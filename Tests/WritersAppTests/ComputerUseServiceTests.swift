import XCTest
@testable import WritersApp

/// Tests for Computer Use models and service introduced in this PR.
/// Covers ComputerUseActionType, ComputerUseAction, ComputerUseResult,
/// ComputerUseConfiguration, ComputerUseSessionResult, ComputerUseError,
/// and the ComputerUseService itself using a mock executor.
final class ComputerUseServiceTests: XCTestCase {

    // MARK: - ComputerUseActionType Raw Values

    func testComputerUseActionTypeRawValueRightClick() {
        XCTAssertEqual(ComputerUseActionType.rightClick.rawValue, "right_click")
    }

    func testComputerUseActionTypeRawValueDoubleClick() {
        XCTAssertEqual(ComputerUseActionType.doubleClick.rawValue, "double_click")
    }

    func testComputerUseActionTypeRawValueMiddleClick() {
        XCTAssertEqual(ComputerUseActionType.middleClick.rawValue, "middle_click")
    }

    func testComputerUseActionTypeRawValueLeftClickDrag() {
        XCTAssertEqual(ComputerUseActionType.leftClickDrag.rawValue, "left_click_drag")
    }

    func testComputerUseActionTypeRawValueMouseMove() {
        XCTAssertEqual(ComputerUseActionType.mouseMoveAction.rawValue, "mouse_move")
    }

    func testComputerUseActionTypeRawValueWait() {
        XCTAssertEqual(ComputerUseActionType.wait.rawValue, "wait")
    }

    func testComputerUseActionTypeRawValueCursorPosition() {
        XCTAssertEqual(ComputerUseActionType.cursorPosition.rawValue, "cursor_position")
    }

    // MARK: - ComputerUseAction Codable

    func testComputerUseActionScreenshotAllNilOptionals() throws {
        let action = ComputerUseAction(action: .screenshot)
        let data = try JSONEncoder().encode(action)
        let decoded = try JSONDecoder().decode(ComputerUseAction.self, from: data)

        XCTAssertEqual(decoded.action, .screenshot)
        XCTAssertNil(decoded.coordinate)
        XCTAssertNil(decoded.startCoordinate)
        XCTAssertNil(decoded.text)
        XCTAssertNil(decoded.key)
        XCTAssertNil(decoded.direction)
        XCTAssertNil(decoded.amount)
        XCTAssertNil(decoded.duration)
    }

    func testComputerUseActionTypeActionWithTextField() throws {
        let action = ComputerUseAction(action: .type, text: "Hello, World!")
        let data = try JSONEncoder().encode(action)
        let decoded = try JSONDecoder().decode(ComputerUseAction.self, from: data)

        XCTAssertEqual(decoded.action, .type)
        XCTAssertEqual(decoded.text, "Hello, World!")
        XCTAssertNil(decoded.coordinate)
    }

    func testComputerUseActionKeypressWithKeyField() throws {
        let action = ComputerUseAction(action: .keypress, key: "ctrl+c")
        let data = try JSONEncoder().encode(action)
        let decoded = try JSONDecoder().decode(ComputerUseAction.self, from: data)

        XCTAssertEqual(decoded.action, .keypress)
        XCTAssertEqual(decoded.key, "ctrl+c")
        XCTAssertNil(decoded.text)
    }

    func testComputerUseActionScrollWithDirectionAndAmount() throws {
        let action = ComputerUseAction(
            action: .scroll,
            coordinate: [400, 300],
            direction: "down",
            amount: 3
        )
        let data = try JSONEncoder().encode(action)
        let decoded = try JSONDecoder().decode(ComputerUseAction.self, from: data)

        XCTAssertEqual(decoded.action, .scroll)
        XCTAssertEqual(decoded.coordinate, [400, 300])
        XCTAssertEqual(decoded.direction, "down")
        XCTAssertEqual(decoded.amount, 3)
    }

    func testComputerUseActionWaitWithDuration() throws {
        let action = ComputerUseAction(action: .wait, duration: 1500)
        let data = try JSONEncoder().encode(action)
        let decoded = try JSONDecoder().decode(ComputerUseAction.self, from: data)

        XCTAssertEqual(decoded.action, .wait)
        XCTAssertEqual(decoded.duration, 1500)
        XCTAssertNil(decoded.coordinate)
    }

    func testComputerUseActionDragWithStartCoordinate() throws {
        let action = ComputerUseAction(
            action: .leftClickDrag,
            coordinate: [200, 300],
            startCoordinate: [100, 100]
        )
        let data = try JSONEncoder().encode(action)
        let decoded = try JSONDecoder().decode(ComputerUseAction.self, from: data)

        XCTAssertEqual(decoded.action, .leftClickDrag)
        XCTAssertEqual(decoded.coordinate, [200, 300])
        XCTAssertEqual(decoded.startCoordinate, [100, 100])
    }

