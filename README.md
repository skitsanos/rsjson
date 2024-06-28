# rsjson

`rsjson` is a Rust library designed to be called from OpenResty Lua for JSON encoding and decoding. It provides a
high-performance, safe, and easy-to-use solution for working with JSON data in Lua.

## Features

- **High Performance**: Written in Rust, `rsjson` is designed for speed.
- **Safety**: Leverages Rust's strong type system and error handling.
- **Ease of Use**: Simple API with only two methods, `encode` and `decode`.

## Installation

### Build the Rust Library

1. Clone the repository and navigate to its directory.
2. Run `cargo build --release`.
3. The dynamic library (`librsjson.so` on Linux, `librsjson.dylib` on macOS) will be in the `target/release` directory.

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

