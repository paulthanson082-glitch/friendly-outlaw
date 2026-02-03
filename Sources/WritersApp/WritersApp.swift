import Foundation

/// Main application class for the Writers App
public class WritersApp {
    public let templateManager: TemplateManager
    public let documentManager: DocumentManager
    public let databaseManager: DatabaseManager
    public private(set) var aiService: AIService?
    public private(set) var currentUserId: UUID?
    private var currentSessionId: UUID?

    public init() {
        self.templateManager = TemplateManager()
        self.documentManager = DocumentManager()
        self.databaseManager = DatabaseManager()
        try? self.databaseManager.initialize()
    }

    /// Initialize with AI capabilities
    public init(aiConfiguration: AIConfiguration) {
        self.templateManager = TemplateManager()
        self.documentManager = DocumentManager()
        self.databaseManager = DatabaseManager()
        try? self.databaseManager.initialize()
        self.aiService = AIService(configuration: aiConfiguration)
    }
    
    /// Initialize with custom database path
    public init(databasePath: String? = nil) {
        self.templateManager = TemplateManager()
        self.documentManager = DocumentManager()
        self.databaseManager = DatabaseManager(databasePath: databasePath)
        try? self.databaseManager.initialize()
    }

    /// Enable AI features by providing configuration
    public func enableAI(configuration: AIConfiguration, userId: UUID? = nil) {
        self.aiService = AIService(configuration: configuration)
        if let uid = userId {
            self.currentUserId = uid
            try? self.databaseManager.saveAIConfiguration(userId: uid, configuration: configuration)
        }
    }

    /// Disable AI features
    public func disableAI() {
        self.aiService = nil
    }

    /// Check if AI is available
    public var isAIEnabled: Bool {
        return aiService != nil
    }

    // MARK: - Document Creation from Templates

    /// Creates a new document from a template
    public func createDocumentFromTemplate(
        templateId: UUID,
        values: [String: String]
    ) -> Document? {
        guard let template = templateManager.getTemplate(id: templateId) else {
            return nil
        }

        let document = template.createDocument(with: values)
        documentManager.createDocument(document)
        return document
    }

    /// Creates a blank document
    public func createBlankDocument(
        title: String,
        category: TemplateCategory
    ) -> Document {
        let document = Document(
            title: title,
            content: "",
            category: category
        )
        documentManager.createDocument(document)
        return document
    }

    // MARK: - Export Functionality

    /// Exports a document to a string format
    public func exportDocument(id: UUID, format: ExportFormat = .markdown) -> String? {
        guard let document = documentManager.getDocument(id: id) else {
            return nil
        }

        switch format {
        case .markdown:
            return exportAsMarkdown(document)
        case .plainText:
            return document.content
        case .html:
            return exportAsHTML(document)
        }
    }

    private func exportAsMarkdown(_ document: Document) -> String {
        return """
        # \(document.title)

        **Category:** \(document.category.rawValue)
        **Created:** \(formatDate(document.metadata.created))
        **Modified:** \(formatDate(document.metadata.modified))
        **Word Count:** \(document.wordCount)

        ---

        \(document.content)
        """
    }

