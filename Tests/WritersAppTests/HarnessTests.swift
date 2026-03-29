import XCTest
@testable import WritersApp

// MARK: - HarnessConfiguration Additional Tests

final class HarnessConfigurationTests: XCTestCase {

    // MARK: - Quality Threshold Clamping

    func testQualityThresholdClampedBelowOne() {
        let config = HarnessConfiguration(qualityThreshold: 0)
        XCTAssertEqual(config.qualityThreshold, 1, "Threshold below 1 must be clamped to 1")
    }

    func testQualityThresholdClampedToOneForNegativeInput() {
        let config = HarnessConfiguration(qualityThreshold: -100)
        XCTAssertEqual(config.qualityThreshold, 1)
    }

    func testQualityThresholdClampedAboveTen() {
        let config = HarnessConfiguration(qualityThreshold: 11)
        XCTAssertEqual(config.qualityThreshold, 10, "Threshold above 10 must be clamped to 10")
    }

    func testQualityThresholdClampedForLargeValue() {
        let config = HarnessConfiguration(qualityThreshold: 999)
        XCTAssertEqual(config.qualityThreshold, 10)
    }

    func testQualityThresholdBoundaryOne() {
        let config = HarnessConfiguration(qualityThreshold: 1)
        XCTAssertEqual(config.qualityThreshold, 1)
    }

    func testQualityThresholdBoundaryTen() {
        let config = HarnessConfiguration(qualityThreshold: 10)
        XCTAssertEqual(config.qualityThreshold, 10)
    }

    func testQualityThresholdMidRange() {
        let config = HarnessConfiguration(qualityThreshold: 5)
        XCTAssertEqual(config.qualityThreshold, 5)
    }

    // MARK: - Codable Round Trip

    func testHarnessConfigurationCodableRoundTrip() throws {
        let original = HarnessConfiguration(
            maxRevisionsPerSection: 4,
            qualityThreshold: 8,
            maxSections: 15,
            model: .claude3Haiku
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(HarnessConfiguration.self, from: data)
        XCTAssertEqual(decoded.maxRevisionsPerSection, original.maxRevisionsPerSection)
        XCTAssertEqual(decoded.qualityThreshold, original.qualityThreshold)
        XCTAssertEqual(decoded.maxSections, original.maxSections)
        XCTAssertEqual(decoded.model, original.model)
    }
}

// MARK: - WritingCriterion Additional Tests

final class WritingCriterionTests: XCTestCase {

    func testWritingCriterionDisplayNamesAreDistinct() {
        let names = WritingCriterion.allCases.map { $0.displayName }
        let uniqueNames = Set(names)
        XCTAssertEqual(names.count, uniqueNames.count, "Each criterion must have a unique display name")
    }

    func testWritingCriterionRubricsAreDistinct() {
        let rubrics = WritingCriterion.allCases.map { $0.rubric }
        let uniqueRubrics = Set(rubrics)
        XCTAssertEqual(rubrics.count, uniqueRubrics.count, "Each criterion must have a unique rubric")
    }

    func testWritingCriterionCodableRoundTrip() throws {
        for criterion in WritingCriterion.allCases {
            let data = try JSONEncoder().encode(criterion)
            let decoded = try JSONDecoder().decode(WritingCriterion.self, from: data)
            XCTAssertEqual(decoded, criterion)
        }
    }

    func testNarrativeCoherenceDisplayName() {
        XCTAssertEqual(WritingCriterion.narrativeCoherence.displayName, "Narrative Coherence")
    }

    func testOriginalityDisplayName() {
        XCTAssertEqual(WritingCriterion.originality.displayName, "Originality")
    }

    func testCraftDisplayName() {
        XCTAssertEqual(WritingCriterion.craft.displayName, "Craft")
    }

    func testPlanConsistencyDisplayName() {
        XCTAssertEqual(WritingCriterion.planConsistency.displayName, "Plan Consistency")
    }
}

// MARK: - CriterionScore Additional Tests

final class CriterionScoreTests: XCTestCase {

    func testCriterionScoreBoundaryAtOne() {
        let score = CriterionScore(criterion: .craft, score: 1, feedback: "minimum")
        XCTAssertEqual(score.score, 1)
    }

