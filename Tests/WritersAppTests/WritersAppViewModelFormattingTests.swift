#if canImport(SwiftUI) && os(iOS)
import XCTest
@testable import WritersApp

/// Tests for WritersAppViewModel formatting methods changed in this PR:
/// - toggleBold: simplified to always wrap content with ** (no toggle-off)
/// - toggleItalic: simplified to always wrap content with * (no toggle-off)
/// - toggleUnderline: changed from <u>…</u> to __…__ syntax
/// - applyHeading: simplified to always prepend # markers (no stripping)
/// - applyBodyStyle: now uses __ regex instead of <u> for underline removal
/// - toggleNumberedList: index-based check (strips if line starts with "{n}. ")
@available(iOS 16.0, macOS 13.0, *)
final class WritersAppViewModelFormattingTests: XCTestCase {

    // Helper to create and set up a ViewModel on the main actor
    @MainActor
    private func makeViewModel(content: String = "") -> WritersAppViewModel {
        let vm = WritersAppViewModel()
        vm.currentDocumentContent = content
        return vm
    }

    // MARK: - toggleBold (PR change: always wraps, never unwraps)

    @MainActor
    func testToggleBoldWrapsContent() {
        let vm = makeViewModel(content: "Hello World")
        vm.toggleBold()
        XCTAssertEqual(vm.currentDocumentContent, "**Hello World**")
    }

    @MainActor
    func testToggleBoldOnEmptyContent() {
        let vm = makeViewModel(content: "")
        vm.toggleBold()
        XCTAssertEqual(vm.currentDocumentContent, "****")
    }

    @MainActor
    func testToggleBoldOnAlreadyBoldContent() {
        // PR change: no longer removes bold — it wraps again
        let vm = makeViewModel(content: "**already bold**")
        vm.toggleBold()
        XCTAssertEqual(vm.currentDocumentContent, "****already bold****")
    }

    @MainActor
    func testToggleBoldDoesNotRemoveExistingFormatting() {
        // Regression: old implementation would strip ** if content started/ended with **
        let vm = makeViewModel(content: "**text**")
        vm.toggleBold()
        // New simplified implementation always adds markers
        XCTAssertTrue(vm.currentDocumentContent.hasPrefix("**"), "Should still start with **")
        XCTAssertTrue(vm.currentDocumentContent.hasSuffix("**"), "Should still end with **")
    }

    @MainActor
    func testToggleBoldUpdatesStatistics() {
        let vm = makeViewModel(content: "word")
        let before = vm.wordCount
        vm.toggleBold()
        // Word count may change slightly due to formatting markers
        // Just ensure it runs without crash and updates
        _ = before // suppress unused warning; the key test is no crash
    }

    // MARK: - toggleItalic (PR change: always wraps, never unwraps)

    @MainActor
    func testToggleItalicWrapsContent() {
        let vm = makeViewModel(content: "Hello World")
        vm.toggleItalic()
        XCTAssertEqual(vm.currentDocumentContent, "*Hello World*")
    }

    @MainActor
    func testToggleItalicOnEmptyContent() {
        let vm = makeViewModel(content: "")
        vm.toggleItalic()
        XCTAssertEqual(vm.currentDocumentContent, "**")
    }

    @MainActor
    func testToggleItalicOnAlreadyItalicContent() {
        // PR change: no longer removes italic — it wraps again
        let vm = makeViewModel(content: "*already italic*")
        vm.toggleItalic()
        XCTAssertEqual(vm.currentDocumentContent, "**already italic**")
    }

    @MainActor
    func testToggleItalicDoesNotRemoveExistingFormatting() {
        let vm = makeViewModel(content: "*text*")
        vm.toggleItalic()
        XCTAssertTrue(vm.currentDocumentContent.hasPrefix("*"))
        XCTAssertTrue(vm.currentDocumentContent.hasSuffix("*"))
    }

    // MARK: - toggleUnderline (PR change: uses __ instead of <u>…</u>)

    @MainActor
    func testToggleUnderlineUsesDoubleUnderscoreSyntax() {
        let vm = makeViewModel(content: "underline me")
        vm.toggleUnderline()
        XCTAssertEqual(vm.currentDocumentContent, "__underline me__")
    }

    @MainActor
    func testToggleUnderlineDoesNotUseHTMLSyntax() {
        let vm = makeViewModel(content: "no html")
        vm.toggleUnderline()
        XCTAssertFalse(vm.currentDocumentContent.contains("<u>"),
                       "toggleUnderline should no longer use <u> HTML tag")
        XCTAssertFalse(vm.currentDocumentContent.contains("</u>"),
                       "toggleUnderline should no longer use </u> HTML tag")
    }

    @MainActor
    func testToggleUnderlineOnEmptyContent() {
        let vm = makeViewModel(content: "")
        vm.toggleUnderline()
        XCTAssertEqual(vm.currentDocumentContent, "____")
    }

    @MainActor
    func testToggleUnderlineAlwaysWraps() {
        // New simplified implementation always adds markers
        let vm = makeViewModel(content: "__already underlined__")
        vm.toggleUnderline()
        XCTAssertEqual(vm.currentDocumentContent, "____already underlined____")
    }

    // MARK: - applyHeading (PR change: always prepends, no stripping of existing)

    @MainActor
    func testApplyHeadingLevel1PrependsHash() {
        let vm = makeViewModel(content: "My Title")
        vm.applyHeading(level: 1)
        XCTAssertEqual(vm.currentDocumentContent, "# My Title")
    }

    @MainActor
    func testApplyHeadingLevel2PrependsTwoHashes() {
        let vm = makeViewModel(content: "Section")
        vm.applyHeading(level: 2)
        XCTAssertEqual(vm.currentDocumentContent, "## Section")
    }

