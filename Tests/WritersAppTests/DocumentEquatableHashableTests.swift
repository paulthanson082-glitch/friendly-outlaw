import XCTest
@testable import WritersApp

// MARK: - Document Equatable/Hashable Tests
//
// The PR removed the custom `==` and `hash(into:)` implementations from `Document`.
// Before this PR, equality and hashing were based on `id` alone — two documents with
// the same UUID but different content were considered equal.
//
// After this PR, Swift synthesizes Equatable/Hashable from ALL stored properties
// (id, title, content, templateId, category, metadata). Two documents with the same
// UUID but any differing field are now considered NOT equal.

final class DocumentEquatableTests: XCTestCase {

    // MARK: - Equality: identical documents

    func testDocumentsWithIdenticalPropertiesAreEqual() {
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
        let fixedId = UUID()
        let metadata = DocumentMetadata(
            created: fixedDate,
            modified: fixedDate,
            lastOpened: nil,
            wordCountGoal: nil,
            tags: [],
            notes: ""
        )
        let doc1 = Document(
            id: fixedId,
            title: "Chapter One",
            content: "It was a dark and stormy night.",
            templateId: nil,
            category: .novel,
            metadata: metadata
        )
        let doc2 = Document(
            id: fixedId,
            title: "Chapter One",
            content: "It was a dark and stormy night.",
            templateId: nil,
            category: .novel,
            metadata: metadata
        )
        XCTAssertEqual(doc1, doc2,
            "Two documents with identical properties must be equal (synthesized Equatable)")
    }

    // MARK: - Equality: same id, different content → NOT equal after PR

    func testDocumentsWithSameIdButDifferentContentAreNotEqual() {
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
        let fixedId = UUID()
        let metadata = DocumentMetadata(created: fixedDate, modified: fixedDate)
        let doc1 = Document(
            id: fixedId,
            title: "Same Title",
            content: "Original content.",
            category: .novel,
            metadata: metadata
        )
        let doc2 = Document(
            id: fixedId,
            title: "Same Title",
            content: "Revised content.",  // different content
            category: .novel,
            metadata: metadata
        )
        XCTAssertNotEqual(doc1, doc2,
            "After the PR, documents with the same id but different content must NOT be equal")
    }

    func testDocumentsWithSameIdButDifferentTitleAreNotEqual() {
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
        let fixedId = UUID()
        let metadata = DocumentMetadata(created: fixedDate, modified: fixedDate)
        let doc1 = Document(id: fixedId, title: "Title A", content: "Body", category: .shortStory, metadata: metadata)
        let doc2 = Document(id: fixedId, title: "Title B", content: "Body", category: .shortStory, metadata: metadata)
        XCTAssertNotEqual(doc1, doc2,
            "Documents with the same id but different titles must NOT be equal")
    }

    func testDocumentsWithSameIdButDifferentCategoryAreNotEqual() {
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
        let fixedId = UUID()
        let metadata = DocumentMetadata(created: fixedDate, modified: fixedDate)
        let doc1 = Document(id: fixedId, title: "T", content: "C", category: .novel, metadata: metadata)
        let doc2 = Document(id: fixedId, title: "T", content: "C", category: .screenplay, metadata: metadata)
        XCTAssertNotEqual(doc1, doc2,
            "Documents with the same id but different categories must NOT be equal")
    }

    func testDocumentsWithSameIdButDifferentMetadataAreNotEqual() {
        let fixedId = UUID()
        let date1 = Date(timeIntervalSince1970: 1_000_000)
        let date2 = Date(timeIntervalSince1970: 2_000_000)
        let meta1 = DocumentMetadata(created: date1, modified: date1)
        let meta2 = DocumentMetadata(created: date2, modified: date2)
        let doc1 = Document(id: fixedId, title: "T", content: "C", category: .novel, metadata: meta1)
        let doc2 = Document(id: fixedId, title: "T", content: "C", category: .novel, metadata: meta2)
        XCTAssertNotEqual(doc1, doc2,
            "Documents with the same id but different metadata must NOT be equal")
    }

    func testDocumentsWithDifferentIdsAreNotEqual() {
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
        let metadata = DocumentMetadata(created: fixedDate, modified: fixedDate)
        let doc1 = Document(id: UUID(), title: "T", content: "C", category: .novel, metadata: metadata)
        let doc2 = Document(id: UUID(), title: "T", content: "C", category: .novel, metadata: metadata)
        XCTAssertNotEqual(doc1, doc2,
            "Documents with different ids must never be equal")
    }

    // MARK: - Hashability: use in Set

