import XCTest
@testable import WritersApp

final class iPadProFeaturesTests: XCTestCase {

    // MARK: - iPad Pro Configuration Tests

    func testDefaultiPadProConfiguration() {
        let config = iPadProConfiguration()

        XCTAssertEqual(config.displayMode, .adaptive)
        XCTAssertEqual(config.multitaskingMode, .fullScreen)
        XCTAssertTrue(config.keyboardShortcutsEnabled)
        XCTAssertTrue(config.applePencilEnabled)
        XCTAssertTrue(config.stageManagerEnabled)
        XCTAssertTrue(config.proMotionEnabled)
        XCTAssertTrue(config.hapticFeedbackEnabled)
    }

    func testDisplayModeProperties() {
        XCTAssertEqual(iPadDisplayMode.compact.displayName, "Compact")
        XCTAssertEqual(iPadDisplayMode.regular.displayName, "Regular")
        XCTAssertEqual(iPadDisplayMode.adaptive.displayName, "Adaptive")
        XCTAssertEqual(iPadDisplayMode.focusMode.displayName, "Focus Mode")
    }

    func testMultitaskingModeProperties() {
        XCTAssertTrue(MultitaskingMode.fullScreen.showSidebar)
        XCTAssertTrue(MultitaskingMode.fullScreen.showAIPanel)
        XCTAssertFalse(MultitaskingMode.slideOver.showSidebar)
        XCTAssertFalse(MultitaskingMode.slideOver.showAIPanel)
    }

    func testiPadProScreenSizes() {
        let iPadPro11 = iPadProModel.iPadPro11.screenSize
        let iPadPro13 = iPadProModel.iPadPro13.screenSize
        let iPadProM4_13 = iPadProModel.iPadProM4_13.screenSize

        XCTAssertEqual(iPadPro11.ppi, 264)
        XCTAssertTrue(iPadPro11.supportsProMotion)
        XCTAssertTrue(iPadPro11.supportsFaceID)

        XCTAssertGreaterThan(iPadPro13.width, iPadPro11.width)
        XCTAssertEqual(iPadProM4_13.supportsApplePencil, .pro)
    }

    func testEditorLayoutConfiguration() {
        let defaultLayout = EditorLayoutConfiguration()

        XCTAssertEqual(defaultLayout.sidebarWidth, 280)
        XCTAssertEqual(defaultLayout.aiPanelWidth, 320)
        XCTAssertTrue(defaultLayout.showWordCount)
        XCTAssertTrue(defaultLayout.showReadingTime)

        let focusModeLayout = EditorLayoutConfiguration.focusMode
        XCTAssertEqual(focusModeLayout.sidebarWidth, 0)
        XCTAssertEqual(focusModeLayout.aiPanelWidth, 0)
        XCTAssertFalse(focusModeLayout.showWordCount)
    }

    func testWritingSession() {
        var session = WritingSession(
            documentId: UUID(),
            wordsWritten: 500,
            wordsDeleted: 100
        )

        XCTAssertEqual(session.netWordsAdded, 400)
        XCTAssertNil(session.endTime)

        session.endTime = Date()
        XCTAssertNotNil(session.duration)
    }

    func testGestureConfiguration() {
        let config = GestureConfiguration()

        XCTAssertEqual(config.twoFingerTapAction, .showAIMenu)
        XCTAssertEqual(config.threeFingerTapAction, .toggleFocusMode)
        XCTAssertEqual(config.pinchAction, .adjustFontSize)
    }

    // MARK: - Keyboard Shortcut Tests

    func testKeyboardShortcutManagerInitialization() {
        let manager = KeyboardShortcutManager()
        let shortcuts = manager.getAllShortcuts()

        XCTAssertGreaterThan(shortcuts.count, 0)
    }

    func testFindShortcut() {
        let manager = KeyboardShortcutManager()

        // Test Command+S for save
        let saveShortcut = manager.findShortcut(key: "s", modifiers: [.command])
        XCTAssertNotNil(saveShortcut)
        XCTAssertEqual(saveShortcut?.action, .save)

        // Test Command+B for bold
        let boldShortcut = manager.findShortcut(key: "b", modifiers: [.command])
        XCTAssertNotNil(boldShortcut)
        XCTAssertEqual(boldShortcut?.action, .bold)
    }

    func testShortcutCategories() {
        let manager = KeyboardShortcutManager()

        let fileShortcuts = manager.getShortcuts(for: .file)
        let aiShortcuts = manager.getShortcuts(for: .ai)

        XCTAssertGreaterThan(fileShortcuts.count, 0)
        XCTAssertGreaterThan(aiShortcuts.count, 0)
    }

