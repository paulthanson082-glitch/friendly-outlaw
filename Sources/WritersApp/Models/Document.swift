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

    /// Counts word-like tokens in the document content, excluding empty tokens and tokens that contain no letter or digit.
    /// 
    /// The content is split on whitespace and newlines; only components that are non-empty and contain at least one letter or digit are counted.
    /// - Returns: The number of tokens in `content` that contain at least one letter or digit.
    public func enhancedWordCount() -> Int {
        let components = content.components(separatedBy: .whitespacesAndNewlines)
        return components.filter { word in
            // Filter out empty strings and pure punctuation
            !word.isEmpty && word.contains { $0.isLetter || $0.isNumber }
        }.count
    }

    /// Counts sentence-like segments in the document content separated by the characters `.`, `!`, or `?`, ignoring segments that are empty or contain only whitespace.
    /// - Returns: The number of detected sentences.
    public func sentenceCount() -> Int {
        let sentences = content.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        return sentences.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }

    /// Counts non-empty paragraphs in the document.
    /// 
    /// Paragraphs are defined as segments separated by two consecutive newline characters ("\n\n"); segments that are empty or contain only whitespace/newlines are ignored.
    /// - Returns: The number of non-empty paragraph segments.
    public func paragraphCount() -> Int {
        let paragraphs = content.components(separatedBy: "\n\n")
        return paragraphs.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }

    /// Calculates progress toward the document's word count goal.
    /// If `metadata.wordCountGoal` is missing or not greater than zero, returns `0.0`.
    /// - Returns: A value between `0.0` and `1.0` representing the fraction of the goal completed; `1.0` when the word count meets or exceeds the goal.
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
