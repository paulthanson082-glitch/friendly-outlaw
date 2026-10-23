import Foundation

// MARK: - Hermes Models

/// The emotional tone Hermes should adopt when generating ideas
public enum HermesTone: String, Codable, CaseIterable {
    case inspirational
    case provocative
    case calm
    case energetic
    case whimsical
    case dark
    case playful

    public var displayName: String {
        switch self {
        case .inspirational: return "Inspirational"
        case .provocative:   return "Provocative"
        case .calm:          return "Calm"
        case .energetic:     return "Energetic"
        case .whimsical:     return "Whimsical"
        case .dark:          return "Dark"
        case .playful:       return "Playful"
        }
    }

    /// One-line prompt fragment injected into the Hermes persona when this tone is active
    public var promptHint: String {
        switch self {
        case .inspirational: return "Be uplifting and motivating — make the writer feel that anything is possible."
        case .provocative:   return "Be bold and challenging — push conventional boundaries and subvert expectations."
        case .calm:          return "Be measured and serene — offer ideas with quiet confidence and gentle clarity."
        case .energetic:     return "Be vivid and fast-paced — flood the writer with momentum and excitement."
        case .whimsical:     return "Be playfully strange and dreamy — let ideas drift into the unexpected."
        case .dark:          return "Be brooding and intense — explore shadow, conflict, and moral complexity."
        case .playful:       return "Be lighthearted and witty — ideas should sparkle with humour and fun."
        }
    }
}

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

/// Aggregated statistics for a completed or in-progress Hermes session
public struct HermesSessionStats: Codable, Identifiable {
    public var id: UUID { sessionId }
    /// Identifier of the session these stats describe
    public let sessionId: UUID
    /// Total number of messages exchanged (user + Hermes combined)
    public let messageCount: Int
    /// Total number of ideas generated across all Hermes messages
    public let totalIdeas: Int
    /// Number of ideas the writer has marked as favourite
    public let favoriteCount: Int
    /// Idea count broken down by `HermesIdeaType`
    public let ideaCountByType: [HermesIdeaType: Int]
    /// Wall-clock duration from session start to the last message, in seconds
    public let sessionDuration: TimeInterval
    /// Mean number of ideas per Hermes message (0 when no Hermes messages exist)
    public let averageIdeasPerMessage: Double

    public init(
        sessionId: UUID,
        messageCount: Int,
        totalIdeas: Int,
        favoriteCount: Int,
        ideaCountByType: [HermesIdeaType: Int],
        sessionDuration: TimeInterval,
        averageIdeasPerMessage: Double
    ) {
        self.sessionId = sessionId
        self.messageCount = messageCount
        self.totalIdeas = totalIdeas
        self.favoriteCount = favoriteCount
        self.ideaCountByType = ideaCountByType
        self.sessionDuration = sessionDuration
        self.averageIdeasPerMessage = averageIdeasPerMessage
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

// MARK: - Archiver Models

/// A snapshot of archive state at a point in time (word count, streak, documents completed, etc.)
public struct ArchiveSnapshot: Identifiable, Codable {
    public let id: UUID
    public let documentId: UUID
    public let timestamp: Date
    public let wordCount: Int
    public let characterCount: Int
    public let sessionCount: Int
    public let daysStreak: Int
    public let title: String
    public let summary: String
    public let tags: [String]

    public init(
        id: UUID = UUID(),
        documentId: UUID,
        timestamp: Date = Date(),
        wordCount: Int = 0,
        characterCount: Int = 0,
        sessionCount: Int = 0,
        daysStreak: Int = 0,
        title: String,
        summary: String,
        tags: [String] = []
    ) {
        self.id = id
        self.documentId = documentId
        self.timestamp = timestamp
        self.wordCount = wordCount
        self.characterCount = characterCount
        self.sessionCount = sessionCount
        self.daysStreak = daysStreak
        self.title = title
        self.summary = summary
        self.tags = tags
    }
}

/// A named collection of archived documents, ideas, and snapshots
public struct ArchiveCollection: Identifiable, Codable {
    public let id: UUID
    public let name: String
    public let description: String
    public var documentIds: [UUID]
    public var ideaIds: [UUID]
    public var snapshotIds: [UUID]
    public let createdAt: Date
    public var updatedAt: Date
    public var tags: [String]
    public var theme: String

    public init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        documentIds: [UUID] = [],
        ideaIds: [UUID] = [],
        snapshotIds: [UUID] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        tags: [String] = [],
        theme: String = "default"
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.documentIds = documentIds
        self.ideaIds = ideaIds
        self.snapshotIds = snapshotIds
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.tags = tags
        self.theme = theme
    }
}

/// Context provided to Archiver for organizing and summarizing work
public struct ArchiverContext: Codable {
    public let userId: UUID?
    public let timeRange: DateRange?
    public let excludedTags: [String]
    public let priorityTags: [String]

    public struct DateRange: Codable {
        public let start: Date
        public let end: Date

        public init(start: Date, end: Date) {
            self.start = start
            self.end = end
        }
    }

    public init(
        userId: UUID? = nil,
        timeRange: DateRange? = nil,
        excludedTags: [String] = [],
        priorityTags: [String] = []
    ) {
        self.userId = userId
        self.timeRange = timeRange
        self.excludedTags = excludedTags
        self.priorityTags = priorityTags
    }
}

/// Archiver agent profile configuration for organizing and preserving creative work
public struct ArchiverProfile: Codable {
    public let id: UUID
    public let name: String
    public var collections: [ArchiveCollection]
    public var snapshots: [ArchiveSnapshot]
    public let createdAt: Date
    public var lastArchiveAt: Date?

    public init(
        id: UUID = UUID(),
        name: String = "My Archive",
        collections: [ArchiveCollection] = [],
        snapshots: [ArchiveSnapshot] = [],
        createdAt: Date = Date(),
        lastArchiveAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.collections = collections
        self.snapshots = snapshots
        self.createdAt = createdAt
        self.lastArchiveAt = lastArchiveAt
    }
}