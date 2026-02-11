#if canImport(SwiftUI)
import XCTest
@testable import WritersApp

@MainActor
final class MetalDashboardTests: XCTestCase {

    // MARK: - MetalMantra Tests

    func testMetalMantraRandomReturnsNonNil() {
        let mantra = MetalMantra.random()
        XCTAssertFalse(mantra.quote.isEmpty)
        XCTAssertFalse(mantra.attribution.isEmpty)
    }

    func testMetalMantraAllIsNotEmpty() {
        XCTAssertGreaterThan(MetalMantra.all.count, 0)
    }

    func testMetalMantraContainsDeathcoreQuotes() {
        let quotes = MetalMantra.all.map { $0.quote }
        let hasBreakdownReference = quotes.contains { $0.contains("breakdown") }
        XCTAssertTrue(hasBreakdownReference, "Should contain deathcore-themed breakdown reference")
    }

    func testMetalMantraContainsGrooveMetalQuotes() {
        let attributions = MetalMantra.all.map { $0.attribution }
        let hasAshesRef = attributions.contains { $0.contains("Ashes") }
        XCTAssertTrue(hasAshesRef, "Should contain Lamb of God-inspired attribution")
    }

    func testAllMantrasHaveContent() {
        for mantra in MetalMantra.all {
            XCTAssertFalse(mantra.quote.isEmpty, "Mantra quote should not be empty")
            XCTAssertFalse(mantra.attribution.isEmpty, "Mantra attribution should not be empty")
        }
    }

    // MARK: - MetalDashboardViewModel Tests

    func testViewModelInitialState() {
        let vm = MetalDashboardViewModel()
        XCTAssertEqual(vm.totalDocuments, 0)
        XCTAssertEqual(vm.totalWords, 0)
        XCTAssertEqual(vm.totalTemplates, 0)
        XCTAssertTrue(vm.recentDocuments.isEmpty)
        XCTAssertTrue(vm.activeGoals.isEmpty)
        XCTAssertNil(vm.currentFocusSession)
        XCTAssertNil(vm.selectedDocument)
    }

    func testViewModelLoadDashboardPopulatesTemplates() {
        let app = WritersApp()
        let vm = MetalDashboardViewModel(app: app)
        vm.loadDashboard()

        // WritersApp loads 7 default templates
        XCTAssertEqual(vm.totalTemplates, 7)
    }

    func testViewModelLoadDashboardEmptyDocuments() {
        let vm = MetalDashboardViewModel()
        vm.loadDashboard()

        XCTAssertEqual(vm.totalDocuments, 0)
        XCTAssertEqual(vm.totalWords, 0)
        XCTAssertTrue(vm.recentDocuments.isEmpty)
    }

    func testViewModelCreateBlankDocument() {
        let app = WritersApp()
        let vm = MetalDashboardViewModel(app: app)
        vm.loadDashboard()

        vm.createBlankDocument(title: "Reclamation", category: .novel)

        XCTAssertNotNil(vm.selectedDocument)
        XCTAssertEqual(vm.selectedDocument?.title, "Reclamation")
        XCTAssertEqual(vm.totalDocuments, 1)
    }

    func testViewModelCreateFromTemplate() {
        let app = WritersApp()
        let vm = MetalDashboardViewModel(app: app)
        vm.loadDashboard()

        let templates = vm.getAllTemplates()
        guard let poetryTemplate = templates.first(where: { $0.category == .poetry }) else {
            XCTFail("Should have poetry template")
            return
        }

        vm.createFromTemplate(
            templateId: poetryTemplate.id,
            values: ["title": "Descent", "author": "Me"]
        )

        XCTAssertNotNil(vm.selectedDocument)
        XCTAssertEqual(vm.totalDocuments, 1)
    }

    func testViewModelRecentDocuments() {
        let app = WritersApp()
        let vm = MetalDashboardViewModel(app: app)

        _ = app.createBlankDocument(title: "Track 1", category: .novel)
        _ = app.createBlankDocument(title: "Track 2", category: .shortStory)
        _ = app.createBlankDocument(title: "Track 3", category: .poetry)

        vm.loadDashboard()

        XCTAssertEqual(vm.recentDocuments.count, 3)
        XCTAssertEqual(vm.totalDocuments, 3)
    }

    func testViewModelSelectDocument() {
        let app = WritersApp()
        let vm = MetalDashboardViewModel(app: app)

        let doc = app.createBlankDocument(title: "Whitechapel Lyrics", category: .poetry)
        vm.selectDocument(doc)

        XCTAssertNotNil(vm.selectedDocument)
        XCTAssertEqual(vm.selectedDocument?.id, doc.id)
    }

    func testViewModelGetAllTemplates() {
        let app = WritersApp()
        let vm = MetalDashboardViewModel(app: app)
        let templates = vm.getAllTemplates()

        XCTAssertEqual(templates.count, 7)
    }

    func testViewModelGetTemplatesByCategory() {
        let app = WritersApp()
        let vm = MetalDashboardViewModel(app: app)

        let poetryTemplates = vm.getTemplates(for: .poetry)
        XCTAssertGreaterThan(poetryTemplates.count, 0)
    }

    // MARK: - Focus Session Integration Tests

