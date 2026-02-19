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

### 📧 Email & Communication
Integration options for sharing and sending documents:
- **MessageUI Framework** - Native iOS/macOS mail composer for user-initiated emails
- **MailSlurp** - Swift SDK for automated email sending/receiving and inbox management
- **Sidemail** - Email API for sending transactional emails (via HTTP API)
- **SwiftMail** - SMTP and IMAP library for direct email sending

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

### 💾 Database & Persistence (NEW!)
SQLite-powered persistent storage for tracking and analytics:
- **AI Suggestion History**: Complete log of all AI-generated suggestions
  - Track which tools were used and when
  - Store prompts and responses for review
  - Mark suggestions as applied/unapplied
  - Pagination support for large datasets
- **Session Tracking**: Comprehensive writing session analytics
  - Track start/end times and session duration
  - Monitor words written per session
  - Count AI interactions during each session
  - Record multitasking mode (Split View, Full Screen, etc.)
  - Aggregate statistics (total sessions, average duration, etc.)
- **AI Configuration Storage**: Persist user-specific AI settings
  - API keys and model preferences
  - Token limits and temperature settings
  - Automatic configuration per user
- **Advanced SQL Operations**:
  - Indexed queries for fast performance
  - Pagination for efficient data loading
  - JOIN operations for related data
  - GROUP BY for usage statistics
  - Aggregation functions (SUM, AVG, COUNT, MIN, MAX)
  - Filtering and sorting capabilities

See [DATABASE.md](DATABASE.md) for complete database documentation including schema, API reference, and usage examples.

### 🤘 Metal Dashboard (iPad Pro) (NEW!)
Heavy metal-themed command center optimized for iPad Pro:
- **The Mantra**: Rotating metal-inspired motivational quotes
- **Kill Count**: Real-time statistics dashboard (words, documents, streaks)
- **The Armory**: Quick-start focus sessions (Pomodoro, Sprint, Deep Work, Marathon)
- **War Room**: Recent documents with quick access
- **The Gauntlet**: Writing goals and progress tracking
- **The Forge**: Quick actions for creating new content
- **Dark Theme**: Brutal color scheme inspired by Whitechapel and Lamb of God
- **SwiftUI**: Modern, responsive interface optimized for iPad displays

See [PREVIEW_METAL_DASHBOARD.md](PREVIEW_METAL_DASHBOARD.md) for complete Metal Dashboard documentation including design system, architecture, and usage examples.

### 💫 Encouragement System (NEW!)
A positive, motivational feedback system that celebrates your writing achievements:
- **Context-Aware Messages**: Encouragement adapts to word count, session duration, and writing patterns
- **Milestone Celebrations**: Automatic recognition of achievements (1K, 5K, 10K+ words, etc.)
- **Configurable**: Enable/disable encouragement or adjust frequency to your preference
- **Variety**: Dozens of unique messages across different categories:
  - Word count achievements (small to massive writing sessions)
  - Session duration recognition (from quick sprints to marathon sessions)
  - Perseverance messages for consistent writing
  - General encouragement to keep you motivated
- **History Tracking**: Review past encouragements to see your progress
- **CLI Integration**: Encouragement appears automatically after editing documents
- **No Distractions**: Thoughtfully designed to motivate without interrupting your flow

The encouragement system is enabled by default and can be toggled on/off through the CLI menu (option 51). Get instant positive feedback as you write!

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
│   ├── CSQLite/                      # SQLite3 module wrapper
│   │   └── module.modulemap          # C module map for SQLite
│   ├── WritersApp/
│   │   ├── Models/
│   │   │   ├── Template.swift        # Template data structures
│   │   │   ├── Document.swift        # Document data structures
│   │   │   ├── AIModels.swift        # AI configuration & types
│   │   │   ├── AISuggestion.swift    # AI suggestion & session models
│   │   │   └── iPadProModels.swift   # iPad-specific models
│   │   ├── Services/
│   │   │   ├── TemplateManager.swift     # Template CRUD operations
│   │   │   ├── DocumentManager.swift     # Document CRUD operations
│   │   │   ├── AIService.swift           # AI-powered assistance
│   │   │   ├── DatabaseManager.swift     # SQLite database operations
│   │   │   ├── MultitaskingManager.swift # iPad multitasking support
│   │   │   ├── ApplePencilManager.swift  # Apple Pencil integration
│   │   │   └── KeyboardShortcutManager.swift # Keyboard shortcuts
│   │   ├── Views/
│   │   │   ├── iPadProViews.swift        # SwiftUI views for iPad Pro
│   │   │   ├── MetalDashboardView.swift  # Metal Dashboard UI
│   │   │   ├── MetalDashboardViewModel.swift # Dashboard state management
│   │   │   └── MetalTheme.swift          # Metal color scheme and styling
│   │   ├── Previews/
│   │   │   └── MetalDashboardPreview.swift # SwiftUI preview provider
│   │   ├── Extensions/
│   │   │   └── String+Extensions.swift   # String utilities
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

