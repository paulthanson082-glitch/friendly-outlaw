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
            name: "test_trace",
            startTime: Date(),
            metadata: "{\"key\": \"value\"}"
        )

        try databaseManager.insertTrace(trace)

        let retrieved = try databaseManager.getTraces()
        XCTAssertEqual(retrieved.count, 1)
        XCTAssertEqual(retrieved.first?.id, trace.id)
        XCTAssertEqual(retrieved.first?.sessionId, "session-123")
        XCTAssertEqual(retrieved.first?.name, "test_trace")
    }

    func testGetTracesFilteredBySession() throws {
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
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(120)

        let trace = Trace(
            sessionId: "session-456",
            name: "completed_trace",
            startTime: startTime,
            endTime: endTime,
            metadata: nil
        )

        try databaseManager.insertTrace(trace)

        let retrieved = try databaseManager.getTraces()
        XCTAssertEqual(retrieved.count, 1)
        XCTAssertNotNil(retrieved.first?.endTime)
        XCTAssertEqual(retrieved.first?.durationSeconds, 120.0, accuracy: 1.0)
    }

    func testTraceWithoutMetadata() throws {
        let trace = Trace(
            sessionId: "session-789",
            name: "simple_trace",
            metadata: nil
        )

        try databaseManager.insertTrace(trace)

        let retrieved = try databaseManager.getTraces()
        XCTAssertEqual(retrieved.count, 1)
        XCTAssertNil(retrieved.first?.metadata)
    }

    // MARK: - Observation Tests

    func testInsertAndRetrieveObservation() throws {
        let trace = Trace(sessionId: "session-1", name: "parent_trace")
        try databaseManager.insertTrace(trace)

        let observation = Observation(
            traceId: trace.id,
            name: "tool_call",
            input: "{\"query\": \"test\"}",
            output: "{\"result\": \"success\"}",
            statusMessage: "completed"
        )

        try databaseManager.insertObservation(observation)

        let retrieved = try databaseManager.getObservations(traceId: trace.id)
        XCTAssertEqual(retrieved.count, 1)
        XCTAssertEqual(retrieved.first?.id, observation.id)
        XCTAssertEqual(retrieved.first?.name, "tool_call")
        XCTAssertEqual(retrieved.first?.input, "{\"query\": \"test\"}")
    }

    func testMultipleObservationsForTrace() throws {
        let trace = Trace(sessionId: "session-2", name: "multi_obs_trace")
        try databaseManager.insertTrace(trace)

        let obs1 = Observation(traceId: trace.id, name: "step1")
        let obs2 = Observation(traceId: trace.id, name: "step2")
        let obs3 = Observation(traceId: trace.id, name: "step3")

        try databaseManager.insertObservation(obs1)
        try databaseManager.insertObservation(obs2)
        try databaseManager.insertObservation(obs3)

        let retrieved = try databaseManager.getObservations(traceId: trace.id)
        XCTAssertEqual(retrieved.count, 3)

        let names = retrieved.map { $0.name }
        XCTAssertTrue(names.contains("step1"))
        XCTAssertTrue(names.contains("step2"))
        XCTAssertTrue(names.contains("step3"))
    }

    func testObservationWithEndTime() throws {
        let trace = Trace(sessionId: "session-3", name: "timed_trace")
        try databaseManager.insertTrace(trace)

        let startTime = Date()
        let endTime = startTime.addingTimeInterval(5)

        let observation = Observation(
            traceId: trace.id,
            name: "timed_observation",
            startTime: startTime,
            endTime: endTime
        )

        try databaseManager.insertObservation(observation)

        let retrieved = try databaseManager.getObservations(traceId: trace.id)
        XCTAssertEqual(retrieved.count, 1)
        XCTAssertNotNil(retrieved.first?.endTime)
    }

    func testObservationWithNullFields() throws {
        let trace = Trace(sessionId: "session-4", name: "minimal_trace")
        try databaseManager.insertTrace(trace)

        let observation = Observation(
            traceId: trace.id,
            name: "minimal_obs",
            input: nil,
            output: nil,
            statusMessage: nil
        )

        try databaseManager.insertObservation(observation)

        let retrieved = try databaseManager.getObservations(traceId: trace.id)
        XCTAssertEqual(retrieved.count, 1)
        XCTAssertNil(retrieved.first?.input)
        XCTAssertNil(retrieved.first?.output)
        XCTAssertNil(retrieved.first?.statusMessage)
    }

    // MARK: - Issue Tests

    func testInsertAndRetrieveIssue() throws {
        let documentId = UUID()
        let issue = Issue(
            documentId: documentId,
            title: "Test Issue",
            description: "This is a test issue",
            status: .open,
            priority: .medium
        )

        try databaseManager.insertIssue(issue)

        let retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(retrieved.count, 1)
        XCTAssertEqual(retrieved.first?.id, issue.id)
        XCTAssertEqual(retrieved.first?.title, "Test Issue")
        XCTAssertEqual(retrieved.first?.status, .open)
        XCTAssertEqual(retrieved.first?.priority, .medium)
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
        issue.priority = .high
        issue.metadata.resolvedAt = Date()

        try databaseManager.updateIssue(issue)

        let retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(retrieved.first?.title, "Updated Title")
        XCTAssertEqual(retrieved.first?.description, "Updated Description")
        XCTAssertEqual(retrieved.first?.status, .resolved)
        XCTAssertEqual(retrieved.first?.priority, .high)
        XCTAssertNotNil(retrieved.first?.metadata.resolvedAt)
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

        let issue1 = Issue(documentId: documentId, title: "Open Issue", status: .open)
        let issue2 = Issue(documentId: documentId, title: "In Progress Issue", status: .inProgress)
        let issue3 = Issue(documentId: documentId, title: "Resolved Issue", status: .resolved)
        let issue4 = Issue(documentId: documentId, title: "Another Open", status: .open)

        try databaseManager.insertIssue(issue1)
        try databaseManager.insertIssue(issue2)
        try databaseManager.insertIssue(issue3)
        try databaseManager.insertIssue(issue4)

        let openIssues = try databaseManager.getIssues(withStatus: .open)
        XCTAssertEqual(openIssues.count, 2)
        XCTAssertTrue(openIssues.allSatisfy { $0.status == .open })

        let resolvedIssues = try databaseManager.getIssues(withStatus: .resolved)
        XCTAssertEqual(resolvedIssues.count, 1)
        XCTAssertEqual(resolvedIssues.first?.status, .resolved)
    }

    func testGetAllIssuesWithPagination() throws {
        let documentId = UUID()

        for i in 1...25 {
            let issue = Issue(documentId: documentId, title: "Issue \(i)")
            try databaseManager.insertIssue(issue)
        }

        let firstPage = try databaseManager.getAllIssues(limit: 10, offset: 0)
        XCTAssertEqual(firstPage.count, 10)

        let secondPage = try databaseManager.getAllIssues(limit: 10, offset: 10)
        XCTAssertEqual(secondPage.count, 10)

        let thirdPage = try databaseManager.getAllIssues(limit: 10, offset: 20)
        XCTAssertEqual(thirdPage.count, 5)
    }

    func testIssueWithTags() throws {
        let documentId = UUID()
        var metadata = IssueMetadata()
        metadata.tags = ["bug", "urgent", "frontend"]

        let issue = Issue(
            documentId: documentId,
            title: "Tagged Issue",
            metadata: metadata
        )

        try databaseManager.insertIssue(issue)

        let retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(retrieved.first?.metadata.tags.count, 3)
        XCTAssertTrue(retrieved.first?.metadata.tags.contains("bug") ?? false)
        XCTAssertTrue(retrieved.first?.metadata.tags.contains("urgent") ?? false)
    }

    func testIssueWithNotes() throws {
        let documentId = UUID()
        var metadata = IssueMetadata()
        metadata.notes = "This is an important note about the issue."

        let issue = Issue(
            documentId: documentId,
            title: "Issue with Notes",
            metadata: metadata
        )

        try databaseManager.insertIssue(issue)

        let retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(retrieved.first?.metadata.notes, "This is an important note about the issue.")
    }

    // MARK: - Edge Case Tests

    func testDatabaseNotInitializedError() throws {
        let uninitializedDB = DatabaseManager(databasePath: "/tmp/not_initialized.db")

        let suggestion = AISuggestion(
            userId: testUserId,
            toolUsed: "Test",
            prompt: "Test",
            response: "Test"
        )

        XCTAssertThrowsError(try uninitializedDB.insertAISuggestion(suggestion)) { error in
            XCTAssertTrue(error is DatabaseError)
            if case DatabaseError.notInitialized = error {
                // Expected error
            } else {
                XCTFail("Expected notInitialized error")
            }
        }
    }

    func testEmptyResultSets() throws {
        let nonExistentUserId = UUID()

        let suggestions = try databaseManager.getAISuggestions(userId: nonExistentUserId)
        XCTAssertEqual(suggestions.count, 0)

        let sessions = try databaseManager.getUserSessions(userId: nonExistentUserId)
        XCTAssertEqual(sessions.count, 0)

        let config = try databaseManager.getAIConfiguration(userId: nonExistentUserId)
        XCTAssertNil(config)
    }

    func testNullableFieldsHandling() throws {
        // Test suggestion with null documentId
        let suggestion = AISuggestion(
            userId: testUserId,
            documentId: nil,
            toolUsed: "Test Tool",
            prompt: "Test Prompt",
            response: "Test Response"
        )

        try databaseManager.insertAISuggestion(suggestion)
        let retrieved = try databaseManager.getAISuggestions(userId: testUserId)
        XCTAssertNil(retrieved.first?.documentId)

        // Test session with null endTime
        let session = UserSession(
            userId: testUserId,
            endTime: nil,
            durationSeconds: nil
        )

        try databaseManager.insertUserSession(session)
        let retrievedSessions = try databaseManager.getUserSessions(userId: testUserId)
        XCTAssertNil(retrievedSessions.first?.endTime)
        XCTAssertNil(retrievedSessions.first?.durationSeconds)
    }

    func testLargeTextFields() throws {
        let largePrompt = String(repeating: "This is a very long prompt. ", count: 1000)
        let largeResponse = String(repeating: "This is a very long response. ", count: 1000)

        let suggestion = AISuggestion(
            userId: testUserId,
            toolUsed: "Continue Writing",
            prompt: largePrompt,
            response: largeResponse
        )

        try databaseManager.insertAISuggestion(suggestion)

        let retrieved = try databaseManager.getAISuggestions(userId: testUserId)
        XCTAssertEqual(retrieved.first?.prompt, largePrompt)
        XCTAssertEqual(retrieved.first?.response, largeResponse)
    }

    func testConcurrentAccess() throws {
        let expectation = XCTestExpectation(description: "Concurrent inserts complete")
        expectation.expectedFulfillmentCount = 10

        DispatchQueue.concurrentPerform(iterations: 10) { index in
            let suggestion = AISuggestion(
                userId: testUserId,
                toolUsed: "Tool \(index)",
                prompt: "Prompt \(index)",
                response: "Response \(index)"
            )

            do {
                try databaseManager.insertAISuggestion(suggestion)
                expectation.fulfill()
            } catch {
                XCTFail("Concurrent insert failed: \(error)")
            }
        }

        wait(for: [expectation], timeout: 5.0)

        let retrieved = try databaseManager.getAISuggestions(userId: testUserId, limit: 100)
        XCTAssertEqual(retrieved.count, 10)
    }

    func testSpecialCharactersInText() throws {
        let specialChars = "Test with special chars: 🎉 \"quotes\" 'apostrophes' & < > \\ / 中文 العربية"

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

    func testSessionStatsWithNoSessions() throws {
        let nonExistentUserId = UUID()
        let stats = try databaseManager.getSessionStats(userId: nonExistentUserId)

        XCTAssertEqual(stats.totalSessions, 0)
        XCTAssertEqual(stats.totalDurationSeconds, 0)
        XCTAssertEqual(stats.averageDurationSeconds, 0.0)
        XCTAssertNil(stats.earliestSession)
        XCTAssertNil(stats.latestSession)
    }

    // MARK: - Additional Edge Cases and Regression Tests

    func testMultipleUsersIsolation() throws {
        let user1 = UUID()
        let user2 = UUID()

        // Create suggestions for both users
        let suggestion1 = AISuggestion(userId: user1, toolUsed: "Tool1", prompt: "Prompt1", response: "Response1")
        let suggestion2 = AISuggestion(userId: user2, toolUsed: "Tool2", prompt: "Prompt2", response: "Response2")

        try databaseManager.insertAISuggestion(suggestion1)
        try databaseManager.insertAISuggestion(suggestion2)

        // Verify isolation
        let user1Suggestions = try databaseManager.getAISuggestions(userId: user1)
        let user2Suggestions = try databaseManager.getAISuggestions(userId: user2)

        XCTAssertEqual(user1Suggestions.count, 1)
        XCTAssertEqual(user2Suggestions.count, 1)
        XCTAssertEqual(user1Suggestions.first?.toolUsed, "Tool1")
        XCTAssertEqual(user2Suggestions.first?.toolUsed, "Tool2")
    }

    func testDatabaseReinitializationPreservesData() throws {
        let suggestion = AISuggestion(
            userId: testUserId,
            toolUsed: "Persistent Tool",
            prompt: "Test",
            response: "Test"
        )

        try databaseManager.insertAISuggestion(suggestion)
        databaseManager.close()

        // Reinitialize with same path
        databaseManager = DatabaseManager(databasePath: testDatabasePath)
        try databaseManager.initialize()

        let retrieved = try databaseManager.getAISuggestions(userId: testUserId)
        XCTAssertEqual(retrieved.count, 1)
        XCTAssertEqual(retrieved.first?.toolUsed, "Persistent Tool")
    }

    func testInvalidUUIDHandling() throws {
        // Insert a valid suggestion
        let suggestion = AISuggestion(
            userId: testUserId,
            toolUsed: "Test",
            prompt: "Test",
            response: "Test"
        )
        try databaseManager.insertAISuggestion(suggestion)

        // Try to delete with non-existent UUID
        let nonExistentId = UUID()
        try databaseManager.deleteAISuggestion(id: nonExistentId)

        // Original should still exist
        let retrieved = try databaseManager.getAISuggestions(userId: testUserId)
        XCTAssertEqual(retrieved.count, 1)
    }

    func testZeroPaginationLimit() throws {
        for i in 1...5 {
            let suggestion = AISuggestion(
                userId: testUserId,
                toolUsed: "Tool \(i)",
                prompt: "Test",
                response: "Test"
            )
            try databaseManager.insertAISuggestion(suggestion)
        }

        // Request with limit 0 should return empty
        let results = try databaseManager.getAISuggestions(userId: testUserId, limit: 0)
        XCTAssertEqual(results.count, 0)
    }

    func testLargeOffsetPagination() throws {
        for i in 1...10 {
            let suggestion = AISuggestion(
                userId: testUserId,
                toolUsed: "Tool \(i)",
                prompt: "Test",
                response: "Test"
            )
            try databaseManager.insertAISuggestion(suggestion)
        }

        // Request with offset beyond available data
        let results = try databaseManager.getAISuggestions(userId: testUserId, limit: 10, offset: 100)
        XCTAssertEqual(results.count, 0)
    }

    func testUpdateNonExistentAISuggestion() throws {
        let nonExistentSuggestion = AISuggestion(
            id: UUID(),
            userId: testUserId,
            toolUsed: "Test",
            prompt: "Test",
            response: "Test"
        )

        // Update should not throw but also not affect anything
        try databaseManager.updateAISuggestion(nonExistentSuggestion)

        let retrieved = try databaseManager.getAISuggestions(userId: testUserId)
        XCTAssertEqual(retrieved.count, 0)
    }

    func testSessionWithZeroDuration() throws {
        let session = UserSession(
            userId: testUserId,
            durationSeconds: 0
        )

        try databaseManager.insertUserSession(session)

        let retrieved = try databaseManager.getUserSessions(userId: testUserId)
        XCTAssertEqual(retrieved.first?.durationSeconds, 0)
    }

    func testSessionWithNegativeValues() throws {
        let session = UserSession(
            userId: testUserId,
            wordsWritten: -100,
            aiInteractions: -5
        )

        try databaseManager.insertUserSession(session)

        let retrieved = try databaseManager.getUserSessions(userId: testUserId)
        XCTAssertEqual(retrieved.first?.wordsWritten, -100)
        XCTAssertEqual(retrieved.first?.aiInteractions, -5)
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

    func testFilterByNonExistentTool() throws {
        let suggestion = AISuggestion(
            userId: testUserId,
            toolUsed: "Existing Tool",
            prompt: "Test",
            response: "Test"
        )
        try databaseManager.insertAISuggestion(suggestion)

        let filtered = try databaseManager.filterAISuggestionsByTool(userId: testUserId, tool: "NonExistent Tool")
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

    func testMultipleIssuesForSameDocument() throws {
        let documentId = UUID()

        let issues = [
            Issue(documentId: documentId, title: "Issue 1", priority: .low),
            Issue(documentId: documentId, title: "Issue 2", priority: .medium),
            Issue(documentId: documentId, title: "Issue 3", priority: .high),
            Issue(documentId: documentId, title: "Issue 4", priority: .critical)
        ]

        for issue in issues {
            try databaseManager.insertIssue(issue)
        }

        let retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(retrieved.count, 4)
    }

    func testIssueStatusTransitions() throws {
        let documentId = UUID()
        var issue = Issue(documentId: documentId, title: "Status Test", status: .open)

        try databaseManager.insertIssue(issue)

        // Transition through various states
        let statuses: [IssueStatus] = [.inProgress, .resolved, .closed, .open]
        for status in statuses {
            issue.status = status
            if status == .resolved || status == .closed {
                issue.metadata.resolvedAt = Date()
            } else {
                issue.metadata.resolvedAt = nil
            }
            try databaseManager.updateIssue(issue)

            let retrieved = try databaseManager.getIssues(forDocument: documentId)
            XCTAssertEqual(retrieved.first?.status, status)
        }
    }

    func testTraceWithVeryLongMetadata() throws {
        let longMetadata = String(repeating: "{\"key\": \"value\", \"data\": \"content\"}", count: 100)
        let trace = Trace(
            sessionId: "test-session",
            name: "long_metadata_trace",
            metadata: longMetadata
        )

        try databaseManager.insertTrace(trace)

        let retrieved = try databaseManager.getTraces()
        XCTAssertEqual(retrieved.first?.metadata, longMetadata)
    }

    func testObservationsOrderedByStartTime() throws {
        let trace = Trace(sessionId: "ordered-session", name: "ordering_test")
        try databaseManager.insertTrace(trace)

        let baseTime = Date()
        let obs1 = Observation(traceId: trace.id, name: "third", startTime: baseTime.addingTimeInterval(20))
        let obs2 = Observation(traceId: trace.id, name: "first", startTime: baseTime)
        let obs3 = Observation(traceId: trace.id, name: "second", startTime: baseTime.addingTimeInterval(10))

        try databaseManager.insertObservation(obs1)
        try databaseManager.insertObservation(obs2)
        try databaseManager.insertObservation(obs3)

        let retrieved = try databaseManager.getObservations(traceId: trace.id)
        XCTAssertEqual(retrieved.count, 3)
        XCTAssertEqual(retrieved[0].name, "first")
        XCTAssertEqual(retrieved[1].name, "second")
        XCTAssertEqual(retrieved[2].name, "third")
    }

    func testDuplicateInsertWithSameId() throws {
        let suggestion = AISuggestion(
            id: UUID(),
            userId: testUserId,
            toolUsed: "Test",
            prompt: "Test",
            response: "Test"
        )

        try databaseManager.insertAISuggestion(suggestion)

        // Trying to insert with same ID should fail
        XCTAssertThrowsError(try databaseManager.insertAISuggestion(suggestion)) { error in
            XCTAssertTrue(error is DatabaseError)
        }
    }

    func testGetObservationsForNonExistentTrace() throws {
        let nonExistentTraceId = UUID()
        let observations = try databaseManager.getObservations(traceId: nonExistentTraceId)
        XCTAssertEqual(observations.count, 0)
    }

    func testIssueWithEmptyTagsArray() throws {
        let documentId = UUID()
        var metadata = IssueMetadata()
        metadata.tags = []

        let issue = Issue(
            documentId: documentId,
            title: "No Tags Issue",
            metadata: metadata
        )

        try databaseManager.insertIssue(issue)

        let retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(retrieved.first?.metadata.tags.count, 0)
    }

    func testAIConfigurationWithExtremeValues() throws {
        let config = AIConfiguration(
            apiKey: String(repeating: "x", count: 1000),
            model: .claude35Sonnet,
            maxTokens: 200000,
            temperature: 2.0
        )

        try databaseManager.saveAIConfiguration(userId: testUserId, configuration: config)

        let retrieved = try databaseManager.getAIConfiguration(userId: testUserId)
        XCTAssertEqual(retrieved?.maxTokens, 200000)
        XCTAssertEqual(retrieved?.temperature, 2.0)
    }

    func testTimestampPrecision() throws {
        let preciseTime = Date(timeIntervalSince1970: 1234567890.123456)
        let session = UserSession(
            userId: testUserId,
            startTime: preciseTime
        )

        try databaseManager.insertUserSession(session)

        let retrieved = try databaseManager.getUserSessions(userId: testUserId)
        let retrievedTime = retrieved.first?.startTime.timeIntervalSince1970 ?? 0
        let originalTime = preciseTime.timeIntervalSince1970

        // SQLite stores timestamps as REAL, so we should have good precision
        XCTAssertEqual(retrievedTime, originalTime, accuracy: 0.001)
    }

    func testGetAIToolUsageStatsOrdering() throws {
        let toolCounts = [
            ("Tool A", 5),
            ("Tool B", 10),
            ("Tool C", 3),
            ("Tool D", 15)
        ]

        for (tool, count) in toolCounts {
            for _ in 0..<count {
                let suggestion = AISuggestion(
                    userId: testUserId,
                    toolUsed: tool,
                    prompt: "Test",
                    response: "Test"
                )
                try databaseManager.insertAISuggestion(suggestion)
            }
        }

        let stats = try databaseManager.getAIToolUsageStats(userId: testUserId)

        // Should be ordered by usage count descending
        XCTAssertEqual(stats[0].toolName, "Tool D")
        XCTAssertEqual(stats[0].usageCount, 15)
        XCTAssertEqual(stats[1].toolName, "Tool B")
        XCTAssertEqual(stats[1].usageCount, 10)
        XCTAssertEqual(stats[2].toolName, "Tool A")
        XCTAssertEqual(stats[2].usageCount, 5)
        XCTAssertEqual(stats[3].toolName, "Tool C")
        XCTAssertEqual(stats[3].usageCount, 3)
    }
}