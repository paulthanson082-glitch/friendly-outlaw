import XCTest
@testable import WritersApp

// MARK: - String+Extensions Tests

final class StringExtensionsTests: XCTestCase {

    // MARK: - removingPlaceholders

    func testRemovingPlaceholdersRemovesSinglePlaceholder() {
        let result = "Hello {{name}}!".removingPlaceholders()
        XCTAssertEqual(result, "Hello !")
    }

    func testRemovingPlaceholdersRemovesMultiplePlaceholders() {
        let result = "{{title}} by {{author}}".removingPlaceholders()
        XCTAssertEqual(result, " by ")
    }

    func testRemovingPlaceholdersLeavesNonPlaceholderContentIntact() {
        let result = "No placeholders here.".removingPlaceholders()
        XCTAssertEqual(result, "No placeholders here.")
    }

    func testRemovingPlaceholdersHandlesAdjacentPlaceholders() {
        let result = "{{first}}{{last}}".removingPlaceholders()
        XCTAssertEqual(result, "")
    }

    func testRemovingPlaceholdersHandlesUnderscoreKeys() {
        let result = "{{scene_heading}} action {{character_2}}".removingPlaceholders()
        XCTAssertEqual(result, " action ")
    }

    func testRemovingPlaceholdersHandlesEmptyString() {
        XCTAssertEqual("".removingPlaceholders(), "")
    }

    func testRemovingPlaceholdersDoesNotRemoveSingleBraces() {
        let result = "{not a placeholder}".removingPlaceholders()
        XCTAssertEqual(result, "{not a placeholder}")
    }

    // MARK: - extractPlaceholders

    func testExtractPlaceholdersSingleKey() {
        let keys = "Hello {{name}}!".extractPlaceholders()
        XCTAssertEqual(keys, ["name"])
    }

    func testExtractPlaceholdersMultipleKeys() {
        let keys = "{{title}} by {{author}} published in {{year}}".extractPlaceholders()
        XCTAssertEqual(keys, ["title", "author", "year"])
    }

    func testExtractPlaceholdersReturnsEmptyForNoPlaceholders() {
        let keys = "No placeholders here.".extractPlaceholders()
        XCTAssertTrue(keys.isEmpty)
    }

    func testExtractPlaceholdersHandlesUnderscoreKeys() {
        let keys = "{{scene_heading}} {{character_state}}".extractPlaceholders()
        XCTAssertEqual(keys, ["scene_heading", "character_state"])
    }

    func testExtractPlaceholdersHandlesAdjacentPlaceholders() {
        let keys = "{{first}}{{last}}".extractPlaceholders()
        XCTAssertEqual(keys, ["first", "last"])
    }

    func testExtractPlaceholdersIgnoresSingleBraces() {
        let keys = "{not_a_key}".extractPlaceholders()
        XCTAssertTrue(keys.isEmpty)
    }

    func testExtractPlaceholdersHandlesEmptyString() {
        XCTAssertTrue("".extractPlaceholders().isEmpty)
    }

    func testExtractPlaceholdersDuplicateKeys() {
        let keys = "{{name}} and {{name}} again".extractPlaceholders()
        XCTAssertEqual(keys, ["name", "name"])
    }

    // MARK: - sanitizedForFilename

    func testSanitizedForFilenameAllowsAlphanumeric() {
        XCTAssertEqual("MyDocument123".sanitizedForFilename, "MyDocument123")
    }

    func testSanitizedForFilenameAllowsDots() {
        XCTAssertEqual("file.txt".sanitizedForFilename, "file.txt")
    }

    func testSanitizedForFilenameAllowsDashes() {
        XCTAssertEqual("my-file".sanitizedForFilename, "my-file")
    }

    func testSanitizedForFilenameAllowsUnderscores() {
        XCTAssertEqual("my_file".sanitizedForFilename, "my_file")
    }

    func testSanitizedForFilenameReplacesSpaces() {
        let result = "My Document".sanitizedForFilename
        XCTAssertFalse(result.contains(" "))
        XCTAssertTrue(result.contains("_"))
    }

    func testSanitizedForFilenameReplacesSlashes() {
        let result = "path/to/file".sanitizedForFilename
        XCTAssertFalse(result.contains("/"))
    }

    func testSanitizedForFilenameReplacesColons() {
        let result = "file:name".sanitizedForFilename
        XCTAssertFalse(result.contains(":"))
    }

    func testSanitizedForFilenameStripsTrailingNonAlphanumeric() {
        let result = "filename---".sanitizedForFilename
        XCTAssertFalse(result.hasSuffix("-"))
    }

    func testSanitizedForFilenameReturnsUnknownForEmptyResult() {
        // All invalid characters result in "unknown"
        let result = "!!!".sanitizedForFilename
        XCTAssertEqual(result, "unknown")
    }

    func testSanitizedForFilenameHandlesEmptyString() {
        XCTAssertEqual("".sanitizedForFilename, "unknown")
    }

    func testSanitizedForFilenameMixedContent() {
        let result = "My Novel: Chapter 1".sanitizedForFilename
        XCTAssertFalse(result.contains(":"))
        XCTAssertFalse(result.contains(" "))
        XCTAssertTrue(result.contains("My"))
        XCTAssertTrue(result.contains("Novel"))
    }

    // MARK: - paragraphCount

    func testParagraphCountSingleParagraph() {
        XCTAssertEqual("Hello World.".paragraphCount, 1)
    }

    func testParagraphCountMultipleParagraphs() {
        let text = "First paragraph.\n\nSecond paragraph.\n\nThird paragraph."
        XCTAssertEqual(text.paragraphCount, 3)
    }

    func testParagraphCountIgnoresEmptyParagraphs() {
        let text = "First.\n\n\n\nSecond."
        XCTAssertEqual(text.paragraphCount, 2)
    }

    func testParagraphCountEmptyStringReturnsZero() {
        XCTAssertEqual("".paragraphCount, 0)
    }

    func testParagraphCountWhitespaceOnlyStringReturnsZero() {
        XCTAssertEqual("   \n\n   ".paragraphCount, 0)
    }
}
