import Foundation

/// Represents a trace (a single interaction turn within a session)
public struct Trace: Codable, Identifiable {
    public let id: UUID
    public let sessionId: String
    public let name: String
    public let startTime: Date
    public var endTime: Date?
    public var metadata: String?

    public init(
        id: UUID = UUID(),
        sessionId: String,
        name: String,
        startTime: Date = Date(),
        endTime: Date? = nil,
        metadata: String? = nil
    ) {
        self.id = id
        self.sessionId = sessionId
        self.name = name
        self.startTime = startTime
        self.endTime = endTime
        self.metadata = metadata
    }

    /// Duration in seconds, if both start and end times are set
    public var durationSeconds: Double? {
        guard let end = endTime else { return nil }
        return end.timeIntervalSince(startTime)
    }
}

/// Represents an observation within a trace (tool call, action, etc.)
public struct Observation: Codable, Identifiable {
    public let id: UUID
    public let traceId: UUID
    public let name: String
    public let startTime: Date
    public var endTime: Date?
    public var input: String?
    public var output: String?
    public var statusMessage: String?

    public init(
        id: UUID = UUID(),
        traceId: UUID,
        name: String,
        startTime: Date = Date(),
        endTime: Date? = nil,
        input: String? = nil,
        output: String? = nil,
        statusMessage: String? = nil
    ) {
        self.id = id
        self.traceId = traceId
        self.name = name
        self.startTime = startTime
        self.endTime = endTime
        self.input = input
        self.output = output
        self.statusMessage = statusMessage
    }
}

// MARK: - Analysis Result Models

/// Productivity metrics for a session-length bucket
public struct SessionBucketMetrics: Codable {
    public let bucket: String
    public let sessions: Int
    public let changesPerTurn: Double

    public init(bucket: String, sessions: Int, changesPerTurn: Double) {
        self.bucket = bucket
        self.sessions = sessions
        self.changesPerTurn = changesPerTurn
    }
}

/// Per-session metrics used in analysis
public struct SessionMetrics: Codable {
    public let sessionId: String
    public let turns: Int
    public let changes: Int
    public let reads: Int

    public init(sessionId: String, turns: Int, changes: Int, reads: Int) {
        self.sessionId = sessionId
        self.turns = turns
        self.changes = changes
        self.reads = reads
    }

    /// Ratio of changes (edits + writes) per turn
    public var changesPerTurn: Double {
        guard turns > 0 else { return 0 }
        return Double(changes) / Double(turns)
    }
}

/// Tool usage frequency data
public struct ToolUsageFrequency: Codable {
    public let toolName: String
    public let count: Int
    public let percentage: Double

    public init(toolName: String, count: Int, percentage: Double) {
        self.toolName = toolName
        self.count = count
        self.percentage = percentage
    }
}

/// Read-before-edit compliance metrics
public struct ReadBeforeEditMetrics: Codable {
    public let tracesWithEdit: Int
    public let alsoReadFirst: Int
    public let percentage: Double

    public init(tracesWithEdit: Int, alsoReadFirst: Int, percentage: Double) {
        self.tracesWithEdit = tracesWithEdit
        self.alsoReadFirst = alsoReadFirst
        self.percentage = percentage
    }
}

/// Comprehensive trace analysis report
public struct TraceAnalysisReport: Codable {
    public let generatedAt: Date
    public let totalTraces: Int
    public let totalObservations: Int
    public let totalSessions: Int
    public let productivityBySessionLength: [SessionBucketMetrics]
    public let toolUsageBreakdown: [ToolUsageFrequency]
    public let sessionMetrics: [SessionMetrics]
    public let readBeforeEdit: ReadBeforeEditMetrics

    public init(
        generatedAt: Date = Date(),
        totalTraces: Int,
        totalObservations: Int,
        totalSessions: Int,
        productivityBySessionLength: [SessionBucketMetrics],
        toolUsageBreakdown: [ToolUsageFrequency],
        sessionMetrics: [SessionMetrics],
        readBeforeEdit: ReadBeforeEditMetrics
    ) {
        self.generatedAt = generatedAt
        self.totalTraces = totalTraces
        self.totalObservations = totalObservations
        self.totalSessions = totalSessions
        self.productivityBySessionLength = productivityBySessionLength
        self.toolUsageBreakdown = toolUsageBreakdown
        self.sessionMetrics = sessionMetrics
        self.readBeforeEdit = readBeforeEdit
    }
}
