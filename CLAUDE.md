# CLAUDE.md - AI Assistant Guide for friendly-outlaw

This document provides essential context for AI assistants working with this codebase.

## Project Overview

**friendly-outlaw** is a Swift application for writers featuring template management, document creation with word count tracking, AI-powered writing assistance (via Claude/Anthropic API), and multi-format export capabilities.

- **Type**: Swift library + CLI application
- **Platforms**: macOS 13+, iOS 16+
- **Swift Version**: 5.9+
- **Dependencies**: None (uses Swift standard library only)

## Quick Commands

```bash
# Build
swift build                           # Debug build
swift build -c release                # Release build

# Test
swift test                            # Run all tests
swift test --verbose                  # Verbose output

# Run
swift run WritersAppCLI               # Run CLI app
ANTHROPIC_API_KEY="sk-..." swift run WritersAppCLI  # With AI features

# Clean
swift package clean                   # Remove build artifacts
```

## Project Structure

```
/
├── Sources/
│   ├── WritersApp/                   # Main library (public API)
│   │   ├── Models/                   # Data structures
│   │   │   ├── Template.swift        # Template, TemplateCategory, Placeholder
│   │   │   ├── Document.swift        # Document, DocumentMetadata
│   │   │   └── AIModels.swift        # AI configuration, enums
│   │   ├── Services/                 # Business logic
│   │   │   ├── TemplateManager.swift # Template CRUD + 7 default templates
│   │   │   ├── DocumentManager.swift # Document CRUD + statistics
│   │   │   └── AIService.swift       # Claude API integration
│   │   ├── Extensions/
│   │   │   └── String+Extensions.swift
│   │   └── WritersApp.swift          # Main entry point
│   └── WritersAppCLI/
│       └── main.swift                # Interactive CLI
├── Tests/
│   └── WritersAppTests/
│       └── WritersAppTests.swift     # 11 unit tests
├── examples/
│   ├── python_ai_service.py          # Python Anthropic SDK example
│   └── requirements.txt
├── .vscode/                          # VS Code configuration
├── Package.swift                     # SPM manifest
└── README.md
```

## Architecture Patterns

### Manager Pattern
- `TemplateManager`: Handles template lifecycle and 7 default templates
- `DocumentManager`: Handles document CRUD, search, and statistics

### Service Pattern
- `AIService`: Encapsulates all Anthropic API communication

### Model Structure
- **Structs** for data: `Document`, `Template`, `AIConfiguration`
- **Classes** for services: `WritersApp`, `TemplateManager`, `DocumentManager`, `AIService`
- **Enums** for types: `TemplateCategory`, `AIModel`, `WritingTone`, `AIAssistanceType`

## Code Conventions

### Naming
- Methods use verbs: `createDocument`, `improveText`, `brainstormIdeas`
- Properties are descriptive: `wordCount`, `characterCount`, `readingTime`
- All entities have UUID `id` property (conform to `Identifiable`)

### Organization
- Use `// MARK: - Section Name` for code sections
- Public interfaces at top, private implementation below
- Models conform to `Codable` for JSON serialization

### Async/Await
- All AI operations are `async throws`
- Use proper error handling with typed errors (`AIError`, `AIServiceError`)

### Placeholders in Templates
- Format: `{{placeholder_key}}`
- Replaced via `String+Extensions.swift` utilities

## Key APIs

### WritersApp (Main Class)
```swift
// Document operations
createDocumentFromTemplate(templateId:values:) -> Document?
createBlankDocument(title:category:) -> Document
exportDocument(id:format:) -> String?  // .markdown, .plainText, .html

// AI operations (requires enableAI() first)
enableAI(configuration:)
continueDocument(documentId:context:appendToDocument:) async throws -> String
improveDocument(documentId:context:replaceContent:) async throws -> String
analyzeDocument(documentId:) async throws -> DocumentAnalysis
brainstormIdeas(topic:context:) async throws -> String
```

### AIService Methods (18+)
- `continueWriting()`, `improveText()`, `checkGrammar()`
- `generateTitles()`, `summarize()`, `expandText()`
- `brainstormIdeas()`, `generateOutline()`, `developCharacter()`
- `improveDialogue()`, `analyzeDocument()`, `getWritingInsights()`

