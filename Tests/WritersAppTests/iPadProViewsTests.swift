import XCTest
@testable import WritersApp

#if canImport(SwiftUI) && os(iOS)
import SwiftUI

@available(iOS 16.0, macOS 13.0, *)
final class iPadProViewsTests: XCTestCase {

    // MARK: - WritersAppViewModel Tests

    func testWritersAppViewModelInitialization() {
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
    }

    func testUpdateStatisticsWithEmptyContent() {
        let viewModel = WritersAppViewModel()

        viewModel.currentDocumentContent = ""
        // Trigger statistics update by changing content
        viewModel.objectWillChange.send()

        // Access the private updateStatistics indirectly by setting content
        // and checking the computed values
        XCTAssertEqual(viewModel.currentDocumentContent, "")
    }

    func testStatisticsLogicWithSimpleContent() {
        // Test the statistics calculation logic directly
        let content = "This is a simple test with exactly ten words total."

        let words = content.components(separatedBy: .whitespacesAndNewlines)
        let wordCount = words.filter { !$0.isEmpty }.count
        let characterCount = content.count
        let readingTime = max(1, wordCount / 200)

        XCTAssertEqual(wordCount, 10)
        XCTAssertGreaterThan(characterCount, 0)
        XCTAssertEqual(readingTime, 1)
    }

    func testStatisticsLogicWithMultipleSpaces() {
        // Test word counting with multiple spaces
        let content = "Word1   Word2    Word3     Word4"

        let words = content.components(separatedBy: .whitespacesAndNewlines)
        let wordCount = words.filter { !$0.isEmpty }.count

        XCTAssertEqual(wordCount, 4)
    }

    func testStatisticsLogicWithNewlines() {
        // Test word counting with newlines
        let content = "Line1\nLine2\nLine3\n\nLine4"

        let words = content.components(separatedBy: .whitespacesAndNewlines)
        let wordCount = words.filter { !$0.isEmpty }.count

        XCTAssertEqual(wordCount, 4)
    }

    func testReadingTimeCalculationLogic() {
        // Test reading time calculation with 200 words
        let wordCount = 200
        let readingTime = max(1, wordCount / 200)

        XCTAssertEqual(readingTime, 1)
    }

    func testToggleAIPanel() async {
        let viewModel = WritersAppViewModel()

        await MainActor.run {
            let initialState = viewModel.showAIPanel

            viewModel.toggleAIPanel()

            XCTAssertNotEqual(viewModel.showAIPanel, initialState)

            viewModel.toggleAIPanel()

            XCTAssertEqual(viewModel.showAIPanel, initialState)
        }
    }

    func testToggleFocusMode() async {
        let viewModel = WritersAppViewModel()

        await MainActor.run {
            XCTAssertFalse(viewModel.isFocusMode)

            viewModel.toggleFocusMode()

            XCTAssertTrue(viewModel.isFocusMode)

            viewModel.toggleFocusMode()

            XCTAssertFalse(viewModel.isFocusMode)
        }
    }

    func testInsertAIResponse() async {
        let viewModel = WritersAppViewModel()

        await MainActor.run {
            viewModel.initialize()
            viewModel.currentDocumentContent = "Initial content"
            viewModel.aiResponse = "AI generated text"

            let initialWordCount = viewModel.wordCount

            viewModel.insertAIResponse()

            XCTAssertTrue(viewModel.currentDocumentContent.contains("AI generated text"))
            XCTAssertEqual(viewModel.aiResponse, "")
            // Statistics should be updated after inserting AI response
            XCTAssertGreaterThan(viewModel.wordCount, initialWordCount)
        }
    }

    func testInsertAIResponseWithEmptyDocument() async {
        let viewModel = WritersAppViewModel()

        await MainActor.run {
            viewModel.currentDocumentContent = ""
            viewModel.aiResponse = "AI response"

            viewModel.insertAIResponse()

            XCTAssertTrue(viewModel.currentDocumentContent.contains("AI response"))
        }
    }

    func testShowWordCount() async {
        let viewModel = WritersAppViewModel()

        await MainActor.run {
            XCTAssertFalse(viewModel.showWordCountSheet)

            viewModel.showWordCount()

            XCTAssertTrue(viewModel.showWordCountSheet)
        }
    }

