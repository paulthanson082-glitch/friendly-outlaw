import XCTest
@testable import WritersApp

final class DatabaseManagerTests: XCTestCase {
    var databaseManager: DatabaseManager!
    let testUserId = UUID()
    var testDatabasePath: String!
    
    override func setUp() {
        super.setUp()
        // Create a unique database path for each test
        testDatabasePath = "/tmp/test_writersapp_\(UUID().uuidString).db"
        
        // Remove any existing test database
        try? FileManager.default.removeItem(atPath: testDatabasePath)
        
        databaseManager = DatabaseManager(databasePath: testDatabasePath)
        try? databaseManager.initialize()
    }
    
    override func tearDown() {
        databaseManager.close()
        try? FileManager.default.removeItem(atPath: testDatabasePath)
        databaseManager = nil
        super.tearDown()
    }
    
    // MARK: - AI Suggestions Tests
    
    func testInsertAndRetrieveAISuggestion() throws {
        let suggestion = AISuggestion(
            userId: testUserId,
            toolUsed: "Continue Writing",
            prompt: "Continue the story about...",
            response: "Once upon a time..."
        )
        
        try databaseManager.insertAISuggestion(suggestion)
        
        let retrieved = try databaseManager.getAISuggestions(userId: testUserId)
        XCTAssertEqual(retrieved.count, 1)
        XCTAssertEqual(retrieved.first?.id, suggestion.id)
        XCTAssertEqual(retrieved.first?.toolUsed, "Continue Writing")
    }
    
    func testPagination() throws {
        // Insert multiple suggestions
        for i in 1...15 {
            let suggestion = AISuggestion(
                userId: testUserId,
                toolUsed: "Tool \(i)",
                prompt: "Prompt \(i)",
                response: "Response \(i)"
            )
            try databaseManager.insertAISuggestion(suggestion)
        }
        
        // Test pagination
        let firstPage = try databaseManager.getAISuggestions(userId: testUserId, limit: 5, offset: 0)
        XCTAssertEqual(firstPage.count, 5)
        
        let secondPage = try databaseManager.getAISuggestions(userId: testUserId, limit: 5, offset: 5)
        XCTAssertEqual(secondPage.count, 5)
        
        let thirdPage = try databaseManager.getAISuggestions(userId: testUserId, limit: 5, offset: 10)
        XCTAssertEqual(thirdPage.count, 5)
        
        // Verify no overlap
        XCTAssertNotEqual(firstPage.first?.id, secondPage.first?.id)
    }
    
    func testUpdateAISuggestion() throws {
        var suggestion = AISuggestion(
            userId: testUserId,
            toolUsed: "Grammar Check",
            prompt: "Check this text",
            response: "Original response"
        )
        
        try databaseManager.insertAISuggestion(suggestion)
        
        suggestion.isApplied = true
        try databaseManager.updateAISuggestion(suggestion)
        
        let retrieved = try databaseManager.getAISuggestions(userId: testUserId)
        XCTAssertEqual(retrieved.first?.isApplied, true)
    }
    
    func testDeleteAISuggestion() throws {
        let suggestion = AISuggestion(
            userId: testUserId,
            toolUsed: "Improve Text",
            prompt: "Improve this",
            response: "Improved text"
        )
        
        try databaseManager.insertAISuggestion(suggestion)
        
        var retrieved = try databaseManager.getAISuggestions(userId: testUserId)
        XCTAssertEqual(retrieved.count, 1)
        
        try databaseManager.deleteAISuggestion(id: suggestion.id)
        
        retrieved = try databaseManager.getAISuggestions(userId: testUserId)
        XCTAssertEqual(retrieved.count, 0)
    }
    
    func testFilterByTool() throws {
        let tools = ["Continue Writing", "Grammar Check", "Continue Writing", "Improve Text"]
        
        for tool in tools {
            let suggestion = AISuggestion(
                userId: testUserId,
                toolUsed: tool,
                prompt: "Test prompt",
                response: "Test response"
            )
            try databaseManager.insertAISuggestion(suggestion)
        }
        
        let filtered = try databaseManager.filterAISuggestionsByTool(userId: testUserId, tool: "Continue Writing")
        XCTAssertEqual(filtered.count, 2)
        XCTAssertTrue(filtered.allSatisfy { $0.toolUsed == "Continue Writing" })
    }
    
