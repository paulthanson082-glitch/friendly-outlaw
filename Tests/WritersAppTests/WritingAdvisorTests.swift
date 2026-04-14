import XCTest
@testable import WritersApp

// MARK: - AdvisorCategory Tests

final class AdvisorCategoryTests: XCTestCase {

    func testAdvisorCategoryRawValues() {
        XCTAssertEqual(AdvisorCategory.productivity.rawValue, "productivity")
        XCTAssertEqual(AdvisorCategory.creativity.rawValue, "creativity")
        XCTAssertEqual(AdvisorCategory.consistency.rawValue, "consistency")
        XCTAssertEqual(AdvisorCategory.craft.rawValue, "craft")
        XCTAssertEqual(AdvisorCategory.goals.rawValue, "goals")
    }

    func testAdvisorCategoryDisplayNames() {
        XCTAssertEqual(AdvisorCategory.productivity.displayName, "Productivity")
        XCTAssertEqual(AdvisorCategory.creativity.displayName, "Creativity")
        XCTAssertEqual(AdvisorCategory.consistency.displayName, "Consistency")
        XCTAssertEqual(AdvisorCategory.craft.displayName, "Craft")
        XCTAssertEqual(AdvisorCategory.goals.displayName, "Goals")
    }

    func testAdvisorCategoryInitFromRawValue() {
        XCTAssertEqual(AdvisorCategory(rawValue: "productivity"), .productivity)
        XCTAssertEqual(AdvisorCategory(rawValue: "creativity"), .creativity)
        XCTAssertEqual(AdvisorCategory(rawValue: "consistency"), .consistency)
        XCTAssertEqual(AdvisorCategory(rawValue: "craft"), .craft)
        XCTAssertEqual(AdvisorCategory(rawValue: "goals"), .goals)
    }

    func testAdvisorCategoryInitFromUnknownRawValueReturnsNil() {
        XCTAssertNil(AdvisorCategory(rawValue: "unknown"))
        XCTAssertNil(AdvisorCategory(rawValue: ""))
        XCTAssertNil(AdvisorCategory(rawValue: "Productivity"))  // case-sensitive
    }

    func testAdvisorCategoryCodableRoundTrip() throws {
        for category in AdvisorCategory.allCases {
            let encoded = try JSONEncoder().encode(category)
            let decoded = try JSONDecoder().decode(AdvisorCategory.self, from: encoded)
            XCTAssertEqual(decoded, category, "Codable round-trip failed for \(category.rawValue)")
        }
    }

    func testAdvisorCategoryAllCasesMatchRawValues() {
        let expectedRawValues: Set<String> = ["productivity", "creativity", "consistency", "craft", "goals"]
        let actualRawValues = Set(AdvisorCategory.allCases.map { $0.rawValue })
        XCTAssertEqual(actualRawValues, expectedRawValues)
    }
}

// MARK: - AdvisorPriority Tests

final class AdvisorPriorityTests: XCTestCase {

    func testAdvisorPriorityRawValues() {
        XCTAssertEqual(AdvisorPriority.high.rawValue, "high")
        XCTAssertEqual(AdvisorPriority.medium.rawValue, "medium")
        XCTAssertEqual(AdvisorPriority.low.rawValue, "low")
    }

    func testAdvisorPriorityInitFromRawValue() {
        XCTAssertEqual(AdvisorPriority(rawValue: "high"), .high)
        XCTAssertEqual(AdvisorPriority(rawValue: "medium"), .medium)
        XCTAssertEqual(AdvisorPriority(rawValue: "low"), .low)
    }

    func testAdvisorPriorityInitFromUnknownRawValueReturnsNil() {
        XCTAssertNil(AdvisorPriority(rawValue: "critical"))
        XCTAssertNil(AdvisorPriority(rawValue: ""))
        XCTAssertNil(AdvisorPriority(rawValue: "High"))  // case-sensitive
    }

    func testAdvisorPriorityCodableRoundTrip() throws {
        for priority in AdvisorPriority.allCases {
            let encoded = try JSONEncoder().encode(priority)
            let decoded = try JSONDecoder().decode(AdvisorPriority.self, from: encoded)
            XCTAssertEqual(decoded, priority, "Codable round-trip failed for \(priority.rawValue)")
        }
    }
}

