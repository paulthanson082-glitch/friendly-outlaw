import XCTest
@testable import WritersApp

/// Tests covering PR-specific changes to WritersApp.swift and iPadProViews.swift:
/// - addProspect no longer takes a status parameter (always defaults to .new)
/// - getAllIdeas / getHermesSessionStats removed from WritersApp
/// - disableAI clears AI services
/// - CRMManager is now initialized before HardwareManager (property order)
final class WritersAppPRChangesTests: XCTestCase {

    var app: WritersApp!

    override func setUp() {
        super.setUp()
        app = WritersApp()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // MARK: - addProspect: no status parameter

    func testAddProspectDoesNotTakeStatusParameter() {
        // PR removed the `status` parameter from WritersApp.addProspect.
        // Calling without status should succeed and default to .new.
        let prospect = app.addProspect(
            name: "Jane Austen",
            email: "jane@example.com"
        )
        XCTAssertEqual(prospect.name, "Jane Austen")
        XCTAssertEqual(prospect.email, "jane@example.com")
        XCTAssertEqual(prospect.status, .new, "Default status should be .new when no status is supplied")
    }

    func testAddProspectDefaultStatusIsNew() {
        let prospect = app.addProspect(
            name: "George Eliot",
            email: "george@example.com",
            company: "Penguin Books"
        )
        XCTAssertEqual(prospect.status, .new)
    }

    func testAddProspectWithOptionalFieldsDoesNotRequireStatus() {
        let prospect = app.addProspect(
            name: "Charlotte Brontë",
            email: "charlotte@example.com",
            company: "HarperCollins",
            role: "Author",
            notes: "Prefers email contact",
            tags: ["fiction", "literary"]
        )
        XCTAssertEqual(prospect.company, "HarperCollins")
        XCTAssertEqual(prospect.role, "Author")
        XCTAssertEqual(prospect.tags, ["fiction", "literary"])
        XCTAssertEqual(prospect.status, .new)
    }

    func testAddProspectIsStoredInDatabase() {
        let prospect = app.addProspect(name: "Leo Tolstoy", email: "leo@example.com")
        let all = app.getAllProspects()
        XCTAssertTrue(all.contains { $0.id == prospect.id })
    }

    func testAddProspectWithMinimalParameters() {
        let prospect = app.addProspect(name: "Virginia Woolf", email: "v@woolf.com")
        XCTAssertEqual(prospect.name, "Virginia Woolf")
        XCTAssertEqual(prospect.email, "v@woolf.com")
        XCTAssertNil(prospect.company)
        XCTAssertNil(prospect.role)
        XCTAssertEqual(prospect.notes, "")
        XCTAssertTrue(prospect.tags.isEmpty)
    }

    // MARK: - CRMManager initialized before HardwareManager

    func testCRMManagerAndHardwareManagerBothExist() {
        // PR changed property initialization order; verify both are accessible
        XCTAssertNotNil(app.crmManager)
        XCTAssertNotNil(app.hardwareManager)
    }

    // MARK: - disableAI clears services

    func testDisableAIClearsAIService() {
        // Can only test that after calling disableAI, aiService becomes nil
        // (enableAI requires a network key in production; here we test the disable path)
        app.disableAI()
        XCTAssertNil(app.aiService, "aiService should be nil after disableAI()")
    }

    func testDisableAIClearsHermesService() {
        app.disableAI()
        XCTAssertNil(app.hermesService, "hermesService should be nil after disableAI()")
    }

    func testDisableAIClearsChatbotService() {
        app.disableAI()
        XCTAssertNil(app.chatbotService, "chatbotService should be nil after disableAI()")
    }

    func testDisableAIClearsWritingAdvisorService() {
        app.disableAI()
        XCTAssertNil(app.writingAdvisorService, "writingAdvisorService should be nil after disableAI()")
    }

    // MARK: - Prospect status can be updated after creation

    func testProspectStatusCanBeUpdatedAfterCreation() throws {
        let prospect = app.addProspect(name: "Mark Twain", email: "mark@example.com")
        XCTAssertEqual(prospect.status, .new)
        try app.updateProspectStatus(id: prospect.id, status: .contacted)
        let updated = app.getAllProspects().first { $0.id == prospect.id }
        XCTAssertEqual(updated?.status, .contacted)
    }

    // MARK: - Prospect management after PR changes

    func testDeleteProspect() {
        let prospect = app.addProspect(name: "Fyodor D.", email: "fyodor@example.com")
        app.deleteProspect(id: prospect.id)
        let all = app.getAllProspects()
        XCTAssertFalse(all.contains { $0.id == prospect.id })
    }

    func testGetProspectsByStatusAfterCreation() {
        _ = app.addProspect(name: "Prospect A", email: "a@test.com")
        _ = app.addProspect(name: "Prospect B", email: "b@test.com")
        let newProspects = app.getProspects(withStatus: .new)
        XCTAssertGreaterThanOrEqual(newProspects.count, 2)
    }

    func testSearchProspects() {
        _ = app.addProspect(name: "Unique Author Name", email: "unique@test.com")
        let results = app.searchProspects(query: "Unique Author")
        XCTAssertGreaterThanOrEqual(results.count, 1)
        XCTAssertTrue(results.contains { $0.name == "Unique Author Name" })
    }

    func testGetProspectStats() {
        _ = app.addProspect(name: "Stats Test", email: "stats@test.com")
        let stats = app.getProspectStats()
        XCTAssertGreaterThanOrEqual(stats[.new] ?? 0, 1)
    }

    // MARK: - DatabaseManager API key security change

    func testDatabaseManagerAPIKeyStoredAsEmptyString() throws {
        let dbPath = "/tmp/test_apikey_\(UUID().uuidString).db"
        defer { try? FileManager.default.removeItem(atPath: dbPath) }

        let db = DatabaseManager(databasePath: dbPath)
        try db.initialize()
        defer { db.close() }

        let userId = UUID()
        let config = AIConfiguration(
            apiKey: "sk-ant-secret-key-12345",
            model: .claude35Sonnet,
            maxTokens: 1024,
            temperature: 0.7
        )
        try db.setAIConfiguration(config, userId: userId)

        // Retrieve and confirm API key is NOT persisted
        let retrieved = try db.getAIConfiguration(userId: userId)
        XCTAssertNotNil(retrieved, "Configuration should be retrievable")
        XCTAssertEqual(retrieved?.apiKey, "",
                       "API key must not be persisted in plaintext; should be empty string")
        // Other fields should be intact
        XCTAssertEqual(retrieved?.model, .claude35Sonnet)
        XCTAssertEqual(retrieved?.maxTokens, 1024)
        XCTAssertEqual(retrieved?.temperature, 0.7, accuracy: 0.001)
    }

    func testDatabaseManagerDoesNotStoreOriginalAPIKey() throws {
        let dbPath = "/tmp/test_apikey2_\(UUID().uuidString).db"
        defer { try? FileManager.default.removeItem(atPath: dbPath) }

        let db = DatabaseManager(databasePath: dbPath)
        try db.initialize()
        defer { db.close() }

        let userId = UUID()
        let secretKey = "sk-ant-very-secret-key-should-not-appear"
        let config = AIConfiguration(apiKey: secretKey, model: .claude3Opus, maxTokens: 2048, temperature: 0.5)
        try db.setAIConfiguration(config, userId: userId)

        let retrieved = try db.getAIConfiguration(userId: userId)
        XCTAssertNotEqual(retrieved?.apiKey, secretKey,
                          "The original API key must not be retrievable from the database")
    }

    // MARK: - Hermes session management still works (endHermesSession/startHermesSession)

    func testEndHermesSessionDoesNothingWhenNoSession() {
        // Should not crash when Hermes is not enabled
        app.endHermesSession()
        // No assertion needed; just verifying no crash
    }
}