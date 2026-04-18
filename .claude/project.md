# friendly-outlaw: Quick Project Reference

A Swift application for writers with templates, documents, AI assistance, version control, and plugins.

## What It Is

**friendly-outlaw** helps writers with:
- **Templates** — Pre-built writing structures (novel outline, screenplay, blog post, etc.)
- **Documents** — Create and track documents, word count, export to Markdown/HTML/plaintext
- **AI Writing Assistant** — Claude integration for brainstorming, editing, outlining (opt-in)
- **Issues** — Track problems per-document with status and priority
- **Kanban Boards** — Organize writing tasks in columns (backlog → planning → running → review → done)
- **Version Control** — Git-like branching, commits, diffs for document snapshots
- **Plugins** — Extensible architecture for memory storage, MCP servers, custom actions
- **Analytics** — Track writing streaks, sessions, productivity

**Platform:** macOS 13+, iOS 16+ | **Language:** Swift 5.9+ | **Build:** SPM

---

## Quick Commands

```bash
# Build
swift build                    # Debug build
swift build -c release         # Release build

# Test
swift test                     # All tests (88+)
swift test --verbose          # Detailed output

# Run
swift run WritersAppCLI       # Interactive CLI
ANTHROPIC_API_KEY=sk-... \
  swift run WritersAppCLI    # With AI features enabled

# Clean
swift package clean           # Remove build artifacts
```

---

## Project Structure

```
Sources/WritersApp/
├── Models/                   # Data structures (Template, Document, Issue, etc.)
├── Services/                 # Business logic (TemplateManager, AIService, etc.)
├── Plugins/                  # Plugin architecture (Plugin protocol, PluginManager)
├── Views/                    # UI (Metal dashboard, iPad views)
└── Extensions/               # Utilities (string placeholders, Codable types)

Tests/WritersAppTests/
└── WritersAppTests.swift     # 88+ tests for all major components

.claude/
├── knowledge/                # Structured standards (JSON)
├── agents/                   # Subagents (knowledge-advisor, debugger, etc.)
├── skills/                   # Workflows (add-template, add-ai-feature, etc.)
└── hooks/                    # Automation (session-start.sh installs deps)
```

---

## Key Concepts

### Managers
Classes that handle CRUD and business logic. All are properties of the main `WritersApp` class:
- `TemplateManager` — Template library (7 defaults)
- `DocumentManager` — Document lifecycle + statistics
- `IssueManager` — Issue tracking per-document
- `KanbanManager` — Kanban boards and task workflow
- `WritingGoalManager` — Goal creation + progress tracking
- `PluginManager` — Singleton, manages all plugins

### Services
Classes that handle complex operations:
- `AIService` — Anthropic API calls, tool loop
- `DatabaseManager` — SQLite persistence (sessions, suggestions, version control)
- `DoltVersionControlService` — Git-like branching, commits, diffs, time-travel
- `EncouragementService` — Motivational messages
- `ProductivityAnalytics` — Writing statistics and trends

### The Plugin System
Extensible via the `Plugin` protocol:
- `ClaudeMemoryPlugin` — Key/value memory store
- `MCPClient` — Model Context Protocol client for external MCP servers
- User can add more plugins — they all implement `initialize()`, `shutdown()`, `execute(action:)`

### Version Control (Dolt-Inspired)
Git-like semantics for documents:
- Branches, commits, diffs, merges
- Time-travel queries (`query(asOf:)`)
- Merge strategies: fast-forward and 3-way merge
- Backed by SQLite for durability

### AI Tool Loop
Claude can call built-in tools during responses:
- `get_word_count` — Count words
- `search_documents` — Search by query
- `get_document` — Fetch document by title
- `calculate_reading_time` — Reading time estimate (200 wpm)
- `list_templates` — List templates by category

---

## Code Conventions

### Naming
- Methods: verbs (`createDocument`, `improveText`, `brainstormIdeas`)
- Properties: descriptive (`wordCount`, `isAchieved`, `progressPercentage`)
- Status/state: `updateIssueStatus`, `checkoutBranch`, `moveKanbanTask`

### Organization
- `// MARK: - Section Name` for code sections
- Public interfaces first, private implementation below
- Conform types to `Codable` for JSON serialization