// MARK: - AdvisorRecommendation Tests

final class AdvisorRecommendationTests: XCTestCase {

    func testAdvisorRecommendationDefaultIdIsUnique() {
        let rec1 = AdvisorRecommendation(
            category: .craft, priority: .high,
            title: "A", recommendation: "B", actionableSteps: []
        )
        let rec2 = AdvisorRecommendation(
            category: .craft, priority: .high,
            title: "A", recommendation: "B", actionableSteps: []
        )
        XCTAssertNotEqual(rec1.id, rec2.id,
                          "Two recommendations with default UUID must have distinct IDs")
    }

    func testAdvisorRecommendationExplicitIdIsPreserved() {
        let fixedId = UUID()
        let rec = AdvisorRecommendation(
            id: fixedId, category: .goals, priority: .low,
            title: "Title", recommendation: "Rec", actionableSteps: ["Step"]
        )
        XCTAssertEqual(rec.id, fixedId)
    }

    func testAdvisorRecommendationPropertiesStoredCorrectly() {
        let steps = ["Step 1", "Step 2", "Step 3"]
        let rec = AdvisorRecommendation(
            category: .creativity,
            priority: .medium,
            title: "Be Creative",
            recommendation: "Try free-writing for 10 minutes daily.",
            actionableSteps: steps
        )
        XCTAssertEqual(rec.category, .creativity)
        XCTAssertEqual(rec.priority, .medium)
        XCTAssertEqual(rec.title, "Be Creative")
        XCTAssertEqual(rec.recommendation, "Try free-writing for 10 minutes daily.")
        XCTAssertEqual(rec.actionableSteps, steps)
    }

    func testAdvisorRecommendationActionableStepsCanBeEmpty() {
        let rec = AdvisorRecommendation(
            category: .consistency, priority: .low,
            title: "T", recommendation: "R", actionableSteps: []
        )
        XCTAssertTrue(rec.actionableSteps.isEmpty)
    }

    func testAdvisorRecommendationCodablePreservesAllFields() throws {
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
        let fixedId = UUID()
        let original = AdvisorRecommendation(
            id: fixedId,
            category: .goals,
            priority: .high,
            title: "Finish the novel",
            recommendation: "Break the manuscript into weekly milestones.",
            actionableSteps: ["Outline chapters", "Write 2000 words/day", "Review weekly"],
            generatedAt: fixedDate
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AdvisorRecommendation.self, from: data)

        XCTAssertEqual(decoded.id, fixedId)
        XCTAssertEqual(decoded.category, .goals)
        XCTAssertEqual(decoded.priority, .high)
        XCTAssertEqual(decoded.title, "Finish the novel")
        XCTAssertEqual(decoded.recommendation, "Break the manuscript into weekly milestones.")
        XCTAssertEqual(decoded.actionableSteps, ["Outline chapters", "Write 2000 words/day", "Review weekly"])
    }

    func testAdvisorRecommendationGeneratedAtDefaultIsRecent() {
        let before = Date()
        let rec = AdvisorRecommendation(
            category: .productivity, priority: .high,
            title: "T", recommendation: "R", actionableSteps: []
        )
        let after = Date()
        XCTAssertGreaterThanOrEqual(rec.generatedAt, before)
        XCTAssertLessThanOrEqual(rec.generatedAt, after)
    }
}

// MARK: - WritingAdvisorReport Tests

final class WritingAdvisorReportTests: XCTestCase {

    func testWritingAdvisorReportPropertiesStoredCorrectly() {
        let rec = AdvisorRecommendation(
            category: .productivity, priority: .high,
            title: "T", recommendation: "R", actionableSteps: ["S"]
        )
        let report = WritingAdvisorReport(
            recommendations: [rec],
            overallAssessment: "Good progress.",
            focusArea: .productivity
        )
        XCTAssertEqual(report.recommendations.count, 1)
        XCTAssertEqual(report.overallAssessment, "Good progress.")
        XCTAssertEqual(report.focusArea, .productivity)
    }

    func testWritingAdvisorReportEmptyRecommendations() {
        let report = WritingAdvisorReport(
            recommendations: [],
            overallAssessment: "Just starting out.",
            focusArea: .consistency
        )
        XCTAssertTrue(report.recommendations.isEmpty)
        XCTAssertEqual(report.focusArea, .consistency)
    }

