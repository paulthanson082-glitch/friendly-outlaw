import Foundation

// MARK: - Channel Event

/// An event pushed into a running session from a channel
public struct ChannelEvent {
    /// Unique event identifier
    public let id: UUID

    /// The channel that produced this event
    public let channelId: String

    /// The sender of this event
    public let sender: ChannelSender

    /// Event payload
    public let message: ChannelMessage

    /// When the event was received
    public let receivedAt: Date

    public init(
        id: UUID = UUID(),
        channelId: String,
        sender: ChannelSender,
        message: ChannelMessage,
        receivedAt: Date = Date()
    ) {
        self.id = id
        self.channelId = channelId
        self.sender = sender
        self.message = message
        self.receivedAt = receivedAt
    }
}

// MARK: - Channel Sender

/// Identity of a message sender on a channel
public struct ChannelSender: Equatable {
    /// Platform-specific sender identifier (e.g. Telegram user id)
    public let id: String

    /// Human-readable display name
    public let displayName: String

    /// Which platform this sender is on
    public let platform: ChannelPlatform

    public init(id: String, displayName: String, platform: ChannelPlatform) {
        self.id = id
        self.displayName = displayName
        self.platform = platform
    }
}

// MARK: - Channel Platform

/// The external platform a channel bridges to
public enum ChannelPlatform: String, Codable, CaseIterable {
    case telegram = "telegram"
    case discord = "discord"
    case fakechat = "fakechat"
    case custom = "custom"

    public var displayName: String {
        switch self {
        case .telegram: return "Telegram"
        case .discord: return "Discord"
        case .fakechat: return "Fakechat (demo)"
        case .custom: return "Custom"
        }
    }
}

// MARK: - Channel Message

/// A message carried by a channel event
public struct ChannelMessage {
    /// Plain-text content of the message
    public let text: String

    /// Optional structured metadata (e.g. image URLs, attachments)
    public let metadata: [String: String]

    public init(text: String, metadata: [String: String] = [:]) {
        self.text = text
        self.metadata = metadata
    }
}

// MARK: - Channel Reply

/// A reply sent back through a channel
public struct ChannelReply {
    /// The event this reply is responding to
    public let eventId: UUID

    /// The channel to send the reply on
    public let channelId: String

    /// Reply text
    public let text: String

    /// When the reply was sent
    public let sentAt: Date

    public init(eventId: UUID, channelId: String, text: String, sentAt: Date = Date()) {
        self.eventId = eventId
        self.channelId = channelId
        self.text = text
        self.sentAt = sentAt
    }
}

// MARK: - Sender Allowlist

/// Manages which senders are allowed to push events into the session
public struct SenderAllowlist {
    private var allowedSenderIds: Set<String>

    /// Current policy for senders not in the allowlist
    public var policy: AllowlistPolicy

    public init(policy: AllowlistPolicy = .allowAll, initialIds: [String] = []) {
        self.policy = policy
        self.allowedSenderIds = Set(initialIds)
    }

    /// Whether the given sender is allowed to push events
    public func allows(sender: ChannelSender) -> Bool {
        switch policy {
        case .allowAll:
            return true
        case .allowlist:
            return allowedSenderIds.contains(sender.id)
        case .denyAll:
            return false
        }
    }

    /// Add a sender to the allowlist
    public mutating func add(senderId: String) {
        allowedSenderIds.insert(senderId)
    }

    /// Remove a sender from the allowlist
    public mutating func remove(senderId: String) {
        allowedSenderIds.remove(senderId)
    }

    /// All currently allowlisted sender IDs
    public var allowedIds: [String] {
        return Array(allowedSenderIds)
    }
}

// MARK: - Allowlist Policy

/// Controls who can send events to the session
public enum AllowlistPolicy: String, Codable {
    /// Accept events from any sender (default, open)
    case allowAll = "allow_all"
    /// Only accept events from explicitly allowlisted senders
    case allowlist = "allowlist"
    /// Reject all incoming events
    case denyAll = "deny_all"
}

// MARK: - Channel Pairing

/// A pairing request used to add a sender to the allowlist
public struct ChannelPairingRequest {
    /// The one-time pairing code shown to the sender
    public let code: String

    /// The sender identity that initiated the pairing
    public let sender: ChannelSender

    /// The channel this pairing is for
    public let channelId: String

    /// When the code was generated
    public let createdAt: Date

    /// When the code expires
    public let expiresAt: Date

    public var isExpired: Bool {
        return Date() > expiresAt
    }

    public init(
        code: String = String(format: "%06d", Int.random(in: 100000...999999)),
        sender: ChannelSender,
        channelId: String,
        createdAt: Date = Date(),
        ttl: TimeInterval = 300  // 5 minutes
    ) {
        self.code = code
        self.sender = sender
        self.channelId = channelId
        self.createdAt = createdAt
        self.expiresAt = createdAt.addingTimeInterval(ttl)
    }
}

// MARK: - Channel Configuration

/// Configuration for a channel
public struct ChannelConfiguration: Codable {
    /// Channel plugin id
    public let channelId: String

    /// Human-readable name
    public let name: String

    /// Platform this channel connects to
    public let platform: ChannelPlatform

    /// Whether the channel is active in the current session
    public var isEnabled: Bool

    /// Platform-specific settings (e.g. bot token)
    public var settings: [String: String]

    public init(
        channelId: String,
        name: String,
        platform: ChannelPlatform,
        isEnabled: Bool = true,
        settings: [String: String] = [:]
    ) {
        self.channelId = channelId
        self.name = name
        self.platform = platform
        self.isEnabled = isEnabled
        self.settings = settings
    }
}

// MARK: - Channel Error

/// Errors that can occur in channel operations
public enum ChannelError: LocalizedError {
    case channelNotFound(String)
    case channelNotEnabled(String)
    case senderNotAllowed(String)
    case pairingCodeExpired
    case pairingCodeInvalid
    case pairingCodeNotFound
    case replyFailed(String)
    case notInitialized

    public var errorDescription: String? {
        switch self {
        case .channelNotFound(let id):
            return "Channel not found: \(id)"
        case .channelNotEnabled(let id):
            return "Channel is not enabled: \(id)"
        case .senderNotAllowed(let senderId):
            return "Sender is not in the allowlist: \(senderId)"
        case .pairingCodeExpired:
            return "Pairing code has expired"
        case .pairingCodeInvalid:
            return "Pairing code is invalid"
        case .pairingCodeNotFound:
            return "No pending pairing request found"
        case .replyFailed(let reason):
            return "Failed to send reply: \(reason)"
        case .notInitialized:
            return "Channel is not initialized"
        }
    }
}
