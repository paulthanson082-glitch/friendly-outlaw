import Foundation

/// Main application class for the Writers App
public class WritersApp {
    public let templateManager: TemplateManager
    public let documentManager: DocumentManager
    public let issueManager: IssueManager
    public let kanbanManager: KanbanManager
    public let hardwareManager: HardwareManager
    public let databaseManager: DatabaseManager
    public let pluginManager: PluginManager
    public let encouragementService: EncouragementService
    public let versionControl: DoltVersionControlService
    public let giftCardManager: GiftCardManager
    public let crmManager: CRMManager
    public private(set) var guiService: GuiNewService?
    public private(set) var aiService: AIService?
    public private(set) var chatbotService: ChatbotService?
    public private(set) var hermesService: HermesService?
    public private(set) var ragieService: RagieService?
    public private(set) var writingAdvisorService: WritingAdvisorService?
    public private(set) var currentUserId: UUID?
    private var currentSessionId: UUID?
    private var memoryPlugin: ClaudeMemoryPlugin?
    private(set) var appSettings: AppSettings

    // MARK: - Cowork Mode
    public let prospectDatabase: ProspectDatabase
    public let browserService: BrowserService
    public private(set) var gmailService: GmailService?
    public private(set) var activeCoworkSession: CoworkSession?

    public convenience init() {
        self.init(databaseManager: DatabaseManager(), aiConfiguration: nil)
    }

    /// Initialize with AI capabilities
    public convenience init(aiConfiguration: AIConfiguration) {
        self.init(databaseManager: DatabaseManager(), aiConfiguration: aiConfiguration)
    }

    /// Initialize with custom database path
    public convenience init(databasePath: String? = nil) {
        self.init(databaseManager: DatabaseManager(databasePath: databasePath), aiConfiguration: nil)
    }

    private init(databaseManager: DatabaseManager, aiConfiguration: AIConfiguration?) {
        self.templateManager = TemplateManager()
        self.documentManager = DocumentManager()
        self.issueManager = IssueManager()
        self.kanbanManager = KanbanManager()
        self.hardwareManager = HardwareManager()
        self.databaseManager = databaseManager
        self.pluginManager = PluginManager.shared
        self.encouragementService = EncouragementService()
        self.versionControl = DoltVersionControlService(databaseManager: databaseManager)
        self.spoilerProtection = SpoilerProtectionService()
        self.giftCardManager = GiftCardManager(databaseManager: databaseManager)
        self.crmManager = CRMManager()
        self.guiService = nil
        self.appSettings = AppSettings()
        self.prospectDatabase = ProspectDatabase()
        self.browserService = BrowserService()
        self.gmailService = nil
        self.activeCoworkSession = nil
        let aiSvc = aiConfiguration.map { AIService(configuration: $0) }
        self.aiService = aiSvc
        if let svc = aiSvc {
            self.chatbotService = ChatbotService(
                aiService: svc,
                documentManager: self.documentManager,
                templateManager: self.templateManager
            )
            self.writingAdvisorService = WritingAdvisorService(aiService: svc)
            self.hermesService = HermesService(
                aiService: svc,
                documentManager: self.documentManager,
                templateManager: self.templateManager
            )
            self.writingAdvisorService = WritingAdvisorService(aiService: svc)
        } else {
            self.chatbotService = nil
            self.writingAdvisorService = nil
            self.hermesService = nil
            self.writingAdvisorService = nil
        }
        try? databaseManager.initialize()
    }

    /// Enables the application's AI features by creating and wiring AI-related services.
    /// - Parameters:
    ///   - configuration: Configuration used to initialize the AI subsystem.
    ///   - userId: Optional user identifier; when provided the AI configuration is associated with and persisted for that user.
    public func enableAI(configuration: AIConfiguration, userId: UUID? = nil) {
        let aiSvc = AIService(configuration: configuration)
        self.aiService = aiSvc
        self.chatbotService = ChatbotService(
            aiService: aiSvc,
            documentManager: self.documentManager,
            templateManager: self.templateManager
        )
        self.writingAdvisorService = WritingAdvisorService(aiService: aiSvc)
        self.hermesService = HermesService(
            aiService: aiSvc,
            documentManager: self.documentManager,
            templateManager: self.templateManager
        )
        self.writingAdvisorService = WritingAdvisorService(aiService: aiSvc)
        if let uid = userId {
            self.currentUserId = uid
            try? self.databaseManager.saveAIConfiguration(userId: uid, configuration: configuration)
        }
    }

    /// Disables all AI features for the application.
    ///
    /// Clears the configured AI, chatbot, writing advisor, and Hermes service instances so AI-based functionality becomes unavailable.
    public func disableAI() {
        self.aiService = nil
        self.chatbotService = nil
        self.writingAdvisorService = nil
        self.hermesService = nil
        self.writingAdvisorService = nil
    }

    /// Check if AI is available
    public var isAIEnabled: Bool {
        return aiService != nil
    }

    // MARK: - Spoiler Protection

    /// Tags a range of a document's content as a spoiler.
    /// Returns nil if the range is invalid (startOffset must be >= 0 and < endOffset).
    @discardableResult
    public func tagSpoiler(
        in documentId: UUID,
        startOffset: Int,
        endOffset: Int,
        description: String = "",
        severity: SpoilerSeverity = .moderate
    ) -> SpoilerTag? {
        return spoilerProtection.tagSpoiler(
            in: documentId,
            startOffset: startOffset,
            endOffset: endOffset,
            description: description,
            severity: severity
        )
    }

    /// Removes a spoiler tag from a document
    public func removeSpoilerTag(id: UUID) {
        spoilerProtection.removeSpoilerTag(id: id)
    }

    /// Returns all spoiler tags for a document
    public func getSpoilerTags(forDocument documentId: UUID) -> [SpoilerTag] {
        return spoilerProtection.getSpoilerTags(forDocument: documentId)
    }

    /// Returns whether a document has any spoiler-tagged regions
    public func documentHasSpoilers(_ documentId: UUID) -> Bool {
        return spoilerProtection.hasSpoilers(in: documentId)
    }

    /// Returns the document content with spoiler regions redacted
    public func redactedContent(forDocument documentId: UUID) -> String? {
        guard let document = documentManager.getDocument(id: documentId) else { return nil }
        return spoilerProtection.redactSpoilers(in: document.content, document: documentId)
    }

    /// Exports a document with spoiler regions wrapped in markup
    public func exportDocumentWithSpoilerMarkup(
        id documentId: UUID,
        format: SpoilerMarkupFormat = .markdown
    ) -> String? {
        guard let document = documentManager.getDocument(id: documentId) else { return nil }
        return spoilerProtection.exportWithSpoilerMarkup(
            content: document.content,
            document: documentId,
            format: format
        )
    }

    // MARK: - Ragie Integration

    /// Initializes and enables the Ragie integration using the provided configuration.
    /// - Parameter configuration: Configuration parameters used to create and configure the Ragie service.
    public func enableRagie(configuration: RagieConfiguration) {
        self.ragieService = RagieService(configuration: configuration)
    }

    /// Disables the Ragie integration for the app.
    /// 
    /// Clears the active `RagieService` instance so Ragie-dependent features become unavailable.
    public func disableRagie() {
        self.ragieService = nil
    }

    /// Whether the Ragie service is configured and available.
    public var isRagieEnabled: Bool {
        return ragieService != nil
    }

