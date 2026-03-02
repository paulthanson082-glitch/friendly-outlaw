import Foundation

// MARK: - Widgets Manager

/// Manages Home Screen widgets and Quick Note integration for iPad Pro
public class WidgetsManager {

    // MARK: - Properties

    public private(set) var availableWidgets: [WidgetConfiguration] = []
    public private(set) var activeWidgets: [ActiveWidget] = []
    public private(set) var quickNotes: [QuickNote] = []

    public var configuration: WidgetsConfiguration

    // MARK: - Initialization

    public init(configuration: WidgetsConfiguration = WidgetsConfiguration()) {
        self.configuration = configuration
        setupAvailableWidgets()
    }

    private func setupAvailableWidgets() {
        availableWidgets = [
            // Word Count Widget
            WidgetConfiguration(
                id: "wordcount",
                name: "Word Count",
                description: "Track your daily word count progress",
                supportedFamilies: [.small, .medium],
                refreshInterval: 60,
                category: .progress,
                previewData: WordCountWidgetData(
                    currentWords: 1250,
                    goalWords: 2000,
                    documentTitle: "My Novel"
                )
            ),

            // Writing Streak Widget
            WidgetConfiguration(
                id: "streak",
                name: "Writing Streak",
                description: "Keep your writing streak alive",
                supportedFamilies: [.small, .medium, .large],
                refreshInterval: 3600,
                category: .progress,
                previewData: StreakWidgetData(
                    currentStreak: 15,
                    longestStreak: 42,
                    lastWritingDate: Date(),
                    status: .safe
                )
            ),

            // Recent Documents Widget
            WidgetConfiguration(
                id: "recent",
                name: "Recent Documents",
                description: "Quick access to your recent documents",
                supportedFamilies: [.medium, .large],
                refreshInterval: 300,
                category: .quickAccess,
                previewData: RecentDocumentsWidgetData(
                    documents: [
                        RecentDocumentInfo(id: UUID(), title: "Chapter 12", wordCount: 2340, lastModified: Date()),
                        RecentDocumentInfo(id: UUID(), title: "Blog Post Draft", wordCount: 890, lastModified: Date().addingTimeInterval(-3600))
                    ]
                )
            ),

            // Writing Stats Widget
            WidgetConfiguration(
                id: "stats",
                name: "Writing Stats",
                description: "View your writing statistics",
                supportedFamilies: [.medium, .large],
                refreshInterval: 3600,
                category: .statistics,
                previewData: StatsWidgetData(
                    todayWords: 1250,
                    weekWords: 8500,
                    monthWords: 32000,
                    sessionsThisWeek: 12
                )
            ),

            // Quick Capture Widget
            WidgetConfiguration(
                id: "capture",
                name: "Quick Capture",
                description: "Capture ideas with one tap",
                supportedFamilies: [.small, .medium],
                refreshInterval: 0,
                category: .quickAccess,
                previewData: QuickCaptureWidgetData(
                    recentCaptures: 3,
                    lastCaptureTime: Date().addingTimeInterval(-1800)
                )
            ),

            // Writing Prompt Widget
            WidgetConfiguration(
                id: "prompt",
                name: "Daily Prompt",
                description: "Get daily writing inspiration",
                supportedFamilies: [.medium, .large],
                refreshInterval: 86400,
                category: .inspiration,
                previewData: PromptWidgetData(
                    prompt: "Write about a character who discovers a hidden door in their childhood home.",
                    category: "Fiction",
                    date: Date()
                )
            ),

            // Goal Progress Widget
            WidgetConfiguration(
                id: "goals",
                name: "Goals",
                description: "Track progress on your writing goals",
                supportedFamilies: [.small, .medium, .large],
                refreshInterval: 300,
                category: .progress,
                previewData: GoalsWidgetData(
                    goals: [
                        GoalProgressInfo(name: "Daily Words", progress: 0.62, target: 2000, current: 1250),
                        GoalProgressInfo(name: "Weekly Hours", progress: 0.85, target: 10, current: 8)
                    ]
                )
            ),

            // AI Suggestions Widget
            WidgetConfiguration(
                id: "ai",
                name: "AI Assistant",
                description: "Quick access to AI writing help",
                supportedFamilies: [.small, .medium],
                refreshInterval: 0,
                category: .quickAccess,
                previewData: AIWidgetData(
                    lastSuggestion: "Continue writing your current document",
                    quickActions: ["Continue", "Brainstorm", "Improve"]
                )
            ),

            // Lock Screen Widgets
            WidgetConfiguration(
                id: "lockscreen_progress",
                name: "Progress Ring",
                description: "Daily word count progress for lock screen",
                supportedFamilies: [.accessoryCircular],
                refreshInterval: 300,
                category: .progress,
                previewData: LockScreenProgressData(progress: 0.75)
            ),

            WidgetConfiguration(
                id: "lockscreen_streak",
                name: "Streak Counter",
                description: "Current streak on lock screen",
                supportedFamilies: [.accessoryInline, .accessoryRectangular],
                refreshInterval: 3600,
                category: .progress,
                previewData: LockScreenStreakData(streakDays: 15)
            )
        ]
    }

