import Foundation

/// Time period for analytics
public enum AnalyticsPeriod: String, Codable, CaseIterable {
    case today = "today"
    case yesterday = "yesterday"
    case thisWeek = "this_week"
    case lastWeek = "last_week"
    case thisMonth = "this_month"
    case lastMonth = "last_month"
    case allTime = "all_time"
    case custom = "custom"

    public var displayName: String {
        switch self {
        case .today: return "Today"
        case .yesterday: return "Yesterday"
        case .thisWeek: return "This Week"
        case .lastWeek: return "Last Week"
        case .thisMonth: return "This Month"
        case .lastMonth: return "Last Month"
        case .allTime: return "All Time"
        case .custom: return "Custom Range"
        }
    }
}

/// Hourly productivity data
public struct HourlyProductivity: Codable {
    public let hour: Int
    public var wordsWritten: Int
    public var sessionsCount: Int
    public var focusMinutes: Double

    public init(hour: Int, wordsWritten: Int = 0, sessionsCount: Int = 0, focusMinutes: Double = 0) {
        self.hour = hour
        self.wordsWritten = wordsWritten
        self.sessionsCount = sessionsCount
        self.focusMinutes = focusMinutes
    }
}

/// Daily productivity summary
public struct DailyProductivity: Codable {
    public let date: Date
    public var wordsWritten: Int
    public var sessionsCompleted: Int
    public var focusMinutes: Double
    public var goalsAchieved: Int
    public var documentsWorkedOn: Int

    public init(
        date: Date,
        wordsWritten: Int = 0,
        sessionsCompleted: Int = 0,
        focusMinutes: Double = 0,
        goalsAchieved: Int = 0,
        documentsWorkedOn: Int = 0
    ) {
        self.date = date
        self.wordsWritten = wordsWritten
        self.sessionsCompleted = sessionsCompleted
        self.focusMinutes = focusMinutes
        self.goalsAchieved = goalsAchieved
        self.documentsWorkedOn = documentsWorkedOn
    }

    /// Words per minute average
    public var wordsPerMinute: Double {
        guard focusMinutes > 0 else { return 0 }
        return Double(wordsWritten) / focusMinutes
    }
}

/// Comprehensive productivity report
public struct ProductivityReport: Codable {
    public let period: AnalyticsPeriod
    public let startDate: Date
    public let endDate: Date
    public var totalWords: Int
    public var totalSessions: Int
    public var totalFocusMinutes: Double
    public var averageWordsPerDay: Double
    public var averageWordsPerSession: Double
    public var averageSessionLength: Double
    public var peakHour: Int?
    public var mostProductiveDay: Date?
    public var dailyBreakdown: [DailyProductivity]
    public var hourlyBreakdown: [HourlyProductivity]

    public init(
        period: AnalyticsPeriod,
        startDate: Date,
        endDate: Date,
        totalWords: Int = 0,
        totalSessions: Int = 0,
        totalFocusMinutes: Double = 0,
        averageWordsPerDay: Double = 0,
        averageWordsPerSession: Double = 0,
        averageSessionLength: Double = 0,
        peakHour: Int? = nil,
        mostProductiveDay: Date? = nil,
        dailyBreakdown: [DailyProductivity] = [],
        hourlyBreakdown: [HourlyProductivity] = []
    ) {
        self.period = period
        self.startDate = startDate
        self.endDate = endDate
        self.totalWords = totalWords
        self.totalSessions = totalSessions
        self.totalFocusMinutes = totalFocusMinutes
        self.averageWordsPerDay = averageWordsPerDay
        self.averageWordsPerSession = averageWordsPerSession
        self.averageSessionLength = averageSessionLength
        self.peakHour = peakHour
        self.mostProductiveDay = mostProductiveDay
        self.dailyBreakdown = dailyBreakdown
        self.hourlyBreakdown = hourlyBreakdown
    }

    /// Total hours of focus time
    public var totalFocusHours: Double {
        return totalFocusMinutes / 60.0
    }

    /// Average words per minute
    public var averageWordsPerMinute: Double {
        guard totalFocusMinutes > 0 else { return 0 }
        return Double(totalWords) / totalFocusMinutes
    }
}

