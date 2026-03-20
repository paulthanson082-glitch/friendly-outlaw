#!/bin/bash
set -euo pipefail

echo "==> Setting up friendly-outlaw workspace..."

# Copy .env from parent repo if available
if [ -f "../.env" ]; then
  cp "../.env" ".env"
  echo "==> Copied .env from parent repository"
fi

# Detect OS and install system dependencies (sqlite3 required for CSQLite module)
if command -v apt-get &>/dev/null; then
  if ! dpkg -s libsqlite3-dev &>/dev/null || ! dpkg -s pkg-config &>/dev/null; then
    echo "==> Installing system dependencies (libsqlite3-dev, pkg-config)..."
    apt-get update -qq
    apt-get install -y -qq libsqlite3-dev pkg-config
  fi
elif command -v brew &>/dev/null; then
  if ! brew list sqlite &>/dev/null; then
    echo "==> Installing sqlite via Homebrew..."
    brew install sqlite pkg-config
  fi
fi

# Install Swift via swiftly if not present
if ! command -v swift &>/dev/null; then
  echo "==> Swift not found, installing via swiftly..."
  if ! command -v curl &>/dev/null; then
    apt-get update -qq && apt-get install -y -qq curl
  fi

  ARCH="$(uname -m)"
  cd /tmp
  curl -fsSLO "https://download.swift.org/swiftly/linux/swiftly-${ARCH}.tar.gz"
  tar zxf "swiftly-${ARCH}.tar.gz"
  ./swiftly init --quiet-shell-followup -y
  . "${SWIFTLY_HOME_DIR:-$HOME/.local/share/swiftly}/env.sh"
  hash -r
  rm -f "swiftly-${ARCH}.tar.gz" swiftly

  cd "$SUPERSET_ROOT_PATH"

  # Persist Swift PATH for the workspace
  echo ". \"${SWIFTLY_HOME_DIR:-$HOME/.local/share/swiftly}/env.sh\"" >> "${HOME}/.bashrc"
fi

# Build the project to resolve dependencies and warm up the build cache
echo "==> Building friendly-outlaw..."
swift build

echo "==> Workspace ready!"
echo ""
echo "  Project:  ${SUPERSET_WORKSPACE_NAME:-friendly-outlaw}"
echo "  Root:     ${SUPERSET_ROOT_PATH:-.}"
echo ""
echo "  Commands:"
echo "    swift build          # Build"
echo "    swift test           # Run tests"
echo "    swift run WritersAppCLI  # Run CLI"
echo "    ANTHROPIC_API_KEY=sk-... swift run WritersAppCLI  # With AI"
