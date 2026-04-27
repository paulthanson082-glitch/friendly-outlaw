import XCTest
@testable import WritersApp

// MARK: - AdvisorCategory Tests

final class AdvisorCategoryTests: XCTestCase {

    func testAllCasesCount() {
        XCTAssertEqual(AdvisorCategory.allCases.count, 5)
    }

    func testAllCasesContainsExpectedValues() {
        let expected: Set<AdvisorCategory> = [.productivity, .creativity, .consistency, .craft, .goals]
        XCTAssertEqual(Set(AdvisorCategory.allCases), expected)
    }

    func testDisplayNameProductivity() {
        XCTAssertEqual(AdvisorCategory.productivity.displayName, "Productivity")
    }

    func testDisplayNameCreativity() {
        XCTAssertEqual(AdvisorCategory.creativity.displayName, "Creativity")
    }

    func testDisplayNameConsistency() {
        XCTAssertEqual(AdvisorCategory.consistency.displayName, "Consistency")
    }

    func testDisplayNameCraft() {
        XCTAssertEqual(AdvisorCategory.craft.displayName, "Craft")
    }

    func testDisplayNameGoals() {
        XCTAssertEqual(AdvisorCategory.goals.displayName, "Goals")
    }

    func testRawValueProductivity() {
        XCTAssertEqual(AdvisorCategory.productivity.rawValue, "productivity")
    }

    func testRawValueCreativity() {
        XCTAssertEqual(AdvisorCategory.creativity.rawValue, "creativity")
    }

    func testRawValueConsistency() {
        XCTAssertEqual(AdvisorCategory.consistency.rawValue, "consistency")
    }

    func testRawValueCraft() {
        XCTAssertEqual(AdvisorCategory.craft.rawValue, "craft")
    }

    func testRawValueGoals() {
        XCTAssertEqual(AdvisorCategory.goals.rawValue, "goals")
    }

    func testInitFromRawValue() {
        XCTAssertEqual(AdvisorCategory(rawValue: "productivity"), .productivity)
        XCTAssertEqual(AdvisorCategory(rawValue: "creativity"), .creativity)
        XCTAssertEqual(AdvisorCategory(rawValue: "consistency"), .consistency)
        XCTAssertEqual(AdvisorCategory(rawValue: "craft"), .craft)
        XCTAssertEqual(AdvisorCategory(rawValue: "goals"), .goals)
    }

    func testInitFromInvalidRawValueReturnsNil() {
        XCTAssertNil(AdvisorCategory(rawValue: "invalid"))
        XCTAssertNil(AdvisorCategory(rawValue: "Productivity"))
        XCTAssertNil(AdvisorCategory(rawValue: ""))
    }

    func testCodableRoundTrip() throws {
        for category in AdvisorCategory.allCases {
            let data = try JSONEncoder().encode(category)
            let decoded = try JSONDecoder().decode(AdvisorCategory.self, from: data)
            XCTAssertEqual(decoded, category, "\(category) must survive JSON encode/decode")
        }
    }

    func testDisplayNameMatchesCapitalizedRawValue() {
        // Each displayName must be the capitalized form of the raw value
        for category in AdvisorCategory.allCases {
            let expected = category.rawValue.prefix(1).uppercased() + category.rawValue.dropFirst()
            XCTAssertEqual(category.displayName, expected,
                "displayName for .\(category) must be capitalized rawValue")
        }
    }
}

// MARK: - AdvisorPriority Tests

final class AdvisorPriorityTests: XCTestCase {

    func testAllCasesCount() {
        XCTAssertEqual(AdvisorPriority.allCases.count, 3)
    }

    func testAllCasesContainsExpectedValues() {
        let expected: Set<AdvisorPriority> = [.high, .medium, .low]
        XCTAssertEqual(Set(AdvisorPriority.allCases), expected)
    }

    func testRawValueHigh() {
        XCTAssertEqual(AdvisorPriority.high.rawValue, "high")
    }

    func testRawValueMedium() {
        XCTAssertEqual(AdvisorPriority.medium.rawValue, "medium")
    }

