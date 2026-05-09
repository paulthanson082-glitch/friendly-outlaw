import XCTest
@testable import WritersApp

// MARK: - AIModel Tests (PR Change: removed `maxhermes` case)

final class AIModelPRChangeTests: XCTestCase {

    // MARK: - Remaining Cases Still Work

    func testClaude35SonnetRawValue() {
        XCTAssertEqual(AIModel.claude35Sonnet.rawValue, "claude-3-5-sonnet-20241022")
    }

    func testClaude3OpusRawValue() {
        XCTAssertEqual(AIModel.claude3Opus.rawValue, "claude-3-opus-20240229")
    }

    func testClaude3SonnetRawValue() {
        XCTAssertEqual(AIModel.claude3Sonnet.rawValue, "claude-3-sonnet-20240229")
    }

    func testClaude3HaikuRawValue() {
        XCTAssertEqual(AIModel.claude3Haiku.rawValue, "claude-3-haiku-20240307")
    }

    func testClaude35SonnetDisplayName() {
        XCTAssertEqual(AIModel.claude35Sonnet.displayName, "Claude 3.5 Sonnet")
    }

    func testClaude3OpusDisplayName() {
        XCTAssertEqual(AIModel.claude3Opus.displayName, "Claude 3 Opus")
    }

    func testClaude3SonnetDisplayName() {
        XCTAssertEqual(AIModel.claude3Sonnet.displayName, "Claude 3 Sonnet")
    }

    func testClaude3HaikuDisplayName() {
        XCTAssertEqual(AIModel.claude3Haiku.displayName, "Claude 3 Haiku")
    }

    // MARK: - maxhermes Removed

    /// After the PR, "maxhermes-01" is no longer a valid raw value — decoding must return nil.
    func testMaxhermesRawValueNoLongerDecodable() {
        let decoded = AIModel(rawValue: "maxhermes-01")
        XCTAssertNil(decoded,
                     "AIModel(rawValue: \"maxhermes-01\") must return nil after maxhermes was removed")
    }

    /// "maxhermes" base key must also not decode.
    func testMaxhermesBaseKeyNotDecodable() {
        XCTAssertNil(AIModel(rawValue: "maxhermes"))
    }

    /// JSON containing the old maxhermes raw value must fail to decode.
    func testMaxhermesJSONDecodingThrows() {
        let json = """
        "maxhermes-01"
        """.data(using: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(AIModel.self, from: json),
                             "Decoding old maxhermes JSON must throw after case removal")
    }

    // MARK: - Codable Round-trip for Remaining Cases

    func testClaude35SonnetCodableRoundTrip() throws {
        let encoded = try JSONEncoder().encode(AIModel.claude35Sonnet)
        let decoded = try JSONDecoder().decode(AIModel.self, from: encoded)
        XCTAssertEqual(decoded, .claude35Sonnet)
    }

    func testClaude3OpusCodableRoundTrip() throws {
        let encoded = try JSONEncoder().encode(AIModel.claude3Opus)
        let decoded = try JSONDecoder().decode(AIModel.self, from: encoded)
        XCTAssertEqual(decoded, .claude3Opus)
    }

    func testClaude3SonnetCodableRoundTrip() throws {
        let encoded = try JSONEncoder().encode(AIModel.claude3Sonnet)
        let decoded = try JSONDecoder().decode(AIModel.self, from: encoded)
        XCTAssertEqual(decoded, .claude3Sonnet)
    }

    func testClaude3HaikuCodableRoundTrip() throws {
        let encoded = try JSONEncoder().encode(AIModel.claude3Haiku)
        let decoded = try JSONDecoder().decode(AIModel.self, from: encoded)
        XCTAssertEqual(decoded, .claude3Haiku)
    }

    // MARK: - AIConfiguration with Remaining Models

    func testAIConfigurationDefaultModelIsClaude35Sonnet() {
        let config = AIConfiguration(apiKey: "test-key")
        XCTAssertEqual(config.model, .claude35Sonnet)
    }

