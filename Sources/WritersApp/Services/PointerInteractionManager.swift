import Foundation

// MARK: - Pointer Interaction Manager

/// Manages trackpad, mouse, and pointer interactions for iPad Pro
public class PointerInteractionManager {

    // MARK: - Properties

    public private(set) var isPointerConnected: Bool = false
    public private(set) var pointerType: PointerType = .unknown
    public private(set) var currentPointerStyle: PointerStyle = .automatic

    public var configuration: PointerConfiguration

    private var gestureHandlers: [TrackpadGestureType: (TrackpadGestureInfo) -> Void] = [:]

    // MARK: - Initialization

    public init(configuration: PointerConfiguration = PointerConfiguration()) {
        self.configuration = configuration
    }

    // MARK: - Pointer Detection

    /// Update pointer connection state
    public func updatePointerState(isConnected: Bool, type: PointerType) {
        self.isPointerConnected = isConnected
        self.pointerType = type
    }

    // MARK: - Pointer Styles

    /// Get pointer style for a UI element
    public func getPointerStyle(for element: PointerElement) -> PointerStyleConfiguration {
        switch element {
        case .button(let size):
            return PointerStyleConfiguration(
                style: .highlight,
                effect: .lift,
                shape: .roundedRect(cornerRadius: 8),
                constrainedAxes: [],
                targetSize: size
            )

        case .textField:
            return PointerStyleConfiguration(
                style: .beam,
                effect: .none,
                shape: .beam,
                constrainedAxes: [.vertical],
                targetSize: nil
            )

        case .editor:
            return PointerStyleConfiguration(
                style: .beam,
                effect: .none,
                shape: .beam,
                constrainedAxes: [],
                targetSize: nil
            )

        case .link:
            return PointerStyleConfiguration(
                style: .highlight,
                effect: .hover,
                shape: .roundedRect(cornerRadius: 4),
                constrainedAxes: [],
                targetSize: nil
            )

        case .slider:
            return PointerStyleConfiguration(
                style: .highlight,
                effect: .hover,
                shape: .roundedRect(cornerRadius: 4),
                constrainedAxes: [.vertical],
                targetSize: nil
            )

        case .toolbar:
            return PointerStyleConfiguration(
                style: .automatic,
                effect: .lift,
                shape: .roundedRect(cornerRadius: 6),
                constrainedAxes: [],
                targetSize: CGSize(width: 44, height: 44)
            )

        case .listItem:
            return PointerStyleConfiguration(
                style: .highlight,
                effect: .hover,
                shape: .roundedRect(cornerRadius: 8),
                constrainedAxes: [],
                targetSize: nil
            )

        case .dragHandle:
            return PointerStyleConfiguration(
                style: .highlight,
                effect: .lift,
                shape: .circle,
                constrainedAxes: [],
                targetSize: CGSize(width: 32, height: 32)
            )

        case .resizeHandle(let direction):
            return PointerStyleConfiguration(
                style: .resize(direction),
                effect: .none,
                shape: .arrow,
                constrainedAxes: direction.constrainedAxes,
                targetSize: nil
            )

        case .custom(let config):
            return config
        }
    }

    // MARK: - Trackpad Gestures

    /// Register handler for trackpad gesture
    public func onGesture(_ type: TrackpadGestureType, handler: @escaping (TrackpadGestureInfo) -> Void) {
        gestureHandlers[type] = handler
    }

    /// Process a trackpad gesture
    public func processGesture(_ gesture: TrackpadGestureInfo) {
        if let handler = gestureHandlers[gesture.type] {
            handler(gesture)
        }
    }

    /// Get recommended action for a gesture
    public func getRecommendedAction(for gesture: TrackpadGestureType) -> GestureRecommendedAction {
        switch gesture {
        case .twoFingerSwipeLeft:
            return GestureRecommendedAction(
                action: .showAIPanel,
                description: "Show AI assistant panel"
            )
        case .twoFingerSwipeRight:
            return GestureRecommendedAction(
                action: .hideAIPanel,
                description: "Hide AI assistant panel"
            )
        case .threeFingerSwipeUp:
            return GestureRecommendedAction(
                action: .showAppSwitcher,
                description: "Show app switcher"
            )
        case .threeFingerSwipeDown:
            return GestureRecommendedAction(
                action: .goToHome,
                description: "Go to home screen"
            )
        case .pinchIn:
            return GestureRecommendedAction(
                action: .zoomOut,
                description: "Zoom out"
            )
        case .pinchOut:
            return GestureRecommendedAction(
                action: .zoomIn,
                description: "Zoom in"
            )
        case .twoFingerTap:
            return GestureRecommendedAction(
                action: .secondaryClick,
                description: "Show context menu"
            )
        case .scroll:
            return GestureRecommendedAction(
                action: .scroll,
                description: "Scroll content"
            )
        case .rotate:
            return GestureRecommendedAction(
                action: .rotate,
                description: "Rotate content"
            )
        }
    }

    // MARK: - Mouse Support

