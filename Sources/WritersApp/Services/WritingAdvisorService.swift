import Foundation

// MARK: - WritingAdvisorService

public class WritingAdvisorService {
    private let aiService: AIService

    public init(aiService: AIService) {
        self.aiService = aiService
    }

    // MARK: - Public API

    /// Requests a structured writing advisor report from the AI service using the provided context.
    /// - Parameters:
    ///   - context: The AdvisorContext used to build the prompt (documents, session statistics, categories, and notes).
    /// - Returns: A WritingAdvisorReport parsed from the AI response. If the response cannot be decoded as the expected JSON structure, the returned report contains no recommendations, the raw response as the overall assessment, and a default focus area.
    public func getAdvisorReport(context: AdvisorContext) async throws -> WritingAdvisorReport {
        let contextText = buildContextText(from: context)
        let response = try await aiService.getAssistance(
            text: contextText,
            type: .writingAdvisor,
            context: nil
        )
        return parseAdvisorReport(from: response.generatedContent)
    }

    /// Requests a category-focused writing recommendation from the AI and returns a single Recommendation.
    /// - Parameters:
    ///   - category: The advisor category to focus the recommendation on.
    ///   - context: Context about the user's documents and sessions used to build the prompt.
    /// - Returns: An `AdvisorRecommendation` focused on `category` parsed from the AI response; if the response cannot be parsed into a recommendation, returns a fallback `AdvisorRecommendation` with the provided `category`, `.medium` priority, a title of `"<Category DisplayName> Advice"`, the raw AI content as the recommendation, and an empty `actionableSteps` array.
    public func getRecommendation(
        for category: AdvisorCategory,
        context: AdvisorContext
    ) async throws -> AdvisorRecommendation {
        let contextText = buildContextText(from: context)
        let categoryInstruction = "Focus only on the \(category.displayName) category."
        let combinedText = "\(contextText)\n\nInstruction: \(categoryInstruction)"
        let response = try await aiService.getAssistance(
            text: combinedText,
            type: .writingAdvisor,
            context: nil
        )
        return parseRecommendation(from: response.generatedContent, category: category)
    }

    // MARK: - Context Building

    /// Builds a human-readable prompt string describing the provided advisor context.
    /// 
    /// The resulting text contains one line per present section: document counts and total words; recent document titles (each quoted) when available; document categories as a comma-separated list when available; session statistics including total sessions and average duration in minutes when present; and additional notes when provided.
    /// - Parameter ctx: The AdvisorContext to format into prompt text.
    /// - Returns: A newline-separated string representing the formatted context.
    internal func buildContextText(from ctx: AdvisorContext) -> String {
        var lines: [String] = []

        lines.append("Documents: \(ctx.totalDocuments) total, \(ctx.totalWordsAcrossDocuments) words")

        if !ctx.recentDocumentTitles.isEmpty {
            let titles = ctx.recentDocumentTitles.map { "\"\($0)\"" }.joined(separator: ", ")
            lines.append("Recent titles: \(titles)")
        }

        if !ctx.documentCategories.isEmpty {
            lines.append("Categories: \(ctx.documentCategories.joined(separator: ", "))")
        }

        if let stats = ctx.sessionStats {
            let avgMin = Int(stats.averageDurationSeconds / 60)
            lines.append("Sessions: \(stats.totalSessions) total, avg \(avgMin) min each")
        }

        if let notes = ctx.additionalNotes, !notes.isEmpty {
            lines.append("Additional context: \(notes)")
        }

        return lines.joined(separator: "\n")
    }

    /// Parses AI response content into a WritingAdvisorReport by extracting and decoding an embedded JSON object when present.
    /// - Parameters:
    ///   - content: The raw AI-generated string which may contain a JSON-formatted report.
    /// - Returns: A `WritingAdvisorReport` decoded from the JSON object found in `content`. If no valid JSON can be extracted or decoding fails, returns a report with an empty `recommendations`, `overallAssessment` set to the original `content`, and `focusArea` set to `.productivity`.

    private func parseAdvisorReport(from content: String) -> WritingAdvisorReport {
        guard
            let start = content.firstIndex(of: "{"),
            let end = content.lastIndex(of: "}"),
            start <= end,
            let data = String(content[start...end]).data(using: .utf8),
            let parsed = try? JSONDecoder().decode(ParsedReport.self, from: data)
        else {
            return WritingAdvisorReport(
                recommendations: [],
                overallAssessment: content,
                focusArea: .productivity
            )
        }

        let recommendations = parsed.recommendations.map { r in
            AdvisorRecommendation(
                category: AdvisorCategory(rawValue: r.category) ?? .productivity,
                priority: AdvisorPriority(rawValue: r.priority) ?? .medium,
                title: r.title,
                recommendation: r.recommendation,
                actionableSteps: r.actionableSteps
            )
        }

        return WritingAdvisorReport(
            recommendations: recommendations,
            overallAssessment: parsed.overallAssessment,
            focusArea: AdvisorCategory(rawValue: parsed.focusArea) ?? .productivity
        )
    }

    /// Parses AI-generated content and produces a single recommendation focused on the given category.
    /// - Parameters:
    ///   - content: The raw AI response text to parse for a recommendation (may contain JSON or plain text).
    ///   - category: The desired AdvisorCategory to use for a fallback recommendation when none are parsed.
    /// - Returns: An `AdvisorRecommendation` extracted from the parsed report; if no recommendation is present, a fallback recommendation using `category`, medium priority, the category display name as the title, the raw `content` as the recommendation text, and no actionable steps.
    private func parseRecommendation(
        from content: String,
        category: AdvisorCategory
    ) -> AdvisorRecommendation {
        let report = parseAdvisorReport(from: content)
        if let first = report.recommendations.first {
            return first
        }
        return AdvisorRecommendation(
            category: category,
            priority: .medium,
            title: "\(category.displayName) Advice",
            recommendation: content,
            actionableSteps: []
        )
    }

    // MARK: - Private Decodable Types

    private struct ParsedReport: Decodable {
        let overallAssessment: String
        let focusArea: String
        let recommendations: [ParsedRecommendation]
    }

    private struct ParsedRecommendation: Decodable {
        let category: String
        let priority: String
        let title: String
        let recommendation: String
        let actionableSteps: [String]
    }
}
