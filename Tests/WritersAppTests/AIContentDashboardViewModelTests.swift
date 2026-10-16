import XCTest
@testable import WritersApp

@MainActor
final class AIContentDashboardViewModelTests: XCTestCase {
    var viewModel: AIContentDashboardViewModel!
    var analyticsService: AIAnalyticsService!

    override func setUp() {
        super.setUp()
        analyticsService = AIAnalyticsService()
        viewModel = AIContentDashboardViewModel(analyticsService: analyticsService)
    }

    func testInitialState() {
        XCTAssertEqual(viewModel.snapshot.totalRequests, 0)
    }

    func testReload() {
        let record = AIGenerationRecord(
            timestamp: Date(),
            assistanceType: .improveText,
            inputTokens: 100,
            outputTokens: 150,
            model: .claude35Sonnet,
            status: .completed
        )
        analyticsService.trackGeneration(record)
        viewModel.reload()
        XCTAssertEqual(viewModel.snapshot.totalRequests, 1)
    }
}
