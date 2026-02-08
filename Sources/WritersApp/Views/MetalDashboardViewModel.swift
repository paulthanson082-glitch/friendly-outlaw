#if canImport(SwiftUI)
import SwiftUI

// MARK: - Metal Dashboard View Model

/// View model powering the heavy metal iPad Pro dashboard.
/// Bridges WritersApp services into observable state for SwiftUI.
@available(iOS 16.0, macOS 13.0, *)
@MainActor
public class MetalDashboardViewModel: ObservableObject {

    // MARK: - Published State

    // Stats
    @Published public var totalDocuments: Int = 0
    @Published public var totalWords: Int = 0
    @Published public var totalTemplates: Int = 0
    @Published public var averageWordCount: Int = 0
    @Published public var documentsByCategory: [TemplateCategory: Int] = [:]

    // Recent documents
    @Published public var recentDocuments: [Document] = []

    // Goals
    @Published public var activeGoals: [WritingGoal] = []
    @Published public var goalsSummary: GoalsSummary = GoalsSummary()
    @Published public var writingStreak: WritingStreak = WritingStreak()

    // Focus sessions
    @Published public var currentFocusSession: FocusSession? = nil
    @Published public var focusStats: FocusSessionStats = FocusSessionStats()
    @Published public var todayFocusStats: FocusSessionStats = FocusSessionStats()

    // Metal mantra
    @Published public var currentMantra: MetalMantra = MetalMantra.random()

    // Navigation / interaction state
    @Published public var selectedDocument: Document? = nil
    @Published public var showNewDocumentSheet: Bool = false
    @Published public var showTemplateSheet: Bool = false
    @Published public var showGoalSheet: Bool = false
    @Published public var selectedFocusType: FocusSessionType? = nil

    // MARK: - Services

    private let app: WritersApp
    private let focusSessionManager: FocusSessionManager
    private let goalManager: WritingGoalManager

    // MARK: - Init

    public init(
        app: WritersApp = WritersApp(),
        focusSessionManager: FocusSessionManager = FocusSessionManager(),
        goalManager: WritingGoalManager = WritingGoalManager()
    ) {
        self.app = app
        self.focusSessionManager = focusSessionManager
        self.goalManager = goalManager
    }

    // MARK: - Data Loading

    /// Load all dashboard data from services
    public func loadDashboard() {
        loadStats()
        loadRecentDocuments()
        loadGoals()
        loadFocusSessions()
        refreshMantra()
    }

    public func loadStats() {
        let stats = app.getStatistics()
        totalDocuments = stats.totalDocuments
        totalWords = stats.totalWordCount
        averageWordCount = stats.averageWordCount
        totalTemplates = stats.totalTemplates
        documentsByCategory = stats.documentsByCategory
    }

    public func loadRecentDocuments() {
        recentDocuments = app.documentManager.getRecentDocuments(limit: 6)
    }

    public func loadGoals() {
        activeGoals = goalManager.getActiveGoals()
        goalsSummary = goalManager.getSummary()
        writingStreak = goalManager.getStreak()
        goalManager.checkStreakStatus()
    }

    public func loadFocusSessions() {
        currentFocusSession = focusSessionManager.getCurrentSession()
        focusStats = focusSessionManager.getStats()
        todayFocusStats = focusSessionManager.getTodayStats()
    }

    // MARK: - Document Actions

    public func createBlankDocument(title: String, category: TemplateCategory) {
        let doc = app.createBlankDocument(title: title, category: category)
        selectedDocument = doc
        loadStats()
        loadRecentDocuments()
    }

    public func createFromTemplate(templateId: UUID, values: [String: String]) {
        if let doc = app.createDocumentFromTemplate(templateId: templateId, values: values) {
            selectedDocument = doc
            loadStats()
            loadRecentDocuments()
        }
    }

    public func selectDocument(_ document: Document) {
        app.documentManager.markDocumentOpened(id: document.id)
        selectedDocument = document
    }

    public func getAllTemplates() -> [Template] {
        return app.templateManager.getAllTemplates()
    }

    public func getTemplates(for category: TemplateCategory) -> [Template] {
        return app.templateManager.getTemplates(for: category)
    }

    // MARK: - Focus Session Actions

    public func startFocusSession(type: FocusSessionType, documentId: UUID? = nil) {
        let wordCount = selectedDocument?.wordCount ?? 0
        let session = focusSessionManager.startSession(
            type: type,
            documentId: documentId ?? selectedDocument?.id,
            currentWordCount: wordCount
        )
        currentFocusSession = session
        loadFocusSessions()
    }

    public func pauseFocusSession() {
        currentFocusSession = focusSessionManager.pauseSession()
    }

    public func resumeFocusSession(pausedDuration: TimeInterval = 0) {
        currentFocusSession = focusSessionManager.resumeSession(pausedDuration: pausedDuration)
    }

    public func endFocusSession(finalWordCount: Int? = nil) {
        guard let session = currentFocusSession else { return }
        let wordCount = finalWordCount ?? selectedDocument?.wordCount ?? session.wordsAtStart
        _ = focusSessionManager.endSession(id: session.id, finalWordCount: wordCount)
        currentFocusSession = nil
        loadFocusSessions()
    }

    // MARK: - Goal Actions

    public func createDailyGoal(target: Int) {
        _ = goalManager.createDailyWordGoal(target: target)
        loadGoals()
    }

    public func recordGoalProgress(goalId: UUID, amount: Int) {
        _ = goalManager.recordProgress(goalId: goalId, amount: amount)
        loadGoals()
    }

    // MARK: - Mantra

    public func refreshMantra() {
        currentMantra = MetalMantra.random()
    }

    // MARK: - Formatting Helpers

    public func formatDuration(_ seconds: TimeInterval) -> String {
        return FocusSessionManager.formatDuration(seconds)
    }

    public func formatTimeRemaining(_ seconds: TimeInterval) -> String {
        return FocusSessionManager.formatTimeRemaining(seconds)
    }

    /// Category icon mapping with metal flair
    public func iconForCategory(_ category: TemplateCategory) -> String {
        switch category {
        case .novel: return "book.closed.fill"
        case .shortStory: return "text.book.closed.fill"
        case .screenplay: return "film.fill"
        case .blogPost: return "globe"
        case .article: return "newspaper.fill"
        case .essay: return "doc.text.fill"
        case .poetry: return "quote.bubble.fill"
        case .businessLetter: return "envelope.fill"
        case .proposal: return "doc.badge.plus"
        case .resume: return "person.text.rectangle.fill"
        case .other: return "folder.fill"
        }
    }

    /// Focus session type icon
    public func iconForFocusType(_ type: FocusSessionType) -> String {
        switch type {
        case .freeWrite: return "flame.fill"
        case .pomodoro: return "timer"
        case .sprint: return "bolt.fill"
        case .deepWork: return "moon.fill"
        }
    }
}

#endif
