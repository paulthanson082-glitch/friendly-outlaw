import Foundation

// MARK: - WritingAdvisorService

public class WritingAdvisorService {

    private let aiService: AIService

    public init(aiService: AIService) {
        self.aiService = aiService
    }

    // MARK: - Context Building

    /// Builds a plain-text summary of the writer's context suitable for embedding in an AI prompt.
    public func buildContextText(from context: AdvisorContext) -> String {
        var lines: [String] = []

        lines.append("Documents: \(context.totalDocuments) total, \(context.totalWordsAcrossDocuments) words")

        if !context.recentDocumentTitles.isEmpty {
            let quoted = context.recentDocumentTitles.map { "\"\($0)\"" }.joined(separator: ", ")
            lines.append("Recent titles: \(quoted)")
        }

        if !context.documentCategories.isEmpty {
            let cats = context.documentCategories.joined(separator: ", ")
            lines.append("Categories: \(cats)")
        }

        if let stats = context.sessionStats {
            let avgMin = Int(stats.averageDurationSeconds / 60)
            lines.append("Sessions: \(stats.totalSessions) total, avg \(avgMin) min")
        }

        if let notes = context.additionalNotes, !notes.isEmpty {
            lines.append("Additional context: \(notes)")
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Advice Generation

    /// Generates personalized writing advice.
    public func getPersonalizedAdvice(notes: String? = nil) async throws -> WritingAdvisorReport {
        let ctx = AdvisorContext(
            totalDocuments: 0,
            recentDocumentTitles: [],
            totalWordsAcrossDocuments: 0,
            documentCategories: [],
            sessionStats: nil,
            additionalNotes: notes
        )
        let writerData = buildContextText(from: ctx)
        let response = try await aiService.getAssistance(
            text: writerData,
            type: .writingAdvisor,
            context: nil
        )
        return try parseReport(from: response.generatedContent)
    }

    /// Generates writing advice focused on a specific category.
    public func getAdvice(for category: AdvisorCategory) async throws -> WritingAdvisorReport {
        let ctx = AdvisorContext(
            totalDocuments: 0,
            recentDocumentTitles: [],
            totalWordsAcrossDocuments: 0,
            documentCategories: [],
            sessionStats: nil,
            additionalNotes: "Focus on \(category.displayName.lowercased()) advice."
        )
        let writerData = buildContextText(from: ctx)
        let response = try await aiService.getAssistance(
            text: writerData,
            type: .writingAdvisor,
            context: nil
        )
        var report = try parseReport(from: response.generatedContent)
        report = WritingAdvisorReport(
            recommendations: report.recommendations,
            overallAssessment: report.overallAssessment,
            focusArea: category,
            generatedAt: report.generatedAt
        )
        return report
    }

    // MARK: - Private Parsing

    private func parseReport(from content: String) throws -> WritingAdvisorReport {
        // Attempt to decode JSON response from the model
        let jsonData: Data
        if let range = content.range(of: "{"),
           let endRange = content.range(of: "}", options: .backwards) {
            let jsonString = String(content[range.lowerBound...endRange.upperBound])
            jsonData = Data(jsonString.utf8)
        } else {
            jsonData = Data(content.utf8)
        }
        let decoder = JSONDecoder()
        return try decoder.decode(WritingAdvisorReport.self, from: jsonData)
    }
}
