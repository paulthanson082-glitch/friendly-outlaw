#!/bin/bash
# Statusline counter script for VS Code statusLineCommand integration
# Usage: statusline-counts.sh /path/to/project

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

if [ -f "$PROJECT_ROOT/.build/release/StatuslineCounter" ]; then
    COUNTER="$PROJECT_ROOT/.build/release/StatuslineCounter"
elif [ -f "$PROJECT_ROOT/.build/debug/StatuslineCounter" ]; then
    COUNTER="$PROJECT_ROOT/.build/debug/StatuslineCounter"
else
    cd "$PROJECT_ROOT" && swift build > /dev/null 2>&1
    COUNTER="$PROJECT_ROOT/.build/debug/StatuslineCounter"
fi

"$COUNTER" "$@"
