import XCTest
@testable import WritersApp

// MARK: - WritersApp PR Changes Tests
// Tests for changes introduced in this PR: crmManager property, disableAI deduplication fix.

final class WritersAppCRMManagerTests: XCTestCase {

    // MARK: - crmManager initialization (PR change: new property added)

    func testCRMManagerIsNotNilAfterDefaultInit() {
        let app = WritersApp()
        // crmManager is a non-optional let property added in this PR; it must always be non-nil
        XCTAssertNotNil(app.crmManager,
                        "crmManager must be initialized and non-nil after WritersApp default init")
    }

    func testCRMManagerIsNotNilAfterAIConfigInit() {
        let config = AIConfiguration(apiKey: "test-key")
        let app = WritersApp(aiConfiguration: config)
        XCTAssertNotNil(app.crmManager,
                        "crmManager must be initialized regardless of AI configuration")
    }

    func testCRMManagerIsDistinctAcrossInstances() {
        let app1 = WritersApp()
        let app2 = WritersApp()
        // Each instance must have its own CRMManager (not shared)
        XCTAssertTrue(app1.crmManager !== app2.crmManager,
                      "Each WritersApp instance must have a separate CRMManager")
    }

    func testCRMManagerStartsEmpty() {
        let app = WritersApp()
        // A fresh CRMManager should have no contacts
        let contacts = app.crmManager.getAllContacts()
        XCTAssertTrue(contacts.isEmpty,
                      "crmManager must start with no contacts in a freshly created WritersApp")
    }

    func testCRMManagerIsAccessibleFromCreatedApp() {
        let app = WritersApp()
        // Verify we can perform basic operations on the manager
        let contact = app.crmManager.createContact(
            name: "Test Publisher",
            email: "pub@example.com",
            company: "Big Books Inc"
        )
        XCTAssertEqual(contact.name, "Test Publisher")
        XCTAssertEqual(app.crmManager.getAllContacts().count, 1)
    }
}

// MARK: - WritersApp disableAI deduplication fix tests

final class WritersAppDisableAITests: XCTestCase {

    func testDisableAIClearsWritingAdvisorService() {
        let app = WritersApp(aiConfiguration: AIConfiguration(apiKey: "key"))
        XCTAssertNotNil(app.writingAdvisorService)
        app.disableAI()
        XCTAssertNil(app.writingAdvisorService,
                     "disableAI() must set writingAdvisorService to nil")
    }

    func testDisableAIClearsAIService() {
        let app = WritersApp(aiConfiguration: AIConfiguration(apiKey: "key"))
        XCTAssertNotNil(app.aiService)
        app.disableAI()
        XCTAssertNil(app.aiService, "disableAI() must set aiService to nil")
    }

    func testDisableAIClearsChatbotService() {
        let app = WritersApp(aiConfiguration: AIConfiguration(apiKey: "key"))
        XCTAssertNotNil(app.chatbotService)
        app.disableAI()
        XCTAssertNil(app.chatbotService, "disableAI() must set chatbotService to nil")
    }

    func testDisableAIClearsHermesService() {
        let app = WritersApp(aiConfiguration: AIConfiguration(apiKey: "key"))
        XCTAssertNotNil(app.hermesService)
        app.disableAI()
        XCTAssertNil(app.hermesService, "disableAI() must set hermesService to nil")
    }

    func testDisableAISetsIsAIEnabledToFalse() {
        let app = WritersApp(aiConfiguration: AIConfiguration(apiKey: "key"))
        XCTAssertTrue(app.isAIEnabled)
        app.disableAI()
        XCTAssertFalse(app.isAIEnabled, "isAIEnabled must be false after disableAI()")
    }

    func testDisableAIIsIdempotent() {
        // Regression: calling disableAI() twice must not crash
        let app = WritersApp(aiConfiguration: AIConfiguration(apiKey: "key"))
        app.disableAI()
        XCTAssertNoThrow(app.disableAI(), "disableAI() must be safe to call multiple times")
        XCTAssertNil(app.writingAdvisorService)
        XCTAssertFalse(app.isAIEnabled)
    }

    func testDisableAIOnAppWithoutAIIsNoOp() {
        // Calling disableAI() on an app that never had AI must not crash
        let app = WritersApp()
        XCTAssertNil(app.aiService)
        XCTAssertNoThrow(app.disableAI(), "disableAI() on app without AI must not throw")
        XCTAssertNil(app.writingAdvisorService)
    }
}

// MARK: - WritersApp enableAI deduplication fix tests

final class WritersAppEnableAITests: XCTestCase {

    func testEnableAICreatesWritingAdvisorService() {
        let app = WritersApp()
        XCTAssertNil(app.writingAdvisorService)
        app.enableAI(configuration: AIConfiguration(apiKey: "key"))
        XCTAssertNotNil(app.writingAdvisorService,
                        "enableAI() must create a WritingAdvisorService instance")
    }

