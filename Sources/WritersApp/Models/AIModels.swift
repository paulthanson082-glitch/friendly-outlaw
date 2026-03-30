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
public enum AIModel: String, Codable {
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
    // Hallucination-reducing techniques
    case extractQuotes
    case verifyWithCitations
    case analyzeWithUncertainty
    case chainOfThoughtVerification

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
        case .extractQuotes: return "Extract Quotes"
        case .verifyWithCitations: return "Verify with Citations"
        case .analyzeWithUncertainty: return "Analyze with Uncertainty"
        case .chainOfThoughtVerification: return "Chain of Thought Verification"
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

            Important: Only suggest improvements that you're confident about. If you're unsure about any change, note your uncertainty.

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

            Important: Only suggest ideas that are feasible and well-grounded. If you're proposing something speculative, mark it as such.

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

        case .extractQuotes:
            return """
            Extract the most relevant and important quotes from this text. For each quote:
            1. Provide the exact text in quotation marks
            2. Provide the page or section reference if available
            3. Explain why this quote is relevant

            If there are fewer than 3 significant quotes, list what you found. If you cannot find relevant quotes, state "No significant quotes found."

            Text:
            \(text)

            Relevant quotes:
            """

        case .verifyWithCitations:
            return """
            Analyze this document and provide citations for each claim. For each major claim:
            1. State the claim
            2. Find supporting evidence from the provided material
            3. Quote the exact passage that supports it
            4. If you cannot find supporting evidence, state "No supporting evidence found for this claim"

            Do not include claims that you cannot verify from the material. If unsure about any claim, acknowledge the uncertainty.

            Document:
            \(text)

            Verified claims with citations:
            """

        case .analyzeWithUncertainty:
            return """
            Analyze this text, but importantly: you are permitted and encouraged to say "I don't have enough information to assess this" or "I'm uncertain about X" when appropriate.

            Provide your analysis below, being clear about:
            - What you can confidently assess based on the information provided
            - What you are uncertain about
            - What information would be needed for a more complete analysis

            Text:
            \(text)

            Analysis:
            """

