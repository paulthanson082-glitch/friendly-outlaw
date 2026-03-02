import Foundation

// MARK: - Writing Goals Manager

/// Manages writing goals, streaks, achievements, and gamification features
public class WritingGoalsManager {

    // MARK: - Properties

    public private(set) var currentStreak: WritingStreak
    public private(set) var lifetimeStats: LifetimeWritingStats
    public private(set) var achievements: [Achievement]
    public private(set) var dailyProgress: DailyProgress
    public private(set) var activeGoals: [WritingGoal]
    public private(set) var completedGoals: [WritingGoal]

    public var configuration: GoalsConfiguration

    private var goalHandlers: [(GoalEvent) -> Void] = []

    // MARK: - Initialization

    public init(configuration: GoalsConfiguration = GoalsConfiguration()) {
        self.configuration = configuration
        self.currentStreak = WritingStreak()
        self.lifetimeStats = LifetimeWritingStats()
        self.achievements = []
        self.dailyProgress = DailyProgress(date: Date())
        self.activeGoals = []
        self.completedGoals = []

        setupDefaultAchievements()
    }

    // MARK: - Daily Goals

    /// Set daily word count goal
    public func setDailyGoal(wordCount: Int) {
        dailyProgress.wordCountGoal = wordCount
    }

    /// Set daily writing time goal
    public func setDailyTimeGoal(minutes: Int) {
        dailyProgress.timeGoalMinutes = minutes
    }

    /// Log words written
    public func logWordsWritten(_ count: Int, documentId: UUID) {
        dailyProgress.wordsWritten += count
        lifetimeStats.totalWordsWritten += count

        checkDailyGoalCompletion()
        checkAchievements()
        notifyEvent(.progressUpdated(dailyProgress))
    }

    /// Log writing session
    public func logWritingSession(_ session: WritingSessionLog) {
        dailyProgress.sessionsToday += 1
        dailyProgress.minutesWritten += Int(session.duration / 60)
        lifetimeStats.totalSessions += 1
        lifetimeStats.totalMinutesWritten += Int(session.duration / 60)

        updateStreak()
        checkDailyGoalCompletion()
        checkAchievements()
    }

    private func checkDailyGoalCompletion() {
        var goalsCompleted: [GoalType] = []

        if let wordGoal = dailyProgress.wordCountGoal,
           dailyProgress.wordsWritten >= wordGoal,
           !dailyProgress.wordGoalCompleted {
            dailyProgress.wordGoalCompleted = true
            goalsCompleted.append(.dailyWordCount)
        }

        if let timeGoal = dailyProgress.timeGoalMinutes,
           dailyProgress.minutesWritten >= timeGoal,
           !dailyProgress.timeGoalCompleted {
            dailyProgress.timeGoalCompleted = true
            goalsCompleted.append(.dailyWritingTime)
        }

        for goalType in goalsCompleted {
            notifyEvent(.goalCompleted(goalType))
        }
    }

    // MARK: - Streaks

    /// Update writing streak
    private func updateStreak() {
        let today = Calendar.current.startOfDay(for: Date())

        if let lastWritingDay = currentStreak.lastWritingDate {
            let daysSinceLastWrite = Calendar.current.dateComponents(
                [.day],
                from: Calendar.current.startOfDay(for: lastWritingDay),
                to: today
            ).day ?? 0

            if daysSinceLastWrite == 0 {
                // Already wrote today, no change
                return
            } else if daysSinceLastWrite == 1 {
                // Consecutive day, extend streak
                currentStreak.currentDays += 1
                currentStreak.lastWritingDate = today

                if currentStreak.currentDays > currentStreak.longestStreak {
                    currentStreak.longestStreak = currentStreak.currentDays
                    notifyEvent(.newStreakRecord(currentStreak.longestStreak))
                }

                notifyEvent(.streakContinued(currentStreak.currentDays))
            } else {
                // Streak broken
                let lostStreak = currentStreak.currentDays
                currentStreak.currentDays = 1
                currentStreak.lastWritingDate = today

                if lostStreak > 0 {
                    notifyEvent(.streakBroken(lostStreak))
                }
            }
        } else {
            // First writing day
            currentStreak.currentDays = 1
            currentStreak.lastWritingDate = today
            notifyEvent(.streakStarted)
        }
    }