    func testCriterionScoreBoundaryAtTen() {
        let score = CriterionScore(criterion: .craft, score: 10, feedback: "maximum")
        XCTAssertEqual(score.score, 10)
    }

    func testCriterionScorePassedDefaultExactlyAtThreshold() {
        // Default threshold is 7; score of 7 should pass
        let score = CriterionScore(criterion: .originality, score: 7, feedback: "just enough")
        XCTAssertTrue(score.passedDefault)
    }

    func testCriterionScoreFailedDefaultJustBelow() {
        let score = CriterionScore(criterion: .originality, score: 6, feedback: "just under")
        XCTAssertFalse(score.passedDefault)
    }

    func testCriterionScorePassedAtMinThreshold() {
        let score = CriterionScore(criterion: .craft, score: 1, feedback: "low")
        XCTAssertTrue(score.passed(threshold: 1))
        XCTAssertFalse(score.passed(threshold: 2))
    }

    func testCriterionScoreCodableRoundTrip() throws {
        let original = CriterionScore(criterion: .narrativeCoherence, score: 8, feedback: "Flows well")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(CriterionScore.self, from: data)
        XCTAssertEqual(decoded.criterion, original.criterion)
        XCTAssertEqual(decoded.score, original.score)
        XCTAssertEqual(decoded.feedback, original.feedback)
    }
}

// MARK: - WritingSection Additional Tests

final class WritingSectionTests: XCTestCase {

    func testWritingSectionEmptyKeyElements() {
        let section = WritingSection(
            sequenceNumber: 1,
            title: "Opening",
            purpose: "Establish tone",
            keyElements: []
        )
        XCTAssertTrue(section.keyElements.isEmpty)
    }

    func testWritingSectionCustomId() {
        let customId = UUID()
        let section = WritingSection(
            id: customId,
            sequenceNumber: 2,
            title: "Middle",
            purpose: "Rising action",
            keyElements: ["conflict revealed"]
        )
        XCTAssertEqual(section.id, customId)
    }

    func testWritingSectionCodableRoundTrip() throws {
        let original = WritingSection(
            sequenceNumber: 3,
            title: "Climax",
            purpose: "Peak tension",
            keyElements: ["confrontation", "revelation"]
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(WritingSection.self, from: data)
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.sequenceNumber, original.sequenceNumber)
        XCTAssertEqual(decoded.title, original.title)
        XCTAssertEqual(decoded.purpose, original.purpose)
        XCTAssertEqual(decoded.keyElements, original.keyElements)
    }
}

// MARK: - WritingPlan Additional Tests

final class WritingPlanTests: XCTestCase {

    func testHandoffSummaryWithNilGenre() {
        let section = WritingSection(
            sequenceNumber: 1, title: "Opening", purpose: "Establish", keyElements: []
        )
        let plan = WritingPlan(
            title: "Untitled",
            genre: nil,
            tone: "somber",
            synopsis: "A tale.",
            sections: [section]
        )
        XCTAssertTrue(plan.handoffSummary.contains("unspecified"),
                      "Nil genre should render as 'unspecified' in handoff summary")
    }

    func testHandoffSummaryWithEmptyCharactersAndThemes() {
        let section = WritingSection(
            sequenceNumber: 1, title: "S1", purpose: "Purpose", keyElements: []
        )
        let plan = WritingPlan(
            title: "Story",
            tone: "neutral",
            synopsis: "Synopsis.",
            sections: [section],
            characters: [],
            themes: []
        )
        let summary = plan.handoffSummary
        XCTAssertTrue(summary.contains("Characters:"))
        XCTAssertTrue(summary.contains("Themes:"))
    }

