// MARK: - Advisor Models

public enum AdvisorCategory: String, Codable, CaseIterable {
    case productivity
    case creativity
    case consistency
    case craft
    case goals

    public var displayName: String {
        switch self {
        case .productivity: return "Productivity"
        case .creativity:   return "Creativity"
        case .consistency:  return "Consistency"
        case .craft:        return "Craft"
        case .goals:        return "Goals"
        }
    }
}

public enum AdvisorPriority: String, Codable, CaseIterable {
    case high
    case medium
    case low
}

public struct AdvisorRecommendation: Codable, Identifiable {
    public let id: UUID
    public let category: AdvisorCategory
    public let priority: AdvisorPriority
    public let title: String
    public let recommendation: String
    public let actionableSteps: [String]
    public let generatedAt: Date

    public init(
        id: UUID = UUID(),
        category: AdvisorCategory,
        priority: AdvisorPriority,
        title: String,
        recommendation: String,
        actionableSteps: [String],
        generatedAt: Date = Date()
    ) {
        self.id = id
        self.category = category
        self.priority = priority
        self.title = title
        self.recommendation = recommendation
        self.actionableSteps = actionableSteps
        self.generatedAt = generatedAt
    }
}

public struct WritingAdvisorReport: Codable {
    public let recommendations: [AdvisorRecommendation]
    public let overallAssessment: String
    public let focusArea: AdvisorCategory
    public let generatedAt: Date

    public init(
        recommendations: [AdvisorRecommendation],
        overallAssessment: String,
        focusArea: AdvisorCategory,
        generatedAt: Date = Date()
    ) {
        self.recommendations = recommendations
        self.overallAssessment = overallAssessment
        self.focusArea = focusArea
        self.generatedAt = generatedAt
    }
}

public struct AdvisorContext {
    public let totalDocuments: Int
    public let recentDocumentTitles: [String]
    public let totalWordsAcrossDocuments: Int
    public let documentCategories: [String]
    public let sessionStats: SessionStats?
    public let additionalNotes: String?

    public init(
        totalDocuments: Int,
        recentDocumentTitles: [String],
        totalWordsAcrossDocuments: Int,
        documentCategories: [String],
        sessionStats: SessionStats?,
        additionalNotes: String? = nil
    ) {
        self.totalDocuments = totalDocuments
        self.recentDocumentTitles = recentDocumentTitles
        self.totalWordsAcrossDocuments = totalWordsAcrossDocuments
        self.documentCategories = documentCategories
        self.sessionStats = sessionStats
        self.additionalNotes = additionalNotes
    }
}