    func testComputerUseActionAllFieldsPopulated() throws {
        let action = ComputerUseAction(
            action: .type,
            coordinate: [50, 75],
            startCoordinate: [10, 20],
            text: "typed text",
            key: "Return",
            direction: "up",
            amount: 5,
            duration: 200
        )
        let data = try JSONEncoder().encode(action)
        let decoded = try JSONDecoder().decode(ComputerUseAction.self, from: data)

        XCTAssertEqual(decoded.coordinate, [50, 75])
        XCTAssertEqual(decoded.startCoordinate, [10, 20])
        XCTAssertEqual(decoded.text, "typed text")
        XCTAssertEqual(decoded.key, "Return")
        XCTAssertEqual(decoded.direction, "up")
        XCTAssertEqual(decoded.amount, 5)
        XCTAssertEqual(decoded.duration, 200)
    }

    func testComputerUseActionDoubleClickWithCoordinate() throws {
        let action = ComputerUseAction(action: .doubleClick, coordinate: [640, 480])
        let data = try JSONEncoder().encode(action)
        let decoded = try JSONDecoder().decode(ComputerUseAction.self, from: data)

        XCTAssertEqual(decoded.action, .doubleClick)
        XCTAssertEqual(decoded.coordinate, [640, 480])
    }

    func testComputerUseActionMouseMove() throws {
        let action = ComputerUseAction(action: .mouseMoveAction, coordinate: [320, 240])
        let data = try JSONEncoder().encode(action)
        let decoded = try JSONDecoder().decode(ComputerUseAction.self, from: data)

        XCTAssertEqual(decoded.action, .mouseMoveAction)
        XCTAssertEqual(decoded.coordinate, [320, 240])
    }

    func testComputerUseActionCursorPosition() {
        let action = ComputerUseAction(action: .cursorPosition)
        XCTAssertEqual(action.action, .cursorPosition)
        XCTAssertNil(action.coordinate)
    }

    // MARK: - ComputerUseResult

    func testComputerUseResultWithError() {
        let action = ComputerUseAction(action: .leftClick, coordinate: [0, 0])
        let result = ComputerUseResult(
            action: action,
            screenshotBase64: nil,
            error: "Click target not found"
        )

        XCTAssertNil(result.screenshotBase64)
        XCTAssertEqual(result.error, "Click target not found")
        XCTAssertEqual(result.action.action, .leftClick)
    }

    func testComputerUseResultWithBothScreenshotAndError() {
        let action = ComputerUseAction(action: .screenshot)
        let result = ComputerUseResult(
            action: action,
            screenshotBase64: "partialScreenshotData",
            error: "Partial capture"
        )

        XCTAssertEqual(result.screenshotBase64, "partialScreenshotData")
        XCTAssertEqual(result.error, "Partial capture")
    }

    func testComputerUseResultDefaultsToNilFields() {
        let action = ComputerUseAction(action: .screenshot)
        let result = ComputerUseResult(action: action)

        XCTAssertNil(result.screenshotBase64)
        XCTAssertNil(result.error)
    }

    // MARK: - ComputerUseSessionResult

    func testComputerUseSessionResultSummaryWhenExhausted() {
        let result = ComputerUseSessionResult(
            task: "Fill out form",
            finalResponse: "Partially completed",
            actions: [ComputerUseAction(action: .screenshot)],
            iterationCount: 20,
            wasExhausted: true
        )

        XCTAssertTrue(result.wasExhausted)
        XCTAssertTrue(result.summary.contains("exhausted"), "Summary should say 'exhausted' when max iterations reached")
        XCTAssertTrue(result.summary.contains("20"), "Summary should include iteration count")
        XCTAssertTrue(result.summary.contains("Fill out form"), "Summary should contain task name")
    }

    func testComputerUseSessionResultSummaryWhenCompleted() {
        let result = ComputerUseSessionResult(
            task: "Open browser",
            finalResponse: "Done",
            actions: [ComputerUseAction(action: .screenshot), ComputerUseAction(action: .leftClick)],
            iterationCount: 3,
            wasExhausted: false
        )

        XCTAssertFalse(result.wasExhausted)
        XCTAssertTrue(result.summary.contains("completed"), "Summary should say 'completed' when finished normally")
        XCTAssertTrue(result.summary.contains("3"), "Summary should contain iteration count")
        XCTAssertTrue(result.summary.contains("2 actions"), "Summary should include action count")
    }

    func testComputerUseSessionResultSummaryContainsFinalResponse() {
        let result = ComputerUseSessionResult(
            task: "test task",
            finalResponse: "Task accomplished successfully",
            actions: [],
            iterationCount: 1,
            wasExhausted: false
        )

        XCTAssertTrue(result.summary.contains("Task accomplished successfully"))
    }

