#!/bin/bash
# Convenient script to run the Writers App CLI
# Usage: ./run.sh [options]
# 
# Options:
#   --release    Build and run in release mode
#   --help       Show this help message

set -e

show_help() {
    echo "Writers App CLI Runner"
    echo ""
    echo "Usage: ./run.sh [options]"
    echo ""
    echo "Options:"
    echo "  --release    Build and run in release mode (optimized)"
    echo "  --help       Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  ANTHROPIC_API_KEY    Set this to enable AI features"
    echo ""
    echo "Examples:"
    echo "  ./run.sh                                    # Run in debug mode"
    echo "  ./run.sh --release                          # Run in release mode"
    echo "  ANTHROPIC_API_KEY=sk-... ./run.sh          # Run with AI features"
}

# Parse arguments
BUILD_CONFIG="debug"
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
    .build/release/WritersAppCLI
else
    echo "Building in debug mode..."
    swift build
    echo ""
    echo "Running Writers App CLI (debug)..."
    swift run WritersAppCLI
fi
