import Foundation
import CSQLite

// SQLite constant for transient text binding
private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

/// Errors that can occur during database operations
public enum DatabaseError: Error, LocalizedError {
    case connectionFailed(String)
    case queryFailed(String)
    case invalidData(String)
    case notInitialized
    
    public var errorDescription: String? {
        switch self {
        case .connectionFailed(let message):
            return "Database connection failed: \(message)"
        case .queryFailed(let message):
            return "Query failed: \(message)"
        case .invalidData(let message):
            return "Invalid data: \(message)"
        case .notInitialized:
            return "Database not initialized"
        }
    }
}

/// Manages SQLite database operations for AI suggestions, user sessions, and configurations
public class DatabaseManager {
    
    private var db: OpaquePointer?
    
    private let databasePath: String
    private var isInitialized = false
    
    // MARK: - Initialization
    
    /// Initialize with a custom database path
    public init(databasePath: String? = nil) {
        if let path = databasePath {
            self.databasePath = path
        } else {
            // Default path in user's documents directory
            let fileManager = FileManager.default
            let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.path ?? ""
            self.databasePath = documentsPath + "/writersapp.db"
        }
    }
    
    deinit {
        close()
    }
    
    // MARK: - Connection Management
    
    /// Opens the database connection and creates tables if needed
    public func initialize() throws {
        guard sqlite3_open(databasePath, &db) == SQLITE_OK else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.connectionFailed(errorMessage)
        }
        
