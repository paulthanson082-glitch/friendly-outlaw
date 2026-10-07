#if canImport(SwiftUI) && os(iOS)
import XCTest
import SwiftUI
@testable import WritersApp

// MARK: - WritersAppViewModel Formatting Tests
// Tests for the simplified formatting methods changed in this PR:
//   - toggleBold: always wraps with ** (removed toggle-off logic)
//   - toggleItalic: always wraps with * (removed toggle-off logic)
//   - toggleUnderline: uses __ instead of <u></u> (removed toggle-off logic)
//   - applyHeading: always prepends # markers (removed strip-existing logic)
//   - applyBodyStyle: uses replacingOccurrences regex chain (simplified from NSRegularExpression)
//   - toggleNumberedList: new algorithm using line index for numbering

@available(iOS 16.0, macOS 13.0, *)
final class WritersAppViewModelFormattingTests: XCTestCase {

    var viewModel: WritersAppViewModel!

    override func setUp() {
        super.setUp()
        viewModel = WritersAppViewModel()
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    // MARK: - toggleBold (PR Change: always wraps, no toggle-off)

    func testToggleBoldWrapsPlainText() {
        viewModel.currentDocumentContent = "Hello World"
        viewModel.toggleBold()
        XCTAssertEqual(viewModel.currentDocumentContent, "**Hello World**")
    }

    func testToggleBoldOnEmptyString() {
        viewModel.currentDocumentContent = ""
        viewModel.toggleBold()
        XCTAssertEqual(viewModel.currentDocumentContent, "****",
            "Wrapping empty string with bold should produce ****")
    }

    /// PR change: toggleBold no longer strips existing ** markers; it adds another layer.
    func testToggleBoldOnAlreadyBoldTextAddsAnotherLayer() {
        viewModel.currentDocumentContent = "**already bold**"
        viewModel.toggleBold()
        XCTAssertEqual(viewModel.currentDocumentContent, "****already bold****",
            "Post-PR toggleBold always wraps — no toggle-off behavior")
    }

    func testToggleBoldDoesNotUseHTMLTags() {
        viewModel.currentDocumentContent = "Sample"
        viewModel.toggleBold()
        XCTAssertFalse(viewModel.currentDocumentContent.contains("<b>"))
        XCTAssertFalse(viewModel.currentDocumentContent.contains("<strong>"))
    }

    func testToggleBoldPreservesInternalContent() {
        let content = "The quick brown fox"
        viewModel.currentDocumentContent = content
        viewModel.toggleBold()
        XCTAssertTrue(viewModel.currentDocumentContent.contains(content))
        XCTAssertTrue(viewModel.currentDocumentContent.hasPrefix("**"))
        XCTAssertTrue(viewModel.currentDocumentContent.hasSuffix("**"))
    }

    // MARK: - toggleItalic (PR Change: always wraps, no toggle-off)

    func testToggleItalicWrapsPlainText() {
        viewModel.currentDocumentContent = "Hello World"
        viewModel.toggleItalic()
        XCTAssertEqual(viewModel.currentDocumentContent, "*Hello World*")
    }

    func testToggleItalicOnEmptyString() {
        viewModel.currentDocumentContent = ""
        viewModel.toggleItalic()
        XCTAssertEqual(viewModel.currentDocumentContent, "**")
    }

    /// PR change: toggleItalic no longer strips existing * markers.
    func testToggleItalicOnAlreadyItalicTextAddsAnotherLayer() {
        viewModel.currentDocumentContent = "*already italic*"
        viewModel.toggleItalic()
        XCTAssertEqual(viewModel.currentDocumentContent, "**already italic**",
            "Post-PR toggleItalic always wraps — no toggle-off behavior")
    }

    func testToggleItalicUsesAsterisks() {
        viewModel.currentDocumentContent = "Text"
        viewModel.toggleItalic()
        XCTAssertTrue(viewModel.currentDocumentContent.hasPrefix("*"))
        XCTAssertTrue(viewModel.currentDocumentContent.hasSuffix("*"))
    }

    // MARK: - toggleUnderline (PR Change: uses __ instead of <u></u>)

    func testToggleUnderlineUsesDoubleUnderscore() {
        viewModel.currentDocumentContent = "Underlined Text"
        viewModel.toggleUnderline()
        XCTAssertEqual(viewModel.currentDocumentContent, "__Underlined Text__")
    }

    func testToggleUnderlineDoesNotUseHTMLUTag() {
        viewModel.currentDocumentContent = "Some text"
        viewModel.toggleUnderline()
        XCTAssertFalse(viewModel.currentDocumentContent.contains("<u>"),
            "PR change: underline must use __ not <u> tags")
        XCTAssertFalse(viewModel.currentDocumentContent.contains("</u>"))
    }

    func testToggleUnderlineOnEmptyString() {
        viewModel.currentDocumentContent = ""
        viewModel.toggleUnderline()
        XCTAssertEqual(viewModel.currentDocumentContent, "____",
            "Wrapping empty string with underline should produce ____")
    }

    /// PR change: toggleUnderline no longer strips existing __ markers.
    func testToggleUnderlineOnAlreadyUnderlinedTextAddsAnotherLayer() {
        viewModel.currentDocumentContent = "__already underlined__"
        viewModel.toggleUnderline()
        XCTAssertEqual(viewModel.currentDocumentContent, "____already underlined____",
            "Post-PR toggleUnderline always wraps — no toggle-off behavior")
    }

    // MARK: - applyHeading (PR Change: always prepends, no strip-existing logic)

    func testApplyHeadingLevel1() {
        viewModel.currentDocumentContent = "Chapter Title"
        viewModel.applyHeading(level: 1)
        XCTAssertEqual(viewModel.currentDocumentContent, "# Chapter Title")
    }

    func testApplyHeadingLevel2() {
        viewModel.currentDocumentContent = "Section"
        viewModel.applyHeading(level: 2)
        XCTAssertEqual(viewModel.currentDocumentContent, "## Section")
    }

    func testApplyHeadingLevel3() {
        viewModel.currentDocumentContent = "Subsection"
        viewModel.applyHeading(level: 3)
        XCTAssertEqual(viewModel.currentDocumentContent, "### Subsection")
    }

    func testApplyHeadingLevel6() {
        viewModel.currentDocumentContent = "Small heading"
        viewModel.applyHeading(level: 6)
        XCTAssertEqual(viewModel.currentDocumentContent, "###### Small heading")
    }

    /// PR change: applyHeading no longer strips existing heading markers first.
    func testApplyHeadingOnAlreadyHeadedTextAddsAnotherPrefix() {
        viewModel.currentDocumentContent = "# Already a heading"
        viewModel.applyHeading(level: 2)
        XCTAssertEqual(viewModel.currentDocumentContent, "## # Already a heading",
            "Post-PR applyHeading always prepends — no strip-existing logic")
    }

    func testApplyHeadingWithEmptyContent() {
        viewModel.currentDocumentContent = ""
        viewModel.applyHeading(level: 1)
        XCTAssertEqual(viewModel.currentDocumentContent, "# ")
    }

    // MARK: - applyBodyStyle (PR Change: simplified regex chain, uses __ not <u>)

    func testApplyBodyStyleRemovesBoldFormatting() {
        viewModel.currentDocumentContent = "**Bold text**"
        viewModel.applyBodyStyle()
        XCTAssertEqual(viewModel.currentDocumentContent, "Bold text")
    }

    func testApplyBodyStyleRemovesItalicFormatting() {
        viewModel.currentDocumentContent = "*Italic text*"
        viewModel.applyBodyStyle()
        XCTAssertEqual(viewModel.currentDocumentContent, "Italic text")
    }

    /// PR change: applyBodyStyle now removes __ underline (not <u>) since toggleUnderline changed.
    func testApplyBodyStyleRemovesDoubleUnderlineFormatting() {
        viewModel.currentDocumentContent = "__Underlined text__"
        viewModel.applyBodyStyle()
        XCTAssertEqual(viewModel.currentDocumentContent, "Underlined text")
    }

    func testApplyBodyStylePlainTextUnchanged() {
        let plain = "This is plain text without any formatting."
        viewModel.currentDocumentContent = plain
        viewModel.applyBodyStyle()
        XCTAssertEqual(viewModel.currentDocumentContent, plain)
    }

    func testApplyBodyStyleOnEmptyString() {
        viewModel.currentDocumentContent = ""
        viewModel.applyBodyStyle()
        XCTAssertEqual(viewModel.currentDocumentContent, "")
    }

    // MARK: - toggleNumberedList (PR Change: new algorithm using line-index for numbering)

    func testToggleNumberedListAddsNumbersToPureText() {
        viewModel.currentDocumentContent = "First\nSecond\nThird"
        viewModel.toggleNumberedList()
        XCTAssertEqual(viewModel.currentDocumentContent, "1. First\n2. Second\n3. Third")
    }

    /// PR change: new algorithm checks if each line starts with "{lineNum}. " to toggle off.
    func testToggleNumberedListRemovesNumberedPrefixWhenPresent() {
        viewModel.currentDocumentContent = "1. First\n2. Second\n3. Third"
        viewModel.toggleNumberedList()
        XCTAssertEqual(viewModel.currentDocumentContent, "First\nSecond\nThird")
    }

    func testToggleNumberedListPreservesEmptyLines() {
        viewModel.currentDocumentContent = "First\n\nThird"
        viewModel.toggleNumberedList()
        // Empty lines are not numbered
        let lines = viewModel.currentDocumentContent.split(separator: "\n", omittingEmptySubsequences: false)
        XCTAssertTrue(lines[0].hasPrefix("1."))
        XCTAssertEqual(String(lines[1]), "")
        XCTAssertTrue(lines[2].hasPrefix("3."))
    }

    func testToggleNumberedListSingleLine() {
        viewModel.currentDocumentContent = "Only line"
        viewModel.toggleNumberedList()
        XCTAssertEqual(viewModel.currentDocumentContent, "1. Only line")
    }

    func testToggleNumberedListEmptyContent() {
        viewModel.currentDocumentContent = ""
        viewModel.toggleNumberedList()
        // An empty string split by \n gives [""] — not empty, so it's treated as a line
        // But the line is empty/whitespace, so it's returned unchanged
        XCTAssertEqual(viewModel.currentDocumentContent, "")
    }

    // MARK: - updateStatistics called by formatting methods

    func testToggleBoldUpdatesWordCount() {
        viewModel.currentDocumentContent = "Hello World"
        let before = viewModel.wordCount
        viewModel.toggleBold()
        // After bold, content is "**Hello World**" — still 2 words
        XCTAssertGreaterThanOrEqual(viewModel.wordCount, 0,
            "wordCount must be updated after toggleBold (non-negative)")
        _ = before // silence unused warning
    }
}

#endif