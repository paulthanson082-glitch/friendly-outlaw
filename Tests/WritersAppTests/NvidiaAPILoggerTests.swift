import XCTest
@testable import WritersApp

final class NvidiaAPILoggerTests: XCTestCase {

    // MARK: - Helpers

    private func tmpDir() -> String {
        let dir = NSTemporaryDirectory().appending("nvidia_logger_tests_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        return dir
    }

    private func envFile(in dir: String, contents: String) -> String {
        let path = dir + "/.env"
        try? contents.write(toFile: path, atomically: true, encoding: .utf8)
        return path
    }

    private func logFile(in dir: String) -> String {
        dir + "/proxy.log"
    }

    // MARK: - .env parsing

    func testReadAPIKeyBareValue() {
        let dir = tmpDir()
        _ = envFile(in: dir, contents: "NVIDIA_API_KEY=nvapi-abc123\n")
        XCTAssertEqual(NvidiaAPILogger.readAPIKey(from: dir + "/.env"), "nvapi-abc123")
    }

    func testReadAPIKeyDoubleQuotes() {
        let dir = tmpDir()
        _ = envFile(in: dir, contents: "NVIDIA_API_KEY=\"nvapi-quoted\"\n")
        XCTAssertEqual(NvidiaAPILogger.readAPIKey(from: dir + "/.env"), "nvapi-quoted")
    }

    func testReadAPIKeySingleQuotes() {
        let dir = tmpDir()
        _ = envFile(in: dir, contents: "NVIDIA_API_KEY='nvapi-single'\n")
        XCTAssertEqual(NvidiaAPILogger.readAPIKey(from: dir + "/.env"), "nvapi-single")
    }

    func testReadAPIKeyIgnoresComments() {
        let dir = tmpDir()
        _ = envFile(in: dir, contents: "# comment\nNVIDIA_API_KEY=nvapi-real\n")
        XCTAssertEqual(NvidiaAPILogger.readAPIKey(from: dir + "/.env"), "nvapi-real")
    }

    func testReadAPIKeyMissingFile() {
        XCTAssertNil(NvidiaAPILogger.readAPIKey(from: "/nonexistent/path/.env"))
    }

    func testReadAPIKeyEmptyValue() {
        let dir = tmpDir()
        _ = envFile(in: dir, contents: "NVIDIA_API_KEY=\n")
        XCTAssertNil(NvidiaAPILogger.readAPIKey(from: dir + "/.env"))
    }

    func testReadAPIKeyMissingKeyLine() {
        let dir = tmpDir()
        _ = envFile(in: dir, contents: "OTHER_KEY=something\n")
        XCTAssertNil(NvidiaAPILogger.readAPIKey(from: dir + "/.env"))
    }

    // MARK: - Logger initialisation

    func testLoggerExposesAPIKey() {
        let dir = tmpDir()
        _ = envFile(in: dir, contents: "NVIDIA_API_KEY=nvapi-test\n")
        let logger = NvidiaAPILogger(envPath: dir + "/.env", logPath: logFile(in: dir))
        XCTAssertEqual(logger.apiKey, "nvapi-test")
    }

    func testLoggerNilWhenKeyAbsent() {
        let dir = tmpDir()
        _ = envFile(in: dir, contents: "# no key here\n")
        let logger = NvidiaAPILogger(envPath: dir + "/.env", logPath: logFile(in: dir))
        XCTAssertNil(logger.apiKey)
    }

    // MARK: - Log writing

    func testLogCreatesFile() {
        let dir = tmpDir()
        let log = logFile(in: dir)
        let logger = NvidiaAPILogger(envPath: dir + "/.env", logPath: log)

        logger.log(
            endpoint: "/v1/chat/completions",
            model: "meta/llama-3.1-8b-instruct",
            promptTokens: 10,
            completionTokens: 20,
            statusCode: 200,
            latencyMs: 123.4
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: log))
    }

    func testLogEntryContainsExpectedFields() {
        let dir = tmpDir()
        let log = logFile(in: dir)
        let logger = NvidiaAPILogger(envPath: dir + "/.env", logPath: log)

        logger.log(
            endpoint: "/v1/chat/completions",
            model: "nvidia/nemotron-4-340b-instruct",
            promptTokens: 50,
            completionTokens: 100,
            statusCode: 200,
            latencyMs: 250.0
        )

        let contents = (try? String(contentsOfFile: log, encoding: .utf8)) ?? ""
        XCTAssertTrue(contents.contains("status=200"))
        XCTAssertTrue(contents.contains("model=nvidia/nemotron-4-340b-instruct"))
        XCTAssertTrue(contents.contains("endpoint=/v1/chat/completions"))
        XCTAssertTrue(contents.contains("prompt_tokens=50"))
        XCTAssertTrue(contents.contains("completion_tokens=100"))
        XCTAssertTrue(contents.contains("latency_ms=250.0"))
    }

