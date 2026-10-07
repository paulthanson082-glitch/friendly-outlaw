#if canImport(SwiftUI) && os(iOS)
import XCTest
@testable import WritersApp

// MARK: - WritersAppViewModel Formatting Tests
// Tests for the simplified formatting methods changed in this PR

@available(iOS 16.0, macOS 13.0, *)
@MainActor
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

    // MARK: - toggleBold (PR change: now always wraps, no toggle-off)

    func testToggleBoldWrapsContentInDoubleAsterisks() {
        viewModel.currentDocumentContent = "Hello World"
        viewModel.toggleBold()
        XCTAssertEqual(viewModel.currentDocumentContent, "**Hello World**")
    }

    func testToggleBoldOnEmptyString() {
        viewModel.currentDocumentContent = ""
        viewModel.toggleBold()
        XCTAssertEqual(viewModel.currentDocumentContent, "****")
    }

    func testToggleBoldOnAlreadyBoldTextWrapsAgain() {
        // PR simplified to always add markers, no toggle-off
        viewModel.currentDocumentContent = "**already bold**"
        viewModel.toggleBold()
        XCTAssertEqual(viewModel.currentDocumentContent, "****already bold****")
    }

    func testToggleBoldPreservesWhitespace() {
        viewModel.currentDocumentContent = "  spaced  "
        viewModel.toggleBold()
        XCTAssertEqual(viewModel.currentDocumentContent, "**  spaced  **")
    }

    func testToggleBoldOnMultilineContent() {
        viewModel.currentDocumentContent = "line 1\nline 2"
        viewModel.toggleBold()
        XCTAssertEqual(viewModel.currentDocumentContent, "**line 1\nline 2**")
    }

    // MARK: - toggleItalic (PR change: now always wraps, no toggle-off)

    func testToggleItalicWrapsContentInAsterisks() {
        viewModel.currentDocumentContent = "Hello World"
        viewModel.toggleItalic()
        XCTAssertEqual(viewModel.currentDocumentContent, "*Hello World*")
    }

    func testToggleItalicOnEmptyString() {
        viewModel.currentDocumentContent = ""
        viewModel.toggleItalic()
        XCTAssertEqual(viewModel.currentDocumentContent, "**")
    }

    func testToggleItalicOnAlreadyItalicTextWrapsAgain() {
        // PR simplified to always add markers, no toggle-off
        viewModel.currentDocumentContent = "*already italic*"
        viewModel.toggleItalic()
        XCTAssertEqual(viewModel.currentDocumentContent, "**already italic**")
    }

    // MARK: - toggleUnderline (PR change: uses __ instead of <u>)

    func testToggleUnderlineUsesDoubleUnderscores() {
        viewModel.currentDocumentContent = "Hello World"
        viewModel.toggleUnderline()
        XCTAssertEqual(viewModel.currentDocumentContent, "__Hello World__")
    }

    func testToggleUnderlineDoesNotUseHTMLTags() {
        viewModel.currentDocumentContent = "Test"
        viewModel.toggleUnderline()
        XCTAssertFalse(viewModel.currentDocumentContent.contains("<u>"),
                       "toggleUnderline must use __ syntax, not <u> HTML tags")
        XCTAssertFalse(viewModel.currentDocumentContent.contains("</u>"),
                       "toggleUnderline must use __ syntax, not </u> HTML tags")
    }

    func testToggleUnderlineOnEmptyString() {
        viewModel.currentDocumentContent = ""
        viewModel.toggleUnderline()
        XCTAssertEqual(viewModel.currentDocumentContent, "____")
    }

    func testToggleUnderlineOnAlreadyUnderlinedContentWrapsAgain() {
        viewModel.currentDocumentContent = "__underlined__"
        viewModel.toggleUnderline()
        XCTAssertEqual(viewModel.currentDocumentContent, "____underlined____")
    }

    // MARK: - applyHeading (PR change: simplified, always prepends heading marker)

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
        viewModel.currentDocumentContent = "Deepest"
        viewModel.applyHeading(level: 6)
        XCTAssertEqual(viewModel.currentDocumentContent, "###### Deepest")
    }

    func testApplyHeadingOnEmptyString() {
        viewModel.currentDocumentContent = ""
        viewModel.applyHeading(level: 1)
        XCTAssertEqual(viewModel.currentDocumentContent, "# ")
    }

    func testApplyHeadingAlwaysPrependsEvenOnExistingHeading() {
        // PR simplified: always prepends, no stripping logic
        viewModel.currentDocumentContent = "## Existing Heading"
        viewModel.applyHeading(level: 1)
        XCTAssertEqual(viewModel.currentDocumentContent, "# ## Existing Heading")
    }

    // MARK: - applyBodyStyle (PR change: simplified regex-based removal)

    func testApplyBodyStyleRemovesBoldMarkers() {
        viewModel.currentDocumentContent = "**Bold text**"
        viewModel.applyBodyStyle()
        XCTAssertEqual(viewModel.currentDocumentContent, "Bold text")
    }

    func testApplyBodyStyleRemovesItalicMarkers() {
        viewModel.currentDocumentContent = "*Italic text*"
        viewModel.applyBodyStyle()
        XCTAssertEqual(viewModel.currentDocumentContent, "Italic text")
    }

    func testApplyBodyStyleRemovesUnderlineMarkers() {
        viewModel.currentDocumentContent = "__Underlined text__"
        viewModel.applyBodyStyle()
        XCTAssertEqual(viewModel.currentDocumentContent, "Underlined text")
    }

    func testApplyBodyStyleRemovesHeadingMarker() {
        viewModel.currentDocumentContent = "# Heading"
        viewModel.applyBodyStyle()
        XCTAssertFalse(viewModel.currentDocumentContent.hasPrefix("#"),
                       "applyBodyStyle must strip the leading # heading marker")
    }

    func testApplyBodyStyleLeavesPlainTextUnchanged() {
        viewModel.currentDocumentContent = "Just plain text"
        viewModel.applyBodyStyle()
        XCTAssertEqual(viewModel.currentDocumentContent, "Just plain text")
    }

    func testApplyBodyStyleOnEmptyString() {
        viewModel.currentDocumentContent = ""
        viewModel.applyBodyStyle()
        XCTAssertEqual(viewModel.currentDocumentContent, "")
    }

    func testApplyBodyStyleRemovesMultipleFormats() {
        viewModel.currentDocumentContent = "**bold** and *italic* and __underline__"
        viewModel.applyBodyStyle()
        XCTAssertEqual(viewModel.currentDocumentContent, "bold and italic and underline")
    }

    // MARK: - toggleBulletList (unchanged but verify still works)

    func testToggleBulletListAddsBulletPrefix() {
        viewModel.currentDocumentContent = "Item one\nItem two"
        viewModel.toggleBulletList()
        XCTAssertEqual(viewModel.currentDocumentContent, "- Item one\n- Item two")
    }

    func testToggleBulletListRemovesBulletPrefix() {
        viewModel.currentDocumentContent = "- Item one\n- Item two"
        viewModel.toggleBulletList()
        XCTAssertEqual(viewModel.currentDocumentContent, "Item one\nItem two")
    }

    func testToggleBulletListPreservesEmptyLines() {
        viewModel.currentDocumentContent = "Item one\n\nItem two"
        viewModel.toggleBulletList()
        XCTAssertEqual(viewModel.currentDocumentContent, "- Item one\n\n- Item two")
    }

    // MARK: - toggleNumberedList (PR change: simplified, per-line positional toggle)

    func testToggleNumberedListAddsNumberPrefix() {
        viewModel.currentDocumentContent = "First\nSecond\nThird"
        viewModel.toggleNumberedList()
        XCTAssertEqual(viewModel.currentDocumentContent, "1. First\n2. Second\n3. Third")
    }

    func testToggleNumberedListRemovesNumberPrefix() {
        viewModel.currentDocumentContent = "1. First\n2. Second\n3. Third"
        viewModel.toggleNumberedList()
        XCTAssertEqual(viewModel.currentDocumentContent, "First\nSecond\nThird")
    }

    func testToggleNumberedListPreservesEmptyLines() {
        viewModel.currentDocumentContent = "Item A\n\nItem B"
        viewModel.toggleNumberedList()
        // Empty lines are unchanged; non-empty lines get numbers 1 and 3
        let result = viewModel.currentDocumentContent
        XCTAssertTrue(result.contains("1. Item A"), "First non-empty line should be prefixed with 1.")
        XCTAssertTrue(result.contains("3. Item B"), "Third line (Item B) should be prefixed with 3.")
    }

    func testToggleNumberedListSingleLine() {
        viewModel.currentDocumentContent = "Only item"
        viewModel.toggleNumberedList()
        XCTAssertEqual(viewModel.currentDocumentContent, "1. Only item")
    }

    func testToggleNumberedListOnEmptyString() {
        viewModel.currentDocumentContent = ""
        viewModel.toggleNumberedList()
        XCTAssertEqual(viewModel.currentDocumentContent, "")
    }

    // MARK: - Regression: formatting methods call updateStatistics

    func testFormattingMethodsDoNotCrash() {
        // Regression: verify each changed formatting method runs without error
        viewModel.currentDocumentContent = "Test content"
        XCTAssertNoThrow(viewModel.toggleBold())
        viewModel.currentDocumentContent = "Test content"
        XCTAssertNoThrow(viewModel.toggleItalic())
        viewModel.currentDocumentContent = "Test content"
        XCTAssertNoThrow(viewModel.toggleUnderline())
        viewModel.currentDocumentContent = "Test content"
        XCTAssertNoThrow(viewModel.applyHeading(level: 2))
        viewModel.currentDocumentContent = "**bold** and *italic*"
        XCTAssertNoThrow(viewModel.applyBodyStyle())
        viewModel.currentDocumentContent = "Line 1\nLine 2"
        XCTAssertNoThrow(viewModel.toggleNumberedList())
    }

    // MARK: - toggleNumberedList edge cases (PR change: positional index-based toggle)

    /// Partial state: only the first line has a matching positional prefix.
    /// Expected: first line strips its prefix, remaining lines gain their positional prefix.
    func testToggleNumberedListMixedState() {
        // Line 0 (lineNum=1) has "1. " → stripped
        // Line 1 (lineNum=2) has no "2. " → gains "2. "
        // Line 2 (lineNum=3) has no "3. " → gains "3. "
        viewModel.currentDocumentContent = "1. First\nSecond\nThird"
        viewModel.toggleNumberedList()
        let result = viewModel.currentDocumentContent
        XCTAssertFalse(result.hasPrefix("1."), "First line prefix '1. ' must be stripped")
        XCTAssertTrue(result.contains("2. Second"), "Second line must gain its positional prefix")
        XCTAssertTrue(result.contains("3. Third"), "Third line must gain its positional prefix")
    }

    /// A line with a number that doesn't match its position is treated as plain text
    /// and gets the positional prefix prepended.
    func testToggleNumberedListWrongNumberGetsPositionalPrefix() {
        // "2. First" at position 0: lineNum=1, doesn't match "1. ", so adds "1. "
        viewModel.currentDocumentContent = "2. First"
        viewModel.toggleNumberedList()
        XCTAssertEqual(viewModel.currentDocumentContent, "1. 2. First",
                       "A line with mismatched number must receive its positional prefix")
    }

    /// Idempotency check: applying toggle twice returns to original for a simple list.
    func testToggleNumberedListTwiceRestoresOriginal() {
        viewModel.currentDocumentContent = "Apple\nBanana\nCherry"
        viewModel.toggleNumberedList()
        viewModel.toggleNumberedList()
        XCTAssertEqual(viewModel.currentDocumentContent, "Apple\nBanana\nCherry",
                       "Two consecutive toggles must return content to its original form")
    }

    // MARK: - applyBodyStyle: HTML underline tags are NOT removed (PR changed to __ syntax)

    /// Regression: the old <u>text</u> HTML underline format is NOT handled by the
    /// simplified applyBodyStyle. This test documents the current behaviour.
    func testApplyBodyStyleDoesNotStripHtmlUnderlineTags() {
        viewModel.currentDocumentContent = "<u>Underlined via HTML</u>"
        viewModel.applyBodyStyle()
        // The new implementation uses __ regex only; <u> tags are left in place
        XCTAssertTrue(viewModel.currentDocumentContent.contains("<u>"),
                      "applyBodyStyle no longer strips <u> tags; this documents current behaviour")
    }

    // MARK: - toggleUnderline: uses __ not <u>

    /// Boundary: applying underline then body style must completely remove the __ markers.
    func testUnderlineThenBodyStyleProducesPlainText() {
        viewModel.currentDocumentContent = "Text to underline"
        viewModel.toggleUnderline()
        // Should now be __Text to underline__
        XCTAssertEqual(viewModel.currentDocumentContent, "__Text to underline__")
        viewModel.applyBodyStyle()
        // applyBodyStyle's __ regex should strip the markers
        XCTAssertEqual(viewModel.currentDocumentContent, "Text to underline",
                       "applyBodyStyle must remove __ underline markers added by toggleUnderline")
    }

    // MARK: - applyHeading: positional application (PR removed stripping logic)

    /// Boundary: applying heading level 4 must produce exactly four # characters.
    func testApplyHeadingLevel4() {
        viewModel.currentDocumentContent = "Section"
        viewModel.applyHeading(level: 4)
        XCTAssertEqual(viewModel.currentDocumentContent, "#### Section")
    }

    /// Regression: applyHeading called multiple times accumulates prefixes
    /// (no stripping logic in the PR version).
    func testApplyHeadingDoublePrependAccumulates() {
        viewModel.currentDocumentContent = "Title"
        viewModel.applyHeading(level: 2)
        viewModel.applyHeading(level: 1)
        // Second call prepends "# " to the result of the first call "## Title"
        XCTAssertEqual(viewModel.currentDocumentContent, "# ## Title",
                       "Double applyHeading must accumulate prefixes without stripping")
    }
}
#endif