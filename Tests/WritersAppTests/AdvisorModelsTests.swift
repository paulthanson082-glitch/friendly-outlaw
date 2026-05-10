import XCTest
@testable import WritersApp

// MARK: - AdvisorCategory Tests

final class AdvisorCategoryModelTests: XCTestCase {

    // MARK: - CaseIterable

    func testAdvisorCategoryAllCasesCount() {
        XCTAssertEqual(AdvisorCategory.allCases.count, 5)
    }

    func testAdvisorCategoryAllCasesContainsExpected() {
        let expected: Set<AdvisorCategory> = [.productivity, .creativity, .consistency, .craft, .goals]
        XCTAssertEqual(Set(AdvisorCategory.allCases), expected)
    }

    // MARK: - Raw Values

    func testAdvisorCategoryRawValues() {
        XCTAssertEqual(AdvisorCategory.productivity.rawValue, "productivity")
        XCTAssertEqual(AdvisorCategory.creativity.rawValue, "creativity")
        XCTAssertEqual(AdvisorCategory.consistency.rawValue, "consistency")
        XCTAssertEqual(AdvisorCategory.craft.rawValue, "craft")
        XCTAssertEqual(AdvisorCategory.goals.rawValue, "goals")
    }

    func testAdvisorCategoryInitFromRawValue() {
        XCTAssertEqual(AdvisorCategory(rawValue: "productivity"), .productivity)
        XCTAssertEqual(AdvisorCategory(rawValue: "creativity"), .creativity)
        XCTAssertEqual(AdvisorCategory(rawValue: "consistency"), .consistency)
        XCTAssertEqual(AdvisorCategory(rawValue: "craft"), .craft)
        XCTAssertEqual(AdvisorCategory(rawValue: "goals"), .goals)
        XCTAssertNil(AdvisorCategory(rawValue: "unknown"))
        XCTAssertNil(AdvisorCategory(rawValue: "Productivity"))  // case-sensitive
    }

    // MARK: - Display Names

    func testAdvisorCategoryDisplayNames() {
        XCTAssertEqual(AdvisorCategory.productivity.displayName, "Productivity")
        XCTAssertEqual(AdvisorCategory.creativity.displayName, "Creativity")
        XCTAssertEqual(AdvisorCategory.consistency.displayName, "Consistency")
        XCTAssertEqual(AdvisorCategory.craft.displayName, "Craft")
        XCTAssertEqual(AdvisorCategory.goals.displayName, "Goals")
    }

    func testAdvisorCategoryDisplayNamesAreNonEmpty() {
        for category in AdvisorCategory.allCases {
            XCTAssertFalse(category.displayName.isEmpty, "\(category) displayName must not be empty")
        }
    }

    // MARK: - Codable

    func testAdvisorCategoryCodableRoundTrip() throws {
        for category in AdvisorCategory.allCases {
            let data = try JSONEncoder().encode(category)
            let decoded = try JSONDecoder().decode(AdvisorCategory.self, from: data)
            XCTAssertEqual(decoded, category, "Round-trip failed for \(category)")
        }
    }

    func testAdvisorCategoryDecodesFromRawValueString() throws {
        let json = "\"craft\"".data(using: .utf8)!
        let decoded = try JSONDecoder().decode(AdvisorCategory.self, from: json)
        XCTAssertEqual(decoded, .craft)
    }
}

// MARK: - AdvisorPriority Tests

final class AdvisorPriorityModelTests: XCTestCase {

    // MARK: - CaseIterable

    func testAdvisorPriorityAllCasesCount() {
        XCTAssertEqual(AdvisorPriority.allCases.count, 3)
    }

    func testAdvisorPriorityAllCasesContainsExpected() {
        let expected: Set<AdvisorPriority> = [.high, .medium, .low]
        XCTAssertEqual(Set(AdvisorPriority.allCases), expected)
    }

    // MARK: - Raw Values

    func testAdvisorPriorityRawValues() {
        XCTAssertEqual(AdvisorPriority.high.rawValue, "high")
        XCTAssertEqual(AdvisorPriority.medium.rawValue, "medium")
        XCTAssertEqual(AdvisorPriority.low.rawValue, "low")
    }