    func testWritingAdvisorReportGeneratedAtDefaultIsRecent() {
        let before = Date()
        let report = WritingAdvisorReport(
            recommendations: [], overallAssessment: "", focusArea: .craft
        )
        let after = Date()
        XCTAssertGreaterThanOrEqual(report.generatedAt, before)
        XCTAssertLessThanOrEqual(report.generatedAt, after)
    }

    func testWritingAdvisorReportCodablePreservesMultipleRecommendations() throws {
        let recs = [
            AdvisorRecommendation(
                category: .productivity, priority: .high,
                title: "Focus", recommendation: "Use pomodoro.", actionableSteps: ["25 min blocks"]
            ),
            AdvisorRecommendation(
                category: .craft, priority: .low,
                title: "Polish", recommendation: "Read aloud.", actionableSteps: ["Print draft"]
            )
        ]
        let report = WritingAdvisorReport(
            recommendations: recs,
            overallAssessment: "You are progressing well across multiple areas.",
            focusArea: .craft,
            generatedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )

        let data = try JSONEncoder().encode(report)
        let decoded = try JSONDecoder().decode(WritingAdvisorReport.self, from: data)

        XCTAssertEqual(decoded.recommendations.count, 2)
        XCTAssertEqual(decoded.overallAssessment, report.overallAssessment)
        XCTAssertEqual(decoded.focusArea, .craft)
        XCTAssertEqual(decoded.recommendations[0].title, "Focus")
        XCTAssertEqual(decoded.recommendations[1].title, "Polish")
    }
}

// MARK: - AdvisorContext Tests

final class AdvisorContextTests: XCTestCase {

    func testAdvisorContextPropertiesStoredCorrectly() {
        let stats = SessionStats(
            totalSessions: 10,
            totalDurationSeconds: 36000,
            averageDurationSeconds: 3600,
            earliestSession: nil,
            latestSession: nil
        )
        let ctx = AdvisorContext(
            totalDocuments: 5,
            recentDocumentTitles: ["Novel Ch1", "Short Story"],
            totalWordsAcrossDocuments: 12000,
            documentCategories: ["novel", "shortStory"],
            sessionStats: stats,
            additionalNotes: "Working on a sci-fi project"
        )

        XCTAssertEqual(ctx.totalDocuments, 5)
        XCTAssertEqual(ctx.recentDocumentTitles, ["Novel Ch1", "Short Story"])
        XCTAssertEqual(ctx.totalWordsAcrossDocuments, 12000)
        XCTAssertEqual(ctx.documentCategories, ["novel", "shortStory"])
        XCTAssertEqual(ctx.sessionStats?.totalSessions, 10)
        XCTAssertEqual(ctx.additionalNotes, "Working on a sci-fi project")
    }

    func testAdvisorContextOptionalFieldsCanBeNil() {
        let ctx = AdvisorContext(
            totalDocuments: 0,
            recentDocumentTitles: [],
            totalWordsAcrossDocuments: 0,
            documentCategories: [],
            sessionStats: nil,
            additionalNotes: nil
        )
        XCTAssertNil(ctx.sessionStats)
        XCTAssertNil(ctx.additionalNotes)
        XCTAssertTrue(ctx.recentDocumentTitles.isEmpty)
        XCTAssertTrue(ctx.documentCategories.isEmpty)
    }

    func testAdvisorContextAdditionalNotesDefaultsToNil() {
        let ctx = AdvisorContext(
            totalDocuments: 1,
            recentDocumentTitles: ["Doc"],
            totalWordsAcrossDocuments: 500,
            documentCategories: ["novel"],
            sessionStats: nil
        )
        XCTAssertNil(ctx.additionalNotes)
    }
}

// MARK: - WritingAdvisorService.buildContextText Tests

final class WritingAdvisorServiceContextBuildingTests: XCTestCase {

    private var service: WritingAdvisorService!

    override func setUp() {
        super.setUp()
        let config = AIConfiguration(apiKey: "test-key")
        service = WritingAdvisorService(aiService: AIService(configuration: config))
    }

    override func tearDown() {
        service = nil
        super.tearDown()
    }

