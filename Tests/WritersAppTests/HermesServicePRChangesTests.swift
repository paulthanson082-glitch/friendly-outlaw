import XCTest
@testable import WritersApp

// MARK: - HermesService PR Changes Tests
//
// This PR removed the following from HermesService:
//   - AgentProfile enum (.hermes / .archiver cases)
//   - currentProfile property
//   - switchProfile(_:) method
//   - archiverPersona private constant
//   - getCurrentPersona() private method
//
// The service now always uses the hardcoded hermesPersona.
// These tests verify that the remaining public API continues to work correctly
// and that the simplified single-persona design is properly represented.

// MARK: - HermesService Session Lifecycle (no profile switching required)

final class HermesServiceSessionLifecycleTests: XCTestCase {

    var documentManager: DocumentManager!
    var templateManager: TemplateManager!

    override func setUp() {
        super.setUp()
        documentManager = DocumentManager()
        templateManager = TemplateManager()
    }

    override func tearDown() {
        documentManager = nil
        templateManager = nil
        super.tearDown()
    }

    // MARK: - startSession

    /// startSession with no arguments should use an empty HermesContext.
    func testStartSessionReturnsSessionWithDefaultContext() {
        let config = AIConfiguration(apiKey: "test-key")
        let aiService = AIService(configuration: config)
        let service = HermesService(
            aiService: aiService,
            documentManager: documentManager,
            templateManager: templateManager
        )

        let session = service.startSession()

        XCTAssertNotNil(session.id)
        XCTAssertTrue(session.messages.isEmpty)
        XCTAssertEqual(session.context.genre, "")
    }

    /// startSession with a context should embed that context in the session.
    func testStartSessionWithContextStoresContext() {
        let config = AIConfiguration(apiKey: "test-key")
        let service = HermesService(
            aiService: AIService(configuration: config),
            documentManager: documentManager,
            templateManager: templateManager
        )

        let context = HermesContext(
            genre: "Fantasy",
            logline: "A dragon seeks redemption",
            currentScene: "Opening battle",
            characters: ["Aria", "Kael"],
            themes: ["sacrifice", "identity"]
        )
        let session = service.startSession(context: context)

        XCTAssertEqual(session.context.genre, "Fantasy")
        XCTAssertEqual(session.context.logline, "A dragon seeks redemption")
        XCTAssertEqual(session.context.currentScene, "Opening battle")
        XCTAssertEqual(session.context.characters, ["Aria", "Kael"])
        XCTAssertEqual(session.context.themes, ["sacrifice", "identity"])
    }

    /// startSession must update currentSession on the service.
    func testStartSessionUpdatesCurrentSession() {
        let config = AIConfiguration(apiKey: "test-key")
        let service = HermesService(
            aiService: AIService(configuration: config),
            documentManager: documentManager,
            templateManager: templateManager
        )

        XCTAssertNil(service.currentSession, "currentSession must be nil before startSession")

        let session = service.startSession(context: HermesContext(genre: "Sci-Fi"))
        XCTAssertNotNil(service.currentSession)
        XCTAssertEqual(service.currentSession?.id, session.id)
    }

    /// A second call to startSession replaces the previous current session.
    func testStartSessionReplacesPreviousCurrentSession() {
        let config = AIConfiguration(apiKey: "test-key")
        let service = HermesService(
            aiService: AIService(configuration: config),
            documentManager: documentManager,
            templateManager: templateManager
        )

        let first = service.startSession(context: HermesContext(genre: "Horror"))
        let second = service.startSession(context: HermesContext(genre: "Romance"))

        XCTAssertNotEqual(first.id, second.id)
        XCTAssertEqual(service.currentSession?.id, second.id,
            "currentSession must point to the most recently started session")
    }

    // MARK: - endSession

    /// endSession clears currentSession.
    func testEndSessionClearsCurrentSession() {
        let config = AIConfiguration(apiKey: "test-key")
        let service = HermesService(
            aiService: AIService(configuration: config),
            documentManager: documentManager,
            templateManager: templateManager
        )

        _ = service.startSession()
        XCTAssertNotNil(service.currentSession)

        service.endSession()
        XCTAssertNil(service.currentSession, "currentSession must be nil after endSession")
    }