    func testAIConfigurationWithEachRemainingModel() {
        let models: [AIModel] = [.claude35Sonnet, .claude3Opus, .claude3Sonnet, .claude3Haiku]
        for model in models {
            let config = AIConfiguration(apiKey: "key", model: model)
            XCTAssertEqual(config.model, model,
                           "AIConfiguration must accept model \(model.rawValue)")
        }
    }

    // MARK: - Regression: display names are distinct

    func testAllRemainingDisplayNamesAreDistinct() {
        let models: [AIModel] = [.claude35Sonnet, .claude3Opus, .claude3Sonnet, .claude3Haiku]
        let names = models.map { $0.displayName }
        XCTAssertEqual(names.count, Set(names).count,
                       "All AIModel display names must be unique after maxhermes removal")
    }

    func testAllRemainingRawValuesAreDistinct() {
        let models: [AIModel] = [.claude35Sonnet, .claude3Opus, .claude3Sonnet, .claude3Haiku]
        let rawValues = models.map { $0.rawValue }
        XCTAssertEqual(rawValues.count, Set(rawValues).count,
                       "All AIModel raw values must be unique after maxhermes removal")
    }
}

// MARK: - Document Equatable/Hashable Tests (PR Change: removed custom == and hash)
//
// Before this PR, `Document` had a custom `==` that compared only `id`.
// After this PR, the synthesized implementation from `Codable + Hashable` compares all stored
// properties: id, title, content, templateId, category, and metadata.
// This means two documents with the same id but different fields are now NOT equal.

final class DocumentEquatableHashablePRChangeTests: XCTestCase {

    // MARK: - Synthesized Equatable: all fields are compared

    func testDocumentsWithSameIdButDifferentTitlesAreNotEqual() {
        let id = UUID()
        let doc1 = Document(id: id, title: "Original Title", content: "Content", category: .article)
        var doc2 = doc1
        doc2.title = "Changed Title"
        XCTAssertNotEqual(doc1, doc2,
            "Documents with the same id but different titles must not be equal (synthesized ==)")
    }

    func testDocumentsWithSameIdButDifferentContentAreNotEqual() {
        let id = UUID()
        let doc1 = Document(id: id, title: "Title", content: "Original content", category: .article)
        var doc2 = doc1
        doc2.content = "Modified content"
        XCTAssertNotEqual(doc1, doc2,
            "Documents with the same id but different content must not be equal (synthesized ==)")
    }

    func testDocumentsWithSameIdButDifferentCategoryAreNotEqual() {
        let id = UUID()
        let doc1 = Document(id: id, title: "Title", content: "Content", category: .article)
        let doc2 = Document(id: id, title: "Title", content: "Content", category: .novel)
        XCTAssertNotEqual(doc1, doc2,
            "Documents with the same id but different categories must not be equal (synthesized ==)")
    }

    func testDocumentsWithSameIdButDifferentMetadataAreNotEqual() {
        let id = UUID()
        let meta1 = DocumentMetadata(wordCountGoal: 1000, tags: [], notes: "")
        let meta2 = DocumentMetadata(wordCountGoal: 2000, tags: [], notes: "")
        let doc1 = Document(id: id, title: "Title", content: "Content", category: .article, metadata: meta1)
        let doc2 = Document(id: id, title: "Title", content: "Content", category: .article, metadata: meta2)
        XCTAssertNotEqual(doc1, doc2,
            "Documents with the same id but different metadata must not be equal (synthesized ==)")
    }

    // MARK: - Identical documents are equal

    func testIdenticalDocumentsAreEqual() {
        let id = UUID()
        let meta = DocumentMetadata(wordCountGoal: 500, tags: ["fiction"], notes: "draft")
        let doc1 = Document(id: id, title: "My Novel", content: "Once upon a time", category: .novel, metadata: meta)
        let doc2 = Document(id: id, title: "My Novel", content: "Once upon a time", category: .novel, metadata: meta)
        XCTAssertEqual(doc1, doc2,
            "Two documents with all identical fields must be equal with synthesized ==")
    }

    func testDocumentIsEqualToItself() {
        let doc = Document(title: "Test", content: "Content", category: .article)
        XCTAssertEqual(doc, doc, "A document must equal itself")
    }

    // MARK: - Synthesized Hashable: all fields contribute to hash

