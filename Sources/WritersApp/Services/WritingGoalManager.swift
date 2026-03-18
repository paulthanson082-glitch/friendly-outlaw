import Foundation

/// Manages writing goals, progress tracking, and streaks
public class WritingGoalManager {
    private var goals: [UUID: WritingGoal]
    private var progressHistory: [GoalProgressEntry]
    private var streak: WritingStreak

    public init() {
        self.goals = [:]
        self.progressHistory = []
        self.streak = WritingStreak()
    }

    // MARK: - Goal Management

    /// Creates a new writing goal
    public func createGoal(
        name: String,
        type: GoalType,
        unit: GoalUnit = .words,
        target: Int,
        documentId: UUID? = nil,
        startDate: Date = Date(),
        endDate: Date? = nil,
        reminderEnabled: Bool = false,
        reminderTime: Date? = nil
    ) -> WritingGoal {
        let calculatedEndDate = endDate ?? calculateEndDate(for: type)

        let goal = WritingGoal(
            name: name,
            type: type,
            unit: unit,
            target: target,
            documentId: documentId,
            startDate: startDate,
            endDate: calculatedEndDate,
            reminderEnabled: reminderEnabled,
            reminderTime: reminderTime
        )

        goals[goal.id] = goal
        return goal
    }

    /// Creates a daily word count goal
    public func createDailyWordGoal(target: Int, name: String = "Daily Writing Goal") -> WritingGoal {
        return createGoal(name: name, type: .daily, unit: .words, target: target)
    }

    /// Creates a weekly word count goal
    public func createWeeklyWordGoal(target: Int, name: String = "Weekly Writing Goal") -> WritingGoal {
        return createGoal(name: name, type: .weekly, unit: .words, target: target)
    }

    /// Creates a project goal for a specific document
    public func createProjectGoal(
        documentId: UUID,
        target: Int,
        unit: GoalUnit = .words,
        name: String = "Project Goal"
    ) -> WritingGoal {
        return createGoal(
            name: name,
            type: .project,
            unit: unit,
            target: target,
            documentId: documentId
        )
    }

    /// Updates an existing goal
    public func updateGoal(_ goal: WritingGoal) {
        goals[goal.id] = goal
    }

    /// Deletes a goal
    public func deleteGoal(id: UUID) {
        goals.removeValue(forKey: id)
    }

    /// Gets a goal by ID
    public func getGoal(id: UUID) -> WritingGoal? {
        return goals[id]
    }

    /// Gets all goals
    public func getAllGoals() -> [WritingGoal] {
        return Array(goals.values).sorted { $0.startDate > $1.startDate }
    }

    /// Gets active goals
    public func getActiveGoals() -> [WritingGoal] {
        return goals.values.filter { $0.isActive && $0.isWithinTimeWindow }
            .sorted { $0.progress < $1.progress }
    }

    /// Gets goals for a specific document
    public func getGoals(for documentId: UUID) -> [WritingGoal] {
        return goals.values.filter { $0.documentId == documentId }
            .sorted { $0.startDate > $1.startDate }
    }

    /// Gets daily goals
    public func getDailyGoals() -> [WritingGoal] {
        return goals.values.filter { $0.type == .daily && $0.isActive }
    }

    // MARK: - Progress Tracking

    /// Records progress toward a goal
    public func recordProgress(goalId: UUID, amount: Int, notes: String = "") -> WritingGoal? {
        guard var goal = goals[goalId] else { return nil }

        let entry = GoalProgressEntry(
            goalId: goalId,
            amount: amount,
            notes: notes
        )
        progressHistory.append(entry)

        goal.current += amount
        goals[goalId] = goal

        // Update streak
        updateStreak()

        return goal
    }

    /// Sets the current value for a goal directly
    public func setProgress(goalId: UUID, current: Int) -> WritingGoal? {
        guard var goal = goals[goalId] else { return nil }

        let delta = current - goal.current
        if delta > 0 {
            let entry = GoalProgressEntry(
                goalId: goalId,
                amount: delta
            )
            progressHistory.append(entry)
            updateStreak()
        }

        goal.current = current
        goals[goalId] = goal
        return goal
    }

    /// Gets progress history for a goal
    public func getProgressHistory(goalId: UUID) -> [GoalProgressEntry] {
        return progressHistory.filter { $0.goalId == goalId }
            .sorted { $0.date > $1.date }
    }

    /// Gets progress for today
    public func getTodayProgress() -> Int {
        let calendar = Calendar.current
        return progressHistory
            .filter { calendar.isDateInToday($0.date) }
            .reduce(0) { $0 + $1.amount }
    }

    /// Gets progress for a specific date range
    public func getProgress(from startDate: Date, to endDate: Date) -> Int {
        return progressHistory
            .filter { $0.date >= startDate && $0.date <= endDate }
            .reduce(0) { $0 + $1.amount }
    }