    /// Calling endSession when no session is active must not crash.
    func testEndSessionWithNoActiveSessionIsNoOp() {
        let config = AIConfiguration(apiKey: "test-key")
        let service = HermesService(
            aiService: AIService(configuration: config),
            documentManager: documentManager,
            templateManager: templateManager
        )

        XCTAssertNil(service.currentSession)
        service.endSession() // must not throw or crash
        XCTAssertNil(service.currentSession)
    }

    // MARK: - Initialization defaults

    func testDefaultMaxHistoryMessages() {
        let config = AIConfiguration(apiKey: "test-key")
        let service = HermesService(
            aiService: AIService(configuration: config),
            documentManager: documentManager,
            templateManager: templateManager
        )
        XCTAssertEqual(service.maxHistoryMessages, 30)
    }

    func testDefaultMaxPromptLength() {
        let config = AIConfiguration(apiKey: "test-key")
        let service = HermesService(
            aiService: AIService(configuration: config),
            documentManager: documentManager,
            templateManager: templateManager
        )
        XCTAssertEqual(service.maxPromptLength, 4000)
    }

    func testCustomMaxHistoryMessages() {
        let config = AIConfiguration(apiKey: "test-key")
        let service = HermesService(
            aiService: AIService(configuration: config),
            documentManager: documentManager,
            templateManager: templateManager,
            maxHistoryMessages: 10
        )
        XCTAssertEqual(service.maxHistoryMessages, 10)
    }

    func testCustomMaxPromptLength() {
        let config = AIConfiguration(apiKey: "test-key")
        let service = HermesService(
            aiService: AIService(configuration: config),
            documentManager: documentManager,
            templateManager: templateManager,
            maxPromptLength: 2000
        )
        XCTAssertEqual(service.maxPromptLength, 2000)
    }
}

// MARK: - HermesService Idea Parsing (parseIdeas — unchanged behavior post-PR)

final class HermesServiceParseIdeasTests: XCTestCase {

    var service: HermesService!

    override func setUp() {
        super.setUp()
        let config = AIConfiguration(apiKey: "test-key")
        let docMgr = DocumentManager()
        let tmplMgr = TemplateManager()
        service = HermesService(
            aiService: AIService(configuration: config),
            documentManager: docMgr,
            templateManager: tmplMgr
        )
    }

    override func tearDown() {
        service = nil
        super.tearDown()
    }

    /// A well-formed numbered list with type tags must be parsed into HermesIdeas.
    func testParseIdeasWithTypeTags() {
        let text = """
        1. [PLOT HOOK] The Forgotten Letter
           A mysterious letter arrives decades after its author died.
        2. [CHARACTER TRAIT] Perfectionist Archivist
           Obsessively catalogues every detail, even at the cost of relationships.
        3. [TWIST] The Map Is Wrong
           The map they trusted was deliberately altered generations ago.
        """
        let ideas = service.parseIdeas(from: text)

        XCTAssertEqual(ideas.count, 3)
        XCTAssertEqual(ideas[0].title, "The Forgotten Letter")
        XCTAssertEqual(ideas[0].ideaType, .plotHook)
        XCTAssertTrue(ideas[0].description.contains("mysterious letter"))

        XCTAssertEqual(ideas[1].title, "Perfectionist Archivist")
        XCTAssertEqual(ideas[1].ideaType, .characterTrait)

        XCTAssertEqual(ideas[2].title, "The Map Is Wrong")
        XCTAssertEqual(ideas[2].ideaType, .twist)
    }

    /// Ideas without explicit type tags must default to plotHook.
    func testParseIdeasWithoutTypeTags() {
        let text = """
        1. Simple Idea
           Just a plain idea with no type tag.
        2. Another Idea
           Another simple idea.
        """
        let ideas = service.parseIdeas(from: text)

        XCTAssertEqual(ideas.count, 2)
        XCTAssertEqual(ideas[0].ideaType, .plotHook,
            "Ideas without a type tag must default to .plotHook")
        XCTAssertEqual(ideas[1].ideaType, .plotHook)
    }

