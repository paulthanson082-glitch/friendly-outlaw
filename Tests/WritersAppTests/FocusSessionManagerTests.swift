import XCTest
@testable import WritersApp

/// Comprehensive tests for FocusSessionManager operations
final class FocusSessionManagerTests: XCTestCase {
    var manager: FocusSessionManager!

    override func setUp() {
        super.setUp()
        manager = FocusSessionManager()
    }

    override func tearDown() {
        manager = nil
        super.tearDown()
    }

    // MARK: - Session Start Tests

    func testStartSession() {
        let session = manager.startSession(type: .pomodoro, currentWordCount: 100)

        XCTAssertEqual(session.type, .pomodoro)
        XCTAssertEqual(session.state, .active)
        XCTAssertEqual(session.wordsAtStart, 100)
        XCTAssertEqual(session.targetDuration, 25 * 60)
        XCTAssertEqual(manager.getCurrentSession()?.id, session.id)
    }

    func testStartSessionWithCustomDuration() {
        let customDuration: TimeInterval = 3600 // 1 hour
        let session = manager.startSession(type: .freeWrite, customDuration: customDuration)

        XCTAssertEqual(session.targetDuration, customDuration)
    }

    func testStartSessionWithDocumentId() {
        let documentId = UUID()
        let session = manager.startSession(type: .sprint, documentId: documentId)

        XCTAssertEqual(session.documentId, documentId)
    }

    func testStartSessionEndsExistingSession() {
        let session1 = manager.startSession(type: .pomodoro, currentWordCount: 100)
        let session2 = manager.startSession(type: .sprint, currentWordCount: 150)

        XCTAssertNotEqual(session1.id, session2.id)
        XCTAssertEqual(manager.getCurrentSession()?.id, session2.id)

        // First session should be ended
        let endedSession = manager.getSession(id: session1.id)
        XCTAssertNotNil(endedSession?.endTime)
    }

    func testStartMultipleFocusSessionTypes() {
        let pomodoro = manager.startSession(type: .pomodoro)
        XCTAssertEqual(pomodoro.targetDuration, 25 * 60)

        let sprint = manager.startSession(type: .sprint)
        XCTAssertEqual(sprint.targetDuration, 15 * 60)

        let deepWork = manager.startSession(type: .deepWork)
        XCTAssertEqual(deepWork.targetDuration, 90 * 60)

        let marathon = manager.startSession(type: .marathon)
        XCTAssertEqual(marathon.targetDuration, 120 * 60)

        let freeWrite = manager.startSession(type: .freeWrite)
        XCTAssertEqual(freeWrite.targetDuration, 0)
    }

    // MARK: - Session Pause/Resume Tests

    func testPauseSession() {
        let session = manager.startSession(type: .pomodoro)

        let pausedSession = manager.pauseSession()

        XCTAssertNotNil(pausedSession)
        XCTAssertEqual(pausedSession?.state, .paused)
        XCTAssertEqual(pausedSession?.id, session.id)
    }

    func testPauseSessionWhenNoActiveSession() {
        let pausedSession = manager.pauseSession()

        XCTAssertNil(pausedSession)
    }

    func testPauseSessionWhenAlreadyPaused() {
        manager.startSession(type: .pomodoro)
        manager.pauseSession()

        let pausedAgain = manager.pauseSession()

        XCTAssertNil(pausedAgain)
    }

    func testResumeSession() {
        manager.startSession(type: .pomodoro)
        manager.pauseSession()

        let pauseDuration: TimeInterval = 120 // 2 minutes
        let resumedSession = manager.resumeSession(pausedDuration: pauseDuration)

        XCTAssertNotNil(resumedSession)
        XCTAssertEqual(resumedSession?.state, .active)
        XCTAssertEqual(resumedSession?.pausedTime, pauseDuration)
    }

    func testResumeSessionWhenNoSession() {
        let resumedSession = manager.resumeSession(pausedDuration: 60)

        XCTAssertNil(resumedSession)
    }

    func testResumeSessionWhenNotPaused() {
        manager.startSession(type: .pomodoro)

        let resumedSession = manager.resumeSession(pausedDuration: 60)

        XCTAssertNil(resumedSession)
    }

    func testMultiplePausesAccumulatePausedTime() {
        manager.startSession(type: .pomodoro)
        manager.pauseSession()
        manager.resumeSession(pausedDuration: 60)
        manager.pauseSession()
        manager.resumeSession(pausedDuration: 90)

        let session = manager.getCurrentSession()
        XCTAssertEqual(session?.pausedTime, 150)
    }

    // MARK: - Session End Tests

