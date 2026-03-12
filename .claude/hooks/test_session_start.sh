#!/bin/bash
#
# Test suite for session-start.sh
#
# This test suite validates the session-start hook behavior using a
# combination of unit tests (testing individual functions in isolation)
# and integration tests (testing the full script behavior).
#
# Usage:
#   bash test_session_start.sh
#

# Note: Intentionally NOT using 'set -e' to allow test suite to continue on failures

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test result tracking
declare -a FAILED_TESTS

# Helper functions
print_test_header() {
    echo ""
    echo "========================================="
    echo "$1"
    echo "========================================="
}

print_test_name() {
    echo -n "  $1 ... "
}

pass() {
    echo -e "${GREEN}PASS${NC}"
    ((TESTS_PASSED++))
    ((TESTS_RUN++))
}

fail() {
    echo -e "${RED}FAIL${NC}"
    if [ -n "${1:-}" ]; then
        echo "    Error: $1"
    fi
    ((TESTS_FAILED++))
    ((TESTS_RUN++))
    FAILED_TESTS+=("$CURRENT_TEST")
}

skip() {
    echo -e "${YELLOW}SKIP${NC} - $1"
    ((TESTS_RUN++))
}

# Set up test environment
setup_test_env() {
    export TEST_MODE=1
    export TEST_TMPDIR=$(mktemp -d)
    export PATH="$TEST_TMPDIR/bin:$PATH"
}

# Clean up test environment
teardown_test_env() {
    if [ -n "${TEST_TMPDIR:-}" ] && [ -d "$TEST_TMPDIR" ]; then
        rm -rf "$TEST_TMPDIR"
    fi
}

# Create mock commands for testing
create_mock_command() {
    local cmd=$1
    local exit_code=${2:-0}
    local output=${3:-""}

    mkdir -p "$TEST_TMPDIR/bin"
    cat > "$TEST_TMPDIR/bin/$cmd" <<EOF
#!/bin/bash
echo "$output"
exit $exit_code
EOF
    chmod +x "$TEST_TMPDIR/bin/$cmd"
}

# ============================================================================
# Unit Tests - Test individual script behaviors
# ============================================================================

test_script_exists() {
    CURRENT_TEST="Script exists and is readable"
    print_test_name "$CURRENT_TEST"

    if [ -f ".claude/hooks/session-start.sh" ] && [ -r ".claude/hooks/session-start.sh" ]; then
        pass
    else
        fail "session-start.sh not found or not readable"
    fi
}

test_script_is_executable() {
    CURRENT_TEST="Script has executable permissions"
    print_test_name "$CURRENT_TEST"

    if [ -x ".claude/hooks/session-start.sh" ]; then
        pass
    else
        fail "session-start.sh is not executable"
    fi
}

test_script_has_shebang() {
    CURRENT_TEST="Script has correct shebang"
    print_test_name "$CURRENT_TEST"

    local first_line=$(head -n1 .claude/hooks/session-start.sh)
    if [[ "$first_line" == "#!/bin/bash"* ]]; then
        pass
    else
        fail "Expected #!/bin/bash, got: $first_line"
    fi
}

test_script_uses_strict_mode() {
    CURRENT_TEST="Script uses strict mode (set -euo pipefail)"
    print_test_name "$CURRENT_TEST"

    if grep -q "set -euo pipefail" .claude/hooks/session-start.sh; then
        pass
    else
        fail "Script should use 'set -euo pipefail'"
    fi
}

test_script_checks_remote_mode() {
    CURRENT_TEST="Script checks CLAUDE_CODE_REMOTE variable"
    print_test_name "$CURRENT_TEST"

    if grep -q "CLAUDE_CODE_REMOTE" .claude/hooks/session-start.sh; then
        pass
    else
        fail "Script should check CLAUDE_CODE_REMOTE environment variable"
    fi
}

