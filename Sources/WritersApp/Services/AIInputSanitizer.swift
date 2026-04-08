import Foundation

// MARK: - AI Input Sanitizer

/// Sanitizes user-supplied text before it is embedded in AI API prompts.
///
/// Implements the "skeptical input" security pattern: treat user text as potentially
/// hostile, detect prompt-injection attempts, and enforce length limits so that
/// malicious inputs cannot overflow context windows or manipulate model behavior.
///
/// Usage:
/// ```swift
/// let sanitizer = AIInputSanitizer()
/// let result = sanitizer.sanitize(userText)
/// if result.hasSuspiciousPatterns {
///     // log / warn; result.sanitizedText is still safe to send
/// }
/// sendToAPI(result.sanitizedText)
/// ```
public struct AIInputSanitizer {

    // MARK: - Types

    public enum SanitizationIssue: Equatable {
        /// A known prompt-injection phrase was detected.
        case injectionPatternDetected(pattern: String)
        /// The input exceeded the character limit and was truncated.
        case excessiveLength(actual: Int, limit: Int)
    }

    public struct SanitizationResult {
        /// The text that is safe to embed in an API prompt.
        public let sanitizedText: String
        /// Issues found during sanitization.
        public let issues: [SanitizationIssue]

        public var wasTruncated: Bool {
            issues.contains {
                if case .excessiveLength = $0 { return true }
                return false
            }
        }

        public var hasSuspiciousPatterns: Bool {
            issues.contains {
                if case .injectionPatternDetected = $0 { return true }
                return false
            }
        }
    }

    // MARK: - Configuration

    /// Maximum character length before the input is truncated.
    public let maxLength: Int

    public init(maxLength: Int = 50_000) {
        self.maxLength = maxLength
    }

    // MARK: - Injection Pattern List

    /// Lower-cased fragments that indicate a prompt-injection attempt.
    ///
    /// These patterns are checked case-insensitively against the input. Legitimate
    /// fiction that references AI systems may trigger a warning, but the text is
    /// never blocked outright — callers decide how to act on the issues list.
    private static let injectionPhrases: [String] = [
        "ignore previous instructions",
        "ignore all previous",
        "ignore the above instructions",
        "disregard previous instructions",
        "disregard all previous",
        "forget previous instructions",
        "you are now",
        "pretend you are",
        "act as if you are",
        "your new instructions are",
        "override your instructions",
        "override the system prompt",
        "new system prompt",
        "system prompt:",
        "[system]",
        "<|system|>",
        "<system>",
        "###instruction###",
        "### new instruction",
        "jailbreak",
        "do anything now",
        "dan mode",
        "developer mode enabled",
        "ignore safety",
        "bypass restrictions",
    ]

    // MARK: - Public API

    /// Sanitize a string before embedding it in an AI prompt.
    ///
    /// - Parameter text: Raw user-supplied text (document content, topic, instruction, etc.).
    /// - Returns: A `SanitizationResult` with a safe text string and a list of any issues
    ///   that were found. The caller decides whether to log, reject, or proceed.
    public func sanitize(_ text: String) -> SanitizationResult {
        var issues: [SanitizationIssue] = []
        var sanitized = text

        // 1. Enforce length limit — truncate, do not reject outright.
        if text.count > maxLength {
            sanitized = String(text.prefix(maxLength))
            issues.append(.excessiveLength(actual: text.count, limit: maxLength))
        }

        // 2. Detect injection patterns in the (possibly truncated) text.
        let lower = sanitized.lowercased()
        for phrase in Self.injectionPhrases where lower.contains(phrase) {
            issues.append(.injectionPatternDetected(pattern: phrase))
        }

        return SanitizationResult(sanitizedText: sanitized, issues: issues)
    }

    /// Quick predicate: returns `true` if the text contains any known injection phrases.
    public func containsInjectionPatterns(_ text: String) -> Bool {
        let lower = text.lowercased()
        return Self.injectionPhrases.contains { lower.contains($0) }
    }
}