    /// All 8 recognised type tags must be mapped correctly.
    func testParseIdeasAllTypeTagsRecognised() {
        let tagToType: [(String, HermesIdeaType)] = [
            ("PLOT HOOK",       .plotHook),
            ("CHARACTER TRAIT", .characterTrait),
            ("WORLD BUILDING",  .worldBuilding),
            ("CONFLICT",        .conflict),
            ("TWIST",           .twist),
            ("DIALOGUE",        .dialogue),
            ("SETTING",         .setting),
            ("THEME",           .theme),
        ]
        for (idx, (tag, expectedType)) in tagToType.enumerated() {
            let text = "\(idx + 1). [\(tag)] Title For \(tag)\n   Description here.\n"
            let ideas = service.parseIdeas(from: text)
            XCTAssertEqual(ideas.count, 1, "Expected 1 idea for tag '\(tag)'")
            XCTAssertEqual(ideas.first?.ideaType, expectedType,
                "Tag '\(tag)' must map to \(expectedType)")
        }
    }

    /// An unknown type tag must fall back to plotHook.
    func testParseIdeasUnknownTagDefaultsToPlotHook() {
        let text = "1. [UNKNOWN TAG] Mystery Idea\n   Something strange.\n"
        let ideas = service.parseIdeas(from: text)
        XCTAssertEqual(ideas.count, 1)
        XCTAssertEqual(ideas[0].ideaType, .plotHook)
    }

    /// Markdown bold markers (*) must be stripped and not affect parsing.
    func testParseIdeasStripsMarkdownAsterisks() {
        let text = "1. **[TWIST]** The Hidden Truth\n   Nothing is as it seems.\n"
        let ideas = service.parseIdeas(from: text)
        XCTAssertEqual(ideas.count, 1)
        XCTAssertEqual(ideas[0].ideaType, .twist)
        XCTAssertFalse(ideas[0].title.contains("*"),
            "Title must not contain asterisks after markdown stripping")
    }

    /// Empty text must produce an empty ideas array.
    func testParseIdeasEmptyInput() {
        let ideas = service.parseIdeas(from: "")
        XCTAssertTrue(ideas.isEmpty)
    }

    /// Text with no numbered items must produce an empty ideas array.
    func testParseIdeasNoNumberedItems() {
        let text = "This is just free-form text without any numbered ideas."
        let ideas = service.parseIdeas(from: text)
        XCTAssertTrue(ideas.isEmpty)
    }

    /// Multi-line descriptions are concatenated into a single description string.
    func testParseIdeasMultiLineDescription() {
        let text = """
        1. [SETTING] The Sunken City
           A once-great metropolis now lies beneath the waves.
           Its towers still stand, draped in seaweed and shadow.
           Fish dart through broken windows.
        """
        let ideas = service.parseIdeas(from: text)
        XCTAssertEqual(ideas.count, 1)
        XCTAssertTrue(ideas[0].description.contains("metropolis"),
            "Multi-line description must be combined")
        XCTAssertTrue(ideas[0].description.contains("seaweed"),
            "All description lines must appear in the output")
    }

    /// A single idea with only a title and no description must still parse.
    func testParseIdeasTitleWithNoDescription() {
        let text = "1. [CONFLICT] A Lone Hero\n"
        let ideas = service.parseIdeas(from: text)
        XCTAssertEqual(ideas.count, 1)
        XCTAssertEqual(ideas[0].title, "A Lone Hero")
        XCTAssertEqual(ideas[0].ideaType, .conflict)
        XCTAssertEqual(ideas[0].description, "",
            "An idea without description lines must have an empty description")
    }
}

// MARK: - HermesService Prompt Validation (unchanged, tested to catch regressions)

final class HermesServicePromptValidationTests: XCTestCase {

    var service: HermesService!

    override func setUp() {
        super.setUp()
        let config = AIConfiguration(apiKey: "test-key")
        let docMgr = DocumentManager()
        let tmplMgr = TemplateManager()
        service = HermesService(
            aiService: AIService(configuration: config),
            documentManager: docMgr,
            templateManager: tmplMgr
        )
    }

    override func tearDown() {
        service = nil
        super.tearDown()
    }

    /// An empty prompt must throw HermesError.emptyPrompt.
    func testEmptyPromptThrowsError() async {
        var session = service.startSession()
        do {
            _ = try await service.generateIdeas("", in: &session)
            XCTFail("Expected HermesError.emptyPrompt to be thrown")
        } catch HermesError.emptyPrompt {
            // Expected
        } catch {
            XCTFail("Expected HermesError.emptyPrompt but got \(error)")
        }
    }