    func testViewModelStartFocusSession() {
        let vm = MetalDashboardViewModel()
        vm.startFocusSession(type: .pomodoro)

        XCTAssertNotNil(vm.currentFocusSession)
        XCTAssertEqual(vm.currentFocusSession?.type, .pomodoro)
        XCTAssertEqual(vm.currentFocusSession?.state, .active)
    }

    func testViewModelPauseFocusSession() {
        let vm = MetalDashboardViewModel()
        vm.startFocusSession(type: .sprint)
        vm.pauseFocusSession()

        XCTAssertEqual(vm.currentFocusSession?.state, .paused)
    }

    func testViewModelEndFocusSession() {
        let vm = MetalDashboardViewModel()
        vm.startFocusSession(type: .freeWrite)
        vm.endFocusSession(finalWordCount: 500)

        XCTAssertNil(vm.currentFocusSession)
    }

    // MARK: - Goal Integration Tests

    func testViewModelCreateDailyGoal() {
        let vm = MetalDashboardViewModel()
        vm.createDailyGoal(target: 1000)
        vm.loadGoals()

        XCTAssertEqual(vm.activeGoals.count, 1)
        XCTAssertEqual(vm.activeGoals.first?.target, 1000)
    }

    func testViewModelRecordGoalProgress() {
        let goalManager = WritingGoalManager()
        let vm = MetalDashboardViewModel(goalManager: goalManager)

        let goal = goalManager.createDailyWordGoal(target: 500)
        vm.recordGoalProgress(goalId: goal.id, amount: 200)

        let updatedGoal = goalManager.getGoal(id: goal.id)
        XCTAssertEqual(updatedGoal?.current, 200)
    }

    func testViewModelGoalsSummary() {
        let goalManager = WritingGoalManager()
        let vm = MetalDashboardViewModel(goalManager: goalManager)

        _ = goalManager.createDailyWordGoal(target: 500)
        _ = goalManager.createWeeklyWordGoal(target: 3500)
        vm.loadGoals()

        XCTAssertEqual(vm.goalsSummary.totalGoals, 2)
        XCTAssertEqual(vm.goalsSummary.activeGoals, 2)
    }

    // MARK: - Mantra Refresh Tests

    func testViewModelRefreshMantra() {
        let vm = MetalDashboardViewModel()
        let firstMantra = vm.currentMantra.quote

        // Refresh many times - at least one should differ (probabilistic but reliable with 14 mantras)
        var gotDifferent = false
        for _ in 0..<50 {
            vm.refreshMantra()
            if vm.currentMantra.quote != firstMantra {
                gotDifferent = true
                break
            }
        }

        XCTAssertTrue(gotDifferent, "Refreshing mantra should eventually produce a different quote")
    }

    // MARK: - Formatting Helper Tests

    func testFormatDuration() {
        let vm = MetalDashboardViewModel()
        XCTAssertEqual(vm.formatDuration(0), "0m")
        XCTAssertEqual(vm.formatDuration(300), "5m")
        XCTAssertEqual(vm.formatDuration(3600), "1h 0m")
        XCTAssertEqual(vm.formatDuration(5400), "1h 30m")
    }

    func testFormatTimeRemaining() {
        let vm = MetalDashboardViewModel()
        XCTAssertEqual(vm.formatTimeRemaining(0), "00:00")
        XCTAssertEqual(vm.formatTimeRemaining(90), "01:30")
        XCTAssertEqual(vm.formatTimeRemaining(1500), "25:00")
    }

    // MARK: - Icon Helper Tests

    func testIconForCategory() {
        let vm = MetalDashboardViewModel()
        XCTAssertEqual(vm.iconForCategory(.novel), "book.closed.fill")
        XCTAssertEqual(vm.iconForCategory(.poetry), "quote.bubble.fill")
        XCTAssertEqual(vm.iconForCategory(.screenplay), "film.fill")
    }

    func testIconForFocusType() {
        let vm = MetalDashboardViewModel()
        XCTAssertEqual(vm.iconForFocusType(FocusSessionType.freeWrite), "flame.fill")
        XCTAssertEqual(vm.iconForFocusType(FocusSessionType.pomodoro), "timer")
        XCTAssertEqual(vm.iconForFocusType(FocusSessionType.sprint), "bolt.fill")
        XCTAssertEqual(vm.iconForFocusType(FocusSessionType.deepWork), "moon.fill")
        XCTAssertEqual(vm.iconForFocusType(FocusSessionType.marathon), "flag.fill")
    }
    
    func testMarathonSessionType() {
        // Test marathon session properties
        XCTAssertEqual(FocusSessionType.marathon.displayName, "Marathon (120 min)")
        XCTAssertEqual(FocusSessionType.marathon.defaultDuration, 120 * 60)
        XCTAssertEqual(FocusSessionType.marathon.breakDuration, 20 * 60)
    }
    
    func testAllFocusSessionTypesHaveIcons() {
        let vm = MetalDashboardViewModel()
        for type in FocusSessionType.allCases {
            let icon = vm.iconForFocusType(type)
            XCTAssertFalse(icon.isEmpty, "Focus type \(type.rawValue) should have an icon")
        }
    }
}
#endif
