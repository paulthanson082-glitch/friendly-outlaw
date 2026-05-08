# CLAUDE.md - AI Assistant Guide for friendly-outlaw

This document provides essential context for AI assistants working with this codebase.

## Project Overview

**friendly-outlaw** is a multi-platform Swift writing assistant featuring template management, document creation with word count tracking, AI-powered writing assistance (via Claude/Anthropic API), issue tracking, Kanban boards, version control, plugin architecture, multi-format export, CRM, chatbot, computer-use, multi-agent harness, and Docker container orchestration tools.

- **Type**: Swift library + multiple CLI executables
- **Platforms**: macOS 14+, iOS 16+
- **Swift Version**: 5.9+
- **Dependencies**:
  - `CSQLite` (system library wrapping `sqlite3`) — persistent storage
  - `swift-argument-parser` 1.3.0+ — CLI argument parsing
  - `Yams` 5.0.0+ — YAML parsing (used by MockerKit)

## Quick Commands

```bash
# Build
swift build                           # Debug build
swift build -c release                # Release build

# Test
swift test                            # Run all tests
swift test --verbose                  # Verbose output

# Run
swift run WritersAppCLI               # Run writers CLI app
swift run mocker                      # Run container orchestration CLI
swift run manop                       # Run manpage operator CLI
ANTHROPIC_API_KEY="sk-..." swift run WritersAppCLI  # With AI features

# Clean
swift package clean                   # Remove build artifacts
```

## Project Structure

