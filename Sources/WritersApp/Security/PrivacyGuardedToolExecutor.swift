import Foundation

/// Runs tool output through the privacy gate before the model can see it.
///
/// Stored document text can contain personal data even when the user's prompt is clean,
/// so tool results are checked on the way back to the model.
///
/// A blocked result throws. The tool loop turns that into an error result for the model,
/// so the content is never sent. The error text names pattern types only, never the value.
public final class PrivacyGuardedToolExecutor: AIToolExecutor {

    private let inner: AIToolExecutor
    private let router: PrivacyRouter

    public init(inner: AIToolExecutor, router: PrivacyRouter) {
        self.inner = inner
        self.router = router
    }

    public func executeTool(name: String, input: [String: Any]) async throws -> String {
        let output = try await inner.executeTool(name: name, input: input)
        if case .blocked(let reason) = router.route(output) {
            throw HermesError.privacyBlocked(reason)
        }
        return output
    }
}
