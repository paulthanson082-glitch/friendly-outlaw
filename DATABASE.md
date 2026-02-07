# Database Implementation Guide

This document describes the SQLite database implementation added to WritersApp for persisting AI suggestions, user sessions, and AI configurations.

## Overview

The database layer provides persistent storage for:
- **AI Suggestions**: Tracks AI-generated content suggestions and tool usage
- **User Sessions**: Records writing sessions with statistics and metrics
- **AI Configurations**: Stores user-specific AI settings

## Database Schema

### AI_Suggestions Table

Stores AI-generated suggestions with tool tracking.

```sql
CREATE TABLE AI_Suggestions (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    document_id TEXT,
    tool_used TEXT NOT NULL,
    prompt TEXT NOT NULL,
    response TEXT NOT NULL,
    timestamp REAL NOT NULL,
    is_applied INTEGER DEFAULT 0
);

-- Indexes for performance
CREATE INDEX idx_ai_suggestions_tool ON AI_Suggestions(tool_used);
CREATE INDEX idx_ai_suggestions_user ON AI_Suggestions(user_id);
CREATE INDEX idx_ai_suggestions_timestamp ON AI_Suggestions(timestamp);
```

**Fields:**
- `id`: Unique identifier (UUID)
- `user_id`: User who requested the suggestion
- `document_id`: Optional reference to the document being edited
- `tool_used`: Name of the AI tool (e.g., "Continue Writing", "Grammar Check")
- `prompt`: User's input or document content sent to AI
- `response`: AI-generated suggestion
- `timestamp`: When the suggestion was created
- `is_applied`: Whether the user applied the suggestion (0 = false, 1 = true)

### User_Sessions Table

Tracks writing sessions with productivity metrics.

```sql
CREATE TABLE User_Sessions (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    start_time REAL NOT NULL,
    end_time REAL,
    duration_seconds INTEGER,
    words_written INTEGER DEFAULT 0,
    ai_interactions INTEGER DEFAULT 0,
    multitasking_mode TEXT
);

-- Indexes for performance
CREATE INDEX idx_user_sessions_user ON User_Sessions(user_id);
CREATE INDEX idx_user_sessions_start ON User_Sessions(start_time);
```

**Fields:**
- `id`: Unique identifier (UUID)
- `user_id`: User who owns the session
- `start_time`: Session start timestamp
- `end_time`: Session end timestamp (nullable for active sessions)
- `duration_seconds`: Total session duration in seconds
- `words_written`: Number of words written during session
- `ai_interactions`: Number of AI tool uses
- `multitasking_mode`: iPad multitasking mode (e.g., "Split View", "Full Screen")

### AI_Configurations Table

Stores user-specific AI settings.

```sql
CREATE TABLE AI_Configurations (
    user_id TEXT PRIMARY KEY,
    api_key TEXT NOT NULL,
    model TEXT NOT NULL,
    max_tokens INTEGER DEFAULT 4096,
    temperature REAL DEFAULT 0.7,
    created_at REAL NOT NULL,
    updated_at REAL NOT NULL
);

-- Index for performance
CREATE INDEX idx_ai_configs_user ON AI_Configurations(user_id);
```

**Fields:**
- `user_id`: User who owns the configuration (PRIMARY KEY)
- `api_key`: Anthropic API key
- `model`: AI model identifier (e.g., "claude-3-5-sonnet-20241022")
- `max_tokens`: Maximum tokens for AI responses
- `temperature`: AI creativity setting (0.0-1.0)
- `created_at`: Configuration creation timestamp
- `updated_at`: Last update timestamp

## Database Manager API

### Initialization

```swift
let dbManager = DatabaseManager(databasePath: "/path/to/database.db")
try dbManager.initialize()
```

### AI Suggestions Operations

```swift
// Insert a suggestion
let suggestion = AISuggestion(
    userId: userId,
    documentId: documentId,
    toolUsed: "Continue Writing",
    prompt: "My story begins...",
    response: "Once upon a time..."
)
try dbManager.insertAISuggestion(suggestion)

// Get suggestions with pagination
let suggestions = try dbManager.getAISuggestions(
    userId: userId,
    limit: 50,
    offset: 0
)

// Update a suggestion
var suggestion = suggestions[0]
suggestion.isApplied = true
try dbManager.updateAISuggestion(suggestion)

// Delete a suggestion
try dbManager.deleteAISuggestion(id: suggestionId)

// Filter by tool
let continueSuggestions = try dbManager.filterAISuggestionsByTool(
    userId: userId,
    tool: "Continue Writing"
)

// Get usage statistics (GROUP BY, COUNT)
let stats = try dbManager.getAIToolUsageStats(userId: userId)
// Returns: [AIToolUsageStats(toolName: "Continue Writing", usageCount: 15, ...)]
```

### User Session Operations

```swift
// Insert a session
let session = UserSession(
    userId: userId,
    startTime: Date(),
    wordsWritten: 500,
    aiInteractions: 3,
    multitaskingMode: "Split View"
)
try dbManager.insertUserSession(session)

// Update a session
var session = sessions[0]
session.endTime = Date()
session.durationSeconds = 1800 // 30 minutes
session.wordsWritten = 1200
try dbManager.updateUserSession(session)

// Get sessions sorted by duration
let sessions = try dbManager.getUserSessions(
    userId: userId,
    sortByDuration: true
)

// Filter by multitasking mode
let splitViewSessions = try dbManager.filterSessionsByMode(
    userId: userId,
    mode: "Split View"
)

// Get aggregated statistics (SUM, AVG, MIN, MAX)
let stats = try dbManager.getSessionStats(userId: userId)
// Returns: SessionStats(
//   totalSessions: 10,
//   totalDurationSeconds: 18000,
//   averageDurationSeconds: 1800,
//   earliestSession: Date(...),
//   latestSession: Date(...)
// )
```

### AI Configuration Operations

```swift
// Save or update configuration
let config = AIConfiguration(
    apiKey: "sk-ant-...",
    model: .claude35Sonnet,
    maxTokens: 4096,
    temperature: 0.7
)
try dbManager.saveAIConfiguration(userId: userId, configuration: config)

// Get configuration
let config = try dbManager.getAIConfiguration(userId: userId)
```

### Join Operations

```swift
// Get AI suggestions with their associated AI configuration
let joined = try dbManager.getAISuggestionsWithConfig(userId: userId)
// Returns: [(suggestion: AISuggestion, modelUsed: String)]
```

## Integration with WritersApp

### Session Management

```swift
let app = WritersApp()

// Start a session
app.startSession(userId: userId, multitaskingMode: "Split View")

// Update session stats
app.updateSessionStats(wordsWritten: 1500, aiInteractions: 5)

// End session
app.endSession()
```

### AI Suggestion Logging

AI suggestions are automatically logged when using AI features:

```swift
// Automatically logs to database
let continuation = try await app.continueDocument(
    documentId: documentId,
    appendToDocument: true
)

let improved = try await app.improveDocument(
    documentId: documentId,
    replaceContent: true
)
```

### Querying Statistics

```swift
// Get AI tool usage statistics
let toolStats = try app.getAIToolUsageStats(userId: userId)

// Get session statistics
let sessionStats = try app.getSessionStats(userId: userId)

// Get recent suggestions with pagination
let suggestions = try app.getAISuggestions(
    userId: userId,
    limit: 50,
    offset: 0
)

// Get user sessions sorted by duration
let sessions = try app.getUserSessions(
    userId: userId,
    sortByDuration: true
)
```

## UI Integration

The `AISidebarView` displays database-backed information:

1. **Recent AI Suggestions**: Shows last 5 suggestions with timestamps
2. **Tool Usage Statistics**: Displays usage counts per AI tool
3. **Pagination**: "View All" button for accessing full suggestion history

The `WritersAppViewModel` loads data on initialization:

```swift
viewModel.initialize()
// Automatically loads:
// - Recent AI suggestions
// - Tool usage statistics
// - Session statistics
```

## Performance Considerations

### Indexes

The implementation includes indexes on frequently queried columns:
- `tool_used` for filtering by AI tool
- `user_id` for user-specific queries
- `timestamp` and `start_time` for chronological sorting

### Pagination

Use pagination for large result sets:

```swift
// Load first page
let page1 = try dbManager.getAISuggestions(userId: userId, limit: 50, offset: 0)

// Load second page
let page2 = try dbManager.getAISuggestions(userId: userId, limit: 50, offset: 50)
```

### Memory Management

The implementation uses `SQLITE_TRANSIENT` for string bindings to ensure SQLite makes copies of Swift strings, preventing memory corruption issues.

## Error Handling

All database operations can throw `DatabaseError`:

```swift
do {
    let suggestions = try dbManager.getAISuggestions(userId: userId)
} catch DatabaseError.notInitialized {
    print("Database not initialized")
} catch DatabaseError.queryFailed(let message) {
    print("Query failed: \(message)")
} catch DatabaseError.connectionFailed(let message) {
    print("Connection failed: \(message)")
} catch {
    print("Unknown error: \(error)")
}
```

## Testing

The implementation includes 14 comprehensive unit tests covering:
- Insert/retrieve operations
- Pagination
- Updates and deletes
- Filtering
- Grouping and aggregations
- Joins
- Session statistics

Run tests with:
```bash
swift test --filter DatabaseManagerTests
```

## Example Use Cases

### Track Writing Productivity

```swift
// Start session when user begins writing
app.startSession(userId: userId, multitaskingMode: "Split View")

// Update as they write
app.updateSessionStats(wordsWritten: 500, aiInteractions: 3)

// End when done
app.endSession()

// View statistics
let stats = try app.getSessionStats(userId: userId)
print("Total sessions: \(stats.totalSessions)")
print("Average duration: \(stats.averageDurationSeconds) seconds")
```

### Analyze AI Tool Usage

```swift
// Get usage statistics
let stats = try app.getAIToolUsageStats(userId: userId)

for stat in stats {
    print("\(stat.toolName): \(stat.usageCount) uses")
}

// Filter suggestions by specific tool
let grammarSuggestions = try dbManager.filterAISuggestionsByTool(
    userId: userId,
    tool: "Grammar Check"
)
```

### Review AI Suggestion History

```swift
// Get recent suggestions
let recent = try app.getAISuggestions(userId: userId, limit: 10, offset: 0)

for suggestion in recent {
    print("\(suggestion.toolUsed) - \(suggestion.timestamp)")
    print("Prompt: \(suggestion.prompt)")
    print("Response: \(suggestion.response)")
    print("Applied: \(suggestion.isApplied)")
}
```

## Security Considerations

- API keys are stored in the database - implement encryption for production use
- Use proper user authentication to prevent unauthorized access
- Consider database file permissions for multi-user systems
- Implement rate limiting for AI operations to prevent abuse

## Future Enhancements

Potential improvements:
1. Encrypt sensitive data (API keys) at rest
2. Add full-text search for suggestions
3. Implement automatic cleanup of old sessions
4. Add export functionality for session data
5. Implement backup/restore functionality
6. Add analytics dashboards
7. Support multiple database backends
