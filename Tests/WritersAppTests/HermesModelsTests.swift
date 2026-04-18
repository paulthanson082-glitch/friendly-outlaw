import XCTest
@testable import WritersApp

// MARK: - HermesIdeaType Tests

final class HermesIdeaTypeTests: XCTestCase {

    func testAllCasesCount() {
        XCTAssertEqual(HermesIdeaType.allCases.count, 8)
    }

    func testRawValues() {
        XCTAssertEqual(HermesIdeaType.plotHook.rawValue, "plotHook")
        XCTAssertEqual(HermesIdeaType.characterTrait.rawValue, "characterTrait")
        XCTAssertEqual(HermesIdeaType.worldBuilding.rawValue, "worldBuilding")
        XCTAssertEqual(HermesIdeaType.conflict.rawValue, "conflict")
        XCTAssertEqual(HermesIdeaType.twist.rawValue, "twist")
        XCTAssertEqual(HermesIdeaType.dialogue.rawValue, "dialogue")
        XCTAssertEqual(HermesIdeaType.setting.rawValue, "setting")
        XCTAssertEqual(HermesIdeaType.theme.rawValue, "theme")
    }

    func testDisplayNames() {
        XCTAssertEqual(HermesIdeaType.plotHook.displayName, "Plot Hook")
        XCTAssertEqual(HermesIdeaType.characterTrait.displayName, "Character Trait")
        XCTAssertEqual(HermesIdeaType.worldBuilding.displayName, "World Building")
        XCTAssertEqual(HermesIdeaType.conflict.displayName, "Conflict")
        XCTAssertEqual(HermesIdeaType.twist.displayName, "Twist")
        XCTAssertEqual(HermesIdeaType.dialogue.displayName, "Dialogue")
        XCTAssertEqual(HermesIdeaType.setting.displayName, "Setting")
        XCTAssertEqual(HermesIdeaType.theme.displayName, "Theme")
    }

    func testCodableRoundTrip() throws {
        for ideaType in HermesIdeaType.allCases {
            let data = try JSONEncoder().encode(ideaType)
            let decoded = try JSONDecoder().decode(HermesIdeaType.self, from: data)
            XCTAssertEqual(decoded, ideaType)
        }
    }
}

// MARK: - HermesIdea Tests
// Tests for the updated HermesIdea struct which no longer has isFavorite property (removed in this PR).

final class HermesIdeaTests: XCTestCase {

    func testInitStoresAllProperties() {
        let id = UUID()
        let timestamp = Date(timeIntervalSince1970: 1000000)
        let idea = HermesIdea(
            id: id,
            title: "The Secret Door",
            description: "A hidden portal to another world",
            ideaType: .worldBuilding,
            timestamp: timestamp
        )
        XCTAssertEqual(idea.id, id)
        XCTAssertEqual(idea.title, "The Secret Door")
        XCTAssertEqual(idea.description, "A hidden portal to another world")
        XCTAssertEqual(idea.ideaType, .worldBuilding)
        XCTAssertEqual(idea.timestamp.timeIntervalSince1970, timestamp.timeIntervalSince1970, accuracy: 1.0)
    }

    func testInitUsesDefaultUUID() {
        let idea1 = HermesIdea(title: "A", description: "B", ideaType: .plotHook)
        let idea2 = HermesIdea(title: "A", description: "B", ideaType: .plotHook)
        XCTAssertNotEqual(idea1.id, idea2.id, "Each HermesIdea should get a unique default UUID")
    }

    func testInitUsesDefaultTimestamp() {
        let before = Date()
        let idea = HermesIdea(title: "T", description: "D", ideaType: .conflict)
        let after = Date()
        XCTAssertGreaterThanOrEqual(idea.timestamp, before)
        XCTAssertLessThanOrEqual(idea.timestamp, after)
    }

