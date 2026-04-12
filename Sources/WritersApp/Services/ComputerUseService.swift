import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// MARK: - Computer Use Executor Protocol

/// Protocol for executing computer use actions (screenshot, click, type, etc.)
public protocol ComputerUseExecutor {
    /// Take a screenshot of the current screen, returning a base64-encoded PNG string
    func takeScreenshot() async throws -> String

    /// Execute a computer use action and return its result
    func execute(action: ComputerUseAction) async throws -> ComputerUseResult
}

// MARK: - Computer Use Service

/// Service for AI-powered computer use sessions using Claude's computer use capability.
///
/// `ComputerUseService` drives an iterative loop: it sends the task to Claude along with
/// computer use tool definitions, then calls the provided `ComputerUseExecutor` for any
/// tool requests Claude returns (screenshot, click, type, etc.) and feeds the results
/// back until Claude returns a final text response or iterations are exhausted.
public class ComputerUseService {

    // MARK: - Private Properties

    private let apiKey: String
    private let model: String
    private let executor: ComputerUseExecutor
    private let configuration: ComputerUseConfiguration
    private let apiURL = "https://api.anthropic.com/v1/messages"

    // MARK: - Initialization

    public init(
        apiKey: String,
        model: String,
        executor: ComputerUseExecutor,
        configuration: ComputerUseConfiguration = ComputerUseConfiguration()
    ) {
        self.apiKey = apiKey
        self.model = model
        self.executor = executor
        self.configuration = configuration
    }

    // MARK: - Session Execution

    /// Run a computer use task and return the aggregate session result.
    ///
    /// - Parameters:
    ///   - task: Natural-language description of what to do on screen
    ///   - systemPrompt: Optional system prompt injected before the task
    /// - Returns: A `ComputerUseSessionResult` describing what happened
    public func run(
        task: String,
        systemPrompt: String? = nil
    ) async throws -> ComputerUseSessionResult {
        guard let url = URL(string: apiURL) else {
            throw ComputerUseError.invalidRequest
        }

        var messages: [[String: Any]] = [["role": "user", "content": task]]
        var performedActions: [ComputerUseAction] = []
        var finalResponse = ""
        var exhausted = false
        var iterationCount = 0

        for iteration in 0..<configuration.maxIterations {
            iterationCount = iteration + 1
            let requestBody = buildRequestBody(messages: messages, systemPrompt: systemPrompt)
            let request = try buildURLRequest(url: url, body: requestBody)
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw ComputerUseError.invalidResponse
            }
            guard httpResponse.statusCode == 200 else {
                throw ComputerUseError.apiError("HTTP \(httpResponse.statusCode)")
            }

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let content = json["content"] as? [[String: Any]] else {
                throw ComputerUseError.invalidResponse
            }

            // Collect text blocks and tool-use blocks
            var toolUseBlocks: [[String: Any]] = []
            for block in content {
                if let type = block["type"] as? String {
                    if type == "text", let text = block["text"] as? String {
                        finalResponse = text
                    } else if type == "tool_use" {
                        toolUseBlocks.append(block)
                    }
                }
            }

            // If no tool calls, Claude is done
            if toolUseBlocks.isEmpty {
                break
            }

            // Append assistant message
            messages.append(["role": "assistant", "content": content])

            // Execute each tool call and collect results
            var toolResults: [[String: Any]] = []
            for toolBlock in toolUseBlocks {
                guard let toolId = toolBlock["id"] as? String,
                      let inputDict = toolBlock["input"] as? [String: Any],
                      let actionRaw = inputDict["action"] as? String,
                      let actionType = ComputerUseActionType(rawValue: actionRaw) else {
                    continue
                }

                let action = ComputerUseAction(
                    action: actionType,
                    coordinate: inputDict["coordinate"] as? [Int],
                    startCoordinate: inputDict["start_coordinate"] as? [Int],
                    text: inputDict["text"] as? String,
                    key: inputDict["key"] as? String,
                    direction: inputDict["direction"] as? String,
                    amount: inputDict["amount"] as? Int,
                    duration: inputDict["duration"] as? Int
                )
                performedActions.append(action)

                do {
                    let result = try await executor.execute(action: action)
                    var resultContent: [String: Any] = ["type": "tool_result", "tool_use_id": toolId]
                    if let screenshot = result.screenshotBase64 {
                        resultContent["content"] = [
                            ["type": "image", "source": ["type": "base64", "media_type": "image/png", "data": screenshot]]
                        ]
                    } else if let error = result.error {
                        resultContent["content"] = error
                        resultContent["is_error"] = true
                    }
                    toolResults.append(resultContent)
                } catch {
                    toolResults.append([
                        "type": "tool_result",
                        "tool_use_id": toolId,
                        "content": error.localizedDescription,
                        "is_error": true
                    ])
                }
            }

            messages.append(["role": "user", "content": toolResults])

            if iteration == configuration.maxIterations - 1 {
                exhausted = true
            }
        }

        return ComputerUseSessionResult(
            task: task,
            finalResponse: finalResponse,
            actions: performedActions,
            iterationCount: iterationCount,
            wasExhausted: exhausted
        )
    }

    // MARK: - Private Helpers

    private func buildRequestBody(messages: [[String: Any]], systemPrompt: String?) -> [String: Any] {
        var body: [String: Any] = [
            "model": model,
            "max_tokens": 4096,
            "tools": computerUseToolDefinitions(),
            "messages": messages
        ]
        if let system = systemPrompt, !system.isEmpty {
            body["system"] = system
        }
        return body
    }

    private func buildURLRequest(url: URL, body: [String: Any]) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue("computer-use-2024-10-22", forHTTPHeaderField: "anthropic-beta")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    private func computerUseToolDefinitions() -> [[String: Any]] {
        return [
            [
                "type": "computer_20241022",
                "name": "computer",
                "display_width_px": configuration.displayWidth,
                "display_height_px": configuration.displayHeight
            ]
        ]
    }
}
