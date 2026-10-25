import XCTest
@testable import WritersApp

final class PrivacyGuardedToolExecutorTests: XCTestCase {

    /// Returns fixed output and records calls, so the wrapper can be tested alone.
    private final class FakeExecutor: AIToolExecutor {
        let output: String
        private(set) var callCount = 0

        init(output: String) {
            self.output = output
        }

        func executeTool(name: String, input: [String: Any]) async throws -> String {
            callCount += 1
            return output
        }
    }

    func testCleanToolOutputPassesThrough() async throws {
        let inner = FakeExecutor(output: "Chapter one opens on a quiet harbor.")
        let guarded = PrivacyGuardedToolExecutor(inner: inner, router: PrivacyRouter())

        let result = try await guarded.executeTool(name: "get_document", input: [:])

        XCTAssertEqual(result, "Chapter one opens on a quiet harbor.")
        XCTAssertEqual(inner.callCount, 1)
    }

    func testPersonalDataInToolOutputIsBlocked() async {
        let inner = FakeExecutor(output: "Witness statement: call 555-867-5309 for details.")
        let guarded = PrivacyGuardedToolExecutor(inner: inner, router: PrivacyRouter())

        do {
            _ = try await guarded.executeTool(name: "get_document", input: [:])
            XCTFail("Expected personal data in tool output to be blocked")
        } catch let error as HermesError {
            guard case .privacyBlocked(let reason) = error else {
                return XCTFail("Expected privacyBlocked, got \(error)")
            }
            XCTAssertFalse(reason.contains("555-867-5309"), "Blocked reason must not echo the value")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
}
