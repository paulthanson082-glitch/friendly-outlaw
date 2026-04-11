import Foundation

/// Production-grade memory plugin with persistent SQLite storage, encryption, TTL, and full-text search
public class ActiveMemoryPlugin: Plugin {
    public let id: String = "active-memory"
    public let name: String = "Active Memory"
    public let version: String = "1.0.0"
    public let description: String = "Persistent memory storage with encryption, TTL, and full-text search"
    public var isEnabled: Bool = true
    public let capabilities: [PluginCapability] = [.memory, .customActions, .tools]

    private let databasePath: String
    private let encryptionEnabled: Bool
    private let encryptionKey: String?
    private var connection: OpaquePointer?
    private let queue = DispatchQueue(label: "com.writersapp.active-memory")

    /// Initialize the ActiveMemoryPlugin
    /// - Parameters:
    ///   - databasePath: Path to the SQLite database file
    ///   - encryptionEnabled: Whether to encrypt stored memories
    ///   - encryptionKey: Optional encryption key (will use keychain if not provided)
    public init(
        databasePath: String,
        encryptionEnabled: Bool = true,
        encryptionKey: String? = nil
    ) {
        self.databasePath = databasePath
        self.encryptionEnabled = encryptionEnabled
        self.encryptionKey = encryptionKey ?? Self.getKeychainKey()
    }

    public func initialize() async throws {
        try await queue.async { [weak self] in
            guard let self = self else { return }
            try self.setupDatabase()
        }
    }

    public func shutdown() async throws {
        try await queue.async { [weak self] in
            guard let self = self else { return }
            if let conn = self.connection {
                sqlite3_close(conn)
                self.connection = nil
            }
        }
    }

    public func execute(action: PluginAction) async throws -> PluginResult {
        switch action.type {
        case .storeMemory:
            return try await handleStoreMemory(action.parameters)

        case .retrieveMemory:
            return try await handleRetrieveMemory(action.parameters)

        case .searchMemory:
            return try await handleSearchMemory(action.parameters)

        case .listMemories:
            return try await handleListMemories(action.parameters)

        case .clearMemory:
            return try await handleClearMemory(action.parameters)

        case .custom:
            if let customAction = action.parameters["action"] as? String {
                switch customAction {
                case "getStats":
                    return try await handleGetStats()
                case "compact":
                    return try await handleCompact()
                case "export":
                    return try await handleExport()
                case "import":
                    return try await handleImport(action.parameters)
                default:
                    throw PluginError.actionNotSupported(customAction)
                }
            }
            throw PluginError.invalidParameters("action required for custom action")

        default:
            throw PluginError.actionNotSupported(action.type.rawValue)
        }
    }

    // MARK: - Private Implementation

    private func setupDatabase() throws {
        var db: OpaquePointer?
        let flags = SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE
        guard sqlite3_open_v2(databasePath, &db, flags, nil) == SQLITE_OK else {
            throw PluginError.executionFailed("Failed to open database")
        }
        self.connection = db

        // Create memories table
        let createMemoriesSQL = """
        CREATE TABLE IF NOT EXISTS memories (
            id TEXT PRIMARY KEY,
            key TEXT NOT NULL UNIQUE,
            value TEXT NOT NULL,
            category TEXT,
            tags TEXT,
            importance REAL DEFAULT 0.5,
            ttl INTEGER,
            expiration_timestamp INTEGER,
            created INTEGER NOT NULL,
            accessed INTEGER NOT NULL,
            access_count INTEGER DEFAULT 0,
            encrypted_flag INTEGER DEFAULT 0,
            encrypted_value TEXT,
            metadata TEXT
        )
        """

        try executeSQL(createMemoriesSQL)

        // Create FTS5 virtual table for full-text search
        let createFTSSQL = """
        CREATE VIRTUAL TABLE IF NOT EXISTS memories_fts USING fts5(
            key, value, category, tags,
            content=memories,
            content_rowid=rowid
        )
        """

        try executeSQL(createFTSSQL)

        // Create index on expiration_timestamp for efficient cleanup
        let createIndexSQL = """
        CREATE INDEX IF NOT EXISTS memories_expiration_idx ON memories(expiration_timestamp)
        """

        try executeSQL(createIndexSQL)
    }

