import XCTest
@testable import WritersApp

/// Comprehensive tests for KanbanManager operations
final class KanbanManagerTests: XCTestCase {
    var kanbanManager: KanbanManager!
    var testBoardId: UUID!

    override func setUp() {
        super.setUp()
        kanbanManager = KanbanManager()
        let board = KanbanBoard(name: "Test Board", description: "Board for tests")
        kanbanManager.createBoard(board)
        testBoardId = board.id
    }

    override func tearDown() {
        kanbanManager = nil
        testBoardId = nil
        super.tearDown()
    }

    // MARK: - searchTasks: empty and whitespace query (changed behaviour)

    func testSearchTasksEmptyQueryReturnsAllTasks() {
        let task1 = KanbanTask(title: "Write chapter 1", boardId: testBoardId)
        let task2 = KanbanTask(title: "Review outline", boardId: testBoardId)
        let task3 = KanbanTask(title: "Edit prologue", boardId: testBoardId)
        kanbanManager.createTask(task1)
        kanbanManager.createTask(task2)
        kanbanManager.createTask(task3)

        let results = kanbanManager.searchTasks(query: "")
        XCTAssertEqual(results.count, 3)
    }

    func testSearchTasksWhitespaceOnlyQueryReturnsAllTasks() {
        let task1 = KanbanTask(title: "Task Alpha", boardId: testBoardId)
        let task2 = KanbanTask(title: "Task Beta", boardId: testBoardId)
        kanbanManager.createTask(task1)
        kanbanManager.createTask(task2)

        let results = kanbanManager.searchTasks(query: "   ")
        XCTAssertEqual(results.count, 2)
    }

    func testSearchTasksNewlineTabQueryReturnsAllTasks() {
        let task1 = KanbanTask(title: "Task One", boardId: testBoardId)
        let task2 = KanbanTask(title: "Task Two", boardId: testBoardId)
        kanbanManager.createTask(task1)
        kanbanManager.createTask(task2)

        let results = kanbanManager.searchTasks(query: "\n\t")
        XCTAssertEqual(results.count, 2)
    }

    func testSearchTasksEmptyQueryOnEmptyManagerReturnsEmptyArray() {
        let results = kanbanManager.searchTasks(query: "")
        XCTAssertEqual(results.count, 0)
    }

    // MARK: - searchTasks: filtering with non-empty query