    /// Check if streak is at risk
    public func getStreakStatus() -> StreakStatus {
        guard let lastWrite = currentStreak.lastWritingDate else {
            return .noStreak
        }

        let hoursSinceLastWrite = Date().timeIntervalSince(lastWrite) / 3600

        if Calendar.current.isDateInToday(lastWrite) {
            return .safe(currentStreak.currentDays)
        } else if hoursSinceLastWrite < 24 {
            let hoursRemaining = 24 - hoursSinceLastWrite
            return .atRisk(currentStreak.currentDays, hoursRemaining: hoursRemaining)
        } else if hoursSinceLastWrite < 48 {
            return .critical(currentStreak.currentDays)
        } else {
            return .broken
        }
    }

    // MARK: - Custom Goals

    /// Create a custom writing goal
    public func createGoal(_ goal: WritingGoal) {
        activeGoals.append(goal)
        notifyEvent(.goalCreated(goal))
    }

    /// Update progress on a goal
    public func updateGoalProgress(goalId: UUID, progress: Int) {
        guard let index = activeGoals.firstIndex(where: { $0.id == goalId }) else { return }

        activeGoals[index].currentProgress = progress

        if activeGoals[index].currentProgress >= activeGoals[index].targetValue {
            completeGoal(goalId: goalId)
        }
    }

    /// Complete a goal
    public func completeGoal(goalId: UUID) {
        guard let index = activeGoals.firstIndex(where: { $0.id == goalId }) else { return }

        var goal = activeGoals.remove(at: index)
        goal.completedDate = Date()
        goal.isCompleted = true
        completedGoals.append(goal)

        notifyEvent(.goalCompleted(goal.type))
        awardPointsForGoal(goal)
    }

    // MARK: - Achievements

    private func setupDefaultAchievements() {
        achievements = [
            // Word count achievements
            Achievement(id: "words_1k", name: "First Steps", description: "Write 1,000 words", icon: "pencil", category: .wordCount, requirement: 1000, reward: 10),
            Achievement(id: "words_10k", name: "Getting Started", description: "Write 10,000 words", icon: "doc.text", category: .wordCount, requirement: 10000, reward: 50),
            Achievement(id: "words_50k", name: "NaNoWriMo", description: "Write 50,000 words", icon: "book.closed", category: .wordCount, requirement: 50000, reward: 200),
            Achievement(id: "words_100k", name: "Prolific Writer", description: "Write 100,000 words", icon: "books.vertical", category: .wordCount, requirement: 100000, reward: 500),

            // Streak achievements
            Achievement(id: "streak_7", name: "Week Warrior", description: "Maintain a 7-day writing streak", icon: "flame", category: .streak, requirement: 7, reward: 25),
            Achievement(id: "streak_30", name: "Monthly Master", description: "Maintain a 30-day writing streak", icon: "flame.fill", category: .streak, requirement: 30, reward: 100),
            Achievement(id: "streak_100", name: "Century Writer", description: "Maintain a 100-day writing streak", icon: "star.fill", category: .streak, requirement: 100, reward: 500),
            Achievement(id: "streak_365", name: "Year of Writing", description: "Maintain a 365-day writing streak", icon: "crown", category: .streak, requirement: 365, reward: 2000),

            // Session achievements
            Achievement(id: "sessions_10", name: "Regular Writer", description: "Complete 10 writing sessions", icon: "clock", category: .sessions, requirement: 10, reward: 15),
            Achievement(id: "sessions_100", name: "Dedicated Author", description: "Complete 100 writing sessions", icon: "clock.fill", category: .sessions, requirement: 100, reward: 150),

            // Time achievements
            Achievement(id: "time_1h", name: "Hour of Power", description: "Write for 1 hour total", icon: "timer", category: .time, requirement: 60, reward: 10),
            Achievement(id: "time_10h", name: "Time Invested", description: "Write for 10 hours total", icon: "hourglass", category: .time, requirement: 600, reward: 50),
            Achievement(id: "time_100h", name: "Committed Writer", description: "Write for 100 hours total", icon: "hourglass.bottomhalf.filled", category: .time, requirement: 6000, reward: 300),

            // Daily goal achievements
            Achievement(id: "daily_7", name: "Goal Getter", description: "Meet your daily goal 7 days in a row", icon: "checkmark.circle", category: .dailyGoals, requirement: 7, reward: 30),
            Achievement(id: "daily_30", name: "Consistent Achiever", description: "Meet your daily goal 30 days in a row", icon: "checkmark.circle.fill", category: .dailyGoals, requirement: 30, reward: 150),

            // AI usage achievements
            Achievement(id: "ai_first", name: "AI Explorer", description: "Use AI assistance for the first time", icon: "sparkles", category: .aiUsage, requirement: 1, reward: 5),
            Achievement(id: "ai_10", name: "AI Collaborator", description: "Use AI assistance 10 times", icon: "wand.and.stars", category: .aiUsage, requirement: 10, reward: 25),

            // Document achievements
            Achievement(id: "docs_5", name: "Multi-Project", description: "Create 5 documents", icon: "doc.badge.plus", category: .documents, requirement: 5, reward: 15),
            Achievement(id: "docs_25", name: "Portfolio Builder", description: "Create 25 documents", icon: "folder.fill", category: .documents, requirement: 25, reward: 75),

            // Special achievements
            Achievement(id: "night_owl", name: "Night Owl", description: "Write after midnight", icon: "moon.stars", category: .special, requirement: 1, reward: 10),
            Achievement(id: "early_bird", name: "Early Bird", description: "Write before 6 AM", icon: "sunrise", category: .special, requirement: 1, reward: 10),
            Achievement(id: "weekend_warrior", name: "Weekend Warrior", description: "Write on both Saturday and Sunday", icon: "calendar", category: .special, requirement: 1, reward: 15),
        ]
    }

