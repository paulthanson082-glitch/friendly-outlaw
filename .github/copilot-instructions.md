# GitHub Copilot Instructions for friendly-outlaw

This document provides coding standards, architectural guidelines, and best practices for GitHub Copilot coding agent when working with this Swift-based writers application.

## Project Context

**friendly-outlaw** is a Swift library and CLI application for writers, featuring:
- Template management system
- Document creation and word count tracking
- AI-powered writing assistance (Claude/Anthropic API)
- SQLite-powered persistence and analytics
- Multi-format export capabilities (Markdown, HTML, plain text)
- iPad Pro optimizations with Metal Dashboard

**Key Technologies:**
- Swift 5.9+
- Swift Package Manager (SPM)
- No external dependencies (pure Swift standard library)
- SQLite3 for database operations
- Anthropic Claude API for AI features

## Code Style and Conventions

### Swift Style Guide

1. **Naming Conventions:**
   - Use clear, descriptive names
   - Methods should use verbs: `createDocument()`, `improveText()`, `brainstormIdeas()`
   - Properties should be descriptive nouns: `wordCount`, `characterCount`, `readingTime`
   - All model entities should have a UUID `id` property and conform to `Identifiable`

2. **Code Organization:**
   - Use `// MARK: - Section Name` for organizing code sections
   - Public interfaces at the top, private implementation below
   - Group related functionality together

3. **Type Choices:**
   - Use **structs** for data models: `Document`, `Template`, `AIConfiguration`
   - Use **classes** for services and managers: `WritersApp`, `TemplateManager`, `DocumentManager`, `AIService`
   - Use **enums** for type-safe categories: `TemplateCategory`, `AIModel`, `WritingTone`, `AIAssistanceType`

4. **Protocols:**
   - All models must conform to `Codable` for JSON serialization
   - Use `Identifiable` for entities with unique IDs

### Async/Await Patterns

- All AI operations are `async throws`
- Use proper error handling with typed errors (`AIError`, `AIServiceError`)
- Never use completion handlers or callbacks - this codebase uses modern async/await exclusively

### Template Placeholders

- Format: `{{placeholder_key}}`
- Replaced via utilities in `String+Extensions.swift`
- Always include descriptive labels and validation in `Placeholder` struct

## Architecture Patterns

### Manager Pattern
Services that handle lifecycle and CRUD operations:
- `TemplateManager`: Template operations + 7 default templates
- `DocumentManager`: Document CRUD, search, and statistics
- `DatabaseManager`: SQLite operations for persistence

### Service Pattern
Business logic encapsulation:
- `AIService`: All Anthropic API communication
- `MultitaskingManager`: iPad Pro multitasking support
- `ApplePencilManager`: Apple Pencil integration

### Model Structure
- Data models are immutable structs where possible
- Use computed properties for derived data (e.g., `wordCount`, `readingTime`)
- Metadata stored in dedicated nested structs (`DocumentMetadata`)

## File Organization

```
Sources/WritersApp/
├── Models/           # Data structures (structs, enums)
├── Services/         # Business logic (classes)
├── Views/           # SwiftUI views (iPad Pro specific)
├── Extensions/      # Extension utilities
└── WritersApp.swift # Main entry point
```

**Rules:**
- Models go in `Models/`
- Business logic goes in `Services/`
- UI code goes in `Views/`
- Never mix concerns across directories

## AI Integration Guidelines

### When Adding AI Features

1. Add method to `Sources/WritersApp/Services/AIService.swift`
2. Create clear system prompt and user prompt
3. Add assistance type to `AIAssistanceType` enum in `AIModels.swift`
4. Expose via `WritersApp.swift` main API if needed
5. Add CLI option in `main.swift` if user-facing

### API Configuration
- Endpoint: `https://api.anthropic.com/v1/messages`
- Auth header: `x-api-key`
- Version header: `anthropic-version: 2023-06-01`
- Default model: Claude 3.5 Sonnet
- All AI features are optional - graceful degradation without API key

## Testing Standards

### Test Coverage
Current test suite includes 11 tests covering:
- Template loading and search
- Document creation (from template and blank)
- Word count calculation
- Document manager CRUD
- Export formats
- Statistics generation
- Placeholder substitution

### Writing New Tests
- Use descriptive test names: `testDocumentCreationFromTemplate()`
- Test both success and failure paths
- Don't test implementation details, test behavior
- Keep tests isolated - no dependencies between tests

### Running Tests
```bash
swift test              # Run all tests
swift test --verbose    # Verbose output
```

## Build and Development

### Commands
```bash
# Build
swift build                    # Debug
swift build -c release         # Release

# Test
swift test                     # All tests

# Run CLI
swift run WritersAppCLI
ANTHROPIC_API_KEY="sk-..." swift run WritersAppCLI  # With AI

# Clean
swift package clean
```

### VS Code Integration
Pre-configured tasks (use `Cmd+Shift+B`):
- Swift: Build (default)
- Swift: Build Release
- Swift: Test
- Swift: Clean
- Swift: Run CLI

## Database Operations

When working with SQLite:
- Use `DatabaseManager` service exclusively
- All database code should be in `Services/DatabaseManager.swift`
- Use parameterized queries to prevent SQL injection
- Always handle errors gracefully
- Support pagination for large datasets

## Common Tasks

### Adding a New Template
1. Edit `Sources/WritersApp/Services/TemplateManager.swift`
2. Add to `loadDefaultTemplates()` method
3. Define placeholders with `Placeholder` struct
4. Update tests if needed

### Adding a New Export Format
1. Add case to export format enum
2. Implement conversion in `exportDocument()` method
3. Add test case for new format

### Modifying Models
1. Update struct in `Models/` directory
2. Ensure `Codable` conformance is maintained
3. Update related manager methods
4. Update tests

## Files to Handle with Care

- `Package.swift` - Changes affect build configuration
- `.vscode/` - VS Code settings for cross-device development
- `Tests/` - Ensure tests pass after changes
- `CLAUDE.md` - Keep synchronized with Copilot instructions

## Security Guidelines

- Never commit API keys or secrets to source code
- Environment variables for sensitive data: `ANTHROPIC_API_KEY`
- Validate all user input before processing
- Use parameterized SQL queries
- All dates use ISO 8601 format for consistent serialization

## Documentation

- Keep `README.md` updated with user-facing features
- Keep `CLAUDE.md` updated with AI assistant context
- Update `DATABASE.md` for database schema changes
- Keep this file synchronized with coding standards

## Platform Support

- Primary: macOS 13+, iOS 16+
- Linux supported with SQLite3 dev libraries
- iPad Pro optimizations available (Metal Dashboard)
- CLI works cross-platform

## Dependencies Philosophy

- **Zero external dependencies** - uses Swift standard library only
- SQLite3 is system-provided (not a package dependency)
- Keep it simple and maintainable
- Only add dependencies if absolutely necessary and justify in PR

## Git Workflow

- Feature branches with descriptive names
- Keep commits focused and well-described
- Tests must pass before merging
- PRs should be reviewable (not too large)

## When in Doubt

1. Check existing code for patterns
2. Review `CLAUDE.md` for detailed API documentation
3. Run tests to verify changes: `swift test`
4. Keep changes minimal and focused
5. Maintain consistency with existing codebase
