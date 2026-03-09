//
//  EncouragementService.swift
//  WritersApp
//
//  A service that provides positive, motivational feedback to writers
//  based on their writing achievements and patterns.
//

import Foundation

// MARK: - Encouragement Types

/// Types of encouragement messages
public enum EncouragementType: String, Codable {
    case wordCount = "word_count"
    case sessionDuration = "session_duration"
    case consistency = "consistency"
    case milestone = "milestone"
    case general = "general"
    case perseverance = "perseverance"
    case creativity = "creativity"
}

/// An encouragement message
public struct EncouragementMessage: Codable, Identifiable {
    public let id: UUID
    public let type: EncouragementType
    public let message: String
    public let timestamp: Date
    public let context: [String: String]?
    
    public init(
        id: UUID = UUID(),
        type: EncouragementType,
        message: String,
        timestamp: Date = Date(),
        context: [String: String]? = nil
    ) {
        self.id = id
        self.type = type
        self.message = message
        self.timestamp = timestamp
        self.context = context
    }
}

// MARK: - Encouragement Configuration

/// Configuration for the encouragement service
public struct EncouragementConfiguration: Codable {
    public var enabled: Bool
    public var showOnMilestones: Bool
    public var showOnSessionEnd: Bool
    public var minimumWordsForEncouragement: Int
    public var encouragementFrequency: EncouragementFrequency
    
    public enum EncouragementFrequency: String, Codable {
        case always = "always"
        case often = "often"
        case moderate = "moderate"
        case occasional = "occasional"
    }
    
    public init(
        enabled: Bool = true,
        showOnMilestones: Bool = true,
        showOnSessionEnd: Bool = true,
        minimumWordsForEncouragement: Int = 50,
        encouragementFrequency: EncouragementFrequency = .moderate
    ) {
        self.enabled = enabled
        self.showOnMilestones = showOnMilestones
        self.showOnSessionEnd = showOnSessionEnd
        self.minimumWordsForEncouragement = minimumWordsForEncouragement
        self.encouragementFrequency = encouragementFrequency
    }
}

// MARK: - Encouragement Thresholds

private enum WordCountThreshold {
    static let small = 100
    static let medium = 250
    static let large = 500
    static let huge = 1000
}

private enum SessionDurationThreshold {
    static let short = 15
    static let medium = 30
    static let long = 60
}

private enum WritingSpeedThreshold {
    static let slowWordsPerMinute = 5.0
}

// MARK: - Encouragement Service

/// Service for providing motivational feedback to writers
public class EncouragementService {
    
    public var configuration: EncouragementConfiguration
    private var history: [EncouragementMessage] = []
    
    // MARK: - Initialization
    
    public init(configuration: EncouragementConfiguration = EncouragementConfiguration()) {
        self.configuration = configuration
    }
    
    // MARK: - Public Methods
    
    /// Get encouragement based on word count achievement
    public func getWordCountEncouragement(wordCount: Int, previousCount: Int = 0) -> EncouragementMessage? {
        guard configuration.enabled else { return nil }

        let wordsWritten = wordCount - previousCount
        guard wordsWritten >= configuration.minimumWordsForEncouragement else { return nil }

        return record(EncouragementMessage(
            type: .wordCount,
            message: selectWordCountMessage(wordsWritten: wordsWritten, totalWords: wordCount),
            context: [
                "words_written": "\(wordsWritten)",
                "total_words": "\(wordCount)"
            ]
        ))
    }

    /// Get encouragement for session duration
    public func getSessionEncouragement(durationMinutes: Int, wordsWritten: Int) -> EncouragementMessage? {
        guard configuration.enabled && configuration.showOnSessionEnd else { return nil }

        return record(EncouragementMessage(
            type: .sessionDuration,
            message: selectSessionMessage(durationMinutes: durationMinutes, wordsWritten: wordsWritten),
            context: [
                "duration_minutes": "\(durationMinutes)",
                "words_written": "\(wordsWritten)"
            ]
        ))
    }

    /// Get encouragement for reaching a milestone
    public func getMilestoneEncouragement(milestone: WritingMilestone) -> EncouragementMessage? {
        guard configuration.enabled && configuration.showOnMilestones else { return nil }

        return record(EncouragementMessage(
            type: .milestone,
            message: selectMilestoneMessage(for: milestone),
            context: [
                "milestone_type": milestone.type.rawValue,
                "milestone_value": "\(milestone.value)"
            ]
        ))
    }

    /// Get a general encouragement message
    public func getGeneralEncouragement() -> EncouragementMessage {
        return record(EncouragementMessage(
            type: .general,
            message: generalMessages.randomElement() ?? "Keep up the great work!"
        ))
    }

    /// Get encouragement for perseverance (continuing to write despite challenges)
    public func getPerseveranceEncouragement() -> EncouragementMessage {
        return record(EncouragementMessage(
            type: .perseverance,
            message: perseveranceMessages.randomElement() ?? "Your dedication is inspiring!"
        ))
    }
    
    /// Get the history of encouragement messages
    public func getHistory(limit: Int = 10) -> [EncouragementMessage] {
        return Array(history.suffix(limit))
    }
    
    /// Clear the encouragement history
    public func clearHistory() {
        history.removeAll()
    }
    
    // MARK: - Private Methods

    @discardableResult
    private func record(_ encouragement: EncouragementMessage) -> EncouragementMessage {
        history.append(encouragement)
        return encouragement
    }

