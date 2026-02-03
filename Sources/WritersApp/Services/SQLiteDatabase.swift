import Foundation
import CSQLite

// MARK: - SQLite Database Manager

/// Core SQLite database manager for persisting AI-related data, user sessions, and configurations
public class SQLiteDatabase {
    private var db: OpaquePointer?
    private let dbPath: String
    
    // MARK: - Initialization
    
    /// Initialize database with a specific file path
    public init(path: String? = nil) {
        if let path = path {
            self.dbPath = path
        } else {
            // Default to Application Support directory
            let fileManager = FileManager.default
            let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let dbDirectory = appSupportURL.appendingPathComponent("WritersApp", isDirectory: true)
            
            // Create directory if it doesn't exist
            try? fileManager.createDirectory(at: dbDirectory, withIntermediateDirectories: true)
            
            self.dbPath = dbDirectory.appendingPathComponent("writersapp.db").path
        }
    }
    
    deinit {
        close()
    }
    
    // MARK: - Connection Management
    
    /// Open database connection
    @discardableResult
    public func open() throws -> Bool {
        guard db == nil else { return true }
        
        let result = sqlite3_open(dbPath, &db)
        guard result == SQLITE_OK else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            sqlite3_close(db)
            db = nil
            throw SQLiteError.openDatabase(message: errorMessage)
        }
        
