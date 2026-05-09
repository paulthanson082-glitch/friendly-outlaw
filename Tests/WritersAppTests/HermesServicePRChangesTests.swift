import XCTest
@testable import WritersApp

// MARK: - HermesService PR Changes Tests
//
// This PR removed the following from HermesService.swift:
//   - AgentProfile enum (cases: .hermes, .archiver)
//   - currentProfile public property
//   - switchProfile(_:) public method
//   - archiverPersona private property
//   - getCurrentPersona() private method
//
// The service now always uses hermesPersona directly in generateIdeas().
//
// Tests here verify:
//   1. The remaining HermesService API still works correctly (non-regression).
//   2. Session lifecycle (startSession / endSession) is unaffected.
//   3. Prompt validation logic is unaffected.
//   4. Idea parsing logic is unaffected.
//   5. History management is unaffected.
//   6. getSessionStats still computes correct aggregates.

// MARK: - Session Lifecycle (no-profile-switching path)

final class HermesServiceSessionLifecycleTests: XCTestCase {

    // MARK: - startSession

    /// startSession returns a fresh session and makes it the active session.
    func testStartSessionReturnsNewSession() {
        let service = makeHermesService()
        let session = service.startSession()

        XCTAssertNotNil(session.id)
        XCTAssertTrue(session.messages.isEmpty)
    }

    /// startSession with a custom context stores the context on the session.
    func testStartSessionStoresContext() {
        let service = makeHermesService()
        let context = HermesContext(genre: "Fantasy", logline: "A hero's quest")
        let session = service.startSession(context: context)

        XCTAssertEqual(session.context.genre, "Fantasy")
        XCTAssertEqual(session.context.logline, "A hero's quest")
    }

    /// After startSession, currentSession is set.
    func testStartSessionSetsCurrentSession() {
        let service = makeHermesService()
        let session = service.startSession()

        XCTAssertEqual(service.currentSession?.id, session.id)
    }

    /// startSession replaces any previously active session.
    func testStartSessionReplacesPreviousSession() {
        let service = makeHermesService()
        let first = service.startSession()
        let second = service.startSession()

        XCTAssertNotEqual(first.id, second.id)
        XCTAssertEqual(service.currentSession?.id, second.id)
    }

    // MARK: - endSession

    /// endSession clears the currentSession.
    func testEndSessionClearsCurrentSession() {
        let service = makeHermesService()
        _ = service.startSession()
        XCTAssertNotNil(service.currentSession)

        service.endSession()
        XCTAssertNil(service.currentSession)
    }

    /// Calling endSession when no session is active is a no-op.
    func testEndSessionWhenNoActiveSessionIsNoOp() {
        let service = makeHermesService()
        XCTAssertNil(service.currentSession)
        service.endSession() // must not crash
        XCTAssertNil(service.currentSession)
    }

    /// Multiple consecutive endSession calls do not crash.
    func testEndSessionCalledMultipleTimesIsIdempotent() {
        let service = makeHermesService()
        _ = service.startSession()

        service.endSession()
        service.endSession()

        XCTAssertNil(service.currentSession)
    }
}

// MARK: - Prompt Validation (unaffected by profile removal)

final class HermesServicePromptValidationTests: XCTestCase {

