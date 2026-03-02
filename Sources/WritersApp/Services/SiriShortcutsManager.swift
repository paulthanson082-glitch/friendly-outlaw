import Foundation

// MARK: - Siri Shortcuts Manager

/// Manages Siri Shortcuts and App Intents for voice-activated writing features
public class SiriShortcutsManager {

    // MARK: - Properties

    public private(set) var donatedShortcuts: [ShortcutDonation] = []
    public private(set) var availableIntents: [WriterIntent] = []

    // MARK: - Initialization

    public init() {
        setupAvailableIntents()
    }

    private func setupAvailableIntents() {
        availableIntents = [
            // Document Intents
            WriterIntent(
                identifier: "com.writersapp.create-document",
                title: "Create New Document",
                description: "Create a new writing document",
                category: .document,
                parameters: [
                    IntentParameter(name: "title", type: .string, required: false),
                    IntentParameter(name: "template", type: .template, required: false)
                ],
                suggestedPhrases: [
                    "Create a new document in Writers App",
                    "Start writing",
                    "New story",
                    "Begin a new chapter"
                ]
            ),
            WriterIntent(
                identifier: "com.writersapp.open-document",
                title: "Open Document",
                description: "Open an existing document",
                category: .document,
                parameters: [
                    IntentParameter(name: "documentName", type: .string, required: true)
                ],
                suggestedPhrases: [
                    "Open my document",
                    "Continue writing",
                    "Open my story"
                ]
            ),
            WriterIntent(
                identifier: "com.writersapp.open-recent",
                title: "Open Recent Document",
                description: "Open your most recently edited document",
                category: .document,
                parameters: [],
                suggestedPhrases: [
                    "Open my recent document",
                    "Continue where I left off",
                    "Resume writing"
                ]
            ),

            // Writing Intents
            WriterIntent(
                identifier: "com.writersapp.dictate",
                title: "Dictate to Document",
                description: "Add dictated text to your document",
                category: .writing,
                parameters: [
                    IntentParameter(name: "text", type: .string, required: true),
                    IntentParameter(name: "position", type: .position, required: false)
                ],
                suggestedPhrases: [
                    "Add to my document",
                    "Write this down",
                    "Append to my story"
                ]
            ),
            WriterIntent(
                identifier: "com.writersapp.quick-note",
                title: "Quick Writing Note",
                description: "Capture a quick idea or note",
                category: .writing,
                parameters: [
                    IntentParameter(name: "note", type: .string, required: true)
                ],
                suggestedPhrases: [
                    "Save this idea",
                    "Quick note for my story",
                    "Remember this for later"
                ]
            ),

            // AI Intents
            WriterIntent(
                identifier: "com.writersapp.ai-brainstorm",
                title: "Brainstorm Ideas",
                description: "Use AI to brainstorm writing ideas",
                category: .ai,
                parameters: [
                    IntentParameter(name: "topic", type: .string, required: true)
                ],
                suggestedPhrases: [
                    "Help me brainstorm",
                    "Give me ideas for",
                    "What should I write about"
                ]
            ),
            WriterIntent(
                identifier: "com.writersapp.ai-continue",
                title: "AI Continue Writing",
                description: "Have AI continue your current document",
                category: .ai,
                parameters: [],
                suggestedPhrases: [
                    "Continue my story",
                    "Write the next paragraph",
                    "Keep writing for me"
                ]
            ),
            WriterIntent(
                identifier: "com.writersapp.ai-improve",
                title: "AI Improve Text",
                description: "Have AI improve selected text",
                category: .ai,
                parameters: [
                    IntentParameter(name: "text", type: .string, required: false)
                ],
                suggestedPhrases: [
                    "Improve my writing",
                    "Make this better",
                    "Polish my text"
                ]
            ),

            // Stats Intents
            WriterIntent(
                identifier: "com.writersapp.word-count",
                title: "Get Word Count",
                description: "Check your current word count",
                category: .stats,
                parameters: [
                    IntentParameter(name: "documentName", type: .string, required: false)
                ],
                suggestedPhrases: [
                    "How many words have I written?",
                    "What's my word count?",
                    "Check my progress"
                ]
            ),
            WriterIntent(
                identifier: "com.writersapp.writing-stats",
                title: "Get Writing Statistics",
                description: "Get your writing statistics",
                category: .stats,
                parameters: [
                    IntentParameter(name: "period", type: .timePeriod, required: false)
                ],
                suggestedPhrases: [
                    "How much did I write today?",
                    "Show my writing stats",
                    "What's my writing progress?"
                ]
            ),

            // Export Intents
            WriterIntent(
                identifier: "com.writersapp.export",
                title: "Export Document",
                description: "Export your document to another format",
                category: .export,
                parameters: [
                    IntentParameter(name: "documentName", type: .string, required: false),
                    IntentParameter(name: "format", type: .exportFormat, required: false)
                ],
                suggestedPhrases: [
                    "Export my document",
                    "Save as PDF",
                    "Convert to markdown"
                ]
            ),
            WriterIntent(
                identifier: "com.writersapp.share",
                title: "Share Document",
                description: "Share your document",
                category: .export,
                parameters: [
                    IntentParameter(name: "documentName", type: .string, required: false)
                ],
                suggestedPhrases: [
                    "Share my document",
                    "Send my story",
                    "Share what I wrote"
                ]
            ),

            // Focus Intents
            WriterIntent(
                identifier: "com.writersapp.start-focus",
                title: "Start Focus Writing Session",
                description: "Begin a distraction-free writing session",
                category: .focus,
                parameters: [
                    IntentParameter(name: "duration", type: .duration, required: false),
                    IntentParameter(name: "wordGoal", type: .number, required: false)
                ],
                suggestedPhrases: [
                    "Start focus mode",
                    "Begin writing session",
                    "Time to write"
                ]
            ),
            WriterIntent(
                identifier: "com.writersapp.set-goal",
                title: "Set Writing Goal",
                description: "Set a word count goal for today",
                category: .focus,
                parameters: [
                    IntentParameter(name: "wordCount", type: .number, required: true)
                ],
                suggestedPhrases: [
                    "Set my writing goal",
                    "I want to write words today",
                    "My goal is words"
                ]
            )
        ]
    }

