import Foundation

// MARK: - Hermes Service

/// Hermes — Creative Idea Generator Agent
///
/// Hermes is a stateful, session-based AI agent specialising in creative ideation.
/// It helps writers overcome creative blocks by generating structured ideas: plot hooks,
/// character traits, twists, worldbuilding details, dialogue seeds, and more.
///
/// Each response includes both raw text and a parsed `[HermesIdea]` array, giving
/// callers structured creative output they can display, store, or act on.
///
/// Usage:
/// ```swift
/// var session = hermesService.startSession(context: HermesContext(genre: "Fantasy"))
/// let response = try await hermesService.generateIdeas("I'm stuck on my dragon story", in: &session)
/// print(response.ideas.map(\.title))
/// ```
public class HermesService {

    // MARK: - Public Properties

    public var currentSession: HermesSession?
    public let maxHistoryMessages: Int
    public let maxPromptLength: Int

    // MARK: - Private Properties

    private let aiService: AIService
    private let toolExecutor: WritingToolExecutor

    private let hermesPersona = """
        You are Hermes, a creative muse for writers. You are energetic, imaginative, and swift — \
        you generate ideas fast, with contagious enthusiasm. Your sole purpose is to spark \
        creative breakthroughs.

        When generating ideas, ALWAYS format your response as a numbered list. Each item must \
        follow this exact pattern:
          1. [TYPE] Title of Idea
             Brief 1–3 sentence description expanding on the idea.

        Valid TYPE tags: [PLOT HOOK] [CHARACTER TRAIT] [WORLD BUILDING] [CONFLICT] [TWIST] \
        [DIALOGUE] [SETTING] [THEME]

        After the list you may add a short 2–3 sentence narrative riff connecting the ideas, \
        but the numbered list must come first. Be bold. Be surprising. Writers come to you \
        when they are stuck — give them ideas worth stealing.
        """

    // MARK: - Initialization

    public init(
        aiService: AIService,
        documentManager: DocumentManager,
        templateManager: TemplateManager,
        maxHistoryMessages: Int = 30,
        maxPromptLength: Int = 4000
    ) {
        self.aiService = aiService
        self.toolExecutor = WritingToolExecutor(
            documentManager: documentManager,
            templateManager: templateManager
        )
        self.maxHistoryMessages = maxHistoryMessages
        self.maxPromptLength = maxPromptLength
    }

    // MARK: - Session Lifecycle

    /// Start a new Hermes ideation session
    public func startSession(context: HermesContext = HermesContext()) -> HermesSession {
        let session = HermesSession(context: context)
        currentSession = session
        return session
    }

    /// End the current session
    public func endSession() {
        currentSession = nil
    }

    // MARK: - Core Interaction

    /// Send a creative prompt to Hermes and receive structured ideas
    public func generateIdeas(
        _ prompt: String,
        in session: inout HermesSession
    ) async throws -> HermesResponse {
        try validatePrompt(prompt)

        // Build the prompt from existing history BEFORE appending the new user
        // message — otherwise the current turn would appear twice (once in the
        // history block and once as the final "User: …\nHermes:" line).
        trimHistory(&session)
        let userPrompt = buildUserPrompt(userText: prompt, session: session)

        // Call Claude with the Hermes persona as the system prompt and tool support
        let rawResponse: String
        do {
            rawResponse = try await aiService.performAgentTaskWithTools(
                systemPrompt: hermesPersona,
                userPrompt: userPrompt,
                tools: WritingToolExecutor.tools,
                toolExecutor: toolExecutor
            )
        } catch {
            throw HermesError.aiServiceFailed(error.localizedDescription)
        }

        // Persist both messages only after a successful round-trip so a failed
        // API call never corrupts the session history.
        let ideas = parseIdeas(from: rawResponse)
        session.messages.append(HermesMessage(role: .user, content: prompt))
        session.messages.append(HermesMessage(role: .hermes, content: rawResponse, ideas: ideas))
        session.lastMessageAt = Date()

        return HermesResponse(
            sessionId: session.id,
            message: rawResponse,
            ideas: ideas
        )
    }

    /// Expand on a specific idea by its UUID, generating deeper variations
    public func expandIdea(
        _ ideaId: UUID,
        in session: inout HermesSession
    ) async throws -> HermesResponse {
        // Search in reverse (most recent first), only Hermes messages contain ideas
        let idea = session.messages
            .reversed()
            .filter { $0.role == .hermes }
            .flatMap { $0.ideas }
            .first { $0.id == ideaId }

        guard let found = idea else {
            throw HermesError.ideaNotFound(id: ideaId)
        }

        let expansionPrompt = """
            Expand on the idea "\(found.title)": \(found.description)
            Explore it from multiple angles — plot, character, theme — and give me \
            5 deeper variations that take it somewhere unexpected.
            """

        return try await generateIdeas(expansionPrompt, in: &session)
    }

    // MARK: - History

    /// Return all messages in a session
    public func getHistory(from session: HermesSession) -> [HermesMessage] {
        return session.messages
    }

    /// Clear all messages in a session (context is preserved)
    public func clearHistory(for session: inout HermesSession) {
        session.messages.removeAll()
    }

    // MARK: - Private Helpers

    private func validatePrompt(_ prompt: String) throws {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw HermesError.emptyPrompt
        }
        guard trimmed.count <= maxPromptLength else {
            throw HermesError.promptTooLong
        }
    }

    private func trimHistory(_ session: inout HermesSession) {
        if session.messages.count > maxHistoryMessages {
            let excess = session.messages.count - maxHistoryMessages
            session.messages.removeFirst(excess)
        }
    }

    private func buildUserPrompt(userText: String, session: HermesSession) -> String {
        var prompt = ""
        let ctx = session.context

        // Context block — always included so trimming never loses story setup
        if !ctx.genre.isEmpty || !ctx.logline.isEmpty || !ctx.currentScene.isEmpty
            || !ctx.characters.isEmpty || !ctx.themes.isEmpty {
            prompt += "Story context:\n"
            if !ctx.genre.isEmpty { prompt += "Genre: \(ctx.genre)\n" }
            if !ctx.logline.isEmpty { prompt += "Logline: \(ctx.logline)\n" }
            if !ctx.currentScene.isEmpty { prompt += "Current scene: \(ctx.currentScene)\n" }
            if !ctx.characters.isEmpty { prompt += "Characters: \(ctx.characters.joined(separator: ", "))\n" }
            if !ctx.themes.isEmpty { prompt += "Themes: \(ctx.themes.joined(separator: ", "))\n" }
            prompt += "\n"
        }

        // History block — last 6 messages for conversational context
        let hermesMessages = session.messages.filter { $0.role == .hermes || $0.role == .user }
        let recentMessages = hermesMessages.suffix(6)
        if !recentMessages.isEmpty {
            prompt += "Recent exchange:\n"
            for message in recentMessages {
                let label = message.role == .user ? "User" : "Hermes"
                prompt += "\(label): \(message.content)\n"
            }
            prompt += "\n"
        }

        prompt += "User: \(userText)\nHermes:"
        return prompt
    }

    /// Parse a numbered idea list from Hermes's raw response text.
    /// Exposed as `internal` so tests can call it directly without an API key.
    internal func parseIdeas(from text: String) -> [HermesIdea] {
        var ideas: [HermesIdea] = []
        let lines = text.components(separatedBy: "\n")

        var currentTitle: String?
        var currentType: HermesIdeaType = .plotHook
        var descLines: [String] = []

        func flush() {
            guard let title = currentTitle, !title.isEmpty else { return }
            let desc = descLines
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
                .joined(separator: " ")
            ideas.append(HermesIdea(title: title, description: desc, ideaType: currentType))
            descLines = []
            currentTitle = nil
        }

        for line in lines {
            // Strip bold markdown (* chars) Claude sometimes emits
            let cleaned = line.replacingOccurrences(of: "*", with: "")
            let trimmed = cleaned.trimmingCharacters(in: .whitespaces)

            // Detect numbered item: "1. [TAG] Title" or "1. Title"
            if trimmed.range(of: #"^\d+\.\s+"#, options: .regularExpression) != nil,
               let range = trimmed.range(of: #"^\d+\.\s+"#, options: .regularExpression) {
                flush()
                let rest = String(trimmed[range.upperBound...])

                if rest.hasPrefix("["), let closeIdx = rest.firstIndex(of: "]") {
                    let tagRaw = String(rest[rest.index(after: rest.startIndex)..<closeIdx])
                    currentType = classifyIdeaType(from: tagRaw)
                    currentTitle = String(rest[rest.index(after: closeIdx)...])
                        .trimmingCharacters(in: .whitespaces)
                } else {
                    currentType = .plotHook
                    currentTitle = rest.trimmingCharacters(in: .whitespaces)
                }
            } else if currentTitle != nil, !trimmed.isEmpty {
                descLines.append(trimmed)
            }
        }
        flush()
        return ideas
    }

    private func classifyIdeaType(from tag: String) -> HermesIdeaType {
        switch tag.lowercased() {
        case "plot hook":       return .plotHook
        case "character trait": return .characterTrait
        case "world building":  return .worldBuilding
        case "conflict":        return .conflict
        case "twist":           return .twist
        case "dialogue":        return .dialogue
        case "setting":         return .setting
        case "theme":           return .theme
        default:                return .plotHook
        }
    }
}