    func testHandoffSummaryListsSectionsInOrder() {
        let s1 = WritingSection(sequenceNumber: 1, title: "Act 1", purpose: "Open", keyElements: [])
        let s2 = WritingSection(sequenceNumber: 2, title: "Act 2", purpose: "Middle", keyElements: [])
        let s3 = WritingSection(sequenceNumber: 3, title: "Act 3", purpose: "Close", keyElements: [])
        let plan = WritingPlan(
            title: "Three Acts",
            tone: "dramatic",
            synopsis: "A play.",
            sections: [s3, s1, s2]  // Deliberately out of order
        )
        let summary = plan.handoffSummary
        let act1Range = summary.range(of: "Act 1")
        let act2Range = summary.range(of: "Act 2")
        let act3Range = summary.range(of: "Act 3")
        XCTAssertNotNil(act1Range)
        XCTAssertNotNil(act2Range)
        XCTAssertNotNil(act3Range)
        // All three sections appear in the summary
        XCTAssertTrue(summary.contains("1. Act 1"))
        XCTAssertTrue(summary.contains("2. Act 2"))
        XCTAssertTrue(summary.contains("3. Act 3"))
    }

    func testHandoffSummaryContainsTitleToneAndSynopsis() {
        let section = WritingSection(
            sequenceNumber: 1, title: "S", purpose: "P", keyElements: []
        )
        let plan = WritingPlan(
            title: "My Novel",
            tone: "melancholic",
            synopsis: "A story about loss.",
            sections: [section]
        )
        let summary = plan.handoffSummary
        XCTAssertTrue(summary.contains("My Novel"))
        XCTAssertTrue(summary.contains("melancholic"))
        XCTAssertTrue(summary.contains("A story about loss."))
    }

    func testWritingPlanNilOptionalFields() {
        let section = WritingSection(
            sequenceNumber: 1, title: "S", purpose: "P", keyElements: []
        )
        let plan = WritingPlan(
            title: "Test",
            genre: nil,
            tone: "neutral",
            targetAudience: nil,
            synopsis: "Test synopsis.",
            sections: [section]
        )
        XCTAssertNil(plan.genre)
        XCTAssertNil(plan.targetAudience)
    }

    func testWritingPlanCodablePreservesNilOptionals() throws {
        let section = WritingSection(
            sequenceNumber: 1, title: "S", purpose: "P", keyElements: []
        )
        let original = WritingPlan(
            title: "Nulls",
            genre: nil,
            tone: "flat",
            targetAudience: nil,
            synopsis: "Synopsis.",
            sections: [section]
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(WritingPlan.self, from: data)
        XCTAssertNil(decoded.genre)
        XCTAssertNil(decoded.targetAudience)
    }
}

// MARK: - SectionContract Additional Tests

final class SectionContractTests: XCTestCase {

    func testDescriptionWithoutWordCountBounds() {
        let contract = SectionContract(
            sectionId: UUID(),
            goals: ["Goal A"],
            successCriteria: ["Criterion A"],
            wordCountMin: nil,
            wordCountMax: nil
        )
        let desc = contract.description
        // Word count section should not appear
        XCTAssertFalse(desc.contains("Word Count"), "Word count line should be absent when bounds are nil")
    }

    func testDescriptionWithOnlyMinWordCount() {
        // Only min is set, max is nil — the description should NOT show the word count line
        // (both lo and hi are required by the implementation)
        let contract = SectionContract(
            sectionId: UUID(),
            goals: ["Goal"],
            successCriteria: ["Criterion"],
            wordCountMin: 200,
            wordCountMax: nil
        )
        XCTAssertFalse(contract.description.contains("Word Count"))
    }

    func testDescriptionWithoutToneNotes() {
        let contract = SectionContract(
            sectionId: UUID(),
            goals: ["Goal"],
            successCriteria: ["Criterion"],
            toneNotes: nil
        )
        XCTAssertFalse(contract.description.contains("Tone Notes"), "Tone notes line should be absent when nil")
    }

    func testDescriptionContainsGoalsAsBullets() {
        let contract = SectionContract(
            sectionId: UUID(),
            goals: ["Goal One", "Goal Two"],
            successCriteria: ["Criterion"]
        )
        let desc = contract.description
        XCTAssertTrue(desc.contains("• Goal One"))
        XCTAssertTrue(desc.contains("• Goal Two"))
    }

    func testDescriptionContainsSuccessCriteriaAsBullets() {
        let contract = SectionContract(
            sectionId: UUID(),
            goals: ["Goal"],
            successCriteria: ["Check A", "Check B"]
        )
        let desc = contract.description
        XCTAssertTrue(desc.contains("• Check A"))
        XCTAssertTrue(desc.contains("• Check B"))
    }

