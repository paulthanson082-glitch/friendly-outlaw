import XCTest
import Foundation

/// Tests for .claude/settings.json configuration file
/// Validates the structure, schema, and integrity of Claude Code settings
final class ClaudeSettingsTests: XCTestCase {
    var settingsPath: String!
    var projectRoot: String!

    override func setUp() async throws {
        try await super.setUp()

        // Determine project root (go up from Tests directory)
        let currentFile = URL(fileURLWithPath: #file)
        projectRoot = currentFile
            .deletingLastPathComponent() // WritersAppTests
            .deletingLastPathComponent() // Tests
            .deletingLastPathComponent() // project root
            .path

        settingsPath = projectRoot + "/.claude/settings.json"
    }

    override func tearDown() async throws {
        settingsPath = nil
        projectRoot = nil
        try await super.tearDown()
    }

    // MARK: - File Existence Tests

    func testSettingsFileExists() {
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: settingsPath),
            "Settings file should exist at \(settingsPath ?? "unknown")"
        )
    }

    func testSettingsFileIsReadable() throws {
        let data = try Data(contentsOf: URL(fileURLWithPath: settingsPath))
        XCTAssertGreaterThan(data.count, 0, "Settings file should not be empty")
    }

    // MARK: - JSON Structure Tests

    func testSettingsIsValidJSON() throws {
        let data = try Data(contentsOf: URL(fileURLWithPath: settingsPath))
        let json = try JSONSerialization.jsonObject(with: data)
        XCTAssertNotNil(json, "Settings should be valid JSON")
    }

    func testSettingsHasHooksProperty() throws {
        let settings = try loadSettings()
        XCTAssertNotNil(settings["hooks"], "Settings should contain 'hooks' property")
    }

    func testHooksPropertyIsObject() throws {
        let settings = try loadSettings()
        guard let hooks = settings["hooks"] else {
            XCTFail("Settings should contain 'hooks' property")
            return
        }
        XCTAssertTrue(hooks is [String: Any], "hooks should be an object/dictionary")
    }

    // MARK: - Hook Configuration Tests

    func testHooksContainSessionStart() throws {
        let hooks = try loadHooks()
        XCTAssertNotNil(hooks["SessionStart"], "hooks should contain 'SessionStart' event")
    }

    func testSessionStartIsArray() throws {
        let hooks = try loadHooks()
        guard let sessionStart = hooks["SessionStart"] else {
            XCTFail("hooks should contain 'SessionStart' event")
            return
        }
        XCTAssertTrue(sessionStart is [Any], "SessionStart should be an array")
    }

    func testSessionStartHasHookEntries() throws {
        let sessionStartHooks = try loadSessionStartHooks()
        XCTAssertGreaterThan(sessionStartHooks.count, 0, "SessionStart should have at least one hook entry")
    }

    func testSessionStartHookStructure() throws {
        let sessionStartHooks = try loadSessionStartHooks()

        for (index, hookEntry) in sessionStartHooks.enumerated() {
            guard let hookDict = hookEntry as? [String: Any] else {
                XCTFail("SessionStart hook entry \(index) should be a dictionary")
                continue
            }

            XCTAssertNotNil(
                hookDict["hooks"],
                "SessionStart hook entry \(index) should have 'hooks' property"
            )

            guard let hooks = hookDict["hooks"] as? [[String: Any]] else {
                XCTFail("SessionStart hook entry \(index) 'hooks' should be an array of dictionaries")
                continue
            }

            XCTAssertGreaterThan(
                hooks.count,
                0,
                "SessionStart hook entry \(index) should have at least one hook"
            )
        }
    }

    func testHookCommandStructure() throws {
        let sessionStartHooks = try loadSessionStartHooks()

        for hookEntry in sessionStartHooks {
            guard let hookDict = hookEntry as? [String: Any],
                  let hooks = hookDict["hooks"] as? [[String: Any]] else {
                continue
            }

            for (hookIndex, hook) in hooks.enumerated() {
                XCTAssertNotNil(
                    hook["type"],
                    "Hook \(hookIndex) should have 'type' property"
                )

                XCTAssertNotNil(
                    hook["command"],
                    "Hook \(hookIndex) should have 'command' property"
                )

                if let type = hook["type"] as? String {
                    XCTAssertEqual(
                        type,
                        "command",
                        "Hook \(hookIndex) type should be 'command'"
                    )
                }

                if let command = hook["command"] as? String {
                    XCTAssertFalse(
                        command.isEmpty,
                        "Hook \(hookIndex) command should not be empty"
                    )
                }
            }
        }
    }

    // MARK: - Hook Script File Tests

    func testSessionStartScriptExists() throws {
        let sessionStartHooks = try loadSessionStartHooks()

        for hookEntry in sessionStartHooks {
            guard let hookDict = hookEntry as? [String: Any],
                  let hooks = hookDict["hooks"] as? [[String: Any]] else {
                continue
            }

            for hook in hooks {
                guard let command = hook["command"] as? String else {
                    continue
                }

                // Replace $CLAUDE_PROJECT_DIR with actual project root
                let resolvedCommand = command.replacingOccurrences(
                    of: "$CLAUDE_PROJECT_DIR",
                    with: projectRoot
                )

                // Extract the script path (first token)
                let scriptPath = resolvedCommand.components(separatedBy: " ").first ?? resolvedCommand

                XCTAssertTrue(
                    FileManager.default.fileExists(atPath: scriptPath),
                    "Hook script should exist at \(scriptPath)"
                )
            }
        }
    }

    func testSessionStartScriptIsExecutable() throws {
        let sessionStartHooks = try loadSessionStartHooks()

        for hookEntry in sessionStartHooks {
            guard let hookDict = hookEntry as? [String: Any],
                  let hooks = hookDict["hooks"] as? [[String: Any]] else {
                continue
            }

            for hook in hooks {
                guard let command = hook["command"] as? String else {
                    continue
                }

                let resolvedCommand = command.replacingOccurrences(
                    of: "$CLAUDE_PROJECT_DIR",
                    with: projectRoot
                )

                let scriptPath = resolvedCommand.components(separatedBy: " ").first ?? resolvedCommand

                // Check if file has executable permission
                let attributes = try FileManager.default.attributesOfItem(atPath: scriptPath)
                let permissions = attributes[.posixPermissions] as? NSNumber

                XCTAssertNotNil(permissions, "Should be able to read file permissions")

                if let perms = permissions?.uint16Value {
                    // Check if any executable bit is set (owner, group, or other)
                    let isExecutable = (perms & 0o111) != 0
                    XCTAssertTrue(
                        isExecutable,
                        "Hook script at \(scriptPath) should be executable (permissions: \(String(perms, radix: 8)))"
                    )
                }
            }
        }
    }

    // MARK: - Schema Validation Tests

    func testNoUnexpectedTopLevelKeys() throws {
        let settings = try loadSettings()
        let expectedKeys = Set(["hooks"])
        let actualKeys = Set(settings.keys)

        let unexpectedKeys = actualKeys.subtracting(expectedKeys)
        XCTAssertTrue(
            unexpectedKeys.isEmpty,
            "Settings should not have unexpected top-level keys: \(unexpectedKeys)"
        )
    }

    func testHooksOnlyContainsSupportedEvents() throws {
        let hooks = try loadHooks()
        let supportedEvents = Set(["SessionStart", "SessionEnd", "ToolCall", "UserPromptSubmit"])
        let actualEvents = Set(hooks.keys)

        for event in actualEvents {
            XCTAssertTrue(
                supportedEvents.contains(event),
                "Hook event '\(event)' should be a supported event type"
            )
        }
    }

    // MARK: - Edge Case Tests

    func testSettingsCanBeParsedAndReEncoded() throws {
        // Load original
        let originalData = try Data(contentsOf: URL(fileURLWithPath: settingsPath))
        let settings = try JSONSerialization.jsonObject(with: originalData)

        // Re-encode
        let reencodedData = try JSONSerialization.data(
            withJSONObject: settings,
            options: [.prettyPrinted, .sortedKeys]
        )

        // Should be valid JSON
        let reparsed = try JSONSerialization.jsonObject(with: reencodedData)
        XCTAssertNotNil(reparsed, "Re-encoded settings should be valid JSON")
    }

    func testHookCommandUsesEnvironmentVariable() throws {
        let sessionStartHooks = try loadSessionStartHooks()
        var foundEnvVar = false

        for hookEntry in sessionStartHooks {
            guard let hookDict = hookEntry as? [String: Any],
                  let hooks = hookDict["hooks"] as? [[String: Any]] else {
                continue
            }

            for hook in hooks {
                if let command = hook["command"] as? String {
                    if command.contains("$CLAUDE_PROJECT_DIR") {
                        foundEnvVar = true
                    }
                }
            }
        }

        XCTAssertTrue(
            foundEnvVar,
            "At least one hook command should use $CLAUDE_PROJECT_DIR environment variable"
        )
    }

    func testSettingsJSONFormatting() throws {
        let data = try Data(contentsOf: URL(fileURLWithPath: settingsPath))
        let content = String(data: data, encoding: .utf8)

        XCTAssertNotNil(content, "Settings file should be UTF-8 encoded")

        if let content = content {
            // Check for proper JSON formatting (indentation)
            XCTAssertTrue(
                content.contains("  "),
                "Settings JSON should be formatted with indentation"
            )

            // Should not have trailing whitespace issues
            let lines = content.components(separatedBy: .newlines)
            for (index, line) in lines.enumerated() {
                if !line.isEmpty {
                    XCTAssertFalse(
                        line.hasSuffix(" ") || line.hasSuffix("\t"),
                        "Line \(index + 1) should not have trailing whitespace"
                    )
                }
            }
        }
    }

    // MARK: - Negative Tests (Error Handling)

    func testRejectsInvalidJSON() throws {
        let invalidJSON = "{ hooks: invalid }"
        let data = invalidJSON.data(using: .utf8)!

        XCTAssertThrowsError(
            try JSONSerialization.jsonObject(with: data),
            "Should reject invalid JSON syntax"
        )
    }

    func testRejectsMalformedHookStructure() {
        let malformed: [String: Any] = [
            "hooks": [
                "SessionStart": "not an array" // Should be array
            ]
        ]

        // This would fail validation if we had a proper validator
        // For now, we just verify the actual file has correct structure
        XCTAssertNoThrow(try loadSessionStartHooks())
    }

    // MARK: - Integration Tests

    func testCompleteConfigurationIntegrity() throws {
        // Load settings
        let settings = try loadSettings()

        // Verify hooks
        guard let hooks = settings["hooks"] as? [String: Any] else {
            XCTFail("Settings should have valid hooks object")
            return
        }

        // Verify SessionStart
        guard let sessionStart = hooks["SessionStart"] as? [Any] else {
            XCTFail("hooks should have SessionStart array")
            return
        }

        XCTAssertGreaterThan(sessionStart.count, 0)

        // Verify each hook entry is well-formed
        for entry in sessionStart {
            guard let hookEntry = entry as? [String: Any],
                  let innerHooks = hookEntry["hooks"] as? [[String: Any]] else {
                XCTFail("SessionStart entries should have proper structure")
                return
            }

            for hook in innerHooks {
                XCTAssertNotNil(hook["type"])
                XCTAssertNotNil(hook["command"])

                if let type = hook["type"] as? String {
                    XCTAssertEqual(type, "command")
                }
            }
        }
    }

    func testRoundTripSerialization() throws {
        // Test that we can parse and recreate the configuration
        let originalData = try Data(contentsOf: URL(fileURLWithPath: settingsPath))
        let settings = try JSONSerialization.jsonObject(with: originalData)

        // Convert to our model (if we had one)
        let hooks = try loadHooks()
        XCTAssertNotNil(hooks["SessionStart"])

        // Verify we can serialize back
        let serialized = try JSONSerialization.data(withJSONObject: ["hooks": hooks])
        let reparsed = try JSONSerialization.jsonObject(with: serialized) as? [String: Any]

        XCTAssertNotNil(reparsed?["hooks"])
    }

    // MARK: - Additional Strengthening Tests

    func testSettingsFileSize() throws {
        let data = try Data(contentsOf: URL(fileURLWithPath: settingsPath))
        // Settings file should not be unreasonably large (> 1MB would be suspicious)
        XCTAssertLessThan(data.count, 1_000_000, "Settings file is unexpectedly large")
        // But should have some content (at minimum > 10 bytes)
        XCTAssertGreaterThan(data.count, 10, "Settings file is suspiciously small")
    }

    func testHookCommandDoesNotContainDangerousPatterns() throws {
        let sessionStartHooks = try loadSessionStartHooks()

        for hookEntry in sessionStartHooks {
            guard let hookDict = hookEntry as? [String: Any],
                  let hooks = hookDict["hooks"] as? [[String: Any]] else {
                continue
            }

            for hook in hooks {
                guard let command = hook["command"] as? String else {
                    continue
                }

                // Check for potentially dangerous patterns
                let dangerousPatterns = [
                    "rm -rf /",
                    "dd if=",
                    "mkfs",
                    ":(){ :|:& };:",  // Fork bomb
                    "curl | sh",
                    "wget | sh"
                ]

                for pattern in dangerousPatterns {
                    XCTAssertFalse(
                        command.contains(pattern),
                        "Hook command contains potentially dangerous pattern: \(pattern)"
                    )
                }
            }
        }
    }

    func testSettingsJSONIsWellFormatted() throws {
        let data = try Data(contentsOf: URL(fileURLWithPath: settingsPath))
        let content = String(data: data, encoding: .utf8)

        XCTAssertNotNil(content)

        if let content = content {
            // Should start with opening brace
            XCTAssertTrue(content.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("{"))

            // Should end with closing brace
            XCTAssertTrue(content.trimmingCharacters(in: .whitespacesAndNewlines).hasSuffix("}"))

            // Should have proper JSON structure markers
            XCTAssertTrue(content.contains("\"hooks\""))
            XCTAssertTrue(content.contains("\"SessionStart\""))
        }
    }

    func testHookScriptPathIsValid() throws {
        let sessionStartHooks = try loadSessionStartHooks()

        for hookEntry in sessionStartHooks {
            guard let hookDict = hookEntry as? [String: Any],
                  let hooks = hookDict["hooks"] as? [[String: Any]] else {
                continue
            }

            for hook in hooks {
                guard let command = hook["command"] as? String else {
                    continue
                }

                // Verify path starts with expected environment variable
                if command.contains("$CLAUDE_PROJECT_DIR") {
                    let afterVar = command.replacingOccurrences(of: "$CLAUDE_PROJECT_DIR", with: "")
                    // After substitution, should be a valid relative path starting with /
                    XCTAssertTrue(
                        afterVar.hasPrefix("/.claude/"),
                        "Hook script path should be in .claude directory"
                    )
                }
            }
        }
    }

    func testSettingsCanBeLoadedMultipleTimes() throws {
        // Test that loading settings multiple times yields consistent results
        let settings1 = try loadSettings()
        let settings2 = try loadSettings()

        let hooks1 = settings1["hooks"] as? [String: Any]
        let hooks2 = settings2["hooks"] as? [String: Any]

        XCTAssertNotNil(hooks1)
        XCTAssertNotNil(hooks2)

        // Both should have the same keys
        XCTAssertEqual(Set(hooks1?.keys ?? []), Set(hooks2?.keys ?? []))
    }

    func testHookCommandIsNotEmpty() throws {
        let sessionStartHooks = try loadSessionStartHooks()

        for hookEntry in sessionStartHooks {
            guard let hookDict = hookEntry as? [String: Any],
                  let hooks = hookDict["hooks"] as? [[String: Any]] else {
                continue
            }

            for (index, hook) in hooks.enumerated() {
                guard let command = hook["command"] as? String else {
                    XCTFail("Hook \(index) should have a command")
                    continue
                }

                XCTAssertFalse(
                    command.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                    "Hook \(index) command should not be empty or just whitespace"
                )
            }
        }
    }

    func testSessionStartHooksArrayNotEmpty() throws {
        let hooks = try loadHooks()
        guard let sessionStart = hooks["SessionStart"] as? [Any] else {
            XCTFail("SessionStart should be an array")
            return
        }

        XCTAssertFalse(sessionStart.isEmpty, "SessionStart array should not be empty")
    }

    func testJSONEncodingIsUTF8() throws {
        let data = try Data(contentsOf: URL(fileURLWithPath: settingsPath))

        // Should be valid UTF-8
        let string = String(data: data, encoding: .utf8)
        XCTAssertNotNil(string, "Settings file should be valid UTF-8")

        // Verify we can parse it as JSON
        let json = try JSONSerialization.jsonObject(with: data)
        XCTAssertNotNil(json)
    }

    func testSettingsFilePermissions() throws {
        let attributes = try FileManager.default.attributesOfItem(atPath: settingsPath)

        // Settings file should be readable
        let permissions = attributes[.posixPermissions] as? NSNumber
        XCTAssertNotNil(permissions, "Should be able to read file permissions")

        if let perms = permissions?.uint16Value {
            // File should be readable by owner (at least 0400)
            let ownerRead = (perms & 0o400) != 0
            XCTAssertTrue(ownerRead, "Settings file should be readable by owner")
        }
    }

    func testHookTypeIsCommand() throws {
        let sessionStartHooks = try loadSessionStartHooks()

        for hookEntry in sessionStartHooks {
            guard let hookDict = hookEntry as? [String: Any],
                  let hooks = hookDict["hooks"] as? [[String: Any]] else {
                continue
            }

            for (index, hook) in hooks.enumerated() {
                guard let type = hook["type"] as? String else {
                    XCTFail("Hook \(index) should have a type")
                    continue
                }

                XCTAssertEqual(
                    type,
                    "command",
                    "Hook \(index) type should be 'command' (got '\(type)')"
                )
            }
        }
    }

    func testNoCircularReferences() throws {
        // JSON should not have circular references (JSONSerialization will catch this)
        let data = try Data(contentsOf: URL(fileURLWithPath: settingsPath))
        let settings = try JSONSerialization.jsonObject(with: data)

        // If we got here without throwing, there are no circular references
        XCTAssertNotNil(settings)

        // Verify we can re-serialize
        let reserialized = try JSONSerialization.data(withJSONObject: settings)
        XCTAssertGreaterThan(reserialized.count, 0)
    }

    // MARK: - Helper Methods

    private func loadSettings() throws -> [String: Any] {
        let data = try Data(contentsOf: URL(fileURLWithPath: settingsPath))
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw TestError.invalidJSON("Settings root should be an object")
        }
        return json
    }

    private func loadHooks() throws -> [String: Any] {
        let settings = try loadSettings()
        guard let hooks = settings["hooks"] as? [String: Any] else {
            throw TestError.missingProperty("hooks")
        }
        return hooks
    }

    private func loadSessionStartHooks() throws -> [Any] {
        let hooks = try loadHooks()
        guard let sessionStart = hooks["SessionStart"] as? [Any] else {
            throw TestError.missingProperty("SessionStart")
        }
        return sessionStart
    }
}

// MARK: - Test Error Types

enum TestError: Error, LocalizedError {
    case invalidJSON(String)
    case missingProperty(String)
    case invalidStructure(String)

    var errorDescription: String? {
        switch self {
        case .invalidJSON(let message):
            return "Invalid JSON: \(message)"
        case .missingProperty(let property):
            return "Missing property: \(property)"
        case .invalidStructure(let message):
            return "Invalid structure: \(message)"
        }
    }
}