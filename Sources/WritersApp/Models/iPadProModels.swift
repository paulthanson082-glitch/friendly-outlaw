import Foundation

// MARK: - iPad Pro Configuration

/// Configuration for iPad Pro-specific features
public struct iPadProConfiguration: Codable {
    public var displayMode: iPadDisplayMode
    public var multitaskingMode: MultitaskingMode
    public var keyboardShortcutsEnabled: Bool
    public var applePencilEnabled: Bool
    public var stageManagerEnabled: Bool
    public var proMotionEnabled: Bool
    public var hapticFeedbackEnabled: Bool

    public init(
        displayMode: iPadDisplayMode = .adaptive,
        multitaskingMode: MultitaskingMode = .fullScreen,
        keyboardShortcutsEnabled: Bool = true,
        applePencilEnabled: Bool = true,
        stageManagerEnabled: Bool = true,
        proMotionEnabled: Bool = true,
        hapticFeedbackEnabled: Bool = true
    ) {
        self.displayMode = displayMode
        self.multitaskingMode = multitaskingMode
        self.keyboardShortcutsEnabled = keyboardShortcutsEnabled
        self.applePencilEnabled = applePencilEnabled
        self.stageManagerEnabled = stageManagerEnabled
        self.proMotionEnabled = proMotionEnabled
        self.hapticFeedbackEnabled = hapticFeedbackEnabled
    }
}

// MARK: - Display Modes

/// Display modes for iPad Pro
public enum iPadDisplayMode: String, Codable, CaseIterable {
    case compact
    case regular
    case adaptive
    case focusMode

    public var displayName: String {
        switch self {
        case .compact: return "Compact"
        case .regular: return "Regular"
        case .adaptive: return "Adaptive"
        case .focusMode: return "Focus Mode"
        }
    }

    public var description: String {
        switch self {
        case .compact: return "Optimized for smaller screen areas and Split View"
        case .regular: return "Full-featured layout for maximum screen real estate"
        case .adaptive: return "Automatically adjusts based on available space"
        case .focusMode: return "Distraction-free writing with minimal UI"
        }
    }
}

// MARK: - Multitasking Modes

/// Multitasking modes for iPad Pro
public enum MultitaskingMode: String, Codable, CaseIterable {
    case fullScreen
    case splitViewPrimary
    case splitViewSecondary
    case slideOver
    case stageManager

    public var displayName: String {
        switch self {
        case .fullScreen: return "Full Screen"
        case .splitViewPrimary: return "Split View (Primary)"
        case .splitViewSecondary: return "Split View (Secondary)"
        case .slideOver: return "Slide Over"
        case .stageManager: return "Stage Manager"
        }
    }

    /// Recommended sidebar visibility for each mode
    public var showSidebar: Bool {
        switch self {
        case .fullScreen, .stageManager: return true
        case .splitViewPrimary: return true
        case .splitViewSecondary, .slideOver: return false
        }
    }

    /// Recommended AI panel visibility for each mode
    public var showAIPanel: Bool {
        switch self {
        case .fullScreen, .stageManager, .splitViewPrimary: return true
        case .splitViewSecondary, .slideOver: return false
        }
    }
}

// MARK: - iPad Pro Screen Sizes

/// iPad Pro screen size configurations
public struct iPadProScreenSize: Codable {
    public let model: iPadProModel
    public let width: Double
    public let height: Double
    public let ppi: Int
    public let supportsProMotion: Bool
    public let supportsApplePencil: ApplePencilGeneration
    public let supportsFaceID: Bool

    public init(
        model: iPadProModel,
        width: Double,
        height: Double,
        ppi: Int,
        supportsProMotion: Bool,
        supportsApplePencil: ApplePencilGeneration,
        supportsFaceID: Bool
    ) {
        self.model = model
        self.width = width
        self.height = height
        self.ppi = ppi
        self.supportsProMotion = supportsProMotion
        self.supportsApplePencil = supportsApplePencil
        self.supportsFaceID = supportsFaceID
    }

    /// Diagonal screen size in inches
    public var diagonalInches: Double {
        return sqrt(width * width + height * height)
    }

    /// Optimal font size for this screen
    public var recommendedBodyFontSize: Double {
        switch model {
        case .iPadPro11: return 17
        case .iPadPro13: return 18
        case .iPadProM4_11, .iPadProM4_13: return 18
        }
    }

    /// Optimal editor width in points
    public var recommendedEditorWidth: Double {
        switch model {
        case .iPadPro11, .iPadProM4_11: return 680
        case .iPadPro13, .iPadProM4_13: return 780
        }
    }
}

