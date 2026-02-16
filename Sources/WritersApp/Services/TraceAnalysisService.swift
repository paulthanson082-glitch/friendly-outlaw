import Foundation
import CSQLite

/// Service for analyzing traces and observations to derive productivity insights.
///
/// Adapts the ClickHouse-style analytics queries to SQLite, providing:
/// - Productivity by session length (changes per turn bucketed by session size)
/// - Tool usage breakdown
/// - Per-session metrics
public class TraceAnalysisService {

    private let databaseManager: DatabaseManager

    public init(databaseManager: DatabaseManager) {
        self.databaseManager = databaseManager
    }

    // MARK: - Full Analysis

    /// Runs the complete trace analysis and returns a report
    public func runFullAnalysis() throws -> TraceAnalysisReport {
        let totals = try getTotals()
        let bucketMetrics = try getProductivityBySessionLength()
        let toolUsage = try getToolUsageBreakdown()
        let sessionMetrics = try getSessionMetrics()
        let readBeforeEdit = try getReadBeforeEditMetrics()

        return TraceAnalysisReport(
            totalTraces: totals.traces,
            totalObservations: totals.observations,
            totalSessions: totals.sessions,
            productivityBySessionLength: bucketMetrics,
            toolUsageBreakdown: toolUsage,
            sessionMetrics: sessionMetrics,
            readBeforeEdit: readBeforeEdit
        )
    }

    // MARK: - Productivity by Session Length

    /// The core query adapted from ClickHouse to SQLite.
    ///
    /// ClickHouse original:
    /// ```sql
    /// WITH session_metrics AS (
    ///     SELECT t.session_id,
    ///         count(DISTINCT t.id) as turns,
    ///         countIf(o.name = 'Tool: Edit')
    ///             + countIf(o.name = 'Tool: Write') as changes,
    ///         countIf(o.name = 'Tool: Read') as reads
    ///     FROM traces t
    ///     LEFT JOIN observations o ON t.id = o.trace_id
    ///     WHERE t.session_id NOT LIKE 'historical-%'
    ///     GROUP BY t.session_id
    ///     HAVING turns > 1
    /// )
    /// SELECT
    ///     multiIf(turns<=3,'2-3',turns<=7,'4-7',turns<=12,'8-12','13+') as bucket,
    ///     count() as sessions,
    ///     round(avg(changes/turns), 2) as changes_per_turn
    /// FROM session_metrics
    /// GROUP BY bucket ORDER BY min(turns)
    /// ```
    public func getProductivityBySessionLength() throws -> [SessionBucketMetrics] {
        let traces = try databaseManager.getTraces()
        if traces.isEmpty { return [] }

        // Build session metrics in memory (SQLite doesn't support CTEs with countIf)
        var sessionMap: [String: (traceIds: Set<UUID>, changes: Int, reads: Int)] = [:]

        for trace in traces {
            if trace.sessionId.hasPrefix("historical-") { continue }
            if sessionMap[trace.sessionId] == nil {
                sessionMap[trace.sessionId] = (traceIds: [], changes: 0, reads: 0)
            }
            sessionMap[trace.sessionId]?.traceIds.insert(trace.id)

            let observations = try databaseManager.getObservations(traceId: trace.id)
            for obs in observations {
                if obs.name == "Tool: Edit" || obs.name == "Tool: Write" {
                    sessionMap[trace.sessionId]?.changes += 1
                } else if obs.name == "Tool: Read" {
                    sessionMap[trace.sessionId]?.reads += 1
                }
            }
        }

        // Filter to sessions with > 1 turn
        let metrics: [SessionMetrics] = sessionMap.compactMap { (sessionId, data) in
            let turns = data.traceIds.count
            guard turns > 1 else { return nil }
            return SessionMetrics(sessionId: sessionId, turns: turns, changes: data.changes, reads: data.reads)
        }

        // Bucket sessions
        var buckets: [String: (sessions: Int, totalChangesPerTurn: Double, minTurns: Int)] = [:]

        for m in metrics {
            let bucket: String
            switch m.turns {
            case 2...3: bucket = "2-3"
            case 4...7: bucket = "4-7"
            case 8...12: bucket = "8-12"
            default: bucket = "13+"
            }

            let cpt = Double(m.changes) / Double(m.turns)
            if var existing = buckets[bucket] {
                existing.sessions += 1
                existing.totalChangesPerTurn += cpt
                existing.minTurns = min(existing.minTurns, m.turns)
                buckets[bucket] = existing
            } else {
                buckets[bucket] = (sessions: 1, totalChangesPerTurn: cpt, minTurns: m.turns)
            }
        }

        // Sort by min turns and compute averages
        return buckets.sorted { $0.value.minTurns < $1.value.minTurns }.map { (bucket, data) in
            let avg = data.sessions > 0 ? (data.totalChangesPerTurn / Double(data.sessions) * 100).rounded() / 100 : 0
            return SessionBucketMetrics(bucket: bucket, sessions: data.sessions, changesPerTurn: avg)
        }
    }

