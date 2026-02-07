import Foundation

// MARK: - Multitasking Manager

/// Manages iPad Pro multitasking features including Split View, Slide Over, and Stage Manager
public class MultitaskingManager {

    // MARK: - Properties

    public private(set) var currentMode: MultitaskingMode = .fullScreen
    public private(set) var sizeClass: SizeClass = .regular
    public private(set) var availableWidth: Double = 0
    public private(set) var availableHeight: Double = 0
    public private(set) var isStageManagerEnabled: Bool = false

    private var modeChangeHandlers: [(MultitaskingMode) -> Void] = []
    private var sizeClassChangeHandlers: [(SizeClass) -> Void] = []

    // MARK: - Initialization

    public init() {}

    // MARK: - Mode Detection

    /// Update the current multitasking state based on available dimensions
    public func updateState(
        availableWidth: Double,
        availableHeight: Double,
        isStageManager: Bool = false
    ) {
        self.availableWidth = availableWidth
        self.availableHeight = availableHeight
        self.isStageManagerEnabled = isStageManager

        // Determine size class
        let newSizeClass = determineSizeClass(width: availableWidth, height: availableHeight)
        if newSizeClass != sizeClass {
            sizeClass = newSizeClass
            notifySizeClassChange()
        }

        // Determine multitasking mode
        let newMode = determineMultitaskingMode(
            width: availableWidth,
            height: availableHeight,
            isStageManager: isStageManager
        )
        if newMode != currentMode {
            currentMode = newMode
            notifyModeChange()
        }
    }

    private func determineSizeClass(width: Double, height: Double) -> SizeClass {
        // iPad Pro size class determination based on available width
        if width < 320 {
            return .compact
        } else if width < 500 {
            return .compactMedium
        } else if width < 700 {
            return .regular
        } else {
            return .regularLarge
        }
    }

    private func determineMultitaskingMode(
        width: Double,
        height: Double,
        isStageManager: Bool
    ) -> MultitaskingMode {
        if isStageManager {
            return .stageManager
        }

        // Approximate detection based on typical iPad Pro dimensions
        let fullScreenThreshold: Double = 980 // ~70% of 12.9" iPad Pro width

        if width >= fullScreenThreshold {
            return .fullScreen
        } else if width >= 500 {
            return .splitViewPrimary
        } else if width >= 320 {
            return .splitViewSecondary
        } else {
            return .slideOver
        }
    }

    // MARK: - Layout Recommendations

    /// Get recommended layout configuration for current multitasking state
    public func getRecommendedLayout() -> LayoutRecommendation {
        switch currentMode {
        case .fullScreen:
            return LayoutRecommendation(
                showSidebar: true,
                sidebarWidth: 280,
                showAIPanel: true,
                aiPanelWidth: 320,
                editorMaxWidth: 720,
                toolbarStyle: .full,
                navigationStyle: .sidebar
            )

        case .splitViewPrimary:
            return LayoutRecommendation(
                showSidebar: sizeClass == .regularLarge,
                sidebarWidth: 220,
                showAIPanel: true,
                aiPanelWidth: 280,
                editorMaxWidth: 600,
                toolbarStyle: .compact,
                navigationStyle: sizeClass == .regularLarge ? .sidebar : .modal
            )

        case .splitViewSecondary:
            return LayoutRecommendation(
                showSidebar: false,
                sidebarWidth: 0,
                showAIPanel: false,
                aiPanelWidth: 0,
                editorMaxWidth: availableWidth - 40,
                toolbarStyle: .minimal,
                navigationStyle: .modal
            )

        case .slideOver:
            return LayoutRecommendation(
                showSidebar: false,
                sidebarWidth: 0,
                showAIPanel: false,
                aiPanelWidth: 0,
                editorMaxWidth: availableWidth - 32,
                toolbarStyle: .minimal,
                navigationStyle: .modal
            )

        case .stageManager:
            return LayoutRecommendation(
                showSidebar: availableWidth > 700,
                sidebarWidth: 260,
                showAIPanel: availableWidth > 900,
                aiPanelWidth: 300,
                editorMaxWidth: 680,
                toolbarStyle: availableWidth > 600 ? .full : .compact,
                navigationStyle: availableWidth > 700 ? .sidebar : .modal
            )
        }
    }

