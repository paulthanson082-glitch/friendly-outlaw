# CLAUDE.md - friendly-outlaw Project Documentation

## Project Overview

**friendly-outlaw** is a Swift application and CLI for writers offering:
- Template management
- Document creation with word/count and statistics
- AI-powered authoring features (Anthropic / Claude)
- Multi-format export (.markdown, .plainText, .html)

**Platform Requirements:**
- macOS 14+
- iOS 16+
- Swift 5.9+

**Dependencies:**
- swift-argument-parser 1.3.0+
- Yams 5.0.0+
- Anthropic API (optional, for AI features)

## Quick Commands

```bash
# Build & Test
swift build
swift build -c release
swift test
swift test --verbose

# Run CLI
swift run WritersAppCLI

# With AI (use environment variable)
export ANTHROPIC_API_KEY="<your-anthropic-api-key>"
swift run WritersAppCLI

# Clean
swift package clean
```

## Project Structure

```
/friendly-outlaw
├── Sources/
│   ├── WritersApp/
│   │   ├── Models/              # Core data models
│   │   │   ├── ChatbotModels.swift
│   │   │   ├── CRMModels.swift
│   │   │   ├── HarnessModels.swift
│   │   │   ├── Document.swift
│   │   │   ├── Template.swift
│   │   │   └── AIModels.swift
│   │   ├── Services/            # Business logic
│   │   │   ├── ChatbotService.swift
│   │   │   ├── MultiAgentHarness.swift
│   │   │   ├── RagieService.swift
│   │   │   ├── MockerKit/       # Docker orchestration
│   │   │   ├── DocumentManager.swift
│   │   │   ├── TemplateManager.swift
│   │   │   └── AIService.swift
│   │   ├── Views/
│   │   │   └── CRMDashboardView.swift
│   │   └── WritersApp.swift
│   └── WritersAppCLI/
│       └── main.swift
├── Tests/
│   ├── WritersAppTests/         # 17 test files
│   └── MockerKitTests/
├── examples/                    # Go, firecrawl, Sherlock
├── web/                         # Next.js app
├── mobile/                      # React Native
├── .claude/
│   └── skills/
├── Package.swift
├── README.md
└── DATABASE.md                  # Schema details
```

## Architecture & Patterns

- **Manager Pattern:** TemplateManager, DocumentManager
- **Service Pattern:** AIService for Anthropic operations
- **Models:** Structs (Document, Template), Classes (services), Enums (category, model, tone)
- **Async/Await:** All AI operations use `async throws` with typed errors

## Key APIs

```swift
// Document Operations
createDocumentFromTemplate(templateId:values:) -> Document?
createBlankDocument(title:category:) -> Document
exportDocument(id:format:) -> String?

// AI Operations
enableAI(configuration:)
continueDocument(documentId:context:) async throws -> String
improveDocument(documentId:context:) async throws -> String
analyzeDocument(documentId:) async throws -> DocumentAnalysis
brainstormIdeas(topic:context:) async throws -> String
```

## AI Integration

```swift
let config = AIConfiguration(
    apiKey: "<your-anthropic-api-key>",
    model: .claude35Sonnet,
    maxTokens: 4096,
    temperature: 0.7
)
```

**API Details:**
- Endpoint: https://api.anthropic.com/v1/messages
- Auth: `x-api-key: <API_KEY>`
- Version: `anthropic-version: 2023-06-01`

## Testing

```bash
swift test  # Run all 1398+ tests
```

**Test Coverage:** Templates, documents, word counts, exports, substitutions, MockerKit

**Security:** Never commit API keys. Use environment variables or CI secret stores.

## Environment Variables

- `ANTHROPIC_API_KEY` — Anthropic API key (required for AI features)

**Security Guidance:**
- Never commit secrets
- Use OS keyring or CI secret store
- Enable secret scanning in CI

## Common Tasks

**Adding a Template:**
1. Edit `Sources/WritersApp/Services/TemplateManager.swift`
2. Add to `loadDefaultTemplates()` with Placeholder structs
3. Update tests in `WritersAppTests/`

**Adding AI Feature:**
1. Add method in `AIService.swift`
2. Create typed error (AIError, AIServiceError)
3. Use `async throws` pattern
4. Test with environment variable API key

## Git Workflow

- Create feature branches: `feature/description`
- Use meaningful commit messages
- Open PRs against main for review
- Squash merge for clean history

## Resources

- See README.md for project overview
- See DATABASE.md for schema details
- See .claude/skills/ for development skills
