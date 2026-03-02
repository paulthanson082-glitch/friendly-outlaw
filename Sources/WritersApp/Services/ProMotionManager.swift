import Foundation

// MARK: - ProMotion Display Manager

/// Manages ProMotion 120Hz display features for smooth scrolling and animations
public class ProMotionManager {

    // MARK: - Properties

    public private(set) var isProMotionSupported: Bool = false
    public private(set) var currentRefreshRate: Int = 60
    public private(set) var maxRefreshRate: Int = 60
    public private(set) var isAdaptiveRefreshEnabled: Bool = true

    public var configuration: ProMotionConfiguration

    // MARK: - Initialization

    public init(configuration: ProMotionConfiguration = ProMotionConfiguration()) {
        self.configuration = configuration
    }

    // MARK: - Display Detection

    /// Update ProMotion capabilities based on device
    public func updateCapabilities(
        isSupported: Bool,
        maxRate: Int,
        currentRate: Int
    ) {
        self.isProMotionSupported = isSupported
        self.maxRefreshRate = maxRate
        self.currentRefreshRate = currentRate
    }

    // MARK: - Refresh Rate Management

    /// Get optimal refresh rate for current activity
    public func getOptimalRefreshRate(for activity: DisplayActivity) -> RefreshRatePreference {
        guard isProMotionSupported else {
            return RefreshRatePreference(rate: 60, reason: "ProMotion not supported")
        }

        switch activity {
        case .idle:
            return RefreshRatePreference(rate: 24, reason: "Power saving during idle")
        case .reading:
            return RefreshRatePreference(rate: 60, reason: "Standard rate for reading")
        case .typing:
            return RefreshRatePreference(rate: 120, reason: "Maximum responsiveness for typing")
        case .scrolling:
            return RefreshRatePreference(rate: 120, reason: "Smooth scrolling experience")
        case .animation:
            return RefreshRatePreference(rate: 120, reason: "Fluid animations")
        case .video:
            return RefreshRatePreference(rate: 60, reason: "Match video frame rate")
        case .pencilDrawing:
            return RefreshRatePreference(rate: 120, reason: "Low latency for Pencil input")
        }
    }

    // MARK: - Animation Timing

    /// Get animation duration optimized for ProMotion
    public func getOptimizedAnimationDuration(baseDuration: TimeInterval, type: AnimationType) -> TimeInterval {
        guard isProMotionSupported && configuration.optimizeAnimations else {
            return baseDuration
        }

        // ProMotion allows slightly faster animations that still look smooth
        let multiplier: Double
        switch type {
        case .springy:
            multiplier = 0.85
        case .smooth:
            multiplier = 0.9
        case .quick:
            multiplier = 0.8
        case .standard:
            multiplier = 0.95
        }

        return baseDuration * multiplier
    }

    /// Get frame interval for smooth animations
    public func getFrameInterval() -> TimeInterval {
        if isProMotionSupported && currentRefreshRate >= 120 {
            return 1.0 / 120.0 // ~8.33ms per frame
        }
        return 1.0 / 60.0 // ~16.67ms per frame
    }

    // MARK: - Scroll Optimization

    /// Get scroll deceleration rate for ProMotion displays
    public func getScrollDecelerationRate() -> ScrollDecelerationRate {
        if isProMotionSupported {
            return ScrollDecelerationRate(
                normal: 0.998,
                fast: 0.99,
                custom: configuration.customDecelerationRate
            )
        }
        return ScrollDecelerationRate(
            normal: 0.998,
            fast: 0.99,
            custom: nil
        )
    }

    /// Calculate smooth scroll velocity
    public func calculateScrollVelocity(
        distance: Double,
        duration: TimeInterval
    ) -> ScrollVelocity {
        let baseVelocity = distance / duration
        let frameRate = Double(isProMotionSupported ? 120 : 60)

        return ScrollVelocity(
            pointsPerSecond: baseVelocity,
            pointsPerFrame: baseVelocity / frameRate,
            recommendedFrameRate: Int(frameRate)
        )
    }

    // MARK: - Input Latency

    /// Get Apple Pencil latency for current display mode
    public func getPencilLatency() -> PencilLatencyInfo {
        if isProMotionSupported {
            return PencilLatencyInfo(
                baseLatency: 9.0, // 9ms base latency with ProMotion
                predictedLatency: 2.0, // With prediction
                isPredictionEnabled: configuration.enablePencilPrediction
            )
        }
        return PencilLatencyInfo(
            baseLatency: 20.0,
            predictedLatency: 9.0,
            isPredictionEnabled: configuration.enablePencilPrediction
        )
    }

    // MARK: - Power Management

    /// Get power impact for current refresh rate
    public func getPowerImpact() -> PowerImpact {
        switch currentRefreshRate {
        case 120:
            return PowerImpact(level: .high, estimatedBatteryDrain: 1.3)
        case 80:
            return PowerImpact(level: .medium, estimatedBatteryDrain: 1.15)
        case 60:
            return PowerImpact(level: .normal, estimatedBatteryDrain: 1.0)
        default:
            return PowerImpact(level: .low, estimatedBatteryDrain: 0.85)
        }
    }

    /// Should reduce refresh rate for battery
    public func shouldReduceRefreshRate(batteryLevel: Double, isCharging: Bool) -> Bool {
        if isCharging { return false }
        if batteryLevel < 0.2 && configuration.reducePowerWhenLowBattery {
            return true
        }
        return false
    }
}

