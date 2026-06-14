# Pipeline Implementation Guide

This document describes the current rsjson build, test, Docker, and release pipeline.

## Current Architecture

rsjson is a Cargo workspace with one library crate:

```text
.
├── Cargo.toml
├── rust-toolchain.toml
├── rsjson/
│   ├── Cargo.toml
│   ├── build.rs
│   └── src/lib.rs
├── docker/
└── .github/workflows/build.yml
```

The crate builds a `cdylib` Lua module using `mlua` and `serde_json`.

Direct runtime dependencies:

```text
mlua
serde_json
```

The project no longer uses a C wrapper, generated bindgen bindings, or a separate Lua state during module initialization. That is important for OpenResty/Railway deployments because module load should not allocate or initialize an unnecessary extra Lua VM.

## Toolchain

Rust is pinned to `1.96.0` in `rust-toolchain.toml` and in GitHub Actions.

Required checks:

```bash
cargo fmt --all -- --check
cargo test --workspace
cargo clippy --all-targets -- -D warnings
```

OpenResty/LuaJIT checks:

```bash
cargo test --workspace --no-default-features --features luajit
cargo build --release --no-default-features --features luajit
```

## Cargo Feature Matrix

`rsjson/Cargo.toml` exposes one feature per Lua ABI:

```toml
[features]
default = ["lua54"]
lua54 = ["mlua/lua54"]
lua53 = ["mlua/lua53"]
lua52 = ["mlua/lua52"]
lua51 = ["mlua/lua51"]
luajit = ["mlua/luajit"]
```

Build examples:

```bash
cargo build --release
cargo build --release --no-default-features --features lua53
cargo build --release --no-default-features --features luajit
```

Only one Lua ABI feature should be enabled per build.

## Build Script

`rsjson/build.rs` is intentionally small. It only selects the Lua library search path and link name. It does not compile C code and does not generate bindings.

Important path rules:

- LuaJIT builds use `LUAJIT_DIR` when provided.
- Lua builds use `LUA_DIR` when provided.
- Homebrew versioned formulae such as `/opt/homebrew/opt/lua@5.4/lib` are preferred over unversioned `/opt/homebrew/opt/lua/lib`.
- Alpine packages store Lua libraries in versioned directories such as `/usr/lib/lua5.4`, but the library name is often `lua`.
- System Linux packages usually expose versioned library names such as `lua5.4`.

Common overrides:

```bash
LUA_DIR=/usr/lib/x86_64-linux-gnu cargo build --release --no-default-features --features lua54
LUAJIT_DIR=/usr/lib cargo build --release --no-default-features --features luajit
```

## GitHub Actions

Workflow: `.github/workflows/build.yml`

Triggers:

- Push to `main` and `develop`
- Pull requests targeting `main`

Permissions:

```yaml
permissions:
  contents: write
```

This is required for tagged release publishing.

### Quality Job

The `quality` job runs on Ubuntu with Rust `1.96.0` and installs Lua 5.4 development headers.

Steps:

```text
checkout
install Rust 1.96.0 with clippy and rustfmt
install liblua5.4-dev
cargo fmt --all -- --check
cargo test --workspace
cargo clippy --all-targets -- -D warnings
```

This job is the main code-quality gate.

### Build Job

The `build` job runs a matrix across operating systems and Lua runtimes:

```yaml
os: [ubuntu-latest, macos-latest, windows-latest]
lua_version: [lua51, lua52, lua53, lua54, luajit]
```

Current exclusions:

- Windows builds only `lua54`.
- macOS builds `lua54` and `luajit`.
- Windows LuaJIT is excluded.

The build job compiles release libraries and uploads artifacts:

| Platform | Artifact |
|---|---|
| Linux | `librsjson.so` |
| macOS | `librsjson.dylib` |
| Windows | `rsjson.dll` |

### Docker Test Job

The `docker-test` job runs:

```bash
./docker/test-simple.sh
```

That script currently builds and runs the Lua 5.4 Alpine container. Use `./docker/test-all.sh` locally when validating every Dockerfile.

### Release Steps

On tags, the workflow builds LuaRocks packages for `lua54` and creates a GitHub release through `softprops/action-gh-release@v3.0.0`.

Current major action versions:

```text
actions/checkout@v6.0.3
dtolnay/rust-toolchain@1.96.0
leafo/gh-actions-lua@v13.0.0
actions/upload-artifact@v7.0.1
softprops/action-gh-release@v3.0.0
```

## Docker Pipeline

The Docker setup has two roles:

