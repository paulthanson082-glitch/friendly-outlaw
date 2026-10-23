import XCTest
@testable import WritersApp

/// Tests for AI-related functionality including AIService, AIConfiguration, and error handling
final class AIServiceTests: XCTestCase {

    // MARK: - AIConfiguration Tests

    func testAIConfigurationDefaults() {
        let config = AIConfiguration(apiKey: "test-key")

        XCTAssertEqual(config.apiKey, "test-key")
        XCTAssertEqual(config.model, .claude35Sonnet)
        XCTAssertEqual(config.maxTokens, 4096)
        XCTAssertEqual(config.temperature, 0.7)
    }

    func testAIConfigurationCustomValues() {
        let config = AIConfiguration(
            apiKey: "custom-key",
            model: .claude3Haiku,
            maxTokens: 2048,
            temperature: 0.5
        )

        XCTAssertEqual(config.apiKey, "custom-key")
        XCTAssertEqual(config.model, .claude3Haiku)
        XCTAssertEqual(config.maxTokens, 2048)
        XCTAssertEqual(config.temperature, 0.5)
    }

    // MARK: - AIModel Tests

    func testAIModelRawValues() {
        XCTAssertEqual(AIModel.claude35Sonnet.rawValue, "claude-3-5-sonnet-20241022")
        XCTAssertEqual(AIModel.claude3Opus.rawValue, "claude-3-opus-20240229")
        XCTAssertEqual(AIModel.claude3Sonnet.rawValue, "claude-3-sonnet-20240229")
        XCTAssertEqual(AIModel.claude3Haiku.rawValue, "claude-3-haiku-20240307")
    }

    func testAIModelDisplayNames() {
        XCTAssertEqual(AIModel.claude35Sonnet.displayName, "Claude 3.5 Sonnet")
        XCTAssertEqual(AIModel.claude3Opus.displayName, "Claude 3 Opus")
        XCTAssertEqual(AIModel.claude3Sonnet.displayName, "Claude 3 Sonnet")
        XCTAssertEqual(AIModel.claude3Haiku.displayName, "Claude 3 Haiku")
    }

    // MARK: - AIService Initialization Tests

    func testAIServiceInitialization() {
        let config = AIConfiguration(apiKey: "test-key")
        let service = AIService(configuration: config)

        XCTAssertNotNil(service)
    }

    // MARK: - AIAssistanceType Tests

    func testAIAssistanceTypeDisplayNames() {
        XCTAssertEqual(AIAssistanceType.continueWriting.displayName, "Continue Writing")
        XCTAssertEqual(AIAssistanceType.improveText.displayName, "Improve Text")
        XCTAssertEqual(AIAssistanceType.grammarCheck.displayName, "Grammar Check")
        XCTAssertEqual(AIAssistanceType.styleSuggestions.displayName, "Style Suggestions")
        XCTAssertEqual(AIAssistanceType.generateOutline.displayName, "Generate Outline")
        XCTAssertEqual(AIAssistanceType.brainstormIdeas.displayName, "Brainstorm Ideas")
        XCTAssertEqual(AIAssistanceType.characterDevelopment.displayName, "Character Development")
        XCTAssertEqual(AIAssistanceType.plotSuggestions.displayName, "Plot Suggestions")
        XCTAssertEqual(AIAssistanceType.dialogueImprovement.displayName, "Dialogue Improvement")
        XCTAssertEqual(AIAssistanceType.descriptionEnhancement.displayName, "Description Enhancement")
        XCTAssertEqual(AIAssistanceType.titleGeneration.displayName, "Title Generation")
        XCTAssertEqual(AIAssistanceType.summarize.displayName, "Summarize")
        XCTAssertEqual(AIAssistanceType.expandText.displayName, "Expand Text")
        XCTAssertEqual(AIAssistanceType.simplifyText.displayName, "Simplify Text")
    }

    func testAIAssistanceTypeChangeToneDisplayName() {
        let professionalTone = AIAssistanceType.changetone(.professional)
        XCTAssertEqual(professionalTone.displayName, "Change Tone to Professional")

        let casualTone = AIAssistanceType.changetone(.casual)
        XCTAssertEqual(casualTone.displayName, "Change Tone to Casual")
    }

    func testAIAssistanceTypeCustomDisplayName() {
        let custom = AIAssistanceType.custom("Make it funnier")
        XCTAssertEqual(custom.displayName, "Custom Request")
    }

