#!/bin/bash
set -euo pipefail

# Only run in Claude Code on the web
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

# Install system dependencies (libsqlite3-dev needed for CSQLite module)
if ! dpkg -s libsqlite3-dev &>/dev/null || ! dpkg -s pkg-config &>/dev/null; then
  apt-get update -qq
  apt-get install -y -qq libsqlite3-dev pkg-config curl
fi

# Install Swift via swiftly if not already installed
if ! command -v swift &>/dev/null; then
  ARCH="$(uname -m)"
  SWIFTLY_TARBALL="swiftly-${ARCH}.tar.gz"
  cd /tmp

  if curl -fsSLO "https://download.swift.org/swiftly/linux/${SWIFTLY_TARBALL}"; then
    tar zxf "${SWIFTLY_TARBALL}"
    ./swiftly init --quiet-shell-followup -y
    SWIFTLY_ENV="${SWIFTLY_HOME_DIR:-$HOME/.local/share/swiftly}/env.sh"
    if [ -f "$SWIFTLY_ENV" ]; then
      # shellcheck source=/dev/null
      . "$SWIFTLY_ENV"
      # Persist Swift PATH for the rest of this session
      if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
        echo ". \"$SWIFTLY_ENV\"" >> "$CLAUDE_ENV_FILE"
      fi
    fi
    hash -r
    rm -f "${SWIFTLY_TARBALL}" swiftly
  else
    echo "Warning: Could not download swiftly. Swift must be installed manually." >&2
  fi
fi

# Build the project to cache dependencies and validate the environment
if command -v swift &>/dev/null; then
  cd "$CLAUDE_PROJECT_DIR"
  swift build 2>&1
else
  echo "Warning: swift not found — skipping build step." >&2
fi

# Install Firecrawl CLI for web scraping, searching, and browsing
if ! command -v firecrawl &>/dev/null; then
  npm install -g firecrawl-cli 2>&1 || true
fi