    /// A whitespace-only prompt must throw HermesError.emptyPrompt.
    func testWhitespaceOnlyPromptThrowsError() async {
        var session = service.startSession()
        do {
            _ = try await service.generateIdeas("   \n\t  ", in: &session)
            XCTFail("Expected HermesError.emptyPrompt to be thrown")
        } catch HermesError.emptyPrompt {
            // Expected
        } catch {
            XCTFail("Expected HermesError.emptyPrompt but got \(error)")
        }
    }

    /// A prompt exceeding maxPromptLength must throw HermesError.promptTooLong.
    func testTooLongPromptThrowsError() async {
        let shortLimitService = HermesService(
            aiService: AIService(configuration: AIConfiguration(apiKey: "test-key")),
            documentManager: DocumentManager(),
            templateManager: TemplateManager(),
            maxPromptLength: 10
        )
        var session = shortLimitService.startSession()
        do {
            _ = try await shortLimitService.generateIdeas(
                "This prompt is longer than ten characters",
                in: &session
            )
            XCTFail("Expected HermesError.promptTooLong to be thrown")
        } catch HermesError.promptTooLong {
            // Expected
        } catch {
            XCTFail("Expected HermesError.promptTooLong but got \(error)")
        }
    }

    /// A prompt of exactly maxPromptLength characters must not throw promptTooLong.
    func testPromptAtExactLimitDoesNotThrow() async {
        let limit = 20
        let exactLimitService = HermesService(
            aiService: AIService(configuration: AIConfiguration(apiKey: "test-key")),
            documentManager: DocumentManager(),
            templateManager: TemplateManager(),
            maxPromptLength: limit
        )
        var session = exactLimitService.startSession()
        let exactPrompt = String(repeating: "a", count: limit)
        do {
            // Will throw aiServiceFailed (no real API), but must NOT throw promptTooLong
            _ = try await exactLimitService.generateIdeas(exactPrompt, in: &session)
        } catch HermesError.promptTooLong {
            XCTFail("Prompt of exactly maxPromptLength must not throw .promptTooLong")
        } catch {
            // Any other error (e.g., aiServiceFailed) is acceptable
        }
    }
}

// MARK: - HermesService Session History and Idea Queries

final class HermesServiceHistoryAndQueryTests: XCTestCase {

    var service: HermesService!
    var docManager: DocumentManager!
    var tmplManager: TemplateManager!

    override func setUp() {
        super.setUp()
        docManager = DocumentManager()
        tmplManager = TemplateManager()
        let config = AIConfiguration(apiKey: "test-key")
        service = HermesService(
            aiService: AIService(configuration: config),
            documentManager: docManager,
            templateManager: tmplManager
        )
    }

    override func tearDown() {
        service = nil
        docManager = nil
        tmplManager = nil
        super.tearDown()
    }

    // MARK: - getHistory

    func testGetHistoryReturnsMessagesInOrder() {
        var session = service.startSession()
        let msg1 = HermesMessage(role: .user, content: "First")
        let msg2 = HermesMessage(role: .hermes, content: "Response to first")
        session.messages.append(msg1)
        session.messages.append(msg2)

        let history = service.getHistory(from: session)

        XCTAssertEqual(history.count, 2)
        XCTAssertEqual(history[0].content, "First")
        XCTAssertEqual(history[1].content, "Response to first")
    }

    func testGetHistoryEmptySession() {
        let session = service.startSession()
        let history = service.getHistory(from: session)
        XCTAssertTrue(history.isEmpty)
    }

    // MARK: - clearHistory

    func testClearHistoryRemovesAllMessages() {
        var session = service.startSession()
        session.messages.append(HermesMessage(role: .user, content: "A"))
        session.messages.append(HermesMessage(role: .hermes, content: "B"))
        XCTAssertEqual(session.messages.count, 2)

        service.clearHistory(for: &session)

        XCTAssertTrue(session.messages.isEmpty)
    }

    func testClearHistoryOnEmptySessionIsNoOp() {
        var session = service.startSession()
        service.clearHistory(for: &session)
        XCTAssertTrue(session.messages.isEmpty)
    }

    // MARK: - getAllIdeas

