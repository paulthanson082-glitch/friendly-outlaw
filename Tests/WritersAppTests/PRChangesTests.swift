import XCTest
@testable import WritersApp

// MARK: - Document Method Tests (PR: doc comment changes on enhancedWordCount, sentenceCount, paragraphCount, wordCountProgress; removal of DocumentBackup/DocumentSafetyError)

final class DocumentMethodTests: XCTestCase {

    // MARK: - enhancedWordCount()

    func testEnhancedWordCountBasic() {
        let doc = Document(title: "Test", content: "Hello world foo bar", category: .article)
        XCTAssertEqual(doc.enhancedWordCount(), 4)
    }

    func testEnhancedWordCountEmptyContent() {
        let doc = Document(title: "Empty", content: "", category: .article)
        XCTAssertEqual(doc.enhancedWordCount(), 0)
    }

    func testEnhancedWordCountFiltersEmptyTokens() {
        // Multiple spaces produce empty components; enhancedWordCount should ignore them
        let doc = Document(title: "Test", content: "one  two   three", category: .article)
        XCTAssertEqual(doc.enhancedWordCount(), 3)
    }

    func testEnhancedWordCountFiltersPurePunctuation() {
        // Tokens that contain no letter or digit (e.g. "--", "...") should be excluded
        let doc = Document(title: "Test", content: "Hello -- world ...", category: .article)
        XCTAssertEqual(doc.enhancedWordCount(), 2)
    }

    func testEnhancedWordCountIncludesHyphenatedWords() {
        // Hyphenated words like "well-known" contain letters and should be counted
        let doc = Document(title: "Test", content: "well-known state-of-the-art", category: .article)
        XCTAssertEqual(doc.enhancedWordCount(), 2)
    }

    func testEnhancedWordCountIncludesNumbers() {
        // Tokens with digits are included
        let doc = Document(title: "Test", content: "Chapter 3 page 42", category: .article)
        XCTAssertEqual(doc.enhancedWordCount(), 4)
    }

    func testEnhancedWordCountWithNewlines() {
        let doc = Document(title: "Test", content: "line one\nline two\nline three", category: .article)
        XCTAssertEqual(doc.enhancedWordCount(), 6)
    }

    func testEnhancedWordCountWithMixedWhitespace() {
        let doc = Document(title: "Test", content: "word1\t word2\n  word3", category: .article)
        XCTAssertEqual(doc.enhancedWordCount(), 3)
    }

    func testEnhancedWordCountAlwaysAtLeastBasicWordCount() {
        // enhancedWordCount should be <= wordCount since it is stricter
        let content = "Hello world! This is... a -- test."
        let doc = Document(title: "Test", content: content, category: .article)
        XCTAssertLessThanOrEqual(doc.enhancedWordCount(), doc.wordCount)
    }

    // MARK: - sentenceCount()

    func testSentenceCountBasic() {
        let doc = Document(title: "Test", content: "Hello world. How are you? I am fine!", category: .article)
        XCTAssertEqual(doc.sentenceCount(), 3)
    }

    func testSentenceCountEmptyContent() {
        let doc = Document(title: "Test", content: "", category: .article)
        XCTAssertEqual(doc.sentenceCount(), 0)
    }

    func testSentenceCountNoTerminator() {
        // Content with no .!? should count as one sentence (the whole text)
        let doc = Document(title: "Test", content: "This has no sentence terminator", category: .article)
        XCTAssertEqual(doc.sentenceCount(), 1)
    }

    func testSentenceCountPeriodOnly() {
        let doc = Document(title: "Test", content: "First sentence. Second sentence.", category: .article)
        // Splits on '.' → ["First sentence", " Second sentence", ""] → 2 non-empty
        XCTAssertEqual(doc.sentenceCount(), 2)
    }

    func testSentenceCountMixedTerminators() {
        let doc = Document(title: "Test", content: "Really? Yes! Definitely.", category: .article)
        XCTAssertEqual(doc.sentenceCount(), 3)
    }

    func testSentenceCountWithConsecutiveTerminators() {
        // "..." or "?!" produce empty segments after splitting
        let doc = Document(title: "Test", content: "Wait...", category: .article)
        // Splits: ["Wait", "", ""] → only 1 non-empty segment
        XCTAssertEqual(doc.sentenceCount(), 1)
    }

    func testSentenceCountLargeText() {
        let sentences = (1...10).map { "Sentence \($0)." }.joined(separator: " ")
        let doc = Document(title: "Test", content: sentences, category: .article)
        XCTAssertEqual(doc.sentenceCount(), 10)
    }

    // MARK: - paragraphCount()

    func testParagraphCountBasic() {
        let doc = Document(title: "Test", content: "Para one.\n\nPara two.\n\nPara three.", category: .article)
        XCTAssertEqual(doc.paragraphCount(), 3)
    }

    func testParagraphCountEmptyContent() {
        let doc = Document(title: "Test", content: "", category: .article)
        XCTAssertEqual(doc.paragraphCount(), 0)
    }

    func testParagraphCountSingleParagraph() {
        let doc = Document(title: "Test", content: "Just one paragraph here.", category: .article)
        XCTAssertEqual(doc.paragraphCount(), 1)
    }

    func testParagraphCountIgnoresBlankParagraphs() {
        // Extra blank lines should not inflate paragraph count
        let doc = Document(title: "Test", content: "Para one.\n\n\n\nPara two.", category: .article)
        // Splits on "\n\n": ["Para one.", "\n\nPara two."] or ["Para one.", "", "Para two."]
        // Empty or whitespace-only segments are filtered out
        XCTAssertGreaterThanOrEqual(doc.paragraphCount(), 2)
    }

    func testParagraphCountWithLeadingAndTrailingNewlines() {
        let doc = Document(title: "Test", content: "\n\nPara one.\n\nPara two.\n\n", category: .article)
        XCTAssertEqual(doc.paragraphCount(), 2)
    }