    func testEnableAICreatesHermesService() {
        let app = WritersApp()
        XCTAssertNil(app.hermesService)
        app.enableAI(configuration: AIConfiguration(apiKey: "key"))
        XCTAssertNotNil(app.hermesService,
                        "enableAI() must create a HermesService instance")
    }

    func testEnableAIReplacesExistingServicesOnReEnable() {
        let app = WritersApp()
        app.enableAI(configuration: AIConfiguration(apiKey: "key-1"))
        let firstAdvisor = app.writingAdvisorService
        let firstHermes = app.hermesService

        app.enableAI(configuration: AIConfiguration(apiKey: "key-2"))
        // After re-enable the services must be new instances
        XCTAssertNotNil(app.writingAdvisorService)
        XCTAssertNotNil(app.hermesService)
        XCTAssertTrue(app.writingAdvisorService !== firstAdvisor,
                      "Re-enabling AI must produce a new WritingAdvisorService instance")
        XCTAssertTrue(app.hermesService !== firstHermes,
                      "Re-enabling AI must produce a new HermesService instance")
    }

    func testEnableAIThenDisableAIClearsAllServices() {
        let app = WritersApp()
        app.enableAI(configuration: AIConfiguration(apiKey: "key"))
        XCTAssertTrue(app.isAIEnabled)

        app.disableAI()
        XCTAssertFalse(app.isAIEnabled)
        XCTAssertNil(app.writingAdvisorService)
        XCTAssertNil(app.hermesService)
        XCTAssertNil(app.chatbotService)
    }

    func testInitWithAIConfigurationSetsUpAllServices() {
        let config = AIConfiguration(apiKey: "init-key")
        let app = WritersApp(aiConfiguration: config)
        XCTAssertNotNil(app.aiService)
        XCTAssertNotNil(app.chatbotService)
        XCTAssertNotNil(app.hermesService)
        XCTAssertNotNil(app.writingAdvisorService)
    }

    func testInitWithoutAIConfigurationLeavesServicesNil() {
        let app = WritersApp()
        XCTAssertNil(app.aiService)
        XCTAssertNil(app.chatbotService)
        XCTAssertNil(app.hermesService)
        XCTAssertNil(app.writingAdvisorService)
    }
}

// MARK: - WritersApp Hermes Session Regression Tests (PR removed favorites/stats methods)

final class WritersAppHermesSessionRegressionTests: XCTestCase {

    /// Regression: endHermesSession must be safe to call even when hermesService
    /// has been cleared by disableAI() (which is the PR's behavior).
    func testEndHermesSessionAfterDisableAIIsNoOp() {
        let app = WritersApp(aiConfiguration: AIConfiguration(apiKey: "key"))
        XCTAssertNotNil(app.hermesService)
        app.startHermesSession(context: HermesContext(genre: "Fantasy"))
        app.disableAI()
        XCTAssertNil(app.hermesService)
        // Must not crash even though hermesService is now nil
        XCTAssertNoThrow(app.endHermesSession())
    }

    /// Regression: calling endHermesSession when no session is active and
    /// hermesService is nil must be a no-op.
    func testEndHermesSessionWithoutStartIsNoOp() {
        let app = WritersApp()
        XCTAssertNoThrow(app.endHermesSession(),
                         "endHermesSession must not crash when called without starting a session")
    }

    /// The crmManager must retain contacts added across multiple operations,
    /// confirming it is properly initialized and not re-created.
    func testCRMManagerRetainsMultipleContacts() {
        let app = WritersApp()
        app.crmManager.createContact(name: "Publisher A", email: "a@pub.com")
        app.crmManager.createContact(name: "Editor B", email: "b@edit.com")
        app.crmManager.createContact(name: "Agent C", email: "c@agent.com")
        XCTAssertEqual(app.crmManager.getAllContacts().count, 3,
                       "crmManager must retain all created contacts")
    }

    /// Regression: disableAI must not affect the crmManager (it's not an AI service).
    func testCRMManagerSurvivesDisableAI() {
        let app = WritersApp(aiConfiguration: AIConfiguration(apiKey: "key"))
        app.crmManager.createContact(name: "Survivor", email: "ok@test.com")
        app.disableAI()
        // crmManager must still have its data
        XCTAssertEqual(app.crmManager.getAllContacts().count, 1,
                       "crmManager data must not be cleared by disableAI()")
    }

    /// Regression: brainstormIdeas must throw AIError.aiNotEnabled when AI is off.
    func testBrainstormIdeasThrowsWhenAINotEnabled() async {
        let app = WritersApp()
        do {
            _ = try await app.brainstormIdeas(topic: "dragons")
            XCTFail("brainstormIdeas must throw when AI is not enabled")
        } catch {
            // Any error is acceptable; the key point is it must not silently succeed
            XCTAssertNotNil(error)
        }
    }
}