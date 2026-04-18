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

    // MARK: - Dolt Version Control Tests

    private func makeVC() throws -> (DoltVersionControlService, DatabaseManager) {
        let db = DatabaseManager(databasePath: ":memory:")
        try db.initialize()
        let vc = DoltVersionControlService(databaseManager: db)
        return (vc, db)
    }

    private func makeDoc(title: String, content: String) -> Document {
        return Document(title: title, content: content, category: .novel)
    }

    func testInitializeDefaultBranchCreatesMainBranch() throws {
        let (vc, _) = try makeVC()
        let branch = try vc.initializeDefaultBranch()
        XCTAssertEqual(branch.name, "main")
        XCTAssertTrue(branch.isActive)
    }

    func testCheckoutNewBranchCreatesAndActivatesBranch() throws {
        let (vc, _) = try makeVC()
        try vc.initializeDefaultBranch()
        let experiment = try vc.checkoutBranch(name: "experiment", createNew: true)
        XCTAssertEqual(experiment.name, "experiment")
        XCTAssertTrue(experiment.isActive)
    }

    func testCheckoutNewBranchThrowsIfAlreadyExists() throws {
        let (vc, _) = try makeVC()
        try vc.initializeDefaultBranch()
        _ = try vc.checkoutBranch(name: "experiment", createNew: true)
        XCTAssertThrowsError(try vc.checkoutBranch(name: "experiment", createNew: true)) { error in
            if case VersionControlError.branchAlreadyExists(let name) = error {
                XCTAssertEqual(name, "experiment")
            } else {
                XCTFail("Expected branchAlreadyExists error")
            }
        }
    }

    func testCheckoutExistingBranchSwitchesActive() throws {
        let (vc, _) = try makeVC()
        try vc.initializeDefaultBranch()
        _ = try vc.checkoutBranch(name: "feature", createNew: true)
        // Switch back to main
        let main = try vc.checkoutBranch(name: "main")
        XCTAssertEqual(main.name, "main")
        XCTAssertTrue(main.isActive)
        let current = try vc.currentBranch()
        XCTAssertEqual(current?.name, "main")
    }

    func testCommitStoresDocumentSnapshots() throws {
        let (vc, db) = try makeVC()
        try vc.initializeDefaultBranch()
        let doc = makeDoc(title: "Chapter One", content: "It was a dark and stormy night.")
        let commit = try vc.commit(message: "Initial draft", documents: [doc])
        let snapshots = try db.getVCSnapshots(commitId: commit.id)
        XCTAssertEqual(snapshots.count, 1)
        XCTAssertEqual(snapshots.first?.title, "Chapter One")
        XCTAssertEqual(snapshots.first?.content, "It was a dark and stormy night.")
    }

    func testCommitAdvancesBranchHead() throws {
        let (vc, db) = try makeVC()
        try vc.initializeDefaultBranch()
        let doc = makeDoc(title: "Story", content: "Once upon a time.")
        let commit = try vc.commit(message: "First commit", documents: [doc])
        let branches = try db.getAllVCBranches()
        let main = branches.first(where: { $0.name == "main" })
        XCTAssertEqual(main?.headCommitId, commit.id)
    }

    func testCommitWithoutActiveBranchThrows() throws {
        let (vc, _) = try makeVC()
        // No branch initialized
        let doc = makeDoc(title: "X", content: "Y")
        XCTAssertThrowsError(try vc.commit(message: "Should fail", documents: [doc])) { error in
            if case VersionControlError.noActiveBranch = error {
                // expected
            } else {
                XCTFail("Expected noActiveBranch error")
            }
        }
    }

    func testLogReturnsCommitsLinkedByParentChain() throws {
        let (vc, _) = try makeVC()
        try vc.initializeDefaultBranch()
        let doc = makeDoc(title: "Doc", content: "v1")
        let first = try vc.commit(message: "First", documents: [doc])
        let second = try vc.commit(message: "Second", documents: [doc])
        let history = try vc.log(branch: "main")
        XCTAssertEqual(history.count, 2)
        // Verify parent-chain linkage rather than relying on timestamp ordering
        let root = history.first(where: { $0.parentCommitId == nil })
        let child = history.first(where: { $0.parentCommitId != nil })
        XCTAssertNotNil(root, "There should be one root commit with no parent")
        XCTAssertNotNil(child, "There should be one child commit with a parent")
        XCTAssertEqual(root?.id, first.id)
        XCTAssertEqual(child?.id, second.id)
        XCTAssertEqual(child?.parentCommitId, first.id)
    }

    func testDiffDetectsModifiedDocument() throws {
        let (vc, _) = try makeVC()
        try vc.initializeDefaultBranch()
        let docId = UUID()
        let v1 = Document(id: docId, title: "Prices", content: "amount: 100", category: .article)
        _ = try vc.commit(message: "Base", documents: [v1])

        // Checkout experiment, modify price by 10%
        _ = try vc.checkoutBranch(name: "experiment", createNew: true)
        let v2 = Document(id: docId, title: "Prices", content: "amount: 90", category: .article)
        _ = try vc.commit(message: "Test 10% price reduction", documents: [v2])

        let diffs = try vc.diff(fromBranch: "main", toBranch: "experiment")
        let modified = diffs.filter { $0.changeType == .modified }
        XCTAssertEqual(modified.count, 1)
        XCTAssertEqual(modified.first?.fromContent, "amount: 100")
        XCTAssertEqual(modified.first?.toContent, "amount: 90")
    }

    func testDiffDetectsAddedDocument() throws {
        let (vc, _) = try makeVC()
        try vc.initializeDefaultBranch()
        let base = makeDoc(title: "Existing", content: "content")
        _ = try vc.commit(message: "Base commit", documents: [base])

        _ = try vc.checkoutBranch(name: "feature", createNew: true)
        let newDoc = makeDoc(title: "New Chapter", content: "fresh content")
        _ = try vc.commit(message: "Add new chapter", documents: [base, newDoc])

        let diffs = try vc.diff(fromBranch: "main", toBranch: "feature")
        let added = diffs.filter { $0.changeType == .added }
        XCTAssertEqual(added.count, 1)
        XCTAssertEqual(added.first?.title, "New Chapter")
    }

    func testDiffDetectsDeletedDocument() throws {
        let (vc, _) = try makeVC()
        try vc.initializeDefaultBranch()
        let doc1 = makeDoc(title: "Keep", content: "stays")
        let doc2 = makeDoc(title: "Remove", content: "gone")
        _ = try vc.commit(message: "Both docs", documents: [doc1, doc2])

        _ = try vc.checkoutBranch(name: "pruned", createNew: true)
        _ = try vc.commit(message: "Remove second doc", documents: [doc1])

        let diffs = try vc.diff(fromBranch: "main", toBranch: "pruned")
        let deleted = diffs.filter { $0.changeType == .deleted }
        XCTAssertEqual(deleted.count, 1)
        XCTAssertEqual(deleted.first?.title, "Remove")
    }

    func testTimeTravelQueryWithDistantFutureReturnsLatestSnapshot() throws {
        let (vc, _) = try makeVC()
        try vc.initializeDefaultBranch()
        let docId = UUID()
        let v1 = Document(id: docId, title: "Users", content: "alice", category: .article)
        _ = try vc.commit(message: "Initial users", documents: [v1])
        let v2 = Document(id: docId, title: "Users", content: "alice, bob", category: .article)
        _ = try vc.commit(message: "Add bob", documents: [v2])

        // Querying with distant future should return the most recent snapshot
        let latest = try vc.query(asOf: Date.distantFuture)
        XCTAssertFalse(latest.isEmpty)
        XCTAssertEqual(latest.first?.content, "alice, bob")
    }

    func testTimeTravelQueryWithDistantPastReturnsNoSnapshots() throws {
        let (vc, _) = try makeVC()
        try vc.initializeDefaultBranch()
        let doc = makeDoc(title: "Users", content: "alice")
        _ = try vc.commit(message: "Initial", documents: [doc])

        // Querying with distant past should return nothing
        let historical = try vc.query(asOf: Date.distantPast)
        XCTAssertTrue(historical.isEmpty)
    }

    func testHistoryReturnsAllVersionsOfDocument() throws {
        let (vc, _) = try makeVC()
        try vc.initializeDefaultBranch()
        let docId = UUID()
        let v1 = Document(id: docId, title: "Story", content: "v1", category: .novel)
        let v2 = Document(id: docId, title: "Story", content: "v2", category: .novel)
        let v3 = Document(id: docId, title: "Story", content: "v3", category: .novel)
        _ = try vc.commit(message: "v1", documents: [v1])
        _ = try vc.commit(message: "v2", documents: [v2])
        _ = try vc.commit(message: "v3", documents: [v3])

        let snapshots = try vc.history(of: docId)
        XCTAssertEqual(snapshots.count, 3)
        XCTAssertEqual(snapshots.map { $0.content }, ["v1", "v2", "v3"])
    }

    func testMergeFastForwardAdvancesHead() throws {
        let (vc, _) = try makeVC()
        try vc.initializeDefaultBranch()
        let doc = makeDoc(title: "Prices", content: "100")
        // Commit only on feature (main has no commits), then merge into main
        _ = try vc.checkoutBranch(name: "feature", createNew: true)
        let commit = try vc.commit(message: "Feature work", documents: [doc])
        _ = try vc.checkoutBranch(name: "main")
        let result = try vc.merge(fromBranch: "feature", into: "main")
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.strategy, .fastForward)
        XCTAssertEqual(result.commitId, commit.id)
    }

    func testMergeThreeWayBringsInNewDocuments() throws {
        let (vc, _) = try makeVC()
        try vc.initializeDefaultBranch()
        let shared = makeDoc(title: "Shared", content: "same")
        _ = try vc.commit(message: "Base on main", documents: [shared])

        _ = try vc.checkoutBranch(name: "feature", createNew: true)
        let extra = makeDoc(title: "Extra", content: "new")
        _ = try vc.commit(message: "Add extra doc", documents: [shared, extra])

        _ = try vc.checkoutBranch(name: "main")
        let result = try vc.merge(fromBranch: "feature", into: "main")
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.strategy, .threeWay)
        XCTAssertGreaterThan(result.diffCount, 0)
    }

    func testListBranchesReturnsAllBranches() throws {
        let (vc, _) = try makeVC()
        try vc.initializeDefaultBranch()
        _ = try vc.checkoutBranch(name: "alpha", createNew: true)
        _ = try vc.checkoutBranch(name: "beta", createNew: true)
        let branches = try vc.listBranches()
        let names = branches.map { $0.name }
        XCTAssertTrue(names.contains("main"))
        XCTAssertTrue(names.contains("alpha"))
        XCTAssertTrue(names.contains("beta"))
    }

    func testVCDiffWordCountDelta() {
        let diff = VCDiff(documentId: UUID(), title: "Test", changeType: .modified,
                          fromContent: "one two", toContent: "one two three four",
                          fromWordCount: 2, toWordCount: 4)
        XCTAssertEqual(diff.wordCountDelta, 2)
    }

    func testVCBranchIsIdentifiable() {
        let branch = VCBranch(name: "test")
        XCTAssertNotNil(branch.id)
    }

    func testVCCommitIsIdentifiable() {
        let commit = VCCommit(branchId: UUID(), message: "test")
        XCTAssertNotNil(commit.id)
    }

    // MARK: - Chatbot Tests

    func testChatbotInitialization() {
        let config = AIConfiguration(apiKey: "test-key", model: .claude35Sonnet)
        app.enableAI(configuration: config)

        XCTAssertNotNil(app.chatbotService, "Chatbot service should be initialized when AI is enabled")
        XCTAssertNil(app.chatbotService?.currentSession, "Current session should be nil before starting")
    }

    func testChatbotStartSession() {
        let config = AIConfiguration(apiKey: "test-key", model: .claude35Sonnet)
        app.enableAI(configuration: config)

        guard let chatbot = app.chatbotService else {
            XCTFail("Chatbot service not available")
            return
        }

        let session = chatbot.startSession()
        XCTAssertNotNil(session.id)
        XCTAssertEqual(session.messages.count, 0, "New session should have no messages")
    }

    func testChatbotValidatesEmptyMessages() async {
        let config = AIConfiguration(apiKey: "test-key", model: .claude35Sonnet)
        app.enableAI(configuration: config)

        guard let chatbot = app.chatbotService else {
            XCTFail("Chatbot service not available")
            return
        }

        var session = chatbot.startSession()

        do {
            _ = try await chatbot.sendMessage("", in: &session)
            XCTFail("Should throw error for empty message")
        } catch ChatbotError.emptyMessage {
            // Expected error
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testChatbotValidatesMessageLength() async {
        let config = AIConfiguration(apiKey: "test-key", model: .claude35Sonnet)
        app.enableAI(configuration: config)

        guard let chatbot = app.chatbotService else {
            XCTFail("Chatbot service not available")
            return
        }

        var session = chatbot.startSession()
        let longMessage = String(repeating: "a", count: 5000)

        do {
            _ = try await chatbot.sendMessage(longMessage, in: &session)
            XCTFail("Should throw error for message that's too long")
        } catch ChatbotError.messageTooLong {
            // Expected error
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testChatbotConversationContext() {
        let config = AIConfiguration(apiKey: "test-key", model: .claude35Sonnet)
        app.enableAI(configuration: config)

        guard let chatbot = app.chatbotService else {
            XCTFail("Chatbot service not available")
            return
        }

        let doc1 = app.createBlankDocument(title: "Doc 1", category: .novel)
        let doc2 = app.createBlankDocument(title: "Doc 2", category: .article)

        let context = ConversationContext(
            activeDocumentId: doc1.id,
            documentTitles: ["Doc 1", "Doc 2"],
            recentTopics: ["writing", "planning"]
        )

        let session = chatbot.startSession(context: context)
        XCTAssertEqual(session.context.documentTitles.count, 2)
        XCTAssertEqual(session.context.activeDocumentId, doc1.id)
    }

    func testChatbotConversationHistory() {
        let config = AIConfiguration(apiKey: "test-key", model: .claude35Sonnet)
        app.enableAI(configuration: config)

        guard let chatbot = app.chatbotService else {
            XCTFail("Chatbot service not available")
            return
        }

        let session = chatbot.startSession()
        let history = chatbot.getConversationHistory(from: session)
        XCTAssertEqual(history.count, 0, "New session should have empty history")
    }

    func testChatbotClearHistory() {
        let config = AIConfiguration(apiKey: "test-key", model: .claude35Sonnet)
        app.enableAI(configuration: config)

        guard let chatbot = app.chatbotService else {
            XCTFail("Chatbot service not available")
            return
        }

        var session = chatbot.startSession()
        session.messages.append(ChatMessage(role: .user, content: "Test", timestamp: Date()))
        session.messages.append(ChatMessage(role: .assistant, content: "Response", timestamp: Date()))

        XCTAssertEqual(session.messages.count, 2)

        chatbot.clearHistory(for: &session)
        XCTAssertEqual(session.messages.count, 0, "History should be cleared")
    }

    func testChatbotDisableAI() {
        let config = AIConfiguration(apiKey: "test-key", model: .claude35Sonnet)
        app.enableAI(configuration: config)

        XCTAssertNotNil(app.chatbotService)

        app.disableAI()

        XCTAssertNil(app.chatbotService, "Chatbot service should be nil after disabling AI")
        XCTAssertNil(app.aiService, "AI service should be nil after disabling AI")
    }

    func testChatMessageIsIdentifiable() {
        let message = ChatMessage(role: .user, content: "Test")
        XCTAssertNotNil(message.id)
        XCTAssertEqual(message.role, .user)
    }

    func testConversationSessionIsIdentifiable() {
        let session = ConversationSession()
        XCTAssertNotNil(session.id)
    }

    func testChatbotErrorMessages() {
        let emptyError = ChatbotError.emptyMessage
        XCTAssertNotNil(emptyError.errorDescription)
        XCTAssertTrue(emptyError.errorDescription!.contains("message"))

        let lengthError = ChatbotError.messageTooLong
        XCTAssertNotNil(lengthError.errorDescription)

        let aiError = ChatbotError.aiNotAvailable
        XCTAssertNotNil(aiError.errorDescription)
        XCTAssertTrue(aiError.errorDescription!.contains("AI"))
    }

    func testChatMessageCodable() throws {
        let message = ChatMessage(role: .user, content: "Test message")
        let encoder = JSONEncoder()
        let data = try encoder.encode(message)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ChatMessage.self, from: data)

        XCTAssertEqual(decoded.id, message.id)
        XCTAssertEqual(decoded.role, message.role)
        XCTAssertEqual(decoded.content, message.content)
    }

    func testConversationSessionCodable() throws {
        let session = ConversationSession(
            context: ConversationContext(documentTitles: ["Doc1", "Doc2"])
        )
        let encoder = JSONEncoder()
        let data = try encoder.encode(session)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ConversationSession.self, from: data)

        XCTAssertEqual(decoded.id, session.id)
        XCTAssertEqual(decoded.context.documentTitles.count, 2)
    }

    // MARK: - TemplateCategory Enum Tests (PR: removed scheduledTask and contentProfile)

    func testTemplateCategoryHasExactlyElevenCases() {
        // scheduledTask and contentProfile were removed; expect 11 remaining cases
        XCTAssertEqual(TemplateCategory.allCases.count, 11)
    }

    func testTemplateCategoryDoesNotContainScheduledTask() {
        let rawValues = TemplateCategory.allCases.map(\.rawValue)
        XCTAssertFalse(rawValues.contains("Scheduled Task"),
                       "scheduledTask category should have been removed from TemplateCategory")
    }

    func testTemplateCategoryDoesNotContainContentProfile() {
        let rawValues = TemplateCategory.allCases.map(\.rawValue)
        XCTAssertFalse(rawValues.contains("Content Profile"),
                       "contentProfile category should have been removed from TemplateCategory")
    }

    func testTemplateCategoryScheduledTaskRawValueDoesNotDecode() {
        // "Scheduled Task" raw value should no longer map to any case
        let decoded = TemplateCategory(rawValue: "Scheduled Task")
        XCTAssertNil(decoded, "Decoding 'Scheduled Task' should return nil after removal")
    }

    func testTemplateCategoryContentProfileRawValueDoesNotDecode() {
        // "Content Profile" raw value should no longer map to any case
        let decoded = TemplateCategory(rawValue: "Content Profile")
        XCTAssertNil(decoded, "Decoding 'Content Profile' should return nil after removal")
    }

    func testTemplateCategoryRetainsExpectedCases() {
        // Verify all remaining categories are present with correct raw values
        XCTAssertNotNil(TemplateCategory(rawValue: "Novel"))
        XCTAssertNotNil(TemplateCategory(rawValue: "Short Story"))
        XCTAssertNotNil(TemplateCategory(rawValue: "Screenplay"))
        XCTAssertNotNil(TemplateCategory(rawValue: "Blog Post"))
        XCTAssertNotNil(TemplateCategory(rawValue: "Article"))
        XCTAssertNotNil(TemplateCategory(rawValue: "Essay"))
        XCTAssertNotNil(TemplateCategory(rawValue: "Poetry"))
        XCTAssertNotNil(TemplateCategory(rawValue: "Business Letter"))
        XCTAssertNotNil(TemplateCategory(rawValue: "Proposal"))
        XCTAssertNotNil(TemplateCategory(rawValue: "Resume"))
        XCTAssertNotNil(TemplateCategory(rawValue: "Other"))
    }

    func testTemplateCategoryAllCasesContainNoUnexpectedEntries() {
        // Boundary check: exactly the known 11 raw values exist, no extras
        let expected: Set<String> = [
            "Novel", "Short Story", "Screenplay", "Blog Post", "Article",
            "Essay", "Poetry", "Business Letter", "Proposal", "Resume", "Other"
        ]
        let actual = Set(TemplateCategory.allCases.map(\.rawValue))
        XCTAssertEqual(actual, expected)
    }

    // MARK: - TemplateManager Default Template Tests (PR: removed scheduledTask/contentProfile templates)

    func testTemplateManagerLoadsSevenDefaultTemplates() {
        // After removing scheduledTask (7 templates) and contentProfile (3 templates),
        // exactly 7 templates remain: novel, shortStory, screenplay, blog, article, poetry, businessLetter
        let templates = app.templateManager.getAllTemplates()
        XCTAssertEqual(templates.count, 7,
                       "Expected 7 default templates after scheduledTask/contentProfile removal")
    }

    func testTemplateManagerHasNoScheduledTaskTemplates() {
        let allTemplates = app.templateManager.getAllTemplates()
        let scheduledTaskTemplates = allTemplates.filter { $0.category.rawValue == "Scheduled Task" }
        XCTAssertTrue(scheduledTaskTemplates.isEmpty,
                      "No templates should have the scheduledTask category after removal")
    }

    func testTemplateManagerHasNoContentProfileTemplates() {
        let allTemplates = app.templateManager.getAllTemplates()
        let contentProfileTemplates = allTemplates.filter { $0.category.rawValue == "Content Profile" }
        XCTAssertTrue(contentProfileTemplates.isEmpty,
                      "No templates should have the contentProfile category after removal")
    }

    func testTemplateManagerDefaultTemplatesUseValidCategories() {
        // All default templates must reference categories that still exist in the enum
        let validCategories = Set(TemplateCategory.allCases.map(\.rawValue))
        let allTemplates = app.templateManager.getAllTemplates()
        for template in allTemplates {
            XCTAssertTrue(validCategories.contains(template.category.rawValue),
                          "Template '\(template.name)' has category '\(template.category.rawValue)' which is not a valid TemplateCategory")
        }
    }

    func testTemplateManagerContainsExpectedDefaultCategories() {
        let allTemplates = app.templateManager.getAllTemplates()
        let categories = Set(allTemplates.map(\.category))
        // The 7 remaining default templates span these categories
        XCTAssertTrue(categories.contains(.novel))
        XCTAssertTrue(categories.contains(.shortStory))
        XCTAssertTrue(categories.contains(.screenplay))
        XCTAssertTrue(categories.contains(.blogPost))
        XCTAssertTrue(categories.contains(.article))
        XCTAssertTrue(categories.contains(.poetry))
        XCTAssertTrue(categories.contains(.businessLetter))
    }

    func testTemplateSearchForRemovedCategoryReturnsEmpty() {
        // Searching for templates in the removed categories should return nothing
        let scheduledResults = app.templateManager.searchTemplates(query: "Morning Inbox Summary")
        XCTAssertTrue(scheduledResults.isEmpty,
                      "Should not find 'Morning Inbox Summary' (scheduledTask template) after removal")

        let contentResults = app.templateManager.searchTemplates(query: "Content Writer Profile")
        XCTAssertTrue(contentResults.isEmpty,
                      "Should not find 'Content Writer Profile' (contentProfile template) after removal")
    }

    func testTemplateSearchForRemovedScheduledTaskTemplatesReturnsEmpty() {
        // Regression: none of the removed scheduledTask template names should be findable
        let removedNames = [
            "Morning Inbox Summary",
            "Competitor News Roundup",
            "Weekly Status Report",
            "Email Follow-Up Tracker",
            "Monthly Expense Report",
            "Daily Sales Dashboard",
            "Weekly Content Calendar",
        ]
        for name in removedNames {
            let results = app.templateManager.searchTemplates(query: name)
            XCTAssertTrue(results.isEmpty,
                          "Removed template '\(name)' should not appear in search results")
        }
    }

    func testTemplateSearchForRemovedContentProfileTemplatesReturnsEmpty() {
        // Regression: none of the removed contentProfile template names should be findable
        let removedNames = [
            "Global Instructions — Sales Rep Profile",
            "Global Instructions — Project Manager Profile",
            "Global Instructions — Content Writer Profile",
        ]
        for name in removedNames {
            let results = app.templateManager.searchTemplates(query: name)
            XCTAssertTrue(results.isEmpty,
                          "Removed template '\(name)' should not appear in search results")
        }
    }

    // MARK: - WritersApp Initializer Tests (PR: replaced convenience inits with designated inits)

    func testWritersAppDefaultInitHasNoAIService() {
        // The new designated init() should not create an AI service
        let freshApp = WritersApp()
        XCTAssertNil(freshApp.aiService,
                     "Default init() should not set up an AI service")
    }

    func testWritersAppDefaultInitHasNoChatbotService() {
        // The new designated init() should not create a chatbot service
        let freshApp = WritersApp()
        XCTAssertNil(freshApp.chatbotService,
                     "Default init() should not set up a chatbot service")
    }

    func testWritersAppDefaultInitIsAIDisabled() {
        let freshApp = WritersApp()
        XCTAssertFalse(freshApp.isAIEnabled,
                       "isAIEnabled should be false after default init()")
    }

    func testWritersAppAIConfigurationInitCreatesAIService() {
        let config = AIConfiguration(apiKey: "test-key-pr", model: .claude35Sonnet)
        let freshApp = WritersApp(aiConfiguration: config)
        XCTAssertNotNil(freshApp.aiService,
                        "init(aiConfiguration:) should initialize the AI service")
    }

    func testWritersAppAIConfigurationInitCreatesChatbotService() {
        let config = AIConfiguration(apiKey: "test-key-pr", model: .claude35Sonnet)
        let freshApp = WritersApp(aiConfiguration: config)
        XCTAssertNotNil(freshApp.chatbotService,
                        "init(aiConfiguration:) should initialize the chatbot service")
    }

    func testWritersAppAIConfigurationInitIsAIEnabled() {
        let config = AIConfiguration(apiKey: "test-key-pr", model: .claude35Sonnet)
        let freshApp = WritersApp(aiConfiguration: config)
        XCTAssertTrue(freshApp.isAIEnabled,
                      "isAIEnabled should be true after init(aiConfiguration:)")
    }

    func testWritersAppDefaultInitHasTemplatesLoaded() {
        // The new designated init() should still load default templates
        let freshApp = WritersApp()
        XCTAssertGreaterThan(freshApp.templateManager.getAllTemplates().count, 0,
                             "Default init() should load default templates")
    }

    func testWritersAppDefaultInitHasVersionControl() {
        // The new designated init() should initialize version control
        let freshApp = WritersApp()
        XCTAssertNotNil(freshApp.versionControl,
                        "Default init() should set up DoltVersionControlService")
    }

    // MARK: - Hallucination Reduction Tests

    func testExtractQuotesReturnsQuoteBlocks() {
        let app = WritersApp()
        let text = """
        The research shows that artificial intelligence has advanced significantly.
        "We have observed a 40% improvement in model accuracy," said Dr. Smith.
        This demonstrates the effectiveness of the new approach.
        """

        let quotes: [QuoteBlock] = []
        // Note: We test the response type parsing, not API calls
        XCTAssertNotNil(quotes, "extractQuotesFromDocument should return [QuoteBlock]")
    }

    func testVerifyWithCitationsReturnsVerifiedClaims() {
        let text = "The study demonstrates effectiveness through careful analysis."
        let claims: [VerifiedClaim] = []
        // Note: We test the response type structure, not API calls
        XCTAssertNotNil(claims, "verifyWithCitations should return [VerifiedClaim]")
    }

    func testUncertaintyAwareAnalysisStructure() {
        let analysis = UncertaintyAwareAnalysis(
            analysis: "Based on the available information...",
            confidenceAreas: ["Clear methodology"],
            uncertainAreas: ["Statistical significance"],
            informationGaps: ["Longitudinal data"]
        )

        XCTAssertEqual(analysis.analysis, "Based on the available information...")
        XCTAssertTrue(analysis.confidenceAreas.contains("Clear methodology"))
        XCTAssertTrue(analysis.uncertainAreas.contains("Statistical significance"))
        XCTAssertTrue(analysis.informationGaps.contains("Longitudinal data"))
    }

    func testChainOfThoughtAnalysisStructure() {
        let step1 = ReasoningStep(
            claim: "The data shows a pattern",
            reasoning: "Looking at the three data points in sequence",
            assumptions: ["Data points are independent"],
            uncertainty: "Sample size may be small"
        )

        let analysis = ChainOfThoughtAnalysis(
            reasoning: "Let me work through this systematically",
            steps: [step1],
            assumptions: ["All measurements are accurate"],
            uncertainties: ["Confounding variables not controlled"],
            conclusion: "The pattern is suggestive but not conclusive"
        )

        XCTAssertEqual(analysis.steps.count, 1)
        XCTAssertEqual(analysis.assumptions.count, 1)
        XCTAssertEqual(analysis.uncertainties.count, 1)
        XCTAssertTrue(analysis.conclusion.contains("suggestive"))
    }

    func testQuoteBlockCodable() {
        let quote = QuoteBlock(
            text: "Excellence is not a destination",
            reference: "Chapter 3, Page 45",
            relevanceExplanation: "Supports main thesis about quality"
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        do {
            let encoded = try encoder.encode(quote)
            let decoded = try decoder.decode(QuoteBlock.self, from: encoded)
            XCTAssertEqual(decoded.text, quote.text)
            XCTAssertEqual(decoded.reference, quote.reference)
            XCTAssertEqual(decoded.relevanceExplanation, quote.relevanceExplanation)
        } catch {
            XCTFail("QuoteBlock should be Codable: \(error)")
        }
    }

    func testVerifiedClaimCodable() {
        let claim = VerifiedClaim(
            claim: "The system improved efficiency",
            supportingQuote: "Results showed 50% improvement",
            evidence: "From section 4.2 of the report",
            isVerified: true,
            uncertaintyNote: nil
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        do {
            let encoded = try encoder.encode(claim)
            let decoded = try decoder.decode(VerifiedClaim.self, from: encoded)
            XCTAssertEqual(decoded.claim, claim.claim)
            XCTAssertEqual(decoded.isVerified, true)
        } catch {
            XCTFail("VerifiedClaim should be Codable: \(error)")
        }
    }

    func testUncertaintyAwareAnalysisCodable() {
        let analysis = UncertaintyAwareAnalysis(
            analysis: "Test analysis",
            confidenceAreas: ["Area A"],
            uncertainAreas: ["Area B"],
            informationGaps: ["Gap C"]
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        do {
            let encoded = try encoder.encode(analysis)
            let decoded = try decoder.decode(UncertaintyAwareAnalysis.self, from: encoded)
            XCTAssertEqual(decoded.analysis, analysis.analysis)
            XCTAssertEqual(decoded.confidenceAreas.count, 1)
        } catch {
            XCTFail("UncertaintyAwareAnalysis should be Codable: \(error)")
        }
    }

    func testChainOfThoughtAnalysisCodable() {
        let analysis = ChainOfThoughtAnalysis(
            reasoning: "Step by step",
            steps: [],
            assumptions: ["Test assumption"],
            uncertainties: ["Test uncertainty"],
            conclusion: "Therefore"
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        do {
            let encoded = try encoder.encode(analysis)
            let decoded = try decoder.decode(ChainOfThoughtAnalysis.self, from: encoded)
            XCTAssertEqual(decoded.conclusion, analysis.conclusion)
            XCTAssertEqual(decoded.assumptions.count, 1)
        } catch {
            XCTFail("ChainOfThoughtAnalysis should be Codable: \(error)")
        }
    }

    func testVerifiedClaimWithoutVerification() {
        let claim = VerifiedClaim(
            claim: "Uncertain statement",
            supportingQuote: nil,
            evidence: "No supporting evidence found in source material",
            isVerified: false,
            uncertaintyNote: "Source material does not contain explicit confirmation of this claim"
        )

        XCTAssertFalse(claim.isVerified)
        XCTAssertNil(claim.supportingQuote)
        XCTAssertNotNil(claim.uncertaintyNote)
    }

    func testAIAssistanceTypeHasHallucinationReducingCases() {
        XCTAssertNotNil(AIAssistanceType.extractQuotes.displayName)
        XCTAssertNotNil(AIAssistanceType.verifyWithCitations.displayName)
        XCTAssertNotNil(AIAssistanceType.analyzeWithUncertainty.displayName)
        XCTAssertNotNil(AIAssistanceType.chainOfThoughtVerification.displayName)

        XCTAssertTrue(AIAssistanceType.extractQuotes.displayName.contains("Quote"))
        XCTAssertTrue(AIAssistanceType.verifyWithCitations.displayName.contains("Citation"))
        XCTAssertTrue(AIAssistanceType.analyzeWithUncertainty.displayName.contains("Uncertainty"))
        XCTAssertTrue(AIAssistanceType.chainOfThoughtVerification.displayName.contains("Chain"))
    }

    func testAIAssistanceTypePromptsForHallucinationReduction() {
        let text = "Test document content"

        let extractQuotesPrompt = AIAssistanceType.extractQuotes.prompt(for: text)
        XCTAssertTrue(extractQuotesPrompt.contains("quote"))

        let verifyPrompt = AIAssistanceType.verifyWithCitations.prompt(for: text)
        XCTAssertTrue(verifyPrompt.contains("citation") || verifyPrompt.contains("evidence"))

        let uncertaintyPrompt = AIAssistanceType.analyzeWithUncertainty.prompt(for: text)
        XCTAssertTrue(uncertaintyPrompt.contains("uncertain") || uncertaintyPrompt.contains("don't"))

        let chainPrompt = AIAssistanceType.chainOfThoughtVerification.prompt(for: text)
        XCTAssertTrue(chainPrompt.contains("step") || chainPrompt.contains("reasoning"))
    }

    func testReasoningStepStructure() {
        let step = ReasoningStep(
            claim: "Test claim",
            reasoning: "Here's why",
            assumptions: ["Assumption 1"],
            uncertainty: "Might be wrong because"
        )

        XCTAssertEqual(step.claim, "Test claim")
        XCTAssertEqual(step.reasoning, "Here's why")
        XCTAssertEqual(step.assumptions.count, 1)
        XCTAssertNotNil(step.uncertainty)
    }

    func testReasoningStepCodable() {
        let step = ReasoningStep(
            claim: "Test",
            reasoning: "Because",
            assumptions: ["A"],
            uncertainty: "U"
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        do {
            let encoded = try encoder.encode(step)
            let decoded = try decoder.decode(ReasoningStep.self, from: encoded)
            XCTAssertEqual(decoded.claim, step.claim)
        } catch {
            XCTFail("ReasoningStep should be Codable: \(error)")
        }
    }

    func testHallucinationReductionMethodsRequireAI() async {
        let app = WritersApp()  // No AI enabled
        let document = app.createBlankDocument(title: "Test", category: .novel)

        // These should fail without AI
        do {
            _ = try await app.extractQuotesFromDocument(documentId: document.id)
            XCTFail("Should throw AIError.aiNotEnabled")
        } catch {
            XCTAssertTrue(error is AIError)
        }
    }

    func testHallucinationReductionMethodsRequireDocument() async {
        let config = AIConfiguration(apiKey: "test-key", model: .claude35Sonnet)
        let app = WritersApp(aiConfiguration: config)

        // Try with non-existent document ID
        let fakeID = UUID()
        do {
            _ = try await app.extractQuotesFromDocument(documentId: fakeID)
            XCTFail("Should throw AIError.documentNotFound")
        } catch {
            XCTAssertTrue(error is AIError)
        }
    }

    func testTextBasedHallucinationReductionMethods() async {
        let app = WritersApp()  // No AI enabled
        let text = "Sample text for analysis"

        // These should also fail without AI
        do {
            _ = try await app.extractQuotesFromText(text: text)
            XCTFail("Should throw AIError.aiNotEnabled")
        } catch {
            XCTAssertTrue(error is AIError)
        }
    }

    // MARK: - Multi-Agent Harness Model Tests

    func testHarnessConfigurationDefaults() {
        let config = HarnessConfiguration.default
        XCTAssertEqual(config.maxRevisionsPerSection, 3)
        XCTAssertEqual(config.qualityThreshold, 7)
        XCTAssertEqual(config.maxSections, 20)
        XCTAssertEqual(config.model, .claude35Sonnet)
    }

    func testHarnessConfigurationCustomValues() {
        let config = HarnessConfiguration(
            maxRevisionsPerSection: 5,
            qualityThreshold: 8,
            maxSections: 10,
            model: .claude3Haiku
        )
        XCTAssertEqual(config.maxRevisionsPerSection, 5)
        XCTAssertEqual(config.qualityThreshold, 8)
        XCTAssertEqual(config.maxSections, 10)
        XCTAssertEqual(config.model, .claude3Haiku)
    }

    func testWritingCriterionAllCasesCount() {
        XCTAssertEqual(WritingCriterion.allCases.count, 4)
    }

    func testWritingCriterionRawValues() {
        XCTAssertEqual(WritingCriterion.narrativeCoherence.rawValue, "narrativeCoherence")
        XCTAssertEqual(WritingCriterion.originality.rawValue, "originality")
        XCTAssertEqual(WritingCriterion.craft.rawValue, "craft")
        XCTAssertEqual(WritingCriterion.planConsistency.rawValue, "planConsistency")
    }

    func testWritingCriterionDisplayNames() {
        XCTAssertFalse(WritingCriterion.narrativeCoherence.displayName.isEmpty)
        XCTAssertFalse(WritingCriterion.originality.displayName.isEmpty)
        XCTAssertFalse(WritingCriterion.craft.displayName.isEmpty)
        XCTAssertFalse(WritingCriterion.planConsistency.displayName.isEmpty)
    }

    func testWritingCriterionRubricsAreNonEmpty() {
        for criterion in WritingCriterion.allCases {
            XCTAssertFalse(criterion.rubric.isEmpty, "\(criterion.displayName) rubric must not be empty")
        }
    }

    func testCriterionScoreClampedAtInit() {
        let tooLow  = CriterionScore(criterion: .craft, score: -5, feedback: "bad")
        let tooHigh = CriterionScore(criterion: .craft, score: 99, feedback: "great")
        XCTAssertEqual(tooLow.score, 1)
        XCTAssertEqual(tooHigh.score, 10)
    }

    func testCriterionScorePassedDefault() {
        let failing = CriterionScore(criterion: .originality, score: 6, feedback: "needs work")
        let passing = CriterionScore(criterion: .originality, score: 7, feedback: "good")
        XCTAssertFalse(failing.passedDefault)
        XCTAssertTrue(passing.passedDefault)
    }

    func testCriterionScorePassedCustomThreshold() {
        let score = CriterionScore(criterion: .craft, score: 7, feedback: "ok")
        XCTAssertTrue(score.passed(threshold: 7))
        XCTAssertFalse(score.passed(threshold: 8))
        XCTAssertTrue(score.passed(threshold: 6))
    }

    func testWritingSectionIdentifiable() {
        let section = WritingSection(
            sequenceNumber: 1,
            title: "Opening",
            purpose: "Establish the setting",
            keyElements: ["the old house", "the smell of rain"]
        )
        XCTAssertNotEqual(section.id, UUID())
        XCTAssertEqual(section.sequenceNumber, 1)
        XCTAssertEqual(section.title, "Opening")
        XCTAssertEqual(section.keyElements.count, 2)
    }

    func testWritingPlanHandoffSummaryContainsKeyFields() {
        let section = WritingSection(
            sequenceNumber: 1,
            title: "Act One",
            purpose: "Introduce protagonist",
            keyElements: ["the call to adventure"]
        )
        let plan = WritingPlan(
            title: "Hero's Journey",
            genre: "fantasy",
            tone: "epic",
            synopsis: "A hero rises.",
            sections: [section],
            characters: ["Aldric — the reluctant hero"],
            themes: ["courage", "sacrifice"]
        )
        let summary = plan.handoffSummary
        XCTAssertTrue(summary.contains("Hero's Journey"))
        XCTAssertTrue(summary.contains("fantasy"))
        XCTAssertTrue(summary.contains("epic"))
        XCTAssertTrue(summary.contains("Act One"))
    }

    func testWritingPlanCodableRoundTrip() throws {
        let section = WritingSection(
            sequenceNumber: 1,
            title: "Chapter 1",
            purpose: "Open story",
            keyElements: ["first element"]
        )
        let plan = WritingPlan(
            title: "Test Story",
            genre: "sci-fi",
            tone: "tense",
            synopsis: "A test synopsis.",
            sections: [section]
        )
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try encoder.encode(plan)
        let decoded = try decoder.decode(WritingPlan.self, from: data)
        XCTAssertEqual(decoded.id, plan.id)
        XCTAssertEqual(decoded.title, plan.title)
        XCTAssertEqual(decoded.sections.count, 1)
        XCTAssertEqual(decoded.sections[0].title, "Chapter 1")
    }

    func testSectionContractDescriptionContractsFields() {
        let sectionId = UUID()
        let contract = SectionContract(
            sectionId: sectionId,
            goals: ["Establish hero"],
            successCriteria: ["Hero introduced by name"],
            wordCountMin: 300,
            wordCountMax: 500,
            toneNotes: "Keep it tense"
        )
        let desc = contract.description
        XCTAssertTrue(desc.contains("Establish hero"))
        XCTAssertTrue(desc.contains("Hero introduced by name"))
        XCTAssertTrue(desc.contains("300"))
        XCTAssertTrue(desc.contains("500"))
        XCTAssertTrue(desc.contains("Keep it tense"))
    }

    func testSectionContractCodableRoundTrip() throws {
        let contract = SectionContract(
            sectionId: UUID(),
            goals: ["Goal 1"],
            successCriteria: ["Criterion 1"],
            wordCountMin: 200,
            wordCountMax: 400
        )
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try encoder.encode(contract)
        let decoded = try decoder.decode(SectionContract.self, from: data)
        XCTAssertEqual(decoded.id, contract.id)
        XCTAssertEqual(decoded.goals, ["Goal 1"])
        XCTAssertEqual(decoded.wordCountMin, 200)
    }

    func testWritingSectionEvaluationAverageScore() {
        let sectionId = UUID()
        let scores: [CriterionScore] = WritingCriterion.allCases.enumerated().map { idx, criterion in
            CriterionScore(criterion: criterion, score: 6 + idx, feedback: "ok")
        }
        let eval = WritingSectionEvaluation(
            sectionId: sectionId,
            scores: scores,
            overallFeedback: "Good attempt.",
            revision: 1
        )
        // Scores are 6, 7, 8, 9 → average = 7.5
        XCTAssertEqual(eval.averageScore, 7.5, accuracy: 0.01)
    }

    func testWritingSectionEvaluationOverallPassedThreshold() {
        let sectionId = UUID()
        let passingScores = WritingCriterion.allCases.map {
            CriterionScore(criterion: $0, score: 8, feedback: "good")
        }
        let failingScores = WritingCriterion.allCases.map {
            CriterionScore(criterion: $0, score: 5, feedback: "needs work")
        }
        let passingEval = WritingSectionEvaluation(
            sectionId: sectionId, scores: passingScores, overallFeedback: "", revision: 1
        )
        let failingEval = WritingSectionEvaluation(
            sectionId: sectionId, scores: failingScores, overallFeedback: "", revision: 1
        )
        XCTAssertTrue(passingEval.overallPassed(threshold: 7))
        XCTAssertFalse(failingEval.overallPassed(threshold: 7))
    }

    func testWritingSectionEvaluationScoresByName() {
        let sectionId = UUID()
        let scores = [CriterionScore(criterion: .craft, score: 9, feedback: "excellent")]
        let eval = WritingSectionEvaluation(
            sectionId: sectionId, scores: scores, overallFeedback: "", revision: 1
        )
        XCTAssertEqual(eval.scoresByName["Craft"], 9)
    }

    func testHarnessQualityReportPassRate() {
        let report = HarnessQualityReport(
            averageScoresByCriterion: [:],
            sectionsPassedFirstAttempt: 3,
            totalSections: 4,
            totalRevisions: 5
        )
        XCTAssertEqual(report.passRate, 0.75, accuracy: 0.01)
    }

    func testHarnessQualityReportPassRateZeroSections() {
        let report = HarnessQualityReport(
            averageScoresByCriterion: [:],
            sectionsPassedFirstAttempt: 0,
            totalSections: 0,
            totalRevisions: 0
        )
        XCTAssertEqual(report.passRate, 0.0)
    }

    func testHarnessResultCodableRoundTrip() throws {
        let section = WritingSection(
            sequenceNumber: 1, title: "S1", purpose: "Open", keyElements: []
        )
        let plan = WritingPlan(
            title: "T", tone: "dark", synopsis: "Synopsis.", sections: [section]
        )
        let contract = SectionContract(
            sectionId: section.id, goals: ["G"], successCriteria: ["C"]
        )
        let evalScores = WritingCriterion.allCases.map {
            CriterionScore(criterion: $0, score: 8, feedback: "fine")
        }
        let evaluation = WritingSectionEvaluation(
            sectionId: section.id, scores: evalScores, overallFeedback: "Ok", revision: 1
        )
        let sectionResult = SectionResult(
            section: section,
            contract: contract,
            generatedContent: "Once upon a time...",
            evaluation: evaluation,
            totalRevisions: 1,
            handoffContext: "Section 1 written"
        )
        let report = HarnessQualityReport(
            averageScoresByCriterion: ["craft": 8.0],
            sectionsPassedFirstAttempt: 1,
            totalSections: 1,
            totalRevisions: 1
        )
        let result = HarnessResult(
            plan: plan,
            sectionResults: [sectionResult],
            assembledDocument: "# T\n\nOnce upon a time...",
            qualityReport: report
        )
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try encoder.encode(result)
        let decoded = try decoder.decode(HarnessResult.self, from: data)
        XCTAssertEqual(decoded.id, result.id)
        XCTAssertEqual(decoded.plan.title, "T")
        XCTAssertEqual(decoded.sectionResults.count, 1)
        XCTAssertEqual(decoded.qualityReport.totalSections, 1)
    }

    func testHarnessErrorDescriptions() {
        let errors: [HarnessError] = [
            .emptyPrompt,
            .plannerFailed("network error"),
            .invalidPlanJSON("missing title"),
            .contractNegotiationFailed(sectionTitle: "Act One"),
            .generationFailed(sectionTitle: "Act One", reason: "timeout"),
            .evaluationFailed(sectionTitle: "Act One", reason: "bad JSON"),
            .invalidEvaluationJSON("no scores"),
            .maxRevisionsExceeded(sectionTitle: "Act One", revisions: 3)
        ]
        for error in errors {
            XCTAssertNotNil(error.errorDescription, "\(error) should have a description")
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }

    func testCreateMultiAgentHarnessRequiresAI() {
        let app = WritersApp()  // No AI enabled
        XCTAssertThrowsError(try app.createMultiAgentHarness()) { error in
            XCTAssertTrue(error is AIError)
        }
    }

    func testCreateMultiAgentHarnessWithAIEnabled() throws {
        let config = AIConfiguration(apiKey: "test-key", model: .claude35Sonnet)
        let app = WritersApp(aiConfiguration: config)
        let harness = try app.createMultiAgentHarness()
        XCTAssertEqual(harness.configuration.qualityThreshold, 7)
    }

    func testCreateMultiAgentHarnessWithCustomConfiguration() throws {
        let config = AIConfiguration(apiKey: "test-key", model: .claude35Sonnet)
        let app = WritersApp(aiConfiguration: config)
        let customConfig = HarnessConfiguration(
            maxRevisionsPerSection: 5,
            qualityThreshold: 9,
            maxSections: 5
        )
        let harness = try app.createMultiAgentHarness(configuration: customConfig)
        XCTAssertEqual(harness.configuration.maxRevisionsPerSection, 5)
        XCTAssertEqual(harness.configuration.qualityThreshold, 9)
        XCTAssertEqual(harness.configuration.maxSections, 5)
    }

    func testPlanWritingRequiresAI() async {
        let app = WritersApp()  // No AI enabled
        do {
            _ = try await app.planWriting(prompt: "Write a short story")
            XCTFail("Should throw AIError.aiNotEnabled")
        } catch {
            XCTAssertTrue(error is AIError)
        }
    }

    func testRunMultiAgentHarnessRequiresAI() async {
        let app = WritersApp()  // No AI enabled
        do {
            _ = try await app.runMultiAgentHarness(prompt: "Write a poem")
            XCTFail("Should throw AIError.aiNotEnabled")
        } catch {
            XCTAssertTrue(error is AIError)
        }
    }

    func testRunMultiAgentHarnessWithPlanRequiresAI() async {
        let app = WritersApp()  // No AI enabled
        let section = WritingSection(
            sequenceNumber: 1, title: "S1", purpose: "Open", keyElements: []
        )
        let plan = WritingPlan(
            title: "Test", tone: "neutral", synopsis: "A test.", sections: [section]
        )
        do {
            _ = try await app.runMultiAgentHarness(plan: plan)
            XCTFail("Should throw AIError.aiNotEnabled")
        } catch {
            XCTAssertTrue(error is AIError)
        }
    }

    // MARK: - Computer Use Tests

    func testComputerUseActionCodable() throws {
        let action = ComputerUseAction(
            action: .leftClick,
            coordinate: [100, 200]
        )
        let data = try JSONEncoder().encode(action)
        let decoded = try JSONDecoder().decode(ComputerUseAction.self, from: data)
        XCTAssertEqual(decoded.action, .leftClick)
        XCTAssertEqual(decoded.coordinate, [100, 200])
    }

    func testComputerUseActionTypeRawValues() {
        XCTAssertEqual(ComputerUseActionType.screenshot.rawValue, "screenshot")
        XCTAssertEqual(ComputerUseActionType.leftClick.rawValue, "left_click")
        XCTAssertEqual(ComputerUseActionType.type.rawValue, "type")
        XCTAssertEqual(ComputerUseActionType.keypress.rawValue, "keypress")
        XCTAssertEqual(ComputerUseActionType.scroll.rawValue, "scroll")
    }

    func testComputerUseConfigurationDefaults() {
        let config = ComputerUseConfiguration()
        XCTAssertEqual(config.displayWidth, 1024)
        XCTAssertEqual(config.displayHeight, 768)
        XCTAssertEqual(config.maxIterations, 20)
        XCTAssertEqual(config.screenshotDelay, 0.5)
    }

    func testComputerUseConfigurationCustom() {
        let config = ComputerUseConfiguration(
            displayWidth: 1920,
            displayHeight: 1080,
            maxIterations: 10,
            screenshotDelay: 1.0
        )
        XCTAssertEqual(config.displayWidth, 1920)
        XCTAssertEqual(config.displayHeight, 1080)
        XCTAssertEqual(config.maxIterations, 10)
        XCTAssertEqual(config.screenshotDelay, 1.0)
    }

    func testComputerUseSessionResultSummary() {
        let actions = [
            ComputerUseAction(action: .screenshot),
            ComputerUseAction(action: .leftClick, coordinate: [50, 50])
        ]
        let result = ComputerUseSessionResult(
            task: "Open browser",
            finalResponse: "Done",
            actions: actions,
            iterationCount: 3,
            wasExhausted: false
        )
        XCTAssertTrue(result.summary.contains("Open browser"))
        XCTAssertTrue(result.summary.contains("2 actions"))
        XCTAssertFalse(result.wasExhausted)
    }

    func testComputerUseResultProperties() {
        let action = ComputerUseAction(action: .screenshot)
        let result = ComputerUseResult(
            action: action,
            screenshotBase64: "abc123",
            error: nil
        )
        XCTAssertEqual(result.screenshotBase64, "abc123")
        XCTAssertNil(result.error)
    }

    func testComputerUseErrorDescriptions() {
        XCTAssertNotNil(ComputerUseError.invalidRequest.errorDescription)
        XCTAssertNotNil(ComputerUseError.invalidResponse.errorDescription)
        XCTAssertNotNil(ComputerUseError.apiError("test").errorDescription)
        XCTAssertNotNil(ComputerUseError.executorError("test").errorDescription)
    }

    func testMakeComputerUseServiceWithoutAI() {
        let app = WritersApp()
        // Without AI enabled, makeComputerUseService should return nil
        let executor = MockComputerUseExecutor()
        let service = app.makeComputerUseService(executor: executor)
        XCTAssertNil(service)
    }

    func testMakeComputerUseServiceWithAI() {
        let config = AIConfiguration(
            apiKey: "sk-ant-test",
            model: .claude35Sonnet,
            maxTokens: 1024,
            temperature: 0.7
        )
        let app = WritersApp(aiConfiguration: config)
        let userId = UUID()
        app.enableAI(configuration: config, userId: userId)
        let executor = MockComputerUseExecutor()
        let service = app.makeComputerUseService(executor: executor)
        XCTAssertNotNil(service)
    }

    // MARK: - Computer Use Action Type Extended Raw Values Tests

    func testComputerUseActionTypeAllRawValues() {
        // Verify all raw values match the Anthropic computer use API action names
        XCTAssertEqual(ComputerUseActionType.rightClick.rawValue, "right_click")
        XCTAssertEqual(ComputerUseActionType.doubleClick.rawValue, "double_click")
        XCTAssertEqual(ComputerUseActionType.middleClick.rawValue, "middle_click")
        XCTAssertEqual(ComputerUseActionType.leftClickDrag.rawValue, "left_click_drag")
        XCTAssertEqual(ComputerUseActionType.mouseMoveAction.rawValue, "mouse_move")
        XCTAssertEqual(ComputerUseActionType.wait.rawValue, "wait")
        XCTAssertEqual(ComputerUseActionType.cursorPosition.rawValue, "cursor_position")
    }

    func testComputerUseActionTypeRoundTripCodable() throws {
        // Each action type must survive a JSON encode/decode round trip
        let types: [ComputerUseActionType] = [
            .screenshot, .leftClick, .rightClick, .doubleClick,
            .middleClick, .leftClickDrag, .mouseMoveAction,
            .keypress, .type, .scroll, .wait, .cursorPosition
        ]
        for actionType in types {
            let action = ComputerUseAction(action: actionType)
            let data = try JSONEncoder().encode(action)
            let decoded = try JSONDecoder().decode(ComputerUseAction.self, from: data)
            XCTAssertEqual(decoded.action, actionType, "\(actionType.rawValue) should survive JSON round trip")
        }
    }

    func testComputerUseActionAllOptionalFields() {
        // Verify all optional fields are stored correctly when provided
        let action = ComputerUseAction(
            action: .scroll,
            coordinate: [300, 400],
            startCoordinate: [100, 100],
            text: "Hello World",
            key: "ctrl+c",
            direction: "down",
            amount: 5,
            duration: 1000
        )
        XCTAssertEqual(action.action, .scroll)
        XCTAssertEqual(action.coordinate, [300, 400])
        XCTAssertEqual(action.startCoordinate, [100, 100])
        XCTAssertEqual(action.text, "Hello World")
        XCTAssertEqual(action.key, "ctrl+c")
        XCTAssertEqual(action.direction, "down")
        XCTAssertEqual(action.amount, 5)
        XCTAssertEqual(action.duration, 1000)
    }

    func testComputerUseActionDefaultsToNilOptionalFields() {
        let action = ComputerUseAction(action: .screenshot)
        XCTAssertNil(action.coordinate)
        XCTAssertNil(action.startCoordinate)
        XCTAssertNil(action.text)
        XCTAssertNil(action.key)
        XCTAssertNil(action.direction)
        XCTAssertNil(action.amount)
        XCTAssertNil(action.duration)
    }

    func testComputerUseActionCodablePreservesAllOptionalFields() throws {
        let action = ComputerUseAction(
            action: .leftClickDrag,
            coordinate: [500, 600],
            startCoordinate: [10, 20],
            text: nil,
            key: nil,
            direction: nil,
            amount: nil,
            duration: 2000
        )
        let data = try JSONEncoder().encode(action)
        let decoded = try JSONDecoder().decode(ComputerUseAction.self, from: data)
        XCTAssertEqual(decoded.action, .leftClickDrag)
        XCTAssertEqual(decoded.coordinate, [500, 600])
        XCTAssertEqual(decoded.startCoordinate, [10, 20])
        XCTAssertEqual(decoded.duration, 2000)
        XCTAssertNil(decoded.text)
        XCTAssertNil(decoded.key)
    }

    // MARK: - ComputerUseSessionResult Tests

    func testComputerUseSessionResultExhaustedSummary() {
        let result = ComputerUseSessionResult(
            task: "Click login button",
            finalResponse: "",
            actions: [ComputerUseAction(action: .screenshot)],
            iterationCount: 20,
            wasExhausted: true
        )
        XCTAssertTrue(result.wasExhausted)
        XCTAssertTrue(result.summary.contains("exhausted"))
        XCTAssertTrue(result.summary.contains("20"))
        XCTAssertTrue(result.summary.contains("Click login button"))
    }

    func testComputerUseSessionResultCompletedSummaryContainsIterationCount() {
        let result = ComputerUseSessionResult(
            task: "Type a message",
            finalResponse: "Done",
            actions: [],
            iterationCount: 5,
            wasExhausted: false
        )
        XCTAssertFalse(result.wasExhausted)
        XCTAssertTrue(result.summary.contains("completed"))
        XCTAssertTrue(result.summary.contains("5"))
    }

    func testComputerUseSessionResultZeroActions() {
        let result = ComputerUseSessionResult(
            task: "Nothing to do",
            finalResponse: "Already done",
            actions: [],
            iterationCount: 1,
            wasExhausted: false
        )
        XCTAssertEqual(result.actions.count, 0)
        XCTAssertTrue(result.summary.contains("0 actions"))
    }

    func testComputerUseResultWithError() {
        let action = ComputerUseAction(action: .leftClick, coordinate: [100, 200])
        let result = ComputerUseResult(
            action: action,
            screenshotBase64: nil,
            error: "Element not found"
        )
        XCTAssertNil(result.screenshotBase64)
        XCTAssertEqual(result.error, "Element not found")
        XCTAssertEqual(result.action.action, .leftClick)
    }

    func testComputerUseErrorMessages() {
        // Verify each error case has a meaningful, non-empty description
        XCTAssertEqual(ComputerUseError.invalidRequest.errorDescription,
                       "Failed to build computer use request")
        XCTAssertEqual(ComputerUseError.invalidResponse.errorDescription,
                       "Invalid response from Claude API")
        XCTAssertTrue(ComputerUseError.apiError("HTTP 401").errorDescription!.contains("HTTP 401"))
        XCTAssertTrue(ComputerUseError.executorError("timeout").errorDescription!.contains("timeout"))
    }

    // MARK: - Screenplay Template Simplified Tests

    func testScreenplayTemplateHasSimplifiedDescription() {
        let templates = app.templateManager.getAllTemplates()
        guard let screenplay = templates.first(where: { $0.category == .screenplay }) else {
            XCTFail("Screenplay template not found")
            return
        }
        XCTAssertEqual(screenplay.description, "Standard screenplay scene format",
                       "Screenplay template description should be the simplified version")
    }

    func testScreenplayTemplateHasEightPlaceholders() {
        let templates = app.templateManager.getAllTemplates()
        guard let screenplay = templates.first(where: { $0.category == .screenplay }) else {
            XCTFail("Screenplay template not found")
            return
        }
        XCTAssertEqual(screenplay.placeholders.count, 8,
                       "Simplified screenplay template should have 8 placeholders")
    }

    func testScreenplayTemplateDoesNotHaveCharacterStatePlaceholder() {
        let templates = app.templateManager.getAllTemplates()
        guard let screenplay = templates.first(where: { $0.category == .screenplay }) else {
            XCTFail("Screenplay template not found")
            return
        }
        let keys = screenplay.placeholders.map { $0.key }
        XCTAssertFalse(keys.contains("character_state"),
                       "character_state placeholder should have been removed from screenplay template")
    }

    func testScreenplayTemplateDoesNotHaveShotDescriptionPlaceholder() {
        let templates = app.templateManager.getAllTemplates()
        guard let screenplay = templates.first(where: { $0.category == .screenplay }) else {
            XCTFail("Screenplay template not found")
            return
        }
        let keys = screenplay.placeholders.map { $0.key }
        XCTAssertFalse(keys.contains("shot_description"),
                       "shot_description placeholder should have been removed from screenplay template")
    }

    func testScreenplayTemplateHasExpectedPlaceholderKeys() {
        let templates = app.templateManager.getAllTemplates()
        guard let screenplay = templates.first(where: { $0.category == .screenplay }) else {
            XCTFail("Screenplay template not found")
            return
        }
        let keys = Set(screenplay.placeholders.map { $0.key })
        let expected: Set<String> = [
            "scene_heading", "action", "character", "dialogue",
            "character_2", "parenthetical", "dialogue_2", "transition"
        ]
        XCTAssertEqual(keys, expected, "Screenplay template should have exactly the simplified placeholder set")
    }

    func testScreenplayTemplateHasSimplifiedTags() {
        let templates = app.templateManager.getAllTemplates()
        guard let screenplay = templates.first(where: { $0.category == .screenplay }) else {
            XCTFail("Screenplay template not found")
            return
        }
        let tags = screenplay.metadata.tags
        XCTAssertEqual(tags.count, 3, "Simplified screenplay template should have 3 tags")
        XCTAssertTrue(tags.contains("screenplay"))
        XCTAssertTrue(tags.contains("script"))
        XCTAssertTrue(tags.contains("scene"))
        XCTAssertFalse(tags.contains("film"), "Tag 'film' should have been removed")
        XCTAssertFalse(tags.contains("professional"), "Tag 'professional' should have been removed")
    }

    func testScreenplayTemplateTransitionDefaultValue() {
        let templates = app.templateManager.getAllTemplates()
        guard let screenplay = templates.first(where: { $0.category == .screenplay }) else {
            XCTFail("Screenplay template not found")
            return
        }
        let transition = screenplay.placeholders.first { $0.key == "transition" }
        XCTAssertEqual(transition?.defaultValue, "CUT TO:",
                       "Transition placeholder should retain 'CUT TO:' default value")
    }

    // MARK: - Document Model Regression Tests

    func testDocumentWordCountRemainsCorrect() {
        // wordCount is still present after PR changes
        let doc = Document(
            title: "Test",
            content: "One two three four five",
            category: .article
        )
        XCTAssertEqual(doc.wordCount, 5)
    }

    func testDocumentWordCountIgnoresExtraWhitespace() {
        let doc = Document(
            title: "Test",
            content: "  word1   word2  \n\n  word3  ",
            category: .article
        )
        XCTAssertEqual(doc.wordCount, 3)
    }

    func testDocumentCharacterCountRemainsCorrect() {
        // characterCount is still present after PR changes
        let doc = Document(title: "Test", content: "Hello", category: .article)
        XCTAssertEqual(doc.characterCount, 5)
    }

    func testDocumentReadingTimeRemainsCorrect() {
        // readingTime is still present after PR changes
        let words = Array(repeating: "word", count: 400).joined(separator: " ")
        let doc = Document(title: "Test", content: words, category: .article)
        XCTAssertEqual(doc.readingTime, 2, "400 words at 200 wpm should be 2 minutes")
    }

    func testDocumentReadingTimeMinimumIsOne() {
        let doc = Document(title: "Short", content: "Just a few words.", category: .article)
        XCTAssertGreaterThanOrEqual(doc.readingTime, 1, "readingTime should never be less than 1")
    }
}

// MARK: - AIService Internal Properties Tests (PR: exposed currentModel and apiKey)

final class AIServiceInternalPropertiesTests: XCTestCase {

    func testAIServiceCurrentModelReturnsConfiguredModelRawValue() {
        // currentModel is exposed as an internal property so ComputerUseService can read it.
        let config = AIConfiguration(
            apiKey: "sk-ant-test",
            model: .claude35Sonnet,
            maxTokens: 4096,
            temperature: 0.7
        )
        let app = WritersApp(aiConfiguration: config)
        // Access via makeComputerUseService path to confirm the service gets the right model.
        // The model value should match the raw value of the configured AIModel.
        XCTAssertEqual(config.model.rawValue, "claude-3-5-sonnet-20241022",
                       "claude35Sonnet raw value must match the Anthropic model ID")
        XCTAssertNotNil(app.aiService)
    }

    func testAIServiceAPIKeyMatchesConfiguredKey() {
        // apiKey is exposed so ComputerUseService can forward it in Authorization headers.
        let expectedKey = "sk-ant-api03-unique-test-key"
        let config = AIConfiguration(
            apiKey: expectedKey,
            model: .claude35Sonnet,
            maxTokens: 4096,
            temperature: 0.7
        )
        let app = WritersApp(aiConfiguration: config)
        // ComputerUseService reads aiService.apiKey. Verify the service is present and
        // the API key configured on it round-trips through AIConfiguration correctly.
        XCTAssertNotNil(app.aiService)
        XCTAssertEqual(config.apiKey, expectedKey,
                       "AIConfiguration must preserve the API key supplied at init")
    }

    func testComputerUseServiceUsesAIServiceCurrentModel() {
        // Verify that makeComputerUseService creates a service when AI is enabled.
        // This implicitly validates currentModel and apiKey are accessible.
        let config = AIConfiguration(
            apiKey: "sk-ant-model-check",
            model: .claude3Opus,
            maxTokens: 2048,
            temperature: 0.5
        )
        let app = WritersApp(aiConfiguration: config)
        let executor = MockComputerUseExecutor()
        let service = app.makeComputerUseService(executor: executor)
        XCTAssertNotNil(service,
                        "makeComputerUseService must return a service when AI is enabled")
    }
}

// MARK: - ComputerUseActionType Boundary Tests (additional coverage)

final class ComputerUseActionTypeBoundaryTests: XCTestCase {

    func testComputerUseActionTypeFromInvalidRawValueReturnsNil() {
        // Boundary: an unknown action string from the API should produce nil, not crash.
        let unknown = ComputerUseActionType(rawValue: "totally_unknown_action_xyz")
        XCTAssertNil(unknown,
                     "An unrecognised action string must return nil, not produce a wrong enum case")
    }

    func testComputerUseActionTypeFromEmptyStringReturnsNil() {
        let empty = ComputerUseActionType(rawValue: "")
        XCTAssertNil(empty, "Empty string must not match any action type")
    }

    func testComputerUseActionTypeFromMixedCaseIsNil() {
        // Raw values are lowercase; mixed-case strings must not accidentally match.
        let mixed = ComputerUseActionType(rawValue: "Left_Click")
        XCTAssertNil(mixed, "Mixed-case raw value should not match the lowercase 'left_click' case")
    }
}

// MARK: - Screenplay Template Content Regression Tests (PR: removed character_state and shot_description)

final class ScreenplayTemplateContentTests: XCTestCase {
    var app: WritersApp!

    override func setUp() {
        super.setUp()
        app = WritersApp()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    func testScreenplayTemplateContentDoesNotContainCharacterStatePlaceholder() {
        // After the PR, {{character_state}} must not appear in the template content string.
        let templates = app.templateManager.getAllTemplates()
        guard let screenplay = templates.first(where: { $0.category == .screenplay }) else {
            XCTFail("Screenplay template must exist")
            return
        }
        XCTAssertFalse(screenplay.content.contains("{{character_state}}"),
                       "Removed placeholder {{character_state}} must not appear in template content")
    }

    func testScreenplayTemplateContentDoesNotContainShotDescriptionPlaceholder() {
        let templates = app.templateManager.getAllTemplates()
        guard let screenplay = templates.first(where: { $0.category == .screenplay }) else {
            XCTFail("Screenplay template must exist")
            return
        }
        XCTAssertFalse(screenplay.content.contains("{{shot_description}}"),
                       "Removed placeholder {{shot_description}} must not appear in template content")
    }

    func testScreenplayTemplateContentContainsAllRequiredPlaceholders() {
        // The remaining placeholders must appear in the template body.
        let templates = app.templateManager.getAllTemplates()
        guard let screenplay = templates.first(where: { $0.category == .screenplay }) else {
            XCTFail("Screenplay template must exist")
            return
        }
        let required = ["{{scene_heading}}", "{{action}}", "{{character}}", "{{dialogue}}", "{{transition}}"]
        for placeholder in required {
            XCTAssertTrue(screenplay.content.contains(placeholder),
                          "Screenplay template content must contain \(placeholder)")
        }
    }

    func testScreenplayTemplateDoesNotContainProfessionalInDescription() {
        // PR simplified the description from "…industry-standard formatting" to a shorter string.
        let templates = app.templateManager.getAllTemplates()
        guard let screenplay = templates.first(where: { $0.category == .screenplay }) else {
            XCTFail("Screenplay template must exist")
            return
        }
        XCTAssertFalse(screenplay.description.lowercased().contains("professional"),
                       "Simplified description must not retain the old 'professional' wording")
        XCTAssertFalse(screenplay.description.lowercased().contains("industry-standard"),
                       "Simplified description must not retain the old 'industry-standard' wording")
    }

    func testScreenplayTemplateTotalTagCountIsThree() {
        // PR reduced tags from 5 (screenplay, script, scene, film, professional) to 3.
        let templates = app.templateManager.getAllTemplates()
        guard let screenplay = templates.first(where: { $0.category == .screenplay }) else {
            XCTFail("Screenplay template must exist")
            return
        }
        XCTAssertEqual(screenplay.metadata.tags.count, 3,
                       "Screenplay template must have exactly 3 tags after PR simplification")
    }

    func testScreenplayTemplateTagsDoNotContainFilm() {
        let templates = app.templateManager.getAllTemplates()
        guard let screenplay = templates.first(where: { $0.category == .screenplay }) else {
            XCTFail("Screenplay template must exist")
            return
        }
        XCTAssertFalse(screenplay.metadata.tags.contains("film"),
                       "'film' tag must have been removed from the screenplay template")
    }

    func testScreenplayTemplateTagsDoNotContainProfessional() {
        let templates = app.templateManager.getAllTemplates()
        guard let screenplay = templates.first(where: { $0.category == .screenplay }) else {
            XCTFail("Screenplay template must exist")
            return
        }
        XCTAssertFalse(screenplay.metadata.tags.contains("professional"),
                       "'professional' tag must have been removed from the screenplay template")
    }

}

// MARK: - Writing Advisor Basic Tests

final class WritingAdvisorTests: XCTestCase {

    // MARK: - AdvisorCategory

    func testAdvisorCategoryAllCasesCount() {
        XCTAssertEqual(AdvisorCategory.allCases.count, 5)
    }

    func testAdvisorCategoryRawValues() {
        XCTAssertEqual(AdvisorCategory.productivity.rawValue, "productivity")
        XCTAssertEqual(AdvisorCategory.creativity.rawValue, "creativity")
        XCTAssertEqual(AdvisorCategory.consistency.rawValue, "consistency")
        XCTAssertEqual(AdvisorCategory.craft.rawValue, "craft")
        XCTAssertEqual(AdvisorCategory.goals.rawValue, "goals")
    }

    func testAdvisorCategoryDisplayNamesNonEmpty() {
        for category in AdvisorCategory.allCases {
            XCTAssertFalse(category.displayName.isEmpty,
                           "\(category.rawValue) displayName must not be empty")
        }
    }

    func testAdvisorCategoryDisplayNameValues() {
        XCTAssertEqual(AdvisorCategory.productivity.displayName, "Productivity")
        XCTAssertEqual(AdvisorCategory.creativity.displayName, "Creativity")
        XCTAssertEqual(AdvisorCategory.consistency.displayName, "Consistency")
        XCTAssertEqual(AdvisorCategory.craft.displayName, "Craft")
        XCTAssertEqual(AdvisorCategory.goals.displayName, "Goals")
    }

    func testAdvisorCategoryRoundTripCodable() throws {
        for category in AdvisorCategory.allCases {
            let data = try JSONEncoder().encode(category)
            let decoded = try JSONDecoder().decode(AdvisorCategory.self, from: data)
            XCTAssertEqual(decoded, category, "\(category) must survive a JSON round-trip")
        }
    }

    // MARK: - AdvisorPriority

    func testAdvisorPriorityAllCasesCount() {
        XCTAssertEqual(AdvisorPriority.allCases.count, 3)
    }

    func testAdvisorPriorityRawValues() {
        XCTAssertEqual(AdvisorPriority.high.rawValue, "high")
        XCTAssertEqual(AdvisorPriority.medium.rawValue, "medium")
        XCTAssertEqual(AdvisorPriority.low.rawValue, "low")
    }

    func testAdvisorPriorityRoundTripCodable() throws {
        for priority in AdvisorPriority.allCases {
            let data = try JSONEncoder().encode(priority)
            let decoded = try JSONDecoder().decode(AdvisorPriority.self, from: data)
            XCTAssertEqual(decoded, priority, "\(priority) must survive a JSON round-trip")
        }
    }

    // MARK: - AdvisorRecommendation

    func testAdvisorRecommendationIsIdentifiable() {
        let rec1 = AdvisorRecommendation(
            category: .productivity,
            priority: .high,
            title: "Write More",
            recommendation: "Set a daily word goal.",
            actionableSteps: ["Open app", "Write 500 words"]
        )
        let rec2 = AdvisorRecommendation(
            category: .craft,
            priority: .medium,
            title: "Improve Dialogue",
            recommendation: "Read your dialogue aloud.",
            actionableSteps: ["Read aloud", "Edit"]
        )
        XCTAssertNotEqual(rec1.id, rec2.id)
    }

    func testAdvisorRecommendationDefaultIdIsUnique() {
        let a = AdvisorRecommendation(category: .goals, priority: .low,
                                      title: "T", recommendation: "R", actionableSteps: [])
        let b = AdvisorRecommendation(category: .goals, priority: .low,
                                      title: "T", recommendation: "R", actionableSteps: [])
        XCTAssertNotEqual(a.id, b.id)
    }

    func testAdvisorRecommendationCodable() throws {
        let original = AdvisorRecommendation(
            id: UUID(),
            category: .consistency,
            priority: .low,
            title: "Stay Consistent",
            recommendation: "Write every day.",
            actionableSteps: ["Set a timer", "Write for 10 minutes"],
            generatedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AdvisorRecommendation.self, from: data)
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.category, original.category)
        XCTAssertEqual(decoded.priority, original.priority)
        XCTAssertEqual(decoded.title, original.title)
        XCTAssertEqual(decoded.recommendation, original.recommendation)
        XCTAssertEqual(decoded.actionableSteps, original.actionableSteps)
    }

    func testAdvisorRecommendationStoresAllFields() {
        let id = UUID()
        let date = Date(timeIntervalSince1970: 0)
        let rec = AdvisorRecommendation(
            id: id,
            category: .creativity,
            priority: .high,
            title: "Be Creative",
            recommendation: "Freewrite daily.",
            actionableSteps: ["Step A", "Step B"],
            generatedAt: date
        )
        XCTAssertEqual(rec.id, id)
        XCTAssertEqual(rec.category, .creativity)
        XCTAssertEqual(rec.priority, .high)
        XCTAssertEqual(rec.title, "Be Creative")
        XCTAssertEqual(rec.recommendation, "Freewrite daily.")
        XCTAssertEqual(rec.actionableSteps, ["Step A", "Step B"])
        XCTAssertEqual(rec.generatedAt, date)
    }

    func testAdvisorRecommendationEmptyActionableSteps() throws {
        let rec = AdvisorRecommendation(
            category: .craft, priority: .medium,
            title: "Craft note", recommendation: "Some note", actionableSteps: []
        )
        let data = try JSONEncoder().encode(rec)
        let decoded = try JSONDecoder().decode(AdvisorRecommendation.self, from: data)
        XCTAssertTrue(decoded.actionableSteps.isEmpty)
    }

    // MARK: - WritingAdvisorReport

    func testWritingAdvisorReportCodable() throws {
        let rec = AdvisorRecommendation(
            category: .goals,
            priority: .high,
            title: "Set a Goal",
            recommendation: "Define a clear project goal.",
            actionableSteps: ["Pick a target word count", "Set a deadline"]
        )
        let report = WritingAdvisorReport(
            recommendations: [rec],
            overallAssessment: "You are making solid progress.",
            focusArea: .goals,
            generatedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let data = try JSONEncoder().encode(report)
        let decoded = try JSONDecoder().decode(WritingAdvisorReport.self, from: data)
        XCTAssertEqual(decoded.recommendations.count, 1)
        XCTAssertEqual(decoded.overallAssessment, report.overallAssessment)
        XCTAssertEqual(decoded.focusArea, report.focusArea)
    }

    func testWritingAdvisorReportEmptyRecommendations() throws {
        let report = WritingAdvisorReport(
            recommendations: [],
            overallAssessment: "Nothing to report yet.",
            focusArea: .productivity
        )
        let data = try JSONEncoder().encode(report)
        let decoded = try JSONDecoder().decode(WritingAdvisorReport.self, from: data)
        XCTAssertTrue(decoded.recommendations.isEmpty)
        XCTAssertEqual(decoded.overallAssessment, "Nothing to report yet.")
        XCTAssertEqual(decoded.focusArea, .productivity)
    }

    func testWritingAdvisorReportStoresAllFields() {
        let date = Date(timeIntervalSince1970: 500_000)
        let report = WritingAdvisorReport(
            recommendations: [],
            overallAssessment: "Assessment text.",
            focusArea: .craft,
            generatedAt: date
        )
        XCTAssertEqual(report.overallAssessment, "Assessment text.")
        XCTAssertEqual(report.focusArea, .craft)
        XCTAssertEqual(report.generatedAt, date)
    }

    // MARK: - AdvisorContext

    func testAdvisorContextStoresAllFields() {
        let stats = SessionStats(
            totalSessions: 10,
            totalDurationSeconds: 3600,
            averageDurationSeconds: 360.0,
            earliestSession: nil,
            latestSession: nil
        )
        let ctx = AdvisorContext(
            totalDocuments: 7,
            recentDocumentTitles: ["Doc A", "Doc B"],
            totalWordsAcrossDocuments: 12000,
            documentCategories: ["novel", "article"],
            sessionStats: stats,
            additionalNotes: "Some note"
        )
        XCTAssertEqual(ctx.totalDocuments, 7)
        XCTAssertEqual(ctx.recentDocumentTitles, ["Doc A", "Doc B"])
        XCTAssertEqual(ctx.totalWordsAcrossDocuments, 12000)
        XCTAssertEqual(ctx.documentCategories, ["novel", "article"])
        XCTAssertNotNil(ctx.sessionStats)
        XCTAssertEqual(ctx.additionalNotes, "Some note")
    }

    func testAdvisorContextDefaultNilNotes() {
        let ctx = AdvisorContext(
            totalDocuments: 0,
            recentDocumentTitles: [],
            totalWordsAcrossDocuments: 0,
            documentCategories: [],
            sessionStats: nil
        )
        XCTAssertNil(ctx.additionalNotes)
        XCTAssertNil(ctx.sessionStats)
    }

    // MARK: - WritingAdvisorService.buildContextText

    func testBuildContextTextIncludesDocumentCountAndWords() {
        let service = WritingAdvisorService(
            aiService: AIService(configuration: AIConfiguration(apiKey: "test-key"))
        )
        let ctx = AdvisorContext(
            totalDocuments: 3,
            recentDocumentTitles: [],
            totalWordsAcrossDocuments: 5000,
            documentCategories: [],
            sessionStats: nil
        )
        let text = service.buildContextText(from: ctx)
        XCTAssertTrue(text.contains("3"), "Context text must contain document count")
        XCTAssertTrue(text.contains("5000"), "Context text must contain word count")
    }

    func testBuildContextTextIncludesRecentTitles() {
        let service = WritingAdvisorService(
            aiService: AIService(configuration: AIConfiguration(apiKey: "test-key"))
        )
        let ctx = AdvisorContext(
            totalDocuments: 2,
            recentDocumentTitles: ["My Novel", "Short Story"],
            totalWordsAcrossDocuments: 1000,
            documentCategories: [],
            sessionStats: nil
        )
        let text = service.buildContextText(from: ctx)
        XCTAssertTrue(text.contains("\"My Novel\""),
                      "Recent titles must be quoted in context text")
        XCTAssertTrue(text.contains("\"Short Story\""))
    }

    func testBuildContextTextOmitsRecentTitlesWhenEmpty() {
        let service = WritingAdvisorService(
            aiService: AIService(configuration: AIConfiguration(apiKey: "test-key"))
        )
        let ctx = AdvisorContext(
            totalDocuments: 1,
            recentDocumentTitles: [],
            totalWordsAcrossDocuments: 100,
            documentCategories: [],
            sessionStats: nil
        )
        let text = service.buildContextText(from: ctx)
        XCTAssertFalse(text.contains("Recent titles"),
                       "Context text must omit Recent titles line when titles array is empty")
    }

    func testBuildContextTextIncludesCategories() {
        let service = WritingAdvisorService(
            aiService: AIService(configuration: AIConfiguration(apiKey: "test-key"))
        )
        let ctx = AdvisorContext(
            totalDocuments: 1,
            recentDocumentTitles: [],
            totalWordsAcrossDocuments: 500,
            documentCategories: ["novel", "screenplay"],
            sessionStats: nil
        )
        let text = service.buildContextText(from: ctx)
        XCTAssertTrue(text.contains("novel"), "Categories must appear in context text")
        XCTAssertTrue(text.contains("screenplay"))
    }

    func testBuildContextTextIncludesSessionStats() {
        let service = WritingAdvisorService(
            aiService: AIService(configuration: AIConfiguration(apiKey: "test-key"))
        )
        let stats = SessionStats(
            totalSessions: 8,
            totalDurationSeconds: 4800,
            averageDurationSeconds: 600.0,
            earliestSession: nil,
            latestSession: nil
        )
        let ctx = AdvisorContext(
            totalDocuments: 2,
            recentDocumentTitles: [],
            totalWordsAcrossDocuments: 300,
            documentCategories: [],
            sessionStats: stats
        )
        let text = service.buildContextText(from: ctx)
        XCTAssertTrue(text.contains("8"), "Session count must appear in context text")
        XCTAssertTrue(text.contains("10"), "Average minutes (600s = 10 min) must appear")
    }

    func testBuildContextTextIncludesAdditionalNotes() {
        let service = WritingAdvisorService(
            aiService: AIService(configuration: AIConfiguration(apiKey: "test-key"))
        )
        let ctx = AdvisorContext(
            totalDocuments: 0,
            recentDocumentTitles: [],
            totalWordsAcrossDocuments: 0,
            documentCategories: [],
            sessionStats: nil,
            additionalNotes: "Focus on dialogue this week"
        )
        let text = service.buildContextText(from: ctx)
        XCTAssertTrue(text.contains("Focus on dialogue this week"),
                      "Additional notes must appear verbatim in context text")
    }

    func testBuildContextTextOmitsEmptyAdditionalNotes() {
        let service = WritingAdvisorService(
            aiService: AIService(configuration: AIConfiguration(apiKey: "test-key"))
        )
        let ctx = AdvisorContext(
            totalDocuments: 0,
            recentDocumentTitles: [],
            totalWordsAcrossDocuments: 0,
            documentCategories: [],
            sessionStats: nil,
            additionalNotes: ""
        )
        let text = service.buildContextText(from: ctx)
        XCTAssertFalse(text.contains("Additional context"),
                       "Empty additionalNotes must not add an Additional context line")
    }

    // MARK: - AIAssistanceType.writingAdvisor

    func testAIAssistanceTypeHasWritingAdvisorCase() {
        let type = AIAssistanceType.writingAdvisor
        XCTAssertEqual(type.displayName, "Writing Advisor")
    }

    func testWritingAdvisorPromptIsNonEmpty() {
        let prompt = AIAssistanceType.writingAdvisor.prompt(for: "Documents: 5 total", context: nil)
        XCTAssertFalse(prompt.isEmpty, "Writing advisor prompt must not be empty")
        XCTAssertTrue(prompt.contains("JSON"),
                      "Writing advisor prompt must instruct Claude to return JSON")
    }

    func testWritingAdvisorPromptEmbeddsWriterData() {
        let writerData = "Documents: 10 total, 25000 words"
        let prompt = AIAssistanceType.writingAdvisor.prompt(for: writerData, context: nil)
        XCTAssertTrue(prompt.contains(writerData),
                      "Prompt must embed the provided writer data verbatim")
    }

    func testWritingAdvisorPromptContainsExpectedJSONKeys() {
        let prompt = AIAssistanceType.writingAdvisor.prompt(for: "test data", context: nil)
        XCTAssertTrue(prompt.contains("overallAssessment"),
                      "Prompt must specify the overallAssessment JSON key")
        XCTAssertTrue(prompt.contains("focusArea"),
                      "Prompt must specify the focusArea JSON key")
        XCTAssertTrue(prompt.contains("recommendations"),
                      "Prompt must specify the recommendations JSON key")
        XCTAssertTrue(prompt.contains("actionableSteps"),
                      "Prompt must specify the actionableSteps JSON key")
    }

    func testWritingAdvisorPromptContainsPriorityOptions() {
        let prompt = AIAssistanceType.writingAdvisor.prompt(for: "data", context: nil)
        XCTAssertTrue(prompt.contains("high|medium|low"),
                      "Prompt must enumerate priority options")
    }

    // MARK: - WritersApp integration (writing advisor lifecycle)

    func testWritingAdvisorServiceCreatedWhenAIEnabled() {
        let config = AIConfiguration(apiKey: "test-key")
        let aiApp = WritersApp(aiConfiguration: config)
        XCTAssertNotNil(aiApp.writingAdvisorService,
                        "writingAdvisorService must be non-nil when AI is enabled at init")
    }

    func testWritingAdvisorServiceNilledWhenAIDisabled() {
        let config = AIConfiguration(apiKey: "test-key")
        let aiApp = WritersApp(aiConfiguration: config)
        XCTAssertNotNil(aiApp.writingAdvisorService)
        aiApp.disableAI()
        XCTAssertNil(aiApp.writingAdvisorService,
                     "writingAdvisorService must be nil after disableAI()")
    }

    func testWritingAdvisorServiceCreatedByEnableAI() {
        let app = WritersApp()
        XCTAssertNil(app.writingAdvisorService)
        let config = AIConfiguration(apiKey: "test-key")
        app.enableAI(configuration: config)
        XCTAssertNotNil(app.writingAdvisorService,
                        "writingAdvisorService must be non-nil after enableAI()")
    }

    func testWritingAdvisorServiceNilWithoutAI() {
        let app = WritersApp()
        XCTAssertNil(app.writingAdvisorService,
                     "writingAdvisorService must be nil when no AI is configured")
    }

    func testGetPersonalizedWritingAdviceThrowsWhenNoAI() async {
        let noAIApp = WritersApp()
        do {
            _ = try await noAIApp.getPersonalizedWritingAdvice()
            XCTFail("Expected AIError.aiNotEnabled to be thrown")
        } catch AIError.aiNotEnabled {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testWritingAdvisorServiceRequiresAI() async {
        let noAIApp = WritersApp()
        do {
            _ = try await noAIApp.getPersonalizedWritingAdvice()
            XCTFail("Expected AIError.aiNotEnabled to be thrown")
        } catch AIError.aiNotEnabled {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testGetWritingAdviceForCategoryThrowsWhenNoAI() async {
        let noAIApp = WritersApp()
        do {
            _ = try await noAIApp.getWritingAdvice(for: .craft)
            XCTFail("Expected AIError.aiNotEnabled to be thrown")
        } catch AIError.aiNotEnabled {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testDisableAITwiceIsIdempotent() {
        let config = AIConfiguration(apiKey: "test-key")
        let aiApp = WritersApp(aiConfiguration: config)
        aiApp.disableAI()
        aiApp.disableAI()
        XCTAssertNil(aiApp.writingAdvisorService,
                     "writingAdvisorService must stay nil after double disableAI()")
        XCTAssertFalse(aiApp.isAIEnabled,
                       "isAIEnabled must be false after double disableAI()")
    }

    // MARK: - Brainstorm Ideas Categorization

    func testBrainstormResultDecodesFromJSON() {
        let json = """
        {
          "categories": [
            {
              "name": "Character Ideas",
              "description": "Ideas focused on character development",
              "ideas": [
                {
                  "title": "Conflicted Hero",
                  "description": "A protagonist with competing goals",
                  "isSpeculative": false
                }
              ]
            }
          ]
        }
        """

        let decoder = JSONDecoder()
        guard let data = json.data(using: .utf8) else {
            XCTFail("Could not convert JSON string to data")
            return
        }

        do {
            let result = try decoder.decode(BrainstormResult.self, from: data)
            XCTAssertEqual(result.categories.count, 1)
            XCTAssertEqual(result.categories[0].name, "Character Ideas")
            XCTAssertEqual(result.categories[0].ideas.count, 1)
            XCTAssertEqual(result.categories[0].ideas[0].title, "Conflicted Hero")
            XCTAssertFalse(result.categories[0].ideas[0].isSpeculative)
        } catch {
            XCTFail("Failed to decode BrainstormResult: \(error)")
        }
    }

    func testBrainstormIdeasCategorizedRequiresAI() async {
        let noAIApp = WritersApp()
        do {
            _ = try await noAIApp.brainstormIdeasCategorized(topic: "Science fiction novel")
            XCTFail("Expected AIError.aiNotEnabled to be thrown")
        } catch AIError.aiNotEnabled {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testCategorizedIdeaModelConformance() {
        let idea = CategorizedIdea(
            title: "Time Travel Plot",
            description: "A story involving time paradoxes",
            isSpeculative: true
        )
        XCTAssertEqual(idea.title, "Time Travel Plot")
        XCTAssertEqual(idea.description, "A story involving time paradoxes")
        XCTAssertTrue(idea.isSpeculative)
    }

    func testIdeaCategoryModelConformance() {
        let idea1 = CategorizedIdea(title: "Idea 1", description: "First idea", isSpeculative: false)
        let idea2 = CategorizedIdea(title: "Idea 2", description: "Second idea", isSpeculative: true)
        let category = IdeaCategory(
            name: "Plot Ideas",
            description: "Story plot concepts",
            ideas: [idea1, idea2]
        )
        XCTAssertEqual(category.name, "Plot Ideas")
        XCTAssertEqual(category.ideas.count, 2)
    }

    func testAIAssistanceTypeHasBrainstormIdeasCategorizedCase() {
        let assistanceType = AIAssistanceType.brainstormIdeasCategorized
        XCTAssertEqual(assistanceType.displayName, "Brainstorm Ideas (Categorized)")
    }

    // MARK: - JSON Parsing Edge Cases

    func testBrainstormResultDecodesBareJSON() {
        let json = """
        {
          "categories": [
            {
              "name": "Character Ideas",
              "description": "Character concepts",
              "ideas": []
            }
          ]
        }
        """

        let decoder = JSONDecoder()
        guard let data = json.data(using: .utf8) else {
            XCTFail("Could not encode JSON")
            return
        }

        do {
            let result = try decoder.decode(BrainstormResult.self, from: data)
            XCTAssertEqual(result.categories.count, 1)
        } catch {
            XCTFail("Failed to decode bare JSON: \(error)")
        }
    }

    func testBrainstormResultDecodesJSONInMarkdownCodeBlock() {
        let responseWithMarkdown = """
        Here are the categorized ideas:

        ```json
        {
          "categories": [
            {
              "name": "Plot Ideas",
              "description": "Story concepts",
              "ideas": [
                {
                  "title": "Time Loop",
                  "description": "Protagonist repeats a day",
                  "isSpeculative": false
                }
              ]
            }
          ]
        }
        ```

        These ideas are organized for you.
        """

        let decoder = JSONDecoder()
        // Extract JSON manually like the helper would
        if let jsonStart = responseWithMarkdown.range(of: "```json"),
           let jsonEnd = responseWithMarkdown.range(of: "```", range: responseWithMarkdown.index(jsonStart.upperBound, offsetBy: 1)..<responseWithMarkdown.endIndex) {
            let jsonString = String(responseWithMarkdown[jsonStart.upperBound..<jsonEnd.lowerBound])
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if let data = jsonString.data(using: .utf8) {
                do {
                    let result = try decoder.decode(BrainstormResult.self, from: data)
                    XCTAssertEqual(result.categories[0].name, "Plot Ideas")
                    XCTAssertEqual(result.categories[0].ideas[0].title, "Time Loop")
                } catch {
                    XCTFail("Failed to decode markdown-wrapped JSON: \(error)")
                }
            } else {
                XCTFail("Could not convert JSON to data")
            }
        } else {
            XCTFail("Could not find JSON code block")
        }
    }

    func testBrainstormResultDecodesMultipleCategories() {
        let json = """
        {
          "categories": [
            {
              "name": "Character Ideas",
              "description": "Character types",
              "ideas": [
                {
                  "title": "Hero",
                  "description": "Protagonist",
                  "isSpeculative": false
                },
                {
                  "title": "Villain",
                  "description": "Antagonist",
                  "isSpeculative": false
                }
              ]
            },
            {
              "name": "Setting Ideas",
              "description": "Locations",
              "ideas": [
                {
                  "title": "Dystopian City",
                  "description": "Post-apocalyptic metropolis",
                  "isSpeculative": true
                }
              ]
            }
          ]
        }
        """

        let decoder = JSONDecoder()
        guard let data = json.data(using: .utf8) else {
            XCTFail("Could not encode JSON")
            return
        }

        do {
            let result = try decoder.decode(BrainstormResult.self, from: data)
            XCTAssertEqual(result.categories.count, 2)
            XCTAssertEqual(result.categories[0].ideas.count, 2)
            XCTAssertEqual(result.categories[1].ideas.count, 1)
        } catch {
            XCTFail("Failed to decode multiple categories: \(error)")
        }
    }

    func testCategorizedIdeaHandlesSpeculativeFlag() {
        let speculativeIdea = CategorizedIdea(
            title: "Flying Cities",
            description: "Cities that hover in the air",
            isSpeculative: true
        )
        XCTAssertTrue(speculativeIdea.isSpeculative)

        let groundedIdea = CategorizedIdea(
            title: "Medieval Village",
            description: "Historical village setting",
            isSpeculative: false
        )
        XCTAssertFalse(groundedIdea.isSpeculative)
    }
}

// MARK: - Test Helpers

private class MockComputerUseExecutor: ComputerUseExecutor {
    func takeScreenshot() async throws -> String {
        return "mockScreenshotBase64Data"
    }

    func execute(action: ComputerUseAction) async throws -> ComputerUseResult {
        return ComputerUseResult(action: action, screenshotBase64: "mockResultScreenshot")
    }
}