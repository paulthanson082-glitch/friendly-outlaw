# The Archiver Agent Profile

## Overview

The **Archiver** is a complementary agent profile to Hermes, designed to organize, preserve, and resurface your creative work. While Hermes sparks new ideas, the Archiver curates your body of work—creating collections, preserving milestones, summarizing completed projects, and surfacing forgotten ideas when they're relevant.

## When to Use the Archiver

- **After completing a document** — preserve the milestone and add it to a collection
- **Organizing past work** — tag and categorize your documents thematically
- **Preparing for a new project** — search the archive for related earlier work
- **Celebrating progress** — review snapshots of your writing journey
- **Rediscovering ideas** — get AI-powered suggestions for archived work related to your current writing

## Core Capabilities

### 1. Collections
Create themed, titled collections to organize your archive:

```swift
let collection = archiverService.createCollection(
    name: "Fantasy Shorts",
    description: "A collection of completed short stories in the fantasy genre",
    theme: "fantasy",
    tags: ["fantasy", "shorts", "completed"]
)

archiverService.addDocumentToCollection(documentId, collectionId: collection.id)
```

**Use case:** Group related work (all romance stories, all experimental pieces, all submissions to a magazine).

### 2. Snapshots (Milestones)
Preserve key moments in your writing journey:

```swift
let snapshot = archiverService.preserveMilestone(
    documentId: doc.id,
    title: "First Draft Complete — Chapter 5",
    wordCount: 12500,
    daysStreak: 14,
    sessionCount: 8,
    summary: "Completed the pivotal scene where the protagonist discovers the truth."
)
```

**Use case:** Record word count milestones, streak achievements, or significant creative moments.

### 3. Organization & Tagging
Automatically tag documents with AI-powered suggestions:

```swift
let tags = try await archiverService.organizeByTags([doc1.id, doc2.id])
// Returns: [UUID: [String]] mapping documents to tag arrays
```

**Use case:** Quickly categorize batches of documents with consistent, interconnected tags.

### 4. Summarization
Generate concise, evocative summaries for archival:

```swift
let summary = try await archiverService.summarizeDocument(documentId)
// "A haunting tale of loss and redemption set in a decaying seaside town."
```

**Use case:** Create abstracts of finished projects for quick reference.

### 5. Retrieval & Recommendations
Search and resurface relevant archived work:

```swift
let (docs, snapshots, collections) = archiverService.search("dragon", limit: 10)

let suggestions = await archiverService.suggestRelated(to: currentDocId, limit: 5)
```

**Use case:** When starting a new dragon story, find all past dragon-related work.

## Switching Between Hermes and Archiver

The Archiver runs as a profile within HermesService, allowing you to switch personas:

```swift
// Start with Hermes (creative ideation)
var session = try app.startHermesSession(context: HermesContext(genre: "Fantasy"))
let ideas = try await hermesService.generateIdeas("I'm stuck on my dragon", in: &session)

// Switch to Archiver (organizing and reflecting)
hermesService.switchProfile(.archiver)
hermesService.endSession()  // End Hermes session first

var archiveSession = hermesService.startSession(context: HermesContext())
let archiveResponse = try await hermesService.generateIdeas(
    "Organize my dragon stories and find themes across them",
    in: &archiveSession
)
```

## Workflow: From Creation to Archive

### Phase 1: Generate & Write (Hermes)
```swift
var session = try app.startHermesSession(context: HermesContext(genre: "Fantasy"))
let ideas = try await hermesService.generateIdeas("Dragon story ideas", in: &session)
// Write your story...
```

### Phase 2: Complete & Preserve (Archiver)
```swift
let doc = documentManager.getDocument(id: docId)!
let summary = try await archiverService.summarizeDocument(docId)
let snapshot = archiverService.preserveMilestone(
    documentId: docId,
    title: doc.title,
    wordCount: doc.content.split(separator: " ").count,
    daysStreak: 7,
    summary: summary
)
```

### Phase 3: Organize (Archiver)
```swift
let collection = archiverService.createCollection(name: "Dragon Stories")
archiverService.addDocumentToCollection(docId, collectionId: collection.id)

let tags = try await archiverService.organizeByTags([docId])
```

### Phase 4: Discover (Archiver)
```swift
let relatedWork = await archiverService.suggestRelated(to: newDocId)
// Review past dragon stories before starting a new one
```

## API Reference

### Collections

