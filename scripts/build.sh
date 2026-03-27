#!/bin/bash
# build.sh - Swift project build automation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Determine build configuration
BUILD_CONFIG="${1:-release}"
VERBOSE="${2:-false}"

if [[ ! "$BUILD_CONFIG" =~ ^(debug|release)$ ]]; then
    echo -e "${RED}❌ Invalid build config: $BUILD_CONFIG (use 'debug' or 'release')${NC}"
    exit 1
fi

echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   WritersApp Build Script${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo ""
echo -e "Build Configuration: ${YELLOW}$BUILD_CONFIG${NC}"
if [ "$VERBOSE" = "true" ]; then
    echo -e "Verbose Mode: ${YELLOW}ON${NC}"
fi
echo ""

# Check Swift is available
if ! command -v swift &> /dev/null; then
    echo -e "${RED}❌ Swift is not installed or not in PATH${NC}"
    echo "Install Xcode or Swift from https://swift.org"
    exit 1
fi

echo -e "${BLUE}📦 Swift Version:${NC} $(swift --version)"
echo ""

# Check SQLite
if ! command -v sqlite3 &> /dev/null; then
    echo -e "${YELLOW}⚠️  SQLite3 not found. Installing via Homebrew...${NC}"
    if command -v brew &> /dev/null; then
        brew install sqlite3
    else
        echo -e "${RED}❌ SQLite3 required and Homebrew not available${NC}"
        exit 1
    fi
fi

echo -e "${BLUE}🔍 Checking environment...${NC}"
echo "  ✓ Swift: $(swift --version | head -1)"
echo "  ✓ SQLite: $(sqlite3 --version)"
echo ""

# Clean if requested
if [ "$3" = "--clean" ]; then
    echo -e "${YELLOW}🧹 Cleaning build artifacts...${NC}"
    swift package clean
    echo "  ✓ Clean complete"
    echo ""
fi

# Build
echo -e "${YELLOW}🏗️  Building ($BUILD_CONFIG mode)...${NC}"
echo ""

if [ "$VERBOSE" = "true" ]; then
    swift build -c "$BUILD_CONFIG" -v
else
    swift build -c "$BUILD_CONFIG" 2>&1 | grep -E "Building|Build complete|error:|warning:" || true
fi

BUILD_EXIT=$?

if [ $BUILD_EXIT -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Build successful!${NC}"
    echo ""

    # Show output location
    if [ "$BUILD_CONFIG" = "release" ]; then
        EXECUTABLE=".build/release/WritersAppCLI"
    else
        EXECUTABLE=".build/debug/WritersAppCLI"
    fi

    if [ -f "$EXECUTABLE" ]; then
        SIZE=$(du -h "$EXECUTABLE" | cut -f1)
        echo -e "${BLUE}📍 Output:${NC}"
        echo "  Location: $EXECUTABLE"
        echo "  Size: $SIZE"
        echo ""
        echo -e "${BLUE}🚀 Run with:${NC}"
        echo "  ./$EXECUTABLE"
        echo "  or: ./run.sh"
    fi
else
    echo ""
    echo -e "${RED}❌ Build failed!${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
