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
}
#endif