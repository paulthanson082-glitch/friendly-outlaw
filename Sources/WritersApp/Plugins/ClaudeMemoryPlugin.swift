import Foundation

// MARK: - Claude Memory Plugin

/// Built-in plugin for persistent memory storage for Claude interactions
public class ClaudeMemoryPlugin: Plugin {
    public let id: String = "claude-memory"
    public let name: String = "Claude Memory"
    public let version: String = "1.0.0"
    public let description: String = "Persistent memory storage for Claude AI interactions, enabling context retention across sessions"
    public var isEnabled: Bool = true
    public let capabilities: [PluginCapability] = [.memory, .customActions]

    private let storagePath: String
    private var memories: [String: MemoryEntry] = [:]
    private var memoryIndex: MemoryIndex
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var isInitialized = false

    public init(storagePath: String? = nil) {
        if let path = storagePath {
            self.storagePath = path
        } else {
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.path ?? NSTemporaryDirectory()
            self.storagePath = documentsPath + "/WritersApp/claude-memory"
        }

        self.memoryIndex = MemoryIndex()
    }

    // MARK: - Plugin Lifecycle

    public func initialize() async throws {
        try FileManager.default.createDirectory(atPath: storagePath, withIntermediateDirectories: true)

        // Load existing memories
        loadMemories()
        loadIndex()

        isInitialized = true
    }

    public func shutdown() async throws {
        // Save all memories before shutdown
        saveAllMemories()
        saveIndex()
        isInitialized = false
    }

    // MARK: - Plugin Actions

    public func execute(action: PluginAction) async throws -> PluginResult {
        guard isInitialized else {
            throw PluginError.notInitialized
        }

        switch action.type {
        case .storeMemory:
            return try storeMemory(params: action.parameters)

        case .retrieveMemory:
            return try retrieveMemory(params: action.parameters)

        case .searchMemory:
            return try searchMemory(params: action.parameters)

        case .clearMemory:
            return try clearMemory(params: action.parameters)

        case .listMemories:
            return listMemories(params: action.parameters)

        case .custom:
            return try handleCustomAction(params: action.parameters)

        default:
            throw PluginError.actionNotSupported(action.type.rawValue)
        }
    }

    // MARK: - Memory Operations

    private func storeMemory(params: [String: Any]) throws -> PluginResult {
        guard let key = params["key"] as? String else {
            throw PluginError.invalidParameters("Memory key is required")
        }

        guard let value = params["value"] as? String else {
            throw PluginError.invalidParameters("Memory value is required")
        }

        let category = params["category"] as? String ?? "general"
        let tags = params["tags"] as? [String] ?? []
        let metadata = params["metadata"] as? [String: String] ?? [:]
        let importance = params["importance"] as? Double ?? 0.5
        let ttl = params["ttl"] as? Int // Time-to-live in seconds, nil = permanent

        let entry = MemoryEntry(
            key: key,
            value: value,
            category: category,
            tags: tags,
            metadata: metadata,
            importance: importance,
            ttl: ttl
        )

        memories[key] = entry

        // Update index
        memoryIndex.add(entry: entry)

        // Save to disk
        saveMemory(entry)
        saveIndex()

        return PluginResult.success(
            data: ["key": key, "stored": true],
            metadata: ["timestamp": ISO8601DateFormatter().string(from: entry.created)]
        )
    }

    private func retrieveMemory(params: [String: Any]) throws -> PluginResult {
        guard let key = params["key"] as? String else {
            throw PluginError.invalidParameters("Memory key is required")
        }

        guard let entry = memories[key] else {
            return PluginResult.success(data: nil)
        }

        // Check TTL
        if let ttl = entry.ttl {
            let expirationDate = entry.created.addingTimeInterval(TimeInterval(ttl))
            if Date() > expirationDate {
                // Memory has expired
                memories.removeValue(forKey: key)
                deleteMemoryFile(key: key)
                return PluginResult.success(data: nil)
            }
        }

        // Update access time
        var updatedEntry = entry
        updatedEntry.lastAccessed = Date()
        updatedEntry.accessCount += 1
        memories[key] = updatedEntry
        saveMemory(updatedEntry)

        return PluginResult.success(data: entry.value, metadata: [
            "category": entry.category,
            "tags": entry.tags.joined(separator: ","),
            "importance": String(entry.importance),
            "accessCount": String(entry.accessCount)
        ])
    }