```
/
├── Sources/
│   ├── WritersApp/                   # Main library (public API)
│   │   ├── Models/                   # Data structures
│   │   │   ├── Template.swift        # Template, TemplateCategory, Placeholder
│   │   │   ├── Document.swift        # Document, DocumentMetadata
│   │   │   ├── AIModels.swift        # AI config, AIAssistanceType, tool loop types
│   │   │   ├── AISuggestion.swift    # AISuggestion, UserSession, AIToolUsageStats
│   │   │   ├── AppSettings.swift     # App-wide settings and preferences
│   │   │   ├── ChatbotModels.swift   # Chatbot conversation models
│   │   │   ├── ComputerUseModels.swift  # Computer-use action/result models
│   │   │   ├── CoworkModels.swift    # Collaborative work session models
│   │   │   ├── CRMModels.swift       # CRM contact, deal, pipeline models
│   │   │   ├── FocusSession.swift    # FocusSession, FocusSessionType, FocusSessionState
│   │   │   ├── GuiNewModels.swift    # GUI automation models
│   │   │   ├── HardwareModels.swift  # Hardware/device info models
│   │   │   ├── HarnessModels.swift   # Multi-agent harness models
│   │   │   ├── HermesModels.swift    # Hermes messaging models
│   │   │   ├── Issue.swift           # Issue, IssueStatus, IssuePriority, IssueMetadata
│   │   │   ├── KanbanModels.swift    # KanbanBoard, KanbanTask, KanbanColumn
│   │   │   ├── RagieModels.swift     # RAG/retrieval models
│   │   │   ├── TraceModels.swift     # Trace, TraceEvent, TraceSpan (analytics)
│   │   │   ├── VersionControl.swift  # VCBranch, VCCommit, VCDiff, VCMergeResult
│   │   │   ├── WritingAdvisorModels.swift  # Writing advisor session/feedback models
│   │   │   ├── WritingGoal.swift     # WritingGoal, GoalType, GoalUnit, WritingStreak
│   │   │   └── iPadProModels.swift   # iPad Pro-specific UI models
│   │   ├── Services/                 # Business logic
│   │   │   ├── AIService.swift       # Claude API integration + tool loop
│   │   │   ├── ApplePencilManager.swift    # Apple Pencil input handling
│   │   │   ├── ChatbotService.swift  # Conversational chatbot via Claude
│   │   │   ├── ComputerUseService.swift    # Computer-use action execution
│   │   │   ├── CoworkService.swift   # Collaborative writing sessions
│   │   │   ├── CRMManager.swift      # CRM contact/deal management
│   │   │   ├── DatabaseManager.swift # SQLite persistence (sessions, suggestions, VC)
│   │   │   ├── DocumentManager.swift # Document CRUD + statistics
│   │   │   ├── DoltVersionControlService.swift  # Branch/commit/diff/merge/time-travel
│   │   │   ├── EncouragementService.swift # Motivational messages + milestones
│   │   │   ├── FocusSessionManager.swift # Focus session lifecycle
│   │   │   ├── GuiNewService.swift   # GUI automation service
│   │   │   ├── HardwareManager.swift # Hardware/device management
│   │   │   ├── HermesService.swift   # Hermes messaging/notification service
│   │   │   ├── IssueManager.swift    # Issue CRUD + status/priority management
│   │   │   ├── KanbanManager.swift   # Kanban board and task management
│   │   │   ├── KeyboardShortcutManager.swift # Keyboard shortcut registration
│   │   │   ├── MultiAgentHarness.swift     # Multi-agent orchestration
│   │   │   ├── MultitaskingManager.swift   # iPadOS multitasking/split view
│   │   │   ├── ProductivityAnalytics.swift # Writing analytics and statistics
│   │   │   ├── RagieService.swift    # RAG/retrieval-augmented generation
│   │   │   ├── StageManagerSupport.swift   # Stage Manager window management
│   │   │   ├── TemplateManager.swift # Template CRUD + 7 default templates
│   │   │   ├── TraceAnalysisService.swift  # Distributed trace analysis
│   │   │   ├── WritingAdvisorService.swift # AI-powered writing advisor
│   │   │   ├── WritingGoalManager.swift    # Goal tracking + streaks
│   │   │   └── WritingToolExecutor.swift   # AI tool loop executor (5 built-in tools)
│   │   ├── Plugins/                  # Plugin architecture
│   │   │   ├── Plugin.swift          # Plugin protocol, PluginCapability, PluginAction
│   │   │   ├── PluginManager.swift   # Plugin registry and lifecycle (singleton)
│   │   │   ├── ClaudeMemoryPlugin.swift  # Memory storage via plugin protocol
│   │   │   └── MCPClient.swift       # MCP (Model Context Protocol) client
│   │   ├── Views/                    # UI layer
│   │   │   ├── CRMDashboardView.swift     # CRM dashboard SwiftUI view
│   │   │   ├── MetalDashboardView.swift   # Metal GPU-accelerated dashboard
│   │   │   ├── MetalDashboardViewModel.swift
│   │   │   ├── MetalTheme.swift       # Metal rendering theme/colors
│   │   │   └── iPadProViews.swift     # iPad Pro-specific SwiftUI views
│   │   ├── Previews/
│   │   │   └── MetalDashboardPreview.swift
│   │   ├── Extensions/
│   │   │   ├── String+Extensions.swift   # Placeholder substitution utilities
│   │   │   └── CoreGraphics+Codable.swift # CGFloat/CGSize/CGPoint Codable support
│   │   └── WritersApp.swift          # Main entry point / facade class
│   ├── WritersAppCLI/
│   │   └── main.swift                # Interactive writers CLI
│   ├── MockerKit/                    # Docker container orchestration library
│   │   ├── Compose/
│   │   │   ├── ComposeFile.swift     # Docker Compose file parsing
│   │   │   └── ComposeOrchestrator.swift # Compose lifecycle management
│   │   ├── Container/
│   │   │   ├── ContainerEngine.swift # Container create/start/stop/remove
│   │   │   └── ContainerStore.swift  # In-memory container state
│   │   ├── Image/
│   │   │   ├── ImageManager.swift    # Image pull/list/remove
│   │   │   └── ImageStore.swift      # In-memory image state
│   │   ├── Network/
│   │   │   └── NetworkManager.swift  # Docker network management
│   │   ├── Volume/
│   │   │   └── VolumeManager.swift   # Docker volume management
│   │   ├── Models/
│   │   │   ├── ContainerInfo.swift
│   │   │   ├── ImageInfo.swift
│   │   │   ├── NetworkInfo.swift
│   │   │   └── VolumeInfo.swift
│   │   ├── Formatters/
│   │   │   └── TableFormatter.swift  # CLI table output formatting
│   │   └── Config/
│   │       └── MockerConfig.swift    # Mocker daemon configuration
│   ├── Mocker/                       # `mocker` CLI executable
│   │   └── Commands/
│   │       ├── MockerCommand.swift   # Root command
│   │       ├── ComposeCommands.swift
│   │       ├── ContainerCommands.swift
│   │       ├── ImageCommands.swift
│   │       ├── NetworkCommands.swift
│   │       ├── SystemCommands.swift
│   │       └── VolumeCommands.swift
│   └── ManpageOperator/
│       └── main.swift                # `manop` CLI — manual page operations
├── Tests/
│   ├── WritersAppTests/              # 17 test files
│   │   ├── WritersAppTests.swift     # Core: templates, documents, word count, tool loop
│   │   ├── AIServiceTests.swift      # AI operations and tool loop
│   │   ├── DatabaseManagerTests.swift # SQLite CRUD operations
│   │   ├── DocumentManagerTests.swift # Document lifecycle
│   │   ├── DoltVersionControlServiceTests.swift # VC branches, commits, diff, merge
│   │   ├── EncouragementServiceTests.swift # Motivational messages
│   │   ├── ErrorPathTests.swift      # Error handling edge cases
│   │   ├── ExportTests.swift         # Export format correctness
│   │   ├── FocusSessionManagerTests.swift # Focus session lifecycle
│   │   ├── IssueManagementTests.swift # Issues + reopen
│   │   ├── MetalDashboardTests.swift # Metal dashboard view model
│   │   ├── PerformanceTests.swift    # Performance benchmarks
│   │   ├── PluginTests.swift         # Plugin system
│   │   ├── ProductivityAnalyticsTests.swift # Analytics aggregation
│   │   ├── WritingAdvisorTests.swift # Writing advisor service
│   │   ├── WritingGoalManagerTests.swift # Goals and streaks
│   │   └── iPadProFeaturesTests.swift # iPad-specific features
│   └── MockerKitTests/
│       └── MockerKitTests.swift      # Container toolkit tests
├── examples/
│   ├── README.md
│   ├── python_ai_service.py          # Python Anthropic SDK example
│   ├── requirements.txt              # Python dependencies
│   ├── go_ai_service/
│   │   └── main.go                   # Go implementation (stdlib only)
│   ├── custom_board_examples.swift   # Custom Kanban board examples
│   ├── firecrawl_skill_generator.py  # Web scraping/crawling examples
│   ├── sherlock_integration.md       # Username research use cases
│   └── sherlock_mcp_server.py        # MCP server for Sherlock
├── app/                              # Next.js web application
├── frontend/                         # React frontend components
├── backend/                          # Node.js/Express backend
├── mobile/                           # React Native iOS/Android app
├── .vscode/                          # VS Code configuration
├── .claude/
│   ├── settings.json                 # Hooks registration + tool permissions
│   ├── hooks/
│   │   └── session-start.sh          # SessionStart hook — installs deps, builds
│   ├── agents/                       # Subagents (isolated workers)
│   │   ├── knowledge-advisor.md
│   │   ├── swift-code-reviewer.md
│   │   ├── swift-debugger.md
│   │   ├── template-designer.md
│   │   └── test-runner.md
│   ├── skills/                       # Skills (reusable workflows)
│   │   ├── add-template.md
│   │   ├── add-ai-feature.md
│   │   ├── add-version-control-op.md
│   │   ├── build-and-test.md
│   │   └── firecrawl.md
│   └── knowledge/                    # Structured standards as JSON
│       ├── index.json
│       ├── swift.json
│       ├── architecture.json
│       ├── security.json
│       ├── templates.json
│       └── testing.json
├── Package.swift                     # SPM manifest
├── README.md
├── DATABASE.md                       # SQLite schema and persistence details
├── QUICK_START.md                    # Quick setup guide
└── [additional docs: AGENTS.md, HARDWARE.md, DEPLOYMENT.md, ...]
```

