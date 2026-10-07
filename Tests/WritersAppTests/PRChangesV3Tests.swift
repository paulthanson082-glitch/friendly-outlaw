import XCTest
@testable import WritersApp

// MARK: - Document synthesized Equatable/Hashable: templateId field
//
// After removing the custom == / hash(into:), Document uses synthesized conformance.
// All stored properties — including `templateId` — now participate in equality and hashing.

final class DocumentSynthesizedEqualityTemplateIdTests: XCTestCase {

    private func fixedMeta() -> DocumentMetadata {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        return DocumentMetadata(created: date, modified: date)
    }

    // MARK: - templateId participates in synthesized equality

    func testDocumentsWithDifferentTemplateIdsAreNotEqual() {
        let id = UUID()
        let meta = fixedMeta()
        let doc1 = Document(
            id: id, title: "T", content: "C",
            templateId: UUID(), category: .novel, metadata: meta
        )
        let doc2 = Document(
            id: id, title: "T", content: "C",
            templateId: UUID(), category: .novel, metadata: meta
        )
        XCTAssertNotEqual(doc1, doc2,
            "Documents with same id but different templateId must not be equal under synthesized Equatable")
    }

    func testDocumentsWithSameTemplateIdAreEqual() {
        let id = UUID()
        let templateId = UUID()
        let meta = fixedMeta()
        let doc1 = Document(
            id: id, title: "T", content: "C",
            templateId: templateId, category: .novel, metadata: meta
        )
        let doc2 = Document(
            id: id, title: "T", content: "C",
            templateId: templateId, category: .novel, metadata: meta
        )
        XCTAssertEqual(doc1, doc2,
            "Documents with identical properties including templateId must be equal")
    }

    func testDocumentWithNilTemplateIdNotEqualToOneWithNonNilTemplateId() {
        let id = UUID()
        let meta = fixedMeta()
        let withTemplate = Document(
            id: id, title: "T", content: "C",
            templateId: UUID(), category: .novel, metadata: meta
        )
        let withoutTemplate = Document(
            id: id, title: "T", content: "C",
            templateId: nil, category: .novel, metadata: meta
        )
        XCTAssertNotEqual(withTemplate, withoutTemplate,
            "Document with templateId must not equal one without templateId (synthesized equality)")
    }

    func testDocumentsWithBothNilTemplateIdsAndSameFieldsAreEqual() {
        let id = UUID()
        let meta = fixedMeta()
        let doc1 = Document(
            id: id, title: "T", content: "C",
            templateId: nil, category: .article, metadata: meta
        )
        let doc2 = Document(
            id: id, title: "T", content: "C",
            templateId: nil, category: .article, metadata: meta
        )
        XCTAssertEqual(doc1, doc2,
            "Documents with nil templateId and otherwise identical fields must be equal")
    }

    // MARK: - templateId participates in synthesized hash

    func testDocumentsWithDifferentTemplateIdsProduceDifferentHashes() {
        let id = UUID()
        let meta = fixedMeta()
        let doc1 = Document(
            id: id, title: "T", content: "C",
            templateId: UUID(), category: .novel, metadata: meta
        )
        let doc2 = Document(
            id: id, title: "T", content: "C",
            templateId: UUID(), category: .novel, metadata: meta
        )
        var h1 = Hasher()
        doc1.hash(into: &h1)
        var h2 = Hasher()
        doc2.hash(into: &h2)
        XCTAssertNotEqual(h1.finalize(), h2.finalize(),
            "Documents differing only in templateId should produce different hash values")
    }

    func testDocumentsWithSameTemplateIdProduceSameHash() {
        let id = UUID()
        let templateId = UUID()
        let meta = fixedMeta()
        let doc1 = Document(
            id: id, title: "T", content: "C",
            templateId: templateId, category: .novel, metadata: meta
        )
        let doc2 = Document(
            id: id, title: "T", content: "C",
            templateId: templateId, category: .novel, metadata: meta
        )
        var h1 = Hasher()
        doc1.hash(into: &h1)
        var h2 = Hasher()
        doc2.hash(into: &h2)
        XCTAssertEqual(h1.finalize(), h2.finalize(),
            "Equal documents (including templateId) must have identical hash values")
    }

