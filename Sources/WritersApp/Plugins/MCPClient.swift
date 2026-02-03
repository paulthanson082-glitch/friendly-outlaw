import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// MARK: - MCP Client

/// Client for communicating with MCP (Model Context Protocol) servers
public class MCPClient {
    private let serverConfig: MCPServerConfig
    private var process: Process?
    private var inputPipe: Pipe?
    private var outputPipe: Pipe?
    private var isConnected: Bool = false
    private var requestId: Int = 0
    private var pendingRequests: [Int: CheckedContinuation<MCPResponse, Error>] = [:]
    private let queue = DispatchQueue(label: "com.writersapp.mcp.client")

    public init(serverConfig: MCPServerConfig) {
        self.serverConfig = serverConfig
    }

    // MARK: - Connection Management

    /// Connect to the MCP server
    public func connect() async throws {
        switch serverConfig.transport {
        case "stdio":
            try await connectStdio()
        case "http", "websocket":
            try await connectHTTP()
        default:
            throw MCPError.unsupportedTransport(serverConfig.transport)
        }

        // Initialize the connection
        let initResult = try await initialize()
        guard initResult.success else {
            throw MCPError.initializationFailed(initResult.error?.message ?? "Unknown error")
        }

        isConnected = true
    }

    /// Disconnect from the MCP server
    public func disconnect() async {
        isConnected = false

        if let process = process {
            process.terminate()
            self.process = nil
        }

        inputPipe = nil
        outputPipe = nil
    }

    private func connectStdio() async throws {
        guard let command = serverConfig.command else {
            throw MCPError.invalidConfiguration("Command is required for stdio transport")
        }

        process = Process()
        process?.executableURL = URL(fileURLWithPath: command)
        process?.arguments = serverConfig.args ?? []

        // Set environment variables
        var environment = ProcessInfo.processInfo.environment
        if let env = serverConfig.env {
            for (key, value) in env {
                environment[key] = value
            }
        }
        process?.environment = environment

        inputPipe = Pipe()
        outputPipe = Pipe()
        process?.standardInput = inputPipe
        process?.standardOutput = outputPipe

        // Handle output
        outputPipe?.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            self?.handleOutput(data)
        }