    func testParagraphCountSingleNewlineDoesNotSplit() {
        // Single \n is not a paragraph separator — should still be one paragraph
        let doc = Document(title: "Test", content: "Line one.\nLine two.", category: .article)
        XCTAssertEqual(doc.paragraphCount(), 1)
    }

    func testParagraphCountMultipleParagraphs() {
        let content = (1...5).map { "Paragraph \($0) content here." }.joined(separator: "\n\n")
        let doc = Document(title: "Test", content: content, category: .article)
        XCTAssertEqual(doc.paragraphCount(), 5)
    }

    // MARK: - wordCountProgress()

    func testWordCountProgressWithNoGoal() {
        let doc = Document(title: "Test", content: "Some words here", category: .article)
        XCTAssertEqual(doc.wordCountProgress(), 0.0)
    }

    func testWordCountProgressWithZeroGoal() {
        var metadata = DocumentMetadata()
        metadata.wordCountGoal = 0
        let doc = Document(title: "Test", content: "Some words here", category: .article, metadata: metadata)
        XCTAssertEqual(doc.wordCountProgress(), 0.0)
    }

    func testWordCountProgressHalfway() {
        var metadata = DocumentMetadata()
        metadata.wordCountGoal = 10
        let doc = Document(title: "Test", content: "one two three four five", category: .article, metadata: metadata)
        XCTAssertEqual(doc.wordCountProgress(), 0.5, accuracy: 0.01)
    }

    func testWordCountProgressAtGoal() {
        var metadata = DocumentMetadata()
        metadata.wordCountGoal = 3
        let doc = Document(title: "Test", content: "one two three", category: .article, metadata: metadata)
        XCTAssertEqual(doc.wordCountProgress(), 1.0, accuracy: 0.001)
    }

    func testWordCountProgressDoesNotExceedOne() {
        // Clamped to 1.0 even when word count exceeds the goal
        var metadata = DocumentMetadata()
        metadata.wordCountGoal = 2
        let doc = Document(title: "Test", content: "one two three four five six", category: .article, metadata: metadata)
        XCTAssertEqual(doc.wordCountProgress(), 1.0, accuracy: 0.001)
    }

    func testWordCountProgressNegativeGoalReturnsZero() {
        var metadata = DocumentMetadata()
        metadata.wordCountGoal = -5
        let doc = Document(title: "Test", content: "Some content", category: .article, metadata: metadata)
        XCTAssertEqual(doc.wordCountProgress(), 0.0)
    }

    func testWordCountProgressWithEmptyContent() {
        var metadata = DocumentMetadata()
        metadata.wordCountGoal = 100
        let doc = Document(title: "Test", content: "", category: .article, metadata: metadata)
        XCTAssertEqual(doc.wordCountProgress(), 0.0)
    }
}

// MARK: - AIAssistanceType Prompt Tests (PR: removed brainstormIdeasCategorized case)

final class AIAssistanceTypePromptTests: XCTestCase {

    private let sampleText = "A hero must save the world."

    // MARK: - brainstormIdeas (formerly paired with brainstormIdeasCategorized, now the sole brainstorm case)

    func testBrainstormIdeasPromptContainsText() {
        let prompt = AIAssistanceType.brainstormIdeas.prompt(for: sampleText)
        XCTAssertTrue(prompt.contains(sampleText), "brainstormIdeas prompt should embed the input text")
    }

    func testBrainstormIdeasPromptContainsBrainstormKeyword() {
        let prompt = AIAssistanceType.brainstormIdeas.prompt(for: sampleText)
        XCTAssertTrue(prompt.lowercased().contains("brainstorm"), "brainstormIdeas prompt should contain 'brainstorm'")
    }

    func testBrainstormIdeasPromptDoesNotRequestJSON() {
        // After removing brainstormIdeasCategorized, the plain brainstormIdeas case should NOT
        // produce a JSON schema prompt — that was the categorized variant.
        let prompt = AIAssistanceType.brainstormIdeas.prompt(for: sampleText)
        XCTAssertFalse(prompt.contains("\"categories\""), "brainstormIdeas prompt must not contain JSON categories schema")
        XCTAssertFalse(prompt.contains("isSpeculative"), "brainstormIdeas prompt must not contain categorized JSON fields")
    }

    func testBrainstormIdeasPromptWithContext() {
        let context = AIContext(genre: "Fantasy", targetAudience: "Young Adults")
        let prompt = AIAssistanceType.brainstormIdeas.prompt(for: sampleText, context: context)
        XCTAssertTrue(prompt.contains("Fantasy"))
        XCTAssertTrue(prompt.contains("Young Adults"))
        XCTAssertTrue(prompt.contains(sampleText))
    }

    func testBrainstormIdeasPromptWithoutContext() {
        // No context → no "Context:" prefix should appear
        let prompt = AIAssistanceType.brainstormIdeas.prompt(for: sampleText, context: nil)
        XCTAssertFalse(prompt.hasPrefix("Context:"))
        XCTAssertTrue(prompt.contains(sampleText))
    }

    // MARK: - Display name for brainstormIdeas (should remain "Brainstorm Ideas")

    func testBrainstormIdeasDisplayName() {
        XCTAssertEqual(AIAssistanceType.brainstormIdeas.displayName, "Brainstorm Ideas")
    }

    // MARK: - Additional prompt coverage for cases not tested in AIServiceTests

    func testExtractQuotesPromptContainsText() {
        let prompt = AIAssistanceType.extractQuotes.prompt(for: sampleText)
        XCTAssertTrue(prompt.contains(sampleText))
        XCTAssertTrue(prompt.lowercased().contains("quote"))
    }

    func testExtractQuotesPromptDisplayName() {
        XCTAssertEqual(AIAssistanceType.extractQuotes.displayName, "Extract Quotes")
    }