    private func checkAchievements() {
        for i in 0..<achievements.count {
            guard !achievements[i].isUnlocked else { continue }

            var shouldUnlock = false

            switch achievements[i].category {
            case .wordCount:
                shouldUnlock = lifetimeStats.totalWordsWritten >= achievements[i].requirement

            case .streak:
                shouldUnlock = currentStreak.longestStreak >= achievements[i].requirement

            case .sessions:
                shouldUnlock = lifetimeStats.totalSessions >= achievements[i].requirement

            case .time:
                shouldUnlock = lifetimeStats.totalMinutesWritten >= achievements[i].requirement

            case .dailyGoals:
                shouldUnlock = lifetimeStats.consecutiveDailyGoals >= achievements[i].requirement

            case .aiUsage:
                shouldUnlock = lifetimeStats.aiAssistanceUsed >= achievements[i].requirement

            case .documents:
                shouldUnlock = lifetimeStats.documentsCreated >= achievements[i].requirement

            case .special:
                // Special achievements are checked elsewhere
                break
            }

            if shouldUnlock {
                unlockAchievement(index: i)
            }
        }
    }

    private func unlockAchievement(index: Int) {
        achievements[index].isUnlocked = true
        achievements[index].unlockedDate = Date()
        lifetimeStats.totalPoints += achievements[index].reward

        notifyEvent(.achievementUnlocked(achievements[index]))
    }

    /// Check for time-based special achievements
    public func checkTimeBasedAchievements() {
        let hour = Calendar.current.component(.hour, from: Date())

        // Night Owl (after midnight, before 5 AM)
        if hour >= 0 && hour < 5 {
            if let index = achievements.firstIndex(where: { $0.id == "night_owl" && !$0.isUnlocked }) {
                unlockAchievement(index: index)
            }
        }

        // Early Bird (5 AM to 6 AM)
        if hour >= 5 && hour < 6 {
            if let index = achievements.firstIndex(where: { $0.id == "early_bird" && !$0.isUnlocked }) {
                unlockAchievement(index: index)
            }
        }
    }

