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

    // MARK: - Database Integration Tests

    func testSessionManagement() throws {
        // Create app with temporary database
        let tempPath = "/tmp/test_app_db_\(UUID().uuidString).db"
        defer { try? FileManager.default.removeItem(atPath: tempPath) }

        let app = WritersApp(databasePath: tempPath)
        let userId = UUID()

        // Start session
        app.startSession(userId: userId, multitaskingMode: "Split View")

        // Update session stats
        app.updateSessionStats(wordsWritten: 500, aiInteractions: 3)

        // End session
        app.endSession()

        // Verify session was recorded
        let sessions = try app.getUserSessions(userId: userId)
        XCTAssertEqual(sessions.count, 1)
        XCTAssertEqual(sessions.first?.wordsWritten, 500)
        XCTAssertEqual(sessions.first?.aiInteractions, 3)
        XCTAssertEqual(sessions.first?.multitaskingMode, "Split View")
        XCTAssertNotNil(sessions.first?.endTime)
        XCTAssertNotNil(sessions.first?.durationSeconds)
    }

    func testIssueManagementIntegration() throws {
        let tempPath = "/tmp/test_app_db_\(UUID().uuidString).db"
        defer { try? FileManager.default.removeItem(atPath: tempPath) }

        let app = WritersApp(databasePath: tempPath)
        let doc = app.createBlankDocument(title: "Test Doc", category: .novel)

        // Create issue
        let issue = app.createIssue(
            documentId: doc.id,
            title: "Plot hole",
            description: "Chapter 3 has inconsistent timeline",
            status: .open,
            priority: .high
        )

        // Verify issue was saved to database
        let dbIssues = try app.databaseManager.getIssues(forDocument: doc.id)
        XCTAssertEqual(dbIssues.count, 1)
        XCTAssertEqual(dbIssues.first?.title, "Plot hole")

        // Update issue
        var updatedIssue = issue
        updatedIssue.status = .resolved
        app.updateIssue(updatedIssue)

        // Verify update in database
        let updated = try app.databaseManager.getIssues(forDocument: doc.id)
        XCTAssertEqual(updated.first?.status, .resolved)

        // Delete issue
        app.deleteIssue(id: issue.id)

        // Verify deletion from database
        let afterDelete = try app.databaseManager.getIssues(forDocument: doc.id)
        XCTAssertEqual(afterDelete.count, 0)
    }

    func testIssueStatusUpdateIntegration() throws {
        let tempPath = "/tmp/test_app_db_\(UUID().uuidString).db"
        defer { try? FileManager.default.removeItem(atPath: tempPath) }

        let app = WritersApp(databasePath: tempPath)
        let doc = app.createBlankDocument(title: "Test Doc", category: .article)

        let issue = app.createIssue(documentId: doc.id, title: "Test Issue")

        // Update status
        app.updateIssueStatus(id: issue.id, status: .inProgress)

        // Verify in database
        let dbIssues = try app.databaseManager.getIssues(forDocument: doc.id)
        XCTAssertEqual(dbIssues.first?.status, .inProgress)

        // Reopen issue
        app.updateIssueStatus(id: issue.id, status: .resolved)
        app.reopenIssue(id: issue.id)

        // Verify reopened in database
        let reopened = try app.databaseManager.getIssues(forDocument: doc.id)
        XCTAssertEqual(reopened.first?.status, .open)
        XCTAssertNil(reopened.first?.metadata.resolvedAt)
    }

    func testIssuePriorityUpdateIntegration() throws {
        let tempPath = "/tmp/test_app_db_\(UUID().uuidString).db"
        defer { try? FileManager.default.removeItem(atPath: tempPath) }

        let app = WritersApp(databasePath: tempPath)
        let doc = app.createBlankDocument(title: "Test Doc", category: .novel)

        let issue = app.createIssue(documentId: doc.id, title: "Priority Test", priority: .low)

        // Update priority
        app.updateIssuePriority(id: issue.id, priority: .critical)

        // Verify in database
        let dbIssues = try app.databaseManager.getIssues(forDocument: doc.id)
        XCTAssertEqual(dbIssues.first?.priority, .critical)
    }

    func testAIConfigurationIntegration() throws {
        let tempPath = "/tmp/test_app_db_\(UUID().uuidString).db"
        defer { try? FileManager.default.removeItem(atPath: tempPath) }

        let app = WritersApp(databasePath: tempPath)
        let userId = UUID()

        let config = AIConfiguration(
            apiKey: "test-key",
            model: .claude35Sonnet,
            maxTokens: 4096,
            temperature: 0.7
        )

        app.enableAI(configuration: config, userId: userId)

        // Verify configuration was saved to database
        let savedConfig = try app.databaseManager.getAIConfiguration(userId: userId)
        XCTAssertNotNil(savedConfig)
        XCTAssertEqual(savedConfig?.apiKey, "test-key")
        XCTAssertEqual(savedConfig?.model, .claude35Sonnet)
    }

    func testMultipleSessionsTracking() throws {
        let tempPath = "/tmp/test_app_db_\(UUID().uuidString).db"
        defer { try? FileManager.default.removeItem(atPath: tempPath) }

        let app = WritersApp(databasePath: tempPath)
        let userId = UUID()

        // Create multiple sessions
        for i in 1...3 {
            app.startSession(userId: userId)
            app.updateSessionStats(wordsWritten: i * 100, aiInteractions: i)
            app.endSession()
        }

        // Verify all sessions tracked
        let sessions = try app.getUserSessions(userId: userId)
        XCTAssertEqual(sessions.count, 3)
    }

    func testSessionStatistics() throws {
        let tempPath = "/tmp/test_app_db_\(UUID().uuidString).db"
        defer { try? FileManager.default.removeItem(atPath: tempPath) }

        let app = WritersApp(databasePath: tempPath)
        let userId = UUID()

        // Create sessions with known durations
        let session1 = UserSession(userId: userId, durationSeconds: 1000)
        let session2 = UserSession(userId: userId, durationSeconds: 2000)
        let session3 = UserSession(userId: userId, durationSeconds: 3000)

        try app.databaseManager.insertUserSession(session1)
        try app.databaseManager.insertUserSession(session2)
        try app.databaseManager.insertUserSession(session3)

        // Get session stats
        let stats = try app.getSessionStats(userId: userId)
        XCTAssertEqual(stats.totalSessions, 3)
        XCTAssertEqual(stats.totalDurationSeconds, 6000)
        XCTAssertEqual(stats.averageDurationSeconds, 2000.0)
    }

    func testGetAISuggestionsIntegration() throws {
        let tempPath = "/tmp/test_app_db_\(UUID().uuidString).db"
        defer { try? FileManager.default.removeItem(atPath: tempPath) }

        let app = WritersApp(databasePath: tempPath)
        let userId = UUID()

        // Insert test suggestions
        for i in 1...10 {
            let suggestion = AISuggestion(
                userId: userId,
                toolUsed: "Tool \(i)",
                prompt: "Prompt \(i)",
                response: "Response \(i)"
            )
            try app.databaseManager.insertAISuggestion(suggestion)
        }

        // Test pagination
        let firstPage = try app.getAISuggestions(userId: userId, limit: 5, offset: 0)
        XCTAssertEqual(firstPage.count, 5)

        let secondPage = try app.getAISuggestions(userId: userId, limit: 5, offset: 5)
        XCTAssertEqual(secondPage.count, 5)

        // Verify different results
        XCTAssertNotEqual(firstPage.first?.id, secondPage.first?.id)
    }

    func testAIToolUsageStatsIntegration() throws {
        let tempPath = "/tmp/test_app_db_\(UUID().uuidString).db"
        defer { try? FileManager.default.removeItem(atPath: tempPath) }

        let app = WritersApp(databasePath: tempPath)
        let userId = UUID()

        // Insert suggestions with different tools
        let tools = ["Continue Writing", "Grammar Check", "Continue Writing", "Improve Text"]
        for tool in tools {
            let suggestion = AISuggestion(userId: userId, toolUsed: tool, prompt: "Test", response: "Test")
            try app.databaseManager.insertAISuggestion(suggestion)
        }

        // Get stats
        let stats = try app.getAIToolUsageStats(userId: userId)
        XCTAssertEqual(stats.count, 3) // 3 unique tools
        XCTAssertEqual(stats.first?.toolName, "Continue Writing")
        XCTAssertEqual(stats.first?.usageCount, 2)
    }

    func testDatabaseInitializationOnAppCreation() throws {
        let tempPath = "/tmp/test_app_db_\(UUID().uuidString).db"
        defer { try? FileManager.default.removeItem(atPath: tempPath) }

        let app = WritersApp(databasePath: tempPath)

        // Verify database can be used immediately
        let userId = UUID()
        let suggestion = AISuggestion(userId: userId, toolUsed: "Test", prompt: "Test", response: "Test")

        XCTAssertNoThrow(try app.databaseManager.insertAISuggestion(suggestion))

        let retrieved = try app.databaseManager.getAISuggestions(userId: userId)
        XCTAssertEqual(retrieved.count, 1)
    }

    func testTraceAndObservationWorkflow() throws {
        let tempPath = "/tmp/test_app_db_\(UUID().uuidString).db"
        defer { try? FileManager.default.removeItem(atPath: tempPath) }

        let app = WritersApp(databasePath: tempPath)

        // Create trace
        let trace = Trace(sessionId: "test-session", name: "Writing Session", startTime: Date())
        try app.databaseManager.insertTrace(trace)

        // Add observations
        let obs1 = Observation(traceId: trace.id, name: "Start Writing", startTime: Date())
        let obs2 = Observation(traceId: trace.id, name: "AI Assist", startTime: Date())

        try app.databaseManager.insertObservation(obs1)
        try app.databaseManager.insertObservation(obs2)

        // Retrieve and verify
        let traces = try app.databaseManager.getTraces(sessionId: "test-session")
        XCTAssertEqual(traces.count, 1)

        let observations = try app.databaseManager.getObservations(traceId: trace.id)
        XCTAssertEqual(observations.count, 2)
    }

    func testConcurrentIssueOperations() throws {
        let tempPath = "/tmp/test_app_db_\(UUID().uuidString).db"
        defer { try? FileManager.default.removeItem(atPath: tempPath) }

        let app = WritersApp(databasePath: tempPath)
        let doc = app.createBlankDocument(title: "Test Doc", category: .novel)

        // Create multiple issues
        let issue1 = app.createIssue(documentId: doc.id, title: "Issue 1", priority: .low)
        let issue2 = app.createIssue(documentId: doc.id, title: "Issue 2", priority: .high)
        let issue3 = app.createIssue(documentId: doc.id, title: "Issue 3", priority: .medium)

        // Update different issues
        app.updateIssueStatus(id: issue1.id, status: .resolved)
        app.updateIssuePriority(id: issue2.id, priority: .critical)

        // Verify all changes persisted
        let allIssues = app.getIssues(forDocument: doc.id)
        XCTAssertEqual(allIssues.count, 3)

        let resolvedIssues = allIssues.filter { $0.status == .resolved }
        XCTAssertEqual(resolvedIssues.count, 1)

        let criticalIssues = allIssues.filter { $0.priority == .critical }
        XCTAssertEqual(criticalIssues.count, 1)
    }

    func testEmptyDatabaseQueries() throws {
        let tempPath = "/tmp/test_app_db_\(UUID().uuidString).db"
        defer { try? FileManager.default.removeItem(atPath: tempPath) }

        let app = WritersApp(databasePath: tempPath)
        let userId = UUID()

        // Test all empty queries
        let suggestions = try app.getAISuggestions(userId: userId)
        XCTAssertEqual(suggestions.count, 0)

        let sessions = try app.getUserSessions(userId: userId)
        XCTAssertEqual(sessions.count, 0)

        let stats = try app.getSessionStats(userId: userId)
        XCTAssertEqual(stats.totalSessions, 0)

        let toolStats = try app.getAIToolUsageStats(userId: userId)
        XCTAssertEqual(toolStats.count, 0)
    }

    func testSessionDurationCalculation() throws {
        let tempPath = "/tmp/test_app_db_\(UUID().uuidString).db"
        defer { try? FileManager.default.removeItem(atPath: tempPath) }

        let app = WritersApp(databasePath: tempPath)
        let userId = UUID()

        app.startSession(userId: userId)

        // Simulate some time passing
        Thread.sleep(forTimeInterval: 0.1)

        app.endSession()

        let sessions = try app.getUserSessions(userId: userId)
        XCTAssertEqual(sessions.count, 1)
        XCTAssertNotNil(sessions.first?.durationSeconds)
        XCTAssertGreaterThan(sessions.first?.durationSeconds ?? 0, 0)
    }

    func testGetUserSessionsSortedByDuration() throws {
        let tempPath = "/tmp/test_app_db_\(UUID().uuidString).db"
        defer { try? FileManager.default.removeItem(atPath: tempPath) }

        let app = WritersApp(databasePath: tempPath)
        let userId = UUID()

        // Create sessions with different durations
        let session1 = UserSession(userId: userId, durationSeconds: 500)
        let session2 = UserSession(userId: userId, durationSeconds: 2000)
        let session3 = UserSession(userId: userId, durationSeconds: 100)

        try app.databaseManager.insertUserSession(session1)
        try app.databaseManager.insertUserSession(session2)
        try app.databaseManager.insertUserSession(session3)

        // Get sessions sorted by duration
        let sortedSessions = try app.getUserSessions(userId: userId, sortByDuration: true)
        XCTAssertEqual(sortedSessions.count, 3)
        XCTAssertEqual(sortedSessions[0].durationSeconds, 2000)
        XCTAssertEqual(sortedSessions[1].durationSeconds, 500)
        XCTAssertEqual(sortedSessions[2].durationSeconds, 100)
    }

    // MARK: - Additional Edge Case Tests

    func testAINotEnabledErrorHandling() {
        let app = WritersApp()
        let doc = app.createBlankDocument(title: "Test", category: .novel)

        // Try to use AI features without enabling AI
        let expectation = XCTestExpectation(description: "AI error thrown")

        Task {
            do {
                _ = try await app.continueDocument(documentId: doc.id)
                XCTFail("Should throw AI not enabled error")
            } catch let error as AIError {
                XCTAssertEqual(error, .aiNotEnabled)
                expectation.fulfill()
            } catch {
                XCTFail("Wrong error type: \(error)")
            }
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testDocumentNotFoundErrorHandling() {
        let app = WritersApp()
        let config = AIConfiguration(apiKey: "test", model: .claude35Sonnet)
        app.enableAI(configuration: config)

        let nonExistentId = UUID()
        let expectation = XCTestExpectation(description: "Document not found error thrown")

        Task {
            do {
                _ = try await app.continueDocument(documentId: nonExistentId)
                XCTFail("Should throw document not found error")
            } catch let error as AIError {
                XCTAssertEqual(error, .documentNotFound)
                expectation.fulfill()
            } catch {
                XCTFail("Wrong error type: \(error)")
            }
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testIsAIEnabledFlag() {
        let app = WritersApp()
        XCTAssertFalse(app.isAIEnabled)

        let config = AIConfiguration(apiKey: "test", model: .claude35Sonnet)
        app.enableAI(configuration: config)
        XCTAssertTrue(app.isAIEnabled)

        app.disableAI()
        XCTAssertFalse(app.isAIEnabled)
    }

    func testCreateDocumentFromNonExistentTemplate() {
        let app = WritersApp()
        let nonExistentTemplateId = UUID()

        let doc = app.createDocumentFromTemplate(templateId: nonExistentTemplateId, values: [:])
        XCTAssertNil(doc)
    }

    func testExportNonExistentDocument() {
        let app = WritersApp()
        let nonExistentId = UUID()

        let exported = app.exportDocument(id: nonExistentId)
        XCTAssertNil(exported)
    }

    func testExportDocumentAsPlainText() {
        let app = WritersApp()
        let doc = Document(title: "Test", content: "Plain text content", category: .article)
        app.documentManager.createDocument(doc)

        let exported = app.exportDocument(id: doc.id, format: .plainText)
        XCTAssertEqual(exported, "Plain text content")
    }

    func testExportDocumentAsHTML() {
        let app = WritersApp()
        let doc = Document(title: "HTML Test", content: "HTML content", category: .blogPost)
        app.documentManager.createDocument(doc)

        let exported = app.exportDocument(id: doc.id, format: .html)
        XCTAssertNotNil(exported)
        XCTAssertTrue(exported?.contains("<!DOCTYPE html>") ?? false)
        XCTAssertTrue(exported?.contains("HTML Test") ?? false)
        XCTAssertTrue(exported?.contains("HTML content") ?? false)
    }

    func testStatisticsWithNoDocuments() {
        let app = WritersApp()
        let stats = app.getStatistics()

        XCTAssertEqual(stats.totalDocuments, 0)
        XCTAssertEqual(stats.totalWordCount, 0)
        XCTAssertEqual(stats.averageWordCount, 0)
    }

    func testUpdateIssueStatusOnNonExistentIssue() {
        let app = WritersApp()
        let nonExistentId = UUID()

        // Should not crash, just fail silently
        app.updateIssueStatus(id: nonExistentId, status: .resolved)

        let issue = app.getIssue(id: nonExistentId)
        XCTAssertNil(issue)
    }

    func testUpdateIssuePriorityOnNonExistentIssue() {
        let app = WritersApp()
        let nonExistentId = UUID()

        // Should not crash, just fail silently
        app.updateIssuePriority(id: nonExistentId, priority: .critical)

        let issue = app.getIssue(id: nonExistentId)
        XCTAssertNil(issue)
    }

    func testReopenNonExistentIssue() {
        let app = WritersApp()
        let nonExistentId = UUID()

        // Should not crash, just fail silently
        app.reopenIssue(id: nonExistentId)

        let issue = app.getIssue(id: nonExistentId)
        XCTAssertNil(issue)
    }

    func testGetIssuesForNonExistentDocument() {
        let app = WritersApp()
        let nonExistentDocId = UUID()

        let issues = app.getIssues(forDocument: nonExistentDocId)
        XCTAssertEqual(issues.count, 0)
    }

    func testSearchIssuesWithNoMatches() {
        let app = WritersApp()
        let doc = app.createBlankDocument(title: "Test", category: .novel)
        _ = app.createIssue(documentId: doc.id, title: "Bug in chapter 1")

        let results = app.searchIssues(query: "nonexistent xyz 123")
        XCTAssertEqual(results.count, 0)
    }

    func testGetIssueStatisticsWithNoIssues() {
        let app = WritersApp()
        let (byStatus, byPriority) = app.getIssueStatistics()

        XCTAssertEqual(byStatus.count, 0)
        XCTAssertEqual(byPriority.count, 0)
    }

    func testMoveNonExistentKanbanTask() {
        let app = WritersApp()
        let nonExistentId = UUID()

        // Should not crash
        app.moveKanbanTask(id: nonExistentId, toColumn: .done)

        let task = app.getKanbanTask(id: nonExistentId)
        XCTAssertNil(task)
    }

    func testAdvanceNonExistentKanbanTask() {
        let app = WritersApp()
        let nonExistentId = UUID()

        let result = app.advanceKanbanTask(id: nonExistentId)
        XCTAssertNil(result)
    }

    func testRegressNonExistentKanbanTask() {
        let app = WritersApp()
        let nonExistentId = UUID()

        let result = app.regressKanbanTask(id: nonExistentId)
        XCTAssertNil(result)
    }

    func testGetKanbanTasksForNonExistentBoard() {
        let app = WritersApp()
        let nonExistentBoardId = UUID()

        let tasks = app.getKanbanTasks(forBoard: nonExistentBoardId)
        XCTAssertEqual(tasks.count, 0)
    }

    func testSearchKanbanTasksWithNoResults() {
        let app = WritersApp()
        let board = app.createKanbanBoard(name: "Board")
        _ = app.createKanbanTask(boardId: board.id, title: "Task 1")

        let results = app.searchKanbanTasks(query: "nonexistent xyz")
        XCTAssertEqual(results.count, 0)
    }

    func testGetKanbanTaskCountsForEmptyBoard() {
        let app = WritersApp()
        let board = app.createKanbanBoard(name: "Empty Board")

        let counts = app.getKanbanTaskCounts(forBoard: board.id)
        XCTAssertEqual(counts[.backlog], 0)
        XCTAssertEqual(counts[.planning], 0)
        XCTAssertEqual(counts[.running], 0)
        XCTAssertEqual(counts[.review], 0)
        XCTAssertEqual(counts[.done], 0)
    }

    func testDeleteNonExistentKanbanBoard() {
        let app = WritersApp()
        let nonExistentId = UUID()

        // Should not crash
        app.deleteKanbanBoard(id: nonExistentId)
    }

    func testDeleteNonExistentKanbanTask() {
        let app = WritersApp()
        let nonExistentId = UUID()

        // Should not crash
        app.deleteKanbanTask(id: nonExistentId)
    }

    func testStartSessionWithoutUserId() {
        let tempPath = "/tmp/test_app_db_\(UUID().uuidString).db"
        defer { try? FileManager.default.removeItem(atPath: tempPath) }

        let app = WritersApp(databasePath: tempPath)
        let userId = UUID()

        app.startSession(userId: userId)

        // Update stats without setting user explicitly
        app.updateSessionStats(wordsWritten: 100, aiInteractions: 1)

        app.endSession()

        // Verify session was created
        let sessions = try? app.getUserSessions(userId: userId)
        XCTAssertEqual(sessions?.count, 1)
    }

    func testEndSessionWithoutStarting() {
        let app = WritersApp()

        // Should not crash
        app.endSession()
    }

    func testUpdateSessionStatsWithoutStarting() {
        let app = WritersApp()

        // Should not crash
        app.updateSessionStats(wordsWritten: 100, aiInteractions: 5)
    }

    func testGetAIToolUsageStatsWithDefaultUserId() throws {
        let tempPath = "/tmp/test_app_db_\(UUID().uuidString).db"
        defer { try? FileManager.default.removeItem(atPath: tempPath) }

        let app = WritersApp(databasePath: tempPath)

        // Call without explicit userId (uses default UUID)
        let stats = try app.getAIToolUsageStats(userId: nil)
        XCTAssertEqual(stats.count, 0)
    }

    func testGetSessionStatsWithDefaultUserId() throws {
        let tempPath = "/tmp/test_app_db_\(UUID().uuidString).db"
        defer { try? FileManager.default.removeItem(atPath: tempPath) }

        let app = WritersApp(databasePath: tempPath)

        // Call without explicit userId
        let stats = try app.getSessionStats(userId: nil)
        XCTAssertEqual(stats.totalSessions, 0)
    }

    func testGetAISuggestionsWithDefaultUserId() throws {
        let tempPath = "/tmp/test_app_db_\(UUID().uuidString).db"
        defer { try? FileManager.default.removeItem(atPath: tempPath) }

        let app = WritersApp(databasePath: tempPath)

        // Call without explicit userId
        let suggestions = try app.getAISuggestions(userId: nil)
        XCTAssertEqual(suggestions.count, 0)
    }

    func testGetUserSessionsWithDefaultUserId() throws {
        let tempPath = "/tmp/test_app_db_\(UUID().uuidString).db"
        defer { try? FileManager.default.removeItem(atPath: tempPath) }

        let app = WritersApp(databasePath: tempPath)

        // Call without explicit userId
        let sessions = try app.getUserSessions(userId: nil)
        XCTAssertEqual(sessions.count, 0)
    }

    func testGetOpenIssuesForDocumentWithNoIssues() {
        let app = WritersApp()
        let doc = app.createBlankDocument(title: "Test", category: .novel)

        let openIssues = app.getOpenIssues(forDocument: doc.id)
        XCTAssertEqual(openIssues.count, 0)
    }

    func testGetCriticalIssuesWithNone() {
        let app = WritersApp()
        let doc = app.createBlankDocument(title: "Test", category: .novel)
        _ = app.createIssue(documentId: doc.id, title: "Low priority", priority: .low)

        let criticalIssues = app.getCriticalIssues()
        XCTAssertEqual(criticalIssues.count, 0)
    }

    func testGetCriticalIssues() {
        let app = WritersApp()
        let doc1 = app.createBlankDocument(title: "Doc1", category: .novel)
        let doc2 = app.createBlankDocument(title: "Doc2", category: .article)

        _ = app.createIssue(documentId: doc1.id, title: "Critical 1", priority: .critical)
        _ = app.createIssue(documentId: doc2.id, title: "Critical 2", priority: .critical)
        _ = app.createIssue(documentId: doc1.id, title: "High", priority: .high)

        let criticalIssues = app.getCriticalIssues()
        XCTAssertEqual(criticalIssues.count, 2)
        XCTAssertTrue(criticalIssues.allSatisfy { $0.priority == .critical })
    }

    func testDocumentWordCountWithEmptyContent() {
        let doc = Document(title: "Empty", content: "", category: .article)
        XCTAssertEqual(doc.wordCount, 0)
    }

    func testDocumentWordCountWithWhitespaceOnly() {
        let doc = Document(title: "Whitespace", content: "   \n\n\t\t   ", category: .article)
        XCTAssertEqual(doc.wordCount, 0)
    }

    func testDocumentWordCountWithMultipleSpaces() {
        let doc = Document(title: "Spaces", content: "word1    word2     word3", category: .article)
        XCTAssertEqual(doc.wordCount, 3)
    }

    func testCreateIssueWithDefaultParameters() {
        let app = WritersApp()
        let doc = app.createBlankDocument(title: "Test", category: .novel)

        let issue = app.createIssue(documentId: doc.id, title: "Simple Issue")

        XCTAssertEqual(issue.title, "Simple Issue")
        XCTAssertEqual(issue.description, "")
        XCTAssertEqual(issue.status, .open)
        XCTAssertEqual(issue.priority, .medium)
    }

    func testCreateKanbanTaskWithDefaultColumn() {
        let app = WritersApp()
        let board = app.createKanbanBoard(name: "Board")

        let task = app.createKanbanTask(boardId: board.id, title: "Task")

        XCTAssertEqual(task.column, .backlog)
        XCTAssertEqual(task.description, "")
    }

    func testKanbanBoardWithEmptyDescription() {
        let app = WritersApp()
        let board = app.createKanbanBoard(name: "Board")

        XCTAssertEqual(board.description, "")
    }

    func testMultipleSessionsForSameUser() throws {
        let tempPath = "/tmp/test_app_db_\(UUID().uuidString).db"
        defer { try? FileManager.default.removeItem(atPath: tempPath) }

        let app = WritersApp(databasePath: tempPath)
        let userId = UUID()

        // Start and end multiple sessions
        for i in 1...5 {
            app.startSession(userId: userId)
            app.updateSessionStats(wordsWritten: i * 100, aiInteractions: i)
            app.endSession()
        }

        let sessions = try app.getUserSessions(userId: userId)
        XCTAssertEqual(sessions.count, 5)
    }

    func testEnableAIWithUserIdSavesConfiguration() throws {
        let tempPath = "/tmp/test_app_db_\(UUID().uuidString).db"
        defer { try? FileManager.default.removeItem(atPath: tempPath) }

        let app = WritersApp(databasePath: tempPath)
        let userId = UUID()

        let config = AIConfiguration(apiKey: "test-key", model: .claude35Sonnet)
        app.enableAI(configuration: config, userId: userId)

        // Verify configuration was saved
        let savedConfig = try app.databaseManager.getAIConfiguration(userId: userId)
        XCTAssertNotNil(savedConfig)
        XCTAssertEqual(savedConfig?.apiKey, "test-key")
    }

    func testEnableAIWithoutUserIdDoesNotSave() throws {
        let tempPath = "/tmp/test_app_db_\(UUID().uuidString).db"
        defer { try? FileManager.default.removeItem(atPath: tempPath) }

        let app = WritersApp(databasePath: tempPath)
        let userId = UUID()

        let config = AIConfiguration(apiKey: "test-key", model: .claude35Sonnet)
        app.enableAI(configuration: config, userId: nil)

        // Verify configuration was NOT saved (no userId provided)
        let savedConfig = try app.databaseManager.getAIConfiguration(userId: userId)
        XCTAssertNil(savedConfig)
    }

    func testDatabaseInitializationFailsGracefully() {
        // Create app with invalid path
        let invalidPath = "/nonexistent/invalid/path.db"
        let app = WritersApp(databasePath: invalidPath)

        // App should still be created, but database operations may fail
        XCTAssertNotNil(app)
    }

    func testTemplateWithEmptyPlaceholders() {
        let template = Template(
            name: "No Placeholders",
            category: .other,
            description: "Template without placeholders",
            content: "Static content only",
            placeholders: []
        )

        let doc = template.createDocument(with: [:])
        XCTAssertEqual(doc.content, "Static content only")
    }

    func testTemplateWithMissingPlaceholderValues() {
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

        // Only provide one value
        let doc = template.createDocument(with: ["name": "John"])
        XCTAssertTrue(doc.content.contains("John"))
        XCTAssertTrue(doc.content.contains("{{age}}")) // Unreplaced placeholder
    }

    func testGetIssuesWithStatusReturnsEmpty() {
        let app = WritersApp()
        let doc = app.createBlankDocument(title: "Test", category: .novel)
        _ = app.createIssue(documentId: doc.id, title: "Open Issue", status: .open)

        let closedIssues = app.getIssues(withStatus: .closed)
        XCTAssertEqual(closedIssues.count, 0)
    }

    func testGetIssuesWithPriority() {
        let app = WritersApp()
        let doc = app.createBlankDocument(title: "Test", category: .novel)

        _ = app.createIssue(documentId: doc.id, title: "High 1", priority: .high)
        _ = app.createIssue(documentId: doc.id, title: "High 2", priority: .high)
        _ = app.createIssue(documentId: doc.id, title: "Low", priority: .low)

        let highIssues = app.getIssues(withPriority: .high)
        XCTAssertEqual(highIssues.count, 2)
        XCTAssertTrue(highIssues.allSatisfy { $0.priority == .high })
    }
}