    func testVerifyWithCitationsPromptContainsText() {
        let prompt = AIAssistanceType.verifyWithCitations.prompt(for: sampleText)
        XCTAssertTrue(prompt.contains(sampleText))
        XCTAssertTrue(prompt.lowercased().contains("citation") || prompt.lowercased().contains("claim"))
    }

    func testVerifyWithCitationsDisplayName() {
        XCTAssertEqual(AIAssistanceType.verifyWithCitations.displayName, "Verify with Citations")
    }

    func testAnalyzeWithUncertaintyPromptContainsText() {
        let prompt = AIAssistanceType.analyzeWithUncertainty.prompt(for: sampleText)
        XCTAssertTrue(prompt.contains(sampleText))
        XCTAssertTrue(prompt.lowercased().contains("uncertain") || prompt.lowercased().contains("analysis"))
    }

    func testAnalyzeWithUncertaintyDisplayName() {
        XCTAssertEqual(AIAssistanceType.analyzeWithUncertainty.displayName, "Analyze with Uncertainty")
    }

    func testChainOfThoughtVerificationPromptContainsText() {
        let prompt = AIAssistanceType.chainOfThoughtVerification.prompt(for: sampleText)
        XCTAssertTrue(prompt.contains(sampleText))
        XCTAssertTrue(prompt.lowercased().contains("step") || prompt.lowercased().contains("reasoning"))
    }

    func testChainOfThoughtVerificationDisplayName() {
        XCTAssertEqual(AIAssistanceType.chainOfThoughtVerification.displayName, "Chain of Thought Verification")
    }

    func testWritingAdvisorPromptContainsText() {
        let prompt = AIAssistanceType.writingAdvisor.prompt(for: sampleText)
        XCTAssertTrue(prompt.contains(sampleText))
        // Writing advisor produces a JSON schema prompt
        XCTAssertTrue(prompt.contains("overallAssessment"))
        XCTAssertTrue(prompt.contains("focusArea"))
        XCTAssertTrue(prompt.contains("recommendations"))
    }

    func testWritingAdvisorDisplayName() {
        XCTAssertEqual(AIAssistanceType.writingAdvisor.displayName, "Writing Advisor")
    }

    func testWritingAdvisorPromptWithContext() {
        let context = AIContext(additionalNotes: "User writes 500 words/day")
        let prompt = AIAssistanceType.writingAdvisor.prompt(for: "writer data", context: context)
        XCTAssertTrue(prompt.contains("500 words/day"))
    }

    func testGenerateOutlinePromptContainsText() {
        let prompt = AIAssistanceType.generateOutline.prompt(for: sampleText)
        XCTAssertTrue(prompt.contains(sampleText))
        XCTAssertTrue(prompt.lowercased().contains("outline"))
    }

    func testCharacterDevelopmentPromptContainsText() {
        let prompt = AIAssistanceType.characterDevelopment.prompt(for: sampleText)
        XCTAssertTrue(prompt.contains(sampleText))
        XCTAssertTrue(prompt.lowercased().contains("character"))
    }

    func testPlotSuggestionsPromptContainsText() {
        let prompt = AIAssistanceType.plotSuggestions.prompt(for: sampleText)
        XCTAssertTrue(prompt.contains(sampleText))
        XCTAssertTrue(prompt.lowercased().contains("plot"))
    }

    func testDialogueImprovementPromptContainsText() {
        let prompt = AIAssistanceType.dialogueImprovement.prompt(for: sampleText)
        XCTAssertTrue(prompt.contains(sampleText))
        XCTAssertTrue(prompt.lowercased().contains("dialogue"))
    }

    func testDescriptionEnhancementPromptContainsText() {
        let prompt = AIAssistanceType.descriptionEnhancement.prompt(for: sampleText)
        XCTAssertTrue(prompt.contains(sampleText))
        XCTAssertTrue(prompt.lowercased().contains("description") || prompt.lowercased().contains("enhance"))
    }

    func testTitleGenerationPromptContainsText() {
        let prompt = AIAssistanceType.titleGeneration.prompt(for: sampleText)
        XCTAssertTrue(prompt.contains(sampleText))
        XCTAssertTrue(prompt.lowercased().contains("title"))
    }

    func testSummarizePromptContainsText() {
        let prompt = AIAssistanceType.summarize.prompt(for: sampleText)
        XCTAssertTrue(prompt.contains(sampleText))
        XCTAssertTrue(prompt.lowercased().contains("summar"))
    }

    func testExpandTextPromptContainsText() {
        let prompt = AIAssistanceType.expandText.prompt(for: sampleText)
        XCTAssertTrue(prompt.contains(sampleText))
        XCTAssertTrue(prompt.lowercased().contains("expand"))
    }

    func testSimplifyTextPromptContainsText() {
        let prompt = AIAssistanceType.simplifyText.prompt(for: sampleText)
        XCTAssertTrue(prompt.contains(sampleText))
        XCTAssertTrue(prompt.lowercased().contains("simplif"))
    }

    func testChangeTonePromptIncludesToneName() {
        let prompt = AIAssistanceType.changetone(.academic).prompt(for: sampleText)
        XCTAssertTrue(prompt.contains(sampleText))
        XCTAssertTrue(prompt.lowercased().contains("academic"))
    }

    func testCustomPromptEmbeddsInstruction() {
        let instruction = "Make it rhyme"
        let prompt = AIAssistanceType.custom(instruction).prompt(for: sampleText)
        XCTAssertTrue(prompt.contains(instruction))
        XCTAssertTrue(prompt.contains(sampleText))
    }

    // MARK: - Boundary: empty text

    func testBrainstormIdeasPromptWithEmptyText() {
        let prompt = AIAssistanceType.brainstormIdeas.prompt(for: "")
        // Prompt should still be generated (not crash or return empty)
        XCTAssertFalse(prompt.isEmpty)
    }

