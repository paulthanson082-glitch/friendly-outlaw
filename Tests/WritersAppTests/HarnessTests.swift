import XCTest
@testable import WritersApp

// MARK: - Multi-Agent Harness Tests
// Tests for the multi-agent harness facade methods on WritersApp.
// The PR simplified the docstring for runMultiAgentHarness(plan:configuration:)
// but the behavior is unchanged. These tests cover:
//   - createMultiAgentHarness() throws when AI is not enabled
//   - runMultiAgentHarness(prompt:) throws when AI is not enabled
//   - runMultiAgentHarness(plan:) throws when AI is not enabled
//   - planWriting() throws when AI is not enabled
//   - HarnessConfiguration.default values
//   - HarnessError localized descriptions

final class HarnessAINotEnabledTests: XCTestCase {

    var app: WritersApp!

    override func setUp() {
        super.setUp()
        app = WritersApp()
        // Do NOT enable AI — these tests verify error-path behavior
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    func testCreateMultiAgentHarnessThrowsWhenAINotEnabled() {
        XCTAssertThrowsError(
            try app.createMultiAgentHarness()
        ) { error in
            XCTAssertTrue(error is AIError || error is AIServiceError,
                "Expected an AI-disabled error, got: \(error)")
        }
    }

    func testRunMultiAgentHarnessWithPromptThrowsWhenAINotEnabled() async {
        do {
            let _ = try await app.runMultiAgentHarness(prompt: "Write a short story about the sea")
            XCTFail("Expected an error because AI is not enabled")
        } catch {
            // Expected — AI is not configured
            XCTAssertTrue(error is AIError || error is AIServiceError || error is HarnessError,
                "Expected an AI or Harness error, got: \(error)")
        }
    }

    func testRunMultiAgentHarnessWithPlanThrowsWhenAINotEnabled() async {
        let plan = WritingPlan(
            title: "Test Story",
            genre: "Fantasy",
            tone: "Heroic",
            targetAudience: "Adults",
            synopsis: "A hero's journey",
            sections: [],
            characters: [],
            themes: []
        )
        do {
            let _ = try await app.runMultiAgentHarness(plan: plan)
            XCTFail("Expected an error because AI is not enabled")
        } catch {
            // Expected — AI is not configured
            XCTAssertTrue(error is AIError || error is AIServiceError || error is HarnessError,
                "Expected an AI or Harness error, got: \(error)")
        }
    }

    func testPlanWritingThrowsWhenAINotEnabled() async {
        do {
            let _ = try await app.planWriting(prompt: "Write a mystery novel about a detective")
            XCTFail("Expected an error because AI is not enabled")
        } catch {
            // Expected — AI is not configured
            XCTAssertTrue(error is AIError || error is AIServiceError || error is HarnessError,
                "Expected an AI or Harness error, got: \(error)")
        }
    }

    func testCreateMultiAgentHarnessWithCustomConfigThrowsWhenAINotEnabled() {
        let config = HarnessConfiguration(
            maxRevisionsPerSection: 2,
            qualityThreshold: 7,
            maxSections: 5,
            model: .claude35Sonnet
        )
        XCTAssertThrowsError(
            try app.createMultiAgentHarness(configuration: config)
        )
    }
}

// MARK: - HarnessConfiguration Tests

final class HarnessConfigurationTests: XCTestCase {

    func testHarnessConfigurationDefaultValues() {
        let config = HarnessConfiguration.default
        XCTAssertGreaterThan(config.maxRevisionsPerSection, 0,
            "Default maxRevisionsPerSection must be positive")
        XCTAssertGreaterThan(config.qualityThreshold, 0,
            "Default qualityThreshold must be positive")
        XCTAssertGreaterThan(config.maxSections, 0,
            "Default maxSections must be positive")
    }

    func testHarnessConfigurationCustomInit() {
        let config = HarnessConfiguration(
            maxRevisionsPerSection: 3,
            qualityThreshold: 8,
            maxSections: 10,
            model: .claude3Opus
        )
        XCTAssertEqual(config.maxRevisionsPerSection, 3)
        XCTAssertEqual(config.qualityThreshold, 8)
        XCTAssertEqual(config.maxSections, 10)
        XCTAssertEqual(config.model, .claude3Opus)
    }

