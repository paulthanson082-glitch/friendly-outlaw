import Foundation

// MARK: - AdvisorCategory

/// Categories of writing advice that the advisor can provide.
public enum AdvisorCategory: String, Codable, CaseIterable, Equatable {
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

// MARK: - AdvisorPriority

/// Priority level for an advisor recommendation.
public enum AdvisorPriority: String, Codable, CaseIterable, Equatable {
    case high
    case medium
    case low
}

// MARK: - AdvisorRecommendation

/// A single personalized writing recommendation from the advisor.
public struct AdvisorRecommendation: Identifiable, Codable, Equatable {
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

    // MARK: Codable

    private enum CodingKeys: String, CodingKey {
        case id, category, priority, title, recommendation, actionableSteps, generatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id              = try container.decode(UUID.self,            forKey: .id)
        category        = try container.decode(AdvisorCategory.self, forKey: .category)
        priority        = try container.decode(AdvisorPriority.self, forKey: .priority)
        title           = try container.decode(String.self,          forKey: .title)
        recommendation  = try container.decode(String.self,          forKey: .recommendation)
        actionableSteps = try container.decode([String].self,        forKey: .actionableSteps)
        let iso = try container.decode(String.self, forKey: .generatedAt)
        let formatter = ISO8601DateFormatter()
        generatedAt = formatter.date(from: iso) ?? Date()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id,              forKey: .id)
        try container.encode(category,        forKey: .category)
        try container.encode(priority,        forKey: .priority)
        try container.encode(title,           forKey: .title)
        try container.encode(recommendation,  forKey: .recommendation)
        try container.encode(actionableSteps, forKey: .actionableSteps)
        let formatter = ISO8601DateFormatter()
        try container.encode(formatter.string(from: generatedAt), forKey: .generatedAt)
    }
}

// MARK: - WritingAdvisorReport

/// A full personalized coaching report containing multiple recommendations.
public struct WritingAdvisorReport: Identifiable, Codable {
    public let id: UUID
    public let recommendations: [AdvisorRecommendation]
    public let overallAssessment: String
    public let focusArea: AdvisorCategory
    public let generatedAt: Date

    public init(
        id: UUID = UUID(),
        recommendations: [AdvisorRecommendation],
        overallAssessment: String,
        focusArea: AdvisorCategory,
        generatedAt: Date = Date()
    ) {
        self.id               = id
        self.recommendations  = recommendations
        self.overallAssessment = overallAssessment
        self.focusArea        = focusArea
        self.generatedAt      = generatedAt
    }

    // MARK: Codable

    private enum CodingKeys: String, CodingKey {
        case id, recommendations, overallAssessment, focusArea, generatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id                = try container.decode(UUID.self,                      forKey: .id)
        recommendations   = try container.decode([AdvisorRecommendation].self,   forKey: .recommendations)
        overallAssessment = try container.decode(String.self,                    forKey: .overallAssessment)
        focusArea         = try container.decode(AdvisorCategory.self,           forKey: .focusArea)
        let iso = try container.decode(String.self, forKey: .generatedAt)
        let formatter = ISO8601DateFormatter()
        generatedAt = formatter.date(from: iso) ?? Date()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id,                forKey: .id)
        try container.encode(recommendations,   forKey: .recommendations)
        try container.encode(overallAssessment, forKey: .overallAssessment)
        try container.encode(focusArea,         forKey: .focusArea)
        let formatter = ISO8601DateFormatter()
        try container.encode(formatter.string(from: generatedAt), forKey: .generatedAt)
    }
}

// MARK: - AdvisorContext

/// Context about the writer's current corpus and session history, used to personalise advice.
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
        self.totalDocuments             = totalDocuments
        self.recentDocumentTitles       = recentDocumentTitles
        self.totalWordsAcrossDocuments  = totalWordsAcrossDocuments
        self.documentCategories         = documentCategories
        self.sessionStats               = sessionStats
        self.additionalNotes            = additionalNotes
    }
}
