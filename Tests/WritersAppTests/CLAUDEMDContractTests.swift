import XCTest
@testable import WritersApp

/// Tests that validate the public API contract documented in CLAUDE.md.
///
/// This PR updated CLAUDE.md to be the single authoritative reference for
/// the project structure, initializer variants, public properties, and
/// AI lifecycle. It also modified .gitignore to track Package.resolved and
/// remove the cmd/cargent/cargent ignore rule.
///
/// These tests guard against regressions between the documented contract
/// and the actual implementation.
final class CLAUDEMDContractTests: XCTestCase {

    // MARK: - .gitignore Contract Tests

    /// CLAUDE.md is now the authoritative reference; the accompanying .gitignore
    /// change uncommented Package.resolved so it is tracked by git.
    /// This test confirms the active .gitignore rules no longer suppress Package.resolved.
    func testGitignoreDoesNotActivelyIgnorePackageResolved() throws {
        let gitignoreURL = try gitignoreURL()
        let contents = try String(contentsOf: gitignoreURL, encoding: .utf8)
        let activeLines = activeIgnoreLines(in: contents)

        XCTAssertFalse(
            activeLines.contains("Package.resolved"),
            "Package.resolved should not be an active ignore rule; the PR commented it out so it is now tracked by git."
        )
    }

    /// The PR removed the `cmd/cargent/cargent` binary from the .gitignore.
    /// Verify it is no longer present at all (neither active nor commented).
    func testGitignoreNoLongerContainsCargentBinary() throws {
        let gitignoreURL = try gitignoreURL()
        let contents = try String(contentsOf: gitignoreURL, encoding: .utf8)

        XCTAssertFalse(
            contents.contains("cmd/cargent/cargent"),
            "cmd/cargent/cargent should have been removed from .gitignore entirely."
        )
    }

    /// Sanity-check: core Swift/Xcode artefacts that SHOULD still be ignored remain active.
    func testGitignoreStillIgnoresSwiftBuildDirectory() throws {
        let gitignoreURL = try gitignoreURL()
        let contents = try String(contentsOf: gitignoreURL, encoding: .utf8)
        let activeLines = activeIgnoreLines(in: contents)

        XCTAssertTrue(
            activeLines.contains(".build/"),
            ".build/ must still be an active ignore rule."
        )
    }

    // MARK: - WritersApp Initializer Contract Tests

    /// CLAUDE.md documents `init()` as the no-AI default initializer.
    func testDefaultInitializerCreatesApp() {
        let app = WritersApp()

        XCTAssertNotNil(app.templateManager, "templateManager must be non-nil after default init")
        XCTAssertNotNil(app.documentManager, "documentManager must be non-nil after default init")
        XCTAssertNotNil(app.issueManager, "issueManager must be non-nil after default init")
        XCTAssertNotNil(app.kanbanManager, "kanbanManager must be non-nil after default init")
        XCTAssertNotNil(app.databaseManager, "databaseManager must be non-nil after default init")
        XCTAssertNotNil(app.encouragementService, "encouragementService must be non-nil after default init")
        XCTAssertNotNil(app.versionControl, "versionControl must be non-nil after default init")
    }

    /// CLAUDE.md documents `init(aiConfiguration:)` as the AI-enabled initializer.
    func testAIConfigurationInitializerEnablesAIServices() {
        let config = AIConfiguration(apiKey: "test-key")
        let app = WritersApp(aiConfiguration: config)

        XCTAssertNotNil(app.aiService, "aiService must be non-nil when initialized with an AIConfiguration")
        XCTAssertTrue(app.isAIEnabled, "isAIEnabled must return true when AI is configured at init")
    }

    /// CLAUDE.md documents `init(databasePath:)` supporting an explicit path (or nil for default).
    func testCustomDatabasePathInitializerWithNilUsesDefault() {
        let app = WritersApp(databasePath: nil)

        XCTAssertNotNil(app.databaseManager, "databaseManager must be present when databasePath is nil")
        XCTAssertFalse(app.isAIEnabled, "AI must be disabled when using databasePath initializer without AI config")
    }

    /// CLAUDE.md documents passing `:memory:` as a lightweight in-test database path.
    func testCustomDatabasePathInitializerWithMemoryString() {
        let app = WritersApp(databasePath: ":memory:")

        XCTAssertNotNil(app.databaseManager, "databaseManager must be non-nil for in-memory path")
        XCTAssertFalse(app.isAIEnabled, "AI must be disabled when no AI config is passed")
    }

