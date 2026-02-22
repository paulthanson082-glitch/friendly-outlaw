#!/usr/bin/env python3
"""
Comprehensive validation tests for .claude/settings.json
Supplementary to ClaudeSettingsTests.swift - provides validation in environments without Swift
"""

import json
import os
import sys
from pathlib import Path


class TestResult:
    def __init__(self):
        self.passed = 0
        self.failed = 0
        self.warnings = 0
        self.tests = []

    def add_pass(self, name, message=""):
        self.passed += 1
        self.tests.append(("PASS", name, message))
        print(f"✓ PASS: {name}")
        if message:
            print(f"  {message}")

    def add_fail(self, name, message=""):
        self.failed += 1
        self.tests.append(("FAIL", name, message))
        print(f"✗ FAIL: {name}")
        if message:
            print(f"  {message}")

    def add_warning(self, name, message=""):
        self.warnings += 1
        self.tests.append(("WARN", name, message))
        print(f"⚠ WARN: {name}")
        if message:
            print(f"  {message}")

    def summary(self):
        print("\n" + "=" * 60)
        print(f"Test Results: {self.passed} passed, {self.failed} failed, {self.warnings} warnings")
        print("=" * 60)
        return self.failed == 0


def find_project_root():
    """Find the project root directory"""
    script_path = Path(__file__).resolve()
    # Go up from Tests/WritersAppTests/ to project root
    return script_path.parent.parent.parent


def test_file_existence(settings_path, result):
    """Test that settings file exists and is readable"""
    print("\n=== File Existence Tests ===")

    if settings_path.exists():
        result.add_pass("Settings file exists", str(settings_path))
    else:
        result.add_fail("Settings file not found", str(settings_path))
        return False

    if settings_path.is_file():
        result.add_pass("Settings path is a file")
    else:
        result.add_fail("Settings path is not a file")
        return False

    if os.access(settings_path, os.R_OK):
        result.add_pass("Settings file is readable")
    else:
        result.add_fail("Settings file is not readable")
        return False

    if settings_path.stat().st_size > 0:
        result.add_pass("Settings file is not empty", f"{settings_path.stat().st_size} bytes")
    else:
        result.add_fail("Settings file is empty")
        return False

    return True


def test_json_validity(settings_path, result):
    """Test that settings file contains valid JSON"""
    print("\n=== JSON Validity Tests ===")

    try:
        with open(settings_path, 'r', encoding='utf-8') as f:
            content = f.read()

        if not content.strip():
            result.add_fail("Settings file is empty or contains only whitespace")
            return None

        data = json.loads(content)
        result.add_pass("Settings file contains valid JSON")

        return data

    except json.JSONDecodeError as e:
        result.add_fail("Invalid JSON syntax", str(e))
        return None
    except Exception as e:
        result.add_fail("Error reading settings file", str(e))
        return None


def test_json_structure(data, result):
    """Test the overall JSON structure"""
    print("\n=== JSON Structure Tests ===")

    if not isinstance(data, dict):
        result.add_fail("Settings root should be an object/dictionary")
        return False

    result.add_pass("Settings root is an object")

    # Check for required top-level 'hooks' property
    if 'hooks' not in data:
        result.add_fail("Settings missing required 'hooks' property")
        return False

    result.add_pass("Settings contains 'hooks' property")

    # Check hooks is an object
    if not isinstance(data['hooks'], dict):
        result.add_fail("'hooks' should be an object/dictionary")
        return False

    result.add_pass("'hooks' is an object")

    return True


def test_hooks_configuration(data, result):
    """Test hooks configuration structure"""
    print("\n=== Hooks Configuration Tests ===")

    hooks = data.get('hooks', {})

    # Check for SessionStart
    if 'SessionStart' not in hooks:
        result.add_fail("hooks missing 'SessionStart' event")
        return False

    result.add_pass("hooks contains 'SessionStart' event")

    # Check SessionStart is an array
    session_start = hooks['SessionStart']
    if not isinstance(session_start, list):
        result.add_fail("SessionStart should be an array")
        return False

    result.add_pass("SessionStart is an array")

    # Check SessionStart has entries
    if len(session_start) == 0:
        result.add_fail("SessionStart array is empty")
        return False

    result.add_pass(f"SessionStart has {len(session_start)} hook entry/entries")

    return True


