// Tests/WritersAppTests/AIAnalyticsServiceTests.swift
import XCTest
@testable import WritersApp

class AIAnalyticsServiceTests: XCTestCase {
    var service: AIAnalyticsService!

    override func setUp() {
        super.setUp()
        service = AIAnalyticsService()
    }

    func testTrackGeneration() {
        let record = AIGenerationRecord(
            timestamp: Date(),
            assistanceType: .improveText,
            inputTokens: 100,
            outputTokens: 150,
            model: .claude35Sonnet,
            status: .completed
        )
        service.trackGeneration(record)
        let snapshot = service.getSnapshot()
        XCTAssertEqual(snapshot.totalRequests, 1)
        XCTAssertEqual(snapshot.totalTokens, 250)
    }

    func testGetSnapshot() {
        let snapshot = service.getSnapshot()
        XCTAssertGreaterThanOrEqual(snapshot.totalRequests, 0)
    }

    func testGetModelBreakdown() {
        let record1 = AIGenerationRecord(
            timestamp: Date(),
            assistanceType: .improveText,
            inputTokens: 100,
            outputTokens: 150,
            model: .claude35Sonnet,
            status: .completed
        )
        service.trackGeneration(record1)
        let breakdown = service.getModelBreakdown()
        XCTAssertGreaterThan(breakdown.count, 0)
    }

    func testGetTrends() {
        let trends = service.getTrends(days: 30)
        XCTAssertGreaterThanOrEqual(trends.count, 0)
    }

    func testGetRecentRecords() {
        let records = service.getRecentRecords(limit: 10)
        XCTAssertLessThanOrEqual(records.count, 10)
    }
}