        try createTables()
        try createIndexes()
        isInitialized = true
    }
    
    /// Closes the database connection
    public func close() {
        
        if let db = db {
            sqlite3_close(db)
            self.db = nil
        }
        isInitialized = false
        
    }
    
    // MARK: - Schema Creation
    
    private func createTables() throws {
        
        // Create AI_Suggestions table
        let createAISuggestionsTable = """
        CREATE TABLE IF NOT EXISTS AI_Suggestions (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            document_id TEXT,
            tool_used TEXT NOT NULL,
            prompt TEXT NOT NULL,
            response TEXT NOT NULL,
            timestamp REAL NOT NULL,
            is_applied INTEGER DEFAULT 0
        );
        """
        
        // Create User_Sessions table
        let createUserSessionsTable = """
        CREATE TABLE IF NOT EXISTS User_Sessions (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            start_time REAL NOT NULL,
            end_time REAL,
            duration_seconds INTEGER,
            words_written INTEGER DEFAULT 0,
            ai_interactions INTEGER DEFAULT 0,
            multitasking_mode TEXT
        );
        """
        
        // Create AI_Configurations table
        let createAIConfigurationsTable = """
        CREATE TABLE IF NOT EXISTS AI_Configurations (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            api_key TEXT NOT NULL,
            model TEXT NOT NULL,
            max_tokens INTEGER DEFAULT 4096,
            temperature REAL DEFAULT 0.7,
            created_at REAL NOT NULL,
            updated_at REAL NOT NULL
        );
        """
        
        try execute(createAISuggestionsTable)
        try execute(createUserSessionsTable)
        try execute(createAIConfigurationsTable)
        
    }
    
    private func createIndexes() throws {
        
        // Index for frequently queried columns
        let indexes = [
            "CREATE INDEX IF NOT EXISTS idx_ai_suggestions_tool ON AI_Suggestions(tool_used);",
            "CREATE INDEX IF NOT EXISTS idx_ai_suggestions_user ON AI_Suggestions(user_id);",
            "CREATE INDEX IF NOT EXISTS idx_ai_suggestions_timestamp ON AI_Suggestions(timestamp);",
            "CREATE INDEX IF NOT EXISTS idx_user_sessions_user ON User_Sessions(user_id);",
            "CREATE INDEX IF NOT EXISTS idx_user_sessions_start ON User_Sessions(start_time);",
            "CREATE INDEX IF NOT EXISTS idx_ai_configs_user ON AI_Configurations(user_id);"
        ]
        
        for index in indexes {
            try execute(index)
        }
        
    }
    
    // MARK: - Query Execution
    
    private func execute(_ sql: String) throws {
        guard let db = db else {
            throw DatabaseError.notInitialized
        }
        
        var statement: OpaquePointer?
        defer {
            if statement != nil {
                sqlite3_finalize(statement)
            }
        }
        
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.queryFailed("Prepare failed: \(errorMessage)")
        }
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.queryFailed("Step failed: \(errorMessage)")
        }
        
    }
    
    // MARK: - AI Suggestions Operations
    
    /// Inserts a new AI suggestion
    public func insertAISuggestion(_ suggestion: AISuggestion) throws {
        
        guard isInitialized, let db = db else {
            throw DatabaseError.notInitialized
        }
        
        let sql = """
        INSERT INTO AI_Suggestions (id, user_id, document_id, tool_used, prompt, response, timestamp, is_applied)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?);
        """
        
        var statement: OpaquePointer?
        defer {
            if statement != nil {
                sqlite3_finalize(statement)
            }
        }
        
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.queryFailed("Prepare failed: \(errorMessage)")
        }
        
        sqlite3_bind_text(statement, 1, suggestion.id.uuidString, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 2, suggestion.userId.uuidString, -1, SQLITE_TRANSIENT)
        if let documentId = suggestion.documentId {
            sqlite3_bind_text(statement, 3, documentId.uuidString, -1, SQLITE_TRANSIENT)
        } else {
            sqlite3_bind_null(statement, 3)
        }
        sqlite3_bind_text(statement, 4, suggestion.toolUsed, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 5, suggestion.prompt, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 6, suggestion.response, -1, SQLITE_TRANSIENT)
        sqlite3_bind_double(statement, 7, suggestion.timestamp.timeIntervalSince1970)
        sqlite3_bind_int(statement, 8, suggestion.isApplied ? 1 : 0)
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.queryFailed("Insert failed: \(errorMessage)")
        }
        
    }
    
    /// Retrieves AI suggestions with pagination
    public func getAISuggestions(userId: UUID, limit: Int = 50, offset: Int = 0) throws -> [AISuggestion] {
        
        guard isInitialized, let db = db else {
            throw DatabaseError.notInitialized
        }
        
        let sql = """
        SELECT id, user_id, document_id, tool_used, prompt, response, timestamp, is_applied
        FROM AI_Suggestions
        WHERE user_id = ?
        ORDER BY timestamp DESC
        LIMIT ? OFFSET ?;
        """
        
        var statement: OpaquePointer?
        defer {
            if statement != nil {
                sqlite3_finalize(statement)
            }
        }
        
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.queryFailed("Prepare failed: \(errorMessage)")
        }
        
        sqlite3_bind_text(statement, 1, userId.uuidString, -1, SQLITE_TRANSIENT)
        sqlite3_bind_int(statement, 2, Int32(limit))
        sqlite3_bind_int(statement, 3, Int32(offset))
        
        var suggestions: [AISuggestion] = []
        
        while sqlite3_step(statement) == SQLITE_ROW {
            guard let id = UUID(uuidString: String(cString: sqlite3_column_text(statement, 0))),
                  let userId = UUID(uuidString: String(cString: sqlite3_column_text(statement, 1))) else {
                continue
            }
            
            let documentIdString = sqlite3_column_type(statement, 2) != SQLITE_NULL ?
                String(cString: sqlite3_column_text(statement, 2)) : nil
            let documentId = documentIdString != nil ? UUID(uuidString: documentIdString!) : nil
            
            let toolUsed = String(cString: sqlite3_column_text(statement, 3))
            let prompt = String(cString: sqlite3_column_text(statement, 4))
            let response = String(cString: sqlite3_column_text(statement, 5))
            let timestamp = Date(timeIntervalSince1970: sqlite3_column_double(statement, 6))
            let isApplied = sqlite3_column_int(statement, 7) == 1
            
            let suggestion = AISuggestion(
                id: id,
                userId: userId,
                documentId: documentId,
                toolUsed: toolUsed,
                prompt: prompt,
                response: response,
                timestamp: timestamp,
                isApplied: isApplied
            )
            suggestions.append(suggestion)
        }
        
        return suggestions
        
        
    }
    
    /// Updates an AI suggestion
    public func updateAISuggestion(_ suggestion: AISuggestion) throws {
        
        guard isInitialized, let db = db else {
            throw DatabaseError.notInitialized
        }
        
        let sql = """
        UPDATE AI_Suggestions
        SET is_applied = ?, response = ?
        WHERE id = ?;
        """
        
        var statement: OpaquePointer?
        defer {
            if statement != nil {
                sqlite3_finalize(statement)
            }
        }
        
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.queryFailed("Prepare failed: \(errorMessage)")
        }
        
        sqlite3_bind_int(statement, 1, suggestion.isApplied ? 1 : 0)
        sqlite3_bind_text(statement, 2, suggestion.response, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 3, suggestion.id.uuidString, -1, SQLITE_TRANSIENT)
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.queryFailed("Update failed: \(errorMessage)")
        }
        
    }
    
    /// Deletes an AI suggestion by ID
    public func deleteAISuggestion(id: UUID) throws {
        
        guard isInitialized, let db = db else {
            throw DatabaseError.notInitialized
        }
        
        let sql = "DELETE FROM AI_Suggestions WHERE id = ?;"
        
        var statement: OpaquePointer?
        defer {
            if statement != nil {
                sqlite3_finalize(statement)
            }
        }
        
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.queryFailed("Prepare failed: \(errorMessage)")
        }
        
        sqlite3_bind_text(statement, 1, id.uuidString, -1, SQLITE_TRANSIENT)
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.queryFailed("Delete failed: \(errorMessage)")
        }
        
    }
    
    /// Filters AI suggestions by tool
    public func filterAISuggestionsByTool(userId: UUID, tool: String) throws -> [AISuggestion] {
        
        guard isInitialized, let db = db else {
            throw DatabaseError.notInitialized
        }
        
        let sql = """
        SELECT id, user_id, document_id, tool_used, prompt, response, timestamp, is_applied
        FROM AI_Suggestions
        WHERE user_id = ? AND tool_used = ?
        ORDER BY timestamp DESC;
        """
        
        var statement: OpaquePointer?
        defer {
            if statement != nil {
                sqlite3_finalize(statement)
            }
        }
        
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.queryFailed("Prepare failed: \(errorMessage)")
        }
        
        sqlite3_bind_text(statement, 1, userId.uuidString, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 2, tool, -1, SQLITE_TRANSIENT)
        
        var suggestions: [AISuggestion] = []
        
        while sqlite3_step(statement) == SQLITE_ROW {
            guard let id = UUID(uuidString: String(cString: sqlite3_column_text(statement, 0))),
                  let userId = UUID(uuidString: String(cString: sqlite3_column_text(statement, 1))) else {
                continue
            }
            
            let documentIdString = sqlite3_column_type(statement, 2) != SQLITE_NULL ?
                String(cString: sqlite3_column_text(statement, 2)) : nil
            let documentId = documentIdString != nil ? UUID(uuidString: documentIdString!) : nil
            
            let toolUsed = String(cString: sqlite3_column_text(statement, 3))
            let prompt = String(cString: sqlite3_column_text(statement, 4))
            let response = String(cString: sqlite3_column_text(statement, 5))
            let timestamp = Date(timeIntervalSince1970: sqlite3_column_double(statement, 6))
            let isApplied = sqlite3_column_int(statement, 7) == 1
            
            let suggestion = AISuggestion(
                id: id,
                userId: userId,
                documentId: documentId,
                toolUsed: toolUsed,
                prompt: prompt,
                response: response,
                timestamp: timestamp,
                isApplied: isApplied
            )
            suggestions.append(suggestion)
        }
        
        return suggestions
        
        
    }
    
    /// Gets AI tool usage statistics (grouping and counting)
    public func getAIToolUsageStats(userId: UUID) throws -> [AIToolUsageStats] {
        
        guard isInitialized, let db = db else {
            throw DatabaseError.notInitialized
        }
        
        let sql = """
        SELECT tool_used, COUNT(*) as usage_count, MAX(timestamp) as last_used
        FROM AI_Suggestions
        WHERE user_id = ?
        GROUP BY tool_used
        ORDER BY usage_count DESC;
        """
        
        var statement: OpaquePointer?
        defer {
            if statement != nil {
                sqlite3_finalize(statement)
            }
        }
        
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.queryFailed("Prepare failed: \(errorMessage)")
        }
        
        sqlite3_bind_text(statement, 1, userId.uuidString, -1, SQLITE_TRANSIENT)
        
        var stats: [AIToolUsageStats] = []
        
        while sqlite3_step(statement) == SQLITE_ROW {
            let toolName = String(cString: sqlite3_column_text(statement, 0))
            let usageCount = Int(sqlite3_column_int(statement, 1))
            let lastUsedTimestamp = sqlite3_column_double(statement, 2)
            let lastUsed = Date(timeIntervalSince1970: lastUsedTimestamp)
            
            stats.append(AIToolUsageStats(toolName: toolName, usageCount: usageCount, lastUsed: lastUsed))
        }
        
        return stats
        
        
    }
    
    /// Joins AI suggestions with configurations (example of JOIN operation)
    public func getAISuggestionsWithConfig(userId: UUID) throws -> [(suggestion: AISuggestion, modelUsed: String)] {
        
        guard isInitialized, let db = db else {
            throw DatabaseError.notInitialized
        }
        
        let sql = """
        SELECT s.id, s.user_id, s.document_id, s.tool_used, s.prompt, s.response, s.timestamp, s.is_applied, c.model
        FROM AI_Suggestions s
        LEFT JOIN AI_Configurations c ON s.user_id = c.user_id
        WHERE s.user_id = ?
        ORDER BY s.timestamp DESC
        LIMIT 100;
        """
        
        var statement: OpaquePointer?
        defer {
            if statement != nil {
                sqlite3_finalize(statement)
            }
        }
        
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.queryFailed("Prepare failed: \(errorMessage)")
        }
        
        sqlite3_bind_text(statement, 1, userId.uuidString, -1, SQLITE_TRANSIENT)
        
        var results: [(suggestion: AISuggestion, modelUsed: String)] = []
        
        while sqlite3_step(statement) == SQLITE_ROW {
            guard let id = UUID(uuidString: String(cString: sqlite3_column_text(statement, 0))),
                  let userId = UUID(uuidString: String(cString: sqlite3_column_text(statement, 1))) else {
                continue
            }
            
            let documentIdString = sqlite3_column_type(statement, 2) != SQLITE_NULL ?
                String(cString: sqlite3_column_text(statement, 2)) : nil
            let documentId = documentIdString != nil ? UUID(uuidString: documentIdString!) : nil
            
            let toolUsed = String(cString: sqlite3_column_text(statement, 3))
            let prompt = String(cString: sqlite3_column_text(statement, 4))
            let response = String(cString: sqlite3_column_text(statement, 5))
            let timestamp = Date(timeIntervalSince1970: sqlite3_column_double(statement, 6))
            let isApplied = sqlite3_column_int(statement, 7) == 1
            
            let modelUsed = sqlite3_column_type(statement, 8) != SQLITE_NULL ?
                String(cString: sqlite3_column_text(statement, 8)) : "unknown"
            
            let suggestion = AISuggestion(
                id: id,
                userId: userId,
                documentId: documentId,
                toolUsed: toolUsed,
                prompt: prompt,
                response: response,
                timestamp: timestamp,
                isApplied: isApplied
            )
            results.append((suggestion: suggestion, modelUsed: modelUsed))
        }
        
        return results
        
        
    }
    
    // MARK: - User Sessions Operations
    
    /// Inserts a new user session
    public func insertUserSession(_ session: UserSession) throws {
        
        guard isInitialized, let db = db else {
            throw DatabaseError.notInitialized
        }
        
        let sql = """
        INSERT INTO User_Sessions (id, user_id, start_time, end_time, duration_seconds, words_written, ai_interactions, multitasking_mode)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?);
        """
        
        var statement: OpaquePointer?
        defer {
            if statement != nil {
                sqlite3_finalize(statement)
            }
        }
        
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.queryFailed("Prepare failed: \(errorMessage)")
        }
        
        sqlite3_bind_text(statement, 1, session.id.uuidString, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 2, session.userId.uuidString, -1, SQLITE_TRANSIENT)
        sqlite3_bind_double(statement, 3, session.startTime.timeIntervalSince1970)
        
        if let endTime = session.endTime {
            sqlite3_bind_double(statement, 4, endTime.timeIntervalSince1970)
        } else {
            sqlite3_bind_null(statement, 4)
        }
        
        if let duration = session.durationSeconds {
            sqlite3_bind_int(statement, 5, Int32(duration))
        } else {
            sqlite3_bind_null(statement, 5)
        }
        
        sqlite3_bind_int(statement, 6, Int32(session.wordsWritten))
        sqlite3_bind_int(statement, 7, Int32(session.aiInteractions))
        
        if let mode = session.multitaskingMode {
            sqlite3_bind_text(statement, 8, mode, -1, SQLITE_TRANSIENT)
        } else {
            sqlite3_bind_null(statement, 8)
        }
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.queryFailed("Insert failed: \(errorMessage)")
        }
        
    }
    
    /// Updates a user session
    public func updateUserSession(_ session: UserSession) throws {
        
        guard isInitialized, let db = db else {
            throw DatabaseError.notInitialized
        }
        
        let sql = """
        UPDATE User_Sessions
        SET end_time = ?, duration_seconds = ?, words_written = ?, ai_interactions = ?, multitasking_mode = ?
        WHERE id = ?;
        """
        
        var statement: OpaquePointer?
        defer {
            if statement != nil {
                sqlite3_finalize(statement)
            }
        }
        
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.queryFailed("Prepare failed: \(errorMessage)")
        }
        
        if let endTime = session.endTime {
            sqlite3_bind_double(statement, 1, endTime.timeIntervalSince1970)
        } else {
            sqlite3_bind_null(statement, 1)
        }
        
        if let duration = session.durationSeconds {
            sqlite3_bind_int(statement, 2, Int32(duration))
        } else {
            sqlite3_bind_null(statement, 2)
        }
        
        sqlite3_bind_int(statement, 3, Int32(session.wordsWritten))
        sqlite3_bind_int(statement, 4, Int32(session.aiInteractions))
        
        if let mode = session.multitaskingMode {
            sqlite3_bind_text(statement, 5, mode, -1, SQLITE_TRANSIENT)
        } else {
            sqlite3_bind_null(statement, 5)
        }
        
        sqlite3_bind_text(statement, 6, session.id.uuidString, -1, SQLITE_TRANSIENT)
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.queryFailed("Update failed: \(errorMessage)")
        }
        
    }
    
    /// Gets user sessions for a specific user, sorted by duration
    public func getUserSessions(userId: UUID, sortByDuration: Bool = false) throws -> [UserSession] {
        
        guard isInitialized, let db = db else {
            throw DatabaseError.notInitialized
        }
        
        let orderClause = sortByDuration ? "ORDER BY duration_seconds DESC" : "ORDER BY start_time DESC"
        let sql = """
        SELECT id, user_id, start_time, end_time, duration_seconds, words_written, ai_interactions, multitasking_mode
        FROM User_Sessions
        WHERE user_id = ?
        \(orderClause);
        """
        
        var statement: OpaquePointer?
        defer {
            if statement != nil {
                sqlite3_finalize(statement)
            }
        }
        
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.queryFailed("Prepare failed: \(errorMessage)")
        }
        
        sqlite3_bind_text(statement, 1, userId.uuidString, -1, SQLITE_TRANSIENT)
        
        var sessions: [UserSession] = []
        
        while sqlite3_step(statement) == SQLITE_ROW {
            guard let id = UUID(uuidString: String(cString: sqlite3_column_text(statement, 0))),
                  let userId = UUID(uuidString: String(cString: sqlite3_column_text(statement, 1))) else {
                continue
            }
            
            let startTime = Date(timeIntervalSince1970: sqlite3_column_double(statement, 2))
            
            let endTime = sqlite3_column_type(statement, 3) != SQLITE_NULL ?
                Date(timeIntervalSince1970: sqlite3_column_double(statement, 3)) : nil
            
            let durationSeconds = sqlite3_column_type(statement, 4) != SQLITE_NULL ?
                Int(sqlite3_column_int(statement, 4)) : nil
            
            let wordsWritten = Int(sqlite3_column_int(statement, 5))
            let aiInteractions = Int(sqlite3_column_int(statement, 6))
            
            let multitaskingMode = sqlite3_column_type(statement, 7) != SQLITE_NULL ?
                String(cString: sqlite3_column_text(statement, 7)) : nil
            
            let session = UserSession(
                id: id,
                userId: userId,
                startTime: startTime,
                endTime: endTime,
                durationSeconds: durationSeconds,
                wordsWritten: wordsWritten,
                aiInteractions: aiInteractions,
                multitaskingMode: multitaskingMode
            )
            sessions.append(session)
        }
        
        return sessions
        
        
    }
    
    /// Gets session statistics (aggregation functions)
    public func getSessionStats(userId: UUID) throws -> SessionStats {
        
        guard isInitialized, let db = db else {
            throw DatabaseError.notInitialized
        }
        
        let sql = """
        SELECT
            COUNT(*) as total_sessions,
            SUM(duration_seconds) as total_duration,
            AVG(duration_seconds) as avg_duration,
            MIN(start_time) as earliest,
            MAX(start_time) as latest
        FROM User_Sessions
        WHERE user_id = ? AND duration_seconds IS NOT NULL;
        """
        
        var statement: OpaquePointer?
        defer {
            if statement != nil {
                sqlite3_finalize(statement)
            }
        }
        
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.queryFailed("Prepare failed: \(errorMessage)")
        }
        
        sqlite3_bind_text(statement, 1, userId.uuidString, -1, SQLITE_TRANSIENT)
        
        guard sqlite3_step(statement) == SQLITE_ROW else {
            return SessionStats(totalSessions: 0, totalDurationSeconds: 0, averageDurationSeconds: 0, earliestSession: nil, latestSession: nil)
        }
        
        let totalSessions = Int(sqlite3_column_int(statement, 0))
        let totalDuration = Int(sqlite3_column_int(statement, 1))
        let avgDuration = sqlite3_column_double(statement, 2)
        
        let earliest = sqlite3_column_type(statement, 3) != SQLITE_NULL ?
            Date(timeIntervalSince1970: sqlite3_column_double(statement, 3)) : nil
        let latest = sqlite3_column_type(statement, 4) != SQLITE_NULL ?
            Date(timeIntervalSince1970: sqlite3_column_double(statement, 4)) : nil
        
        return SessionStats(
            totalSessions: totalSessions,
            totalDurationSeconds: totalDuration,
            averageDurationSeconds: avgDuration,
            earliestSession: earliest,
            latestSession: latest
        )
        
        return SessionStats(totalSessions: 0, totalDurationSeconds: 0, averageDurationSeconds: 0, earliestSession: nil, latestSession: nil)
        
    }
    
    /// Filters sessions by multitasking mode
    public func filterSessionsByMode(userId: UUID, mode: String) throws -> [UserSession] {
        
        guard isInitialized, let db = db else {
            throw DatabaseError.notInitialized
        }
        
        let sql = """
        SELECT id, user_id, start_time, end_time, duration_seconds, words_written, ai_interactions, multitasking_mode
        FROM User_Sessions
        WHERE user_id = ? AND multitasking_mode = ?
        ORDER BY start_time DESC;
        """
        
        var statement: OpaquePointer?
        defer {
            if statement != nil {
                sqlite3_finalize(statement)
            }
        }
        
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.queryFailed("Prepare failed: \(errorMessage)")
        }
        
        sqlite3_bind_text(statement, 1, userId.uuidString, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 2, mode, -1, SQLITE_TRANSIENT)
        
        var sessions: [UserSession] = []
        
        while sqlite3_step(statement) == SQLITE_ROW {
            guard let id = UUID(uuidString: String(cString: sqlite3_column_text(statement, 0))),
                  let userId = UUID(uuidString: String(cString: sqlite3_column_text(statement, 1))) else {
                continue
            }
            
            let startTime = Date(timeIntervalSince1970: sqlite3_column_double(statement, 2))
            
            let endTime = sqlite3_column_type(statement, 3) != SQLITE_NULL ?
                Date(timeIntervalSince1970: sqlite3_column_double(statement, 3)) : nil
            
            let durationSeconds = sqlite3_column_type(statement, 4) != SQLITE_NULL ?
                Int(sqlite3_column_int(statement, 4)) : nil
            
            let wordsWritten = Int(sqlite3_column_int(statement, 5))
            let aiInteractions = Int(sqlite3_column_int(statement, 6))
            
            let multitaskingMode = sqlite3_column_type(statement, 7) != SQLITE_NULL ?
                String(cString: sqlite3_column_text(statement, 7)) : nil
            
            let session = UserSession(
                id: id,
                userId: userId,
                startTime: startTime,
                endTime: endTime,
                durationSeconds: durationSeconds,
                wordsWritten: wordsWritten,
                aiInteractions: aiInteractions,
                multitaskingMode: multitaskingMode
            )
            sessions.append(session)
        }
        
        return sessions
        
        
    }
    
    // MARK: - AI Configurations Operations
    
    /// Saves or updates an AI configuration
    public func saveAIConfiguration(userId: UUID, configuration: AIConfiguration) throws {
        
        guard isInitialized, let db = db else {
            throw DatabaseError.notInitialized
        }
        
        let now = Date().timeIntervalSince1970
        
        let sql = """
        INSERT OR REPLACE INTO AI_Configurations (id, user_id, api_key, model, max_tokens, temperature, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?);
        """
        
        var statement: OpaquePointer?
        defer {
            if statement != nil {
                sqlite3_finalize(statement)
            }
        }
        
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.queryFailed("Prepare failed: \(errorMessage)")
        }
        
        sqlite3_bind_text(statement, 1, userId.uuidString, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 2, userId.uuidString, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 3, configuration.apiKey, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 4, configuration.model.rawValue, -1, SQLITE_TRANSIENT)
        sqlite3_bind_int(statement, 5, Int32(configuration.maxTokens))
        sqlite3_bind_double(statement, 6, configuration.temperature)
        sqlite3_bind_double(statement, 7, now)
        sqlite3_bind_double(statement, 8, now)
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.queryFailed("Insert/Update failed: \(errorMessage)")
        }
        
    }
    
    /// Gets AI configuration for a user
    public func getAIConfiguration(userId: UUID) throws -> AIConfiguration? {
        
        guard isInitialized, let db = db else {
            throw DatabaseError.notInitialized
        }
        
        let sql = """
        SELECT api_key, model, max_tokens, temperature
        FROM AI_Configurations
        WHERE user_id = ?
        LIMIT 1;
        """
        
        var statement: OpaquePointer?
        defer {
            if statement != nil {
                sqlite3_finalize(statement)
            }
        }
        
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.queryFailed("Prepare failed: \(errorMessage)")
        }
        
        sqlite3_bind_text(statement, 1, userId.uuidString, -1, SQLITE_TRANSIENT)
        
        guard sqlite3_step(statement) == SQLITE_ROW else {
            return nil
        }
        
        let apiKey = String(cString: sqlite3_column_text(statement, 0))
        let modelString = String(cString: sqlite3_column_text(statement, 1))
        let maxTokens = Int(sqlite3_column_int(statement, 2))
        let temperature = sqlite3_column_double(statement, 3)
        
        guard let model = AIModel(rawValue: modelString) else {
            return nil
        }
        
        return AIConfiguration(
            apiKey: apiKey,
            model: model,
            maxTokens: maxTokens,
            temperature: temperature
        )
        
        
    }
}
