import XCTest
@testable import WritersApp

// MARK: - AdvisorCategory Tests

final class AdvisorCategoryTests: XCTestCase {

    // MARK: - CaseIterable

    func testAdvisorCategoryHasFiveCases() {
        XCTAssertEqual(AdvisorCategory.allCases.count, 5)
    }

    func testAdvisorCategoryAllCasesPresent() {
        let all = AdvisorCategory.allCases
        XCTAssertTrue(all.contains(.productivity))
        XCTAssertTrue(all.contains(.creativity))
        XCTAssertTrue(all.contains(.consistency))
        XCTAssertTrue(all.contains(.craft))
        XCTAssertTrue(all.contains(.goals))
    }

    // MARK: - displayName

    func testAdvisorCategoryDisplayNames() {
        XCTAssertEqual(AdvisorCategory.productivity.displayName, "Productivity")
        XCTAssertEqual(AdvisorCategory.creativity.displayName, "Creativity")
        XCTAssertEqual(AdvisorCategory.consistency.displayName, "Consistency")
        XCTAssertEqual(AdvisorCategory.craft.displayName, "Craft")
        XCTAssertEqual(AdvisorCategory.goals.displayName, "Goals")
    }

    func testAdvisorCategoryDisplayNamesAreNonEmpty() {
        for category in AdvisorCategory.allCases {
            XCTAssertFalse(category.displayName.isEmpty,
                "displayName must not be empty for \(category)")
        }
    }

    // MARK: - RawValue (String)

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
    }

    // MARK: - Codable

    func testAdvisorCategoryCodableRoundTrip() throws {
        for category in AdvisorCategory.allCases {
            let data = try JSONEncoder().encode(category)
            let decoded = try JSONDecoder().decode(AdvisorCategory.self, from: data)
            XCTAssertEqual(decoded, category, "Codable round-trip failed for \(category)")
        }
    }

    func testAdvisorCategoryDecodesFromWritingAdvisorPromptValues() throws {
        // The AI prompt schema uses these exact string values
        let json = "\"craft\"".data(using: .utf8)!
        let decoded = try JSONDecoder().decode(AdvisorCategory.self, from: json)
        XCTAssertEqual(decoded, .craft)
    }
}

// MARK: - AdvisorPriority Tests

final class AdvisorPriorityTests: XCTestCase {

    // MARK: - CaseIterable

    func testAdvisorPriorityHasThreeCases() {
        XCTAssertEqual(AdvisorPriority.allCases.count, 3)
    }

    func testAdvisorPriorityAllCasesPresent() {
        let all = AdvisorPriority.allCases
        XCTAssertTrue(all.contains(.high))
        XCTAssertTrue(all.contains(.medium))
        XCTAssertTrue(all.contains(.low))
    }

    // MARK: - RawValue

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
    }

    // MARK: - Codable

    func testAdvisorPriorityCodableRoundTrip() throws {
        for priority in AdvisorPriority.allCases {
            let data = try JSONEncoder().encode(priority)
            let decoded = try JSONDecoder().decode(AdvisorPriority.self, from: data)
            XCTAssertEqual(decoded, priority, "Codable round-trip failed for \(priority)")
        }
    }
}

// MARK: - AdvisorRecommendation Tests

final class AdvisorRecommendationTests: XCTestCase {

    // MARK: - Initialization

    func testAdvisorRecommendationDefaultIdIsUnique() {
        let r1 = AdvisorRecommendation(
            category: .craft, priority: .high,
            title: "A", recommendation: "B", actionableSteps: []
        )
        let r2 = AdvisorRecommendation(
            category: .craft, priority: .high,
            title: "A", recommendation: "B", actionableSteps: []
        )
        XCTAssertNotEqual(r1.id, r2.id, "Default ids must differ between instances")
    }

