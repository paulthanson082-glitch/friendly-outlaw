import XCTest
@testable import WritersApp

final class DoltVersionControlServiceTests: XCTestCase {
    var databaseManager: DatabaseManager!
    var vcService: DoltVersionControlService!
    var testDatabasePath: String!

    override func setUp() {
        super.setUp()
        testDatabasePath = "/tmp/test_vc_\(UUID().uuidString).db"

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
        let branch1 = try vcService.initializeDefaultBranch()
        let branch2 = try vcService.initializeDefaultBranch()

        XCTAssertEqual(branch1.id, branch2.id)
        XCTAssertTrue(branch2.isActive)
    }

    // MARK: - Branch Operations Tests

    func testListBranchesEmpty() throws {
        let branches = try vcService.listBranches()
        XCTAssertEqual(branches.count, 0)
    }

    func testListBranches() throws {
        try vcService.checkoutBranch(name: "main", createNew: true)
        try vcService.checkoutBranch(name: "feature-1", createNew: true)
        try vcService.checkoutBranch(name: "feature-2", createNew: true)

        let branches = try vcService.listBranches()
        XCTAssertEqual(branches.count, 3)

        let branchNames = branches.map { $0.name }
        XCTAssertTrue(branchNames.contains("main"))
        XCTAssertTrue(branchNames.contains("feature-1"))
        XCTAssertTrue(branchNames.contains("feature-2"))
    }

    func testCurrentBranchNone() throws {
        let current = try vcService.currentBranch()
        XCTAssertNil(current)
    }

    func testCurrentBranch() throws {
        try vcService.checkoutBranch(name: "main", createNew: true)

        let current = try vcService.currentBranch()
        XCTAssertNotNil(current)
        XCTAssertEqual(current?.name, "main")
        XCTAssertTrue(current?.isActive ?? false)
    }

    func testCheckoutNewBranch() throws {
        let branch = try vcService.checkoutBranch(name: "feature", createNew: true)

        XCTAssertEqual(branch.name, "feature")
        XCTAssertTrue(branch.isActive)
    }

    func testCheckoutExistingBranch() throws {
        try vcService.checkoutBranch(name: "main", createNew: true)
        try vcService.checkoutBranch(name: "feature", createNew: true)

        // Switch back to main
        let mainBranch = try vcService.checkoutBranch(name: "main", createNew: false)

        XCTAssertEqual(mainBranch.name, "main")
        XCTAssertTrue(mainBranch.isActive)

        let current = try vcService.currentBranch()
        XCTAssertEqual(current?.name, "main")
    }

    func testCheckoutBranchAlreadyExists() throws {
        try vcService.checkoutBranch(name: "feature", createNew: true)

        XCTAssertThrowsError(try vcService.checkoutBranch(name: "feature", createNew: true)) { error in
            if case VersionControlError.branchAlreadyExists(let name) = error {
                XCTAssertEqual(name, "feature")
            } else {
                XCTFail("Expected branchAlreadyExists error")
            }
        }
    }

    func testCheckoutNonexistentBranch() throws {
        XCTAssertThrowsError(try vcService.checkoutBranch(name: "nonexistent", createNew: false)) { error in
            if case VersionControlError.branchNotFound(let name) = error {
                XCTAssertEqual(name, "nonexistent")
            } else {
                XCTFail("Expected branchNotFound error")
            }
        }
    }

    func testNewBranchInheritsHeadCommit() throws {
        try vcService.checkoutBranch(name: "main", createNew: true)

        let documents = [createTestDocument(title: "Doc 1")]
        let commit = try vcService.commit(message: "Initial commit", documents: documents)

        // Create feature branch from main
        let featureBranch = try vcService.checkoutBranch(name: "feature", createNew: true)

        XCTAssertEqual(featureBranch.headCommitId, commit.id)
    }

    // MARK: - Commit Operations Tests

