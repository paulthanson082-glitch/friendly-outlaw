import XCTest
@testable import WritersApp

// MARK: - WritersApp Archiver Removal Tests
//
// This PR removed the following from WritersApp.swift:
//   - archiverService public property (ArchiverService?)
//   - ArchiverService initialization in both init(databaseManager:aiConfiguration:) and enableAI(configuration:userId:)
//   - archiverService = nil in disableAI()
//   - All archive wrapper methods:
//       createArchiveCollection, getArchiveCollection, addDocumentToArchiveCollection,
//       removeDocumentFromArchiveCollection, listArchiveCollections, deleteArchiveCollection,
//       preserveArchiveMilestone, getArchiveSnapshot, getArchiveSnapshots(forDocument:),
//       listArchiveSnapshots, organizeArchiveByTags, summarizeDocumentForArchive,
//       searchArchive, suggestRelatedArchived, getArchiveStats
//
// This PR also removed from HermesModels.swift the Archiver model types:
//   - ArchiveSnapshot, ArchiveCollection, ArchiverContext, ArchiverProfile
//
// Tests here verify the post-PR state of WritersApp — that:
//   1. WritersApp initializes correctly without AI (no archiver-related side effects).
//   2. WritersApp initializes correctly with AI (only expected AI services are created).
//   3. disableAI() clears all AI services and does not crash.
//   4. enableAI() sets up only the expected AI services.
//   5. Hermes-related features still work after archiver removal (regression).
//   6. isAIEnabled reflects the correct state.

// MARK: - WritersApp Initialization (No AI)

final class WritersAppNoAIInitTests: XCTestCase {

    func testInitWithoutAIConfigurationSucceeds() {
        let app = WritersApp()
        XCTAssertNotNil(app)
    }

    func testInitWithoutAIHasNoAIService() {
        let app = WritersApp()
        XCTAssertFalse(app.isAIEnabled)
    }

    func testInitWithoutAIHasNoHermesService() {
        let app = WritersApp()
        XCTAssertNil(app.hermesService)
    }

    func testInitWithoutAIHasNoChatbotService() {
        let app = WritersApp()
        XCTAssertNil(app.chatbotService)
    }

    func testInitWithoutAICoreServicesArePresent() {
        let app = WritersApp()
        // Non-AI services must still be present
        XCTAssertNotNil(app.documentManager)
        XCTAssertNotNil(app.templateManager)
        XCTAssertNotNil(app.issueManager)
        XCTAssertNotNil(app.kanbanManager)
    }
}

// MARK: - WritersApp Initialization (With AI)

final class WritersAppWithAIInitTests: XCTestCase {

    private var config: AIConfiguration {
        AIConfiguration(apiKey: "test-key", model: .claude35Sonnet, maxTokens: 1024, temperature: 0.7)
    }

    func testInitWithAIConfigurationSucceeds() {
        let app = WritersApp(aiConfiguration: config)
        XCTAssertNotNil(app)
    }

    func testInitWithAIConfigurationEnablesAI() {
        let app = WritersApp(aiConfiguration: config)
        XCTAssertTrue(app.isAIEnabled)
    }

    func testInitWithAIConfigurationCreatesHermesService() {
        let app = WritersApp(aiConfiguration: config)
        XCTAssertNotNil(app.hermesService)
    }

    func testInitWithAIConfigurationCreatesChatbotService() {
        let app = WritersApp(aiConfiguration: config)
        XCTAssertNotNil(app.chatbotService)
    }

    /// Regression: archiverService no longer exists as a property.
    /// Verify the app doesn't have any lingering archiver-initialization side effects.
    func testInitWithAIDoesNotCrashAfterArchiverRemoval() {
        // If any archiver initialization code were still present,
        // this would either crash or access a non-existent type.
        let app = WritersApp(aiConfiguration: config)
        XCTAssertTrue(app.isAIEnabled, "App must initialize correctly without archiver code")
    }

    func testInitWithMaxhermesModelSucceeds() {
        let maxhermesConfig = AIConfiguration(apiKey: "test-key", model: .maxhermes, maxTokens: 1024, temperature: 0.7)
        let app = WritersApp(aiConfiguration: maxhermesConfig)
        XCTAssertTrue(app.isAIEnabled)
        XCTAssertNotNil(app.hermesService)
    }
}