    /// Ingest a local document into Ragie for semantic retrieval.
    ///
    /// The document's content is sent to Ragie as raw text. The returned
    /// `RagieDocument` includes the Ragie document id and initial processing status.
    /// Poll `getRagieDocumentStatus(ragieId:)` until `isReady` is true before querying.
    ///
    /// - Parameter documentId: The id of the local `Document` to ingest.
    /// Ingests the specified document's text into Ragie and returns the resulting RagieDocument.
    /// - Parameters:
    ///   - documentId: The UUID of the document to ingest.
    /// - Returns: The `RagieDocument` created by Ragie for the ingested document.
    /// - Throws: `RagieError.ragieNotEnabled` if Ragie has not been enabled; `RagieError.documentNotFound` if no document exists with the given `documentId`.
    public func ingestDocumentToRagie(documentId: UUID) async throws -> RagieDocument {
        guard let ragie = ragieService else { throw RagieError.ragieNotEnabled }
        guard let document = documentManager.getDocument(id: documentId) else {
            throw RagieError.documentNotFound
        }
        return try await ragie.ingestRawText(
            document.content,
            name: document.title,
            metadata: ["document_id": documentId.uuidString, "category": document.category.rawValue]
        )
    }

    /// Fetch the processing status of a Ragie document.
    ///
    /// - Parameter ragieId: The Ragie document id (from `ingestDocumentToRagie`).
    /// Retrieves the Ragie document and its current status for the given Ragie document identifier.
    /// - Parameter ragieId: The Ragie-assigned identifier of the document to fetch.
    /// - Returns: The `RagieDocument` matching `ragieId`.
    /// - Throws: `RagieError.ragieNotEnabled` if Ragie integration is not enabled.
    /// - Throws: Any error propagated from `RagieService` if the document cannot be retrieved.
    public func getRagieDocumentStatus(ragieId: String) async throws -> RagieDocument {
        guard let ragie = ragieService else { throw RagieError.ragieNotEnabled }
        return try await ragie.getDocument(id: ragieId)
    }

    /// Retrieve semantically relevant chunks from Ragie for a natural-language query.
    ///
    /// - Parameters:
    ///   - query: The search query.
    ///   - topK: Number of chunks to return (overrides configuration default).
    ///   - rerank: Whether to apply reranking (overrides configuration default).
    /// Retrieve documents from Ragie using a natural-language query.
    /// - Parameters:
    ///   - query: The text query to search the Ragie index.
    ///   - topK: Optional maximum number of results to return; when `nil` the service default is used.
    ///   - rerank: Optional flag to request reranking of initial results by relevance; when `nil` the service default is used.
    /// - Returns: A `RagieRetrievalResult` containing matched documents and associated relevance metadata.
    /// - Throws: `RagieError.ragieNotEnabled` if Ragie has not been enabled. Errors emitted by the underlying Ragie service are propagated.
    public func retrieveFromRagie(
        query: String,
        topK: Int? = nil,
        rerank: Bool? = nil
    ) async throws -> RagieRetrievalResult {
        guard let ragie = ragieService else { throw RagieError.ragieNotEnabled }
        return try await ragie.retrieve(query: query, topK: topK, rerank: rerank)
    }

    /// List all documents currently stored in Ragie.
    ///
    /// Lists documents currently indexed in Ragie.
    /// - Returns: An array of `RagieDocument` objects representing documents stored in Ragie.
    /// - Throws: `RagieError.ragieNotEnabled` if Ragie is not enabled; rethrows any errors produced by the underlying `RagieService`.
    public func listRagieDocuments() async throws -> [RagieDocument] {
        guard let ragie = ragieService else { throw RagieError.ragieNotEnabled }
        return try await ragie.listDocuments()
    }

    /// Enable adult-content mode for the integrated "Jules" chatbot.
    /// 
    /// If the chatbot service is not configured, this call has no effect.
    public func enableJulesAdultMode() {
        chatbotService?.isAdultModeEnabled = true
    }

    /// Disable adult content mode for Jules
    public func disableJulesAdultMode() {
        chatbotService?.isAdultModeEnabled = false
    }

    /// Check if Jules is in adult mode
    public var isJulesAdultModeEnabled: Bool {
        return chatbotService?.isAdultModeEnabled ?? false
    }

    // MARK: - Hermes (Creative Idea Generator)

    /// Start a new Hermes ideation session
    ///
    /// - Parameter context: Optional story context (genre, logline, characters, etc.)
    /// Starts a new Hermes ideation session using the provided context.
    /// - Parameter context: Configuration and seed data used to initialize the Hermes session. Defaults to an empty `HermesContext`.
    /// - Returns: A newly created `HermesSession`.
    /// - Throws: `HermesError.aiNotAvailable` if the Hermes service is not enabled.
    public func startHermesSession(context: HermesContext = HermesContext()) throws -> HermesSession {
        guard let service = hermesService else {
            throw HermesError.aiNotAvailable
        }
        return service.startSession(context: context)
    }

    /// Send a creative prompt to Hermes and receive structured ideas
    ///
    /// - Parameters:
    ///   - prompt: What the writer needs help with
    ///   - session: The active Hermes session (mutated in place)
    /// - Returns: A `HermesResponse` containing the raw message and parsed `[HermesIdea]`
    /// Generates structured ideas from a prompt and updates the provided Hermes session.
    /// - Parameters:
    ///   - prompt: The textual prompt used to seed idea generation.
    ///   - session: An inout `HermesSession` that will be mutated to reflect the generation state and any produced ideas.
    /// - Returns: A `HermesResponse` containing the generated ideas and related metadata.
    /// - Throws: `HermesError.aiNotAvailable` if the Hermes service is not enabled.
    public func generateIdeas(
        prompt: String,
        in session: inout HermesSession
    ) async throws -> HermesResponse {
        guard let service = hermesService else {
            throw HermesError.aiNotAvailable
        }
        return try await service.generateIdeas(prompt, in: &session)
    }

    /// Expand on a specific idea, generating deeper variations
    ///
    /// - Parameters:
    ///   - ideaId: UUID of the idea to expand
    ///   - session: The active Hermes session (mutated in place)
    /// - Returns: A `HermesResponse` with expanded variations
    /// Expands an existing idea into deeper variations within a Hermes session.
    /// - Parameters:
    ///   - ideaId: The identifier of the idea to expand.
    ///   - session: The active `HermesSession` to update; mutated in place with expansion results.
    /// - Returns: A `HermesResponse` containing the expansion output.
    /// - Throws: `HermesError.aiNotAvailable` if the Hermes service is not enabled.
    public func expandIdea(
        ideaId: UUID,
        in session: inout HermesSession
    ) async throws -> HermesResponse {
        guard let service = hermesService else {
            throw HermesError.aiNotAvailable
        }
        return try await service.expandIdea(ideaId, in: &session)
    }

    /// Ends the active Hermes ideation session.
    ///
    /// If Hermes is not enabled or no session is active, this does nothing.
    public func endHermesSession() {
        hermesService?.endSession()
    }

    /// Returns all ideas generated in the session, optionally filtered by type.
    /// - Parameters:
    ///   - session: The session to query.
    ///   - type: When non-nil, only ideas of this type are returned.
    /// - Returns: A flat array of `HermesIdea` in chronological order.
    public func getAllIdeas(from session: HermesSession, filteredBy type: HermesIdeaType? = nil) -> [HermesIdea] {
        return hermesService?.getAllIdeas(from: session, filteredBy: type) ?? []
    }

    /// Computes aggregated statistics for a Hermes session.
    /// - Parameter session: The session to analyse.
    /// - Returns: A `HermesSessionStats` value, or `nil` if Hermes is not enabled.
    public func getHermesSessionStats(from session: HermesSession) -> HermesSessionStats? {
        return hermesService?.getSessionStats(from: session)
    }

