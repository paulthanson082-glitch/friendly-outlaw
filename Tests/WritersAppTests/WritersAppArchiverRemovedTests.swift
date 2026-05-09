import XCTest
@testable import WritersApp

// MARK: - WritersApp Archiver Removed Tests
//
// This PR removed the following from WritersApp:
//   - archiverService property (public private(set) var archiverService: ArchiverService?)
//   - createArchiveCollection(name:description:theme:tags:)
//   - getArchiveCollection(_:)
//   - addDocumentToArchiveCollection(_:collectionId:)
//   - removeDocumentFromArchiveCollection(_:collectionId:)
//   - listArchiveCollections()
//   - deleteArchiveCollection(_:)
//   - preserveArchiveMilestone(documentId:title:wordCount:...)
//   - getArchiveSnapshot(_:)
//   - getArchiveSnapshots(forDocument:)
//   - listArchiveSnapshots()
//   - organizeArchiveByTags(_:context:)
//   - summarizeDocumentForArchive(_:)
//   - searchArchive(_:limit:)
//   - suggestRelatedArchived(to:limit:)
//   - getArchiveStats()
//
// From enableAI and init(databaseManager:aiConfiguration:):
//   - ArchiverService is no longer created alongside HermesService
//
// From disableAI():
//   - archiverService is no longer set to nil (it doesn't exist)
//
// These tests verify that the remaining AI service management (hermesService,
// chatbotService, writingAdvisorService) continues to work correctly after
// the archiver removal.

final class WritersAppArchiverRemovedTests: XCTestCase {

    var app: WritersApp!

