import Foundation

/// Manages focus writing sessions including pomodoro, sprints, and deep work
public class FocusSessionManager {
    private var sessions: [UUID: FocusSession]
    private var currentSession: FocusSession?
    private var sessionHistory: [FocusSession]

    public init() {
        self.sessions = [:]
        self.currentSession = nil
        self.sessionHistory = []
    }

    // MARK: - Session Lifecycle

    /// Starts a new focus session
    public func startSession(
        type: FocusSessionType,
        documentId: UUID? = nil,
        currentWordCount: Int = 0,
        customDuration: TimeInterval? = nil
    ) -> FocusSession {
        // End any existing session first
        if let current = currentSession {
            _ = endSession(id: current.id, finalWordCount: current.wordsAtStart)
        }

        var session = FocusSession(
            type: type,
            state: .active,
            documentId: documentId,
            startTime: Date(),
            wordsAtStart: currentWordCount
        )

        if let duration = customDuration {
            session.targetDuration = duration
        }

        sessions[session.id] = session
        currentSession = session
        return session
    }

    /// Pauses the current session
    public func pauseSession() -> FocusSession? {
        guard var session = currentSession, session.state == .active else {
            return nil
        }

        session.state = .paused
        sessions[session.id] = session
        currentSession = session
        return session
    }

    /// Resumes a paused session
    public func resumeSession(pausedDuration: TimeInterval) -> FocusSession? {
        guard var session = currentSession, session.state == .paused else {
            return nil
        }

        session.state = .active
        session.pausedTime += pausedDuration
        sessions[session.id] = session
        currentSession = session
        return session
    }

    /// Ends the current session
    public func endSession(id: UUID, finalWordCount: Int, completed: Bool = true) -> FocusSession? {
        guard var session = sessions[id] else { return nil }

        session.endTime = Date()
        session.wordsAtEnd = finalWordCount
        session.state = completed ? .completed : .cancelled

        sessions[session.id] = session
        sessionHistory.append(session)

        if currentSession?.id == id {
            currentSession = nil
        }

        return session
    }

    /// Starts a break after a pomodoro session
    public func startBreak() -> FocusSession? {
        guard var session = currentSession,
              session.type == .pomodoro,
              session.isTargetReached else {
            return nil
        }

        session.state = .onBreak
        session.completedPomodoros += 1
        sessions[session.id] = session
        currentSession = session
        return session
    }

    /// Ends break and starts next pomodoro
    public func endBreakAndContinue() -> FocusSession? {
        guard let session = currentSession,
              session.state == .onBreak else {
            return nil
        }

        // Start a new pomodoro session
        return startSession(
            type: .pomodoro,
            documentId: session.documentId,
            currentWordCount: session.wordsAtEnd ?? session.wordsAtStart
        )
    }

    // MARK: - Session Queries

    /// Gets the current active session
    public func getCurrentSession() -> FocusSession? {
        return currentSession
    }

    /// Gets a session by ID
    public func getSession(id: UUID) -> FocusSession? {
        return sessions[id]
    }

    /// Gets all sessions
    public func getAllSessions() -> [FocusSession] {
        return Array(sessions.values).sorted { $0.startTime > $1.startTime }
    }

    /// Gets completed sessions
    public func getCompletedSessions() -> [FocusSession] {
        return sessionHistory.filter { $0.state == .completed }
            .sorted { $0.startTime > $1.startTime }
    }

    /// Gets sessions for a specific date
    public func getSessions(for date: Date) -> [FocusSession] {
        let calendar = Calendar.current
        return sessionHistory.filter {
            calendar.isDate($0.startTime, inSameDayAs: date)
        }.sorted { $0.startTime > $1.startTime }
    }

    /// Gets sessions for today
    public func getTodaySessions() -> [FocusSession] {
        return getSessions(for: Date())
    }