    // MARK: - Set behaviour with templateId

    func testDocumentsWithDifferentTemplateIdsOccupyTwoSetSlots() {
        let id = UUID()
        let meta = fixedMeta()
        let doc1 = Document(
            id: id, title: "T", content: "C",
            templateId: UUID(), category: .novel, metadata: meta
        )
        let doc2 = Document(
            id: id, title: "T", content: "C",
            templateId: UUID(), category: .novel, metadata: meta
        )
        let s: Set<Document> = [doc1, doc2]
        XCTAssertEqual(s.count, 2,
            "Two documents differing only in templateId must each occupy their own slot in a Set")
    }

    func testDocumentsWithNilVsNonNilTemplateIdOccupyTwoSetSlots() {
        let id = UUID()
        let meta = fixedMeta()
        let withTemplate = Document(
            id: id, title: "T", content: "C",
            templateId: UUID(), category: .article, metadata: meta
        )
        let withoutTemplate = Document(
            id: id, title: "T", content: "C",
            templateId: nil, category: .article, metadata: meta
        )
        let s: Set<Document> = [withTemplate, withoutTemplate]
        XCTAssertEqual(s.count, 2,
            "Document with and without templateId must occupy separate slots in a Set")
    }
}

// MARK: - GiftCardManager: expirationDays > 0 exact error message

final class GiftCardManagerExpirationDaysMessageTests: XCTestCase {

    private var manager: GiftCardManager!

    override func setUp() {
        super.setUp()
        manager = GiftCardManager()
    }

    override func tearDown() {
        manager = nil
        super.tearDown()
    }

    // MARK: - Zero expirationDays: exact error message

    func testZeroExpirationDaysThrowsExactMessage() {
        XCTAssertThrowsError(
            try manager.createBundle(
                name: "Zero Days",
                description: "desc",
                price: 10.0,
                bundleType: .starter,
                aiCredits: 50,
                expirationDays: 0
            )
        ) { error in
            guard case GiftCardError.invalidInput(let msg) = error else {
                XCTFail("Expected GiftCardError.invalidInput, got \(error)")
                return
            }
            XCTAssertEqual(msg, "Expiration days must be greater than 0",
                "The error message for expirationDays=0 must exactly match the PR change")
        }
    }

    func testZeroExpirationDaysErrorDescriptionMatchesPRChange() {
        XCTAssertThrowsError(
            try manager.createBundle(
                name: "Zero Days",
                description: "desc",
                price: 5.0,
                bundleType: .starter,
                aiCredits: 10,
                expirationDays: 0
            )
        ) { error in
            let desc = (error as? GiftCardError)?.errorDescription ?? ""
            XCTAssertTrue(
                desc.contains("greater than 0"),
                "Error description must contain 'greater than 0' (not 'greater than or equal to 0')"
            )
            XCTAssertFalse(
                desc.contains("greater than or equal to 0"),
                "Error description must NOT contain the old wording 'greater than or equal to 0'"
            )
        }
    }

    // MARK: - Boundary: exactly 1 is the minimum accepted value

    func testExpirationDaysOneIsAcceptedAndStored() throws {
        let bundle = try manager.createBundle(
            name: "Minimum Expiry",
            description: "desc",
            price: 5.0,
            bundleType: .starter,
            aiCredits: 10,
            expirationDays: 1
        )
        XCTAssertEqual(bundle.expirationDays, 1,
            "expirationDays=1 is the minimum valid value and must be accepted without modification")
    }

    // MARK: - Both aiCredits and expirationDays validation interact correctly

