// Sources/WritersApp/Models/AIAnalyticsModels.swift
import Foundation

// MARK: - AI Generation Record

/// Single tracked AI generation event
public struct AIGenerationRecord: Identifiable, Codable {
    public let id: UUID
    public let timestamp: Date
    public let assistanceType: AIAssistanceType
    public let inputTokens: Int
    public let outputTokens: Int
    public let model: AIModel
    public let status: GenerationStatus
    public let documentId: UUID?
    public var totalTokens: Int { inputTokens + outputTokens }

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        assistanceType: AIAssistanceType,
        inputTokens: Int,
        outputTokens: Int,
        model: AIModel,
        status: GenerationStatus,
        documentId: UUID? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.assistanceType = assistanceType
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.model = model
        self.status = status
        self.documentId = documentId
    }
}

// MARK: - Generation Status

public enum GenerationStatus: String, Codable {
    case pending
    case completed
    case failed
    case cancelled

    public var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .completed: return "Completed"
        case .failed: return "Failed"
        case .cancelled: return "Cancelled"
        }
    }

    public var icon: String {
        switch self {
        case .pending: return "hourglass.tophalf.filled"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        case .cancelled: return "minus.circle.fill"
        }
    }
}

// MARK: - Analytics Snapshot

/// Current AI usage analytics
public struct AIAnalyticsSnapshot {
    public let totalRequests: Int
    public let totalTokens: Int
    public let costEstimate: Double
    public let requestsToday: Int
    public let averageTokensPerRequest: Int

    public init(
        totalRequests: Int,
        totalTokens: Int,
        costEstimate: Double,
        requestsToday: Int,
        averageTokensPerRequest: Int
    ) {
        self.totalRequests = totalRequests
        self.totalTokens = totalTokens
        self.costEstimate = costEstimate
        self.requestsToday = requestsToday
        self.averageTokensPerRequest = averageTokensPerRequest
    }
}

// MARK: - Model Usage Breakdown

/// Per-model usage statistics
public struct ModelUsageBreakdown: Identifiable {
    public let id: String
    public let model: AIModel
    public let requestCount: Int
    public let tokenCount: Int
    public let percentage: Double

    public init(
        model: AIModel,
        requestCount: Int,
        tokenCount: Int,
        percentage: Double
    ) {
        self.id = model.rawValue
        self.model = model
        self.requestCount = requestCount
        self.tokenCount = tokenCount
        self.percentage = percentage
    }
}

// MARK: - Daily Trend

/// Daily aggregated AI usage
public struct DailyTrend: Identifiable {
    public let id: String
    public let date: Date
    public let requestCount: Int
    public let tokenCount: Int
    public let costEstimate: Double

    public init(
        date: Date,
        requestCount: Int,
        tokenCount: Int,
        costEstimate: Double
    ) {
        self.id = ISO8601DateFormatter().string(from: date)
        self.date = date
        self.requestCount = requestCount
        self.tokenCount = tokenCount
        self.costEstimate = costEstimate
    }
}

// MARK: - Assistance Type Extension for Analytics

extension AIAssistanceType {
    public var analyticsKey: String {
        switch self {
        case .continueWriting: return "continue_writing"
        case .improveText: return "improve_text"
        case .grammarCheck: return "grammar_check"
        case .styleSuggestions: return "style_suggestions"
        case .generateOutline: return "generate_outline"
        case .brainstormIdeas: return "brainstorm_ideas"
        case .brainstormIdeasCategorized: return "brainstorm_categorized"
        case .characterDevelopment: return "character_development"
        case .plotSuggestions: return "plot_suggestions"
        case .dialogueImprovement: return "dialogue_improvement"
        case .descriptionEnhancement: return "description_enhancement"
        case .titleGeneration: return "title_generation"
        case .summarize: return "summarize"
        case .expandText: return "expand_text"
        case .simplifyText: return "simplify_text"
        case .changetone: return "change_tone"
        case .custom: return "custom"
        case .extractQuotes: return "extract_quotes"
        case .verifyWithCitations: return "verify_with_citations"
        case .analyzeWithUncertainty: return "analyze_uncertainty"
        case .chainOfThoughtVerification: return "chain_of_thought"
        case .writingAdvisor: return "writing_advisor"
        }
    }
}