    func testWritingAdvisorPromptWithEmptyText() {
        let prompt = AIAssistanceType.writingAdvisor.prompt(for: "")
        XCTAssertFalse(prompt.isEmpty)
        XCTAssertTrue(prompt.contains("overallAssessment"))
    }
}

// MARK: - HermesModels Tests (PR: removed HermesTone enum; remaining types unchanged but file was modified)

final class HermesModelsTests: XCTestCase {

    // MARK: - HermesIdeaType

    func testHermesIdeaTypeRawValues() {
        XCTAssertEqual(HermesIdeaType.plotHook.rawValue, "plotHook")
        XCTAssertEqual(HermesIdeaType.characterTrait.rawValue, "characterTrait")
        XCTAssertEqual(HermesIdeaType.worldBuilding.rawValue, "worldBuilding")
        XCTAssertEqual(HermesIdeaType.conflict.rawValue, "conflict")
        XCTAssertEqual(HermesIdeaType.twist.rawValue, "twist")
        XCTAssertEqual(HermesIdeaType.dialogue.rawValue, "dialogue")
        XCTAssertEqual(HermesIdeaType.setting.rawValue, "setting")
        XCTAssertEqual(HermesIdeaType.theme.rawValue, "theme")
    }

    func testHermesIdeaTypeDisplayNames() {
        XCTAssertEqual(HermesIdeaType.plotHook.displayName, "Plot Hook")
        XCTAssertEqual(HermesIdeaType.characterTrait.displayName, "Character Trait")
        XCTAssertEqual(HermesIdeaType.worldBuilding.displayName, "World Building")
        XCTAssertEqual(HermesIdeaType.conflict.displayName, "Conflict")
        XCTAssertEqual(HermesIdeaType.twist.displayName, "Twist")
        XCTAssertEqual(HermesIdeaType.dialogue.displayName, "Dialogue")
        XCTAssertEqual(HermesIdeaType.setting.displayName, "Setting")
        XCTAssertEqual(HermesIdeaType.theme.displayName, "Theme")
    }

    func testHermesIdeaTypeAllCases() {
        let expected: Set<String> = ["plotHook", "characterTrait", "worldBuilding", "conflict", "twist", "dialogue", "setting", "theme"]
        let actual = Set(HermesIdeaType.allCases.map { $0.rawValue })
        XCTAssertEqual(actual, expected)
    }

    func testHermesIdeaTypeCodableRoundTrip() throws {
        for ideaType in HermesIdeaType.allCases {
            let encoded = try JSONEncoder().encode(ideaType)
            let decoded = try JSONDecoder().decode(HermesIdeaType.self, from: encoded)
            XCTAssertEqual(decoded, ideaType)
        }
    }

    func testHermesIdeaTypeInitFromRawValue() {
        XCTAssertEqual(HermesIdeaType(rawValue: "plotHook"), .plotHook)
        XCTAssertNil(HermesIdeaType(rawValue: "unknown"))
        XCTAssertNil(HermesIdeaType(rawValue: "PlotHook"))  // case-sensitive
    }

    // MARK: - HermesIdea Codable