## Architecture Patterns

### Manager Pattern
- `TemplateManager`: Template lifecycle, 7 default templates
- `DocumentManager`: Document CRUD, search, and statistics
- `IssueManager`: Issue CRUD with status and priority transitions
- `KanbanManager`: Kanban boards, tasks, column-based workflow
- `WritingGoalManager`: Goal creation, progress tracking, streaks
- `FocusSessionManager`: Focus session lifecycle
- `CRMManager`: CRM contacts, deals, pipeline stages
- `HardwareManager`: Hardware/device info and management

### Service Pattern
- `AIService`: Anthropic API calls, tool loop, analysis
- `ChatbotService`: Conversational chatbot powered by Claude
- `ComputerUseService`: Claude computer-use action execution
- `CoworkService`: Collaborative writing sessions
- `EncouragementService`: Milestone-aware motivational messages
- `GuiNewService`: GUI automation
- `HermesService`: Messaging and notifications
- `MultiAgentHarness`: Orchestrates multiple Claude agents in parallel
- `ProductivityAnalytics`: Writing analytics aggregation
- `RagieService`: Retrieval-augmented generation integration
- `TraceAnalysisService`: Distributed trace analysis
- `WritingAdvisorService`: AI-powered writing advisor
- `DoltVersionControlService`: Branch/commit/diff/merge for documents

### Database Layer
- `DatabaseManager`: SQLite via `CSQLite`. Persists:
  - User sessions (`UserSession`)
  - AI suggestions (`AISuggestion`)
  - AI configuration per user
  - Issues (mirror of in-memory `IssueManager`)
  - Version control branches, commits, and document snapshots
- See `DATABASE.md` for full schema reference