| Method | Purpose |
|--------|---------|
| `createCollection(name:description:theme:tags:)` | Create a new collection |
| `getCollection(_:)` | Retrieve a collection by ID |
| `addDocumentToCollection(_:collectionId:)` | Add a document to a collection |
| `removeDocumentFromCollection(_:collectionId:)` | Remove a document from a collection |
| `listCollections()` | Get all collections |
| `deleteCollection(_:)` | Delete a collection |

### Snapshots

| Method | Purpose |
|--------|---------|
| `preserveMilestone(...)` | Create a milestone snapshot |
| `getSnapshot(_:)` | Retrieve a snapshot by ID |
| `getSnapshots(forDocument:)` | Get all snapshots for a document |
| `listSnapshots()` | Get all snapshots (most recent first) |

### Organization

| Method | Purpose |
|--------|---------|
| `organizeByTags(_:context:)` | Auto-tag documents with AI assistance |

### Summarization

| Method | Purpose |
|--------|---------|
| `summarizeDocument(_:)` | Generate AI summary for archival |

### Search & Discovery

| Method | Purpose |
|--------|---------|
| `search(_:limit:)` | Search documents, snapshots, and collections |
| `suggestRelated(to:limit:)` | Get related archived work |

### Statistics

| Method | Purpose |
|--------|---------|
| `getArchiveStats()` | Get aggregate archive metrics |

## Example: Complete Archive Workflow

```swift
let app = WritersApp(aiConfiguration: config)

// Create collections
let fantasyCollection = archiverService.createCollection(
    name: "Fantasy World",
    theme: "fantasy",
    tags: ["fantasy", "epic"]
)
let experimentalCollection = archiverService.createCollection(
    name: "Experimental Pieces",
    theme: "experimental"
)

// Add completed documents
for doc in completedDocs {
    let summary = try await archiverService.summarizeDocument(doc.id)
    let snapshot = archiverService.preserveMilestone(
        documentId: doc.id,
        title: doc.title,
        wordCount: doc.wordCount,
        summary: summary,
        tags: doc.tags ?? []
    )
    
    let collection = doc.tags?.contains("fantasy") ?? false ? fantasyCollection : experimentalCollection
    archiverService.addDocumentToCollection(doc.id, collectionId: collection.id)
}

// Search and explore
let (docs, _, _) = archiverService.search("dragon")
for doc in docs {
    print("Found: \(doc.title)")
}

// Get stats
let stats = archiverService.getArchiveStats()
print("Archived \(stats["archivedDocumentCount"]!) documents")
```

## Archiver Profile Persona

The Archiver adopts a wise, methodical curator persona:

> "You are the Archiver, a wise and methodical curator of creative work. Your role is to preserve, organize, and illuminate the writer's journey..."

When generating archive-focused responses, the Archiver:
- Organizes information into clear, structured sections
- Identifies patterns and recurring elements
- Celebrates milestones and creative growth
- Surfaces forgotten ideas with clear relevance
- Uses consistent, interconnected tagging
- Remains systematic and patient

## Integration with WritersApp

The Archiver is automatically available when AI is enabled:

```swift
let app = WritersApp(aiConfiguration: aiConfig)

// archiverService is now available
let collection = app.archiverService?.createCollection(name: "My Archive")
```

## Storage & Persistence

- **In-memory by default**: Archive data is stored in the `ArchiverService.profile`
- **Optional SQLite**: Implement persistence by extending `DatabaseManager` with archive tables
- **Manual export**: Archive profiles can be exported/imported as JSON via `Codable`

## Advanced: AI-Powered Organization

When `aiService` is available, the Archiver can:

1. **Generate intelligent summaries** — captures essence in 2–3 sentences
2. **Suggest tags** — creates consistent, interconnected tag vocabulary
3. **Recommend related work** — finds thematic and conceptual connections
4. **Analyze patterns** — identifies recurring themes across your body of work

All AI operations are **optional** — the Archiver gracefully degrades to keyword-based search if AI is unavailable.

## Tips for Effective Archiving

1. **Use consistent themes** — "fantasy", "sci-fi", "romance" instead of "story1", "story2"
2. **Create focused collections** — 3–5 documents per collection is ideal for discovery
3. **Preserve snapshots at milestones** — chapter completion, word count targets, streak achievements
4. **Review your snapshots** — celebrate progress by looking back at your journey
5. **Search regularly** — resurface forgotten ideas before starting new projects
6. **Tag deeply** — use 5+ tags per document for richer discovery later

## Limitations & Future

- Currently **in-memory only** — no SQLite persistence yet
- **Manual collection management** — future versions may auto-group by AI themes
- **No export formats** — planned: PDF portfolio, JSON archive, web gallery
- **No timeline view** — planned: visual timeline of milestones and snapshots
