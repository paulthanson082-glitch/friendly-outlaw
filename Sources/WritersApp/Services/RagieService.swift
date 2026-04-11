import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Service for document ingestion and retrieval using the Ragie API.
///
/// Ragie is a fully-managed RAG-as-a-Service that handles document chunking,
/// embedding, and semantic retrieval. Use this service to:
/// - Ingest writer documents into Ragie for semantic search
/// - Retrieve relevant context chunks for AI-assisted writing
///
/// API base: https://api.ragie.ai
/// Auth: `Authorization: Bearer <apiKey>`
public class RagieService {
    private let configuration: RagieConfiguration
    private let baseURL = "https://api.ragie.ai"

    public init(configuration: RagieConfiguration) {
        self.configuration = configuration
    }

    // MARK: - Document Ingestion

    /// Ingest raw text content into Ragie as a named document.
    ///
    /// The document will be chunked and embedded asynchronously. Poll
    /// `getDocument(id:)` until `isReady` is true before querying.
    ///
    /// - Parameters:
    ///   - text: The raw text content to ingest.
    ///   - name: An optional display name for the document.
    ///   - metadata: Optional key-value metadata for filtering retrievals.
    /// Ingests raw text as a Ragie document.
    /// - Parameters:
    ///   - text: The raw text content to ingest.
    ///   - name: An optional human-readable name for the document.
    ///   - metadata: Optional key/value metadata to attach to the document.
    /// - Returns: A `RagieDocument` containing the created document's `id`, `status`, optional `name`, and optional `chunkCount`.
    /// - Throws: `RagieServiceError.invalidURL` if the service URL cannot be constructed; `RagieServiceError.invalidResponseFormat` if the API response is missing expected fields; `RagieServiceError.networkError` for underlying networking failures; `RagieServiceError.apiError` for non-2xx API responses.
    public func ingestRawText(
        _ text: String,
        name: String? = nil,
        metadata: [String: String] = [:]
    ) async throws -> RagieDocument {
        guard let url = URL(string: "\(baseURL)/documents/raw") else {
            throw RagieServiceError.invalidURL
        }

        var body: [String: Any] = ["data": text]
        if let name = name {
            body["name"] = name
        }
        if !metadata.isEmpty {
            body["metadata"] = metadata
        }

        let request = try buildRequest(url: url, method: "POST", body: body)
        let data = try await performRequest(request)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let id = json["id"] as? String,
              let status = json["status"] as? String else {
            throw RagieServiceError.invalidResponseFormat
        }

        return RagieDocument(
            id: id,
            status: status,
            name: json["name"] as? String,
            chunkCount: json["chunk_count"] as? Int
        )
    }

    /// Ingest a document from a URL into Ragie.
    ///
    /// - Parameters:
    ///   - documentURL: The URL of the document to ingest.
    ///   - name: An optional display name for the document.
    ///   - metadata: Optional key-value metadata for filtering retrievals.
    /// Ingests a document from the specified public URL into Ragie and returns its ingestion record.
    /// - Parameters:
    ///   - documentURL: The publicly accessible URL of the document to ingest.
    ///   - name: An optional display name to assign to the ingested document.
    ///   - metadata: Optional key/value metadata to attach to the document.
    /// - Returns: A `RagieDocument` containing the document `id`, current `status`, optional `name`, and optional `chunkCount`.
    /// - Throws: `RagieServiceError.invalidURL` if the service endpoint URL cannot be constructed; `RagieServiceError.invalidResponseFormat` if the API response is missing expected fields; `RagieServiceError.networkError(_)` for transport errors; or `RagieServiceError.apiError(statusCode:message:)` for non-2xx API responses.
    public func ingestURL(
        _ documentURL: String,
        name: String? = nil,
        metadata: [String: String] = [:]
    ) async throws -> RagieDocument {
        guard let url = URL(string: "\(baseURL)/documents/url") else {
            throw RagieServiceError.invalidURL
        }

        // Validate the document URL for SSRF safety
        if let documentURLObject = URL(string: documentURL) {
            let ssrfResult = NetworkSecurity.validateSSRFSafety(url: documentURLObject)
            guard ssrfResult.isAllowed else {
                throw RagieServiceError.invalidURL
            }
        }

        var body: [String: Any] = ["url": documentURL]
        if let name = name {
            body["name"] = name
        }
        if !metadata.isEmpty {
            body["metadata"] = metadata
        }

        let request = try buildRequest(url: url, method: "POST", body: body)
        let data = try await performRequest(request)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let id = json["id"] as? String,
              let status = json["status"] as? String else {
            throw RagieServiceError.invalidResponseFormat
        }

        return RagieDocument(
            id: id,
            status: status,
            name: json["name"] as? String,
            chunkCount: json["chunk_count"] as? Int
        )
    }

