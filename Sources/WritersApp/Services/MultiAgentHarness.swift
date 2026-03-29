import Foundation

/// Three-agent writing harness inspired by the GAN-inspired architecture described in
/// Anthropic's "Harness design for long-running application development" post.
///
/// Architecture:
/// - **Planner**: Expands a short user prompt into a structured `WritingPlan`.
/// - **Generator**: Writes one section at a time following a negotiated `SectionContract`.
/// - **Evaluator**: Scores each draft against four writing criteria and provides
///   actionable feedback. If the section fails the quality threshold the generator
///   revises it, up to `HarnessConfiguration.maxRevisionsPerSection` times.
///
/// Context resets between agent calls are handled naturally — each agent role is a
/// separate `AIService.performAgentTask()` call, so no single context window
/// accumulates across the full run. Structured handoff artifacts (the `WritingPlan`,
/// `SectionContract`, and per-section summary strings) carry state between calls.
public class MultiAgentHarness {

    private let aiService: AIService
    public let configuration: HarnessConfiguration

    public init(aiService: AIService, configuration: HarnessConfiguration = .default) {
        self.aiService = aiService
        self.configuration = configuration
    }

    // MARK: - Public Entry Points

    /// Run the full three-agent loop starting from a short writing prompt.
    ///
    /// 1. The planner expands `prompt` into a `WritingPlan`.
    /// 2. For each section the harness negotiates a `SectionContract`.
    /// 3. The generator writes the section.
    /// 4. The evaluator scores the draft; if it fails, the generator revises.
    /// 5. All accepted sections are assembled into a final document.
    ///
    /// - Parameter prompt: A 1–4 sentence description of the writing task.
    /// - Returns: A `HarnessResult` with the assembled prose, plan, and quality report.
    public func run(prompt: String) async throws -> HarnessResult {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw HarnessError.emptyPrompt }

