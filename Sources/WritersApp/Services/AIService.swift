import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Service for AI-powered writing assistance using Claude API
public class AIService {
    private let configuration: AIConfiguration
    private let apiURL = "https://api.anthropic.com/v1/messages"

    public init(configuration: AIConfiguration) {
        self.configuration = configuration
    }

    // MARK: - Main Assistance Methods

    /// Get AI assistance for writing tasks
    public func getAssistance(
        text: String,
        type: AIAssistanceType,
        context: AIContext? = nil
    ) async throws -> AIResponse {
        let prompt = type.prompt(for: text, context: context)
        let generatedContent = try await sendRequest(prompt: prompt)

        return AIResponse(
            requestType: type,
            originalText: text,
            generatedContent: generatedContent,
            model: configuration.model
        )
    }

    /// Continue writing from existing text
    public func continueWriting(
        text: String,
        context: AIContext? = nil
    ) async throws -> String {
        let response = try await getAssistance(
            text: text,
            type: .continueWriting,
            context: context
        )
        return response.generatedContent
    }

    /// Improve existing text
    public func improveText(
        text: String,
        context: AIContext? = nil
    ) async throws -> String {
        let response = try await getAssistance(
            text: text,
            type: .improveText,
            context: context
        )
        return response.generatedContent
    }

    /// Check grammar and spelling
    public func checkGrammar(text: String) async throws -> String {
        let response = try await getAssistance(
            text: text,
            type: .grammarCheck
        )
        return response.generatedContent
    }

    /// Get style suggestions
    public func getStyleSuggestions(
        text: String,
        context: AIContext? = nil
    ) async throws -> String {
        let response = try await getAssistance(
            text: text,
            type: .styleSuggestions,
            context: context
        )
        return response.generatedContent
    }

    /// Generate outline from concept
    public func generateOutline(
        concept: String,
        context: AIContext? = nil
    ) async throws -> String {
        let response = try await getAssistance(
            text: concept,
            type: .generateOutline,
            context: context
        )
        return response.generatedContent
    }

    /// Brainstorm ideas
    public func brainstormIdeas(
        topic: String,
        context: AIContext? = nil
    ) async throws -> String {
        let response = try await getAssistance(
            text: topic,
            type: .brainstormIdeas,
            context: context
        )
        return response.generatedContent
    }

    /// Develop character
    public func developCharacter(
        characterConcept: String,
        context: AIContext? = nil
    ) async throws -> String {
        let response = try await getAssistance(
            text: characterConcept,
            type: .characterDevelopment,
            context: context
        )
        return response.generatedContent
    }

    /// Get plot suggestions
    public func suggestPlot(
        currentStory: String,
        context: AIContext? = nil
    ) async throws -> String {
        let response = try await getAssistance(
            text: currentStory,
            type: .plotSuggestions,
            context: context
        )
        return response.generatedContent
    }

    /// Improve dialogue
    public func improveDialogue(
        dialogue: String,
        context: AIContext? = nil
    ) async throws -> String {
        let response = try await getAssistance(
            text: dialogue,
            type: .dialogueImprovement,
            context: context
        )
        return response.generatedContent
    }

    /// Enhance description
    public func enhanceDescription(
        description: String,
        context: AIContext? = nil
    ) async throws -> String {
        let response = try await getAssistance(
            text: description,
            type: .descriptionEnhancement,
            context: context
        )
        return response.generatedContent
    }

    /// Generate title options
    public func generateTitles(
        content: String,
        context: AIContext? = nil
    ) async throws -> [String] {
        let response = try await getAssistance(
            text: content,
            type: .titleGeneration,
            context: context
        )
        // Parse the response to extract individual titles
        return response.generatedContent
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { title in
                // Remove numbering like "1. " or "1) "
                title.replacingOccurrences(of: "^\\d+[.):]\\s*", with: "", options: .regularExpression)
            }
    }

    /// Summarize text
    public func summarize(text: String) async throws -> String {
        let response = try await getAssistance(
            text: text,
            type: .summarize
        )
        return response.generatedContent
    }

    /// Expand text with more detail
    public func expandText(
        text: String,
        context: AIContext? = nil
    ) async throws -> String {
        let response = try await getAssistance(
            text: text,
            type: .expandText,
            context: context
        )
        return response.generatedContent
    }

    /// Simplify text
    public func simplifyText(text: String) async throws -> String {
        let response = try await getAssistance(
            text: text,
            type: .simplifyText
        )
        return response.generatedContent
    }