        case .chainOfThoughtVerification:
            return """
            Analyze this document using step-by-step reasoning. For each major point:
            1. State the claim or observation
            2. Show your reasoning step-by-step
            3. Identify what assumptions you're making
            4. Note any uncertainties in your analysis
            5. State your conclusion

            If at any point you realize a claim may not be well-supported, explicitly note this.

            Document:
            \(text)

            Step-by-step analysis:
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

// MARK: - Tool Definitions

/// Definition of a tool that the AI can use during the tool loop
public struct ToolDefinition {
    public let name: String
    public let description: String
    public let inputSchema: [String: Any]

    public init(name: String, description: String, inputSchema: [String: Any]) {
        self.name = name
        self.description = description
        self.inputSchema = inputSchema
    }

    /// Convert to dictionary format for the Claude API request body
    public func toDict() -> [String: Any] {
        return [
            "name": name,
            "description": description,
            "input_schema": inputSchema
        ]
    }
}

/// A tool use request parsed from an AI response content block
public struct ToolUseBlock {
    public let id: String
    public let name: String
    public let input: [String: Any]

    public init?(from dict: [String: Any]) {
        guard let type = dict["type"] as? String, type == "tool_use",
              let id = dict["id"] as? String,
              let name = dict["name"] as? String else {
            return nil
        }
        self.id = id
        self.name = name
        self.input = dict["input"] as? [String: Any] ?? [:]
    }
}

/// Result of executing a tool, sent back to the API
public struct ToolResult {
    public let toolUseId: String
    public let content: String
    public let isError: Bool

    public init(toolUseId: String, content: String, isError: Bool = false) {
        self.toolUseId = toolUseId
        self.content = content
        self.isError = isError
    }

    /// Convert to dictionary format for the Claude API request body
    public func toDict() -> [String: Any] {
        var dict: [String: Any] = [
            "type": "tool_result",
            "tool_use_id": toolUseId,
            "content": content
        ]
        if isError {
            dict["is_error"] = true
        }
        return dict
    }
}

/// Protocol for executing tools in the tool loop
public protocol AIToolExecutor {
    /// Execute a tool by name with the given input parameters
    func executeTool(name: String, input: [String: Any]) async throws -> String
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

// MARK: - Hallucination Reduction Types

/// A quote extracted from source material with citation information
public struct QuoteBlock: Codable {
    public let text: String
    public let reference: String?
    public let relevanceExplanation: String

    public init(text: String, reference: String? = nil, relevanceExplanation: String) {
        self.text = text
        self.reference = reference
        self.relevanceExplanation = relevanceExplanation
    }
}

/// A claim with supporting evidence and citations
public struct VerifiedClaim: Codable {
    public let claim: String
    public let supportingQuote: String?
    public let evidence: String
    public let isVerified: Bool
    public let uncertaintyNote: String?

    public init(
        claim: String,
        supportingQuote: String? = nil,
        evidence: String,
        isVerified: Bool,
        uncertaintyNote: String? = nil
    ) {
        self.claim = claim
        self.supportingQuote = supportingQuote
        self.evidence = evidence
        self.isVerified = isVerified
        self.uncertaintyNote = uncertaintyNote
    }
}

/// Analysis with explicit uncertainty acknowledgment
public struct UncertaintyAwareAnalysis: Codable {
    public let analysis: String
    public let confidenceAreas: [String]
    public let uncertainAreas: [String]
    public let informationGaps: [String]

    public init(
        analysis: String,
        confidenceAreas: [String] = [],
        uncertainAreas: [String] = [],
        informationGaps: [String] = []
    ) {
        self.analysis = analysis
        self.confidenceAreas = confidenceAreas
        self.uncertainAreas = uncertainAreas
        self.informationGaps = informationGaps
    }
}

/// Step-by-step reasoning with explicit assumptions and uncertainties
public struct ChainOfThoughtAnalysis: Codable {
    public let reasoning: String
    public let steps: [ReasoningStep]
    public let assumptions: [String]
    public let uncertainties: [String]
    public let conclusion: String

    public init(
        reasoning: String,
        steps: [ReasoningStep] = [],
        assumptions: [String] = [],
        uncertainties: [String] = [],
        conclusion: String
    ) {
        self.reasoning = reasoning
        self.steps = steps
        self.assumptions = assumptions
        self.uncertainties = uncertainties
        self.conclusion = conclusion
    }
}

/// A single step in chain-of-thought reasoning
public struct ReasoningStep: Codable {
    public let claim: String
    public let reasoning: String
    public let assumptions: [String]
    public let uncertainty: String?

    public init(
        claim: String,
        reasoning: String,
        assumptions: [String] = [],
        uncertainty: String? = nil
    ) {
        self.claim = claim
        self.reasoning = reasoning
        self.assumptions = assumptions
        self.uncertainty = uncertainty
    }
}

// MARK: - Computer Use

/// Represents a computer use action type that Claude can request
public enum ComputerUseActionType: String, Codable {
    case screenshot
    case leftClick = "left_click"
    case rightClick = "right_click"
    case doubleClick = "double_click"
    case middleClick = "middle_click"
    case leftClickDrag = "left_click_drag"
    case mouseMoveAction = "mouse_move"
    case keypress
    case type
    case scroll
    case wait
    case cursorPosition = "cursor_position"
}

/// A computer use action requested by Claude
public struct ComputerUseAction: Codable {
    public let action: ComputerUseActionType
    public let coordinate: [Int]?      // [x, y] for mouse actions
    public let startCoordinate: [Int]? // [x, y] for drag start
    public let text: String?           // for type/keypress actions
    public let key: String?            // for keypress (e.g. "Return", "ctrl+c")
    public let direction: String?      // "up" | "down" | "left" | "right" for scroll
    public let amount: Int?            // scroll amount
    public let duration: Int?          // wait duration in ms

    public init(action: ComputerUseActionType, coordinate: [Int]? = nil,
                startCoordinate: [Int]? = nil, text: String? = nil,
                key: String? = nil, direction: String? = nil,
                amount: Int? = nil, duration: Int? = nil) {
        self.action = action
        self.coordinate = coordinate
        self.startCoordinate = startCoordinate
        self.text = text
        self.key = key
        self.direction = direction
        self.amount = amount
        self.duration = duration
    }
}

/// Result of executing a computer use action
public struct ComputerUseResult {
    public let action: ComputerUseAction
    public let screenshotBase64: String? // PNG screenshot after action (base64)
    public let error: String?

    public init(action: ComputerUseAction, screenshotBase64: String? = nil, error: String? = nil) {
        self.action = action
        self.screenshotBase64 = screenshotBase64
        self.error = error
    }
}

/// Configuration for computer use sessions
public struct ComputerUseConfiguration {
    public let displayWidth: Int
    public let displayHeight: Int
    public let maxIterations: Int
    public let screenshotDelay: Double // seconds to wait after action before screenshot

    public init(displayWidth: Int = 1024, displayHeight: Int = 768,
                maxIterations: Int = 20, screenshotDelay: Double = 0.5) {
        self.displayWidth = displayWidth
        self.displayHeight = displayHeight
        self.maxIterations = maxIterations
        self.screenshotDelay = screenshotDelay
    }
}
