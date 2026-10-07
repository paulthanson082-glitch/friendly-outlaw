import XCTest
@testable import WritersApp

// MARK: - HermesModels Tests
// Tests for remaining Hermes model types after this PR:
// - HermesTone enum was REMOVED in this PR (no longer testable)
// - HermesSessionStats struct was REMOVED in this PR (no longer testable)
// Tests here cover the models that remain and verify they still work correctly,
// including the custom ISO-8601 Codable implementation in HermesIdea.

final class HermesIdeaTypeTests: XCTestCase {

    func testHermesIdeaTypeHasEightCases() {
        XCTAssertEqual(HermesIdeaType.allCases.count, 8)
    }

    func testHermesIdeaTypeRawValues() {
        XCTAssertEqual(HermesIdeaType.plotHook.rawValue, "plotHook")
        XCTAssertEqual(HermesIdeaType.characterTrait.rawValue, "characterTrait")
        XCTAssertEqual(HermesIdeaType.worldBuilding.rawValue, "worldBuilding")
        XCTAssertEqual(HermesIdeaType.conflict.rawValue, "conflict")
        XCTAssertEqual(HermesIdeaType.twist.rawValue, "twist")
        XCTAssertEqual(HermesIdeaType.dialogue.rawValue, "dialogue")
        XCTAssertEqual(HermesIdeaType.setting.rawValue, "setting")
        XCTAssertEqual(HermesIdeaType.theme.rawValue, "theme")
    }

    func testHermesIdeaTypeDisplayNames() {
        XCTAssertEqual(HermesIdeaType.plotHook.displayName, "Plot Hook")
        XCTAssertEqual(HermesIdeaType.characterTrait.displayName, "Character Trait")
        XCTAssertEqual(HermesIdeaType.worldBuilding.displayName, "World Building")
        XCTAssertEqual(HermesIdeaType.conflict.displayName, "Conflict")
        XCTAssertEqual(HermesIdeaType.twist.displayName, "Twist")
        XCTAssertEqual(HermesIdeaType.dialogue.displayName, "Dialogue")
        XCTAssertEqual(HermesIdeaType.setting.displayName, "Setting")
        XCTAssertEqual(HermesIdeaType.theme.displayName, "Theme")
    }

    func testHermesIdeaTypeCodable() throws {
        for ideaType in HermesIdeaType.allCases {
            let data = try JSONEncoder().encode(ideaType)
            let decoded = try JSONDecoder().decode(HermesIdeaType.self, from: data)
            XCTAssertEqual(decoded, ideaType)
        }
    }
}

final class HermesIdeaTests: XCTestCase {

    func testHermesIdeaInit() {
        let idea = HermesIdea(
            title: "The Lost Kingdom",
            description: "A hidden realm beneath the sea",
            ideaType: .worldBuilding
        )
        XCTAssertEqual(idea.title, "The Lost Kingdom")
        XCTAssertEqual(idea.description, "A hidden realm beneath the sea")
        XCTAssertEqual(idea.ideaType, .worldBuilding)
    }

    func testHermesIdeaHasId() {
        let idea = HermesIdea(title: "Test", description: "Desc", ideaType: .plotHook)
        // Verify id is a valid UUID (non-nil is guaranteed by the type)
        XCTAssertNotNil(idea.id)
    }

    func testHermesIdeaCustomIdIsPreserved() {
        let customId = UUID()
        let idea = HermesIdea(id: customId, title: "Custom", description: "Desc", ideaType: .twist)
        XCTAssertEqual(idea.id, customId)
    }

    /// Tests the custom Codable implementation that serializes timestamp as ISO-8601 string.
    /// The encode(to:) method was given a docstring in this PR but behavior is unchanged.
    func testHermesIdeaCodableRoundTrip() throws {
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000) // stable timestamp
        let original = HermesIdea(
            title: "Epic Plot Twist",
            description: "The villain was the hero's clone",
            ideaType: .twist,
            timestamp: fixedDate
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(HermesIdea.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.title, original.title)
        XCTAssertEqual(decoded.description, original.description)
        XCTAssertEqual(decoded.ideaType, original.ideaType)
        // ISO8601 has second-level precision; compare within 1 second
        XCTAssertEqual(decoded.timestamp.timeIntervalSinceReferenceDate,
                       original.timestamp.timeIntervalSinceReferenceDate,
                       accuracy: 1.0)
    }

