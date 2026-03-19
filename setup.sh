#!/bin/bash
#
# Setup and verification script for friendly-outlaw Writers App
# This script checks prerequisites, builds the project, and verifies it runs correctly.
#

set -e  # Exit on error

echo "╔══════════════════════════════════════════════════════════╗"
echo "║   friendly-outlaw Writers App - Setup & Verification     ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track if any checks failed
FAILED=0

# Function to print success
success() {
    echo -e "   ${GREEN}✓${NC} $1"
}

# Function to print error
error() {
    echo -e "   ${RED}✗${NC} $1"
    FAILED=1
}

# Function to print warning
warning() {
    echo -e "   ${YELLOW}⚠${NC} $1"
}

# Check 1: Swift installation
echo "1. Checking Swift installation..."
if command -v swift &> /dev/null; then
    SWIFT_VERSION=$(swift --version 2>&1 | head -1)
    success "Swift is installed: $SWIFT_VERSION"
else
    error "Swift is not installed"
    echo "      Install from: https://swift.org/download/"
    exit 1
fi

# Check 2: SQLite3 installation
echo ""
echo "2. Checking SQLite3 installation..."
if command -v sqlite3 &> /dev/null; then
    SQLITE_VERSION=$(sqlite3 --version 2>&1 | awk '{print $1}')
    success "SQLite3 is installed: $SQLITE_VERSION"
else
    error "SQLite3 is not installed"
    echo "      Ubuntu/Debian: sudo apt-get install libsqlite3-dev"
    echo "      Fedora/RHEL: sudo dnf install sqlite-devel"
    echo "      macOS: Already included"
    exit 1
fi

# Check 3: Build the project
echo ""
echo "3. Building the project..."
BUILD_LOG=$(mktemp)
if swift build > "$BUILD_LOG" 2>&1; then
    BUILD_TIME=$(grep "Build complete!" "$BUILD_LOG" | sed -n 's/.*(\(.*\)s)/\1/p' || echo "unknown")
    success "Build successful (${BUILD_TIME}s)"
else
    error "Build failed"
    echo ""
    echo "Build log (last 30 lines):"
    tail -30 "$BUILD_LOG"
    rm -f "$BUILD_LOG"
    exit 1
fi
rm -f "$BUILD_LOG"

# Check 4: Verify CLI binary exists
echo ""
echo "4. Verifying CLI binary..."
if [ -f .build/debug/WritersAppCLI ]; then
    CLI_SIZE=$(du -h .build/debug/WritersAppCLI | cut -f1)
    success "CLI binary created: .build/debug/WritersAppCLI ($CLI_SIZE)"
else
    error "CLI binary not found at .build/debug/WritersAppCLI"
    exit 1
fi

# Check 5: Test CLI --help
echo ""
echo "5. Testing CLI --help..."
HELP_LOG=$(mktemp)
if .build/debug/WritersAppCLI --help > "$HELP_LOG" 2>&1; then
    if grep -q "Writers App CLI" "$HELP_LOG"; then
        success "CLI --help works correctly"
    else
        warning "CLI --help output unexpected"
        head -5 "$HELP_LOG"
    fi
else
    error "CLI --help failed"
    cat "$HELP_LOG"
fi
rm -f "$HELP_LOG"

# Check 6: Test CLI --list
echo ""
echo "6. Testing CLI --list..."
LIST_LOG=$(mktemp)
if .build/debug/WritersAppCLI --list > "$LIST_LOG" 2>&1; then
    success "CLI --list works correctly"
else
    error "CLI --list failed"
    cat "$LIST_LOG"
fi
rm -f "$LIST_LOG"

# Check 7: Test interactive mode (launch and quit immediately)
echo ""
echo "7. Testing interactive mode..."
INTERACTIVE_LOG=$(mktemp)
if echo "0" | timeout 5 .build/debug/WritersAppCLI > "$INTERACTIVE_LOG" 2>&1; then
    if grep -q "Writers App with Templates" "$INTERACTIVE_LOG"; then
        success "Interactive mode launches successfully"
    else
        warning "Interactive mode output unexpected"
        head -10 "$INTERACTIVE_LOG"
    fi
else
    error "Interactive mode failed or timed out"
    cat "$INTERACTIVE_LOG"
fi
rm -f "$INTERACTIVE_LOG"

# Check 8: Verify run.sh script
echo ""
echo "8. Checking run.sh convenience script..."
if [ -f run.sh ]; then
    if [ -x run.sh ]; then
        success "run.sh is executable"
    else
        warning "run.sh exists but is not executable"
        echo "      Run: chmod +x run.sh"
    fi
else
    warning "run.sh not found (optional convenience script)"
fi

# Check 9: Optional - Check for API keys
echo ""
echo "9. Checking optional API keys..."
if [ -n "$ANTHROPIC_API_KEY" ]; then
    success "ANTHROPIC_API_KEY is set (AI features enabled)"
else
    warning "ANTHROPIC_API_KEY not set (AI features disabled)"
    echo "      To enable: export ANTHROPIC_API_KEY=your-key"
fi

if [ -n "$GUI_NEW_API_KEY" ]; then
    success "GUI_NEW_API_KEY is set"
else
    warning "GUI_NEW_API_KEY not set (gui.new exports available with default expiry)"
fi

if [ -n "$RAGIE_API_KEY" ]; then
    success "RAGIE_API_KEY is set"
else
    warning "RAGIE_API_KEY not set (document retrieval disabled)"
fi

# Summary
echo ""
echo "═══════════════════════════════════════════════════════════"

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    echo ""
    echo "The friendly-outlaw Writers App is successfully set up and ready to use."
    echo ""
    echo "Next steps:"
    echo "  • Run interactively:     swift run WritersAppCLI"
    echo "  • Or use the binary:     .build/debug/WritersAppCLI"
    echo "  • Or use run script:     ./run.sh"
    echo "  • View help:             ./run.sh --help"
    echo "  • List documents:        ./run.sh --list"
    echo "  • Run tests:             swift test"
    echo ""
    echo "To enable AI features:"
    echo "  export ANTHROPIC_API_KEY=your-key-here"
    echo "  ./run.sh"
    echo ""
    echo "Documentation:"
    echo "  • README.md             - Full documentation"
    echo "  • QUICK_START.md        - Quick start guide"
    echo "  • SETUP_VERIFICATION.md - Detailed setup verification"
    echo ""
    exit 0
else
    echo -e "${RED}✗ Some checks failed!${NC}"
    echo ""
    echo "Please address the errors above and try again."
    echo ""
    exit 1
fi