    func testAdvisorRecommendationExplicitIdIsPreserved() {
        let fixedId = UUID()
        let rec = AdvisorRecommendation(
            id: fixedId,
            category: .goals,
            priority: .medium,
            title: "Write daily",
            recommendation: "Consistency is key",
            actionableSteps: ["Set a timer", "Open your editor"]
        )
        XCTAssertEqual(rec.id, fixedId)
        XCTAssertEqual(rec.category, .goals)
        XCTAssertEqual(rec.priority, .medium)
        XCTAssertEqual(rec.title, "Write daily")
        XCTAssertEqual(rec.recommendation, "Consistency is key")
        XCTAssertEqual(rec.actionableSteps.count, 2)
        XCTAssertEqual(rec.actionableSteps[0], "Set a timer")
        XCTAssertEqual(rec.actionableSteps[1], "Open your editor")
    }

    func testAdvisorRecommendationDefaultGeneratedAt() {
        let before = Date()
        let rec = AdvisorRecommendation(
            category: .productivity, priority: .low,
            title: "T", recommendation: "R", actionableSteps: []
        )
        let after = Date()
        XCTAssertGreaterThanOrEqual(rec.generatedAt, before)
        XCTAssertLessThanOrEqual(rec.generatedAt, after)
    }

    func testAdvisorRecommendationEmptyActionableSteps() {
        let rec = AdvisorRecommendation(
            category: .creativity, priority: .low,
            title: "Freewrite", recommendation: "Just write without stopping",
            actionableSteps: []
        )
        XCTAssertTrue(rec.actionableSteps.isEmpty)
    }

    func testAdvisorRecommendationManyActionableSteps() {
        let steps = ["Step 1", "Step 2", "Step 3", "Step 4", "Step 5"]
        let rec = AdvisorRecommendation(
            category: .consistency, priority: .high,
            title: "Build a habit", recommendation: "Small steps every day",
            actionableSteps: steps
        )
        XCTAssertEqual(rec.actionableSteps, steps)
    }

    // MARK: - Identifiable

    func testAdvisorRecommendationConformsToIdentifiable() {
        let rec = AdvisorRecommendation(
            category: .craft, priority: .high,
            title: "T", recommendation: "R", actionableSteps: []
        )
        // Identifiable requires an `id` property; verify it matches what we set
        let knownId = UUID()
        let recWithId = AdvisorRecommendation(
            id: knownId, category: .craft, priority: .high,
            title: "T", recommendation: "R", actionableSteps: []
        )
        XCTAssertEqual(recWithId.id, knownId)
    }

    // MARK: - Codable

    func testAdvisorRecommendationCodableRoundTrip() throws {
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
        let original = AdvisorRecommendation(
            id: UUID(uuidString: "AAAAAAAA-1111-2222-3333-444444444444")!,
            category: .productivity,
            priority: .high,
            title: "Block distraction time",
            recommendation: "Use focused writing blocks",
            actionableSteps: ["Turn off notifications", "Set 25-min timer"],
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
        XCTAssertEqual(decoded.generatedAt.timeIntervalSince1970,
                       original.generatedAt.timeIntervalSince1970,
                       accuracy: 1.0)
    }

    func testAdvisorRecommendationDecodesAllCategoryValues() throws {
        for category in AdvisorCategory.allCases {
            let rec = AdvisorRecommendation(
                category: category, priority: .medium,
                title: "T", recommendation: "R", actionableSteps: []
            )
            let data = try JSONEncoder().encode(rec)
            let decoded = try JSONDecoder().decode(AdvisorRecommendation.self, from: data)
            XCTAssertEqual(decoded.category, category)
        }
    }

    func testAdvisorRecommendationDecodesAllPriorityValues() throws {
        for priority in AdvisorPriority.allCases {
            let rec = AdvisorRecommendation(
                category: .craft, priority: priority,
                title: "T", recommendation: "R", actionableSteps: []
            )
            let data = try JSONEncoder().encode(rec)
            let decoded = try JSONDecoder().decode(AdvisorRecommendation.self, from: data)
            XCTAssertEqual(decoded.priority, priority)
        }
    }
}

// MARK: - WritingAdvisorReport Tests

final class WritingAdvisorReportTests: XCTestCase {

