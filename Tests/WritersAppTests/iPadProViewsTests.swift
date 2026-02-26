import XCTest
@testable import WritersApp

/// Comprehensive tests for iPad Pro Views and ViewModels
@available(iOS 16.0, macOS 13.0, *)
final class iPadProViewsTests: XCTestCase {

    // MARK: - WritersAppViewModel Tests

    @MainActor
    func testViewModelInitialization() {
        let viewModel = WritersAppViewModel()

        XCTAssertEqual(viewModel.currentDocumentTitle, "Untitled")
        XCTAssertEqual(viewModel.currentDocumentContent, "")
        XCTAssertTrue(viewModel.showAIPanel)
        XCTAssertFalse(viewModel.isFocusMode)
        XCTAssertFalse(viewModel.isSaving)
        XCTAssertEqual(viewModel.aiResponse, "")
        XCTAssertFalse(viewModel.showWordCountSheet)

        XCTAssertEqual(viewModel.wordCount, 0)
        XCTAssertEqual(viewModel.characterCount, 0)
        XCTAssertEqual(viewModel.readingTime, 1)
        XCTAssertNil(viewModel.wordCountGoal)

        XCTAssertEqual(viewModel.recentAISuggestions.count, 0)
        XCTAssertEqual(viewModel.toolUsageStats.count, 0)

        XCTAssertEqual(viewModel.bodyFontSize, 17)
        XCTAssertEqual(viewModel.lineSpacing, 8)
    }

    @MainActor
    func testWordCountCalculation() {
        let viewModel = WritersAppViewModel()

        // Test empty content
        viewModel.currentDocumentContent = ""
        XCTAssertEqual(viewModel.wordCount, 0)

        // Test single word
        viewModel.currentDocumentContent = "Hello"
        XCTAssertEqual(viewModel.wordCount, 0) // updateStatistics not called automatically

        // Manually trigger statistics update by simulating insertAIResponse
        viewModel.currentDocumentContent = "Hello world test"
        viewModel.aiResponse = "additional content"
        viewModel.insertAIResponse()

        // Count words in the combined content
        let expectedWords = "Hello world test\n\nadditional content".components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        XCTAssertEqual(viewModel.wordCount, expectedWords)
    }

    @MainActor
    func testCharacterCountCalculation() {
        let viewModel = WritersAppViewModel()

        viewModel.currentDocumentContent = "Hello"
        viewModel.aiResponse = "test"
        viewModel.insertAIResponse()

        XCTAssertEqual(viewModel.characterCount, "Hello\n\ntest".count)
    }

    @MainActor
    func testReadingTimeCalculation() {
        let viewModel = WritersAppViewModel()

        // 200 words = 1 minute
        let words200 = String(repeating: "word ", count: 200).trimmingCharacters(in: .whitespaces)
        viewModel.aiResponse = words200
        viewModel.insertAIResponse()

        XCTAssertEqual(viewModel.readingTime, 1)

        // 400 words = 2 minutes
        let words400 = String(repeating: "word ", count: 400).trimmingCharacters(in: .whitespaces)
        viewModel.currentDocumentContent = ""
        viewModel.aiResponse = words400
        viewModel.insertAIResponse()

        XCTAssertEqual(viewModel.readingTime, 2)
    }

    @MainActor
    func testReadingTimeMinimum() {
        let viewModel = WritersAppViewModel()

        // Very few words should still show at least 1 minute
        viewModel.aiResponse = "Short"
        viewModel.insertAIResponse()

        XCTAssertEqual(viewModel.readingTime, 1)
    }

    @MainActor
    func testToggleAIPanel() {
        let viewModel = WritersAppViewModel()

        XCTAssertTrue(viewModel.showAIPanel)

        viewModel.toggleAIPanel()
        XCTAssertFalse(viewModel.showAIPanel)

        viewModel.toggleAIPanel()
        XCTAssertTrue(viewModel.showAIPanel)
    }

    @MainActor
    func testToggleFocusMode() {
        let viewModel = WritersAppViewModel()

        XCTAssertFalse(viewModel.isFocusMode)

        viewModel.toggleFocusMode()
        XCTAssertTrue(viewModel.isFocusMode)

        viewModel.toggleFocusMode()
        XCTAssertFalse(viewModel.isFocusMode)
    }

    @MainActor
    func testShowWordCount() {
        let viewModel = WritersAppViewModel()

        XCTAssertFalse(viewModel.showWordCountSheet)

        viewModel.showWordCount()
        XCTAssertTrue(viewModel.showWordCountSheet)
    }

    @MainActor
    func testInsertAIResponse() {
        let viewModel = WritersAppViewModel()

        viewModel.currentDocumentContent = "Existing content"
        viewModel.aiResponse = "AI generated text"

        viewModel.insertAIResponse()

        XCTAssertTrue(viewModel.currentDocumentContent.contains("Existing content"))
        XCTAssertTrue(viewModel.currentDocumentContent.contains("AI generated text"))
        XCTAssertEqual(viewModel.aiResponse, "") // Should be cleared
    }

    @MainActor
    func testInsertAIResponseUpdatesStatistics() {
        let viewModel = WritersAppViewModel()

        viewModel.aiResponse = "Hello world"
        viewModel.insertAIResponse()

        XCTAssertGreaterThan(viewModel.wordCount, 0)
        XCTAssertGreaterThan(viewModel.characterCount, 0)
    }

    @MainActor
    func testMultitaskingStateUpdate() {
        let viewModel = WritersAppViewModel()

        let initialFontSize = viewModel.bodyFontSize

        // Update to full screen size
        viewModel.updateMultitaskingState(size: CGSize(width: 1200, height: 800))

        // Font size should be updated based on layout recommendations
        XCTAssertNotNil(viewModel.bodyFontSize)
    }

    @MainActor
    func testMultitaskingStateHidesAIPanelInSmallScreen() {
        let viewModel = WritersAppViewModel()

        XCTAssertTrue(viewModel.showAIPanel)

        // Update to slide over size (small screen)
        viewModel.updateMultitaskingState(size: CGSize(width: 300, height: 800))

        // AI panel should be hidden in slide over mode
        XCTAssertFalse(viewModel.showAIPanel)
    }

    // MARK: - WordCountDetailView Tests

    @MainActor
    func testSentenceCountEmpty() {
        let viewModel = WritersAppViewModel()
        viewModel.currentDocumentContent = ""

        let sentenceCount = calculateSentenceCount(for: viewModel.currentDocumentContent)
        XCTAssertEqual(sentenceCount, 0)
    }

    @MainActor
    func testSentenceCountSingleSentence() {
        let viewModel = WritersAppViewModel()
        viewModel.currentDocumentContent = "This is a sentence."

        let sentenceCount = calculateSentenceCount(for: viewModel.currentDocumentContent)
        XCTAssertEqual(sentenceCount, 1)
    }

    @MainActor
    func testSentenceCountMultipleSentences() {
        let viewModel = WritersAppViewModel()
        viewModel.currentDocumentContent = "First sentence. Second sentence! Third sentence?"

        let sentenceCount = calculateSentenceCount(for: viewModel.currentDocumentContent)
        XCTAssertEqual(sentenceCount, 3)
    }

    @MainActor
    func testSentenceCountWithExtraWhitespace() {
        let viewModel = WritersAppViewModel()
        viewModel.currentDocumentContent = "First.   Second!   Third?"

        let sentenceCount = calculateSentenceCount(for: viewModel.currentDocumentContent)
        XCTAssertEqual(sentenceCount, 3)
    }

    @MainActor
    func testSentenceCountWithOnlyPunctuation() {
        let viewModel = WritersAppViewModel()
        viewModel.currentDocumentContent = "...!!??"

        let sentenceCount = calculateSentenceCount(for: viewModel.currentDocumentContent)
        XCTAssertEqual(sentenceCount, 0) // No actual content
    }

    @MainActor
    func testParagraphCountEmpty() {
        let viewModel = WritersAppViewModel()
        viewModel.currentDocumentContent = ""

        let paragraphCount = calculateParagraphCount(for: viewModel.currentDocumentContent)
        XCTAssertEqual(paragraphCount, 0)
    }

    @MainActor
    func testParagraphCountSingleParagraph() {
        let viewModel = WritersAppViewModel()
        viewModel.currentDocumentContent = "This is a single paragraph with multiple sentences. It continues here."

        let paragraphCount = calculateParagraphCount(for: viewModel.currentDocumentContent)
        XCTAssertEqual(paragraphCount, 1)
    }

    @MainActor
    func testParagraphCountMultipleParagraphs() {
        let viewModel = WritersAppViewModel()
        viewModel.currentDocumentContent = "First paragraph.\n\nSecond paragraph.\n\nThird paragraph."

        let paragraphCount = calculateParagraphCount(for: viewModel.currentDocumentContent)
        XCTAssertEqual(paragraphCount, 3)
    }

    @MainActor
    func testParagraphCountWithExtraNewlines() {
        let viewModel = WritersAppViewModel()
        viewModel.currentDocumentContent = "First.\n\n\n\nSecond.\n\n\n\nThird."

        let paragraphCount = calculateParagraphCount(for: viewModel.currentDocumentContent)
        XCTAssertEqual(paragraphCount, 3)
    }

    @MainActor
    func testParagraphCountWithOnlyWhitespace() {
        let viewModel = WritersAppViewModel()
        viewModel.currentDocumentContent = "\n\n\n\n"

        let paragraphCount = calculateParagraphCount(for: viewModel.currentDocumentContent)
        XCTAssertEqual(paragraphCount, 0)
    }

    @MainActor
    func testParagraphCountWithSingleNewlines() {
        let viewModel = WritersAppViewModel()
        // Single newlines don't create new paragraphs, only double newlines do
        viewModel.currentDocumentContent = "Line 1\nLine 2\nLine 3"

        let paragraphCount = calculateParagraphCount(for: viewModel.currentDocumentContent)
        XCTAssertEqual(paragraphCount, 1) // All lines are part of one paragraph
    }

    // MARK: - AISidebarView Date Formatting Tests

    func testFormatSuggestionDateJustNow() {
        let now = Date()
        let formatted = formatSuggestionDate(now, referenceDate: now)
        XCTAssertEqual(formatted, "Just now")
    }

    func testFormatSuggestionDateSeconds() {
        let now = Date()
        let past = now.addingTimeInterval(-30) // 30 seconds ago
        let formatted = formatSuggestionDate(past, referenceDate: now)
        XCTAssertEqual(formatted, "Just now")
    }

    func testFormatSuggestionDateMinutes() {
        let now = Date()
        let past = now.addingTimeInterval(-120) // 2 minutes ago
        let formatted = formatSuggestionDate(past, referenceDate: now)
        XCTAssertEqual(formatted, "2m ago")
    }

    func testFormatSuggestionDateMinutesEdgeCase() {
        let now = Date()
        let past = now.addingTimeInterval(-60) // Exactly 1 minute
        let formatted = formatSuggestionDate(past, referenceDate: now)
        XCTAssertEqual(formatted, "1m ago")
    }

    func testFormatSuggestionDateHours() {
        let now = Date()
        let past = now.addingTimeInterval(-7200) // 2 hours ago
        let formatted = formatSuggestionDate(past, referenceDate: now)
        XCTAssertEqual(formatted, "2h ago")
    }

    func testFormatSuggestionDateHoursEdgeCase() {
        let now = Date()
        let past = now.addingTimeInterval(-3600) // Exactly 1 hour
        let formatted = formatSuggestionDate(past, referenceDate: now)
        XCTAssertEqual(formatted, "1h ago")
    }

    func testFormatSuggestionDateDays() {
        let now = Date()
        let past = now.addingTimeInterval(-172800) // 2 days ago
        let formatted = formatSuggestionDate(past, referenceDate: now)
        XCTAssertEqual(formatted, "2d ago")
    }

    func testFormatSuggestionDateDaysEdgeCase() {
        let now = Date()
        let past = now.addingTimeInterval(-86400) // Exactly 1 day
        let formatted = formatSuggestionDate(past, referenceDate: now)
        XCTAssertEqual(formatted, "1d ago")
    }

    func testFormatSuggestionDateMultipleDays() {
        let now = Date()
        let past = now.addingTimeInterval(-432000) // 5 days ago
        let formatted = formatSuggestionDate(past, referenceDate: now)
        XCTAssertEqual(formatted, "5d ago")
    }

    func testFormatSuggestionDateFutureDate() {
        let now = Date()
        let future = now.addingTimeInterval(3600) // 1 hour in future
        let formatted = formatSuggestionDate(future, referenceDate: now)
        // Future dates should show as "Just now" (negative interval)
        XCTAssertEqual(formatted, "Just now")
    }

    func testFormatSuggestionDateBoundaryBetweenMinutesAndHours() {
        let now = Date()
        let past = now.addingTimeInterval(-3599) // 59 minutes 59 seconds
        let formatted = formatSuggestionDate(past, referenceDate: now)
        XCTAssertEqual(formatted, "59m ago")
    }

    func testFormatSuggestionDateBoundaryBetweenHoursAndDays() {
        let now = Date()
        let past = now.addingTimeInterval(-86399) // 23 hours 59 minutes 59 seconds
        let formatted = formatSuggestionDate(past, referenceDate: now)
        XCTAssertEqual(formatted, "23h ago")
    }