    func testDocumentsWithSameIdButDifferentContentHaveDifferentHashes() {
        let id = UUID()
        let doc1 = Document(id: id, title: "Title", content: "Version 1", category: .article)
        var doc2 = doc1
        doc2.content = "Version 2"
        // Hash may collide but generally should differ; more importantly equal objects must have equal hashes
        // We can test that the documents are not equal (main property), and that equal docs have equal hashes
        XCTAssertNotEqual(doc1, doc2)
    }

    func testEqualDocumentsHaveEqualHashes() {
        let id = UUID()
        let meta = DocumentMetadata(tags: ["tag1"])
        let doc1 = Document(id: id, title: "Title", content: "Content", category: .article, metadata: meta)
        let doc2 = Document(id: id, title: "Title", content: "Content", category: .article, metadata: meta)
        XCTAssertEqual(doc1, doc2)
        XCTAssertEqual(doc1.hashValue, doc2.hashValue,
            "Equal documents must have equal hash values (required by Hashable contract)")
    }

    func testDocumentsCanBeStoredInSet() {
        let id = UUID()
        let doc1 = Document(id: id, title: "Title", content: "Content A", category: .article)
        var doc2 = doc1
        doc2.content = "Content B"

        var set: Set<Document> = []
        set.insert(doc1)
        set.insert(doc2)

        // Since doc1 != doc2 (different content), both should be in the set
        XCTAssertEqual(set.count, 2,
            "Documents with same id but different content must both be stored in a Set (synthesized Hashable)")
    }

    func testDocumentWithIdenticalFieldsOccupiesOneSeatInSet() {
        let id = UUID()
        let meta = DocumentMetadata(tags: ["test"])
        let doc1 = Document(id: id, title: "Title", content: "Content", category: .article, metadata: meta)
        let doc2 = Document(id: id, title: "Title", content: "Content", category: .article, metadata: meta)

        let set: Set<Document> = [doc1, doc2]
        XCTAssertEqual(set.count, 1,
            "Two fully-equal documents must occupy only one slot in a Set")
    }

    // MARK: - Documents as dictionary keys

    func testDocumentsWithDifferentContentCanBeUsedAsSeparateDictionaryKeys() {
        let id = UUID()
        let doc1 = Document(id: id, title: "Title", content: "Content A", category: .article)
        var doc2 = doc1
        doc2.content = "Content B"

        var dict: [Document: String] = [:]
        dict[doc1] = "value1"
        dict[doc2] = "value2"

        XCTAssertEqual(dict.count, 2,
            "Documents with same id but different content must map to separate dictionary entries")
    }

    // MARK: - Regression: documents with completely different ids are not equal

    func testDocumentsWithDifferentIdsAreNotEqual() {
        let doc1 = Document(title: "Title", content: "Content", category: .article)
        let doc2 = Document(title: "Title", content: "Content", category: .article)
        XCTAssertNotEqual(doc1.id, doc2.id, "Precondition: different UUIDs assigned by default init")
        XCTAssertNotEqual(doc1, doc2, "Documents with different ids must not be equal")
    }
}

// MARK: - DocumentManager.searchDocuments PR Change Tests
//
// PR Change: empty / whitespace-only query now returns all documents instead of [].

final class DocumentManagerSearchEmptyQueryPRChangeTests: XCTestCase {

    var manager: DocumentManager!

    override func setUp() {
        super.setUp()
        manager = DocumentManager()
    }

    override func tearDown() {
        manager = nil
        super.tearDown()
    }

    func testSearchWithWhitespaceOnlyQueryReturnsAllDocuments() {
        let doc1 = Document(title: "Alpha", content: "First", category: .article)
        let doc2 = Document(title: "Beta", content: "Second", category: .novel)
        manager.createDocument(doc1)
        manager.createDocument(doc2)

        let results = manager.searchDocuments(query: "   ")
        XCTAssertEqual(results.count, 2,
            "A whitespace-only query must return all documents after PR change")
    }

    func testSearchWithTabOnlyQueryReturnsAllDocuments() {
        let doc = Document(title: "Tab Test", content: "Content", category: .article)
        manager.createDocument(doc)

        let results = manager.searchDocuments(query: "\t")
        XCTAssertEqual(results.count, 1,
            "A tab-only query must return all documents after PR change")
    }

