extern crate libc;
use libc::c_char;
use std::ffi::{CString, CStr};
use serde_json::{Value, json};

// Helper function to convert C string to Rust string
fn c_str_to_string(input: *const c_char) -> Result<String, String> {
    let c_str = unsafe { CStr::from_ptr(input) };
    c_str.to_str()
        .map(|s| s.to_string())
        .map_err(|_| "Invalid UTF-8 string".to_string())
}

// Helper function to convert Rust string to C string
fn string_to_c_str(input: String) -> *mut c_char {
    CString::new(input).unwrap().into_raw()
}

#[no_mangle]
pub extern "C" fn encode(input: *const c_char) -> *mut c_char {
    let result = c_str_to_string(input)
        .and_then(|input_str| {
            serde_json::from_str::<Value>(&input_str)
                .map(|val| json!(val).to_string())
                .map_err(|e| format!("Failed to encode JSON: {}", e))
        });

    match result {
        Ok(output) => string_to_c_str(output),
        Err(e) => string_to_c_str(e),
    }
}

#[no_mangle]
pub extern "C" fn validate(input: *const c_char) -> *mut c_char {
    let result = c_str_to_string(input)
        .and_then(|input_str| {
            serde_json::from_str::<Value>(&input_str)
                .map(|_| "Valid JSON".to_string())
                .map_err(|e| format!("Invalid JSON: {}", e))
        });

    match result {
        Ok(output) => string_to_c_str(output),
        Err(e) => string_to_c_str(e),
    }
}

#[no_mangle]
pub extern "C" fn get_value(json_str: *const c_char, key: *const c_char) -> *mut c_char {
    let result = (|| {
        let json = c_str_to_string(json_str)?;
        let key = c_str_to_string(key)?;
        let value: Value = serde_json::from_str(&json)
            .map_err(|e| format!("Failed to parse JSON: {}", e))?;

        value.get(&key)
            .map(|v| v.to_string())
            .ok_or_else(|| format!("Key '{}' not found", key))
    })();

    match result {
        Ok(output) => string_to_c_str(output),
        Err(e) => string_to_c_str(e),
    }
}

#[no_mangle]
pub extern "C" fn free_string(ptr: *mut c_char) {
    unsafe {
        if !ptr.is_null() {
            drop(CString::from_raw(ptr));
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::ffi::CString;

    #[test]
    fn test_encode() {
        let input = CString::new(r#"{"key": "value"}"#).unwrap();
        let result = encode(input.as_ptr());
        let output = unsafe { CStr::from_ptr(result).to_str().unwrap() };
        assert_eq!(output, r#"{"key":"value"}"#);
        free_string(result);
    }

    #[test]
    fn test_validate() {
        let valid_input = CString::new(r#"{"key": "value"}"#).unwrap();
        let result = validate(valid_input.as_ptr());
        let output = unsafe { CStr::from_ptr(result).to_str().unwrap() };
        assert_eq!(output, "Valid JSON");
        free_string(result);

        let invalid_input = CString::new(r#"{"key": "value""#).unwrap();
        let result = validate(invalid_input.as_ptr());
        let output = unsafe { CStr::from_ptr(result).to_str().unwrap() };
        assert!(output.starts_with("Invalid JSON"));
        free_string(result);
    }

    #[test]
    fn test_get_value() {
        let json = CString::new(r#"{"key": "value", "nested": {"inner": 42}}"#).unwrap();
        let key = CString::new("nested").unwrap();
        let result = get_value(json.as_ptr(), key.as_ptr());
        let output = unsafe { CStr::from_ptr(result).to_str().unwrap() };
        assert_eq!(output, r#"{"inner":42}"#);
        free_string(result);

        let non_existent_key = CString::new("non_existent").unwrap();
        let result = get_value(json.as_ptr(), non_existent_key.as_ptr());
        let output = unsafe { CStr::from_ptr(result).to_str().unwrap() };
        assert_eq!(output, "Key 'non_existent' not found");
        free_string(result);
    }
}