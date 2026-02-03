import Foundation

// MARK: - Keyboard Shortcut Manager

/// Manages keyboard shortcuts for iPad Pro external keyboard support
public class KeyboardShortcutManager {

    // MARK: - Properties

    private var shortcuts: [KeyboardShortcut] = []
    private var customShortcuts: [UUID: KeyboardShortcut] = [:]

    public var isEnabled: Bool = true

    // MARK: - Initialization

    public init() {
        loadDefaultShortcuts()
    }

    // MARK: - Default Shortcuts

    private func loadDefaultShortcuts() {
        shortcuts = [
            // File operations
            KeyboardShortcut(
                id: UUID(),
                action: .newDocument,
                key: "n",
                modifiers: [.command],
                category: .file,
                description: "Create a new document"
            ),
            KeyboardShortcut(
                id: UUID(),
                action: .openDocument,
                key: "o",
                modifiers: [.command],
                category: .file,
                description: "Open document"
            ),
            KeyboardShortcut(
                id: UUID(),
                action: .save,
                key: "s",
                modifiers: [.command],
                category: .file,
                description: "Save document"
            ),
            KeyboardShortcut(
                id: UUID(),
                action: .saveAs,
                key: "s",
                modifiers: [.command, .shift],
                category: .file,
                description: "Save document as..."
            ),
            KeyboardShortcut(
                id: UUID(),
                action: .export,
                key: "e",
                modifiers: [.command, .shift],
                category: .file,
                description: "Export document"
            ),
            KeyboardShortcut(
                id: UUID(),
                action: .print,
                key: "p",
                modifiers: [.command],
                category: .file,
                description: "Print document"
            ),

            // Edit operations
            KeyboardShortcut(
                id: UUID(),
                action: .undo,
                key: "z",
                modifiers: [.command],
                category: .edit,
                description: "Undo last action"
            ),
            KeyboardShortcut(
                id: UUID(),
                action: .redo,
                key: "z",
                modifiers: [.command, .shift],
                category: .edit,
                description: "Redo last action"
            ),
            KeyboardShortcut(
                id: UUID(),
                action: .cut,
                key: "x",
                modifiers: [.command],
                category: .edit,
                description: "Cut selection"
            ),
            KeyboardShortcut(
                id: UUID(),
                action: .copy,
                key: "c",
                modifiers: [.command],
                category: .edit,
                description: "Copy selection"
            ),
            KeyboardShortcut(
                id: UUID(),
                action: .paste,
                key: "v",
                modifiers: [.command],
                category: .edit,
                description: "Paste from clipboard"
            ),
            KeyboardShortcut(
                id: UUID(),
                action: .selectAll,
                key: "a",
                modifiers: [.command],
                category: .edit,
                description: "Select all text"
            ),
            KeyboardShortcut(
                id: UUID(),
                action: .find,
                key: "f",
                modifiers: [.command],
                category: .edit,
                description: "Find in document"
            ),
            KeyboardShortcut(
                id: UUID(),
                action: .findAndReplace,
                key: "f",
                modifiers: [.command, .option],
                category: .edit,
                description: "Find and replace"
            ),

            // Formatting
            KeyboardShortcut(
                id: UUID(),
                action: .bold,
                key: "b",
                modifiers: [.command],
                category: .formatting,
                description: "Toggle bold"
            ),
            KeyboardShortcut(
                id: UUID(),
                action: .italic,
                key: "i",
                modifiers: [.command],
                category: .formatting,
                description: "Toggle italic"
            ),
            KeyboardShortcut(
                id: UUID(),
                action: .underline,
                key: "u",
                modifiers: [.command],
                category: .formatting,
                description: "Toggle underline"
            ),
            KeyboardShortcut(
                id: UUID(),
                action: .heading1,
                key: "1",
                modifiers: [.command, .option],
                category: .formatting,
                description: "Format as Heading 1"
            ),
            KeyboardShortcut(
                id: UUID(),
                action: .heading2,
                key: "2",
                modifiers: [.command, .option],
                category: .formatting,
                description: "Format as Heading 2"
            ),
            KeyboardShortcut(
                id: UUID(),
                action: .heading3,
                key: "3",
                modifiers: [.command, .option],
                category: .formatting,
                description: "Format as Heading 3"
            ),
            KeyboardShortcut(
                id: UUID(),
                action: .bulletList,
                key: "8",
                modifiers: [.command, .shift],
                category: .formatting,
                description: "Toggle bullet list"
            ),
            KeyboardShortcut(
                id: UUID(),
                action: .numberedList,
                key: "7",
                modifiers: [.command, .shift],
                category: .formatting,
                description: "Toggle numbered list"
            ),
            KeyboardShortcut(
                id: UUID(),
                action: .blockquote,
                key: "9",
                modifiers: [.command, .shift],
                category: .formatting,
                description: "Toggle blockquote"
            ),

            // View controls
            KeyboardShortcut(
                id: UUID(),
                action: .toggleSidebar,
                key: "s",
                modifiers: [.command, .option],
                category: .view,
                description: "Toggle sidebar"
            ),
            KeyboardShortcut(
                id: UUID(),
                action: .toggleAIPanel,
                key: "a",
                modifiers: [.command, .option],
                category: .view,
                description: "Toggle AI assistant panel"
            ),
            KeyboardShortcut(
                id: UUID(),
                action: .toggleFocusMode,
                key: "d",
                modifiers: [.command, .shift],
                category: .view,
                description: "Toggle focus mode"
            ),
            KeyboardShortcut(
                id: UUID(),
                action: .zoomIn,
                key: "+",
                modifiers: [.command],
                category: .view,
                description: "Zoom in"
            ),
            KeyboardShortcut(
                id: UUID(),
                action: .zoomOut,
                key: "-",
                modifiers: [.command],
                category: .view,
                description: "Zoom out"
            ),
            KeyboardShortcut(
                id: UUID(),
                action: .resetZoom,
                key: "0",
                modifiers: [.command],
                category: .view,
                description: "Reset zoom to 100%"
            ),
            KeyboardShortcut(
                id: UUID(),
                action: .fullScreen,
                key: "f",
                modifiers: [.command, .control],
                category: .view,
                description: "Toggle full screen"
            ),

            // AI assistance
            KeyboardShortcut(
                id: UUID(),
                action: .aiContinue,
                key: "return",
                modifiers: [.command],
                category: .ai,
                description: "AI: Continue writing"
            ),
            KeyboardShortcut(
                id: UUID(),
                action: .aiImprove,
                key: "i",
                modifiers: [.command, .shift],
                category: .ai,
                description: "AI: Improve selected text"
            ),
            KeyboardShortcut(
                id: UUID(),
                action: .aiGrammarCheck,
                key: "g",
                modifiers: [.command, .shift],
                category: .ai,
                description: "AI: Check grammar"
            ),
            KeyboardShortcut(
                id: UUID(),
                action: .aiBrainstorm,
                key: "b",
                modifiers: [.command, .shift],
                category: .ai,
                description: "AI: Brainstorm ideas"
            ),
            KeyboardShortcut(
                id: UUID(),
                action: .aiSummarize,
                key: "m",
                modifiers: [.command, .shift],
                category: .ai,
                description: "AI: Summarize text"
            ),
            KeyboardShortcut(
                id: UUID(),
                action: .aiExpand,
                key: "x",
                modifiers: [.command, .shift],
                category: .ai,
                description: "AI: Expand text"
            ),
            KeyboardShortcut(
                id: UUID(),
                action: .aiSimplify,
                key: "l",
                modifiers: [.command, .shift],
                category: .ai,
                description: "AI: Simplify text"
            ),
            KeyboardShortcut(
                id: UUID(),
                action: .aiOutline,
                key: "o",
                modifiers: [.command, .shift],
                category: .ai,
                description: "AI: Generate outline"
            ),
            KeyboardShortcut(
                id: UUID(),
                action: .aiMenu,
                key: "/",
                modifiers: [.command],
                category: .ai,
                description: "Show AI command menu"
            ),

            // Navigation
            KeyboardShortcut(
                id: UUID(),
                action: .goToBeginning,
                key: "home",
                modifiers: [.command],
                category: .navigation,
                description: "Go to beginning of document"
            ),
            KeyboardShortcut(
                id: UUID(),
                action: .goToEnd,
                key: "end",
                modifiers: [.command],
                category: .navigation,
                description: "Go to end of document"
            ),
            KeyboardShortcut(
                id: UUID(),
                action: .goToLine,
                key: "l",
                modifiers: [.command],
                category: .navigation,
                description: "Go to line..."
            ),
            KeyboardShortcut(
                id: UUID(),
                action: .nextDocument,
                key: "}",
                modifiers: [.command, .shift],
                category: .navigation,
                description: "Next document"
            ),
            KeyboardShortcut(
                id: UUID(),
                action: .previousDocument,
                key: "{",
                modifiers: [.command, .shift],
                category: .navigation,
                description: "Previous document"
            ),

            // Tools
            KeyboardShortcut(
                id: UUID(),
                action: .wordCount,
                key: "w",
                modifiers: [.command, .shift],
                category: .tools,
                description: "Show word count"
            ),
            KeyboardShortcut(
                id: UUID(),
                action: .documentInfo,
                key: "i",
                modifiers: [.command, .option],
                category: .tools,
                description: "Show document info"
            ),
            KeyboardShortcut(
                id: UUID(),
                action: .spellCheck,
                key: ":",
                modifiers: [.command],
                category: .tools,
                description: "Check spelling"
            ),
            KeyboardShortcut(
                id: UUID(),
                action: .commandPalette,
                key: "p",
                modifiers: [.command, .shift],
                category: .tools,
                description: "Open command palette"
            ),
            KeyboardShortcut(
                id: UUID(),
                action: .settings,
                key: ",",
                modifiers: [.command],
                category: .tools,
                description: "Open settings"
            ),
        ]
    }

