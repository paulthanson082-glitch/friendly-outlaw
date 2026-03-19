#!/bin/bash
# Setup verification script for Writers App
# Checks prerequisites, builds the project, and verifies CLI functionality.
#
# Usage: ./setup.sh

set -e

# Colour helpers
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ok()   { echo -e "${GREEN}✓${NC} $1"; }
fail() { echo -e "${RED}✗${NC} $1"; }
info() { echo -e "${YELLOW}→${NC} $1"; }

echo "======================================"
echo "  Writers App — Setup Verification"
echo "======================================"
echo ""

# ── 1. Swift ──────────────────────────────
info "Checking Swift..."
if command -v swift &> /dev/null; then
    SWIFT_VERSION=$(swift --version 2>&1 | head -1)
    ok "Swift found: $SWIFT_VERSION"
else
    fail "Swift not found. Install it from https://swift.org/download/"
    exit 1
fi

# ── 2. SQLite3 ────────────────────────────
info "Checking SQLite3..."
if pkg-config --exists sqlite3 2>/dev/null; then
    SQLITE_VERSION=$(pkg-config --modversion sqlite3 2>/dev/null || echo "unknown")
    ok "SQLite3 found (version $SQLITE_VERSION)"
elif command -v sqlite3 &> /dev/null; then
    ok "sqlite3 CLI found"
else
    fail "SQLite3 development libraries not found."
    echo "  macOS: sqlite3 is included with Xcode Command Line Tools."
    echo "  Linux: sudo apt-get install libsqlite3-dev"
    exit 1
fi

# ── 3. Build ──────────────────────────────
info "Building Writers App (debug)..."
if swift build 2>&1; then
    ok "Build succeeded"
else
    fail "Build failed — see output above"
    exit 1
fi

# ── 4. Binary check ───────────────────────
BINARY=".build/debug/WritersAppCLI"
info "Checking binary..."
if [ -f "$BINARY" ]; then
    SIZE=$(du -sh "$BINARY" | cut -f1)
    ok "Binary present: $BINARY ($SIZE)"
else
    fail "Binary not found at $BINARY"
    exit 1
fi

# ── 5. Smoke test ─────────────────────────
info "Running CLI smoke test (--help)..."
SMOKE_OUTPUT=$("$BINARY" --help 2>&1 || true)
if echo "$SMOKE_OUTPUT" | grep -qi "usage\|option\|writer\|document\|template\|menu\|help"; then
    ok "CLI responds to --help"
else
    fail "CLI smoke test failed"
    exit 1
fi

# ── Done ──────────────────────────────────
echo ""
echo "======================================"
echo -e "${GREEN}  Setup complete!${NC}"
echo "======================================"
echo ""
echo "Next steps:"
echo "  ./run.sh                          # Start the interactive CLI"
echo "  ./run.sh --release                # Build optimised and run"
echo "  swift test                        # Run the test suite"
echo "  ANTHROPIC_API_KEY=sk-... ./run.sh # Run with AI features"
echo ""