    func testRawValueLow() {
        XCTAssertEqual(AdvisorPriority.low.rawValue, "low")
    }

    func testInitFromRawValue() {
        XCTAssertEqual(AdvisorPriority(rawValue: "high"), .high)
        XCTAssertEqual(AdvisorPriority(rawValue: "medium"), .medium)
        XCTAssertEqual(AdvisorPriority(rawValue: "low"), .low)
    }

    func testInitFromInvalidRawValueReturnsNil() {
        XCTAssertNil(AdvisorPriority(rawValue: "urgent"))
        XCTAssertNil(AdvisorPriority(rawValue: "High"))
        XCTAssertNil(AdvisorPriority(rawValue: ""))
    }

    func testCodableRoundTrip() throws {
        for priority in AdvisorPriority.allCases {
            let data = try JSONEncoder().encode(priority)
            let decoded = try JSONDecoder().decode(AdvisorPriority.self, from: data)
            XCTAssertEqual(decoded, priority, "\(priority) must survive JSON encode/decode")
        }
    }
}

// MARK: - AdvisorRecommendation Tests

final class AdvisorRecommendationTests: XCTestCase {

    func testInitWithExplicitId() {
        let fixedId = UUID()
        let rec = AdvisorRecommendation(
            id: fixedId,
            category: .productivity,
            priority: .high,
            title: "Write Every Day",
            recommendation: "Consistency builds habits.",
            actionableSteps: ["Set a timer", "Close social media"],
            generatedAt: Date()
        )
        XCTAssertEqual(rec.id, fixedId)
    }

    func testInitWithDefaultIdGeneratesUUID() {
        let rec = AdvisorRecommendation(
            category: .craft,
            priority: .medium,
            title: "Vary Sentence Length",
            recommendation: "Mix short and long sentences.",
            actionableSteps: ["Read your draft aloud"],
            generatedAt: Date()
        )
        XCTAssertNotNil(rec.id)
    }

    func testTwoDefaultInitCallsProduceDifferentIds() {
        let rec1 = AdvisorRecommendation(category: .craft, priority: .low, title: "T1", recommendation: "R", actionableSteps: [])
        let rec2 = AdvisorRecommendation(category: .craft, priority: .low, title: "T2", recommendation: "R", actionableSteps: [])
        XCTAssertNotEqual(rec1.id, rec2.id)
    }

    func testInitStoresCategory() {
        let rec = AdvisorRecommendation(
            category: .creativity,
            priority: .low,
            title: "T",
            recommendation: "R",
            actionableSteps: [],
            generatedAt: Date()
        )
        XCTAssertEqual(rec.category, .creativity)
    }

    func testInitStoresPriority() {
        let rec = AdvisorRecommendation(
            category: .goals,
            priority: .high,
            title: "T",
            recommendation: "R",
            actionableSteps: [],
            generatedAt: Date()
        )
        XCTAssertEqual(rec.priority, .high)
    }

    func testInitStoresTitle() {
        let rec = AdvisorRecommendation(
            category: .consistency,
            priority: .medium,
            title: "Track Your Progress",
            recommendation: "Use a spreadsheet.",
            actionableSteps: [],
            generatedAt: Date()
        )
        XCTAssertEqual(rec.title, "Track Your Progress")
    }

    func testInitStoresRecommendation() {
        let rec = AdvisorRecommendation(
            category: .craft,
            priority: .high,
            title: "Title",
            recommendation: "Edit ruthlessly.",
            actionableSteps: [],
            generatedAt: Date()
        )
        XCTAssertEqual(rec.recommendation, "Edit ruthlessly.")
    }

    func testInitStoresActionableSteps() {
        let steps = ["Step one", "Step two", "Step three"]
        let rec = AdvisorRecommendation(
            category: .productivity,
            priority: .low,
            title: "T",
            recommendation: "R",
            actionableSteps: steps,
            generatedAt: Date()
        )
        XCTAssertEqual(rec.actionableSteps, steps)
    }

