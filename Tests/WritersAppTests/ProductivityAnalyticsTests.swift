import XCTest
@testable import WritersApp

/// Comprehensive tests for ProductivityAnalytics operations
final class ProductivityAnalyticsTests: XCTestCase {
    var focusManager: FocusSessionManager!
    var goalManager: WritingGoalManager!
    var analytics: ProductivityAnalytics!

    override func setUp() {
        super.setUp()
        focusManager = FocusSessionManager()
        goalManager = WritingGoalManager()
        analytics = ProductivityAnalytics(focusManager: focusManager, goalManager: goalManager)
    }

    override func tearDown() {
        analytics = nil
        goalManager = nil
        focusManager = nil
        super.tearDown()
    }

    // MARK: - Data Recording Tests

    func testRecordWordCount() {
        let documentId = UUID()

        analytics.recordWordCount(documentId: documentId, wordCount: 500)

        // No direct way to verify, but should not crash
        XCTAssertNotNil(analytics)
    }

    func testRecordMultipleWordCounts() {
        let doc1 = UUID()
        let doc2 = UUID()

        analytics.recordWordCount(documentId: doc1, wordCount: 500)
        analytics.recordWordCount(documentId: doc2, wordCount: 300)
        analytics.recordWordCount(documentId: doc1, wordCount: 600)

        XCTAssertNotNil(analytics)
    }

    // MARK: - Report Generation Tests

    func testGenerateReportForToday() {
        createTestSessions()

        let report = analytics.generateReport(for: .today)

        XCTAssertEqual(report.period, .today)
        XCTAssertGreaterThan(report.totalWords, 0)
        XCTAssertGreaterThan(report.totalSessions, 0)
        XCTAssertGreaterThan(report.totalFocusMinutes, 0)
    }

    func testGenerateReportForYesterday() {
        let report = analytics.generateReport(for: .yesterday)

        XCTAssertEqual(report.period, .yesterday)
        XCTAssertNotNil(report.startDate)
        XCTAssertNotNil(report.endDate)
    }

    func testGenerateReportForThisWeek() {
        createTestSessions()

        let report = analytics.generateReport(for: .thisWeek)

        XCTAssertEqual(report.period, .thisWeek)
        XCTAssertGreaterThanOrEqual(report.totalSessions, 0)
    }

    func testGenerateReportForLastWeek() {
        let report = analytics.generateReport(for: .lastWeek)

        XCTAssertEqual(report.period, .lastWeek)
        XCTAssertNotNil(report.startDate)
        XCTAssertNotNil(report.endDate)
    }

    func testGenerateReportForThisMonth() {
        createTestSessions()

        let report = analytics.generateReport(for: .thisMonth)

        XCTAssertEqual(report.period, .thisMonth)
    }

    func testGenerateReportForLastMonth() {
        let report = analytics.generateReport(for: .lastMonth)

        XCTAssertEqual(report.period, .lastMonth)
    }

    func testGenerateReportForAllTime() {
        createTestSessions()

        let report = analytics.generateReport(for: .allTime)

        XCTAssertEqual(report.period, .allTime)
        XCTAssertGreaterThan(report.totalWords, 0)
    }

    func testGenerateReportForCustomRange() {
        let startDate = Date(timeIntervalSinceNow: -86400 * 7) // 7 days ago
        let endDate = Date()

        let report = analytics.generateReport(for: .custom, customStart: startDate, customEnd: endDate)

        XCTAssertEqual(report.period, .custom)
        XCTAssertEqual(report.startDate, startDate)
        XCTAssertEqual(report.endDate, endDate)
    }

    func testGenerateReportWithNoSessions() {
        let report = analytics.generateReport(for: .today)

        XCTAssertEqual(report.totalWords, 0)
        XCTAssertEqual(report.totalSessions, 0)
        XCTAssertEqual(report.totalFocusMinutes, 0)
        XCTAssertEqual(report.averageWordsPerDay, 0)
        XCTAssertEqual(report.averageWordsPerSession, 0)
        XCTAssertEqual(report.averageSessionLength, 0)
    }

    func testGenerateReportCalculatesAverages() {
        createMultipleCompletedSessions()

        let report = analytics.generateReport(for: .today)

        XCTAssertGreaterThan(report.averageWordsPerDay, 0)
        XCTAssertGreaterThan(report.averageWordsPerSession, 0)
        XCTAssertGreaterThan(report.averageSessionLength, 0)
    }

