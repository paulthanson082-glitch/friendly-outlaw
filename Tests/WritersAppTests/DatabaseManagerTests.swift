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
            name: "test_interaction",
            startTime: Date(),
            metadata: "{\"key\":\"value\"}"
        )

        try databaseManager.insertTrace(trace)

        let retrieved = try databaseManager.getTraces()
        XCTAssertEqual(retrieved.count, 1)
        XCTAssertEqual(retrieved.first?.id, trace.id)
        XCTAssertEqual(retrieved.first?.sessionId, "session-123")
        XCTAssertEqual(retrieved.first?.name, "test_interaction")
    }

    func testRetrieveTracesBySessionId() throws {
        let trace1 = Trace(sessionId: "session-A", name: "trace1")
        let trace2 = Trace(sessionId: "session-B", name: "trace2")
        let trace3 = Trace(sessionId: "session-A", name: "trace3")

        try databaseManager.insertTrace(trace1)
        try databaseManager.insertTrace(trace2)
        try databaseManager.insertTrace(trace3)

        let sessionATraces = try databaseManager.getTraces(sessionId: "session-A")
        XCTAssertEqual(sessionATraces.count, 2)
        XCTAssertTrue(sessionATraces.allSatisfy { $0.sessionId == "session-A" })

        let sessionBTraces = try databaseManager.getTraces(sessionId: "session-B")
        XCTAssertEqual(sessionBTraces.count, 1)
        XCTAssertEqual(sessionBTraces.first?.sessionId, "session-B")
    }

    func testTraceWithEndTime() throws {
        var trace = Trace(
            sessionId: "session-456",
            name: "completed_trace",
            startTime: Date()
        )
        trace.endTime = Date().addingTimeInterval(300)

        try databaseManager.insertTrace(trace)

        let retrieved = try databaseManager.getTraces()
        XCTAssertNotNil(retrieved.first?.endTime)
    }

    func testTraceOrderedByStartTime() throws {
        let trace1 = Trace(sessionId: "session-1", name: "first", startTime: Date(timeIntervalSince1970: 1000))
        let trace2 = Trace(sessionId: "session-1", name: "second", startTime: Date(timeIntervalSince1970: 2000))
        let trace3 = Trace(sessionId: "session-1", name: "third", startTime: Date(timeIntervalSince1970: 1500))

        try databaseManager.insertTrace(trace1)
        try databaseManager.insertTrace(trace2)
        try databaseManager.insertTrace(trace3)

        let traces = try databaseManager.getTraces(sessionId: "session-1")
        XCTAssertEqual(traces.count, 3)
        XCTAssertEqual(traces[0].name, "first")
        XCTAssertEqual(traces[1].name, "third")
        XCTAssertEqual(traces[2].name, "second")
    }

    // MARK: - Observation Tests

    func testInsertAndRetrieveObservation() throws {
        let trace = Trace(sessionId: "session-789", name: "parent_trace")
        try databaseManager.insertTrace(trace)

        let observation = Observation(
            traceId: trace.id,
            name: "tool_call",
            startTime: Date(),
            input: "input data",
            output: "output data",
            statusMessage: "success"
        )

        try databaseManager.insertObservation(observation)

        let retrieved = try databaseManager.getObservations(traceId: trace.id)
        XCTAssertEqual(retrieved.count, 1)
        XCTAssertEqual(retrieved.first?.id, observation.id)
        XCTAssertEqual(retrieved.first?.name, "tool_call")
        XCTAssertEqual(retrieved.first?.input, "input data")
        XCTAssertEqual(retrieved.first?.output, "output data")
    }

    func testMultipleObservationsForTrace() throws {
        let trace = Trace(sessionId: "session-multi", name: "trace_with_observations")
        try databaseManager.insertTrace(trace)

        let obs1 = Observation(traceId: trace.id, name: "read_file", startTime: Date(timeIntervalSince1970: 1000))
        let obs2 = Observation(traceId: trace.id, name: "edit_file", startTime: Date(timeIntervalSince1970: 2000))
        let obs3 = Observation(traceId: trace.id, name: "write_file", startTime: Date(timeIntervalSince1970: 1500))

        try databaseManager.insertObservation(obs1)
        try databaseManager.insertObservation(obs2)
        try databaseManager.insertObservation(obs3)

        let observations = try databaseManager.getObservations(traceId: trace.id)
        XCTAssertEqual(observations.count, 3)
        XCTAssertEqual(observations[0].name, "read_file")
        XCTAssertEqual(observations[1].name, "write_file")
        XCTAssertEqual(observations[2].name, "edit_file")
    }

    func testObservationWithNullFields() throws {
        let trace = Trace(sessionId: "session-nulls", name: "trace")
        try databaseManager.insertTrace(trace)

        let observation = Observation(
            traceId: trace.id,
            name: "minimal_observation",
            startTime: Date()
        )

        try databaseManager.insertObservation(observation)

        let retrieved = try databaseManager.getObservations(traceId: trace.id)
        XCTAssertEqual(retrieved.count, 1)
        XCTAssertNil(retrieved.first?.endTime)
        XCTAssertNil(retrieved.first?.input)
        XCTAssertNil(retrieved.first?.output)
        XCTAssertNil(retrieved.first?.statusMessage)
    }

    func testObservationsForeignKeyConstraint() throws {
        let observation = Observation(
            traceId: UUID(),
            name: "orphan_observation"
        )

        // This should work even without a parent trace (SQLite doesn't enforce FK by default)
        // But the relationship is documented
        try databaseManager.insertObservation(observation)

        let retrieved = try databaseManager.getObservations(traceId: observation.traceId)
        XCTAssertEqual(retrieved.count, 1)
    }

    // MARK: - Issue Tests

    func testInsertAndRetrieveIssue() throws {
        let documentId = UUID()
        let issue = Issue(
            documentId: documentId,
            title: "Fix plot hole",
            description: "Character motivation unclear",
            status: .open,
            priority: .high
        )

        try databaseManager.insertIssue(issue)

        let retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(retrieved.count, 1)
        XCTAssertEqual(retrieved.first?.title, "Fix plot hole")
        XCTAssertEqual(retrieved.first?.status, .open)
        XCTAssertEqual(retrieved.first?.priority, .high)
    }

    func testUpdateIssue() throws {
        let documentId = UUID()
        var issue = Issue(
            documentId: documentId,
            title: "Original title",
            description: "Original description",
            status: .open,
            priority: .low
        )

        try databaseManager.insertIssue(issue)

        issue.title = "Updated title"
        issue.description = "Updated description"
        issue.status = .resolved
        issue.priority = .high
        issue.metadata.modified = Date()
        issue.metadata.resolvedAt = Date()

        try databaseManager.updateIssue(issue)

        let retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(retrieved.first?.title, "Updated title")
        XCTAssertEqual(retrieved.first?.description, "Updated description")
        XCTAssertEqual(retrieved.first?.status, .resolved)
        XCTAssertEqual(retrieved.first?.priority, .high)
        XCTAssertNotNil(retrieved.first?.metadata.resolvedAt)
    }

    func testDeleteIssue() throws {
        let documentId = UUID()
        let issue = Issue(
            documentId: documentId,
            title: "Temporary issue",
            status: .open,
            priority: .medium
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

        let issue1 = Issue(documentId: documentId, title: "Open issue 1", status: .open, priority: .low)
        let issue2 = Issue(documentId: documentId, title: "Open issue 2", status: .open, priority: .medium)
        let issue3 = Issue(documentId: documentId, title: "Resolved issue", status: .resolved, priority: .high)
        let issue4 = Issue(documentId: documentId, title: "In Progress issue", status: .inProgress, priority: .critical)

        try databaseManager.insertIssue(issue1)
        try databaseManager.insertIssue(issue2)
        try databaseManager.insertIssue(issue3)
        try databaseManager.insertIssue(issue4)

        let openIssues = try databaseManager.getIssues(withStatus: .open)
        XCTAssertEqual(openIssues.count, 2)
        XCTAssertTrue(openIssues.allSatisfy { $0.status == .open })

        let resolvedIssues = try databaseManager.getIssues(withStatus: .resolved)
        XCTAssertEqual(resolvedIssues.count, 1)
        XCTAssertEqual(resolvedIssues.first?.title, "Resolved issue")
    }

    func testGetAllIssues() throws {
        let doc1 = UUID()
        let doc2 = UUID()

        try databaseManager.insertIssue(Issue(documentId: doc1, title: "Issue 1", status: .open, priority: .low))
        try databaseManager.insertIssue(Issue(documentId: doc2, title: "Issue 2", status: .resolved, priority: .medium))
        try databaseManager.insertIssue(Issue(documentId: doc1, title: "Issue 3", status: .closed, priority: .high))

        let allIssues = try databaseManager.getAllIssues()
        XCTAssertEqual(allIssues.count, 3)
    }

    func testIssuesOrderedByCreated() throws {
        let documentId = UUID()

        let issue1 = Issue(documentId: documentId, title: "First", status: .open, priority: .low)
        Thread.sleep(forTimeInterval: 0.01)
        let issue2 = Issue(documentId: documentId, title: "Second", status: .open, priority: .low)
        Thread.sleep(forTimeInterval: 0.01)
        let issue3 = Issue(documentId: documentId, title: "Third", status: .open, priority: .low)

        try databaseManager.insertIssue(issue1)
        try databaseManager.insertIssue(issue2)
        try databaseManager.insertIssue(issue3)

        let retrieved = try databaseManager.getIssues(forDocument: documentId)
        // Should be ordered by created DESC (newest first)
        XCTAssertEqual(retrieved[0].title, "Third")
        XCTAssertEqual(retrieved[1].title, "Second")
        XCTAssertEqual(retrieved[2].title, "First")
    }

    func testIssuePaginationForDocument() throws {
        let documentId = UUID()

        for i in 1...10 {
            let issue = Issue(documentId: documentId, title: "Issue \(i)", status: .open, priority: .low)
            try databaseManager.insertIssue(issue)
        }

        let firstPage = try databaseManager.getIssues(forDocument: documentId, limit: 3, offset: 0)
        XCTAssertEqual(firstPage.count, 3)

        let secondPage = try databaseManager.getIssues(forDocument: documentId, limit: 3, offset: 3)
        XCTAssertEqual(secondPage.count, 3)

        let thirdPage = try databaseManager.getIssues(forDocument: documentId, limit: 3, offset: 6)
        XCTAssertEqual(thirdPage.count, 3)

        let fourthPage = try databaseManager.getIssues(forDocument: documentId, limit: 3, offset: 9)
        XCTAssertEqual(fourthPage.count, 1)
    }

    func testIssuePaginationForStatus() throws {
        let documentId = UUID()

        for i in 1...12 {
            let status: IssueStatus = i % 2 == 0 ? .open : .resolved
            let issue = Issue(documentId: documentId, title: "Issue \(i)", status: status, priority: .low)
            try databaseManager.insertIssue(issue)
        }

        let openIssues = try databaseManager.getIssues(withStatus: .open, limit: 10, offset: 0)
        XCTAssertEqual(openIssues.count, 6)
    }

    func testIssueWithTags() throws {
        let documentId = UUID()
        var issue = Issue(
            documentId: documentId,
            title: "Tagged issue",
            status: .open,
            priority: .medium
        )
        issue.metadata.tags = ["bug", "urgent", "chapter-5"]
        issue.metadata.notes = "Need to address this before publication"

        try databaseManager.insertIssue(issue)

        let retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(retrieved.first?.metadata.tags.count, 3)
        XCTAssertTrue(retrieved.first?.metadata.tags.contains("bug") ?? false)
        XCTAssertEqual(retrieved.first?.metadata.notes, "Need to address this before publication")
    }

    func testIssueWithEmptyTags() throws {
        let documentId = UUID()
        let issue = Issue(
            documentId: documentId,
            title: "No tags",
            status: .open,
            priority: .low
        )

        try databaseManager.insertIssue(issue)

        let retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(retrieved.first?.metadata.tags.count, 0)
    }

    // MARK: - Error Handling Tests

    func testOperationsFailWhenNotInitialized() throws {
        let uninitializedDb = DatabaseManager(databasePath: "/tmp/never_initialized.db")

        let suggestion = AISuggestion(userId: testUserId, toolUsed: "test", prompt: "test", response: "test")

        XCTAssertThrowsError(try uninitializedDb.insertAISuggestion(suggestion)) { error in
            XCTAssertTrue(error is DatabaseError)
            if case DatabaseError.notInitialized = error {
                // Expected
            } else {
                XCTFail("Expected notInitialized error")
            }
        }

        XCTAssertThrowsError(try uninitializedDb.getAISuggestions(userId: testUserId)) { error in
            XCTAssertTrue(error is DatabaseError)
        }
    }

    func testInvalidDatabasePath() throws {
        let invalidDb = DatabaseManager(databasePath: "/invalid/path/that/does/not/exist/db.sqlite")

        XCTAssertThrowsError(try invalidDb.initialize()) { error in
            XCTAssertTrue(error is DatabaseError)
            if case DatabaseError.connectionFailed = error {
                // Expected
            } else {
                XCTFail("Expected connectionFailed error")
            }
        }
    }

    func testSessionStatsWithNoSessions() throws {
        let stats = try databaseManager.getSessionStats(userId: testUserId)

        XCTAssertEqual(stats.totalSessions, 0)
        XCTAssertEqual(stats.totalDurationSeconds, 0)
        XCTAssertEqual(stats.averageDurationSeconds, 0.0)
        XCTAssertNil(stats.earliestSession)
        XCTAssertNil(stats.latestSession)
    }

    func testGetObservationsForNonexistentTrace() throws {
        let observations = try databaseManager.getObservations(traceId: UUID())
        XCTAssertEqual(observations.count, 0)
    }

    func testGetTracesForNonexistentSession() throws {
        let traces = try databaseManager.getTraces(sessionId: "nonexistent-session")
        XCTAssertEqual(traces.count, 0)
    }

    func testGetIssuesForNonexistentDocument() throws {
        let issues = try databaseManager.getIssues(forDocument: UUID())
        XCTAssertEqual(issues.count, 0)
    }

    // MARK: - Edge Case and Boundary Tests

    func testAISuggestionWithDocumentId() throws {
        let documentId = UUID()
        let suggestion = AISuggestion(
            userId: testUserId,
            documentId: documentId,
            toolUsed: "Continue Writing",
            prompt: "Test",
            response: "Response"
        )

        try databaseManager.insertAISuggestion(suggestion)

        let retrieved = try databaseManager.getAISuggestions(userId: testUserId)
        XCTAssertEqual(retrieved.first?.documentId, documentId)
    }

    func testAISuggestionWithoutDocumentId() throws {
        let suggestion = AISuggestion(
            userId: testUserId,
            documentId: nil,
            toolUsed: "Brainstorm",
            prompt: "Test",
            response: "Response"
        )

        try databaseManager.insertAISuggestion(suggestion)

        let retrieved = try databaseManager.getAISuggestions(userId: testUserId)
        XCTAssertNil(retrieved.first?.documentId)
    }

    func testMultipleUsersIsolation() throws {
        let user1 = UUID()
        let user2 = UUID()

        let suggestion1 = AISuggestion(userId: user1, toolUsed: "Tool1", prompt: "p1", response: "r1")
        let suggestion2 = AISuggestion(userId: user2, toolUsed: "Tool2", prompt: "p2", response: "r2")

        try databaseManager.insertAISuggestion(suggestion1)
        try databaseManager.insertAISuggestion(suggestion2)

        let user1Suggestions = try databaseManager.getAISuggestions(userId: user1)
        let user2Suggestions = try databaseManager.getAISuggestions(userId: user2)

        XCTAssertEqual(user1Suggestions.count, 1)
        XCTAssertEqual(user2Suggestions.count, 1)
        XCTAssertEqual(user1Suggestions.first?.toolUsed, "Tool1")
        XCTAssertEqual(user2Suggestions.first?.toolUsed, "Tool2")
    }

    func testUserSessionsMultipleUsersIsolation() throws {
        let user1 = UUID()
        let user2 = UUID()

        try databaseManager.insertUserSession(UserSession(userId: user1, wordsWritten: 100))
        try databaseManager.insertUserSession(UserSession(userId: user2, wordsWritten: 200))

        let user1Sessions = try databaseManager.getUserSessions(userId: user1)
        let user2Sessions = try databaseManager.getUserSessions(userId: user2)

        XCTAssertEqual(user1Sessions.count, 1)
        XCTAssertEqual(user2Sessions.count, 1)
        XCTAssertEqual(user1Sessions.first?.wordsWritten, 100)
        XCTAssertEqual(user2Sessions.first?.wordsWritten, 200)
    }

    func testAIConfigurationMultipleUsers() throws {
        let user1 = UUID()
        let user2 = UUID()

        let config1 = AIConfiguration(apiKey: "key1", model: .claude35Sonnet)
        let config2 = AIConfiguration(apiKey: "key2", model: .claude3Opus)

        try databaseManager.saveAIConfiguration(userId: user1, configuration: config1)
        try databaseManager.saveAIConfiguration(userId: user2, configuration: config2)

        let retrieved1 = try databaseManager.getAIConfiguration(userId: user1)
        let retrieved2 = try databaseManager.getAIConfiguration(userId: user2)

        XCTAssertEqual(retrieved1?.apiKey, "key1")
        XCTAssertEqual(retrieved2?.apiKey, "key2")
        XCTAssertEqual(retrieved1?.model, .claude35Sonnet)
        XCTAssertEqual(retrieved2?.model, .claude3Opus)
    }

    func testPaginationBeyondAvailableData() throws {
        for i in 1...5 {
            let suggestion = AISuggestion(userId: testUserId, toolUsed: "Tool\(i)", prompt: "p", response: "r")
            try databaseManager.insertAISuggestion(suggestion)
        }

        let page = try databaseManager.getAISuggestions(userId: testUserId, limit: 10, offset: 10)
        XCTAssertEqual(page.count, 0)
    }

    func testPaginationWithZeroLimit() throws {
        for i in 1...5 {
            let suggestion = AISuggestion(userId: testUserId, toolUsed: "Tool\(i)", prompt: "p", response: "r")
            try databaseManager.insertAISuggestion(suggestion)
        }

        let page = try databaseManager.getAISuggestions(userId: testUserId, limit: 0, offset: 0)
        XCTAssertEqual(page.count, 0)
    }

    func testLargeDataSetRetrieval() throws {
        for i in 1...100 {
            let suggestion = AISuggestion(
                userId: testUserId,
                toolUsed: "Tool\(i % 5)",
                prompt: "Prompt \(i)",
                response: "Response \(i)"
            )
            try databaseManager.insertAISuggestion(suggestion)
        }

        let all = try databaseManager.getAISuggestions(userId: testUserId, limit: 100, offset: 0)
        XCTAssertEqual(all.count, 100)

        let stats = try databaseManager.getAIToolUsageStats(userId: testUserId)
        XCTAssertEqual(stats.count, 5)
    }

    func testSessionWithAllNullOptionals() throws {
        let session = UserSession(
            userId: testUserId,
            startTime: Date(),
            endTime: nil,
            durationSeconds: nil,
            wordsWritten: 0,
            aiInteractions: 0,
            multitaskingMode: nil
        )

        try databaseManager.insertUserSession(session)

        let retrieved = try databaseManager.getUserSessions(userId: testUserId)
        XCTAssertEqual(retrieved.count, 1)
        XCTAssertNil(retrieved.first?.endTime)
        XCTAssertNil(retrieved.first?.durationSeconds)
        XCTAssertNil(retrieved.first?.multitaskingMode)
    }

    func testTraceWithMinimalData() throws {
        let trace = Trace(sessionId: "minimal", name: "trace")

        try databaseManager.insertTrace(trace)

        let retrieved = try databaseManager.getTraces()
        XCTAssertEqual(retrieved.count, 1)
        XCTAssertNil(retrieved.first?.endTime)
        XCTAssertNil(retrieved.first?.metadata)
    }

    func testTraceWithLargeMetadata() throws {
        let largeMetadata = String(repeating: "x", count: 10000)
        let trace = Trace(
            sessionId: "session-large",
            name: "trace",
            startTime: Date(),
            metadata: largeMetadata
        )

        try databaseManager.insertTrace(trace)

        let retrieved = try databaseManager.getTraces()
        XCTAssertEqual(retrieved.first?.metadata?.count, 10000)
    }

    func testObservationWithLargeInputOutput() throws {
        let trace = Trace(sessionId: "session-io", name: "trace")
        try databaseManager.insertTrace(trace)

        let largeInput = String(repeating: "input", count: 1000)
        let largeOutput = String(repeating: "output", count: 1000)

        let observation = Observation(
            traceId: trace.id,
            name: "large_data",
            startTime: Date(),
            input: largeInput,
            output: largeOutput
        )

        try databaseManager.insertObservation(observation)

        let retrieved = try databaseManager.getObservations(traceId: trace.id)
        XCTAssertEqual(retrieved.first?.input?.count, 5000)
        XCTAssertEqual(retrieved.first?.output?.count, 6000)
    }

    func testIssueWithLongDescription() throws {
        let documentId = UUID()
        let longDescription = String(repeating: "This is a very long description. ", count: 100)

        let issue = Issue(
            documentId: documentId,
            title: "Issue with long description",
            description: longDescription,
            status: .open,
            priority: .medium
        )

        try databaseManager.insertIssue(issue)

        let retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(retrieved.first?.description.count, longDescription.count)
    }

    func testIssueWithManyTags() throws {
        let documentId = UUID()
        var issue = Issue(
            documentId: documentId,
            title: "Tagged issue",
            status: .open,
            priority: .low
        )

        issue.metadata.tags = (1...50).map { "tag\($0)" }

        try databaseManager.insertIssue(issue)

        let retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(retrieved.first?.metadata.tags.count, 50)
    }

    func testFilterByNonexistentTool() throws {
        let suggestion = AISuggestion(userId: testUserId, toolUsed: "RealTool", prompt: "p", response: "r")
        try databaseManager.insertAISuggestion(suggestion)

        let filtered = try databaseManager.filterAISuggestionsByTool(userId: testUserId, tool: "FakeTool")
        XCTAssertEqual(filtered.count, 0)
    }

    func testFilterByNonexistentMode() throws {
        let session = UserSession(userId: testUserId, multitaskingMode: "Split View")
        try databaseManager.insertUserSession(session)

        let filtered = try databaseManager.filterSessionsByMode(userId: testUserId, mode: "Nonexistent Mode")
        XCTAssertEqual(filtered.count, 0)
    }

    func testGetAIConfigurationForNonexistentUser() throws {
        let config = try databaseManager.getAIConfiguration(userId: UUID())
        XCTAssertNil(config)
    }

    func testUpdateNonexistentAISuggestion() throws {
        let suggestion = AISuggestion(
            id: UUID(),
            userId: testUserId,
            toolUsed: "Tool",
            prompt: "p",
            response: "r"
        )

        // Should not throw, just update nothing
        try databaseManager.updateAISuggestion(suggestion)

        let retrieved = try databaseManager.getAISuggestions(userId: testUserId)
        XCTAssertEqual(retrieved.count, 0)
    }

    func testDeleteNonexistentAISuggestion() throws {
        // Should not throw, just delete nothing
        try databaseManager.deleteAISuggestion(id: UUID())

        let retrieved = try databaseManager.getAISuggestions(userId: testUserId)
        XCTAssertEqual(retrieved.count, 0)
    }

    func testDeleteNonexistentIssue() throws {
        // Should not throw, just delete nothing
        try databaseManager.deleteIssue(id: UUID())

        let issues = try databaseManager.getAllIssues()
        XCTAssertEqual(issues.count, 0)
    }

    func testSpecialCharactersInStrings() throws {
        let specialChars = "Test with special chars: 'single', \"double\", `backtick`, and \\ backslash"

        let suggestion = AISuggestion(
            userId: testUserId,
            toolUsed: specialChars,
            prompt: specialChars,
            response: specialChars
        )

        try databaseManager.insertAISuggestion(suggestion)

        let retrieved = try databaseManager.getAISuggestions(userId: testUserId)
        XCTAssertEqual(retrieved.first?.toolUsed, specialChars)
        XCTAssertEqual(retrieved.first?.prompt, specialChars)
        XCTAssertEqual(retrieved.first?.response, specialChars)
    }

    func testUnicodeCharactersInStrings() throws {
        let unicode = "Unicode: 你好 🌍 مرحبا Здравствуйте"

        let issue = Issue(
            documentId: UUID(),
            title: unicode,
            description: unicode,
            status: .open,
            priority: .medium
        )

        try databaseManager.insertIssue(issue)

        let retrieved = try databaseManager.getAllIssues()
        XCTAssertEqual(retrieved.first?.title, unicode)
        XCTAssertEqual(retrieved.first?.description, unicode)
    }

    func testEmptyStringHandling() throws {
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

    func testTraceSessionIdEmptyString() throws {
        let trace = Trace(sessionId: "", name: "empty_session_trace")
        try databaseManager.insertTrace(trace)

        let retrieved = try databaseManager.getTraces(sessionId: "")
        XCTAssertEqual(retrieved.count, 1)
        XCTAssertEqual(retrieved.first?.sessionId, "")
    }

    func testAllIssuesPaginationEdgeCases() throws {
        // Insert exactly 50 issues
        for i in 1...50 {
            let issue = Issue(documentId: UUID(), title: "Issue \(i)", status: .open, priority: .low)
            try databaseManager.insertIssue(issue)
        }

        // Get all with default limit
        let page1 = try databaseManager.getAllIssues(limit: 50, offset: 0)
        XCTAssertEqual(page1.count, 50)

        // Get with offset at boundary
        let page2 = try databaseManager.getAllIssues(limit: 50, offset: 50)
        XCTAssertEqual(page2.count, 0)

        // Get with offset just before boundary
        let page3 = try databaseManager.getAllIssues(limit: 10, offset: 45)
        XCTAssertEqual(page3.count, 5)
    }

    func testGetIssuesByStatusPaginationEdgeCases() throws {
        for i in 1...25 {
            let issue = Issue(documentId: UUID(), title: "Open \(i)", status: .open, priority: .low)
            try databaseManager.insertIssue(issue)
        }

        let page1 = try databaseManager.getIssues(withStatus: .open, limit: 20, offset: 0)
        XCTAssertEqual(page1.count, 20)

        let page2 = try databaseManager.getIssues(withStatus: .open, limit: 20, offset: 20)
        XCTAssertEqual(page2.count, 5)
    }

    func testConcurrentUsersSessions() throws {
        let users = (1...10).map { _ in UUID() }

        for user in users {
            let session = UserSession(userId: user, wordsWritten: 100)
            try databaseManager.insertUserSession(session)
        }

        for user in users {
            let sessions = try databaseManager.getUserSessions(userId: user)
            XCTAssertEqual(sessions.count, 1)
            XCTAssertEqual(sessions.first?.userId, user)
        }
    }

    func testDatePrecisionInStorage() throws {
        let preciseDate = Date(timeIntervalSince1970: 1234567890.123456)

        let session = UserSession(
            userId: testUserId,
            startTime: preciseDate
        )

        try databaseManager.insertUserSession(session)

        let retrieved = try databaseManager.getUserSessions(userId: testUserId)
        let difference = abs(retrieved.first!.startTime.timeIntervalSince1970 - preciseDate.timeIntervalSince1970)
        XCTAssertLessThan(difference, 0.001) // Within 1ms
    }

    func testIssueStatusEnumRoundTrip() throws {
        let documentId = UUID()
        let statuses: [IssueStatus] = [.open, .inProgress, .resolved, .closed]

        for status in statuses {
            let issue = Issue(
                documentId: documentId,
                title: "Status \(status.rawValue)",
                status: status,
                priority: .medium
            )
            try databaseManager.insertIssue(issue)
        }

        let retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(retrieved.count, 4)

        let retrievedStatuses = Set(retrieved.map { $0.status })
        XCTAssertEqual(retrievedStatuses.count, 4)
        XCTAssertTrue(retrievedStatuses.contains(.open))
        XCTAssertTrue(retrievedStatuses.contains(.inProgress))
        XCTAssertTrue(retrievedStatuses.contains(.resolved))
        XCTAssertTrue(retrievedStatuses.contains(.closed))
    }

    func testIssuePriorityEnumRoundTrip() throws {
        let documentId = UUID()
        let priorities: [IssuePriority] = [.low, .medium, .high, .critical]

        for priority in priorities {
            let issue = Issue(
                documentId: documentId,
                title: "Priority \(priority.rawValue)",
                status: .open,
                priority: priority
            )
            try databaseManager.insertIssue(issue)
        }

        let retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(retrieved.count, 4)

        let retrievedPriorities = Set(retrieved.map { $0.priority })
        XCTAssertEqual(retrievedPriorities.count, 4)
    }

    func testAIModelEnumRoundTrip() throws {
        let models: [AIModel] = [.claude3Opus, .claude3Sonnet, .claude35Sonnet, .claudeInstant]

        for (index, model) in models.enumerated() {
            let userId = UUID()
            let config = AIConfiguration(
                apiKey: "key\(index)",
                model: model,
                maxTokens: 4096,
                temperature: 0.7
            )
            try databaseManager.saveAIConfiguration(userId: userId, configuration: config)

            let retrieved = try databaseManager.getAIConfiguration(userId: userId)
            XCTAssertEqual(retrieved?.model, model)
        }
    }

    func testMultipleClosesDoNotCrash() throws {
        databaseManager.close()
        databaseManager.close()
        databaseManager.close()
        // Should not crash
    }

    func testReinitializeAfterClose() throws {
        try databaseManager.initialize()

        let suggestion = AISuggestion(userId: testUserId, toolUsed: "Tool", prompt: "p", response: "r")
        try databaseManager.insertAISuggestion(suggestion)

        databaseManager.close()

        try databaseManager.initialize()

        // Data should still be there
        let retrieved = try databaseManager.getAISuggestions(userId: testUserId)
        XCTAssertEqual(retrieved.count, 1)
    }

    func testIndexesAreCreated() throws {
        // Indexes should improve query performance
        // This test just verifies initialization doesn't fail with indexes
        let newDb = DatabaseManager(databasePath: "/tmp/test_indexes_\(UUID().uuidString).db")
        try newDb.initialize()

        // Insert data to ensure indexes work
        let suggestion = AISuggestion(userId: testUserId, toolUsed: "Tool", prompt: "p", response: "r")
        try newDb.insertAISuggestion(suggestion)

        let retrieved = try newDb.getAISuggestions(userId: testUserId)
        XCTAssertEqual(retrieved.count, 1)

        newDb.close()
    }

    func testSessionStatsWithOnlyNullDurations() throws {
        try databaseManager.insertUserSession(UserSession(userId: testUserId, durationSeconds: nil))
        try databaseManager.insertUserSession(UserSession(userId: testUserId, durationSeconds: nil))

        let stats = try databaseManager.getSessionStats(userId: testUserId)

        // Should only count sessions with non-null durations
        XCTAssertEqual(stats.totalSessions, 0)
        XCTAssertEqual(stats.totalDurationSeconds, 0)
    }

    func testSessionStatsWithMixedNullDurations() throws {
        try databaseManager.insertUserSession(UserSession(userId: testUserId, durationSeconds: 1000))
        try databaseManager.insertUserSession(UserSession(userId: testUserId, durationSeconds: nil))
        try databaseManager.insertUserSession(UserSession(userId: testUserId, durationSeconds: 2000))

        let stats = try databaseManager.getSessionStats(userId: testUserId)

        XCTAssertEqual(stats.totalSessions, 2)
        XCTAssertEqual(stats.totalDurationSeconds, 3000)
        XCTAssertEqual(stats.averageDurationSeconds, 1500.0)
    }

    // MARK: - Additional Regression and Boundary Tests

    func testAISuggestionWithVeryLongPrompt() throws {
        let longPrompt = String(repeating: "This is a very long prompt. ", count: 1000)
        let suggestion = AISuggestion(
            userId: testUserId,
            toolUsed: "Continue Writing",
            prompt: longPrompt,
            response: "Response"
        )

        try databaseManager.insertAISuggestion(suggestion)

        let retrieved = try databaseManager.getAISuggestions(userId: testUserId)
        XCTAssertEqual(retrieved.first?.prompt.count, longPrompt.count)
    }

    func testAISuggestionWithVeryLongResponse() throws {
        let longResponse = String(repeating: "This is a very long response. ", count: 2000)
        let suggestion = AISuggestion(
            userId: testUserId,
            toolUsed: "Improve Text",
            prompt: "Short prompt",
            response: longResponse
        )

        try databaseManager.insertAISuggestion(suggestion)

        let retrieved = try databaseManager.getAISuggestions(userId: testUserId)
        XCTAssertEqual(retrieved.first?.response.count, longResponse.count)
    }

    func testUpdateAISuggestionChangesResponse() throws {
        var suggestion = AISuggestion(
            userId: testUserId,
            toolUsed: "Grammar Check",
            prompt: "Check this",
            response: "Original"
        )

        try databaseManager.insertAISuggestion(suggestion)

        suggestion.response = "Updated response with new content"
        try databaseManager.updateAISuggestion(suggestion)

        let retrieved = try databaseManager.getAISuggestions(userId: testUserId)
        XCTAssertEqual(retrieved.first?.response, "Updated response with new content")
    }

    func testGetAISuggestionsOrderedByTimestampDescending() throws {
        let suggestion1 = AISuggestion(userId: testUserId, toolUsed: "T1", prompt: "p", response: "r")
        Thread.sleep(forTimeInterval: 0.01)
        let suggestion2 = AISuggestion(userId: testUserId, toolUsed: "T2", prompt: "p", response: "r")
        Thread.sleep(forTimeInterval: 0.01)
        let suggestion3 = AISuggestion(userId: testUserId, toolUsed: "T3", prompt: "p", response: "r")

        try databaseManager.insertAISuggestion(suggestion1)
        try databaseManager.insertAISuggestion(suggestion2)
        try databaseManager.insertAISuggestion(suggestion3)

        let retrieved = try databaseManager.getAISuggestions(userId: testUserId)

        XCTAssertEqual(retrieved[0].toolUsed, "T3")
        XCTAssertEqual(retrieved[1].toolUsed, "T2")
        XCTAssertEqual(retrieved[2].toolUsed, "T1")
    }

    func testGetAISuggestionsWithConfigWhenNoConfigExists() throws {
        let suggestion = AISuggestion(userId: testUserId, toolUsed: "Tool", prompt: "p", response: "r")
        try databaseManager.insertAISuggestion(suggestion)

        let joined = try databaseManager.getAISuggestionsWithConfig(userId: testUserId)

        XCTAssertEqual(joined.count, 1)
        XCTAssertEqual(joined.first?.modelUsed, "unknown")
    }

    func testFilterAISuggestionsByToolOrderedByTimestamp() throws {
        let tool = "Continue Writing"

        try databaseManager.insertAISuggestion(AISuggestion(userId: testUserId, toolUsed: tool, prompt: "p1", response: "r1"))
        Thread.sleep(forTimeInterval: 0.01)
        try databaseManager.insertAISuggestion(AISuggestion(userId: testUserId, toolUsed: "Other", prompt: "p2", response: "r2"))
        Thread.sleep(forTimeInterval: 0.01)
        try databaseManager.insertAISuggestion(AISuggestion(userId: testUserId, toolUsed: tool, prompt: "p3", response: "r3"))

        let filtered = try databaseManager.filterAISuggestionsByTool(userId: testUserId, tool: tool)

        XCTAssertEqual(filtered.count, 2)
        XCTAssertEqual(filtered[0].prompt, "p3")
        XCTAssertEqual(filtered[1].prompt, "p1")
    }

    func testAIToolUsageStatsLastUsedTimestamp() throws {
        Thread.sleep(forTimeInterval: 0.01)
        try databaseManager.insertAISuggestion(AISuggestion(userId: testUserId, toolUsed: "Tool1", prompt: "p", response: "r"))
        Thread.sleep(forTimeInterval: 0.02)
        try databaseManager.insertAISuggestion(AISuggestion(userId: testUserId, toolUsed: "Tool1", prompt: "p", response: "r"))

        let stats = try databaseManager.getAIToolUsageStats(userId: testUserId)

        XCTAssertEqual(stats.count, 1)
        XCTAssertNotNil(stats.first?.lastUsed)
    }

    func testUserSessionWithZeroWordsAndInteractions() throws {
        let session = UserSession(
            userId: testUserId,
            startTime: Date(),
            wordsWritten: 0,
            aiInteractions: 0
        )

        try databaseManager.insertUserSession(session)

        let retrieved = try databaseManager.getUserSessions(userId: testUserId)
        XCTAssertEqual(retrieved.first?.wordsWritten, 0)
        XCTAssertEqual(retrieved.first?.aiInteractions, 0)
    }

    func testUserSessionWithVeryLongDuration() throws {
        let longDuration = 86400 * 7 // 7 days in seconds
        let session = UserSession(userId: testUserId, durationSeconds: longDuration)

        try databaseManager.insertUserSession(session)

        let retrieved = try databaseManager.getUserSessions(userId: testUserId)
        XCTAssertEqual(retrieved.first?.durationSeconds, longDuration)
    }

    func testGetUserSessionsDefaultOrderByStartTime() throws {
        let session1 = UserSession(userId: testUserId, startTime: Date(timeIntervalSince1970: 2000), durationSeconds: 500)
        let session2 = UserSession(userId: testUserId, startTime: Date(timeIntervalSince1970: 3000), durationSeconds: 1000)
        let session3 = UserSession(userId: testUserId, startTime: Date(timeIntervalSince1970: 1000), durationSeconds: 2000)

        try databaseManager.insertUserSession(session1)
        try databaseManager.insertUserSession(session2)
        try databaseManager.insertUserSession(session3)

        let sessions = try databaseManager.getUserSessions(userId: testUserId, sortByDuration: false)

        // Should be ordered by start_time DESC (newest first)
        XCTAssertEqual(sessions[0].startTime.timeIntervalSince1970, 3000)
        XCTAssertEqual(sessions[1].startTime.timeIntervalSince1970, 2000)
        XCTAssertEqual(sessions[2].startTime.timeIntervalSince1970, 1000)
    }

    func testFilterSessionsByModeWithNullMode() throws {
        try databaseManager.insertUserSession(UserSession(userId: testUserId, multitaskingMode: "Split View"))
        try databaseManager.insertUserSession(UserSession(userId: testUserId, multitaskingMode: nil))

        let filtered = try databaseManager.filterSessionsByMode(userId: testUserId, mode: "Split View")
        XCTAssertEqual(filtered.count, 1)
    }

    func testSessionStatsWithVeryEarlyAndLateDates() throws {
        let earlyDate = Date(timeIntervalSince1970: 0)
        let lateDate = Date()

        try databaseManager.insertUserSession(UserSession(userId: testUserId, startTime: earlyDate, durationSeconds: 100))
        try databaseManager.insertUserSession(UserSession(userId: testUserId, startTime: lateDate, durationSeconds: 200))

        let stats = try databaseManager.getSessionStats(userId: testUserId)

        XCTAssertNotNil(stats.earliestSession)
        XCTAssertNotNil(stats.latestSession)
        XCTAssertEqual(stats.earliestSession?.timeIntervalSince1970, 0, accuracy: 1.0)
    }

    func testAIConfigurationWithExtremeValues() throws {
        let config = AIConfiguration(
            apiKey: "test-key",
            model: .claude3Opus,
            maxTokens: 200000,
            temperature: 1.0
        )

        try databaseManager.saveAIConfiguration(userId: testUserId, configuration: config)

        let retrieved = try databaseManager.getAIConfiguration(userId: testUserId)
        XCTAssertEqual(retrieved?.maxTokens, 200000)
        XCTAssertEqual(retrieved?.temperature, 1.0)
    }

    func testAIConfigurationWithMinimumValues() throws {
        let config = AIConfiguration(
            apiKey: "k",
            model: .claudeInstant,
            maxTokens: 1,
            temperature: 0.0
        )

        try databaseManager.saveAIConfiguration(userId: testUserId, configuration: config)

        let retrieved = try databaseManager.getAIConfiguration(userId: testUserId)
        XCTAssertEqual(retrieved?.apiKey, "k")
        XCTAssertEqual(retrieved?.maxTokens, 1)
        XCTAssertEqual(retrieved?.temperature, 0.0)
    }

    func testTraceWithVeryLongName() throws {
        let longName = String(repeating: "trace_name_", count: 100)
        let trace = Trace(sessionId: "session", name: longName)

        try databaseManager.insertTrace(trace)

        let retrieved = try databaseManager.getTraces()
        XCTAssertEqual(retrieved.first?.name.count, longName.count)
    }

    func testTraceWithVeryLongSessionId() throws {
        let longSessionId = String(repeating: "session-", count: 100)
        let trace = Trace(sessionId: longSessionId, name: "trace")

        try databaseManager.insertTrace(trace)

        let retrieved = try databaseManager.getTraces(sessionId: longSessionId)
        XCTAssertEqual(retrieved.count, 1)
    }

    func testGetAllTracesWithMultipleSessions() throws {
        try databaseManager.insertTrace(Trace(sessionId: "A", name: "t1"))
        try databaseManager.insertTrace(Trace(sessionId: "B", name: "t2"))
        try databaseManager.insertTrace(Trace(sessionId: "A", name: "t3"))
        try databaseManager.insertTrace(Trace(sessionId: "C", name: "t4"))

        let allTraces = try databaseManager.getTraces()
        XCTAssertEqual(allTraces.count, 4)
    }

    func testObservationWithVeryLongName() throws {
        let trace = Trace(sessionId: "session", name: "trace")
        try databaseManager.insertTrace(trace)

        let longName = String(repeating: "observation_", count: 100)
        let observation = Observation(traceId: trace.id, name: longName)

        try databaseManager.insertObservation(observation)

        let retrieved = try databaseManager.getObservations(traceId: trace.id)
        XCTAssertEqual(retrieved.first?.name.count, longName.count)
    }

    func testObservationWithEndTime() throws {
        let trace = Trace(sessionId: "session", name: "trace")
        try databaseManager.insertTrace(trace)

        let startTime = Date()
        let endTime = startTime.addingTimeInterval(5.0)

        var observation = Observation(traceId: trace.id, name: "obs", startTime: startTime)
        observation.endTime = endTime

        try databaseManager.insertObservation(observation)

        let retrieved = try databaseManager.getObservations(traceId: trace.id)
        XCTAssertNotNil(retrieved.first?.endTime)
        XCTAssertEqual(retrieved.first?.endTime?.timeIntervalSince1970, endTime.timeIntervalSince1970, accuracy: 0.01)
    }

    func testIssueWithVeryLongTitle() throws {
        let documentId = UUID()
        let longTitle = String(repeating: "Issue Title ", count: 100)

        let issue = Issue(
            documentId: documentId,
            title: longTitle,
            status: .open,
            priority: .medium
        )

        try databaseManager.insertIssue(issue)

        let retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(retrieved.first?.title.count, longTitle.count)
    }

    func testIssueWithVeryLongNotes() throws {
        let documentId = UUID()
        let longNotes = String(repeating: "Note content. ", count: 500)

        var issue = Issue(documentId: documentId, title: "Issue", status: .open, priority: .low)
        issue.metadata.notes = longNotes

        try databaseManager.insertIssue(issue)

        let retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(retrieved.first?.metadata.notes.count, longNotes.count)
    }

    func testIssueStatusTransitions() throws {
        let documentId = UUID()
        var issue = Issue(documentId: documentId, title: "Status Change Test", status: .open, priority: .medium)

        try databaseManager.insertIssue(issue)

        // Open -> In Progress
        issue.status = .inProgress
        issue.metadata.modified = Date()
        try databaseManager.updateIssue(issue)

        var retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(retrieved.first?.status, .inProgress)

        // In Progress -> Resolved
        issue.status = .resolved
        issue.metadata.modified = Date()
        issue.metadata.resolvedAt = Date()
        try databaseManager.updateIssue(issue)

        retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(retrieved.first?.status, .resolved)
        XCTAssertNotNil(retrieved.first?.metadata.resolvedAt)
    }

    func testIssuePriorityEscalation() throws {
        let documentId = UUID()
        var issue = Issue(documentId: documentId, title: "Escalation Test", status: .open, priority: .low)

        try databaseManager.insertIssue(issue)

        // Low -> Medium
        issue.priority = .medium
        issue.metadata.modified = Date()
        try databaseManager.updateIssue(issue)

        var retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(retrieved.first?.priority, .medium)

        // Medium -> High
        issue.priority = .high
        issue.metadata.modified = Date()
        try databaseManager.updateIssue(issue)

        retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(retrieved.first?.priority, .high)

        // High -> Critical
        issue.priority = .critical
        issue.metadata.modified = Date()
        try databaseManager.updateIssue(issue)

        retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(retrieved.first?.priority, .critical)
    }

    func testGetIssuesByStatusWithMultipleStatuses() throws {
        let documentId = UUID()

        try databaseManager.insertIssue(Issue(documentId: documentId, title: "Open 1", status: .open, priority: .low))
        try databaseManager.insertIssue(Issue(documentId: documentId, title: "Open 2", status: .open, priority: .low))
        try databaseManager.insertIssue(Issue(documentId: documentId, title: "In Progress", status: .inProgress, priority: .low))
        try databaseManager.insertIssue(Issue(documentId: documentId, title: "Resolved", status: .resolved, priority: .low))
        try databaseManager.insertIssue(Issue(documentId: documentId, title: "Closed", status: .closed, priority: .low))

        XCTAssertEqual(try databaseManager.getIssues(withStatus: .open).count, 2)
        XCTAssertEqual(try databaseManager.getIssues(withStatus: .inProgress).count, 1)
        XCTAssertEqual(try databaseManager.getIssues(withStatus: .resolved).count, 1)
        XCTAssertEqual(try databaseManager.getIssues(withStatus: .closed).count, 1)
    }

    func testMultipleDocumentsWithIssues() throws {
        let doc1 = UUID()
        let doc2 = UUID()
        let doc3 = UUID()

        try databaseManager.insertIssue(Issue(documentId: doc1, title: "Doc1 Issue1", status: .open, priority: .low))
        try databaseManager.insertIssue(Issue(documentId: doc1, title: "Doc1 Issue2", status: .open, priority: .low))
        try databaseManager.insertIssue(Issue(documentId: doc2, title: "Doc2 Issue1", status: .open, priority: .low))
        try databaseManager.insertIssue(Issue(documentId: doc3, title: "Doc3 Issue1", status: .open, priority: .low))

        XCTAssertEqual(try databaseManager.getIssues(forDocument: doc1).count, 2)
        XCTAssertEqual(try databaseManager.getIssues(forDocument: doc2).count, 1)
        XCTAssertEqual(try databaseManager.getIssues(forDocument: doc3).count, 1)
    }

    func testIssueTagsWithSpecialCharacters() throws {
        let documentId = UUID()
        var issue = Issue(documentId: documentId, title: "Tagged", status: .open, priority: .low)
        issue.metadata.tags = ["bug#1", "todo:urgent", "chapter-5/scene-2", "author's-note"]

        try databaseManager.insertIssue(issue)

        let retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(retrieved.first?.metadata.tags.count, 4)
        XCTAssertTrue(retrieved.first?.metadata.tags.contains("author's-note") ?? false)
    }

    func testConcurrentDatabaseOperations() throws {
        // Simulate concurrent operations from different components
        let userIds = (1...5).map { _ in UUID() }

        for userId in userIds {
            try databaseManager.insertAISuggestion(AISuggestion(userId: userId, toolUsed: "Tool", prompt: "p", response: "r"))
            try databaseManager.insertUserSession(UserSession(userId: userId, durationSeconds: 100))
            try databaseManager.saveAIConfiguration(userId: userId, configuration: AIConfiguration(apiKey: "key", model: .claude35Sonnet))
        }

        for userId in userIds {
            XCTAssertEqual(try databaseManager.getAISuggestions(userId: userId).count, 1)
            XCTAssertEqual(try databaseManager.getUserSessions(userId: userId).count, 1)
            XCTAssertNotNil(try databaseManager.getAIConfiguration(userId: userId))
        }
    }

    func testDatabasePersistenceAcrossConnections() throws {
        let suggestion = AISuggestion(userId: testUserId, toolUsed: "Tool", prompt: "p", response: "r")
        try databaseManager.insertAISuggestion(suggestion)

        databaseManager.close()

        let newDbManager = DatabaseManager(databasePath: testDatabasePath)
        try newDbManager.initialize()

        let retrieved = try newDbManager.getAISuggestions(userId: testUserId)
        XCTAssertEqual(retrieved.count, 1)
        XCTAssertEqual(retrieved.first?.id, suggestion.id)

        newDbManager.close()
    }

    func testNegativeOffsetHandling() throws {
        for i in 1...5 {
            try databaseManager.insertAISuggestion(AISuggestion(userId: testUserId, toolUsed: "T\(i)", prompt: "p", response: "r"))
        }

        // SQLite handles negative offset as 0
        let results = try databaseManager.getAISuggestions(userId: testUserId, limit: 3, offset: -1)
        XCTAssertEqual(results.count, 3)
    }

    func testVeryLargeLimitValue() throws {
        for i in 1...10 {
            try databaseManager.insertAISuggestion(AISuggestion(userId: testUserId, toolUsed: "T\(i)", prompt: "p", response: "r"))
        }

        let results = try databaseManager.getAISuggestions(userId: testUserId, limit: 1000000, offset: 0)
        XCTAssertEqual(results.count, 10)
    }
}