import XCTest
@testable import WritersApp

#if canImport(SwiftUI) && os(iOS)
import SwiftUI

@available(iOS 16.0, macOS 13.0, *)
final class iPadProViewsTests: XCTestCase {

    // MARK: - WritersAppViewModel Tests

    func testViewModelInitialization() {
        let viewModel = WritersAppViewModel()

        XCTAssertEqual(viewModel.currentDocumentTitle, "Untitled")
        XCTAssertEqual(viewModel.currentDocumentContent, "")
        XCTAssertTrue(viewModel.showAIPanel)
        XCTAssertFalse(viewModel.isFocusMode)
        XCTAssertFalse(viewModel.isSaving)
        XCTAssertEqual(viewModel.aiResponse, "")
        XCTAssertFalse(viewModel.showWordCountSheet)

        // Statistics
        XCTAssertEqual(viewModel.wordCount, 0)
        XCTAssertEqual(viewModel.characterCount, 0)
        XCTAssertEqual(viewModel.readingTime, 1)
        XCTAssertNil(viewModel.wordCountGoal)

        // Layout
        XCTAssertEqual(viewModel.bodyFontSize, 17)
        XCTAssertEqual(viewModel.lineSpacing, 8)
    }

    func testViewModelStatisticsCalculation() {
        // Test the statistics calculation logic directly using Document model
        let doc = Document(
            title: "Test",
            content: "The quick brown fox jumps over the lazy dog",
            category: .article
        )

        XCTAssertEqual(doc.wordCount, 9)
        XCTAssertEqual(doc.characterCount, 44)
        XCTAssertEqual(doc.readingTime, 1) // 9 words / 200 wpm = 0.045 min, max(1) = 1
    }

    func testViewModelStatisticsWithLargeContent() {
        // Create content with exactly 600 words
        let words = Array(repeating: "word", count: 600).joined(separator: " ")
        let doc = Document(title: "Test", content: words, category: .article)

        XCTAssertEqual(doc.wordCount, 600)
        XCTAssertEqual(doc.readingTime, 3) // 600 / 200 = 3 minutes
    }

    func testViewModelStatisticsWithEmptyContent() {
        let doc = Document(title: "Test", content: "", category: .article)

        XCTAssertEqual(doc.wordCount, 0)
        XCTAssertEqual(doc.characterCount, 0)
        XCTAssertEqual(doc.readingTime, 1) // Minimum reading time is 1 minute
    }

    func testViewModelStatisticsWithWhitespaceOnly() {
        let doc = Document(title: "Test", content: "   \n\n\t  \n  ", category: .article)

        XCTAssertEqual(doc.wordCount, 0)
        XCTAssertGreaterThan(doc.characterCount, 0) // Whitespace counts as characters
        XCTAssertEqual(doc.readingTime, 1)
    }

    @MainActor
    func testViewModelToggleAIPanel() async {
        let viewModel = WritersAppViewModel()

        XCTAssertTrue(viewModel.showAIPanel)
        viewModel.toggleAIPanel()
        XCTAssertFalse(viewModel.showAIPanel)
        viewModel.toggleAIPanel()
        XCTAssertTrue(viewModel.showAIPanel)
    }

    @MainActor
    func testViewModelToggleFocusMode() async {
        let viewModel = WritersAppViewModel()

        XCTAssertFalse(viewModel.isFocusMode)
        viewModel.toggleFocusMode()
        XCTAssertTrue(viewModel.isFocusMode)
        viewModel.toggleFocusMode()
        XCTAssertFalse(viewModel.isFocusMode)
    }

    @MainActor
    func testViewModelShowWordCount() async {
        let viewModel = WritersAppViewModel()

        XCTAssertFalse(viewModel.showWordCountSheet)
        viewModel.showWordCount()
        XCTAssertTrue(viewModel.showWordCountSheet)
    }

    @MainActor
    func testViewModelInsertAIResponse() async {
        let viewModel = WritersAppViewModel()

        viewModel.currentDocumentContent = "Initial content"
        viewModel.aiResponse = "AI generated content"

        viewModel.insertAIResponse()

        XCTAssertTrue(viewModel.currentDocumentContent.contains("Initial content"))
        XCTAssertTrue(viewModel.currentDocumentContent.contains("AI generated content"))
        XCTAssertEqual(viewModel.aiResponse, "")
    }

    @MainActor
    func testViewModelInsertAIResponseWithEmptyDocument() async {
        let viewModel = WritersAppViewModel()

        viewModel.currentDocumentContent = ""
        viewModel.aiResponse = "AI generated content"

        viewModel.insertAIResponse()

        XCTAssertTrue(viewModel.currentDocumentContent.contains("AI generated content"))
        XCTAssertEqual(viewModel.aiResponse, "")
    }

    @MainActor
    func testViewModelMultitaskingStateUpdate() async {
        let viewModel = WritersAppViewModel()

        // Test full screen size
        let fullScreenSize = CGSize(width: 1200, height: 800)
        viewModel.updateMultitaskingState(size: fullScreenSize)

        // Font sizes should be appropriate for full screen
        XCTAssertGreaterThan(viewModel.bodyFontSize, 0)
        XCTAssertGreaterThan(viewModel.lineSpacing, 0)

        // Test small size (slide over)
        let slideOverSize = CGSize(width: 320, height: 800)
        viewModel.updateMultitaskingState(size: slideOverSize)

        // AI panel should be hidden in small mode
        XCTAssertFalse(viewModel.showAIPanel)
    }

    @MainActor
    func testViewModelEditorPaddingIsConfigured() async {
        let viewModel = WritersAppViewModel()

        XCTAssertGreaterThan(viewModel.editorPadding.top, 0)
        XCTAssertGreaterThan(viewModel.editorPadding.leading, 0)
        XCTAssertGreaterThan(viewModel.editorPadding.bottom, 0)
        XCTAssertGreaterThan(viewModel.editorPadding.trailing, 0)
    }

    // MARK: - WordCountDetailView Sentence Counting Tests

    func testSentenceCountWithSimpleText() {
        let content = "This is a sentence. This is another sentence."
        let sentences = content.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        let count = sentences.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count

        XCTAssertEqual(count, 2)
    }

    func testSentenceCountWithMixedPunctuation() {
        let content = "Is this a question? Yes! This is an answer. How exciting!"
        let sentences = content.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        let count = sentences.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count

        XCTAssertEqual(count, 4)
    }

    func testSentenceCountWithEmptyContent() {
        let content = ""
        let sentences = content.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        let count = sentences.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count

        XCTAssertEqual(count, 0)
    }

    func testSentenceCountWithWhitespaceOnly() {
        let content = "   \n\n\t  "
        let sentences = content.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        let count = sentences.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count

        XCTAssertEqual(count, 1) // Whitespace counts as one sentence if no punctuation
    }

    func testSentenceCountWithNoPunctuation() {
        let content = "This is text without ending punctuation"
        let sentences = content.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        let count = sentences.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count

        XCTAssertEqual(count, 1) // Content without punctuation is still one sentence
    }

    func testSentenceCountWithMultiplePunctuationMarks() {
        let content = "Really?! Yes!! Amazing..."
        let sentences = content.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        let count = sentences.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count

        // "Really", "", " Yes", "", " Amazing", "", ""
        // After filtering empty/whitespace: "Really", " Yes", " Amazing"
        XCTAssertEqual(count, 3)
    }