    func testCommitNoActiveBranch() throws {
        let documents = [createTestDocument(title: "Doc 1")]

        XCTAssertThrowsError(try vcService.commit(message: "Test", documents: documents)) { error in
            if case VersionControlError.noActiveBranch = error {
                // Expected
            } else {
                XCTFail("Expected noActiveBranch error")
            }
        }
    }

    func testFirstCommit() throws {
        try vcService.checkoutBranch(name: "main", createNew: true)

        let documents = [
            createTestDocument(title: "Doc 1", content: "Content 1"),
            createTestDocument(title: "Doc 2", content: "Content 2")
        ]

        let commit = try vcService.commit(message: "Initial commit", documents: documents)

        XCTAssertEqual(commit.message, "Initial commit")
        XCTAssertNil(commit.parentCommitId)

        let branch = try vcService.currentBranch()
        XCTAssertEqual(branch?.headCommitId, commit.id)
    }

    func testSecondCommitHasParent() throws {
        try vcService.checkoutBranch(name: "main", createNew: true)

        let documents = [createTestDocument(title: "Doc 1")]

        let commit1 = try vcService.commit(message: "First commit", documents: documents)
        let commit2 = try vcService.commit(message: "Second commit", documents: documents)

        XCTAssertEqual(commit2.parentCommitId, commit1.id)

        let branch = try vcService.currentBranch()
        XCTAssertEqual(branch?.headCommitId, commit2.id)
    }

    func testCommitWithAuthor() throws {
        try vcService.checkoutBranch(name: "main", createNew: true)

        let documents = [createTestDocument(title: "Doc 1")]

        let commit = try vcService.commit(message: "Test", documents: documents, authorId: "author-123")

        XCTAssertEqual(commit.authorId, "author-123")
    }

    func testCommitCreatesSnapshots() throws {
        try vcService.checkoutBranch(name: "main", createNew: true)

        let doc1 = createTestDocument(title: "Doc 1", content: "Content 1")
        let doc2 = createTestDocument(title: "Doc 2", content: "Content 2")
        let documents = [doc1, doc2]

        let commit = try vcService.commit(message: "Test", documents: documents)

        let snapshots = try databaseManager.getVCSnapshots(commitId: commit.id)
        XCTAssertEqual(snapshots.count, 2)

        let snapshot1 = snapshots.first { $0.documentId == doc1.id }
        XCTAssertEqual(snapshot1?.title, "Doc 1")
        XCTAssertEqual(snapshot1?.content, "Content 1")
    }

    func testLog() throws {
        try vcService.checkoutBranch(name: "main", createNew: true)

        let documents = [createTestDocument(title: "Doc 1")]

        _ = try vcService.commit(message: "First commit", documents: documents)
        _ = try vcService.commit(message: "Second commit", documents: documents)
        _ = try vcService.commit(message: "Third commit", documents: documents)

        let log = try vcService.log(branch: "main")

        XCTAssertEqual(log.count, 3)
        XCTAssertEqual(log[0].message, "First commit")
        XCTAssertEqual(log[1].message, "Second commit")
        XCTAssertEqual(log[2].message, "Third commit")
    }

    func testLogNonexistentBranch() throws {
        XCTAssertThrowsError(try vcService.log(branch: "nonexistent")) { error in
            if case VersionControlError.branchNotFound = error {
                // Expected
            } else {
                XCTFail("Expected branchNotFound error")
            }
        }
    }

    // MARK: - Diff Operations Tests

    func testDiffBranchesNoChanges() throws {
        try vcService.checkoutBranch(name: "main", createNew: true)

        let documents = [createTestDocument(title: "Doc 1", content: "Content 1")]
        _ = try vcService.commit(message: "Initial commit", documents: documents)

        try vcService.checkoutBranch(name: "feature", createNew: true)

        let diffs = try vcService.diff(fromBranch: "main", toBranch: "feature")

        XCTAssertEqual(diffs.count, 1)
        XCTAssertEqual(diffs[0].changeType, .unchanged)
    }

