#!/bin/bash
# Convenient script to run the Writers App CLI
# Usage: ./run.sh [options] [CLI arguments]
# 
# Options:
#   --release    Build and run in release mode
#   --help       Show this help message
#
# Any additional arguments are passed to the CLI application

set -e

show_help() {
    echo "Writers App CLI Runner"
    echo ""
    echo "Usage: ./run.sh [options] [CLI arguments]"
    echo ""
    echo "Options:"
    echo "  --release    Build and run in release mode (optimized)"
    echo "  --help       Show this help message"
    echo ""
    echo "CLI Arguments:"
    echo "  Any arguments after --release (or without it) are passed to the CLI"
    echo ""
    echo "Environment Variables:"
    echo "  ANTHROPIC_API_KEY    Set this to enable AI features"
    echo ""
    echo "Examples:"
    echo "  ./run.sh                                    # Run in debug mode (interactive)"
    echo "  ./run.sh --release                          # Run in release mode (interactive)"
    echo "  ./run.sh --list                             # List all documents"
    echo "  ./run.sh --status                           # Show current session status"
    echo "  ./run.sh --open \"My Story\"                  # Open a document by title"
    echo "  ./run.sh --release --open <document-id>     # Open document in release mode"
    echo "  ./run.sh --run pomodoro                     # Start a 25-minute Pomodoro session"
    echo "  ./run.sh --run sprint                       # Start a 15-minute writing sprint"
    echo "  ./run.sh --open \"My Novel\" --run pomodoro   # Open document and start 25-min session"
    echo "  ./run.sh --run deepwork --open \"Chapter 1\"  # Open document and start 90-min session"
    echo "  ANTHROPIC_API_KEY=sk-... ./run.sh          # Run with AI features"
}

# Parse arguments
BUILD_CONFIG="debug"
CLI_ARGS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        --release)
            BUILD_CONFIG="release"
            shift
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            # Collect remaining arguments for CLI
            CLI_ARGS+=("$1")
            shift
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
    .build/release/WritersAppCLI "${CLI_ARGS[@]}"
else
    echo "Building in debug mode..."
    swift build
    echo ""
    echo "Running Writers App CLI (debug)..."
    if [ ${#CLI_ARGS[@]} -eq 0 ]; then
        swift run WritersAppCLI
    else
        swift run WritersAppCLI "${CLI_ARGS[@]}"
    fi
fi
