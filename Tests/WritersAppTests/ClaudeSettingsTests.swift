import XCTest
import Foundation

/// Tests for validating .claude/settings.json configuration
final class ClaudeSettingsTests: XCTestCase {

    var testDirectory: URL!
    var settingsFileURL: URL!

    override func setUp() {
        super.setUp()
        // Create temporary directory for test files
        testDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("ClaudeSettingsTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: testDirectory, withIntermediateDirectories: true)
        settingsFileURL = testDirectory.appendingPathComponent("settings.json")
    }

    override func tearDown() {
        // Clean up test files
        try? FileManager.default.removeItem(at: testDirectory)
        super.tearDown()
    }

    // MARK: - Test Models

    struct ClaudeSettings: Codable {
        let hooks: Hooks
    }

    struct Hooks: Codable {
        let SessionStart: [HookGroup]
    }

    struct HookGroup: Codable {
        let hooks: [Hook]
    }

    struct Hook: Codable {
        let type: String
        let command: String
    }

    // MARK: - Valid Configuration Tests

    func testValidSettingsCanBeParsed() throws {
        // Test that a valid settings.json can be parsed correctly
        let validSettings = """
        {
          "hooks": {
            "SessionStart": [
              {
                "hooks": [
                  {
                    "type": "command",
                    "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/session-start.sh"
                  }
                ]
              }
            ]
          }
        }
        """

        let data = validSettings.data(using: .utf8)!
        let decoder = JSONDecoder()

        let settings = try decoder.decode(ClaudeSettings.self, from: data)

        XCTAssertEqual(settings.hooks.SessionStart.count, 1)
        XCTAssertEqual(settings.hooks.SessionStart[0].hooks.count, 1)
        XCTAssertEqual(settings.hooks.SessionStart[0].hooks[0].type, "command")
        XCTAssertEqual(settings.hooks.SessionStart[0].hooks[0].command, "$CLAUDE_PROJECT_DIR/.claude/hooks/session-start.sh")
    }

    func testActualSettingsFileCanBeParsed() throws {
        // Test that the actual .claude/settings.json file in the project is valid
        let projectRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let actualSettingsURL = projectRoot.appendingPathComponent(".claude/settings.json")

        // Skip if file doesn't exist (for CI environments)
        guard FileManager.default.fileExists(atPath: actualSettingsURL.path) else {
            throw XCTSkip("Actual settings.json file not found in expected location")
        }

        let data = try Data(contentsOf: actualSettingsURL)
        let decoder = JSONDecoder()
        let settings = try decoder.decode(ClaudeSettings.self, from: data)

        // Verify basic structure
        XCTAssertGreaterThan(settings.hooks.SessionStart.count, 0, "SessionStart should have at least one hook group")

        // Verify all hooks have required fields
        for hookGroup in settings.hooks.SessionStart {
            XCTAssertGreaterThan(hookGroup.hooks.count, 0, "Hook group should have at least one hook")
            for hook in hookGroup.hooks {
                XCTAssertFalse(hook.type.isEmpty, "Hook type should not be empty")
                XCTAssertFalse(hook.command.isEmpty, "Hook command should not be empty")
            }
        }
    }

    func testSettingsWithMultipleHooks() throws {
        // Test configuration with multiple hooks in a single group
        let settings = """
        {
          "hooks": {
            "SessionStart": [
              {
                "hooks": [
                  {
                    "type": "command",
                    "command": "echo 'First hook'"
                  },
                  {
                    "type": "command",
                    "command": "echo 'Second hook'"
                  }
                ]
              }
            ]
          }
        }
        """

        let data = settings.data(using: .utf8)!
        let decoder = JSONDecoder()
        let parsed = try decoder.decode(ClaudeSettings.self, from: data)

        XCTAssertEqual(parsed.hooks.SessionStart[0].hooks.count, 2)
        XCTAssertEqual(parsed.hooks.SessionStart[0].hooks[0].command, "echo 'First hook'")
        XCTAssertEqual(parsed.hooks.SessionStart[0].hooks[1].command, "echo 'Second hook'")
    }

    func testSettingsWithMultipleHookGroups() throws {
        // Test configuration with multiple hook groups
        let settings = """
        {
          "hooks": {
            "SessionStart": [
              {
                "hooks": [
                  {
                    "type": "command",
                    "command": "setup.sh"
                  }
                ]
              },
              {
                "hooks": [
                  {
                    "type": "command",
                    "command": "init.sh"
                  }
                ]
              }
            ]
          }
        }
        """

        let data = settings.data(using: .utf8)!
        let decoder = JSONDecoder()
        let parsed = try decoder.decode(ClaudeSettings.self, from: data)

        XCTAssertEqual(parsed.hooks.SessionStart.count, 2)
        XCTAssertEqual(parsed.hooks.SessionStart[0].hooks[0].command, "setup.sh")
        XCTAssertEqual(parsed.hooks.SessionStart[1].hooks[0].command, "init.sh")
    }

    func testSettingsRoundTripEncoding() throws {
        // Test that settings can be encoded and decoded without data loss
        let hook = Hook(type: "command", command: "/path/to/script.sh")
        let hookGroup = HookGroup(hooks: [hook])
        let hooks = Hooks(SessionStart: [hookGroup])
        let settings = ClaudeSettings(hooks: hooks)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let encoded = try encoder.encode(settings)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ClaudeSettings.self, from: encoded)

        XCTAssertEqual(decoded.hooks.SessionStart.count, 1)
        XCTAssertEqual(decoded.hooks.SessionStart[0].hooks[0].type, "command")
        XCTAssertEqual(decoded.hooks.SessionStart[0].hooks[0].command, "/path/to/script.sh")
    }