    // MARK: - Points & Rewards

    private func awardPointsForGoal(_ goal: WritingGoal) {
        let points = goal.difficulty.pointValue
        lifetimeStats.totalPoints += points
        notifyEvent(.pointsAwarded(points))
    }

    /// Get current level based on points
    public func getCurrentLevel() -> WriterLevel {
        let points = lifetimeStats.totalPoints

        if points < 100 { return WriterLevel(level: 1, title: "Novice Writer", pointsForNext: 100 - points) }
        if points < 300 { return WriterLevel(level: 2, title: "Aspiring Author", pointsForNext: 300 - points) }
        if points < 600 { return WriterLevel(level: 3, title: "Dedicated Scribe", pointsForNext: 600 - points) }
        if points < 1000 { return WriterLevel(level: 4, title: "Skilled Wordsmith", pointsForNext: 1000 - points) }
        if points < 1500 { return WriterLevel(level: 5, title: "Prolific Penman", pointsForNext: 1500 - points) }
        if points < 2500 { return WriterLevel(level: 6, title: "Master Writer", pointsForNext: 2500 - points) }
        if points < 4000 { return WriterLevel(level: 7, title: "Literary Expert", pointsForNext: 4000 - points) }
        if points < 6000 { return WriterLevel(level: 8, title: "Renowned Author", pointsForNext: 6000 - points) }
        if points < 10000 { return WriterLevel(level: 9, title: "Legendary Writer", pointsForNext: 10000 - points) }
        return WriterLevel(level: 10, title: "Writing Legend", pointsForNext: 0)
    }

    // MARK: - Statistics

    /// Get writing statistics for a time period
    public func getStatistics(for period: StatisticsPeriod) -> WritingStatistics {
        WritingStatistics(
            period: period,
            wordsWritten: getWordsForPeriod(period),
            sessionsCompleted: getSessionsForPeriod(period),
            minutesWritten: getMinutesForPeriod(period),
            averageWordsPerSession: calculateAverageWords(period),
            goalsCompleted: getGoalsCompletedForPeriod(period),
            currentStreak: currentStreak.currentDays,
            longestStreak: currentStreak.longestStreak
        )
    }

    private func getWordsForPeriod(_ period: StatisticsPeriod) -> Int {
        // Would calculate from stored data
        switch period {
        case .today: return dailyProgress.wordsWritten
        case .thisWeek: return dailyProgress.wordsWritten * 5 // Placeholder
        case .thisMonth: return dailyProgress.wordsWritten * 20
        case .thisYear: return lifetimeStats.totalWordsWritten
        case .allTime: return lifetimeStats.totalWordsWritten
        }
    }

    private func getSessionsForPeriod(_ period: StatisticsPeriod) -> Int {
        switch period {
        case .today: return dailyProgress.sessionsToday
        case .thisWeek: return dailyProgress.sessionsToday * 5
        case .thisMonth: return dailyProgress.sessionsToday * 20
        case .thisYear, .allTime: return lifetimeStats.totalSessions
        }
    }

    private func getMinutesForPeriod(_ period: StatisticsPeriod) -> Int {
        switch period {
        case .today: return dailyProgress.minutesWritten
        case .thisWeek: return dailyProgress.minutesWritten * 5
        case .thisMonth: return dailyProgress.minutesWritten * 20
        case .thisYear, .allTime: return lifetimeStats.totalMinutesWritten
        }
    }

    private func calculateAverageWords(_ period: StatisticsPeriod) -> Int {
        let sessions = getSessionsForPeriod(period)
        guard sessions > 0 else { return 0 }
        return getWordsForPeriod(period) / sessions
    }

    private func getGoalsCompletedForPeriod(_ period: StatisticsPeriod) -> Int {
        // Would calculate from stored data
        return 0
    }

    // MARK: - Event Handlers

    public func onGoalEvent(_ handler: @escaping (GoalEvent) -> Void) {
        goalHandlers.append(handler)
    }

    private func notifyEvent(_ event: GoalEvent) {
        for handler in goalHandlers {
            handler(event)
        }
    }
}

