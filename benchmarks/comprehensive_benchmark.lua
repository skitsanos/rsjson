#!/usr/bin/env lua

--[[
Comprehensive JSON Library Benchmark Suite
Tests rsjson against other popular Lua JSON libraries across various scenarios
]]

local json_libraries = {}
local results = {}

-- Try to load available JSON libraries
local function try_require(name)
    local success, module = pcall(require, name)
    return success and module or nil
end

-- Load available libraries
json_libraries.rsjson = try_require("rsjson")
json_libraries.dkjson = try_require("dkjson") 
json_libraries.cjson = try_require("cjson")
json_libraries.rapidjson = try_require("rapidjson")

print("=== JSON Library Benchmark Suite ===")
print("Available libraries:")
for name, lib in pairs(json_libraries) do
    if lib then
        print("  ✓ " .. name)
    else
        print("  ✗ " .. name .. " (not available)")
    end
end
print()

-- Test data generators
local test_data = {}

-- Small, simple object
test_data.small = {
    id = 123,
    name = "John Doe",
    active = true,
    score = 95.5,
    tags = {"user", "premium"}
}

-- Medium complexity object
test_data.medium = {
    user = {
        id = 12345,
        profile = {
            name = "Jane Smith",
            email = "jane@example.com",
            preferences = {
                theme = "dark",
                notifications = true,
                language = "en-US"
            },
            metadata = {
                created = "2023-01-15T10:30:00Z",
                last_login = "2024-01-15T08:45:00Z",
                login_count = 247
            }
        },
        permissions = {"read", "write", "admin"},
        recent_activity = {
            {action = "login", timestamp = "2024-01-15T08:45:00Z"},
            {action = "update_profile", timestamp = "2024-01-14T15:20:00Z"},
            {action = "create_post", timestamp = "2024-01-14T14:10:00Z"}
        }
    },
    settings = {
        privacy = {public = false, searchable = true},
        security = {two_factor = true, password_reset = "2024-01-01"}
    }
}

-- Large array with nested objects
test_data.large_array = {}
for i = 1, 1000 do
    table.insert(test_data.large_array, {
        id = i,
        name = "Item " .. i,
        value = math.random() * 1000,
        active = (i % 3 == 0),
        metadata = {
            created = "2024-01-" .. string.format("%02d", (i % 28) + 1),
            category = "category_" .. (i % 10),
            tags = {"tag1", "tag2", "tag" .. (i % 5)}
        }
    })
end

-- Deep nesting test
local function create_deep_object(depth)
    if depth <= 0 then
        return {value = "leaf", depth = 0}
    end
    return {
        level = depth,
        data = "level_" .. depth,
        nested = create_deep_object(depth - 1)
    }
end
test_data.deep_nested = create_deep_object(100)

-- Very large object
test_data.large_object = {}
for i = 1, 500 do
    test_data.large_object["field_" .. i] = {
        string_val = "This is a longer string value for field " .. i,
        numeric_val = i * 3.14159,
        boolean_val = (i % 2 == 0),
        array_val = {i, i+1, i+2, i+3, i+4},
        nested_obj = {
            sub_field_1 = "sub_value_" .. i,
            sub_field_2 = i * 2,
            sub_array = {"a", "b", "c", i}
        }
    }
end

-- JSON strings for decode testing
local encoded_strings = {}

-- Pre-encode test data with a reference implementation (dkjson)
if json_libraries.dkjson then
    for name, data in pairs(test_data) do
        encoded_strings[name] = json_libraries.dkjson.encode(data)
    end
end

-- Benchmark configuration
local benchmark_config = {
    {name = "small", data = test_data.small, iterations = 50000},
    {name = "medium", data = test_data.medium, iterations = 10000},
    {name = "large_array", data = test_data.large_array, iterations = 1000},
    {name = "deep_nested", data = test_data.deep_nested, iterations = 5000},
    {name = "large_object", data = test_data.large_object, iterations = 500}
}

-- Memory tracking helper
local function get_memory_usage()
    collectgarbage("collect")
    return collectgarbage("count") * 1024 -- Convert KB to bytes
end

