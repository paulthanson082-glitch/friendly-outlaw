#!/bin/bash
# Convenient script to run the Writers App CLI
# Usage: ./run.sh [options]
# 
# Options:
#   --release    Build and run in release mode
#   --open       Open the CLI in a new Terminal window (macOS only)
#   --help       Show this help message

set -e

show_help() {
    echo "Writers App CLI Runner"
    echo ""
    echo "Usage: ./run.sh [options]"
    echo ""
    echo "Options:"
    echo "  --release    Build and run in release mode (optimized)"
    echo "  --open       Open the CLI in a new Terminal window (macOS only)"
    echo "  --help       Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  ANTHROPIC_API_KEY    Set this to enable AI features"
    echo ""
    echo "Examples:"
    echo "  ./run.sh                                    # Run in debug mode"
    echo "  ./run.sh --release                          # Run in release mode"
    echo "  ./run.sh --open                             # Open in new Terminal window"
    echo "  ./run.sh --release --open                   # Open release build in new window"
    echo "  ANTHROPIC_API_KEY=sk-... ./run.sh          # Run with AI features"
}

# Helper function to run or open the CLI
run_cli() {
    local run_command="$1"
    
    if [ "$OPEN_IN_TERMINAL" = true ]; then
        # Open in new Terminal window (macOS only)
        if [[ "$OSTYPE" == "darwin"* ]]; then
            echo "Opening Writers App CLI in new Terminal window..."
            SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
            osascript -e "tell application \"Terminal\" to do script \"cd '$SCRIPT_DIR' && $run_command\""
        else
            echo "Warning: --open flag is only supported on macOS"
            echo "Running Writers App CLI in current terminal..."
            eval "$run_command"
        fi
    else
        eval "$run_command"
    fi
}

# Parse arguments
BUILD_CONFIG="debug"
OPEN_IN_TERMINAL=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --release)
            BUILD_CONFIG="release"
            shift
            ;;
        --open)
            OPEN_IN_TERMINAL=true
            shift
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Check if Swift is available
if ! command -v swift &> /dev/null; then
    echo "Error: Swift is not installed or not in PATH"
    echo "Please install Swift from https://swift.org/download/"
    exit 1
fi

# Build and run
echo "Building Writers App CLI..."
if [ "$BUILD_CONFIG" = "release" ]; then
    echo "Building in release mode (optimized)..."
    swift build -c release
    echo ""
    echo "Running Writers App CLI (release)..."
    run_cli ".build/release/WritersAppCLI"
else
    echo "Building in debug mode..."
    swift build
    echo ""
    echo "Running Writers App CLI (debug)..."
    run_cli "swift run WritersAppCLI"
fi