### Plugin System
- `Plugin` protocol: All plugins implement `initialize()`, `shutdown()`, `execute(action:)`
- `PluginManager` (singleton via `.shared`): Registers, installs, and shuts down plugins
- `ClaudeMemoryPlugin`: In-memory key/value store with category and importance support
- `MCPClient`: Model Context Protocol client for stdio/http/websocket MCP servers
- `PluginCapability`: `.memory`, `.tools`, `.resources`, `.prompts`, `.sampling`, `.logging`, `.customActions`

### AI Tool Loop
- `AIToolExecutor` protocol in `AIModels.swift`: `executeTool(name:input:) async throws -> String`
- `WritingToolExecutor`: Implements 5 built-in tools: `get_word_count`, `search_documents`, `get_document`, `calculate_reading_time`, `list_templates`
- `AIService.getAssistanceWithTools()` drives the loop: sends tool requests to executor, feeds results back, repeats until Claude returns a text response
- `WritersApp.getAIAssistanceWithTools()` is the high-level entry point, wiring `WritingToolExecutor` automatically

### Version Control
- Inspired by Dolt (Git semantics over document data)
- `VCBranch` → `VCCommit` → `[VCDocumentSnapshot]` linked chain
- Supports: `initializeDefaultBranch()`, `checkoutBranch()`, `commit()`, `log()`, `diff()`, `merge()`, `query(asOf:)` (time-travel), `history(of:)`
- Merge strategies: `.fastForward` and `.threeWay`
- Backed by `DatabaseManager` for durability

### MockerKit — Container Orchestration
- `ContainerEngine`: Interfaces with Docker daemon to create/start/stop/remove containers
- `ComposeOrchestrator`: Parses Docker Compose YAML (via Yams) and manages multi-container apps
- `ImageManager` / `NetworkManager` / `VolumeManager`: Lifecycle management for Docker primitives
- `TableFormatter`: Renders CLI output as aligned tables
- `mocker` CLI: Wraps MockerKit via `swift-argument-parser` with subcommands for each resource type

### Model Structure
- **Structs** for data: `Document`, `Template`, `AIConfiguration`, `Issue`, `KanbanTask`, `VCBranch`, `WritingGoal`
- **Classes** for services: `WritersApp`, `TemplateManager`, `DocumentManager`, `AIService`, `DatabaseManager`, `IssueManager`, `KanbanManager`, `PluginManager`, `EncouragementService`
- **Enums** for types: See "Enum Reference" section below
- All entities have UUID `id` property (conform to `Identifiable`)

## Code Conventions

### Naming
- Methods use verbs: `createDocument`, `improveText`, `brainstormIdeas`, `advanceKanbanTask`
- Properties are descriptive: `wordCount`, `characterCount`, `readingTime`, `isAchieved`, `progressPercentage`
- Status/state transitions: `updateIssueStatus`, `moveKanbanTask`, `checkoutBranch`

### Organization
- Use `// MARK: - Section Name` for code sections
- Public interfaces at top, private implementation below
- Models conform to `Codable` for JSON serialization

### Async/Await
- All AI operations are `async throws`
- All plugin operations are `async throws`
- Use typed errors: `AIError`, `AIServiceError`, `PluginError`, `DatabaseError`, `VersionControlError`

### Placeholders in Templates
- Format: `{{placeholder_key}}`
- Replaced via `String+Extensions.swift` utilities

## Key APIs

### WritersApp Public Properties
```swift
public let templateManager: TemplateManager
public let documentManager: DocumentManager
public let issueManager: IssueManager
public let kanbanManager: KanbanManager
public let databaseManager: DatabaseManager
public let pluginManager: PluginManager           // shared singleton
public let encouragementService: EncouragementService
public let versionControl: DoltVersionControlService
public private(set) var aiService: AIService?
public private(set) var currentUserId: UUID?
public var isAIEnabled: Bool
public var isMemoryPluginEnabled: Bool
public var isEncouragementEnabled: Bool
```

### WritersApp Initializers
```swift
init()                                     // No AI, default DB path
init(aiConfiguration: AIConfiguration)    // With AI pre-configured
init(databasePath: String? = nil)          // Custom SQLite path (nil = Documents dir)
```

### Document Operations
```swift
createDocumentFromTemplate(templateId:values:) -> Document?
createBlankDocument(title:category:) -> Document
exportDocument(id:format:) -> String?    // .markdown, .plainText, .html
getStatistics() -> AppStatistics
```

