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
        let branch = VCBranch(name: "feature-1", isActive: true)

        try databaseManager.insertVCBranch(branch)

        let retrieved = try databaseManager.getVCBranch(name: "feature-1")
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.id, branch.id)
        XCTAssertEqual(retrieved?.name, "feature-1")
        XCTAssertEqual(retrieved?.isActive, true)
        XCTAssertNil(retrieved?.headCommitId)
    }

    func testGetAllVCBranches() throws {
        let branches = [
            VCBranch(name: "main", isActive: true),
            VCBranch(name: "develop", isActive: false),
            VCBranch(name: "feature-x", isActive: false)
        ]

        for branch in branches {
            try databaseManager.insertVCBranch(branch)
        }

        let retrieved = try databaseManager.getAllVCBranches()
        XCTAssertEqual(retrieved.count, 3)
        XCTAssertTrue(retrieved.contains(where: { $0.name == "main" }))
        XCTAssertTrue(retrieved.contains(where: { $0.name == "develop" }))
        XCTAssertTrue(retrieved.contains(where: { $0.name == "feature-x" }))
    }

    func testUpdateVCBranch() throws {
        var branch = VCBranch(name: "main", isActive: false)
        try databaseManager.insertVCBranch(branch)

        let commitId = UUID()
        branch.headCommitId = commitId
        branch.isActive = true

        try databaseManager.updateVCBranch(branch)

        let retrieved = try databaseManager.getVCBranch(name: "main")
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

        let allBranches = try databaseManager.getAllVCBranches()
        let mainBranch = allBranches.first(where: { $0.name == "main" })
        let featureBranch = allBranches.first(where: { $0.name == "feature" })

        XCTAssertEqual(mainBranch?.isActive, false)
        XCTAssertEqual(featureBranch?.isActive, true)
    }

    func testGetVCBranchByNameReturnsNilForNonexistent() throws {
        let retrieved = try databaseManager.getVCBranch(name: "nonexistent")
        XCTAssertNil(retrieved)
    }

    // MARK: - Version Control: Commit Tests

    func testInsertAndRetrieveVCCommit() throws {
        let branch = VCBranch(name: "main", isActive: true)
        try databaseManager.insertVCBranch(branch)

        let commit = VCCommit(
            branchId: branch.id,
            message: "Initial commit",
            authorId: "author-1"
        )

        try databaseManager.insertVCCommit(commit)

        let retrieved = try databaseManager.getVCCommits(branchId: branch.id)
        XCTAssertEqual(retrieved.count, 1)
        XCTAssertEqual(retrieved.first?.id, commit.id)
        XCTAssertEqual(retrieved.first?.message, "Initial commit")
        XCTAssertEqual(retrieved.first?.authorId, "author-1")
    }

    func testVCCommitWithParent() throws {
        let branch = VCBranch(name: "main", isActive: true)
        try databaseManager.insertVCBranch(branch)

        let parentCommit = VCCommit(
            branchId: branch.id,
            message: "First commit"
        )
        try databaseManager.insertVCCommit(parentCommit)

        let childCommit = VCCommit(
            branchId: branch.id,
            message: "Second commit",
            parentCommitId: parentCommit.id
        )
        try databaseManager.insertVCCommit(childCommit)

        let retrieved = try databaseManager.getVCCommits(branchId: branch.id)
        XCTAssertEqual(retrieved.count, 2)
        XCTAssertEqual(retrieved.last?.parentCommitId, parentCommit.id)
    }

    func testVCMergeCommitWithTwoParents() throws {
        let mainBranch = VCBranch(name: "main", isActive: true)
        let featureBranch = VCBranch(name: "feature", isActive: false)

        try databaseManager.insertVCBranch(mainBranch)
        try databaseManager.insertVCBranch(featureBranch)

        let mainCommit = VCCommit(branchId: mainBranch.id, message: "Main commit")
        let featureCommit = VCCommit(branchId: featureBranch.id, message: "Feature commit")

        try databaseManager.insertVCCommit(mainCommit)
        try databaseManager.insertVCCommit(featureCommit)

        let mergeCommit = VCCommit(
            branchId: mainBranch.id,
            message: "Merge feature into main",
            parentCommitId: mainCommit.id,
            secondParentCommitId: featureCommit.id
        )
        try databaseManager.insertVCCommit(mergeCommit)

        let retrieved = try databaseManager.getVCCommits(branchId: mainBranch.id)
        let merge = retrieved.first(where: { $0.id == mergeCommit.id })

        XCTAssertNotNil(merge)
        XCTAssertEqual(merge?.parentCommitId, mainCommit.id)
        XCTAssertEqual(merge?.secondParentCommitId, featureCommit.id)
    }

    func testVCCommitsOrderedByTimestamp() throws {
        let branch = VCBranch(name: "main", isActive: true)
        try databaseManager.insertVCBranch(branch)

        let commit1 = VCCommit(branchId: branch.id, message: "First", timestamp: Date(timeIntervalSince1970: 1000))
        let commit2 = VCCommit(branchId: branch.id, message: "Second", timestamp: Date(timeIntervalSince1970: 2000))
        let commit3 = VCCommit(branchId: branch.id, message: "Third", timestamp: Date(timeIntervalSince1970: 3000))

        // Insert in random order
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

        let commit = VCCommit(branchId: branch.id, message: "Test commit")
        try databaseManager.insertVCCommit(commit)

        let snapshot = VCDocumentSnapshot(
            commitId: commit.id,
            documentId: UUID(),
            title: "Test Document",
            content: "This is test content.",
            category: "Novel",
            wordCount: 4
        )

        try databaseManager.insertVCSnapshot(snapshot)

        let retrieved = try databaseManager.getVCSnapshots(commitId: commit.id)
        XCTAssertEqual(retrieved.count, 1)
        XCTAssertEqual(retrieved.first?.id, snapshot.id)
        XCTAssertEqual(retrieved.first?.title, "Test Document")
        XCTAssertEqual(retrieved.first?.content, "This is test content.")
        XCTAssertEqual(retrieved.first?.wordCount, 4)
    }

    func testMultipleSnapshotsPerCommit() throws {
        let branch = VCBranch(name: "main", isActive: true)
        try databaseManager.insertVCBranch(branch)

        let commit = VCCommit(branchId: branch.id, message: "Multi-doc commit")
        try databaseManager.insertVCCommit(commit)

        let doc1Id = UUID()
        let doc2Id = UUID()

        let snapshot1 = VCDocumentSnapshot(
            commitId: commit.id,
            documentId: doc1Id,
            title: "Doc 1",
            content: "Content 1",
            category: "Novel",
            wordCount: 2
        )

        let snapshot2 = VCDocumentSnapshot(
            commitId: commit.id,
            documentId: doc2Id,
            title: "Doc 2",
            content: "Content 2",
            category: "Essay",
            wordCount: 2
        )

        try databaseManager.insertVCSnapshot(snapshot1)
        try databaseManager.insertVCSnapshot(snapshot2)

        let retrieved = try databaseManager.getVCSnapshots(commitId: commit.id)
        XCTAssertEqual(retrieved.count, 2)
        XCTAssertTrue(retrieved.contains(where: { $0.documentId == doc1Id }))
        XCTAssertTrue(retrieved.contains(where: { $0.documentId == doc2Id }))
    }

    func testGetVCSnapshotsForDocument() throws {
        let branch = VCBranch(name: "main", isActive: true)
        try databaseManager.insertVCBranch(branch)

        let documentId = UUID()

        // Create multiple commits with snapshots of the same document
        let commit1 = VCCommit(branchId: branch.id, message: "Commit 1", timestamp: Date(timeIntervalSince1970: 1000))
        let commit2 = VCCommit(branchId: branch.id, message: "Commit 2", timestamp: Date(timeIntervalSince1970: 2000))

        try databaseManager.insertVCCommit(commit1)
        try databaseManager.insertVCCommit(commit2)

        let snapshot1 = VCDocumentSnapshot(
            commitId: commit1.id,
            documentId: documentId,
            title: "Version 1",
            content: "Initial content",
            category: "Novel",
            wordCount: 2,
            capturedAt: Date(timeIntervalSince1970: 1000)
        )

        let snapshot2 = VCDocumentSnapshot(
            commitId: commit2.id,
            documentId: documentId,
            title: "Version 2",
            content: "Updated content",
            category: "Novel",
            wordCount: 2,
            capturedAt: Date(timeIntervalSince1970: 2000)
        )

        try databaseManager.insertVCSnapshot(snapshot1)
        try databaseManager.insertVCSnapshot(snapshot2)

        let history = try databaseManager.getVCSnapshotsForDocument(documentId: documentId)

        XCTAssertEqual(history.count, 2)
        XCTAssertEqual(history[0].title, "Version 1")
        XCTAssertEqual(history[1].title, "Version 2")
    }

    func testGetVCSnapshotsAsOf() throws {
        let branch = VCBranch(name: "main", isActive: true)
        try databaseManager.insertVCBranch(branch)

        let doc1Id = UUID()
        let doc2Id = UUID()

        // Create commits at different times
        let commit1 = VCCommit(branchId: branch.id, message: "Commit 1")
        let commit2 = VCCommit(branchId: branch.id, message: "Commit 2")

        try databaseManager.insertVCCommit(commit1)
        try databaseManager.insertVCCommit(commit2)

        // Document 1 has snapshots at t=1000 and t=3000
        let snap1_v1 = VCDocumentSnapshot(
            commitId: commit1.id,
            documentId: doc1Id,
            title: "Doc1 v1",
            content: "First version",
            category: "Novel",
            wordCount: 2,
            capturedAt: Date(timeIntervalSince1970: 1000)
        )

        let snap1_v2 = VCDocumentSnapshot(
            commitId: commit2.id,
            documentId: doc1Id,
            title: "Doc1 v2",
            content: "Second version",
            category: "Novel",
            wordCount: 2,
            capturedAt: Date(timeIntervalSince1970: 3000)
        )

        // Document 2 has a snapshot at t=2000
        let snap2_v1 = VCDocumentSnapshot(
            commitId: commit1.id,
            documentId: doc2Id,
            title: "Doc2 v1",
            content: "Content",
            category: "Essay",
            wordCount: 1,
            capturedAt: Date(timeIntervalSince1970: 2000)
        )

        try databaseManager.insertVCSnapshot(snap1_v1)
        try databaseManager.insertVCSnapshot(snap1_v2)
        try databaseManager.insertVCSnapshot(snap2_v1)

        // Query as of t=2500: should get snap1_v1 (latest before 2500) and snap2_v1
        let asOf = try databaseManager.getVCSnapshotsAsOf(date: Date(timeIntervalSince1970: 2500))

        XCTAssertEqual(asOf.count, 2)

        let doc1Snap = asOf.first(where: { $0.documentId == doc1Id })
        let doc2Snap = asOf.first(where: { $0.documentId == doc2Id })

        XCTAssertNotNil(doc1Snap)
        XCTAssertNotNil(doc2Snap)
        XCTAssertEqual(doc1Snap?.title, "Doc1 v1")
        XCTAssertEqual(doc2Snap?.title, "Doc2 v1")
    }

    func testGetVCSnapshotsAsOfEdgeCase() throws {
        let branch = VCBranch(name: "main", isActive: true)
        try databaseManager.insertVCBranch(branch)

        let documentId = UUID()
        let commit = VCCommit(branchId: branch.id, message: "Commit")
        try databaseManager.insertVCCommit(commit)

        let snapshot = VCDocumentSnapshot(
            commitId: commit.id,
            documentId: documentId,
            title: "Doc",
            content: "Content",
            category: "Novel",
            wordCount: 1,
            capturedAt: Date(timeIntervalSince1970: 2000)
        )

        try databaseManager.insertVCSnapshot(snapshot)

        // Query before any snapshots exist
        let beforeAll = try databaseManager.getVCSnapshotsAsOf(date: Date(timeIntervalSince1970: 1000))
        XCTAssertEqual(beforeAll.count, 0)

        // Query exactly at the snapshot time
        let exactTime = try databaseManager.getVCSnapshotsAsOf(date: Date(timeIntervalSince1970: 2000))
        XCTAssertEqual(exactTime.count, 1)

        // Query after the snapshot time
        let afterAll = try databaseManager.getVCSnapshotsAsOf(date: Date(timeIntervalSince1970: 3000))
        XCTAssertEqual(afterAll.count, 1)
    }

    // MARK: - Trace Tests

    func testInsertAndRetrieveTrace() throws {
        let trace = Trace(
            sessionId: "session-123",
            name: "AI Generation",
            startTime: Date(),
            metadata: "{\"model\": \"gpt-4\"}"
        )

        try databaseManager.insertTrace(trace)

        let retrieved = try databaseManager.getTraces()
        XCTAssertEqual(retrieved.count, 1)
        XCTAssertEqual(retrieved.first?.id, trace.id)
        XCTAssertEqual(retrieved.first?.sessionId, "session-123")
        XCTAssertEqual(retrieved.first?.name, "AI Generation")
        XCTAssertEqual(retrieved.first?.metadata, "{\"model\": \"gpt-4\"}")
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

        let session2Traces = try databaseManager.getTraces(sessionId: "session-2")
        XCTAssertEqual(session2Traces.count, 1)
        XCTAssertEqual(session2Traces.first?.name, "Trace 2")
    }

    func testTraceWithEndTime() throws {
        let startTime = Date()
        let endTime = Date(timeInterval: 30, since: startTime)

        let trace = Trace(
            sessionId: "session-1",
            name: "Completed Trace",
            startTime: startTime,
            endTime: endTime
        )

        try databaseManager.insertTrace(trace)

        let retrieved = try databaseManager.getTraces()
        XCTAssertNotNil(retrieved.first?.endTime)
        XCTAssertEqual(retrieved.first?.endTime?.timeIntervalSince1970, endTime.timeIntervalSince1970, accuracy: 0.01)
    }

    func testTraceWithoutMetadata() throws {
        let trace = Trace(
            sessionId: "session-1",
            name: "Simple Trace",
            metadata: nil
        )

        try databaseManager.insertTrace(trace)

        let retrieved = try databaseManager.getTraces()
        XCTAssertEqual(retrieved.count, 1)
        XCTAssertNil(retrieved.first?.metadata)
    }

    // MARK: - Observation Tests

    func testInsertAndRetrieveObservation() throws {
        let trace = Trace(sessionId: "session-1", name: "Parent Trace")
        try databaseManager.insertTrace(trace)

        let observation = Observation(
            traceId: trace.id,
            name: "Read File",
            input: "/path/to/file.txt",
            output: "File content here",
            statusMessage: "Success"
        )

        try databaseManager.insertObservation(observation)

        let retrieved = try databaseManager.getObservations(traceId: trace.id)
        XCTAssertEqual(retrieved.count, 1)
        XCTAssertEqual(retrieved.first?.id, observation.id)
        XCTAssertEqual(retrieved.first?.name, "Read File")
        XCTAssertEqual(retrieved.first?.input, "/path/to/file.txt")
        XCTAssertEqual(retrieved.first?.output, "File content here")
        XCTAssertEqual(retrieved.first?.statusMessage, "Success")
    }

    func testMultipleObservationsPerTrace() throws {
        let trace = Trace(sessionId: "session-1", name: "Multi-step Trace")
        try databaseManager.insertTrace(trace)

        let obs1 = Observation(
            traceId: trace.id,
            name: "Step 1",
            startTime: Date(timeIntervalSince1970: 1000)
        )

        let obs2 = Observation(
            traceId: trace.id,
            name: "Step 2",
            startTime: Date(timeIntervalSince1970: 2000)
        )

        let obs3 = Observation(
            traceId: trace.id,
            name: "Step 3",
            startTime: Date(timeIntervalSince1970: 3000)
        )

        try databaseManager.insertObservation(obs1)
        try databaseManager.insertObservation(obs2)
        try databaseManager.insertObservation(obs3)

        let retrieved = try databaseManager.getObservations(traceId: trace.id)
        XCTAssertEqual(retrieved.count, 3)
        // Verify ordered by start time
        XCTAssertEqual(retrieved[0].name, "Step 1")
        XCTAssertEqual(retrieved[1].name, "Step 2")
        XCTAssertEqual(retrieved[2].name, "Step 3")
    }

    func testObservationWithOptionalFields() throws {
        let trace = Trace(sessionId: "session-1", name: "Trace")
        try databaseManager.insertTrace(trace)

        // Observation with minimal fields
        let observation = Observation(
            traceId: trace.id,
            name: "Minimal Observation"
        )

        try databaseManager.insertObservation(observation)

        let retrieved = try databaseManager.getObservations(traceId: trace.id)
        XCTAssertEqual(retrieved.count, 1)
        XCTAssertEqual(retrieved.first?.name, "Minimal Observation")
        XCTAssertNil(retrieved.first?.endTime)
        XCTAssertNil(retrieved.first?.input)
        XCTAssertNil(retrieved.first?.output)
        XCTAssertNil(retrieved.first?.statusMessage)
    }

    func testObservationWithEndTime() throws {
        let trace = Trace(sessionId: "session-1", name: "Trace")
        try databaseManager.insertTrace(trace)

        let startTime = Date()
        let endTime = Date(timeInterval: 5, since: startTime)

        let observation = Observation(
            traceId: trace.id,
            name: "Timed Observation",
            startTime: startTime,
            endTime: endTime
        )

        try databaseManager.insertObservation(observation)

        let retrieved = try databaseManager.getObservations(traceId: trace.id)
        XCTAssertNotNil(retrieved.first?.endTime)
    }

    // MARK: - Issue Tests

    func testInsertAndRetrieveIssue() throws {
        let documentId = UUID()
        let issue = Issue(
            documentId: documentId,
            title: "Plot hole in chapter 3",
            description: "Need to explain how the character got there",
            status: .open,
            priority: .high
        )

        try databaseManager.insertIssue(issue)

        let retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(retrieved.count, 1)
        XCTAssertEqual(retrieved.first?.id, issue.id)
        XCTAssertEqual(retrieved.first?.title, "Plot hole in chapter 3")
        XCTAssertEqual(retrieved.first?.status, .open)
        XCTAssertEqual(retrieved.first?.priority, .high)
    }

    func testUpdateIssue() throws {
        let documentId = UUID()
        var issue = Issue(
            documentId: documentId,
            title: "Fix typo",
            status: .open,
            priority: .low
        )

        try databaseManager.insertIssue(issue)

        // Update the issue
        issue.status = .resolved
        issue.priority = .medium
        issue.description = "Fixed the typo in paragraph 2"
        issue.metadata.resolvedAt = Date()

        try databaseManager.updateIssue(issue)

        let retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(retrieved.first?.status, .resolved)
        XCTAssertEqual(retrieved.first?.priority, .medium)
        XCTAssertEqual(retrieved.first?.description, "Fixed the typo in paragraph 2")
        XCTAssertNotNil(retrieved.first?.metadata.resolvedAt)
    }

    func testDeleteIssue() throws {
        let documentId = UUID()
        let issue = Issue(
            documentId: documentId,
            title: "Test issue"
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

        let issue1 = Issue(documentId: documentId, title: "Issue 1", status: .open)
        let issue2 = Issue(documentId: documentId, title: "Issue 2", status: .inProgress)
        let issue3 = Issue(documentId: documentId, title: "Issue 3", status: .open)
        let issue4 = Issue(documentId: documentId, title: "Issue 4", status: .resolved)

        try databaseManager.insertIssue(issue1)
        try databaseManager.insertIssue(issue2)
        try databaseManager.insertIssue(issue3)
        try databaseManager.insertIssue(issue4)

        let openIssues = try databaseManager.getIssues(withStatus: .open)
        XCTAssertEqual(openIssues.count, 2)
        XCTAssertTrue(openIssues.allSatisfy { $0.status == .open })

        let inProgressIssues = try databaseManager.getIssues(withStatus: .inProgress)
        XCTAssertEqual(inProgressIssues.count, 1)
        XCTAssertEqual(inProgressIssues.first?.title, "Issue 2")
    }

    func testGetAllIssues() throws {
        let doc1 = UUID()
        let doc2 = UUID()

        let issue1 = Issue(documentId: doc1, title: "Issue 1")
        let issue2 = Issue(documentId: doc2, title: "Issue 2")
        let issue3 = Issue(documentId: doc1, title: "Issue 3")

        try databaseManager.insertIssue(issue1)
        try databaseManager.insertIssue(issue2)
        try databaseManager.insertIssue(issue3)

        let allIssues = try databaseManager.getAllIssues()
        XCTAssertEqual(allIssues.count, 3)
    }

    func testIssueWithTags() throws {
        let documentId = UUID()
        var metadata = IssueMetadata()
        metadata.tags = ["grammar", "style", "urgent"]

        let issue = Issue(
            documentId: documentId,
            title: "Multiple tags issue",
            metadata: metadata
        )

        try databaseManager.insertIssue(issue)

        let retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(retrieved.first?.metadata.tags.count, 3)
        XCTAssertTrue(retrieved.first?.metadata.tags.contains("grammar") ?? false)
        XCTAssertTrue(retrieved.first?.metadata.tags.contains("style") ?? false)
        XCTAssertTrue(retrieved.first?.metadata.tags.contains("urgent") ?? false)
    }

    func testIssuePagination() throws {
        let documentId = UUID()

        // Insert 25 issues
        for i in 1...25 {
            let issue = Issue(
                documentId: documentId,
                title: "Issue \(i)"
            )
            try databaseManager.insertIssue(issue)
        }

        // Test pagination
        let page1 = try databaseManager.getIssues(forDocument: documentId, limit: 10, offset: 0)
        XCTAssertEqual(page1.count, 10)

        let page2 = try databaseManager.getIssues(forDocument: documentId, limit: 10, offset: 10)
        XCTAssertEqual(page2.count, 10)

        let page3 = try databaseManager.getIssues(forDocument: documentId, limit: 10, offset: 20)
        XCTAssertEqual(page3.count, 5)
    }

    func testIssueWithNotes() throws {
        let documentId = UUID()
        var metadata = IssueMetadata()
        metadata.notes = "This needs to be addressed before publication."

        let issue = Issue(
            documentId: documentId,
            title: "Critical issue",
            metadata: metadata
        )

        try databaseManager.insertIssue(issue)

        let retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(retrieved.first?.metadata.notes, "This needs to be addressed before publication.")
    }
}