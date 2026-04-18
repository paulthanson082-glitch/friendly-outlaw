import XCTest
@testable import WritersApp

// MARK: - HermesIdeaType Tests

final class HermesIdeaTypeTests: XCTestCase {

    func testAllCasesExist() {
        let expected: Set<HermesIdeaType> = [
            .plotHook, .characterTrait, .worldBuilding, .conflict,
            .twist, .dialogue, .setting, .theme
        ]
        XCTAssertEqual(Set(HermesIdeaType.allCases), expected)
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

    func testDisplayNamesAreDistinct() {
        let names = HermesIdeaType.allCases.map { $0.displayName }
        XCTAssertEqual(names.count, Set(names).count, "All display names must be unique")
    }

    func testCodableRoundTrip() throws {
        for type_ in HermesIdeaType.allCases {
            let data = try JSONEncoder().encode(type_)
            let decoded = try JSONDecoder().decode(HermesIdeaType.self, from: data)
            XCTAssertEqual(decoded, type_)
        }
    }
}

// MARK: - HermesIdea Tests (PR Change: removed isFavorite)

final class HermesIdeaTests: XCTestCase {

    // MARK: - Initialization

    func testHermesIdeaInitWithDefaults() {
        let before = Date()
        let idea = HermesIdea(
            title: "A ghost town",
            description: "An abandoned mining settlement haunted by memory",
            ideaType: .setting
        )
        let after = Date()

        XCTAssertEqual(idea.title, "A ghost town")
        XCTAssertEqual(idea.description, "An abandoned mining settlement haunted by memory")
        XCTAssertEqual(idea.ideaType, .setting)
        XCTAssertGreaterThanOrEqual(idea.timestamp, before)
        XCTAssertLessThanOrEqual(idea.timestamp, after)
    }

    func testHermesIdeaExplicitId() {
        let fixedId = UUID()
        let idea = HermesIdea(
            id: fixedId,
            title: "T",
            description: "D",
            ideaType: .conflict
        )
        XCTAssertEqual(idea.id, fixedId)
    }

    func testHermesIdeaDefaultIdsAreUnique() {
        let idea1 = HermesIdea(title: "A", description: "D", ideaType: .plotHook)
        let idea2 = HermesIdea(title: "A", description: "D", ideaType: .plotHook)
        XCTAssertNotEqual(idea1.id, idea2.id)
    }

    func testHermesIdeaExplicitTimestamp() {
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
        let idea = HermesIdea(
            title: "T",
            description: "D",
            ideaType: .theme,
            timestamp: fixedDate
        )
        XCTAssertEqual(idea.timestamp, fixedDate)
    }

    // MARK: - Removed isFavorite property (PR change)

    func testHermesIdeaHasNoIsFavoriteProperty() {
        // Compile-time check: the init must not accept an isFavorite parameter
        let idea = HermesIdea(title: "T", description: "D", ideaType: .dialogue)
        // If isFavorite existed on the struct it would be accessible; absence is confirmed by successful init
        XCTAssertNotNil(idea, "HermesIdea must initialise without an isFavorite parameter")
    }

    // MARK: - Codable round-trip