    // MARK: - Document Status

    /// Fetch the current status of a Ragie document.
    ///
    /// - Parameter id: The document id returned by `ingestRawText` or `ingestURL`.
    /// - Returns: A `RagieDocument` with the current status. `isReady` is true when
    /// Fetches the current status and metadata for a Ragie document by its identifier.
    /// - Parameters:
    ///   - id: The Ragie document identifier.
    /// - Returns: A `RagieDocument` containing the document's `id`, `status`, optional `name`, and optional `chunkCount`.
    /// - Throws: `RagieServiceError.invalidURL` if the request URL cannot be constructed; `RagieServiceError.invalidResponseFormat` if the API response JSON is missing expected fields; `RagieServiceError.networkError` for underlying networking failures; `RagieServiceError.apiError(statusCode:message:)` for non-2xx API responses.
    public func getDocument(id: String) async throws -> RagieDocument {
        guard let url = URL(string: "\(baseURL)/documents/\(id)") else {
            throw RagieServiceError.invalidURL
        }

        let request = try buildRequest(url: url, method: "GET", body: nil)
        let data = try await performRequest(request)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let docId = json["id"] as? String,
              let status = json["status"] as? String else {
            throw RagieServiceError.invalidResponseFormat
        }

        return RagieDocument(
            id: docId,
            status: status,
            name: json["name"] as? String,
            chunkCount: json["chunk_count"] as? Int
        )
    }

    // MARK: - Retrieval

    /// Retrieve semantically relevant chunks from Ragie for a given query.
    ///
    /// - Parameters:
    ///   - query: The natural-language query to search for.
    ///   - topK: Override the number of chunks to return (defaults to `configuration.topK`).
    ///   - rerank: Override reranking behavior (defaults to `configuration.rerank`).
    ///   - filter: Optional metadata filter expression to restrict which documents are searched.
    /// Retrieves semantically relevant document chunks for the given query.
    /// - Parameters:
    ///   - query: The natural-language query used to find relevant chunks.
    ///   - topK: Maximum number of chunks to return; defaults to the service configuration's `topK` when `nil`.
    ///   - rerank: Whether to perform reranking on candidates; defaults to the service configuration's `rerank` when `nil`.
    ///   - filter: Optional constraints applied to the retrieval (document-level filters) represented as a JSON-like dictionary.
    /// - Returns: A `RagieRetrievalResult` containing the original query and the array of scored `RagieChunk` items.
    /// - Throws: `RagieServiceError.invalidURL` if the retrieval endpoint URL cannot be constructed; `RagieServiceError.invalidResponseFormat` if the API response structure is not as expected; or other `RagieServiceError` cases for network or API errors.
    public func retrieve(
        query: String,
        topK: Int? = nil,
        rerank: Bool? = nil,
        filter: [String: Any]? = nil
    ) async throws -> RagieRetrievalResult {
        guard let url = URL(string: "\(baseURL)/retrievals") else {
            throw RagieServiceError.invalidURL
        }

        var body: [String: Any] = [
            "query": query,
            "top_k": topK ?? configuration.topK,
            "rerank": rerank ?? configuration.rerank
        ]
        if let filter = filter {
            body["filter"] = filter
        }

        let request = try buildRequest(url: url, method: "POST", body: body)
        let data = try await performRequest(request)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let scoredChunks = json["scored_chunks"] as? [[String: Any]] else {
            throw RagieServiceError.invalidResponseFormat
        }

        let chunks = scoredChunks.compactMap { chunk -> RagieChunk? in
            guard let text = chunk["text"] as? String,
                  let chunkId = chunk["id"] as? String,
                  let documentId = chunk["document_id"] as? String else {
                return nil
            }
            // The Ragie API may return score as a JSON integer (0, 1) or float
            let score: Double
            if let d = chunk["score"] as? Double {
                score = d
            } else if let i = chunk["score"] as? Int {
                score = Double(i)
            } else {
                return nil
            }
            return RagieChunk(
                text: text,
                score: score,
                id: chunkId,
                documentId: documentId,
                documentName: chunk["document_name"] as? String
            )
        }

        return RagieRetrievalResult(query: query, chunks: chunks)
    }

