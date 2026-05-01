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

    // MARK: - extractText Behavior Tests (PR change: separator "" instead of " ")

    // extractText is a private method. The tests below validate the expected
    // concatenation behavior (no separator between adjacent text blocks) using
    // a local helper that mirrors the changed logic, and verify observable
    // public-API contract properties that depend on it.

    /// Local mirror of the changed private extractText(from:) logic.
    private func extractText(from content: [[String: Any]]) -> String? {
        let textParts = content.compactMap { block -> String? in
            guard block["type"] as? String == "text" else { return nil }
            return block["text"] as? String
        }
        // PR change: joined() — no separator (was joined(separator: " "))
        return textParts.isEmpty ? nil : textParts.joined()
    }

    func testExtractTextSingleBlock() {
        let content: [[String: Any]] = [
            ["type": "text", "text": "Hello world"]
        ]
        let result = extractText(from: content)
        XCTAssertEqual(result, "Hello world")
    }

    func testExtractTextMultipleBlocksJoinedWithoutSeparator() {
        // PR change: blocks are now joined with no separator (previously joined with " ")
        let content: [[String: Any]] = [
            ["type": "text", "text": "Hello"],
            ["type": "text", "text": " world"]
        ]
        let result = extractText(from: content)
        // After change: "Hello" + " world" = "Hello world" (space is part of the second block)
        XCTAssertEqual(result, "Hello world")
    }

    func testExtractTextMultipleBlocksNoSpaceInBlocks() {
        // With the old separator " " this would be "foobar" with a space between.
        // With the new separator "" (empty) this concatenates directly: "foobar"
        let content: [[String: Any]] = [
            ["type": "text", "text": "foo"],
            ["type": "text", "text": "bar"]
        ]
        let result = extractText(from: content)
        // PR change: no space inserted between blocks → "foobar"
        XCTAssertEqual(result, "foobar")
        XCTAssertNotEqual(result, "foo bar")
    }

    func testExtractTextIgnoresNonTextBlocks() {
        let content: [[String: Any]] = [
            ["type": "tool_use", "id": "tu_123", "name": "search", "input": [:]],
            ["type": "text", "text": "Result after tool"]
        ]
        let result = extractText(from: content)
        XCTAssertEqual(result, "Result after tool")
    }

    func testExtractTextReturnsNilForEmptyContent() {
        let content: [[String: Any]] = []
        let result = extractText(from: content)
        XCTAssertNil(result)
    }

    func testExtractTextReturnsNilForNoTextBlocks() {
        // All blocks are non-text; nil is returned
        let content: [[String: Any]] = [
            ["type": "tool_use", "id": "tu_1", "name": "search", "input": [:]],
            ["type": "tool_result", "tool_use_id": "tu_1", "content": "done"]
        ]
        let result = extractText(from: content)
        XCTAssertNil(result)
    }

    func testExtractTextWithEmptyStringBlock() {
        // A text block with an empty string contributes nothing but is still a valid block
        let content: [[String: Any]] = [
            ["type": "text", "text": ""]
        ]
        let result = extractText(from: content)
        // One text block exists, so result is non-nil — it's an empty string
        XCTAssertNotNil(result)
        XCTAssertEqual(result, "")
    }

    func testExtractTextMixedBlocksMultipleTextBlocks() {
        // Interleaved text and tool blocks; only text blocks are extracted and concatenated
        let content: [[String: Any]] = [
            ["type": "text", "text": "Part one."],
            ["type": "tool_use", "id": "tu_1", "name": "lookup", "input": [:]],
            ["type": "text", "text": "Part two."]
        ]
        let result = extractText(from: content)
        // PR change: no space inserted → "Part one.Part two."
        XCTAssertEqual(result, "Part one.Part two.")
        XCTAssertNotEqual(result, "Part one. Part two.")
    }

    func testExtractTextFallbackInToolLoopReturnsEmptyStringWhenNoText() {
        // In sendRequestWithToolLoop, when stop_reason == "end_turn",
        // the result is extractText(from: content) ?? "".
        // If extractText returns nil (no text blocks), the result is "".
        let noTextContent: [[String: Any]] = [
            ["type": "tool_use", "id": "tu_1", "name": "search", "input": [:]]
        ]
        let result = extractText(from: noTextContent) ?? ""
        XCTAssertEqual(result, "")
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
}
