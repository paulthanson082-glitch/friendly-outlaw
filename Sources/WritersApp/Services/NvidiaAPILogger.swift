import Foundation

/// Reads the NVIDIA API key from ~/.local/share/claude-free/.env and logs
/// all NVIDIA NIM API interactions to ~/.local/share/claude-free/proxy.log.
public final class NvidiaAPILogger {

    // MARK: - Public constants

    public static let envFilePath = (
        "~/.local/share/claude-free/.env" as NSString
    ).expandingTildeInPath

    public static let logFilePath = (
        "~/.local/share/claude-free/proxy.log" as NSString
    ).expandingTildeInPath

    // MARK: - Properties

    /// The NVIDIA API key read from the .env file, or nil if not configured.
    public let apiKey: String?

    private let logURL: URL
    private let lock = NSLock()

    private static let iso8601: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    // MARK: - Initialisation

    public init(
        envPath: String = NvidiaAPILogger.envFilePath,
        logPath: String = NvidiaAPILogger.logFilePath
    ) {
        apiKey = NvidiaAPILogger.readAPIKey(from: envPath)
        logURL = URL(fileURLWithPath: logPath)
        ensureLogDirectoryExists()
    }

    // MARK: - Logging

    /// Log a completed NVIDIA API request.
    ///
    /// - Parameters:
    ///   - endpoint: The API path (e.g. `/v1/chat/completions`).
    ///   - model: The model name used in the request.
    ///   - promptTokens: Number of tokens in the prompt.
    ///   - completionTokens: Number of tokens in the completion.
    ///   - statusCode: HTTP status code returned by the API.
    ///   - latencyMs: Round-trip time in milliseconds.
    public func log(
        endpoint: String,
        model: String,
        promptTokens: Int,
        completionTokens: Int,
        statusCode: Int,
        latencyMs: Double
    ) {
        let entry = """
        [\(timestamp())] status=\(statusCode) model=\(model) \
        endpoint=\(endpoint) prompt_tokens=\(promptTokens) \
        completion_tokens=\(completionTokens) latency_ms=\(String(format: "%.1f", latencyMs))
        """
        write(line: entry)
    }

    /// Log an NVIDIA API error.
    ///
    /// - Parameters:
    ///   - endpoint: The API path attempted.
    ///   - model: The model name used in the request.
    ///   - error: Human-readable error description.
    public func logError(
        endpoint: String,
        model: String,
        error: String
    ) {
        let entry = """
        [\(timestamp())] ERROR model=\(model) endpoint=\(endpoint) error=\(error)
        """
        write(line: entry)
    }

    // MARK: - Private helpers

    private func timestamp() -> String {
        NvidiaAPILogger.iso8601.string(from: Date())
    }

    private func write(line: String) {
        lock.lock()
        defer { lock.unlock() }

        let data = (line + "\n").data(using: .utf8) ?? Data()

        if FileManager.default.fileExists(atPath: logURL.path) {
            if let handle = try? FileHandle(forWritingTo: logURL) {
                handle.seekToEndOfFile()
                handle.write(data)
                handle.closeFile()
            }
        } else {
            try? data.write(to: logURL, options: .atomic)
        }
    }

    private func ensureLogDirectoryExists() {
        let dir = logURL.deletingLastPathComponent().path
        try? FileManager.default.createDirectory(
            atPath: dir,
            withIntermediateDirectories: true
        )
    }

    /// Parse `KEY=value` lines from a .env file, returning the value for
    /// `NVIDIA_API_KEY` (strips surrounding quotes if present).
    static func readAPIKey(from path: String) -> String? {
        guard let contents = try? String(contentsOfFile: path, encoding: .utf8) else {
            return nil
        }
        for line in contents.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.hasPrefix("#"), trimmed.hasPrefix("NVIDIA_API_KEY=") else { continue }
            var value = String(trimmed.dropFirst("NVIDIA_API_KEY=".count))
            // Strip optional surrounding quotes
            if (value.hasPrefix("\"") && value.hasSuffix("\"")) ||
               (value.hasPrefix("'") && value.hasSuffix("'")) {
                value = String(value.dropFirst().dropLast())
            }
            return value.isEmpty ? nil : value
        }
        return nil
    }
}

