# SQL Integration for Multitasking AI Tools

This document describes the SQLite database integration added to the Writers App to support multitasking AI tools with persistent data storage.

## Overview

The SQL integration provides a robust storage backend for AI-related data, user sessions, and configurations using SQLite. This enhancement enables:

- Persistent storage of AI interactions across app sessions
- Session tracking for usage analytics and optimization
- User-specific AI configuration management
- Real-time logging of multitasking behaviors

## Architecture

### Core Components

1. **SQLiteDatabase.swift** - Low-level database wrapper
   - Connection management
   - Schema initialization
   - Query execution
   - Error handling

2. **DatabaseModels.swift** - Data models
   - `AISuggestion` - AI prompt/response pairs
   - `UserSession` - Session tracking data
   - `AIConfigurationStorage` - Serialized AI settings

3. **DatabaseService.swift** - High-level service layer
   - CRUD operations for all tables
   - Analytics queries
   - Session management utilities

### Database Schema

#### AI_Suggestions Table
Stores AI prompt responses and metadata for retrieval and analysis.

```sql
CREATE TABLE AI_Suggestions (
    id TEXT PRIMARY KEY,
    prompt_text TEXT NOT NULL,
    output_text TEXT NOT NULL,
    ai_tool TEXT NOT NULL,
    ai_model TEXT,
    document_id TEXT,
    timestamp REAL NOT NULL,
    tokens_used INTEGER,
    context TEXT
)
```

**Indexes:**
- `idx_ai_suggestions_timestamp ON AI_Suggestions(timestamp)`
- `idx_ai_suggestions_document ON AI_Suggestions(document_id)`

#### User_Sessions Table
Tracks user session data for usage analysis and optimization.

```sql
CREATE TABLE User_Sessions (
    id TEXT PRIMARY KEY,
    session_start REAL NOT NULL,
    session_end REAL,
    tools_used TEXT NOT NULL,
    multitasking_mode TEXT,
    screen_size TEXT,
    ai_interactions_count INTEGER DEFAULT 0,
    toolbar_interactions TEXT,
    duration_seconds INTEGER,
    metadata TEXT
)
```

**Indexes:**
- `idx_user_sessions_start ON User_Sessions(session_start)`

#### AI_Configurations Table
Manages user-specific AI tool settings stored as JSON.

```sql
CREATE TABLE AI_Configurations (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    configuration_json TEXT NOT NULL,
    created_at REAL NOT NULL,
    updated_at REAL NOT NULL
)
```

**Indexes:**
- `idx_ai_configs_user ON AI_Configurations(user_id)`

## SwiftUI Integration

### WritersAppViewModel

The main view model initializes the database and manages session tracking:

```swift
public let databaseService = DatabaseService()
private var currentSession: UserSession?

public func initialize() {
    writersApp = WritersApp()
    
    // Initialize database
    try databaseService.initialize()
    
    // Start a new session
    currentSession = UserSession(
        screenSize: "\(UIScreen.main.bounds.width)x\(UIScreen.main.bounds.height)"
    )
    try databaseService.createUserSession(currentSession!)
}
```

### Automatic Logging

All toolbar and AI interactions are automatically logged:

**Toolbar Interactions:**
```swift
Button(action: { 
    viewModel.toggleBold()
    viewModel.logToolbarInteraction("bold")
}) {
    Image(systemName: "bold")
}
```

**AI Tool Usage:**
```swift
AIQuickActionButton(
    title: "Continue",
    icon: "arrow.right.circle",
    action: { 
        viewModel.aiContinueWriting()
        viewModel.logToolUsage("ai_continue")
    }
)
```

**Multitasking State Changes:**
```swift
public func updateMultitaskingState(size: CGSize) {
    // ... layout logic ...
    
    var updatedSession = currentSession
    updatedSession?.multitaskingMode = layout.showAIPanel ? "split" : "fullscreen"
    updatedSession?.screenSize = "\(size.width)x\(size.height)"
    try? databaseService.updateUserSession(updatedSession!)
}
```

## Usage Examples

### Saving AI Suggestions

