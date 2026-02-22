#!/bin/bash
# Supplementary validation script for .claude/settings.json
# This provides basic validation that can run without Swift/XCTest
# For comprehensive testing, run: swift test --filter ClaudeSettingsTests

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SETTINGS_FILE="$PROJECT_ROOT/.claude/settings.json"

TESTS_PASSED=0
TESTS_FAILED=0

# Test helper functions
pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((TESTS_PASSED++))
}

fail() {
    echo -e "${RED}✗${NC} $1"
    ((TESTS_FAILED++))
}

warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

test_header() {
    echo ""
    echo "=== $1 ==="
}

# Test 1: Settings file exists
test_file_exists() {
    test_header "File Existence"
    if [ -f "$SETTINGS_FILE" ]; then
        pass "Settings file exists at $SETTINGS_FILE"
    else
        fail "Settings file not found at $SETTINGS_FILE"
        return 1
    fi
}

# Test 2: Settings file is not empty
test_file_not_empty() {
    if [ -s "$SETTINGS_FILE" ]; then
        pass "Settings file is not empty"
    else
        fail "Settings file is empty"
    fi
}

# Test 3: Settings file is valid JSON
test_valid_json() {
    test_header "JSON Validation"
    if command -v jq &>/dev/null; then
        if jq empty "$SETTINGS_FILE" 2>/dev/null; then
            pass "Settings file contains valid JSON"
        else
            fail "Settings file contains invalid JSON"
            jq . "$SETTINGS_FILE" 2>&1 | head -5
        fi
    elif command -v python3 &>/dev/null; then
        if python3 -c "import json; json.load(open('$SETTINGS_FILE'))" 2>/dev/null; then
            pass "Settings file contains valid JSON (validated with Python)"
        else
            fail "Settings file contains invalid JSON"
            python3 -c "import json; json.load(open('$SETTINGS_FILE'))" 2>&1
        fi
    else
        warn "No JSON validator found (jq or python3), skipping JSON validation"
    fi
}

# Test 4: Settings has required structure
test_structure() {
    test_header "Structure Validation"

    if command -v jq &>/dev/null; then
        # Check for 'hooks' property
        if jq -e '.hooks' "$SETTINGS_FILE" >/dev/null 2>&1; then
            pass "Settings contains 'hooks' property"
        else
            fail "Settings missing 'hooks' property"
        fi

        # Check for SessionStart
        if jq -e '.hooks.SessionStart' "$SETTINGS_FILE" >/dev/null 2>&1; then
            pass "hooks contains 'SessionStart' event"
        else
            fail "hooks missing 'SessionStart' event"
        fi

        # Check SessionStart is array
        if jq -e '.hooks.SessionStart | type == "array"' "$SETTINGS_FILE" | grep -q true; then
            pass "SessionStart is an array"
        else
            fail "SessionStart should be an array"
        fi

        # Check SessionStart has entries
        local count=$(jq '.hooks.SessionStart | length' "$SETTINGS_FILE")
        if [ "$count" -gt 0 ]; then
            pass "SessionStart has $count hook entry/entries"
        else
            fail "SessionStart has no hook entries"
        fi

    elif command -v python3 &>/dev/null; then
        python3 << 'EOF'
import json, sys

try:
    with open(sys.argv[1]) as f:
        data = json.load(f)

    # Check hooks
    if 'hooks' not in data:
        print("FAIL: Missing 'hooks' property")
        sys.exit(1)
    print("PASS: Settings contains 'hooks' property")

    # Check SessionStart
    if 'SessionStart' not in data['hooks']:
        print("FAIL: Missing 'SessionStart' event")
        sys.exit(1)
    print("PASS: hooks contains 'SessionStart' event")

    # Check SessionStart is array
    if not isinstance(data['hooks']['SessionStart'], list):
        print("FAIL: SessionStart should be an array")
        sys.exit(1)
    print("PASS: SessionStart is an array")

    # Check SessionStart has entries
    count = len(data['hooks']['SessionStart'])
    if count > 0:
        print(f"PASS: SessionStart has {count} hook entry/entries")
    else:
        print("FAIL: SessionStart has no hook entries")
        sys.exit(1)

except Exception as e:
    print(f"ERROR: {e}")
    sys.exit(1)
EOF
        if [ $? -eq 0 ]; then
            ((TESTS_PASSED += 4))
        else
            ((TESTS_FAILED += 1))
        fi
    else
        warn "No JSON parser found, skipping structure validation"
    fi
}