    // MARK: - Public Methods

    /// Get all shortcuts
    public func getAllShortcuts() -> [KeyboardShortcut] {
        return shortcuts + Array(customShortcuts.values)
    }

    /// Get shortcuts by category
    public func getShortcuts(for category: ShortcutCategory) -> [KeyboardShortcut] {
        return getAllShortcuts().filter { $0.category == category }
    }

    /// Find shortcut for a key combination
    public func findShortcut(key: String, modifiers: Set<KeyModifier>) -> KeyboardShortcut? {
        return getAllShortcuts().first { shortcut in
            shortcut.key.lowercased() == key.lowercased() &&
            shortcut.modifiers == modifiers
        }
    }

    /// Add a custom shortcut
    public func addCustomShortcut(_ shortcut: KeyboardShortcut) {
        customShortcuts[shortcut.id] = shortcut
    }

    /// Remove a custom shortcut
    public func removeCustomShortcut(id: UUID) {
        customShortcuts.removeValue(forKey: id)
    }

    /// Update an existing shortcut
    public func updateShortcut(id: UUID, key: String, modifiers: Set<KeyModifier>) -> Bool {
        // Check for conflicts
        if let existing = findShortcut(key: key, modifiers: modifiers), existing.id != id {
            return false
        }

        // Update in custom shortcuts
        if var shortcut = customShortcuts[id] {
            shortcut.key = key
            shortcut.modifiers = modifiers
            customShortcuts[id] = shortcut
            return true
        }

        // Update in default shortcuts
        if let index = shortcuts.firstIndex(where: { $0.id == id }) {
            shortcuts[index].key = key
            shortcuts[index].modifiers = modifiers
            return true
        }

        return false
    }

