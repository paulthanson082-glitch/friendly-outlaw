import XCTest
@testable import WritersApp

// MARK: - MessageRole Tests

final class MessageRoleTests: XCTestCase {

    func testMessageRoleRawValues() {
        XCTAssertEqual(MessageRole.user.rawValue, "user")
        XCTAssertEqual(MessageRole.assistant.rawValue, "assistant")
        XCTAssertEqual(MessageRole.system.rawValue, "system")
    }

    func testMessageRoleCodableRoundTrip() throws {
        for role in [MessageRole.user, .assistant, .system] {
            let encoded = try JSONEncoder().encode(role)
            let decoded = try JSONDecoder().decode(MessageRole.self, from: encoded)
            XCTAssertEqual(decoded, role)
        }
    }

    func testMessageRoleInitFromRawValue() {
        XCTAssertEqual(MessageRole(rawValue: "user"), .user)
        XCTAssertEqual(MessageRole(rawValue: "assistant"), .assistant)
        XCTAssertEqual(MessageRole(rawValue: "system"), .system)
        XCTAssertNil(MessageRole(rawValue: "unknown"))
    }
}

// MARK: - ChatMessage Tests

final class ChatMessageTests: XCTestCase {

    func testChatMessageDefaultId() {
        let msg1 = ChatMessage(role: .user, content: "Hello")
        let msg2 = ChatMessage(role: .user, content: "Hello")
        XCTAssertNotEqual(msg1.id, msg2.id)
    }

    func testChatMessagePropertiesStoredCorrectly() {
        let id = UUID()
        let date = Date(timeIntervalSinceReferenceDate: 0)
        let msg = ChatMessage(id: id, role: .assistant, content: "Response", timestamp: date)
        XCTAssertEqual(msg.id, id)
        XCTAssertEqual(msg.role, .assistant)
        XCTAssertEqual(msg.content, "Response")
        XCTAssertEqual(msg.timestamp, date)
    }

    func testChatMessageIsIdentifiable() {
        let msg = ChatMessage(role: .user, content: "Test")
        XCTAssertNotNil(msg.id)
    }

    func testChatMessageCodableRoundTrip() throws {
        let original = ChatMessage(
            id: UUID(),
            role: .user,
            content: "Round-trip test",
            timestamp: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ChatMessage.self, from: encoded)
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.role, original.role)
        XCTAssertEqual(decoded.content, original.content)
        // Timestamps encoded as ISO-8601 strings lose sub-second precision
        XCTAssertEqual(decoded.timestamp.timeIntervalSince1970,
                       original.timestamp.timeIntervalSince1970,
                       accuracy: 1.0)
    }

    func testChatMessageCodableForAllRoles() throws {
        for role in [MessageRole.user, .assistant, .system] {
            let msg = ChatMessage(role: role, content: "Test")
            let encoded = try JSONEncoder().encode(msg)
            let decoded = try JSONDecoder().decode(ChatMessage.self, from: encoded)
            XCTAssertEqual(decoded.role, role)
        }
    }
}

// MARK: - ConversationContext Tests

final class ConversationContextTests: XCTestCase {

    func testDefaultValues() {
        let context = ConversationContext()
        XCTAssertNil(context.activeDocumentId)
        XCTAssertTrue(context.documentTitles.isEmpty)
        XCTAssertTrue(context.recentTopics.isEmpty)
        XCTAssertTrue(context.userPreferences.isEmpty)
    }

    func testCustomValues() {
        let docId = UUID()
        let context = ConversationContext(
            activeDocumentId: docId,
            documentTitles: ["My Novel", "My Blog"],
            recentTopics: ["character development"],
            userPreferences: ["tone": "casual"]
        )
        XCTAssertEqual(context.activeDocumentId, docId)
        XCTAssertEqual(context.documentTitles, ["My Novel", "My Blog"])
        XCTAssertEqual(context.recentTopics, ["character development"])
        XCTAssertEqual(context.userPreferences["tone"], "casual")
    }