/// iPad Pro model variants
public enum iPadProModel: String, Codable, CaseIterable {
    case iPadPro11 = "iPad Pro 11-inch"
    case iPadPro13 = "iPad Pro 12.9-inch"
    case iPadProM4_11 = "iPad Pro 11-inch (M4)"
    case iPadProM4_13 = "iPad Pro 13-inch (M4)"

    public var displayName: String { rawValue }

    /// Get the screen size configuration for this model
    public var screenSize: iPadProScreenSize {
        switch self {
        case .iPadPro11:
            return iPadProScreenSize(
                model: self,
                width: 8.46, height: 5.80,
                ppi: 264,
                supportsProMotion: true,
                supportsApplePencil: .secondGeneration,
                supportsFaceID: true
            )
        case .iPadPro13:
            return iPadProScreenSize(
                model: self,
                width: 10.32, height: 7.74,
                ppi: 264,
                supportsProMotion: true,
                supportsApplePencil: .secondGeneration,
                supportsFaceID: true
            )
        case .iPadProM4_11:
            return iPadProScreenSize(
                model: self,
                width: 8.46, height: 5.80,
                ppi: 264,
                supportsProMotion: true,
                supportsApplePencil: .pro,
                supportsFaceID: true
            )
        case .iPadProM4_13:
            return iPadProScreenSize(
                model: self,
                width: 11.09, height: 8.32,
                ppi: 264,
                supportsProMotion: true,
                supportsApplePencil: .pro,
                supportsFaceID: true
            )
        }
    }
}

// MARK: - Apple Pencil Support

/// Apple Pencil generations
public enum ApplePencilGeneration: String, Codable {
    case firstGeneration = "Apple Pencil (1st generation)"
    case secondGeneration = "Apple Pencil (2nd generation)"
    case pro = "Apple Pencil Pro"

    public var displayName: String { rawValue }

    public var supportsPressureSensitivity: Bool { true }
    public var supportsTiltSensitivity: Bool { true }

    public var supportsDoubleTap: Bool {
        switch self {
        case .firstGeneration: return false
        case .secondGeneration, .pro: return true
        }
    }

    public var supportsSqueeze: Bool {
        switch self {
        case .firstGeneration, .secondGeneration: return false
        case .pro: return true
        }
    }

    public var supportsBarrelRoll: Bool {
        switch self {
        case .firstGeneration, .secondGeneration: return false
        case .pro: return true
        }
    }

    public var supportsHapticFeedback: Bool {
        switch self {
        case .firstGeneration, .secondGeneration: return false
        case .pro: return true
        }
    }
}

// MARK: - Editor Layout Configuration

/// Layout configuration for the document editor on iPad Pro
public struct EditorLayoutConfiguration: Codable {
    public var sidebarWidth: Double
    public var aiPanelWidth: Double
    public var editorPadding: EdgeInsets
    public var lineSpacing: Double
    public var paragraphSpacing: Double
    public var showLineNumbers: Bool
    public var showWordCount: Bool
    public var showReadingTime: Bool

    public init(
        sidebarWidth: Double = 280,
        aiPanelWidth: Double = 320,
        editorPadding: EdgeInsets = EdgeInsets(top: 20, leading: 40, bottom: 20, trailing: 40),
        lineSpacing: Double = 1.5,
        paragraphSpacing: Double = 12,
        showLineNumbers: Bool = false,
        showWordCount: Bool = true,
        showReadingTime: Bool = true
    ) {
        self.sidebarWidth = sidebarWidth
        self.aiPanelWidth = aiPanelWidth
        self.editorPadding = editorPadding
        self.lineSpacing = lineSpacing
        self.paragraphSpacing = paragraphSpacing
        self.showLineNumbers = showLineNumbers
        self.showWordCount = showWordCount
        self.showReadingTime = showReadingTime
    }

    /// Optimized configuration for Split View
    public static var splitView: EditorLayoutConfiguration {
        EditorLayoutConfiguration(
            sidebarWidth: 200,
            aiPanelWidth: 0,
            editorPadding: EdgeInsets(top: 16, leading: 24, bottom: 16, trailing: 24),
            lineSpacing: 1.4,
            paragraphSpacing: 10,
            showLineNumbers: false,
            showWordCount: true,
            showReadingTime: false
        )
    }

    /// Optimized configuration for Focus Mode
    public static var focusMode: EditorLayoutConfiguration {
        EditorLayoutConfiguration(
            sidebarWidth: 0,
            aiPanelWidth: 0,
            editorPadding: EdgeInsets(top: 60, leading: 80, bottom: 60, trailing: 80),
            lineSpacing: 1.8,
            paragraphSpacing: 16,
            showLineNumbers: false,
            showWordCount: false,
            showReadingTime: false
        )
    }
}

