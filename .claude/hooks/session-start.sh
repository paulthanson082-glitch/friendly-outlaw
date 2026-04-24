#!/bin/bash
# Do not use `set -e`: this hook should fail soft so a single broken apt
# repository or a sandboxed-network environment never blocks the whole session.
set -uo pipefail

# Only run in Claude Code on the web
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

# Install system dependencies (libsqlite3-dev needed for CSQLite module).
# `apt-get update` may fail when third-party PPAs return 403; ignore that
# failure and try to install anyway — installs work as long as the cache has
# the packages we need.
if ! dpkg -s libsqlite3-dev &>/dev/null || ! dpkg -s pkg-config &>/dev/null; then
  apt-get update -qq || true
  apt-get install -y -qq libsqlite3-dev pkg-config || \
    echo "Warning: could not install libsqlite3-dev / pkg-config." >&2
fi

# Install Swift via swiftly if not already installed.
#
# REQUIRED NETWORK ACCESS:
#   - download.swift.org   (swiftly bootstrap + Swift toolchain tarballs)
#   - swift.org            (toolchain index / signing metadata)
#
# If either host is blocked by the sandbox (HTTP 403 with `host_not_allowed`),
# Swift cannot be installed at runtime. To unblock, either:
#   (a) add the hosts above to the environment's network allowlist, or
#   (b) bake Swift into the base image (see Dockerfile.swift), or
#   (c) run builds in CI (see .github/workflows/swift.yml).
if ! command -v swift &>/dev/null; then
  apt-get install -y -qq curl 2>/dev/null || true

  ARCH="$(uname -m)"
  cd /tmp
  if curl -fsSLO --max-time 60 "https://download.swift.org/swiftly/linux/swiftly-${ARCH}.tar.gz" 2>/dev/null \
     && [ -s "swiftly-${ARCH}.tar.gz" ] \
     && tar tzf "swiftly-${ARCH}.tar.gz" &>/dev/null; then
    tar zxf "swiftly-${ARCH}.tar.gz"
    if ./swiftly init --quiet-shell-followup -y; then
      . "${SWIFTLY_HOME_DIR:-$HOME/.local/share/swiftly}/env.sh"
      hash -r
      # Persist PATH for the session
      if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
        echo ". \"${SWIFTLY_HOME_DIR:-$HOME/.local/share/swiftly}/env.sh\"" >> "$CLAUDE_ENV_FILE"
      fi
    else
      echo "Warning: swiftly init failed; Swift not installed." >&2
    fi
    rm -f "swiftly-${ARCH}.tar.gz" swiftly
  else
    echo "Warning: could not download swiftly from download.swift.org" >&2
    echo "  (likely a sandboxed network — see hook header for fixes)." >&2
  fi
fi

# Build the project to resolve dependencies and cache build artifacts
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