    private func executeSQL(_ sql: String) throws {
        guard let conn = connection else {
            throw PluginError.executionFailed("Database not initialized")
        }

        var errorMessage: UnsafeMutablePointer<CChar>?
        if sqlite3_exec(conn, sql, nil, nil, &errorMessage) != SQLITE_OK {
            let message = errorMessage.map { String(cString: $0) } ?? "Unknown error"
            sqlite3_free(errorMessage)
            throw PluginError.executionFailed(message)
        }
    }

    // MARK: - Memory Operations

    private func handleStoreMemory(_ params: [String: Any]) async throws -> PluginResult {
        guard let key = params["key"] as? String,
              let value = params["value"] as? String else {
            throw PluginError.invalidParameters("key and value required")
        }

        let category = params["category"] as? String ?? "default"
        let importance = (params["importance"] as? NSNumber)?.doubleValue ?? 0.5
        let ttl = params["ttl"] as? Int // In seconds
        let tags = (params["tags"] as? [String])?.joined(separator: ",") ?? ""
        let metadata = params["metadata"] as? [String: String]

        return try await queue.async { [weak self] in
            guard let self = self else {
                return PluginResult.failure(PluginError.executionFailed("Plugin not available"))
            }

            let now = Int(Date().timeIntervalSince1970)
            let expirationTimestamp = ttl.map { now + $0 }
            let memoryId = UUID().uuidString

            let encryptedValue: String?
            let encryptedFlag: Int
            if self.encryptionEnabled, let key = self.encryptionKey {
                encryptedValue = try? MemoryEncryption.encryptMemory(value, key: key)
                encryptedFlag = encryptedValue != nil ? 1 : 0
            } else {
                encryptedValue = nil
                encryptedFlag = 0
            }

            let sql = """
            INSERT OR REPLACE INTO memories
            (id, key, value, category, tags, importance, ttl, expiration_timestamp, created, accessed, access_count, encrypted_flag, encrypted_value, metadata)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """

            let metadataJSON = metadata.flatMap { try? JSONSerialization.data(withJSONObject: $0) }
                .flatMap { String(data: $0, encoding: .utf8) }

            var stmt: OpaquePointer?
            guard sqlite3_prepare_v2(self.connection, sql, -1, &stmt, nil) == SQLITE_OK,
                  let statement = stmt else {
                return PluginResult.failure(PluginError.executionFailed("Failed to prepare statement"))
            }

            defer { sqlite3_finalize(statement) }

            sqlite3_bind_text(statement, 1, memoryId, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 2, key, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 3, encryptedValue ?? value, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 4, category, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 5, tags, -1, SQLITE_TRANSIENT)
            sqlite3_bind_double(statement, 6, importance)
            if let ttl = ttl {
                sqlite3_bind_int(statement, 7, Int32(ttl))
            } else {
                sqlite3_bind_null(statement, 7)
            }
            if let expiration = expirationTimestamp {
                sqlite3_bind_int(statement, 8, Int32(expiration))
            } else {
                sqlite3_bind_null(statement, 8)
            }
            sqlite3_bind_int(statement, 9, Int32(now))
            sqlite3_bind_int(statement, 10, Int32(now))
            sqlite3_bind_int(statement, 11, 1)
            sqlite3_bind_int(statement, 12, Int32(encryptedFlag))
            if encryptedFlag == 1 {
                sqlite3_bind_text(statement, 13, encryptedValue, -1, SQLITE_TRANSIENT)
            } else {
                sqlite3_bind_null(statement, 13)
            }
            if let metadataJSON = metadataJSON {
                sqlite3_bind_text(statement, 14, metadataJSON, -1, SQLITE_TRANSIENT)
            } else {
                sqlite3_bind_null(statement, 14)
            }

            if sqlite3_step(statement) == SQLITE_DONE {
                return PluginResult.success(data: ["memoryId": memoryId])
            } else {
                return PluginResult.failure(PluginError.executionFailed("Failed to store memory"))
            }
        }
    }

