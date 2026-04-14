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

    /// Creates a new `HermesSession` with the provided context and makes it the active session.
    /// - Parameter context: Initial session context containing story metadata and settings; defaults to an empty `HermesContext`.
    /// - Returns: The newly created `HermesSession`, also stored in `currentSession`.
    public func startSession(context: HermesContext = HermesContext()) -> HermesSession {
        let session = HermesSession(context: context)
        currentSession = session
        return session
    }

    /// Ends the active Hermes session by clearing the service's `currentSession`.
    /// If no session is active, this method is a no-op.
    public func endSession() {
        currentSession = nil
    }

    // MARK: - Core Interaction

    /// Generate ideation output for a user's prompt, append the user and Hermes messages (including parsed ideas) to the provided session, and return the raw message plus structured ideas.
    /// - Parameters:
    ///   - prompt: The user's prompt text to send to the Hermes persona.
    ///   - session: The active `HermesSession` to update; this will be trimmed, and the new user and Hermes messages plus parsed ideas will be appended. The session's `lastMessageAt` will be updated on success.
    /// - Returns: A `HermesResponse` containing the session id, the raw Hermes message text, and the parsed `[HermesIdea]`.
    /// - Throws: `HermesError.emptyPrompt` if the prompt is empty after trimming; `HermesError.promptTooLong` if the prompt exceeds `maxPromptLength`; `HermesError.aiServiceFailed` if the AI service call fails.
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

        // Append tone instruction when the session context specifies one
        let effectivePersona: String
        if let tone = session.context.tone {
            effectivePersona = hermesPersona + "\n\nTone instruction: \(tone.promptHint)"
        } else {
            effectivePersona = hermesPersona
        }

        // Call Claude with the Hermes persona as the system prompt and tool support
        let rawResponse: String
        do {
            rawResponse = try await aiService.performAgentTaskWithTools(
                systemPrompt: effectivePersona,
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

    /// Finds a previously generated idea by UUID, requests five deeper variations of it, and generates an expanded Hermes response appended to the session.
    /// - Parameters:
    ///   - ideaId: The UUID of the idea to expand.
    ///   - session: The session to search for the idea and to update with the generated messages.
    /// - Returns: A `HermesResponse` containing the raw Hermes message and the parsed expanded ideas.
    /// - Throws: `HermesError.ideaNotFound(id:)` if no idea with the given `ideaId` exists in the session.
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

    // MARK: - Idea Queries

    /// Returns every idea from all Hermes messages in the session, optionally filtered by type.
    /// - Parameters:
    ///   - session: The session to scan.
    ///   - type: When non-nil, only ideas whose `ideaType` matches are included.
    /// - Returns: A flat array of `HermesIdea` in chronological order.
    public func getAllIdeas(from session: HermesSession, filteredBy type: HermesIdeaType? = nil) -> [HermesIdea] {
        let all = session.messages
            .filter { $0.role == .hermes }
            .flatMap { $0.ideas }
        guard let filter = type else { return all }
        return all.filter { $0.ideaType == filter }
    }

    /// Returns every idea in the session that has been marked as a favourite.
    /// - Parameter session: The session to scan.
    /// - Returns: A flat array of favourite `HermesIdea` in chronological order.
    public func getFavorites(from session: HermesSession) -> [HermesIdea] {
        return session.messages
            .filter { $0.role == .hermes }
            .flatMap { $0.ideas }
            .filter { $0.isFavorite }
    }

    /// Marks an idea in the session as a favourite.
    /// - Parameters:
    ///   - ideaId: UUID of the idea to favourite.
    ///   - session: The session containing the idea; mutated in place.
    /// - Throws: `HermesError.ideaNotFound(id:)` if no idea with that UUID exists.
    public func favoriteIdea(_ ideaId: UUID, in session: inout HermesSession) throws {
        try setFavoriteFlag(ideaId: ideaId, value: true, in: &session)
    }

    /// Removes the favourite mark from an idea in the session.
    /// - Parameters:
    ///   - ideaId: UUID of the idea to un-favourite.
    ///   - session: The session containing the idea; mutated in place.
    /// - Throws: `HermesError.ideaNotFound(id:)` if no idea with that UUID exists.
    public func unfavoriteIdea(_ ideaId: UUID, in session: inout HermesSession) throws {
        try setFavoriteFlag(ideaId: ideaId, value: false, in: &session)
    }

    // MARK: - Session Statistics

    /// Computes aggregated statistics for a Hermes session.
    /// - Parameter session: The session to analyse.
    /// - Returns: A `HermesSessionStats` value summarising the session.
    public func getSessionStats(from session: HermesSession) -> HermesSessionStats {
        let hermesMessages = session.messages.filter { $0.role == .hermes }
        let allIdeas = hermesMessages.flatMap { $0.ideas }

        var countByType: [HermesIdeaType: Int] = [:]
        var favoriteCount = 0
        for idea in allIdeas {
            countByType[idea.ideaType, default: 0] += 1
            if idea.isFavorite { favoriteCount += 1 }
        }

        let duration = session.lastMessageAt.timeIntervalSince(session.startedAt)
        let avgIdeas = hermesMessages.isEmpty
            ? 0.0
            : Double(allIdeas.count) / Double(hermesMessages.count)

        return HermesSessionStats(
            sessionId: session.id,
            messageCount: session.messages.count,
            totalIdeas: allIdeas.count,
            favoriteCount: favoriteCount,
            ideaCountByType: countByType,
            sessionDuration: max(0, duration),
            averageIdeasPerMessage: avgIdeas
        )
    }

    // MARK: - History

    /// Retrieve the session's message history in chronological order.
    /// - Parameter session: The session whose messages are being retrieved.
    /// - Returns: An array of `HermesMessage` in the session's stored order (oldest message first).
    public func getHistory(from session: HermesSession) -> [HermesMessage] {
        return session.messages
    }

    /// Clears all messages from the given session while preserving its other context (e.g., id, metadata, and session settings).
    /// - Parameters:
    ///   - session: The `HermesSession` whose message history will be removed.
    public func clearHistory(for session: inout HermesSession) {
        session.messages.removeAll()
    }

    /// Sets the `isFavorite` flag on an idea inside the session, rebuilding the containing message in place.
    /// - Parameters:
    ///   - ideaId: UUID of the idea to update.
    ///   - value: The new favourite flag value.
    ///   - session: The session to mutate.
    /// - Throws: `HermesError.ideaNotFound(id:)` if the idea does not exist in the session.
    private func setFavoriteFlag(ideaId: UUID, value: Bool, in session: inout HermesSession) throws {
        for msgIdx in session.messages.indices {
            let message = session.messages[msgIdx]
            guard message.role == .hermes else { continue }
            guard let ideaIdx = message.ideas.firstIndex(where: { $0.id == ideaId }) else { continue }
            var updatedIdeas = message.ideas
            updatedIdeas[ideaIdx].isFavorite = value
            session.messages[msgIdx] = HermesMessage(
                id: message.id,
                role: message.role,
                content: message.content,
                ideas: updatedIdeas,
                timestamp: message.timestamp
            )
            return
        }
        throw HermesError.ideaNotFound(id: ideaId)
    }

    /// Validates a user prompt by trimming surrounding whitespace and enforcing non-empty text and the configured maximum length.
    /// - Parameter prompt: The raw user prompt; leading and trailing whitespace and newlines are ignored for validation.
    /// - Throws:
    ///   - `HermesError.emptyPrompt` if the trimmed prompt is empty.
    ///   - `HermesError.promptTooLong` if the trimmed prompt's character count exceeds `maxPromptLength`.

    private func validatePrompt(_ prompt: String) throws {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw HermesError.emptyPrompt
        }
        guard trimmed.count <= maxPromptLength else {
            throw HermesError.promptTooLong
        }
    }

    /// Trims the session's message history to at most `maxHistoryMessages`, removing the oldest messages first.
    /// - Parameter session: The session whose `messages` array will be modified; no change occurs if its count is already within the limit.
    private func trimHistory(_ session: inout HermesSession) {
        if session.messages.count > maxHistoryMessages {
            let excess = session.messages.count - maxHistoryMessages
            session.messages.removeFirst(excess)
        }
    }

    /// Builds the composed user prompt sent to the Hermes AI, including story context, a recent exchange, and the final user turn.
    /// - Parameters:
    ///   - userText: The user's current input to place as the final `User:` line.
    ///   - session: The session whose `context` (genre, logline, current scene, characters, themes) and recent messages are included.
    /// - Returns: A single prompt string containing an optional "Story context" block, an optional "Recent exchange" block with up to the last 6 user/Hermes messages, and a trailing `User: <userText>\nHermes:` line.
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
    /// Parses a raw Hermes AI response containing a numbered list of ideas into an array of `HermesIdea`.
    /// 
    /// The input may include numbered items like `1. Title` or `1. [TYPE] Title`, optional bold markdown (`*`), and multi-line descriptions; descriptions for each idea are concatenated into a single string and the `[TYPE]` tag (when present) is mapped to a `HermesIdeaType`.
    /// - Parameter text: Raw AI response text containing a numbered list of ideas (may include optional `[TYPE]` tags and `*` markdown).
    /// - Returns: An array of `HermesIdea` where each element has a `title`, a combined `description`, and a classified `ideaType`.
    internal func parseIdeas(from text: String) -> [HermesIdea] {
        var ideas: [HermesIdea] = []
        let lines = text.components(separatedBy: "\n")

        var currentTitle: String?
        var currentType: HermesIdeaType = .plotHook
        var descLines: [String] = []

        /// Finalizes the currently buffered idea and appends it to the accumulated ideas.
        /// - Discussion: If no title is present, the function does nothing. Otherwise it builds the idea's description by trimming and joining collected description lines, appends a `HermesIdea` with the buffered title, description, and type to `ideas`, and then clears the buffered title and description lines.
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

    /// Maps a textual idea tag to the corresponding `HermesIdeaType`.
    /// - Parameter tag: The tag text extracted from an AI response (case-insensitive), e.g. "plot hook", "character trait".
    /// - Returns: The matching `HermesIdeaType`; returns `.plotHook` when the tag is unrecognized.
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