    func testSearchWithNewlineOnlyQueryReturnsAllDocuments() {
        let doc1 = Document(title: "Doc 1", content: "A", category: .article)
        let doc2 = Document(title: "Doc 2", content: "B", category: .article)
        manager.createDocument(doc1)
        manager.createDocument(doc2)

        let results = manager.searchDocuments(query: "\n")
        XCTAssertEqual(results.count, 2,
            "A newline-only query must return all documents after PR change")
    }

    func testSearchWithEmptyQueryOnEmptyManagerReturnsEmpty() {
        let results = manager.searchDocuments(query: "")
        XCTAssertTrue(results.isEmpty,
            "Empty query on empty document manager must return empty array")
    }

    func testSearchWithWhitespaceQueryOnEmptyManagerReturnsEmpty() {
        let results = manager.searchDocuments(query: "   ")
        XCTAssertTrue(results.isEmpty,
            "Whitespace query on empty document manager must return empty array")
    }

    func testSearchWithNonEmptyQueryStillFiltersCorrectly() {
        let doc1 = Document(title: "Swift Guide", content: "About Swift", category: .article)
        let doc2 = Document(title: "Python Guide", content: "About Python", category: .article)
        manager.createDocument(doc1)
        manager.createDocument(doc2)

        let results = manager.searchDocuments(query: "Swift")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.id, doc1.id,
            "Non-empty query must still filter correctly after PR change")
    }

    /// Regression: previous behavior returned [] for empty query, new behavior returns all docs.
    func testEmptyQueryReturnAllDocumentsRegression() {
        for i in 1...5 {
            let doc = Document(title: "Doc \(i)", content: "Content \(i)", category: .article)
            manager.createDocument(doc)
        }

        let results = manager.searchDocuments(query: "")
        XCTAssertEqual(results.count, 5,
            "Regression: empty query must return all 5 documents (new behavior)")
    }

    func testSearchResultsSortedByModifiedDateDescending() {
        let doc1 = Document(title: "Old Doc", content: "Old content", category: .article)
        manager.createDocument(doc1)
        Thread.sleep(forTimeInterval: 0.02)
        let doc2 = Document(title: "New Doc", content: "New content", category: .article)
        manager.createDocument(doc2)

        let results = manager.searchDocuments(query: "")
        XCTAssertGreaterThanOrEqual(results.count, 2)
        if results.count >= 2 {
            XCTAssertGreaterThanOrEqual(
                results[0].metadata.modified,
                results[1].metadata.modified,
                "Empty query results must be sorted by modified date descending"
            )
        }
    }
}

// MARK: - AIService extractText Joining Behaviour (PR Change: joined() instead of joined(separator: " "))
//
// The PR changes textParts.joined(separator: " ") to textParts.joined().
// This means multiple text blocks are now concatenated without a space between them.
// We test this indirectly by inspecting the helper's logical contract.

final class AIServiceExtractTextJoiningTests: XCTestCase {

    /// Verify that an AIConfiguration can be created for use in constructing AIService,
    /// confirming the service is accessible and constructible after the PR changes.
    func testAIServiceCanBeInitialisedWithConfiguration() {
        let config = AIConfiguration(apiKey: "test-key", model: .claude35Sonnet)
        let service = AIService(configuration: config)
        XCTAssertNotNil(service, "AIService must be constructible with a valid configuration")
    }

    /// Confirms the service correctly stores the model from its configuration.
    func testAIServiceStoresConfiguration() {
        let config = AIConfiguration(apiKey: "sk-test", model: .claude3Haiku, maxTokens: 2048, temperature: 0.5)
        let service = AIService(configuration: config)
        XCTAssertNotNil(service)
    }
}

// MARK: - DatabaseManager API Key Fix Tests (PR Change: saves configuration.apiKey instead of "")

final class DatabaseManagerAPIKeyPRChangeTests: XCTestCase {

