import XCTest
@testable import WritersApp

/// Tests for KanbanManager, focused on the searchTasks behaviour changed in this PR:
/// an empty or whitespace-only query now returns all tasks instead of an empty array.
final class KanbanManagerTests: XCTestCase {
    var kanbanManager: KanbanManager!
    var boardId: UUID!

    override func setUp() {
        super.setUp()
        kanbanManager = KanbanManager()
        let board = KanbanBoard(name: "Test Board")
        boardId = board.id
        kanbanManager.createBoard(board)
    }

    override func tearDown() {
        kanbanManager = nil
        boardId = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func makeTask(title: String, description: String = "", column: KanbanColumn = .backlog) -> KanbanTask {
        KanbanTask(title: title, description: description, column: column, boardId: boardId)
    }

    // MARK: - searchTasks: empty / whitespace queries return all tasks

    func testSearchTasksEmptyQueryReturnsAllTasks() {
        let task1 = makeTask(title: "Write chapter one")
        let task2 = makeTask(title: "Revise outline")
        let task3 = makeTask(title: "Research setting")

        kanbanManager.createTask(task1)
        kanbanManager.createTask(task2)
        kanbanManager.createTask(task3)

        let results = kanbanManager.searchTasks(query: "")
        XCTAssertEqual(results.count, 3)
    }

    func testSearchTasksWhitespaceOnlyQueryReturnsAllTasks() {
        let task1 = makeTask(title: "Draft synopsis")
        let task2 = makeTask(title: "Edit dialogue")

        kanbanManager.createTask(task1)
        kanbanManager.createTask(task2)

        let results = kanbanManager.searchTasks(query: "   ")
        XCTAssertEqual(results.count, 2)
    }

    func testSearchTasksTabAndNewlineOnlyQueryReturnsAllTasks() {
        let task = makeTask(title: "Proofread final draft")
        kanbanManager.createTask(task)

        let results = kanbanManager.searchTasks(query: "\t\n")
        XCTAssertEqual(results.count, 1)
    }

    func testSearchTasksEmptyQueryOnEmptyManagerReturnsEmpty() {
        let results = kanbanManager.searchTasks(query: "")
        XCTAssertEqual(results.count, 0)
    }

    // MARK: - searchTasks: non-empty queries filter by title

    func testSearchTasksByTitle() {
        let task1 = makeTask(title: "Write chapter one")
        let task2 = makeTask(title: "Revise outline")
        let task3 = makeTask(title: "Write chapter two")

        kanbanManager.createTask(task1)
        kanbanManager.createTask(task2)
        kanbanManager.createTask(task3)

        let results = kanbanManager.searchTasks(query: "Write")
        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.contains { $0.id == task1.id })
        XCTAssertTrue(results.contains { $0.id == task3.id })
    }

    func testSearchTasksByTitleNoMatch() {
        let task = makeTask(title: "Brainstorm themes")
        kanbanManager.createTask(task)

        let results = kanbanManager.searchTasks(query: "nonexistent")
        XCTAssertEqual(results.count, 0)
    }

    // MARK: - searchTasks: non-empty queries filter by description