        try process?.run()
    }

    private func connectHTTP() async throws {
        // HTTP transport is simpler - just verify the URL
        guard serverConfig.url != nil else {
            throw MCPError.invalidConfiguration("URL is required for HTTP transport")
        }
        // Connection will be established per-request
    }

    // MARK: - MCP Protocol Methods

    /// Initialize the MCP connection
    private func initialize() async throws -> MCPResponse {
        let request = MCPRequest(
            method: "initialize",
            params: [
                "protocolVersion": "2024-11-05",
                "capabilities": [
                    "tools": [:],
                    "resources": [:],
                    "prompts": [:]
                ],
                "clientInfo": [
                    "name": "WritersApp",
                    "version": "1.0.0"
                ]
            ]
        )

        return try await sendRequest(request)
    }

    /// List available tools from the MCP server
    public func listTools() async throws -> [MCPTool] {
        let response = try await sendRequest(MCPRequest(method: "tools/list"))

        guard let tools = response.result?["tools"] as? [[String: Any]] else {
            return []
        }

        return tools.compactMap { MCPTool(from: $0) }
    }

    /// Call a tool on the MCP server
    public func callTool(name: String, arguments: [String: Any]) async throws -> MCPToolResult {
        let request = MCPRequest(
            method: "tools/call",
            params: [
                "name": name,
                "arguments": arguments
            ]
        )

        let response = try await sendRequest(request)

        guard let content = response.result?["content"] as? [[String: Any]] else {
            throw MCPError.invalidResponse("Missing content in tool result")
        }

        return MCPToolResult(content: content, isError: response.error != nil)
    }

    /// List available resources from the MCP server
    public func listResources() async throws -> [MCPResource] {
        let response = try await sendRequest(MCPRequest(method: "resources/list"))

        guard let resources = response.result?["resources"] as? [[String: Any]] else {
            return []
        }

        return resources.compactMap { MCPResource(from: $0) }
    }

    /// Read a resource from the MCP server
    public func readResource(uri: String) async throws -> MCPResourceContent {
        let request = MCPRequest(
            method: "resources/read",
            params: ["uri": uri]
        )

        let response = try await sendRequest(request)

        guard let contents = response.result?["contents"] as? [[String: Any]],
              let first = contents.first else {
            throw MCPError.invalidResponse("Missing contents in resource read result")
        }

        return MCPResourceContent(from: first)
    }

    /// List available prompts from the MCP server
    public func listPrompts() async throws -> [MCPPrompt] {
        let response = try await sendRequest(MCPRequest(method: "prompts/list"))

        guard let prompts = response.result?["prompts"] as? [[String: Any]] else {
            return []
        }

        return prompts.compactMap { MCPPrompt(from: $0) }
    }

    /// Get a prompt from the MCP server
    public func getPrompt(name: String, arguments: [String: String]? = nil) async throws -> MCPPromptResult {
        var params: [String: Any] = ["name": name]
        if let args = arguments {
            params["arguments"] = args
        }

        let request = MCPRequest(method: "prompts/get", params: params)
        let response = try await sendRequest(request)

        guard let messages = response.result?["messages"] as? [[String: Any]] else {
            throw MCPError.invalidResponse("Missing messages in prompt result")
        }

        return MCPPromptResult(
            description: response.result?["description"] as? String,
            messages: messages.map { MCPPromptMessage(from: $0) }
        )
    }

    // MARK: - Request Handling

    private func sendRequest(_ request: MCPRequest) async throws -> MCPResponse {
        let id = nextRequestId()
        var mutableRequest = request
        mutableRequest.id = id

        switch serverConfig.transport {
        case "stdio":
            return try await sendStdioRequest(mutableRequest)
        case "http":
            return try await sendHTTPRequest(mutableRequest)
        default:
            throw MCPError.unsupportedTransport(serverConfig.transport)
        }
    }

    private func sendStdioRequest(_ request: MCPRequest) async throws -> MCPResponse {
        guard let inputPipe = inputPipe else {
            throw MCPError.notConnected
        }

        let encoder = JSONEncoder()
        let data = try encoder.encode(request)

        // Write request with newline delimiter (JSON-RPC over stdio)
        var requestData = data
        requestData.append(contentsOf: "\n".utf8)

        return try await withCheckedThrowingContinuation { continuation in
            queue.sync {
                pendingRequests[request.id!] = continuation
            }

            inputPipe.fileHandleForWriting.write(requestData)
        }
    }

    private func sendHTTPRequest(_ request: MCPRequest) async throws -> MCPResponse {
        guard let urlString = serverConfig.url,
              let url = URL(string: urlString) else {
            throw MCPError.invalidConfiguration("Invalid URL")
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw MCPError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }

        let decoder = JSONDecoder()
        return try decoder.decode(MCPResponse.self, from: data)
    }

    private func handleOutput(_ data: Data) {
        // Parse JSON-RPC responses (newline-delimited)
        let lines = String(data: data, encoding: .utf8)?.components(separatedBy: "\n") ?? []

        for line in lines {
            guard !line.isEmpty else { continue }

            if let responseData = line.data(using: .utf8),
               let response = try? JSONDecoder().decode(MCPResponse.self, from: responseData),
               let id = response.id {
                queue.sync {
                    if let continuation = pendingRequests.removeValue(forKey: id) {
                        continuation.resume(returning: response)
                    }
                }
            }
        }
    }

    private func nextRequestId() -> Int {
        queue.sync {
            requestId += 1
            return requestId
        }
    }
}

// MARK: - MCP Types

/// MCP JSON-RPC request
public struct MCPRequest: Codable {
    public var jsonrpc: String = "2.0"
    public var id: Int?
    public let method: String
    public var params: [String: Any]?

    public init(method: String, params: [String: Any]? = nil) {
        self.method = method
        self.params = params
    }

    enum CodingKeys: String, CodingKey {
        case jsonrpc, id, method, params
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(jsonrpc, forKey: .jsonrpc)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(method, forKey: .method)

        if let params = params {
            let jsonData = try JSONSerialization.data(withJSONObject: params)
            let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
            try container.encode(AnyCodable(jsonObject), forKey: .params)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        jsonrpc = try container.decode(String.self, forKey: .jsonrpc)
        id = try container.decodeIfPresent(Int.self, forKey: .id)
        method = try container.decode(String.self, forKey: .method)

        if let anyCodable = try container.decodeIfPresent(AnyCodable.self, forKey: .params) {
            params = anyCodable.value as? [String: Any]
        }
    }
}

/// MCP JSON-RPC response
public struct MCPResponse: Codable {
    public let jsonrpc: String
    public let id: Int?
    public var result: [String: Any]?
    public var error: MCPResponseError?

    var success: Bool {
        return error == nil
    }

    enum CodingKeys: String, CodingKey {
        case jsonrpc, id, result, error
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(jsonrpc, forKey: .jsonrpc)
        try container.encodeIfPresent(id, forKey: .id)