    /// Get recommended font sizes for current state
    public func getRecommendedFontSizes() -> FontSizeRecommendation {
        switch sizeClass {
        case .compact:
            return FontSizeRecommendation(
                body: 15,
                heading1: 24,
                heading2: 20,
                heading3: 17,
                caption: 12,
                lineHeight: 1.4
            )

        case .compactMedium:
            return FontSizeRecommendation(
                body: 16,
                heading1: 26,
                heading2: 22,
                heading3: 18,
                caption: 13,
                lineHeight: 1.5
            )

        case .regular:
            return FontSizeRecommendation(
                body: 17,
                heading1: 28,
                heading2: 24,
                heading3: 20,
                caption: 14,
                lineHeight: 1.6
            )

        case .regularLarge:
            return FontSizeRecommendation(
                body: 18,
                heading1: 32,
                heading2: 26,
                heading3: 22,
                caption: 14,
                lineHeight: 1.7
            )
        }
    }

    // MARK: - Observers

    /// Register a handler for mode changes
    public func onModeChange(_ handler: @escaping (MultitaskingMode) -> Void) {
        modeChangeHandlers.append(handler)
    }

    /// Register a handler for size class changes
    public func onSizeClassChange(_ handler: @escaping (SizeClass) -> Void) {
        sizeClassChangeHandlers.append(handler)
    }

    private func notifyModeChange() {
        for handler in modeChangeHandlers {
            handler(currentMode)
        }
    }

    private func notifySizeClassChange() {
        for handler in sizeClassChangeHandlers {
            handler(sizeClass)
        }
    }

    // MARK: - Split View Helpers

    /// Check if app should show reduced UI
    public var shouldShowReducedUI: Bool {
        return currentMode == .slideOver ||
               currentMode == .splitViewSecondary ||
               sizeClass == .compact
    }

    /// Check if AI panel can be shown
    public var canShowAIPanel: Bool {
        return currentMode == .fullScreen ||
               currentMode == .splitViewPrimary ||
               (currentMode == .stageManager && availableWidth > 900)
    }

    /// Check if sidebar can be shown
    public var canShowSidebar: Bool {
        return currentMode == .fullScreen ||
               (currentMode == .splitViewPrimary && sizeClass == .regularLarge) ||
               (currentMode == .stageManager && availableWidth > 700)
    }

    // MARK: - Drag and Drop Support

    /// Configuration for drag and drop in current multitasking mode
    public func getDragDropConfiguration() -> DragDropConfiguration {
        DragDropConfiguration(
            canAcceptExternalDrops: true,
            canDragToOtherApps: true,
            supportedDropTypes: [.plainText, .rtf, .markdown, .url],
            supportedDragTypes: [.plainText, .markdown]
        )
    }
}

// MARK: - Size Class

/// Size classes for iPad Pro layout
public enum SizeClass: String, Codable {
    case compact        // < 320pt (Slide Over)
    case compactMedium  // 320-500pt (Split View secondary)
    case regular        // 500-700pt (Split View primary)
    case regularLarge   // > 700pt (Full screen or Stage Manager)

    public var displayName: String {
        switch self {
        case .compact: return "Compact"
        case .compactMedium: return "Compact Medium"
        case .regular: return "Regular"
        case .regularLarge: return "Regular Large"
        }
    }
}

// MARK: - Layout Recommendation

/// Recommended layout configuration based on multitasking state
public struct LayoutRecommendation {
    public let showSidebar: Bool
    public let sidebarWidth: Double
    public let showAIPanel: Bool
    public let aiPanelWidth: Double
    public let editorMaxWidth: Double
    public let toolbarStyle: ToolbarStyle
    public let navigationStyle: NavigationStyle

    public init(
        showSidebar: Bool,
        sidebarWidth: Double,
        showAIPanel: Bool,
        aiPanelWidth: Double,
        editorMaxWidth: Double,
        toolbarStyle: ToolbarStyle,
        navigationStyle: NavigationStyle
    ) {
        self.showSidebar = showSidebar
        self.sidebarWidth = sidebarWidth
        self.showAIPanel = showAIPanel
        self.aiPanelWidth = aiPanelWidth
        self.editorMaxWidth = editorMaxWidth
        self.toolbarStyle = toolbarStyle
        self.navigationStyle = navigationStyle
    }
}

