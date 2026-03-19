#!/bin/bash
# Writers App - Setup & Verification Script
# Checks prerequisites, builds the Swift project, and verifies CLI functionality.
#
# Usage: ./setup.sh [--release]
#   --release    Also perform a release build after the debug build

set -e

COLOR_GREEN='\033[0;32m'
COLOR_BLUE='\033[0;34m'
COLOR_YELLOW='\033[1;33m'
COLOR_RED='\033[0;31m'
NC='\033[0m' # No Color

PASSED=0
FAILED=0
WARNINGS=0
RELEASE_BUILD=false

# Parse arguments
for arg in "$@"; do
    case $arg in
        --release)
            RELEASE_BUILD=true
            ;;
    esac
done

print_header() {
    echo -e "\n${COLOR_BLUE}===================================${NC}"
    echo -e "${COLOR_BLUE}  $1${NC}"
    echo -e "${COLOR_BLUE}===================================${NC}\n"
}

check_pass() {
    echo -e "${COLOR_GREEN}✓ $1${NC}"
    ((PASSED++)) || true
}

check_fail() {
    echo -e "${COLOR_RED}✗ $1${NC}"
    ((FAILED++)) || true
}

check_warn() {
    echo -e "${COLOR_YELLOW}⚠ $1${NC}"
    ((WARNINGS++)) || true
}

# ---------------------------------------------------------------------------
# 1. Prerequisites
# ---------------------------------------------------------------------------
print_header "PREREQUISITES"

# Swift
if command -v swift &> /dev/null; then
    SWIFT_VERSION=$(swift --version 2>&1 | head -1)
    check_pass "Swift found: $SWIFT_VERSION"
else
    check_fail "Swift not found. Install from https://swift.org/download/"
    echo -e "${COLOR_RED}Cannot continue without Swift.${NC}"
    exit 1
fi

# SQLite3 (library – checked via pkg-config or header presence)
if pkg-config --exists sqlite3 2>/dev/null; then
    SQLITE_VERSION=$(pkg-config --modversion sqlite3 2>/dev/null || echo "unknown")
    check_pass "SQLite3 library found (version $SQLITE_VERSION)"
elif [ -f /usr/include/sqlite3.h ] || [ -f /usr/local/include/sqlite3.h ]; then
    check_pass "SQLite3 headers found"
else
    check_warn "SQLite3 development headers not detected. On Linux, install with: sudo apt-get install libsqlite3-dev"
fi

# Optional: SQLite3 CLI
if command -v sqlite3 &> /dev/null; then
    check_pass "sqlite3 CLI found: $(sqlite3 --version | head -1)"
else
    check_warn "sqlite3 CLI not in PATH (optional – not required to build or run)"
fi

# Package.swift
if [ -f "Package.swift" ]; then
    check_pass "Package.swift found"
else
    check_fail "Package.swift not found – are you in the project root?"
    exit 1
fi

# ---------------------------------------------------------------------------
# 2. Debug Build
# ---------------------------------------------------------------------------
print_header "DEBUG BUILD"

echo "Running: swift build"
if swift build 2>&1; then
    check_pass "Debug build succeeded"
else
    check_fail "Debug build failed"
    exit 1
fi

DEBUG_BINARY=".build/debug/WritersAppCLI"
if [ -f "$DEBUG_BINARY" ]; then
    SIZE=$(du -h "$DEBUG_BINARY" | cut -f1)
    check_pass "Binary found: $DEBUG_BINARY ($SIZE)"
else
    check_fail "Binary not found at $DEBUG_BINARY"
    exit 1
fi

# ---------------------------------------------------------------------------
# 3. CLI Smoke Test
# ---------------------------------------------------------------------------
print_header "CLI SMOKE TEST"

echo "Running: $DEBUG_BINARY --help"
"$DEBUG_BINARY" --help > /tmp/writers_app_help.txt 2>&1; HELP_EXIT=$?
if [ "$HELP_EXIT" -eq 0 ]; then
    check_pass "CLI --help exited successfully"
elif [ "$HELP_EXIT" -eq 1 ]; then
    # Some apps return exit code 1 for --help; treat non-crash as passing
    check_pass "CLI --help responded (exit 1 acceptable for help output)"
else
    check_warn "CLI --help returned unexpected exit code $HELP_EXIT – check binary manually"
fi

echo "Running: $DEBUG_BINARY --list"
if "$DEBUG_BINARY" --list > /tmp/writers_app_list.txt 2>&1; then
    check_pass "CLI --list exited successfully"
    LINES=$(wc -l < /tmp/writers_app_list.txt)
    check_pass "CLI output: $LINES line(s)"
else
    check_warn "CLI --list returned non-zero exit (may be expected with no documents)"
fi

# ---------------------------------------------------------------------------
# 4. Release Build (optional)
# ---------------------------------------------------------------------------
if [ "$RELEASE_BUILD" = true ]; then
    print_header "RELEASE BUILD"

    echo "Running: swift build -c release"
    if swift build -c release 2>&1; then
        check_pass "Release build succeeded"
        RELEASE_BINARY=".build/release/WritersAppCLI"
        if [ -f "$RELEASE_BINARY" ]; then
            SIZE=$(du -h "$RELEASE_BINARY" | cut -f1)
            check_pass "Release binary: $RELEASE_BINARY ($SIZE)"
        else
            check_fail "Release binary not found at $RELEASE_BINARY"
        fi
    else
        check_fail "Release build failed"
    fi
fi

# ---------------------------------------------------------------------------
# 5. Environment Check
# ---------------------------------------------------------------------------
print_header "ENVIRONMENT"

if [ -n "$ANTHROPIC_API_KEY" ]; then
    check_pass "ANTHROPIC_API_KEY is set – AI features enabled"
else
    check_warn "ANTHROPIC_API_KEY not set – AI features will be disabled"
    echo "        Set it with: export ANTHROPIC_API_KEY=\"your-api-key\""
fi

# ---------------------------------------------------------------------------
# 6. Summary
# ---------------------------------------------------------------------------
print_header "SUMMARY"

TOTAL=$((PASSED + FAILED + WARNINGS))
echo "Total checks: $TOTAL"
echo -e "${COLOR_GREEN}Passed:   $PASSED${NC}"
if [ "$WARNINGS" -gt 0 ]; then
    echo -e "${COLOR_YELLOW}Warnings: $WARNINGS${NC}"
fi
if [ "$FAILED" -gt 0 ]; then
    echo -e "${COLOR_RED}Failed:   $FAILED${NC}"
fi

echo ""

if [ "$FAILED" -eq 0 ]; then
    echo -e "${COLOR_GREEN}✓ Setup complete – Writers App is ready to run!${NC}"
    echo ""
    echo "Next steps:"
    echo "  Interactive mode:       ./run.sh"
    echo "  Release mode:           ./run.sh --release"
    echo "  List documents:         ./run.sh --list"
    echo "  Open a document:        ./run.sh --open \"My Story\""
    echo "  With AI features:       ANTHROPIC_API_KEY=sk-... ./run.sh"
    echo "  Run tests:              swift test"
    echo "  See full docs:          cat SETUP_AND_RUN.md"
    exit 0
else
    echo -e "${COLOR_RED}✗ $FAILED check(s) failed – see above for details.${NC}"
    echo ""
    echo "Fix the issues listed above, then re-run: ./setup.sh"
    exit 1
fi