    func testDocumentCanBeStoredInSet() {
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
        let fixedId = UUID()
        let metadata = DocumentMetadata(created: fixedDate, modified: fixedDate)
        let doc = Document(
            id: fixedId,
            title: "Unique Doc",
            content: "Some content",
            category: .novel,
            metadata: metadata
        )
        var docSet: Set<Document> = []
        docSet.insert(doc)
        XCTAssertEqual(docSet.count, 1, "Document must be insertable into a Set")
    }

    func testDocumentsWithDifferentContentHaveDifferentHashValues() {
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
        let fixedId = UUID()
        let metadata = DocumentMetadata(created: fixedDate, modified: fixedDate)
        let doc1 = Document(id: fixedId, title: "T", content: "Content A", category: .novel, metadata: metadata)
        let doc2 = Document(id: fixedId, title: "T", content: "Content B", category: .novel, metadata: metadata)

        var hasher1 = Hasher()
        doc1.hash(into: &hasher1)
        var hasher2 = Hasher()
        doc2.hash(into: &hasher2)
        // Hash collision is theoretically possible but practically impossible with this input difference.
        XCTAssertNotEqual(hasher1.finalize(), hasher2.finalize(),
            "Documents with different content should produce different hash values")
    }

    func testEqualDocumentsHaveSameHashValue() {
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
        let fixedId = UUID()
        let metadata = DocumentMetadata(created: fixedDate, modified: fixedDate)
        let doc1 = Document(
            id: fixedId,
            title: "Same Title",
            content: "Same content",
            category: .novel,
            metadata: metadata
        )
        let doc2 = Document(
            id: fixedId,
            title: "Same Title",
            content: "Same content",
            category: .novel,
            metadata: metadata
        )
        XCTAssertEqual(doc1, doc2)

        var hasher1 = Hasher()
        doc1.hash(into: &hasher1)
        var hasher2 = Hasher()
        doc2.hash(into: &hasher2)
        XCTAssertEqual(hasher1.finalize(), hasher2.finalize(),
            "Equal documents must have the same hash value")
    }

    func testTwoDistinctDocumentsOccupyTwoSlotsInSet() {
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
        let fixedId = UUID()
        let metadata = DocumentMetadata(created: fixedDate, modified: fixedDate)
        // These have the same id but different content → NOT equal after the PR.
        let doc1 = Document(id: fixedId, title: "T", content: "Content A", category: .novel, metadata: metadata)
        let doc2 = Document(id: fixedId, title: "T", content: "Content B", category: .novel, metadata: metadata)
        let docSet: Set<Document> = [doc1, doc2]
        XCTAssertEqual(docSet.count, 2,
            "After the PR, two documents with the same id but different content occupy two slots in a Set")
    }

    func testInsertingDuplicateDocumentDoesNotIncreaseSetSize() {
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
        let fixedId = UUID()
        let metadata = DocumentMetadata(created: fixedDate, modified: fixedDate)
        let doc = Document(id: fixedId, title: "T", content: "C", category: .novel, metadata: metadata)
        var docSet: Set<Document> = [doc]
        docSet.insert(doc)
        XCTAssertEqual(docSet.count, 1,
            "Inserting the same document twice must not increase the set size")
    }

    // MARK: - DocumentMetadata synthesized Equatable/Hashable

    func testDocumentMetadataEqualityIsSynthesized() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let meta1 = DocumentMetadata(created: date, modified: date, wordCountGoal: 50000, tags: ["tag1"])
        let meta2 = DocumentMetadata(created: date, modified: date, wordCountGoal: 50000, tags: ["tag1"])
        XCTAssertEqual(meta1, meta2, "DocumentMetadata with identical fields must be equal")
    }

    func testDocumentMetadataWithDifferentTagsIsNotEqual() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let meta1 = DocumentMetadata(created: date, modified: date, tags: ["draft"])
        let meta2 = DocumentMetadata(created: date, modified: date, tags: ["final"])
        XCTAssertNotEqual(meta1, meta2, "DocumentMetadata with different tags must not be equal")
    }

    func testDocumentMetadataWithDifferentGoalIsNotEqual() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let meta1 = DocumentMetadata(created: date, modified: date, wordCountGoal: 1000)
        let meta2 = DocumentMetadata(created: date, modified: date, wordCountGoal: 2000)
        XCTAssertNotEqual(meta1, meta2, "DocumentMetadata with different wordCountGoal must not be equal")
    }

    func testDocumentMetadataCanBeUsedInDictionary() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let meta = DocumentMetadata(created: date, modified: date)
        var dict: [DocumentMetadata: String] = [:]
        dict[meta] = "value"
        XCTAssertEqual(dict[meta], "value", "DocumentMetadata must be usable as a dictionary key")
    }
}