### AI Operations (requires `enableAI()` first)
```swift
enableAI(configuration:userId:)
disableAI()

// High-level convenience methods
continueDocument(documentId:context:appendToDocument:) async throws -> String
improveDocument(documentId:context:replaceContent:) async throws -> String
analyzeDocument(documentId:) async throws -> DocumentAnalysis
brainstormIdeas(topic:context:) async throws -> String
generateOutline(concept:context:) async throws -> String
developCharacter(characterConcept:context:) async throws -> String
generateDocumentTitles(documentId:context:) async throws -> [String]
getDocumentInsights(documentId:) async throws -> WritingInsights

// Generic AI assistance
getAIAssistance(documentId:type:context:) async throws -> AIResponse

// Tool loop (Claude can call built-in writing tools during response)
getAIAssistanceWithTools(documentId:type:context:maxIterations:) async throws -> AIResponse
```

### Issue Management
```swift
createIssue(documentId:title:description:status:priority:) -> Issue
getIssue(id:) -> Issue?
getIssues(forDocument:) -> [Issue]
getIssues(withStatus:) -> [Issue]
getIssues(withPriority:) -> [Issue]
searchIssues(query:) -> [Issue]
updateIssue(_:)
deleteIssue(id:)
updateIssueStatus(id:status:)
reopenIssue(id:)                  // Sets status=.open, clears resolvedAt
updateIssuePriority(id:priority:)
getIssueStatistics() -> (byStatus: [IssueStatus: Int], byPriority: [IssuePriority: Int])
getOpenIssues(forDocument:) -> [Issue]
getCriticalIssues() -> [Issue]
```

### Kanban Board/Task Management
```swift
createKanbanBoard(name:description:) -> KanbanBoard
getKanbanBoard(id:) -> KanbanBoard?
getAllKanbanBoards() -> [KanbanBoard]
deleteKanbanBoard(id:)           // Also removes all tasks on the board

createKanbanTask(boardId:title:description:column:) -> KanbanTask
getKanbanTask(id:) -> KanbanTask?
getKanbanTasks(forBoard:) -> [KanbanTask]
getKanbanTasks(forBoard:inColumn:) -> [KanbanTask]
searchKanbanTasks(query:) -> [KanbanTask]
deleteKanbanTask(id:)
moveKanbanTask(id:toColumn:)
advanceKanbanTask(id:) -> KanbanColumn?    // nil if already .done
regressKanbanTask(id:) -> KanbanColumn?   // nil if already .backlog
getKanbanTaskCounts(forBoard:) -> [KanbanColumn: Int]
```

### Plugin Management
```swift
enableMemoryPlugin() async throws
storeMemory(key:value:category:tags:importance:) async throws
retrieveMemory(key:) async throws -> String?
searchMemories(query:category:limit:) async throws -> [[String: Any]]
listMemories(category:limit:sortBy:) async throws -> [[String: Any]]
clearMemory(key:category:) async throws -> Int    // returns cleared count
getMemoryStats() async throws -> [String: Any]
getPlugins() -> [Plugin]
getEnabledPlugins() -> [Plugin]
shutdownPlugins() async
```

### Session & Analytics
```swift
startSession(userId:multitaskingMode:)
endSession()
updateSessionStats(wordsWritten:aiInteractions:)
getAIToolUsageStats(userId:) throws -> [AIToolUsageStats]
getSessionStats(userId:) throws -> SessionStats
getAISuggestions(userId:limit:offset:) throws -> [AISuggestion]
getUserSessions(userId:sortByDuration:) throws -> [UserSession]
```

### Encouragement
```swift
getEncouragementForDocument(_:previousWordCount:) -> EncouragementMessage?
getSessionEncouragement(durationMinutes:wordsWritten:) -> EncouragementMessage?
getMilestoneEncouragement(milestone:) -> EncouragementMessage?
getGeneralEncouragement() -> EncouragementMessage
setEncouragementEnabled(_:)
```

### AIService Methods (18+)
```swift
// Direct text operations
continueWriting(text:context:) async throws -> String
improveText(text:context:) async throws -> String
checkGrammar(text:) async throws -> String
generateTitles(content:context:) async throws -> [String]
summarize(text:) async throws -> String
expandText(text:context:) async throws -> String
brainstormIdeas(topic:context:) async throws -> String
generateOutline(concept:context:) async throws -> String
developCharacter(characterConcept:context:) async throws -> String
improveDialogue(text:context:) async throws -> String
analyzeDocument(document:) async throws -> DocumentAnalysis
getWritingInsights(document:) async throws -> WritingInsights

// Generic
getAssistance(text:type:context:) async throws -> AIResponse
getAssistanceWithTools(text:type:tools:toolExecutor:context:maxIterations:) async throws -> AIResponse
```

## Enum Reference

### Template & Document
```swift
TemplateCategory: novel, shortStory, screenplay, blogPost, article, essay,
                  poetry, businessLetter, proposal, resume, other
ExportFormat: markdown, plainText, html
```