test_script_exits_on_non_remote() {
    CURRENT_TEST="Script exits early when not in remote mode"
    print_test_name "$CURRENT_TEST"

    # Test by running script without CLAUDE_CODE_REMOTE set
    # Should exit with code 0 without doing anything
    local exit_code=0

    # Run in subshell with minimal environment
    env -i HOME="$HOME" PATH="$PATH" bash .claude/hooks/session-start.sh >/dev/null 2>&1 || exit_code=$?

    if [ $exit_code -eq 0 ]; then
        pass
    else
        fail "Script should exit with code 0 when CLAUDE_CODE_REMOTE is not set (got: $exit_code)"
    fi
}

test_script_installs_system_dependencies() {
    CURRENT_TEST="Script checks for system dependencies (libsqlite3-dev, pkg-config)"
    print_test_name "$CURRENT_TEST"

    if grep -q "libsqlite3-dev" .claude/hooks/session-start.sh && \
       grep -q "pkg-config" .claude/hooks/session-start.sh; then
        pass
    else
        fail "Script should check for libsqlite3-dev and pkg-config"
    fi
}

test_script_installs_swift() {
    CURRENT_TEST="Script installs Swift if not present"
    print_test_name "$CURRENT_TEST"

    if grep -q "swift" .claude/hooks/session-start.sh && \
       grep -q "swiftly" .claude/hooks/session-start.sh; then
        pass
    else
        fail "Script should install Swift using swiftly"
    fi
}

test_script_builds_project() {
    CURRENT_TEST="Script runs swift build"
    print_test_name "$CURRENT_TEST"

    if grep -q "swift build" .claude/hooks/session-start.sh; then
        pass
    else
        fail "Script should run 'swift build'"
    fi
}

test_script_installs_plugins() {
    CURRENT_TEST="Script installs Claude plugins"
    print_test_name "$CURRENT_TEST"

    if grep -q "claude plugin install" .claude/hooks/session-start.sh; then
        pass
    else
        fail "Script should install Claude plugins"
    fi
}

test_script_handles_plugin_errors() {
    CURRENT_TEST="Script continues on plugin install errors (|| true)"
    print_test_name "$CURRENT_TEST"

    if grep -q "claude plugin install.*|| true" .claude/hooks/session-start.sh; then
        pass
    else
        fail "Script should use '|| true' to handle plugin install errors gracefully"
    fi
}

test_script_persists_swift_env() {
    CURRENT_TEST="Script persists Swift environment to CLAUDE_ENV_FILE"
    print_test_name "$CURRENT_TEST"

    if grep -q "CLAUDE_ENV_FILE" .claude/hooks/session-start.sh; then
        pass
    else
        fail "Script should persist environment to CLAUDE_ENV_FILE"
    fi
}

test_script_uses_quiet_apt_get() {
    CURRENT_TEST="Script uses quiet flags for apt-get (-qq)"
    print_test_name "$CURRENT_TEST"

    if grep -q "apt-get.*-qq" .claude/hooks/session-start.sh; then
        pass
    else
        fail "Script should use -qq flag for quiet apt-get output"
    fi
}

test_script_checks_dpkg_before_install() {
    CURRENT_TEST="Script checks if packages are already installed (dpkg -s)"
    print_test_name "$CURRENT_TEST"

    if grep -q "dpkg -s" .claude/hooks/session-start.sh; then
        pass
    else
        fail "Script should check if packages are already installed"
    fi
}

test_script_downloads_swiftly() {
    CURRENT_TEST="Script downloads swiftly from official source"
    print_test_name "$CURRENT_TEST"

    if grep -q "download.swift.org/swiftly" .claude/hooks/session-start.sh; then
        pass
    else
        fail "Script should download swiftly from download.swift.org"
    fi
}

test_script_handles_architecture() {
    CURRENT_TEST="Script detects system architecture (uname -m)"
    print_test_name "$CURRENT_TEST"

    if grep -q "uname -m" .claude/hooks/session-start.sh; then
        pass
    else
        fail "Script should detect system architecture"
    fi
}

test_script_redirects_output() {
    CURRENT_TEST="Script redirects command output (2>&1)"
    print_test_name "$CURRENT_TEST"

    if grep -q "2>&1" .claude/hooks/session-start.sh; then
        pass
    else
        fail "Script should redirect stderr to stdout for better logging"
    fi
}

# ============================================================================
# Edge Case Tests
# ============================================================================

