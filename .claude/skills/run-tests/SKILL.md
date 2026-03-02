---
name: run-tests
description: Run the friendly-outlaw test suite and report results
disable-model-invocation: false
---

# Run Tests

Run the Swift test suite for the friendly-outlaw project and report comprehensive results.

## What to do

1. Run `swift test --verbose` to execute all 88+ unit tests
2. Parse the output to identify:
   - Total test count and pass/fail breakdown
   - Failed tests with error messages (if any)
   - Test execution time
3. Report results in a clear format
4. If tests fail, highlight the failing tests and suggest fixes based on the test names and errors

## Key test groups

- **Core**: Templates, documents, word count, statistics
- **Tool loop**: Tool definitions, tool use blocks, tool results
- **Writing tools**: Built-in AI tool executor (5 tools)
- **Issues**: Issue CRUD operations and status management
- **Kanban**: Board and task management, workflow transitions
- **Version control**: Branches, commits, diffs, merges, time-travel queries

## Tips

- Tests are in `Tests/WritersAppTests/WritersAppTests.swift`
- Use `-c release` flag if you need a faster build
- Check `ANTHROPIC_API_KEY` for AI-related tests
