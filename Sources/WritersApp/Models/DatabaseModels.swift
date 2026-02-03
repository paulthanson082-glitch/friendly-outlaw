import Foundation

// MARK: - AI Suggestion Model

/// Represents an AI suggestion stored in the database
public struct AISuggestion: Codable, Identifiable {
    public let id: UUID
    public let promptText: String
    public let outputText: String
    public let aiTool: String
    public let aiModel: String?
    public let documentId: UUID?
    public let timestamp: Date
    public let tokensUsed: Int?
    public let context: String?
    
    public init(
        id: UUID = UUID(),
        promptText: String,
        outputText: String,
        aiTool: String,
        aiModel: String? = nil,
        documentId: UUID? = nil,
        timestamp: Date = Date(),
        tokensUsed: Int? = nil,
        context: String? = nil
    ) {
        self.id = id
        self.promptText = promptText
        self.outputText = outputText
        self.aiTool = aiTool
        self.aiModel = aiModel
        self.documentId = documentId
        self.timestamp = timestamp
        self.tokensUsed = tokensUsed
        self.context = context
    }
    
    /// Convert to dictionary for database insertion
    public func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id.uuidString,
            "prompt_text": promptText,
            "output_text": outputText,
            "ai_tool": aiTool,
            "timestamp": timestamp.timeIntervalSince1970
        ]
        
        if let aiModel = aiModel {
            dict["ai_model"] = aiModel
        }
        
        if let documentId = documentId {
            dict["document_id"] = documentId.uuidString
        }
        
        if let tokensUsed = tokensUsed {
            dict["tokens_used"] = tokensUsed
        }
        
        if let context = context {
            dict["context"] = context
        }
        
        return dict
    }
    
    /// Create from database dictionary
    public static func from(dictionary: [String: Any]) -> AISuggestion? {
        guard let idString = dictionary["id"] as? String,
              let id = UUID(uuidString: idString),
              let promptText = dictionary["prompt_text"] as? String,
              let outputText = dictionary["output_text"] as? String,
              let aiTool = dictionary["ai_tool"] as? String,
              let timestamp = dictionary["timestamp"] as? Double else {
            return nil
        }
        
        let aiModel = dictionary["ai_model"] as? String
        let documentId: UUID?
        if let docIdString = dictionary["document_id"] as? String {
            documentId = UUID(uuidString: docIdString)
        } else {
            documentId = nil
        }
        
        let tokensUsed = dictionary["tokens_used"] as? Int
        let context = dictionary["context"] as? String
        
        return AISuggestion(
            id: id,
            promptText: promptText,
            outputText: outputText,
            aiTool: aiTool,
            aiModel: aiModel,
            documentId: documentId,
            timestamp: Date(timeIntervalSince1970: timestamp),
            tokensUsed: tokensUsed,
            context: context
        )
    }
}

// MARK: - User Session Model

/// Represents a user session tracked in the database
public struct UserSession: Codable, Identifiable {
    public let id: UUID
    public let sessionStart: Date
    public var sessionEnd: Date?
    public var toolsUsed: [String]
    public var multitaskingMode: String?
    public var screenSize: String?
    public var aiInteractionsCount: Int
    public var toolbarInteractions: [String]
    public var durationSeconds: Int?
    public var metadata: [String: String]?
    
    public init(
        id: UUID = UUID(),
        sessionStart: Date = Date(),
        sessionEnd: Date? = nil,
        toolsUsed: [String] = [],
        multitaskingMode: String? = nil,
        screenSize: String? = nil,
        aiInteractionsCount: Int = 0,
        toolbarInteractions: [String] = [],
        durationSeconds: Int? = nil,
        metadata: [String: String]? = nil
    ) {
        self.id = id
        self.sessionStart = sessionStart
        self.sessionEnd = sessionEnd
        self.toolsUsed = toolsUsed
        self.multitaskingMode = multitaskingMode
        self.screenSize = screenSize
        self.aiInteractionsCount = aiInteractionsCount
        self.toolbarInteractions = toolbarInteractions
        self.durationSeconds = durationSeconds
        self.metadata = metadata
    }
    
