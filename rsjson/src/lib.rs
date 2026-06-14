use std::{mem, os::raw::c_void};

use mlua::prelude::*;
use serde_json::{Error as JsonError, Value as JsonValue};

pub struct RsJson;

impl RsJson {
    pub fn parse(input: &str) -> Result<JsonValue, JsonError> {
        serde_json::from_str(input)
    }

    pub fn parse_bytes(input: &[u8]) -> Result<JsonValue, JsonError> {
        serde_json::from_slice(input)
    }

    pub fn stringify(value: &JsonValue) -> Result<String, JsonError> {
        serde_json::to_string(value)
    }

    pub fn stringify_pretty(value: &JsonValue) -> Result<String, JsonError> {
        serde_json::to_string_pretty(value)
    }
}

fn lua_value_to_json(value: LuaValue) -> Result<JsonValue, LuaError> {
    lua_value_to_json_inner(value, &mut Vec::new())
}

fn lua_value_to_json_inner(
    value: LuaValue,
    table_stack: &mut Vec<*const c_void>,
) -> Result<JsonValue, LuaError> {
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
        LuaValue::Table(t) => lua_table_to_json(t, table_stack),
        _ => Err(LuaError::FromLuaConversionError {
            from: value.type_name(),
            to: "json".to_string(),
            message: None,
        }),
    }
}

fn lua_table_to_json(
    table: LuaTable,
    table_stack: &mut Vec<*const c_void>,
) -> Result<JsonValue, LuaError> {
    let table_ptr = table.to_pointer();
    if table_stack.contains(&table_ptr) {
        return Err(LuaError::FromLuaConversionError {
            from: "table",
            to: "json".to_string(),
            message: Some("recursive table cannot be encoded as JSON".into()),
        });
    }

    table_stack.push(table_ptr);
    let json_value = (|| -> Result<JsonValue, LuaError> {
        let mut array_entries = Vec::new();
        let mut object: Option<serde_json::Map<String, JsonValue>> = None;
        let mut count = 0usize;
        let mut max_index = 0usize;

        for pair in table.pairs::<LuaValue, LuaValue>() {
            let (key, value) = pair?;
            let json_value = lua_value_to_json_inner(value, table_stack)?;

            if let Some(object) = object.as_mut() {
                object.insert(lua_key_to_json_key(key)?, json_value);
                continue;
            }

            let LuaValue::Integer(index) = key else {
                let mut map = serde_json::Map::with_capacity(array_entries.len() + 1);
                move_array_entries_to_object(&mut map, mem::take(&mut array_entries));
                map.insert(lua_key_to_json_key(key)?, json_value);
                object = Some(map);
                continue;
            };

            let Ok(index) = usize::try_from(index) else {
                let mut map = serde_json::Map::with_capacity(array_entries.len() + 1);
                move_array_entries_to_object(&mut map, mem::take(&mut array_entries));
                map.insert(index.to_string(), json_value);
                object = Some(map);
                continue;
            };

            if index == 0 {
                let mut map = serde_json::Map::with_capacity(array_entries.len() + 1);
                move_array_entries_to_object(&mut map, mem::take(&mut array_entries));
                map.insert("0".to_string(), json_value);
                object = Some(map);
                continue;
            }

            count += 1;
            max_index = max_index.max(index);
            array_entries.push((index, json_value));
        }

        if let Some(object) = object {
            return Ok(JsonValue::Object(object));
        }

        if count == max_index {
            array_entries.sort_unstable_by_key(|(index, _)| *index);
            Ok(JsonValue::Array(
                array_entries.into_iter().map(|(_, value)| value).collect(),
            ))
        } else {
            let mut object = serde_json::Map::with_capacity(array_entries.len());
            move_array_entries_to_object(&mut object, array_entries);
            Ok(JsonValue::Object(object))
        }
    })();

    table_stack.pop();
    json_value
}

fn move_array_entries_to_object(
    object: &mut serde_json::Map<String, JsonValue>,
    array_entries: Vec<(usize, JsonValue)>,
) {
    for (index, value) in array_entries {
        object.insert(index.to_string(), value);
    }
}

fn lua_key_to_json_key(key: LuaValue) -> Result<String, LuaError> {
    match key {
        LuaValue::String(s) => Ok(s.to_str()?.to_owned()),
        _ => key.to_string(),
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
            let lua_table = lua.create_table_with_capacity(arr.len(), 0)?;
            for (i, v) in arr.iter().enumerate() {
                lua_table.raw_set(i + 1, json_to_lua_value(lua, v)?)?;
            }
            Ok(LuaValue::Table(lua_table))
        }
        JsonValue::Object(obj) => {
            let lua_table = lua.create_table_with_capacity(0, obj.len())?;
            for (k, v) in obj {
                lua_table.raw_set(k.as_str(), json_to_lua_value(lua, v)?)?;
            }
            Ok(LuaValue::Table(lua_table))
        }
    }
}

#[mlua::lua_module]
fn rsjson(lua: &Lua) -> LuaResult<LuaTable> {
    let exports = lua.create_table()?;

    exports.set(
        "parse",
        lua.create_function(|lua, input: LuaString| {
            let json_value = RsJson::parse_bytes(&input.as_bytes()).map_err(LuaError::external)?;
            json_to_lua_value(lua, &json_value)
        })?,
    )?;

    exports.set(
        "decode",
        lua.create_function(|lua, input: LuaString| {
            let json_value = RsJson::parse_bytes(&input.as_bytes()).map_err(LuaError::external)?;
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

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn lua_table_with_out_of_order_integer_keys_encodes_as_array() -> LuaResult<()> {
        let lua = Lua::new();
        let table = lua.create_table()?;
        table.set(2, "second")?;
        table.set(1, "first")?;

        let json = lua_value_to_json(LuaValue::Table(table))?;

        assert_eq!(json, json!(["first", "second"]));
        Ok(())
    }

    #[test]
    fn mixed_lua_table_preserves_array_and_object_entries() -> LuaResult<()> {
        let lua = Lua::new();
        let table = lua.create_table()?;
        table.set(1, "first")?;
        table.set("kind", "mixed")?;

        let json = lua_value_to_json(LuaValue::Table(table))?;

        assert_eq!(json, json!({"1": "first", "kind": "mixed"}));
        Ok(())
    }

    #[test]
    fn sparse_lua_table_encodes_as_object() -> LuaResult<()> {
        let lua = Lua::new();
        let table = lua.create_table()?;
        table.set(1, "first")?;
        table.set(3, "third")?;

        let json = lua_value_to_json(LuaValue::Table(table))?;

        assert_eq!(json, json!({"1": "first", "3": "third"}));
        Ok(())
    }

    #[test]
    fn recursive_lua_table_returns_error() -> LuaResult<()> {
        let lua = Lua::new();
        let table = lua.create_table()?;
        table.set("self", table.clone())?;

        let error = lua_value_to_json(LuaValue::Table(table)).expect_err("recursive table failed");

        assert!(error.to_string().contains("recursive table"));
        Ok(())
    }
}
