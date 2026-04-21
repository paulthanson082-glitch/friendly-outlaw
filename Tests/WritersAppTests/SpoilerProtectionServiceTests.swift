import XCTest
@testable import WritersApp

// MARK: - SpoilerProtectionService Tests

final class SpoilerProtectionServiceTests: XCTestCase {

    var service: SpoilerProtectionService!
    var documentId: UUID!

    override func setUp() {
        super.setUp()
        service = SpoilerProtectionService()
        documentId = UUID()
    }

    override func tearDown() {
        service = nil
        documentId = nil
        super.tearDown()
    }

    // MARK: - tagSpoiler

    func testTagSpoilerReturnsValidTag() {
        let tag = service.tagSpoiler(in: documentId, startOffset: 0, endOffset: 10)
        XCTAssertNotNil(tag)
        XCTAssertEqual(tag?.startOffset, 0)
        XCTAssertEqual(tag?.endOffset, 10)
        XCTAssertEqual(tag?.documentId, documentId)
    }

    func testTagSpoilerAssignsUniqueId() {
        let tag1 = service.tagSpoiler(in: documentId, startOffset: 0, endOffset: 5)
        let tag2 = service.tagSpoiler(in: documentId, startOffset: 5, endOffset: 10)
        XCTAssertNotEqual(tag1?.id, tag2?.id)
    }

    func testTagSpoilerSetsDescription() {
        let tag = service.tagSpoiler(in: documentId, startOffset: 0, endOffset: 5, description: "Key plot reveal")
        XCTAssertEqual(tag?.description, "Key plot reveal")
    }

    func testTagSpoilerSetsSeverity() {
        let tag = service.tagSpoiler(in: documentId, startOffset: 0, endOffset: 5, severity: .major)
        XCTAssertEqual(tag?.severity, .major)
    }

    func testTagSpoilerDefaultSeverityIsModerate() {
        let tag = service.tagSpoiler(in: documentId, startOffset: 0, endOffset: 5)
        XCTAssertEqual(tag?.severity, .moderate)
    }

    func testTagSpoilerRejectsNegativeStartOffset() {
        let tag = service.tagSpoiler(in: documentId, startOffset: -1, endOffset: 5)
        XCTAssertNil(tag, "Negative startOffset must be rejected")
    }

    func testTagSpoilerRejectsEndOffsetEqualToStart() {
        let tag = service.tagSpoiler(in: documentId, startOffset: 5, endOffset: 5)
        XCTAssertNil(tag, "endOffset == startOffset is an empty range and must be rejected")
    }

    func testTagSpoilerRejectsEndOffsetLessThanStart() {
        let tag = service.tagSpoiler(in: documentId, startOffset: 10, endOffset: 5)
        XCTAssertNil(tag, "endOffset < startOffset must be rejected")
    }

    func testTagSpoilerAcceptsZeroStartWithPositiveEnd() {
        let tag = service.tagSpoiler(in: documentId, startOffset: 0, endOffset: 1)
        XCTAssertNotNil(tag)
    }

    // MARK: - removeSpoilerTag

    func testRemoveSpoilerTagRemovesTag() {
        let tag = service.tagSpoiler(in: documentId, startOffset: 0, endOffset: 5)!
        service.removeSpoilerTag(id: tag.id)
        let tags = service.getSpoilerTags(forDocument: documentId)
        XCTAssertFalse(tags.contains { $0.id == tag.id })
    }

    func testRemoveSpoilerTagDoesNotAffectOtherTags() {
        let tag1 = service.tagSpoiler(in: documentId, startOffset: 0, endOffset: 5)!
        let tag2 = service.tagSpoiler(in: documentId, startOffset: 5, endOffset: 10)!
        service.removeSpoilerTag(id: tag1.id)
        let tags = service.getSpoilerTags(forDocument: documentId)
        XCTAssertTrue(tags.contains { $0.id == tag2.id })
    }

    func testRemoveNonExistentTagIsNoOp() {
        service.tagSpoiler(in: documentId, startOffset: 0, endOffset: 5)
        service.removeSpoilerTag(id: UUID())
        XCTAssertEqual(service.getSpoilerTags(forDocument: documentId).count, 1)
    }

    // MARK: - getSpoilerTags(forDocument:)

    func testGetSpoilerTagsForDocumentReturnsSortedByStartOffset() {
        service.tagSpoiler(in: documentId, startOffset: 20, endOffset: 30)
        service.tagSpoiler(in: documentId, startOffset: 0, endOffset: 10)
        service.tagSpoiler(in: documentId, startOffset: 10, endOffset: 20)
        let tags = service.getSpoilerTags(forDocument: documentId)
        XCTAssertEqual(tags.count, 3)
        XCTAssertEqual(tags[0].startOffset, 0)
        XCTAssertEqual(tags[1].startOffset, 10)
        XCTAssertEqual(tags[2].startOffset, 20)
    }

