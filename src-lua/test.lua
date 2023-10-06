local json = require('rsjson')

local json_string = '{"user": "demo", "debug": true, "unique_id": 123456, "meta": {}}'

print(json.decode(json_string))