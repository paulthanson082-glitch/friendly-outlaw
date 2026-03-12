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
    /// - Returns: A `RagieDocument` with the new document's id and initial status.
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
    /// - Returns: A `RagieDocument` with the new document's id and initial status.
    public func ingestURL(
        _ documentURL: String,
        name: String? = nil,
        metadata: [String: String] = [:]
    ) async throws -> RagieDocument {
        guard let url = URL(string: "\(baseURL)/documents/url") else {
            throw RagieServiceError.invalidURL
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
    ///            the document has been fully processed and is available for retrieval.
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
    /// - Returns: A `RagieRetrievalResult` containing the matching chunks.
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
    /// - Returns: An array of `RagieDocument` representing all ingested documents.
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

    // MARK: - HTTP Helpers

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