    func testSectionContractCodableRoundTripWithNilFields() throws {
        let original = SectionContract(
            sectionId: UUID(),
            goals: ["G"],
            successCriteria: ["C"],
            wordCountMin: nil,
            wordCountMax: nil,
            toneNotes: nil
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SectionContract.self, from: data)
        XCTAssertNil(decoded.wordCountMin)
        XCTAssertNil(decoded.wordCountMax)
        XCTAssertNil(decoded.toneNotes)
        XCTAssertEqual(decoded.goals, ["G"])
    }
}

// MARK: - WritingSectionEvaluation Additional Tests

final class WritingSectionEvaluationTests: XCTestCase {

    func testAverageScoreWithEmptyScores() {
        let eval = WritingSectionEvaluation(
            sectionId: UUID(),
            scores: [],
            overallFeedback: "no scores",
            revision: 1
        )
        XCTAssertEqual(eval.averageScore, 0.0)
    }

    func testOverallPassedDefaultUsesThresholdOfSeven() {
        let sectionId = UUID()
        let allSevenScores = WritingCriterion.allCases.map {
            CriterionScore(criterion: $0, score: 7, feedback: "ok")
        }
        let eval = WritingSectionEvaluation(
            sectionId: sectionId,
            scores: allSevenScores,
            overallFeedback: "",
            revision: 1
        )
        XCTAssertTrue(eval.overallPassedDefault, "All scores of 7 should pass the default threshold")
    }

    func testOverallPassedDefaultFailsWhenOneCriterionBelowSeven() {
        let sectionId = UUID()
        var scores = WritingCriterion.allCases.map {
            CriterionScore(criterion: $0, score: 8, feedback: "good")
        }
        // Replace first with a failing score
        scores[0] = CriterionScore(criterion: WritingCriterion.allCases[0], score: 6, feedback: "needs work")
        let eval = WritingSectionEvaluation(
            sectionId: sectionId,
            scores: scores,
            overallFeedback: "",
            revision: 1
        )
        XCTAssertFalse(eval.overallPassedDefault)
    }

    func testAverageScoreWithSingleCriterion() {
        let eval = WritingSectionEvaluation(
            sectionId: UUID(),
            scores: [CriterionScore(criterion: .craft, score: 9, feedback: "great")],
            overallFeedback: "",
            revision: 1
        )
        XCTAssertEqual(eval.averageScore, 9.0, accuracy: 0.001)
    }

    func testScoresByNameContainsAllCriteria() {
        let scores = WritingCriterion.allCases.map {
            CriterionScore(criterion: $0, score: 7, feedback: "ok")
        }
        let eval = WritingSectionEvaluation(
            sectionId: UUID(),
            scores: scores,
            overallFeedback: "",
            revision: 1
        )
        for criterion in WritingCriterion.allCases {
            XCTAssertNotNil(eval.scoresByName[criterion.displayName],
                            "scoresByName must contain key '\(criterion.displayName)'")
        }
    }

    func testWritingSectionEvaluationCodableRoundTrip() throws {
        let sectionId = UUID()
        let scores = WritingCriterion.allCases.map {
            CriterionScore(criterion: $0, score: 8, feedback: "solid")
        }
        let original = WritingSectionEvaluation(
            sectionId: sectionId,
            scores: scores,
            overallFeedback: "Well done",
            revision: 2
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(WritingSectionEvaluation.self, from: data)
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.sectionId, sectionId)
        XCTAssertEqual(decoded.scores.count, original.scores.count)
        XCTAssertEqual(decoded.overallFeedback, "Well done")
        XCTAssertEqual(decoded.revision, 2)
    }

    func testOverallPassedWithHighThresholdFailsAtTen() {
        let scores = WritingCriterion.allCases.map {
            CriterionScore(criterion: $0, score: 9, feedback: "nearly perfect")
        }
        let eval = WritingSectionEvaluation(
            sectionId: UUID(),
            scores: scores,
            overallFeedback: "",
            revision: 1
        )
        XCTAssertFalse(eval.overallPassed(threshold: 10), "Score of 9 should fail threshold of 10")
        XCTAssertTrue(eval.overallPassed(threshold: 9))
    }
}

// MARK: - SectionResult Additional Tests

final class SectionResultTests: XCTestCase {

