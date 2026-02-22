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

    func testGetAIConfigurationReturnsNilForNonExistentUser() throws {
        let randomUserId = UUID()
        let retrieved = try databaseManager.getAIConfiguration(userId: randomUserId)
        XCTAssertNil(retrieved)
    }

    // MARK: - Trace Operations Tests

    func testInsertAndRetrieveTrace() throws {
        let trace = Trace(
            sessionId: "test-session-123",
            name: "writing-session",
            startTime: Date()
        )

        try databaseManager.insertTrace(trace)

        let retrieved = try databaseManager.getTraces(sessionId: "test-session-123")
        XCTAssertEqual(retrieved.count, 1)
        XCTAssertEqual(retrieved.first?.id, trace.id)
        XCTAssertEqual(retrieved.first?.name, "writing-session")
        XCTAssertEqual(retrieved.first?.sessionId, "test-session-123")
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

    func testGetTracesFilteredBySessionId() throws {
        let trace1 = Trace(sessionId: "session-alpha", name: "trace-1")
        let trace2 = Trace(sessionId: "session-beta", name: "trace-2")
        let trace3 = Trace(sessionId: "session-alpha", name: "trace-3")

        try databaseManager.insertTrace(trace1)
        try databaseManager.insertTrace(trace2)
        try databaseManager.insertTrace(trace3)

        let filtered = try databaseManager.getTraces(sessionId: "session-alpha")
        XCTAssertEqual(filtered.count, 2)
        XCTAssertTrue(filtered.allSatisfy { $0.sessionId == "session-alpha" })
    }

    func testTraceWithMetadata() throws {
        let metadata = "{\"user\": \"test-user\", \"context\": \"writing\"}"
        let trace = Trace(sessionId: "session-1", name: "test", metadata: metadata)

        try databaseManager.insertTrace(trace)

        let retrieved = try databaseManager.getTraces(sessionId: "session-1")
        XCTAssertEqual(retrieved.first?.metadata, metadata)
    }

    func testTraceWithEndTime() throws {
        let startTime = Date()
        let endTime = Date(timeIntervalSinceNow: 300)
        let trace = Trace(sessionId: "session-1", name: "test", startTime: startTime, endTime: endTime)

        try databaseManager.insertTrace(trace)

        let retrieved = try databaseManager.getTraces(sessionId: "session-1")
        XCTAssertNotNil(retrieved.first?.endTime)
    }

    // MARK: - Observation Operations Tests

    func testInsertAndRetrieveObservation() throws {
        let trace = Trace(sessionId: "session-1", name: "trace-1")
        try databaseManager.insertTrace(trace)

        let observation = Observation(
            traceId: trace.id,
            name: "edit-action",
            input: "edit request",
            output: "edit completed"
        )

        try databaseManager.insertObservation(observation)

        let retrieved = try databaseManager.getObservations(traceId: trace.id)
        XCTAssertEqual(retrieved.count, 1)
        XCTAssertEqual(retrieved.first?.id, observation.id)
        XCTAssertEqual(retrieved.first?.name, "edit-action")
    }

    func testMultipleObservationsForTrace() throws {
        let trace = Trace(sessionId: "session-1", name: "trace-1")
        try databaseManager.insertTrace(trace)

        let obs1 = Observation(traceId: trace.id, name: "obs-1", input: "input1", output: "output1")
        let obs2 = Observation(traceId: trace.id, name: "obs-2", input: "input2", output: "output2")
        let obs3 = Observation(traceId: trace.id, name: "obs-3", input: "input3", output: "output3")

        try databaseManager.insertObservation(obs1)
        try databaseManager.insertObservation(obs2)
        try databaseManager.insertObservation(obs3)

        let retrieved = try databaseManager.getObservations(traceId: trace.id)
        XCTAssertEqual(retrieved.count, 3)
    }

    func testObservationWithStatusMessage() throws {
        let trace = Trace(sessionId: "session-1", name: "trace-1")
        try databaseManager.insertTrace(trace)

        let observation = Observation(
            traceId: trace.id,
            name: "test-obs",
            statusMessage: "Completed successfully"
        )

        try databaseManager.insertObservation(observation)

        let retrieved = try databaseManager.getObservations(traceId: trace.id)
        XCTAssertEqual(retrieved.first?.statusMessage, "Completed successfully")
    }

    func testObservationWithNullableFields() throws {
        let trace = Trace(sessionId: "session-1", name: "trace-1")
        try databaseManager.insertTrace(trace)

        let observation = Observation(traceId: trace.id, name: "minimal-obs")

        try databaseManager.insertObservation(observation)

        let retrieved = try databaseManager.getObservations(traceId: trace.id)
        XCTAssertNil(retrieved.first?.endTime)
        XCTAssertNil(retrieved.first?.input)
        XCTAssertNil(retrieved.first?.output)
        XCTAssertNil(retrieved.first?.statusMessage)
    }

    // MARK: - Issue Operations Tests

    func testInsertAndRetrieveIssue() throws {
        let documentId = UUID()
        let issue = Issue(
            documentId: documentId,
            title: "Plot inconsistency",
            description: "Character appears in two places at once",
            status: .open,
            priority: .high
        )

        try databaseManager.insertIssue(issue)

        let retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(retrieved.count, 1)
        XCTAssertEqual(retrieved.first?.id, issue.id)
        XCTAssertEqual(retrieved.first?.title, "Plot inconsistency")
    }

    func testGetIssuesForDocument() throws {
        let docId1 = UUID()
        let docId2 = UUID()

        let issue1 = Issue(documentId: docId1, title: "Issue 1")
        let issue2 = Issue(documentId: docId1, title: "Issue 2")
        let issue3 = Issue(documentId: docId2, title: "Issue 3")

        try databaseManager.insertIssue(issue1)
        try databaseManager.insertIssue(issue2)
        try databaseManager.insertIssue(issue3)

        let doc1Issues = try databaseManager.getIssues(forDocument: docId1)
        XCTAssertEqual(doc1Issues.count, 2)
        XCTAssertTrue(doc1Issues.allSatisfy { $0.documentId == docId1 })
    }

    func testGetIssuesByStatus() throws {
        let docId = UUID()

        let issue1 = Issue(documentId: docId, title: "Open Issue 1", status: .open)
        let issue2 = Issue(documentId: docId, title: "Resolved Issue", status: .resolved)
        let issue3 = Issue(documentId: docId, title: "Open Issue 2", status: .open)
        let issue4 = Issue(documentId: docId, title: "Closed Issue", status: .closed)

        try databaseManager.insertIssue(issue1)
        try databaseManager.insertIssue(issue2)
        try databaseManager.insertIssue(issue3)
        try databaseManager.insertIssue(issue4)

        let openIssues = try databaseManager.getIssues(withStatus: .open)
        XCTAssertEqual(openIssues.count, 2)
        XCTAssertTrue(openIssues.allSatisfy { $0.status == .open })

        let resolvedIssues = try databaseManager.getIssues(withStatus: .resolved)
        XCTAssertEqual(resolvedIssues.count, 1)
    }

    func testGetAllIssues() throws {
        let docId = UUID()

        for i in 1...5 {
            let issue = Issue(documentId: docId, title: "Issue \(i)")
            try databaseManager.insertIssue(issue)
        }

        let allIssues = try databaseManager.getAllIssues()
        XCTAssertEqual(allIssues.count, 5)
    }

    func testUpdateIssue() throws {
        let docId = UUID()
        var issue = Issue(
            documentId: docId,
            title: "Original Title",
            description: "Original description",
            status: .open,
            priority: .low
        )

        try databaseManager.insertIssue(issue)

        issue.title = "Updated Title"
        issue.description = "Updated description"
        issue.status = .resolved
        issue.priority = .critical
        issue.metadata.notes = "Fixed the issue"

        try databaseManager.updateIssue(issue)

        let retrieved = try databaseManager.getIssues(forDocument: docId).first
        XCTAssertEqual(retrieved?.title, "Updated Title")
        XCTAssertEqual(retrieved?.description, "Updated description")
        XCTAssertEqual(retrieved?.status, .resolved)
        XCTAssertEqual(retrieved?.priority, .critical)
        XCTAssertEqual(retrieved?.metadata.notes, "Fixed the issue")
    }

    func testDeleteIssue() throws {
        let docId = UUID()
        let issue = Issue(documentId: docId, title: "To Delete")

        try databaseManager.insertIssue(issue)
        XCTAssertEqual(try databaseManager.getIssues(forDocument: docId).count, 1)

        try databaseManager.deleteIssue(id: issue.id)
        XCTAssertEqual(try databaseManager.getIssues(forDocument: docId).count, 0)
    }

    func testIssueWithTags() throws {
        let docId = UUID()
        var metadata = IssueMetadata()
        metadata.tags = ["bug", "high-priority", "chapter-3"]

        let issue = Issue(
            documentId: docId,
            title: "Tagged Issue",
            metadata: metadata
        )

        try databaseManager.insertIssue(issue)

        let retrieved = try databaseManager.getIssues(forDocument: docId).first
        XCTAssertEqual(retrieved?.metadata.tags.count, 3)
        XCTAssertTrue(retrieved?.metadata.tags.contains("bug") ?? false)
        XCTAssertTrue(retrieved?.metadata.tags.contains("high-priority") ?? false)
        XCTAssertTrue(retrieved?.metadata.tags.contains("chapter-3") ?? false)
    }

    func testIssueWithResolvedAt() throws {
        let docId = UUID()
        let resolvedDate = Date()
        var metadata = IssueMetadata()
        metadata.resolvedAt = resolvedDate

        let issue = Issue(
            documentId: docId,
            title: "Resolved Issue",
            status: .resolved,
            metadata: metadata
        )

        try databaseManager.insertIssue(issue)

        let retrieved = try databaseManager.getIssues(forDocument: docId).first
        XCTAssertNotNil(retrieved?.metadata.resolvedAt)
    }

    func testIssuePagination() throws {
        let docId = UUID()

        for i in 1...15 {
            let issue = Issue(documentId: docId, title: "Issue \(i)")
            try databaseManager.insertIssue(issue)
        }

        let page1 = try databaseManager.getIssues(forDocument: docId, limit: 10, offset: 0)
        XCTAssertEqual(page1.count, 10)

        let page2 = try databaseManager.getIssues(forDocument: docId, limit: 10, offset: 10)
        XCTAssertEqual(page2.count, 5)
    }

    // MARK: - Error Handling Tests

    func testOperationsFailWhenNotInitialized() {
        databaseManager.close()

        XCTAssertThrowsError(try databaseManager.getAISuggestions(userId: testUserId)) { error in
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

        XCTAssertThrowsError(try databaseManager.getUserSessions(userId: testUserId)) { error in
            XCTAssertTrue(error is DatabaseError)
        }
    }

    func testDatabaseErrorDescriptions() {
        let connectionError = DatabaseError.connectionFailed("Connection failed")
        XCTAssertTrue(connectionError.errorDescription?.contains("Connection failed") ?? false)

        let queryError = DatabaseError.queryFailed("Syntax error")
        XCTAssertTrue(queryError.errorDescription?.contains("Syntax error") ?? false)

        let invalidDataError = DatabaseError.invalidData("Invalid UUID")
        XCTAssertTrue(invalidDataError.errorDescription?.contains("Invalid UUID") ?? false)

        let notInitializedError = DatabaseError.notInitialized
        XCTAssertNotNil(notInitializedError.errorDescription)
    }

    // MARK: - Edge Cases Tests

    func testAISuggestionWithNullDocumentId() throws {
        let suggestion = AISuggestion(
            userId: testUserId,
            documentId: nil,
            toolUsed: "Tool",
            prompt: "Prompt",
            response: "Response"
        )

        try databaseManager.insertAISuggestion(suggestion)

        let retrieved = try databaseManager.getAISuggestions(userId: testUserId)
        XCTAssertNil(retrieved.first?.documentId)
    }

    func testUserSessionWithNullOptionalFields() throws {
        let session = UserSession(userId: testUserId)

        try databaseManager.insertUserSession(session)

        let retrieved = try databaseManager.getUserSessions(userId: testUserId)
        XCTAssertNil(retrieved.first?.endTime)
        XCTAssertNil(retrieved.first?.durationSeconds)
        XCTAssertNil(retrieved.first?.multitaskingMode)
    }

    func testLargeTextFields() throws {
        let largePrompt = String(repeating: "a", count: 5000)
        let largeResponse = String(repeating: "b", count: 5000)

        let suggestion = AISuggestion(
            userId: testUserId,
            toolUsed: "Test",
            prompt: largePrompt,
            response: largeResponse
        )

        try databaseManager.insertAISuggestion(suggestion)

        let retrieved = try databaseManager.getAISuggestions(userId: testUserId)
        XCTAssertEqual(retrieved.first?.prompt.count, 5000)
        XCTAssertEqual(retrieved.first?.response.count, 5000)
    }

    func testSpecialCharactersInStrings() throws {
        let specialChars = "Test with 'quotes', \"double quotes\", and special: @#$%^&*()"
        let suggestion = AISuggestion(
            userId: testUserId,
            toolUsed: specialChars,
            prompt: specialChars,
            response: specialChars
        )

        try databaseManager.insertAISuggestion(suggestion)

        let retrieved = try databaseManager.getAISuggestions(userId: testUserId)
        XCTAssertEqual(retrieved.first?.toolUsed, specialChars)
    }

    func testEmptyTags() throws {
        let docId = UUID()
        let issue = Issue(documentId: docId, title: "No Tags")

        try databaseManager.insertIssue(issue)

        let retrieved = try databaseManager.getIssues(forDocument: docId).first
        XCTAssertTrue(retrieved?.metadata.tags.isEmpty ?? false)
    }

    // MARK: - Integration Tests

    func testCompleteWorkflow() throws {
        let userId = UUID()
        let documentId = UUID()

        // Save AI configuration
        let config = AIConfiguration(apiKey: "test-key", model: .claude35Sonnet)
        try databaseManager.saveAIConfiguration(userId: userId, configuration: config)

        // Create user session
        let session = UserSession(userId: userId, wordsWritten: 500, aiInteractions: 10)
        try databaseManager.insertUserSession(session)

        // Add AI suggestion
        let suggestion = AISuggestion(
            userId: userId,
            documentId: documentId,
            toolUsed: "Continue Writing",
            prompt: "Write more",
            response: "Continued text"
        )
        try databaseManager.insertAISuggestion(suggestion)

        // Create trace and observation
        let trace = Trace(sessionId: session.id.uuidString, name: "writing-session")
        try databaseManager.insertTrace(trace)

        let observation = Observation(traceId: trace.id, name: "edit", input: "edit", output: "done")
        try databaseManager.insertObservation(observation)

        // Create issue
        let issue = Issue(documentId: documentId, title: "Fix plot", status: .open, priority: .high)
        try databaseManager.insertIssue(issue)

        // Verify all data
        XCTAssertNotNil(try databaseManager.getAIConfiguration(userId: userId))
        XCTAssertEqual(try databaseManager.getUserSessions(userId: userId).count, 1)
        XCTAssertEqual(try databaseManager.getAISuggestions(userId: userId).count, 1)
        XCTAssertEqual(try databaseManager.getTraces(sessionId: session.id.uuidString).count, 1)
        XCTAssertEqual(try databaseManager.getObservations(traceId: trace.id).count, 1)
        XCTAssertEqual(try databaseManager.getIssues(forDocument: documentId).count, 1)
    }
}