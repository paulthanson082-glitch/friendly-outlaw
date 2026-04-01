import XCTest
@testable import WritersApp

/// Tests verifying that the Cowork Mode removal (CoworkModels, CoworkService, and the
/// corresponding WritersApp façade) was applied cleanly and that WritersApp continues to
/// initialize and operate correctly without those dependencies.
final class CoworkRemovalTests: XCTestCase {

    var app: WritersApp!

    override func setUp() {
        super.setUp()
        app = WritersApp()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // MARK: - WritersApp Initialization Tests

    /// Default convenience init must succeed without any cowork setup.
    func testDefaultInitSucceeds() {
        let instance = WritersApp()
        XCTAssertNotNil(instance)
    }

    /// Init with a custom database path must succeed without cowork setup.
    func testInitWithDatabasePathSucceeds() {
        let path = "/tmp/cowork_removal_test_\(UUID().uuidString).db"
        let instance = WritersApp(databasePath: path)
        XCTAssertNotNil(instance)
        try? FileManager.default.removeItem(atPath: path)
    }

    /// All expected public managers and services are non-nil after default init.
    func testCoreServicesAvailableAfterInit() {
        XCTAssertNotNil(app.templateManager)
        XCTAssertNotNil(app.documentManager)
        XCTAssertNotNil(app.issueManager)
        XCTAssertNotNil(app.kanbanManager)
        XCTAssertNotNil(app.crmManager)
        XCTAssertNotNil(app.hardwareManager)
        XCTAssertNotNil(app.databaseManager)
        XCTAssertNotNil(app.pluginManager)
        XCTAssertNotNil(app.encouragementService)
        XCTAssertNotNil(app.versionControl)
    }

    /// Optional services are nil by default after init (no configuration supplied).
    func testOptionalServicesNilByDefault() {
        XCTAssertNil(app.aiService, "aiService should be nil without AIConfiguration")
        XCTAssertNil(app.chatbotService, "chatbotService should be nil without AIConfiguration")
        XCTAssertNil(app.ragieService, "ragieService should be nil without RagieConfiguration")
        XCTAssertNil(app.guiService, "guiService should be nil after default init")
        XCTAssertNil(app.currentUserId, "currentUserId should be nil after default init")
    }

    // MARK: - AI Enable/Disable Tests (unchanged path, regression check)

    func testIsAIEnabledFalseByDefault() {
        XCTAssertFalse(app.isAIEnabled)
    }

    func testDisableAIWhenAlreadyDisabledIsHarmless() {
        // Should not crash when disabling AI that was never enabled
        app.disableAI()
        XCTAssertFalse(app.isAIEnabled)
        XCTAssertNil(app.aiService)
        XCTAssertNil(app.chatbotService)
    }

    // MARK: - Ragie Enable/Disable Tests (unchanged path, regression check)

    func testIsRagieEnabledFalseByDefault() {
        XCTAssertFalse(app.isRagieEnabled)
    }

    func testDisableRagieWhenAlreadyDisabledIsHarmless() {
        app.disableRagie()
        XCTAssertFalse(app.isRagieEnabled)
        XCTAssertNil(app.ragieService)
    }

    // MARK: - Core Functionality Still Works After Removal

    /// Document creation must work after cowork removal.
    func testCreateBlankDocumentStillWorks() {
        let doc = app.createBlankDocument(title: "Post-Cowork Doc", category: .article)
        XCTAssertEqual(doc.title, "Post-Cowork Doc")
        XCTAssertEqual(doc.category, .article)
        XCTAssertEqual(doc.content, "")
    }

    /// Template manager still loads default templates after cowork removal.
    func testTemplateManagerStillLoadsDefaults() {
        let templates = app.templateManager.getAllTemplates()
        XCTAssertGreaterThan(templates.count, 0, "Default templates should still load")
    }

    /// Statistics still work after cowork removal.
    func testStatisticsStillWork() {
        _ = app.createBlankDocument(title: "Stats Doc", category: .novel)
        let stats = app.getStatistics()
        XCTAssertGreaterThanOrEqual(stats.totalDocuments, 1)
    }

    // MARK: - Regression: Cowork Symbols Must Not Exist at Runtime

    /// WritersApp's mirror should not contain any cowork-related stored properties.
    func testNoCoworkPropertiesOnWritersApp() {
        let mirror = Mirror(reflecting: app!)
        let coworkPropertyNames = ["prospectDatabase", "browserService", "gmailService",
                                   "activeCoworkSession"]
        for name in coworkPropertyNames {
            let found = mirror.children.contains { $0.label == name }
            XCTAssertFalse(found, "WritersApp should no longer expose '\(name)' property")
        }
    }

    // MARK: - Multiple Init Paths (Regression)

    /// Ensure two independent WritersApp instances do not share state.
    func testTwoInstancesAreIndependent() {
        let app1 = WritersApp()
        let app2 = WritersApp()

        _ = app1.createBlankDocument(title: "App1 Doc", category: .novel)
        let app1Docs = app1.documentManager.getAllDocuments()
        let app2Docs = app2.documentManager.getAllDocuments()

        XCTAssertEqual(app1Docs.count, 1)
        XCTAssertEqual(app2Docs.count, 0, "Second instance should not share document state")
    }

    /// WritersApp initialized with a database path should use it without crashing.
    func testDatabasePathInitDoesNotPolluteCoreInit() {
        let tmpPath = "/tmp/cowork_removal_isolation_\(UUID().uuidString).db"
        defer { try? FileManager.default.removeItem(atPath: tmpPath) }

        let custom = WritersApp(databasePath: tmpPath)
        // Core services must still be available
        XCTAssertNotNil(custom.templateManager)
        XCTAssertNotNil(custom.documentManager)
        XCTAssertFalse(custom.isAIEnabled)
        XCTAssertFalse(custom.isRagieEnabled)
    }
}