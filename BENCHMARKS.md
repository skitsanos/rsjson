# Benchmark Results Analysis

This file records the current benchmark interpretation for rsjson. Treat the numbers as a point-in-time reference, not as a release guarantee.

## Executive Summary

rsjson targets a middle ground between pure Lua portability and C-library raw speed:

- Faster than pure Lua implementations such as dkjson on typical encode/decode workloads.
- Slower than lua-cjson in raw throughput, but implemented in Rust and integrated with Cargo, tests, Clippy, and cross-platform CI.
- Better-defined Lua table conversion behavior than libraries that infer arrays directly from Lua's length operator alone.
- Suitable for OpenResty/LuaJIT deployment when built with `--features luajit`.

## Current Benchmark Workflow

Default Lua 5.4 benchmark:

```bash
./benchmarks/run_benchmarks.sh --build --feature lua54 --lua lua5.4
```

OpenResty/LuaJIT benchmark:

```bash
./benchmarks/run_benchmarks.sh --build --feature luajit --lua luajit
```

Comprehensive benchmark:

```bash
./benchmarks/run_benchmarks.sh --type comprehensive
```

## Current Local Results

These results were captured on June 14, 2026 after the Rust 1.96.0/tooling changes and benchmark runner updates.

Environment:

- Hardware: Apple Silicon Mac
- Lua 5.4 executable: `/opt/homebrew/opt/lua@5.4/bin/lua`
- LuaJIT executable: `luajit`
- Rust toolchain: 1.96.0
- Benchmark type: `comprehensive`
- Runs per operation: 5, except summary comparisons
- lua-cjson: available for Lua 5.4, not available for the tested LuaJIT installation
- rapidjson: not available

Lua 5.4 operations per second:

| Library | Small Encode | Small Decode | Medium Encode | Medium Decode | Large Array Encode | Large Array Decode | Large Object Encode | Large Object Decode | Sparse Encode | Sparse Decode |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| rsjson | 719,592 | 627,800 | 156,290 | 116,058 | 554 | 397 | 815 | 634 | 1,062,462 | 761,012 |
| dkjson | 193,652 | 130,878 | 38,913 | 26,803 | 132 | 79 | 171 | 114 | 235,629 | 185,182 |
| lua-cjson | 2,252,110 | 1,633,293 | 550,770 | 313,596 | 1,604 | 965 | 1,217 | 1,315 | 2,965,775 | 2,672,725 |

LuaJIT operations per second:

| Library | Small Encode | Small Decode | Medium Encode | Medium Decode | Large Array Encode | Large Array Decode | Large Object Encode | Large Object Decode | Sparse Encode | Sparse Decode |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| rsjson | 741,461 | 506,622 | 155,239 | 89,761 | 541 | 281 | 866 | 468 | 1,107,604 | 649,984 |
| dkjson | 447,481 | 372,545 | 67,182 | 71,303 | 270 | 207 | 347 | 307 | 535,667 | 573,644 |

Deep nesting operations per second:

| Runtime | Library | Encode | Decode |
|---|---|---:|---:|
| Lua 5.4 | rsjson | 18,276 | 13,455 |
| Lua 5.4 | dkjson | 4,836 | 2,792 |
| Lua 5.4 | lua-cjson | 49,635 | 34,645 |
| LuaJIT | rsjson | 19,039 | 11,054 |
| LuaJIT | dkjson | 9,717 | 8,000 |

Current interpretation:

- rsjson remains substantially faster than dkjson on stock Lua 5.4 across every measured dataset.
- On LuaJIT, dkjson narrows the gap because LuaJIT accelerates pure Lua code, but rsjson still wins most measured encode/decode cases.
- lua-cjson remains faster than rsjson on stock Lua 5.4 raw throughput.
- Large decode paths are the clearest place to keep watching for regressions, especially under LuaJIT/OpenResty.
- The current implementation improved encode-heavy and object-table workloads by avoiding the old generated C wrapper, reducing avoidable string handling, and classifying Lua tables in one pass.

## Historical Results

Historical test environment:

- Hardware: Apple M4 Pro
- Memory: 24GB RAM
- Operating system: macOS 15.6
- Lua version: 5.4.8
- rsjson version: 2.1.0 built from source
- lua-cjson: 2.1.0.10
- dkjson: 2.5
- Date: August 13, 2025

Operations per second, higher is better:

| Library | Small Encode | Small Decode | Medium Encode | Medium Decode | Large Encode | Large Decode |
|---|---:|---:|---:|---:|---:|---:|
| lua-cjson | 1,969,279 | 1,440,673 | 1,760,873 | 1,043,841 | 2,540 | 3,017 |
| rsjson | 754,102 | 493,418 | 530,645 | 346,656 | 1,508 | 1,027 |
| dkjson | 146,611 | 100,631 | 104,909 | 75,116 | 282 | 168 |

These numbers predate the current table-classification and benchmark-runner updates. Re-run the benchmark suite before using the figures for release notes or performance claims.

## Table Semantics

Lua tables do not encode enough type information to distinguish JSON arrays from JSON objects. rsjson currently uses these rules:

- Tables with exactly the positive integer keys `1..n` encode as JSON arrays.
- Empty tables encode as empty arrays.
- Sparse tables encode as JSON objects.
- Mixed tables encode as JSON objects.
- Numeric object keys are converted to JSON object key strings.
- Recursive tables return an error.

The benchmark suite includes a sparse mixed table dataset so this behavior is measured along with simple object and array cases.

## Library Tradeoffs

### rsjson

Strengths:

- Rust implementation with memory safety guarantees.
- Strong Cargo and CI integration.
- Consistent cross-platform build story.
- Explicit sparse/mixed/recursive table behavior.
- Good performance versus pure Lua libraries.

Tradeoffs:

- Native module build is required.
- Raw throughput is generally below lua-cjson.
- The correct Lua ABI feature must match the runtime.

### lua-cjson

Strengths:

- Very fast raw encode/decode throughput.
- Widely deployed in OpenResty environments.
- Mature C implementation.

Tradeoffs:

- C memory-safety risk profile.
- Platform-specific build and packaging behavior.
- Table edge cases may not match rsjson semantics.

### dkjson

Strengths:

- Pure Lua implementation.
- Easy to vendor.
- Broad Lua compatibility.

Tradeoffs:

- Slower on CPU-heavy JSON workloads.
- Higher Lua-side allocation pressure.

## Performance Guidance

For Railway/OpenResty deployments:

- Benchmark with `luajit`, not only stock `lua`.
- Build with `--no-default-features --features luajit`.
- Keep benchmark data close to production payload shapes.
- Include encode and decode hot paths separately.
- Avoid `stringify_pretty` in hot paths unless formatted JSON is required.

For release comparisons:

- Run each benchmark multiple times.
- Compare medians or averages, not a single run.
- Record hardware, OS, Lua executable, rsjson commit, and comparison library versions.
- Keep the same Lua runtime and feature flags between baseline and candidate runs.

## Reproducing Results

```bash
cargo build --release
luarocks install dkjson
luarocks install lua-cjson
./benchmarks/run_benchmarks.sh --type simple
./benchmarks/run_benchmarks.sh --type comprehensive
```

Results vary by CPU, OS, Lua runtime, compiler version, and system load. The relative relationships are more useful than exact operation counts.