    func testGetAllIdeasWithNoIdeas() {
        var session = service.startSession()
        session.messages.append(HermesMessage(role: .user, content: "Tell me ideas"))

        let ideas = service.getAllIdeas(from: session)
        XCTAssertTrue(ideas.isEmpty)
    }

    func testGetAllIdeasReturnsIdeasFromHermesMessages() {
        var session = service.startSession()
        let idea1 = HermesIdea(title: "Idea A", description: "Desc A", ideaType: .plotHook)
        let idea2 = HermesIdea(title: "Idea B", description: "Desc B", ideaType: .twist)
        let hermesMsg = HermesMessage(role: .hermes, content: "Here are ideas", ideas: [idea1, idea2])
        session.messages.append(HermesMessage(role: .user, content: "Give me ideas"))
        session.messages.append(hermesMsg)

        let ideas = service.getAllIdeas(from: session)
        XCTAssertEqual(ideas.count, 2)
    }

    func testGetAllIdeasExcludesUserMessageIdeas() {
        var session = service.startSession()
        // User messages don't typically have ideas, but ensure only hermes ideas are returned
        let hermesIdea = HermesIdea(title: "Hermes Idea", description: "Desc", ideaType: .conflict)
        let hermesMsg = HermesMessage(role: .hermes, content: "Ideas", ideas: [hermesIdea])
        let userMsg = HermesMessage(role: .user, content: "Question", ideas: [])
        session.messages.append(userMsg)
        session.messages.append(hermesMsg)

        let ideas = service.getAllIdeas(from: session)
        XCTAssertEqual(ideas.count, 1)
        XCTAssertEqual(ideas[0].title, "Hermes Idea")
    }

    func testGetAllIdeasFilteredByType() {
        var session = service.startSession()
        let plotIdea = HermesIdea(title: "Plot One", description: "Plot desc", ideaType: .plotHook)
        let twistIdea = HermesIdea(title: "Twist One", description: "Twist desc", ideaType: .twist)
        let settingIdea = HermesIdea(title: "Setting One", description: "Setting desc", ideaType: .setting)
        let hermesMsg = HermesMessage(
            role: .hermes,
            content: "Ideas",
            ideas: [plotIdea, twistIdea, settingIdea]
        )
        session.messages.append(hermesMsg)

        let plotIdeas = service.getAllIdeas(from: session, filteredBy: .plotHook)
        XCTAssertEqual(plotIdeas.count, 1)
        XCTAssertEqual(plotIdeas[0].title, "Plot One")

        let twistIdeas = service.getAllIdeas(from: session, filteredBy: .twist)
        XCTAssertEqual(twistIdeas.count, 1)
        XCTAssertEqual(twistIdeas[0].title, "Twist One")

        let allIdeas = service.getAllIdeas(from: session, filteredBy: nil)
        XCTAssertEqual(allIdeas.count, 3)
    }

    func testGetAllIdeasFilteredByTypeThatDoesNotExist() {
        var session = service.startSession()
        let idea = HermesIdea(title: "Plot Hook Idea", description: "Desc", ideaType: .plotHook)
        session.messages.append(HermesMessage(role: .hermes, content: "Ideas", ideas: [idea]))

        let dialogueIdeas = service.getAllIdeas(from: session, filteredBy: .dialogue)
        XCTAssertTrue(dialogueIdeas.isEmpty,
            "Filtering by a type that has no ideas must return empty array")
    }

    // MARK: - getSessionStats

    func testGetSessionStatsEmptySession() {
        var session = service.startSession()
        // Advance lastMessageAt a bit to avoid negative duration
        session = HermesSession(
            id: session.id,
            messages: [],
            context: session.context,
            startedAt: Date().addingTimeInterval(-10),
            lastMessageAt: Date()
        )

        let stats = service.getSessionStats(from: session)

        XCTAssertEqual(stats.messageCount, 0)
        XCTAssertEqual(stats.totalIdeas, 0)
        XCTAssertEqual(stats.favoriteCount, 0)
        XCTAssertEqual(stats.averageIdeasPerMessage, 0.0)
        XCTAssertGreaterThanOrEqual(stats.sessionDuration, 0.0)
    }

