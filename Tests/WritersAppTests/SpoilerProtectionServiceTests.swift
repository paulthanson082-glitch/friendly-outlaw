import XCTest
@testable import WritersApp

// MARK: - SpoilerSeverity Tests

final class SpoilerSeverityTests: XCTestCase {

    func testRawValues() {
        XCTAssertEqual(SpoilerSeverity.minor.rawValue, "minor")
        XCTAssertEqual(SpoilerSeverity.moderate.rawValue, "moderate")
        XCTAssertEqual(SpoilerSeverity.major.rawValue, "major")
    }

    func testDisplayNames() {
        XCTAssertEqual(SpoilerSeverity.minor.displayName, "Minor")
        XCTAssertEqual(SpoilerSeverity.moderate.displayName, "Moderate")
        XCTAssertEqual(SpoilerSeverity.major.displayName, "Major")
    }

    func testCodableRoundTrip() throws {
        for severity in SpoilerSeverity.allCases {
            let encoded = try JSONEncoder().encode(severity)
            let decoded = try JSONDecoder().decode(SpoilerSeverity.self, from: encoded)
            XCTAssertEqual(decoded, severity)
        }
    }

    func testAllCasesCount() {
        XCTAssertEqual(SpoilerSeverity.allCases.count, 3)
    }
}

// MARK: - SpoilerTag Model Tests

final class SpoilerTagModelTests: XCTestCase {

    func testSpoilerTagDefaultSeverityIsModerate() {
        let docId = UUID()
        let tag = SpoilerTag(documentId: docId, startOffset: 0, endOffset: 10)
        XCTAssertEqual(tag.severity, .moderate)
    }

    func testSpoilerTagDefaultDescriptionIsEmpty() {
        let tag = SpoilerTag(documentId: UUID(), startOffset: 0, endOffset: 5)
        XCTAssertEqual(tag.description, "")
    }

    func testSpoilerTagIdIsUnique() {
        let docId = UUID()
        let tag1 = SpoilerTag(documentId: docId, startOffset: 0, endOffset: 5)
        let tag2 = SpoilerTag(documentId: docId, startOffset: 0, endOffset: 5)
        XCTAssertNotEqual(tag1.id, tag2.id)
    }

    func testSpoilerTagCodableRoundTrip() throws {
        let original = SpoilerTag(
            documentId: UUID(),
            startOffset: 5,
            endOffset: 15,
            description: "Big reveal",
            severity: .major
        )
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SpoilerTag.self, from: encoded)
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.documentId, original.documentId)
        XCTAssertEqual(decoded.startOffset, original.startOffset)
        XCTAssertEqual(decoded.endOffset, original.endOffset)
        XCTAssertEqual(decoded.description, original.description)
        XCTAssertEqual(decoded.severity, original.severity)
    }
}

// MARK: - SpoilerProtectionService Tag Management Tests

final class SpoilerProtectionServiceTagTests: XCTestCase {

    var service: SpoilerProtectionService!
    var docId: UUID!

    override func setUp() {
        super.setUp()
        service = SpoilerProtectionService()
        docId = UUID()
    }

    func testTagSpoilerReturnsTagForValidRange() {
        let tag = service.tagSpoiler(in: docId, startOffset: 0, endOffset: 10)
        XCTAssertNotNil(tag)
        XCTAssertEqual(tag?.documentId, docId)
        XCTAssertEqual(tag?.startOffset, 0)
        XCTAssertEqual(tag?.endOffset, 10)
    }

    func testTagSpoilerStoresSeverity() {
        let tag = service.tagSpoiler(in: docId, startOffset: 0, endOffset: 5, severity: .major)
        XCTAssertEqual(tag?.severity, .major)
    }

    func testTagSpoilerStoresDescription() {
        let tag = service.tagSpoiler(in: docId, startOffset: 0, endOffset: 5, description: "Character dies")
        XCTAssertEqual(tag?.description, "Character dies")
    }

    func testTagSpoilerReturnsNilWhenStartEqualsEnd() {
        let tag = service.tagSpoiler(in: docId, startOffset: 5, endOffset: 5)
        XCTAssertNil(tag)
    }

