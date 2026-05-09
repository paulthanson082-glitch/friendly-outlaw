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
  if curl -sSLO "https://download.swift.org/swiftly/linux/swiftly-${ARCH}.tar.gz" 2>/dev/null && [ -f "swiftly-${ARCH}.tar.gz" ]; then
    tar zxf "swiftly-${ARCH}.tar.gz"
    ./swiftly init --quiet-shell-followup -y
    . "${SWIFTLY_HOME_DIR:-$HOME/.local/share/swiftly}/env.sh"
    hash -r
    rm -f "swiftly-${ARCH}.tar.gz" swiftly

    # Persist PATH for the session
    if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
      echo ". \"${SWIFTLY_HOME_DIR:-$HOME/.local/share/swiftly}/env.sh\"" >> "$CLAUDE_ENV_FILE"
    fi
  else
    echo "Warning: Could not download swiftly from swift.org. Swift must be installed manually." >&2
  fi
fi

# Build the project to resolve dependencies and cache build artifacts
if command -v swift &>/dev/null; then
  cd "$CLAUDE_PROJECT_DIR"
  env GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=safe.bareRepository GIT_CONFIG_VALUE_0=all swift build 2>&1
else
  echo "Warning: swift not found — skipping build step." >&2
fi

# Install Firecrawl CLI for web scraping, searching, and browsing
if ! command -v firecrawl &>/dev/null; then
  npm install -g firecrawl-cli 2>&1 || true
fi

# Install Claude plugins
claude plugin install context7@claude-plugins-official 2>&1 || true
claude plugin install frontend-design@claude-plugins-official 2>&1 || true
claude plugin install code-review@claude-plugins-official 2>&1 || true
claude plugin install superpowers@claude-plugins-official 2>&1 || true
claude plugin install github@claude-plugins-official 2>&1 || true
claude plugin install feature-dev@claude-plugins-official 2>&1 || true
claude plugin install code-simplifier@claude-plugins-official 2>&1 || true
claude plugin install ralph-loop@claude-plugins-official 2>&1 || true
claude plugin install typescript-lsp@claude-plugins-official 2>&1 || true