#### With Encouragement Features

```swift
import WritersApp

let app = WritersApp()

// Get encouragement after updating a document
let document = app.createBlankDocument(title: "My Novel", category: .novel)
// ... user writes content ...

// Get encouragement for progress
if let encouragement = app.getEncouragementForDocument(
    document,
    previousWordCount: 0
) {
    print("💫 \(encouragement.message)")
    // Output: "Great start! You're building momentum."
}

// Get encouragement after a writing session
if let sessionEncouragement = app.getSessionEncouragement(
    durationMinutes: 30,
    wordsWritten: 500
) {
    print("⏱️ \(sessionEncouragement.message)")
    // Output: "Productive session! You're making excellent progress."
}

// Celebrate milestones
let milestone = WritingMilestone(type: .totalWords, value: 1000)
if let milestoneEncouragement = app.getMilestoneEncouragement(milestone: milestone) {
    print("🏆 \(milestoneEncouragement.message)")
    // Output: "Your first thousand words! A fantastic milestone!"
}

// Get general encouragement anytime
let encouragement = app.getGeneralEncouragement()
print("💫 \(encouragement.message)")

// Check if encouragement is enabled
print("Encouragement enabled: \(app.isEncouragementEnabled)")

// Toggle encouragement
app.setEncouragementEnabled(false)  // Disable
app.setEncouragementEnabled(true)   // Enable

// View encouragement history
let history = app.encouragementService.getHistory(limit: 10)
for enc in history {
    print("\(enc.type): \(enc.message)")
}
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

#### Quick Start

Use the convenient run script:

```bash
./run.sh                 # Run in debug mode (interactive)
./run.sh --release       # Run in release mode (optimized)
./run.sh --help          # Show help and options
```

Or build and run manually:

```bash
swift build
swift run WritersAppCLI
```

Or build a release version:

```bash
swift build -c release
.build/release/WritersAppCLI
```

#### Command-Line Arguments (NEW!)

The CLI now supports direct command-line operations without entering interactive mode:

```bash
# Show help
./run.sh --help
swift run WritersAppCLI --help

# List all documents
./run.sh --list
swift run WritersAppCLI --list

# Open a document by title
./run.sh --open "My Story"
swift run WritersAppCLI --open "My Story"

# Open a document by ID
./run.sh --open <document-uuid>
swift run WritersAppCLI --open <document-uuid>

# Start a focus session (NEW!)
./run.sh --run pomodoro           # 25-minute Pomodoro session
./run.sh --run sprint             # 15-minute writing sprint
./run.sh --run deepwork           # 90-minute Deep Work session
./run.sh --run marathon           # 120-minute Marathon session
./run.sh --run                    # Free write (no time limit)
swift run WritersAppCLI --run pomodoro

# Open document and start focus session (NEW!)
./run.sh --open "My Novel" --run pomodoro      # Open and start 25-min session
./run.sh --run sprint --open "Chapter 1"       # Open and start 15-min sprint
swift run WritersAppCLI --open "My Story" --run deepwork

