# The Archiver Agent Profile

## Overview

The **Archiver** is a complementary agent profile alongside Hermes in the WritersApp. While Hermes sparks creative breakthroughs with bold ideas, the Archiver preserves, organizes, and illuminates the writer's creative journey.

The Archiver excels at:
- **Organizing work** into meaningful collections and thematic groupings
- **Summarizing** the essence of completed projects and writing sessions
- **Preserving milestones** as snapshots of progress and creative growth
- **Retrieving & resurfacing** forgotten ideas and relevant past work
- **Creating connections** across the writer's body of work through intelligent tagging

## Architecture

### Location
- Service: `Sources/WritersApp/Services/ArchiverService.swift`
- Models: `Sources/WritersApp/Models/HermesModels.swift` (ArchiveCollection, ArchiveSnapshot, ArchiverProfile, ArchiverContext)
- Integration: `Sources/WritersApp/WritersApp.swift` (property: `archiverService`)

### Key Components

#### ArchiverService
The main service class providing archival operations:
```swift
public class ArchiverService {
    public var profile: ArchiverProfile
    public let documentManager: DocumentManager
    
    // Collections API
    public func createCollection(...) -> ArchiveCollection
    public func getCollection(_:) -> ArchiveCollection?
    public func listCollections() -> [ArchiveCollection]
    public func addDocumentToCollection(_:collectionId:)
    public func removeDocumentFromCollection(_:collectionId:)
    public func deleteCollection(_:)
    
    // Snapshots API (preserving milestones)
    public func preserveMilestone(...) -> ArchiveSnapshot
    public func getSnapshot(_:) -> ArchiveSnapshot?
    public func getSnapshots(forDocument:) -> [ArchiveSnapshot]
    public func listSnapshots() -> [ArchiveSnapshot]
    
    // Organization & tagging
    public func organizeByTags(_:context:) async throws -> [UUID: [String]]
    
    // Summarization
    public func summarizeDocument(_:) async throws -> String
    
    // Retrieval & recommendations
    public func search(_:limit:) -> (documents, snapshots, collections)
    public func suggestRelated(to:limit:) async -> [Document]
    
    // Statistics
    public func getArchiveStats() -> [String: Any]
}
```

#### Models

**ArchiveCollection** — A thematic grouping of documents, ideas, and snapshots:
```swift
public struct ArchiveCollection: Identifiable, Codable {
    public let id: UUID
    public let name: String
    public let description: String
    public var documentIds: [UUID]
    public var ideaIds: [UUID]
    public var snapshotIds: [UUID]
    public let createdAt: Date
    public var updatedAt: Date
    public var tags: [String]
    public var theme: String
}
```

**ArchiveSnapshot** — A moment-in-time preservation of progress and milestones:
```swift
public struct ArchiveSnapshot: Identifiable, Codable {
    public let id: UUID
    public let documentId: UUID
    public let timestamp: Date
    public let wordCount: Int
    public let characterCount: Int
    public let sessionCount: Int
    public let daysStreak: Int
    public let title: String
    public let summary: String
    public let tags: [String]
}
```

**ArchiverProfile** — The user's complete archive state:
```swift
public struct ArchiverProfile: Codable {
    public let id: UUID
    public let name: String
    public var collections: [ArchiveCollection]
    public var snapshots: [ArchiveSnapshot]
    public let createdAt: Date
    public var lastArchiveAt: Date?
}
```

**ArchiverContext** — Configuration for organizing and filtering archived work:
```swift
public struct ArchiverContext: Codable {
    public let userId: UUID?
    public let timeRange: DateRange?
    public let excludedTags: [String]
    public let priorityTags: [String]
}
```

## Usage Examples

### 1. Create a Collection and Archive Documents

```swift
let archiver = app.archiverService!

// Create a themed collection
let fantasyCollection = archiver.createCollection(
    name: "Fantasy Short Stories",
    description: "Completed fantasy tales and world-building exercises",
    theme: "fantasy",
    tags: ["fantasy", "shorts", "2024"]
)

// Archive documents into the collection
for docId in myFantasyDocIds {
    archiver.addDocumentToCollection(docId, collectionId: fantasyCollection.id)
}
```

### 2. Preserve a Milestone

```swift
// Capture a moment of achievement
let milestone = archiver.preserveMilestone(
    documentId: novelId,
    title: "First Draft Complete: 'The Shadow King'",
    wordCount: 82000,
    characterCount: 475000,
    sessionCount: 156,
    daysStreak: 42,
    summary: "Completed the first draft of an epic fantasy novel blending historical fiction with magical systems.",
    tags: ["novel", "epic-fantasy", "milestone", "draft-1-complete"]
)
```

### 3. Organize and Tag

```swift
let context = ArchiverContext(
    priorityTags: ["published", "award-nominated"]
)

let tagMap = try await archiver.organizeByTags(
    [doc1.id, doc2.id, doc3.id],
    context: context
)
// Returns: [UUID: [String]] mapping each doc to generated tags
```

### 4. Summarize a Document

```swift
let summary = try await archiver.summarizeDocument(documentId)
print(summary)
// Output: "A haunting exploration of identity and memory, this character study interweaves past and present to reveal unexpected truths."
```