    // MARK: - Widget Data

    /// Get data for a specific widget
    public func getWidgetData(for widgetId: String) -> WidgetData? {
        guard let config = availableWidgets.first(where: { $0.id == widgetId }) else {
            return nil
        }
        return config.previewData
    }

    /// Update widget data
    public func updateWidgetData(widgetId: String, data: WidgetData) {
        // Would trigger WidgetCenter.shared.reloadTimelines
    }

    /// Reload all widgets
    public func reloadAllWidgets() {
        // Would call WidgetCenter.shared.reloadAllTimelines()
    }

    /// Reload specific widget
    public func reloadWidget(kind: String) {
        // Would call WidgetCenter.shared.reloadTimelines(ofKind:)
    }

    // MARK: - Widget Configuration

    /// Get user's active widget configurations
    public func getActiveWidgets() -> [ActiveWidget] {
        return activeWidgets
    }

    /// Track widget addition
    public func widgetAdded(_ widget: ActiveWidget) {
        activeWidgets.append(widget)
    }

    /// Track widget removal
    public func widgetRemoved(id: UUID) {
        activeWidgets.removeAll { $0.id == id }
    }

    // MARK: - Quick Note Integration

    /// Create a quick note
    public func createQuickNote(content: String, source: QuickNoteSource = .widget) -> QuickNote {
        let note = QuickNote(
            id: UUID(),
            content: content,
            createdAt: Date(),
            source: source,
            linkedDocumentId: nil,
            tags: []
        )
        quickNotes.append(note)
        return note
    }

    /// Get all quick notes
    public func getQuickNotes(limit: Int? = nil) -> [QuickNote] {
        let sorted = quickNotes.sorted { $0.createdAt > $1.createdAt }
        if let limit = limit {
            return Array(sorted.prefix(limit))
        }
        return sorted
    }

    /// Convert quick note to document
    public func convertToDocument(noteId: UUID) -> UUID? {
        guard let note = quickNotes.first(where: { $0.id == noteId }) else {
            return nil
        }
        // Would create document and return its ID
        let documentId = UUID()
        deleteQuickNote(id: noteId)
        return documentId
    }

    /// Delete quick note
    public func deleteQuickNote(id: UUID) {
        quickNotes.removeAll { $0.id == id }
    }

    /// Link quick note to document
    public func linkNoteToDocument(noteId: UUID, documentId: UUID) {
        guard let index = quickNotes.firstIndex(where: { $0.id == noteId }) else { return }
        quickNotes[index].linkedDocumentId = documentId
    }

    // MARK: - App Intent Donations

    /// Donate interaction for widget suggestions
    public func donateInteraction(type: WidgetInteractionType, context: [String: Any]) {
        // Would donate to INInteraction for Siri suggestions
    }