    func testDoesNotHaveIsFavoriteProperty() {
        // The isFavorite property was removed in this PR.
        let idea = HermesIdea(title: "Check", description: "No favorite flag", ideaType: .theme)
        let mirror = Mirror(reflecting: idea)
        let hasIsFavorite = mirror.children.contains { $0.label == "isFavorite" }
        XCTAssertFalse(hasIsFavorite, "HermesIdea should not have an isFavorite property after PR changes")
    }

    func testCodableRoundTrip() throws {
        let id = UUID()
        let timestamp = Date(timeIntervalSince1970: 1700000000)
        let original = HermesIdea(
            id: id,
            title: "Flashback Scene",
            description: "Protagonist recalls childhood trauma",
            ideaType: .characterTrait,
            timestamp: timestamp
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(HermesIdea.self, from: data)
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.title, original.title)
        XCTAssertEqual(decoded.description, original.description)
        XCTAssertEqual(decoded.ideaType, original.ideaType)
    }

    func testCodableTimestampIsISO8601String() throws {
        let timestamp = Date(timeIntervalSince1970: 1700000000)
        let idea = HermesIdea(id: UUID(), title: "T", description: "D", ideaType: .setting, timestamp: timestamp)
        let data = try JSONEncoder().encode(idea)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNotNil(json)
        // timestamp should be a string in ISO8601 format
        let timestampValue = json?["timestamp"]
        XCTAssertNotNil(timestampValue, "Timestamp must be present in JSON")
        XCTAssertTrue(timestampValue is String, "Timestamp should be encoded as an ISO8601 string")
        let timestampString = timestampValue as! String
        XCTAssertTrue(timestampString.contains("T"), "ISO8601 string should contain 'T' separator")
    }

    func testCodableEncodedJSONDoesNotContainIsFavoriteKey() throws {
        let idea = HermesIdea(title: "No Fav", description: "Should not have isFavorite in JSON", ideaType: .twist)
        let data = try JSONEncoder().encode(idea)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNotNil(json)
        XCTAssertNil(json?["isFavorite"], "HermesIdea JSON should not contain 'isFavorite' key after PR changes")
    }

    func testDecodingOldJSONWithIsFavoriteKeyDoesNotFail() throws {
        // Old persisted JSON may include isFavorite - decoding should succeed without crashing
        let id = UUID()
        let oldJSON = """
        {
            "id": "\(id.uuidString)",
            "title": "Legacy Idea",
            "description": "Stored with old schema",
            "ideaType": "plotHook",
            "timestamp": "2024-01-01T00:00:00Z",
            "isFavorite": true
        }
        """.data(using: .utf8)!
        // Should decode without throwing (isFavorite is simply ignored)
        XCTAssertNoThrow(try JSONDecoder().decode(HermesIdea.self, from: oldJSON))
        let decoded = try JSONDecoder().decode(HermesIdea.self, from: oldJSON)
        XCTAssertEqual(decoded.id, id)
        XCTAssertEqual(decoded.title, "Legacy Idea")
        XCTAssertEqual(decoded.ideaType, .plotHook)
    }

    func testCodableRoundTripAllIdeaTypes() throws {
        for ideaType in HermesIdeaType.allCases {
            let original = HermesIdea(title: "Test", description: "Test desc", ideaType: ideaType)
            let data = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(HermesIdea.self, from: data)
            XCTAssertEqual(decoded.ideaType, ideaType, "Round-trip failed for ideaType \(ideaType.rawValue)")
        }
    }
}

// MARK: - HermesContext Tests
// Tests for the updated HermesContext struct which no longer has a tone property (removed in this PR).

final class HermesContextTests: XCTestCase {

    func testDefaultInit() {
        let context = HermesContext()
        XCTAssertEqual(context.genre, "")
        XCTAssertEqual(context.logline, "")
        XCTAssertEqual(context.currentScene, "")
        XCTAssertTrue(context.characters.isEmpty)
        XCTAssertTrue(context.themes.isEmpty)
        XCTAssertNil(context.documentId)
    }