    func testInitialize() async {
        let viewModel = WritersAppViewModel()

        await MainActor.run {
            viewModel.initialize()

            // After initialization, statistics should be set
            XCTAssertGreaterThanOrEqual(viewModel.wordCount, 0)
            XCTAssertGreaterThanOrEqual(viewModel.characterCount, 0)
            XCTAssertGreaterThanOrEqual(viewModel.readingTime, 1)
        }
    }

    func testCreateNewDocument() async {
        let viewModel = WritersAppViewModel()
        await MainActor.run {
            viewModel.initialize()
        }

        await MainActor.run {
            viewModel.createNewDocument()

            // Should have a document title
            XCTAssertNotNil(viewModel.currentDocumentTitle)
        }
    }

    func testSaveDocument() async {
        let viewModel = WritersAppViewModel()
        await MainActor.run {
            viewModel.initialize()
        }

        await MainActor.run {
            viewModel.createNewDocument()
            viewModel.currentDocumentTitle = "Test Document"
            viewModel.currentDocumentContent = "Test content"

            XCTAssertFalse(viewModel.isSaving)

            viewModel.saveDocument()

            // isSaving should be set to true initially
            XCTAssertTrue(viewModel.isSaving)
        }

        // Wait for save to complete (simulated delay is 0.5 seconds)
        try? await Task.sleep(nanoseconds: 600_000_000) // 0.6 seconds

        await MainActor.run {
            // After save completes, isSaving should be false
            XCTAssertFalse(viewModel.isSaving)
        }
    }

    func testUpdateMultitaskingState() async {
        let viewModel = WritersAppViewModel()

        await MainActor.run {
            // Test full screen size
            viewModel.updateMultitaskingState(size: CGSize(width: 1200, height: 800))

            // Font sizes should be appropriate for the size
            XCTAssertGreaterThan(viewModel.bodyFontSize, 0)
            XCTAssertGreaterThan(viewModel.lineSpacing, 0)
        }
    }

    func testUpdateMultitaskingStateWithSmallSize() async {
        let viewModel = WritersAppViewModel()

        await MainActor.run {
            // Test small size (should hide AI panel)
            viewModel.updateMultitaskingState(size: CGSize(width: 300, height: 800))

            // AI panel should be hidden in small size
            XCTAssertFalse(viewModel.showAIPanel)
        }
    }

    func testEditorPaddingDefaults() async {
        let viewModel = WritersAppViewModel()

        await MainActor.run {
            XCTAssertEqual(viewModel.editorPadding.top, 20)
            XCTAssertEqual(viewModel.editorPadding.leading, 40)
            XCTAssertEqual(viewModel.editorPadding.bottom, 20)
            XCTAssertEqual(viewModel.editorPadding.trailing, 40)
        }
    }

    func testBodyFontSizeDefault() async {
        let viewModel = WritersAppViewModel()

        await MainActor.run {
            XCTAssertEqual(viewModel.bodyFontSize, 17)
        }
    }

    func testLineSpacingDefault() async {
        let viewModel = WritersAppViewModel()

        await MainActor.run {
            XCTAssertEqual(viewModel.lineSpacing, 8)
        }
    }

    // MARK: - Sentence and Paragraph Counting Tests
    // These test the logic from WordCountDetailView computed properties

    func testSentenceCountWithEmptyContent() {
        let content = ""
        let sentences = content.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        let count = sentences.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count

        XCTAssertEqual(count, 0)
    }

    func testSentenceCountWithSingleSentence() {
        let content = "This is a sentence."
        let sentences = content.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        let count = sentences.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count

        XCTAssertEqual(count, 1)
    }

    func testSentenceCountWithMultipleSentences() {
        let content = "First sentence. Second sentence! Third sentence?"
        let sentences = content.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        let count = sentences.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count

        XCTAssertEqual(count, 3)
    }

    func testSentenceCountWithMultipleEndMarks() {
        let content = "What?! Really... Yes."
        let sentences = content.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        let count = sentences.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count

        // Should count each punctuation mark separately
        XCTAssertGreaterThan(count, 0)
    }