    func testAdvisorPriorityInitFromRawValue() {
        XCTAssertEqual(AdvisorPriority(rawValue: "high"), .high)
        XCTAssertEqual(AdvisorPriority(rawValue: "medium"), .medium)
        XCTAssertEqual(AdvisorPriority(rawValue: "low"), .low)
        XCTAssertNil(AdvisorPriority(rawValue: "critical"))
        XCTAssertNil(AdvisorPriority(rawValue: "High"))  // case-sensitive
    }

    // MARK: - Codable

    func testAdvisorPriorityCodableRoundTrip() throws {
        for priority in AdvisorPriority.allCases {
            let data = try JSONEncoder().encode(priority)
            let decoded = try JSONDecoder().decode(AdvisorPriority.self, from: data)
            XCTAssertEqual(decoded, priority, "Round-trip failed for \(priority)")
        }
    }
}

// MARK: - AdvisorRecommendation Tests

final class AdvisorRecommendationModelTests: XCTestCase {

    // MARK: - Initialization

    func testAdvisorRecommendationBasicInit() {
        let rec = AdvisorRecommendation(
            category: .productivity,
            priority: .high,
            title: "Write Every Day",
            recommendation: "Set a daily writing goal",
            actionableSteps: ["Open your document", "Write 500 words"]
        )
        XCTAssertEqual(rec.category, .productivity)
        XCTAssertEqual(rec.priority, .high)
        XCTAssertEqual(rec.title, "Write Every Day")
        XCTAssertEqual(rec.recommendation, "Set a daily writing goal")
        XCTAssertEqual(rec.actionableSteps.count, 2)
        XCTAssertEqual(rec.actionableSteps[0], "Open your document")
        XCTAssertEqual(rec.actionableSteps[1], "Write 500 words")
    }

    func testAdvisorRecommendationDefaultId() {
        let rec1 = AdvisorRecommendation(
            category: .craft,
            priority: .medium,
            title: "Rec 1",
            recommendation: "Text",
            actionableSteps: []
        )
        let rec2 = AdvisorRecommendation(
            category: .craft,
            priority: .medium,
            title: "Rec 1",
            recommendation: "Text",
            actionableSteps: []
        )
        XCTAssertNotEqual(rec1.id, rec2.id, "Default UUIDs must be unique")
    }

    func testAdvisorRecommendationCustomId() {
        let fixedId = UUID()
        let rec = AdvisorRecommendation(
            id: fixedId,
            category: .goals,
            priority: .low,
            title: "Goal Setting",
            recommendation: "Set SMART goals",
            actionableSteps: ["Define goal", "Set deadline"]
        )
        XCTAssertEqual(rec.id, fixedId)
    }

    func testAdvisorRecommendationEmptyActionableSteps() {
        let rec = AdvisorRecommendation(
            category: .creativity,
            priority: .low,
            title: "Free Write",
            recommendation: "Try free writing",
            actionableSteps: []
        )
        XCTAssertTrue(rec.actionableSteps.isEmpty)
    }

    func testAdvisorRecommendationManyActionableSteps() {
        let steps = (1...10).map { "Step \($0)" }
        let rec = AdvisorRecommendation(
            category: .consistency,
            priority: .high,
            title: "Build Habit",
            recommendation: "Build a writing habit",
            actionableSteps: steps
        )
        XCTAssertEqual(rec.actionableSteps.count, 10)
    }

    func testAdvisorRecommendationGeneratedAtDefaultsToNow() {
        let beforeCreation = Date()
        let rec = AdvisorRecommendation(
            category: .craft,
            priority: .medium,
            title: "Title",
            recommendation: "Rec",
            actionableSteps: []
        )
        let afterCreation = Date()
        XCTAssertGreaterThanOrEqual(rec.generatedAt, beforeCreation)
        XCTAssertLessThanOrEqual(rec.generatedAt, afterCreation)
    }

