#!/bin/bash
# dev.sh - Development workflow: build, test, run

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ACTION="${1:-menu}"

show_menu() {
    echo ""
    echo -e "${BLUE}┌────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│   WritersApp Development Menu         │${NC}"
    echo -e "${BLUE}└────────────────────────────────────────┘${NC}"
    echo ""
    echo "  1. Build (Debug)"
    echo "  2. Build (Release)"
    echo "  3. Run Tests"
    echo "  4. Run CLI"
    echo "  5. Build + Test + Run"
    echo "  6. Clean + Full Rebuild"
    echo "  7. Show Environment"
    echo "  0. Exit"
    echo ""
    echo -n "Choose action: "
}

build_debug() {
    echo -e "${YELLOW}Building (debug mode)...${NC}"
    ./scripts/build.sh debug
}

build_release() {
    echo -e "${YELLOW}Building (release mode)...${NC}"
    ./scripts/build.sh release
}

run_tests() {
    echo -e "${YELLOW}Running test suite...${NC}"
    ./scripts/test.sh
}

run_cli() {
    echo -e "${YELLOW}Starting CLI...${NC}"
    ./run.sh
}

full_workflow() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Full Development Workflow${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    echo "Step 1: Building..."
    ./scripts/build.sh release
    echo ""

    echo "Step 2: Testing..."
    ./scripts/test.sh
    echo ""

    echo "Step 3: Ready to run"
    echo -e "${GREEN}✅ All steps complete!${NC}"
    echo ""
    echo "To start the CLI, run: ./run.sh"
    echo ""
}

clean_rebuild() {
    echo -e "${YELLOW}Cleaning and rebuilding...${NC}"
    swift package clean
    echo "  ✓ Clean complete"
    echo ""
    ./scripts/build.sh release --clean
}

show_env() {
    echo -e "${BLUE}Environment Information:${NC}"
    echo ""
    echo "  Swift:"
    swift --version
    echo ""
    echo "  Xcode:"
    xcode-select -p
    echo ""
    echo "  SQLite3:"
    sqlite3 --version
    echo ""
    echo "  Git:"
    git --version
    echo ""
    echo "  Current Branch:"
    git rev-parse --abbrev-ref HEAD
    echo ""
    echo "  Project Structure:"
    echo "    Swift Files: $(find Sources -name '*.swift' -type f | wc -l)"
    echo "    Test Files: $(find Tests -name '*.swift' -type f | wc -l)"
    echo ""
}

# Handle command line arguments
case "$ACTION" in
    1|build-debug)
        build_debug
        ;;
    2|build-release)
        build_release
        ;;
    3|test)
        run_tests
        ;;
    4|run)
        run_cli
        ;;
    5|full)
        full_workflow
        ;;
    6|clean)
        clean_rebuild
        ;;
    7|env)
        show_env
        ;;
    0|exit)
        exit 0
        ;;
    menu)
        # Interactive menu
        while true; do
            show_menu
            read -r choice
            case "$choice" in
                1) build_debug ;;
                2) build_release ;;
                3) run_tests ;;
                4) run_cli ;;
                5) full_workflow ;;
                6) clean_rebuild ;;
                7) show_env ;;
                0) exit 0 ;;
                *) echo -e "${RED}Invalid choice${NC}" ;;
            esac
        done
        ;;
    *)
        echo "Usage: ./scripts/dev.sh [command]"
        echo ""
        echo "Commands:"
        echo "  build-debug     Build in debug mode"
        echo "  build-release   Build in release mode"
        echo "  test            Run test suite"
        echo "  run             Run CLI"
        echo "  full            Build + Test + Run workflow"
        echo "  clean           Clean and rebuild"
        echo "  env             Show environment info"
        echo "  menu            Interactive menu (default)"
        echo ""
        ;;
esac