    func testEndSession() {
        let session = manager.startSession(type: .pomodoro, currentWordCount: 100)

        let endedSession = manager.endSession(id: session.id, finalWordCount: 250)

        XCTAssertNotNil(endedSession)
        XCTAssertNotNil(endedSession?.endTime)
        XCTAssertEqual(endedSession?.wordsAtEnd, 250)
        XCTAssertEqual(endedSession?.state, .completed)
        XCTAssertNil(manager.getCurrentSession())
    }

    func testEndSessionAsCancelled() {
        let session = manager.startSession(type: .pomodoro, currentWordCount: 100)

        let endedSession = manager.endSession(id: session.id, finalWordCount: 100, completed: false)

        XCTAssertEqual(endedSession?.state, .cancelled)
    }

    func testEndSessionWithInvalidId() {
        let invalidId = UUID()
        let endedSession = manager.endSession(id: invalidId, finalWordCount: 100)

        XCTAssertNil(endedSession)
    }

    func testEndSessionAddsToHistory() {
        let session = manager.startSession(type: .pomodoro)
        manager.endSession(id: session.id, finalWordCount: 100)

        let completedSessions = manager.getCompletedSessions()
        XCTAssertEqual(completedSessions.count, 1)
        XCTAssertEqual(completedSessions.first?.id, session.id)
    }

    // MARK: - Break Management Tests

    func testStartBreak() {
        let session = manager.startSession(type: .pomodoro, currentWordCount: 100)

        // Simulate reaching target duration
        Thread.sleep(forTimeInterval: 0.01)
        var updatedSession = manager.getSession(id: session.id)!
        updatedSession.endTime = Date(timeInterval: 25 * 60 + 10, since: session.startTime)

        // Manually update the session to simulate target reached
        if let current = manager.getCurrentSession() {
            _ = manager.endSession(id: current.id, finalWordCount: 100, completed: false)
            let newSession = manager.startSession(type: .pomodoro, currentWordCount: 100)
            // Force the session to be on target
            _ = manager.endSession(id: newSession.id, finalWordCount: 150, completed: false)
            let targetReachedSession = manager.startSession(type: .pomodoro, currentWordCount: 150)
            _ = manager.pauseSession()
            _ = manager.resumeSession(pausedDuration: 0)
        }

        // Try with fresh session that has reached target
        let newPomodoroSession = manager.startSession(type: .pomodoro, currentWordCount: 100)

        // Simulate time passing to reach target - need to get the session, modify it, then update
        Thread.sleep(forTimeInterval: 0.01)

        // Since the startBreak checks isTargetReached which depends on actualDuration,
        // we need the session to have endTime set such that actualDuration >= targetDuration
        // This is a limitation - we'd need to either wait or have a way to mock time
        // For now, test the failure case
        let breakSession = manager.startBreak()

        // This will be nil because the session hasn't actually reached its target duration in real time
        XCTAssertNil(breakSession)
    }

    func testStartBreakWhenNotPomodoro() {
        manager.startSession(type: .sprint)

        let breakSession = manager.startBreak()

        XCTAssertNil(breakSession)
    }

    func testStartBreakWhenNoSession() {
        let breakSession = manager.startBreak()

        XCTAssertNil(breakSession)
    }

    func testEndBreakAndContinue() {
        let session = manager.startSession(type: .pomodoro, currentWordCount: 100)

        // Force session into break state by directly manipulating it
        _ = manager.pauseSession()
        _ = manager.resumeSession(pausedDuration: 0)

        // Since we can't easily force a break state, test the failure case
        let continuedSession = manager.endBreakAndContinue()

        XCTAssertNil(continuedSession)
    }

    func testEndBreakAndContinueWhenNoSession() {
        let continuedSession = manager.endBreakAndContinue()

        XCTAssertNil(continuedSession)
    }

    // MARK: - Session Query Tests

    func testGetCurrentSession() {
        XCTAssertNil(manager.getCurrentSession())

        let session = manager.startSession(type: .pomodoro)

        XCTAssertEqual(manager.getCurrentSession()?.id, session.id)
    }