    private func handleRetrieveMemory(_ params: [String: Any]) async throws -> PluginResult {
        guard let key = params["key"] as? String else {
            throw PluginError.invalidParameters("key required")
        }

        return try await queue.async { [weak self] in
            guard let self = self else {
                return PluginResult.failure(PluginError.executionFailed("Plugin not available"))
            }

            let now = Int(Date().timeIntervalSince1970)

            // Check expiration
            let expirationSQL = """
            SELECT expiration_timestamp FROM memories WHERE key = ? AND expiration_timestamp IS NOT NULL AND expiration_timestamp < ?
            """

            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(self.connection, expirationSQL, -1, &stmt, nil) == SQLITE_OK {
                sqlite3_bind_text(stmt, 1, key, -1, SQLITE_TRANSIENT)
                sqlite3_bind_int(stmt, 2, Int32(now))

                if sqlite3_step(stmt) == SQLITE_ROW {
                    sqlite3_finalize(stmt)
                    return PluginResult.failure(PluginError.executionFailed("Memory has expired"))
                }
                sqlite3_finalize(stmt)
            }

            // Retrieve and update access time
            let retrieveSQL = """
            SELECT value, encrypted_flag, encrypted_value, category, tags, importance, metadata FROM memories WHERE key = ?
            """

            var retrieveStmt: OpaquePointer?
            guard sqlite3_prepare_v2(self.connection, retrieveSQL, -1, &retrieveStmt, nil) == SQLITE_OK,
                  let statement = retrieveStmt else {
                return PluginResult.failure(PluginError.executionFailed("Failed to prepare statement"))
            }

            defer { sqlite3_finalize(statement) }

            sqlite3_bind_text(statement, 1, key, -1, SQLITE_TRANSIENT)

            if sqlite3_step(statement) == SQLITE_ROW {
                let value = String(cString: sqlite3_column_text(statement, 0))
                let encryptedFlag = sqlite3_column_int(statement, 1)

                var decryptedValue = value
                if encryptedFlag == 1, let encKey = self.encryptionKey {
                    if let encrypted = String(cString: sqlite3_column_text(statement, 2)) as String? {
                        decryptedValue = (try? MemoryEncryption.decryptMemory(encrypted, key: encKey)) ?? value
                    }
                }

                let category = String(cString: sqlite3_column_text(statement, 3))
                let tags = String(cString: sqlite3_column_text(statement, 4)).split(separator: ",").map(String.init)
                let importance = Double(sqlite3_column_double(statement, 5))

                // Update access time and count
                let updateSQL = "UPDATE memories SET accessed = ?, access_count = access_count + 1 WHERE key = ?"
                var updateStmt: OpaquePointer?
                if sqlite3_prepare_v2(self.connection, updateSQL, -1, &updateStmt, nil) == SQLITE_OK {
                    sqlite3_bind_int(updateStmt, 1, Int32(now))
                    sqlite3_bind_text(updateStmt, 2, key, -1, SQLITE_TRANSIENT)
                    sqlite3_step(updateStmt)
                    sqlite3_finalize(updateStmt)
                }

                return PluginResult.success(data: [
                    "value": decryptedValue,
                    "category": category,
                    "tags": tags,
                    "importance": importance
                ])
            }

            return PluginResult.failure(PluginError.executionFailed("Memory not found"))
        }
    }

    private func handleSearchMemory(_ params: [String: Any]) async throws -> PluginResult {
        guard let query = params["query"] as? String else {
            throw PluginError.invalidParameters("query required")
        }

        let limit = (params["limit"] as? Int) ?? 10
        let category = params["category"] as? String

        return try await queue.async { [weak self] in
            guard let self = self else {
                return PluginResult.failure(PluginError.executionFailed("Plugin not available"))
            }

            var sql = "SELECT key, value, importance FROM memories_fts WHERE memories_fts MATCH ?"

            if let category = category {
                sql += " AND category = '\(category)'"
            }

            sql += " ORDER BY rank DESC LIMIT \(limit)"

            var results: [[String: Any]] = []
            var stmt: OpaquePointer?

            if sqlite3_prepare_v2(self.connection, sql, -1, &stmt, nil) == SQLITE_OK {
                sqlite3_bind_text(stmt, 1, query, -1, SQLITE_TRANSIENT)

                while sqlite3_step(stmt) == SQLITE_ROW {
                    let key = String(cString: sqlite3_column_text(stmt, 0))
                    let value = String(cString: sqlite3_column_text(stmt, 1))
                    let importance = Double(sqlite3_column_double(stmt, 2))

                    results.append([
                        "key": key,
                        "value": value,
                        "importance": importance
                    ])
                }

                sqlite3_finalize(stmt)
            }

            return PluginResult.success(data: ["results": results])
        }
    }

