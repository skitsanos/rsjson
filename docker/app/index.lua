local success, json = pcall(require, 'rsjson')
if not success then
    print("Error loading rsjson: ", json)
    ngx.say("Error loading rsjson: ", json)
else
    print("rsjson loaded successfully")

    local json_string = '{"user": "demo", "debug": true, "unique_id": 123456, "meta": {"items": ["1","2","3"]}}'
    
    -- Decode JSON string to Lua table
    local decoded = json.decode(json_string)
    ngx.say("Decoded user: ", decoded.user)
    ngx.say("Decoded debug: ", tostring(decoded.debug))
    ngx.say("Decoded unique_id: ", decoded.unique_id)
    
    -- Encode Lua table back to JSON
    local lua_table = {
        message = "Hello from rsjson!",
        timestamp = ngx.time(),
        data = decoded
    }
    local encoded = json.encode(lua_table)
    ngx.say("Encoded: ", encoded)
end