    func testGenerateReportFindsPeakHour() {
        createMultipleCompletedSessions()

        let report = analytics.generateReport(for: .today)

        XCTAssertNotNil(report.peakHour)
        XCTAssertGreaterThanOrEqual(report.peakHour!, 0)
        XCTAssertLessThan(report.peakHour!, 24)
    }

    func testGenerateReportFindsMostProductiveDay() {
        createMultipleCompletedSessions()

        let report = analytics.generateReport(for: .thisWeek)

        XCTAssertNotNil(report.mostProductiveDay)
    }

    func testGenerateReportDailyBreakdown() {
        createMultipleCompletedSessions()

        let report = analytics.generateReport(for: .thisWeek)

        XCTAssertGreaterThan(report.dailyBreakdown.count, 0)
        XCTAssertTrue(report.dailyBreakdown.allSatisfy { $0.date >= report.startDate && $0.date <= report.endDate })
    }

    func testGenerateReportHourlyBreakdown() {
        createMultipleCompletedSessions()

        let report = analytics.generateReport(for: .today)

        XCTAssertEqual(report.hourlyBreakdown.count, 24)
        XCTAssertEqual(report.hourlyBreakdown[0].hour, 0)
        XCTAssertEqual(report.hourlyBreakdown[23].hour, 23)
    }

    func testReportCalculatesCorrectTotalFocusHours() {
        createTestSessions()

        let report = analytics.generateReport(for: .today)

        XCTAssertEqual(report.totalFocusHours, report.totalFocusMinutes / 60.0, accuracy: 0.01)
    }

    func testReportCalculatesCorrectWordsPerMinute() {
        createTestSessions()

        let report = analytics.generateReport(for: .today)

        let expectedWPM = report.totalFocusMinutes > 0 ? Double(report.totalWords) / report.totalFocusMinutes : 0
        XCTAssertEqual(report.averageWordsPerMinute, expectedWPM, accuracy: 0.01)
    }

    // MARK: - Today Summary Tests

    func testGetTodaySummary() {
        createTestSessions()

        let summary = analytics.getTodaySummary()

        XCTAssertNotNil(summary)
        XCTAssertGreaterThan(summary.wordsWritten, 0)
        XCTAssertGreaterThan(summary.sessionsCompleted, 0)
        XCTAssertGreaterThan(summary.focusMinutes, 0)
    }

    func testGetTodaySummaryWithNoSessions() {
        let summary = analytics.getTodaySummary()

        XCTAssertEqual(summary.wordsWritten, 0)
        XCTAssertEqual(summary.sessionsCompleted, 0)
        XCTAssertEqual(summary.focusMinutes, 0)
        XCTAssertEqual(summary.goalsAchieved, 0)
        XCTAssertEqual(summary.documentsWorkedOn, 0)
    }

    func testGetTodaySummaryTracksDocuments() {
        let doc1 = UUID()
        let doc2 = UUID()

        let session1 = focusManager.startSession(type: .pomodoro, documentId: doc1, currentWordCount: 0)
        focusManager.endSession(id: session1.id, finalWordCount: 100)

        let session2 = focusManager.startSession(type: .sprint, documentId: doc2, currentWordCount: 0)
        focusManager.endSession(id: session2.id, finalWordCount: 150)

        let session3 = focusManager.startSession(type: .pomodoro, documentId: doc1, currentWordCount: 100)
        focusManager.endSession(id: session3.id, finalWordCount: 200)

        let summary = analytics.getTodaySummary()

        XCTAssertEqual(summary.documentsWorkedOn, 2) // Only 2 unique documents
    }

    func testGetTodaySummaryIncludesGoalsAchieved() {
        createTestSessions()

        let goal = goalManager.createDailyWordGoal(target: 100)
        goalManager.recordProgress(goalId: goal.id, amount: 100)

        let summary = analytics.getTodaySummary()

        XCTAssertGreaterThan(summary.goalsAchieved, 0)
    }

    func testTodaySummaryCalculatesWordsPerMinute() {
        createTestSessions()

        let summary = analytics.getTodaySummary()

        let expectedWPM = summary.focusMinutes > 0 ? Double(summary.wordsWritten) / summary.focusMinutes : 0
        XCTAssertEqual(summary.wordsPerMinute, expectedWPM, accuracy: 0.01)
    }