test_script_syntax_valid() {
    CURRENT_TEST="Script has valid bash syntax"
    print_test_name "$CURRENT_TEST"

    if bash -n .claude/hooks/session-start.sh 2>/dev/null; then
        pass
    else
        fail "Script has syntax errors"
    fi
}

test_script_no_hardcoded_paths() {
    CURRENT_TEST="Script uses environment variables for paths"
    print_test_name "$CURRENT_TEST"

    # Should use $CLAUDE_PROJECT_DIR instead of hardcoded paths
    if grep -q "CLAUDE_PROJECT_DIR" .claude/hooks/session-start.sh; then
        pass
    else
        fail "Script should use CLAUDE_PROJECT_DIR environment variable"
    fi
}

test_script_sources_swiftly_env() {
    CURRENT_TEST="Script sources swiftly environment (env.sh)"
    print_test_name "$CURRENT_TEST"

    if grep -q "env.sh" .claude/hooks/session-start.sh; then
        pass
    else
        fail "Script should source swiftly's env.sh"
    fi
}

test_script_updates_hash_table() {
    CURRENT_TEST="Script updates bash hash table after PATH changes (hash -r)"
    print_test_name "$CURRENT_TEST"

    if grep -q "hash -r" .claude/hooks/session-start.sh; then
        pass
    else
        fail "Script should run 'hash -r' after modifying PATH"
    fi
}

# ============================================================================
# Integration Tests - Test specific plugin installations
# ============================================================================

test_installs_context7_plugin() {
    CURRENT_TEST="Script installs context7 plugin"
    print_test_name "$CURRENT_TEST"

    if grep -q "context7@claude-plugins-official" .claude/hooks/session-start.sh; then
        pass
    else
        fail "Script should install context7 plugin"
    fi
}

test_installs_frontend_design_plugin() {
    CURRENT_TEST="Script installs frontend-design plugin"
    print_test_name "$CURRENT_TEST"

    if grep -q "frontend-design@claude-plugins-official" .claude/hooks/session-start.sh; then
        pass
    else
        fail "Script should install frontend-design plugin"
    fi
}

test_installs_code_review_plugin() {
    CURRENT_TEST="Script installs code-review plugin"
    print_test_name "$CURRENT_TEST"

    if grep -q "code-review@claude-plugins-official" .claude/hooks/session-start.sh; then
        pass
    else
        fail "Script should install code-review plugin"
    fi
}

test_installs_superpowers_plugin() {
    CURRENT_TEST="Script installs superpowers plugin"
    print_test_name "$CURRENT_TEST"

    if grep -q "superpowers@claude-plugins-official" .claude/hooks/session-start.sh; then
        pass
    else
        fail "Script should install superpowers plugin"
    fi
}

test_installs_github_plugin() {
    CURRENT_TEST="Script installs github plugin"
    print_test_name "$CURRENT_TEST"

    if grep -q "github@claude-plugins-official" .claude/hooks/session-start.sh; then
        pass
    else
        fail "Script should install github plugin"
    fi
}

test_installs_feature_dev_plugin() {
    CURRENT_TEST="Script installs feature-dev plugin"
    print_test_name "$CURRENT_TEST"

    if grep -q "feature-dev@claude-plugins-official" .claude/hooks/session-start.sh; then
        pass
    else
        fail "Script should install feature-dev plugin"
    fi
}

test_installs_code_simplifier_plugin() {
    CURRENT_TEST="Script installs code-simplifier plugin"
    print_test_name "$CURRENT_TEST"

    if grep -q "code-simplifier@claude-plugins-official" .claude/hooks/session-start.sh; then
        pass
    else
        fail "Script should install code-simplifier plugin"
    fi
}

test_installs_ralph_loop_plugin() {
    CURRENT_TEST="Script installs ralph-loop plugin"
    print_test_name "$CURRENT_TEST"

    if grep -q "ralph-loop@claude-plugins-official" .claude/hooks/session-start.sh; then
        pass
    else
        fail "Script should install ralph-loop plugin"
    fi
}