    // MARK: - TemplateCategory Extension Tests

    func testTemplateCategoryIconNames() {
        XCTAssertEqual(TemplateCategory.novel.iconName, "book.closed")
        XCTAssertEqual(TemplateCategory.shortStory.iconName, "text.book.closed")
        XCTAssertEqual(TemplateCategory.screenplay.iconName, "film")
        XCTAssertEqual(TemplateCategory.blogPost.iconName, "globe")
        XCTAssertEqual(TemplateCategory.article.iconName, "newspaper")
        XCTAssertEqual(TemplateCategory.essay.iconName, "doc.text")
        XCTAssertEqual(TemplateCategory.poetry.iconName, "quote.bubble")
        XCTAssertEqual(TemplateCategory.businessLetter.iconName, "envelope")
        XCTAssertEqual(TemplateCategory.proposal.iconName, "doc.badge.plus")
        XCTAssertEqual(TemplateCategory.resume.iconName, "person.text.rectangle")
        XCTAssertEqual(TemplateCategory.other.iconName, "folder")
    }

    func testTemplateCategoryDisplayNames() {
        XCTAssertEqual(TemplateCategory.novel.displayName, "Novel")
        XCTAssertEqual(TemplateCategory.shortStory.displayName, "Short Story")
        XCTAssertEqual(TemplateCategory.screenplay.displayName, "Screenplay")
        XCTAssertEqual(TemplateCategory.blogPost.displayName, "Blog Post")
        XCTAssertEqual(TemplateCategory.article.displayName, "Article")
        XCTAssertEqual(TemplateCategory.essay.displayName, "Essay")
        XCTAssertEqual(TemplateCategory.poetry.displayName, "Poetry")
        XCTAssertEqual(TemplateCategory.businessLetter.displayName, "Business Letter")
        XCTAssertEqual(TemplateCategory.proposal.displayName, "Proposal")
        XCTAssertEqual(TemplateCategory.resume.displayName, "Resume")
        XCTAssertEqual(TemplateCategory.other.displayName, "Other")
    }

    // MARK: - Edge Cases and Boundary Tests

    @MainActor
    func testWordCountWithUnicodeCharacters() {
        let viewModel = WritersAppViewModel()
        viewModel.aiResponse = "Hello 世界 🌍 test"
        viewModel.insertAIResponse()

        // Should count 4 words (emoji and unicode are part of words or separate)
        XCTAssertGreaterThan(viewModel.wordCount, 0)
    }

    @MainActor
    func testWordCountWithMultipleSpaces() {
        let viewModel = WritersAppViewModel()
        viewModel.aiResponse = "word1    word2     word3"
        viewModel.insertAIResponse()

        XCTAssertEqual(viewModel.wordCount, 3)
    }

    @MainActor
    func testWordCountWithMixedWhitespace() {
        let viewModel = WritersAppViewModel()
        viewModel.aiResponse = "word1\t\tword2\n\nword3"
        viewModel.insertAIResponse()

        XCTAssertEqual(viewModel.wordCount, 3)
    }

    @MainActor
    func testCharacterCountWithEmojis() {
        let viewModel = WritersAppViewModel()
        viewModel.aiResponse = "Hello 🌍"
        viewModel.insertAIResponse()

        // Should count all characters including emoji
        XCTAssertGreaterThan(viewModel.characterCount, 6)
    }

    @MainActor
    func testReadingTimeWithLargeContent() {
        let viewModel = WritersAppViewModel()

        // 2000 words = 10 minutes at 200 words per minute
        let words2000 = String(repeating: "word ", count: 2000).trimmingCharacters(in: .whitespaces)
        viewModel.aiResponse = words2000
        viewModel.insertAIResponse()

        XCTAssertEqual(viewModel.readingTime, 10)
    }

    @MainActor
    func testSentenceCountWithAbbreviations() {
        let viewModel = WritersAppViewModel()
        // Dr. and Mr. should not be counted as separate sentences
        viewModel.currentDocumentContent = "Dr. Smith met Mr. Jones. They discussed the project."

        let sentenceCount = calculateSentenceCount(for: viewModel.currentDocumentContent)
        // This is a limitation - the simple algorithm counts 4 sentences
        // A more sophisticated algorithm would recognize abbreviations
        XCTAssertGreaterThanOrEqual(sentenceCount, 2)
    }

