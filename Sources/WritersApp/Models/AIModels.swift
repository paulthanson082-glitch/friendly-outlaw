import Foundation

// MARK: - AI Configuration

/// Configuration for AI service
public struct AIConfiguration {
    public let apiKey: String
    public let model: AIModel
    public let maxTokens: Int
    public let temperature: Double

    public init(
        apiKey: String,
        model: AIModel = .claude35Sonnet,
        maxTokens: Int = 4096,
        temperature: Double = 0.7
    ) {
        self.apiKey = apiKey
        self.model = model
        self.maxTokens = maxTokens
        self.temperature = temperature
    }
}

/// Available AI models
public enum AIModel: String {
    case claude35Sonnet = "claude-3-5-sonnet-20241022"
    case claude3Opus = "claude-3-opus-20240229"
    case claude3Sonnet = "claude-3-sonnet-20240229"
    case claude3Haiku = "claude-3-haiku-20240307"

    public var displayName: String {
        switch self {
        case .claude35Sonnet: return "Claude 3.5 Sonnet"
        case .claude3Opus: return "Claude 3 Opus"
        case .claude3Sonnet: return "Claude 3 Sonnet"
        case .claude3Haiku: return "Claude 3 Haiku"
        }
    }
}

// MARK: - AI Assistance Types

/// Types of AI writing assistance
public enum AIAssistanceType {
    case continueWriting
    case improveText
    case grammarCheck
    case styleSuggestions
    case generateOutline
    case brainstormIdeas
    case characterDevelopment
    case plotSuggestions
    case dialogueImprovement
    case descriptionEnhancement
    case titleGeneration
    case summarize
    case expandText
    case simplifyText
    case changetone(WritingTone)
    case custom(String)

    public var displayName: String {
        switch self {
        case .continueWriting: return "Continue Writing"
        case .improveText: return "Improve Text"
        case .grammarCheck: return "Grammar Check"
        case .styleSuggestions: return "Style Suggestions"
        case .generateOutline: return "Generate Outline"
        case .brainstormIdeas: return "Brainstorm Ideas"
        case .characterDevelopment: return "Character Development"
        case .plotSuggestions: return "Plot Suggestions"
        case .dialogueImprovement: return "Dialogue Improvement"
        case .descriptionEnhancement: return "Description Enhancement"
        case .titleGeneration: return "Title Generation"
        case .summarize: return "Summarize"
        case .expandText: return "Expand Text"
        case .simplifyText: return "Simplify Text"
        case .changetone(let tone): return "Change Tone to \(tone.displayName)"
        case .custom: return "Custom Request"
        }
    }