    func testBuildContextTextAlwaysIncludesDocumentLine() {
        let ctx = AdvisorContext(
            totalDocuments: 3,
            recentDocumentTitles: [],
            totalWordsAcrossDocuments: 1500,
            documentCategories: [],
            sessionStats: nil
        )
        let text = service.buildContextText(from: ctx)
        XCTAssertTrue(text.contains("Documents: 3 total, 1500 words"),
                      "Context text must include document count and word total")
    }

    func testBuildContextTextIncludesRecentTitlesWhenPresent() {
        let ctx = AdvisorContext(
            totalDocuments: 2,
            recentDocumentTitles: ["Chapter One", "Prologue"],
            totalWordsAcrossDocuments: 4000,
            documentCategories: [],
            sessionStats: nil
        )
        let text = service.buildContextText(from: ctx)
        XCTAssertTrue(text.contains("\"Chapter One\""),
                      "Context text must quote recent document titles")
        XCTAssertTrue(text.contains("\"Prologue\""),
                      "Context text must quote all provided recent titles")
    }

    func testBuildContextTextOmitsTitleLineWhenEmpty() {
        let ctx = AdvisorContext(
            totalDocuments: 1,
            recentDocumentTitles: [],
            totalWordsAcrossDocuments: 300,
            documentCategories: [],
            sessionStats: nil
        )
        let text = service.buildContextText(from: ctx)
        XCTAssertFalse(text.contains("Recent titles:"),
                       "Context text must not include title line when there are no titles")
    }

    func testBuildContextTextIncludesCategoriesWhenPresent() {
        let ctx = AdvisorContext(
            totalDocuments: 2,
            recentDocumentTitles: [],
            totalWordsAcrossDocuments: 500,
            documentCategories: ["novel", "screenplay"],
            sessionStats: nil
        )
        let text = service.buildContextText(from: ctx)
        XCTAssertTrue(text.contains("Categories:"),
                      "Context text must include a categories line when categories are present")
        XCTAssertTrue(text.contains("novel"), "Context text must list the 'novel' category")
        XCTAssertTrue(text.contains("screenplay"), "Context text must list the 'screenplay' category")
    }

    func testBuildContextTextOmitsCategoryLineWhenEmpty() {
        let ctx = AdvisorContext(
            totalDocuments: 1,
            recentDocumentTitles: [],
            totalWordsAcrossDocuments: 0,
            documentCategories: [],
            sessionStats: nil
        )
        let text = service.buildContextText(from: ctx)
        XCTAssertFalse(text.contains("Categories:"),
                       "Context text must not include category line when there are no categories")
    }

    func testBuildContextTextIncludesSessionStatsWhenPresent() {
        let stats = SessionStats(
            totalSessions: 5,
            totalDurationSeconds: 9000,
            averageDurationSeconds: 1800,  // 30 minutes
            earliestSession: nil,
            latestSession: nil
        )
        let ctx = AdvisorContext(
            totalDocuments: 3,
            recentDocumentTitles: [],
            totalWordsAcrossDocuments: 600,
            documentCategories: [],
            sessionStats: stats
        )
        let text = service.buildContextText(from: ctx)
        XCTAssertTrue(text.contains("Sessions: 5 total"),
                      "Context text must include session count")
        XCTAssertTrue(text.contains("avg 30 min"),
                      "Context text must include average session duration in minutes")
    }

    func testBuildContextTextOmitsSessionLineWhenNoStats() {
        let ctx = AdvisorContext(
            totalDocuments: 1,
            recentDocumentTitles: [],
            totalWordsAcrossDocuments: 0,
            documentCategories: [],
            sessionStats: nil
        )
        let text = service.buildContextText(from: ctx)
        XCTAssertFalse(text.contains("Sessions:"),
                       "Context text must not include sessions line when stats are nil")
    }

    func testBuildContextTextIncludesAdditionalNotesWhenPresent() {
        let ctx = AdvisorContext(
            totalDocuments: 0,
            recentDocumentTitles: [],
            totalWordsAcrossDocuments: 0,
            documentCategories: [],
            sessionStats: nil,
            additionalNotes: "Trying to finish NaNoWriMo"
        )
        let text = service.buildContextText(from: ctx)
        XCTAssertTrue(text.contains("Additional context: Trying to finish NaNoWriMo"),
                      "Context text must include additional notes when provided")
    }

