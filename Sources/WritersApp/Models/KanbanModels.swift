import Foundation

// MARK: - KanbanColumn

/// The column (stage) a Kanban task occupies in the workflow
public enum KanbanColumn: String, Codable, CaseIterable {
    case backlog = "backlog"
    case planning = "planning"
    case running = "running"
    case review = "review"
    case done = "done"

    public var displayName: String {
        switch self {
        case .backlog: return "Backlog"
        case .planning: return "Planning"
        case .running: return "Running"
        case .review: return "Review"
        case .done: return "Done"
        }
    }

    /// Returns the next column in the workflow, or nil if already at done
    public var next: KanbanColumn? {
        switch self {
        case .backlog: return .planning
        case .planning: return .running
        case .running: return .review
        case .review: return .done
        case .done: return nil
        }
    }

    /// Returns the previous column in the workflow, or nil if already at backlog
    public var previous: KanbanColumn? {
        switch self {
        case .backlog: return nil
        case .planning: return .backlog
        case .running: return .planning
        case .review: return .running
        case .done: return .review
        }
    }
}

// MARK: - KanbanTask

/// A task managed on the Kanban board
public struct KanbanTask: Codable, Identifiable {
    public let id: UUID
    public var title: String
    public var description: String
    public var column: KanbanColumn
    public let boardId: UUID
    public var metadata: KanbanTaskMetadata

    public init(
        id: UUID = UUID(),
        title: String,
        description: String = "",
        column: KanbanColumn = .backlog,
        boardId: UUID,
        metadata: KanbanTaskMetadata = KanbanTaskMetadata()
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.column = column
        self.boardId = boardId
        self.metadata = metadata
    }
}

// MARK: - KanbanTaskMetadata

/// Metadata associated with a Kanban task
public struct KanbanTaskMetadata: Codable {
    public var created: Date
    public var modified: Date
    public var completedAt: Date?
    public var tags: [String]
    public var notes: String

    public init(
        created: Date = Date(),
        modified: Date = Date(),
        completedAt: Date? = nil,
        tags: [String] = [],
        notes: String = ""
    ) {
        self.created = created
        self.modified = modified
        self.completedAt = completedAt
        self.tags = tags
        self.notes = notes
    }
}

// MARK: - KanbanBoard

/// A Kanban board grouping tasks into columns
public struct KanbanBoard: Codable, Identifiable {
    public let id: UUID
    public var name: String
    public var description: String
    public var metadata: KanbanBoardMetadata

    public init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        metadata: KanbanBoardMetadata = KanbanBoardMetadata()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.metadata = metadata
    }
}

// MARK: - KanbanBoardMetadata

/// Metadata associated with a Kanban board
public struct KanbanBoardMetadata: Codable {
    public var created: Date
    public var modified: Date

    public init(
        created: Date = Date(),
        modified: Date = Date()
    ) {
        self.created = created
        self.modified = modified
    }
}