    func testDiffBranchesModified() throws {
        try vcService.checkoutBranch(name: "main", createNew: true)

        let doc = createTestDocument(title: "Doc 1", content: "Original content")
        _ = try vcService.commit(message: "Initial commit", documents: [doc])

        try vcService.checkoutBranch(name: "feature", createNew: true)

        var modifiedDoc = doc
        modifiedDoc.content = "Modified content"
        _ = try vcService.commit(message: "Modify doc", documents: [modifiedDoc])

        let diffs = try vcService.diff(fromBranch: "main", toBranch: "feature")

        XCTAssertEqual(diffs.count, 1)
        XCTAssertEqual(diffs[0].changeType, .modified)
        XCTAssertEqual(diffs[0].fromContent, "Original content")
        XCTAssertEqual(diffs[0].toContent, "Modified content")
    }

    func testDiffBranchesAdded() throws {
        try vcService.checkoutBranch(name: "main", createNew: true)

        let doc1 = createTestDocument(title: "Doc 1", content: "Content 1")
        _ = try vcService.commit(message: "Initial commit", documents: [doc1])

        try vcService.checkoutBranch(name: "feature", createNew: true)

        let doc2 = createTestDocument(title: "Doc 2", content: "Content 2")
        _ = try vcService.commit(message: "Add doc", documents: [doc1, doc2])

        let diffs = try vcService.diff(fromBranch: "main", toBranch: "feature")

        let addedDiff = diffs.first { $0.changeType == .added }
        XCTAssertNotNil(addedDiff)
        XCTAssertEqual(addedDiff?.title, "Doc 2")
        XCTAssertEqual(addedDiff?.toContent, "Content 2")
    }

    func testDiffBranchesDeleted() throws {
        try vcService.checkoutBranch(name: "main", createNew: true)

        let doc1 = createTestDocument(title: "Doc 1", content: "Content 1")
        let doc2 = createTestDocument(title: "Doc 2", content: "Content 2")
        _ = try vcService.commit(message: "Initial commit", documents: [doc1, doc2])

        try vcService.checkoutBranch(name: "feature", createNew: true)

        _ = try vcService.commit(message: "Remove doc", documents: [doc1])

        let diffs = try vcService.diff(fromBranch: "main", toBranch: "feature")

        let deletedDiff = diffs.first { $0.changeType == .deleted }
        XCTAssertNotNil(deletedDiff)
        XCTAssertEqual(deletedDiff?.title, "Doc 2")
        XCTAssertEqual(deletedDiff?.fromContent, "Content 2")
    }

    func testDiffWordCountDelta() throws {
        try vcService.checkoutBranch(name: "main", createNew: true)

        let doc = createTestDocument(title: "Doc 1", content: "One two three")
        _ = try vcService.commit(message: "Initial", documents: [doc])

        try vcService.checkoutBranch(name: "feature", createNew: true)

        var modifiedDoc = doc
        modifiedDoc.content = "One two three four five"
        _ = try vcService.commit(message: "Expand", documents: [modifiedDoc])

        let diffs = try vcService.diff(fromBranch: "main", toBranch: "feature")

        XCTAssertEqual(diffs[0].changeType, .modified)
        XCTAssertEqual(diffs[0].fromWordCount, 3)
        XCTAssertEqual(diffs[0].toWordCount, 5)
        XCTAssertEqual(diffs[0].wordCountDelta, 2)
    }

    func testDiffCommitToCommit() throws {
        try vcService.checkoutBranch(name: "main", createNew: true)

        let doc = createTestDocument(title: "Doc 1", content: "Version 1")
        let commit1 = try vcService.commit(message: "Commit 1", documents: [doc])

        var doc2 = doc
        doc2.content = "Version 2"
        let commit2 = try vcService.commit(message: "Commit 2", documents: [doc2])

        let diffs = try vcService.diff(fromCommitId: commit1.id, toCommitId: commit2.id)

        XCTAssertEqual(diffs.count, 1)
        XCTAssertEqual(diffs[0].changeType, .modified)
        XCTAssertEqual(diffs[0].fromContent, "Version 1")
        XCTAssertEqual(diffs[0].toContent, "Version 2")
    }