    func testBuildContextTextOmitsAdditionalNotesWhenNil() {
        let ctx = AdvisorContext(
            totalDocuments: 1,
            recentDocumentTitles: [],
            totalWordsAcrossDocuments: 0,
            documentCategories: [],
            sessionStats: nil,
            additionalNotes: nil
        )
        let text = service.buildContextText(from: ctx)
        XCTAssertFalse(text.contains("Additional context:"),
                       "Context text must not include additional context line when notes are nil")
    }

    func testBuildContextTextOmitsAdditionalNotesWhenEmpty() {
        let ctx = AdvisorContext(
            totalDocuments: 1,
            recentDocumentTitles: [],
            totalWordsAcrossDocuments: 0,
            documentCategories: [],
            sessionStats: nil,
            additionalNotes: ""
        )
        let text = service.buildContextText(from: ctx)
        XCTAssertFalse(text.contains("Additional context:"),
                       "Context text must not include additional context line when notes is empty string")
    }

    func testBuildContextTextLinesJoinedByNewline() {
        let stats = SessionStats(
            totalSessions: 2,
            totalDurationSeconds: 3600,
            averageDurationSeconds: 1800,
            earliestSession: nil,
            latestSession: nil
        )
        let ctx = AdvisorContext(
            totalDocuments: 2,
            recentDocumentTitles: ["Doc A"],
            totalWordsAcrossDocuments: 800,
            documentCategories: ["novel"],
            sessionStats: stats,
            additionalNotes: "Extra note"
        )
        let text = service.buildContextText(from: ctx)
        let lines = text.components(separatedBy: "\n")
        XCTAssertEqual(lines.count, 5,
                       "Context text must have exactly 5 lines when all sections are present")
    }

    func testBuildContextTextSessionAverageDurationRoundsDownToMinutes() {
        // 90 seconds = 1 min (integer truncation)
        let stats = SessionStats(
            totalSessions: 1,
            totalDurationSeconds: 90,
            averageDurationSeconds: 90,
            earliestSession: nil,
            latestSession: nil
        )
        let ctx = AdvisorContext(
            totalDocuments: 0,
            recentDocumentTitles: [],
            totalWordsAcrossDocuments: 0,
            documentCategories: [],
            sessionStats: stats
        )
        let text = service.buildContextText(from: ctx)
        XCTAssertTrue(text.contains("avg 1 min"),
                      "Context text must truncate average seconds to integer minutes")
    }

    func testBuildContextTextZeroDocumentsIsValid() {
        let ctx = AdvisorContext(
            totalDocuments: 0,
            recentDocumentTitles: [],
            totalWordsAcrossDocuments: 0,
            documentCategories: [],
            sessionStats: nil
        )
        let text = service.buildContextText(from: ctx)
        XCTAssertTrue(text.contains("Documents: 0 total, 0 words"))
    }
}

// MARK: - AIAssistanceType.writingAdvisor Tests

final class AIAssistanceTypeWritingAdvisorTests: XCTestCase {

    func testWritingAdvisorDisplayName() {
        XCTAssertEqual(AIAssistanceType.writingAdvisor.displayName, "Writing Advisor")
    }

    func testWritingAdvisorPromptContainsWriterData() {
        let writerData = "Documents: 10 total, 50000 words"
        let prompt = AIAssistanceType.writingAdvisor.prompt(for: writerData)
        XCTAssertTrue(prompt.contains(writerData),
                      "Prompt must embed the provided writer data text")
    }

    func testWritingAdvisorPromptContainsJSONInstructions() {
        let prompt = AIAssistanceType.writingAdvisor.prompt(for: "test data")
        XCTAssertTrue(prompt.contains("JSON"), "Prompt must instruct the model to return JSON")
        XCTAssertTrue(prompt.contains("overallAssessment"),
                      "Prompt must include the overallAssessment field name")
        XCTAssertTrue(prompt.contains("focusArea"),
                      "Prompt must include the focusArea field name")
        XCTAssertTrue(prompt.contains("recommendations"),
                      "Prompt must include the recommendations field name")
    }

