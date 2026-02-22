import XCTest
@testable import WritersApp
import Foundation

final class DatabaseManagerTests: XCTestCase {
    var databaseManager: DatabaseManager!
    var tempDatabasePath: String!

    override func setUp() {
        super.setUp()
        // Create a temporary database for testing
        let tempDir = FileManager.default.temporaryDirectory
        tempDatabasePath = tempDir.appendingPathComponent("test_\(UUID().uuidString).db").path
        databaseManager = DatabaseManager(databasePath: tempDatabasePath)
        try! databaseManager.initialize()
    }

    override func tearDown() {
        databaseManager.close()
        // Clean up temporary database file
        try? FileManager.default.removeItem(atPath: tempDatabasePath)
        databaseManager = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testDatabaseInitializationSucceeds() {
        // Database is already initialized in setUp
        XCTAssertNotNil(databaseManager)
    }

    func testDatabaseCloseAndReinitialize() throws {
        databaseManager.close()
        try databaseManager.initialize()
        // Should be able to perform operations after reinitializing
        let userId = UUID()
        let suggestion = AISuggestion(
            userId: userId,
            toolUsed: "Test Tool",
            prompt: "Test prompt",
            response: "Test response"
        )
        XCTAssertNoThrow(try databaseManager.insertAISuggestion(suggestion))
    }

    func testOperationWithoutInitializationThrowsError() {
        let uninitializedDB = DatabaseManager(databasePath: tempDatabasePath + "_uninit")
        let userId = UUID()
        let suggestion = AISuggestion(
            userId: userId,
            toolUsed: "Test",
            prompt: "Test",
            response: "Test"
        )

        XCTAssertThrowsError(try uninitializedDB.insertAISuggestion(suggestion)) { error in
            XCTAssertTrue(error is DatabaseError)
            if case DatabaseError.notInitialized = error {
                // Expected error
            } else {
                XCTFail("Expected DatabaseError.notInitialized")
            }
        }
    }

    // MARK: - AI Suggestions Tests

    func testInsertAndRetrieveAISuggestion() throws {
        let userId = UUID()
        let documentId = UUID()
        let suggestion = AISuggestion(
            userId: userId,
            documentId: documentId,
            toolUsed: "Continue Writing",
            prompt: "Write more about dragons",
            response: "Dragons soared through the sky...",
            isApplied: false
        )

        try databaseManager.insertAISuggestion(suggestion)

        let suggestions = try databaseManager.getAISuggestions(userId: userId)
        XCTAssertEqual(suggestions.count, 1)
        XCTAssertEqual(suggestions.first?.id, suggestion.id)
        XCTAssertEqual(suggestions.first?.toolUsed, "Continue Writing")
        XCTAssertEqual(suggestions.first?.prompt, "Write more about dragons")
        XCTAssertEqual(suggestions.first?.isApplied, false)
    }

    func testInsertAISuggestionWithoutDocumentId() throws {
        let userId = UUID()
        let suggestion = AISuggestion(
            userId: userId,
            documentId: nil,
            toolUsed: "Brainstorm",
            prompt: "Ideas for a story",
            response: "1. Space adventure\n2. Mystery novel"
        )

        try databaseManager.insertAISuggestion(suggestion)

        let suggestions = try databaseManager.getAISuggestions(userId: userId)
        XCTAssertEqual(suggestions.count, 1)
        XCTAssertNil(suggestions.first?.documentId)
    }

    func testUpdateAISuggestion() throws {
        let userId = UUID()
        var suggestion = AISuggestion(
            userId: userId,
            toolUsed: "Improve Text",
            prompt: "Original text",
            response: "Improved text",
            isApplied: false
        )

        try databaseManager.insertAISuggestion(suggestion)

        suggestion.isApplied = true
        try databaseManager.updateAISuggestion(suggestion)

        let suggestions = try databaseManager.getAISuggestions(userId: userId)
        XCTAssertEqual(suggestions.first?.isApplied, true)
    }

    func testDeleteAISuggestion() throws {
        let userId = UUID()
        let suggestion = AISuggestion(
            userId: userId,
            toolUsed: "Test",
            prompt: "Test",
            response: "Test"
        )

        try databaseManager.insertAISuggestion(suggestion)
        var suggestions = try databaseManager.getAISuggestions(userId: userId)
        XCTAssertEqual(suggestions.count, 1)

        try databaseManager.deleteAISuggestion(id: suggestion.id)
        suggestions = try databaseManager.getAISuggestions(userId: userId)
        XCTAssertEqual(suggestions.count, 0)
    }

    func testGetAISuggestionsWithPagination() throws {
        let userId = UUID()

        // Insert 10 suggestions
        for i in 1...10 {
            let suggestion = AISuggestion(
                userId: userId,
                toolUsed: "Tool \(i)",
                prompt: "Prompt \(i)",
                response: "Response \(i)"
            )
            try databaseManager.insertAISuggestion(suggestion)
        }

        // Get first 5
        let firstPage = try databaseManager.getAISuggestions(userId: userId, limit: 5, offset: 0)
        XCTAssertEqual(firstPage.count, 5)

        // Get next 5
        let secondPage = try databaseManager.getAISuggestions(userId: userId, limit: 5, offset: 5)
        XCTAssertEqual(secondPage.count, 5)

        // Ensure no overlap
        let firstIds = Set(firstPage.map { $0.id })
        let secondIds = Set(secondPage.map { $0.id })
        XCTAssertTrue(firstIds.isDisjoint(with: secondIds))
    }

    func testFilterAISuggestionsByTool() throws {
        let userId = UUID()

        let suggestion1 = AISuggestion(userId: userId, toolUsed: "Continue Writing", prompt: "P1", response: "R1")
        let suggestion2 = AISuggestion(userId: userId, toolUsed: "Improve Text", prompt: "P2", response: "R2")
        let suggestion3 = AISuggestion(userId: userId, toolUsed: "Continue Writing", prompt: "P3", response: "R3")

        try databaseManager.insertAISuggestion(suggestion1)
        try databaseManager.insertAISuggestion(suggestion2)
        try databaseManager.insertAISuggestion(suggestion3)

        let filtered = try databaseManager.filterAISuggestionsByTool(userId: userId, tool: "Continue Writing")
        XCTAssertEqual(filtered.count, 2)
        XCTAssertTrue(filtered.allSatisfy { $0.toolUsed == "Continue Writing" })
    }

    func testGetAIToolUsageStats() throws {
        let userId = UUID()

        // Insert suggestions with different tools
        for _ in 1...3 {
            let suggestion = AISuggestion(userId: userId, toolUsed: "Continue Writing", prompt: "P", response: "R")
            try databaseManager.insertAISuggestion(suggestion)
        }

        for _ in 1...2 {
            let suggestion = AISuggestion(userId: userId, toolUsed: "Improve Text", prompt: "P", response: "R")
            try databaseManager.insertAISuggestion(suggestion)
        }

        let stats = try databaseManager.getAIToolUsageStats(userId: userId)
        XCTAssertEqual(stats.count, 2)

        let continueWritingStat = stats.first { $0.toolName == "Continue Writing" }
        XCTAssertEqual(continueWritingStat?.usageCount, 3)

        let improveTextStat = stats.first { $0.toolName == "Improve Text" }
        XCTAssertEqual(improveTextStat?.usageCount, 2)
    }

    func testGetAISuggestionsWithConfig() throws {
        let userId = UUID()

        // Save AI configuration
        let config = AIConfiguration(apiKey: "test-key", model: .claude35Sonnet)
        try databaseManager.saveAIConfiguration(userId: userId, configuration: config)

        // Insert suggestion
        let suggestion = AISuggestion(userId: userId, toolUsed: "Test", prompt: "P", response: "R")
        try databaseManager.insertAISuggestion(suggestion)

        let results = try databaseManager.getAISuggestionsWithConfig(userId: userId)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.modelUsed, AIModel.claude35Sonnet.rawValue)
    }