    func testInitWithEmptyActionableSteps() {
        let rec = AdvisorRecommendation(
            category: .goals,
            priority: .medium,
            title: "T",
            recommendation: "R",
            actionableSteps: [],
            generatedAt: Date()
        )
        XCTAssertTrue(rec.actionableSteps.isEmpty)
    }

    func testInitStoresGeneratedAt() {
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
        let rec = AdvisorRecommendation(
            category: .creativity,
            priority: .high,
            title: "T",
            recommendation: "R",
            actionableSteps: [],
            generatedAt: fixedDate
        )
        XCTAssertEqual(rec.generatedAt, fixedDate)
    }

    func testDefaultGeneratedAtIsNearNow() {
        let before = Date()
        let rec = AdvisorRecommendation(category: .craft, priority: .low, title: "T", recommendation: "R", actionableSteps: [])
        let after = Date()
        XCTAssertGreaterThanOrEqual(rec.generatedAt, before)
        XCTAssertLessThanOrEqual(rec.generatedAt, after)
    }

    func testCodableRoundTrip() throws {
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
        let original = AdvisorRecommendation(
            id: UUID(),
            category: .craft,
            priority: .high,
            title: "Sentence Variation",
            recommendation: "Vary your sentence length.",
            actionableSteps: ["Read aloud", "Mark long sentences"],
            generatedAt: fixedDate
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AdvisorRecommendation.self, from: data)
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.category, original.category)
        XCTAssertEqual(decoded.priority, original.priority)
        XCTAssertEqual(decoded.title, original.title)
        XCTAssertEqual(decoded.recommendation, original.recommendation)
        XCTAssertEqual(decoded.actionableSteps, original.actionableSteps)
        XCTAssertEqual(decoded.generatedAt.timeIntervalSinceReferenceDate,
                       original.generatedAt.timeIntervalSinceReferenceDate,
                       accuracy: 0.001)
    }

    func testIdentifiableIdMatchesStoredId() {
        let fixedId = UUID()
        let rec = AdvisorRecommendation(
            id: fixedId,
            category: .productivity,
            priority: .low,
            title: "T",
            recommendation: "R",
            actionableSteps: [],
            generatedAt: Date()
        )
        XCTAssertEqual(rec.id, fixedId, "Identifiable.id must equal the stored id")
    }

    func testCodablePreservesActionableStepsOrder() throws {
        let steps = ["First step", "Second step", "Third step"]
        let original = AdvisorRecommendation(
            category: .goals, priority: .medium, title: "T", recommendation: "R",
            actionableSteps: steps, generatedAt: Date(timeIntervalSince1970: 0)
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AdvisorRecommendation.self, from: data)
        XCTAssertEqual(decoded.actionableSteps, steps, "Actionable steps order must be preserved after round-trip")
    }
}

// MARK: - WritingAdvisorReport Tests

final class WritingAdvisorReportTests: XCTestCase {

