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

## Project Structure

```
WritersApp/
├── Package.swift
├── Sources/
│   ├── WritersApp/
│   │   ├── Models/
│   │   │   ├── Template.swift       # Template data structures
│   │   │   └── Document.swift       # Document data structures
│   │   ├── Services/
│   │   │   ├── TemplateManager.swift   # Template CRUD operations
│   │   │   └── DocumentManager.swift   # Document CRUD operations
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
