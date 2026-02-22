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

    func testGetAIConfigurationNonexistent() throws {
        let retrieved = try databaseManager.getAIConfiguration(userId: UUID())
        XCTAssertNil(retrieved)
    }

    // MARK: - Trace Tests

    func testInsertAndRetrieveTrace() throws {
        let trace = Trace(
            sessionId: "session-123",
            name: "Document Edit",
            startTime: Date()
        )

        try databaseManager.insertTrace(trace)

        let retrieved = try databaseManager.getTraces()
        XCTAssertEqual(retrieved.count, 1)
        XCTAssertEqual(retrieved.first?.id, trace.id)
        XCTAssertEqual(retrieved.first?.name, "Document Edit")
        XCTAssertEqual(retrieved.first?.sessionId, "session-123")
    }

    func testRetrieveTracesBySession() throws {
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
        XCTAssertEqual(session2Traces.first?.name, "Trace 2")
    }

    func testTraceWithEndTime() throws {
        let startTime = Date()
        let endTime = Date(timeInterval: 60, since: startTime)

        let trace = Trace(
            sessionId: "session-456",
            name: "Completed Trace",
            startTime: startTime,
            endTime: endTime,
            metadata: "{\"key\": \"value\"}"
        )

        try databaseManager.insertTrace(trace)

        let retrieved = try databaseManager.getTraces()
        XCTAssertEqual(retrieved.first?.endTime?.timeIntervalSince1970, endTime.timeIntervalSince1970, accuracy: 0.001)
        XCTAssertEqual(retrieved.first?.metadata, "{\"key\": \"value\"}")
    }

    func testTraceWithNullFields() throws {
        let trace = Trace(
            sessionId: "session-789",
            name: "Incomplete Trace",
            startTime: Date(),
            endTime: nil,
            metadata: nil
        )

        try databaseManager.insertTrace(trace)

        let retrieved = try databaseManager.getTraces()
        XCTAssertNil(retrieved.first?.endTime)
        XCTAssertNil(retrieved.first?.metadata)
    }

    // MARK: - Observation Tests

    func testInsertAndRetrieveObservation() throws {
        let trace = Trace(sessionId: "session-obs", name: "Test Trace", startTime: Date())
        try databaseManager.insertTrace(trace)

        let observation = Observation(
            traceId: trace.id,
            name: "AI Request",
            startTime: Date(),
            input: "Generate text",
            output: "Generated content"
        )

        try databaseManager.insertObservation(observation)

        let retrieved = try databaseManager.getObservations(traceId: trace.id)
        XCTAssertEqual(retrieved.count, 1)
        XCTAssertEqual(retrieved.first?.id, observation.id)
        XCTAssertEqual(retrieved.first?.name, "AI Request")
        XCTAssertEqual(retrieved.first?.input, "Generate text")
        XCTAssertEqual(retrieved.first?.output, "Generated content")
    }

    func testMultipleObservationsForTrace() throws {
        let trace = Trace(sessionId: "session-multi", name: "Multi Obs Trace", startTime: Date())
        try databaseManager.insertTrace(trace)

        let obs1 = Observation(traceId: trace.id, name: "Obs 1", startTime: Date())
        let obs2 = Observation(traceId: trace.id, name: "Obs 2", startTime: Date())
        let obs3 = Observation(traceId: trace.id, name: "Obs 3", startTime: Date())

        try databaseManager.insertObservation(obs1)
        try databaseManager.insertObservation(obs2)
        try databaseManager.insertObservation(obs3)

        let retrieved = try databaseManager.getObservations(traceId: trace.id)
        XCTAssertEqual(retrieved.count, 3)
    }

    func testObservationWithAllFields() throws {
        let trace = Trace(sessionId: "session-full", name: "Full Trace", startTime: Date())
        try databaseManager.insertTrace(trace)

        let startTime = Date()
        let endTime = Date(timeInterval: 5, since: startTime)

        let observation = Observation(
            traceId: trace.id,
            name: "Complete Observation",
            startTime: startTime,
            endTime: endTime,
            input: "Input data",
            output: "Output data",
            statusMessage: "Success"
        )

        try databaseManager.insertObservation(observation)

        let retrieved = try databaseManager.getObservations(traceId: trace.id)
        XCTAssertEqual(retrieved.first?.endTime?.timeIntervalSince1970, endTime.timeIntervalSince1970, accuracy: 0.001)
        XCTAssertEqual(retrieved.first?.statusMessage, "Success")
    }

    func testObservationWithNullOptionalFields() throws {
        let trace = Trace(sessionId: "session-minimal", name: "Minimal Trace", startTime: Date())
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
        XCTAssertNil(retrieved.first?.endTime)
        XCTAssertNil(retrieved.first?.input)
        XCTAssertNil(retrieved.first?.output)
        XCTAssertNil(retrieved.first?.statusMessage)
    }

    // MARK: - Issue Tests

    func testInsertAndRetrieveIssue() throws {
        let documentId = UUID()
        let issue = Issue(
            documentId: documentId,
            title: "Plot hole in chapter 3",
            description: "The timeline doesn't match",
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
            title: "Original Title",
            description: "Original Description",
            status: .open,
            priority: .low
        )

        try databaseManager.insertIssue(issue)

        issue.title = "Updated Title"
        issue.description = "Updated Description"
        issue.status = .resolved
        issue.priority = .critical
        issue.metadata.resolvedAt = Date()

        try databaseManager.updateIssue(issue)

        let retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(retrieved.first?.title, "Updated Title")
        XCTAssertEqual(retrieved.first?.description, "Updated Description")
        XCTAssertEqual(retrieved.first?.status, .resolved)
        XCTAssertEqual(retrieved.first?.priority, .critical)
        XCTAssertNotNil(retrieved.first?.metadata.resolvedAt)
    }

    func testGetIssuesByStatus() throws {
        let docId = UUID()

        let issue1 = Issue(documentId: docId, title: "Open Issue", status: .open, priority: .medium)
        let issue2 = Issue(documentId: docId, title: "Resolved Issue", status: .resolved, priority: .medium)
        let issue3 = Issue(documentId: docId, title: "Another Open", status: .open, priority: .medium)
        let issue4 = Issue(documentId: docId, title: "Closed Issue", status: .closed, priority: .medium)

        try databaseManager.insertIssue(issue1)
        try databaseManager.insertIssue(issue2)
        try databaseManager.insertIssue(issue3)
        try databaseManager.insertIssue(issue4)

        let openIssues = try databaseManager.getIssues(withStatus: .open)
        XCTAssertEqual(openIssues.count, 2)
        XCTAssertTrue(openIssues.allSatisfy { $0.status == .open })

        let resolvedIssues = try databaseManager.getIssues(withStatus: .resolved)
        XCTAssertEqual(resolvedIssues.count, 1)
        XCTAssertEqual(resolvedIssues.first?.title, "Resolved Issue")
    }

    func testGetAllIssues() throws {
        let docId1 = UUID()
        let docId2 = UUID()

        try databaseManager.insertIssue(Issue(documentId: docId1, title: "Issue 1", status: .open, priority: .low))
        try databaseManager.insertIssue(Issue(documentId: docId2, title: "Issue 2", status: .open, priority: .low))
        try databaseManager.insertIssue(Issue(documentId: docId1, title: "Issue 3", status: .resolved, priority: .low))

        let allIssues = try databaseManager.getAllIssues()
        XCTAssertEqual(allIssues.count, 3)
    }

    func testDeleteIssue() throws {
        let documentId = UUID()
        let issue = Issue(
            documentId: documentId,
            title: "To Delete",
            status: .open,
            priority: .low
        )

        try databaseManager.insertIssue(issue)

        var retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(retrieved.count, 1)

        try databaseManager.deleteIssue(id: issue.id)

        retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(retrieved.count, 0)
    }

    func testIssueWithTagsAndNotes() throws {
        let documentId = UUID()
        var issue = Issue(
            documentId: documentId,
            title: "Tagged Issue",
            status: .open,
            priority: .medium
        )
        issue.metadata.tags = ["plot", "character", "timeline"]
        issue.metadata.notes = "This needs urgent attention"

        try databaseManager.insertIssue(issue)

        let retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(retrieved.first?.metadata.tags.count, 3)
        XCTAssertTrue(retrieved.first?.metadata.tags.contains("plot") ?? false)
        XCTAssertEqual(retrieved.first?.metadata.notes, "This needs urgent attention")
    }

    func testIssuePagination() throws {
        let documentId = UUID()

        for i in 1...20 {
            let issue = Issue(
                documentId: documentId,
                title: "Issue \(i)",
                status: .open,
                priority: .low
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

    func testOperationBeforeInitialization() throws {
        let uninitializedDB = DatabaseManager(databasePath: "/tmp/uninitialized_\(UUID().uuidString).db")

        let suggestion = AISuggestion(
            userId: testUserId,
            toolUsed: "Test",
            prompt: "Test",
            response: "Test"
        )

        XCTAssertThrowsError(try uninitializedDB.insertAISuggestion(suggestion)) { error in
            guard let dbError = error as? DatabaseError else {
                XCTFail("Expected DatabaseError")
                return
            }
            if case .notInitialized = dbError {
                // Expected error
            } else {
                XCTFail("Expected notInitialized error")
            }
        }
    }

    func testDatabaseConnectionFailure() throws {
        // Try to create database in non-existent directory
        let invalidPath = "/nonexistent/path/database.db"
        let invalidDB = DatabaseManager(databasePath: invalidPath)

        XCTAssertThrowsError(try invalidDB.initialize()) { error in
            guard let dbError = error as? DatabaseError else {
                XCTFail("Expected DatabaseError")
                return
            }
            if case .connectionFailed = dbError {
                // Expected error
            } else {
                XCTFail("Expected connectionFailed error")
            }
        }
    }

    func testCloseDatabase() throws {
        databaseManager.close()

        // Operations after close should fail
        let suggestion = AISuggestion(
            userId: testUserId,
            toolUsed: "Test",
            prompt: "Test",
            response: "Test"
        )

        XCTAssertThrowsError(try databaseManager.insertAISuggestion(suggestion))
    }

    func testAISuggestionWithNullDocumentId() throws {
        let suggestion = AISuggestion(
            userId: testUserId,
            documentId: nil,
            toolUsed: "Global Tool",
            prompt: "No document",
            response: "General response"
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

    // MARK: - Edge Case Tests

    func testEmptyQueryResults() throws {
        let nonexistentUserId = UUID()

        let suggestions = try databaseManager.getAISuggestions(userId: nonexistentUserId)
        XCTAssertEqual(suggestions.count, 0)

        let sessions = try databaseManager.getUserSessions(userId: nonexistentUserId)
        XCTAssertEqual(sessions.count, 0)

        let stats = try databaseManager.getSessionStats(userId: nonexistentUserId)
        XCTAssertEqual(stats.totalSessions, 0)
        XCTAssertEqual(stats.totalDurationSeconds, 0)
    }

    func testLargeTextFields() throws {
        let largePrompt = String(repeating: "A", count: 10000)
        let largeResponse = String(repeating: "B", count: 10000)

        let suggestion = AISuggestion(
            userId: testUserId,
            toolUsed: "Test",
            prompt: largePrompt,
            response: largeResponse
        )

        try databaseManager.insertAISuggestion(suggestion)

        let retrieved = try databaseManager.getAISuggestions(userId: testUserId)
        XCTAssertEqual(retrieved.first?.prompt.count, 10000)
        XCTAssertEqual(retrieved.first?.response.count, 10000)
    }

    func testSpecialCharactersInText() throws {
        let specialText = "Test with 'quotes', \"double quotes\", and special chars: <>&\n\t"

        let suggestion = AISuggestion(
            userId: testUserId,
            toolUsed: "Special Test",
            prompt: specialText,
            response: specialText
        )

        try databaseManager.insertAISuggestion(suggestion)

        let retrieved = try databaseManager.getAISuggestions(userId: testUserId)
        XCTAssertEqual(retrieved.first?.prompt, specialText)
        XCTAssertEqual(retrieved.first?.response, specialText)
    }

    func testMultipleDatabaseInstances() throws {
        let path1 = "/tmp/test_db1_\(UUID().uuidString).db"
        let path2 = "/tmp/test_db2_\(UUID().uuidString).db"

        let db1 = DatabaseManager(databasePath: path1)
        let db2 = DatabaseManager(databasePath: path2)

        try db1.initialize()
        try db2.initialize()

        let suggestion1 = AISuggestion(userId: testUserId, toolUsed: "DB1", prompt: "test", response: "test")
        let suggestion2 = AISuggestion(userId: testUserId, toolUsed: "DB2", prompt: "test", response: "test")

        try db1.insertAISuggestion(suggestion1)
        try db2.insertAISuggestion(suggestion2)

        let results1 = try db1.getAISuggestions(userId: testUserId)
        let results2 = try db2.getAISuggestions(userId: testUserId)

        XCTAssertEqual(results1.count, 1)
        XCTAssertEqual(results2.count, 1)
        XCTAssertEqual(results1.first?.toolUsed, "DB1")
        XCTAssertEqual(results2.first?.toolUsed, "DB2")

        db1.close()
        db2.close()
        try? FileManager.default.removeItem(atPath: path1)
        try? FileManager.default.removeItem(atPath: path2)
    }

    // MARK: - Additional Boundary and Edge Case Tests

    func testReInitializeAfterClose() throws {
        databaseManager.close()
        try databaseManager.initialize()

        let suggestion = AISuggestion(
            userId: testUserId,
            toolUsed: "Test",
            prompt: "Test prompt",
            response: "Test response"
        )

        try databaseManager.insertAISuggestion(suggestion)
        let retrieved = try databaseManager.getAISuggestions(userId: testUserId)
        XCTAssertEqual(retrieved.count, 1)
    }

    func testIssueWithEmptyTags() throws {
        let documentId = UUID()
        var issue = Issue(
            documentId: documentId,
            title: "No tags issue",
            status: .open,
            priority: .low
        )
        issue.metadata.tags = []

        try databaseManager.insertIssue(issue)

        let retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(retrieved.first?.metadata.tags.count, 0)
    }

    func testIssueWithEmptyNotes() throws {
        let documentId = UUID()
        var issue = Issue(
            documentId: documentId,
            title: "Empty notes",
            status: .open,
            priority: .low
        )
        issue.metadata.notes = ""

        try databaseManager.insertIssue(issue)

        let retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(retrieved.first?.metadata.notes, "")
    }

    func testIssueWithVeryLongDescription() throws {
        let documentId = UUID()
        let longDescription = String(repeating: "A", count: 50000)
        let issue = Issue(
            documentId: documentId,
            title: "Long description issue",
            description: longDescription,
            status: .open,
            priority: .medium
        )

        try databaseManager.insertIssue(issue)

        let retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(retrieved.first?.description.count, 50000)
    }

    func testTraceWithVeryLongMetadata() throws {
        let longMetadata = String(repeating: "{\"key\":\"value\"}", count: 1000)
        let trace = Trace(
            sessionId: "session-long",
            name: "Long metadata trace",
            startTime: Date(),
            metadata: longMetadata
        )

        try databaseManager.insertTrace(trace)

        let retrieved = try databaseManager.getTraces()
        XCTAssertEqual(retrieved.first?.metadata?.count, longMetadata.count)
    }

    func testObservationWithVeryLargeInputOutput() throws {
        let trace = Trace(sessionId: "session-large", name: "Large obs trace", startTime: Date())
        try databaseManager.insertTrace(trace)

        let largeInput = String(repeating: "Input ", count: 10000)
        let largeOutput = String(repeating: "Output ", count: 10000)

        let observation = Observation(
            traceId: trace.id,
            name: "Large data observation",
            startTime: Date(),
            input: largeInput,
            output: largeOutput
        )

        try databaseManager.insertObservation(observation)

        let retrieved = try databaseManager.getObservations(traceId: trace.id)
        XCTAssertGreaterThan(retrieved.first?.input?.count ?? 0, 50000)
        XCTAssertGreaterThan(retrieved.first?.output?.count ?? 0, 50000)
    }

    func testGetObservationsForNonexistentTrace() throws {
        let observations = try databaseManager.getObservations(traceId: UUID())
        XCTAssertEqual(observations.count, 0)
    }

    func testGetTracesForNonexistentSession() throws {
        let traces = try databaseManager.getTraces(sessionId: "nonexistent-session")
        XCTAssertEqual(traces.count, 0)
    }

    func testAISuggestionTimestampPrecision() throws {
        let now = Date()
        let suggestion = AISuggestion(
            userId: testUserId,
            toolUsed: "Timestamp test",
            prompt: "Test",
            response: "Test",
            timestamp: now
        )

        try databaseManager.insertAISuggestion(suggestion)

        let retrieved = try databaseManager.getAISuggestions(userId: testUserId)
        let timeDiff = abs(retrieved.first!.timestamp.timeIntervalSince1970 - now.timeIntervalSince1970)
        XCTAssertLessThan(timeDiff, 0.001) // Less than 1ms difference
    }

    func testUserSessionWithVeryOldDates() throws {
        let veryOldDate = Date(timeIntervalSince1970: 0) // Jan 1, 1970
        let session = UserSession(
            userId: testUserId,
            startTime: veryOldDate,
            endTime: Date(timeInterval: 3600, since: veryOldDate),
            durationSeconds: 3600
        )

        try databaseManager.insertUserSession(session)

        let retrieved = try databaseManager.getUserSessions(userId: testUserId)
        XCTAssertEqual(retrieved.first?.startTime.timeIntervalSince1970, 0, accuracy: 0.001)
    }

    func testUserSessionWithFutureDates() throws {
        let futureDate = Date(timeIntervalSinceNow: 365 * 24 * 3600) // 1 year in future
        let session = UserSession(
            userId: testUserId,
            startTime: futureDate,
            durationSeconds: 1000
        )

        try databaseManager.insertUserSession(session)

        let retrieved = try databaseManager.getUserSessions(userId: testUserId)
        XCTAssertNotNil(retrieved.first)
        XCTAssertGreaterThan(retrieved.first!.startTime.timeIntervalSinceNow, 0)
    }

    func testFilterAISuggestionsByNonexistentTool() throws {
        let suggestion = AISuggestion(
            userId: testUserId,
            toolUsed: "Existing Tool",
            prompt: "Test",
            response: "Test"
        )
        try databaseManager.insertAISuggestion(suggestion)

        let filtered = try databaseManager.filterAISuggestionsByTool(userId: testUserId, tool: "Nonexistent Tool")
        XCTAssertEqual(filtered.count, 0)
    }

    func testAIToolUsageStatsWithNoData() throws {
        let stats = try databaseManager.getAIToolUsageStats(userId: UUID())
        XCTAssertEqual(stats.count, 0)
    }

    func testFilterSessionsByNonexistentMode() throws {
        let session = UserSession(
            userId: testUserId,
            multitaskingMode: "Split View"
        )
        try databaseManager.insertUserSession(session)

        let filtered = try databaseManager.filterSessionsByMode(userId: testUserId, mode: "Nonexistent Mode")
        XCTAssertEqual(filtered.count, 0)
    }

    func testGetAISuggestionsWithConfigNoConfig() throws {
        let suggestion = AISuggestion(
            userId: testUserId,
            toolUsed: "Test",
            prompt: "Test",
            response: "Test"
        )
        try databaseManager.insertAISuggestion(suggestion)

        let joined = try databaseManager.getAISuggestionsWithConfig(userId: testUserId)
        XCTAssertEqual(joined.count, 1)
        XCTAssertEqual(joined.first?.modelUsed, "unknown")
    }

    func testSessionStatsWithSessionsWithoutDuration() throws {
        let session = UserSession(
            userId: testUserId,
            startTime: Date(),
            durationSeconds: nil
        )
        try databaseManager.insertUserSession(session)

        let stats = try databaseManager.getSessionStats(userId: testUserId)
        XCTAssertEqual(stats.totalSessions, 0) // Should only count sessions with duration
    }

    func testInsertMultipleIssuesSameDocument() throws {
        let documentId = UUID()

        for i in 1...10 {
            let issue = Issue(
                documentId: documentId,
                title: "Issue \(i)",
                status: .open,
                priority: .low
            )
            try databaseManager.insertIssue(issue)
        }

        let retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(retrieved.count, 10)
    }

    func testUpdateIssueChangesModifiedDate() throws {
        let documentId = UUID()
        var issue = Issue(
            documentId: documentId,
            title: "Original",
            status: .open,
            priority: .low
        )

        try databaseManager.insertIssue(issue)
        let originalModified = issue.metadata.modified

        Thread.sleep(forTimeInterval: 0.1) // Small delay

        issue.title = "Updated"
        issue.metadata.modified = Date()

        try databaseManager.updateIssue(issue)

        let retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertGreaterThan(retrieved.first!.metadata.modified, originalModified)
    }

    func testIssueStatusPaginationBoundary() throws {
        // Test pagination boundary with exactly limit items
        for i in 1...5 {
            let issue = Issue(
                documentId: UUID(),
                title: "Issue \(i)",
                status: .open,
                priority: .low
            )
            try databaseManager.insertIssue(issue)
        }

        let firstPage = try databaseManager.getIssues(withStatus: .open, limit: 5, offset: 0)
        XCTAssertEqual(firstPage.count, 5)

        let secondPage = try databaseManager.getIssues(withStatus: .open, limit: 5, offset: 5)
        XCTAssertEqual(secondPage.count, 0)
    }

    func testTracesOrderedByStartTime() throws {
        let trace1 = Trace(sessionId: "s1", name: "First", startTime: Date(timeIntervalSince1970: 1000))
        let trace2 = Trace(sessionId: "s1", name: "Second", startTime: Date(timeIntervalSince1970: 2000))
        let trace3 = Trace(sessionId: "s1", name: "Third", startTime: Date(timeIntervalSince1970: 1500))

        try databaseManager.insertTrace(trace1)
        try databaseManager.insertTrace(trace2)
        try databaseManager.insertTrace(trace3)

        let retrieved = try databaseManager.getTraces(sessionId: "s1")
        XCTAssertEqual(retrieved.count, 3)
        XCTAssertEqual(retrieved[0].name, "First")
        XCTAssertEqual(retrieved[1].name, "Third")
        XCTAssertEqual(retrieved[2].name, "Second")
    }

    func testObservationsOrderedByStartTime() throws {
        let trace = Trace(sessionId: "order-test", name: "Order Trace", startTime: Date())
        try databaseManager.insertTrace(trace)

        let obs1 = Observation(traceId: trace.id, name: "First", startTime: Date(timeIntervalSince1970: 1000))
        let obs2 = Observation(traceId: trace.id, name: "Second", startTime: Date(timeIntervalSince1970: 2000))
        let obs3 = Observation(traceId: trace.id, name: "Third", startTime: Date(timeIntervalSince1970: 1500))

        try databaseManager.insertObservation(obs1)
        try databaseManager.insertObservation(obs2)
        try databaseManager.insertObservation(obs3)

        let retrieved = try databaseManager.getObservations(traceId: trace.id)
        XCTAssertEqual(retrieved.count, 3)
        XCTAssertEqual(retrieved[0].name, "First")
        XCTAssertEqual(retrieved[1].name, "Third")
        XCTAssertEqual(retrieved[2].name, "Second")
    }

    func testAISuggestionsOrderedByTimestampDescending() throws {
        let sug1 = AISuggestion(userId: testUserId, toolUsed: "T1", prompt: "p", response: "r", timestamp: Date(timeIntervalSince1970: 1000))
        let sug2 = AISuggestion(userId: testUserId, toolUsed: "T2", prompt: "p", response: "r", timestamp: Date(timeIntervalSince1970: 3000))
        let sug3 = AISuggestion(userId: testUserId, toolUsed: "T3", prompt: "p", response: "r", timestamp: Date(timeIntervalSince1970: 2000))

        try databaseManager.insertAISuggestion(sug1)
        try databaseManager.insertAISuggestion(sug2)
        try databaseManager.insertAISuggestion(sug3)

        let retrieved = try databaseManager.getAISuggestions(userId: testUserId)
        XCTAssertEqual(retrieved.count, 3)
        XCTAssertEqual(retrieved[0].toolUsed, "T2") // Most recent first
        XCTAssertEqual(retrieved[1].toolUsed, "T3")
        XCTAssertEqual(retrieved[2].toolUsed, "T1")
    }

    func testUnicodeCharactersInText() throws {
        let unicodeText = "Testing with emoji 😀🎉 and unicode: 你好世界 مرحبا العالم"

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

    func testIssueWithUnicodeContent() throws {
        let documentId = UUID()
        let issue = Issue(
            documentId: documentId,
            title: "Unicode Title 日本語 العربية",
            description: "Description with 🚀 emojis and ñ special chars",
            status: .open,
            priority: .low
        )

        try databaseManager.insertIssue(issue)

        let retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertTrue(retrieved.first!.title.contains("日本語"))
        XCTAssertTrue(retrieved.first!.description.contains("🚀"))
    }

    func testGetAllIssuesPagination() throws {
        for i in 1...30 {
            let issue = Issue(
                documentId: UUID(),
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
        XCTAssertEqual(thirdPage.count, 10)
        XCTAssertNotEqual(firstPage.first?.id, secondPage.first?.id)
    }

    func testDefaultDatabasePath() throws {
        let defaultDB = DatabaseManager()
        try defaultDB.initialize()

        let suggestion = AISuggestion(
            userId: testUserId,
            toolUsed: "Default Path Test",
            prompt: "test",
            response: "test"
        )

        try defaultDB.insertAISuggestion(suggestion)
        let retrieved = try defaultDB.getAISuggestions(userId: testUserId)
        XCTAssertEqual(retrieved.count, 1)

        defaultDB.close()
    }

    func testMultipleUpdatesToSameAISuggestion() throws {
        var suggestion = AISuggestion(
            userId: testUserId,
            toolUsed: "Update Test",
            prompt: "original",
            response: "original response"
        )

        try databaseManager.insertAISuggestion(suggestion)

        // First update
        suggestion.isApplied = true
        try databaseManager.updateAISuggestion(suggestion)

        // Second update
        suggestion.isApplied = false
        try databaseManager.updateAISuggestion(suggestion)

        let retrieved = try databaseManager.getAISuggestions(userId: testUserId)
        XCTAssertEqual(retrieved.first?.isApplied, false)
    }

    func testMultipleUpdatesToSameUserSession() throws {
        var session = UserSession(
            userId: testUserId,
            startTime: Date(),
            wordsWritten: 100
        )

        try databaseManager.insertUserSession(session)

        session.wordsWritten = 200
        try databaseManager.updateUserSession(session)

        session.wordsWritten = 300
        session.aiInteractions = 5
        try databaseManager.updateUserSession(session)

        let retrieved = try databaseManager.getUserSessions(userId: testUserId)
        XCTAssertEqual(retrieved.first?.wordsWritten, 300)
        XCTAssertEqual(retrieved.first?.aiInteractions, 5)
    }

    func testIssueWithMultipleTags() throws {
        let documentId = UUID()
        var issue = Issue(
            documentId: documentId,
            title: "Multi-tag issue",
            status: .open,
            priority: .low
        )
        issue.metadata.tags = ["tag1", "tag2", "tag3", "tag4", "tag5"]

        try databaseManager.insertIssue(issue)

        let retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(retrieved.first?.metadata.tags.count, 5)
        XCTAssertTrue(retrieved.first!.metadata.tags.contains("tag1"))
        XCTAssertTrue(retrieved.first!.metadata.tags.contains("tag5"))
    }

    func testZeroLimitPagination() throws {
        let suggestion = AISuggestion(userId: testUserId, toolUsed: "Test", prompt: "p", response: "r")
        try databaseManager.insertAISuggestion(suggestion)

        // Limit of 0 should return 0 results
        let results = try databaseManager.getAISuggestions(userId: testUserId, limit: 0, offset: 0)
        XCTAssertEqual(results.count, 0)
    }

    func testHighOffsetPagination() throws {
        let suggestion = AISuggestion(userId: testUserId, toolUsed: "Test", prompt: "p", response: "r")
        try databaseManager.insertAISuggestion(suggestion)

        // Offset beyond available data
        let results = try databaseManager.getAISuggestions(userId: testUserId, limit: 10, offset: 100)
        XCTAssertEqual(results.count, 0)
    }
}