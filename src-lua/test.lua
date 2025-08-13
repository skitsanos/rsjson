-- Add the compiled library to the package search path
-- For Lua 5.4: cargo build --release
-- For other versions: cargo build --release --no-default-features --features lua53
-- package.cpath = package.cpath .. ';../target/release/lib?.dylib'

local json = require("rsjson")

-- Parse JSON string to Lua table
local jsonString = '{"name":"John", "age":30, "city":"New York"}'
local parsed = json.parse(jsonString)
print("Parsed JSON:")
for k, v in pairs(parsed) do
    print(k, v)
end

-- Convert Lua table to JSON string
local luaTable = {
    name = "Alice",
    age = 25,
    hobbies = {"reading", "swimming"},
    address = {
        street = "123 Main St",
        city = "Los Angeles"
    }
}
local stringified = json.stringify(luaTable)
print("\nStringified JSON:", stringified)

-- Pretty print JSON
local prettyJson = json.stringify_pretty(luaTable)
print("\nPretty JSON:")
print(prettyJson)

print('Using JSON.encode()')
print(json.encode(luaTable))

print('Using JSON.decode()')
local decoded = json.decode(prettyJson)
print(decoded)
print(decoded.name)