    // MARK: - Time Travel Tests

    func testQueryAsOf() throws {
        try vcService.checkoutBranch(name: "main", createNew: true)

        let doc = createTestDocument(title: "Doc 1", content: "Version 1")
        _ = try vcService.commit(message: "Commit 1", documents: [doc])

        let queryTime = Date()
        Thread.sleep(forTimeInterval: 0.1)

        var doc2 = doc
        doc2.content = "Version 2"
        _ = try vcService.commit(message: "Commit 2", documents: [doc2])

        // Query at the time between commits
        let snapshots = try vcService.query(asOf: queryTime)

        XCTAssertEqual(snapshots.count, 1)
        XCTAssertEqual(snapshots[0].content, "Version 1")
    }

    func testQueryAsOfMultipleDocuments() throws {
        try vcService.checkoutBranch(name: "main", createNew: true)

        let doc1 = createTestDocument(title: "Doc 1", content: "Content 1")
        let doc2 = createTestDocument(title: "Doc 2", content: "Content 2")
        _ = try vcService.commit(message: "Initial", documents: [doc1, doc2])

        let queryTime = Date()
        Thread.sleep(forTimeInterval: 0.1)

        var doc1Modified = doc1
        doc1Modified.content = "Updated content 1"
        _ = try vcService.commit(message: "Update", documents: [doc1Modified, doc2])

        let snapshots = try vcService.query(asOf: queryTime)

        XCTAssertEqual(snapshots.count, 2)
        let snapshot1 = snapshots.first { $0.documentId == doc1.id }
        XCTAssertEqual(snapshot1?.content, "Content 1")
    }

    func testHistory() throws {
        try vcService.checkoutBranch(name: "main", createNew: true)

        let doc = createTestDocument(title: "Doc 1", content: "Version 1")
        _ = try vcService.commit(message: "Commit 1", documents: [doc])

        var doc2 = doc
        doc2.content = "Version 2"
        _ = try vcService.commit(message: "Commit 2", documents: [doc2])

        var doc3 = doc
        doc3.content = "Version 3"
        _ = try vcService.commit(message: "Commit 3", documents: [doc3])

        let history = try vcService.history(of: doc.id)

        XCTAssertEqual(history.count, 3)
        XCTAssertEqual(history[0].content, "Version 1")
        XCTAssertEqual(history[1].content, "Version 2")
        XCTAssertEqual(history[2].content, "Version 3")
    }

    // MARK: - Merge Operations Tests

    func testMergeFastForwardEmptyTarget() throws {
        try vcService.checkoutBranch(name: "main", createNew: true)
        try vcService.checkoutBranch(name: "feature", createNew: true)

        let doc = createTestDocument(title: "Doc 1", content: "Content")
        let commit = try vcService.commit(message: "Add doc", documents: [doc])

        let result = try vcService.merge(fromBranch: "feature", into: "main")

        XCTAssertTrue(result.success)
        XCTAssertEqual(result.strategy, .fastForward)
        XCTAssertEqual(result.commitId, commit.id)
        XCTAssertEqual(result.diffCount, 1)
    }

    func testMergeSourceBranchNoCommits() throws {
        try vcService.checkoutBranch(name: "main", createNew: true)

        let doc = createTestDocument(title: "Doc 1", content: "Content")
        _ = try vcService.commit(message: "Initial", documents: [doc])

        try vcService.checkoutBranch(name: "feature", createNew: true)

        let result = try vcService.merge(fromBranch: "feature", into: "main")

        XCTAssertTrue(result.success)
        XCTAssertEqual(result.strategy, .fastForward)
        XCTAssertEqual(result.diffCount, 0)
    }

