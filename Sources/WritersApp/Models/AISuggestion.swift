import Foundation

/// Represents an AI suggestion made to a user
public struct AISuggestion: Codable, Identifiable {
    public let id: UUID
    public let userId: UUID
    public let documentId: UUID?
    public let toolUsed: String
    public let prompt: String
    public let response: String
    public let timestamp: Date
    public var isApplied: Bool
    
    public init(
        id: UUID = UUID(),
        userId: UUID,
        documentId: UUID? = nil,
        toolUsed: String,
        prompt: String,
        response: String,
        timestamp: Date = Date(),
        isApplied: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.documentId = documentId
        self.toolUsed = toolUsed
        self.prompt = prompt
        self.response = response
        self.timestamp = timestamp
        self.isApplied = isApplied
    }
}

/// Represents a user session with the app
public struct UserSession: Codable, Identifiable {
    public let id: UUID
    public let userId: UUID
    public let startTime: Date
    public var endTime: Date?
    public var durationSeconds: Int?
    public var wordsWritten: Int
    public var aiInteractions: Int
    public var multitaskingMode: String?
    
    public init(
        id: UUID = UUID(),
        userId: UUID,
        startTime: Date = Date(),
        endTime: Date? = nil,
        durationSeconds: Int? = nil,
        wordsWritten: Int = 0,
        aiInteractions: Int = 0,
        multitaskingMode: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.startTime = startTime
        self.endTime = endTime
        self.durationSeconds = durationSeconds
        self.wordsWritten = wordsWritten
        self.aiInteractions = aiInteractions
        self.multitaskingMode = multitaskingMode
    }
}

/// Statistics for AI tool usage
public struct AIToolUsageStats: Codable {
    public let toolName: String
    public let usageCount: Int
    public let lastUsed: Date?
    
    public init(toolName: String, usageCount: Int, lastUsed: Date? = nil) {
        self.toolName = toolName
        self.usageCount = usageCount
        self.lastUsed = lastUsed
    }
}

// MARK: - Token Usage Records

/// A record of token usage for a single AI API call, persisted to the database
public struct TokenUsageRecord: Codable, Identifiable {
    public let id: UUID
    public let timestamp: Date
    public let operation: String
    public let model: String
    public let inputTokens: Int
    public let outputTokens: Int

    public var totalTokens: Int { inputTokens + outputTokens }

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        operation: String,
        model: String,
        inputTokens: Int,
        outputTokens: Int
    ) {
        self.id = id
        self.timestamp = timestamp
        self.operation = operation
        self.model = model
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
    }
}

/// Aggregated token usage totals
public struct TokenUsageSummary: Codable {
    public let totalInputTokens: Int
    public let totalOutputTokens: Int
    public let totalTokens: Int
    public let estimatedCostUSD: Double
    public let requestCount: Int

    public init(totalInputTokens: Int, totalOutputTokens: Int, estimatedCostUSD: Double, requestCount: Int) {
        self.totalInputTokens = totalInputTokens
        self.totalOutputTokens = totalOutputTokens
        self.totalTokens = totalInputTokens + totalOutputTokens
        self.estimatedCostUSD = estimatedCostUSD
        self.requestCount = requestCount
    }
}

/// Daily token usage breakdown
public struct DailyTokenUsage: Codable {
    public let date: String
    public let inputTokens: Int
    public let outputTokens: Int
    public let totalTokens: Int
    public let estimatedCostUSD: Double
    public let requestCount: Int

    public init(date: String, inputTokens: Int, outputTokens: Int, estimatedCostUSD: Double, requestCount: Int) {
        self.date = date
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.totalTokens = inputTokens + outputTokens
        self.estimatedCostUSD = estimatedCostUSD
        self.requestCount = requestCount
    }
}

/// Per-model token usage breakdown
public struct ModelTokenUsage: Codable {
    public let model: String
    public let inputTokens: Int
    public let outputTokens: Int
    public let totalTokens: Int
    public let estimatedCostUSD: Double
    public let requestCount: Int

    public init(model: String, inputTokens: Int, outputTokens: Int, estimatedCostUSD: Double, requestCount: Int) {
        self.model = model
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.totalTokens = inputTokens + outputTokens
        self.estimatedCostUSD = estimatedCostUSD
        self.requestCount = requestCount
    }
}

/// Per-operation token usage breakdown
public struct OperationTokenUsage: Codable {
    public let operation: String
    public let inputTokens: Int
    public let outputTokens: Int
    public let totalTokens: Int
    public let estimatedCostUSD: Double
    public let requestCount: Int

    public init(operation: String, inputTokens: Int, outputTokens: Int, estimatedCostUSD: Double, requestCount: Int) {
        self.operation = operation
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.totalTokens = inputTokens + outputTokens
        self.estimatedCostUSD = estimatedCostUSD
        self.requestCount = requestCount
    }
}

/// Statistics for user sessions
public struct SessionStats: Codable {
    public let totalSessions: Int
    public let totalDurationSeconds: Int
    public let averageDurationSeconds: Double
    public let earliestSession: Date?
    public let latestSession: Date?
    
    public init(
        totalSessions: Int,
        totalDurationSeconds: Int,
        averageDurationSeconds: Double,
        earliestSession: Date?,
        latestSession: Date?
    ) {
        self.totalSessions = totalSessions
        self.totalDurationSeconds = totalDurationSeconds
        self.averageDurationSeconds = averageDurationSeconds
        self.earliestSession = earliestSession
        self.latestSession = latestSession
    }
}
