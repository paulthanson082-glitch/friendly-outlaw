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

    func testNestedPlaceholderPrevention() {
        // Test that placeholder values containing {{...}} patterns are NOT recursively replaced
        let template = Template(
            name: "Nested Test",
            category: .other,
            description: "Test nested placeholder prevention",
            content: "User: {{username}}, Role: {{role}}, Config: {{config}}",
            placeholders: [
                Placeholder(key: "username", label: "Username"),
                Placeholder(key: "role", label: "Role"),
                Placeholder(key: "config", label: "Config")
            ]
        )

        // Value for 'role' contains a placeholder pattern that should NOT be replaced
        let values = [
            "username": "Alice",
            "role": "{{username}}",
            "config": "Setting: {{role}}"
        ]

        let document = template.createDocument(with: values)

        // The {{username}} in role value should remain literal, not be replaced with "Alice"
        // The {{role}} in config value should remain literal, not be replaced
        XCTAssertEqual(
            document.content,
            "User: Alice, Role: {{username}}, Config: Setting: {{role}}",
            "Placeholder values should not be recursively replaced"
        )
    }
}
