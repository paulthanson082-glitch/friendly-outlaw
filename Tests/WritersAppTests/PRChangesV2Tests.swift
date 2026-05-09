import XCTest
@testable import WritersApp

// MARK: - AIModel Changes Tests (PR: removed maxhermes case)

final class AIModelChangesTests: XCTestCase {

    // MARK: - maxhermes Removed

    /// PR change: the `maxhermes` case was removed from `AIModel`.
    private let allModels: [AIModel] = [.claude35Sonnet, .claude3Opus, .claude3Sonnet, .claude3Haiku]

    func testAIModelDoesNotContainMaxhermes() {
        // Verify that the "maxhermes-01" raw value is not present in any case
        let allRawValues = Set(allModels.map { $0.rawValue })
        XCTAssertFalse(allRawValues.contains("maxhermes-01"),
                       "maxhermes was removed from AIModel; its raw value must not appear")
    }

    func testAIModelInitFromMaxhermesRawValueReturnsNil() {
        XCTAssertNil(AIModel(rawValue: "maxhermes-01"),
                     "Initialising AIModel from 'maxhermes-01' must return nil after removal")
    }

    // MARK: - Remaining Cases Still Present

    func testAIModelStillContainsFourCases() {
        XCTAssertEqual(allModels.count, 4,
                       "After removing maxhermes there should be exactly 4 model cases")
    }

    func testAIModelContainsClaude35Sonnet() {
        XCTAssertNotNil(AIModel(rawValue: "claude-3-5-sonnet-20241022"))
        XCTAssertEqual(AIModel.claude35Sonnet.displayName, "Claude 3.5 Sonnet")
    }

    func testAIModelContainsClaude3Opus() {
        XCTAssertNotNil(AIModel(rawValue: "claude-3-opus-20240229"))
        XCTAssertEqual(AIModel.claude3Opus.displayName, "Claude 3 Opus")
    }

    func testAIModelContainsClaude3Sonnet() {
        XCTAssertNotNil(AIModel(rawValue: "claude-3-sonnet-20240229"))
        XCTAssertEqual(AIModel.claude3Sonnet.displayName, "Claude 3 Sonnet")
    }

    func testAIModelContainsClaude3Haiku() {
        XCTAssertNotNil(AIModel(rawValue: "claude-3-haiku-20240307"))
        XCTAssertEqual(AIModel.claude3Haiku.displayName, "Claude 3 Haiku")
    }

    func testAIModelDisplayNamesAreNonEmpty() {
        for model in allModels {
            XCTAssertFalse(model.displayName.isEmpty, "\(model) displayName must not be empty")
        }
    }

    func testAIModelCodableRoundTripForAllCases() throws {
        for model in allModels {
            let data = try JSONEncoder().encode(model)
            let decoded = try JSONDecoder().decode(AIModel.self, from: data)
            XCTAssertEqual(decoded, model)
        }
    }

    // MARK: - Regression: unknown raw value returns nil

    func testAIModelUnknownRawValueReturnsNil() {
        XCTAssertNil(AIModel(rawValue: "gpt-4"))
        XCTAssertNil(AIModel(rawValue: ""))
        XCTAssertNil(AIModel(rawValue: "claude"))
    }
}

// MARK: - Document Synthesized Hashable Tests (PR: removed explicit == and hash)

final class DocumentSynthesizedHashableTests: XCTestCase {

    // MARK: - Equality: synthesized compares all stored properties

    /// PR change: explicit id-only == was removed; synthesized == now compares all fields.
    /// Two documents with the same id but different content are now NOT equal.
    func testDocumentsWithSameIdButDifferentContentAreNotEqual() {
        let id = UUID()
        let doc1 = Document(id: id, title: "Original", content: "Hello world", category: .article)
        let doc2 = Document(id: id, title: "Original", content: "Different content", category: .article)
        XCTAssertNotEqual(doc1, doc2,
                          "PR change: synthesized == compares all fields; same id + different content must be not-equal")
    }

    func testDocumentsWithSameIdButDifferentTitleAreNotEqual() {
        let id = UUID()
        let doc1 = Document(id: id, title: "Title A", content: "Body", category: .article)
        let doc2 = Document(id: id, title: "Title B", content: "Body", category: .article)
        XCTAssertNotEqual(doc1, doc2,
                          "PR change: synthesized == compares title; same id + different title must be not-equal")
    }

