# rsjson

`rsjson` is a Rust library designed to be called from OpenResty Lua for JSON encoding and decoding. It provides a
high-performance, safe, and easy-to-use solution for working with JSON data in Lua.

## Features

- **High Performance**: Written in Rust, `rsjson` is designed for speed.
- **Safety**: Leverages Rust's strong type system and error handling.
- **Ease of Use**: Simple API with only two methods, `encode` and `decode`.
- **Unified Solution**: Single codebase supports both Lua 5.4 and LuaJIT through feature flags.

## Installation

### Build the Rust Library

1. Clone the repository and navigate to its directory.
2. Build for your target Lua version:
   - **Lua 5.4** (default): `cargo build --release`
   - **Lua 5.3**: `cargo build --release --no-default-features --features lua53`
   - **Lua 5.2**: `cargo build --release --no-default-features --features lua52`
   - **Lua 5.1**: `cargo build --release --no-default-features --features lua51`
   - **LuaJIT**: `cargo build --release --no-default-features --features luajit`
3. The dynamic library (`librsjson.so` on Linux, `librsjson.dylib` on macOS) will be in the `target/release` directory.

### Supported Lua Versions

| Version | Feature Flag | Minimum Version |
|---------|--------------|-----------------|
| Lua 5.4 | `lua54` (default) | 5.4.0+ |
| Lua 5.3 | `lua53` | 5.3.0+ |
| Lua 5.2 | `lua52` | 5.2.0+ |
| Lua 5.1 | `lua51` | 5.1.0+ |
| LuaJIT  | `luajit` | 2.0.0+ |

**Note**: You need to have the corresponding Lua development headers installed:
- **macOS**: `brew install lua` (5.4), `brew install lua@5.3`, etc., or `brew install luajit`
- **Ubuntu/Debian**: `apt-get install liblua5.4-dev`, `libluajit-5.1-dev`, etc.
- **CentOS/RHEL**: `yum install lua-devel`, `luajit-devel`, etc.

### Lua Bindings

Copy the `rsjson.lua` file to your OpenResty Lua project.

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

## API

`json.decode(json_string: string) -> table`
Decodes a JSON-formatted string and returns a Lua table.

`json.encode(lua_table: table) -> string`
Encodes a Lua table into a JSON-formatted string.

## Contributing

Feel free to open issues or pull requests if you have suggestions or improvements.

## License

This project is licensed under the MIT License.

