import XCTest
@testable import WritersApp

final class DoltVersionControlServiceTests: XCTestCase {
    var databaseManager: DatabaseManager!
    var versionControl: DoltVersionControlService!
    var testDatabasePath: String!

    override func setUp() {
        super.setUp()
        testDatabasePath = "/tmp/test_vc_\(UUID().uuidString).db"
        try? FileManager.default.removeItem(atPath: testDatabasePath)

        databaseManager = DatabaseManager(databasePath: testDatabasePath)
        try? databaseManager.initialize()
        versionControl = DoltVersionControlService(databaseManager: databaseManager)
    }

    override func tearDown() {
        databaseManager.close()
        try? FileManager.default.removeItem(atPath: testDatabasePath)
        databaseManager = nil
        versionControl = nil
        super.tearDown()
    }

    // MARK: - Branch Operations Tests

    func testInitializeDefaultBranch() throws {
        let branch = try versionControl.initializeDefaultBranch()

        XCTAssertEqual(branch.name, "main")
        XCTAssertTrue(branch.isActive)
        XCTAssertNil(branch.headCommitId)
    }

    func testInitializeDefaultBranchIdempotent() throws {
        let branch1 = try versionControl.initializeDefaultBranch()
        let branch2 = try versionControl.initializeDefaultBranch()

        XCTAssertEqual(branch1.id, branch2.id)
        XCTAssertEqual(branch1.name, branch2.name)
    }

    func testListBranchesEmpty() throws {
        let branches = try versionControl.listBranches()
        XCTAssertEqual(branches.count, 0)
    }

    func testListBranches() throws {
        try versionControl.initializeDefaultBranch()
        try versionControl.checkoutBranch(name: "feature-1", createNew: true)
        try versionControl.checkoutBranch(name: "feature-2", createNew: true)

        let branches = try versionControl.listBranches()
        XCTAssertEqual(branches.count, 3)
        XCTAssertTrue(branches.contains(where: { $0.name == "main" }))
        XCTAssertTrue(branches.contains(where: { $0.name == "feature-1" }))
        XCTAssertTrue(branches.contains(where: { $0.name == "feature-2" }))
    }

    func testCurrentBranchNone() throws {
        let current = try versionControl.currentBranch()
        XCTAssertNil(current)
    }

    func testCurrentBranch() throws {
        try versionControl.initializeDefaultBranch()

        let current = try versionControl.currentBranch()
        XCTAssertNotNil(current)
        XCTAssertEqual(current?.name, "main")
        XCTAssertTrue(current?.isActive ?? false)
    }

    func testCheckoutBranchCreateNew() throws {
        let branch = try versionControl.checkoutBranch(name: "feature", createNew: true)

        XCTAssertEqual(branch.name, "feature")
        XCTAssertTrue(branch.isActive)
    }

    func testCheckoutBranchCreateDuplicate() throws {
        try versionControl.checkoutBranch(name: "feature", createNew: true)

        XCTAssertThrowsError(try versionControl.checkoutBranch(name: "feature", createNew: true)) { error in
            XCTAssertTrue(error is VersionControlError)
            if case VersionControlError.branchAlreadyExists(let name) = error {
                XCTAssertEqual(name, "feature")
            }
        }
    }

    func testCheckoutExistingBranch() throws {
        try versionControl.checkoutBranch(name: "main", createNew: true)
        try versionControl.checkoutBranch(name: "feature", createNew: true)

        let switched = try versionControl.checkoutBranch(name: "main", createNew: false)
        XCTAssertEqual(switched.name, "main")
        XCTAssertTrue(switched.isActive)

        let current = try versionControl.currentBranch()
        XCTAssertEqual(current?.name, "main")
    }

    func testCheckoutNonExistentBranch() throws {
        XCTAssertThrowsError(try versionControl.checkoutBranch(name: "nonexistent", createNew: false)) { error in
            XCTAssertTrue(error is VersionControlError)
            if case VersionControlError.branchNotFound(let name) = error {
                XCTAssertEqual(name, "nonexistent")
            }
        }
    }

    func testCheckoutNewBranchDoesNotInheritHead() throws {
        try versionControl.initializeDefaultBranch()

        let doc = Document(title: "Test", content: "Content", category: .novel)
        try versionControl.commit(message: "Initial commit", documents: [doc])

        let featureBranch = try versionControl.checkoutBranch(name: "feature", createNew: true)
        XCTAssertNil(featureBranch.headCommitId)
    }

    // MARK: - Commit Operations Tests

    func testCommitWithNoActiveBranch() throws {
        let doc = Document(title: "Test", content: "Content", category: .novel)

        XCTAssertThrowsError(try versionControl.commit(message: "Test", documents: [doc])) { error in
            XCTAssertTrue(error is VersionControlError)
            if case VersionControlError.noActiveBranch = error {
                // Expected
            } else {
                XCTFail("Expected noActiveBranch error")
            }
        }
    }

    func testCommitSingleDocument() throws {
        try versionControl.initializeDefaultBranch()

        let doc = Document(title: "My Novel", content: "Once upon a time...", category: .novel)
        let commit = try versionControl.commit(message: "Initial commit", documents: [doc])

        XCTAssertEqual(commit.message, "Initial commit")
        XCTAssertNil(commit.parentCommitId)

        let snapshots = try databaseManager.getVCSnapshots(commitId: commit.id)
        XCTAssertEqual(snapshots.count, 1)
        XCTAssertEqual(snapshots.first?.title, "My Novel")
        XCTAssertEqual(snapshots.first?.content, "Once upon a time...")
    }

    func testCommitMultipleDocuments() throws {
        try versionControl.initializeDefaultBranch()

        let docs = [
            Document(title: "Doc 1", content: "Content 1", category: .novel),
            Document(title: "Doc 2", content: "Content 2", category: .essay),
            Document(title: "Doc 3", content: "Content 3", category: .article)
        ]

        let commit = try versionControl.commit(message: "Multi-doc commit", documents: docs)
        let snapshots = try databaseManager.getVCSnapshots(commitId: commit.id)

        XCTAssertEqual(snapshots.count, 3)
        XCTAssertTrue(snapshots.contains(where: { $0.title == "Doc 1" }))
        XCTAssertTrue(snapshots.contains(where: { $0.title == "Doc 2" }))
        XCTAssertTrue(snapshots.contains(where: { $0.title == "Doc 3" }))
    }