    func testWritingAdvisorPromptContainsValidCategories() {
        let prompt = AIAssistanceType.writingAdvisor.prompt(for: "data")
        for category in ["productivity", "creativity", "consistency", "craft", "goals"] {
            XCTAssertTrue(prompt.contains(category),
                          "Prompt must list the '\(category)' category option")
        }
    }

    func testWritingAdvisorPromptContainsValidPriorities() {
        let prompt = AIAssistanceType.writingAdvisor.prompt(for: "data")
        XCTAssertTrue(prompt.contains("high"), "Prompt must list 'high' priority")
        XCTAssertTrue(prompt.contains("medium"), "Prompt must list 'medium' priority")
        XCTAssertTrue(prompt.contains("low"), "Prompt must list 'low' priority")
    }

    func testWritingAdvisorPromptContainsActionableStepsField() {
        let prompt = AIAssistanceType.writingAdvisor.prompt(for: "data")
        XCTAssertTrue(prompt.contains("actionableSteps"),
                      "Prompt must reference actionableSteps in the JSON schema")
    }

    func testWritingAdvisorPromptWithContextIncludesContextInfo() {
        let ctx = AIContext(
            genre: "Fantasy",
            targetAudience: "Adults",
            existingCharacters: ["Aera", "Mira"],
            plotSummary: "A hero's journey",
            additionalNotes: nil
        )
        let prompt = AIAssistanceType.writingAdvisor.prompt(for: "some data", context: ctx)
        XCTAssertFalse(prompt.isEmpty)
        XCTAssertTrue(prompt.contains("some data"),
                      "Prompt must still embed the writer data when context is provided")
    }

    func testWritingAdvisorPromptWithNilContextIsNonEmpty() {
        let prompt = AIAssistanceType.writingAdvisor.prompt(for: "writer stats", context: nil)
        XCTAssertFalse(prompt.isEmpty)
    }

    func testWritingAdvisorPromptMentions35Recommendations() {
        let prompt = AIAssistanceType.writingAdvisor.prompt(for: "data")
        XCTAssertTrue(prompt.contains("3-5"),
                      "Prompt must specify 3-5 coaching recommendations")
    }
}

// MARK: - WritersApp WritingAdvisor Integration Tests

final class WritersAppWritingAdvisorTests: XCTestCase {

    func testWritingAdvisorServiceIsNilWithoutAI() {
        let app = WritersApp()
        XCTAssertNil(app.writingAdvisorService,
                     "writingAdvisorService must be nil when no AI configuration is provided")
    }

    func testWritingAdvisorServiceIsCreatedAtInit() {
        let config = AIConfiguration(apiKey: "test-key")
        let app = WritersApp(aiConfiguration: config)
        XCTAssertNotNil(app.writingAdvisorService,
                        "writingAdvisorService must be non-nil when AI config is provided at init")
    }

    func testWritingAdvisorServiceIsCreatedByEnableAI() {
        let app = WritersApp()
        XCTAssertNil(app.writingAdvisorService)
        app.enableAI(configuration: AIConfiguration(apiKey: "new-key"))
        XCTAssertNotNil(app.writingAdvisorService,
                        "writingAdvisorService must be created by enableAI()")
    }

    func testWritingAdvisorServiceIsNilledByDisableAI() {
        let app = WritersApp(aiConfiguration: AIConfiguration(apiKey: "key"))
        XCTAssertNotNil(app.writingAdvisorService)
        app.disableAI()
        XCTAssertNil(app.writingAdvisorService,
                     "writingAdvisorService must be nil after disableAI()")
    }

    func testWritingAdvisorServiceReplacedOnReEnable() {
        let app = WritersApp()
        app.enableAI(configuration: AIConfiguration(apiKey: "key-1"))
        let firstService = app.writingAdvisorService
        app.disableAI()
        app.enableAI(configuration: AIConfiguration(apiKey: "key-2"))
        XCTAssertNotNil(app.writingAdvisorService)
        // Services should be different objects (new service created after re-enable)
        XCTAssertTrue(app.writingAdvisorService !== firstService,
                      "A new WritingAdvisorService instance must be created on re-enable")
    }