    func testGetSpoilerTagsFiltersToRequestedDocument() {
        let other = UUID()
        service.tagSpoiler(in: documentId, startOffset: 0, endOffset: 5)
        service.tagSpoiler(in: other, startOffset: 0, endOffset: 5)
        let tags = service.getSpoilerTags(forDocument: documentId)
        XCTAssertEqual(tags.count, 1)
        XCTAssertEqual(tags[0].documentId, documentId)
    }

    func testGetSpoilerTagsReturnsEmptyForUnknownDocument() {
        service.tagSpoiler(in: documentId, startOffset: 0, endOffset: 5)
        let tags = service.getSpoilerTags(forDocument: UUID())
        XCTAssertTrue(tags.isEmpty)
    }

    // MARK: - getSpoilerTags(withSeverity:)

    func testGetSpoilerTagsWithSeverityFiltersCorrectly() {
        service.tagSpoiler(in: documentId, startOffset: 0, endOffset: 5, severity: .minor)
        service.tagSpoiler(in: documentId, startOffset: 5, endOffset: 10, severity: .major)
        service.tagSpoiler(in: documentId, startOffset: 10, endOffset: 15, severity: .minor)
        let minors = service.getSpoilerTags(withSeverity: .minor)
        XCTAssertEqual(minors.count, 2)
        XCTAssertTrue(minors.allSatisfy { $0.severity == .minor })
    }

    func testGetSpoilerTagsWithSeverityReturnsEmptyIfNoneMatch() {
        service.tagSpoiler(in: documentId, startOffset: 0, endOffset: 5, severity: .minor)
        let majors = service.getSpoilerTags(withSeverity: .major)
        XCTAssertTrue(majors.isEmpty)
    }

    // MARK: - hasSpoilers

    func testHasSpoilersReturnsTrueWhenTagExists() {
        service.tagSpoiler(in: documentId, startOffset: 0, endOffset: 5)
        XCTAssertTrue(service.hasSpoilers(in: documentId))
    }

    func testHasSpoilersReturnsFalseWhenNoTags() {
        XCTAssertFalse(service.hasSpoilers(in: documentId))
    }

    func testHasSpoilersReturnsFalseAfterTagRemoval() {
        let tag = service.tagSpoiler(in: documentId, startOffset: 0, endOffset: 5)!
        service.removeSpoilerTag(id: tag.id)
        XCTAssertFalse(service.hasSpoilers(in: documentId))
    }

    func testHasSpoilersReturnsFalseForDifferentDocument() {
        service.tagSpoiler(in: documentId, startOffset: 0, endOffset: 5)
        XCTAssertFalse(service.hasSpoilers(in: UUID()))
    }

    // MARK: - redactSpoilers

    func testRedactSpoilersReplacesRegionWithPlaceholder() {
        let content = "Hello World"
        service.tagSpoiler(in: documentId, startOffset: 6, endOffset: 11)
        let result = service.redactSpoilers(in: content, document: documentId)
        XCTAssertEqual(result, "Hello [SPOILER REDACTED]")
    }

    func testRedactSpoilersReturnsOriginalWhenNoTags() {
        let content = "No spoilers here"
        let result = service.redactSpoilers(in: content, document: documentId)
        XCTAssertEqual(result, content)
    }

    func testRedactSpoilersHandlesMultipleTags() {
        let content = "ABCDE"
        service.tagSpoiler(in: documentId, startOffset: 0, endOffset: 1) // A
        service.tagSpoiler(in: documentId, startOffset: 2, endOffset: 3) // C
        let result = service.redactSpoilers(in: content, document: documentId)
        XCTAssertTrue(result.contains("[SPOILER REDACTED]"))
        XCTAssertTrue(result.contains("B"))
        XCTAssertTrue(result.contains("DE"))
    }

    func testRedactSpoilersHandlesFullContentTag() {
        let content = "Entire content is a spoiler"
        service.tagSpoiler(in: documentId, startOffset: 0, endOffset: content.unicodeScalars.count)
        let result = service.redactSpoilers(in: content, document: documentId)
        XCTAssertEqual(result, "[SPOILER REDACTED]")
    }

    func testRedactSpoilersDoesNotAffectOtherDocuments() {
        let content = "Hello World"
        service.tagSpoiler(in: UUID(), startOffset: 0, endOffset: 5)
        let result = service.redactSpoilers(in: content, document: documentId)
        XCTAssertEqual(result, content)
    }

    // MARK: - exportWithSpoilerMarkup

    func testExportWithMarkdownFormat() {
        let content = "World"
        service.tagSpoiler(in: documentId, startOffset: 0, endOffset: 5, severity: .major)
        let result = service.exportWithSpoilerMarkup(content: content, document: documentId, format: .markdown)
        XCTAssertTrue(result.contains("||SPOILER(major): World||"), "Markdown format: got '\(result)'")
    }

