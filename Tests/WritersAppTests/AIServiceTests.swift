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
        XCTAssertEqual(AIModel.maxhermes.rawValue, "maxhermes-01")
    }

    func testAIModelDisplayNames() {
        XCTAssertEqual(AIModel.claude35Sonnet.displayName, "Claude 3.5 Sonnet")
        XCTAssertEqual(AIModel.claude3Opus.displayName, "Claude 3 Opus")
        XCTAssertEqual(AIModel.claude3Sonnet.displayName, "Claude 3 Sonnet")
        XCTAssertEqual(AIModel.claude3Haiku.displayName, "Claude 3 Haiku")
        XCTAssertEqual(AIModel.maxhermes.displayName, "MaxHermes")
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
}

// MARK: - AIModel.maxhermes Additional Tests (PR: MaxHermes/Minimax model support added)

final class AIModelMaxhermesTests: XCTestCase {

    // MARK: - Raw Value

    func testMaxhermesRawValueIsMaxhermes01() {
        XCTAssertEqual(AIModel.maxhermes.rawValue, "maxhermes-01")
    }

    func testMaxhermesRawValueDecodesBack() {
        let decoded = AIModel(rawValue: "maxhermes-01")
        XCTAssertNotNil(decoded, "maxhermes-01 must decode to a valid AIModel")
        XCTAssertEqual(decoded, .maxhermes)
    }

    func testMaxhermesDisplayNameIsMaxHermes() {
        XCTAssertEqual(AIModel.maxhermes.displayName, "MaxHermes")
    }

    // MARK: - Codable

    func testMaxhermesCodableRoundtrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try encoder.encode(AIModel.maxhermes)
        let decoded = try decoder.decode(AIModel.self, from: data)
        XCTAssertEqual(decoded, AIModel.maxhermes)
    }

    func testMaxhermesDecodesFromJSONString() throws {
        let json = "\"maxhermes-01\"".data(using: .utf8)!
        let decoded = try JSONDecoder().decode(AIModel.self, from: json)
        XCTAssertEqual(decoded, AIModel.maxhermes)
    }

    func testMaxhermesEncodesToExpectedJSONString() throws {
        let data = try JSONEncoder().encode(AIModel.maxhermes)
        let jsonString = String(data: data, encoding: .utf8)
        XCTAssertEqual(jsonString, "\"maxhermes-01\"")
    }

    // MARK: - AIConfiguration with maxhermes

    func testAIConfigurationWithMaxhermesModel() {
        let config = AIConfiguration(apiKey: "test-key", model: .maxhermes, maxTokens: 2048, temperature: 0.5)
        XCTAssertEqual(config.model, .maxhermes)
        XCTAssertEqual(config.model.rawValue, "maxhermes-01")
        XCTAssertEqual(config.model.displayName, "MaxHermes")
    }

    func testAIServiceInitWithMaxhermesConfig() {
        let config = AIConfiguration(apiKey: "test-key", model: .maxhermes)
        let service = AIService(configuration: config)
        XCTAssertNotNil(service)
    }

    // MARK: - Regression: maxhermes is distinct from all other models

    func testMaxhermesIsNotEqualToClaudeModels() {
        XCTAssertNotEqual(AIModel.maxhermes, AIModel.claude35Sonnet)
        XCTAssertNotEqual(AIModel.maxhermes, AIModel.claude3Opus)
        XCTAssertNotEqual(AIModel.maxhermes, AIModel.claude3Sonnet)
        XCTAssertNotEqual(AIModel.maxhermes, AIModel.claude3Haiku)
    }

    func testMaxhermesRawValueIsUniqueAmongAllModels() {
        let allRawValues: [String] = [
            AIModel.claude35Sonnet.rawValue,
            AIModel.claude3Opus.rawValue,
            AIModel.claude3Sonnet.rawValue,
            AIModel.claude3Haiku.rawValue,
        ]
        XCTAssertFalse(
            allRawValues.contains(AIModel.maxhermes.rawValue),
            "maxhermes rawValue must be unique among all AIModel cases"
        )
    }

    // MARK: - Boundary: invalid raw values still return nil

    func testInvalidRawValueReturnsNil() {
        XCTAssertNil(AIModel(rawValue: "maxhermes"))       // close but wrong
        XCTAssertNil(AIModel(rawValue: "maxhermes-02"))    // wrong version
        XCTAssertNil(AIModel(rawValue: "MaxHermes-01"))    // wrong casing
        XCTAssertNil(AIModel(rawValue: ""))
    }
}