    // MARK: - Invalid Configuration Tests

    func testMalformedJSONThrowsError() {
        // Test that malformed JSON is properly rejected
        let malformedJSON = """
        {
          "hooks": {
            "SessionStart": [
              {
                "hooks": [
                  {
                    "type": "command",
                    "command": "test.sh"
        """

        let data = malformedJSON.data(using: .utf8)!
        let decoder = JSONDecoder()

        XCTAssertThrowsError(try decoder.decode(ClaudeSettings.self, from: data)) { error in
            XCTAssertTrue(error is DecodingError, "Should throw DecodingError for malformed JSON")
        }
    }

    func testMissingHooksFieldThrowsError() {
        // Test that missing required 'hooks' field is detected
        let invalidSettings = """
        {
          "other_field": "value"
        }
        """

        let data = invalidSettings.data(using: .utf8)!
        let decoder = JSONDecoder()

        XCTAssertThrowsError(try decoder.decode(ClaudeSettings.self, from: data)) { error in
            guard case DecodingError.keyNotFound(let key, _) = error else {
                XCTFail("Expected keyNotFound error")
                return
            }
            XCTAssertEqual(key.stringValue, "hooks")
        }
    }

    func testMissingSessionStartFieldThrowsError() {
        // Test that missing SessionStart field is detected
        let invalidSettings = """
        {
          "hooks": {
          }
        }
        """

        let data = invalidSettings.data(using: .utf8)!
        let decoder = JSONDecoder()

        XCTAssertThrowsError(try decoder.decode(ClaudeSettings.self, from: data)) { error in
            guard case DecodingError.keyNotFound(let key, _) = error else {
                XCTFail("Expected keyNotFound error")
                return
            }
            XCTAssertEqual(key.stringValue, "SessionStart")
        }
    }

    func testMissingHookTypeThrowsError() {
        // Test that missing 'type' field in hook is detected
        let invalidSettings = """
        {
          "hooks": {
            "SessionStart": [
              {
                "hooks": [
                  {
                    "command": "test.sh"
                  }
                ]
              }
            ]
          }
        }
        """

        let data = invalidSettings.data(using: .utf8)!
        let decoder = JSONDecoder()

        XCTAssertThrowsError(try decoder.decode(ClaudeSettings.self, from: data)) { error in
            guard case DecodingError.keyNotFound(let key, _) = error else {
                XCTFail("Expected keyNotFound error")
                return
            }
            XCTAssertEqual(key.stringValue, "type")
        }
    }