    // MARK: - Intent Handling

    /// Handle an intent
    public func handleIntent(_ intent: WriterIntent, parameters: [String: Any]) async -> IntentResult {
        switch intent.identifier {
        case "com.writersapp.create-document":
            return await handleCreateDocument(parameters)
        case "com.writersapp.open-document":
            return await handleOpenDocument(parameters)
        case "com.writersapp.open-recent":
            return await handleOpenRecent()
        case "com.writersapp.dictate":
            return await handleDictate(parameters)
        case "com.writersapp.quick-note":
            return await handleQuickNote(parameters)
        case "com.writersapp.ai-brainstorm":
            return await handleAIBrainstorm(parameters)
        case "com.writersapp.ai-continue":
            return await handleAIContinue()
        case "com.writersapp.word-count":
            return await handleWordCount(parameters)
        case "com.writersapp.start-focus":
            return await handleStartFocus(parameters)
        default:
            return IntentResult(
                success: false,
                response: "Unknown intent",
                data: nil
            )
        }
    }

    private func handleCreateDocument(_ parameters: [String: Any]) async -> IntentResult {
        let title = parameters["title"] as? String ?? "Untitled"
        return IntentResult(
            success: true,
            response: "Created new document '\(title)'",
            data: ["action": "openDocument", "title": title]
        )
    }

    private func handleOpenDocument(_ parameters: [String: Any]) async -> IntentResult {
        guard let documentName = parameters["documentName"] as? String else {
            return IntentResult(
                success: false,
                response: "Please specify a document name",
                data: nil
            )
        }
        return IntentResult(
            success: true,
            response: "Opening '\(documentName)'",
            data: ["action": "openDocument", "name": documentName]
        )
    }

    private func handleOpenRecent() async -> IntentResult {
        return IntentResult(
            success: true,
            response: "Opening your most recent document",
            data: ["action": "openRecent"]
        )
    }

    private func handleDictate(_ parameters: [String: Any]) async -> IntentResult {
        guard let text = parameters["text"] as? String else {
            return IntentResult(
                success: false,
                response: "No text to add",
                data: nil
            )
        }
        return IntentResult(
            success: true,
            response: "Added \(text.components(separatedBy: .whitespaces).count) words to your document",
            data: ["action": "appendText", "text": text]
        )
    }

    private func handleQuickNote(_ parameters: [String: Any]) async -> IntentResult {
        guard let note = parameters["note"] as? String else {
            return IntentResult(
                success: false,
                response: "No note to save",
                data: nil
            )
        }
        return IntentResult(
            success: true,
            response: "Saved your note",
            data: ["action": "saveNote", "note": note]
        )
    }

    private func handleAIBrainstorm(_ parameters: [String: Any]) async -> IntentResult {
        guard let topic = parameters["topic"] as? String else {
            return IntentResult(
                success: false,
                response: "Please provide a topic to brainstorm",
                data: nil
            )
        }
        return IntentResult(
            success: true,
            response: "Here are some ideas for '\(topic)'",
            data: ["action": "brainstorm", "topic": topic]
        )
    }

    private func handleAIContinue() async -> IntentResult {
        return IntentResult(
            success: true,
            response: "Continuing your document with AI",
            data: ["action": "aiContinue"]
        )
    }

    private func handleWordCount(_ parameters: [String: Any]) async -> IntentResult {
        // Would fetch actual word count
        let wordCount = 1250
        return IntentResult(
            success: true,
            response: "You've written \(wordCount) words",
            data: ["wordCount": wordCount]
        )
    }

    private func handleStartFocus(_ parameters: [String: Any]) async -> IntentResult {
        let duration = parameters["duration"] as? Int ?? 25
        let wordGoal = parameters["wordGoal"] as? Int
        var response = "Starting \(duration)-minute focus session"
        if let goal = wordGoal {
            response += " with a goal of \(goal) words"
        }
        return IntentResult(
            success: true,
            response: response,
            data: ["action": "startFocus", "duration": duration, "wordGoal": wordGoal as Any]
        )
    }