    func testHermesIdeaEncodeProducesISO8601Timestamp() throws {
        let idea = HermesIdea(title: "T", description: "D", ideaType: .plotHook)
        let data = try JSONEncoder().encode(idea)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let timestampString = json?["timestamp"] as? String
        XCTAssertNotNil(timestampString, "timestamp must be encoded as a string")
        // ISO8601 strings contain "T" separator between date and time
        XCTAssertTrue(timestampString?.contains("T") ?? false,
            "timestamp string must be ISO-8601 format, got: \(timestampString ?? "nil")")
    }

    func testHermesIdeaDecodingFromISO8601String() throws {
        let json = """
        {
            "id": "12345678-1234-1234-1234-123456789012",
            "title": "Ancient Prophecy",
            "description": "Written in starlight",
            "ideaType": "theme",
            "timestamp": "2024-01-15T10:30:00Z"
        }
        """.data(using: .utf8)!

        let idea = try JSONDecoder().decode(HermesIdea.self, from: json)
        XCTAssertEqual(idea.title, "Ancient Prophecy")
        XCTAssertEqual(idea.description, "Written in starlight")
        XCTAssertEqual(idea.ideaType, .theme)
    }

    func testHermesIdeaAllIdeaTypes() {
        for ideaType in HermesIdeaType.allCases {
            let idea = HermesIdea(title: "Test \(ideaType.displayName)", description: "Desc", ideaType: ideaType)
            XCTAssertEqual(idea.ideaType, ideaType)
        }
    }
}

final class HermesContextTests: XCTestCase {

    func testHermesContextDefaultInit() {
        let context = HermesContext()
        XCTAssertEqual(context.genre, "")
        XCTAssertEqual(context.logline, "")
        XCTAssertEqual(context.currentScene, "")
        XCTAssertTrue(context.characters.isEmpty)
        XCTAssertTrue(context.themes.isEmpty)
        XCTAssertNil(context.documentId)
    }

    func testHermesContextFullInit() {
        let docId = UUID()
        let context = HermesContext(
            genre: "Fantasy",
            logline: "A young wizard discovers their destiny",
            currentScene: "The forbidden forest",
            characters: ["Aria", "Zephyr"],
            themes: ["courage", "sacrifice"],
            documentId: docId
        )
        XCTAssertEqual(context.genre, "Fantasy")
        XCTAssertEqual(context.logline, "A young wizard discovers their destiny")
        XCTAssertEqual(context.currentScene, "The forbidden forest")
        XCTAssertEqual(context.characters, ["Aria", "Zephyr"])
        XCTAssertEqual(context.themes, ["courage", "sacrifice"])
        XCTAssertEqual(context.documentId, docId)
    }

    func testHermesContextCodableRoundTrip() throws {
        let original = HermesContext(
            genre: "Sci-Fi",
            logline: "Humanity's last hope",
            currentScene: "On the spaceship",
            characters: ["Commander Voss"],
            themes: ["isolation"],
            documentId: UUID()
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(HermesContext.self, from: data)
        XCTAssertEqual(decoded.genre, original.genre)
        XCTAssertEqual(decoded.logline, original.logline)
        XCTAssertEqual(decoded.characters, original.characters)
        XCTAssertEqual(decoded.documentId, original.documentId)
    }
}

final class HermesMessageTests: XCTestCase {

    func testHermesMessageRoles() {
        let userMsg = HermesMessage(role: .user, content: "Generate ideas")
        let hermesMsg = HermesMessage(role: .hermes, content: "Here are some ideas")
        XCTAssertEqual(userMsg.role, .user)
        XCTAssertEqual(hermesMsg.role, .hermes)
    }

    func testHermesMessageWithIdeas() {
        let idea = HermesIdea(title: "Dark Forest", description: "An ancient evil stirs", ideaType: .setting)
        let message = HermesMessage(role: .hermes, content: "Here is an idea", ideas: [idea])
        XCTAssertEqual(message.ideas.count, 1)
        XCTAssertEqual(message.ideas[0].title, "Dark Forest")
    }