    func testCommitUpdatesHeadCommit() throws {
        try versionControl.initializeDefaultBranch()

        let doc = Document(title: "Test", content: "Content", category: .novel)
        let commit = try versionControl.commit(message: "Initial", documents: [doc])

        let branch = try versionControl.currentBranch()
        XCTAssertEqual(branch?.headCommitId, commit.id)
    }

    func testCommitWithParent() throws {
        try versionControl.initializeDefaultBranch()

        let doc1 = Document(title: "Test", content: "v1", category: .novel)
        let commit1 = try versionControl.commit(message: "First", documents: [doc1])

        let doc2 = Document(title: "Test", content: "v2", category: .novel)
        let commit2 = try versionControl.commit(message: "Second", documents: [doc2])

        XCTAssertEqual(commit2.parentCommitId, commit1.id)
    }

    func testCommitWithAuthor() throws {
        try versionControl.initializeDefaultBranch()

        let doc = Document(title: "Test", content: "Content", category: .novel)
        let commit = try versionControl.commit(
            message: "Authored commit",
            documents: [doc],
            authorId: "user@example.com"
        )

        XCTAssertEqual(commit.authorId, "user@example.com")
    }

    func testLog() throws {
        try versionControl.initializeDefaultBranch()

        let doc1 = Document(title: "Test", content: "v1", category: .novel)
        try versionControl.commit(message: "First commit", documents: [doc1])

        let doc2 = Document(title: "Test", content: "v2", category: .novel)
        try versionControl.commit(message: "Second commit", documents: [doc2])

        let doc3 = Document(title: "Test", content: "v3", category: .novel)
        try versionControl.commit(message: "Third commit", documents: [doc3])

        let log = try versionControl.log(branch: "main")
        XCTAssertEqual(log.count, 3)
        XCTAssertEqual(log[0].message, "First commit")
        XCTAssertEqual(log[1].message, "Second commit")
        XCTAssertEqual(log[2].message, "Third commit")
    }

    func testLogNonExistentBranch() throws {
        XCTAssertThrowsError(try versionControl.log(branch: "nonexistent")) { error in
            XCTAssertTrue(error is VersionControlError)
            if case VersionControlError.branchNotFound = error {
                // Expected
            } else {
                XCTFail("Expected branchNotFound error")
            }
        }
    }

    // MARK: - Diff Operations Tests

    func testDiffAddedDocument() throws {
        try versionControl.initializeDefaultBranch()

        let commit1 = try versionControl.commit(message: "Empty", documents: [])

        let doc = Document(title: "New Doc", content: "New content", category: .novel)
        let commit2 = try versionControl.commit(message: "Added", documents: [doc])

        let diffs = try versionControl.diff(fromCommitId: commit1.id, toCommitId: commit2.id)

        XCTAssertEqual(diffs.count, 1)
        XCTAssertEqual(diffs[0].changeType, .added)
        XCTAssertEqual(diffs[0].title, "New Doc")
        XCTAssertEqual(diffs[0].toContent, "New content")
        XCTAssertNil(diffs[0].fromContent)
    }

    func testDiffDeletedDocument() throws {
        try versionControl.initializeDefaultBranch()

        let doc = Document(title: "Old Doc", content: "Old content", category: .novel)
        let commit1 = try versionControl.commit(message: "With doc", documents: [doc])

        let commit2 = try versionControl.commit(message: "Deleted", documents: [])

        let diffs = try versionControl.diff(fromCommitId: commit1.id, toCommitId: commit2.id)

        XCTAssertEqual(diffs.count, 1)
        XCTAssertEqual(diffs[0].changeType, .deleted)
        XCTAssertEqual(diffs[0].title, "Old Doc")
        XCTAssertEqual(diffs[0].fromContent, "Old content")
        XCTAssertNil(diffs[0].toContent)
    }

    func testDiffModifiedDocument() throws {
        try versionControl.initializeDefaultBranch()

        let doc1 = Document(id: UUID(), title: "My Doc", content: "Version 1", category: .novel)
        let commit1 = try versionControl.commit(message: "v1", documents: [doc1])

        let doc2 = Document(id: doc1.id, title: "My Doc Updated", content: "Version 2", category: .novel)
        let commit2 = try versionControl.commit(message: "v2", documents: [doc2])

        let diffs = try versionControl.diff(fromCommitId: commit1.id, toCommitId: commit2.id)

        XCTAssertEqual(diffs.count, 1)
        XCTAssertEqual(diffs[0].changeType, .modified)
        XCTAssertEqual(diffs[0].title, "My Doc Updated")
        XCTAssertEqual(diffs[0].fromContent, "Version 1")
        XCTAssertEqual(diffs[0].toContent, "Version 2")
    }

    func testDiffUnchangedDocument() throws {
        try versionControl.initializeDefaultBranch()

        let doc = Document(id: UUID(), title: "Unchanged", content: "Same content", category: .novel)
        let commit1 = try versionControl.commit(message: "v1", documents: [doc])
        let commit2 = try versionControl.commit(message: "v2", documents: [doc])

        let diffs = try versionControl.diff(fromCommitId: commit1.id, toCommitId: commit2.id)

        XCTAssertEqual(diffs.count, 1)
        XCTAssertEqual(diffs[0].changeType, .unchanged)
    }

    func testDiffBetweenBranches() throws {
        try versionControl.initializeDefaultBranch()

        let doc1 = Document(title: "Doc", content: "Main content", category: .novel)
        try versionControl.commit(message: "Main commit", documents: [doc1])

        try versionControl.checkoutBranch(name: "feature", createNew: true)
        let doc2 = Document(id: doc1.id, title: "Doc", content: "Feature content", category: .novel)
        try versionControl.commit(message: "Feature commit", documents: [doc2])

        let diffs = try versionControl.diff(fromBranch: "main", toBranch: "feature")

        XCTAssertEqual(diffs.count, 1)
        XCTAssertEqual(diffs[0].changeType, .modified)
        XCTAssertEqual(diffs[0].fromContent, "Main content")
        XCTAssertEqual(diffs[0].toContent, "Feature content")
    }

