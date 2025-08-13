#!/bin/bash

# RSJSON Multi-Version Test Script
# Tests all supported Lua versions using Docker

set -e  # Exit on any error

# Change to project root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

echo "🚀 RSJSON Multi-Version Test Suite"
echo "=================================="
echo "Working directory: $(pwd)"
echo "Script location: $SCRIPT_DIR"
echo "Project root: $PROJECT_ROOT"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test results tracking
declare -a RESULTS=()
TOTAL_TESTS=0
PASSED_TESTS=0

# Function to run a single test
run_test() {
    local version=$1
    local dockerfile=$2
    local name=$3
    
    echo -e "${BLUE}📦 Testing $name${NC}"
    echo "   Dockerfile: $dockerfile"
    echo "   Building image..."
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    # Build the image with timeout
    if timeout 300 docker build -f "docker/$dockerfile" -t "rsjson:$version" . > /dev/null 2>&1; then
        echo "   ✅ Build successful"
        
        # Run the test
        echo "   🧪 Running tests..."
        if timeout 60 docker run --rm "rsjson:$version" > "/tmp/rsjson-$version.log" 2>&1; then
            echo -e "   ${GREEN}✅ Tests PASSED${NC}"
            RESULTS+=("$name: PASSED")
            PASSED_TESTS=$((PASSED_TESTS + 1))
        else
            echo -e "   ${RED}❌ Tests FAILED${NC}"
            echo "   📄 Error log:"
            cat "/tmp/rsjson-$version.log" | sed 's/^/      /'
            RESULTS+=("$name: FAILED")
        fi
    else
        echo -e "   ${RED}❌ Build FAILED${NC}"
        RESULTS+=("$name: BUILD FAILED")
    fi
    
    echo ""
}

# Run web test for LuaJIT
run_web_test() {
    echo -e "${BLUE}🌐 Testing LuaJIT + OpenResty (Web)${NC}"
    echo "   Building OpenResty image..."
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if timeout 300 docker build -f "docker/Dockerfile.luajit" -t "rsjson:luajit-web" . > /dev/null 2>&1; then
        echo "   ✅ Build successful"
        echo "   🌐 Starting web server..."
        
        # Start container in background
        CONTAINER_ID=$(docker run -d -p 8080:80 "rsjson:luajit-web")
        
        # Wait for server to start
        sleep 3
        
        # Test web endpoint
        echo "   🧪 Testing HTTP endpoint..."
        if curl -s http://localhost:8080 > "/tmp/rsjson-web.log" 2>&1; then
            if grep -q "rsjson" "/tmp/rsjson-web.log"; then
                echo -e "   ${GREEN}✅ Web test PASSED${NC}"
                RESULTS+=("LuaJIT + OpenResty: PASSED")
                PASSED_TESTS=$((PASSED_TESTS + 1))
            else
                echo -e "   ${RED}❌ Web test FAILED - rsjson not working${NC}"
                RESULTS+=("LuaJIT + OpenResty: FAILED")
            fi
        else
            echo -e "   ${RED}❌ Web test FAILED - server not responding${NC}"
            RESULTS+=("LuaJIT + OpenResty: FAILED")
        fi
        
        # Cleanup
        docker stop "$CONTAINER_ID" > /dev/null 2>&1
        docker rm "$CONTAINER_ID" > /dev/null 2>&1
    else
        echo -e "   ${RED}❌ Build FAILED${NC}"
        RESULTS+=("LuaJIT + OpenResty: BUILD FAILED")
    fi
    
    echo ""
}

# Main test execution
echo "📋 Test Plan:"
echo "   • Lua 5.1 (oldest supported)"
echo "   • Lua 5.2"
echo "   • Lua 5.3" 
echo "   • Lua 5.4 (default)"
echo "   • LuaJIT + OpenResty (web)"
echo ""

# Run all tests
run_test "lua51" "Dockerfile.lua51" "Lua 5.1"
run_test "lua52" "Dockerfile.lua52" "Lua 5.2"
run_test "lua53" "Dockerfile.lua53" "Lua 5.3"
run_test "lua54" "Dockerfile.lua54" "Lua 5.4"
run_web_test

# Summary
echo "📊 Test Results Summary"
echo "======================"
for result in "${RESULTS[@]}"; do
    if [[ $result == *"PASSED"* ]]; then
        echo -e "${GREEN}✅ $result${NC}"
    else
        echo -e "${RED}❌ $result${NC}"
    fi
done

echo ""
echo "📈 Overall Results:"
echo "   Total Tests: $TOTAL_TESTS"
echo "   Passed: $PASSED_TESTS"
echo "   Failed: $((TOTAL_TESTS - PASSED_TESTS))"

if [ $PASSED_TESTS -eq $TOTAL_TESTS ]; then
    echo -e "${GREEN}🎉 All tests PASSED! 🎉${NC}"
    exit 0
else
    echo -e "${RED}💥 Some tests FAILED!${NC}"
    exit 1
fi