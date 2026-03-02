import Foundation

// MARK: - Accessibility Manager

/// Manages accessibility features for inclusive iPad Pro writing experience
public class AccessibilityManager {

    // MARK: - Properties

    public private(set) var currentSettings: AccessibilitySettings
    public private(set) var voiceOverEnabled: Bool = false
    public private(set) var reduceMotionEnabled: Bool = false
    public private(set) var increaseContrastEnabled: Bool = false
    public private(set) var boldTextEnabled: Bool = false

    private var settingsChangeHandlers: [(AccessibilitySettings) -> Void] = []

    // MARK: - Initialization

    public init(settings: AccessibilitySettings = AccessibilitySettings()) {
        self.currentSettings = settings
    }

    // MARK: - System Settings Detection

    /// Update from system accessibility settings
    public func updateFromSystemSettings(
        voiceOverEnabled: Bool,
        reduceMotionEnabled: Bool,
        increaseContrastEnabled: Bool,
        boldTextEnabled: Bool,
        preferredContentSizeCategory: ContentSizeCategory
    ) {
        self.voiceOverEnabled = voiceOverEnabled
        self.reduceMotionEnabled = reduceMotionEnabled
        self.increaseContrastEnabled = increaseContrastEnabled
        self.boldTextEnabled = boldTextEnabled
        self.currentSettings.preferredContentSize = preferredContentSizeCategory

        notifySettingsChange()
    }

    // MARK: - VoiceOver Support

    /// Get VoiceOver label for a UI element
    public func getVoiceOverLabel(for element: UIElementType, context: ElementContext) -> VoiceOverLabel {
        switch element {
        case .documentTitle:
            return VoiceOverLabel(
                label: "Document title: \(context.text ?? "Untitled")",
                hint: "Double tap to edit the title",
                traits: [.header, .button]
            )

        case .wordCount:
            let count = context.numericValue ?? 0
            return VoiceOverLabel(
                label: "\(count) words",
                hint: "Shows your current word count",
                traits: [.staticText, .updatesFrequently]
            )

        case .editor:
            return VoiceOverLabel(
                label: "Document editor",
                hint: "Double tap to start editing. Use rotor to navigate by paragraph, sentence, or word.",
                traits: [.allowsDirectInteraction]
            )

        case .aiButton:
            return VoiceOverLabel(
                label: "AI Assistant",
                hint: "Double tap to open AI writing assistance options",
                traits: [.button]
            )

        case .formatButton(let format):
            return VoiceOverLabel(
                label: format.accessibilityName,
                hint: "Double tap to apply \(format.accessibilityName.lowercased()) formatting",
                traits: context.isSelected ? [.button, .selected] : [.button]
            )

        case .templateItem:
            return VoiceOverLabel(
                label: "Template: \(context.text ?? "Unknown")",
                hint: "Double tap to create a new document from this template",
                traits: [.button]
            )

        case .documentItem:
            let wordCount = context.numericValue ?? 0
            return VoiceOverLabel(
                label: "\(context.text ?? "Untitled"), \(wordCount) words",
                hint: "Double tap to open this document",
                traits: [.button]
            )

        case .sidebar:
            return VoiceOverLabel(
                label: "Sidebar navigation",
                hint: "Contains document list, templates, and settings",
                traits: [.tabBar]
            )

        case .progressIndicator:
            let progress = context.progress ?? 0
            return VoiceOverLabel(
                label: "Writing progress: \(Int(progress * 100)) percent",
                hint: nil,
                traits: [.updatesFrequently]
            )

        case .custom(let customLabel):
            return VoiceOverLabel(
                label: customLabel,
                hint: context.hint,
                traits: context.traits
            )
        }
    }

    /// Announce a message to VoiceOver users
    public func announceToVoiceOver(_ message: String, priority: AnnouncementPriority = .normal) {
        // Would use UIAccessibility.post(notification:argument:)
    }