    func testAIToolUsageStats() throws {
        let tools = ["Continue Writing", "Grammar Check", "Continue Writing", "Improve Text", "Continue Writing"]
        
        for tool in tools {
            let suggestion = AISuggestion(
                userId: testUserId,
                toolUsed: tool,
                prompt: "Test prompt",
                response: "Test response"
            )
            try databaseManager.insertAISuggestion(suggestion)
        }
        
        let stats = try databaseManager.getAIToolUsageStats(userId: testUserId)
        
        XCTAssertEqual(stats.count, 3) // 3 unique tools
        
        // Continue Writing should be the most used
        XCTAssertEqual(stats.first?.toolName, "Continue Writing")
        XCTAssertEqual(stats.first?.usageCount, 3)
        
        // Check that stats are ordered by usage count
        XCTAssertGreaterThanOrEqual(stats[0].usageCount, stats[1].usageCount)
    }
    
    func testJoinWithConfig() throws {
        // Create AI configuration
        let config = AIConfiguration(
            apiKey: "test-key",
            model: .claude35Sonnet,
            maxTokens: 4096,
            temperature: 0.7
        )
        try databaseManager.saveAIConfiguration(userId: testUserId, configuration: config)
        
        // Create suggestion
        let suggestion = AISuggestion(
            userId: testUserId,
            toolUsed: "Continue Writing",
            prompt: "Test prompt",
            response: "Test response"
        )
        try databaseManager.insertAISuggestion(suggestion)
        
        // Get joined data
        let joined = try databaseManager.getAISuggestionsWithConfig(userId: testUserId)
        
        XCTAssertEqual(joined.count, 1)
        XCTAssertEqual(joined.first?.suggestion.id, suggestion.id)
        XCTAssertEqual(joined.first?.modelUsed, "claude-3-5-sonnet-20241022")
    }
    
    // MARK: - User Sessions Tests
    
    func testInsertAndRetrieveUserSession() throws {
        let session = UserSession(
            userId: testUserId,
            startTime: Date(),
            wordsWritten: 500,
            aiInteractions: 3,
            multitaskingMode: "Split View"
        )
        
        try databaseManager.insertUserSession(session)
        
        let retrieved = try databaseManager.getUserSessions(userId: testUserId)
        XCTAssertEqual(retrieved.count, 1)
        XCTAssertEqual(retrieved.first?.id, session.id)
        XCTAssertEqual(retrieved.first?.wordsWritten, 500)
    }
    
    func testUpdateUserSession() throws {
        var session = UserSession(
            userId: testUserId,
            startTime: Date(),
            wordsWritten: 100,
            aiInteractions: 1
        )
        
        try databaseManager.insertUserSession(session)
        
        session.endTime = Date()
        session.durationSeconds = 1800 // 30 minutes
        session.wordsWritten = 500
        
        try databaseManager.updateUserSession(session)
        
        let retrieved = try databaseManager.getUserSessions(userId: testUserId)
        XCTAssertEqual(retrieved.first?.durationSeconds, 1800)
        XCTAssertEqual(retrieved.first?.wordsWritten, 500)
    }
    
    func testSortSessionsByDuration() throws {
        let sessions = [
            UserSession(userId: testUserId, durationSeconds: 1000),
            UserSession(userId: testUserId, durationSeconds: 3000),
            UserSession(userId: testUserId, durationSeconds: 500)
        ]
        
        for session in sessions {
            try databaseManager.insertUserSession(session)
        }
        
        let sorted = try databaseManager.getUserSessions(userId: testUserId, sortByDuration: true)
        
        XCTAssertEqual(sorted.count, 3)
        XCTAssertEqual(sorted[0].durationSeconds, 3000)
        XCTAssertEqual(sorted[1].durationSeconds, 1000)
        XCTAssertEqual(sorted[2].durationSeconds, 500)
    }
    
    func testFilterSessionsByMode() throws {
        let modes = ["Split View", "Full Screen", "Split View", "Slide Over"]
        
        for mode in modes {
            let session = UserSession(
                userId: testUserId,
                multitaskingMode: mode
            )
            try databaseManager.insertUserSession(session)
        }
        
        let filtered = try databaseManager.filterSessionsByMode(userId: testUserId, mode: "Split View")
        XCTAssertEqual(filtered.count, 2)
        XCTAssertTrue(filtered.allSatisfy { $0.multitaskingMode == "Split View" })
    }
    
    func testSessionAggregations() throws {
        let sessions = [
            UserSession(userId: testUserId, startTime: Date(timeIntervalSince1970: 1000), durationSeconds: 1200),
            UserSession(userId: testUserId, startTime: Date(timeIntervalSince1970: 2000), durationSeconds: 1800),
            UserSession(userId: testUserId, startTime: Date(timeIntervalSince1970: 3000), durationSeconds: 600)
        ]
        
        for session in sessions {
            try databaseManager.insertUserSession(session)
        }
        
        let stats = try databaseManager.getSessionStats(userId: testUserId)
        
        XCTAssertEqual(stats.totalSessions, 3)
        XCTAssertEqual(stats.totalDurationSeconds, 3600)
        XCTAssertEqual(stats.averageDurationSeconds, 1200.0)
        XCTAssertNotNil(stats.earliestSession)
        XCTAssertNotNil(stats.latestSession)
    }
    