    func testMergeThreeWay() throws {
        try vcService.checkoutBranch(name: "main", createNew: true)

        let doc1 = createTestDocument(title: "Doc 1", content: "Main content")
        _ = try vcService.commit(message: "Main commit", documents: [doc1])

        try vcService.checkoutBranch(name: "feature", createNew: true)

        let doc2 = createTestDocument(title: "Doc 2", content: "Feature content")
        _ = try vcService.commit(message: "Feature commit", documents: [doc1, doc2])

        try vcService.checkoutBranch(name: "main", createNew: false)

        var doc1Updated = doc1
        doc1Updated.content = "Updated main content"
        _ = try vcService.commit(message: "Update main", documents: [doc1Updated])

        let result = try vcService.merge(fromBranch: "feature", into: "main")

        XCTAssertTrue(result.success)
        XCTAssertEqual(result.strategy, .threeWay)
        XCTAssertNotNil(result.commitId)

        // Verify merge commit created
        let mainBranch = try vcService.currentBranch()
        XCTAssertEqual(mainBranch?.headCommitId, result.commitId)

        // Verify merge commit has two parents
        let commits = try vcService.log(branch: "main")
        let mergeCommit = commits.last
        XCTAssertNotNil(mergeCommit?.parentCommitId)
        XCTAssertNotNil(mergeCommit?.secondParentCommitId)
    }

    func testMergeLastWriterWins() throws {
        try vcService.checkoutBranch(name: "main", createNew: true)

        let doc = createTestDocument(title: "Doc 1", content: "Original")
        _ = try vcService.commit(message: "Initial", documents: [doc])

        try vcService.checkoutBranch(name: "feature", createNew: true)

        var docFeature = doc
        docFeature.content = "Feature version"
        _ = try vcService.commit(message: "Feature update", documents: [docFeature])

        try vcService.checkoutBranch(name: "main", createNew: false)

        var docMain = doc
        docMain.content = "Main version"
        _ = try vcService.commit(message: "Main update", documents: [docMain])

        let result = try vcService.merge(fromBranch: "feature", into: "main")

        XCTAssertTrue(result.success)

        // Verify the feature version won (last writer wins)
        let snapshots = try databaseManager.getVCSnapshots(commitId: result.commitId!)
        let snapshot = snapshots.first { $0.documentId == doc.id }
        XCTAssertEqual(snapshot?.content, "Feature version")
    }

    func testMergeBranchNotFound() throws {
        try vcService.checkoutBranch(name: "main", createNew: true)

        XCTAssertThrowsError(try vcService.merge(fromBranch: "nonexistent", into: "main")) { error in
            if case VersionControlError.branchNotFound = error {
                // Expected
            } else {
                XCTFail("Expected branchNotFound error")
            }
        }
    }

    func testMergeIntoNonexistentBranch() throws {
        try vcService.checkoutBranch(name: "main", createNew: true)

        XCTAssertThrowsError(try vcService.merge(fromBranch: "main", into: "nonexistent")) { error in
            if case VersionControlError.branchNotFound = error {
                // Expected
            } else {
                XCTFail("Expected branchNotFound error")
            }
        }
    }

    // MARK: - Complex Workflow Tests

    func testComplexBranchingWorkflow() throws {
        // Initialize main branch
        try vcService.initializeDefaultBranch()

        let doc1 = createTestDocument(title: "Doc 1", content: "Chapter 1")
        _ = try vcService.commit(message: "Add chapter 1", documents: [doc1])

        // Create feature branch
        try vcService.checkoutBranch(name: "feature", createNew: true)

        var doc1Feature = doc1
        doc1Feature.content = "Chapter 1 - Draft 2"
        _ = try vcService.commit(message: "Revise chapter 1", documents: [doc1Feature])

        // Switch back to main and add another chapter
        try vcService.checkoutBranch(name: "main", createNew: false)

        let doc2 = createTestDocument(title: "Doc 2", content: "Chapter 2")
        _ = try vcService.commit(message: "Add chapter 2", documents: [doc1, doc2])

        // Merge feature into main
        let result = try vcService.merge(fromBranch: "feature", into: "main")

        XCTAssertTrue(result.success)
        XCTAssertEqual(result.strategy, .threeWay)

        // Verify both chapters are present with correct content
        let snapshots = try databaseManager.getVCSnapshots(commitId: result.commitId!)
        XCTAssertEqual(snapshots.count, 2)

        let chapter1 = snapshots.first { $0.title == "Doc 1" }
        let chapter2 = snapshots.first { $0.title == "Doc 2" }

        XCTAssertEqual(chapter1?.content, "Chapter 1 - Draft 2")
        XCTAssertEqual(chapter2?.content, "Chapter 2")
    }