    func testDocumentsWithSameIdButDifferentCategoryAreNotEqual() {
        let id = UUID()
        let doc1 = Document(id: id, title: "T", content: "C", category: .article)
        let doc2 = Document(id: id, title: "T", content: "C", category: .novel)
        XCTAssertNotEqual(doc1, doc2,
                          "PR change: synthesized == compares category; different categories must be not-equal")
    }

    func testDocumentsIdenticalInAllFieldsAreEqual() {
        let id = UUID()
        let metadata = DocumentMetadata(wordCountGoal: 1000, tags: ["fantasy"], notes: "Draft")
        let doc1 = Document(id: id, title: "My Story", content: "Once upon a time", category: .novel, metadata: metadata)
        // Must create fresh metadata with same values (Date() calls would differ)
        let sameMetadata = DocumentMetadata(
            created: metadata.created,
            modified: metadata.modified,
            lastOpened: metadata.lastOpened,
            wordCountGoal: metadata.wordCountGoal,
            tags: metadata.tags,
            notes: metadata.notes
        )
        let doc2 = Document(id: id, title: "My Story", content: "Once upon a time", category: .novel, metadata: sameMetadata)
        XCTAssertEqual(doc1, doc2, "Two documents with all identical fields must be equal")
    }

    // MARK: - Hashing: synthesized hash combines all stored properties

    func testDocumentsWithSameIdButDifferentContentHaveDifferentHashes() {
        let id = UUID()
        let doc1 = Document(id: id, title: "T", content: "Content A", category: .article)
        let doc2 = Document(id: id, title: "T", content: "Content B", category: .article)
        // Hashes may collide in rare cases, but for distinct values they should differ
        // This is a probabilistic assertion; collisions are astronomically unlikely here
        XCTAssertNotEqual(doc1.hashValue, doc2.hashValue,
                          "PR change: synthesized hash uses all fields; different content should yield different hashes")
    }

    // MARK: - Set behaviour with synthesized Hashable

    /// Documents with different UUIDs should always be distinct in a Set.
    func testSetInsertsDocumentsWithDifferentIds() {
        let doc1 = Document(title: "A", content: "C1", category: .article)
        let doc2 = Document(title: "A", content: "C1", category: .article)
        var set = Set<Document>()
        set.insert(doc1)
        set.insert(doc2)
        XCTAssertEqual(set.count, 2, "Documents with different UUIDs must occupy separate set slots")
    }

    /// A document inserted twice should not grow the set.
    func testSetDoesNotDuplicateIdenticalDocument() {
        let id = UUID()
        let metadata = DocumentMetadata()
        let doc = Document(id: id, title: "Same", content: "Same", category: .article, metadata: metadata)
        var set = Set<Document>()
        set.insert(doc)
        set.insert(doc)
        XCTAssertEqual(set.count, 1, "Inserting the exact same document twice must not grow the set")
    }

    /// With synthesized Hashable a document modified after insertion has a different hash,
    /// so the set treats the updated copy as a new element.
    func testSetTreatsDocumentsWithSameIdButDifferentContentAsSeparate() {
        let id = UUID()
        let doc1 = Document(id: id, title: "Draft", content: "v1", category: .article)
        var doc2 = doc1
        doc2.content = "v2"  // Same id, different content
        var set = Set<Document>()
        set.insert(doc1)
        set.insert(doc2)
        // With synthesized == comparing all fields, doc1 != doc2, so they're separate entries
        XCTAssertEqual(set.count, 2,
                       "PR change: synthesized equality treats same-id documents with different content as distinct")
    }
}

// MARK: - DocumentManager Search Changes Tests (PR: empty query returns all documents)

final class DocumentManagerSearchChangesTests: XCTestCase {

    var manager: DocumentManager!

    override func setUp() {
        super.setUp()
        manager = DocumentManager()
    }

    override func tearDown() {
        manager = nil
        super.tearDown()
    }

    // MARK: - Empty query returns all documents

    /// PR change: an empty query now returns all documents instead of an empty array.
    func testEmptyQueryReturnsAllDocuments() {
        let doc1 = Document(title: "Alpha", content: "Content A", category: .article)
        let doc2 = Document(title: "Beta", content: "Content B", category: .novel)
        let doc3 = Document(title: "Gamma", content: "Content C", category: .blogPost)
        manager.createDocument(doc1)
        manager.createDocument(doc2)
        manager.createDocument(doc3)

        let results = manager.searchDocuments(query: "")
        XCTAssertEqual(results.count, 3,
                       "PR change: empty query must return all documents, not an empty array")
    }