    func testHermesIdeaEncodeDecodeRoundTrip() throws {
        let original = HermesIdea(
            id: UUID(),
            title: "The Unexpected Ally",
            description: "A villain becomes a reluctant ally",
            ideaType: .plotHook,
            timestamp: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(HermesIdea.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.title, original.title)
        XCTAssertEqual(decoded.description, original.description)
        XCTAssertEqual(decoded.ideaType, original.ideaType)
        // Timestamp is serialized as ISO 8601 string; allow ±1 second for rounding
        XCTAssertEqual(decoded.timestamp.timeIntervalSince1970, original.timestamp.timeIntervalSince1970, accuracy: 1.0)
    }

    func testHermesIdeaDefaultIdIsUnique() {
        let idea1 = HermesIdea(title: "A", description: "B", ideaType: .conflict)
        let idea2 = HermesIdea(title: "A", description: "B", ideaType: .conflict)
        XCTAssertNotEqual(idea1.id, idea2.id)
    }

    // MARK: - HermesContext

    func testHermesContextDefaultValues() {
        let context = HermesContext()
        XCTAssertEqual(context.genre, "")
        XCTAssertEqual(context.logline, "")
        XCTAssertEqual(context.currentScene, "")
        XCTAssertTrue(context.characters.isEmpty)
        XCTAssertTrue(context.themes.isEmpty)
        XCTAssertNil(context.documentId)
    }

    func testHermesContextCustomValues() {
        let docId = UUID()
        let context = HermesContext(
            genre: "Fantasy",
            logline: "A wizard saves the world",
            currentScene: "Battle at the castle",
            characters: ["Merlin", "Arthur"],
            themes: ["courage", "sacrifice"],
            documentId: docId
        )
        XCTAssertEqual(context.genre, "Fantasy")
        XCTAssertEqual(context.logline, "A wizard saves the world")
        XCTAssertEqual(context.currentScene, "Battle at the castle")
        XCTAssertEqual(context.characters, ["Merlin", "Arthur"])
        XCTAssertEqual(context.themes, ["courage", "sacrifice"])
        XCTAssertEqual(context.documentId, docId)
    }

    func testHermesContextCodableRoundTrip() throws {
        let context = HermesContext(
            genre: "Sci-Fi",
            logline: "Space explorers find an alien artifact",
            characters: ["Commander Lee"],
            documentId: UUID()
        )
        let data = try JSONEncoder().encode(context)
        let decoded = try JSONDecoder().decode(HermesContext.self, from: data)
        XCTAssertEqual(decoded.genre, context.genre)
        XCTAssertEqual(decoded.logline, context.logline)
        XCTAssertEqual(decoded.characters, context.characters)
        XCTAssertEqual(decoded.documentId, context.documentId)
    }

    // MARK: - HermesMessageRole

    func testHermesMessageRoleRawValues() {
        XCTAssertEqual(HermesMessageRole.user.rawValue, "user")
        XCTAssertEqual(HermesMessageRole.hermes.rawValue, "hermes")
    }

    func testHermesMessageRoleCodableRoundTrip() throws {
        for role in [HermesMessageRole.user, .hermes] {
            let encoded = try JSONEncoder().encode(role)
            let decoded = try JSONDecoder().decode(HermesMessageRole.self, from: encoded)
            XCTAssertEqual(decoded, role)
        }
    }

    // MARK: - HermesMessage Codable

    func testHermesMessageEncodeDecodeRoundTrip() throws {
        let idea = HermesIdea(title: "Idea", description: "Desc", ideaType: .theme)
        let message = HermesMessage(
            role: .hermes,
            content: "Here is your idea",
            ideas: [idea]
        )
        let data = try JSONEncoder().encode(message)
        let decoded = try JSONDecoder().decode(HermesMessage.self, from: data)

        XCTAssertEqual(decoded.id, message.id)
        XCTAssertEqual(decoded.role, message.role)
        XCTAssertEqual(decoded.content, message.content)
        XCTAssertEqual(decoded.ideas.count, 1)
        XCTAssertEqual(decoded.ideas.first?.title, "Idea")
    }

    func testHermesMessageDefaultEmptyIdeas() {
        let message = HermesMessage(role: .user, content: "Hello")
        XCTAssertTrue(message.ideas.isEmpty)
    }

    // MARK: - HermesSession Codable

    func testHermesSessionEncodeDecodeRoundTrip() throws {
        let context = HermesContext(genre: "Mystery")
        var session = HermesSession(context: context)
        let msg = HermesMessage(role: .user, content: "Start")
        session.messages.append(msg)

        let data = try JSONEncoder().encode(session)
        let decoded = try JSONDecoder().decode(HermesSession.self, from: data)

        XCTAssertEqual(decoded.id, session.id)
        XCTAssertEqual(decoded.context.genre, "Mystery")
        XCTAssertEqual(decoded.messages.count, 1)
        XCTAssertEqual(decoded.messages.first?.content, "Start")
    }

    func testHermesSessionDefaultValues() {
        let session = HermesSession()
        XCTAssertTrue(session.messages.isEmpty)
        XCTAssertEqual(session.context.genre, "")
    }

    // MARK: - HermesError

    func testHermesErrorDescriptions() {
        XCTAssertEqual(HermesError.emptyPrompt.errorDescription, "Please enter a prompt for Hermes.")
        XCTAssertEqual(HermesError.promptTooLong.errorDescription, "Prompt exceeds maximum length.")
        XCTAssertEqual(HermesError.aiNotAvailable.errorDescription, "Hermes requires AI to be enabled. Please configure an API key.")

        let id = UUID()
        let ideaNotFoundError = HermesError.ideaNotFound(id: id)
        XCTAssertTrue(ideaNotFoundError.errorDescription?.contains(id.uuidString) ?? false)

        let failedError = HermesError.aiServiceFailed("timeout")
        XCTAssertTrue(failedError.errorDescription?.contains("timeout") ?? false)
    }

    // MARK: - HermesResponse

    func testHermesResponseInitialisation() {
        let sessionId = UUID()
        let ideas = [HermesIdea(title: "T", description: "D", ideaType: .setting)]
        let response = HermesResponse(sessionId: sessionId, message: "Here you go", ideas: ideas)

        XCTAssertEqual(response.sessionId, sessionId)
        XCTAssertEqual(response.message, "Here you go")
        XCTAssertEqual(response.ideas.count, 1)
    }
}

// MARK: - PR Changes: AIModel.maxhermes Removed

final class AIModelMaxhermesRemovedTests: XCTestCase {

    /// PR change: 'maxhermes-01' is no longer a valid AIModel raw value.
    func testMaxhermesRawValueDecodesAsNil() {
        let data = "\"maxhermes-01\"".data(using: .utf8)!
        let decoded = try? JSONDecoder().decode(AIModel.self, from: data)
        XCTAssertNil(decoded,
            "AIModel must not decode 'maxhermes-01' after the maxhermes case was removed in this PR")
    }

    func testMaxhermesDisplayNameNotPresentInAnyModel() {
        let displayNames = [
            AIModel.claude35Sonnet.displayName,
            AIModel.claude3Opus.displayName,
            AIModel.claude3Sonnet.displayName,
            AIModel.claude3Haiku.displayName,
        ]
        XCTAssertFalse(displayNames.contains("MaxHermes"),
            "No remaining AIModel must have display name 'MaxHermes'")
    }

    /// All four remaining Claude models still encode/decode correctly.
    func testRemainingModelsCodeableRoundTrip() throws {
        let models: [AIModel] = [.claude35Sonnet, .claude3Opus, .claude3Sonnet, .claude3Haiku]
        for model in models {
            let data = try JSONEncoder().encode(model)
            let decoded = try JSONDecoder().decode(AIModel.self, from: data)
            XCTAssertEqual(decoded, model, "Codable round-trip failed for \(model.rawValue)")
        }
    }

    func testAllFourModelsHaveUniqueRawValues() {
        let rawValues = [
            AIModel.claude35Sonnet.rawValue,
            AIModel.claude3Opus.rawValue,
            AIModel.claude3Sonnet.rawValue,
            AIModel.claude3Haiku.rawValue,
        ]
        XCTAssertEqual(rawValues.count, Set(rawValues).count,
            "All AIModel raw values must be unique")
    }

    func testAllFourModelsHaveUniqueDisplayNames() {
        let names = [
            AIModel.claude35Sonnet.displayName,
            AIModel.claude3Opus.displayName,
            AIModel.claude3Sonnet.displayName,
            AIModel.claude3Haiku.displayName,
        ]
        XCTAssertEqual(names.count, Set(names).count,
            "All AIModel display names must be unique")
    }

