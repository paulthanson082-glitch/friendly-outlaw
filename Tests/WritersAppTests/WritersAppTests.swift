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

    // MARK: - Hallucination Reduction

    func testHallucinationReductionMethodsRequireAI() async {
        let freshApp = WritersApp()
        let doc = freshApp.createBlankDocument(title: "Test", category: .novel)

        do {
            _ = try await freshApp.extractQuotesFromDocument(documentId: doc.id)
            XCTFail("Should throw aiNotEnabled when AI is not configured")
        } catch AIError.aiNotEnabled {
            // Expected
        } catch {
            XCTFail("Wrong error: \(error)")
        }

        do {
            _ = try await freshApp.verifyDocumentConsistency(documentId: doc.id)
            XCTFail("Should throw aiNotEnabled when AI is not configured")
        } catch AIError.aiNotEnabled {
            // Expected
        } catch {
            XCTFail("Wrong error: \(error)")
        }
    }

    func testHallucinationReductionMethodsRequireDocument() async {
        let freshApp = WritersApp()
        let config = AIConfiguration(apiKey: "test-key", model: .claude35Sonnet)
        freshApp.enableAI(configuration: config)
        let bogusId = UUID()

        do {
            _ = try await freshApp.extractQuotesFromDocument(documentId: bogusId)
            XCTFail("Should throw documentNotFound for unknown document")
        } catch AIError.documentNotFound {
            // Expected
        } catch {
            XCTFail("Wrong error: \(error)")
        }

        do {
            _ = try await freshApp.verifyDocumentConsistency(documentId: bogusId)
            XCTFail("Should throw documentNotFound for unknown document")
        } catch AIError.documentNotFound {
            // Expected
        } catch {
            XCTFail("Wrong error: \(error)")
        }
    }

    func testTextBasedHallucinationReductionMethods() async {
        let freshApp = WritersApp()

        do {
            _ = try await freshApp.extractQuotesFromText("He said, \"Hello world.\"")
            XCTFail("Should throw aiNotEnabled when AI is not configured")
        } catch AIError.aiNotEnabled {
            // Expected
        } catch {
            XCTFail("Wrong error: \(error)")
        }
    }
}