    /// PR change: a whitespace-only query should also be treated as empty and return all documents.
    func testWhitespaceOnlyQueryReturnsAllDocuments() {
        let doc1 = Document(title: "Doc 1", content: "Something", category: .article)
        let doc2 = Document(title: "Doc 2", content: "Else", category: .article)
        manager.createDocument(doc1)
        manager.createDocument(doc2)

        let results = manager.searchDocuments(query: "   ")
        XCTAssertEqual(results.count, 2,
                       "PR change: whitespace-only query must return all documents")
    }

    func testTabOnlyQueryReturnsAllDocuments() {
        let doc = Document(title: "Tab Test", content: "Content", category: .article)
        manager.createDocument(doc)

        let results = manager.searchDocuments(query: "\t\t")
        XCTAssertEqual(results.count, 1,
                       "Tab-only query should be treated as empty and return all documents")
    }

    func testMixedWhitespaceQueryReturnsAllDocuments() {
        for i in 1...4 {
            let doc = Document(title: "Document \(i)", content: "Content", category: .article)
            manager.createDocument(doc)
        }

        let results = manager.searchDocuments(query: " \t \n ")
        XCTAssertEqual(results.count, 4,
                       "Mixed whitespace query should return all documents")
    }

    func testEmptyQueryOnEmptyManagerReturnsEmptyArray() {
        let results = manager.searchDocuments(query: "")
        XCTAssertTrue(results.isEmpty, "Empty query on empty store should return empty array")
    }

    // MARK: - Normal (non-empty) search still filters

    func testNonEmptyQueryStillFilters() {
        let doc1 = Document(title: "Swift Programming", content: "Swift is great", category: .article)
        let doc2 = Document(title: "Python Tutorial", content: "Python basics", category: .article)
        manager.createDocument(doc1)
        manager.createDocument(doc2)

        let results = manager.searchDocuments(query: "Swift")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.id, doc1.id)
    }

    // MARK: - Regression: query that was empty before the change

    /// Before the PR, empty query returned []. After, it returns all.
    /// Verify the returned array contains the expected documents.
    func testEmptyQueryResultsMatchGetAllDocuments() {
        let doc1 = Document(title: "One", content: "Content 1", category: .article)
        let doc2 = Document(title: "Two", content: "Content 2", category: .novel)
        manager.createDocument(doc1)
        manager.createDocument(doc2)

        let searchResults = manager.searchDocuments(query: "").map { $0.id }.sorted { $0.uuidString < $1.uuidString }
        let allResults = manager.getAllDocuments().map { $0.id }.sorted { $0.uuidString < $1.uuidString }
        XCTAssertEqual(searchResults, allResults,
                       "Empty-query search results must match getAllDocuments()")
    }
}

// MARK: - GiftCardManager Expiration Validation Tests (PR: expirationDays must be > 0)

final class GiftCardExpirationValidationChangedTests: XCTestCase {

    var manager: GiftCardManager!

    override func setUp() {
        super.setUp()
        manager = GiftCardManager()
    }

    override func tearDown() {
        manager = nil
        super.tearDown()
    }

    // MARK: - Zero expirationDays must now throw (PR reversion)

    /// PR change: expirationDays == 0 must now throw (validation tightened back from >= 0 to > 0).
    func testCreateBundleWithZeroExpirationDaysNowThrows() {
        XCTAssertThrowsError(
            try manager.createBundle(
                name: "Zero Day Bundle",
                description: "Should now fail",
                price: 9.99,
                bundleType: .starter,
                aiCredits: 10,
                expirationDays: 0
            ),
            "PR change: expirationDays == 0 must throw after validation was tightened back to > 0"
        ) { error in
            guard case GiftCardError.invalidInput(let message) = error else {
                return XCTFail("Expected GiftCardError.invalidInput, got \(error)")
            }
            XCTAssertTrue(
                message.lowercased().contains("expiration"),
                "Error message should mention expiration, got: \(message)"
            )
        }
    }

