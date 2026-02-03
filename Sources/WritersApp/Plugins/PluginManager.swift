import Foundation

// MARK: - Plugin Manager

/// Manages loading, configuration, and lifecycle of plugins
public class PluginManager {
    /// Shared instance for global access
    public static let shared = PluginManager()

    /// Registered plugins
    private var plugins: [String: Plugin] = [:]

    /// Plugin configurations
    private var configurations: [String: PluginConfiguration] = [:]

    /// MCP clients for MCP-based plugins
    private var mcpClients: [String: MCPClient] = [:]

    /// Storage path for plugin data
    private let storagePath: String

    /// Delegate for plugin events
    public weak var delegate: PluginManagerDelegate?

    public init(storagePath: String? = nil) {
        if let path = storagePath {
            self.storagePath = path
        } else {
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.path ?? NSTemporaryDirectory()
            self.storagePath = documentsPath + "/WritersApp/plugins"
        }

        // Ensure storage directory exists
        try? FileManager.default.createDirectory(atPath: self.storagePath, withIntermediateDirectories: true)
    }

    // MARK: - Plugin Registration

    /// Register a plugin
    public func register(plugin: Plugin) {
        plugins[plugin.id] = plugin
        delegate?.pluginManager(self, didRegister: plugin)
    }

    /// Unregister a plugin
    public func unregister(pluginId: String) async {
        if let plugin = plugins[pluginId] {
            if plugin.isEnabled {
                try? await plugin.shutdown()
            }
            plugins.removeValue(forKey: pluginId)
            delegate?.pluginManager(self, didUnregister: pluginId)
        }

        // Clean up MCP client if exists
        if let client = mcpClients[pluginId] {
            await client.disconnect()
            mcpClients.removeValue(forKey: pluginId)
        }
    }

    /// Get a registered plugin
    public func getPlugin(id: String) -> Plugin? {
        return plugins[id]
    }

    /// Get all registered plugins
    public func getAllPlugins() -> [Plugin] {
        return Array(plugins.values)
    }

    /// Get enabled plugins
    public func getEnabledPlugins() -> [Plugin] {
        return plugins.values.filter { $0.isEnabled }
    }

    /// Get plugins with a specific capability
    public func getPlugins(with capability: PluginCapability) -> [Plugin] {
        return plugins.values.filter { $0.capabilities.contains(capability) }
    }

    // MARK: - Plugin Lifecycle

    /// Initialize all enabled plugins
    public func initializeAll() async throws {
        for plugin in getEnabledPlugins() {
            try await initializePlugin(id: plugin.id)
        }
    }

    /// Initialize a specific plugin
    public func initializePlugin(id: String) async throws {
        guard let plugin = plugins[id] else {
            throw PluginError.pluginNotFound(id)
        }

        try await plugin.initialize()
        delegate?.pluginManager(self, didInitialize: plugin)
    }

    /// Shutdown all plugins
    public func shutdownAll() async {
        for plugin in plugins.values {
            try? await plugin.shutdown()
        }
    }

    /// Shutdown a specific plugin
    public func shutdownPlugin(id: String) async throws {
        guard let plugin = plugins[id] else {
            throw PluginError.pluginNotFound(id)
        }

        try await plugin.shutdown()
        delegate?.pluginManager(self, didShutdown: plugin)
    }

    /// Enable a plugin
    public func enablePlugin(id: String) async throws {
        guard let plugin = plugins[id] else {
            throw PluginError.pluginNotFound(id)
        }

        plugin.isEnabled = true
        try await plugin.initialize()

        // Update configuration
        if var config = configurations[id] {
            config = PluginConfiguration(id: config.id, name: config.name, enabled: true, settings: config.settings)
            configurations[id] = config
            saveConfiguration(config)
        }

        delegate?.pluginManager(self, didEnable: plugin)
    }

    /// Disable a plugin
    public func disablePlugin(id: String) async throws {
        guard let plugin = plugins[id] else {
            throw PluginError.pluginNotFound(id)
        }

        try await plugin.shutdown()
        plugin.isEnabled = false

        // Update configuration
        if var config = configurations[id] {
            config = PluginConfiguration(id: config.id, name: config.name, enabled: false, settings: config.settings)
            configurations[id] = config
            saveConfiguration(config)
        }

        delegate?.pluginManager(self, didDisable: plugin)
    }

    // MARK: - MCP Plugin Loading