    func testMissingHookCommandThrowsError() {
        // Test that missing 'command' field in hook is detected
        let invalidSettings = """
        {
          "hooks": {
            "SessionStart": [
              {
                "hooks": [
                  {
                    "type": "command"
                  }
                ]
              }
            ]
          }
        }
        """

        let data = invalidSettings.data(using: .utf8)!
        let decoder = JSONDecoder()

        XCTAssertThrowsError(try decoder.decode(ClaudeSettings.self, from: data)) { error in
            guard case DecodingError.keyNotFound(let key, _) = error else {
                XCTFail("Expected keyNotFound error")
                return
            }
            XCTAssertEqual(key.stringValue, "command")
        }
    }

    func testEmptySessionStartArrayIsValid() throws {
        // Test that an empty SessionStart array is technically valid JSON
        let settings = """
        {
          "hooks": {
            "SessionStart": []
          }
        }
        """

        let data = settings.data(using: .utf8)!
        let decoder = JSONDecoder()
        let parsed = try decoder.decode(ClaudeSettings.self, from: data)

        XCTAssertEqual(parsed.hooks.SessionStart.count, 0)
    }

    func testWrongTypeForHooksFieldThrowsError() {
        // Test that wrong type for hooks field is rejected
        let invalidSettings = """
        {
          "hooks": "not an object"
        }
        """

        let data = invalidSettings.data(using: .utf8)!
        let decoder = JSONDecoder()

        XCTAssertThrowsError(try decoder.decode(ClaudeSettings.self, from: data)) { error in
            XCTAssertTrue(error is DecodingError, "Should throw DecodingError for type mismatch")
        }
    }

    // MARK: - Hook Reference Validation Tests

    func testSessionStartHookScriptExists() throws {
        // Test that the referenced session-start.sh script exists
        let projectRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let hookScriptURL = projectRoot.appendingPathComponent(".claude/hooks/session-start.sh")

        // This test verifies the actual project structure
        guard FileManager.default.fileExists(atPath: hookScriptURL.path) else {
            throw XCTSkip("Hook script not found in expected location")
        }

        // Verify the file is readable
        XCTAssertTrue(FileManager.default.isReadableFile(atPath: hookScriptURL.path))

        // Verify it's a file (not a directory)
        var isDirectory: ObjCBool = false
        FileManager.default.fileExists(atPath: hookScriptURL.path, isDirectory: &isDirectory)
        XCTAssertFalse(isDirectory.boolValue, "Hook script should be a file, not a directory")
    }

    func testHookScriptIsExecutable() throws {
        // Test that the hook script has executable permissions
        let projectRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let hookScriptURL = projectRoot.appendingPathComponent(".claude/hooks/session-start.sh")

        guard FileManager.default.fileExists(atPath: hookScriptURL.path) else {
            throw XCTSkip("Hook script not found in expected location")
        }

        // Check if file is executable
        XCTAssertTrue(FileManager.default.isExecutableFile(atPath: hookScriptURL.path),
                     "Hook script should be executable")
    }

    func testHookScriptHasValidShebang() throws {
        // Test that the hook script has a valid shebang line
        let projectRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let hookScriptURL = projectRoot.appendingPathComponent(".claude/hooks/session-start.sh")

        guard FileManager.default.fileExists(atPath: hookScriptURL.path) else {
            throw XCTSkip("Hook script not found in expected location")
        }

        let content = try String(contentsOf: hookScriptURL, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines)

        XCTAssertGreaterThan(lines.count, 0, "Script should not be empty")
        XCTAssertTrue(lines[0].hasPrefix("#!/"), "Script should start with shebang")
        XCTAssertTrue(lines[0].contains("bash") || lines[0].contains("sh"),
                     "Script should use bash or sh")
    }

