import Foundation

/// Type of writing goal
public enum GoalType: String, Codable, CaseIterable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case project = "project"
    case custom = "custom"

    public var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .project: return "Project"
        case .custom: return "Custom"
        }
    }
}

/// Unit for measuring goal progress
public enum GoalUnit: String, Codable, CaseIterable {
    case words = "words"
    case pages = "pages"
    case minutes = "minutes"
    case sessions = "sessions"
    case chapters = "chapters"

    public var displayName: String {
        switch self {
        case .words: return "Words"
        case .pages: return "Pages"
        case .minutes: return "Minutes"
        case .sessions: return "Sessions"
        case .chapters: return "Chapters"
        }
    }

    /// Default words per page (for conversion)
    public static let wordsPerPage: Int = 250
}

/// Represents a writing goal
public struct WritingGoal: Codable, Identifiable {
    public let id: UUID
    public var name: String
    public var type: GoalType
    public var unit: GoalUnit
    public var target: Int
    public var current: Int
    public var documentId: UUID?
    public var startDate: Date
    public var endDate: Date?
    public var isActive: Bool
    public var reminderEnabled: Bool
    public var reminderTime: Date?
    public var notes: String

    public init(
        id: UUID = UUID(),
        name: String,
        type: GoalType,
        unit: GoalUnit = .words,
        target: Int,
        current: Int = 0,
        documentId: UUID? = nil,
        startDate: Date = Date(),
        endDate: Date? = nil,
        isActive: Bool = true,
        reminderEnabled: Bool = false,
        reminderTime: Date? = nil,
        notes: String = ""
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.unit = unit
        self.target = target
        self.current = current
        self.documentId = documentId
        self.startDate = startDate
        self.endDate = endDate
        self.isActive = isActive
        self.reminderEnabled = reminderEnabled
        self.reminderTime = reminderTime
        self.notes = notes
    }

    /// Progress as a percentage (0.0 to 1.0)
    public var progress: Double {
        guard target > 0 else { return 0 }
        return min(1.0, Double(current) / Double(target))
    }

    /// Progress as a percentage (0 to 100)
    public var progressPercentage: Int {
        return Int(progress * 100)
    }

    /// Whether the goal has been achieved
    public var isAchieved: Bool {
        return current >= target
    }

    /// Remaining amount to reach goal
    public var remaining: Int {
        return max(0, target - current)
    }

    /// Whether the goal is still within its time window
    public var isWithinTimeWindow: Bool {
        let now = Date()
        if let end = endDate {
            return now >= startDate && now <= end
        }
        return now >= startDate
    }

    /// Days until deadline (nil if no end date)
    public var daysRemaining: Int? {
        guard let end = endDate else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: end)
        return components.day
    }

    /// Required daily progress to meet goal
    public var requiredDailyProgress: Int? {
        guard let days = daysRemaining, days > 0 else { return nil }
        return Int(ceil(Double(remaining) / Double(days)))
    }
}

/// Progress entry for tracking goal progress over time
public struct GoalProgressEntry: Codable, Identifiable {
    public let id: UUID
    public let goalId: UUID
    public let date: Date
    public let amount: Int
    public let notes: String

    public init(
        id: UUID = UUID(),
        goalId: UUID,
        date: Date = Date(),
        amount: Int,
        notes: String = ""
    ) {
        self.id = id
        self.goalId = goalId
        self.date = date
        self.amount = amount
        self.notes = notes
    }
}

/// Writing streak information
public struct WritingStreak: Codable {
    public var currentStreak: Int
    public var longestStreak: Int
    public var lastWritingDate: Date?
    public var streakStartDate: Date?
    public var totalDaysWritten: Int

    public init(
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        lastWritingDate: Date? = nil,
        streakStartDate: Date? = nil,
        totalDaysWritten: Int = 0
    ) {
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastWritingDate = lastWritingDate
        self.streakStartDate = streakStartDate
        self.totalDaysWritten = totalDaysWritten
    }

    /// Whether the streak is still active (wrote yesterday or today)
    public var isStreakActive: Bool {
        guard let last = lastWritingDate else { return false }
        let calendar = Calendar.current
        return calendar.isDateInToday(last) || calendar.isDateInYesterday(last)
    }

    /// Whether the user has written today
    public var wroteToday: Bool {
        guard let last = lastWritingDate else { return false }
        return Calendar.current.isDateInToday(last)
    }
}

/// Summary of all goals
public struct GoalsSummary: Codable {
    public var activeGoals: Int
    public var achievedGoals: Int
    public var totalGoals: Int
    public var overallProgress: Double
    public var streak: WritingStreak

    public init(
        activeGoals: Int = 0,
        achievedGoals: Int = 0,
        totalGoals: Int = 0,
        overallProgress: Double = 0,
        streak: WritingStreak = WritingStreak()
    ) {
        self.activeGoals = activeGoals
        self.achievedGoals = achievedGoals
        self.totalGoals = totalGoals
        self.overallProgress = overallProgress
        self.streak = streak
    }
}