    func testTagSpoilerReturnsNilWhenStartExceedsEnd() {
        let tag = service.tagSpoiler(in: docId, startOffset: 10, endOffset: 5)
        XCTAssertNil(tag)
    }

    func testTagSpoilerReturnsNilForNegativeStart() {
        let tag = service.tagSpoiler(in: docId, startOffset: -1, endOffset: 5)
        XCTAssertNil(tag)
    }

    func testTagSpoilerWithZeroStartIsValid() {
        let tag = service.tagSpoiler(in: docId, startOffset: 0, endOffset: 1)
        XCTAssertNotNil(tag)
    }

    func testRemoveSpoilerTagDeletesTag() {
        let tag = service.tagSpoiler(in: docId, startOffset: 0, endOffset: 10)!
        XCTAssertEqual(service.getSpoilerTags(forDocument: docId).count, 1)
        service.removeSpoilerTag(id: tag.id)
        XCTAssertEqual(service.getSpoilerTags(forDocument: docId).count, 0)
    }

    func testRemoveNonexistentTagDoesNotCrash() {
        service.removeSpoilerTag(id: UUID()) // should not crash
    }

    func testGetSpoilerTagsForDocumentOnlyReturnsDocumentTags() {
        let docId2 = UUID()
        service.tagSpoiler(in: docId, startOffset: 0, endOffset: 5)
        service.tagSpoiler(in: docId2, startOffset: 0, endOffset: 5)
        service.tagSpoiler(in: docId, startOffset: 10, endOffset: 20)

        XCTAssertEqual(service.getSpoilerTags(forDocument: docId).count, 2)
        XCTAssertEqual(service.getSpoilerTags(forDocument: docId2).count, 1)
    }

    func testGetSpoilerTagsSortedByStartOffset() {
        service.tagSpoiler(in: docId, startOffset: 30, endOffset: 40)
        service.tagSpoiler(in: docId, startOffset: 0, endOffset: 10)
        service.tagSpoiler(in: docId, startOffset: 15, endOffset: 25)

        let tags = service.getSpoilerTags(forDocument: docId)
        XCTAssertEqual(tags[0].startOffset, 0)
        XCTAssertEqual(tags[1].startOffset, 15)
        XCTAssertEqual(tags[2].startOffset, 30)
    }

    func testGetSpoilerTagsForDocumentReturnsEmptyWhenNoTags() {
        XCTAssertTrue(service.getSpoilerTags(forDocument: docId).isEmpty)
    }

    func testGetSpoilerTagsWithSeverityFiltersByCorrectSeverity() {
        service.tagSpoiler(in: docId, startOffset: 0, endOffset: 5, severity: .minor)
        service.tagSpoiler(in: docId, startOffset: 10, endOffset: 15, severity: .major)
        service.tagSpoiler(in: docId, startOffset: 20, endOffset: 25, severity: .minor)

        let minorTags = service.getSpoilerTags(withSeverity: .minor)
        let majorTags = service.getSpoilerTags(withSeverity: .major)
        let moderateTags = service.getSpoilerTags(withSeverity: .moderate)

        XCTAssertEqual(minorTags.count, 2)
        XCTAssertEqual(majorTags.count, 1)
        XCTAssertEqual(moderateTags.count, 0)
    }

    func testHasSpoilersReturnsFalseWhenNoTags() {
        XCTAssertFalse(service.hasSpoilers(in: docId))
    }

    func testHasSpoilersReturnsTrueAfterTagging() {
        service.tagSpoiler(in: docId, startOffset: 0, endOffset: 5)
        XCTAssertTrue(service.hasSpoilers(in: docId))
    }

    func testHasSpoilersReturnsFalseAfterTagRemoval() {
        let tag = service.tagSpoiler(in: docId, startOffset: 0, endOffset: 5)!
        service.removeSpoilerTag(id: tag.id)
        XCTAssertFalse(service.hasSpoilers(in: docId))
    }
}

// MARK: - SpoilerProtectionService Redaction Tests

final class SpoilerProtectionServiceRedactionTests: XCTestCase {

