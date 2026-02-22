import XCTest
@testable import WritersApp

final class DoltVersionControlServiceTests: XCTestCase {
    var databaseManager: DatabaseManager!
    var vcService: DoltVersionControlService!
    var testDatabasePath: String!

    override func setUp() {
        super.setUp()
        // Create a unique database path for each test
        testDatabasePath = "/tmp/test_vc_\(UUID().uuidString).db"

        // Remove any existing test database
        try? FileManager.default.removeItem(atPath: testDatabasePath)

        databaseManager = DatabaseManager(databasePath: testDatabasePath)
        try? databaseManager.initialize()

        vcService = DoltVersionControlService(databaseManager: databaseManager)
    }

    override func tearDown() {
        databaseManager.close()
        try? FileManager.default.removeItem(atPath: testDatabasePath)
        databaseManager = nil
        vcService = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitializeDefaultBranch() throws {
        let mainBranch = try vcService.initializeDefaultBranch()

        XCTAssertEqual(mainBranch.name, "main")
        XCTAssertTrue(mainBranch.isActive)
        XCTAssertNil(mainBranch.headCommitId)
    }

    func testInitializeDefaultBranchIdempotent() throws {
        let first = try vcService.initializeDefaultBranch()
        let second = try vcService.initializeDefaultBranch()

        XCTAssertEqual(first.id, second.id)
        XCTAssertEqual(first.name, second.name)
    }

    // MARK: - Branch Operations Tests

    func testListBranches() throws {
        try vcService.initializeDefaultBranch()

        let branches = try vcService.listBranches()

        XCTAssertEqual(branches.count, 1)
        XCTAssertEqual(branches.first?.name, "main")
    }

    func testCurrentBranchWhenNoBranchCheckedOut() throws {
        let current = try vcService.currentBranch()
        XCTAssertNil(current)
    }

    func testCurrentBranchAfterInitialization() throws {
        try vcService.initializeDefaultBranch()

        let current = try vcService.currentBranch()

        XCTAssertNotNil(current)
        XCTAssertEqual(current?.name, "main")
        XCTAssertTrue(current?.isActive ?? false)
    }

    func testCheckoutNewBranch() throws {
        try vcService.initializeDefaultBranch()

        let featureBranch = try vcService.checkoutBranch(name: "feature-1", createNew: true)

        XCTAssertEqual(featureBranch.name, "feature-1")
        XCTAssertTrue(featureBranch.isActive)

        let current = try vcService.currentBranch()
        XCTAssertEqual(current?.name, "feature-1")
    }

    func testCheckoutNewBranchInheritsHeadCommit() throws {
        try vcService.initializeDefaultBranch()

        // Create a commit on main
        let doc = createTestDocument(title: "Test Doc", content: "Content")
        let commit = try vcService.commit(message: "First commit", documents: [doc])

        // Create new branch
        let featureBranch = try vcService.checkoutBranch(name: "feature", createNew: true)

        // Feature branch should inherit main's head commit
        XCTAssertEqual(featureBranch.headCommitId, commit.id)
    }

    func testCheckoutExistingBranch() throws {
        try vcService.initializeDefaultBranch()
        try vcService.checkoutBranch(name: "feature", createNew: true)

        // Switch back to main
        let mainBranch = try vcService.checkoutBranch(name: "main", createNew: false)

        XCTAssertEqual(mainBranch.name, "main")
        XCTAssertTrue(mainBranch.isActive)

        let current = try vcService.currentBranch()
        XCTAssertEqual(current?.name, "main")
    }

    func testCheckoutNonexistentBranchThrowsError() throws {
        try vcService.initializeDefaultBranch()

        XCTAssertThrowsError(try vcService.checkoutBranch(name: "nonexistent", createNew: false)) { error in
            guard case VersionControlError.branchNotFound(let name) = error else {
                XCTFail("Expected branchNotFound error")
                return
            }
            XCTAssertEqual(name, "nonexistent")
        }
    }

    func testCreateBranchThatAlreadyExistsThrowsError() throws {
        try vcService.initializeDefaultBranch()

        XCTAssertThrowsError(try vcService.checkoutBranch(name: "main", createNew: true)) { error in
            guard case VersionControlError.branchAlreadyExists(let name) = error else {
                XCTFail("Expected branchAlreadyExists error")
                return
            }
            XCTAssertEqual(name, "main")
        }
    }

    // MARK: - Commit Operations Tests

    func testCommitOnActiveBranch() throws {
        try vcService.initializeDefaultBranch()

        let doc = createTestDocument(title: "Novel", content: "Once upon a time...")
        let commit = try vcService.commit(message: "Initial draft", documents: [doc])

        XCTAssertEqual(commit.message, "Initial draft")
        XCTAssertNotNil(commit.timestamp)
        XCTAssertNil(commit.parentCommitId)
    }

    func testCommitUpdatesHeadCommit() throws {
        try vcService.initializeDefaultBranch()

        let doc = createTestDocument(title: "Doc", content: "Content")
        let commit = try vcService.commit(message: "First commit", documents: [doc])

        let current = try vcService.currentBranch()
        XCTAssertEqual(current?.headCommitId, commit.id)
    }

    func testSecondCommitHasParent() throws {
        try vcService.initializeDefaultBranch()

        let doc = createTestDocument(title: "Doc", content: "First version")
        let commit1 = try vcService.commit(message: "First commit", documents: [doc])

        let doc2 = createTestDocument(id: doc.id, title: "Doc", content: "Second version")
        let commit2 = try vcService.commit(message: "Second commit", documents: [doc2])

        XCTAssertEqual(commit2.parentCommitId, commit1.id)
    }

    func testCommitWithoutActiveBranchThrowsError() throws {
        let doc = createTestDocument(title: "Doc", content: "Content")

        XCTAssertThrowsError(try vcService.commit(message: "Test", documents: [doc])) { error in
            guard case VersionControlError.noActiveBranch = error else {
                XCTFail("Expected noActiveBranch error")
                return
            }
        }
    }

    func testCommitWithMultipleDocuments() throws {
        try vcService.initializeDefaultBranch()

        let doc1 = createTestDocument(title: "Doc 1", content: "Content 1")
        let doc2 = createTestDocument(title: "Doc 2", content: "Content 2")
        let doc3 = createTestDocument(title: "Doc 3", content: "Content 3")

        let commit = try vcService.commit(
            message: "Multi-doc commit",
            documents: [doc1, doc2, doc3]
        )

        let snapshots = try databaseManager.getVCSnapshots(commitId: commit.id)
        XCTAssertEqual(snapshots.count, 3)
    }

    func testCommitWithAuthorId() throws {
        try vcService.initializeDefaultBranch()

        let doc = createTestDocument(title: "Doc", content: "Content")
        let commit = try vcService.commit(
            message: "Authored commit",
            documents: [doc],
            authorId: "user-123"
        )

        XCTAssertEqual(commit.authorId, "user-123")
    }

    func testLog() throws {
        try vcService.initializeDefaultBranch()

        let doc = createTestDocument(title: "Doc", content: "v1")
        try vcService.commit(message: "Commit 1", documents: [doc])

        let doc2 = createTestDocument(id: doc.id, title: "Doc", content: "v2")
        try vcService.commit(message: "Commit 2", documents: [doc2])

        let doc3 = createTestDocument(id: doc.id, title: "Doc", content: "v3")
        try vcService.commit(message: "Commit 3", documents: [doc3])

        let log = try vcService.log(branch: "main")

        XCTAssertEqual(log.count, 3)
        XCTAssertEqual(log[0].message, "Commit 1")
        XCTAssertEqual(log[1].message, "Commit 2")
        XCTAssertEqual(log[2].message, "Commit 3")
    }

    func testLogOnNonexistentBranchThrowsError() throws {
        try vcService.initializeDefaultBranch()

        XCTAssertThrowsError(try vcService.log(branch: "nonexistent")) { error in
            guard case VersionControlError.branchNotFound = error else {
                XCTFail("Expected branchNotFound error")
                return
            }
        }
    }

    // MARK: - Diff Operations Tests

    func testDiffBetweenBranchesWithAddedDocument() throws {
        try vcService.initializeDefaultBranch()

        let doc1 = createTestDocument(title: "Original Doc", content: "Original content")
        try vcService.commit(message: "Main commit", documents: [doc1])

        try vcService.checkoutBranch(name: "feature", createNew: true)

        let doc2 = createTestDocument(title: "New Doc", content: "New content")
        try vcService.commit(message: "Feature commit", documents: [doc1, doc2])

        let diffs = try vcService.diff(fromBranch: "main", toBranch: "feature")

        let addedDiff = diffs.first(where: { $0.documentId == doc2.id })
        XCTAssertNotNil(addedDiff)
        XCTAssertEqual(addedDiff?.changeType, .added)
        XCTAssertEqual(addedDiff?.title, "New Doc")
    }

    func testDiffBetweenBranchesWithModifiedDocument() throws {
        try vcService.initializeDefaultBranch()

        let doc = createTestDocument(title: "Doc", content: "Original content")
        try vcService.commit(message: "Main commit", documents: [doc])

        try vcService.checkoutBranch(name: "feature", createNew: true)

        let modifiedDoc = createTestDocument(id: doc.id, title: "Doc", content: "Modified content")
        try vcService.commit(message: "Feature commit", documents: [modifiedDoc])

        let diffs = try vcService.diff(fromBranch: "main", toBranch: "feature")

        let modifiedDiff = diffs.first(where: { $0.documentId == doc.id })
        XCTAssertNotNil(modifiedDiff)
        XCTAssertEqual(modifiedDiff?.changeType, .modified)
        XCTAssertEqual(modifiedDiff?.fromContent, "Original content")
        XCTAssertEqual(modifiedDiff?.toContent, "Modified content")
    }

    func testDiffBetweenBranchesWithDeletedDocument() throws {
        try vcService.initializeDefaultBranch()

        let doc1 = createTestDocument(title: "Doc 1", content: "Content 1")
        let doc2 = createTestDocument(title: "Doc 2", content: "Content 2")
        try vcService.commit(message: "Main commit", documents: [doc1, doc2])

        try vcService.checkoutBranch(name: "feature", createNew: true)

        // Only commit doc1, effectively deleting doc2
        try vcService.commit(message: "Feature commit", documents: [doc1])

        let diffs = try vcService.diff(fromBranch: "main", toBranch: "feature")

        let deletedDiff = diffs.first(where: { $0.documentId == doc2.id })
        XCTAssertNotNil(deletedDiff)
        XCTAssertEqual(deletedDiff?.changeType, .deleted)
        XCTAssertEqual(deletedDiff?.fromContent, "Content 2")
        XCTAssertNil(deletedDiff?.toContent)
    }

    func testDiffBetweenBranchesWithUnchangedDocument() throws {
        try vcService.initializeDefaultBranch()

        let doc = createTestDocument(title: "Doc", content: "Unchanged content")
        try vcService.commit(message: "Main commit", documents: [doc])

        try vcService.checkoutBranch(name: "feature", createNew: true)

        // Commit the same document without changes
        try vcService.commit(message: "Feature commit", documents: [doc])

        let diffs = try vcService.diff(fromBranch: "main", toBranch: "feature")

        let unchangedDiff = diffs.first(where: { $0.documentId == doc.id })
        XCTAssertNotNil(unchangedDiff)
        XCTAssertEqual(unchangedDiff?.changeType, .unchanged)
    }

    func testDiffBetweenCommits() throws {
        try vcService.initializeDefaultBranch()

        let doc = createTestDocument(title: "Doc", content: "Version 1")
        let commit1 = try vcService.commit(message: "Commit 1", documents: [doc])

        let modifiedDoc = createTestDocument(id: doc.id, title: "Doc", content: "Version 2")
        let commit2 = try vcService.commit(message: "Commit 2", documents: [modifiedDoc])

        let diffs = try vcService.diff(fromCommitId: commit1.id, toCommitId: commit2.id)

        XCTAssertEqual(diffs.count, 1)
        XCTAssertEqual(diffs.first?.changeType, .modified)
        XCTAssertEqual(diffs.first?.fromContent, "Version 1")
        XCTAssertEqual(diffs.first?.toContent, "Version 2")
    }

    func testDiffWordCountDelta() throws {
        try vcService.initializeDefaultBranch()

        let doc = createTestDocument(title: "Doc", content: "One two three")
        let commit1 = try vcService.commit(message: "Commit 1", documents: [doc])

        let modifiedDoc = createTestDocument(id: doc.id, title: "Doc", content: "One two three four five six")
        let commit2 = try vcService.commit(message: "Commit 2", documents: [modifiedDoc])

        let diffs = try vcService.diff(fromCommitId: commit1.id, toCommitId: commit2.id)

        XCTAssertEqual(diffs.first?.wordCountDelta, 3)
    }

    // MARK: - Time Travel Tests

    func testQueryAsOf() throws {
        try vcService.initializeDefaultBranch()

        let doc = createTestDocument(title: "Doc", content: "Version 1")
        try vcService.commit(message: "Commit 1", documents: [doc])

        let timestamp = Date()
        Thread.sleep(forTimeInterval: 0.1)

        let modifiedDoc = createTestDocument(id: doc.id, title: "Doc", content: "Version 2")
        try vcService.commit(message: "Commit 2", documents: [modifiedDoc])

        let historical = try vcService.query(asOf: timestamp)

        XCTAssertEqual(historical.count, 1)
        XCTAssertEqual(historical.first?.content, "Version 1")
    }

    func testHistoryOfDocument() throws {
        try vcService.initializeDefaultBranch()

        let docId = UUID()
        let doc1 = createTestDocument(id: docId, title: "Doc", content: "Version 1")
        try vcService.commit(message: "Commit 1", documents: [doc1])

        let doc2 = createTestDocument(id: docId, title: "Doc", content: "Version 2")
        try vcService.commit(message: "Commit 2", documents: [doc2])

        let doc3 = createTestDocument(id: docId, title: "Doc", content: "Version 3")
        try vcService.commit(message: "Commit 3", documents: [doc3])

        let history = try vcService.history(of: docId)

        XCTAssertEqual(history.count, 3)
        XCTAssertEqual(history[0].content, "Version 1")
        XCTAssertEqual(history[1].content, "Version 2")
        XCTAssertEqual(history[2].content, "Version 3")
    }

    // MARK: - Merge Tests

    func testFastForwardMerge() throws {
        try vcService.initializeDefaultBranch()

        // Create feature branch before any commits
        try vcService.checkoutBranch(name: "feature", createNew: true)

        let doc = createTestDocument(title: "Doc", content: "Content")
        try vcService.commit(message: "Feature commit", documents: [doc])

        // Switch back to main (which has no commits)
        try vcService.checkoutBranch(name: "main", createNew: false)

        // Merge feature into main
        let result = try vcService.merge(fromBranch: "feature", into: "main")

        XCTAssertTrue(result.success)
        XCTAssertEqual(result.strategy, .fastForward)
        XCTAssertEqual(result.diffCount, 1)

        // Main should now point to feature's commit
        let mainBranch = try vcService.currentBranch()
        XCTAssertNotNil(mainBranch?.headCommitId)
    }

    func testThreeWayMerge() throws {
        try vcService.initializeDefaultBranch()

        let doc = createTestDocument(title: "Doc", content: "Original")
        try vcService.commit(message: "Initial commit", documents: [doc])

        // Create feature branch
        try vcService.checkoutBranch(name: "feature", createNew: true)

        let featureDoc = createTestDocument(id: doc.id, title: "Doc", content: "Feature changes")
        try vcService.commit(message: "Feature commit", documents: [featureDoc])

        // Switch back to main and make changes
        try vcService.checkoutBranch(name: "main", createNew: false)

        let mainDoc = createTestDocument(id: doc.id, title: "Doc", content: "Main changes")
        try vcService.commit(message: "Main commit", documents: [mainDoc])

        // Merge feature into main
        let result = try vcService.merge(fromBranch: "feature", into: "main")

        XCTAssertTrue(result.success)
        XCTAssertEqual(result.strategy, .threeWay)
        XCTAssertNotNil(result.commitId)
        XCTAssertGreaterThan(result.diffCount, 0)
    }

    func testMergeCreatesCommitWithBothParents() throws {
        try vcService.initializeDefaultBranch()

        let doc = createTestDocument(title: "Doc", content: "Original")
        let initialCommit = try vcService.commit(message: "Initial", documents: [doc])

        try vcService.checkoutBranch(name: "feature", createNew: true)
        let featureDoc = createTestDocument(id: doc.id, title: "Doc", content: "Feature")
        try vcService.commit(message: "Feature", documents: [featureDoc])

        try vcService.checkoutBranch(name: "main", createNew: false)
        let mainDoc = createTestDocument(id: doc.id, title: "Doc", content: "Main")
        let mainCommit = try vcService.commit(message: "Main", documents: [mainDoc])

        let featureBranch = try databaseManager.getVCBranch(name: "feature")
        let featureCommitId = featureBranch?.headCommitId

        let mergeResult = try vcService.merge(fromBranch: "feature", into: "main")

        guard let mergeCommitId = mergeResult.commitId else {
            XCTFail("Merge commit ID should not be nil")
            return
        }

        let mainBranch = try databaseManager.getVCBranch(name: "main")
        let commits = try databaseManager.getVCCommits(branchId: mainBranch!.id)
        let mergeCommit = commits.first(where: { $0.id == mergeCommitId })

        XCTAssertNotNil(mergeCommit)
        XCTAssertEqual(mergeCommit?.parentCommitId, mainCommit.id)
        XCTAssertEqual(mergeCommit?.secondParentCommitId, featureCommitId)
    }

    func testMergeAddsNewDocumentsFromSourceBranch() throws {
        try vcService.initializeDefaultBranch()

        let doc1 = createTestDocument(title: "Doc 1", content: "Content 1")
        try vcService.commit(message: "Main commit", documents: [doc1])

        try vcService.checkoutBranch(name: "feature", createNew: true)

        let doc2 = createTestDocument(title: "Doc 2", content: "Content 2")
        try vcService.commit(message: "Feature commit", documents: [doc1, doc2])

        try vcService.checkoutBranch(name: "main", createNew: false)

        let result = try vcService.merge(fromBranch: "feature", into: "main")

        XCTAssertTrue(result.success)

        // Check that merged commit has both documents
        let mainBranch = try databaseManager.getVCBranch(name: "main")
        guard let headCommitId = mainBranch?.headCommitId else {
            XCTFail("Main branch should have a head commit")
            return
        }

        let snapshots = try databaseManager.getVCSnapshots(commitId: headCommitId)
        XCTAssertEqual(snapshots.count, 2)
        XCTAssertTrue(snapshots.contains(where: { $0.documentId == doc1.id }))
        XCTAssertTrue(snapshots.contains(where: { $0.documentId == doc2.id }))
    }

    func testMergeNonexistentBranchThrowsError() throws {
        try vcService.initializeDefaultBranch()

        XCTAssertThrowsError(try vcService.merge(fromBranch: "nonexistent", into: "main")) { error in
            guard case VersionControlError.branchNotFound = error else {
                XCTFail("Expected branchNotFound error")
                return
            }
        }
    }

    // MARK: - Edge Cases and Regression Tests

    func testCommitEmptyDocumentList() throws {
        try vcService.initializeDefaultBranch()

        let commit = try vcService.commit(message: "Empty commit", documents: [])

        XCTAssertEqual(commit.message, "Empty commit")

        let snapshots = try databaseManager.getVCSnapshots(commitId: commit.id)
        XCTAssertEqual(snapshots.count, 0)
    }

    func testMultipleBranchesWithIndependentHistory() throws {
        try vcService.initializeDefaultBranch()

        let mainDoc = createTestDocument(title: "Main Doc", content: "Main content")
        try vcService.commit(message: "Main commit", documents: [mainDoc])

        try vcService.checkoutBranch(name: "feature-a", createNew: true)
        let featureADoc = createTestDocument(title: "Feature A Doc", content: "Feature A content")
        try vcService.commit(message: "Feature A commit", documents: [featureADoc])

        try vcService.checkoutBranch(name: "main", createNew: false)
        try vcService.checkoutBranch(name: "feature-b", createNew: true)
        let featureBDoc = createTestDocument(title: "Feature B Doc", content: "Feature B content")
        try vcService.commit(message: "Feature B commit", documents: [featureBDoc])

        let branches = try vcService.listBranches()
        XCTAssertEqual(branches.count, 3)

        let mainLog = try vcService.log(branch: "main")
        let featureALog = try vcService.log(branch: "feature-a")
        let featureBLog = try vcService.log(branch: "feature-b")

        XCTAssertEqual(mainLog.count, 1)
        XCTAssertEqual(featureALog.count, 2) // Inherits from main + its own
        XCTAssertEqual(featureBLog.count, 2) // Inherits from main + its own
    }

    func testDiffWithTitleChange() throws {
        try vcService.initializeDefaultBranch()

        let doc = createTestDocument(title: "Original Title", content: "Content")
        let commit1 = try vcService.commit(message: "Commit 1", documents: [doc])

        let renamedDoc = createTestDocument(id: doc.id, title: "New Title", content: "Content")
        let commit2 = try vcService.commit(message: "Commit 2", documents: [renamedDoc])

        let diffs = try vcService.diff(fromCommitId: commit1.id, toCommitId: commit2.id)

        XCTAssertEqual(diffs.first?.changeType, .modified)
        XCTAssertEqual(diffs.first?.title, "New Title")
    }

    func testLargeDocumentCommit() throws {
        try vcService.initializeDefaultBranch()

        let largeContent = String(repeating: "Lorem ipsum dolor sit amet. ", count: 1000)
        let doc = createTestDocument(title: "Large Doc", content: largeContent)

        let commit = try vcService.commit(message: "Large commit", documents: [doc])

        let snapshots = try databaseManager.getVCSnapshots(commitId: commit.id)
        XCTAssertEqual(snapshots.count, 1)
        XCTAssertEqual(snapshots.first?.content, largeContent)
    }

    // MARK: - Helper Methods

    private func createTestDocument(
        id: UUID = UUID(),
        title: String,
        content: String
    ) -> Document {
        return Document(
            id: id,
            title: title,
            content: content,
            category: .novel
        )
    }
}