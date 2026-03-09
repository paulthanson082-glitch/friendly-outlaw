---
name: build-and-test
description: Build the project and run the full test suite. Use before committing changes or when verifying the project is in a clean state.
---

# Build and Test

Run the following commands in order.

## 1. Build (debug)

```bash
swift build 2>&1
```

A clean build output ends with `Build complete!`. Compiler errors appear as `error:` lines — fix them before proceeding.

## 2. Run tests

```bash
swift test 2>&1
```

All tests should pass. The output ends with:
```
Test Suite 'All tests' passed ...
```

If tests fail, use the `swift-debugger` subagent to diagnose, or the `test-runner` subagent for a concise failure summary.

## 3. Release build (optional — before tagging a release)

```bash
swift build -c release 2>&1
```

## Common failure patterns

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `missing sqlite3` / `CSQLite` link error | `libsqlite3-dev` not installed | `apt-get install libsqlite3-dev pkg-config` |
| `cannot find type 'X' in scope` | New type not imported or file not in target | Check `Package.swift` target sources |
| Test count assertion fails | Template count changed | Update the `XCTAssertEqual` in `WritersAppTests.swift` |
| `error: expression is ambiguous` | Enum case added without updating switch exhaustiveness | Add the missing `case` to every `switch` on that enum |

## Tip

The `session-start.sh` hook runs `swift build` automatically at the start of each Claude Code web session, so dependencies and build artifacts are usually already cached.
