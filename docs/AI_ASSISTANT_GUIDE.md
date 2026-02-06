# AI Assistant Guide — friendly-outlaw

This document provides essential context for AI assistants and contributors working with the friendly-outlaw codebase.

Table of contents
- [Project overview](#project-overview)
- [Quick commands](#quick-commands)
- [Project structure](#project-structure)
- [Architecture & patterns](#architecture--patterns)
- [Key APIs](#key-apis)
- [AI integration](#ai-integration)
- [Testing](#testing)
- [Environment variables & secrets](#environment-variables--secrets)
- [Plugin system](#plugin-system)
- [Common tasks for AI assistants](#common-tasks-for-ai-assistants)
- [Where not to edit lightly](#where-not-to-edit-lightly)
- [Git workflow & VS Code](#git-workflow--vs-code)

## Project overview

friendly-outlaw is a Swift application and CLI for writers offering:
- Template management
- Document creation with word/count and statistics
- AI-powered authoring features (Anthropic / Claude)
- Multi-format export (.markdown, .plainText, .html)

Platforms: macOS 13+, iOS 16+  
Swift: 5.9+

## Quick commands

Build / test / run:
```bash
swift build
swift build -c release

swift test
swift test --verbose

# Run CLI
swift run WritersAppCLI
# With AI (use environment variable; don't commit keys):
export ANTHROPIC_API_KEY="<your-anthropic-api-key>"
swift run WritersAppCLI

# Clean
swift package clean
```

## Project structure

```
/
├── Sources/
│   ├── WritersApp/
│   │   ├── Models/          # Template.swift, Document.swift, AIModels.swift
│   │   ├── Services/        # TemplateManager.swift, DocumentManager.swift, AIService.swift
│   │   ├── Plugins/         # Plugin system and Claude Memory plugin
│   │   │   ├── Plugin.swift            # Plugin protocol, types, errors
│   │   │   ├── PluginManager.swift     # Plugin lifecycle and registration
│   │   │   ├── ClaudeMemoryPlugin.swift # Built-in memory storage plugin
│   │   │   └── MCPClient.swift         # Model Context Protocol client
│   │   ├── Extensions/
│   │   └── WritersApp.swift
│   └── WritersAppCLI/
│       └── main.swift
├── Tests/
│   └── WritersAppTests/     # Includes PluginTests.swift
├── examples/
├── .vscode/
├── Package.swift
└── README.md
```

## Architecture & patterns

- Manager pattern: TemplateManager, DocumentManager
- Service pattern: AIService for all Anthropic API operations
- Models: structs (Document, Template), classes for services, enums (TemplateCategory, AIModel, WritingTone, AIAssistanceType)
- Async/await: all AI operations are `async throws` and should use typed errors (`AIError`, `AIServiceError`)

## Key APIs (high level)

WritersApp (main entry points)
```swift
// Document operations
createDocumentFromTemplate(templateId:values:) -> Document?
createBlankDocument(title:category:) -> Document
exportDocument(id:format:) -> String?  // .markdown, .plainText, .html

// AI operations (requires enableAI(configuration:) first)
enableAI(configuration:)
continueDocument(documentId:context:appendToDocument:) async throws -> String
improveDocument(documentId:context:replaceContent:) async throws -> String
analyzeDocument(documentId:) async throws -> DocumentAnalysis
brainstormIdeas(topic:context:) async throws -> String
```

AIService methods (common)
- continueWriting(), improveText(), checkGrammar()
- generateTitles(), summarize(), expandText()
- brainstormIdeas(), generateOutline(), developCharacter()
- improveDialogue(), analyzeDocument(), getWritingInsights()
- customRequest() for one-off prompts

## AI integration

Configuration example (do not commit keys):
```swift
let config = AIConfiguration(
    apiKey: "<your-anthropic-api-key>",
    model: .claude35Sonnet,   // verify current model names in Anthropic docs
    maxTokens: 4096,
    temperature: 0.7
)
```

API details (implementation notes)
- Endpoint used in code: https://api.anthropic.com/v1/messages
- Auth header: `x-api-key: <API_KEY>`
- Version header: `anthropic-version: 2023-06-01` (confirm with Anthropic docs)
- Ensure code checks HTTP status and parses response safely

## Testing

There are unit tests covering templates, document creation, word counts, exports, and substitution. Run:
```bash
swift test
```

If you add AI tests, do not store real keys in the repo. Use CI secret stores or local environment variables.

## Environment variables & secrets

- ANTHROPIC_API_KEY — Anthropic / Claude API key

Security guidance:
- Never commit API keys or secrets.
- Use your OS keyring or CI secret store.
- Add a secret-scan step to CI (see suggested GitHub Action example below).

## Plugin system

The app includes a plugin architecture with MCP (Model Context Protocol) support.

### Built-in plugins

- **Claude Memory Plugin** (`claude-memory`): Persistent memory storage for Claude AI interactions with relevance-scored search, TTL support, import/export, and category-based organization.

### Plugin architecture

All plugins conform to the `Plugin` protocol defined in `Sources/WritersApp/Plugins/Plugin.swift`:
- `initialize()` / `shutdown()` — lifecycle management
- `execute(action:)` — action dispatch
- `capabilities` — declares what the plugin provides (memory, tools, resources, prompts, etc.)

### Key plugin types

- `PluginManager` — singleton that handles registration, lifecycle, and action routing
- `PluginAction` / `PluginActionType` — action dispatch system
- `PluginResult` — success/failure result wrapper
- `MCPPlugin` / `MCPClient` — MCP protocol integration for external plugins
- `PluginManifest` / `PluginConfiguration` — plugin metadata and settings persistence

### Memory plugin operations

Available through `WritersApp`:
```swift
app.enableMemoryPlugin()
app.storeMemory(key:value:category:tags:importance:)
app.retrieveMemory(key:)
app.searchMemories(query:category:limit:)
app.listMemories(category:limit:sortBy:)
app.clearMemory(key:category:)
app.getMemoryStats()
```

### Adding a new plugin

1. Create a class conforming to `Plugin` in `Sources/WritersApp/Plugins/`
2. Implement `initialize()`, `shutdown()`, and `execute(action:)`
3. Register via `PluginManager.shared.register(plugin:)`
4. Add tests in `Tests/WritersAppTests/PluginTests.swift`
5. Optionally expose convenience methods in `WritersApp.swift`
6. Add CLI menu options in `main.swift` if needed

## Common tasks for AI assistants

- Adding a template: edit `Sources/WritersApp/Services/TemplateManager.swift` and update `loadDefaultTemplates()`. Add placeholders with the `Placeholder` struct and update tests.
- Adding an AI feature: add method in `Sources/WritersApp/Services/AIService.swift`, create prompt templates, add assistance type to `AIAssistanceType` in `AIModels.swift`, expose via `WritersApp.swift`, and add CLI options if needed.
- Adding a plugin: create a class conforming to `Plugin` in `Sources/WritersApp/Plugins/`, register via `PluginManager`, add tests in `PluginTests.swift`, expose in `WritersApp.swift` and `main.swift`.
- Adding export format: extend export enum and implement in `exportDocument()`; update tests.

## Where not to edit lightly

- `Package.swift` — build config
- Generated or vendored code
- Tests — ensure they continue to pass
- CLI UX — coordinate with maintainers

## Git workflow & VS Code

- Feature branch per change; PRs for reviews
- Suggested labels: documentation, needs-review, security-check
- VS Code tasks pre-configured (Build, Test, Run)

## Suggested small improvements (next steps)
- Move this file to docs/ (done in this change)
- Link from README.md
- Add a TOC with anchor links (included)
- Add a CI secret-scan job and a short "How to run AI integration tests" section