// MARK: - disableAI

final class WritersAppDisableAITests: XCTestCase {

    private var config: AIConfiguration {
        AIConfiguration(apiKey: "test-key", model: .claude35Sonnet, maxTokens: 1024, temperature: 0.7)
    }

    func testDisableAIClearsAIService() {
        let app = WritersApp(aiConfiguration: config)
        XCTAssertTrue(app.isAIEnabled)

        app.disableAI()

        XCTAssertFalse(app.isAIEnabled)
    }

    func testDisableAIClearsHermesService() {
        let app = WritersApp(aiConfiguration: config)
        XCTAssertNotNil(app.hermesService)

        app.disableAI()

        XCTAssertNil(app.hermesService)
    }

    func testDisableAIDoesNotCrashAfterArchiverRemoval() {
        // Before this PR, disableAI() also set archiverService = nil.
        // After this PR, that line is gone. Calling disableAI() must not crash.
        let app = WritersApp(aiConfiguration: config)
        app.disableAI() // must not crash
        XCTAssertFalse(app.isAIEnabled)
    }

    func testDisableAIWhenAlreadyDisabledIsNoOp() {
        let app = WritersApp()
        XCTAssertFalse(app.isAIEnabled)

        app.disableAI() // no-op, must not crash
        XCTAssertFalse(app.isAIEnabled)
    }

    func testDisableAICanBeCalledMultipleTimes() {
        let app = WritersApp(aiConfiguration: config)

        app.disableAI()
        app.disableAI()
        app.disableAI()

        XCTAssertFalse(app.isAIEnabled)
    }
}

// MARK: - enableAI

final class WritersAppEnableAITests: XCTestCase {

    private var config: AIConfiguration {
        AIConfiguration(apiKey: "test-key", model: .claude35Sonnet, maxTokens: 1024, temperature: 0.7)
    }

    func testEnableAISetsAIService() {
        let app = WritersApp()
        XCTAssertFalse(app.isAIEnabled)

        app.enableAI(configuration: config)

        XCTAssertTrue(app.isAIEnabled)
    }

    func testEnableAICreatesHermesService() {
        let app = WritersApp()
        XCTAssertNil(app.hermesService)

        app.enableAI(configuration: config)

        XCTAssertNotNil(app.hermesService)
    }

    func testEnableAIAfterDisableRestoresHermesService() {
        let app = WritersApp(aiConfiguration: config)
        app.disableAI()
        XCTAssertNil(app.hermesService)

        app.enableAI(configuration: config)
        XCTAssertNotNil(app.hermesService)
    }

    func testEnableAIDoesNotCrashAfterArchiverRemoval() {
        // Before this PR, enableAI() also created an ArchiverService.
        // After this PR, that code is removed. enableAI() must still work.
        let app = WritersApp()
        app.enableAI(configuration: config)
        XCTAssertTrue(app.isAIEnabled)
    }

    func testEnableAICanBeCalledMultipleTimes() {
        let app = WritersApp()

        for _ in 1...3 {
            app.enableAI(configuration: config)
            XCTAssertTrue(app.isAIEnabled)
            XCTAssertNotNil(app.hermesService)
        }
    }

    func testEnableAIWithUserId() {
        let app = WritersApp()
        let userId = UUID()
        app.enableAI(configuration: config, userId: userId)
        XCTAssertTrue(app.isAIEnabled)
        XCTAssertEqual(app.currentUserId, userId)
    }
}

// MARK: - Hermes Integration Regression (after archiver removal)

final class WritersAppHermesAfterArchiverRemovalTests: XCTestCase {

    private var app: WritersApp!