    // MARK: - Live Activities

    /// Start a writing session live activity
    public func startWritingSessionActivity(documentTitle: String, wordGoal: Int?) -> LiveActivityInfo {
        LiveActivityInfo(
            id: UUID(),
            type: .writingSession,
            startTime: Date(),
            data: WritingSessionActivityData(
                documentTitle: documentTitle,
                startWordCount: 0,
                currentWordCount: 0,
                wordGoal: wordGoal,
                elapsedTime: 0
            )
        )
    }

    /// Update live activity
    public func updateLiveActivity(id: UUID, wordCount: Int, elapsedTime: TimeInterval) {
        // Would update the live activity
    }

    /// End live activity
    public func endLiveActivity(id: UUID, finalWordCount: Int) {
        // Would end the live activity
    }
}

// MARK: - Widgets Configuration

public struct WidgetsConfiguration: Codable {
    public var enableWidgets: Bool
    public var enableQuickNotes: Bool
    public var enableLiveActivities: Bool
    public var defaultQuickNoteTag: String?
    public var maxQuickNotes: Int

    public init(
        enableWidgets: Bool = true,
        enableQuickNotes: Bool = true,
        enableLiveActivities: Bool = true,
        defaultQuickNoteTag: String? = nil,
        maxQuickNotes: Int = 100
    ) {
        self.enableWidgets = enableWidgets
        self.enableQuickNotes = enableQuickNotes
        self.enableLiveActivities = enableLiveActivities
        self.defaultQuickNoteTag = defaultQuickNoteTag
        self.maxQuickNotes = maxQuickNotes
    }
}

// MARK: - Widget Configuration

public struct WidgetConfiguration: Identifiable {
    public let id: String
    public let name: String
    public let description: String
    public let supportedFamilies: [WidgetFamily]
    public let refreshInterval: TimeInterval
    public let category: WidgetCategory
    public let previewData: WidgetData

    public init(
        id: String,
        name: String,
        description: String,
        supportedFamilies: [WidgetFamily],
        refreshInterval: TimeInterval,
        category: WidgetCategory,
        previewData: WidgetData
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.supportedFamilies = supportedFamilies
        self.refreshInterval = refreshInterval
        self.category = category
        self.previewData = previewData
    }
}

public enum WidgetFamily: String, Codable {
    case small
    case medium
    case large
    case extraLarge
    case accessoryInline
    case accessoryCircular
    case accessoryRectangular
}

public enum WidgetCategory: String, Codable {
    case progress
    case quickAccess
    case statistics
    case inspiration
}

// MARK: - Active Widget

public struct ActiveWidget: Codable, Identifiable {
    public let id: UUID
    public let configurationId: String
    public let family: WidgetFamily
    public let addedDate: Date

    public init(
        id: UUID = UUID(),
        configurationId: String,
        family: WidgetFamily,
        addedDate: Date = Date()
    ) {
        self.id = id
        self.configurationId = configurationId
        self.family = family
        self.addedDate = addedDate
    }
}

// MARK: - Widget Data Protocol

public protocol WidgetData {}

public struct WordCountWidgetData: WidgetData {
    public let currentWords: Int
    public let goalWords: Int
    public let documentTitle: String?

    public var progress: Double {
        guard goalWords > 0 else { return 0 }
        return min(Double(currentWords) / Double(goalWords), 1.0)
    }
}

public struct StreakWidgetData: WidgetData {
    public let currentStreak: Int
    public let longestStreak: Int
    public let lastWritingDate: Date
    public let status: StreakDisplayStatus

    public enum StreakDisplayStatus {
        case safe, atRisk, critical
    }
}

public struct RecentDocumentsWidgetData: WidgetData {
    public let documents: [RecentDocumentInfo]
}

public struct RecentDocumentInfo: Codable {
    public let id: UUID
    public let title: String
    public let wordCount: Int
    public let lastModified: Date
}

