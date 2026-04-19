import XCTest
@testable import WritersApp

/// Tests for HermesModels as they exist after the PR changes:
/// - HermesTone removed
/// - HermesSessionStats removed
/// - HermesIdea encode/decode with ISO-8601 timestamp (encode(to:) docstring added)
final class HermesModelsTests: XCTestCase {

    // MARK: - HermesIdeaType

    func testHermesIdeaTypeAllCases() {
        let allCases = HermesIdeaType.allCases
        XCTAssertEqual(allCases.count, 8)
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

    func testHermesIdeaTypeCodable() throws {
        for ideaType in HermesIdeaType.allCases {
            let data = try JSONEncoder().encode(ideaType)
            let decoded = try JSONDecoder().decode(HermesIdeaType.self, from: data)
            XCTAssertEqual(decoded, ideaType, "Round-trip failed for \(ideaType)")
        }
    }

    // MARK: - HermesIdea Initialization

    func testHermesIdeaInit() {
        let id = UUID()
        let now = Date()
        let idea = HermesIdea(
            id: id,
            title: "The village is haunted",
            description: "A mysterious force grips the locals",
            ideaType: .plotHook,
            timestamp: now
        )
        XCTAssertEqual(idea.id, id)
        XCTAssertEqual(idea.title, "The village is haunted")
        XCTAssertEqual(idea.description, "A mysterious force grips the locals")
        XCTAssertEqual(idea.ideaType, .plotHook)
        XCTAssertEqual(idea.timestamp.timeIntervalSinceReferenceDate,
                       now.timeIntervalSinceReferenceDate, accuracy: 0.001)
    }

    func testHermesIdeaDefaultIdIsUnique() {
        let idea1 = HermesIdea(title: "A", description: "B", ideaType: .twist)
        let idea2 = HermesIdea(title: "C", description: "D", ideaType: .theme)
        XCTAssertNotEqual(idea1.id, idea2.id)
    }

    // MARK: - HermesIdea Codable (encode(to:) uses ISO-8601)

    func testHermesIdeaEncodingProducesISO8601Timestamp() throws {
        let idea = HermesIdea(
            title: "A clue in the attic",
            description: "Something was left behind",
            ideaType: .conflict
        )
        let data = try JSONEncoder().encode(idea)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let timestamp = json?["timestamp"] as? String
        XCTAssertNotNil(timestamp, "timestamp should be encoded as a string")
        // ISO-8601 strings contain 'T' and typically 'Z' or '+HH:MM'
        XCTAssertTrue(timestamp?.contains("T") ?? false, "Timestamp should be in ISO-8601 format")
    }

    func testHermesIdeaEncodingContainsRequiredKeys() throws {
        let idea = HermesIdea(
            title: "Storm approaches",
            description: "The characters must decide now",
            ideaType: .setting
        )
        let data = try JSONEncoder().encode(idea)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNotNil(json?["id"])
        XCTAssertNotNil(json?["title"])
        XCTAssertNotNil(json?["description"])
        XCTAssertNotNil(json?["ideaType"])
        XCTAssertNotNil(json?["timestamp"])
    }

    func testHermesIdeaRoundTrip() throws {
        let original = HermesIdea(
            title: "Betrayal at the gates",
            description: "The ally was working against them",
            ideaType: .twist,
            timestamp: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(HermesIdea.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.title, original.title)
        XCTAssertEqual(decoded.description, original.description)
        XCTAssertEqual(decoded.ideaType, original.ideaType)
        // Timestamps are serialized to second precision via ISO-8601
        XCTAssertEqual(decoded.timestamp.timeIntervalSince1970,
                       original.timestamp.timeIntervalSince1970, accuracy: 1.0)
    }

    func testHermesIdeaRoundTripAllIdeaTypes() throws {
        for ideaType in HermesIdeaType.allCases {
            let original = HermesIdea(
                title: "Idea for \(ideaType.rawValue)",
                description: "Description",
                ideaType: ideaType
            )
            let data = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(HermesIdea.self, from: data)
            XCTAssertEqual(decoded.ideaType, ideaType, "Round-trip failed for idea type \(ideaType)")
        }
    }

    func testHermesIdeaDecodingFromJSON() throws {
        let json = """
        {
            "id": "12345678-1234-1234-1234-123456789012",
            "title": "Echoes of the past",
            "description": "Old memories return",
            "ideaType": "worldBuilding",
            "timestamp": "2025-01-01T12:00:00Z"
        }
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(HermesIdea.self, from: json)
        XCTAssertEqual(decoded.title, "Echoes of the past")
        XCTAssertEqual(decoded.description, "Old memories return")
        XCTAssertEqual(decoded.ideaType, .worldBuilding)
        XCTAssertEqual(decoded.id, UUID(uuidString: "12345678-1234-1234-1234-123456789012"))
    }

    func testHermesIdeaDecodingWithInvalidTimestampFallsBackToCurrentDate() throws {
        let before = Date()
        let json = """
        {
            "id": "12345678-1234-1234-1234-123456789012",
            "title": "Fallback",
            "description": "Bad timestamp",
            "ideaType": "theme",
            "timestamp": "not-a-date"
        }
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(HermesIdea.self, from: json)
        let after = Date()
        // Should fall back to Date() (approximately now)
        XCTAssertGreaterThanOrEqual(decoded.timestamp.timeIntervalSince(before), 0)
        XCTAssertLessThanOrEqual(decoded.timestamp.timeIntervalSince(after), 0)
    }

    // MARK: - HermesIdea Identifiable

    func testHermesIdeaIsIdentifiable() {
        let idea = HermesIdea(title: "Identity", description: "Has an id", ideaType: .dialogue)
        // Verifies the id property exists and is a UUID
        XCTAssertNotNil(idea.id)
    }

    // MARK: - HermesError

    func testHermesErrorEmptyPrompt() {
        let error = HermesError.emptyPrompt
        XCTAssertEqual(error.errorDescription, "Please enter a prompt to inspire Hermes.")
    }

    func testHermesErrorPromptTooLong() {
        let error = HermesError.promptTooLong(4000)
        let description = error.errorDescription ?? ""
        XCTAssertTrue(description.contains("4000"))
    }

    func testHermesErrorAINotAvailable() {
        let error = HermesError.aiNotAvailable
        let description = error.errorDescription ?? ""
        XCTAssertFalse(description.isEmpty)
    }

    func testHermesErrorIdeaNotFound() {
        let id = UUID()
        let error = HermesError.ideaNotFound(id)
        let description = error.errorDescription ?? ""
        XCTAssertFalse(description.isEmpty)
    }

    func testHermesErrorAIServiceFailed() {
        let error = HermesError.aiServiceFailed("connection timeout")
        let description = error.errorDescription ?? ""
        XCTAssertTrue(description.contains("connection timeout"))
    }

    // MARK: - HermesContext

    func testHermesContextInit() {
        let docId = UUID()
        let context = HermesContext(
            genre: "Fantasy",
            logline: "A young wizard discovers a hidden school",
            currentScene: "The train arrives",
            characters: ["Harry", "Hermione"],
            themes: ["Friendship", "Courage"],
            documentId: docId
        )
        XCTAssertEqual(context.genre, "Fantasy")
        XCTAssertEqual(context.logline, "A young wizard discovers a hidden school")
        XCTAssertEqual(context.currentScene, "The train arrives")
        XCTAssertEqual(context.characters, ["Harry", "Hermione"])
        XCTAssertEqual(context.themes, ["Friendship", "Courage"])
        XCTAssertEqual(context.documentId, docId)
    }

    func testHermesContextDefaultValues() {
        let context = HermesContext()
        XCTAssertEqual(context.genre, "")
        XCTAssertEqual(context.logline, "")
        XCTAssertEqual(context.currentScene, "")
        XCTAssertTrue(context.characters.isEmpty)
        XCTAssertTrue(context.themes.isEmpty)
        XCTAssertNil(context.documentId)
    }

    // MARK: - HermesSession

    func testHermesSessionInit() {
        let context = HermesContext(genre: "Sci-Fi")
        let session = HermesSession(context: context)
        XCTAssertTrue(session.messages.isEmpty)
        XCTAssertEqual(session.context.genre, "Sci-Fi")
        XCTAssertNotNil(session.id)
    }

    func testHermesSessionLastMessageAtEqualsStartedAtWhenEmpty() {
        let session = HermesSession()
        // lastMessageAt should be close to startedAt when there are no messages
        let diff = abs(session.lastMessageAt.timeIntervalSince(session.startedAt))
        XCTAssertLessThanOrEqual(diff, 1.0)
    }
}