    func testGetPersonalizedWritingAdviceThrowsWhenNoAI() async {
        let app = WritersApp()
        do {
            _ = try await app.getPersonalizedWritingAdvice()
            XCTFail("Expected AIError.aiNotEnabled")
        } catch AIError.aiNotEnabled {
            // expected
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testGetPersonalizedWritingAdviceWithNotesThrowsWhenNoAI() async {
        let app = WritersApp()
        do {
            _ = try await app.getPersonalizedWritingAdvice(notes: "some notes")
            XCTFail("Expected AIError.aiNotEnabled")
        } catch AIError.aiNotEnabled {
            // expected
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testGetWritingAdviceForCategoryThrowsWhenNoAI() async {
        let app = WritersApp()
        do {
            _ = try await app.getWritingAdvice(for: .productivity)
            XCTFail("Expected AIError.aiNotEnabled")
        } catch AIError.aiNotEnabled {
            // expected
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testGetWritingAdviceThrowsForAllCategoriesWhenNoAI() async {
        let app = WritersApp()
        for category in AdvisorCategory.allCases {
            do {
                _ = try await app.getWritingAdvice(for: category)
                XCTFail("Expected AIError.aiNotEnabled for category \(category.rawValue)")
            } catch AIError.aiNotEnabled {
                // expected
            } catch {
                XCTFail("Unexpected error for \(category.rawValue): \(error)")
            }
        }
    }

    func testDisableAIThenGetAdviceThrowsAINotEnabled() async {
        let app = WritersApp(aiConfiguration: AIConfiguration(apiKey: "key"))
        XCTAssertNotNil(app.writingAdvisorService)
        app.disableAI()
        do {
            _ = try await app.getPersonalizedWritingAdvice()
            XCTFail("Expected AIError.aiNotEnabled after disableAI()")
        } catch AIError.aiNotEnabled {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

// MARK: - WritingAdvisorService Parsing Tests (via internal surface)

final class WritingAdvisorServiceParsingTests: XCTestCase {

    private var service: WritingAdvisorService!

    override func setUp() {
        super.setUp()
        let config = AIConfiguration(apiKey: "test-key")
        service = WritingAdvisorService(aiService: AIService(configuration: config))
    }

    override func tearDown() {
        service = nil
        super.tearDown()
    }

    // Tests for buildContextText covering boundary conditions not in context-building tests

    func testBuildContextTextTitlesSeparatedByCommaSpace() {
        let ctx = AdvisorContext(
            totalDocuments: 3,
            recentDocumentTitles: ["Title A", "Title B", "Title C"],
            totalWordsAcrossDocuments: 0,
            documentCategories: [],
            sessionStats: nil
        )
        let text = service.buildContextText(from: ctx)
        XCTAssertTrue(text.contains("\"Title A\", \"Title B\", \"Title C\""),
                      "Titles must be comma-space separated and individually quoted")
    }

    func testBuildContextTextSingleTitle() {
        let ctx = AdvisorContext(
            totalDocuments: 1,
            recentDocumentTitles: ["Only One"],
            totalWordsAcrossDocuments: 100,
            documentCategories: [],
            sessionStats: nil
        )
        let text = service.buildContextText(from: ctx)
        XCTAssertTrue(text.contains("\"Only One\""),
                      "Single title must be quoted in context text")
        // The titles line for a single entry should not include a separating comma
        let titleLine = text.components(separatedBy: "\n")
            .first(where: { $0.hasPrefix("Recent titles:") })
        XCTAssertNotNil(titleLine, "Recent titles line must be present")
        XCTAssertFalse(titleLine?.contains("\", \"") ?? false,
                       "Single title must not have a comma-separated list")
    }

    func testBuildContextTextSessionAverageZeroSeconds() {
        let stats = SessionStats(
            totalSessions: 3,
            totalDurationSeconds: 0,
            averageDurationSeconds: 0,
            earliestSession: nil,
            latestSession: nil
        )
        let ctx = AdvisorContext(
            totalDocuments: 0,
            recentDocumentTitles: [],
            totalWordsAcrossDocuments: 0,
            documentCategories: [],
            sessionStats: stats
        )
        let text = service.buildContextText(from: ctx)
        XCTAssertTrue(text.contains("avg 0 min"),
                      "Zero-second average duration should format to 0 min")
    }
}