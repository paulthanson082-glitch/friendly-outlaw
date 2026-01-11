import Foundation

/// Manages document storage, retrieval, and operations
public class DocumentManager {
    private var documents: [UUID: Document]

    public init() {
        self.documents = [:]
    }

    // MARK: - Document Management

    /// Creates a new document
    public func createDocument(_ document: Document) {
        documents[document.id] = document
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
        let lowercaseQuery = query.lowercased()
        return documents.values.filter {
            $0.title.lowercased().contains(lowercaseQuery) ||
            $0.content.lowercased().contains(lowercaseQuery)
        }.sorted { $0.metadata.modified > $1.metadata.modified }
    }

    /// Updates an existing document
    public func updateDocument(_ document: Document) {
        var updatedDoc = document
        updatedDoc.metadata.modified = Date()
        documents[document.id] = updatedDoc
    }

    /// Deletes a document
    public func deleteDocument(id: UUID) {
        documents.removeValue(forKey: id)
    }

    /// Marks a document as opened
    public func markDocumentOpened(id: UUID) {
        guard var document = documents[id] else { return }
        document.metadata.lastOpened = Date()
        documents[id] = document
    }

    // MARK: - Statistics

    /// Gets total word count across all documents
    public func getTotalWordCount() -> Int {
        return documents.values.reduce(0) { $0 + $1.wordCount }
    }

    /// Gets documents by word count goal progress
    public func getDocumentsByProgress() -> [(Document, Double)] {
        return documents.values.compactMap { doc in
            guard let goal = doc.metadata.wordCountGoal, goal > 0 else { return nil }
            let progress = Double(doc.wordCount) / Double(goal)
            return (doc, progress)
        }.sorted { $0.1 > $1.1 }
    }

    /// Gets recently modified documents
    public func getRecentDocuments(limit: Int = 10) -> [Document] {
        return getAllDocuments().prefix(limit).map { $0 }
    }
}
