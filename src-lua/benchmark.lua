--[[
DEPRECATED: This benchmark has been replaced with a comprehensive benchmark suite.

For better benchmarking with statistical analysis, multiple datasets, and 
comprehensive library comparison, please use:

  ./benchmarks/run_benchmarks.sh

or directly:

  cd benchmarks && lua simple_benchmark.lua

The new benchmark suite includes:
- Multiple realistic test datasets
- Statistical analysis (multiple runs, std dev)  
- Memory usage tracking
- Comparison with multiple JSON libraries
- Error handling performance testing
- CI/CD integration support

This legacy benchmark is kept for compatibility but is not recommended.
--]]

print("⚠️  DEPRECATED BENCHMARK")
print("This basic benchmark has been replaced with a comprehensive suite.")
print("Please use: ./benchmarks/run_benchmarks.sh")
print("Or: cd benchmarks && lua simple_benchmark.lua")
print()
print("The new benchmarks provide:")
print("  ✅ Multiple realistic test datasets")
print("  ✅ Statistical analysis and reliability")
print("  ✅ Memory usage tracking")  
print("  ✅ Comparison with multiple libraries")
print("  ✅ Error handling performance")
print()

-- Ask user if they want to continue with legacy benchmark
io.write("Continue with legacy benchmark? [y/N]: ")
local answer = io.read()
if answer ~= "y" and answer ~= "Y" then
    print("Exiting. Please use the new benchmark suite in ./benchmarks/")
    os.exit(0)
end

print("Running legacy benchmark...")
print()

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
-- Build rsjson first: cargo build --release
-- Or for specific Lua version: cargo build --release --no-default-features --features lua53
local ok_dkjson, dkjson = pcall(require, "dkjson")
local ok_rsjson, rsjson = pcall(require, "rsjson")

if not ok_rsjson then
    print("❌ rsjson not found. Build with: cargo build --release")
    os.exit(1)
end

if not ok_dkjson then
    print("❌ dkjson not found. Install with: luarocks install dkjson")
    os.exit(1)
end

benchmark("dkjson: 10,000", dkjson.encode, dkjson.decode, 10000)
benchmark("rsjson: 10,000", rsjson.encode, rsjson.decode, 10000)

benchmark("dkjson: 100,000", dkjson.encode, dkjson.decode, 100000)
benchmark("rsjson: 100,000", rsjson.encode, rsjson.decode, 100000)

print("RECOMMENDATION: Use ./benchmarks/run_benchmarks.sh for comprehensive testing")