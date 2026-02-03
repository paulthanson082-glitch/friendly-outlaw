import Foundation

// MARK: - Database Service

/// High-level service for interacting with SQLite database
public class DatabaseService {
    private let database: SQLiteDatabase
    
    public init(database: SQLiteDatabase) {
        self.database = database
    }
    
    /// Initialize with default database path
    public convenience init() {
        self.init(database: SQLiteDatabase())
    }
    
    /// Initialize database schema
    public func initialize() throws {
        try database.initializeSchema()
    }
    
    // MARK: - AI Suggestions Operations
    
    /// Save an AI suggestion to the database
    public func saveAISuggestion(_ suggestion: AISuggestion) throws {
        let sql = """
            INSERT INTO AI_Suggestions (id, prompt_text, output_text, ai_tool, ai_model, 
                                       document_id, timestamp, tokens_used, context)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """
        
        let parameters: [Any] = [
            suggestion.id.uuidString,
            suggestion.promptText,
            suggestion.outputText,
            suggestion.aiTool,
            suggestion.aiModel ?? NSNull(),
            suggestion.documentId?.uuidString ?? NSNull(),
            suggestion.timestamp.timeIntervalSince1970,
            suggestion.tokensUsed ?? NSNull(),
            suggestion.context ?? NSNull()
        ]
        
        try database.executeWithBindings(sql, parameters: parameters)
    }
    
    /// Get all AI suggestions for a specific document
    public func getAISuggestionsForDocument(_ documentId: UUID) throws -> [AISuggestion] {
        let sql = """
            SELECT * FROM AI_Suggestions 
            WHERE document_id = ?
            ORDER BY timestamp DESC
        """
        
        let results = try database.query(sql, parameters: [documentId.uuidString])
        return results.compactMap { AISuggestion.from(dictionary: $0) }
    }
    
    /// Get recent AI suggestions (last N)
    public func getRecentAISuggestions(limit: Int = 10) throws -> [AISuggestion] {
        let sql = """
            SELECT * FROM AI_Suggestions 
            ORDER BY timestamp DESC
            LIMIT ?
        """
        
        let results = try database.query(sql, parameters: [limit])
        return results.compactMap { AISuggestion.from(dictionary: $0) }
    }
    
    /// Get AI suggestions by tool type
    public func getAISuggestionsByTool(_ tool: String, limit: Int = 20) throws -> [AISuggestion] {
        let sql = """
            SELECT * FROM AI_Suggestions 
            WHERE ai_tool = ?
            ORDER BY timestamp DESC
            LIMIT ?
        """
        
        let results = try database.query(sql, parameters: [tool, limit])
        return results.compactMap { AISuggestion.from(dictionary: $0) }
    }
    
    /// Get AI suggestions in a date range
    public func getAISuggestions(from startDate: Date, to endDate: Date) throws -> [AISuggestion] {
        let sql = """
            SELECT * FROM AI_Suggestions 
            WHERE timestamp >= ? AND timestamp <= ?
            ORDER BY timestamp DESC
        """
        
        let parameters = [
            startDate.timeIntervalSince1970,
            endDate.timeIntervalSince1970
        ]
        
        let results = try database.query(sql, parameters: parameters)
        return results.compactMap { AISuggestion.from(dictionary: $0) }
    }
    
    /// Delete AI suggestions older than a specific date
    public func deleteOldAISuggestions(olderThan date: Date) throws {
        let sql = "DELETE FROM AI_Suggestions WHERE timestamp < ?"
        try database.executeWithBindings(sql, parameters: [date.timeIntervalSince1970])
    }
    
    // MARK: - User Sessions Operations
    
    /// Helper function to serialize string arrays to JSON
    private func serializeToJSON(_ array: [String]) -> String {
        if let jsonData = try? JSONSerialization.data(withJSONObject: array),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        return "[]"
    }
    
    /// Helper function to serialize dictionary to JSON
    private func serializeToJSON(_ dictionary: [String: String]) -> String? {
        if let jsonData = try? JSONSerialization.data(withJSONObject: dictionary),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        return nil
    }
    
