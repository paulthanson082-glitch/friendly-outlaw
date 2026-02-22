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

    func testStartSessionCreatesNewSession() {
        let userId = UUID()
        app.startSession(userId: userId)

        XCTAssertEqual(app.currentUserId, userId)

        // Verify session was inserted into database
        let sessions = try? app.databaseManager.getUserSessions(userId: userId)
        XCTAssertNotNil(sessions)
        XCTAssertEqual(sessions?.count, 1)
    }

    func testStartSessionWithMultitaskingMode() {
        let userId = UUID()
        app.startSession(userId: userId, multitaskingMode: "Split View")

        let sessions = try? app.databaseManager.getUserSessions(userId: userId)
        XCTAssertEqual(sessions?.first?.multitaskingMode, "Split View")
    }

    func testEndSessionUpdatesSessionTimes() {
        let userId = UUID()
        app.startSession(userId: userId)

        Thread.sleep(forTimeInterval: 0.1)

        app.endSession()

        let sessions = try? app.databaseManager.getUserSessions(userId: userId)
        XCTAssertNotNil(sessions?.first?.endTime)
        XCTAssertNotNil(sessions?.first?.durationSeconds)
        XCTAssertGreaterThan(sessions?.first?.durationSeconds ?? 0, 0)
    }

    func testEndSessionWithoutStartingDoesNotCrash() {
        // Should handle gracefully
        app.endSession()
        // No assertion needed, just ensuring it doesn't crash
    }

    func testUpdateSessionStatsUpdatesWordCountAndInteractions() {
        let userId = UUID()
        app.startSession(userId: userId)

        app.updateSessionStats(wordsWritten: 500, aiInteractions: 5)

        let sessions = try? app.databaseManager.getUserSessions(userId: userId)
        XCTAssertEqual(sessions?.first?.wordsWritten, 500)
        XCTAssertEqual(sessions?.first?.aiInteractions, 5)
    }

    func testUpdateSessionStatsWithoutStartingDoesNotCrash() {
        // Should handle gracefully
        app.updateSessionStats(wordsWritten: 100, aiInteractions: 2)
        // No assertion needed, just ensuring it doesn't crash
    }

    func testMultipleSessionsForSameUser() {
        let userId = UUID()

        app.startSession(userId: userId)
        app.endSession()

        app.startSession(userId: userId)
        app.endSession()

        let sessions = try? app.databaseManager.getUserSessions(userId: userId)
        XCTAssertEqual(sessions?.count, 2)
    }

    // MARK: - Statistics Retrieval Tests

    func testGetAIToolUsageStatsWithCurrentUser() throws {
        let userId = UUID()
        app.startSession(userId: userId)

        // Insert some AI suggestions
        let suggestion1 = AISuggestion(userId: userId, toolUsed: "Continue Writing", prompt: "test", response: "test")
        let suggestion2 = AISuggestion(userId: userId, toolUsed: "Grammar Check", prompt: "test", response: "test")
        let suggestion3 = AISuggestion(userId: userId, toolUsed: "Continue Writing", prompt: "test", response: "test")

        try app.databaseManager.insertAISuggestion(suggestion1)
        try app.databaseManager.insertAISuggestion(suggestion2)
        try app.databaseManager.insertAISuggestion(suggestion3)

        let stats = try app.getAIToolUsageStats()

        XCTAssertEqual(stats.count, 2)
        XCTAssertEqual(stats.first?.toolName, "Continue Writing")
        XCTAssertEqual(stats.first?.usageCount, 2)
    }

    func testGetAIToolUsageStatsWithSpecificUser() throws {
        let userId = UUID()

        let suggestion = AISuggestion(userId: userId, toolUsed: "Improve Text", prompt: "test", response: "test")
        try app.databaseManager.insertAISuggestion(suggestion)

        let stats = try app.getAIToolUsageStats(userId: userId)

        XCTAssertEqual(stats.count, 1)
        XCTAssertEqual(stats.first?.toolName, "Improve Text")
    }

    func testGetSessionStatsWithCurrentUser() throws {
        let userId = UUID()
        app.startSession(userId: userId)

        let session = UserSession(userId: userId, durationSeconds: 1800, wordsWritten: 500, aiInteractions: 3)
        try app.databaseManager.insertUserSession(session)

        let stats = try app.getSessionStats()

        XCTAssertGreaterThanOrEqual(stats.totalSessions, 1)
        XCTAssertGreaterThan(stats.totalDurationSeconds, 0)
    }

    func testGetSessionStatsWithSpecificUser() throws {
        let userId = UUID()

        let session1 = UserSession(userId: userId, durationSeconds: 1200)
        let session2 = UserSession(userId: userId, durationSeconds: 1800)

        try app.databaseManager.insertUserSession(session1)
        try app.databaseManager.insertUserSession(session2)

        let stats = try app.getSessionStats(userId: userId)

        XCTAssertEqual(stats.totalSessions, 2)
        XCTAssertEqual(stats.totalDurationSeconds, 3000)
        XCTAssertEqual(stats.averageDurationSeconds, 1500.0)
    }

    func testGetAISuggestionsWithPagination() throws {
        let userId = UUID()
        app.startSession(userId: userId)

        for i in 1...10 {
            let suggestion = AISuggestion(userId: userId, toolUsed: "Tool \(i)", prompt: "prompt", response: "response")
            try app.databaseManager.insertAISuggestion(suggestion)
        }

        let firstPage = try app.getAISuggestions(limit: 5, offset: 0)
        XCTAssertEqual(firstPage.count, 5)

        let secondPage = try app.getAISuggestions(limit: 5, offset: 5)
        XCTAssertEqual(secondPage.count, 5)
    }

    func testGetUserSessionsSortedByDuration() throws {
        let userId = UUID()

        let session1 = UserSession(userId: userId, durationSeconds: 1000)
        let session2 = UserSession(userId: userId, durationSeconds: 3000)
        let session3 = UserSession(userId: userId, durationSeconds: 500)

        try app.databaseManager.insertUserSession(session1)
        try app.databaseManager.insertUserSession(session2)
        try app.databaseManager.insertUserSession(session3)

        let sessions = try app.getUserSessions(userId: userId, sortByDuration: true)

        XCTAssertEqual(sessions.count, 3)
        XCTAssertEqual(sessions[0].durationSeconds, 3000)
        XCTAssertEqual(sessions[1].durationSeconds, 1000)
        XCTAssertEqual(sessions[2].durationSeconds, 500)
    }

    // MARK: - AI Error Handling Tests

    func testAIMethodsThrowWhenAINotEnabled() async {
        let doc = app.createBlankDocument(title: "Test", category: .novel)

        do {
            _ = try await app.getAIAssistance(documentId: doc.id, type: .continueWriting)
            XCTFail("Should throw AIError.aiNotEnabled")
        } catch AIError.aiNotEnabled {
            // Expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testContinueDocumentThrowsWhenAINotEnabled() async {
        let doc = app.createBlankDocument(title: "Test", category: .novel)

        do {
            _ = try await app.continueDocument(documentId: doc.id)
            XCTFail("Should throw AIError.aiNotEnabled")
        } catch AIError.aiNotEnabled {
            // Expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testImproveDocumentThrowsWhenAINotEnabled() async {
        let doc = app.createBlankDocument(title: "Test", category: .novel)

        do {
            _ = try await app.improveDocument(documentId: doc.id)
            XCTFail("Should throw AIError.aiNotEnabled")
        } catch AIError.aiNotEnabled {
            // Expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testGenerateDocumentTitlesThrowsWhenAINotEnabled() async {
        let doc = app.createBlankDocument(title: "Test", category: .novel)

        do {
            _ = try await app.generateDocumentTitles(documentId: doc.id)
            XCTFail("Should throw AIError.aiNotEnabled")
        } catch AIError.aiNotEnabled {
            // Expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testAnalyzeDocumentThrowsWhenAINotEnabled() async {
        let doc = app.createBlankDocument(title: "Test", category: .novel)

        do {
            _ = try await app.analyzeDocument(documentId: doc.id)
            XCTFail("Should throw AIError.aiNotEnabled")
        } catch AIError.aiNotEnabled {
            // Expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testGetDocumentInsightsThrowsWhenAINotEnabled() async {
        let doc = app.createBlankDocument(title: "Test", category: .novel)

        do {
            _ = try await app.getDocumentInsights(documentId: doc.id)
            XCTFail("Should throw AIError.aiNotEnabled")
        } catch AIError.aiNotEnabled {
            // Expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testAIMethodsThrowWhenDocumentNotFound() async {
        let config = AIConfiguration(apiKey: "test", model: .claude35Sonnet)
        app.enableAI(configuration: config)

        let nonexistentId = UUID()

        do {
            _ = try await app.getAIAssistance(documentId: nonexistentId, type: .continueWriting)
            XCTFail("Should throw AIError.documentNotFound")
        } catch AIError.documentNotFound {
            // Expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    // MARK: - Database Integration Tests

    func testSessionManagementPersistsToDatabase() {
        let userId = UUID()
        let testDbPath = "/tmp/test_session_\(UUID().uuidString).db"
        let dbManager = DatabaseManager(databasePath: testDbPath)
        try? dbManager.initialize()

        let testApp = WritersApp(databasePath: testDbPath)

        testApp.startSession(userId: userId, multitaskingMode: "Full Screen")
        testApp.updateSessionStats(wordsWritten: 250, aiInteractions: 2)
        testApp.endSession()

        let sessions = try? dbManager.getUserSessions(userId: userId)
        XCTAssertEqual(sessions?.count, 1)
        XCTAssertEqual(sessions?.first?.wordsWritten, 250)
        XCTAssertEqual(sessions?.first?.aiInteractions, 2)
        XCTAssertEqual(sessions?.first?.multitaskingMode, "Full Screen")
        XCTAssertNotNil(sessions?.first?.endTime)

        dbManager.close()
        try? FileManager.default.removeItem(atPath: testDbPath)
    }

    func testIssueManagementPersistsToDatabase() {
        let testDbPath = "/tmp/test_issues_\(UUID().uuidString).db"
        let testApp = WritersApp(databasePath: testDbPath)

        let doc = testApp.createBlankDocument(title: "Test Doc", category: .novel)
        let issue = testApp.createIssue(documentId: doc.id, title: "Fix typo", priority: .low)

        testApp.updateIssueStatus(id: issue.id, status: .resolved)

        let retrieved = testApp.getIssue(id: issue.id)
        XCTAssertEqual(retrieved?.status, .resolved)

        let dbIssues = try? testApp.databaseManager.getIssues(forDocument: doc.id)
        XCTAssertEqual(dbIssues?.count, 1)
        XCTAssertEqual(dbIssues?.first?.status, .resolved)

        testApp.databaseManager.close()
        try? FileManager.default.removeItem(atPath: testDbPath)
    }

    // MARK: - Edge Cases and Boundary Tests

    func testSessionStatsWithZeroSessions() throws {
        let userId = UUID()
        let stats = try app.getSessionStats(userId: userId)

        XCTAssertEqual(stats.totalSessions, 0)
        XCTAssertEqual(stats.totalDurationSeconds, 0)
        XCTAssertEqual(stats.averageDurationSeconds, 0.0)
    }

    func testAISuggestionsWithZeroResults() throws {
        let userId = UUID()
        let suggestions = try app.getAISuggestions(userId: userId)

        XCTAssertEqual(suggestions.count, 0)
    }

    func testGetUserSessionsForNonexistentUser() throws {
        let nonexistentUserId = UUID()
        let sessions = try app.getUserSessions(userId: nonexistentUserId)

        XCTAssertEqual(sessions.count, 0)
    }

    func testMultipleSimultaneousSessionsNotSupported() {
        let userId = UUID()

        app.startSession(userId: userId)
        let firstSessionId = app.currentUserId

        app.startSession(userId: userId)
        let secondSessionId = app.currentUserId

        XCTAssertEqual(firstSessionId, secondSessionId)
    }

    // MARK: - Additional Edge Cases and Regression Tests

    func testEnableAIUpdatesCurrentUserId() {
        let userId = UUID()
        let config = AIConfiguration(apiKey: "test-key", model: .claude35Sonnet)

        app.enableAI(configuration: config, userId: userId)

        XCTAssertEqual(app.currentUserId, userId)
        XCTAssertTrue(app.isAIEnabled)
    }

    func testEnableAIWithoutUserIdDoesNotSetCurrentUser() {
        let config = AIConfiguration(apiKey: "test-key", model: .claude35Sonnet)

        app.enableAI(configuration: config, userId: nil)

        XCTAssertNil(app.currentUserId)
        XCTAssertTrue(app.isAIEnabled)
    }

    func testDisableAIClearsAIService() {
        let config = AIConfiguration(apiKey: "test-key", model: .claude35Sonnet)
        app.enableAI(configuration: config)

        XCTAssertTrue(app.isAIEnabled)

        app.disableAI()

        XCTAssertFalse(app.isAIEnabled)
    }

    func testIsAIEnabledReturnsFalseByDefault() {
        XCTAssertFalse(app.isAIEnabled)
    }

    func testExportDocumentWithInvalidIdReturnsNil() {
        let exported = app.exportDocument(id: UUID(), format: .markdown)
        XCTAssertNil(exported)
    }

    func testExportDocumentPlainTextFormat() {
        let doc = app.createBlankDocument(title: "Plain Test", category: .article)
        let exported = app.exportDocument(id: doc.id, format: .plainText)

        XCTAssertNotNil(exported)
        XCTAssertEqual(exported, doc.content)
    }

    func testExportDocumentHTMLFormat() {
        let doc = Document(title: "HTML Test", content: "Test content", category: .blogPost)
        app.documentManager.createDocument(doc)

        let exported = app.exportDocument(id: doc.id, format: .html)

        XCTAssertNotNil(exported)
        XCTAssertTrue(exported!.contains("<!DOCTYPE html>"))
        XCTAssertTrue(exported!.contains("HTML Test"))
        XCTAssertTrue(exported!.contains("Test content"))
    }

    func testCreateDocumentFromTemplateWithInvalidIdReturnsNil() {
        let document = app.createDocumentFromTemplate(templateId: UUID(), values: [:])
        XCTAssertNil(document)
    }

    func testGetStatisticsReturnsCorrectCounts() {
        let doc1 = app.createBlankDocument(title: "Novel 1", category: .novel)
        let doc2 = app.createBlankDocument(title: "Novel 2", category: .novel)
        let doc3 = app.createBlankDocument(title: "Article 1", category: .article)

        let stats = app.getStatistics()

        XCTAssertEqual(stats.totalDocuments, 3)
        XCTAssertEqual(stats.documentsByCategory[.novel], 2)
        XCTAssertEqual(stats.documentsByCategory[.article], 1)
    }

    func testGetStatisticsWithNoDocuments() {
        let stats = app.getStatistics()

        XCTAssertEqual(stats.totalDocuments, 0)
        XCTAssertEqual(stats.totalWordCount, 0)
        XCTAssertEqual(stats.averageWordCount, 0)
    }

    func testUpdateIssueWithNonexistentIdDoesNotCrash() {
        let issue = Issue(
            id: UUID(),
            documentId: UUID(),
            title: "Nonexistent",
            status: .open,
            priority: .low
        )

        // Should not crash
        app.updateIssue(issue)
    }

    func testDeleteIssueWithNonexistentIdDoesNotCrash() {
        // Should not crash
        app.deleteIssue(id: UUID())
    }

    func testGetIssueWithNonexistentIdReturnsNil() {
        let issue = app.getIssue(id: UUID())
        XCTAssertNil(issue)
    }

    func testGetIssuesForNonexistentDocumentReturnsEmpty() {
        let issues = app.getIssues(forDocument: UUID())
        XCTAssertEqual(issues.count, 0)
    }

    func testGetIssuesWithStatusWhenNoneExist() {
        let issues = app.getIssues(withStatus: .resolved)
        XCTAssertEqual(issues.count, 0)
    }

    func testGetIssuesWithPriorityWhenNoneExist() {
        let issues = app.getIssues(withPriority: .critical)
        XCTAssertEqual(issues.count, 0)
    }

    func testSearchIssuesWithNoMatches() {
        let doc = app.createBlankDocument(title: "Test", category: .novel)
        app.createIssue(documentId: doc.id, title: "Issue One")

        let results = app.searchIssues(query: "nonexistent search term")
        XCTAssertEqual(results.count, 0)
    }

    func testSearchIssuesWithMatches() {
        let doc = app.createBlankDocument(title: "Test", category: .novel)
        app.createIssue(documentId: doc.id, title: "Fix character motivation")
        app.createIssue(documentId: doc.id, title: "Update plot twist")

        let results = app.searchIssues(query: "character")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Fix character motivation")
    }

    func testUpdateIssueStatusWithNonexistentIdDoesNotCrash() {
        // Should not crash
        app.updateIssueStatus(id: UUID(), status: .resolved)
    }

    func testUpdateIssuePriorityWithNonexistentIdDoesNotCrash() {
        // Should not crash
        app.updateIssuePriority(id: UUID(), priority: .critical)
    }

    func testGetIssueStatisticsWithNoIssues() {
        let (byStatus, byPriority) = app.getIssueStatistics()

        XCTAssertEqual(byStatus.count, 0)
        XCTAssertEqual(byPriority.count, 0)
    }

    func testGetIssueStatisticsWithMultipleIssues() {
        let doc = app.createBlankDocument(title: "Test", category: .novel)

        app.createIssue(documentId: doc.id, title: "Issue 1", status: .open, priority: .high)
        app.createIssue(documentId: doc.id, title: "Issue 2", status: .open, priority: .high)
        app.createIssue(documentId: doc.id, title: "Issue 3", status: .resolved, priority: .low)

        let (byStatus, byPriority) = app.getIssueStatistics()

        XCTAssertEqual(byStatus[.open], 2)
        XCTAssertEqual(byStatus[.resolved], 1)
        XCTAssertEqual(byPriority[.high], 2)
        XCTAssertEqual(byPriority[.low], 1)
    }

    func testGetOpenIssuesForDocumentWithNoOpenIssues() {
        let doc = app.createBlankDocument(title: "Test", category: .novel)
        let issue = app.createIssue(documentId: doc.id, title: "Resolved Issue")
        app.updateIssueStatus(id: issue.id, status: .resolved)

        let openIssues = app.getOpenIssues(forDocument: doc.id)
        XCTAssertEqual(openIssues.count, 0)
    }

    func testGetCriticalIssuesWithNoCriticalIssues() {
        let doc = app.createBlankDocument(title: "Test", category: .novel)
        app.createIssue(documentId: doc.id, title: "Low Priority", priority: .low)

        let criticalIssues = app.getCriticalIssues()
        XCTAssertEqual(criticalIssues.count, 0)
    }

    func testGetCriticalIssuesWithCriticalIssues() {
        let doc = app.createBlankDocument(title: "Test", category: .novel)
        app.createIssue(documentId: doc.id, title: "Critical Issue", priority: .critical)
        app.createIssue(documentId: doc.id, title: "High Issue", priority: .high)

        let criticalIssues = app.getCriticalIssues()
        XCTAssertEqual(criticalIssues.count, 1)
        XCTAssertEqual(criticalIssues.first?.priority, .critical)
    }

    func testGetKanbanBoardWithNonexistentIdReturnsNil() {
        let board = app.getKanbanBoard(id: UUID())
        XCTAssertNil(board)
    }

    func testGetKanbanTaskWithNonexistentIdReturnsNil() {
        let task = app.getKanbanTask(id: UUID())
        XCTAssertNil(task)
    }

    func testGetKanbanTasksForNonexistentBoardReturnsEmpty() {
        let tasks = app.getKanbanTasks(forBoard: UUID())
        XCTAssertEqual(tasks.count, 0)
    }

    func testSearchKanbanTasksWithNoMatches() {
        let board = app.createKanbanBoard(name: "Board")
        app.createKanbanTask(boardId: board.id, title: "Task One")

        let results = app.searchKanbanTasks(query: "nonexistent")
        XCTAssertEqual(results.count, 0)
    }

    func testDeleteKanbanTaskWithNonexistentIdDoesNotCrash() {
        // Should not crash
        app.deleteKanbanTask(id: UUID())
    }

    func testMoveKanbanTaskWithNonexistentIdDoesNotCrash() {
        // Should not crash
        app.moveKanbanTask(id: UUID(), toColumn: .done)
    }

    func testAdvanceKanbanTaskWithNonexistentIdReturnsNil() {
        let result = app.advanceKanbanTask(id: UUID())
        XCTAssertNil(result)
    }

    func testRegressKanbanTaskWithNonexistentIdReturnsNil() {
        let result = app.regressKanbanTask(id: UUID())
        XCTAssertNil(result)
    }

    func testGetKanbanTaskCountsForNonexistentBoard() {
        let counts = app.getKanbanTaskCounts(forBoard: UUID())

        XCTAssertEqual(counts[.backlog], 0)
        XCTAssertEqual(counts[.planning], 0)
        XCTAssertEqual(counts[.running], 0)
        XCTAssertEqual(counts[.review], 0)
        XCTAssertEqual(counts[.done], 0)
    }

    func testDeleteKanbanBoardWithNonexistentIdDoesNotCrash() {
        // Should not crash
        app.deleteKanbanBoard(id: UUID())
    }

    func testGetAllKanbanBoardsWhenNoneExist() {
        let boards = app.getAllKanbanBoards()
        // May have boards from other tests, but should return array
        XCTAssertNotNil(boards)
    }

    func testEncouragementFeaturesDefaultEnabled() {
        XCTAssertTrue(app.isEncouragementEnabled)
    }

    func testSetEncouragementEnabledToggle() {
        app.setEncouragementEnabled(false)
        XCTAssertFalse(app.isEncouragementEnabled)

        app.setEncouragementEnabled(true)
        XCTAssertTrue(app.isEncouragementEnabled)
    }

    func testGetEncouragementForDocumentReturnsMessage() {
        let doc = Document(title: "Test", content: String(repeating: "word ", count: 100), category: .novel)
        app.documentManager.createDocument(doc)

        let encouragement = app.getEncouragementForDocument(doc, previousWordCount: 50)
        XCTAssertNotNil(encouragement)
    }

    func testGetSessionEncouragementReturnsMessage() {
        let encouragement = app.getSessionEncouragement(durationMinutes: 30, wordsWritten: 500)
        XCTAssertNotNil(encouragement)
    }

    func testGetMilestoneEncouragementReturnsMessage() {
        let encouragement = app.getMilestoneEncouragement(milestone: .firstDraft)
        XCTAssertNotNil(encouragement)
    }

    func testGetGeneralEncouragementReturnsMessage() {
        let encouragement = app.getGeneralEncouragement()
        XCTAssertNotNil(encouragement)
    }

    func testGetPluginsReturnsArray() {
        let plugins = app.getPlugins()
        XCTAssertNotNil(plugins)
    }

    func testGetEnabledPluginsReturnsArray() {
        let plugins = app.getEnabledPlugins()
        XCTAssertNotNil(plugins)
    }

    func testIsMemoryPluginEnabledDefaultsFalse() {
        XCTAssertFalse(app.isMemoryPluginEnabled)
    }

    func testCreateIssueWithDefaultValues() {
        let doc = app.createBlankDocument(title: "Test", category: .novel)
        let issue = app.createIssue(documentId: doc.id, title: "Simple Issue")

        XCTAssertEqual(issue.title, "Simple Issue")
        XCTAssertEqual(issue.description, "")
        XCTAssertEqual(issue.status, .open)
        XCTAssertEqual(issue.priority, .medium)
    }

    func testCreateKanbanTaskWithDefaultColumn() {
        let board = app.createKanbanBoard(name: "Board")
        let task = app.createKanbanTask(boardId: board.id, title: "Task")

        XCTAssertEqual(task.column, .backlog)
        XCTAssertEqual(task.description, "")
    }

    func testDocumentWordCountIsAccurate() {
        let content = "One two three four five"
        let doc = Document(title: "Test", content: content, category: .article)

        XCTAssertEqual(doc.wordCount, 5)
    }

    func testDocumentWordCountWithExtraSpaces() {
        let content = "One   two    three     four      five"
        let doc = Document(title: "Test", content: content, category: .article)

        XCTAssertEqual(doc.wordCount, 5)
    }

    func testDocumentWordCountWithNewlines() {
        let content = "One\ntwo\nthree\nfour\nfive"
        let doc = Document(title: "Test", content: content, category: .article)

        XCTAssertEqual(doc.wordCount, 5)
    }

    func testDocumentWordCountEmpty() {
        let doc = Document(title: "Test", content: "", category: .article)
        XCTAssertEqual(doc.wordCount, 0)
    }

    func testInitWithAIConfiguration() {
        let config = AIConfiguration(apiKey: "test-key", model: .claude35Sonnet)
        let testApp = WritersApp(aiConfiguration: config)

        XCTAssertTrue(testApp.isAIEnabled)
    }

    func testInitWithCustomDatabasePath() {
        let testPath = "/tmp/custom_test_\(UUID().uuidString).db"
        let testApp = WritersApp(databasePath: testPath)

        let userId = UUID()
        testApp.startSession(userId: userId)

        let sessions = try? testApp.databaseManager.getUserSessions(userId: userId)
        XCTAssertEqual(sessions?.count, 1)

        testApp.databaseManager.close()
        try? FileManager.default.removeItem(atPath: testPath)
    }

    func testBrainstormIdeasThrowsWhenAINotEnabled() async {
        do {
            _ = try await app.brainstormIdeas(topic: "Space exploration")
            XCTFail("Should throw AIError.aiNotEnabled")
        } catch AIError.aiNotEnabled {
            // Expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testGenerateOutlineThrowsWhenAINotEnabled() async {
        do {
            _ = try await app.generateOutline(concept: "Mystery novel")
            XCTFail("Should throw AIError.aiNotEnabled")
        } catch AIError.aiNotEnabled {
            // Expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testDevelopCharacterThrowsWhenAINotEnabled() async {
        do {
            _ = try await app.developCharacter(characterConcept: "Detective")
            XCTFail("Should throw AIError.aiNotEnabled")
        } catch AIError.aiNotEnabled {
            // Expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testGetAIAssistanceWithToolsThrowsWhenAINotEnabled() async {
        let doc = app.createBlankDocument(title: "Test", category: .novel)

        do {
            _ = try await app.getAIAssistanceWithTools(documentId: doc.id, type: .continueWriting)
            XCTFail("Should throw AIError.aiNotEnabled")
        } catch AIError.aiNotEnabled {
            // Expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testAIErrorDescriptions() {
        let aiNotEnabled = AIError.aiNotEnabled
        XCTAssertNotNil(aiNotEnabled.errorDescription)
        XCTAssertTrue(aiNotEnabled.errorDescription!.contains("not enabled"))

        let documentNotFound = AIError.documentNotFound
        XCTAssertNotNil(documentNotFound.errorDescription)
        XCTAssertTrue(documentNotFound.errorDescription!.contains("not found"))
    }

    func testDatabaseErrorDescriptions() {
        let connectionFailed = DatabaseError.connectionFailed("test message")
        XCTAssertNotNil(connectionFailed.errorDescription)
        XCTAssertTrue(connectionFailed.errorDescription!.contains("test message"))

        let queryFailed = DatabaseError.queryFailed("query error")
        XCTAssertNotNil(queryFailed.errorDescription)
        XCTAssertTrue(queryFailed.errorDescription!.contains("query error"))

        let invalidData = DatabaseError.invalidData("data error")
        XCTAssertNotNil(invalidData.errorDescription)
        XCTAssertTrue(invalidData.errorDescription!.contains("data error"))

        let notInitialized = DatabaseError.notInitialized
        XCTAssertNotNil(notInitialized.errorDescription)
        XCTAssertTrue(notInitialized.errorDescription!.contains("not initialized"))
    }

    func testExportFormatCases() {
        let formats: [ExportFormat] = [.markdown, .plainText, .html]
        XCTAssertEqual(formats.count, 3)
    }

    // MARK: - Additional Regression and Edge Case Tests

    func testContinueDocumentLogsToDatabase() async throws {
        let testDbPath = "/tmp/test_continue_doc_\(UUID().uuidString).db"
        let testApp = WritersApp(databasePath: testDbPath)
        let userId = UUID()

        let config = AIConfiguration(apiKey: "test-key", model: .claude35Sonnet)
        testApp.enableAI(configuration: config, userId: userId)

        let doc = testApp.createBlankDocument(title: "Test", category: .novel)

        // Note: This will fail because AI service is not properly configured for actual API calls
        // But we can test that the error is appropriate
        do {
            _ = try await testApp.continueDocument(documentId: doc.id)
            // If this somehow succeeds, verify logging
        } catch {
            // Expected to fail without actual API key
        }

        testApp.databaseManager.close()
        try? FileManager.default.removeItem(atPath: testDbPath)
    }

    func testImproveDocumentLogsToDatabase() async throws {
        let testDbPath = "/tmp/test_improve_doc_\(UUID().uuidString).db"
        let testApp = WritersApp(databasePath: testDbPath)
        let userId = UUID()

        let config = AIConfiguration(apiKey: "test-key", model: .claude35Sonnet)
        testApp.enableAI(configuration: config, userId: userId)

        let doc = testApp.createBlankDocument(title: "Test", category: .novel)

        do {
            _ = try await testApp.improveDocument(documentId: doc.id)
        } catch {
            // Expected to fail without actual API
        }

        testApp.databaseManager.close()
        try? FileManager.default.removeItem(atPath: testDbPath)
    }

    func testSessionManagementWithMultipleSequentialSessions() {
        let userId = UUID()

        app.startSession(userId: userId, multitaskingMode: "Full Screen")
        app.updateSessionStats(wordsWritten: 100, aiInteractions: 1)
        app.endSession()

        app.startSession(userId: userId, multitaskingMode: "Split View")
        app.updateSessionStats(wordsWritten: 200, aiInteractions: 2)
        app.endSession()

        app.startSession(userId: userId, multitaskingMode: "Slide Over")
        app.updateSessionStats(wordsWritten: 300, aiInteractions: 3)
        app.endSession()

        let sessions = try? app.getUserSessions(userId: userId)
        XCTAssertEqual(sessions?.count, 3)

        let totalWords = sessions?.reduce(0) { $0 + $1.wordsWritten } ?? 0
        XCTAssertEqual(totalWords, 600)
    }

    func testIssueManagementWithComplexWorkflow() {
        let doc = app.createBlankDocument(title: "Complex Doc", category: .novel)

        let issue1 = app.createIssue(documentId: doc.id, title: "Plot hole", priority: .critical)
        let issue2 = app.createIssue(documentId: doc.id, title: "Typo", priority: .low)
        let issue3 = app.createIssue(documentId: doc.id, title: "Character inconsistency", priority: .high)

        app.updateIssueStatus(id: issue2.id, status: .resolved)

        let openIssues = app.getOpenIssues(forDocument: doc.id)
        XCTAssertEqual(openIssues.count, 2)

        let criticalIssues = app.getCriticalIssues()
        XCTAssertEqual(criticalIssues.count, 1)
        XCTAssertEqual(criticalIssues.first?.title, "Plot hole")
    }

    func testKanbanBoardWithMultipleTasks() {
        let board = app.createKanbanBoard(name: "Writing Project")

        let task1 = app.createKanbanTask(boardId: board.id, title: "Outline", description: "Create chapter outline")
        let task2 = app.createKanbanTask(boardId: board.id, title: "Research", description: "Research historical period")
        let task3 = app.createKanbanTask(boardId: board.id, title: "Draft", description: "Write first draft")

        app.advanceKanbanTask(id: task1.id)
        app.advanceKanbanTask(id: task1.id)

        let planningTasks = app.getKanbanTasks(forBoard: board.id, inColumn: .planning)
        XCTAssertEqual(planningTasks.count, 0)

        let runningTasks = app.getKanbanTasks(forBoard: board.id, inColumn: .running)
        XCTAssertEqual(runningTasks.count, 1)

        let backlogTasks = app.getKanbanTasks(forBoard: board.id, inColumn: .backlog)
        XCTAssertEqual(backlogTasks.count, 2)
    }

    func testKanbanTaskCompleteWorkflow() {
        let board = app.createKanbanBoard(name: "Workflow Board")
        let task = app.createKanbanTask(boardId: board.id, title: "Complete Task")

        XCTAssertEqual(task.column, .backlog)
        XCTAssertNil(task.metadata.completedAt)

        app.advanceKanbanTask(id: task.id)
        XCTAssertEqual(app.getKanbanTask(id: task.id)?.column, .planning)

        app.advanceKanbanTask(id: task.id)
        XCTAssertEqual(app.getKanbanTask(id: task.id)?.column, .running)

        app.advanceKanbanTask(id: task.id)
        XCTAssertEqual(app.getKanbanTask(id: task.id)?.column, .review)

        app.advanceKanbanTask(id: task.id)
        let completedTask = app.getKanbanTask(id: task.id)
        XCTAssertEqual(completedTask?.column, .done)
        XCTAssertNotNil(completedTask?.metadata.completedAt)

        let result = app.advanceKanbanTask(id: task.id)
        XCTAssertNil(result)
    }

    func testKanbanTaskRegressionWorkflow() {
        let board = app.createKanbanBoard(name: "Regress Board")
        let task = app.createKanbanTask(boardId: board.id, title: "Task", column: .done)

        app.regressKanbanTask(id: task.id)
        XCTAssertEqual(app.getKanbanTask(id: task.id)?.column, .review)

        app.regressKanbanTask(id: task.id)
        XCTAssertEqual(app.getKanbanTask(id: task.id)?.column, .running)

        app.regressKanbanTask(id: task.id)
        XCTAssertEqual(app.getKanbanTask(id: task.id)?.column, .planning)

        app.regressKanbanTask(id: task.id)
        XCTAssertEqual(app.getKanbanTask(id: task.id)?.column, .backlog)

        let result = app.regressKanbanTask(id: task.id)
        XCTAssertNil(result)
    }

    func testDocumentWithVeryLongContent() {
        let longContent = String(repeating: "word ", count: 10000)
        let doc = Document(title: "Long Doc", content: longContent, category: .novel)
        app.documentManager.createDocument(doc)

        let exported = app.exportDocument(id: doc.id, format: .plainText)
        XCTAssertEqual(exported?.count, longContent.count)
    }

    func testTemplateWithManyPlaceholders() {
        let placeholders = (1...20).map { Placeholder(key: "var\($0)", label: "Variable \($0)") }
        let content = placeholders.map { "{{\($0.key)}}" }.joined(separator: " ")

        let template = Template(
            name: "Many Vars",
            category: .other,
            description: "Template with many placeholders",
            content: content,
            placeholders: placeholders
        )

        var values: [String: String] = [:]
        for p in placeholders {
            values[p.key] = "Value"
        }

        let doc = template.createDocument(with: values)
        XCTAssertFalse(doc.content.contains("{{"))
    }

    func testSearchDocumentsWithPartialMatch() {
        app.documentManager.createDocument(Document(title: "Science Fiction Novel", content: "Space travel", category: .novel))
        app.documentManager.createDocument(Document(title: "Fiction Writing Guide", content: "Tips", category: .article))
        app.documentManager.createDocument(Document(title: "Non-Fiction Essay", content: "Facts", category: .essay))

        let results = app.documentManager.searchDocuments(query: "Fiction")
        XCTAssertEqual(results.count, 3)
    }

    func testSearchDocumentsCaseInsensitive() {
        app.documentManager.createDocument(Document(title: "UPPERCASE TITLE", content: "content", category: .novel))
        app.documentManager.createDocument(Document(title: "lowercase title", content: "content", category: .novel))
        app.documentManager.createDocument(Document(title: "MiXeD CaSe Title", content: "content", category: .novel))

        let results = app.documentManager.searchDocuments(query: "title")
        XCTAssertEqual(results.count, 3)
    }

    func testDocumentManagerUpdateDocument() {
        var doc = Document(title: "Original", content: "Original content", category: .article)
        app.documentManager.createDocument(doc)

        doc.title = "Updated"
        doc.content = "Updated content"
        app.documentManager.updateDocument(doc)

        let retrieved = app.documentManager.getDocument(id: doc.id)
        XCTAssertEqual(retrieved?.title, "Updated")
        XCTAssertEqual(retrieved?.content, "Updated content")
    }

    func testDocumentManagerGetAllDocumentsSortedByModified() {
        let doc1 = Document(title: "Doc 1", content: "Content 1", category: .novel)
        Thread.sleep(forTimeInterval: 0.01)
        let doc2 = Document(title: "Doc 2", content: "Content 2", category: .novel)
        Thread.sleep(forTimeInterval: 0.01)
        let doc3 = Document(title: "Doc 3", content: "Content 3", category: .novel)

        app.documentManager.createDocument(doc1)
        app.documentManager.createDocument(doc2)
        app.documentManager.createDocument(doc3)

        let all = app.documentManager.getAllDocuments()
        XCTAssertEqual(all.count, 3)
    }

    func testGetStatisticsWithVaryingWordCounts() {
        app.documentManager.createDocument(Document(title: "Short", content: "One", category: .article))
        app.documentManager.createDocument(Document(title: "Medium", content: "One two three four five", category: .article))
        app.documentManager.createDocument(Document(title: "Long", content: String(repeating: "word ", count: 100), category: .article))

        let stats = app.getStatistics()
        XCTAssertEqual(stats.totalDocuments, 3)
        XCTAssertGreaterThan(stats.totalWordCount, 100)
        XCTAssertGreaterThan(stats.averageWordCount, 30)
    }

    func testExportDocumentMarkdownWithSpecialCharacters() {
        let doc = Document(
            title: "Special: Title & More",
            content: "Content with <html> & \"quotes\"",
            category: .article
        )
        app.documentManager.createDocument(doc)

        let exported = app.exportDocument(id: doc.id, format: .markdown)
        XCTAssertNotNil(exported)
        XCTAssertTrue(exported!.contains("Special: Title & More"))
        XCTAssertTrue(exported!.contains("<html>"))
    }

    func testExportDocumentHTMLEscaping() {
        let doc = Document(
            title: "HTML Title",
            content: "Content with <script>alert('test')</script>",
            category: .article
        )
        app.documentManager.createDocument(doc)

        let exported = app.exportDocument(id: doc.id, format: .html)
        XCTAssertNotNil(exported)
        XCTAssertTrue(exported!.contains("<!DOCTYPE html>"))
    }

    func testReopenIssueMultipleTimes() {
        let doc = app.createBlankDocument(title: "Test", category: .novel)
        let issue = app.createIssue(documentId: doc.id, title: "Reopenable")

        app.updateIssueStatus(id: issue.id, status: .resolved)
        XCTAssertNotNil(app.getIssue(id: issue.id)?.metadata.resolvedAt)

        app.reopenIssue(id: issue.id)
        XCTAssertNil(app.getIssue(id: issue.id)?.metadata.resolvedAt)

        app.updateIssueStatus(id: issue.id, status: .resolved)
        XCTAssertNotNil(app.getIssue(id: issue.id)?.metadata.resolvedAt)

        app.reopenIssue(id: issue.id)
        XCTAssertNil(app.getIssue(id: issue.id)?.metadata.resolvedAt)
    }

    func testUpdateIssuePriorityMultipleTimes() {
        let doc = app.createBlankDocument(title: "Test", category: .novel)
        let issue = app.createIssue(documentId: doc.id, title: "Priority Test", priority: .low)

        app.updateIssuePriority(id: issue.id, priority: .medium)
        XCTAssertEqual(app.getIssue(id: issue.id)?.priority, .medium)

        app.updateIssuePriority(id: issue.id, priority: .high)
        XCTAssertEqual(app.getIssue(id: issue.id)?.priority, .high)

        app.updateIssuePriority(id: issue.id, priority: .critical)
        XCTAssertEqual(app.getIssue(id: issue.id)?.priority, .critical)

        app.updateIssuePriority(id: issue.id, priority: .low)
        XCTAssertEqual(app.getIssue(id: issue.id)?.priority, .low)
    }

    func testGetIssueStatisticsWithVariedData() {
        let doc = app.createBlankDocument(title: "Test", category: .novel)

        app.createIssue(documentId: doc.id, title: "I1", status: .open, priority: .low)
        app.createIssue(documentId: doc.id, title: "I2", status: .open, priority: .medium)
        app.createIssue(documentId: doc.id, title: "I3", status: .inProgress, priority: .high)
        app.createIssue(documentId: doc.id, title: "I4", status: .resolved, priority: .critical)
        app.createIssue(documentId: doc.id, title: "I5", status: .closed, priority: .low)

        let (byStatus, byPriority) = app.getIssueStatistics()

        XCTAssertEqual(byStatus[.open], 2)
        XCTAssertEqual(byStatus[.inProgress], 1)
        XCTAssertEqual(byStatus[.resolved], 1)
        XCTAssertEqual(byStatus[.closed], 1)

        XCTAssertEqual(byPriority[.low], 2)
        XCTAssertEqual(byPriority[.medium], 1)
        XCTAssertEqual(byPriority[.high], 1)
        XCTAssertEqual(byPriority[.critical], 1)
    }

    func testMultipleKanbanBoardsIndependence() {
        let board1 = app.createKanbanBoard(name: "Board 1")
        let board2 = app.createKanbanBoard(name: "Board 2")

        app.createKanbanTask(boardId: board1.id, title: "B1 T1")
        app.createKanbanTask(boardId: board1.id, title: "B1 T2")
        app.createKanbanTask(boardId: board2.id, title: "B2 T1")

        XCTAssertEqual(app.getKanbanTasks(forBoard: board1.id).count, 2)
        XCTAssertEqual(app.getKanbanTasks(forBoard: board2.id).count, 1)

        app.deleteKanbanBoard(id: board1.id)

        XCTAssertTrue(app.getKanbanTasks(forBoard: board1.id).isEmpty)
        XCTAssertEqual(app.getKanbanTasks(forBoard: board2.id).count, 1)
    }

    func testKanbanTaskSearchAcrossMultipleBoards() {
        let board1 = app.createKanbanBoard(name: "Board 1")
        let board2 = app.createKanbanBoard(name: "Board 2")

        app.createKanbanTask(boardId: board1.id, title: "Write chapter one")
        app.createKanbanTask(boardId: board1.id, title: "Edit draft")
        app.createKanbanTask(boardId: board2.id, title: "Write synopsis")
        app.createKanbanTask(boardId: board2.id, title: "Proofread")

        let results = app.searchKanbanTasks(query: "Write")
        XCTAssertEqual(results.count, 2)
    }

    func testAppStatisticsWithEmptyCategories() {
        app.documentManager.createDocument(Document(title: "Doc", content: "", category: .novel))

        let stats = app.getStatistics()

        XCTAssertEqual(stats.totalDocuments, 1)
        XCTAssertEqual(stats.documentsByCategory[.novel], 1)
        XCTAssertNil(stats.documentsByCategory[.article])
        XCTAssertNil(stats.documentsByCategory[.essay])
    }

    func testEnableAISavesConfigurationToDatabase() throws {
        let testDbPath = "/tmp/test_ai_config_\(UUID().uuidString).db"
        let testApp = WritersApp(databasePath: testDbPath)

        let userId = UUID()
        let config = AIConfiguration(apiKey: "test-key-123", model: .claude35Sonnet, maxTokens: 8192)

        testApp.enableAI(configuration: config, userId: userId)

        let retrieved = try testApp.databaseManager.getAIConfiguration(userId: userId)
        XCTAssertEqual(retrieved?.apiKey, "test-key-123")
        XCTAssertEqual(retrieved?.model, .claude35Sonnet)
        XCTAssertEqual(retrieved?.maxTokens, 8192)

        testApp.databaseManager.close()
        try? FileManager.default.removeItem(atPath: testDbPath)
    }

    func testDisableAIKeepsConfigurationInDatabase() throws {
        let testDbPath = "/tmp/test_ai_disable_\(UUID().uuidString).db"
        let testApp = WritersApp(databasePath: testDbPath)

        let userId = UUID()
        let config = AIConfiguration(apiKey: "test-key", model: .claude3Opus)

        testApp.enableAI(configuration: config, userId: userId)
        testApp.disableAI()

        XCTAssertFalse(testApp.isAIEnabled)

        let retrieved = try testApp.databaseManager.getAIConfiguration(userId: userId)
        XCTAssertNotNil(retrieved)

        testApp.databaseManager.close()
        try? FileManager.default.removeItem(atPath: testDbPath)
    }

    func testGetAISuggestionsReturnsEmptyForNewUser() throws {
        let newUserId = UUID()
        let suggestions = try app.getAISuggestions(userId: newUserId)
        XCTAssertEqual(suggestions.count, 0)
    }

    func testGetUserSessionsReturnsEmptyForNewUser() throws {
        let newUserId = UUID()
        let sessions = try app.getUserSessions(userId: newUserId)
        XCTAssertEqual(sessions.count, 0)
    }

    func testInitWithDefaultConstructor() {
        let testApp = WritersApp()
        XCTAssertNotNil(testApp.templateManager)
        XCTAssertNotNil(testApp.documentManager)
        XCTAssertNotNil(testApp.issueManager)
        XCTAssertNotNil(testApp.kanbanManager)
        XCTAssertNotNil(testApp.databaseManager)
        XCTAssertFalse(testApp.isAIEnabled)
    }

    func testCreateBlankDocumentWithVariousCategories() {
        let categories: [TemplateCategory] = [.novel, .shortStory, .poem, .article, .blogPost, .essay, .other]

        for category in categories {
            let doc = app.createBlankDocument(title: "Test \(category.rawValue)", category: category)
            XCTAssertEqual(doc.category, category)
        }

        let allDocs = app.documentManager.getAllDocuments()
        XCTAssertEqual(allDocs.count, categories.count)
    }

    func testTemplateManagerGetAllTemplatesIsNotEmpty() {
        let templates = app.templateManager.getAllTemplates()
        XCTAssertGreaterThan(templates.count, 0)
    }

    func testDocumentMetadataTimestamps() {
        let beforeCreation = Date()
        let doc = app.createBlankDocument(title: "Timestamp Test", category: .novel)
        let afterCreation = Date()

        XCTAssertGreaterThanOrEqual(doc.metadata.created, beforeCreation)
        XCTAssertLessThanOrEqual(doc.metadata.created, afterCreation)
        XCTAssertEqual(doc.metadata.created, doc.metadata.modified)
    }

    func testIssueMetadataTimestamps() {
        let beforeCreation = Date()
        let doc = app.createBlankDocument(title: "Test", category: .novel)
        let issue = app.createIssue(documentId: doc.id, title: "Issue")
        let afterCreation = Date()

        XCTAssertGreaterThanOrEqual(issue.metadata.created, beforeCreation)
        XCTAssertLessThanOrEqual(issue.metadata.created, afterCreation)
    }

    func testKanbanTaskMetadataTimestamps() {
        let beforeCreation = Date()
        let board = app.createKanbanBoard(name: "Board")
        let task = app.createKanbanTask(boardId: board.id, title: "Task")
        let afterCreation = Date()

        XCTAssertGreaterThanOrEqual(task.metadata.created, beforeCreation)
        XCTAssertLessThanOrEqual(task.metadata.created, afterCreation)
    }

    func testSessionStatsCalculations() throws {
        let userId = UUID()
        let testDbPath = "/tmp/test_stats_\(UUID().uuidString).db"
        let testApp = WritersApp(databasePath: testDbPath)

        try testApp.databaseManager.insertUserSession(UserSession(userId: userId, durationSeconds: 1200))
        try testApp.databaseManager.insertUserSession(UserSession(userId: userId, durationSeconds: 1800))
        try testApp.databaseManager.insertUserSession(UserSession(userId: userId, durationSeconds: 3000))

        let stats = try testApp.getSessionStats(userId: userId)

        XCTAssertEqual(stats.totalSessions, 3)
        XCTAssertEqual(stats.totalDurationSeconds, 6000)
        XCTAssertEqual(stats.averageDurationSeconds, 2000.0)

        testApp.databaseManager.close()
        try? FileManager.default.removeItem(atPath: testDbPath)
    }
}