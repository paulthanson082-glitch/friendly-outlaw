import Foundation

// MARK: - Harness Configuration

/// Configuration for the multi-agent writing harness.
public struct HarnessConfiguration: Codable {
    /// Maximum number of revision cycles per section before accepting best result.
    public let maxRevisionsPerSection: Int
    /// Minimum score (1–10) that each criterion must meet for a section to pass.
    public let qualityThreshold: Int
    /// Hard cap on sections the planner may produce (prevents runaway generation).
    public let maxSections: Int
    /// Claude model used for all agents in this harness run.
    public let model: AIModel

    public init(
        maxRevisionsPerSection: Int = 3,
        qualityThreshold: Int = 7,
        maxSections: Int = 20,
        model: AIModel = .claude35Sonnet
    ) {
        self.maxRevisionsPerSection = maxRevisionsPerSection
        // Clamp to valid criterion score range so the evaluator loop behaves correctly.
        self.qualityThreshold = max(1, min(10, qualityThreshold))
        self.maxSections = maxSections
        self.model = model
    }

    /// Sensible defaults suitable for most writing tasks.
    public static let `default` = HarnessConfiguration()
}

// MARK: - Writing Criteria

/// The four quality dimensions the evaluator agent scores each section against.
///
/// Adapted from the GAN-inspired harness design described in Anthropic's
/// "Harness design for long-running application development" engineering post.
public enum WritingCriterion: String, Codable, CaseIterable {
    case narrativeCoherence = "narrativeCoherence"
    case originality        = "originality"
    case craft              = "craft"
    case planConsistency    = "planConsistency"

    public var displayName: String {
        switch self {
        case .narrativeCoherence: return "Narrative Coherence"
        case .originality:        return "Originality"
        case .craft:              return "Craft"
        case .planConsistency:    return "Plan Consistency"
        }
    }

    /// Human-readable rubric sent to the evaluator agent in its system prompt.
    public var rubric: String {
        switch self {
        case .narrativeCoherence:
            return "Does the writing flow logically? Are plot points connected? Are character actions motivated? Does it build naturally on prior sections?"
        case .originality:
            return "Are there fresh ideas, a distinctive voice, or unique images? Penalise clichés and generic AI writing patterns (vague metaphors, meandering openings, purple-gradient prose)."
        case .craft:
            return "Technical quality: varied sentence structures, show-don't-tell, sensory details, pacing control, and strong dialogue where present."
        case .planConsistency:
            return "Does the section fulfil its purpose, deliver all contracted key elements, and stay within the agreed tone and word-count range?"
        }
    }
}

// MARK: - Criterion Score

/// Score and feedback for one criterion in a section evaluation.
public struct CriterionScore: Codable {
    public let criterion: WritingCriterion
    /// Raw score on a 1–10 scale (clamped at init).
    public let score: Int
    public let feedback: String

    public init(criterion: WritingCriterion, score: Int, feedback: String) {
        self.criterion = criterion
        self.score = max(1, min(10, score))
        self.feedback = feedback
    }

    /// Returns true when the score meets the default threshold (7).
    public var passedDefault: Bool { score >= 7 }

    /// Determines whether this score meets or exceeds a specified threshold.
/// - Parameter threshold: The minimum score required to be considered passing.
/// - Returns: `true` if the score is greater than or equal to `threshold`, `false` otherwise.
    public func passed(threshold: Int) -> Bool { score >= threshold }
}

// MARK: - Writing Plan

/// A single chunk of work the generator agent will produce.
public struct WritingSection: Codable, Identifiable {
    public let id: UUID
    /// 1-based ordering within the plan.
    public let sequenceNumber: Int
    public let title: String
    /// Why this section exists — what it must accomplish for the story.
    public let purpose: String
    /// Concrete story elements that must appear in this section.
    public let keyElements: [String]

    public init(
        id: UUID = UUID(),
        sequenceNumber: Int,
        title: String,
        purpose: String,
        keyElements: [String]
    ) {
        self.id = id
        self.sequenceNumber = sequenceNumber
        self.title = title
        self.purpose = purpose
        self.keyElements = keyElements
    }
}