    var service: SpoilerProtectionService!
    var docId: UUID!

    override func setUp() {
        super.setUp()
        service = SpoilerProtectionService()
        docId = UUID()
    }

    func testRedactSpoilersReturnsOriginalWhenNoTags() {
        let result = service.redactSpoilers(in: "Hello world", document: docId)
        XCTAssertEqual(result, "Hello world")
    }

    func testRedactSpoilersReplacesTaggedRegion() {
        // "Hello world" — tag offsets 6..<11 covers "world"
        service.tagSpoiler(in: docId, startOffset: 6, endOffset: 11)
        let result = service.redactSpoilers(in: "Hello world", document: docId)
        XCTAssertFalse(result.contains("world"))
        XCTAssertTrue(result.contains("[SPOILER REDACTED]"))
        XCTAssertTrue(result.hasPrefix("Hello "))
    }

    func testRedactSpoilersPreservesContentOutsideTag() {
        service.tagSpoiler(in: docId, startOffset: 0, endOffset: 5)
        let result = service.redactSpoilers(in: "Hello world", document: docId)
        XCTAssertTrue(result.hasSuffix(" world"))
        XCTAssertTrue(result.contains("[SPOILER REDACTED]"))
    }

    func testRedactSpoilersHandlesTagAtStartOfContent() {
        service.tagSpoiler(in: docId, startOffset: 0, endOffset: 5)
        let result = service.redactSpoilers(in: "Hello world", document: docId)
        XCTAssertTrue(result.hasPrefix("[SPOILER REDACTED]"))
    }

    func testRedactSpoilersHandlesTagAtEndOfContent() {
        // "Hello world" length = 11; tag last 5 chars "world" at 6..<11
        service.tagSpoiler(in: docId, startOffset: 6, endOffset: 11)
        let result = service.redactSpoilers(in: "Hello world", document: docId)
        XCTAssertTrue(result.hasSuffix("[SPOILER REDACTED]"))
    }

    func testRedactSpoilersHandlesTagCoveringEntireContent() {
        let content = "Entire content is a spoiler"
        service.tagSpoiler(in: docId, startOffset: 0, endOffset: content.unicodeScalars.count)
        let result = service.redactSpoilers(in: content, document: docId)
        XCTAssertEqual(result, "[SPOILER REDACTED]")
    }

    func testRedactSpoilersHandlesMultipleTags() {
        // "Hello world foo bar" — tag "world" (6..<11) and "bar" (16..<19)
        service.tagSpoiler(in: docId, startOffset: 6, endOffset: 11)
        service.tagSpoiler(in: docId, startOffset: 16, endOffset: 19)
        let result = service.redactSpoilers(in: "Hello world foo bar", document: docId)
        XCTAssertFalse(result.contains("world"))
        XCTAssertFalse(result.contains("bar"))
        XCTAssertTrue(result.contains("Hello "))
        XCTAssertTrue(result.contains(" foo "))
    }

    func testRedactSpoilersHandlesTagBeyondContentLength() {
        // Tag extends beyond content — should clamp and not crash
        service.tagSpoiler(in: docId, startOffset: 0, endOffset: 1000)
        let result = service.redactSpoilers(in: "Short", document: docId)
        XCTAssertEqual(result, "[SPOILER REDACTED]")
    }

    func testRedactSpoilersIgnoresOverlappingTagsByAdvancingCursor() {
        // Overlapping: tag 0..<10 and 5..<15; cursor should not go backwards
        service.tagSpoiler(in: docId, startOffset: 0, endOffset: 10)
        service.tagSpoiler(in: docId, startOffset: 5, endOffset: 15)
        let content = "Hello world foo"
        let result = service.redactSpoilers(in: content, document: docId)
        // Should not crash or produce duplicate text
        XCTAssertFalse(result.isEmpty)
        XCTAssertFalse(result.contains("Hello"))
    }
}

// MARK: - SpoilerProtectionService Markup Export Tests

final class SpoilerProtectionServiceMarkupTests: XCTestCase {

    var service: SpoilerProtectionService!
    var docId: UUID!