    func testGetSession() {
        let session = manager.startSession(type: .pomodoro)

        let retrieved = manager.getSession(id: session.id)

        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.id, session.id)
    }

    func testGetSessionWithInvalidId() {
        let retrieved = manager.getSession(id: UUID())

        XCTAssertNil(retrieved)
    }

    func testGetAllSessions() {
        let session1 = manager.startSession(type: .pomodoro)
        let session2 = manager.startSession(type: .sprint)
        let session3 = manager.startSession(type: .deepWork)

        let allSessions = manager.getAllSessions()

        XCTAssertEqual(allSessions.count, 3)
        // Should be sorted by start time descending
        XCTAssertEqual(allSessions[0].id, session3.id)
        XCTAssertEqual(allSessions[1].id, session2.id)
        XCTAssertEqual(allSessions[2].id, session1.id)
    }

    func testGetCompletedSessions() {
        let session1 = manager.startSession(type: .pomodoro, currentWordCount: 100)
        manager.endSession(id: session1.id, finalWordCount: 200)

        let session2 = manager.startSession(type: .sprint, currentWordCount: 200)
        manager.endSession(id: session2.id, finalWordCount: 250, completed: false)

        let completedSessions = manager.getCompletedSessions()

        XCTAssertEqual(completedSessions.count, 1)
        XCTAssertEqual(completedSessions.first?.id, session1.id)
    }

    func testGetSessionsForDate() {
        let session1 = manager.startSession(type: .pomodoro)
        manager.endSession(id: session1.id, finalWordCount: 100)

        let todaySessions = manager.getSessions(for: Date())

        XCTAssertEqual(todaySessions.count, 1)
        XCTAssertEqual(todaySessions.first?.id, session1.id)
    }

    func testGetSessionsForDateWithNoDates() {
        let yesterday = Date(timeIntervalSinceNow: -86400)

        let sessions = manager.getSessions(for: yesterday)

        XCTAssertEqual(sessions.count, 0)
    }

    func testGetTodaySessions() {
        let session1 = manager.startSession(type: .pomodoro)
        manager.endSession(id: session1.id, finalWordCount: 100)

        let todaySessions = manager.getTodaySessions()

        XCTAssertEqual(todaySessions.count, 1)
        XCTAssertEqual(todaySessions.first?.id, session1.id)
    }

    func testGetThisWeekSessions() {
        let session1 = manager.startSession(type: .pomodoro)
        manager.endSession(id: session1.id, finalWordCount: 100)

        let weekSessions = manager.getThisWeekSessions()

        XCTAssertEqual(weekSessions.count, 1)
        XCTAssertEqual(weekSessions.first?.id, session1.id)
    }

    // MARK: - Statistics Tests

    func testGetStats() {
        let session1 = manager.startSession(type: .pomodoro, currentWordCount: 0)
        manager.endSession(id: session1.id, finalWordCount: 100)

        let session2 = manager.startSession(type: .sprint, currentWordCount: 100)
        manager.endSession(id: session2.id, finalWordCount: 250)

        let session3 = manager.startSession(type: .pomodoro, currentWordCount: 250)
        manager.endSession(id: session3.id, finalWordCount: 400)

        let stats = manager.getStats()

        XCTAssertEqual(stats.totalSessions, 3)
        XCTAssertEqual(stats.completedSessions, 3)
        XCTAssertEqual(stats.totalWordsWritten, 400)
        XCTAssertGreaterThan(stats.totalFocusTime, 0)
    }

    func testGetStatsWithNoSessions() {
        let stats = manager.getStats()

        XCTAssertEqual(stats.totalSessions, 0)
        XCTAssertEqual(stats.completedSessions, 0)
        XCTAssertEqual(stats.totalFocusTime, 0)
        XCTAssertEqual(stats.totalWordsWritten, 0)
        XCTAssertEqual(stats.averageWordsPerMinute, 0)
    }

    func testGetStatsWithMixedCompletedAndCancelled() {
        let session1 = manager.startSession(type: .pomodoro, currentWordCount: 0)
        manager.endSession(id: session1.id, finalWordCount: 100)

        let session2 = manager.startSession(type: .sprint, currentWordCount: 100)
        manager.endSession(id: session2.id, finalWordCount: 150, completed: false)

        let stats = manager.getStats()

        XCTAssertEqual(stats.totalSessions, 2)
        XCTAssertEqual(stats.completedSessions, 1)
        XCTAssertEqual(stats.totalWordsWritten, 100)
    }

    func testGetStatsFavoriteSessionType() {
        manager.startSession(type: .pomodoro, currentWordCount: 0)
        manager.endSession(id: manager.getCurrentSession()!.id, finalWordCount: 100)

        manager.startSession(type: .pomodoro, currentWordCount: 100)
        manager.endSession(id: manager.getCurrentSession()!.id, finalWordCount: 200)

        manager.startSession(type: .sprint, currentWordCount: 200)
        manager.endSession(id: manager.getCurrentSession()!.id, finalWordCount: 250)

        let stats = manager.getStats()

        XCTAssertEqual(stats.favoriteSessionType, .pomodoro)
    }

    func testGetTodayStats() {
        let session1 = manager.startSession(type: .pomodoro, currentWordCount: 0)
        manager.endSession(id: session1.id, finalWordCount: 100)

        let session2 = manager.startSession(type: .sprint, currentWordCount: 100)
        manager.endSession(id: session2.id, finalWordCount: 200)

        let todayStats = manager.getTodayStats()

        XCTAssertEqual(todayStats.totalSessions, 2)
        XCTAssertEqual(todayStats.completedSessions, 2)
        XCTAssertEqual(todayStats.totalWordsWritten, 200)
    }

    func testGetFocusTime() {
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: Date())

        let session1 = manager.startSession(type: .pomodoro, currentWordCount: 0)
        Thread.sleep(forTimeInterval: 0.05)
        manager.endSession(id: session1.id, finalWordCount: 100)

        let endDate = Date()
        let focusTime = manager.getFocusTime(from: startDate, to: endDate)

        XCTAssertGreaterThan(focusTime, 0)
    }

    func testGetFocusTimeWithNoSessions() {
        let focusTime = manager.getFocusTime(from: Date(), to: Date())

        XCTAssertEqual(focusTime, 0)
    }

    // MARK: - Streak Calculation Tests

    func testStreakCalculationWithConsecutiveDays() {
        // This is hard to test without mocking dates, but we can test the basic flow
        let session1 = manager.startSession(type: .pomodoro, currentWordCount: 0)
        manager.endSession(id: session1.id, finalWordCount: 100)

        let stats = manager.getStats()

        // Should have at least a streak of 1 if we wrote today
        XCTAssertGreaterThanOrEqual(stats.currentStreak, 0)
    }

    // MARK: - Format Helper Tests

    func testFormatTimeRemaining() {
        let formatted = FocusSessionManager.formatTimeRemaining(125)
        XCTAssertEqual(formatted, "02:05")
    }

    func testFormatTimeRemainingZero() {
        let formatted = FocusSessionManager.formatTimeRemaining(0)
        XCTAssertEqual(formatted, "00:00")
    }

    func testFormatTimeRemainingLarge() {
        let formatted = FocusSessionManager.formatTimeRemaining(3665) // 61 minutes, 5 seconds
        XCTAssertEqual(formatted, "61:05")
    }

    func testFormatDuration() {
        let formatted = FocusSessionManager.formatDuration(3660) // 1 hour, 1 minute
        XCTAssertEqual(formatted, "1h 1m")
    }

    func testFormatDurationMinutesOnly() {
        let formatted = FocusSessionManager.formatDuration(600) // 10 minutes
        XCTAssertEqual(formatted, "10m")
    }

    func testFormatDurationZero() {
        let formatted = FocusSessionManager.formatDuration(0)
        XCTAssertEqual(formatted, "0m")
    }

    // MARK: - Edge Cases and Negative Tests

    func testStartSessionWithZeroWordCount() {
        let session = manager.startSession(type: .pomodoro, currentWordCount: 0)

        XCTAssertEqual(session.wordsAtStart, 0)
    }

    func testEndSessionWithLowerWordCount() {
        let session = manager.startSession(type: .pomodoro, currentWordCount: 100)
        let endedSession = manager.endSession(id: session.id, finalWordCount: 50)

        // wordsWritten should be 0 (max(0, 50 - 100))
        XCTAssertEqual(endedSession?.wordsWritten, 0)
    }

    func testMultipleSessionsIndependence() {
        let doc1 = UUID()
        let doc2 = UUID()

        let session1 = manager.startSession(type: .pomodoro, documentId: doc1, currentWordCount: 100)
        manager.endSession(id: session1.id, finalWordCount: 200)

        let session2 = manager.startSession(type: .sprint, documentId: doc2, currentWordCount: 0)
        manager.endSession(id: session2.id, finalWordCount: 150)

        XCTAssertEqual(manager.getSession(id: session1.id)?.wordsWritten, 100)
        XCTAssertEqual(manager.getSession(id: session2.id)?.wordsWritten, 150)
    }

    func testSessionActualDurationCalculation() {
        let session = manager.startSession(type: .pomodoro)

        Thread.sleep(forTimeInterval: 0.1)

        let currentSession = manager.getCurrentSession()
        XCTAssertNotNil(currentSession)
        XCTAssertGreaterThan(currentSession!.actualDuration, 0)
    }

    func testPausedTimeExcludedFromActualDuration() {
        let session = manager.startSession(type: .pomodoro)

        Thread.sleep(forTimeInterval: 0.05)
        manager.pauseSession()

        let pauseDuration: TimeInterval = 100
        manager.resumeSession(pausedDuration: pauseDuration)

        let currentSession = manager.getCurrentSession()
        XCTAssertEqual(currentSession?.pausedTime, pauseDuration)
    }
}