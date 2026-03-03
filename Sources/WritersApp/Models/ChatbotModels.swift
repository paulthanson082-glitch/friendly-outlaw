import Foundation

// MARK: - Chatbot Models

/// Represents a single message in a conversation
public struct ChatMessage: Identifiable, Codable {
    public let id: UUID
    public let role: MessageRole
    public let content: String
    public let timestamp: Date

    public init(
        id: UUID = UUID(),
        role: MessageRole,
        content: String,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }

    enum CodingKeys: String, CodingKey {
        case id
        case role
        case content
        case timestamp
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        role = try container.decode(MessageRole.self, forKey: .role)
        content = try container.decode(String.self, forKey: .content)

        let timestampString = try container.decode(String.self, forKey: .timestamp)
        let formatter = ISO8601DateFormatter()
        timestamp = formatter.date(from: timestampString) ?? Date()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(role, forKey: .role)
        try container.encode(content, forKey: .content)

        let formatter = ISO8601DateFormatter()
        let timestampString = formatter.string(from: timestamp)
        try container.encode(timestampString, forKey: .timestamp)
    }
}

/// Role of the message sender
public enum MessageRole: String, Codable {
    case user
    case assistant
    case system
}

/// Context for building a message prompt
public struct ConversationContext: Codable {
    public let activeDocumentId: UUID?
    public let documentTitles: [String]
    public let recentTopics: [String]
    public let userPreferences: [String: String]

    public init(
        activeDocumentId: UUID? = nil,
        documentTitles: [String] = [],
        recentTopics: [String] = [],
        userPreferences: [String: String] = [:]
    ) {
        self.activeDocumentId = activeDocumentId
        self.documentTitles = documentTitles
        self.recentTopics = recentTopics
        self.userPreferences = userPreferences
    }
}

/// A conversation session with Jules
public struct ConversationSession: Identifiable, Codable {
    public let id: UUID
    public let startedAt: Date
    public var lastMessageAt: Date
    public var messages: [ChatMessage]
    public var context: ConversationContext

    public init(
        id: UUID = UUID(),
        startedAt: Date = Date(),
        lastMessageAt: Date = Date(),
        messages: [ChatMessage] = [],
        context: ConversationContext = ConversationContext()
    ) {
        self.id = id
        self.startedAt = startedAt
        self.lastMessageAt = lastMessageAt
        self.messages = messages
        self.context = context
    }

    enum CodingKeys: String, CodingKey {
        case id
        case startedAt
        case lastMessageAt
        case messages
        case context
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        messages = try container.decode([ChatMessage].self, forKey: .messages)
        context = try container.decode(ConversationContext.self, forKey: .context)

        let startedAtString = try container.decode(String.self, forKey: .startedAt)
        let formatter = ISO8601DateFormatter()
        startedAt = formatter.date(from: startedAtString) ?? Date()

        let lastMessageAtString = try container.decode(String.self, forKey: .lastMessageAt)
        lastMessageAt = formatter.date(from: lastMessageAtString) ?? Date()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(messages, forKey: .messages)
        try container.encode(context, forKey: .context)

        let formatter = ISO8601DateFormatter()
        try container.encode(formatter.string(from: startedAt), forKey: .startedAt)
        try container.encode(formatter.string(from: lastMessageAt), forKey: .lastMessageAt)
    }
}

/// Errors that can occur in the chatbot service
public enum ChatbotError: LocalizedError {
    case emptyMessage
    case messageTooLong
    case aiNotAvailable
    case documentNotFound(id: UUID)
    case conversationLimitExceeded
    case invalidContext
    case aiServiceFailed(String)

    public var errorDescription: String? {
        switch self {
        case .emptyMessage:
            return "Please enter a message."
        case .messageTooLong:
            return "Message exceeds maximum length."
        case .aiNotAvailable:
            return "The AI assistant is not enabled. Please configure an API key."
        case .documentNotFound(let id):
            return "Document with ID \(id) not found."
        case .conversationLimitExceeded:
            return "Conversation history limit exceeded."
        case .invalidContext:
            return "Invalid conversation context."
        case .aiServiceFailed(let reason):
            return "AI service error: \(reason)"
        }
    }
}