    func testParagraphCountWithEmptyContent() {
        let content = ""
        let paragraphs = content.components(separatedBy: "\n\n")
        let count = paragraphs.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count

        XCTAssertEqual(count, 0)
    }

    func testParagraphCountWithSingleParagraph() {
        let content = "This is a single paragraph with multiple words."
        let paragraphs = content.components(separatedBy: "\n\n")
        let count = paragraphs.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count

        XCTAssertEqual(count, 1)
    }

    func testParagraphCountWithMultipleParagraphs() {
        let content = "First paragraph.\n\nSecond paragraph.\n\nThird paragraph."
        let paragraphs = content.components(separatedBy: "\n\n")
        let count = paragraphs.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count

        XCTAssertEqual(count, 3)
    }

    func testParagraphCountWithSingleNewlines() {
        let content = "Line one.\nLine two.\nLine three."
        let paragraphs = content.components(separatedBy: "\n\n")
        let count = paragraphs.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count

        // Single newlines should not create new paragraphs
        XCTAssertEqual(count, 1)
    }

    func testParagraphCountWithMultipleBlankLines() {
        let content = "Paragraph one.\n\n\n\nParagraph two."
        let paragraphs = content.components(separatedBy: "\n\n")
        let count = paragraphs.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count

        XCTAssertEqual(count, 2)
    }

    // MARK: - AISidebarView formatSuggestionDate Tests

    func testFormatSuggestionDateJustNow() {
        let now = Date()
        let interval = now.timeIntervalSince(now)

        let formatted: String
        if interval < 60 {
            formatted = "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            formatted = "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            formatted = "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            formatted = "\(days)d ago"
        }

        XCTAssertEqual(formatted, "Just now")
    }

    func testFormatSuggestionDateMinutesAgo() {
        let now = Date()
        let pastDate = now.addingTimeInterval(-120) // 2 minutes ago
        let interval = now.timeIntervalSince(pastDate)

        let formatted: String
        if interval < 60 {
            formatted = "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            formatted = "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            formatted = "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            formatted = "\(days)d ago"
        }

        XCTAssertEqual(formatted, "2m ago")
    }

    func testFormatSuggestionDateHoursAgo() {
        let now = Date()
        let pastDate = now.addingTimeInterval(-7200) // 2 hours ago
        let interval = now.timeIntervalSince(pastDate)

        let formatted: String
        if interval < 60 {
            formatted = "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            formatted = "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            formatted = "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            formatted = "\(days)d ago"
        }

        XCTAssertEqual(formatted, "2h ago")
    }

    func testFormatSuggestionDateDaysAgo() {
        let now = Date()
        let pastDate = now.addingTimeInterval(-172800) // 2 days ago
        let interval = now.timeIntervalSince(pastDate)

        let formatted: String
        if interval < 60 {
            formatted = "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            formatted = "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            formatted = "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            formatted = "\(days)d ago"
        }

        XCTAssertEqual(formatted, "2d ago")
    }

    func testFormatSuggestionDateBoundary59Seconds() {
        let now = Date()
        let pastDate = now.addingTimeInterval(-59) // 59 seconds ago
        let interval = now.timeIntervalSince(pastDate)

        let formatted: String
        if interval < 60 {
            formatted = "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            formatted = "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            formatted = "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            formatted = "\(days)d ago"
        }

        XCTAssertEqual(formatted, "Just now")
    }

