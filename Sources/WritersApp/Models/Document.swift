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

    /// Counts the words in `content` by splitting on whitespace and newlines and excluding empty tokens and tokens that contain no letters or digits.
    /// - Returns: The number of tokens considered words (excludes pure punctuation and empty tokens).
    public func enhancedWordCount() -> Int {
        let components = content.components(separatedBy: .whitespacesAndNewlines)
        return components.filter { word in
            // Filter out empty strings and pure punctuation
            !word.isEmpty && word.contains { $0.isLetter || $0.isNumber }
        }.count
    }

    /// Counts sentence-like segments in the document's content.
    /// Splits the content on `.`, `!`, and `?`, trims whitespace and newlines from each segment, and counts the non-empty segments.
    /// - Returns: The number of non-empty sentence segments.
    public func sentenceCount() -> Int {
        let sentences = content.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        return sentences.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }

    /// Counts the paragraphs in the document.
    /// 
    /// Splits `content` on the double-newline delimiter `"\n\n"`, trims whitespace and newlines from each segment, and counts segments that are not empty after trimming.
    /// - Returns: The number of paragraphs found in `content`.
    public func paragraphCount() -> Int {
        let paragraphs = content.components(separatedBy: "\n\n")
        return paragraphs.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }

    /// Computes progress toward the document's word count goal as a ratio.
    /// - Returns: `0.0` if no positive goal is set; otherwise a value between `0.0` and `1.0` equal to `wordCount / goal`, clamped to `1.0`.
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