### 5. Search the Archive

```swift
let (docs, snapshots, cols) = archiver.search("dragon")
print("Found \(docs.count) documents, \(snapshots.count) milestones")

// Get documents related to current work
let relatedDocs = await archiver.suggestRelated(to: currentDocId, limit: 5)
```

### 6. Get Archive Statistics

```swift
let stats = archiver.getArchiveStats()
// {
//   "collectionCount": 5,
//   "snapshotCount": 23,
//   "archivedDocumentCount": 47,
//   "totalWordsArchived": 285000,
//   "createdAt": 2026-01-15T10:00:00Z,
//   "lastArchiveAt": 2026-05-07T14:30:00Z
// }
```

## Persona

The Archiver adopts a wise, methodical curator voice:

> You are the Archiver, a wise and methodical curator of creative work. Your role is to preserve, organize, and illuminate the writer's journey. You excel at:
> 1. Organizing work into meaningful collections and themes
> 2. Summarizing the essence of completed projects
> 3. Identifying patterns and recurring elements across work
> 4. Surfacing forgotten ideas that connect to current projects
> 5. Celebrating milestones and preserving memorable moments

When interacting through HermesService with the Archiver profile active, Claude adopts this systematic, celebratory tone.

## Integration with Hermes

The Archiver complements Hermes as a dual-agent system:

- **Hermes**: Forward-looking, creative sparks, idea generation
- **Archiver**: Backward-looking, preservation, organization, pattern discovery

### Switching Profiles

```swift
// Start a Hermes creative session
var hermesSession = app.hermesService!.startSession(context: storyContext)
let ideas = try await app.hermesService!.generateIdeas("Plot twist ideas", in: &hermesSession)

// Switch to Archiver to organize and summarize
app.hermesService!.switchProfile(.archiver)
// Now queries to generateIdeas() will use the Archiver persona instead
```

When switching profiles, the active session is cleared, allowing fresh context for the new agent.

## Workflow: Archive a Completed Project

1. **Document Completion**: Writer finishes a project
2. **Preserve Milestone**: Capture stats, summary, and emotional moment
3. **Tag & Organize**: Auto-generate tags, assign to thematic collection
4. **Summarize**: AI generates an evocative summary for future discovery
5. **Link & Resurface**: Connect to related past work for inspiration
6. **Celebrate**: Display milestone in encouragement/progress UI

Example:
```swift
async {
    let doc = documentManager.getDocument(id: docId)!
    
    // Capture achievement
    let snapshot = archiver.preserveMilestone(
        documentId: docId,
        title: "\(doc.title) - Complete",
        wordCount: doc.content.split(separator: " ").count,
        summary: try await archiver.summarizeDocument(docId),
        tags: doc.tags ?? []
    )
    
    // Organize
    let tags = try await archiver.organizeByTags([docId])
    
    // Add to collection
    let col = archiver.createCollection(name: "Completed 2026")
    archiver.addDocumentToCollection(docId, collectionId: col.id)
    
    // Suggest related
    let relatedDocs = await archiver.suggestRelated(to: docId, limit: 3)
}
```

## Testing

Test coverage in `Tests/WritersAppTests/ArchiverServiceTests.swift`:

- ✅ Collection CRUD (create, retrieve, list, delete)
- ✅ Adding/removing documents from collections
- ✅ Snapshot creation and retrieval
- ✅ Organization and tagging
- ✅ Summarization (with and without AI)
- ✅ Search across documents, snapshots, collections
- ✅ Related document suggestions
- ✅ Archive statistics

Run: `swift test -filter ArchiverServiceTests`

## Design Notes

### Simplest Yet Effective

The Archiver is designed with intentional minimalism:

- **Collections**: Simple UUID-based grouping with tags for discovery
- **Snapshots**: Lightweight milestone markers with timestamp and stats
- **Tagging**: Keyword-based organization, optional AI enrichment
- **Search**: Full-text matching across titles, summaries, tags
- **Suggestions**: Relevance scoring via tag overlap (no ML/embeddings needed)

This approach:
- ✅ Requires no external dependencies or databases
- ✅ Integrates naturally with existing Document and Template structures
- ✅ Provides meaningful organization without bloat
- ✅ Scales gracefully for typical writer workflows
- ✅ Allows optional AI enhancement (summaries, tags) when available

### No Persistence

By design, ArchiverProfile is in-memory. To persist across sessions:
- Extend `DatabaseManager` with `archive_collections` and `archive_snapshots` tables
- Serialize `ArchiverProfile` to JSON via `Codable`
- Or integrate with user preferences in `AppSettings`

This keeps the initial implementation focused and testable.

## Future Extensions

Possible enhancements (outside current scope):

- SQLite persistence for archives across sessions
- ML-based tag suggestions and document clustering
- Temporal analytics (writing patterns, productivity trends)
- Integration with version control (linking snapshots to VC commits)
- Export capabilities (collections as EPUB, PDF collections)
- Collaborative archives (shared collections across users)

## See Also

- `HermesService.swift` — Creative ideation agent
- `CLAUDE.md` — Full project documentation
- `.claude/agents/` — Other agent profiles