    /// Load an MCP-based plugin from manifest
    public func loadMCPPlugin(from manifest: PluginManifest) async throws -> Plugin {
        guard let serverConfig = manifest.mcpServer else {
            throw PluginError.invalidParameters("MCP server configuration is required")
        }

        let mcpClient = MCPClient(serverConfig: serverConfig)
        try await mcpClient.connect()

        mcpClients[manifest.id] = mcpClient

        let plugin = MCPPlugin(manifest: manifest, client: mcpClient)
        register(plugin: plugin)

        return plugin
    }

    /// Load an MCP plugin from a configuration file
    public func loadMCPPlugin(fromConfigFile path: String) async throws -> Plugin {
        let url = URL(fileURLWithPath: path)
        let data = try Data(contentsOf: url)
        let manifest = try JSONDecoder().decode(PluginManifest.self, from: data)

        return try await loadMCPPlugin(from: manifest)
    }

    // MARK: - Plugin Actions

    /// Execute an action on a plugin
    public func execute(pluginId: String, action: PluginAction) async throws -> PluginResult {
        guard let plugin = plugins[pluginId] else {
            throw PluginError.pluginNotFound(pluginId)
        }

        guard plugin.isEnabled else {
            throw PluginError.notInitialized
        }

        return try await plugin.execute(action: action)
    }

    /// Execute an action on all plugins with a specific capability
    public func executeOnAll(capability: PluginCapability, action: PluginAction) async -> [String: PluginResult] {
        var results: [String: PluginResult] = [:]

        let targetPlugins = getPlugins(with: capability).filter { $0.isEnabled }

        for plugin in targetPlugins {
            do {
                let result = try await plugin.execute(action: action)
                results[plugin.id] = result
            } catch {
                results[plugin.id] = PluginResult.failure(error: PluginError.executionFailed(error.localizedDescription))
            }
        }

        return results
    }

    // MARK: - Memory Operations (Convenience)

    /// Store a memory across all memory-capable plugins
    public func storeMemory(key: String, value: String, metadata: [String: String]? = nil) async -> [String: PluginResult] {
        var params: [String: Any] = ["key": key, "value": value]
        if let meta = metadata {
            params["metadata"] = meta
        }

        let action = PluginAction(type: .storeMemory, parameters: params)
        return await executeOnAll(capability: .memory, action: action)
    }

    /// Retrieve a memory from the first available memory plugin
    public func retrieveMemory(key: String) async -> String? {
        let action = PluginAction(type: .retrieveMemory, parameters: ["key": key])

        for plugin in getPlugins(with: .memory).filter({ $0.isEnabled }) {
            if let result = try? await plugin.execute(action: action),
               result.success,
               let value = result.data as? String {
                return value
            }
        }

        return nil
    }

    /// Search memories across all memory plugins
    public func searchMemories(query: String, limit: Int = 10) async -> [MemorySearchResult] {
        let action = PluginAction(type: .searchMemory, parameters: ["query": query, "limit": limit])
        let results = await executeOnAll(capability: .memory, action: action)

        var searchResults: [MemorySearchResult] = []

        for (pluginId, result) in results {
            if result.success, let items = result.data as? [[String: Any]] {
                for item in items {
                    if let key = item["key"] as? String,
                       let value = item["value"] as? String {
                        let score = item["score"] as? Double ?? 0.0
                        searchResults.append(MemorySearchResult(
                            pluginId: pluginId,
                            key: key,
                            value: value,
                            score: score
                        ))
                    }
                }
            }
        }

        return searchResults.sorted { $0.score > $1.score }
    }

    // MARK: - Configuration Persistence

    /// Save plugin configuration
    public func saveConfiguration(_ config: PluginConfiguration) {
        configurations[config.id] = config

        let configPath = storagePath + "/\(config.id).json"
        if let data = try? JSONEncoder().encode(config) {
            try? data.write(to: URL(fileURLWithPath: configPath))
        }
    }

    /// Load plugin configuration
    public func loadConfiguration(pluginId: String) -> PluginConfiguration? {
        if let config = configurations[pluginId] {
            return config
        }

        let configPath = storagePath + "/\(pluginId).json"
        if let data = try? Data(contentsOf: URL(fileURLWithPath: configPath)),
           let config = try? JSONDecoder().decode(PluginConfiguration.self, from: data) {
            configurations[pluginId] = config
            return config
        }

        return nil
    }

    /// Load all saved configurations
    public func loadAllConfigurations() {
        let fileManager = FileManager.default
        guard let files = try? fileManager.contentsOfDirectory(atPath: storagePath) else { return }

        for file in files where file.hasSuffix(".json") {
            let path = storagePath + "/\(file)"
            if let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
               let config = try? JSONDecoder().decode(PluginConfiguration.self, from: data) {
                configurations[config.id] = config
            }
        }
    }