    // MARK: - Settings Management

    /// Toggle dark mode on/off
    public func toggleDarkMode() {
        appSettings.isDarkModeEnabled = !appSettings.isDarkModeEnabled
    }

    /// Set dark mode to specific state
    public func setDarkMode(_ enabled: Bool) {
        appSettings.isDarkModeEnabled = enabled
    }

    /// Get current dark mode state
    public var isDarkModeEnabled: Bool {
        return appSettings.isDarkModeEnabled
    }

    /// Set the app theme
    public func setTheme(_ theme: AppTheme) {
        appSettings.theme = theme
    }

    /// Update font size
    public func setFontSize(_ size: Int) {
        appSettings.fontSize = max(8, min(32, size))
    }

    /// Update default word count goal
    public func setDefaultWordCountGoal(_ words: Int?) {
        appSettings.defaultWordCountGoal = words
    }

    /// Enable/disable spell check
    public func setSpellCheckEnabled(_ enabled: Bool) {
        appSettings.spellCheckEnabled = enabled
    }

    /// Enable/disable grammar check
    public func setGrammarCheckEnabled(_ enabled: Bool) {
        appSettings.grammarCheckEnabled = enabled
    }

    /// Get current app settings
    public func getAppSettings() -> AppSettings {
        return appSettings
    }

    // MARK: - Plugin Management

    /// Enable the Claude Memory plugin
    public func enableMemoryPlugin() async throws {
        memoryPlugin = pluginManager.installClaudeMemoryPlugin()
        try await memoryPlugin?.initialize()
    }

    /// Check if memory plugin is enabled
    public var isMemoryPluginEnabled: Bool {
        return memoryPlugin?.isEnabled ?? false
    }

    /// Store a memory
    public func storeMemory(key: String, value: String, category: String = "general", tags: [String] = [], importance: Double = 0.5) async throws {
        guard let plugin = memoryPlugin, plugin.isEnabled else {
            throw PluginError.notInitialized
        }

        let action = PluginAction(type: .storeMemory, parameters: [
            "key": key,
            "value": value,
            "category": category,
            "tags": tags,
            "importance": importance
        ])

        let result = try await plugin.execute(action: action)
        if !result.success, let error = result.error {
            throw error
        }
    }

    /// Retrieve a memory by key
    public func retrieveMemory(key: String) async throws -> String? {
        guard let plugin = memoryPlugin, plugin.isEnabled else {
            throw PluginError.notInitialized
        }

        let action = PluginAction(type: .retrieveMemory, parameters: ["key": key])
        let result = try await plugin.execute(action: action)

        if result.success {
            return result.data as? String
        }

        return nil
    }

    /// Searches stored memories matching `query` and returns matching memory entries.
    /// - Parameters:
    ///   - query: Text to match against stored memories.
    ///   - category: Optional category to restrict the search.
    ///   - limit: Maximum number of results to return.
    /// - Returns: An array of memory records as dictionaries (`[[String: Any]]`); empty if no matches are found.
    /// - Throws: `PluginError.notInitialized` if the memory plugin is not installed or enabled; forwards any errors thrown while executing the plugin action.
    public func searchMemories(query: String, category: String? = nil, limit: Int = 10) async throws -> [[String: Any]] {
        guard let plugin = memoryPlugin, plugin.isEnabled else {
            throw PluginError.notInitialized
        }

        var params: [String: Any] = ["query": query, "limit": limit]
        if let category {
            params["category"] = category
        }

        let action = PluginAction(type: .searchMemory, parameters: params)
        let result = try await plugin.execute(action: action)

        if result.success, let data = result.data as? [[String: Any]] {
            return data
        }

        return []
    }

    /// Lists stored memories, optionally filtered by category, limited, and sorted.
    /// - Parameters:
    ///   - category: Optional category to filter memories.
    ///   - limit: Maximum number of memory entries to return.
    ///   - sortBy: Field name to sort results by (e.g., `"created"`).
    /// - Throws: `PluginError.notInitialized` if the memory plugin is not enabled; propagates errors thrown by the plugin during execution.
    /// - Returns: An array of memory records as dictionaries; returns an empty array if the plugin reports no results.
    public func listMemories(category: String? = nil, limit: Int = 100, sortBy: String = "created") async throws -> [[String: Any]] {
        guard let plugin = memoryPlugin, plugin.isEnabled else {
            throw PluginError.notInitialized
        }

        var params: [String: Any] = ["limit": limit, "sortBy": sortBy]
        if let category {
            params["category"] = category
        }

        let action = PluginAction(type: .listMemories, parameters: params)
        let result = try await plugin.execute(action: action)

        if result.success, let data = result.data as? [[String: Any]] {
            return data
        }

        return []
    }

    /// Clears stored memory entries matching an optional key and/or category.
    /// - Parameters:
    ///   - key: An optional memory key to clear; when omitted, entries are not filtered by key.
    ///   - category: An optional category to restrict which memories are cleared; when omitted, entries are not filtered by category.
    /// - Returns: The number of memory entries that were cleared.
    /// - Throws: `PluginError.notInitialized` if the memory plugin is not available or enabled. Propagates errors thrown by the plugin execution.
    public func clearMemory(key: String? = nil, category: String? = nil) async throws -> Int {
        guard let plugin = memoryPlugin, plugin.isEnabled else {
            throw PluginError.notInitialized
        }

        var params: [String: Any] = [:]
        if let key {
            params["key"] = key
        }
        if let category {
            params["category"] = category
        }

        let action = PluginAction(type: .clearMemory, parameters: params)
        let result = try await plugin.execute(action: action)

        if result.success, let data = result.data as? [String: Any], let cleared = data["cleared"] as? Int {
            return cleared
        }

        return 0
    }

    /// Get memory plugin statistics
    public func getMemoryStats() async throws -> [String: Any] {
        guard let plugin = memoryPlugin, plugin.isEnabled else {
            throw PluginError.notInitialized
        }

        let action = PluginAction(type: .custom, parameters: ["action": "getStats"])
        let result = try await plugin.execute(action: action)

        if result.success, let data = result.data as? [String: Any] {
            return data
        }

        return [:]
    }

    /// Get all registered plugins
    public func getPlugins() -> [Plugin] {
        return pluginManager.getAllPlugins()
    }

    /// Get enabled plugins
    public func getEnabledPlugins() -> [Plugin] {
        return pluginManager.getEnabledPlugins()
    }