    /// Announce writing milestone
    public func announceWritingMilestone(_ milestone: WritingMilestone) {
        let message: String
        switch milestone {
        case .wordCountReached(let count):
            message = "Congratulations! You've reached \(count) words."
        case .dailyGoalComplete:
            message = "Amazing! You've completed your daily writing goal."
        case .streakContinued(let days):
            message = "Great job! Your writing streak is now \(days) days."
        case .documentSaved:
            message = "Document saved successfully."
        case .exportComplete(let format):
            message = "Document exported as \(format)."
        }
        announceToVoiceOver(message, priority: .high)
    }

    // MARK: - Dynamic Type Support

    /// Get scaled font size based on Dynamic Type settings
    public func getScaledFontSize(baseSize: Double, style: TextStyle) -> ScaledFont {
        let scaleFactor = getScaleFactor(for: currentSettings.preferredContentSize)
        let scaledSize = baseSize * scaleFactor

        // Apply minimum/maximum constraints
        let minSize = getMinimumSize(for: style)
        let maxSize = getMaximumSize(for: style)
        let constrainedSize = min(max(scaledSize, minSize), maxSize)

        return ScaledFont(
            size: constrainedSize,
            weight: boldTextEnabled ? .semibold : style.defaultWeight,
            style: style
        )
    }

    private func getScaleFactor(for category: ContentSizeCategory) -> Double {
        switch category {
        case .extraSmall: return 0.8
        case .small: return 0.9
        case .medium: return 1.0
        case .large: return 1.1
        case .extraLarge: return 1.2
        case .extraExtraLarge: return 1.3
        case .extraExtraExtraLarge: return 1.4
        case .accessibilityMedium: return 1.6
        case .accessibilityLarge: return 1.8
        case .accessibilityExtraLarge: return 2.0
        case .accessibilityExtraExtraLarge: return 2.3
        case .accessibilityExtraExtraExtraLarge: return 2.6
        }
    }

    private func getMinimumSize(for style: TextStyle) -> Double {
        switch style {
        case .body: return 14
        case .headline: return 16
        case .title: return 20
        case .caption: return 11
        case .footnote: return 10
        }
    }

    private func getMaximumSize(for style: TextStyle) -> Double {
        switch style {
        case .body: return 40
        case .headline: return 48
        case .title: return 60
        case .caption: return 30
        case .footnote: return 28
        }
    }

    // MARK: - Reduce Motion

    /// Get animation configuration respecting Reduce Motion
    public func getAnimationConfiguration() -> AnimationConfiguration {
        if reduceMotionEnabled {
            return AnimationConfiguration(
                duration: 0,
                curve: .linear,
                useSpring: false,
                allowParallax: false
            )
        }
        return AnimationConfiguration(
            duration: 0.3,
            curve: .easeInOut,
            useSpring: true,
            allowParallax: true
        )
    }

    /// Should use crossfade instead of movement animation
    public var shouldUseCrossfade: Bool {
        return reduceMotionEnabled
    }

    // MARK: - Increase Contrast

    /// Get color adjustments for increased contrast
    public func getContrastAdjustedColors() -> ContrastColors {
        if increaseContrastEnabled {
            return ContrastColors(
                textPrimary: "#000000",
                textSecondary: "#333333",
                background: "#FFFFFF",
                accent: "#0066CC",
                separator: "#666666",
                selection: "#CCE5FF"
            )
        }
        return ContrastColors(
            textPrimary: "#1A1A1A",
            textSecondary: "#666666",
            background: "#FFFFFF",
            accent: "#007AFF",
            separator: "#E5E5E5",
            selection: "#E8F0FE"
        )
    }

    // MARK: - Text-to-Speech

    /// Configure text-to-speech for reading documents
    public func configureSpeech() -> SpeechConfiguration {
        SpeechConfiguration(
            voice: currentSettings.preferredVoice,
            rate: currentSettings.speechRate,
            pitch: currentSettings.speechPitch,
            volume: currentSettings.speechVolume,
            highlightWords: currentSettings.highlightSpokenWords
        )
    }

    /// Get speech utterance for document content
    public func getSpeechUtterance(for text: String, range: Range<String.Index>? = nil) -> SpeechUtterance {
        let textToSpeak = range.map { String(text[$0]) } ?? text
        let config = configureSpeech()

        return SpeechUtterance(
            text: textToSpeak,
            voice: config.voice,
            rate: config.rate,
            pitch: config.pitch,
            volume: config.volume,
            preUtteranceDelay: 0.1,
            postUtteranceDelay: 0.1
        )
    }