```swift
let suggestion = AISuggestion(
    promptText: "Continue writing this story",
    outputText: "Once upon a time in a distant galaxy...",
    aiTool: "continueWriting",
    aiModel: "claude-3-5-sonnet-20241022",
    documentId: currentDocument.id
)

try databaseService.saveAISuggestion(suggestion)
```

### Retrieving AI Suggestions

```swift
// Get recent suggestions
let recent = try databaseService.getRecentAISuggestions(limit: 10)

// Get suggestions by tool
let continueSuggestions = try databaseService.getAISuggestionsByTool("continueWriting")

// Get suggestions for a document
let docSuggestions = try databaseService.getAISuggestionsForDocument(documentId)
```

### Session Management

```swift
// Create a session
let session = UserSession()
try databaseService.createUserSession(session)

// Log tool usage
try databaseService.logToolUsage(sessionId: session.id, tool: "editor")

// Log toolbar interaction
try databaseService.logToolbarInteraction(sessionId: session.id, interaction: "bold")

// Increment AI interaction count
try databaseService.incrementAIInteractionCount(sessionId: session.id)

// End session
try databaseService.endSession(id: session.id)
```

### AI Configuration Storage

```swift
// Save configuration
let aiConfig = AIConfiguration(
    apiKey: "sk-ant-...",
    model: .claude35Sonnet,
    maxTokens: 4096,
    temperature: 0.7
)

let configStorage = AIConfigurationStorage.from(
    aiConfiguration: aiConfig,
    userId: "user-123"
)!

try databaseService.saveAIConfiguration(configStorage)

// Retrieve configuration
let retrieved = try databaseService.getAIConfiguration(userId: "user-123")
let decodedConfig = retrieved?.toAIConfiguration()
```

### Analytics Queries

```swift
// Get total AI interactions
let total = try databaseService.getTotalAIInteractions()

// Get most used AI tools
let mostUsed = try databaseService.getMostUsedAITools(limit: 5)

// Get average session duration
let avgDuration = try databaseService.getAverageSessionDuration()

// Get active sessions
let activeSessions = try databaseService.getActiveSessions()
```

## Testing

The integration includes comprehensive test coverage with 16 tests:

- **Database Initialization** - Schema creation and table existence
- **AI Suggestions** - CRUD operations, filtering, document linking
- **User Sessions** - Creation, updates, tool/toolbar logging, session ending
- **AI Configurations** - Save, retrieve, update operations
- **Analytics** - Total interactions, most used tools, session duration

Run tests:
```bash
swift test --filter DatabaseTests
```

All tests pass successfully ✓

## Database Location

The SQLite database is stored in the Application Support directory:

**macOS:** `~/Library/Application Support/WritersApp/writersapp.db`

**iOS:** `[App Container]/Library/Application Support/WritersApp/writersapp.db`

## Benefits

1. **Persistent Storage** - User data survives app restarts
2. **Analytics** - Track usage patterns for optimization
3. **History** - Access previous AI interactions
4. **Configuration** - Maintain user preferences across sessions
5. **Insights** - Generate usage reports and statistics
6. **Performance** - Indexed queries for fast data retrieval
7. **Scalability** - SQLite handles large datasets efficiently

## Error Handling

All database operations use proper error handling:

```swift
do {
    try databaseService.saveAISuggestion(suggestion)
} catch {
    print("Failed to save suggestion: \(error)")
}
```

The system gracefully degrades if database operations fail, logging errors without crashing the app.

## Future Enhancements

Potential improvements for future versions:

- Cloud sync for cross-device data access
- Data export for backup and analysis
- Advanced analytics dashboard
- AI suggestion search and filtering UI
- Session replay functionality
- Performance metrics visualization

## References

- **Source Code:**
  - `Sources/WritersApp/Services/SQLiteDatabase.swift`
  - `Sources/WritersApp/Services/DatabaseService.swift`
  - `Sources/WritersApp/Models/DatabaseModels.swift`
  - `Sources/WritersApp/Views/iPadProViews.swift`
  
- **Tests:**
  - `Tests/WritersAppTests/DatabaseTests.swift`
  
- **Examples:**
  - `examples/database_demo.swift`
