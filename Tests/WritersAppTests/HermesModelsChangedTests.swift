import XCTest
@testable import WritersApp

// MARK: - HermesModels Changed Tests
// This PR removed two types from HermesModels.swift:
//   - HermesTone enum (all 7 cases and displayName/promptHint properties removed)
//   - HermesSessionStats struct (removed, along with HermesService.getSessionStats and
//     WritersApp.getHermesSessionStats facade)
//
// This PR also removed from HermesService.swift:
//   - getAllIdeas(from:filteredBy:) method
//   - getSessionStats(from:) method
//
// Tests in this file verify the current post-PR state and document the changes.

// MARK: - HermesIdeaType: Still Present After Removals

final class HermesIdeaTypePostPRTests: XCTestCase {

    /// Verify all 8 ideaType cases still compile and are accessible.
    func testAllIdeaTypeCasesExist() {
        let cases = HermesIdeaType.allCases
        XCTAssertEqual(cases.count, 8)
        XCTAssertTrue(cases.contains(.plotHook))
        XCTAssertTrue(cases.contains(.characterTrait))
        XCTAssertTrue(cases.contains(.worldBuilding))
        XCTAssertTrue(cases.contains(.conflict))
        XCTAssertTrue(cases.contains(.twist))
        XCTAssertTrue(cases.contains(.dialogue))
        XCTAssertTrue(cases.contains(.setting))
        XCTAssertTrue(cases.contains(.theme))
    }

    /// HermesIdeaType must still be encodable and decodable (codable contract unchanged).
    func testIdeaTypeCodablePreservation() throws {
        let original = HermesIdeaType.worldBuilding
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(HermesIdeaType.self, from: data)
        XCTAssertEqual(decoded, original)
    }
}

// MARK: - HermesIdea: encode(to:) Docstring Added, Behavior Unchanged

final class HermesIdeaEncoderPostPRTests: XCTestCase {

    /// The encode(to:) method had a docstring added in this PR.
    /// Verify that the underlying encoding behavior remains unchanged.
    func testEncodeProducesExpectedKeys() throws {
        let idea = HermesIdea(
            title: "Shadow Realm",
            description: "A parallel dimension of darkness",
            ideaType: .setting
        )
        let data = try JSONEncoder().encode(idea)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertNotNil(json?["id"], "id key must be present in encoded output")
        XCTAssertNotNil(json?["title"], "title key must be present")
        XCTAssertNotNil(json?["description"], "description key must be present")
        XCTAssertNotNil(json?["ideaType"], "ideaType key must be present")
        XCTAssertNotNil(json?["timestamp"], "timestamp key must be present")
        XCTAssertEqual(json?["title"] as? String, "Shadow Realm")
        XCTAssertEqual(json?["ideaType"] as? String, "setting")
    }

    func testEncodeTimestampAsISO8601() throws {
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
        let idea = HermesIdea(
            title: "Time Anchor",
            description: "A point in time that never moves",
            ideaType: .theme,
            timestamp: fixedDate
        )
        let data = try JSONEncoder().encode(idea)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        guard let timestampStr = json?["timestamp"] as? String else {
            return XCTFail("timestamp must be encoded as a String")
        }
        let formatter = ISO8601DateFormatter()
        let decoded = formatter.date(from: timestampStr)
        XCTAssertNotNil(decoded, "timestamp string must parse as valid ISO-8601: \(timestampStr)")
        XCTAssertEqual(decoded!.timeIntervalSince1970, fixedDate.timeIntervalSince1970, accuracy: 1.0)
    }

    func testDecodePreservesAllFields() throws {
        let ideaId = UUID()
        let jsonString = """
        {
            "id": "\(ideaId.uuidString)",
            "title": "Forgotten Empire",
            "description": "A civilization lost to time",
            "ideaType": "worldBuilding",
            "timestamp": "2024-03-20T12:00:00Z"
        }
        """
        let idea = try JSONDecoder().decode(HermesIdea.self, from: jsonString.data(using: .utf8)!)
        XCTAssertEqual(idea.id, ideaId)
        XCTAssertEqual(idea.title, "Forgotten Empire")
        XCTAssertEqual(idea.description, "A civilization lost to time")
        XCTAssertEqual(idea.ideaType, .worldBuilding)
    }

