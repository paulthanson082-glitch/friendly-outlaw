# CLAUDE.md - AI Assistant Guide for WritersApp

> **Repository**: friendly-outlaw
> **Project Type**: Swift Package (Library + CLI)
> **Purpose**: Comprehensive writing application with template management, document creation, and AI-powered writing assistance
> **Platform**: macOS 13+, iOS 16+
> **Swift Version**: 5.9+

---

## 📋 Table of Contents

1. [Repository Overview](#repository-overview)
2. [Codebase Structure](#codebase-structure)
3. [Architecture & Design](#architecture--design)
4. [Key Components](#key-components)
5. [Development Workflows](#development-workflows)
6. [Testing Strategy](#testing-strategy)
7. [Coding Conventions](#coding-conventions)
8. [Common Tasks](#common-tasks)
9. [AI Integration](#ai-integration)
10. [Important Notes for AI Assistants](#important-notes-for-ai-assistants)

---

## 🎯 Repository Overview

### Purpose
WritersApp is a Swift-based writing application that provides:
- Template-based document creation (7+ professional templates)
- Document management with metadata tracking
- Word count, character count, and reading time analytics
- Export functionality (Markdown, HTML, Plain Text)
- Optional AI-powered writing assistance via Claude API
- Both library and CLI interfaces

### Project Sentiment
The repository name "friendly-outlaw" is a personal tribute - a name the developer and their father used together. Treat this codebase with respect for its sentimental value.

---

## 📁 Codebase Structure

```
friendly-outlaw/
├── Package.swift                    # Swift Package Manager configuration
├── README.md                        # User-facing documentation
├── LICENSE                          # MIT License
├── .gitignore                       # Git ignore rules
├── CLAUDE.md                        # This file - AI assistant guide
│
├── Sources/
│   ├── WritersApp/                  # Main library target
│   │   ├── WritersApp.swift         # Main app class, orchestrates all features
│   │   │
│   │   ├── Models/                  # Data structures and domain models
│   │   │   ├── Template.swift       # Template, TemplateCategory, Placeholder
│   │   │   ├── Document.swift       # Document, DocumentMetadata
│   │   │   └── AIModels.swift       # AI configuration, types, prompts
│   │   │
│   │   ├── Services/                # Business logic and operations
│   │   │   ├── TemplateManager.swift    # CRUD for templates
│   │   │   ├── DocumentManager.swift    # CRUD for documents
│   │   │   └── AIService.swift          # Claude API integration
│   │   │
│   │   └── Extensions/
│   │       └── String+Extensions.swift  # String utility methods
│   │
│   └── WritersAppCLI/               # Executable CLI target
│       └── main.swift               # Interactive command-line interface
│
└── Tests/
    └── WritersAppTests/
        └── WritersAppTests.swift    # Unit tests for core functionality
```

### File Responsibilities

| File | Primary Responsibility | Key Types |
|------|------------------------|-----------|
| `WritersApp.swift` | Main orchestrator, public API | `WritersApp`, `AppStatistics`, `ExportFormat`, `AIError` |
| `Template.swift` | Template data model | `Template`, `TemplateCategory`, `Placeholder`, `TemplateMetadata` |
| `Document.swift` | Document data model | `Document`, `DocumentMetadata` |
| `AIModels.swift` | AI configuration & types | `AIConfiguration`, `AIModel`, `AIAssistanceType`, `WritingTone`, `AIContext`, `AIResponse` |
| `TemplateManager.swift` | Template CRUD operations | `TemplateManager` |
| `DocumentManager.swift` | Document CRUD operations | `DocumentManager` |
| `AIService.swift` | Claude API integration | `AIService` |
| `main.swift` | CLI interface | N/A (executable) |

---

## 🏗️ Architecture & Design

### Design Patterns

**1. Facade Pattern**
- `WritersApp` acts as a facade, providing a simple interface to complex subsystems
- Coordinates `TemplateManager`, `DocumentManager`, and optional `AIService`

**2. Manager Pattern**
- `TemplateManager` and `DocumentManager` handle CRUD operations for their respective domains
- Encapsulate storage logic (currently in-memory, easily replaceable with persistence)

**3. Service Pattern**
- `AIService` encapsulates all AI-related functionality
- Isolated from core business logic, making AI features truly optional

**4. Value Types**
- Models use structs (`Template`, `Document`, `AIConfiguration`, etc.)
- Immutable by default, with explicit mutability where needed (`var content: String` in `Document`)

### Dependency Flow

```
┌─────────────────────────────────────────────────┐
│             WritersApp (Facade)                 │
│  - Coordinates all subsystems                   │
│  - Public API                                   │
└─────────────────────────────────────────────────┘
         │           │              │
         ▼           ▼              ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│ Template     │ │ Document     │ │ AIService    │
│ Manager      │ │ Manager      │ │ (Optional)   │
└──────────────┘ └──────────────┘ └──────────────┘
         │           │              │
         ▼           ▼              ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│ Template     │ │ Document     │ │ AIModels     │
│ Models       │ │ Models       │ │ & Config     │
└──────────────┘ └──────────────┘ └──────────────┘
```

### Data Flow

**Creating Document from Template:**
1. User calls `WritersApp.createDocumentFromTemplate(templateId:values:)`
2. WritersApp retrieves template via `TemplateManager.getTemplate(id:)`
3. Template generates document via `Template.createDocument(with:)`
4. Document saved via `DocumentManager.createDocument(_:)`

**AI-Powered Writing:**
1. User calls `WritersApp.continueDocument(documentId:context:appendToDocument:)`
2. WritersApp checks if `aiService` is enabled (throws `AIError.aiNotEnabled` if not)
3. Document retrieved via `DocumentManager.getDocument(id:)`
4. Content passed to `AIService.continueWriting(text:context:)`
5. AIService makes API call to Claude
6. If `appendToDocument: true`, updates document via `DocumentManager.updateDocument(_:)`

---

## 🔑 Key Components

### WritersApp (Main Class)

**Location**: `Sources/WritersApp/WritersApp.swift`

**Responsibilities**:
- Main entry point for all library functionality
- Manages lifecycle of TemplateManager, DocumentManager, and AIService
- Provides high-level API for document and template operations
- Handles AI feature enablement/disablement
- Exports documents to various formats

**Key Methods**:
```swift
// Document Creation
createDocumentFromTemplate(templateId:values:) -> Document?
createBlankDocument(title:category:) -> Document

// Export
exportDocument(id:format:) -> String?

// AI Features
enableAI(configuration:)
disableAI()
continueDocument(documentId:context:appendToDocument:) async throws -> String
improveDocument(documentId:context:replaceContent:) async throws -> String
generateDocumentTitles(documentId:context:) async throws -> [String]
analyzeDocument(documentId:) async throws -> DocumentAnalysis
brainstormIdeas(topic:context:) async throws -> String
generateOutline(concept:context:) async throws -> String
developCharacter(characterConcept:context:) async throws -> String

// Statistics
getStatistics() -> AppStatistics
```

### TemplateManager

**Location**: `Sources/WritersApp/Services/TemplateManager.swift`

**Responsibilities**:
- CRUD operations for templates
- Template search and filtering
- Pre-loaded with 7 default templates

**Storage**: In-memory array (consider persistence for future enhancement)

**Default Templates**:
1. Novel Chapter
2. Short Story (three-act structure)
3. Screenplay Scene
4. Blog Post (SEO-optimized)
5. Article (research format)
6. Poetry
7. Business Letter

### DocumentManager

**Location**: `Sources/WritersApp/Services/DocumentManager.swift`

**Responsibilities**:
- CRUD operations for documents
- Document search (title and content)
- Filtering by category
- Word count aggregation
- Recent document tracking

**Storage**: In-memory dictionary (UUID -> Document mapping)

### AIService

**Location**: `Sources/WritersApp/Services/AIService.swift`

**Responsibilities**:
- Claude API integration
- Prompt construction and management
- Multiple AI assistance types (continue writing, improve text, grammar check, etc.)
- Document analysis and insights
- Error handling for API calls

**API Details**:
- Uses Anthropic Messages API
- Supports multiple Claude models (3 Haiku, 3 Sonnet, 3 Opus, 3.5 Sonnet)
- Default model: `claude-3-5-sonnet-20241022`
- Configurable temperature and max tokens

---

## 🔄 Development Workflows

### Building the Project

```bash
# Build for development
swift build

# Build for release (optimized)
swift build -c release

# Run CLI
swift run WritersAppCLI

# Run CLI with AI features
ANTHROPIC_API_KEY="your-key" swift run WritersAppCLI
```

### Running Tests

```bash
# Run all tests
swift test

# Run tests with verbose output
swift test --verbose

# Run specific test
swift test --filter WritersAppTests
```

### Git Workflow

**Current Branch**: `claude/add-claude-documentation-kfhIp`

**Important Git Conventions**:
- Feature branches follow pattern: `claude/<description>-<sessionId>`
- Always commit to designated feature branch
- Use descriptive commit messages
- Push with: `git push -u origin <branch-name>`

**Recent Commits**:
```
88c75cf Merge pull request #1
1888518 Add AI-powered writing assistant features to Writers App
39253aa Add comprehensive Writers App with templates in Swift
13e6fc0 Initial commit
```

### Adding New Features

**When adding a new template:**
1. Define placeholders in `TemplateManager.createDefaultTemplates()`
2. Write template content with `{{placeholder_key}}` syntax
3. Ensure category exists in `TemplateCategory` enum
4. Add tests for template creation and placeholder replacement

**When adding a new AI feature:**
1. Add case to `AIAssistanceType` enum in `AIModels.swift`
2. Implement prompt generation in `AIAssistanceType.prompt(for:context:)`
3. Add method to `AIService` if needed
4. Add high-level method to `WritersApp` for easy access
5. Update CLI menu if exposing to CLI users

**When adding a new export format:**
1. Add case to `ExportFormat` enum in `WritersApp.swift`
2. Implement export method (e.g., `exportAsPDF(_:)`)
3. Add switch case in `exportDocument(id:format:)`

---

## 🧪 Testing Strategy

**Location**: `Tests/WritersAppTests/WritersAppTests.swift`

### Current Test Coverage

Tests cover:
- ✅ Template creation and retrieval
- ✅ Document creation from templates
- ✅ Blank document creation
- ✅ Word count calculations
- ✅ Search functionality (templates and documents)
- ✅ Export formats (Markdown, HTML, Plain Text)
- ✅ Statistics generation
- ✅ Placeholder substitution

### Not Currently Tested

- ❌ AI service integration (requires API key and live calls)
- ❌ Error handling edge cases
- ❌ Concurrent access to managers
- ❌ CLI interface

### Testing Conventions

**Test Naming**: `test<Feature><Scenario>()`
- Example: `testCreateDocumentFromTemplate()`
- Example: `testSearchDocuments()`

**Test Structure**:
1. Setup (create app, templates, documents)
2. Exercise (call method being tested)
3. Assert (verify expected outcomes)
4. Optional: Cleanup (not needed for value types)

### Adding New Tests

```swift
func testNewFeature() throws {
    // Setup
    let app = WritersApp()

    // Exercise
    let result = app.someMethod()

    // Assert
    XCTAssertNotNil(result)
    XCTAssertEqual(result.property, expectedValue)
}
```

---

## 📐 Coding Conventions

### Swift Style

**1. Access Control**
- Use `public` for library API
- Use `private` for implementation details
- Use `private(set)` for readable but immutable properties

**2. Type Naming**
- Types: `PascalCase` (e.g., `WritersApp`, `TemplateManager`)
- Properties/Methods: `camelCase` (e.g., `templateManager`, `createDocument`)
- Enums: `PascalCase` for type, `camelCase` for cases (e.g., `TemplateCategory.shortStory`)

**3. Optionals**
- Prefer `guard let` for early returns
- Use `if let` for optional binding in non-guard scenarios
- Avoid force unwrapping (`!`) except in tests or when truly guaranteed

**4. Error Handling**
- Use custom error enums (e.g., `AIError`)
- Conform to `LocalizedError` for user-friendly messages
- Use `throws` for recoverable errors
- Use `async throws` for asynchronous operations that can fail

**5. Comments**
- Use `///` for documentation comments
- Use `// MARK: -` to organize code sections
- Avoid redundant comments; code should be self-documenting

### Code Organization

**File Structure**:
```swift
import Foundation

// MARK: - Main Types

public struct MyType {
    // Properties first
    public let id: UUID
    public var name: String

    // Initializers
    public init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }

    // Computed properties
    public var displayName: String {
        return name.uppercased()
    }

    // Methods
    public func doSomething() {
        // Implementation
    }
}

// MARK: - Supporting Types

public enum MyEnum {
    case optionA
    case optionB
}
```

### Model Design Patterns

**1. Identifiable Conformance**
- All primary models conform to `Identifiable`
- Use `UUID` for `id` property
- Provides default value: `id: UUID = UUID()`

**2. Codable Conformance**
- Models conform to `Codable` for future persistence
- Enables JSON encoding/decoding

**3. Metadata Pattern**
- Complex models have separate metadata structs
- Example: `Document` has `DocumentMetadata`
- Keeps main model clean and focused

**4. Computed Properties for Derived Data**
- Don't store what can be calculated
- Example: `Document.wordCount` is computed from `content`

---

## 🛠️ Common Tasks

### 1. Adding a New Template

```swift
// In TemplateManager.createDefaultTemplates()
let newTemplate = Template(
    name: "My Custom Template",
    category: .other,
    description: "Description of the template",
    content: """
    {{title}}

    {{main_content}}
    """,
    placeholders: [
        Placeholder(
            key: "title",
            label: "Title",
            description: "The title of your document",
            required: true
        ),
        Placeholder(
            key: "main_content",
            label: "Main Content",
            description: "The main body of your document",
            required: true
        )
    ]
)
templates.append(newTemplate)
```

### 2. Using the Library in Another Project

```swift
import WritersApp

// Basic usage
let app = WritersApp()
let templates = app.templateManager.getAllTemplates()
let novelTemplate = templates.first { $0.category == .novel }

// Create document from template
if let template = novelTemplate {
    let document = app.createDocumentFromTemplate(
        templateId: template.id,
        values: [
            "title": "My Novel",
            "chapter_number": "1",
            "chapter_title": "The Beginning"
        ]
    )
}

// With AI
let aiConfig = AIConfiguration(
    apiKey: "your-api-key",
    model: .claude35Sonnet,
    temperature: 0.7
)
let aiApp = WritersApp(aiConfiguration: aiConfig)

// Use AI features
Task {
    let continuation = try await aiApp.continueDocument(
        documentId: document.id,
        appendToDocument: true
    )
    print(continuation)
}
```

### 3. Extending Export Formats

```swift
// In WritersApp.swift

// 1. Add to ExportFormat enum
public enum ExportFormat {
    case markdown
    case plainText
    case html
    case pdf  // New format
}

// 2. Add switch case in exportDocument
public func exportDocument(id: UUID, format: ExportFormat = .markdown) -> String? {
    guard let document = documentManager.getDocument(id: id) else {
        return nil
    }

    switch format {
    case .markdown:
        return exportAsMarkdown(document)
    case .plainText:
        return document.content
    case .html:
        return exportAsHTML(document)
    case .pdf:
        return exportAsPDF(document)  // New method
    }
}

// 3. Implement export method
private func exportAsPDF(_ document: Document) -> String {
    // Implementation
    // Note: Might return Data instead of String for binary formats
}
```

### 4. Adding Persistence

Currently, both managers use in-memory storage. To add persistence:

```swift
// Example: DocumentManager with file persistence
public class DocumentManager {
    private var documents: [UUID: Document] = [:]
    private let storageURL: URL

    public init(storageURL: URL? = nil) {
        self.storageURL = storageURL ?? Self.defaultStorageURL()
        loadDocuments()
    }

    private static func defaultStorageURL() -> URL {
        let documentsPath = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!
        return documentsPath.appendingPathComponent("WritersApp/documents.json")
    }

    private func loadDocuments() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else {
            return
        }

        do {
            let data = try Data(contentsOf: storageURL)
            let decoded = try JSONDecoder().decode([UUID: Document].self, from: data)
            self.documents = decoded
        } catch {
            print("Failed to load documents: \(error)")
        }
    }

    private func saveDocuments() {
        do {
            let data = try JSONEncoder().encode(documents)
            try data.write(to: storageURL)
        } catch {
            print("Failed to save documents: \(error)")
        }
    }

    public func createDocument(_ document: Document) {
        documents[document.id] = document
        saveDocuments()  // Add this line to existing methods
    }

    // Update other CRUD methods similarly
}
```

---

## 🤖 AI Integration

### Claude API Setup

**Environment Variable**:
```bash
export ANTHROPIC_API_KEY="sk-ant-..."
```

**Configuration**:
```swift
let config = AIConfiguration(
    apiKey: "your-key",
    model: .claude35Sonnet,    // Default, recommended
    maxTokens: 4096,            // Default
    temperature: 0.7            // Default, 0.0-1.0 range
)
```

### Available Models

| Model ID | Display Name | Use Case |
|----------|--------------|----------|
| `claude-3-5-sonnet-20241022` | Claude 3.5 Sonnet | **Recommended** - Best balance of quality and speed |
| `claude-3-opus-20240229` | Claude 3 Opus | Highest quality, slower |
| `claude-3-sonnet-20240229` | Claude 3 Sonnet | Good quality, fast |
| `claude-3-haiku-20240307` | Claude 3 Haiku | Fastest, lower quality |

### AI Assistance Types

**Writing Assistance**:
- `continueWriting` - Generate natural continuation
- `improveText` - Enhance clarity and impact
- `grammarCheck` - Grammar and spelling corrections
- `styleSuggestions` - Style improvement recommendations

**Creative Tools**:
- `brainstormIdeas` - Generate creative ideas
- `characterDevelopment` - Develop character concepts
- `plotSuggestions` - Story development ideas
- `generateOutline` - Create structured outlines

**Text Manipulation**:
- `titleGeneration` - Generate compelling titles
- `summarize` - Concise summaries
- `expandText` - Add detail and elaboration
- `simplifyText` - Simplify for accessibility
- `changetone(WritingTone)` - Rewrite in different tone

**Enhancement**:
- `dialogueImprovement` - Natural, engaging dialogue
- `descriptionEnhancement` - Vivid, sensory descriptions

**Custom**:
- `custom(String)` - Custom instructions

### AI Context

Provide context for better AI responses:

```swift
let context = AIContext(
    genre: "Science Fiction",
    targetAudience: "Young Adult",
    existingCharacters: ["Alex", "Sarah", "Dr. Martinez"],
    plotSummary: "A team discovers time travel but must prevent its misuse",
    additionalNotes: "Should have a hopeful tone despite challenges"
)

let ideas = try await app.brainstormIdeas(
    topic: "Plot twists for the finale",
    context: context
)
```

### Error Handling

```swift
do {
    let improved = try await app.improveDocument(documentId: id)
    print(improved)
} catch AIError.aiNotEnabled {
    print("AI features not enabled")
} catch AIError.documentNotFound {
    print("Document not found")
} catch {
    print("AI error: \(error.localizedDescription)")
}
```

---

## 📝 Important Notes for AI Assistants

### When Working with This Codebase

**1. Respect the Sentimental Value**
- The repository name "friendly-outlaw" has personal significance
- Make changes thoughtfully and with care

**2. Swift Package Manager**
- This is a Swift Package, not an Xcode project
- No `.xcodeproj` file
- Configuration is in `Package.swift`
- Build with `swift build`, not Xcode (though Xcode can open Package.swift)

**3. Two Targets**
- `WritersApp`: Library for embedding in other projects
- `WritersAppCLI`: Executable CLI tool
- Changes to library should maintain backward compatibility
- CLI can be more experimental

**4. AI Features are Optional**
- App must work fully without AI
- Always check `isAIEnabled` or handle `AIError.aiNotEnabled`
- Never require AI for core functionality

**5. In-Memory Storage**
- Current implementation uses in-memory storage
- Data is lost when app exits
- This is intentional for v1
- Persistence is a known future enhancement

**6. Test Coverage**
- Add tests for new features
- Run `swift test` before committing
- Tests don't cover AI features (requires live API)

**7. API Keys**
- Never commit API keys
- Use environment variables
- Remind users to set `ANTHROPIC_API_KEY`

**8. Code Style**
- Follow existing Swift conventions
- Use `// MARK: -` sections
- Public API gets `///` documentation
- Keep methods focused and single-purpose

**9. Error Messages**
- Make errors user-friendly
- Conform custom errors to `LocalizedError`
- Provide actionable error descriptions

**10. Platform Compatibility**
- Minimum: macOS 13, iOS 16
- Use `@available` for newer features
- Avoid platform-specific code in library (ok in CLI)

### Common Gotchas

**1. Placeholder Syntax**
- Templates use `{{key}}` not `{key}` or `$key`
- Case-sensitive: `{{title}}` ≠ `{{Title}}`

**2. Async/Await**
- All AI methods are `async throws`
- CLI uses `Task { ... }` for async code
- Remember to `await` and `try`

**3. Model Updates**
- `Document` is a struct, so mutations require reassignment
- Use `var updatedDocument = document` then `documentManager.updateDocument(updatedDocument)`

**4. UUID Lookups**
- All lookups by UUID can return `nil`
- Always handle optional cases

**5. Export Format Strings**
- HTML export uses inline styles (no external CSS)
- Markdown export includes metadata header
- Plain text is just the content

### Suggested Improvements (Future Enhancements)

When users ask about improvements or you're brainstorming:

**High Priority**:
- ✅ File persistence (JSON or SQLite)
- ✅ Rich text formatting support
- ✅ Version history for documents
- ✅ More export formats (PDF, DOCX)

**Medium Priority**:
- Cloud storage integration (iCloud, Dropbox)
- Collaborative editing
- Voice dictation support
- Custom template creation UI
- Import from other formats

**Low Priority**:
- Plagiarism detection
- Style consistency checking
- Advanced analytics dashboard
- Multiple AI provider support
- Voice profile learning

**Infrastructure**:
- Comprehensive logging
- Performance monitoring
- More extensive test coverage
- CI/CD pipeline setup
- Documentation generation

### Working with Git

**Current Branch**: `claude/add-claude-documentation-kfhIp`

**When Committing**:
```bash
git add <files>
git commit -m "Clear, descriptive message"
git push -u origin claude/add-claude-documentation-kfhIp
```

**Commit Message Style**:
- Use imperative mood: "Add feature" not "Added feature"
- Be specific: "Add PDF export support" not "Update exports"
- Reference issues if applicable

**Before Creating PR**:
1. Run `swift test` - ensure all tests pass
2. Run `swift build` - ensure clean build
3. Update README.md if adding user-facing features
4. Update this CLAUDE.md if changing architecture

---

## 🎓 Learning Resources

### Swift Package Manager
- [Swift.org Package Manager Guide](https://swift.org/package-manager/)
- [Apple SPM Documentation](https://developer.apple.com/documentation/packagedescription)

### Anthropic Claude API
- [API Documentation](https://docs.anthropic.com/)
- [Messages API Reference](https://docs.anthropic.com/claude/reference/messages)
- [Prompt Engineering Guide](https://docs.anthropic.com/claude/docs/prompt-engineering)

### Swift Language
- [Swift Language Guide](https://docs.swift.org/swift-book/)
- [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)

---

## 📞 Support & Contribution

### Reporting Issues
- Check existing issues first
- Provide minimal reproducible example
- Include Swift version, platform, and OS version
- For AI issues, include model and approximate prompt (no API keys!)

### Contributing Guidelines
1. Fork the repository
2. Create feature branch: `git checkout -b feature/my-feature`
3. Make changes following coding conventions
4. Add/update tests
5. Ensure `swift test` passes
6. Commit with descriptive messages
7. Push and create pull request
8. Link related issues in PR description

---

## 📄 License

MIT License - See LICENSE file for details

---

**Last Updated**: 2026-01-17
**For**: Claude AI Assistant
**By**: AI Assistant analyzing codebase

*This document should be updated whenever significant architectural changes occur.*
