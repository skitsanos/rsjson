# Benchmarking rsjson

This directory contains benchmark tools for comparing rsjson with other Lua JSON libraries.

## Quick Start

Build and benchmark the default Lua 5.4 target:

```bash
./benchmarks/run_benchmarks.sh --build --feature lua54 --lua lua5.4
```

Build and benchmark the OpenResty/LuaJIT target:

```bash
./benchmarks/run_benchmarks.sh --build --feature luajit --lua luajit
```

Run the comprehensive suite:

```bash
./benchmarks/run_benchmarks.sh --type comprehensive
```

Save output:

```bash
./benchmarks/run_benchmarks.sh --output benchmark_results.txt
```

## Runner Options

```text
Usage: ./benchmarks/run_benchmarks.sh [OPTIONS]

Options:
  -t, --type TYPE       Benchmark type: simple, comprehensive
  -o, --output FILE     Save output to file
      --lua BIN         Lua executable to use, for example lua, lua5.4, luajit
      --feature FEATURE Cargo feature to build when --build is used
      --build           Build rsjson before running benchmarks
  -h, --help            Show help
```

The runner sets `LUA_CPATH` so Lua can load the compiled module and generated `rsjson.so` symlink. When `--build` is used, builds are isolated under `target/bench-<feature>/release` so Lua 5.4 and LuaJIT benchmark runs do not overwrite each other's modules.

The selected `--lua` executable must match the selected `--feature`. For example, use a Lua 5.4 executable with `--feature lua54`, and use `luajit` with `--feature luajit`.

## Optional Comparison Libraries

Install whichever comparison libraries are useful on your platform:

```bash
luarocks install dkjson
luarocks install lua-cjson
luarocks install rapidjson
```

On Ubuntu/Debian:

```bash
sudo apt-get install lua-cjson lua-dkjson
```

## Scripts

### `simple_benchmark.lua`

The simple benchmark is intended for quick local checks. It reports time, operations per second, and Lua heap delta for:

- small object
- medium nested object
- large array
- sparse mixed table

The sparse table case is included because rsjson has explicit table classification rules: dense positive integer keys encode as arrays, while sparse or mixed tables encode as objects.

### `comprehensive_benchmark.lua`

The comprehensive benchmark runs multiple statistical passes and includes:

- small object
- medium nested object
- large array
- deeply nested object
- large object
- sparse mixed table
- malformed JSON error handling

It uses deterministic library ordering and a fixed random seed so output is easier to compare between runs.

## Interpreting Results

Key columns:

- `Ops/sec`: higher is better.
- `Time(s)`: lower is better.
- `Mem(KB)`: Lua heap delta during the benchmark loop; lower usually means less Lua-side allocation pressure.
- `Std Dev`: lower means the runs were more consistent.

Do not compare one-off benchmark runs as release criteria. Run each benchmark several times on an otherwise idle machine and compare medians or averages.

## OpenResty/Railway Notes

For OpenResty deployments, benchmark with LuaJIT:

```bash
./benchmarks/run_benchmarks.sh --build --feature luajit --lua luajit
```

This is the relevant path for Railway OpenResty containers. Benchmarking with stock Lua 5.4 is still useful for development, but it does not represent the OpenResty runtime ABI.

## CI Usage

Benchmarks are not part of the required CI quality gate because runtime performance varies heavily across GitHub-hosted runners. If you want benchmark artifacts for a branch, use the current artifact action major:

```yaml
- name: Run JSON benchmarks
  run: ./benchmarks/run_benchmarks.sh --build --feature lua54 --output benchmark_results.txt

- name: Upload benchmark results
  uses: actions/upload-artifact@v7.0.1
  with:
    name: benchmark-results
    path: benchmark_results.txt
```

## Troubleshooting

### `rsjson` Cannot Be Loaded

Check the selected Lua executable and ABI:

```bash
lua -e "print(_VERSION)"
luajit -e "print(_VERSION, jit.version)"
```

Build with the matching feature:

```bash
cargo build --release --no-default-features --features lua54
cargo build --release --no-default-features --features luajit
```

Then run the benchmark with the matching executable:

```bash
./benchmarks/run_benchmarks.sh --lua lua5.4 --feature lua54
./benchmarks/run_benchmarks.sh --lua luajit --feature luajit
```

### Comparison Libraries Are Missing

The benchmarks still run with only rsjson installed. Missing libraries are reported as `MISSING` and skipped.

### Results Look Noisy

- Close other CPU-heavy applications.
- Run multiple times.
- Prefer comprehensive benchmark medians for regressions.
- Benchmark the same Lua executable and same rsjson feature every time.

## Contributing

When adding benchmark scenarios:

1. Add the dataset to both simple and comprehensive scripts when practical.
2. Keep output ordering deterministic.
3. Include realistic Lua table shapes.
4. Document why the scenario matters.
5. Test with both `lua54` and `luajit` when the change affects OpenResty behavior.