    // MARK: - Switch Control

    /// Get switch control configuration
    public func getSwitchControlActions(for element: UIElementType) -> [SwitchControlAction] {
        switch element {
        case .editor:
            return [
                SwitchControlAction(name: "Edit", action: .activate),
                SwitchControlAction(name: "Select All", action: .selectAll),
                SwitchControlAction(name: "Copy", action: .copy),
                SwitchControlAction(name: "Paste", action: .paste),
                SwitchControlAction(name: "AI Assist", action: .custom("aiAssist"))
            ]
        case .documentItem:
            return [
                SwitchControlAction(name: "Open", action: .activate),
                SwitchControlAction(name: "Delete", action: .delete),
                SwitchControlAction(name: "Export", action: .custom("export"))
            ]
        default:
            return [
                SwitchControlAction(name: "Activate", action: .activate)
            ]
        }
    }

    // MARK: - Custom Actions

    /// Register accessibility custom actions for an element
    public func getCustomActions(for element: UIElementType) -> [AccessibilityAction] {
        switch element {
        case .editor:
            return [
                AccessibilityAction(name: "AI Continue Writing", identifier: "aiContinue"),
                AccessibilityAction(name: "AI Improve Text", identifier: "aiImprove"),
                AccessibilityAction(name: "Check Grammar", identifier: "checkGrammar"),
                AccessibilityAction(name: "Show Word Count", identifier: "wordCount"),
                AccessibilityAction(name: "Toggle Focus Mode", identifier: "focusMode")
            ]
        case .documentItem:
            return [
                AccessibilityAction(name: "Export", identifier: "export"),
                AccessibilityAction(name: "Duplicate", identifier: "duplicate"),
                AccessibilityAction(name: "Move to Folder", identifier: "move")
            ]
        default:
            return []
        }
    }

    // MARK: - Settings Change

    /// Register for settings changes
    public func onSettingsChange(_ handler: @escaping (AccessibilitySettings) -> Void) {
        settingsChangeHandlers.append(handler)
    }

    private func notifySettingsChange() {
        for handler in settingsChangeHandlers {
            handler(currentSettings)
        }
    }
}

// MARK: - Accessibility Settings

public struct AccessibilitySettings: Codable {
    public var preferredContentSize: ContentSizeCategory
    public var preferredVoice: String?
    public var speechRate: Float
    public var speechPitch: Float
    public var speechVolume: Float
    public var highlightSpokenWords: Bool
    public var useHapticFeedback: Bool
    public var autoReadAIResponses: Bool

    public init(
        preferredContentSize: ContentSizeCategory = .large,
        preferredVoice: String? = nil,
        speechRate: Float = 0.5,
        speechPitch: Float = 1.0,
        speechVolume: Float = 1.0,
        highlightSpokenWords: Bool = true,
        useHapticFeedback: Bool = true,
        autoReadAIResponses: Bool = false
    ) {
        self.preferredContentSize = preferredContentSize
        self.preferredVoice = preferredVoice
        self.speechRate = speechRate
        self.speechPitch = speechPitch
        self.speechVolume = speechVolume
        self.highlightSpokenWords = highlightSpokenWords
        self.useHapticFeedback = useHapticFeedback
        self.autoReadAIResponses = autoReadAIResponses
    }
}

// MARK: - Content Size Category

public enum ContentSizeCategory: String, Codable, CaseIterable {
    case extraSmall
    case small
    case medium
    case large
    case extraLarge
    case extraExtraLarge
    case extraExtraExtraLarge
    case accessibilityMedium
    case accessibilityLarge
    case accessibilityExtraLarge
    case accessibilityExtraExtraLarge
    case accessibilityExtraExtraExtraLarge

    public var isAccessibilityCategory: Bool {
        switch self {
        case .accessibilityMedium, .accessibilityLarge, .accessibilityExtraLarge,
             .accessibilityExtraExtraLarge, .accessibilityExtraExtraExtraLarge:
            return true
        default:
            return false
        }
    }
}

// MARK: - UI Element Types

