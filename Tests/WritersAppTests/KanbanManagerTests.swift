import XCTest
@testable import WritersApp

/// Tests for KanbanManager, focusing on the searchTasks behavior changed in this PR.
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

    // MARK: - searchTasks – empty / whitespace query returns all tasks

    func testSearchTasksEmptyQueryReturnsAllTasks() {
        let task1 = KanbanTask(title: "Design UI", boardId: boardId)
        let task2 = KanbanTask(title: "Write tests", boardId: boardId)
        let task3 = KanbanTask(title: "Deploy service", boardId: boardId)

        kanbanManager.createTask(task1)
        kanbanManager.createTask(task2)
        kanbanManager.createTask(task3)

        let results = kanbanManager.searchTasks(query: "")
        XCTAssertEqual(results.count, 3)
    }

    func testSearchTasksWhitespaceOnlyQueryReturnsAllTasks() {
        let task1 = KanbanTask(title: "Alpha task", boardId: boardId)
        let task2 = KanbanTask(title: "Beta task", boardId: boardId)

        kanbanManager.createTask(task1)
        kanbanManager.createTask(task2)

        let results = kanbanManager.searchTasks(query: "   ")
        XCTAssertEqual(results.count, 2)
    }

    func testSearchTasksTabAndNewlineQueryReturnsAllTasks() {
        let task1 = KanbanTask(title: "Task One", boardId: boardId)
        let task2 = KanbanTask(title: "Task Two", boardId: boardId)

        kanbanManager.createTask(task1)
        kanbanManager.createTask(task2)

        let results = kanbanManager.searchTasks(query: "\t\n")
        XCTAssertEqual(results.count, 2)
    }

    func testSearchTasksEmptyQueryOnEmptyStoreReturnsEmpty() {
        let results = kanbanManager.searchTasks(query: "")
        XCTAssertEqual(results.count, 0)
    }

    func testSearchTasksWhitespaceQueryOnEmptyStoreReturnsEmpty() {
        let results = kanbanManager.searchTasks(query: "   ")
        XCTAssertEqual(results.count, 0)
    }

    // MARK: - searchTasks – filtering by title and description

    func testSearchTasksByTitle() {
        let task1 = KanbanTask(title: "Implement login screen", boardId: boardId)
        let task2 = KanbanTask(title: "Write unit tests", boardId: boardId)
        let task3 = KanbanTask(title: "Implement logout", boardId: boardId)

        kanbanManager.createTask(task1)
        kanbanManager.createTask(task2)
        kanbanManager.createTask(task3)

        let results = kanbanManager.searchTasks(query: "Implement")
        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.contains { $0.id == task1.id })
        XCTAssertTrue(results.contains { $0.id == task3.id })
    }

    func testSearchTasksByDescription() {
        let task1 = KanbanTask(
            title: "Fix bug",
            description: "unique-desc-keyword",
            boardId: boardId
        )
        let task2 = KanbanTask(
            title: "New feature",
            description: "unrelated description",
            boardId: boardId
        )

        kanbanManager.createTask(task1)
        kanbanManager.createTask(task2)

        let results = kanbanManager.searchTasks(query: "unique-desc-keyword")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.id, task1.id)
    }

    func testSearchTasksCaseInsensitive() {
        let task = KanbanTask(title: "UPPERCASE TITLE", description: "lowercase desc", boardId: boardId)
        kanbanManager.createTask(task)

        let upperResults = kanbanManager.searchTasks(query: "UPPERCASE")
        let lowerResults = kanbanManager.searchTasks(query: "uppercase")
        let mixedResults = kanbanManager.searchTasks(query: "UpperCase")

        XCTAssertEqual(upperResults.count, 1)
        XCTAssertEqual(lowerResults.count, 1)
        XCTAssertEqual(mixedResults.count, 1)
    }

    func testSearchTasksNoMatchesReturnsEmpty() {
        let task = KanbanTask(title: "Real task title", description: "Real description", boardId: boardId)
        kanbanManager.createTask(task)

        let results = kanbanManager.searchTasks(query: "nonexistent-xyz-query")
        XCTAssertEqual(results.count, 0)
    }

    func testSearchTasksMatchesEitherTitleOrDescription() {
        let task1 = KanbanTask(title: "search-keyword in title", description: "no match here", boardId: boardId)
        let task2 = KanbanTask(title: "unrelated title", description: "search-keyword in description", boardId: boardId)
        let task3 = KanbanTask(title: "no match at all", description: "nothing relevant", boardId: boardId)

        kanbanManager.createTask(task1)
        kanbanManager.createTask(task2)
        kanbanManager.createTask(task3)

        let results = kanbanManager.searchTasks(query: "search-keyword")
        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.contains { $0.id == task1.id })
        XCTAssertTrue(results.contains { $0.id == task2.id })
    }

    // MARK: - searchTasks – sort order

    func testSearchTasksEmptyQuerySortedByCreatedDescending() {
        // Create tasks with explicit created dates to control ordering
        var metadata1 = KanbanTaskMetadata()
        metadata1.created = Date(timeIntervalSinceNow: -200)
        let oldTask = KanbanTask(title: "Old Task", boardId: boardId, metadata: metadata1)

        var metadata2 = KanbanTaskMetadata()
        metadata2.created = Date(timeIntervalSinceNow: -100)
        let midTask = KanbanTask(title: "Mid Task", boardId: boardId, metadata: metadata2)

        var metadata3 = KanbanTaskMetadata()
        metadata3.created = Date(timeIntervalSinceNow: -10)
        let newTask = KanbanTask(title: "New Task", boardId: boardId, metadata: metadata3)

        kanbanManager.createTask(oldTask)
        kanbanManager.createTask(midTask)
        kanbanManager.createTask(newTask)

        let results = kanbanManager.searchTasks(query: "")
        XCTAssertEqual(results.count, 3)
        // Most recently created should come first
        XCTAssertEqual(results[0].id, newTask.id)
        XCTAssertEqual(results[1].id, midTask.id)
        XCTAssertEqual(results[2].id, oldTask.id)
    }

    func testSearchTasksNonEmptyQuerySortedByCreatedDescending() {
        var metadata1 = KanbanTaskMetadata()
        metadata1.created = Date(timeIntervalSinceNow: -300)
        let oldTask = KanbanTask(title: "Match A old", boardId: boardId, metadata: metadata1)

        var metadata2 = KanbanTaskMetadata()
        metadata2.created = Date(timeIntervalSinceNow: -50)
        let newTask = KanbanTask(title: "Match A new", boardId: boardId, metadata: metadata2)

        kanbanManager.createTask(oldTask)
        kanbanManager.createTask(newTask)

        let results = kanbanManager.searchTasks(query: "Match A")
        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[0].id, newTask.id)
        XCTAssertEqual(results[1].id, oldTask.id)
    }

    // MARK: - searchTasks – tasks across boards

    func testSearchTasksReturnsTasksFromAllBoards() {
        let board2 = KanbanBoard(name: "Second Board")
        kanbanManager.createBoard(board2)

        let task1 = KanbanTask(title: "shared-keyword task on board 1", boardId: boardId)
        let task2 = KanbanTask(title: "shared-keyword task on board 2", boardId: board2.id)

        kanbanManager.createTask(task1)
        kanbanManager.createTask(task2)

        let results = kanbanManager.searchTasks(query: "shared-keyword")
        XCTAssertEqual(results.count, 2)
    }

    // MARK: - Board and task management integration

    func testCreateAndRetrieveBoard() {
        let board = KanbanBoard(name: "Sprint Board", description: "Q1 Sprint")
        kanbanManager.createBoard(board)

        let retrieved = kanbanManager.getBoard(id: board.id)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.name, "Sprint Board")
        XCTAssertEqual(retrieved?.description, "Q1 Sprint")
    }

    func testCreateAndRetrieveTask() {
        let task = KanbanTask(title: "Test task", description: "A task for testing", boardId: boardId)
        kanbanManager.createTask(task)

        let retrieved = kanbanManager.getTask(id: task.id)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.title, "Test task")
        XCTAssertEqual(retrieved?.description, "A task for testing")
        XCTAssertEqual(retrieved?.column, .backlog)
    }

    func testDeleteBoardRemovesOrphanedTasks() {
        let task1 = KanbanTask(title: "Orphan Task 1", boardId: boardId)
        let task2 = KanbanTask(title: "Orphan Task 2", boardId: boardId)

        kanbanManager.createTask(task1)
        kanbanManager.createTask(task2)

        XCTAssertEqual(kanbanManager.getTasks(forBoard: boardId).count, 2)

        kanbanManager.deleteBoard(id: boardId)

        XCTAssertNil(kanbanManager.getBoard(id: boardId))
        XCTAssertNil(kanbanManager.getTask(id: task1.id))
        XCTAssertNil(kanbanManager.getTask(id: task2.id))
    }
}