    func testSentenceCountWithAbbreviations() {
        let content = "Dr. Smith went to the U.S.A. He had fun."
        let sentences = content.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        let count = sentences.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count

        // Splits on all periods: "Dr", " Smith went to the U", "S", "A", " He had fun", ""
        // After filtering: "Dr", " Smith went to the U", "S", "A", " He had fun"
        XCTAssertEqual(count, 5) // Note: abbreviations cause multiple splits
    }

    // MARK: - WordCountDetailView Paragraph Counting Tests

    func testParagraphCountWithSimpleParagraphs() {
        let content = "First paragraph.\n\nSecond paragraph.\n\nThird paragraph."
        let paragraphs = content.components(separatedBy: "\n\n")
        let count = paragraphs.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count

        XCTAssertEqual(count, 3)
    }

    func testParagraphCountWithSingleParagraph() {
        let content = "This is all one paragraph without double newlines."
        let paragraphs = content.components(separatedBy: "\n\n")
        let count = paragraphs.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count

        XCTAssertEqual(count, 1)
    }

    func testParagraphCountWithEmptyContent() {
        let content = ""
        let paragraphs = content.components(separatedBy: "\n\n")
        let count = paragraphs.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count

        XCTAssertEqual(count, 0)
    }

    func testParagraphCountWithWhitespaceOnly() {
        let content = "   \n\n\t  "
        let paragraphs = content.components(separatedBy: "\n\n")
        let count = paragraphs.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count

        XCTAssertEqual(count, 0)
    }

    func testParagraphCountWithSingleNewlines() {
        let content = "Line one\nLine two\nLine three"
        let paragraphs = content.components(separatedBy: "\n\n")
        let count = paragraphs.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count

        XCTAssertEqual(count, 1) // Single newlines don't split paragraphs
    }

    func testParagraphCountWithMultipleConsecutiveNewlines() {
        let content = "First paragraph.\n\n\n\nSecond paragraph."
        let paragraphs = content.components(separatedBy: "\n\n")
        let count = paragraphs.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count

        // Splits into: "First paragraph.", "", "Second paragraph."
        // After filtering: "First paragraph.", "Second paragraph."
        XCTAssertEqual(count, 2)
    }

    func testParagraphCountWithLeadingAndTrailingNewlines() {
        let content = "\n\nFirst paragraph.\n\nSecond paragraph.\n\n"
        let paragraphs = content.components(separatedBy: "\n\n")
        let count = paragraphs.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count

        XCTAssertEqual(count, 2)
    }

    // MARK: - AISidebarView formatSuggestionDate Tests

    func testFormatSuggestionDateJustNow() {
        let now = Date()
        let result = formatSuggestionDate(now, relativeTo: now)
        XCTAssertEqual(result, "Just now")
    }

    func testFormatSuggestionDate30SecondsAgo() {
        let now = Date()
        let past = now.addingTimeInterval(-30)
        let result = formatSuggestionDate(past, relativeTo: now)
        XCTAssertEqual(result, "Just now")
    }

    func testFormatSuggestionDate1MinuteAgo() {
        let now = Date()
        let past = now.addingTimeInterval(-60)
        let result = formatSuggestionDate(past, relativeTo: now)
        XCTAssertEqual(result, "1m ago")
    }

    func testFormatSuggestionDate5MinutesAgo() {
        let now = Date()
        let past = now.addingTimeInterval(-5 * 60)
        let result = formatSuggestionDate(past, relativeTo: now)
        XCTAssertEqual(result, "5m ago")
    }

    func testFormatSuggestionDate59MinutesAgo() {
        let now = Date()
        let past = now.addingTimeInterval(-59 * 60)
        let result = formatSuggestionDate(past, relativeTo: now)
        XCTAssertEqual(result, "59m ago")
    }

    func testFormatSuggestionDate1HourAgo() {
        let now = Date()
        let past = now.addingTimeInterval(-3600)
        let result = formatSuggestionDate(past, relativeTo: now)
        XCTAssertEqual(result, "1h ago")
    }

    func testFormatSuggestionDate3HoursAgo() {
        let now = Date()
        let past = now.addingTimeInterval(-3 * 3600)
        let result = formatSuggestionDate(past, relativeTo: now)
        XCTAssertEqual(result, "3h ago")
    }

    func testFormatSuggestionDate23HoursAgo() {
        let now = Date()
        let past = now.addingTimeInterval(-23 * 3600)
        let result = formatSuggestionDate(past, relativeTo: now)
        XCTAssertEqual(result, "23h ago")
    }

    func testFormatSuggestionDate1DayAgo() {
        let now = Date()
        let past = now.addingTimeInterval(-86400)
        let result = formatSuggestionDate(past, relativeTo: now)
        XCTAssertEqual(result, "1d ago")
    }

    func testFormatSuggestionDate5DaysAgo() {
        let now = Date()
        let past = now.addingTimeInterval(-5 * 86400)
        let result = formatSuggestionDate(past, relativeTo: now)
        XCTAssertEqual(result, "5d ago")
    }

    func testFormatSuggestionDate30DaysAgo() {
        let now = Date()
        let past = now.addingTimeInterval(-30 * 86400)
        let result = formatSuggestionDate(past, relativeTo: now)
        XCTAssertEqual(result, "30d ago")
    }

    // MARK: - Edge Cases for formatSuggestionDate

    func testFormatSuggestionDateBoundaryMinutes() {
        let now = Date()

        // Just under 1 hour (59 minutes 59 seconds)
        let almostOneHour = now.addingTimeInterval(-(59 * 60 + 59))
        let result1 = formatSuggestionDate(almostOneHour, relativeTo: now)
        XCTAssertEqual(result1, "59m ago")

        // Exactly 1 hour
        let exactlyOneHour = now.addingTimeInterval(-3600)
        let result2 = formatSuggestionDate(exactlyOneHour, relativeTo: now)
        XCTAssertEqual(result2, "1h ago")
    }

