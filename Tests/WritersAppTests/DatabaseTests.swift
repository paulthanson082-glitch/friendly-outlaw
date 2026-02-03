import XCTest
@testable import WritersApp

final class DatabaseTests: XCTestCase {
    var database: SQLiteDatabase!
    var databaseService: DatabaseService!
    var tempDBPath: String!
    
    override func setUp() {
        super.setUp()
        
        // Create a temporary database file for testing
        let tempDir = FileManager.default.temporaryDirectory
        tempDBPath = tempDir.appendingPathComponent("test_\(UUID().uuidString).db").path
        
        database = SQLiteDatabase(path: tempDBPath)
        databaseService = DatabaseService(database: database)
        
        // Initialize schema
        try? databaseService.initialize()
    }
    
    override func tearDown() {
        database.close()
        
        // Clean up temporary database file
        try? FileManager.default.removeItem(atPath: tempDBPath)
        
        super.tearDown()
    }
    
    // MARK: - Database Initialization Tests
    
    func testDatabaseInitialization() throws {
        XCTAssertTrue(database.isOpen, "Database should be open after initialization")
        
        // Check if tables exist
        XCTAssertTrue(try database.tableExists("AI_Suggestions"), "AI_Suggestions table should exist")
        XCTAssertTrue(try database.tableExists("User_Sessions"), "User_Sessions table should exist")
        XCTAssertTrue(try database.tableExists("AI_Configurations"), "AI_Configurations table should exist")
    }
    
    // MARK: - AI Suggestions Tests
    
    func testSaveAISuggestion() throws {
        let suggestion = AISuggestion(
            promptText: "Continue writing this story",
            outputText: "Once upon a time...",
            aiTool: "continueWriting",
            aiModel: "claude-3-5-sonnet-20241022"
        )
        
        XCTAssertNoThrow(try databaseService.saveAISuggestion(suggestion))
        
        // Retrieve the suggestion
        let suggestions = try databaseService.getRecentAISuggestions(limit: 1)
        XCTAssertEqual(suggestions.count, 1)
        XCTAssertEqual(suggestions.first?.promptText, "Continue writing this story")
        XCTAssertEqual(suggestions.first?.outputText, "Once upon a time...")
        XCTAssertEqual(suggestions.first?.aiTool, "continueWriting")
    }
    
    func testGetAISuggestionsByTool() throws {
        // Save multiple suggestions with different tools
        let suggestion1 = AISuggestion(
            promptText: "Improve this text",
            outputText: "Improved version",
            aiTool: "improveText"
        )
        
        let suggestion2 = AISuggestion(
            promptText: "Check grammar",
            outputText: "Grammar checked",
            aiTool: "grammarCheck"
        )
        
        let suggestion3 = AISuggestion(
            promptText: "Improve more text",
            outputText: "Another improved version",
            aiTool: "improveText"
        )
        
        try databaseService.saveAISuggestion(suggestion1)
        try databaseService.saveAISuggestion(suggestion2)
        try databaseService.saveAISuggestion(suggestion3)
        
        // Get suggestions by tool
        let improveSuggestions = try databaseService.getAISuggestionsByTool("improveText")
        XCTAssertEqual(improveSuggestions.count, 2)
        
        let grammarSuggestions = try databaseService.getAISuggestionsByTool("grammarCheck")
        XCTAssertEqual(grammarSuggestions.count, 1)
    }
    
    func testGetAISuggestionsForDocument() throws {
        let documentId = UUID()
        
        let suggestion1 = AISuggestion(
            promptText: "Test prompt",
            outputText: "Test output",
            aiTool: "testTool",
            documentId: documentId
        )
        
        let suggestion2 = AISuggestion(
            promptText: "Another prompt",
            outputText: "Another output",
            aiTool: "testTool",
            documentId: UUID() // Different document
        )
        
        try databaseService.saveAISuggestion(suggestion1)
        try databaseService.saveAISuggestion(suggestion2)
        
        let documentSuggestions = try databaseService.getAISuggestionsForDocument(documentId)
        XCTAssertEqual(documentSuggestions.count, 1)
        XCTAssertEqual(documentSuggestions.first?.documentId, documentId)
    }
    
    // MARK: - User Sessions Tests
    
