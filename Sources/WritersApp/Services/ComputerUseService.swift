import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// MARK: - Computer Use Executor Protocol

/// Implement this protocol to handle computer use actions in your environment
public protocol ComputerUseExecutor {
    /// Take a screenshot and return it as base64-encoded PNG data
    func takeScreenshot() async throws -> String
    /// Execute a computer use action and return a screenshot of the result
    func execute(action: ComputerUseAction) async throws -> ComputerUseResult
}

// MARK: - Computer Use Service

/// Drives a Claude computer use session, letting Claude control a virtual desktop
/// to accomplish a task described in natural language.
public class ComputerUseService {

    private let aiService: AIService
    private let executor: ComputerUseExecutor
    private let configuration: ComputerUseConfiguration

    public init(aiService: AIService, executor: ComputerUseExecutor,
                configuration: ComputerUseConfiguration = ComputerUseConfiguration()) {
        self.aiService = aiService
        self.executor = executor
        self.configuration = configuration
    }

    // MARK: - Public API

    /// Run a computer use session to accomplish the given task.
    /// Claude will take screenshots and perform actions until the task is done
    /// or `maxIterations` is reached.
    public func runTask(_ task: String) async throws -> ComputerUseSessionResult {
        var messages: [[String: Any]] = []
        var actions: [ComputerUseAction] = []
        var iterationCount = 0

        // Initial screenshot so Claude can see the current state
        let initialScreenshot = try await executor.takeScreenshot()

        // Build initial user message with screenshot
        let initialContent: [[String: Any]] = [
            ["type": "text", "text": task],
            [
                "type": "image",
                "source": [
                    "type": "base64",
                    "media_type": "image/png",
                    "data": initialScreenshot
                ]
            ]
        ]
        messages.append(["role": "user", "content": initialContent])

        // Tool definition for computer use
        let computerTool: [String: Any] = [
            "type": "computer_20241022",
            "name": "computer",
            "display_width_px": configuration.displayWidth,
            "display_height_px": configuration.displayHeight,
            "display_number": 1
        ]

        var finalResponse = ""

        // Agentic loop
        while iterationCount < configuration.maxIterations {
            iterationCount += 1

            let requestBody: [String: Any] = [
                "model": aiService.currentModel,
                "max_tokens": 4096,
                "tools": [computerTool],
                "messages": messages
            ]

            guard let requestData = try? JSONSerialization.data(withJSONObject: requestBody) else {
                throw ComputerUseError.invalidRequest
            }

            var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(aiService.apiKey, forHTTPHeaderField: "x-api-key")
            request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
            request.setValue("computer-use-2024-10-22", forHTTPHeaderField: "anthropic-beta")
            request.httpBody = requestData

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw ComputerUseError.apiError("HTTP \((response as? HTTPURLResponse)?.statusCode ?? 0)")
            }

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let contentBlocks = json["content"] as? [[String: Any]] else {
                throw ComputerUseError.invalidResponse
            }

            let stopReason = json["stop_reason"] as? String ?? ""

            // Collect assistant message
            messages.append(["role": "assistant", "content": contentBlocks])

            // Check for text response
            for block in contentBlocks {
                if let blockType = block["type"] as? String, blockType == "text",
                   let text = block["text"] as? String {
                    finalResponse = text
                }
            }

            // If no tool use, we're done
            guard stopReason == "tool_use" else { break }

            // Process tool use blocks
            var toolResults: [[String: Any]] = []

            for block in contentBlocks {
                guard let blockType = block["type"] as? String,
                      blockType == "tool_use",
                      let toolName = block["name"] as? String,
                      toolName == "computer",
                      let toolUseId = block["id"] as? String,
                      let input = block["input"] as? [String: Any] else { continue }

                let action = parseAction(from: input)
                actions.append(action)

                let result = try await executor.execute(action: action)

                var resultContent: [[String: Any]] = []

                if let screenshot = result.screenshotBase64 {
                    resultContent.append([
                        "type": "image",
                        "source": [
                            "type": "base64",
                            "media_type": "image/png",
                            "data": screenshot
                        ]
                    ])
                }

                if let error = result.error {
                    resultContent.append(["type": "text", "text": "Error: \(error)"])
                } else if result.screenshotBase64 == nil {
                    resultContent.append(["type": "text", "text": "Action completed."])
                }

                toolResults.append([
                    "type": "tool_result",
                    "tool_use_id": toolUseId,
                    "content": resultContent
                ])
            }

            if !toolResults.isEmpty {
                messages.append(["role": "user", "content": toolResults])
            }
        }

        let exhausted = iterationCount >= configuration.maxIterations
        return ComputerUseSessionResult(
            task: task,
            finalResponse: finalResponse,
            actions: actions,
            iterationCount: iterationCount,
            wasExhausted: exhausted
        )
    }

    // MARK: - Private Helpers

    private func parseAction(from input: [String: Any]) -> ComputerUseAction {
        let actionString = input["action"] as? String ?? "screenshot"
        let actionType = ComputerUseActionType(rawValue: actionString) ?? .screenshot
        let coordinate = input["coordinate"] as? [Int]
        let startCoordinate = input["start_coordinate"] as? [Int]
        let text = input["text"] as? String
        let key = input["key"] as? String
        let direction = input["direction"] as? String
        let amount = input["amount"] as? Int
        let duration = input["duration"] as? Int

        return ComputerUseAction(
            action: actionType,
            coordinate: coordinate,
            startCoordinate: startCoordinate,
            text: text,
            key: key,
            direction: direction,
            amount: amount,
            duration: duration
        )
    }
}

// MARK: - Result & Errors

/// Summary of a completed computer use session
public struct ComputerUseSessionResult {
    public let task: String
    public let finalResponse: String
    public let actions: [ComputerUseAction]
    public let iterationCount: Int
    public let wasExhausted: Bool

    /// Human-readable summary
    public var summary: String {
        let status = wasExhausted ? "exhausted after \(iterationCount) iterations" : "completed in \(iterationCount) iterations"
        return "Task '\(task)' \(status) with \(actions.count) actions. Response: \(finalResponse)"
    }
}

public enum ComputerUseError: Error, LocalizedError {
    case invalidRequest
    case invalidResponse
    case apiError(String)
    case executorError(String)

    public var errorDescription: String? {
        switch self {
        case .invalidRequest: return "Failed to build computer use request"
        case .invalidResponse: return "Invalid response from Claude API"
        case .apiError(let msg): return "API error: \(msg)"
        case .executorError(let msg): return "Executor error: \(msg)"
        }
    }
}