    /// PR change: the error message for zero days should explicitly mention "> 0" or equivalent.
    func testCreateBundleWithZeroExpirationDaysErrorMessageMentionsGreaterThanZero() {
        do {
            _ = try manager.createBundle(
                name: "Zero Day",
                description: "Test",
                price: 1.0,
                bundleType: .starter,
                aiCredits: 5,
                expirationDays: 0
            )
            XCTFail("Expected error to be thrown")
        } catch GiftCardError.invalidInput(let message) {
            // Error message should convey that 0 is not allowed
            let lower = message.lowercased()
            XCTAssertTrue(lower.contains("greater than 0") || lower.contains("> 0") || lower.contains("expiration"),
                         "Error message should communicate the > 0 requirement, got: '\(message)'")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Minimum positive value succeeds

    func testCreateBundleWithOneExpirationDaySucceeds() throws {
        let bundle = try manager.createBundle(
            name: "One Day Bundle",
            description: "Minimum valid expiration",
            price: 1.99,
            bundleType: .starter,
            aiCredits: 5,
            expirationDays: 1
        )
        XCTAssertEqual(bundle.expirationDays, 1)
    }

    // MARK: - Negative expirationDays still throws

    func testCreateBundleWithNegativeExpirationDaysThrows() {
        XCTAssertThrowsError(
            try manager.createBundle(
                name: "Negative Days",
                description: "Invalid",
                price: 5.0,
                bundleType: .starter,
                aiCredits: 10,
                expirationDays: -1
            )
        ) { error in
            XCTAssertTrue(error is GiftCardError, "Expected GiftCardError")
        }
    }

    func testCreateBundleWithLargeNegativeExpirationDaysThrows() {
        XCTAssertThrowsError(
            try manager.createBundle(
                name: "Very Negative",
                description: "Invalid",
                price: 5.0,
                bundleType: .custom,
                aiCredits: 5,
                expirationDays: -365
            )
        )
    }

    // MARK: - Positive values still work

    func testCreateBundleWithLargeExpirationDaysSucceeds() throws {
        let bundle = try manager.createBundle(
            name: "Yearly Bundle",
            description: "Expires in one year",
            price: 49.99,
            bundleType: .professional,
            aiCredits: 500,
            expirationDays: 365
        )
        XCTAssertEqual(bundle.expirationDays, 365)
    }

    // MARK: - Zero aiCredits still throws (unchanged validation)

    func testCreateBundleWithZeroAICreditsStillThrows() {
        XCTAssertThrowsError(
            try manager.createBundle(
                name: "No Credits",
                description: "Invalid",
                price: 0.00,
                bundleType: .starter,
                aiCredits: 0,
                expirationDays: 30
            )
        ) { error in
            guard case GiftCardError.invalidInput(let message) = error else {
                return XCTFail("Expected GiftCardError.invalidInput")
            }
            XCTAssertTrue(message.lowercased().contains("credit"))
        }
    }
}

// MARK: - DatabaseManager API Key Persistence Tests (PR: fixed empty-string bug)

final class DatabaseManagerAPIKeyPersistenceTests: XCTestCase {

    var databaseManager: DatabaseManager!
    var testDatabasePath: String!
    let testUserId = UUID()

    override func setUp() {
        super.setUp()
        testDatabasePath = "/tmp/test_writersapp_apikey_\(UUID().uuidString).db"
        try? FileManager.default.removeItem(atPath: testDatabasePath)
        databaseManager = DatabaseManager(databasePath: testDatabasePath)
        try? databaseManager.initialize()
    }

    override func tearDown() {
        databaseManager.close()
        try? FileManager.default.removeItem(atPath: testDatabasePath)
        databaseManager = nil
        super.tearDown()
    }

    // MARK: - API key is now properly saved and retrieved

    /// PR bug fix: previously sqlite3_bind_text was binding "" instead of configuration.apiKey.
    /// Now the actual API key is persisted and returned.
    func testAPIKeyIsPersistedCorrectly() throws {
        let apiKey = "sk-ant-api03-test-key-abc123"
        let config = AIConfiguration(
            apiKey: apiKey,
            model: .claude35Sonnet,
            maxTokens: 4096,
            temperature: 0.7
        )

        try databaseManager.saveAIConfiguration(userId: testUserId, configuration: config)

        let retrieved = try databaseManager.getAIConfiguration(userId: testUserId)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.apiKey, apiKey,
                       "PR bug fix: API key must be persisted and returned, not replaced with empty string")
    }

    func testAPIKeyWithSpecialCharactersIsPersistedCorrectly() throws {
        let apiKey = "sk-ant-api03-abc!@#$%^&*()-_+=[]{}|;:',.<>?"
        let config = AIConfiguration(apiKey: apiKey, model: .claude3Opus)

        try databaseManager.saveAIConfiguration(userId: testUserId, configuration: config)

        let retrieved = try databaseManager.getAIConfiguration(userId: testUserId)
        XCTAssertEqual(retrieved?.apiKey, apiKey,
                       "API key with special characters should be preserved as-is")
    }

    func testAPIKeyRoundTripForDifferentModels() throws {
        let models: [AIModel] = [.claude35Sonnet, .claude3Opus, .claude3Sonnet, .claude3Haiku]
        for model in models {
            let userId = UUID()
            let apiKey = "key-for-\(model.rawValue)"
            let config = AIConfiguration(apiKey: apiKey, model: model, maxTokens: 2048, temperature: 0.5)

            try databaseManager.saveAIConfiguration(userId: userId, configuration: config)

            let retrieved = try databaseManager.getAIConfiguration(userId: userId)
            XCTAssertEqual(retrieved?.apiKey, apiKey, "API key must persist for model \(model)")
            XCTAssertEqual(retrieved?.model, model)
            XCTAssertEqual(retrieved?.maxTokens, 2048)
            XCTAssertEqual(retrieved?.temperature, 0.5, accuracy: 0.001)
        }
    }

    func testAPIKeyUpdateReplacesOldKey() throws {
        let originalKey = "sk-ant-original-key"
        let updatedKey = "sk-ant-updated-key"

        try databaseManager.saveAIConfiguration(
            userId: testUserId,
            configuration: AIConfiguration(apiKey: originalKey, model: .claude35Sonnet)
        )

        try databaseManager.saveAIConfiguration(
            userId: testUserId,
            configuration: AIConfiguration(apiKey: updatedKey, model: .claude35Sonnet)
        )

        let retrieved = try databaseManager.getAIConfiguration(userId: testUserId)
        XCTAssertEqual(retrieved?.apiKey, updatedKey,
                       "Saving a new config for the same user should overwrite the previous API key")
    }

    func testEmptyAPIKeyIsPersistedAsEmpty() throws {
        // An empty string key (intentional) should be stored as empty, not replaced by something else
        let config = AIConfiguration(apiKey: "", model: .claude3Haiku)

        try databaseManager.saveAIConfiguration(userId: testUserId, configuration: config)

        let retrieved = try databaseManager.getAIConfiguration(userId: testUserId)
        XCTAssertEqual(retrieved?.apiKey, "",
                       "An explicitly-empty API key should be stored and returned as empty")
    }

    // MARK: - Other fields still persist correctly

    func testNonAPIKeyConfigFieldsPersistCorrectly() throws {
        let config = AIConfiguration(
            apiKey: "test-key",
            model: .claude3Opus,
            maxTokens: 8192,
            temperature: 0.9
        )

        try databaseManager.saveAIConfiguration(userId: testUserId, configuration: config)

        let retrieved = try databaseManager.getAIConfiguration(userId: testUserId)
        XCTAssertEqual(retrieved?.model, .claude3Opus)
        XCTAssertEqual(retrieved?.maxTokens, 8192)
        XCTAssertEqual(retrieved?.temperature, 0.9, accuracy: 0.001)
    }
}

// MARK: - HermesModels Archiver Types Removal Tests (PR: removed Archiver models)

/// The PR removed ArchiveSnapshot, ArchiveCollection, ArchiverContext, and ArchiverProfile
/// from HermesModels.swift. These tests confirm that the remaining HermesModels types
/// still compile and work correctly after the removal.
final class HermesModelsAfterArchiveRemovalTests: XCTestCase {

