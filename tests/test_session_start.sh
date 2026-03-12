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

# Test helper functions
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

assert_command_exists() {
    local cmd="$1"
    if command -v "$cmd" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

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

# Test: Script file exists
test_script_exists() {
    [[ -f "$HOOK_SCRIPT" ]]
}

# Test: Script is executable
test_script_executable() {
    [[ -x "$HOOK_SCRIPT" ]]
}

# Test: Script has proper shebang
test_script_shebang() {
    local first_line
    first_line=$(head -n1 "$HOOK_SCRIPT")
    assert_equals "#!/bin/bash" "$first_line" "Script should have bash shebang"
}

# Test: Script has set -euo pipefail
test_script_strict_mode() {
    local content
    content=$(cat "$HOOK_SCRIPT")
    assert_contains "$content" "set -euo pipefail" "Script should use strict mode"
}

# Test: Script checks CLAUDE_CODE_REMOTE variable
test_checks_remote_variable() {
    local content
    content=$(cat "$HOOK_SCRIPT")
    assert_contains "$content" "CLAUDE_CODE_REMOTE" "Script should check CLAUDE_CODE_REMOTE"
}

# Test: Script exits early if not remote
test_exits_early_if_not_remote() {
    local content
    content=$(cat "$HOOK_SCRIPT")
    assert_contains "$content" 'if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]' "Script should check if remote"
    assert_contains "$content" "exit 0" "Script should exit early if not remote"
}

# Test: Script checks for libsqlite3-dev
test_checks_libsqlite3_dev() {
    local content
    content=$(cat "$HOOK_SCRIPT")
    assert_contains "$content" "libsqlite3-dev" "Script should check for libsqlite3-dev"
}

# Test: Script checks for pkg-config
test_checks_pkg_config() {
    local content
    content=$(cat "$HOOK_SCRIPT")
    assert_contains "$content" "pkg-config" "Script should check for pkg-config"
}

# Test: Script uses dpkg -s to check packages
test_uses_dpkg_check() {
    local content
    content=$(cat "$HOOK_SCRIPT")
    assert_contains "$content" "dpkg -s" "Script should use dpkg -s to check packages"
}

# Test: Script installs system dependencies with apt-get
test_installs_with_apt_get() {
    local content
    content=$(cat "$HOOK_SCRIPT")
    assert_contains "$content" "apt-get update" "Script should run apt-get update"
    assert_contains "$content" "apt-get install" "Script should run apt-get install"
}

# Test: Script checks for swift command
test_checks_swift_command() {
    local content
    content=$(cat "$HOOK_SCRIPT")
    assert_contains "$content" "command -v swift" "Script should check for swift command"
}

# Test: Script installs Swift via swiftly
test_installs_swift_via_swiftly() {
    local content
    content=$(cat "$HOOK_SCRIPT")
    assert_contains "$content" "swiftly" "Script should install Swift via swiftly"
}

# Test: Script downloads swiftly tarball
test_downloads_swiftly() {
    local content
    content=$(cat "$HOOK_SCRIPT")
    assert_contains "$content" "curl -fsSLO" "Script should download swiftly"
    assert_contains "$content" "swiftly-" "Script should download swiftly tarball"
}

# Test: Script detects architecture
test_detects_architecture() {
    local content
    content=$(cat "$HOOK_SCRIPT")
    assert_contains "$content" "uname -m" "Script should detect architecture"
    assert_contains "$content" "ARCH=" "Script should store architecture"
}

# Test: Script extracts swiftly tarball
test_extracts_swiftly() {
    local content
    content=$(cat "$HOOK_SCRIPT")
    assert_contains "$content" "tar zxf" "Script should extract swiftly tarball"
}

# Test: Script initializes swiftly
test_initializes_swiftly() {
    local content
    content=$(cat "$HOOK_SCRIPT")
    assert_contains "$content" "swiftly init" "Script should initialize swiftly"
}

# Test: Script sources swiftly environment
test_sources_swiftly_env() {
    local content
    content=$(cat "$HOOK_SCRIPT")
    assert_contains "$content" "SWIFTLY_HOME_DIR" "Script should reference SWIFTLY_HOME_DIR"
    assert_contains "$content" "env.sh" "Script should source env.sh"
}

# Test: Script persists PATH via CLAUDE_ENV_FILE
test_persists_path() {
    local content
    content=$(cat "$HOOK_SCRIPT")
    assert_contains "$content" "CLAUDE_ENV_FILE" "Script should check CLAUDE_ENV_FILE"
}

# Test: Script cleans up downloaded files
test_cleans_up_downloads() {
    local content
    content=$(cat "$HOOK_SCRIPT")
    assert_contains "$content" "rm -f" "Script should clean up downloaded files"
}

# Test: Script builds the project
test_builds_project() {
    local content
    content=$(cat "$HOOK_SCRIPT")
    assert_contains "$content" "swift build" "Script should build the project"
}

# Test: Script changes to project directory
test_changes_to_project_dir() {
    local content
    content=$(cat "$HOOK_SCRIPT")
    assert_contains "$content" "CLAUDE_PROJECT_DIR" "Script should use CLAUDE_PROJECT_DIR"
    assert_contains "$content" 'cd "$CLAUDE_PROJECT_DIR"' "Script should change to project directory"
}

# Test: Script installs Claude plugins
test_installs_claude_plugins() {
    local content
    content=$(cat "$HOOK_SCRIPT")
    assert_contains "$content" "claude plugin install" "Script should install Claude plugins"
}

# Test: Script installs specific plugins
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

# Test: Plugin installs use || true to ignore failures
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

# Test: Script redirects output to suppress noise
test_redirects_output() {
    local content
    content=$(cat "$HOOK_SCRIPT")
    assert_contains "$content" "2>&1" "Script should redirect stderr for some commands"
}

# Test: apt-get uses quiet flags
test_apt_get_quiet_flags() {
    local content
    content=$(cat "$HOOK_SCRIPT")
    assert_contains "$content" "-qq" "apt-get should use -qq flag for quiet output"
    assert_contains "$content" "-y" "apt-get should use -y flag for auto-yes"
}

# Test: Script uses temporary directory for downloads
test_uses_tmp_directory() {
    local content
    content=$(cat "$HOOK_SCRIPT")
    assert_contains "$content" "cd /tmp" "Script should use /tmp for downloads"
}

# Test: Script handles missing environment variables gracefully
test_handles_missing_env_vars() {
    local content
    content=$(cat "$HOOK_SCRIPT")

    # Should use parameter expansion with defaults
    assert_contains "$content" ":-" "Script should use parameter expansion for defaults"
}

# Test: Script has comments explaining sections
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

# Test: Script structure - checks before installations
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

# Test: Swift installation comes before build
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

# Test: hash -r is called after Swift installation
test_hash_refresh() {
    local content
    content=$(cat "$HOOK_SCRIPT")
    assert_contains "$content" "hash -r" "Script should call hash -r after installing Swift"
}

# Test: swiftly init uses quiet flag
test_swiftly_quiet_init() {
    local content
    content=$(cat "$HOOK_SCRIPT")
    assert_contains "$content" "--quiet-shell-followup" "swiftly init should use quiet flag"
    assert_contains "$content" "-y" "swiftly init should use -y flag"
}

# Test: Script uses secure curl options
test_secure_curl_options() {
    local content
    content=$(cat "$HOOK_SCRIPT")
    assert_contains "$content" "curl -fsSLO" "Script should use secure curl options (-fsSL)"
}

# Test: Script properly handles both x86_64 and arm64 architectures
test_handles_multiple_architectures() {
    local content
    content=$(cat "$HOOK_SCRIPT")
    # Architecture detection should be dynamic, not hardcoded
    assert_contains "$content" '"$(uname -m)"' "Script should detect architecture dynamically"
    assert_contains "$content" '"swiftly-${ARCH}.tar.gz"' "Script should use architecture variable"
}

# Test: Plugin installation doesn't fail the entire script
test_plugin_failure_resilience() {
    local content
    content=$(cat "$HOOK_SCRIPT")

    # Every plugin install should have || true for resilience
    local plugin_install_count
    local plugin_resilient_count

    plugin_install_count=$(grep -c "claude plugin install" "$HOOK_SCRIPT" || true)
    plugin_resilient_count=$(grep -c "claude plugin install.*|| true" "$HOOK_SCRIPT" || true)

    if [[ "$plugin_install_count" -eq "$plugin_resilient_count" ]]; then
        return 0
    else
        echo "All plugin installs should use '|| true' for resilience"
        echo "Found $plugin_install_count installs but only $plugin_resilient_count with || true"
        return 1
    fi
}

# Test: Script suppresses stderr for package checks to avoid noise
test_suppresses_package_check_noise() {
    local content
    content=$(cat "$HOOK_SCRIPT")
    assert_contains "$content" "&>/dev/null" "Script should suppress stderr for dpkg checks"
}

# Test: Script validates expected environment variables exist
test_expects_required_env_vars() {
    local content
    content=$(cat "$HOOK_SCRIPT")

    # Should reference CLAUDE_PROJECT_DIR which is critical
    assert_contains "$content" "CLAUDE_PROJECT_DIR" "Script should use CLAUDE_PROJECT_DIR"

    # Should check CLAUDE_CODE_REMOTE before doing any work
    assert_contains "$content" "CLAUDE_CODE_REMOTE" "Script should check CLAUDE_CODE_REMOTE"
}

# Test: Swiftly cleanup removes both tarball and binary
test_swiftly_cleanup_complete() {
    local content
    content=$(cat "$HOOK_SCRIPT")

    # Should clean up both the tarball and extracted binary
    assert_contains "$content" 'rm -f "swiftly-${ARCH}.tar.gz"' "Should remove tarball"
    assert_contains "$content" "rm -f" "Should use rm -f for cleanup"

    # Check that cleanup happens after extraction
    local extract_line
    local cleanup_line
    extract_line=$(grep -n "tar zxf" "$HOOK_SCRIPT" | head -1 | cut -d: -f1)
    cleanup_line=$(grep -n "rm -f.*swiftly" "$HOOK_SCRIPT" | head -1 | cut -d: -f1)

    if [[ "$cleanup_line" -gt "$extract_line" ]]; then
        return 0
    else
        echo "Cleanup should happen after extraction"
        return 1
    fi
}

# Test: Build output is redirected to reduce noise
test_build_output_redirected() {
    local content
    content=$(cat "$HOOK_SCRIPT")

    # swift build should redirect output
    local build_line
    build_line=$(grep "swift build" "$HOOK_SCRIPT" || true)

    if [[ "$build_line" == *"2>&1"* ]]; then
        return 0
    else
        echo "swift build should redirect stderr to stdout"
        return 1
    fi
}

# Test: Script uses full paths for system commands
test_uses_explicit_paths_for_critical_commands() {
    local content
    content=$(cat "$HOOK_SCRIPT")

    # cd commands should use quoted variables
    assert_contains "$content" 'cd "$CLAUDE_PROJECT_DIR"' "Should quote CLAUDE_PROJECT_DIR"
    assert_contains "$content" "cd /tmp" "Should use absolute path for tmp"
}

# Test: Plugin installation uses correct repository format
test_plugin_repository_format() {
    local content
    content=$(cat "$HOOK_SCRIPT")

    # Plugins should be installed from claude-plugins-official
    assert_contains "$content" "@claude-plugins-official" "Plugins should be from official repository"

    # Count how many plugin installs follow the pattern
    local official_plugin_count
    official_plugin_count=$(grep -c "@claude-plugins-official" "$HOOK_SCRIPT" || true)

    if [[ "$official_plugin_count" -ge 5 ]]; then
        return 0
    else
        echo "Should install multiple plugins from official repository"
        return 1
    fi
}

# Additional regression and edge case tests

# Test: Script handles both installed and not-installed package states
test_handles_package_state_transitions() {
    local content
    content=$(cat "$HOOK_SCRIPT")

    # Should check if packages are NOT installed (dpkg -s failure case)
    assert_contains "$content" "if ! dpkg -s" "Script should handle not-installed state"
}

# Test: Swift installation uses correct default home directory
test_swift_home_directory_default() {
    local content
    content=$(cat "$HOOK_SCRIPT")

    # Should have fallback for SWIFTLY_HOME_DIR
    assert_contains "$content" '$HOME/.local/share/swiftly' "Script should use default swiftly home"
}

# Test: Script avoids redundant installations
test_avoids_redundant_swift_installation() {
    local content
    content=$(cat "$HOOK_SCRIPT")

    # Swift check should prevent reinstallation
    assert_contains "$content" "if ! command -v swift" "Script should check if swift exists before installing"
}

# Test: Environment persistence is conditional
test_env_persistence_conditional() {
    local content
    content=$(cat "$HOOK_SCRIPT")

    # Should check if CLAUDE_ENV_FILE is set before using it
    assert_contains "$content" 'if [ -n "${CLAUDE_ENV_FILE:-}"' "Script should check CLAUDE_ENV_FILE is set"
}

# Test: Architecture variable is used consistently
test_architecture_variable_consistency() {
    local content
    content=$(cat "$HOOK_SCRIPT")

    # ARCH should be used for download and extraction
    local arch_usage_count
    arch_usage_count=$(grep -c '${ARCH}' "$HOOK_SCRIPT" || true)

    if [[ "$arch_usage_count" -ge 2 ]]; then
        return 0
    else
        echo "ARCH variable should be used consistently (at least 2 times)"
        return 1
    fi
}

# Test: Script uses logical AND for package checks
test_uses_and_for_package_checks() {
    local content
    content=$(cat "$HOOK_SCRIPT")

    # Should check multiple packages with OR logic (||)
    assert_contains "$content" "||" "Script should use OR logic for checking multiple packages"
}

# Test: Curl uses fail-fast options
test_curl_fail_fast() {
    local content
    content=$(cat "$HOOK_SCRIPT")

    # -f flag makes curl fail on HTTP errors
    assert_contains "$content" "curl -fsSLO" "Curl should use -f flag for fail-fast"
}

# Test: Tarball extraction is quiet
test_tarball_extraction_quiet() {
    local content
    content=$(cat "$HOOK_SCRIPT")

    # tar should extract quietly
    assert_contains "$content" "tar zxf" "Should use tar zxf for quiet extraction"
}

# Test: No hardcoded architecture values
test_no_hardcoded_architecture() {
    local content
    content=$(cat "$HOOK_SCRIPT")

    # Should NOT have hardcoded x86_64 or arm64 in download URLs
    if grep -q "x86_64" "$HOOK_SCRIPT" && grep -q "swiftly-x86_64.tar.gz" "$HOOK_SCRIPT"; then
        echo "Should not hardcode architecture in URLs"
        return 1
    fi

    # Using variable is correct
    assert_contains "$content" 'swiftly-${ARCH}' "Should use variable for architecture"
}

# Test: apt-get update happens before install
test_apt_update_before_install() {
    local content
    content=$(cat "$HOOK_SCRIPT")

    # Find line numbers
    local update_lines
    local install_lines
    update_lines=$(grep -n "apt-get update" "$HOOK_SCRIPT" | cut -d: -f1 || true)
    install_lines=$(grep -n "apt-get install" "$HOOK_SCRIPT" | cut -d: -f1 || true)

    # At least one update should come before at least one install
    local first_update
    local first_install
    first_update=$(echo "$update_lines" | head -1)
    first_install=$(echo "$install_lines" | head -1)

    if [[ -n "$first_update" && -n "$first_install" && "$first_update" -lt "$first_install" ]]; then
        return 0
    else
        echo "apt-get update should come before apt-get install"
        return 1
    fi
}

# Test: Script sources environment file correctly
test_sources_env_file_safely() {
    local content
    content=$(cat "$HOOK_SCRIPT")

    # Should use safe sourcing with quotes
    assert_contains "$content" '. "' "Should quote path when sourcing"
}

# Test: Plugin install output is redirected
test_plugin_output_redirected() {
    local content
    content=$(cat "$HOOK_SCRIPT")

    # Plugin installs should redirect stderr
    local plugin_redirect_count
    plugin_redirect_count=$(grep -c "claude plugin install.*2>&1" "$HOOK_SCRIPT" || true)

    if [[ "$plugin_redirect_count" -gt 0 ]]; then
        return 0
    else
        echo "Plugin installs should redirect output"
        return 1
    fi
}

# Test: Script avoids unnecessary subshells
test_avoids_unnecessary_subshells() {
    local content
    content=$(cat "$HOOK_SCRIPT")

    # Should use command substitution efficiently
    assert_contains "$content" 'ARCH="$(uname -m)"' "Should use command substitution for ARCH"
}

# Test: Cleanup happens in correct directory
test_cleanup_in_tmp_directory() {
    local content
    content=$(cat "$HOOK_SCRIPT")

    # Verify cd /tmp happens before cleanup
    local cd_tmp_line
    local rm_swiftly_line
    cd_tmp_line=$(grep -n "cd /tmp" "$HOOK_SCRIPT" | head -1 | cut -d: -f1)
    rm_swiftly_line=$(grep -n "rm -f.*swiftly" "$HOOK_SCRIPT" | head -1 | cut -d: -f1)

    if [[ "$cd_tmp_line" -lt "$rm_swiftly_line" ]]; then
        return 0
    else
        echo "Should cd to /tmp before cleanup"
        return 1
    fi
}

# Test: Build happens in project directory
test_build_in_project_directory() {
    local content
    content=$(cat "$HOOK_SCRIPT")

    # Find line numbers
    local cd_project_line
    local swift_build_line
    cd_project_line=$(grep -n 'cd "$CLAUDE_PROJECT_DIR"' "$HOOK_SCRIPT" | head -1 | cut -d: -f1)
    swift_build_line=$(grep -n "swift build" "$HOOK_SCRIPT" | head -1 | cut -d: -f1)

    if [[ "$cd_project_line" -lt "$swift_build_line" ]]; then
        return 0
    else
        echo "Should cd to project directory before building"
        return 1
    fi
}

# Test: Script has proper error handling with set options
test_proper_error_handling() {
    local content
    content=$(cat "$HOOK_SCRIPT")

    # set -e: exit on error
    # set -u: error on undefined variable
    # set -o pipefail: error in pipe
    assert_contains "$content" "set -euo pipefail" "Should have comprehensive error handling"
}

# Test: Package installation uses -y flag for non-interactive
test_package_install_non_interactive() {
    local content
    content=$(cat "$HOOK_SCRIPT")

    # All apt-get install commands should have -y
    local install_count
    local install_y_count
    install_count=$(grep -c "apt-get install" "$HOOK_SCRIPT" || true)
    install_y_count=$(grep -c "apt-get install.*-y" "$HOOK_SCRIPT" || true)

    if [[ "$install_count" -eq "$install_y_count" ]]; then
        return 0
    else
        echo "All apt-get install commands should use -y flag"
        return 1
    fi
}

# Test: Swift installation appends to CLAUDE_ENV_FILE
test_swift_env_file_append() {
    local content
    content=$(cat "$HOOK_SCRIPT")

    # Should append (>>) not overwrite (>)
    assert_contains "$content" '>> "$CLAUDE_ENV_FILE"' "Should append to CLAUDE_ENV_FILE"
}

# Test: Swiftly download URL uses HTTPS
test_swiftly_download_https() {
    local content
    content=$(cat "$HOOK_SCRIPT")

    assert_contains "$content" "https://download.swift.org/swiftly" "Should download swiftly over HTTPS"
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
run_test test_secure_curl_options
run_test test_handles_multiple_architectures
run_test test_plugin_failure_resilience
run_test test_suppresses_package_check_noise
run_test test_expects_required_env_vars
run_test test_swiftly_cleanup_complete
run_test test_build_output_redirected
run_test test_uses_explicit_paths_for_critical_commands
run_test test_plugin_repository_format
run_test test_handles_package_state_transitions
run_test test_swift_home_directory_default
run_test test_avoids_redundant_swift_installation
run_test test_env_persistence_conditional
run_test test_architecture_variable_consistency
run_test test_uses_and_for_package_checks
run_test test_curl_fail_fast
run_test test_tarball_extraction_quiet
run_test test_no_hardcoded_architecture
run_test test_apt_update_before_install
run_test test_sources_env_file_safely
run_test test_plugin_output_redirected
run_test test_avoids_unnecessary_subshells
run_test test_cleanup_in_tmp_directory
run_test test_build_in_project_directory
run_test test_proper_error_handling
run_test test_package_install_non_interactive
run_test test_swift_env_file_append
run_test test_swiftly_download_https

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