    /// Shutdown all plugins
    public func shutdownPlugins() async {
        await pluginManager.shutdownAll()
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
    
    /// Ends the currently active user session and records its completion.
    ///
    /// If a session is active for the current user, sets the session's `endTime` to now,
    /// updates `durationSeconds` to the number of seconds between `startTime` and `endTime`,
    /// and attempts to persist the updated session (errors are suppressed). Clears the in-memory
    /// `currentSessionId` whether or not persistence succeeded.
    public func endSession() {
        guard let sessionId = currentSessionId, let userId = currentUserId else { return }

        if let sessions = try? databaseManager.getUserSessions(userId: userId),
           let index = sessions.firstIndex(where: { $0.id == sessionId }) {
            var session = sessions[index]
            let endTime = Date()
            session.endTime = endTime
            session.durationSeconds = Int(endTime.timeIntervalSince(session.startTime))
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

    // MARK: - Issue Management
    
    /// Creates a new issue for a document
    public func createIssue(
        documentId: UUID,
        title: String,
        description: String = "",
        status: IssueStatus = .open,
        priority: IssuePriority = .medium
    ) -> Issue {
        let issue = Issue(
            documentId: documentId,
            title: title,
            description: description,
            status: status,
            priority: priority
        )
        issueManager.createIssue(issue)
        try? databaseManager.insertIssue(issue)
        return issue
    }
    
    /// Retrieves an issue by ID
    public func getIssue(id: UUID) -> Issue? {
        return issueManager.getIssue(id: id)
    }
    
    /// Retrieves all issues for a document
    public func getIssues(forDocument documentId: UUID) -> [Issue] {
        return issueManager.getIssues(forDocument: documentId)
    }
    
    /// Retrieves issues by status
    public func getIssues(withStatus status: IssueStatus) -> [Issue] {
        return issueManager.getIssues(withStatus: status)
    }
    
    /// Retrieves issues by priority
    public func getIssues(withPriority priority: IssuePriority) -> [Issue] {
        return issueManager.getIssues(withPriority: priority)
    }
    
    /// Searches issues by title or description
    public func searchIssues(query: String) -> [Issue] {
        return issueManager.searchIssues(query: query)
    }
    
    /// Updates an existing issue
    public func updateIssue(_ issue: Issue) {
        issueManager.updateIssue(issue)
        try? databaseManager.updateIssue(issue)
    }
    
    /// Deletes an issue
    public func deleteIssue(id: UUID) {
        issueManager.deleteIssue(id: id)
        try? databaseManager.deleteIssue(id: id)
    }
    
    /// Updates the status of an issue
    public func updateIssueStatus(id: UUID, status: IssueStatus) {
        issueManager.updateIssueStatus(id: id, status: status)
        if let issue = issueManager.getIssue(id: id) {
            try? databaseManager.updateIssue(issue)
        }
    }
    
    /// Reopens a resolved or closed issue, clearing its resolved date
    public func reopenIssue(id: UUID) {
        issueManager.reopenIssue(id: id)
        if let issue = issueManager.getIssue(id: id) {
            try? databaseManager.updateIssue(issue)
        }
    }
    
    /// Updates the priority of an issue
    public func updateIssuePriority(id: UUID, priority: IssuePriority) {
        issueManager.updateIssuePriority(id: id, priority: priority)
        if let issue = issueManager.getIssue(id: id) {
            try? databaseManager.updateIssue(issue)
        }
    }
    
    /// Gets issue statistics
    public func getIssueStatistics() -> (byStatus: [IssueStatus: Int], byPriority: [IssuePriority: Int]) {
        let byStatus = issueManager.getIssueCountByStatus()
        let byPriority = issueManager.getIssueCountByPriority()
        return (byStatus, byPriority)
    }
    
    /// Gets open issues for a document
    public func getOpenIssues(forDocument documentId: UUID) -> [Issue] {
        return issueManager.getOpenIssues(forDocument: documentId)
    }
    
    /// Gets critical issues across all documents
    public func getCriticalIssues() -> [Issue] {
        return issueManager.getCriticalIssues()
    }

    // MARK: - Kanban Board Management

    /// Creates a new Kanban board
    public func createKanbanBoard(name: String, description: String = "") -> KanbanBoard {
        let board = KanbanBoard(name: name, description: description)
        kanbanManager.createBoard(board)
        return board
    }

    /// Retrieves a Kanban board by ID
    public func getKanbanBoard(id: UUID) -> KanbanBoard? {
        return kanbanManager.getBoard(id: id)
    }

    /// Retrieves all Kanban boards
    public func getAllKanbanBoards() -> [KanbanBoard] {
        return kanbanManager.getAllBoards()
    }

    /// Deletes a Kanban board and all its tasks
    public func deleteKanbanBoard(id: UUID) {
        kanbanManager.deleteBoard(id: id)
    }

    // MARK: - Kanban Task Management

    /// Creates a new task on a Kanban board
    public func createKanbanTask(
        boardId: UUID,
        title: String,
        description: String = "",
        column: KanbanColumn = .backlog
    ) -> KanbanTask {
        let task = KanbanTask(
            title: title,
            description: description,
            column: column,
            boardId: boardId
        )
        kanbanManager.createTask(task)
        return task
    }

    /// Retrieves a Kanban task by ID
    public func getKanbanTask(id: UUID) -> KanbanTask? {
        return kanbanManager.getTask(id: id)
    }

    /// Retrieves all tasks for a board
    public func getKanbanTasks(forBoard boardId: UUID) -> [KanbanTask] {
        return kanbanManager.getTasks(forBoard: boardId)
    }

    /// Retrieves tasks in a specific column on a board
    public func getKanbanTasks(forBoard boardId: UUID, inColumn column: KanbanColumn) -> [KanbanTask] {
        return kanbanManager.getTasks(forBoard: boardId, inColumn: column)
    }

    /// Searches Kanban tasks by title or description
    public func searchKanbanTasks(query: String) -> [KanbanTask] {
        return kanbanManager.searchTasks(query: query)
    }

    /// Deletes a Kanban task
    public func deleteKanbanTask(id: UUID) {
        kanbanManager.deleteTask(id: id)
    }

    /// Moves a Kanban task to a specific column
    public func moveKanbanTask(id: UUID, toColumn column: KanbanColumn) {
        kanbanManager.moveTask(id: id, toColumn: column)
    }

    /// Advances a Kanban task to the next column in the workflow
    /// - Returns: The new column, or nil if the task was already in Done
    @discardableResult
    public func advanceKanbanTask(id: UUID) -> KanbanColumn? {
        return kanbanManager.advanceTask(id: id)
    }

    /// Moves a Kanban task back to the previous column in the workflow
    /// - Returns: The new column, or nil if the task was already in Backlog
    @discardableResult
    public func regressKanbanTask(id: UUID) -> KanbanColumn? {
        return kanbanManager.regressTask(id: id)
    }

    /// Gets task counts by column for a board
    public func getKanbanTaskCounts(forBoard boardId: UUID) -> [KanbanColumn: Int] {
        return kanbanManager.getTaskCountByColumn(forBoard: boardId)
    }

    // MARK: - AI-Powered Features

    /// Ensures AI is enabled and retrieves the document with the given identifier.
    /// - Parameter documentId: The UUID of the document to load.
    /// - Returns: The active `AIService` and the corresponding `Document`.
    /// - Throws: `AIError.aiNotEnabled` if AI is not enabled, `AIError.documentNotFound` if no document exists for the given ID.
    private func requireAIAndDocument(documentId: UUID) throws -> (AIService, Document) {
        guard let ai = aiService else {
            throw AIError.aiNotEnabled
        }
        guard let document = documentManager.getDocument(id: documentId) else {
            throw AIError.documentNotFound
        }
        return (ai, document)
    }

    /// Request AI assistance for the specified document.
    /// - Parameters:
    ///   - documentId: The identifier of the document to analyze and assist with.
    ///   - type: The kind of assistance to request.
    ///   - context: Optional additional context to guide the AI's response.
    /// - Returns: An `AIResponse` containing the AI's suggestions or generated content for the document.
    /// - Throws: `AIError.aiNotEnabled` if AI is disabled, `AIError.documentNotFound` if the document does not exist, or other errors propagated from the AI service.
    public func getAIAssistance(
        documentId: UUID,
        type: AIAssistanceType,
        context: AIContext? = nil
    ) async throws -> AIResponse {
        let (ai, document) = try requireAIAndDocument(documentId: documentId)
        return try await ai.getAssistance(text: document.content, type: type, context: context)
    }

    /// Generate a continuation for the specified document using the enabled AI service.
    /// - Parameters:
    ///   - documentId: The identifier of the document to continue.
    ///   - context: Optional AI context to guide the continuation.
    ///   - appendToDocument: If `true`, append the generated continuation to the document's content and persist the update.
    /// - Returns: The generated continuation text.
    /// - Throws: `AIError.aiNotEnabled` if AI is not enabled, `AIError.documentNotFound` if the document cannot be found, or any error produced by the AI service.
    public func continueDocument(
        documentId: UUID,
        context: AIContext? = nil,
        appendToDocument: Bool = false
    ) async throws -> String {
        let (ai, document) = try requireAIAndDocument(documentId: documentId)

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

    /// Produces an improved version of a document's text using the configured AI.
    /// - Parameters:
    ///   - documentId: The identifier of the document to improve.
    ///   - context: Optional AIContext providing additional instructions or guidance for the improvement.
    ///   - replaceContent: If `true`, replaces the stored document content with the improved text; otherwise leaves the document unchanged.
    /// - Returns: The improved document text.
    /// - Throws: `AIError.aiNotEnabled` if AI is not enabled; `AIError.documentNotFound` if the document cannot be found. Propagates errors thrown by the AI service or underlying persistence operations.
    public func improveDocument(
        documentId: UUID,
        context: AIContext? = nil,
        replaceContent: Bool = false
    ) async throws -> String {
        let (ai, document) = try requireAIAndDocument(documentId: documentId)

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

    /// Generate candidate titles for a document using the configured AI service.
    /// - Parameters:
    ///   - documentId: The identifier of the document to analyze.
    ///   - context: Optional contextual hints to guide title generation.
    /// - Returns: Suggested titles for the document.
    /// - Throws: `AIError.aiNotEnabled` if AI is disabled, `AIError.documentNotFound` if the document cannot be found, or other AI-related errors encountered while generating titles.
    public func generateDocumentTitles(
        documentId: UUID,
        context: AIContext? = nil
    ) async throws -> [String] {
        let (ai, document) = try requireAIAndDocument(documentId: documentId)
        return try await ai.generateTitles(content: document.content, context: context)
    }

    /// Performs an AI-powered analysis of the specified document.
    /// - Parameter documentId: The UUID of the document to analyze.
    /// - Returns: A `DocumentAnalysis` containing the analysis results for the document.
    /// - Throws: `AIError.aiNotEnabled` if AI is not enabled.
    /// - Throws: `AIError.documentNotFound` if no document exists with the given `documentId`.
    /// - Throws: Any error produced by the AI service while performing the analysis.
    public func analyzeDocument(documentId: UUID) async throws -> DocumentAnalysis {
        let (ai, document) = try requireAIAndDocument(documentId: documentId)
        return try await ai.analyzeDocument(document: document)
    }

    /// Fetches writing insights for the specified document using the enabled AI service.
    /// - Returns: `WritingInsights` containing analysis and recommendations derived from the document's content.
    /// - Throws: `AIError.aiNotEnabled` if AI is disabled; `AIError.documentNotFound` if no document exists for the given `documentId`.
    public func getDocumentInsights(documentId: UUID) async throws -> WritingInsights {
        let (ai, document) = try requireAIAndDocument(documentId: documentId)
        return try await ai.getWritingInsights(document: document)
    }

    /// Get AI assistance with tool support (implements the tool loop pattern).
    ///
    /// This enables Claude to use built-in writing tools (word count, document search,
    /// template listing, reading time) during its response generation. The tool loop
    /// Request AI assistance for a specific document using tool-enabled multi-step reasoning.
    /// - Parameters:
    ///   - documentId: The UUID of the document to analyze and assist with.
    ///   - type: The kind of assistance to request (e.g., edit, brainstorm, outline).
    ///   - context: Optional additional context to guide the AI.
    ///   - maxIterations: Maximum number of tool-iteration cycles the AI may perform.
    /// - Returns: An `AIResponse` containing the final assistant output and any tool results.
    /// - Throws: `AIError.aiNotEnabled` if AI is not configured; `AIError.documentNotFound` if the document does not exist.
    public func getAIAssistanceWithTools(
        documentId: UUID,
        type: AIAssistanceType,
        context: AIContext? = nil,
        maxIterations: Int = 10
    ) async throws -> AIResponse {
        let (ai, document) = try requireAIAndDocument(documentId: documentId)

        let toolExecutor = WritingToolExecutor(
            documentManager: documentManager,
            templateManager: templateManager
        )

        return try await ai.getAssistanceWithTools(
            text: document.content,
            type: type,
            tools: WritingToolExecutor.tools,
            toolExecutor: toolExecutor,
            context: context,
            maxIterations: maxIterations
        )
    }

    /// Generates brainstorming suggestions for the given subject.
    /// - Parameters:
    ///   - topic: The subject or prompt to generate ideas about.
    ///   - context: Optional contextual hints (tone, constraints, or additional prompts) to guide generation.
    /// - Returns: A string containing AI-generated brainstorming suggestions for the provided topic.
    /// - Throws: `AIError.aiNotEnabled` if the AI service is not configured.
    public func brainstormIdeas(
        topic: String,
        context: AIContext? = nil
    ) async throws -> String {
        guard let ai = aiService else { throw AIError.aiNotEnabled }
        return try await ai.brainstormIdeas(topic: topic, context: context)
    }

    /// Brainstorm ideas organized by category
    public func brainstormIdeasCategorized(
        topic: String,
        context: AIContext? = nil
    ) async throws -> BrainstormResult {
        guard let ai = aiService else { throw AIError.aiNotEnabled }
        return try await ai.brainstormIdeasCategorized(topic: topic, context: context)
    }

    /// Generate an outline for the provided concept using the configured AI service.
    /// - Parameters:
    ///   - concept: The topic or idea to generate an outline for.
    ///   - context: Optional AIContext providing additional guidance or constraints for generation.
    /// - Throws: `AIError.aiNotEnabled` if the AI service is not enabled.
    /// - Returns: The generated outline as a `String`.
    public func generateOutline(
        concept: String,
        context: AIContext? = nil
    ) async throws -> String {
        guard let ai = aiService else { throw AIError.aiNotEnabled }
        return try await ai.generateOutline(concept: concept, context: context)
    }

    /// Develop a character concept
    public func developCharacter(
        characterConcept: String,
        context: AIContext? = nil
    ) async throws -> String {
        guard let ai = aiService else { throw AIError.aiNotEnabled }
        return try await ai.developCharacter(characterConcept: characterConcept, context: context)
    }

    // MARK: - Writing Advisor

    /// Returns personalized writing advice for the current writer.
    ///
    /// - Parameter notes: Optional additional context or focus area for the advice.
    /// - Returns: A `WritingAdvisorReport` with coaching recommendations.
    /// - Throws: `AIError.aiNotEnabled` if AI has not been configured.
    public func getPersonalizedWritingAdvice(notes: String? = nil) async throws -> WritingAdvisorReport {
        guard let advisor = writingAdvisorService else { throw AIError.aiNotEnabled }
        return try await advisor.getPersonalizedAdvice(notes: notes)
    }

    /// Returns writing advice focused on a specific advisor category.
    ///
    /// - Parameter category: The category of advice to generate.
    /// - Returns: A `WritingAdvisorReport` focused on the requested category.
    /// - Throws: `AIError.aiNotEnabled` if AI has not been configured.
    public func getWritingAdvice(for category: AdvisorCategory) async throws -> WritingAdvisorReport {
        guard let advisor = writingAdvisorService else { throw AIError.aiNotEnabled }
        return try await advisor.getAdvice(for: category)
    }

    // MARK: - Hallucination Reduction Methods

    /// Extract relevant quotes from a document for fact-grounding
    ///
    /// Uses the "direct quotes for factual grounding" technique to reduce hallucinations.
    /// Claude extracts word-for-word quotes before performing analysis.
    public func extractQuotesFromDocument(
        documentId: UUID,
        context: AIContext? = nil
    ) async throws -> [QuoteBlock] {
        guard let ai = aiService else { throw AIError.aiNotEnabled }
        guard let document = documentManager.getDocument(id: documentId) else {
            throw AIError.documentNotFound
        }
        return try await ai.extractQuotesFromDocument(text: document.content, context: context)
    }

    /// Verify document claims with citations from source material
    ///
    /// Uses the "verify with citations" technique. Claude must find supporting quotes
    /// for each claim or explicitly acknowledge it cannot be verified.
    public func verifyDocumentWithCitations(
        documentId: UUID,
        context: AIContext? = nil
    ) async throws -> [VerifiedClaim] {
        guard let ai = aiService else { throw AIError.aiNotEnabled }
        guard let document = documentManager.getDocument(id: documentId) else {
            throw AIError.documentNotFound
        }
        return try await ai.verifyWithCitations(text: document.content, context: context)
    }

    /// Analyze document while allowing Claude to admit uncertainty
    ///
    /// Uses the "allow Claude to say 'I don't know'" technique. Explicitly permits
    /// uncertainty acknowledgment and information gap identification.
    public func analyzeDocumentWithUncertainty(
        documentId: UUID,
        context: AIContext? = nil
    ) async throws -> UncertaintyAwareAnalysis {
        guard let ai = aiService else { throw AIError.aiNotEnabled }
        guard let document = documentManager.getDocument(id: documentId) else {
            throw AIError.documentNotFound
        }
        return try await ai.analyzeWithUncertainty(text: document.content, context: context)
    }

    /// Perform chain-of-thought analysis with explicit verification
    ///
    /// Uses the "chain-of-thought verification" technique. Claude explains its
    /// reasoning step-by-step, identifying assumptions and uncertainties.
    public func chainOfThoughtAnalysis(
        documentId: UUID,
        context: AIContext? = nil
    ) async throws -> ChainOfThoughtAnalysis {
        guard let ai = aiService else { throw AIError.aiNotEnabled }
        guard let document = documentManager.getDocument(id: documentId) else {
            throw AIError.documentNotFound
        }
        return try await ai.chainOfThoughtVerification(text: document.content, context: context)
    }

    /// Extract relevant quotes from arbitrary text (non-document)
    public func extractQuotesFromText(
        text: String,
        context: AIContext? = nil
    ) async throws -> [QuoteBlock] {
        guard let ai = aiService else { throw AIError.aiNotEnabled }
        return try await ai.extractQuotesFromDocument(text: text, context: context)
    }

    /// Verify arbitrary text with citations
    public func verifyTextWithCitations(
        text: String,
        context: AIContext? = nil
    ) async throws -> [VerifiedClaim] {
        guard let ai = aiService else { throw AIError.aiNotEnabled }
        return try await ai.verifyWithCitations(text: text, context: context)
    }

    /// Analyze arbitrary text with uncertainty acknowledgment
    public func analyzeTextWithUncertainty(
        text: String,
        context: AIContext? = nil
    ) async throws -> UncertaintyAwareAnalysis {
        guard let ai = aiService else { throw AIError.aiNotEnabled }
        return try await ai.analyzeWithUncertainty(text: text, context: context)
    }

    /// Perform chain-of-thought analysis on arbitrary text
    public func chainOfThoughtAnalysisForText(
        text: String,
        context: AIContext? = nil
    ) async throws -> ChainOfThoughtAnalysis {
        guard let ai = aiService else { throw AIError.aiNotEnabled }
        return try await ai.chainOfThoughtVerification(text: text, context: context)
    }

    // MARK: - Statistics
    
    /// Gets AI tool usage statistics
    public func getAIToolUsageStats(userId: UUID? = nil) throws -> [AIToolUsageStats] {
        let resolvedUserId = userId ?? currentUserId ?? UUID()
        return try databaseManager.getAIToolUsageStats(userId: resolvedUserId)
    }

    /// Gets session statistics
    public func getSessionStats(userId: UUID? = nil) throws -> SessionStats {
        let resolvedUserId = userId ?? currentUserId ?? UUID()
        return try databaseManager.getSessionStats(userId: resolvedUserId)
    }

    /// Gets AI suggestions with pagination
    public func getAISuggestions(userId: UUID? = nil, limit: Int = 50, offset: Int = 0) throws -> [AISuggestion] {
        let resolvedUserId = userId ?? currentUserId ?? UUID()
        return try databaseManager.getAISuggestions(userId: resolvedUserId, limit: limit, offset: offset)
    }

    /// Gets user sessions sorted by duration
    public func getUserSessions(userId: UUID? = nil, sortByDuration: Bool = false) throws -> [UserSession] {
        let resolvedUserId = userId ?? currentUserId ?? UUID()
        return try databaseManager.getUserSessions(userId: resolvedUserId, sortByDuration: sortByDuration)
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
    
    // MARK: - Encouragement Features
    
    /// Get encouragement for a document update
    public func getEncouragementForDocument(_ document: Document, previousWordCount: Int = 0) -> EncouragementMessage? {
        return encouragementService.getWordCountEncouragement(
            wordCount: document.wordCount,
            previousCount: previousWordCount
        )
    }
    
    /// Get encouragement for a writing session
    public func getSessionEncouragement(durationMinutes: Int, wordsWritten: Int) -> EncouragementMessage? {
        return encouragementService.getSessionEncouragement(
            durationMinutes: durationMinutes,
            wordsWritten: wordsWritten
        )
    }
    
    /// Get encouragement for a milestone
    public func getMilestoneEncouragement(milestone: WritingMilestone) -> EncouragementMessage? {
        return encouragementService.getMilestoneEncouragement(milestone: milestone)
    }
    
    /// Get a general encouragement message
    public func getGeneralEncouragement() -> EncouragementMessage {
        return encouragementService.getGeneralEncouragement()
    }
    
    /// Check if encouragement is enabled
    public var isEncouragementEnabled: Bool {
        return encouragementService.configuration.enabled
    }
    
    /// Enable or disable encouragement
    public func setEncouragementEnabled(_ enabled: Bool) {
        encouragementService.configuration.enabled = enabled
    }

    // MARK: - Hardware Board Management

    /// Creates a new hardware board with validation
    public func createHardwareBoard(name: String, type: BoardType,
                                   description: String = "",
                                   serialPort: String? = nil,
                                   baudRate: Int = 9600) throws -> HardwareBoard {
        let board = HardwareBoard(
            name: name,
            boardType: type,
            description: description,
            serialPort: serialPort,
            baudRate: baudRate
        )
        try hardwareManager.createBoard(board)
        return board
    }

    /// Retrieves hardware board statistics
    public func getHardwareStatistics() -> (totalBoards: Int, byType: [String: Int], activeCount: Int) {
        let stats = hardwareManager.getBoardStatistics()
        let byTypeStrings = Dictionary(uniqueKeysWithValues:
            stats.byType.map { ($0.key.rawValue, $0.value) })
        return (stats.totalBoards, byTypeStrings, stats.activeCount)
    }

    // MARK: - gui.new Visual Export

    /// Configure the gui.new client. Omit `apiKey` to use the `GUI_NEW_API_KEY` env variable.
    public func enableGui(apiKey: String? = nil) {
        guiService = GuiNewService(apiKey: apiKey)
    }

    /// Remove the gui.new client.
    public func disableGui() {
        guiService = nil
    }

    /// Whether the gui.new client is configured.
    public var isGuiEnabled: Bool { guiService != nil }

    /// Export a document as a shareable gui.new canvas.
    /// - Returns: A `GuiCanvas` containing the shareable URL.
    public func exportDocumentToGui(id: UUID) async throws -> GuiCanvas {
        guard let svc = guiService else { throw GuiNewError.notConfigured }
        guard let document = documentManager.getDocument(id: id) else { throw AIError.documentNotFound }
        return try await svc.createDocumentCanvas(document: document)
    }

    /// Export the current writing statistics as a shareable gui.new dashboard.
    public func exportStatisticsToGui(title: String = "Writing Statistics") async throws -> GuiCanvas {
        guard let svc = guiService else { throw GuiNewError.notConfigured }
        let stats = getStatistics()
        return try await svc.createStatisticsCanvas(statistics: stats, title: title)
    }

    /// Export a Kanban board as a shareable gui.new canvas.
    public func exportKanbanBoardToGui(boardId: UUID) async throws -> GuiCanvas {
        guard let svc = guiService else { throw GuiNewError.notConfigured }
        guard let board = kanbanManager.getBoard(id: boardId) else {
            throw GuiNewError.notConfigured
        }
        let tasks = kanbanManager.getTasks(forBoard: boardId)
        return try await svc.createKanbanCanvas(board: board, tasks: tasks)
    }

    // MARK: - Multi-Agent Harness

    /// Create a `ComputerUseService` wired to the active AI service.
    ///
    /// - Parameter executor: The executor responsible for taking screenshots and performing actions.
    /// - Returns: A configured `ComputerUseService`, or `nil` if AI has not been enabled.
    public func makeComputerUseService(executor: ComputerUseExecutor) -> ComputerUseService? {
        guard let ai = aiService else { return nil }
        return ComputerUseService(aiService: ai, executor: executor)
    }

    /// Create a `MultiAgentHarness` wired to the active AI service.
    ///
    /// - Parameter configuration: Harness settings (revision budget, quality threshold, model).
    /// - Throws: `AIError.aiNotEnabled` if AI has not been configured via `enableAI()`.
    public func createMultiAgentHarness(
        configuration: HarnessConfiguration = .default
    ) throws -> MultiAgentHarness {
        guard let ai = aiService else { throw AIError.aiNotEnabled }
        return MultiAgentHarness(aiService: ai, configuration: configuration)
    }

    /// Expand a short writing prompt into a structured `WritingPlan` using the planner agent.
    ///
    /// This is a convenience wrapper around `MultiAgentHarness.createPlan(prompt:)`.
    /// Use it when you want only the plan without running the full generator–evaluator loop.
    ///
    /// - Parameter prompt: A 1–4 sentence description of what to write.
    /// - Returns: A `WritingPlan` with sections, characters, themes, and tone.
    /// - Throws: `AIError.aiNotEnabled`, `HarnessError.emptyPrompt`, or `HarnessError.plannerFailed`.
    public func planWriting(prompt: String) async throws -> WritingPlan {
        let harness = try createMultiAgentHarness()
        return try await harness.createPlan(prompt: prompt)
    }

    /// Run the full three-agent harness (planner → generator → evaluator) for a writing prompt.
    ///
    /// The harness:
    /// 1. Expands `prompt` into a `WritingPlan`.
    /// 2. For each section, negotiates a `SectionContract`, generates prose, and evaluates it.
    /// 3. Revises sections that fail the quality threshold (up to `configuration.maxRevisionsPerSection`).
    /// 4. Assembles all sections into a final document.
    ///
    /// - Parameters:
    ///   - prompt: A 1–4 sentence writing task description.
    ///   - configuration: Harness settings controlling revision budget and quality threshold.
    /// - Returns: A `HarnessResult` with assembled prose, quality report, and per-section data.
    public func runMultiAgentHarness(
        prompt: String,
        configuration: HarnessConfiguration = .default
    ) async throws -> HarnessResult {
        let harness = try createMultiAgentHarness(configuration: configuration)
        return try await harness.run(prompt: prompt)
    }

    /// Executes a multi-agent harness using the provided writing plan.
    /// - Parameters:
    ///   - plan: The prepared `WritingPlan` to execute.
    ///   - configuration: `HarnessConfiguration` to apply when creating the harness. Defaults to `.default`.
    /// - Returns: A `HarnessResult` containing the outcome of running the harness.
    /// - Throws: If AI is not enabled or the harness fails during creation or execution.
    public func runMultiAgentHarness(
        plan: WritingPlan,
        configuration: HarnessConfiguration = .default
    ) async throws -> HarnessResult {
        let harness = try createMultiAgentHarness(configuration: configuration)
        return try await harness.run(plan: plan)
    }

    // MARK: - Cowork Mode

    /// Enable Gmail integration using the given OAuth 2.0 bearer token.
    /// Enables Gmail integration for the app using the provided OAuth access token.
    /// - Parameter oauthToken: OAuth access token used to authenticate requests to the Gmail API.
    public func enableGmail(oauthToken: String) {
        self.gmailService = GmailService(oauthToken: oauthToken)
    }

    /// Disables the Gmail integration and clears any existing Gmail service configuration.
    /// After calling this, `isGmailEnabled` will return `false`.
    public func disableGmail() {
        self.gmailService = nil
    }

    /// Whether Gmail is available for this session.
    public var isGmailEnabled: Bool {
        return gmailService != nil
    }

    // MARK: Cowork session lifecycle

    /// Creates and activates a new cowork session.
    /// 
    /// Sets this WritersApp's `activeCoworkSession` to the created session.
    /// - Returns: The newly created `CoworkSession`.
    @discardableResult
    public func startCoworkSession() -> CoworkSession {
        let session = CoworkSession()
        self.activeCoworkSession = session
        return session
    }

    /// Ends the currently active cowork session.
    /// - Returns: The ended `CoworkSession` if a session was active, `nil` otherwise.
    @discardableResult
    public func endCoworkSession() -> CoworkSession? {
        guard var session = activeCoworkSession else { return nil }
        session.endedAt = Date()
        self.activeCoworkSession = nil
        return session
    }

    // MARK: Prospect facade

    /// Creates a new prospect, saves it to the prospect database, and records the addition on the active cowork session if present.
    /// 
    /// The prospect is constructed from the provided fields and added to `prospectDatabase`. If an `activeCoworkSession` exists, its `prospectsAdded` counter is incremented.
    /// - Returns: The created `Prospect`.
    @discardableResult
    public func addProspect(
        name: String,
        email: String,
        company: String? = nil,
        role: String? = nil,
        status: ProspectStatus = .new,
        notes: String = "",
        tags: [String] = []
    ) -> Prospect {
        let prospect = Prospect(
            name: name,
            email: email,
            company: company,
            role: role,
            status: status,
            notes: notes,
            tags: tags
        )
        prospectDatabase.addProspect(prospect)
        activeCoworkSession?.prospectsAdded += 1
        return prospect
    }

    /// Fetches all prospects stored in the prospect database.
    /// - Returns: An array containing every stored `Prospect`.
    public func getAllProspects() -> [Prospect] {
        return prospectDatabase.getAllProspects()
    }

    /// Retrieves all prospects that have the specified status.
    /// - Parameter status: The prospect status to filter by.
    /// - Returns: An array of `Prospect` objects whose status equals the provided `status`.
    public func getProspects(withStatus status: ProspectStatus) -> [Prospect] {
        return prospectDatabase.getProspects(withStatus: status)
    }

    /// Searches prospects using the provided query across common prospect fields (name, email, company, role, and notes).
    /// - Parameter query: The search text to match against prospect fields.
    /// - Returns: An array of `Prospect` objects that match the query.
    public func searchProspects(query: String) -> [Prospect] {
        return prospectDatabase.searchProspects(query: query)
    }

    /// Update the status of a prospect and, when applicable, increment the active cowork session's contacted count.
    /// - Parameters:
    ///   - id: The unique identifier of the prospect to update.
    ///   - status: The new status to assign to the prospect.
    /// - Throws: Any error produced while updating the prospect status in the prospect database.
    /// - Note: If the new status is `.contacted`, `.replied`, or `.meeting`, increments `activeCoworkSession?.prospectsContacted` by 1.
    public func updateProspectStatus(id: UUID, status: ProspectStatus) throws {
        let isContactStatus: (ProspectStatus) -> Bool = {
            $0 == .contacted || $0 == .replied || $0 == .meeting
        }
        let previousStatus = prospectDatabase.getProspect(id: id)?.status
        try prospectDatabase.updateProspectStatus(id: id, status: status)
        if isContactStatus(status) && !(previousStatus.map(isContactStatus) ?? false) {
            activeCoworkSession?.prospectsContacted += 1
        }
    }

    /// Deletes the prospect with the given identifier.
    /// - Parameter id: The UUID of the prospect to remove.
    public func deleteProspect(id: UUID) {
        prospectDatabase.deleteProspect(id: id)
    }

    /// Counts prospects grouped by their status.
    /// - Returns: A dictionary mapping each `ProspectStatus` to the number of prospects with that status.
    public func getProspectStats() -> [ProspectStatus: Int] {
        return prospectDatabase.getStats()
    }

    // MARK: Gmail facade

    /// List Gmail inbox messages.
    /// Retrieve Gmail messages from the configured Gmail service.
    /// - Parameters:
    ///   - maxResults: The maximum number of messages to return.
    ///   - query: An optional Gmail search query to filter results (e.g., "is:unread").
    /// - Returns: An array of `GmailMessage` objects matching the query, limited to `maxResults`.
    /// - Throws: `CoworkError.gmailNotEnabled` if Gmail integration is not enabled.
    public func listGmailMessages(maxResults: Int = 20, query: String? = nil) async throws -> [GmailMessage] {
        guard let gmail = gmailService else { throw CoworkError.gmailNotEnabled }
        return try await gmail.listMessages(maxResults: maxResults, query: query)
    }

    /// Send an email via Gmail and record it in the active cowork session.
    /// Send an email draft using the configured Gmail service and increment the active cowork session's sent counter.
    /// - Parameter draft: The `GmailDraft` to send.
    /// - Returns: The sent message's identifier as a `String`.
    /// - Throws: `CoworkError.gmailNotEnabled` if Gmail is not configured; rethrows errors produced by the underlying `GmailService` when sending fails.
    @discardableResult
    public func sendGmail(draft: GmailDraft) async throws -> String {
        guard let gmail = gmailService else { throw CoworkError.gmailNotEnabled }
        let sentId = try await gmail.sendMessage(draft: draft)
        activeCoworkSession?.emailsSent += 1
        return sentId
    }

    /// Mark a Gmail message as read.
    /// Marks a Gmail message as read.
    /// - Parameters:
    ///   - id: The Gmail message identifier to mark as read.
    /// - Throws: `CoworkError.gmailNotEnabled` if Gmail integration is not configured; rethrows errors from the `GmailService` if the mark-as-read operation fails.
    public func markGmailAsRead(id: String) async throws {
        guard let gmail = gmailService else { throw CoworkError.gmailNotEnabled }
        try await gmail.markAsRead(id: id)
    }

    // MARK: Browser facade

    /// Fetches the page at the given URL and increments the active cowork session's researched-pages counter.
    /// - Parameter urlString: The URL string to fetch.
    /// - Returns: The fetched `BrowsedPage`.
    public func browseURL(_ urlString: String) async throws -> BrowsedPage {
        let page = try await browserService.fetch(urlString: urlString)
        activeCoworkSession?.pagesResearched += 1
        return page
    }

    /// Retrieve the stored browsing history.
    /// - Returns: An array of `BrowsedPage` entries held by the browser service.
    public func getBrowsingHistory() -> [BrowsedPage] {
        return browserService.history
    }

    /// Clears the browsing history maintained by the BrowserService.
    public func clearBrowsingHistory() {
        browserService.clearHistory()
    }

    // MARK: - Gift Card Bundle Management

    @discardableResult
    public func createGiftCardBundle(
        name: String,
        description: String,
        price: Decimal,
        bundleType: BundleType,
        includedTemplateIds: [UUID] = [],
        aiCredits: Int,
        expirationDays: Int
    ) throws -> GiftCardBundle {
        return try giftCardManager.createBundle(
            name: name,
            description: description,
            price: price,
            bundleType: bundleType,
            includedTemplateIds: includedTemplateIds,
            aiCredits: aiCredits,
            expirationDays: expirationDays
        )
    }

    public func getGiftCardBundle(id: UUID) -> GiftCardBundle? {
        return giftCardManager.getBundle(id: id)
    }

    public func getAllGiftCardBundles() -> [GiftCardBundle] {
        return giftCardManager.getAllBundles()
    }

    public func updateGiftCardBundle(_ bundle: GiftCardBundle) throws {
        try giftCardManager.updateBundle(bundle)
    }

    public func deleteGiftCardBundle(id: UUID) throws {
        try giftCardManager.deleteBundle(id: id)
    }

    // MARK: - Gift Card Management

    @discardableResult
    public func generateGiftCard(bundleId: UUID) throws -> GiftCard {
        return try giftCardManager.createGiftCard(bundleId: bundleId)
    }

    public func redeemGiftCard(code: String, userId: UUID) throws -> GiftCardBundle {
        return try giftCardManager.redeemGiftCard(code: code, userId: userId)
    }

    public func getGiftCardByCode(_ code: String) -> GiftCard? {
        return giftCardManager.getGiftCardByCode(code)
    }

    public func getGiftCardStatistics() -> GiftCardStats {
        return giftCardManager.getGiftCardStats()
    }

    public func getGiftCardBundleStatistics() -> BundleStats {
        return giftCardManager.getBundleStats()
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

public enum RagieError: LocalizedError, Equatable {
    case ragieNotEnabled
    case documentNotFound

    public var errorDescription: String? {
        switch self {
        case .ragieNotEnabled:
            return "Ragie is not enabled. Please configure it with enableRagie(configuration:) first."
        case .documentNotFound:
            return "The specified document was not found."
        }
    }
}
// MARK: - Document Safety Guardrails

extension WritersApp {

    @discardableResult
    public func updateDocumentSafely(_ document: Document) throws -> DocumentBackup {
        return try documentManager.updateDocumentSafely(document)
    }

    @discardableResult
    public func deleteDocumentSafely(id: UUID) throws -> DocumentBackup {
        return try documentManager.deleteDocumentSafely(id: id)
    }

    @discardableResult
    public func restoreDocumentFromBackup(backupId: UUID) throws -> Document {
        return try documentManager.restoreFromBackup(backupId: backupId)
    }

    public func getDocumentBackups(documentId: UUID) -> [DocumentBackup] {
        return documentManager.getBackups(forDocument: documentId)
    }

    public func enableDocumentWriteProtection(documentId: UUID) {
        documentManager.enableWriteProtection(for: documentId)
    }

    public func disableDocumentWriteProtection(documentId: UUID) {
        documentManager.disableWriteProtection(for: documentId)
    }

    public func isDocumentWriteProtected(documentId: UUID) -> Bool {
        return documentManager.isWriteProtected(id: documentId)
    }
}