    func testDiffWordCountDelta() throws {
        try versionControl.initializeDefaultBranch()

        let doc1 = Document(id: UUID(), title: "Doc", content: "One two", category: .novel)
        let commit1 = try versionControl.commit(message: "v1", documents: [doc1])

        let doc2 = Document(id: doc1.id, title: "Doc", content: "One two three four five", category: .novel)
        let commit2 = try versionControl.commit(message: "v2", documents: [doc2])

        let diffs = try versionControl.diff(fromCommitId: commit1.id, toCommitId: commit2.id)

        XCTAssertEqual(diffs[0].fromWordCount, 2)
        XCTAssertEqual(diffs[0].toWordCount, 5)
        XCTAssertEqual(diffs[0].wordCountDelta, 3)
    }

    func testDiffMultipleDocuments() throws {
        try versionControl.initializeDefaultBranch()

        let doc1 = Document(id: UUID(), title: "A", content: "Content A", category: .novel)
        let doc2 = Document(id: UUID(), title: "B", content: "Content B", category: .essay)
        let commit1 = try versionControl.commit(message: "v1", documents: [doc1, doc2])

        let doc1Updated = Document(id: doc1.id, title: "A", content: "Updated A", category: .novel)
        let doc3 = Document(id: UUID(), title: "C", content: "Content C", category: .article)
        let commit2 = try versionControl.commit(message: "v2", documents: [doc1Updated, doc3])

        let diffs = try versionControl.diff(fromCommitId: commit1.id, toCommitId: commit2.id)

        XCTAssertEqual(diffs.count, 3)
        XCTAssertTrue(diffs.contains(where: { $0.title == "A" && $0.changeType == .modified }))
        XCTAssertTrue(diffs.contains(where: { $0.title == "B" && $0.changeType == .deleted }))
        XCTAssertTrue(diffs.contains(where: { $0.title == "C" && $0.changeType == .added }))
    }

    func testDiffSorted() throws {
        try versionControl.initializeDefaultBranch()

        let commit1 = try versionControl.commit(message: "Empty", documents: [])

        let docs = [
            Document(title: "Zebra", content: "Z", category: .novel),
            Document(title: "Apple", content: "A", category: .novel),
            Document(title: "Mango", content: "M", category: .novel)
        ]
        let commit2 = try versionControl.commit(message: "Docs", documents: docs)

        let diffs = try versionControl.diff(fromCommitId: commit1.id, toCommitId: commit2.id)

        XCTAssertEqual(diffs[0].title, "Apple")
        XCTAssertEqual(diffs[1].title, "Mango")
        XCTAssertEqual(diffs[2].title, "Zebra")
    }

    // MARK: - Time Travel Tests

    func testQueryAsOfEmpty() throws {
        let snapshots = try versionControl.query(asOf: Date())
        XCTAssertEqual(snapshots.count, 0)
    }

    func testQueryAsOfSingleCommit() throws {
        try versionControl.initializeDefaultBranch()

        let doc = Document(title: "Doc", content: "Content", category: .novel)
        try versionControl.commit(message: "Commit", documents: [doc])

        let snapshots = try versionControl.query(asOf: Date())
        XCTAssertEqual(snapshots.count, 1)
        XCTAssertEqual(snapshots[0].title, "Doc")
    }

    func testQueryAsOfBeforeCommit() throws {
        try versionControl.initializeDefaultBranch()

        let pastDate = Date(timeIntervalSince1970: 1000)

        let doc = Document(title: "Doc", content: "Content", category: .novel)
        try versionControl.commit(message: "Commit", documents: [doc])

        let snapshots = try versionControl.query(asOf: pastDate)
        XCTAssertEqual(snapshots.count, 0)
    }

    func testQueryAsOfTimeTravelBetweenCommits() throws {
        try versionControl.initializeDefaultBranch()

        let doc1 = Document(id: UUID(), title: "Doc", content: "Version 1", category: .novel)
        let commit1 = try versionControl.commit(message: "v1", documents: [doc1])

        Thread.sleep(forTimeInterval: 0.1)

        let queryDate = Date()

        Thread.sleep(forTimeInterval: 0.1)

        let doc2 = Document(id: doc1.id, title: "Doc", content: "Version 2", category: .novel)
        try versionControl.commit(message: "v2", documents: [doc2])

        let snapshots = try versionControl.query(asOf: queryDate)
        XCTAssertEqual(snapshots.count, 1)
        XCTAssertEqual(snapshots[0].content, "Version 1")
    }

    func testQueryAsOfMultipleDocuments() throws {
        try versionControl.initializeDefaultBranch()

        let doc1 = Document(id: UUID(), title: "Doc1", content: "Old", category: .novel)
        let doc2 = Document(id: UUID(), title: "Doc2", content: "Old", category: .essay)
        let commit1 = try versionControl.commit(message: "Initial", documents: [doc1, doc2])

        Thread.sleep(forTimeInterval: 0.1)
        let queryDate = Date()
        Thread.sleep(forTimeInterval: 0.1)

        let doc1Updated = Document(id: doc1.id, title: "Doc1", content: "New", category: .novel)
        try versionControl.commit(message: "Update", documents: [doc1Updated, doc2])

        let snapshots = try versionControl.query(asOf: queryDate)
        XCTAssertEqual(snapshots.count, 2)
        let doc1Snap = snapshots.first(where: { $0.documentId == doc1.id })
        XCTAssertEqual(doc1Snap?.content, "Old")
    }

    func testHistory() throws {
        try versionControl.initializeDefaultBranch()

        let docId = UUID()
        let doc1 = Document(id: docId, title: "Doc", content: "v1", category: .novel)
        try versionControl.commit(message: "First", documents: [doc1])

        let doc2 = Document(id: docId, title: "Doc", content: "v2", category: .novel)
        try versionControl.commit(message: "Second", documents: [doc2])

        let doc3 = Document(id: docId, title: "Doc", content: "v3", category: .novel)
        try versionControl.commit(message: "Third", documents: [doc3])

        let history = try versionControl.history(of: docId)
        XCTAssertEqual(history.count, 3)
        XCTAssertEqual(history[0].content, "v1")
        XCTAssertEqual(history[1].content, "v2")
        XCTAssertEqual(history[2].content, "v3")
    }

    func testHistoryNonExistentDocument() throws {
        let history = try versionControl.history(of: UUID())
        XCTAssertEqual(history.count, 0)
    }

    // MARK: - Merge Tests