    // MARK: - Edge Case Tests

    func testSettingsWithUnicodeInCommand() throws {
        // Test that Unicode characters in command strings are handled correctly
        let settings = """
        {
          "hooks": {
            "SessionStart": [
              {
                "hooks": [
                  {
                    "type": "command",
                    "command": "echo 'Hello 🌍 World'"
                  }
                ]
              }
            ]
          }
        }
        """

        let data = settings.data(using: .utf8)!
        let decoder = JSONDecoder()
        let parsed = try decoder.decode(ClaudeSettings.self, from: data)

        XCTAssertEqual(parsed.hooks.SessionStart[0].hooks[0].command, "echo 'Hello 🌍 World'")
    }

    func testSettingsWithEscapedCharacters() throws {
        // Test that escaped characters in JSON are handled correctly
        let settings = """
        {
          "hooks": {
            "SessionStart": [
              {
                "hooks": [
                  {
                    "type": "command",
                    "command": "echo \\"quoted\\" and \\n newline"
                  }
                ]
              }
            ]
          }
        }
        """

        let data = settings.data(using: .utf8)!
        let decoder = JSONDecoder()
        let parsed = try decoder.decode(ClaudeSettings.self, from: data)

        XCTAssertEqual(parsed.hooks.SessionStart[0].hooks[0].command, "echo \"quoted\" and \n newline")
    }

    func testSettingsWithVeryLongCommand() throws {
        // Test that very long command strings are handled correctly
        let longCommand = String(repeating: "a", count: 10000)
        let settings = """
        {
          "hooks": {
            "SessionStart": [
              {
                "hooks": [
                  {
                    "type": "command",
                    "command": "\(longCommand)"
                  }
                ]
              }
            ]
          }
        }
        """

        let data = settings.data(using: .utf8)!
        let decoder = JSONDecoder()
        let parsed = try decoder.decode(ClaudeSettings.self, from: data)

        XCTAssertEqual(parsed.hooks.SessionStart[0].hooks[0].command.count, 10000)
    }

    func testSettingsFileWriteAndRead() throws {
        // Test that settings can be written to a file and read back correctly
        let hook = Hook(type: "command", command: "$CLAUDE_PROJECT_DIR/.claude/hooks/session-start.sh")
        let hookGroup = HookGroup(hooks: [hook])
        let hooks = Hooks(SessionStart: [hookGroup])
        let settings = ClaudeSettings(hooks: hooks)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let encoded = try encoder.encode(settings)

        // Write to file
        try encoded.write(to: settingsFileURL)

        // Read back
        let readData = try Data(contentsOf: settingsFileURL)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ClaudeSettings.self, from: readData)

        XCTAssertEqual(decoded.hooks.SessionStart[0].hooks[0].type, "command")
        XCTAssertEqual(decoded.hooks.SessionStart[0].hooks[0].command, "$CLAUDE_PROJECT_DIR/.claude/hooks/session-start.sh")
    }

    func testDifferentHookTypes() throws {
        // Test that different hook types can be stored (future-proofing)
        let settings = """
        {
          "hooks": {
            "SessionStart": [
              {
                "hooks": [
                  {
                    "type": "command",
                    "command": "setup.sh"
                  },
                  {
                    "type": "script",
                    "command": "init.js"
                  }
                ]
              }
            ]
          }
        }
        """

        let data = settings.data(using: .utf8)!
        let decoder = JSONDecoder()
        let parsed = try decoder.decode(ClaudeSettings.self, from: data)

        XCTAssertEqual(parsed.hooks.SessionStart[0].hooks.count, 2)
        XCTAssertEqual(parsed.hooks.SessionStart[0].hooks[0].type, "command")
        XCTAssertEqual(parsed.hooks.SessionStart[0].hooks[1].type, "script")
    }
}