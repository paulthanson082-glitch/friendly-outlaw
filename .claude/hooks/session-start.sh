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

# Ensure the official Claude plugins marketplace is registered
claude plugin marketplace add anthropics/claude-plugins-official 2>&1 || true

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
claude plugin install security-guidance@claude-plugins-official 2>&1 || true
claude plugin install commit-commands@claude-plugins-official 2>&1 || true
claude plugin install playwright@claude-plugins-official 2>&1 || true
claude plugin install claude-md-management@claude-plugins-official 2>&1 || true