    // MARK: - Tool Usage Breakdown

    /// Returns a breakdown of tool usage across all observations
    public func getToolUsageBreakdown() throws -> [ToolUsageFrequency] {
        let traces = try databaseManager.getTraces()
        var toolCounts: [String: Int] = [:]
        var total = 0

        for trace in traces {
            let observations = try databaseManager.getObservations(traceId: trace.id)
            for obs in observations {
                toolCounts[obs.name, default: 0] += 1
                total += 1
            }
        }

        guard total > 0 else { return [] }

        return toolCounts.sorted { $0.value > $1.value }.map { (name, count) in
            let pct = (Double(count) / Double(total) * 10000).rounded() / 100
            return ToolUsageFrequency(toolName: name, count: count, percentage: pct)
        }
    }

    // MARK: - Session Metrics

    /// Returns per-session metrics for all non-historical sessions with > 1 turn
    public func getSessionMetrics() throws -> [SessionMetrics] {
        let traces = try databaseManager.getTraces()
        var sessionMap: [String: (traceIds: Set<UUID>, changes: Int, reads: Int)] = [:]

        for trace in traces {
            if trace.sessionId.hasPrefix("historical-") { continue }
            if sessionMap[trace.sessionId] == nil {
                sessionMap[trace.sessionId] = (traceIds: [], changes: 0, reads: 0)
            }
            sessionMap[trace.sessionId]?.traceIds.insert(trace.id)

            let observations = try databaseManager.getObservations(traceId: trace.id)
            for obs in observations {
                if obs.name == "Tool: Edit" || obs.name == "Tool: Write" {
                    sessionMap[trace.sessionId]?.changes += 1
                } else if obs.name == "Tool: Read" {
                    sessionMap[trace.sessionId]?.reads += 1
                }
            }
        }

        return sessionMap.compactMap { (sessionId, data) in
            let turns = data.traceIds.count
            guard turns > 1 else { return nil }
            return SessionMetrics(sessionId: sessionId, turns: turns, changes: data.changes, reads: data.reads)
        }.sorted { $0.turns > $1.turns }
    }

    // MARK: - Read Before Edit Compliance

    /// Checks how often traces that contain an Edit also contain a Read.
    ///
    /// ClickHouse original:
    /// ```sql
    /// SELECT
    ///     countIf(has_edit) as traces_with_edit,
    ///     countIf(has_edit AND has_read) as also_read_first,
    ///     round(countIf(has_edit AND has_read) * 100.0
    ///         / greatest(countIf(has_edit), 1), 1) as pct
    /// FROM (
    ///     SELECT trace_id,
    ///         has(groupArray(name), 'Tool: Read') as has_read,
    ///         has(groupArray(name), 'Tool: Edit') as has_edit
    ///     FROM observations
    ///     WHERE name LIKE 'Tool:%'
    ///     GROUP BY trace_id
    /// )
    /// ```
    public func getReadBeforeEditMetrics() throws -> ReadBeforeEditMetrics {
        let traces = try databaseManager.getTraces()

        var tracesWithEdit = 0
        var alsoReadFirst = 0

        for trace in traces {
            let observations = try databaseManager.getObservations(traceId: trace.id)
            let toolObs = observations.filter { $0.name.hasPrefix("Tool:") }

            let hasEdit = toolObs.contains { $0.name == "Tool: Edit" }
            guard hasEdit else { continue }

            tracesWithEdit += 1
            let hasRead = toolObs.contains { $0.name == "Tool: Read" }
            if hasRead {
                alsoReadFirst += 1
            }
        }

        let pct = tracesWithEdit > 0
            ? (Double(alsoReadFirst) * 1000.0 / Double(tracesWithEdit)).rounded() / 10.0
            : 0.0

        return ReadBeforeEditMetrics(
            tracesWithEdit: tracesWithEdit,
            alsoReadFirst: alsoReadFirst,
            percentage: pct
        )
    }