### AI
```swift
AIModel: claude35Sonnet, claude3Opus, claude3Sonnet, claude3Haiku
AIAssistanceType: continueWriting, improveText, grammarCheck, styleSuggestions,
                  generateOutline, brainstormIdeas, characterDevelopment, plotSuggestions,
                  dialogueImprovement, descriptionEnhancement, titleGeneration,
                  summarize, expandText, simplifyText, changetone(WritingTone), custom(String)
WritingTone: professional, casual, academic, creative, humorous, serious,
             enthusiastic, empathetic, persuasive, informative
```

### Issues
```swift
IssueStatus:   open, inProgress, resolved, closed
IssuePriority: low, medium, high, critical
```

### Kanban
```swift
KanbanColumn: backlog → planning → running → review → done
              (advance/regress walk this ordered sequence)
```

### Version Control
```swift
VCChangeType: added, modified, deleted, unchanged
VCMergeResult.MergeStrategy: fastForward, threeWay
VersionControlError: branchNotFound, commitNotFound, branchAlreadyExists,
                     mergeConflict, noActiveBranch, notInitialized
```

### Goals & Encouragement
```swift
GoalType:           daily, weekly, monthly, project, custom
GoalUnit:           words, pages, minutes, sessions, chapters
EncouragementType:  wordCount, sessionDuration, consistency, milestone,
                    general, perseverance, creativity
WritingMilestone.MilestoneType: totalWords, documentCount, consecutiveDays, sessionsCompleted
```

### Plugins
```swift
PluginCapability:   memory, tools, resources, prompts, sampling, logging, customActions
PluginActionType:   storeMemory, retrieveMemory, searchMemory, clearMemory, listMemories,
                    listTools, executeTool, listResources, readResource,
                    listPrompts, getPrompt, custom
MCPServerConfig.transport: "stdio", "http", "websocket"
```

### Errors
```swift
AIError:          aiNotEnabled, documentNotFound
AIServiceError:   networkError, invalidResponse, apiError, noContent,
                  toolLoopExhausted(iterations:), toolExecutionFailed(toolName:reason:)
DatabaseError:    connectionFailed, queryFailed, invalidData, notInitialized
VersionControlError: branchNotFound, commitNotFound, branchAlreadyExists,
                     mergeConflict, noActiveBranch, notInitialized
PluginError:      notInitialized, actionNotSupported, invalidParameters,
                  executionFailed, connectionFailed, timeout, pluginNotFound,
                  capabilityNotSupported
```

## AI Integration

### Configuration
```swift
let config = AIConfiguration(
    apiKey: "sk-ant-...",
    model: .claude35Sonnet,  // or .claude3Opus, .claude3Sonnet, .claude3Haiku
    maxTokens: 4096,
    temperature: 0.7
)
app.enableAI(configuration: config, userId: userId)
```

### API Details
- Endpoint: `https://api.anthropic.com/v1/messages`
- Auth: `x-api-key` header
- Version: `anthropic-version: 2023-06-01`

### Tool Loop Pattern
```swift
// WritersApp facade (recommended):
let response = try await app.getAIAssistanceWithTools(
    documentId: doc.id,
    type: .improveText,
    maxIterations: 10   // prevents infinite loops
)

// Direct AIService usage:
let response = try await aiService.getAssistanceWithTools(
    text: content,
    type: .brainstormIdeas,
    tools: WritingToolExecutor.tools,
    toolExecutor: myExecutor,
    maxIterations: 10
)
```

Built-in tools available during the loop:

| Tool | Description |
|------|-------------|
| `get_word_count` | Count words in given text |
| `search_documents` | Search documents by query |
| `get_document` | Retrieve document by title |
| `calculate_reading_time` | Estimate reading time (200 wpm) |
| `list_templates` | List templates, optionally filtered by category |

### Tool Loop Types (in `AIModels.swift`)
```swift
ToolDefinition(name:description:inputSchema:)  // Describe a tool for Claude
ToolUseBlock(from:)                             // Parse Claude's tool request
ToolResult(toolUseId:content:isError:)          // Send result back to Claude
protocol AIToolExecutor {
    func executeTool(name:input:) async throws -> String
}
```

## Testing

Tests are split across 18 files (17 for `WritersApp`, 1 for `MockerKit`):

