import Foundation

/// User preferences and application settings
public struct AppSettings: Codable, Identifiable {
    public let id: UUID
    public var isDarkModeEnabled: Bool
    public var isAutoSaveEnabled: Bool
    public var autoSaveIntervalSeconds: Int
    public var fontSize: Int
    public var defaultWordCountGoal: Int?
    public var theme: AppTheme
    public var spellCheckEnabled: Bool
    public var grammarCheckEnabled: Bool

    public init(
        id: UUID = UUID(),
        isDarkModeEnabled: Bool = false,
        isAutoSaveEnabled: Bool = true,
        autoSaveIntervalSeconds: Int = 30,
        fontSize: Int = 14,
        defaultWordCountGoal: Int? = nil,
        theme: AppTheme = .system,
        spellCheckEnabled: Bool = true,
        grammarCheckEnabled: Bool = true
    ) {
        self.id = id
        self.isDarkModeEnabled = isDarkModeEnabled
        self.isAutoSaveEnabled = isAutoSaveEnabled
        self.autoSaveIntervalSeconds = autoSaveIntervalSeconds
        self.fontSize = max(8, min(32, fontSize))
        self.defaultWordCountGoal = defaultWordCountGoal
        self.theme = theme
        self.spellCheckEnabled = spellCheckEnabled
        self.grammarCheckEnabled = grammarCheckEnabled
    }
}

/// App theme options
public enum AppTheme: String, Codable {
    case light
    case dark
    case system

    public var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "System"
        }
    }
}
