# rsjson

[![CI/CD Pipeline](https://github.com/skitsanos/rsjson/actions/workflows/build.yml/badge.svg)](https://github.com/skitsanos/rsjson/actions/workflows/build.yml)

`rsjson` is a high-performance Rust library for JSON encoding and decoding in Lua environments. It provides a unified solution supporting multiple Lua versions through feature flags, with comprehensive cross-platform CI/CD testing.

## Features

- **High Performance**: Written in Rust with optimized JSON serialization via serde_json
- **Memory Safety**: Leverages Rust's ownership system and error handling
- **Unified Codebase**: Single implementation supporting all major Lua versions
- **Cross-Platform**: Tested on Windows, macOS, and Linux with full CI/CD coverage
- **Docker Ready**: Containerized testing for all supported Lua versions
- **Simple API**: Clean interface with `encode` and `decode` methods

## Installation

### Build from Source

1. Clone the repository:
   ```bash
   git clone https://github.com/skitsanos/rsjson.git
   cd rsjson
   ```

2. Build for your target Lua version:
   ```bash
   # Lua 5.4 (default)
   cargo build --release
   
   # Other versions
   cargo build --release --no-default-features --features lua53
   cargo build --release --no-default-features --features lua52
   cargo build --release --no-default-features --features lua51
   cargo build --release --no-default-features --features luajit
   ```

3. The shared library will be in `target/release/`:
   - Linux: `librsjson.so`
   - macOS: `librsjson.dylib` 
   - Windows: `rsjson.dll`

### Supported Lua Versions

| Version | Feature Flag | Minimum Version |
|---------|--------------|-----------------|
| Lua 5.4 | `lua54` (default) | 5.4.0+ |
| Lua 5.3 | `lua53` | 5.3.0+ |
| Lua 5.2 | `lua52` | 5.2.0+ |
| Lua 5.1 | `lua51` | 5.1.0+ |
| LuaJIT  | `luajit` | 2.0.0+ |

### Prerequisites

Install Lua development headers for your target version:

**macOS (Homebrew)**:
```bash
brew install lua          # Lua 5.4
brew install lua@5.3      # Lua 5.3
brew install luajit       # LuaJIT
```

**Ubuntu/Debian**:
```bash
sudo apt-get install liblua5.4-dev    # Lua 5.4
sudo apt-get install liblua5.3-dev    # Lua 5.3
sudo apt-get install liblua5.2-dev    # Lua 5.2
sudo apt-get install liblua5.1-dev    # Lua 5.1
sudo apt-get install libluajit-5.1-dev # LuaJIT
```

**Alpine Linux**:
```bash
apk add lua5.4-dev        # Lua 5.4
apk add lua5.3-dev        # Lua 5.3
apk add luajit-dev        # LuaJIT
```

### Integration

1. Copy the built library to your Lua library path
2. Ensure the library is accessible to your Lua runtime via `package.cpath`

### Usage

Here's a simple example demonstrating how to use `rsjson`:

```lua
local json = require('rsjson')

local json_string = '{"user": "demo", "debug": true, "unique_id": 123456, "meta": {"items": ["1","2","3"]}}'

-- Decode JSON string to Lua table
local doc = json.decode(json_string)
print(doc)

-- Encode Lua table to JSON string
print(json.encode(doc))
```

## Performance

### vs Pure Lua (dkjson)

Comparison with dkjson (pure Lua implementation):

| Dataset | Operation | rsjson ops/sec | dkjson ops/sec | **Speedup** |
|---------|-----------|----------------|----------------|-------------|
| Small (50B) | encode | **1,329,717** | 251,797 | **5.3x faster** |
| Small (50B) | decode | **1,002,526** | 177,503 | **5.8x faster** |
| Medium (300B) | encode | **522,548** | 108,846 | **4.9x faster** |
| Medium (300B) | decode | **343,136** | 72,585 | **4.7x faster** |
| Large Array (50KB) | encode | **1,512** | 284 | **5.4x faster** |
| Large Array (50KB) | decode | **1,035** | 169 | **6.1x faster** |

### vs C Implementation (lua-cjson)

Comparison with lua-cjson 2.1.0.10 (C implementation):

| Library | Encode (ops/sec) | Decode (ops/sec) | **Performance** |
|---------|------------------|------------------|-----------------|
| **cjson** | **1,969,279** | **1,440,673** | Fastest raw speed |
| **rsjson** | 754,102 | 493,418 | 2.6x slower encode, 2.9x slower decode |
| **dkjson** | 146,611 | 100,631 | 13.4x slower encode, 14.3x slower decode |

### **Why Choose rsjson over cjson?**

While cjson is faster in pure performance, **rsjson offers significant reliability advantages**:

| **Aspect** | **rsjson** | **lua-cjson** |
|------------|------------|---------------|
| **Sparse Arrays** | ✅ Consistent behavior | ❌ Converts to objects unexpectedly |
| **Number Precision** | ✅ Full precision maintained | ⚠️ Precision loss in large numbers |
| **Memory Safety** | ✅ Rust memory safety guarantees | ❌ C memory management risks |
| **Error Messages** | ✅ Detailed, helpful errors | ⚠️ Generic C-style errors |
| **Unicode Handling** | ✅ Full UTF-8 support | ⚠️ Limited Unicode support |
| **Maintenance** | ✅ Active development | ⚠️ Infrequent updates |
| **Platform Support** | ✅ Cross-platform via Cargo | ❌ Requires C compilation setup |

### **Performance vs Reliability Trade-off**

- **Choose cjson** if: Maximum speed is critical, data is well-controlled, C compilation is acceptable
- **Choose rsjson** if: Reliability and safety matter, cross-platform deployment, modern development practices
- **Choose dkjson** if: Pure Lua portability is required, performance is not critical

**Test Environment**: Apple M4 Pro, 24GB RAM, macOS 15.6, Lua 5.4.8

*Run your own benchmarks with: `./benchmarks/run_benchmarks.sh`*

## API

`json.decode(json_string: string) -> table`
Decodes a JSON-formatted string and returns a Lua table.

`json.encode(lua_table: table) -> string`
Encodes a Lua table into a JSON-formatted string.

## Development

### Testing

Run the full test suite including Docker containers:
```bash
./docker/test-all.sh
```

Build individual Docker containers:
```bash
docker build -f docker/Dockerfile.lua54 -t rsjson:lua54 .
docker build -f docker/Dockerfile.luajit -t rsjson:luajit .
```

### Benchmarking

Run performance benchmarks comparing rsjson with other JSON libraries:

```bash
# Quick benchmark (30 seconds)
./benchmarks/run_benchmarks.sh

# Comprehensive statistical analysis (5 minutes)  
./benchmarks/run_benchmarks.sh -t comprehensive

# Save results to file
./benchmarks/run_benchmarks.sh -o benchmark_results.txt
```

The benchmark suite includes multiple realistic datasets and statistical analysis for reliable performance measurement.

### CI/CD

This project uses GitHub Actions for comprehensive testing across:
- **Platforms**: Windows, macOS, Linux
- **Lua Versions**: 5.1, 5.2, 5.3, 5.4, LuaJIT
- **Containerization**: Docker testing on Alpine Linux

See [PIPELINE.md](PIPELINE.md) for detailed information about our CI/CD implementation.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes with tests
4. Ensure CI/CD passes
5. Submit a pull request

## License

This project is licensed under the MIT License.