// MARK: - Goals Configuration

public struct GoalsConfiguration: Codable {
    public var defaultDailyWordGoal: Int
    public var defaultDailyTimeGoal: Int
    public var enableNotifications: Bool
    public var streakReminderTime: Date?
    public var showProgressInStatusBar: Bool

    public init(
        defaultDailyWordGoal: Int = 500,
        defaultDailyTimeGoal: Int = 30,
        enableNotifications: Bool = true,
        streakReminderTime: Date? = nil,
        showProgressInStatusBar: Bool = true
    ) {
        self.defaultDailyWordGoal = defaultDailyWordGoal
        self.defaultDailyTimeGoal = defaultDailyTimeGoal
        self.enableNotifications = enableNotifications
        self.streakReminderTime = streakReminderTime
        self.showProgressInStatusBar = showProgressInStatusBar
    }
}

// MARK: - Writing Streak

public struct WritingStreak: Codable {
    public var currentDays: Int
    public var longestStreak: Int
    public var lastWritingDate: Date?
    public var streakStartDate: Date?

    public init(
        currentDays: Int = 0,
        longestStreak: Int = 0,
        lastWritingDate: Date? = nil,
        streakStartDate: Date? = nil
    ) {
        self.currentDays = currentDays
        self.longestStreak = longestStreak
        self.lastWritingDate = lastWritingDate
        self.streakStartDate = streakStartDate
    }
}

public enum StreakStatus {
    case noStreak
    case safe(Int)
    case atRisk(Int, hoursRemaining: Double)
    case critical(Int)
    case broken
}

// MARK: - Lifetime Stats

public struct LifetimeWritingStats: Codable {
    public var totalWordsWritten: Int
    public var totalSessions: Int
    public var totalMinutesWritten: Int
    public var totalPoints: Int
    public var consecutiveDailyGoals: Int
    public var aiAssistanceUsed: Int
    public var documentsCreated: Int

    public init(
        totalWordsWritten: Int = 0,
        totalSessions: Int = 0,
        totalMinutesWritten: Int = 0,
        totalPoints: Int = 0,
        consecutiveDailyGoals: Int = 0,
        aiAssistanceUsed: Int = 0,
        documentsCreated: Int = 0
    ) {
        self.totalWordsWritten = totalWordsWritten
        self.totalSessions = totalSessions
        self.totalMinutesWritten = totalMinutesWritten
        self.totalPoints = totalPoints
        self.consecutiveDailyGoals = consecutiveDailyGoals
        self.aiAssistanceUsed = aiAssistanceUsed
        self.documentsCreated = documentsCreated
    }
}

// MARK: - Daily Progress

public struct DailyProgress: Codable {
    public let date: Date
    public var wordsWritten: Int
    public var wordCountGoal: Int?
    public var wordGoalCompleted: Bool
    public var minutesWritten: Int
    public var timeGoalMinutes: Int?
    public var timeGoalCompleted: Bool
    public var sessionsToday: Int

    public init(
        date: Date,
        wordsWritten: Int = 0,
        wordCountGoal: Int? = nil,
        wordGoalCompleted: Bool = false,
        minutesWritten: Int = 0,
        timeGoalMinutes: Int? = nil,
        timeGoalCompleted: Bool = false,
        sessionsToday: Int = 0
    ) {
        self.date = date
        self.wordsWritten = wordsWritten
        self.wordCountGoal = wordCountGoal
        self.wordGoalCompleted = wordGoalCompleted
        self.minutesWritten = minutesWritten
        self.timeGoalMinutes = timeGoalMinutes
        self.timeGoalCompleted = timeGoalCompleted
        self.sessionsToday = sessionsToday
    }

    public var wordGoalProgress: Double {
        guard let goal = wordCountGoal, goal > 0 else { return 0 }
        return min(Double(wordsWritten) / Double(goal), 1.0)
    }

    public var timeGoalProgress: Double {
        guard let goal = timeGoalMinutes, goal > 0 else { return 0 }
        return min(Double(minutesWritten) / Double(goal), 1.0)
    }
}

// MARK: - Writing Goal

