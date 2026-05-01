import XCTest
@testable import WritersApp

/// Tests for KanbanManager operations, focusing on the searchTasks behavior
/// introduced/changed in the PR (empty/whitespace query returns all tasks).
final class KanbanManagerTests: XCTestCase {
    var kanbanManager: KanbanManager!
    var boardId: UUID!

    override func setUp() {
        super.setUp()
        kanbanManager = KanbanManager()
        let board = KanbanBoard(name: "Test Board")
        kanbanManager.createBoard(board)
        boardId = board.id
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

    // MARK: - searchTasks: empty / whitespace query (PR change)

    func testSearchTasksEmptyQueryReturnsAll() {
        // PR change: empty query now returns all tasks instead of empty array
        let task1 = makeTask(title: "Write chapter one")
        let task2 = makeTask(title: "Edit chapter two")
        let task3 = makeTask(title: "Review outline")

        kanbanManager.createTask(task1)
        kanbanManager.createTask(task2)
        kanbanManager.createTask(task3)

        let results = kanbanManager.searchTasks(query: "")
        XCTAssertEqual(results.count, 3)
    }

    func testSearchTasksWhitespaceOnlyQueryReturnsAll() {
        // PR change: whitespace-only query returns all tasks instead of empty array
        let task1 = makeTask(title: "Task Alpha")
        let task2 = makeTask(title: "Task Beta")

        kanbanManager.createTask(task1)
        kanbanManager.createTask(task2)

        let spaceResults = kanbanManager.searchTasks(query: "   ")
        XCTAssertEqual(spaceResults.count, 2)

        let newlineResults = kanbanManager.searchTasks(query: "\n\n")
        XCTAssertEqual(newlineResults.count, 2)

        let tabResults = kanbanManager.searchTasks(query: "\t  \t")
        XCTAssertEqual(tabResults.count, 2)
    }

    func testSearchTasksEmptyQueryOnEmptyStore() {
        // Edge case: empty query on empty manager returns empty array
        let results = kanbanManager.searchTasks(query: "")
        XCTAssertEqual(results.count, 0)
    }

    func testSearchTasksWhitespaceQueryOnEmptyStore() {
        // Edge case: whitespace query on empty manager returns empty array, does not crash
        let results = kanbanManager.searchTasks(query: "   ")
        XCTAssertEqual(results.count, 0)
    }

    func testSearchTasksEmptyQuerySortedByCreatedDesc() {
        // Verify all-tasks result from empty query is sorted newest-created first
        let task1 = makeTask(title: "Older Task")
        kanbanManager.createTask(task1)
        Thread.sleep(forTimeInterval: 0.01)
        let task2 = makeTask(title: "Newer Task")
        kanbanManager.createTask(task2)

        let results = kanbanManager.searchTasks(query: "")
        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[0].id, task2.id)
        XCTAssertEqual(results[1].id, task1.id)
    }

