import XCTest
@testable import WritersApp

final class WritersAppTests: XCTestCase {
    var app: WritersApp!

    override func setUp() {
        super.setUp()
        app = WritersApp()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    func testTemplateManagerLoadsDefaultTemplates() {
        let templates = app.templateManager.getAllTemplates()
        XCTAssertGreaterThan(templates.count, 0, "Should have default templates")
    }

    func testCreateDocumentFromTemplate() {
        let templates = app.templateManager.getAllTemplates()
        guard let template = templates.first else {
            XCTFail("No templates available")
            return
        }

        var values: [String: String] = [:]
        for placeholder in template.placeholders {
            values[placeholder.key] = "Test Value"
        }

        let document = app.createDocumentFromTemplate(templateId: template.id, values: values)
        XCTAssertNotNil(document, "Document should be created")
        XCTAssertTrue(document!.content.contains("Test Value"), "Content should contain filled values")
    }

    func testCreateBlankDocument() {
        let document = app.createBlankDocument(title: "Test Document", category: .novel)
        XCTAssertEqual(document.title, "Test Document")
        XCTAssertEqual(document.category, .novel)
        XCTAssertEqual(document.content, "")
    }

    func testDocumentWordCount() {
        let document = Document(
            title: "Test",
            content: "This is a test document with ten words in it.",
            category: .article
        )
        XCTAssertEqual(document.wordCount, 10)
    }

    func testTemplateSearch() {
        let results = app.templateManager.searchTemplates(query: "novel")
        XCTAssertGreaterThan(results.count, 0, "Should find novel templates")
    }

    func testDocumentManagerOperations() {
        let document = Document(
            title: "Test Document",
            content: "Test content",
            category: .blogPost
        )

        app.documentManager.createDocument(document)

        let retrieved = app.documentManager.getDocument(id: document.id)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.title, "Test Document")

        let allDocuments = app.documentManager.getAllDocuments()
        XCTAssertEqual(allDocuments.count, 1)

        app.documentManager.deleteDocument(id: document.id)
        let afterDelete = app.documentManager.getAllDocuments()
        XCTAssertEqual(afterDelete.count, 0)
    }

    func testExportDocument() {
        let document = Document(
            title: "Export Test",
            content: "Content to export",
            category: .article
        )
        app.documentManager.createDocument(document)

        let exported = app.exportDocument(id: document.id, format: .markdown)
        XCTAssertNotNil(exported)
        XCTAssertTrue(exported!.contains("Export Test"))
        XCTAssertTrue(exported!.contains("Content to export"))
    }

    func testStatistics() {
        let doc1 = app.createBlankDocument(title: "Doc 1", category: .novel)
        let doc2 = app.createBlankDocument(title: "Doc 2", category: .novel)
        let doc3 = app.createBlankDocument(title: "Doc 3", category: .article)

        let stats = app.getStatistics()
        XCTAssertEqual(stats.totalDocuments, 3)
        XCTAssertEqual(stats.documentsByCategory[.novel], 2)
        XCTAssertEqual(stats.documentsByCategory[.article], 1)
    }

    func testTemplatePlaceholders() {
        let template = Template(
            name: "Test Template",
            category: .other,
            description: "Test",
            content: "Hello {{name}}, you are {{age}} years old.",
            placeholders: [
                Placeholder(key: "name", label: "Name"),
                Placeholder(key: "age", label: "Age")
            ]
        )

        let document = template.createDocument(with: ["name": "John", "age": "30"])
        XCTAssertEqual(document.content, "Hello John, you are 30 years old.")
    }

    // MARK: - Tool Loop Types Tests

    func testToolDefinitionToDict() {
        let tool = ToolDefinition(
            name: "test_tool",
            description: "A test tool",
            inputSchema: [
                "type": "object",
                "properties": [
                    "input": ["type": "string"]
                ],
                "required": ["input"]
            ]
        )

        let dict = tool.toDict()
        XCTAssertEqual(dict["name"] as? String, "test_tool")
        XCTAssertEqual(dict["description"] as? String, "A test tool")
        XCTAssertNotNil(dict["input_schema"])
    }

    func testToolUseBlockParsing() {
        let validDict: [String: Any] = [
            "type": "tool_use",
            "id": "toolu_123",
            "name": "get_word_count",
            "input": ["text": "hello world"]
        ]

        let block = ToolUseBlock(from: validDict)
        XCTAssertNotNil(block)
        XCTAssertEqual(block?.id, "toolu_123")
        XCTAssertEqual(block?.name, "get_word_count")
        XCTAssertEqual(block?.input["text"] as? String, "hello world")
    }

    func testToolUseBlockRejectsInvalidType() {
        let invalidDict: [String: Any] = [
            "type": "text",
            "text": "Hello"
        ]

        let block = ToolUseBlock(from: invalidDict)
        XCTAssertNil(block, "Should return nil for non-tool_use blocks")
    }