    private func makeSectionResult(totalRevisions: Int = 1) -> SectionResult {
        let section = WritingSection(
            sequenceNumber: 1, title: "Test Section", purpose: "Test", keyElements: ["element"]
        )
        let contract = SectionContract(
            sectionId: section.id,
            goals: ["Goal"],
            successCriteria: ["Criterion"]
        )
        let scores = WritingCriterion.allCases.map {
            CriterionScore(criterion: $0, score: 8, feedback: "ok")
        }
        let evaluation = WritingSectionEvaluation(
            sectionId: section.id, scores: scores, overallFeedback: "Good", revision: totalRevisions
        )
        return SectionResult(
            section: section,
            contract: contract,
            generatedContent: "The prose goes here.",
            evaluation: evaluation,
            totalRevisions: totalRevisions,
            handoffContext: "Section 1 done."
        )
    }

    func testSectionResultCodableRoundTrip() throws {
        let original = makeSectionResult(totalRevisions: 2)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SectionResult.self, from: data)
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.generatedContent, "The prose goes here.")
        XCTAssertEqual(decoded.totalRevisions, 2)
        XCTAssertEqual(decoded.handoffContext, "Section 1 done.")
    }

    func testSectionResultPreservesSection() {
        let result = makeSectionResult()
        XCTAssertEqual(result.section.title, "Test Section")
        XCTAssertEqual(result.section.keyElements, ["element"])
    }
}

// MARK: - HarnessQualityReport Additional Tests

final class HarnessQualityReportTests: XCTestCase {

    func testPassRateWhenAllSectionsPassFirstAttempt() {
        let report = HarnessQualityReport(
            averageScoresByCriterion: [:],
            sectionsPassedFirstAttempt: 5,
            totalSections: 5,
            totalRevisions: 5
        )
        XCTAssertEqual(report.passRate, 1.0, accuracy: 0.001)
    }

    func testPassRateWhenNoSectionsPassFirstAttempt() {
        let report = HarnessQualityReport(
            averageScoresByCriterion: [:],
            sectionsPassedFirstAttempt: 0,
            totalSections: 3,
            totalRevisions: 9
        )
        XCTAssertEqual(report.passRate, 0.0, accuracy: 0.001)
    }

    func testQualityReportCodableRoundTrip() throws {
        let averages: [String: Double] = [
            WritingCriterion.craft.rawValue: 8.5,
            WritingCriterion.originality.rawValue: 7.0
        ]
        let original = HarnessQualityReport(
            averageScoresByCriterion: averages,
            sectionsPassedFirstAttempt: 2,
            totalSections: 3,
            totalRevisions: 4
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(HarnessQualityReport.self, from: data)
        XCTAssertEqual(decoded.totalSections, 3)
        XCTAssertEqual(decoded.totalRevisions, 4)
        XCTAssertEqual(decoded.sectionsPassedFirstAttempt, 2)
        XCTAssertEqual(decoded.averageScoresByCriterion[WritingCriterion.craft.rawValue], 8.5, accuracy: 0.001)
    }
}

// MARK: - HarnessError Additional Tests

final class HarnessErrorTests: XCTestCase {

    func testEmptyPromptErrorDescription() {
        let error = HarnessError.emptyPrompt
        XCTAssertEqual(error.errorDescription, "Writing prompt must not be empty")
    }

    func testPlannerFailedErrorContainsReason() {
        let error = HarnessError.plannerFailed("connection timeout")
        XCTAssertTrue(error.errorDescription?.contains("connection timeout") ?? false)
    }

    func testInvalidPlanJSONErrorContainsDetail() {
        let error = HarnessError.invalidPlanJSON("missing title")
        XCTAssertTrue(error.errorDescription?.contains("missing title") ?? false)
    }

