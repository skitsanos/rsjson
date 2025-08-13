#!/bin/bash

# Benchmark runner script for rsjson
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== rsjson Benchmark Suite ==="
echo "Project root: $PROJECT_ROOT"
echo "Script directory: $SCRIPT_DIR"
echo

# Check if rsjson is built
if [ ! -f "$PROJECT_ROOT/target/release/librsjson.so" ] && [ ! -f "$PROJECT_ROOT/target/release/librsjson.dylib" ]; then
    echo "❌ rsjson library not found in target/release/"
    echo "Please build first: cargo build --release"
    exit 1
fi

echo "✅ rsjson library found"

# Check Lua installation
if ! command -v lua &> /dev/null; then
    echo "❌ Lua not found. Please install Lua 5.1-5.4"
    exit 1
fi

LUA_VERSION=$(lua -e "print(_VERSION)")
echo "✅ Found $LUA_VERSION"

# Set up library path for rsjson
export LUA_CPATH="$PROJECT_ROOT/target/release/?.so;$PROJECT_ROOT/target/release/?.dylib;$LUA_CPATH"

# Check available JSON libraries
echo
echo "Checking available JSON libraries:"

# Check rsjson
if lua -e "require('rsjson')" 2>/dev/null; then
    echo "  ✅ rsjson"
else
    echo "  ❌ rsjson (check build and library path)"
    exit 1
fi

# Check dkjson
if lua -e "require('dkjson')" 2>/dev/null; then
    echo "  ✅ dkjson"
else
    echo "  ❌ dkjson (install with: luarocks install dkjson)"
fi

# Check cjson
if lua -e "require('cjson')" 2>/dev/null; then
    echo "  ✅ cjson" 
else
    echo "  ❌ cjson (install with: luarocks install lua-cjson)"
fi

echo

# Parse command line arguments
BENCHMARK_TYPE="simple"
OUTPUT_FILE=""

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
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  -t, --type TYPE     Benchmark type: simple, comprehensive (default: simple)"
            echo "  -o, --output FILE   Save output to file"
            echo "  -h, --help          Show this help"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h for help"
            exit 1
            ;;
    esac
done

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

# Change to benchmarks directory
cd "$SCRIPT_DIR"

# Run benchmark
echo "Starting benchmark..."
echo

if [ -n "$OUTPUT_FILE" ]; then
    lua "$BENCHMARK_SCRIPT" | tee "$OUTPUT_FILE"
    echo
    echo "Results saved to: $OUTPUT_FILE"
else
    lua "$BENCHMARK_SCRIPT"
fi

echo
echo "Benchmark completed!"
echo
echo "Tip: Run multiple times and average results for production benchmarking."
echo "Tip: Use -o option to save results: $0 -o benchmark_$(date +%Y%m%d_%H%M%S).txt"