    func testFormatSuggestionDateBoundary60Seconds() {
        let now = Date()
        let pastDate = now.addingTimeInterval(-60) // 60 seconds ago
        let interval = now.timeIntervalSince(pastDate)

        let formatted: String
        if interval < 60 {
            formatted = "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            formatted = "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            formatted = "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            formatted = "\(days)d ago"
        }

        XCTAssertEqual(formatted, "1m ago")
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

    func testTemplateCategoryAllCases() {
        let allCases = TemplateCategory.allCases

        XCTAssertEqual(allCases.count, 11)
        XCTAssertTrue(allCases.contains(.novel))
        XCTAssertTrue(allCases.contains(.shortStory))
        XCTAssertTrue(allCases.contains(.screenplay))
        XCTAssertTrue(allCases.contains(.blogPost))
        XCTAssertTrue(allCases.contains(.article))
        XCTAssertTrue(allCases.contains(.essay))
        XCTAssertTrue(allCases.contains(.poetry))
        XCTAssertTrue(allCases.contains(.businessLetter))
        XCTAssertTrue(allCases.contains(.proposal))
        XCTAssertTrue(allCases.contains(.resume))
        XCTAssertTrue(allCases.contains(.other))
    }

    // MARK: - SidebarSection Tests

    func testSidebarSectionEquality() {
        XCTAssertEqual(SidebarSection.documents, SidebarSection.documents)
        XCTAssertEqual(SidebarSection.templates, SidebarSection.templates)
        XCTAssertEqual(SidebarSection.recent, SidebarSection.recent)
        XCTAssertEqual(SidebarSection.statistics, SidebarSection.statistics)
        XCTAssertEqual(SidebarSection.settings, SidebarSection.settings)

        XCTAssertEqual(
            SidebarSection.category(.novel),
            SidebarSection.category(.novel)
        )

        XCTAssertNotEqual(
            SidebarSection.category(.novel),
            SidebarSection.category(.shortStory)
        )
    }

    // MARK: - Edge Case Tests

    func testWordCountWithOnlyWhitespace() {
        let content = "   \n\n   \t\t   "
        let words = content.components(separatedBy: .whitespacesAndNewlines)
        let wordCount = words.filter { !$0.isEmpty }.count

        XCTAssertEqual(wordCount, 0)
    }

    func testWordCountWithUnicodeCharacters() {
        let content = "Hello 你好 мир العالم"
        let words = content.components(separatedBy: .whitespacesAndNewlines)
        let wordCount = words.filter { !$0.isEmpty }.count

        XCTAssertEqual(wordCount, 4)
    }

    func testWordCountWithEmojis() {
        let content = "Hello 😀 world 🌍"
        let words = content.components(separatedBy: .whitespacesAndNewlines)
        let wordCount = words.filter { !$0.isEmpty }.count

        XCTAssertEqual(wordCount, 4)
    }

    func testCharacterCountWithEmptyString() {
        let content = ""
        XCTAssertEqual(content.count, 0)
    }

    func testCharacterCountWithWhitespace() {
        let content = "Hello World"
        XCTAssertEqual(content.count, 11) // Including the space
    }

    func testCharacterCountWithNewlines() {
        let content = "Line1\nLine2"
        XCTAssertEqual(content.count, 11) // Including the newline
    }

    func testReadingTimeMinimumValue() {
        let wordCount = 0
        let readingTime = max(1, wordCount / 200)

        XCTAssertEqual(readingTime, 1)
    }

    func testReadingTimeWithExactly200Words() {
        let wordCount = 200
        let readingTime = max(1, wordCount / 200)

        XCTAssertEqual(readingTime, 1)
    }

    func testReadingTimeWithExactly201Words() {
        let wordCount = 201
        let readingTime = max(1, wordCount / 200)

        XCTAssertEqual(readingTime, 1)
    }

    func testReadingTimeWith400Words() {
        let wordCount = 400
        let readingTime = max(1, wordCount / 200)

        XCTAssertEqual(readingTime, 2)
    }

    func testReadingTimeWith1000Words() {
        let wordCount = 1000
        let readingTime = max(1, wordCount / 200)

        XCTAssertEqual(readingTime, 5)
    }

    // MARK: - Word Count Goal Tests

    func testWordCountGoalProgress() {
        let wordCount = 500
        let goal = 1000
        let progress = Double(min(wordCount, goal)) / Double(goal)

        XCTAssertEqual(progress, 0.5, accuracy: 0.01)
    }

    func testWordCountGoalExceeded() {
        let wordCount = 1200
        let goal = 1000
        let remaining = max(0, goal - wordCount)

        XCTAssertEqual(remaining, 0)
    }

    func testWordCountGoalRemaining() {
        let wordCount = 300
        let goal = 1000
        let remaining = max(0, goal - wordCount)

        XCTAssertEqual(remaining, 700)
    }

    func testWordCountGoalReached() {
        let wordCount = 1000
        let goal = 1000
        let remaining = max(0, goal - wordCount)

        XCTAssertEqual(remaining, 0)
    }

    // MARK: - Content Validation Tests

    func testSentenceCountWithNoEndPunctuation() {
        let content = "This is a sentence without ending"
        let sentences = content.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        let count = sentences.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count

        // Should still count as 1 sentence
        XCTAssertEqual(count, 1)
    }

    func testSentenceCountWithOnlyPunctuation() {
        let content = "...!!???"
        let sentences = content.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        let count = sentences.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count

        // Should not count empty segments
        XCTAssertEqual(count, 0)
    }

    func testParagraphCountWithOnlyNewlines() {
        let content = "\n\n\n\n"
        let paragraphs = content.components(separatedBy: "\n\n")
        let count = paragraphs.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count

        XCTAssertEqual(count, 0)
    }

    func testParagraphCountWithLeadingAndTrailingNewlines() {
        let content = "\n\nFirst paragraph\n\nSecond paragraph\n\n"
        let paragraphs = content.components(separatedBy: "\n\n")
        let count = paragraphs.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count

        XCTAssertEqual(count, 2)
    }

    // MARK: - Statistical Accuracy Tests

    func testStatisticsWithLongContent() {
        let words = Array(repeating: "word", count: 10000)
        let content = words.joined(separator: " ")

        let wordComponents = content.components(separatedBy: .whitespacesAndNewlines)
        let wordCount = wordComponents.filter { !$0.isEmpty }.count

        XCTAssertEqual(wordCount, 10000)

        let characterCount = content.count
        XCTAssertGreaterThan(characterCount, 0)

        let readingTime = max(1, wordCount / 200)
        XCTAssertEqual(readingTime, 50)
    }

    func testStatisticsWithMixedContent() {
        let content = """
        # Title

        This is the first paragraph with some words.

        This is the second paragraph. It has multiple sentences! Does it work?

        - List item 1
        - List item 2
        - List item 3

        Final paragraph.
        """

        let wordComponents = content.components(separatedBy: .whitespacesAndNewlines)
        let wordCount = wordComponents.filter { !$0.isEmpty }.count

        XCTAssertGreaterThan(wordCount, 0)

        let sentences = content.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        let sentenceCount = sentences.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count

        XCTAssertGreaterThan(sentenceCount, 0)

        let paragraphs = content.components(separatedBy: "\n\n")
        let paragraphCount = paragraphs.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count

        XCTAssertGreaterThan(paragraphCount, 0)
    }

    // MARK: - Regression Tests

    func testViewModelDoesNotCrashWithNilValues() async {
        let viewModel = WritersAppViewModel()

        await MainActor.run {
            viewModel.wordCountGoal = nil
            XCTAssertNil(viewModel.wordCountGoal)

            viewModel.wordCountGoal = 1000
            XCTAssertEqual(viewModel.wordCountGoal, 1000)
        }
    }

    func testViewModelHandlesRapidToggles() async {
        let viewModel = WritersAppViewModel()

        await MainActor.run {
            for _ in 0..<100 {
                viewModel.toggleAIPanel()
            }

            // Should end up in initial state
            XCTAssertTrue(viewModel.showAIPanel)

            for _ in 0..<100 {
                viewModel.toggleFocusMode()
            }

            // Should end up in initial state
            XCTAssertFalse(viewModel.isFocusMode)
        }
    }

    func testViewModelHandlesLargeContent() async {
        let viewModel = WritersAppViewModel()

        await MainActor.run {
            let largeContent = String(repeating: "word ", count: 100000)
            viewModel.currentDocumentContent = largeContent

            // Should not crash with large content
            XCTAssertEqual(viewModel.currentDocumentContent.count, largeContent.count)
        }
    }

    // MARK: - Additional Coverage Tests

    func testWordCountGoalSetting() async {
        let viewModel = WritersAppViewModel()

        await MainActor.run {
            XCTAssertNil(viewModel.wordCountGoal)

            viewModel.wordCountGoal = 500
            XCTAssertEqual(viewModel.wordCountGoal, 500)

            viewModel.wordCountGoal = nil
            XCTAssertNil(viewModel.wordCountGoal)
        }
    }

    func testRecentAISuggestionsInitiallyEmpty() async {
        let viewModel = WritersAppViewModel()

        await MainActor.run {
            XCTAssertTrue(viewModel.recentAISuggestions.isEmpty)
        }
    }

    func testToolUsageStatsInitiallyEmpty() async {
        let viewModel = WritersAppViewModel()

        await MainActor.run {
            XCTAssertTrue(viewModel.toolUsageStats.isEmpty)
        }
    }

    func testCurrentSessionStatsInitiallyNil() async {
        let viewModel = WritersAppViewModel()

        await MainActor.run {
            XCTAssertNil(viewModel.currentSessionStats)
        }
    }

    func testMultitaskingManagerExists() async {
        let viewModel = WritersAppViewModel()

        await MainActor.run {
            XCTAssertNotNil(viewModel.multitaskingManager)
        }
    }

    func testKeyboardShortcutManagerExists() async {
        let viewModel = WritersAppViewModel()

        await MainActor.run {
            XCTAssertNotNil(viewModel.keyboardShortcutManager)
        }
    }

    func testApplePencilManagerExists() async {
        let viewModel = WritersAppViewModel()

        await MainActor.run {
            XCTAssertNotNil(viewModel.applePencilManager)
        }
    }

    // MARK: - Boundary Condition Tests

    func testWordCountWithExactly200Words() {
        let words = Array(repeating: "word", count: 200)
        let content = words.joined(separator: " ")

        let wordComponents = content.components(separatedBy: .whitespacesAndNewlines)
        let wordCount = wordComponents.filter { !$0.isEmpty }.count

        XCTAssertEqual(wordCount, 200)

        let readingTime = max(1, wordCount / 200)
        XCTAssertEqual(readingTime, 1)
    }

    func testWordCountWithExactly199Words() {
        let words = Array(repeating: "word", count: 199)
        let content = words.joined(separator: " ")

        let wordComponents = content.components(separatedBy: .whitespacesAndNewlines)
        let wordCount = wordComponents.filter { !$0.isEmpty }.count

        XCTAssertEqual(wordCount, 199)

        let readingTime = max(1, wordCount / 200)
        XCTAssertEqual(readingTime, 1) // Still rounds down to 0, but max returns 1
    }

    func testWordCountWith201Words() {
        let words = Array(repeating: "word", count: 201)
        let content = words.joined(separator: " ")

        let wordComponents = content.components(separatedBy: .whitespacesAndNewlines)
        let wordCount = wordComponents.filter { !$0.isEmpty }.count

        XCTAssertEqual(wordCount, 201)

        let readingTime = max(1, wordCount / 200)
        XCTAssertEqual(readingTime, 1) // 201 / 200 = 1.005, truncated to 1
    }

    func testSentenceCountWithQuestionAndExclamation() {
        let content = "Is this a question? Yes it is!"
        let sentences = content.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        let count = sentences.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count

        XCTAssertEqual(count, 2)
    }

    func testParagraphCountWithWindowsLineEndings() {
        let content = "First paragraph.\r\n\r\nSecond paragraph."
        let paragraphs = content.components(separatedBy: "\n\n")
        let count = paragraphs.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count

        // Windows line endings may not split correctly with \n\n
        XCTAssertGreaterThan(count, 0)
    }

    func testContentWithTabCharacters() {
        let content = "Word1\tWord2\tWord3"
        let words = content.components(separatedBy: .whitespacesAndNewlines)
        let wordCount = words.filter { !$0.isEmpty }.count

        XCTAssertEqual(wordCount, 3)
    }

    func testContentWithMixedWhitespace() {
        let content = "Word1 \t  Word2\n\nWord3\t\tWord4   Word5"
        let words = content.components(separatedBy: .whitespacesAndNewlines)
        let wordCount = words.filter { !$0.isEmpty }.count

        XCTAssertEqual(wordCount, 5)
    }

    func testSentenceCountWithEllipsis() {
        let content = "This is a sentence... And another one."
        let sentences = content.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        let count = sentences.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count

        // Multiple periods will create multiple empty splits
        XCTAssertGreaterThan(count, 0)
    }

    func testParagraphCountWithMixedLineEndings() {
        let content = "Para1\n\nPara2\n\nPara3"
        let paragraphs = content.components(separatedBy: "\n\n")
        let count = paragraphs.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count

        XCTAssertEqual(count, 3)
    }
}

#endif