import Foundation

// MARK: - JSON-RPC 2.0 Request/Response

/// Codex JSON-RPC 2.0 request format
public struct CodexRequest: Codable {
    public let jsonrpc: String = "2.0"
    public let method: String
    public let params: [String: AnyCodable]?
    public let id: Int?

    public init(method: String, params: [String: AnyCodable]? = nil, id: Int? = nil) {
        self.method = method
        self.params = params
        self.id = id
    }
}

/// Codex JSON-RPC 2.0 response format
public struct CodexResponse: Codable {
    public let jsonrpc: String = "2.0"
    public let result: AnyCodable?
    public let error: CodexError?
    public let id: Int?

    public init(result: AnyCodable?, error: CodexError?, id: Int?) {
        self.result = result
        self.error = error
        self.id = id
    }
}

/// JSON-RPC error response
public struct CodexError: Codable {
    public let code: Int
    public let message: String
    public let data: AnyCodable?

    public init(code: Int, message: String, data: AnyCodable? = nil) {
        self.code = code
        self.message = message
        self.data = data
    }

    // Standard JSON-RPC error codes
    static let parseError = CodexError(code: -32700, message: "Parse error")
    static let invalidRequest = CodexError(code: -32600, message: "Invalid Request")
    static let methodNotFound = CodexError(code: -32601, message: "Method not found")
    static let invalidParams = CodexError(code: -32602, message: "Invalid params")
    static let internalError = CodexError(code: -32603, message: "Internal error")

    static func serverError(_ message: String) -> CodexError {
        CodexError(code: -32000, message: message)
    }
}

// MARK: - App Instance Management

/// Represents a running WritersApp instance registered with Codex
public struct AppInstance: Codable, Identifiable {
    public let id: String
    public let status: AppInstanceStatus
    public let capabilities: [String]
    public let lastHeartbeat: Date
    public let workload: WorkloadInfo?

    public init(
        id: String,
        status: AppInstanceStatus,
        capabilities: [String],
        lastHeartbeat: Date = Date(),
        workload: WorkloadInfo? = nil
    ) {
        self.id = id
        self.status = status
        self.capabilities = capabilities
        self.lastHeartbeat = lastHeartbeat
        self.workload = workload
    }
}

/// Status of an app instance
public enum AppInstanceStatus: String, Codable {
    case starting
    case ready
    case processing
    case idle
    case stopping
    case stopped
    case error
}

/// Workload information for an app instance
public struct WorkloadInfo: Codable {
    public let operationType: String
    public let estimatedDuration: TimeInterval
    public let processingCount: Int
    public let queueLength: Int

    public init(
        operationType: String,
        estimatedDuration: TimeInterval,
        processingCount: Int = 0,
        queueLength: Int = 0
    ) {
        self.operationType = operationType
        self.estimatedDuration = estimatedDuration
        self.processingCount = processingCount
        self.queueLength = queueLength
    }
}

// MARK: - Type-Erased Codable (AnyCodable)

/// Type-erased wrapper for any Codable value (similar to AnyCodable)
public enum AnyCodable: Codable {
    case null
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)
    case array([AnyCodable])
    case object([String: AnyCodable])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let boolValue = try? container.decode(Bool.self) {
            self = .bool(boolValue)
        } else if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
        } else if let doubleValue = try? container.decode(Double.self) {
            self = .double(doubleValue)
        } else if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            self = .array(arrayValue)
        } else if let objectValue = try? container.decode([String: AnyCodable].self) {
            self = .object(objectValue)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode AnyCodable")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .null:
            try container.encodeNil()
        case .bool(let bool):
            try container.encode(bool)
        case .int(let int):
            try container.encode(int)
        case .double(let double):
            try container.encode(double)
        case .string(let string):
            try container.encode(string)
        case .array(let array):
            try container.encode(array)
        case .object(let object):
            try container.encode(object)
        }
    }
}

// MARK: - Codex Server Configuration

/// Configuration for Codex server
public struct CodexServerConfig: Codable {
    public let port: Int
    public let host: String
    public let instanceId: String
    public let capabilities: [String]
    public let logPath: String?

    public init(
        port: Int = 8000,
        host: String = "localhost",
        instanceId: String = UUID().uuidString,
        capabilities: [String] = ["memory", "documents", "ai"],
        logPath: String? = nil
    ) {
        self.port = port
        self.host = host
        self.instanceId = instanceId
        self.capabilities = capabilities
        self.logPath = logPath
    }
}

// MARK: - Daemon Configuration

/// Configuration for daemon mode
public struct DaemonConfig: Codable {
    public let launchAgentPath: String
    public let logDirectory: String
    public let pidFile: String?
    public let maxLogSize: Int
    public let backupLogCount: Int

    public init(
        launchAgentPath: String = "~/.launchagents/com.writersapp.daemon.plist",
        logDirectory: String = "~/.writersapp/logs",
        pidFile: String? = nil,
        maxLogSize: Int = 10 * 1024 * 1024, // 10MB
        backupLogCount: Int = 5
    ) {
        self.launchAgentPath = launchAgentPath.expandingTildeInPath
        self.logDirectory = logDirectory.expandingTildeInPath
        self.pidFile = pidFile?.expandingTildeInPath
        self.maxLogSize = maxLogSize
        self.backupLogCount = backupLogCount
    }
}

// MARK: - Extensions

extension String {
    fileprivate var expandingTildeInPath: String {
        (self as NSString).expandingTildeInPath
    }
}