# Combine with release mode
./run.sh --release --open "My Story"
```

> **📚 See [RUN_OPEN_COMMAND.md](RUN_OPEN_COMMAND.md)** for complete documentation on the combined `--open --run` command feature, including session types, document matching, and workflow examples.

These arguments allow for quick operations without entering the interactive menu system, making it easier to integrate with scripts and workflows.

#### Enabling AI Features in CLI

Set your Anthropic API key as an environment variable:

```bash
export ANTHROPIC_API_KEY="your-api-key-here"
./run.sh
```

Or inline:

```bash
ANTHROPIC_API_KEY="your-key" ./run.sh
```

Or with swift run:

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

#### Encouragement Features in CLI

The CLI includes built-in encouragement features to keep you motivated:

**Automatic Encouragement:**
- Receive positive feedback when editing documents
- Messages adapt to word count progress
- Encouragement appears after saving document changes

**Encouragement Menu Options:**
- **Option 50: Get Encouragement** - Receive an immediate motivational message
  - General encouragement
  - Perseverance messages
  - Progress-based encouragement
- **Option 51: Toggle Encouragement** - Enable or disable the encouragement system
- **Option 52: View Encouragement History** - Review your past encouragements and achievements

Encouragement is enabled by default but can be turned off if you prefer a minimal experience.

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

**Encouragement Features:**
- `getEncouragementForDocument(_:previousWordCount:)` - Get encouragement for document progress
- `getSessionEncouragement(durationMinutes:wordsWritten:)` - Get encouragement for writing session
- `getMilestoneEncouragement(milestone:)` - Get encouragement for achievements
- `getGeneralEncouragement()` - Get a motivational message
- `isEncouragementEnabled` - Check if encouragement is enabled
- `setEncouragementEnabled(_:)` - Enable or disable encouragement

### EncouragementService
- `getWordCountEncouragement(wordCount:previousCount:)` - Get encouragement based on words written
- `getSessionEncouragement(durationMinutes:wordsWritten:)` - Get encouragement for session completion
- `getMilestoneEncouragement(milestone:)` - Get encouragement for milestone achievement
- `getGeneralEncouragement()` - Get a random general encouragement message
- `getPerseveranceEncouragement()` - Get perseverance-focused encouragement
- `getHistory(limit:)` - Retrieve encouragement history
- `clearHistory()` - Clear encouragement history

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

For detailed runtime verification and test results, see [RUN_VERIFICATION.md](RUN_VERIFICATION.md).

## Requirements

- Swift 5.9+
- macOS 13+, iOS 16+, or Linux (with SQLite3 development libraries)
- Anthropic API key (for AI features - optional)

**Platform-specific setup:**

Linux users need SQLite3 development libraries:
```bash
# Ubuntu/Debian
sudo apt-get install libsqlite3-dev

# Fedora/RHEL
sudo dnf install sqlite-devel
```

macOS users with Homebrew (if system SQLite is not found):
```bash
brew install sqlite3
# Ensure pkg-config can find it
export PKG_CONFIG_PATH="/opt/homebrew/opt/sqlite/lib/pkgconfig"
```

For detailed setup verification steps and system requirements, see [SETUP_VERIFICATION.md](SETUP_VERIFICATION.md).

## Quick Setup

After cloning the repository:

```bash
# Install Node.js dependencies (for Next.js web interface)
npm install

# Verify Swift CLI works
./run.sh --help

# Run Next.js dev server
npm run dev
```

**Note:** The `node_modules` directory is gitignored, so you must run `npm install` after cloning.

## Getting an API Key

To use AI features, you'll need an Anthropic API key:

1. Visit [console.anthropic.com](https://console.anthropic.com)
2. Sign up or log in
3. Navigate to API Keys section
4. Generate a new API key
5. Set it as an environment variable: `export ANTHROPIC_API_KEY="your-key"`

AI features are completely optional - the app works fully without them.

## Additional Resources

- [SETUP_VERIFICATION.md](SETUP_VERIFICATION.md) - Detailed setup verification and system requirements
- [RUN_VERIFICATION.md](RUN_VERIFICATION.md) - Runtime verification and test results
- [TECH_TIPS.md](TECH_TIPS.md) - Useful technical tips and hidden browser commands
- [DATABASE.md](DATABASE.md) - Complete database documentation
- [QUICK_START.md](QUICK_START.md) - Quick start guide
- [VSCODE_SETUP.md](VSCODE_SETUP.md) - VS Code setup guide

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