    func testMergeFastForwardTargetHasNoHead() throws {
        try versionControl.initializeDefaultBranch()

        let doc = Document(title: "Doc", content: "Content", category: .novel)
        try versionControl.commit(message: "Main commit", documents: [doc])

        try versionControl.checkoutBranch(name: "empty", createNew: true)
        let emptyBranch = try versionControl.currentBranch()
        XCTAssertNil(emptyBranch?.headCommitId)

        try versionControl.checkoutBranch(name: "main", createNew: false)

        let result = try versionControl.merge(fromBranch: "main", into: "empty")

        XCTAssertTrue(result.success)
        XCTAssertEqual(result.strategy, .fastForward)
        XCTAssertEqual(result.diffCount, 1)

        let emptyBranchAfter = try databaseManager.getVCBranch(name: "empty")
        XCTAssertNotNil(emptyBranchAfter?.headCommitId)
    }

    func testMergeThreeWaySameContent() throws {
        try versionControl.initializeDefaultBranch()

        let doc = Document(id: UUID(), title: "Doc", content: "Content", category: .novel)
        try versionControl.commit(message: "Initial", documents: [doc])

        try versionControl.checkoutBranch(name: "feature", createNew: true)
        try versionControl.commit(message: "Feature work", documents: [doc])

        let result = try versionControl.merge(fromBranch: "feature", into: "main")

        XCTAssertTrue(result.success)
        XCTAssertEqual(result.strategy, .threeWay)
        XCTAssertEqual(result.diffCount, 0)
    }

    func testMergeThreeWayWithChanges() throws {
        try versionControl.initializeDefaultBranch()

        let doc = Document(id: UUID(), title: "Doc", content: "Initial", category: .novel)
        try versionControl.commit(message: "Initial", documents: [doc])

        try versionControl.checkoutBranch(name: "feature", createNew: true)
        let docUpdated = Document(id: doc.id, title: "Doc", content: "Feature change", category: .novel)
        try versionControl.commit(message: "Feature work", documents: [docUpdated])

        let result = try versionControl.merge(fromBranch: "feature", into: "main")

        XCTAssertTrue(result.success)
        XCTAssertEqual(result.strategy, .threeWay)
        XCTAssertEqual(result.diffCount, 1)

        let mainBranch = try databaseManager.getVCBranch(name: "main")
        let mergedSnapshots = try databaseManager.getVCSnapshots(commitId: mainBranch!.headCommitId!)
        XCTAssertEqual(mergedSnapshots.count, 1)
        XCTAssertEqual(mergedSnapshots[0].content, "Feature change")
    }

    func testMergeCreatesCommitWithTwoParents() throws {
        try versionControl.initializeDefaultBranch()

        let doc = Document(title: "Doc", content: "Initial", category: .novel)
        let mainCommit = try versionControl.commit(message: "Main", documents: [doc])

        try versionControl.checkoutBranch(name: "feature", createNew: true)
        let featureCommit = try versionControl.commit(message: "Feature", documents: [doc])

        try versionControl.merge(fromBranch: "feature", into: "main")

        let mainBranch = try databaseManager.getVCBranch(name: "main")
        let commits = try databaseManager.getVCCommits(branchId: mainBranch!.id)
        let mergeCommit = commits.last

        XCTAssertEqual(mergeCommit?.message, "Merge 'feature' into 'main'")
        XCTAssertEqual(mergeCommit?.parentCommitId, mainCommit.id)
        XCTAssertEqual(mergeCommit?.secondParentCommitId, featureCommit.id)
    }

    func testMergeAddsNewDocument() throws {
        try versionControl.initializeDefaultBranch()

        let doc1 = Document(id: UUID(), title: "Doc1", content: "Main", category: .novel)
        try versionControl.commit(message: "Main", documents: [doc1])

        try versionControl.checkoutBranch(name: "feature", createNew: true)
        let doc2 = Document(id: UUID(), title: "Doc2", content: "Feature", category: .essay)
        try versionControl.commit(message: "Feature", documents: [doc1, doc2])

        let result = try versionControl.merge(fromBranch: "feature", into: "main")

        XCTAssertEqual(result.diffCount, 1)

        let mainBranch = try databaseManager.getVCBranch(name: "main")
        let snapshots = try databaseManager.getVCSnapshots(commitId: mainBranch!.headCommitId!)
        XCTAssertEqual(snapshots.count, 2)
        XCTAssertTrue(snapshots.contains(where: { $0.title == "Doc2" }))
    }

    func testMergeNonExistentSourceBranch() throws {
        try versionControl.initializeDefaultBranch()

        XCTAssertThrowsError(try versionControl.merge(fromBranch: "nonexistent", into: "main")) { error in
            XCTAssertTrue(error is VersionControlError)
            if case VersionControlError.branchNotFound(let name) = error {
                XCTAssertEqual(name, "nonexistent")
            }
        }
    }

    func testMergeNonExistentTargetBranch() throws {
        try versionControl.initializeDefaultBranch()

        XCTAssertThrowsError(try versionControl.merge(fromBranch: "main", into: "nonexistent")) { error in
            XCTAssertTrue(error is VersionControlError)
            if case VersionControlError.branchNotFound(let name) = error {
                XCTAssertEqual(name, "nonexistent")
            }
        }
    }

    func testMergeFromBranchWithNoCommits() throws {
        try versionControl.initializeDefaultBranch()

        let doc = Document(title: "Doc", content: "Content", category: .novel)
        try versionControl.commit(message: "Main", documents: [doc])

        try versionControl.checkoutBranch(name: "empty", createNew: true)

        let result = try versionControl.merge(fromBranch: "empty", into: "main")

        XCTAssertTrue(result.success)
        XCTAssertEqual(result.strategy, .fastForward)
        XCTAssertEqual(result.diffCount, 0)
    }

    // MARK: - Integration Tests

    func testCompleteWorkflow() throws {
        // Initialize version control
        try versionControl.initializeDefaultBranch()

        // Create initial document
        let doc = Document(id: UUID(), title: "My Story", content: "Chapter 1: Beginning", category: .novel)
        try versionControl.commit(message: "Initial commit", documents: [doc])

        // Create feature branch
        try versionControl.checkoutBranch(name: "feature/chapter-2", createNew: true)

        // Add second chapter
        let docWithChapter2 = Document(
            id: doc.id,
            title: "My Story",
            content: "Chapter 1: Beginning\n\nChapter 2: Middle",
            category: .novel
        )
        try versionControl.commit(message: "Add chapter 2", documents: [docWithChapter2])

        // Check diff
        let diffs = try versionControl.diff(fromBranch: "main", toBranch: "feature/chapter-2")
        XCTAssertEqual(diffs.count, 1)
        XCTAssertEqual(diffs[0].changeType, .modified)

        // Merge back to main
        let mergeResult = try versionControl.merge(fromBranch: "feature/chapter-2", into: "main")
        XCTAssertTrue(mergeResult.success)

        // Check log
        let log = try versionControl.log(branch: "main")
        XCTAssertEqual(log.count, 2)
        XCTAssertEqual(log.last?.message, "Merge 'feature/chapter-2' into 'main'")
    }

    func testMultipleBranchesWorkflow() throws {
        try versionControl.initializeDefaultBranch()

        let doc = Document(id: UUID(), title: "Doc", content: "Initial", category: .novel)
        try versionControl.commit(message: "Initial", documents: [doc])

        // Create and work on feature-A
        try versionControl.checkoutBranch(name: "feature-A", createNew: true)
        let docA = Document(id: doc.id, title: "Doc", content: "Initial + A", category: .novel)
        try versionControl.commit(message: "Feature A", documents: [docA])

        // Create and work on feature-B
        try versionControl.checkoutBranch(name: "main", createNew: false)
        try versionControl.checkoutBranch(name: "feature-B", createNew: true)
        let docB = Document(id: doc.id, title: "Doc", content: "Initial + B", category: .novel)
        try versionControl.commit(message: "Feature B", documents: [docB])

        // List all branches
        let branches = try versionControl.listBranches()
        XCTAssertEqual(branches.count, 3)

        // Current branch should be feature-B
        let current = try versionControl.currentBranch()
        XCTAssertEqual(current?.name, "feature-B")
    }

    func testTimeTravelWorkflow() throws {
        try versionControl.initializeDefaultBranch()

        let doc = Document(id: UUID(), title: "Doc", content: "v1", category: .novel)
        try versionControl.commit(message: "v1", documents: [doc])

        Thread.sleep(forTimeInterval: 0.1)
        let afterV1 = Date()
        Thread.sleep(forTimeInterval: 0.1)

        let docV2 = Document(id: doc.id, title: "Doc", content: "v2", category: .novel)
        try versionControl.commit(message: "v2", documents: [docV2])

        Thread.sleep(forTimeInterval: 0.1)
        let afterV2 = Date()
        Thread.sleep(forTimeInterval: 0.1)

        let docV3 = Document(id: doc.id, title: "Doc", content: "v3", category: .novel)
        try versionControl.commit(message: "v3", documents: [docV3])

        // Query at different points in time
        let snapshotV1 = try versionControl.query(asOf: afterV1)
        XCTAssertEqual(snapshotV1[0].content, "v1")

        let snapshotV2 = try versionControl.query(asOf: afterV2)
        XCTAssertEqual(snapshotV2[0].content, "v2")

        let snapshotNow = try versionControl.query(asOf: Date())
        XCTAssertEqual(snapshotNow[0].content, "v3")

        // Check full history
        let history = try versionControl.history(of: doc.id)
        XCTAssertEqual(history.count, 3)
        XCTAssertEqual(history[0].content, "v1")
        XCTAssertEqual(history[1].content, "v2")
        XCTAssertEqual(history[2].content, "v3")
    }

    // MARK: - Edge Cases

    func testCommitEmptyDocumentList() throws {
        try versionControl.initializeDefaultBranch()

        let commit = try versionControl.commit(message: "Empty commit", documents: [])
        let snapshots = try databaseManager.getVCSnapshots(commitId: commit.id)

        XCTAssertEqual(snapshots.count, 0)
    }

    func testDiffBranchesWithNoCommits() throws {
        try versionControl.checkoutBranch(name: "empty1", createNew: true)
        try versionControl.checkoutBranch(name: "empty2", createNew: true)

        XCTAssertThrowsError(try versionControl.diff(fromBranch: "empty1", toBranch: "empty2"))
    }

    func testMultipleCommitsInSuccession() throws {
        try versionControl.initializeDefaultBranch()

        for i in 1...10 {
            let doc = Document(title: "Doc \(i)", content: "Content \(i)", category: .novel)
            try versionControl.commit(message: "Commit \(i)", documents: [doc])
        }

        let log = try versionControl.log(branch: "main")
        XCTAssertEqual(log.count, 10)

        let branch = try versionControl.currentBranch()
        let snapshots = try databaseManager.getVCSnapshots(commitId: branch!.headCommitId!)
        XCTAssertEqual(snapshots.count, 10)
    }

    func testLargeContentCommit() throws {
        try versionControl.initializeDefaultBranch()

        let largeContent = String(repeating: "Lorem ipsum dolor sit amet. ", count: 1000)
        let doc = Document(title: "Large Doc", content: largeContent, category: .novel)
        let commit = try versionControl.commit(message: "Large commit", documents: [doc])

        let snapshots = try databaseManager.getVCSnapshots(commitId: commit.id)
        XCTAssertEqual(snapshots[0].content, largeContent)
    }

    func testWordCountTracking() throws {
        try versionControl.initializeDefaultBranch()

        let doc1 = Document(id: UUID(), title: "Doc", content: "One two three", category: .novel)
        try versionControl.commit(message: "Three words", documents: [doc1])

        let doc2 = Document(id: doc1.id, title: "Doc", content: "One two three four five six", category: .novel)
        try versionControl.commit(message: "Six words", documents: [doc2])

        let history = try versionControl.history(of: doc1.id)
        XCTAssertEqual(history[0].wordCount, 3)
        XCTAssertEqual(history[1].wordCount, 6)
    }

    func testBranchNamesWithSpecialCharacters() throws {
        let specialNames = ["feature/test", "bug-fix_123", "v1.0.0"]

        for name in specialNames {
            try versionControl.checkoutBranch(name: name, createNew: true)
            let branch = try versionControl.currentBranch()
            XCTAssertEqual(branch?.name, name)
        }
    }

    // MARK: - Negative Cases and Boundary Conditions

    func testCommitVeryLongMessage() throws {
        try versionControl.initializeDefaultBranch()

        let longMessage = String(repeating: "A", count: 10000)
        let doc = Document(title: "Doc", content: "Content", category: .novel)
        let commit = try versionControl.commit(message: longMessage, documents: [doc])

        let log = try versionControl.log(branch: "main")
        XCTAssertEqual(log[0].message, longMessage)
    }