    func testComputerUseSessionResultWithZeroActions() {
        let result = ComputerUseSessionResult(
            task: "Inspect screen",
            finalResponse: "Screen is blank",
            actions: [],
            iterationCount: 1,
            wasExhausted: false
        )

        XCTAssertEqual(result.actions.count, 0)
        XCTAssertTrue(result.summary.contains("0 actions"))
    }

    func testComputerUseSessionResultIterationCount() {
        let result = ComputerUseSessionResult(
            task: "t",
            finalResponse: "r",
            actions: [],
            iterationCount: 7,
            wasExhausted: false
        )

        XCTAssertEqual(result.iterationCount, 7)
    }

    // MARK: - ComputerUseError

    func testComputerUseErrorInvalidRequestMessage() {
        let error = ComputerUseError.invalidRequest
        XCTAssertEqual(error.errorDescription, "Failed to build computer use request")
    }

    func testComputerUseErrorInvalidResponseMessage() {
        let error = ComputerUseError.invalidResponse
        XCTAssertEqual(error.errorDescription, "Invalid response from Claude API")
    }

    func testComputerUseErrorAPIErrorMessageContainsDetail() {
        let error = ComputerUseError.apiError("HTTP 429")
        let description = error.errorDescription ?? ""
        XCTAssertTrue(description.contains("HTTP 429"), "API error description should contain the detail message")
    }

    func testComputerUseErrorExecutorErrorMessageContainsDetail() {
        let error = ComputerUseError.executorError("Screen capture unavailable")
        let description = error.errorDescription ?? ""
        XCTAssertTrue(description.contains("Screen capture unavailable"))
    }

    func testComputerUseErrorIsLocalizedError() {
        let error: Error = ComputerUseError.invalidRequest
        XCTAssertNotNil((error as? ComputerUseError)?.errorDescription)
    }

    // MARK: - ComputerUseService Initialization

    func testComputerUseServiceInitWithDefaultConfiguration() {
        let config = AIConfiguration(apiKey: "sk-ant-test", model: .claude35Sonnet)
        let aiService = AIService(configuration: config)
        let executor = StubComputerUseExecutor()
        let service = ComputerUseService(aiService: aiService, executor: executor)

        XCTAssertNotNil(service)
    }

    func testComputerUseServiceInitWithCustomConfiguration() {
        let aiConfig = AIConfiguration(apiKey: "sk-ant-test", model: .claude3Haiku)
        let aiService = AIService(configuration: aiConfig)
        let executor = StubComputerUseExecutor()
        let computerConfig = ComputerUseConfiguration(
            displayWidth: 1920,
            displayHeight: 1080,
            maxIterations: 5,
            screenshotDelay: 0.2
        )
        let service = ComputerUseService(
            aiService: aiService,
            executor: executor,
            configuration: computerConfig
        )

        XCTAssertNotNil(service)
    }

    // MARK: - ComputerUseConfiguration Boundary Values

    func testComputerUseConfigurationZeroMaxIterations() {
        // Zero maxIterations should be stored as-is (loop won't execute)
        let config = ComputerUseConfiguration(
            displayWidth: 100,
            displayHeight: 100,
            maxIterations: 0,
            screenshotDelay: 0.0
        )
        XCTAssertEqual(config.maxIterations, 0)
    }

    func testComputerUseConfigurationLargeDimensions() {
        let config = ComputerUseConfiguration(
            displayWidth: 3840,
            displayHeight: 2160,
            maxIterations: 100,
            screenshotDelay: 2.0
        )
        XCTAssertEqual(config.displayWidth, 3840)
        XCTAssertEqual(config.displayHeight, 2160)
    }
}

// MARK: - Test Helpers

/// Stub executor that returns fixed responses without network calls.
private class StubComputerUseExecutor: ComputerUseExecutor {
    var screenshotData: String = "stubScreenshotBase64"
    var actionError: String? = nil

    func takeScreenshot() async throws -> String {
        return screenshotData
    }

    func execute(action: ComputerUseAction) async throws -> ComputerUseResult {
        return ComputerUseResult(
            action: action,
            screenshotBase64: actionError == nil ? screenshotData : nil,
            error: actionError
        )
    }
}

/// Stub executor that throws on screenshot (simulates failure at start of runTask).
private class FailingScreenshotExecutor: ComputerUseExecutor {
    func takeScreenshot() async throws -> String {
        throw ComputerUseError.executorError("Screenshot failed")
    }

    func execute(action: ComputerUseAction) async throws -> ComputerUseResult {
        return ComputerUseResult(action: action)
    }
}