    func testEncodeDecodeRoundTripForAllIdeaTypes() throws {
        for ideaType in HermesIdeaType.allCases {
            let original = HermesIdea(
                title: "\(ideaType.displayName) Idea",
                description: "Testing \(ideaType.rawValue)",
                ideaType: ideaType
            )
            let data = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(HermesIdea.self, from: data)
            XCTAssertEqual(decoded.ideaType, ideaType,
                "ideaType \(ideaType.rawValue) must survive encode/decode round-trip")
            XCTAssertEqual(decoded.title, original.title)
        }
    }
}

// MARK: - HermesSession: Codable Still Works After Type Removals

final class HermesSessionPostPRTests: XCTestCase {

    func testSessionCodableRoundTripWithIdeas() throws {
        let idea = HermesIdea(
            title: "The Mirror Gate",
            description: "A portal between reflections",
            ideaType: .worldBuilding,
            timestamp: Date(timeIntervalSince1970: 1_700_500_000)
        )
        let hermesMsg = HermesMessage(
            role: .hermes,
            content: "Here is an idea for your world",
            ideas: [idea],
            timestamp: Date(timeIntervalSince1970: 1_700_500_000)
        )
        let userMsg = HermesMessage(
            role: .user,
            content: "Give me world-building ideas",
            ideas: [],
            timestamp: Date(timeIntervalSince1970: 1_700_499_000)
        )

        var session = HermesSession(
            context: HermesContext(genre: "Fantasy"),
            startedAt: Date(timeIntervalSince1970: 1_700_498_000),
            lastMessageAt: Date(timeIntervalSince1970: 1_700_500_000)
        )
        session.messages = [userMsg, hermesMsg]

        let data = try JSONEncoder().encode(session)
        let decoded = try JSONDecoder().decode(HermesSession.self, from: data)

        XCTAssertEqual(decoded.messages.count, 2)
        let decodedHermesMsg = decoded.messages.first { $0.role == .hermes }
        XCTAssertEqual(decodedHermesMsg?.ideas.count, 1)
        XCTAssertEqual(decodedHermesMsg?.ideas.first?.title, "The Mirror Gate")
        XCTAssertEqual(decoded.context.genre, "Fantasy")
    }

    func testSessionMessagesAreCorrectlyTyped() {
        var session = HermesSession()
        session.messages.append(HermesMessage(role: .user, content: "User message"))
        session.messages.append(HermesMessage(role: .hermes, content: "Hermes message"))

        let userMessages = session.messages.filter { $0.role == .user }
        let hermesMessages = session.messages.filter { $0.role == .hermes }
        XCTAssertEqual(userMessages.count, 1)
        XCTAssertEqual(hermesMessages.count, 1)
    }
}

// MARK: - HermesError: Still Works After Type Removals

final class HermesErrorPostPRTests: XCTestCase {

    func testAllErrorCasesHaveNonEmptyDescriptions() {
        let errors: [HermesError] = [
            .emptyPrompt,
            .promptTooLong,
            .aiNotAvailable,
            .ideaNotFound(id: UUID()),
            .aiServiceFailed("test reason")
        ]
        for error in errors {
            XCTAssertNotNil(error.errorDescription, "\(error) must have a non-nil description")
            XCTAssertFalse(error.errorDescription!.isEmpty, "\(error) must have a non-empty description")
        }
    }

    func testAIServiceFailedContainsReason() {
        let reason = "rate limit exceeded"
        let error = HermesError.aiServiceFailed(reason)
        XCTAssertTrue(error.errorDescription?.contains(reason) ?? false)
    }
}