    /// Reset all shortcuts to defaults
    public func resetToDefaults() {
        customShortcuts.removeAll()
        loadDefaultShortcuts()
    }

    /// Export shortcuts configuration
    public func exportConfiguration() -> Data? {
        let config = ShortcutConfiguration(
            defaultShortcuts: shortcuts,
            customShortcuts: Array(customShortcuts.values)
        )
        return try? JSONEncoder().encode(config)
    }

    /// Import shortcuts configuration
    public func importConfiguration(from data: Data) -> Bool {
        guard let config = try? JSONDecoder().decode(ShortcutConfiguration.self, from: data) else {
            return false
        }
        shortcuts = config.defaultShortcuts
        customShortcuts = Dictionary(uniqueKeysWithValues: config.customShortcuts.map { ($0.id, $0) })
        return true
    }

    /// Get formatted string representation of a shortcut
    public func formatShortcut(_ shortcut: KeyboardShortcut) -> String {
        var parts: [String] = []

        if shortcut.modifiers.contains(.control) { parts.append("^") }
        if shortcut.modifiers.contains(.option) { parts.append("⌥") }
        if shortcut.modifiers.contains(.shift) { parts.append("⇧") }
        if shortcut.modifiers.contains(.command) { parts.append("⌘") }

        parts.append(shortcut.key.uppercased())

        return parts.joined()
    }
}

