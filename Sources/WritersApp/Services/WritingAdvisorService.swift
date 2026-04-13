import Foundation

// MARK: - WritingAdvisorService

/// Generates personalised writing coaching reports and recommendations using Claude.
///
/// Use `WritersApp.getPersonalizedWritingAdvice()` or `WritersApp.getWritingAdvice(for:)` as
/// the high-level entry points; those methods build an `AdvisorContext` and delegate here.
public class WritingAdvisorService {

    // MARK: - Private Properties

    private let aiService: AIService

    // MARK: - Init

    public init(aiService: AIService) {
        self.aiService = aiService
    }

    // MARK: - Public API

    /// Returns a full personalised coaching report with 3–5 recommendations.
    public func getAdvisorReport(context: AdvisorContext) async throws -> WritingAdvisorReport {
        let contextText = buildContextText(from: context)
        let response = try await aiService.getAssistance(
            text: contextText,
            type: .writingAdvisor,
            context: nil
        )
        return try parseReport(from: response.generatedContent)
    }

    /// Returns a single recommendation for the specified advisor category.
    public func getRecommendation(
        for category: AdvisorCategory,
        context: AdvisorContext
    ) async throws -> AdvisorRecommendation {
        let contextText = buildContextText(from: context)
        let categoryPrompt = """
            Focus only on the "\(category.rawValue)" category.
            \(contextText)
            """
        let response = try await aiService.getAssistance(
            text: categoryPrompt,
            type: .writingAdvisor,
            context: nil
        )
        return try parseRecommendation(from: response.generatedContent, defaultCategory: category)
    }

    // MARK: - Context Building

    /// Builds a compact text summary of the writer's corpus for inclusion in an AI prompt.
    ///
    /// The output always contains a document line and conditionally appends lines for recent
    /// titles, document categories, session statistics, and additional notes. Lines are
    /// joined with `"\n"` (no trailing newline).
    public func buildContextText(from context: AdvisorContext) -> String {
        var lines: [String] = []

        lines.append("Documents: \(context.totalDocuments) total, \(context.totalWordsAcrossDocuments) words")

        if !context.recentDocumentTitles.isEmpty {
            let quoted = context.recentDocumentTitles.map { "\"\($0)\"" }.joined(separator: ", ")
            lines.append("Recent titles: \(quoted)")
        }

        if !context.documentCategories.isEmpty {
            lines.append("Categories: \(context.documentCategories.joined(separator: ", "))")
        }

        if let stats = context.sessionStats {
            let avgMinutes = stats.averageDurationSeconds / 60
            lines.append("Sessions: \(stats.totalSessions) total, avg \(avgMinutes) min")
        }

        if let notes = context.additionalNotes, !notes.isEmpty {
            lines.append("Additional context: \(notes)")
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Private Parsing

    private func parseReport(from content: String) throws -> WritingAdvisorReport {
        let jsonString = extractJSON(from: content)
        guard let data = jsonString.data(using: .utf8) else {
            return fallbackReport(content: content)
        }
        if let report = try? JSONDecoder().decode(WritingAdvisorReport.self, from: data) {
            return report
        }
        return fallbackReport(content: content)
    }

    private func parseRecommendation(
        from content: String,
        defaultCategory: AdvisorCategory
    ) throws -> AdvisorRecommendation {
        let jsonString = extractJSON(from: content)
        if let data = jsonString.data(using: .utf8),
           let report = try? JSONDecoder().decode(WritingAdvisorReport.self, from: data),
           let first = report.recommendations.first {
            return first
        }
        return AdvisorRecommendation(
            category: defaultCategory,
            priority: .medium,
            title: "Writing Advice",
            recommendation: content,
            actionableSteps: []
        )
    }

    private func extractJSON(from text: String) -> String {
        if let start = text.range(of: "{"),
           let end = text.range(of: "}", options: .backwards) {
            return String(text[start.lowerBound...end.upperBound])
        }
        return text
    }

    private func fallbackReport(content: String) -> WritingAdvisorReport {
        WritingAdvisorReport(
            recommendations: [],
            overallAssessment: content,
            focusArea: .productivity
        )
    }
}