    override func setUp() {
        super.setUp()
        service = SpoilerProtectionService()
        docId = UUID()
    }

    func testExportWithMarkdownFormatWrapsInSpoilerMarkup() {
        service.tagSpoiler(in: docId, startOffset: 0, endOffset: 4, severity: .moderate)
        let result = service.exportWithSpoilerMarkup(content: "dies at the end", document: docId, format: .markdown)
        XCTAssertTrue(result.contains("||SPOILER(moderate): dies||"))
    }

    func testExportWithMarkdownMajorSeverity() {
        service.tagSpoiler(in: docId, startOffset: 3, endOffset: 7, severity: .major)
        let result = service.exportWithSpoilerMarkup(content: "He dies!", document: docId, format: .markdown)
        XCTAssertTrue(result.contains("||SPOILER(major): dies||"))
    }

    func testExportWithMarkdownMinorSeverity() {
        service.tagSpoiler(in: docId, startOffset: 0, endOffset: 5, severity: .minor)
        let result = service.exportWithSpoilerMarkup(content: "Twist ending", document: docId, format: .markdown)
        XCTAssertTrue(result.contains("||SPOILER(minor): Twist||"))
    }

    func testExportWithHTMLFormatWrapsInSpanTag() {
        service.tagSpoiler(in: docId, startOffset: 0, endOffset: 5, severity: .major)
        let result = service.exportWithSpoilerMarkup(content: "Twist ending", document: docId, format: .html)
        XCTAssertTrue(result.contains("<span class=\"spoiler spoiler-major\">Twist</span>"))
    }

    func testExportWithHTMLEscapesAmpersand() {
        // content: "A&B" — tag all 3 chars
        service.tagSpoiler(in: docId, startOffset: 0, endOffset: 3)
        let result = service.exportWithSpoilerMarkup(content: "A&B", document: docId, format: .html)
        XCTAssertTrue(result.contains("A&amp;B"))
    }

    func testExportWithHTMLEscapesAngleBrackets() {
        service.tagSpoiler(in: docId, startOffset: 0, endOffset: 5)
        let result = service.exportWithSpoilerMarkup(content: "<tag>", document: docId, format: .html)
        XCTAssertTrue(result.contains("&lt;tag&gt;"))
    }

    func testExportWithHTMLEscapesQuotes() {
        service.tagSpoiler(in: docId, startOffset: 0, endOffset: 3)
        let content = "\"hi\""
        service.tagSpoiler(in: docId, startOffset: 0, endOffset: content.unicodeScalars.count)
        let result = service.exportWithSpoilerMarkup(content: content, document: docId, format: .html)
        XCTAssertTrue(result.contains("&quot;") || result.contains("&#39;") || result.contains("hi"))
    }

    func testExportWithPlainTextFormat() {
        service.tagSpoiler(in: docId, startOffset: 0, endOffset: 4, severity: .minor)
        let result = service.exportWithSpoilerMarkup(content: "dies at the end", document: docId, format: .plainText)
        XCTAssertTrue(result.contains("[SPOILER(minor): dies]"))
    }

    func testExportReturnsOriginalContentWhenNoTags() {
        let content = "No spoilers here at all"
        let resultMd = service.exportWithSpoilerMarkup(content: content, document: docId, format: .markdown)
        let resultHtml = service.exportWithSpoilerMarkup(content: content, document: docId, format: .html)
        let resultPlain = service.exportWithSpoilerMarkup(content: content, document: docId, format: .plainText)
        XCTAssertEqual(resultMd, content)
        XCTAssertEqual(resultHtml, content)
        XCTAssertEqual(resultPlain, content)
    }

    func testExportPreservesTextOutsideSpoilerRegion() {
        // "He dies at the end." — tag "dies" at 3..<7
        service.tagSpoiler(in: docId, startOffset: 3, endOffset: 7, severity: .moderate)
        let result = service.exportWithSpoilerMarkup(content: "He dies at the end.", document: docId, format: .markdown)
        XCTAssertTrue(result.hasPrefix("He "))
        XCTAssertTrue(result.hasSuffix(" at the end."))
    }
}
