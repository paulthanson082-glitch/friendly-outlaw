import XCTest
@testable import WritersApp

// MARK: - Document Equatable/Hashable Tests
//
// PR change: the custom `==` and `hash(into:)` implementations were removed from `Document`.
//
// Before this PR, equality and hashing were based on `id` alone — two documents with
// the same UUID but different content were considered equal.
//
// After this PR, Swift synthesizes Equatable/Hashable from ALL stored properties
// (id, title, content, templateId, category, metadata). Two documents with the same
// UUID but any differing field are now considered NOT equal.

final class DocumentEquatableTests: XCTestCase {

    // MARK: - Helpers

    private func makeMetadata(date: Date = Date(timeIntervalSince1970: 1_700_000_000)) -> DocumentMetadata {
        DocumentMetadata(created: date, modified: date, lastOpened: nil, wordCountGoal: nil, tags: [], notes: "")
    }

    // MARK: - Identical documents are equal (synthesized)

    func testDocumentsWithIdenticalPropertiesAreEqual() {
        let id = UUID()
        let meta = makeMetadata()
        let doc1 = Document(id: id, title: "Chapter One", content: "It was a dark and stormy night.", category: .novel, metadata: meta)
        let doc2 = Document(id: id, title: "Chapter One", content: "It was a dark and stormy night.", category: .novel, metadata: meta)
        XCTAssertEqual(doc1, doc2,
            "Two documents with identical properties must be equal (synthesized Equatable)")
    }

    // MARK: - Same id, different fields → NOT equal after PR

    func testDocumentsWithSameIdButDifferentContentAreNotEqual() {
        let id = UUID()
        let meta = makeMetadata()
        let doc1 = Document(id: id, title: "Title", content: "Original content.", category: .novel, metadata: meta)
        let doc2 = Document(id: id, title: "Title", content: "Revised content.", category: .novel, metadata: meta)
        XCTAssertNotEqual(doc1, doc2,
            "After the PR, documents with the same id but different content must NOT be equal")
    }

    func testDocumentsWithSameIdButDifferentTitleAreNotEqual() {
        let id = UUID()
        let meta = makeMetadata()
        let doc1 = Document(id: id, title: "Title A", content: "Body", category: .shortStory, metadata: meta)
        let doc2 = Document(id: id, title: "Title B", content: "Body", category: .shortStory, metadata: meta)
        XCTAssertNotEqual(doc1, doc2,
            "Documents with the same id but different titles must NOT be equal")
    }

    func testDocumentsWithSameIdButDifferentCategoryAreNotEqual() {
        let id = UUID()
        let meta = makeMetadata()
        let doc1 = Document(id: id, title: "T", content: "C", category: .novel, metadata: meta)
        let doc2 = Document(id: id, title: "T", content: "C", category: .screenplay, metadata: meta)
        XCTAssertNotEqual(doc1, doc2,
            "Documents with the same id but different categories must NOT be equal")
    }

    func testDocumentsWithSameIdButDifferentMetadataAreNotEqual() {
        let id = UUID()
        let meta1 = DocumentMetadata(created: Date(timeIntervalSince1970: 1_000_000), modified: Date(timeIntervalSince1970: 1_000_000))
        let meta2 = DocumentMetadata(created: Date(timeIntervalSince1970: 2_000_000), modified: Date(timeIntervalSince1970: 2_000_000))
        let doc1 = Document(id: id, title: "T", content: "C", category: .novel, metadata: meta1)
        let doc2 = Document(id: id, title: "T", content: "C", category: .novel, metadata: meta2)
        XCTAssertNotEqual(doc1, doc2,
            "Documents with the same id but different metadata must NOT be equal")
    }

    func testDocumentsWithDifferentIdsAreNotEqual() {
        let meta = makeMetadata()
        let doc1 = Document(id: UUID(), title: "T", content: "C", category: .novel, metadata: meta)
        let doc2 = Document(id: UUID(), title: "T", content: "C", category: .novel, metadata: meta)
        XCTAssertNotEqual(doc1, doc2,
            "Documents with different ids must never be equal")
    }

    // MARK: - Hashability: use in Set

    func testDocumentCanBeStoredInSet() {
        let meta = makeMetadata()
        let doc = Document(id: UUID(), title: "Unique Doc", content: "Some content", category: .novel, metadata: meta)
        var docSet: Set<Document> = []
        docSet.insert(doc)
        XCTAssertEqual(docSet.count, 1, "Document must be insertable into a Set")
    }

