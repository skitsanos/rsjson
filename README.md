# rsjson

[![CI/CD Pipeline](https://github.com/skitsanos/rsjson/actions/workflows/build.yml/badge.svg)](https://github.com/skitsanos/rsjson/actions/workflows/build.yml)

`rsjson` is a Rust-backed JSON encoder and decoder for Lua, LuaJIT, and OpenResty environments. It exposes a small Lua module API while using `serde_json` for JSON parsing and serialization.

## Features

- **Fast JSON handling**: parsing and serialization are delegated to `serde_json`.
- **Lua and LuaJIT support**: one Rust crate supports Lua 5.1, 5.2, 5.3, 5.4, and LuaJIT through feature flags.
- **OpenResty ready**: the `luajit` feature builds the module used by OpenResty containers.
- **Low runtime overhead**: module initialization does not create a separate Lua VM, and decode avoids copying the input string before parsing.
- **Safer table handling**: sequential Lua tables encode as JSON arrays regardless of table iteration order; sparse, mixed, and recursive tables are handled explicitly.
- **Cross-platform CI**: GitHub Actions builds Linux, macOS, and Windows targets and runs formatting, tests, and Clippy on Rust 1.96.0.

## Toolchain

The project is pinned to Rust `1.96.0` through `rust-toolchain.toml`. Install Rust with `rustup`; Cargo will automatically select the pinned toolchain inside this repository.

Required local checks:

```bash
cargo fmt --all -- --check
cargo test --workspace
cargo clippy --all-targets -- -D warnings
```

For the OpenResty/LuaJIT target, also run:

```bash
cargo test --workspace --no-default-features --features luajit
cargo build --release --no-default-features --features luajit
```

## Installation

### Build From Source

```bash
git clone https://github.com/skitsanos/rsjson.git
cd rsjson
```

Build for the target Lua runtime:

```bash
# Lua 5.4 (default)
cargo build --release

# Other Lua versions
cargo build --release --no-default-features --features lua53
cargo build --release --no-default-features --features lua52
cargo build --release --no-default-features --features lua51

# LuaJIT / OpenResty
cargo build --release --no-default-features --features luajit
```

The shared library is written to `target/release/`:

| Platform | Output |
|---|---|
| Linux | `librsjson.so` |
| macOS | `librsjson.dylib` |
| Windows | `rsjson.dll` |

### Supported Lua Versions

| Runtime | Feature Flag | Minimum Version |
|---|---|---|
| Lua 5.4 | `lua54` (default) | 5.4.0+ |
| Lua 5.3 | `lua53` | 5.3.0+ |
| Lua 5.2 | `lua52` | 5.2.0+ |
| Lua 5.1 | `lua51` | 5.1.0+ |
| LuaJIT | `luajit` | 2.0.0+ |

### Prerequisites

Install the development package for the Lua runtime you are building against.

macOS with Homebrew:

```bash
brew install lua@5.4
brew install lua@5.3
brew install luajit
```

Ubuntu/Debian:

```bash
sudo apt-get install liblua5.4-dev
sudo apt-get install liblua5.3-dev
sudo apt-get install liblua5.2-dev
sudo apt-get install liblua5.1-dev
sudo apt-get install libluajit-5.1-dev
```

Alpine Linux:

```bash
apk add lua5.4-dev
apk add lua5.3-dev
apk add lua5.2-dev
apk add lua5.1-dev
apk add luajit-dev
```

### Build Path Overrides

The build script detects common Linux, Alpine, Homebrew, and CI layouts. If your Lua installation is in a custom location, set the library directory explicitly:

```bash
LUA_DIR=/path/to/lua/lib cargo build --release --no-default-features --features lua54
LUAJIT_DIR=/path/to/luajit/lib cargo build --release --no-default-features --features luajit
```

On Apple Silicon Homebrew, Lua 5.4 is usually:

```bash
LUA_DIR=/opt/homebrew/opt/lua@5.4/lib cargo build --release
```

The project intentionally prefers versioned Homebrew formulae such as `lua@5.4`; the unversioned `lua` formula may point to a newer Lua ABI than the selected Cargo feature.

## OpenResty and Railway

OpenResty uses LuaJIT, so build rsjson with the `luajit` feature:

```bash
cargo build --release --no-default-features --features luajit
```

In an OpenResty container, copy `target/release/librsjson.so` into a directory on `package.cpath`, commonly `/app/lib/rsjson.so`:

```bash
cp target/release/librsjson.so /app/lib/rsjson.so
```

The included [docker/Dockerfile.luajit](docker/Dockerfile.luajit) demonstrates this layout for an OpenResty Bookworm image. It uses a Rust 1.96 builder stage and copies only the compiled module into the OpenResty runtime image to reduce image size and Railway runtime cost.

Runtime notes:

- Use `luajit` builds for OpenResty; do not load a Lua 5.4 build into OpenResty.
- Prefer a glibc OpenResty image for rsjson. Rust does not support producing this `cdylib` Lua module for the Linux musl target used by Alpine.
- Keep `package.cpath` pointed at the compiled module path.
- Reuse the module through Lua's normal `require("rsjson")` cache.
- Avoid pretty serialization on hot paths unless formatted output is required.

## Usage

```lua
local json = require("rsjson")

local json_string = '{"user":"demo","debug":true,"unique_id":123456,"meta":{"items":["1","2","3"]}}'

local doc = json.decode(json_string)
print(doc.user)

local encoded = json.encode(doc)
print(encoded)
```

Aliases are provided for compatibility:

| Function | Alias | Description |
|---|---|---|
| `decode(json_string)` | `parse(json_string)` | Decode JSON into Lua values. |
| `encode(value)` | `stringify(value)` | Encode Lua values into compact JSON. |
| `stringify_pretty(value)` | none | Encode Lua values into pretty JSON. |

### Table Encoding Semantics

Lua tables do not distinguish arrays from objects at the type level. rsjson uses these rules:

- Tables with exactly the positive integer keys `1..n` encode as JSON arrays.
- Empty tables encode as empty arrays.
- Sparse tables, mixed tables, and tables with non-integer keys encode as JSON objects.
- Numeric object keys are converted to JSON object key strings.
- Recursive tables return an error because JSON cannot represent cycles.

## Performance

### vs Pure Lua (dkjson)

Comparison with dkjson:

| Dataset | Operation | rsjson ops/sec | dkjson ops/sec | Speedup |
|---|---:|---:|---:|---:|
| Small (50B) | encode | 1,329,717 | 251,797 | 5.3x |
| Small (50B) | decode | 1,002,526 | 177,503 | 5.8x |
| Medium (300B) | encode | 522,548 | 108,846 | 4.9x |
| Medium (300B) | decode | 343,136 | 72,585 | 4.7x |
| Large Array (50KB) | encode | 1,512 | 284 | 5.4x |
| Large Array (50KB) | decode | 1,035 | 169 | 6.1x |

### vs lua-cjson

Comparison with lua-cjson 2.1.0.10:

| Library | Encode ops/sec | Decode ops/sec | Notes |
|---|---:|---:|---|
| lua-cjson | 1,969,279 | 1,440,673 | Fastest raw speed |
| rsjson | 754,102 | 493,418 | Rust memory safety and consistent table handling |
| dkjson | 146,611 | 100,631 | Pure Lua portability |

Choose rsjson when reliability, memory safety, and cross-platform Cargo builds matter. Choose lua-cjson when maximum raw throughput is the only priority and the input/table shapes are tightly controlled.

Run local benchmarks with:

```bash
./benchmarks/run_benchmarks.sh
./benchmarks/run_benchmarks.sh -t comprehensive
./benchmarks/run_benchmarks.sh -o benchmark_results.txt
```

## Development

### Rust Checks

```bash
cargo fmt --all -- --check
cargo test --workspace
cargo clippy --all-targets -- -D warnings
```

### Docker Tests

Run the quick Docker smoke test:

```bash
./docker/test-simple.sh
```

Run all Docker tests:

```bash
./docker/test-all.sh
```

Build individual containers:

```bash
docker build -f docker/Dockerfile.lua54 -t rsjson:lua54 .
docker build -f docker/Dockerfile.luajit -t rsjson:luajit .
```

### CI/CD

GitHub Actions uses:

- Rust `1.96.0`
- `actions/checkout@v6.0.3`
- `actions/upload-artifact@v7.0.1`
- `softprops/action-gh-release@v3.0.0`
- `leafo/gh-actions-lua@v13.0.0`
- Linux, macOS, and Windows build matrix
- Linux quality gate for `fmt`, `test`, and `clippy`
- Docker smoke testing on Alpine Linux

See [PIPELINE.md](PIPELINE.md) for details.

## Contributing

1. Fork the repository.
2. Create a feature branch.
3. Make focused changes with tests.
4. Run `cargo fmt --all -- --check`, `cargo test --workspace`, and `cargo clippy --all-targets -- -D warnings`.
5. Submit a pull request.

## License

This project is licensed under the MIT License.