/// Expanded writing plan produced by the planner agent.
public struct WritingPlan: Codable, Identifiable {
    public let id: UUID
    public let title: String
    public let genre: String?
    /// Overall emotional and stylistic register (e.g. "melancholic and hopeful").
    public let tone: String
    public let targetAudience: String?
    public let synopsis: String
    public let sections: [WritingSection]
    /// Brief character descriptions (name + role).
    public let characters: [String]
    public let themes: [String]
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        title: String,
        genre: String? = nil,
        tone: String,
        targetAudience: String? = nil,
        synopsis: String,
        sections: [WritingSection],
        characters: [String] = [],
        themes: [String] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.genre = genre
        self.tone = tone
        self.targetAudience = targetAudience
        self.synopsis = synopsis
        self.sections = sections
        self.characters = characters
        self.themes = themes
        self.createdAt = createdAt
    }

    /// Compact summary passed as a handoff artifact between agent calls.
    public var handoffSummary: String {
        let sectionList = sections
            .map { "\($0.sequenceNumber). \($0.title) — \($0.purpose)" }
            .joined(separator: "\n")
        return """
        Title: \(title)
        Genre: \(genre ?? "unspecified")
        Tone: \(tone)
        Synopsis: \(synopsis)
        Characters: \(characters.joined(separator: "; "))
        Themes: \(themes.joined(separator: ", "))
        Sections:
        \(sectionList)
        """
    }
}

// MARK: - Section Contract

/// Agreed-upon success criteria negotiated before a section is written.
///
/// Mirrors the "sprint contract" from the harness design post — both the
/// generator and evaluator agree on what "done" looks like before any prose is produced.
public struct SectionContract: Codable, Identifiable {
    public let id: UUID
    public let sectionId: UUID
    /// High-level narrative goals the section must accomplish.
    public let goals: [String]
    /// Verifiable criteria the evaluator will check.
    public let successCriteria: [String]
    public let wordCountMin: Int?
    public let wordCountMax: Int?
    /// Any extra tone or style notes specific to this section.
    public let toneNotes: String?

    public init(
        id: UUID = UUID(),
        sectionId: UUID,
        goals: [String],
        successCriteria: [String],
        wordCountMin: Int? = nil,
        wordCountMax: Int? = nil,
        toneNotes: String? = nil
    ) {
        self.id = id
        self.sectionId = sectionId
        self.goals = goals
        self.successCriteria = successCriteria
        self.wordCountMin = wordCountMin
        self.wordCountMax = wordCountMax
        self.toneNotes = toneNotes
    }

    /// Human-readable summary included in generator and evaluator prompts.
    public var description: String {
        var parts: [String] = []
        parts.append("Goals:\n" + goals.map { "• \($0)" }.joined(separator: "\n"))
        parts.append("Success Criteria:\n" + successCriteria.map { "• \($0)" }.joined(separator: "\n"))
        if let lo = wordCountMin, let hi = wordCountMax {
            parts.append("Word Count: \(lo)–\(hi) words")
        }
        if let notes = toneNotes {
            parts.append("Tone Notes: \(notes)")
        }
        return parts.joined(separator: "\n\n")
    }
}

// MARK: - Section Evaluation

/// Evaluator agent's scored assessment of one section revision.
public struct WritingSectionEvaluation: Codable, Identifiable {
    public let id: UUID
    public let sectionId: UUID
    public let scores: [CriterionScore]
    public let overallFeedback: String
    /// Which revision attempt this evaluation covers (1-based).
    public let revision: Int
    public let evaluatedAt: Date

    public init(
        id: UUID = UUID(),
        sectionId: UUID,
        scores: [CriterionScore],
        overallFeedback: String,
        revision: Int,
        evaluatedAt: Date = Date()
    ) {
        self.id = id
        self.sectionId = sectionId
        self.scores = scores
        self.overallFeedback = overallFeedback
        self.revision = revision
        self.evaluatedAt = evaluatedAt
    }

    /// True when every criterion score meets the default threshold of 7.
    public var overallPassedDefault: Bool {
        scores.allSatisfy { $0.passedDefault }
    }

    /// Checks whether every criterion score meets or exceeds the given threshold.
    /// - Parameter threshold: Minimum score required for a criterion to be considered passing.
    /// - Returns: `true` if all criterion scores are greater than or equal to `threshold`, `false` otherwise.
    public func overallPassed(threshold: Int) -> Bool {
        scores.allSatisfy { $0.passed(threshold: threshold) }
    }

    public var averageScore: Double {
        guard !scores.isEmpty else { return 0 }
        return Double(scores.reduce(0) { $0 + $1.score }) / Double(scores.count)
    }

    /// Returns the scores as a dictionary keyed by criterion display name.
    public var scoresByName: [String: Int] {
        Dictionary(uniqueKeysWithValues: scores.map { ($0.criterion.displayName, $0.score) })
    }
}

// MARK: - Section Result

/// Completed record for one section: plan, contract, final prose, and evaluation.
public struct SectionResult: Codable, Identifiable {
    public let id: UUID
    public let section: WritingSection
    public let contract: SectionContract
    /// Best version of the generated prose after all revision cycles.
    public let generatedContent: String
    /// Evaluation of the final accepted content.
    public let evaluation: WritingSectionEvaluation
    /// How many revision cycles were needed (1 = passed on first attempt).
    public let totalRevisions: Int
    /// Summary passed to the generator for the next section.
    public let handoffContext: String

    public init(
        id: UUID = UUID(),
        section: WritingSection,
        contract: SectionContract,
        generatedContent: String,
        evaluation: WritingSectionEvaluation,
        totalRevisions: Int,
        handoffContext: String
    ) {
        self.id = id
        self.section = section
        self.contract = contract
        self.generatedContent = generatedContent
        self.evaluation = evaluation
        self.totalRevisions = totalRevisions
        self.handoffContext = handoffContext
    }
}

// MARK: - Quality Report

/// Aggregate quality statistics for a complete harness run.
public struct HarnessQualityReport: Codable {
    /// Average score per criterion, keyed by `WritingCriterion.rawValue`.
    public let averageScoresByCriterion: [String: Double]
    public let sectionsPassedFirstAttempt: Int
    public let totalSections: Int
    public let totalRevisions: Int

    public var passRate: Double {
        guard totalSections > 0 else { return 0 }
        return Double(sectionsPassedFirstAttempt) / Double(totalSections)
    }

    public init(
        averageScoresByCriterion: [String: Double],
        sectionsPassedFirstAttempt: Int,
        totalSections: Int,
        totalRevisions: Int
    ) {
        self.averageScoresByCriterion = averageScoresByCriterion
        self.sectionsPassedFirstAttempt = sectionsPassedFirstAttempt
        self.totalSections = totalSections
        self.totalRevisions = totalRevisions
    }
}

// MARK: - Harness Result

/// Final output of a complete multi-agent harness run.
public struct HarnessResult: Codable, Identifiable {
    public let id: UUID
    public let plan: WritingPlan
    public let sectionResults: [SectionResult]
    /// Full prose assembled from all section results in sequence order.
    public let assembledDocument: String
    public let qualityReport: HarnessQualityReport
    public let completedAt: Date

    public init(
        id: UUID = UUID(),
        plan: WritingPlan,
        sectionResults: [SectionResult],
        assembledDocument: String,
        qualityReport: HarnessQualityReport,
        completedAt: Date = Date()
    ) {
        self.id = id
        self.plan = plan
        self.sectionResults = sectionResults
        self.assembledDocument = assembledDocument
        self.qualityReport = qualityReport
        self.completedAt = completedAt
    }
}

// MARK: - Harness Errors

/// Errors thrown by `MultiAgentHarness`.
public enum HarnessError: LocalizedError {
    case emptyPrompt
    case plannerFailed(String)
    case invalidPlanJSON(String)
    case contractNegotiationFailed(sectionTitle: String)
    case generationFailed(sectionTitle: String, reason: String)
    case evaluationFailed(sectionTitle: String, reason: String)
    case invalidEvaluationJSON(String)
    case maxRevisionsExceeded(sectionTitle: String, revisions: Int)

    public var errorDescription: String? {
        switch self {
        case .emptyPrompt:
            return "Writing prompt must not be empty"
        case .plannerFailed(let reason):
            return "Planner agent failed: \(reason)"
        case .invalidPlanJSON(let detail):
            return "Planner returned invalid JSON: \(detail)"
        case .contractNegotiationFailed(let title):
            return "Could not negotiate a section contract for '\(title)'"
        case .generationFailed(let title, let reason):
            return "Generator failed for section '\(title)': \(reason)"
        case .evaluationFailed(let title, let reason):
            return "Evaluator failed for section '\(title)': \(reason)"
        case .invalidEvaluationJSON(let detail):
            return "Evaluator returned invalid JSON: \(detail)"
        case .maxRevisionsExceeded(let title, let revisions):
            return "Section '\(title)' could not pass quality checks after \(revisions) revision(s)"
        }
    }
}