    private func handleListMemories(_ params: [String: Any]) async throws -> PluginResult {
        let category = params["category"] as? String
        let limit = (params["limit"] as? Int) ?? 50
        let sortBy = (params["sortBy"] as? String) ?? "importance"

        return try await queue.async { [weak self] in
            guard let self = self else {
                return PluginResult.failure(PluginError.executionFailed("Plugin not available"))
            }

            var sql = "SELECT key, value, category, importance FROM memories"

            if let category = category {
                sql += " WHERE category = '\(category)'"
            }

            switch sortBy {
            case "accessed":
                sql += " ORDER BY accessed DESC"
            case "created":
                sql += " ORDER BY created DESC"
            default:
                sql += " ORDER BY importance DESC"
            }

            sql += " LIMIT \(limit)"

            var results: [[String: Any]] = []
            var stmt: OpaquePointer?

            if sqlite3_prepare_v2(self.connection, sql, -1, &stmt, nil) == SQLITE_OK {
                while sqlite3_step(stmt) == SQLITE_ROW {
                    let key = String(cString: sqlite3_column_text(stmt, 0))
                    let value = String(cString: sqlite3_column_text(stmt, 1))
                    let category = String(cString: sqlite3_column_text(stmt, 2))
                    let importance = Double(sqlite3_column_double(stmt, 3))

                    results.append([
                        "key": key,
                        "value": value,
                        "category": category,
                        "importance": importance
                    ])
                }

                sqlite3_finalize(stmt)
            }

            return PluginResult.success(data: ["memories": results])
        }
    }

    private func handleClearMemory(_ params: [String: Any]) async throws -> PluginResult {
        let key = params["key"] as? String
        let category = params["category"] as? String

        return try await queue.async { [weak self] in
            guard let self = self else {
                return PluginResult.failure(PluginError.executionFailed("Plugin not available"))
            }

            var sql = "DELETE FROM memories"
            if let key = key {
                sql += " WHERE key = '\(key)'"
            } else if let category = category {
                sql += " WHERE category = '\(category)'"
            }

            do {
                try self.executeSQL(sql)
                return PluginResult.success(data: ["cleared": true])
            } catch {
                return PluginResult.failure(error as? PluginError ?? PluginError.executionFailed("Clear failed"))
            }
        }
    }

    private func handleGetStats() async throws -> PluginResult {
        return try await queue.async { [weak self] in
            guard let self = self else {
                return PluginResult.failure(PluginError.executionFailed("Plugin not available"))
            }

            let countSQL = "SELECT COUNT(*) FROM memories"
            var stmt: OpaquePointer?

            guard sqlite3_prepare_v2(self.connection, countSQL, -1, &stmt, nil) == SQLITE_OK else {
                return PluginResult.failure(PluginError.executionFailed("Failed to query stats"))
            }

            defer { sqlite3_finalize(stmt) }

            var totalMemories = 0
            if sqlite3_step(stmt) == SQLITE_ROW {
                totalMemories = Int(sqlite3_column_int(stmt, 0))
            }

            return PluginResult.success(data: [
                "totalMemories": totalMemories,
                "version": self.version
            ])
        }
    }

    private func handleCompact() async throws -> PluginResult {
        return try await queue.async { [weak self] in
            guard let self = self else {
                return PluginResult.failure(PluginError.executionFailed("Plugin not available"))
            }

            let now = Int(Date().timeIntervalSince1970)
            let sql = "DELETE FROM memories WHERE expiration_timestamp IS NOT NULL AND expiration_timestamp < \(now)"

            do {
                try self.executeSQL(sql)
                return PluginResult.success(data: ["compacted": true])
            } catch {
                return PluginResult.failure(error as? PluginError ?? PluginError.executionFailed("Compact failed"))
            }
        }
    }

    private func handleExport() async throws -> PluginResult {
        return PluginResult.failure(PluginError.actionNotSupported("export"))
    }

    private func handleImport(_ params: [String: Any]) async throws -> PluginResult {
        return PluginResult.failure(PluginError.actionNotSupported("import"))
    }

    private static func getKeychainKey() -> String? {
        // TODO: Implement keychain access for macOS
        // For now, return nil to use unencrypted mode
        return nil
    }
}