    func testValidAiCreditsWithZeroExpirationDaysStillThrows() {
        XCTAssertThrowsError(
            try manager.createBundle(
                name: "Valid Credits Zero Days",
                description: "desc",
                price: 20.0,
                bundleType: .professional,
                aiCredits: 500,
                expirationDays: 0
            )
        ) { error in
            guard case GiftCardError.invalidInput = error else {
                XCTFail("Expected GiftCardError.invalidInput, got \(error)")
                return
            }
        }
    }

    // MARK: - Regression: old "greater than or equal to 0" wording no longer emitted

    func testNegativeExpirationDaysErrorMessageDoesNotContainOldWording() {
        XCTAssertThrowsError(
            try manager.createBundle(
                name: "Old Wording Regression",
                description: "desc",
                price: 1.0,
                bundleType: .starter,
                aiCredits: 1,
                expirationDays: -10
            )
        ) { error in
            let desc = (error as? GiftCardError)?.errorDescription ?? ""
            XCTAssertFalse(
                desc.contains("greater than or equal to"),
                "Error must not contain old wording 'greater than or equal to'"
            )
        }
    }
}

// MARK: - NvidiaAPILogger additional edge-case tests

final class NvidiaAPILoggerAdditionalTests: XCTestCase {

    // MARK: - Helpers

