# Spec Kit — friendly-outlaw

This document describes how to use [Spec-Driven Development](https://github.com/github/spec-kit) with the **friendly-outlaw** writers app. Follow the workflow below to contribute new features or extend the application in a structured, predictable way.

## Prerequisites

- [uv](https://github.com/astral-sh/uv) for Python package management
- Python 3.11+
- Git
- A supported AI coding agent (Claude Code, Copilot, Cursor, etc.)

## Install Specify CLI

```bash
# Persistent installation (recommended)
uv tool install specify-cli --from git+https://github.com/github/spec-kit.git

# Verify installation
specify check
```

## Initialize Spec Kit in This Project

If Spec Kit has not been initialised yet, run from the project root:

```bash
specify init . --ai claude
# or for Copilot
specify init . --ai copilot
```

---

## Spec-Driven Development Workflow

### Step 1 — Establish Principles (`/speckit.constitution`)

Run once per project (already done — see [Constitution](#project-constitution) below). Re-run only when governance or standards need updating.

```
/speckit.constitution Create principles focused on Swift code quality,
async/await patterns, SQLite persistence, no external dependencies beyond
CSQLite, and comprehensive unit-test coverage consistent with the existing test suite.
```

### Step 2 — Define What to Build (`/speckit.specify`)

Describe the feature in plain language — what and why, not how.

```
/speckit.specify Add a writing-streak leaderboard that shows the top 10 users
by consecutive daily writing days, displayed as a section in the CLI menu and
queryable via the WritersApp public API.
```

### Step 3 — Create a Technical Plan (`/speckit.plan`)

Provide your architectural constraints and preferred tech choices.

```
/speckit.plan Swift 5.9+, macOS 13 / iOS 16. No new external dependencies.
Persist streak data in the existing SQLite database via DatabaseManager.
Expose the leaderboard through WritersApp as a new public method.
Add CLI menu option under the Analytics section.
```

### Step 4 — Break Down into Tasks (`/speckit.tasks`)

```
/speckit.tasks
```

The agent will produce a numbered, actionable task list derived from the plan.

### Step 5 — Implement (`/speckit.implement`)

```
/speckit.implement
```

The agent executes all tasks, writes code, and runs `swift test` to confirm nothing is broken.

---

## Optional Quality Commands

| Command | When to use |
|---|---|
| `/speckit.clarify` | Before `/speckit.plan` — surface ambiguities in the spec |
| `/speckit.analyze` | After `/speckit.tasks`, before `/speckit.implement` — cross-artifact consistency check |
| `/speckit.checklist` | Generate acceptance criteria from the spec |

---

## Project Constitution

The following principles govern all development on friendly-outlaw.

### Code Quality
- All public APIs must have clear, descriptive names following the verb-noun convention (`createDocument`, `improveText`, `advanceKanbanTask`).
- Use `// MARK: - Section Name` to organise every source file.
- Prefer `struct` for data, `class` for services and managers, `enum` for domain types.
- All domain types must conform to `Codable` and `Identifiable` (UUID `id`).

### Swift Patterns
- All AI and plugin operations must be `async throws`.
- Use typed errors (`AIError`, `DatabaseError`, `VersionControlError`, `PluginError`) — never throw `String` or untyped errors.
- Avoid force-unwraps (`!`) in production code; use `guard let` or `if let`.
- No external dependencies beyond `CSQLite` (which wraps the system `sqlite3`).

### Testing Standards
- Every new public method requires at least one corresponding test in the appropriate feature-specific test file under `Tests/WritersAppTests/` (e.g., `AIServiceTests.swift`, `DatabaseManagerTests.swift`).
- Use `DatabaseManager(databasePath: ":memory:")` for all database tests to ensure isolation.
- AI-dependent tests must be skipped or mocked — do not make real API calls in the test suite.
- Test function names use descriptive camelCase starting with `test`, without underscores (e.g., `testAdvanceKanbanTaskMovesForwardInWorkflow`, `testCreateGoalWithDocumentId`).

### Architecture Rules
- New features that manage domain state belong in a `Manager` class under `Sources/WritersApp/Services/`.
- New stateless operations (AI, analytics, export) belong in a `Service` class.
- Expose new capabilities through the `WritersApp` facade in `WritersApp.swift` as public methods.
- The `PluginManager` is a singleton (`PluginManager.shared`); register plugins once at startup.
- Version control operations must keep the in-memory state and SQLite layer in sync.

### Security
- Never hard-code API keys or secrets. Read them from environment variables only.
- Sanitise all user-supplied strings before constructing SQL queries.
- Validate all external input at system boundaries (CLI, API responses, MCP tool results).

### Performance
- Target sub-100 ms response time for all non-AI, non-network operations.
- Use indexed columns for every frequently-queried SQLite field.
- Paginate results when returning unbounded lists from `DatabaseManager`.

---

## Common Feature Recipes

### Adding a New Template
1. Edit `Sources/WritersApp/Services/TemplateManager.swift`
2. Add an entry to `loadDefaultTemplates()` with a `Template` and `[Placeholder]` array
3. Add a test verifying the template loads and placeholders resolve

### Adding a New AI Capability
1. Add the assistance type case to `AIAssistanceType` in `Sources/WritersApp/Models/AIModels.swift`
2. Add the method to `Sources/WritersApp/Services/AIService.swift`
3. Expose it through `WritersApp.swift`
4. Add a CLI menu entry in `Sources/WritersAppCLI/main.swift`
5. Add a test (mocked — no real API calls)

### Adding a New Export Format
1. Add a case to `ExportFormat` in `Sources/WritersApp/WritersApp.swift`
2. Implement conversion in `exportDocument(id:format:)`
3. Add a test for the new format output

### Adding a New Plugin
1. Create a class conforming to `Plugin` in `Sources/WritersApp/Plugins/`
2. Implement `initialize()`, `shutdown()`, `execute(action:)`
3. Declare `capabilities`
4. Register via `PluginManager.shared.register(plugin: myPlugin)` in `WritersApp.swift`

---

## Running Tests

```bash
swift test                # Run the full test suite
swift test --verbose      # Verbose output with timing
```

Tests must pass before any commit on a feature branch.

---

## Quick Reference

```bash
# Build
swift build               # Debug
swift build -c release    # Release

# Run CLI
swift run WritersAppCLI
ANTHROPIC_API_KEY="sk-..." swift run WritersAppCLI   # With AI

# Clean
swift package clean
```

---

## Further Reading

- [Spec Kit repository](https://github.com/github/spec-kit)
- [Spec-Driven Development methodology](https://github.com/github/spec-kit/blob/main/docs/methodology.md)
- [CLAUDE.md](CLAUDE.md) — full project context for AI assistants
- [DATABASE.md](DATABASE.md) — SQLite schema and API reference
- [QUICK_START.md](QUICK_START.md) — getting started guide
