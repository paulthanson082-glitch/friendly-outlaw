import Foundation

// MARK: - Plugin Protocol

/// Protocol that all plugins must conform to
public protocol Plugin: AnyObject {
    /// Unique identifier for the plugin
    var id: String { get }

    /// Display name for the plugin
    var name: String { get }

    /// Plugin version
    var version: String { get }

    /// Plugin description
    var description: String { get }

    /// Whether the plugin is currently enabled
    var isEnabled: Bool { get set }

    /// Plugin capabilities
    var capabilities: [PluginCapability] { get }

    /// Initialize the plugin
    func initialize() async throws

    /// Shutdown the plugin
    func shutdown() async throws

    /// Execute a plugin action
    func execute(action: PluginAction) async throws -> PluginResult
}

// MARK: - Plugin Capability

/// Capabilities that a plugin can provide
public enum PluginCapability: String, Codable, CaseIterable {
    case memory = "memory"                      // Store and retrieve context
    case tools = "tools"                        // Provide additional tools
    case resources = "resources"                // Provide resources/files
    case prompts = "prompts"                    // Provide prompt templates
    case sampling = "sampling"                  // Request LLM completions
    case logging = "logging"                    // Logging and analytics
    case customActions = "custom_actions"       // Custom plugin-specific actions

    public var displayName: String {
        switch self {
        case .memory: return "Memory"
        case .tools: return "Tools"
        case .resources: return "Resources"
        case .prompts: return "Prompts"
        case .sampling: return "Sampling"
        case .logging: return "Logging"
        case .customActions: return "Custom Actions"
        }
    }
}

// MARK: - Plugin Action

/// Actions that can be performed by plugins
public struct PluginAction {
    public let type: PluginActionType
    public let parameters: [String: Any]

    public init(type: PluginActionType, parameters: [String: Any] = [:]) {
        self.type = type
        self.parameters = parameters
    }
}

/// Types of plugin actions
public enum PluginActionType: String {
    // Memory actions
    case storeMemory = "store_memory"
    case retrieveMemory = "retrieve_memory"
    case searchMemory = "search_memory"
    case clearMemory = "clear_memory"
    case listMemories = "list_memories"

    // Tool actions
    case listTools = "list_tools"
    case executeTool = "execute_tool"

    // Resource actions
    case listResources = "list_resources"
    case readResource = "read_resource"

    // Prompt actions
    case listPrompts = "list_prompts"
    case getPrompt = "get_prompt"

    // Custom actions
    case custom = "custom"
}

// MARK: - Plugin Result

/// Result from a plugin action
public struct PluginResult {
    public let success: Bool
    public let data: Any?
    public let error: PluginError?
    public let metadata: [String: Any]?

    public init(success: Bool, data: Any? = nil, error: PluginError? = nil, metadata: [String: Any]? = nil) {
        self.success = success
        self.data = data
        self.error = error
        self.metadata = metadata
    }

    public static func success(data: Any? = nil, metadata: [String: Any]? = nil) -> PluginResult {
        return PluginResult(success: true, data: data, metadata: metadata)
    }

    public static func failure(error: PluginError) -> PluginResult {
        return PluginResult(success: false, error: error)
    }
}

// MARK: - Plugin Error

/// Errors that can occur in plugins
public enum PluginError: LocalizedError {
    case notInitialized
    case actionNotSupported(String)
    case invalidParameters(String)
    case executionFailed(String)
    case connectionFailed(String)
    case timeout
    case pluginNotFound(String)
    case capabilityNotSupported(PluginCapability)

    public var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "Plugin is not initialized"
        case .actionNotSupported(let action):
            return "Action not supported: \(action)"
        case .invalidParameters(let message):
            return "Invalid parameters: \(message)"
        case .executionFailed(let message):
            return "Execution failed: \(message)"
        case .connectionFailed(let message):
            return "Connection failed: \(message)"
        case .timeout:
            return "Plugin operation timed out"
        case .pluginNotFound(let id):
            return "Plugin not found: \(id)"
        case .capabilityNotSupported(let capability):
            return "Capability not supported: \(capability.rawValue)"
        }
    }
}

// MARK: - Plugin Configuration

/// Configuration for a plugin
public struct PluginConfiguration: Codable {
    public let id: String
    public let name: String
    public let enabled: Bool
    public let settings: [String: String]

    public init(id: String, name: String, enabled: Bool = true, settings: [String: String] = [:]) {
        self.id = id
        self.name = name
        self.enabled = enabled
        self.settings = settings
    }
}

// MARK: - Plugin Manifest

/// Manifest describing a plugin
public struct PluginManifest: Codable {
    public let id: String
    public let name: String
    public let version: String
    public let description: String
    public let author: String?
    public let capabilities: [String]
    public let settings: [PluginSettingDefinition]?
    public let mcpServer: MCPServerConfig?

    public init(
        id: String,
        name: String,
        version: String,
        description: String,
        author: String? = nil,
        capabilities: [String],
        settings: [PluginSettingDefinition]? = nil,
        mcpServer: MCPServerConfig? = nil
    ) {
        self.id = id
        self.name = name
        self.version = version
        self.description = description
        self.author = author
        self.capabilities = capabilities
        self.settings = settings
        self.mcpServer = mcpServer
    }
}

/// Definition of a plugin setting
public struct PluginSettingDefinition: Codable {
    public let key: String
    public let name: String
    public let description: String
    public let type: String  // "string", "number", "boolean", "select"
    public let required: Bool
    public let defaultValue: String?
    public let options: [String]?  // For select type

    public init(
        key: String,
        name: String,
        description: String,
        type: String,
        required: Bool = false,
        defaultValue: String? = nil,
        options: [String]? = nil
    ) {
        self.key = key
        self.name = name
        self.description = description
        self.type = type
        self.required = required
        self.defaultValue = defaultValue
        self.options = options
    }
}

/// MCP server configuration
public struct MCPServerConfig: Codable {
    public let transport: String  // "stdio", "http", "websocket"
    public let command: String?   // For stdio transport
    public let args: [String]?    // Command arguments
    public let url: String?       // For http/websocket transport
    public let env: [String: String]? // Environment variables

    public init(
        transport: String,
        command: String? = nil,
        args: [String]? = nil,
        url: String? = nil,
        env: [String: String]? = nil
    ) {
        self.transport = transport
        self.command = command
        self.args = args
        self.url = url
        self.env = env
    }
}