    func testMultipleBranchesIndependentHistory() throws {
        try vcService.checkoutBranch(name: "main", createNew: true)

        let doc = createTestDocument(title: "Doc 1", content: "Original")
        _ = try vcService.commit(message: "Initial", documents: [doc])

        // Create branch A
        try vcService.checkoutBranch(name: "branch-a", createNew: true)
        var docA = doc
        docA.content = "Branch A version"
        _ = try vcService.commit(message: "A commit", documents: [docA])

        // Create branch B from main
        try vcService.checkoutBranch(name: "main", createNew: false)
        try vcService.checkoutBranch(name: "branch-b", createNew: true)
        var docB = doc
        docB.content = "Branch B version"
        _ = try vcService.commit(message: "B commit", documents: [docB])

        // Verify each branch has its own history
        let logA = try vcService.log(branch: "branch-a")
        let logB = try vcService.log(branch: "branch-b")

        XCTAssertEqual(logA.last?.message, "A commit")
        XCTAssertEqual(logB.last?.message, "B commit")
    }

    // MARK: - Edge Cases and Error Tests

    func testEmptyCommit() throws {
        try vcService.checkoutBranch(name: "main", createNew: true)

        let commit = try vcService.commit(message: "Empty commit", documents: [])

        let snapshots = try databaseManager.getVCSnapshots(commitId: commit.id)
        XCTAssertEqual(snapshots.count, 0)
    }

    func testDiffNonexistentBranch() throws {
        try vcService.checkoutBranch(name: "main", createNew: true)

        XCTAssertThrowsError(try vcService.diff(fromBranch: "nonexistent", toBranch: "main")) { error in
            if case VersionControlError.branchNotFound = error {
                // Expected
            } else {
                XCTFail("Expected branchNotFound error")
            }
        }
    }

    func testQueryAsOfBeforeAnyCommits() throws {
        try vcService.checkoutBranch(name: "main", createNew: true)

        let doc = createTestDocument(title: "Doc 1", content: "Content")
        _ = try vcService.commit(message: "Commit", documents: [doc])

        let pastDate = Date(timeIntervalSince1970: 0)
        let snapshots = try vcService.query(asOf: pastDate)

        XCTAssertEqual(snapshots.count, 0)
    }

    func testHistoryOfNonexistentDocument() throws {
        try vcService.checkoutBranch(name: "main", createNew: true)

        let doc = createTestDocument(title: "Doc 1", content: "Content")
        _ = try vcService.commit(message: "Commit", documents: [doc])

        let nonexistentId = UUID()
        let history = try vcService.history(of: nonexistentId)

        XCTAssertEqual(history.count, 0)
    }

    func testTitleChangesDetectedAsDiff() throws {
        try vcService.checkoutBranch(name: "main", createNew: true)

        var doc = createTestDocument(title: "Original Title", content: "Content")
        _ = try vcService.commit(message: "Commit 1", documents: [doc])

        try vcService.checkoutBranch(name: "feature", createNew: true)

        doc.title = "New Title"
        _ = try vcService.commit(message: "Commit 2", documents: [doc])

        let diffs = try vcService.diff(fromBranch: "main", toBranch: "feature")

        XCTAssertEqual(diffs.count, 1)
        XCTAssertEqual(diffs[0].changeType, .modified)
    }

