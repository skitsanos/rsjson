-- Adding custom paths for C modules
--package.cpath = package.cpath .. ';../target/release/?.dylib'

local json = require('rsjson')

local json_string = '{"user": "demo", "debug": true, "unique_id": 123456, "meta": {"items": ["1","2","3"]}}'

local encoded = json.encode(json_string)
print("Encoded:", encoded)

local decoded, err = json.decode(encoded)
if decoded then
    print("Decoded:", decoded)

    local value, err_get_value = json.get_value(decoded, "meta")
    if value then
        print("Value:", value)
    else
        print("Get value error:", err_get_value)
    end
else
    print("Decode error:", err)
end