# Test 5: Hook commands reference valid files
test_hook_files() {
    test_header "Hook File Validation"

    if command -v jq &>/dev/null; then
        local commands=$(jq -r '.hooks.SessionStart[].hooks[].command // empty' "$SETTINGS_FILE")

        if [ -z "$commands" ]; then
            fail "No hook commands found"
            return
        fi

        while IFS= read -r cmd; do
            # Replace $CLAUDE_PROJECT_DIR with actual path
            local resolved_cmd="${cmd/\$CLAUDE_PROJECT_DIR/$PROJECT_ROOT}"

            # Extract script path (first token)
            local script_path=$(echo "$resolved_cmd" | awk '{print $1}')

            if [ -f "$script_path" ]; then
                pass "Hook script exists: $script_path"

                # Check if executable
                if [ -x "$script_path" ]; then
                    pass "Hook script is executable: $script_path"
                else
                    warn "Hook script exists but is not executable: $script_path"
                fi
            else
                fail "Hook script not found: $script_path"
            fi
        done <<< "$commands"

    elif command -v python3 &>/dev/null; then
        python3 << 'EOF'
import json, sys, os

project_root = sys.argv[2]

try:
    with open(sys.argv[1]) as f:
        data = json.load(f)

    commands = []
    for entry in data['hooks']['SessionStart']:
        for hook in entry.get('hooks', []):
            if 'command' in hook:
                commands.append(hook['command'])

    if not commands:
        print("FAIL: No hook commands found")
        sys.exit(1)

    all_ok = True
    for cmd in commands:
        resolved = cmd.replace('$CLAUDE_PROJECT_DIR', project_root)
        script_path = resolved.split()[0]

        if os.path.isfile(script_path):
            print(f"PASS: Hook script exists: {script_path}")
            if os.access(script_path, os.X_OK):
                print(f"PASS: Hook script is executable: {script_path}")
            else:
                print(f"WARN: Hook script not executable: {script_path}")
        else:
            print(f"FAIL: Hook script not found: {script_path}")
            all_ok = False

    sys.exit(0 if all_ok else 1)

except Exception as e:
    print(f"ERROR: {e}")
    sys.exit(1)
EOF
        if [ $? -eq 0 ]; then
            ((TESTS_PASSED += 2))
        else
            ((TESTS_FAILED += 1))
        fi
    else
        warn "No JSON parser found, skipping hook file validation"
    fi
}

# Test 6: No trailing whitespace
test_formatting() {
    test_header "Format Validation"

    if grep -q '[[:space:]]$' "$SETTINGS_FILE"; then
        fail "Settings file has lines with trailing whitespace"
    else
        pass "Settings file has no trailing whitespace"
    fi

    # Check file ends with newline
    if [ -n "$(tail -c 1 "$SETTINGS_FILE")" ]; then
        fail "Settings file should end with newline"
    else
        pass "Settings file ends with newline"
    fi
}

# Run all tests
main() {
    echo "Claude Settings Validation Script"
    echo "=================================="
    echo "Project Root: $PROJECT_ROOT"
    echo "Settings File: $SETTINGS_FILE"

    test_file_exists || exit 1
    test_file_not_empty
    test_valid_json
    test_structure
    test_hook_files
    test_formatting

    echo ""
    echo "=================================="
    echo "Results: $TESTS_PASSED passed, $TESTS_FAILED failed"
    echo "=================================="

    if [ $TESTS_FAILED -gt 0 ]; then
        echo -e "${RED}FAILED${NC}"
        exit 1
    else
        echo -e "${GREEN}ALL TESTS PASSED${NC}"
        echo ""
        echo "Note: For comprehensive testing with full coverage,"
        echo "run: swift test --filter ClaudeSettingsTests"
        exit 0
    fi
}

main "$@"