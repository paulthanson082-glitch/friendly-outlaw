import XCTest
@testable import WritersApp

/// Tests for the Harness-related code touched by this PR:
/// - WritersApp.getAIAssistanceWithTools docstring change (behavior unchanged)
/// - WritersApp.runMultiAgentHarness docstring change (behavior unchanged)
/// - HarnessConfiguration, WritingCriterion, CriterionScore models
/// - WritersApp.brainstormIdeas throws when AI not enabled
final class HarnessTests: XCTestCase {

    // MARK: - HarnessConfiguration defaults

    func testHarnessConfigurationDefaultValues() {
        let config = HarnessConfiguration.default
        XCTAssertEqual(config.maxRevisionsPerSection, 3)
        XCTAssertEqual(config.qualityThreshold, 7)
        XCTAssertEqual(config.maxSections, 20)
        XCTAssertEqual(config.model, .claude35Sonnet)
    }

    func testHarnessConfigurationCustomValues() {
        let config = HarnessConfiguration(
            maxRevisionsPerSection: 5,
            qualityThreshold: 8,
            maxSections: 10,
            model: .claude3Opus
        )
        XCTAssertEqual(config.maxRevisionsPerSection, 5)
        XCTAssertEqual(config.qualityThreshold, 8)
        XCTAssertEqual(config.maxSections, 10)
        XCTAssertEqual(config.model, .claude3Opus)
    }

    func testHarnessConfigurationQualityThresholdClampedToMin() {
        let config = HarnessConfiguration(qualityThreshold: 0)
        XCTAssertEqual(config.qualityThreshold, 1, "qualityThreshold should be clamped to minimum 1")
    }

    func testHarnessConfigurationQualityThresholdClampedToMax() {
        let config = HarnessConfiguration(qualityThreshold: 11)
        XCTAssertEqual(config.qualityThreshold, 10, "qualityThreshold should be clamped to maximum 10")
    }

    func testHarnessConfigurationQualityThresholdBoundaryMin() {
        let config = HarnessConfiguration(qualityThreshold: 1)
        XCTAssertEqual(config.qualityThreshold, 1)
    }

    func testHarnessConfigurationQualityThresholdBoundaryMax() {
        let config = HarnessConfiguration(qualityThreshold: 10)
        XCTAssertEqual(config.qualityThreshold, 10)
    }

    func testHarnessConfigurationCodable() throws {
        let original = HarnessConfiguration(
            maxRevisionsPerSection: 2,
            qualityThreshold: 6,
            maxSections: 15,
            model: .claude3Sonnet
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(HarnessConfiguration.self, from: data)
        XCTAssertEqual(decoded.maxRevisionsPerSection, original.maxRevisionsPerSection)
        XCTAssertEqual(decoded.qualityThreshold, original.qualityThreshold)
        XCTAssertEqual(decoded.maxSections, original.maxSections)
        XCTAssertEqual(decoded.model, original.model)
    }

    // MARK: - WritingCriterion

    func testWritingCriterionAllCases() {
        XCTAssertEqual(WritingCriterion.allCases.count, 4)
    }

    func testWritingCriterionDisplayNames() {
        XCTAssertEqual(WritingCriterion.narrativeCoherence.displayName, "Narrative Coherence")
        XCTAssertEqual(WritingCriterion.originality.displayName, "Originality")
        XCTAssertEqual(WritingCriterion.craft.displayName, "Craft")
        XCTAssertEqual(WritingCriterion.planConsistency.displayName, "Plan Consistency")
    }

    func testWritingCriterionRawValues() {
        XCTAssertEqual(WritingCriterion.narrativeCoherence.rawValue, "narrativeCoherence")
        XCTAssertEqual(WritingCriterion.originality.rawValue, "originality")
        XCTAssertEqual(WritingCriterion.craft.rawValue, "craft")
        XCTAssertEqual(WritingCriterion.planConsistency.rawValue, "planConsistency")
    }

    func testWritingCriterionRubricsAreNonEmpty() {
        for criterion in WritingCriterion.allCases {
            XCTAssertFalse(criterion.rubric.isEmpty, "Rubric for \(criterion) should not be empty")
        }
    }

    func testWritingCriterionCodable() throws {
        for criterion in WritingCriterion.allCases {
            let data = try JSONEncoder().encode(criterion)
            let decoded = try JSONDecoder().decode(WritingCriterion.self, from: data)
            XCTAssertEqual(decoded, criterion)
        }
    }

    // MARK: - CriterionScore

    func testCriterionScoreInit() {
        let score = CriterionScore(criterion: .craft, score: 8, feedback: "Strong prose")
        XCTAssertEqual(score.criterion, .craft)
        XCTAssertEqual(score.score, 8)
        XCTAssertEqual(score.feedback, "Strong prose")
    }

    func testCriterionScoreClampedToMin() {
        let score = CriterionScore(criterion: .originality, score: 0, feedback: "Too generic")
        XCTAssertEqual(score.score, 1, "Score should be clamped to minimum 1")
    }

    func testCriterionScoreClampedToMax() {
        let score = CriterionScore(criterion: .planConsistency, score: 11, feedback: "Excellent")
        XCTAssertEqual(score.score, 10, "Score should be clamped to maximum 10")
    }

    func testCriterionScoreBoundaryValues() {
        let min = CriterionScore(criterion: .craft, score: 1, feedback: "Poor")
        XCTAssertEqual(min.score, 1)
        let max = CriterionScore(criterion: .craft, score: 10, feedback: "Perfect")
        XCTAssertEqual(max.score, 10)
    }

    func testCriterionScoreCodable() throws {
        let original = CriterionScore(criterion: .narrativeCoherence, score: 7, feedback: "Good flow")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(CriterionScore.self, from: data)
        XCTAssertEqual(decoded.criterion, original.criterion)
        XCTAssertEqual(decoded.score, original.score)
        XCTAssertEqual(decoded.feedback, original.feedback)
    }

    // MARK: - WritersApp.brainstormIdeas throws when AI not enabled (PR docstring change)

    func testBrainstormIdeasThrowsWhenAINotEnabled() async {
        let app = WritersApp()
        do {
            _ = try await app.brainstormIdeas(topic: "Adventure")
            XCTFail("Expected error when AI not enabled")
        } catch {
            // Expected — AI is not configured so an error should be thrown
        }
    }

    // MARK: - WritersApp.runMultiAgentHarness requires AI (PR docstring change)

    func testRunMultiAgentHarnessWithPromptThrowsWhenAINotEnabled() async {
        let app = WritersApp()
        do {
            _ = try await app.runMultiAgentHarness(prompt: "Write a short story")
            XCTFail("Expected error when AI not enabled")
        } catch {
            // Expected — AI must be configured for harness to run
        }
    }
}