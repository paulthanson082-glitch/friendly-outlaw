import Foundation

// MARK: - Computer Use Action Types

/// The type of computer use action to perform
public enum ComputerUseActionType: String, Codable, CaseIterable {
    case screenshot = "screenshot"
    case leftClick = "left_click"
    case rightClick = "right_click"
    case doubleClick = "double_click"
    case middleClick = "middle_click"
    case leftClickDrag = "left_click_drag"
    case mouseMoveAction = "mouse_move"
    case keypress = "keypress"
    case type = "type"
    case scroll = "scroll"
    case wait = "wait"
    case cursorPosition = "cursor_position"
}

// MARK: - Computer Use Action

/// A single computer use action sent to or received from the Claude computer use API
public struct ComputerUseAction: Codable {
    public let action: ComputerUseActionType
    public let coordinate: [Int]?
    public let startCoordinate: [Int]?
    public let text: String?
    public let key: String?
    public let direction: String?
    public let amount: Int?
    public let duration: Int?

    public init(
        action: ComputerUseActionType,
        coordinate: [Int]? = nil,
        startCoordinate: [Int]? = nil,
        text: String? = nil,
        key: String? = nil,
        direction: String? = nil,
        amount: Int? = nil,
        duration: Int? = nil
    ) {
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

// MARK: - Computer Use Result

/// The result of executing a single computer use action
public struct ComputerUseResult {
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

// MARK: - Computer Use Session Result

/// The aggregate result of a complete computer use session
public struct ComputerUseSessionResult {
    public let task: String
    public let finalResponse: String
    public let actions: [ComputerUseAction]
    public let iterationCount: Int
    public let wasExhausted: Bool

    public init(
        task: String,
        finalResponse: String,
        actions: [ComputerUseAction],
        iterationCount: Int,
        wasExhausted: Bool
    ) {
        self.task = task
        self.finalResponse = finalResponse
        self.actions = actions
        self.iterationCount = iterationCount
        self.wasExhausted = wasExhausted
    }

    /// A human-readable summary of the session result
    public var summary: String {
        let actionCount = actions.count
        let plural = actionCount == 1 ? "action" : "actions"
        if wasExhausted {
            return "Task '\(task)' exhausted after \(iterationCount) iterations with \(actionCount) \(plural)."
        } else {
            return "Task '\(task)' completed in \(iterationCount) iterations with \(actionCount) \(plural)."
        }
    }
}

// MARK: - Computer Use Configuration

/// Configuration for the computer use session
public struct ComputerUseConfiguration {
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

// MARK: - Computer Use Error

/// Errors that can occur during computer use sessions
public enum ComputerUseError: LocalizedError {
    case invalidRequest
    case invalidResponse
    case apiError(String)
    case executorError(String)

    public var errorDescription: String? {
        switch self {
        case .invalidRequest:
            return "Failed to build computer use request"
        case .invalidResponse:
            return "Invalid response from Claude API"
        case .apiError(let detail):
            return "API error: \(detail)"
        case .executorError(let detail):
            return "Executor error: \(detail)"
        }
    }
}
