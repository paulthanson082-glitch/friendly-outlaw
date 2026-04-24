import Foundation

/// Type of focus session
public enum FocusSessionType: String, Codable, CaseIterable {
    case freeWrite = "free_write"
    case openRun = "open_run"
    case pomodoro = "pomodoro"
    case sprint = "sprint"
    case deepWork = "deep_work"
    case marathon = "marathon"

    public var displayName: String {
        switch self {
        case .freeWrite: return "Free Write"
        case .openRun: return "Open Run"
        case .pomodoro: return "Pomodoro (25 min)"
        case .sprint: return "Writing Sprint"
        case .deepWork: return "Deep Work (90 min)"
        case .marathon: return "Marathon (120 min)"
        }
    }

    /// Default duration in seconds
    public var defaultDuration: TimeInterval {
        switch self {
        case .freeWrite: return 0 // No time limit
        case .openRun: return 0 // No time limit
        case .pomodoro: return 25 * 60 // 25 minutes
        case .sprint: return 15 * 60 // 15 minutes
        case .deepWork: return 90 * 60 // 90 minutes
        case .marathon: return 120 * 60 // 120 minutes
        }
    }

    /// Break duration in seconds
    public var breakDuration: TimeInterval {
        switch self {
        case .freeWrite: return 0
        case .openRun: return 0
        case .pomodoro: return 5 * 60 // 5 minutes
        case .sprint: return 3 * 60 // 3 minutes
        case .deepWork: return 15 * 60 // 15 minutes
        case .marathon: return 20 * 60 // 20 minutes
        }
    }
}

/// State of a focus session
public enum FocusSessionState: String, Codable {
    case notStarted = "not_started"
    case active = "active"
    case paused = "paused"
    case onBreak = "on_break"
    case completed = "completed"
    case cancelled = "cancelled"
}

/// Represents a focused writing session
public struct FocusSession: Codable, Identifiable {
    public let id: UUID
    public let type: FocusSessionType
    public var state: FocusSessionState
    public let documentId: UUID?
    public let startTime: Date
    public var endTime: Date?
    public var pausedTime: TimeInterval
    public var targetDuration: TimeInterval
    public var wordsAtStart: Int
    public var wordsAtEnd: Int?
    public var completedPomodoros: Int
    public var notes: String

    public init(
        id: UUID = UUID(),
        type: FocusSessionType,
        state: FocusSessionState = .notStarted,
        documentId: UUID? = nil,
        startTime: Date = Date(),
        endTime: Date? = nil,
        pausedTime: TimeInterval = 0,
        targetDuration: TimeInterval? = nil,
        wordsAtStart: Int = 0,
        wordsAtEnd: Int? = nil,
        completedPomodoros: Int = 0,
        notes: String = ""
    ) {
        self.id = id
        self.type = type
        self.state = state
        self.documentId = documentId
        self.startTime = startTime
        self.endTime = endTime
        self.pausedTime = pausedTime
        self.targetDuration = targetDuration ?? type.defaultDuration
        self.wordsAtStart = wordsAtStart
        self.wordsAtEnd = wordsAtEnd
        self.completedPomodoros = completedPomodoros
        self.notes = notes
    }

    /// Actual duration of the session (excluding paused time)
    public var actualDuration: TimeInterval {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime) - pausedTime
    }

    /// Words written during this session
    public var wordsWritten: Int {
        guard let endWords = wordsAtEnd else { return 0 }
        return max(0, endWords - wordsAtStart)
    }

    /// Words per minute during this session
    public var wordsPerMinute: Double {
        let minutes = actualDuration / 60
        guard minutes > 0 else { return 0 }
        return Double(wordsWritten) / minutes
    }

    /// Time remaining in the session (for timed sessions)
    public var timeRemaining: TimeInterval {
        guard targetDuration > 0 else { return 0 }
        return max(0, targetDuration - actualDuration)
    }

    /// Whether the session has reached its target duration
    public var isTargetReached: Bool {
        guard targetDuration > 0 else { return false }
        return actualDuration >= targetDuration
    }

    /// Progress percentage (0.0 to 1.0)
    public var progress: Double {
        guard targetDuration > 0 else { return 0 }
        return min(1.0, actualDuration / targetDuration)
    }
}

/// Statistics for focus sessions
public struct FocusSessionStats: Codable {
    public var totalSessions: Int
    public var completedSessions: Int
    public var totalFocusTime: TimeInterval
    public var totalWordsWritten: Int
    public var averageWordsPerMinute: Double
    public var longestStreak: Int
    public var currentStreak: Int
    public var pomodorosCompleted: Int
    public var favoriteSessionType: FocusSessionType?

    public init(
        totalSessions: Int = 0,
        completedSessions: Int = 0,
        totalFocusTime: TimeInterval = 0,
        totalWordsWritten: Int = 0,
        averageWordsPerMinute: Double = 0,
        longestStreak: Int = 0,
        currentStreak: Int = 0,
        pomodorosCompleted: Int = 0,
        favoriteSessionType: FocusSessionType? = nil
    ) {
        self.totalSessions = totalSessions
        self.completedSessions = completedSessions
        self.totalFocusTime = totalFocusTime
        self.totalWordsWritten = totalWordsWritten
        self.averageWordsPerMinute = averageWordsPerMinute
        self.longestStreak = longestStreak
        self.currentStreak = currentStreak
        self.pomodorosCompleted = pomodorosCompleted
        self.favoriteSessionType = favoriteSessionType
    }

    /// Completion rate as percentage
    public var completionRate: Double {
        guard totalSessions > 0 else { return 0 }
        return Double(completedSessions) / Double(totalSessions) * 100
    }

    /// Average session duration in minutes
    public var averageSessionDuration: Double {
        guard completedSessions > 0 else { return 0 }
        return (totalFocusTime / 60) / Double(completedSessions)
    }
}