    /// Create a new user session
    public func createUserSession(_ session: UserSession) throws {
        let sql = """
            INSERT INTO User_Sessions (id, session_start, session_end, tools_used, 
                                      multitasking_mode, screen_size, ai_interactions_count,
                                      toolbar_interactions, duration_seconds, metadata)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """
        
        let parameters: [Any] = [
            session.id.uuidString,
            session.sessionStart.timeIntervalSince1970,
            session.sessionEnd?.timeIntervalSince1970 ?? NSNull(),
            serializeToJSON(session.toolsUsed),
            session.multitaskingMode ?? NSNull(),
            session.screenSize ?? NSNull(),
            session.aiInteractionsCount,
            serializeToJSON(session.toolbarInteractions),
            session.durationSeconds ?? NSNull(),
            session.metadata.flatMap { serializeToJSON($0) } ?? NSNull()
        ]
        
        try database.executeWithBindings(sql, parameters: parameters)
    }
    
    /// Update an existing user session
    public func updateUserSession(_ session: UserSession) throws {
        let sql = """
            UPDATE User_Sessions 
            SET session_end = ?, tools_used = ?, multitasking_mode = ?, 
                screen_size = ?, ai_interactions_count = ?, toolbar_interactions = ?,
                duration_seconds = ?, metadata = ?
            WHERE id = ?
        """
        
        let parameters: [Any] = [
            session.sessionEnd?.timeIntervalSince1970 ?? NSNull(),
            serializeToJSON(session.toolsUsed),
            session.multitaskingMode ?? NSNull(),
            session.screenSize ?? NSNull(),
            session.aiInteractionsCount,
            serializeToJSON(session.toolbarInteractions),
            session.durationSeconds ?? NSNull(),
            session.metadata.flatMap { serializeToJSON($0) } ?? NSNull(),
            session.id.uuidString
        ]
        
        try database.executeWithBindings(sql, parameters: parameters)
    }
    
    /// Get a specific user session
    public func getUserSession(id: UUID) throws -> UserSession? {
        let sql = "SELECT * FROM User_Sessions WHERE id = ?"
        let results = try database.query(sql, parameters: [id.uuidString])
        return results.first.flatMap { UserSession.from(dictionary: $0) }
    }
    
    /// Get recent user sessions
    public func getRecentUserSessions(limit: Int = 10) throws -> [UserSession] {
        let sql = """
            SELECT * FROM User_Sessions 
            ORDER BY session_start DESC
            LIMIT ?
        """
        
        let results = try database.query(sql, parameters: [limit])
        return results.compactMap { UserSession.from(dictionary: $0) }
    }
    
    /// Get active (unclosed) user sessions
    public func getActiveSessions() throws -> [UserSession] {
        let sql = """
            SELECT * FROM User_Sessions 
            WHERE session_end IS NULL
            ORDER BY session_start DESC
        """
        
        let results = try database.query(sql, parameters: [])
        return results.compactMap { UserSession.from(dictionary: $0) }
    }
    
    /// Get user sessions in a date range
    public func getUserSessions(from startDate: Date, to endDate: Date) throws -> [UserSession] {
        let sql = """
            SELECT * FROM User_Sessions 
            WHERE session_start >= ? AND session_start <= ?
            ORDER BY session_start DESC
        """
        
        let parameters = [
            startDate.timeIntervalSince1970,
            endDate.timeIntervalSince1970
        ]
        
        let results = try database.query(sql, parameters: parameters)
        return results.compactMap { UserSession.from(dictionary: $0) }
    }
    
    /// End a session by setting the end time and duration
    public func endSession(id: UUID) throws {
        guard var session = try getUserSession(id: id) else {
            throw DatabaseServiceError.sessionNotFound
        }
        
        session.sessionEnd = Date()
        if let duration = session.sessionEnd?.timeIntervalSince(session.sessionStart) {
            session.durationSeconds = Int(duration)
        }
        
        try updateUserSession(session)
    }
    
    /// Log a tool usage in the current session
    public func logToolUsage(sessionId: UUID, tool: String) throws {
        guard var session = try getUserSession(id: sessionId) else {
            throw DatabaseServiceError.sessionNotFound
        }
        
        if !session.toolsUsed.contains(tool) {
            session.toolsUsed.append(tool)
        }
        
        try updateUserSession(session)
    }
    
    /// Log a toolbar interaction in the current session
    public func logToolbarInteraction(sessionId: UUID, interaction: String) throws {
        guard var session = try getUserSession(id: sessionId) else {
            throw DatabaseServiceError.sessionNotFound
        }
        
        session.toolbarInteractions.append(interaction)
        
        try updateUserSession(session)
    }
    
