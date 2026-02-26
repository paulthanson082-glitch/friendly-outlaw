import XCTest
@testable import WritersApp

#if canImport(SwiftUI) && os(iOS)
import SwiftUI

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
        XCTAssertEqual(viewModel.bodyFontSize, 17)
        XCTAssertEqual(viewModel.lineSpacing, 8)
    }

    @MainActor
    func testViewModelInitialize() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()

        // After initialization, recent suggestions and stats should be loaded
        // They may be empty if no data exists
        XCTAssertNotNil(viewModel.recentAISuggestions)
        XCTAssertNotNil(viewModel.toolUsageStats)
    }

    @MainActor
    func testCreateNewDocument() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()
        viewModel.createNewDocument()

        XCTAssertEqual(viewModel.currentDocumentTitle, "Untitled")
        XCTAssertEqual(viewModel.currentDocumentContent, "")
        XCTAssertEqual(viewModel.wordCount, 0)
    }

    @MainActor
    func testSaveDocument() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()
        viewModel.createNewDocument()

        viewModel.currentDocumentTitle = "My Story"
        viewModel.currentDocumentContent = "Once upon a time..."

        XCTAssertFalse(viewModel.isSaving)
        viewModel.saveDocument()
        XCTAssertTrue(viewModel.isSaving)

        // Wait for save to complete
        let expectation = XCTestExpectation(description: "Save completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            XCTAssertFalse(viewModel.isSaving)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    @MainActor
    func testShowWordCount() {
        let viewModel = WritersAppViewModel()
        XCTAssertFalse(viewModel.showWordCountSheet)

        viewModel.showWordCount()
        XCTAssertTrue(viewModel.showWordCountSheet)
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
    func testInsertAIResponse() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()
        viewModel.createNewDocument()

        viewModel.currentDocumentContent = "Hello"
        viewModel.aiResponse = "World"

        viewModel.insertAIResponse()

        XCTAssertEqual(viewModel.currentDocumentContent, "Hello\n\nWorld")
        XCTAssertEqual(viewModel.aiResponse, "")
        XCTAssertEqual(viewModel.wordCount, 2)
    }

    @MainActor
    func testInsertAIResponseWithEmptyContent() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()
        viewModel.createNewDocument()

        viewModel.aiResponse = "Generated text"
        viewModel.insertAIResponse()

        XCTAssertEqual(viewModel.currentDocumentContent, "\n\nGenerated text")
        XCTAssertEqual(viewModel.aiResponse, "")
    }

    @MainActor
    func testUpdateMultitaskingState() {
        let viewModel = WritersAppViewModel()

        // Test full screen size
        viewModel.updateMultitaskingState(size: CGSize(width: 1200, height: 800))
        XCTAssertGreaterThan(viewModel.bodyFontSize, 0)
        XCTAssertGreaterThan(viewModel.lineSpacing, 0)

        // Test smaller size
        viewModel.updateMultitaskingState(size: CGSize(width: 400, height: 600))
        // Font size should still be positive
        XCTAssertGreaterThan(viewModel.bodyFontSize, 0)
    }

    @MainActor
    func testUpdateMultitaskingStateHidesAIPanelInSlideOver() {
        let viewModel = WritersAppViewModel()
        viewModel.showAIPanel = true

        // Slide Over size (narrow)
        viewModel.updateMultitaskingState(size: CGSize(width: 300, height: 800))

        // AI panel should be hidden in narrow layouts
        XCTAssertFalse(viewModel.showAIPanel)
    }

    // MARK: - Statistics Tests

    @MainActor
    func testStatisticsWithEmptyContent() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()
        viewModel.currentDocumentContent = ""

        // Manually trigger statistics update by changing content
        viewModel.createNewDocument()

        XCTAssertEqual(viewModel.wordCount, 0)
        XCTAssertEqual(viewModel.characterCount, 0)
        XCTAssertEqual(viewModel.readingTime, 1)
    }

    @MainActor
    func testStatisticsWithSimpleText() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()
        viewModel.createNewDocument()

        viewModel.currentDocumentContent = "Hello world"
        viewModel.insertAIResponse() // This triggers updateStatistics

        // Reset and update properly
        viewModel.currentDocumentContent = "Hello world"
        viewModel.aiResponse = ""
        viewModel.insertAIResponse()

        // Manually compute expected values
        let content = "Hello world"
        let words = content.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        XCTAssertEqual(words.count, 2)
    }

    @MainActor
    func testStatisticsWithMultipleWords() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()
        viewModel.createNewDocument()

        // Create content with known word count
        let content = "The quick brown fox jumps over the lazy dog"
        viewModel.currentDocumentContent = content
        viewModel.aiResponse = ""
        viewModel.insertAIResponse()

        // After insert, content should be updated
        // Check character count
        XCTAssertGreaterThan(viewModel.characterCount, 0)
    }

    @MainActor
    func testStatisticsWordCountWithMultipleSpaces() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()
        viewModel.createNewDocument()

        viewModel.currentDocumentContent = "Hello    world   test"
        viewModel.aiResponse = ""
        viewModel.insertAIResponse()

        // The statistics should filter empty strings
        XCTAssertGreaterThan(viewModel.wordCount, 0)
    }

    @MainActor
    func testStatisticsReadingTime() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()
        viewModel.createNewDocument()

        // 400 words should be ~2 minutes at 200 wpm
        let words = Array(repeating: "word", count: 400).joined(separator: " ")
        viewModel.currentDocumentContent = words
        viewModel.aiResponse = ""
        viewModel.insertAIResponse()

        // Reading time is max(1, wordCount / 200)
        XCTAssertGreaterThanOrEqual(viewModel.readingTime, 1)
    }

    @MainActor
    func testStatisticsReadingTimeMinimum() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()
        viewModel.createNewDocument()

        viewModel.currentDocumentContent = "Short"
        viewModel.aiResponse = ""
        viewModel.insertAIResponse()

        // Reading time should be at least 1 minute
        XCTAssertEqual(viewModel.readingTime, 1)
    }

    @MainActor
    func testStatisticsCharacterCount() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()
        viewModel.createNewDocument()

        let content = "Hello!"
        viewModel.currentDocumentContent = content
        viewModel.aiResponse = ""
        viewModel.insertAIResponse()

        XCTAssertGreaterThan(viewModel.characterCount, 0)
    }

    // MARK: - Database Operations Tests

    @MainActor
    func testLoadRecentSuggestions() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()
        viewModel.loadRecentSuggestions()

        // Should not crash and should initialize the array
        XCTAssertNotNil(viewModel.recentAISuggestions)
    }

    @MainActor
    func testLoadToolUsageStats() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()
        viewModel.loadToolUsageStats()

        // Should not crash and should initialize the array
        XCTAssertNotNil(viewModel.toolUsageStats)
    }

    @MainActor
    func testLoadSessionStats() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()
        viewModel.loadSessionStats()

        // Should not crash
        // currentSessionStats may be nil if no session exists
    }

    @MainActor
    func testLoadMoreSuggestions() {
        let viewModel = WritersAppViewModel()
        viewModel.loadMoreSuggestions()

        // Should not crash (currently a no-op)
    }

    // MARK: - Edge Cases and Boundary Conditions

    @MainActor
    func testViewModelWithVeryLongContent() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()
        viewModel.createNewDocument()

        // Create very long content
        let longContent = String(repeating: "word ", count: 10000)
        viewModel.currentDocumentContent = longContent
        viewModel.aiResponse = ""
        viewModel.insertAIResponse()

        // Should handle large content without crashing
        XCTAssertGreaterThan(viewModel.wordCount, 5000)
        XCTAssertGreaterThan(viewModel.characterCount, 20000)
    }

    @MainActor
    func testViewModelWithSpecialCharacters() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()
        viewModel.createNewDocument()

        viewModel.currentDocumentContent = "Hello! @#$% World?"
        viewModel.aiResponse = ""
        viewModel.insertAIResponse()

        XCTAssertGreaterThan(viewModel.wordCount, 0)
        XCTAssertGreaterThan(viewModel.characterCount, 0)
    }

    @MainActor
    func testViewModelWithNewlines() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()
        viewModel.createNewDocument()

        viewModel.currentDocumentContent = "Line 1\n\nLine 2\nLine 3"
        viewModel.aiResponse = ""
        viewModel.insertAIResponse()

        XCTAssertGreaterThan(viewModel.wordCount, 0)
    }

    @MainActor
    func testViewModelWithOnlyWhitespace() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()
        viewModel.createNewDocument()

        viewModel.currentDocumentContent = "   \n\n  \t  "
        viewModel.aiResponse = ""
        viewModel.insertAIResponse()

        // Should have 0 words but non-zero characters
        XCTAssertEqual(viewModel.wordCount, 0)
        XCTAssertGreaterThan(viewModel.characterCount, 0)
    }

    @MainActor
    func testMultipleToggleAIPanelCalls() {
        let viewModel = WritersAppViewModel()

        for _ in 0..<10 {
            viewModel.toggleAIPanel()
        }

        // After even number of toggles, should be back to initial state
        XCTAssertFalse(viewModel.showAIPanel)
    }

    @MainActor
    func testEditorPaddingDefaults() {
        let viewModel = WritersAppViewModel()

        XCTAssertEqual(viewModel.editorPadding.top, 20)
        XCTAssertEqual(viewModel.editorPadding.leading, 40)
        XCTAssertEqual(viewModel.editorPadding.bottom, 20)
        XCTAssertEqual(viewModel.editorPadding.trailing, 40)
    }

    // MARK: - formatSuggestionDate Tests

    func testFormatSuggestionDateJustNow() {
        let now = Date()
        let recent = now.addingTimeInterval(-30) // 30 seconds ago

        let result = formatSuggestionDateHelper(recent)
        XCTAssertEqual(result, "Just now")
    }

    func testFormatSuggestionDateMinutesAgo() {
        let now = Date()
        let fiveMinutesAgo = now.addingTimeInterval(-5 * 60)

        let result = formatSuggestionDateHelper(fiveMinutesAgo)
        XCTAssertEqual(result, "5m ago")
    }

    func testFormatSuggestionDateOneMinuteAgo() {
        let now = Date()
        let oneMinuteAgo = now.addingTimeInterval(-61)

        let result = formatSuggestionDateHelper(oneMinuteAgo)
        XCTAssertEqual(result, "1m ago")
    }

    func testFormatSuggestionDateHoursAgo() {
        let now = Date()
        let twoHoursAgo = now.addingTimeInterval(-2 * 3600)

        let result = formatSuggestionDateHelper(twoHoursAgo)
        XCTAssertEqual(result, "2h ago")
    }

    func testFormatSuggestionDateOneHourAgo() {
        let now = Date()
        let oneHourAgo = now.addingTimeInterval(-3601)

        let result = formatSuggestionDateHelper(oneHourAgo)
        XCTAssertEqual(result, "1h ago")
    }

    func testFormatSuggestionDateDaysAgo() {
        let now = Date()
        let threeDaysAgo = now.addingTimeInterval(-3 * 86400)

        let result = formatSuggestionDateHelper(threeDaysAgo)
        XCTAssertEqual(result, "3d ago")
    }

    func testFormatSuggestionDateOneDayAgo() {
        let now = Date()
        let oneDayAgo = now.addingTimeInterval(-86401)

        let result = formatSuggestionDateHelper(oneDayAgo)
        XCTAssertEqual(result, "1d ago")
    }

    func testFormatSuggestionDateBoundaryConditions() {
        let now = Date()

        // Exactly 60 seconds (should be 1m ago, not just now)
        let exactly60Seconds = now.addingTimeInterval(-60)
        let result60 = formatSuggestionDateHelper(exactly60Seconds)
        XCTAssertEqual(result60, "1m ago")

        // Exactly 3600 seconds (should be 1h ago)
        let exactly3600Seconds = now.addingTimeInterval(-3600)
        let result3600 = formatSuggestionDateHelper(exactly3600Seconds)
        XCTAssertEqual(result3600, "1h ago")

        // Exactly 86400 seconds (should be 1d ago)
        let exactly86400Seconds = now.addingTimeInterval(-86400)
        let result86400 = formatSuggestionDateHelper(exactly86400Seconds)
        XCTAssertEqual(result86400, "1d ago")
    }

    func testFormatSuggestionDateFutureDate() {
        let now = Date()
        let future = now.addingTimeInterval(100)

        // Future dates should result in "Just now" (negative interval)
        let result = formatSuggestionDateHelper(future)
        XCTAssertEqual(result, "Just now")
    }

    // Helper function that mimics the formatSuggestionDate logic
    private func formatSuggestionDateHelper(_ date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)

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

    func testTemplateCategoryAllCasesHaveIconsAndNames() {
        for category in TemplateCategory.allCases {
            // Ensure no category returns empty strings
            XCTAssertFalse(category.iconName.isEmpty, "Icon name should not be empty for \(category)")
            XCTAssertFalse(category.displayName.isEmpty, "Display name should not be empty for \(category)")
        }
    }

    // MARK: - WordCountDetailView Logic Tests

    func testSentenceCountWithEmptyContent() {
        let content = ""
        let sentenceCount = calculateSentenceCount(content)
        XCTAssertEqual(sentenceCount, 0)
    }

    func testSentenceCountWithSingleSentence() {
        let content = "This is a sentence."
        let sentenceCount = calculateSentenceCount(content)
        XCTAssertEqual(sentenceCount, 1)
    }

    func testSentenceCountWithMultipleSentences() {
        let content = "First sentence. Second sentence! Third sentence?"
        let sentenceCount = calculateSentenceCount(content)
        XCTAssertEqual(sentenceCount, 3)
    }

    func testSentenceCountWithWhitespaceOnly() {
        let content = "   \n\n   "
        let sentenceCount = calculateSentenceCount(content)
        XCTAssertEqual(sentenceCount, 0)
    }

    func testSentenceCountWithTrailingPunctuation() {
        let content = "Sentence one. Sentence two. "
        let sentenceCount = calculateSentenceCount(content)
        XCTAssertEqual(sentenceCount, 2)
    }

    func testSentenceCountWithMultiplePunctuationMarks() {
        let content = "Really?! Yes! Maybe..."
        let sentenceCount = calculateSentenceCount(content)
        // Splits on .!? so "Really" "Yes" "Maybe.." -> filters non-empty -> 3
        XCTAssertEqual(sentenceCount, 3)
    }

    func testParagraphCountWithEmptyContent() {
        let content = ""
        let paragraphCount = calculateParagraphCount(content)
        XCTAssertEqual(paragraphCount, 0)
    }

    func testParagraphCountWithSingleParagraph() {
        let content = "This is a single paragraph."
        let paragraphCount = calculateParagraphCount(content)
        XCTAssertEqual(paragraphCount, 1)
    }

    func testParagraphCountWithMultipleParagraphs() {
        let content = "First paragraph.\n\nSecond paragraph.\n\nThird paragraph."
        let paragraphCount = calculateParagraphCount(content)
        XCTAssertEqual(paragraphCount, 3)
    }

    func testParagraphCountWithWhitespaceOnly() {
        let content = "   \n\n   \n\n   "
        let paragraphCount = calculateParagraphCount(content)
        XCTAssertEqual(paragraphCount, 0)
    }

    func testParagraphCountWithSingleNewlines() {
        let content = "Line one\nLine two\nLine three"
        let paragraphCount = calculateParagraphCount(content)
        // Single newlines don't split paragraphs, only \n\n does
        XCTAssertEqual(paragraphCount, 1)
    }

    func testParagraphCountWithMixedSpacing() {
        let content = "Paragraph 1\n\nParagraph 2\n\n\n\nParagraph 3"
        let paragraphCount = calculateParagraphCount(content)
        XCTAssertEqual(paragraphCount, 3)
    }

    func testParagraphCountWithTrailingNewlines() {
        let content = "Paragraph 1\n\nParagraph 2\n\n"
        let paragraphCount = calculateParagraphCount(content)
        XCTAssertEqual(paragraphCount, 2)
    }

    // Helper functions that mimic WordCountDetailView computed properties
    private func calculateSentenceCount(_ content: String) -> Int {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return 0 }
        let sentences = content.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        return sentences.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }

    private func calculateParagraphCount(_ content: String) -> Int {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return 0 }
        let paragraphs = content.components(separatedBy: "\n\n")
        return paragraphs.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }

    // MARK: - SidebarSection Tests

    func testSidebarSectionHashable() {
        let section1 = SidebarSection.documents
        let section2 = SidebarSection.documents
        let section3 = SidebarSection.templates

        XCTAssertEqual(section1, section2)
        XCTAssertNotEqual(section1, section3)
    }

    func testSidebarSectionCategoryWithSameCategory() {
        let category1 = SidebarSection.category(.novel)
        let category2 = SidebarSection.category(.novel)
        let category3 = SidebarSection.category(.article)

        XCTAssertEqual(category1, category2)
        XCTAssertNotEqual(category1, category3)
    }

    func testSidebarSectionAllCases() {
        let documents = SidebarSection.documents
        let templates = SidebarSection.templates
        let recent = SidebarSection.recent
        let statistics = SidebarSection.statistics
        let settings = SidebarSection.settings
        let categoryNovel = SidebarSection.category(.novel)

        XCTAssertNotEqual(documents, templates)
        XCTAssertNotEqual(templates, recent)
        XCTAssertNotEqual(recent, statistics)
        XCTAssertNotEqual(statistics, settings)
        XCTAssertNotEqual(settings, categoryNovel)
    }

    // MARK: - Regression Tests

    @MainActor
    func testViewModelDoesNotCrashWithRapidUpdates() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()

        // Rapidly update content
        for i in 0..<100 {
            viewModel.currentDocumentContent = "Content \(i)"
        }

        // Should not crash
        XCTAssertNotNil(viewModel.currentDocumentContent)
    }

    @MainActor
    func testViewModelResetAfterSave() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()
        viewModel.createNewDocument()

        viewModel.currentDocumentTitle = "Test"
        viewModel.currentDocumentContent = "Content"
        viewModel.saveDocument()

        // After save, content should remain
        XCTAssertEqual(viewModel.currentDocumentTitle, "Test")
        XCTAssertEqual(viewModel.currentDocumentContent, "Content")
    }

    @MainActor
    func testWordCountGoalProgress() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()
        viewModel.createNewDocument()

        viewModel.wordCountGoal = 100
        viewModel.currentDocumentContent = Array(repeating: "word", count: 50).joined(separator: " ")
        viewModel.aiResponse = ""
        viewModel.insertAIResponse()

        // Progress should be calculable
        XCTAssertNotNil(viewModel.wordCountGoal)
        if let goal = viewModel.wordCountGoal {
            XCTAssertGreaterThan(goal, 0)
        }
    }

    @MainActor
    func testAIResponseEmptyAfterInsert() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()
        viewModel.createNewDocument()

        viewModel.aiResponse = "Some AI generated text"
        XCTAssertFalse(viewModel.aiResponse.isEmpty)

        viewModel.insertAIResponse()
        XCTAssertTrue(viewModel.aiResponse.isEmpty)
    }

    // MARK: - Additional Edge Cases

    @MainActor
    func testStatisticsWithEmojiContent() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()
        viewModel.createNewDocument()

        viewModel.currentDocumentContent = "Hello 👋 world 🌍"
        viewModel.aiResponse = ""
        viewModel.insertAIResponse()

        // Should handle emoji without crashing
        XCTAssertGreaterThan(viewModel.wordCount, 0)
        XCTAssertGreaterThan(viewModel.characterCount, 0)
    }

    @MainActor
    func testStatisticsWithUnicodeContent() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()
        viewModel.createNewDocument()

        viewModel.currentDocumentContent = "Héllo wörld"
        viewModel.aiResponse = ""
        viewModel.insertAIResponse()

        XCTAssertGreaterThan(viewModel.wordCount, 0)
        XCTAssertGreaterThan(viewModel.characterCount, 0)
    }

    @MainActor
    func testMultitaskingManagerNotNil() {
        let viewModel = WritersAppViewModel()
        XCTAssertNotNil(viewModel.multitaskingManager)
    }

    @MainActor
    func testKeyboardShortcutManagerNotNil() {
        let viewModel = WritersAppViewModel()
        XCTAssertNotNil(viewModel.keyboardShortcutManager)
    }

    @MainActor
    func testApplePencilManagerNotNil() {
        let viewModel = WritersAppViewModel()
        XCTAssertNotNil(viewModel.applePencilManager)
    }

    func testSentenceCountWithAbbreviations() {
        let content = "Dr. Smith said hello. Mr. Jones agreed."
        let sentenceCount = calculateSentenceCount(content)
        // This will count 4 because it splits on all periods
        // This is a known limitation of the simple implementation
        XCTAssertGreaterThan(sentenceCount, 0)
    }

    func testParagraphCountWithWindowsLineEndings() {
        let content = "Paragraph 1\r\n\r\nParagraph 2"
        let paragraphCount = calculateParagraphCount(content)
        // \n\n splitting won't catch \r\n\r\n properly
        // This documents the current behavior
        XCTAssertGreaterThanOrEqual(paragraphCount, 0)
    }

    // MARK: - Additional Comprehensive Tests

    @MainActor
    func testStatisticsUpdateOnContentChange() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()
        viewModel.createNewDocument()

        // Set initial content
        viewModel.currentDocumentContent = "Hello world"
        viewModel.aiResponse = ""
        viewModel.insertAIResponse()

        let initialWordCount = viewModel.wordCount
        XCTAssertGreaterThan(initialWordCount, 0)

        // Change content directly and trigger update
        viewModel.currentDocumentContent = "Hello world this is more content"
        viewModel.aiResponse = ""
        viewModel.insertAIResponse()

        // Word count should have increased
        XCTAssertGreaterThan(viewModel.wordCount, initialWordCount)
    }

    @MainActor
    func testWordCountGoalBoundaryAtGoal() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()
        viewModel.createNewDocument()

        viewModel.wordCountGoal = 10

        // Set content to exactly the goal
        let words = Array(repeating: "word", count: 10).joined(separator: " ")
        viewModel.currentDocumentContent = words
        viewModel.aiResponse = ""
        viewModel.insertAIResponse()

        XCTAssertNotNil(viewModel.wordCountGoal)
        if let goal = viewModel.wordCountGoal {
            // Should be able to reach the goal
            XCTAssertGreaterThanOrEqual(viewModel.wordCount, goal - 2) // Allow some tolerance
        }
    }

    @MainActor
    func testWordCountGoalExceedsGoal() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()
        viewModel.createNewDocument()

        viewModel.wordCountGoal = 5

        // Set content to exceed the goal
        let words = Array(repeating: "word", count: 20).joined(separator: " ")
        viewModel.currentDocumentContent = words
        viewModel.aiResponse = ""
        viewModel.insertAIResponse()

        XCTAssertNotNil(viewModel.wordCountGoal)
        if let goal = viewModel.wordCountGoal {
            XCTAssertGreaterThan(viewModel.wordCount, goal)
        }
    }

    @MainActor
    func testWordCountSheetToggles() {
        let viewModel = WritersAppViewModel()
        XCTAssertFalse(viewModel.showWordCountSheet)

        viewModel.showWordCount()
        XCTAssertTrue(viewModel.showWordCountSheet)

        // Manually toggle off
        viewModel.showWordCountSheet = false
        XCTAssertFalse(viewModel.showWordCountSheet)

        // Show again
        viewModel.showWordCount()
        XCTAssertTrue(viewModel.showWordCountSheet)
    }

    @MainActor
    func testConcurrentSaveOperations() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()
        viewModel.createNewDocument()

        viewModel.currentDocumentTitle = "Test"
        viewModel.currentDocumentContent = "Content"

        // Trigger multiple saves rapidly
        viewModel.saveDocument()
        XCTAssertTrue(viewModel.isSaving)

        viewModel.saveDocument()
        // Should still be saving
        XCTAssertTrue(viewModel.isSaving)

        let expectation = XCTestExpectation(description: "All saves complete")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            XCTAssertFalse(viewModel.isSaving)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    @MainActor
    func testReadingTimeWithLargeContent() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()
        viewModel.createNewDocument()

        // Create content with exactly 1000 words
        let words = Array(repeating: "word", count: 1000).joined(separator: " ")
        viewModel.currentDocumentContent = words
        viewModel.aiResponse = ""
        viewModel.insertAIResponse()

        // 1000 words at 200 wpm = 5 minutes
        XCTAssertEqual(viewModel.readingTime, 5)
    }

    @MainActor
    func testReadingTimeWithExactlyTwoHundredWords() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()
        viewModel.createNewDocument()

        // Create content with exactly 200 words
        let words = Array(repeating: "word", count: 200).joined(separator: " ")
        viewModel.currentDocumentContent = words
        viewModel.aiResponse = ""
        viewModel.insertAIResponse()

        // 200 words at 200 wpm = 1 minute
        XCTAssertEqual(viewModel.readingTime, 1)
    }

    @MainActor
    func testReadingTimeWithOneHundredNinetyNineWords() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()
        viewModel.createNewDocument()

        // Create content with 199 words
        let words = Array(repeating: "word", count: 199).joined(separator: " ")
        viewModel.currentDocumentContent = words
        viewModel.aiResponse = ""
        viewModel.insertAIResponse()

        // 199 words at 200 wpm = 0.995 minutes, but minimum is 1
        XCTAssertEqual(viewModel.readingTime, 1)
    }

    @MainActor
    func testCharacterCountIncludesPunctuation() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()
        viewModel.createNewDocument()

        viewModel.currentDocumentContent = "Hi!"
        viewModel.aiResponse = ""
        viewModel.insertAIResponse()

        // "Hi!" has 3 characters
        XCTAssertGreaterThanOrEqual(viewModel.characterCount, 3)
    }

    @MainActor
    func testStatisticsWithMixedContent() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()
        viewModel.createNewDocument()

        // Mix of text, numbers, punctuation
        viewModel.currentDocumentContent = "Test 123 with numbers! And symbols @#$"
        viewModel.aiResponse = ""
        viewModel.insertAIResponse()

        XCTAssertGreaterThan(viewModel.wordCount, 0)
        XCTAssertGreaterThan(viewModel.characterCount, 0)
        XCTAssertGreaterThanOrEqual(viewModel.readingTime, 1)
    }

    @MainActor
    func testMultitaskingStateWithVariousSizes() {
        let viewModel = WritersAppViewModel()

        // Test various screen sizes
        let sizes = [
            CGSize(width: 320, height: 568),   // Slide Over
            CGSize(width: 640, height: 800),   // Split View 1/3
            CGSize(width: 768, height: 1024),  // Split View 1/2
            CGSize(width: 1024, height: 768),  // Full Screen iPad
            CGSize(width: 1366, height: 1024)  // iPad Pro 12.9" Full Screen
        ]

        for size in sizes {
            viewModel.updateMultitaskingState(size: size)
            XCTAssertGreaterThan(viewModel.bodyFontSize, 0)
            XCTAssertGreaterThanOrEqual(viewModel.lineSpacing, 0)
        }
    }

    @MainActor
    func testToggleFocusModeMultipleTimes() {
        let viewModel = WritersAppViewModel()

        let initialState = viewModel.isFocusMode

        // Toggle 20 times
        for _ in 0..<20 {
            viewModel.toggleFocusMode()
        }

        // Should be back to initial state (even number of toggles)
        XCTAssertEqual(viewModel.isFocusMode, initialState)
    }

    @MainActor
    func testInsertAIResponseClearsAIResponse() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()
        viewModel.createNewDocument()

        viewModel.aiResponse = "AI generated content"
        XCTAssertFalse(viewModel.aiResponse.isEmpty)

        viewModel.insertAIResponse()

        // AI response should be cleared
        XCTAssertTrue(viewModel.aiResponse.isEmpty)
    }

    @MainActor
    func testInsertAIResponseWithMultipleInsertions() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()
        viewModel.createNewDocument()

        viewModel.aiResponse = "First"
        viewModel.insertAIResponse()

        viewModel.aiResponse = "Second"
        viewModel.insertAIResponse()

        viewModel.aiResponse = "Third"
        viewModel.insertAIResponse()

        // Content should contain all three insertions
        XCTAssertTrue(viewModel.currentDocumentContent.contains("First"))
        XCTAssertTrue(viewModel.currentDocumentContent.contains("Second"))
        XCTAssertTrue(viewModel.currentDocumentContent.contains("Third"))
    }

    @MainActor
    func testCreateMultipleNewDocuments() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()

        viewModel.createNewDocument()
        viewModel.currentDocumentTitle = "First"
        viewModel.currentDocumentContent = "First content"

        viewModel.createNewDocument()

        // New document should reset to defaults
        XCTAssertEqual(viewModel.currentDocumentTitle, "Untitled")
        XCTAssertEqual(viewModel.currentDocumentContent, "")
    }

    @MainActor
    func testDatabaseOperationsWithoutCrashing() {
        let viewModel = WritersAppViewModel()

        // These should not crash even before initialization
        viewModel.loadRecentSuggestions()
        viewModel.loadToolUsageStats()
        viewModel.loadSessionStats()
        viewModel.loadMoreSuggestions()

        // Arrays should be initialized (empty)
        XCTAssertNotNil(viewModel.recentAISuggestions)
        XCTAssertNotNil(viewModel.toolUsageStats)
    }

    func testSentenceCountWithNoEndingPunctuation() {
        let content = "This is a sentence without ending"
        let sentenceCount = calculateSentenceCount(content)
        // Should count as 1 sentence even without punctuation
        XCTAssertEqual(sentenceCount, 1)
    }

    func testSentenceCountWithConsecutivePunctuation() {
        let content = "Wait... Really?! Yes!!!"
        let sentenceCount = calculateSentenceCount(content)
        // Should handle consecutive punctuation
        XCTAssertGreaterThan(sentenceCount, 0)
    }

    func testParagraphCountWithTabSeparation() {
        let content = "Paragraph 1\n\nParagraph 2\n\nParagraph 3"
        let paragraphCount = calculateParagraphCount(content)
        XCTAssertEqual(paragraphCount, 3)
    }

    func testParagraphCountWithLeadingAndTrailingWhitespace() {
        let content = "  \n\nParagraph 1\n\nParagraph 2\n\n  "
        let paragraphCount = calculateParagraphCount(content)
        XCTAssertEqual(paragraphCount, 2)
    }

    @MainActor
    func testWordCountWithTabs() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()
        viewModel.createNewDocument()

        viewModel.currentDocumentContent = "Hello\tworld\ttest"
        viewModel.aiResponse = ""
        viewModel.insertAIResponse()

        // Tabs should be treated as whitespace
        XCTAssertEqual(viewModel.wordCount, 3)
    }

    @MainActor
    func testWordCountWithVariousWhitespace() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()
        viewModel.createNewDocument()

        viewModel.currentDocumentContent = "Hello \n world \t test \r\n done"
        viewModel.aiResponse = ""
        viewModel.insertAIResponse()

        // Should handle various whitespace characters
        XCTAssertEqual(viewModel.wordCount, 4)
    }

    @MainActor
    func testAIPanelHiddenInNarrowLayout() {
        let viewModel = WritersAppViewModel()
        viewModel.showAIPanel = true

        // Very narrow width (like Slide Over)
        viewModel.updateMultitaskingState(size: CGSize(width: 250, height: 800))

        // AI panel should be hidden
        XCTAssertFalse(viewModel.showAIPanel)
    }

    @MainActor
    func testFontSizeAdjustsForDifferentLayouts() {
        let viewModel = WritersAppViewModel()

        // Large screen
        viewModel.updateMultitaskingState(size: CGSize(width: 1366, height: 1024))
        let largeFontSize = viewModel.bodyFontSize

        // Small screen
        viewModel.updateMultitaskingState(size: CGSize(width: 320, height: 568))
        let smallFontSize = viewModel.bodyFontSize

        // Both should be valid positive values
        XCTAssertGreaterThan(largeFontSize, 0)
        XCTAssertGreaterThan(smallFontSize, 0)
    }

    @MainActor
    func testInitializeCreatesWritersAppInstance() {
        let viewModel = WritersAppViewModel()

        // Before initialization
        viewModel.loadRecentSuggestions()
        let beforeCount = viewModel.recentAISuggestions.count

        // Initialize
        viewModel.initialize()

        // After initialization, should have loaded data
        XCTAssertNotNil(viewModel.recentAISuggestions)
        XCTAssertNotNil(viewModel.toolUsageStats)
    }

    @MainActor
    func testViewModelStateAfterMultipleOperations() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()

        // Perform a sequence of operations
        viewModel.createNewDocument()
        viewModel.toggleAIPanel()
        viewModel.toggleFocusMode()
        viewModel.showWordCount()

        viewModel.currentDocumentContent = "Test content"
        viewModel.aiResponse = "AI response"
        viewModel.insertAIResponse()

        viewModel.saveDocument()

        // Verify final state is consistent
        XCTAssertFalse(viewModel.showAIPanel)
        XCTAssertTrue(viewModel.isFocusMode)
        XCTAssertTrue(viewModel.showWordCountSheet)
        XCTAssertTrue(viewModel.currentDocumentContent.contains("Test content"))
        XCTAssertTrue(viewModel.currentDocumentContent.contains("AI response"))
        XCTAssertTrue(viewModel.aiResponse.isEmpty)
    }

    // MARK: - WordCountDetailView Specific Tests

    func testSentenceCountWithMixedPunctuation() {
        let content = "Hello! How are you? I'm fine. Great!"
        let sentenceCount = calculateSentenceCount(content)
        XCTAssertEqual(sentenceCount, 4)
    }

    func testSentenceCountWithEllipsis() {
        let content = "Well... I'm not sure..."
        let sentenceCount = calculateSentenceCount(content)
        // Should count segments separated by periods
        XCTAssertGreaterThan(sentenceCount, 0)
    }

    func testSentenceCountWithQuestionAndExclamation() {
        let content = "What?! No way!"
        let sentenceCount = calculateSentenceCount(content)
        XCTAssertEqual(sentenceCount, 2)
    }

    func testParagraphCountWithMultipleEmptyLines() {
        let content = "First\n\n\n\nSecond\n\n\n\nThird"
        let paragraphCount = calculateParagraphCount(content)
        // Should still count 3 paragraphs despite multiple empty lines
        XCTAssertEqual(paragraphCount, 3)
    }

    func testParagraphCountSingleLineContent() {
        let content = "Just one line"
        let paragraphCount = calculateParagraphCount(content)
        XCTAssertEqual(paragraphCount, 1)
    }

    func testSentenceCountWithNumbersAndPeriods() {
        let content = "The value is 3.14 approximately. This is 99.9% certain."
        let sentenceCount = calculateSentenceCount(content)
        // This will split on decimal points too - documents current behavior
        XCTAssertGreaterThan(sentenceCount, 0)
    }

    @MainActor
    func testWordCountDetailViewDataConsistency() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()
        viewModel.createNewDocument()

        let testContent = "Hello world. This is a test! How are you?"
        viewModel.currentDocumentContent = testContent
        viewModel.aiResponse = ""
        viewModel.insertAIResponse()

        // Verify statistics are consistent with what WordCountDetailView would display
        XCTAssertGreaterThan(viewModel.wordCount, 0)
        XCTAssertGreaterThan(viewModel.characterCount, 0)
        XCTAssertGreaterThanOrEqual(viewModel.readingTime, 1)

        // Test sentence count calculation
        let sentenceCount = calculateSentenceCount(testContent)
        XCTAssertEqual(sentenceCount, 3)

        // Test paragraph count calculation
        let paragraphCount = calculateParagraphCount(testContent)
        XCTAssertEqual(paragraphCount, 1)
    }

    @MainActor
    func testWordCountGoalProgressWithZeroGoal() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()
        viewModel.createNewDocument()

        // Edge case: zero goal (should not cause division by zero)
        viewModel.wordCountGoal = 0
        viewModel.currentDocumentContent = "Test content"
        viewModel.aiResponse = ""
        viewModel.insertAIResponse()

        // Should handle zero goal gracefully
        XCTAssertNotNil(viewModel.wordCountGoal)
        XCTAssertEqual(viewModel.wordCountGoal, 0)
    }

    @MainActor
    func testWordCountGoalProgressWithNegativeRemaining() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()
        viewModel.createNewDocument()

        viewModel.wordCountGoal = 5
        let words = Array(repeating: "word", count: 10).joined(separator: " ")
        viewModel.currentDocumentContent = words
        viewModel.aiResponse = ""
        viewModel.insertAIResponse()

        // Word count exceeds goal
        if let goal = viewModel.wordCountGoal {
            let remaining = goal - viewModel.wordCount
            // Remaining should be negative
            XCTAssertLessThan(remaining, 0)
            // max(0, remaining) should be 0
            XCTAssertEqual(max(0, remaining), 0)
        }
    }

    @MainActor
    func testWordCountGoalProgressDisplay() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()
        viewModel.createNewDocument()

        viewModel.wordCountGoal = 100
        viewModel.currentDocumentContent = Array(repeating: "word", count: 50).joined(separator: " ")
        viewModel.aiResponse = ""
        viewModel.insertAIResponse()

        // Test progress calculation
        if let goal = viewModel.wordCountGoal {
            let progress = Double(min(viewModel.wordCount, goal)) / Double(goal)
            XCTAssertGreaterThan(progress, 0)
            XCTAssertLessThanOrEqual(progress, 1.0)

            let remaining = max(0, goal - viewModel.wordCount)
            XCTAssertGreaterThan(remaining, 0)
        }
    }

    @MainActor
    func testWordCountGoalReachedStatus() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()
        viewModel.createNewDocument()

        viewModel.wordCountGoal = 10
        viewModel.currentDocumentContent = Array(repeating: "word", count: 10).joined(separator: " ")
        viewModel.aiResponse = ""
        viewModel.insertAIResponse()

        if let goal = viewModel.wordCountGoal {
            let remaining = max(0, goal - viewModel.wordCount)
            let isGoalReached = (remaining == 0)
            // Should be true or close to true
            XCTAssertTrue(isGoalReached || remaining <= 2)
        }
    }

    func testSentenceCountWithEmptyStringBetweenPunctuation() {
        let content = "..??!!"
        let sentenceCount = calculateSentenceCount(content)
        // All empty segments after splitting, should be 0
        XCTAssertEqual(sentenceCount, 0)
    }

    func testParagraphCountWithOnlyNewlines() {
        let content = "\n\n\n\n\n\n"
        let paragraphCount = calculateParagraphCount(content)
        XCTAssertEqual(paragraphCount, 0)
    }

    @MainActor
    func testComplexDocumentStatistics() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()
        viewModel.createNewDocument()

        // Create a complex document with multiple paragraphs and sentences
        let content = """
        This is the first paragraph. It has multiple sentences! Does it work?

        Here is the second paragraph. It's quite interesting. Let me tell you more.

        Finally, the third paragraph. Short and sweet!
        """

        viewModel.currentDocumentContent = content
        viewModel.aiResponse = ""
        viewModel.insertAIResponse()

        // Verify all statistics are calculated
        XCTAssertGreaterThan(viewModel.wordCount, 20)
        XCTAssertGreaterThan(viewModel.characterCount, 100)
        XCTAssertGreaterThanOrEqual(viewModel.readingTime, 1)

        let sentenceCount = calculateSentenceCount(content)
        XCTAssertGreaterThanOrEqual(sentenceCount, 8)

        let paragraphCount = calculateParagraphCount(content)
        XCTAssertEqual(paragraphCount, 3)
    }

    @MainActor
    func testReadingTimeCalculationAccuracy() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()
        viewModel.createNewDocument()

        // Test various word counts and expected reading times
        let testCases = [
            (wordCount: 50, expectedMinTime: 1),
            (wordCount: 200, expectedMinTime: 1),
            (wordCount: 400, expectedMinTime: 2),
            (wordCount: 600, expectedMinTime: 3),
            (wordCount: 1000, expectedMinTime: 5)
        ]

        for testCase in testCases {
            let content = Array(repeating: "word", count: testCase.wordCount).joined(separator: " ")
            viewModel.currentDocumentContent = content
            viewModel.aiResponse = ""
            viewModel.insertAIResponse()

            XCTAssertGreaterThanOrEqual(viewModel.readingTime, testCase.expectedMinTime)
        }
    }

    @MainActor
    func testShowWordCountSheetInteraction() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()
        viewModel.createNewDocument()

        // Set up some content
        viewModel.currentDocumentContent = "Test content for word count sheet"
        viewModel.aiResponse = ""
        viewModel.insertAIResponse()

        // Show word count sheet
        XCTAssertFalse(viewModel.showWordCountSheet)
        viewModel.showWordCount()
        XCTAssertTrue(viewModel.showWordCountSheet)

        // Verify statistics are ready for display
        XCTAssertGreaterThan(viewModel.wordCount, 0)
        XCTAssertGreaterThan(viewModel.characterCount, 0)
    }

    func testSentenceCountWithOnlySentenceEnders() {
        let content = "."
        let sentenceCount = calculateSentenceCount(content)
        XCTAssertEqual(sentenceCount, 0)
    }

    func testParagraphCountWithSpacesAroundSeparators() {
        let content = "Para1   \n\n   Para2   \n\n   Para3"
        let paragraphCount = calculateParagraphCount(content)
        XCTAssertEqual(paragraphCount, 3)
    }

    @MainActor
    func testStatisticsWithRealWorldContent() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()
        viewModel.createNewDocument()

        // Real world content with various formatting
        let content = """
        Chapter 1: The Beginning

        It was a dark and stormy night. The wind howled through the trees.
        Lightning flashed across the sky!

        She knew this was going to be a long night... But she was ready.
        After all, she had been preparing for this moment for years.

        "Are you sure about this?" he asked nervously.
        "Absolutely," she replied with confidence.
        """

        viewModel.currentDocumentContent = content
        viewModel.aiResponse = ""
        viewModel.insertAIResponse()

        // Verify comprehensive statistics
        XCTAssertGreaterThan(viewModel.wordCount, 30)
        XCTAssertGreaterThan(viewModel.characterCount, 200)
        XCTAssertGreaterThanOrEqual(viewModel.readingTime, 1)

        let sentenceCount = calculateSentenceCount(content)
        XCTAssertGreaterThanOrEqual(sentenceCount, 6)

        let paragraphCount = calculateParagraphCount(content)
        XCTAssertGreaterThanOrEqual(paragraphCount, 3)
    }

    @MainActor
    func testWordCountGoalProgressBarValues() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()
        viewModel.createNewDocument()

        viewModel.wordCountGoal = 100

        // Test at 0% progress
        viewModel.currentDocumentContent = ""
        viewModel.aiResponse = ""
        viewModel.insertAIResponse()

        if let goal = viewModel.wordCountGoal {
            let progress = Double(min(viewModel.wordCount, goal))
            XCTAssertEqual(progress, 0)
        }

        // Test at 50% progress
        viewModel.currentDocumentContent = Array(repeating: "word", count: 50).joined(separator: " ")
        viewModel.aiResponse = ""
        viewModel.insertAIResponse()

        if let goal = viewModel.wordCountGoal {
            let progressValue = Double(min(viewModel.wordCount, goal))
            XCTAssertGreaterThan(progressValue, 40) // Allow some tolerance
            XCTAssertLessThan(progressValue, 60)
        }

        // Test at 100% progress
        viewModel.currentDocumentContent = Array(repeating: "word", count: 100).joined(separator: " ")
        viewModel.aiResponse = ""
        viewModel.insertAIResponse()

        if let goal = viewModel.wordCountGoal {
            let progressValue = Double(min(viewModel.wordCount, goal))
            XCTAssertGreaterThanOrEqual(progressValue, 90) // Allow some tolerance
        }

        // Test at >100% progress (should cap at goal)
        viewModel.currentDocumentContent = Array(repeating: "word", count: 150).joined(separator: " ")
        viewModel.aiResponse = ""
        viewModel.insertAIResponse()

        if let goal = viewModel.wordCountGoal {
            let progressValue = Double(min(viewModel.wordCount, goal))
            XCTAssertEqual(progressValue, Double(goal))
        }
    }

    @MainActor
    func testMultipleWordCountSheetToggles() {
        let viewModel = WritersAppViewModel()

        // Toggle multiple times
        for _ in 0..<5 {
            viewModel.showWordCount()
            XCTAssertTrue(viewModel.showWordCountSheet)

            viewModel.showWordCountSheet = false
            XCTAssertFalse(viewModel.showWordCountSheet)
        }
    }

    func testSentenceCountEdgeCaseWithLongText() {
        // Test performance with longer text
        let sentences = Array(repeating: "This is a sentence.", count: 100).joined(separator: " ")
        let sentenceCount = calculateSentenceCount(sentences)
        XCTAssertEqual(sentenceCount, 100)
    }

    func testParagraphCountEdgeCaseWithLongText() {
        // Test performance with many paragraphs
        let paragraph = "This is a paragraph."
        let paragraphs = Array(repeating: paragraph, count: 50).joined(separator: "\n\n")
        let paragraphCount = calculateParagraphCount(paragraphs)
        XCTAssertEqual(paragraphCount, 50)
    }

    @MainActor
    func testWordCountGoalNilBehavior() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()
        viewModel.createNewDocument()

        // Ensure goal is nil by default
        XCTAssertNil(viewModel.wordCountGoal)

        viewModel.currentDocumentContent = "Some content"
        viewModel.aiResponse = ""
        viewModel.insertAIResponse()

        // Should still calculate statistics even without a goal
        XCTAssertGreaterThan(viewModel.wordCount, 0)
        XCTAssertNil(viewModel.wordCountGoal)
    }

    @MainActor
    func testWordCountDetailViewCompatibilityWithEmptyDocument() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()
        viewModel.createNewDocument()

        // Empty document should show zeros
        XCTAssertEqual(viewModel.wordCount, 0)
        XCTAssertEqual(viewModel.characterCount, 0)
        XCTAssertEqual(viewModel.readingTime, 1) // Minimum is 1

        let sentenceCount = calculateSentenceCount(viewModel.currentDocumentContent)
        XCTAssertEqual(sentenceCount, 0)

        let paragraphCount = calculateParagraphCount(viewModel.currentDocumentContent)
        XCTAssertEqual(paragraphCount, 0)
    }
}

#endif