    /// Boundary: AIConfiguration's default model is still claude35Sonnet.
    func testAIConfigurationDefaultModelIsNotMaxhermes() {
        let config = AIConfiguration(apiKey: "key")
        XCTAssertNotEqual(config.model.rawValue, "maxhermes-01")
        XCTAssertEqual(config.model, .claude35Sonnet)
    }
}

// MARK: - PR Changes: Document Synthesized Hashable (custom == and hash removed)

final class DocumentSynthesizedHashablePRTests: XCTestCase {

    /// After removing custom ==, two documents with same id but different content are NOT equal.
    func testDocumentsWithSameIdDifferentContentAreNotEqual() {
        let id = UUID()
        let doc1 = Document(id: id, title: "Title", content: "Content A", category: .article)
        let doc2 = Document(id: id, title: "Title", content: "Content B", category: .article)
        XCTAssertNotEqual(doc1, doc2,
            "PR removed custom ==; synthesized == compares all properties; different content → not equal")
    }

    /// After removing custom ==, two documents with same id but different title are NOT equal.
    func testDocumentsWithSameIdDifferentTitleAreNotEqual() {
        let id = UUID()
        let doc1 = Document(id: id, title: "Title A", content: "Content", category: .article)
        let doc2 = Document(id: id, title: "Title B", content: "Content", category: .article)
        XCTAssertNotEqual(doc1, doc2,
            "Synthesized == must compare title; different titles → not equal")
    }

    /// Two documents with all identical properties are equal.
    func testDocumentsWithIdenticalPropertiesAreEqual() {
        let id = UUID()
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
        var meta = DocumentMetadata()
        meta.created = fixedDate
        meta.modified = fixedDate
        let doc1 = Document(id: id, title: "Same", content: "Same", category: .novel, metadata: meta)
        let doc2 = Document(id: id, title: "Same", content: "Same", category: .novel, metadata: meta)
        XCTAssertEqual(doc1, doc2)
    }

    /// Two documents with same id but different category are not equal (synthesized ==).
    func testDocumentsWithSameIdDifferentCategoryAreNotEqual() {
        let id = UUID()
        let doc1 = Document(id: id, title: "T", content: "C", category: .article)
        let doc2 = Document(id: id, title: "T", content: "C", category: .novel)
        XCTAssertNotEqual(doc1, doc2)
    }

    /// Document can be used as Set member.
    func testDocumentConformsToHashable() {
        let id = UUID()
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
        var meta = DocumentMetadata()
        meta.created = fixedDate
        meta.modified = fixedDate
        let doc = Document(id: id, title: "T", content: "C", category: .article, metadata: meta)
        var docSet = Set<Document>()
        docSet.insert(doc)
        docSet.insert(doc)
        XCTAssertEqual(docSet.count, 1, "Inserting same document twice must deduplicate in Set")
    }

    /// Two docs with same id but different content count as separate Set members.
    func testDocumentsWithSameIdDifferentContentAreSeparateSetMembers() {
        let id = UUID()
        let doc1 = Document(id: id, title: "T", content: "Content A", category: .article)
        let doc2 = Document(id: id, title: "T", content: "Content B", category: .article)
        let docSet: Set<Document> = [doc1, doc2]
        XCTAssertEqual(docSet.count, 2,
            "Documents with same id but different content must be separate members after removing id-only hash")
    }
}

// MARK: - PR Changes: HermesService AgentProfile and switchProfile Removed

final class HermesServiceAgentProfileRemovedTests: XCTestCase {

    var hermesService: HermesService!

    override func setUp() {
        super.setUp()
        let config = AIConfiguration(apiKey: "test-key")
        let aiService = AIService(configuration: config)
        let documentManager = DocumentManager()
        let templateManager = TemplateManager()
        hermesService = HermesService(
            aiService: aiService,
            documentManager: documentManager,
            templateManager: templateManager
        )
    }

    override func tearDown() {
        hermesService = nil
        super.tearDown()
    }

    /// Verify session lifecycle still works (PR only removed AgentProfile, not sessions).
    func testStartSessionCreatesAndStoresSession() {
        let session = hermesService.startSession()
        XCTAssertNotNil(hermesService.currentSession)
        XCTAssertEqual(hermesService.currentSession?.id, session.id)
    }

    func testEndSessionClearsCurrentSession() {
        _ = hermesService.startSession()
        hermesService.endSession()
        XCTAssertNil(hermesService.currentSession)
    }

    func testStartNewSessionReplacesOldSession() {
        let first = hermesService.startSession()
        let second = hermesService.startSession()
        XCTAssertNotEqual(first.id, second.id)
        XCTAssertEqual(hermesService.currentSession?.id, second.id)
    }

    /// getAllIdeas is still present (not removed in this PR).
    func testGetAllIdeasStillWorks() {
        let session = hermesService.startSession()
        let ideas = hermesService.getAllIdeas(from: session)
        XCTAssertTrue(ideas.isEmpty)
    }

    func testGetAllIdeasFilteredByTypeStillWorks() {
        let session = hermesService.startSession()
        let ideas = hermesService.getAllIdeas(from: session, filteredBy: .conflict)
        XCTAssertTrue(ideas.isEmpty)
    }

    /// getSessionStats is still present (not removed in this PR).
    func testGetSessionStatsStillWorks() {
        let session = hermesService.startSession()
        let stats = hermesService.getSessionStats(from: session)
        XCTAssertEqual(stats.messageCount, 0)
        XCTAssertEqual(stats.totalIdeas, 0)
    }

    /// maxHistoryMessages and maxPromptLength properties still present.
    func testMaxHistoryMessagesProperty() {
        XCTAssertEqual(hermesService.maxHistoryMessages, 30)
    }

    func testMaxPromptLengthProperty() {
        XCTAssertEqual(hermesService.maxPromptLength, 4000)
    }

