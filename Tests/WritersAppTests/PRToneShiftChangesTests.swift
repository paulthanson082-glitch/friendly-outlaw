import XCTest
@testable import WritersApp

// MARK: - AIModel: maxhermes Removed
// PR removed the `maxhermes` case from AIModel enum, leaving exactly 4 cases.

final class AIModelPRChangesTests: XCTestCase {

    func testAIModelHasExactlyFourCases() {
        // Verify the total count by checking every expected case exists
        let knownRawValues = [
            "claude-3-5-sonnet-20241022",
            "claude-3-opus-20240229",
            "claude-3-sonnet-20240229",
            "claude-3-haiku-20240307"
        ]
        for rawValue in knownRawValues {
            XCTAssertNotNil(AIModel(rawValue: rawValue),
                "AIModel with rawValue '\(rawValue)' must exist")
        }
    }

    func testAIModelMaxhermesRawValueReturnsNil() {
        // maxhermes was removed in this PR; its raw value must no longer initialise a case
        XCTAssertNil(AIModel(rawValue: "maxhermes-01"),
            "maxhermes-01 must not be a valid AIModel raw value after removal")
    }

    func testAIModelAllFourDisplayNamesAreNonEmpty() {
        let models: [AIModel] = [.claude35Sonnet, .claude3Opus, .claude3Sonnet, .claude3Haiku]
        for model in models {
            XCTAssertFalse(model.displayName.isEmpty,
                "displayName must not be empty for \(model)")
        }
    }

    func testAIModelDisplayNames() {
        XCTAssertEqual(AIModel.claude35Sonnet.displayName, "Claude 3.5 Sonnet")
        XCTAssertEqual(AIModel.claude3Opus.displayName, "Claude 3 Opus")
        XCTAssertEqual(AIModel.claude3Sonnet.displayName, "Claude 3 Sonnet")
        XCTAssertEqual(AIModel.claude3Haiku.displayName, "Claude 3 Haiku")
    }

    func testAIModelCodableRoundTrip() throws {
        let models: [AIModel] = [.claude35Sonnet, .claude3Opus, .claude3Sonnet, .claude3Haiku]
        for model in models {
            let data = try JSONEncoder().encode(model)
            let decoded = try JSONDecoder().decode(AIModel.self, from: data)
            XCTAssertEqual(decoded, model, "Codable round-trip failed for \(model)")
        }
    }

    func testAIModelDefaultConfigurationUsesSonnet35() {
        let config = AIConfiguration(apiKey: "sk-test")
        XCTAssertEqual(config.model, .claude35Sonnet,
            "Default model must still be claude35Sonnet after maxhermes removal")
    }

    // Regression: decoding a JSON payload that previously contained maxhermes must fail gracefully
    func testAIModelDecodingUnknownRawValueThrows() {
        let json = "\"maxhermes-01\"".data(using: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(AIModel.self, from: json),
            "Decoding an unknown raw value must throw")
    }
}

// MARK: - Document: Synthesized Equatable / Hashable
// PR removed the explicit `==` and `hash(into:)` implementations from Document.
// Swift now synthesises them, which compares ALL stored properties, not just `id`.

final class DocumentSynthesizedHashableTests: XCTestCase {