/// Insights and recommendations based on productivity data
public struct ProductivityInsight: Codable {
    public enum InsightType: String, Codable {
        case peakTime = "peak_time"
        case streak = "streak"
        case improvement = "improvement"
        case goalProgress = "goal_progress"
        case suggestion = "suggestion"
        case warning = "warning"
        case achievement = "achievement"
    }

    public let type: InsightType
    public let title: String
    public let message: String
    public let priority: Int

    public init(type: InsightType, title: String, message: String, priority: Int = 0) {
        self.type = type
        self.title = title
        self.message = message
        self.priority = priority
    }
}

/// Service for generating productivity analytics and insights
public class ProductivityAnalytics {
    private let focusManager: FocusSessionManager
    private let goalManager: WritingGoalManager
    private var wordCountHistory: [(date: Date, documentId: UUID, wordCount: Int)]

    public init(focusManager: FocusSessionManager, goalManager: WritingGoalManager) {
        self.focusManager = focusManager
        self.goalManager = goalManager
        self.wordCountHistory = []
    }

    // MARK: - Data Recording

    /// Records word count for tracking
    public func recordWordCount(documentId: UUID, wordCount: Int) {
        wordCountHistory.append((date: Date(), documentId: documentId, wordCount: wordCount))
    }

    // MARK: - Report Generation

    /// Generates a productivity report for a given period
    public func generateReport(for period: AnalyticsPeriod, customStart: Date? = nil, customEnd: Date? = nil) -> ProductivityReport {
        let (startDate, endDate) = getDateRange(for: period, customStart: customStart, customEnd: customEnd)

        let sessions = focusManager.getAllSessions().filter {
            $0.startTime >= startDate && $0.startTime <= endDate && $0.state == .completed
        }

        // Single-pass calculation
        var totalWords = 0
        var totalFocusMinutes: TimeInterval = 0.0
        
        for session in sessions {
            totalWords += session.wordsWritten
            totalFocusMinutes += session.actualDuration / 60
        }

        let calendar = Calendar.current
        let dayCount = max(1, calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 1)

        let avgWordsPerDay = Double(totalWords) / Double(dayCount)
        let avgWordsPerSession = sessions.isEmpty ? 0 : Double(totalWords) / Double(sessions.count)
        let avgSessionLength = sessions.isEmpty ? 0 : totalFocusMinutes / Double(sessions.count)

        let dailyBreakdown = generateDailyBreakdown(sessions: sessions, from: startDate, to: endDate)
        let hourlyBreakdown = generateHourlyBreakdown(sessions: sessions)

        let peakHour = hourlyBreakdown.max(by: { $0.wordsWritten < $1.wordsWritten })?.hour
        let mostProductiveDay = dailyBreakdown.max(by: { $0.wordsWritten < $1.wordsWritten })?.date

        return ProductivityReport(
            period: period,
            startDate: startDate,
            endDate: endDate,
            totalWords: totalWords,
            totalSessions: sessions.count,
            totalFocusMinutes: totalFocusMinutes,
            averageWordsPerDay: avgWordsPerDay,
            averageWordsPerSession: avgWordsPerSession,
            averageSessionLength: avgSessionLength,
            peakHour: peakHour,
            mostProductiveDay: mostProductiveDay,
            dailyBreakdown: dailyBreakdown,
            hourlyBreakdown: hourlyBreakdown
        )
    }

    /// Generates a quick summary for today
    public func getTodaySummary() -> DailyProductivity {
        let todaySessions = focusManager.getTodaySessions().filter { $0.state == .completed }

        // Single-pass calculation with set for document tracking
        var words = 0
        var focusMinutes: TimeInterval = 0.0
        var documentIds = Set<UUID>()
        
        for session in todaySessions {
            words += session.wordsWritten
            focusMinutes += session.actualDuration / 60
            if let docId = session.documentId {
                documentIds.insert(docId)
            }
        }

        let todayGoals = goalManager.getDailyGoals()
        let achievedGoals = todayGoals.filter { $0.isAchieved }.count

        return DailyProductivity(
            date: Date(),
            wordsWritten: words,
            sessionsCompleted: todaySessions.count,
            focusMinutes: focusMinutes,
            goalsAchieved: achievedGoals,
            documentsWorkedOn: documentIds.count
        )
    }