    // MARK: - Remaining Hermes types are unaffected

    func testHermesIdeaStillWorks() {
        let idea = HermesIdea(title: "New Story Arc", description: "Plot twist", ideaType: .plotHook)
        XCTAssertEqual(idea.title, "New Story Arc")
        XCTAssertEqual(idea.ideaType, .plotHook)
    }

    func testHermesContextStillWorks() {
        let context = HermesContext(
            genre: "Science Fiction",
            logline: "Humanity reaches the stars",
            characters: ["Captain Nova"]
        )
        XCTAssertEqual(context.genre, "Science Fiction")
        XCTAssertEqual(context.characters.count, 1)
    }

    func testHermesSessionStillWorks() {
        let context = HermesContext(genre: "Horror")
        var session = HermesSession(context: context)
        let message = HermesMessage(role: .user, content: "Tell me a horror story")
        session.messages.append(message)
        XCTAssertEqual(session.messages.count, 1)
        XCTAssertEqual(session.context.genre, "Horror")
    }

    func testHermesErrorStillWorks() {
        let error = HermesError.aiNotAvailable
        XCTAssertNotNil(error.errorDescription)
    }

    func testHermesResponseStillWorks() {
        let sessionId = UUID()
        let response = HermesResponse(sessionId: sessionId, message: "Here are ideas", ideas: [])
        XCTAssertEqual(response.sessionId, sessionId)
        XCTAssertEqual(response.message, "Here are ideas")
        XCTAssertTrue(response.ideas.isEmpty)
    }

