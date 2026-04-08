import Foundation

// MARK: - Model Performance Tracker

/// Tracks per-model AI response quality metrics to detect regressions and support
/// routing decisions.
///
/// Implements the "model performance tracking" pattern: record whether responses were
/// flagged as incorrect or uncertain, compute running flag rates, and alert callers
/// when a model's error rate exceeds the configured threshold.
///
/// Usage:
/// ```swift
/// let tracker = ModelPerformanceTracker()
/// tracker.recordResponse(modelId: model.rawValue, wasFlagged: false, wasUncertain: true)
///
/// if tracker.shouldRouteAway(from: model.rawValue) {
///     // switch to a different model
/// }
/// ```
public class ModelPerformanceTracker {

    // MARK: - Types

    /// Accumulated statistics for a single model.
    public struct ModelMetrics: Codable {
        /// Total number of responses recorded.
        public var totalResponses: Int = 0
        /// Responses explicitly flagged as likely incorrect or hallucinated.
        public var flaggedResponses: Int = 0
        /// Responses that acknowledged uncertainty (positive signal: reduces overconfidence).
        public var responsesWithUncertainty: Int = 0
        /// Responses that included supporting citations (positive signal: reduces hallucinations).
        public var responsesWithCitations: Int = 0

        /// Fraction of responses that were flagged (0.0–1.0).
        public var flagRate: Double {
            totalResponses == 0 ? 0.0 : Double(flaggedResponses) / Double(totalResponses)
        }

        /// Fraction of responses that admitted uncertainty (0.0–1.0).
        public var uncertaintyRate: Double {
            totalResponses == 0 ? 0.0 : Double(responsesWithUncertainty) / Double(totalResponses)
        }

        /// Fraction of responses that included citations (0.0–1.0).
        public var citationRate: Double {
            totalResponses == 0 ? 0.0 : Double(responsesWithCitations) / Double(totalResponses)
        }
    }

    // MARK: - Configuration

    /// Flag rate above which `shouldRouteAway(from:)` returns `true`.
    public let highFlagRateThreshold: Double

    // MARK: - State

    private var metrics: [String: ModelMetrics] = [:]

    // MARK: - Init

    public init(highFlagRateThreshold: Double = 0.25) {
        self.highFlagRateThreshold = highFlagRateThreshold
    }

    // MARK: - Recording

    /// Record the outcome of a single model response.
    ///
    /// - Parameters:
    ///   - modelId: The model identifier string (e.g. `AIModel.claude35Sonnet.rawValue`).
    ///   - wasFlagged: `true` if the response was identified as likely incorrect.
    ///   - wasUncertain: `true` if the response acknowledged uncertainty (reduces overconfidence).
    ///   - hadCitations: `true` if the response included supporting source citations.
    public func recordResponse(
        modelId: String,
        wasFlagged: Bool,
        wasUncertain: Bool = false,
        hadCitations: Bool = false
    ) {
        var m = metrics[modelId] ?? ModelMetrics()
        m.totalResponses += 1
        if wasFlagged { m.flaggedResponses += 1 }
        if wasUncertain { m.responsesWithUncertainty += 1 }
        if hadCitations { m.responsesWithCitations += 1 }
        metrics[modelId] = m
    }

    // MARK: - Querying

    /// Returns metrics for a model, or `nil` if no responses have been recorded.
    public func getMetrics(for modelId: String) -> ModelMetrics? {
        return metrics[modelId]
    }

    /// Current flag rate for a model (0.0 if no data).
    public func getFlagRate(for modelId: String) -> Double {
        return metrics[modelId]?.flagRate ?? 0.0
    }

    /// Returns `true` when the model's flag rate exceeds `highFlagRateThreshold`.
    ///
    /// Callers can use this to avoid routing requests to a degraded model version.
    public func shouldRouteAway(from modelId: String) -> Bool {
        return getFlagRate(for: modelId) > highFlagRateThreshold
    }

    /// Snapshot of all tracked models and their metrics.
    public func getAllMetrics() -> [String: ModelMetrics] {
        return metrics
    }

    /// Reset accumulated metrics for a model (e.g. after a version update resets the baseline).
    public func resetMetrics(for modelId: String) {
        metrics.removeValue(forKey: modelId)
    }

    /// Reset metrics for all models.
    public func resetAllMetrics() {
        metrics.removeAll()
    }
}
