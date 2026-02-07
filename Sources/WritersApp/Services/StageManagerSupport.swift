import Foundation

// MARK: - Stage Manager Support

/// Provides Stage Manager support for iPad Pro running iPadOS 16+
public class StageManagerSupport {

    // MARK: - Properties

    public private(set) var isStageManagerEnabled: Bool = false
    public private(set) var isExternalDisplayConnected: Bool = false
    public private(set) var currentWindowGroup: WindowGroup?
    public private(set) var availableWindows: [WindowInfo] = []

    private var windowStateHandlers: [(WindowState) -> Void] = []

    // MARK: - Initialization

    public init() {}

    // MARK: - State Management

    /// Update Stage Manager state
    public func updateState(
        isEnabled: Bool,
        hasExternalDisplay: Bool,
        currentGroup: WindowGroup?,
        windows: [WindowInfo]
    ) {
        self.isStageManagerEnabled = isEnabled
        self.isExternalDisplayConnected = hasExternalDisplay
        self.currentWindowGroup = currentGroup
        self.availableWindows = windows
    }

    /// Check if Stage Manager features should be used
    public var shouldUseStageManagerFeatures: Bool {
        return isStageManagerEnabled
    }

    // MARK: - Window Management

    /// Get recommended window configuration
    public func getRecommendedWindowConfiguration() -> StageManagerWindowConfiguration {
        if isExternalDisplayConnected {
            return StageManagerWindowConfiguration(
                preferredSize: CGSize(width: 1280, height: 800),
                minimumSize: CGSize(width: 640, height: 480),
                resizingBehavior: .freeform,
                supportedOrientations: [.landscape, .portrait],
                allowsMultipleWindows: true,
                externalDisplayMode: .extend
            )
        } else {
            return StageManagerWindowConfiguration(
                preferredSize: CGSize(width: 1024, height: 768),
                minimumSize: CGSize(width: 320, height: 480),
                resizingBehavior: .freeform,
                supportedOrientations: [.landscape, .portrait],
                allowsMultipleWindows: true,
                externalDisplayMode: .mirror
            )
        }
    }

    /// Create a new window for a document
    public func requestNewWindow(for documentId: UUID, title: String) -> WindowRequest {
        WindowRequest(
            id: UUID(),
            documentId: documentId,
            title: title,
            preferredSize: CGSize(width: 800, height: 600),
            windowStyle: .document
        )
    }

    /// Get layout recommendations for current window configuration
    public func getLayoutRecommendations(windowSize: CGSize) -> StageManagerLayoutRecommendations {
        let isCompact = windowSize.width < 600
        let isNarrow = windowSize.width < 800

        return StageManagerLayoutRecommendations(
            showSidebar: !isCompact,
            sidebarStyle: isNarrow ? .overlay : .column,
            showToolbar: true,
            toolbarStyle: isCompact ? .compact : .full,
            showAIPanel: !isNarrow,
            aiPanelStyle: isNarrow ? .sheet : .sidebar,
            editorLayout: isCompact ? .centered : .fullWidth,
            navigationStyle: isCompact ? .stack : .splitView
        )
    }

    // MARK: - Window State Observers

    /// Register a handler for window state changes
    public func onWindowStateChange(_ handler: @escaping (WindowState) -> Void) {
        windowStateHandlers.append(handler)
    }

    /// Notify observers of window state change
    public func notifyWindowStateChange(_ state: WindowState) {
        for handler in windowStateHandlers {
            handler(state)
        }
    }

    // MARK: - Multi-Window Support

    /// Check if app can open new windows
    public var canOpenNewWindow: Bool {
        return isStageManagerEnabled && availableWindows.count < 8
    }

    /// Get information about windows in the current group
    public func getWindowsInCurrentGroup() -> [WindowInfo] {
        guard let group = currentWindowGroup else { return [] }
        return availableWindows.filter { $0.groupId == group.id }
    }

    /// Calculate optimal positions for multiple windows
    public func calculateWindowPositions(
        count: Int,
        screenSize: CGSize
    ) -> [CGRect] {
        // Validate input
        guard count > 0 else {
            return []
        }

        let windowCount = min(count, 10)
        var positions: [CGRect] = []

        switch windowCount {
        case 1:
            // Single window, centered
            let width = min(screenSize.width * 0.8, 1200)
            let height = min(screenSize.height * 0.85, 900)
            positions.append(CGRect(
                x: (screenSize.width - width) / 2,
                y: (screenSize.height - height) / 2,
                width: width,
                height: height
            ))

        case 2:
            // Two windows side by side
            let width = screenSize.width * 0.48
            let height = screenSize.height * 0.85
            let gap: Double = 16
            positions.append(CGRect(
                x: (screenSize.width - (width * 2 + gap)) / 2,
                y: (screenSize.height - height) / 2,
                width: width,
                height: height
            ))
            positions.append(CGRect(
                x: (screenSize.width - (width * 2 + gap)) / 2 + width + gap,
                y: (screenSize.height - height) / 2,
                width: width,
                height: height
            ))

        case 3:
            // One large, two smaller stacked
            let mainWidth = screenSize.width * 0.55
            let sideWidth = screenSize.width * 0.4
            let height = screenSize.height * 0.85
            let smallHeight = (height - 16) / 2
            let gap: Double = 16

            positions.append(CGRect(
                x: gap,
                y: (screenSize.height - height) / 2,
                width: mainWidth,
                height: height
            ))
            positions.append(CGRect(
                x: mainWidth + gap * 2,
                y: (screenSize.height - height) / 2,
                width: sideWidth - gap * 2,
                height: smallHeight
            ))
            positions.append(CGRect(
                x: mainWidth + gap * 2,
                y: (screenSize.height - height) / 2 + smallHeight + gap,
                width: sideWidth - gap * 2,
                height: smallHeight
            ))

        default:
            // Grid layout for 4+ windows
            let cols = Int(ceil(sqrt(Double(count))))
            let rows = Int(ceil(Double(count) / Double(cols)))
            let gap: Double = 12
            let cellWidth = (screenSize.width - gap * Double(cols + 1)) / Double(cols)
            let cellHeight = (screenSize.height - gap * Double(rows + 1)) / Double(rows)

            for i in 0..<count {
                let col = i % cols
                let row = i / cols
                positions.append(CGRect(
                    x: gap + Double(col) * (cellWidth + gap),
                    y: gap + Double(row) * (cellHeight + gap),
                    width: cellWidth,
                    height: cellHeight
                ))
            }
        }

        return positions
    }

    // MARK: - External Display Support

    /// Get configuration for external display
    public func getExternalDisplayConfiguration() -> ExternalDisplayConfiguration {
        ExternalDisplayConfiguration(
            displayMode: isExternalDisplayConnected ? .extend : .none,
            resolution: .native,
            scaling: .default,
            contentPlacement: .centered,
            showDockOnExternal: false
        )
    }

    /// Determine which content should appear on external display
    public func getExternalDisplayContent() -> ExternalDisplayContent {
        if isExternalDisplayConnected {
            return .fullEditor // Show full editor on external display
        }
        return .none
    }
}

// MARK: - Window Configuration

/// Configuration for Stage Manager windows
public struct StageManagerWindowConfiguration: Codable {
    public let preferredSize: CGSize
    public let minimumSize: CGSize
    public let resizingBehavior: ResizingBehavior
    public let supportedOrientations: [WindowOrientation]
    public let allowsMultipleWindows: Bool
    public let externalDisplayMode: ExternalDisplayMode

    public init(
        preferredSize: CGSize,
        minimumSize: CGSize,
        resizingBehavior: ResizingBehavior,
        supportedOrientations: [WindowOrientation],
        allowsMultipleWindows: Bool,
        externalDisplayMode: ExternalDisplayMode
    ) {
        self.preferredSize = preferredSize
        self.minimumSize = minimumSize
        self.resizingBehavior = resizingBehavior
        self.supportedOrientations = supportedOrientations
        self.allowsMultipleWindows = allowsMultipleWindows
        self.externalDisplayMode = externalDisplayMode
    }
}

/// Window resizing behavior
public enum ResizingBehavior: String, Codable {
    case fixed
    case uniform
    case freeform
}

/// Window orientations
public enum WindowOrientation: String, Codable {
    case portrait
    case landscape
    case any
}

/// External display modes
public enum ExternalDisplayMode: String, Codable {
    case none
    case mirror
    case extend
}

// MARK: - Window Info

/// Information about an open window
public struct WindowInfo: Codable, Identifiable {
    public let id: UUID
    public let documentId: UUID?
    public let title: String
    public let groupId: UUID?
    public var frame: CGRect
    public var isActive: Bool
    public var isMinimized: Bool

    public init(
        id: UUID = UUID(),
        documentId: UUID?,
        title: String,
        groupId: UUID?,
        frame: CGRect,
        isActive: Bool = false,
        isMinimized: Bool = false
    ) {
        self.id = id
        self.documentId = documentId
        self.title = title
        self.groupId = groupId
        self.frame = frame
        self.isActive = isActive
        self.isMinimized = isMinimized
    }
}

// MARK: - Window Group

/// Represents a Stage Manager window group
public struct WindowGroup: Codable, Identifiable {
    public let id: UUID
    public var name: String
    public var windowIds: [UUID]
    public var isActive: Bool