    func testHarnessConfigurationCodableRoundTrip() throws {
        let original = HarnessConfiguration(
            maxRevisionsPerSection: 2,
            qualityThreshold: 7,
            maxSections: 5,
            model: .claude35Sonnet
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(HarnessConfiguration.self, from: data)
        XCTAssertEqual(decoded.maxRevisionsPerSection, original.maxRevisionsPerSection)
        XCTAssertEqual(decoded.qualityThreshold, original.qualityThreshold)
        XCTAssertEqual(decoded.maxSections, original.maxSections)
        XCTAssertEqual(decoded.model, original.model)
    }
}

// MARK: - HarnessError Tests

final class HarnessErrorTests: XCTestCase {

    func testAllHarnessErrorsHaveNonEmptyDescriptions() {
        let errors: [HarnessError] = [
            .emptyPrompt,
            .plannerFailed("timeout"),
            .invalidPlanJSON("unexpected token"),
            .contractNegotiationFailed(sectionTitle: "Chapter 1"),
            .generationFailed(sectionTitle: "Chapter 1", reason: "model overloaded"),
            .evaluationFailed(sectionTitle: "Chapter 2", reason: "parse error"),
            .invalidEvaluationJSON("malformed"),
            .maxRevisionsExceeded(sectionTitle: "Chapter 3", revisions: 5)
        ]
        for error in errors {
            XCTAssertNotNil(error.errorDescription,
                "\(error) must have a non-nil error description")
            XCTAssertFalse(error.errorDescription?.isEmpty ?? true,
                "\(error) must have a non-empty error description")
        }
    }

    func testPlannerFailedContainsReason() {
        let reason = "API rate limit exceeded"
        let error = HarnessError.plannerFailed(reason)
        XCTAssertTrue(error.errorDescription?.contains(reason) ?? false,
            "plannerFailed description must contain the reason string")
    }

    func testMaxRevisionsExceededContainsSectionTitle() {
        let title = "The Final Chapter"
        let error = HarnessError.maxRevisionsExceeded(sectionTitle: title, revisions: 3)
        XCTAssertTrue(error.errorDescription?.contains(title) ?? false,
            "maxRevisionsExceeded description must contain the section title")
    }

    func testContractNegotiationFailedContainsSectionTitle() {
        let title = "Act II"
        let error = HarnessError.contractNegotiationFailed(sectionTitle: title)
        XCTAssertTrue(error.errorDescription?.contains(title) ?? false)
    }
}

// MARK: - WritingPlan Tests

final class WritingPlanTests: XCTestCase {

    func testWritingPlanInit() {
        let plan = WritingPlan(
            title: "The Lost Compass",
            genre: "Adventure",
            tone: "Exciting",
            targetAudience: "Young adults",
            synopsis: "A teenager finds a magical compass",
            sections: [],
            characters: ["Alex", "Sam"],
            themes: ["courage", "friendship"]
        )
        XCTAssertEqual(plan.title, "The Lost Compass")
        XCTAssertEqual(plan.genre, "Adventure")
        XCTAssertEqual(plan.tone, "Exciting")
        XCTAssertEqual(plan.characters, ["Alex", "Sam"])
        XCTAssertEqual(plan.themes, ["courage", "friendship"])
    }

    func testWritingPlanCodableRoundTrip() throws {
        let original = WritingPlan(
            title: "Starborn",
            genre: "Sci-Fi",
            tone: "Wonder-filled",
            targetAudience: nil,
            synopsis: "A child born among the stars",
            sections: [],
            characters: ["Nova"],
            themes: ["discovery"]
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(WritingPlan.self, from: data)
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.title, original.title)
        XCTAssertEqual(decoded.genre, original.genre)
        XCTAssertEqual(decoded.characters, original.characters)
        XCTAssertNil(decoded.targetAudience)
    }
}