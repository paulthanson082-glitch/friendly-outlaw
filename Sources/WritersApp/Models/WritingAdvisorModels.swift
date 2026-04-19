import Foundation

// MARK: - AdvisorCategory

public enum AdvisorCategory: String, Codable, CaseIterable, Equatable {
    case productivity
    case creativity
    case consistency
    case craft
    case goals

    public var displayName: String {
        switch self {
        case .productivity: return "Productivity"
        case .creativity: return "Creativity"
        case .consistency: return "Consistency"
        case .craft: return "Craft"
        case .goals: return "Goals"
        }
    }
}

// MARK: - AdvisorPriority

public enum AdvisorPriority: String, Codable, CaseIterable, Equatable {
    case high
    case medium
    case low
}

// MARK: - AdvisorRecommendation

public struct AdvisorRecommendation: Codable, Identifiable, Equatable {
    public let id: UUID
    public let category: AdvisorCategory
    public let priority: AdvisorPriority
    public let title: String
    public let recommendation: String
    public let actionableSteps: [String]
    public let generatedAt: Date

    private enum CodingKeys: String, CodingKey {
        case id, category, priority, title, recommendation, actionableSteps, generatedAt
    }

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

    // The AI response schema omits `id` and `generatedAt`; supply defaults when absent.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        category = try c.decode(AdvisorCategory.self, forKey: .category)
        priority = try c.decode(AdvisorPriority.self, forKey: .priority)
        title = try c.decode(String.self, forKey: .title)
        recommendation = try c.decode(String.self, forKey: .recommendation)
        actionableSteps = try c.decode([String].self, forKey: .actionableSteps)
        generatedAt = try c.decodeIfPresent(Date.self, forKey: .generatedAt) ?? Date()
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(category, forKey: .category)
        try c.encode(priority, forKey: .priority)
        try c.encode(title, forKey: .title)
        try c.encode(recommendation, forKey: .recommendation)
        try c.encode(actionableSteps, forKey: .actionableSteps)
        try c.encode(generatedAt, forKey: .generatedAt)
    }
}

// MARK: - WritingAdvisorReport

public struct WritingAdvisorReport: Codable, Equatable {
    public let recommendations: [AdvisorRecommendation]
    public let overallAssessment: String
    public let focusArea: AdvisorCategory
    public let generatedAt: Date

    private enum CodingKeys: String, CodingKey {
        case recommendations, overallAssessment, focusArea, generatedAt
    }

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

    // The AI response schema omits `generatedAt`; supply a default when absent.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        recommendations = try c.decode([AdvisorRecommendation].self, forKey: .recommendations)
        overallAssessment = try c.decode(String.self, forKey: .overallAssessment)
        focusArea = try c.decode(AdvisorCategory.self, forKey: .focusArea)
        generatedAt = try c.decodeIfPresent(Date.self, forKey: .generatedAt) ?? Date()
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(recommendations, forKey: .recommendations)
        try c.encode(overallAssessment, forKey: .overallAssessment)
        try c.encode(focusArea, forKey: .focusArea)
        try c.encode(generatedAt, forKey: .generatedAt)
    }
}

// MARK: - AdvisorContext

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