    public func prompt(for text: String, context: AIContext? = nil) -> String {
        let contextInfo = context?.description ?? ""

        switch self {
        case .continueWriting:
            return """
            \(contextInfo)
            Continue writing from where this text leaves off. Match the style, tone, and voice. Keep the narrative flowing naturally.

            Current text:
            \(text)

            Continue the writing:
            """

        case .improveText:
            return """
            \(contextInfo)
            Improve this text while maintaining its core message and style. Focus on clarity, flow, and impact.

            Original text:
            \(text)

            Improved version:
            """

        case .grammarCheck:
            return """
            Check this text for grammar, spelling, and punctuation errors. Provide corrections and explanations.

            Text to check:
            \(text)

            Corrections:
            """

        case .styleSuggestions:
            return """
            \(contextInfo)
            Analyze this text and provide specific style improvement suggestions. Consider sentence variety, word choice, rhythm, and readability.

            Text:
            \(text)

            Style suggestions:
            """

        case .generateOutline:
            return """
            \(contextInfo)
            Based on this text or idea, generate a detailed outline for a complete piece.

            Concept:
            \(text)

            Outline:
            """

        case .brainstormIdeas:
            return """
            \(contextInfo)
            Brainstorm creative ideas related to this topic or concept. Provide diverse, interesting angles and approaches.

            Topic:
            \(text)

            Ideas:
            """

        case .characterDevelopment:
            return """
            \(contextInfo)
            Help develop this character idea into a rich, multi-dimensional character. Include backstory, motivations, conflicts, and character arc suggestions.

            Character concept:
            \(text)

            Character development:
            """

        case .plotSuggestions:
            return """
            \(contextInfo)
            Suggest plot developments, twists, or story directions based on this narrative.

            Current story:
            \(text)

            Plot suggestions:
            """

        case .dialogueImprovement:
            return """
            \(contextInfo)
            Improve this dialogue to make it more natural, engaging, and character-revealing. Maintain character voices while enhancing impact.

            Original dialogue:
            \(text)

            Improved dialogue:
            """

        case .descriptionEnhancement:
            return """
            \(contextInfo)
            Enhance this description with more vivid, sensory details and stronger imagery while maintaining the core vision.

            Original description:
            \(text)

            Enhanced description:
            """

        case .titleGeneration:
            return """
            \(contextInfo)
            Generate 10 compelling title options for this piece. Make them attention-grabbing and reflective of the content.

            Content:
            \(text)

            Title options:
            """

        case .summarize:
            return """
            Provide a concise summary of this text, capturing the main points and key themes.

            Text:
            \(text)

            Summary:
            """

        case .expandText:
            return """
            \(contextInfo)
            Expand this text with more detail, examples, and elaboration while maintaining the original meaning and style.

            Original:
            \(text)

            Expanded version:
            """

        case .simplifyText:
            return """
            Simplify this text to make it clearer and more accessible while preserving the core message.

            Original:
            \(text)

            Simplified version:
            """

        case .changetone(let tone):
            return """
            \(contextInfo)
            Rewrite this text in a \(tone.displayName.lowercased()) tone while keeping the core content.

            Original:
            \(text)

            Rewritten in \(tone.displayName.lowercased()) tone:
            """

        case .custom(let instruction):
            return """
            \(contextInfo)
            \(instruction)

            Text:
            \(text)

            Result:
            """
        }
    }
}

/// Writing tone options
public enum WritingTone {
    case professional
    case casual
    case academic
    case creative
    case humorous
    case serious
    case enthusiastic
    case empathetic
    case persuasive
    case informative

    public var displayName: String {
        switch self {
        case .professional: return "Professional"
        case .casual: return "Casual"
        case .academic: return "Academic"
        case .creative: return "Creative"
        case .humorous: return "Humorous"
        case .serious: return "Serious"
        case .enthusiastic: return "Enthusiastic"
        case .empathetic: return "Empathetic"
        case .persuasive: return "Persuasive"
        case .informative: return "Informative"
        }
    }
}

// MARK: - AI Context

/// Context for AI assistance
public struct AIContext {
    public let genre: String?
    public let targetAudience: String?
    public let existingCharacters: [String]?
    public let plotSummary: String?
    public let additionalNotes: String?

    public init(
        genre: String? = nil,
        targetAudience: String? = nil,
        existingCharacters: [String]? = nil,
        plotSummary: String? = nil,
        additionalNotes: String? = nil
    ) {
        self.genre = genre
        self.targetAudience = targetAudience
        self.existingCharacters = existingCharacters
        self.plotSummary = plotSummary
        self.additionalNotes = additionalNotes
    }

    public var description: String {
        var parts: [String] = []

        if let genre = genre {
            parts.append("Genre: \(genre)")
        }
        if let audience = targetAudience {
            parts.append("Target Audience: \(audience)")
        }
        if let characters = existingCharacters, !characters.isEmpty {
            parts.append("Characters: \(characters.joined(separator: ", "))")
        }
        if let plot = plotSummary {
            parts.append("Plot: \(plot)")
        }
        if let notes = additionalNotes {
            parts.append("Notes: \(notes)")
        }

        return parts.isEmpty ? "" : "Context:\n" + parts.joined(separator: "\n") + "\n\n"
    }
}

// MARK: - AI Response

/// Response from AI assistance
public struct AIResponse {
    public let requestType: AIAssistanceType
    public let originalText: String
    public let generatedContent: String
    public let model: AIModel
    public let tokensUsed: Int?
    public let timestamp: Date

    public init(
        requestType: AIAssistanceType,
        originalText: String,
        generatedContent: String,
        model: AIModel,
        tokensUsed: Int? = nil,
        timestamp: Date = Date()
    ) {
        self.requestType = requestType
        self.originalText = originalText
        self.generatedContent = generatedContent
        self.model = model
        self.tokensUsed = tokensUsed
        self.timestamp = timestamp
    }
}