    func testSearchTasksByTitle() {
        let task1 = KanbanTask(title: "Research character backstory", boardId: testBoardId)
        let task2 = KanbanTask(title: "Write battle scene", boardId: testBoardId)
        let task3 = KanbanTask(title: "Character arc revision", boardId: testBoardId)
        kanbanManager.createTask(task1)
        kanbanManager.createTask(task2)
        kanbanManager.createTask(task3)

        let results = kanbanManager.searchTasks(query: "character")
        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.contains { $0.id == task1.id })
        XCTAssertTrue(results.contains { $0.id == task3.id })
    }

    func testSearchTasksByDescription() {
        let task1 = KanbanTask(title: "Task A", description: "Improve pacing in act two", boardId: testBoardId)
        let task2 = KanbanTask(title: "Task B", description: "Fix dialogue issues", boardId: testBoardId)
        kanbanManager.createTask(task1)
        kanbanManager.createTask(task2)

        let results = kanbanManager.searchTasks(query: "pacing")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.id, task1.id)
    }

    func testSearchTasksCaseInsensitive() {
        let task = KanbanTask(title: "UPPERCASE TASK", description: "lowercase description", boardId: testBoardId)
        kanbanManager.createTask(task)

        XCTAssertEqual(kanbanManager.searchTasks(query: "UPPERCASE").count, 1)
        XCTAssertEqual(kanbanManager.searchTasks(query: "uppercase").count, 1)
        XCTAssertEqual(kanbanManager.searchTasks(query: "UpperCase").count, 1)
        XCTAssertEqual(kanbanManager.searchTasks(query: "LOWERCASE").count, 1)
    }

    func testSearchTasksNoMatchReturnsEmpty() {
        let task = KanbanTask(title: "Existing task", boardId: testBoardId)
        kanbanManager.createTask(task)

        let results = kanbanManager.searchTasks(query: "nonexistent_xyz")
        XCTAssertEqual(results.count, 0)
    }

    func testSearchTasksMatchesTitleOrDescription() {
        let task1 = KanbanTask(title: "Plot outline", description: "Cover story structure", boardId: testBoardId)
        let task2 = KanbanTask(title: "Edit draft", description: "Check plot consistency", boardId: testBoardId)
        let task3 = KanbanTask(title: "Character notes", description: "Develop personalities", boardId: testBoardId)
        kanbanManager.createTask(task1)
        kanbanManager.createTask(task2)
        kanbanManager.createTask(task3)

        let results = kanbanManager.searchTasks(query: "plot")
        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.contains { $0.id == task1.id })
        XCTAssertTrue(results.contains { $0.id == task2.id })
    }

    func testSearchTasksResultsSortedByCreatedDescending() {
        let metadata1 = KanbanTaskMetadata(created: Date(timeIntervalSinceNow: -200))
        let task1 = KanbanTask(title: "First task", boardId: testBoardId, metadata: metadata1)

        let metadata2 = KanbanTaskMetadata(created: Date(timeIntervalSinceNow: -100))
        let task2 = KanbanTask(title: "Second task", boardId: testBoardId, metadata: metadata2)

        let metadata3 = KanbanTaskMetadata(created: Date(timeIntervalSinceNow: -50))
        let task3 = KanbanTask(title: "Third task", boardId: testBoardId, metadata: metadata3)

        kanbanManager.createTask(task1)
        kanbanManager.createTask(task2)
        kanbanManager.createTask(task3)

        // Non-empty query: all titles contain "task"
        let results = kanbanManager.searchTasks(query: "task")
        XCTAssertEqual(results.count, 3)
        XCTAssertEqual(results[0].id, task3.id) // newest first
        XCTAssertEqual(results[1].id, task2.id)
        XCTAssertEqual(results[2].id, task1.id)
    }

    func testSearchTasksEmptyQueryResultsSortedByCreatedDescending() {
        let metadata1 = KanbanTaskMetadata(created: Date(timeIntervalSinceNow: -200))
        let task1 = KanbanTask(title: "Old task", boardId: testBoardId, metadata: metadata1)

        let metadata2 = KanbanTaskMetadata(created: Date(timeIntervalSinceNow: -50))
        let task2 = KanbanTask(title: "New task", boardId: testBoardId, metadata: metadata2)

        kanbanManager.createTask(task1)
        kanbanManager.createTask(task2)

        let results = kanbanManager.searchTasks(query: "")
        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[0].id, task2.id) // newest first
        XCTAssertEqual(results[1].id, task1.id)
    }

    func testSearchTasksWhitespaceQueryResultsSortedByCreatedDescending() {
        let metadata1 = KanbanTaskMetadata(created: Date(timeIntervalSinceNow: -300))
        let task1 = KanbanTask(title: "Oldest task", boardId: testBoardId, metadata: metadata1)

        let metadata2 = KanbanTaskMetadata(created: Date(timeIntervalSinceNow: -100))
        let task2 = KanbanTask(title: "Middle task", boardId: testBoardId, metadata: metadata2)

        let metadata3 = KanbanTaskMetadata(created: Date(timeIntervalSinceNow: -10))
        let task3 = KanbanTask(title: "Newest task", boardId: testBoardId, metadata: metadata3)

        kanbanManager.createTask(task1)
        kanbanManager.createTask(task2)
        kanbanManager.createTask(task3)

        let results = kanbanManager.searchTasks(query: "  ")
        XCTAssertEqual(results.count, 3)
        XCTAssertEqual(results[0].id, task3.id)
        XCTAssertEqual(results[1].id, task2.id)
        XCTAssertEqual(results[2].id, task1.id)
    }

    // MARK: - Board CRUD

    func testCreateAndGetBoard() {
        let board = KanbanBoard(name: "My Novel Board", description: "Tasks for the novel")
        kanbanManager.createBoard(board)

        let retrieved = kanbanManager.getBoard(id: board.id)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.name, "My Novel Board")
        XCTAssertEqual(retrieved?.description, "Tasks for the novel")
    }

    func testGetBoardReturnsNilForUnknownId() {
        let result = kanbanManager.getBoard(id: UUID())
        XCTAssertNil(result)
    }

    func testGetAllBoardsSortedByCreatedDescending() {
        let meta1 = KanbanBoardMetadata(created: Date(timeIntervalSinceNow: -300))
        let board1 = KanbanBoard(name: "Board A", metadata: meta1)

        let meta2 = KanbanBoardMetadata(created: Date(timeIntervalSinceNow: -100))
        let board2 = KanbanBoard(name: "Board B", metadata: meta2)

        kanbanManager.createBoard(board1)
        kanbanManager.createBoard(board2)

        let boards = kanbanManager.getAllBoards()
        // testBoardId board was created in setUp – filter it out for ordering check
        let filteredBoards = boards.filter { $0.id == board1.id || $0.id == board2.id }
        XCTAssertEqual(filteredBoards[0].id, board2.id) // newer first
        XCTAssertEqual(filteredBoards[1].id, board1.id)
    }

    func testUpdateBoard() {
        var board = KanbanBoard(name: "Original Name")
        kanbanManager.createBoard(board)

        board.name = "Updated Name"
        kanbanManager.updateBoard(board)

        let retrieved = kanbanManager.getBoard(id: board.id)
        XCTAssertEqual(retrieved?.name, "Updated Name")
    }

    func testDeleteBoardRemovesBoard() {
        let board = KanbanBoard(name: "Temporary Board")
        kanbanManager.createBoard(board)
        kanbanManager.deleteBoard(id: board.id)

        XCTAssertNil(kanbanManager.getBoard(id: board.id))
    }

    func testDeleteBoardAlsoRemovesOrphanedTasks() {
        let board = KanbanBoard(name: "Board With Tasks")
        kanbanManager.createBoard(board)

        let task1 = KanbanTask(title: "Task 1", boardId: board.id)
        let task2 = KanbanTask(title: "Task 2", boardId: board.id)
        kanbanManager.createTask(task1)
        kanbanManager.createTask(task2)

        kanbanManager.deleteBoard(id: board.id)

        XCTAssertNil(kanbanManager.getTask(id: task1.id))
        XCTAssertNil(kanbanManager.getTask(id: task2.id))
    }

    func testDeleteBoardDoesNotRemoveTasksOnOtherBoards() {
        let otherBoard = KanbanBoard(name: "Keeper Board")
        kanbanManager.createBoard(otherBoard)

        let boardToDelete = KanbanBoard(name: "Doomed Board")
        kanbanManager.createBoard(boardToDelete)

        let keeperTask = KanbanTask(title: "Keep me", boardId: otherBoard.id)
        let doomedTask = KanbanTask(title: "Delete me", boardId: boardToDelete.id)
        kanbanManager.createTask(keeperTask)
        kanbanManager.createTask(doomedTask)

        kanbanManager.deleteBoard(id: boardToDelete.id)

        XCTAssertNotNil(kanbanManager.getTask(id: keeperTask.id))
        XCTAssertNil(kanbanManager.getTask(id: doomedTask.id))
    }

    // MARK: - Task CRUD

    func testCreateAndGetTask() {
        let task = KanbanTask(title: "Draft synopsis", description: "One paragraph summary", boardId: testBoardId)
        kanbanManager.createTask(task)

        let retrieved = kanbanManager.getTask(id: task.id)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.title, "Draft synopsis")
        XCTAssertEqual(retrieved?.description, "One paragraph summary")
    }

    func testGetTaskReturnsNilForUnknownId() {
        XCTAssertNil(kanbanManager.getTask(id: UUID()))
    }

    func testDeleteTask() {
        let task = KanbanTask(title: "Doomed task", boardId: testBoardId)
        kanbanManager.createTask(task)
        kanbanManager.deleteTask(id: task.id)

        XCTAssertNil(kanbanManager.getTask(id: task.id))
    }

    func testGetTasksForBoard() {
        let otherBoard = KanbanBoard(name: "Other Board")
        kanbanManager.createBoard(otherBoard)

        let task1 = KanbanTask(title: "Task for test board", boardId: testBoardId)
        let task2 = KanbanTask(title: "Another task for test board", boardId: testBoardId)
        let task3 = KanbanTask(title: "Task for other board", boardId: otherBoard.id)
        kanbanManager.createTask(task1)
        kanbanManager.createTask(task2)
        kanbanManager.createTask(task3)

        let testBoardTasks = kanbanManager.getTasks(forBoard: testBoardId)
        XCTAssertEqual(testBoardTasks.count, 2)

        let otherBoardTasks = kanbanManager.getTasks(forBoard: otherBoard.id)
        XCTAssertEqual(otherBoardTasks.count, 1)
    }

    func testUpdateTask() {
        var task = KanbanTask(title: "Original Title", boardId: testBoardId)
        kanbanManager.createTask(task)

        task.title = "Updated Title"
        kanbanManager.updateTask(task)

        let retrieved = kanbanManager.getTask(id: task.id)
        XCTAssertEqual(retrieved?.title, "Updated Title")
    }

    // MARK: - Column Transitions

    func testMoveTaskToColumn() {
        let task = KanbanTask(title: "Move me", column: .backlog, boardId: testBoardId)
        kanbanManager.createTask(task)

        kanbanManager.moveTask(id: task.id, toColumn: .running)

        let retrieved = kanbanManager.getTask(id: task.id)
        XCTAssertEqual(retrieved?.column, .running)
    }

    func testMoveTaskToDoneSetsCompletedAt() {
        let task = KanbanTask(title: "Done task", column: .review, boardId: testBoardId)
        kanbanManager.createTask(task)

        kanbanManager.moveTask(id: task.id, toColumn: .done)

        let retrieved = kanbanManager.getTask(id: task.id)
        XCTAssertNotNil(retrieved?.metadata.completedAt)
    }

    func testMoveTaskOutOfDoneClearsCompletedAt() {
        let task = KanbanTask(title: "Moved back", column: .done, boardId: testBoardId)
        kanbanManager.createTask(task)

        kanbanManager.moveTask(id: task.id, toColumn: .review)

        let retrieved = kanbanManager.getTask(id: task.id)
        XCTAssertNil(retrieved?.metadata.completedAt)
    }

    func testAdvanceTask() {
        let task = KanbanTask(title: "Advance me", column: .backlog, boardId: testBoardId)
        kanbanManager.createTask(task)

        let nextColumn = kanbanManager.advanceTask(id: task.id)
        XCTAssertEqual(nextColumn, .planning)
        XCTAssertEqual(kanbanManager.getTask(id: task.id)?.column, .planning)
    }

    func testAdvanceTaskAtDoneReturnsNil() {
        let task = KanbanTask(title: "Final task", column: .done, boardId: testBoardId)
        kanbanManager.createTask(task)

        let result = kanbanManager.advanceTask(id: task.id)
        XCTAssertNil(result)
    }

    func testRegressTask() {
        let task = KanbanTask(title: "Regress me", column: .running, boardId: testBoardId)
        kanbanManager.createTask(task)

        let prevColumn = kanbanManager.regressTask(id: task.id)
        XCTAssertEqual(prevColumn, .planning)
        XCTAssertEqual(kanbanManager.getTask(id: task.id)?.column, .planning)
    }

    func testRegressTaskAtBacklogReturnsNil() {
        let task = KanbanTask(title: "Backlog task", column: .backlog, boardId: testBoardId)
        kanbanManager.createTask(task)

        let result = kanbanManager.regressTask(id: task.id)
        XCTAssertNil(result)
    }

    func testAdvanceThroughAllColumns() {
        let task = KanbanTask(title: "Journey task", column: .backlog, boardId: testBoardId)
        kanbanManager.createTask(task)

        XCTAssertEqual(kanbanManager.advanceTask(id: task.id), .planning)
        XCTAssertEqual(kanbanManager.advanceTask(id: task.id), .running)
        XCTAssertEqual(kanbanManager.advanceTask(id: task.id), .review)
        XCTAssertEqual(kanbanManager.advanceTask(id: task.id), .done)
        XCTAssertNil(kanbanManager.advanceTask(id: task.id))
    }

    // MARK: - Statistics

    func testGetTaskCountByColumnForBoard() {
        let task1 = KanbanTask(title: "Backlog 1", column: .backlog, boardId: testBoardId)
        let task2 = KanbanTask(title: "Backlog 2", column: .backlog, boardId: testBoardId)
        let task3 = KanbanTask(title: "Running 1", column: .running, boardId: testBoardId)
        kanbanManager.createTask(task1)
        kanbanManager.createTask(task2)
        kanbanManager.createTask(task3)

        let counts = kanbanManager.getTaskCountByColumn(forBoard: testBoardId)
        XCTAssertEqual(counts[.backlog], 2)
        XCTAssertEqual(counts[.running], 1)
        XCTAssertEqual(counts[.done], 0)
    }

    func testGetTaskCountByColumnAcrossAllBoards() {
        let otherBoard = KanbanBoard(name: "Another Board")
        kanbanManager.createBoard(otherBoard)

        let task1 = KanbanTask(title: "Done on test board", column: .done, boardId: testBoardId)
        let task2 = KanbanTask(title: "Done on other board", column: .done, boardId: otherBoard.id)
        kanbanManager.createTask(task1)
        kanbanManager.createTask(task2)

        let counts = kanbanManager.getTaskCountByColumn()
        XCTAssertEqual(counts[.done], 2)
    }

    func testGetTaskCountByColumnReturnsZeroForEmptyBoard() {
        let counts = kanbanManager.getTaskCountByColumn(forBoard: testBoardId)
        for column in KanbanColumn.allCases {
            XCTAssertEqual(counts[column], 0)
        }
    }

    // MARK: - getTasks with column filter

    func testGetTasksForBoardInColumn() {
        let task1 = KanbanTask(title: "Backlog task", column: .backlog, boardId: testBoardId)
        let task2 = KanbanTask(title: "Running task", column: .running, boardId: testBoardId)
        let task3 = KanbanTask(title: "Another backlog", column: .backlog, boardId: testBoardId)
        kanbanManager.createTask(task1)
        kanbanManager.createTask(task2)
        kanbanManager.createTask(task3)

        let backlogTasks = kanbanManager.getTasks(forBoard: testBoardId, inColumn: .backlog)
        XCTAssertEqual(backlogTasks.count, 2)
        XCTAssertTrue(backlogTasks.allSatisfy { $0.column == .backlog })

        let runningTasks = kanbanManager.getTasks(forBoard: testBoardId, inColumn: .running)
        XCTAssertEqual(runningTasks.count, 1)
    }

    func testGetTasksInColumnAcrossBoards() {
        let otherBoard = KanbanBoard(name: "Other Board")
        kanbanManager.createBoard(otherBoard)

        let task1 = KanbanTask(title: "Planning A", column: .planning, boardId: testBoardId)
        let task2 = KanbanTask(title: "Planning B", column: .planning, boardId: otherBoard.id)
        let task3 = KanbanTask(title: "Backlog C", column: .backlog, boardId: testBoardId)
        kanbanManager.createTask(task1)
        kanbanManager.createTask(task2)
        kanbanManager.createTask(task3)

        let planningTasks = kanbanManager.getTasks(inColumn: .planning)
        XCTAssertEqual(planningTasks.count, 2)
    }
}