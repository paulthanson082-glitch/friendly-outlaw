#!/usr/bin/env python3
"""
analyze-traces-sdk.py - Analyze traces via the Langfuse Python SDK.

Use this when connecting to Langfuse Cloud or a self-hosted instance
that doesn't expose ClickHouse directly.

Usage:
    # Set env vars first
    export LANGFUSE_PUBLIC_KEY="pk-lf-..."
    export LANGFUSE_SECRET_KEY="sk-lf-..."
    export LANGFUSE_HOST="https://cloud.langfuse.com"   # optional, this is default

    python3 scripts/analyze-traces-sdk.py

Requirements:
    pip install langfuse
"""

import os
import sys
from collections import defaultdict

try:
    from langfuse import Langfuse
except ImportError:
    print("Error: langfuse package not installed.")
    print("Install it with: pip install langfuse")
    sys.exit(1)


def get_client() -> Langfuse:
    public_key = os.environ.get("LANGFUSE_PUBLIC_KEY")
    secret_key = os.environ.get("LANGFUSE_SECRET_KEY")
    host = os.environ.get("LANGFUSE_HOST", "https://cloud.langfuse.com")

    if not public_key or not secret_key:
        print("Error: LANGFUSE_PUBLIC_KEY and LANGFUSE_SECRET_KEY must be set.")
        sys.exit(1)

    return Langfuse(public_key=public_key, secret_key=secret_key, host=host)


def fetch_all_traces(client: Langfuse) -> list:
    """Fetch all traces using pagination."""
    all_traces = []
    page = 1
    while True:
        response = client.fetch_traces(page=page, limit=100)
        traces = response.data
        if not traces:
            break
        all_traces.extend(traces)
        if len(traces) < 100:
            break
        page += 1
    return all_traces


def fetch_observations_for_trace(client: Langfuse, trace_id: str) -> list:
    """Fetch observations for a single trace."""
    response = client.fetch_observations(trace_id=trace_id, limit=500)
    return response.data


def productivity_by_session_length(traces: list, observations_by_trace: dict):
    """
    Equivalent to the ClickHouse query:

    WITH session_metrics AS (
        SELECT t.session_id,
            count(DISTINCT t.id) as turns,
            countIf(o.name = 'Tool: Edit')
                + countIf(o.name = 'Tool: Write') as changes,
            countIf(o.name = 'Tool: Read') as reads
        FROM traces t
        LEFT JOIN observations o ON t.id = o.trace_id
        WHERE t.session_id NOT LIKE 'historical-%'
        GROUP BY t.session_id
        HAVING turns > 1
    )
    SELECT
        multiIf(turns<=3,'2-3',turns<=7,'4-7',
                turns<=12,'8-12','13+') as bucket,
        count() as sessions,
        round(avg(changes/turns), 2) as changes_per_turn
    FROM session_metrics
    GROUP BY bucket ORDER BY min(turns)
    """
    session_map = defaultdict(lambda: {"trace_ids": set(), "changes": 0, "reads": 0})

    for trace in traces:
        session_id = getattr(trace, "session_id", None) or ""
        if session_id.startswith("historical-"):
            continue
        trace_id = trace.id
        session_map[session_id]["trace_ids"].add(trace_id)

        for obs in observations_by_trace.get(trace_id, []):
            name = getattr(obs, "name", "") or ""
            if name in ("Tool: Edit", "Tool: Write"):
                session_map[session_id]["changes"] += 1
            elif name == "Tool: Read":
                session_map[session_id]["reads"] += 1

    # Filter to sessions with > 1 turn
    metrics = []
    for session_id, data in session_map.items():
        turns = len(data["trace_ids"])
        if turns > 1:
            metrics.append({
                "session_id": session_id,
                "turns": turns,
                "changes": data["changes"],
                "reads": data["reads"],
            })

    # Bucket
    buckets = {}
    for m in metrics:
        turns = m["turns"]
        if turns <= 3:
            bucket = "2-3"
        elif turns <= 7:
            bucket = "4-7"
        elif turns <= 12:
            bucket = "8-12"
        else:
            bucket = "13+"

        cpt = m["changes"] / m["turns"]
        if bucket not in buckets:
            buckets[bucket] = {"sessions": 0, "total_cpt": 0.0, "min_turns": turns}
        buckets[bucket]["sessions"] += 1
        buckets[bucket]["total_cpt"] += cpt
        buckets[bucket]["min_turns"] = min(buckets[bucket]["min_turns"], turns)

    # Sort and format
    result = []
    for bucket, data in sorted(buckets.items(), key=lambda x: x[1]["min_turns"]):
        avg_cpt = round(data["total_cpt"] / data["sessions"], 2) if data["sessions"] else 0
        result.append((bucket, data["sessions"], avg_cpt))
    return result