    func testCreateUserSession() throws {
        let session = UserSession(
            toolsUsed: ["editor", "ai_assistant"],
            multitaskingMode: "split",
            screenSize: "1024x768"
        )
        
        XCTAssertNoThrow(try databaseService.createUserSession(session))
        
        // Retrieve the session
        let retrievedSession = try databaseService.getUserSession(id: session.id)
        XCTAssertNotNil(retrievedSession)
        XCTAssertEqual(retrievedSession?.toolsUsed, ["editor", "ai_assistant"])
        XCTAssertEqual(retrievedSession?.multitaskingMode, "split")
        XCTAssertEqual(retrievedSession?.screenSize, "1024x768")
    }
    
    func testUpdateUserSession() throws {
        var session = UserSession()
        try databaseService.createUserSession(session)
        
        // Update session
        session.toolsUsed = ["editor", "ai_assistant", "export"]
        session.aiInteractionsCount = 5
        session.sessionEnd = Date()
        
        XCTAssertNoThrow(try databaseService.updateUserSession(session))
        
        // Retrieve updated session
        let updated = try databaseService.getUserSession(id: session.id)
        XCTAssertEqual(updated?.toolsUsed.count, 3)
        XCTAssertEqual(updated?.aiInteractionsCount, 5)
        XCTAssertNotNil(updated?.sessionEnd)
    }
    
    func testEndSession() throws {
        let session = UserSession()
        try databaseService.createUserSession(session)
        
        // End the session
        XCTAssertNoThrow(try databaseService.endSession(id: session.id))
        
        // Retrieve ended session
        let endedSession = try databaseService.getUserSession(id: session.id)
        XCTAssertNotNil(endedSession?.sessionEnd)
        XCTAssertNotNil(endedSession?.durationSeconds)
        XCTAssert(endedSession!.durationSeconds! >= 0)
    }
    
    func testLogToolUsage() throws {
        let session = UserSession()
        try databaseService.createUserSession(session)
        
        // Log tool usage
        try databaseService.logToolUsage(sessionId: session.id, tool: "editor")
        try databaseService.logToolUsage(sessionId: session.id, tool: "ai_assistant")
        
        let updated = try databaseService.getUserSession(id: session.id)
        XCTAssertTrue(updated?.toolsUsed.contains("editor") ?? false)
        XCTAssertTrue(updated?.toolsUsed.contains("ai_assistant") ?? false)
    }
    
    func testLogToolbarInteraction() throws {
        let session = UserSession()
        try databaseService.createUserSession(session)
        
        // Log toolbar interactions
        try databaseService.logToolbarInteraction(sessionId: session.id, interaction: "bold")
        try databaseService.logToolbarInteraction(sessionId: session.id, interaction: "italic")
        
        let updated = try databaseService.getUserSession(id: session.id)
        XCTAssertEqual(updated?.toolbarInteractions.count, 2)
        XCTAssertTrue(updated?.toolbarInteractions.contains("bold") ?? false)
    }
    
    func testIncrementAIInteractionCount() throws {
        let session = UserSession()
        try databaseService.createUserSession(session)
        
        // Increment counter multiple times
        try databaseService.incrementAIInteractionCount(sessionId: session.id)
        try databaseService.incrementAIInteractionCount(sessionId: session.id)
        try databaseService.incrementAIInteractionCount(sessionId: session.id)
        
        let updated = try databaseService.getUserSession(id: session.id)
        XCTAssertEqual(updated?.aiInteractionsCount, 3)
    }
    
    func testGetActiveSessions() throws {
        // Create an active session
        let activeSession = UserSession()
        try databaseService.createUserSession(activeSession)
        
        // Create a closed session
        var closedSession = UserSession()
        closedSession.sessionEnd = Date()
        closedSession.durationSeconds = 100
        try databaseService.createUserSession(closedSession)
        
        let activeSessions = try databaseService.getActiveSessions()
        XCTAssertEqual(activeSessions.count, 1)
        XCTAssertEqual(activeSessions.first?.id, activeSession.id)
    }
    
    // MARK: - AI Configurations Tests
    