// MARK: - NvidiaAIService

/// Thin wrapper around NVIDIA's OpenAI-compatible NIM API.
///
/// All requests and errors are automatically forwarded to `NvidiaAPILogger`.
public class NvidiaAIService {

    private static let baseURL = "https://integrate.api.nvidia.com/v1"
    private static let chatEndpoint = "/chat/completions"

    private let apiKey: String
    private let model: String
    private let logger: NvidiaAPILogger

    /// - Parameters:
    ///   - apiKey: NVIDIA API key; defaults to the key found in the .env file.
    ///   - model: NIM model identifier (default: `meta/llama-3.1-8b-instruct`).
    ///   - logger: Logger to use; defaults to a new `NvidiaAPILogger`.
    public init(
        apiKey: String? = nil,
        model: String = "meta/llama-3.1-8b-instruct",
        logger: NvidiaAPILogger = NvidiaAPILogger()
    ) throws {
        self.logger = logger
        self.model = model

        if let key = apiKey ?? logger.apiKey, !key.isEmpty {
            self.apiKey = key
        } else {
            throw NvidiaAIError.missingAPIKey
        }
    }

    /// Send a chat completion request to NVIDIA NIM and return the response text.
    ///
    /// - Parameters:
    ///   - messages: Array of `{role, content}` dictionaries.
    ///   - maxTokens: Maximum tokens in the completion.
    ///   - temperature: Sampling temperature.
    public func chatCompletion(
        messages: [[String: String]],
        maxTokens: Int = 1024,
        temperature: Double = 0.7
    ) async throws -> String {
        guard let url = URL(string: Self.baseURL + Self.chatEndpoint) else {
            throw NvidiaAIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": model,
            "messages": messages,
            "max_tokens": maxTokens,
            "temperature": temperature
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let start = Date()
        let (data, response) = try await URLSession.shared.data(for: request)
        let latencyMs = Date().timeIntervalSince(start) * 1000

        guard let http = response as? HTTPURLResponse else {
            logger.logError(endpoint: Self.chatEndpoint, model: model, error: "No HTTP response")
            throw NvidiaAIError.invalidResponse
        }

        guard http.statusCode == 200 else {
            let msg = (try? JSONSerialization.jsonObject(with: data))
                .flatMap { $0 as? [String: Any] }
                .flatMap { $0["error"] as? [String: Any] }
                .flatMap { $0["message"] as? String } ?? "HTTP \(http.statusCode)"
            logger.logError(endpoint: Self.chatEndpoint, model: model, error: msg)
            throw NvidiaAIError.apiError(statusCode: http.statusCode, message: msg)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let first = choices.first,
              let message = first["message"] as? [String: Any],
              let content = message["content"] as? String else {
            logger.logError(endpoint: Self.chatEndpoint, model: model, error: "Unexpected response shape")
            throw NvidiaAIError.invalidResponseFormat
        }

        let usage = json["usage"] as? [String: Any]
        let promptTokens = usage?["prompt_tokens"] as? Int ?? 0
        let completionTokens = usage?["completion_tokens"] as? Int ?? 0

        logger.log(
            endpoint: Self.chatEndpoint,
            model: model,
            promptTokens: promptTokens,
            completionTokens: completionTokens,
            statusCode: http.statusCode,
            latencyMs: latencyMs
        )

        return content
    }
}

// MARK: - Errors

public enum NvidiaAIError: LocalizedError {
    case missingAPIKey
    case invalidURL
    case invalidResponse
    case invalidResponseFormat
    case apiError(statusCode: Int, message: String)

    public var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "NVIDIA API key not found; set NVIDIA_API_KEY in ~/.local/share/claude-free/.env"
        case .invalidURL:
            return "Invalid NVIDIA API URL"
        case .invalidResponse:
            return "Invalid response from NVIDIA API"
        case .invalidResponseFormat:
            return "Could not parse NVIDIA API response"
        case .apiError(let code, let msg):
            return "NVIDIA API error (status \(code)): \(msg)"
        }
    }
}
