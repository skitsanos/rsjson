extern crate libc;
use libc::c_char;
use std::ffi::{CString, CStr};
use serde_json::{Value, json};

#[no_mangle]
pub extern "C" fn encode(input: *const c_char) -> *mut c_char {
    let c_str = unsafe { CStr::from_ptr(input) };
    let input_str = c_str.to_str().unwrap();
    let parsed: Value = serde_json::from_str(input_str).unwrap();
    let output = json!(parsed).to_string();
    CString::new(output).unwrap().into_raw()
}

#[no_mangle]
pub extern "C" fn decode(input: *const c_char) -> *mut c_char {
    let c_str = unsafe { CStr::from_ptr(input) };
    let input_str = c_str.to_str().unwrap();
    let parsed: Value = serde_json::from_str(input_str).unwrap();
    let output = parsed.to_string();
    CString::new(output).unwrap().into_raw()
}
