import Foundation

/// Status of an issue
public enum IssueStatus: String, Codable, CaseIterable {
    case open = "open"
    case inProgress = "in_progress"
    case resolved = "resolved"
    case closed = "closed"
    
    public var displayName: String {
        switch self {
        case .open: return "Open"
        case .inProgress: return "In Progress"
        case .resolved: return "Resolved"
        case .closed: return "Closed"
        }
    }
}

/// Priority level of an issue
public enum IssuePriority: String, Codable, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    public var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }
}

/// Represents a writing issue, note, or task associated with a document
public struct Issue: Codable, Identifiable {
    public let id: UUID
    public let documentId: UUID
    public var title: String
    public var description: String
    public var status: IssueStatus
    public var priority: IssuePriority
    public var metadata: IssueMetadata
    
    public init(
        id: UUID = UUID(),
        documentId: UUID,
        title: String,
        description: String = "",
        status: IssueStatus = .open,
        priority: IssuePriority = .medium,
        metadata: IssueMetadata = IssueMetadata()
    ) {
        self.id = id
        self.documentId = documentId
        self.title = title
        self.description = description
        self.status = status
        self.priority = priority
        self.metadata = metadata
    }
}

/// Metadata for issues
public struct IssueMetadata: Codable {
    public var created: Date
    public var modified: Date
    public var resolvedAt: Date?
    public var tags: [String]
    public var notes: String
    
    public init(
        created: Date = Date(),
        modified: Date = Date(),
        resolvedAt: Date? = nil,
        tags: [String] = [],
        notes: String = ""
    ) {
        self.created = created
        self.modified = modified
        self.resolvedAt = resolvedAt
        self.tags = tags
        self.notes = notes
    }
}