    private func searchMemory(params: [String: Any]) throws -> PluginResult {
        guard let query = params["query"] as? String else {
            throw PluginError.invalidParameters("Search query is required")
        }

        let limit = params["limit"] as? Int ?? 10
        let category = params["category"] as? String
        let tags = params["tags"] as? [String]
        let minImportance = params["minImportance"] as? Double ?? 0.0

        var results: [(entry: MemoryEntry, score: Double)] = []

        for (_, entry) in memories {
            // Filter by category if specified
            if let cat = category, entry.category != cat {
                continue
            }

            // Filter by tags if specified
            if let requiredTags = tags {
                let hasAllTags = requiredTags.allSatisfy { entry.tags.contains($0) }
                if !hasAllTags { continue }
            }

            // Filter by importance
            if entry.importance < minImportance {
                continue
            }

            // Calculate relevance score
            let score = calculateRelevanceScore(entry: entry, query: query)
            if score > 0 {
                results.append((entry, score))
            }
        }

        // Sort by score and limit
        results.sort { $0.score > $1.score }
        let limitedResults = Array(results.prefix(limit))

        let data: [[String: Any]] = limitedResults.map { result in
            return [
                "key": result.entry.key,
                "value": result.entry.value,
                "score": result.score,
                "category": result.entry.category,
                "tags": result.entry.tags,
                "importance": result.entry.importance
            ]
        }

        return PluginResult.success(data: data, metadata: ["totalResults": String(results.count)])
    }

    private func clearMemory(params: [String: Any]) throws -> PluginResult {
        if let key = params["key"] as? String {
            // Clear specific memory
            memories.removeValue(forKey: key)
            memoryIndex.remove(key: key)
            deleteMemoryFile(key: key)
            saveIndex()
            return PluginResult.success(data: ["cleared": 1])
        }

        if let category = params["category"] as? String {
            // Clear all memories in category
            let keysToRemove = memories.filter { $0.value.category == category }.map { $0.key }
            for key in keysToRemove {
                memories.removeValue(forKey: key)
                memoryIndex.remove(key: key)
                deleteMemoryFile(key: key)
            }
            saveIndex()
            return PluginResult.success(data: ["cleared": keysToRemove.count])
        }

        // Clear all memories
        let count = memories.count
        memories.removeAll()
        memoryIndex = MemoryIndex()

        // Delete all memory files
        if let files = try? FileManager.default.contentsOfDirectory(atPath: storagePath) {
            for file in files {
                try? FileManager.default.removeItem(atPath: storagePath + "/\(file)")
            }
        }

        return PluginResult.success(data: ["cleared": count])
    }

    private func listMemories(params: [String: Any]) -> PluginResult {
        let category = params["category"] as? String
        let limit = params["limit"] as? Int ?? 100
        let offset = params["offset"] as? Int ?? 0
        let sortBy = params["sortBy"] as? String ?? "created" // created, accessed, importance

        var filteredMemories = Array(memories.values)

        // Filter by category
        if let cat = category {
            filteredMemories = filteredMemories.filter { $0.category == cat }
        }

        // Sort
        switch sortBy {
        case "accessed":
            filteredMemories.sort { $0.lastAccessed > $1.lastAccessed }
        case "importance":
            filteredMemories.sort { $0.importance > $1.importance }
        default:
            filteredMemories.sort { $0.created > $1.created }
        }

        // Paginate
        let paginatedMemories = Array(filteredMemories.dropFirst(offset).prefix(limit))

        let data: [[String: Any]] = paginatedMemories.map { entry in
            return [
                "key": entry.key,
                "category": entry.category,
                "tags": entry.tags,
                "importance": entry.importance,
                "created": ISO8601DateFormatter().string(from: entry.created),
                "accessCount": entry.accessCount
            ]
        }

        return PluginResult.success(data: data, metadata: [
            "total": String(filteredMemories.count),
            "offset": String(offset),
            "limit": String(limit)
        ])
    }