- Standalone Lua containers for Lua 5.1 through Lua 5.4.
- OpenResty container for LuaJIT.

Standalone Dockerfiles:

```text
docker/Dockerfile.lua51
docker/Dockerfile.lua52
docker/Dockerfile.lua53
docker/Dockerfile.lua54
```

OpenResty Dockerfile:

```text
docker/Dockerfile.luajit
```

### Standalone Lua Dockerfiles

Each standalone Dockerfile uses a multi-stage Alpine build:

1. Install build dependencies, Rust, Cargo, Clang, and Lua development headers.
2. Copy Cargo manifests and `build.rs` for Docker layer caching.
3. Copy `rsjson/src`.
4. Build `librsjson.so`.
5. Copy only the shared library and test script into the runtime image.

The workspace target directory is `/build/target`, not `/build/rsjson/target`, because Cargo uses the workspace root.

### OpenResty Dockerfile

`docker/Dockerfile.luajit` builds with:

```bash
cargo build --release --locked --no-default-features --features luajit
```

This image intentionally uses `rust:1.96-bookworm` for the builder and `openresty/openresty:bookworm` for the runtime. Rust does not support producing this `cdylib` Lua module for the Linux musl target used by Alpine, so a glibc OpenResty image is the practical deployment target for rsjson.

The resulting `librsjson.so` is copied to:

```text
/usr/lib/librsjson.so
/app/lib/librsjson.so
/app/lib/rsjson.so
```

Build dependencies are removed after compilation to keep the runtime image smaller. This matters in Railway-style deployments where image size, startup work, memory, and CPU all have cost impact.

## Local Verification

Run the Rust checks:

```bash
cargo fmt --all -- --check
cargo test --workspace
cargo clippy --all-targets -- -D warnings
```

Run LuaJIT-specific checks:

```bash
cargo test --workspace --no-default-features --features luajit
cargo build --release --no-default-features --features luajit
```

Run Docker checks:

```bash
./docker/test-simple.sh
./docker/test-all.sh
```

Build individual images:

```bash
docker build -f docker/Dockerfile.lua54 -t rsjson:lua54 .
docker build -f docker/Dockerfile.luajit -t rsjson:luajit .
```

## Runtime Behavior Worth Testing

The Rust unit tests cover these table conversion rules:

- Out-of-order integer keys `1..n` encode as arrays.
- Mixed tables encode as objects.
- Sparse integer-keyed tables encode as objects.
- Recursive tables return an error instead of recursing indefinitely.

These are especially important because Lua's `pairs()` order is not guaranteed.

## Maintenance Guidelines

### Updating Rust

1. Update `rust-toolchain.toml`.
2. Update `rust-version` in `rsjson/Cargo.toml`.
3. Update `dtolnay/rust-toolchain@...` in `.github/workflows/build.yml`.
4. Run the full local verification set.

### Updating Dependencies

1. Check direct dependency releases.
2. Avoid release candidates for production unless there is a specific reason.
3. Run `cargo update`.
4. Run Rust, LuaJIT, and Docker checks.

### Adding a Lua Version

1. Add a Cargo feature.
2. Update `build.rs` link detection.
3. Add CI matrix entries and exclusions.
4. Add or update Dockerfiles.
5. Update README and this file.

### Debugging Link Failures

Check:

- Selected Cargo feature matches the runtime ABI.
- `LUA_DIR` or `LUAJIT_DIR` points to a library directory, not an include directory.
- Alpine uses versioned library directories but may link with `-llua`.
- Homebrew unversioned `lua` may point to a newer Lua ABI; prefer `lua@5.4` for the default feature.

Useful commands:

```bash
cargo build --release --verbose
otool -L target/release/librsjson.dylib
ldd target/release/librsjson.so
```

## Current Known Tradeoffs

- `mlua` is kept on the latest stable `0.11.x`; `0.12.x` is still a release candidate at the time of this update.
- The CI matrix builds release artifacts for multiple platforms, while the deep quality gate runs once on Ubuntu. This keeps CI cost reasonable while still enforcing formatting, tests, and Clippy.
- Docker `test-simple.sh` is intentionally a smoke test. Use `test-all.sh` before releases or changes that affect Dockerfiles.

## Summary

The current pipeline optimizes for:

1. Reproducible Rust builds on toolchain `1.96.0`.
2. Low-overhead OpenResty/LuaJIT runtime behavior.
3. Cross-platform release artifacts.
4. Fast local and CI feedback through focused quality gates.
5. Docker coverage for Alpine-based deployment paths.