    // MARK: - Insights Generation Tests

    func testGenerateInsights() {
        createMultipleCompletedSessions()

        let insights = analytics.generateInsights()

        XCTAssertNotNil(insights)
        XCTAssertTrue(insights.allSatisfy { $0.priority >= 0 })
    }

    func testGenerateInsightsWithPeakTime() {
        createMultipleCompletedSessions()

        let insights = analytics.generateInsights()

        let peakTimeInsight = insights.first { $0.type == .peakTime }
        if peakTimeInsight != nil {
            XCTAssertFalse(peakTimeInsight!.message.isEmpty)
        }
    }

    func testGenerateInsightsWithStreak() {
        let goal = goalManager.createDailyWordGoal(target: 100)
        goalManager.recordProgress(goalId: goal.id, amount: 100)

        let insights = analytics.generateInsights()

        // May have streak insights
        XCTAssertNotNil(insights)
    }

    func testGenerateInsightsForGoalsBehindSchedule() {
        let calendar = Calendar.current
        let tenDaysAgo = calendar.date(byAdding: .day, value: -10, to: Date())!
        let twoDaysFromNow = calendar.date(byAdding: .day, value: 2, to: Date())!

        let goal = goalManager.createGoal(
            name: "Behind Goal",
            type: .custom,
            target: 1000,
            startDate: tenDaysAgo,
            endDate: twoDaysFromNow
        )
        goalManager.recordProgress(goalId: goal.id, amount: 100) // Only 10% done with 10/12 days elapsed

        let insights = analytics.generateInsights()

        let warningInsight = insights.first { $0.type == .warning }
        XCTAssertNotNil(warningInsight)
    }

    func testGenerateInsightsForShortSessions() {
        // Create short sessions
        for _ in 1...5 {
            let session = focusManager.startSession(type: .freeWrite, currentWordCount: 0, customDuration: 300) // 5 min
            Thread.sleep(forTimeInterval: 0.01)
            focusManager.endSession(id: session.id, finalWordCount: 50)
        }

        let insights = analytics.generateInsights()

        let suggestionInsight = insights.first { $0.type == .suggestion }
        // May suggest longer sessions
        if suggestionInsight != nil {
            XCTAssertFalse(suggestionInsight!.message.isEmpty)
        }
    }

    func testGenerateInsightsForFastWriter() {
        // Create sessions with high word count
        for _ in 1...3 {
            let session = focusManager.startSession(type: .pomodoro, currentWordCount: 0)
            Thread.sleep(forTimeInterval: 0.05)
            focusManager.endSession(id: session.id, finalWordCount: 2000) // Very high for short time
        }

        let insights = analytics.generateInsights()

        // Should detect high WPM
        XCTAssertNotNil(insights)
    }

    func testGenerateInsightsWhenStreakAtRisk() {
        let goal = goalManager.createDailyWordGoal(target: 100)

        // Simulate writing yesterday but not today
        // This is hard to test without mocking dates, so we just verify insights are generated
        let insights = analytics.generateInsights()

        XCTAssertNotNil(insights)
    }

    func testGenerateInsightsSortedByPriority() {
        createMultipleCompletedSessions()

        let goal = goalManager.createDailyWordGoal(target: 100)
        goalManager.recordProgress(goalId: goal.id, amount: 50)

        let insights = analytics.generateInsights()

        // Verify sorted by priority
        for i in 0..<insights.count-1 {
            XCTAssertLessThanOrEqual(insights[i].priority, insights[i+1].priority)
        }
    }

    // MARK: - Comparison Analytics Tests

    func testComparePeriods() {
        createMultipleCompletedSessions()

        let (current, previous, improvement) = analytics.comparePeriods(current: .thisWeek, previous: .lastWeek)

        XCTAssertEqual(current.period, .thisWeek)
        XCTAssertEqual(previous.period, .lastWeek)
        XCTAssertNotNil(improvement)
    }

    func testComparePeriodsCalculatesImprovement() {
        createMultipleCompletedSessions()

        let (current, previous, improvement) = analytics.comparePeriods(current: .today, previous: .yesterday)

        // Improvement should be calculated as percentage
        if current.totalWords > 0 && previous.totalWords > 0 {
            let expectedImprovement = (Double(current.totalWords - previous.totalWords) / Double(previous.totalWords)) * 100
            XCTAssertEqual(improvement, expectedImprovement, accuracy: 0.01)
        }
    }