    func testInitWithAllParameters() {
        let docId = UUID()
        let context = HermesContext(
            genre: "Fantasy",
            logline: "A hero's journey",
            currentScene: "The dragon's lair",
            characters: ["Hero", "Dragon", "Mentor"],
            themes: ["Courage", "Sacrifice"],
            documentId: docId
        )
        XCTAssertEqual(context.genre, "Fantasy")
        XCTAssertEqual(context.logline, "A hero's journey")
        XCTAssertEqual(context.currentScene, "The dragon's lair")
        XCTAssertEqual(context.characters, ["Hero", "Dragon", "Mentor"])
        XCTAssertEqual(context.themes, ["Courage", "Sacrifice"])
        XCTAssertEqual(context.documentId, docId)
    }

    func testDoesNotHaveToneProperty() {
        // The tone property was removed in this PR.
        let context = HermesContext()
        let mirror = Mirror(reflecting: context)
        let hasTone = mirror.children.contains { $0.label == "tone" }
        XCTAssertFalse(hasTone, "HermesContext should not have a tone property after PR changes")
    }

    func testInitDoesNotAcceptToneParameter() {
        // Verify that HermesContext initializer works without a tone parameter.
        // This confirms the API surface is correct post-PR.
        let context = HermesContext(genre: "Sci-Fi", logline: "Space adventure")
        XCTAssertEqual(context.genre, "Sci-Fi")
        XCTAssertEqual(context.logline, "Space adventure")
    }

    func testCodableRoundTrip() throws {
        let docId = UUID()
        let original = HermesContext(
            genre: "Mystery",
            logline: "A detective investigates a haunted mansion",
            currentScene: "The library with a secret passage",
            characters: ["Detective", "Butler", "Ghost"],
            themes: ["Truth", "Deception"],
            documentId: docId
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(HermesContext.self, from: data)
        XCTAssertEqual(decoded.genre, original.genre)
        XCTAssertEqual(decoded.logline, original.logline)
        XCTAssertEqual(decoded.currentScene, original.currentScene)
        XCTAssertEqual(decoded.characters, original.characters)
        XCTAssertEqual(decoded.themes, original.themes)
        XCTAssertEqual(decoded.documentId, original.documentId)
    }

    func testCodableRoundTripWithNilDocumentId() throws {
        let original = HermesContext(genre: "Horror", logline: "Haunted house", documentId: nil)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(HermesContext.self, from: data)
        XCTAssertNil(decoded.documentId)
    }

    func testCodableRoundTripWithEmptyArrays() throws {
        let original = HermesContext(characters: [], themes: [])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(HermesContext.self, from: data)
        XCTAssertTrue(decoded.characters.isEmpty)
        XCTAssertTrue(decoded.themes.isEmpty)
    }

    func testCodableEncodedJSONDoesNotContainToneKey() throws {
        let context = HermesContext(genre: "Thriller")
        let data = try JSONEncoder().encode(context)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNotNil(json)
        XCTAssertNil(json?["tone"], "HermesContext JSON should not contain a 'tone' key after PR changes")
    }

    func testDecodingOldJSONWithToneKeyDoesNotFail() throws {
        // Old persisted JSON may include a tone field - decoding should succeed without crashing
        let oldJSON = """
        {
            "genre": "Fantasy",
            "logline": "Epic quest",
            "currentScene": "Prologue",
            "characters": ["Hero"],
            "themes": ["Adventure"],
            "documentId": null,
            "tone": "inspirational"
        }
        """.data(using: .utf8)!
        XCTAssertNoThrow(try JSONDecoder().decode(HermesContext.self, from: oldJSON))
        let decoded = try JSONDecoder().decode(HermesContext.self, from: oldJSON)
        XCTAssertEqual(decoded.genre, "Fantasy")
    }
}

// MARK: - HermesSession Tests

final class HermesSessionTests: XCTestCase {

    func testDefaultInit() {
        let before = Date()
        let session = HermesSession()
        let after = Date()
        XCTAssertNotNil(session.id)
        XCTAssertTrue(session.messages.isEmpty)
        XCTAssertGreaterThanOrEqual(session.startedAt, before)
        XCTAssertLessThanOrEqual(session.startedAt, after)
    }