    /// Change tone of text
    public func changeTone(
        text: String,
        tone: WritingTone,
        context: AIContext? = nil
    ) async throws -> String {
        let response = try await getAssistance(
            text: text,
            type: .changetone(tone),
            context: context
        )
        return response.generatedContent
    }

    /// Custom AI request
    public func customRequest(
        text: String,
        instruction: String,
        context: AIContext? = nil
    ) async throws -> String {
        let response = try await getAssistance(
            text: text,
            type: .custom(instruction),
            context: context
        )
        return response.generatedContent
    }

    // MARK: - API Communication

    private func sendRequest(prompt: String) async throws -> String {
        guard let url = URL(string: apiURL) else {
            throw AIServiceError.invalidURL
        }

        let messages: [[String: Any]] = [["role": "user", "content": prompt]]
        let request = try buildAPIURLRequest(url: url, messages: messages, toolDefinitions: [])
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AIServiceError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]] else {
            throw AIServiceError.invalidResponseFormat
        }

        guard let text = extractText(from: content) else {
            throw AIServiceError.invalidResponseFormat
        }

        return text
    }

    // MARK: - Tool Loop

    /// Get AI assistance with tool support, implementing the client SDK tool loop pattern.
    ///
    /// This method sends the request to the Claude API with tool definitions. If Claude
    /// responds with `stop_reason: "tool_use"`, the tools are executed via the provided
    /// `toolExecutor`, and results are sent back. This loop continues until Claude
    /// produces a final text response (`stop_reason: "end_turn"`).
    public func getAssistanceWithTools(
        text: String,
        type: AIAssistanceType,
        tools: [ToolDefinition],
        toolExecutor: AIToolExecutor,
        context: AIContext? = nil,
        maxIterations: Int = 10
    ) async throws -> AIResponse {
        let prompt = type.prompt(for: text, context: context)
        let generatedContent = try await sendRequestWithToolLoop(
            prompt: prompt,
            tools: tools,
            toolExecutor: toolExecutor,
            maxIterations: maxIterations
        )

        return AIResponse(
            requestType: type,
            originalText: text,
            generatedContent: generatedContent,
            model: configuration.model
        )
    }

    /// Core tool loop implementation.
    ///
    /// Mirrors the client SDK pattern:
    /// ```
    /// response = client.messages.create(...)
    /// while response.stop_reason == "tool_use":
    ///     result = your_tool_executor(response.tool_use)
    ///     response = client.messages.create(tool_result=result, **params)
    /// ```
    private func sendRequestWithToolLoop(
        prompt: String,
        tools: [ToolDefinition],
        toolExecutor: AIToolExecutor,
        maxIterations: Int
    ) async throws -> String {
        guard let url = URL(string: apiURL) else {
            throw AIServiceError.invalidURL
        }

        var messages: [[String: Any]] = [
            ["role": "user", "content": prompt]
        ]

        let toolDefinitions = tools.map { $0.toDict() }

        for _ in 0..<maxIterations {
            let request = try buildAPIURLRequest(url: url, messages: messages, toolDefinitions: toolDefinitions)
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AIServiceError.invalidResponse
            }

            guard httpResponse.statusCode == 200 else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw AIServiceError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
            }

            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let stopReason = json["stop_reason"] as? String,
                  let content = json["content"] as? [[String: Any]] else {
                throw AIServiceError.invalidResponseFormat
            }

            // If the model finished with a text response, extract and return it
            if stopReason == "end_turn" {
                return extractText(from: content) ?? ""
            }

            // If the model wants to use tools, execute them and continue the loop
            if stopReason == "tool_use" {
                // Add the assistant's response (with tool_use blocks) to the conversation
                messages.append(["role": "assistant", "content": content])

                // Execute each tool use block and collect results
                let toolResults = try await executeToolUseBlocks(in: content, using: toolExecutor)

                // Send tool results back as a user message
                messages.append(["role": "user", "content": toolResults])

                continue
            }

            // Unknown stop reason — try to extract text if available
            if let text = extractText(from: content) {
                return text
            }

            throw AIServiceError.invalidResponseFormat
        }

        throw AIServiceError.toolLoopExhausted(iterations: maxIterations)
    }

    /// Builds a configured URLRequest for the Anthropic Messages API.
    private func buildAPIURLRequest(
        url: URL,
        messages: [[String: Any]],
        toolDefinitions: [[String: Any]],
        systemPrompt: String? = nil
    ) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(configuration.apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")

        var requestBody: [String: Any] = [
            "model": configuration.model.rawValue,
            "max_tokens": configuration.maxTokens,
            "temperature": configuration.temperature,
            "messages": messages
        ]

        if !toolDefinitions.isEmpty {
            requestBody["tools"] = toolDefinitions
        }

        if let system = systemPrompt, !system.isEmpty {
            requestBody["system"] = system
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        return request
    }

    // MARK: - Agent Task (Multi-Agent Harness)

    /// Send a request with an explicit system prompt and user prompt.
    ///
    /// Used by `MultiAgentHarness` to give each agent (planner, generator, evaluator)
    /// its own specialised system prompt without affecting the general-purpose assistance
    /// methods. All network I/O still flows through `AIService`.
    public func performAgentTask(
        systemPrompt: String,
        userPrompt: String
    ) async throws -> String {
        guard let url = URL(string: apiURL) else {
            throw AIServiceError.invalidURL
        }

        let messages: [[String: Any]] = [["role": "user", "content": userPrompt]]
        let request = try buildAPIURLRequest(
            url: url,
            messages: messages,
            toolDefinitions: [],
            systemPrompt: systemPrompt
        )
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AIServiceError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]] else {
            throw AIServiceError.invalidResponseFormat
        }

        guard let text = extractText(from: content) else {
            throw AIServiceError.invalidResponseFormat
        }

        return text
    }

    /// Extracts joined text from a list of content blocks.
    /// Returns nil if no text blocks are present.
    private func extractText(from content: [[String: Any]]) -> String? {
        let textParts = content.compactMap { block -> String? in
            guard block["type"] as? String == "text" else { return nil }
            return block["text"] as? String
        }
        return textParts.isEmpty ? nil : textParts.joined()
    }

    /// Executes all tool_use blocks found in an assistant response and returns their results.
    private func executeToolUseBlocks(
        in content: [[String: Any]],
        using toolExecutor: AIToolExecutor
    ) async throws -> [[String: Any]] {
        let toolUseBlocks = content.compactMap { ToolUseBlock(from: $0) }

        var toolResults: [[String: Any]] = []
        for toolUse in toolUseBlocks {
            do {
                let result = try await toolExecutor.executeTool(
                    name: toolUse.name,
                    input: toolUse.input
                )
                toolResults.append(ToolResult(toolUseId: toolUse.id, content: result).toDict())
            } catch {
                toolResults.append(ToolResult(
                    toolUseId: toolUse.id,
                    content: "Error: \(error.localizedDescription)",
                    isError: true
                ).toDict())
            }
        }
        return toolResults
    }

    // MARK: - Batch Operations

    /// Process multiple requests in batch
    public func batchProcess(
        requests: [(text: String, type: AIAssistanceType, context: AIContext?)]
    ) async throws -> [AIResponse] {
        var responses: [AIResponse] = []

        for (text, type, context) in requests {
            let response = try await getAssistance(
                text: text,
                type: type,
                context: context
            )
            responses.append(response)
        }

        return responses
    }

    // MARK: - Document-Level Operations

    /// Analyze entire document and provide comprehensive feedback
    public func analyzeDocument(document: Document) async throws -> DocumentAnalysis {
        let analysisPrompt = """
        Analyze this document comprehensively and provide:
        1. Overall assessment
        2. Strengths (3-5 points)
        3. Areas for improvement (3-5 points)
        4. Specific suggestions for enhancement
        5. Target audience suitability

        Important: Only include observations you can directly support from the document. If you're uncertain about any point, acknowledge this. Do not speculate beyond what the text shows.

        Document Title: \(document.title)
        Category: \(document.category.rawValue)
        Word Count: \(document.wordCount)

        Content:
        \(document.content)

        Provide the analysis in a structured format.
        """

        let response = try await sendRequest(prompt: analysisPrompt)

        return DocumentAnalysis(
            documentId: document.id,
            analysis: response,
            timestamp: Date()
        )
    }

    /// Get writing statistics and insights
    public func getWritingInsights(document: Document) async throws -> WritingInsights {
        let insightsPrompt = """
        Analyze this text and provide insights:
        1. Reading level (Flesch-Kincaid grade)
        2. Tone analysis
        3. Pacing assessment
        4. Vocabulary richness
        5. Sentence structure variety

        Important: For metrics like reading level, provide your best estimate. If you cannot reliably assess something, say so explicitly rather than guessing.

        Text:
        \(document.content)

        Provide specific metrics and observations.
        """

        let response = try await sendRequest(prompt: insightsPrompt)

        return WritingInsights(
            documentId: document.id,
            insights: response,
            timestamp: Date()
        )
    }

    // MARK: - Hallucination Reduction Methods

    /// Extract and verify relevant quotes from source material
    ///
    /// This method implements the "direct quotes for factual grounding" technique.
    /// It asks Claude to extract word-for-word quotes before analysis, reducing hallucinations.
    public func extractQuotesFromDocument(
        text: String,
        context: AIContext? = nil
    ) async throws -> [QuoteBlock] {
        let response = try await getAssistance(
            text: text,
            type: .extractQuotes,
            context: context
        )

        // Parse the response to extract quote blocks
        // In a production system, you might parse structured output
        let quotes = parseQuotesFromResponse(response.generatedContent)
        return quotes
    }

    /// Verify claims with citations from source material
    ///
    /// This method implements the "verify with citations" technique.
    /// Claude must find supporting quotes for each claim or acknowledge they can't be verified.
    public func verifyWithCitations(
        text: String,
        context: AIContext? = nil
    ) async throws -> [VerifiedClaim] {
        let response = try await getAssistance(
            text: text,
            type: .verifyWithCitations,
            context: context
        )

        // Parse the response to extract verified claims
        let claims = parseVerifiedClaimsFromResponse(response.generatedContent)
        return claims
    }

    /// Analyze text while explicitly allowing Claude to admit uncertainty
    ///
    /// This method implements the "allow Claude to say 'I don't know'" technique.
    /// It explicitly permits uncertainty acknowledgment and information gaps.
    public func analyzeWithUncertainty(
        text: String,
        context: AIContext? = nil
    ) async throws -> UncertaintyAwareAnalysis {
        let response = try await getAssistance(
            text: text,
            type: .analyzeWithUncertainty,
            context: context
        )

        // Parse the response to identify confidence areas and uncertainties
        let analysis = parseUncertaintyAnalysisFromResponse(
            response.generatedContent,
            originalText: text
        )
        return analysis
    }

    /// Perform analysis with explicit chain-of-thought verification
    ///
    /// This method implements the "chain-of-thought verification" technique.
    /// Claude explains its reasoning step-by-step, identifying assumptions and uncertainties.
    public func chainOfThoughtVerification(
        text: String,
        context: AIContext? = nil
    ) async throws -> ChainOfThoughtAnalysis {
        let response = try await getAssistance(
            text: text,
            type: .chainOfThoughtVerification,
            context: context
        )

        // Parse the response to extract reasoning steps and conclusions
        let analysis = parseChainOfThoughtFromResponse(
            response.generatedContent,
            originalText: text
        )
        return analysis
    }

    // MARK: - Parsing Helpers for Hallucination Reduction

    private func parseQuotesFromResponse(_ response: String) -> [QuoteBlock] {
        var quotes: [QuoteBlock] = []
        let lines = response.components(separatedBy: "\n")

        var currentQuote: String?
        var currentReference: String?
        var currentExplanation: String?

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }

            // Look for quoted text patterns
            if trimmed.contains("\"") {
                currentQuote = trimmed
                    .replacingOccurrences(of: "^[0-9]+[.):\\s]*", with: "", options: .regularExpression)
                    .trimmingCharacters(in: .whitespaces)
            } else if let quote = currentQuote, !trimmed.isEmpty {
                // Use the next line as explanation
                currentExplanation = trimmed
                quotes.append(QuoteBlock(
                    text: quote,
                    reference: currentReference,
                    relevanceExplanation: currentExplanation ?? ""
                ))
                currentQuote = nil
                currentReference = nil
                currentExplanation = nil
            }
        }

        return quotes
    }

    private func parseVerifiedClaimsFromResponse(_ response: String) -> [VerifiedClaim] {
        var claims: [VerifiedClaim] = []
        let lines = response.components(separatedBy: "\n")

        var currentClaim: String?
        var currentEvidence: String?
        var currentQuote: String?

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }

            // Look for claim patterns
            if trimmed.lowercased().starts(with: "claim:") || trimmed.lowercased().starts(with: "statement:") {
                if let claim = currentClaim, let evidence = currentEvidence {
                    let isVerified = !evidence.lowercased().contains("no supporting evidence")
                    claims.append(VerifiedClaim(
                        claim: claim,
                        supportingQuote: currentQuote,
                        evidence: evidence,
                        isVerified: isVerified
                    ))
                }
                currentClaim = String(trimmed.dropFirst("claim:".count)).trimmingCharacters(in: .whitespaces)
            } else if trimmed.lowercased().starts(with: "evidence:") {
                currentEvidence = String(trimmed.dropFirst("evidence:".count)).trimmingCharacters(in: .whitespaces)
            } else if trimmed.lowercased().starts(with: "quote:") {
                currentQuote = String(trimmed.dropFirst("quote:".count)).trimmingCharacters(in: .whitespaces)
            } else if let claim = currentClaim, let evidence = currentEvidence {
                currentEvidence = (currentEvidence ?? "") + " " + trimmed
            }
        }

        // Add last claim if present
        if let claim = currentClaim, let evidence = currentEvidence {
            let isVerified = !evidence.lowercased().contains("no supporting evidence")
            claims.append(VerifiedClaim(
                claim: claim,
                supportingQuote: currentQuote,
                evidence: evidence,
                isVerified: isVerified
            ))
        }

        return claims
    }

    private func parseUncertaintyAnalysisFromResponse(
        _ response: String,
        originalText: String
    ) -> UncertaintyAwareAnalysis {
        let lines = response.components(separatedBy: "\n")

        var analysis = response
        var confidenceAreas: [String] = []
        var uncertainAreas: [String] = []
        var informationGaps: [String] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.lowercased().contains("confident") || trimmed.lowercased().contains("certain") {
                confidenceAreas.append(trimmed)
            } else if trimmed.lowercased().contains("uncertain") || trimmed.lowercased().contains("unsure") {
                uncertainAreas.append(trimmed)
            } else if trimmed.lowercased().contains("don't have") || trimmed.lowercased().contains("insufficient") {
                informationGaps.append(trimmed)
            }
        }

        return UncertaintyAwareAnalysis(
            analysis: analysis,
            confidenceAreas: confidenceAreas,
            uncertainAreas: uncertainAreas,
            informationGaps: informationGaps
        )
    }

    private func parseChainOfThoughtFromResponse(
        _ response: String,
        originalText: String
    ) -> ChainOfThoughtAnalysis {
        let lines = response.components(separatedBy: "\n")

        var steps: [ReasoningStep] = []
        var assumptions: [String] = []
        var uncertainties: [String] = []
        var reasoning = ""
        var conclusion = ""

        var currentStep: String?
        var currentReasoning: String?
        var stepNumber = 0

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }

            // Look for step markers
            if trimmed.lowercased().starts(with: "step") || trimmed.first?.isNumber == true && trimmed.contains(".") {
                if let step = currentStep, let reason = currentReasoning {
                    steps.append(ReasoningStep(
                        claim: step,
                        reasoning: reason,
                        assumptions: [],
                        uncertainty: nil
                    ))
                }
                currentStep = trimmed
                currentReasoning = nil
                stepNumber += 1
            } else if trimmed.lowercased().starts(with: "assume") {
                assumptions.append(trimmed)
            } else if trimmed.lowercased().starts(with: "uncertain") || trimmed.lowercased().starts(with: "unsure") {
                uncertainties.append(trimmed)
            } else if trimmed.lowercased().starts(with: "conclusion") {
                conclusion = String(trimmed.dropFirst("conclusion:".count)).trimmingCharacters(in: .whitespaces)
            } else if currentStep != nil {
                currentReasoning = (currentReasoning ?? "") + " " + trimmed
            } else {
                reasoning += trimmed + "\n"
            }
        }

        // Add last step
        if let step = currentStep, let reason = currentReasoning {
            steps.append(ReasoningStep(
                claim: step,
                reasoning: reason,
                assumptions: [],
                uncertainty: nil
            ))
        }

        return ChainOfThoughtAnalysis(
            reasoning: reasoning,
            steps: steps,
            assumptions: assumptions,
            uncertainties: uncertainties,
            conclusion: conclusion.isEmpty ? "See steps above." : conclusion
        )
    }
}

// MARK: - Supporting Types

public struct DocumentAnalysis {
    public let documentId: UUID
    public let analysis: String
    public let timestamp: Date

    public init(documentId: UUID, analysis: String, timestamp: Date) {
        self.documentId = documentId
        self.analysis = analysis
        self.timestamp = timestamp
    }
}

public struct WritingInsights {
    public let documentId: UUID
    public let insights: String
    public let timestamp: Date

    public init(documentId: UUID, insights: String, timestamp: Date) {
        self.documentId = documentId
        self.insights = insights
        self.timestamp = timestamp
    }
}

// MARK: - Errors

public enum AIServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case invalidResponseFormat
    case apiError(statusCode: Int, message: String)
    case networkError(Error)
    case toolLoopExhausted(iterations: Int)
    case toolExecutionFailed(toolName: String, reason: String)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from API"
        case .invalidResponseFormat:
            return "Could not parse API response"
        case .apiError(let statusCode, let message):
            return "API error (status \(statusCode)): \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .toolLoopExhausted(let iterations):
            return "Tool loop exceeded maximum iterations (\(iterations))"
        case .toolExecutionFailed(let toolName, let reason):
            return "Tool '\(toolName)' execution failed: \(reason)"
        }
    }
}