// MARK: - Keyboard Shortcut Model

/// Represents a keyboard shortcut
public struct KeyboardShortcut: Codable, Identifiable {
    public let id: UUID
    public let action: ShortcutAction
    public var key: String
    public var modifiers: Set<KeyModifier>
    public let category: ShortcutCategory
    public let description: String

    public init(
        id: UUID = UUID(),
        action: ShortcutAction,
        key: String,
        modifiers: Set<KeyModifier>,
        category: ShortcutCategory,
        description: String
    ) {
        self.id = id
        self.action = action
        self.key = key
        self.modifiers = modifiers
        self.category = category
        self.description = description
    }
}

// MARK: - Key Modifiers

/// Keyboard modifiers
public enum KeyModifier: String, Codable, Hashable {
    case command
    case shift
    case option
    case control

    public var symbol: String {
        switch self {
        case .command: return "⌘"
        case .shift: return "⇧"
        case .option: return "⌥"
        case .control: return "^"
        }
    }
}

// MARK: - Shortcut Actions

/// Actions that can be triggered by keyboard shortcuts
public enum ShortcutAction: String, Codable {
    // File
    case newDocument
    case openDocument
    case save
    case saveAs
    case export
    case print
    case close

    // Edit
    case undo
    case redo
    case cut
    case copy
    case paste
    case selectAll
    case find
    case findAndReplace

    // Formatting
    case bold
    case italic
    case underline
    case strikethrough
    case heading1
    case heading2
    case heading3
    case bulletList
    case numberedList
    case blockquote
    case codeBlock
    case link

    // View
    case toggleSidebar
    case toggleAIPanel
    case toggleFocusMode
    case zoomIn
    case zoomOut
    case resetZoom
    case fullScreen
    case showOutline

    // AI
    case aiContinue
    case aiImprove
    case aiGrammarCheck
    case aiBrainstorm
    case aiSummarize
    case aiExpand
    case aiSimplify
    case aiOutline
    case aiMenu
    case aiCharacter
    case aiDialogue

    // Navigation
    case goToBeginning
    case goToEnd
    case goToLine
    case nextDocument
    case previousDocument
    case jumpToSelection

    // Tools
    case wordCount
    case documentInfo
    case spellCheck
    case commandPalette
    case settings
    case help
}

// MARK: - Shortcut Categories

/// Categories for organizing shortcuts
public enum ShortcutCategory: String, Codable, CaseIterable {
    case file
    case edit
    case formatting
    case view
    case ai
    case navigation
    case tools

    public var displayName: String {
        switch self {
        case .file: return "File"
        case .edit: return "Edit"
        case .formatting: return "Formatting"
        case .view: return "View"
        case .ai: return "AI Assistant"
        case .navigation: return "Navigation"
        case .tools: return "Tools"
        }
    }
}

// MARK: - Shortcut Configuration

/// Configuration for saving/loading shortcuts
public struct ShortcutConfiguration: Codable {
    public let defaultShortcuts: [KeyboardShortcut]
    public let customShortcuts: [KeyboardShortcut]

    public init(defaultShortcuts: [KeyboardShortcut], customShortcuts: [KeyboardShortcut]) {
        self.defaultShortcuts = defaultShortcuts
        self.customShortcuts = customShortcuts
    }
}