    func testInitWithCustomContext() {
        let context = HermesContext(genre: "Sci-Fi", logline: "Space opera")
        let session = HermesSession(context: context)
        XCTAssertEqual(session.context.genre, "Sci-Fi")
        XCTAssertEqual(session.context.logline, "Space opera")
    }

    func testCodableRoundTrip() throws {
        let idea = HermesIdea(title: "Red Sun Rising", description: "A solar flare event", ideaType: .setting)
        let message = HermesMessage(
            role: .hermes,
            content: "Here is a setting idea",
            ideas: [idea]
        )
        let context = HermesContext(genre: "Sci-Fi")
        let startDate = Date(timeIntervalSince1970: 1700000000)
        let original = HermesSession(
            messages: [message],
            context: context,
            startedAt: startDate,
            lastMessageAt: startDate
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(HermesSession.self, from: data)
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.messages.count, 1)
        XCTAssertEqual(decoded.messages[0].ideas.count, 1)
        XCTAssertEqual(decoded.messages[0].ideas[0].title, "Red Sun Rising")
        XCTAssertEqual(decoded.context.genre, "Sci-Fi")
    }
}

// MARK: - HermesMessage Tests

final class HermesMessageTests: XCTestCase {

    func testInitWithUserRole() {
        let message = HermesMessage(role: .user, content: "Give me a plot idea")
        XCTAssertEqual(message.role, .user)
        XCTAssertEqual(message.content, "Give me a plot idea")
        XCTAssertTrue(message.ideas.isEmpty)
    }

    func testInitWithHermesRole() {
        let idea = HermesIdea(title: "Ancient Prophecy", description: "A foretold doom", ideaType: .plotHook)
        let message = HermesMessage(role: .hermes, content: "Here is an idea", ideas: [idea])
        XCTAssertEqual(message.role, .hermes)
        XCTAssertEqual(message.ideas.count, 1)
        XCTAssertEqual(message.ideas[0].title, "Ancient Prophecy")
    }

    func testCodableRoundTrip() throws {
        let idea = HermesIdea(title: "Betrayal", description: "A trusted ally turns", ideaType: .conflict)
        let original = HermesMessage(
            role: .hermes,
            content: "Consider this conflict",
            ideas: [idea],
            timestamp: Date(timeIntervalSince1970: 1700000000)
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(HermesMessage.self, from: data)
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.role, original.role)
        XCTAssertEqual(decoded.content, original.content)
        XCTAssertEqual(decoded.ideas.count, 1)
        XCTAssertEqual(decoded.ideas[0].ideaType, .conflict)
    }

    func testTimestampEncodedAsISO8601String() throws {
        let message = HermesMessage(
            role: .user,
            content: "Test",
            timestamp: Date(timeIntervalSince1970: 1700000000)
        )
        let data = try JSONEncoder().encode(message)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNotNil(json)
        let timestampValue = json?["timestamp"]
        XCTAssertTrue(timestampValue is String, "HermesMessage timestamp must be encoded as a string")
    }
}

// MARK: - HermesError Tests

final class HermesErrorTests: XCTestCase {

    func testEmptyPromptErrorDescription() {
        let error = HermesError.emptyPrompt
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription!.isEmpty)
    }

    func testPromptTooLongErrorDescription() {
        let error = HermesError.promptTooLong
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription!.isEmpty)
    }

    func testAINotAvailableErrorDescription() {
        let error = HermesError.aiNotAvailable
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription!.isEmpty)
    }

    func testIdeaNotFoundErrorDescription() {
        let id = UUID()
        let error = HermesError.ideaNotFound(id: id)
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains(id.uuidString),
                      "ideaNotFound error description should include the UUID")
    }

    func testAIServiceFailedErrorDescription() {
        let error = HermesError.aiServiceFailed("network timeout")
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("network timeout"))
    }
}