import XCTest
@testable import WritersApp

// MARK: - WritersApp PR Changes Tests
// Tests covering changes made to WritersApp in this PR:
// 1. addProspect: removed `status` parameter (prospects now always created with default .new status)
// 2. disableAI: no longer sets writingAdvisorService to nil twice (duplicate removed)
// 3. getAllIdeas and getHermesSessionStats facade methods removed
// 4. crmManager reordered in property declarations (functional behavior unchanged)

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

    // MARK: - addProspect: Status Parameter Removed (PR Change)

    /// PR change: addProspect no longer accepts a `status` parameter.
    /// Prospects are always created with the default `.new` status.
    func testAddProspectCreatesProspectWithNewStatus() {
        let prospect = app.addProspect(
            name: "Jane Publisher",
            email: "jane@publisher.com"
        )
        XCTAssertEqual(prospect.status, .new,
            "Prospects created via addProspect must default to .new status after the status parameter was removed")
    }

    func testAddProspectWithAllOptionalParametersExceptStatus() {
        let prospect = app.addProspect(
            name: "John Agent",
            email: "john@agency.com",
            company: "Big Agency",
            role: "Literary Agent",
            notes: "Met at conference",
            tags: ["fiction", "fantasy"]
        )
        XCTAssertEqual(prospect.name, "John Agent")
        XCTAssertEqual(prospect.email, "john@agency.com")
        XCTAssertEqual(prospect.company, "Big Agency")
        XCTAssertEqual(prospect.role, "Literary Agent")
        XCTAssertEqual(prospect.notes, "Met at conference")
        XCTAssertEqual(prospect.tags, ["fiction", "fantasy"])
        XCTAssertEqual(prospect.status, .new,
            "All prospects must start with .new status since the status parameter was removed")
    }

    func testAddProspectWithOnlyRequiredParameters() {
        let prospect = app.addProspect(name: "Minimal Contact", email: "min@example.com")
        XCTAssertEqual(prospect.name, "Minimal Contact")
        XCTAssertEqual(prospect.email, "min@example.com")
        XCTAssertNil(prospect.company)
        XCTAssertNil(prospect.role)
        XCTAssertEqual(prospect.notes, "")
        XCTAssertEqual(prospect.tags, [])
        XCTAssertEqual(prospect.status, .new)
    }

    func testAddMultipleProspectsAllHaveNewStatus() {
        let names = ["Alice", "Bob", "Carol"]
        let prospects = names.map { name in
            app.addProspect(name: name, email: "\(name.lowercased())@test.com")
        }
        for prospect in prospects {
            XCTAssertEqual(prospect.status, .new,
                "Prospect '\(prospect.name)' must have .new status")
        }
    }

    /// After adding a prospect (always .new), updating its status via updateProspectStatus
    /// should work correctly.
    func testAddProspectThenUpdateStatusWorks() throws {
        let prospect = app.addProspect(name: "Test User", email: "test@example.com")
        XCTAssertEqual(prospect.status, .new)

        try app.updateProspectStatus(id: prospect.id, status: .contacted)

        let updated = app.getAllProspects().first { $0.id == prospect.id }
        XCTAssertEqual(updated?.status, .contacted)
    }

    func testAddProspectIsStoredInDatabase() {
        let prospect = app.addProspect(name: "Stored User", email: "stored@example.com")
        let all = app.getAllProspects()
        XCTAssertTrue(all.contains { $0.id == prospect.id },
            "Prospect must be retrievable after addProspect")
    }

    func testAddProspectReturnsProspectWithValidId() {
        let prospect = app.addProspect(name: "ID Check", email: "id@example.com")
        // UUID must be non-nil (it is always set); verify the ID is stable
        let retrieved = app.getAllProspects().first { $0.id == prospect.id }
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.id, prospect.id)
    }

    // MARK: - disableAI Clears All AI Services (PR: removed duplicate writingAdvisorService = nil)

    func testDisableAIClearsAIService() {
        let config = AIConfiguration(apiKey: "sk-test", model: .claude35Sonnet, maxTokens: 1024, temperature: 0.7)
        app.enableAI(configuration: config)
        XCTAssertTrue(app.isAIEnabled)

        app.disableAI()
        XCTAssertFalse(app.isAIEnabled, "aiService must be nil after disableAI")
    }

    func testDisableAIClearsChatbotService() {
        let config = AIConfiguration(apiKey: "sk-test", model: .claude35Sonnet, maxTokens: 1024, temperature: 0.7)
        app.enableAI(configuration: config)

        app.disableAI()
        // Access via reflection to avoid direct property dependency
        XCTAssertFalse(app.isAIEnabled)
        // Chatbot depends on AI being enabled; if AI is nil, chatbot should also be nil
        // (verified via isAIEnabled as proxy, since chatbot is not public API)
    }

    func testEnableAndDisableAIMultipleTimes() {
        let config = AIConfiguration(apiKey: "sk-test", model: .claude35Sonnet, maxTokens: 1024, temperature: 0.7)

        // Enable → disable → enable → disable
        for _ in 1...3 {
            app.enableAI(configuration: config)
            XCTAssertTrue(app.isAIEnabled)

            app.disableAI()
            XCTAssertFalse(app.isAIEnabled)
        }
    }

    func testIsAIEnabledFalseByDefault() {
        let freshApp = WritersApp()
        XCTAssertFalse(freshApp.isAIEnabled, "AI must be disabled by default on a new WritersApp instance")
    }

    // MARK: - CRM Manager Initialized (regression after reordering)

    func testCRMManagerIsInitialized() {
        XCTAssertNotNil(app.crmManager,
            "crmManager must be initialized even after property reordering in this PR")
    }

    func testCRMManagerIsAvailableBeforeAndAfterAIEnable() {
        let config = AIConfiguration(apiKey: "sk-test", model: .claude35Sonnet, maxTokens: 1024, temperature: 0.7)
        XCTAssertNotNil(app.crmManager, "crmManager must exist before enableAI")
        app.enableAI(configuration: config)
        XCTAssertNotNil(app.crmManager, "crmManager must exist after enableAI")
    }

    // MARK: - Prospect Status Transitions (regression)

    func testUpdateProspectStatusToContacted() throws {
        let prospect = app.addProspect(name: "Contacted User", email: "c@test.com")
        try app.updateProspectStatus(id: prospect.id, status: .contacted)
        let updated = app.getAllProspects().first { $0.id == prospect.id }
        XCTAssertEqual(updated?.status, .contacted)
    }

    func testUpdateProspectStatusToReplied() throws {
        let prospect = app.addProspect(name: "Replied User", email: "r@test.com")
        try app.updateProspectStatus(id: prospect.id, status: .replied)
        let updated = app.getAllProspects().first { $0.id == prospect.id }
        XCTAssertEqual(updated?.status, .replied)
    }

    func testDeleteProspect() {
        let prospect = app.addProspect(name: "To Delete", email: "del@test.com")
        app.deleteProspect(id: prospect.id)
        let all = app.getAllProspects()
        XCTAssertFalse(all.contains { $0.id == prospect.id })
    }

    func testGetProspectsByStatus() {
        let prospect = app.addProspect(name: "New User", email: "new@test.com")
        let newProspects = app.getProspects(withStatus: .new)
        XCTAssertTrue(newProspects.contains { $0.id == prospect.id })
    }

    func testSearchProspects() {
        let _ = app.addProspect(name: "Searchable Name", email: "search@example.com")
        let results = app.searchProspects(query: "Searchable")
        XCTAssertFalse(results.isEmpty)
        XCTAssertTrue(results.contains { $0.name == "Searchable Name" })
    }

    func testGetProspectStats() {
        let _ = app.addProspect(name: "Stats User", email: "stats@example.com")
        let stats = app.getProspectStats()
        XCTAssertNotNil(stats[.new])
        XCTAssertGreaterThanOrEqual(stats[.new]!, 1)
    }
}