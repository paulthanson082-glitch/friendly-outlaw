import Foundation

// MARK: - Ragie Configuration

/// Configuration for the Ragie document retrieval service
public struct RagieConfiguration: Codable {
    public let apiKey: String
    public let topK: Int
    public let rerank: Bool

    public init(
        apiKey: String,
        topK: Int = 8,
        rerank: Bool = false
    ) {
        self.apiKey = apiKey
        self.topK = topK
        self.rerank = rerank
    }
}

// MARK: - Ragie Document

/// A document stored in Ragie
public struct RagieDocument: Codable {
    public let id: String
    public let status: String
    public let name: String?
    public let chunkCount: Int?

    public var isReady: Bool {
        return status == "ready"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case status
        case name
        case chunkCount = "chunk_count"
    }

    public init(id: String, status: String, name: String? = nil, chunkCount: Int? = nil) {
        self.id = id
        self.status = status
        self.name = name
        self.chunkCount = chunkCount
    }
}

// MARK: - Ragie Retrieval

/// A chunk returned by a Ragie retrieval query
public struct RagieChunk: Codable {
    public let text: String
    public let score: Double
    public let id: String
    public let documentId: String
    public let documentName: String?

    enum CodingKeys: String, CodingKey {
        case text
        case score
        case id
        case documentId = "document_id"
        case documentName = "document_name"
    }

    public init(
        text: String,
        score: Double,
        id: String,
        documentId: String,
        documentName: String? = nil
    ) {
        self.text = text
        self.score = score
        self.id = id
        self.documentId = documentId
        self.documentName = documentName
    }
}

/// Result of a Ragie retrieval query
public struct RagieRetrievalResult: Codable {
    public let query: String
    public let chunks: [RagieChunk]

    public var combinedText: String {
        chunks.map(\.text).joined(separator: "\n\n")
    }

    public init(query: String, chunks: [RagieChunk]) {
        self.query = query
        self.chunks = chunks
    }
}

// MARK: - Ragie Errors

public enum RagieServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case invalidResponseFormat
    case apiError(statusCode: Int, message: String)
    case networkError(Error)
    case documentNotReady(status: String)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid Ragie API URL"
        case .invalidResponse:
            return "Invalid response from Ragie API"
        case .invalidResponseFormat:
            return "Could not parse Ragie API response"
        case .apiError(let statusCode, let message):
            return "Ragie API error (status \(statusCode)): \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .documentNotReady(let status):
            return "Document is not ready for retrieval (status: \(status))"
        }
    }
}
