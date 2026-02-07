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
        // End any existing session first, marking it as cancelled (completed: false) since it's being interrupted
        if let current = currentSession {
            _ = endSession(id: current.id, finalWordCount: current.wordsAtStart, completed: false)
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
        session.pauseStartTime = Date()
        sessions[session.id] = session
        currentSession = session
        return session
    }

    /// Resumes a paused session
    public func resumeSession() -> FocusSession? {
        guard var session = currentSession, 
              session.state == .paused,
              let pauseStart = session.pauseStartTime else {
            return nil
        }

        session.state = .active
        let pauseDuration = Date().timeIntervalSince(pauseStart)
        session.pausedTime += pauseDuration
        session.pauseStartTime = nil
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
        guard let activeSession = currentSession,
              activeSession.type == .pomodoro,
              activeSession.isTargetReached else {
            return nil
        }

        // Finalize the completed pomodoro session so it is recorded in history
        let finalWordCount = activeSession.wordsAtEnd ?? activeSession.wordsAtStart
        guard let completedSession = endSession(
            id: activeSession.id,
            finalWordCount: finalWordCount,
            completed: true
        ) else {
            return nil
        }

        // Start a break session (represented as a special state)
        var breakSession = completedSession
        breakSession.state = .onBreak
        breakSession.completedPomodoros += 1
        sessions[breakSession.id] = breakSession
        currentSession = breakSession
        return breakSession
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

    /// Gets all sessions (historical sessions plus the current active session, if any)
    public func getAllSessions() -> [FocusSession] {
        var allSessions = sessionHistory
        if let current = currentSession {
            allSessions.append(current)
        }
        return allSessions.sorted { $0.startTime > $1.startTime }
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

    /// Gets overall focus session statistics
    public func getStats() -> FocusSessionStats {
        let completed = sessionHistory.filter { $0.state == .completed }

        let totalTime = completed.reduce(0.0) { $0 + $1.actualDuration }
        let totalWords = completed.reduce(0) { $0 + $1.wordsWritten }
        let totalPomodoros = completed.reduce(0) { $0 + $1.completedPomodoros }

        let avgWPM: Double
        if totalTime > 0 {
            avgWPM = Double(totalWords) / (totalTime / 60)
        } else {
            avgWPM = 0
        }

        // Find favorite session type
        var typeCounts: [FocusSessionType: Int] = [:]
        for session in completed {
            typeCounts[session.type, default: 0] += 1
        }
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

    /// Gets stats for today
    public func getTodayStats() -> FocusSessionStats {
        let todaySessions = getTodaySessions().filter { $0.state == .completed }

        let totalTime = todaySessions.reduce(0.0) { $0 + $1.actualDuration }
        let totalWords = todaySessions.reduce(0) { $0 + $1.wordsWritten }
        let totalPomodoros = todaySessions.reduce(0) { $0 + $1.completedPomodoros }

        let avgWPM: Double
        if totalTime > 0 {
            avgWPM = Double(totalWords) / (totalTime / 60)
        } else {
            avgWPM = 0
        }

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

    // MARK: - Private Helpers

    private func calculateStreaks() -> (current: Int, longest: Int) {
        let calendar = Calendar.current
        var dates = Set<Date>()

        for session in sessionHistory where session.state == .completed {
            if let day = calendar.date(from: calendar.dateComponents([.year, .month, .day], from: session.startTime)) {
                dates.insert(day)
            }
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
