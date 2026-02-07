#!/usr/bin/env bash
# Simple script to build and run the Writers App CLI
# Note: This builds in debug mode. For release builds, see QUICKSTART.md

echo "╔══════════════════════════════════════╗"
echo "║  Writers App CLI - Build and Run     ║"
echo "╚══════════════════════════════════════╝"
echo ""

# Check if ANTHROPIC_API_KEY is set
if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo "⚠️  Note: AI features will be disabled (ANTHROPIC_API_KEY not set)"
    echo "   To enable AI features, set your API key:"
    echo "   export ANTHROPIC_API_KEY=\"your-key-here\""
    echo ""
fi

echo "Building the application..."
swift build

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo ""
    echo "Starting Writers App CLI..."
    echo ""
    ./.build/debug/WritersAppCLI
else
    echo "❌ Build failed!"
    exit 1
fi
