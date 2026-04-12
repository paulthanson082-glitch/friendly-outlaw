import Foundation

// MARK: - WritingAdvisorService

public class WritingAdvisorService {
    private let aiService: AIService

    public init(aiService: AIService) {
        self.aiService = aiService
    }

    // MARK: - Public API

    /// Returns a full personalized coaching report with 3-5 recommendations.
    public func getAdvisorReport(context: AdvisorContext) async throws -> WritingAdvisorReport {
        let contextText = buildContextText(from: context)
        let response = try await aiService.getAssistance(
            text: contextText,
            type: .writingAdvisor,
            context: nil
        )
        return parseAdvisorReport(from: response.generatedContent)
    }

    /// Returns a single focused recommendation for the specified category.
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

    /// Converts an AdvisorContext into a human-readable string for the AI prompt.
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

    // MARK: - Response Parsing

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
