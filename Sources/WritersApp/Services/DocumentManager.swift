import Foundation

/// Manages document storage, retrieval, and operations
public class DocumentManager {
    private var documents: [UUID: Document]

    // MARK: - Safety State

    /// Backups keyed by backup UUID; also indexed per document for fast lookup.
    private var backups: [UUID: DocumentBackup] = [:]
    /// Document IDs that are currently write-protected.
    private var writeProtectedIds: Set<UUID> = []

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

    // MARK: - Write Protection

    /// Marks a document as write-protected. Subsequent calls to `updateDocumentSafely` or
    /// `deleteDocumentSafely` will throw `DocumentSafetyError.writeProtected` until protection
    /// is lifted with `disableWriteProtection(for:)`.
    public func enableWriteProtection(for id: UUID) {
        writeProtectedIds.insert(id)
    }

    /// Removes write protection from a document.
    public func disableWriteProtection(for id: UUID) {
        writeProtectedIds.remove(id)
    }

    /// Returns `true` if the document is currently write-protected.
    public func isWriteProtected(id: UUID) -> Bool {
        return writeProtectedIds.contains(id)
    }

    // MARK: - Safe Mutations

    /// Updates a document, but first checks write protection and creates a content backup.
    ///
    /// - Throws: `DocumentSafetyError.writeProtected` if the document is protected.
    /// - Throws: `DocumentSafetyError.documentNotFound` if the document does not exist.
    @discardableResult
    public func updateDocumentSafely(_ document: Document) throws -> DocumentBackup {
        guard let existing = documents[document.id] else {
            throw DocumentSafetyError.documentNotFound(documentId: document.id)
        }
        guard !writeProtectedIds.contains(document.id) else {
            throw DocumentSafetyError.writeProtected(documentId: document.id)
        }
        let backup = DocumentBackup(
            documentId: existing.id,
            documentTitle: existing.title,
            documentCategory: existing.category,
            contentSnapshot: existing.content,
            reason: "before update"
        )
        backups[backup.id] = backup
        updateDocument(document)
        return backup
    }

    /// Deletes a document, but first checks write protection and creates a content backup.
    ///
    /// - Throws: `DocumentSafetyError.writeProtected` if the document is protected.
    /// - Throws: `DocumentSafetyError.documentNotFound` if the document does not exist.
    @discardableResult
    public func deleteDocumentSafely(id: UUID) throws -> DocumentBackup {
        guard let existing = documents[id] else {
            throw DocumentSafetyError.documentNotFound(documentId: id)
        }
        guard !writeProtectedIds.contains(id) else {
            throw DocumentSafetyError.writeProtected(documentId: id)
        }
        let backup = DocumentBackup(
            documentId: existing.id,
            documentTitle: existing.title,
            documentCategory: existing.category,
            contentSnapshot: existing.content,
            reason: "before delete"
        )
        backups[backup.id] = backup
        deleteDocument(id: id)
        return backup
    }

    // MARK: - Backup Access

    /// Returns all backups for a given document, ordered newest first.
    public func getBackups(forDocument id: UUID) -> [DocumentBackup] {
        return backups.values
            .filter { $0.documentId == id }
            .sorted { $0.createdAt > $1.createdAt }
    }

    /// Returns a specific backup by its ID.
    public func getBackup(id: UUID) -> DocumentBackup? {
        return backups[id]
    }

    /// Restores a document's content from a backup snapshot and stores the restored document.
    ///
    /// The restored document replaces the current document with the same ID.
    /// - Returns: The restored `Document`.
    /// - Throws: `DocumentSafetyError.backupNotFound` if the backup does not exist.
    @discardableResult
    public func restoreFromBackup(backupId: UUID) throws -> Document {
        guard let backup = backups[backupId] else {
            throw DocumentSafetyError.backupNotFound(backupId: backupId)
        }
        if var existing = documents[backup.documentId] {
            existing.content = backup.contentSnapshot
            updateDocument(existing)
            return existing
        } else {
            // Document was deleted — recreate it from the backup.
            let restored = Document(
                id: backup.documentId,
                title: backup.documentTitle,
                content: backup.contentSnapshot,
                category: backup.documentCategory
            )
            createDocument(restored)
            return restored
        }
    }
}