    func testSaveAIConfiguration() throws {
        let aiConfig = AIConfiguration(
            apiKey: "test-key",
            model: .claude35Sonnet,
            maxTokens: 4096,
            temperature: 0.7
        )
        
        let configStorage = AIConfigurationStorage.from(
            aiConfiguration: aiConfig,
            userId: "test-user"
        )!
        
        XCTAssertNoThrow(try databaseService.saveAIConfiguration(configStorage))
        
        // Retrieve configuration
        let retrieved = try databaseService.getAIConfiguration(userId: "test-user")
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.userId, "test-user")
        
        let decodedConfig = retrieved?.toAIConfiguration()
        XCTAssertNotNil(decodedConfig)
        XCTAssertEqual(decodedConfig?.apiKey, "test-key")
        XCTAssertEqual(decodedConfig?.model, .claude35Sonnet)
    }
    
    func testUpdateAIConfiguration() throws {
        let aiConfig = AIConfiguration(
            apiKey: "old-key",
            model: .claude3Haiku
        )
        
        var configStorage = AIConfigurationStorage.from(
            aiConfiguration: aiConfig,
            userId: "test-user"
        )!
        
        try databaseService.saveAIConfiguration(configStorage)
        
        // Update configuration
        let newConfig = AIConfiguration(
            apiKey: "new-key",
            model: .claude35Sonnet
        )
        
        let newConfigStorage = AIConfigurationStorage.from(
            aiConfiguration: newConfig,
            userId: "test-user"
        )!
        
        configStorage = AIConfigurationStorage(
            id: configStorage.id,
            userId: configStorage.userId,
            configurationJSON: newConfigStorage.configurationJSON,
            createdAt: configStorage.createdAt,
            updatedAt: Date()
        )
        
        try databaseService.updateAIConfiguration(configStorage)
        
        // Retrieve updated configuration
        let retrieved = try databaseService.getAIConfiguration(userId: "test-user")
        let decodedConfig = retrieved?.toAIConfiguration()
        XCTAssertEqual(decodedConfig?.apiKey, "new-key")
        XCTAssertEqual(decodedConfig?.model, .claude35Sonnet)
    }
    
    // MARK: - Analytics Tests
    
    func testGetTotalAIInteractions() throws {
        // Save multiple suggestions
        for i in 1...5 {
            let suggestion = AISuggestion(
                promptText: "Prompt \(i)",
                outputText: "Output \(i)",
                aiTool: "testTool"
            )
            try databaseService.saveAISuggestion(suggestion)
        }
        
        let total = try databaseService.getTotalAIInteractions()
        XCTAssertEqual(total, 5)
    }
    
    func testGetMostUsedAITools() throws {
        // Save suggestions with different tools
        for _ in 1...3 {
            let suggestion = AISuggestion(
                promptText: "Test",
                outputText: "Output",
                aiTool: "continueWriting"
            )
            try databaseService.saveAISuggestion(suggestion)
        }
        
        for _ in 1...2 {
            let suggestion = AISuggestion(
                promptText: "Test",
                outputText: "Output",
                aiTool: "improveText"
            )
            try databaseService.saveAISuggestion(suggestion)
        }
        
        let suggestion = AISuggestion(
            promptText: "Test",
            outputText: "Output",
            aiTool: "grammarCheck"
        )
        try databaseService.saveAISuggestion(suggestion)
        
        let mostUsed = try databaseService.getMostUsedAITools(limit: 3)
        XCTAssertEqual(mostUsed.count, 3)
        XCTAssertEqual(mostUsed[0].tool, "continueWriting")
        XCTAssertEqual(mostUsed[0].count, 3)
        XCTAssertEqual(mostUsed[1].tool, "improveText")
        XCTAssertEqual(mostUsed[1].count, 2)
    }
    
    func testGetAverageSessionDuration() throws {
        // Create sessions with durations
        var session1 = UserSession()
        session1.durationSeconds = 100
        try databaseService.createUserSession(session1)
        
        var session2 = UserSession()
        session2.durationSeconds = 200
        try databaseService.createUserSession(session2)
        
        var session3 = UserSession()
        session3.durationSeconds = 300
        try databaseService.createUserSession(session3)
        
        let avgDuration = try databaseService.getAverageSessionDuration()
        XCTAssertEqual(avgDuration, 200.0, accuracy: 0.1)
    }
}
