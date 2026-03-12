# Test Suite

This directory contains comprehensive test suites for the changed files in this pull request.

## Test Files

### 1. `test_firecrawl_skill_generator.py`

Comprehensive unit tests for `examples/firecrawl_skill_generator.py`.

**Test Coverage:**
- Language detection (`_detect_lang` function) - 13 tests
- Skill markdown rendering - 4 tests
- Firecrawl API calls - 7 tests
- Argument parsing - 4 tests
- Main function integration - 4 tests
- Schema validation - 3 tests
- Edge cases - 6 tests
- Integration scenarios - 1 test
- Robustness and regression cases - 23 tests

**Total: 65 tests**

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
- `TestRobustnessAndRegressionCases`: Additional robustness, negative cases, and regression prevention tests (including API request validation, HTTP method verification, content-type headers, and special character handling)

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
- Regression tests - 2 tests

**Total: 35 tests**

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
- Regression tests to verify Firecrawl CLI is not installed (removed in PR)

## Test Results

All tests pass successfully:
- Python tests: 65/65 passed ✅
- Bash tests: 35/35 passed ✅

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