// MARK: - ProMotion Configuration

/// Configuration for ProMotion features
public struct ProMotionConfiguration: Codable {
    public var optimizeAnimations: Bool
    public var enablePencilPrediction: Bool
    public var reducePowerWhenLowBattery: Bool
    public var preferHighRefreshRate: Bool
    public var customDecelerationRate: Double?

    public init(
        optimizeAnimations: Bool = true,
        enablePencilPrediction: Bool = true,
        reducePowerWhenLowBattery: Bool = true,
        preferHighRefreshRate: Bool = true,
        customDecelerationRate: Double? = nil
    ) {
        self.optimizeAnimations = optimizeAnimations
        self.enablePencilPrediction = enablePencilPrediction
        self.reducePowerWhenLowBattery = reducePowerWhenLowBattery
        self.preferHighRefreshRate = preferHighRefreshRate
        self.customDecelerationRate = customDecelerationRate
    }
}

// MARK: - Display Activity

/// Types of display activity that affect refresh rate
public enum DisplayActivity: String, Codable {
    case idle
    case reading
    case typing
    case scrolling
    case animation
    case video
    case pencilDrawing
}

// MARK: - Animation Types

/// Types of animations
public enum AnimationType: String, Codable {
    case springy
    case smooth
    case quick
    case standard
}

// MARK: - Supporting Types

public struct RefreshRatePreference {
    public let rate: Int
    public let reason: String
}

public struct ScrollDecelerationRate {
    public let normal: Double
    public let fast: Double
    public let custom: Double?
}

public struct ScrollVelocity {
    public let pointsPerSecond: Double
    public let pointsPerFrame: Double
    public let recommendedFrameRate: Int
}

public struct PencilLatencyInfo {
    public let baseLatency: Double // in milliseconds
    public let predictedLatency: Double
    public let isPredictionEnabled: Bool
}

public struct PowerImpact {
    public let level: PowerLevel
    public let estimatedBatteryDrain: Double // multiplier vs 60Hz

    public enum PowerLevel: String {
        case low, normal, medium, high
    }
}

// MARK: - Haptic Feedback Manager

/// Manages haptic feedback for iPad Pro interactions
public class HapticFeedbackManager {

    // MARK: - Properties

    public var isEnabled: Bool = true
    public var intensity: HapticIntensity = .medium

    // MARK: - Feedback Types

    /// Trigger haptic feedback for an interaction
    public func trigger(_ type: HapticFeedbackType) {
        guard isEnabled else { return }
        // In actual implementation, this would use UIImpactFeedbackGenerator
    }

    /// Trigger selection feedback
    public func selectionChanged() {
        guard isEnabled else { return }
        // Uses UISelectionFeedbackGenerator
    }

    /// Trigger notification feedback
    public func notify(_ type: NotificationFeedbackType) {
        guard isEnabled else { return }
        // Uses UINotificationFeedbackGenerator
    }

    // MARK: - Custom Patterns

    /// Play a custom haptic pattern
    public func playPattern(_ pattern: HapticPattern) {
        guard isEnabled else { return }
        // Would use CHHapticEngine for custom patterns
    }

    /// Get recommended haptic for writing actions
    public func getRecommendedHaptic(for action: WritingAction) -> HapticFeedbackType? {
        switch action {
        case .save:
            return .success
        case .delete:
            return .warning
        case .undo, .redo:
            return .light
        case .formatApplied:
            return .selection
        case .aiSuggestionAccepted:
            return .medium
        case .wordCountGoalReached:
            return .success
        case .error:
            return .error
        case .typing:
            return nil // No haptic for typing by default
        }
    }
}

// MARK: - Haptic Types

public enum HapticFeedbackType: String, Codable {
    case light
    case medium
    case heavy
    case soft
    case rigid
    case selection
    case success
    case warning
    case error
}

public enum NotificationFeedbackType: String, Codable {
    case success
    case warning
    case error
}

public enum HapticIntensity: String, Codable {
    case light
    case medium
    case strong
}

public struct HapticPattern: Codable {
    public let events: [HapticEvent]

    public init(events: [HapticEvent]) {
        self.events = events
    }

    public static var celebration: HapticPattern {
        HapticPattern(events: [
            HapticEvent(type: .transient, time: 0, intensity: 0.8),
            HapticEvent(type: .transient, time: 0.1, intensity: 1.0),
            HapticEvent(type: .transient, time: 0.2, intensity: 0.6)
        ])
    }

    public static var gentle: HapticPattern {
        HapticPattern(events: [
            HapticEvent(type: .continuous, time: 0, intensity: 0.3, duration: 0.2)
        ])
    }
}

public struct HapticEvent: Codable {
    public let type: HapticEventType
    public let time: Double
    public let intensity: Double
    public var duration: Double?

    public init(type: HapticEventType, time: Double, intensity: Double, duration: Double? = nil) {
        self.type = type
        self.time = time
        self.intensity = intensity
        self.duration = duration
    }
}

public enum HapticEventType: String, Codable {
    case transient
    case continuous
}

public enum WritingAction: String, Codable {
    case save
    case delete
    case undo
    case redo
    case formatApplied
    case aiSuggestionAccepted
    case wordCountGoalReached
    case error
    case typing
}
