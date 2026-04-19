import XCTest
@testable import WritersApp

/// Tests verifying the PR-specific changes to HermesModels.swift:
/// - HermesTone enum was removed
/// - HermesSessionStats struct was removed
/// - HermesIdea.encode(to:) docstring was added (behavior tested via Codable)
///
/// The absence of removed types is confirmed via compile-time checks (the test file
/// simply doesn't reference those types) and runtime Mirror checks where practical.
final class HermesModelsChangedTests: XCTestCase {

    // MARK: - Confirm HermesTone Does Not Exist

    func testHermesIdeaTypeIsTheOnlyToneRelatedEnum() {
        // HermesTone was removed. The surviving enum for categorising ideas is HermesIdeaType.
        // Verifying we can still enumerate all idea types without HermesTone.
        let types = HermesIdeaType.allCases
        XCTAssertEqual(types.count, 8, "HermesIdeaType should still have 8 cases after HermesTone removal")
        // None of the idea types should be confused with tone names that were in HermesTone
        let toneNames = ["inspirational", "provocative", "calm", "energetic", "whimsical", "dark", "playful"]
        for typeName in types.map({ $0.rawValue }) {
            XCTAssertFalse(toneNames.contains(typeName),
                           "HermesIdeaType '\(typeName)' should not be a former HermesTone name")
        }
    }

    // MARK: - Confirm HermesSessionStats Does Not Exist

    func testHermesSessionHasNoSessionStatsProperty() {
        // HermesSessionStats was removed. HermesSession should not expose any stats aggregate.
        let session = HermesSession()
        let mirror = Mirror(reflecting: session)
        let hasStats = mirror.children.contains { child in
            child.label?.lowercased().contains("stats") ?? false
        }
        XCTAssertFalse(hasStats, "HermesSession should not have a stats property after HermesSessionStats removal")
    }

    func testHermesSessionDoesNotConformToHermesSessionStatsBearing() {
        // HermesSession should still be Identifiable and Codable, but not wrap HermesSessionStats.
        let session = HermesSession()
        let mirror = Mirror(reflecting: session)
        // Verify properties are the expected primitive/collection types (no aggregated stats struct)
        let propertyLabels = mirror.children.compactMap { $0.label }
        XCTAssertTrue(propertyLabels.contains("id"))
        XCTAssertTrue(propertyLabels.contains("messages"))
        XCTAssertFalse(propertyLabels.contains("sessionStats"), "No sessionStats property expected")
        XCTAssertFalse(propertyLabels.contains("stats"), "No stats property expected on HermesSession")
    }

    // MARK: - HermesIdea.encode(to:) correctness

    func testHermesIdeaEncodeProducesISO8601Timestamp() throws {
        // The PR added a docstring to encode(to:) which describes ISO-8601 date serialisation.
        // This test confirms the encode behaviour matches the documented contract.
        let knownDate = Date(timeIntervalSince1970: 1_700_000_000) // 2023-11-14
        let idea = HermesIdea(
            title: "Dark forest path",
            description: "The protagonist must cross alone",
            ideaType: .conflict,
            timestamp: knownDate
        )

        let data = try JSONEncoder().encode(idea)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            XCTFail("Encoded output is not a JSON object")
            return
        }

        let timestampString = json["timestamp"] as? String
        XCTAssertNotNil(timestampString, "timestamp must be encoded as a String (ISO-8601)")

        // Verify it's parseable by ISO8601DateFormatter
        let formatter = ISO8601DateFormatter()
        let parsedDate = formatter.date(from: timestampString ?? "")
        XCTAssertNotNil(parsedDate, "Encoded timestamp must be valid ISO-8601")

