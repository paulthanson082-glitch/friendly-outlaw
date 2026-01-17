# friendly-outlaw
Its a name let me and my dad used to use all the time so it's in remembrance of him

---

# Writers App with Templates - Swift

A comprehensive Swift application for writers featuring template management, document creation, and writing tools.

## Features

### 📝 Template System
- **Pre-built Templates**: 7+ professional writing templates including:
  - Novel chapters
  - Short stories (three-act structure)
  - Screenplay scenes
  - Blog posts (SEO-optimized)
  - Articles (research format)
  - Poetry
  - Business letters

- **Placeholder System**: Dynamic content substitution with:
  - Required and optional fields
  - Default values
  - Descriptive labels
  - Validation support

### 📄 Document Management
- Create documents from templates or start blank
- Track word count, character count, and reading time
- Document metadata (creation date, modified date, tags)
- Word count goals and progress tracking
- Full-text search across documents
- Category-based organization

### 📊 Statistics & Analytics
- Total word count across all documents
- Average words per document
- Documents by category breakdown
- Progress tracking for word count goals
- Recently modified documents

### 🔧 Export Options
- Markdown format
- Plain text
- HTML with styling

### 🤖 AI-Powered Writing Assistant (NEW!)
Powered by Claude API for intelligent writing assistance:
- **Continue Writing**: AI generates natural continuations matching your style
- **Improve Text**: Enhance clarity, flow, and impact
- **Grammar Check**: Automated grammar and spelling corrections
- **Style Suggestions**: Get specific recommendations for better writing
- **Title Generation**: Generate compelling title options
- **Document Analysis**: Comprehensive feedback on strengths and improvements
- **Writing Insights**: Reading level, tone, pacing, and vocabulary analysis
- **Brainstorming**: Creative idea generation for any topic
- **Character Development**: Deep character creation assistance
- **Plot Suggestions**: Story development and plot twist ideas
- **Dialogue Improvement**: Natural, engaging dialogue enhancement
- **Outline Generation**: Structured outlines from concepts
- **Tone Adjustment**: Rewrite in different tones (professional, casual, etc.)
- **Text Expansion/Simplification**: Adjust complexity as needed

## Development Environment

### VS Code Setup for iPad and MacBook Pro

This project includes a complete VS Code configuration for seamless development across iPad and MacBook Pro. See [VSCODE_SETUP.md](VSCODE_SETUP.md) for detailed setup instructions including:

- Complete VS Code configuration (settings, extensions, tasks, debugging)
- Cross-device synchronization with Settings Sync
- iPad development options (native app, remote SSH, GitHub Codespaces)
- Recommended extensions for Swift development
- Keyboard shortcuts and productivity tips
- Troubleshooting guide

**Quick Start:**
1. Open this project in VS Code
2. Install recommended extensions when prompted
3. Enable Settings Sync to sync across devices
4. Use `Cmd+Shift+B` to build or `Cmd+Shift+P` → "Tasks: Run Task" for other commands

## Project Structure

```
WritersApp/
├── Package.swift
├── Sources/
│   ├── WritersApp/
│   │   ├── Models/
│   │   │   ├── Template.swift       # Template data structures
│   │   │   ├── Document.swift       # Document data structures
│   │   │   └── AIModels.swift       # AI configuration & types
│   │   ├── Services/
│   │   │   ├── TemplateManager.swift   # Template CRUD operations
│   │   │   ├── DocumentManager.swift   # Document CRUD operations
│   │   │   └── AIService.swift         # AI-powered assistance
│   │   ├── Extensions/
│   │   │   └── String+Extensions.swift # String utilities
│   │   └── WritersApp.swift         # Main app class
│   └── WritersAppCLI/
│       └── main.swift               # CLI interface
└── Tests/
    └── WritersAppTests/
        └── WritersAppTests.swift    # Unit tests
```

## Usage

### As a Library