        let plan = try await createPlan(prompt: trimmed)
        return try await run(plan: plan)
    }

    /// Run the generator–evaluator loop using a pre-built plan (skips the planner).
    public func run(plan: WritingPlan) async throws -> HarnessResult {
        let sectionsToProcess = Array(plan.sections.prefix(configuration.maxSections))
        var sectionResults: [SectionResult] = []
        var previousContext = ""

        for section in sectionsToProcess {
            let contract = try await negotiateContract(
                for: section,
                plan: plan,
                previousContext: previousContext
            )

            let result = try await processSection(
                section,
                contract: contract,
                plan: plan,
                previousContext: previousContext
            )

            sectionResults.append(result)
            previousContext = result.handoffContext
        }

        let assembled = assembleDocument(from: sectionResults, plan: plan)
        let report    = buildQualityReport(from: sectionResults)

        return HarnessResult(
            plan: plan,
            sectionResults: sectionResults,
            assembledDocument: assembled,
            qualityReport: report,
            completedAt: Date()
        )
    }

    // MARK: - Planner Agent

    /// Expand a user prompt into a structured `WritingPlan`.
    ///
    /// The planner is instructed to be ambitious about scope and to stay at the
    /// product / narrative level rather than dictating implementation details.
    public func createPlan(prompt: String) async throws -> WritingPlan {
        let systemPrompt = """
        You are an expert writing planner. Given a short writing prompt, expand it into a \
        detailed, structured writing plan.

        Respond with ONLY a JSON object matching this exact schema (no markdown, no prose):
        {
          "title": "string",
          "genre": "string or null",
          "tone": "string",
          "targetAudience": "string or null",
          "synopsis": "string (2-4 sentences)",
          "sections": [
            {
              "sequenceNumber": 1,
              "title": "string",
              "purpose": "string (1 sentence — what must this section accomplish?)",
              "keyElements": ["string", "string"]
            }
          ],
          "characters": ["Name — role (1 sentence)", ...],
          "themes": ["string", ...]
        }

        Rules:
        - Produce 3–8 sections unless the prompt clearly calls for more.
        - Be ambitious: create a complete, satisfying arc.
        - keyElements must be concrete and verifiable (e.g. "Maya discovers the signal at 3 am", not "tension").
        - Do NOT include any text outside the JSON object.
        """

        let userPrompt = "Writing prompt: \(prompt)"

        let rawResponse: String
        do {
            rawResponse = try await aiService.performAgentTask(
                systemPrompt: systemPrompt,
                userPrompt: userPrompt
            )
        } catch {
            throw HarnessError.plannerFailed(error.localizedDescription)
        }

        return try parsePlan(from: rawResponse, originalPrompt: prompt)
    }

    // MARK: - Contract Negotiation

    /// Ask the planner/generator to propose concrete success criteria for a section.
    ///
    /// The contract mirrors the "sprint contract" from the harness design post:
    /// both agents agree on what "done" looks like before any prose is written.
    private func negotiateContract(
        for section: WritingSection,
        plan: WritingPlan,
        previousContext: String
    ) async throws -> SectionContract {
        let systemPrompt = """
        You are a writing project manager. Given a section brief and the overall writing plan, \
        produce a concrete section contract that the writer and editor will both use to verify success.

        Respond with ONLY a JSON object (no markdown, no prose):
        {
          "goals": ["string", ...],
          "successCriteria": ["string", ...],
          "wordCountMin": integer or null,
          "wordCountMax": integer or null,
          "toneNotes": "string or null"
        }

        Rules:
        - 2–4 goals describing what the section must accomplish narratively.
        - 3–6 success criteria that are verifiable (can an editor confirm yes/no?).
        - Word count should be proportional to section complexity (typically 300–800 words).
        - Do NOT include any text outside the JSON object.
        """

        let contextBlock = previousContext.isEmpty
            ? "This is the opening section."
            : "Story so far:\n\(previousContext)"

        let userPrompt = """
        Overall plan:
        \(plan.handoffSummary)

        \(contextBlock)

        Section to contract:
        Title: \(section.title)
        Purpose: \(section.purpose)
        Key elements: \(section.keyElements.joined(separator: "; "))
        """

        let rawResponse: String
        do {
            rawResponse = try await aiService.performAgentTask(
                systemPrompt: systemPrompt,
                userPrompt: userPrompt
            )
        } catch {
            throw HarnessError.contractNegotiationFailed(sectionTitle: section.title)
        }

        return try parseContract(from: rawResponse, sectionId: section.id)
    }

    // MARK: - Section Processing (generator + evaluator loop)

    private func processSection(
        _ section: WritingSection,
        contract: SectionContract,
        plan: WritingPlan,
        previousContext: String
    ) async throws -> SectionResult {
        guard configuration.maxRevisionsPerSection >= 1 else {
            throw HarnessError.generationFailed(
                sectionTitle: section.title,
                reason: "maxRevisionsPerSection must be at least 1"
            )
        }

        var bestContent = ""
        var bestEvaluation: WritingSectionEvaluation?
        var revision = 0
        var lastFeedback = ""

        while revision < configuration.maxRevisionsPerSection {
            revision += 1

            let content = try await generateSection(
                section,
                contract: contract,
                plan: plan,
                previousContext: previousContext,
                priorFeedback: lastFeedback
            )

            let evaluation = try await evaluateSection(
                content: content,
                contract: contract,
                section: section,
                plan: plan,
                revision: revision
            )

            // Keep the best version seen so far (highest average score)
            if let current = bestEvaluation {
                if evaluation.averageScore > current.averageScore {
                    bestContent = content
                    bestEvaluation = evaluation
                }
            } else {
                bestContent = content
                bestEvaluation = evaluation
            }

            if evaluation.overallPassed(threshold: configuration.qualityThreshold) {
                break
            }

            lastFeedback = evaluation.overallFeedback
        }

        // bestEvaluation is guaranteed non-nil: the loop runs at least once (guard above)
        // and always assigns bestEvaluation on the first iteration.
        let finalEvaluation = bestEvaluation!  // safe: loop body always executes at least once

        // Throw if the section never reached the quality bar after all revisions.
        if !finalEvaluation.overallPassed(threshold: configuration.qualityThreshold) {
            throw HarnessError.maxRevisionsExceeded(
                sectionTitle: section.title,
                revisions: revision
            )
        }

        let handoff = buildHandoffContext(
            section: section,
            content: bestContent,
            evaluation: finalEvaluation
        )

        return SectionResult(
            section: section,
            contract: contract,
            generatedContent: bestContent,
            evaluation: finalEvaluation,
            totalRevisions: revision,
            handoffContext: handoff
        )
    }

    // MARK: - Generator Agent

    private func generateSection(
        _ section: WritingSection,
        contract: SectionContract,
        plan: WritingPlan,
        previousContext: String,
        priorFeedback: String
    ) async throws -> String {
        let systemPrompt = """
        You are a skilled creative writer. Write the requested section of the story exactly \
        as specified in the contract. Your only output should be the finished prose — no \
        preamble, no commentary, no section headings unless they naturally belong in the text.

        Quality standards (these will be scored by an independent editor):
        \(WritingCriterion.allCases.map { "• \($0.displayName): \($0.rubric)" }.joined(separator: "\n"))

        Avoid generic AI writing patterns: vague metaphors, meandering openers, \
        over-explained emotions, purple prose, and cliché sentence structures.
        """

        var userParts: [String] = []
        userParts.append("Overall plan:\n\(plan.handoffSummary)")

        if previousContext.isEmpty {
            userParts.append("This is the opening section of the story.")
        } else {
            userParts.append("Story so far:\n\(previousContext)")
        }

        userParts.append("Section to write:\nTitle: \(section.title)\nPurpose: \(section.purpose)")
        userParts.append("Contract:\n\(contract.description)")

        if !priorFeedback.isEmpty {
            userParts.append("Editor feedback on your previous draft (address all points):\n\(priorFeedback)")
        }

        let userPrompt = userParts.joined(separator: "\n\n")

        do {
            return try await aiService.performAgentTask(
                systemPrompt: systemPrompt,
                userPrompt: userPrompt
            )
        } catch {
            throw HarnessError.generationFailed(
                sectionTitle: section.title,
                reason: error.localizedDescription
            )
        }
    }

    // MARK: - Evaluator Agent

    private func evaluateSection(
        content: String,
        contract: SectionContract,
        section: WritingSection,
        plan: WritingPlan,
        revision: Int
    ) async throws -> WritingSectionEvaluation {
        let criteriaBlock = WritingCriterion.allCases
            .map { "• \($0.rawValue) (\($0.displayName)): \($0.rubric)" }
            .joined(separator: "\n")

        let systemPrompt = """
        You are a rigorous, unsparing writing editor. Score the provided section against \
        each criterion on a 1–10 scale. Be critical — a 7 means "meets professional standard", \
        not "pretty good for AI". A score below 7 means the criterion fails and the writer must revise.

        Criteria:
        \(criteriaBlock)

        Respond with ONLY a JSON object (no markdown, no prose):
        {
          "scores": {
            "narrativeCoherence": {"score": integer, "feedback": "string"},
            "originality":        {"score": integer, "feedback": "string"},
            "craft":              {"score": integer, "feedback": "string"},
            "planConsistency":    {"score": integer, "feedback": "string"}
          },
          "overallFeedback": "string (2-4 sentences summarising what must change if revising)"
        }

        If revising: overallFeedback must be concrete and actionable, not vague praise.
        """

        let userPrompt = """
        Plan summary:
        \(plan.handoffSummary)

        Section contract:
        \(contract.description)

        Draft (revision \(revision)):
        \(content)
        """

        let rawResponse: String
        do {
            rawResponse = try await aiService.performAgentTask(
                systemPrompt: systemPrompt,
                userPrompt: userPrompt
            )
        } catch {
            throw HarnessError.evaluationFailed(
                sectionTitle: section.title,
                reason: error.localizedDescription
            )
        }

        return try parseEvaluation(
            from: rawResponse,
            sectionId: section.id,
            revision: revision
        )
    }

    // MARK: - JSON Parsing

    /// Extracts a JSON object from a response that may be wrapped in markdown fences.
    private func extractJSON(from text: String) -> String {
        // Strip ```json ... ``` fences
        if let fenceStart = text.range(of: "```json\n") ?? text.range(of: "```json\r\n") {
            let afterFence = fenceStart.upperBound
            if let fenceEnd = text.range(of: "```", range: afterFence..<text.endIndex) {
                return String(text[afterFence..<fenceEnd.lowerBound])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        // Strip generic ``` fences
        if let fenceStart = text.range(of: "```\n") ?? text.range(of: "```\r\n") {
            let afterFence = fenceStart.upperBound
            if let fenceEnd = text.range(of: "```", range: afterFence..<text.endIndex) {
                return String(text[afterFence..<fenceEnd.lowerBound])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        // Try to find a raw JSON object
        if let start = text.firstIndex(of: "{"), let end = text.lastIndex(of: "}") {
            if start <= end {
                return String(text[start...end])
            }
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func parsePlan(from rawResponse: String, originalPrompt: String) throws -> WritingPlan {
        let jsonString = extractJSON(from: rawResponse)
        guard let data = jsonString.data(using: .utf8),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw HarnessError.invalidPlanJSON("Could not parse JSON from planner response")
        }

        guard let title = root["title"] as? String, !title.isEmpty else {
            throw HarnessError.invalidPlanJSON("Missing 'title' field")
        }
        guard let tone = root["tone"] as? String, !tone.isEmpty else {
            throw HarnessError.invalidPlanJSON("Missing 'tone' field")
        }
        guard let synopsis = root["synopsis"] as? String, !synopsis.isEmpty else {
            throw HarnessError.invalidPlanJSON("Missing 'synopsis' field")
        }
        guard let sectionsArray = root["sections"] as? [[String: Any]], !sectionsArray.isEmpty else {
            throw HarnessError.invalidPlanJSON("Missing or empty 'sections' array")
        }

        let sections: [WritingSection] = try sectionsArray.map { dict in
            guard let seq = dict["sequenceNumber"] as? Int,
                  let sTitle = dict["title"] as? String,
                  let purpose = dict["purpose"] as? String else {
                throw HarnessError.invalidPlanJSON("Section missing required fields")
            }
            let keyElements = dict["keyElements"] as? [String] ?? []
            return WritingSection(
                sequenceNumber: seq,
                title: sTitle,
                purpose: purpose,
                keyElements: keyElements
            )
        }

        let characters = root["characters"] as? [String] ?? []
        let themes      = root["themes"] as? [String] ?? []
        let genre       = root["genre"] as? String
        let audience    = root["targetAudience"] as? String

        return WritingPlan(
            title: title,
            genre: genre,
            tone: tone,
            targetAudience: audience,
            synopsis: synopsis,
            sections: sections.sorted { $0.sequenceNumber < $1.sequenceNumber },
            characters: characters,
            themes: themes
        )
    }

    private func parseContract(from rawResponse: String, sectionId: UUID) throws -> SectionContract {
        let jsonString = extractJSON(from: rawResponse)
        guard let data = jsonString.data(using: .utf8),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            // Fall back to a minimal default contract rather than failing hard
            return SectionContract(
                sectionId: sectionId,
                goals: ["Write the section as described in the plan"],
                successCriteria: ["Section is written with good quality"],
                wordCountMin: 300,
                wordCountMax: 700,
                toneNotes: nil
            )
        }

        let goals            = root["goals"] as? [String] ?? ["Write the section as described"]
        let successCriteria  = root["successCriteria"] as? [String] ?? ["Section meets quality bar"]
        let wordCountMin     = root["wordCountMin"] as? Int
        let wordCountMax     = root["wordCountMax"] as? Int
        let toneNotes        = root["toneNotes"] as? String

        return SectionContract(
            sectionId: sectionId,
            goals: goals,
            successCriteria: successCriteria,
            wordCountMin: wordCountMin,
            wordCountMax: wordCountMax,
            toneNotes: toneNotes
        )
    }

    private func parseEvaluation(
        from rawResponse: String,
        sectionId: UUID,
        revision: Int
    ) throws -> WritingSectionEvaluation {
        let jsonString = extractJSON(from: rawResponse)
        guard let data = jsonString.data(using: .utf8),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw HarnessError.invalidEvaluationJSON("Could not parse JSON from evaluator response")
        }

        guard let scoresDict = root["scores"] as? [String: Any] else {
            throw HarnessError.invalidEvaluationJSON("Missing 'scores' object")
        }

        var criterionScores: [CriterionScore] = []
        for criterion in WritingCriterion.allCases {
            if let entry = scoresDict[criterion.rawValue] as? [String: Any],
               let score = entry["score"] as? Int,
               let feedback = entry["feedback"] as? String {
                criterionScores.append(CriterionScore(
                    criterion: criterion,
                    score: score,
                    feedback: feedback
                ))
            } else {
                // Missing criterion — assign a neutral passing score so the run continues
                criterionScores.append(CriterionScore(
                    criterion: criterion,
                    score: 7,
                    feedback: "Score not provided by evaluator."
                ))
            }
        }

        let overallFeedback = root["overallFeedback"] as? String ?? ""

        return WritingSectionEvaluation(
            sectionId: sectionId,
            scores: criterionScores,
            overallFeedback: overallFeedback,
            revision: revision
        )
    }

    // MARK: - Handoff & Assembly

    private func buildHandoffContext(
        section: WritingSection,
        content: String,
        evaluation: WritingSectionEvaluation
    ) -> String {
        let scoresSummary = evaluation.scores
            .map { "\($0.criterion.displayName): \($0.score)/10" }
            .joined(separator: ", ")

        // Summarise the content for the next generator call (avoid ballooning context)
        let contentPreview: String
        if content.count > 600 {
            let endIndex = content.index(content.startIndex, offsetBy: 600)
            contentPreview = String(content[..<endIndex]) + "…"
        } else {
            contentPreview = content
        }

        return """
        Section \(section.sequenceNumber): \(section.title)
        Quality scores: \(scoresSummary)
        Content excerpt:
        \(contentPreview)
        """
    }

    private func assembleDocument(from results: [SectionResult], plan: WritingPlan) -> String {
        let header = "# \(plan.title)\n\n"
        let body = results
            .sorted { $0.section.sequenceNumber < $1.section.sequenceNumber }
            .map { result in
                "## \(result.section.title)\n\n\(result.generatedContent)"
            }
            .joined(separator: "\n\n---\n\n")
        return header + body
    }

    private func buildQualityReport(from results: [SectionResult]) -> HarnessQualityReport {
        var totalsByCriterion: [String: Int] = [:]
        var countsByCriterion: [String: Int] = [:]
        var passedFirstAttempt = 0
        var totalRevisions = 0

        for result in results {
            if result.totalRevisions == 1 {
                passedFirstAttempt += 1
            }
            totalRevisions += result.totalRevisions

            for score in result.evaluation.scores {
                let key = score.criterion.rawValue
                totalsByCriterion[key, default: 0] += score.score
                countsByCriterion[key, default: 0] += 1
            }
        }

        var averages: [String: Double] = [:]
        for criterion in WritingCriterion.allCases {
            let key = criterion.rawValue
            let total = totalsByCriterion[key] ?? 0
            let count = countsByCriterion[key] ?? 0
            averages[key] = count > 0 ? Double(total) / Double(count) : 0
        }

        return HarnessQualityReport(
            averageScoresByCriterion: averages,
            sectionsPassedFirstAttempt: passedFirstAttempt,
            totalSections: results.count,
            totalRevisions: totalRevisions
        )
    }
}
