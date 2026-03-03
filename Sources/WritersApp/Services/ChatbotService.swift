import Foundation

// MARK: - Chatbot Service

/// Jules - Personal Assistant Chatbot Service
/// Provides conversational AI assistance with document context awareness
public class ChatbotService {
    // MARK: - Public Properties

    public var currentSession: ConversationSession?
    public let maxHistoryMessages: Int
    public let maxMessageLength: Int

    // MARK: - Private Properties

    private let aiService: AIService
    private let documentManager: DocumentManager
    private let templateManager: TemplateManager

    // MARK: - Initialization

    public init(
        aiService: AIService,
        documentManager: DocumentManager,
        templateManager: TemplateManager,
        maxHistoryMessages: Int = 50,
        maxMessageLength: Int = 4000
    ) {
        self.aiService = aiService
        self.documentManager = documentManager
        self.templateManager = templateManager
        self.maxHistoryMessages = maxHistoryMessages
        self.maxMessageLength = maxMessageLength
    }

    // MARK: - Public Interface

    /// Start a new conversation session
    public func startSession(context: ConversationContext? = nil) -> ConversationSession {
        let session = ConversationSession(
            context: context ?? ConversationContext()
        )
        currentSession = session
        return session
    }

    /// Send a message to Jules and get a response
    public func sendMessage(
        _ userMessage: String,
        in session: inout ConversationSession
    ) async throws -> String {
        // Validate input
        try validateMessage(userMessage)

        // Add user message to history
        let userChatMessage = ChatMessage(
            role: .user,
            content: userMessage,
            timestamp: Date()
        )
        session.messages.append(userChatMessage)

        // Trim history if needed
        trimConversationHistory(&session)

        // Get AI response
        let assistantResponse = try await getAIResponse(
            from: userMessage,
            context: session
        )

        // Add assistant response to history
        let assistantMessage = ChatMessage(
            role: .assistant,
            content: assistantResponse,
            timestamp: Date()
        )
        session.messages.append(assistantMessage)
        session.lastMessageAt = Date()

        return assistantResponse
    }

    /// Get conversation history
    public func getConversationHistory(from session: ConversationSession) -> [ChatMessage] {
        return session.messages
    }

    /// Clear conversation history (keep context)
    public func clearHistory(for session: inout ConversationSession) {
        session.messages.removeAll()
    }

    /// End current session
    public func endSession() {
        currentSession = nil
    }

    // MARK: - Conversation Management

    private func trimConversationHistory(_ session: inout ConversationSession) {
        if session.messages.count > maxHistoryMessages {
            let excess = session.messages.count - maxHistoryMessages
            session.messages.removeFirst(excess)
        }
    }

    // MARK: - Message Processing

    private func validateMessage(_ message: String) throws {
        let trimmed = message.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            throw ChatbotError.emptyMessage
        }
        guard trimmed.count <= maxMessageLength else {
            throw ChatbotError.messageTooLong
        }
    }

    private func buildPrompt(
        userMessage: String,
        context: ConversationSession
    ) -> String {
        var prompt = "You are Jules, a helpful personal assistant for writers. "
        prompt += "You help with writing, provide feedback, and assist with creative tasks. "
        prompt += "Be supportive, encouraging, and provide practical advice.\n\n"

        // Add context if available
        if let activeDocId = context.context.activeDocumentId,
           let activeDoc = documentManager.getDocument(id: activeDocId) {
            prompt += "The user is currently working on: \(activeDoc.title)\n"
            prompt += "Word count: \(activeDoc.wordCount)\n"
            if !activeDoc.content.isEmpty {
                let preview = String(activeDoc.content.prefix(500))
                prompt += "Content preview: \(preview)...\n"
            }
            prompt += "\n"
        }

        // Add recent conversation context
        if context.messages.count > 0 {
            prompt += "Recent conversation:\n"
            let recentMessages = context.messages.suffix(6)
            for message in recentMessages {
                let role = message.role == .user ? "User" : "Jules"
                prompt += "\(role): \(message.content)\n"
            }
            prompt += "\n"
        }

        prompt += "User: \(userMessage)\nJules:"
        return prompt
    }

    private func getAIResponse(
        from userMessage: String,
        context: ConversationSession
    ) async throws -> String {
        let prompt = buildPrompt(userMessage: userMessage, context: context)

        let response = try await aiService.getAssistance(
            text: prompt,
            type: .custom("conversation"),
            context: nil
        )

        return response.text.trimmingCharacters(in: .whitespaces)
    }
}