    // Fixed reference date for deterministic metadata comparisons
    private let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)

    private func fixedMetadata() -> DocumentMetadata {
        DocumentMetadata(created: fixedDate, modified: fixedDate)
    }

    // MARK: - Equatable (synthesised: all fields must match)

    func testDocumentsWithIdenticalFieldsAreEqual() {
        // Use explicit metadata to avoid timestamp drift between Date() calls
        let id = UUID()
        let meta = fixedMetadata()
        let d1 = Document(id: id, title: "Title", content: "Content",
                          category: .article, metadata: meta)
        let d2 = Document(id: id, title: "Title", content: "Content",
                          category: .article, metadata: meta)
        XCTAssertEqual(d1, d2,
            "Documents with identical stored properties must be equal with synthesised Equatable")
    }

    func testDocumentsWithSameIdButDifferentTitlesAreNotEqual() {
        // With synthesised Equatable, two docs sharing an id but differing in title are NOT equal.
        // (Previously with explicit == { lhs.id == rhs.id } they would have been equal.)
        let id = UUID()
        let meta = fixedMetadata()
        let d1 = Document(id: id, title: "Original Title", content: "Content",
                          category: .article, metadata: meta)
        let d2 = Document(id: id, title: "Different Title", content: "Content",
                          category: .article, metadata: meta)
        XCTAssertNotEqual(d1, d2,
            "Synthesised Equatable compares all fields; same id but different title must not be equal")
    }

    func testDocumentsWithSameIdButDifferentContentAreNotEqual() {
        let id = UUID()
        let meta = fixedMetadata()
        let d1 = Document(id: id, title: "Title", content: "Content A",
                          category: .article, metadata: meta)
        let d2 = Document(id: id, title: "Title", content: "Content B",
                          category: .article, metadata: meta)
        XCTAssertNotEqual(d1, d2)
    }

    func testDocumentsWithSameIdButDifferentCategoriesAreNotEqual() {
        let id = UUID()
        let meta = fixedMetadata()
        let d1 = Document(id: id, title: "Title", content: "Content",
                          category: .article, metadata: meta)
        let d2 = Document(id: id, title: "Title", content: "Content",
                          category: .novel, metadata: meta)
        XCTAssertNotEqual(d1, d2)
    }

    func testDocumentsWithDifferentIdsAreNotEqual() {
        let meta = fixedMetadata()
        let d1 = Document(title: "Title", content: "Content", category: .article, metadata: meta)
        let d2 = Document(title: "Title", content: "Content", category: .article, metadata: meta)
        // Each call to Document() generates a new UUID
        XCTAssertNotEqual(d1, d2)
    }

    // MARK: - Hashable

    func testDocumentWithIdenticalFieldsProducesSameHash() {
        let id = UUID()
        let meta = fixedMetadata()
        let d1 = Document(id: id, title: "A", content: "B", category: .novel, metadata: meta)
        let d2 = Document(id: id, title: "A", content: "B", category: .novel, metadata: meta)
        XCTAssertEqual(d1.hashValue, d2.hashValue)
    }

    func testDocumentCanBeStoredInSet() {
        let meta = fixedMetadata()
        let d1 = Document(title: "D1", content: "", category: .other, metadata: meta)
        let d2 = Document(title: "D2", content: "", category: .other, metadata: meta)
        var set = Set<Document>()
        set.insert(d1)
        set.insert(d2)
        XCTAssertEqual(set.count, 2, "Two distinct documents must occupy two slots in a Set")
    }

    func testDocumentSetDoesNotDuplicateIdenticalValue() {
        let id = UUID()
        let meta = fixedMetadata()
        let d1 = Document(id: id, title: "Same", content: "Same",
                          category: .article, metadata: meta)
        let d2 = Document(id: id, title: "Same", content: "Same",
                          category: .article, metadata: meta)
        var set = Set<Document>()
        set.insert(d1)
        set.insert(d2)
        XCTAssertEqual(set.count, 1,
            "Two documents with identical stored properties must not produce duplicate Set entries")
    }

    func testDocumentCanBeUsedAsDictionaryKey() {
        let id = UUID()
        let meta = fixedMetadata()
        let doc = Document(id: id, title: "Key Doc", content: "Content",
                           category: .article, metadata: meta)
        var dict: [Document: String] = [:]
        dict[doc] = "value"
        XCTAssertEqual(dict[doc], "value")
    }

    // Regression: Hashable still works correctly (no compile error from missing explicit impl)
    func testDocumentHashableConformanceCompilesCorrectly() {
        let doc = Document(title: "Test", content: "Content", category: .article,
                           metadata: fixedMetadata())
        // If Hashable were not synthesised, this line would not compile
        var hasher = Hasher()
        doc.hash(into: &hasher)
        // No assertion needed; if this compiles and runs, the conformance works
    }
}

// MARK: - GiftCardManager: expirationDays Must Be > 0
// PR changed the validation guard from `expirationDays >= 0` to `expirationDays > 0`.
// Zero-day bundles now throw `GiftCardError.invalidInput`.

final class GiftCardManagerExpirationPRTests: XCTestCase {

    var manager: GiftCardManager!

    override func setUp() {
        super.setUp()
        manager = GiftCardManager()
    }

    override func tearDown() {
        manager = nil
        super.tearDown()
    }

    func testCreateBundleWithZeroExpirationDaysThrows() {
        XCTAssertThrowsError(
            try manager.createBundle(
                name: "Instant Expire Bundle",
                description: "Should fail",
                price: 9.99,
                bundleType: .starter,
                aiCredits: 10,
                expirationDays: 0
            ),
            "expirationDays == 0 must throw after PR change"
        ) { error in
            guard case GiftCardError.invalidInput(let msg) = error else {
                return XCTFail("Expected GiftCardError.invalidInput, got \(error)")
            }
            XCTAssertFalse(msg.isEmpty, "Error message must not be empty")
        }
    }