| File | Coverage |
|------|----------|
| `WritersAppTests.swift` | Core: templates, documents, word count, stats, placeholders, tool loop types |
| `AIServiceTests.swift` | AI operations, tool loop |
| `DatabaseManagerTests.swift` | SQLite CRUD |
| `DocumentManagerTests.swift` | Document lifecycle |
| `DoltVersionControlServiceTests.swift` | Branches, commits, diff, merge, time-travel |
| `EncouragementServiceTests.swift` | Motivational messages, milestones |
| `ErrorPathTests.swift` | Error handling edge cases |
| `ExportTests.swift` | Export format correctness |
| `FocusSessionManagerTests.swift` | Focus session lifecycle |
| `IssueManagementTests.swift` | Issues + reopen |
| `MetalDashboardTests.swift` | Metal dashboard view model |
| `PerformanceTests.swift` | Performance benchmarks |
| `PluginTests.swift` | Plugin system |
| `ProductivityAnalyticsTests.swift` | Analytics aggregation |
| `WritingAdvisorTests.swift` | Writing advisor service |
| `WritingGoalManagerTests.swift` | Goals and streaks |
| `iPadProFeaturesTests.swift` | iPad-specific features |
| `MockerKitTests.swift` | Container orchestration toolkit |

Run with: `swift test`

Use `DatabaseManager(databasePath: ":memory:")` in tests for isolated SQLite instances.

## Environment Variables

| Variable | Purpose |
|----------|---------|
| `ANTHROPIC_API_KEY` | Claude API key for AI features |

## Claude Code Extensions

The `.claude/` directory organises all Claude Code extensions for this project.

```
.claude/
├── settings.json          # Hooks registration + tool permissions (45+ allowed commands)
├── hooks/
│   └── session-start.sh   # SessionStart hook — installs deps, builds project
├── agents/                # Subagents (isolated workers with their own context)
│   ├── knowledge-advisor.md
│   ├── swift-code-reviewer.md
│   ├── swift-debugger.md
│   ├── template-designer.md
│   └── test-runner.md
├── skills/                # Skills (reusable workflows that run in the current context)
│   ├── add-template.md
│   ├── add-ai-feature.md
│   ├── add-version-control-op.md
│   ├── build-and-test.md
│   └── firecrawl.md
└── knowledge/             # Structured standards as JSON (used by knowledge-advisor)
    ├── index.json
    ├── swift.json
    ├── architecture.json
    ├── security.json
    ├── templates.json
    └── testing.json
```

### When to use each extension

| Extension | Purpose | How to invoke |
|-----------|---------|---------------|
| **Subagent** (`.claude/agents/`) | Isolated worker — does research or runs tests without filling your context | Delegate tasks: "Use the swift-code-reviewer agent on this file" |
| **Skill** (`.claude/skills/`) | Step-by-step workflow that runs in your current session | Say: "Use the add-template skill" or ask Claude to add a template |
| **Hook** (`.claude/hooks/`) | Deterministic script on a lifecycle event (no LLM involved) | Runs automatically on `SessionStart` |
| **MCP** (`.mcp.json`) | External service connections (browser, Gemini) | Available as tools throughout the session |

### Available Subagents

| Agent | When to use |
|-------|-------------|
| `knowledge-advisor` | Before any Swift code change — returns applicable standards |
| `swift-code-reviewer` | After modifying `.swift` files — checks quality and conventions |
| `swift-debugger` | On build errors, crashes, or test failures |
| `template-designer` | When designing a complex new writing template |
| `test-runner` | To get a concise pass/fail summary of `swift test` |

### Available Skills

| Skill | When to use |
|-------|-------------|
| `add-template` | Adding a new writing template to `TemplateManager` |
| `add-ai-feature` | Implementing a new AI-assisted writing capability |
| `add-version-control-op` | Extending `DoltVersionControlService` with new operations |
| `build-and-test` | Building the project and running the full test suite |
| `firecrawl` | Scraping URLs, searching the web, crawling sites, or browsing interactive pages |

## Knowledge System

Project standards live in `.claude/knowledge/` as structured JSON files. Before making any code change, consult the relevant files or use the **knowledge-advisor** subagent to retrieve applicable rules automatically.

### Knowledge Base Files

| File | Covers |
|------|--------|
| `index.json` | Category index and usage guide |
| `swift.json` | Naming, optionals, async/await, Codable, no-external-deps |
| `architecture.json` | Manager/service layers, how to add features, entry points |
| `security.json` | No hardcoded secrets, input sanitisation, network policy |
| `templates.json` | Placeholder format, count, descriptions, categories |
| `testing.json` | What to test, naming conventions, AI method approach |

### Using the Knowledge Advisor Agent

The **knowledge-advisor** subagent reads the relevant files and returns a focused rule list plus a pre-commit checklist for your specific task. Invoke it before writing code:

> "I am about to add a new async method to AIService for generating chapter outlines. What standards apply?"

### Quick Reference — Which Files to Read

- **Any Swift change**: `swift.json` + `architecture.json` + `testing.json`
- **New AI feature**: all of the above + `security.json`
- **New template**: `templates.json` + `testing.json`
- **Security-sensitive change**: `security.json`

