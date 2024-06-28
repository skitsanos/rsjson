local success, json = pcall(require, 'rsjson')
if not success then
    print("Error loading rsjson: ", json)
    ngx.say("Error loading rsjson: ", json)
else
    print("rsjson loaded successfully")

    local json_string = '{"user": "demo", "debug": true, "unique_id": 123456, "meta": {"items": ["1","2","3"]}}'

    local encoded = json.encode(json_string)
    ngx.say("Encoded:", encoded)
end