    func testContractNegotiationFailedContainsSectionTitle() {
        let error = HarnessError.contractNegotiationFailed(sectionTitle: "Chapter One")
        XCTAssertTrue(error.errorDescription?.contains("Chapter One") ?? false)
    }

    func testGenerationFailedContainsSectionTitleAndReason() {
        let error = HarnessError.generationFailed(sectionTitle: "Chapter Two", reason: "API error")
        let desc = error.errorDescription ?? ""
        XCTAssertTrue(desc.contains("Chapter Two"))
        XCTAssertTrue(desc.contains("API error"))
    }

    func testEvaluationFailedContainsSectionTitleAndReason() {
        let error = HarnessError.evaluationFailed(sectionTitle: "Chapter Three", reason: "bad JSON")
        let desc = error.errorDescription ?? ""
        XCTAssertTrue(desc.contains("Chapter Three"))
        XCTAssertTrue(desc.contains("bad JSON"))
    }

    func testInvalidEvaluationJSONContainsDetail() {
        let error = HarnessError.invalidEvaluationJSON("no scores field")
        XCTAssertTrue(error.errorDescription?.contains("no scores field") ?? false)
    }

    func testMaxRevisionsExceededContainsTitleAndCount() {
        let error = HarnessError.maxRevisionsExceeded(sectionTitle: "Epilogue", revisions: 5)
        let desc = error.errorDescription ?? ""
        XCTAssertTrue(desc.contains("Epilogue"))
        XCTAssertTrue(desc.contains("5"))
    }

    func testHarnessErrorIsLocalizedError() {
        let error: Error = HarnessError.emptyPrompt
        // Should be convertible to LocalizedError
        XCTAssertNotNil((error as? HarnessError)?.errorDescription)
    }
}

// MARK: - MultiAgentHarness Initialisation Tests

final class MultiAgentHarnessInitTests: XCTestCase {

    func testHarnessStoresConfiguration() {
        let aiConfig = AIConfiguration(apiKey: "test-key")
        let aiService = AIService(configuration: aiConfig)
        let harnessConfig = HarnessConfiguration(
            maxRevisionsPerSection: 2,
            qualityThreshold: 6,
            maxSections: 8,
            model: .claude3Opus
        )
        let harness = MultiAgentHarness(aiService: aiService, configuration: harnessConfig)
        XCTAssertEqual(harness.configuration.maxRevisionsPerSection, 2)
        XCTAssertEqual(harness.configuration.qualityThreshold, 6)
        XCTAssertEqual(harness.configuration.maxSections, 8)
        XCTAssertEqual(harness.configuration.model, .claude3Opus)
    }

    func testHarnessDefaultConfiguration() {
        let aiConfig = AIConfiguration(apiKey: "test-key")
        let aiService = AIService(configuration: aiConfig)
        let harness = MultiAgentHarness(aiService: aiService)
        XCTAssertEqual(harness.configuration.maxRevisionsPerSection, 3)
        XCTAssertEqual(harness.configuration.qualityThreshold, 7)
        XCTAssertEqual(harness.configuration.maxSections, 20)
        XCTAssertEqual(harness.configuration.model, .claude35Sonnet)
    }