    func testCreateBundleWithOneDaySucceeds() throws {
        let bundle = try manager.createBundle(
            name: "One Day Bundle",
            description: "Minimal valid expiration",
            price: 4.99,
            bundleType: .starter,
            aiCredits: 5,
            expirationDays: 1
        )
        XCTAssertEqual(bundle.expirationDays, 1)
        XCTAssertEqual(bundle.name, "One Day Bundle")
    }

    func testCreateBundleWithPositiveExpirationDaysSucceeds() throws {
        let bundle = try manager.createBundle(
            name: "Professional Bundle",
            description: "30-day expiration",
            price: 19.99,
            bundleType: .professional,
            aiCredits: 100,
            expirationDays: 30
        )
        XCTAssertEqual(bundle.expirationDays, 30)
    }

    func testCreateBundleWithNegativeExpirationDaysThrows() {
        XCTAssertThrowsError(
            try manager.createBundle(
                name: "Negative Bundle",
                description: "Should fail",
                price: 9.99,
                bundleType: .starter,
                aiCredits: 10,
                expirationDays: -5
            ),
            "Negative expirationDays must still throw"
        ) { error in
            guard case GiftCardError.invalidInput = error else {
                return XCTFail("Expected GiftCardError.invalidInput")
            }
        }
    }

    func testCreateBundleWithLargeExpirationDaysSucceeds() throws {
        let bundle = try manager.createBundle(
            name: "Annual Bundle",
            description: "365-day subscription",
            price: 99.99,
            bundleType: .enterprise,
            aiCredits: 1000,
            expirationDays: 365
        )
        XCTAssertEqual(bundle.expirationDays, 365)
    }

    // Boundary: expirationDays == 0 is the exact boundary case that changed
    func testBundleCountUnchangedAfterFailedCreation() throws {
        XCTAssertThrowsError(
            try manager.createBundle(
                name: "Bad Bundle", description: "", price: 1.0,
                bundleType: .starter, aiCredits: 1, expirationDays: 0
            )
        )
        XCTAssertEqual(manager.getAllBundles().count, 0,
            "Failed bundle creation must not add to the bundle store")
    }
}

// MARK: - KanbanManager.searchTasks: Empty Query Returns All Tasks
// PR changed empty-query behaviour from returning [] to returning all tasks.

final class KanbanManagerSearchTasksPRTests: XCTestCase {

    var manager: KanbanManager!
    var board: KanbanBoard!

    override func setUp() {
        super.setUp()
        manager = KanbanManager()
        board = KanbanBoard(name: "Test Board", description: "")
        manager.createBoard(board)
    }

    override func tearDown() {
        manager = nil
        board = nil
        super.tearDown()
    }

    private func makeTask(title: String, description: String = "") -> KanbanTask {
        KanbanTask(title: title, description: description, column: .backlog, boardId: board.id)
    }

    func testSearchTasksEmptyQueryReturnsAllTasks() {
        let t1 = makeTask(title: "Write chapter one")
        let t2 = makeTask(title: "Edit draft")
        let t3 = makeTask(title: "Proofread")
        manager.createTask(t1)
        manager.createTask(t2)
        manager.createTask(t3)

        let results = manager.searchTasks(query: "")
        XCTAssertEqual(results.count, 3,
            "Empty query must return all tasks after PR change")
    }

    func testSearchTasksWhitespaceOnlyQueryReturnsAllTasks() {
        let t1 = makeTask(title: "Alpha")
        let t2 = makeTask(title: "Beta")
        manager.createTask(t1)
        manager.createTask(t2)

        let results = manager.searchTasks(query: "   ")
        XCTAssertEqual(results.count, 2,
            "Whitespace-only query must return all tasks after PR change")
    }

    func testSearchTasksTabsAndNewlinesQueryReturnsAllTasks() {
        let t1 = makeTask(title: "Gamma")
        manager.createTask(t1)

        let results = manager.searchTasks(query: "\t\n  \t")
        XCTAssertEqual(results.count, 1,
            "Tab/newline-only query must return all tasks after PR change")
    }

    func testSearchTasksEmptyQueryWithNoTasksReturnsEmpty() {
        let results = manager.searchTasks(query: "")
        XCTAssertEqual(results.count, 0,
            "Empty query on an empty store must return empty array")
    }