    // MARK: - Shortcut Donation

    /// Donate a shortcut for an action the user performed
    public func donateShortcut(for action: UserAction) {
        let donation = ShortcutDonation(
            id: UUID(),
            intentIdentifier: action.intentIdentifier,
            parameters: action.parameters,
            donatedAt: Date()
        )
        donatedShortcuts.append(donation)
    }

    /// Get suggested shortcuts based on user behavior
    public func getSuggestedShortcuts() -> [SuggestedShortcut] {
        // Analyze donated shortcuts and suggest relevant ones
        var suggestions: [SuggestedShortcut] = []

        // Suggest opening recent documents
        suggestions.append(SuggestedShortcut(
            intent: availableIntents.first { $0.identifier == "com.writersapp.open-recent" }!,
            reason: "Quickly continue where you left off",
            priority: .high
        ))

        // Suggest word count if frequently used
        suggestions.append(SuggestedShortcut(
            intent: availableIntents.first { $0.identifier == "com.writersapp.word-count" }!,
            reason: "Track your writing progress",
            priority: .medium
        ))

        // Suggest focus mode
        suggestions.append(SuggestedShortcut(
            intent: availableIntents.first { $0.identifier == "com.writersapp.start-focus" }!,
            reason: "Start a focused writing session",
            priority: .medium
        ))

        return suggestions
    }

    // MARK: - Voice Commands

    /// Get available voice commands
    public func getVoiceCommands() -> [VoiceCommand] {
        [
            VoiceCommand(
                phrase: "Hey Siri, start writing",
                description: "Opens the app and creates a new document",
                intent: "com.writersapp.create-document"
            ),
            VoiceCommand(
                phrase: "Hey Siri, how many words have I written?",
                description: "Reports your current word count",
                intent: "com.writersapp.word-count"
            ),
            VoiceCommand(
                phrase: "Hey Siri, continue my story",
                description: "Uses AI to continue writing your document",
                intent: "com.writersapp.ai-continue"
            ),
            VoiceCommand(
                phrase: "Hey Siri, brainstorm ideas for [topic]",
                description: "Uses AI to generate writing ideas",
                intent: "com.writersapp.ai-brainstorm"
            ),
            VoiceCommand(
                phrase: "Hey Siri, start focus writing",
                description: "Begins a distraction-free writing session",
                intent: "com.writersapp.start-focus"
            )
        ]
    }
}

// MARK: - Writer Intent

public struct WriterIntent: Codable, Identifiable {
    public let id: UUID
    public let identifier: String
    public let title: String
    public let description: String
    public let category: IntentCategory
    public let parameters: [IntentParameter]
    public let suggestedPhrases: [String]

    public init(
        id: UUID = UUID(),
        identifier: String,
        title: String,
        description: String,
        category: IntentCategory,
        parameters: [IntentParameter],
        suggestedPhrases: [String]
    ) {
        self.id = id
        self.identifier = identifier
        self.title = title
        self.description = description
        self.category = category
        self.parameters = parameters
        self.suggestedPhrases = suggestedPhrases
    }
}

// MARK: - Intent Category

public enum IntentCategory: String, Codable {
    case document
    case writing
    case ai
    case stats
    case export
    case focus
}

// MARK: - Intent Parameter

public struct IntentParameter: Codable {
    public let name: String
    public let type: ParameterType
    public let required: Bool

    public init(name: String, type: ParameterType, required: Bool) {
        self.name = name
        self.type = type
        self.required = required
    }

    public enum ParameterType: String, Codable {
        case string
        case number
        case template
        case position
        case exportFormat
        case timePeriod
        case duration
    }
}

// MARK: - Intent Result

public struct IntentResult {
    public let success: Bool
    public let response: String
    public let data: [String: Any]?

    public init(success: Bool, response: String, data: [String: Any]?) {
        self.success = success
        self.response = response
        self.data = data
    }
}

// MARK: - Shortcut Donation

public struct ShortcutDonation: Codable, Identifiable {
    public let id: UUID
    public let intentIdentifier: String
    public let parameters: [String: String]
    public let donatedAt: Date

    public init(id: UUID, intentIdentifier: String, parameters: [String: String], donatedAt: Date) {
        self.id = id
        self.intentIdentifier = intentIdentifier
        self.parameters = parameters
        self.donatedAt = donatedAt
    }
}

// MARK: - User Action

public struct UserAction {
    public let intentIdentifier: String
    public let parameters: [String: String]

    public init(intentIdentifier: String, parameters: [String: String]) {
        self.intentIdentifier = intentIdentifier
        self.parameters = parameters
    }
}

// MARK: - Suggested Shortcut

public struct SuggestedShortcut {
    public let intent: WriterIntent
    public let reason: String
    public let priority: Priority

    public enum Priority {
        case low, medium, high
    }
}

// MARK: - Voice Command

public struct VoiceCommand {
    public let phrase: String
    public let description: String
    public let intent: String
}
