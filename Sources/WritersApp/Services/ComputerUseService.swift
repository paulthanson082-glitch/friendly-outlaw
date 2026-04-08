import Foundation

/// Service for managing computer use sessions with Claude AI.
public class ComputerUseService {
    private let aiService: AIService
    private let executor: ComputerUseExecutor
    private let configuration: ComputerUseConfiguration

    /// Initialize a ComputerUseService.
    /// - Parameters:
    ///   - aiService: The AI service to use for generating actions.
    ///   - executor: The executor to perform actions.
    ///   - configuration: The configuration for computer use sessions (defaults to standard settings).
    public init(
        aiService: AIService,
        executor: ComputerUseExecutor,
        configuration: ComputerUseConfiguration = ComputerUseConfiguration()
    ) {
        self.aiService = aiService
        self.executor = executor
        self.configuration = configuration
    }

    /// Run a computer use session for a given task.
    /// - Parameters:
    ///   - task: The task description for Claude to accomplish.
    ///   - initialScreenshot: An optional initial screenshot (base64) to provide context.
    /// - Returns: A ComputerUseSessionResult containing the executed actions and final response.
    public func runSession(
        task: String,
        initialScreenshot: String? = nil
    ) async throws -> ComputerUseSessionResult {
        var actions: [ComputerUseAction] = []
        var messages: [[String: Any]] = []

        // Initialize with task message
        var systemPrompt = "You are a computer use assistant. You can take screenshots and perform actions on the computer."
        systemPrompt += "\nDisplay resolution: \(configuration.displayWidth)x\(configuration.displayHeight)"
        systemPrompt += "\nMax iterations: \(configuration.maxIterations)"

        // Build initial user message
        var userContent: [[String: Any]] = [
            [
                "type": "text",
                "text": task
            ]
        ]

        // Add initial screenshot if provided
        if let screenshot = initialScreenshot {
            userContent.append([
                "type": "image",
                "source": [
                    "type": "base64",
                    "media_type": "image/png",
                    "data": screenshot
                ]
            ])
        } else {
            // Take initial screenshot
            let screenshot = try await executor.takeScreenshot()
            userContent.append([
                "type": "image",
                "source": [
                    "type": "base64",
                    "media_type": "image/png",
                    "data": screenshot
                ]
            ])
        }

        messages.append([
            "role": "user",
            "content": userContent
        ])

        var iterationCount = 0
        var wasExhausted = false
        var finalResponse = ""

        // Main loop for computer use
        while iterationCount < configuration.maxIterations {
            iterationCount += 1

            // Call Claude to decide what action to take next
            // For now, we'll just break after taking initial screenshot
            // In a full implementation, this would call Claude and parse the response
            break
        }

        if iterationCount >= configuration.maxIterations {
            wasExhausted = true
        }

        return ComputerUseSessionResult(
            task: task,
            finalResponse: finalResponse,
            actions: actions,
            iterationCount: iterationCount,
            wasExhausted: wasExhausted
        )
    }
}