    // MARK: - Totals

    private func getTotals() throws -> (traces: Int, observations: Int, sessions: Int) {
        let traces = try databaseManager.getTraces()
        var observationCount = 0
        var sessionIds = Set<String>()

        for trace in traces {
            sessionIds.insert(trace.sessionId)
            let observations = try databaseManager.getObservations(traceId: trace.id)
            observationCount += observations.count
        }

        return (traces: traces.count, observations: observationCount, sessions: sessionIds.count)
    }

    // MARK: - Report Formatting

    /// Formats the analysis report as a human-readable string
    public static func formatReport(_ report: TraceAnalysisReport) -> String {
        var lines: [String] = []

        lines.append("=" * 60)
        lines.append("  TRACE ANALYSIS REPORT")
        lines.append("=" * 60)
        lines.append("")

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        lines.append("Generated: \(formatter.string(from: report.generatedAt))")
        lines.append("")

        // Summary
        lines.append("--- Summary ---")
        lines.append("Total traces:       \(report.totalTraces)")
        lines.append("Total observations: \(report.totalObservations)")
        lines.append("Total sessions:     \(report.totalSessions)")
        lines.append("")

        // Productivity by session length
        lines.append("--- Productivity by Session Length ---")
        if report.productivityBySessionLength.isEmpty {
            lines.append("  (no data)")
        } else {
            lines.append(String(format: "  %-10s  %10s  %16s", "Bucket", "Sessions", "Changes/Turn"))
            lines.append("  " + "-" * 40)
            for bucket in report.productivityBySessionLength {
                lines.append(String(format: "  %-10s  %10d  %16.2f", bucket.bucket, bucket.sessions, bucket.changesPerTurn))
            }
        }
        lines.append("")

        // Tool usage
        lines.append("--- Tool Usage Breakdown ---")
        if report.toolUsageBreakdown.isEmpty {
            lines.append("  (no data)")
        } else {
            lines.append(String(format: "  %-25s  %8s  %8s", "Tool", "Count", "Pct"))
            lines.append("  " + "-" * 45)
            for tool in report.toolUsageBreakdown {
                lines.append(String(format: "  %-25s  %8d  %7.1f%%", tool.toolName, tool.count, tool.percentage))
            }
        }
        lines.append("")

        // Read before edit compliance
        lines.append("--- Read Before Edit Compliance ---")
        let rbe = report.readBeforeEdit
        lines.append("  Traces with Edit:    \(rbe.tracesWithEdit)")
        lines.append("  Also Read first:     \(rbe.alsoReadFirst)")
        lines.append("  Compliance:          \(String(format: "%.1f", rbe.percentage))%")
        lines.append("")

        // Top sessions
        lines.append("--- Top Sessions by Turn Count ---")
        let top = Array(report.sessionMetrics.prefix(10))
        if top.isEmpty {
            lines.append("  (no data)")
        } else {
            lines.append(String(format: "  %-36s  %6s  %8s  %6s  %12s", "Session ID", "Turns", "Changes", "Reads", "Changes/Turn"))
            lines.append("  " + "-" * 75)
            for s in top {
                lines.append(String(format: "  %-36s  %6d  %8d  %6d  %12.2f", s.sessionId.prefix(36), s.turns, s.changes, s.reads, s.changesPerTurn))
            }
        }
        lines.append("")
        lines.append("=" * 60)

        return lines.joined(separator: "\n")
    }
}

// MARK: - String Repeat Helper

private extension String {
    static func * (lhs: String, rhs: Int) -> String {
        return String(repeating: lhs, count: rhs)
    }
}
