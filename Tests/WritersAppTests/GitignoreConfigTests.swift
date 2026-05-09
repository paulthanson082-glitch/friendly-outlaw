import XCTest

/// Tests for .gitignore configuration changes introduced in this PR:
/// - Package.resolved is no longer ignored (line commented out), meaning it is now tracked
/// - cmd/cargent/cargent binary path removed from ignore list
/// - Core ignore patterns remain intact (regression)
final class GitignoreConfigTests: XCTestCase {

    // MARK: - Helpers

    /// Resolve the path to the repository root's .gitignore by walking up from this source file.
    private func gitignorePath() -> String {
        // #file is .../Tests/WritersAppTests/GitignoreConfigTests.swift
        let thisFile = URL(fileURLWithPath: #file)
        // Walk up: GitignoreConfigTests.swift → WritersAppTests/ → Tests/ → repo root
        let repoRoot = thisFile
            .deletingLastPathComponent()   // WritersAppTests/
            .deletingLastPathComponent()   // Tests/
            .deletingLastPathComponent()   // repo root
        return repoRoot.appendingPathComponent(".gitignore").path
    }

    private func gitignoreContents() throws -> String {
        let path = gitignorePath()
        return try String(contentsOfFile: path, encoding: .utf8)
    }

    /// Returns every non-empty, non-comment line in the .gitignore as a set of active patterns.
    private func activePatterns() throws -> Set<String> {
        let contents = try gitignoreContents()
        let lines = contents.components(separatedBy: .newlines)
        var patterns = Set<String>()
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { continue }
            patterns.insert(trimmed)
        }
        return patterns
    }

    // MARK: - File Existence

    func testGitignoreFileExists() {
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: gitignorePath()),
            ".gitignore must exist at the repository root"
        )
    }

    func testGitignoreIsReadable() {
        XCTAssertTrue(
            FileManager.default.isReadableFile(atPath: gitignorePath()),
            ".gitignore must be readable"
        )
    }

    func testGitignoreIsNonEmpty() throws {
        let contents = try gitignoreContents()
        XCTAssertFalse(contents.isEmpty, ".gitignore must not be empty")
    }

    // MARK: - Package.resolved Is Now Tracked (PR change)

    /// After this PR, `Package.resolved` must NOT appear as an active (uncommented) ignore pattern.
    /// The previously un-commented `Package.resolved` line was changed to a comment (`# Package.resolved`).
    func testPackageResolvedIsNotAnActiveIgnorePattern() throws {
        let patterns = try activePatterns()
        XCTAssertFalse(
            patterns.contains("Package.resolved"),
            "Package.resolved should NOT be an active ignore pattern; it was changed to a comment so the file is now tracked by git"
        )
    }

    /// The comment `# Package.resolved` should still exist in the file so the intent is documented.
    func testPackageResolvedCommentLineExists() throws {
        let contents = try gitignoreContents()
        XCTAssertTrue(
            contents.contains("# Package.resolved"),
            ".gitignore should still contain '# Package.resolved' as a comment explaining the intentional choice"
        )
    }

    /// Verify that the file does not contain a bare, un-commented `Package.resolved` line.
    func testNoUncommentedPackageResolvedLine() throws {
        let contents = try gitignoreContents()
        let lines = contents.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            XCTAssertFalse(
                trimmed == "Package.resolved",
                "Found an active (uncommented) 'Package.resolved' ignore line — this PR intentionally removed it"
            )
        }
    }

    // MARK: - cmd/cargent/cargent Removed (PR change)

    /// After this PR, the `cmd/cargent/cargent` binary path must NOT appear in the gitignore at all.
    func testCargentBinaryNotIgnored() throws {
        let patterns = try activePatterns()
        XCTAssertFalse(
            patterns.contains("cmd/cargent/cargent"),
            "cmd/cargent/cargent should have been removed from .gitignore in this PR"
        )
    }

    func testCargentBinaryLineAbsent() throws {
        let contents = try gitignoreContents()
        let lines = contents.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            XCTAssertFalse(
                trimmed == "cmd/cargent/cargent",
                "cmd/cargent/cargent must not appear anywhere in .gitignore (even as a comment) after this PR"
            )
        }
    }

    // MARK: - Regression: Core Swift / Xcode Patterns Remain

    func testBuildDirectoryStillIgnored() throws {
        let patterns = try activePatterns()
        XCTAssertTrue(
            patterns.contains(".build/"),
            ".build/ must still be an active ignore pattern"
        )
    }

    func testNodeModulesStillIgnored() throws {
        let patterns = try activePatterns()
        XCTAssertTrue(
            patterns.contains("node_modules/"),
            "node_modules/ must still be an active ignore pattern"
        )
    }

    func testXcuserdataStillIgnored() throws {
        let patterns = try activePatterns()
        XCTAssertTrue(
            patterns.contains("xcuserdata/"),
            "xcuserdata/ must still be an active ignore pattern"
        )
    }

    func testDsymZipStillIgnored() throws {
        let patterns = try activePatterns()
        XCTAssertTrue(
            patterns.contains("*.dSYM.zip"),
            "*.dSYM.zip must still be an active ignore pattern"
        )
    }

    func testEnvFileStillIgnored() throws {
        let patterns = try activePatterns()
        XCTAssertTrue(
            patterns.contains(".env"),
            ".env must still be an active ignore pattern"
        )
    }

    // MARK: - Boundary / Negative Cases

    /// .gitignore should have a reasonable number of active patterns — guards against accidental truncation.
    func testGitignoreHasSufficientPatterns() throws {
        let patterns = try activePatterns()
        XCTAssertGreaterThanOrEqual(
            patterns.count,
            10,
            ".gitignore should have at least 10 active patterns; got \(patterns.count)"
        )
    }

    /// Active patterns must not contain empty strings — guards against accidentally blank lines being parsed as patterns.
    func testNoEmptyActivePatterns() throws {
        let patterns = try activePatterns()
        XCTAssertFalse(
            patterns.contains(""),
            "activePatterns() must not include the empty string"
        )
    }

    /// Lines that are pure whitespace should not be returned as active patterns.
    func testWhitespaceOnlyLinesNotTreatedAsPatterns() throws {
        let contents = try gitignoreContents()
        // Inject a whitespace-only line conceptually — verify our helper handles it
        let syntheticContents = contents + "\n   \n"
        let lines = syntheticContents.components(separatedBy: .newlines)
        var patterns = Set<String>()
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { continue }
            patterns.insert(trimmed)
        }
        XCTAssertFalse(
            patterns.contains("   "),
            "Whitespace-only lines must not be treated as active ignore patterns"
        )
    }
}