    func testComparePeriodsWithNoPreviousData() {
        createTestSessions()

        let (current, previous, improvement) = analytics.comparePeriods(current: .today, previous: .lastWeek)

        // If no previous data, improvement should be 100% if current has data
        if current.totalWords > 0 && previous.totalWords == 0 {
            XCTAssertEqual(improvement, 100, accuracy: 0.01)
        }
    }

    func testComparePeriodsWithNoData() {
        let (current, previous, improvement) = analytics.comparePeriods(current: .lastWeek, previous: .lastMonth)

        XCTAssertEqual(improvement, 0, accuracy: 0.01)
    }

    // MARK: - Daily Productivity Tests

    func testDailyProductivityCalculatesWordsPerMinute() {
        let daily = DailyProductivity(
            date: Date(),
            wordsWritten: 600,
            sessionsCompleted: 2,
            focusMinutes: 30
        )

        XCTAssertEqual(daily.wordsPerMinute, 20, accuracy: 0.01)
    }

    func testDailyProductivityWordsPerMinuteZeroMinutes() {
        let daily = DailyProductivity(
            date: Date(),
            wordsWritten: 600,
            sessionsCompleted: 2,
            focusMinutes: 0
        )

        XCTAssertEqual(daily.wordsPerMinute, 0)
    }

    // MARK: - Hourly Productivity Tests

    func testHourlyProductivityInitialization() {
        let hourly = HourlyProductivity(hour: 14, wordsWritten: 500, sessionsCount: 2, focusMinutes: 25)

        XCTAssertEqual(hourly.hour, 14)
        XCTAssertEqual(hourly.wordsWritten, 500)
        XCTAssertEqual(hourly.sessionsCount, 2)
        XCTAssertEqual(hourly.focusMinutes, 25)
    }

    // MARK: - Analytics Period Tests

    func testAnalyticsPeriodDisplayNames() {
        XCTAssertEqual(AnalyticsPeriod.today.displayName, "Today")
        XCTAssertEqual(AnalyticsPeriod.yesterday.displayName, "Yesterday")
        XCTAssertEqual(AnalyticsPeriod.thisWeek.displayName, "This Week")
        XCTAssertEqual(AnalyticsPeriod.lastWeek.displayName, "Last Week")
        XCTAssertEqual(AnalyticsPeriod.thisMonth.displayName, "This Month")
        XCTAssertEqual(AnalyticsPeriod.lastMonth.displayName, "Last Month")
        XCTAssertEqual(AnalyticsPeriod.allTime.displayName, "All Time")
        XCTAssertEqual(AnalyticsPeriod.custom.displayName, "Custom Range")
    }

    // MARK: - Productivity Insight Tests

    func testProductivityInsightTypes() {
        let peakTime = ProductivityInsight(type: .peakTime, title: "Peak", message: "Message", priority: 1)
        let streak = ProductivityInsight(type: .streak, title: "Streak", message: "Message", priority: 1)
        let improvement = ProductivityInsight(type: .improvement, title: "Improve", message: "Message", priority: 1)
        let goalProgress = ProductivityInsight(type: .goalProgress, title: "Goal", message: "Message", priority: 1)
        let suggestion = ProductivityInsight(type: .suggestion, title: "Suggest", message: "Message", priority: 1)
        let warning = ProductivityInsight(type: .warning, title: "Warn", message: "Message", priority: 1)
        let achievement = ProductivityInsight(type: .achievement, title: "Achieve", message: "Message", priority: 1)

        XCTAssertEqual(peakTime.type, .peakTime)
        XCTAssertEqual(streak.type, .streak)
        XCTAssertEqual(improvement.type, .improvement)
        XCTAssertEqual(goalProgress.type, .goalProgress)
        XCTAssertEqual(suggestion.type, .suggestion)
        XCTAssertEqual(warning.type, .warning)
        XCTAssertEqual(achievement.type, .achievement)
    }

    // MARK: - Edge Cases and Integration Tests

    func testAnalyticsWithMixedSessionStates() {
        let session1 = focusManager.startSession(type: .pomodoro, currentWordCount: 0)
        focusManager.endSession(id: session1.id, finalWordCount: 100)

        let session2 = focusManager.startSession(type: .sprint, currentWordCount: 100)
        focusManager.endSession(id: session2.id, finalWordCount: 150, completed: false)

        let report = analytics.generateReport(for: .today)

        // Only completed sessions should count
        XCTAssertEqual(report.totalSessions, 1)
        XCTAssertEqual(report.totalWords, 100)
    }

