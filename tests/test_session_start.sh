#!/bin/bash
# Test suite for .claude/hooks/session-start.sh
# Uses a simple assertion-based testing framework

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK_SCRIPT="${SCRIPT_DIR}/../.claude/hooks/session-start.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# assert_equals compares two strings and, if they differ, echoes a colored "FAIL" line with the optional message and prints the expected and actual values.
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-}"

    if [[ "$expected" == "$actual" ]]; then
        return 0
    else
        echo -e "${RED}FAIL${NC}: $message"
        echo "  Expected: $expected"
        echo "  Actual:   $actual"
        return 1
    fi
}

# assert_contains checks whether the first argument (haystack) contains the second argument (needle); on failure it prints a FAIL message showing the expected needle and the haystack and returns non-zero.
assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-}"

    if [[ "$haystack" == *"$needle"* ]]; then
        return 0
    else
        echo -e "${RED}FAIL${NC}: $message"
        echo "  Expected to find: $needle"
        echo "  In: $haystack"
        return 1
    fi
}

# assert_command_exists verifies that the given command is available in PATH and returns 0 if found, 1 otherwise.
assert_command_exists() {
    local cmd="$1"
    if command -v "$cmd" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# run_test runs a test function by name, updates TESTS_RUN/TESTS_PASSED/TESTS_FAILED, and prints a "Running" message followed by PASS or FAIL.
run_test() {
    local test_name="$1"
    TESTS_RUN=$((TESTS_RUN + 1))

    echo -n "Running: $test_name ... "

    if "$test_name"; then
        echo -e "${GREEN}PASS${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}FAIL${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# test_script_exists checks that the hook script file referenced by HOOK_SCRIPT exists.
test_script_exists() {
    [[ -f "$HOOK_SCRIPT" ]]
}

# test_script_executable verifies that the target hook script file is executable.
test_script_executable() {
    [[ -x "$HOOK_SCRIPT" ]]
}

# test_script_shebang verifies the target hook script's first line is `#!/bin/bash`.
test_script_shebang() {
    local first_line
    first_line=$(head -n1 "$HOOK_SCRIPT")
    assert_equals "#!/bin/bash" "$first_line" "Script should have bash shebang"
}

# test_script_strict_mode checks that the target hook script enables strict shell options with `set -euo pipefail`.
test_script_strict_mode() {
    local content
    content=$(cat "$HOOK_SCRIPT")
    assert_contains "$content" "set -euo pipefail" "Script should use strict mode"
}

# test_checks_remote_variable verifies the target hook script contains a reference to CLAUDE_CODE_REMOTE.
test_checks_remote_variable() {
    local content
    content=$(cat "$HOOK_SCRIPT")
    assert_contains "$content" "CLAUDE_CODE_REMOTE" "Script should check CLAUDE_CODE_REMOTE"
}

# test_exits_early_if_not_remote verifies the hook script checks CLAUDE_CODE_REMOTE and exits early when its value is not "true".
test_exits_early_if_not_remote() {
    local content
    content=$(cat "$HOOK_SCRIPT")
    assert_contains "$content" 'if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]' "Script should check if remote"
    assert_contains "$content" "exit 0" "Script should exit early if not remote"
}

# test_checks_libsqlite3_dev verifies the hook script checks for the libsqlite3-dev package.
test_checks_libsqlite3_dev() {
    local content
    content=$(cat "$HOOK_SCRIPT")
    assert_contains "$content" "libsqlite3-dev" "Script should check for libsqlite3-dev"
}

# test_checks_pkg_config verifies that the hook script checks for the presence of `pkg-config`.
test_checks_pkg_config() {
    local content
    content=$(cat "$HOOK_SCRIPT")
    assert_contains "$content" "pkg-config" "Script should check for pkg-config"
}

# test_uses_dpkg_check verifies the hook script checks for installed packages using dpkg -s.
test_uses_dpkg_check() {
    local content
    content=$(cat "$HOOK_SCRIPT")
    assert_contains "$content" "dpkg -s" "Script should use dpkg -s to check packages"
}

# test_installs_with_apt_get verifies the hook script contains both `apt-get update` and `apt-get install` commands.
test_installs_with_apt_get() {
    local content
    content=$(cat "$HOOK_SCRIPT")
    assert_contains "$content" "apt-get update" "Script should run apt-get update"
    assert_contains "$content" "apt-get install" "Script should run apt-get install"
}

# test_checks_swift_command verifies that the hook script checks for the presence of the `swift` command.
test_checks_swift_command() {
    local content
    content=$(cat "$HOOK_SCRIPT")
    assert_contains "$content" "command -v swift" "Script should check for swift command"
}

# test_installs_swift_via_swiftly verifies that the hook script installs Swift using swiftly.
test_installs_swift_via_swiftly() {
    local content
    content=$(cat "$HOOK_SCRIPT")
    assert_contains "$content" "swiftly" "Script should install Swift via swiftly"
}

# test_downloads_swiftly verifies that the hook script downloads the swiftly tarball using curl with -fsSLO and references "swiftly-".
test_downloads_swiftly() {
    local content
    content=$(cat "$HOOK_SCRIPT")
    assert_contains "$content" "curl -fsSLO" "Script should download swiftly"
    assert_contains "$content" "swiftly-" "Script should download swiftly tarball"
}

# test_detects_architecture verifies the hook script detects the system architecture (uses `uname -m`) and stores it in the `ARCH` variable.
test_detects_architecture() {
    local content
    content=$(cat "$HOOK_SCRIPT")
    assert_contains "$content" "uname -m" "Script should detect architecture"
    assert_contains "$content" "ARCH=" "Script should store architecture"
}

# test_extracts_swiftly verifies that the target hook script extracts the swiftly tarball using `tar zxf`.
test_extracts_swiftly() {
    local content
    content=$(cat "$HOOK_SCRIPT")
    assert_contains "$content" "tar zxf" "Script should extract swiftly tarball"
}

# test_initializes_swiftly Verifies the hook script calls `swiftly init` to initialize swiftly.
test_initializes_swiftly() {
    local content
    content=$(cat "$HOOK_SCRIPT")
    assert_contains "$content" "swiftly init" "Script should initialize swiftly"
}

# test_sources_swiftly_env verifies the target script references SWIFTLY_HOME_DIR and sources env.sh.
test_sources_swiftly_env() {
    local content
    content=$(cat "$HOOK_SCRIPT")
    assert_contains "$content" "SWIFTLY_HOME_DIR" "Script should reference SWIFTLY_HOME_DIR"
    assert_contains "$content" "env.sh" "Script should source env.sh"
}

# test_persists_path verifies the hook script references CLAUDE_ENV_FILE to persist PATH entries.
test_persists_path() {
    local content
    content=$(cat "$HOOK_SCRIPT")
    assert_contains "$content" "CLAUDE_ENV_FILE" "Script should check CLAUDE_ENV_FILE"
}

# test_cleans_up_downloads verifies that the hook script removes downloaded files by checking for an `rm -f` command.
test_cleans_up_downloads() {
    local content
    content=$(cat "$HOOK_SCRIPT")
    assert_contains "$content" "rm -f" "Script should clean up downloaded files"
}

# test_builds_project verifies the hook script invokes `swift build` to build the project.
test_builds_project() {
    local content
    content=$(cat "$HOOK_SCRIPT")
    assert_contains "$content" "swift build" "Script should build the project"
}

# test_changes_to_project_dir checks that the hook script references CLAUDE_PROJECT_DIR and changes to that directory.
test_changes_to_project_dir() {
    local content
    content=$(cat "$HOOK_SCRIPT")
    assert_contains "$content" "CLAUDE_PROJECT_DIR" "Script should use CLAUDE_PROJECT_DIR"
    assert_contains "$content" 'cd "$CLAUDE_PROJECT_DIR"' "Script should change to project directory"
}

# test_installs_claude_plugins verifies the hook script contains one or more `claude plugin install` commands.
test_installs_claude_plugins() {
    local content
    content=$(cat "$HOOK_SCRIPT")
    assert_contains "$content" "claude plugin install" "Script should install Claude plugins"
}

# test_installs_specific_plugins verifies the hook script contains installation commands for a predefined set of Claude plugins.
test_installs_specific_plugins() {
    local content
    content=$(cat "$HOOK_SCRIPT")

    # Check for each expected plugin
    local plugins=(
        "context7"
        "frontend-design"
        "code-review"
        "superpowers"
        "github"
        "feature-dev"
        "code-simplifier"
        "ralph-loop"
        "typescript-lsp"
    )

    for plugin in "${plugins[@]}"; do
        if ! assert_contains "$content" "$plugin" "Script should install $plugin plugin"; then
            return 1
        fi
    done

    return 0
}

# test_plugin_installs_ignore_failures verifies that plugin install commands include "|| true" so failures are ignored.
test_plugin_installs_ignore_failures() {
    local content
    content=$(cat "$HOOK_SCRIPT")

    # Count lines with "claude plugin install" and "|| true"
    local plugin_lines
    plugin_lines=$(grep -c "claude plugin install.*|| true" "$HOOK_SCRIPT" || true)

    if [[ "$plugin_lines" -gt 0 ]]; then
        return 0
    else
        echo "Plugin install commands should use '|| true' to ignore failures"
        return 1
    fi
}

# test_redirects_output verifies the hook script redirects stderr to stdout (checks for "2>&1") to suppress noisy output.
test_redirects_output() {
    local content
    content=$(cat "$HOOK_SCRIPT")
    assert_contains "$content" "2>&1" "Script should redirect stderr for some commands"
}

# test_apt_get_quiet_flags verifies apt-get commands include the quiet flag `-qq` and the auto-yes flag `-y`.
test_apt_get_quiet_flags() {
    local content
    content=$(cat "$HOOK_SCRIPT")
    assert_contains "$content" "-qq" "apt-get should use -qq flag for quiet output"
    assert_contains "$content" "-y" "apt-get should use -y flag for auto-yes"
}

# test_uses_tmp_directory checks that the hook script changes to /tmp for downloads.
test_uses_tmp_directory() {
    local content
    content=$(cat "$HOOK_SCRIPT")
    assert_contains "$content" "cd /tmp" "Script should use /tmp for downloads"
}

# test_handles_missing_env_vars verifies the hook script uses parameter expansion with defaults (the ':-' operator).
test_handles_missing_env_vars() {
    local content
    content=$(cat "$HOOK_SCRIPT")

    # Should use parameter expansion with defaults
    assert_contains "$content" ":-" "Script should use parameter expansion for defaults"
}

# test_has_comments checks that the hook script contains more than five comment lines explaining sections.
test_has_comments() {
    local content
    content=$(cat "$HOOK_SCRIPT")

    # Should have at least one comment
    local comment_count
    comment_count=$(grep -c "^#" "$HOOK_SCRIPT" || true)

    if [[ "$comment_count" -gt 5 ]]; then
        return 0
    else
        echo "Script should have comments explaining sections"
        return 1
    fi
}

# test_logical_structure verifies that the CLAUDE_CODE_REMOTE check appears in the hook script before any `dpkg -s` package checks.
test_logical_structure() {
    local content
    content=$(cat "$HOOK_SCRIPT")

    # Remote check should come before dpkg check
    local remote_line
    local dpkg_line
    remote_line=$(grep -n "CLAUDE_CODE_REMOTE" "$HOOK_SCRIPT" | head -1 | cut -d: -f1)
    dpkg_line=$(grep -n "dpkg -s" "$HOOK_SCRIPT" | head -1 | cut -d: -f1)

    if [[ "$remote_line" -lt "$dpkg_line" ]]; then
        return 0
    else
        echo "Remote check should come before package checks"
        return 1
    fi
}

# test_swift_before_build verifies the hook script checks for or installs Swift before running `swift build`; it succeeds if the first occurrence of `command -v swift` appears on an earlier line than the first `swift build`, otherwise it prints an error and fails.
test_swift_before_build() {
    local content
    content=$(cat "$HOOK_SCRIPT")

    local swift_check_line
    local build_line
    swift_check_line=$(grep -n "command -v swift" "$HOOK_SCRIPT" | head -1 | cut -d: -f1)
    build_line=$(grep -n "swift build" "$HOOK_SCRIPT" | head -1 | cut -d: -f1)

    if [[ "$swift_check_line" -lt "$build_line" ]]; then
        return 0
    else
        echo "Swift installation should come before swift build"
        return 1
    fi
}

# test_hash_refresh verifies the script calls hash -r after installing Swift.
test_hash_refresh() {
    local content
    content=$(cat "$HOOK_SCRIPT")
    assert_contains "$content" "hash -r" "Script should call hash -r after installing Swift"
}

# test_swiftly_quiet_init verifies that `swiftly init` is invoked with the `--quiet-shell-followup` flag and the `-y` confirmation flag.
test_swiftly_quiet_init() {
    local content
    content=$(cat "$HOOK_SCRIPT")
    assert_contains "$content" "--quiet-shell-followup" "swiftly init should use quiet flag"
    assert_contains "$content" "-y" "swiftly init should use -y flag"
}

# test_does_not_install_firecrawl verifies that the hook script does NOT install Firecrawl CLI (regression test for PR removal).
test_does_not_install_firecrawl() {
    local content
    content=$(cat "$HOOK_SCRIPT")

    # Should NOT contain firecrawl installation
    if grep -q "firecrawl" "$HOOK_SCRIPT"; then
        echo "Script should not install Firecrawl CLI (was removed in PR)"
        return 1
    fi

    # Should NOT contain npm install -g firecrawl-cli
    if grep -q "npm install -g firecrawl-cli" "$HOOK_SCRIPT"; then
        echo "Script should not install firecrawl-cli via npm"
        return 1
    fi

    return 0
}

# test_does_not_check_firecrawl_command verifies that the script no longer checks for the firecrawl command.
test_does_not_check_firecrawl_command() {
    local content
    content=$(cat "$HOOK_SCRIPT")

    # Should NOT check for firecrawl command
    if grep -q "command -v firecrawl" "$HOOK_SCRIPT"; then
        echo "Script should not check for firecrawl command (was removed in PR)"
        return 1
    fi

    return 0
}

# Run all tests
echo "=========================================="
echo "Testing session-start.sh"
echo "=========================================="
echo

run_test test_script_exists
run_test test_script_executable
run_test test_script_shebang
run_test test_script_strict_mode
run_test test_checks_remote_variable
run_test test_exits_early_if_not_remote
run_test test_checks_libsqlite3_dev
run_test test_checks_pkg_config
run_test test_uses_dpkg_check
run_test test_installs_with_apt_get
run_test test_checks_swift_command
run_test test_installs_swift_via_swiftly
run_test test_downloads_swiftly
run_test test_detects_architecture
run_test test_extracts_swiftly
run_test test_initializes_swiftly
run_test test_sources_swiftly_env
run_test test_persists_path
run_test test_cleans_up_downloads
run_test test_builds_project
run_test test_changes_to_project_dir
run_test test_installs_claude_plugins
run_test test_installs_specific_plugins
run_test test_plugin_installs_ignore_failures
run_test test_redirects_output
run_test test_apt_get_quiet_flags
run_test test_uses_tmp_directory
run_test test_handles_missing_env_vars
run_test test_has_comments
run_test test_logical_structure
run_test test_swift_before_build
run_test test_hash_refresh
run_test test_swiftly_quiet_init
run_test test_does_not_install_firecrawl
run_test test_does_not_check_firecrawl_command

# Summary
echo
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo -e "Total tests run:    $TESTS_RUN"
echo -e "Tests passed:       ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests failed:       ${RED}$TESTS_FAILED${NC}"
echo

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed.${NC}"
    exit 1
fi