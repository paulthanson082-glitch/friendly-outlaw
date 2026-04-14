import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Service for performing computer use tasks via the Anthropic API
public class ComputerUseService {
    private let aiService: AIService
    private let executor: ComputerUseExecutor

    public init(aiService: AIService, executor: ComputerUseExecutor) {
        self.aiService = aiService
        self.executor = executor
    }

    // MARK: - Session Execution

    /// Run a computer use session to complete the given task
    public func run(
        task: String,
        configuration: ComputerUseConfiguration = ComputerUseConfiguration()
    ) async throws -> ComputerUseSessionResult {
        var actions: [ComputerUseAction] = []
        var iterationCount = 0
        var finalResponse = ""
        var wasExhausted = false

        while iterationCount < configuration.maxIterations {
            iterationCount += 1

            let screenshot = try await executor.takeScreenshot()
            let nextAction = try await requestNextAction(
                task: task,
                screenshot: screenshot,
                previousActions: actions,
                configuration: configuration
            )

            if let action = nextAction.action {
                let result = try await executor.execute(action: action)
                actions.append(action)
                if result.error != nil {
                    finalResponse = result.error ?? ""
                    break
                }
                if nextAction.isDone {
                    finalResponse = nextAction.response ?? ""
                    break
                }
            } else {
                finalResponse = nextAction.response ?? ""
                break
            }
        }

        wasExhausted = iterationCount >= configuration.maxIterations && finalResponse.isEmpty

        return ComputerUseSessionResult(
            task: task,
            finalResponse: finalResponse,
            actions: actions,
            iterationCount: iterationCount,
            wasExhausted: wasExhausted
        )
    }

    // MARK: - Private Helpers

    private struct ActionResponse {
        let action: ComputerUseAction?
        let response: String?
        let isDone: Bool
    }

    private func requestNextAction(
        task: String,
        screenshot: String,
        previousActions: [ComputerUseAction],
        configuration: ComputerUseConfiguration
    ) async throws -> ActionResponse {
        // Build the prompt for the AI
        let history = previousActions.map { $0.action.rawValue }.joined(separator: ", ")
        let prompt = """
        Task: \(task)
        Display: \(configuration.displayWidth)x\(configuration.displayHeight)
        Previous actions: \(history.isEmpty ? "none" : history)

        Analyze the current screenshot and determine the next action to complete the task.
        Reply with "DONE" if the task is finished, or describe the next action to take.
        """

        // Send screenshot as vision content using the Anthropic API vision capabilities
        let response = try await aiService.getAssistanceWithVision(
            text: prompt,
            imageBase64: screenshot,
            mediaType: "image/png"
        )

        if response.uppercased().contains("DONE") {
            return ActionResponse(action: nil, response: response, isDone: true)
        }
        // Mark as done when we cannot parse a concrete action to avoid infinite screenshot loops
        return ActionResponse(action: nil, response: response, isDone: true)
    }
}
