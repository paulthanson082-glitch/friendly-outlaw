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
    public var project: String?
    
    public init(
        id: UUID = UUID(),
        userId: UUID,
        documentId: UUID? = nil,
        toolUsed: String,
        prompt: String,
        response: String,
        timestamp: Date = Date(),
        isApplied: Bool = false,
        project: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.documentId = documentId
        self.toolUsed = toolUsed
        self.prompt = prompt
        self.response = response
        self.timestamp = timestamp
        self.isApplied = isApplied
        self.project = project
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
    public var project: String?
    
    public init(
        id: UUID = UUID(),
        userId: UUID,
        startTime: Date = Date(),
        endTime: Date? = nil,
        durationSeconds: Int? = nil,
        wordsWritten: Int = 0,
        aiInteractions: Int = 0,
        multitaskingMode: String? = nil,
        project: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.startTime = startTime
        self.endTime = endTime
        self.durationSeconds = durationSeconds
        self.wordsWritten = wordsWritten
        self.aiInteractions = aiInteractions
        self.multitaskingMode = multitaskingMode
        self.project = project
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
