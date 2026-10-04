import XCTest
@testable import WritersApp

final class ArchiverServiceTests: XCTestCase {

    var archiver: ArchiverService!
    var documentManager: DocumentManager!

    override func setUp() {
        super.setUp()
        documentManager = DocumentManager()
        archiver = ArchiverService(documentManager: documentManager)
    }

    // MARK: - Collection Tests

    func testCreateCollection() {
        let collection = archiver.createCollection(
            name: "Fantasy Shorts",
            description: "Short fantasy stories",
            theme: "fantasy",
            tags: ["fantasy", "shorts"]
        )

        XCTAssertEqual(collection.name, "Fantasy Shorts")
        XCTAssertEqual(collection.description, "Short fantasy stories")
        XCTAssertEqual(collection.theme, "fantasy")
        XCTAssertEqual(collection.tags, ["fantasy", "shorts"])
        XCTAssertTrue(collection.documentIds.isEmpty)
    }

    func testGetCollection() {
        let collection = archiver.createCollection(name: "Test")
        let retrieved = archiver.getCollection(collection.id)

        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.id, collection.id)
        XCTAssertEqual(retrieved?.name, "Test")
    }

    func testGetNonexistentCollection() {
        let retrieved = archiver.getCollection(UUID())
        XCTAssertNil(retrieved)
    }

    func testListCollections() {
        archiver.createCollection(name: "Collection 1")
        archiver.createCollection(name: "Collection 2")
        archiver.createCollection(name: "Collection 3")

        let collections = archiver.listCollections()
        XCTAssertEqual(collections.count, 3)
    }

    func testAddDocumentToCollection() {
        let doc = documentManager.createBlankDocument(title: "Test Doc")
        let collection = archiver.createCollection(name: "Test")

        archiver.addDocumentToCollection(doc.id, collectionId: collection.id)

        guard let updated = archiver.getCollection(collection.id) else {
            XCTFail("Collection not found")
            return
        }

        XCTAssertTrue(updated.documentIds.contains(doc.id))
    }

    func testAddDocumentPreventsDuplicates() {
        let doc = documentManager.createBlankDocument(title: "Test Doc")
        let collection = archiver.createCollection(name: "Test")

        archiver.addDocumentToCollection(doc.id, collectionId: collection.id)
        archiver.addDocumentToCollection(doc.id, collectionId: collection.id)

        guard let updated = archiver.getCollection(collection.id) else {
            XCTFail("Collection not found")
            return
        }

        XCTAssertEqual(updated.documentIds.filter { $0 == doc.id }.count, 1)
    }

    func testRemoveDocumentFromCollection() {
        let doc = documentManager.createBlankDocument(title: "Test Doc")
        let collection = archiver.createCollection(name: "Test")

        archiver.addDocumentToCollection(doc.id, collectionId: collection.id)
        archiver.removeDocumentFromCollection(doc.id, collectionId: collection.id)

        guard let updated = archiver.getCollection(collection.id) else {
            XCTFail("Collection not found")
            return
        }

        XCTAssertFalse(updated.documentIds.contains(doc.id))
    }

    func testDeleteCollection() {
        let collection = archiver.createCollection(name: "To Delete")
        archiver.deleteCollection(collection.id)

        let retrieved = archiver.getCollection(collection.id)
        XCTAssertNil(retrieved)
    }

    // MARK: - Snapshot Tests

    func testPreserveMilestone() {
        let snapshot = archiver.preserveMilestone(
            documentId: UUID(),
            title: "First Draft Complete",
            wordCount: 5000,
            characterCount: 28000,
            sessionCount: 8,
            daysStreak: 7,
            summary: "Completed the opening act",
            tags: ["milestone", "draft"]
        )

        XCTAssertEqual(snapshot.title, "First Draft Complete")
        XCTAssertEqual(snapshot.wordCount, 5000)
        XCTAssertEqual(snapshot.characterCount, 28000)
        XCTAssertEqual(snapshot.sessionCount, 8)
        XCTAssertEqual(snapshot.daysStreak, 7)
        XCTAssertEqual(snapshot.summary, "Completed the opening act")
        XCTAssertEqual(snapshot.tags, ["milestone", "draft"])
    }

    func testGetSnapshot() {
        let snapshot = archiver.preserveMilestone(
            documentId: UUID(),
            title: "Test Snapshot",
            wordCount: 1000
        )

        let retrieved = archiver.getSnapshot(snapshot.id)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.id, snapshot.id)
    }

    func testGetSnapshotsForDocument() {
        let docId = UUID()
        let otherId = UUID()

        archiver.preserveMilestone(documentId: docId, title: "Snap 1", wordCount: 1000)
        archiver.preserveMilestone(documentId: docId, title: "Snap 2", wordCount: 2000)
        archiver.preserveMilestone(documentId: otherId, title: "Snap 3", wordCount: 3000)

        let snapshots = archiver.getSnapshots(forDocument: docId)

        XCTAssertEqual(snapshots.count, 2)
        XCTAssertTrue(snapshots.allSatisfy { $0.documentId == docId })
    }

    func testListSnapshots() {
        let snap1 = archiver.preserveMilestone(documentId: UUID(), title: "First", wordCount: 1000)
        let snap2 = archiver.preserveMilestone(documentId: UUID(), title: "Second", wordCount: 2000)
        let snap3 = archiver.preserveMilestone(documentId: UUID(), title: "Third", wordCount: 3000)

        let snapshots = archiver.listSnapshots()

        XCTAssertEqual(snapshots.count, 3)
        XCTAssertEqual(snapshots[0].id, snap3.id)
        XCTAssertEqual(snapshots[1].id, snap2.id)
        XCTAssertEqual(snapshots[2].id, snap1.id)
    }

    // MARK: - Search Tests

    func testSearchByTitle() {
        let doc = documentManager.createBlankDocument(title: "Dragon's Tale")
        let collection = archiver.createCollection(name: "Fantasy")
        archiver.addDocumentToCollection(doc.id, collectionId: collection.id)

        let results = archiver.search("dragon")

        XCTAssertEqual(results.documents.count, 1)
        XCTAssertEqual(results.documents[0].title, "Dragon's Tale")
    }

    func testSearchBySnapshotSummary() {
        let snapshot = archiver.preserveMilestone(
            documentId: UUID(),
            title: "Epic Scene",
            summary: "The dragon awakens with fury"
        )

        let results = archiver.search("dragon")

        XCTAssertEqual(results.snapshots.count, 1)
        XCTAssertEqual(results.snapshots[0].id, snapshot.id)
    }

    func testSearchByTags() {
        var doc = documentManager.createBlankDocument(title: "Story")
        doc.metadata.tags = ["fantasy", "dragon"]
        documentManager.updateDocument(doc)
        let collection = archiver.createCollection(name: "Test")
        archiver.addDocumentToCollection(doc.id, collectionId: collection.id)

        let results = archiver.search("fantasy")

        XCTAssertEqual(results.documents.count, 1)
    }

    func testSearchByCollectionName() {
        archiver.createCollection(name: "Dragon Stories", tags: ["dragon"])

        let results = archiver.search("dragon")

        XCTAssertEqual(results.collections.count, 1)
    }

    func testSearchLimitRespected() {
        for i in 1...15 {
            let doc = documentManager.createBlankDocument(title: "Doc \(i)")
            let collection = archiver.createCollection(name: "Collection \(i)")
            archiver.addDocumentToCollection(doc.id, collectionId: collection.id)
        }

        let results = archiver.search("doc", limit: 5)

        XCTAssertLessThanOrEqual(results.documents.count, 5)
    }

    // MARK: - Suggestions Tests

    func testSuggestRelated() {
        var currentDoc = documentManager.createBlankDocument(title: "New Dragon Story")
        currentDoc.metadata.tags = ["fantasy", "dragon"]
        documentManager.updateDocument(currentDoc)

        var relatedDoc = documentManager.createBlankDocument(title: "Old Dragon Story")
        relatedDoc.metadata.tags = ["fantasy", "dragon"]
        documentManager.updateDocument(relatedDoc)

        let collection = archiver.createCollection(name: "Archive")
        archiver.addDocumentToCollection(relatedDoc.id, collectionId: collection.id)

        let expectation = XCTestExpectation(description: "Suggestions loaded")
        Task {
            let result = await archiver.suggestRelated(to: currentDoc.id, limit: 5)
            XCTAssertEqual(result.count, 1)
            XCTAssertEqual(result[0].id, relatedDoc.id)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testSuggestRelatedNoResults() {
        var currentDoc = documentManager.createBlankDocument(title: "Unique Story")
        currentDoc.metadata.tags = ["scifi", "alien"]
        documentManager.updateDocument(currentDoc)

        var archiveDoc = documentManager.createBlankDocument(title: "Fantasy Story")
        archiveDoc.metadata.tags = ["fantasy", "dragon"]
        documentManager.updateDocument(archiveDoc)

        let collection = archiver.createCollection(name: "Archive")
        archiver.addDocumentToCollection(archiveDoc.id, collectionId: collection.id)

        let expectation = XCTestExpectation(description: "Suggestions loaded")
        Task {
            let result = await archiver.suggestRelated(to: currentDoc.id, limit: 5)
            XCTAssertTrue(result.isEmpty)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testSuggestRelatedExcludesCurrentDocument() {
        var doc = documentManager.createBlankDocument(title: "Story")
        doc.metadata.tags = ["fantasy"]
        documentManager.updateDocument(doc)

        let collection = archiver.createCollection(name: "Archive")
        archiver.addDocumentToCollection(doc.id, collectionId: collection.id)

        let expectation = XCTestExpectation(description: "Suggestions loaded")
        Task {
            let result = await archiver.suggestRelated(to: doc.id, limit: 5)
            XCTAssertTrue(result.isEmpty)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Statistics Tests

    func testGetArchiveStats() {
        let doc1 = documentManager.createBlankDocument(title: "Story 1")
        let doc2 = documentManager.createBlankDocument(title: "Story 2")

        let collection = archiver.createCollection(name: "Test")
        archiver.addDocumentToCollection(doc1.id, collectionId: collection.id)
        archiver.addDocumentToCollection(doc2.id, collectionId: collection.id)

        archiver.preserveMilestone(documentId: doc1.id, title: "Snap 1", wordCount: 1000)
        archiver.preserveMilestone(documentId: doc2.id, title: "Snap 2", wordCount: 2000)

        let stats = archiver.getArchiveStats()

        XCTAssertEqual(stats["collectionCount"] as? Int, 1)
        XCTAssertEqual(stats["snapshotCount"] as? Int, 2)
        XCTAssertEqual(stats["archivedDocumentCount"] as? Int, 2)
        XCTAssertGreaterThan(stats["totalWordsArchived"] as? Int ?? 0, 0)
    }

    // MARK: - Organization Tests

    func testOrganizeByTagsWithoutAI() {
        var doc = documentManager.createBlankDocument(title: "Story")
        doc.metadata.tags = ["fantasy", "dragon"]
        documentManager.updateDocument(doc)

        let expectation = XCTestExpectation(description: "Tags organized")
        Task {
            let tags = try await archiver.organizeByTags([doc.id])
            XCTAssertEqual(tags[doc.id], ["dragon", "fantasy"])
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testOrganizeByTagsNonexistentDocument() {
        let docId = UUID()
        let expectation = XCTestExpectation(description: "Tags organized")
        Task {
            let tags = try await archiver.organizeByTags([docId])
            XCTAssertEqual(tags[docId], [])
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Profile Tests

    func testProfileInitialization() {
        let profile = ArchiverProfile(name: "My Archive")

        XCTAssertEqual(profile.name, "My Archive")
        XCTAssertTrue(profile.collections.isEmpty)
        XCTAssertTrue(profile.snapshots.isEmpty)
    }

    func testProfilePersistence() {
        let profile = ArchiverProfile(name: "Test Archive")
        let snap = ArchiveSnapshot(
            documentId: UUID(),
            title: "Test",
            summary: "Test summary"
        )
        var mutableProfile = profile
        mutableProfile.snapshots.append(snap)

        let encoder = JSONEncoder()
        let encoded = try! encoder.encode(mutableProfile)

        let decoder = JSONDecoder()
        let decoded = try! decoder.decode(ArchiverProfile.self, from: encoded)

        XCTAssertEqual(decoded.name, "Test Archive")
        XCTAssertEqual(decoded.snapshots.count, 1)
        XCTAssertEqual(decoded.snapshots[0].title, "Test")
    }

    // MARK: - Codable Tests

    func testArchiveSnapshotCodable() {
        let original = ArchiveSnapshot(
            documentId: UUID(),
            title: "Milestone",
            wordCount: 5000,
            summary: "Test summary",
            tags: ["test"]
        )

        let encoder = JSONEncoder()
        let data = try! encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try! decoder.decode(ArchiveSnapshot.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.title, original.title)
        XCTAssertEqual(decoded.wordCount, original.wordCount)
        XCTAssertEqual(decoded.summary, original.summary)
        XCTAssertEqual(decoded.tags, original.tags)
    }

    func testArchiveCollectionCodable() {
        let original = ArchiveCollection(
            name: "Test Collection",
            description: "A test",
            tags: ["test"],
            theme: "dark"
        )

        let encoder = JSONEncoder()
        let data = try! encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try! decoder.decode(ArchiveCollection.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.name, original.name)
        XCTAssertEqual(decoded.theme, original.theme)
    }
}