    override func setUp() {
        super.setUp()
        let config = AIConfiguration(apiKey: "test-key", model: .claude35Sonnet, maxTokens: 1024, temperature: 0.7)
        app = WritersApp(aiConfiguration: config)
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    func testStartHermesSessionSucceeds() throws {
        let session = try app.startHermesSession()
        XCTAssertNotNil(session.id)
        XCTAssertTrue(session.messages.isEmpty)
    }

    func testStartHermesSessionWithContextSucceeds() throws {
        let context = HermesContext(genre: "Sci-Fi", logline: "A space odyssey")
        let session = try app.startHermesSession(context: context)
        XCTAssertEqual(session.context.genre, "Sci-Fi")
        XCTAssertEqual(session.context.logline, "A space odyssey")
    }

    func testEndHermesSessionDoesNotCrash() throws {
        _ = try app.startHermesSession()
        app.endHermesSession() // must not crash
    }

    func testGetAllIdeasFromEmptySessionReturnsEmpty() throws {
        let session = try app.startHermesSession()
        let ideas = app.getAllIdeas(from: session)
        XCTAssertTrue(ideas.isEmpty)
    }

    func testGetHermesSessionStatsFromEmptySession() throws {
        let session = try app.startHermesSession()
        let stats = app.getHermesSessionStats(from: session)
        XCTAssertNotNil(stats)
        XCTAssertEqual(stats?.messageCount, 0)
        XCTAssertEqual(stats?.totalIdeas, 0)
    }

    func testStartHermesSessionWhenAIDisabledThrows() {
        app.disableAI()

        XCTAssertThrowsError(try app.startHermesSession()) { error in
            guard let hermesError = error as? HermesError else {
                XCTFail("Expected HermesError, got \(error)")
                return
            }
            if case .aiNotAvailable = hermesError {
                // expected
            } else {
                XCTFail("Expected HermesError.aiNotAvailable, got \(hermesError)")
            }
        }
    }

    func testHermesServiceSessionLifecycleStillWorksPostPR() throws {
        // Full lifecycle: start → inspect → end
        let session = try app.startHermesSession(context: HermesContext(genre: "Fantasy"))
        XCTAssertEqual(session.context.genre, "Fantasy")
        XCTAssertTrue(session.messages.isEmpty)

        // After ending, starting a new session should succeed
        app.endHermesSession()
        let newSession = try app.startHermesSession()
        XCTAssertNotEqual(session.id, newSession.id)
    }

    /// getAllIdeas with a type filter returns only matching idea types.
    func testGetAllIdeasFilteredByTypeAfterArchiverRemoval() throws {
        var session = try app.startHermesSession()

        let plotIdea = HermesIdea(title: "Plot", description: "Desc", ideaType: .plotHook)
        let twistIdea = HermesIdea(title: "Twist", description: "Desc", ideaType: .twist)
        session.messages.append(HermesMessage(role: .hermes, content: "ideas", ideas: [plotIdea, twistIdea]))

        let plotIdeas = app.getAllIdeas(from: session, filteredBy: .plotHook)
        XCTAssertEqual(plotIdeas.count, 1)
        XCTAssertEqual(plotIdeas[0].title, "Plot")

        let twistIdeas = app.getAllIdeas(from: session, filteredBy: .twist)
        XCTAssertEqual(twistIdeas.count, 1)
        XCTAssertEqual(twistIdeas[0].title, "Twist")
    }
}

// MARK: - isAIEnabled State Machine

final class WritersAppAIEnabledStateMachineTests: XCTestCase {

    private var config: AIConfiguration {
        AIConfiguration(apiKey: "test-key", model: .claude35Sonnet, maxTokens: 1024, temperature: 0.7)
    }

    func testInitWithoutConfigIsDisabled() {
        XCTAssertFalse(WritersApp().isAIEnabled)
    }

    func testInitWithConfigIsEnabled() {
        XCTAssertTrue(WritersApp(aiConfiguration: config).isAIEnabled)
    }

    func testEnableDisableToggle() {
        let app = WritersApp()

        app.enableAI(configuration: config)
        XCTAssertTrue(app.isAIEnabled)

        app.disableAI()
        XCTAssertFalse(app.isAIEnabled)

        app.enableAI(configuration: config)
        XCTAssertTrue(app.isAIEnabled)
    }

    /// Regression: after archiver removal, toggling AI multiple times must remain stable.
    func testRepeatToggleCyclesRemainStable() {
        let app = WritersApp()

        for cycle in 1...5 {
            app.enableAI(configuration: config)
            XCTAssertTrue(app.isAIEnabled, "Cycle \(cycle): expected AI enabled")
            XCTAssertNotNil(app.hermesService, "Cycle \(cycle): expected hermesService")

            app.disableAI()
            XCTAssertFalse(app.isAIEnabled, "Cycle \(cycle): expected AI disabled")
            XCTAssertNil(app.hermesService, "Cycle \(cycle): expected hermesService nil")
        }
    }
}
