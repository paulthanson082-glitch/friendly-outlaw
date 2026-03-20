#!/bin/bash
set -euo pipefail

echo "==> Tearing down friendly-outlaw workspace..."

# Clean Swift build artifacts to free disk space
if command -v swift &>/dev/null; then
  swift package clean 2>/dev/null || true
  echo "==> Cleaned Swift build artifacts"
fi

# Remove .env copy (not the original)
if [ -f ".env" ]; then
  rm -f ".env"
  echo "==> Removed workspace .env"
fi

echo "==> Workspace teardown complete."