    // MARK: - Regression Tests

    func testBranchIsolationAfterCommit() throws {
        // Regression test: ensure commits on one branch don't affect other branches
        try vcService.checkoutBranch(name: "main", createNew: true)

        let doc = createTestDocument(title: "Doc 1", content: "Main version")
        _ = try vcService.commit(message: "Main commit", documents: [doc])

        let mainHeadBefore = try vcService.currentBranch()?.headCommitId

        // Create and commit on feature branch
        try vcService.checkoutBranch(name: "feature", createNew: true)
        var docFeature = doc
        docFeature.content = "Feature version"
        _ = try vcService.commit(message: "Feature commit", documents: [docFeature])

        // Switch back to main and verify it wasn't affected
        try vcService.checkoutBranch(name: "main", createNew: false)
        let mainHeadAfter = try vcService.currentBranch()?.headCommitId

        XCTAssertEqual(mainHeadBefore, mainHeadAfter, "Main branch should not be affected by feature branch commits")

        // Verify main still has original content
        let mainBranch = try databaseManager.getVCBranch(name: "main")!
        let mainSnapshots = try databaseManager.getVCSnapshots(commitId: mainBranch.headCommitId!)
        let mainDoc = mainSnapshots.first { $0.documentId == doc.id }
        XCTAssertEqual(mainDoc?.content, "Main version")
    }

    func testConcurrentBranchOperationsIntegrity() throws {
        // Regression test: ensure database integrity with rapid branch operations
        try vcService.checkoutBranch(name: "main", createNew: true)

        let doc = createTestDocument(title: "Doc", content: "Content")
        _ = try vcService.commit(message: "Initial", documents: [doc])

        // Rapidly create and switch between branches
        for i in 1...10 {
            try vcService.checkoutBranch(name: "branch-\(i)", createNew: true)
            var modifiedDoc = doc
            modifiedDoc.content = "Branch \(i) content"
            _ = try vcService.commit(message: "Branch \(i) commit", documents: [modifiedDoc])
        }

        // Verify all branches exist and have correct commit counts
        let branches = try vcService.listBranches()
        XCTAssertEqual(branches.count, 11) // main + 10 branches

        for i in 1...10 {
            let log = try vcService.log(branch: "branch-\(i)")
            XCTAssertEqual(log.count, 2) // Initial + branch commit
        }
    }

    func testSnapshotIntegrityAfterMultipleMerges() throws {
        // Regression test: ensure snapshots remain consistent after multiple merges
        try vcService.checkoutBranch(name: "main", createNew: true)

        let doc1 = createTestDocument(title: "Doc 1", content: "Original 1")
        let doc2 = createTestDocument(title: "Doc 2", content: "Original 2")
        _ = try vcService.commit(message: "Initial", documents: [doc1, doc2])

        // Create and merge multiple branches
        for i in 1...3 {
            try vcService.checkoutBranch(name: "feature-\(i)", createNew: true)

            var modifiedDoc1 = doc1
            modifiedDoc1.content = "Feature \(i) - Doc 1"
            _ = try vcService.commit(message: "Feature \(i)", documents: [modifiedDoc1, doc2])

            try vcService.checkoutBranch(name: "main", createNew: false)
            _ = try vcService.merge(fromBranch: "feature-\(i)", into: "main")
        }

        // Verify final state
        let mainBranch = try vcService.currentBranch()!
        let finalSnapshots = try databaseManager.getVCSnapshots(commitId: mainBranch.headCommitId!)

        XCTAssertEqual(finalSnapshots.count, 2)

        let finalDoc1 = finalSnapshots.first { $0.title == "Doc 1" }
        XCTAssertEqual(finalDoc1?.content, "Feature 3 - Doc 1", "Last merge should win")
    }

    // MARK: - Helper Methods

    private func createTestDocument(title: String, content: String = "Test content") -> Document {
        return Document(
            title: title,
            content: content,
            category: .novel
        )
    }
}