    /// Increment AI interaction count for a session
    public func incrementAIInteractionCount(sessionId: UUID) throws {
        guard var session = try getUserSession(id: sessionId) else {
            throw DatabaseServiceError.sessionNotFound
        }
        
        session.aiInteractionsCount += 1
        
        try updateUserSession(session)
    }
    
    // MARK: - AI Configurations Operations
    
    /// Save an AI configuration
    public func saveAIConfiguration(_ configuration: AIConfigurationStorage) throws {
        let sql = """
            INSERT OR REPLACE INTO AI_Configurations (id, user_id, configuration_json, 
                                                      created_at, updated_at)
            VALUES (?, ?, ?, ?, ?)
        """
        
        let parameters: [Any] = [
            configuration.id.uuidString,
            configuration.userId,
            configuration.configurationJSON,
            configuration.createdAt.timeIntervalSince1970,
            configuration.updatedAt.timeIntervalSince1970
        ]
        
        try database.executeWithBindings(sql, parameters: parameters)
    }
    
    /// Get AI configuration for a specific user
    public func getAIConfiguration(userId: String) throws -> AIConfigurationStorage? {
        let sql = """
            SELECT * FROM AI_Configurations 
            WHERE user_id = ?
            ORDER BY updated_at DESC
            LIMIT 1
        """
        
        let results = try database.query(sql, parameters: [userId])
        return results.first.flatMap { AIConfigurationStorage.from(dictionary: $0) }
    }
    
    /// Update AI configuration
    public func updateAIConfiguration(_ configuration: AIConfigurationStorage) throws {
        var updatedConfig = configuration
        updatedConfig.updatedAt = Date()
        
        let sql = """
            UPDATE AI_Configurations 
            SET configuration_json = ?, updated_at = ?
            WHERE id = ?
        """
        
        let parameters: [Any] = [
            updatedConfig.configurationJSON,
            updatedConfig.updatedAt.timeIntervalSince1970,
            updatedConfig.id.uuidString
        ]
        
        try database.executeWithBindings(sql, parameters: parameters)
    }
    
    /// Delete AI configuration
    public func deleteAIConfiguration(id: UUID) throws {
        let sql = "DELETE FROM AI_Configurations WHERE id = ?"
        try database.executeWithBindings(sql, parameters: [id.uuidString])
    }
    
    /// Get all AI configurations for a user
    public func getAllAIConfigurations(userId: String) throws -> [AIConfigurationStorage] {
        let sql = """
            SELECT * FROM AI_Configurations 
            WHERE user_id = ?
            ORDER BY updated_at DESC
        """
        
        let results = try database.query(sql, parameters: [userId])
        return results.compactMap { AIConfigurationStorage.from(dictionary: $0) }
    }
    
    // MARK: - Analytics and Statistics
    
    /// Get total number of AI interactions
    public func getTotalAIInteractions() throws -> Int {
        let sql = "SELECT COUNT(*) as count FROM AI_Suggestions"
        let results = try database.query(sql, parameters: [])
        return results.first?["count"] as? Int ?? 0
    }
    
    /// Get most used AI tools
    public func getMostUsedAITools(limit: Int = 5) throws -> [(tool: String, count: Int)] {
        let sql = """
            SELECT ai_tool, COUNT(*) as count 
            FROM AI_Suggestions 
            GROUP BY ai_tool 
            ORDER BY count DESC 
            LIMIT ?
        """
        
        let results = try database.query(sql, parameters: [limit])
        return results.compactMap { row in
            guard let tool = row["ai_tool"] as? String,
                  let count = row["count"] as? Int else {
                return nil
            }
            return (tool, count)
        }
    }
    
    /// Get average session duration
    public func getAverageSessionDuration() throws -> Double {
        let sql = """
            SELECT AVG(duration_seconds) as avg_duration 
            FROM User_Sessions 
            WHERE duration_seconds IS NOT NULL
        """
        
        let results = try database.query(sql, parameters: [])
        return results.first?["avg_duration"] as? Double ?? 0
    }
}

// MARK: - Errors

public enum DatabaseServiceError: LocalizedError {
    case sessionNotFound
    case configurationNotFound
    case invalidData
    
    public var errorDescription: String? {
        switch self {
        case .sessionNotFound:
            return "User session not found"
        case .configurationNotFound:
            return "AI configuration not found"
        case .invalidData:
            return "Invalid data provided"
        }
    }
}