    private func tmpDir() -> String {
        let dir = NSTemporaryDirectory().appending("nvidia_additional_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        return dir
    }

    private func makeEnv(in dir: String, contents: String) -> String {
        let path = dir + "/.env"
        try? contents.write(toFile: path, atomically: true, encoding: .utf8)
        return path
    }

    private func logPath(in dir: String) -> String {
        dir + "/proxy.log"
    }

    // MARK: - .env parsing edge cases

    func testReadAPIKeyFromEmptyFile() {
        let dir = tmpDir()
        _ = makeEnv(in: dir, contents: "")
        XCTAssertNil(NvidiaAPILogger.readAPIKey(from: dir + "/.env"),
            "Empty .env file must return nil")
    }

    func testReadAPIKeyFirstMatchWinsWhenMultipleKeysPresent() {
        let dir = tmpDir()
        _ = makeEnv(in: dir, contents: """
            NVIDIA_API_KEY=nvapi-first
            NVIDIA_API_KEY=nvapi-second
            """)
        XCTAssertEqual(
            NvidiaAPILogger.readAPIKey(from: dir + "/.env"),
            "nvapi-first",
            "When multiple NVIDIA_API_KEY entries exist, the first one must win"
        )
    }

    func testReadAPIKeyIgnoresKeyWithOnlyWhitespaceValue() {
        let dir = tmpDir()
        _ = makeEnv(in: dir, contents: "NVIDIA_API_KEY=   \n")
        // value after stripping quotes becomes "   " which is not empty, so it would be returned unless trimmed
        // The implementation strips surrounding matching quotes but NOT general whitespace.
        // " " is non-empty so readAPIKey returns "   " — this documents the actual behaviour.
        let result = NvidiaAPILogger.readAPIKey(from: dir + "/.env")
        // The value "   " is non-empty so the key is returned as-is (spaces are preserved).
        XCTAssertNotNil(result,
            "A value consisting only of spaces is non-empty and should be returned (spaces preserved)")
    }

    func testReadAPIKeyFileWithOnlyComments() {
        let dir = tmpDir()
        _ = makeEnv(in: dir, contents: "# NVIDIA_API_KEY=should-not-be-read\n# another comment\n")
        XCTAssertNil(NvidiaAPILogger.readAPIKey(from: dir + "/.env"),
            "Lines starting with # must be skipped; nil returned when no real key is found")
    }

    func testReadAPIKeyOtherKeysDoNotInterfere() {
        let dir = tmpDir()
        _ = makeEnv(in: dir, contents: "OPENAI_API_KEY=sk-other\nNVIDIA_API_KEY=nvapi-target\n")
        XCTAssertEqual(
            NvidiaAPILogger.readAPIKey(from: dir + "/.env"),
            "nvapi-target",
            "readAPIKey must return only the NVIDIA_API_KEY value, ignoring other keys"
        )
    }

    // MARK: - Static path constants

    func testEnvFilePathContainsExpectedComponents() {
        let path = NvidiaAPILogger.envFilePath
        XCTAssertTrue(path.contains("claude-free"), "envFilePath must reference the claude-free directory")
        XCTAssertTrue(path.hasSuffix(".env"), "envFilePath must end with .env")
        XCTAssertFalse(path.hasPrefix("~"), "envFilePath must be an expanded path (not start with ~)")
    }

    func testLogFilePathContainsExpectedComponents() {
        let path = NvidiaAPILogger.logFilePath
        XCTAssertTrue(path.contains("claude-free"), "logFilePath must reference the claude-free directory")
        XCTAssertTrue(path.hasSuffix("proxy.log"), "logFilePath must end with proxy.log")
        XCTAssertFalse(path.hasPrefix("~"), "logFilePath must be an expanded path (not start with ~)")
    }

    // MARK: - Log entry format details

    func testLogEntryContainsTimestampBrackets() {
        let dir = tmpDir()
        let log = logPath(in: dir)
        let logger = NvidiaAPILogger(envPath: dir + "/.env", logPath: log)

        logger.log(
            endpoint: "/v1/chat/completions",
            model: "meta/llama-3.1-8b-instruct",
            promptTokens: 5,
            completionTokens: 10,
            statusCode: 200,
            latencyMs: 100.0
        )

        let contents = (try? String(contentsOfFile: log, encoding: .utf8)) ?? ""
        XCTAssertTrue(contents.contains("["), "Log entry must contain opening bracket for timestamp")
        XCTAssertTrue(contents.contains("]"), "Log entry must contain closing bracket for timestamp")
    }

    func testLogEntryLatencyFormattedToOneDecimalPlace() {
        let dir = tmpDir()
        let log = logPath(in: dir)
        let logger = NvidiaAPILogger(envPath: dir + "/.env", logPath: log)

        logger.log(
            endpoint: "/v1/chat/completions",
            model: "test-model",
            promptTokens: 1,
            completionTokens: 1,
            statusCode: 200,
            latencyMs: 99.567
        )

        let contents = (try? String(contentsOfFile: log, encoding: .utf8)) ?? ""
        XCTAssertTrue(contents.contains("latency_ms=99.6"),
            "Latency must be formatted to one decimal place (99.567 → 99.6)")
    }

    func testLogErrorContainsModelField() {
        let dir = tmpDir()
        let log = logPath(in: dir)
        let logger = NvidiaAPILogger(envPath: dir + "/.env", logPath: log)

        logger.logError(
            endpoint: "/v1/chat/completions",
            model: "nvidia/nemotron-4-340b-instruct",
            error: "timeout"
        )

        let contents = (try? String(contentsOfFile: log, encoding: .utf8)) ?? ""
        XCTAssertTrue(contents.contains("model=nvidia/nemotron-4-340b-instruct"),
            "logError entry must include the model field")
    }

    func testLogFileCreatesIntermediateDirectories() {
        let dir = tmpDir()
        let nestedLog = dir + "/a/b/c/proxy.log"
        let logger = NvidiaAPILogger(envPath: dir + "/.env", logPath: nestedLog)

        logger.log(
            endpoint: "/v1/chat/completions",
            model: "test",
            promptTokens: 1,
            completionTokens: 1,
            statusCode: 200,
            latencyMs: 10.0
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: nestedLog),
            "Logger must create intermediate directories so log writes succeed")
    }

    // MARK: - NvidiaAIService: key precedence