    func testDocumentsWithDifferentContentProduceDifferentHashValues() {
        let id = UUID()
        let meta = makeMetadata()
        let doc1 = Document(id: id, title: "T", content: "Content A", category: .novel, metadata: meta)
        let doc2 = Document(id: id, title: "T", content: "Content B", category: .novel, metadata: meta)

        var hasher1 = Hasher()
        doc1.hash(into: &hasher1)
        var hasher2 = Hasher()
        doc2.hash(into: &hasher2)
        XCTAssertNotEqual(hasher1.finalize(), hasher2.finalize(),
            "Documents with different content should produce different hash values")
    }

    func testEqualDocumentsHaveSameHashValue() {
        let id = UUID()
        let meta = makeMetadata()
        let doc1 = Document(id: id, title: "Same", content: "Same content", category: .novel, metadata: meta)
        let doc2 = Document(id: id, title: "Same", content: "Same content", category: .novel, metadata: meta)
        XCTAssertEqual(doc1, doc2)

        var hasher1 = Hasher()
        doc1.hash(into: &hasher1)
        var hasher2 = Hasher()
        doc2.hash(into: &hasher2)
        XCTAssertEqual(hasher1.finalize(), hasher2.finalize(),
            "Equal documents must have the same hash value")
    }

    func testTwoDocumentsWithSameIdButDifferentContentOccupyTwoSetSlots() {
        let id = UUID()
        let meta = makeMetadata()
        let doc1 = Document(id: id, title: "T", content: "Content A", category: .novel, metadata: meta)
        let doc2 = Document(id: id, title: "T", content: "Content B", category: .novel, metadata: meta)
        let docSet: Set<Document> = [doc1, doc2]
        XCTAssertEqual(docSet.count, 2,
            "After the PR, two documents with the same id but different content occupy two slots in a Set")
    }

    func testInsertingDuplicateDocumentDoesNotIncreaseSetSize() {
        let meta = makeMetadata()
        let doc = Document(id: UUID(), title: "T", content: "C", category: .novel, metadata: meta)
        var docSet: Set<Document> = [doc]
        docSet.insert(doc)
        XCTAssertEqual(docSet.count, 1,
            "Inserting the same document twice must not increase the set size")
    }

    // MARK: - Regression: document with updated content is treated as distinct

    func testMutatedContentIsConsideredDifferentDocument() {
        let id = UUID()
        let meta = makeMetadata()
        var doc = Document(id: id, title: "Novel", content: "Original", category: .novel, metadata: meta)
        let snapshot = doc
        doc.content = "Updated content after edit"
        XCTAssertNotEqual(doc, snapshot,
            "After mutating content, the document should not equal its earlier snapshot")
    }

    func testMutatedTitleIsConsideredDifferentDocument() {
        let id = UUID()
        let meta = makeMetadata()
        var doc = Document(id: id, title: "Old Title", content: "Body", category: .novel, metadata: meta)
        let snapshot = doc
        doc.title = "New Title"
        XCTAssertNotEqual(doc, snapshot,
            "After mutating title, the document should not equal its earlier snapshot")
    }
}

// MARK: - DocumentMetadata synthesized Equatable/Hashable

final class DocumentMetadataEquatableHashableTests: XCTestCase {

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

    func testDocumentMetadataWithDifferentWordCountGoalIsNotEqual() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let meta1 = DocumentMetadata(created: date, modified: date, wordCountGoal: 1000)
        let meta2 = DocumentMetadata(created: date, modified: date, wordCountGoal: 2000)
        XCTAssertNotEqual(meta1, meta2, "DocumentMetadata with different wordCountGoal must not be equal")
    }

    func testDocumentMetadataCanBeUsedAsDictionaryKey() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let meta = DocumentMetadata(created: date, modified: date)
        var dict: [DocumentMetadata: String] = [:]
        dict[meta] = "value"
        XCTAssertEqual(dict[meta], "value", "DocumentMetadata must be usable as a dictionary key")
    }

    func testDocumentMetadataCanBeStoredInSet() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let meta = DocumentMetadata(created: date, modified: date, tags: ["test"])
        var s: Set<DocumentMetadata> = []
        s.insert(meta)
        XCTAssertEqual(s.count, 1)
    }

    func testDocumentMetadataWithDifferentNotesIsNotEqual() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let meta1 = DocumentMetadata(created: date, modified: date, notes: "First draft")
        let meta2 = DocumentMetadata(created: date, modified: date, notes: "Second draft")
        XCTAssertNotEqual(meta1, meta2, "DocumentMetadata with different notes must not be equal")
    }
}