public struct StatsWidgetData: WidgetData {
    public let todayWords: Int
    public let weekWords: Int
    public let monthWords: Int
    public let sessionsThisWeek: Int
}

public struct QuickCaptureWidgetData: WidgetData {
    public let recentCaptures: Int
    public let lastCaptureTime: Date?
}

public struct PromptWidgetData: WidgetData {
    public let prompt: String
    public let category: String
    public let date: Date
}

public struct GoalsWidgetData: WidgetData {
    public let goals: [GoalProgressInfo]
}

public struct GoalProgressInfo {
    public let name: String
    public let progress: Double
    public let target: Int
    public let current: Int
}

public struct AIWidgetData: WidgetData {
    public let lastSuggestion: String?
    public let quickActions: [String]
}

public struct LockScreenProgressData: WidgetData {
    public let progress: Double
}

public struct LockScreenStreakData: WidgetData {
    public let streakDays: Int
}

// MARK: - Quick Note

public struct QuickNote: Codable, Identifiable {
    public let id: UUID
    public var content: String
    public let createdAt: Date
    public let source: QuickNoteSource
    public var linkedDocumentId: UUID?
    public var tags: [String]

    public init(
        id: UUID = UUID(),
        content: String,
        createdAt: Date = Date(),
        source: QuickNoteSource,
        linkedDocumentId: UUID? = nil,
        tags: [String] = []
    ) {
        self.id = id
        self.content = content
        self.createdAt = createdAt
        self.source = source
        self.linkedDocumentId = linkedDocumentId
        self.tags = tags
    }
}

public enum QuickNoteSource: String, Codable {
    case widget
    case siri
    case pencilGesture
    case shareExtension
    case spotlight
    case controlCenter
}

// MARK: - Widget Interaction

public enum WidgetInteractionType {
    case openDocument(UUID)
    case createDocument
    case viewStats
    case continueWriting
    case captureIdea
    case useAI(String)
}

// MARK: - Live Activity

public struct LiveActivityInfo {
    public let id: UUID
    public let type: LiveActivityType
    public let startTime: Date
    public let data: LiveActivityData

    public enum LiveActivityType {
        case writingSession
        case focusMode
        case goalProgress
    }
}

public protocol LiveActivityData {}

public struct WritingSessionActivityData: LiveActivityData {
    public let documentTitle: String
    public var startWordCount: Int
    public var currentWordCount: Int
    public let wordGoal: Int?
    public var elapsedTime: TimeInterval

    public var wordsWritten: Int {
        currentWordCount - startWordCount
    }

    public var progress: Double? {
        guard let goal = wordGoal, goal > 0 else { return nil }
        return min(Double(wordsWritten) / Double(goal), 1.0)
    }
}

// MARK: - Control Center Widget

public struct ControlCenterWidget {
    public let id: String
    public let title: String
    public let icon: String
    public let action: ControlCenterAction

    public enum ControlCenterAction {
        case createDocument
        case openRecent
        case captureNote
        case startFocusMode
    }
}

// MARK: - App Intent Support

public struct WidgetAppIntent {
    public let intentType: String
    public let parameters: [String: Any]

    public static func openDocument(id: UUID) -> WidgetAppIntent {
        WidgetAppIntent(
            intentType: "OpenDocument",
            parameters: ["documentId": id.uuidString]
        )
    }

    public static func createDocument(template: String?) -> WidgetAppIntent {
        WidgetAppIntent(
            intentType: "CreateDocument",
            parameters: template.map { ["template": $0] } ?? [:]
        )
    }

    public static func captureNote() -> WidgetAppIntent {
        WidgetAppIntent(
            intentType: "CaptureNote",
            parameters: [:]
        )
    }

    public static func startWritingSession(goalWords: Int?) -> WidgetAppIntent {
        WidgetAppIntent(
            intentType: "StartWritingSession",
            parameters: goalWords.map { ["goalWords": $0] } ?? [:]
        )
    }
}
