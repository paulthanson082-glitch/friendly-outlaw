/// RAG Evaluation Example for friendly-outlaw
/// This example demonstrates how to use the Summary Indexing + Re-Ranking RAG system
/// and evaluate its performance using precision, recall, MRR, and end-to-end accuracy metrics.

import Foundation

// Example usage of RAG system with evaluation
func demonstrateRAGEvaluation() async {
    // Initialize the app with optional AI configuration
    let app = WritersApp()

    // Create sample documents for RAG testing
    let documents = createSampleDocuments()

    // Index all documents
    for doc in documents {
        app.documentManager.createDocument(doc)
        do {
            try await app.indexDocumentForRAG(documentId: doc.id)
            print("✓ Indexed document: \(doc.title)")
        } catch {
            print("✗ Failed to index document: \(error)")
        }
    }

    // Create test cases based on expected retrieval patterns
    let testCases = createTestCases(documents: documents)

    print("\n=== RAG Evaluation Results ===\n")

    // Run evaluation
    for testCase in testCases {
        do {
            // Retrieve chunks for this query
            var results = try await app.retrieveDocumentChunks(
                query: testCase.query,
                topK: 5
            )

            // Extract retrieved chunk IDs
            var retrievedIds = results.map { $0.chunk.id }

            // Update test case with retrieved IDs
            var updatedCase = testCase
            updatedCase.retrievedChunkIds = retrievedIds

            // Calculate metrics
            let correct = Set(testCase.correctChunkIds)
            let retrieved = Set(retrievedIds)

            let precision = retrieved.isEmpty
                ? 0.0
                : Double(retrieved.intersection(correct).count) / Double(retrievedIds.count)

            let recall = correct.isEmpty
                ? 0.0
                : Double(retrieved.intersection(correct).count) / Double(correct.count)

            var mrr = 0.0
            for (index, chunkId) in retrievedIds.enumerated() {
                if correct.contains(chunkId) {
                    mrr = 1.0 / Double(index + 1)
                    break
                }
            }

            updatedCase.retrievalPrecision = precision
            updatedCase.retrievalRecall = recall
            updatedCase.retrievalMRR = mrr

            print("Query: \(testCase.query)")
            print("  Precision: \(String(format: "%.2f", precision))")
            print("  Recall: \(String(format: "%.2f", recall))")
            print("  MRR: \(String(format: "%.2f", mrr))")
            print()
        } catch {
            print("Error evaluating query '\(testCase.query)': \(error)\n")
        }
    }

    // Calculate overall metrics
    let metrics = app.evaluateRAGPerformance(testCases: testCases)

    print("=== Overall Metrics ===\n")
    print("Average Precision: \(String(format: "%.4f", metrics.precision))")
    print("Average Recall: \(String(format: "%.4f", metrics.recall))")
    print("F1 Score: \(String(format: "%.4f", metrics.f1Score))")
    print("Mean Reciprocal Rank (MRR): \(String(format: "%.4f", metrics.meanReciprocalRank))")
    print("End-to-End Accuracy: \(String(format: "%.4f", metrics.endToEndAccuracy))")
    print("Total Queries: \(metrics.totalQueries)")
    print("Correct Answers: \(metrics.correctAnswers)")
}

// Helper: Create sample documents
func createSampleDocuments() -> [Document] {
    return [
        Document(
            title: "Claude API Basics",
            content: """
            Claude is an AI assistant created by Anthropic. The Claude API provides access to Claude models
            for building AI applications. You can use the Messages API to interact with Claude. The API
            supports multiple models including Claude 3 Opus, Claude 3 Sonnet, and Claude 3 Haiku.
            """,
            category: .article
        ),
        Document(
            title: "RAG Implementation Guide",
            content: """
            Retrieval-Augmented Generation (RAG) improves AI responses by retrieving relevant context
            before generation. Summary Indexing + Re-Ranking is a powerful RAG approach. First, you
            create document summaries and chunk your documents. Then you retrieve relevant chunks
            based on query similarity. Finally, you re-rank results using Claude for better relevance.
            """,
            category: .article
        ),
        Document(
            title: "Prompt Engineering Best Practices",
            content: """
            Prompt engineering helps you get better results from Claude. Use clear instructions and
            provide examples when helpful. System prompts set the context for Claude's behavior.
            Temperature controls randomness in responses. Breaking complex tasks into subtasks
            (chain-of-thought) often improves accuracy. Always test your prompts before deployment.
            """,
            category: .article
        ),
        Document(
            title: "Evaluation Metrics for AI Systems",
            content: """
            When evaluating RAG systems, consider multiple metrics. Precision measures accuracy of
            retrieved results. Recall measures coverage of relevant documents. F1 score combines both.
            Mean Reciprocal Rank (MRR) measures how highly ranked the first correct result is.
            End-to-end accuracy evaluates whether the final answer is correct. Build comprehensive
            test cases with correct answers for reliable evaluation.
            """,
            category: .article
        )
    ]
}

// Helper: Create test cases
func createTestCases(documents: [Document]) -> [RAGQueryEvaluation] {
    // For this example, we'll create synthetic test cases
    // In a real scenario, these would come from your evaluation dataset
    return [
        RAGQueryEvaluation(
            query: "How do I use the Claude API?",
            correctChunkIds: [] // Would be set to actual chunk IDs from the Basics document
        ),
        RAGQueryEvaluation(
            query: "What is RAG and how does it work?",
            correctChunkIds: [] // Would be set to chunk IDs from the RAG Guide document
        ),
        RAGQueryEvaluation(
            query: "How do I improve Claude's responses with prompts?",
            correctChunkIds: [] // Would be set to chunk IDs from the Prompt Engineering document
        ),
        RAGQueryEvaluation(
            query: "How do I measure RAG system performance?",
            correctChunkIds: [] // Would be set to chunk IDs from the Evaluation Metrics document
        )
    ]
}

// Note: This example demonstrates the structure. In production:
// 1. Load your actual documents from files or a database
// 2. Create test cases with known correct chunk IDs from your evaluation dataset
// 3. Run the RAG system and collect metrics
// 4. Compare against target metrics (e.g., 0.81 end-to-end accuracy for Summary Indexing + Re-Ranking)
// 5. Iterate on indexing/re-ranking strategies to improve performance