## Template Categories

`TemplateCategory` enum values:
- `novel`, `shortStory`, `screenplay`
- `blogPost`, `article`, `essay`, `poetry`
- `businessLetter`, `proposal`, `resume`
- `other`

## AI Integration

### Configuration
```swift
let config = AIConfiguration(
    apiKey: "sk-ant-...",
    model: .claude35Sonnet,  // or .claude3Opus, .claude3Sonnet, .claude3Haiku
    maxTokens: 4096,
    temperature: 0.7
)
```

### API Details
- Endpoint: `https://api.anthropic.com/v1/messages`
- Auth: `x-api-key` header
- Version: `anthropic-version: 2023-06-01`

## Testing

11 test cases covering:
- Template loading and search
- Document creation (from template and blank)
- Word count calculation
- Document manager CRUD
- Export formats
- Statistics generation
- Placeholder substitution

Run with: `swift test`

## Environment Variables

| Variable | Purpose |
|----------|---------|
| `ANTHROPIC_API_KEY` | Claude API key for AI features |

## Knowledge System

Project standards live in `.claude/knowledge/` as structured JSON files. Before making any code change, consult the relevant files or use the **knowledge-advisor** subagent to retrieve applicable rules automatically.

### Knowledge Base Files

| File | Covers |
|------|--------|
| `index.json` | Category index and usage guide |
| `swift.json` | Naming, optionals, async/await, Codable, no-external-deps |
| `architecture.json` | Manager/service layers, how to add features, entry points |
| `security.json` | No hardcoded secrets, input sanitisation, network policy |
| `templates.json` | Placeholder format, count, descriptions, categories |
| `testing.json` | What to test, naming conventions, AI method approach |

### Using the Knowledge Advisor Agent

The **knowledge-advisor** subagent reads the relevant files and returns a focused rule list plus a pre-commit checklist for your specific task. Invoke it before writing code:

> "I am about to add a new async method to AIService for generating chapter outlines. What standards apply?"

The agent selects the right categories (swift + architecture + security + testing for an AI feature), reads the JSON files, and returns only the rules that matter for that task.

### Quick Reference — Which Files to Read

- **Any Swift change**: `swift.json` + `architecture.json` + `testing.json`
- **New AI feature**: all of the above + `security.json`
- **New template**: `templates.json` + `testing.json`
- **Security-sensitive change**: `security.json`

## Common Tasks for AI Assistants

### Adding a New Template
1. Edit `Sources/WritersApp/Services/TemplateManager.swift`
2. Add to `loadDefaultTemplates()` method
3. Define placeholders with `Placeholder` struct
4. Update tests if needed

### Adding a New AI Feature
1. Add method to `Sources/WritersApp/Services/AIService.swift`
2. Create system prompt and user prompt
3. Add assistance type to `AIAssistanceType` enum in `AIModels.swift`
4. Expose via `WritersApp.swift` if needed
5. Add CLI option in `main.swift` if applicable

### Adding a New Export Format
1. Add case to export format enum
2. Implement conversion in `exportDocument()` method
3. Update tests

### Modifying Document/Template Models
1. Update struct in `Models/` directory
2. Ensure `Codable` conformance is maintained
3. Update related manager methods
4. Update tests

## Files to Avoid Modifying Without Care

- `Package.swift` - Changes affect build configuration
- `.vscode/` - VS Code settings for cross-device development
- `Tests/` - Ensure tests pass after changes

## Development Notes

- No external dependencies - uses only Swift standard library
- AI features are optional (graceful degradation without API key)
- CLI auto-detects `ANTHROPIC_API_KEY` environment variable
- All dates use ISO 8601 format for JSON serialization

## VS Code Integration

Pre-configured tasks available via `Cmd+Shift+B`:
- Swift: Build (default)
- Swift: Build Release
- Swift: Test
- Swift: Clean
- Swift: Run CLI

Debug configurations available in Run panel.

## Git Workflow

- Feature branches merged via PRs
- Branch naming: descriptive feature names
- Keep commits focused and well-described