    func testAIAssistanceTypePromptGeneration() {
        let sampleText = "The quick brown fox"

        let continuePrompt = AIAssistanceType.continueWriting.prompt(for: sampleText)
        XCTAssertTrue(continuePrompt.contains(sampleText))
        XCTAssertTrue(continuePrompt.contains("Continue writing"))

        let improvePrompt = AIAssistanceType.improveText.prompt(for: sampleText)
        XCTAssertTrue(improvePrompt.contains(sampleText))
        XCTAssertTrue(improvePrompt.contains("Improve"))

        let grammarPrompt = AIAssistanceType.grammarCheck.prompt(for: sampleText)
        XCTAssertTrue(grammarPrompt.contains(sampleText))
        XCTAssertTrue(grammarPrompt.contains("grammar"))
    }

    func testAIAssistanceTypePromptWithContext() {
        let sampleText = "A dark and stormy night"
        let context = AIContext(
            genre: "Horror",
            targetAudience: "Young Adults"
        )

        let prompt = AIAssistanceType.continueWriting.prompt(for: sampleText, context: context)
        XCTAssertTrue(prompt.contains(sampleText))
        XCTAssertTrue(prompt.contains("Horror"))
        XCTAssertTrue(prompt.contains("Young Adults"))
    }

    // MARK: - AIContext Tests

    func testAIContextEmptyDescription() {
        let context = AIContext()
        XCTAssertEqual(context.description, "")
    }

    func testAIContextWithGenre() {
        let context = AIContext(genre: "Science Fiction")
        XCTAssertTrue(context.description.contains("Genre: Science Fiction"))
    }

    func testAIContextWithMultipleFields() {
        let context = AIContext(
            genre: "Mystery",
            targetAudience: "Adults",
            existingCharacters: ["Detective Smith", "Dr. Watson"],
            plotSummary: "A murder at the mansion",
            additionalNotes: "Set in 1920s"
        )

        let description = context.description
        XCTAssertTrue(description.contains("Genre: Mystery"))
        XCTAssertTrue(description.contains("Target Audience: Adults"))
        XCTAssertTrue(description.contains("Detective Smith"))
        XCTAssertTrue(description.contains("Dr. Watson"))
        XCTAssertTrue(description.contains("A murder at the mansion"))
        XCTAssertTrue(description.contains("Set in 1920s"))
    }

    func testAIContextWithEmptyCharacterArray() {
        let context = AIContext(existingCharacters: [])
        XCTAssertEqual(context.description, "")
    }

    // MARK: - AIResponse Tests

    func testAIResponseCreation() {
        let response = AIResponse(
            requestType: .improveText,
            originalText: "Original",
            generatedContent: "Improved version",
            model: .claude35Sonnet
        )

        XCTAssertEqual(response.originalText, "Original")
        XCTAssertEqual(response.generatedContent, "Improved version")
        XCTAssertEqual(response.model, .claude35Sonnet)
        XCTAssertNil(response.tokensUsed)
    }

    func testAIResponseWithTokens() {
        let response = AIResponse(
            requestType: .summarize,
            originalText: "Long text",
            generatedContent: "Summary",
            model: .claude3Haiku,
            tokensUsed: 150
        )

        XCTAssertEqual(response.tokensUsed, 150)
    }

    // MARK: - WritingTone Tests

    func testWritingToneDisplayNames() {
        XCTAssertEqual(WritingTone.professional.displayName, "Professional")
        XCTAssertEqual(WritingTone.casual.displayName, "Casual")
        XCTAssertEqual(WritingTone.academic.displayName, "Academic")
        XCTAssertEqual(WritingTone.creative.displayName, "Creative")
        XCTAssertEqual(WritingTone.humorous.displayName, "Humorous")
        XCTAssertEqual(WritingTone.serious.displayName, "Serious")
        XCTAssertEqual(WritingTone.enthusiastic.displayName, "Enthusiastic")
        XCTAssertEqual(WritingTone.empathetic.displayName, "Empathetic")
        XCTAssertEqual(WritingTone.persuasive.displayName, "Persuasive")
        XCTAssertEqual(WritingTone.informative.displayName, "Informative")
    }

    // MARK: - DocumentAnalysis Tests

    func testDocumentAnalysisCreation() {
        let documentId = UUID()
        let analysis = DocumentAnalysis(
            documentId: documentId,
            analysis: "This is a great document",
            timestamp: Date()
        )

        XCTAssertEqual(analysis.documentId, documentId)
        XCTAssertEqual(analysis.analysis, "This is a great document")
    }