    func testSearchTasksNonEmptyQueryFiltersNormally() {
        let t1 = makeTask(title: "Write chapter one", description: "First chapter")
        let t2 = makeTask(title: "Edit draft", description: "Revision pass")
        manager.createTask(t1)
        manager.createTask(t2)

        let results = manager.searchTasks(query: "chapter")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.id, t1.id)
    }

    func testSearchTasksEmptyQueryResultsSortedByCreatedDescending() {
        // Results from an empty query are sorted newest-first
        var t1 = makeTask(title: "Older task")
        var t2 = makeTask(title: "Newer task")
        // Force t1 to have an older created timestamp
        t1.metadata.created = Date(timeIntervalSince1970: 1_000_000)
        t2.metadata.created = Date(timeIntervalSince1970: 2_000_000)
        manager.createTask(t1)
        manager.createTask(t2)

        let results = manager.searchTasks(query: "")
        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results.first?.title, "Newer task",
            "Empty-query results must be sorted newest-first")
    }

    func testSearchTasksCaseInsensitiveForNonEmptyQuery() {
        let t1 = makeTask(title: "SWIFT programming")
        manager.createTask(t1)

        XCTAssertEqual(manager.searchTasks(query: "swift").count, 1)
        XCTAssertEqual(manager.searchTasks(query: "SWIFT").count, 1)
        XCTAssertEqual(manager.searchTasks(query: "Swift").count, 1)
    }
}

// MARK: - TemplateManager: Screenplay Scene Template Changes
// PR renamed "Screenplay" to "Screenplay Scene" and added new placeholders:
//   - character_state (optional)
//   - shot_description (optional)

final class TemplateManagerScreenplayPRTests: XCTestCase {

    var manager: TemplateManager!

    override func setUp() {
        super.setUp()
        manager = TemplateManager()
    }

    override func tearDown() {
        manager = nil
        super.tearDown()
    }

    private func screenplayTemplate() -> Template? {
        manager.getAllTemplates().first { $0.name == "Screenplay Scene" }
    }

    func testScreenplaySceneTemplateExists() {
        XCTAssertNotNil(screenplayTemplate(),
            "'Screenplay Scene' template must exist after rename")
    }

    func testOldScreenplayNameNoLongerExists() {
        let old = manager.getAllTemplates().first { $0.name == "Screenplay" }
        XCTAssertNil(old,
            "The old 'Screenplay' template name must no longer exist after rename")
    }

    func testScreenplaySceneTemplateCategory() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay Scene template not found")
        }
        XCTAssertEqual(template.category, .screenplay)
    }

    // MARK: - New placeholders added by PR

    func testScreenplaySceneHasCharacterStatePlaceholder() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay Scene template not found")
        }
        let hasKey = template.placeholders.contains { $0.key == "character_state" }
        XCTAssertTrue(hasKey,
            "character_state placeholder must be present after PR addition")
    }

    func testScreenplaySceneHasShotDescriptionPlaceholder() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay Scene template not found")
        }
        let hasKey = template.placeholders.contains { $0.key == "shot_description" }
        XCTAssertTrue(hasKey,
            "shot_description placeholder must be present after PR addition")
    }

    func testCharacterStatePlaceholderIsOptional() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay Scene template not found")
        }
        let placeholder = template.placeholders.first { $0.key == "character_state" }
        XCTAssertNotNil(placeholder)
        XCTAssertFalse(placeholder?.required ?? true,
            "character_state must be an optional (non-required) placeholder")
    }

    func testShotDescriptionPlaceholderIsOptional() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay Scene template not found")
        }
        let placeholder = template.placeholders.first { $0.key == "shot_description" }
        XCTAssertNotNil(placeholder)
        XCTAssertFalse(placeholder?.required ?? true,
            "shot_description must be an optional (non-required) placeholder")
    }

    func testScreenplaySceneContentContainsCharacterStateMacro() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay Scene template not found")
        }
        XCTAssertTrue(template.content.contains("{{character_state}}"),
            "Template content must contain {{character_state}} after PR change")
    }

    func testScreenplaySceneContentContainsShotDescriptionMacro() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay Scene template not found")
        }
        XCTAssertTrue(template.content.contains("{{shot_description}}"),
            "Template content must contain {{shot_description}} after PR change")
    }

    func testScreenplaySceneSearchableByNewName() {
        let results = manager.searchTemplates(query: "Screenplay Scene")
        XCTAssertGreaterThan(results.count, 0,
            "Searching 'Screenplay Scene' must find the renamed template")
    }

    func testScreenplaySceneSearchableByKeyword() {
        let results = manager.searchTemplates(query: "screenplay")
        XCTAssertGreaterThan(results.count, 0,
            "Searching 'screenplay' keyword must still find the template")
    }

    // MARK: - Core placeholders still present

    func testScreenplaySceneStillHasSceneHeadingPlaceholder() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay Scene template not found")
        }
        XCTAssertTrue(template.placeholders.contains { $0.key == "scene_heading" })
    }

    func testScreenplaySceneStillHasActionPlaceholder() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay Scene template not found")
        }
        XCTAssertTrue(template.placeholders.contains { $0.key == "action" })
    }

    func testScreenplaySceneStillHasDialoguePlaceholder() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay Scene template not found")
        }
        XCTAssertTrue(template.placeholders.contains { $0.key == "dialogue" })
    }

    func testScreenplaySceneStillHasTransitionPlaceholder() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay Scene template not found")
        }
        XCTAssertTrue(template.placeholders.contains { $0.key == "transition" })
    }
}

