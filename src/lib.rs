extern crate libc;
use libc::c_char;
use std::ffi::{CString, CStr};
use serde_json::{Value, json};

#[no_mangle]
pub extern "C" fn encode(input: *const c_char) -> *mut c_char {
    let c_str = unsafe { CStr::from_ptr(input) };
    let input_str = match c_str.to_str() {
        Ok(s) => s,
        Err(_) => return CString::new("Invalid UTF-8 string").unwrap().into_raw(),
    };

    let parsed: Result<Value, _> = serde_json::from_str(input_str);
    let output = match parsed {
        Ok(val) => json!(val).to_string(),
        Err(e) => format!("Failed to encode JSON: {}", e),
    };

    CString::new(output).unwrap().into_raw()
}

#[no_mangle]
pub extern "C" fn decode(input: *const c_char) -> *mut c_char {
    let c_str = unsafe { CStr::from_ptr(input) };
    let input_str = match c_str.to_str() {
        Ok(s) => s,
        Err(_) => return CString::new("Invalid UTF-8 string").unwrap().into_raw(),
    };

    let parsed: Result<Value, _> = serde_json::from_str(input_str);
    let output = match parsed {
        Ok(val) => val.to_string(),
        Err(e) => format!("Failed to decode JSON: {}", e),
    };

    CString::new(output).unwrap().into_raw()
}
