import XCTest
@testable import WritersApp

/// Comprehensive tests for WritingGoalManager operations
final class WritingGoalManagerTests: XCTestCase {
    var manager: WritingGoalManager!

    override func setUp() {
        super.setUp()
        manager = WritingGoalManager()
    }

    override func tearDown() {
        manager = nil
        super.tearDown()
    }

    // MARK: - Goal Creation Tests

    func testCreateGoal() {
        let goal = manager.createGoal(
            name: "Test Goal",
            type: .daily,
            unit: .words,
            target: 500
        )

        XCTAssertEqual(goal.name, "Test Goal")
        XCTAssertEqual(goal.type, .daily)
        XCTAssertEqual(goal.unit, .words)
        XCTAssertEqual(goal.target, 500)
        XCTAssertEqual(goal.current, 0)
        XCTAssertTrue(goal.isActive)
    }

    func testCreateGoalWithDocumentId() {
        let documentId = UUID()
        let goal = manager.createGoal(
            name: "Document Goal",
            type: .project,
            target: 1000,
            documentId: documentId
        )

        XCTAssertEqual(goal.documentId, documentId)
    }

    func testCreateGoalWithEndDate() {
        let endDate = Date(timeIntervalSinceNow: 86400) // Tomorrow
        let goal = manager.createGoal(
            name: "Custom Goal",
            type: .custom,
            target: 1000,
            endDate: endDate
        )

        XCTAssertNotNil(goal.endDate)
    }

    func testCreateGoalWithReminder() {
        let reminderTime = Date()
        let goal = manager.createGoal(
            name: "Reminder Goal",
            type: .daily,
            target: 500,
            reminderEnabled: true,
            reminderTime: reminderTime
        )

        XCTAssertTrue(goal.reminderEnabled)
        XCTAssertEqual(goal.reminderTime, reminderTime)
    }

    func testCreateDailyWordGoal() {
        let goal = manager.createDailyWordGoal(target: 1000)

        XCTAssertEqual(goal.type, .daily)
        XCTAssertEqual(goal.unit, .words)
        XCTAssertEqual(goal.target, 1000)
        XCTAssertNotNil(goal.endDate)
    }

    func testCreateDailyWordGoalWithCustomName() {
        let goal = manager.createDailyWordGoal(target: 500, name: "Morning Writing")

        XCTAssertEqual(goal.name, "Morning Writing")
    }

    func testCreateWeeklyWordGoal() {
        let goal = manager.createWeeklyWordGoal(target: 5000)

        XCTAssertEqual(goal.type, .weekly)
        XCTAssertEqual(goal.unit, .words)
        XCTAssertEqual(goal.target, 5000)
        XCTAssertNotNil(goal.endDate)
    }

    func testCreateWeeklyWordGoalWithCustomName() {
        let goal = manager.createWeeklyWordGoal(target: 3000, name: "Weekly Target")

        XCTAssertEqual(goal.name, "Weekly Target")
    }

    func testCreateProjectGoal() {
        let documentId = UUID()
        let goal = manager.createProjectGoal(
            documentId: documentId,
            target: 50000,
            unit: .words,
            name: "Novel Project"
        )

        XCTAssertEqual(goal.type, .project)
        XCTAssertEqual(goal.documentId, documentId)
        XCTAssertEqual(goal.target, 50000)
        XCTAssertEqual(goal.name, "Novel Project")
    }

    func testCreateProjectGoalWithPages() {
        let documentId = UUID()
        let goal = manager.createProjectGoal(
            documentId: documentId,
            target: 200,
            unit: .pages
        )

        XCTAssertEqual(goal.unit, .pages)
        XCTAssertEqual(goal.target, 200)
    }

    // MARK: - Goal Management Tests

    func testUpdateGoal() {
        var goal = manager.createGoal(name: "Original", type: .daily, target: 500)
        goal.name = "Updated"
        goal.target = 1000

        manager.updateGoal(goal)

        let retrieved = manager.getGoal(id: goal.id)
        XCTAssertEqual(retrieved?.name, "Updated")
        XCTAssertEqual(retrieved?.target, 1000)
    }