    func testSearchTasksByDescription() {
        let task1 = makeTask(title: "Task A", description: "Focus on the antagonist's motivation")
        let task2 = makeTask(title: "Task B", description: "Adjust pacing in act two")

        kanbanManager.createTask(task1)
        kanbanManager.createTask(task2)

        let results = kanbanManager.searchTasks(query: "antagonist")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.id, task1.id)
    }

    func testSearchTasksMatchesTitleOrDescription() {
        let task1 = makeTask(title: "Character arc", description: "Develop the hero")
        let task2 = makeTask(title: "Setting notes", description: "Character sketches for side cast")
        let task3 = makeTask(title: "Unrelated task", description: "Nothing relevant here")

        kanbanManager.createTask(task1)
        kanbanManager.createTask(task2)
        kanbanManager.createTask(task3)

        let results = kanbanManager.searchTasks(query: "character")
        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.contains { $0.id == task1.id })
        XCTAssertTrue(results.contains { $0.id == task2.id })
    }

    // MARK: - searchTasks: case-insensitive matching

    func testSearchTasksCaseInsensitiveUppercase() {
        let task = makeTask(title: "Plot Summary", description: "A brief overview")
        kanbanManager.createTask(task)

        let results = kanbanManager.searchTasks(query: "PLOT")
        XCTAssertEqual(results.count, 1)
    }

    func testSearchTasksCaseInsensitiveLowercase() {
        let task = makeTask(title: "UPPERCASE TITLE", description: "")
        kanbanManager.createTask(task)

        let results = kanbanManager.searchTasks(query: "uppercase")
        XCTAssertEqual(results.count, 1)
    }

    func testSearchTasksCaseInsensitiveMixedCase() {
        let task = makeTask(title: "Mixed Case Task")
        kanbanManager.createTask(task)

        let upper = kanbanManager.searchTasks(query: "MIXED CASE TASK")
        let lower = kanbanManager.searchTasks(query: "mixed case task")
        let mixed = kanbanManager.searchTasks(query: "Mixed Case Task")

        XCTAssertEqual(upper.count, 1)
        XCTAssertEqual(lower.count, 1)
        XCTAssertEqual(mixed.count, 1)
    }

    // MARK: - searchTasks: result ordering

    func testSearchTasksEmptyQueryResultsSortedByCreatedDateDescending() {
        // Create tasks with distinct timestamps to verify ordering.
        var metadata1 = KanbanTaskMetadata()
        metadata1.created = Date(timeIntervalSinceNow: -200)
        let task1 = KanbanTask(title: "Oldest task", boardId: boardId, metadata: metadata1)

        var metadata2 = KanbanTaskMetadata()
        metadata2.created = Date(timeIntervalSinceNow: -100)
        let task2 = KanbanTask(title: "Middle task", boardId: boardId, metadata: metadata2)

        var metadata3 = KanbanTaskMetadata()
        metadata3.created = Date(timeIntervalSinceNow: -10)
        let task3 = KanbanTask(title: "Newest task", boardId: boardId, metadata: metadata3)

        kanbanManager.createTask(task1)
        kanbanManager.createTask(task2)
        kanbanManager.createTask(task3)

        let results = kanbanManager.searchTasks(query: "")

        XCTAssertEqual(results.count, 3)
        XCTAssertEqual(results[0].id, task3.id, "Newest task should be first")
        XCTAssertEqual(results[1].id, task2.id)
        XCTAssertEqual(results[2].id, task1.id, "Oldest task should be last")
    }

    func testSearchTasksNonEmptyQueryResultsSortedByCreatedDateDescending() {
        var metadata1 = KanbanTaskMetadata()
        metadata1.created = Date(timeIntervalSinceNow: -200)
        let task1 = KanbanTask(title: "Write scene A", boardId: boardId, metadata: metadata1)

        var metadata2 = KanbanTaskMetadata()
        metadata2.created = Date(timeIntervalSinceNow: -10)
        let task2 = KanbanTask(title: "Write scene B", boardId: boardId, metadata: metadata2)

        kanbanManager.createTask(task1)
        kanbanManager.createTask(task2)

        let results = kanbanManager.searchTasks(query: "write")
        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[0].id, task2.id, "More recently created task should appear first")
        XCTAssertEqual(results[1].id, task1.id)
    }

    // MARK: - searchTasks: single task edge cases

    func testSearchTasksSingleTaskMatchReturnsIt() {
        let task = makeTask(title: "Unique title for chapter")
        kanbanManager.createTask(task)

        let results = kanbanManager.searchTasks(query: "Unique")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.id, task.id)
    }

    func testSearchTasksSingleTaskNoMatchReturnsEmpty() {
        let task = makeTask(title: "Unique title for chapter")
        kanbanManager.createTask(task)

        let results = kanbanManager.searchTasks(query: "protagonist")
        XCTAssertTrue(results.isEmpty)
    }
}