/// Edge insets for layout
public struct EdgeInsets: Codable {
    public var top: Double
    public var leading: Double
    public var bottom: Double
    public var trailing: Double

    public init(top: Double, leading: Double, bottom: Double, trailing: Double) {
        self.top = top
        self.leading = leading
        self.bottom = bottom
        self.trailing = trailing
    }

    public static var zero: EdgeInsets {
        EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
    }
}

// MARK: - Writing Session

/// Tracks a writing session on iPad Pro
public struct WritingSession: Codable, Identifiable {
    public let id: UUID
    public let documentId: UUID
    public let startTime: Date
    public var endTime: Date?
    public var wordsWritten: Int
    public var wordsDeleted: Int
    public var aiAssistanceUsed: [AIAssistanceRecord]
    public var pencilInteractions: Int
    public var keyboardShortcutsUsed: Int

    public init(
        id: UUID = UUID(),
        documentId: UUID,
        startTime: Date = Date(),
        endTime: Date? = nil,
        wordsWritten: Int = 0,
        wordsDeleted: Int = 0,
        aiAssistanceUsed: [AIAssistanceRecord] = [],
        pencilInteractions: Int = 0,
        keyboardShortcutsUsed: Int = 0
    ) {
        self.id = id
        self.documentId = documentId
        self.startTime = startTime
        self.endTime = endTime
        self.wordsWritten = wordsWritten
        self.wordsDeleted = wordsDeleted
        self.aiAssistanceUsed = aiAssistanceUsed
        self.pencilInteractions = pencilInteractions
        self.keyboardShortcutsUsed = keyboardShortcutsUsed
    }

    /// Session duration in seconds
    public var duration: TimeInterval {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime)
    }

    /// Net words added during session
    public var netWordsAdded: Int {
        return wordsWritten - wordsDeleted
    }

    /// Words per minute during session
    public var wordsPerMinute: Double {
        let minutes = duration / 60
        return minutes > 0 ? Double(wordsWritten) / minutes : 0
    }
}

/// Record of AI assistance usage
public struct AIAssistanceRecord: Codable {
    public let timestamp: Date
    public let assistanceType: String
    public let inputLength: Int
    public let outputLength: Int

    public init(
        timestamp: Date = Date(),
        assistanceType: String,
        inputLength: Int,
        outputLength: Int
    ) {
        self.timestamp = timestamp
        self.assistanceType = assistanceType
        self.inputLength = inputLength
        self.outputLength = outputLength
    }
}

// MARK: - Gesture Configuration

/// Configuration for gesture support on iPad Pro
public struct GestureConfiguration: Codable {
    public var twoFingerTapAction: GestureAction
    public var threeFingerTapAction: GestureAction
    public var pinchAction: GestureAction
    public var swipeLeftAction: GestureAction
    public var swipeRightAction: GestureAction
    public var longPressAction: GestureAction

    public init(
        twoFingerTapAction: GestureAction = .showAIMenu,
        threeFingerTapAction: GestureAction = .toggleFocusMode,
        pinchAction: GestureAction = .adjustFontSize,
        swipeLeftAction: GestureAction = .showAIPanel,
        swipeRightAction: GestureAction = .showDocumentList,
        longPressAction: GestureAction = .showContextMenu
    ) {
        self.twoFingerTapAction = twoFingerTapAction
        self.threeFingerTapAction = threeFingerTapAction
        self.pinchAction = pinchAction
        self.swipeLeftAction = swipeLeftAction
        self.swipeRightAction = swipeRightAction
        self.longPressAction = longPressAction
    }
}

/// Actions that can be triggered by gestures
public enum GestureAction: String, Codable, CaseIterable {
    case none
    case showAIMenu
    case showAIPanel
    case hideAIPanel
    case toggleFocusMode
    case showDocumentList
    case showTemplates
    case showContextMenu
    case adjustFontSize
    case undo
    case redo
    case save
    case export

    public var displayName: String {
        switch self {
        case .none: return "None"
        case .showAIMenu: return "Show AI Menu"
        case .showAIPanel: return "Show AI Panel"
        case .hideAIPanel: return "Hide AI Panel"
        case .toggleFocusMode: return "Toggle Focus Mode"
        case .showDocumentList: return "Show Documents"
        case .showTemplates: return "Show Templates"
        case .showContextMenu: return "Show Context Menu"
        case .adjustFontSize: return "Adjust Font Size"
        case .undo: return "Undo"
        case .redo: return "Redo"
        case .save: return "Save"
        case .export: return "Export"
        }
    }
}