    private func handleCustomAction(params: [String: Any]) throws -> PluginResult {
        guard let actionName = params["action"] as? String else {
            throw PluginError.invalidParameters("Custom action name is required")
        }

        switch actionName {
        case "getStats":
            return getStats()

        case "compact":
            return compact()

        case "export":
            return exportMemories(params: params)

        case "import":
            return try importMemories(params: params)

        case "setImportance":
            return try setImportance(params: params)

        case "addTags":
            return try addTags(params: params)

        case "getCategories":
            return getCategories()

        default:
            throw PluginError.actionNotSupported(actionName)
        }
    }

    // MARK: - Custom Actions

    private func getStats() -> PluginResult {
        let totalMemories = memories.count
        let categoryCounts = Dictionary(grouping: memories.values, by: { $0.category })
            .mapValues { $0.count }
        let totalAccessCount = memories.values.reduce(0) { $0 + $1.accessCount }
        let avgImportance = memories.isEmpty ? 0.0 : memories.values.reduce(0.0) { $0 + $1.importance } / Double(memories.count)

        return PluginResult.success(data: [
            "totalMemories": totalMemories,
            "categoryCounts": categoryCounts,
            "totalAccessCount": totalAccessCount,
            "averageImportance": avgImportance
        ])
    }

    private func compact() -> PluginResult {
        // Remove expired memories
        var removed = 0
        let now = Date()

        for (key, entry) in memories {
            if let ttl = entry.ttl {
                let expirationDate = entry.created.addingTimeInterval(TimeInterval(ttl))
                if now > expirationDate {
                    memories.removeValue(forKey: key)
                    memoryIndex.remove(key: key)
                    deleteMemoryFile(key: key)
                    removed += 1
                }
            }
        }

        saveIndex()

        return PluginResult.success(data: ["removed": removed])
    }

    private func exportMemories(params: [String: Any]) -> PluginResult {
        let format = params["format"] as? String ?? "json"
        let category = params["category"] as? String

        var memoriesToExport = Array(memories.values)
        if let cat = category {
            memoriesToExport = memoriesToExport.filter { $0.category == cat }
        }

        if format == "json" {
            if let data = try? encoder.encode(memoriesToExport),
               let jsonString = String(data: data, encoding: .utf8) {
                return PluginResult.success(data: jsonString)
            }
        }

        return PluginResult.failure(error: PluginError.executionFailed("Export failed"))
    }

    private func importMemories(params: [String: Any]) throws -> PluginResult {
        guard let jsonString = params["data"] as? String,
              let data = jsonString.data(using: .utf8) else {
            throw PluginError.invalidParameters("Import data is required")
        }

        let importedEntries = try decoder.decode([MemoryEntry].self, from: data)
        var imported = 0

        for entry in importedEntries {
            memories[entry.key] = entry
            memoryIndex.add(entry: entry)
            saveMemory(entry)
            imported += 1
        }

        saveIndex()

        return PluginResult.success(data: ["imported": imported])
    }

    private func setImportance(params: [String: Any]) throws -> PluginResult {
        guard let key = params["key"] as? String else {
            throw PluginError.invalidParameters("Memory key is required")
        }

        guard let importance = params["importance"] as? Double else {
            throw PluginError.invalidParameters("Importance value is required")
        }

        guard var entry = memories[key] else {
            return PluginResult.failure(error: PluginError.executionFailed("Memory not found"))
        }

        entry.importance = max(0.0, min(1.0, importance)) // Clamp to 0-1
        memories[key] = entry
        saveMemory(entry)

        return PluginResult.success(data: ["key": key, "importance": entry.importance])
    }

    private func addTags(params: [String: Any]) throws -> PluginResult {
        guard let key = params["key"] as? String else {
            throw PluginError.invalidParameters("Memory key is required")
        }

        guard let newTags = params["tags"] as? [String] else {
            throw PluginError.invalidParameters("Tags are required")
        }

        guard var entry = memories[key] else {
            return PluginResult.failure(error: PluginError.executionFailed("Memory not found"))
        }

        let uniqueTags = Set(entry.tags + newTags)
        entry.tags = Array(uniqueTags)
        memories[key] = entry
        memoryIndex.add(entry: entry) // Re-index with new tags
        saveMemory(entry)

        return PluginResult.success(data: ["key": key, "tags": entry.tags])
    }

    private func getCategories() -> PluginResult {
        let categories = Set(memories.values.map { $0.category })
        return PluginResult.success(data: Array(categories))
    }

    // MARK: - Relevance Scoring