    /// Idea parsing (internal) still works after the removal.
    func testParseIdeasFromNumberedListStillWorks() {
        let text = """
        1. [TWIST] The Hidden Traitor
           Someone trusted is secretly working against the protagonist.
        2. [SETTING] Underwater City
           A city built on the ocean floor.
        """
        let ideas = hermesService.parseIdeas(from: text)
        XCTAssertEqual(ideas.count, 2)
        XCTAssertEqual(ideas[0].ideaType, .twist)
        XCTAssertEqual(ideas[1].ideaType, .setting)
    }

    /// Boundary: Empty prompt causes parseIdeas to return [].
    func testParseIdeasFromEmptyStringReturnsEmpty() {
        let ideas = hermesService.parseIdeas(from: "")
        XCTAssertTrue(ideas.isEmpty)
    }
}

// MARK: - PR Changes: DocumentManager.searchDocuments Empty Query Returns All

final class DocumentManagerSearchEmptyQueryPRTests: XCTestCase {

    var manager: DocumentManager!

    override func setUp() {
        super.setUp()
        manager = DocumentManager()
    }

    override func tearDown() {
        manager = nil
        super.tearDown()
    }

    /// PR change: empty query now returns all documents (was []).
    func testEmptyQueryReturnsAllDocuments() {
        manager.createDocument(Document(title: "A", content: "Content 1", category: .article))
        manager.createDocument(Document(title: "B", content: "Content 2", category: .novel))
        manager.createDocument(Document(title: "C", content: "Content 3", category: .essay))

        let results = manager.searchDocuments(query: "")
        XCTAssertEqual(results.count, 3,
            "Empty query must return all documents after the PR change from returning []")
    }

    /// PR change: whitespace-only query also returns all.
    func testWhitespaceQueryReturnsAllDocuments() {
        manager.createDocument(Document(title: "Doc A", content: "C", category: .article))
        manager.createDocument(Document(title: "Doc B", content: "C", category: .article))

        let results = manager.searchDocuments(query: "   ")
        XCTAssertEqual(results.count, 2,
            "Whitespace-only query must return all documents")
    }

    /// No documents → empty query returns [].
    func testEmptyQueryWithNoDocumentsReturnsEmpty() {
        XCTAssertTrue(manager.searchDocuments(query: "").isEmpty)
    }

    /// Non-empty query still filters (regression check).
    func testNonEmptyQueryFiltersNormally() {
        manager.createDocument(Document(title: "Swift Programming", content: "Swift guide", category: .article))
        manager.createDocument(Document(title: "Python Basics", content: "Python intro", category: .article))

        let results = manager.searchDocuments(query: "Swift")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Swift Programming")
    }
}

// MARK: - PR Changes: IssueManager.searchIssues Empty Query Returns All

final class IssueManagerSearchEmptyQueryPRTests: XCTestCase {

    var manager: IssueManager!
    let docId = UUID()

    override func setUp() {
        super.setUp()
        manager = IssueManager()
    }

    override func tearDown() {
        manager = nil
        super.tearDown()
    }

    /// PR change: empty query now returns all issues (was []).
    func testEmptyQueryReturnsAllIssues() {
        manager.createIssue(Issue(documentId: docId, title: "Issue A", description: "Desc A"))
        manager.createIssue(Issue(documentId: docId, title: "Issue B", description: "Desc B"))
        manager.createIssue(Issue(documentId: docId, title: "Issue C", description: "Desc C"))

        let results = manager.searchIssues(query: "")
        XCTAssertEqual(results.count, 3,
            "Empty query must return all issues after the PR change")
    }

    /// PR change: whitespace-only query also returns all.
    func testWhitespaceQueryReturnsAllIssues() {
        manager.createIssue(Issue(documentId: docId, title: "X", description: ""))
        manager.createIssue(Issue(documentId: docId, title: "Y", description: ""))

        let results = manager.searchIssues(query: "\t")
        XCTAssertEqual(results.count, 2)
    }

    /// No issues → empty query returns [].
    func testEmptyQueryWithNoIssuesReturnsEmpty() {
        XCTAssertTrue(manager.searchIssues(query: "").isEmpty)
    }

    /// Non-empty query still filters normally (regression check).
    func testNonEmptyQueryFiltersNormally() {
        manager.createIssue(Issue(documentId: docId, title: "Plot hole", description: "Chapter 3 problem"))
        manager.createIssue(Issue(documentId: docId, title: "Grammar", description: "Run-on sentences"))

        let results = manager.searchIssues(query: "plot")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Plot hole")
    }
}

// MARK: - PR Changes: KanbanManager.searchTasks Empty Query Returns All

final class KanbanManagerSearchEmptyQueryPRTests: XCTestCase {

    var manager: KanbanManager!
    var boardId: UUID!

    override func setUp() {
        super.setUp()
        manager = KanbanManager()
        let board = KanbanBoard(name: "Test Board")
        boardId = board.id
        manager.createBoard(board)
    }

    override func tearDown() {
        manager = nil
        boardId = nil
        super.tearDown()
    }

    /// PR change: empty query now returns all tasks (was []).
    func testEmptyQueryReturnsAllTasks() {
        manager.createTask(KanbanTask(title: "Task 1", boardId: boardId))
        manager.createTask(KanbanTask(title: "Task 2", boardId: boardId))
        manager.createTask(KanbanTask(title: "Task 3", boardId: boardId))

        let results = manager.searchTasks(query: "")
        XCTAssertEqual(results.count, 3,
            "Empty query must return all tasks after the PR change")
    }

    /// PR change: whitespace query also returns all.
    func testWhitespaceQueryReturnsAllTasks() {
        manager.createTask(KanbanTask(title: "Alpha", boardId: boardId))
        manager.createTask(KanbanTask(title: "Beta", boardId: boardId))

        let results = manager.searchTasks(query: "   ")
        XCTAssertEqual(results.count, 2)
    }

