# Test Suite

This directory contains comprehensive test suites for the changed files in this pull request.

## Test Files

### 1. `test_firecrawl_skill_generator.py`

Comprehensive unit tests for `examples/firecrawl_skill_generator.py`.

**Test Coverage:**
- Language detection (`_detect_lang` function) - 12 tests
- Skill markdown rendering - 4 tests
- Firecrawl API calls - 7 tests
- Argument parsing - 4 tests
- Main function integration - 4 tests
- Schema validation - 3 tests
- Edge cases - 6 tests
- Integration scenarios - 1 test
- Robustness and regression cases - 13 tests
- Security and validation - 9 tests (NEW)

**Total: 62 tests** (53 original + 9 additional)

**Running the tests:**
```bash
python3 -m pytest tests/test_firecrawl_skill_generator.py -v
```

**Test Categories:**
- `TestLanguageDetection`: Tests for detecting code language in snippets (Python, TypeScript, Bash, JSON)
- `TestRenderSkillMarkdown`: Tests for rendering structured data to markdown skill files
- `TestCallFirecrawlAgent`: Tests for API communication with Firecrawl agent endpoint
- `TestParseArgs`: Tests for command-line argument parsing
- `TestMainFunction`: Tests for main function integration and workflow
- `TestSkillSchema`: Tests for schema validation
- `TestEdgeCases`: Tests for edge cases and boundary conditions
- `TestIntegrationScenarios`: End-to-end integration tests
- `TestRobustnessAndRegressionCases`: Additional robustness, negative cases, and regression prevention tests
- `TestAdditionalSecurityAndValidation`: Security validation, YAML injection prevention, API key handling, and schema validation tests

### 2. `test_session_start.sh`

Bash script tests for `.claude/hooks/session-start.sh`.

**Test Coverage:**
- Script structure and conventions - 5 tests
- Environment checks - 5 tests
- System dependency installation - 3 tests
- Swift installation - 10 tests
- Project building - 2 tests
- Claude plugin installation - 4 tests
- Script logic and flow - 4 tests
- Security and resilience - 9 tests (NEW)

**Total: 42 tests** (33 original + 9 additional)

**Running the tests:**
```bash
bash tests/test_session_start.sh
```

**Test Categories:**
- Basic structure (shebang, executable, strict mode)
- Environment variable handling (CLAUDE_CODE_REMOTE, CLAUDE_PROJECT_DIR, CLAUDE_ENV_FILE)
- Package installation (libsqlite3-dev, pkg-config)
- Swift installation via swiftly
- Project build process
- Claude plugin installation
- Script logic flow validation
- Security (secure curl options, proper cleanup, output redirection)
- Resilience (plugin failure handling, architecture detection, error suppression)

## Test Results

All tests pass successfully:
- Python tests: 62/62 passed ✅ (includes 9 new security & validation tests)
- Bash tests: 42/42 passed ✅ (includes 9 new security & resilience tests)

### New Tests Added

**Python Tests (9 new):**
1. `test_api_key_not_leaked_in_request` - Ensures API keys only appear in headers, not request bodies
2. `test_schema_validation_prevents_missing_required_fields` - Validates critical fields are required
3. `test_render_prevents_yaml_injection` - Tests YAML frontmatter security with special characters
4. `test_file_output_creates_parent_directories` - Regression test for nested path creation
5. `test_render_handles_code_injection_attempt` - Security test for malicious code in examples
6. `test_api_call_authorization_header_format` - Validates proper Bearer token format
7. `test_model_parameter_validation_in_request` - Ensures model selection is correctly passed
8. `test_empty_trigger_conditions_list_renders_correctly` - Regression test for empty trigger lists
9. `test_system_prompt_includes_security_instructions` - Verifies prompt tells agent not to include secrets

**Bash Tests (9 new):**
1. `test_secure_curl_options` - Validates curl uses secure options (-fsSL)
2. `test_handles_multiple_architectures` - Tests dynamic architecture detection
3. `test_plugin_failure_resilience` - Ensures all plugin installs use `|| true`
4. `test_suppresses_package_check_noise` - Validates stderr suppression for clean output
5. `test_expects_required_env_vars` - Tests for required environment variables
6. `test_swiftly_cleanup_complete` - Validates proper cleanup of downloaded files
7. `test_build_output_redirected` - Tests that build output is properly redirected
8. `test_uses_explicit_paths_for_critical_commands` - Validates path safety with quoted variables
9. `test_plugin_repository_format` - Ensures plugins are from official repository

## Dependencies

### Python Tests
- Python 3.7+
- pytest
- unittest (standard library)
- unittest.mock (standard library)

Install pytest if needed:
```bash
pip install pytest
```

### Bash Tests
- Bash 4.0+
- Standard Unix utilities (grep, head, cat)

## Notes

- The Python tests use mocking extensively to avoid actual API calls to Firecrawl
- The bash tests verify script structure and logic without executing the actual installation commands
- Documentation files (`.md` files) are not tested as they contain no executable code