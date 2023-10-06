local ffi = require("ffi")

ffi.cdef[[
    char* encode(const char* input);
    char* decode(const char* input);
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
    return ffi.string(rsjson.encode(input))
end

local function decode(input)
    return ffi.string(rsjson.decode(input))
end

return {
    encode = encode,
    decode = decode
}