    // MARK: - User Sessions Tests

    func testInsertAndRetrieveUserSession() throws {
        let userId = UUID()
        let session = UserSession(
            userId: userId,
            startTime: Date(),
            wordsWritten: 500,
            aiInteractions: 3,
            multitaskingMode: "focused"
        )

        try databaseManager.insertUserSession(session)

        let sessions = try databaseManager.getUserSessions(userId: userId)
        XCTAssertEqual(sessions.count, 1)
        XCTAssertEqual(sessions.first?.userId, userId)
        XCTAssertEqual(sessions.first?.wordsWritten, 500)
        XCTAssertEqual(sessions.first?.aiInteractions, 3)
        XCTAssertEqual(sessions.first?.multitaskingMode, "focused")
    }

    func testUpdateUserSession() throws {
        let userId = UUID()
        var session = UserSession(
            userId: userId,
            startTime: Date(),
            endTime: nil,
            wordsWritten: 100
        )

        try databaseManager.insertUserSession(session)

        // Update session
        session.endTime = Date()
        session.durationSeconds = 3600
        session.wordsWritten = 500

        try databaseManager.updateUserSession(session)

        let sessions = try databaseManager.getUserSessions(userId: userId)
        XCTAssertNotNil(sessions.first?.endTime)
        XCTAssertEqual(sessions.first?.durationSeconds, 3600)
        XCTAssertEqual(sessions.first?.wordsWritten, 500)
    }

