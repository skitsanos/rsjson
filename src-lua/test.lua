local json = require('rsjson')

local json_string = '{"user": "demo", "debug": true, "unique_id": 123456, "meta": {"items": ["1","2","3"]}}'

local doc = json.decode(json_string)
print(doc)

print(json.encode(doc))