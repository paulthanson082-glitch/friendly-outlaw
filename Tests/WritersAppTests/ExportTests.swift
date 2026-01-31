import XCTest
@testable import WritersApp

/// Tests for document export functionality across all formats
final class ExportTests: XCTestCase {
    var app: WritersApp!

    override func setUp() {
        super.setUp()
        app = WritersApp()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // MARK: - Markdown Export Tests

    func testExportAsMarkdown() {
        let doc = Document(
            title: "Test Document",
            content: "This is the content.",
            category: .article
        )
        app.documentManager.createDocument(doc)

        let exported = app.exportDocument(id: doc.id, format: .markdown)

        XCTAssertNotNil(exported)
        XCTAssertTrue(exported!.contains("# Test Document"))
        XCTAssertTrue(exported!.contains("This is the content."))
        XCTAssertTrue(exported!.contains("**Category:** Article"))
        XCTAssertTrue(exported!.contains("**Word Count:** 4"))
    }

    func testExportAsMarkdownContainsMetadata() {
        let doc = Document(
            title: "My Article",
            content: "Content here",
            category: .blogPost
        )
        app.documentManager.createDocument(doc)

        let exported = app.exportDocument(id: doc.id, format: .markdown)

        XCTAssertNotNil(exported)
        XCTAssertTrue(exported!.contains("**Created:**"))
        XCTAssertTrue(exported!.contains("**Modified:**"))
        XCTAssertTrue(exported!.contains("---"))
    }

    func testExportAsMarkdownIsDefault() {
        let doc = Document(title: "Test", content: "Content", category: .article)
        app.documentManager.createDocument(doc)

        let defaultExport = app.exportDocument(id: doc.id)
        let markdownExport = app.exportDocument(id: doc.id, format: .markdown)

        XCTAssertEqual(defaultExport, markdownExport)
    }

    // MARK: - Plain Text Export Tests

    func testExportAsPlainText() {
        let doc = Document(
            title: "Plain Text Test",
            content: "Just the content, nothing more.",
            category: .article
        )
        app.documentManager.createDocument(doc)

        let exported = app.exportDocument(id: doc.id, format: .plainText)

        XCTAssertNotNil(exported)
        XCTAssertEqual(exported, "Just the content, nothing more.")
    }

    func testExportAsPlainTextPreservesFormatting() {
        let contentWithNewlines = """
        First paragraph.

        Second paragraph.

        Third paragraph.
        """
        let doc = Document(
            title: "Multi-paragraph",
            content: contentWithNewlines,
            category: .article
        )
        app.documentManager.createDocument(doc)

        let exported = app.exportDocument(id: doc.id, format: .plainText)

        XCTAssertEqual(exported, contentWithNewlines)
    }

    func testExportAsPlainTextEmpty() {
        let doc = Document(title: "Empty", content: "", category: .article)
        app.documentManager.createDocument(doc)

        let exported = app.exportDocument(id: doc.id, format: .plainText)

        XCTAssertEqual(exported, "")
    }

    // MARK: - HTML Export Tests

    func testExportAsHTML() {
        let doc = Document(
            title: "HTML Test",
            content: "Content for HTML export.",
            category: .article
        )
        app.documentManager.createDocument(doc)

        let exported = app.exportDocument(id: doc.id, format: .html)

        XCTAssertNotNil(exported)
        XCTAssertTrue(exported!.contains("<!DOCTYPE html>"))
        XCTAssertTrue(exported!.contains("<html>"))
        XCTAssertTrue(exported!.contains("</html>"))
    }

    func testExportAsHTMLContainsTitle() {
        let doc = Document(
            title: "My Great Title",
            content: "Content",
            category: .article
        )
        app.documentManager.createDocument(doc)

        let exported = app.exportDocument(id: doc.id, format: .html)

        XCTAssertNotNil(exported)
        XCTAssertTrue(exported!.contains("<title>My Great Title</title>"))
        XCTAssertTrue(exported!.contains("<h1>My Great Title</h1>"))
    }

    func testExportAsHTMLContainsContent() {
        let doc = Document(
            title: "Test",
            content: "The actual document content goes here.",
            category: .article
        )
        app.documentManager.createDocument(doc)

        let exported = app.exportDocument(id: doc.id, format: .html)

        XCTAssertNotNil(exported)
        XCTAssertTrue(exported!.contains("The actual document content goes here."))
    }

    func testExportAsHTMLContainsMetadata() {
        let doc = Document(
            title: "Test",
            content: "Content",
            category: .novel
        )
        app.documentManager.createDocument(doc)

        let exported = app.exportDocument(id: doc.id, format: .html)

        XCTAssertNotNil(exported)
        XCTAssertTrue(exported!.contains("Category: Novel"))
        XCTAssertTrue(exported!.contains("Word Count:"))
        XCTAssertTrue(exported!.contains("Created:"))
    }

    func testExportAsHTMLHasProperStructure() {
        let doc = Document(title: "Test", content: "Content", category: .article)
        app.documentManager.createDocument(doc)

        let exported = app.exportDocument(id: doc.id, format: .html)

        XCTAssertNotNil(exported)
        XCTAssertTrue(exported!.contains("<head>"))
        XCTAssertTrue(exported!.contains("</head>"))
        XCTAssertTrue(exported!.contains("<body>"))
        XCTAssertTrue(exported!.contains("</body>"))
        XCTAssertTrue(exported!.contains("<meta charset=\"UTF-8\">"))
    }

    func testExportAsHTMLContainsStyles() {
        let doc = Document(title: "Test", content: "Content", category: .article)
        app.documentManager.createDocument(doc)

        let exported = app.exportDocument(id: doc.id, format: .html)

        XCTAssertNotNil(exported)
        XCTAssertTrue(exported!.contains("<style>"))
        XCTAssertTrue(exported!.contains("</style>"))
        XCTAssertTrue(exported!.contains("font-family"))
    }

    func testExportAsHTMLWithDifferentCategories() {
        let categories: [TemplateCategory] = [.novel, .shortStory, .blogPost, .poetry]

        for category in categories {
            let doc = Document(title: "Test \(category.rawValue)", content: "Content", category: category)
            app.documentManager.createDocument(doc)

            let exported = app.exportDocument(id: doc.id, format: .html)

            XCTAssertNotNil(exported)
            XCTAssertTrue(exported!.contains("Category: \(category.rawValue)"))
        }
    }

    // MARK: - Export Error Cases

    func testExportNonexistentDocument() {
        let invalidId = UUID()

        let markdownExport = app.exportDocument(id: invalidId, format: .markdown)
        let plainExport = app.exportDocument(id: invalidId, format: .plainText)
        let htmlExport = app.exportDocument(id: invalidId, format: .html)

        XCTAssertNil(markdownExport)
        XCTAssertNil(plainExport)
        XCTAssertNil(htmlExport)
    }

    func testExportDeletedDocument() {
        let doc = Document(title: "To Delete", content: "Content", category: .article)
        app.documentManager.createDocument(doc)
        app.documentManager.deleteDocument(id: doc.id)

        let exported = app.exportDocument(id: doc.id)

        XCTAssertNil(exported)
    }

    // MARK: - Export Format Enum Tests

    func testExportFormatCases() {
        // Ensure all expected cases exist
        let formats: [ExportFormat] = [.markdown, .plainText, .html]
        XCTAssertEqual(formats.count, 3)
    }

    // MARK: - Export with Special Content

    func testExportWithUnicodeContent() {
        let doc = Document(
            title: "Unicode Test",
            content: "Hello 世界! 🎉 Émojis and ñ characters.",
            category: .article
        )
        app.documentManager.createDocument(doc)

        let markdownExport = app.exportDocument(id: doc.id, format: .markdown)
        let plainExport = app.exportDocument(id: doc.id, format: .plainText)
        let htmlExport = app.exportDocument(id: doc.id, format: .html)

        XCTAssertTrue(markdownExport?.contains("世界") ?? false)
        XCTAssertTrue(plainExport?.contains("🎉") ?? false)
        XCTAssertTrue(htmlExport?.contains("ñ") ?? false)
    }

    func testExportWithLongContent() {
        let longContent = String(repeating: "This is a test sentence. ", count: 1000)
        let doc = Document(title: "Long Document", content: longContent, category: .novel)
        app.documentManager.createDocument(doc)

        let exported = app.exportDocument(id: doc.id, format: .markdown)

        XCTAssertNotNil(exported)
        XCTAssertTrue(exported!.contains(longContent))
    }

    func testExportWithMultilineContent() {
        let multilineContent = """
        Line 1
        Line 2
        Line 3

        New paragraph here.

        Another paragraph.
        """
        let doc = Document(title: "Multiline", content: multilineContent, category: .article)
        app.documentManager.createDocument(doc)

        let plainExport = app.exportDocument(id: doc.id, format: .plainText)

        XCTAssertEqual(plainExport, multilineContent)
    }
}