def read_before_edit_compliance(traces: list, observations_by_trace: dict):
    """
    Equivalent to the ClickHouse query:

    SELECT
        countIf(has_edit) as traces_with_edit,
        countIf(has_edit AND has_read) as also_read_first,
        round(countIf(has_edit AND has_read) * 100.0
            / greatest(countIf(has_edit), 1), 1) as pct
    FROM (
        SELECT trace_id,
            has(groupArray(name), 'Tool: Read') as has_read,
            has(groupArray(name), 'Tool: Edit') as has_edit
        FROM observations
        WHERE name LIKE 'Tool:%'
        GROUP BY trace_id
    )
    """
    traces_with_edit = 0
    also_read_first = 0

    for trace in traces:
        obs_list = observations_by_trace.get(trace.id, [])
        tool_names = {
            getattr(o, "name", "") or ""
            for o in obs_list
            if (getattr(o, "name", "") or "").startswith("Tool:")
        }

        if "Tool: Edit" not in tool_names:
            continue
        traces_with_edit += 1
        if "Tool: Read" in tool_names:
            also_read_first += 1

    pct = round(also_read_first * 100.0 / max(traces_with_edit, 1), 1)
    return traces_with_edit, also_read_first, pct


def tool_usage_breakdown(observations_by_trace: dict):
    """Count tool usage across all observations."""
    counts = defaultdict(int)
    total = 0
    for obs_list in observations_by_trace.values():
        for obs in obs_list:
            name = getattr(obs, "name", "") or ""
            counts[name] += 1
            total += 1
    result = []
    for name, count in sorted(counts.items(), key=lambda x: -x[1]):
        pct = round(count * 100.0 / max(total, 1), 1)
        result.append((name, count, pct))
    return result


def main():
    print("=" * 60)
    print("  TRACE ANALYSIS REPORT (Langfuse SDK)")
    print("=" * 60)
    print()

    client = get_client()

    print("Fetching traces from Langfuse...")
    traces = fetch_all_traces(client)
    print(f"Found {len(traces)} traces.")

    print("Fetching observations...")
    observations_by_trace = {}
    for i, trace in enumerate(traces):
        observations_by_trace[trace.id] = fetch_observations_for_trace(client, trace.id)
        if (i + 1) % 50 == 0:
            print(f"  ...fetched observations for {i + 1}/{len(traces)} traces")
    print(f"Done. {sum(len(v) for v in observations_by_trace.values())} total observations.")
    print()

    # Summary
    session_ids = {getattr(t, "session_id", None) or "" for t in traces}
    total_obs = sum(len(v) for v in observations_by_trace.values())

    print("--- Summary ---")
    print(f"Total traces:       {len(traces)}")
    print(f"Total observations: {total_obs}")
    print(f"Total sessions:     {len(session_ids)}")
    print()

    # Productivity by session length
    print("--- Productivity by Session Length ---")
    buckets = productivity_by_session_length(traces, observations_by_trace)
    if not buckets:
        print("  (no data)")
    else:
        print(f"  {'Bucket':<10}  {'Sessions':>10}  {'Changes/Turn':>16}")
        print("  " + "-" * 40)
        for bucket, sessions, cpt in buckets:
            print(f"  {bucket:<10}  {sessions:>10}  {cpt:>16.2f}")
    print()

    # Tool usage
    print("--- Tool Usage Breakdown ---")
    tools = tool_usage_breakdown(observations_by_trace)
    if not tools:
        print("  (no data)")
    else:
        print(f"  {'Tool':<25}  {'Count':>8}  {'Pct':>8}")
        print("  " + "-" * 45)
        for name, count, pct in tools:
            print(f"  {name:<25}  {count:>8}  {pct:>7.1f}%")
    print()

    # Read before edit compliance
    print("--- Read Before Edit Compliance ---")
    rbe_edit, rbe_read, rbe_pct = read_before_edit_compliance(traces, observations_by_trace)
    print(f"  Traces with Edit:    {rbe_edit}")
    print(f"  Also Read first:     {rbe_read}")
    print(f"  Compliance:          {rbe_pct}%")
    print()

    print("=" * 60)
    client.shutdown()


if __name__ == "__main__":
    main()