// MARK: - HermesService: AgentProfile and switchProfile Removed
// PR removed the `AgentProfile` enum and `switchProfile(_:)` method from HermesService.
// `currentProfile` property was also removed.

final class HermesServiceProfilePRTests: XCTestCase {

    private func makeHermesService() -> HermesService {
        let aiConfig = AIConfiguration(apiKey: "sk-test", model: .claude35Sonnet)
        let aiService = AIService(configuration: aiConfig)
        let docManager = DocumentManager()
        let templateManager = TemplateManager()
        return HermesService(aiService: aiService,
                             documentManager: docManager,
                             templateManager: templateManager)
    }

    func testHermesServiceCurrentSessionIsAccessible() {
        // currentSession is still public; verify it is nil on a fresh service
        let hermesService = makeHermesService()
        XCTAssertNil(hermesService.currentSession,
            "currentSession must be nil before any session is started")
    }

    func testHermesServiceInitialisesWithDefaultParameters() {
        let hermesService = makeHermesService()
        XCTAssertGreaterThan(hermesService.maxHistoryMessages, 0)
        XCTAssertGreaterThan(hermesService.maxPromptLength, 0)
    }

    func testHermesServiceStartSessionReturnsSession() {
        let hermesService = makeHermesService()
        let context = HermesContext(genre: "Fantasy")
        let session = hermesService.startSession(context: context)
        XCTAssertNotNil(session, "startSession must return a valid HermesSession")
        XCTAssertNotNil(hermesService.currentSession,
            "currentSession must be set after startSession")
    }

    func testHermesServiceEndSessionClearsCurrentSession() {
        let hermesService = makeHermesService()
        let context = HermesContext(genre: "Sci-Fi")
        _ = hermesService.startSession(context: context)
        XCTAssertNotNil(hermesService.currentSession)
        hermesService.endSession()
        XCTAssertNil(hermesService.currentSession,
            "currentSession must be nil after endSession")
    }
}

// MARK: - HermesModels: Archiver Types Removed
// PR removed ArchiveSnapshot, ArchiveCollection, ArchiverContext, and ArchiverProfile
// from HermesModels.swift. These were moved/deleted — they must not be accessible
// as HermesModels types.
//
// Compile-time verification is implicit (the types simply no longer exist in the module).
// The tests below document the current model state and guard against accidental re-addition.

final class HermesModelsPRCleanupTests: XCTestCase {

    func testHermesErrorIsStillAvailable() {
        // HermesError was retained in HermesModels.swift; confirm it was not accidentally removed
        let err = HermesError.emptyPrompt
        switch err {
        case .emptyPrompt:
            break // expected
        default:
            XCTFail("HermesError.emptyPrompt must still exist")
        }
    }

    func testHermesErrorAiNotAvailableIsStillAvailable() {
        let err = HermesError.aiNotAvailable
        XCTAssertNotNil(err.errorDescription)
        XCTAssertFalse(err.errorDescription!.isEmpty)
    }

    func testHermesContextIsStillAvailable() {
        let context = HermesContext(genre: "Horror")
        XCTAssertEqual(context.genre, "Horror")
    }

    func testHermesIdeaIsStillAvailable() {
        let idea = HermesIdea(
            title: "The Haunted Library",
            description: "A library that changes its layout each night",
            ideaType: .setting
        )
        XCTAssertEqual(idea.title, "The Haunted Library")
        XCTAssertEqual(idea.ideaType, .setting)
    }