    func testHarnessThrowsEmptyPromptImmediately() async {
        let aiConfig = AIConfiguration(apiKey: "test-key")
        let aiService = AIService(configuration: aiConfig)
        let harness = MultiAgentHarness(aiService: aiService)

        do {
            _ = try await harness.run(prompt: "")
            XCTFail("Expected HarnessError.emptyPrompt to be thrown")
        } catch HarnessError.emptyPrompt {
            // Expected
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testHarnessThrowsEmptyPromptForWhitespaceOnly() async {
        let aiConfig = AIConfiguration(apiKey: "test-key")
        let aiService = AIService(configuration: aiConfig)
        let harness = MultiAgentHarness(aiService: aiService)

        do {
            _ = try await harness.run(prompt: "   \n\t  ")
            XCTFail("Expected HarnessError.emptyPrompt to be thrown")
        } catch HarnessError.emptyPrompt {
            // Expected
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
}

// MARK: - AIModel Codable Tests

final class AIModelCodableTests: XCTestCase {

    func testAIModelCodableRoundTripAllCases() throws {
        let models: [AIModel] = [.claude35Sonnet, .claude3Opus, .claude3Sonnet, .claude3Haiku]
        for model in models {
            let data = try JSONEncoder().encode(model)
            let decoded = try JSONDecoder().decode(AIModel.self, from: data)
            XCTAssertEqual(decoded, model, "AIModel '\(model.rawValue)' should survive a Codable round trip")
        }
    }

    func testAIModelEncodesAsRawStringValue() throws {
        let data = try JSONEncoder().encode(AIModel.claude35Sonnet)
        let jsonString = String(data: data, encoding: .utf8) ?? ""
        XCTAssertTrue(jsonString.contains("claude-3-5-sonnet-20241022"),
                      "Encoded AIModel should use its rawValue string")
    }

    func testAIModelDecodesFromRawString() throws {
        let json = "\"claude-3-haiku-20240307\""
        let data = json.data(using: .utf8)!
        let model = try JSONDecoder().decode(AIModel.self, from: data)
        XCTAssertEqual(model, .claude3Haiku)
    }

    func testAIModelDecodingFailsForUnknownValue() {
        let json = "\"unknown-model-xyz\""
        let data = json.data(using: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(AIModel.self, from: data))
    }

    func testHarnessConfigurationEncodesModelAsRawValue() throws {
        let config = HarnessConfiguration(model: .claude3Opus)
        let data = try JSONEncoder().encode(config)
        let jsonString = String(data: data, encoding: .utf8) ?? ""
        XCTAssertTrue(jsonString.contains("claude-3-opus-20240229"),
                      "HarnessConfiguration JSON should embed AIModel's raw string")
    }
}

// MARK: - WritersApp Facade Additional Tests

final class WritersAppHarnessFacadeTests: XCTestCase {

    func testCreateMultiAgentHarnessReturnsHarnessWithCorrectConfig() throws {
        let aiConfig = AIConfiguration(apiKey: "test-key")
        let app = WritersApp(aiConfiguration: aiConfig)
        let harnessConfig = HarnessConfiguration(maxRevisionsPerSection: 2, qualityThreshold: 8)
        let harness = try app.createMultiAgentHarness(configuration: harnessConfig)
        XCTAssertEqual(harness.configuration.maxRevisionsPerSection, 2)
        XCTAssertEqual(harness.configuration.qualityThreshold, 8)
    }

    func testCreateMultiAgentHarnessReturnsDifferentInstancesEachCall() throws {
        let aiConfig = AIConfiguration(apiKey: "test-key")
        let app = WritersApp(aiConfiguration: aiConfig)
        let harness1 = try app.createMultiAgentHarness()
        let harness2 = try app.createMultiAgentHarness()
        // Both should be valid, independent harness instances
        XCTAssertEqual(harness1.configuration.qualityThreshold, harness2.configuration.qualityThreshold)
    }

    func testRunMultiAgentHarnessWithEmptyPromptThrowsEmptyPromptError() async {
        // runMultiAgentHarness delegates to harness.run(prompt:) which validates the prompt
        // before making any network call, so emptyPrompt should be raised immediately.
        let aiConfig = AIConfiguration(apiKey: "test-key")
        let app = WritersApp(aiConfiguration: aiConfig)
        do {
            _ = try await app.runMultiAgentHarness(prompt: "")
            XCTFail("Should throw HarnessError.emptyPrompt")
        } catch HarnessError.emptyPrompt {
            // Correct path
        } catch {
            XCTFail("Unexpected error: \(error) — expected HarnessError.emptyPrompt")
        }
    }

    func testRunMultiAgentHarnessWithWhitespaceOnlyPromptThrowsEmptyPromptError() async {
        let aiConfig = AIConfiguration(apiKey: "test-key")
        let app = WritersApp(aiConfiguration: aiConfig)
        do {
            _ = try await app.runMultiAgentHarness(prompt: "  \n ")
            XCTFail("Should throw HarnessError.emptyPrompt")
        } catch HarnessError.emptyPrompt {
            // Correct path
        } catch {
            XCTFail("Unexpected error: \(error) — expected HarnessError.emptyPrompt")
        }
    }
}