    // MARK: - Insights Generation

    /// Generates productivity insights and recommendations
    public func generateInsights() -> [ProductivityInsight] {
        var insights: [ProductivityInsight] = []

        // Peak time insight
        let weekReport = generateReport(for: .thisWeek)
        if let peakHour = weekReport.peakHour {
            let timeString = formatHour(peakHour)
            insights.append(ProductivityInsight(
                type: .peakTime,
                title: "Peak Writing Time",
                message: "You're most productive around \(timeString). Consider scheduling important writing sessions then.",
                priority: 1
            ))
        }

        // Streak insight
        let streak = goalManager.getStreak()
        if let streakInsight = makeStreakInsight(streak: streak) {
            insights.append(streakInsight)
        }

        // Goal progress insight
        let goalsNeedingAttention = goalManager.getGoalsNeedingAttention()
        if !goalsNeedingAttention.isEmpty {
            let goal = goalsNeedingAttention[0]
            insights.append(ProductivityInsight(
                type: .warning,
                title: "Goal Behind Schedule",
                message: "\"\(goal.name)\" is at \(goal.progressPercentage)%. Write \(goal.requiredDailyProgress ?? goal.remaining) \(goal.unit.displayName.lowercased()) daily to catch up.",
                priority: 0
            ))
        }

        // Improvement suggestion based on session length
        let focusStats = focusManager.getStats()
        if focusStats.averageSessionDuration < 15 && focusStats.completedSessions > 3 {
            insights.append(ProductivityInsight(
                type: .suggestion,
                title: "Try Longer Sessions",
                message: "Your average session is \(Int(focusStats.averageSessionDuration)) minutes. Try 25-minute Pomodoro sessions for deeper focus.",
                priority: 2
            ))
        }

        // Words per minute insight
        if focusStats.averageWordsPerMinute > 0 {
            let wpm = Int(focusStats.averageWordsPerMinute)
            if wpm >= 30 {
                insights.append(ProductivityInsight(
                    type: .achievement,
                    title: "Fast Writer!",
                    message: "Your average writing speed is \(wpm) words/minute. That's impressive!",
                    priority: 2
                ))
            }
        }

        // Suggest writing if haven't written today
        if !streak.wroteToday && streak.currentStreak > 0 {
            insights.append(ProductivityInsight(
                type: .suggestion,
                title: "Don't Break Your Streak!",
                message: "You haven't written today. A quick 15-minute session will keep your \(streak.currentStreak)-day streak alive.",
                priority: 0
            ))
        }

        return insights.sorted { $0.priority < $1.priority }
    }

    // MARK: - Comparison Analytics

    /// Compares productivity between two periods
    public func comparePeriods(current: AnalyticsPeriod, previous: AnalyticsPeriod) -> (current: ProductivityReport, previous: ProductivityReport, improvement: Double) {
        let currentReport = generateReport(for: current)
        let previousReport = generateReport(for: previous)

        let improvement: Double
        if previousReport.totalWords > 0 {
            improvement = (Double(currentReport.totalWords - previousReport.totalWords) / Double(previousReport.totalWords)) * 100
        } else if currentReport.totalWords > 0 {
            improvement = 100
        } else {
            improvement = 0
        }

        return (currentReport, previousReport, improvement)
    }

    // MARK: - Private Helpers

    private func getDateRange(for period: AnalyticsPeriod, customStart: Date?, customEnd: Date?) -> (Date, Date) {
        let calendar = Calendar.current
        let now = Date()

        switch period {
        case .today:
            let start = calendar.startOfDay(for: now)
            return (start, now)

        case .yesterday:
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: now) else {
                return (now, now)
            }
            let start = calendar.startOfDay(for: yesterday)
            let end = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: yesterday) ?? yesterday
            return (start, end)

        case .thisWeek:
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
            let start = calendar.date(from: components) ?? now
            return (start, now)