    /// An empty prompt throws HermesError.emptyPrompt.
    func testEmptyPromptThrows() async {
        let service = makeHermesService()
        var session = service.startSession()

        do {
            _ = try await service.generateIdeas("", in: &session)
            XCTFail("Expected emptyPrompt error")
        } catch HermesError.emptyPrompt {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    /// A whitespace-only prompt throws HermesError.emptyPrompt.
    func testWhitespaceOnlyPromptThrows() async {
        let service = makeHermesService()
        var session = service.startSession()

        do {
            _ = try await service.generateIdeas("   \n\t  ", in: &session)
            XCTFail("Expected emptyPrompt error")
        } catch HermesError.emptyPrompt {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    /// A prompt exceeding maxPromptLength throws HermesError.promptTooLong.
    func testTooLongPromptThrows() async {
        let maxLength = 100
        let service = makeHermesService(maxPromptLength: maxLength)
        var session = service.startSession()
        let longPrompt = String(repeating: "x", count: maxLength + 1)

        do {
            _ = try await service.generateIdeas(longPrompt, in: &session)
            XCTFail("Expected promptTooLong error")
        } catch HermesError.promptTooLong {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    /// A prompt of exactly maxPromptLength characters does not throw a length error.
    func testExactMaxLengthPromptPassesValidation() async {
        let maxLength = 50
        let service = makeHermesService(maxPromptLength: maxLength)
        var session = service.startSession()
        let exactPrompt = String(repeating: "a", count: maxLength)

        do {
            _ = try await service.generateIdeas(exactPrompt, in: &session)
        } catch HermesError.promptTooLong {
            XCTFail("A prompt of exactly maxPromptLength should not throw promptTooLong")
        } catch HermesError.aiServiceFailed {
            // AI not available in tests — that's fine, it means validation passed
        } catch {
            // Other errors (e.g., network not available) are acceptable here
        }
    }
}

// MARK: - Idea Parsing (unaffected by profile removal)

final class HermesServiceIdeaParsingTests: XCTestCase {

    private func service() -> HermesService {
        return makeHermesService()
    }

    /// A numbered list with TYPE tags is correctly parsed.
    func testParseIdeasWithTypeTags() {
        let text = """
        1. [PLOT HOOK] The Ancient Map
           An old map discovered in the attic leads to a buried secret.
        2. [CHARACTER TRAIT] Stubborn Optimism
           The hero refuses to give up no matter what.
        """

        let ideas = service().parseIdeas(from: text)

        XCTAssertEqual(ideas.count, 2)
        XCTAssertEqual(ideas[0].title, "The Ancient Map")
        XCTAssertEqual(ideas[0].ideaType, .plotHook)
        XCTAssertTrue(ideas[0].description.contains("secret"))

        XCTAssertEqual(ideas[1].title, "Stubborn Optimism")
        XCTAssertEqual(ideas[1].ideaType, .characterTrait)
    }

    /// A numbered list without TYPE tags defaults to .plotHook.
    func testParseIdeasWithoutTagsDefaultsToPlotHook() {
        let text = """
        1. The Dragon's Bargain
           The dragon offers the villagers a deal they can't refuse.
        """

        let ideas = service().parseIdeas(from: text)

        XCTAssertEqual(ideas.count, 1)
        XCTAssertEqual(ideas[0].ideaType, .plotHook)
        XCTAssertEqual(ideas[0].title, "The Dragon's Bargain")
    }

    /// Empty text produces no ideas.
    func testParseIdeasFromEmptyTextReturnsEmpty() {
        let ideas = service().parseIdeas(from: "")
        XCTAssertTrue(ideas.isEmpty)
    }

    /// Text with no numbered items produces no ideas.
    func testParseIdeasFromNonListTextReturnsEmpty() {
        let text = "Just some narrative text without any numbered list items here."
        let ideas = service().parseIdeas(from: text)
        XCTAssertTrue(ideas.isEmpty)
    }

    /// Bold markdown asterisks are stripped from titles and descriptions.
    func testParseIdeasStripsAsterisks() {
        let text = """
        1. *[TWIST] The Hidden Heir*
           *The king's advisor was secretly the true heir all along.*
        """

        let ideas = service().parseIdeas(from: text)

        XCTAssertEqual(ideas.count, 1)
        XCTAssertFalse(ideas[0].title.contains("*"), "Title must not contain asterisks")
        XCTAssertFalse(ideas[0].description.contains("*"), "Description must not contain asterisks")
    }

    /// All TYPE tags map to the correct HermesIdeaType.
    func testParseIdeasRecognizesAllTypeTags() {
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

        for (index, (tag, expectedType)) in tagToType.enumerated() {
            let text = "\(index + 1). [\(tag)] Test Idea\n   A brief description.\n"
            let ideas = service().parseIdeas(from: text)
            XCTAssertEqual(ideas.count, 1, "Expected 1 idea for tag '\(tag)'")
            XCTAssertEqual(ideas[0].ideaType, expectedType, "Tag '\(tag)' must map to \(expectedType)")
        }
    }

    /// Multiple ideas are parsed in order.
    func testParseIdeasPreservesOrder() {
        let text = """
        1. [PLOT HOOK] First Idea
           Description of first.
        2. [TWIST] Second Idea
           Description of second.
        3. [SETTING] Third Idea
           Description of third.
        """

        let ideas = service().parseIdeas(from: text)

        XCTAssertEqual(ideas.count, 3)
        XCTAssertEqual(ideas[0].title, "First Idea")
        XCTAssertEqual(ideas[1].title, "Second Idea")
        XCTAssertEqual(ideas[2].title, "Third Idea")
    }

    /// An unknown TYPE tag defaults to .plotHook.
    func testParseIdeasUnknownTagDefaultsToPlotHook() {
        let text = "1. [UNKNOWN TAG] Some Title\n   A description.\n"
        let ideas = service().parseIdeas(from: text)
        XCTAssertEqual(ideas.count, 1)
        XCTAssertEqual(ideas[0].ideaType, .plotHook)
    }
}

// MARK: - History Management (unaffected by profile removal)

final class HermesServiceHistoryTests: XCTestCase {

    func testGetHistoryReturnsAllMessages() {
        let service = makeHermesService()
        var session = service.startSession()

        session.messages.append(HermesMessage(role: .user, content: "User msg"))
        session.messages.append(HermesMessage(role: .hermes, content: "Hermes msg"))

        let history = service.getHistory(from: session)
        XCTAssertEqual(history.count, 2)
    }

    func testGetHistoryIsInChronologicalOrder() {
        let service = makeHermesService()
        var session = service.startSession()

        let msg1 = HermesMessage(role: .user, content: "First")
        let msg2 = HermesMessage(role: .hermes, content: "Second")
        session.messages = [msg1, msg2]

        let history = service.getHistory(from: session)
        XCTAssertEqual(history[0].content, "First")
        XCTAssertEqual(history[1].content, "Second")
    }

    func testClearHistoryRemovesAllMessages() {
        let service = makeHermesService()
        var session = service.startSession()

        session.messages.append(HermesMessage(role: .user, content: "User msg"))
        session.messages.append(HermesMessage(role: .hermes, content: "Hermes msg"))
        XCTAssertEqual(session.messages.count, 2)

        service.clearHistory(for: &session)

        XCTAssertTrue(session.messages.isEmpty)
    }

    func testClearHistoryOnEmptySessionIsNoOp() {
        let service = makeHermesService()
        var session = service.startSession()
        XCTAssertTrue(session.messages.isEmpty)

        service.clearHistory(for: &session)
        XCTAssertTrue(session.messages.isEmpty)
    }
}

// MARK: - Session Statistics (unaffected by profile removal)

final class HermesServiceSessionStatsTests: XCTestCase {

    func testSessionStatsEmptySession() {
        let service = makeHermesService()
        let session = service.startSession()

        let stats = service.getSessionStats(from: session)

        XCTAssertEqual(stats.messageCount, 0)
        XCTAssertEqual(stats.totalIdeas, 0)
        XCTAssertEqual(stats.favoriteCount, 0)
        XCTAssertEqual(stats.averageIdeasPerMessage, 0.0)
    }

    func testSessionStatsCounting() {
        let service = makeHermesService()
        var session = service.startSession()

        let idea1 = HermesIdea(title: "Idea 1", description: "Desc", ideaType: .plotHook)
        let idea2 = HermesIdea(title: "Idea 2", description: "Desc", ideaType: .twist)
        session.messages.append(HermesMessage(role: .user, content: "A user message"))
        session.messages.append(HermesMessage(role: .hermes, content: "Hermes reply", ideas: [idea1, idea2]))

        let stats = service.getSessionStats(from: session)

        XCTAssertEqual(stats.messageCount, 2)
        XCTAssertEqual(stats.totalIdeas, 2)
        XCTAssertEqual(stats.averageIdeasPerMessage, 2.0)
    }

    func testSessionStatsIdeaCountByType() {
        let service = makeHermesService()
        var session = service.startSession()

        let plotIdea = HermesIdea(title: "Plot 1", description: "Desc", ideaType: .plotHook)
        let twistIdea1 = HermesIdea(title: "Twist 1", description: "Desc", ideaType: .twist)
        let twistIdea2 = HermesIdea(title: "Twist 2", description: "Desc", ideaType: .twist)
        session.messages.append(
            HermesMessage(role: .hermes, content: "Ideas", ideas: [plotIdea, twistIdea1, twistIdea2])
        )

        let stats = service.getSessionStats(from: session)

        XCTAssertEqual(stats.ideaCountByType[.plotHook], 1)
        XCTAssertEqual(stats.ideaCountByType[.twist], 2)
    }

    func testSessionStatsDurationIsNonNegative() {
        let service = makeHermesService()
        let session = service.startSession()
        let stats = service.getSessionStats(from: session)
        XCTAssertGreaterThanOrEqual(stats.sessionDuration, 0.0)
    }
}

// MARK: - getAllIdeas (unaffected by profile removal)

final class HermesServiceGetAllIdeasTests: XCTestCase {

    func testGetAllIdeasReturnsIdeasFromHermesMessages() {
        let service = makeHermesService()
        var session = service.startSession()

        let idea = HermesIdea(title: "Dragon Lair", description: "A hidden cave", ideaType: .setting)
        session.messages.append(HermesMessage(role: .user, content: "user"))
        session.messages.append(HermesMessage(role: .hermes, content: "hermes", ideas: [idea]))

        let all = service.getAllIdeas(from: session)
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all[0].title, "Dragon Lair")
    }

    func testGetAllIdeasDoesNotIncludeUserMessageIdeas() {
        let service = makeHermesService()
        var session = service.startSession()

        // User messages with ideas (edge case) should not appear when filtering by .hermes role
        let idea = HermesIdea(title: "Should Not Appear", description: "Desc", ideaType: .plotHook)
        session.messages.append(HermesMessage(role: .user, content: "user", ideas: [idea]))

        let all = service.getAllIdeas(from: session)
        XCTAssertTrue(all.isEmpty, "getAllIdeas must only return ideas from hermes-role messages")
    }

    func testGetAllIdeasFilteredByType() {
        let service = makeHermesService()
        var session = service.startSession()

        let plotIdea = HermesIdea(title: "Plot", description: "Desc", ideaType: .plotHook)
        let twistIdea = HermesIdea(title: "Twist", description: "Desc", ideaType: .twist)
        session.messages.append(
            HermesMessage(role: .hermes, content: "ideas", ideas: [plotIdea, twistIdea])
        )

        let filtered = service.getAllIdeas(from: session, filteredBy: .plotHook)
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered[0].ideaType, .plotHook)
    }

    func testGetAllIdeasWithNoFilterReturnsAll() {
        let service = makeHermesService()
        var session = service.startSession()

        let ideas = HermesIdeaType.allCases.map {
            HermesIdea(title: "\($0.rawValue)", description: "Desc", ideaType: $0)
        }
        session.messages.append(HermesMessage(role: .hermes, content: "ideas", ideas: ideas))

        let all = service.getAllIdeas(from: session)
        XCTAssertEqual(all.count, HermesIdeaType.allCases.count)
    }
}

// MARK: - maxHistoryMessages trimming (unaffected by profile removal)

final class HermesServiceHistoryTrimmingTests: XCTestCase {

    /// When the session history grows beyond maxHistoryMessages, the oldest messages are trimmed.
    func testHistoryTrimmingOccursOnGenerateIdeas() async {
        // maxHistoryMessages = 4; we add 5 messages and verify trimming would occur
        let service = makeHermesService(maxHistoryMessages: 4)
        var session = service.startSession()

        // Manually populate 5 messages (beyond the limit)
        for i in 1...5 {
            session.messages.append(HermesMessage(role: .user, content: "Message \(i)"))
        }
        XCTAssertEqual(session.messages.count, 5)

        // Trigger prompt validation (which internally calls trimHistory)
        // We use an empty prompt to trigger early exit (emptyPrompt error) after trimming
        do {
            _ = try await service.generateIdeas("", in: &session)
        } catch HermesError.emptyPrompt {
            // Expected — trimHistory runs before validation throws
        } catch {
            // Other errors acceptable
        }

        // After trimming 1 excess message, 4 remain
        XCTAssertLessThanOrEqual(session.messages.count, 4)
    }
}

// MARK: - Helpers

private func makeHermesService(
    maxHistoryMessages: Int = 30,
    maxPromptLength: Int = 4000
) -> HermesService {
    // We need a minimal DocumentManager and TemplateManager but no actual AIService.
    // Since HermesService requires a real AIService, we construct a stub config.
    // Tests that don't invoke the AI will never call through to the network.
    let docMgr = DocumentManager()
    let tmplMgr = TemplateManager()
    let config = AIConfiguration(apiKey: "test-key")
    let aiService = AIService(configuration: config)
    return HermesService(
        aiService: aiService,
        documentManager: docMgr,
        templateManager: tmplMgr,
        maxHistoryMessages: maxHistoryMessages,
        maxPromptLength: maxPromptLength
    )
}