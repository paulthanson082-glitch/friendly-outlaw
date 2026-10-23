// Tests/WritersAppTests/AIAnalyticsModels+Tests.swift
import XCTest
@testable import WritersApp

class AIAnalyticsModelsTests: XCTestCase {
    func testAIGenerationRecordInitialization() {
        let record = AIGenerationRecord(
            id: UUID(),
            timestamp: Date(),
            assistanceType: .improveText,
            inputTokens: 100,
            outputTokens: 150,
            model: .claude35Sonnet,
            status: .completed,
            documentId: UUID()
        )
        XCTAssertEqual(record.inputTokens, 100)
        XCTAssertEqual(record.outputTokens, 150)
    }

    func testAIAnalyticsSnapshotCalculation() {
        let snapshot = AIAnalyticsSnapshot(
            totalRequests: 42,
            totalTokens: 15000,
            costEstimate: 0.45,
            requestsToday: 5,
            averageTokensPerRequest: 357
        )
        XCTAssertEqual(snapshot.totalRequests, 42)
    }

    func testModelUsageBreakdown() {
        let breakdown = ModelUsageBreakdown(
            model: .claude35Sonnet,
            requestCount: 30,
            tokenCount: 10000,
            percentage: 0.75
        )
        XCTAssertEqual(breakdown.percentage, 0.75)
    }
}