    private func calculateRelevanceScore(entry: MemoryEntry, query: String) -> Double {
        var score = 0.0
        let queryLower = query.lowercased()
        let words = queryLower.components(separatedBy: .whitespaces)

        // Check key match
        if entry.key.lowercased().contains(queryLower) {
            score += 1.0
        }

        // Check value match
        let valueLower = entry.value.lowercased()
        for word in words {
            if valueLower.contains(word) {
                score += 0.5
            }
        }

        // Check tag match
        for tag in entry.tags {
            if tag.lowercased().contains(queryLower) {
                score += 0.75
            }
        }

        // Factor in importance
        score *= (0.5 + entry.importance * 0.5)

        // Factor in recency (more recent = higher score)
        let daysSinceAccess = Date().timeIntervalSince(entry.lastAccessed) / (24 * 60 * 60)
        let recencyFactor = max(0.1, 1.0 - (daysSinceAccess / 30.0)) // Decay over 30 days
        score *= recencyFactor

        return score
    }

    // MARK: - Persistence

    private func loadMemories() {
        let fileManager = FileManager.default
        guard let files = try? fileManager.contentsOfDirectory(atPath: storagePath) else { return }

        for file in files where file.hasSuffix(".json") && file != "index.json" {
            let path = storagePath + "/\(file)"
            if let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
               let entry = try? decoder.decode(MemoryEntry.self, from: data) {
                memories[entry.key] = entry
            }
        }
    }

    private func saveMemory(_ entry: MemoryEntry) {
        let filename = entry.key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? entry.key
        let path = storagePath + "/\(filename).json"

        if let data = try? encoder.encode(entry) {
            try? data.write(to: URL(fileURLWithPath: path))
        }
    }

    private func deleteMemoryFile(key: String) {
        let filename = key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? key
        let path = storagePath + "/\(filename).json"
        try? FileManager.default.removeItem(atPath: path)
    }

    private func saveAllMemories() {
        for entry in memories.values {
            saveMemory(entry)
        }
    }

    private func loadIndex() {
        let indexPath = storagePath + "/index.json"
        if let data = try? Data(contentsOf: URL(fileURLWithPath: indexPath)),
           let index = try? decoder.decode(MemoryIndex.self, from: data) {
            self.memoryIndex = index
        }
    }

    private func saveIndex() {
        let indexPath = storagePath + "/index.json"
        if let data = try? encoder.encode(memoryIndex) {
            try? data.write(to: URL(fileURLWithPath: indexPath))
        }
    }
}

// MARK: - Memory Entry

/// A single memory entry
public struct MemoryEntry: Codable {
    public let key: String
    public var value: String
    public var category: String
    public var tags: [String]
    public var metadata: [String: String]
    public var importance: Double // 0.0 to 1.0
    public var ttl: Int? // Time-to-live in seconds, nil = permanent
    public let created: Date
    public var lastAccessed: Date
    public var accessCount: Int

    public init(
        key: String,
        value: String,
        category: String = "general",
        tags: [String] = [],
        metadata: [String: String] = [:],
        importance: Double = 0.5,
        ttl: Int? = nil
    ) {
        self.key = key
        self.value = value
        self.category = category
        self.tags = tags
        self.metadata = metadata
        self.importance = max(0.0, min(1.0, importance))
        self.ttl = ttl
        self.created = Date()
        self.lastAccessed = Date()
        self.accessCount = 0
    }
}

// MARK: - Memory Index

/// Index for fast memory lookups
struct MemoryIndex: Codable {
    var keysByCategory: [String: Set<String>] = [:]
    var keysByTag: [String: Set<String>] = [:]

    mutating func add(entry: MemoryEntry) {
        // Index by category
        if keysByCategory[entry.category] == nil {
            keysByCategory[entry.category] = []
        }
        keysByCategory[entry.category]?.insert(entry.key)

        // Index by tags
        for tag in entry.tags {
            if keysByTag[tag] == nil {
                keysByTag[tag] = []
            }
            keysByTag[tag]?.insert(entry.key)
        }
    }

    mutating func remove(key: String) {
        for category in keysByCategory.keys {
            keysByCategory[category]?.remove(key)
        }
        for tag in keysByTag.keys {
            keysByTag[tag]?.remove(key)
        }
    }
}