    /// Get mouse button configuration
    public func getMouseButtonActions() -> MouseButtonConfiguration {
        MouseButtonConfiguration(
            leftClick: .primaryAction,
            rightClick: .contextMenu,
            middleClick: configuration.middleClickAction,
            backButton: .navigateBack,
            forwardButton: .navigateForward,
            scrollWheel: .scroll
        )
    }

    /// Process mouse click
    public func processMouseClick(_ click: MouseClickInfo) -> MouseAction {
        switch click.button {
        case .left:
            return .primaryAction
        case .right:
            return .contextMenu
        case .middle:
            return configuration.middleClickAction
        case .back:
            return .navigateBack
        case .forward:
            return .navigateForward
        }
    }

    // MARK: - Hover Effects

    /// Get hover effect for an element
    public func getHoverEffect(for element: HoverElement) -> HoverEffectConfiguration {
        switch element {
        case .button:
            return HoverEffectConfiguration(
                type: .lift,
                scale: 1.02,
                shadowRadius: 4,
                shadowOpacity: 0.15,
                tintColor: nil
            )
        case .card:
            return HoverEffectConfiguration(
                type: .lift,
                scale: 1.01,
                shadowRadius: 8,
                shadowOpacity: 0.2,
                tintColor: nil
            )
        case .link:
            return HoverEffectConfiguration(
                type: .highlight,
                scale: 1.0,
                shadowRadius: 0,
                shadowOpacity: 0,
                tintColor: "#007AFF"
            )
        case .menuItem:
            return HoverEffectConfiguration(
                type: .highlight,
                scale: 1.0,
                shadowRadius: 0,
                shadowOpacity: 0,
                tintColor: "#E8E8E8"
            )
        case .custom(let config):
            return config
        }
    }

    // MARK: - Scroll Wheel

    /// Process scroll wheel input
    public func processScrollWheel(_ scroll: ScrollWheelInfo) -> ScrollAction {
        var action = ScrollAction(
            deltaX: scroll.deltaX * configuration.scrollSpeed,
            deltaY: scroll.deltaY * configuration.scrollSpeed,
            isInertial: scroll.isInertial,
            phase: scroll.phase
        )

        // Natural scrolling
        if configuration.naturalScrolling {
            action.deltaX = -action.deltaX
            action.deltaY = -action.deltaY
        }

        return action
    }

    // MARK: - Precision Scrolling

    /// Get precision scroll settings
    public func getPrecisionScrollSettings() -> PrecisionScrollSettings {
        PrecisionScrollSettings(
            pixelPerfect: configuration.pixelPerfectScrolling,
            smoothScrolling: configuration.smoothScrolling,
            scrollAcceleration: configuration.scrollAcceleration,
            inertiaDecay: configuration.inertiaDecay
        )
    }

    // MARK: - Context Menu

    /// Get context menu configuration
    public func getContextMenuTrigger() -> ContextMenuTrigger {
        if isPointerConnected {
            return .rightClick
        }
        return .longPress
    }
}

// MARK: - Pointer Configuration

public struct PointerConfiguration: Codable {
    public var naturalScrolling: Bool
    public var scrollSpeed: Double
    public var smoothScrolling: Bool
    public var pixelPerfectScrolling: Bool
    public var scrollAcceleration: Double
    public var inertiaDecay: Double
    public var middleClickAction: MouseAction
    public var showPointerEffects: Bool

    public init(
        naturalScrolling: Bool = true,
        scrollSpeed: Double = 1.0,
        smoothScrolling: Bool = true,
        pixelPerfectScrolling: Bool = true,
        scrollAcceleration: Double = 1.0,
        inertiaDecay: Double = 0.95,
        middleClickAction: MouseAction = .openInNewWindow,
        showPointerEffects: Bool = true
    ) {
        self.naturalScrolling = naturalScrolling
        self.scrollSpeed = scrollSpeed
        self.smoothScrolling = smoothScrolling
        self.pixelPerfectScrolling = pixelPerfectScrolling
        self.scrollAcceleration = scrollAcceleration
        self.inertiaDecay = inertiaDecay
        self.middleClickAction = middleClickAction
        self.showPointerEffects = showPointerEffects
    }
}

// MARK: - Pointer Type

public enum PointerType: String, Codable {
    case unknown
    case mouse
    case trackpad
    case pencil
    case touch
}

// MARK: - Pointer Style

public enum PointerStyle: String, Codable {
    case automatic
    case highlight
    case beam
    case hidden
}

// MARK: - Pointer Element

public enum PointerElement {
    case button(size: CGSize)
    case textField
    case editor
    case link
    case slider
    case toolbar
    case listItem
    case dragHandle
    case resizeHandle(ResizeDirection)
    case custom(PointerStyleConfiguration)
}

// MARK: - Resize Direction

public enum ResizeDirection: String, Codable {
    case horizontal
    case vertical
    case diagonal

    var constrainedAxes: [Axis] {
        switch self {
        case .horizontal: return [.vertical]
        case .vertical: return [.horizontal]
        case .diagonal: return []
        }
    }
}

