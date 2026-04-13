import Foundation

// MARK: - Hermes Models

/// The type of creative idea Hermes generated
public enum HermesIdeaType: String, Codable, CaseIterable {
    case plotHook = "plotHook"
    case characterTrait = "characterTrait"
    case worldBuilding = "worldBuilding"
    case conflict = "conflict"
    case twist = "twist"
    case dialogue = "dialogue"
    case setting = "setting"
    case theme = "theme"

    public var displayName: String {
        switch self {
        case .plotHook:       return "Plot Hook"
        case .characterTrait: return "Character Trait"
        case .worldBuilding:  return "World Building"
        case .conflict:       return "Conflict"
        case .twist:          return "Twist"
        case .dialogue:       return "Dialogue"
        case .setting:        return "Setting"
        case .theme:          return "Theme"
        }
    }
}

/// A single structured creative idea from Hermes
public struct HermesIdea: Identifiable, Codable {
    public let id: UUID
    public let title: String
    public let description: String
    public let ideaType: HermesIdeaType
    public let timestamp: Date

    public init(
        id: UUID = UUID(),
        title: String,
        description: String,
        ideaType: HermesIdeaType,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.ideaType = ideaType
        self.timestamp = timestamp
    }

    enum CodingKeys: String, CodingKey {
        case id, title, description, ideaType, timestamp
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        ideaType = try container.decode(HermesIdeaType.self, forKey: .ideaType)
        let timestampString = try container.decode(String.self, forKey: .timestamp)
        let formatter = ISO8601DateFormatter()
        timestamp = formatter.date(from: timestampString) ?? Date()
    }

    /// Encodes the instance into the provided encoder.
    /// 
    /// Encodes `id`, `title`, `description`, and `ideaType` using their coding keys and serializes `timestamp` as an ISO-8601 formatted string.
    /// - Parameter encoder: The encoder to write this value into.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(ideaType, forKey: .ideaType)
        let formatter = ISO8601DateFormatter()
        try container.encode(formatter.string(from: timestamp), forKey: .timestamp)
    }
}

/// Story context provided to Hermes to ground its ideation
public struct HermesContext: Codable {
    public let genre: String
    public let logline: String
    public let currentScene: String
    public let characters: [String]
    public let themes: [String]
    public let documentId: UUID?

    public init(
        genre: String = "",
        logline: String = "",
        currentScene: String = "",
        characters: [String] = [],
        themes: [String] = [],
        documentId: UUID? = nil
    ) {
        self.genre = genre
        self.logline = logline
        self.currentScene = currentScene
        self.characters = characters
        self.themes = themes
        self.documentId = documentId
    }
}

/// Role of a message in a Hermes session
public enum HermesMessageRole: String, Codable {
    case user
    case hermes
}

/// A single message in a Hermes ideation session
public struct HermesMessage: Identifiable, Codable {
    public let id: UUID
    public let role: HermesMessageRole
    public let content: String
    public let ideas: [HermesIdea]
    public let timestamp: Date

    public init(
        id: UUID = UUID(),
        role: HermesMessageRole,
        content: String,
        ideas: [HermesIdea] = [],
        timestamp: Date = Date()
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.ideas = ideas
        self.timestamp = timestamp
    }

    enum CodingKeys: String, CodingKey {
        case id, role, content, ideas, timestamp
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        role = try container.decode(HermesMessageRole.self, forKey: .role)
        content = try container.decode(String.self, forKey: .content)
        ideas = try container.decode([HermesIdea].self, forKey: .ideas)
        let timestampString = try container.decode(String.self, forKey: .timestamp)
        let formatter = ISO8601DateFormatter()
        timestamp = formatter.date(from: timestampString) ?? Date()
    }

    /// Encodes the message's properties into the given encoder.
    /// 
    /// The message's `timestamp` is serialized as an ISO-8601 formatted string.
    /// - Parameters:
    ///   - encoder: The encoder to write this message's encoded representation into.
    /// - Throws: An error if any of the message's properties fail to encode.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(role, forKey: .role)
        try container.encode(content, forKey: .content)
        try container.encode(ideas, forKey: .ideas)
        let formatter = ISO8601DateFormatter()
        try container.encode(formatter.string(from: timestamp), forKey: .timestamp)
    }
}

/// An ongoing ideation session with Hermes
public struct HermesSession: Identifiable, Codable {
    public let id: UUID
    public var messages: [HermesMessage]
    public let context: HermesContext
    public let startedAt: Date
    public var lastMessageAt: Date

    public init(
        id: UUID = UUID(),
        messages: [HermesMessage] = [],
        context: HermesContext = HermesContext(),
        startedAt: Date = Date(),
        lastMessageAt: Date = Date()
    ) {
        self.id = id
        self.messages = messages
        self.context = context
        self.startedAt = startedAt
        self.lastMessageAt = lastMessageAt
    }

    enum CodingKeys: String, CodingKey {
        case id, messages, context, startedAt, lastMessageAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        messages = try container.decode([HermesMessage].self, forKey: .messages)
        context = try container.decode(HermesContext.self, forKey: .context)
        let formatter = ISO8601DateFormatter()
        let startedAtString = try container.decode(String.self, forKey: .startedAt)
        startedAt = formatter.date(from: startedAtString) ?? Date()
        let lastMessageAtString = try container.decode(String.self, forKey: .lastMessageAt)
        lastMessageAt = formatter.date(from: lastMessageAtString) ?? Date()
    }

    /// Encodes the session into the provided encoder, serializing `startedAt` and `lastMessageAt` as ISO-8601 strings.
    ///
    /// Encodes `id`, `messages`, and `context` using their standard keyed representations and writes `startedAt` and `lastMessageAt` as ISO-8601 formatted strings.
    /// - Parameter encoder: The encoder to write data to.
    /// - Throws: An error if any of the values fail to encode.
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

/// The response returned from a Hermes ideation request (ephemeral, not persisted)
public struct HermesResponse {
    public let sessionId: UUID
    public let message: String
    public let ideas: [HermesIdea]
    public let timestamp: Date

    public init(
        sessionId: UUID,
        message: String,
        ideas: [HermesIdea],
        timestamp: Date = Date()
    ) {
        self.sessionId = sessionId
        self.message = message
        self.ideas = ideas
        self.timestamp = timestamp
    }
}

/// Errors that can occur in Hermes
public enum HermesError: LocalizedError {
    case emptyPrompt
    case promptTooLong
    case aiNotAvailable
    case ideaNotFound(id: UUID)
    case aiServiceFailed(String)

    public var errorDescription: String? {
        switch self {
        case .emptyPrompt:
            return "Please enter a prompt for Hermes."
        case .promptTooLong:
            return "Prompt exceeds maximum length."
        case .aiNotAvailable:
            return "Hermes requires AI to be enabled. Please configure an API key."
        case .ideaNotFound(let id):
            return "Idea with ID \(id) was not found in this session."
        case .aiServiceFailed(let reason):
            return "Hermes AI error: \(reason)"
        }
    }
}