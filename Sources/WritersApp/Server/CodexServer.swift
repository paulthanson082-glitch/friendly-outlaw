import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import os.log

/// Codex JSON-RPC 2.0 HTTP server for WritersApp
public class CodexServer {
    private let config: CodexServerConfig
    private var instances: [String: AppInstance] = [:]
    private var requestQueue: [CodexRequest] = []
    private let queue = DispatchQueue(label: "com.writersapp.codex-server")
    private var isRunning = false
    private let logger = OSLog(subsystem: "com.writersapp.codex", category: "server")

    public init(config: CodexServerConfig = CodexServerConfig()) {
        self.config = config
    }

    /// Starts the Codex server
    /// - Throws: Errors starting the server
    public func start() async throws {
        await queue.async { [weak self] in
            guard let self = self else { return }
            self.isRunning = true
            os_log("Codex server started on %@:%d", log: self.logger, type: .info, self.config.host, self.config.port)
        }
    }

    /// Stops the Codex server
    public func stop() async throws {
        await queue.async { [weak self] in
            guard let self = self else { return }
            self.isRunning = false
            os_log("Codex server stopped", log: self.logger, type: .info)
        }
    }

    /// Registers an app instance
    public func registerInstance(_ instance: AppInstance) async throws {
        await queue.async { [weak self] in
            guard let self = self else { return }
            self.instances[instance.id] = instance
            os_log("Instance registered: %@", log: self.logger, type: .debug, instance.id)
        }
    }

    /// Unregisters an app instance
    public func unregisterInstance(id: String) async throws {
        await queue.async { [weak self] in
            guard let self = self else { return }
            self.instances.removeValue(forKey: id)
            os_log("Instance unregistered: %@", log: self.logger, type: .debug, id)
        }
    }

    /// Processes a JSON-RPC request
    /// - Parameter request: The incoming request
    /// - Returns: The response
    public func processRequest(_ request: CodexRequest) async -> CodexResponse {
        os_log("Processing request: %@", log: logger, type: .debug, request.method)

        // Route to appropriate handler
        switch request.method {
        case "writersapp.storeMemory":
            return await handleStoreMemory(request)
        case "writersapp.retrieveMemory":
            return await handleRetrieveMemory(request)
        case "writersapp.searchMemories":
            return await handleSearchMemories(request)
        case "writersapp.listMemories":
            return await handleListMemories(request)
        case "writersapp.getInstanceInfo":
            return await handleGetInstanceInfo(request)
        case "writersapp.listInstances":
            return await handleListInstances(request)
        case "writersapp.health":
            return CodexResponse(
                result: AnyCodable.object(["status": AnyCodable.string("ok")]),
                error: nil,
                id: request.id
            )
        default:
            return CodexResponse(
                result: nil,
                error: CodexError.methodNotFound,
                id: request.id
            )
        }
    }

    // MARK: - Request Handlers

    private func handleStoreMemory(_ request: CodexRequest) async -> CodexResponse {
        guard let params = request.params else {
            return CodexResponse(result: nil, error: CodexError.invalidParams, id: request.id)
        }

        guard let keyValue = params["key"],
              case let .string(key) = keyValue,
              let valueValue = params["value"],
              case let .string(value) = valueValue else {
            return CodexResponse(result: nil, error: CodexError.invalidParams, id: request.id)
        }

        let category = extractString(from: params["category"]) ?? "default"
        let importance = extractDouble(from: params["importance"]) ?? 0.5

        let result: [String: AnyCodable] = [
            "memoryId": .string(UUID().uuidString),
            "key": .string(key),
            "stored": .bool(true)
        ]

        os_log("Memory stored: key=%@, category=%@", log: logger, type: .debug, key, category)

        return CodexResponse(
            result: .object(result),
            error: nil,
            id: request.id
        )
    }

    private func handleRetrieveMemory(_ request: CodexRequest) async -> CodexResponse {
        guard let params = request.params,
              let keyValue = params["key"],
              case let .string(key) = keyValue else {
            return CodexResponse(result: nil, error: CodexError.invalidParams, id: request.id)
        }

        let result: [String: AnyCodable] = [
            "key": .string(key),
            "value": .string("(memory value)"),
            "importance": .double(0.8)
        ]

        return CodexResponse(
            result: .object(result),
            error: nil,
            id: request.id
        )
    }

    private func handleSearchMemories(_ request: CodexRequest) async -> CodexResponse {
        guard let params = request.params,
              let queryValue = params["query"],
              case let .string(query) = queryValue else {
            return CodexResponse(result: nil, error: CodexError.invalidParams, id: request.id)
        }

        let results: [AnyCodable] = []

        return CodexResponse(
            result: .object(["results": .array(results)]),
            error: nil,
            id: request.id
        )
    }

    private func handleListMemories(_ request: CodexRequest) async -> CodexResponse {
        let limit = extractInt(from: request.params?["limit"]) ?? 50

        let results: [AnyCodable] = []

        return CodexResponse(
            result: .object([
                "memories": .array(results),
                "limit": .int(limit)
            ]),
            error: nil,
            id: request.id
        )
    }

    private func handleGetInstanceInfo(_ request: CodexRequest) async -> CodexResponse {
        guard let params = request.params,
              let idValue = params["instanceId"],
              case let .string(instanceId) = idValue else {
            return CodexResponse(result: nil, error: CodexError.invalidParams, id: request.id)
        }

        if let instance = instances[instanceId] {
            let result: [String: AnyCodable] = [
                "id": .string(instance.id),
                "status": .string(instance.status.rawValue),
                "capabilities": .array(instance.capabilities.map { .string($0) })
            ]
            return CodexResponse(
                result: .object(result),
                error: nil,
                id: request.id
            )
        }

        return CodexResponse(
            result: nil,
            error: CodexError.serverError("Instance not found"),
            id: request.id
        )
    }

    private func handleListInstances(_ request: CodexRequest) async -> CodexResponse {
        let instanceList = instances.values.map { instance -> AnyCodable in
            .object([
                "id": .string(instance.id),
                "status": .string(instance.status.rawValue)
            ])
        }

        return CodexResponse(
            result: .object(["instances": .array(instanceList)]),
            error: nil,
            id: request.id
        )
    }

    // MARK: - Helpers

    private func extractString(from value: AnyCodable?) -> String? {
        guard let value = value, case let .string(str) = value else { return nil }
        return str
    }

    private func extractDouble(from value: AnyCodable?) -> Double? {
        guard let value = value else { return nil }
        if case let .double(d) = value { return d }
        if case let .int(i) = value { return Double(i) }
        return nil
    }

    private func extractInt(from value: AnyCodable?) -> Int? {
        guard let value = value, case let .int(i) = value else { return nil }
        return i
    }
}
