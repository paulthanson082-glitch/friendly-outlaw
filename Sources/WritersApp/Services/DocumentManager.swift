import Foundation

/// Manages document storage, retrieval, and operations
public class DocumentManager {
    private var documents: [UUID: Document]

    /// Trigram-based index for fast regex search over document content.
    private let searchIndex = RegexSearchIndex()

    public init() {
        self.documents = [:]
    }

    // MARK: - Document Management

    /// Creates a new document
    public func createDocument(_ document: Document) {
        documents[document.id] = document
        searchIndex.indexDocument(id: document.id, text: document.title + " " + document.content)
    }

    /// Retrieves a document by ID
    public func getDocument(id: UUID) -> Document? {
        return documents[id]
    }

    /// Retrieves all documents
    public func getAllDocuments() -> [Document] {
        return Array(documents.values)
            .sorted { $0.metadata.modified > $1.metadata.modified }
    }

    /// Retrieves documents by category
    public func getDocuments(for category: TemplateCategory) -> [Document] {
        return documents.values.filter { $0.category == category }
            .sorted { $0.metadata.modified > $1.metadata.modified }
    }

    /// Searches documents by title or content
    public func searchDocuments(query: String) -> [Document] {
        // Return all documents if query is empty
        if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return getAllDocuments()
        }
        
        // Use localizedCaseInsensitiveContains which handles case conversion internally
        return documents.values.filter { doc in
            doc.title.localizedCaseInsensitiveContains(query) ||
            doc.content.localizedCaseInsensitiveContains(query)
        }.sorted { $0.metadata.modified > $1.metadata.modified }
    }

    /// Updates an existing document
    public func updateDocument(_ document: Document) {
        var updatedDoc = document
        updatedDoc.metadata.modified = Date()
        documents[document.id] = updatedDoc
        searchIndex.indexDocument(id: updatedDoc.id, text: updatedDoc.title + " " + updatedDoc.content)
    }

    /// Deletes a document
    public func deleteDocument(id: UUID) {
        documents.removeValue(forKey: id)
        searchIndex.removeDocument(id: id)
    }

    /// Marks a document as opened
    public func markDocumentOpened(id: UUID) {
        guard var document = documents[id] else { return }
        document.metadata.lastOpened = Date()
        documents[id] = document
    }

    /// Searches documents using a regex pattern, accelerated by the trigram index.
    ///
    /// The index is used to prune candidate documents before running the full
    /// regular expression engine, so performance scales sub-linearly with corpus
    /// size for selective patterns.
    ///
    /// - Parameter pattern: An `NSRegularExpression`-compatible pattern.
    ///   Case-insensitive matching is applied automatically.
    /// - Returns: Documents whose title or content match the pattern, sorted
    ///   by most-recently modified.
    public func searchDocumentsWithRegex(pattern: String) -> [Document] {
        guard !pattern.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return getAllDocuments()
        }
        let matchingIds = searchIndex.search(pattern: pattern)
        return matchingIds.compactMap { documents[$0] }
            .sorted { $0.metadata.modified > $1.metadata.modified }
    }

    // MARK: - Statistics

    /// Gets total word count across all documents
    public func getTotalWordCount() -> Int {
        return documents.values.reduce(0) { $0 + $1.wordCount }
    }

    /// Gets documents by word count goal progress
    public func getDocumentsByProgress() -> [(document: Document, progress: Double)] {
        return documents.values.compactMap { doc in
            guard let goal = doc.metadata.wordCountGoal, goal > 0 else { return nil }
            let progress = Double(doc.wordCount) / Double(goal)
            return (document: doc, progress: progress)
        }.sorted { $0.progress > $1.progress }
    }

    /// Gets recently modified documents
    public func getRecentDocuments(limit: Int = 10) -> [Document] {
        // Optimize by using partial sort instead of full sort
        let sortedDocs = documents.values.sorted { $0.metadata.modified > $1.metadata.modified }
        return Array(sortedDocs.prefix(limit))
    }
}