### Async/Await
- All AI and plugin operations are `async throws`
- Typed errors: `AIError`, `DatabaseError`, `VersionControlError`, `PluginError`

### No External Dependencies
The main library (`WritersApp`) has zero external dependencies:
- No third-party HTTP clients (use `URLSession`)
- No JSON parsing libraries (use `Codable`)
- Only dependency: `CSQLite` (system library wrapping sqlite3)

---

## High-Level APIs

### Initialization
```swift
let app = WritersApp()                                    // No AI
let app = WritersApp(aiConfiguration: config)            // With AI
let app = WritersApp(databasePath: ":memory:")            // In-memory DB (tests)
```

### Documents
```swift
app.createDocumentFromTemplate(templateId:values:)
app.createBlankDocument(title:category:)
app.exportDocument(id:format:)  // .markdown, .plainText, .html
app.documentManager.getStatistics()
```

### AI (requires `enableAI()` first)
```swift
app.enableAI(configuration: config, userId: userId)

// High-level helpers
try await app.continueDocument(documentId:context:appendToDocument:)
try await app.improveDocument(documentId:context:replaceContent:)
try await app.brainstormIdeas(topic:context:)
try await app.generateOutline(concept:context:)

// With tool loop (Claude calls your built-in tools)
try await app.getAIAssistanceWithTools(
    documentId:type:context:maxIterations:
)
```

### Issues
```swift
app.issueManager.createIssue(documentId:title:description:status:priority:)
app.issueManager.getIssues(forDocument:)
app.issueManager.updateIssueStatus(id:status:)
app.issueManager.reopenIssue(id:)  // Clears resolvedAt timestamp
```

### Kanban
```swift
app.kanbanManager.createKanbanBoard(name:description:)
app.kanbanManager.createKanbanTask(boardId:title:description:column:)
app.kanbanManager.moveKanbanTask(id:toColumn:)
app.kanbanManager.advanceKanbanTask(id:)  // Next column in workflow
```

### Version Control
```swift
try app.versionControl.initializeDefaultBranch()
try app.versionControl.commit(message:author:timestamp:)
try app.versionControl.checkoutBranch(name:)
try app.versionControl.diff(from:to:)
try app.versionControl.merge(source:strategy:)
try app.versionControl.query(asOf:)  // Time-travel queries
```

### Plugins
```swift
try await app.enableMemoryPlugin()
try await app.storeMemory(key:value:category:tags:importance:)
try await app.retrieveMemory(key:)
try await app.searchMemories(query:category:limit:)
```

---

## Development Notes

- **AI is optional** — Works without `ANTHROPIC_API_KEY` (graceful degradation)
- **Database location** — Defaults to `~/Documents/writersapp.db`; override via init
- **PluginManager is a singleton** — `PluginManager.shared` — register plugins once at app startup
- **Dual-layer design** — IssueManager and version control are in-memory + SQLite-backed; keep them in sync via WritersApp facade
- **Dates use ISO 8601** — For JSON serialization
- **CSQLite is required** — `libsqlite3-dev` and `pkg-config` must be installed

---

## Testing

Run all tests: `swift test`

Coverage:
- **Core:** templates, documents, word count, statistics, placeholders (8 tests)
- **AI tool loop:** ToolDefinition, ToolUseBlock, ToolResult, WritingToolExecutor (16 tests)
- **Issues:** CRUD, status/priority management, reopen (3 tests)
- **Kanban:** boards, tasks, column workflow (18 tests)
- **Version control:** branches, commits, diffs, merges, time-travel (17 tests)
- **Total: 88+ tests**

All tests must pass before committing.

---

## Environment Variables

| Variable | Purpose |
|----------|---------|
| `ANTHROPIC_API_KEY` | Claude API key (enables AI features) |
| `CLAUDE_PROJECT_DIR` | Project root (set by session-start hook) |

---

## Next Steps

- **Starting a task?** → Read `.claude/workflow.md` to understand ask → plan → execute
- **Adding a feature?** → Check `.claude/knowledge/` for standards first
- **Debugging?** → Use the swift-debugger or test-runner agents
- **Want examples?** → See `examples/` directory for Python Anthropic SDK usage