    func testAddCustomShortcut() {
        let manager = KeyboardShortcutManager()
        let initialCount = manager.getAllShortcuts().count

        let customShortcut = KeyboardShortcut(
            action: .save,
            key: "w",
            modifiers: [.command, .shift],
            category: .file,
            description: "Custom save shortcut"
        )

        manager.addCustomShortcut(customShortcut)
        XCTAssertEqual(manager.getAllShortcuts().count, initialCount + 1)
    }

    func testFormatShortcut() {
        let manager = KeyboardShortcutManager()

        let shortcut = KeyboardShortcut(
            action: .save,
            key: "s",
            modifiers: [.command, .shift],
            category: .file,
            description: "Test"
        )

        let formatted = manager.formatShortcut(shortcut)
        XCTAssertTrue(formatted.contains("⌘"))
        XCTAssertTrue(formatted.contains("⇧"))
        XCTAssertTrue(formatted.contains("S"))
    }

    func testResetToDefaults() {
        let manager = KeyboardShortcutManager()
        let initialCount = manager.getAllShortcuts().count

        // Add custom shortcut
        let customShortcut = KeyboardShortcut(
            action: .save,
            key: "w",
            modifiers: [.command, .shift],
            category: .file,
            description: "Custom"
        )
        manager.addCustomShortcut(customShortcut)

        // Reset
        manager.resetToDefaults()
        XCTAssertEqual(manager.getAllShortcuts().count, initialCount)
    }

    // MARK: - Multitasking Manager Tests

    func testMultitaskingManagerStateUpdate() {
        let manager = MultitaskingManager()

        // Test full screen detection
        manager.updateState(availableWidth: 1200, availableHeight: 800)
        XCTAssertEqual(manager.currentMode, .fullScreen)

        // Test Split View detection
        manager.updateState(availableWidth: 600, availableHeight: 800)
        XCTAssertEqual(manager.currentMode, .splitViewPrimary)

        // Test Slide Over detection
        manager.updateState(availableWidth: 300, availableHeight: 800)
        XCTAssertEqual(manager.currentMode, .slideOver)
    }

    func testLayoutRecommendations() {
        let manager = MultitaskingManager()

        manager.updateState(availableWidth: 1200, availableHeight: 800)
        let fullScreenLayout = manager.getRecommendedLayout()
        XCTAssertTrue(fullScreenLayout.showSidebar)
        XCTAssertTrue(fullScreenLayout.showAIPanel)

        manager.updateState(availableWidth: 300, availableHeight: 800)
        let slideOverLayout = manager.getRecommendedLayout()
        XCTAssertFalse(slideOverLayout.showSidebar)
        XCTAssertFalse(slideOverLayout.showAIPanel)
    }

    func testFontSizeRecommendations() {
        let manager = MultitaskingManager()

        manager.updateState(availableWidth: 1200, availableHeight: 800)
        let largeFonts = manager.getRecommendedFontSizes()

        manager.updateState(availableWidth: 300, availableHeight: 800)
        let smallFonts = manager.getRecommendedFontSizes()

        XCTAssertGreaterThan(largeFonts.body, smallFonts.body)
    }

    func testStageManagerMode() {
        let manager = MultitaskingManager()

        manager.updateState(availableWidth: 800, availableHeight: 600, isStageManager: true)
        XCTAssertEqual(manager.currentMode, .stageManager)
    }

    // MARK: - Apple Pencil Manager Tests

    func testApplePencilConfiguration() {
        let config = PencilConfiguration()

        XCTAssertEqual(config.doubleTapAction, .switchTool)
        XCTAssertEqual(config.squeezeAction, .showToolPicker)
        XCTAssertEqual(config.currentTool, .pen)
        XCTAssertTrue(config.scribbleEnabled)
    }

    func testPencilToolProperties() {
        XCTAssertEqual(PencilTool.pen.defaultStrokeWidth, 2.0)
        XCTAssertEqual(PencilTool.highlighter.defaultStrokeWidth, 20.0)
        XCTAssertTrue(PencilTool.pen.supportsPressure)
        XCTAssertFalse(PencilTool.highlighter.supportsPressure)
        XCTAssertTrue(PencilTool.pencil.supportsTilt)
    }

    func testPencilStroke() {
        let points = [
            PencilPoint(x: 0, y: 0, pressure: 0.5),
            PencilPoint(x: 10, y: 10, pressure: 0.6),
            PencilPoint(x: 20, y: 5, pressure: 0.7)
        ]

        let stroke = PencilStroke(
            startTime: Date(),
            endTime: Date(),
            points: points,
            tool: .pen
        )

        XCTAssertEqual(stroke.points.count, 3)
        XCTAssertEqual(stroke.averagePressure, 0.6, accuracy: 0.001)

        let boundingBox = stroke.boundingBox
        XCTAssertEqual(boundingBox.minX, 0)
        XCTAssertEqual(boundingBox.maxX, 20)
        XCTAssertEqual(boundingBox.minY, 0)
        XCTAssertEqual(boundingBox.maxY, 10)
    }

