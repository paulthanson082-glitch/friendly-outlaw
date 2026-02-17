#!/bin/bash
set -euo pipefail

# Only run in Claude Code on the web
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

# Install system dependencies (libsqlite3-dev needed for CSQLite module)
if ! dpkg -s libsqlite3-dev &>/dev/null || ! dpkg -s pkg-config &>/dev/null; then
  apt-get update -qq
  apt-get install -y -qq libsqlite3-dev pkg-config
fi

# Install Swift via swiftly if not already installed
if ! command -v swift &>/dev/null; then
  apt-get update -qq
  apt-get install -y -qq curl

  ARCH="$(uname -m)"
  cd /tmp
  curl -fsSLO "https://download.swift.org/swiftly/linux/swiftly-${ARCH}.tar.gz"
  tar zxf "swiftly-${ARCH}.tar.gz"
  ./swiftly init --quiet-shell-followup -y
  . "${SWIFTLY_HOME_DIR:-$HOME/.local/share/swiftly}/env.sh"
  hash -r
  rm -f "swiftly-${ARCH}.tar.gz" swiftly

  # Persist PATH for the session
  if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
    echo ". \"${SWIFTLY_HOME_DIR:-$HOME/.local/share/swiftly}/env.sh\"" >> "$CLAUDE_ENV_FILE"
  fi
fi

# Build the project to resolve dependencies and cache build artifacts
cd "$CLAUDE_PROJECT_DIR"
swift build 2>&1
