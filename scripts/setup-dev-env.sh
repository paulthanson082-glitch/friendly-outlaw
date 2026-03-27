#!/bin/bash
# setup-dev-env.sh - Set up development environment for friendly-outlaw

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}╔═════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                             ║${NC}"
echo -e "${BLUE}║  WritersApp Development Environment Setup                  ║${NC}"
echo -e "${BLUE}║                                                             ║${NC}"
echo -e "${BLUE}╚═════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Detect OS
OS_TYPE=$(uname)
if [ "$OS_TYPE" != "Darwin" ]; then
    echo -e "${YELLOW}⚠️  This script is optimized for macOS${NC}"
    echo -e "${YELLOW}Found: $OS_TYPE - Some steps may differ${NC}"
    echo ""
fi

# Step 1: Check prerequisites
echo -e "${CYAN}Step 1: Checking prerequisites...${NC}"
echo ""

# Check Swift
if command -v swift &> /dev/null; then
    SWIFT_VERSION=$(swift --version | awk '{print $3}')
    echo -e "  ${GREEN}✓${NC} Swift $SWIFT_VERSION"
else
    echo -e "  ${RED}✗${NC} Swift not found"
    echo -e "    ${YELLOW}→ Install Xcode Command Line Tools:${NC}"
    echo -e "      ${CYAN}xcode-select --install${NC}"
    exit 1
fi

# Check git
if command -v git &> /dev/null; then
    echo -e "  ${GREEN}✓${NC} Git $(git --version | awk '{print $3}')"
else
    echo -e "  ${RED}✗${NC} Git not found - required for development"
    exit 1
fi

# Check SQLite3
if command -v sqlite3 &> /dev/null; then
    SQLITE_VERSION=$(sqlite3 --version | awk '{print $1}')
    echo -e "  ${GREEN}✓${NC} SQLite3 $SQLITE_VERSION"
else
    echo -e "  ${YELLOW}!${NC} SQLite3 not found - attempting to install..."
    if command -v brew &> /dev/null; then
        brew install sqlite3
        echo -e "  ${GREEN}✓${NC} SQLite3 installed via Homebrew"
    else
        echo -e "  ${RED}✗${NC} Homebrew not found - please install SQLite3 manually"
        exit 1
    fi
fi

echo ""

# Step 2: Environment configuration
echo -e "${CYAN}Step 2: Setting up environment configuration...${NC}"
echo ""

if [ -f ".env" ]; then
    echo -e "  ${GREEN}✓${NC} .env file already exists"
else
    if [ -f ".env.example" ]; then
        cp .env.example .env
        echo -e "  ${GREEN}✓${NC} Created .env from .env.example"
        echo -e "    ${YELLOW}→ Edit .env and add your ANTHROPIC_API_KEY${NC}"
    else
        echo -e "  ${YELLOW}!${NC} .env.example not found"
    fi
fi

echo ""

# Step 3: Make scripts executable
echo -e "${CYAN}Step 3: Setting up development scripts...${NC}"
echo ""

if [ -d "scripts" ]; then
    chmod +x scripts/*.sh 2>/dev/null || true
    echo -e "  ${GREEN}✓${NC} Scripts made executable"
    echo -e "    ${CYAN}Available:${NC}"
    echo -e "      • ./scripts/build.sh       - Build the project"
    echo -e "      • ./scripts/test.sh        - Run test suite"
    echo -e "      • ./scripts/dev.sh         - Development workflow"
else
    echo -e "  ${YELLOW}!${NC} scripts/ directory not found"
fi

chmod +x run.sh 2>/dev/null || true
echo -e "  ${GREEN}✓${NC} Main scripts executable"

echo ""

# Step 4: Dependencies check
echo -e "${CYAN}Step 4: Checking Swift dependencies...${NC}"
echo ""

if swift package describe > /dev/null 2>&1; then
    echo -e "  ${GREEN}✓${NC} Package manifest valid"
    echo -e "  ${GREEN}✓${NC} Dependencies configured:"
    echo -e "      • CSQLite (system library)"
    echo -e "      • swift-argument-parser"
    echo -e "      • Yams"
else
    echo -e "  ${RED}✗${NC} Package manifest error"
    exit 1
fi

echo ""

# Step 5: Recommendations
echo -e "${CYAN}Step 5: Development recommendations...${NC}"
echo ""

echo -e "  ${BLUE}IDE Setup:${NC}"
if [ -d ".vscode" ]; then
    echo -e "    ${GREEN}✓${NC} VS Code configuration exists (.vscode/)"
    echo -e "      Recommended extensions:"
    echo -e "        • Swift for Visual Studio Code"
    echo -e "        • LLDB Debugger"
    echo -e "        • Git History"
else
    echo -e "    ${YELLOW}!${NC} No VS Code configuration"
fi

echo ""

echo -e "  ${BLUE}Git Workflow:${NC}"
BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ "$BRANCH" == "claude/"* ]]; then
    echo -e "    ${GREEN}✓${NC} On development branch: $BRANCH"
else
    echo -e "    ${YELLOW}!${NC} Current branch: $BRANCH"
fi

echo ""

echo -e "  ${BLUE}Build & Test:${NC}"
echo -e "    • Debug build:    ${CYAN}./scripts/build.sh debug${NC}"
echo -e "    • Release build:  ${CYAN}./scripts/build.sh release${NC}"
echo -e "    • Run tests:      ${CYAN}./scripts/test.sh${NC}"
echo -e "    • Run CLI:        ${CYAN}./run.sh${NC}"

echo ""

# Step 6: Quick start
echo -e "${CYAN}Step 6: Quick start verification...${NC}"
echo ""

echo -e "  To verify setup works:"
echo -e "    ${CYAN}./scripts/build.sh debug${NC}"
echo -e "    ${CYAN}./scripts/test.sh${NC}"
echo -e "    ${CYAN}./run.sh${NC}"

echo ""
echo -e "${GREEN}✅ Development environment setup complete!${NC}"
echo ""
echo -e "${BLUE}╔═════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                             ║${NC}"
echo -e "${BLUE}║  Ready for development. Run './scripts/build.sh debug'     ║${NC}"
echo -e "${BLUE}║                                                             ║${NC}"
echo -e "${BLUE}╚═════════════════════════════════════════════════════════════╝${NC}"
echo ""