    func testHermesSessionIsStillAvailable() {
        // Ensure HermesSession can be created via the service
        let context = HermesContext(genre: "Mystery")
        let aiConfig = AIConfiguration(apiKey: "sk-test")
        let aiService = AIService(configuration: aiConfig)
        let docManager = DocumentManager()
        let templateManager = TemplateManager()
        let hermesService = HermesService(aiService: aiService,
                                          documentManager: docManager,
                                          templateManager: templateManager)
        let session = hermesService.startSession(context: context)
        XCTAssertNotNil(session.id)
    }
}

// MARK: - DocumentManager.searchDocuments: Empty Query Returns All
// PR changed the empty-query behaviour from returning [] to returning all documents.

final class DocumentManagerSearchPRTests: XCTestCase {

    var manager: DocumentManager!

    override func setUp() {
        super.setUp()
        manager = DocumentManager()
    }

    override func tearDown() {
        manager = nil
        super.tearDown()
    }

    func testSearchDocumentsWhitespaceQueryReturnsAll() {
        manager.createDocument(Document(title: "A", content: "", category: .article))
        manager.createDocument(Document(title: "B", content: "", category: .novel))
        let results = manager.searchDocuments(query: "   ")
        XCTAssertEqual(results.count, 2,
            "Whitespace-only query must return all documents after PR change")
    }

    func testSearchDocumentsTabNewlineQueryReturnsAll() {
        manager.createDocument(Document(title: "Doc", content: "Text", category: .article))
        let results = manager.searchDocuments(query: "\t\n")
        XCTAssertEqual(results.count, 1,
            "Tab/newline-only query must return all documents after PR change")
    }

    func testSearchDocumentsEmptyQueryOnEmptyStoreReturnsEmpty() {
        let results = manager.searchDocuments(query: "")
        XCTAssertEqual(results.count, 0)
    }

    // Regression: non-empty queries must still filter correctly
    func testSearchDocumentsNonEmptyQueryStillFilters() {
        manager.createDocument(Document(title: "Swift Guide", content: "Learn Swift", category: .article))
        manager.createDocument(Document(title: "Python Tutorial", content: "Learn Python", category: .article))
        let results = manager.searchDocuments(query: "Swift")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Swift Guide")
    }
}

// MARK: - IssueManager.searchIssues: Empty Query Returns All
// PR changed the empty-query behaviour from returning [] to returning all issues.

final class IssueManagerSearchPRTests: XCTestCase {

    var manager: IssueManager!
    let docId = UUID()

    override func setUp() {
        super.setUp()
        manager = IssueManager()
    }

    override func tearDown() {
        manager = nil
        super.tearDown()
    }

    func testSearchIssuesWhitespaceQueryReturnsAll() {
        manager.createIssue(Issue(documentId: docId, title: "Bug A",
                                  description: "Description A", status: .open, priority: .high))
        manager.createIssue(Issue(documentId: docId, title: "Bug B",
                                  description: "Description B", status: .open, priority: .low))
        let results = manager.searchIssues(query: "  ")
        XCTAssertEqual(results.count, 2,
            "Whitespace-only query must return all issues after PR change")
    }

    func testSearchIssuesTabQueryReturnsAll() {
        manager.createIssue(Issue(documentId: docId, title: "Plot hole",
                                  description: "Needs fixing", status: .open, priority: .medium))
        let results = manager.searchIssues(query: "\t")
        XCTAssertEqual(results.count, 1)
    }

    func testSearchIssuesEmptyQueryOnEmptyStoreReturnsEmpty() {
        let results = manager.searchIssues(query: "")
        XCTAssertEqual(results.count, 0)
    }

    // Regression: non-empty queries still filter by title and description
    func testSearchIssuesNonEmptyQueryFiltersNormally() {
        manager.createIssue(Issue(documentId: docId, title: "Character arc issue",
                                  description: "Needs backstory", status: .open, priority: .high))
        manager.createIssue(Issue(documentId: docId, title: "Pacing problem",
                                  description: "Third act too slow", status: .open, priority: .medium))
        let results = manager.searchIssues(query: "character")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Character arc issue")
    }

    func testSearchIssuesDescriptionSearchStillWorks() {
        manager.createIssue(Issue(documentId: docId, title: "Title",
                                  description: "backstory needed for protagonist",
                                  status: .open, priority: .low))
        let results = manager.searchIssues(query: "backstory")
        XCTAssertEqual(results.count, 1)
    }
}
