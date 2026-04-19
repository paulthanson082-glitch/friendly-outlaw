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