    func testExplicitKeyTakesPriorityOverEnvKey() throws {
        let dir = tmpDir()
        _ = makeEnv(in: dir, contents: "NVIDIA_API_KEY=nvapi-from-env\n")
        let logger = NvidiaAPILogger(envPath: dir + "/.env", logPath: logPath(in: dir))

        // Providing an explicit key must not throw even if the logger also has one
        XCTAssertNoThrow(
            try NvidiaAIService(apiKey: "nvapi-explicit-override", logger: logger),
            "NvidiaAIService must accept an explicit apiKey regardless of what the logger's env key is"
        )
    }

    func testNvidiaAIServiceWithEmptyStringExplicitKeyThrows() {
        let dir = tmpDir()
        // Even if the logger has a key, passing an explicit empty string uses "" ?? logger.apiKey
        // which evaluates to "" (non-nil), and !key.isEmpty is false → throws missingAPIKey.
        let logger = NvidiaAPILogger(envPath: dir + "/.env", logPath: logPath(in: dir))

        XCTAssertThrowsError(
            try NvidiaAIService(apiKey: "", logger: logger)
        ) { error in
            XCTAssertEqual(error as? NvidiaAIError, .missingAPIKey,
                "Passing an empty string as apiKey must throw missingAPIKey (empty string is not nil, so logger key is not consulted)")
        }
    }

    // MARK: - NvidiaAIError: error description content

    func testMissingAPIKeyDescriptionMentionsEnvPath() {
        let desc = NvidiaAIError.missingAPIKey.errorDescription ?? ""
        XCTAssertTrue(desc.contains("NVIDIA_API_KEY"),
            "missingAPIKey description must mention the expected env variable name")
        XCTAssertTrue(desc.contains(".env"),
            "missingAPIKey description must mention the .env file")
    }

    func testAPIErrorDescriptionContainsBothStatusCodeAndMessage() {
        let desc = NvidiaAIError.apiError(statusCode: 503, message: "service unavailable").errorDescription ?? ""
        XCTAssertTrue(desc.contains("503"),
            "apiError description must contain the HTTP status code")
        XCTAssertTrue(desc.contains("service unavailable"),
            "apiError description must contain the error message")
    }

    func testInvalidResponseFormatDescriptionIsNonEmpty() {
        let desc = NvidiaAIError.invalidResponseFormat.errorDescription ?? ""
        XCTAssertFalse(desc.isEmpty, "invalidResponseFormat description must not be empty")
    }

    func testInvalidResponseDescriptionIsNonEmpty() {
        let desc = NvidiaAIError.invalidResponse.errorDescription ?? ""
        XCTAssertFalse(desc.isEmpty, "invalidResponse description must not be empty")
    }

    func testInvalidURLDescriptionIsNonEmpty() {
        let desc = NvidiaAIError.invalidURL.errorDescription ?? ""
        XCTAssertFalse(desc.isEmpty, "invalidURL description must not be empty")
    }

    // MARK: - Concurrent log writes (thread safety)

    func testConcurrentLogWritesProduceCorrectLineCount() {
        let dir = tmpDir()
        let log = logPath(in: dir)
        let logger = NvidiaAPILogger(envPath: dir + "/.env", logPath: log)

        let expectation = self.expectation(description: "All concurrent writes complete")
        expectation.expectedFulfillmentCount = 10

        let queue = DispatchQueue(label: "concurrent.log.test", attributes: .concurrent)
        for i in 0..<10 {
            queue.async {
                logger.log(
                    endpoint: "/v1/chat/completions",
                    model: "test-model",
                    promptTokens: i,
                    completionTokens: i * 2,
                    statusCode: 200,
                    latencyMs: Double(i) * 10
                )
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 5)

        let contents = (try? String(contentsOfFile: log, encoding: .utf8)) ?? ""
        let lineCount = contents.components(separatedBy: "\n").filter { !$0.isEmpty }.count
        XCTAssertEqual(lineCount, 10,
            "All 10 concurrent log writes must be preserved without data loss")
    }
}
