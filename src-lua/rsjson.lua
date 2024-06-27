local ffi = require("ffi")

ffi.cdef[[
    char* encode(const char* input);
    char* validate(const char* input);
    char* get_value(const char* json_str, const char* key);
    void free_string(char* ptr);
]]

local lib_name
if ffi.os == "OSX" then
    lib_name = "../target/release/librsjson.dylib"
elseif ffi.os == "Linux" then
    lib_name = "../target/release/librsjson.so"
elseif ffi.os == "Windows" then
    lib_name = "../target/release/rsjson.dll"
else
    error("Unsupported operating system: " .. ffi.os)
end

local rsjson = ffi.load(lib_name)

local function encode(input)
    local ptr = rsjson.encode(input)
    if ptr == nil then
        return nil, "Encoding failed"
    end
    local result = ffi.string(ptr)
    rsjson.free_string(ptr)
    return result
end

local function validate(input)
    local ptr = rsjson.validate(input)
    if ptr == nil then
        return nil, "Validation failed"
    end
    local result = ffi.string(ptr)
    rsjson.free_string(ptr)
    return result
end

local function get_value(json_str, key)
    local ptr = rsjson.get_value(json_str, key)
    if ptr == nil then
        return nil, "Get value failed"
    end
    local result = ffi.string(ptr)
    rsjson.free_string(ptr)
    return result
end

local function decode(input)
    local result, err = validate(input)
    if result == "Valid JSON" then
        return input  -- The input is already valid JSON
    else
        return nil, err or result  -- Return nil and the error message
    end
end

return {
    encode = encode,
    decode = decode,
    validate = validate,
    get_value = get_value
}