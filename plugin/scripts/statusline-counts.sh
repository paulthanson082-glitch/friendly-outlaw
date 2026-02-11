#!/bin/bash
# Statusline counter script for VS Code statusLineCommand integration
# Usage: statusline-counts.sh /path/to/project

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Build the StatuslineCounter if needed
if [ ! -f "$PROJECT_ROOT/.build/debug/StatuslineCounter" ]; then
    cd "$PROJECT_ROOT" && swift build > /dev/null 2>&1
fi

# Run the counter
"$PROJECT_ROOT/.build/debug/StatuslineCounter" "$@"
