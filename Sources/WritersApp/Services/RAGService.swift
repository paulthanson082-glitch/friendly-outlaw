import Foundation

/// Service for Retrieval-Augmented Generation (RAG) functionality
/// Implements Summary Indexing + Re-Ranking approach
public class RAGService {
    private var indexedChunks: [DocumentChunk] = []
    private var rankingScores: [RankingScore] = []
    private var chunkSummaries: [UUID: String] = [:]
    private let documentManager: DocumentManager
    private weak var aiService: AIService?
    private let chunkSize: Int = 500  // words per chunk
    private let overlapSize: Int = 50  // overlap in words

    public init(documentManager: DocumentManager, aiService: AIService? = nil) {
        self.documentManager = documentManager
        self.aiService = aiService
    }

    // MARK: - Indexing

    /// Index a document by breaking it into chunks with summaries
    public func indexDocument(documentId: UUID) async throws {
        guard let document = documentManager.getDocument(id: documentId) else {
            throw RAGError.retrievalFailed("Document not found: \(documentId)")
        }

        // Split document into chunks
        let chunks = splitDocumentIntoChunks(
            document: document,
            documentId: documentId
        )

        guard !chunks.isEmpty else {
            throw RAGError.indexingFailed("Document produced no chunks")
        }

        // Validate chunks
        for chunk in chunks {
            guard !chunk.text.isEmpty else {
                throw RAGError.invalidQuery("Empty chunk text")
            }
        }

        // Store chunks
        indexedChunks.append(contentsOf: chunks)

        // Generate summaries for each chunk if AI is available
        if let aiService = aiService {
            for i in 0 ..< chunks.count {
                do {
                    let summary = try await generateChunkSummary(
                        text: chunks[i].text,
                        aiService: aiService
                    )
                    indexedChunks[indexedChunks.count - chunks.count + i].summary = summary
                    chunkSummaries[chunks[i].id] = summary
                } catch {
                    // Degrade gracefully: use text preview as summary
                    let preview = String(chunks[i].text.prefix(200))
                    indexedChunks[indexedChunks.count - chunks.count + i].summary = preview
                    chunkSummaries[chunks[i].id] = preview
                }
            }
        }
    }

    /// Retrieve relevant chunks for a query
    public func retrieveRelevantChunks(
        query: String,
        topK: Int = 5
    ) async throws -> [RetrievalResult] {
        guard !query.isEmpty else {
            throw RAGError.invalidQuery("Query cannot be empty")
        }

        guard !indexedChunks.isEmpty else {
            throw RAGError.noChunksFound
        }

        // Validate query length
        guard query.count < 10000 else {
            throw RAGError.invalidQuery("Query too long (max 10000 characters)")
        }

        // Calculate similarity scores using BM25-like approach
        let scoredChunks = calculateSimilarityScores(query: query)

        // Sort by relevance score (descending)
        let sortedChunks = scoredChunks.sorted { $0.relevanceScore > $1.relevanceScore }

        // Return top K results
        let topResults = Array(sortedChunks.prefix(topK))

        // Store ranking scores
        let queryHash = hashQuery(query)
        for (index, result) in topResults.enumerated() {
            let score = RankingScore(
                chunkId: result.chunk.id,
                queryHash: queryHash,
                relevanceScore: result.relevanceScore,
                rankPosition: index + 1
            )
            rankingScores.append(score)
        }

        return topResults
    }

    /// Re-rank retrieved chunks using Claude for improved relevance
    public func rerankResults(
        results: [RetrievalResult],
        query: String
    ) async throws -> [RetrievalResult] {
        guard let aiService = aiService else {
            // No AI available, return original results
            return results
        }

        guard !results.isEmpty else {
            return results
        }

        guard !query.isEmpty else {
            throw RAGError.invalidQuery("Query cannot be empty")
        }

        // Create ranking prompt for Claude
        let rankingPrompt = createRankingPrompt(chunks: results, query: query)

        do {
            let rankingResponse = try await aiService.getAssistance(
                text: rankingPrompt,
                type: .custom("Rank document chunks by relevance")
            )

            // Parse Claude's response to extract ranking
            let rerankedResults = try parseRankingResponse(
                response: rankingResponse.generatedContent,
                originalResults: results
            )

            return rerankedResults
        } catch {
            // Degrade gracefully: return original results if re-ranking fails
            return results
        }
    }

    // MARK: - Evaluation

    /// Evaluate RAG performance on a set of test queries
    public func evaluateRetrieval(
        testCases: [RAGQueryEvaluation]
    ) -> RAGEvaluationMetrics {
        var totalPrecision = 0.0
        var totalRecall = 0.0
        var totalMRR = 0.0
        var correctCount = 0

        for testCase in testCases {
            let retrieved = testCase.retrievedChunkIds
            let correct = Set(testCase.correctChunkIds)
            let retrievedSet = Set(retrieved)

            // Calculate precision: correct / retrieved
            let precision = retrievedSet.isEmpty
                ? 0.0
                : Double(retrievedSet.intersection(correct).count) / Double(retrieved.count)

            // Calculate recall: correct / total correct
            let recall = correct.isEmpty
                ? 0.0
                : Double(retrievedSet.intersection(correct).count) / Double(correct.count)

            // Calculate MRR: 1 / rank of first correct result
            var mrr = 0.0
            for (index, chunkId) in retrieved.enumerated() {
                if correct.contains(chunkId) {
                    mrr = 1.0 / Double(index + 1)
                    break
                }
            }

            totalPrecision += precision
            totalRecall += recall
            totalMRR += mrr

            if testCase.endToEndCorrect {
                correctCount += 1
            }
        }

        let count = Double(testCases.count)
        let avgPrecision = count > 0 ? totalPrecision / count : 0.0
        let avgRecall = count > 0 ? totalRecall / count : 0.0
        let avgMRR = count > 0 ? totalMRR / count : 0.0
        let f1Score = calculateF1(precision: avgPrecision, recall: avgRecall)
        let endToEndAccuracy = count > 0 ? Double(correctCount) / count : 0.0

        return RAGEvaluationMetrics(
            precision: avgPrecision,
            recall: avgRecall,
            f1Score: f1Score,
            meanReciprocalRank: avgMRR,
            endToEndAccuracy: endToEndAccuracy,
            totalQueries: testCases.count,
            correctAnswers: correctCount
        )
    }