/// Toolbar display styles
public enum ToolbarStyle: String, Codable {
    case full       // All buttons visible
    case compact    // Grouped buttons with overflow menu
    case minimal    // Essential buttons only

    public var displayName: String {
        switch self {
        case .full: return "Full"
        case .compact: return "Compact"
        case .minimal: return "Minimal"
        }
    }
}

/// Navigation styles
public enum NavigationStyle: String, Codable {
    case sidebar    // Always-visible sidebar
    case modal      // Modal presentation
    case tabBar     // Tab bar navigation

    public var displayName: String {
        switch self {
        case .sidebar: return "Sidebar"
        case .modal: return "Modal"
        case .tabBar: return "Tab Bar"
        }
    }
}

// MARK: - Font Size Recommendation

/// Recommended font sizes based on size class
public struct FontSizeRecommendation {
    public let body: Double
    public let heading1: Double
    public let heading2: Double
    public let heading3: Double
    public let caption: Double
    public let lineHeight: Double

    public init(
        body: Double,
        heading1: Double,
        heading2: Double,
        heading3: Double,
        caption: Double,
        lineHeight: Double
    ) {
        self.body = body
        self.heading1 = heading1
        self.heading2 = heading2
        self.heading3 = heading3
        self.caption = caption
        self.lineHeight = lineHeight
    }
}

// MARK: - Drag and Drop Configuration

/// Configuration for drag and drop support
public struct DragDropConfiguration {
    public let canAcceptExternalDrops: Bool
    public let canDragToOtherApps: Bool
    public let supportedDropTypes: [ContentType]
    public let supportedDragTypes: [ContentType]

    public init(
        canAcceptExternalDrops: Bool,
        canDragToOtherApps: Bool,
        supportedDropTypes: [ContentType],
        supportedDragTypes: [ContentType]
    ) {
        self.canAcceptExternalDrops = canAcceptExternalDrops
        self.canDragToOtherApps = canDragToOtherApps
        self.supportedDropTypes = supportedDropTypes
        self.supportedDragTypes = supportedDragTypes
    }
}

/// Content types for drag and drop
public enum ContentType: String, Codable {
    case plainText
    case rtf
    case markdown
    case html
    case url
    case image
    case pdf

    public var utType: String {
        switch self {
        case .plainText: return "public.plain-text"
        case .rtf: return "public.rtf"
        case .markdown: return "net.daringfireball.markdown"
        case .html: return "public.html"
        case .url: return "public.url"
        case .image: return "public.image"
        case .pdf: return "com.adobe.pdf"
        }
    }
}

// MARK: - Scene Configuration

/// Configuration for iPad Pro scene management
public struct SceneConfiguration: Codable {
    public var windowStyle: WindowStyle
    public var minimumSize: CGSize
    public var maximumSize: CGSize?
    public var defaultSize: CGSize
    public var resizable: Bool
    public var supportsMultipleWindows: Bool

    public init(
        windowStyle: WindowStyle = .automatic,
        minimumSize: CGSize = CGSize(width: 320, height: 480),
        maximumSize: CGSize? = nil,
        defaultSize: CGSize = CGSize(width: 1024, height: 768),
        resizable: Bool = true,
        supportsMultipleWindows: Bool = true
    ) {
        self.windowStyle = windowStyle
        self.minimumSize = minimumSize
        self.maximumSize = maximumSize
        self.defaultSize = defaultSize
        self.resizable = resizable
        self.supportsMultipleWindows = supportsMultipleWindows
    }

    /// Default configuration for writers app
    public static var writersApp: SceneConfiguration {
        SceneConfiguration(
            windowStyle: .automatic,
            minimumSize: CGSize(width: 320, height: 480),
            maximumSize: nil,
            defaultSize: CGSize(width: 1024, height: 768),
            resizable: true,
            supportsMultipleWindows: true
        )
    }
}

/// Window styles for Stage Manager
public enum WindowStyle: String, Codable {
    case automatic
    case plain
    case hiddenTitleBar

    public var displayName: String {
        switch self {
        case .automatic: return "Automatic"
        case .plain: return "Plain"
        case .hiddenTitleBar: return "Hidden Title Bar"
        }
    }
}

// MARK: - CGSize Extension for Codable
// Note: CGSize already conforms to Codable in Foundation
