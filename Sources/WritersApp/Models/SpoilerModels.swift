import Foundation

/// Severity level of a spoiler
public enum SpoilerSeverity: String, Codable, CaseIterable {
    case minor = "minor"
    case moderate = "moderate"
    case major = "major"

    public var displayName: String {
        switch self {
        case .minor: return "Minor"
        case .moderate: return "Moderate"
        case .major: return "Major"
        }
    }
}

/// Represents a spoiler-protected region within a document
public struct SpoilerTag: Codable, Identifiable {
    public let id: UUID
    public let documentId: UUID
    /// Character offset of the first spoiler character (inclusive)
    public var startOffset: Int
    /// Character offset one past the last spoiler character (exclusive)
    public var endOffset: Int
    public var description: String
    public var severity: SpoilerSeverity
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        documentId: UUID,
        startOffset: Int,
        endOffset: Int,
        description: String = "",
        severity: SpoilerSeverity = .moderate,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.documentId = documentId
        self.startOffset = startOffset
        self.endOffset = endOffset
        self.description = description
        self.severity = severity
        self.createdAt = createdAt
    }
}