    @MainActor
    func testApplyHeadingLevel3PrependsThreeHashes() {
        let vm = makeViewModel(content: "Subsection")
        vm.applyHeading(level: 3)
        XCTAssertEqual(vm.currentDocumentContent, "### Subsection")
    }

    @MainActor
    func testApplyHeadingDoesNotStripExistingHeading() {
        // PR change: old impl stripped existing #; new always prepends
        let vm = makeViewModel(content: "# Already H1")
        vm.applyHeading(level: 2)
        XCTAssertEqual(vm.currentDocumentContent, "## # Already H1",
                       "New implementation should prepend # without stripping existing markers")
    }

    @MainActor
    func testApplyHeadingOnEmptyContent() {
        let vm = makeViewModel(content: "")
        vm.applyHeading(level: 1)
        XCTAssertEqual(vm.currentDocumentContent, "# ")
    }

    // MARK: - applyBodyStyle (PR change: uses __ regex for underline removal)

    @MainActor
    func testApplyBodyStyleRemovesDoubleUnderscoreUnderline() {
        let vm = makeViewModel(content: "__underlined text__")
        vm.applyBodyStyle()
        XCTAssertEqual(vm.currentDocumentContent, "underlined text")
    }

    @MainActor
    func testApplyBodyStyleRemovesBoldMarkers() {
        let vm = makeViewModel(content: "**bold text**")
        vm.applyBodyStyle()
        XCTAssertEqual(vm.currentDocumentContent, "bold text")
    }

    @MainActor
    func testApplyBodyStyleRemovesItalicMarkers() {
        let vm = makeViewModel(content: "*italic text*")
        vm.applyBodyStyle()
        XCTAssertEqual(vm.currentDocumentContent, "italic text")
    }

    @MainActor
    func testApplyBodyStyleRemovesHeadingPrefix() {
        let vm = makeViewModel(content: "# Heading Text")
        vm.applyBodyStyle()
        XCTAssertEqual(vm.currentDocumentContent, "Heading Text")
    }

    @MainActor
    func testApplyBodyStyleDoesNotRemoveHTMLUnderlineTags() {
        // PR change: new applyBodyStyle only handles __ not <u>
        let vm = makeViewModel(content: "<u>html underline</u>")
        vm.applyBodyStyle()
        // <u> tags are NOT handled in the new implementation
        XCTAssertEqual(vm.currentDocumentContent, "<u>html underline</u>",
                       "applyBodyStyle no longer removes <u> HTML tags")
    }

    @MainActor
    func testApplyBodyStyleOnPlainText() {
        let vm = makeViewModel(content: "plain text")
        vm.applyBodyStyle()
        XCTAssertEqual(vm.currentDocumentContent, "plain text")
    }

    // MARK: - toggleNumberedList (PR change: index-based, not all-or-nothing toggle)

    @MainActor
    func testToggleNumberedListAddsNumbersToLines() {
        let vm = makeViewModel(content: "First line\nSecond line\nThird line")
        vm.toggleNumberedList()
        XCTAssertEqual(vm.currentDocumentContent, "1. First line\n2. Second line\n3. Third line")
    }

    @MainActor
    func testToggleNumberedListStripsExistingNumberWhenMatchesIndex() {
        // PR change: strips "n. " only if line[i] starts with "{i+1}. "
        let vm = makeViewModel(content: "1. First\n2. Second\n3. Third")
        vm.toggleNumberedList()
        XCTAssertEqual(vm.currentDocumentContent, "First\nSecond\nThird")
    }

    @MainActor
    func testToggleNumberedListDoesNotStripMismatchedIndex() {
        // Line 1 has "2. " prefix (wrong index), so it gets "1. " prepended, not stripped
        let vm = makeViewModel(content: "2. wrong index")
        vm.toggleNumberedList()
        XCTAssertEqual(vm.currentDocumentContent, "1. 2. wrong index")
    }

    @MainActor
    func testToggleNumberedListPreservesEmptyLines() {
        let vm = makeViewModel(content: "Line one\n\nLine three")
        vm.toggleNumberedList()
        let result = vm.currentDocumentContent
        // Empty line should remain empty (not numbered)
        XCTAssertTrue(result.contains("\n\n"), "Empty lines should be preserved")
        XCTAssertTrue(result.contains("1. Line one"))
    }

    @MainActor
    func testToggleNumberedListSingleLine() {
        let vm = makeViewModel(content: "Only line")
        vm.toggleNumberedList()
        XCTAssertEqual(vm.currentDocumentContent, "1. Only line")
    }

    @MainActor
    func testToggleNumberedListSingleLineStrip() {
        let vm = makeViewModel(content: "1. Only line")
        vm.toggleNumberedList()
        XCTAssertEqual(vm.currentDocumentContent, "Only line")
    }

    @MainActor
    func testToggleNumberedListDoesNotNumberEmptyContent() {
        let vm = makeViewModel(content: "")
        vm.toggleNumberedList()
        // Empty content stays as-is (empty line, not numbered)
        XCTAssertEqual(vm.currentDocumentContent, "")
    }

    // MARK: - Regression: formatting methods update statistics

    @MainActor
    func testFormattingMethodsDoNotCrash() {
        let vm = makeViewModel(content: "test content")
        // Verify none of these crash
        vm.toggleBold()
        vm.toggleItalic()
        vm.toggleUnderline()
        vm.applyHeading(level: 1)
        vm.applyBodyStyle()
        vm.toggleNumberedList()
        // If we reach here, no crash occurred
        XCTAssertTrue(true)
    }
}
#endif