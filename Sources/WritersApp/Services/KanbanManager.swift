import Foundation

/// Manages Kanban boards and tasks through their workflow lifecycle
public class KanbanManager {
    private var boards: [UUID: KanbanBoard]
    private var tasks: [UUID: KanbanTask]

    public init() {
        self.boards = [:]
        self.tasks = [:]
    }

    // MARK: - Board Management

    /// Creates a new Kanban board
    public func createBoard(_ board: KanbanBoard) {
        boards[board.id] = board
    }

    /// Retrieves a board by ID
    public func getBoard(id: UUID) -> KanbanBoard? {
        return boards[id]
    }

    /// Retrieves all boards sorted by creation date descending
    public func getAllBoards() -> [KanbanBoard] {
        return Array(boards.values)
            .sorted { $0.metadata.created > $1.metadata.created }
    }

    /// Updates an existing board
    public func updateBoard(_ board: KanbanBoard) {
        var updated = board
        updated.metadata.modified = Date()
        boards[board.id] = updated
    }

    /// Deletes a board and all its tasks
    public func deleteBoard(id: UUID) {
        let orphanedTaskIds = tasks.values
            .filter { $0.boardId == id }
            .map { $0.id }
        boards.removeValue(forKey: id)
        for taskId in orphanedTaskIds {
            tasks.removeValue(forKey: taskId)
        }
    }

    // MARK: - Task Management

    /// Creates a new Kanban task on the specified board
    public func createTask(_ task: KanbanTask) {
        tasks[task.id] = task
    }

    /// Retrieves a task by ID
    public func getTask(id: UUID) -> KanbanTask? {
        return tasks[id]
    }

    /// Retrieves all tasks for a given board sorted by creation date descending
    public func getTasks(forBoard boardId: UUID) -> [KanbanTask] {
        return tasks.values.filter { $0.boardId == boardId }
            .sorted { $0.metadata.created > $1.metadata.created }
    }

    /// Retrieves tasks in a specific column on a board sorted by creation date descending
    public func getTasks(forBoard boardId: UUID, inColumn column: KanbanColumn) -> [KanbanTask] {
        return tasks.values.filter { $0.boardId == boardId && $0.column == column }
            .sorted { $0.metadata.created > $1.metadata.created }
    }

    /// Retrieves all tasks in a specific column across all boards sorted by creation date descending
    public func getTasks(inColumn column: KanbanColumn) -> [KanbanTask] {
        return tasks.values.filter { $0.column == column }
            .sorted { $0.metadata.created > $1.metadata.created }
    }

    /// Searches tasks by title or description sorted by creation date descending
    public func searchTasks(query: String) -> [KanbanTask] {
        if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return Array(tasks.values).sorted { $0.metadata.created > $1.metadata.created }
        }
        return tasks.values.filter { task in
            task.title.localizedCaseInsensitiveContains(query) ||
            task.description.localizedCaseInsensitiveContains(query)
        }.sorted { $0.metadata.created > $1.metadata.created }
    }

    /// Updates an existing task, keeping completedAt consistent with column state
    public func updateTask(_ task: KanbanTask) {
        var updated = task
        updated.metadata.modified = Date()
        if updated.column == .done && updated.metadata.completedAt == nil {
            updated.metadata.completedAt = Date()
        } else if updated.column != .done {
            updated.metadata.completedAt = nil
        }
        tasks[task.id] = updated
    }

    /// Deletes a task by ID
    public func deleteTask(id: UUID) {
        tasks.removeValue(forKey: id)
    }

    // MARK: - Column Transitions

    /// Moves a task to a specific column
    public func moveTask(id: UUID, toColumn column: KanbanColumn) {
        guard var task = tasks[id] else { return }
        task.column = column
        task.metadata.modified = Date()
        if column == .done {
            task.metadata.completedAt = Date()
        } else {
            task.metadata.completedAt = nil
        }
        tasks[id] = task
    }

    /// Advances a task to the next column in the workflow
    /// - Returns: The new column, or nil if the task was already in Done
    @discardableResult
    public func advanceTask(id: UUID) -> KanbanColumn? {
        guard let task = tasks[id], let nextColumn = task.column.next else { return nil }
        moveTask(id: id, toColumn: nextColumn)
        return nextColumn
    }

    /// Moves a task back to the previous column in the workflow
    /// - Returns: The new column, or nil if the task was already in Backlog
    @discardableResult
    public func regressTask(id: UUID) -> KanbanColumn? {
        guard let task = tasks[id], let previousColumn = task.column.previous else { return nil }
        moveTask(id: id, toColumn: previousColumn)
        return previousColumn
    }

    // MARK: - Statistics

    /// Returns the count of tasks per column for a given board
    public func getTaskCountByColumn(forBoard boardId: UUID) -> [KanbanColumn: Int] {
        var counts: [KanbanColumn: Int] = [:]
        for column in KanbanColumn.allCases {
            counts[column] = tasks.values.filter { $0.boardId == boardId && $0.column == column }.count
        }
        return counts
    }

    /// Returns the total count of tasks per column across all boards
    public func getTaskCountByColumn() -> [KanbanColumn: Int] {
        var counts: [KanbanColumn: Int] = [:]
        for column in KanbanColumn.allCases {
            counts[column] = tasks.values.filter { $0.column == column }.count
        }
        return counts
    }
}