    public init(
        id: UUID = UUID(),
        name: String = "Group",
        windowIds: [UUID] = [],
        isActive: Bool = false
    ) {
        self.id = id
        self.name = name
        self.windowIds = windowIds
        self.isActive = isActive
    }
}

// MARK: - Window Request

/// Request to open a new window
public struct WindowRequest {
    public let id: UUID
    public let documentId: UUID
    public let title: String
    public let preferredSize: CGSize
    public let windowStyle: WindowDocumentStyle

    public init(
        id: UUID = UUID(),
        documentId: UUID,
        title: String,
        preferredSize: CGSize,
        windowStyle: WindowDocumentStyle
    ) {
        self.id = id
        self.documentId = documentId
        self.title = title
        self.preferredSize = preferredSize
        self.windowStyle = windowStyle
    }
}

/// Window document styles
public enum WindowDocumentStyle: String, Codable {
    case document
    case auxiliary
    case settings
}

// MARK: - Window State

/// Current state of a window
public struct WindowState {
    public let windowId: UUID
    public let isActive: Bool
    public let isFullScreen: Bool
    public let frame: CGRect
    public let displayId: Int

    public init(
        windowId: UUID,
        isActive: Bool,
        isFullScreen: Bool,
        frame: CGRect,
        displayId: Int
    ) {
        self.windowId = windowId
        self.isActive = isActive
        self.isFullScreen = isFullScreen
        self.frame = frame
        self.displayId = displayId
    }
}

// MARK: - Layout Recommendations

/// Layout recommendations for Stage Manager
public struct StageManagerLayoutRecommendations {
    public let showSidebar: Bool
    public let sidebarStyle: SidebarPresentationStyle
    public let showToolbar: Bool
    public let toolbarStyle: ToolbarPresentationStyle
    public let showAIPanel: Bool
    public let aiPanelStyle: AIPanelPresentationStyle
    public let editorLayout: EditorLayoutStyle
    public let navigationStyle: NavigationPresentationStyle

    public init(
        showSidebar: Bool,
        sidebarStyle: SidebarPresentationStyle,
        showToolbar: Bool,
        toolbarStyle: ToolbarPresentationStyle,
        showAIPanel: Bool,
        aiPanelStyle: AIPanelPresentationStyle,
        editorLayout: EditorLayoutStyle,
        navigationStyle: NavigationPresentationStyle
    ) {
        self.showSidebar = showSidebar
        self.sidebarStyle = sidebarStyle
        self.showToolbar = showToolbar
        self.toolbarStyle = toolbarStyle
        self.showAIPanel = showAIPanel
        self.aiPanelStyle = aiPanelStyle
        self.editorLayout = editorLayout
        self.navigationStyle = navigationStyle
    }
}

/// Sidebar presentation styles
public enum SidebarPresentationStyle: String, Codable {
    case column
    case overlay
    case hidden
}

/// Toolbar presentation styles
public enum ToolbarPresentationStyle: String, Codable {
    case full
    case compact
    case hidden
}

/// AI panel presentation styles
public enum AIPanelPresentationStyle: String, Codable {
    case sidebar
    case sheet
    case popover
    case hidden
}

/// Editor layout styles
public enum EditorLayoutStyle: String, Codable {
    case fullWidth
    case centered
    case compact
}

/// Navigation presentation styles
public enum NavigationPresentationStyle: String, Codable {
    case splitView
    case stack
    case tabs
}

// MARK: - External Display Configuration

/// Configuration for external display support
public struct ExternalDisplayConfiguration: Codable {
    public let displayMode: ExternalDisplayMode
    public let resolution: DisplayResolution
    public let scaling: DisplayScaling
    public let contentPlacement: ContentPlacement
    public let showDockOnExternal: Bool

    public init(
        displayMode: ExternalDisplayMode,
        resolution: DisplayResolution,
        scaling: DisplayScaling,
        contentPlacement: ContentPlacement,
        showDockOnExternal: Bool
    ) {
        self.displayMode = displayMode
        self.resolution = resolution
        self.scaling = scaling
        self.contentPlacement = contentPlacement
        self.showDockOnExternal = showDockOnExternal
    }
}

/// Display resolution options
public enum DisplayResolution: String, Codable {
    case native
    case scaled
    case lowPower
}

/// Display scaling options
public enum DisplayScaling: String, Codable {
    case `default`
    case moreSpace
    case larger
}

/// Content placement on external display
public enum ContentPlacement: String, Codable {
    case centered
    case fill
    case fit
}

/// Content types for external display
public enum ExternalDisplayContent: String, Codable {
    case none
    case fullEditor
    case preview
    case outline
    case reference
}