    // MARK: - Document Listing

    /// List all documents stored in Ragie.
    ///
    /// Lists all documents previously ingested into Ragie.
    /// - Returns: An array of `RagieDocument` objects representing each ingested document.
    /// - Throws:
    ///   - `RagieServiceError.invalidURL` if the service URL cannot be constructed.
    ///   - `RagieServiceError.invalidResponseFormat` if the API response JSON does not contain the expected structure.
    ///   - `RagieServiceError.networkError` for underlying network failures returned by the request layer.
    ///   - `RagieServiceError.apiError` when the API responds with a non-2xx status and an error message.
    public func listDocuments() async throws -> [RagieDocument] {
        guard let url = URL(string: "\(baseURL)/documents") else {
            throw RagieServiceError.invalidURL
        }

        let request = try buildRequest(url: url, method: "GET", body: nil)
        let data = try await performRequest(request)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let results = json["results"] as? [[String: Any]] else {
            throw RagieServiceError.invalidResponseFormat
        }

        return results.compactMap { doc -> RagieDocument? in
            guard let id = doc["id"] as? String,
                  let status = doc["status"] as? String else {
                return nil
            }
            return RagieDocument(
                id: id,
                status: status,
                name: doc["name"] as? String,
                chunkCount: doc["chunk_count"] as? Int
            )
        }
    }

    /// Builds a URLRequest with the given HTTP method, Bearer authorization header, JSON accept/content headers, and an optional JSON-encoded body.
    /// - Parameters:
    ///   - url: The request URL.
    ///   - method: The HTTP method (e.g., "GET", "POST").
    ///   - body: An optional dictionary to encode as a JSON request body.
    /// - Returns: A configured `URLRequest`.
    /// - Throws: An error from `JSONSerialization.data(withJSONObject:)` if the provided `body` cannot be encoded as JSON.

    private func buildRequest(url: URL, method: String, body: [String: Any]?) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(configuration.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "accept")

        if let body = body {
            request.setValue("application/json", forHTTPHeaderField: "content-type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        return request
    }

    /// Executes the given URLRequest and returns the response body data.
    /// 
    /// Performs the network request, validates that the response is an HTTP response with a 2xx status code, and returns the response body.
    /// - Returns: The response body as `Data`.
    /// - Throws: `RagieServiceError.networkError` if the network request fails.
    /// - Throws: `RagieServiceError.invalidResponse` if the response is not an `HTTPURLResponse`.
    /// - Throws: `RagieServiceError.apiError` if the HTTP status code is not in the 200–299 range; the error includes the status code and any message decoded from the response body.
    private func performRequest(_ request: URLRequest) async throws -> Data {
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw RagieServiceError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw RagieServiceError.invalidResponse
        }

        guard httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw RagieServiceError.apiError(statusCode: httpResponse.statusCode, message: message)
        }

        return data
    }
}