    func testHermesIdeaCodableRoundTrip() throws {
        let fixedId = UUID()
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
        let original = HermesIdea(
            id: fixedId,
            title: "Moonlit duel",
            description: "Two rivals clash at midnight",
            ideaType: .conflict,
            timestamp: fixedDate
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(HermesIdea.self, from: data)

        XCTAssertEqual(decoded.id, fixedId)
        XCTAssertEqual(decoded.title, "Moonlit duel")
        XCTAssertEqual(decoded.description, "Two rivals clash at midnight")
        XCTAssertEqual(decoded.ideaType, .conflict)
        // Timestamp round-trip via ISO8601 may lose sub-second precision; compare to the second
        XCTAssertEqual(decoded.timestamp.timeIntervalSince1970, fixedDate.timeIntervalSince1970,
                       accuracy: 1.0)
    }

    func testHermesIdeaEncodedJSONDoesNotContainIsFavoriteKey() throws {
        let idea = HermesIdea(title: "X", description: "Y", ideaType: .twist)
        let data = try JSONEncoder().encode(idea)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNil(json?["isFavorite"],
                     "Encoded JSON must not contain 'isFavorite' key after the field was removed")
    }

    func testHermesIdeaEncodedJSONContainsExpectedKeys() throws {
        let idea = HermesIdea(title: "T", description: "D", ideaType: .worldBuilding)
        let data = try JSONEncoder().encode(idea)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNotNil(json?["id"])
        XCTAssertNotNil(json?["title"])
        XCTAssertNotNil(json?["description"])
        XCTAssertNotNil(json?["ideaType"])
        XCTAssertNotNil(json?["timestamp"])
    }

    func testHermesIdeaDecodesFromJsonWithoutIsFavoriteKey() throws {
        // Backward-compatibility: old payloads that have isFavorite should still decode
        // (the field is simply ignored); new payloads without it must also work fine.
        let json = """
        {
          "id": "00000000-0000-0000-0000-000000000001",
          "title": "Dark forest",
          "description": "A forest no one returns from",
          "ideaType": "setting",
          "timestamp": "2024-01-15T12:00:00Z"
        }
        """.data(using: .utf8)!
        let idea = try JSONDecoder().decode(HermesIdea.self, from: json)
        XCTAssertEqual(idea.title, "Dark forest")
        XCTAssertEqual(idea.ideaType, .setting)
    }

    func testHermesIdeaDecodesFromJsonWithIsFavoriteKeyPresentButIgnored() throws {
        // Old JSON that still contains isFavorite should decode without error
        // (field is present in JSON but not in the struct)
        let json = """
        {
          "id": "00000000-0000-0000-0000-000000000002",
          "title": "Secret garden",
          "description": "Hidden sanctuary",
          "ideaType": "worldBuilding",
          "timestamp": "2024-02-01T08:00:00Z",
          "isFavorite": true
        }
        """.data(using: .utf8)!
        // Decoding should succeed even with extra key; Swift default Decodable ignores unknown keys
        XCTAssertNoThrow(try JSONDecoder().decode(HermesIdea.self, from: json))
    }
}

// MARK: - HermesContext Tests (PR Change: removed tone field)

final class HermesContextTests: XCTestCase {

    // MARK: - Default initialisation

    func testHermesContextDefaultValues() {
        let context = HermesContext()
        XCTAssertEqual(context.genre, "")
        XCTAssertEqual(context.logline, "")
        XCTAssertEqual(context.currentScene, "")
        XCTAssertTrue(context.characters.isEmpty)
        XCTAssertTrue(context.themes.isEmpty)
        XCTAssertNil(context.documentId)
    }

    func testHermesContextWithAllFields() {
        let docId = UUID()
        let context = HermesContext(
            genre: "Fantasy",
            logline: "A hero's journey",
            currentScene: "The departure",
            characters: ["Aria", "Rowan"],
            themes: ["redemption", "sacrifice"],
            documentId: docId
        )
        XCTAssertEqual(context.genre, "Fantasy")
        XCTAssertEqual(context.logline, "A hero's journey")
        XCTAssertEqual(context.currentScene, "The departure")
        XCTAssertEqual(context.characters, ["Aria", "Rowan"])
        XCTAssertEqual(context.themes, ["redemption", "sacrifice"])
        XCTAssertEqual(context.documentId, docId)
    }

    // MARK: - Removed tone field (PR change)

    func testHermesContextHasNoToneProperty() {
        // Compile-time check: the init must not accept a tone parameter.
        let context = HermesContext(genre: "Horror")
        XCTAssertNotNil(context, "HermesContext must initialise without a tone parameter")
    }

    // MARK: - Codable

    func testHermesContextCodableRoundTrip() throws {
        let docId = UUID()
        let original = HermesContext(
            genre: "Thriller",
            logline: "A detective hunts a serial killer",
            currentScene: "The murder scene",
            characters: ["Det. Holt", "The Killer"],
            themes: ["justice", "obsession"],
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

    func testHermesContextEncodedJSONDoesNotContainToneKey() throws {
        let context = HermesContext(genre: "Mystery")
        let data = try JSONEncoder().encode(context)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNil(json?["tone"],
                     "Encoded JSON must not contain 'tone' key after the field was removed")
    }

    func testHermesContextDocumentIdNilPreservedInCoding() throws {
        let original = HermesContext(genre: "Horror", documentId: nil)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(HermesContext.self, from: data)
        XCTAssertNil(decoded.documentId)
    }

    func testHermesContextMultipleCharactersAndThemes() {
        let chars = ["Alice", "Bob", "Charlie", "Diana"]
        let themes = ["love", "war", "peace", "hope"]
        let context = HermesContext(characters: chars, themes: themes)
        XCTAssertEqual(context.characters, chars)
        XCTAssertEqual(context.themes, themes)
    }
}

// MARK: - HermesError Tests

final class HermesErrorTests: XCTestCase {

    func testEmptyPromptDescription() {
        let error = HermesError.emptyPrompt
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription!.isEmpty)
    }

    func testPromptTooLongDescription() {
        let error = HermesError.promptTooLong
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription!.isEmpty)
    }