    // MARK: - Streak Management

    /// Gets the current writing streak
    public func getStreak() -> WritingStreak {
        return streak
    }

    /// Updates the streak based on writing activity
    private func updateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        guard let lastDate = streak.lastWritingDate else {
            // First time writing
            streak.currentStreak = 1
            streak.longestStreak = 1
            streak.streakStartDate = today
            streak.lastWritingDate = Date()
            streak.totalDaysWritten += 1
            return
        }

        // Already wrote today — no change needed
        guard !calendar.isDateInToday(lastDate) else { return }

        if calendar.isDateInYesterday(lastDate) {
            // Wrote yesterday — extend streak
            streak.currentStreak += 1
            streak.longestStreak = max(streak.longestStreak, streak.currentStreak)
        } else {
            // Gap in writing — restart streak
            streak.currentStreak = 1
            streak.streakStartDate = today
        }

        streak.lastWritingDate = Date()
        streak.totalDaysWritten += 1
    }

    /// Checks and updates streak status (call at app start)
    public func checkStreakStatus() {
        guard let lastDate = streak.lastWritingDate else { return }
        let calendar = Calendar.current

        // If last writing was before yesterday, streak is broken
        if !calendar.isDateInToday(lastDate) && !calendar.isDateInYesterday(lastDate) {
            streak.currentStreak = 0
            streak.streakStartDate = nil
        }
    }

    // MARK: - Goal Reset (for recurring goals)

    /// Resets all active daily goals to start a new daily period.
    /// 
    /// For each active daily goal this sets its progress back to zero, updates its start date to now, and recalculates its end date.
    public func resetDailyGoals() {
        resetGoals(ofType: .daily)
    }

    /// Reset all active weekly goals to the start of a new weekly period.
    /// 
    /// Sets each active weekly goal's current progress to 0, updates its start date to now, and recalculates its end date for the new week.
    public func resetWeeklyGoals() {
        resetGoals(ofType: .weekly)
    }

    /// Resets all active monthly goals by setting their current progress to 0, updating their start date to now, and recalculating their end date for the new monthly period.
    public func resetMonthlyGoals() {
        resetGoals(ofType: .monthly)
    }

    /// Resets all active goals of the specified type to start a new period.
    /// 
    /// For each active goal matching `type`, sets `current` to 0, updates `startDate` to now, and recalculates `endDate`.
    /// - Parameters:
    ///   - type: The goal recurrence type to reset (e.g., daily, weekly, monthly).
    private func resetGoals(ofType type: GoalType) {
        for (id, var goal) in goals where goal.type == type && goal.isActive {
            goal.current = 0
            goal.startDate = Date()
            goal.endDate = calculateEndDate(for: type)
            goals[id] = goal
        }
    }

    // MARK: - Statistics

    /// Gets a summary of all goals
    public func getSummary() -> GoalsSummary {
        // Single-pass calculation
        var activeCount = 0
        var achievedCount = 0
        var totalProgress: Double = 0.0
        
        for goal in goals.values {
            if goal.isActive {
                activeCount += 1
                totalProgress += goal.progress
            }
            if goal.isAchieved {
                achievedCount += 1
            }
        }
        
        let avgProgress = activeCount > 0 ? totalProgress / Double(activeCount) : 0

        return GoalsSummary(
            activeGoals: activeCount,
            achievedGoals: achievedCount,
            totalGoals: goals.count,
            overallProgress: avgProgress,
            streak: streak
        )
    }

    /// Gets goals needing attention (behind schedule)
    public func getGoalsNeedingAttention() -> [WritingGoal] {
        let calendar = Calendar.current
        return goals.values.filter { goal in
            guard goal.isActive,
                  let endDate = goal.endDate,
                  let daysRemaining = goal.daysRemaining,
                  daysRemaining > 0 else { return false }

            let totalDays = max(1, calendar.dateComponents([.day], from: goal.startDate, to: endDate).day ?? 1)
            let expectedProgress = 1.0 - (Double(daysRemaining) / Double(totalDays))
            return goal.progress < expectedProgress * 0.8 // More than 20% behind
        }.sorted { $0.progress < $1.progress }
    }

    // MARK: - Private Helpers

    private func calculateEndDate(for type: GoalType) -> Date? {
        let calendar = Calendar.current
        let now = Date()

        switch type {
        case .daily:
            return calendar.date(bySettingHour: 23, minute: 59, second: 59, of: now)
        case .weekly:
            guard let nextWeek = calendar.date(byAdding: .day, value: 7, to: now) else { return nil }
            return calendar.startOfDay(for: nextWeek)
        case .monthly:
            guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: now) else { return nil }
            return calendar.startOfDay(for: nextMonth)
        case .project, .custom:
            return nil
        }
    }
}
