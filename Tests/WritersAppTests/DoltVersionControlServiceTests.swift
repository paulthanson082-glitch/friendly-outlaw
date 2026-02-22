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

    // MARK: - Branch Operations Tests

    func testInitializeDefaultBranch() throws {
        let branch = try vcService.initializeDefaultBranch()

        XCTAssertEqual(branch.name, "main")
        XCTAssertTrue(branch.isActive)
        XCTAssertNil(branch.headCommitId) // No commits yet
    }

    func testInitializeDefaultBranchIdempotent() throws {
        let branch1 = try vcService.initializeDefaultBranch()
        let branch2 = try vcService.initializeDefaultBranch()

        XCTAssertEqual(branch1.id, branch2.id)
        XCTAssertTrue(branch2.isActive)
    }

    func testListBranches() throws {
        try vcService.initializeDefaultBranch()
        try vcService.checkoutBranch(name: "feature", createNew: true)
        try vcService.checkoutBranch(name: "experimental", createNew: true)

        let branches = try vcService.listBranches()

        XCTAssertEqual(branches.count, 3)
        XCTAssertTrue(branches.contains { $0.name == "main" })
        XCTAssertTrue(branches.contains { $0.name == "feature" })
        XCTAssertTrue(branches.contains { $0.name == "experimental" })
    }

    func testCurrentBranch() throws {
        let branch = try vcService.initializeDefaultBranch()

        let current = try vcService.currentBranch()

        XCTAssertNotNil(current)
        XCTAssertEqual(current?.id, branch.id)
        XCTAssertEqual(current?.name, "main")
    }

    func testCurrentBranchWhenNoneActive() throws {
        // Without initialization, no branch should be active
        let current = try vcService.currentBranch()
        XCTAssertNil(current)
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

    func testCheckoutNewBranch() throws {
        try vcService.initializeDefaultBranch()

        let newBranch = try vcService.checkoutBranch(name: "feature", createNew: true)

        XCTAssertEqual(newBranch.name, "feature")
        XCTAssertTrue(newBranch.isActive)
    }

    func testCheckoutNewBranchInheritsHeadCommit() throws {
        try vcService.initializeDefaultBranch()

        let doc = Document(title: "Test", content: "Content", category: .novel)
        let commit = try vcService.commit(message: "Initial commit", documents: [doc])

        // Create new branch - should inherit head commit
        let featureBranch = try vcService.checkoutBranch(name: "feature", createNew: true)

        XCTAssertEqual(featureBranch.headCommitId, commit.id)
    }

    func testCheckoutNonExistentBranchThrows() throws {
        try vcService.initializeDefaultBranch()

        XCTAssertThrowsError(try vcService.checkoutBranch(name: "nonexistent", createNew: false)) { error in
            XCTAssertTrue(error is VersionControlError)
        }
    }

    func testCheckoutExistingBranchWithCreateNewThrows() throws {
        try vcService.initializeDefaultBranch()

        XCTAssertThrowsError(try vcService.checkoutBranch(name: "main", createNew: true)) { error in
            guard case VersionControlError.branchAlreadyExists = error else {
                XCTFail("Expected branchAlreadyExists error")
                return
            }
        }
    }

    // MARK: - Commit Operations Tests

    func testCommitSingleDocument() throws {
        try vcService.initializeDefaultBranch()

        let doc = Document(title: "My Novel", content: "Chapter 1...", category: .novel)
        let commit = try vcService.commit(message: "Add first chapter", documents: [doc])

        XCTAssertEqual(commit.message, "Add first chapter")
        XCTAssertNotNil(commit.branchId)

        // Verify branch head was updated
        let currentBranch = try vcService.currentBranch()
        XCTAssertEqual(currentBranch?.headCommitId, commit.id)
    }

    func testCommitMultipleDocuments() throws {
        try vcService.initializeDefaultBranch()

        let docs = [
            Document(title: "Chapter 1", content: "Content 1", category: .novel),
            Document(title: "Chapter 2", content: "Content 2", category: .novel),
            Document(title: "Chapter 3", content: "Content 3", category: .novel)
        ]

        let commit = try vcService.commit(message: "Add three chapters", documents: docs)

        // Verify snapshots were created
        let snapshots = try databaseManager.getVCSnapshots(commitId: commit.id)
        XCTAssertEqual(snapshots.count, 3)
        XCTAssertTrue(snapshots.contains { $0.title == "Chapter 1" })
        XCTAssertTrue(snapshots.contains { $0.title == "Chapter 2" })
        XCTAssertTrue(snapshots.contains { $0.title == "Chapter 3" })
    }

    func testCommitWithAuthor() throws {
        try vcService.initializeDefaultBranch()

        let doc = Document(title: "Test", content: "Content", category: .novel)
        let commit = try vcService.commit(
            message: "Test commit",
            documents: [doc],
            authorId: "author123"
        )

        XCTAssertEqual(commit.authorId, "author123")
    }

    func testCommitWithoutActiveBranchThrows() throws {
        let doc = Document(title: "Test", content: "Content", category: .novel)

        XCTAssertThrowsError(try vcService.commit(message: "Test", documents: [doc])) { error in
            guard case VersionControlError.noActiveBranch = error else {
                XCTFail("Expected noActiveBranch error")
                return
            }
        }
    }

    func testCommitCreatesParentChildRelationship() throws {
        try vcService.initializeDefaultBranch()

        let doc = Document(title: "Test", content: "Version 1", category: .novel)
        let commit1 = try vcService.commit(message: "First commit", documents: [doc])

        let doc2 = Document(id: doc.id, title: "Test", content: "Version 2", category: .novel)
        let commit2 = try vcService.commit(message: "Second commit", documents: [doc2])

        XCTAssertEqual(commit2.parentCommitId, commit1.id)
    }

    func testLog() throws {
        let mainBranch = try vcService.initializeDefaultBranch()

        let doc = Document(title: "Test", content: "V1", category: .novel)
        try vcService.commit(message: "Commit 1", documents: [doc])

        let doc2 = Document(id: doc.id, title: "Test", content: "V2", category: .novel)
        try vcService.commit(message: "Commit 2", documents: [doc2])

        let doc3 = Document(id: doc.id, title: "Test", content: "V3", category: .novel)
        try vcService.commit(message: "Commit 3", documents: [doc3])

        let log = try vcService.log(branch: mainBranch.name)

        XCTAssertEqual(log.count, 3)
        XCTAssertEqual(log[0].message, "Commit 1")
        XCTAssertEqual(log[1].message, "Commit 2")
        XCTAssertEqual(log[2].message, "Commit 3")
    }

    func testLogForNonExistentBranchThrows() throws {
        XCTAssertThrowsError(try vcService.log(branch: "nonexistent")) { error in
            guard case VersionControlError.branchNotFound = error else {
                XCTFail("Expected branchNotFound error")
                return
            }
        }
    }

    // MARK: - Diff Operations Tests

    func testDiffWithAddedDocument() throws {
        try vcService.initializeDefaultBranch()

        let doc1 = Document(title: "Doc 1", content: "Content 1", category: .novel)
        try vcService.commit(message: "Initial commit", documents: [doc1])

        try vcService.checkoutBranch(name: "feature", createNew: true)

        let doc2 = Document(title: "Doc 2", content: "Content 2", category: .novel)
        try vcService.commit(message: "Add doc 2", documents: [doc1, doc2])

        let diffs = try vcService.diff(fromBranch: "main", toBranch: "feature")

        XCTAssertEqual(diffs.count, 2)
        let unchanged = diffs.first { $0.title == "Doc 1" }
        let added = diffs.first { $0.title == "Doc 2" }

        XCTAssertEqual(unchanged?.changeType, .unchanged)
        XCTAssertEqual(added?.changeType, .added)
    }

    func testDiffWithModifiedDocument() throws {
        try vcService.initializeDefaultBranch()

        let doc = Document(title: "Novel", content: "Version 1", category: .novel)
        try vcService.commit(message: "Initial", documents: [doc])

        try vcService.checkoutBranch(name: "edit", createNew: true)

        let modifiedDoc = Document(id: doc.id, title: "Novel", content: "Version 2 - much longer", category: .novel)
        try vcService.commit(message: "Edit", documents: [modifiedDoc])

        let diffs = try vcService.diff(fromBranch: "main", toBranch: "edit")

        XCTAssertEqual(diffs.count, 1)
        XCTAssertEqual(diffs.first?.changeType, .modified)
        XCTAssertEqual(diffs.first?.fromContent, "Version 1")
        XCTAssertEqual(diffs.first?.toContent, "Version 2 - much longer")
        XCTAssertGreaterThan(diffs.first?.wordCountDelta ?? 0, 0)
    }

    func testDiffWithDeletedDocument() throws {
        try vcService.initializeDefaultBranch()

        let doc1 = Document(title: "Keep", content: "Content", category: .novel)
        let doc2 = Document(title: "Delete", content: "Content", category: .novel)
        try vcService.commit(message: "Two docs", documents: [doc1, doc2])

        try vcService.checkoutBranch(name: "cleanup", createNew: true)
        try vcService.commit(message: "Remove one", documents: [doc1])

        let diffs = try vcService.diff(fromBranch: "main", toBranch: "cleanup")

        XCTAssertEqual(diffs.count, 2)
        let kept = diffs.first { $0.title == "Keep" }
        let deleted = diffs.first { $0.title == "Delete" }

        XCTAssertEqual(kept?.changeType, .unchanged)
        XCTAssertEqual(deleted?.changeType, .deleted)
    }

    func testDiffIsSortedByTitle() throws {
        try vcService.initializeDefaultBranch()

        let docs = [
            Document(title: "Zebra", content: "Z", category: .novel),
            Document(title: "Alpha", content: "A", category: .novel),
            Document(title: "Beta", content: "B", category: .novel)
        ]
        try vcService.commit(message: "Initial", documents: docs)

        try vcService.checkoutBranch(name: "feature", createNew: true)
        try vcService.commit(message: "Same", documents: docs)

        let diffs = try vcService.diff(fromBranch: "main", toBranch: "feature")

        XCTAssertEqual(diffs.count, 3)
        XCTAssertEqual(diffs[0].title, "Alpha")
        XCTAssertEqual(diffs[1].title, "Beta")
        XCTAssertEqual(diffs[2].title, "Zebra")
    }

    func testDiffBetweenCommits() throws {
        let branch = try vcService.initializeDefaultBranch()

        let doc = Document(title: "Doc", content: "V1", category: .novel)
        let commit1 = try vcService.commit(message: "C1", documents: [doc])

        let doc2 = Document(id: doc.id, title: "Doc", content: "V2", category: .novel)
        let commit2 = try vcService.commit(message: "C2", documents: [doc2])

        let diffs = try vcService.diff(fromCommitId: commit1.id, toCommitId: commit2.id)

        XCTAssertEqual(diffs.count, 1)
        XCTAssertEqual(diffs.first?.changeType, .modified)
    }

    // MARK: - Time Travel Tests

    func testQueryAsOf() throws {
        try vcService.initializeDefaultBranch()

        let doc = Document(title: "Time Traveler", content: "V1", category: .novel)
        try vcService.commit(message: "V1", documents: [doc])

        let timestamp1 = Date()
        Thread.sleep(forTimeInterval: 0.1)

        let doc2 = Document(id: doc.id, title: "Time Traveler", content: "V2", category: .novel)
        try vcService.commit(message: "V2", documents: [doc2])

        Thread.sleep(forTimeInterval: 0.1)
        let timestamp2 = Date()

        // Query as of timestamp1 should get V1
        let snapshotsV1 = try vcService.query(asOf: timestamp1)
        XCTAssertEqual(snapshotsV1.count, 1)
        XCTAssertEqual(snapshotsV1.first?.content, "V1")

        // Query as of timestamp2 should get V2
        let snapshotsV2 = try vcService.query(asOf: timestamp2)
        XCTAssertEqual(snapshotsV2.count, 1)
        XCTAssertEqual(snapshotsV2.first?.content, "V2")
    }

    func testHistoryOfDocument() throws {
        try vcService.initializeDefaultBranch()

        let docId = UUID()
        for i in 1...5 {
            let doc = Document(id: docId, title: "Novel", content: "Version \(i)", category: .novel)
            try vcService.commit(message: "V\(i)", documents: [doc])
        }

        let history = try vcService.history(of: docId)

        XCTAssertEqual(history.count, 5)
        XCTAssertEqual(history[0].content, "Version 1")
        XCTAssertEqual(history[1].content, "Version 2")
        XCTAssertEqual(history[2].content, "Version 3")
        XCTAssertEqual(history[3].content, "Version 4")
        XCTAssertEqual(history[4].content, "Version 5")
    }

    func testHistoryOfNonExistentDocument() throws {
        try vcService.initializeDefaultBranch()

        let doc = Document(title: "Test", content: "Content", category: .novel)
        try vcService.commit(message: "Test", documents: [doc])

        let history = try vcService.history(of: UUID())
        XCTAssertTrue(history.isEmpty)
    }

    // MARK: - Merge Operations Tests

    func testMergeFastForwardToEmptyBranch() throws {
        try vcService.initializeDefaultBranch()

        let doc = Document(title: "Doc", content: "Content", category: .novel)
        try vcService.commit(message: "Initial commit", documents: [doc])

        // Create empty branch
        try vcService.checkoutBranch(name: "empty", createNew: true)
        let emptyBranch = try vcService.currentBranch()
        XCTAssertNil(emptyBranch?.headCommitId)

        // Merge main into empty
        let result = try vcService.merge(fromBranch: "main", into: "empty")

        XCTAssertTrue(result.success)
        XCTAssertEqual(result.strategy, .fastForward)
        XCTAssertEqual(result.diffCount, 1)
    }

    func testMergeWithNoChanges() throws {
        try vcService.initializeDefaultBranch()

        let doc = Document(title: "Doc", content: "Content", category: .novel)
        try vcService.commit(message: "Commit", documents: [doc])

        try vcService.checkoutBranch(name: "feature", createNew: true)

        // Merge main into feature (no changes)
        let result = try vcService.merge(fromBranch: "main", into: "feature")

        XCTAssertTrue(result.success)
        XCTAssertEqual(result.diffCount, 0)
    }

    func testMergeThreeWayWithNewDocuments() throws {
        try vcService.initializeDefaultBranch()

        let doc1 = Document(title: "Base", content: "Base content", category: .novel)
        try vcService.commit(message: "Base", documents: [doc1])

        // Create feature branch and add document
        try vcService.checkoutBranch(name: "feature", createNew: true)
        let doc2 = Document(title: "Feature", content: "Feature content", category: .novel)
        try vcService.commit(message: "Add feature doc", documents: [doc1, doc2])

        // Switch back to main and commit
        try vcService.checkoutBranch(name: "main")
        let doc3 = Document(title: "Main", content: "Main content", category: .novel)
        try vcService.commit(message: "Add main doc", documents: [doc1, doc3])

        // Merge feature into main
        let result = try vcService.merge(fromBranch: "feature", into: "main")

        XCTAssertTrue(result.success)
        XCTAssertEqual(result.strategy, .threeWay)
        XCTAssertGreaterThan(result.diffCount, 0)

        // Verify merge commit exists
        let log = try vcService.log(branch: "main")
        let mergeCommit = log.last
        XCTAssertTrue(mergeCommit?.message.contains("Merge") ?? false)
        XCTAssertNotNil(mergeCommit?.secondParentCommitId)
    }

    func testMergeThreeWayWithModifiedDocuments() throws {
        try vcService.initializeDefaultBranch()

        let doc = Document(title: "Shared", content: "Original", category: .novel)
        try vcService.commit(message: "Initial", documents: [doc])

        // Modify on feature branch
        try vcService.checkoutBranch(name: "feature", createNew: true)
        let featureDoc = Document(id: doc.id, title: "Shared", content: "Feature version", category: .novel)
        try vcService.commit(message: "Feature edit", documents: [featureDoc])

        // Modify on main branch
        try vcService.checkoutBranch(name: "main")
        let mainDoc = Document(id: doc.id, title: "Shared", content: "Main version", category: .novel)
        try vcService.commit(message: "Main edit", documents: [mainDoc])

        // Merge feature into main (last-writer-wins)
        let result = try vcService.merge(fromBranch: "feature", into: "main")

        XCTAssertTrue(result.success)
        XCTAssertEqual(result.strategy, .threeWay)

        // Verify the merge commit was created
        XCTAssertNotNil(result.commitId)
    }

    func testMergeFromNonExistentBranchThrows() throws {
        try vcService.initializeDefaultBranch()

        XCTAssertThrowsError(try vcService.merge(fromBranch: "nonexistent", into: "main")) { error in
            guard case VersionControlError.branchNotFound = error else {
                XCTFail("Expected branchNotFound error")
                return
            }
        }
    }

    func testMergeIntoNonExistentBranchThrows() throws {
        try vcService.initializeDefaultBranch()

        XCTAssertThrowsError(try vcService.merge(fromBranch: "main", into: "nonexistent")) { error in
            guard case VersionControlError.branchNotFound = error else {
                XCTFail("Expected branchNotFound error")
                return
            }
        }
    }

    // MARK: - Complex Workflow Tests

    func testCompleteWorkflow() throws {
        // 1. Initialize
        try vcService.initializeDefaultBranch()

        // 2. Create initial commit
        let doc1 = Document(title: "Chapter 1", content: "Once upon a time...", category: .novel)
        try vcService.commit(message: "Start novel", documents: [doc1])

        // 3. Create feature branch and add content
        try vcService.checkoutBranch(name: "chapter2", createNew: true)
        let doc2 = Document(title: "Chapter 2", content: "Meanwhile...", category: .novel)
        try vcService.commit(message: "Add chapter 2", documents: [doc1, doc2])

        // 4. Go back to main and make changes
        try vcService.checkoutBranch(name: "main")
        let doc1Updated = Document(id: doc1.id, title: "Chapter 1", content: "Once upon a time in a land far away...", category: .novel)
        try vcService.commit(message: "Expand chapter 1", documents: [doc1Updated])

        // 5. Compare branches
        let diffs = try vcService.diff(fromBranch: "main", toBranch: "chapter2")
        XCTAssertEqual(diffs.count, 2) // Both chapters present in diff

        // 6. Merge feature branch
        let mergeResult = try vcService.merge(fromBranch: "chapter2", into: "main")
        XCTAssertTrue(mergeResult.success)

        // 7. Verify merged state
        let log = try vcService.log(branch: "main")
        XCTAssertEqual(log.count, 3) // Initial + expand + merge
    }

    func testMultipleBranchesWorkflow() throws {
        try vcService.initializeDefaultBranch()

        let doc = Document(title: "Base", content: "Base", category: .novel)
        try vcService.commit(message: "Base", documents: [doc])

        // Create multiple feature branches
        for i in 1...3 {
            try vcService.checkoutBranch(name: "feature\(i)", createNew: true)
            let newDoc = Document(id: doc.id, title: "Base", content: "Base + Feature \(i)", category: .novel)
            try vcService.commit(message: "Feature \(i) changes", documents: [newDoc])
        }

        // Verify all branches exist
        let branches = try vcService.listBranches()
        XCTAssertEqual(branches.count, 4) // main + 3 features

        // Switch between branches
        try vcService.checkoutBranch(name: "feature1")
        XCTAssertEqual(try vcService.currentBranch()?.name, "feature1")

        try vcService.checkoutBranch(name: "feature2")
        XCTAssertEqual(try vcService.currentBranch()?.name, "feature2")
    }

    func testDocumentEvolutionTracking() throws {
        try vcService.initializeDefaultBranch()

        let docId = UUID()
        let versions = [
            "Draft 1: The beginning",
            "Draft 2: Added middle section",
            "Draft 3: Revised ending",
            "Draft 4: Final polish",
            "Draft 5: Publisher feedback incorporated"
        ]

        for (index, content) in versions.enumerated() {
            let doc = Document(id: docId, title: "My Novel", content: content, category: .novel)
            try vcService.commit(message: "Draft \(index + 1)", documents: [doc])
        }

        // Get full history
        let history = try vcService.history(of: docId)
        XCTAssertEqual(history.count, 5)

        for i in 0..<5 {
            XCTAssertEqual(history[i].content, versions[i])
        }

        // Get snapshot at a specific point
        let commits = try vcService.log(branch: "main")
        let thirdCommit = commits[2]

        let snapshotsAtDraft3 = try databaseManager.getVCSnapshots(commitId: thirdCommit.id)
        XCTAssertEqual(snapshotsAtDraft3.first?.content, "Draft 3: Revised ending")
    }

    // MARK: - Edge Cases and Error Handling

    func testCommitEmptyDocumentList() throws {
        try vcService.initializeDefaultBranch()

        let commit = try vcService.commit(message: "Empty commit", documents: [])

        let snapshots = try databaseManager.getVCSnapshots(commitId: commit.id)
        XCTAssertTrue(snapshots.isEmpty)
    }

    func testDiffWhenBranchHasNoCommits() throws {
        try vcService.initializeDefaultBranch()

        let doc = Document(title: "Doc", content: "Content", category: .novel)
        try vcService.commit(message: "Commit", documents: [doc])

        try vcService.checkoutBranch(name: "empty", createNew: true)

        // This should throw because empty branch has no commits
        XCTAssertThrowsError(try vcService.diff(fromBranch: "empty", toBranch: "main"))
    }

    func testCommitWithVeryLongMessage() throws {
        try vcService.initializeDefaultBranch()

        let longMessage = String(repeating: "This is a very detailed commit message explaining all the changes made in this commit. ", count: 50)
        let doc = Document(title: "Doc", content: "Content", category: .novel)
        let commit = try vcService.commit(message: longMessage, documents: [doc])

        let log = try vcService.log(branch: "main")
        XCTAssertEqual(log.first?.message, longMessage)
    }

    func testCommitWithSpecialCharactersInContent() throws {
        try vcService.initializeDefaultBranch()

        let specialContent = "Content with 'quotes', \"double quotes\", and other special chars: @#$%^&*()"
        let doc = Document(title: "Special", content: specialContent, category: .novel)
        try vcService.commit(message: "Special chars", documents: [doc])

        let snapshots = try databaseManager.getVCSnapshots(
            commitId: (try vcService.currentBranch()?.headCommitId)!
        )
        XCTAssertEqual(snapshots.first?.content, specialContent)
    }

    func testWordCountDeltaInDiff() throws {
        try vcService.initializeDefaultBranch()

        let doc = Document(title: "Doc", content: "One two three", category: .novel)
        try vcService.commit(message: "Initial", documents: [doc])

        try vcService.checkoutBranch(name: "expand", createNew: true)
        let expandedDoc = Document(id: doc.id, title: "Doc", content: "One two three four five six seven eight nine ten", category: .novel)
        try vcService.commit(message: "Expand", documents: [expandedDoc])

        let diffs = try vcService.diff(fromBranch: "main", toBranch: "expand")

        XCTAssertEqual(diffs.count, 1)
        XCTAssertEqual(diffs.first?.fromWordCount, 3)
        XCTAssertEqual(diffs.first?.toWordCount, 10)
        XCTAssertEqual(diffs.first?.wordCountDelta, 7)
    }

    // MARK: - Regression Tests

    func testBranchSwitchingPreservesData() throws {
        try vcService.initializeDefaultBranch()

        let doc1 = Document(title: "Main Doc", content: "Main content", category: .novel)
        try vcService.commit(message: "Main commit", documents: [doc1])

        try vcService.checkoutBranch(name: "feature", createNew: true)
        let doc2 = Document(title: "Feature Doc", content: "Feature content", category: .novel)
        try vcService.commit(message: "Feature commit", documents: [doc1, doc2])

        // Switch back and forth
        try vcService.checkoutBranch(name: "main")
        let mainLog = try vcService.log(branch: "main")
        XCTAssertEqual(mainLog.count, 1)

        try vcService.checkoutBranch(name: "feature")
        let featureLog = try vcService.log(branch: "feature")
        XCTAssertEqual(featureLog.count, 2)
    }

    func testMergeDoesNotLoseDocuments() throws {
        try vcService.initializeDefaultBranch()

        let doc1 = Document(title: "Doc 1", content: "Content 1", category: .novel)
        try vcService.commit(message: "Add doc 1", documents: [doc1])

        try vcService.checkoutBranch(name: "add-doc2", createNew: true)
        let doc2 = Document(title: "Doc 2", content: "Content 2", category: .novel)
        try vcService.commit(message: "Add doc 2", documents: [doc1, doc2])

        try vcService.checkoutBranch(name: "main")
        let doc3 = Document(title: "Doc 3", content: "Content 3", category: .novel)
        try vcService.commit(message: "Add doc 3", documents: [doc1, doc3])

        let result = try vcService.merge(fromBranch: "add-doc2", into: "main")
        XCTAssertTrue(result.success)

        // Verify all three documents are in the merge commit
        let mergeCommit = result.commitId!
        let snapshots = try databaseManager.getVCSnapshots(commitId: mergeCommit)
        XCTAssertEqual(snapshots.count, 3)
        XCTAssertTrue(snapshots.contains { $0.title == "Doc 1" })
        XCTAssertTrue(snapshots.contains { $0.title == "Doc 2" })
        XCTAssertTrue(snapshots.contains { $0.title == "Doc 3" })
    }

    // MARK: - Additional Strengthening Tests

    func testMergeFromEmptyBranchReturnsSuccess() throws {
        try vcService.initializeDefaultBranch()

        let doc = Document(title: "Doc", content: "Content", category: .novel)
        try vcService.commit(message: "Commit on main", documents: [doc])

        // Create new empty branch (no commits)
        try vcService.checkoutBranch(name: "empty", createNew: true)
        // Immediately switch back to empty - this creates branch with inherited head
        try vcService.checkoutBranch(name: "main")

        // Now manually create truly empty branch by inserting without head
        let emptyBranch = VCBranch(name: "truly-empty", headCommitId: nil, isActive: false)
        try databaseManager.insertVCBranch(emptyBranch)

        // Merge from empty branch into main
        let result = try vcService.merge(fromBranch: "truly-empty", into: "main")

        XCTAssertTrue(result.success)
        XCTAssertEqual(result.strategy, .fastForward)
        XCTAssertEqual(result.diffCount, 0)
    }

    func testDiffDetectsTitleChange() throws {
        try vcService.initializeDefaultBranch()

        let doc = Document(title: "Original Title", content: "Same content", category: .novel)
        try vcService.commit(message: "Initial", documents: [doc])

        try vcService.checkoutBranch(name: "rename", createNew: true)

        // Change only the title, keep content the same
        let renamedDoc = Document(id: doc.id, title: "New Title", content: "Same content", category: .novel)
        try vcService.commit(message: "Rename", documents: [renamedDoc])

        let diffs = try vcService.diff(fromBranch: "main", toBranch: "rename")

        XCTAssertEqual(diffs.count, 1)
        // Should be marked as modified even if only title changed
        XCTAssertEqual(diffs.first?.changeType, .modified)
        XCTAssertEqual(diffs.first?.title, "New Title")
        XCTAssertEqual(diffs.first?.fromContent, "Same content")
        XCTAssertEqual(diffs.first?.toContent, "Same content")
    }

    func testDiffWithOnlyTitleChangeStillShowsModified() throws {
        try vcService.initializeDefaultBranch()

        let docId = UUID()
        let doc1 = Document(id: docId, title: "Chapter One", content: "Story begins", category: .novel)
        try vcService.commit(message: "First", documents: [doc1])

        try vcService.checkoutBranch(name: "retitle", createNew: true)

        let doc2 = Document(id: docId, title: "Chapter 1: The Beginning", content: "Story begins", category: .novel)
        try vcService.commit(message: "Better title", documents: [doc2])

        let diffs = try vcService.diff(fromBranch: "main", toBranch: "retitle")

        XCTAssertEqual(diffs.count, 1)
        XCTAssertEqual(diffs.first?.changeType, .modified)
        // Content is unchanged but it's still a modification
        XCTAssertEqual(diffs.first?.fromContent, diffs.first?.toContent)
    }

    func testCommitPreservesDocumentWordCount() throws {
        try vcService.initializeDefaultBranch()

        let doc = Document(title: "Test", content: "one two three four five", category: .novel)
        let commit = try vcService.commit(message: "Test", documents: [doc])

        let snapshots = try databaseManager.getVCSnapshots(commitId: commit.id)
        XCTAssertEqual(snapshots.first?.wordCount, 5)
    }

    func testBranchCreationTimestamp() throws {
        let beforeTime = Date()
        let branch = try vcService.initializeDefaultBranch()
        let afterTime = Date()

        XCTAssertGreaterThanOrEqual(branch.createdAt, beforeTime)
        XCTAssertLessThanOrEqual(branch.createdAt, afterTime)
    }

    func testCommitTimestamp() throws {
        try vcService.initializeDefaultBranch()

        let beforeTime = Date()
        let doc = Document(title: "Test", content: "Content", category: .novel)
        let commit = try vcService.commit(message: "Test", documents: [doc])
        let afterTime = Date()

        XCTAssertGreaterThanOrEqual(commit.timestamp, beforeTime)
        XCTAssertLessThanOrEqual(commit.timestamp, afterTime)
    }

    func testQueryAsOfBeforeAnyCommits() throws {
        try vcService.initializeDefaultBranch()

        let doc = Document(title: "Doc", content: "Content", category: .novel)
        try vcService.commit(message: "Commit", documents: [doc])

        // Query before any commits
        let veryOldDate = Date(timeIntervalSince1970: 0)
        let snapshots = try vcService.query(asOf: veryOldDate)

        XCTAssertTrue(snapshots.isEmpty)
    }

    func testMergeTwiceFromSameBranch() throws {
        try vcService.initializeDefaultBranch()

        let doc1 = Document(title: "Doc", content: "V1", category: .novel)
        try vcService.commit(message: "V1", documents: [doc1])

        try vcService.checkoutBranch(name: "feature", createNew: true)
        let doc2 = Document(id: doc1.id, title: "Doc", content: "V2", category: .novel)
        try vcService.commit(message: "V2", documents: [doc2])

        try vcService.checkoutBranch(name: "main")

        // First merge
        let result1 = try vcService.merge(fromBranch: "feature", into: "main")
        XCTAssertTrue(result1.success)

        // Second merge (should have no changes)
        let result2 = try vcService.merge(fromBranch: "feature", into: "main")
        XCTAssertTrue(result2.success)
        XCTAssertEqual(result2.diffCount, 0) // No new changes
    }

    func testLogEmptyBranch() throws {
        let branch = try vcService.initializeDefaultBranch()

        let log = try vcService.log(branch: branch.name)
        XCTAssertTrue(log.isEmpty)
    }

    func testMultipleDocumentsWithSameContent() throws {
        try vcService.initializeDefaultBranch()

        let sameContent = "This is the same content"
        let docs = [
            Document(title: "Doc 1", content: sameContent, category: .novel),
            Document(title: "Doc 2", content: sameContent, category: .novel),
            Document(title: "Doc 3", content: sameContent, category: .novel)
        ]

        let commit = try vcService.commit(message: "Same content", documents: docs)

        let snapshots = try databaseManager.getVCSnapshots(commitId: commit.id)
        XCTAssertEqual(snapshots.count, 3)
        XCTAssertTrue(snapshots.allSatisfy { $0.content == sameContent })
    }

    func testDiffWithEmptyContent() throws {
        try vcService.initializeDefaultBranch()

        let doc1 = Document(title: "Empty", content: "", category: .novel)
        try vcService.commit(message: "Empty doc", documents: [doc1])

        try vcService.checkoutBranch(name: "add-content", createNew: true)

        let doc2 = Document(id: doc1.id, title: "Empty", content: "Now has content", category: .novel)
        try vcService.commit(message: "Add content", documents: [doc2])

        let diffs = try vcService.diff(fromBranch: "main", toBranch: "add-content")

        XCTAssertEqual(diffs.count, 1)
        XCTAssertEqual(diffs.first?.changeType, .modified)
        XCTAssertEqual(diffs.first?.fromContent, "")
        XCTAssertEqual(diffs.first?.toContent, "Now has content")
    }

    func testHistoryAcrossBranches() throws {
        try vcService.initializeDefaultBranch()

        let docId = UUID()
        let doc1 = Document(id: docId, title: "Doc", content: "V1 on main", category: .novel)
        try vcService.commit(message: "Main V1", documents: [doc1])

        // Create branch and make changes
        try vcService.checkoutBranch(name: "branch1", createNew: true)
        let doc2 = Document(id: docId, title: "Doc", content: "V2 on branch1", category: .novel)
        try vcService.commit(message: "Branch1 V2", documents: [doc2])

        // Switch back to main and make more changes
        try vcService.checkoutBranch(name: "main")
        let doc3 = Document(id: docId, title: "Doc", content: "V3 on main", category: .novel)
        try vcService.commit(message: "Main V3", documents: [doc3])

        // History should show all versions across branches
        let history = try vcService.history(of: docId)
        XCTAssertEqual(history.count, 3)
        XCTAssertTrue(history.contains { $0.content == "V1 on main" })
        XCTAssertTrue(history.contains { $0.content == "V2 on branch1" })
        XCTAssertTrue(history.contains { $0.content == "V3 on main" })
    }
}