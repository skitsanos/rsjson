# RSJSON Docker Testing Plan

This document outlines the testing procedures for the rsjson library across all supported Lua versions using Docker containers.

## Supported Lua Versions

- **Lua 5.4** (default) - using `lua54` feature
- **Lua 5.3** - using `lua53` feature  
- **Lua 5.2** - using `lua52` feature
- **Lua 5.1** - using `lua51` feature
- **LuaJIT** - using `luajit` feature (OpenResty compatible)

## Test Structure

Each Lua version has its own Dockerfile and test environment:

```
docker/
├── TESTPLAN.md           # This document
├── Dockerfile.luajit     # LuaJIT + OpenResty (web server)
├── Dockerfile.lua54      # Lua 5.4 standalone
├── Dockerfile.lua53      # Lua 5.3 standalone  
├── Dockerfile.lua52      # Lua 5.2 standalone
├── Dockerfile.lua51      # Lua 5.1 standalone
├── docker-compose.yml    # Multi-version testing
├── app/
│   ├── index.lua         # OpenResty web test
│   └── test.lua          # Standalone Lua test
└── nginx/
    └── conf/
        └── nginx.conf    # OpenResty configuration
```

## Test Scenarios

### 1. JSON Parsing Test
- Parse a complex JSON string with various data types
- Verify correct Lua table structure
- Test nested objects and arrays

### 2. JSON Generation Test  
- Create Lua table with mixed data types
- Encode to JSON string
- Verify correct JSON format

### 3. Round-trip Test
- Parse JSON → encode back to JSON
- Verify data integrity maintained

### 4. Error Handling Test
- Test invalid JSON input
- Verify proper error messages
- Test edge cases (empty strings, null values)

### 5. Performance Test
- Benchmark encoding/decoding operations
- Compare with other JSON libraries when available

## Testing Procedures

### Individual Version Testing

Build and test a specific Lua version:

```bash
# Test Lua 5.4
docker build -f docker/Dockerfile.lua54 -t rsjson:lua54 .
docker run --rm rsjson:lua54

# Test LuaJIT with OpenResty
docker build -f docker/Dockerfile.luajit -t rsjson:luajit .
docker run -p 8080:80 --rm rsjson:luajit
curl http://localhost:8080
```

### Multi-Version Testing

Test all versions simultaneously:

```bash
# Build all versions
docker-compose build

# Run all tests
docker-compose up

# Run specific version
docker-compose up lua54
```

### Manual Testing Commands

For development and debugging:

```bash
# Interactive shell in container
docker run -it --rm rsjson:lua54 /bin/sh

# Volume mount for live testing
docker run -v $(pwd):/workspace --rm rsjson:lua54 lua /workspace/src-lua/test.lua

# Test with custom JSON data
echo '{"test": "data"}' | docker run -i --rm rsjson:lua54 lua -e 'local json=require("rsjson"); print(json.encode(json.decode(io.read())))'
```

## Expected Test Results

### Successful Test Output

Each test should produce output similar to:

```
rsjson loaded successfully
Decoded user: demo
Decoded debug: true  
Decoded unique_id: 123456
Encoded: {"message":"Hello from rsjson!","timestamp":1234567890,"data":{"user":"demo",...}}
```

### Failure Indicators

- Library loading errors: `Error loading rsjson: ...`
- Compilation errors during build
- Segmentation faults or crashes
- Incorrect JSON output format
- Data loss in round-trip tests

## CI/CD Integration

### GitHub Actions Workflow

```yaml
name: Multi-Lua Testing
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        lua-version: [lua51, lua52, lua53, lua54, luajit]
    steps:
      - uses: actions/checkout@v3
      - name: Test ${{ matrix.lua-version }}
        run: |
          docker build -f docker/Dockerfile.${{ matrix.lua-version }} -t test:${{ matrix.lua-version }} .
          docker run --rm test:${{ matrix.lua-version }}
```

## Maintenance Notes

### When Adding New Features

1. Update test.lua with new functionality tests
2. Run full test suite: `docker-compose up`
3. Verify all versions pass tests
4. Update this document if new test scenarios added

### When Updating Dependencies

1. Update Dockerfiles with new package versions
2. Test build process for all versions
3. Verify runtime compatibility
4. Update base images if needed

### Version-Specific Issues

- **Lua 5.1**: May have integer/number handling differences
- **Lua 5.2**: Environment changes from 5.1
- **LuaJIT**: Performance characteristics and JIT compilation
- **OpenResty**: Web context and ngx API availability

## Troubleshooting

### Common Issues

1. **Build failures**: Check Lua development headers installation
2. **Runtime errors**: Verify library path configuration  
3. **Performance issues**: Compare with native Lua JSON libraries
4. **Memory leaks**: Run with Valgrind in development containers

### Debug Commands

```bash
# Check library loading
docker run --rm rsjson:lua54 lua -e "print(package.cpath)"

# Verify rsjson functions
docker run --rm rsjson:lua54 lua -e "local j=require('rsjson'); print(type(j.encode))"

# Test minimal JSON
docker run --rm rsjson:lua54 lua -e "local j=require('rsjson'); print(j.encode({test=true}))"
```