    // MARK: - Built-in Plugin Installation

    /// Install the Claude Memory plugin
    public func installClaudeMemoryPlugin(storagePath: String? = nil) -> ClaudeMemoryPlugin {
        let plugin = ClaudeMemoryPlugin(storagePath: storagePath ?? self.storagePath + "/claude-memory")
        register(plugin: plugin)
        return plugin
    }
}

// MARK: - Memory Search Result

/// Result from memory search
public struct MemorySearchResult {
    public let pluginId: String
    public let key: String
    public let value: String
    public let score: Double
}

// MARK: - Plugin Manager Delegate

/// Delegate for plugin manager events
public protocol PluginManagerDelegate: AnyObject {
    func pluginManager(_ manager: PluginManager, didRegister plugin: Plugin)
    func pluginManager(_ manager: PluginManager, didUnregister pluginId: String)
    func pluginManager(_ manager: PluginManager, didInitialize plugin: Plugin)
    func pluginManager(_ manager: PluginManager, didShutdown plugin: Plugin)
    func pluginManager(_ manager: PluginManager, didEnable plugin: Plugin)
    func pluginManager(_ manager: PluginManager, didDisable plugin: Plugin)
}

// Default implementations for optional delegate methods
public extension PluginManagerDelegate {
    func pluginManager(_ manager: PluginManager, didRegister plugin: Plugin) {}
    func pluginManager(_ manager: PluginManager, didUnregister pluginId: String) {}
    func pluginManager(_ manager: PluginManager, didInitialize plugin: Plugin) {}
    func pluginManager(_ manager: PluginManager, didShutdown plugin: Plugin) {}
    func pluginManager(_ manager: PluginManager, didEnable plugin: Plugin) {}
    func pluginManager(_ manager: PluginManager, didDisable plugin: Plugin) {}
}

// MARK: - MCP Plugin Wrapper

/// Plugin wrapper for MCP-based plugins
public class MCPPlugin: Plugin {
    public let id: String
    public let name: String
    public let version: String
    public let description: String
    public var isEnabled: Bool = true
    public let capabilities: [PluginCapability]

    private let manifest: PluginManifest
    private let client: MCPClient
    private var cachedTools: [MCPTool]?
    private var cachedResources: [MCPResource]?
    private var cachedPrompts: [MCPPrompt]?

    init(manifest: PluginManifest, client: MCPClient) {
        self.manifest = manifest
        self.client = client
        self.id = manifest.id
        self.name = manifest.name
        self.version = manifest.version
        self.description = manifest.description
        self.capabilities = manifest.capabilities.compactMap { PluginCapability(rawValue: $0) }
    }

    public func initialize() async throws {
        // Refresh cached data
        cachedTools = try? await client.listTools()
        cachedResources = try? await client.listResources()
        cachedPrompts = try? await client.listPrompts()
    }

    public func shutdown() async throws {
        await client.disconnect()
    }

    public func execute(action: PluginAction) async throws -> PluginResult {
        switch action.type {
        case .listTools:
            if cachedTools == nil {
                cachedTools = try await client.listTools()
            }
            return PluginResult.success(data: cachedTools)

        case .executeTool:
            guard let name = action.parameters["name"] as? String else {
                throw PluginError.invalidParameters("Tool name is required")
            }
            let arguments = action.parameters["arguments"] as? [String: Any] ?? [:]
            let result = try await client.callTool(name: name, arguments: arguments)
            return PluginResult.success(data: result.textContent)

        case .listResources:
            if cachedResources == nil {
                cachedResources = try await client.listResources()
            }
            return PluginResult.success(data: cachedResources)

        case .readResource:
            guard let uri = action.parameters["uri"] as? String else {
                throw PluginError.invalidParameters("Resource URI is required")
            }
            let content = try await client.readResource(uri: uri)
            return PluginResult.success(data: content.text ?? content.blob)

        case .listPrompts:
            if cachedPrompts == nil {
                cachedPrompts = try await client.listPrompts()
            }
            return PluginResult.success(data: cachedPrompts)

        case .getPrompt:
            guard let name = action.parameters["name"] as? String else {
                throw PluginError.invalidParameters("Prompt name is required")
            }
            let arguments = action.parameters["arguments"] as? [String: String]
            let result = try await client.getPrompt(name: name, arguments: arguments)
            return PluginResult.success(data: result)

        default:
            throw PluginError.actionNotSupported(action.type.rawValue)
        }
    }
}
