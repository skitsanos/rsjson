#!/usr/bin/env lua

--[[
Simple JSON Performance Benchmark
Quick and easy comparison between rsjson and other JSON libraries
]]

-- Load available libraries
local json_libs = {}
local library_order = {"rsjson", "dkjson", "cjson"}
local dataset_order = {"small", "medium", "large_array", "sparse_table"}

local function try_load(name)
    local ok, lib = pcall(require, name)
    if ok then json_libs[name] = lib end
    return ok
end

print("Loading JSON libraries...")
for _, name in ipairs(library_order) do
    try_load(name)
end

if not next(json_libs) then
    print("No JSON libraries found!")
    os.exit(1)
end

for _, name in ipairs(library_order) do
    if json_libs[name] then
        print("  OK: " .. name)
    end
end
print()

-- Test datasets
local datasets = {
    small = {
        name = "Small Object",
        data = {id = 123, name = "John", active = true, score = 95.5}
    },
    
    medium = {
        name = "Medium Object", 
        data = {
            user = {
                id = 12345,
                profile = {name = "Jane", email = "jane@example.com"},
                permissions = {"read", "write"},
                settings = {theme = "dark", notifications = true}
            }
        }
    },
    
    large_array = {
        name = "Large Array",
        data = {}
    },

    sparse_table = {
        name = "Sparse Table",
        data = {
            [1] = "first",
            [3] = "third",
            label = "sparse"
        }
    }
}

-- Generate large array
for i = 1, 1000 do
    table.insert(datasets.large_array.data, {
        id = i, 
        name = "Item " .. i, 
        value = i * 3.14,
        active = (i % 2 == 0)
    })
end

-- Simple benchmark function
local function benchmark(name, func, iterations)
    iterations = iterations or 10000
    
    collectgarbage("collect")
    local start_memory = collectgarbage("count")
    local start_time = os.clock()
    
    for i = 1, iterations do
        func()
    end
    
    local end_time = os.clock()
    local end_memory = collectgarbage("count")
    
    local duration = end_time - start_time
    local memory_used = end_memory - start_memory
    local ops_per_sec = iterations / duration
    
    return {
        duration = duration,
        memory_used = memory_used,
        ops_per_sec = ops_per_sec
    }
end

-- Run benchmarks
print("Running benchmarks...")
print(string.format("%-10s %-12s %-8s %10s %12s %8s", 
    "Library", "Dataset", "Op", "Time(s)", "Ops/sec", "Mem(KB)"))
print(string.rep("-", 70))

local iterations_by_dataset = {
    small = 50000,
    medium = 10000, 
    large_array = 1000,
    sparse_table = 20000
}

-- Encode JSON strings for decode tests
local encoded_data = {}
local reference_encoder = json_libs.rsjson or json_libs.dkjson or json_libs.cjson
if reference_encoder then
    for _, dataset_name in ipairs(dataset_order) do
        local dataset = datasets[dataset_name]
        local ok, encoded = pcall(reference_encoder.encode, dataset.data)
        if ok then
            encoded_data[dataset_name] = encoded
        end
    end
end

local function supports_operation(operation)
    local ok = pcall(operation)
    return ok
end

-- Main benchmark loop
for _, dataset_name in ipairs(dataset_order) do
    local dataset = datasets[dataset_name]
    local iterations = iterations_by_dataset[dataset_name]
    
    for _, lib_name in ipairs(library_order) do
        local lib = json_libs[lib_name]
        if lib and lib.encode then
            -- Benchmark encoding
            local encode_operation = function() lib.encode(dataset.data) end
            if supports_operation(encode_operation) then
                local encode_result = benchmark(
                    lib_name .. "_encode",
                    encode_operation,
                    iterations
                )

                print(string.format("%-10s %-12s %-8s %8.3f %10.0f %8.1f",
                    lib_name, dataset_name, "encode",
                    encode_result.duration, encode_result.ops_per_sec, encode_result.memory_used))
            else
                print(string.format("%-10s %-12s %-8s %8s %10s %8s",
                    lib_name, dataset_name, "encode", "SKIP", "SKIP", "SKIP"))
            end
        end
        
        if lib and lib.decode and encoded_data[dataset_name] then
            -- Benchmark decoding  
            local decode_operation = function() lib.decode(encoded_data[dataset_name]) end
            if supports_operation(decode_operation) then
                local decode_result = benchmark(
                    lib_name .. "_decode",
                    decode_operation,
                    iterations
                )

                print(string.format("%-10s %-12s %-8s %8.3f %10.0f %8.1f",
                    lib_name, dataset_name, "decode",
                    decode_result.duration, decode_result.ops_per_sec, decode_result.memory_used))
            else
                print(string.format("%-10s %-12s %-8s %8s %10s %8s",
                    lib_name, dataset_name, "decode", "SKIP", "SKIP", "SKIP"))
            end
        end
    end
    print() -- Blank line between datasets
end

-- Performance comparison
if json_libs.rsjson and json_libs.dkjson then
    print("=== Performance Comparison ===")
    
    local function compare_libs(dataset_name, iterations)
        if not encoded_data[dataset_name] then
            return
        end

        local rsjson_encode = benchmark("rsjson_encode", 
            function() json_libs.rsjson.encode(datasets[dataset_name].data) end, iterations)
        local dkjson_encode = benchmark("dkjson_encode",
            function() json_libs.dkjson.encode(datasets[dataset_name].data) end, iterations)
            
        local speedup = rsjson_encode.ops_per_sec / dkjson_encode.ops_per_sec
        print(string.format("%-12s encode: rsjson is %.1fx faster than dkjson", 
            dataset_name, speedup))
        
        local rsjson_decode = benchmark("rsjson_decode",
            function() json_libs.rsjson.decode(encoded_data[dataset_name]) end, iterations)
        local dkjson_decode = benchmark("dkjson_decode",
            function() json_libs.dkjson.decode(encoded_data[dataset_name]) end, iterations)

        local decode_speedup = rsjson_decode.ops_per_sec / dkjson_decode.ops_per_sec
        print(string.format("%-12s decode: rsjson is %.1fx faster than dkjson",
            dataset_name, decode_speedup))
    end
    
    compare_libs("small", 50000)
    compare_libs("medium", 10000) 
    compare_libs("large_array", 1000)
    compare_libs("sparse_table", 20000)
end

print("\nBenchmark completed!")
print("Note: Run multiple times and average for reliable results.")