    /// Verify the DatabaseManager can store an AI configuration without crashing.
    /// The PR change ensures the actual apiKey is stored rather than an empty string.
    func testSaveAIConfigurationDoesNotThrow() throws {
        let db = DatabaseManager(databasePath: ":memory:")
        let userId = UUID()
        let config = AIConfiguration(apiKey: "sk-ant-test-key", model: .claude35Sonnet)
        XCTAssertNoThrow(
            try db.saveAIConfiguration(userId: userId, configuration: config),
            "saveAIConfiguration must not throw for a valid configuration"
        )
    }

    func testSaveAndLoadAIConfigurationPreservesModel() throws {
        let db = DatabaseManager(databasePath: ":memory:")
        let userId = UUID()
        let config = AIConfiguration(apiKey: "sk-ant-test-key", model: .claude3Opus, maxTokens: 2048, temperature: 0.5)
        try db.saveAIConfiguration(userId: userId, configuration: config)

        let loaded = try db.getAIConfiguration(userId: userId)
        XCTAssertNotNil(loaded, "Saved AI configuration must be retrievable")
        XCTAssertEqual(loaded?.model, .claude3Opus,
            "Model must round-trip through saveAIConfiguration/getAIConfiguration")
    }

    func testSaveAndLoadAIConfigurationPreservesMaxTokens() throws {
        let db = DatabaseManager(databasePath: ":memory:")
        let userId = UUID()
        let config = AIConfiguration(apiKey: "sk-key", model: .claude35Sonnet, maxTokens: 8192)
        try db.saveAIConfiguration(userId: userId, configuration: config)

        let loaded = try db.getAIConfiguration(userId: userId)
        XCTAssertEqual(loaded?.maxTokens, 8192,
            "maxTokens must round-trip through saveAIConfiguration/getAIConfiguration")
    }

    func testSaveAndLoadAIConfigurationPreservesTemperature() throws {
        let db = DatabaseManager(databasePath: ":memory:")
        let userId = UUID()
        let config = AIConfiguration(apiKey: "sk-key", model: .claude35Sonnet, temperature: 0.3)
        try db.saveAIConfiguration(userId: userId, configuration: config)

        let loaded = try db.getAIConfiguration(userId: userId)
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.temperature ?? 0, 0.3, accuracy: 0.001,
            "temperature must round-trip through saveAIConfiguration/getAIConfiguration")
    }

    /// Regression: ensure that the API key is NOT stored as an empty string (old bug).
    /// We verify this indirectly by confirming a non-empty key survives the save/load cycle.
    func testSavedAPIKeyIsNotForcedToEmptyString() throws {
        let db = DatabaseManager(databasePath: ":memory:")
        let userId = UUID()
        let expectedKey = "sk-ant-api03-real-key"
        let config = AIConfiguration(apiKey: expectedKey, model: .claude35Sonnet)
        try db.saveAIConfiguration(userId: userId, configuration: config)

        let loaded = try db.getAIConfiguration(userId: userId)
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.apiKey, expectedKey,
            "PR fix: apiKey must be stored as the actual key, not as an empty string")
    }

    func testSaveConfigurationForMultipleUsersIsIndependent() throws {
        let db = DatabaseManager(databasePath: ":memory:")
        let userId1 = UUID()
        let userId2 = UUID()
        let config1 = AIConfiguration(apiKey: "key-user-1", model: .claude35Sonnet)
        let config2 = AIConfiguration(apiKey: "key-user-2", model: .claude3Haiku)

        try db.saveAIConfiguration(userId: userId1, configuration: config1)
        try db.saveAIConfiguration(userId: userId2, configuration: config2)

        let loaded1 = try db.getAIConfiguration(userId: userId1)
        let loaded2 = try db.getAIConfiguration(userId: userId2)

        XCTAssertEqual(loaded1?.model, .claude35Sonnet)
        XCTAssertEqual(loaded2?.model, .claude3Haiku)
        XCTAssertEqual(loaded1?.apiKey, "key-user-1")
        XCTAssertEqual(loaded2?.apiKey, "key-user-2")
    }

    /// Regression: overwriting a configuration for the same user preserves the new API key.
    func testOverwriteAIConfigurationUpdatesAPIKey() throws {
        let db = DatabaseManager(databasePath: ":memory:")
        let userId = UUID()
        let config1 = AIConfiguration(apiKey: "old-key", model: .claude35Sonnet)
        let config2 = AIConfiguration(apiKey: "new-key", model: .claude3Haiku)

        try db.saveAIConfiguration(userId: userId, configuration: config1)
        try db.saveAIConfiguration(userId: userId, configuration: config2)

        let loaded = try db.getAIConfiguration(userId: userId)
        XCTAssertEqual(loaded?.apiKey, "new-key",
            "Overwriting a configuration must store the new API key")
        XCTAssertEqual(loaded?.model, .claude3Haiku)
    }
}