    func testDocumentWithEmptyContent() throws {
        try versionControl.initializeDefaultBranch()

        let doc = Document(title: "Empty", content: "", category: .novel)
        let commit = try versionControl.commit(message: "Empty doc", documents: [doc])

        let snapshots = try databaseManager.getVCSnapshots(commitId: commit.id)
        XCTAssertEqual(snapshots[0].content, "")
        XCTAssertEqual(snapshots[0].wordCount, 0)
    }

    func testDocumentWithUnicodeContent() throws {
        try versionControl.initializeDefaultBranch()

        let unicodeContent = "Hello 世界! 🌍 Émoji"
        let doc = Document(title: "Unicode Doc", content: unicodeContent, category: .novel)
        let commit = try versionControl.commit(message: "Unicode test", documents: [doc])

        let snapshots = try databaseManager.getVCSnapshots(commitId: commit.id)
        XCTAssertEqual(snapshots[0].content, unicodeContent)
    }

    func testMultipleFastMerges() throws {
        try versionControl.initializeDefaultBranch()

        let doc1 = Document(title: "Doc1", content: "Content1", category: .novel)
        try versionControl.commit(message: "Initial", documents: [doc1])

        try versionControl.checkoutBranch(name: "feature-1", createNew: true)
        let doc2 = Document(title: "Doc2", content: "Content2", category: .essay)
        try versionControl.commit(message: "Feature 1", documents: [doc1, doc2])

        try versionControl.checkoutBranch(name: "feature-2", createNew: true)
        let doc3 = Document(title: "Doc3", content: "Content3", category: .article)
        try versionControl.commit(message: "Feature 2", documents: [doc1, doc2, doc3])

        try versionControl.merge(fromBranch: "feature-1", into: "main")
        try versionControl.merge(fromBranch: "feature-2", into: "main")

        let mainBranch = try databaseManager.getVCBranch(name: "main")
        let snapshots = try databaseManager.getVCSnapshots(commitId: mainBranch!.headCommitId!)
        XCTAssertEqual(snapshots.count, 3)
    }

    func testSwitchBranchesMultipleTimes() throws {
        try versionControl.checkoutBranch(name: "branch-A", createNew: true)
        try versionControl.checkoutBranch(name: "branch-B", createNew: true)
        try versionControl.checkoutBranch(name: "branch-C", createNew: true)

        for _ in 0..<10 {
            try versionControl.checkoutBranch(name: "branch-A", createNew: false)
            XCTAssertEqual(try versionControl.currentBranch()?.name, "branch-A")

            try versionControl.checkoutBranch(name: "branch-B", createNew: false)
            XCTAssertEqual(try versionControl.currentBranch()?.name, "branch-B")

            try versionControl.checkoutBranch(name: "branch-C", createNew: false)
            XCTAssertEqual(try versionControl.currentBranch()?.name, "branch-C")
        }
    }

    func testQueryAsOfVeryOldDate() throws {
        try versionControl.initializeDefaultBranch()

        let doc = Document(title: "Doc", content: "Content", category: .novel)
        try versionControl.commit(message: "Recent", documents: [doc])

        let veryOldDate = Date(timeIntervalSince1970: 0)
        let snapshots = try versionControl.query(asOf: veryOldDate)
        XCTAssertEqual(snapshots.count, 0)
    }

    func testQueryAsOfVeryFutureDate() throws {
        try versionControl.initializeDefaultBranch()

        let doc = Document(title: "Doc", content: "Content", category: .novel)
        try versionControl.commit(message: "Now", documents: [doc])

        let futureDate = Date(timeIntervalSinceNow: 365 * 24 * 60 * 60)
        let snapshots = try versionControl.query(asOf: futureDate)
        XCTAssertEqual(snapshots.count, 1)
        XCTAssertEqual(snapshots[0].content, "Content")
    }

    func testDiffWithIdenticalCommits() throws {
        try versionControl.initializeDefaultBranch()

        let doc = Document(title: "Doc", content: "Content", category: .novel)
        let commit = try versionControl.commit(message: "Commit", documents: [doc])

        let diffs = try versionControl.diff(fromCommitId: commit.id, toCommitId: commit.id)
        XCTAssertEqual(diffs.count, 1)
        XCTAssertEqual(diffs[0].changeType, .unchanged)
    }

    func testMergeIntoSelfBranch() throws {
        try versionControl.initializeDefaultBranch()

        let doc = Document(title: "Doc", content: "Content", category: .novel)
        try versionControl.commit(message: "Commit", documents: [doc])

        let result = try versionControl.merge(fromBranch: "main", into: "main")
        XCTAssertTrue(result.success)
    }

    func testHistoryWithDuplicateDocumentIds() throws {
        try versionControl.initializeDefaultBranch()

        let sharedId = UUID()

        let doc1 = Document(id: sharedId, title: "Version 1", content: "v1", category: .novel)
        try versionControl.commit(message: "Commit 1", documents: [doc1])

        let doc2 = Document(id: sharedId, title: "Version 2", content: "v2", category: .novel)
        try versionControl.commit(message: "Commit 2", documents: [doc2])

        let doc3 = Document(id: sharedId, title: "Version 3", content: "v3", category: .novel)
        try versionControl.commit(message: "Commit 3", documents: [doc3])

        let history = try versionControl.history(of: sharedId)
        XCTAssertEqual(history.count, 3)

        XCTAssertEqual(history[0].title, "Version 1")
        XCTAssertEqual(history[1].title, "Version 2")
        XCTAssertEqual(history[2].title, "Version 3")
    }

    func testConcurrentBranchCreation() throws {
        let branches = (1...20).map { "branch-\($0)" }

        for branchName in branches {
            try versionControl.checkoutBranch(name: branchName, createNew: true)
        }

        let allBranches = try versionControl.listBranches()
        XCTAssertEqual(allBranches.count, 20)
    }

    func testDiffWithManyDocuments() throws {
        try versionControl.initializeDefaultBranch()

        let docs1 = (1...50).map { Document(title: "Doc \($0)", content: "Content \($0)", category: .novel) }
        let commit1 = try versionControl.commit(message: "50 docs", documents: docs1)

        // Reuse IDs from docs1 for the first 50, add 25 new docs
        let docs2 = docs1.map { Document(id: $0.id, title: $0.title, content: $0.content + " updated", category: .novel) }
            + (51...75).map { Document(title: "Doc \($0)", content: "Content \($0)", category: .novel) }
        let commit2 = try versionControl.commit(message: "75 docs", documents: docs2)

        let diffs = try versionControl.diff(fromCommitId: commit1.id, toCommitId: commit2.id)
        XCTAssertEqual(diffs.count, 75)

        let modified = diffs.filter { $0.changeType == .modified }
        let added = diffs.filter { $0.changeType == .added }
        XCTAssertEqual(modified.count, 50)
        XCTAssertEqual(added.count, 25)
    }