    /// Convert to dictionary for database insertion
    public func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id.uuidString,
            "session_start": sessionStart.timeIntervalSince1970,
            "ai_interactions_count": aiInteractionsCount
        ]
        
        // Serialize toolsUsed as JSON
        if let jsonData = try? JSONSerialization.data(withJSONObject: toolsUsed),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            dict["tools_used"] = jsonString
        } else {
            dict["tools_used"] = "[]"
        }
        
        // Serialize toolbarInteractions as JSON
        if let jsonData = try? JSONSerialization.data(withJSONObject: toolbarInteractions),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            dict["toolbar_interactions"] = jsonString
        } else {
            dict["toolbar_interactions"] = "[]"
        }
        
        if let sessionEnd = sessionEnd {
            dict["session_end"] = sessionEnd.timeIntervalSince1970
        }
        
        if let multitaskingMode = multitaskingMode {
            dict["multitasking_mode"] = multitaskingMode
        }
        
        if let screenSize = screenSize {
            dict["screen_size"] = screenSize
        }
        
        if let durationSeconds = durationSeconds {
            dict["duration_seconds"] = durationSeconds
        }
        
        if let metadata = metadata,
           let jsonData = try? JSONSerialization.data(withJSONObject: metadata),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            dict["metadata"] = jsonString
        }
        
        return dict
    }
    
    /// Create from database dictionary
    public static func from(dictionary: [String: Any]) -> UserSession? {
        guard let idString = dictionary["id"] as? String,
              let id = UUID(uuidString: idString),
              let sessionStartTimestamp = dictionary["session_start"] as? Double,
              let toolsUsedString = dictionary["tools_used"] as? String,
              let aiInteractionsCount = dictionary["ai_interactions_count"] as? Int else {
            return nil
        }
        
        let sessionStart = Date(timeIntervalSince1970: sessionStartTimestamp)
        
        // Deserialize toolsUsed from JSON
        let toolsUsed: [String]
        if let jsonData = toolsUsedString.data(using: .utf8),
           let array = try? JSONSerialization.jsonObject(with: jsonData) as? [String] {
            toolsUsed = array
        } else {
            toolsUsed = []
        }
        
        let sessionEnd: Date?
        if let sessionEndTimestamp = dictionary["session_end"] as? Double {
            sessionEnd = Date(timeIntervalSince1970: sessionEndTimestamp)
        } else {
            sessionEnd = nil
        }
        
        let multitaskingMode = dictionary["multitasking_mode"] as? String
        let screenSize = dictionary["screen_size"] as? String
        let durationSeconds = dictionary["duration_seconds"] as? Int
        
        let toolbarInteractionsString = dictionary["toolbar_interactions"] as? String ?? "[]"
        
        // Deserialize toolbarInteractions from JSON
        let toolbarInteractions: [String]
        if let jsonData = toolbarInteractionsString.data(using: .utf8),
           let array = try? JSONSerialization.jsonObject(with: jsonData) as? [String] {
            toolbarInteractions = array
        } else {
            toolbarInteractions = []
        }
        
        let metadata: [String: String]?
        if let metadataString = dictionary["metadata"] as? String,
           let jsonData = metadataString.data(using: .utf8),
           let dict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: String] {
            metadata = dict
        } else {
            metadata = nil
        }
        
        return UserSession(
            id: id,
            sessionStart: sessionStart,
            sessionEnd: sessionEnd,
            toolsUsed: toolsUsed,
            multitaskingMode: multitaskingMode,
            screenSize: screenSize,
            aiInteractionsCount: aiInteractionsCount,
            toolbarInteractions: toolbarInteractions,
            durationSeconds: durationSeconds,
            metadata: metadata
        )
    }
}

// MARK: - AI Configuration Storage Model

/// Represents AI configuration stored in the database
public struct AIConfigurationStorage: Codable, Identifiable {
    public let id: UUID
    public let userId: String
    public let configurationJSON: String
    public let createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: UUID = UUID(),
        userId: String,
        configurationJSON: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.configurationJSON = configurationJSON
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    /// Convert to dictionary for database insertion
    public func toDictionary() -> [String: Any] {
        return [
            "id": id.uuidString,
            "user_id": userId,
            "configuration_json": configurationJSON,
            "created_at": createdAt.timeIntervalSince1970,
            "updated_at": updatedAt.timeIntervalSince1970
        ]
    }
    
    /// Create from database dictionary
    public static func from(dictionary: [String: Any]) -> AIConfigurationStorage? {
        guard let idString = dictionary["id"] as? String,
              let id = UUID(uuidString: idString),
              let userId = dictionary["user_id"] as? String,
              let configurationJSON = dictionary["configuration_json"] as? String,
              let createdAtTimestamp = dictionary["created_at"] as? Double,
              let updatedAtTimestamp = dictionary["updated_at"] as? Double else {
            return nil
        }
        
        return AIConfigurationStorage(
            id: id,
            userId: userId,
            configurationJSON: configurationJSON,
            createdAt: Date(timeIntervalSince1970: createdAtTimestamp),
            updatedAt: Date(timeIntervalSince1970: updatedAtTimestamp)
        )
    }
    
    /// Create from AIConfiguration
    public static func from(aiConfiguration: AIConfiguration, userId: String) -> AIConfigurationStorage? {
        let encoder = JSONEncoder()
        guard let jsonData = try? encoder.encode(aiConfiguration),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return nil
        }
        
        return AIConfigurationStorage(
            userId: userId,
            configurationJSON: jsonString
        )
    }
    
    /// Decode to AIConfiguration
    public func toAIConfiguration() -> AIConfiguration? {
        guard let jsonData = configurationJSON.data(using: .utf8) else {
            return nil
        }
        
        let decoder = JSONDecoder()
        return try? decoder.decode(AIConfiguration.self, from: jsonData)
    }
}
