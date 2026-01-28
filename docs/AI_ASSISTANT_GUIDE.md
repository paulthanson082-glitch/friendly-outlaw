# AI Assistant Guide — friendly-outlaw

This document provides essential context for AI assistants and contributors working with the friendly-outlaw codebase.

Table of contents
- <a>Project overview</a>
- <a>Quick commands</a>
- <a>Project structure</a>
- <a>Architecture &amp; patterns</a>
- <a>Key APIs</a>
- <a>AI integration</a>
- <a>Testing</a>
- <a>Environment variables &amp; secrets</a>
- <a>Common tasks for AI assistants</a>
- <a>Where not to edit lightly</a>
- <a>Git workflow &amp; VS Code</a>

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
│   │   ├── Extensions/
│   │   └── WritersApp.swift
│   └── WritersAppCLI/
│       └── main.swift
├── Tests/
│   └── WritersAppTests/
├── examples/
├── .vscode/
├── Package.swift
└── README.md
```

## Architecture &amp; patterns

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

## Environment variables &amp; secrets

- ANTHROPIC_API_KEY — Anthropic / Claude API key

Security guidance:
- Never commit API keys or secrets.
- Use your OS keyring or CI secret store.
- Add a secret-scan step to CI (see suggested GitHub Action example below).

## Common tasks for AI assistants

- Adding a template: edit `Sources/WritersApp/Services/TemplateManager.swift` and update `loadDefaultTemplates()`. Add placeholders with the `Placeholder` struct and update tests.
- Adding an AI feature: add method in `Sources/WritersApp/Services/AIService.swift`, create prompt templates, add assistance type to `AIAssistanceType` in `AIModels.swift`, expose via `WritersApp.swift`, and add CLI options if needed.
- Adding export format: extend export enum and implement in `exportDocument()`; update tests.

## Where not to edit lightly

- `Package.swift` — build config
- Generated or vendored code
- Tests — ensure they continue to pass
- CLI UX — coordinate with maintainers

## Git workflow &amp; VS Code

- Feature branch per change; PRs for reviews
- Suggested labels: documentation, needs-review, security-check
- VS Code tasks pre-configured (Build, Test, Run)

## Suggested small improvements (next steps)
- Move this file to docs/ (done in this change)
- Link from README.md
- Add a TOC with anchor links (included)
- Add a CI secret-scan job and a short "How to run AI integration tests" section