    private func selectWordCountMessage(wordsWritten: Int, totalWords: Int) -> String {
        switch wordsWritten {
        case 0..<WordCountThreshold.small:
            return wordCountMessages.small.randomElement() ?? "Nice progress! Every word counts."
        case WordCountThreshold.small..<WordCountThreshold.medium:
            return wordCountMessages.medium.randomElement() ?? "You're on a roll! Keep the momentum going."
        case WordCountThreshold.medium..<WordCountThreshold.large:
            return wordCountMessages.large.randomElement() ?? "Impressive word count! Your story is taking shape."
        case WordCountThreshold.large..<WordCountThreshold.huge:
            return wordCountMessages.huge.randomElement() ?? "Wow! That's a significant achievement. Your dedication shows!"
        default:
            return wordCountMessages.massive.randomElement() ?? "Outstanding! You're crushing it today!"
        }
    }

    private func selectSessionMessage(durationMinutes: Int, wordsWritten: Int) -> String {
        let wordsPerMinute = durationMinutes > 0 ? Double(wordsWritten) / Double(durationMinutes) : 0
        let isSlowPace = wordsPerMinute < WritingSpeedThreshold.slowWordsPerMinute

        switch durationMinutes {
        case 0..<SessionDurationThreshold.short:
            return "Great start! Even short sessions add up."
        case SessionDurationThreshold.short..<SessionDurationThreshold.medium:
            return isSlowPace
                ? "Nice focused session! Quality matters more than speed."
                : "Productive session! You're making excellent progress."
        case SessionDurationThreshold.medium..<SessionDurationThreshold.long:
            return "Fantastic dedication! A solid writing session."
        default:
            return isSlowPace
                ? "Remarkable commitment! A marathon writing session."
                : "Incredible! Both duration and productivity are outstanding!"
        }
    }
    
    private func selectMilestoneMessage(for milestone: WritingMilestone) -> String {
        switch milestone.type {
        case .totalWords:
            return wordMilestoneMessages[milestone.value] ?? "Congratulations on reaching \(milestone.value) words!"
        case .documentCount:
            return "You've created \(milestone.value) documents! What an accomplishment!"
        case .consecutiveDays:
            return "You've written for \(milestone.value) consecutive days! Consistency is key."
        case .sessionsCompleted:
            return "\(milestone.value) sessions completed! Your dedication is impressive."
        }
    }
    
    // MARK: - Message Collections
    
    private let generalMessages = [
        "You're doing great! Keep writing.",
        "Every word brings you closer to your goal.",
        "Your creativity is flowing beautifully.",
        "Writers write, and you're definitely writing!",
        "The world needs your stories. Keep going!",
        "One word at a time, you're making magic.",
        "Your voice matters. Keep sharing it.",
        "Great writers write consistently. You're on your way!",
        "The hardest part is showing up. You're here!",
        "Your dedication to your craft is inspiring."
    ]
    
    private let perseveranceMessages = [
        "Writing is hard, but you're doing it anyway. That's courage.",
        "Every great writer faces the blank page. You're facing it head-on.",
        "Your persistence will pay off. Keep pushing forward.",
        "The fact that you keep showing up says everything.",
        "Writing through the tough parts makes you stronger.",
        "Your determination is admirable. Don't give up!",
        "Real writers write when it's hard. That's you.",
        "You're building something meaningful, one session at a time.",
        "The breakthrough often comes right after the struggle.",
        "Your commitment to your story is powerful."
    ]
    
    private let wordCountMessages = (
        small: [
            "Nice progress! Every word counts.",
            "Great start! You're building momentum.",
            "Well done! Keep the words flowing.",
            "Excellent! Small steps lead to big achievements."
        ],
        medium: [
            "You're on a roll! Keep the momentum going.",
            "Fantastic progress! Your story is developing nicely.",
            "Great work! You're making solid headway.",
            "Impressive! You're in the zone."
        ],
        large: [
            "Impressive word count! Your story is taking shape.",
            "Wow! That's serious progress. Keep it up!",
            "Outstanding effort! You're really flying now.",
            "Remarkable! Your dedication is paying off."
        ],
        huge: [
            "Wow! That's a significant achievement. Your dedication shows!",
            "Incredible! You've written a substantial amount.",
            "Amazing! This is what commitment looks like.",
            "Phenomenal! You're on fire today!"
        ],
        massive: [
            "Outstanding! You're crushing it today!",
            "Extraordinary! This is a banner writing day!",
            "Legendary! Your productivity is off the charts!",
            "Mindblowing! You're unstoppable!"
        ]
    )
    
    private let wordMilestoneMessages: [Int: String] = [
        1000: "Your first thousand words! A fantastic milestone!",
        5000: "5,000 words! You're building something substantial.",
        10000: "10,000 words! You've hit a major milestone!",
        25000: "25,000 words! That's novella length!",
        50000: "50,000 words! NaNoWriMo complete! Incredible!",
        75000: "75,000 words! You're in novel territory now!",
        100000: "100,000 words! What an achievement!"
    ]
}

// MARK: - Writing Milestone

/// Represents a writing milestone
public struct WritingMilestone {
    public enum MilestoneType: String, Codable {
        case totalWords = "total_words"
        case documentCount = "document_count"
        case consecutiveDays = "consecutive_days"
        case sessionsCompleted = "sessions_completed"
    }
    
    public let type: MilestoneType
    public let value: Int
    public let achievedAt: Date
    
    public init(type: MilestoneType, value: Int, achievedAt: Date = Date()) {
        self.type = type
        self.value = value
        self.achievedAt = achievedAt
    }
}
