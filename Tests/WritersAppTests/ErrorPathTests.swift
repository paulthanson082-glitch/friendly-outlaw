import XCTest
@testable import WritersApp

/// Tests for error handling paths in WritersApp, especially AI-related errors
final class ErrorPathTests: XCTestCase {
    var app: WritersApp!

    override func setUp() {
        super.setUp()
        app = WritersApp()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // MARK: - AI Not Enabled Error Tests

    func testGetAIAssistanceWithoutAI() async {
        let doc = Document(title: "Test", content: "Content", category: .article)
        app.documentManager.createDocument(doc)

        do {
            _ = try await app.getAIAssistance(documentId: doc.id, type: .improveText)
            XCTFail("Should have thrown AIError.aiNotEnabled")
        } catch let error as AIError {
            XCTAssertEqual(error, .aiNotEnabled)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testContinueDocumentWithoutAI() async {
        let doc = Document(title: "Test", content: "Content", category: .article)
        app.documentManager.createDocument(doc)

        do {
            _ = try await app.continueDocument(documentId: doc.id)
            XCTFail("Should have thrown AIError.aiNotEnabled")
        } catch let error as AIError {
            XCTAssertEqual(error, .aiNotEnabled)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testImproveDocumentWithoutAI() async {
        let doc = Document(title: "Test", content: "Content", category: .article)
        app.documentManager.createDocument(doc)

        do {
            _ = try await app.improveDocument(documentId: doc.id)
            XCTFail("Should have thrown AIError.aiNotEnabled")
        } catch let error as AIError {
            XCTAssertEqual(error, .aiNotEnabled)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testGenerateDocumentTitlesWithoutAI() async {
        let doc = Document(title: "Test", content: "Content", category: .article)
        app.documentManager.createDocument(doc)

        do {
            _ = try await app.generateDocumentTitles(documentId: doc.id)
            XCTFail("Should have thrown AIError.aiNotEnabled")
        } catch let error as AIError {
            XCTAssertEqual(error, .aiNotEnabled)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testAnalyzeDocumentWithoutAI() async {
        let doc = Document(title: "Test", content: "Content", category: .article)
        app.documentManager.createDocument(doc)

        do {
            _ = try await app.analyzeDocument(documentId: doc.id)
            XCTFail("Should have thrown AIError.aiNotEnabled")
        } catch let error as AIError {
            XCTAssertEqual(error, .aiNotEnabled)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testGetDocumentInsightsWithoutAI() async {
        let doc = Document(title: "Test", content: "Content", category: .article)
        app.documentManager.createDocument(doc)

        do {
            _ = try await app.getDocumentInsights(documentId: doc.id)
            XCTFail("Should have thrown AIError.aiNotEnabled")
        } catch let error as AIError {
            XCTAssertEqual(error, .aiNotEnabled)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testBrainstormIdeasWithoutAI() async {
        do {
            _ = try await app.brainstormIdeas(topic: "Science fiction")
            XCTFail("Should have thrown AIError.aiNotEnabled")
        } catch let error as AIError {
            XCTAssertEqual(error, .aiNotEnabled)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testGenerateOutlineWithoutAI() async {
        do {
            _ = try await app.generateOutline(concept: "A mystery novel")
            XCTFail("Should have thrown AIError.aiNotEnabled")
        } catch let error as AIError {
            XCTAssertEqual(error, .aiNotEnabled)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testDevelopCharacterWithoutAI() async {
        do {
            _ = try await app.developCharacter(characterConcept: "A detective")
            XCTFail("Should have thrown AIError.aiNotEnabled")
        } catch let error as AIError {
            XCTAssertEqual(error, .aiNotEnabled)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Document Not Found Error Tests

    func testGetAIAssistanceWithInvalidDocument() async {
        let config = AIConfiguration(apiKey: "test-key")
        app.enableAI(configuration: config)

        let invalidId = UUID()

        do {
            _ = try await app.getAIAssistance(documentId: invalidId, type: .improveText)
            XCTFail("Should have thrown AIError.documentNotFound")
        } catch let error as AIError {
            XCTAssertEqual(error, .documentNotFound)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testContinueDocumentWithInvalidDocument() async {
        let config = AIConfiguration(apiKey: "test-key")
        app.enableAI(configuration: config)

        let invalidId = UUID()

        do {
            _ = try await app.continueDocument(documentId: invalidId)
            XCTFail("Should have thrown AIError.documentNotFound")
        } catch let error as AIError {
            XCTAssertEqual(error, .documentNotFound)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testImproveDocumentWithInvalidDocument() async {
        let config = AIConfiguration(apiKey: "test-key")
        app.enableAI(configuration: config)

        let invalidId = UUID()

        do {
            _ = try await app.improveDocument(documentId: invalidId)
            XCTFail("Should have thrown AIError.documentNotFound")
        } catch let error as AIError {
            XCTAssertEqual(error, .documentNotFound)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testGenerateDocumentTitlesWithInvalidDocument() async {
        let config = AIConfiguration(apiKey: "test-key")
        app.enableAI(configuration: config)

        let invalidId = UUID()

        do {
            _ = try await app.generateDocumentTitles(documentId: invalidId)
            XCTFail("Should have thrown AIError.documentNotFound")
        } catch let error as AIError {
            XCTAssertEqual(error, .documentNotFound)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testAnalyzeDocumentWithInvalidDocument() async {
        let config = AIConfiguration(apiKey: "test-key")
        app.enableAI(configuration: config)

        let invalidId = UUID()

        do {
            _ = try await app.analyzeDocument(documentId: invalidId)
            XCTFail("Should have thrown AIError.documentNotFound")
        } catch let error as AIError {
            XCTAssertEqual(error, .documentNotFound)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testGetDocumentInsightsWithInvalidDocument() async {
        let config = AIConfiguration(apiKey: "test-key")
        app.enableAI(configuration: config)

        let invalidId = UUID()

        do {
            _ = try await app.getDocumentInsights(documentId: invalidId)
            XCTFail("Should have thrown AIError.documentNotFound")
        } catch let error as AIError {
            XCTAssertEqual(error, .documentNotFound)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Enable/Disable AI Tests

    func testEnableAI() {
        XCTAssertFalse(app.isAIEnabled)

        let config = AIConfiguration(apiKey: "test-key")
        app.enableAI(configuration: config)

        XCTAssertTrue(app.isAIEnabled)
    }

    func testDisableAI() {
        let config = AIConfiguration(apiKey: "test-key")
        app.enableAI(configuration: config)
        XCTAssertTrue(app.isAIEnabled)

        app.disableAI()

        XCTAssertFalse(app.isAIEnabled)
    }

    func testInitWithAIConfiguration() {
        let config = AIConfiguration(apiKey: "test-key")
        let appWithAI = WritersApp(aiConfiguration: config)

        XCTAssertTrue(appWithAI.isAIEnabled)
    }

    func testReEnableAI() {
        let config1 = AIConfiguration(apiKey: "key-1", model: .claude3Haiku)
        app.enableAI(configuration: config1)
        XCTAssertTrue(app.isAIEnabled)

        app.disableAI()
        XCTAssertFalse(app.isAIEnabled)

        let config2 = AIConfiguration(apiKey: "key-2", model: .claude3Opus)
        app.enableAI(configuration: config2)
        XCTAssertTrue(app.isAIEnabled)
    }

    // MARK: - AIError Equatable Tests

    func testAIErrorEquatable() {
        XCTAssertEqual(AIError.aiNotEnabled, AIError.aiNotEnabled)
        XCTAssertEqual(AIError.documentNotFound, AIError.documentNotFound)
        XCTAssertNotEqual(AIError.aiNotEnabled, AIError.documentNotFound)
    }

    // MARK: - Document Manager Edge Cases

    func testGetNonexistentDocument() {
        let invalidId = UUID()
        let doc = app.documentManager.getDocument(id: invalidId)
        XCTAssertNil(doc)
    }

    func testDeleteNonexistentDocument() {
        let invalidId = UUID()
        // Should not crash
        app.documentManager.deleteDocument(id: invalidId)
        XCTAssertNil(app.documentManager.getDocument(id: invalidId))
    }

    func testCreateDocumentFromInvalidTemplate() {
        let invalidTemplateId = UUID()
        let doc = app.createDocumentFromTemplate(templateId: invalidTemplateId, values: [:])
        XCTAssertNil(doc)
    }

    // MARK: - Template Manager Edge Cases

    func testGetNonexistentTemplate() {
        let invalidId = UUID()
        let template = app.templateManager.getTemplate(id: invalidId)
        XCTAssertNil(template)
    }

    func testSearchTemplatesNoResults() {
        let results = app.templateManager.searchTemplates(query: "xyznonexistent123")
        XCTAssertEqual(results.count, 0)
    }

    func testGetTemplatesForEmptyCategory() {
        // Essay category has no default templates
        let results = app.templateManager.getTemplates(for: .essay)
        XCTAssertEqual(results.count, 0)
    }

    // MARK: - Statistics Edge Cases

    func testStatisticsWithNoDocuments() {
        let stats = app.getStatistics()

        XCTAssertEqual(stats.totalDocuments, 0)
        XCTAssertEqual(stats.totalWordCount, 0)
        XCTAssertEqual(stats.averageWordCount, 0)
        XCTAssertTrue(stats.documentsByCategory.isEmpty)
    }

    func testStatisticsWithMultipleDocuments() {
        let doc1 = Document(title: "Doc 1", content: "One two three", category: .novel)
        let doc2 = Document(title: "Doc 2", content: "Four five", category: .novel)
        let doc3 = Document(title: "Doc 3", content: "Six", category: .article)

        app.documentManager.createDocument(doc1)
        app.documentManager.createDocument(doc2)
        app.documentManager.createDocument(doc3)

        let stats = app.getStatistics()

        XCTAssertEqual(stats.totalDocuments, 3)
        XCTAssertEqual(stats.totalWordCount, 6)
        XCTAssertEqual(stats.averageWordCount, 2) // 6 / 3 = 2
        XCTAssertEqual(stats.documentsByCategory[.novel], 2)
        XCTAssertEqual(stats.documentsByCategory[.article], 1)
    }
}