    /// Gets sessions for this week
    public func getThisWeekSessions() -> [FocusSession] {
        let calendar = Calendar.current
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) else {
            return []
        }
        return sessionHistory.filter { $0.startTime >= weekStart }
            .sorted { $0.startTime > $1.startTime }
    }

    // MARK: - Statistics

    /// Compute aggregated statistics from completed focus sessions.
    /// 
    /// The returned stats include totals for sessions and completed sessions, total focused time, total words written, average words per minute, longest and current streaks of daily completed sessions, total pomodoros completed, and the most frequent session type when available.
    /// - Returns: A `FocusSessionStats` populated with aggregated values derived from the manager's session history; `favoriteSessionType` is `nil` if there are no completed sessions.
    public func getStats() -> FocusSessionStats {
        let completed = sessionHistory.filter { $0.state == .completed }

        // Single-pass calculation of time, words, and pomodoros
        var totalTime: TimeInterval = 0.0
        var totalWords: Int = 0
        var totalPomodoros: Int = 0
        var typeCounts: [FocusSessionType: Int] = [:]
        
        for session in completed {
            totalTime += session.actualDuration
            totalWords += session.wordsWritten
            totalPomodoros += session.completedPomodoros
            typeCounts[session.type, default: 0] += 1
        }

        let avgWPM = averageWordsPerMinute(totalWords: totalWords, totalDuration: totalTime)

        // Find favorite session type
        let favorite = typeCounts.max(by: { $0.value < $1.value })?.key

        // Calculate streaks
        let streaks = calculateStreaks()

        return FocusSessionStats(
            totalSessions: sessionHistory.count,
            completedSessions: completed.count,
            totalFocusTime: totalTime,
            totalWordsWritten: totalWords,
            averageWordsPerMinute: avgWPM,
            longestStreak: streaks.longest,
            currentStreak: streaks.current,
            pomodorosCompleted: totalPomodoros,
            favoriteSessionType: favorite
        )
    }

    /// Gathers aggregated statistics for completed focus sessions that started today.
    /// - Returns: A `FocusSessionStats` containing counts and totals for today's completed sessions: totalSessions, completedSessions, totalFocusTime (seconds), totalWordsWritten, averageWordsPerMinute, and pomodorosCompleted.
    public func getTodayStats() -> FocusSessionStats {
        let todaySessions = getTodaySessions().filter { $0.state == .completed }

        // Single-pass calculation
        var totalTime: TimeInterval = 0.0
        var totalWords: Int = 0
        var totalPomodoros: Int = 0
        
        for session in todaySessions {
            totalTime += session.actualDuration
            totalWords += session.wordsWritten
            totalPomodoros += session.completedPomodoros
        }

        let avgWPM = averageWordsPerMinute(totalWords: totalWords, totalDuration: totalTime)

        return FocusSessionStats(
            totalSessions: todaySessions.count,
            completedSessions: todaySessions.count,
            totalFocusTime: totalTime,
            totalWordsWritten: totalWords,
            averageWordsPerMinute: avgWPM,
            pomodorosCompleted: totalPomodoros
        )
    }

    /// Calculate focus time for a specific date range
    public func getFocusTime(from startDate: Date, to endDate: Date) -> TimeInterval {
        return sessionHistory
            .filter { $0.startTime >= startDate && $0.startTime <= endDate && $0.state == .completed }
            .reduce(0.0) { $0 + $1.actualDuration }
    }

    /// Calculates the average writing speed in words per minute.
    /// - Parameters:
    ///   - totalWords: The total number of words written.
    ///   - totalDuration: The total duration in seconds during which the words were written.
    /// - Returns: The average words per minute as a `Double`; `0` if `totalDuration` is less than or equal to zero.

    private func averageWordsPerMinute(totalWords: Int, totalDuration: TimeInterval) -> Double {
        guard totalDuration > 0 else { return 0 }
        return Double(totalWords) / (totalDuration / 60)
    }

    /// Compute the current and longest consecutive-day streaks based on completed sessions.
    /// 
    /// The calculation uses unique session days from `sessionHistory`. The current streak counts consecutive days up to today (including yesterday when applicable). If there are no completed session days, both values are `0`.
    /// - Returns: A tuple where `current` is the number of consecutive days in the current streak and `longest` is the maximum consecutive-day streak observed.
    private func calculateStreaks() -> (current: Int, longest: Int) {
        let calendar = Calendar.current
        var dates = Set<Date>()

        // Collect unique dates with single calendar operation per session
        for session in sessionHistory where session.state == .completed {
            let day = calendar.startOfDay(for: session.startTime)
            dates.insert(day)
        }

        let sortedDates = dates.sorted(by: >)
        guard !sortedDates.isEmpty else { return (0, 0) }

        var currentStreak = 0
        var longestStreak = 0
        var streak = 1
        var previousDate: Date?

        for date in sortedDates {
            if let prev = previousDate {
                let diff = calendar.dateComponents([.day], from: date, to: prev).day ?? 0
                if diff == 1 {
                    streak += 1
                } else {
                    longestStreak = max(longestStreak, streak)
                    streak = 1
                }
            }
            previousDate = date

            // Check if current streak includes today
            if calendar.isDateInToday(date) || calendar.isDateInYesterday(date) {
                currentStreak = streak
            }
        }

        longestStreak = max(longestStreak, streak)

        return (currentStreak, longestStreak)
    }

    // MARK: - Session Display Helpers

    /// Formats time remaining as a string
    public static func formatTimeRemaining(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    /// Formats duration as a human-readable string
    public static func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let mins = (Int(seconds) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(mins)m"
        } else {
            return "\(mins)m"
        }
    }
}
