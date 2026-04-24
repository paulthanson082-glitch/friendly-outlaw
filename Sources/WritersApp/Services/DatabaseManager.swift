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
    
    /// Ensures all required database tables for the application exist by creating them if missing.
    /// 
    /// Creates schema for AI suggestions, user sessions, AI configurations, traces, observations, issues,
    /// and version control (branches, commits, document snapshots).
    /// - Throws: `DatabaseError.queryFailed` if any CREATE TABLE statement fails.
    
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
            user_id TEXT PRIMARY KEY,
            api_key TEXT NOT NULL,
            model TEXT NOT NULL,
            max_tokens INTEGER DEFAULT 4096,
            temperature REAL DEFAULT 0.7,
            created_at REAL NOT NULL,
            updated_at REAL NOT NULL
        );
        """
        
        // Create Traces table
        let createTracesTable = """
        CREATE TABLE IF NOT EXISTS Traces (
            id TEXT PRIMARY KEY,
            session_id TEXT NOT NULL,
            name TEXT NOT NULL,
            start_time REAL NOT NULL,
            end_time REAL,
            metadata TEXT
        );
        """

        // Create Observations table
        let createObservationsTable = """
        CREATE TABLE IF NOT EXISTS Observations (
            id TEXT PRIMARY KEY,
            trace_id TEXT NOT NULL,
            name TEXT NOT NULL,
            start_time REAL NOT NULL,
            end_time REAL,
            input TEXT,
            output TEXT,
            status_message TEXT,
            FOREIGN KEY (trace_id) REFERENCES Traces(id)
        );
        """

        // Create Issues table
        let createIssuesTable = """
        CREATE TABLE IF NOT EXISTS Issues (
            id TEXT PRIMARY KEY,
            document_id TEXT NOT NULL,
            title TEXT NOT NULL,
            description TEXT NOT NULL,
            status TEXT NOT NULL,
            priority TEXT NOT NULL,
            created REAL NOT NULL,
            modified REAL NOT NULL,
            resolved_at REAL,
            tags TEXT,
            notes TEXT
        );
        """

        // Create version control tables
        let createVCBranchesTable = """
        CREATE TABLE IF NOT EXISTS vc_branches (
            id TEXT PRIMARY KEY,
            name TEXT UNIQUE NOT NULL,
            head_commit_id TEXT,
            created_at REAL NOT NULL,
            is_active INTEGER DEFAULT 0
        );
        """

        let createVCCommitsTable = """
        CREATE TABLE IF NOT EXISTS vc_commits (
            id TEXT PRIMARY KEY,
            branch_id TEXT NOT NULL,
            message TEXT NOT NULL,
            author_id TEXT,
            timestamp REAL NOT NULL,
            parent_commit_id TEXT,
            second_parent_commit_id TEXT,
            FOREIGN KEY (branch_id) REFERENCES vc_branches(id)
        );
        """

        let createVCSnapshotsTable = """
        CREATE TABLE IF NOT EXISTS vc_document_snapshots (
            id TEXT PRIMARY KEY,
            commit_id TEXT NOT NULL,
            document_id TEXT NOT NULL,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            category TEXT NOT NULL,
            word_count INTEGER DEFAULT 0,
            captured_at REAL NOT NULL,
            FOREIGN KEY (commit_id) REFERENCES vc_commits(id)
        );
        """

        let createGiftCardBundlesTable = """
        CREATE TABLE IF NOT EXISTS GiftCardBundles (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT NOT NULL,
            price TEXT NOT NULL,
            bundle_type TEXT NOT NULL,
            included_template_ids TEXT,
            ai_credits INTEGER NOT NULL,
            expiration_days INTEGER NOT NULL,
            created_at REAL NOT NULL,
            modified_at REAL NOT NULL
        );
        """

        let createGiftCardsTable = """
        CREATE TABLE IF NOT EXISTS GiftCards (
            id TEXT PRIMARY KEY,
            code TEXT UNIQUE NOT NULL,
            bundle_id TEXT NOT NULL,
            status TEXT NOT NULL,
            redeemed_by_user_id TEXT,
            redeemed_at REAL,
            created_at REAL NOT NULL,
            expires_at REAL,
            FOREIGN KEY (bundle_id) REFERENCES GiftCardBundles(id)
        );
        """

        try execute(createAISuggestionsTable)
        try execute(createUserSessionsTable)
        try execute(createAIConfigurationsTable)
        try execute(createTracesTable)
        try execute(createObservationsTable)
        try execute(createIssuesTable)
        try execute(createVCBranchesTable)
        try execute(createVCCommitsTable)
        try execute(createVCSnapshotsTable)
        try execute(createGiftCardBundlesTable)
        try execute(createGiftCardsTable)

    }
    
    /// Creates the database indexes used to optimize common queries across tables.
    /// 
    /// Executes a predefined set of `CREATE INDEX IF NOT EXISTS` statements for
    /// AI_Suggestions, User_Sessions, AI_Configurations, Traces, Observations,
    /// Issues, and version control tables (vc_branches, vc_commits,
    /// vc_document_snapshots).
    /// - Throws: `DatabaseError.queryFailed` if executing any index statement fails.
    private func createIndexes() throws {
        
        // Index for frequently queried columns
        let indexes = [
            "CREATE INDEX IF NOT EXISTS idx_ai_suggestions_tool ON AI_Suggestions(tool_used);",
            "CREATE INDEX IF NOT EXISTS idx_ai_suggestions_user ON AI_Suggestions(user_id);",
            "CREATE INDEX IF NOT EXISTS idx_ai_suggestions_timestamp ON AI_Suggestions(timestamp);",
            "CREATE INDEX IF NOT EXISTS idx_user_sessions_user ON User_Sessions(user_id);",
            "CREATE INDEX IF NOT EXISTS idx_user_sessions_start ON User_Sessions(start_time);",
            "CREATE INDEX IF NOT EXISTS idx_ai_configs_user ON AI_Configurations(user_id);",
            "CREATE INDEX IF NOT EXISTS idx_traces_session ON Traces(session_id);",
            "CREATE INDEX IF NOT EXISTS idx_traces_start ON Traces(start_time);",
            "CREATE INDEX IF NOT EXISTS idx_observations_trace ON Observations(trace_id);",
            "CREATE INDEX IF NOT EXISTS idx_observations_name ON Observations(name);",
            "CREATE INDEX IF NOT EXISTS idx_issues_document ON Issues(document_id);",
            "CREATE INDEX IF NOT EXISTS idx_issues_status ON Issues(status);",
            "CREATE INDEX IF NOT EXISTS idx_issues_priority ON Issues(priority);",
            "CREATE INDEX IF NOT EXISTS idx_issues_created ON Issues(created);",
            "CREATE INDEX IF NOT EXISTS idx_vc_branches_name ON vc_branches(name);",
            "CREATE INDEX IF NOT EXISTS idx_vc_commits_branch ON vc_commits(branch_id);",
            "CREATE INDEX IF NOT EXISTS idx_vc_commits_timestamp ON vc_commits(timestamp);",
            "CREATE INDEX IF NOT EXISTS idx_vc_snapshots_commit ON vc_document_snapshots(commit_id);",
            "CREATE INDEX IF NOT EXISTS idx_vc_snapshots_document ON vc_document_snapshots(document_id);",
            "CREATE INDEX IF NOT EXISTS idx_vc_snapshots_captured ON vc_document_snapshots(captured_at);",
            "CREATE INDEX IF NOT EXISTS idx_gift_card_code ON GiftCards(code);",
            "CREATE INDEX IF NOT EXISTS idx_gift_card_status ON GiftCards(status);",
            "CREATE INDEX IF NOT EXISTS idx_gift_card_bundle ON GiftCards(bundle_id);",
            "CREATE INDEX IF NOT EXISTS idx_bundle_type ON GiftCardBundles(bundle_type);"
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
        INSERT OR REPLACE INTO AI_Configurations (user_id, api_key, model, max_tokens, temperature, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?);
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
        // Security: API key is not persisted to the database to prevent plaintext exposure.
        sqlite3_bind_text(statement, 2, "", -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 3, configuration.model.rawValue, -1, SQLITE_TRANSIENT)
        sqlite3_bind_int(statement, 4, Int32(configuration.maxTokens))
        sqlite3_bind_double(statement, 5, configuration.temperature)
        sqlite3_bind_double(statement, 6, now)
        sqlite3_bind_double(statement, 7, now)
        
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
        
        // Read api_key from column 0, model from column 1, etc.
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

    // MARK: - Trace Operations

    /// Inserts a new trace
    public func insertTrace(_ trace: Trace) throws {
        guard isInitialized, let db = db else {
            throw DatabaseError.notInitialized
        }

        let sql = """
        INSERT INTO Traces (id, session_id, name, start_time, end_time, metadata)
        VALUES (?, ?, ?, ?, ?, ?);
        """

        var statement: OpaquePointer?
        defer { if statement != nil { sqlite3_finalize(statement) } }

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.queryFailed("Prepare failed: \(errorMessage)")
        }

        sqlite3_bind_text(statement, 1, trace.id.uuidString, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 2, trace.sessionId, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 3, trace.name, -1, SQLITE_TRANSIENT)
        sqlite3_bind_double(statement, 4, trace.startTime.timeIntervalSince1970)

        if let endTime = trace.endTime {
            sqlite3_bind_double(statement, 5, endTime.timeIntervalSince1970)
        } else {
            sqlite3_bind_null(statement, 5)
        }

        if let metadata = trace.metadata {
            sqlite3_bind_text(statement, 6, metadata, -1, SQLITE_TRANSIENT)
        } else {
            sqlite3_bind_null(statement, 6)
        }

        guard sqlite3_step(statement) == SQLITE_DONE else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.queryFailed("Insert failed: \(errorMessage)")
        }
    }

    /// Retrieves all traces, optionally filtered by session ID
    public func getTraces(sessionId: String? = nil) throws -> [Trace] {
        guard isInitialized, let db = db else {
            throw DatabaseError.notInitialized
        }

        let sql: String
        if sessionId != nil {
            sql = "SELECT id, session_id, name, start_time, end_time, metadata FROM Traces WHERE session_id = ? ORDER BY start_time;"
        } else {
            sql = "SELECT id, session_id, name, start_time, end_time, metadata FROM Traces ORDER BY start_time;"
        }

        var statement: OpaquePointer?
        defer { if statement != nil { sqlite3_finalize(statement) } }

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.queryFailed("Prepare failed: \(errorMessage)")
        }

        if let sid = sessionId {
            sqlite3_bind_text(statement, 1, sid, -1, SQLITE_TRANSIENT)
        }

        var traces: [Trace] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            guard let id = UUID(uuidString: String(cString: sqlite3_column_text(statement, 0))) else { continue }
            let sid = String(cString: sqlite3_column_text(statement, 1))
            let name = String(cString: sqlite3_column_text(statement, 2))
            let startTime = Date(timeIntervalSince1970: sqlite3_column_double(statement, 3))
            let endTime = sqlite3_column_type(statement, 4) != SQLITE_NULL ?
                Date(timeIntervalSince1970: sqlite3_column_double(statement, 4)) : nil
            let metadata = sqlite3_column_type(statement, 5) != SQLITE_NULL ?
                String(cString: sqlite3_column_text(statement, 5)) : nil

            traces.append(Trace(id: id, sessionId: sid, name: name, startTime: startTime, endTime: endTime, metadata: metadata))
        }

        return traces
    }

    // MARK: - Observation Operations

    /// Inserts a new observation
    public func insertObservation(_ observation: Observation) throws {
        guard isInitialized, let db = db else {
            throw DatabaseError.notInitialized
        }

        let sql = """
        INSERT INTO Observations (id, trace_id, name, start_time, end_time, input, output, status_message)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?);
        """

        var statement: OpaquePointer?
        defer { if statement != nil { sqlite3_finalize(statement) } }

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.queryFailed("Prepare failed: \(errorMessage)")
        }

        sqlite3_bind_text(statement, 1, observation.id.uuidString, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 2, observation.traceId.uuidString, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 3, observation.name, -1, SQLITE_TRANSIENT)
        sqlite3_bind_double(statement, 4, observation.startTime.timeIntervalSince1970)

        if let endTime = observation.endTime {
            sqlite3_bind_double(statement, 5, endTime.timeIntervalSince1970)
        } else {
            sqlite3_bind_null(statement, 5)
        }

        if let input = observation.input {
            sqlite3_bind_text(statement, 6, input, -1, SQLITE_TRANSIENT)
        } else {
            sqlite3_bind_null(statement, 6)
        }

        if let output = observation.output {
            sqlite3_bind_text(statement, 7, output, -1, SQLITE_TRANSIENT)
        } else {
            sqlite3_bind_null(statement, 7)
        }

        if let statusMessage = observation.statusMessage {
            sqlite3_bind_text(statement, 8, statusMessage, -1, SQLITE_TRANSIENT)
        } else {
            sqlite3_bind_null(statement, 8)
        }

        guard sqlite3_step(statement) == SQLITE_DONE else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.queryFailed("Insert failed: \(errorMessage)")
        }
    }

    /// Retrieves observations for a given trace
    public func getObservations(traceId: UUID) throws -> [Observation] {
        guard isInitialized, let db = db else {
            throw DatabaseError.notInitialized
        }

        let sql = """
        SELECT id, trace_id, name, start_time, end_time, input, output, status_message
        FROM Observations WHERE trace_id = ? ORDER BY start_time;
        """

        var statement: OpaquePointer?
        defer { if statement != nil { sqlite3_finalize(statement) } }

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.queryFailed("Prepare failed: \(errorMessage)")
        }

        sqlite3_bind_text(statement, 1, traceId.uuidString, -1, SQLITE_TRANSIENT)

        var observations: [Observation] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            guard let id = UUID(uuidString: String(cString: sqlite3_column_text(statement, 0))),
                  let tid = UUID(uuidString: String(cString: sqlite3_column_text(statement, 1))) else { continue }
            let name = String(cString: sqlite3_column_text(statement, 2))
            let startTime = Date(timeIntervalSince1970: sqlite3_column_double(statement, 3))
            let endTime = sqlite3_column_type(statement, 4) != SQLITE_NULL ?
                Date(timeIntervalSince1970: sqlite3_column_double(statement, 4)) : nil
            let input = sqlite3_column_type(statement, 5) != SQLITE_NULL ?
                String(cString: sqlite3_column_text(statement, 5)) : nil
            let output = sqlite3_column_type(statement, 6) != SQLITE_NULL ?
                String(cString: sqlite3_column_text(statement, 6)) : nil
            let statusMessage = sqlite3_column_type(statement, 7) != SQLITE_NULL ?
                String(cString: sqlite3_column_text(statement, 7)) : nil

            observations.append(Observation(id: id, traceId: tid, name: name, startTime: startTime, endTime: endTime, input: input, output: output, statusMessage: statusMessage))
        }

        return observations
    }
    
    // MARK: - Issue Operations
    
    /// Inserts a new issue
    public func insertIssue(_ issue: Issue) throws {
        guard isInitialized, let db = db else {
            throw DatabaseError.notInitialized
        }
        
        let sql = """
        INSERT INTO Issues (id, document_id, title, description, status, priority, created, modified, resolved_at, tags, notes)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
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
        
        // Encode tags as JSON
        let tagsData = try JSONEncoder().encode(issue.metadata.tags)
        let tagsString = String(data: tagsData, encoding: .utf8) ?? "[]"
        
        sqlite3_bind_text(statement, 1, issue.id.uuidString, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 2, issue.documentId.uuidString, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 3, issue.title, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 4, issue.description, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 5, issue.status.rawValue, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 6, issue.priority.rawValue, -1, SQLITE_TRANSIENT)
        sqlite3_bind_double(statement, 7, issue.metadata.created.timeIntervalSince1970)
        sqlite3_bind_double(statement, 8, issue.metadata.modified.timeIntervalSince1970)
        
        if let resolvedAt = issue.metadata.resolvedAt {
            sqlite3_bind_double(statement, 9, resolvedAt.timeIntervalSince1970)
        } else {
            sqlite3_bind_null(statement, 9)
        }
        
        sqlite3_bind_text(statement, 10, tagsString, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 11, issue.metadata.notes, -1, SQLITE_TRANSIENT)
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.queryFailed("Insert failed: \(errorMessage)")
        }
    }
    
    /// Updates an existing issue
    public func updateIssue(_ issue: Issue) throws {
        guard isInitialized, let db = db else {
            throw DatabaseError.notInitialized
        }
        
        let sql = """
        UPDATE Issues SET
            title = ?, description = ?, status = ?, priority = ?,
            modified = ?, resolved_at = ?, tags = ?, notes = ?
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
        
        // Encode tags as JSON
        let tagsData = try JSONEncoder().encode(issue.metadata.tags)
        let tagsString = String(data: tagsData, encoding: .utf8) ?? "[]"
        
        sqlite3_bind_text(statement, 1, issue.title, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 2, issue.description, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 3, issue.status.rawValue, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 4, issue.priority.rawValue, -1, SQLITE_TRANSIENT)
        sqlite3_bind_double(statement, 5, issue.metadata.modified.timeIntervalSince1970)
        
        if let resolvedAt = issue.metadata.resolvedAt {
            sqlite3_bind_double(statement, 6, resolvedAt.timeIntervalSince1970)
        } else {
            sqlite3_bind_null(statement, 6)
        }
        
        sqlite3_bind_text(statement, 7, tagsString, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 8, issue.metadata.notes, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 9, issue.id.uuidString, -1, SQLITE_TRANSIENT)
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.queryFailed("Update failed: \(errorMessage)")
        }
    }
    
    /// Retrieves issues for a document with pagination
    public func getIssues(forDocument documentId: UUID, limit: Int = 50, offset: Int = 0) throws -> [Issue] {
        guard isInitialized, let db = db else {
            throw DatabaseError.notInitialized
        }
        
        let sql = """
        SELECT id, document_id, title, description, status, priority, created, modified, resolved_at, tags, notes
        FROM Issues
        WHERE document_id = ?
        ORDER BY created DESC
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
        
        sqlite3_bind_text(statement, 1, documentId.uuidString, -1, SQLITE_TRANSIENT)
        sqlite3_bind_int(statement, 2, Int32(limit))
        sqlite3_bind_int(statement, 3, Int32(offset))
        
        return try parseIssues(from: statement)
    }
    
    /// Retrieves issues by status with pagination
    public func getIssues(withStatus status: IssueStatus, limit: Int = 50, offset: Int = 0) throws -> [Issue] {
        guard isInitialized, let db = db else {
            throw DatabaseError.notInitialized
        }
        
        let sql = """
        SELECT id, document_id, title, description, status, priority, created, modified, resolved_at, tags, notes
        FROM Issues
        WHERE status = ?
        ORDER BY created DESC
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
        
        sqlite3_bind_text(statement, 1, status.rawValue, -1, SQLITE_TRANSIENT)
        sqlite3_bind_int(statement, 2, Int32(limit))
        sqlite3_bind_int(statement, 3, Int32(offset))
        
        return try parseIssues(from: statement)
    }
    
    /// Retrieves all issues with pagination
    public func getAllIssues(limit: Int = 50, offset: Int = 0) throws -> [Issue] {
        guard isInitialized, let db = db else {
            throw DatabaseError.notInitialized
        }
        
        let sql = """
        SELECT id, document_id, title, description, status, priority, created, modified, resolved_at, tags, notes
        FROM Issues
        ORDER BY created DESC
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
        
        sqlite3_bind_int(statement, 1, Int32(limit))
        sqlite3_bind_int(statement, 2, Int32(offset))
        
        return try parseIssues(from: statement)
    }
    
    /// Deletes an issue
    public func deleteIssue(id: UUID) throws {
        guard isInitialized, let db = db else {
            throw DatabaseError.notInitialized
        }
        
        let sql = "DELETE FROM Issues WHERE id = ?;"
        
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
    
    /// Parses rows from a prepared SQLite statement into an array of `Issue` values.
    /// 
    /// Decodes each result row into an `Issue`, interpreting numeric timestamp columns as seconds since the Unix epoch and decoding the tags column from JSON into `[String]`. Rows are skipped when required fields are malformed (invalid UUIDs, unknown status or priority). If tag JSON fails to decode, an empty tag array is used.
    /// - Parameters:
    ///   - statement: A prepared SQLite statement positioned at the result set; the function will step through all rows.
    /// - Returns: An array of `Issue` objects parsed from the statement; rows with invalid or unparseable data are omitted.
    private func parseIssues(from statement: OpaquePointer?) throws -> [Issue] {
        var issues: [Issue] = []
        
        while sqlite3_step(statement) == SQLITE_ROW {
            guard let id = UUID(uuidString: String(cString: sqlite3_column_text(statement, 0))),
                  let documentId = UUID(uuidString: String(cString: sqlite3_column_text(statement, 1))) else {
                continue
            }
            
            let title = String(cString: sqlite3_column_text(statement, 2))
            let description = String(cString: sqlite3_column_text(statement, 3))
            let statusString = String(cString: sqlite3_column_text(statement, 4))
            let priorityString = String(cString: sqlite3_column_text(statement, 5))
            
            guard let status = IssueStatus(rawValue: statusString),
                  let priority = IssuePriority(rawValue: priorityString) else {
                continue
            }
            
            let created = Date(timeIntervalSince1970: sqlite3_column_double(statement, 6))
            let modified = Date(timeIntervalSince1970: sqlite3_column_double(statement, 7))
            
            let resolvedAt = sqlite3_column_type(statement, 8) != SQLITE_NULL ?
                Date(timeIntervalSince1970: sqlite3_column_double(statement, 8)) : nil
            
            // Decode tags from JSON
            let tagsString = String(cString: sqlite3_column_text(statement, 9))
            let tags = (try? JSONDecoder().decode([String].self, from: Data(tagsString.utf8))) ?? []
            
            let notes = String(cString: sqlite3_column_text(statement, 10))
            
            let metadata = IssueMetadata(
                created: created,
                modified: modified,
                resolvedAt: resolvedAt,
                tags: tags,
                notes: notes
            )
            
            let issue = Issue(
                id: id,
                documentId: documentId,
                title: title,
                description: description,
                status: status,
                priority: priority,
                metadata: metadata
            )
            
            issues.append(issue)
        }

        return issues
    }

    // MARK: - Version Control: Branch Operations

    /// Inserts a new version-control branch record into the database.
    /// - Parameters:
    ///   - branch: The `VCBranch` to persist. Its `id`, `name`, `createdAt`, and `isActive` fields are stored; `headCommitId` is stored when present.
    /// - Throws: `DatabaseError.notInitialized` if the database manager has not been initialized; `DatabaseError.queryFailed` if preparing or executing the SQL statement fails.
    public func insertVCBranch(_ branch: VCBranch) throws {
        guard isInitialized, let db = db else { throw DatabaseError.notInitialized }
        let sql = """
        INSERT INTO vc_branches (id, name, head_commit_id, created_at, is_active)
        VALUES (?, ?, ?, ?, ?);
        """
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw DatabaseError.queryFailed(String(cString: sqlite3_errmsg(db)))
        }
        sqlite3_bind_text(stmt, 1, branch.id.uuidString, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 2, branch.name, -1, SQLITE_TRANSIENT)
        if let hc = branch.headCommitId {
            sqlite3_bind_text(stmt, 3, hc.uuidString, -1, SQLITE_TRANSIENT)
        } else {
            sqlite3_bind_null(stmt, 3)
        }
        sqlite3_bind_double(stmt, 4, branch.createdAt.timeIntervalSince1970)
        sqlite3_bind_int(stmt, 5, branch.isActive ? 1 : 0)
        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw DatabaseError.queryFailed(String(cString: sqlite3_errmsg(db)))
        }
    }

    /// Updates a version-control branch's head commit and active flag in the database.
    /// - Parameter branch: The branch containing the new `headCommitId`, `isActive` flag, and `id` to identify which row to update.
    /// - Throws: `DatabaseError.notInitialized` if the database manager has not been initialized; `DatabaseError.queryFailed` if preparing or executing the SQL update fails.
    public func updateVCBranch(_ branch: VCBranch) throws {
        guard isInitialized, let db = db else { throw DatabaseError.notInitialized }
        let sql = "UPDATE vc_branches SET head_commit_id = ?, is_active = ? WHERE id = ?;"
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw DatabaseError.queryFailed(String(cString: sqlite3_errmsg(db)))
        }
        if let hc = branch.headCommitId {
            sqlite3_bind_text(stmt, 1, hc.uuidString, -1, SQLITE_TRANSIENT)
        } else {
            sqlite3_bind_null(stmt, 1)
        }
        sqlite3_bind_int(stmt, 2, branch.isActive ? 1 : 0)
        sqlite3_bind_text(stmt, 3, branch.id.uuidString, -1, SQLITE_TRANSIENT)
        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw DatabaseError.queryFailed(String(cString: sqlite3_errmsg(db)))
        }
    }

    /// Atomically sets all branches inactive then marks one as active.
    /// The two-statement update is wrapped in a transaction so a crash between
    /// Atomically activates the branch with the given id and deactivates all other branches.
    /// 
    /// Performs the operation inside a transaction: sets all branches' `is_active` to 0, then sets the specified branch's `is_active` to 1. On any failure the transaction is rolled back.
    /// - Parameters:
    ///   - id: The UUID of the branch to activate.
    /// - Throws: `DatabaseError.notInitialized` if the database has not been initialized; `DatabaseError.queryFailed` if any SQLite operation fails (message contains the underlying SQLite error).
    public func setActiveBranch(id: UUID) throws {
        guard isInitialized, let db = db else { throw DatabaseError.notInitialized }
        try execute("BEGIN;")
        do {
            try execute("UPDATE vc_branches SET is_active = 0;")
            let sql = "UPDATE vc_branches SET is_active = 1 WHERE id = ?;"
            var stmt: OpaquePointer?
            defer { sqlite3_finalize(stmt) }
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
                throw DatabaseError.queryFailed(String(cString: sqlite3_errmsg(db)))
            }
            sqlite3_bind_text(stmt, 1, id.uuidString, -1, SQLITE_TRANSIENT)
            guard sqlite3_step(stmt) == SQLITE_DONE else {
                throw DatabaseError.queryFailed(String(cString: sqlite3_errmsg(db)))
            }
            try execute("COMMIT;")
        } catch {
            try? execute("ROLLBACK;")
            throw error
        }
    }

    /// Retrieves all version-control branches ordered by creation time (oldest first).
    /// - Returns: An array of `VCBranch` objects ordered by `createdAt` ascending.
    /// - Throws: `DatabaseError.notInitialized` if the database manager is not initialized or the connection is closed.
    /// - Throws: `DatabaseError.queryFailed` if preparing or executing the SQL query fails.
    public func getAllVCBranches() throws -> [VCBranch] {
        guard isInitialized, let db = db else { throw DatabaseError.notInitialized }
        let sql = """
        SELECT id, name, head_commit_id, created_at, is_active
        FROM vc_branches ORDER BY created_at ASC;
        """
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw DatabaseError.queryFailed(String(cString: sqlite3_errmsg(db)))
        }
        var branches: [VCBranch] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            guard let idText = sqlite3_column_text(stmt, 0),
                  let nameText = sqlite3_column_text(stmt, 1),
                  let id = UUID(uuidString: String(cString: idText)) else { continue }
            let headId: UUID?
            if let hcText = sqlite3_column_text(stmt, 2) {
                headId = UUID(uuidString: String(cString: hcText))
            } else {
                headId = nil
            }
            let createdAt = Date(timeIntervalSince1970: sqlite3_column_double(stmt, 3))
            let isActive = sqlite3_column_int(stmt, 4) != 0
            branches.append(VCBranch(id: id, name: String(cString: nameText),
                                     headCommitId: headId, createdAt: createdAt, isActive: isActive))
        }
        return branches
    }

    /// Fetches a version-control branch by its name.
    /// - Parameters:
    ///   - name: The branch name to look up.
    /// - Returns: The matching `VCBranch` if found, `nil` otherwise.
    /// - Throws: `DatabaseError.notInitialized` if the database has not been initialized.
    /// - Throws: `DatabaseError.queryFailed` if preparing or executing the SQL query fails.
    public func getVCBranch(name: String) throws -> VCBranch? {
        guard isInitialized, let db = db else { throw DatabaseError.notInitialized }
        let sql = """
        SELECT id, name, head_commit_id, created_at, is_active
        FROM vc_branches WHERE name = ?;
        """
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw DatabaseError.queryFailed(String(cString: sqlite3_errmsg(db)))
        }
        sqlite3_bind_text(stmt, 1, name, -1, SQLITE_TRANSIENT)
        guard sqlite3_step(stmt) == SQLITE_ROW else { return nil }
        guard let idText = sqlite3_column_text(stmt, 0),
              let nameText = sqlite3_column_text(stmt, 1),
              let id = UUID(uuidString: String(cString: idText)) else { return nil }
        let headId: UUID?
        if let hcText = sqlite3_column_text(stmt, 2) {
            headId = UUID(uuidString: String(cString: hcText))
        } else {
            headId = nil
        }
        let createdAt = Date(timeIntervalSince1970: sqlite3_column_double(stmt, 3))
        let isActive = sqlite3_column_int(stmt, 4) != 0
        return VCBranch(id: id, name: String(cString: nameText),
                        headCommitId: headId, createdAt: createdAt, isActive: isActive)
    }

    // MARK: - Version Control: Commit Operations

    /// Inserts a new version-control commit record into the database.
    ///
    /// The provided `VCCommit` is persisted to the `vc_commits` table; optional fields on the model are stored as NULL when absent.
    /// - Parameter commit: The commit record to insert.
    /// - Throws: `DatabaseError.notInitialized` if the database manager has not been initialized.  
    ///           `DatabaseError.queryFailed` if preparing or executing the SQL statement fails.
    public func insertVCCommit(_ commit: VCCommit) throws {
        guard isInitialized, let db = db else { throw DatabaseError.notInitialized }
        let sql = """
        INSERT INTO vc_commits
            (id, branch_id, message, author_id, timestamp, parent_commit_id, second_parent_commit_id)
        VALUES (?, ?, ?, ?, ?, ?, ?);
        """
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw DatabaseError.queryFailed(String(cString: sqlite3_errmsg(db)))
        }
        sqlite3_bind_text(stmt, 1, commit.id.uuidString, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 2, commit.branchId.uuidString, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 3, commit.message, -1, SQLITE_TRANSIENT)
        if let author = commit.authorId {
            sqlite3_bind_text(stmt, 4, author, -1, SQLITE_TRANSIENT)
        } else {
            sqlite3_bind_null(stmt, 4)
        }
        sqlite3_bind_double(stmt, 5, commit.timestamp.timeIntervalSince1970)
        if let parent = commit.parentCommitId {
            sqlite3_bind_text(stmt, 6, parent.uuidString, -1, SQLITE_TRANSIENT)
        } else {
            sqlite3_bind_null(stmt, 6)
        }
        if let second = commit.secondParentCommitId {
            sqlite3_bind_text(stmt, 7, second.uuidString, -1, SQLITE_TRANSIENT)
        } else {
            sqlite3_bind_null(stmt, 7)
        }
        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw DatabaseError.queryFailed(String(cString: sqlite3_errmsg(db)))
        }
    }

    /// Fetches all commits for the specified branch, ordered by timestamp ascending.
    /// - Parameters:
    ///   - branchId: UUID of the branch whose commits should be retrieved.
    /// - Returns: An array of `VCCommit` objects for the branch ordered by ascending timestamp.
    /// - Throws: `DatabaseError.notInitialized` if the database manager is not initialized; `DatabaseError.queryFailed` if preparing or executing the SQL query fails.
    public func getVCCommits(branchId: UUID) throws -> [VCCommit] {
        guard isInitialized, let db = db else { throw DatabaseError.notInitialized }
        let sql = """
        SELECT id, branch_id, message, author_id, timestamp,
               parent_commit_id, second_parent_commit_id
        FROM vc_commits WHERE branch_id = ? ORDER BY timestamp ASC;
        """
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw DatabaseError.queryFailed(String(cString: sqlite3_errmsg(db)))
        }
        sqlite3_bind_text(stmt, 1, branchId.uuidString, -1, SQLITE_TRANSIENT)
        var commits: [VCCommit] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            guard let idText = sqlite3_column_text(stmt, 0),
                  let branchText = sqlite3_column_text(stmt, 1),
                  let msgText = sqlite3_column_text(stmt, 2),
                  let id = UUID(uuidString: String(cString: idText)),
                  let bId = UUID(uuidString: String(cString: branchText)) else { continue }
            let author: String? = sqlite3_column_text(stmt, 3).map { String(cString: $0) }
            let ts = Date(timeIntervalSince1970: sqlite3_column_double(stmt, 4))
            let parent: UUID? = sqlite3_column_text(stmt, 5)
                .flatMap { UUID(uuidString: String(cString: $0)) }
            let secondParent: UUID? = sqlite3_column_text(stmt, 6)
                .flatMap { UUID(uuidString: String(cString: $0)) }
            commits.append(VCCommit(id: id, branchId: bId,
                                    message: String(cString: msgText),
                                    authorId: author, timestamp: ts,
                                    parentCommitId: parent,
                                    secondParentCommitId: secondParent))
        }
        return commits
    }

    // MARK: - Version Control: Snapshot Operations

    /// Inserts a document snapshot into the version control snapshots table.
    /// - Parameter snapshot: The `VCDocumentSnapshot` to persist (id, commitId, documentId, title, content, category, wordCount, capturedAt).
    /// - Throws: `DatabaseError.notInitialized` if the database has not been opened; `DatabaseError.queryFailed` if the SQL prepare or execution fails.
    public func insertVCSnapshot(_ snapshot: VCDocumentSnapshot) throws {
        guard isInitialized, let db = db else { throw DatabaseError.notInitialized }
        let sql = """
        INSERT INTO vc_document_snapshots
            (id, commit_id, document_id, title, content, category, word_count, captured_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?);
        """
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw DatabaseError.queryFailed(String(cString: sqlite3_errmsg(db)))
        }
        sqlite3_bind_text(stmt, 1, snapshot.id.uuidString, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 2, snapshot.commitId.uuidString, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 3, snapshot.documentId.uuidString, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 4, snapshot.title, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 5, snapshot.content, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 6, snapshot.category, -1, SQLITE_TRANSIENT)
        sqlite3_bind_int64(stmt, 7, Int64(snapshot.wordCount))
        sqlite3_bind_double(stmt, 8, snapshot.capturedAt.timeIntervalSince1970)
        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw DatabaseError.queryFailed(String(cString: sqlite3_errmsg(db)))
        }
    }

    /// Retrieves only the snapshots stored directly on a given commit (no parent-chain walk).
    /// - Parameter commitId: The commit UUID whose direct snapshots to retrieve.
    /// - Returns: An array of `VCDocumentSnapshot` records stored for the specified commit.
    /// - Throws: `DatabaseError.notInitialized` if the database is not initialized; `DatabaseError.queryFailed` if the SQL preparation or execution fails.
    public func getVCSnapshotsDirect(commitId: UUID) throws -> [VCDocumentSnapshot] {
        guard isInitialized, let db = db else { throw DatabaseError.notInitialized }
        let sql = """
        SELECT id, commit_id, document_id, title, content, category, word_count, captured_at
        FROM vc_document_snapshots WHERE commit_id = ?;
        """
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw DatabaseError.queryFailed(String(cString: sqlite3_errmsg(db)))
        }
        sqlite3_bind_text(stmt, 1, commitId.uuidString, -1, SQLITE_TRANSIENT)
        return try collectSnapshots(stmt: stmt)
    }

    /// Retrieves the accumulated document state at a given commit by walking the parent-commit
    /// chain. For each document, the snapshot from the most recent commit in the chain wins.
    /// - Parameter commitId: The commit UUID to start from (most recent).
    /// - Returns: One `VCDocumentSnapshot` per unique document, reflecting the state at
    ///   `commitId`, sorted by title.
    /// - Throws: `DatabaseError.notInitialized` if the database is not initialized;
    ///   `DatabaseError.queryFailed` if any SQL query fails.
    public func getVCSnapshots(commitId: UUID) throws -> [VCDocumentSnapshot] {
        let maxDepth = 10_000
        var accumulator: [UUID: VCDocumentSnapshot] = [:]
        var currentId: UUID? = commitId
        var visited = Set<UUID>()
        var depth = 0
        while let cId = currentId, depth < maxDepth {
            guard !visited.contains(cId) else { break }
            visited.insert(cId)
            depth += 1
            for snap in try getVCSnapshotsDirect(commitId: cId) {
                if accumulator[snap.documentId] == nil {
                    accumulator[snap.documentId] = snap
                }
            }
            guard let commit = try getVCCommit(id: cId) else { break }
            currentId = commit.parentCommitId
        }
        return Array(accumulator.values).sorted { $0.title < $1.title }
    }

    /// Retrieves a single version-control commit by its unique identifier.
    /// - Parameter id: The UUID of the commit to look up.
    /// - Returns: The matching `VCCommit`, or `nil` if not found.
    /// - Throws: `DatabaseError.notInitialized` if the database is not initialized;
    ///   `DatabaseError.queryFailed` if the SQL preparation or execution fails.
    public func getVCCommit(id: UUID) throws -> VCCommit? {
        guard isInitialized, let db = db else { throw DatabaseError.notInitialized }
        let sql = """
        SELECT id, branch_id, message, author_id, timestamp,
               parent_commit_id, second_parent_commit_id
        FROM vc_commits WHERE id = ?;
        """
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw DatabaseError.queryFailed(String(cString: sqlite3_errmsg(db)))
        }
        sqlite3_bind_text(stmt, 1, id.uuidString, -1, SQLITE_TRANSIENT)
        guard sqlite3_step(stmt) == SQLITE_ROW else { return nil }
        guard let idText = sqlite3_column_text(stmt, 0),
              let branchText = sqlite3_column_text(stmt, 1),
              let msgText = sqlite3_column_text(stmt, 2),
              let cId = UUID(uuidString: String(cString: idText)),
              let bId = UUID(uuidString: String(cString: branchText)) else { return nil }
        let author: String? = sqlite3_column_text(stmt, 3).map { String(cString: $0) }
        let ts = Date(timeIntervalSince1970: sqlite3_column_double(stmt, 4))
        let parent: UUID? = sqlite3_column_text(stmt, 5)
            .flatMap { UUID(uuidString: String(cString: $0)) }
        let secondParent: UUID? = sqlite3_column_text(stmt, 6)
            .flatMap { UUID(uuidString: String(cString: $0)) }
        return VCCommit(id: cId, branchId: bId, message: String(cString: msgText),
                        authorId: author, timestamp: ts,
                        parentCommitId: parent, secondParentCommitId: secondParent)
    }

    /// Retrieves all version-control document snapshots for the given document ordered from oldest to newest by capture time.
    /// - Parameters:
    ///   - documentId: The UUID of the document whose snapshots will be returned.
    /// - Returns: An array of `VCDocumentSnapshot` objects for the specified document ordered by `capturedAt` ascending.
    /// - Throws: `DatabaseError.notInitialized` if the database manager is not initialized; `DatabaseError.queryFailed` if preparing or executing the query fails.
    public func getVCSnapshotsForDocument(documentId: UUID) throws -> [VCDocumentSnapshot] {
        guard isInitialized, let db = db else { throw DatabaseError.notInitialized }
        let sql = """
        SELECT id, commit_id, document_id, title, content, category, word_count, captured_at
        FROM vc_document_snapshots WHERE document_id = ? ORDER BY captured_at ASC;
        """
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw DatabaseError.queryFailed(String(cString: sqlite3_errmsg(db)))
        }
        sqlite3_bind_text(stmt, 1, documentId.uuidString, -1, SQLITE_TRANSIENT)
        return try collectSnapshots(stmt: stmt)
    }

    /// Returns the most recent snapshot for each document captured at or before the given date.
    /// Fetches the most recent snapshot for each document with a captured_at timestamp less than or equal to the provided date.
    /// - Parameters:
    ///   - date: The cutoff date; snapshots with `captured_at` less than or equal to this date are considered.
    /// - Returns: An array of `VCDocumentSnapshot` containing, for each document, the snapshot with the latest `captured_at` at or before `date`.
    /// - Throws: `DatabaseError.notInitialized` if the database manager is not initialized; `DatabaseError.queryFailed` if the SQL query fails.
    public func getVCSnapshotsAsOf(date: Date) throws -> [VCDocumentSnapshot] {
        guard isInitialized, let db = db else { throw DatabaseError.notInitialized }
        let sql = """
        SELECT s.id, s.commit_id, s.document_id, s.title, s.content,
               s.category, s.word_count, s.captured_at
        FROM vc_document_snapshots s
        INNER JOIN (
            SELECT document_id, MAX(captured_at) AS latest
            FROM vc_document_snapshots
            WHERE captured_at <= ?
            GROUP BY document_id
        ) latest ON s.document_id = latest.document_id AND s.captured_at = latest.latest;
        """
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw DatabaseError.queryFailed(String(cString: sqlite3_errmsg(db)))
        }
        sqlite3_bind_double(stmt, 1, date.timeIntervalSince1970)
        return try collectSnapshots(stmt: stmt)
    }

    /// Collects `VCDocumentSnapshot` records from an SQLite result statement.
    /// 
    /// Reads rows from `stmt` and constructs `VCDocumentSnapshot` values from the
    /// columns in the following order: `id`, `commit_id`, `document_id`, `title`,
    /// `content`, `category`, `word_count`, `captured_at`. Rows missing required
    /// values or containing invalid UUIDs are skipped.
    /// - Parameter stmt: A prepared SQLite statement positioned before the first row.
    /// - Returns: An array of `VCDocumentSnapshot` parsed from the statement's result rows.

    private func collectSnapshots(stmt: OpaquePointer?) throws -> [VCDocumentSnapshot] {
        var snapshots: [VCDocumentSnapshot] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            guard let idText = sqlite3_column_text(stmt, 0),
                  let commitText = sqlite3_column_text(stmt, 1),
                  let docText = sqlite3_column_text(stmt, 2),
                  let titleText = sqlite3_column_text(stmt, 3),
                  let contentText = sqlite3_column_text(stmt, 4),
                  let categoryText = sqlite3_column_text(stmt, 5),
                  let id = UUID(uuidString: String(cString: idText)),
                  let commitId = UUID(uuidString: String(cString: commitText)),
                  let documentId = UUID(uuidString: String(cString: docText)) else { continue }
            let wordCount = Int(sqlite3_column_int64(stmt, 6))
            let capturedAt = Date(timeIntervalSince1970: sqlite3_column_double(stmt, 7))
            snapshots.append(VCDocumentSnapshot(
                id: id, commitId: commitId, documentId: documentId,
                title: String(cString: titleText),
                content: String(cString: contentText),
                category: String(cString: categoryText),
                wordCount: wordCount, capturedAt: capturedAt))
        }
        return snapshots
    }

    // MARK: - Gift Card Operations

    public func insertGiftCardBundle(_ bundle: GiftCardBundle) throws {
        guard isInitialized, let db = db else {
            throw DatabaseError.notInitialized
        }

        let sql = """
        INSERT INTO GiftCardBundles (id, name, description, price, bundle_type, included_template_ids, ai_credits, expiration_days, created_at, modified_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """

        var statement: OpaquePointer?
        defer { if statement != nil { sqlite3_finalize(statement) } }

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.queryFailed("Prepare failed: \(errorMessage)")
        }

        let templateIds = try JSONEncoder().encode(bundle.includedTemplateIds)
        let templateIdsString = String(data: templateIds, encoding: .utf8) ?? "[]"
        let priceString = bundle.price.description

        sqlite3_bind_text(statement, 1, bundle.id.uuidString, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 2, bundle.name, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 3, bundle.description, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 4, priceString, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 5, bundle.bundleType.rawValue, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 6, templateIdsString, -1, SQLITE_TRANSIENT)
        sqlite3_bind_int(statement, 7, Int32(bundle.aiCredits))
        sqlite3_bind_int(statement, 8, Int32(bundle.expirationDays))
        sqlite3_bind_double(statement, 9, bundle.metadata.created.timeIntervalSince1970)
        sqlite3_bind_double(statement, 10, bundle.metadata.modified.timeIntervalSince1970)

        guard sqlite3_step(statement) == SQLITE_DONE else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.queryFailed("Insert failed: \(errorMessage)")
        }
    }

    public func getGiftCardBundle(id: UUID) throws -> GiftCardBundle? {
        guard isInitialized, let db = db else {
            throw DatabaseError.notInitialized
        }

        let sql = """
        SELECT id, name, description, price, bundle_type, included_template_ids, ai_credits, expiration_days, created_at, modified_at
        FROM GiftCardBundles WHERE id = ?;
        """

        var statement: OpaquePointer?
        defer { if statement != nil { sqlite3_finalize(statement) } }

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.queryFailed("Prepare failed: \(errorMessage)")
        }

        sqlite3_bind_text(statement, 1, id.uuidString, -1, SQLITE_TRANSIENT)

        guard sqlite3_step(statement) == SQLITE_ROW else { return nil }

        guard let idText = sqlite3_column_text(statement, 0),
              let nameText = sqlite3_column_text(statement, 1),
              let descText = sqlite3_column_text(statement, 2),
              let priceText = sqlite3_column_text(statement, 3),
              let typeText = sqlite3_column_text(statement, 4),
              let bundleId = UUID(uuidString: String(cString: idText)),
              let bundleType = BundleType(rawValue: String(cString: typeText)) else {
            return nil
        }

        let name = String(cString: nameText)
        let description = String(cString: descText)
        let priceString = String(cString: priceText)
        let price = Decimal(string: priceString) ?? 0

        let templateIdsText = sqlite3_column_text(statement, 5)
        let templateIds: [UUID] = templateIdsText.flatMap {
            try? JSONDecoder().decode([UUID].self, from: Data(String(cString: $0).utf8))
        } ?? []

        let aiCredits = Int(sqlite3_column_int(statement, 6))
        let expirationDays = Int(sqlite3_column_int(statement, 7))
        let created = Date(timeIntervalSince1970: sqlite3_column_double(statement, 8))
        let modified = Date(timeIntervalSince1970: sqlite3_column_double(statement, 9))

        let metadata = BundleMetadata(created: created, modified: modified)

        return GiftCardBundle(
            id: bundleId,
            name: name,
            description: description,
            price: price,
            bundleType: bundleType,
            includedTemplateIds: templateIds,
            aiCredits: aiCredits,
            expirationDays: expirationDays,
            metadata: metadata
        )
    }

    public func updateGiftCardBundle(_ bundle: GiftCardBundle) throws {
        guard isInitialized, let db = db else {
            throw DatabaseError.notInitialized
        }

        let sql = """
        UPDATE GiftCardBundles
        SET name = ?, description = ?, price = ?, bundle_type = ?, included_template_ids = ?, ai_credits = ?, expiration_days = ?, modified_at = ?
        WHERE id = ?;
        """

        var statement: OpaquePointer?
        defer { if statement != nil { sqlite3_finalize(statement) } }

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.queryFailed("Prepare failed: \(errorMessage)")
        }

        let templateIds = try JSONEncoder().encode(bundle.includedTemplateIds)
        let templateIdsString = String(data: templateIds, encoding: .utf8) ?? "[]"
        let priceString = bundle.price.description

        sqlite3_bind_text(statement, 1, bundle.name, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 2, bundle.description, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 3, priceString, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 4, bundle.bundleType.rawValue, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 5, templateIdsString, -1, SQLITE_TRANSIENT)
        sqlite3_bind_int(statement, 6, Int32(bundle.aiCredits))
        sqlite3_bind_int(statement, 7, Int32(bundle.expirationDays))
        sqlite3_bind_double(statement, 8, bundle.metadata.modified.timeIntervalSince1970)
        sqlite3_bind_text(statement, 9, bundle.id.uuidString, -1, SQLITE_TRANSIENT)

        guard sqlite3_step(statement) == SQLITE_DONE else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.queryFailed("Update failed: \(errorMessage)")
        }
    }

    public func deleteGiftCardBundle(id: UUID) throws {
        guard isInitialized, let db = db else {
            throw DatabaseError.notInitialized
        }

        let sql = "DELETE FROM GiftCardBundles WHERE id = ?;"

        var statement: OpaquePointer?
        defer { if statement != nil { sqlite3_finalize(statement) } }

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

    public func insertGiftCard(_ card: GiftCard) throws {
        guard isInitialized, let db = db else {
            throw DatabaseError.notInitialized
        }

        let sql = """
        INSERT INTO GiftCards (id, code, bundle_id, status, redeemed_by_user_id, redeemed_at, created_at, expires_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?);
        """

        var statement: OpaquePointer?
        defer { if statement != nil { sqlite3_finalize(statement) } }

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.queryFailed("Prepare failed: \(errorMessage)")
        }

        sqlite3_bind_text(statement, 1, card.id.uuidString, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 2, card.code, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 3, card.bundleId.uuidString, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 4, card.status.rawValue, -1, SQLITE_TRANSIENT)

        if let userId = card.redeemedByUserId {
            sqlite3_bind_text(statement, 5, userId.uuidString, -1, SQLITE_TRANSIENT)
        } else {
            sqlite3_bind_null(statement, 5)
        }

        if let redeemedAt = card.redeemedAt {
            sqlite3_bind_double(statement, 6, redeemedAt.timeIntervalSince1970)
        } else {
            sqlite3_bind_null(statement, 6)
        }

        sqlite3_bind_double(statement, 7, card.metadata.createdAt.timeIntervalSince1970)

        if let expiresAt = card.metadata.expiresAt {
            sqlite3_bind_double(statement, 8, expiresAt.timeIntervalSince1970)
        } else {
            sqlite3_bind_null(statement, 8)
        }

        guard sqlite3_step(statement) == SQLITE_DONE else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.queryFailed("Insert failed: \(errorMessage)")
        }
    }

    public func getGiftCard(id: UUID) throws -> GiftCard? {
        guard isInitialized, let db = db else {
            throw DatabaseError.notInitialized
        }

        let sql = """
        SELECT id, code, bundle_id, status, redeemed_by_user_id, redeemed_at, created_at, expires_at
        FROM GiftCards WHERE id = ?;
        """

        var statement: OpaquePointer?
        defer { if statement != nil { sqlite3_finalize(statement) } }

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.queryFailed("Prepare failed: \(errorMessage)")
        }

        sqlite3_bind_text(statement, 1, id.uuidString, -1, SQLITE_TRANSIENT)

        guard sqlite3_step(statement) == SQLITE_ROW else { return nil }

        return try parseGiftCard(from: statement)
    }

    public func getGiftCardByCode(_ code: String) throws -> GiftCard? {
        guard isInitialized, let db = db else {
            throw DatabaseError.notInitialized
        }

        let sql = """
        SELECT id, code, bundle_id, status, redeemed_by_user_id, redeemed_at, created_at, expires_at
        FROM GiftCards WHERE code = ?;
        """

        var statement: OpaquePointer?
        defer { if statement != nil { sqlite3_finalize(statement) } }

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.queryFailed("Prepare failed: \(errorMessage)")
        }

        sqlite3_bind_text(statement, 1, code, -1, SQLITE_TRANSIENT)

        guard sqlite3_step(statement) == SQLITE_ROW else { return nil }

        return try parseGiftCard(from: statement)
    }

    public func updateGiftCard(_ card: GiftCard) throws {
        guard isInitialized, let db = db else {
            throw DatabaseError.notInitialized
        }

        let sql = """
        UPDATE GiftCards
        SET status = ?, redeemed_by_user_id = ?, redeemed_at = ?
        WHERE id = ?;
        """

        var statement: OpaquePointer?
        defer { if statement != nil { sqlite3_finalize(statement) } }

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.queryFailed("Prepare failed: \(errorMessage)")
        }

        sqlite3_bind_text(statement, 1, card.status.rawValue, -1, SQLITE_TRANSIENT)

        if let userId = card.redeemedByUserId {
            sqlite3_bind_text(statement, 2, userId.uuidString, -1, SQLITE_TRANSIENT)
        } else {
            sqlite3_bind_null(statement, 2)
        }

        if let redeemedAt = card.redeemedAt {
            sqlite3_bind_double(statement, 3, redeemedAt.timeIntervalSince1970)
        } else {
            sqlite3_bind_null(statement, 3)
        }

        sqlite3_bind_text(statement, 4, card.id.uuidString, -1, SQLITE_TRANSIENT)

        guard sqlite3_step(statement) == SQLITE_DONE else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.queryFailed("Update failed: \(errorMessage)")
        }
    }

    public func deleteGiftCard(id: UUID) throws {
        guard isInitialized, let db = db else {
            throw DatabaseError.notInitialized
        }

        let sql = "DELETE FROM GiftCards WHERE id = ?;"

        var statement: OpaquePointer?
        defer { if statement != nil { sqlite3_finalize(statement) } }

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

    private func parseGiftCard(from statement: OpaquePointer?) throws -> GiftCard? {
        guard let idText = sqlite3_column_text(statement, 0),
              let codeText = sqlite3_column_text(statement, 1),
              let bundleText = sqlite3_column_text(statement, 2),
              let statusText = sqlite3_column_text(statement, 3),
              let cardId = UUID(uuidString: String(cString: idText)),
              let bundleId = UUID(uuidString: String(cString: bundleText)),
              let status = GiftCardStatus(rawValue: String(cString: statusText)) else {
            return nil
        }

        let code = String(cString: codeText)

        let redeemedByUserId: UUID? = sqlite3_column_text(statement, 4).flatMap { UUID(uuidString: String(cString: $0)) }

        let redeemedAt = sqlite3_column_type(statement, 5) != SQLITE_NULL ?
            Date(timeIntervalSince1970: sqlite3_column_double(statement, 5)) : nil

        let createdAt = Date(timeIntervalSince1970: sqlite3_column_double(statement, 6))

        let expiresAt = sqlite3_column_type(statement, 7) != SQLITE_NULL ?
            Date(timeIntervalSince1970: sqlite3_column_double(statement, 7)) : nil

        let metadata = GiftCardMetadata(createdAt: createdAt, expiresAt: expiresAt)

        return GiftCard(
            id: cardId,
            code: code,
            bundleId: bundleId,
            status: status,
            redeemedByUserId: redeemedByUserId,
            redeemedAt: redeemedAt,
            metadata: metadata
        )
    }

}