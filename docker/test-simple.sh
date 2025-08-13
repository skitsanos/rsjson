#!/bin/bash

# Simple RSJSON Multi-Version Test Script
# Tests all supported Lua versions using Docker

set -e  # Exit on any error

# Change to project root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

echo "🔍 Debug info:"
echo "   Script dir: $SCRIPT_DIR"
echo "   Project root: $PROJECT_ROOT"
echo "   Current working dir: $(pwd)"
echo "   Cargo.lock exists: $(test -f Cargo.lock && echo "YES" || echo "NO")"
echo ""

echo "🚀 RSJSON Simple Test Suite"
echo "Working directory: $(pwd)"
echo ""

# Test results tracking
TOTAL_TESTS=0
PASSED_TESTS=0

# Function to run a single test
run_test() {
    local version=$1
    local dockerfile=$2
    local name=$3
    
    echo "📦 Testing $name"
    echo "   Dockerfile: $dockerfile"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    # Build the image
    echo "   Building image..."
    echo "   Docker command: docker build -f docker/$dockerfile -t rsjson:$version ."
    if docker build -f "docker/$dockerfile" -t "rsjson:$version" . 2>&1; then
        echo "   ✅ Build successful"
        
        # Run the test
        echo "   🧪 Running tests..."
        if docker run --rm "rsjson:$version" | grep -q "All Tests Completed Successfully"; then
            echo "   ✅ Tests PASSED"
            PASSED_TESTS=$((PASSED_TESTS + 1))
        else
            echo "   ❌ Tests FAILED"
        fi
    else
        echo "   ❌ Build FAILED"
    fi
    
    echo ""
}

# Run tests for standalone Lua versions only
echo "📋 Testing standalone Lua versions:"
echo "⚠️  Testing only Lua 5.4 for debugging..."
run_test "lua54" "Dockerfile.lua54" "Lua 5.4"

# Summary
echo "📊 Test Results Summary"
echo "======================"
echo "   Total Tests: $TOTAL_TESTS"
echo "   Passed: $PASSED_TESTS"
echo "   Failed: $((TOTAL_TESTS - PASSED_TESTS))"

if [ $PASSED_TESTS -eq $TOTAL_TESTS ]; then
    echo "🎉 All tests PASSED! 🎉"
    exit 0
else
    echo "💥 Some tests FAILED!"
    exit 1
fi