    func testApplePencilManagerStrokeHandling() {
        let manager = ApplePencilManager()

        manager.beginStroke(at: PencilPoint(x: 0, y: 0))
        manager.addPoint(PencilPoint(x: 5, y: 5))
        manager.addPoint(PencilPoint(x: 10, y: 10))

        let stroke = manager.endStroke()
        XCTAssertNotNil(stroke)
        XCTAssertEqual(stroke?.points.count, 3)
    }

    func testApplePencilGenerationCapabilities() {
        XCTAssertFalse(ApplePencilGeneration.firstGeneration.supportsDoubleTap)
        XCTAssertTrue(ApplePencilGeneration.secondGeneration.supportsDoubleTap)
        XCTAssertTrue(ApplePencilGeneration.pro.supportsSqueeze)
        XCTAssertTrue(ApplePencilGeneration.pro.supportsHapticFeedback)
        XCTAssertFalse(ApplePencilGeneration.secondGeneration.supportsSqueeze)
    }

    // MARK: - Stage Manager Support Tests

    func testStageManagerWindowConfiguration() {
        let support = StageManagerSupport()

        let config = support.getRecommendedWindowConfiguration()
        XCTAssertTrue(config.allowsMultipleWindows)
        XCTAssertEqual(config.resizingBehavior, .freeform)
    }

    func testStageManagerLayoutRecommendations() {
        let support = StageManagerSupport()

        let wideLayout = support.getLayoutRecommendations(windowSize: CGSize(width: 1200, height: 800))
        XCTAssertTrue(wideLayout.showSidebar)
        XCTAssertTrue(wideLayout.showAIPanel)

        let narrowLayout = support.getLayoutRecommendations(windowSize: CGSize(width: 500, height: 800))
        XCTAssertFalse(narrowLayout.showSidebar)
    }

    func testWindowPositionCalculation() {
        let support = StageManagerSupport()
        let screenSize = CGSize(width: 1920, height: 1080)

        let singleWindow = support.calculateWindowPositions(count: 1, screenSize: screenSize)
        XCTAssertEqual(singleWindow.count, 1)

        let twoWindows = support.calculateWindowPositions(count: 2, screenSize: screenSize)
        XCTAssertEqual(twoWindows.count, 2)

        let threeWindows = support.calculateWindowPositions(count: 3, screenSize: screenSize)
        XCTAssertEqual(threeWindows.count, 3)
    }

    func testWindowRequest() {
        let support = StageManagerSupport()
        let documentId = UUID()

        let request = support.requestNewWindow(for: documentId, title: "Test Document")
        XCTAssertEqual(request.documentId, documentId)
        XCTAssertEqual(request.title, "Test Document")
        XCTAssertEqual(request.windowStyle, .document)
    }

    // MARK: - Codable Tests

    func testConfigurationCodable() throws {
        let config = iPadProConfiguration(
            displayMode: .focusMode,
            multitaskingMode: .stageManager,
            keyboardShortcutsEnabled: false
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(config)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(iPadProConfiguration.self, from: data)

        XCTAssertEqual(decoded.displayMode, .focusMode)
        XCTAssertEqual(decoded.multitaskingMode, .stageManager)
        XCTAssertFalse(decoded.keyboardShortcutsEnabled)
    }

    func testPencilStrokeCodable() throws {
        let points = [
            PencilPoint(x: 0, y: 0, pressure: 0.5),
            PencilPoint(x: 10, y: 10, pressure: 0.8)
        ]

        let stroke = PencilStroke(
            startTime: Date(),
            endTime: Date(),
            points: points,
            tool: .pencil
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(stroke)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PencilStroke.self, from: data)

        XCTAssertEqual(decoded.points.count, 2)
        XCTAssertEqual(decoded.tool, .pencil)
    }

    func testShortcutConfigurationExportImport() throws {
        let manager = KeyboardShortcutManager()

        guard let exportedData = manager.exportConfiguration() else {
            XCTFail("Failed to export configuration")
            return
        }

        let newManager = KeyboardShortcutManager()
        let success = newManager.importConfiguration(from: exportedData)

        XCTAssertTrue(success)
        XCTAssertEqual(newManager.getAllShortcuts().count, manager.getAllShortcuts().count)
    }
}