    func testGetUserSessionsSortedByDuration() throws {
        let userId = UUID()

        let session1 = UserSession(userId: userId, durationSeconds: 1800, wordsWritten: 200)
        let session2 = UserSession(userId: userId, durationSeconds: 3600, wordsWritten: 500)
        let session3 = UserSession(userId: userId, durationSeconds: 900, wordsWritten: 100)

        try databaseManager.insertUserSession(session1)
        try databaseManager.insertUserSession(session2)
        try databaseManager.insertUserSession(session3)

        let sessions = try databaseManager.getUserSessions(userId: userId, sortByDuration: true)
        XCTAssertEqual(sessions.count, 3)
        XCTAssertEqual(sessions[0].durationSeconds, 3600)
        XCTAssertEqual(sessions[1].durationSeconds, 1800)
        XCTAssertEqual(sessions[2].durationSeconds, 900)
    }

    func testFilterSessionsByMode() throws {
        let userId = UUID()

        let session1 = UserSession(userId: userId, multitaskingMode: "focused")
        let session2 = UserSession(userId: userId, multitaskingMode: "balanced")
        let session3 = UserSession(userId: userId, multitaskingMode: "focused")

        try databaseManager.insertUserSession(session1)
        try databaseManager.insertUserSession(session2)
        try databaseManager.insertUserSession(session3)

        let focused = try databaseManager.filterSessionsByMode(userId: userId, mode: "focused")
        XCTAssertEqual(focused.count, 2)
        XCTAssertTrue(focused.allSatisfy { $0.multitaskingMode == "focused" })
    }

    func testGetSessionStats() throws {
        let userId = UUID()

        let now = Date()
        let session1 = UserSession(userId: userId, startTime: now.addingTimeInterval(-7200), durationSeconds: 1800)
        let session2 = UserSession(userId: userId, startTime: now.addingTimeInterval(-3600), durationSeconds: 3600)
        let session3 = UserSession(userId: userId, startTime: now, durationSeconds: 900)

        try databaseManager.insertUserSession(session1)
        try databaseManager.insertUserSession(session2)
        try databaseManager.insertUserSession(session3)

        let stats = try databaseManager.getSessionStats(userId: userId)
        XCTAssertEqual(stats.totalSessions, 3)
        XCTAssertEqual(stats.totalDurationSeconds, 6300)
        XCTAssertEqual(stats.averageDurationSeconds, 2100.0)
        XCTAssertNotNil(stats.earliestSession)
        XCTAssertNotNil(stats.latestSession)
    }

    func testGetSessionStatsWithNoSessions() throws {
        let userId = UUID()
        let stats = try databaseManager.getSessionStats(userId: userId)
        XCTAssertEqual(stats.totalSessions, 0)
        XCTAssertEqual(stats.totalDurationSeconds, 0)
        XCTAssertNil(stats.earliestSession)
        XCTAssertNil(stats.latestSession)
    }

    // MARK: - AI Configuration Tests

