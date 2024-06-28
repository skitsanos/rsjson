local function benchmark(name, encode_func, decode_func, iterations)
    local sample_data = {
        string = "Hello, World!",
        number = 42,
        boolean = true,
        array = {1, 2, 3, 4, 5},
        object = {a = 1, b = 2, c = 3}
    }

    local json_string = '{"string":"Hello, World!","number":42,"boolean":true,"array":[1,2,3,4,5],"object":{"a":1,"b":2,"c":3}}'

    print("Benchmarking " .. name)

    -- Benchmark encoding
    local start_time = os.clock()
    for i = 1, iterations do
        encode_func(sample_data)
    end
    local encode_time = os.clock() - start_time
    print("  Encode time: " .. encode_time)

    -- Benchmark decoding
    start_time = os.clock()
    for i = 1, iterations do
        decode_func(json_string)
    end
    local decode_time = os.clock() - start_time
    print("  Decode time: " .. decode_time)

    print("  Total time: " .. (encode_time + decode_time))
    print()
end

-- Example usage with different libraries
local dkjson = require "dkjson"
local rsjson = require "rsjson"

benchmark("dkjson: 10,000", dkjson.encode, dkjson.decode, 10000)
benchmark("rsjson: 10,000", rsjson.encode, rsjson.decode, 10000)

benchmark("dkjson: 100,000", dkjson.encode, dkjson.decode, 100000)
benchmark("rsjson: 100,000", rsjson.encode, rsjson.decode, 100000)