def test_hook_entries(data, result):
    """Test individual hook entry structures"""
    print("\n=== Hook Entry Structure Tests ===")

    hooks = data.get('hooks', {})
    session_start = hooks.get('SessionStart', [])

    all_valid = True

    for i, entry in enumerate(session_start):
        if not isinstance(entry, dict):
            result.add_fail(f"SessionStart entry {i} should be an object", type(entry).__name__)
            all_valid = False
            continue

        # Check for 'hooks' property in entry
        if 'hooks' not in entry:
            result.add_fail(f"SessionStart entry {i} missing 'hooks' property")
            all_valid = False
            continue

        inner_hooks = entry['hooks']
        if not isinstance(inner_hooks, list):
            result.add_fail(f"SessionStart entry {i} 'hooks' should be an array")
            all_valid = False
            continue

        if len(inner_hooks) == 0:
            result.add_warning(f"SessionStart entry {i} has empty hooks array")

        # Validate each hook in the entry
        for j, hook in enumerate(inner_hooks):
            if not isinstance(hook, dict):
                result.add_fail(f"SessionStart entry {i} hook {j} should be an object")
                all_valid = False
                continue

            # Check required hook properties
            if 'type' not in hook:
                result.add_fail(f"SessionStart entry {i} hook {j} missing 'type' property")
                all_valid = False

            if 'command' not in hook:
                result.add_fail(f"SessionStart entry {i} hook {j} missing 'command' property")
                all_valid = False

            # Validate type value
            if 'type' in hook:
                hook_type = hook['type']
                if hook_type != 'command':
                    result.add_warning(
                        f"SessionStart entry {i} hook {j} has unexpected type",
                        f"Expected 'command', got '{hook_type}'"
                    )

            # Validate command value
            if 'command' in hook:
                command = hook['command']
                if not isinstance(command, str):
                    result.add_fail(f"SessionStart entry {i} hook {j} command should be a string")
                    all_valid = False
                elif not command.strip():
                    result.add_fail(f"SessionStart entry {i} hook {j} command is empty")
                    all_valid = False

    if all_valid:
        result.add_pass("All hook entries have valid structure")

    return all_valid


def test_hook_files(data, project_root, result):
    """Test that hook script files exist and are executable"""
    print("\n=== Hook File Tests ===")

    hooks = data.get('hooks', {})
    session_start = hooks.get('SessionStart', [])

    all_valid = True

    for entry in session_start:
        inner_hooks = entry.get('hooks', [])

        for hook in inner_hooks:
            command = hook.get('command', '')
            if not command:
                continue

            # Replace environment variable
            resolved_command = command.replace('$CLAUDE_PROJECT_DIR', str(project_root))

            # Extract script path (first token)
            script_path = resolved_command.split()[0]
            script_file = Path(script_path)

            if script_file.exists():
                result.add_pass(f"Hook script exists: {script_file.name}")

                # Check if executable
                if os.access(script_file, os.X_OK):
                    result.add_pass(f"Hook script is executable: {script_file.name}")
                else:
                    result.add_warning(f"Hook script not executable: {script_file.name}")
            else:
                result.add_fail(f"Hook script not found: {script_path}")
                all_valid = False

    return all_valid


def test_schema_validation(data, result):
    """Test schema constraints and validation rules"""
    print("\n=== Schema Validation Tests ===")

    # Check for unexpected top-level keys
    expected_keys = {'hooks'}
    actual_keys = set(data.keys())
    unexpected_keys = actual_keys - expected_keys

    if unexpected_keys:
        result.add_warning(
            "Settings has unexpected top-level keys",
            f"Unexpected: {', '.join(unexpected_keys)}"
        )
    else:
        result.add_pass("No unexpected top-level keys")

    # Check for supported hook event types
    hooks = data.get('hooks', {})
    supported_events = {'SessionStart', 'SessionEnd', 'ToolCall', 'UserPromptSubmit'}
    actual_events = set(hooks.keys())

    unsupported_events = actual_events - supported_events
    if unsupported_events:
        result.add_warning(
            "hooks contains unsupported event types",
            f"Unsupported: {', '.join(unsupported_events)}"
        )
    else:
        result.add_pass("All hook events are supported types")

    return True