test_installs_typescript_lsp_plugin() {
    CURRENT_TEST="Script installs typescript-lsp plugin"
    print_test_name "$CURRENT_TEST"

    if grep -q "typescript-lsp@claude-plugins-official" .claude/hooks/session-start.sh; then
        pass
    else
        fail "Script should install typescript-lsp plugin"
    fi
}

# ============================================================================
# Security Tests
# ============================================================================

test_no_hardcoded_credentials() {
    CURRENT_TEST="Script contains no hardcoded credentials"
    print_test_name "$CURRENT_TEST"

    # Check for common patterns of credentials
    if grep -iE "(password|api[_-]?key|secret|token)[[:space:]]*=[[:space:]]*['\"][^'\"]+['\"]" .claude/hooks/session-start.sh 2>/dev/null; then
        fail "Script appears to contain hardcoded credentials"
    else
        pass
    fi
}

test_uses_fsslo_for_curl() {
    CURRENT_TEST="Script uses secure curl options (-fsSLO)"
    print_test_name "$CURRENT_TEST"

    # Check that curl commands use appropriate flags
    if grep -q "curl.*-fsSLO" .claude/hooks/session-start.sh || \
       ! grep -q "curl" .claude/hooks/session-start.sh; then
        pass
    else
        fail "curl should use -fsSLO flags for security and error handling"
    fi
}

test_no_eval_usage() {
    CURRENT_TEST="Script avoids using eval"
    print_test_name "$CURRENT_TEST"

    # eval can be dangerous with untrusted input
    if grep -q "eval" .claude/hooks/session-start.sh; then
        fail "Script should avoid using 'eval' for security"
    else
        pass
    fi
}

# ============================================================================
# Main test runner
# ============================================================================

main() {
    local start_dir=$(pwd)

    # Change to git root directory
    if [ -d ".git" ]; then
        cd "$(git rev-parse --show-toplevel)"
    fi

    echo "Session-Start Hook Test Suite"
    echo "=============================="
    echo ""

    # Setup
    setup_test_env
    trap teardown_test_env EXIT

    # Run unit tests
    print_test_header "Unit Tests - Script Structure"
    test_script_exists
    test_script_is_executable
    test_script_has_shebang
    test_script_syntax_valid
    test_script_uses_strict_mode

    print_test_header "Unit Tests - Environment Checks"
    test_script_checks_remote_mode
    test_script_exits_on_non_remote
    test_script_no_hardcoded_paths
    test_script_persists_swift_env

    print_test_header "Unit Tests - Dependency Management"
    test_script_installs_system_dependencies
    test_script_checks_dpkg_before_install
    test_script_uses_quiet_apt_get
    test_script_installs_swift
    test_script_downloads_swiftly
    test_script_handles_architecture
    test_script_sources_swiftly_env
    test_script_updates_hash_table

    print_test_header "Unit Tests - Build and Plugin Installation"
    test_script_builds_project
    test_script_installs_plugins
    test_script_handles_plugin_errors
    test_script_redirects_output

    print_test_header "Integration Tests - Plugin Installations"
    test_installs_context7_plugin
    test_installs_frontend_design_plugin
    test_installs_code_review_plugin
    test_installs_superpowers_plugin
    test_installs_github_plugin
    test_installs_feature_dev_plugin
    test_installs_code_simplifier_plugin
    test_installs_ralph_loop_plugin
    test_installs_typescript_lsp_plugin

    print_test_header "Security Tests"
    test_no_hardcoded_credentials
    test_uses_fsslo_for_curl
    test_no_eval_usage

    # Summary
    echo ""
    echo "========================================="
    echo "Test Summary"
    echo "========================================="
    echo "Total tests run: $TESTS_RUN"
    echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"

    if [ $TESTS_FAILED -gt 0 ]; then
        echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
        echo ""
        echo "Failed tests:"
        for test in "${FAILED_TESTS[@]}"; do
            echo -e "  ${RED}✗${NC} $test"
        done
        echo ""
        exit 1
    else
        echo -e "Tests failed: ${GREEN}0${NC}"
        echo ""
        echo -e "${GREEN}All tests passed!${NC}"
        exit 0
    fi
}

# Run tests if executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi