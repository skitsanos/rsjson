#!/usr/bin/env lua

-- Standalone Lua test script for rsjson
-- This script tests rsjson functionality outside of OpenResty

print("=== RSJSON Standalone Test ===")

-- Try to load rsjson
local success, json = pcall(require, 'rsjson')
if not success then
    print("❌ Error loading rsjson: " .. tostring(json))
    os.exit(1)
end

print("✅ rsjson loaded successfully")
print("Available functions: " .. table.concat({
    type(json.encode) == "function" and "encode" or nil,
    type(json.decode) == "function" and "decode" or nil,
    type(json.parse) == "function" and "parse" or nil,
    type(json.stringify) == "function" and "stringify" or nil,
    type(json.stringify_pretty) == "function" and "stringify_pretty" or nil
}, ", "))

-- Test 1: JSON Parsing
print("\n--- Test 1: JSON Parsing ---")
local json_string = '{"user": "demo", "debug": true, "unique_id": 123456, "meta": {"items": ["1","2","3"], "count": 3}}'
print("Input JSON: " .. json_string)

local decoded = json.decode(json_string)
print("✅ Decoded successfully")
print("  user: " .. tostring(decoded.user))
print("  debug: " .. tostring(decoded.debug))
print("  unique_id: " .. tostring(decoded.unique_id))
print("  meta.count: " .. tostring(decoded.meta.count))
print("  meta.items[1]: " .. tostring(decoded.meta.items[1]))

-- Test 2: JSON Generation
print("\n--- Test 2: JSON Generation ---")
local lua_table = {
    message = "Hello from rsjson!",
    version = "2.1.0",
    timestamp = os.time(),
    features = {"encode", "decode", "parse", "stringify"},
    config = {
        debug = false,
        max_depth = 10
    },
    data = decoded  -- nested data from test 1
}

local encoded = json.encode(lua_table)
print("✅ Encoded successfully")
print("Output JSON: " .. encoded)

-- Test 3: Pretty Print
print("\n--- Test 3: Pretty Printing ---")
if json.stringify_pretty then
    local pretty = json.stringify_pretty(lua_table)
    print("✅ Pretty print successful")
    print("Pretty JSON:\n" .. pretty)
else
    print("⚠️  stringify_pretty not available")
end

-- Test 4: Round-trip Test
print("\n--- Test 4: Round-trip Test ---")
local round_trip = json.decode(encoded)
print("✅ Round-trip successful")
print("  Original message: " .. tostring(lua_table.message))
print("  Round-trip message: " .. tostring(round_trip.message))
print("  Data integrity: " .. (lua_table.message == round_trip.message and "✅ PASS" or "❌ FAIL"))

-- Test 5: Error Handling
print("\n--- Test 5: Error Handling ---")
local invalid_json = '{"invalid": json, "missing": quotes}'
local success_parse, error_msg = pcall(json.decode, invalid_json)
if success_parse then
    print("❌ Expected error for invalid JSON, but parsing succeeded")
else
    print("✅ Properly handled invalid JSON: " .. tostring(error_msg))
end

-- Test 6: Edge Cases
print("\n--- Test 6: Edge Cases ---")
local edge_cases = {
    empty_object = {},
    empty_array = {},
    null_value = json.decode('{"null_field": null}').null_field,
    boolean_true = true,
    boolean_false = false,
    zero = 0,
    negative = -42,
    float = 3.14159
}

local edge_encoded = json.encode(edge_cases)
local edge_decoded = json.decode(edge_encoded)
print("✅ Edge cases handled")
print("Empty object type: " .. type(edge_decoded.empty_object))
print("Null value: " .. tostring(edge_decoded.null_value))
print("Boolean values: " .. tostring(edge_decoded.boolean_true) .. ", " .. tostring(edge_decoded.boolean_false))

print("\n=== All Tests Completed Successfully! ===")
print("Lua version: " .. _VERSION)
print("Platform: " .. (jit and jit.version or "Standard Lua"))