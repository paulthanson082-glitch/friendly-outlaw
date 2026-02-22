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

    // MARK: - Trace Tests

    func testInsertAndRetrieveTrace() throws {
        let trace = Trace(
            sessionId: "session-123",
            name: "test-trace",
            startTime: Date(),
            endTime: Date().addingTimeInterval(60)
        )

        try databaseManager.insertTrace(trace)

        let retrieved = try databaseManager.getTraces(sessionId: "session-123")
        XCTAssertEqual(retrieved.count, 1)
        XCTAssertEqual(retrieved.first?.id, trace.id)
        XCTAssertEqual(retrieved.first?.name, "test-trace")
    }

    func testGetAllTraces() throws {
        let trace1 = Trace(sessionId: "session-1", name: "trace-1")
        let trace2 = Trace(sessionId: "session-2", name: "trace-2")
        let trace3 = Trace(sessionId: "session-1", name: "trace-3")

        try databaseManager.insertTrace(trace1)
        try databaseManager.insertTrace(trace2)
        try databaseManager.insertTrace(trace3)

        let allTraces = try databaseManager.getTraces()
        XCTAssertEqual(allTraces.count, 3)
    }

    func testGetTracesFilteredBySession() throws {
        let trace1 = Trace(sessionId: "session-1", name: "trace-1")
        let trace2 = Trace(sessionId: "session-2", name: "trace-2")
        let trace3 = Trace(sessionId: "session-1", name: "trace-3")

        try databaseManager.insertTrace(trace1)
        try databaseManager.insertTrace(trace2)
        try databaseManager.insertTrace(trace3)

        let session1Traces = try databaseManager.getTraces(sessionId: "session-1")
        XCTAssertEqual(session1Traces.count, 2)
        XCTAssertTrue(session1Traces.allSatisfy { $0.sessionId == "session-1" })
    }

    func testTraceWithMetadata() throws {
        let metadataJSON = "{\"key\":\"value\",\"count\":42}"
        let trace = Trace(
            sessionId: "session-123",
            name: "metadata-trace",
            metadata: metadataJSON
        )

        try databaseManager.insertTrace(trace)

        let retrieved = try databaseManager.getTraces(sessionId: "session-123")
        XCTAssertEqual(retrieved.first?.metadata, metadataJSON)
    }

    func testTraceWithNullEndTime() throws {
        let trace = Trace(
            sessionId: "session-123",
            name: "ongoing-trace",
            startTime: Date(),
            endTime: nil
        )

        try databaseManager.insertTrace(trace)

        let retrieved = try databaseManager.getTraces(sessionId: "session-123")
        XCTAssertNil(retrieved.first?.endTime)
    }

    // MARK: - Observation Tests

    func testInsertAndRetrieveObservation() throws {
        let trace = Trace(sessionId: "session-123", name: "parent-trace")
        try databaseManager.insertTrace(trace)

        let observation = Observation(
            traceId: trace.id,
            name: "test-observation",
            startTime: Date(),
            endTime: Date().addingTimeInterval(30),
            input: "input text",
            output: "output text"
        )

        try databaseManager.insertObservation(observation)

        let retrieved = try databaseManager.getObservations(traceId: trace.id)
        XCTAssertEqual(retrieved.count, 1)
        XCTAssertEqual(retrieved.first?.id, observation.id)
        XCTAssertEqual(retrieved.first?.name, "test-observation")
        XCTAssertEqual(retrieved.first?.input, "input text")
        XCTAssertEqual(retrieved.first?.output, "output text")
    }

    func testMultipleObservationsForTrace() throws {
        let trace = Trace(sessionId: "session-123", name: "parent-trace")
        try databaseManager.insertTrace(trace)

        for i in 1...5 {
            let observation = Observation(
                traceId: trace.id,
                name: "observation-\(i)",
                input: "input-\(i)",
                output: "output-\(i)"
            )
            try databaseManager.insertObservation(observation)
        }

        let retrieved = try databaseManager.getObservations(traceId: trace.id)
        XCTAssertEqual(retrieved.count, 5)
    }

    func testObservationWithStatusMessage() throws {
        let trace = Trace(sessionId: "session-123", name: "parent-trace")
        try databaseManager.insertTrace(trace)

        let observation = Observation(
            traceId: trace.id,
            name: "status-observation",
            statusMessage: "completed successfully"
        )

        try databaseManager.insertObservation(observation)

        let retrieved = try databaseManager.getObservations(traceId: trace.id)
        XCTAssertEqual(retrieved.first?.statusMessage, "completed successfully")
    }

    func testObservationWithNullFields() throws {
        let trace = Trace(sessionId: "session-123", name: "parent-trace")
        try databaseManager.insertTrace(trace)

        let observation = Observation(
            traceId: trace.id,
            name: "minimal-observation",
            input: nil,
            output: nil,
            statusMessage: nil
        )

        try databaseManager.insertObservation(observation)

        let retrieved = try databaseManager.getObservations(traceId: trace.id)
        XCTAssertNil(retrieved.first?.input)
        XCTAssertNil(retrieved.first?.output)
        XCTAssertNil(retrieved.first?.statusMessage)
    }

    // MARK: - Issue Database Tests

    func testInsertAndRetrieveIssue() throws {
        let documentId = UUID()
        let issue = Issue(
            documentId: documentId,
            title: "Test Issue",
            description: "Test description",
            status: .open,
            priority: .high
        )

        try databaseManager.insertIssue(issue)

        let retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(retrieved.count, 1)
        XCTAssertEqual(retrieved.first?.id, issue.id)
        XCTAssertEqual(retrieved.first?.title, "Test Issue")
        XCTAssertEqual(retrieved.first?.status, .open)
        XCTAssertEqual(retrieved.first?.priority, .high)
    }

    func testUpdateIssue() throws {
        let documentId = UUID()
        var issue = Issue(
            documentId: documentId,
            title: "Original Title",
            description: "Original description",
            status: .open,
            priority: .medium
        )

        try databaseManager.insertIssue(issue)

        issue.title = "Updated Title"
        issue.description = "Updated description"
        issue.status = .inProgress
        issue.priority = .high

        try databaseManager.updateIssue(issue)

        let retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(retrieved.first?.title, "Updated Title")
        XCTAssertEqual(retrieved.first?.description, "Updated description")
        XCTAssertEqual(retrieved.first?.status, .inProgress)
        XCTAssertEqual(retrieved.first?.priority, .high)
    }

    func testDeleteIssue() throws {
        let documentId = UUID()
        let issue = Issue(documentId: documentId, title: "To Delete")

        try databaseManager.insertIssue(issue)

        var retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(retrieved.count, 1)

        try databaseManager.deleteIssue(id: issue.id)

        retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(retrieved.count, 0)
    }

    func testGetIssuesByStatus() throws {
        let documentId = UUID()

        let issue1 = Issue(documentId: documentId, title: "Open 1", status: .open)
        let issue2 = Issue(documentId: documentId, title: "Open 2", status: .open)
        let issue3 = Issue(documentId: documentId, title: "In Progress", status: .inProgress)

        try databaseManager.insertIssue(issue1)
        try databaseManager.insertIssue(issue2)
        try databaseManager.insertIssue(issue3)

        let openIssues = try databaseManager.getIssues(withStatus: .open)
        XCTAssertEqual(openIssues.count, 2)
        XCTAssertTrue(openIssues.allSatisfy { $0.status == .open })
    }

    func testGetAllIssuesWithPagination() throws {
        let documentId = UUID()

        for i in 1...15 {
            let issue = Issue(documentId: documentId, title: "Issue \(i)")
            try databaseManager.insertIssue(issue)
        }

        let firstPage = try databaseManager.getAllIssues(limit: 5, offset: 0)
        XCTAssertEqual(firstPage.count, 5)

        let secondPage = try databaseManager.getAllIssues(limit: 5, offset: 5)
        XCTAssertEqual(secondPage.count, 5)

        let thirdPage = try databaseManager.getAllIssues(limit: 5, offset: 10)
        XCTAssertEqual(thirdPage.count, 5)
    }

    func testIssueTagsEncoding() throws {
        let documentId = UUID()
        var issue = Issue(documentId: documentId, title: "Tagged Issue")
        issue.metadata.tags = ["urgent", "bug", "documentation"]

        try databaseManager.insertIssue(issue)

        let retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(retrieved.first?.metadata.tags.count, 3)
        XCTAssertTrue(retrieved.first?.metadata.tags.contains("urgent") ?? false)
        XCTAssertTrue(retrieved.first?.metadata.tags.contains("bug") ?? false)
        XCTAssertTrue(retrieved.first?.metadata.tags.contains("documentation") ?? false)
    }

    func testIssueResolvedTimestamp() throws {
        let documentId = UUID()
        let resolvedDate = Date()

        var issue = Issue(documentId: documentId, title: "Resolved Issue")
        issue.metadata.resolvedAt = resolvedDate

        try databaseManager.insertIssue(issue)

        let retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertNotNil(retrieved.first?.metadata.resolvedAt)
    }

    // MARK: - Version Control: Branch Tests

    func testInsertAndRetrieveBranch() throws {
        let branch = VCBranch(name: "main", isActive: true)

        try databaseManager.insertVCBranch(branch)

        let retrieved = try databaseManager.getVCBranch(name: "main")
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.id, branch.id)
        XCTAssertEqual(retrieved?.name, "main")
        XCTAssertTrue(retrieved?.isActive ?? false)
    }

    func testGetAllBranches() throws {
        let branch1 = VCBranch(name: "main", isActive: true)
        let branch2 = VCBranch(name: "feature-1", isActive: false)
        let branch3 = VCBranch(name: "feature-2", isActive: false)

        try databaseManager.insertVCBranch(branch1)
        try databaseManager.insertVCBranch(branch2)
        try databaseManager.insertVCBranch(branch3)

        let branches = try databaseManager.getAllVCBranches()
        XCTAssertEqual(branches.count, 3)
    }

    func testUpdateBranch() throws {
        let commitId = UUID()
        var branch = VCBranch(name: "main", headCommitId: nil, isActive: true)

        try databaseManager.insertVCBranch(branch)

        branch.headCommitId = commitId
        branch.isActive = false

        try databaseManager.updateVCBranch(branch)

        let retrieved = try databaseManager.getVCBranch(name: "main")
        XCTAssertEqual(retrieved?.headCommitId, commitId)
        XCTAssertFalse(retrieved?.isActive ?? true)
    }

    func testSetActiveBranch() throws {
        let branch1 = VCBranch(name: "main", isActive: true)
        let branch2 = VCBranch(name: "feature", isActive: false)

        try databaseManager.insertVCBranch(branch1)
        try databaseManager.insertVCBranch(branch2)

        try databaseManager.setActiveBranch(id: branch2.id)

        let branches = try databaseManager.getAllVCBranches()
        let mainBranch = branches.first { $0.name == "main" }
        let featureBranch = branches.first { $0.name == "feature" }

        XCTAssertFalse(mainBranch?.isActive ?? true)
        XCTAssertTrue(featureBranch?.isActive ?? false)
    }

    func testSetActiveBranchTransaction() throws {
        let branch1 = VCBranch(name: "main", isActive: true)

        try databaseManager.insertVCBranch(branch1)

        // All branches should be inactive then one should be active
        try databaseManager.setActiveBranch(id: branch1.id)

        let branches = try databaseManager.getAllVCBranches()
        let activeBranches = branches.filter { $0.isActive }
        XCTAssertEqual(activeBranches.count, 1)
    }

    // MARK: - Version Control: Commit Tests

    func testInsertAndRetrieveCommit() throws {
        let branch = VCBranch(name: "main")
        try databaseManager.insertVCBranch(branch)

        let commit = VCCommit(
            branchId: branch.id,
            message: "Initial commit",
            authorId: "author-123"
        )

        try databaseManager.insertVCCommit(commit)

        let retrieved = try databaseManager.getVCCommits(branchId: branch.id)
        XCTAssertEqual(retrieved.count, 1)
        XCTAssertEqual(retrieved.first?.id, commit.id)
        XCTAssertEqual(retrieved.first?.message, "Initial commit")
        XCTAssertEqual(retrieved.first?.authorId, "author-123")
    }

    func testCommitWithParent() throws {
        let branch = VCBranch(name: "main")
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
        XCTAssertEqual(retrieved.last?.parentCommitId, commit1.id)
    }

    func testMergeCommitWithTwoParents() throws {
        let branch = VCBranch(name: "main")
        try databaseManager.insertVCBranch(branch)

        let commit1 = VCCommit(branchId: branch.id, message: "Commit 1")
        let commit2 = VCCommit(branchId: branch.id, message: "Commit 2")
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
        let merge = retrieved.first { $0.message == "Merge commit" }
        XCTAssertEqual(merge?.parentCommitId, commit1.id)
        XCTAssertEqual(merge?.secondParentCommitId, commit2.id)
    }

    func testGetCommitsOrdering() throws {
        let branch = VCBranch(name: "main")
        try databaseManager.insertVCBranch(branch)

        let commit1 = VCCommit(branchId: branch.id, message: "First", timestamp: Date(timeIntervalSince1970: 1000))
        let commit2 = VCCommit(branchId: branch.id, message: "Second", timestamp: Date(timeIntervalSince1970: 2000))
        let commit3 = VCCommit(branchId: branch.id, message: "Third", timestamp: Date(timeIntervalSince1970: 3000))

        try databaseManager.insertVCCommit(commit3)
        try databaseManager.insertVCCommit(commit1)
        try databaseManager.insertVCCommit(commit2)

        let retrieved = try databaseManager.getVCCommits(branchId: branch.id)
        XCTAssertEqual(retrieved.count, 3)
        XCTAssertEqual(retrieved[0].message, "First")
        XCTAssertEqual(retrieved[1].message, "Second")
        XCTAssertEqual(retrieved[2].message, "Third")
    }

    // MARK: - Version Control: Snapshot Tests

    func testInsertAndRetrieveSnapshot() throws {
        let branch = VCBranch(name: "main")
        try databaseManager.insertVCBranch(branch)

        let commit = VCCommit(branchId: branch.id, message: "Commit")
        try databaseManager.insertVCCommit(commit)

        let documentId = UUID()
        let snapshot = VCDocumentSnapshot(
            commitId: commit.id,
            documentId: documentId,
            title: "Test Document",
            content: "Document content",
            category: "novel",
            wordCount: 100
        )

        try databaseManager.insertVCSnapshot(snapshot)

        let retrieved = try databaseManager.getVCSnapshots(commitId: commit.id)
        XCTAssertEqual(retrieved.count, 1)
        XCTAssertEqual(retrieved.first?.id, snapshot.id)
        XCTAssertEqual(retrieved.first?.title, "Test Document")
        XCTAssertEqual(retrieved.first?.content, "Document content")
        XCTAssertEqual(retrieved.first?.wordCount, 100)
    }

    func testGetSnapshotsForDocument() throws {
        let branch = VCBranch(name: "main")
        try databaseManager.insertVCBranch(branch)

        let documentId = UUID()

        for i in 1...3 {
            let commit = VCCommit(branchId: branch.id, message: "Commit \(i)")
            try databaseManager.insertVCCommit(commit)

            let snapshot = VCDocumentSnapshot(
                commitId: commit.id,
                documentId: documentId,
                title: "Version \(i)",
                content: "Content \(i)",
                category: "novel",
                wordCount: i * 100
            )
            try databaseManager.insertVCSnapshot(snapshot)
        }

        let snapshots = try databaseManager.getVCSnapshotsForDocument(documentId: documentId)
        XCTAssertEqual(snapshots.count, 3)
    }

    func testGetSnapshotsAsOf() throws {
        let branch = VCBranch(name: "main")
        try databaseManager.insertVCBranch(branch)

        let doc1 = UUID()
        let doc2 = UUID()

        let commit1 = VCCommit(branchId: branch.id, message: "Commit 1", timestamp: Date(timeIntervalSince1970: 1000))
        try databaseManager.insertVCCommit(commit1)

        let snapshot1 = VCDocumentSnapshot(commitId: commit1.id, documentId: doc1, title: "Doc1 v1", content: "Content 1", category: "novel", wordCount: 100, capturedAt: Date(timeIntervalSince1970: 1000))
        let snapshot2 = VCDocumentSnapshot(commitId: commit1.id, documentId: doc2, title: "Doc2 v1", content: "Content 2", category: "novel", wordCount: 200, capturedAt: Date(timeIntervalSince1970: 1000))
        try databaseManager.insertVCSnapshot(snapshot1)
        try databaseManager.insertVCSnapshot(snapshot2)

        let commit2 = VCCommit(branchId: branch.id, message: "Commit 2", timestamp: Date(timeIntervalSince1970: 2000))
        try databaseManager.insertVCCommit(commit2)

        let snapshot3 = VCDocumentSnapshot(commitId: commit2.id, documentId: doc1, title: "Doc1 v2", content: "Updated content", category: "novel", wordCount: 150, capturedAt: Date(timeIntervalSince1970: 2000))
        try databaseManager.insertVCSnapshot(snapshot3)

        // Query as of time 1500 should return doc1 v1 and doc2 v1
        let snapshotsAsOf = try databaseManager.getVCSnapshotsAsOf(date: Date(timeIntervalSince1970: 1500))
        XCTAssertEqual(snapshotsAsOf.count, 2)

        let doc1Snapshot = snapshotsAsOf.first { $0.documentId == doc1 }
        XCTAssertEqual(doc1Snapshot?.title, "Doc1 v1")

        // Query as of time 2500 should return doc1 v2 and doc2 v1
        let snapshotsAsOf2 = try databaseManager.getVCSnapshotsAsOf(date: Date(timeIntervalSince1970: 2500))
        XCTAssertEqual(snapshotsAsOf2.count, 2)

        let doc1Snapshot2 = snapshotsAsOf2.first { $0.documentId == doc1 }
        XCTAssertEqual(doc1Snapshot2?.title, "Doc1 v2")
    }

    func testMultipleSnapshotsPerCommit() throws {
        let branch = VCBranch(name: "main")
        try databaseManager.insertVCBranch(branch)

        let commit = VCCommit(branchId: branch.id, message: "Commit multiple docs")
        try databaseManager.insertVCCommit(commit)

        for i in 1...5 {
            let snapshot = VCDocumentSnapshot(
                commitId: commit.id,
                documentId: UUID(),
                title: "Document \(i)",
                content: "Content \(i)",
                category: "novel",
                wordCount: i * 100
            )
            try databaseManager.insertVCSnapshot(snapshot)
        }

        let snapshots = try databaseManager.getVCSnapshots(commitId: commit.id)
        XCTAssertEqual(snapshots.count, 5)
    }

    // MARK: - Error Handling Tests

    func testOperationOnUninitializedDatabase() throws {
        let uninitializedDB = DatabaseManager(databasePath: "/tmp/test_uninitialized.db")

        let suggestion = AISuggestion(userId: testUserId, toolUsed: "Test", prompt: "test", response: "test")

        XCTAssertThrowsError(try uninitializedDB.insertAISuggestion(suggestion)) { error in
            XCTAssertTrue(error is DatabaseError)
            if case DatabaseError.notInitialized = error {
                // Expected error
            } else {
                XCTFail("Wrong error type")
            }
        }
    }

    func testInvalidDatabasePath() throws {
        let invalidPath = "/nonexistent/path/to/database.db"
        let invalidDB = DatabaseManager(databasePath: invalidPath)

        XCTAssertThrowsError(try invalidDB.initialize()) { error in
            XCTAssertTrue(error is DatabaseError)
        }
    }

    // MARK: - Boundary and Regression Tests

    func testLargeDataInsertion() throws {
        // Test handling of large text content
        let largeContent = String(repeating: "Lorem ipsum dolor sit amet. ", count: 10000)
        let suggestion = AISuggestion(
            userId: testUserId,
            toolUsed: "Large Test",
            prompt: "Large prompt",
            response: largeContent
        )

        try databaseManager.insertAISuggestion(suggestion)

        let retrieved = try databaseManager.getAISuggestions(userId: testUserId)
        XCTAssertEqual(retrieved.first?.response.count, largeContent.count)
    }

    func testUnicodeAndSpecialCharacters() throws {
        let unicodeContent = "Hello 世界 🌍 émojis and spëcial çharacters"
        let suggestion = AISuggestion(
            userId: testUserId,
            toolUsed: "Unicode Test",
            prompt: unicodeContent,
            response: unicodeContent
        )

        try databaseManager.insertAISuggestion(suggestion)

        let retrieved = try databaseManager.getAISuggestions(userId: testUserId)
        XCTAssertEqual(retrieved.first?.prompt, unicodeContent)
        XCTAssertEqual(retrieved.first?.response, unicodeContent)
    }

    func testEmptyStringFields() throws {
        let suggestion = AISuggestion(
            userId: testUserId,
            toolUsed: "",
            prompt: "",
            response: ""
        )

        try databaseManager.insertAISuggestion(suggestion)

        let retrieved = try databaseManager.getAISuggestions(userId: testUserId)
        XCTAssertEqual(retrieved.first?.toolUsed, "")
        XCTAssertEqual(retrieved.first?.prompt, "")
        XCTAssertEqual(retrieved.first?.response, "")
    }

    func testMultipleUsersIsolation() throws {
        let user1 = UUID()
        let user2 = UUID()

        let suggestion1 = AISuggestion(userId: user1, toolUsed: "Tool 1", prompt: "Prompt 1", response: "Response 1")
        let suggestion2 = AISuggestion(userId: user2, toolUsed: "Tool 2", prompt: "Prompt 2", response: "Response 2")

        try databaseManager.insertAISuggestion(suggestion1)
        try databaseManager.insertAISuggestion(suggestion2)

        let user1Suggestions = try databaseManager.getAISuggestions(userId: user1)
        let user2Suggestions = try databaseManager.getAISuggestions(userId: user2)

        XCTAssertEqual(user1Suggestions.count, 1)
        XCTAssertEqual(user2Suggestions.count, 1)
        XCTAssertEqual(user1Suggestions.first?.toolUsed, "Tool 1")
        XCTAssertEqual(user2Suggestions.first?.toolUsed, "Tool 2")
    }

    func testConcurrentBranchUpdates() throws {
        let branch = VCBranch(name: "test-branch", isActive: false)
        try databaseManager.insertVCBranch(branch)

        var updatedBranch1 = branch
        updatedBranch1.headCommitId = UUID()

        var updatedBranch2 = branch
        updatedBranch2.headCommitId = UUID()

        // Last update should win
        try databaseManager.updateVCBranch(updatedBranch1)
        try databaseManager.updateVCBranch(updatedBranch2)

        let retrieved = try databaseManager.getVCBranch(name: "test-branch")
        XCTAssertEqual(retrieved?.headCommitId, updatedBranch2.headCommitId)
    }

    func testGetSnapshotsAsOfEdgeCases() throws {
        let branch = VCBranch(name: "main")
        try databaseManager.insertVCBranch(branch)

        let doc = UUID()

        // Create snapshots at different times
        let times = [1000.0, 2000.0, 3000.0]
        for (index, time) in times.enumerated() {
            let commit = VCCommit(branchId: branch.id, message: "Commit \(index)", timestamp: Date(timeIntervalSince1970: time))
            try databaseManager.insertVCCommit(commit)

            let snapshot = VCDocumentSnapshot(
                commitId: commit.id,
                documentId: doc,
                title: "Version \(index)",
                content: "Content \(index)",
                category: "novel",
                wordCount: 100,
                capturedAt: Date(timeIntervalSince1970: time)
            )
            try databaseManager.insertVCSnapshot(snapshot)
        }

        // Query at exact timestamp should return that version
        let exactSnapshot = try databaseManager.getVCSnapshotsAsOf(date: Date(timeIntervalSince1970: 2000.0))
        XCTAssertEqual(exactSnapshot.count, 1)
        XCTAssertEqual(exactSnapshot.first?.title, "Version 1")

        // Query between timestamps should return earlier version
        let betweenSnapshot = try databaseManager.getVCSnapshotsAsOf(date: Date(timeIntervalSince1970: 2500.0))
        XCTAssertEqual(betweenSnapshot.count, 1)
        XCTAssertEqual(betweenSnapshot.first?.title, "Version 1")

        // Query before all snapshots should return nothing
        let beforeSnapshot = try databaseManager.getVCSnapshotsAsOf(date: Date(timeIntervalSince1970: 500.0))
        XCTAssertEqual(beforeSnapshot.count, 0)

        // Query after all snapshots should return latest
        let afterSnapshot = try databaseManager.getVCSnapshotsAsOf(date: Date(timeIntervalSince1970: 5000.0))
        XCTAssertEqual(afterSnapshot.count, 1)
        XCTAssertEqual(afterSnapshot.first?.title, "Version 2")
    }

    func testIssueTagsWithEmptyArray() throws {
        let documentId = UUID()
        var issue = Issue(documentId: documentId, title: "No tags issue")
        issue.metadata.tags = []

        try databaseManager.insertIssue(issue)

        let retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(retrieved.first?.metadata.tags.count, 0)
    }

    func testTraceAndObservationChaining() throws {
        // Test that observations correctly link to traces
        let trace = Trace(sessionId: "session-1", name: "parent-trace")
        try databaseManager.insertTrace(trace)

        for i in 1...5 {
            let observation = Observation(
                traceId: trace.id,
                name: "obs-\(i)",
                startTime: Date(timeIntervalSince1970: Double(i * 1000))
            )
            try databaseManager.insertObservation(observation)
        }

        let observations = try databaseManager.getObservations(traceId: trace.id)
        XCTAssertEqual(observations.count, 5)
        XCTAssertTrue(observations.allSatisfy { $0.traceId == trace.id })

        // Verify observations are ordered by start time
        for i in 0..<observations.count-1 {
            XCTAssertLessThan(observations[i].startTime, observations[i+1].startTime)
        }
    }

    func testDatabaseReinitializationAfterClose() throws {
        databaseManager.close()

        XCTAssertThrowsError(try databaseManager.insertAISuggestion(AISuggestion(userId: testUserId, toolUsed: "Test", prompt: "test", response: "test"))) { error in
            XCTAssertTrue(error is DatabaseError)
        }

        // Reinitialize
        try databaseManager.initialize()

        // Should work now
        let suggestion = AISuggestion(userId: testUserId, toolUsed: "Test", prompt: "test", response: "test")
        XCTAssertNoThrow(try databaseManager.insertAISuggestion(suggestion))
    }
}