        if let result = result {
            let jsonData = try JSONSerialization.data(withJSONObject: result)
            let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
            try container.encode(AnyCodable(jsonObject), forKey: .result)
        }

        try container.encodeIfPresent(error, forKey: .error)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        jsonrpc = try container.decode(String.self, forKey: .jsonrpc)
        id = try container.decodeIfPresent(Int.self, forKey: .id)

        if let anyCodable = try container.decodeIfPresent(AnyCodable.self, forKey: .result) {
            result = anyCodable.value as? [String: Any]
        }

        error = try container.decodeIfPresent(MCPResponseError.self, forKey: .error)
    }
}

/// MCP response error
public struct MCPResponseError: Codable {
    public let code: Int
    public let message: String
    public let data: String?
}

/// MCP tool definition
public struct MCPTool {
    public let name: String
    public let description: String?
    public let inputSchema: [String: Any]?

    init?(from dict: [String: Any]) {
        guard let name = dict["name"] as? String else { return nil }
        self.name = name
        self.description = dict["description"] as? String
        self.inputSchema = dict["inputSchema"] as? [String: Any]
    }
}

/// MCP tool result
public struct MCPToolResult {
    public let content: [[String: Any]]
    public let isError: Bool

    public var textContent: String? {
        for item in content {
            if item["type"] as? String == "text",
               let text = item["text"] as? String {
                return text
            }
        }
        return nil
    }
}

/// MCP resource definition
public struct MCPResource {
    public let uri: String
    public let name: String
    public let description: String?
    public let mimeType: String?

    init?(from dict: [String: Any]) {
        guard let uri = dict["uri"] as? String,
              let name = dict["name"] as? String else { return nil }
        self.uri = uri
        self.name = name
        self.description = dict["description"] as? String
        self.mimeType = dict["mimeType"] as? String
    }
}

/// MCP resource content
public struct MCPResourceContent {
    public let uri: String
    public let mimeType: String?
    public let text: String?
    public let blob: Data?

    init(from dict: [String: Any]) {
        self.uri = dict["uri"] as? String ?? ""
        self.mimeType = dict["mimeType"] as? String
        self.text = dict["text"] as? String
        if let blobString = dict["blob"] as? String {
            self.blob = Data(base64Encoded: blobString)
        } else {
            self.blob = nil
        }
    }
}

/// MCP prompt definition
public struct MCPPrompt {
    public let name: String
    public let description: String?
    public let arguments: [MCPPromptArgument]?

    init?(from dict: [String: Any]) {
        guard let name = dict["name"] as? String else { return nil }
        self.name = name
        self.description = dict["description"] as? String

        if let args = dict["arguments"] as? [[String: Any]] {
            self.arguments = args.map { MCPPromptArgument(from: $0) }
        } else {
            self.arguments = nil
        }
    }
}

/// MCP prompt argument
public struct MCPPromptArgument {
    public let name: String
    public let description: String?
    public let required: Bool

    init(from dict: [String: Any]) {
        self.name = dict["name"] as? String ?? ""
        self.description = dict["description"] as? String
        self.required = dict["required"] as? Bool ?? false
    }
}

/// MCP prompt result
public struct MCPPromptResult {
    public let description: String?
    public let messages: [MCPPromptMessage]
}

/// MCP prompt message
public struct MCPPromptMessage {
    public let role: String
    public let content: Any

    init(from dict: [String: Any]) {
        self.role = dict["role"] as? String ?? "user"
        self.content = dict["content"] ?? ""
    }
}

// MARK: - MCP Errors

public enum MCPError: LocalizedError {
    case notConnected
    case unsupportedTransport(String)
    case invalidConfiguration(String)
    case invalidResponse(String)
    case httpError(Int)
    case initializationFailed(String)
    case toolError(String)

    public var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Not connected to MCP server"
        case .unsupportedTransport(let transport):
            return "Unsupported transport: \(transport)"
        case .invalidConfiguration(let message):
            return "Invalid configuration: \(message)"
        case .invalidResponse(let message):
            return "Invalid response: \(message)"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .initializationFailed(let message):
            return "Initialization failed: \(message)"
        case .toolError(let message):
            return "Tool error: \(message)"
        }
    }
}

// MARK: - AnyCodable Helper

/// Helper for encoding/decoding arbitrary JSON values
struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self.value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let string = try? container.decode(String.self) {
            self.value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            self.value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            self.value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unable to decode value")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Unable to encode value"))
        }
    }
}