    func testAdvisorRecommendationCustomGeneratedAt() {
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
        let rec = AdvisorRecommendation(
            category: .productivity,
            priority: .high,
            title: "Title",
            recommendation: "Rec",
            actionableSteps: [],
            generatedAt: fixedDate
        )
        XCTAssertEqual(rec.generatedAt.timeIntervalSince1970, fixedDate.timeIntervalSince1970, accuracy: 0.001)
    }

    // MARK: - Identifiable

    func testAdvisorRecommendationIdentifiable() {
        let id = UUID()
        let rec = AdvisorRecommendation(
            id: id,
            category: .goals,
            priority: .low,
            title: "T",
            recommendation: "R",
            actionableSteps: []
        )
        XCTAssertEqual(rec.id, id)
    }

    // MARK: - Codable

    func testAdvisorRecommendationCodableRoundTrip() throws {
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
        let original = AdvisorRecommendation(
            id: UUID(),
            category: .craft,
            priority: .high,
            title: "Vivid Prose",
            recommendation: "Use more sensory detail",
            actionableSteps: ["Describe smells", "Add textures", "Include sounds"],
            generatedAt: fixedDate
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(AdvisorRecommendation.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.category, original.category)
        XCTAssertEqual(decoded.priority, original.priority)
        XCTAssertEqual(decoded.title, original.title)
        XCTAssertEqual(decoded.recommendation, original.recommendation)
        XCTAssertEqual(decoded.actionableSteps, original.actionableSteps)
        XCTAssertEqual(decoded.generatedAt.timeIntervalSince1970,
                       original.generatedAt.timeIntervalSince1970, accuracy: 1.0)
    }

    func testAdvisorRecommendationAllCategoriesEncodeDecode() throws {
        for category in AdvisorCategory.allCases {
            for priority in AdvisorPriority.allCases {
                let rec = AdvisorRecommendation(
                    category: category,
                    priority: priority,
                    title: "Test",
                    recommendation: "Rec",
                    actionableSteps: []
                )
                let data = try JSONEncoder().encode(rec)
                let decoded = try JSONDecoder().decode(AdvisorRecommendation.self, from: data)
                XCTAssertEqual(decoded.category, category)
                XCTAssertEqual(decoded.priority, priority)
            }
        }
    }

    // MARK: - Boundary

    func testAdvisorRecommendationWithUnicodeContent() {
        let rec = AdvisorRecommendation(
            category: .creativity,
            priority: .medium,
            title: "Créativité 🎨",
            recommendation: "Écrivez sans limites — 日本語もOK",
            actionableSteps: ["Step with emoji 🚀", "Unicode: αβγδ"]
        )
        XCTAssertEqual(rec.title, "Créativité 🎨")
        XCTAssertEqual(rec.actionableSteps[1], "Unicode: αβγδ")
    }
}

// MARK: - WritingAdvisorReport Tests

final class WritingAdvisorReportModelTests: XCTestCase {

    private func makeRecommendation(
        category: AdvisorCategory = .productivity,
        priority: AdvisorPriority = .medium
    ) -> AdvisorRecommendation {
        AdvisorRecommendation(
            category: category,
            priority: priority,
            title: "Tip for \(category.displayName)",
            recommendation: "Here is a \(priority.rawValue) recommendation",
            actionableSteps: ["Do this first", "Then this"]
        )
    }

    // MARK: - Initialization

    func testWritingAdvisorReportBasicInit() {
        let recs = [makeRecommendation(category: .craft, priority: .high)]
        let report = WritingAdvisorReport(
            recommendations: recs,
            overallAssessment: "Good progress overall",
            focusArea: .craft
        )
        XCTAssertEqual(report.recommendations.count, 1)
        XCTAssertEqual(report.overallAssessment, "Good progress overall")
        XCTAssertEqual(report.focusArea, .craft)
    }

    func testWritingAdvisorReportEmptyRecommendations() {
        let report = WritingAdvisorReport(
            recommendations: [],
            overallAssessment: "Nothing to report",
            focusArea: .consistency
        )
        XCTAssertTrue(report.recommendations.isEmpty)
    }