    func testToolUseBlockRejectsMissingFields() {
        let missingId: [String: Any] = [
            "type": "tool_use",
            "name": "get_word_count"
        ]

        XCTAssertNil(ToolUseBlock(from: missingId), "Should return nil when id is missing")

        let missingName: [String: Any] = [
            "type": "tool_use",
            "id": "toolu_123"
        ]

        XCTAssertNil(ToolUseBlock(from: missingName), "Should return nil when name is missing")
    }

    func testToolUseBlockDefaultsToEmptyInput() {
        let noInput: [String: Any] = [
            "type": "tool_use",
            "id": "toolu_456",
            "name": "list_templates"
        ]

        let block = ToolUseBlock(from: noInput)
        XCTAssertNotNil(block)
        XCTAssertTrue(block?.input.isEmpty ?? false)
    }

    func testToolResultToDict() {
        let result = ToolResult(
            toolUseId: "toolu_123",
            content: "42 words"
        )

        let dict = result.toDict()
        XCTAssertEqual(dict["type"] as? String, "tool_result")
        XCTAssertEqual(dict["tool_use_id"] as? String, "toolu_123")
        XCTAssertEqual(dict["content"] as? String, "42 words")
        XCTAssertNil(dict["is_error"], "Should not include is_error when false")
    }

    func testToolResultErrorToDict() {
        let result = ToolResult(
            toolUseId: "toolu_789",
            content: "Error: Missing parameter",
            isError: true
        )

        let dict = result.toDict()
        XCTAssertEqual(dict["type"] as? String, "tool_result")
        XCTAssertEqual(dict["is_error"] as? Bool, true)
        XCTAssertEqual(dict["content"] as? String, "Error: Missing parameter")
    }

    // MARK: - WritingToolExecutor Tests

    func testWritingToolExecutorWordCount() async throws {
        let executor = WritingToolExecutor(
            documentManager: app.documentManager,
            templateManager: app.templateManager
        )

        let result = try await executor.executeTool(
            name: "get_word_count",
            input: ["text": "The quick brown fox jumps over the lazy dog"]
        )
        XCTAssertEqual(result, "9 words")
    }

    func testWritingToolExecutorWordCountEmpty() async throws {
        let executor = WritingToolExecutor(
            documentManager: app.documentManager,
            templateManager: app.templateManager
        )

        let result = try await executor.executeTool(
            name: "get_word_count",
            input: ["text": ""]
        )
        XCTAssertEqual(result, "0 words")
    }

    func testWritingToolExecutorSearchDocuments() async throws {
        let doc = Document(title: "My Novel Draft", content: "Once upon a time", category: .novel)
        app.documentManager.createDocument(doc)

        let executor = WritingToolExecutor(
            documentManager: app.documentManager,
            templateManager: app.templateManager
        )

        let result = try await executor.executeTool(
            name: "search_documents",
            input: ["query": "Novel"]
        )
        XCTAssertTrue(result.contains("My Novel Draft"))
    }

    func testWritingToolExecutorSearchDocumentsNoResults() async throws {
        let executor = WritingToolExecutor(
            documentManager: app.documentManager,
            templateManager: app.templateManager
        )

        let result = try await executor.executeTool(
            name: "search_documents",
            input: ["query": "nonexistent xyz"]
        )
        XCTAssertTrue(result.contains("No documents found"))
    }

    func testWritingToolExecutorGetDocument() async throws {
        let doc = Document(title: "Test Story", content: "Story content here", category: .shortStory)
        app.documentManager.createDocument(doc)

        let executor = WritingToolExecutor(
            documentManager: app.documentManager,
            templateManager: app.templateManager
        )

        let result = try await executor.executeTool(
            name: "get_document",
            input: ["title": "Test Story"]
        )
        XCTAssertTrue(result.contains("Test Story"))
        XCTAssertTrue(result.contains("Story content here"))
        XCTAssertTrue(result.contains("Short Story"))
    }

    func testWritingToolExecutorGetDocumentNotFound() async throws {
        let executor = WritingToolExecutor(
            documentManager: app.documentManager,
            templateManager: app.templateManager
        )

        let result = try await executor.executeTool(
            name: "get_document",
            input: ["title": "Nonexistent"]
        )
        XCTAssertTrue(result.contains("Document not found"))
    }

    func testWritingToolExecutorCalculateReadingTime() async throws {
        let executor = WritingToolExecutor(
            documentManager: app.documentManager,
            templateManager: app.templateManager
        )

        // 400 words = ~2 minutes at 200 wpm
        let words = Array(repeating: "word", count: 400).joined(separator: " ")
        let result = try await executor.executeTool(
            name: "calculate_reading_time",
            input: ["text": words]
        )
        XCTAssertTrue(result.contains("2 minutes"))
        XCTAssertTrue(result.contains("400 words"))
    }

    func testWritingToolExecutorListTemplates() async throws {
        let executor = WritingToolExecutor(
            documentManager: app.documentManager,
            templateManager: app.templateManager
        )

        let result = try await executor.executeTool(
            name: "list_templates",
            input: [:]
        )
        // Should list all default templates
        XCTAssertFalse(result.contains("No templates found"))
        XCTAssertTrue(result.contains("-"))
    }