    func testExportWithHTMLFormat() {
        let content = "World"
        service.tagSpoiler(in: documentId, startOffset: 0, endOffset: 5, severity: .minor)
        let result = service.exportWithSpoilerMarkup(content: content, document: documentId, format: .html)
        XCTAssertTrue(result.contains("<span class=\"spoiler spoiler-minor\">World</span>"))
    }

    func testExportWithPlainTextFormat() {
        let content = "World"
        service.tagSpoiler(in: documentId, startOffset: 0, endOffset: 5, severity: .moderate)
        let result = service.exportWithSpoilerMarkup(content: content, document: documentId, format: .plainText)
        XCTAssertTrue(result.contains("[SPOILER(moderate): World]"))
    }

    func testExportHTMLEscapesSpecialCharacters() {
        let content = "<b>Bold</b>"
        service.tagSpoiler(in: documentId, startOffset: 0, endOffset: content.unicodeScalars.count, severity: .minor)
        let result = service.exportWithSpoilerMarkup(content: content, document: documentId, format: .html)
        XCTAssertTrue(result.contains("&lt;b&gt;Bold&lt;/b&gt;"))
        XCTAssertFalse(result.contains("<b>"))
    }

    func testExportWithNoTagsReturnsOriginalContent() {
        let content = "No spoilers"
        let result = service.exportWithSpoilerMarkup(content: content, document: documentId, format: .markdown)
        XCTAssertEqual(result, content)
    }

    // MARK: - SpoilerSeverity

    func testSpoilerSeverityDisplayNames() {
        XCTAssertEqual(SpoilerSeverity.minor.displayName, "Minor")
        XCTAssertEqual(SpoilerSeverity.moderate.displayName, "Moderate")
        XCTAssertEqual(SpoilerSeverity.major.displayName, "Major")
    }

    func testSpoilerSeverityAllCases() {
        XCTAssertEqual(SpoilerSeverity.allCases.count, 3)
    }

    func testSpoilerSeverityCodableRoundTrip() throws {
        for severity in SpoilerSeverity.allCases {
            let data = try JSONEncoder().encode(severity)
            let decoded = try JSONDecoder().decode(SpoilerSeverity.self, from: data)
            XCTAssertEqual(decoded, severity)
        }
    }

    // MARK: - SpoilerTag model

    func testSpoilerTagCodableRoundTrip() throws {
        let tag = SpoilerTag(
            documentId: documentId,
            startOffset: 5,
            endOffset: 15,
            description: "Plot twist",
            severity: .major
        )
        let data = try JSONEncoder().encode(tag)
        let decoded = try JSONDecoder().decode(SpoilerTag.self, from: data)
        XCTAssertEqual(decoded.id, tag.id)
        XCTAssertEqual(decoded.startOffset, 5)
        XCTAssertEqual(decoded.endOffset, 15)
        XCTAssertEqual(decoded.description, "Plot twist")
        XCTAssertEqual(decoded.severity, .major)
    }

    // MARK: - WritersApp integration

    func testWritersAppExposesSpoilerProtection() {
        let app = WritersApp()
        XCTAssertNotNil(app.spoilerProtection)
    }

    func testWritersAppTagSpoilerDelegatesToService() {
        let app = WritersApp()
        let doc = app.createBlankDocument(title: "Test", category: .novel)
        let tag = app.tagSpoiler(in: doc.id, startOffset: 0, endOffset: 5, description: "Reveal")
        XCTAssertNotNil(tag)
        XCTAssertEqual(tag?.documentId, doc.id)
    }

    func testWritersAppHasSpoilersDelegatesToService() {
        let app = WritersApp()
        let doc = app.createBlankDocument(title: "Test", category: .novel)
        XCTAssertFalse(app.documentHasSpoilers(doc.id))
        app.tagSpoiler(in: doc.id, startOffset: 0, endOffset: 5)
        XCTAssertTrue(app.documentHasSpoilers(doc.id))
    }

    func testWritersAppGetSpoilerTagsDelegatesToService() {
        let app = WritersApp()
        let doc = app.createBlankDocument(title: "Test", category: .novel)
        app.tagSpoiler(in: doc.id, startOffset: 0, endOffset: 5, severity: .major)
        let tags = app.getSpoilerTags(forDocument: doc.id)
        XCTAssertEqual(tags.count, 1)
        XCTAssertEqual(tags[0].severity, .major)
    }

    func testWritersAppRemoveSpoilerTagDelegatesToService() {
        let app = WritersApp()
        let doc = app.createBlankDocument(title: "Test", category: .novel)
        let tag = app.tagSpoiler(in: doc.id, startOffset: 0, endOffset: 5)!
        app.removeSpoilerTag(id: tag.id)
        XCTAssertFalse(app.documentHasSpoilers(doc.id))
    }
}
