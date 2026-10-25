import Foundation

/// Where a piece of text is allowed to go.
public enum PrivacyRoute: Equatable {
    /// No personal data detected. Safe to send to a cloud model.
    case cloud
    /// Personal data detected. Must not leave the device.
    /// Local inference is not built yet, so the request is blocked (fail closed).
    /// A `.local` case gets added here once a local backend (Ollama or MLX) exists.
    case blocked(reason: String)
}

/// Decides whether text can be sent to a cloud model.
public struct PrivacyRouter {

    private let detector: PiiDetector

    public init(detector: PiiDetector = PiiDetector()) {
        self.detector = detector
    }

    public func route(_ text: String) -> PrivacyRoute {
        let matches = detector.scan(text)
        guard !matches.isEmpty else { return .cloud }

        // Report pattern names only. Never echo the matched text back to the user or logs.
        let names = Set(matches.map { $0.patternName }).sorted().joined(separator: ", ")
        return .blocked(
            reason: "Possible personal data detected (\(names)). Hermes won't send it to a cloud model."
        )
    }
}