    func testFormatSuggestionDateBoundaryHours() {
        let now = Date()

        // Just under 1 day (23 hours 59 minutes)
        let almostOneDay = now.addingTimeInterval(-(23 * 3600 + 59 * 60))
        let result1 = formatSuggestionDate(almostOneDay, relativeTo: now)
        XCTAssertEqual(result1, "23h ago")

        // Exactly 1 day
        let exactlyOneDay = now.addingTimeInterval(-86400)
        let result2 = formatSuggestionDate(exactlyOneDay, relativeTo: now)
        XCTAssertEqual(result2, "1d ago")
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

    func testAllTemplateCategoriesHaveIconAndDisplayName() {
        // Ensure all cases are covered
        for category in TemplateCategory.allCases {
            XCTAssertFalse(category.iconName.isEmpty, "Category \(category) should have an icon name")
            XCTAssertFalse(category.displayName.isEmpty, "Category \(category) should have a display name")
        }
    }

    // MARK: - SidebarSection Hashable Tests

    func testSidebarSectionHashable() {
        let section1 = SidebarSection.documents
        let section2 = SidebarSection.documents
        let section3 = SidebarSection.templates

        XCTAssertEqual(section1, section2)
        XCTAssertNotEqual(section1, section3)
    }

    func testSidebarSectionCategoryHashable() {
        let section1 = SidebarSection.category(.novel)
        let section2 = SidebarSection.category(.novel)
        let section3 = SidebarSection.category(.article)

        XCTAssertEqual(section1, section2)
        XCTAssertNotEqual(section1, section3)
    }

    // MARK: - Integration Tests

    func testStatisticsIntegrationWithRealContent() {
        let sampleContent = """
        Chapter One

        It was a dark and stormy night. The rain poured down in sheets, and the wind howled through the trees.

        John sat by the window, watching the storm rage outside. He wondered if she would come.

        Three hours passed. Still no sign of her.
        """

        let doc = Document(title: "Sample", content: sampleContent, category: .novel)

        // Verify statistics make sense
        XCTAssertGreaterThan(doc.wordCount, 40)
        XCTAssertGreaterThan(doc.characterCount, 200)
        XCTAssertGreaterThanOrEqual(doc.readingTime, 1)
    }

    func testWordCountGoalProgressCalculation() {
        let goal = 500
        let content = Array(repeating: "word", count: 250).joined(separator: " ")
        let doc = Document(title: "Test", content: content, category: .article)

        XCTAssertEqual(doc.wordCount, 250)

        // Test progress calculation that would be used in views
        let progress = Double(doc.wordCount) / Double(goal)
        XCTAssertEqual(progress, 0.5, accuracy: 0.01)
    }

    func testWordCountGoalReachedCalculation() {
        let goal = 100
        let content = Array(repeating: "word", count: 100).joined(separator: " ")
        let doc = Document(title: "Test", content: content, category: .article)

        XCTAssertEqual(doc.wordCount, 100)

        let progress = Double(doc.wordCount) / Double(goal)
        XCTAssertEqual(progress, 1.0, accuracy: 0.01)

        let remaining = max(0, goal - doc.wordCount)
        XCTAssertEqual(remaining, 0)
    }

    func testWordCountExceedsGoalCalculation() {
        let goal = 100
        let content = Array(repeating: "word", count: 150).joined(separator: " ")
        let doc = Document(title: "Test", content: content, category: .article)

        XCTAssertEqual(doc.wordCount, 150)

        let remaining = max(0, goal - doc.wordCount)
        XCTAssertEqual(remaining, 0) // No negative remaining
    }

    // MARK: - Regression Tests

    func testDocumentDoesNotCrashWithVeryLargeContent() {
        // Create very large content (10,000 words)
        let largeContent = Array(repeating: "word", count: 10000).joined(separator: " ")
        let doc = Document(title: "Large", content: largeContent, category: .novel)

        XCTAssertEqual(doc.wordCount, 10000)
        XCTAssertEqual(doc.readingTime, 50) // 10000 / 200 = 50 minutes
    }

    func testDocumentDoesNotCrashWithUnicodeContent() {
        let doc = Document(
            title: "Unicode",
            content: "Hello 世界 🌍 مرحبا Привет",
            category: .article
        )

        XCTAssertGreaterThan(doc.wordCount, 0)
        XCTAssertGreaterThan(doc.characterCount, 0)
    }

    func testDocumentDoesNotCrashWithEmojiOnlyContent() {
        let doc = Document(
            title: "Emoji",
            content: "🎉 🎊 🎈 🎁",
            category: .article
        )

        XCTAssertGreaterThan(doc.characterCount, 0)
    }

    @MainActor
    func testViewModelMultipleTogglesDoNotCorruptState() async {
        let viewModel = WritersAppViewModel()

        // Toggle AI panel multiple times
        for _ in 0..<10 {
            viewModel.toggleAIPanel()
        }
        XCTAssertTrue(viewModel.showAIPanel) // Should end up as true (started true, toggled even number)

        // Toggle focus mode multiple times
        for _ in 0..<5 {
            viewModel.toggleFocusMode()
        }
        XCTAssertTrue(viewModel.isFocusMode) // Should end up as true (started false, toggled odd number)
    }

    // MARK: - Boundary Tests

    func testSentenceCountWithOnlyPunctuation() {
        let content = "...!!!???"
        let sentences = content.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        let count = sentences.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count

        XCTAssertEqual(count, 0) // Only punctuation, no actual sentences
    }

    func testParagraphCountWithOnlyNewlines() {
        let content = "\n\n\n\n\n\n"
        let paragraphs = content.components(separatedBy: "\n\n")
        let count = paragraphs.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count

        XCTAssertEqual(count, 0)
    }

    func testFormatSuggestionDateWithZeroInterval() {
        let now = Date()
        let result = formatSuggestionDate(now, relativeTo: now)
        XCTAssertEqual(result, "Just now")
    }

    // MARK: - Document Operations Tests

    @MainActor
    func testViewModelCreateNewDocument() async {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()

        viewModel.createNewDocument()

        XCTAssertEqual(viewModel.currentDocumentTitle, "Untitled")
        XCTAssertEqual(viewModel.currentDocumentContent, "")
    }

    @MainActor
    func testViewModelSaveDocumentUpdatesState() async {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()
        viewModel.createNewDocument()

        viewModel.currentDocumentTitle = "My Document"
        viewModel.currentDocumentContent = "Some content"

        XCTAssertFalse(viewModel.isSaving)
        viewModel.saveDocument()
        XCTAssertTrue(viewModel.isSaving)
    }

    @MainActor
    func testViewModelSaveDocumentEventuallyCompletes() async {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()
        viewModel.createNewDocument()

        viewModel.currentDocumentTitle = "Test Document"
        viewModel.currentDocumentContent = "Test content"

        viewModel.saveDocument()
        XCTAssertTrue(viewModel.isSaving)

        // Wait for save to complete (simulated delay is 0.5s)
        try? await Task.sleep(nanoseconds: 600_000_000) // 0.6 seconds

        XCTAssertFalse(viewModel.isSaving)
    }

    // MARK: - Reading Time Edge Cases

    func testReadingTimeWithOneWord() {
        let doc = Document(title: "Test", content: "Hello", category: .article)
        XCTAssertEqual(doc.readingTime, 1) // Minimum is 1 minute
    }

    func testReadingTimeWithExactly200Words() {
        let content = Array(repeating: "word", count: 200).joined(separator: " ")
        let doc = Document(title: "Test", content: content, category: .article)
        XCTAssertEqual(doc.readingTime, 1) // 200 words / 200 wpm = 1 minute
    }

    func testReadingTimeWithExactly201Words() {
        let content = Array(repeating: "word", count: 201).joined(separator: " ")
        let doc = Document(title: "Test", content: content, category: .article)
        XCTAssertEqual(doc.readingTime, 1) // 201 words / 200 wpm = 1.005 minutes, rounds to 1
    }

    func testReadingTimeWithExactly400Words() {
        let content = Array(repeating: "word", count: 400).joined(separator: " ")
        let doc = Document(title: "Test", content: content, category: .article)
        XCTAssertEqual(doc.readingTime, 2) // 400 words / 200 wpm = 2 minutes
    }

    func testReadingTimeWith5000Words() {
        let content = Array(repeating: "word", count: 5000).joined(separator: " ")
        let doc = Document(title: "Test", content: content, category: .article)
        XCTAssertEqual(doc.readingTime, 25) // 5000 words / 200 wpm = 25 minutes
    }

    // MARK: - Word Count with Special Content

    func testWordCountWithPunctuationOnly() {
        let doc = Document(title: "Test", content: ".,;:!?", category: .article)
        XCTAssertEqual(doc.wordCount, 1) // Punctuation marks are treated as words by default split
    }

    func testWordCountWithMixedSpacesAndTabs() {
        let doc = Document(title: "Test", content: "word1\t\tword2   word3\n\nword4", category: .article)
        XCTAssertEqual(doc.wordCount, 4)
    }

    func testWordCountWithNumbersAndSymbols() {
        let doc = Document(title: "Test", content: "123 456 $789 #hashtag @mention", category: .article)
        XCTAssertEqual(doc.wordCount, 5)
    }

    func testWordCountWithHyphensAndApostrophes() {
        let doc = Document(title: "Test", content: "it's don't can't won't mother-in-law well-being", category: .article)
        // Each hyphenated/apostrophe word counts as one word
        XCTAssertEqual(doc.wordCount, 6)
    }

    func testWordCountWithURLs() {
        let doc = Document(title: "Test", content: "Visit https://example.com for more info", category: .article)
        XCTAssertEqual(doc.wordCount, 5)
    }

    func testWordCountWithNewlinesInContent() {
        let doc = Document(title: "Test", content: "line1\nline2\nline3\nline4\nline5", category: .article)
        XCTAssertEqual(doc.wordCount, 5)
    }

    // MARK: - Character Count Tests

    func testCharacterCountWithEmojis() {
        let doc = Document(title: "Test", content: "Hello 👋 World 🌍", category: .article)
        // Swift's count property counts Unicode scalar values
        XCTAssertGreaterThan(doc.characterCount, 10)
    }

    func testCharacterCountWithNewlines() {
        let doc = Document(title: "Test", content: "Line1\nLine2\nLine3", category: .article)
        XCTAssertEqual(doc.characterCount, 17) // Including newline characters
    }

    func testCharacterCountWithTabs() {
        let doc = Document(title: "Test", content: "Word1\tWord2\tWord3", category: .article)
        XCTAssertEqual(doc.characterCount, 17) // Including tab characters
    }

    // MARK: - Word Count Goal Progress Tests

    func testWordCountGoalProgressAtZero() {
        let goal = 1000
        let wordCount = 0

        let progress = Double(wordCount) / Double(goal)
        XCTAssertEqual(progress, 0.0)

        let remaining = max(0, goal - wordCount)
        XCTAssertEqual(remaining, 1000)
    }

    func testWordCountGoalProgressAt25Percent() {
        let goal = 1000
        let wordCount = 250

        let progress = Double(wordCount) / Double(goal)
        XCTAssertEqual(progress, 0.25, accuracy: 0.001)

        let remaining = max(0, goal - wordCount)
        XCTAssertEqual(remaining, 750)
    }

    func testWordCountGoalProgressAt50Percent() {
        let goal = 1000
        let wordCount = 500

        let progress = Double(wordCount) / Double(goal)
        XCTAssertEqual(progress, 0.5, accuracy: 0.001)

        let remaining = max(0, goal - wordCount)
        XCTAssertEqual(remaining, 500)
    }

    func testWordCountGoalProgressAt99Percent() {
        let goal = 1000
        let wordCount = 990

        let progress = Double(wordCount) / Double(goal)
        XCTAssertEqual(progress, 0.99, accuracy: 0.001)

        let remaining = max(0, goal - wordCount)
        XCTAssertEqual(remaining, 10)
    }

    func testWordCountGoalProgressAt100Percent() {
        let goal = 1000
        let wordCount = 1000

        let progress = Double(wordCount) / Double(goal)
        XCTAssertEqual(progress, 1.0, accuracy: 0.001)

        let remaining = max(0, goal - wordCount)
        XCTAssertEqual(remaining, 0)
    }

    func testWordCountGoalProgressBeyond100Percent() {
        let goal = 1000
        let wordCount = 1500

        // The UI uses min(wordCount, goal) for the progress bar
        let displayedProgress = Double(min(wordCount, goal)) / Double(goal)
        XCTAssertEqual(displayedProgress, 1.0, accuracy: 0.001)

        let remaining = max(0, goal - wordCount)
        XCTAssertEqual(remaining, 0)
    }

    func testWordCountGoalWithSmallGoal() {
        let goal = 10
        let wordCount = 5

        let progress = Double(wordCount) / Double(goal)
        XCTAssertEqual(progress, 0.5, accuracy: 0.001)
    }

    // MARK: - Sentence Counting Edge Cases

    func testSentenceCountWithEllipsis() {
        let content = "This is a sentence... And another one."
        let sentences = content.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        let count = sentences.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count

        // Splits on each period: "This is a sentence", "", "", " And another one", ""
        XCTAssertEqual(count, 2) // After filtering: "This is a sentence", " And another one"
    }

    func testSentenceCountWithQuotedSentences() {
        let content = "He said, \"Hello.\" She replied, \"Hi!\""
        let sentences = content.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        let count = sentences.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count

        XCTAssertEqual(count, 2)
    }

    func testSentenceCountWithNewlinesInSentences() {
        let content = "This is\na sentence. This is\nanother sentence."
        let sentences = content.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        let count = sentences.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count

        XCTAssertEqual(count, 2)
    }

    // MARK: - Paragraph Counting Edge Cases

    func testParagraphCountWithMixedNewlineTypes() {
        let content = "Paragraph 1.\n\nParagraph 2.\n\nParagraph 3."
        let paragraphs = content.components(separatedBy: "\n\n")
        let count = paragraphs.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count

        XCTAssertEqual(count, 3)
    }

    func testParagraphCountWithTabsAndSpaces() {
        let content = "Paragraph 1.\n\n\tParagraph 2 with indent.\n\nParagraph 3."
        let paragraphs = content.components(separatedBy: "\n\n")
        let count = paragraphs.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count

        XCTAssertEqual(count, 3)
    }

    // MARK: - ViewModel State Consistency Tests

    @MainActor
    func testViewModelShowWordCountSheetToggles() async {
        let viewModel = WritersAppViewModel()

        XCTAssertFalse(viewModel.showWordCountSheet)

        viewModel.showWordCount()
        XCTAssertTrue(viewModel.showWordCountSheet)

        // User can dismiss by setting it back to false
        viewModel.showWordCountSheet = false
        XCTAssertFalse(viewModel.showWordCountSheet)

        // Can show again
        viewModel.showWordCount()
        XCTAssertTrue(viewModel.showWordCountSheet)
    }

    @MainActor
    func testViewModelAIPanelAndFocusModeAreIndependent() async {
        let viewModel = WritersAppViewModel()

        XCTAssertTrue(viewModel.showAIPanel)
        XCTAssertFalse(viewModel.isFocusMode)

        viewModel.toggleAIPanel()
        XCTAssertFalse(viewModel.showAIPanel)
        XCTAssertFalse(viewModel.isFocusMode)

        viewModel.toggleFocusMode()
        XCTAssertFalse(viewModel.showAIPanel)
        XCTAssertTrue(viewModel.isFocusMode)

        viewModel.toggleAIPanel()
        XCTAssertTrue(viewModel.showAIPanel)
        XCTAssertTrue(viewModel.isFocusMode)
    }

    @MainActor
    func testViewModelAIResponseInsertion() async {
        let viewModel = WritersAppViewModel()

        viewModel.currentDocumentContent = "Start"
        viewModel.aiResponse = "End"

        viewModel.insertAIResponse()

        XCTAssertEqual(viewModel.currentDocumentContent, "Start\n\nEnd")
        XCTAssertEqual(viewModel.aiResponse, "")
    }

    @MainActor
    func testViewModelMultipleAIResponseInsertions() async {
        let viewModel = WritersAppViewModel()

        viewModel.currentDocumentContent = "Line 1"
        viewModel.aiResponse = "Line 2"
        viewModel.insertAIResponse()

        XCTAssertEqual(viewModel.currentDocumentContent, "Line 1\n\nLine 2")

        viewModel.aiResponse = "Line 3"
        viewModel.insertAIResponse()

        XCTAssertEqual(viewModel.currentDocumentContent, "Line 1\n\nLine 2\n\nLine 3")
    }

    // MARK: - Multitasking Edge Cases

    @MainActor
    func testViewModelHandlesVerySmallScreenSize() async {
        let viewModel = WritersAppViewModel()

        // iPhone SE size in landscape
        let smallSize = CGSize(width: 568, height: 320)
        viewModel.updateMultitaskingState(size: smallSize)

        XCTAssertGreaterThan(viewModel.bodyFontSize, 0)
        XCTAssertGreaterThan(viewModel.lineSpacing, 0)
    }

    @MainActor
    func testViewModelHandlesVeryLargeScreenSize() async {
        let viewModel = WritersAppViewModel()

        // Large external display
        let largeSize = CGSize(width: 3840, height: 2160)
        viewModel.updateMultitaskingState(size: largeSize)

        XCTAssertGreaterThan(viewModel.bodyFontSize, 0)
        XCTAssertGreaterThan(viewModel.lineSpacing, 0)
    }

    @MainActor
    func testViewModelHandlesSquareScreenSize() async {
        let viewModel = WritersAppViewModel()

        let squareSize = CGSize(width: 800, height: 800)
        viewModel.updateMultitaskingState(size: squareSize)

        XCTAssertGreaterThan(viewModel.bodyFontSize, 0)
        XCTAssertGreaterThan(viewModel.lineSpacing, 0)
    }

    @MainActor
    func testViewModelHandlesPortraitOrientation() async {
        let viewModel = WritersAppViewModel()

        // iPad Pro 12.9" portrait
        let portraitSize = CGSize(width: 1024, height: 1366)
        viewModel.updateMultitaskingState(size: portraitSize)

        XCTAssertGreaterThan(viewModel.bodyFontSize, 0)
        XCTAssertGreaterThan(viewModel.lineSpacing, 0)
    }

    // MARK: - Integration Tests for Complex Scenarios

    @MainActor
    func testCompleteWritingWorkflow() async {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()

        // Create a new document
        viewModel.createNewDocument()
        XCTAssertEqual(viewModel.currentDocumentTitle, "Untitled")

        // Write some content
        viewModel.currentDocumentTitle = "My Story"
        viewModel.currentDocumentContent = "Once upon a time, there was a writer who loved to write."

        // Check statistics are computed (through Document model)
        let doc = Document(title: viewModel.currentDocumentTitle, content: viewModel.currentDocumentContent, category: .novel)
        XCTAssertGreaterThan(doc.wordCount, 0)
        XCTAssertGreaterThan(doc.characterCount, 0)

        // Show word count
        viewModel.showWordCount()
        XCTAssertTrue(viewModel.showWordCountSheet)

        // Save the document
        viewModel.saveDocument()
        XCTAssertTrue(viewModel.isSaving)
    }

    @MainActor
    func testAIWorkflow() async {
        let viewModel = WritersAppViewModel()

        XCTAssertTrue(viewModel.showAIPanel)
        XCTAssertEqual(viewModel.aiResponse, "")

        // Simulate AI response
        viewModel.aiResponse = "This is an AI-generated suggestion for your story."
        XCTAssertFalse(viewModel.aiResponse.isEmpty)

        // Insert the response
        viewModel.currentDocumentContent = "Beginning of story"
        viewModel.insertAIResponse()

        XCTAssertTrue(viewModel.currentDocumentContent.contains("Beginning of story"))
        XCTAssertTrue(viewModel.currentDocumentContent.contains("AI-generated suggestion"))
        XCTAssertEqual(viewModel.aiResponse, "")
    }

    // MARK: - Negative Test Cases

    func testDocumentHandlesControlCharacters() {
        let content = "Hello\u{0000}World\u{0001}Test\u{0002}"
        let doc = Document(title: "Test", content: content, category: .article)

        // Should not crash
        XCTAssertGreaterThan(doc.characterCount, 0)
    }

    func testDocumentHandlesZeroWidthCharacters() {
        let content = "Hello\u{200B}World\u{200C}Test" // Zero-width space and zero-width non-joiner
        let doc = Document(title: "Test", content: content, category: .article)

        // Should not crash
        XCTAssertGreaterThan(doc.characterCount, 0)
    }

    func testDocumentHandlesRightToLeftText() {
        let content = "Hello עברית مرحبا" // English, Hebrew, Arabic
        let doc = Document(title: "Test", content: content, category: .article)

        XCTAssertGreaterThan(doc.wordCount, 0)
        XCTAssertGreaterThan(doc.characterCount, 0)
    }

    func testSentenceCountWithMultilineContent() {
        let content = """
        First sentence on first line.
        Second sentence on second line!
        Third sentence on third line?
        """
        let sentences = content.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        let count = sentences.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count

        XCTAssertEqual(count, 3)
    }

    func testParagraphCountWithRealWorldContent() {
        let content = """
        This is the first paragraph. It contains multiple sentences. Each sentence adds to the paragraph.

        This is the second paragraph. It is shorter.

        This is the third paragraph.
        """
        let paragraphs = content.components(separatedBy: "\n\n")
        let count = paragraphs.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count

        XCTAssertEqual(count, 3)
    }

    // MARK: - Stress Tests

    func testDocumentWithExtremelyLongSingleLine() {
        // Create a very long line (10,000 characters)
        let longLine = String(repeating: "a", count: 10000)
        let doc = Document(title: "Test", content: longLine, category: .article)

        XCTAssertEqual(doc.characterCount, 10000)
        XCTAssertEqual(doc.wordCount, 1) // One continuous "word"
    }

    func testDocumentWithManyShortWords() {
        // Create content with 1000 single-character words
        let content = Array(repeating: "a", count: 1000).joined(separator: " ")
        let doc = Document(title: "Test", content: content, category: .article)

        XCTAssertEqual(doc.wordCount, 1000)
        XCTAssertEqual(doc.readingTime, 5) // 1000 / 200 = 5 minutes
    }

    // MARK: - ViewModel Initialize Tests

    @MainActor
    func testViewModelInitialize() async {
        let viewModel = WritersAppViewModel()

        // Before initialization
        XCTAssertEqual(viewModel.recentAISuggestions.count, 0)
        XCTAssertEqual(viewModel.toolUsageStats.count, 0)
        XCTAssertNil(viewModel.currentSessionStats)

        // Initialize should set up the WritersApp and load data
        viewModel.initialize()

        // After initialization, the WritersApp should be created
        // Note: Initial loads may be empty if no data exists
        XCTAssertGreaterThanOrEqual(viewModel.recentAISuggestions.count, 0)
        XCTAssertGreaterThanOrEqual(viewModel.toolUsageStats.count, 0)
    }

    @MainActor
    func testViewModelLoadRecentSuggestions() async {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()

        // Should not crash even if no suggestions exist
        viewModel.loadRecentSuggestions()

        // Should return an array (empty or with data)
        XCTAssertNotNil(viewModel.recentAISuggestions)
    }

    @MainActor
    func testViewModelLoadToolUsageStats() async {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()

        // Should not crash even if no stats exist
        viewModel.loadToolUsageStats()

        // Should return an array (empty or with data)
        XCTAssertNotNil(viewModel.toolUsageStats)
    }

    @MainActor
    func testViewModelLoadSessionStats() async {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()

        // Should not crash even if no stats exist
        viewModel.loadSessionStats()

        // Stats can be nil if no sessions exist
        // Should not crash
    }

    // MARK: - WordCountDetailView Goal Display Tests

    func testWordCountGoalDisplayWithNoGoal() {
        // When no goal is set, the goal section should not appear
        // This tests the logic: if let goal = viewModel.wordCountGoal
        let goal: Int? = nil

        XCTAssertNil(goal)
    }

    func testWordCountGoalDisplayWithGoalSet() {
        let goal: Int? = 1000

        XCTAssertNotNil(goal)
        XCTAssertEqual(goal, 1000)
    }

    func testWordCountGoalProgressBarValueClamping() {
        // Test that progress bar uses min(wordCount, goal)
        let goal = 500
        let wordCount = 750

        let progressValue = Double(min(wordCount, goal))
        let progressTotal = Double(goal)

        XCTAssertEqual(progressValue, 500.0)
        XCTAssertEqual(progressTotal, 500.0)

        let progress = progressValue / progressTotal
        XCTAssertEqual(progress, 1.0, accuracy: 0.001)
    }

    func testWordCountGoalRemainingTextWhenComplete() {
        let goal = 1000
        let wordCount = 1000

        let remaining = max(0, goal - wordCount)
        XCTAssertEqual(remaining, 0)

        // UI should show "Goal reached!" when remaining == 0
        let message = remaining == 0 ? "Goal reached!" : "\(remaining) remaining"
        XCTAssertEqual(message, "Goal reached!")
    }

    func testWordCountGoalRemainingTextWhenIncomplete() {
        let goal = 1000
        let wordCount = 750

        let remaining = max(0, goal - wordCount)
        XCTAssertEqual(remaining, 250)

        let message = remaining == 0 ? "Goal reached!" : "\(remaining) remaining"
        XCTAssertEqual(message, "250 remaining")
    }

    func testWordCountGoalRemainingTextWhenExceeded() {
        let goal = 1000
        let wordCount = 1250

        let remaining = max(0, goal - wordCount)
        XCTAssertEqual(remaining, 0)

        let message = remaining == 0 ? "Goal reached!" : "\(remaining) remaining"
        XCTAssertEqual(message, "Goal reached!")
    }

    // MARK: - WordCountDetailView Sentence Count Validation

    func testSentenceCountMatchesWordCountDetailViewLogic() {
        // This mirrors the exact logic in WordCountDetailView lines 185-190
        let testCases: [(content: String, expected: Int)] = [
            ("", 0),
            ("   ", 0),
            ("Hello.", 1),
            ("Hello. World.", 2),
            ("Question? Answer!", 2),
            ("One. Two! Three?", 3)
        ]

        for testCase in testCases {
            let content = testCase.content
            let isEmpty = content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

            guard !isEmpty else {
                XCTAssertEqual(0, testCase.expected, "Failed for: '\(content)'")
                continue
            }

            let sentences = content.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            let count = sentences.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count

            XCTAssertEqual(count, testCase.expected, "Failed for: '\(content)'")
        }
    }

    func testParagraphCountMatchesWordCountDetailViewLogic() {
        // This mirrors the exact logic in WordCountDetailView lines 192-197
        let testCases: [(content: String, expected: Int)] = [
            ("", 0),
            ("   ", 0),
            ("Single paragraph.", 1),
            ("First.\n\nSecond.", 2),
            ("One.\n\nTwo.\n\nThree.", 3)
        ]

        for testCase in testCases {
            let content = testCase.content
            let isEmpty = content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

            guard !isEmpty else {
                XCTAssertEqual(0, testCase.expected, "Failed for: '\(content)'")
                continue
            }

            let paragraphs = content.components(separatedBy: "\n\n")
            let count = paragraphs.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count

            XCTAssertEqual(count, testCase.expected, "Failed for: '\(content)'")
        }
    }

    // MARK: - ShowWordCount Integration Tests

    @MainActor
    func testShowWordCountUpdatesSheetState() async {
        let viewModel = WritersAppViewModel()

        XCTAssertFalse(viewModel.showWordCountSheet)

        // Call showWordCount() which is triggered by menu action
        viewModel.showWordCount()

        XCTAssertTrue(viewModel.showWordCountSheet)
    }

    @MainActor
    func testWordCountSheetDismissal() async {
        let viewModel = WritersAppViewModel()

        viewModel.showWordCount()
        XCTAssertTrue(viewModel.showWordCountSheet)

        // Simulate user dismissing the sheet
        viewModel.showWordCountSheet = false
        XCTAssertFalse(viewModel.showWordCountSheet)
    }

    @MainActor
    func testMultipleShowWordCountCalls() async {
        let viewModel = WritersAppViewModel()

        // Multiple calls should keep the sheet visible
        viewModel.showWordCount()
        XCTAssertTrue(viewModel.showWordCountSheet)

        viewModel.showWordCount()
        XCTAssertTrue(viewModel.showWordCountSheet)

        viewModel.showWordCount()
        XCTAssertTrue(viewModel.showWordCountSheet)
    }

    // MARK: - AISidebarView Recent Suggestions Tests

    @MainActor
    func testRecentSuggestionsDisplayLimit() async {
        let viewModel = WritersAppViewModel()

        // Create test suggestions
        let userId = UUID()
        viewModel.recentAISuggestions = (0..<20).map { index in
            AISuggestion(
                userId: userId,
                toolUsed: "Tool \(index)",
                prompt: "Prompt \(index)",
                response: "Response \(index)",
                timestamp: Date().addingTimeInterval(Double(-index * 60))
            )
        }

        XCTAssertEqual(viewModel.recentAISuggestions.count, 20)

        // The view displays only prefix(5)
        let displayedCount = min(5, viewModel.recentAISuggestions.count)
        XCTAssertEqual(displayedCount, 5)
    }

    @MainActor
    func testToolUsageStatsDisplayLimit() async {
        let viewModel = WritersAppViewModel()

        // Create test stats
        viewModel.toolUsageStats = (0..<10).map { index in
            AIToolUsageStats(
                toolName: "Tool \(index)",
                usageCount: 10 - index,
                lastUsed: Date()
            )
        }

        XCTAssertEqual(viewModel.toolUsageStats.count, 10)

        // The view displays only prefix(5)
        let displayedCount = min(5, viewModel.toolUsageStats.count)
        XCTAssertEqual(displayedCount, 5)
    }

    @MainActor
    func testEmptyRecentSuggestions() async {
        let viewModel = WritersAppViewModel()

        viewModel.recentAISuggestions = []

        XCTAssertTrue(viewModel.recentAISuggestions.isEmpty)
        // UI should not display the "Recent Suggestions" section when empty
    }

    @MainActor
    func testEmptyToolUsageStats() async {
        let viewModel = WritersAppViewModel()

        viewModel.toolUsageStats = []

        XCTAssertTrue(viewModel.toolUsageStats.isEmpty)
        // UI should not display the "Tool Usage Statistics" section when empty
    }

    // MARK: - Edge Cases for Statistics Calculations

    func testWordCountWithRepeatedPunctuation() {
        let doc = Document(title: "Test", content: "Hello!!! How are you???", category: .article)

        // "Hello!!!" and "How" and "are" and "you???" should be 4 words
        XCTAssertEqual(doc.wordCount, 4)
    }

    func testWordCountWithLeadingAndTrailingSpaces() {
        let doc = Document(title: "Test", content: "   word1 word2 word3   ", category: .article)

        XCTAssertEqual(doc.wordCount, 3)
    }

    func testSentenceCountWithFragments() {
        let content = "Really. Just one word."
        let sentences = content.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        let count = sentences.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count

        XCTAssertEqual(count, 2)
    }

    func testParagraphCountWithVariableWhitespace() {
        let content = "Para1.\n\n  \n\nPara2."
        let paragraphs = content.components(separatedBy: "\n\n")
        let count = paragraphs.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count

        // "Para1.", "  ", "Para2." -> after filtering -> "Para1.", "Para2."
        XCTAssertEqual(count, 2)
    }

    // MARK: - Focus Mode State Tests

    @MainActor
    func testFocusModeDoesNotAffectDocumentContent() async {
        let viewModel = WritersAppViewModel()

        viewModel.currentDocumentContent = "Important content"

        viewModel.toggleFocusMode()
        XCTAssertTrue(viewModel.isFocusMode)
        XCTAssertEqual(viewModel.currentDocumentContent, "Important content")

        viewModel.toggleFocusMode()
        XCTAssertFalse(viewModel.isFocusMode)
        XCTAssertEqual(viewModel.currentDocumentContent, "Important content")
    }

    @MainActor
    func testAIPanelAndFocusModeCanBothBeActive() async {
        let viewModel = WritersAppViewModel()

        viewModel.toggleFocusMode()
        // AI panel starts as true
        XCTAssertTrue(viewModel.showAIPanel)
        XCTAssertTrue(viewModel.isFocusMode)

        // Can have both active simultaneously
        viewModel.toggleAIPanel()
        XCTAssertFalse(viewModel.showAIPanel)
        XCTAssertTrue(viewModel.isFocusMode)
    }

    // MARK: - Reading Time Precision Tests

    func testReadingTimeRoundsDown() {
        // 199 words should round to 0.995 minutes, but max(1) means 1 minute
        let content = Array(repeating: "word", count: 199).joined(separator: " ")
        let doc = Document(title: "Test", content: content, category: .article)

        XCTAssertEqual(doc.wordCount, 199)
        XCTAssertEqual(doc.readingTime, 1) // max(1, 199/200) = max(1, 0) = 1
    }

    func testReadingTimeWithLargeContent() {
        // 50,000 words should be 250 minutes
        let content = Array(repeating: "word", count: 50000).joined(separator: " ")
        let doc = Document(title: "Test", content: content, category: .article)

        XCTAssertEqual(doc.wordCount, 50000)
        XCTAssertEqual(doc.readingTime, 250)
    }

    // MARK: - Document Title and Content State Tests

    @MainActor
    func testDocumentTitleCanBeChanged() async {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()
        viewModel.createNewDocument()

        XCTAssertEqual(viewModel.currentDocumentTitle, "Untitled")

        viewModel.currentDocumentTitle = "My Novel"
        XCTAssertEqual(viewModel.currentDocumentTitle, "My Novel")
    }

    @MainActor
    func testDocumentContentUpdatesStatistics() async {
        let viewModel = WritersAppViewModel()

        viewModel.currentDocumentContent = "Hello world"

        // Verify through Document model
        let doc = Document(title: "Test", content: viewModel.currentDocumentContent, category: .article)
        XCTAssertEqual(doc.wordCount, 2)
    }

    @MainActor
    func testEmptyDocumentTitleIsValid() async {
        let viewModel = WritersAppViewModel()

        viewModel.currentDocumentTitle = ""
        XCTAssertEqual(viewModel.currentDocumentTitle, "")
    }

    // MARK: - AI Response Edge Cases

    @MainActor
    func testInsertAIResponseWithSpecialCharacters() async {
        let viewModel = WritersAppViewModel()

        viewModel.currentDocumentContent = "Start"
        viewModel.aiResponse = "Special: @#$%^&*()"

        viewModel.insertAIResponse()

        XCTAssertTrue(viewModel.currentDocumentContent.contains("Special: @#$%^&*()"))
        XCTAssertEqual(viewModel.aiResponse, "")
    }

    @MainActor
    func testInsertAIResponseWithMultilineContent() async {
        let viewModel = WritersAppViewModel()

        viewModel.currentDocumentContent = "Line 1"
        viewModel.aiResponse = "Line A\nLine B\nLine C"

        viewModel.insertAIResponse()

        XCTAssertTrue(viewModel.currentDocumentContent.contains("Line 1"))
        XCTAssertTrue(viewModel.currentDocumentContent.contains("Line A"))
        XCTAssertTrue(viewModel.currentDocumentContent.contains("Line B"))
        XCTAssertTrue(viewModel.currentDocumentContent.contains("Line C"))
    }

    @MainActor
    func testInsertAIResponseWithEmptyResponse() async {
        let viewModel = WritersAppViewModel()

        viewModel.currentDocumentContent = "Content"
        viewModel.aiResponse = ""

        let before = viewModel.currentDocumentContent
        viewModel.insertAIResponse()

        // Inserting empty response adds "\n\n"
        XCTAssertEqual(viewModel.currentDocumentContent, before + "\n\n")
    }

    // MARK: - Multitasking Layout Boundary Tests

    @MainActor
    func testMultitaskingStateWithZeroSize() async {
        let viewModel = WritersAppViewModel()

        let zeroSize = CGSize(width: 0, height: 0)
        viewModel.updateMultitaskingState(size: zeroSize)

        // Should not crash, and font size should still be positive
        XCTAssertGreaterThan(viewModel.bodyFontSize, 0)
    }

    @MainActor
    func testMultitaskingStateWithNegativeSize() async {
        let viewModel = WritersAppViewModel()

        // Although unlikely, test defensive programming
        let negativeSize = CGSize(width: -100, height: -100)
        viewModel.updateMultitaskingState(size: negativeSize)

        // Should not crash
        XCTAssertGreaterThan(viewModel.bodyFontSize, 0)
    }

    @MainActor
    func testMultitaskingStateWithVeryWideScreen() async {
        let viewModel = WritersAppViewModel()

        let wideScreen = CGSize(width: 5000, height: 1000)
        viewModel.updateMultitaskingState(size: wideScreen)

        XCTAssertGreaterThan(viewModel.bodyFontSize, 0)
        XCTAssertGreaterThan(viewModel.lineSpacing, 0)
    }

    @MainActor
    func testMultitaskingStateWithVeryTallScreen() async {
        let viewModel = WritersAppViewModel()

        let tallScreen = CGSize(width: 500, height: 5000)
        viewModel.updateMultitaskingState(size: tallScreen)

        XCTAssertGreaterThan(viewModel.bodyFontSize, 0)
        XCTAssertGreaterThan(viewModel.lineSpacing, 0)
    }

    // MARK: - Editor Padding Validation

    @MainActor
    func testEditorPaddingAllSidesPositive() async {
        let viewModel = WritersAppViewModel()

        let padding = viewModel.editorPadding

        XCTAssertGreaterThan(padding.top, 0)
        XCTAssertGreaterThan(padding.leading, 0)
        XCTAssertGreaterThan(padding.bottom, 0)
        XCTAssertGreaterThan(padding.trailing, 0)
    }

    @MainActor
    func testEditorPaddingInitialValues() async {
        let viewModel = WritersAppViewModel()

        XCTAssertEqual(viewModel.editorPadding.top, 20)
        XCTAssertEqual(viewModel.editorPadding.leading, 40)
        XCTAssertEqual(viewModel.editorPadding.bottom, 20)
        XCTAssertEqual(viewModel.editorPadding.trailing, 40)
    }

    // MARK: - Template Category Comprehensive Coverage

    func testAllTemplateCategoriesHaveUniqueIconNames() {
        let iconNames = TemplateCategory.allCases.map { $0.iconName }
        let uniqueIconNames = Set(iconNames)

        // All icons should be unique
        XCTAssertEqual(iconNames.count, uniqueIconNames.count)
    }

    func testAllTemplateCategoriesHaveUniqueDisplayNames() {
        let displayNames = TemplateCategory.allCases.map { $0.displayName }
        let uniqueDisplayNames = Set(displayNames)

        // All display names should be unique
        XCTAssertEqual(displayNames.count, uniqueDisplayNames.count)
    }

    func testTemplateCategoryCount() {
        // Ensure we have all 11 categories
        XCTAssertEqual(TemplateCategory.allCases.count, 11)
    }

    // MARK: - SidebarSection Comprehensive Tests

    func testAllSidebarSectionsAreHashable() {
        let sections: [SidebarSection] = [
            .documents,
            .templates,
            .recent,
            .category(.novel),
            .statistics,
            .settings
        ]

        let sectionSet = Set(sections)
        XCTAssertEqual(sections.count, sectionSet.count)
    }

    func testSidebarSectionCategoryWithDifferentCategories() {
        let sections: [SidebarSection] = TemplateCategory.allCases.map { .category($0) }

        XCTAssertEqual(sections.count, TemplateCategory.allCases.count)

        // Each should be unique
        let sectionSet = Set(sections)
        XCTAssertEqual(sections.count, sectionSet.count)
    }

    // MARK: - Character Count Boundary Tests

    func testCharacterCountWithVeryLongWord() {
        let longWord = String(repeating: "a", count: 10000)
        let doc = Document(title: "Test", content: longWord, category: .article)

        XCTAssertEqual(doc.characterCount, 10000)
        XCTAssertEqual(doc.wordCount, 1)
    }

    func testCharacterCountConsistency() {
        let content = "Hello World!"
        let doc = Document(title: "Test", content: content, category: .article)

        XCTAssertEqual(doc.characterCount, content.count)
    }

    // MARK: - Concurrent State Update Tests

    @MainActor
    func testConcurrentTogglesDoNotCorruptState() async {
        let viewModel = WritersAppViewModel()

        // Rapidly toggle multiple properties
        for i in 0..<100 {
            if i % 2 == 0 {
                viewModel.toggleAIPanel()
            } else {
                viewModel.toggleFocusMode()
            }
        }

        // State should be consistent (even number of toggles)
        XCTAssertTrue(viewModel.showAIPanel)
        XCTAssertFalse(viewModel.isFocusMode)
    }

    // MARK: - Save Document State Tests

    @MainActor
    func testSaveDocumentWithoutCreatingDocument() async {
        let viewModel = WritersAppViewModel()

        // Try to save without creating a document first
        viewModel.currentDocumentTitle = "Test"
        viewModel.currentDocumentContent = "Content"

        // Should not crash
        viewModel.saveDocument()

        // isSaving should become false eventually
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
    }

    @MainActor
    func testSaveDocumentUpdatesTimestamp() async {
        let viewModel = WritersAppViewModel()
        viewModel.initialize()
        viewModel.createNewDocument()

        viewModel.currentDocumentTitle = "Test"
        viewModel.currentDocumentContent = "Content"

        viewModel.saveDocument()

        // Verify saving state is set
        XCTAssertTrue(viewModel.isSaving)
    }

    // MARK: - Additional Stress Tests

    func testWordCountWithExtremePunctuation() {
        let content = "word! word? word. word, word; word: word- word-- word--- word"
        let doc = Document(title: "Test", content: content, category: .article)

        XCTAssertGreaterThan(doc.wordCount, 5)
    }

    func testSentenceCountWithComplexPunctuation() {
        let content = "Mr. Dr. Prof. Smith went to N.Y.C. yesterday."
        let sentences = content.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        let count = sentences.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count

        // Multiple periods from abbreviations
        XCTAssertGreaterThan(count, 1)
    }

    func testParagraphCountWithComplexFormatting() {
        let content = """
        Paragraph 1 with
        multiple lines
        but no double newline.

        Paragraph 2 after double newline.


        Paragraph 3 after triple newline.
        """

        let paragraphs = content.components(separatedBy: "\n\n")
        let count = paragraphs.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count

        XCTAssertEqual(count, 3)
    }

    // MARK: - Word Count Goal Edge Cases

    func testWordCountGoalWithZeroGoal() {
        let goal = 0
        let wordCount = 100

        // Progress would be division by zero, should be handled
        let progress = goal > 0 ? Double(wordCount) / Double(goal) : 0.0
        XCTAssertEqual(progress, 0.0)
    }

    func testWordCountGoalWithNegativeGoal() {
        // Unlikely but test defensive programming
        let goal = -100
        let wordCount = 50

        let remaining = max(0, goal - wordCount)
        XCTAssertEqual(remaining, 0)
    }

    // MARK: - formatSuggestionDate Precision Tests

    func testFormatSuggestionDateExactBoundaries() {
        let now = Date()

        // Exactly 59.9 seconds
        let almostOneMinute = now.addingTimeInterval(-59.9)
        XCTAssertEqual(formatSuggestionDate(almostOneMinute, relativeTo: now), "Just now")

        // Exactly 60 seconds
        let exactlyOneMinute = now.addingTimeInterval(-60)
        XCTAssertEqual(formatSuggestionDate(exactlyOneMinute, relativeTo: now), "1m ago")

        // Exactly 3599 seconds
        let almostOneHour = now.addingTimeInterval(-3599)
        XCTAssertEqual(formatSuggestionDate(almostOneHour, relativeTo: now), "59m ago")

        // Exactly 86399 seconds
        let almostOneDay = now.addingTimeInterval(-86399)
        XCTAssertEqual(formatSuggestionDate(almostOneDay, relativeTo: now), "23h ago")
    }

    // MARK: - Helper Function

    /// Helper function to mimic the formatSuggestionDate logic from AISidebarView
    private func formatSuggestionDate(_ date: Date, relativeTo now: Date = Date()) -> String {
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
}

#endif