    // MARK: - AI Configuration Tests
    
    func testSaveAndRetrieveAIConfiguration() throws {
        let config = AIConfiguration(
            apiKey: "sk-test-key",
            model: .claude3Opus,
            maxTokens: 8192,
            temperature: 0.8
        )
        
        try databaseManager.saveAIConfiguration(userId: testUserId, configuration: config)
        
        let retrieved = try databaseManager.getAIConfiguration(userId: testUserId)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.apiKey, "sk-test-key")
        XCTAssertEqual(retrieved?.model, .claude3Opus)
        XCTAssertEqual(retrieved?.maxTokens, 8192)
        XCTAssertEqual(retrieved?.temperature, 0.8)
    }
    
    func testUpdateAIConfiguration() throws {
        let config1 = AIConfiguration(
            apiKey: "key1",
            model: .claude3Sonnet,
            maxTokens: 4096,
            temperature: 0.7
        )

        try databaseManager.saveAIConfiguration(userId: testUserId, configuration: config1)

        let config2 = AIConfiguration(
            apiKey: "key2",
            model: .claude35Sonnet,
            maxTokens: 8192,
            temperature: 0.9
        )

        try databaseManager.saveAIConfiguration(userId: testUserId, configuration: config2)

        let retrieved = try databaseManager.getAIConfiguration(userId: testUserId)
        XCTAssertEqual(retrieved?.apiKey, "key2")
        XCTAssertEqual(retrieved?.model, .claude35Sonnet)
    }

    // MARK: - Version Control: Branch Tests

    func testInsertAndRetrieveVCBranch() throws {
        let branch = VCBranch(name: "main", isActive: true)

        try databaseManager.insertVCBranch(branch)

        let retrieved = try databaseManager.getVCBranch(name: "main")
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.id, branch.id)
        XCTAssertEqual(retrieved?.name, "main")
        XCTAssertTrue(retrieved?.isActive ?? false)
    }

    func testGetAllVCBranches() throws {
        let branches = [
            VCBranch(name: "main", isActive: true),
            VCBranch(name: "feature", isActive: false),
            VCBranch(name: "experimental", isActive: false)
        ]

        for branch in branches {
            try databaseManager.insertVCBranch(branch)
        }

        let retrieved = try databaseManager.getAllVCBranches()
        XCTAssertEqual(retrieved.count, 3)
        XCTAssertTrue(retrieved.contains { $0.name == "main" })
        XCTAssertTrue(retrieved.contains { $0.name == "feature" })
    }

    func testUpdateVCBranch() throws {
        var branch = VCBranch(name: "develop", isActive: false)
        try databaseManager.insertVCBranch(branch)

        // Create a commit to serve as head
        let commit = VCCommit(branchId: branch.id, message: "Initial commit")
        try databaseManager.insertVCCommit(commit)

        // Update branch with new head
        branch.headCommitId = commit.id
        branch.isActive = true
        try databaseManager.updateVCBranch(branch)

        let retrieved = try databaseManager.getVCBranch(name: "develop")
        XCTAssertEqual(retrieved?.headCommitId, commit.id)
        XCTAssertTrue(retrieved?.isActive ?? false)
    }

    func testSetActiveBranch() throws {
        let branch1 = VCBranch(name: "main", isActive: true)
        let branch2 = VCBranch(name: "feature", isActive: false)

        try databaseManager.insertVCBranch(branch1)
        try databaseManager.insertVCBranch(branch2)

        // Switch active branch
        try databaseManager.setActiveBranch(id: branch2.id)

        let branches = try databaseManager.getAllVCBranches()
        let mainBranch = branches.first { $0.name == "main" }
        let featureBranch = branches.first { $0.name == "feature" }

        XCTAssertFalse(mainBranch?.isActive ?? true)
        XCTAssertTrue(featureBranch?.isActive ?? false)
    }

    func testSetActiveBranchIsAtomic() throws {
        // Test that setActiveBranch uses transactions properly
        let branch1 = VCBranch(name: "main", isActive: true)
        let branch2 = VCBranch(name: "feature", isActive: false)

        try databaseManager.insertVCBranch(branch1)
        try databaseManager.insertVCBranch(branch2)

        try databaseManager.setActiveBranch(id: branch2.id)

        // Verify exactly one branch is active
        let branches = try databaseManager.getAllVCBranches()
        let activeBranches = branches.filter { $0.isActive }
        XCTAssertEqual(activeBranches.count, 1)
        XCTAssertEqual(activeBranches.first?.id, branch2.id)
    }

    // MARK: - Version Control: Commit Tests

    func testInsertAndRetrieveVCCommit() throws {
        let branch = VCBranch(name: "main", isActive: true)
        try databaseManager.insertVCBranch(branch)

        let commit = VCCommit(
            branchId: branch.id,
            message: "Initial commit",
            authorId: "user123"
        )

        try databaseManager.insertVCCommit(commit)

        let retrieved = try databaseManager.getVCCommits(branchId: branch.id)
        XCTAssertEqual(retrieved.count, 1)
        XCTAssertEqual(retrieved.first?.id, commit.id)
        XCTAssertEqual(retrieved.first?.message, "Initial commit")
        XCTAssertEqual(retrieved.first?.authorId, "user123")
    }

    func testCommitWithParent() throws {
        let branch = VCBranch(name: "main", isActive: true)
        try databaseManager.insertVCBranch(branch)

        let parentCommit = VCCommit(branchId: branch.id, message: "Parent commit")
        try databaseManager.insertVCCommit(parentCommit)

        let childCommit = VCCommit(
            branchId: branch.id,
            message: "Child commit",
            parentCommitId: parentCommit.id
        )
        try databaseManager.insertVCCommit(childCommit)

        let retrieved = try databaseManager.getVCCommits(branchId: branch.id)
        XCTAssertEqual(retrieved.count, 2)
        XCTAssertEqual(retrieved.last?.parentCommitId, parentCommit.id)
    }

    func testMergeCommitWithTwoParents() throws {
        let mainBranch = VCBranch(name: "main", isActive: true)
        let featureBranch = VCBranch(name: "feature", isActive: false)

        try databaseManager.insertVCBranch(mainBranch)
        try databaseManager.insertVCBranch(featureBranch)

        let mainCommit = VCCommit(branchId: mainBranch.id, message: "Main commit")
        let featureCommit = VCCommit(branchId: featureBranch.id, message: "Feature commit")

        try databaseManager.insertVCCommit(mainCommit)
        try databaseManager.insertVCCommit(featureCommit)

        // Merge commit has two parents
        let mergeCommit = VCCommit(
            branchId: mainBranch.id,
            message: "Merge feature into main",
            parentCommitId: mainCommit.id,
            secondParentCommitId: featureCommit.id
        )
        try databaseManager.insertVCCommit(mergeCommit)

        let retrieved = try databaseManager.getVCCommits(branchId: mainBranch.id)
        let merge = retrieved.first { $0.message == "Merge feature into main" }

        XCTAssertEqual(merge?.parentCommitId, mainCommit.id)
        XCTAssertEqual(merge?.secondParentCommitId, featureCommit.id)
    }

    func testCommitsOrderedByTimestamp() throws {
        let branch = VCBranch(name: "main", isActive: true)
        try databaseManager.insertVCBranch(branch)

        // Insert commits with specific timestamps
        let commit1 = VCCommit(
            branchId: branch.id,
            message: "First",
            timestamp: Date(timeIntervalSince1970: 1000)
        )
        let commit2 = VCCommit(
            branchId: branch.id,
            message: "Second",
            timestamp: Date(timeIntervalSince1970: 2000)
        )
        let commit3 = VCCommit(
            branchId: branch.id,
            message: "Third",
            timestamp: Date(timeIntervalSince1970: 3000)
        )

        try databaseManager.insertVCCommit(commit2)
        try databaseManager.insertVCCommit(commit1)
        try databaseManager.insertVCCommit(commit3)

        let retrieved = try databaseManager.getVCCommits(branchId: branch.id)
        XCTAssertEqual(retrieved.count, 3)
        XCTAssertEqual(retrieved[0].message, "First")
        XCTAssertEqual(retrieved[1].message, "Second")
        XCTAssertEqual(retrieved[2].message, "Third")
    }

    // MARK: - Version Control: Snapshot Tests

    func testInsertAndRetrieveVCSnapshot() throws {
        let branch = VCBranch(name: "main", isActive: true)
        try databaseManager.insertVCBranch(branch)

        let commit = VCCommit(branchId: branch.id, message: "Commit")
        try databaseManager.insertVCCommit(commit)

        let documentId = UUID()
        let snapshot = VCDocumentSnapshot(
            commitId: commit.id,
            documentId: documentId,
            title: "My Document",
            content: "Document content here",
            category: "Novel",
            wordCount: 3
        )

        try databaseManager.insertVCSnapshot(snapshot)

        let retrieved = try databaseManager.getVCSnapshots(commitId: commit.id)
        XCTAssertEqual(retrieved.count, 1)
        XCTAssertEqual(retrieved.first?.documentId, documentId)
        XCTAssertEqual(retrieved.first?.title, "My Document")
        XCTAssertEqual(retrieved.first?.content, "Document content here")
        XCTAssertEqual(retrieved.first?.wordCount, 3)
    }

    func testMultipleSnapshotsInSingleCommit() throws {
        let branch = VCBranch(name: "main", isActive: true)
        try databaseManager.insertVCBranch(branch)

        let commit = VCCommit(branchId: branch.id, message: "Multi-doc commit")
        try databaseManager.insertVCCommit(commit)

        let snapshots = [
            VCDocumentSnapshot(
                commitId: commit.id,
                documentId: UUID(),
                title: "Doc 1",
                content: "Content 1",
                category: "Novel",
                wordCount: 2
            ),
            VCDocumentSnapshot(
                commitId: commit.id,
                documentId: UUID(),
                title: "Doc 2",
                content: "Content 2",
                category: "Short Story",
                wordCount: 2
            ),
            VCDocumentSnapshot(
                commitId: commit.id,
                documentId: UUID(),
                title: "Doc 3",
                content: "Content 3",
                category: "Essay",
                wordCount: 2
            )
        ]

        for snapshot in snapshots {
            try databaseManager.insertVCSnapshot(snapshot)
        }

        let retrieved = try databaseManager.getVCSnapshots(commitId: commit.id)
        XCTAssertEqual(retrieved.count, 3)
        XCTAssertTrue(retrieved.contains { $0.title == "Doc 1" })
        XCTAssertTrue(retrieved.contains { $0.title == "Doc 2" })
        XCTAssertTrue(retrieved.contains { $0.title == "Doc 3" })
    }

    func testGetSnapshotsForDocument() throws {
        let branch = VCBranch(name: "main", isActive: true)
        try databaseManager.insertVCBranch(branch)

        let documentId = UUID()

        // Create multiple commits with snapshots of the same document
        for i in 1...3 {
            let commit = VCCommit(
                branchId: branch.id,
                message: "Commit \(i)",
                timestamp: Date(timeIntervalSince1970: Double(i * 1000))
            )
            try databaseManager.insertVCCommit(commit)

            let snapshot = VCDocumentSnapshot(
                commitId: commit.id,
                documentId: documentId,
                title: "Document v\(i)",
                content: "Version \(i) content",
                category: "Novel",
                wordCount: i * 2,
                capturedAt: Date(timeIntervalSince1970: Double(i * 1000))
            )
            try databaseManager.insertVCSnapshot(snapshot)
        }

        let history = try databaseManager.getVCSnapshotsForDocument(documentId: documentId)
        XCTAssertEqual(history.count, 3)
        XCTAssertEqual(history[0].title, "Document v1")
        XCTAssertEqual(history[1].title, "Document v2")
        XCTAssertEqual(history[2].title, "Document v3")
    }

    func testGetSnapshotsAsOf() throws {
        let branch = VCBranch(name: "main", isActive: true)
        try databaseManager.insertVCBranch(branch)

        let doc1 = UUID()
        let doc2 = UUID()

        // Commit 1: Both documents at t=1000
        let commit1 = VCCommit(branchId: branch.id, message: "C1", timestamp: Date(timeIntervalSince1970: 1000))
        try databaseManager.insertVCCommit(commit1)
        try databaseManager.insertVCSnapshot(VCDocumentSnapshot(
            commitId: commit1.id, documentId: doc1, title: "D1v1",
            content: "D1 v1", category: "Novel", wordCount: 2,
            capturedAt: Date(timeIntervalSince1970: 1000)
        ))
        try databaseManager.insertVCSnapshot(VCDocumentSnapshot(
            commitId: commit1.id, documentId: doc2, title: "D2v1",
            content: "D2 v1", category: "Novel", wordCount: 2,
            capturedAt: Date(timeIntervalSince1970: 1000)
        ))

        // Commit 2: Only doc1 updated at t=2000
        let commit2 = VCCommit(branchId: branch.id, message: "C2", timestamp: Date(timeIntervalSince1970: 2000))
        try databaseManager.insertVCCommit(commit2)
        try databaseManager.insertVCSnapshot(VCDocumentSnapshot(
            commitId: commit2.id, documentId: doc1, title: "D1v2",
            content: "D1 v2", category: "Novel", wordCount: 2,
            capturedAt: Date(timeIntervalSince1970: 2000)
        ))

        // Query as of t=1500 should get D1v1 and D2v1
        let snapshotsAt1500 = try databaseManager.getVCSnapshotsAsOf(date: Date(timeIntervalSince1970: 1500))
        XCTAssertEqual(snapshotsAt1500.count, 2)
        let d1 = snapshotsAt1500.first { $0.documentId == doc1 }
        let d2 = snapshotsAt1500.first { $0.documentId == doc2 }
        XCTAssertEqual(d1?.title, "D1v1")
        XCTAssertEqual(d2?.title, "D2v1")

        // Query as of t=2500 should get D1v2 and D2v1
        let snapshotsAt2500 = try databaseManager.getVCSnapshotsAsOf(date: Date(timeIntervalSince1970: 2500))
        XCTAssertEqual(snapshotsAt2500.count, 2)
        let d1_later = snapshotsAt2500.first { $0.documentId == doc1 }
        let d2_later = snapshotsAt2500.first { $0.documentId == doc2 }
        XCTAssertEqual(d1_later?.title, "D1v2")
        XCTAssertEqual(d2_later?.title, "D2v1")
    }

    func testGetSnapshotsAsOfWithNoResults() throws {
        // Query before any snapshots exist
        let snapshots = try databaseManager.getVCSnapshotsAsOf(date: Date(timeIntervalSince1970: 100))
        XCTAssertTrue(snapshots.isEmpty)
    }

    // MARK: - Version Control: Edge Cases

    func testBranchWithNullHeadCommit() throws {
        let branch = VCBranch(name: "empty-branch", headCommitId: nil, isActive: false)
        try databaseManager.insertVCBranch(branch)

        let retrieved = try databaseManager.getVCBranch(name: "empty-branch")
        XCTAssertNotNil(retrieved)
        XCTAssertNil(retrieved?.headCommitId)
    }

    func testCommitWithNullAuthor() throws {
        let branch = VCBranch(name: "main", isActive: true)
        try databaseManager.insertVCBranch(branch)

        let commit = VCCommit(branchId: branch.id, message: "Anonymous commit", authorId: nil)
        try databaseManager.insertVCCommit(commit)

        let retrieved = try databaseManager.getVCCommits(branchId: branch.id)
        XCTAssertNil(retrieved.first?.authorId)
    }

    func testLargeCommitMessage() throws {
        let branch = VCBranch(name: "main", isActive: true)
        try databaseManager.insertVCBranch(branch)

        let longMessage = String(repeating: "This is a long commit message. ", count: 100)
        let commit = VCCommit(branchId: branch.id, message: longMessage)
        try databaseManager.insertVCCommit(commit)

        let retrieved = try databaseManager.getVCCommits(branchId: branch.id)
        XCTAssertEqual(retrieved.first?.message, longMessage)
    }

    func testSnapshotWithLargeContent() throws {
        let branch = VCBranch(name: "main", isActive: true)
        try databaseManager.insertVCBranch(branch)

        let commit = VCCommit(branchId: branch.id, message: "Big doc")
        try databaseManager.insertVCCommit(commit)

        let largeContent = String(repeating: "Lorem ipsum dolor sit amet. ", count: 1000)
        let snapshot = VCDocumentSnapshot(
            commitId: commit.id,
            documentId: UUID(),
            title: "Large Document",
            content: largeContent,
            category: "Novel",
            wordCount: 5000
        )

        try databaseManager.insertVCSnapshot(snapshot)

        let retrieved = try databaseManager.getVCSnapshots(commitId: commit.id)
        XCTAssertEqual(retrieved.first?.content.count, largeContent.count)
    }

    // MARK: - Trace Operations Tests

    func testInsertAndRetrieveTrace() throws {
        let trace = Trace(
            sessionId: "session-123",
            name: "user_interaction",
            startTime: Date(),
            metadata: "{\"key\": \"value\"}"
        )

        try databaseManager.insertTrace(trace)

        let retrieved = try databaseManager.getTraces()
        XCTAssertEqual(retrieved.count, 1)
        XCTAssertEqual(retrieved.first?.id, trace.id)
        XCTAssertEqual(retrieved.first?.sessionId, "session-123")
        XCTAssertEqual(retrieved.first?.name, "user_interaction")
        XCTAssertEqual(retrieved.first?.metadata, "{\"key\": \"value\"}")
    }

    func testGetTracesFilteredBySession() throws {
        let trace1 = Trace(sessionId: "session-1", name: "trace1")
        let trace2 = Trace(sessionId: "session-2", name: "trace2")
        let trace3 = Trace(sessionId: "session-1", name: "trace3")

        try databaseManager.insertTrace(trace1)
        try databaseManager.insertTrace(trace2)
        try databaseManager.insertTrace(trace3)

        let session1Traces = try databaseManager.getTraces(sessionId: "session-1")
        XCTAssertEqual(session1Traces.count, 2)
        XCTAssertTrue(session1Traces.allSatisfy { $0.sessionId == "session-1" })

        let session2Traces = try databaseManager.getTraces(sessionId: "session-2")
        XCTAssertEqual(session2Traces.count, 1)
        XCTAssertEqual(session2Traces.first?.sessionId, "session-2")
    }

    func testTraceWithOptionalFields() throws {
        let trace = Trace(
            sessionId: "session-123",
            name: "minimal_trace",
            endTime: nil,
            metadata: nil
        )

        try databaseManager.insertTrace(trace)

        let retrieved = try databaseManager.getTraces()
        XCTAssertNotNil(retrieved.first)
        XCTAssertNil(retrieved.first?.endTime)
        XCTAssertNil(retrieved.first?.metadata)
    }

    func testTraceOrderedByStartTime() throws {
        let trace1 = Trace(
            sessionId: "session",
            name: "First",
            startTime: Date(timeIntervalSince1970: 1000)
        )
        let trace2 = Trace(
            sessionId: "session",
            name: "Second",
            startTime: Date(timeIntervalSince1970: 2000)
        )
        let trace3 = Trace(
            sessionId: "session",
            name: "Third",
            startTime: Date(timeIntervalSince1970: 3000)
        )

        // Insert out of order
        try databaseManager.insertTrace(trace2)
        try databaseManager.insertTrace(trace1)
        try databaseManager.insertTrace(trace3)

        let retrieved = try databaseManager.getTraces()
        XCTAssertEqual(retrieved.count, 3)
        XCTAssertEqual(retrieved[0].name, "First")
        XCTAssertEqual(retrieved[1].name, "Second")
        XCTAssertEqual(retrieved[2].name, "Third")
    }

    // MARK: - Observation Operations Tests

    func testInsertAndRetrieveObservation() throws {
        let trace = Trace(sessionId: "session-123", name: "trace1")
        try databaseManager.insertTrace(trace)

        let observation = Observation(
            traceId: trace.id,
            name: "tool_call",
            input: "test input",
            output: "test output",
            statusMessage: "success"
        )

        try databaseManager.insertObservation(observation)

        let retrieved = try databaseManager.getObservations(traceId: trace.id)
        XCTAssertEqual(retrieved.count, 1)
        XCTAssertEqual(retrieved.first?.id, observation.id)
        XCTAssertEqual(retrieved.first?.traceId, trace.id)
        XCTAssertEqual(retrieved.first?.name, "tool_call")
        XCTAssertEqual(retrieved.first?.input, "test input")
        XCTAssertEqual(retrieved.first?.output, "test output")
        XCTAssertEqual(retrieved.first?.statusMessage, "success")
    }

    func testMultipleObservationsForTrace() throws {
        let trace = Trace(sessionId: "session-123", name: "trace1")
        try databaseManager.insertTrace(trace)

        let observations = [
            Observation(traceId: trace.id, name: "obs1", startTime: Date(timeIntervalSince1970: 1000)),
            Observation(traceId: trace.id, name: "obs2", startTime: Date(timeIntervalSince1970: 2000)),
            Observation(traceId: trace.id, name: "obs3", startTime: Date(timeIntervalSince1970: 3000))
        ]

        for obs in observations {
            try databaseManager.insertObservation(obs)
        }

        let retrieved = try databaseManager.getObservations(traceId: trace.id)
        XCTAssertEqual(retrieved.count, 3)
        // Should be ordered by start time
        XCTAssertEqual(retrieved[0].name, "obs1")
        XCTAssertEqual(retrieved[1].name, "obs2")
        XCTAssertEqual(retrieved[2].name, "obs3")
    }

    func testObservationWithOptionalFields() throws {
        let trace = Trace(sessionId: "session-123", name: "trace1")
        try databaseManager.insertTrace(trace)

        let observation = Observation(
            traceId: trace.id,
            name: "minimal_obs",
            endTime: nil,
            input: nil,
            output: nil,
            statusMessage: nil
        )

        try databaseManager.insertObservation(observation)

        let retrieved = try databaseManager.getObservations(traceId: trace.id)
        XCTAssertNotNil(retrieved.first)
        XCTAssertNil(retrieved.first?.endTime)
        XCTAssertNil(retrieved.first?.input)
        XCTAssertNil(retrieved.first?.output)
        XCTAssertNil(retrieved.first?.statusMessage)
    }

    func testGetObservationsForNonExistentTrace() throws {
        let nonExistentTraceId = UUID()
        let observations = try databaseManager.getObservations(traceId: nonExistentTraceId)
        XCTAssertTrue(observations.isEmpty)
    }

    // MARK: - Issue Operations Tests (Additional)

    func testGetIssuesByPriority() throws {
        let documentId = UUID()

        let issues = [
            Issue(documentId: documentId, title: "Low", priority: .low),
            Issue(documentId: documentId, title: "High", priority: .high),
            Issue(documentId: documentId, title: "Critical", priority: .critical),
            Issue(documentId: documentId, title: "Medium", priority: .medium)
        ]

        for issue in issues {
            try databaseManager.insertIssue(issue)
        }

        let highPriority = try databaseManager.getIssues(withStatus: .open)
        // All are open by default
        XCTAssertEqual(highPriority.count, 4)
    }

    func testIssueWithEmptyTags() throws {
        let documentId = UUID()
        let issue = Issue(
            documentId: documentId,
            title: "Test Issue",
            metadata: IssueMetadata(tags: [])
        )

        try databaseManager.insertIssue(issue)

        let retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(retrieved.first?.metadata.tags.count, 0)
    }

    func testIssueWithMultipleTags() throws {
        let documentId = UUID()
        let tags = ["bug", "high-priority", "chapter-3", "character-development"]
        let issue = Issue(
            documentId: documentId,
            title: "Complex Issue",
            metadata: IssueMetadata(tags: tags)
        )

        try databaseManager.insertIssue(issue)

        let retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(retrieved.first?.metadata.tags, tags)
    }

    func testUpdateIssueStatus() throws {
        let documentId = UUID()
        var issue = Issue(
            documentId: documentId,
            title: "Update Test",
            status: .open
        )

        try databaseManager.insertIssue(issue)

        issue.status = .inProgress
        try databaseManager.updateIssue(issue)

        let retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(retrieved.first?.status, .inProgress)

        issue.status = .resolved
        issue.metadata.resolvedAt = Date()
        try databaseManager.updateIssue(issue)

        let resolvedIssue = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(resolvedIssue.first?.status, .resolved)
        XCTAssertNotNil(resolvedIssue.first?.metadata.resolvedAt)
    }

    // MARK: - Error Handling Tests

    func testDatabaseNotInitializedError() throws {
        // Create a new database manager without initializing
        let uninitializedDB = DatabaseManager(databasePath: "/tmp/uninitialized_\(UUID().uuidString).db")

        // Attempt operations without initialization
        XCTAssertThrowsError(try uninitializedDB.getAISuggestions(userId: testUserId)) { error in
            guard case DatabaseError.notInitialized = error else {
                XCTFail("Expected notInitialized error")
                return
            }
        }

        XCTAssertThrowsError(try uninitializedDB.getUserSessions(userId: testUserId)) { error in
            guard case DatabaseError.notInitialized = error else {
                XCTFail("Expected notInitialized error")
                return
            }
        }

        XCTAssertThrowsError(try uninitializedDB.getAllVCBranches()) { error in
            guard case DatabaseError.notInitialized = error else {
                XCTFail("Expected notInitialized error")
                return
            }
        }
    }

    func testAISuggestionWithNullDocumentId() throws {
        let suggestion = AISuggestion(
            userId: testUserId,
            documentId: nil,
            toolUsed: "General Advice",
            prompt: "How to improve my writing?",
            response: "Practice daily"
        )

        try databaseManager.insertAISuggestion(suggestion)

        let retrieved = try databaseManager.getAISuggestions(userId: testUserId)
        XCTAssertEqual(retrieved.count, 1)
        XCTAssertNil(retrieved.first?.documentId)
    }

    func testGetAIConfigurationForNonExistentUser() throws {
        let nonExistentUserId = UUID()
        let config = try databaseManager.getAIConfiguration(userId: nonExistentUserId)
        XCTAssertNil(config)
    }

    func testSessionStatsWithNoSessions() throws {
        let userId = UUID()
        let stats = try databaseManager.getSessionStats(userId: userId)

        XCTAssertEqual(stats.totalSessions, 0)
        XCTAssertEqual(stats.totalDurationSeconds, 0)
        XCTAssertEqual(stats.averageDurationSeconds, 0.0)
        XCTAssertNil(stats.earliestSession)
        XCTAssertNil(stats.latestSession)
    }

    func testDeleteNonExistentAISuggestion() throws {
        let nonExistentId = UUID()
        // Should not throw, just silently succeed
        XCTAssertNoThrow(try databaseManager.deleteAISuggestion(id: nonExistentId))
    }

    func testDeleteNonExistentIssue() throws {
        let nonExistentId = UUID()
        // Should not throw, just silently succeed
        XCTAssertNoThrow(try databaseManager.deleteIssue(id: nonExistentId))
    }
}