```swift
import WritersApp

// Initialize the app
let app = WritersApp()

// Browse available templates
let templates = app.templateManager.getAllTemplates()

// Create a document from a template
let values = [
    "title": "My First Novel",
    "chapter_number": "1",
    "chapter_title": "The Beginning",
    // ... more placeholder values
]
if let document = app.createDocumentFromTemplate(
    templateId: template.id,
    values: values
) {
    print("Created: \(document.title)")
    print("Word count: \(document.wordCount)")
}

// Create a blank document
let blankDoc = app.createBlankDocument(
    title: "My Story",
    category: .shortStory
)

// Search templates
let novelTemplates = app.templateManager.searchTemplates(query: "novel")

// Get statistics
let stats = app.getStatistics()
print("Total documents: \(stats.totalDocuments)")
print("Total words: \(stats.totalWordCount)")
```

#### With AI Features

```swift
import WritersApp

// Initialize with AI
let apiKey = "your-anthropic-api-key"
let aiConfig = AIConfiguration(
    apiKey: apiKey,
    model: .claude35Sonnet,
    temperature: 0.7
)
let app = WritersApp(aiConfiguration: aiConfig)

// Or enable AI later
var app = WritersApp()
app.enableAI(configuration: aiConfig)

// Continue writing a document
let continuation = try await app.continueDocument(
    documentId: documentId,
    appendToDocument: true
)

// Improve document content
let improved = try await app.improveDocument(
    documentId: documentId,
    replaceContent: false
)
print("Improved version:\n\(improved)")

// Generate title suggestions
let titles = try await app.generateDocumentTitles(documentId: documentId)
print("Title options: \(titles)")

// Analyze a document
let analysis = try await app.analyzeDocument(documentId: documentId)
print("Analysis:\n\(analysis.analysis)")

// Brainstorm ideas
let context = AIContext(
    genre: "Science Fiction",
    targetAudience: "Young Adult"
)
let ideas = try await app.brainstormIdeas(
    topic: "Time travel paradoxes",
    context: context
)
print("Ideas:\n\(ideas)")

// Develop a character
let character = try await app.developCharacter(
    characterConcept: "A cynical detective with a heart of gold",
    context: context
)
print("Character:\n\(character)")

// Generate outline
let outline = try await app.generateOutline(
    concept: "A story about an AI that becomes sentient",
    context: context
)
print("Outline:\n\(outline)")

// Use AI service directly
if let ai = app.aiService {
    // Check grammar
    let corrections = try await ai.checkGrammar(text: "Your text here")

    // Change tone
    let professional = try await ai.changeTone(
        text: "Hey! This is cool!",
        tone: .professional
    )

    // Custom request
    let result = try await ai.customRequest(
        text: "Your content",
        instruction: "Rewrite this as a haiku"
    )
}
```

### As a CLI Tool

Build and run the CLI:

```bash
swift build
swift run WritersAppCLI
```

Or build a release version:

```bash
swift build -c release
.build/release/WritersAppCLI
```

#### Enabling AI Features in CLI

Set your Anthropic API key as an environment variable:

```bash
export ANTHROPIC_API_KEY="your-api-key-here"
swift run WritersAppCLI
```

Or inline:

```bash
ANTHROPIC_API_KEY="your-key" swift run WritersAppCLI
```

When AI is enabled, additional menu options will appear:
- Continue Writing (AI)
- Improve Document (AI)
- Generate Title Ideas (AI)
- Analyze Document (AI)
- Brainstorm Ideas (AI)
- Develop Character (AI)
- Generate Outline (AI)

## Templates Included

### 1. Novel Chapter
Structured chapter template with opening, main content, and closing scenes.

### 2. Short Story
Three-act structure for short fiction writing.

### 3. Screenplay Scene
Industry-standard screenplay format with scene headings, action, dialogue, and transitions.

### 4. Blog Post
SEO-optimized blog structure with introduction, multiple sections, conclusion, and CTA.

### 5. Article
Professional article format with abstract, background, analysis, and references.

### 6. Poetry
Multi-stanza poetry template with dedication support.

### 7. Business Letter
Professional business correspondence format with proper addressing and structure.

## API Overview