    func testHermesMessageCodableRoundTrip() throws {
        let idea = HermesIdea(
            title: "The Oracle",
            description: "A mysterious seer",
            ideaType: .characterTrait,
            timestamp: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let original = HermesMessage(
            role: .hermes,
            content: "Here is your idea",
            ideas: [idea],
            timestamp: Date(timeIntervalSince1970: 1_700_001_000)
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(HermesMessage.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.role, original.role)
        XCTAssertEqual(decoded.content, original.content)
        XCTAssertEqual(decoded.ideas.count, 1)
        XCTAssertEqual(decoded.ideas[0].title, "The Oracle")
    }
}

final class HermesSessionTests: XCTestCase {

    func testHermesSessionDefaultInit() {
        let session = HermesSession()
        XCTAssertTrue(session.messages.isEmpty)
        XCTAssertNotNil(session.id)
    }

    func testHermesSessionCodableRoundTrip() throws {
        let context = HermesContext(genre: "Mystery", logline: "A detective unravels a cold case")
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        var session = HermesSession(
            context: context,
            startedAt: now,
            lastMessageAt: now
        )

        let userMsg = HermesMessage(
            role: .user,
            content: "Give me plot ideas",
            timestamp: now
        )
        session.messages.append(userMsg)

        let data = try JSONEncoder().encode(session)
        let decoded = try JSONDecoder().decode(HermesSession.self, from: data)

        XCTAssertEqual(decoded.id, session.id)
        XCTAssertEqual(decoded.context.genre, "Mystery")
        XCTAssertEqual(decoded.messages.count, 1)
        XCTAssertEqual(decoded.messages[0].content, "Give me plot ideas")
        XCTAssertEqual(decoded.startedAt.timeIntervalSinceReferenceDate,
                       session.startedAt.timeIntervalSinceReferenceDate,
                       accuracy: 1.0)
    }

    func testHermesSessionWithMultipleMessages() throws {
        var session = HermesSession()
        let ideas = [HermesIdea(title: "Idea A", description: "Desc A", ideaType: .plotHook)]
        session.messages.append(HermesMessage(role: .user, content: "First prompt"))
        session.messages.append(HermesMessage(role: .hermes, content: "First response", ideas: ideas))
        session.messages.append(HermesMessage(role: .user, content: "Follow-up prompt"))

        XCTAssertEqual(session.messages.count, 3)
        XCTAssertEqual(session.messages.filter { $0.role == .hermes }.count, 1)
        XCTAssertEqual(session.messages.filter { $0.role == .user }.count, 2)
    }
}

final class HermesErrorTests: XCTestCase {

    func testHermesErrorEmptyPromptDescription() {
        let error = HermesError.emptyPrompt
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription!.isEmpty)
    }

    func testHermesErrorPromptTooLongDescription() {
        let error = HermesError.promptTooLong
        XCTAssertNotNil(error.errorDescription)
    }

    func testHermesErrorAINotAvailableDescription() {
        let error = HermesError.aiNotAvailable
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.lowercased().contains("ai") ||
                      error.errorDescription!.lowercased().contains("enabled"))
    }

    func testHermesErrorIdeaNotFoundDescription() {
        let id = UUID()
        let error = HermesError.ideaNotFound(id: id)
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains(id.uuidString))
    }

    func testHermesErrorAIServiceFailedDescription() {
        let reason = "timeout after 30 seconds"
        let error = HermesError.aiServiceFailed(reason)
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains(reason))
    }
}

final class HermesResponseTests: XCTestCase {

    func testHermesResponseInit() {
        let sessionId = UUID()
        let ideas = [HermesIdea(title: "Quick Hook", description: "A fast plot hook", ideaType: .plotHook)]
        let response = HermesResponse(
            sessionId: sessionId,
            message: "Here are your ideas",
            ideas: ideas
        )
        XCTAssertEqual(response.sessionId, sessionId)
        XCTAssertEqual(response.message, "Here are your ideas")
        XCTAssertEqual(response.ideas.count, 1)
    }

    func testHermesResponseWithEmptyIdeas() {
        let response = HermesResponse(sessionId: UUID(), message: "No ideas generated", ideas: [])
        XCTAssertTrue(response.ideas.isEmpty)
    }
}