    // MARK: - Private Helpers

    /// Split document into overlapping chunks
    private func splitDocumentIntoChunks(
        document: Document,
        documentId: UUID
    ) -> [DocumentChunk] {
        let words = document.content.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }

        var chunks: [DocumentChunk] = []
        var currentIndex = 0
        var chunkNumber = 0

        while currentIndex < words.count {
            let endIndex = min(currentIndex + chunkSize, words.count)
            let chunkWords = Array(words[currentIndex ..< endIndex])
            let chunkText = chunkWords.joined(separator: " ")

            let chunk = DocumentChunk(
                documentId: documentId,
                chunkIndex: chunkNumber,
                text: chunkText
            )

            chunks.append(chunk)

            // Move forward with overlap
            currentIndex = endIndex - overlapSize
            if currentIndex < 0 {
                currentIndex = endIndex
            }
            chunkNumber += 1
        }

        return chunks
    }

    /// Generate summary for a chunk using Claude
    private func generateChunkSummary(
        text: String,
        aiService: AIService
    ) async throws -> String {
        let summaryPrompt = """
        Summarize the following text in 1-2 sentences, capturing the key information:

        \(text)

        Summary:
        """

        do {
            let response = try await aiService.getAssistance(
                text: summaryPrompt,
                type: .summarize
            )
            // Validate summary
            guard !response.generatedContent.isEmpty else {
                return String(text.prefix(200))
            }
            return response.generatedContent
        } catch {
            throw RAGError.rerankingFailed("Failed to generate summary: \(error)")
        }
    }

    /// Calculate similarity scores for chunks against query using keyword matching
    private func calculateSimilarityScores(query: String) -> [RetrievalResult] {
        let queryTerms = query.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }

        var results: [RetrievalResult] = []

        for chunk in indexedChunks {
            // Score based on term frequency and summary relevance
            let chunkText = chunk.text.lowercased()
            let summaryText = chunk.summary.lowercased()

            var score = 0.0

            for term in queryTerms {
                // Count occurrences in text (weight by position in summary)
                let textMatches = chunkText.components(separatedBy: term).count - 1
                let summaryMatches = summaryText.components(separatedBy: term).count - 1

                // Summary matches weighted higher (2x)
                score += Double(summaryMatches) * 2.0 + Double(textMatches)
            }

            // Normalize by query and chunk size
            let queryWeight = Double(queryTerms.count)
            let chunkWeight = Double(chunk.wordCount)

            if queryWeight > 0 && chunkWeight > 0 {
                score = score / (queryWeight * log(chunkWeight + 1))
            }

            let result = RetrievalResult(
                chunk: chunk,
                relevanceScore: score,
                retrievalMethod: .bm25KeywordMatch
            )
            results.append(result)
        }

        return results
    }

    /// Create prompt for Claude to rank chunks
    private func createRankingPrompt(
        chunks: [RetrievalResult],
        query: String
    ) -> String {
        let chunksList = chunks.enumerated()
            .map { (index, result) in
                """
                Chunk \(index + 1):
                \(result.chunk.summary)
                ---
                \(result.chunk.text.prefix(300))...
                """
            }
            .joined(separator: "\n\n")

        return """
        You are a relevance ranking expert. Given the following query and document chunks, \
        rank them by relevance to the query (most relevant first).

        Query: \(query)

        Chunks:
        \(chunksList)

        Provide the ranking as a JSON array with chunk indices in order of relevance:
        {"ranking": [1, 2, 3]}
        """
    }

    /// Parse Claude's ranking response
    private func parseRankingResponse(
        response: String,
        originalResults: [RetrievalResult]
    ) throws -> [RetrievalResult] {
        // Try to extract JSON from response
        guard let jsonData = response.data(using: .utf8),
              let jsonObject = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let rankingArray = jsonObject["ranking"] as? [Int]
        else {
            // If parsing fails, return original results
            return originalResults
        }

        var reranked: [RetrievalResult] = []

        for (index, originalIndex) in rankingArray.enumerated() {
            let arrayIndex = originalIndex - 1  // Convert to 0-based indexing
            if arrayIndex >= 0 && arrayIndex < originalResults.count {
                var result = originalResults[arrayIndex]
                result.retrievalMethod = .rerankingByAI
                reranked.append(result)
            }
        }

        return !reranked.isEmpty ? reranked : originalResults
    }

    /// Hash a query for efficient storage
    private func hashQuery(_ query: String) -> String {
        let data = query.data(using: .utf8) ?? Data()
        let hash = data.withUnsafeBytes { buffer in
            var hashValue: UInt32 = 5381
            for byte in buffer {
                hashValue = ((hashValue << 5) &+ hashValue) &+ UInt32(byte)
            }
            return hashValue
        }
        return String(hash)
    }

    /// Calculate F1 score from precision and recall
    private func calculateF1(precision: Double, recall: Double) -> Double {
        let denominator = precision + recall
        guard denominator > 0 else { return 0.0 }
        return 2.0 * (precision * recall) / denominator
    }
}
