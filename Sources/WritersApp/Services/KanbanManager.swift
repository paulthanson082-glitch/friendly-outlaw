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

    /// Adds a Kanban board to the manager's in-memory store.
    /// - Parameters:
    ///   - board: The `KanbanBoard` to store; it will be keyed by `board.id`.
    public func createBoard(_ board: KanbanBoard) {
        boards[board.id] = board
    }

    /// Retrieve the Kanban board with the specified identifier.
    /// - Returns: The board with the specified `id`, or `nil` if none exists.
    public func getBoard(id: UUID) -> KanbanBoard? {
        return boards[id]
    }

    /// All boards sorted by creation date in descending order.
    /// - Returns: An array of `KanbanBoard` values ordered from newest to oldest by `metadata.created`.
    public func getAllBoards() -> [KanbanBoard] {
        return Array(boards.values)
            .sorted { $0.metadata.created > $1.metadata.created }
    }

    /// Updates the stored board by setting its `metadata.modified` to the current date and saving it under the board's `id`.
    /// - Parameters:
    ///   - board: The board to update; its `metadata.modified` will be set to now and the board will replace any existing entry with the same `id`.
    public func updateBoard(_ board: KanbanBoard) {
        var updated = board
        updated.metadata.modified = Date()
        boards[board.id] = updated
    }

    /// Deletes the board with the given id and removes any tasks that belonged to it.
    /// - Parameter id: The UUID of the board to delete. If no board exists with this id, the call is a no-op.
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

    /// Stores the provided task in the manager's in-memory storage.
    /// - Parameter task: The task to store; if a task with the same `id` already exists it will be replaced.
    public func createTask(_ task: KanbanTask) {
        tasks[task.id] = task
    }

    /// Fetches the task with the specified identifier.
    /// - Parameters:
    ///   - id: The UUID of the task to retrieve.
    /// - Returns: The `KanbanTask` with the given id if it exists, `nil` otherwise.
    public func getTask(id: UUID) -> KanbanTask? {
        return tasks[id]
    }

    /// Retrieve all tasks belonging to a board, sorted by creation date descending.
    /// - Parameter boardId: The UUID of the board whose tasks to retrieve.
    /// - Returns: An array of `KanbanTask` that belong to the specified board, ordered newest first.
    public func getTasks(forBoard boardId: UUID) -> [KanbanTask] {
        return tasks.values.filter { $0.boardId == boardId }
            .sorted { $0.metadata.created > $1.metadata.created }
    }

    /// Retrieves tasks belonging to a specific board that are currently in the given column.
    /// - Parameters:
    ///   - boardId: The identifier of the board whose tasks should be returned.
    ///   - column: The column to filter tasks by.
    /// - Returns: An array of `KanbanTask` for the specified board and column, sorted by `metadata.created` in descending order.
    public func getTasks(forBoard boardId: UUID, inColumn column: KanbanColumn) -> [KanbanTask] {
        return tasks.values.filter { $0.boardId == boardId && $0.column == column }
            .sorted { $0.metadata.created > $1.metadata.created }
    }

    /// Retrieve all tasks in the specified column across all boards.
    /// - Parameters:
    ///   - column: The column to filter tasks by.
    /// - Returns: An array of `KanbanTask` objects in the given column, sorted by `metadata.created` in descending order (most recent first).
    public func getTasks(inColumn column: KanbanColumn) -> [KanbanTask] {
        return tasks.values.filter { $0.column == column }
            .sorted { $0.metadata.created > $1.metadata.created }
    }

    /// Searches tasks by title or description using a case-insensitive match.
    /// - Parameters:
    ///   - query: The search string; leading/trailing whitespace is ignored. Returns empty array if query is empty.
    /// - Returns: An array of matching `KanbanTask` objects sorted by `metadata.created` in descending order.
    public func searchTasks(query: String) -> [KanbanTask] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return [] }

        return tasks.values.filter { task in
            task.title.localizedCaseInsensitiveContains(trimmedQuery) ||
            task.description.localizedCaseInsensitiveContains(trimmedQuery)
        }.sorted { $0.metadata.created > $1.metadata.created }
    }

    /// Updates a task in the manager, refreshes its modified timestamp, and adjusts its completion time based on column status.
    /// - Parameters:
    ///   - task: The task to save. This sets `metadata.modified` to the current date; if `task.column == .done` and `metadata.completedAt` is nil, `metadata.completedAt` is set to the current date, otherwise `metadata.completedAt` is cleared. The updated task replaces the stored entry for its `id`.
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

    /// Removes the task with the specified identifier from the manager.
    /// - Parameter id: The UUID of the task to remove. If no task exists with this identifier, the call has no effect.
    public func deleteTask(id: UUID) {
        tasks.removeValue(forKey: id)
    }

    // MARK: - Column Transitions

    /// Moves the task with the given identifier to the specified column and updates its metadata.
    /// The task's modified timestamp is set to the current date; the `completedAt` timestamp is set when moving into `.done` and cleared when moving out of `.done`.
    /// - Parameters:
    ///   - id: The UUID of the task to move.
    ///   - column: The destination `KanbanColumn`.
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
    /// Moves the task with the given ID to its next workflow column.
    /// - Returns: The next `KanbanColumn` the task moved into, or `nil` if the task was not found or has no next column.
    @discardableResult
    public func advanceTask(id: UUID) -> KanbanColumn? {
        guard let task = tasks[id], let nextColumn = task.column.next else { return nil }
        moveTask(id: id, toColumn: nextColumn)
        return nextColumn
    }

    /// Moves a task back to the previous column in the workflow
    /// Moves the specified task one column backward in the workflow if possible.
    /// - Returns: The previous column the task was moved into, or `nil` if the task does not exist or has no previous column.
    @discardableResult
    public func regressTask(id: UUID) -> KanbanColumn? {
        guard let task = tasks[id], let previousColumn = task.column.previous else { return nil }
        moveTask(id: id, toColumn: previousColumn)
        return previousColumn
    }

    // MARK: - Statistics

    /// Counts tasks in each column for the specified board.
    /// - Parameter boardId: The UUID of the board whose tasks will be counted.
    /// - Returns: A dictionary mapping each `KanbanColumn` to the number of tasks on the given board in that column.
    public func getTaskCountByColumn(forBoard boardId: UUID) -> [KanbanColumn: Int] {
        var counts: [KanbanColumn: Int] = [:]
        for column in KanbanColumn.allCases {
            counts[column] = tasks.values.filter { $0.boardId == boardId && $0.column == column }.count
        }
        return counts
    }

    /// Counts tasks in each Kanban column across all boards.
    /// - Returns: A dictionary mapping each `KanbanColumn` to the number of tasks currently in that column.
    public func getTaskCountByColumn() -> [KanbanColumn: Int] {
        var counts: [KanbanColumn: Int] = [:]
        for column in KanbanColumn.allCases {
            counts[column] = tasks.values.filter { $0.column == column }.count
        }
        return counts
    }
}