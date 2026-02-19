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
        XCTAssertTrue(result.contains("shortStory"))
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
}