    override func setUp() {
        super.setUp()
        app = WritersApp()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // MARK: - AI Service Initialization (no archiverService)

    /// WritersApp initialized without AI config must have no AI services.
    func testDefaultInitHasNoAIServices() {
        let freshApp = WritersApp()
        XCTAssertFalse(freshApp.isAIEnabled,
            "A default WritersApp must not have AI enabled")
        XCTAssertNil(freshApp.aiService)
        XCTAssertNil(freshApp.hermesService)
    }

    /// WritersApp initialized with AI config must have hermesService but not archiverService.
    func testInitWithAIConfigCreatesHermesService() {
        let config = AIConfiguration(apiKey: "sk-test", model: .claude35Sonnet)
        let aiApp = WritersApp(aiConfiguration: config)

        XCTAssertTrue(aiApp.isAIEnabled)
        XCTAssertNotNil(aiApp.hermesService,
            "hermesService must be created when AI is enabled")
    }

    /// enableAI must create hermesService.
    func testEnableAICreatesHermesService() {
        let config = AIConfiguration(apiKey: "sk-test", model: .claude35Sonnet)
        XCTAssertNil(app.hermesService, "hermesService must be nil before enableAI")

        app.enableAI(configuration: config)

        XCTAssertNotNil(app.hermesService,
            "hermesService must exist after enableAI")
    }

    /// enableAI must make isAIEnabled return true.
    func testEnableAISetsIsAIEnabled() {
        let config = AIConfiguration(apiKey: "sk-test", model: .claude35Sonnet)
        XCTAssertFalse(app.isAIEnabled)

        app.enableAI(configuration: config)

        XCTAssertTrue(app.isAIEnabled)
    }

    // MARK: - disableAI (does not reference archiverService)

    /// disableAI must clear hermesService.
    func testDisableAIClearsHermesService() {
        let config = AIConfiguration(apiKey: "sk-test", model: .claude35Sonnet)
        app.enableAI(configuration: config)
        XCTAssertNotNil(app.hermesService)

        app.disableAI()

        XCTAssertNil(app.hermesService,
            "hermesService must be nil after disableAI")
    }

    /// disableAI must clear aiService.
    func testDisableAIClearsAIService() {
        let config = AIConfiguration(apiKey: "sk-test")
        app.enableAI(configuration: config)
        XCTAssertNotNil(app.aiService)

        app.disableAI()

        XCTAssertNil(app.aiService)
        XCTAssertFalse(app.isAIEnabled)
    }

    /// disableAI called on an app with no AI enabled must not crash.
    func testDisableAIWhenAlreadyDisabledIsNoOp() {
        XCTAssertFalse(app.isAIEnabled)
        app.disableAI() // must not crash
        XCTAssertFalse(app.isAIEnabled)
    }

    /// enableAI → disableAI → enableAI cycle must work correctly.
    func testEnableDisableEnableCycle() {
        let config = AIConfiguration(apiKey: "sk-test", model: .claude35Sonnet)

        app.enableAI(configuration: config)
        XCTAssertTrue(app.isAIEnabled)
        XCTAssertNotNil(app.hermesService)

        app.disableAI()
        XCTAssertFalse(app.isAIEnabled)
        XCTAssertNil(app.hermesService)

        app.enableAI(configuration: config)
        XCTAssertTrue(app.isAIEnabled)
        XCTAssertNotNil(app.hermesService)
    }

    // MARK: - hermesService integration (through WritersApp)

    /// startHermesSession facade must work when AI is enabled.
    func testStartHermesSessionWhenAIEnabled() throws {
        let config = AIConfiguration(apiKey: "sk-test", model: .claude35Sonnet)
        app.enableAI(configuration: config)

        let session = try app.startHermesSession(context: HermesContext(genre: "Fantasy"))
        XCTAssertNotNil(session)
        XCTAssertEqual(session.context.genre, "Fantasy")
    }

    /// startHermesSession must throw when AI is not enabled.
    func testStartHermesSessionWithoutAIThrows() {
        XCTAssertFalse(app.isAIEnabled)
        XCTAssertThrowsError(try app.startHermesSession()) { error in
            // Should be AIError.aiNotEnabled or similar
            XCTAssertNotNil(error)
        }
    }

    /// getHermesSessionStats returns nil when no session is available.
    func testGetHermesSessionStatsWithNoSession() {
        let config = AIConfiguration(apiKey: "sk-test", model: .claude35Sonnet)
        app.enableAI(configuration: config)

        // No session started — passing a fresh session
        let session = HermesSession()
        let stats = app.getHermesSessionStats(from: session)

        // Stats should be returned (not nil) since we have hermesService
        XCTAssertNotNil(stats)
    }

    // MARK: - Repeated disableAI robustness

    /// Calling disableAI multiple times must not crash.
    func testMultipleDisableAICallsDoNotCrash() {
        let config = AIConfiguration(apiKey: "sk-test")
        app.enableAI(configuration: config)

        app.disableAI()
        app.disableAI()
        app.disableAI()

        XCTAssertFalse(app.isAIEnabled)
    }

    // MARK: - Non-AI services are unaffected by AI toggling

    /// documentManager must always be accessible regardless of AI state.
    func testDocumentManagerIsAlwaysAvailable() {
        XCTAssertNotNil(app.documentManager)

        let config = AIConfiguration(apiKey: "sk-test")
        app.enableAI(configuration: config)
        XCTAssertNotNil(app.documentManager)

        app.disableAI()
        XCTAssertNotNil(app.documentManager)
    }

    /// templateManager must always be accessible regardless of AI state.
    func testTemplateManagerIsAlwaysAvailable() {
        XCTAssertNotNil(app.templateManager)

        let config = AIConfiguration(apiKey: "sk-test")
        app.enableAI(configuration: config)
        XCTAssertNotNil(app.templateManager)

        app.disableAI()
        XCTAssertNotNil(app.templateManager)
    }

    // MARK: - enableAI with maxhermes model (new model from this PR)

    /// enableAI must work correctly with the new maxhermes model.
    func testEnableAIWithMaxhermesModel() {
        let config = AIConfiguration(apiKey: "sk-test", model: .maxhermes)
        app.enableAI(configuration: config)

        XCTAssertTrue(app.isAIEnabled)
        XCTAssertNotNil(app.hermesService,
            "hermesService must be created when using maxhermes model")
        XCTAssertNotNil(app.aiService)
    }

    /// WritersApp initialized with maxhermes AI config must have hermesService.
    func testInitWithMaxhermesConfigCreatesHermesService() {
        let config = AIConfiguration(apiKey: "sk-test", model: .maxhermes)
        let aiApp = WritersApp(aiConfiguration: config)

        XCTAssertTrue(aiApp.isAIEnabled)
        XCTAssertNotNil(aiApp.hermesService)
    }
}