        case .lastWeek:
            guard let lastWeekDate = calendar.date(byAdding: .weekOfYear, value: -1, to: now) else {
                return (now, now)
            }
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: lastWeekDate)
            let start = calendar.date(from: components) ?? lastWeekDate
            guard let end = calendar.date(byAdding: .day, value: 6, to: start) else {
                return (start, start)
            }
            return (start, end)

        case .thisMonth:
            let components = calendar.dateComponents([.year, .month], from: now)
            let start = calendar.date(from: components) ?? now
            return (start, now)

        case .lastMonth:
            guard let lastMonthDate = calendar.date(byAdding: .month, value: -1, to: now) else {
                return (now, now)
            }
            let components = calendar.dateComponents([.year, .month], from: lastMonthDate)
            let start = calendar.date(from: components) ?? lastMonthDate
            guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: start),
                  let end = calendar.date(byAdding: .day, value: -1, to: nextMonth) else {
                return (start, start)
            }
            return (start, end)

        case .allTime:
            let distantPast = Date.distantPast
            return (distantPast, now)

        case .custom:
            return (customStart ?? now, customEnd ?? now)
        }
    }

    private func generateDailyBreakdown(sessions: [FocusSession], from startDate: Date, to endDate: Date) -> [DailyProductivity] {
        let calendar = Calendar.current
        var dailyMap: [Date: DailyProductivity] = [:]

        // Initialize all days in range
        var currentDate = calendar.startOfDay(for: startDate)
        while currentDate <= endDate {
            dailyMap[currentDate] = DailyProductivity(date: currentDate)
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDay
        }

        // Populate with session data - track documents per day
        var documentsByDay: [Date: Set<UUID>] = [:]
        for session in sessions {
            let day = calendar.startOfDay(for: session.startTime)
            if var daily = dailyMap[day] {
                daily.wordsWritten += session.wordsWritten
                daily.sessionsCompleted += 1
                daily.focusMinutes += session.actualDuration / 60
                
                // Track unique documents safely
                if let docId = session.documentId {
                    documentsByDay[day, default: []].insert(docId)
                    daily.documentsWorkedOn = documentsByDay[day]?.count ?? 0
                }
                
                dailyMap[day] = daily
            }
        }

        return dailyMap.values.sorted { $0.date < $1.date }
    }

    private func generateHourlyBreakdown(sessions: [FocusSession]) -> [HourlyProductivity] {
        var hourlyMap: [Int: HourlyProductivity] = [:]

        // Initialize all hours
        for hour in 0..<24 {
            hourlyMap[hour] = HourlyProductivity(hour: hour)
        }

        // Populate with session data
        let calendar = Calendar.current
        for session in sessions {
            let hour = calendar.component(.hour, from: session.startTime)
            if var hourly = hourlyMap[hour] {
                hourly.wordsWritten += session.wordsWritten
                hourly.sessionsCount += 1
                hourly.focusMinutes += session.actualDuration / 60
                hourlyMap[hour] = hourly
            }
        }

        return (0..<24).compactMap { hourlyMap[$0] }
    }

    private func makeStreakInsight(streak: WritingStreak) -> ProductivityInsight? {
        guard streak.currentStreak > 0 else { return nil }

        if streak.currentStreak >= streak.longestStreak && streak.currentStreak > 1 {
            return ProductivityInsight(
                type: .achievement,
                title: "New Record!",
                message: "You're on your longest writing streak: \(streak.currentStreak) days! Keep it up!",
                priority: 0
            )
        } else if streak.currentStreak >= 7 {
            return ProductivityInsight(
                type: .streak,
                title: "Writing Streak",
                message: "Amazing! \(streak.currentStreak)-day writing streak. You're building a solid habit!",
                priority: 1
            )
        } else if streak.currentStreak >= 3 {
            return ProductivityInsight(
                type: .streak,
                title: "Streak Building",
                message: "\(streak.currentStreak) days in a row. Keep the momentum going!",
                priority: 2
            )
        }
        return nil
    }

    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        var components = DateComponents()
        components.hour = hour
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return "\(hour):00"
    }
}