    private func makeRec(
        category: AdvisorCategory = .craft,
        priority: AdvisorPriority = .medium
    ) -> AdvisorRecommendation {
        AdvisorRecommendation(
            category: category, priority: priority,
            title: "Rec \(category.rawValue)",
            recommendation: "Do this",
            actionableSteps: ["Step 1"]
        )
    }

    // MARK: - Initialization

    func testWritingAdvisorReportInit() {
        let recs = [makeRec(category: .craft), makeRec(category: .goals)]
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
        let report = WritingAdvisorReport(
            recommendations: recs,
            overallAssessment: "Strong progress overall",
            focusArea: .consistency,
            generatedAt: fixedDate
        )
        XCTAssertEqual(report.recommendations.count, 2)
        XCTAssertEqual(report.overallAssessment, "Strong progress overall")
        XCTAssertEqual(report.focusArea, .consistency)
        XCTAssertEqual(report.generatedAt.timeIntervalSince1970, fixedDate.timeIntervalSince1970,
                       accuracy: 1.0)
    }

    func testWritingAdvisorReportDefaultGeneratedAt() {
        let before = Date()
        let report = WritingAdvisorReport(
            recommendations: [],
            overallAssessment: "Good",
            focusArea: .productivity
        )
        let after = Date()
        XCTAssertGreaterThanOrEqual(report.generatedAt, before)
        XCTAssertLessThanOrEqual(report.generatedAt, after)
    }

    func testWritingAdvisorReportEmptyRecommendations() {
        let report = WritingAdvisorReport(
            recommendations: [],
            overallAssessment: "Not enough data",
            focusArea: .goals
        )
        XCTAssertTrue(report.recommendations.isEmpty)
    }

    func testWritingAdvisorReportMaxRecommendations() {
        // Reports can hold multiple recommendations (5 as per prompt schema)
        let recs = AdvisorCategory.allCases.map { makeRec(category: $0) }
        let report = WritingAdvisorReport(
            recommendations: recs,
            overallAssessment: "Comprehensive feedback",
            focusArea: .productivity
        )
        XCTAssertEqual(report.recommendations.count, 5)
    }

    // MARK: - Codable