    func testLogErrorContainsExpectedFields() {
        let dir = tmpDir()
        let log = logFile(in: dir)
        let logger = NvidiaAPILogger(envPath: dir + "/.env", logPath: log)

        logger.logError(
            endpoint: "/v1/chat/completions",
            model: "meta/llama-3.1-8b-instruct",
            error: "rate limit exceeded"
        )

        let contents = (try? String(contentsOfFile: log, encoding: .utf8)) ?? ""
        XCTAssertTrue(contents.contains("ERROR"))
        XCTAssertTrue(contents.contains("rate limit exceeded"))
        XCTAssertTrue(contents.contains("endpoint=/v1/chat/completions"))
    }

    func testMultipleLogEntriesAppend() {
        let dir = tmpDir()
        let log = logFile(in: dir)
        let logger = NvidiaAPILogger(envPath: dir + "/.env", logPath: log)

        for i in 1...3 {
            logger.log(
                endpoint: "/v1/chat/completions",
                model: "meta/llama-3.1-8b-instruct",
                promptTokens: i * 10,
                completionTokens: i * 20,
                statusCode: 200,
                latencyMs: Double(i) * 100
            )
        }

        let contents = (try? String(contentsOfFile: log, encoding: .utf8)) ?? ""
        let lineCount = contents.components(separatedBy: "\n").filter { !$0.isEmpty }.count
        XCTAssertEqual(lineCount, 3)
    }

    // MARK: - NvidiaAIService initialisation

    func testNvidiaAIServiceThrowsWhenNoKey() {
        let dir = tmpDir()
        _ = envFile(in: dir, contents: "NVIDIA_API_KEY=\n")
        let logger = NvidiaAPILogger(envPath: dir + "/.env", logPath: logFile(in: dir))
        XCTAssertThrowsError(try NvidiaAIService(apiKey: nil, logger: logger)) { error in
            XCTAssertEqual(error as? NvidiaAIError, .missingAPIKey)
        }
    }

    func testNvidiaAIServiceInitialisesWithExplicitKey() {
        let dir = tmpDir()
        let logger = NvidiaAPILogger(envPath: dir + "/.env", logPath: logFile(in: dir))
        XCTAssertNoThrow(try NvidiaAIService(apiKey: "nvapi-explicit", logger: logger))
    }

    func testNvidiaAIServiceInitialisesWithEnvKey() {
        let dir = tmpDir()
        _ = envFile(in: dir, contents: "NVIDIA_API_KEY=nvapi-from-env\n")
        let logger = NvidiaAPILogger(envPath: dir + "/.env", logPath: logFile(in: dir))
        XCTAssertNoThrow(try NvidiaAIService(logger: logger))
    }

    // MARK: - NvidiaAIError descriptions

    func testNvidiaAIErrorDescriptions() {
        XCTAssertNotNil(NvidiaAIError.missingAPIKey.errorDescription)
        XCTAssertNotNil(NvidiaAIError.invalidURL.errorDescription)
        XCTAssertNotNil(NvidiaAIError.invalidResponse.errorDescription)
        XCTAssertNotNil(NvidiaAIError.invalidResponseFormat.errorDescription)
        XCTAssertNotNil(NvidiaAIError.apiError(statusCode: 429, message: "rate limit").errorDescription)
        XCTAssertTrue(
            NvidiaAIError.apiError(statusCode: 429, message: "rate limit")
                .errorDescription?.contains("429") == true
        )
    }
}

extension NvidiaAIError: Equatable {
    public static func == (lhs: NvidiaAIError, rhs: NvidiaAIError) -> Bool {
        switch (lhs, rhs) {
        case (.missingAPIKey, .missingAPIKey): return true
        case (.invalidURL, .invalidURL): return true
        case (.invalidResponse, .invalidResponse): return true
        case (.invalidResponseFormat, .invalidResponseFormat): return true
        case (.apiError(let lc, _), .apiError(let rc, _)): return lc == rc
        default: return false
        }
    }
}