public struct WritingGoal: Codable, Identifiable {
    public let id: UUID
    public var name: String
    public var type: GoalType
    public var targetValue: Int
    public var currentProgress: Int
    public var deadline: Date?
    public var difficulty: GoalDifficulty
    public var isCompleted: Bool
    public var completedDate: Date?
    public var createdDate: Date

    public init(
        id: UUID = UUID(),
        name: String,
        type: GoalType,
        targetValue: Int,
        currentProgress: Int = 0,
        deadline: Date? = nil,
        difficulty: GoalDifficulty = .medium,
        isCompleted: Bool = false,
        completedDate: Date? = nil,
        createdDate: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.targetValue = targetValue
        self.currentProgress = currentProgress
        self.deadline = deadline
        self.difficulty = difficulty
        self.isCompleted = isCompleted
        self.completedDate = completedDate
        self.createdDate = createdDate
    }

    public var progress: Double {
        guard targetValue > 0 else { return 0 }
        return min(Double(currentProgress) / Double(targetValue), 1.0)
    }
}

public enum GoalType: String, Codable {
    case dailyWordCount
    case dailyWritingTime
    case weeklyWordCount
    case monthlyWordCount
    case projectWordCount
    case streak
    case custom
}

public enum GoalDifficulty: String, Codable {
    case easy
    case medium
    case hard
    case extreme

    var pointValue: Int {
        switch self {
        case .easy: return 10
        case .medium: return 25
        case .hard: return 50
        case .extreme: return 100
        }
    }
}

// MARK: - Achievement

public struct Achievement: Codable, Identifiable {
    public let id: String
    public let name: String
    public let description: String
    public let icon: String
    public let category: AchievementCategory
    public let requirement: Int
    public let reward: Int
    public var isUnlocked: Bool
    public var unlockedDate: Date?

    public init(
        id: String,
        name: String,
        description: String,
        icon: String,
        category: AchievementCategory,
        requirement: Int,
        reward: Int,
        isUnlocked: Bool = false,
        unlockedDate: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.icon = icon
        self.category = category
        self.requirement = requirement
        self.reward = reward
        self.isUnlocked = isUnlocked
        self.unlockedDate = unlockedDate
    }
}

public enum AchievementCategory: String, Codable {
    case wordCount
    case streak
    case sessions
    case time
    case dailyGoals
    case aiUsage
    case documents
    case special
}

// MARK: - Writer Level

public struct WriterLevel {
    public let level: Int
    public let title: String
    public let pointsForNext: Int
}

// MARK: - Writing Statistics

public struct WritingStatistics {
    public let period: StatisticsPeriod
    public let wordsWritten: Int
    public let sessionsCompleted: Int
    public let minutesWritten: Int
    public let averageWordsPerSession: Int
    public let goalsCompleted: Int
    public let currentStreak: Int
    public let longestStreak: Int
}

public enum StatisticsPeriod: String, Codable {
    case today
    case thisWeek
    case thisMonth
    case thisYear
    case allTime
}

// MARK: - Writing Session Log

public struct WritingSessionLog: Codable {
    public let documentId: UUID
    public let startTime: Date
    public let endTime: Date
    public let wordsWritten: Int
    public let wordsDeleted: Int

    public var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }

    public var netWords: Int {
        wordsWritten - wordsDeleted
    }

    public init(
        documentId: UUID,
        startTime: Date,
        endTime: Date,
        wordsWritten: Int,
        wordsDeleted: Int
    ) {
        self.documentId = documentId
        self.startTime = startTime
        self.endTime = endTime
        self.wordsWritten = wordsWritten
        self.wordsDeleted = wordsDeleted
    }
}

// MARK: - Goal Events

public enum GoalEvent {
    case progressUpdated(DailyProgress)
    case goalCompleted(GoalType)
    case goalCreated(WritingGoal)
    case achievementUnlocked(Achievement)
    case streakStarted
    case streakContinued(Int)
    case streakBroken(Int)
    case newStreakRecord(Int)
    case pointsAwarded(Int)
    case levelUp(WriterLevel)
}