    func testSaveAndGetAIConfiguration() throws {
        let userId = UUID()
        let config = AIConfiguration(
            apiKey: "test-api-key-123",
            model: .claude3Opus,
            maxTokens: 8192,
            temperature: 0.9
        )

        try databaseManager.saveAIConfiguration(userId: userId, configuration: config)

        let retrieved = try databaseManager.getAIConfiguration(userId: userId)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.apiKey, "test-api-key-123")
        XCTAssertEqual(retrieved?.model, .claude3Opus)
        XCTAssertEqual(retrieved?.maxTokens, 8192)
        XCTAssertEqual(retrieved?.temperature, 0.9)
    }

    func testUpdateAIConfiguration() throws {
        let userId = UUID()
        let config1 = AIConfiguration(apiKey: "key1", model: .claude3Haiku)
        try databaseManager.saveAIConfiguration(userId: userId, configuration: config1)

        let config2 = AIConfiguration(apiKey: "key2", model: .claude35Sonnet, maxTokens: 16384)
        try databaseManager.saveAIConfiguration(userId: userId, configuration: config2)

        let retrieved = try databaseManager.getAIConfiguration(userId: userId)
        XCTAssertEqual(retrieved?.apiKey, "key2")
        XCTAssertEqual(retrieved?.model, .claude35Sonnet)
        XCTAssertEqual(retrieved?.maxTokens, 16384)
    }

    func testGetAIConfigurationForNonexistentUser() throws {
        let userId = UUID()
        let config = try databaseManager.getAIConfiguration(userId: userId)
        XCTAssertNil(config)
    }

    // MARK: - Trace Tests

    func testInsertAndRetrieveTrace() throws {
        let trace = Trace(
            sessionId: "session-123",
            name: "test_trace",
            startTime: Date(),
            metadata: "{\"test\": true}"
        )

        try databaseManager.insertTrace(trace)

        let traces = try databaseManager.getTraces()
        XCTAssertEqual(traces.count, 1)
        XCTAssertEqual(traces.first?.sessionId, "session-123")
        XCTAssertEqual(traces.first?.name, "test_trace")
        XCTAssertEqual(traces.first?.metadata, "{\"test\": true}")
    }

    func testGetTracesFilteredBySessionId() throws {
        let trace1 = Trace(sessionId: "session-1", name: "trace1")
        let trace2 = Trace(sessionId: "session-2", name: "trace2")
        let trace3 = Trace(sessionId: "session-1", name: "trace3")

        try databaseManager.insertTrace(trace1)
        try databaseManager.insertTrace(trace2)
        try databaseManager.insertTrace(trace3)

        let filtered = try databaseManager.getTraces(sessionId: "session-1")
        XCTAssertEqual(filtered.count, 2)
        XCTAssertTrue(filtered.allSatisfy { $0.sessionId == "session-1" })
    }

    func testInsertTraceWithEndTime() throws {
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(60)
        let trace = Trace(
            sessionId: "session-456",
            name: "completed_trace",
            startTime: startTime,
            endTime: endTime
        )

        try databaseManager.insertTrace(trace)

        let traces = try databaseManager.getTraces()
        XCTAssertNotNil(traces.first?.endTime)
    }

    // MARK: - Observation Tests

    func testInsertAndRetrieveObservation() throws {
        let traceId = UUID()
        let observation = Observation(
            traceId: traceId,
            name: "test_observation",
            input: "input data",
            output: "output data",
            statusMessage: "success"
        )

        try databaseManager.insertObservation(observation)

        let observations = try databaseManager.getObservations(traceId: traceId)
        XCTAssertEqual(observations.count, 1)
        XCTAssertEqual(observations.first?.name, "test_observation")
        XCTAssertEqual(observations.first?.input, "input data")
        XCTAssertEqual(observations.first?.output, "output data")
        XCTAssertEqual(observations.first?.statusMessage, "success")
    }

    func testGetObservationsForDifferentTraces() throws {
        let trace1Id = UUID()
        let trace2Id = UUID()

        let obs1 = Observation(traceId: trace1Id, name: "obs1")
        let obs2 = Observation(traceId: trace2Id, name: "obs2")
        let obs3 = Observation(traceId: trace1Id, name: "obs3")

        try databaseManager.insertObservation(obs1)
        try databaseManager.insertObservation(obs2)
        try databaseManager.insertObservation(obs3)

        let trace1Observations = try databaseManager.getObservations(traceId: trace1Id)
        let trace2Observations = try databaseManager.getObservations(traceId: trace2Id)

        XCTAssertEqual(trace1Observations.count, 2)
        XCTAssertEqual(trace2Observations.count, 1)
    }

    func testInsertObservationWithNullFields() throws {
        let traceId = UUID()
        let observation = Observation(
            traceId: traceId,
            name: "minimal_observation",
            input: nil,
            output: nil,
            statusMessage: nil
        )

        try databaseManager.insertObservation(observation)

        let observations = try databaseManager.getObservations(traceId: traceId)
        XCTAssertEqual(observations.count, 1)
        XCTAssertNil(observations.first?.input)
        XCTAssertNil(observations.first?.output)
        XCTAssertNil(observations.first?.statusMessage)
    }

    // MARK: - Issue Tests

    func testInsertAndRetrieveIssue() throws {
        let documentId = UUID()
        let issue = Issue(
            documentId: documentId,
            title: "Fix plot hole",
            description: "Chapter 3 has inconsistent timeline",
            status: .open,
            priority: .high
        )

        try databaseManager.insertIssue(issue)

        let issues = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(issues.count, 1)
        XCTAssertEqual(issues.first?.title, "Fix plot hole")
        XCTAssertEqual(issues.first?.description, "Chapter 3 has inconsistent timeline")
        XCTAssertEqual(issues.first?.status, .open)
        XCTAssertEqual(issues.first?.priority, .high)
    }

    func testUpdateIssue() throws {
        let documentId = UUID()
        var issue = Issue(
            documentId: documentId,
            title: "Original Title",
            description: "Original Description",
            status: .open,
            priority: .medium
        )

        try databaseManager.insertIssue(issue)

        issue.title = "Updated Title"
        issue.description = "Updated Description"
        issue.status = .resolved
        issue.priority = .high
        issue.metadata.resolvedAt = Date()

        try databaseManager.updateIssue(issue)

        let issues = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(issues.first?.title, "Updated Title")
        XCTAssertEqual(issues.first?.description, "Updated Description")
        XCTAssertEqual(issues.first?.status, .resolved)
        XCTAssertEqual(issues.first?.priority, .high)
        XCTAssertNotNil(issues.first?.metadata.resolvedAt)
    }

    func testDeleteIssue() throws {
        let documentId = UUID()
        let issue = Issue(documentId: documentId, title: "Temporary Issue")

        try databaseManager.insertIssue(issue)
        var issues = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(issues.count, 1)

        try databaseManager.deleteIssue(id: issue.id)
        issues = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(issues.count, 0)
    }

    func testGetIssuesByStatus() throws {
        let documentId = UUID()

        let issue1 = Issue(documentId: documentId, title: "Open 1", status: .open)
        let issue2 = Issue(documentId: documentId, title: "Resolved 1", status: .resolved)
        let issue3 = Issue(documentId: documentId, title: "Open 2", status: .open)

        try databaseManager.insertIssue(issue1)
        try databaseManager.insertIssue(issue2)
        try databaseManager.insertIssue(issue3)

        let openIssues = try databaseManager.getIssues(withStatus: .open)
        let resolvedIssues = try databaseManager.getIssues(withStatus: .resolved)

        XCTAssertEqual(openIssues.count, 2)
        XCTAssertEqual(resolvedIssues.count, 1)
        XCTAssertTrue(openIssues.allSatisfy { $0.status == .open })
    }

    func testGetAllIssues() throws {
        let doc1 = UUID()
        let doc2 = UUID()

        try databaseManager.insertIssue(Issue(documentId: doc1, title: "Issue 1"))
        try databaseManager.insertIssue(Issue(documentId: doc2, title: "Issue 2"))
        try databaseManager.insertIssue(Issue(documentId: doc1, title: "Issue 3"))

        let allIssues = try databaseManager.getAllIssues()
        XCTAssertEqual(allIssues.count, 3)
    }

    func testGetIssuesWithPagination() throws {
        let documentId = UUID()

        for i in 1...10 {
            let issue = Issue(documentId: documentId, title: "Issue \(i)")
            try databaseManager.insertIssue(issue)
        }

        let firstPage = try databaseManager.getIssues(forDocument: documentId, limit: 5, offset: 0)
        let secondPage = try databaseManager.getIssues(forDocument: documentId, limit: 5, offset: 5)

        XCTAssertEqual(firstPage.count, 5)
        XCTAssertEqual(secondPage.count, 5)
    }

    func testIssueWithTags() throws {
        let documentId = UUID()
        var metadata = IssueMetadata()
        metadata.tags = ["bug", "urgent", "chapter-2"]
        metadata.notes = "This needs immediate attention"

        let issue = Issue(
            documentId: documentId,
            title: "Tagged Issue",
            metadata: metadata
        )

        try databaseManager.insertIssue(issue)

        let issues = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(issues.first?.metadata.tags.count, 3)
        XCTAssertTrue(issues.first?.metadata.tags.contains("bug") ?? false)
        XCTAssertEqual(issues.first?.metadata.notes, "This needs immediate attention")
    }

    // MARK: - Error Handling Tests

    func testDatabaseErrorDescriptions() {
        let connectionError = DatabaseError.connectionFailed("Connection lost")
        XCTAssertTrue(connectionError.localizedDescription.contains("Connection lost"))

        let queryError = DatabaseError.queryFailed("Invalid SQL")
        XCTAssertTrue(queryError.localizedDescription.contains("Invalid SQL"))

        let dataError = DatabaseError.invalidData("Bad UUID")
        XCTAssertTrue(dataError.localizedDescription.contains("Bad UUID"))

        let notInitError = DatabaseError.notInitialized
        XCTAssertTrue(notInitError.localizedDescription.contains("not initialized"))
    }

    // MARK: - Edge Cases and Boundary Tests

    func testInsertMultipleAISuggestionsForSameUser() throws {
        let userId = UUID()

        for i in 1...100 {
            let suggestion = AISuggestion(
                userId: userId,
                toolUsed: "Tool \(i % 5)",
                prompt: "Prompt \(i)",
                response: "Response \(i)"
            )
            try databaseManager.insertAISuggestion(suggestion)
        }

        let suggestions = try databaseManager.getAISuggestions(userId: userId, limit: 100)
        XCTAssertEqual(suggestions.count, 100)
    }

    func testSessionWithVeryLongDuration() throws {
        let userId = UUID()
        let session = UserSession(
            userId: userId,
            durationSeconds: 86400, // 24 hours
            wordsWritten: 50000,
            aiInteractions: 500
        )

        try databaseManager.insertUserSession(session)

        let sessions = try databaseManager.getUserSessions(userId: userId)
        XCTAssertEqual(sessions.first?.durationSeconds, 86400)
        XCTAssertEqual(sessions.first?.wordsWritten, 50000)
        XCTAssertEqual(sessions.first?.aiInteractions, 500)
    }

    func testIssueWithEmptyStrings() throws {
        let documentId = UUID()
        let issue = Issue(
            documentId: documentId,
            title: "",
            description: "",
            status: .open,
            priority: .low
        )

        try databaseManager.insertIssue(issue)

        let issues = try databaseManager.getIssues(forDocument: documentId)
        XCTAssertEqual(issues.first?.title, "")
        XCTAssertEqual(issues.first?.description, "")
    }

    func testDatabaseReinitializationAfterClose() throws {
        databaseManager.close()
        try databaseManager.initialize()

        let userId = UUID()
        let suggestion = AISuggestion(userId: userId, toolUsed: "Test", prompt: "P", response: "R")
        XCTAssertNoThrow(try databaseManager.insertAISuggestion(suggestion))
    }

    func testQueryWithSpecialCharacters() throws {
        let userId = UUID()
        let suggestion = AISuggestion(
            userId: userId,
            toolUsed: "Test's \"Tool\"",
            prompt: "What's the meaning of \"life\"?",
            response: "It's complicated & simple"
        )

        try databaseManager.insertAISuggestion(suggestion)

        let suggestions = try databaseManager.getAISuggestions(userId: userId)
        XCTAssertEqual(suggestions.first?.toolUsed, "Test's \"Tool\"")
        XCTAssertEqual(suggestions.first?.prompt, "What's the meaning of \"life\"?")
        XCTAssertEqual(suggestions.first?.response, "It's complicated & simple")
    }
}