    func testSearchTasksWhitespaceQuerySortedByCreatedDesc() {
        // Verify all-tasks result from whitespace query is also sorted newest-created first
        let task1 = makeTask(title: "First Task")
        kanbanManager.createTask(task1)
        Thread.sleep(forTimeInterval: 0.01)
        let task2 = makeTask(title: "Second Task")
        kanbanManager.createTask(task2)

        let results = kanbanManager.searchTasks(query: "  ")
        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[0].id, task2.id)
        XCTAssertEqual(results[1].id, task1.id)
    }

    // MARK: - searchTasks: non-empty query filtering

    func testSearchTasksByTitle() {
        let task1 = makeTask(title: "Write introduction")
        let task2 = makeTask(title: "Edit conclusion")
        let task3 = makeTask(title: "Write body paragraphs")

        kanbanManager.createTask(task1)
        kanbanManager.createTask(task2)
        kanbanManager.createTask(task3)

        let results = kanbanManager.searchTasks(query: "Write")
        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.contains { $0.id == task1.id })
        XCTAssertTrue(results.contains { $0.id == task3.id })
        XCTAssertFalse(results.contains { $0.id == task2.id })
    }

    func testSearchTasksByDescription() {
        let task1 = makeTask(title: "Task One", description: "Involves character backstory development")
        let task2 = makeTask(title: "Task Two", description: "Plot structure review")
        let task3 = makeTask(title: "Task Three", description: "Grammar and punctuation fixes")

        kanbanManager.createTask(task1)
        kanbanManager.createTask(task2)
        kanbanManager.createTask(task3)

        let results = kanbanManager.searchTasks(query: "backstory")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.id, task1.id)
    }

    func testSearchTasksByTitleOrDescription() {
        // A task matches if either title or description contains the query
        let task1 = makeTask(title: "Dialogue revision", description: "Improve pacing in chapter three")
        let task2 = makeTask(title: "Unrelated task", description: "Check dialogue tags")
        let task3 = makeTask(title: "Plot review", description: "Structural analysis")

        kanbanManager.createTask(task1)
        kanbanManager.createTask(task2)
        kanbanManager.createTask(task3)

        let results = kanbanManager.searchTasks(query: "dialogue")
        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.contains { $0.id == task1.id })
        XCTAssertTrue(results.contains { $0.id == task2.id })
    }

    func testSearchTasksCaseInsensitiveTitle() {
        let task = makeTask(title: "UPPERCASE TASK TITLE")
        kanbanManager.createTask(task)

        let upperResults = kanbanManager.searchTasks(query: "UPPERCASE")
        XCTAssertEqual(upperResults.count, 1)

        let lowerResults = kanbanManager.searchTasks(query: "uppercase")
        XCTAssertEqual(lowerResults.count, 1)

        let mixedResults = kanbanManager.searchTasks(query: "UpperCase")
        XCTAssertEqual(mixedResults.count, 1)
    }

    func testSearchTasksCaseInsensitiveDescription() {
        let task = makeTask(title: "Any Title", description: "Lowercase description content")
        kanbanManager.createTask(task)

        let upperResults = kanbanManager.searchTasks(query: "LOWERCASE")
        XCTAssertEqual(upperResults.count, 1)

        let exactResults = kanbanManager.searchTasks(query: "lowercase")
        XCTAssertEqual(exactResults.count, 1)
    }

    func testSearchTasksNoMatchReturnsEmptyArray() {
        let task = makeTask(title: "Write synopsis", description: "Summarize the story")
        kanbanManager.createTask(task)

        let results = kanbanManager.searchTasks(query: "nonexistent keyword xyz")
        XCTAssertEqual(results.count, 0)
    }

    func testSearchTasksNonEmptyQuerySortedByCreatedDesc() {
        let task1 = makeTask(title: "Feature alpha")
        kanbanManager.createTask(task1)
        Thread.sleep(forTimeInterval: 0.01)
        let task2 = makeTask(title: "Feature beta")
        kanbanManager.createTask(task2)

        let results = kanbanManager.searchTasks(query: "Feature")
        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[0].id, task2.id)
        XCTAssertEqual(results[1].id, task1.id)
    }

    func testSearchTasksQueryWithSurroundingWhitespace() {
        // PR change: query is passed directly to localizedCaseInsensitiveContains
        // without trimming, so surrounding whitespace is part of the match string.
        let task = makeTask(title: "Write draft")
        kanbanManager.createTask(task)

        // Exact match works
        let exactResults = kanbanManager.searchTasks(query: "Write")
        XCTAssertEqual(exactResults.count, 1)

        // Padded query does not match (spaces included in search string)
        let paddedResults = kanbanManager.searchTasks(query: " Write ")
        XCTAssertEqual(paddedResults.count, 0)
    }

    // MARK: - searchTasks: tasks across multiple boards

    func testSearchTasksAcrossAllBoards() {
        let board2 = KanbanBoard(name: "Second Board")
        kanbanManager.createBoard(board2)

        let task1 = KanbanTask(title: "Story planning", boardId: boardId)
        let task2 = KanbanTask(title: "Story editing", boardId: board2.id)
        let task3 = KanbanTask(title: "Research notes", boardId: boardId)

        kanbanManager.createTask(task1)
        kanbanManager.createTask(task2)
        kanbanManager.createTask(task3)

        // searchTasks searches across all boards
        let storyResults = kanbanManager.searchTasks(query: "story")
        XCTAssertEqual(storyResults.count, 2)
        XCTAssertTrue(storyResults.contains { $0.id == task1.id })
        XCTAssertTrue(storyResults.contains { $0.id == task2.id })

        // Empty query returns all tasks from all boards
        let allResults = kanbanManager.searchTasks(query: "")
        XCTAssertEqual(allResults.count, 3)
    }

    // MARK: - searchTasks: boundary and regression cases

    func testSearchTasksSingleTask() {
        // Boundary: only one task in store
        let task = makeTask(title: "Lone task", description: "Single item")
        kanbanManager.createTask(task)

        let matchResults = kanbanManager.searchTasks(query: "Lone")
        XCTAssertEqual(matchResults.count, 1)

        let noMatchResults = kanbanManager.searchTasks(query: "nothing")
        XCTAssertEqual(noMatchResults.count, 0)

        let emptyResults = kanbanManager.searchTasks(query: "")
        XCTAssertEqual(emptyResults.count, 1)
    }

    func testSearchTasksWithEmptyTitleAndDescription() {
        // Edge case: task with empty title and description; only matches empty/whitespace queries
        let task = makeTask(title: "", description: "")
        kanbanManager.createTask(task)

        let emptyQueryResults = kanbanManager.searchTasks(query: "")
        XCTAssertEqual(emptyQueryResults.count, 1)

        let nonEmptyResults = kanbanManager.searchTasks(query: "anything")
        XCTAssertEqual(nonEmptyResults.count, 0)
    }

    func testSearchTasksWithUnicodeCharacters() {
        // Regression: search should work correctly with non-ASCII content
        let task1 = makeTask(title: "Chapter: 日本語タイトル", description: "Japanese content")
        let task2 = makeTask(title: "Chapter: Émoji 🎉", description: "Emoji content")
        kanbanManager.createTask(task1)
        kanbanManager.createTask(task2)

        let japaneseResults = kanbanManager.searchTasks(query: "日本語")
        XCTAssertEqual(japaneseResults.count, 1)
        XCTAssertEqual(japaneseResults.first?.id, task1.id)

        let allResults = kanbanManager.searchTasks(query: "")
        XCTAssertEqual(allResults.count, 2)
    }

    func testSearchTasksPartialMatchInTitle() {
        // Verify substring matching works (not exact word only)
        let task = makeTask(title: "Brainstorming session")
        kanbanManager.createTask(task)

        let substringResults = kanbanManager.searchTasks(query: "storm")
        XCTAssertEqual(substringResults.count, 1)

        let prefixResults = kanbanManager.searchTasks(query: "Brain")
        XCTAssertEqual(prefixResults.count, 1)

        let suffixResults = kanbanManager.searchTasks(query: "session")
        XCTAssertEqual(suffixResults.count, 1)
    }

    func testSearchTasksManyTasksEmptyQuery() {
        // Boundary: verify all tasks are returned when many are present
        for i in 1...20 {
            let task = makeTask(title: "Task \(i)", description: "Description \(i)")
            kanbanManager.createTask(task)
        }

        let results = kanbanManager.searchTasks(query: "")
        XCTAssertEqual(results.count, 20)

        let wsResults = kanbanManager.searchTasks(query: "  ")
        XCTAssertEqual(wsResults.count, 20)
    }
}