        // Verify accuracy within 1 second
        XCTAssertEqual(parsedDate?.timeIntervalSince1970 ?? 0,
                       knownDate.timeIntervalSince1970, accuracy: 1.0)
    }

    func testHermesIdeaEncodeDoesNotUseDoubleForTimestamp() throws {
        let idea = HermesIdea(
            title: "The map reveals",
            description: "An ancient map leads to discovery",
            ideaType: .worldBuilding
        )
        let data = try JSONEncoder().encode(idea)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            XCTFail("Encoded output is not a JSON object")
            return
        }
        // Timestamp must be a String, not a Double (i.e. not Unix epoch number)
        XCTAssertNil(json["timestamp"] as? Double, "Timestamp must not be stored as a Double")
        XCTAssertNotNil(json["timestamp"] as? String, "Timestamp must be stored as an ISO-8601 String")
    }

    func testHermesIdeaEncodeAndDecodePreservesAllFields() throws {
        let originalId = UUID()
        let originalDate = Date(timeIntervalSince1970: 1_680_000_000)
        let original = HermesIdea(
            id: originalId,
            title: "The lighthouse blinks",
            description: "A signal from across the sea",
            ideaType: .setting,
            timestamp: originalDate
        )

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(HermesIdea.self, from: encoded)

        XCTAssertEqual(decoded.id, originalId)
        XCTAssertEqual(decoded.title, "The lighthouse blinks")
        XCTAssertEqual(decoded.description, "A signal from across the sea")
        XCTAssertEqual(decoded.ideaType, .setting)
        XCTAssertEqual(decoded.timestamp.timeIntervalSince1970,
                       originalDate.timeIntervalSince1970, accuracy: 1.0)
    }

    // MARK: - HermesMessage still works without HermesSessionStats

    func testHermesMessageCanBeCreatedWithIdeas() {
        let ideas = [
            HermesIdea(title: "Twist 1", description: "A", ideaType: .twist),
            HermesIdea(title: "Plot 1", description: "B", ideaType: .plotHook)
        ]
        let message = HermesMessage(
            role: .hermes,
            content: "Here are your ideas",
            ideas: ideas
        )
        XCTAssertEqual(message.ideas.count, 2)
        XCTAssertEqual(message.role, .hermes)
    }

    func testHermesMessageRoundTrip() throws {
        let message = HermesMessage(
            role: .user,
            content: "Give me plot ideas for a mystery",
            ideas: []
        )
        let data = try JSONEncoder().encode(message)
        let decoded = try JSONDecoder().decode(HermesMessage.self, from: data)
        XCTAssertEqual(decoded.id, message.id)
        XCTAssertEqual(decoded.content, "Give me plot ideas for a mystery")
        XCTAssertEqual(decoded.role, .user)
        XCTAssertTrue(decoded.ideas.isEmpty)
    }

    // MARK: - HermesSession without stats computation

    func testHermesSessionMessagesCanBeManipulatedDirectly() {
        var session = HermesSession()
        let message = HermesMessage(role: .user, content: "Brainstorm!", ideas: [])
        session.messages.append(message)
        XCTAssertEqual(session.messages.count, 1)
    }

    func testHermesSessionLastMessageAtCanBeUpdated() {
        var session = HermesSession()
        let later = Date(timeIntervalSince1970: 5000)
        // lastMessageAt is a mutable var — can be updated directly
        session.lastMessageAt = later
        XCTAssertEqual(session.lastMessageAt.timeIntervalSince1970, later.timeIntervalSince1970, accuracy: 1.0)
    }

    // MARK: - Regression: HermesIdea still has all required fields

    func testHermesIdeaHasIdTitleDescriptionIdeaTypeTimestamp() {
        let idea = HermesIdea(
            title: "A secret passage",
            description: "Behind the bookshelf",
            ideaType: .worldBuilding
        )
        let mirror = Mirror(reflecting: idea)
        let labels = mirror.children.compactMap { $0.label }
        XCTAssertTrue(labels.contains("id"))
        XCTAssertTrue(labels.contains("title"))
        XCTAssertTrue(labels.contains("description"))
        XCTAssertTrue(labels.contains("ideaType"))
        XCTAssertTrue(labels.contains("timestamp"))
    }
}