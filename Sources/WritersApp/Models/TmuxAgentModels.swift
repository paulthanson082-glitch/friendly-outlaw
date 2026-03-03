import Foundation

// MARK: - Agent Message

/// Represents a message sent between Claude agents via tmux panes
public struct AgentMessage: Codable, Identifiable {
    public let id: UUID
    public let fromAgentId: String
    public let toAgentId: String
    public let content: String
    public let timestamp: Date
    public let metadata: [String: String]?

    public init(
        id: UUID = UUID(),
        fromAgentId: String,
        toAgentId: String,
        content: String,
        timestamp: Date = Date(),
        metadata: [String: String]? = nil
    ) {
        self.id = id
        self.fromAgentId = fromAgentId
        self.toAgentId = toAgentId
        self.content = content
        self.timestamp = timestamp
        self.metadata = metadata
    }
}

// MARK: - Agent Session

/// Represents an active agent connection via tmux pane
public struct AgentSession: Codable, Identifiable {
    public let id: UUID
    public let agentId: String
    public let paneTarget: String  // Format: "window:pane" or index
    public let status: AgentSessionStatus
    public let createdAt: Date
    public var lastActivity: Date
    public var messageCount: Int

    public init(
        id: UUID = UUID(),
        agentId: String,
        paneTarget: String,
        status: AgentSessionStatus = .active,
        createdAt: Date = Date(),
        lastActivity: Date = Date(),
        messageCount: Int = 0
    ) {
        self.id = id
        self.agentId = agentId
        self.paneTarget = paneTarget
        self.status = status
        self.createdAt = createdAt
        self.lastActivity = lastActivity
        self.messageCount = messageCount
    }
}

/// Status of an agent session
public enum AgentSessionStatus: String, Codable {
    case active
    case idle
    case disconnected
    case error
}

// MARK: - Agent Response

/// Represents the response to an agent message
public struct AgentResponse: Codable, Identifiable {
    public let id: UUID
    public let messageId: UUID  // References AgentMessage.id
    public let status: ResponseStatus
    public let content: String?
    public let error: String?
    public let timestamp: Date
    public let processingTimeMs: Int?

    public init(
        id: UUID = UUID(),
        messageId: UUID,
        status: ResponseStatus,
        content: String? = nil,
        error: String? = nil,
        timestamp: Date = Date(),
        processingTimeMs: Int? = nil
    ) {
        self.id = id
        self.messageId = messageId
        self.status = status
        self.content = content
        self.error = error
        self.timestamp = timestamp
        self.processingTimeMs = processingTimeMs
    }
}

/// Status of a response
public enum ResponseStatus: String, Codable {
    case pending
    case received
    case processed
    case error
    case timeout
}

// MARK: - Tmux Configuration

/// Configuration for tmux agent communication
public struct TmuxConfiguration: Codable {
    public let sessionName: String
    public let windowIndex: Int
    public let readTimeoutSeconds: Int
    public let writeRetries: Int
    public let keystrokeDelay: Int  // milliseconds

    public init(
        sessionName: String = "claude",
        windowIndex: Int = 0,
        readTimeoutSeconds: Int = 30,
        writeRetries: Int = 3,
        keystrokeDelay: Int = 50
    ) {
        self.sessionName = sessionName
        self.windowIndex = windowIndex
        self.readTimeoutSeconds = readTimeoutSeconds
        self.writeRetries = writeRetries
        self.keystrokeDelay = keystrokeDelay
    }
}

// MARK: - Errors

/// Errors related to tmux agent communication
public enum TmuxAgentError: Error, LocalizedError {
    case tmuxNotAvailable
    case invalidPaneFormat(String)
    case paneNotFound(String)
    case sendKeysFailed(String)
    case captureOutputFailed(String)
    case responseTimeout(String)
    case invalidMessageFormat
    case serializationFailed(String)
    case notInitialized

    public var errorDescription: String? {
        switch self {
        case .tmuxNotAvailable:
            return "tmux is not available on this system"
        case .invalidPaneFormat(let format):
            return "Invalid pane format: '\(format)'. Expected 'window:pane' or numeric index"
        case .paneNotFound(let pane):
            return "Pane not found: \(pane)"
        case .sendKeysFailed(let reason):
            return "Failed to send keys: \(reason)"
        case .captureOutputFailed(let reason):
            return "Failed to capture pane output: \(reason)"
        case .responseTimeout(let message):
            return "Response timeout: \(message)"
        case .invalidMessageFormat:
            return "Invalid message format"
        case .serializationFailed(let reason):
            return "Serialization failed: \(reason)"
        case .notInitialized:
            return "Tmux agent service not initialized"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .tmuxNotAvailable:
            return "Ensure tmux is installed and available in PATH"
        case .invalidPaneFormat:
            return "Use format 'window:pane' (e.g., '0:0') or a numeric pane index"
        case .paneNotFound:
            return "Verify the pane exists in your tmux session"
        case .sendKeysFailed:
            return "Check if the pane is accessible and try again"
        case .responseTimeout:
            return "Increase the timeout value or check if the agent is responding"
        default:
            return nil
        }
    }
}