    func testWritingAdvisorReportCodableRoundTrip() throws {
        let fixedDate = Date(timeIntervalSince1970: 1_710_000_000)
        let recs = [
            makeRec(category: .craft, priority: .high),
            makeRec(category: .productivity, priority: .low)
        ]
        let original = WritingAdvisorReport(
            recommendations: recs,
            overallAssessment: "Excellent work ethic",
            focusArea: .craft,
            generatedAt: fixedDate
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(WritingAdvisorReport.self, from: data)

        XCTAssertEqual(decoded.recommendations.count, original.recommendations.count)
        XCTAssertEqual(decoded.overallAssessment, original.overallAssessment)
        XCTAssertEqual(decoded.focusArea, original.focusArea)
        XCTAssertEqual(decoded.generatedAt.timeIntervalSince1970,
                       original.generatedAt.timeIntervalSince1970,
                       accuracy: 1.0)
    }

    func testWritingAdvisorReportCodablePreservesRecommendationOrder() throws {
        let recs = AdvisorCategory.allCases.map { makeRec(category: $0) }
        let original = WritingAdvisorReport(
            recommendations: recs,
            overallAssessment: "Good",
            focusArea: .goals
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(WritingAdvisorReport.self, from: data)

        let originalCategories = original.recommendations.map { $0.category }
        let decodedCategories = decoded.recommendations.map { $0.category }
        XCTAssertEqual(decodedCategories, originalCategories)
    }

    func testWritingAdvisorReportDecodesFromWritingAdvisorJsonPayload() throws {
        // Simulates the JSON schema emitted by the `writingAdvisor` AI prompt
        let jsonString = """
        {
          "overallAssessment": "You are writing consistently but need to diversify genres.",
          "focusArea": "creativity",
          "recommendations": [
            {
              "id": "AAAAAAAA-0000-0000-0000-000000000001",
              "category": "creativity",
              "priority": "high",
              "title": "Try a new genre",
              "recommendation": "Experiment with something outside your comfort zone.",
              "actionableSteps": ["Pick a genre you rarely read", "Write a short piece in it"],
              "generatedAt": 1700000000
            }
          ],
          "generatedAt": 1700000000
        }
        """
        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let report = try decoder.decode(WritingAdvisorReport.self, from: data)

        XCTAssertEqual(report.focusArea, .creativity)
        XCTAssertEqual(report.recommendations.count, 1)
        XCTAssertEqual(report.recommendations[0].category, .creativity)
        XCTAssertEqual(report.recommendations[0].priority, .high)
        XCTAssertEqual(report.recommendations[0].actionableSteps.count, 2)
    }
}

// MARK: - AdvisorContext Tests

final class AdvisorContextTests: XCTestCase {

    // MARK: - Initialization

    func testAdvisorContextInitWithAllFields() {
        let stats = SessionStats(
            totalSessions: 10,
            totalDurationSeconds: 3600,
            averageDurationSeconds: 360,
            earliestSession: Date(timeIntervalSince1970: 1_000_000),
            latestSession: Date(timeIntervalSince1970: 1_100_000)
        )
        let context = AdvisorContext(
            totalDocuments: 5,
            recentDocumentTitles: ["My Novel", "Short Story 1"],
            totalWordsAcrossDocuments: 15_000,
            documentCategories: ["novel", "short-story"],
            sessionStats: stats,
            additionalNotes: "Prefers morning writing"
        )

        XCTAssertEqual(context.totalDocuments, 5)
        XCTAssertEqual(context.recentDocumentTitles, ["My Novel", "Short Story 1"])
        XCTAssertEqual(context.totalWordsAcrossDocuments, 15_000)
        XCTAssertEqual(context.documentCategories, ["novel", "short-story"])
        XCTAssertNotNil(context.sessionStats)
        XCTAssertEqual(context.sessionStats?.totalSessions, 10)
        XCTAssertEqual(context.additionalNotes, "Prefers morning writing")
    }

    func testAdvisorContextInitWithNilSessionStats() {
        let context = AdvisorContext(
            totalDocuments: 0,
            recentDocumentTitles: [],
            totalWordsAcrossDocuments: 0,
            documentCategories: [],
            sessionStats: nil
        )
        XCTAssertNil(context.sessionStats)
        XCTAssertNil(context.additionalNotes)
    }

    func testAdvisorContextDefaultAdditionalNotesIsNil() {
        let context = AdvisorContext(
            totalDocuments: 3,
            recentDocumentTitles: ["Doc A"],
            totalWordsAcrossDocuments: 2000,
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

    func testAdvisorContextPreservesDocumentTitleOrder() {
        let titles = ["Third Draft", "First Draft", "Outline", "Final"]
        let context = AdvisorContext(
            totalDocuments: 4,
            recentDocumentTitles: titles,
            totalWordsAcrossDocuments: 10_000,
            documentCategories: ["novel"],
            sessionStats: nil
        )
        XCTAssertEqual(context.recentDocumentTitles, titles)
    }

    func testAdvisorContextWithLargeWordCount() {
        let context = AdvisorContext(
            totalDocuments: 100,
            recentDocumentTitles: Array(repeating: "Long Novel", count: 10),
            totalWordsAcrossDocuments: 1_000_000,
            documentCategories: ["novel"],
            sessionStats: nil
        )
        XCTAssertEqual(context.totalWordsAcrossDocuments, 1_000_000)
        XCTAssertEqual(context.totalDocuments, 100)
    }
}