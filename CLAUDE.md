# CLAUDE.md - AI Assistant Guide for friendly-outlaw

> **Last Updated:** 2026-01-18
> **Repository:** friendly-outlaw (Writers App with Templates)
> **Primary Language:** Swift 5.9+
> **Platforms:** macOS 13+, iOS 16+

## Table of Contents

1. [Repository Overview](#repository-overview)
2. [Codebase Structure](#codebase-structure)
3. [Development Environment](#development-environment)
4. [Code Architecture](#code-architecture)
5. [Coding Conventions](#coding-conventions)
6. [Development Workflows](#development-workflows)
7. [Git Conventions](#git-conventions)
8. [Testing Strategy](#testing-strategy)
9. [Common AI Assistant Tasks](#common-ai-assistant-tasks)
10. [File Locations Reference](#file-locations-reference)
11. [Important Context](#important-context)

---

## Repository Overview

### Project Purpose

**friendly-outlaw** is a Swift-based writing application that provides:
- Template-based document creation (novels, short stories, screenplays, blog posts, etc.)
- Document management with metadata tracking
- AI-powered writing assistance (optional, via Anthropic Claude API)
- Export capabilities (Markdown, HTML, Plain Text)
- CLI and library interfaces

### Personal Context

The repository name "friendly-outlaw" is a remembrance name used by the owner and their father. This is a personal project with sentimental value.

### Key Technologies

- **Language:** Swift 5.9+
- **Build System:** Swift Package Manager (SPM)
- **Platforms:** macOS 13+, iOS 16+
- **AI Integration:** Anthropic Claude API (optional)
- **Development Tools:** VS Code with Swift extensions

### Project Stats

- **Total Swift Code:** ~1,425 lines
- **Main Components:** 9 Swift source files
- **Test Files:** Comprehensive unit tests included
- **Documentation:** README.md, VSCODE_SETUP.md, and this CLAUDE.md

---

## Codebase Structure

```
friendly-outlaw/
├── .vscode/                      # VS Code workspace configuration
│   ├── settings.json             # Editor and Swift settings
│   ├── tasks.json                # Build, test, run tasks
│   ├── launch.json               # Debug configurations
│   └── extensions.json           # Recommended extensions
├── Sources/
│   ├── WritersApp/               # Main library code
│   │   ├── Models/               # Data structures
│   │   │   ├── Template.swift    # Template data model
│   │   │   ├── Document.swift    # Document data model
│   │   │   └── AIModels.swift    # AI configuration & types
│   │   ├── Services/             # Business logic
│   │   │   ├── TemplateManager.swift  # Template CRUD
│   │   │   ├── DocumentManager.swift  # Document CRUD
│   │   │   └── AIService.swift        # AI assistance
│   │   ├── Extensions/           # Swift extensions
│   │   │   └── String+Extensions.swift
│   │   └── WritersApp.swift      # Main app facade
│   └── WritersAppCLI/            # CLI executable
│       └── main.swift            # Command-line interface
├── Tests/
│   └── WritersAppTests/
│       └── WritersAppTests.swift # Unit tests
├── Package.swift                 # SPM package definition
├── .gitignore                    # Git ignore rules
├── LICENSE                       # MIT License
├── README.md                     # User-facing documentation
├── VSCODE_SETUP.md              # VS Code setup guide
└── CLAUDE.md                     # This file (AI assistant guide)
```

### Directory Purposes

| Directory | Purpose |
|-----------|---------|
| `Sources/WritersApp/` | Core library code, can be imported as a Swift package |
| `Sources/WritersAppCLI/` | Command-line interface implementation |
| `Tests/` | Unit tests for all functionality |
| `.vscode/` | VS Code workspace settings (synced across devices) |

---

## Development Environment

### System Requirements

- **Swift:** 5.9 or later
- **macOS:** 13+ (for macOS builds)
- **iOS:** 16+ (for iOS builds)
- **Editor:** VS Code with Swift extensions (recommended)
- **Optional:** Anthropic API key for AI features

### VS Code Setup

The project includes complete VS Code configuration for cross-device development (MacBook Pro + iPad). See [VSCODE_SETUP.md](VSCODE_SETUP.md) for detailed setup.

#### Essential Extensions

```json
{
  "recommendations": [
    "vknabel.vscode-swift-development-environment",
    "sswg.swift-lang",
    "eamodio.gitlens",
    "usernamehw.errorlens",
    "streetsidesoftware.code-spell-checker",
    "gruntfuggly.todo-tree"
  ]
}
```

#### Editor Settings

- **Tab Size:** 4 spaces (Swift convention)
- **Format on Save:** Enabled
- **Line Length:** 80/120 character rulers
- **Word Wrap:** On
- **Swift Path:** `/usr/bin/swift` (adjust per environment)

### Quick Start Commands

```bash
# Build the project
swift build

# Run tests
swift test

# Run CLI application
swift run WritersAppCLI

# Build release version
swift build -c release

# Clean build artifacts
swift package clean

# Update dependencies
swift package update
```

### VS Code Tasks

Use `Cmd+Shift+P` → "Tasks: Run Task" or `Cmd+Shift+B` for default build:

- **Swift: Build** (default) - Build debug version
- **Swift: Build Release** - Build optimized version
- **Swift: Test** - Run test suite
- **Swift: Run CLI** - Launch CLI application
- **Swift: Clean** - Remove build artifacts
- **Swift: Update Dependencies** - Update package dependencies

---

## Code Architecture

### Design Patterns

The application follows a **layered architecture** with clear separation of concerns:

```
┌─────────────────────────────────────┐
│   WritersApp (Facade)               │  ← Main entry point
├─────────────────────────────────────┤
│   TemplateManager  DocumentManager  │  ← Service layer
│   AIService (optional)              │
├─────────────────────────────────────┤
│   Template  Document  AIModels      │  ← Data models
├─────────────────────────────────────┤
│   String+Extensions                 │  ← Utilities
└─────────────────────────────────────┘
```

### Key Classes/Structs

#### WritersApp (Sources/WritersApp/WritersApp.swift)

**Purpose:** Main facade providing unified API
**Responsibilities:**
- Initialize managers
- Coordinate between services
- Provide high-level operations
- Manage AI service lifecycle

```swift
public class WritersApp {
    public let templateManager: TemplateManager
    public let documentManager: DocumentManager
    public private(set) var aiService: AIService?

    // Key methods:
    // - createDocumentFromTemplate(templateId:values:)
    // - createBlankDocument(title:category:)
    // - exportDocument(id:format:)
    // - enableAI(configuration:)
}
```

#### TemplateManager (Sources/WritersApp/Services/TemplateManager.swift)

**Purpose:** Manage writing templates
**Responsibilities:**
- CRUD operations for templates
- Template search and filtering
- Built-in template library

#### DocumentManager (Sources/WritersApp/Services/DocumentManager.swift)

**Purpose:** Manage documents
**Responsibilities:**
- CRUD operations for documents
- Word count tracking
- Document search
- Statistics generation

#### AIService (Sources/WritersApp/Services/AIService.swift)

**Purpose:** AI-powered writing assistance
**Responsibilities:**
- Integration with Claude API
- Text generation and improvement
- Grammar checking
- Style suggestions
- Character development
- Outline generation

### Data Models

#### Template (Sources/WritersApp/Models/Template.swift)

```swift
public struct Template: Codable, Identifiable {
    public let id: UUID
    public let name: String
    public let category: TemplateCategory
    public let content: String
    public let placeholders: [Placeholder]
    public let metadata: TemplateMetadata
}
```

**Key Features:**
- Placeholder system for dynamic content (`{{key}}` syntax)
- Categories: Novel, Short Story, Screenplay, Blog Post, Article, Poetry, etc.
- Built-in templates provided by TemplateManager

#### Document (Sources/WritersApp/Models/Document.swift)

```swift
public struct Document: Codable, Identifiable {
    public let id: UUID
    public var title: String
    public var content: String
    public let category: TemplateCategory
    public var metadata: DocumentMetadata

    // Computed properties:
    public var wordCount: Int
    public var characterCount: Int
    public var estimatedReadingTime: TimeInterval
}
```

**Key Features:**
- Automatic word/character counting
- Reading time estimation
- Creation/modification timestamps
- Optional word count goals
- Tag support

---

## Coding Conventions

### Swift Style Guide

This project follows standard Swift conventions as per [Swift.org style guide](https://swift.org/documentation/api-design-guidelines/).

#### Naming Conventions

```swift
// Types: UpperCamelCase
class WritersApp { }
struct Document { }
enum TemplateCategory { }

// Properties, methods, variables: lowerCamelCase
var wordCount: Int
func createDocument() -> Document

// Constants: lowerCamelCase (not SCREAMING_SNAKE_CASE)
let maxDocumentLength = 1_000_000

// Private properties: use private(set) when appropriate
public private(set) var aiService: AIService?
```

#### Access Control

- **public:** API surface (most of WritersApp, managers, models)
- **internal:** Default for implementation details
- **private:** Class-specific implementation

#### Code Organization

1. **Properties** (grouped by access level)
2. **Initializers**
3. **Public methods**
4. **Internal methods**
5. **Private methods**

Use `// MARK: -` comments to separate sections:

```swift
// MARK: - Properties

// MARK: - Initialization

// MARK: - Public Methods

// MARK: - Private Methods
```

#### Documentation

Use Swift documentation comments for public APIs:

```swift
/// Creates a new document from a template
/// - Parameters:
///   - templateId: The UUID of the template to use
///   - values: Dictionary of placeholder values
/// - Returns: The created document, or nil if template not found
public func createDocumentFromTemplate(
    templateId: UUID,
    values: [String: String]
) -> Document?
```

#### Error Handling

- Use Swift's error handling (`throws`, `try`, `catch`)
- AI service methods are `async throws`
- Return `nil` for optional results when appropriate
- Avoid force unwrapping (`!`) in production code

#### Formatting

- **Indentation:** 4 spaces (no tabs)
- **Line Length:** Prefer under 80 characters, max 120
- **Trailing Commas:** Use in multi-line arrays/dictionaries
- **Brace Style:** Opening brace on same line

```swift
// Good
func createDocument(
    title: String,
    content: String
) -> Document {
    // Implementation
}

// Avoid
func createDocument(title: String, content: String) -> Document
{
    // Implementation
}
```

---

## Development Workflows

### Standard Development Cycle

1. **Pull latest changes**
   ```bash
   git pull origin main
   ```

2. **Create feature branch**
   ```bash
   git checkout -b claude/feature-description-XXXXX
   ```
   > Note: Branch names MUST start with `claude/` for CI/CD

3. **Make changes**
   - Edit code in VS Code
   - Use tasks (`Cmd+Shift+B`) to build
   - Run tests frequently (`swift test`)

4. **Test your changes**
   ```bash
   swift test
   swift run WritersAppCLI  # Manual testing
   ```

5. **Commit changes**
   ```bash
   git add .
   git commit -m "Add feature X"
   ```

6. **Push to remote**
   ```bash
   git push -u origin claude/feature-description-XXXXX
   ```

### Cross-Device Development (iPad + MacBook)

This project supports seamless development across devices:

1. **Settings Sync:** VS Code settings sync enabled
2. **Frequent Commits:** Commit often to sync work
3. **Branch Workflow:** Use feature branches
4. **iPad Options:**
   - Native VS Code app (editing only)
   - Remote SSH to MacBook (full development)
   - GitHub Codespaces (cloud development)
   - vscode.dev (web-based editing)

See [VSCODE_SETUP.md](VSCODE_SETUP.md) for detailed iPad setup.

### AI Features Development

When working with AI features:

1. **Set API Key** (environment variable)
   ```bash
   export ANTHROPIC_API_KEY="your-key-here"
   ```

2. **API Key in Code** (for testing)
   ```swift
   let config = AIConfiguration(
       apiKey: "your-key",
       model: .claude35Sonnet,
       temperature: 0.7
   )
   let app = WritersApp(aiConfiguration: config)
   ```

3. **Test AI Features**
   - AI features are completely optional
   - App should work fully without AI
   - Always handle `aiService == nil` gracefully

---

## Git Conventions

### Branch Naming

**CRITICAL:** All feature branches MUST follow this pattern:

```
claude/<description>-<session-id>
```

Examples:
- `claude/add-export-feature-Ab3Dx`
- `claude/fix-word-count-bug-Zy9Qm`
- `claude/update-templates-Lk4Tp`

**Why:** The CI/CD system requires `claude/` prefix and session ID suffix.

### Commit Messages

Follow conventional commit format:

```
<type>: <subject>

<optional body>

<optional footer>
```

**Types:**
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `refactor:` Code refactoring
- `test:` Test additions/changes
- `chore:` Build/tooling changes

**Examples:**

```
feat: Add poetry template with stanza support

Added a new poetry template that supports:
- Multiple stanzas
- Dedication field
- Author attribution

Closes #42
```

```
fix: Correct word count calculation for documents with special characters

The word count was incorrectly counting hyphenated words as multiple words.
Updated the regex pattern to handle edge cases.
```

```
docs: Update README with AI feature examples

Added code examples showing how to:
- Enable AI features
- Generate title suggestions
- Analyze documents
```

### Push Protocol

**ALWAYS use:**

```bash
git push -u origin <branch-name>
```

**Retry on Network Failures:**

If push fails due to network errors, retry up to 4 times with exponential backoff:
- 1st retry: wait 2 seconds
- 2nd retry: wait 4 seconds
- 3rd retry: wait 8 seconds
- 4th retry: wait 16 seconds

### Pull Request Workflow

When creating PRs (typically done by AI assistants):

1. **Ensure branch is pushed**
   ```bash
   git push -u origin claude/feature-name-XXXXX
   ```

2. **Create PR with `gh` CLI**
   ```bash
   gh pr create --title "Add feature X" --body "Description..."
   ```

3. **PR Body Format:**
   ```markdown
   ## Summary
   - Bullet point overview of changes
   - Key improvements or fixes

   ## Test Plan
   - [ ] Ran `swift test` successfully
   - [ ] Manual testing of feature X
   - [ ] Verified on both debug and release builds
   ```

---

## Testing Strategy

### Test Location

All tests are in `Tests/WritersAppTests/WritersAppTests.swift`

### Running Tests

```bash
# Run all tests
swift test

# Run with verbose output
swift test --verbose

# Run specific test
swift test --filter testTemplateFunctionality
```

### Test Coverage Areas

Current tests cover:
- Template creation and management
- Document creation from templates
- Word count calculations
- Search functionality
- Export functionality (Markdown, HTML, plain text)
- Statistics generation

### Writing New Tests

Follow the existing test structure:

```swift
import XCTest
@testable import WritersApp

final class WritersAppTests: XCTestCase {
    var app: WritersApp!

    override func setUp() {
        super.setUp()
        app = WritersApp()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    func testYourFeature() {
        // Arrange
        let template = app.templateManager.getAllTemplates().first!

        // Act
        let document = app.createDocumentFromTemplate(
            templateId: template.id,
            values: ["title": "Test"]
        )

        // Assert
        XCTAssertNotNil(document)
        XCTAssertEqual(document?.title, "Test")
    }
}
```

### Test Best Practices

1. **Arrange-Act-Assert** pattern
2. **Descriptive test names** (`testWordCountCalculationWithSpecialCharacters`)
3. **Test one thing** per test method
4. **Clean up** in `tearDown()`
5. **Mock external dependencies** (especially AI service)
6. **Don't test implementation details**, test behavior

---

## Common AI Assistant Tasks

### Task 1: Adding a New Template

**Files to modify:**
- `Sources/WritersApp/Services/TemplateManager.swift`

**Steps:**
1. Add new case to `TemplateCategory` enum (if needed)
2. Create template in `TemplateManager.setupDefaultTemplates()`
3. Define placeholders
4. Add template content with `{{placeholder}}` syntax
5. Update tests
6. Update README.md documentation

**Example:**
```swift
// In TemplateManager.swift
let emailTemplate = Template(
    name: "Professional Email",
    category: .businessLetter,
    description: "Professional email template",
    content: """
    Subject: {{subject}}

    Dear {{recipient}},

    {{body}}

    Best regards,
    {{sender}}
    """,
    placeholders: [
        Placeholder(key: "subject", label: "Email Subject"),
        Placeholder(key: "recipient", label: "Recipient Name"),
        Placeholder(key: "body", label: "Email Body"),
        Placeholder(key: "sender", label: "Your Name")
    ]
)
templates.append(emailTemplate)
```

### Task 2: Adding AI Features

**Files to modify:**
- `Sources/WritersApp/Services/AIService.swift`
- `Sources/WritersApp/WritersApp.swift` (if adding facade method)
- `Sources/WritersApp/Models/AIModels.swift` (if adding new types)

**Steps:**
1. Add method to `AIService`
2. Use async/await pattern
3. Handle errors appropriately
4. Add corresponding facade method to `WritersApp` if public API
5. Update tests (mock AI responses)
6. Update README.md with usage examples

### Task 3: Adding Export Formats

**Files to modify:**
- `Sources/WritersApp/WritersApp.swift`
- `Sources/WritersApp/Models/Document.swift` (if adding ExportFormat enum case)

**Steps:**
1. Add new case to `ExportFormat` enum
2. Implement export logic in `WritersApp.exportDocument()`
3. Create private helper method for format conversion
4. Add tests for new format
5. Update README.md

### Task 4: Fixing Bugs

**Process:**
1. **Reproduce:** Write a failing test that demonstrates the bug
2. **Locate:** Use test results to identify problematic code
3. **Fix:** Make minimal changes to fix the issue
4. **Verify:** Ensure test passes, run full test suite
5. **Document:** Update comments/docs if behavior changed
6. **Commit:** Use `fix:` commit message

### Task 5: Refactoring Code

**Guidelines:**
- **Tests first:** Ensure good test coverage before refactoring
- **Small steps:** Make incremental changes
- **Verify often:** Run tests after each step
- **Preserve behavior:** Don't change functionality while refactoring
- **Commit frequently:** Each successful refactor step

### Task 6: Documentation Updates

**Files that need updates:**
- `README.md` - User-facing documentation
- `VSCODE_SETUP.md` - Development setup
- `CLAUDE.md` - This file (AI assistant guide)
- Inline Swift documentation comments

**When to update:**
- New features added
- API changes
- New templates or categories
- Development process changes
- Bug fixes that affect usage

---

## File Locations Reference

### Quick Reference Guide

| Need to... | File(s) to Check |
|------------|------------------|
| Add/modify templates | `Sources/WritersApp/Services/TemplateManager.swift` |
| Change document structure | `Sources/WritersApp/Models/Document.swift` |
| Add AI features | `Sources/WritersApp/Services/AIService.swift` |
| Modify CLI interface | `Sources/WritersAppCLI/main.swift` |
| Add string utilities | `Sources/WritersApp/Extensions/String+Extensions.swift` |
| Update VS Code tasks | `.vscode/tasks.json` |
| Configure editor | `.vscode/settings.json` |
| Add tests | `Tests/WritersAppTests/WritersAppTests.swift` |
| Update dependencies | `Package.swift` |
| Document features | `README.md` |
| Development setup | `VSCODE_SETUP.md` |
| AI assistant guidance | `CLAUDE.md` (this file) |

### Configuration Files

| File | Purpose | When to Modify |
|------|---------|----------------|
| `Package.swift` | Swift Package Manager configuration | Adding dependencies, changing platform requirements |
| `.vscode/settings.json` | Editor settings | Changing Swift path, editor preferences |
| `.vscode/tasks.json` | Build/test tasks | Adding new build configurations |
| `.vscode/launch.json` | Debug configurations | Changing debug settings |
| `.vscode/extensions.json` | Recommended extensions | Adding/removing VS Code extensions |
| `.gitignore` | Git ignore rules | Excluding new file types |

---

## Important Context

### What AI Assistants Should Know

#### 1. This is a Personal Project

- Named after a phrase used with the owner's father (sentimental value)
- Be respectful when making changes
- Document everything clearly
- Don't make unnecessary breaking changes

#### 2. AI Features are Optional

- The app MUST work fully without AI features enabled
- Always check `aiService != nil` before using AI
- Don't make AI features mandatory
- Provide graceful degradation

#### 3. Cross-Platform Considerations

- Code must work on both macOS and iOS
- Use Foundation framework (cross-platform)
- Avoid platform-specific APIs unless necessary
- Test on target platforms

#### 4. Performance Matters

- Document operations should be fast (in-memory)
- Word count is computed property (cached when needed)
- Search should be efficient even with many documents
- AI calls are async (don't block main thread)

#### 5. Swift Package Manager

- No external dependencies currently (except Foundation)
- Keep it lightweight
- If adding dependencies, justify in PR
- Update `Package.swift` properly

#### 6. VS Code Workflow

- Users develop on iPad + MacBook
- Settings sync is enabled
- Some extensions may not work on iPad
- Remote SSH is used for full iPad development

#### 7. Code Quality

- Run tests before committing
- Format on save is enabled
- Spell checker will catch typos
- Error Lens shows inline errors
- Keep code simple and readable

### Common Pitfalls to Avoid

#### ❌ DON'T

1. **Force unwrap optionals** - Use guard/if let instead
2. **Skip tests** - Always verify changes with tests
3. **Push to wrong branch** - Must use `claude/` prefix
4. **Break AI-optional design** - App must work without AI
5. **Ignore build warnings** - Fix warnings promptly
6. **Make unnecessary abstractions** - Keep it simple
7. **Skip documentation** - Update README when adding features
8. **Commit commented-out code** - Remove dead code
9. **Use platform-specific APIs** - Stay cross-platform
10. **Hardcode API keys** - Use environment variables

#### ✅ DO

1. **Use guard statements** for early returns
2. **Write tests first** for bug fixes
3. **Follow branch naming** convention
4. **Handle nil gracefully** for optional AI service
5. **Run swift test** before committing
6. **Use MARK comments** to organize code
7. **Update documentation** when changing APIs
8. **Clean up imports** (remove unused)
9. **Use Foundation APIs** for cross-platform
10. **Store secrets securely** (env vars, keychain)

### API Key Management

**For Development:**
```bash
# MacBook: Add to ~/.zshrc or ~/.bash_profile
export ANTHROPIC_API_KEY="sk-ant-..."

# iPad/SSH: Set before running
ANTHROPIC_API_KEY="sk-ant-..." swift run WritersAppCLI
```

**For Production:**
- NEVER commit API keys to git
- Use environment variables
- Consider keychain storage on macOS/iOS
- Document key setup in README

### Useful Commands Cheat Sheet

```bash
# Building
swift build                    # Debug build
swift build -c release         # Release build
swift build --show-bin-path    # Show binary location

# Testing
swift test                     # Run all tests
swift test --parallel          # Run tests in parallel
swift test --verbose           # Detailed output

# Running
swift run WritersAppCLI        # Run CLI
.build/debug/WritersAppCLI     # Run built binary

# Package Management
swift package clean            # Clean build artifacts
swift package update           # Update dependencies
swift package resolve          # Resolve dependencies
swift package reset            # Reset package state

# Git
git status                     # Check status
git log --oneline -10          # Recent commits
git branch -a                  # List all branches
git checkout -b claude/fix-XYZ # Create feature branch
git push -u origin branch-name # Push with tracking

# VS Code Tasks (from Command Palette)
Cmd+Shift+B                    # Default build
Cmd+Shift+P → Tasks: Run Task  # All tasks
```

---

## Conclusion

This guide provides AI assistants with comprehensive context about the friendly-outlaw repository. When working on this codebase:

1. **Understand the architecture** - Layered design with clear separation
2. **Follow conventions** - Swift style guide, naming, formatting
3. **Test thoroughly** - Write tests, run tests, verify manually
4. **Document changes** - Update README, inline docs, commit messages
5. **Respect the git workflow** - Branch naming, commit format, push protocol
6. **Keep AI optional** - Never make AI features mandatory
7. **Think cross-platform** - macOS + iOS compatibility
8. **Be respectful** - This is a personal project with sentimental value

### Getting Help

- **Swift Documentation:** [swift.org/documentation](https://swift.org/documentation/)
- **Swift Package Manager:** [swift.org/package-manager](https://swift.org/package-manager/)
- **VS Code Swift Extension:** Check extension marketplace
- **Anthropic Claude API:** [docs.anthropic.com](https://docs.anthropic.com)

### Questions to Ask When Uncertain

1. Does this change maintain backward compatibility?
2. Will this work without AI features enabled?
3. Is this cross-platform (macOS + iOS)?
4. Have I updated the relevant documentation?
5. Do the tests cover this change?
6. Is the commit message descriptive?
7. Am I following the branch naming convention?
8. Have I run `swift test` successfully?

---

**Remember:** The goal is to maintain a high-quality, well-documented, and maintainable codebase that honors the personal nature of this project while providing excellent functionality to users.

Happy coding! 🚀