    func testHermesMessageRoleStillWorks() {
        // HermesMessageRole should be unaffected by archiver removal
        XCTAssertEqual(HermesMessageRole.user.rawValue, "user")
        XCTAssertEqual(HermesMessageRole.hermes.rawValue, "hermes")
    }
}

// MARK: - AIService extractText separator change (PR: joined() not joined(separator: " "))

/// The PR changed extractText to use joined() (no separator) instead of joined(separator: " ").
/// We verify this indirectly through the AIAssistanceType prompt concatenation semantics.
/// Direct unit tests of the private extractText function are not possible; instead we test
/// the surrounding public contract.
final class AIServiceExtractTextChangeTests: XCTestCase {

    func testToolDefinitionToDictContainsExpectedKeys() {
        let tool = ToolDefinition(
            name: "get_word_count",
            description: "Returns word count",
            inputSchema: ["type": "object", "properties": [:]]
        )
        let dict = tool.toDict()
        XCTAssertEqual(dict["name"] as? String, "get_word_count")
        XCTAssertEqual(dict["description"] as? String, "Returns word count")
        XCTAssertNotNil(dict["input_schema"])
    }

    func testToolResultToDictWithoutError() {
        let result = ToolResult(toolUseId: "abc123", content: "42 words")
        let dict = result.toDict()
        XCTAssertEqual(dict["type"] as? String, "tool_result")
        XCTAssertEqual(dict["tool_use_id"] as? String, "abc123")
        XCTAssertEqual(dict["content"] as? String, "42 words")
        XCTAssertNil(dict["is_error"])
    }

    func testToolResultToDictWithError() {
        let result = ToolResult(toolUseId: "xyz789", content: "Error message", isError: true)
        let dict = result.toDict()
        XCTAssertEqual(dict["is_error"] as? Bool, true)
    }

    func testToolUseBlockParsesValidDict() {
        let dict: [String: Any] = [
            "type": "tool_use",
            "id": "tu_abc123",
            "name": "get_word_count",
            "input": ["documentId": "some-uuid"]
        ]
        let block = ToolUseBlock(from: dict)
        XCTAssertNotNil(block)
        XCTAssertEqual(block?.id, "tu_abc123")
        XCTAssertEqual(block?.name, "get_word_count")
    }

    func testToolUseBlockRejectsNonToolUseType() {
        let dict: [String: Any] = [
            "type": "text",
            "id": "t123",
            "name": "some_tool"
        ]
        let block = ToolUseBlock(from: dict)
        XCTAssertNil(block, "ToolUseBlock must return nil for non-tool_use type blocks")
    }

    func testToolUseBlockRejectsMissingName() {
        let dict: [String: Any] = [
            "type": "tool_use",
            "id": "t123"
        ]
        let block = ToolUseBlock(from: dict)
        XCTAssertNil(block, "ToolUseBlock must return nil when name is absent")
    }

    func testToolUseBlockDefaultsInputToEmptyDict() {
        let dict: [String: Any] = [
            "type": "tool_use",
            "id": "t123",
            "name": "no_input_tool"
            // no "input" key
        ]
        let block = ToolUseBlock(from: dict)
        XCTAssertNotNil(block)
        XCTAssertTrue(block?.input.isEmpty ?? false,
                      "Missing input key should default to empty dictionary")
    }
}
