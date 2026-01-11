import Foundation

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

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(configuration.apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")

        let requestBody: [String: Any] = [
            "model": configuration.model.rawValue,
            "max_tokens": configuration.maxTokens,
            "temperature": configuration.temperature,
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AIServiceError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstContent = content.first,
              let text = firstContent["text"] as? String else {
            throw AIServiceError.invalidResponseFormat
        }

        return text
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
        }
    }
}
