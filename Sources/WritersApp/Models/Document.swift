import Foundation

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

    /// Word count of the document (basic counting)
    public var wordCount: Int {
        let words = content.components(separatedBy: .whitespacesAndNewlines)
        return words.filter { !$0.isEmpty }.count
    }

    /// Character count including spaces
    public var characterCount: Int {
        return content.count
    }

    /// Character count excluding spaces
    public var characterCountWithoutSpaces: Int {
        return content.replacingOccurrences(of: " ", with: "").count
    }

    /// Estimated reading time in minutes
    public var readingTime: Int {
        let wordsPerMinute = 200
        return max(1, wordCount / wordsPerMinute)
    }

    /// Counts whitespace- and newline-separated tokens that contain at least one letter or digit.
    /// - Returns: The number of tokens (excluding empty tokens and tokens made only of punctuation).
    public func enhancedWordCount() -> Int {
        let components = content.components(separatedBy: .whitespacesAndNewlines)
        return components.filter { word in
            // Filter out empty strings and pure punctuation
            !word.isEmpty && word.contains { $0.isLetter || $0.isNumber }
        }.count
    }

    /// Counts sentences by splitting on `.`, `!`, and `?` and counting non-empty segments after trimming whitespace.
    /// - Returns: The number of sentences found in `content`.
    public func sentenceCount() -> Int {
        let sentences = content.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        return sentences.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }

    /// Counts non-empty paragraphs separated by `"\n\n"` after trimming whitespace.
    /// - Returns: The number of non-empty paragraphs.
    public func paragraphCount() -> Int {
        let paragraphs = content.components(separatedBy: "\n\n")
        return paragraphs.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }

    /// Progress toward the word count goal as a ratio between 0.0 and 1.0.
    /// - Returns: 0.0 if no positive goal is set; otherwise `wordCount / goal`, clamped to 1.0.
    public func wordCountProgress() -> Double {
        guard let goal = metadata.wordCountGoal, goal > 0 else { return 0.0 }
        return min(1.0, Double(wordCount) / Double(goal))
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

// MARK: - Document Safety

/// A snapshot of a document's content taken before a destructive operation.
public struct DocumentBackup: Codable, Identifiable {
    public let id: UUID
    public let documentId: UUID
    public let documentTitle: String
    public let documentCategory: TemplateCategory
    public let contentSnapshot: String
    public let createdAt: Date
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