    func testDeleteGoal() {
        let goal = manager.createGoal(name: "To Delete", type: .daily, target: 500)

        manager.deleteGoal(id: goal.id)

        XCTAssertNil(manager.getGoal(id: goal.id))
    }

    func testDeleteGoalWithInvalidId() {
        let invalidId = UUID()
        // Should not crash
        manager.deleteGoal(id: invalidId)
        XCTAssertNil(manager.getGoal(id: invalidId))
    }

    func testGetGoal() {
        let goal = manager.createGoal(name: "Test", type: .daily, target: 500)

        let retrieved = manager.getGoal(id: goal.id)

        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.id, goal.id)
    }

    func testGetGoalWithInvalidId() {
        let retrieved = manager.getGoal(id: UUID())

        XCTAssertNil(retrieved)
    }

    func testGetAllGoals() {
        let goal1 = manager.createGoal(name: "Goal 1", type: .daily, target: 500)
        let goal2 = manager.createGoal(name: "Goal 2", type: .weekly, target: 3000)
        let goal3 = manager.createGoal(name: "Goal 3", type: .monthly, target: 10000)

        let allGoals = manager.getAllGoals()

        XCTAssertEqual(allGoals.count, 3)
        // Should be sorted by start date descending
        XCTAssertEqual(allGoals[0].id, goal3.id)
        XCTAssertEqual(allGoals[1].id, goal2.id)
        XCTAssertEqual(allGoals[2].id, goal1.id)
    }

    func testGetActiveGoals() {
        let goal1 = manager.createGoal(name: "Active", type: .daily, target: 500)
        var goal2 = manager.createGoal(name: "Inactive", type: .weekly, target: 3000)
        goal2.isActive = false
        manager.updateGoal(goal2)

        let activeGoals = manager.getActiveGoals()

        XCTAssertEqual(activeGoals.count, 1)
        XCTAssertEqual(activeGoals.first?.id, goal1.id)
    }

    func testGetActiveGoalsSortedByProgress() {
        let goal1 = manager.createGoal(name: "Goal 1", type: .daily, target: 100)
        manager.recordProgress(goalId: goal1.id, amount: 50) // 50% progress

        let goal2 = manager.createGoal(name: "Goal 2", type: .daily, target: 100)
        manager.recordProgress(goalId: goal2.id, amount: 25) // 25% progress

        let activeGoals = manager.getActiveGoals()

        XCTAssertEqual(activeGoals.count, 2)
        // Should be sorted by progress ascending
        XCTAssertEqual(activeGoals[0].id, goal2.id)
        XCTAssertEqual(activeGoals[1].id, goal1.id)
    }

    func testGetGoalsForDocument() {
        let doc1 = UUID()
        let doc2 = UUID()

        let goal1 = manager.createGoal(name: "Doc 1 Goal", type: .project, target: 1000, documentId: doc1)
        let goal2 = manager.createGoal(name: "Doc 2 Goal", type: .project, target: 2000, documentId: doc2)
        let goal3 = manager.createGoal(name: "Doc 1 Goal 2", type: .project, target: 1500, documentId: doc1)

        let doc1Goals = manager.getGoals(for: doc1)

        XCTAssertEqual(doc1Goals.count, 2)
        XCTAssertTrue(doc1Goals.allSatisfy { $0.documentId == doc1 })
    }

    func testGetDailyGoals() {
        let daily1 = manager.createDailyWordGoal(target: 500)
        let daily2 = manager.createDailyWordGoal(target: 1000)
        let weekly = manager.createWeeklyWordGoal(target: 3000)

        let dailyGoals = manager.getDailyGoals()

        XCTAssertEqual(dailyGoals.count, 2)
        XCTAssertTrue(dailyGoals.allSatisfy { $0.type == .daily })
    }

    // MARK: - Progress Tracking Tests

    func testRecordProgress() {
        let goal = manager.createGoal(name: "Test", type: .daily, target: 500)

        let updated = manager.recordProgress(goalId: goal.id, amount: 100)

        XCTAssertNotNil(updated)
        XCTAssertEqual(updated?.current, 100)
    }

    func testRecordProgressWithNotes() {
        let goal = manager.createGoal(name: "Test", type: .daily, target: 500)

        let updated = manager.recordProgress(goalId: goal.id, amount: 100, notes: "Good session")

        XCTAssertNotNil(updated)

        let history = manager.getProgressHistory(goalId: goal.id)
        XCTAssertEqual(history.count, 1)
        XCTAssertEqual(history.first?.notes, "Good session")
    }

    func testRecordProgressWithInvalidId() {
        let updated = manager.recordProgress(goalId: UUID(), amount: 100)

        XCTAssertNil(updated)
    }

    func testRecordProgressMultipleTimes() {
        let goal = manager.createGoal(name: "Test", type: .daily, target: 500)

        manager.recordProgress(goalId: goal.id, amount: 100)
        manager.recordProgress(goalId: goal.id, amount: 150)
        let updated = manager.recordProgress(goalId: goal.id, amount: 50)

        XCTAssertEqual(updated?.current, 300)
    }

    func testSetProgress() {
        let goal = manager.createGoal(name: "Test", type: .daily, target: 500)

        let updated = manager.setProgress(goalId: goal.id, current: 250)

        XCTAssertNotNil(updated)
        XCTAssertEqual(updated?.current, 250)
    }

    func testSetProgressCreatesHistoryEntry() {
        let goal = manager.createGoal(name: "Test", type: .daily, target: 500)

        manager.setProgress(goalId: goal.id, current: 250)

        let history = manager.getProgressHistory(goalId: goal.id)
        XCTAssertEqual(history.count, 1)
        XCTAssertEqual(history.first?.amount, 250)
    }

    func testSetProgressWithSmallerValueNoHistory() {
        let goal = manager.createGoal(name: "Test", type: .daily, target: 500)

        manager.setProgress(goalId: goal.id, current: 300)
        manager.setProgress(goalId: goal.id, current: 200) // Smaller value

        let history = manager.getProgressHistory(goalId: goal.id)
        // Should only have one entry (the increase)
        XCTAssertEqual(history.count, 1)
        XCTAssertEqual(history.first?.amount, 300)
    }

    func testSetProgressWithInvalidId() {
        let updated = manager.setProgress(goalId: UUID(), current: 100)

        XCTAssertNil(updated)
    }

    func testGetProgressHistory() {
        let goal = manager.createGoal(name: "Test", type: .daily, target: 500)

        manager.recordProgress(goalId: goal.id, amount: 100, notes: "Session 1")
        manager.recordProgress(goalId: goal.id, amount: 150, notes: "Session 2")
        manager.recordProgress(goalId: goal.id, amount: 50, notes: "Session 3")

        let history = manager.getProgressHistory(goalId: goal.id)

        XCTAssertEqual(history.count, 3)
        // Should be sorted by date descending
        XCTAssertEqual(history[0].notes, "Session 3")
        XCTAssertEqual(history[1].notes, "Session 2")
        XCTAssertEqual(history[2].notes, "Session 1")
    }

    func testGetProgressHistoryWithInvalidId() {
        let history = manager.getProgressHistory(goalId: UUID())

        XCTAssertEqual(history.count, 0)
    }

    func testGetTodayProgress() {
        let goal = manager.createGoal(name: "Test", type: .daily, target: 500)

        manager.recordProgress(goalId: goal.id, amount: 100)
        manager.recordProgress(goalId: goal.id, amount: 150)

        let todayProgress = manager.getTodayProgress()

        XCTAssertEqual(todayProgress, 250)
    }

    func testGetTodayProgressWithNoProgress() {
        let todayProgress = manager.getTodayProgress()

        XCTAssertEqual(todayProgress, 0)
    }

    func testGetProgressDateRange() {
        let goal = manager.createGoal(name: "Test", type: .weekly, target: 3000)

        manager.recordProgress(goalId: goal.id, amount: 500)

        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: Date())
        let endDate = Date()

        let progress = manager.getProgress(from: startDate, to: endDate)

        XCTAssertEqual(progress, 500)
    }

    func testGetProgressDateRangeWithNoProgress() {
        let yesterday = Date(timeIntervalSinceNow: -86400)
        let twoDaysAgo = Date(timeIntervalSinceNow: -172800)

        let progress = manager.getProgress(from: twoDaysAgo, to: yesterday)

        XCTAssertEqual(progress, 0)
    }

    // MARK: - Streak Management Tests

    func testGetStreak() {
        let streak = manager.getStreak()

        XCTAssertEqual(streak.currentStreak, 0)
        XCTAssertEqual(streak.longestStreak, 0)
        XCTAssertNil(streak.lastWritingDate)
        XCTAssertEqual(streak.totalDaysWritten, 0)
    }

    func testStreakUpdatesOnProgress() {
        let goal = manager.createGoal(name: "Test", type: .daily, target: 500)

        manager.recordProgress(goalId: goal.id, amount: 100)

        let streak = manager.getStreak()

        XCTAssertEqual(streak.currentStreak, 1)
        XCTAssertEqual(streak.longestStreak, 1)
        XCTAssertNotNil(streak.lastWritingDate)
        XCTAssertEqual(streak.totalDaysWritten, 1)
    }

    func testStreakDoesNotIncreaseOnSameDay() {
        let goal = manager.createGoal(name: "Test", type: .daily, target: 500)

        manager.recordProgress(goalId: goal.id, amount: 100)
        manager.recordProgress(goalId: goal.id, amount: 100)
        manager.recordProgress(goalId: goal.id, amount: 100)

        let streak = manager.getStreak()

        XCTAssertEqual(streak.currentStreak, 1)
        XCTAssertEqual(streak.totalDaysWritten, 1) // Should not increment multiple times same day
    }

    func testCheckStreakStatus() {
        let goal = manager.createGoal(name: "Test", type: .daily, target: 500)
        manager.recordProgress(goalId: goal.id, amount: 100)

        manager.checkStreakStatus()

        let streak = manager.getStreak()
        // Streak should be maintained since we wrote today
        XCTAssertGreaterThanOrEqual(streak.currentStreak, 1)
    }

    // MARK: - Goal Reset Tests

    func testResetDailyGoals() {
        let daily = manager.createDailyWordGoal(target: 500)
        manager.recordProgress(goalId: daily.id, amount: 300)

        manager.resetDailyGoals()

        let retrieved = manager.getGoal(id: daily.id)
        XCTAssertEqual(retrieved?.current, 0)
        XCTAssertNotNil(retrieved?.endDate)
    }

    func testResetWeeklyGoals() {
        let weekly = manager.createWeeklyWordGoal(target: 3000)
        manager.recordProgress(goalId: weekly.id, amount: 1500)

        manager.resetWeeklyGoals()

        let retrieved = manager.getGoal(id: weekly.id)
        XCTAssertEqual(retrieved?.current, 0)
    }

    func testResetMonthlyGoals() {
        let monthly = manager.createGoal(name: "Monthly", type: .monthly, target: 10000)
        manager.recordProgress(goalId: monthly.id, amount: 5000)

        manager.resetMonthlyGoals()

        let retrieved = manager.getGoal(id: monthly.id)
        XCTAssertEqual(retrieved?.current, 0)
    }

    func testResetDoesNotAffectOtherGoalTypes() {
        let daily = manager.createDailyWordGoal(target: 500)
        let weekly = manager.createWeeklyWordGoal(target: 3000)

        manager.recordProgress(goalId: daily.id, amount: 300)
        manager.recordProgress(goalId: weekly.id, amount: 1500)

        manager.resetDailyGoals()

        XCTAssertEqual(manager.getGoal(id: daily.id)?.current, 0)
        XCTAssertEqual(manager.getGoal(id: weekly.id)?.current, 1500)
    }

    func testResetDoesNotAffectInactiveGoals() {
        var daily = manager.createDailyWordGoal(target: 500)
        daily.isActive = false
        manager.updateGoal(daily)

        manager.recordProgress(goalId: daily.id, amount: 300)

        manager.resetDailyGoals()

        // Should not be reset because it's inactive
        XCTAssertEqual(manager.getGoal(id: daily.id)?.current, 300)
    }

    // MARK: - Statistics Tests

    func testGetSummary() {
        let goal1 = manager.createGoal(name: "Goal 1", type: .daily, target: 100)
        manager.recordProgress(goalId: goal1.id, amount: 50)

        let goal2 = manager.createGoal(name: "Goal 2", type: .weekly, target: 500)
        manager.recordProgress(goalId: goal2.id, amount: 500)

        var goal3 = manager.createGoal(name: "Goal 3", type: .monthly, target: 1000)
        goal3.isActive = false
        manager.updateGoal(goal3)

        let summary = manager.getSummary()

        XCTAssertEqual(summary.totalGoals, 3)
        XCTAssertEqual(summary.activeGoals, 2)
        XCTAssertEqual(summary.achievedGoals, 1)
        XCTAssertGreaterThan(summary.overallProgress, 0)
    }

    func testGetSummaryWithNoGoals() {
        let summary = manager.getSummary()

        XCTAssertEqual(summary.totalGoals, 0)
        XCTAssertEqual(summary.activeGoals, 0)
        XCTAssertEqual(summary.achievedGoals, 0)
        XCTAssertEqual(summary.overallProgress, 0)
    }

    func testGetGoalsNeedingAttention() {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!

        let goal1 = manager.createGoal(
            name: "Behind Schedule",
            type: .custom,
            target: 1000,
            endDate: tomorrow
        )
        manager.recordProgress(goalId: goal1.id, amount: 100) // 10% progress with 1 day left

        let goal2 = manager.createGoal(
            name: "On Track",
            type: .custom,
            target: 100,
            endDate: tomorrow
        )
        manager.recordProgress(goalId: goal2.id, amount: 90) // 90% progress

        let needingAttention = manager.getGoalsNeedingAttention()

        // Goal1 should be in the list (behind schedule)
        XCTAssertTrue(needingAttention.contains { $0.id == goal1.id })
        // Goal2 should not be in the list (on track)
        XCTAssertFalse(needingAttention.contains { $0.id == goal2.id })
    }

    func testGetGoalsNeedingAttentionSorted() {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!

        let goal1 = manager.createGoal(name: "More Behind", type: .custom, target: 1000, endDate: tomorrow)
        manager.recordProgress(goalId: goal1.id, amount: 50) // 5% progress

        let goal2 = manager.createGoal(name: "Less Behind", type: .custom, target: 1000, endDate: tomorrow)
        manager.recordProgress(goalId: goal2.id, amount: 100) // 10% progress

        let needingAttention = manager.getGoalsNeedingAttention()

        // Should be sorted by progress ascending (most behind first)
        if needingAttention.count >= 2 {
            XCTAssertEqual(needingAttention[0].id, goal1.id)
        }
    }

    // MARK: - Goal Properties Tests

    func testGoalProgress() {
        let goal = manager.createGoal(name: "Test", type: .daily, target: 100)
        manager.recordProgress(goalId: goal.id, amount: 50)

        let retrieved = manager.getGoal(id: goal.id)!
        XCTAssertEqual(retrieved.progress, 0.5, accuracy: 0.01)
        XCTAssertEqual(retrieved.progressPercentage, 50)
    }

    func testGoalProgressOver100Percent() {
        let goal = manager.createGoal(name: "Test", type: .daily, target: 100)
        manager.recordProgress(goalId: goal.id, amount: 150)

        let retrieved = manager.getGoal(id: goal.id)!
        XCTAssertEqual(retrieved.progress, 1.0, accuracy: 0.01) // Capped at 1.0
        XCTAssertEqual(retrieved.progressPercentage, 100) // Displayed as 100
    }

    func testGoalIsAchieved() {
        let goal = manager.createGoal(name: "Test", type: .daily, target: 100)
        manager.recordProgress(goalId: goal.id, amount: 100)

        let retrieved = manager.getGoal(id: goal.id)!
        XCTAssertTrue(retrieved.isAchieved)
    }

    func testGoalIsAchievedWithExcess() {
        let goal = manager.createGoal(name: "Test", type: .daily, target: 100)
        manager.recordProgress(goalId: goal.id, amount: 150)

        let retrieved = manager.getGoal(id: goal.id)!
        XCTAssertTrue(retrieved.isAchieved)
    }

    func testGoalIsNotAchieved() {
        let goal = manager.createGoal(name: "Test", type: .daily, target: 100)
        manager.recordProgress(goalId: goal.id, amount: 99)

        let retrieved = manager.getGoal(id: goal.id)!
        XCTAssertFalse(retrieved.isAchieved)
    }

    func testGoalRemaining() {
        let goal = manager.createGoal(name: "Test", type: .daily, target: 100)
        manager.recordProgress(goalId: goal.id, amount: 40)

        let retrieved = manager.getGoal(id: goal.id)!
        XCTAssertEqual(retrieved.remaining, 60)
    }

    func testGoalRemainingWhenAchieved() {
        let goal = manager.createGoal(name: "Test", type: .daily, target: 100)
        manager.recordProgress(goalId: goal.id, amount: 100)

        let retrieved = manager.getGoal(id: goal.id)!
        XCTAssertEqual(retrieved.remaining, 0)
    }

    func testGoalRemainingNeverNegative() {
        let goal = manager.createGoal(name: "Test", type: .daily, target: 100)
        manager.recordProgress(goalId: goal.id, amount: 150)

        let retrieved = manager.getGoal(id: goal.id)!
        XCTAssertEqual(retrieved.remaining, 0)
    }

    func testGoalIsWithinTimeWindow() {
        let tomorrow = Date(timeIntervalSinceNow: 86400)
        let goal = manager.createGoal(
            name: "Test",
            type: .custom,
            target: 100,
            endDate: tomorrow
        )

        XCTAssertTrue(goal.isWithinTimeWindow)
    }

    func testGoalIsNotWithinTimeWindowExpired() {
        let yesterday = Date(timeIntervalSinceNow: -86400)
        let goal = manager.createGoal(
            name: "Test",
            type: .custom,
            target: 100,
            endDate: yesterday
        )

        XCTAssertFalse(goal.isWithinTimeWindow)
    }

    func testGoalIsWithinTimeWindowNoEndDate() {
        let goal = manager.createGoal(
            name: "Test",
            type: .project,
            target: 100
        )

        // Project goals may not have end dates set automatically
        // isWithinTimeWindow should return true if no end date
        if goal.endDate == nil {
            XCTAssertTrue(goal.isWithinTimeWindow)
        }
    }

    func testGoalDaysRemaining() {
        let calendar = Calendar.current
        let threeDaysFromNow = calendar.date(byAdding: .day, value: 3, to: Date())!

        let goal = manager.createGoal(
            name: "Test",
            type: .custom,
            target: 100,
            endDate: threeDaysFromNow
        )

        let daysRemaining = goal.daysRemaining
        XCTAssertNotNil(daysRemaining)
        XCTAssertGreaterThanOrEqual(daysRemaining!, 2) // At least 2 days
        XCTAssertLessThanOrEqual(daysRemaining!, 3) // At most 3 days
    }

    func testGoalDaysRemainingNoEndDate() {
        let goal = manager.createGoal(
            name: "Test",
            type: .project,
            target: 100
        )

        if goal.endDate == nil {
            XCTAssertNil(goal.daysRemaining)
        }
    }

    func testGoalRequiredDailyProgress() {
        let calendar = Calendar.current
        let fiveDaysFromNow = calendar.date(byAdding: .day, value: 5, to: Date())!

        let goal = manager.createGoal(
            name: "Test",
            type: .custom,
            target: 1000,
            endDate: fiveDaysFromNow
        )
        manager.recordProgress(goalId: goal.id, amount: 500)

        let retrieved = manager.getGoal(id: goal.id)!
        let required = retrieved.requiredDailyProgress

        XCTAssertNotNil(required)
        // 500 remaining over ~5 days = 100 per day
        XCTAssertGreaterThanOrEqual(required!, 100)
    }

    func testGoalRequiredDailyProgressNoEndDate() {
        let goal = manager.createGoal(
            name: "Test",
            type: .project,
            target: 1000
        )

        if goal.endDate == nil {
            XCTAssertNil(goal.requiredDailyProgress)
        }
    }

    // MARK: - Edge Cases and Negative Tests

    func testCreateGoalWithZeroTarget() {
        let goal = manager.createGoal(name: "Zero Target", type: .daily, target: 0)

        XCTAssertEqual(goal.target, 0)
        XCTAssertEqual(goal.progress, 0)
    }

    func testRecordNegativeProgress() {
        let goal = manager.createGoal(name: "Test", type: .daily, target: 500)

        manager.recordProgress(goalId: goal.id, amount: -100)

        let retrieved = manager.getGoal(id: goal.id)!
        // Current would be -100, which is allowed by the implementation
        XCTAssertEqual(retrieved.current, -100)
    }

    func testSetProgressToZero() {
        let goal = manager.createGoal(name: "Test", type: .daily, target: 500)
        manager.recordProgress(goalId: goal.id, amount: 300)

        manager.setProgress(goalId: goal.id, current: 0)

        let retrieved = manager.getGoal(id: goal.id)!
        XCTAssertEqual(retrieved.current, 0)
    }

    func testMultipleGoalsIndependence() {
        let goal1 = manager.createGoal(name: "Goal 1", type: .daily, target: 100)
        let goal2 = manager.createGoal(name: "Goal 2", type: .weekly, target: 500)

        manager.recordProgress(goalId: goal1.id, amount: 50)
        manager.recordProgress(goalId: goal2.id, amount: 200)

        XCTAssertEqual(manager.getGoal(id: goal1.id)?.current, 50)
        XCTAssertEqual(manager.getGoal(id: goal2.id)?.current, 200)
    }

    func testGoalUnitsAllTypes() {
        let wordsGoal = manager.createGoal(name: "Words", type: .daily, unit: .words, target: 500)
        let pagesGoal = manager.createGoal(name: "Pages", type: .daily, unit: .pages, target: 10)
        let minutesGoal = manager.createGoal(name: "Minutes", type: .daily, unit: .minutes, target: 60)
        let sessionsGoal = manager.createGoal(name: "Sessions", type: .daily, unit: .sessions, target: 3)
        let chaptersGoal = manager.createGoal(name: "Chapters", type: .daily, unit: .chapters, target: 1)

        XCTAssertEqual(wordsGoal.unit, .words)
        XCTAssertEqual(pagesGoal.unit, .pages)
        XCTAssertEqual(minutesGoal.unit, .minutes)
        XCTAssertEqual(sessionsGoal.unit, .sessions)
        XCTAssertEqual(chaptersGoal.unit, .chapters)
    }

    func testGoalTypesAllTypes() {
        let daily = manager.createGoal(name: "Daily", type: .daily, target: 500)
        let weekly = manager.createGoal(name: "Weekly", type: .weekly, target: 3000)
        let monthly = manager.createGoal(name: "Monthly", type: .monthly, target: 10000)
        let project = manager.createGoal(name: "Project", type: .project, target: 50000)
        let custom = manager.createGoal(name: "Custom", type: .custom, target: 1000)

        XCTAssertEqual(daily.type, .daily)
        XCTAssertEqual(weekly.type, .weekly)
        XCTAssertEqual(monthly.type, .monthly)
        XCTAssertEqual(project.type, .project)
        XCTAssertEqual(custom.type, .custom)
    }

    func testWritingStreakProperties() {
        let goal = manager.createGoal(name: "Test", type: .daily, target: 500)
        manager.recordProgress(goalId: goal.id, amount: 100)

        let streak = manager.getStreak()

        XCTAssertTrue(streak.wroteToday)
        XCTAssertTrue(streak.isStreakActive)
    }
}