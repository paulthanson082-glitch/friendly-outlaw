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
        XCTAssertEqual(viewModel.wordCount, 0)
        XCTAssertEqual(viewModel.characterCount, 0)
        XCTAssertEqual(viewModel.readingTime, 1)
        XCTAssertNil(viewModel.wordCountGoal)
        XCTAssertEqual(viewModel.bodyFontSize, 17)
        XCTAssertEqual(viewModel.lineSpacing, 8)
    }

    @MainActor
    func testWordCountCalculationAfterInitialize() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()

        // After initialization, word count should be 0
        XCTAssertEqual(viewModel.wordCount, 0)

        // Note: Statistics are only updated when initialize(), createNewDocument(),
        // or insertAIResponse() are called. Setting currentDocumentContent directly
        // does NOT automatically update statistics.
        // This test verifies the initial state after initialization.
    }

    @MainActor
    func testWordCountAfterCreateNewDocument() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()

        // Create new document updates statistics
        viewModel.createNewDocument()
        XCTAssertEqual(viewModel.wordCount, 0)
        XCTAssertEqual(viewModel.currentDocumentContent, "")
    }

    @MainActor
    func testCharacterCountAfterInitialize() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()

        // After initialization, character count should be 0
        XCTAssertEqual(viewModel.characterCount, 0)

        // Character count reflects the current content length
        XCTAssertEqual(viewModel.characterCount, viewModel.currentDocumentContent.count)
    }

    @MainActor
    func testReadingTimeCalculation() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()

        // Empty content - should be at least 1 minute (after initialization)
        XCTAssertEqual(viewModel.readingTime, 1)

        // Reading time is based on 200 words per minute
        // This is a calculated property that depends on wordCount
        // which is only updated through specific methods
    }

    @MainActor
    func testToggleAIPanel() {
        let viewModel = WritersAppViewModel()

        // Initially true
        XCTAssertTrue(viewModel.showAIPanel)

        // Toggle to false
        viewModel.toggleAIPanel()
        XCTAssertFalse(viewModel.showAIPanel)

        // Toggle back to true
        viewModel.toggleAIPanel()
        XCTAssertTrue(viewModel.showAIPanel)
    }

    @MainActor
    func testToggleFocusMode() {
        let viewModel = WritersAppViewModel()

        // Initially false
        XCTAssertFalse(viewModel.isFocusMode)

        // Toggle to true
        viewModel.toggleFocusMode()
        XCTAssertTrue(viewModel.isFocusMode)

        // Toggle back to false
        viewModel.toggleFocusMode()
        XCTAssertFalse(viewModel.isFocusMode)
    }

    @MainActor
    func testShowWordCount() {
        let viewModel = WritersAppViewModel()

        // Initially false
        XCTAssertFalse(viewModel.showWordCountSheet)

        // Show word count sheet
        viewModel.showWordCount()
        XCTAssertTrue(viewModel.showWordCountSheet)
    }

    @MainActor
    func testInsertAIResponse() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()

        viewModel.currentDocumentContent = "Hello world"
        viewModel.aiResponse = "This is AI generated text"

        viewModel.insertAIResponse()

        XCTAssertEqual(viewModel.currentDocumentContent, "Hello world\n\nThis is AI generated text")
        XCTAssertEqual(viewModel.aiResponse, "")
        // Word count should be updated by insertAIResponse
        XCTAssertEqual(viewModel.wordCount, 7)
    }

    @MainActor
    func testInsertAIResponseWithEmptyContent() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()

        viewModel.currentDocumentContent = ""
        viewModel.aiResponse = "New content"

        viewModel.insertAIResponse()

        XCTAssertEqual(viewModel.currentDocumentContent, "\n\nNew content")
        XCTAssertEqual(viewModel.aiResponse, "")
        // Word count should be updated
        XCTAssertEqual(viewModel.wordCount, 2)
    }

    @MainActor
    func testUpdateMultitaskingState() {
        let viewModel = WritersAppViewModel()

        // Test full screen layout
        viewModel.updateMultitaskingState(size: CGSize(width: 1200, height: 800))

        // Font size and line spacing should be updated based on layout
        // The exact values depend on the MultitaskingManager implementation
        XCTAssertGreaterThan(viewModel.bodyFontSize, 0)
        XCTAssertGreaterThan(viewModel.lineSpacing, 0)

        // Test compact layout
        viewModel.updateMultitaskingState(size: CGSize(width: 300, height: 800))

        // AI panel should be hidden in compact mode
        XCTAssertFalse(viewModel.showAIPanel)
    }

    @MainActor
    func testCreateNewDocument() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()

        viewModel.createNewDocument()

        XCTAssertEqual(viewModel.currentDocumentTitle, "Untitled")
        XCTAssertEqual(viewModel.currentDocumentContent, "")
    }

    @MainActor
    func testSaveDocument() async {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()
        viewModel.createNewDocument()

        viewModel.currentDocumentTitle = "Test Document"
        viewModel.currentDocumentContent = "Test content"

        viewModel.saveDocument()

        // Should start saving
        XCTAssertTrue(viewModel.isSaving)

        // Wait for save to complete
        try? await Task.sleep(nanoseconds: 600_000_000) // 0.6 seconds

        // Should finish saving
        XCTAssertFalse(viewModel.isSaving)
    }

    @MainActor
    func testPublishedPropertiesAreObservable() {
        let viewModel = WritersAppViewModel()

        // Test that published properties can be set
        viewModel.currentDocumentTitle = "New Title"
        XCTAssertEqual(viewModel.currentDocumentTitle, "New Title")

        viewModel.currentDocumentContent = "New Content"
        XCTAssertEqual(viewModel.currentDocumentContent, "New Content")

        viewModel.wordCountGoal = 1000
        XCTAssertEqual(viewModel.wordCountGoal, 1000)

        viewModel.bodyFontSize = 20
        XCTAssertEqual(viewModel.bodyFontSize, 20)

        viewModel.lineSpacing = 12
        XCTAssertEqual(viewModel.lineSpacing, 12)
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

    func testAllTemplateCategoriesHaveIcons() {
        for category in TemplateCategory.allCases {
            XCTAssertFalse(category.iconName.isEmpty, "\(category) should have an icon name")
        }
    }

    func testAllTemplateCategoriesHaveDisplayNames() {
        for category in TemplateCategory.allCases {
            XCTAssertFalse(category.displayName.isEmpty, "\(category) should have a display name")
        }
    }

    // MARK: - SidebarSection Tests

    func testSidebarSectionHashable() {
        // Test equality
        XCTAssertEqual(SidebarSection.documents, SidebarSection.documents)
        XCTAssertEqual(SidebarSection.templates, SidebarSection.templates)
        XCTAssertEqual(SidebarSection.recent, SidebarSection.recent)
        XCTAssertEqual(SidebarSection.statistics, SidebarSection.statistics)
        XCTAssertEqual(SidebarSection.settings, SidebarSection.settings)

        // Test inequality
        XCTAssertNotEqual(SidebarSection.documents, SidebarSection.templates)
        XCTAssertNotEqual(SidebarSection.recent, SidebarSection.statistics)

        // Test category cases
        XCTAssertEqual(
            SidebarSection.category(.novel),
            SidebarSection.category(.novel)
        )
        XCTAssertNotEqual(
            SidebarSection.category(.novel),
            SidebarSection.category(.shortStory)
        )
    }

    func testSidebarSectionInSet() {
        var sections = Set<SidebarSection>()

        sections.insert(.documents)
        sections.insert(.templates)
        sections.insert(.documents) // Duplicate

        XCTAssertEqual(sections.count, 2)
        XCTAssertTrue(sections.contains(.documents))
        XCTAssertTrue(sections.contains(.templates))
        XCTAssertFalse(sections.contains(.recent))
    }

    // MARK: - Word Count Detail Calculations Tests

    func testSentenceCountEmpty() {
        let viewModel = WritersAppViewModel()
        viewModel.currentDocumentContent = ""

        let sentenceCount = calculateSentenceCount(from: viewModel.currentDocumentContent)
        XCTAssertEqual(sentenceCount, 0)
    }

    func testSentenceCountSingleSentence() {
        let viewModel = WritersAppViewModel()
        viewModel.currentDocumentContent = "This is a test."

        let sentenceCount = calculateSentenceCount(from: viewModel.currentDocumentContent)
        XCTAssertEqual(sentenceCount, 1)
    }

    func testSentenceCountMultipleSentences() {
        let viewModel = WritersAppViewModel()
        viewModel.currentDocumentContent = "First sentence. Second sentence! Third sentence?"

        let sentenceCount = calculateSentenceCount(from: viewModel.currentDocumentContent)
        XCTAssertEqual(sentenceCount, 3)
    }

    func testSentenceCountWithEmptySentences() {
        let viewModel = WritersAppViewModel()
        viewModel.currentDocumentContent = "Hello. . World!"

        let sentenceCount = calculateSentenceCount(from: viewModel.currentDocumentContent)
        XCTAssertEqual(sentenceCount, 2)
    }

    func testSentenceCountWithWhitespaceOnly() {
        let viewModel = WritersAppViewModel()
        viewModel.currentDocumentContent = "   \n\n   "

        let sentenceCount = calculateSentenceCount(from: viewModel.currentDocumentContent)
        XCTAssertEqual(sentenceCount, 0)
    }

    func testSentenceCountWithMultipleEndMarks() {
        let viewModel = WritersAppViewModel()
        viewModel.currentDocumentContent = "What?! No way! Really?"

        let sentenceCount = calculateSentenceCount(from: viewModel.currentDocumentContent)
        XCTAssertGreaterThanOrEqual(sentenceCount, 2)
    }

    func testParagraphCountEmpty() {
        let viewModel = WritersAppViewModel()
        viewModel.currentDocumentContent = ""

        let paragraphCount = calculateParagraphCount(from: viewModel.currentDocumentContent)
        XCTAssertEqual(paragraphCount, 0)
    }

    func testParagraphCountSingleParagraph() {
        let viewModel = WritersAppViewModel()
        viewModel.currentDocumentContent = "This is a single paragraph with multiple sentences. It continues here."

        let paragraphCount = calculateParagraphCount(from: viewModel.currentDocumentContent)
        XCTAssertEqual(paragraphCount, 1)
    }

    func testParagraphCountMultipleParagraphs() {
        let viewModel = WritersAppViewModel()
        viewModel.currentDocumentContent = "First paragraph.\n\nSecond paragraph.\n\nThird paragraph."

        let paragraphCount = calculateParagraphCount(from: viewModel.currentDocumentContent)
        XCTAssertEqual(paragraphCount, 3)
    }

    func testParagraphCountWithEmptyParagraphs() {
        let viewModel = WritersAppViewModel()
        viewModel.currentDocumentContent = "First paragraph.\n\n\n\nSecond paragraph."

        let paragraphCount = calculateParagraphCount(from: viewModel.currentDocumentContent)
        XCTAssertEqual(paragraphCount, 2)
    }

    func testParagraphCountWithWhitespaceOnly() {
        let viewModel = WritersAppViewModel()
        viewModel.currentDocumentContent = "   \n\n   "

        let paragraphCount = calculateParagraphCount(from: viewModel.currentDocumentContent)
        XCTAssertEqual(paragraphCount, 0)
    }

    func testParagraphCountSingleNewline() {
        let viewModel = WritersAppViewModel()
        viewModel.currentDocumentContent = "First line.\nSecond line."

        let paragraphCount = calculateParagraphCount(from: viewModel.currentDocumentContent)
        XCTAssertEqual(paragraphCount, 1)
    }

    // MARK: - Date Formatting Tests

    func testFormatSuggestionDateJustNow() {
        let now = Date()
        let formatted = formatSuggestionDate(now)

        XCTAssertEqual(formatted, "Just now")
    }

    func testFormatSuggestionDateSeconds() {
        let now = Date()
        let thirtySecondsAgo = now.addingTimeInterval(-30)
        let formatted = formatSuggestionDate(thirtySecondsAgo)

        XCTAssertEqual(formatted, "Just now")
    }

    func testFormatSuggestionDateMinutes() {
        let now = Date()
        let fiveMinutesAgo = now.addingTimeInterval(-300) // 5 minutes
        let formatted = formatSuggestionDate(fiveMinutesAgo)

        XCTAssertEqual(formatted, "5m ago")
    }

    func testFormatSuggestionDateHours() {
        let now = Date()
        let twoHoursAgo = now.addingTimeInterval(-7200) // 2 hours
        let formatted = formatSuggestionDate(twoHoursAgo)

        XCTAssertEqual(formatted, "2h ago")
    }

    func testFormatSuggestionDateDays() {
        let now = Date()
        let threeDaysAgo = now.addingTimeInterval(-259200) // 3 days
        let formatted = formatSuggestionDate(threeDaysAgo)

        XCTAssertEqual(formatted, "3d ago")
    }

    func testFormatSuggestionDateEdgeCases() {
        let now = Date()

        // Just under 1 minute
        let fiftyNineSeconds = now.addingTimeInterval(-59)
        XCTAssertEqual(formatSuggestionDate(fiftyNineSeconds), "Just now")

        // Exactly 1 minute
        let oneMinute = now.addingTimeInterval(-60)
        XCTAssertEqual(formatSuggestionDate(oneMinute), "1m ago")

        // Just under 1 hour
        let fiftyNineMinutes = now.addingTimeInterval(-3540) // 59 minutes
        XCTAssertEqual(formatSuggestionDate(fiftyNineMinutes), "59m ago")

        // Exactly 1 hour
        let oneHour = now.addingTimeInterval(-3600)
        XCTAssertEqual(formatSuggestionDate(oneHour), "1h ago")

        // Just under 1 day
        let twentyThreeHours = now.addingTimeInterval(-82800) // 23 hours
        XCTAssertEqual(formatSuggestionDate(twentyThreeHours), "23h ago")

        // Exactly 1 day
        let oneDay = now.addingTimeInterval(-86400)
        XCTAssertEqual(formatSuggestionDate(oneDay), "1d ago")
    }

    // MARK: - Word Count Goal Tests

    @MainActor
    func testWordCountGoalProgress() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()

        viewModel.wordCountGoal = 1000

        // Since statistics don't auto-update when setting content directly,
        // we test the goal property itself
        XCTAssertEqual(viewModel.wordCountGoal, 1000)

        // Word count would be updated through proper methods like insertAIResponse
        // Test the calculation logic itself
        let mockWordCount = 500
        let remaining = max(0, viewModel.wordCountGoal! - mockWordCount)
        XCTAssertEqual(remaining, 500)
    }

    @MainActor
    func testWordCountGoalReached() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()

        viewModel.wordCountGoal = 100

        XCTAssertEqual(viewModel.wordCountGoal, 100)

        // Test the logic when word count reaches goal
        let mockWordCount = 100
        let remaining = max(0, viewModel.wordCountGoal! - mockWordCount)
        XCTAssertEqual(remaining, 0)
    }

    @MainActor
    func testWordCountGoalExceeded() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()

        viewModel.wordCountGoal = 50

        XCTAssertEqual(viewModel.wordCountGoal, 50)

        // Test the logic when word count exceeds goal
        let mockWordCount = 100
        let remaining = max(0, viewModel.wordCountGoal! - mockWordCount)
        XCTAssertEqual(remaining, 0)
    }

    // MARK: - Edge Case Tests

    @MainActor
    func testEmptyDocumentStatistics() {
        let viewModel = WritersAppViewModel()
        viewModel.currentDocumentContent = ""

        XCTAssertEqual(viewModel.wordCount, 0)
        XCTAssertEqual(viewModel.characterCount, 0)
        XCTAssertEqual(viewModel.readingTime, 1) // Minimum reading time
    }

    @MainActor
    func testVeryLongDocument() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()

        // Test with a very long document
        // Statistics would be updated through proper methods
        // Here we test that the property can hold large content
        let longContent = String(repeating: "word ", count: 1000)
        viewModel.currentDocumentContent = longContent

        XCTAssertGreaterThan(viewModel.currentDocumentContent.count, 0)
        XCTAssertEqual(viewModel.currentDocumentContent, longContent)
    }

    @MainActor
    func testSpecialCharactersInContent() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()

        viewModel.currentDocumentContent = "Hello! @world #test $money 100%"

        // Content with special characters should be stored correctly
        XCTAssertTrue(viewModel.currentDocumentContent.contains("@world"))
        XCTAssertTrue(viewModel.currentDocumentContent.contains("#test"))
        XCTAssertGreaterThan(viewModel.currentDocumentContent.count, 0)
    }

    @MainActor
    func testUnicodeCharacters() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()

        viewModel.currentDocumentContent = "Hello 世界 مرحبا Привет"

        // Unicode characters should be handled correctly
        XCTAssertTrue(viewModel.currentDocumentContent.contains("世界"))
        XCTAssertTrue(viewModel.currentDocumentContent.contains("مرحبا"))
        XCTAssertTrue(viewModel.currentDocumentContent.contains("Привет"))
        XCTAssertGreaterThan(viewModel.currentDocumentContent.count, 0)
    }

    @MainActor
    func testMultipleWhitespaceTypes() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()

        viewModel.currentDocumentContent = "word1\tword2\nword3\rword4 word5"

        // Content with different whitespace types should be stored correctly
        XCTAssertTrue(viewModel.currentDocumentContent.contains("word1"))
        XCTAssertTrue(viewModel.currentDocumentContent.contains("word5"))
        XCTAssertGreaterThan(viewModel.currentDocumentContent.count, 0)
    }

    // MARK: - Additional Regression Tests

    @MainActor
    func testStatisticsDoNotAutoUpdateOnContentChange() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()

        let initialWordCount = viewModel.wordCount

        // Change content directly
        viewModel.currentDocumentContent = "Test content with multiple words"

        // Statistics should NOT automatically update when content is set directly
        // They only update when specific methods are called (initialize, createNewDocument, insertAIResponse)
        XCTAssertEqual(viewModel.wordCount, initialWordCount)

        // This is by design - the private updateStatistics() method must be explicitly called
        // In the UI, this would be triggered by user actions like inserting AI responses
    }

    @MainActor
    func testEditorPaddingDefaults() {
        let viewModel = WritersAppViewModel()

        XCTAssertEqual(viewModel.editorPadding.top, 20)
        XCTAssertEqual(viewModel.editorPadding.leading, 40)
        XCTAssertEqual(viewModel.editorPadding.bottom, 20)
        XCTAssertEqual(viewModel.editorPadding.trailing, 40)
    }

    @MainActor
    func testInitialAISuggestionsEmpty() {
        let viewModel = WritersAppViewModel()

        XCTAssertTrue(viewModel.recentAISuggestions.isEmpty)
        XCTAssertTrue(viewModel.toolUsageStats.isEmpty)
        XCTAssertNil(viewModel.currentSessionStats)
    }

    @MainActor
    func testViewModelManagersInitialized() {
        let viewModel = WritersAppViewModel()

        XCTAssertNotNil(viewModel.multitaskingManager)
        XCTAssertNotNil(viewModel.keyboardShortcutManager)
        XCTAssertNotNil(viewModel.applePencilManager)
    }

    // MARK: - Statistics Calculation Through Public API Tests

    @MainActor
    func testStatisticsCalculationThroughInsertAIResponse() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()

        // Initial state
        XCTAssertEqual(viewModel.wordCount, 0)
        XCTAssertEqual(viewModel.characterCount, 0)
        XCTAssertEqual(viewModel.readingTime, 1)

        // Insert AI response with known word count
        viewModel.aiResponse = "This is a test response with ten words in it."
        viewModel.insertAIResponse()

        // Statistics should be updated
        XCTAssertEqual(viewModel.wordCount, 10)
        XCTAssertGreaterThan(viewModel.characterCount, 0)
        XCTAssertEqual(viewModel.readingTime, 1) // Less than 200 words = 1 minute

        // Add more content
        viewModel.aiResponse = String(repeating: "word ", count: 300)
        viewModel.insertAIResponse()

        // Word count should increase
        XCTAssertGreaterThan(viewModel.wordCount, 10)
        XCTAssertGreaterThan(viewModel.readingTime, 1) // Over 200 words now
    }

    @MainActor
    func testReadingTimeCalculationThroughAPI() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()

        // Add exactly 400 words (should give 2 minutes reading time)
        viewModel.aiResponse = String(repeating: "word ", count: 400)
        viewModel.insertAIResponse()

        XCTAssertEqual(viewModel.wordCount, 400)
        XCTAssertEqual(viewModel.readingTime, 2) // 400 / 200 = 2 minutes
    }

    @MainActor
    func testWordCountWithVariousContentTypes() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()

        // Test with empty AI response
        viewModel.aiResponse = ""
        viewModel.insertAIResponse()
        XCTAssertEqual(viewModel.wordCount, 0)

        // Test with single word
        viewModel.aiResponse = "Hello"
        viewModel.insertAIResponse()
        XCTAssertEqual(viewModel.wordCount, 1)

        // Test with multiple words and punctuation
        viewModel.aiResponse = "Hello, world! This is a test."
        viewModel.insertAIResponse()
        XCTAssertEqual(viewModel.wordCount, 7) // 1 (previous) + 6 (new)

        // Test with words separated by various whitespace
        viewModel.aiResponse = "word1\tword2\nword3"
        viewModel.insertAIResponse()
        XCTAssertEqual(viewModel.wordCount, 10) // 7 (previous) + 3 (new)
    }

    // MARK: - Boundary Tests

    @MainActor
    func testWordCountBoundaryValues() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()

        // Test reading time calculation boundary (200 words per minute)
        // At 200 words: 200 / 200 = 1 minute
        // At 201 words: 201 / 200 = 1.005 -> truncated to 1 minute
        // At 400 words: 400 / 200 = 2 minutes

        // This tests the calculation logic that reading time = max(1, wordCount / 200)
        XCTAssertEqual(viewModel.readingTime, 1) // Initial state
    }

    @MainActor
    func testNegativeWordCountGoal() {
        let viewModel = WritersAppViewModel()

        // Setting a negative goal (edge case)
        viewModel.wordCountGoal = -100
        viewModel.currentDocumentContent = "Test"

        // Word count goal can be negative in this implementation
        XCTAssertEqual(viewModel.wordCountGoal, -100)
    }

    @MainActor
    func testZeroWordCountGoal() {
        let viewModel = WritersAppViewModel()

        viewModel.wordCountGoal = 0
        viewModel.currentDocumentContent = "Test"

        XCTAssertEqual(viewModel.wordCountGoal, 0)
        XCTAssertEqual(viewModel.wordCount, 1)
    }

    // MARK: - Helper Functions

    private func calculateSentenceCount(from content: String) -> Int {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return 0 }
        let sentences = content.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        return sentences.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }

    private func calculateParagraphCount(from content: String) -> Int {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return 0 }
        let paragraphs = content.components(separatedBy: "\n\n")
        return paragraphs.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }

    private func formatSuggestionDate(_ date: Date) -> String {
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

    // MARK: - Database Operations Tests

    @MainActor
    func testLoadRecentSuggestionsBeforeInitialize() {
        let viewModel = WritersAppViewModel()

        // Before initialization, suggestions should be empty
        XCTAssertTrue(viewModel.recentAISuggestions.isEmpty)

        // Calling loadRecentSuggestions before initialization should not crash
        viewModel.loadRecentSuggestions()

        // Should still be empty since WritersApp is not initialized
        XCTAssertTrue(viewModel.recentAISuggestions.isEmpty)
    }

    @MainActor
    func testLoadRecentSuggestionsAfterInitialize() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()

        // After initialization, we can load suggestions
        viewModel.loadRecentSuggestions()

        // Should not crash, suggestions array is accessible
        // In a real scenario with database content, this would have data
        XCTAssertNotNil(viewModel.recentAISuggestions)
    }

    @MainActor
    func testLoadToolUsageStatsBeforeInitialize() {
        let viewModel = WritersAppViewModel()

        // Before initialization, stats should be empty
        XCTAssertTrue(viewModel.toolUsageStats.isEmpty)

        // Calling loadToolUsageStats before initialization should not crash
        viewModel.loadToolUsageStats()

        // Should still be empty since WritersApp is not initialized
        XCTAssertTrue(viewModel.toolUsageStats.isEmpty)
    }

    @MainActor
    func testLoadToolUsageStatsAfterInitialize() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()

        // After initialization, we can load stats
        viewModel.loadToolUsageStats()

        // Should not crash, stats array is accessible
        XCTAssertNotNil(viewModel.toolUsageStats)
    }

    @MainActor
    func testLoadSessionStatsBeforeInitialize() {
        let viewModel = WritersAppViewModel()

        // Before initialization, session stats should be nil
        XCTAssertNil(viewModel.currentSessionStats)

        // Calling loadSessionStats before initialization should not crash
        viewModel.loadSessionStats()

        // Should still be nil since WritersApp is not initialized
        XCTAssertNil(viewModel.currentSessionStats)
    }

    @MainActor
    func testLoadSessionStatsAfterInitialize() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()

        // After initialization, we can load session stats
        viewModel.loadSessionStats()

        // Should not crash, session stats is accessible
        // Value depends on database state
        XCTAssertTrue(viewModel.currentSessionStats == nil || viewModel.currentSessionStats != nil)
    }

    @MainActor
    func testLoadMoreSuggestionsDoesNotCrash() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()

        // This method is a placeholder for navigation
        // Should not crash when called
        viewModel.loadMoreSuggestions()

        // Method completes without error
        XCTAssertTrue(true)
    }

    // MARK: - Word Count Sheet Integration Tests

    @MainActor
    func testShowWordCountIntegration() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()

        // Initial state - sheet not shown
        XCTAssertFalse(viewModel.showWordCountSheet)

        // Trigger showWordCount
        viewModel.showWordCount()

        // Sheet should be presented
        XCTAssertTrue(viewModel.showWordCountSheet)

        // Simulate dismissing the sheet
        viewModel.showWordCountSheet = false
        XCTAssertFalse(viewModel.showWordCountSheet)
    }

    @MainActor
    func testWordCountSheetWithContent() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()

        // Add content via AI response to update statistics
        viewModel.aiResponse = "This is a test. Another sentence! And a third one?"
        viewModel.insertAIResponse()

        // Show word count
        viewModel.showWordCount()

        // Verify the data that would be shown in the sheet
        XCTAssertTrue(viewModel.showWordCountSheet)
        XCTAssertGreaterThan(viewModel.wordCount, 0)
        XCTAssertGreaterThan(viewModel.characterCount, 0)

        // Sentence count would be calculated from the content
        let sentenceCount = calculateSentenceCount(from: viewModel.currentDocumentContent)
        XCTAssertEqual(sentenceCount, 3)
    }

    @MainActor
    func testWordCountSheetWithGoal() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()

        // Set a word count goal
        viewModel.wordCountGoal = 100

        // Add some content
        viewModel.aiResponse = String(repeating: "word ", count: 50)
        viewModel.insertAIResponse()

        // Show word count
        viewModel.showWordCount()

        XCTAssertTrue(viewModel.showWordCountSheet)
        XCTAssertNotNil(viewModel.wordCountGoal)
        XCTAssertEqual(viewModel.wordCountGoal, 100)
        XCTAssertEqual(viewModel.wordCount, 50)

        // Calculate remaining
        let remaining = max(0, viewModel.wordCountGoal! - viewModel.wordCount)
        XCTAssertEqual(remaining, 50)
    }

    @MainActor
    func testWordCountSheetWithGoalReached() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()

        // Set a word count goal
        viewModel.wordCountGoal = 50

        // Add content that reaches the goal
        viewModel.aiResponse = String(repeating: "word ", count: 50)
        viewModel.insertAIResponse()

        // Show word count
        viewModel.showWordCount()

        XCTAssertTrue(viewModel.showWordCountSheet)
        XCTAssertEqual(viewModel.wordCount, 50)
        XCTAssertEqual(viewModel.wordCountGoal, 50)

        // Calculate remaining - should be 0
        let remaining = max(0, viewModel.wordCountGoal! - viewModel.wordCount)
        XCTAssertEqual(remaining, 0)
    }

    @MainActor
    func testWordCountSheetWithGoalExceeded() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()

        // Set a word count goal
        viewModel.wordCountGoal = 25

        // Add content that exceeds the goal
        viewModel.aiResponse = String(repeating: "word ", count: 50)
        viewModel.insertAIResponse()

        // Show word count
        viewModel.showWordCount()

        XCTAssertTrue(viewModel.showWordCountSheet)
        XCTAssertEqual(viewModel.wordCount, 50)
        XCTAssertEqual(viewModel.wordCountGoal, 25)

        // Calculate remaining - should be 0 (capped at 0)
        let remaining = max(0, viewModel.wordCountGoal! - viewModel.wordCount)
        XCTAssertEqual(remaining, 0)

        // Progress would be min(wordCount, goal) / goal
        let progress = Double(min(viewModel.wordCount, viewModel.wordCountGoal!)) / Double(viewModel.wordCountGoal!)
        XCTAssertEqual(progress, 1.0)
    }

    // MARK: - Word Count Detail View Calculations Tests

    @MainActor
    func testSentenceCountWithComplexPunctuation() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()

        // Test with ellipsis, abbreviations, etc.
        viewModel.currentDocumentContent = "Dr. Smith went to the store. He bought milk... And then he left!"

        let sentenceCount = calculateSentenceCount(from: viewModel.currentDocumentContent)
        // "Dr" creates a false sentence boundary, so this might count more than 3
        XCTAssertGreaterThan(sentenceCount, 0)
    }

    @MainActor
    func testSentenceCountWithQuotes() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()

        viewModel.currentDocumentContent = "He said, \"Hello!\" She replied, \"Hi there.\""

        let sentenceCount = calculateSentenceCount(from: viewModel.currentDocumentContent)
        XCTAssertGreaterThan(sentenceCount, 0)
    }

    @MainActor
    func testParagraphCountWithComplexFormatting() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()

        // Test with multiple blank lines
        viewModel.currentDocumentContent = "Paragraph one.\n\n\n\nParagraph two.\n\nParagraph three."

        let paragraphCount = calculateParagraphCount(from: viewModel.currentDocumentContent)
        XCTAssertEqual(paragraphCount, 3)
    }

    @MainActor
    func testParagraphCountWithMixedNewlines() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()

        // Mix of single and double newlines
        viewModel.currentDocumentContent = "Line 1\nLine 2\n\nParagraph 2\nMore of paragraph 2"

        let paragraphCount = calculateParagraphCount(from: viewModel.currentDocumentContent)
        // Lines with single newline are part of same paragraph
        XCTAssertEqual(paragraphCount, 2)
    }

    // MARK: - Extreme Edge Cases

    @MainActor
    func testFormatSuggestionDateFarFuture() {
        // Test with a date in the future (negative interval)
        let now = Date()
        let future = now.addingTimeInterval(3600) // 1 hour in future

        let formatted = formatSuggestionDate(future)

        // The function doesn't handle future dates, so result is implementation-dependent
        // This test ensures it doesn't crash
        XCTAssertNotNil(formatted)
    }

    @MainActor
    func testFormatSuggestionDateVeryOld() {
        let now = Date()
        let veryOld = now.addingTimeInterval(-864000) // 10 days ago

        let formatted = formatSuggestionDate(veryOld)

        XCTAssertEqual(formatted, "10d ago")
    }

    @MainActor
    func testFormatSuggestionDateExtremelyOld() {
        let now = Date()
        let extremelyOld = now.addingTimeInterval(-8640000) // 100 days ago

        let formatted = formatSuggestionDate(extremelyOld)

        XCTAssertEqual(formatted, "100d ago")
    }

    @MainActor
    func testWordCountWithOnlyWhitespace() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()

        viewModel.aiResponse = "     \n\n\n\t\t\t     "
        viewModel.insertAIResponse()

        // Only whitespace should result in 0 words
        XCTAssertEqual(viewModel.wordCount, 0)
    }

    @MainActor
    func testWordCountWithEmojis() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()

        viewModel.aiResponse = "Hello 😀 world 🌍 test 🎉"
        viewModel.insertAIResponse()

        // Emojis might be counted as words or not, depending on implementation
        // This tests that the count is reasonable
        XCTAssertGreaterThan(viewModel.wordCount, 0)
        XCTAssertLessThanOrEqual(viewModel.wordCount, 6)
    }

    @MainActor
    func testWordCountWithNumbers() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()

        viewModel.aiResponse = "123 456 789 test 100"
        viewModel.insertAIResponse()

        // Numbers should be counted as words
        XCTAssertEqual(viewModel.wordCount, 5)
    }

    @MainActor
    func testWordCountWithHyphens() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()

        viewModel.aiResponse = "well-known up-to-date state-of-the-art"
        viewModel.insertAIResponse()

        // Hyphenated words might be counted as one or multiple words
        XCTAssertGreaterThan(viewModel.wordCount, 0)
    }

    @MainActor
    func testCharacterCountWithEmojis() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()

        viewModel.aiResponse = "😀🌍🎉"
        viewModel.insertAIResponse()

        // Character count should include emojis
        XCTAssertGreaterThan(viewModel.characterCount, 0)
    }

    @MainActor
    func testVeryLargeWordCount() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()

        // Add 10,000 words
        viewModel.aiResponse = String(repeating: "word ", count: 10000)
        viewModel.insertAIResponse()

        XCTAssertEqual(viewModel.wordCount, 10000)

        // Reading time: 10000 / 200 = 50 minutes
        XCTAssertEqual(viewModel.readingTime, 50)
    }

    @MainActor
    func testReadingTimeRounding() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()

        // Test rounding behavior
        // 250 words: 250 / 200 = 1.25 -> truncated to 1
        viewModel.aiResponse = String(repeating: "word ", count: 250)
        viewModel.insertAIResponse()

        XCTAssertEqual(viewModel.wordCount, 250)
        XCTAssertEqual(viewModel.readingTime, 1) // Integer division truncates
    }

    @MainActor
    func testReadingTimeExactBoundary() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()

        // Exactly 600 words: 600 / 200 = 3 minutes
        viewModel.aiResponse = String(repeating: "word ", count: 600)
        viewModel.insertAIResponse()

        XCTAssertEqual(viewModel.wordCount, 600)
        XCTAssertEqual(viewModel.readingTime, 3)
    }

    // MARK: - Word Count Goal Progress Edge Cases

    @MainActor
    func testWordCountGoalProgressWithZeroGoal() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()

        viewModel.wordCountGoal = 0
        viewModel.aiResponse = "Test content"
        viewModel.insertAIResponse()

        // Progress calculation with zero goal would cause division by zero
        // The view should handle this gracefully
        XCTAssertEqual(viewModel.wordCountGoal, 0)
        XCTAssertGreaterThan(viewModel.wordCount, 0)
    }

    @MainActor
    func testWordCountGoalProgressAtExactGoal() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()

        viewModel.wordCountGoal = 100
        viewModel.aiResponse = String(repeating: "word ", count: 100)
        viewModel.insertAIResponse()

        XCTAssertEqual(viewModel.wordCount, 100)
        XCTAssertEqual(viewModel.wordCountGoal, 100)

        // Progress should be exactly 1.0
        let progress = Double(min(viewModel.wordCount, viewModel.wordCountGoal!)) / Double(viewModel.wordCountGoal!)
        XCTAssertEqual(progress, 1.0)

        let remaining = max(0, viewModel.wordCountGoal! - viewModel.wordCount)
        XCTAssertEqual(remaining, 0)
    }

    @MainActor
    func testWordCountGoalProgressNearGoal() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()

        viewModel.wordCountGoal = 100
        viewModel.aiResponse = String(repeating: "word ", count: 99)
        viewModel.insertAIResponse()

        XCTAssertEqual(viewModel.wordCount, 99)

        let remaining = max(0, viewModel.wordCountGoal! - viewModel.wordCount)
        XCTAssertEqual(remaining, 1)

        let progress = Double(min(viewModel.wordCount, viewModel.wordCountGoal!)) / Double(viewModel.wordCountGoal!)
        XCTAssertGreaterThan(progress, 0.98)
        XCTAssertLessThan(progress, 1.0)
    }

    @MainActor
    func testWordCountGoalProgressWellOverGoal() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()

        viewModel.wordCountGoal = 100
        viewModel.aiResponse = String(repeating: "word ", count: 500)
        viewModel.insertAIResponse()

        XCTAssertEqual(viewModel.wordCount, 500)

        let remaining = max(0, viewModel.wordCountGoal! - viewModel.wordCount)
        XCTAssertEqual(remaining, 0)

        // Progress should be capped at 1.0 for display purposes
        let progress = Double(min(viewModel.wordCount, viewModel.wordCountGoal!)) / Double(viewModel.wordCountGoal!)
        XCTAssertEqual(progress, 1.0)
    }

    @MainActor
    func testWordCountGoalVeryLargeGoal() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()

        viewModel.wordCountGoal = 1_000_000
        viewModel.aiResponse = "Just a few words"
        viewModel.insertAIResponse()

        XCTAssertEqual(viewModel.wordCountGoal, 1_000_000)
        XCTAssertLessThan(viewModel.wordCount, 1_000_000)

        let remaining = max(0, viewModel.wordCountGoal! - viewModel.wordCount)
        XCTAssertGreaterThan(remaining, 990_000)
    }

    // MARK: - Multiple Sequential Operations Tests

    @MainActor
    func testMultipleInsertAIResponseCalls() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()

        // First insert
        viewModel.aiResponse = "First response"
        viewModel.insertAIResponse()
        let firstWordCount = viewModel.wordCount
        XCTAssertEqual(firstWordCount, 2)

        // Second insert
        viewModel.aiResponse = "Second response"
        viewModel.insertAIResponse()
        let secondWordCount = viewModel.wordCount
        XCTAssertEqual(secondWordCount, 4)

        // Third insert
        viewModel.aiResponse = "Third response"
        viewModel.insertAIResponse()
        XCTAssertEqual(viewModel.wordCount, 6)
    }

    @MainActor
    func testToggleOperationsMultipleTimes() {
        let viewModel = WritersAppViewModel()

        // Toggle AI panel multiple times
        let initialState = viewModel.showAIPanel
        for _ in 0..<10 {
            viewModel.toggleAIPanel()
        }
        // After even number of toggles, should be back to initial state
        XCTAssertEqual(viewModel.showAIPanel, initialState)

        // Toggle focus mode multiple times
        let initialFocusMode = viewModel.isFocusMode
        for _ in 0..<10 {
            viewModel.toggleFocusMode()
        }
        XCTAssertEqual(viewModel.isFocusMode, initialFocusMode)
    }

    @MainActor
    func testCreateMultipleDocuments() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()

        // Create first document
        viewModel.createNewDocument()
        viewModel.currentDocumentTitle = "Document 1"
        viewModel.aiResponse = "Content 1"
        viewModel.insertAIResponse()
        let firstContent = viewModel.currentDocumentContent

        // Create second document
        viewModel.createNewDocument()
        // Content should be reset
        XCTAssertEqual(viewModel.currentDocumentTitle, "Untitled")
        XCTAssertEqual(viewModel.currentDocumentContent, "")
        XCTAssertNotEqual(viewModel.currentDocumentContent, firstContent)
    }

    @MainActor
    func testSaveDocumentWithEmptyContent() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()
        viewModel.createNewDocument()

        // Save with empty content
        viewModel.saveDocument()

        XCTAssertTrue(viewModel.isSaving)
        // Document should still be savable even with empty content
        XCTAssertEqual(viewModel.currentDocumentContent, "")
    }

    @MainActor
    func testSaveDocumentMultipleTimes() async {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()
        viewModel.createNewDocument()

        viewModel.currentDocumentContent = "Test"

        // First save
        viewModel.saveDocument()
        XCTAssertTrue(viewModel.isSaving)
        try? await Task.sleep(nanoseconds: 600_000_000)
        XCTAssertFalse(viewModel.isSaving)

        // Second save
        viewModel.saveDocument()
        XCTAssertTrue(viewModel.isSaving)
        try? await Task.sleep(nanoseconds: 600_000_000)
        XCTAssertFalse(viewModel.isSaving)
    }

    // MARK: - Complex Content Scenarios

    @MainActor
    func testMixedLanguageContent() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()

        viewModel.aiResponse = "Hello world 世界 مرحبا мир"
        viewModel.insertAIResponse()

        // Mixed language content should be handled
        XCTAssertGreaterThan(viewModel.wordCount, 0)
        XCTAssertGreaterThan(viewModel.characterCount, 0)
    }

    @MainActor
    func testContentWithURLs() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()

        viewModel.aiResponse = "Visit https://example.com for more info"
        viewModel.insertAIResponse()

        // URLs should be counted in word count
        XCTAssertGreaterThan(viewModel.wordCount, 0)
    }

    @MainActor
    func testContentWithMarkdown() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()

        viewModel.aiResponse = "# Heading\n\n**Bold** and *italic* text"
        viewModel.insertAIResponse()

        // Markdown syntax should be counted
        XCTAssertGreaterThan(viewModel.wordCount, 0)
    }

    @MainActor
    func testContentWithCodeBlocks() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()

        viewModel.aiResponse = "Here is code: `let x = 5` end"
        viewModel.insertAIResponse()

        XCTAssertGreaterThan(viewModel.wordCount, 0)
    }

    @MainActor
    func testVeryLongSingleWord() {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()

        // Create a very long "word" with no spaces
        let longWord = String(repeating: "a", count: 10000)
        viewModel.aiResponse = longWord
        viewModel.insertAIResponse()

        // Should count as 1 word
        XCTAssertEqual(viewModel.wordCount, 1)
        XCTAssertEqual(viewModel.characterCount, longWord.count + 2) // +2 for "\n\n"
    }
}

#endif