    func testAINotAvailableDescription() {
        let error = HermesError.aiNotAvailable
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("API key") || error.errorDescription!.contains("AI"))
    }

    func testIdeaNotFoundDescription() {
        let id = UUID()
        let error = HermesError.ideaNotFound(id: id)
        let description = error.errorDescription ?? ""
        XCTAssertTrue(description.contains(id.uuidString),
                      "Error description must include the missing idea's UUID")
    }

    func testAIServiceFailedDescription() {
        let reason = "connection timeout"
        let error = HermesError.aiServiceFailed(reason)
        let description = error.errorDescription ?? ""
        XCTAssertTrue(description.contains(reason),
                      "Error description must include the failure reason")
    }

    func testAllErrorDescriptionsAreNonEmpty() {
        let errors: [HermesError] = [
            .emptyPrompt,
            .promptTooLong,
            .aiNotAvailable,
            .ideaNotFound(id: UUID()),
            .aiServiceFailed("test")
        ]
        for error in errors {
            XCTAssertNotNil(error.errorDescription, "errorDescription must not be nil for \(error)")
            XCTAssertFalse(error.errorDescription!.isEmpty, "errorDescription must not be empty for \(error)")
        }
    }
}

// MARK: - HermesMessage Tests

final class HermesMessageTests: XCTestCase {

    func testHermesMessageDefaultIdIsUnique() {
        let m1 = HermesMessage(role: .user, content: "Hello")
        let m2 = HermesMessage(role: .user, content: "Hello")
        XCTAssertNotEqual(m1.id, m2.id)
    }

    func testHermesMessageWithIdeas() {
        let ideas = [
            HermesIdea(title: "Idea A", description: "Desc", ideaType: .plotHook)
        ]
        let message = HermesMessage(role: .hermes, content: "Here are some ideas", ideas: ideas)
        XCTAssertEqual(message.ideas.count, 1)
        XCTAssertEqual(message.ideas[0].title, "Idea A")
    }

    func testHermesMessageWithEmptyIdeas() {
        let message = HermesMessage(role: .user, content: "Tell me more")
        XCTAssertTrue(message.ideas.isEmpty)
    }

    func testHermesMessageCodableRoundTrip() throws {
        let idea = HermesIdea(title: "Rising action", description: "Tension builds", ideaType: .conflict)
        let original = HermesMessage(
            role: .hermes,
            content: "Consider this conflict:",
            ideas: [idea]
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(HermesMessage.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.role, .hermes)
        XCTAssertEqual(decoded.content, "Consider this conflict:")
        XCTAssertEqual(decoded.ideas.count, 1)
        XCTAssertEqual(decoded.ideas[0].title, "Rising action")
    }
}

// MARK: - HermesSession Tests

final class HermesSessionTests: XCTestCase {

    func testHermesSessionDefaultValues() {
        let session = HermesSession()
        XCTAssertTrue(session.messages.isEmpty)
        XCTAssertEqual(session.context.genre, "")
    }

    func testHermesSessionCodableRoundTrip() throws {
        let context = HermesContext(genre: "Sci-Fi", logline: "Space opera")
        let fixedStart = Date(timeIntervalSince1970: 1_700_000_000)
        let fixedLast = Date(timeIntervalSince1970: 1_700_003_600)
        let original = HermesSession(
            messages: [],
            context: context,
            startedAt: fixedStart,
            lastMessageAt: fixedLast
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(HermesSession.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.context.genre, "Sci-Fi")
        XCTAssertEqual(decoded.startedAt.timeIntervalSince1970, fixedStart.timeIntervalSince1970,
                       accuracy: 1.0)
        XCTAssertEqual(decoded.lastMessageAt.timeIntervalSince1970, fixedLast.timeIntervalSince1970,
                       accuracy: 1.0)
    }

    func testHermesSessionContextHasNoToneInCoding() throws {
        let context = HermesContext(genre: "Romance")
        let session = HermesSession(context: context)
        let data = try JSONEncoder().encode(session)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let contextDict = json?["context"] as? [String: Any]
        XCTAssertNil(contextDict?["tone"],
                     "Encoded session context must not contain 'tone' key")
    }
}