import Foundation

// MARK: - Document Safety

/// A snapshot of a document's content taken before a destructive operation.
public struct DocumentBackup: Codable, Identifiable {
    public let id: UUID
    public let documentId: UUID
    public let documentTitle: String
    public let documentCategory: TemplateCategory
    public let contentSnapshot: String
    public let createdAt: Date
    /// Human-readable reason the backup was created (e.g. "before update", "before delete").
    public let reason: String

    public init(
        id: UUID = UUID(),
        documentId: UUID,
        documentTitle: String,
        documentCategory: TemplateCategory,
        contentSnapshot: String,
        createdAt: Date = Date(),
        reason: String
    ) {
        self.id = id
        self.documentId = documentId
        self.documentTitle = documentTitle
        self.documentCategory = documentCategory
        self.contentSnapshot = contentSnapshot
        self.createdAt = createdAt
        self.reason = reason
    }
}

/// Errors thrown by the document safety layer.
public enum DocumentSafetyError: LocalizedError {
    case writeProtected(documentId: UUID)
    case backupNotFound(backupId: UUID)
    case documentNotFound(documentId: UUID)

    public var errorDescription: String? {
        switch self {
        case .writeProtected(let id):
            return "Document \(id) is write-protected. Disable write protection before modifying or deleting it."
        case .backupNotFound(let id):
            return "No backup found with id \(id)."
        case .documentNotFound(let id):
            return "No document found with id \(id)."
        }
    }
}

/// Represents a writing document created from a template or from scratch
public struct Document: Codable, Identifiable {
    public let id: UUID
    public var title: String
    public var content: String
    public let templateId: UUID?
    public let category: TemplateCategory
    public var metadata: DocumentMetadata

    public init(
        id: UUID = UUID(),
        title: String,
        content: String,
        templateId: UUID? = nil,
        category: TemplateCategory,
        metadata: DocumentMetadata = DocumentMetadata()
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.templateId = templateId
        self.category = category
        self.metadata = metadata
    }

    /// Word count of the document
    public var wordCount: Int {
        let words = content.components(separatedBy: .whitespacesAndNewlines)
        return words.filter { !$0.isEmpty }.count
    }

    /// Character count including spaces
    public var characterCount: Int {
        return content.count
    }

    /// Estimated reading time in minutes
    public var readingTime: Int {
        let wordsPerMinute = 200
        return max(1, wordCount / wordsPerMinute)
    }
}

/// Metadata for documents
public struct DocumentMetadata: Codable {
    public var created: Date
    public var modified: Date
    public var lastOpened: Date?
    public var wordCountGoal: Int?
    public var tags: [String]
    public var notes: String

    public init(
        created: Date = Date(),
        modified: Date = Date(),
        lastOpened: Date? = nil,
        wordCountGoal: Int? = nil,
        tags: [String] = [],
        notes: String = ""
    ) {
        self.created = created
        self.modified = modified
        self.lastOpened = lastOpened
        self.wordCountGoal = wordCountGoal
        self.tags = tags
        self.notes = notes
    }
}