    func testConversationContextCodableRoundTrip() throws {
        let docId = UUID()
        let original = ConversationContext(
            activeDocumentId: docId,
            documentTitles: ["Novel"],
            recentTopics: ["plot"],
            userPreferences: ["style": "academic"]
        )
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ConversationContext.self, from: encoded)
        XCTAssertEqual(decoded.activeDocumentId, original.activeDocumentId)
        XCTAssertEqual(decoded.documentTitles, original.documentTitles)
        XCTAssertEqual(decoded.recentTopics, original.recentTopics)
        XCTAssertEqual(decoded.userPreferences, original.userPreferences)
    }

    func testConversationContextWithNilDocumentId() throws {
        let original = ConversationContext(activeDocumentId: nil)
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ConversationContext.self, from: encoded)
        XCTAssertNil(decoded.activeDocumentId)
    }
}

// MARK: - ConversationSession Tests

final class ConversationSessionTests: XCTestCase {

    func testDefaultSessionHasNoMessages() {
        let session = ConversationSession()
        XCTAssertTrue(session.messages.isEmpty)
    }

    func testSessionIdIsUnique() {
        let s1 = ConversationSession()
        let s2 = ConversationSession()
        XCTAssertNotEqual(s1.id, s2.id)
    }

    func testSessionCanAddMessages() {
        var session = ConversationSession()
        let msg = ChatMessage(role: .user, content: "Hello Jules")
        session.messages.append(msg)
        XCTAssertEqual(session.messages.count, 1)
        XCTAssertEqual(session.messages[0].content, "Hello Jules")
    }

    func testConversationSessionCodableRoundTrip() throws {
        let id = UUID()
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
        var original = ConversationSession(
            id: id,
            startedAt: fixedDate,
            lastMessageAt: fixedDate,
            messages: [],
            context: ConversationContext(documentTitles: ["Doc1"])
        )
        let msg = ChatMessage(role: .user, content: "Test message", timestamp: fixedDate)
        original.messages.append(msg)

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ConversationSession.self, from: encoded)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.messages.count, 1)
        XCTAssertEqual(decoded.messages[0].content, "Test message")
        XCTAssertEqual(decoded.context.documentTitles, ["Doc1"])
        XCTAssertEqual(decoded.startedAt.timeIntervalSince1970,
                       original.startedAt.timeIntervalSince1970,
                       accuracy: 1.0)
    }
}

// MARK: - ChatbotError Tests

final class ChatbotErrorTests: XCTestCase {

    func testEmptyMessageErrorDescription() {
        let error = ChatbotError.emptyMessage
        XCTAssertEqual(error.errorDescription, "Please enter a message.")
    }

    func testMessageTooLongErrorDescription() {
        let error = ChatbotError.messageTooLong
        XCTAssertEqual(error.errorDescription, "Message exceeds maximum length.")
    }

    func testAINotAvailableErrorDescription() {
        let error = ChatbotError.aiNotAvailable
        let desc = error.errorDescription
        XCTAssertNotNil(desc)
        XCTAssertTrue(desc!.lowercased().contains("api key") || desc!.lowercased().contains("not enabled"))
    }

    func testDocumentNotFoundErrorDescriptionContainsId() {
        let id = UUID()
        let error = ChatbotError.documentNotFound(id: id)
        let desc = error.errorDescription ?? ""
        XCTAssertTrue(desc.contains(id.uuidString))
    }

    func testConversationLimitExceededErrorDescription() {
        let error = ChatbotError.conversationLimitExceeded
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription!.isEmpty)
    }

    func testInvalidContextErrorDescription() {
        let error = ChatbotError.invalidContext
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription!.isEmpty)
    }

    func testAIServiceFailedErrorDescriptionContainsReason() {
        let error = ChatbotError.aiServiceFailed("Network timeout")
        let desc = error.errorDescription ?? ""
        XCTAssertTrue(desc.contains("Network timeout"))
    }
}
