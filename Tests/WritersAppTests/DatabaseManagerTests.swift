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
        XCTAssertEqual(retrieved?.apiKey, "sk-test-key", "API key must be persisted and returned correctly")
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

    // MARK: - API Key Persistence Tests (PR: API keys are now persisted via sqlite3_bind_text)

    /// After the PR, the retrieved API key matches what was saved.
    func testAPIKeyAlwaysReturnedAsEmptyString() throws {
        let config = AIConfiguration(
            apiKey: "sk-ant-secret-key-abc123",
            model: .claude35Sonnet,
            maxTokens: 4096,
            temperature: 0.7
        )
        try databaseManager.saveAIConfiguration(userId: testUserId, configuration: config)

        let retrieved = try databaseManager.getAIConfiguration(userId: testUserId)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.apiKey, "sk-ant-secret-key-abc123",
                       "API key must be persisted and returned as supplied")
    }

    /// After close/reopen, the API key persists correctly.
    func testAPIKeyIsEmptyStringAfterDatabaseCloseAndReopen() throws {
        let config = AIConfiguration(
            apiKey: "sk-ant-persistent-key",
            model: .claude35Sonnet,
            maxTokens: 4096,
            temperature: 0.7
        )
        try databaseManager.saveAIConfiguration(userId: testUserId, configuration: config)

        // Close and re-open the same database file
        databaseManager.close()
        try databaseManager.initialize()

        let retrieved = try databaseManager.getAIConfiguration(userId: testUserId)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.apiKey, "sk-ant-persistent-key",
                       "API key must persist after close/reopen")
        // Other fields must still persist correctly after close/reopen
        XCTAssertEqual(retrieved?.model, .claude35Sonnet)
        XCTAssertEqual(retrieved?.maxTokens, 4096)
    }

    /// API keys with special characters are persisted correctly.
    func testAPIKeyWithAnyContentAlwaysReturnedAsEmpty() throws {
        let specialKey = "sk-ant-api03-AbCdEf123_XYZ-09!@#"
        let config = AIConfiguration(
            apiKey: specialKey,
            model: .claude3Opus,
            maxTokens: 2048,
            temperature: 0.5
        )
        try databaseManager.saveAIConfiguration(userId: testUserId, configuration: config)

        let retrieved = try databaseManager.getAIConfiguration(userId: testUserId)
        XCTAssertEqual(retrieved?.apiKey, specialKey,
                       "API key with special characters must be stored and returned correctly")
    }

    /// Verify that the model, maxTokens, and temperature ARE persisted correctly (only apiKey is protected).
    func testNonSensitiveFieldsPersistCorrectly() throws {
        let config = AIConfiguration(
            apiKey: "sk-ant-real-key",
            model: .claude3Sonnet,
            maxTokens: 2048,
            temperature: 0.42
        )
        try databaseManager.saveAIConfiguration(userId: testUserId, configuration: config)

        let retrieved = try databaseManager.getAIConfiguration(userId: testUserId)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.model, .claude3Sonnet, "model must persist in database")
        XCTAssertEqual(retrieved?.maxTokens, 2048, "maxTokens must persist in database")
        XCTAssertEqual(retrieved?.temperature ?? -1, 0.42, accuracy: 0.001, "temperature must persist in database")
    }

    func testEmptyAPIKeyInputAlsoReturnedAsEmpty() throws {
        // Edge case: deliberately passing "" also yields "" (consistent with PR behavior).
        let config = AIConfiguration(
            apiKey: "",
            model: .claude35Sonnet,
            maxTokens: 4096,
            temperature: 0.7
        )
        try databaseManager.saveAIConfiguration(userId: testUserId, configuration: config)

        let retrieved = try databaseManager.getAIConfiguration(userId: testUserId)
        XCTAssertEqual(retrieved?.apiKey, "",
                       "Empty API key input must also return empty string")
    }

    // MARK: - Version Control: Branch Tests

    func testInsertAndRetrieveVCBranch() throws {
        let branch = VCBranch(name: "main", isActive: true)

        try databaseManager.insertVCBranch(branch)

        let retrieved = try databaseManager.getVCBranch(name: "main")
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.id, branch.id)
        XCTAssertEqual(retrieved?.name, "main")
        XCTAssertEqual(retrieved?.isActive, true)
        XCTAssertNil(retrieved?.headCommitId)
    }

    func testUpdateVCBranch() throws {
        var branch = VCBranch(name: "feature", isActive: false)
        try databaseManager.insertVCBranch(branch)

        let commitId = UUID()
        branch.headCommitId = commitId
        branch.isActive = true
        try databaseManager.updateVCBranch(branch)

        let retrieved = try databaseManager.getVCBranch(name: "feature")
        XCTAssertEqual(retrieved?.headCommitId, commitId)
        XCTAssertEqual(retrieved?.isActive, true)
    }

    func testSetActiveBranch() throws {
        let branch1 = VCBranch(name: "main", isActive: true)
        let branch2 = VCBranch(name: "feature", isActive: false)

        try databaseManager.insertVCBranch(branch1)
        try databaseManager.insertVCBranch(branch2)

        // Switch active branch
        try databaseManager.setActiveBranch(id: branch2.id)

        let retrieved1 = try databaseManager.getVCBranch(name: "main")
        let retrieved2 = try databaseManager.getVCBranch(name: "feature")

        XCTAssertEqual(retrieved1?.isActive, false)
        XCTAssertEqual(retrieved2?.isActive, true)
    }

    func testGetAllVCBranches() throws {
        let branches = [
            VCBranch(name: "main", isActive: true),
            VCBranch(name: "feature-1", isActive: false),
            VCBranch(name: "feature-2", isActive: false)
        ]

        for branch in branches {
            try databaseManager.insertVCBranch(branch)
        }

        let retrieved = try databaseManager.getAllVCBranches()
        XCTAssertEqual(retrieved.count, 3)
        XCTAssertTrue(retrieved.contains(where: { $0.name == "main" && $0.isActive }))
    }

    func testVCBranchUniqueName() throws {
        let branch1 = VCBranch(name: "duplicate", isActive: false)
        try databaseManager.insertVCBranch(branch1)

        let branch2 = VCBranch(name: "duplicate", isActive: false)
        XCTAssertThrowsError(try databaseManager.insertVCBranch(branch2))
    }

    // MARK: - Version Control: Commit Tests

    func testInsertAndRetrieveVCCommit() throws {
        let branch = VCBranch(name: "main", isActive: true)
        try databaseManager.insertVCBranch(branch)

        let commit = VCCommit(
            branchId: branch.id,
            message: "Initial commit",
            authorId: "test-author"
        )

        try databaseManager.insertVCCommit(commit)

        let retrieved = try databaseManager.getVCCommits(branchId: branch.id)
        XCTAssertEqual(retrieved.count, 1)
        XCTAssertEqual(retrieved.first?.id, commit.id)
        XCTAssertEqual(retrieved.first?.message, "Initial commit")
        XCTAssertEqual(retrieved.first?.authorId, "test-author")
    }

    func testVCCommitWithParent() throws {
        let branch = VCBranch(name: "main", isActive: true)
        try databaseManager.insertVCBranch(branch)

        let commit1 = VCCommit(branchId: branch.id, message: "First commit")
        try databaseManager.insertVCCommit(commit1)

        let commit2 = VCCommit(
            branchId: branch.id,
            message: "Second commit",
            parentCommitId: commit1.id
        )
        try databaseManager.insertVCCommit(commit2)

        let retrieved = try databaseManager.getVCCommits(branchId: branch.id)
        XCTAssertEqual(retrieved.count, 2)
        XCTAssertEqual(retrieved[0].id, commit1.id)
        XCTAssertEqual(retrieved[1].id, commit2.id)
        XCTAssertEqual(retrieved[1].parentCommitId, commit1.id)
    }

    func testVCCommitOrderedByTimestamp() throws {
        let branch = VCBranch(name: "main", isActive: true)
        try databaseManager.insertVCBranch(branch)

        let commit1 = VCCommit(
            branchId: branch.id,
            message: "Old commit",
            timestamp: Date(timeIntervalSince1970: 1000)
        )
        let commit2 = VCCommit(
            branchId: branch.id,
            message: "New commit",
            timestamp: Date(timeIntervalSince1970: 2000)
        )

        try databaseManager.insertVCCommit(commit2)
        try databaseManager.insertVCCommit(commit1)

        let retrieved = try databaseManager.getVCCommits(branchId: branch.id)
        XCTAssertEqual(retrieved[0].message, "Old commit")
        XCTAssertEqual(retrieved[1].message, "New commit")
    }

    func testVCMergeCommitWithTwoParents() throws {
        let branch = VCBranch(name: "main", isActive: true)
        try databaseManager.insertVCBranch(branch)

        let commit1 = VCCommit(branchId: branch.id, message: "Main commit")
        let commit2 = VCCommit(branchId: branch.id, message: "Feature commit")
        try databaseManager.insertVCCommit(commit1)
        try databaseManager.insertVCCommit(commit2)

        let mergeCommit = VCCommit(
            branchId: branch.id,
            message: "Merge commit",
            parentCommitId: commit1.id,
            secondParentCommitId: commit2.id
        )
        try databaseManager.insertVCCommit(mergeCommit)

        let retrieved = try databaseManager.getVCCommits(branchId: branch.id)
        let merge = retrieved.first(where: { $0.id == mergeCommit.id })
        XCTAssertEqual(merge?.parentCommitId, commit1.id)
        XCTAssertEqual(merge?.secondParentCommitId, commit2.id)
    }

    // MARK: - Version Control: Snapshot Tests

    func testInsertAndRetrieveVCSnapshot() throws {
        let branch = VCBranch(name: "main", isActive: true)
        try databaseManager.insertVCBranch(branch)

        let commit = VCCommit(branchId: branch.id, message: "Initial commit")
        try databaseManager.insertVCCommit(commit)

        let documentId = UUID()
        let snapshot = VCDocumentSnapshot(
            commitId: commit.id,
            documentId: documentId,
            title: "Test Document",
            content: "This is test content.",
            category: "novel",
            wordCount: 4
        )

        try databaseManager.insertVCSnapshot(snapshot)

        let retrieved = try databaseManager.getVCSnapshots(commitId: commit.id)
        XCTAssertEqual(retrieved.count, 1)
        XCTAssertEqual(retrieved.first?.documentId, documentId)
        XCTAssertEqual(retrieved.first?.title, "Test Document")
        XCTAssertEqual(retrieved.first?.content, "This is test content.")
        XCTAssertEqual(retrieved.first?.wordCount, 4)
    }

    func testGetVCSnapshotsForDocument() throws {
        let branch = VCBranch(name: "main", isActive: true)
        try databaseManager.insertVCBranch(branch)

        let documentId = UUID()

        let commit1 = VCCommit(
            branchId: branch.id,
            message: "Commit 1",
            timestamp: Date(timeIntervalSince1970: 1000)
        )
        let commit2 = VCCommit(
            branchId: branch.id,
            message: "Commit 2",
            timestamp: Date(timeIntervalSince1970: 2000)
        )
        try databaseManager.insertVCCommit(commit1)
        try databaseManager.insertVCCommit(commit2)

        let snapshot1 = VCDocumentSnapshot(
            commitId: commit1.id,
            documentId: documentId,
            title: "Doc v1",
            content: "Version 1",
            category: "essay",
            wordCount: 2,
            capturedAt: Date(timeIntervalSince1970: 1000)
        )
        let snapshot2 = VCDocumentSnapshot(
            commitId: commit2.id,
            documentId: documentId,
            title: "Doc v2",
            content: "Version 2 with more words",
            category: "essay",
            wordCount: 5,
            capturedAt: Date(timeIntervalSince1970: 2000)
        )
        try databaseManager.insertVCSnapshot(snapshot1)
        try databaseManager.insertVCSnapshot(snapshot2)

        let history = try databaseManager.getVCSnapshotsForDocument(documentId: documentId)
        XCTAssertEqual(history.count, 2)
        XCTAssertEqual(history[0].content, "Version 1")
        XCTAssertEqual(history[1].content, "Version 2 with more words")
    }

    func testGetVCSnapshotsAsOf() throws {
        let branch = VCBranch(name: "main", isActive: true)
        try databaseManager.insertVCBranch(branch)

        let doc1Id = UUID()
        let doc2Id = UUID()

        let commit1 = VCCommit(
            branchId: branch.id,
            message: "Commit at t=1000",
            timestamp: Date(timeIntervalSince1970: 1000)
        )
        let commit2 = VCCommit(
            branchId: branch.id,
            message: "Commit at t=2000",
            timestamp: Date(timeIntervalSince1970: 2000)
        )
        try databaseManager.insertVCCommit(commit1)
        try databaseManager.insertVCCommit(commit2)

        // Doc1 has snapshots at t=1000 and t=2000
        try databaseManager.insertVCSnapshot(VCDocumentSnapshot(
            commitId: commit1.id, documentId: doc1Id, title: "Doc1 v1",
            content: "Old version", category: "novel", wordCount: 2,
            capturedAt: Date(timeIntervalSince1970: 1000)
        ))
        try databaseManager.insertVCSnapshot(VCDocumentSnapshot(
            commitId: commit2.id, documentId: doc1Id, title: "Doc1 v2",
            content: "New version", category: "novel", wordCount: 2,
            capturedAt: Date(timeIntervalSince1970: 2000)
        ))

        // Doc2 only has snapshot at t=1000
        try databaseManager.insertVCSnapshot(VCDocumentSnapshot(
            commitId: commit1.id, documentId: doc2Id, title: "Doc2 v1",
            content: "Only version", category: "essay", wordCount: 2,
            capturedAt: Date(timeIntervalSince1970: 1000)
        ))

        // Query as of t=1500 should return doc1 v1 and doc2 v1
        let snapshots1500 = try databaseManager.getVCSnapshotsAsOf(date: Date(timeIntervalSince1970: 1500))
        XCTAssertEqual(snapshots1500.count, 2)
        let doc1_1500 = snapshots1500.first(where: { $0.documentId == doc1Id })
        XCTAssertEqual(doc1_1500?.content, "Old version")

        // Query as of t=2500 should return doc1 v2 and doc2 v1
        let snapshots2500 = try databaseManager.getVCSnapshotsAsOf(date: Date(timeIntervalSince1970: 2500))
        XCTAssertEqual(snapshots2500.count, 2)
        let doc1_2500 = snapshots2500.first(where: { $0.documentId == doc1Id })
        XCTAssertEqual(doc1_2500?.content, "New version")
    }

    func testMultipleSnapshotsInCommit() throws {
        let branch = VCBranch(name: "main", isActive: true)
        try databaseManager.insertVCBranch(branch)

        let commit = VCCommit(branchId: branch.id, message: "Multi-doc commit")
        try databaseManager.insertVCCommit(commit)

        let snapshots = [
            VCDocumentSnapshot(commitId: commit.id, documentId: UUID(), title: "Doc 1",
                              content: "Content 1", category: "novel", wordCount: 2),
            VCDocumentSnapshot(commitId: commit.id, documentId: UUID(), title: "Doc 2",
                              content: "Content 2", category: "essay", wordCount: 2),
            VCDocumentSnapshot(commitId: commit.id, documentId: UUID(), title: "Doc 3",
                              content: "Content 3", category: "article", wordCount: 2)
        ]

        for snapshot in snapshots {
            try databaseManager.insertVCSnapshot(snapshot)
        }

        let retrieved = try databaseManager.getVCSnapshots(commitId: commit.id)
        XCTAssertEqual(retrieved.count, 3)
    }

    // MARK: - Trace Operations Tests

    func testInsertAndRetrieveTrace() throws {
        let trace = Trace(
            sessionId: "session-123",
            name: "AI Tool Usage",
            startTime: Date(timeIntervalSince1970: 1000)
        )

        try databaseManager.insertTrace(trace)

        let retrieved = try databaseManager.getTraces()
        XCTAssertEqual(retrieved.count, 1)
        XCTAssertEqual(retrieved.first?.id, trace.id)
        XCTAssertEqual(retrieved.first?.sessionId, "session-123")
        XCTAssertEqual(retrieved.first?.name, "AI Tool Usage")
    }

    func testGetTracesFilteredBySession() throws {
        let trace1 = Trace(sessionId: "session-1", name: "Trace 1")
        let trace2 = Trace(sessionId: "session-2", name: "Trace 2")
        let trace3 = Trace(sessionId: "session-1", name: "Trace 3")

        try databaseManager.insertTrace(trace1)
        try databaseManager.insertTrace(trace2)
        try databaseManager.insertTrace(trace3)

        let session1Traces = try databaseManager.getTraces(sessionId: "session-1")
        XCTAssertEqual(session1Traces.count, 2)
        XCTAssertTrue(session1Traces.allSatisfy { $0.sessionId == "session-1" })
    }

    func testTraceWithEndTime() throws {
        var trace = Trace(
            sessionId: "session-123",
            name: "Completed Trace",
            startTime: Date(timeIntervalSince1970: 1000)
        )
        trace.endTime = Date(timeIntervalSince1970: 2000)

        try databaseManager.insertTrace(trace)

        let retrieved = try databaseManager.getTraces()
        XCTAssertEqual(retrieved.count, 1)
        XCTAssertNotNil(retrieved.first?.endTime)
        XCTAssertEqual(retrieved.first?.durationSeconds, 1000.0)
    }

    func testTraceWithMetadata() throws {
        let trace = Trace(
            sessionId: "session-123",
            name: "Trace with metadata",
            metadata: "{\"tool\": \"continue_writing\", \"model\": \"claude-3\"}"
        )

        try databaseManager.insertTrace(trace)

        let retrieved = try databaseManager.getTraces()
        XCTAssertEqual(retrieved.first?.metadata, "{\"tool\": \"continue_writing\", \"model\": \"claude-3\"}")
    }

    func testMultipleTracesOrderedByStartTime() throws {
        let trace1 = Trace(
            sessionId: "session-1",
            name: "Old trace",
            startTime: Date(timeIntervalSince1970: 1000)
        )
        let trace2 = Trace(
            sessionId: "session-1",
            name: "New trace",
            startTime: Date(timeIntervalSince1970: 3000)
        )
        let trace3 = Trace(
            sessionId: "session-1",
            name: "Middle trace",
            startTime: Date(timeIntervalSince1970: 2000)
        )

        try databaseManager.insertTrace(trace2)
        try databaseManager.insertTrace(trace1)
        try databaseManager.insertTrace(trace3)

        let retrieved = try databaseManager.getTraces(sessionId: "session-1")
        XCTAssertEqual(retrieved.count, 3)
        XCTAssertEqual(retrieved[0].name, "Old trace")
        XCTAssertEqual(retrieved[1].name, "Middle trace")
        XCTAssertEqual(retrieved[2].name, "New trace")
    }

    // MARK: - Observation Operations Tests

    func testInsertAndRetrieveObservation() throws {
        let trace = Trace(sessionId: "session-123", name: "Test Trace")
        try databaseManager.insertTrace(trace)

        let observation = Observation(
            traceId: trace.id,
            name: "tool_call",
            input: "Input text",
            output: "Output text",
            statusMessage: "Success"
        )

        try databaseManager.insertObservation(observation)

        let retrieved = try databaseManager.getObservations(traceId: trace.id)
        XCTAssertEqual(retrieved.count, 1)
        XCTAssertEqual(retrieved.first?.id, observation.id)
        XCTAssertEqual(retrieved.first?.name, "tool_call")
        XCTAssertEqual(retrieved.first?.input, "Input text")
        XCTAssertEqual(retrieved.first?.output, "Output text")
        XCTAssertEqual(retrieved.first?.statusMessage, "Success")
    }

    func testMultipleObservationsForTrace() throws {
        let trace = Trace(sessionId: "session-123", name: "Test Trace")
        try databaseManager.insertTrace(trace)

        let observations = [
            Observation(traceId: trace.id, name: "read_file", input: "file.txt", output: "content"),
            Observation(traceId: trace.id, name: "write_file", input: "data", output: "success"),
            Observation(traceId: trace.id, name: "execute_bash", input: "ls", output: "files")
        ]

        for observation in observations {
            try databaseManager.insertObservation(observation)
        }

        let retrieved = try databaseManager.getObservations(traceId: trace.id)
        XCTAssertEqual(retrieved.count, 3)
        XCTAssertTrue(retrieved.contains { $0.name == "read_file" })
        XCTAssertTrue(retrieved.contains { $0.name == "write_file" })
        XCTAssertTrue(retrieved.contains { $0.name == "execute_bash" })
    }

    func testObservationWithEndTime() throws {
        let trace = Trace(sessionId: "session-123", name: "Test Trace")
        try databaseManager.insertTrace(trace)

        var observation = Observation(
            traceId: trace.id,
            name: "long_operation",
            startTime: Date(timeIntervalSince1970: 1000)
        )
        observation.endTime = Date(timeIntervalSince1970: 2000)

        try databaseManager.insertObservation(observation)

        let retrieved = try databaseManager.getObservations(traceId: trace.id)
        XCTAssertNotNil(retrieved.first?.endTime)
    }

    func testObservationWithNullFields() throws {
        let trace = Trace(sessionId: "session-123", name: "Test Trace")
        try databaseManager.insertTrace(trace)

        let observation = Observation(
            traceId: trace.id,
            name: "minimal_observation"
        )

        try databaseManager.insertObservation(observation)

        let retrieved = try databaseManager.getObservations(traceId: trace.id)
        XCTAssertEqual(retrieved.count, 1)
        XCTAssertNil(retrieved.first?.input)
        XCTAssertNil(retrieved.first?.output)
        XCTAssertNil(retrieved.first?.statusMessage)
        XCTAssertNil(retrieved.first?.endTime)
    }

    func testObservationsOrderedByStartTime() throws {
        let trace = Trace(sessionId: "session-123", name: "Test Trace")
        try databaseManager.insertTrace(trace)

        let obs1 = Observation(
            traceId: trace.id,
            name: "First",
            startTime: Date(timeIntervalSince1970: 1000)
        )
        let obs2 = Observation(
            traceId: trace.id,
            name: "Third",
            startTime: Date(timeIntervalSince1970: 3000)
        )
        let obs3 = Observation(
            traceId: trace.id,
            name: "Second",
            startTime: Date(timeIntervalSince1970: 2000)
        )

        try databaseManager.insertObservation(obs2)
        try databaseManager.insertObservation(obs1)
        try databaseManager.insertObservation(obs3)

        let retrieved = try databaseManager.getObservations(traceId: trace.id)
        XCTAssertEqual(retrieved[0].name, "First")
        XCTAssertEqual(retrieved[1].name, "Second")
        XCTAssertEqual(retrieved[2].name, "Third")
    }

    func testGetObservationsForNonExistentTrace() throws {
        let nonExistentTraceId = UUID()
        let retrieved = try databaseManager.getObservations(traceId: nonExistentTraceId)
        XCTAssertEqual(retrieved.count, 0)
    }

    // MARK: - Issue Operations Tests

    func testInsertAndRetrieveIssue() throws {
        let documentId = UUID()
        let issue = Issue(
            documentId: documentId,
            title: "Fix plot hole",
            description: "Chapter 3 contradicts chapter 1",
            status: .open,
            priority: .high
        )

        try databaseManager.insertIssue(issue)

        let retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(retrieved.count, 1)
        XCTAssertEqual(retrieved.first?.id, issue.id)
        XCTAssertEqual(retrieved.first?.title, "Fix plot hole")
        XCTAssertEqual(retrieved.first?.description, "Chapter 3 contradicts chapter 1")
        XCTAssertEqual(retrieved.first?.status, .open)
        XCTAssertEqual(retrieved.first?.priority, .high)
    }

    func testUpdateIssue() throws {
        let documentId = UUID()
        var issue = Issue(
            documentId: documentId,
            title: "Review character arc",
            description: "Needs work",
            status: .open,
            priority: .medium
        )

        try databaseManager.insertIssue(issue)

        issue.status = .resolved
        issue.priority = .low
        issue.description = "Updated description"
        issue.metadata.modified = Date()
        issue.metadata.resolvedAt = Date()

        try databaseManager.updateIssue(issue)

        let retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(retrieved.first?.status, .resolved)
        XCTAssertEqual(retrieved.first?.priority, .low)
        XCTAssertEqual(retrieved.first?.description, "Updated description")
        XCTAssertNotNil(retrieved.first?.metadata.resolvedAt)
    }

    func testDeleteIssue() throws {
        let documentId = UUID()
        let issue = Issue(
            documentId: documentId,
            title: "Temporary note",
            description: "To be deleted"
        )

        try databaseManager.insertIssue(issue)

        var retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(retrieved.count, 1)

        try databaseManager.deleteIssue(id: issue.id)

        retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(retrieved.count, 0)
    }

    func testGetIssuesByStatus() throws {
        let documentId = UUID()

        let issues = [
            Issue(documentId: documentId, title: "Open 1", status: .open, priority: .high),
            Issue(documentId: documentId, title: "In Progress 1", status: .inProgress, priority: .medium),
            Issue(documentId: documentId, title: "Open 2", status: .open, priority: .low),
            Issue(documentId: documentId, title: "Resolved 1", status: .resolved, priority: .medium)
        ]

        for issue in issues {
            try databaseManager.insertIssue(issue)
        }

        let openIssues = try databaseManager.getIssues(withStatus: .open)
        XCTAssertEqual(openIssues.count, 2)
        XCTAssertTrue(openIssues.allSatisfy { $0.status == .open })

        let resolvedIssues = try databaseManager.getIssues(withStatus: .resolved)
        XCTAssertEqual(resolvedIssues.count, 1)
        XCTAssertEqual(resolvedIssues.first?.title, "Resolved 1")
    }

    func testGetAllIssues() throws {
        let doc1 = UUID()
        let doc2 = UUID()

        let issues = [
            Issue(documentId: doc1, title: "Issue 1", status: .open, priority: .high),
            Issue(documentId: doc1, title: "Issue 2", status: .inProgress, priority: .medium),
            Issue(documentId: doc2, title: "Issue 3", status: .resolved, priority: .low)
        ]

        for issue in issues {
            try databaseManager.insertIssue(issue)
        }

        let allIssues = try databaseManager.getAllIssues()
        XCTAssertEqual(allIssues.count, 3)
    }

    func testIssuesPagination() throws {
        let documentId = UUID()

        for i in 1...15 {
            let issue = Issue(
                documentId: documentId,
                title: "Issue \(i)",
                status: .open,
                priority: .medium
            )
            try databaseManager.insertIssue(issue)
        }

        let firstPage = try databaseManager.getIssues(forDocument: documentId, limit: 5, offset: 0)
        XCTAssertEqual(firstPage.count, 5)

        let secondPage = try databaseManager.getIssues(forDocument: documentId, limit: 5, offset: 5)
        XCTAssertEqual(secondPage.count, 5)

        let thirdPage = try databaseManager.getIssues(forDocument: documentId, limit: 5, offset: 10)
        XCTAssertEqual(thirdPage.count, 5)

        // Verify no overlap
        XCTAssertNotEqual(firstPage.first?.id, secondPage.first?.id)
    }

    func testIssueWithTags() throws {
        let documentId = UUID()
        var metadata = IssueMetadata()
        metadata.tags = ["plot", "character", "urgent"]

        let issue = Issue(
            documentId: documentId,
            title: "Complex issue",
            description: "Needs attention",
            metadata: metadata
        )

        try databaseManager.insertIssue(issue)

        let retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(retrieved.first?.metadata.tags.count, 3)
        XCTAssertTrue(retrieved.first?.metadata.tags.contains("plot") ?? false)
        XCTAssertTrue(retrieved.first?.metadata.tags.contains("character") ?? false)
        XCTAssertTrue(retrieved.first?.metadata.tags.contains("urgent") ?? false)
    }

    func testIssueWithNotes() throws {
        let documentId = UUID()
        var metadata = IssueMetadata()
        metadata.notes = "This is a detailed note about the issue"

        let issue = Issue(
            documentId: documentId,
            title: "Issue with notes",
            metadata: metadata
        )

        try databaseManager.insertIssue(issue)

        let retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(retrieved.first?.metadata.notes, "This is a detailed note about the issue")
    }

    func testIssuesOrderedByCreatedDate() throws {
        let documentId = UUID()

        let issue1 = Issue(
            documentId: documentId,
            title: "Old issue",
            metadata: IssueMetadata(created: Date(timeIntervalSince1970: 1000))
        )
        let issue2 = Issue(
            documentId: documentId,
            title: "New issue",
            metadata: IssueMetadata(created: Date(timeIntervalSince1970: 3000))
        )
        let issue3 = Issue(
            documentId: documentId,
            title: "Middle issue",
            metadata: IssueMetadata(created: Date(timeIntervalSince1970: 2000))
        )

        try databaseManager.insertIssue(issue2)
        try databaseManager.insertIssue(issue1)
        try databaseManager.insertIssue(issue3)

        let retrieved = try databaseManager.getIssues(forDocument: documentId)
        // Should be ordered by created DESC
        XCTAssertEqual(retrieved[0].title, "New issue")
        XCTAssertEqual(retrieved[1].title, "Middle issue")
        XCTAssertEqual(retrieved[2].title, "Old issue")
    }

    func testIssueAllStatuses() throws {
        let documentId = UUID()

        let statuses: [IssueStatus] = [.open, .inProgress, .resolved, .closed]
        for status in statuses {
            let issue = Issue(
                documentId: documentId,
                title: "Issue with status \(status.rawValue)",
                status: status,
                priority: .medium
            )
            try databaseManager.insertIssue(issue)
        }

        let allIssues = try databaseManager.getAllIssues()
        XCTAssertEqual(allIssues.count, 4)

        for status in statuses {
            let filtered = try databaseManager.getIssues(withStatus: status)
            XCTAssertEqual(filtered.count, 1)
            XCTAssertEqual(filtered.first?.status, status)
        }
    }

    func testIssueAllPriorities() throws {
        let documentId = UUID()

        let priorities: [IssuePriority] = [.low, .medium, .high, .critical]
        for priority in priorities {
            let issue = Issue(
                documentId: documentId,
                title: "Issue with priority \(priority.rawValue)",
                status: .open,
                priority: priority
            )
            try databaseManager.insertIssue(issue)
        }

        let allIssues = try databaseManager.getAllIssues()
        XCTAssertEqual(allIssues.count, 4)
        XCTAssertTrue(allIssues.contains { $0.priority == .low })
        XCTAssertTrue(allIssues.contains { $0.priority == .medium })
        XCTAssertTrue(allIssues.contains { $0.priority == .high })
        XCTAssertTrue(allIssues.contains { $0.priority == .critical })
    }

    func testIssueWithEmptyTags() throws {
        let documentId = UUID()
        let issue = Issue(documentId: documentId, title: "No tags")

        try databaseManager.insertIssue(issue)

        let retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(retrieved.first?.metadata.tags.count, 0)
    }

    // MARK: - Error Handling Tests

    func testOperationWithUninitializedDatabase() throws {
        let uninitializedDB = DatabaseManager(databasePath: "/tmp/test_uninitialized_\(UUID().uuidString).db")

        let suggestion = AISuggestion(
            userId: testUserId,
            toolUsed: "Test",
            prompt: "Test",
            response: "Test"
        )

        XCTAssertThrowsError(try uninitializedDB.insertAISuggestion(suggestion)) { error in
            XCTAssertTrue(error is DatabaseError)
            if case DatabaseError.notInitialized = error {
                // Expected
            } else {
                XCTFail("Expected notInitialized error")
            }
        }
    }

    func testQueryWithUninitializedDatabase() throws {
        let uninitializedDB = DatabaseManager(databasePath: "/tmp/test_uninitialized_\(UUID().uuidString).db")

        XCTAssertThrowsError(try uninitializedDB.getAISuggestions(userId: testUserId)) { error in
            XCTAssertTrue(error is DatabaseError)
        }
    }

    func testCloseAndReopenDatabase() throws {
        let suggestion = AISuggestion(
            userId: testUserId,
            toolUsed: "Test",
            prompt: "Test",
            response: "Test"
        )

        try databaseManager.insertAISuggestion(suggestion)

        databaseManager.close()

        // Should fail after close
        XCTAssertThrowsError(try databaseManager.getAISuggestions(userId: testUserId))

        // Reinitialize
        try databaseManager.initialize()

        // Should work again
        let retrieved = try databaseManager.getAISuggestions(userId: testUserId)
        XCTAssertEqual(retrieved.count, 1)
    }

    func testLargeDataHandling() throws {
        let largeContent = String(repeating: "A", count: 100000)
        let suggestion = AISuggestion(
            userId: testUserId,
            toolUsed: "Test",
            prompt: largeContent,
            response: largeContent
        )

        try databaseManager.insertAISuggestion(suggestion)

        let retrieved = try databaseManager.getAISuggestions(userId: testUserId)
        XCTAssertEqual(retrieved.first?.prompt, largeContent)
        XCTAssertEqual(retrieved.first?.response, largeContent)
    }

    func testUnicodeDataHandling() throws {
        let unicodeText = "Hello 世界! 🌍 Émoji test 日本語"
        let suggestion = AISuggestion(
            userId: testUserId,
            toolUsed: "Unicode Test",
            prompt: unicodeText,
            response: unicodeText
        )

        try databaseManager.insertAISuggestion(suggestion)

        let retrieved = try databaseManager.getAISuggestions(userId: testUserId)
        XCTAssertEqual(retrieved.first?.prompt, unicodeText)
        XCTAssertEqual(retrieved.first?.response, unicodeText)
    }

    func testNullDocumentIdHandling() throws {
        let suggestion = AISuggestion(
            userId: testUserId,
            documentId: nil,
            toolUsed: "Test",
            prompt: "Test",
            response: "Test"
        )

        try databaseManager.insertAISuggestion(suggestion)

        let retrieved = try databaseManager.getAISuggestions(userId: testUserId)
        XCTAssertNil(retrieved.first?.documentId)
    }

    func testMultipleConcurrentOperations() throws {
        // This tests that multiple operations can be performed in succession
        for i in 1...100 {
            let suggestion = AISuggestion(
                userId: testUserId,
                toolUsed: "Tool \(i)",
                prompt: "Prompt \(i)",
                response: "Response \(i)"
            )
            try databaseManager.insertAISuggestion(suggestion)
        }

        let retrieved = try databaseManager.getAISuggestions(userId: testUserId, limit: 100)
        XCTAssertEqual(retrieved.count, 100)
    }

    // MARK: - API Key Persistence (PR Change: apiKey is now persisted)

    func testAPIKeyAlwaysReturnedAsEmptyStringAfterSave() throws {
        let config = AIConfiguration(
            apiKey: "sk-ant-super-secret-key",
            model: .claude35Sonnet,
            maxTokens: 4096,
            temperature: 0.7
        )
        try databaseManager.saveAIConfiguration(userId: testUserId, configuration: config)

        let retrieved = try databaseManager.getAIConfiguration(userId: testUserId)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.apiKey, "sk-ant-super-secret-key",
            "API key must be persisted in the database and returned as supplied")
    }

    func testDifferentAPIKeysAllReturnEmptyString() throws {
        let keys = ["sk-ant-key1", "sk-ant-key2", "sk-ant-key3-with-special!@#"]
        for key in keys {
            let config = AIConfiguration(
                apiKey: key,
                model: .claude35Sonnet,
                maxTokens: 4096,
                temperature: 0.7
            )
            try databaseManager.saveAIConfiguration(userId: testUserId, configuration: config)
            let retrieved = try databaseManager.getAIConfiguration(userId: testUserId)
            XCTAssertEqual(retrieved?.apiKey, key,
                "API key '\(key)' must be stored and returned correctly")
        }
    }

    func testNonAPIKeyConfigurationFieldsArePersistedCorrectly() throws {
        let config = AIConfiguration(
            apiKey: "sk-ant-ignored-key",
            model: .claude3Opus,
            maxTokens: 8192,
            temperature: 0.9
        )
        try databaseManager.saveAIConfiguration(userId: testUserId, configuration: config)

        let retrieved = try databaseManager.getAIConfiguration(userId: testUserId)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.model, .claude3Opus, "Model must persist")
        XCTAssertEqual(retrieved?.maxTokens, 8192, "Max tokens must persist")
        XCTAssertEqual(retrieved?.temperature ?? -1, 0.9, accuracy: 0.001, "Temperature must persist")
        XCTAssertEqual(retrieved?.apiKey, "sk-ant-ignored-key", "API key must be persisted correctly")
    }

    func testAPIKeyEmptyAfterCloseAndReopen() throws {
        let config = AIConfiguration(
            apiKey: "sk-ant-should-not-persist",
            model: .claude35Sonnet,
            maxTokens: 4096,
            temperature: 0.7
        )
        try databaseManager.saveAIConfiguration(userId: testUserId, configuration: config)

        databaseManager.close()
        try databaseManager.initialize()

        let retrieved = try databaseManager.getAIConfiguration(userId: testUserId)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.apiKey, "sk-ant-should-not-persist",
            "After close/reopen, API key must still be returned — it is now persisted in the database")
    }

    func testExplicitlyEmptyAPIKeyAlsoReturnsEmpty() throws {
        // If the caller passes an empty API key, it must round-trip as empty.
        let config = AIConfiguration(
            apiKey: "",
            model: .claude35Sonnet,
            maxTokens: 1024,
            temperature: 0.5
        )
        try databaseManager.saveAIConfiguration(userId: testUserId, configuration: config)

        let retrieved = try databaseManager.getAIConfiguration(userId: testUserId)
        XCTAssertEqual(retrieved?.apiKey, "")
    }

    // MARK: - PR Change: apiKey is now persisted (sqlite3_bind_text uses configuration.apiKey, not "")

    /// After the PR, a non-empty API key must be stored and retrieved as-is.
    func testNonEmptyAPIKeyIsPersistedAndRetrievedCorrectly() throws {
        let expectedKey = "sk-ant-api03-TestKey123"
        let config = AIConfiguration(
            apiKey: expectedKey,
            model: .claude3Sonnet,
            maxTokens: 4096,
            temperature: 0.7
        )
        try databaseManager.saveAIConfiguration(userId: testUserId, configuration: config)

        let retrieved = try databaseManager.getAIConfiguration(userId: testUserId)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.apiKey, expectedKey,
            "PR change: apiKey must now be stored via sqlite3_bind_text(configuration.apiKey) and round-trip correctly")
    }

    /// API key with special characters must be stored and retrieved verbatim.
    func testAPIKeyWithSpecialCharactersIsPersistedCorrectly() throws {
        let specialKey = "sk-ant-api03-AbCdEf!@#_XYZ-09"
        let config = AIConfiguration(
            apiKey: specialKey,
            model: .claude3Opus,
            maxTokens: 2048,
            temperature: 0.5
        )
        try databaseManager.saveAIConfiguration(userId: testUserId, configuration: config)

        let retrieved = try databaseManager.getAIConfiguration(userId: testUserId)
        XCTAssertEqual(retrieved?.apiKey, specialKey,
            "API keys with special characters must be stored and retrieved without modification")
    }

    /// Saving a second configuration must replace the stored apiKey.
    func testUpdatingAPIKeyReplacesStoredValue() throws {
        let config1 = AIConfiguration(apiKey: "initial-key", model: .claude3Sonnet, maxTokens: 4096, temperature: 0.7)
        try databaseManager.saveAIConfiguration(userId: testUserId, configuration: config1)

        let config2 = AIConfiguration(apiKey: "updated-key", model: .claude3Sonnet, maxTokens: 4096, temperature: 0.7)
        try databaseManager.saveAIConfiguration(userId: testUserId, configuration: config2)

        let retrieved = try databaseManager.getAIConfiguration(userId: testUserId)
        XCTAssertEqual(retrieved?.apiKey, "updated-key",
            "After saving a second configuration, the updated apiKey must replace the original")
    }

    /// Empty string apiKey continues to round-trip as empty (no regression from PR change).
    func testEmptyAPIKeyRoundTripAfterPRChange() throws {
        let config = AIConfiguration(apiKey: "", model: .claude35Sonnet, maxTokens: 8192, temperature: 0.3)
        try databaseManager.saveAIConfiguration(userId: testUserId, configuration: config)

        let retrieved = try databaseManager.getAIConfiguration(userId: testUserId)
        XCTAssertEqual(retrieved?.apiKey, "",
            "An explicitly empty apiKey must still be stored and retrieved as an empty string after the PR change")
    }

    /// All non-apiKey fields remain correct when a non-empty apiKey is stored.
    func testNonAPIKeyFieldsArePreservedWhenAPIKeyIsNonEmpty() throws {
        let config = AIConfiguration(
            apiKey: "my-real-key",
            model: .claude3Opus,
            maxTokens: 8192,
            temperature: 0.9
        )
        try databaseManager.saveAIConfiguration(userId: testUserId, configuration: config)

        let retrieved = try databaseManager.getAIConfiguration(userId: testUserId)
        XCTAssertEqual(retrieved?.model, .claude3Opus,
            "model must persist alongside a non-empty apiKey")
        XCTAssertEqual(retrieved?.maxTokens, 8192,
            "maxTokens must persist alongside a non-empty apiKey")
        XCTAssertEqual(retrieved?.temperature ?? -1, 0.9, accuracy: 0.001,
            "temperature must persist alongside a non-empty apiKey")
    }

    /// A very long API key must be stored and retrieved correctly.
    func testLongAPIKeyIsPersistedCorrectly() throws {
        let longKey = "sk-ant-" + String(repeating: "x", count: 200)
        let config = AIConfiguration(apiKey: longKey, model: .claude3Haiku, maxTokens: 1024, temperature: 0.1)
        try databaseManager.saveAIConfiguration(userId: testUserId, configuration: config)

        let retrieved = try databaseManager.getAIConfiguration(userId: testUserId)
        XCTAssertEqual(retrieved?.apiKey, longKey,
            "A very long API key must be stored and retrieved in full")
    }
}