-- Statistical benchmark function
local function benchmark_operation(name, operation, iterations, runs)
    runs = runs or 5
    local times = {}
    local memory_start, memory_end
    
    for run = 1, runs do
        collectgarbage("collect")
        memory_start = get_memory_usage()
        
        local start_time = os.clock()
        for i = 1, iterations do
            operation()
        end
        local end_time = os.clock()
        
        memory_end = get_memory_usage()
        table.insert(times, end_time - start_time)
    end
    
    -- Calculate statistics
    table.sort(times)
    local min_time = times[1]
    local max_time = times[#times]
    local median_time = times[math.ceil(#times / 2)]
    local avg_time = 0
    for _, time in ipairs(times) do
        avg_time = avg_time + time
    end
    avg_time = avg_time / #times
    
    -- Calculate standard deviation
    local variance = 0
    for _, time in ipairs(times) do
        variance = variance + (time - avg_time) ^ 2
    end
    local std_dev = math.sqrt(variance / #times)
    
    return {
        min = min_time,
        max = max_time,
        avg = avg_time,
        median = median_time,
        std_dev = std_dev,
        memory_delta = memory_end - memory_start,
        ops_per_second = iterations / avg_time
    }
end

-- Run benchmarks
local function run_benchmark_suite()
    print("Running comprehensive benchmark suite...")
    print("Format: Library | Operation | Dataset | Avg Time | Ops/sec | Memory | Std Dev")
    print(string.rep("=", 80))
    
    for _, config in ipairs(benchmark_config) do
        local dataset_name = config.name
        local test_data_item = config.data
        local iterations = config.iterations
        local encoded_string = encoded_strings[dataset_name]
        
        print("Dataset: " .. dataset_name .. " (" .. iterations .. " iterations)")
        
        -- Test each available library
        for lib_name, lib in pairs(json_libraries) do
            if lib and lib.encode and lib.decode then
                -- Benchmark encoding
                local encode_stats = benchmark_operation(
                    lib_name .. "_encode",
                    function() lib.encode(test_data_item) end,
                    iterations
                )
                
                -- Benchmark decoding (if we have encoded string)
                local decode_stats
                if encoded_string then
                    decode_stats = benchmark_operation(
                        lib_name .. "_decode", 
                        function() lib.decode(encoded_string) end,
                        iterations
                    )
                end
                
                -- Print results
                printf("  %8s | %-6s | %10s | %8.4fs | %8.0f | %6dKB | ±%.4f",
                    lib_name, "encode", dataset_name, 
                    encode_stats.avg, encode_stats.ops_per_second,
                    math.floor(encode_stats.memory_delta / 1024), encode_stats.std_dev)
                    
                if decode_stats then
                    printf("  %8s | %-6s | %10s | %8.4fs | %8.0f | %6dKB | ±%.4f",
                        lib_name, "decode", dataset_name,
                        decode_stats.avg, decode_stats.ops_per_second, 
                        math.floor(decode_stats.memory_delta / 1024), decode_stats.std_dev)
                end
            end
        end
        print()
    end
end

-- Enhanced printf function for formatted output
function printf(fmt, ...)
    print(string.format(fmt, ...))
end

-- Performance comparison summary
local function print_performance_summary()
    if not (json_libraries.rsjson and json_libraries.dkjson) then
        return
    end
    
    print("=== Performance Summary ===")
    print("Testing rsjson vs other libraries on medium dataset:")
    
    local iterations = 10000
    local test_data_item = test_data.medium
    local encoded_string = encoded_strings.medium
    
    local results = {}
    for lib_name, lib in pairs(json_libraries) do
        if lib and lib.encode and lib.decode then
            local encode_stats = benchmark_operation(
                lib_name .. "_encode",
                function() lib.encode(test_data_item) end,
                iterations, 3
            )
            
            local decode_stats = benchmark_operation(
                lib_name .. "_decode",
                function() lib.decode(encoded_string) end, 
                iterations, 3
            )
            
            results[lib_name] = {
                encode_ops = encode_stats.ops_per_second,
                decode_ops = decode_stats.ops_per_second,
                total_time = encode_stats.avg + decode_stats.avg
            }
        end
    end
    
    -- Find fastest for comparison
    local fastest_encode = 0
    local fastest_decode = 0
    for _, stats in pairs(results) do
        fastest_encode = math.max(fastest_encode, stats.encode_ops)
        fastest_decode = math.max(fastest_decode, stats.decode_ops)
    end
    
    -- Print comparisons
    for lib_name, stats in pairs(results) do
        local encode_ratio = stats.encode_ops / fastest_encode
        local decode_ratio = stats.decode_ops / fastest_decode
        
        printf("%s:", lib_name)
        printf("  Encode: %8.0f ops/sec (%.2fx of fastest)", stats.encode_ops, encode_ratio)
        printf("  Decode: %8.0f ops/sec (%.2fx of fastest)", stats.decode_ops, decode_ratio)
        printf("  Total:  %8.4fs", stats.total_time)
        print()
    end
end

-- Error handling benchmark
local function benchmark_error_handling()
    print("=== Error Handling Performance ===")
    
    local malformed_json_samples = {
        '{"invalid": json,}',  -- Trailing comma
        '{"unclosed": "string}', -- Unclosed string
        '{invalid_key: "value"}', -- Unquoted key
        '{"number": 123.456.789}', -- Invalid number
        '{"nested": {"unclosed": }', -- Unclosed nested object
    }
    
    for lib_name, lib in pairs(json_libraries) do
        if lib and lib.decode then
            print("Testing " .. lib_name .. " error handling:")
            local error_count = 0
            local total_time = 0
            
            for _, malformed in ipairs(malformed_json_samples) do
                local start_time = os.clock()
                local success, result = pcall(lib.decode, malformed)
                local end_time = os.clock()
                
                total_time = total_time + (end_time - start_time)
                if not success then
                    error_count = error_count + 1
                end
            end
            
            printf("  Errors caught: %d/%d", error_count, #malformed_json_samples)
            printf("  Average error handling time: %.6fs", total_time / #malformed_json_samples)
            print()
        end
    end
end

-- Main execution
local available_count = 0
for name, lib in pairs(json_libraries) do
    if lib then available_count = available_count + 1 end
end

if available_count == 0 then
    print("No JSON libraries available for benchmarking!")
    os.exit(1)
end

-- Run all benchmarks
run_benchmark_suite()
print_performance_summary()
benchmark_error_handling()

print("Benchmark completed!")
print("Note: Results may vary based on system load and Lua implementation.")
print("Run multiple times and average results for production benchmarking.")