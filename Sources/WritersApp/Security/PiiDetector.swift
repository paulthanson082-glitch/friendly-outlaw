import Foundation

// MARK: - Types

/// Severity of a PII pattern. Any match, high or medium, blocks cloud routing.
public enum PiiSeverity: String, Codable {
    case high
    case medium
}

/// A single detection rule.
public struct PiiPattern {
    public let name: String
    public let severity: PiiSeverity
    public let regex: NSRegularExpression
    /// Optional extra check that runs on each regex hit to reduce false positives.
    public let validate: ((String) -> Bool)?

    public init(
        name: String,
        severity: PiiSeverity,
        regex: NSRegularExpression,
        validate: ((String) -> Bool)? = nil
    ) {
        self.name = name
        self.severity = severity
        self.regex = regex
        self.validate = validate
    }
}

/// A detection result. Carries the pattern name only, never the matched text.
public struct PiiMatch: Equatable {
    public let patternName: String
    public let severity: PiiSeverity
}

// MARK: - Detector

/// Scans text for personal data before it can leave the device.
public final class PiiDetector {

    public let patterns: [PiiPattern]

    public init(patterns: [PiiPattern] = PiiDetector.standardPatterns) {
        self.patterns = patterns
    }

    /// Returns one match per pattern that fires. Empty means no PII was found.
    public func scan(_ text: String) -> [PiiMatch] {
        guard !text.isEmpty else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        var results: [PiiMatch] = []

        for pattern in patterns {
            let hits = pattern.regex.matches(in: text, options: [], range: range)
            let confirmed = hits.contains { hit in
                guard let swiftRange = Range(hit.range, in: text) else { return false }
                let value = String(text[swiftRange])
                return pattern.validate?(value) ?? true
            }
            if confirmed {
                results.append(PiiMatch(patternName: pattern.name, severity: pattern.severity))
            }
        }
        return results
    }

    // MARK: - Standard Patterns

    /// Standard patterns. Recovery-specific patterns (case numbers, client IDs)
    /// are not included yet and must be added before About Time data is in scope.
    public static let standardPatterns: [PiiPattern] = [
        PiiPattern(
            name: "ssn",
            severity: .high,
            regex: compile(#"\b\d{3}-\d{2}-\d{4}\b"#)
        ),
        PiiPattern(
            name: "credit_card",
            severity: .high,
            // Card-shaped groups only, anchored on digit boundaries. A greedy run match
            // swallowed leading digits ("Order 124 4111 ..."), and testing every sub-window
            // with Luhn gave false positives. Each group is Luhn-checked as a whole.
            regex: compile(
                #"(?<!\d)(?:\d{4}(?:[ -]?\d{4}){2}[ -]?\d{4}|\d{4}[ -]?\d{6}[ -]?\d{5})(?!\d)"#
            ),
            validate: luhnValid
        ),
        PiiPattern(
            name: "email",
            severity: .medium,
            regex: compile(#"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}"#)
        ),
        PiiPattern(
            name: "phone",
            severity: .medium,
            regex: compile(#"(?:\+?1[-. ]?)?\(?\d{3}\)?[-. ]?\d{3}[-. ]?\d{4}\b"#)
        ),
        // Only flags a date that follows a birth keyword. Plain dates such as
        // a letter dated 10/25/2026 are not personal data and must not block.
        PiiPattern(
            name: "date_of_birth",
            severity: .medium,
            regex: compile(
                #"(?i)\b(?:dob|date of birth|born(?: on)?)\W{0,3}(?:0?[1-9]|1[0-2])[/-](?:0?[1-9]|[12]\d|3[01])[/-](?:19|20)\d{2}\b"#
            )
        )
    ]

    // MARK: - Helpers

    private static func compile(_ pattern: String) -> NSRegularExpression {
        // Patterns are compile-time constants. A failure here is a programming error.
        // swiftlint:disable:next force_try
        try! NSRegularExpression(pattern: pattern, options: [])
    }

    /// Luhn checksum. Filters out digit runs that are not real card numbers.
    static func luhnValid(_ value: String) -> Bool {
        let digits = value.compactMap { $0.wholeNumberValue }
        guard (13...19).contains(digits.count) else { return false }

        var sum = 0
        for (index, digit) in digits.reversed().enumerated() {
            if index % 2 == 1 {
                let doubled = digit * 2
                sum += doubled > 9 ? doubled - 9 : doubled
            } else {
                sum += digit
            }
        }
        return sum % 10 == 0
    }
}
