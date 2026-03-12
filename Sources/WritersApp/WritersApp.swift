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
    public private(set) var guiService: GuiNewService?
    public private(set) var aiService: AIService?
    public private(set) var chatbotService: ChatbotService?
    public private(set) var currentUserId: UUID?
    private var currentSessionId: UUID?
    private var memoryPlugin: ClaudeMemoryPlugin?

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
        self.guiService = nil
        let aiSvc = aiConfiguration.map { AIService(configuration: $0) }
        self.aiService = aiSvc
        if let svc = aiSvc {
            self.chatbotService = ChatbotService(
                aiService: svc,
                documentManager: self.documentManager,
                templateManager: self.templateManager
            )
        } else {
            self.chatbotService = nil
        }
        try? databaseManager.initialize()
    }

    /// Enable AI features by providing configuration
    public func enableAI(configuration: AIConfiguration, userId: UUID? = nil) {
        let aiSvc = AIService(configuration: configuration)
        self.aiService = aiSvc
        self.chatbotService = ChatbotService(
            aiService: aiSvc,
            documentManager: self.documentManager,
            templateManager: self.templateManager
        )
        if let uid = userId {
            self.currentUserId = uid
            try? self.databaseManager.saveAIConfiguration(userId: uid, configuration: configuration)
        }
    }

    /// Disable AI features
    public func disableAI() {
        self.aiService = nil
        self.chatbotService = nil
    }

    /// Check if AI is available
    public var isAIEnabled: Bool {
        return aiService != nil
    }

    /// Enable adult content mode for Jules (no content restrictions, curse words allowed)
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

    /// Search memories
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

    /// List all memories
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

    /// Clear a specific memory or all memories
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
    
    /// Ends the current session
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

    /// Returns the active AI service and the document for `documentId`, throwing if either is unavailable.
    private func requireAIAndDocument(documentId: UUID) throws -> (AIService, Document) {
        guard let ai = aiService else {
            throw AIError.aiNotEnabled
        }
        guard let document = documentManager.getDocument(id: documentId) else {
            throw AIError.documentNotFound
        }
        return (ai, document)
    }

    /// Get AI assistance for a document
    public func getAIAssistance(
        documentId: UUID,
        type: AIAssistanceType,
        context: AIContext? = nil
    ) async throws -> AIResponse {
        let (ai, document) = try requireAIAndDocument(documentId: documentId)
        return try await ai.getAssistance(text: document.content, type: type, context: context)
    }

    /// Continue writing a document with AI
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

    /// Improve document content with AI
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

    /// Generate title suggestions for a document
    public func generateDocumentTitles(
        documentId: UUID,
        context: AIContext? = nil
    ) async throws -> [String] {
        let (ai, document) = try requireAIAndDocument(documentId: documentId)
        return try await ai.generateTitles(content: document.content, context: context)
    }

    /// Analyze a document comprehensively
    public func analyzeDocument(documentId: UUID) async throws -> DocumentAnalysis {
        let (ai, document) = try requireAIAndDocument(documentId: documentId)
        return try await ai.analyzeDocument(document: document)
    }

    /// Get writing insights for a document
    public func getDocumentInsights(documentId: UUID) async throws -> WritingInsights {
        let (ai, document) = try requireAIAndDocument(documentId: documentId)
        return try await ai.getWritingInsights(document: document)
    }

    /// Get AI assistance with tool support (implements the tool loop pattern).
    ///
    /// This enables Claude to use built-in writing tools (word count, document search,
    /// template listing, reading time) during its response generation. The tool loop
    /// continues until Claude produces a final text response.
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

    /// Brainstorm ideas for a topic
    public func brainstormIdeas(
        topic: String,
        context: AIContext? = nil
    ) async throws -> String {
        guard let ai = aiService else { throw AIError.aiNotEnabled }
        return try await ai.brainstormIdeas(topic: topic, context: context)
    }

    /// Generate outline from concept
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
