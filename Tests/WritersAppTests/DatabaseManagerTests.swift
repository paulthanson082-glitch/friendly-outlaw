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
            name: "Test Trace",
            startTime: Date(),
            metadata: "test metadata"
        )

        try databaseManager.insertTrace(trace)

        let retrieved = try databaseManager.getTraces()
        XCTAssertEqual(retrieved.count, 1)
        XCTAssertEqual(retrieved.first?.id, trace.id)
        XCTAssertEqual(retrieved.first?.name, "Test Trace")
        XCTAssertEqual(retrieved.first?.sessionId, "session-123")
    }

    func testGetTracesBySessionId() throws {
        let trace1 = Trace(sessionId: "session-1", name: "Trace 1", startTime: Date())
        let trace2 = Trace(sessionId: "session-2", name: "Trace 2", startTime: Date())
        let trace3 = Trace(sessionId: "session-1", name: "Trace 3", startTime: Date())

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
            name: "Minimal Trace",
            startTime: Date(),
            endTime: nil,
            metadata: nil
        )

        try databaseManager.insertTrace(trace)

        let retrieved = try databaseManager.getTraces()
        XCTAssertEqual(retrieved.count, 1)
        XCTAssertNil(retrieved.first?.endTime)
        XCTAssertNil(retrieved.first?.metadata)
    }

    func testTraceWithEndTime() throws {
        let startTime = Date()
        let endTime = Date(timeIntervalSinceNow: 100)
        let trace = Trace(
            sessionId: "session-123",
            name: "Completed Trace",
            startTime: startTime,
            endTime: endTime,
            metadata: "completed"
        )

        try databaseManager.insertTrace(trace)

        let retrieved = try databaseManager.getTraces()
        XCTAssertNotNil(retrieved.first?.endTime)
        XCTAssertEqual(retrieved.first?.metadata, "completed")
    }

    // MARK: - Observation Tests

    func testInsertAndRetrieveObservation() throws {
        // First create a trace
        let trace = Trace(sessionId: "session-123", name: "Test Trace", startTime: Date())
        try databaseManager.insertTrace(trace)

        let observation = Observation(
            traceId: trace.id,
            name: "Test Observation",
            startTime: Date(),
            input: "test input",
            output: "test output",
            statusMessage: "success"
        )

        try databaseManager.insertObservation(observation)

        let retrieved = try databaseManager.getObservations(traceId: trace.id)
        XCTAssertEqual(retrieved.count, 1)
        XCTAssertEqual(retrieved.first?.id, observation.id)
        XCTAssertEqual(retrieved.first?.name, "Test Observation")
        XCTAssertEqual(retrieved.first?.input, "test input")
        XCTAssertEqual(retrieved.first?.output, "test output")
    }

    func testMultipleObservationsForTrace() throws {
        let trace = Trace(sessionId: "session-123", name: "Test Trace", startTime: Date())
        try databaseManager.insertTrace(trace)

        for i in 1...5 {
            let observation = Observation(
                traceId: trace.id,
                name: "Observation \(i)",
                startTime: Date(),
                input: "input \(i)",
                output: "output \(i)"
            )
            try databaseManager.insertObservation(observation)
        }

        let retrieved = try databaseManager.getObservations(traceId: trace.id)
        XCTAssertEqual(retrieved.count, 5)
    }

    func testObservationWithOptionalFields() throws {
        let trace = Trace(sessionId: "session-123", name: "Test Trace", startTime: Date())
        try databaseManager.insertTrace(trace)

        let observation = Observation(
            traceId: trace.id,
            name: "Minimal Observation",
            startTime: Date(),
            endTime: nil,
            input: nil,
            output: nil,
            statusMessage: nil
        )

        try databaseManager.insertObservation(observation)

        let retrieved = try databaseManager.getObservations(traceId: trace.id)
        XCTAssertEqual(retrieved.count, 1)
        XCTAssertNil(retrieved.first?.endTime)
        XCTAssertNil(retrieved.first?.input)
        XCTAssertNil(retrieved.first?.output)
        XCTAssertNil(retrieved.first?.statusMessage)
    }

    func testObservationOrderedByStartTime() throws {
        let trace = Trace(sessionId: "session-123", name: "Test Trace", startTime: Date())
        try databaseManager.insertTrace(trace)

        let obs1 = Observation(traceId: trace.id, name: "First", startTime: Date(timeIntervalSince1970: 1000))
        let obs2 = Observation(traceId: trace.id, name: "Second", startTime: Date(timeIntervalSince1970: 2000))
        let obs3 = Observation(traceId: trace.id, name: "Third", startTime: Date(timeIntervalSince1970: 3000))

        // Insert in reverse order
        try databaseManager.insertObservation(obs3)
        try databaseManager.insertObservation(obs1)
        try databaseManager.insertObservation(obs2)

        let retrieved = try databaseManager.getObservations(traceId: trace.id)
        XCTAssertEqual(retrieved.count, 3)
        XCTAssertEqual(retrieved[0].name, "First")
        XCTAssertEqual(retrieved[1].name, "Second")
        XCTAssertEqual(retrieved[2].name, "Third")
    }

    // MARK: - Issue Tests

    func testInsertAndRetrieveIssue() throws {
        let documentId = UUID()
        let issue = Issue(
            documentId: documentId,
            title: "Test Issue",
            description: "This is a test issue",
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
            description: "Original Description",
            status: .open,
            priority: .low
        )

        try databaseManager.insertIssue(issue)

        // Update the issue
        issue.title = "Updated Title"
        issue.description = "Updated Description"
        issue.status = .resolved
        issue.priority = .critical

        try databaseManager.updateIssue(issue)

        let retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(retrieved.first?.title, "Updated Title")
        XCTAssertEqual(retrieved.first?.description, "Updated Description")
        XCTAssertEqual(retrieved.first?.status, .resolved)
        XCTAssertEqual(retrieved.first?.priority, .critical)
    }

    func testDeleteIssue() throws {
        let documentId = UUID()
        let issue = Issue(
            documentId: documentId,
            title: "Delete Me",
            description: "To be deleted",
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

        let openIssue1 = Issue(documentId: documentId, title: "Open 1", status: .open, priority: .medium)
        let openIssue2 = Issue(documentId: documentId, title: "Open 2", status: .open, priority: .medium)
        let resolvedIssue = Issue(documentId: documentId, title: "Resolved", status: .resolved, priority: .medium)
        let closedIssue = Issue(documentId: documentId, title: "Closed", status: .closed, priority: .medium)

        try databaseManager.insertIssue(openIssue1)
        try databaseManager.insertIssue(openIssue2)
        try databaseManager.insertIssue(resolvedIssue)
        try databaseManager.insertIssue(closedIssue)

        let openIssues = try databaseManager.getIssues(withStatus: .open)
        XCTAssertEqual(openIssues.count, 2)
        XCTAssertTrue(openIssues.allSatisfy { $0.status == .open })

        let resolvedIssues = try databaseManager.getIssues(withStatus: .resolved)
        XCTAssertEqual(resolvedIssues.count, 1)
        XCTAssertEqual(resolvedIssues.first?.title, "Resolved")
    }

    func testGetAllIssues() throws {
        let doc1 = UUID()
        let doc2 = UUID()

        try databaseManager.insertIssue(Issue(documentId: doc1, title: "Issue 1", status: .open, priority: .low))
        try databaseManager.insertIssue(Issue(documentId: doc2, title: "Issue 2", status: .open, priority: .medium))
        try databaseManager.insertIssue(Issue(documentId: doc1, title: "Issue 3", status: .resolved, priority: .high))

        let allIssues = try databaseManager.getAllIssues()
        XCTAssertEqual(allIssues.count, 3)
    }

    func testIssueWithTags() throws {
        let documentId = UUID()
        var issue = Issue(
            documentId: documentId,
            title: "Tagged Issue",
            status: .open,
            priority: .medium
        )
        issue.metadata.tags = ["bug", "urgent", "frontend"]

        try databaseManager.insertIssue(issue)

        let retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(retrieved.first?.metadata.tags.count, 3)
        XCTAssertTrue(retrieved.first?.metadata.tags.contains("bug") ?? false)
        XCTAssertTrue(retrieved.first?.metadata.tags.contains("urgent") ?? false)
    }

    func testIssueWithNotes() throws {
        let documentId = UUID()
        var issue = Issue(
            documentId: documentId,
            title: "Issue with Notes",
            status: .open,
            priority: .low
        )
        issue.metadata.notes = "This is a detailed note about the issue"

        try databaseManager.insertIssue(issue)

        let retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(retrieved.first?.metadata.notes, "This is a detailed note about the issue")
    }

    func testIssueResolvedAt() throws {
        let documentId = UUID()
        let resolvedDate = Date()
        var issue = Issue(
            documentId: documentId,
            title: "Resolved Issue",
            status: .resolved,
            priority: .medium
        )
        issue.metadata.resolvedAt = resolvedDate

        try databaseManager.insertIssue(issue)

        let retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertNotNil(retrieved.first?.metadata.resolvedAt)
    }

    func testIssuePagination() throws {
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

        // Verify no overlap
        XCTAssertNotEqual(firstPage.first?.id, secondPage.first?.id)
    }

    // MARK: - Error Handling Tests

    func testOperationsFailWhenNotInitialized() throws {
        let uninitializedDB = DatabaseManager(databasePath: "/tmp/uninit_\(UUID().uuidString).db")
        // Note: not calling initialize()

        let suggestion = AISuggestion(userId: testUserId, toolUsed: "Test", prompt: "Test", response: "Test")

        XCTAssertThrowsError(try uninitializedDB.insertAISuggestion(suggestion)) { error in
            XCTAssertTrue(error is DatabaseError)
            if case DatabaseError.notInitialized = error {
                // Expected error
            } else {
                XCTFail("Expected notInitialized error")
            }
        }

        XCTAssertThrowsError(try uninitializedDB.getAISuggestions(userId: testUserId)) { error in
            XCTAssertTrue(error is DatabaseError)
        }
    }

    func testConnectionFailureWithInvalidPath() {
        // Try to create database in non-existent directory
        let invalidPath = "/nonexistent/path/to/database.db"
        let dbManager = DatabaseManager(databasePath: invalidPath)

        XCTAssertThrowsError(try dbManager.initialize()) { error in
            XCTAssertTrue(error is DatabaseError)
            if case DatabaseError.connectionFailed = error {
                // Expected error
            } else {
                XCTFail("Expected connectionFailed error")
            }
        }
    }

    func testAISuggestionWithNullDocumentId() throws {
        let suggestion = AISuggestion(
            userId: testUserId,
            documentId: nil,
            toolUsed: "Test Tool",
            prompt: "Test prompt",
            response: "Test response"
        )

        try databaseManager.insertAISuggestion(suggestion)

        let retrieved = try databaseManager.getAISuggestions(userId: testUserId)
        XCTAssertEqual(retrieved.count, 1)
        XCTAssertNil(retrieved.first?.documentId)
    }

    func testUserSessionWithNullOptionalFields() throws {
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

    func testGetAIConfigurationReturnsNilWhenNotFound() throws {
        let nonExistentUserId = UUID()
        let config = try databaseManager.getAIConfiguration(userId: nonExistentUserId)
        XCTAssertNil(config)
    }

    func testEmptyResultsHandling() throws {
        // Test empty results for various queries
        let emptySuggestions = try databaseManager.getAISuggestions(userId: UUID())
        XCTAssertEqual(emptySuggestions.count, 0)

        let emptySessions = try databaseManager.getUserSessions(userId: UUID())
        XCTAssertEqual(emptySessions.count, 0)

        let emptyTraces = try databaseManager.getTraces(sessionId: "nonexistent")
        XCTAssertEqual(emptyTraces.count, 0)

        let emptyObservations = try databaseManager.getObservations(traceId: UUID())
        XCTAssertEqual(emptyObservations.count, 0)
    }

    func testDatabaseCloseAndReopen() throws {
        // Insert some data
        let suggestion = AISuggestion(userId: testUserId, toolUsed: "Test", prompt: "Test", response: "Test")
        try databaseManager.insertAISuggestion(suggestion)

        // Close the database
        databaseManager.close()

        // Verify operations fail after close
        XCTAssertThrowsError(try databaseManager.getAISuggestions(userId: testUserId))

        // Reopen
        try databaseManager.initialize()

        // Verify data is still there
        let retrieved = try databaseManager.getAISuggestions(userId: testUserId)
        XCTAssertEqual(retrieved.count, 1)
    }

    // MARK: - Additional Edge Case Tests

    func testMultipleCloseCalls() {
        // Multiple close calls should not cause errors
        databaseManager.close()
        databaseManager.close()
        databaseManager.close()
        // Should complete without crashing
    }

    func testLargeTextInAISuggestion() throws {
        let largePrompt = String(repeating: "A", count: 10000)
        let largeResponse = String(repeating: "B", count: 10000)

        let suggestion = AISuggestion(
            userId: testUserId,
            toolUsed: "Large Text Tool",
            prompt: largePrompt,
            response: largeResponse
        )

        try databaseManager.insertAISuggestion(suggestion)

        let retrieved = try databaseManager.getAISuggestions(userId: testUserId)
        XCTAssertEqual(retrieved.first?.prompt.count, 10000)
        XCTAssertEqual(retrieved.first?.response.count, 10000)
    }

    func testSpecialCharactersInText() throws {
        let specialText = "Test with 'quotes', \"double quotes\", and special chars: !@#$%^&*()[]{}|\\;:,.<>?/"

        let suggestion = AISuggestion(
            userId: testUserId,
            toolUsed: "Special Chars",
            prompt: specialText,
            response: specialText
        )

        try databaseManager.insertAISuggestion(suggestion)

        let retrieved = try databaseManager.getAISuggestions(userId: testUserId)
        XCTAssertEqual(retrieved.first?.prompt, specialText)
    }

    func testUnicodeCharactersInIssues() throws {
        let documentId = UUID()
        let issue = Issue(
            documentId: documentId,
            title: "Test 测试 テスト 🚀",
            description: "Unicode description: 你好世界 こんにちは世界 😊🎉",
            status: .open,
            priority: .medium
        )

        try databaseManager.insertIssue(issue)

        let retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(retrieved.first?.title, "Test 测试 テスト 🚀")
        XCTAssertTrue(retrieved.first?.description.contains("😊🎉") ?? false)
    }

    func testGetAISuggestionsWithZeroLimit() throws {
        let suggestion = AISuggestion(userId: testUserId, toolUsed: "Test", prompt: "Test", response: "Test")
        try databaseManager.insertAISuggestion(suggestion)

        let results = try databaseManager.getAISuggestions(userId: testUserId, limit: 0, offset: 0)
        // With limit 0, should return 0 results
        XCTAssertEqual(results.count, 0)
    }

    func testGetAISuggestionsWithLargeOffset() throws {
        let suggestion = AISuggestion(userId: testUserId, toolUsed: "Test", prompt: "Test", response: "Test")
        try databaseManager.insertAISuggestion(suggestion)

        let results = try databaseManager.getAISuggestions(userId: testUserId, limit: 10, offset: 1000)
        // Offset larger than total rows should return empty
        XCTAssertEqual(results.count, 0)
    }

    func testMultipleUsersIsolation() throws {
        let user1 = UUID()
        let user2 = UUID()

        let suggestion1 = AISuggestion(userId: user1, toolUsed: "Tool1", prompt: "Prompt1", response: "Response1")
        let suggestion2 = AISuggestion(userId: user2, toolUsed: "Tool2", prompt: "Prompt2", response: "Response2")

        try databaseManager.insertAISuggestion(suggestion1)
        try databaseManager.insertAISuggestion(suggestion2)

        let user1Results = try databaseManager.getAISuggestions(userId: user1)
        let user2Results = try databaseManager.getAISuggestions(userId: user2)

        XCTAssertEqual(user1Results.count, 1)
        XCTAssertEqual(user2Results.count, 1)
        XCTAssertEqual(user1Results.first?.toolUsed, "Tool1")
        XCTAssertEqual(user2Results.first?.toolUsed, "Tool2")
    }

    func testSessionStatsWithNoCompletedSessions() throws {
        let userId = UUID()

        // Insert session without duration
        let session = UserSession(
            userId: userId,
            startTime: Date(),
            endTime: nil,
            durationSeconds: nil
        )
        try databaseManager.insertUserSession(session)

        let stats = try databaseManager.getSessionStats(userId: userId)
        XCTAssertEqual(stats.totalSessions, 0) // Should not count sessions without duration
    }

    func testFilterAISuggestionsByNonExistentTool() throws {
        let suggestion = AISuggestion(userId: testUserId, toolUsed: "ExistingTool", prompt: "Test", response: "Test")
        try databaseManager.insertAISuggestion(suggestion)

        let filtered = try databaseManager.filterAISuggestionsByTool(userId: testUserId, tool: "NonExistentTool")
        XCTAssertEqual(filtered.count, 0)
    }

    func testIssueWithEmptyTags() throws {
        let documentId = UUID()
        var issue = Issue(
            documentId: documentId,
            title: "Issue without tags",
            status: .open,
            priority: .low
        )
        issue.metadata.tags = []

        try databaseManager.insertIssue(issue)

        let retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(retrieved.first?.metadata.tags.count, 0)
    }

    func testIssueWithManyTags() throws {
        let documentId = UUID()
        var issue = Issue(
            documentId: documentId,
            title: "Many tags issue",
            status: .open,
            priority: .medium
        )
        issue.metadata.tags = (1...50).map { "tag\($0)" }

        try databaseManager.insertIssue(issue)

        let retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(retrieved.first?.metadata.tags.count, 50)
    }

    func testTraceWithVeryLongMetadata() throws {
        let longMetadata = String(repeating: "metadata", count: 1000)
        let trace = Trace(
            sessionId: "session-123",
            name: "Long Metadata Trace",
            startTime: Date(),
            metadata: longMetadata
        )

        try databaseManager.insertTrace(trace)

        let retrieved = try databaseManager.getTraces()
        XCTAssertEqual(retrieved.first?.metadata?.count, longMetadata.count)
    }

    func testObservationWithNullTraceId() throws {
        // This should test foreign key constraint behavior
        let nonExistentTraceId = UUID()
        let observation = Observation(
            traceId: nonExistentTraceId,
            name: "Orphan Observation",
            startTime: Date()
        )

        // Should still insert (foreign key is not enforced in SQLite by default)
        try databaseManager.insertObservation(observation)

        let retrieved = try databaseManager.getObservations(traceId: nonExistentTraceId)
        XCTAssertEqual(retrieved.count, 1)
    }

    func testGetIssuesByStatusPagination() throws {
        let documentId = UUID()

        for i in 1...20 {
            let issue = Issue(
                documentId: documentId,
                title: "Issue \(i)",
                status: .open,
                priority: .medium
            )
            try databaseManager.insertIssue(issue)
        }

        let firstPage = try databaseManager.getIssues(withStatus: .open, limit: 10, offset: 0)
        let secondPage = try databaseManager.getIssues(withStatus: .open, limit: 10, offset: 10)

        XCTAssertEqual(firstPage.count, 10)
        XCTAssertEqual(secondPage.count, 10)
        XCTAssertNotEqual(firstPage.first?.id, secondPage.first?.id)
    }

    func testGetAllIssuesPagination() throws {
        let doc1 = UUID()
        let doc2 = UUID()

        for i in 1...25 {
            let issue = Issue(
                documentId: i % 2 == 0 ? doc1 : doc2,
                title: "Issue \(i)",
                status: .open,
                priority: .low
            )
            try databaseManager.insertIssue(issue)
        }

        let firstPage = try databaseManager.getAllIssues(limit: 10, offset: 0)
        let secondPage = try databaseManager.getAllIssues(limit: 10, offset: 10)
        let thirdPage = try databaseManager.getAllIssues(limit: 10, offset: 20)

        XCTAssertEqual(firstPage.count, 10)
        XCTAssertEqual(secondPage.count, 10)
        XCTAssertEqual(thirdPage.count, 5)
    }

    func testUpdateNonExistentAISuggestion() throws {
        let suggestion = AISuggestion(
            id: UUID(),
            userId: testUserId,
            toolUsed: "Test",
            prompt: "Test",
            response: "Test"
        )

        // Should not throw error, just update 0 rows
        try databaseManager.updateAISuggestion(suggestion)

        let retrieved = try databaseManager.getAISuggestions(userId: testUserId)
        XCTAssertEqual(retrieved.count, 0)
    }

    func testDeleteNonExistentAISuggestion() throws {
        let nonExistentId = UUID()

        // Should not throw error, just delete 0 rows
        try databaseManager.deleteAISuggestion(id: nonExistentId)

        let retrieved = try databaseManager.getAISuggestions(userId: testUserId)
        XCTAssertEqual(retrieved.count, 0)
    }

    func testDeleteNonExistentIssue() throws {
        let nonExistentId = UUID()

        // Should not throw error, just delete 0 rows
        try databaseManager.deleteIssue(id: nonExistentId)
    }

    func testJoinWithoutConfiguration() throws {
        // Create suggestion without AI configuration
        let suggestion = AISuggestion(
            userId: testUserId,
            toolUsed: "Test Tool",
            prompt: "Test",
            response: "Test"
        )
        try databaseManager.insertAISuggestion(suggestion)

        let joined = try databaseManager.getAISuggestionsWithConfig(userId: testUserId)

        XCTAssertEqual(joined.count, 1)
        XCTAssertEqual(joined.first?.modelUsed, "unknown")
    }

    func testAISuggestionTimestampOrdering() throws {
        let old = AISuggestion(
            userId: testUserId,
            toolUsed: "Old",
            prompt: "Old",
            response: "Old",
            timestamp: Date(timeIntervalSince1970: 1000)
        )
        let newer = AISuggestion(
            userId: testUserId,
            toolUsed: "Newer",
            prompt: "Newer",
            response: "Newer",
            timestamp: Date(timeIntervalSince1970: 3000)
        )
        let newest = AISuggestion(
            userId: testUserId,
            toolUsed: "Newest",
            prompt: "Newest",
            response: "Newest",
            timestamp: Date(timeIntervalSince1970: 5000)
        )

        // Insert in random order
        try databaseManager.insertAISuggestion(newer)
        try databaseManager.insertAISuggestion(old)
        try databaseManager.insertAISuggestion(newest)

        let retrieved = try databaseManager.getAISuggestions(userId: testUserId)

        // Should be ordered by timestamp DESC (newest first)
        XCTAssertEqual(retrieved[0].toolUsed, "Newest")
        XCTAssertEqual(retrieved[1].toolUsed, "Newer")
        XCTAssertEqual(retrieved[2].toolUsed, "Old")
    }

    func testConcurrentInsertions() throws {
        let expectation = XCTestExpectation(description: "Concurrent insertions complete")
        expectation.expectedFulfillmentCount = 10

        DispatchQueue.concurrentPerform(iterations: 10) { i in
            let suggestion = AISuggestion(
                userId: testUserId,
                toolUsed: "Tool \(i)",
                prompt: "Prompt \(i)",
                response: "Response \(i)"
            )

            do {
                try databaseManager.insertAISuggestion(suggestion)
                expectation.fulfill()
            } catch {
                XCTFail("Concurrent insertion failed: \(error)")
            }
        }

        wait(for: [expectation], timeout: 5.0)

        let retrieved = try databaseManager.getAISuggestions(userId: testUserId)
        XCTAssertEqual(retrieved.count, 10)
    }
}