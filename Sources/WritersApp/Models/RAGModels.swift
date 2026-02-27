import Foundation

// MARK: - RAG Error Type

/// Errors that can occur during RAG operations
public enum RAGError: LocalizedError {
    case indexingFailed(String)
    case retrievalFailed(String)
    case rerankingFailed(String)
    case databaseError(String)
    case invalidQuery(String)
    case noChunksFound

    public var errorDescription: String? {
        switch self {
        case .indexingFailed(let message):
            return "RAG indexing failed: \(message)"
        case .retrievalFailed(let message):
            return "RAG retrieval failed: \(message)"
        case .rerankingFailed(let message):
            return "RAG re-ranking failed: \(message)"
        case .databaseError(let message):
            return "RAG database error: \(message)"
        case .invalidQuery(let message):
            return "Invalid query: \(message)"
        case .noChunksFound:
            return "No document chunks found for retrieval"
        }
    }
}

// MARK: - Document Chunk

/// A chunk of text extracted from a document for indexing and retrieval
public struct DocumentChunk: Codable, Identifiable {
    public let id: UUID
    public let documentId: UUID
    public let chunkIndex: Int
    public var text: String
    public var summary: String
    public let createdAt: Date
    public var lastIndexedAt: Date?

    public init(
        id: UUID = UUID(),
        documentId: UUID,
        chunkIndex: Int,
        text: String,
        summary: String = "",
        createdAt: Date = Date(),
        lastIndexedAt: Date? = nil
    ) {
        self.id = id
        self.documentId = documentId
        self.chunkIndex = chunkIndex
        self.text = text
        self.summary = summary
        self.createdAt = createdAt
        self.lastIndexedAt = lastIndexedAt
    }

    /// Word count of the chunk
    public var wordCount: Int {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        return words.filter { !$0.isEmpty }.count
    }

    /// Character count of the chunk
    public var characterCount: Int {
        return text.count
    }
}

// MARK: - Ranking Score

/// Score for a chunk based on query relevance
public struct RankingScore: Codable, Identifiable {
    public let id: UUID
    public let chunkId: UUID
    public let queryHash: String
    public var relevanceScore: Double
    public var rankPosition: Int
    public let scoredAt: Date

    public init(
        id: UUID = UUID(),
        chunkId: UUID,
        queryHash: String,
        relevanceScore: Double,
        rankPosition: Int,
        scoredAt: Date = Date()
    ) {
        self.id = id
        self.chunkId = chunkId
        self.queryHash = queryHash
        self.relevanceScore = relevanceScore
        self.rankPosition = rankPosition
        self.scoredAt = scoredAt
    }
}

// MARK: - Retrieval Result

/// Result from a document chunk retrieval operation
public struct RetrievalResult: Codable, Identifiable {
    public let id: UUID
    public let chunk: DocumentChunk
    public var relevanceScore: Double
    public var retrievalMethod: RetrievalMethod
    public let retrievedAt: Date

    public enum RetrievalMethod: String, Codable {
        case semanticSimilarity
        case bm25KeywordMatch
        case hybridSearch
        case rerankingByAI
    }

    public init(
        id: UUID = UUID(),
        chunk: DocumentChunk,
        relevanceScore: Double,
        retrievalMethod: RetrievalMethod = .semanticSimilarity,
        retrievedAt: Date = Date()
    ) {
        self.id = id
        self.chunk = chunk
        self.relevanceScore = relevanceScore
        self.retrievalMethod = retrievalMethod
        self.retrievedAt = retrievedAt
    }
}

// MARK: - Evaluation Metrics

/// Metrics for evaluating RAG system performance
public struct RAGEvaluationMetrics: Codable {
    public var precision: Double
    public var recall: Double
    public var f1Score: Double
    public var meanReciprocalRank: Double
    public var endToEndAccuracy: Double
    public var totalQueries: Int
    public var correctAnswers: Int
    public let evaluatedAt: Date

    public init(
        precision: Double = 0.0,
        recall: Double = 0.0,
        f1Score: Double = 0.0,
        meanReciprocalRank: Double = 0.0,
        endToEndAccuracy: Double = 0.0,
        totalQueries: Int = 0,
        correctAnswers: Int = 0,
        evaluatedAt: Date = Date()
    ) {
        self.precision = precision
        self.recall = recall
        self.f1Score = f1Score
        self.meanReciprocalRank = meanReciprocalRank
        self.endToEndAccuracy = endToEndAccuracy
        self.totalQueries = totalQueries
        self.correctAnswers = correctAnswers
        self.evaluatedAt = evaluatedAt
    }
}

// MARK: - Retrieval Context

/// Context information for a retrieval operation
public struct RetrievalContext: Codable {
    public var query: String
    public var topK: Int
    public var includeContext: Bool
    public var rerankWithAI: Bool
    public let createdAt: Date

    public init(
        query: String,
        topK: Int = 5,
        includeContext: Bool = true,
        rerankWithAI: Bool = true,
        createdAt: Date = Date()
    ) {
        self.query = query
        self.topK = topK
        self.includeContext = includeContext
        self.rerankWithAI = rerankWithAI
        self.createdAt = createdAt
    }
}

// MARK: - Query Evaluation

/// Evaluation case for RAG system testing
public struct RAGQueryEvaluation: Codable, Identifiable {
    public let id: UUID
    public let query: String
    public let correctChunkIds: [UUID]
    public var retrievedChunkIds: [UUID]
    public var retrievalPrecision: Double
    public var retrievalRecall: Double
    public var retrievalMRR: Double
    public var endToEndCorrect: Bool
    public let evaluatedAt: Date

    public init(
        id: UUID = UUID(),
        query: String,
        correctChunkIds: [UUID],
        retrievedChunkIds: [UUID] = [],
        retrievalPrecision: Double = 0.0,
        retrievalRecall: Double = 0.0,
        retrievalMRR: Double = 0.0,
        endToEndCorrect: Bool = false,
        evaluatedAt: Date = Date()
    ) {
        self.id = id
        self.query = query
        self.correctChunkIds = correctChunkIds
        self.retrievedChunkIds = retrievedChunkIds
        self.retrievalPrecision = retrievalPrecision
        self.retrievalRecall = retrievalRecall
        self.retrievalMRR = retrievalMRR
        self.endToEndCorrect = endToEndCorrect
        self.evaluatedAt = evaluatedAt
    }
}
