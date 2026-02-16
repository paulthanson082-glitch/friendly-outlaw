#!/usr/bin/env bash
#
# analyze-traces.sh - Run trace analysis on the WritersApp database
#
# Usage:
#   ./scripts/analyze-traces.sh                    # Local analysis only
#   ./scripts/analyze-traces.sh --export-langfuse   # Analyze + export to Langfuse
#
# For Langfuse Cloud or self-hosted with the Python SDK:
#   python3 scripts/analyze-traces-sdk.py
#
# The analysis includes:
#   - Productivity by session length (changes per turn, bucketed by session size)
#   - Tool usage breakdown (Edit, Write, Read, etc.)
#   - Read-before-edit compliance
#   - Top sessions ranked by turn count
#
# Langfuse env vars (optional, for --export-langfuse):
#   TRACE_TO_LANGFUSE=true
#   LANGFUSE_PUBLIC_KEY=pk-lf-...
#   LANGFUSE_SECRET_KEY=sk-lf-...
#   LANGFUSE_HOST=https://cloud.langfuse.com
#
# Equivalent SQL (ClickHouse syntax, adapted to SQLite in the Swift service):
#
#   WITH session_metrics AS (
#       SELECT t.session_id,
#           count(DISTINCT t.id) as turns,
#           countIf(o.name = 'Tool: Edit')
#               + countIf(o.name = 'Tool: Write') as changes,
#           countIf(o.name = 'Tool: Read') as reads
#       FROM traces t
#       LEFT JOIN observations o
#           ON t.id = o.trace_id
#       WHERE t.session_id NOT LIKE 'historical-%'
#       GROUP BY t.session_id
#       HAVING turns > 1
#   )
#   SELECT
#       multiIf(turns<=3,'2-3',turns<=7,'4-7',
#               turns<=12,'8-12','13+') as bucket,
#       count() as sessions,
#       round(avg(changes/turns), 2) as changes_per_turn
#   FROM session_metrics
#   GROUP BY bucket ORDER BY min(turns)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_DIR"

echo "Building project..."
if ! swift build 2>/dev/null; then
    echo "Debug build failed, trying with verbose output..."
    swift build
fi

echo ""
echo "Running trace analysis..."
echo ""

# Pass through any flags (e.g. --export-langfuse)
swift run WritersAppCLI --analyze-traces "$@"
