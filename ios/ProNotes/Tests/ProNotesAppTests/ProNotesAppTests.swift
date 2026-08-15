import XCTest
@testable import ProNotes

/// Unit tests for the `Note` model introduced alongside `ProNotesApp.swift`.
///
/// These tests exercise the pure Swift `Note` struct: its default/custom
/// initialization, id-based `Equatable`/`Hashable` conformance, and
/// `Codable` round-tripping. The CoreData-backed types declared in the same
/// file (`PersistenceController`, `NoteStore`, and the `NoteEntity`
/// extension) depend on the `ProNotes.xcdatamodeld` Core Data model that
/// ships with the Xcode project rather than the Swift source file, so they
/// are intentionally out of scope for these unit tests.
final class NoteTests: XCTestCase {

    // MARK: - Initialization

    func testDefaultInitializationUsesExpectedDefaults() {
        let note = Note()

        XCTAssertEqual(note.title, "Untitled")
        XCTAssertEqual(note.content, "")
        XCTAssertNil(note.canvasData)
        XCTAssertEqual(note.tags, [])
    }

    func testDefaultInitializationGeneratesUniqueIdentifiers() {
        let first = Note()
        let second = Note()

        XCTAssertNotEqual(first.id, second.id)
    }

    func testCustomInitializationRetainsAllProvidedValues() {
        let id = UUID()
        let createdAt = Date(timeIntervalSince1970: 1_000)
        let modifiedAt = Date(timeIntervalSince1970: 2_000)
        let canvasData = Data([0x01, 0x02, 0x03])

        let note = Note(
            id: id,
            title: "My Note",
            content: "Some content",
            canvasData: canvasData,
            createdAt: createdAt,
            modifiedAt: modifiedAt,
            tags: ["work", "ideas"]
        )

        XCTAssertEqual(note.id, id)
        XCTAssertEqual(note.title, "My Note")
        XCTAssertEqual(note.content, "Some content")
        XCTAssertEqual(note.canvasData, canvasData)
        XCTAssertEqual(note.createdAt, createdAt)
        XCTAssertEqual(note.modifiedAt, modifiedAt)
        XCTAssertEqual(note.tags, ["work", "ideas"])
    }

    // MARK: - Equatable

    func testNotesWithSameIdAreEqualRegardlessOfOtherFields() {
        let id = UUID()
        let first = Note(id: id, title: "First title", content: "First content")
        let second = Note(id: id, title: "Second title", content: "Second content")

        XCTAssertEqual(first, second)
    }

    func testNotesWithDifferentIdsAreNotEqualEvenWithIdenticalFields() {
        let createdAt = Date(timeIntervalSince1970: 0)
        let first = Note(title: "Same", content: "Same", createdAt: createdAt, modifiedAt: createdAt)
        let second = Note(title: "Same", content: "Same", createdAt: createdAt, modifiedAt: createdAt)

        XCTAssertNotEqual(first, second)
    }

    // MARK: - Hashable

    func testHashValueIsConsistentForNotesSharingAnId() {
        let id = UUID()
        let first = Note(id: id, title: "A")
        let second = Note(id: id, title: "B")

        XCTAssertEqual(first.hashValue, second.hashValue)
    }

    func testNotesWithSameIdCollapseInASet() {
        let id = UUID()
        let first = Note(id: id, title: "A")
        let second = Note(id: id, title: "B")

        let notes: Set<Note> = [first, second]

        XCTAssertEqual(notes.count, 1)
    }

    func testNotesWithDifferentIdsRemainDistinctInASet() {
        let notes: Set<Note> = [Note(), Note(), Note()]

        XCTAssertEqual(notes.count, 3)
    }

    // MARK: - Codable

    func testEncodingAndDecodingRoundTripsAllFields() throws {
        let original = Note(
            title: "Round Trip",
            content: "Body text",
            canvasData: Data([0xAA, 0xBB]),
            createdAt: Date(timeIntervalSince1970: 12_345),
            modifiedAt: Date(timeIntervalSince1970: 67_890),
            tags: ["tag1", "tag2"]
        )

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Note.self, from: encoded)

        XCTAssertEqual(decoded, original)
        XCTAssertEqual(decoded.title, original.title)
        XCTAssertEqual(decoded.content, original.content)
        XCTAssertEqual(decoded.canvasData, original.canvasData)
        XCTAssertEqual(decoded.createdAt, original.createdAt)
        XCTAssertEqual(decoded.modifiedAt, original.modifiedAt)
        XCTAssertEqual(decoded.tags, original.tags)
    }

    func testEncodingAndDecodingRoundTripsWithNilCanvasData() throws {
        let original = Note(canvasData: nil)

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Note.self, from: encoded)

        XCTAssertNil(decoded.canvasData)
    }

    func testEncodingAndDecodingRoundTripsWithEmptyTags() throws {
        let original = Note(tags: [])

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Note.self, from: encoded)

        XCTAssertEqual(decoded.tags, [])
    }

    func testDecodingFailsForMissingRequiredFields() {
        let incompleteJSON = """
        {
            "title": "Missing id, content, dates, and tags"
        }
        """
        let data = Data(incompleteJSON.utf8)

        XCTAssertThrowsError(try JSONDecoder().decode(Note.self, from: data)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testDecodingFailsForMalformedJSON() {
        let malformedJSON = "{ this is not valid JSON "
        let data = Data(malformedJSON.utf8)

        XCTAssertThrowsError(try JSONDecoder().decode(Note.self, from: data))
    }
}