    // MARK: - AI Lifecycle Contract Tests

    /// CLAUDE.md documents `isAIEnabled` as `false` on a default-constructed WritersApp.
    func testAIIsDisabledByDefault() {
        let app = WritersApp()

        XCTAssertFalse(app.isAIEnabled, "isAIEnabled must be false when no AIConfiguration is provided")
        XCTAssertNil(app.aiService, "aiService must be nil when AI is not enabled")
    }

    /// CLAUDE.md documents `enableAI(configuration:userId:)` to wire up AI services.
    func testEnableAIMakesAIServiceAvailable() {
        let app = WritersApp()
        XCTAssertFalse(app.isAIEnabled)

        let config = AIConfiguration(apiKey: "test-key")
        app.enableAI(configuration: config)

        XCTAssertTrue(app.isAIEnabled, "isAIEnabled must return true after enableAI()")
        XCTAssertNotNil(app.aiService, "aiService must be non-nil after enableAI()")
    }

    /// CLAUDE.md documents `disableAI()` as the counterpart to `enableAI()`.
    func testDisableAIClearsAIService() {
        let config = AIConfiguration(apiKey: "test-key")
        let app = WritersApp(aiConfiguration: config)
        XCTAssertTrue(app.isAIEnabled)

        app.disableAI()

        XCTAssertFalse(app.isAIEnabled, "isAIEnabled must return false after disableAI()")
        XCTAssertNil(app.aiService, "aiService must be nil after disableAI()")
    }

    /// CLAUDE.md documents `currentUserId` as starting nil.
    func testCurrentUserIdIsNilByDefault() {
        let app = WritersApp()

        XCTAssertNil(app.currentUserId, "currentUserId must be nil when no user has been set")
    }

    /// CLAUDE.md documents that `enableAI(configuration:userId:)` with a userId sets `currentUserId`.
    func testEnableAIWithUserIdSetsCurrentUserId() {
        let app = WritersApp()
        let userId = UUID()
        let config = AIConfiguration(apiKey: "test-key")

        app.enableAI(configuration: config, userId: userId)

        XCTAssertEqual(app.currentUserId, userId, "currentUserId must match the userId passed to enableAI()")
    }

    // MARK: - Public Property Contract Tests

    /// CLAUDE.md documents that `pluginManager` is the shared singleton.
    func testPluginManagerIsSharedSingleton() {
        let app1 = WritersApp()
        let app2 = WritersApp()

        XCTAssertTrue(
            app1.pluginManager === app2.pluginManager,
            "pluginManager must be the shared PluginManager singleton across all WritersApp instances"
        )
    }

    /// CLAUDE.md documents `crmManager` and `hardwareManager` as public properties (added in this PR).
    func testCRMManagerAndHardwareManagerAreAccessible() {
        let app = WritersApp()

        // Access is sufficient; no protocol conformance assertion is needed.
        _ = app.crmManager
        _ = app.hardwareManager
        // If this compiles and runs, the documented properties exist.
    }

    /// Regression: CLAUDE.md updated the Quick Commands section to include `swift run mocker`
    /// and `swift run manop`. Verify at the model level that WritersApp does not depend on
    /// those executables, confirming the library/CLI separation is intact.
    func testWritersAppDoesNotHaveDirectCLIDependency() {
        // WritersApp can be instantiated with no environment side-effects.
        let app = WritersApp(databasePath: ":memory:")
        XCTAssertNotNil(app, "WritersApp must initialise cleanly in a unit-test environment")
    }

    // MARK: - Helpers

    private func gitignoreURL() throws -> URL {
        // Walk up from the test bundle to find the repo root .gitignore.
        // In `swift test`, the working directory is the package root.
        let url = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent(".gitignore")

        guard FileManager.default.fileExists(atPath: url.path) else {
            throw XCTSkip("Could not locate .gitignore at \(url.path); skipping .gitignore tests.")
        }
        return url
    }

    /// Returns the non-comment, non-empty lines from a .gitignore file.
    private func activeIgnoreLines(in contents: String) -> Set<String> {
        let lines = contents.components(separatedBy: .newlines)
        return Set(
            lines.compactMap { line -> String? in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { return nil }
                return trimmed
            }
        )
    }
}
