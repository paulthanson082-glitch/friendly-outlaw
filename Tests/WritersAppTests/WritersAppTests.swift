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
        app.startSession(userId: userId, multitaskingMode: "Split View")

        XCTAssertEqual(app.currentUserId, userId)

        // Verify session was created in database
        let sessions = try? app.databaseManager.getUserSessions(userId: userId)
        XCTAssertEqual(sessions?.count, 1)
        XCTAssertEqual(sessions?.first?.multitaskingMode, "Split View")
        XCTAssertNil(sessions?.first?.endTime)
    }

    func testEndSession() {
        let userId = UUID()
        app.startSession(userId: userId)

        // Small delay to ensure different timestamps
        Thread.sleep(forTimeInterval: 0.1)

        app.endSession()

        // Verify session was ended in database
        let sessions = try? app.databaseManager.getUserSessions(userId: userId)
        XCTAssertEqual(sessions?.count, 1)
        XCTAssertNotNil(sessions?.first?.endTime)
        XCTAssertNotNil(sessions?.first?.durationSeconds)
        XCTAssertGreaterThan(sessions?.first?.durationSeconds ?? 0, 0)
    }

    func testUpdateSessionStats() {
        let userId = UUID()
        app.startSession(userId: userId)

        app.updateSessionStats(wordsWritten: 500, aiInteractions: 3)

        let sessions = try? app.databaseManager.getUserSessions(userId: userId)
        XCTAssertEqual(sessions?.first?.wordsWritten, 500)
        XCTAssertEqual(sessions?.first?.aiInteractions, 3)
    }

    func testMultipleSessionUpdates() {
        let userId = UUID()
        app.startSession(userId: userId)

        app.updateSessionStats(wordsWritten: 100, aiInteractions: 1)
        app.updateSessionStats(wordsWritten: 250, aiInteractions: 2)
        app.updateSessionStats(wordsWritten: 500, aiInteractions: 5)

        let sessions = try? app.databaseManager.getUserSessions(userId: userId)
        XCTAssertEqual(sessions?.first?.wordsWritten, 500)
        XCTAssertEqual(sessions?.first?.aiInteractions, 5)
    }

    func testEndSessionWithoutStart() {
        // Should not crash when ending a non-existent session
        app.endSession()

        // Should have no side effects
        XCTAssertNil(app.currentUserId)
    }

    func testUpdateSessionStatsWithoutStart() {
        // Should not crash when updating a non-existent session
        app.updateSessionStats(wordsWritten: 100, aiInteractions: 1)

        // Should have no side effects
        XCTAssertNil(app.currentUserId)
    }

    func testGetSessionStats() throws {
        let userId = UUID()

        // Create multiple sessions
        for i in 1...3 {
            let session = UserSession(
                userId: userId,
                startTime: Date(timeIntervalSince1970: Double(i * 1000)),
                durationSeconds: i * 600
            )
            try app.databaseManager.insertUserSession(session)
        }

        let stats = try app.getSessionStats(userId: userId)
        XCTAssertEqual(stats.totalSessions, 3)
        XCTAssertEqual(stats.totalDurationSeconds, 3600)
        XCTAssertEqual(stats.averageDurationSeconds, 1200.0)
    }

    func testGetUserSessions() throws {
        let userId = UUID()

        let session1 = UserSession(userId: userId, durationSeconds: 1000)
        let session2 = UserSession(userId: userId, durationSeconds: 3000)
        let session3 = UserSession(userId: userId, durationSeconds: 500)

        try app.databaseManager.insertUserSession(session1)
        try app.databaseManager.insertUserSession(session2)
        try app.databaseManager.insertUserSession(session3)

        let sessions = try app.getUserSessions(userId: userId)
        XCTAssertEqual(sessions.count, 3)

        let sortedSessions = try app.getUserSessions(userId: userId, sortByDuration: true)
        XCTAssertEqual(sortedSessions.count, 3)
        XCTAssertEqual(sortedSessions[0].durationSeconds, 3000)
        XCTAssertEqual(sortedSessions[2].durationSeconds, 500)
    }

    // MARK: - AI Suggestions Integration Tests

    func testGetAISuggestions() throws {
        let userId = UUID()

        for i in 1...10 {
            let suggestion = AISuggestion(
                userId: userId,
                toolUsed: "Tool \(i)",
                prompt: "Prompt \(i)",
                response: "Response \(i)"
            )
            try app.databaseManager.insertAISuggestion(suggestion)
        }

        let suggestions = try app.getAISuggestions(userId: userId, limit: 5)
        XCTAssertEqual(suggestions.count, 5)

        let allSuggestions = try app.getAISuggestions(userId: userId, limit: 100)
        XCTAssertEqual(allSuggestions.count, 10)
    }

    func testGetAIToolUsageStats() throws {
        let userId = UUID()

        let tools = ["Continue Writing", "Grammar Check", "Continue Writing", "Improve Text"]
        for tool in tools {
            let suggestion = AISuggestion(
                userId: userId,
                toolUsed: tool,
                prompt: "Test",
                response: "Test"
            )
            try app.databaseManager.insertAISuggestion(suggestion)
        }

        let stats = try app.getAIToolUsageStats(userId: userId)
        XCTAssertEqual(stats.count, 3)
        XCTAssertEqual(stats.first?.toolName, "Continue Writing")
        XCTAssertEqual(stats.first?.usageCount, 2)
    }

    // MARK: - Database Integration Tests

    func testCreateIssueStoresInDatabase() throws {
        let doc = app.createBlankDocument(title: "Test Doc", category: .novel)
        let issue = app.createIssue(documentId: doc.id, title: "DB Test Issue", priority: .high)

        // Verify issue was stored in database
        let dbIssues = try app.databaseManager.getIssues(forDocument: doc.id)
        XCTAssertEqual(dbIssues.count, 1)
        XCTAssertEqual(dbIssues.first?.id, issue.id)
        XCTAssertEqual(dbIssues.first?.title, "DB Test Issue")
        XCTAssertEqual(dbIssues.first?.priority, .high)
    }

    func testUpdateIssueUpdatesDatabase() throws {
        let doc = app.createBlankDocument(title: "Test Doc", category: .novel)
        var issue = app.createIssue(documentId: doc.id, title: "Original Title")

        issue.title = "Updated Title"
        issue.status = .resolved
        app.updateIssue(issue)

        // Verify database was updated
        let dbIssues = try app.databaseManager.getIssues(forDocument: doc.id)
        XCTAssertEqual(dbIssues.first?.title, "Updated Title")
        XCTAssertEqual(dbIssues.first?.status, .resolved)
    }

    func testDeleteIssueRemovesFromDatabase() throws {
        let doc = app.createBlankDocument(title: "Test Doc", category: .novel)
        let issue = app.createIssue(documentId: doc.id, title: "To Delete")

        app.deleteIssue(id: issue.id)

        // Verify issue was deleted from database
        let dbIssues = try app.databaseManager.getIssues(forDocument: doc.id)
        XCTAssertEqual(dbIssues.count, 0)
    }

    // MARK: - AI Configuration Tests

    func testEnableAI() {
        let config = AIConfiguration(
            apiKey: "test-key",
            model: .claude35Sonnet,
            maxTokens: 4096,
            temperature: 0.7
        )

        let userId = UUID()
        app.enableAI(configuration: config, userId: userId)

        XCTAssertTrue(app.isAIEnabled)
        XCTAssertEqual(app.currentUserId, userId)

        // Verify configuration was saved to database
        let dbConfig = try? app.databaseManager.getAIConfiguration(userId: userId)
        XCTAssertNotNil(dbConfig)
        XCTAssertEqual(dbConfig?.model, .claude35Sonnet)
    }

    func testDisableAI() {
        let config = AIConfiguration(apiKey: "test-key")
        app.enableAI(configuration: config)

        XCTAssertTrue(app.isAIEnabled)

        app.disableAI()

        XCTAssertFalse(app.isAIEnabled)
    }

    // MARK: - Encouragement Service Tests

    func testGetEncouragementForDocument() {
        let doc = app.createBlankDocument(title: "Test", category: .novel)
        var updatedDoc = doc
        updatedDoc.content = String(repeating: "word ", count: 1000)

        let encouragement = app.getEncouragementForDocument(updatedDoc, previousWordCount: 0)

        XCTAssertNotNil(encouragement)
        XCTAssertFalse(encouragement!.message.isEmpty)
    }

    func testGetSessionEncouragement() {
        let encouragement = app.getSessionEncouragement(durationMinutes: 30, wordsWritten: 500)

        XCTAssertNotNil(encouragement)
        XCTAssertFalse(encouragement!.message.isEmpty)
    }

    func testGetMilestoneEncouragement() {
        let encouragement = app.getMilestoneEncouragement(milestone: .dailyGoal)

        XCTAssertNotNil(encouragement)
        XCTAssertFalse(encouragement!.message.isEmpty)
    }

    func testGetGeneralEncouragement() {
        let encouragement = app.getGeneralEncouragement()

        XCTAssertFalse(encouragement.message.isEmpty)
    }

    func testSetEncouragementEnabled() {
        XCTAssertTrue(app.isEncouragementEnabled)

        app.setEncouragementEnabled(false)
        XCTAssertFalse(app.isEncouragementEnabled)

        app.setEncouragementEnabled(true)
        XCTAssertTrue(app.isEncouragementEnabled)
    }

    // MARK: - Custom Database Path Tests

    func testCustomDatabasePath() throws {
        let customPath = "/tmp/custom_writers_test_\(UUID().uuidString).db"
        let customApp = WritersApp(databasePath: customPath)

        let userId = UUID()
        let suggestion = AISuggestion(
            userId: userId,
            toolUsed: "Test",
            prompt: "Test",
            response: "Test"
        )

        try customApp.databaseManager.insertAISuggestion(suggestion)

        let retrieved = try customApp.databaseManager.getAISuggestions(userId: userId)
        XCTAssertEqual(retrieved.count, 1)

        // Cleanup
        customApp.databaseManager.close()
        try? FileManager.default.removeItem(atPath: customPath)
    }

    // MARK: - Error Handling Tests

    func testGetStatisticsWithNoDocuments() {
        let emptyApp = WritersApp()
        let stats = emptyApp.getStatistics()

        XCTAssertEqual(stats.totalDocuments, 0)
        XCTAssertEqual(stats.totalWordCount, 0)
        XCTAssertEqual(stats.averageWordCount, 0)
    }

    func testExportNonexistentDocument() {
        let nonexistentId = UUID()
        let result = app.exportDocument(id: nonexistentId, format: .markdown)

        XCTAssertNil(result)
    }

    func testCreateDocumentFromNonexistentTemplate() {
        let nonexistentTemplateId = UUID()
        let result = app.createDocumentFromTemplate(
            templateId: nonexistentTemplateId,
            values: [:]
        )

        XCTAssertNil(result)
    }

    // MARK: - Additional Database Integration Tests

    func testSessionLifecycleWithDatabasePersistence() throws {
        let customPath = "/tmp/session_lifecycle_\(UUID().uuidString).db"
        let testApp = WritersApp(databasePath: customPath)
        defer {
            testApp.databaseManager.close()
            try? FileManager.default.removeItem(atPath: customPath)
        }

        let userId = UUID()

        // Start session
        testApp.startSession(userId: userId, multitaskingMode: "Test Mode")
        testApp.updateSessionStats(wordsWritten: 100, aiInteractions: 2)

        // Verify session exists in database
        var sessions = try testApp.databaseManager.getUserSessions(userId: userId)
        XCTAssertEqual(sessions.count, 1)
        XCTAssertEqual(sessions.first?.wordsWritten, 100)
        XCTAssertNil(sessions.first?.endTime)

        // End session
        Thread.sleep(forTimeInterval: 0.1)
        testApp.endSession()

        // Verify session was updated in database
        sessions = try testApp.databaseManager.getUserSessions(userId: userId)
        XCTAssertEqual(sessions.count, 1)
        XCTAssertNotNil(sessions.first?.endTime)
        XCTAssertNotNil(sessions.first?.durationSeconds)
    }

    func testIssueManagementDatabaseSync() throws {
        let doc = app.createBlankDocument(title: "Sync Test", category: .novel)
        let issue1 = app.createIssue(documentId: doc.id, title: "Issue 1", priority: .high)
        let issue2 = app.createIssue(documentId: doc.id, title: "Issue 2", priority: .low)

        // Verify both issues exist in manager and database
        let managerIssues = app.getIssues(forDocument: doc.id)
        let dbIssues = try app.databaseManager.getIssues(forDocument: doc.id)

        XCTAssertEqual(managerIssues.count, 2)
        XCTAssertEqual(dbIssues.count, 2)

        // Update an issue
        app.updateIssueStatus(id: issue1.id, status: .resolved)

        // Verify update in both places
        let updatedManagerIssue = app.getIssue(id: issue1.id)
        let updatedDbIssues = try app.databaseManager.getIssues(forDocument: doc.id)
        let updatedDbIssue = updatedDbIssues.first(where: { $0.id == issue1.id })

        XCTAssertEqual(updatedManagerIssue?.status, .resolved)
        XCTAssertEqual(updatedDbIssue?.status, .resolved)

        // Delete an issue
        app.deleteIssue(id: issue2.id)

        // Verify deletion in both places
        XCTAssertNil(app.getIssue(id: issue2.id))
        let remainingDbIssues = try app.databaseManager.getIssues(forDocument: doc.id)
        XCTAssertEqual(remainingDbIssues.count, 1)
        XCTAssertEqual(remainingDbIssues.first?.id, issue1.id)
    }

    func testMultipleSessionsForSameUser() throws {
        let userId = UUID()

        // Create multiple sessions
        for i in 1...3 {
            app.startSession(userId: userId, multitaskingMode: "Mode \(i)")
            app.updateSessionStats(wordsWritten: i * 100, aiInteractions: i)
            Thread.sleep(forTimeInterval: 0.05)
            app.endSession()
        }

        // Verify all sessions were stored
        let sessions = try app.databaseManager.getUserSessions(userId: userId)
        XCTAssertEqual(sessions.count, 3)

        // Verify stats are correct
        let stats = try app.getSessionStats(userId: userId)
        XCTAssertEqual(stats.totalSessions, 3)
    }

    func testGetIssuesByStatusAcrossDocuments() {
        let doc1 = app.createBlankDocument(title: "Doc1", category: .novel)
        let doc2 = app.createBlankDocument(title: "Doc2", category: .article)

        // Create issues with different statuses
        _ = app.createIssue(documentId: doc1.id, title: "Open 1", status: .open)
        _ = app.createIssue(documentId: doc1.id, title: "Open 2", status: .open)
        _ = app.createIssue(documentId: doc2.id, title: "Resolved 1", status: .resolved)
        _ = app.createIssue(documentId: doc2.id, title: "InProgress 1", status: .inProgress)

        let openIssues = app.getIssues(withStatus: .open)
        let resolvedIssues = app.getIssues(withStatus: .resolved)
        let inProgressIssues = app.getIssues(withStatus: .inProgress)

        XCTAssertEqual(openIssues.count, 2)
        XCTAssertEqual(resolvedIssues.count, 1)
        XCTAssertEqual(inProgressIssues.count, 1)
    }

    func testGetIssuesByPriority() {
        let doc = app.createBlankDocument(title: "Priority Test", category: .novel)

        _ = app.createIssue(documentId: doc.id, title: "Critical Issue", priority: .critical)
        _ = app.createIssue(documentId: doc.id, title: "High Issue", priority: .high)
        _ = app.createIssue(documentId: doc.id, title: "Medium Issue", priority: .medium)
        _ = app.createIssue(documentId: doc.id, title: "Low Issue", priority: .low)

        let criticalIssues = app.getIssues(withPriority: .critical)
        let highIssues = app.getIssues(withPriority: .high)
        let mediumIssues = app.getIssues(withPriority: .medium)
        let lowIssues = app.getIssues(withPriority: .low)

        XCTAssertEqual(criticalIssues.count, 1)
        XCTAssertEqual(highIssues.count, 1)
        XCTAssertEqual(mediumIssues.count, 1)
        XCTAssertEqual(lowIssues.count, 1)
    }

    func testSearchIssuesFindsPartialMatches() {
        let doc = app.createBlankDocument(title: "Search Test", category: .novel)

        _ = app.createIssue(documentId: doc.id, title: "Plot inconsistency in chapter 3", description: "Character says something contradictory")
        _ = app.createIssue(documentId: doc.id, title: "Grammar fixes needed", description: "Check chapter 5 for grammar issues")
        _ = app.createIssue(documentId: doc.id, title: "Add more description", description: "Chapter 7 needs more detail")

        let chapterResults = app.searchIssues(query: "chapter")
        let grammarResults = app.searchIssues(query: "grammar")
        let detailResults = app.searchIssues(query: "detail")

        XCTAssertEqual(chapterResults.count, 3)
        XCTAssertEqual(grammarResults.count, 1)
        XCTAssertEqual(detailResults.count, 1)
    }

    func testUpdateIssuePriority() {
        let doc = app.createBlankDocument(title: "Priority Update Test", category: .novel)
        let issue = app.createIssue(documentId: doc.id, title: "Test Issue", priority: .low)

        XCTAssertEqual(issue.priority, .low)

        app.updateIssuePriority(id: issue.id, priority: .critical)
        let updated = app.getIssue(id: issue.id)

        XCTAssertEqual(updated?.priority, .critical)
    }

    func testGetIssueStatistics() {
        let doc = app.createBlankDocument(title: "Stats Test", category: .novel)

        _ = app.createIssue(documentId: doc.id, title: "Issue 1", status: .open, priority: .high)
        _ = app.createIssue(documentId: doc.id, title: "Issue 2", status: .open, priority: .low)
        _ = app.createIssue(documentId: doc.id, title: "Issue 3", status: .resolved, priority: .medium)
        _ = app.createIssue(documentId: doc.id, title: "Issue 4", status: .inProgress, priority: .critical)

        let (byStatus, byPriority) = app.getIssueStatistics()

        XCTAssertEqual(byStatus[.open], 2)
        XCTAssertEqual(byStatus[.resolved], 1)
        XCTAssertEqual(byStatus[.inProgress], 1)

        XCTAssertEqual(byPriority[.critical], 1)
        XCTAssertEqual(byPriority[.high], 1)
        XCTAssertEqual(byPriority[.medium], 1)
        XCTAssertEqual(byPriority[.low], 1)
    }

    func testGetOpenIssuesForDocument() {
        let doc = app.createBlankDocument(title: "Open Issues Test", category: .novel)

        _ = app.createIssue(documentId: doc.id, title: "Open 1", status: .open)
        _ = app.createIssue(documentId: doc.id, title: "Resolved", status: .resolved)
        _ = app.createIssue(documentId: doc.id, title: "Open 2", status: .open)
        _ = app.createIssue(documentId: doc.id, title: "Closed", status: .closed)

        let openIssues = app.getOpenIssues(forDocument: doc.id)

        XCTAssertEqual(openIssues.count, 2)
        XCTAssertTrue(openIssues.allSatisfy { $0.status == .open })
    }

    func testGetCriticalIssues() {
        let doc1 = app.createBlankDocument(title: "Doc1", category: .novel)
        let doc2 = app.createBlankDocument(title: "Doc2", category: .article)

        _ = app.createIssue(documentId: doc1.id, title: "Critical 1", priority: .critical)
        _ = app.createIssue(documentId: doc1.id, title: "High", priority: .high)
        _ = app.createIssue(documentId: doc2.id, title: "Critical 2", priority: .critical)
        _ = app.createIssue(documentId: doc2.id, title: "Low", priority: .low)

        let criticalIssues = app.getCriticalIssues()

        XCTAssertEqual(criticalIssues.count, 2)
        XCTAssertTrue(criticalIssues.allSatisfy { $0.priority == .critical })
    }

    func testExportDocumentFormats() {
        let doc = Document(
            title: "Export Format Test",
            content: "This is test content for export.",
            category: .article
        )
        app.documentManager.createDocument(doc)

        // Test markdown export
        let markdown = app.exportDocument(id: doc.id, format: .markdown)
        XCTAssertNotNil(markdown)
        XCTAssertTrue(markdown!.contains("# Export Format Test"))
        XCTAssertTrue(markdown!.contains("This is test content for export."))

        // Test plain text export
        let plainText = app.exportDocument(id: doc.id, format: .plainText)
        XCTAssertEqual(plainText, "This is test content for export.")

        // Test HTML export
        let html = app.exportDocument(id: doc.id, format: .html)
        XCTAssertNotNil(html)
        XCTAssertTrue(html!.contains("<!DOCTYPE html>"))
        XCTAssertTrue(html!.contains("<title>Export Format Test</title>"))
        XCTAssertTrue(html!.contains("This is test content for export."))
    }

    func testAppStatisticsWithMultipleCategories() {
        _ = app.createBlankDocument(title: "Novel 1", category: .novel)
        _ = app.createBlankDocument(title: "Novel 2", category: .novel)
        _ = app.createBlankDocument(title: "Article 1", category: .article)
        _ = app.createBlankDocument(title: "Blog 1", category: .blogPost)
        _ = app.createBlankDocument(title: "Blog 2", category: .blogPost)
        _ = app.createBlankDocument(title: "Blog 3", category: .blogPost)

        let stats = app.getStatistics()

        XCTAssertEqual(stats.totalDocuments, 6)
        XCTAssertEqual(stats.documentsByCategory[.novel], 2)
        XCTAssertEqual(stats.documentsByCategory[.article], 1)
        XCTAssertEqual(stats.documentsByCategory[.blogPost], 3)
    }

    func testDocumentWordCountTracking() {
        var doc = Document(
            title: "Word Count Test",
            content: "One two three four five.",
            category: .article
        )
        app.documentManager.createDocument(doc)

        XCTAssertEqual(doc.wordCount, 5)

        // Update content
        doc.content = "One two three four five six seven eight nine ten."
        app.documentManager.updateDocument(doc)

        let updated = app.documentManager.getDocument(id: doc.id)
        XCTAssertEqual(updated?.wordCount, 10)
    }

    func testAIEnabledStateTransitions() {
        XCTAssertFalse(app.isAIEnabled)

        let config = AIConfiguration(apiKey: "test-key")
        app.enableAI(configuration: config)

        XCTAssertTrue(app.isAIEnabled)

        app.disableAI()

        XCTAssertFalse(app.isAIEnabled)
    }

    func testEncouragementEnabledToggle() {
        let initialState = app.isEncouragementEnabled

        app.setEncouragementEnabled(!initialState)
        XCTAssertEqual(app.isEncouragementEnabled, !initialState)

        app.setEncouragementEnabled(initialState)
        XCTAssertEqual(app.isEncouragementEnabled, initialState)
    }

    func testCreateDocumentWithAllCategories() {
        let categories: [TemplateCategory] = [
            .novel, .shortStory, .screenplay, .poetry,
            .article, .blogPost, .essay, .research,
            .biography, .memoir, .fantasy, .scienceFiction,
            .mystery, .romance, .horror, .other
        ]

        for category in categories {
            let doc = app.createBlankDocument(title: "Test \(category.rawValue)", category: category)
            XCTAssertEqual(doc.category, category)
            XCTAssertNotNil(app.documentManager.getDocument(id: doc.id))
        }

        XCTAssertEqual(app.documentManager.getAllDocuments().count, categories.count)
    }

    func testDatabaseInitializationFailureHandling() {
        let invalidPath = "/invalid/path/that/does/not/exist/test.db"
        let dbManager = DatabaseManager(databasePath: invalidPath)

        XCTAssertThrowsError(try dbManager.initialize()) { error in
            XCTAssertTrue(error is DatabaseError)
        }
    }

    func testMultipleDatabaseInstancesIndependence() throws {
        let path1 = "/tmp/db1_\(UUID().uuidString).db"
        let path2 = "/tmp/db2_\(UUID().uuidString).db"

        let db1 = DatabaseManager(databasePath: path1)
        let db2 = DatabaseManager(databasePath: path2)

        try db1.initialize()
        try db2.initialize()

        defer {
            db1.close()
            db2.close()
            try? FileManager.default.removeItem(atPath: path1)
            try? FileManager.default.removeItem(atPath: path2)
        }

        let userId = UUID()

        // Insert into db1
        let suggestion1 = AISuggestion(userId: userId, toolUsed: "DB1 Tool", prompt: "Test", response: "Test")
        try db1.insertAISuggestion(suggestion1)

        // Insert into db2
        let suggestion2 = AISuggestion(userId: userId, toolUsed: "DB2 Tool", prompt: "Test", response: "Test")
        try db2.insertAISuggestion(suggestion2)

        // Verify independence
        let db1Suggestions = try db1.getAISuggestions(userId: userId)
        let db2Suggestions = try db2.getAISuggestions(userId: userId)

        XCTAssertEqual(db1Suggestions.count, 1)
        XCTAssertEqual(db2Suggestions.count, 1)
        XCTAssertEqual(db1Suggestions.first?.toolUsed, "DB1 Tool")
        XCTAssertEqual(db2Suggestions.first?.toolUsed, "DB2 Tool")
    }

    func testSessionEndWithoutUpdateStats() throws {
        let userId = UUID()
        app.startSession(userId: userId)

        Thread.sleep(forTimeInterval: 0.1)
        app.endSession()

        let sessions = try app.databaseManager.getUserSessions(userId: userId)
        XCTAssertEqual(sessions.count, 1)
        XCTAssertNotNil(sessions.first?.endTime)
        XCTAssertEqual(sessions.first?.wordsWritten, 0)
        XCTAssertEqual(sessions.first?.aiInteractions, 0)
    }

    func testIssueMetadataPreservation() throws {
        let doc = app.createBlankDocument(title: "Metadata Test", category: .novel)

        var metadata = IssueMetadata()
        metadata.tags = ["bug", "urgent"]
        metadata.notes = "Important notes about this issue"

        var issue = Issue(
            documentId: doc.id,
            title: "Metadata Issue",
            description: "Testing metadata",
            status: .open,
            priority: .high,
            metadata: metadata
        )

        issue = app.createIssue(
            documentId: doc.id,
            title: issue.title,
            description: issue.description,
            status: issue.status,
            priority: issue.priority
        )

        // Update with metadata
        issue.metadata = metadata
        app.updateIssue(issue)

        // Retrieve from database
        let dbIssues = try app.databaseManager.getIssues(forDocument: doc.id)
        let retrieved = dbIssues.first

        XCTAssertEqual(retrieved?.metadata.tags.count, 2)
        XCTAssertTrue(retrieved?.metadata.tags.contains("bug") ?? false)
        XCTAssertTrue(retrieved?.metadata.tags.contains("urgent") ?? false)
    }
}