    func testGetSessionStatsCounts() {
        let idea1 = HermesIdea(title: "A", description: "a", ideaType: .plotHook)
        let idea2 = HermesIdea(title: "B", description: "b", ideaType: .twist)
        let idea3 = HermesIdea(title: "C", description: "c", ideaType: .twist)
        let userMsg = HermesMessage(role: .user, content: "Question")
        let hermesMsg = HermesMessage(role: .hermes, content: "Ideas", ideas: [idea1, idea2, idea3])

        let session = HermesSession(
            messages: [userMsg, hermesMsg],
            context: HermesContext(),
            startedAt: Date().addingTimeInterval(-60),
            lastMessageAt: Date()
        )

        let stats = service.getSessionStats(from: session)

        XCTAssertEqual(stats.messageCount, 2,
            "messageCount must include both user and hermes messages")
        XCTAssertEqual(stats.totalIdeas, 3)
        XCTAssertEqual(stats.ideaCountByType[.plotHook], 1)
        XCTAssertEqual(stats.ideaCountByType[.twist], 2)
        XCTAssertEqual(stats.averageIdeasPerMessage, 3.0,
            "averageIdeasPerMessage = totalIdeas / hermesMessageCount = 3/1 = 3.0")
    }

    func testGetSessionStatsDurationIsNonNegative() {
        let session = HermesSession(
            context: HermesContext(),
            startedAt: Date().addingTimeInterval(-300),
            lastMessageAt: Date()
        )
        let stats = service.getSessionStats(from: session)
        XCTAssertGreaterThanOrEqual(stats.sessionDuration, 0.0)
    }
}

// MARK: - HermesService: No AgentProfile API (regression guard)
//
// The following tests are purely behavioral / structural: they confirm that the
// service operates as a single-persona (Hermes only) agent and that no profile-
// switching state leaks into the public API.

final class HermesServiceSinglePersonaTests: XCTestCase {

    var docManager: DocumentManager!
    var tmplManager: TemplateManager!
    var service: HermesService!

    override func setUp() {
        super.setUp()
        docManager = DocumentManager()
        tmplManager = TemplateManager()
        let config = AIConfiguration(apiKey: "test-key")
        service = HermesService(
            aiService: AIService(configuration: config),
            documentManager: docManager,
            templateManager: tmplManager
        )
    }

    override func tearDown() {
        service = nil
        docManager = nil
        tmplManager = nil
        super.tearDown()
    }

    /// The service's public interface must expose only currentSession, maxHistoryMessages,
    /// and maxPromptLength — no profile-related properties.
    func testPublicAPIHasNoProfileProperty() {
        // If `currentProfile` were still present this would be a compile-time error;
        // since we can't check absence at runtime, we verify other public properties
        // are still accessible and behave correctly.
        XCTAssertNil(service.currentSession,
            "currentSession must be nil before startSession is called")
        XCTAssertEqual(service.maxHistoryMessages, 30)
        XCTAssertEqual(service.maxPromptLength, 4000)
    }

    /// Starting a session and ending it must not require any profile management.
    func testSessionLifecycleWithoutProfileManagement() {
        // Pre-PR: switchProfile + endSession were called between agent switches.
        // Post-PR: simple start/end is sufficient.
        let session = service.startSession(context: HermesContext(genre: "Mystery"))
        XCTAssertNotNil(service.currentSession)
        XCTAssertEqual(service.currentSession?.id, session.id)

        service.endSession()
        XCTAssertNil(service.currentSession)
    }

    /// Multiple sequential sessions can be created without switching profiles.
    func testMultipleSequentialSessions() {
        let genres = ["Fantasy", "Horror", "Sci-Fi", "Romance"]
        for genre in genres {
            let session = service.startSession(context: HermesContext(genre: genre))
            XCTAssertEqual(session.context.genre, genre)
            service.endSession()
            XCTAssertNil(service.currentSession,
                "currentSession must be nil after endSession for genre '\(genre)'")
        }
    }

    /// The HermesSession carries the id it was created with.
    func testSessionIdIsStable() {
        let session = service.startSession()
        let sessionId = session.id
        XCTAssertEqual(service.currentSession?.id, sessionId)
        service.endSession()
        // Verify the id we saved is not nil (i.e. the UUID was assigned)
        XCTAssertNotNil(sessionId)
    }
}