## Common Tasks for AI Assistants

### Adding a New Template
1. Edit `Sources/WritersApp/Services/TemplateManager.swift`
2. Add to `loadDefaultTemplates()` method
3. Define placeholders with `Placeholder` struct
4. Update tests if needed

### Adding a New AI Feature
1. Add method to `Sources/WritersApp/Services/AIService.swift`
2. Create system prompt and user prompt
3. Add assistance type to `AIAssistanceType` enum in `AIModels.swift`
4. Expose via `WritersApp.swift` if needed
5. Add CLI option in `Sources/WritersAppCLI/main.swift` if applicable
6. Add test coverage in `Tests/WritersAppTests/AIServiceTests.swift`

### Adding a New Export Format
1. Add case to `ExportFormat` enum in `WritersApp.swift`
2. Implement conversion in `exportDocument()` method
3. Update `Tests/WritersAppTests/ExportTests.swift`

### Modifying Document/Template Models
1. Update struct in `Sources/WritersApp/Models/` directory
2. Ensure `Codable` conformance is maintained
3. Update related manager methods
4. Update tests

### Adding a New Issue Type or Kanban Column
1. Add case to `IssueStatus`/`IssuePriority` or `KanbanColumn` enum in the relevant model file
2. If `KanbanColumn`: update `next` and `previous` computed properties to maintain workflow order
3. Update `IssueManager`/`KanbanManager` filtering logic if needed
4. Update tests

### Adding a New Plugin
1. Create a class conforming to `Plugin` protocol in `Sources/WritersApp/Plugins/`
2. Implement `initialize()`, `shutdown()`, `execute(action:)`
3. Declare `capabilities` matching what the plugin supports
4. Register via `PluginManager.shared.register(plugin:)`
5. Expose convenience methods on `WritersApp` if needed

### Adding a Version Control Operation
1. Add method to `Sources/WritersApp/Services/DoltVersionControlService.swift`
2. Add corresponding `DatabaseManager` persistence methods if needed
3. Add new model types to `Sources/WritersApp/Models/VersionControl.swift`
4. Add tests with in-memory `DatabaseManager(databasePath: ":memory:")`

### Adding a MockerKit Feature
1. Add method to the relevant `Sources/MockerKit/` manager or engine
2. Add model types to `Sources/MockerKit/Models/` if needed
3. Wire CLI subcommand in `Sources/Mocker/Commands/`
4. Add tests in `Tests/MockerKitTests/MockerKitTests.swift`

## Files to Avoid Modifying Without Care

- `Package.swift` — Changes affect build configuration; `CSQLite` system library must remain; `Yams` and `swift-argument-parser` are required by MockerKit and Mocker
- `.vscode/` — VS Code settings for cross-device development
- `Tests/` — Ensure tests pass after changes
- `Sources/WritersApp/Views/` — Metal/SwiftUI views with platform-specific rendering code
- `Sources/WritersApp/Plugins/` — Plugin infrastructure; changes may break MCP integration
- `Sources/WritersApp/Services/DatabaseManager.swift` — Schema changes require migration strategy
- `Sources/MockerKit/Container/ContainerEngine.swift` — Direct Docker daemon interface

## Development Notes

- `CSQLite` is a system library wrapper (`pkgConfig: "sqlite3"`); `sqlite3` must be installed on the host
- AI features are optional (graceful degradation without API key)
- CLI auto-detects `ANTHROPIC_API_KEY` environment variable
- `DatabaseManager` defaults to `<Documents>/writersapp.db`; pass `":memory:"` in tests for isolation
- `PluginManager` is a singleton (`PluginManager.shared`) — register plugins once at startup
- All dates use ISO 8601 format for JSON serialization
- Version control and issue manager are dual-layered: in-memory + SQLite; keep them in sync via `WritersApp` facade methods
- `advanceKanbanTask` / `regressKanbanTask` automatically set/clear `completedAt` when transitioning to/from `.done`
- `reopenIssue` sets status to `.open` and clears `metadata.resolvedAt`
- `MockerKit` uses `Yams` for Docker Compose YAML parsing; requires Docker daemon running at runtime
- `ManpageOperator` (`manop`) is a standalone CLI with no dependency on `WritersApp` or `MockerKit`

## VS Code Integration

Pre-configured tasks available via `Cmd+Shift+B`:
- Swift: Build (default)
- Swift: Build Release
- Swift: Test
- Swift: Clean
- Swift: Run CLI

Debug configurations available in Run panel.

## Git Workflow

- Feature branches merged via PRs
- Branch naming: descriptive feature names (e.g., `claude/add-feature-name`)
- Keep commits focused and well-described