    // MARK: - WritingInsights Tests

    func testWritingInsightsCreation() {
        let documentId = UUID()
        let insights = WritingInsights(
            documentId: documentId,
            insights: "Reading level: Grade 8",
            timestamp: Date()
        )

        XCTAssertEqual(insights.documentId, documentId)
        XCTAssertEqual(insights.insights, "Reading level: Grade 8")
    }

    // MARK: - AIServiceError Tests

    func testAIServiceErrorDescriptions() {
        XCTAssertEqual(AIServiceError.invalidURL.errorDescription, "Invalid API URL")
        XCTAssertEqual(AIServiceError.invalidResponse.errorDescription, "Invalid response from API")
        XCTAssertEqual(AIServiceError.invalidResponseFormat.errorDescription, "Could not parse API response")

        let apiError = AIServiceError.apiError(statusCode: 401, message: "Unauthorized")
        XCTAssertTrue(apiError.errorDescription?.contains("401") ?? false)
        XCTAssertTrue(apiError.errorDescription?.contains("Unauthorized") ?? false)

        struct MockError: Error {
            var localizedDescription: String { "Connection timeout" }
        }
        let networkError = AIServiceError.networkError(MockError())
        XCTAssertTrue(networkError.errorDescription?.contains("Network error") ?? false)
    }

    // MARK: - AIError Tests

    func testAIErrorDescriptions() {
        XCTAssertTrue(AIError.aiNotEnabled.errorDescription?.contains("AI features are not enabled") ?? false)
        XCTAssertTrue(AIError.documentNotFound.errorDescription?.contains("not found") ?? false)
    }

    // MARK: - AIModel Regression Tests (maxhermes removed)

    func testAIModelDoesNotContainMaxhermes() {
        // Regression: maxhermes was removed from AIModel; raw value must not decode
        XCTAssertNil(AIModel(rawValue: "maxhermes"),
                     "maxhermes should not be a valid AIModel case after removal")
    }

    func testAIModelCodableRoundtrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let models: [AIModel] = [.claude35Sonnet, .claude3Opus, .claude3Sonnet, .claude3Haiku]
        for model in models {
            let data = try encoder.encode(model)
            let decoded = try decoder.decode(AIModel.self, from: data)
            XCTAssertEqual(decoded, model, "Codable roundtrip failed for \(model)")
        }
    }

    func testAIModelExactCaseCount() {
        // Verify only 4 models are valid (maxhermes removed)
        let validRawValues = [
            "claude-3-5-sonnet-20241022",
            "claude-3-opus-20240229",
            "claude-3-sonnet-20240229",
            "claude-3-haiku-20240307"
        ]
        for raw in validRawValues {
            XCTAssertNotNil(AIModel(rawValue: raw), "Expected \(raw) to be a valid AIModel")
        }
    }

    // MARK: - AIAssistanceType Hallucination-Reduction Display Names

    func testAIAssistanceTypeHallucinationDisplayNames() {
        XCTAssertEqual(AIAssistanceType.brainstormIdeasCategorized.displayName, "Brainstorm Ideas (Categorized)")
        XCTAssertEqual(AIAssistanceType.extractQuotes.displayName, "Extract Quotes")
        XCTAssertEqual(AIAssistanceType.verifyWithCitations.displayName, "Verify with Citations")
        XCTAssertEqual(AIAssistanceType.analyzeWithUncertainty.displayName, "Analyze with Uncertainty")
        XCTAssertEqual(AIAssistanceType.chainOfThoughtVerification.displayName, "Chain of Thought Verification")
        XCTAssertEqual(AIAssistanceType.writingAdvisor.displayName, "Writing Advisor")
    }

    // MARK: - AIAssistanceType Hallucination-Reduction Prompt Generation

    func testExtractQuotesPromptContainsText() {
        let text = "He said 'Hello world' on page 42."
        let prompt = AIAssistanceType.extractQuotes.prompt(for: text)
        XCTAssertTrue(prompt.contains(text))
        XCTAssertTrue(prompt.contains("quotes"))
    }

    func testVerifyWithCitationsPromptContainsText() {
        let text = "The sky is blue because of Rayleigh scattering."
        let prompt = AIAssistanceType.verifyWithCitations.prompt(for: text)
        XCTAssertTrue(prompt.contains(text))
        XCTAssertTrue(prompt.contains("citations"))
    }

    func testAnalyzeWithUncertaintyPromptContainsText() {
        let text = "This document discusses economic trends."
        let prompt = AIAssistanceType.analyzeWithUncertainty.prompt(for: text)
        XCTAssertTrue(prompt.contains(text))
        XCTAssertTrue(prompt.contains("uncertain"))
    }

    func testChainOfThoughtVerificationPromptContainsText() {
        let text = "Climate change is accelerating."
        let prompt = AIAssistanceType.chainOfThoughtVerification.prompt(for: text)
        XCTAssertTrue(prompt.contains(text))
        XCTAssertTrue(prompt.contains("step"))
    }

    func testBrainstormIdeasCategorizedPromptContainsJSONSchema() {
        let text = "Space exploration missions"
        let prompt = AIAssistanceType.brainstormIdeasCategorized.prompt(for: text)
        XCTAssertTrue(prompt.contains(text))
        XCTAssertTrue(prompt.contains("categories"))
        XCTAssertTrue(prompt.contains("JSON"))
    }

    func testWritingAdvisorPromptContainsJSONSchema() {
        let text = "Writer has 500 words per day average."
        let prompt = AIAssistanceType.writingAdvisor.prompt(for: text)
        XCTAssertTrue(prompt.contains(text))
        XCTAssertTrue(prompt.contains("recommendations"))
        XCTAssertTrue(prompt.contains("JSON"))
    }

    // MARK: - QuoteBlock Tests

    func testQuoteBlockCreation() {
        let quote = QuoteBlock(
            text: "To be or not to be",
            reference: "Hamlet, Act III",
            relevanceExplanation: "Famous soliloquy"
        )
        XCTAssertEqual(quote.text, "To be or not to be")
        XCTAssertEqual(quote.reference, "Hamlet, Act III")
        XCTAssertEqual(quote.relevanceExplanation, "Famous soliloquy")
    }

    func testQuoteBlockWithNilReference() {
        let quote = QuoteBlock(text: "Some quote", relevanceExplanation: "Relevant")
        XCTAssertNil(quote.reference)
    }

    func testQuoteBlockCodableRoundtrip() throws {
        let original = QuoteBlock(
            text: "All that glitters is not gold",
            reference: "Merchant of Venice",
            relevanceExplanation: "Warns against appearances"
        )
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(QuoteBlock.self, from: data)
        XCTAssertEqual(decoded.text, original.text)
        XCTAssertEqual(decoded.reference, original.reference)
        XCTAssertEqual(decoded.relevanceExplanation, original.relevanceExplanation)
    }

    // MARK: - VerifiedClaim Tests

    func testVerifiedClaimCreation() {
        let claim = VerifiedClaim(
            claim: "Water boils at 100°C",
            supportingQuote: "At standard pressure, water boils at 100°C",
            evidence: "Physical chemistry reference",
            isVerified: true
        )
        XCTAssertEqual(claim.claim, "Water boils at 100°C")
        XCTAssertTrue(claim.isVerified)
        XCTAssertNil(claim.uncertaintyNote)
    }

    func testVerifiedClaimUnverified() {
        let claim = VerifiedClaim(
            claim: "Some unverifiable claim",
            evidence: "No supporting evidence found for this claim",
            isVerified: false,
            uncertaintyNote: "Could not find source"
        )
        XCTAssertFalse(claim.isVerified)
        XCTAssertEqual(claim.uncertaintyNote, "Could not find source")
    }

    func testVerifiedClaimCodableRoundtrip() throws {
        let original = VerifiedClaim(
            claim: "Test claim",
            supportingQuote: "Supporting text",
            evidence: "Evidence here",
            isVerified: true,
            uncertaintyNote: nil
        )
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(VerifiedClaim.self, from: data)
        XCTAssertEqual(decoded.claim, original.claim)
        XCTAssertEqual(decoded.isVerified, original.isVerified)
    }

    // MARK: - UncertaintyAwareAnalysis Tests

    func testUncertaintyAwareAnalysisDefaults() {
        let analysis = UncertaintyAwareAnalysis(analysis: "Some analysis")
        XCTAssertEqual(analysis.analysis, "Some analysis")
        XCTAssertTrue(analysis.confidenceAreas.isEmpty)
        XCTAssertTrue(analysis.uncertainAreas.isEmpty)
        XCTAssertTrue(analysis.informationGaps.isEmpty)
    }

    func testUncertaintyAwareAnalysisFull() {
        let analysis = UncertaintyAwareAnalysis(
            analysis: "Detailed analysis",
            confidenceAreas: ["Historical facts"],
            uncertainAreas: ["Future projections"],
            informationGaps: ["Missing primary sources"]
        )
        XCTAssertEqual(analysis.confidenceAreas.count, 1)
        XCTAssertEqual(analysis.uncertainAreas.count, 1)
        XCTAssertEqual(analysis.informationGaps.count, 1)
    }

    func testUncertaintyAwareAnalysisCodableRoundtrip() throws {
        let original = UncertaintyAwareAnalysis(
            analysis: "Analysis text",
            confidenceAreas: ["Area A"],
            uncertainAreas: ["Area B"],
            informationGaps: ["Gap C"]
        )
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(UncertaintyAwareAnalysis.self, from: data)
        XCTAssertEqual(decoded.analysis, original.analysis)
        XCTAssertEqual(decoded.confidenceAreas, original.confidenceAreas)
        XCTAssertEqual(decoded.uncertainAreas, original.uncertainAreas)
        XCTAssertEqual(decoded.informationGaps, original.informationGaps)
    }

    // MARK: - ReasoningStep Tests

    func testReasoningStepCreation() {
        let step = ReasoningStep(
            claim: "The text argues X",
            reasoning: "Because of evidence Y",
            assumptions: ["Author is reliable"],
            uncertainty: "May be outdated"
        )
        XCTAssertEqual(step.claim, "The text argues X")
        XCTAssertEqual(step.reasoning, "Because of evidence Y")
        XCTAssertEqual(step.assumptions, ["Author is reliable"])
        XCTAssertEqual(step.uncertainty, "May be outdated")
    }

    func testReasoningStepDefaults() {
        let step = ReasoningStep(claim: "A claim", reasoning: "Some reasoning")
        XCTAssertTrue(step.assumptions.isEmpty)
        XCTAssertNil(step.uncertainty)
    }

    func testReasoningStepCodableRoundtrip() throws {
        let original = ReasoningStep(
            claim: "Claim",
            reasoning: "Reasoning",
            assumptions: ["Assumption 1"],
            uncertainty: "Uncertain about X"
        )
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(ReasoningStep.self, from: data)
        XCTAssertEqual(decoded.claim, original.claim)
        XCTAssertEqual(decoded.reasoning, original.reasoning)
        XCTAssertEqual(decoded.assumptions, original.assumptions)
        XCTAssertEqual(decoded.uncertainty, original.uncertainty)
    }

    // MARK: - ChainOfThoughtAnalysis Tests

    func testChainOfThoughtAnalysisCreation() {
        let step = ReasoningStep(claim: "Step 1", reasoning: "Because A leads to B")
        let analysis = ChainOfThoughtAnalysis(
            reasoning: "Overall reasoning",
            steps: [step],
            assumptions: ["Premise 1"],
            uncertainties: ["Unknown variable"],
            conclusion: "Therefore, X is true"
        )
        XCTAssertEqual(analysis.steps.count, 1)
        XCTAssertEqual(analysis.assumptions.count, 1)
        XCTAssertEqual(analysis.uncertainties.count, 1)
        XCTAssertEqual(analysis.conclusion, "Therefore, X is true")
    }

    func testChainOfThoughtAnalysisDefaults() {
        let analysis = ChainOfThoughtAnalysis(reasoning: "Basic reasoning", conclusion: "Final answer")
        XCTAssertTrue(analysis.steps.isEmpty)
        XCTAssertTrue(analysis.assumptions.isEmpty)
        XCTAssertTrue(analysis.uncertainties.isEmpty)
    }

    func testChainOfThoughtAnalysisCodableRoundtrip() throws {
        let step = ReasoningStep(claim: "Claim", reasoning: "Reasoning")
        let original = ChainOfThoughtAnalysis(
            reasoning: "Full reasoning",
            steps: [step],
            assumptions: ["Assumption"],
            uncertainties: ["Uncertainty"],
            conclusion: "Conclusion"
        )
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(ChainOfThoughtAnalysis.self, from: data)
        XCTAssertEqual(decoded.reasoning, original.reasoning)
        XCTAssertEqual(decoded.conclusion, original.conclusion)
        XCTAssertEqual(decoded.steps.count, original.steps.count)
        XCTAssertEqual(decoded.assumptions, original.assumptions)
        XCTAssertEqual(decoded.uncertainties, original.uncertainties)
    }

    // MARK: - CategorizedIdea / IdeaCategory / BrainstormResult Tests

    func testCategorizedIdeaCreation() {
        let idea = CategorizedIdea(
            title: "Mars Colony",
            description: "Establish a human settlement on Mars",
            isSpeculative: true
        )
        XCTAssertEqual(idea.title, "Mars Colony")
        XCTAssertEqual(idea.description, "Establish a human settlement on Mars")
        XCTAssertTrue(idea.isSpeculative)
    }

    func testCategorizedIdeaCodableRoundtrip() throws {
        let original = CategorizedIdea(
            title: "Solar-powered trains",
            description: "Trains powered by solar panels",
            isSpeculative: false
        )
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(CategorizedIdea.self, from: data)
        XCTAssertEqual(decoded.title, original.title)
        XCTAssertEqual(decoded.description, original.description)
        XCTAssertEqual(decoded.isSpeculative, original.isSpeculative)
    }

    func testIdeaCategoryCreation() {
        let idea = CategorizedIdea(title: "Idea 1", description: "Desc", isSpeculative: false)
        let category = IdeaCategory(
            name: "Technology",
            description: "Tech-related ideas",
            ideas: [idea]
        )
        XCTAssertEqual(category.name, "Technology")
        XCTAssertEqual(category.ideas.count, 1)
    }

    func testBrainstormResultCodableRoundtrip() throws {
        let idea = CategorizedIdea(title: "Idea", description: "Desc", isSpeculative: false)
        let category = IdeaCategory(name: "Category", description: "Desc", ideas: [idea])
        let original = BrainstormResult(categories: [category])

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(BrainstormResult.self, from: data)
        XCTAssertEqual(decoded.categories.count, 1)
        XCTAssertEqual(decoded.categories[0].name, "Category")
        XCTAssertEqual(decoded.categories[0].ideas.count, 1)
        XCTAssertEqual(decoded.categories[0].ideas[0].title, "Idea")
    }

    func testBrainstormResultEmptyCategories() throws {
        let result = BrainstormResult(categories: [])
        XCTAssertTrue(result.categories.isEmpty)
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try encoder.encode(result)
        let decoded = try decoder.decode(BrainstormResult.self, from: data)
        XCTAssertTrue(decoded.categories.isEmpty)
    }

    // MARK: - ToolResult Error Flag Tests

    func testToolResultToDictWithoutError() {
        let result = ToolResult(toolUseId: "tool_001", content: "42 words")
        let dict = result.toDict()
        XCTAssertEqual(dict["type"] as? String, "tool_result")
        XCTAssertEqual(dict["tool_use_id"] as? String, "tool_001")
        XCTAssertEqual(dict["content"] as? String, "42 words")
        XCTAssertNil(dict["is_error"])
    }

    func testToolResultToDictWithError() {
        let result = ToolResult(toolUseId: "tool_002", content: "Document not found", isError: true)
        let dict = result.toDict()
        XCTAssertEqual(dict["is_error"] as? Bool, true)
    }

    // MARK: - ToolUseBlock Invalid Input Tests

    func testToolUseBlockRejectsWrongType() {
        let dict: [String: Any] = [
            "type": "text",
            "id": "toolu_123",
            "name": "get_word_count",
            "input": [:]
        ]
        XCTAssertNil(ToolUseBlock(from: dict))
    }

    func testToolUseBlockRejectsMissingType() {
        let dict: [String: Any] = [
            "id": "toolu_123",
            "name": "get_word_count",
            "input": [:]
        ]
        XCTAssertNil(ToolUseBlock(from: dict))
    }

    func testToolUseBlockRejectsMissingId() {
        let dict: [String: Any] = [
            "type": "tool_use",
            "name": "get_word_count",
            "input": [:]
        ]
        XCTAssertNil(ToolUseBlock(from: dict))
    }

    func testToolUseBlockRejectsMissingName() {
        let dict: [String: Any] = [
            "type": "tool_use",
            "id": "toolu_123",
            "input": [:]
        ]
        XCTAssertNil(ToolUseBlock(from: dict))
    }

    func testToolUseBlockWithMissingInput() {
        // input is optional — should fall back to empty dict
        let dict: [String: Any] = [
            "type": "tool_use",
            "id": "toolu_456",
            "name": "list_templates"
        ]
        let block = ToolUseBlock(from: dict)
        XCTAssertNotNil(block)
        XCTAssertTrue(block?.input.isEmpty ?? false)
    }
}