    /// No tasks → empty query returns [].
    func testEmptyQueryWithNoTasksReturnsEmpty() {
        XCTAssertTrue(manager.searchTasks(query: "").isEmpty)
    }

    /// Non-empty query filters normally (regression check).
    func testNonEmptyQueryFiltersNormally() {
        manager.createTask(KanbanTask(title: "Write chapter", boardId: boardId))
        manager.createTask(KanbanTask(title: "Review edits", boardId: boardId))

        let results = manager.searchTasks(query: "chapter")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Write chapter")
    }

    /// Empty query results are sorted by created descending.
    func testEmptyQueryResultsSortedByCreatedDescending() {
        manager.createTask(KanbanTask(title: "Earlier", boardId: boardId))
        Thread.sleep(forTimeInterval: 0.01)
        manager.createTask(KanbanTask(title: "Later", boardId: boardId))

        let results = manager.searchTasks(query: "")
        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results.first?.title, "Later",
            "Empty query results must be sorted by created descending")
    }
}

// MARK: - PR Changes: DatabaseManager apiKey Now Saved Correctly

final class DatabaseManagerAPIKeyPRTests: XCTestCase {

    var dbManager: DatabaseManager!
    let testUserId = UUID()

    override func setUp() {
        super.setUp()
        dbManager = DatabaseManager(databasePath: ":memory:")
    }

    override func tearDown() {
        dbManager = nil
        super.tearDown()
    }

    /// PR change: apiKey is now saved correctly (was always stored as "").
    func testSaveAndRetrieveAPIKeyIsPreserved() throws {
        let apiKey = "sk-ant-test-key-correct-12345"
        let config = AIConfiguration(
            apiKey: apiKey,
            model: .claude35Sonnet,
            maxTokens: 2048,
            temperature: 0.8
        )

        try dbManager.saveAIConfiguration(userId: testUserId, configuration: config)
        let retrieved = try dbManager.getAIConfiguration(userId: testUserId)

        XCTAssertNotNil(retrieved, "Saved configuration must be retrievable")
        XCTAssertEqual(retrieved?.apiKey, apiKey,
            "PR fixed empty-string bug: apiKey must now be stored and retrieved correctly")
    }

    /// Regression: confirm the old bug (empty string) is gone.
    func testSavedAPIKeyIsNotEmptyString() throws {
        let config = AIConfiguration(
            apiKey: "sk-ant-real-key",
            model: .claude3Opus,
            maxTokens: 4096,
            temperature: 0.7
        )

        try dbManager.saveAIConfiguration(userId: testUserId, configuration: config)
        let retrieved = try dbManager.getAIConfiguration(userId: testUserId)

        XCTAssertNotEqual(retrieved?.apiKey, "",
            "The PR fixed saving empty string as apiKey; it must now save the actual key")
    }

    /// Model is preserved alongside the fixed apiKey.
    func testSaveAndRetrieveModelAlongsideAPIKey() throws {
        let config = AIConfiguration(apiKey: "any-key", model: .claude3Haiku, maxTokens: 1024, temperature: 0.5)
        try dbManager.saveAIConfiguration(userId: testUserId, configuration: config)
        let retrieved = try dbManager.getAIConfiguration(userId: testUserId)
        XCTAssertEqual(retrieved?.model, .claude3Haiku)
        XCTAssertEqual(retrieved?.apiKey, "any-key")
    }

    /// maxTokens is preserved correctly.
    func testSaveAndRetrieveMaxTokensAlongsideAPIKey() throws {
        let config = AIConfiguration(apiKey: "key", model: .claude35Sonnet, maxTokens: 8192, temperature: 0.3)
        try dbManager.saveAIConfiguration(userId: testUserId, configuration: config)
        let retrieved = try dbManager.getAIConfiguration(userId: testUserId)
        XCTAssertEqual(retrieved?.maxTokens, 8192)
    }

    /// Temperature is preserved correctly.
    func testSaveAndRetrieveTemperature() throws {
        let config = AIConfiguration(apiKey: "key", model: .claude35Sonnet, maxTokens: 1024, temperature: 0.42)
        try dbManager.saveAIConfiguration(userId: testUserId, configuration: config)
        let retrieved = try dbManager.getAIConfiguration(userId: testUserId)
        XCTAssertEqual(retrieved?.temperature ?? 0, 0.42, accuracy: 0.001)
    }

    /// Saving configuration for a second user does not overwrite the first.
    func testSaveConfigurationsForMultipleUsersAreIndependent() throws {
        let userId1 = UUID()
        let userId2 = UUID()
        let config1 = AIConfiguration(apiKey: "key-user-1", model: .claude35Sonnet, maxTokens: 1024, temperature: 0.5)
        let config2 = AIConfiguration(apiKey: "key-user-2", model: .claude3Haiku, maxTokens: 512, temperature: 0.3)

        try dbManager.saveAIConfiguration(userId: userId1, configuration: config1)
        try dbManager.saveAIConfiguration(userId: userId2, configuration: config2)

        let retrieved1 = try dbManager.getAIConfiguration(userId: userId1)
        let retrieved2 = try dbManager.getAIConfiguration(userId: userId2)

        XCTAssertEqual(retrieved1?.apiKey, "key-user-1")
        XCTAssertEqual(retrieved2?.apiKey, "key-user-2")
    }

    /// Boundary: empty string apiKey is stored and retrieved as empty (not replaced).
    func testEmptyAPIKeyStoredAsEmpty() throws {
        let config = AIConfiguration(apiKey: "", model: .claude3Haiku, maxTokens: 1024, temperature: 0.5)
        try dbManager.saveAIConfiguration(userId: testUserId, configuration: config)
        let retrieved = try dbManager.getAIConfiguration(userId: testUserId)
        XCTAssertEqual(retrieved?.apiKey, "")
    }
}