import Foundation

// MARK: - ComputerUseActionType

/// Enum representing the types of actions that can be performed in a computer use session.
/// Raw values match the Anthropic Computer Use API action names.
public enum ComputerUseActionType: String, Codable {
    case screenshot
    case leftClick = "left_click"
    case rightClick = "right_click"
    case doubleClick = "double_click"
    case middleClick = "middle_click"
    case leftClickDrag = "left_click_drag"
    case mouseMoveAction = "mouse_move"
    case keypress
    case type
    case scroll
    case wait
    case cursorPosition = "cursor_position"
}

// MARK: - ComputerUseAction

/// Represents a single action to be performed in a computer use session.
/// Optional fields are only used by specific action types.
public struct ComputerUseAction: Identifiable, Codable {
    public let id: UUID
    public let action: ComputerUseActionType
    public let coordinate: [Int]?
    public let startCoordinate: [Int]?
    public let text: String?
    public let key: String?
    public let direction: String?
    public let amount: Int?
    public let duration: Int?

    public init(
        id: UUID = UUID(),
        action: ComputerUseActionType,
        coordinate: [Int]? = nil,
        startCoordinate: [Int]? = nil,
        text: String? = nil,
        key: String? = nil,
        direction: String? = nil,
        amount: Int? = nil,
        duration: Int? = nil
    ) {
        self.id = id
        self.action = action
        self.coordinate = coordinate
        self.startCoordinate = startCoordinate
        self.text = text
        self.key = key
        self.direction = direction
        self.amount = amount
        self.duration = duration
    }
}

// MARK: - ComputerUseConfiguration

/// Configuration for a computer use session.
public struct ComputerUseConfiguration: Codable {
    public let displayWidth: Int
    public let displayHeight: Int
    public let maxIterations: Int
    public let screenshotDelay: Double

    public init(
        displayWidth: Int = 1024,
        displayHeight: Int = 768,
        maxIterations: Int = 20,
        screenshotDelay: Double = 0.5
    ) {
        self.displayWidth = displayWidth
        self.displayHeight = displayHeight
        self.maxIterations = maxIterations
        self.screenshotDelay = screenshotDelay
    }
}

// MARK: - ComputerUseSessionResult

/// Result of a complete computer use session.
public struct ComputerUseSessionResult: Identifiable, Codable {
    public let id: UUID
    public let task: String
    public let finalResponse: String
    public let actions: [ComputerUseAction]
    public let iterationCount: Int
    public let wasExhausted: Bool

    public var summary: String {
        let actionCount = actions.count
        let actionWord = actionCount == 1 ? "action" : "actions"
        let exhaustedNote = wasExhausted ? " (exhausted after \(iterationCount) iterations)" : ""
        return "Task: \(task) — completed with \(actionCount) \(actionWord)\(exhaustedNote)"
    }

    public init(
        id: UUID = UUID(),
        task: String,
        finalResponse: String,
        actions: [ComputerUseAction],
        iterationCount: Int,
        wasExhausted: Bool
    ) {
        self.id = id
        self.task = task
        self.finalResponse = finalResponse
        self.actions = actions
        self.iterationCount = iterationCount
        self.wasExhausted = wasExhausted
    }
}

// MARK: - ComputerUseResult

/// Result of executing a single computer use action.
public struct ComputerUseResult: Codable {
    public let action: ComputerUseAction
    public let screenshotBase64: String?
    public let error: String?

    public init(
        action: ComputerUseAction,
        screenshotBase64: String? = nil,
        error: String? = nil
    ) {
        self.action = action
        self.screenshotBase64 = screenshotBase64
        self.error = error
    }
}

// MARK: - ComputerUseError

/// Error types that can occur during computer use operations.
public enum ComputerUseError: Error, Codable {
    case invalidRequest
    case invalidResponse
    case apiError(String)
    case executorError(String)

    public var errorDescription: String? {
        switch self {
        case .invalidRequest:
            return "Invalid computer use request"
        case .invalidResponse:
            return "Invalid response from computer use API"
        case .apiError(let message):
            return "Computer use API error: \(message)"
        case .executorError(let message):
            return "Executor error: \(message)"
        }
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case type, message
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "invalidRequest":
            self = .invalidRequest
        case "invalidResponse":
            self = .invalidResponse
        case "apiError":
            let message = try container.decode(String.self, forKey: .message)
            self = .apiError(message)
        case "executorError":
            let message = try container.decode(String.self, forKey: .message)
            self = .executorError(message)
        default:
            self = .invalidRequest
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .invalidRequest:
            try container.encode("invalidRequest", forKey: .type)
        case .invalidResponse:
            try container.encode("invalidResponse", forKey: .type)
        case .apiError(let message):
            try container.encode("apiError", forKey: .type)
            try container.encode(message, forKey: .message)
        case .executorError(let message):
            try container.encode("executorError", forKey: .type)
            try container.encode(message, forKey: .message)
        }
    }
}

// MARK: - ComputerUseExecutor

/// Protocol for executing computer use actions.
public protocol ComputerUseExecutor {
    /// Take a screenshot of the current display and return it as base64-encoded PNG data.
    func takeScreenshot() async throws -> String

    /// Execute the given computer use action and return the result.
    func execute(action: ComputerUseAction) async throws -> ComputerUseResult
}
