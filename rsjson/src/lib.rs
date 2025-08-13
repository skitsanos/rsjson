use mlua::prelude::*;
use serde_json::{Error as JsonError, Value as JsonValue};

// Include the generated bindings
#[allow(non_upper_case_globals)]
#[allow(non_camel_case_types)]
#[allow(non_snake_case)]
#[allow(dead_code)]
#[allow(clippy::upper_case_acronyms)]
mod bindings {
    include!(concat!(env!("OUT_DIR"), "/bindings.rs"));
}

pub struct RsJson;

impl RsJson {
    pub fn parse(input: &str) -> Result<JsonValue, JsonError> {
        serde_json::from_str(input)
    }

    pub fn stringify(value: &JsonValue) -> Result<String, JsonError> {
        serde_json::to_string(value)
    }

    pub fn stringify_pretty(value: &JsonValue) -> Result<String, JsonError> {
        serde_json::to_string_pretty(value)
    }
}

fn lua_value_to_json(value: LuaValue) -> Result<JsonValue, LuaError> {
    match value {
        LuaValue::Nil => Ok(JsonValue::Null),
        LuaValue::Boolean(b) => Ok(JsonValue::Bool(b)),
        LuaValue::Integer(i) => Ok(JsonValue::Number(i.into())),
        LuaValue::Number(n) => Ok(JsonValue::Number(serde_json::Number::from_f64(n).ok_or(
            LuaError::FromLuaConversionError {
                from: "number",
                to: "json".to_string(),
                message: Some("float is not finite".into()),
            },
        )?)),
        LuaValue::String(s) => Ok(JsonValue::String(s.to_str()?.to_owned())),
        LuaValue::Table(t) => {
            let mut object = serde_json::Map::new();
            let mut array = Vec::new();
            let mut is_array = true;
            let mut index = 1;

            for pair in t.pairs::<LuaValue, LuaValue>() {
                let (k, v) = pair?;
                match k {
                    LuaValue::Integer(i) if i as u64 == index => {
                        array.push(lua_value_to_json(v)?);
                        index += 1;
                    }
                    _ => {
                        is_array = false;
                        let key = match k {
                            LuaValue::String(s) => s.to_str()?.to_owned(),
                            _ => k.to_string()?,
                        };
                        object.insert(key, lua_value_to_json(v)?);
                    }
                }
            }

            if is_array {
                Ok(JsonValue::Array(array))
            } else {
                Ok(JsonValue::Object(object))
            }
        }
        _ => Err(LuaError::FromLuaConversionError {
            from: value.type_name(),
            to: "json".to_string(),
            message: None,
        }),
    }
}

fn json_to_lua_value(lua: &Lua, value: &JsonValue) -> Result<LuaValue, LuaError> {
    match value {
        JsonValue::Null => Ok(LuaValue::Nil),
        JsonValue::Bool(b) => Ok(LuaValue::Boolean(*b)),
        JsonValue::Number(n) => {
            if let Some(i) = n.as_i64() {
                Ok(LuaValue::Integer(i))
            } else if let Some(f) = n.as_f64() {
                Ok(LuaValue::Number(f))
            } else {
                Err(LuaError::FromLuaConversionError {
                    from: "json",
                    to: "lua".to_string(),
                    message: Some("invalid number".into()),
                })
            }
        }
        JsonValue::String(s) => Ok(LuaValue::String(lua.create_string(s)?)),
        JsonValue::Array(arr) => {
            let lua_table = lua.create_table()?;
            for (i, v) in arr.iter().enumerate() {
                lua_table.set(i + 1, json_to_lua_value(lua, v)?)?;
            }
            Ok(LuaValue::Table(lua_table))
        }
        JsonValue::Object(obj) => {
            let lua_table = lua.create_table()?;
            for (k, v) in obj {
                lua_table.set(k.clone(), json_to_lua_value(lua, v)?)?;
            }
            Ok(LuaValue::Table(lua_table))
        }
    }
}

#[mlua::lua_module]
fn rsjson(lua: &Lua) -> LuaResult<LuaTable> {
    // Use the init_lua function from our wrapper
    unsafe {
        let _lua_state = bindings::init_lua();
        // Note: In a real-world scenario, you'd want to manage this Lua state properly
    }

    let exports = lua.create_table()?;

    exports.set(
        "parse",
        lua.create_function(|lua, input: String| {
            let json_value = RsJson::parse(&input).map_err(LuaError::external)?;
            json_to_lua_value(lua, &json_value)
        })?,
    )?;

    exports.set(
        "decode",
        lua.create_function(|lua, input: String| {
            let json_value = RsJson::parse(&input).map_err(LuaError::external)?;
            json_to_lua_value(lua, &json_value)
        })?,
    )?;

    exports.set(
        "stringify",
        lua.create_function(|_, value: LuaValue| {
            let json_value = lua_value_to_json(value)?;
            RsJson::stringify(&json_value).map_err(LuaError::external)
        })?,
    )?;

    exports.set(
        "encode",
        lua.create_function(|_, value: LuaValue| {
            let json_value = lua_value_to_json(value)?;
            RsJson::stringify(&json_value).map_err(LuaError::external)
        })?,
    )?;

    exports.set(
        "stringify_pretty",
        lua.create_function(|_, value: LuaValue| {
            let json_value = lua_value_to_json(value)?;
            RsJson::stringify_pretty(&json_value).map_err(LuaError::external)
        })?,
    )?;

    Ok(exports)
}