    private func makeRecommendation(
        category: AdvisorCategory = .productivity,
        priority: AdvisorPriority = .medium
    ) -> AdvisorRecommendation {
        AdvisorRecommendation(
            category: category,
            priority: priority,
            title: "Test Recommendation",
            recommendation: "Do this.",
            actionableSteps: ["Step A"],
            generatedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
    }

    func testInitStoresRecommendations() {
        let recs = [makeRecommendation(), makeRecommendation(category: .craft)]
        let report = WritingAdvisorReport(
            recommendations: recs,
            overallAssessment: "Good progress",
            focusArea: .productivity,
            generatedAt: Date()
        )
        XCTAssertEqual(report.recommendations.count, 2)
    }

    func testInitWithEmptyRecommendations() {
        let report = WritingAdvisorReport(
            recommendations: [],
            overallAssessment: "No data yet",
            focusArea: .goals,
            generatedAt: Date()
        )
        XCTAssertTrue(report.recommendations.isEmpty)
    }

    func testInitStoresOverallAssessment() {
        let report = WritingAdvisorReport(
            recommendations: [],
            overallAssessment: "You are making excellent progress on your novel.",
            focusArea: .creativity,
            generatedAt: Date()
        )
        XCTAssertEqual(report.overallAssessment, "You are making excellent progress on your novel.")
    }

    func testInitStoresFocusArea() {
        let report = WritingAdvisorReport(
            recommendations: [],
            overallAssessment: "Assessment",
            focusArea: .consistency,
            generatedAt: Date()
        )
        XCTAssertEqual(report.focusArea, .consistency)
    }

    func testInitStoresGeneratedAt() {
        let fixedDate = Date(timeIntervalSince1970: 1_600_000_000)
        let report = WritingAdvisorReport(
            recommendations: [],
            overallAssessment: "Assessment",
            focusArea: .craft,
            generatedAt: fixedDate
        )
        XCTAssertEqual(report.generatedAt, fixedDate)
    }

    func testDefaultGeneratedAtIsNearNow() {
        let before = Date()
        let report = WritingAdvisorReport(
            recommendations: [],
            overallAssessment: "Assessment",
            focusArea: .productivity
        )
        let after = Date()
        XCTAssertGreaterThanOrEqual(report.generatedAt, before)
        XCTAssertLessThanOrEqual(report.generatedAt, after)
    }

    func testCodableRoundTrip() throws {
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
        let rec = makeRecommendation(category: .goals, priority: .high)
        let original = WritingAdvisorReport(
            recommendations: [rec],
            overallAssessment: "Strong foundation",
            focusArea: .goals,
            generatedAt: fixedDate
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(WritingAdvisorReport.self, from: data)
        XCTAssertEqual(decoded.recommendations.count, 1)
        XCTAssertEqual(decoded.recommendations[0].category, .goals)
        XCTAssertEqual(decoded.overallAssessment, original.overallAssessment)
        XCTAssertEqual(decoded.focusArea, original.focusArea)
        XCTAssertEqual(decoded.generatedAt.timeIntervalSinceReferenceDate,
                       original.generatedAt.timeIntervalSinceReferenceDate,
                       accuracy: 0.001)
    }

    func testCodableRoundTripWithMultipleRecommendations() throws {
        let recs = [
            makeRecommendation(category: .productivity, priority: .high),
            makeRecommendation(category: .creativity, priority: .medium),
            makeRecommendation(category: .craft, priority: .low)
        ]
        let original = WritingAdvisorReport(
            recommendations: recs,
            overallAssessment: "Mixed results",
            focusArea: .creativity,
            generatedAt: Date()
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(WritingAdvisorReport.self, from: data)
        XCTAssertEqual(decoded.recommendations.count, 3)
        XCTAssertEqual(decoded.recommendations[0].priority, .high)
        XCTAssertEqual(decoded.recommendations[1].category, .creativity)
        XCTAssertEqual(decoded.recommendations[2].priority, .low)
    }

    func testRecommendationsOrderIsPreserved() throws {
        // Insert three recommendations in a known order and verify retrieval order
        let categories: [AdvisorCategory] = [.productivity, .craft, .goals]
        let recs = categories.map { makeRecommendation(category: $0) }
        let original = WritingAdvisorReport(recommendations: recs, overallAssessment: "OK", focusArea: .productivity)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(WritingAdvisorReport.self, from: data)
        for (idx, category) in categories.enumerated() {
            XCTAssertEqual(decoded.recommendations[idx].category, category)
        }
    }
}

// MARK: - AdvisorContext Tests

final class AdvisorContextTests: XCTestCase {

    func testInitStoresTotalDocuments() {
        let ctx = AdvisorContext(
            totalDocuments: 42,
            recentDocumentTitles: [],
            totalWordsAcrossDocuments: 0,
            documentCategories: [],
            sessionStats: nil
        )
        XCTAssertEqual(ctx.totalDocuments, 42)
    }

    func testInitStoresRecentDocumentTitles() {
        let titles = ["Chapter 1", "Chapter 2", "Introduction"]
        let ctx = AdvisorContext(
            totalDocuments: 3,
            recentDocumentTitles: titles,
            totalWordsAcrossDocuments: 5000,
            documentCategories: [],
            sessionStats: nil
        )
        XCTAssertEqual(ctx.recentDocumentTitles, titles)
    }

    func testInitStoresTotalWords() {
        let ctx = AdvisorContext(
            totalDocuments: 5,
            recentDocumentTitles: [],
            totalWordsAcrossDocuments: 120_000,
            documentCategories: [],
            sessionStats: nil
        )
        XCTAssertEqual(ctx.totalWordsAcrossDocuments, 120_000)
    }

    func testInitStoresDocumentCategories() {
        let categories = ["novel", "short-story", "screenplay"]
        let ctx = AdvisorContext(
            totalDocuments: 3,
            recentDocumentTitles: [],
            totalWordsAcrossDocuments: 0,
            documentCategories: categories,
            sessionStats: nil
        )
        XCTAssertEqual(ctx.documentCategories, categories)
    }

    func testInitWithNilSessionStats() {
        let ctx = AdvisorContext(
            totalDocuments: 0,
            recentDocumentTitles: [],
            totalWordsAcrossDocuments: 0,
            documentCategories: [],
            sessionStats: nil
        )
        XCTAssertNil(ctx.sessionStats)
    }

    func testInitWithSessionStats() {
        let stats = SessionStats(
            totalSessions: 10,
            totalDurationSeconds: 36000,
            averageDurationSeconds: 3600,
            earliestSession: nil,
            latestSession: nil
        )
        let ctx = AdvisorContext(
            totalDocuments: 5,
            recentDocumentTitles: [],
            totalWordsAcrossDocuments: 1000,
            documentCategories: [],
            sessionStats: stats
        )
        XCTAssertNotNil(ctx.sessionStats)
        XCTAssertEqual(ctx.sessionStats?.totalSessions, 10)
    }

    func testInitWithNilAdditionalNotes() {
        let ctx = AdvisorContext(
            totalDocuments: 1,
            recentDocumentTitles: [],
            totalWordsAcrossDocuments: 100,
            documentCategories: [],
            sessionStats: nil
        )
        XCTAssertNil(ctx.additionalNotes)
    }

    func testInitWithAdditionalNotes() {
        let ctx = AdvisorContext(
            totalDocuments: 1,
            recentDocumentTitles: [],
            totalWordsAcrossDocuments: 100,
            documentCategories: [],
            sessionStats: nil,
            additionalNotes: "User prefers fantasy genre."
        )
        XCTAssertEqual(ctx.additionalNotes, "User prefers fantasy genre.")
    }

    func testInitWithEmptyCollections() {
        let ctx = AdvisorContext(
            totalDocuments: 0,
            recentDocumentTitles: [],
            totalWordsAcrossDocuments: 0,
            documentCategories: [],
            sessionStats: nil
        )
        XCTAssertTrue(ctx.recentDocumentTitles.isEmpty)
        XCTAssertTrue(ctx.documentCategories.isEmpty)
    }

    func testInitWithZeroDocuments() {
        let ctx = AdvisorContext(
            totalDocuments: 0,
            recentDocumentTitles: [],
            totalWordsAcrossDocuments: 0,
            documentCategories: [],
            sessionStats: nil
        )
        XCTAssertEqual(ctx.totalDocuments, 0)
        XCTAssertEqual(ctx.totalWordsAcrossDocuments, 0)
    }

    func testRecentDocumentTitlesOrderIsPreserved() {
        let titles = ["Z Title", "A Title", "M Title"]
        let ctx = AdvisorContext(
            totalDocuments: 3,
            recentDocumentTitles: titles,
            totalWordsAcrossDocuments: 0,
            documentCategories: [],
            sessionStats: nil
        )
        // Order must be preserved as provided
        XCTAssertEqual(ctx.recentDocumentTitles[0], "Z Title")
        XCTAssertEqual(ctx.recentDocumentTitles[1], "A Title")
        XCTAssertEqual(ctx.recentDocumentTitles[2], "M Title")
    }
}