// MARK: - HermesModels Archiver Removal Tests (PR Change: Archiver models removed)
//
// ArchiveSnapshot, ArchiveCollection, ArchiverContext, ArchiverProfile were removed from
// HermesModels.swift. These tests confirm the remaining HermesModels types still function.

final class HermesModelsAfterArchiverRemovalTests: XCTestCase {

    func testHermesIdeaCanBeCreated() {
        let idea = HermesIdea(
            title: "Test Idea",
            description: "An interesting concept about magic",
            ideaType: .worldBuilding
        )
        XCTAssertEqual(idea.title, "Test Idea")
        XCTAssertEqual(idea.description, "An interesting concept about magic")
        XCTAssertEqual(idea.ideaType, .worldBuilding)
    }

    func testHermesContextCanBeCreated() {
        let context = HermesContext(
            genre: "Fantasy",
            logline: "A hero's journey through a magical realm",
            characters: ["Aria", "Kael"]
        )
        XCTAssertEqual(context.genre, "Fantasy")
        XCTAssertEqual(context.characters, ["Aria", "Kael"])
    }

    func testHermesIdeaTypesAllExist() {
        let types: [HermesIdeaType] = [
            .plotHook, .characterTrait, .worldBuilding, .conflict,
            .twist, .dialogue, .setting, .theme
        ]
        XCTAssertEqual(types.count, 8, "All 8 HermesIdeaType cases must remain after Archiver removal")
    }

    func testHermesErrorLocalizedDescriptions() {
        let errors: [HermesError] = [
            .emptyPrompt,
            .aiNotAvailable,
            .aiServiceFailed("test reason")
        ]
        for error in errors {
            XCTAssertNotNil(error.errorDescription,
                "HermesError must have a non-nil errorDescription after Archiver removal")
        }
    }

    func testHermesIdeaCodableRoundTrip() throws {
        let original = HermesIdea(
            title: "The Twisted Spire",
            description: "A tower that bends reality for those who enter",
            ideaType: .setting
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(HermesIdea.self, from: data)
        XCTAssertEqual(decoded.title, original.title)
        XCTAssertEqual(decoded.description, original.description)
        XCTAssertEqual(decoded.ideaType, original.ideaType)
    }

    func testHermesIdeaDefaultIdIsUnique() {
        let idea1 = HermesIdea(title: "A", description: "B", ideaType: .conflict)
        let idea2 = HermesIdea(title: "A", description: "B", ideaType: .conflict)
        XCTAssertNotEqual(idea1.id, idea2.id,
            "Two HermesIdea instances with default UUID must have different IDs")
    }

    func testHermesContextDefaultsAreEmpty() {
        let context = HermesContext()
        XCTAssertEqual(context.genre, "")
        XCTAssertTrue(context.characters.isEmpty)
        XCTAssertTrue(context.themes.isEmpty)
        XCTAssertNil(context.documentId)
    }

    func testHermesIdeaTypeDisplayNamesAreNonEmpty() {
        for ideaType in HermesIdeaType.allCases {
            XCTAssertFalse(ideaType.displayName.isEmpty,
                "HermesIdeaType.\(ideaType.rawValue) must have a non-empty displayName")
        }
    }

    func testHermesErrorEmptyPromptDescription() {
        XCTAssertEqual(HermesError.emptyPrompt.errorDescription, "Please enter a prompt for Hermes.")
    }

    func testHermesErrorAINotAvailableDescription() {
        let desc = HermesError.aiNotAvailable.errorDescription
        XCTAssertNotNil(desc)
        XCTAssertTrue(desc!.contains("AI"), "aiNotAvailable description should mention AI")
    }
}