public enum Axis: String, Codable {
    case horizontal
    case vertical
}

// MARK: - Pointer Style Configuration

public struct PointerStyleConfiguration {
    public let style: PointerDisplayStyle
    public let effect: PointerEffect
    public let shape: PointerShape
    public let constrainedAxes: [Axis]
    public let targetSize: CGSize?

    public init(
        style: PointerDisplayStyle,
        effect: PointerEffect,
        shape: PointerShape,
        constrainedAxes: [Axis],
        targetSize: CGSize?
    ) {
        self.style = style
        self.effect = effect
        self.shape = shape
        self.constrainedAxes = constrainedAxes
        self.targetSize = targetSize
    }
}

public enum PointerDisplayStyle {
    case automatic
    case highlight
    case beam
    case resize(ResizeDirection)
}

public enum PointerEffect {
    case none
    case lift
    case hover
    case automatic
}

public enum PointerShape {
    case roundedRect(cornerRadius: Double)
    case circle
    case beam
    case arrow
}

// MARK: - Trackpad Gestures

public enum TrackpadGestureType: String, Codable, Hashable {
    case twoFingerSwipeLeft
    case twoFingerSwipeRight
    case threeFingerSwipeUp
    case threeFingerSwipeDown
    case pinchIn
    case pinchOut
    case twoFingerTap
    case scroll
    case rotate
}

public struct TrackpadGestureInfo {
    public let type: TrackpadGestureType
    public let velocity: CGPoint
    public let scale: Double?
    public let rotation: Double?
    public let location: CGPoint

    public init(
        type: TrackpadGestureType,
        velocity: CGPoint = .zero,
        scale: Double? = nil,
        rotation: Double? = nil,
        location: CGPoint = .zero
    ) {
        self.type = type
        self.velocity = velocity
        self.scale = scale
        self.rotation = rotation
        self.location = location
    }
}

public struct GestureRecommendedAction {
    public let action: GestureAction
    public let description: String
}

public enum GestureAction {
    case showAIPanel
    case hideAIPanel
    case showAppSwitcher
    case goToHome
    case zoomIn
    case zoomOut
    case secondaryClick
    case scroll
    case rotate
    case none
}

// MARK: - Mouse Support

public enum MouseButton: String, Codable {
    case left
    case right
    case middle
    case back
    case forward
}

public struct MouseClickInfo {
    public let button: MouseButton
    public let location: CGPoint
    public let clickCount: Int
    public let modifiers: Set<KeyModifier>

    public init(
        button: MouseButton,
        location: CGPoint,
        clickCount: Int = 1,
        modifiers: Set<KeyModifier> = []
    ) {
        self.button = button
        self.location = location
        self.clickCount = clickCount
        self.modifiers = modifiers
    }
}

public enum MouseAction: String, Codable {
    case primaryAction
    case contextMenu
    case navigateBack
    case navigateForward
    case openInNewWindow
    case scroll
    case none
}

public struct MouseButtonConfiguration {
    public let leftClick: MouseAction
    public let rightClick: MouseAction
    public let middleClick: MouseAction
    public let backButton: MouseAction
    public let forwardButton: MouseAction
    public let scrollWheel: MouseAction
}

// MARK: - Hover Effects

public enum HoverElement {
    case button
    case card
    case link
    case menuItem
    case custom(HoverEffectConfiguration)
}

public struct HoverEffectConfiguration {
    public let type: HoverEffectType
    public let scale: Double
    public let shadowRadius: Double
    public let shadowOpacity: Double
    public let tintColor: String?

    public enum HoverEffectType {
        case lift
        case highlight
        case scale
        case none
    }
}

// MARK: - Scroll Wheel

public struct ScrollWheelInfo {
    public let deltaX: Double
    public let deltaY: Double
    public let isInertial: Bool
    public let phase: ScrollPhase

    public init(
        deltaX: Double,
        deltaY: Double,
        isInertial: Bool = false,
        phase: ScrollPhase = .changed
    ) {
        self.deltaX = deltaX
        self.deltaY = deltaY
        self.isInertial = isInertial
        self.phase = phase
    }
}

public enum ScrollPhase {
    case began
    case changed
    case ended
    case cancelled
}

public struct ScrollAction {
    public var deltaX: Double
    public var deltaY: Double
    public let isInertial: Bool
    public let phase: ScrollPhase
}

public struct PrecisionScrollSettings {
    public let pixelPerfect: Bool
    public let smoothScrolling: Bool
    public let scrollAcceleration: Double
    public let inertiaDecay: Double
}

// MARK: - Context Menu

public enum ContextMenuTrigger {
    case rightClick
    case longPress
    case forceTouch
}

// MARK: - CGPoint Extension

extension CGPoint: @retroactive Codable {
    enum CodingKeys: String, CodingKey {
        case x, y
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let x = try container.decode(CGFloat.self, forKey: .x)
        let y = try container.decode(CGFloat.self, forKey: .y)
        self.init(x: x, y: y)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
    }
}