### TemplateManager
- `addTemplate(_:)` - Add a custom template
- `getTemplate(id:)` - Retrieve template by ID
- `getAllTemplates()` - Get all templates
- `getTemplates(for:)` - Get templates by category
- `searchTemplates(query:)` - Search templates
- `updateTemplate(_:)` - Update existing template
- `deleteTemplate(id:)` - Remove template

### DocumentManager
- `createDocument(_:)` - Create new document
- `getDocument(id:)` - Retrieve document by ID
- `getAllDocuments()` - Get all documents
- `getDocuments(for:)` - Get documents by category
- `searchDocuments(query:)` - Search documents
- `updateDocument(_:)` - Update existing document
- `deleteDocument(id:)` - Remove document
- `getTotalWordCount()` - Get total word count
- `getRecentDocuments(limit:)` - Get recently modified documents

### WritersApp
- `createDocumentFromTemplate(templateId:values:)` - Create document from template
- `createBlankDocument(title:category:)` - Create blank document
- `exportDocument(id:format:)` - Export document to format
- `getStatistics()` - Get app statistics

**AI Features:**
- `enableAI(configuration:)` - Enable AI features
- `disableAI()` - Disable AI features
- `getAIAssistance(documentId:type:context:)` - Get AI assistance
- `continueDocument(documentId:context:appendToDocument:)` - Continue writing
- `improveDocument(documentId:context:replaceContent:)` - Improve document
- `generateDocumentTitles(documentId:context:)` - Generate title suggestions
- `analyzeDocument(documentId:)` - Comprehensive document analysis
- `getDocumentInsights(documentId:)` - Get writing insights
- `brainstormIdeas(topic:context:)` - Brainstorm ideas
- `generateOutline(concept:context:)` - Generate outline
- `developCharacter(characterConcept:context:)` - Develop character

### AIService
- `getAssistance(text:type:context:)` - Get AI assistance for any text
- `continueWriting(text:context:)` - Continue writing
- `improveText(text:context:)` - Improve text quality
- `checkGrammar(text:)` - Grammar and spelling check
- `getStyleSuggestions(text:context:)` - Get style suggestions
- `generateOutline(concept:context:)` - Generate outline
- `brainstormIdeas(topic:context:)` - Brainstorm ideas
- `developCharacter(characterConcept:context:)` - Develop character
- `suggestPlot(currentStory:context:)` - Get plot suggestions
- `improveDialogue(dialogue:context:)` - Improve dialogue
- `enhanceDescription(description:context:)` - Enhance descriptions
- `generateTitles(content:context:)` - Generate title options
- `summarize(text:)` - Summarize text
- `expandText(text:context:)` - Expand text with detail
- `simplifyText(text:)` - Simplify text
- `changeTone(text:tone:context:)` - Change writing tone
- `customRequest(text:instruction:context:)` - Custom AI request
- `analyzeDocument(document:)` - Analyze document comprehensively
- `getWritingInsights(document:)` - Get writing insights

## Testing

Run the test suite:

```bash
swift test
```

Tests cover:
- Template creation and management
- Document creation from templates
- Word count calculations
- Search functionality
- Export functionality
- Statistics generation

## Requirements

- Swift 5.9+
- macOS 13+ or iOS 16+
- Anthropic API key (for AI features - optional)

## Getting an API Key

To use AI features, you'll need an Anthropic API key:

1. Visit [console.anthropic.com](https://console.anthropic.com)
2. Sign up or log in
3. Navigate to API Keys section
4. Generate a new API key
5. Set it as an environment variable: `export ANTHROPIC_API_KEY="your-key"`

AI features are completely optional - the app works fully without them.

## License

MIT License - See LICENSE file for details

## Contributing

Contributions welcome! Areas for enhancement:
- Additional template types
- Rich text formatting support
- Cloud storage integration
- Collaborative editing
- Version control for documents
- Export to more formats (PDF, DOCX, etc.)
- Additional AI models and providers
- AI-powered plagiarism detection
- Style consistency checking
- Advanced writing analytics
- Voice and style profile learning
