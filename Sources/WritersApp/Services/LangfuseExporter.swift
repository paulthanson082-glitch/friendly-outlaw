import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Configuration for Langfuse trace export, read from environment variables.
///
/// Expected env vars:
/// ```json
/// {
///   "TRACE_TO_LANGFUSE": "true",
///   "LANGFUSE_PUBLIC_KEY": "pk-lf-...",
///   "LANGFUSE_SECRET_KEY": "sk-lf-...",
///   "LANGFUSE_HOST": "https://cloud.langfuse.com"
/// }
/// ```
public struct LangfuseConfiguration {
    public let publicKey: String
    public let secretKey: String
    public let host: String

    public init(publicKey: String, secretKey: String, host: String = "https://cloud.langfuse.com") {
        self.publicKey = publicKey
        self.secretKey = secretKey
        self.host = host.hasSuffix("/") ? String(host.dropLast()) : host
    }

    /// Reads configuration from environment variables. Returns nil if disabled or missing keys.
    public static func fromEnvironment() -> LangfuseConfiguration? {
        let env = ProcessInfo.processInfo.environment

        guard let enabled = env["TRACE_TO_LANGFUSE"],
              enabled.lowercased() == "true" else {
            return nil
        }

        guard let publicKey = env["LANGFUSE_PUBLIC_KEY"], !publicKey.isEmpty,
              let secretKey = env["LANGFUSE_SECRET_KEY"], !secretKey.isEmpty else {
            return nil
        }

        let host = env["LANGFUSE_HOST"] ?? "https://cloud.langfuse.com"
        return LangfuseConfiguration(publicKey: publicKey, secretKey: secretKey, host: host)
    }

    /// Basic auth header value (public_key:secret_key base64-encoded)
    var authorizationHeader: String {
        let credentials = "\(publicKey):\(secretKey)"
        let data = credentials.data(using: .utf8) ?? Data()
        return "Basic \(data.base64EncodedString())"
    }
}

/// Errors from Langfuse operations
public enum LangfuseError: LocalizedError {
    case notConfigured
    case invalidURL
    case apiError(statusCode: Int, message: String)
    case networkError(Error)
    case invalidResponse

    public var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Langfuse is not configured. Set TRACE_TO_LANGFUSE=true with valid keys."
        case .invalidURL:
            return "Invalid Langfuse host URL"
        case .apiError(let code, let message):
            return "Langfuse API error (status \(code)): \(message)"
        case .networkError(let error):
            return "Langfuse network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from Langfuse API"
        }
    }
}

/// Exports traces and observations to Langfuse via its ingestion API.
///
/// Uses the Langfuse `/api/public/ingestion` batch endpoint to send
/// trace and observation events in a single request.
public class LangfuseExporter {

    private let configuration: LangfuseConfiguration
    private let ingestionURL: String

    public init(configuration: LangfuseConfiguration) {
        self.configuration = configuration
        self.ingestionURL = "\(configuration.host)/api/public/ingestion"
    }

    /// Attempts to create an exporter from environment variables.
    /// Returns nil if TRACE_TO_LANGFUSE is not "true" or keys are missing.
    public static func fromEnvironment() -> LangfuseExporter? {
        guard let config = LangfuseConfiguration.fromEnvironment() else { return nil }
        return LangfuseExporter(configuration: config)
    }

    /// Whether Langfuse export is configured and available
    public var isConfigured: Bool { true }

    // MARK: - Export Operations

    /// Exports a single trace with its observations to Langfuse
    public func exportTrace(_ trace: Trace, observations: [Observation]) async throws {
        try await exportBatch(traces: [trace], observations: observations)
    }

    /// Exports multiple traces and observations in a single batch request
    public func exportBatch(traces: [Trace], observations: [Observation]) async throws {
        var events: [[String: Any]] = []

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        for trace in traces {
            var body: [String: Any] = [
                "id": trace.id.uuidString,
                "name": trace.name,
                "sessionId": trace.sessionId,
                "timestamp": dateFormatter.string(from: trace.startTime)
            ]
            if let endTime = trace.endTime {
                body["endTime"] = dateFormatter.string(from: endTime)
            }
            if let metadata = trace.metadata {
                body["metadata"] = ["raw": metadata]
            }

            events.append([
                "type": "trace-create",
                "id": UUID().uuidString,
                "timestamp": dateFormatter.string(from: Date()),
                "body": body
            ])
        }

        for obs in observations {
            var body: [String: Any] = [
                "id": obs.id.uuidString,
                "traceId": obs.traceId.uuidString,
                "type": "SPAN",
                "name": obs.name,
                "startTime": dateFormatter.string(from: obs.startTime)
            ]
            if let endTime = obs.endTime {
                body["endTime"] = dateFormatter.string(from: endTime)
            }
            if let input = obs.input {
                body["input"] = ["value": input]
            }
            if let output = obs.output {
                body["output"] = ["value": output]
            }
            if let status = obs.statusMessage {
                body["statusMessage"] = status
            }

            events.append([
                "type": "observation-create",
                "id": UUID().uuidString,
                "timestamp": dateFormatter.string(from: Date()),
                "body": body
            ])
        }

        if events.isEmpty { return }

        try await sendIngestionBatch(events: events)
    }

    /// Exports all traces and observations from the database to Langfuse
    public func exportAll(from databaseManager: DatabaseManager) async throws -> (traces: Int, observations: Int) {
        let traces = try databaseManager.getTraces()
        var allObservations: [Observation] = []

        for trace in traces {
            let obs = try databaseManager.getObservations(traceId: trace.id)
            allObservations.append(contentsOf: obs)
        }

        // Send in batches of 50 events to avoid oversized payloads
        let batchSize = 25
        for startIndex in stride(from: 0, to: traces.count, by: batchSize) {
            let endIndex = min(startIndex + batchSize, traces.count)
            let traceBatch = Array(traces[startIndex..<endIndex])
            let traceIds = Set(traceBatch.map { $0.id })
            let obsBatch = allObservations.filter { traceIds.contains($0.traceId) }
            try await exportBatch(traces: traceBatch, observations: obsBatch)
        }

        return (traces: traces.count, observations: allObservations.count)
    }

    // MARK: - HTTP

    private func sendIngestionBatch(events: [[String: Any]]) async throws {
        guard let url = URL(string: ingestionURL) else {
            throw LangfuseError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(configuration.authorizationHeader, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = ["batch": events]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LangfuseError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw LangfuseError.apiError(statusCode: httpResponse.statusCode, message: message)
        }
    }
}