    func testBranchDeletedDocumentThenMerge() throws {
        try versionControl.initializeDefaultBranch()

        let doc1 = Document(id: UUID(), title: "Keep", content: "Keep this", category: .novel)
        let doc2 = Document(id: UUID(), title: "Delete", content: "Delete this", category: .essay)
        try versionControl.commit(message: "Initial", documents: [doc1, doc2])

        try versionControl.checkoutBranch(name: "feature", createNew: true)
        try versionControl.commit(message: "Deleted doc2", documents: [doc1])

        let result = try versionControl.merge(fromBranch: "feature", into: "main")
        XCTAssertTrue(result.success)

        let mainBranch = try databaseManager.getVCBranch(name: "main")
        let snapshots = try databaseManager.getVCSnapshots(commitId: mainBranch!.headCommitId!)
        // The feature branch was created fresh (no inherited state), so it has no knowledge of
        // doc2 ("Delete"); the three-way merge keeps both "Keep" and "Delete" from the target.
        XCTAssertEqual(snapshots.count, 2)
        XCTAssertTrue(snapshots.contains { $0.title == "Keep" })
    }

    func testComplexMergeScenario() throws {
        try versionControl.initializeDefaultBranch()

        let doc1 = Document(id: UUID(), title: "Doc1", content: "Initial", category: .novel)
        let doc2 = Document(id: UUID(), title: "Doc2", content: "Initial", category: .essay)
        try versionControl.commit(message: "Initial", documents: [doc1, doc2])

        try versionControl.checkoutBranch(name: "feature-A", createNew: true)
        let doc1A = Document(id: doc1.id, title: "Doc1", content: "Modified in A", category: .novel)
        let doc3 = Document(id: UUID(), title: "Doc3", content: "New in A", category: .article)
        try versionControl.commit(message: "Feature A", documents: [doc1A, doc2, doc3])

        try versionControl.checkoutBranch(name: "main", createNew: false)
        try versionControl.checkoutBranch(name: "feature-B", createNew: true)
        let doc2B = Document(id: doc2.id, title: "Doc2", content: "Modified in B", category: .essay)
        let doc4 = Document(id: UUID(), title: "Doc4", content: "New in B", category: .blogPost)
        try versionControl.commit(message: "Feature B", documents: [doc1, doc2B, doc4])

        try versionControl.merge(fromBranch: "feature-A", into: "main")
        try versionControl.merge(fromBranch: "feature-B", into: "main")

        let mainBranch = try databaseManager.getVCBranch(name: "main")
        let finalSnapshots = try databaseManager.getVCSnapshots(commitId: mainBranch!.headCommitId!)
        XCTAssertEqual(finalSnapshots.count, 4)
    }

    // MARK: - Additional Regression and Edge Cases

    func testBranchSwitchDoesNotLoseUncommittedState() throws {
        // Regression test: ensure branch switching is about database state, not in-memory document state
        try versionControl.initializeDefaultBranch()

        let doc = Document(id: UUID(), title: "Doc", content: "Main content", category: .novel)
        try versionControl.commit(message: "Main commit", documents: [doc])

        try versionControl.checkoutBranch(name: "feature", createNew: true)
        let docUpdated = Document(id: doc.id, title: "Doc", content: "Feature content", category: .novel)
        try versionControl.commit(message: "Feature commit", documents: [docUpdated])

        // Switch back to main
        try versionControl.checkoutBranch(name: "main", createNew: false)

        // Verify main still has original content
        let mainBranch = try databaseManager.getVCBranch(name: "main")
        let mainSnapshots = try databaseManager.getVCSnapshots(commitId: mainBranch!.headCommitId!)
        XCTAssertEqual(mainSnapshots[0].content, "Main content")

        // Switch to feature and verify it has feature content
        try versionControl.checkoutBranch(name: "feature", createNew: false)
        let featureBranch = try databaseManager.getVCBranch(name: "feature")
        let featureSnapshots = try databaseManager.getVCSnapshots(commitId: featureBranch!.headCommitId!)
        XCTAssertEqual(featureSnapshots[0].content, "Feature content")
    }

    func testDiffHandlesDocumentRename() throws {
        // Edge case: document with same ID but different title
        try versionControl.initializeDefaultBranch()

        let doc1 = Document(id: UUID(), title: "Original Title", content: "Content", category: .novel)
        let commit1 = try versionControl.commit(message: "Original", documents: [doc1])

        let doc2 = Document(id: doc1.id, title: "Renamed Title", content: "Content", category: .novel)
        let commit2 = try versionControl.commit(message: "Renamed", documents: [doc2])

        let diffs = try versionControl.diff(fromCommitId: commit1.id, toCommitId: commit2.id)

        XCTAssertEqual(diffs.count, 1)
        XCTAssertEqual(diffs[0].changeType, .modified)  // Title change makes it modified
        XCTAssertEqual(diffs[0].title, "Renamed Title")
    }

    func testQueryAsOfWithMultipleVersionsOfSameDocument() throws {
        // Boundary test: ensure AS OF query returns correct version when document has many versions
        try versionControl.initializeDefaultBranch()

        let docId = UUID()

        for i in 1...10 {
            let doc = Document(id: docId, title: "Doc", content: "Version \(i)", category: .novel)
            try versionControl.commit(message: "v\(i)", documents: [doc])
            Thread.sleep(forTimeInterval: 0.05)
        }

        // Query at different points should return correct version
        let allCommits = try versionControl.log(branch: "main")
        XCTAssertEqual(allCommits.count, 10)

        // Query just after 5th commit
        let commitTime5 = allCommits[4].timestamp
        let queryDate5 = Date(timeInterval: 0.01, since: commitTime5)

        let snapshots5 = try versionControl.query(asOf: queryDate5)
        XCTAssertEqual(snapshots5.count, 1)
        XCTAssertEqual(snapshots5[0].content, "Version 5")
    }

