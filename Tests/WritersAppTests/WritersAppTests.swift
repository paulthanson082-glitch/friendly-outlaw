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

    func testSessionManagementPersistsToDatabase() {
        let tempDir = FileManager.default.temporaryDirectory
        let dbPath = tempDir.appendingPathComponent("test_session_\(UUID().uuidString).db").path
        let testApp = WritersApp(databasePath: dbPath)
        defer {
            try? FileManager.default.removeItem(atPath: dbPath)
        }

        let userId = UUID()
        testApp.startSession(userId: userId, multitaskingMode: "focused")
        testApp.updateSessionStats(wordsWritten: 250, aiInteractions: 5)
        testApp.endSession()

        let sessions = try? testApp.getUserSessions(userId: userId)
        XCTAssertEqual(sessions?.count, 1)
        XCTAssertEqual(sessions?.first?.wordsWritten, 250)
        XCTAssertEqual(sessions?.first?.aiInteractions, 5)
        XCTAssertEqual(sessions?.first?.multitaskingMode, "focused")
        XCTAssertNotNil(sessions?.first?.endTime)
        XCTAssertNotNil(sessions?.first?.durationSeconds)
    }

    func testSessionStatsCalculation() {
        let tempDir = FileManager.default.temporaryDirectory
        let dbPath = tempDir.appendingPathComponent("test_stats_\(UUID().uuidString).db").path
        let testApp = WritersApp(databasePath: dbPath)
        defer {
            try? FileManager.default.removeItem(atPath: dbPath)
        }

        let userId = UUID()

        // Create multiple sessions
        for i in 1...3 {
            testApp.startSession(userId: userId)
            testApp.updateSessionStats(wordsWritten: i * 100, aiInteractions: i)
            testApp.endSession()
            Thread.sleep(forTimeInterval: 0.1) // Small delay to ensure different timestamps
        }

        let stats = try? testApp.getSessionStats(userId: userId)
        XCTAssertNotNil(stats)
        XCTAssertEqual(stats?.totalSessions, 3)
    }

    func testIssueCreationPersistsToDatabase() {
        let tempDir = FileManager.default.temporaryDirectory
        let dbPath = tempDir.appendingPathComponent("test_issues_\(UUID().uuidString).db").path
        let testApp = WritersApp(databasePath: dbPath)
        defer {
            try? FileManager.default.removeItem(atPath: dbPath)
        }

        let doc = testApp.createBlankDocument(title: "Test Doc", category: .novel)
        let issue = testApp.createIssue(
            documentId: doc.id,
            title: "Review character arc",
            description: "Protagonist needs more development",
            status: .open,
            priority: .high
        )

        // Retrieve from database
        let dbIssues = try? testApp.databaseManager.getIssues(forDocument: doc.id)
        XCTAssertEqual(dbIssues?.count, 1)
        XCTAssertEqual(dbIssues?.first?.title, "Review character arc")
        XCTAssertEqual(dbIssues?.first?.priority, .high)
    }

    func testIssueUpdateSyncWithDatabase() {
        let tempDir = FileManager.default.temporaryDirectory
        let dbPath = tempDir.appendingPathComponent("test_issue_update_\(UUID().uuidString).db").path
        let testApp = WritersApp(databasePath: dbPath)
        defer {
            try? FileManager.default.removeItem(atPath: dbPath)
        }

        let doc = testApp.createBlankDocument(title: "Test Doc", category: .blogPost)
        let issue = testApp.createIssue(documentId: doc.id, title: "Initial Title", priority: .low)

        // Update issue status
        testApp.updateIssueStatus(id: issue.id, status: .resolved)

        // Verify in database
        let dbIssues = try? testApp.databaseManager.getIssues(withStatus: .resolved)
        XCTAssertTrue(dbIssues?.contains(where: { $0.id == issue.id }) ?? false)
        XCTAssertNotNil(dbIssues?.first(where: { $0.id == issue.id })?.metadata.resolvedAt)
    }

    func testIssuePriorityUpdatePersists() {
        let tempDir = FileManager.default.temporaryDirectory
        let dbPath = tempDir.appendingPathComponent("test_priority_\(UUID().uuidString).db").path
        let testApp = WritersApp(databasePath: dbPath)
        defer {
            try? FileManager.default.removeItem(atPath: dbPath)
        }

        let doc = testApp.createBlankDocument(title: "Test", category: .article)
        let issue = testApp.createIssue(documentId: doc.id, title: "Priority Test", priority: .low)

        testApp.updateIssuePriority(id: issue.id, priority: .critical)

        let dbIssues = try? testApp.databaseManager.getIssues(forDocument: doc.id)
        XCTAssertEqual(dbIssues?.first?.priority, .critical)
    }

    func testIssueDeleteSyncWithDatabase() {
        let tempDir = FileManager.default.temporaryDirectory
        let dbPath = tempDir.appendingPathComponent("test_delete_\(UUID().uuidString).db").path
        let testApp = WritersApp(databasePath: dbPath)
        defer {
            try? FileManager.default.removeItem(atPath: dbPath)
        }

        let doc = testApp.createBlankDocument(title: "Test", category: .screenplay)
        let issue = testApp.createIssue(documentId: doc.id, title: "To Delete")

        testApp.deleteIssue(id: issue.id)

        let dbIssues = try? testApp.databaseManager.getIssues(forDocument: doc.id)
        XCTAssertEqual(dbIssues?.count, 0)
    }

    func testReopenIssueSyncWithDatabase() {
        let tempDir = FileManager.default.temporaryDirectory
        let dbPath = tempDir.appendingPathComponent("test_reopen_\(UUID().uuidString).db").path
        let testApp = WritersApp(databasePath: dbPath)
        defer {
            try? FileManager.default.removeItem(atPath: dbPath)
        }

        let doc = testApp.createBlankDocument(title: "Test", category: .novel)
        let issue = testApp.createIssue(documentId: doc.id, title: "Reopen Test")

        // Resolve then reopen
        testApp.updateIssueStatus(id: issue.id, status: .resolved)
        testApp.reopenIssue(id: issue.id)

        let dbIssues = try? testApp.databaseManager.getIssues(forDocument: doc.id)
        XCTAssertEqual(dbIssues?.first?.status, .open)
        XCTAssertNil(dbIssues?.first?.metadata.resolvedAt)
    }

    func testDatabaseInitializationWithCustomPath() {
        let tempDir = FileManager.default.temporaryDirectory
        let customPath = tempDir.appendingPathComponent("custom_\(UUID().uuidString).db").path
        let testApp = WritersApp(databasePath: customPath)
        defer {
            try? FileManager.default.removeItem(atPath: customPath)
        }

        // Verify database was created and initialized
        XCTAssertTrue(FileManager.default.fileExists(atPath: customPath))

        // Verify we can perform operations
        let userId = UUID()
        let config = AIConfiguration(apiKey: "test-key")
        XCTAssertNoThrow(try testApp.databaseManager.saveAIConfiguration(userId: userId, configuration: config))
    }

    func testAIConfigurationPersistence() {
        let tempDir = FileManager.default.temporaryDirectory
        let dbPath = tempDir.appendingPathComponent("test_ai_config_\(UUID().uuidString).db").path
        let testApp = WritersApp(databasePath: dbPath)
        defer {
            try? FileManager.default.removeItem(atPath: dbPath)
        }

        let userId = UUID()
        let config = AIConfiguration(
            apiKey: "sk-test-12345",
            model: .claude35Sonnet,
            maxTokens: 8192,
            temperature: 0.8
        )

        testApp.enableAI(configuration: config, userId: userId)

        let retrieved = try? testApp.databaseManager.getAIConfiguration(userId: userId)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.apiKey, "sk-test-12345")
        XCTAssertEqual(retrieved?.model, .claude35Sonnet)
        XCTAssertEqual(retrieved?.maxTokens, 8192)
        XCTAssertEqual(retrieved?.temperature, 0.8)
    }

    func testGetAISuggestionsIntegration() {
        let tempDir = FileManager.default.temporaryDirectory
        let dbPath = tempDir.appendingPathComponent("test_suggestions_\(UUID().uuidString).db").path
        let testApp = WritersApp(databasePath: dbPath)
        defer {
            try? FileManager.default.removeItem(atPath: dbPath)
        }

        let userId = UUID()
        testApp.startSession(userId: userId)

        // Manually insert some suggestions
        let suggestion1 = AISuggestion(userId: userId, toolUsed: "Continue Writing", prompt: "P1", response: "R1")
        let suggestion2 = AISuggestion(userId: userId, toolUsed: "Improve Text", prompt: "P2", response: "R2")

        try? testApp.databaseManager.insertAISuggestion(suggestion1)
        try? testApp.databaseManager.insertAISuggestion(suggestion2)

        let suggestions = try? testApp.getAISuggestions(userId: userId)
        XCTAssertEqual(suggestions?.count, 2)
    }

    func testGetUserSessionsIntegration() {
        let tempDir = FileManager.default.temporaryDirectory
        let dbPath = tempDir.appendingPathComponent("test_get_sessions_\(UUID().uuidString).db").path
        let testApp = WritersApp(databasePath: dbPath)
        defer {
            try? FileManager.default.removeItem(atPath: dbPath)
        }

        let userId = UUID()

        // Create multiple sessions
        for i in 1...3 {
            testApp.startSession(userId: userId)
            testApp.updateSessionStats(wordsWritten: i * 200, aiInteractions: i * 2)
            testApp.endSession()
        }

        let sessions = try? testApp.getUserSessions(userId: userId)
        XCTAssertEqual(sessions?.count, 3)

        let sortedSessions = try? testApp.getUserSessions(userId: userId, sortByDuration: true)
        XCTAssertEqual(sortedSessions?.count, 3)
    }

    func testGetAIToolUsageStatsIntegration() {
        let tempDir = FileManager.default.temporaryDirectory
        let dbPath = tempDir.appendingPathComponent("test_tool_stats_\(UUID().uuidString).db").path
        let testApp = WritersApp(databasePath: dbPath)
        defer {
            try? FileManager.default.removeItem(atPath: dbPath)
        }

        let userId = UUID()

        // Insert some suggestions
        for _ in 1...5 {
            let suggestion = AISuggestion(userId: userId, toolUsed: "Continue Writing", prompt: "P", response: "R")
            try? testApp.databaseManager.insertAISuggestion(suggestion)
        }
        for _ in 1...3 {
            let suggestion = AISuggestion(userId: userId, toolUsed: "Improve Text", prompt: "P", response: "R")
            try? testApp.databaseManager.insertAISuggestion(suggestion)
        }

        let stats = try? testApp.getAIToolUsageStats(userId: userId)
        XCTAssertNotNil(stats)
        XCTAssertEqual(stats?.count, 2)

        let continueWritingStat = stats?.first { $0.toolName == "Continue Writing" }
        XCTAssertEqual(continueWritingStat?.usageCount, 5)
    }

    func testMultipleUsersSessionIsolation() {
        let tempDir = FileManager.default.temporaryDirectory
        let dbPath = tempDir.appendingPathComponent("test_isolation_\(UUID().uuidString).db").path
        let testApp = WritersApp(databasePath: dbPath)
        defer {
            try? FileManager.default.removeItem(atPath: dbPath)
        }

        let user1 = UUID()
        let user2 = UUID()

        // Create sessions for user 1
        testApp.startSession(userId: user1)
        testApp.updateSessionStats(wordsWritten: 100, aiInteractions: 1)
        testApp.endSession()

        // Create sessions for user 2
        testApp.startSession(userId: user2)
        testApp.updateSessionStats(wordsWritten: 200, aiInteractions: 2)
        testApp.endSession()

        let user1Sessions = try? testApp.getUserSessions(userId: user1)
        let user2Sessions = try? testApp.getUserSessions(userId: user2)

        XCTAssertEqual(user1Sessions?.count, 1)
        XCTAssertEqual(user2Sessions?.count, 1)
        XCTAssertEqual(user1Sessions?.first?.wordsWritten, 100)
        XCTAssertEqual(user2Sessions?.first?.wordsWritten, 200)
    }

    func testDatabasePersistenceAcrossAppInstances() {
        let tempDir = FileManager.default.temporaryDirectory
        let dbPath = tempDir.appendingPathComponent("test_persistence_\(UUID().uuidString).db").path
        defer {
            try? FileManager.default.removeItem(atPath: dbPath)
        }

        let userId = UUID()
        let documentId = UUID()

        // First app instance
        do {
            let app1 = WritersApp(databasePath: dbPath)
            let issue = app1.createIssue(
                documentId: documentId,
                title: "Persistent Issue",
                description: "Should survive app restart"
            )
            app1.databaseManager.close()
        }

        // Second app instance
        do {
            let app2 = WritersApp(databasePath: dbPath)
            let issues = app2.getIssues(forDocument: documentId)
            XCTAssertEqual(issues.count, 1)
            XCTAssertEqual(issues.first?.title, "Persistent Issue")
            XCTAssertEqual(issues.first?.description, "Should survive app restart")
        }
    }
}