    private func exportAsHTML(_ document: Document) -> String {
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <title>\(document.title)</title>
            <meta charset="UTF-8">
            <style>
                body { font-family: Georgia, serif; max-width: 800px; margin: 0 auto; padding: 20px; }
                h1 { color: #333; }
                .metadata { color: #666; font-size: 0.9em; }
                .content { line-height: 1.6; }
            </style>
        </head>
        <body>
            <h1>\(document.title)</h1>
            <div class="metadata">
                <p>Category: \(document.category.rawValue)</p>
                <p>Word Count: \(document.wordCount)</p>
                <p>Created: \(formatDate(document.metadata.created))</p>
            </div>
            <div class="content">
                <pre>\(document.content)</pre>
            </div>
        </body>
        </html>
        """
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    // MARK: - Session Management
    
    /// Starts a new user session
    public func startSession(userId: UUID, multitaskingMode: String? = nil) {
        self.currentUserId = userId
        let session = UserSession(userId: userId, multitaskingMode: multitaskingMode)
        self.currentSessionId = session.id
        try? databaseManager.insertUserSession(session)
    }
    
    /// Ends the current session
    public func endSession() {
        guard let sessionId = currentSessionId, let userId = currentUserId else { return }
        
        if let sessions = try? databaseManager.getUserSessions(userId: userId),
           let index = sessions.firstIndex(where: { $0.id == sessionId }) {
            var session = sessions[index]
            session.endTime = Date()
            let start = session.startTime.timeIntervalSince1970
            if let end = session.endTime?.timeIntervalSince1970 {
                session.durationSeconds = Int(end - start)
            }
            try? databaseManager.updateUserSession(session)
        }
        
        currentSessionId = nil
    }
    
    /// Updates session statistics
    public func updateSessionStats(wordsWritten: Int, aiInteractions: Int) {
        guard let sessionId = currentSessionId, let userId = currentUserId else { return }
        
        if let sessions = try? databaseManager.getUserSessions(userId: userId),
           let index = sessions.firstIndex(where: { $0.id == sessionId }) {
            var session = sessions[index]
            session.wordsWritten = wordsWritten
            session.aiInteractions = aiInteractions
            try? databaseManager.updateUserSession(session)
        }
    }

    // MARK: - AI-Powered Features

    /// Get AI assistance for a document
    public func getAIAssistance(
        documentId: UUID,
        type: AIAssistanceType,
        context: AIContext? = nil
    ) async throws -> AIResponse {
        guard let ai = aiService else {
            throw AIError.aiNotEnabled
        }

        guard let document = documentManager.getDocument(id: documentId) else {
            throw AIError.documentNotFound
        }

        return try await ai.getAssistance(
            text: document.content,
            type: type,
            context: context
        )
    }

    /// Continue writing a document with AI
    public func continueDocument(
        documentId: UUID,
        context: AIContext? = nil,
        appendToDocument: Bool = false
    ) async throws -> String {
        guard let ai = aiService else {
            throw AIError.aiNotEnabled
        }

        guard let document = documentManager.getDocument(id: documentId) else {
            throw AIError.documentNotFound
        }

        let continuation = try await ai.continueWriting(
            text: document.content,
            context: context
        )
        
        // Log AI suggestion if user is set
        if let userId = currentUserId {
            let suggestion = AISuggestion(
                userId: userId,
                documentId: documentId,
                toolUsed: "Continue Writing",
                prompt: document.content,
                response: continuation
            )
            try? databaseManager.insertAISuggestion(suggestion)
        }

        if appendToDocument {
            var updatedDocument = document
            updatedDocument.content += "\n\n" + continuation
            documentManager.updateDocument(updatedDocument)
        }

        return continuation
    }

    /// Improve document content with AI
    public func improveDocument(
        documentId: UUID,
        context: AIContext? = nil,
        replaceContent: Bool = false
    ) async throws -> String {
        guard let ai = aiService else {
            throw AIError.aiNotEnabled
        }

        guard let document = documentManager.getDocument(id: documentId) else {
            throw AIError.documentNotFound
        }

        let improved = try await ai.improveText(
            text: document.content,
            context: context
        )
        
        // Log AI suggestion if user is set
        if let userId = currentUserId {
            let suggestion = AISuggestion(
                userId: userId,
                documentId: documentId,
                toolUsed: "Improve Text",
                prompt: document.content,
                response: improved
            )
            try? databaseManager.insertAISuggestion(suggestion)
        }

        if replaceContent {
            var updatedDocument = document
            updatedDocument.content = improved
            documentManager.updateDocument(updatedDocument)
        }

        return improved
    }

    /// Generate title suggestions for a document
    public func generateDocumentTitles(
        documentId: UUID,
        context: AIContext? = nil
    ) async throws -> [String] {
        guard let ai = aiService else {
            throw AIError.aiNotEnabled
        }

        guard let document = documentManager.getDocument(id: documentId) else {
            throw AIError.documentNotFound
        }

        return try await ai.generateTitles(
            content: document.content,
            context: context
        )
    }

    /// Analyze a document comprehensively
    public func analyzeDocument(documentId: UUID) async throws -> DocumentAnalysis {
        guard let ai = aiService else {
            throw AIError.aiNotEnabled
        }

        guard let document = documentManager.getDocument(id: documentId) else {
            throw AIError.documentNotFound
        }

        return try await ai.analyzeDocument(document: document)
    }

    /// Get writing insights for a document
    public func getDocumentInsights(documentId: UUID) async throws -> WritingInsights {
        guard let ai = aiService else {
            throw AIError.aiNotEnabled
        }

        guard let document = documentManager.getDocument(id: documentId) else {
            throw AIError.documentNotFound
        }

        return try await ai.getWritingInsights(document: document)
    }

    /// Brainstorm ideas for a topic
    public func brainstormIdeas(
        topic: String,
        context: AIContext? = nil
    ) async throws -> String {
        guard let ai = aiService else {
            throw AIError.aiNotEnabled
        }

        return try await ai.brainstormIdeas(topic: topic, context: context)
    }

    /// Generate outline from concept
    public func generateOutline(
        concept: String,
        context: AIContext? = nil
    ) async throws -> String {
        guard let ai = aiService else {
            throw AIError.aiNotEnabled
        }

        return try await ai.generateOutline(concept: concept, context: context)
    }

    /// Develop a character concept
    public func developCharacter(
        characterConcept: String,
        context: AIContext? = nil
    ) async throws -> String {
        guard let ai = aiService else {
            throw AIError.aiNotEnabled
        }

        return try await ai.developCharacter(
            characterConcept: characterConcept,
            context: context
        )
    }

    // MARK: - Statistics
    
    /// Gets AI tool usage statistics
    public func getAIToolUsageStats(userId: UUID? = nil) throws -> [AIToolUsageStats] {
        let uid = userId ?? currentUserId ?? UUID()
        return try databaseManager.getAIToolUsageStats(userId: uid)
    }
    
    /// Gets session statistics
    public func getSessionStats(userId: UUID? = nil) throws -> SessionStats {
        let uid = userId ?? currentUserId ?? UUID()
        return try databaseManager.getSessionStats(userId: uid)
    }
    
    /// Gets AI suggestions with pagination
    public func getAISuggestions(userId: UUID? = nil, limit: Int = 50, offset: Int = 0) throws -> [AISuggestion] {
        let uid = userId ?? currentUserId ?? UUID()
        return try databaseManager.getAISuggestions(userId: uid, limit: limit, offset: offset)
    }
    
    /// Gets user sessions sorted by duration
    public func getUserSessions(userId: UUID? = nil, sortByDuration: Bool = false) throws -> [UserSession] {
        let uid = userId ?? currentUserId ?? UUID()
        return try databaseManager.getUserSessions(userId: uid, sortByDuration: sortByDuration)
    }

    /// Gets application statistics
    public func getStatistics() -> AppStatistics {
        let allDocuments = documentManager.getAllDocuments()
        let totalWords = documentManager.getTotalWordCount()
        let totalDocuments = allDocuments.count
        let averageWords = totalDocuments > 0 ? totalWords / totalDocuments : 0

        let templateCount = templateManager.getAllTemplates().count
        let categoryCounts = Dictionary(grouping: allDocuments, by: { $0.category })
            .mapValues { $0.count }

        return AppStatistics(
            totalDocuments: totalDocuments,
            totalWordCount: totalWords,
            averageWordCount: averageWords,
            totalTemplates: templateCount,
            documentsByCategory: categoryCounts
        )
    }
}

// MARK: - Supporting Types

public enum ExportFormat {
    case markdown
    case plainText
    case html
}

public struct AppStatistics {
    public let totalDocuments: Int
    public let totalWordCount: Int
    public let averageWordCount: Int
    public let totalTemplates: Int
    public let documentsByCategory: [TemplateCategory: Int]

    public init(
        totalDocuments: Int,
        totalWordCount: Int,
        averageWordCount: Int,
        totalTemplates: Int,
        documentsByCategory: [TemplateCategory: Int]
    ) {
        self.totalDocuments = totalDocuments
        self.totalWordCount = totalWordCount
        self.averageWordCount = averageWordCount
        self.totalTemplates = totalTemplates
        self.documentsByCategory = documentsByCategory
    }
}

public enum AIError: LocalizedError {
    case aiNotEnabled
    case documentNotFound

    public var errorDescription: String? {
        switch self {
        case .aiNotEnabled:
            return "AI features are not enabled. Please configure AI with enableAI(configuration:) first."
        case .documentNotFound:
            return "The specified document was not found."
        }
    }
}
