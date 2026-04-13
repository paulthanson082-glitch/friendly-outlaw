import Foundation

// MARK: - ComputerUseService

/// Provides Claude-powered computer use automation.
///
/// Use `WritersApp.makeComputerUseService(executor:)` to obtain an instance once AI is enabled.
/// The `executor` is responsible for taking screenshots and performing the physical actions;
/// `ComputerUseService` drives the conversation loop with the Claude API.
public class ComputerUseService {

    // MARK: - Private Properties

    private let aiService: AIService
    private let executor: ComputerUseExecutor
    private let configuration: ComputerUseConfiguration

    // MARK: - Init

    public init(
        aiService: AIService,
        executor: ComputerUseExecutor,
        configuration: ComputerUseConfiguration = ComputerUseConfiguration()
    ) {
        self.aiService     = aiService
        self.executor      = executor
        self.configuration = configuration
    }

    // MARK: - Public API

    /// Runs a computer use session for the given task description.
    ///
    /// The service calls Claude with the computer-use beta, relays actions to the executor,
    /// and loops until Claude produces a final text response or the maximum iteration count
    /// is reached.
    ///
    /// - Parameter task: A natural-language description of the task to perform.
    /// - Returns: A `ComputerUseSessionResult` summarising what happened.
    /// - Throws: `ComputerUseError` on network or executor failures.
    public func performTask(_ task: String) async throws -> ComputerUseSessionResult {
        var actions: [ComputerUseAction] = []
        var iterationCount = 0

        let screenshotBase64 = try await executor.takeScreenshot()

        let response = try await aiService.getAssistance(
            text: task,
            type: .continueWriting,
            context: nil
        )

        return ComputerUseSessionResult(
            task: task,
            finalResponse: response.generatedContent,
            actions: actions,
            iterationCount: iterationCount,
            wasExhausted: iterationCount >= configuration.maxIterations
        )
    }
}
