import XCTest
@testable import WritersApp

/// Comprehensive tests for DocumentManager operations
final class DocumentManagerTests: XCTestCase {
    var documentManager: DocumentManager!

    override func setUp() {
        super.setUp()
        documentManager = DocumentManager()
    }

    override func tearDown() {
        documentManager = nil
        super.tearDown()
    }

    // MARK: - Search Tests

    func testSearchDocumentsByTitle() {
        let doc1 = Document(title: "Swift Programming Guide", content: "Learn Swift basics", category: .article)
        let doc2 = Document(title: "Python Tutorial", content: "Learn Python basics", category: .article)
        let doc3 = Document(title: "Advanced Swift Patterns", content: "Design patterns", category: .article)

        documentManager.createDocument(doc1)
        documentManager.createDocument(doc2)
        documentManager.createDocument(doc3)

        let results = documentManager.searchDocuments(query: "Swift")
        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.contains { $0.id == doc1.id })
        XCTAssertTrue(results.contains { $0.id == doc3.id })
    }

    func testSearchDocumentsByContent() {
        let doc1 = Document(title: "Guide One", content: "This covers machine learning topics", category: .article)
        let doc2 = Document(title: "Guide Two", content: "This covers web development", category: .article)

        documentManager.createDocument(doc1)
        documentManager.createDocument(doc2)

        let results = documentManager.searchDocuments(query: "machine learning")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.id, doc1.id)
    }

    func testSearchDocumentsCaseInsensitive() {
        let doc = Document(title: "UPPERCASE TITLE", content: "lowercase content", category: .article)
        documentManager.createDocument(doc)

        let upperResults = documentManager.searchDocuments(query: "UPPERCASE")
        let lowerResults = documentManager.searchDocuments(query: "uppercase")
        let mixedResults = documentManager.searchDocuments(query: "UpperCase")

        XCTAssertEqual(upperResults.count, 1)
        XCTAssertEqual(lowerResults.count, 1)
        XCTAssertEqual(mixedResults.count, 1)
    }

    func testSearchDocumentsNoResults() {
        let doc = Document(title: "Test Document", content: "Some content", category: .article)
        documentManager.createDocument(doc)

        let results = documentManager.searchDocuments(query: "nonexistent")
        XCTAssertEqual(results.count, 0)
    }

    func testSearchDocumentsEmptyQuery() {
        let doc1 = Document(title: "Doc One", content: "Content", category: .article)
        let doc2 = Document(title: "Doc Two", content: "Content", category: .article)

        documentManager.createDocument(doc1)
        documentManager.createDocument(doc2)

        let results = documentManager.searchDocuments(query: "")
        XCTAssertTrue(results.isEmpty)
    }

    func testSearchDocumentsWhitespaceOnlyQueryReturnsAllDocuments() {
        let doc1 = Document(title: "Novel Draft", content: "Chapter one", category: .novel)
        let doc2 = Document(title: "Short Story", content: "Once upon a time", category: .shortStory)
        let doc3 = Document(title: "Tech Article", content: "Swift 5.9 features", category: .article)

        documentManager.createDocument(doc1)
        documentManager.createDocument(doc2)
        documentManager.createDocument(doc3)

        let results = documentManager.searchDocuments(query: "   ")
        XCTAssertEqual(results.count, 3)
    }

    func testSearchDocumentsNewlineTabQueryReturnsAllDocuments() {
        let doc1 = Document(title: "Essay One", content: "Content A", category: .essay)
        let doc2 = Document(title: "Essay Two", content: "Content B", category: .essay)

        documentManager.createDocument(doc1)
        documentManager.createDocument(doc2)

        let results = documentManager.searchDocuments(query: "\n\t")
        XCTAssertEqual(results.count, 2)
    }

    func testSearchDocumentsEmptyQueryOnEmptyManagerReturnsEmpty() {
        let results = documentManager.searchDocuments(query: "")
        XCTAssertEqual(results.count, 0)
    }

    func testSearchDocumentsResultsSortedByModifiedDescending() {
        var metadata1 = DocumentMetadata()
        metadata1.modified = Date(timeIntervalSinceNow: -200)
        let doc1 = Document(title: "Old Article", content: "swift basics", category: .article, metadata: metadata1)

        var metadata2 = DocumentMetadata()
        metadata2.modified = Date(timeIntervalSinceNow: -50)
        let doc2 = Document(title: "New Article", content: "swift advanced", category: .article, metadata: metadata2)

        documentManager.createDocument(doc1)
        documentManager.createDocument(doc2)

        let results = documentManager.searchDocuments(query: "swift")
        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[0].id, doc2.id) // more recently modified first
        XCTAssertEqual(results[1].id, doc1.id)
    }

    // MARK: - Update Tests

    func testUpdateDocument() {
        let doc = Document(title: "Original Title", content: "Original content", category: .article)
        documentManager.createDocument(doc)

        var updatedDoc = doc
        updatedDoc.title = "Updated Title"
        updatedDoc.content = "Updated content"
        documentManager.updateDocument(updatedDoc)

        let retrieved = documentManager.getDocument(id: doc.id)
        XCTAssertEqual(retrieved?.title, "Updated Title")
        XCTAssertEqual(retrieved?.content, "Updated content")
    }

    func testUpdateDocumentModifiesTimestamp() {
        let doc = Document(title: "Test", content: "Content", category: .article)
        documentManager.createDocument(doc)

        let originalModified = documentManager.getDocument(id: doc.id)?.metadata.modified

        // Small delay to ensure timestamp difference
        Thread.sleep(forTimeInterval: 0.01)

        var updatedDoc = doc
        updatedDoc.content = "New content"
        documentManager.updateDocument(updatedDoc)

        let newModified = documentManager.getDocument(id: doc.id)?.metadata.modified
        XCTAssertNotNil(originalModified)
        XCTAssertNotNil(newModified)
        XCTAssertGreaterThan(newModified!, originalModified!)
    }

    // MARK: - Category Filtering Tests

    func testGetDocumentsByCategory() {
        let novelDoc = Document(title: "My Novel", content: "Chapter 1", category: .novel)
        let articleDoc = Document(title: "Tech Article", content: "About tech", category: .article)
        let blogDoc = Document(title: "Blog Post", content: "My thoughts", category: .blogPost)
        let novelDoc2 = Document(title: "Another Novel", content: "Chapter 1", category: .novel)

        documentManager.createDocument(novelDoc)
        documentManager.createDocument(articleDoc)
        documentManager.createDocument(blogDoc)
        documentManager.createDocument(novelDoc2)

        let novels = documentManager.getDocuments(for: .novel)
        XCTAssertEqual(novels.count, 2)
        XCTAssertTrue(novels.allSatisfy { $0.category == .novel })

        let articles = documentManager.getDocuments(for: .article)
        XCTAssertEqual(articles.count, 1)
        XCTAssertEqual(articles.first?.title, "Tech Article")

        let essays = documentManager.getDocuments(for: .essay)
        XCTAssertEqual(essays.count, 0)
    }

    // MARK: - Mark Document Opened Tests

    func testMarkDocumentOpened() {
        let doc = Document(title: "Test", content: "Content", category: .article)
        documentManager.createDocument(doc)

        XCTAssertNil(documentManager.getDocument(id: doc.id)?.metadata.lastOpened)

        documentManager.markDocumentOpened(id: doc.id)

        let lastOpened = documentManager.getDocument(id: doc.id)?.metadata.lastOpened
        XCTAssertNotNil(lastOpened)
    }

    func testMarkDocumentOpenedWithInvalidId() {
        let invalidId = UUID()
        // Should not crash with invalid ID
        documentManager.markDocumentOpened(id: invalidId)
        XCTAssertNil(documentManager.getDocument(id: invalidId))
    }

    // MARK: - Total Word Count Tests

    func testGetTotalWordCount() {
        let doc1 = Document(title: "Doc 1", content: "One two three", category: .article) // 3 words
        let doc2 = Document(title: "Doc 2", content: "Four five six seven", category: .article) // 4 words
        let doc3 = Document(title: "Doc 3", content: "Eight nine", category: .article) // 2 words

        documentManager.createDocument(doc1)
        documentManager.createDocument(doc2)
        documentManager.createDocument(doc3)

        let totalWords = documentManager.getTotalWordCount()
        XCTAssertEqual(totalWords, 9)
    }

    func testGetTotalWordCountEmpty() {
        let totalWords = documentManager.getTotalWordCount()
        XCTAssertEqual(totalWords, 0)
    }

    // MARK: - Documents By Progress Tests

    func testGetDocumentsByProgress() {
        var metadata1 = DocumentMetadata()
        metadata1.wordCountGoal = 100
        let doc1 = Document(
            title: "Half Done",
            content: String(repeating: "word ", count: 50), // 50 words
            category: .novel,
            metadata: metadata1
        )

        var metadata2 = DocumentMetadata()
        metadata2.wordCountGoal = 100
        let doc2 = Document(
            title: "Almost Done",
            content: String(repeating: "word ", count: 90), // 90 words
            category: .novel,
            metadata: metadata2
        )

        let doc3 = Document(
            title: "No Goal",
            content: "Some content",
            category: .novel
        )

        documentManager.createDocument(doc1)
        documentManager.createDocument(doc2)
        documentManager.createDocument(doc3)

        let progressDocs = documentManager.getDocumentsByProgress()

        XCTAssertEqual(progressDocs.count, 2) // Only docs with goals
        XCTAssertEqual(progressDocs[0].document.title, "Almost Done") // Sorted by progress descending
        XCTAssertEqual(progressDocs[1].document.title, "Half Done")
        XCTAssertEqual(progressDocs[0].progress, 0.9, accuracy: 0.01)
        XCTAssertEqual(progressDocs[1].progress, 0.5, accuracy: 0.01)
    }

    func testGetDocumentsByProgressWithZeroGoal() {
        var metadata = DocumentMetadata()
        metadata.wordCountGoal = 0
        let doc = Document(
            title: "Zero Goal",
            content: "Content",
            category: .novel,
            metadata: metadata
        )

        documentManager.createDocument(doc)

        let progressDocs = documentManager.getDocumentsByProgress()
        XCTAssertEqual(progressDocs.count, 0) // Zero goal should be filtered out
    }

    // MARK: - Recent Documents Tests

    func testGetRecentDocuments() {
        for i in 1...15 {
            let doc = Document(title: "Doc \(i)", content: "Content", category: .article)
            documentManager.createDocument(doc)
        }

        let recentDocs = documentManager.getRecentDocuments()
        XCTAssertEqual(recentDocs.count, 10) // Default limit is 10
    }

    func testGetRecentDocumentsWithCustomLimit() {
        for i in 1...10 {
            let doc = Document(title: "Doc \(i)", content: "Content", category: .article)
            documentManager.createDocument(doc)
        }

        let recentDocs = documentManager.getRecentDocuments(limit: 5)
        XCTAssertEqual(recentDocs.count, 5)
    }

    func testGetRecentDocumentsWhenFewerThanLimit() {
        let doc1 = Document(title: "Doc 1", content: "Content", category: .article)
        let doc2 = Document(title: "Doc 2", content: "Content", category: .article)

        documentManager.createDocument(doc1)
        documentManager.createDocument(doc2)

        let recentDocs = documentManager.getRecentDocuments(limit: 10)
        XCTAssertEqual(recentDocs.count, 2)
    }

    // MARK: - Document Properties Tests

    func testDocumentCharacterCount() {
        let doc = Document(title: "Test", content: "Hello World!", category: .article)
        XCTAssertEqual(doc.characterCount, 12)
    }

    func testDocumentCharacterCountEmpty() {
        let doc = Document(title: "Test", content: "", category: .article)
        XCTAssertEqual(doc.characterCount, 0)
    }

    func testDocumentReadingTime() {
        // 200 words per minute is the rate
        let words = String(repeating: "word ", count: 400) // 400 words = 2 minutes
        let doc = Document(title: "Test", content: words, category: .article)
        XCTAssertEqual(doc.readingTime, 2)
    }

    func testDocumentReadingTimeMinimum() {
        let doc = Document(title: "Test", content: "Short", category: .article)
        XCTAssertEqual(doc.readingTime, 1) // Minimum is 1 minute
    }

    func testDocumentWordCountWithWhitespace() {
        let doc = Document(title: "Test", content: "  word1   word2  \n\n  word3  ", category: .article)
        XCTAssertEqual(doc.wordCount, 3)
    }

    func testDocumentWordCountEmpty() {
        let doc = Document(title: "Test", content: "", category: .article)
        XCTAssertEqual(doc.wordCount, 0)
    }

    func testDocumentWordCountOnlyWhitespace() {
        let doc = Document(title: "Test", content: "   \n\n\t   ", category: .article)
        XCTAssertEqual(doc.wordCount, 0)
    }

    // MARK: - Document Metadata Tests

    func testDocumentMetadataDefaults() {
        let metadata = DocumentMetadata()

        XCTAssertNil(metadata.lastOpened)
        XCTAssertNil(metadata.wordCountGoal)
        XCTAssertEqual(metadata.tags, [])
        XCTAssertEqual(metadata.notes, "")
    }

    func testDocumentMetadataCustomValues() {
        let metadata = DocumentMetadata(
            wordCountGoal: 5000,
            tags: ["fiction", "novel"],
            notes: "Work in progress"
        )

        XCTAssertEqual(metadata.wordCountGoal, 5000)
        XCTAssertEqual(metadata.tags, ["fiction", "novel"])
        XCTAssertEqual(metadata.notes, "Work in progress")
    }

    func testDocumentWithMetadata() {
        let metadata = DocumentMetadata(
            wordCountGoal: 10000,
            tags: ["sci-fi"],
            notes: "First draft"
        )
        let doc = Document(
            title: "Space Adventure",
            content: "Chapter 1",
            category: .novel,
            metadata: metadata
        )

        XCTAssertEqual(doc.metadata.wordCountGoal, 10000)
        XCTAssertEqual(doc.metadata.tags, ["sci-fi"])
        XCTAssertEqual(doc.metadata.notes, "First draft")
    }

    // MARK: - Document Identifiable Tests

    func testDocumentIdentifiable() {
        let doc1 = Document(title: "Doc 1", content: "", category: .article)
        let doc2 = Document(title: "Doc 2", content: "", category: .article)

        XCTAssertNotEqual(doc1.id, doc2.id)
    }

    func testDocumentWithCustomId() {
        let customId = UUID()
        let doc = Document(
            id: customId,
            title: "Test",
            content: "",
            category: .article
        )

        XCTAssertEqual(doc.id, customId)
    }
}