    func testMergePreservesDocumentMetadata() throws {
        // Regression test: ensure merge preserves all document properties
        try versionControl.initializeDefaultBranch()

        let doc = Document(
            id: UUID(),
            title: "Complex Doc",
            content: "Lorem ipsum " + String(repeating: "dolor sit amet ", count: 100),
            category: .novel
        )
        try versionControl.commit(message: "Initial", documents: [doc])

        try versionControl.checkoutBranch(name: "feature", createNew: true)
        let docUpdated = Document(
            id: doc.id,
            title: "Complex Doc Updated",
            content: doc.content + " Additional content",
            category: .novel
        )
        try versionControl.commit(message: "Feature", documents: [docUpdated])

        try versionControl.merge(fromBranch: "feature", into: "main")

        let mainBranch = try databaseManager.getVCBranch(name: "main")
        let mergedSnapshots = try databaseManager.getVCSnapshots(commitId: mainBranch!.headCommitId!)

        XCTAssertEqual(mergedSnapshots.count, 1)
        XCTAssertEqual(mergedSnapshots[0].title, "Complex Doc Updated")
        XCTAssertTrue(mergedSnapshots[0].content.hasSuffix("Additional content"))
        XCTAssertEqual(mergedSnapshots[0].category, "Novel")
        XCTAssertGreaterThan(mergedSnapshots[0].wordCount, doc.wordCount)
    }

    func testLogWithMergeCommitsShowsFullHistory() throws {
        // Edge case: verify log includes merge commits and maintains order
        try versionControl.initializeDefaultBranch()

        let doc = Document(title: "Doc", content: "Initial", category: .novel)
        try versionControl.commit(message: "Initial commit", documents: [doc])
        try versionControl.commit(message: "Second commit", documents: [doc])

        try versionControl.checkoutBranch(name: "feature", createNew: true)
        try versionControl.commit(message: "Feature commit", documents: [doc])

        try versionControl.merge(fromBranch: "feature", into: "main")

        let log = try versionControl.log(branch: "main")

        // Should have 4 commits: Initial, Second, Feature (inherited), Merge
        XCTAssertGreaterThanOrEqual(log.count, 3)

        // Last commit should be merge commit
        XCTAssertTrue(log.last?.message.contains("Merge") ?? false)

        // Verify commits are in chronological order
        for i in 1..<log.count {
            XCTAssertGreaterThanOrEqual(log[i].timestamp, log[i-1].timestamp)
        }
    }

    func testHistoryWithGapsInCommits() throws {
        // Edge case: document not present in some commits, ensure history only shows when present
        try versionControl.initializeDefaultBranch()

        let doc1 = Document(id: UUID(), title: "Doc1", content: "Content1", category: .novel)
        let doc2 = Document(id: UUID(), title: "Doc2", content: "Content2", category: .essay)

        try versionControl.commit(message: "Only Doc1", documents: [doc1])
        try versionControl.commit(message: "Both", documents: [doc1, doc2])
        try versionControl.commit(message: "Only Doc2", documents: [doc2])
        try versionControl.commit(message: "Both again", documents: [doc1, doc2])

        let doc1History = try versionControl.history(of: doc1.id)
        XCTAssertEqual(doc1History.count, 3)  // Doc1 appears in commits 1, 2, 4

        let doc2History = try versionControl.history(of: doc2.id)
        XCTAssertEqual(doc2History.count, 3)  // Doc2 appears in commits 2, 3, 4
    }

    func testEmptyStringContentHandling() throws {
        // Boundary test: documents with empty content
        try versionControl.initializeDefaultBranch()

        let doc = Document(id: UUID(), title: "Empty", content: "", category: .novel)
        let commit = try versionControl.commit(message: "Empty doc", documents: [doc])

        let snapshots = try databaseManager.getVCSnapshots(commitId: commit.id)
        XCTAssertEqual(snapshots[0].content, "")
        XCTAssertEqual(snapshots[0].wordCount, 0)

        // Verify diff handles empty content
        let docWithContent = Document(id: doc.id, title: "Empty", content: "Now has content", category: .novel)
        let commit2 = try versionControl.commit(message: "Added content", documents: [docWithContent])

        let diffs = try versionControl.diff(fromCommitId: commit.id, toCommitId: commit2.id)
        XCTAssertEqual(diffs[0].changeType, .modified)
        XCTAssertEqual(diffs[0].fromContent, "")
        XCTAssertEqual(diffs[0].toContent, "Now has content")
    }

    func testSpecialCharactersInCommitMessages() throws {
        // Edge case: commit messages with special characters and unicode
        try versionControl.initializeDefaultBranch()

        let specialMessages = [
            "Commit with emoji 🎉",
            "Unicode: 日本語",
            "Special chars: @#$%^&*()",
            "Quotes: \"double\" and 'single'",
            "Newlines\nand\ntabs\there"
        ]

        let doc = Document(title: "Doc", content: "Content", category: .novel)
        for message in specialMessages {
            try versionControl.commit(message: message, documents: [doc])
        }

        let log = try versionControl.log(branch: "main")
        XCTAssertEqual(log.count, specialMessages.count)

        for (index, message) in specialMessages.enumerated() {
            XCTAssertEqual(log[index].message, message)
        }
    }

    func testDiffWithIdenticalContentButDifferentMetadata() throws {
        // Boundary test: documents with same content but different metadata
        try versionControl.initializeDefaultBranch()

        let doc1 = Document(id: UUID(), title: "Version 1", content: "Same content", category: .novel)
        let commit1 = try versionControl.commit(message: "v1", documents: [doc1])

        let doc2 = Document(id: doc1.id, title: "Version 2", content: "Same content", category: .essay)
        let commit2 = try versionControl.commit(message: "v2", documents: [doc2])

        let diffs = try versionControl.diff(fromCommitId: commit1.id, toCommitId: commit2.id)

        // Should be modified because title changed even though content is same
        XCTAssertEqual(diffs[0].changeType, .modified)
        XCTAssertEqual(diffs[0].fromContent, "Same content")
        XCTAssertEqual(diffs[0].toContent, "Same content")
    }

    func testZeroWordCountDocument() throws {
        // Edge case: document with no words
        try versionControl.initializeDefaultBranch()

        let doc = Document(id: UUID(), title: "Title", content: "   \n\n\t  ", category: .novel)
        let commit = try versionControl.commit(message: "Whitespace only", documents: [doc])

        let snapshots = try databaseManager.getVCSnapshots(commitId: commit.id)
        // Document model computes word count - should be 0 for whitespace only
        XCTAssertEqual(snapshots[0].wordCount, 0)
    }
}