    func testWritingAdvisorReportMultipleRecommendations() {
        let recs = AdvisorCategory.allCases.map { makeRecommendation(category: $0) }
        let report = WritingAdvisorReport(
            recommendations: recs,
            overallAssessment: "Comprehensive advice",
            focusArea: .goals
        )
        XCTAssertEqual(report.recommendations.count, 5)
    }

    func testWritingAdvisorReportGeneratedAtDefaultsToNow() {
        let before = Date()
        let report = WritingAdvisorReport(
            recommendations: [],
            overallAssessment: "OK",
            focusArea: .productivity
        )
        let after = Date()
        XCTAssertGreaterThanOrEqual(report.generatedAt, before)
        XCTAssertLessThanOrEqual(report.generatedAt, after)
    }

    func testWritingAdvisorReportCustomGeneratedAt() {
        let fixedDate = Date(timeIntervalSince1970: 1_600_000_000)
        let report = WritingAdvisorReport(
            recommendations: [],
            overallAssessment: "OK",
            focusArea: .creativity,
            generatedAt: fixedDate
        )
        XCTAssertEqual(report.generatedAt.timeIntervalSince1970, fixedDate.timeIntervalSince1970, accuracy: 0.001)
    }

    // MARK: - Codable

    func testWritingAdvisorReportCodableRoundTrip() throws {
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
        let recs = [
            makeRecommendation(category: .productivity, priority: .high),
            makeRecommendation(category: .craft, priority: .low)
        ]
        let original = WritingAdvisorReport(
            recommendations: recs,
            overallAssessment: "You are making great strides",
            focusArea: .consistency,
            generatedAt: fixedDate
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let data = try encoder.encode(original)
        let decoded = try JSONDecoder().decode(WritingAdvisorReport.self, from: data)

        XCTAssertEqual(decoded.overallAssessment, original.overallAssessment)
        XCTAssertEqual(decoded.focusArea, original.focusArea)
        XCTAssertEqual(decoded.recommendations.count, 2)
        XCTAssertEqual(decoded.recommendations[0].category, .productivity)
        XCTAssertEqual(decoded.recommendations[1].category, .craft)
    }

    func testWritingAdvisorReportAllFocusAreasEncode() throws {
        for focusArea in AdvisorCategory.allCases {
            let report = WritingAdvisorReport(
                recommendations: [],
                overallAssessment: "OK",
                focusArea: focusArea
            )
            let data = try JSONEncoder().encode(report)
            let decoded = try JSONDecoder().decode(WritingAdvisorReport.self, from: data)
            XCTAssertEqual(decoded.focusArea, focusArea)
        }
    }

    // MARK: - Regression

    func testWritingAdvisorReportPreservesRecommendationOrder() throws {
        let categories: [AdvisorCategory] = [.goals, .creativity, .productivity, .craft, .consistency]
        let recs = categories.map { makeRecommendation(category: $0) }
        let report = WritingAdvisorReport(
            recommendations: recs,
            overallAssessment: "Ordered",
            focusArea: .productivity
        )
        let data = try JSONEncoder().encode(report)
        let decoded = try JSONDecoder().decode(WritingAdvisorReport.self, from: data)
        XCTAssertEqual(decoded.recommendations.map { $0.category }, categories)
    }
}

// MARK: - AdvisorContext Tests

final class AdvisorContextModelTests: XCTestCase {

    // MARK: - Initialization

    func testAdvisorContextBasicInit() {
        let stats = SessionStats(
            totalSessions: 10,
            totalDurationSeconds: 36000,
            averageDurationSeconds: 3600.0,
            earliestSession: Date(timeIntervalSince1970: 1_000_000),
            latestSession: Date(timeIntervalSince1970: 2_000_000)
        )
        let context = AdvisorContext(
            totalDocuments: 25,
            recentDocumentTitles: ["Novel Draft", "Blog Post"],
            totalWordsAcrossDocuments: 50000,
            documentCategories: ["novel", "blogPost"],
            sessionStats: stats,
            additionalNotes: "Uses iPad"
        )
        XCTAssertEqual(context.totalDocuments, 25)
        XCTAssertEqual(context.recentDocumentTitles, ["Novel Draft", "Blog Post"])
        XCTAssertEqual(context.totalWordsAcrossDocuments, 50000)
        XCTAssertEqual(context.documentCategories, ["novel", "blogPost"])
        XCTAssertNotNil(context.sessionStats)
        XCTAssertEqual(context.sessionStats?.totalSessions, 10)
        XCTAssertEqual(context.additionalNotes, "Uses iPad")
    }

