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

    // MARK: - Trace Operations Tests

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
        XCTAssertEqual(retrieved.first?.sessionId, "session-123")
        XCTAssertEqual(retrieved.first?.name, "Document Edit")
    }

    func testGetTracesBySessionId() throws {
        let session1 = "session-1"
        let session2 = "session-2"

        let trace1 = Trace(sessionId: session1, name: "Trace 1")
        let trace2 = Trace(sessionId: session1, name: "Trace 2")
        let trace3 = Trace(sessionId: session2, name: "Trace 3")

        try databaseManager.insertTrace(trace1)
        try databaseManager.insertTrace(trace2)
        try databaseManager.insertTrace(trace3)

        let session1Traces = try databaseManager.getTraces(sessionId: session1)
        XCTAssertEqual(session1Traces.count, 2)
        XCTAssertTrue(session1Traces.allSatisfy { $0.sessionId == session1 })

        let session2Traces = try databaseManager.getTraces(sessionId: session2)
        XCTAssertEqual(session2Traces.count, 1)
        XCTAssertEqual(session2Traces.first?.sessionId, session2)
    }

    func testTraceWithEndTime() throws {
        var trace = Trace(
            sessionId: "session-456",
            name: "Long Operation",
            startTime: Date()
        )
        trace.endTime = Date().addingTimeInterval(60) // 60 seconds later

        try databaseManager.insertTrace(trace)

        let retrieved = try databaseManager.getTraces()
        XCTAssertNotNil(retrieved.first?.endTime)
    }

    func testTraceWithMetadata() throws {
        var trace = Trace(
            sessionId: "session-789",
            name: "Complex Operation"
        )
        trace.metadata = "{\"key\": \"value\", \"count\": 42}"

        try databaseManager.insertTrace(trace)

        let retrieved = try databaseManager.getTraces()
        XCTAssertEqual(retrieved.first?.metadata, "{\"key\": \"value\", \"count\": 42}")
    }

    func testTracesOrderedByStartTime() throws {
        let now = Date()
        let trace1 = Trace(sessionId: "session-1", name: "Latest", startTime: now)
        let trace2 = Trace(sessionId: "session-1", name: "Middle", startTime: now.addingTimeInterval(-60))
        let trace3 = Trace(sessionId: "session-1", name: "Earliest", startTime: now.addingTimeInterval(-120))

        try databaseManager.insertTrace(trace3)
        try databaseManager.insertTrace(trace1)
        try databaseManager.insertTrace(trace2)

        let retrieved = try databaseManager.getTraces(sessionId: "session-1")
        XCTAssertEqual(retrieved.count, 3)
        XCTAssertEqual(retrieved[0].name, "Earliest")
        XCTAssertEqual(retrieved[1].name, "Middle")
        XCTAssertEqual(retrieved[2].name, "Latest")
    }

    // MARK: - Observation Operations Tests

    func testInsertAndRetrieveObservation() throws {
        let trace = Trace(sessionId: "session-obs", name: "Test Trace")
        try databaseManager.insertTrace(trace)

        let observation = Observation(
            traceId: trace.id,
            name: "tool_call",
            startTime: Date(),
            input: "test input",
            output: "test output"
        )

        try databaseManager.insertObservation(observation)

        let retrieved = try databaseManager.getObservations(traceId: trace.id)
        XCTAssertEqual(retrieved.count, 1)
        XCTAssertEqual(retrieved.first?.id, observation.id)
        XCTAssertEqual(retrieved.first?.name, "tool_call")
        XCTAssertEqual(retrieved.first?.input, "test input")
        XCTAssertEqual(retrieved.first?.output, "test output")
    }

    func testMultipleObservationsForTrace() throws {
        let trace = Trace(sessionId: "session-multi", name: "Trace with Observations")
        try databaseManager.insertTrace(trace)

        let obs1 = Observation(traceId: trace.id, name: "observation_1")
        let obs2 = Observation(traceId: trace.id, name: "observation_2")
        let obs3 = Observation(traceId: trace.id, name: "observation_3")

        try databaseManager.insertObservation(obs1)
        try databaseManager.insertObservation(obs2)
        try databaseManager.insertObservation(obs3)

        let retrieved = try databaseManager.getObservations(traceId: trace.id)
        XCTAssertEqual(retrieved.count, 3)
    }

    func testObservationWithOptionalFields() throws {
        let trace = Trace(sessionId: "session-optional", name: "Test Trace")
        try databaseManager.insertTrace(trace)

        var observation = Observation(traceId: trace.id, name: "minimal_observation")
        observation.endTime = Date()
        observation.statusMessage = "Completed successfully"

        try databaseManager.insertObservation(observation)

        let retrieved = try databaseManager.getObservations(traceId: trace.id)
        XCTAssertNotNil(retrieved.first?.endTime)
        XCTAssertEqual(retrieved.first?.statusMessage, "Completed successfully")
    }

    func testObservationsOrderedByStartTime() throws {
        let trace = Trace(sessionId: "session-ordered", name: "Test Trace")
        try databaseManager.insertTrace(trace)

        let now = Date()
        let obs1 = Observation(traceId: trace.id, name: "third", startTime: now)
        let obs2 = Observation(traceId: trace.id, name: "second", startTime: now.addingTimeInterval(-30))
        let obs3 = Observation(traceId: trace.id, name: "first", startTime: now.addingTimeInterval(-60))

        try databaseManager.insertObservation(obs1)
        try databaseManager.insertObservation(obs3)
        try databaseManager.insertObservation(obs2)

        let retrieved = try databaseManager.getObservations(traceId: trace.id)
        XCTAssertEqual(retrieved[0].name, "first")
        XCTAssertEqual(retrieved[1].name, "second")
        XCTAssertEqual(retrieved[2].name, "third")
    }

    func testObservationIsolationByTrace() throws {
        let trace1 = Trace(sessionId: "session-1", name: "Trace 1")
        let trace2 = Trace(sessionId: "session-2", name: "Trace 2")
        try databaseManager.insertTrace(trace1)
        try databaseManager.insertTrace(trace2)

        let obs1 = Observation(traceId: trace1.id, name: "obs_for_trace1")
        let obs2 = Observation(traceId: trace2.id, name: "obs_for_trace2")

        try databaseManager.insertObservation(obs1)
        try databaseManager.insertObservation(obs2)

        let trace1Obs = try databaseManager.getObservations(traceId: trace1.id)
        let trace2Obs = try databaseManager.getObservations(traceId: trace2.id)

        XCTAssertEqual(trace1Obs.count, 1)
        XCTAssertEqual(trace2Obs.count, 1)
        XCTAssertEqual(trace1Obs.first?.name, "obs_for_trace1")
        XCTAssertEqual(trace2Obs.first?.name, "obs_for_trace2")
    }

    // MARK: - Issue Operations Tests

    func testInsertAndRetrieveIssue() throws {
        let documentId = UUID()
        let issue = Issue(
            documentId: documentId,
            title: "Fix plot hole",
            description: "The character's motivation is unclear",
            status: .open,
            priority: .high
        )

        try databaseManager.insertIssue(issue)

        let retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(retrieved.count, 1)
        XCTAssertEqual(retrieved.first?.id, issue.id)
        XCTAssertEqual(retrieved.first?.title, "Fix plot hole")
        XCTAssertEqual(retrieved.first?.priority, .high)
    }

    func testUpdateIssue() throws {
        let documentId = UUID()
        var issue = Issue(
            documentId: documentId,
            title: "Original Title",
            description: "Original description",
            status: .open
        )

        try databaseManager.insertIssue(issue)

        issue.title = "Updated Title"
        issue.description = "Updated description"
        issue.status = .resolved
        issue.metadata.resolvedAt = Date()

        try databaseManager.updateIssue(issue)

        let retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(retrieved.first?.title, "Updated Title")
        XCTAssertEqual(retrieved.first?.description, "Updated description")
        XCTAssertEqual(retrieved.first?.status, .resolved)
        XCTAssertNotNil(retrieved.first?.metadata.resolvedAt)
    }

    func testDeleteIssue() throws {
        let documentId = UUID()
        let issue = Issue(documentId: documentId, title: "To be deleted")

        try databaseManager.insertIssue(issue)

        var retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(retrieved.count, 1)

        try databaseManager.deleteIssue(id: issue.id)

        retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(retrieved.count, 0)
    }

    func testGetIssuesByStatus() throws {
        let docId = UUID()
        let issue1 = Issue(documentId: docId, title: "Open Issue", status: .open)
        let issue2 = Issue(documentId: docId, title: "In Progress Issue", status: .inProgress)
        let issue3 = Issue(documentId: docId, title: "Another Open Issue", status: .open)

        try databaseManager.insertIssue(issue1)
        try databaseManager.insertIssue(issue2)
        try databaseManager.insertIssue(issue3)

        let openIssues = try databaseManager.getIssues(withStatus: .open)
        XCTAssertEqual(openIssues.count, 2)
        XCTAssertTrue(openIssues.allSatisfy { $0.status == .open })

        let inProgressIssues = try databaseManager.getIssues(withStatus: .inProgress)
        XCTAssertEqual(inProgressIssues.count, 1)
        XCTAssertEqual(inProgressIssues.first?.title, "In Progress Issue")
    }

    func testGetAllIssues() throws {
        let doc1 = UUID()
        let doc2 = UUID()

        try databaseManager.insertIssue(Issue(documentId: doc1, title: "Issue 1"))
        try databaseManager.insertIssue(Issue(documentId: doc1, title: "Issue 2"))
        try databaseManager.insertIssue(Issue(documentId: doc2, title: "Issue 3"))

        let allIssues = try databaseManager.getAllIssues()
        XCTAssertEqual(allIssues.count, 3)
    }

    func testIssueWithTags() throws {
        let documentId = UUID()
        var issue = Issue(documentId: documentId, title: "Tagged Issue")
        issue.metadata.tags = ["plot", "character-development", "urgent"]
        issue.metadata.notes = "Need to address this in chapter 5"

        try databaseManager.insertIssue(issue)

        let retrieved = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(retrieved.first?.metadata.tags.count, 3)
        XCTAssertTrue(retrieved.first?.metadata.tags.contains("plot") ?? false)
        XCTAssertEqual(retrieved.first?.metadata.notes, "Need to address this in chapter 5")
    }

    func testIssuePagination() throws {
        let documentId = UUID()

        for i in 1...25 {
            let issue = Issue(documentId: documentId, title: "Issue \(i)")
            try databaseManager.insertIssue(issue)
        }

        let page1 = try databaseManager.getIssues(forDocument: documentId, limit: 10, offset: 0)
        XCTAssertEqual(page1.count, 10)

        let page2 = try databaseManager.getIssues(forDocument: documentId, limit: 10, offset: 10)
        XCTAssertEqual(page2.count, 10)

        let page3 = try databaseManager.getIssues(forDocument: documentId, limit: 10, offset: 20)
        XCTAssertEqual(page3.count, 5)

        // Verify no overlap
        XCTAssertNotEqual(page1.first?.id, page2.first?.id)
    }

    func testIssueWithAllPriorities() throws {
        let documentId = UUID()

        for priority in IssuePriority.allCases {
            let issue = Issue(documentId: documentId, title: "Priority: \(priority.rawValue)", priority: priority)
            try databaseManager.insertIssue(issue)
        }

        let allIssues = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(allIssues.count, 4)

        let priorities = Set(allIssues.map { $0.priority })
        XCTAssertEqual(priorities.count, 4)
    }

    func testIssueWithAllStatuses() throws {
        let documentId = UUID()

        for status in IssueStatus.allCases {
            let issue = Issue(documentId: documentId, title: "Status: \(status.rawValue)", status: status)
            try databaseManager.insertIssue(issue)
        }

        let allIssues = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(allIssues.count, 4)

        let statuses = Set(allIssues.map { $0.status })
        XCTAssertEqual(statuses.count, 4)
    }

    func testIssueTimestamps() throws {
        let documentId = UUID()
        let issue = Issue(documentId: documentId, title: "Timestamped Issue")

        let beforeInsert = Date()
        try databaseManager.insertIssue(issue)
        let afterInsert = Date()

        let retrieved = try databaseManager.getIssues(forDocument: documentId).first
        XCTAssertNotNil(retrieved?.metadata.created)
        XCTAssertGreaterThanOrEqual(retrieved!.metadata.created, beforeInsert.addingTimeInterval(-1))
        XCTAssertLessThanOrEqual(retrieved!.metadata.created, afterInsert.addingTimeInterval(1))
    }

    // MARK: - Edge Cases and Error Handling

    func testQueryBeforeInitialize() {
        let uninitializedDb = DatabaseManager(databasePath: "/tmp/test_uninitialized.db")

        XCTAssertThrowsError(try uninitializedDb.getAISuggestions(userId: testUserId)) { error in
            XCTAssertTrue(error is DatabaseError)
        }
    }

    func testEmptyResultSets() throws {
        let nonExistentUser = UUID()
        let nonExistentTrace = UUID()
        let nonExistentDocument = UUID()

        let suggestions = try databaseManager.getAISuggestions(userId: nonExistentUser)
        XCTAssertTrue(suggestions.isEmpty)

        let sessions = try databaseManager.getUserSessions(userId: nonExistentUser)
        XCTAssertTrue(sessions.isEmpty)

        let observations = try databaseManager.getObservations(traceId: nonExistentTrace)
        XCTAssertTrue(observations.isEmpty)

        let issues = try databaseManager.getIssues(forDocument: nonExistentDocument)
        XCTAssertTrue(issues.isEmpty)
    }

    func testNullableFields() throws {
        let suggestion = AISuggestion(
            userId: testUserId,
            documentId: nil, // Nullable field
            toolUsed: "Test Tool",
            prompt: "Test prompt",
            response: "Test response"
        )

        try databaseManager.insertAISuggestion(suggestion)

        let retrieved = try databaseManager.getAISuggestions(userId: testUserId)
        XCTAssertNil(retrieved.first?.documentId)
    }
}