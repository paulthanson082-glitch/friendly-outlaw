# AGENTS.md

A guide for AI coding agents working on the **friendly-outlaw** writers app — a Swift library and CLI for template-driven document creation, word count tracking, and AI-powered writing assistance.

## Project overview

- **Language**: Swift 5.9+
- **Platforms**: macOS 13+, iOS 16+, Linux (with SQLite3)
- **Type**: Swift Package Manager library (`WritersApp`) + CLI executable (`WritersAppCLI`)
- **Dependencies**: Swift standard library + system SQLite3 (via `CSQLite` module)
- **AI backend**: Anthropic Claude API (optional, enabled via `ANTHROPIC_API_KEY`)

## Setup commands

```bash
# Install system SQLite (Linux only)
sudo apt-get install libsqlite3-dev    # Ubuntu/Debian
sudo dnf install sqlite-devel          # Fedora/RHEL

# Install Node.js dependencies (Next.js web interface)
npm install

# Build
swift build                            # Debug build
swift build -c release                 # Release/optimized build

# Run
swift run WritersAppCLI                # Interactive CLI (debug)
./run.sh                               # Convenience wrapper (debug)
./run.sh --release                     # Convenience wrapper (release)
ANTHROPIC_API_KEY="sk-..." swift run WritersAppCLI  # With AI features

# Test
swift test                             # Run all tests
swift test --verbose                   # Verbose output

# Clean
swift package clean
```

## Project structure

```
/
├── Sources/
│   ├── WritersApp/                    # Main library (public API)
│   │   ├── Models/
│   │   │   ├── Template.swift         # Template, TemplateCategory, Placeholder
│   │   │   ├── Document.swift         # Document, DocumentMetadata
│   │   │   ├── AIModels.swift         # AI configuration and enums
│   │   │   ├── AISuggestion.swift     # AI suggestion and session models
│   │   │   └── iPadProModels.swift    # iPad-specific models
│   │   ├── Services/
│   │   │   ├── TemplateManager.swift  # Template CRUD + 7 default templates
│   │   │   ├── DocumentManager.swift  # Document CRUD + statistics
│   │   │   ├── AIService.swift        # Claude API integration (18+ methods)
│   │   │   └── DatabaseManager.swift  # SQLite persistence layer
│   │   ├── Views/                     # SwiftUI views (iPad Pro / Metal Dashboard)
│   │   ├── Plugins/                   # MCP plugin system
│   │   ├── Extensions/
│   │   │   └── String+Extensions.swift
│   │   └── WritersApp.swift           # Main app class (public entry point)
│   └── WritersAppCLI/
│       └── main.swift                 # Interactive CLI
├── Tests/
│   └── WritersAppTests/
│       └── WritersAppTests.swift      # 11 unit tests
├── examples/
│   ├── python_ai_service.py           # Python Anthropic SDK example
│   └── requirements.txt
├── Package.swift                      # SPM manifest
└── server.json                        # MCP registry metadata
```

## Code style

- Swift 5.9+ — use `async throws` for all AI and async operations
- **Structs** for data models (`Document`, `Template`, `AIConfiguration`)
- **Classes** for services and managers (`WritersApp`, `TemplateManager`, `AIService`)
- **Enums** for typed values (`TemplateCategory`, `AIModel`, `WritingTone`)
- All models conform to `Codable` (JSON serialization) and `Identifiable` (UUID `id`)
- Use `// MARK: - Section Name` for code organization sections
- Method naming: verbs — `createDocument`, `improveText`, `brainstormIdeas`
- Property naming: descriptive nouns — `wordCount`, `characterCount`, `readingTime`
- Placeholder format in templates: `{{placeholder_key}}`
- No external Swift dependencies — use Swift standard library only

## Testing instructions

```bash
swift test
```

The test suite covers template loading, document creation, word count calculation, CRUD operations, export formats, statistics, and placeholder substitution. Always run tests after modifying any file in `Sources/` or `Tests/`. Fix all failures before committing.

When adding new features:
- Add tests for new template types, document operations, or export formats
- Do not modify `Package.swift` without understanding how it affects build configuration

## Common tasks

### Add a new template
1. Edit `Sources/WritersApp/Services/TemplateManager.swift`
2. Add a new entry in `loadDefaultTemplates()`
3. Define each `Placeholder` with `key`, `label`, `isRequired`, and optional `defaultValue`
4. Add or update tests in `Tests/WritersAppTests/WritersAppTests.swift`

### Add a new AI feature
1. Add a method to `Sources/WritersApp/Services/AIService.swift`
2. Add the corresponding `AIAssistanceType` case in `Sources/WritersApp/Models/AIModels.swift`
3. Expose it via `WritersApp.swift` if it needs a top-level API
4. Add a CLI menu option in `Sources/WritersAppCLI/main.swift` if applicable

### Add a new export format
1. Add a new case to the export format enum
2. Implement the conversion inside `exportDocument()` in `WritersApp.swift`
3. Update tests

### Modify a model
1. Update the struct in `Sources/WritersApp/Models/`
2. Ensure `Codable` conformance is intact (add `CodingKeys` if needed)
3. Update related manager methods
4. Update tests

## Environment variables

| Variable | Purpose |
|---|---|
| `ANTHROPIC_API_KEY` | Enables AI features via Claude API (optional) |

AI features degrade gracefully when the key is absent. The CLI auto-detects it at startup.

## Key APIs

### WritersApp (main class)
```swift
createDocumentFromTemplate(templateId:values:) -> Document?
createBlankDocument(title:category:) -> Document
exportDocument(id:format:) -> String?          // .markdown, .plainText, .html
enableAI(configuration:)
continueDocument(documentId:context:appendToDocument:) async throws -> String
improveDocument(documentId:context:replaceContent:) async throws -> String
analyzeDocument(documentId:) async throws -> DocumentAnalysis
brainstormIdeas(topic:context:) async throws -> String
```

### AIService (18+ methods)
`continueWriting`, `improveText`, `checkGrammar`, `generateTitles`, `summarize`,
`expandText`, `brainstormIdeas`, `generateOutline`, `developCharacter`,
`improveDialogue`, `analyzeDocument`, `getWritingInsights`, `changeTone`, and more.

### TemplateCategory enum values
`novel`, `shortStory`, `screenplay`, `blogPost`, `article`, `essay`, `poetry`,
`businessLetter`, `proposal`, `resume`, `other`

## PR instructions

- Branch naming: `feature/<short-description>` or `fix/<short-description>`
- Keep commits focused — one logical change per commit
- Run `swift test` and ensure all tests pass before opening a PR
- Run `swift build` in release mode (`swift build -c release`) before merging performance-sensitive changes
- Describe *why* the change is needed, not just what changed