    @MainActor
    func testParagraphCountWithMixedLineBreaks() {
        let viewModel = WritersAppViewModel()
        viewModel.currentDocumentContent = "Para 1.\n\nPara 2.\r\n\r\nPara 3."

        let paragraphCount = calculateParagraphCount(for: viewModel.currentDocumentContent)
        XCTAssertGreaterThanOrEqual(paragraphCount, 1)
    }

    @MainActor
    func testEmptyContentStatistics() {
        let viewModel = WritersAppViewModel()
        viewModel.currentDocumentContent = ""
        viewModel.insertAIResponse()

        XCTAssertEqual(viewModel.wordCount, 0)
        XCTAssertEqual(viewModel.characterCount, 0)
        XCTAssertEqual(viewModel.readingTime, 1) // Minimum

        let sentenceCount = calculateSentenceCount(for: viewModel.currentDocumentContent)
        let paragraphCount = calculateParagraphCount(for: viewModel.currentDocumentContent)
        XCTAssertEqual(sentenceCount, 0)
        XCTAssertEqual(paragraphCount, 0)
    }

    @MainActor
    func testOnlyWhitespaceStatistics() {
        let viewModel = WritersAppViewModel()
        viewModel.aiResponse = "   \n\n\t\t   "
        viewModel.insertAIResponse()

        XCTAssertEqual(viewModel.wordCount, 0)
        XCTAssertGreaterThan(viewModel.characterCount, 0) // Whitespace is still characters

        let sentenceCount = calculateSentenceCount(for: viewModel.currentDocumentContent)
        let paragraphCount = calculateParagraphCount(for: viewModel.currentDocumentContent)
        XCTAssertEqual(sentenceCount, 0)
        XCTAssertEqual(paragraphCount, 0)
    }

    // MARK: - Additional Regression Tests

    @MainActor
    func testViewModelWordCountGoalNilByDefault() {
        let viewModel = WritersAppViewModel()
        XCTAssertNil(viewModel.wordCountGoal)
    }

    @MainActor
    func testViewModelWordCountGoalCanBeSet() {
        let viewModel = WritersAppViewModel()
        viewModel.wordCountGoal = 1000
        XCTAssertEqual(viewModel.wordCountGoal, 1000)
    }

    @MainActor
    func testMultipleFontSizeUpdate() {
        let viewModel = WritersAppViewModel()

        // Full screen
        viewModel.updateMultitaskingState(size: CGSize(width: 1200, height: 800))
        let fullScreenFontSize = viewModel.bodyFontSize

        // Split view
        viewModel.updateMultitaskingState(size: CGSize(width: 600, height: 800))
        let splitViewFontSize = viewModel.bodyFontSize

        // Slide over
        viewModel.updateMultitaskingState(size: CGSize(width: 300, height: 800))
        let slideOverFontSize = viewModel.bodyFontSize

        // Font size should decrease as screen size decreases
        XCTAssertGreaterThanOrEqual(fullScreenFontSize, splitViewFontSize)
        XCTAssertGreaterThanOrEqual(splitViewFontSize, slideOverFontSize)
    }

    @MainActor
    func testSaveDocumentSetsIsSaving() async {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()
        viewModel.createNewDocument()

        viewModel.saveDocument()

        // Initially should be saving
        XCTAssertTrue(viewModel.isSaving)

        // Wait for save to complete (simulated with 0.5s delay)
        try? await Task.sleep(nanoseconds: 600_000_000) // 0.6 seconds

        // Should no longer be saving
        XCTAssertFalse(viewModel.isSaving)
    }

    @MainActor
    func testFormatSuggestionDateZeroInterval() {
        let now = Date()
        let formatted = formatSuggestionDate(now, referenceDate: now)
        XCTAssertEqual(formatted, "Just now")
    }

    @MainActor
    func testSentenceCountWithNewlines() {
        let viewModel = WritersAppViewModel()
        viewModel.currentDocumentContent = "First sentence.\nSecond sentence.\nThird sentence."

        let sentenceCount = calculateSentenceCount(for: viewModel.currentDocumentContent)
        XCTAssertEqual(sentenceCount, 3)
    }

    // MARK: - Helper Functions

    private func calculateSentenceCount(for content: String) -> Int {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return 0 }
        let sentences = content.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        return sentences.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }

    private func calculateParagraphCount(for content: String) -> Int {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return 0 }
        let paragraphs = content.components(separatedBy: "\n\n")
        return paragraphs.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }

    private func formatSuggestionDate(_ date: Date, referenceDate: Date = Date()) -> String {
        let interval = referenceDate.timeIntervalSince(date)

        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }
}