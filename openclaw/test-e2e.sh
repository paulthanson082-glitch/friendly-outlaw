#!/usr/bin/env bash
set -e

echo "🧪 Friendly Outlaw OpenClaw Plugin E2E Test"
echo "==========================================="
echo ""

# Check prerequisites
command -v docker >/dev/null 2>&1 || { echo "❌ Docker is required but not installed. Aborting." >&2; exit 1; }

# Build the plugin first
echo "📦 Building plugin..."
npm run build
echo "✅ Plugin built successfully"
echo ""

# Build E2E Docker image
echo "🐳 Building E2E Docker image..."
docker build -f Dockerfile.e2e -t friendly-outlaw-openclaw-e2e:test .
echo "✅ E2E image built"
echo ""

# Run E2E verification
echo "🚀 Running E2E verification..."
docker run --rm friendly-outlaw-openclaw-e2e:test
echo ""

echo "✅ E2E tests passed!"