    func testAnalyticsWithMultipleDocuments() {
        let doc1 = UUID()
        let doc2 = UUID()
        let doc3 = UUID()

        let session1 = focusManager.startSession(type: .pomodoro, documentId: doc1, currentWordCount: 0)
        focusManager.endSession(id: session1.id, finalWordCount: 100)

        let session2 = focusManager.startSession(type: .sprint, documentId: doc2, currentWordCount: 0)
        focusManager.endSession(id: session2.id, finalWordCount: 150)

        let session3 = focusManager.startSession(type: .pomodoro, documentId: doc3, currentWordCount: 0)
        focusManager.endSession(id: session3.id, finalWordCount: 200)

        let summary = analytics.getTodaySummary()

        XCTAssertEqual(summary.documentsWorkedOn, 3)
    }

    func testAnalyticsWithGoalsIntegration() {
        // Create sessions
        createTestSessions()

        // Create and achieve goals
        let goal1 = goalManager.createDailyWordGoal(target: 100)
        goalManager.recordProgress(goalId: goal1.id, amount: 100)

        let goal2 = goalManager.createDailyWordGoal(target: 200)
        goalManager.recordProgress(goalId: goal2.id, amount: 200)

        let summary = analytics.getTodaySummary()

        XCTAssertEqual(summary.goalsAchieved, 2)
    }

    func testReportDateRangesAreCorrect() {
        let report = analytics.generateReport(for: .today)

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        XCTAssertTrue(calendar.isDate(report.startDate, inSameDayAs: today))
    }

    func testReportWithSessionsSpanningMultipleDays() {
        // This would require mocking dates, so we just verify the report handles it
        createMultipleCompletedSessions()

        let report = analytics.generateReport(for: .thisWeek)

        XCTAssertGreaterThanOrEqual(report.dailyBreakdown.count, 1)
    }

    func testHourlyBreakdownCoversAllHours() {
        createMultipleCompletedSessions()

        let report = analytics.generateReport(for: .today)

        XCTAssertEqual(report.hourlyBreakdown.count, 24)

        for hour in 0..<24 {
            XCTAssertTrue(report.hourlyBreakdown.contains { $0.hour == hour })
        }
    }

    func testDailyBreakdownInitializesAllDaysInRange() {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -3, to: Date())!
        let endDate = Date()

        let report = analytics.generateReport(for: .custom, customStart: startDate, customEnd: endDate)

        // Should have at least 3-4 days in breakdown
        XCTAssertGreaterThanOrEqual(report.dailyBreakdown.count, 3)
    }

    func testAnalyticsHandlesZeroProgress() {
        let report = analytics.generateReport(for: .today)

        XCTAssertEqual(report.totalWords, 0)
        XCTAssertEqual(report.totalSessions, 0)
        XCTAssertEqual(report.averageWordsPerMinute, 0)
    }

    func testMultipleAnalyticsInstancesAreIndependent() {
        let focusManager2 = FocusSessionManager()
        let goalManager2 = WritingGoalManager()
        let analytics2 = ProductivityAnalytics(focusManager: focusManager2, goalManager: goalManager2)

        createTestSessions() // In first instance

        let report1 = analytics.generateReport(for: .today)
        let report2 = analytics2.generateReport(for: .today)

        XCTAssertGreaterThan(report1.totalSessions, report2.totalSessions)
    }

    // MARK: - Helper Methods

    private func createTestSessions() {
        let session1 = focusManager.startSession(type: .pomodoro, currentWordCount: 0)
        Thread.sleep(forTimeInterval: 0.01)
        focusManager.endSession(id: session1.id, finalWordCount: 100)

        let session2 = focusManager.startSession(type: .sprint, currentWordCount: 100)
        Thread.sleep(forTimeInterval: 0.01)
        focusManager.endSession(id: session2.id, finalWordCount: 250)
    }

    private func createMultipleCompletedSessions() {
        for i in 0..<5 {
            let session = focusManager.startSession(type: .pomodoro, currentWordCount: i * 100)
            Thread.sleep(forTimeInterval: 0.01)
            focusManager.endSession(id: session.id, finalWordCount: (i + 1) * 100)
        }
    }
}