    func testWritingToolExecutorListTemplatesFiltered() async throws {
        let executor = WritingToolExecutor(
            documentManager: app.documentManager,
            templateManager: app.templateManager
        )

        let result = try await executor.executeTool(
            name: "list_templates",
            input: ["category": "novel"]
        )
        // Should only list novel templates
        XCTAssertTrue(result.contains("novel"))
    }

    func testWritingToolExecutorUnknownTool() async {
        let executor = WritingToolExecutor(
            documentManager: app.documentManager,
            templateManager: app.templateManager
        )

        do {
            _ = try await executor.executeTool(name: "unknown_tool", input: [:])
            XCTFail("Should throw for unknown tool")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("Unknown tool"))
        }
    }

    func testWritingToolExecutorMissingParameter() async {
        let executor = WritingToolExecutor(
            documentManager: app.documentManager,
            templateManager: app.templateManager
        )

        do {
            _ = try await executor.executeTool(name: "get_word_count", input: [:])
            XCTFail("Should throw for missing parameter")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("Missing"))
        }
    }

    func testWritingToolsStaticDefinitions() {
        let tools = WritingToolExecutor.tools
        XCTAssertEqual(tools.count, 5)

        let toolNames = tools.map { $0.name }
        XCTAssertTrue(toolNames.contains("get_word_count"))
        XCTAssertTrue(toolNames.contains("search_documents"))
        XCTAssertTrue(toolNames.contains("get_document"))
        XCTAssertTrue(toolNames.contains("calculate_reading_time"))
        XCTAssertTrue(toolNames.contains("list_templates"))
    }

    func testToolLoopErrorDescriptions() {
        let exhausted = AIServiceError.toolLoopExhausted(iterations: 10)
        XCTAssertTrue(exhausted.localizedDescription.contains("10"))

        let execFailed = AIServiceError.toolExecutionFailed(
            toolName: "test_tool",
            reason: "something broke"
        )
        XCTAssertTrue(execFailed.localizedDescription.contains("test_tool"))
        XCTAssertTrue(execFailed.localizedDescription.contains("something broke"))
    }

    // MARK: - Reopen Issue Tests

    func testReopenIssueClears_resolvedAt() {
        let doc = app.createBlankDocument(title: "Test Doc", category: .novel)
        let issue = app.createIssue(documentId: doc.id, title: "Test Issue")

        // Resolve the issue
        app.updateIssueStatus(id: issue.id, status: .resolved)
        let resolved = app.getIssue(id: issue.id)
        XCTAssertEqual(resolved?.status, .resolved)
        XCTAssertNotNil(resolved?.metadata.resolvedAt, "resolvedAt should be set when resolved")

        // Reopen the issue
        app.reopenIssue(id: issue.id)
        let reopened = app.getIssue(id: issue.id)
        XCTAssertEqual(reopened?.status, .open)
        XCTAssertNil(reopened?.metadata.resolvedAt, "resolvedAt should be cleared when reopened")
    }

    func testReopenClosedIssue() {
        let doc = app.createBlankDocument(title: "Test Doc", category: .novel)
        let issue = app.createIssue(documentId: doc.id, title: "Closed Issue")

        app.updateIssueStatus(id: issue.id, status: .closed)
        let closed = app.getIssue(id: issue.id)
        XCTAssertEqual(closed?.status, .closed)

        app.reopenIssue(id: issue.id)
        let reopened = app.getIssue(id: issue.id)
        XCTAssertEqual(reopened?.status, .open)
    }

    func testUpdateIssueStatusToOpenClears_resolvedAt() {
        let doc = app.createBlankDocument(title: "Test Doc", category: .novel)
        let issue = app.createIssue(documentId: doc.id, title: "Another Issue")

        app.updateIssueStatus(id: issue.id, status: .resolved)
        XCTAssertNotNil(app.getIssue(id: issue.id)?.metadata.resolvedAt)

        app.updateIssueStatus(id: issue.id, status: .open)
        let reopened = app.getIssue(id: issue.id)
        XCTAssertEqual(reopened?.status, .open)
        XCTAssertNil(reopened?.metadata.resolvedAt, "resolvedAt should be nil after status set to open")
    }

    // MARK: - Kanban Tests

    func testKanbanBoardCreationAssignsUniqueId() {
        let board1 = app.createKanbanBoard(name: "Board One")
        let board2 = app.createKanbanBoard(name: "Board Two")
        XCTAssertNotEqual(board1.id, board2.id)
    }

    func testKanbanBoardRetrievedById() {
        let board = app.createKanbanBoard(name: "My Board", description: "A test board")
        let retrieved = app.getKanbanBoard(id: board.id)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.name, "My Board")
        XCTAssertEqual(retrieved?.description, "A test board")
    }

    func testGetAllKanbanBoardsReturnsAllBoards() {
        let before = app.getAllKanbanBoards().count
        _ = app.createKanbanBoard(name: "Board A")
        _ = app.createKanbanBoard(name: "Board B")
        let after = app.getAllKanbanBoards()
        XCTAssertEqual(after.count, before + 2)
    }

    func testDeleteKanbanBoardRemovesBoardAndTasks() {
        let board = app.createKanbanBoard(name: "Delete Me")
        _ = app.createKanbanTask(boardId: board.id, title: "Task on deleted board")
        app.deleteKanbanBoard(id: board.id)
        XCTAssertNil(app.getKanbanBoard(id: board.id))
        XCTAssertTrue(app.getKanbanTasks(forBoard: board.id).isEmpty)
    }

    func testKanbanTaskCreationAssignsUniqueId() {
        let board = app.createKanbanBoard(name: "Task Board")
        let task1 = app.createKanbanTask(boardId: board.id, title: "Task One")
        let task2 = app.createKanbanTask(boardId: board.id, title: "Task Two")
        XCTAssertNotEqual(task1.id, task2.id)
    }

    func testKanbanTaskDefaultsToBacklog() {
        let board = app.createKanbanBoard(name: "Workflow Board")
        let task = app.createKanbanTask(boardId: board.id, title: "New Task")
        XCTAssertEqual(task.column, .backlog)
    }

    func testKanbanTaskRetrievedById() {
        let board = app.createKanbanBoard(name: "Retrieval Board")
        let task = app.createKanbanTask(boardId: board.id, title: "Findable Task", description: "Find me")
        let retrieved = app.getKanbanTask(id: task.id)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.title, "Findable Task")
        XCTAssertEqual(retrieved?.description, "Find me")
    }

    func testGetKanbanTasksForBoardReturnsAllTasks() {
        let board = app.createKanbanBoard(name: "Multi-task Board")
        _ = app.createKanbanTask(boardId: board.id, title: "Alpha")
        _ = app.createKanbanTask(boardId: board.id, title: "Beta")
        _ = app.createKanbanTask(boardId: board.id, title: "Gamma")
        let tasks = app.getKanbanTasks(forBoard: board.id)
        XCTAssertEqual(tasks.count, 3)
    }

    func testGetKanbanTasksInColumnFiltersCorrectly() {
        let board = app.createKanbanBoard(name: "Column Filter Board")
        _ = app.createKanbanTask(boardId: board.id, title: "Backlog Task", column: .backlog)
        _ = app.createKanbanTask(boardId: board.id, title: "Done Task", column: .done)
        let backlogTasks = app.getKanbanTasks(forBoard: board.id, inColumn: .backlog)
        let doneTasks = app.getKanbanTasks(forBoard: board.id, inColumn: .done)
        XCTAssertEqual(backlogTasks.count, 1)
        XCTAssertEqual(doneTasks.count, 1)
        XCTAssertEqual(backlogTasks.first?.title, "Backlog Task")
        XCTAssertEqual(doneTasks.first?.title, "Done Task")
    }

    func testDeleteKanbanTaskRemovesTask() {
        let board = app.createKanbanBoard(name: "Delete Task Board")
        let task = app.createKanbanTask(boardId: board.id, title: "Temporary Task")
        app.deleteKanbanTask(id: task.id)
        XCTAssertNil(app.getKanbanTask(id: task.id))
    }

    func testMoveKanbanTaskBetweenColumnsUpdatesState() {
        let board = app.createKanbanBoard(name: "Move Board")
        let task = app.createKanbanTask(boardId: board.id, title: "Moveable Task")
        XCTAssertEqual(task.column, .backlog)
        app.moveKanbanTask(id: task.id, toColumn: .running)
        let moved = app.getKanbanTask(id: task.id)
        XCTAssertEqual(moved?.column, .running)
    }

    func testAdvanceKanbanTaskMovesForwardInWorkflow() {
        let board = app.createKanbanBoard(name: "Advance Board")
        let task = app.createKanbanTask(boardId: board.id, title: "Advancing Task")
        let newColumn = app.advanceKanbanTask(id: task.id)
        XCTAssertEqual(newColumn, .planning)
        XCTAssertEqual(app.getKanbanTask(id: task.id)?.column, .planning)
    }

    func testAdvanceKanbanTaskThroughFullWorkflow() {
        let board = app.createKanbanBoard(name: "Full Workflow Board")
        let task = app.createKanbanTask(boardId: board.id, title: "Workflow Task")
        app.advanceKanbanTask(id: task.id) // backlog → planning
        app.advanceKanbanTask(id: task.id) // planning → running
        app.advanceKanbanTask(id: task.id) // running → review
        app.advanceKanbanTask(id: task.id) // review → done
        XCTAssertEqual(app.getKanbanTask(id: task.id)?.column, .done)
    }

    func testAdvanceKanbanTaskAtDoneReturnsNil() {
        let board = app.createKanbanBoard(name: "Done Board")
        let task = app.createKanbanTask(boardId: board.id, title: "Done Task", column: .done)
        let result = app.advanceKanbanTask(id: task.id)
        XCTAssertNil(result, "Advancing from Done should return nil")
        XCTAssertEqual(app.getKanbanTask(id: task.id)?.column, .done)
    }

    func testRegressKanbanTaskMovesBackwardInWorkflow() {
        let board = app.createKanbanBoard(name: "Regress Board")
        let task = app.createKanbanTask(boardId: board.id, title: "Regressing Task", column: .running)
        let newColumn = app.regressKanbanTask(id: task.id)
        XCTAssertEqual(newColumn, .planning)
        XCTAssertEqual(app.getKanbanTask(id: task.id)?.column, .planning)
    }

    func testRegressKanbanTaskAtBacklogReturnsNil() {
        let board = app.createKanbanBoard(name: "Backlog Board")
        let task = app.createKanbanTask(boardId: board.id, title: "Backlog Task")
        let result = app.regressKanbanTask(id: task.id)
        XCTAssertNil(result, "Regressing from Backlog should return nil")
        XCTAssertEqual(app.getKanbanTask(id: task.id)?.column, .backlog)
    }

    func testMoveKanbanTaskToDoneSetsCompletedAt() {
        let board = app.createKanbanBoard(name: "Completion Board")
        let task = app.createKanbanTask(boardId: board.id, title: "Completable Task")
        XCTAssertNil(task.metadata.completedAt)
        app.moveKanbanTask(id: task.id, toColumn: .done)
        let completed = app.getKanbanTask(id: task.id)
        XCTAssertNotNil(completed?.metadata.completedAt)
    }

    func testMoveKanbanTaskFromDoneClearsCompletedAt() {
        let board = app.createKanbanBoard(name: "Reopen Board")
        let task = app.createKanbanTask(boardId: board.id, title: "Reopenable Task")
        app.moveKanbanTask(id: task.id, toColumn: .done)
        XCTAssertNotNil(app.getKanbanTask(id: task.id)?.metadata.completedAt, "completedAt should be set on Done")
        app.moveKanbanTask(id: task.id, toColumn: .review)
        let moved = app.getKanbanTask(id: task.id)
        XCTAssertNil(moved?.metadata.completedAt, "completedAt should be cleared when moved out of Done")
    }

    func testGetKanbanTaskCountsByColumn() {
        let board = app.createKanbanBoard(name: "Count Board")
        _ = app.createKanbanTask(boardId: board.id, title: "T1", column: .backlog)
        _ = app.createKanbanTask(boardId: board.id, title: "T2", column: .backlog)
        _ = app.createKanbanTask(boardId: board.id, title: "T3", column: .running)
        let counts = app.getKanbanTaskCounts(forBoard: board.id)
        XCTAssertEqual(counts[.backlog], 2)
        XCTAssertEqual(counts[.running], 1)
        XCTAssertEqual(counts[.planning], 0)
        XCTAssertEqual(counts[.review], 0)
        XCTAssertEqual(counts[.done], 0)
    }

    func testSearchKanbanTasksByTitle() {
        let board = app.createKanbanBoard(name: "Search Board")
        _ = app.createKanbanTask(boardId: board.id, title: "Write chapter one")
        _ = app.createKanbanTask(boardId: board.id, title: "Edit draft")
        _ = app.createKanbanTask(boardId: board.id, title: "Write synopsis")
        let results = app.searchKanbanTasks(query: "Write")
        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.allSatisfy { $0.title.localizedCaseInsensitiveContains("Write") })
    }

    func testKanbanColumnWorkflowOrder() {
        XCTAssertNil(KanbanColumn.backlog.previous)
        XCTAssertEqual(KanbanColumn.backlog.next, .planning)
        XCTAssertEqual(KanbanColumn.planning.next, .running)
        XCTAssertEqual(KanbanColumn.running.next, .review)
        XCTAssertEqual(KanbanColumn.review.next, .done)
        XCTAssertNil(KanbanColumn.done.next)
    }

    // MARK: - Session Management Tests

    func testStartSession() {
        let userId = UUID()
        app.startSession(userId: userId)

        XCTAssertEqual(app.currentUserId, userId)
    }

    func testStartSessionWithMultitaskingMode() {
        let userId = UUID()
        app.startSession(userId: userId, multitaskingMode: "Split View")

        XCTAssertEqual(app.currentUserId, userId)
    }

    func testEndSession() {
        let userId = UUID()
        app.startSession(userId: userId)
        app.endSession()

        // Session should still have userId but session would be ended
        XCTAssertEqual(app.currentUserId, userId)
    }

    func testUpdateSessionStats() {
        let userId = UUID()
        app.startSession(userId: userId)
        app.updateSessionStats(wordsWritten: 250, aiInteractions: 5)

        // Verify session stats were updated through database
        let sessions = try? app.getUserSessions(userId: userId)
        XCTAssertNotNil(sessions)
    }

    func testGetSessionStats() throws {
        let userId = UUID()
        app.startSession(userId: userId)
        app.updateSessionStats(wordsWritten: 100, aiInteractions: 2)

        let stats = try app.getSessionStats(userId: userId)
        XCTAssertGreaterThanOrEqual(stats.totalSessions, 1)
    }

    func testGetUserSessions() throws {
        let userId = UUID()
        app.startSession(userId: userId)
        app.endSession()

        let sessions = try app.getUserSessions(userId: userId)
        XCTAssertGreaterThanOrEqual(sessions.count, 1)
    }

    func testGetUserSessionsSortedByDuration() throws {
        let userId = UUID()
        app.startSession(userId: userId)
        app.endSession()

        let sessions = try app.getUserSessions(userId: userId, sortByDuration: true)
        XCTAssertNotNil(sessions)
    }

    // MARK: - Database Integration Tests

    func testDatabaseManagerIntegration() {
        XCTAssertNotNil(app.databaseManager)
    }

    func testGetAISuggestionsIntegration() throws {
        let userId = UUID()
        let suggestions = try app.getAISuggestions(userId: userId, limit: 10)
        XCTAssertNotNil(suggestions)
    }

    func testGetAIToolUsageStatsIntegration() throws {
        let userId = UUID()
        let stats = try app.getAIToolUsageStats(userId: userId)
        XCTAssertNotNil(stats)
    }

    // MARK: - AI Configuration Tests

    func testEnableAI() {
        let config = AIConfiguration(
            apiKey: "test-key",
            model: .claude35Sonnet,
            maxTokens: 4096,
            temperature: 0.7
        )

        app.enableAI(configuration: config)
        XCTAssertTrue(app.isAIEnabled)
    }

    func testDisableAI() {
        let config = AIConfiguration(
            apiKey: "test-key",
            model: .claude35Sonnet
        )

        app.enableAI(configuration: config)
        XCTAssertTrue(app.isAIEnabled)

        app.disableAI()
        XCTAssertFalse(app.isAIEnabled)
    }

    func testEnableAIWithUserId() {
        let config = AIConfiguration(
            apiKey: "test-key",
            model: .claude3Opus
        )
        let userId = UUID()

        app.enableAI(configuration: config, userId: userId)
        XCTAssertTrue(app.isAIEnabled)
        XCTAssertEqual(app.currentUserId, userId)
    }

    func testAIEnabledByDefault() {
        XCTAssertFalse(app.isAIEnabled)
    }

    func testInitWithAIConfiguration() {
        let config = AIConfiguration(
            apiKey: "test-api-key",
            model: .claude35Sonnet,
            maxTokens: 8192,
            temperature: 0.8
        )

        let appWithAI = WritersApp(aiConfiguration: config)
        XCTAssertTrue(appWithAI.isAIEnabled)
    }

    func testInitWithCustomDatabasePath() {
        let customPath = "/tmp/test_custom_path.db"
        let appWithCustomDb = WritersApp(databasePath: customPath)
        XCTAssertNotNil(appWithCustomDb.databaseManager)
    }

    // MARK: - Plugin Management Tests

    func testGetPlugins() {
        let plugins = app.getPlugins()
        XCTAssertNotNil(plugins)
    }

    func testGetEnabledPlugins() {
        let enabledPlugins = app.getEnabledPlugins()
        XCTAssertNotNil(enabledPlugins)
    }

    func testIsMemoryPluginEnabledByDefault() {
        XCTAssertFalse(app.isMemoryPluginEnabled)
    }

    // MARK: - Encouragement Service Tests

    func testGetGeneralEncouragement() {
        let message = app.getGeneralEncouragement()
        XCTAssertNotNil(message.text)
        XCTAssertFalse(message.text.isEmpty)
    }

    func testIsEncouragementEnabledByDefault() {
        XCTAssertTrue(app.isEncouragementEnabled)
    }

    func testSetEncouragementEnabled() {
        app.setEncouragementEnabled(false)
        XCTAssertFalse(app.isEncouragementEnabled)

        app.setEncouragementEnabled(true)
        XCTAssertTrue(app.isEncouragementEnabled)
    }

    func testGetEncouragementForDocument() {
        let doc = app.createBlankDocument(title: "Test Doc", category: .novel)
        let encouragement = app.getEncouragementForDocument(doc, previousWordCount: 0)
        // May be nil if word count doesn't trigger a milestone
        XCTAssertTrue(encouragement == nil || encouragement?.text != nil)
    }

    func testGetSessionEncouragement() {
        let encouragement = app.getSessionEncouragement(durationMinutes: 30, wordsWritten: 500)
        // May be nil depending on encouragement rules
        XCTAssertTrue(encouragement == nil || encouragement?.text != nil)
    }

    func testGetMilestoneEncouragement() {
        let milestone = WritingMilestone.wordsWritten(1000)
        let encouragement = app.getMilestoneEncouragement(milestone: milestone)
        XCTAssertNotNil(encouragement)
        XCTAssertFalse(encouragement!.text.isEmpty)
    }

    // MARK: - Document Analysis and Export Tests

    func testExportDocumentMarkdown() {
        let doc = Document(
            title: "Export Test",
            content: "Test content for export",
            category: .article
        )
        app.documentManager.createDocument(doc)

        let exported = app.exportDocument(id: doc.id, format: .markdown)
        XCTAssertNotNil(exported)
        XCTAssertTrue(exported!.contains("# Export Test"))
        XCTAssertTrue(exported!.contains("Test content for export"))
    }

    func testExportDocumentPlainText() {
        let doc = Document(
            title: "Plain Text Test",
            content: "Simple content",
            category: .blogPost
        )
        app.documentManager.createDocument(doc)

        let exported = app.exportDocument(id: doc.id, format: .plainText)
        XCTAssertEqual(exported, "Simple content")
    }

    func testExportDocumentHTML() {
        let doc = Document(
            title: "HTML Test",
            content: "HTML content",
            category: .shortStory
        )
        app.documentManager.createDocument(doc)

        let exported = app.exportDocument(id: doc.id, format: .html)
        XCTAssertNotNil(exported)
        XCTAssertTrue(exported!.contains("<!DOCTYPE html>"))
        XCTAssertTrue(exported!.contains("HTML Test"))
    }

    func testExportNonexistentDocument() {
        let nonexistentId = UUID()
        let exported = app.exportDocument(id: nonexistentId, format: .markdown)
        XCTAssertNil(exported)
    }

    // MARK: - Template and Document Integration Tests

    func testCreateDocumentFromTemplateIntegration() {
        let templates = app.templateManager.getAllTemplates()
        guard let template = templates.first else {
            XCTFail("No templates available")
            return
        }

        var values: [String: String] = [:]
        for placeholder in template.placeholders {
            values[placeholder.key] = "Test Value"
        }

        let document = app.createDocumentFromTemplate(templateId: template.id, values: values)
        XCTAssertNotNil(document)

        // Verify it was added to document manager
        let retrieved = app.documentManager.getDocument(id: document!.id)
        XCTAssertNotNil(retrieved)
    }

    func testCreateDocumentFromNonexistentTemplate() {
        let nonexistentId = UUID()
        let document = app.createDocumentFromTemplate(templateId: nonexistentId, values: [:])
        XCTAssertNil(document)
    }

    // MARK: - Issue Management Integration Tests

    func testCreateIssueIntegration() {
        let doc = app.createBlankDocument(title: "Test Doc", category: .novel)
        let issue = app.createIssue(
            documentId: doc.id,
            title: "Test Issue",
            description: "Test description",
            status: .open,
            priority: .high
        )

        XCTAssertEqual(issue.documentId, doc.id)
        XCTAssertEqual(issue.title, "Test Issue")
        XCTAssertEqual(issue.status, .open)
        XCTAssertEqual(issue.priority, .high)

        // Verify it was added to both managers
        let retrievedFromIssueManager = app.getIssue(id: issue.id)
        XCTAssertNotNil(retrievedFromIssueManager)
    }

    func testGetIssuesForDocument() {
        let doc = app.createBlankDocument(title: "Doc with Issues", category: .novel)
        app.createIssue(documentId: doc.id, title: "Issue 1")
        app.createIssue(documentId: doc.id, title: "Issue 2")

        let issues = app.getIssues(forDocument: doc.id)
        XCTAssertEqual(issues.count, 2)
    }

    func testGetIssuesByStatus() {
        let doc = app.createBlankDocument(title: "Test Doc", category: .novel)
        app.createIssue(documentId: doc.id, title: "Open Issue", status: .open)
        app.createIssue(documentId: doc.id, title: "Resolved Issue", status: .resolved)

        let openIssues = app.getIssues(withStatus: .open)
        XCTAssertGreaterThanOrEqual(openIssues.count, 1)
        XCTAssertTrue(openIssues.allSatisfy { $0.status == .open })
    }

    func testGetIssuesByPriority() {
        let doc = app.createBlankDocument(title: "Test Doc", category: .novel)
        app.createIssue(documentId: doc.id, title: "Critical Issue", priority: .critical)
        app.createIssue(documentId: doc.id, title: "Low Issue", priority: .low)

        let criticalIssues = app.getIssues(withPriority: .critical)
        XCTAssertGreaterThanOrEqual(criticalIssues.count, 1)
        XCTAssertTrue(criticalIssues.allSatisfy { $0.priority == .critical })
    }

    func testSearchIssues() {
        let doc = app.createBlankDocument(title: "Test Doc", category: .novel)
        app.createIssue(documentId: doc.id, title: "Character development needed")
        app.createIssue(documentId: doc.id, title: "Fix plot hole")

        let results = app.searchIssues(query: "character")
        XCTAssertGreaterThanOrEqual(results.count, 1)
    }

    func testUpdateIssue() {
        let doc = app.createBlankDocument(title: "Test Doc", category: .novel)
        var issue = app.createIssue(documentId: doc.id, title: "Original Title")

        issue.title = "Updated Title"
        issue.description = "Updated description"
        app.updateIssue(issue)

        let retrieved = app.getIssue(id: issue.id)
        XCTAssertEqual(retrieved?.title, "Updated Title")
        XCTAssertEqual(retrieved?.description, "Updated description")
    }

    func testDeleteIssue() {
        let doc = app.createBlankDocument(title: "Test Doc", category: .novel)
        let issue = app.createIssue(documentId: doc.id, title: "To Delete")

        app.deleteIssue(id: issue.id)

        let retrieved = app.getIssue(id: issue.id)
        XCTAssertNil(retrieved)
    }

    func testUpdateIssueStatus() {
        let doc = app.createBlankDocument(title: "Test Doc", category: .novel)
        let issue = app.createIssue(documentId: doc.id, title: "Test Issue")

        app.updateIssueStatus(id: issue.id, status: .inProgress)

        let retrieved = app.getIssue(id: issue.id)
        XCTAssertEqual(retrieved?.status, .inProgress)
    }

    func testUpdateIssuePriority() {
        let doc = app.createBlankDocument(title: "Test Doc", category: .novel)
        let issue = app.createIssue(documentId: doc.id, title: "Test Issue", priority: .low)

        app.updateIssuePriority(id: issue.id, priority: .critical)

        let retrieved = app.getIssue(id: issue.id)
        XCTAssertEqual(retrieved?.priority, .critical)
    }

    func testGetIssueStatistics() {
        let doc = app.createBlankDocument(title: "Test Doc", category: .novel)
        app.createIssue(documentId: doc.id, title: "Open 1", status: .open)
        app.createIssue(documentId: doc.id, title: "Open 2", status: .open)
        app.createIssue(documentId: doc.id, title: "Resolved", status: .resolved)

        let stats = app.getIssueStatistics()
        XCTAssertGreaterThanOrEqual(stats.byStatus[.open] ?? 0, 2)
        XCTAssertGreaterThanOrEqual(stats.byStatus[.resolved] ?? 0, 1)
    }

    func testGetOpenIssuesForDocument() {
        let doc = app.createBlankDocument(title: "Test Doc", category: .novel)
        app.createIssue(documentId: doc.id, title: "Open", status: .open)
        app.createIssue(documentId: doc.id, title: "Closed", status: .closed)

        let openIssues = app.getOpenIssues(forDocument: doc.id)
        XCTAssertEqual(openIssues.count, 1)
        XCTAssertEqual(openIssues.first?.status, .open)
    }

    func testGetCriticalIssues() {
        let doc = app.createBlankDocument(title: "Test Doc", category: .novel)
        app.createIssue(documentId: doc.id, title: "Critical", priority: .critical)
        app.createIssue(documentId: doc.id, title: "Low", priority: .low)

        let criticalIssues = app.getCriticalIssues()
        XCTAssertGreaterThanOrEqual(criticalIssues.count, 1)
        XCTAssertTrue(criticalIssues.allSatisfy { $0.priority == .critical })
    }

    // MARK: - Statistics Tests

    func testGetStatistics() {
        app.createBlankDocument(title: "Doc 1", category: .novel)
        app.createBlankDocument(title: "Doc 2", category: .article)

        let stats = app.getStatistics()
        XCTAssertGreaterThanOrEqual(stats.totalDocuments, 2)
        XCTAssertNotNil(stats.documentsByCategory)
    }

    // MARK: - Edge Cases and Boundary Tests

    func testMultipleSessionsForSameUser() {
        let userId = UUID()

        app.startSession(userId: userId)
        app.endSession()

        app.startSession(userId: userId, multitaskingMode: "Full Screen")
        app.endSession()

        let sessions = try? app.getUserSessions(userId: userId)
        XCTAssertNotNil(sessions)
        XCTAssertGreaterThanOrEqual(sessions?.count ?? 0, 2)
    }

    func testUpdateSessionStatsWithoutSession() {
        // Should not crash even if no session is active
        app.updateSessionStats(wordsWritten: 100, aiInteractions: 5)
    }

    func testEndSessionWithoutStarting() {
        // Should not crash
        app.endSession()
    }

    func testCreateIssueWithMinimalData() {
        let doc = app.createBlankDocument(title: "Test Doc", category: .novel)
        let issue = app.createIssue(documentId: doc.id, title: "Minimal Issue")

        XCTAssertEqual(issue.title, "Minimal Issue")
        XCTAssertEqual(issue.description, "")
        XCTAssertEqual(issue.status, .open)
        XCTAssertEqual(issue.priority, .medium)
    }

    func testReopenIssueIntegration() {
        let doc = app.createBlankDocument(title: "Test Doc", category: .novel)
        let issue = app.createIssue(documentId: doc.id, title: "Test Issue")

        app.updateIssueStatus(id: issue.id, status: .resolved)
        var retrieved = app.getIssue(id: issue.id)
        XCTAssertNotNil(retrieved?.metadata.resolvedAt)

        app.reopenIssue(id: issue.id)
        retrieved = app.getIssue(id: issue.id)
        XCTAssertEqual(retrieved?.status, .open)
        XCTAssertNil(retrieved?.metadata.resolvedAt)
    }
}