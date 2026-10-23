#!/bin/bash
set -euo pipefail

# Only run in Claude Code on the web
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

# Install system dependencies (libsqlite3-dev needed for CSQLite module)
if ! dpkg -s libsqlite3-dev &>/dev/null || ! dpkg -s pkg-config &>/dev/null; then
  apt-get update -qq >&2
  apt-get install -y -qq libsqlite3-dev pkg-config >&2
fi

# Install Swift via swiftly if not already installed
if ! command -v swift &>/dev/null; then
  apt-get update -qq >&2
  apt-get install -y -qq curl >&2

  ARCH="$(uname -m)"
  cd /tmp
  if curl -sSLO "https://download.swift.org/swiftly/linux/swiftly-${ARCH}.tar.gz" 2>/dev/null && [ -f "swiftly-${ARCH}.tar.gz" ]; then
    tar zxf "swiftly-${ARCH}.tar.gz"
    ./swiftly init --quiet-shell-followup -y >&2
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
  swift build >&2
else
  echo "Warning: swift not found — skipping build step." >&2
fi

# Install Firecrawl CLI for web scraping, searching, and browsing
if ! command -v firecrawl &>/dev/null; then
  npm install -g firecrawl-cli >&2 || true
fi

# Install Claude plugins (best-effort; marketplace may be out of date)
claude plugin install context7@claude-plugins-official >&2 || true
claude plugin install frontend-design@claude-plugins-official >&2 || true
claude plugin install code-review@claude-plugins-official >&2 || true
claude plugin install github@claude-plugins-official >&2 || true
claude plugin install feature-dev@claude-plugins-official >&2 || true
claude plugin install code-simplifier@claude-plugins-official >&2 || true
claude plugin install ralph-loop@claude-plugins-official >&2 || true
claude plugin install typescript-lsp@claude-plugins-official >&2 || true

# Inject superpowers using-superpowers bootstrap directly from bundled skills.
# The superpowers plugin marketplace install is unreliable; skills are bundled
# in .claude/skills/ and the bootstrap is injected here at session start.
SUPERPOWERS_SKILL="$CLAUDE_PROJECT_DIR/.claude/skills/using-superpowers/SKILL.md"

if [ -f "$SUPERPOWERS_SKILL" ]; then
  using_superpowers_content=$(cat "$SUPERPOWERS_SKILL")

  escape_for_json() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    s="${s//$'\r'/\\r}"
    s="${s//$'\t'/\\t}"
    printf '%s' "$s"
  }

  escaped=$(escape_for_json "$using_superpowers_content")
  session_context="<EXTREMELY_IMPORTANT>\nYou have superpowers.\n\n**Below is the full content of your 'superpowers:using-superpowers' skill - your introduction to using skills. For all other skills, use the 'Skill' tool:**\n\n${escaped}\n</EXTREMELY_IMPORTANT>"

  printf '{\n  "hookSpecificOutput": {\n    "hookEventName": "SessionStart",\n    "additionalContext": "%s"\n  }\n}\n' "$session_context"
fi
