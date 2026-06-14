#!/usr/bin/env bash

# Benchmark runner script for rsjson
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

BENCHMARK_TYPE="simple"
OUTPUT_FILE=""
LUA_BIN="${LUA_BIN:-lua}"
FEATURE="${RSJSON_FEATURE:-lua54}"
BUILD_FIRST=0
LIB_DIR="$PROJECT_ROOT/target/release"

usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Options:
  -t, --type TYPE       Benchmark type: simple, comprehensive (default: simple)
  -o, --output FILE     Save output to file
      --lua BIN         Lua executable to use, for example lua, lua5.4, luajit
      --feature FEATURE Cargo feature to build when --build is used (default: lua54)
      --build           Build rsjson before running benchmarks
  -h, --help            Show this help
EOF
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--type)
            BENCHMARK_TYPE="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        --lua)
            LUA_BIN="$2"
            shift 2
            ;;
        --feature)
            FEATURE="$2"
            shift 2
            ;;
        --build)
            BUILD_FIRST=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h for help"
            exit 1
            ;;
    esac
done

echo "=== rsjson Benchmark Suite ==="
echo "Project root: $PROJECT_ROOT"
echo "Script directory: $SCRIPT_DIR"
echo "Lua executable: $LUA_BIN"
echo

if [ "$BUILD_FIRST" -eq 1 ]; then
    echo "Building rsjson with feature: $FEATURE"
    LIB_DIR="$PROJECT_ROOT/target/bench-$FEATURE/release"
    cargo build \
        --release \
        --no-default-features \
        --features "$FEATURE" \
        --manifest-path "$PROJECT_ROOT/rsjson/Cargo.toml" \
        --target-dir "$PROJECT_ROOT/target/bench-$FEATURE"
    echo
fi

# Check if rsjson is built
if [ ! -f "$LIB_DIR/librsjson.so" ] && [ ! -f "$LIB_DIR/librsjson.dylib" ]; then
    echo "ERROR: rsjson library not found in $LIB_DIR"
    echo "Build first with cargo build --release, or pass --build --feature lua54"
    exit 1
fi

echo "OK: rsjson library found"

# Check Lua installation
if ! command -v "$LUA_BIN" >/dev/null 2>&1; then
    echo "ERROR: Lua executable not found: $LUA_BIN"
    exit 1
fi

LUA_VERSION=$("$LUA_BIN" -e "print(_VERSION)")
echo "OK: Found $LUA_VERSION"

case "$FEATURE" in
    lua51)
        EXPECTED_LUA_VERSION="Lua 5.1"
        ;;
    lua52)
        EXPECTED_LUA_VERSION="Lua 5.2"
        ;;
    lua53)
        EXPECTED_LUA_VERSION="Lua 5.3"
        ;;
    lua54)
        EXPECTED_LUA_VERSION="Lua 5.4"
        ;;
    luajit)
        EXPECTED_LUA_VERSION=""
        if ! "$LUA_BIN" -e "if not jit then os.exit(1) end" >/dev/null 2>&1; then
            echo "ERROR: --feature luajit requires a LuaJIT executable. Use --lua luajit."
            exit 1
        fi
        ;;
    *)
        EXPECTED_LUA_VERSION=""
        ;;
esac

if [ -n "${EXPECTED_LUA_VERSION:-}" ] && [ "$LUA_VERSION" != "$EXPECTED_LUA_VERSION" ]; then
    echo "ERROR: --feature $FEATURE expects $EXPECTED_LUA_VERSION, but --lua resolved to $LUA_VERSION."
    echo "Use a matching Lua executable or rebuild with the feature for this runtime."
    exit 1
fi

# Create rsjson.so symlink for Lua loaders that only try ?.so.
if [ -f "$LIB_DIR/librsjson.dylib" ]; then
    ln -sf librsjson.dylib "$LIB_DIR/rsjson.so"
fi

if [ -f "$LIB_DIR/librsjson.so" ]; then
    ln -sf librsjson.so "$LIB_DIR/rsjson.so"
fi

# Set up library path for rsjson
export LUA_CPATH="$LIB_DIR/?.so;$LIB_DIR/lib?.so;$LIB_DIR/?.dylib;$LIB_DIR/lib?.dylib;;${LUA_CPATH:-}"
export LUA_PATH="$PROJECT_ROOT/src-lua/?.lua;;${LUA_PATH:-}"

# Check available JSON libraries
echo
echo "Checking available JSON libraries:"

# Check rsjson
if "$LUA_BIN" -e "require('rsjson')" 2>/dev/null; then
    echo "  OK: rsjson"
else
    echo "  ERROR: rsjson (check build feature, Lua ABI, and library path)"
    exit 1
fi

# Check dkjson
if "$LUA_BIN" -e "require('dkjson')" 2>/dev/null; then
    echo "  OK: dkjson"
else
    echo "  MISSING: dkjson (install with: luarocks install dkjson)"
fi

# Check cjson
if "$LUA_BIN" -e "require('cjson')" 2>/dev/null; then
    echo "  OK: cjson"
else
    echo "  MISSING: cjson (install with: luarocks install lua-cjson)"
fi

echo

# Choose benchmark script
case $BENCHMARK_TYPE in
    simple)
        BENCHMARK_SCRIPT="simple_benchmark.lua"
        echo "Running simple benchmark (quick, ~30 seconds)..."
        ;;
    comprehensive|comp)
        BENCHMARK_SCRIPT="comprehensive_benchmark.lua"  
        echo "Running comprehensive benchmark (detailed, ~5 minutes)..."
        ;;
    *)
        echo "Unknown benchmark type: $BENCHMARK_TYPE"
        echo "Available types: simple, comprehensive"
        exit 1
        ;;
esac

if [ -n "$OUTPUT_FILE" ] && [[ "$OUTPUT_FILE" != /* ]]; then
    OUTPUT_FILE="$PWD/$OUTPUT_FILE"
fi

# Change to benchmarks directory
cd "$SCRIPT_DIR"

# Run benchmark
echo "Starting benchmark..."
echo

if [ -n "$OUTPUT_FILE" ]; then
    "$LUA_BIN" "$BENCHMARK_SCRIPT" | tee "$OUTPUT_FILE"
    echo
    echo "Results saved to: $OUTPUT_FILE"
else
    "$LUA_BIN" "$BENCHMARK_SCRIPT"
fi

echo
echo "Benchmark completed!"
echo
echo "Tip: Run multiple times and average results for production benchmarking."
echo "Tip: Use -o option to save results: $0 -o benchmark_$(date +%Y%m%d_%H%M%S).txt"
