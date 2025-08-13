# Benchmarking rsjson

This directory contains comprehensive benchmarking tools for evaluating rsjson performance against other Lua JSON libraries.

## Quick Start

1. **Build rsjson**:
   ```bash
   cargo build --release
   ```

2. **Install comparison libraries** (optional but recommended):
   ```bash
   # Ubuntu/Debian
   sudo apt-get install lua-cjson-dev lua-dkjson
   
   # macOS with Homebrew
   brew install lua-cjson
   luarocks install dkjson
   
   # Or install via LuaRocks
   luarocks install lua-cjson
   luarocks install dkjson
   ```

3. **Run simple benchmark**:
   ```bash
   cd benchmarks
   lua simple_benchmark.lua
   ```

4. **Run comprehensive benchmark**:
   ```bash
   lua comprehensive_benchmark.lua
   ```

## Benchmark Scripts

### `simple_benchmark.lua`
- **Purpose**: Quick performance comparison
- **Duration**: ~30 seconds
- **Output**: Basic timing and ops/sec metrics
- **Best for**: CI/CD, quick validation, development

**Example Output**:
```
Library    Dataset      Op       Time(s)   Ops/sec     Mem(KB)
----------------------------------------------------------------------
rsjson     small        encode     0.156     320513       12.5
dkjson     small        encode     0.892      55984       45.2
rsjson     small        decode     0.134     373134       8.1
dkjson     small        decode     1.123      44506       52.3

=== Performance Comparison ===
small        encode: rsjson is 5.7x faster than dkjson  
small        decode: rsjson is 8.4x faster than dkjson
```

### `comprehensive_benchmark.lua`
- **Purpose**: Detailed performance analysis
- **Duration**: ~5 minutes  
- **Output**: Statistical analysis, memory usage, error handling
- **Best for**: Performance regression testing, detailed analysis

**Features**:
- Multiple test datasets (small, medium, large array, deep nested, large object)
- Statistical analysis (min/max/avg/median/std deviation)
- Memory usage tracking
- Error handling performance
- Multiple runs for statistical reliability

## Test Datasets

### Small Dataset
- **Size**: ~50 bytes JSON
- **Structure**: Simple object with basic types
- **Iterations**: 50,000
- **Use case**: Microservice API responses, configuration data

### Medium Dataset  
- **Size**: ~300 bytes JSON
- **Structure**: Nested objects with arrays
- **Iterations**: 10,000
- **Use case**: User profiles, application state

### Large Array Dataset
- **Size**: ~50KB JSON  
- **Structure**: 1,000 item array with nested objects
- **Iterations**: 1,000
- **Use case**: Data export, bulk operations

### Deep Nested Dataset
- **Size**: ~2KB JSON
- **Structure**: 100 levels of nesting
- **Iterations**: 5,000  
- **Use case**: Complex configuration, tree structures

### Large Object Dataset
- **Size**: ~100KB JSON
- **Structure**: 500 fields with nested data
- **Iterations**: 500
- **Use case**: Database records, complex documents

## Interpreting Results

### Performance Metrics

- **Operations per second (ops/sec)**: Higher is better
- **Time (seconds)**: Lower is better  
- **Memory (KB)**: Lower is generally better
- **Standard deviation**: Lower indicates more consistent performance

### Expected Performance Characteristics

**rsjson** (Rust implementation):
- ✅ **Fast encoding/decoding**: 2-10x faster than pure Lua implementations
- ✅ **Low memory usage**: Minimal allocation overhead
- ✅ **Consistent performance**: Low standard deviation
- ✅ **Large data handling**: Scales well with data size

**dkjson** (Pure Lua):
- ✅ **Reliable**: Mature, well-tested implementation  
- ✅ **Portable**: Works everywhere Lua works
- ❌ **Slower**: Pure Lua implementation
- ❌ **Memory overhead**: Higher allocation patterns

**lua-cjson** (C implementation):
- ✅ **Very fast**: Often fastest for encoding
- ✅ **Mature**: Widely used in production
- ❌ **Platform dependent**: Requires C compilation
- ❌ **Error handling**: Can be inconsistent

## Running Automated Benchmarks

### CI/CD Integration

Add to your GitHub Actions workflow:

```yaml
- name: Run JSON benchmarks
  run: |
    cd benchmarks
    lua simple_benchmark.lua > benchmark_results.txt
    cat benchmark_results.txt
    
- name: Upload benchmark results  
  uses: actions/upload-artifact@v3
  with:
    name: benchmark-results
    path: benchmarks/benchmark_results.txt
```

### Performance Regression Testing

```bash
# Run baseline benchmark
lua simple_benchmark.lua > baseline_results.txt

# After changes, compare results  
lua simple_benchmark.lua > new_results.txt
diff baseline_results.txt new_results.txt
```

### Custom Benchmark Scenarios

Create custom benchmarks for your specific use case:

```lua
-- Custom data structure
local my_data = {
    -- Your specific JSON structure
}

-- Custom benchmark
local result = benchmark("my_test", 
    function() rsjson.encode(my_data) end, 
    10000)
    
print("My data encode: " .. result.ops_per_sec .. " ops/sec")
```

## Troubleshooting

### Library Not Found Errors

```bash
# Check library path
lua -e "print(package.cpath)"

# Install missing libraries
luarocks install dkjson
luarocks install lua-cjson

# Or copy rsjson library to Lua path
cp ../target/release/librsjson.so /usr/local/lib/lua/5.4/rsjson.so
```

### Memory Issues

```bash
# Increase Lua memory limit if needed
ulimit -v 2097152  # 2GB virtual memory limit
```

### Platform-Specific Notes

**macOS**: Use Homebrew for lua-cjson installation
**Linux**: Use package manager (apt, yum) for lua-cjson-dev  
**Windows**: Consider using lua-cjson from LuaRocks

## Contributing

When adding new benchmark scenarios:

1. **Add to both simple and comprehensive benchmarks**
2. **Include realistic data structures** 
3. **Document expected performance characteristics**
4. **Test across multiple Lua versions**
5. **Update this README with new scenarios**

## Performance Goals

Target performance characteristics for rsjson:

- **Small data**: >300k ops/sec encoding, >400k ops/sec decoding
- **Medium data**: >50k ops/sec encoding, >80k ops/sec decoding  
- **Large arrays**: >5k ops/sec encoding, >8k ops/sec decoding
- **Memory usage**: <50% of pure Lua implementations
- **Consistency**: <10% standard deviation across runs