public enum UIElementType {
    case documentTitle
    case wordCount
    case editor
    case aiButton
    case formatButton(FormatType)
    case templateItem
    case documentItem
    case sidebar
    case progressIndicator
    case custom(String)
}

public enum FormatType {
    case bold, italic, underline, heading1, heading2, heading3, bulletList, numberedList, quote

    var accessibilityName: String {
        switch self {
        case .bold: return "Bold"
        case .italic: return "Italic"
        case .underline: return "Underline"
        case .heading1: return "Heading 1"
        case .heading2: return "Heading 2"
        case .heading3: return "Heading 3"
        case .bulletList: return "Bullet List"
        case .numberedList: return "Numbered List"
        case .quote: return "Quote"
        }
    }
}

// MARK: - Element Context

public struct ElementContext {
    public var text: String?
    public var numericValue: Int?
    public var progress: Double?
    public var isSelected: Bool
    public var hint: String?
    public var traits: [AccessibilityTrait]

    public init(
        text: String? = nil,
        numericValue: Int? = nil,
        progress: Double? = nil,
        isSelected: Bool = false,
        hint: String? = nil,
        traits: [AccessibilityTrait] = []
    ) {
        self.text = text
        self.numericValue = numericValue
        self.progress = progress
        self.isSelected = isSelected
        self.hint = hint
        self.traits = traits
    }
}

// MARK: - VoiceOver Label

public struct VoiceOverLabel {
    public let label: String
    public let hint: String?
    public let traits: [AccessibilityTrait]

    public init(label: String, hint: String?, traits: [AccessibilityTrait]) {
        self.label = label
        self.hint = hint
        self.traits = traits
    }
}

// MARK: - Accessibility Traits

public enum AccessibilityTrait: String, Codable {
    case button
    case link
    case header
    case searchField
    case image
    case selected
    case playsSound
    case keyboardKey
    case staticText
    case summaryElement
    case notEnabled
    case updatesFrequently
    case startsMediaSession
    case adjustable
    case allowsDirectInteraction
    case causesPageTurn
    case tabBar
}

// MARK: - Announcement Priority

public enum AnnouncementPriority {
    case low
    case normal
    case high
}

// MARK: - Writing Milestone

public enum WritingMilestone {
    case wordCountReached(Int)
    case dailyGoalComplete
    case streakContinued(Int)
    case documentSaved
    case exportComplete(String)
}

// MARK: - Text Style

public enum TextStyle {
    case body
    case headline
    case title
    case caption
    case footnote

    var defaultWeight: FontWeight {
        switch self {
        case .body, .caption, .footnote: return .regular
        case .headline, .title: return .semibold
        }
    }
}

public enum FontWeight: String {
    case regular, medium, semibold, bold
}

// MARK: - Scaled Font

public struct ScaledFont {
    public let size: Double
    public let weight: FontWeight
    public let style: TextStyle
}

// MARK: - Animation Configuration

public struct AnimationConfiguration {
    public let duration: TimeInterval
    public let curve: AnimationCurve
    public let useSpring: Bool
    public let allowParallax: Bool

    public enum AnimationCurve {
        case linear, easeIn, easeOut, easeInOut
    }
}

// MARK: - Contrast Colors

public struct ContrastColors {
    public let textPrimary: String
    public let textSecondary: String
    public let background: String
    public let accent: String
    public let separator: String
    public let selection: String
}

// MARK: - Speech Configuration

public struct SpeechConfiguration {
    public let voice: String?
    public let rate: Float
    public let pitch: Float
    public let volume: Float
    public let highlightWords: Bool
}

// MARK: - Speech Utterance

public struct SpeechUtterance {
    public let text: String
    public let voice: String?
    public let rate: Float
    public let pitch: Float
    public let volume: Float
    public let preUtteranceDelay: TimeInterval
    public let postUtteranceDelay: TimeInterval
}

// MARK: - Switch Control Action

public struct SwitchControlAction {
    public let name: String
    public let action: SwitchAction

    public enum SwitchAction {
        case activate
        case selectAll
        case copy
        case paste
        case delete
        case custom(String)
    }
}

// MARK: - Accessibility Action

public struct AccessibilityAction {
    public let name: String
    public let identifier: String
}