    func testAdvisorContextWithNilSessionStats() {
        let context = AdvisorContext(
            totalDocuments: 0,
            recentDocumentTitles: [],
            totalWordsAcrossDocuments: 0,
            documentCategories: [],
            sessionStats: nil
        )
        XCTAssertNil(context.sessionStats)
    }

    func testAdvisorContextAdditionalNotesDefaultsToNil() {
        let context = AdvisorContext(
            totalDocuments: 5,
            recentDocumentTitles: ["Draft"],
            totalWordsAcrossDocuments: 1000,
            documentCategories: ["article"],
            sessionStats: nil
        )
        XCTAssertNil(context.additionalNotes)
    }

    func testAdvisorContextEmptyDocumentTitles() {
        let context = AdvisorContext(
            totalDocuments: 0,
            recentDocumentTitles: [],
            totalWordsAcrossDocuments: 0,
            documentCategories: [],
            sessionStats: nil
        )
        XCTAssertTrue(context.recentDocumentTitles.isEmpty)
        XCTAssertTrue(context.documentCategories.isEmpty)
        XCTAssertEqual(context.totalDocuments, 0)
        XCTAssertEqual(context.totalWordsAcrossDocuments, 0)
    }

    func testAdvisorContextWithManyTitles() {
        let titles = (1...20).map { "Document \($0)" }
        let context = AdvisorContext(
            totalDocuments: 20,
            recentDocumentTitles: titles,
            totalWordsAcrossDocuments: 100000,
            documentCategories: ["novel"],
            sessionStats: nil
        )
        XCTAssertEqual(context.recentDocumentTitles.count, 20)
        XCTAssertEqual(context.recentDocumentTitles.first, "Document 1")
        XCTAssertEqual(context.recentDocumentTitles.last, "Document 20")
    }

    func testAdvisorContextLargeWordCount() {
        let context = AdvisorContext(
            totalDocuments: 1,
            recentDocumentTitles: ["Epic Novel"],
            totalWordsAcrossDocuments: 500_000,
            documentCategories: ["novel"],
            sessionStats: nil
        )
        XCTAssertEqual(context.totalWordsAcrossDocuments, 500_000)
    }

    // MARK: - SessionStats integration

    func testAdvisorContextSessionStatsValues() {
        let stats = SessionStats(
            totalSessions: 3,
            totalDurationSeconds: 5400,
            averageDurationSeconds: 1800.0,
            earliestSession: Date(timeIntervalSince1970: 0),
            latestSession: Date(timeIntervalSince1970: 1_000_000)
        )
        let context = AdvisorContext(
            totalDocuments: 3,
            recentDocumentTitles: ["A", "B", "C"],
            totalWordsAcrossDocuments: 3000,
            documentCategories: ["article"],
            sessionStats: stats
        )
        XCTAssertEqual(context.sessionStats?.totalSessions, 3)
        XCTAssertEqual(context.sessionStats?.totalDurationSeconds, 5400)
        XCTAssertEqual(context.sessionStats?.averageDurationSeconds, 1800.0, accuracy: 0.001)
    }

    // MARK: - Boundary

    func testAdvisorContextWithUnicodeDocumentTitles() {
        let titles = ["日本語タイトル", "Título en español", "Ελληνικά 🎭"]
        let context = AdvisorContext(
            totalDocuments: 3,
            recentDocumentTitles: titles,
            totalWordsAcrossDocuments: 1500,
            documentCategories: ["other"],
            sessionStats: nil
        )
        XCTAssertEqual(context.recentDocumentTitles[0], "日本語タイトル")
        XCTAssertEqual(context.recentDocumentTitles[2], "Ελληνικά 🎭")
    }
}