def test_formatting(settings_path, result):
    """Test file formatting and style"""
    print("\n=== Formatting Tests ===")

    with open(settings_path, 'r', encoding='utf-8') as f:
        content = f.read()
        lines = content.splitlines(keepends=True)

    # Check for UTF-8 encoding
    result.add_pass("Settings file is UTF-8 encoded")

    # Check for proper indentation
    if '  ' in content:
        result.add_pass("Settings JSON uses indentation")
    else:
        result.add_warning("Settings JSON appears to be minified (no indentation)")

    # Check for trailing whitespace
    has_trailing = False
    for i, line in enumerate(lines):
        if line.rstrip('\r\n') != line.rstrip():
            has_trailing = True
            break

    if not has_trailing:
        result.add_pass("No lines with trailing whitespace")
    else:
        result.add_warning(f"Line {i + 1} has trailing whitespace")

    # Check file ends with newline
    if content and not content.endswith('\n'):
        result.add_warning("Settings file does not end with newline")
    else:
        result.add_pass("Settings file ends with newline")

    return True


def test_environment_variable_usage(data, result):
    """Test proper use of environment variables in hook commands"""
    print("\n=== Environment Variable Tests ===")

    hooks = data.get('hooks', {})
    session_start = hooks.get('SessionStart', [])

    found_env_var = False
    for entry in session_start:
        for hook in entry.get('hooks', []):
            command = hook.get('command', '')
            if '$CLAUDE_PROJECT_DIR' in command:
                found_env_var = True
                break

    if found_env_var:
        result.add_pass("Hook command uses $CLAUDE_PROJECT_DIR environment variable")
    else:
        result.add_warning("No hook commands use $CLAUDE_PROJECT_DIR environment variable")

    return True


def test_round_trip_serialization(data, result):
    """Test that configuration can be serialized and deserialized"""
    print("\n=== Serialization Tests ===")

    try:
        # Serialize back to JSON
        serialized = json.dumps(data, indent=2, sort_keys=True)
        result.add_pass("Settings can be serialized to JSON")

        # Deserialize again
        reparsed = json.loads(serialized)
        result.add_pass("Serialized settings can be deserialized")

        # Verify structure is preserved
        if reparsed.get('hooks') is not None:
            result.add_pass("Round-trip serialization preserves structure")
        else:
            result.add_fail("Round-trip serialization lost structure")

        return True

    except Exception as e:
        result.add_fail("Round-trip serialization failed", str(e))
        return False


def main():
    print("=" * 60)
    print("Claude Settings Validation Tests")
    print("Comprehensive validation for .claude/settings.json")
    print("=" * 60)

    result = TestResult()

    # Find project root and settings file
    project_root = find_project_root()
    settings_path = project_root / '.claude' / 'settings.json'

    print(f"\nProject Root: {project_root}")
    print(f"Settings File: {settings_path}")

    # Run test suites
    if not test_file_existence(settings_path, result):
        print("\nCannot continue without valid settings file")
        return result.summary()

    data = test_json_validity(settings_path, result)
    if data is None:
        print("\nCannot continue without valid JSON")
        return result.summary()

    test_json_structure(data, result)
    test_hooks_configuration(data, result)
    test_hook_entries(data, result)
    test_hook_files(data, project_root, result)
    test_schema_validation(data, result)
    test_formatting(settings_path, result)
    test_environment_variable_usage(data, result)
    test_round_trip_serialization(data, result)

    # Summary
    success = result.summary()

    if success:
        print("✓ ALL TESTS PASSED")
        print("\nNote: For comprehensive testing with Swift/XCTest:")
        print("  swift test --filter ClaudeSettingsTests")
    else:
        print("✗ SOME TESTS FAILED")

    return success


if __name__ == '__main__':
    success = main()
    sys.exit(0 if success else 1)