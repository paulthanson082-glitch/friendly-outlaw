#!/usr/bin/env bash
#
# analyze-traces.sh - Run trace analysis on the WritersApp database
#
# This script builds the project (if needed) and runs the CLI with the
# --analyze-traces flag to produce a productivity report based on
# trace and observation data.
#
# Usage:
#   ./scripts/analyze-traces.sh
#
# The analysis includes:
#   - Productivity by session length (changes per turn, bucketed by session size)
#   - Tool usage breakdown (Edit, Write, Read, etc.)
#   - Top sessions ranked by turn count
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

swift run WritersAppCLI --analyze-traces