        return true
    }
    
    /// Close database connection
    public func close() {
        guard db != nil else { return }
        sqlite3_close(db)
        db = nil
    }
    
    /// Check if database is open
    public var isOpen: Bool {
        return db != nil
    }
    
    // MARK: - Schema Creation
    
    /// Initialize database schema with all required tables
    public func initializeSchema() throws {
        try open()
        
        // Create AI_Suggestions table
        try execute("""
            CREATE TABLE IF NOT EXISTS AI_Suggestions (
                id TEXT PRIMARY KEY,
                prompt_text TEXT NOT NULL,
                output_text TEXT NOT NULL,
                ai_tool TEXT NOT NULL,
                ai_model TEXT,
                document_id TEXT,
                timestamp REAL NOT NULL,
                tokens_used INTEGER,
                context TEXT
            )
        """)
        
        // Create User_Sessions table
        try execute("""
            CREATE TABLE IF NOT EXISTS User_Sessions (
                id TEXT PRIMARY KEY,
                session_start REAL NOT NULL,
                session_end REAL,
                tools_used TEXT NOT NULL,
                multitasking_mode TEXT,
                screen_size TEXT,
                ai_interactions_count INTEGER DEFAULT 0,
                toolbar_interactions TEXT,
                duration_seconds INTEGER,
                metadata TEXT
            )
        """)
        
        // Create AI_Configurations table
        try execute("""
            CREATE TABLE IF NOT EXISTS AI_Configurations (
                id TEXT PRIMARY KEY,
                user_id TEXT NOT NULL,
                configuration_json TEXT NOT NULL,
                created_at REAL NOT NULL,
                updated_at REAL NOT NULL
            )
        """)
        
        // Create indexes for better query performance
        try execute("CREATE INDEX IF NOT EXISTS idx_ai_suggestions_timestamp ON AI_Suggestions(timestamp)")
        try execute("CREATE INDEX IF NOT EXISTS idx_ai_suggestions_document ON AI_Suggestions(document_id)")
        try execute("CREATE INDEX IF NOT EXISTS idx_user_sessions_start ON User_Sessions(session_start)")
        try execute("CREATE INDEX IF NOT EXISTS idx_ai_configs_user ON AI_Configurations(user_id)")
    }
    
    // MARK: - Execute Statement
    
    /// Execute a SQL statement without returning results
    public func execute(_ sql: String) throws {
        try open()
        
        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }
        
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw SQLiteError.prepare(message: String(cString: sqlite3_errmsg(db)))
        }
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw SQLiteError.step(message: String(cString: sqlite3_errmsg(db)))
        }
    }
    
    // MARK: - Query with Results
    
    /// Execute a SQL query and return rows as dictionaries
    public func query(_ sql: String, parameters: [Any] = []) throws -> [[String: Any]] {
        try open()
        
        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }
        
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw SQLiteError.prepare(message: String(cString: sqlite3_errmsg(db)))
        }
        
        // Bind parameters
        for (index, parameter) in parameters.enumerated() {
            let bindIndex = Int32(index + 1)
            
            if let stringValue = parameter as? String {
                sqlite3_bind_text(statement, bindIndex, (stringValue as NSString).utf8String, -1, nil)
            } else if let intValue = parameter as? Int {
                sqlite3_bind_int64(statement, bindIndex, Int64(intValue))
            } else if let doubleValue = parameter as? Double {
                sqlite3_bind_double(statement, bindIndex, doubleValue)
            } else if parameter is NSNull {
                sqlite3_bind_null(statement, bindIndex)
            }
        }
        
        var results: [[String: Any]] = []
        
        while sqlite3_step(statement) == SQLITE_ROW {
            var row: [String: Any] = [:]
            let columnCount = sqlite3_column_count(statement)
            
            for i in 0..<columnCount {
                let columnName = String(cString: sqlite3_column_name(statement, i))
                let columnType = sqlite3_column_type(statement, i)
                
                switch columnType {
                case SQLITE_INTEGER:
                    row[columnName] = Int(sqlite3_column_int64(statement, i))
                case SQLITE_FLOAT:
                    row[columnName] = sqlite3_column_double(statement, i)
                case SQLITE_TEXT:
                    if let text = sqlite3_column_text(statement, i) {
                        row[columnName] = String(cString: text)
                    }
                case SQLITE_NULL:
                    row[columnName] = NSNull()
                default:
                    break
                }
            }
            
            results.append(row)
        }
        
        return results
    }
    
    // MARK: - Insert with Bindings
    
    /// Execute an insert/update statement with parameter binding
    public func executeWithBindings(_ sql: String, parameters: [Any]) throws {
        try open()
        
        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }
        
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw SQLiteError.prepare(message: String(cString: sqlite3_errmsg(db)))
        }
        
        // Bind parameters
        for (index, parameter) in parameters.enumerated() {
            let bindIndex = Int32(index + 1)
            
            if let stringValue = parameter as? String {
                sqlite3_bind_text(statement, bindIndex, (stringValue as NSString).utf8String, -1, nil)
            } else if let intValue = parameter as? Int {
                sqlite3_bind_int64(statement, bindIndex, Int64(intValue))
            } else if let doubleValue = parameter as? Double {
                sqlite3_bind_double(statement, bindIndex, doubleValue)
            } else if parameter is NSNull {
                sqlite3_bind_null(statement, bindIndex)
            }
        }
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw SQLiteError.step(message: String(cString: sqlite3_errmsg(db)))
        }
    }
    
    // MARK: - Utility Methods
    
    /// Get the path to the database file
    public func getDatabasePath() -> String {
        return dbPath
    }
    
    /// Check if a table exists
    public func tableExists(_ tableName: String) throws -> Bool {
        // Validate table name to prevent SQL injection
        let allowedTables = ["AI_Suggestions", "User_Sessions", "AI_Configurations", "sqlite_master"]
        guard allowedTables.contains(tableName) else {
            throw SQLiteError.bind(message: "Invalid table name")
        }
        
        let sql = "SELECT name FROM sqlite_master WHERE type='table' AND name=?"
        let results = try query(sql, parameters: [tableName])
        return !results.isEmpty
    }

    /// Delete all data from a table (for testing)
    public func clearTable(_ tableName: String) throws {
        // Validate table name to prevent SQL injection
        let allowedTables = ["AI_Suggestions", "User_Sessions", "AI_Configurations"]
        guard allowedTables.contains(tableName) else {
            throw SQLiteError.bind(message: "Invalid table name")
        }
        
        try execute("DELETE FROM \(tableName)")
    }
}

// MARK: - Errors

public enum SQLiteError: LocalizedError {
    case openDatabase(message: String)
    case prepare(message: String)
    case step(message: String)
    case bind(message: String)
    
    public var errorDescription: String? {
        switch self {
        case .openDatabase(let message):
            return "Failed to open database: \(message)"
        case .prepare(let message):
            return "Failed to prepare statement: \(message)"
        case .step(let message):
            return "Failed to execute statement: \(message)"
        case .bind(let message):
            return "Failed to bind parameter: \(message)"
        }
    }
}
