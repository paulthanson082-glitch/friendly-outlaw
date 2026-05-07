# CLAUDE.md - AI Assistant Guide for friendly-outlaw

## Start Here

**New to the project?** Read in this order:
1. `.claude/project.md` — What friendly-outlaw is and how to build/test/run it
2. `.claude/workflow.md` — How to work with Claude: ask → plan → execute
3. This file — Detailed API reference and architecture

**Just need standards before writing code?** → Use the knowledge-advisor subagent:

> "I'm adding a new async method to AIService for generating chapter summaries. What standards apply?"

**Adding a new feature?** → Use a skill:
- `add-template` — Add a writing template
- `add-ai-feature` — Implement AI assistance
- `add-version-control-op` — Extend version control
- `build-and-test` — Build and run tests

## Quick Reference

See `.claude/project.md` for quick commands, APIs, and project structure. This document contains the detailed reference.

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
│   │   │   ├── AppSettings.swift     # AppSettings, AppTheme (user preferences)
│   │   │   ├── ChatbotModels.swift   # ChatMessage, ChatSession (Jules chatbot)
│   │   │   ├── ComputerUseModels.swift # ComputerUseAction, ComputerUseResult
│   │   │   ├── CoworkModels.swift    # WritingProspect, GmailMessage, BrowsedPage, CoworkSession
│   │   │   ├── CRMModels.swift       # CRMContact, CRMDeal, CRMInteraction, PipelineStage
│   │   │   ├── FocusSession.swift    # FocusSession, FocusSessionType, FocusSessionState
│   │   │   ├── GiftCardModels.swift  # GiftCardBundle, GiftCard, GiftCardStats
│   │   │   ├── GuiNewModels.swift    # GuiNewCanvas, GuiNewError (gui.new API)
│   │   │   ├── HardwareModels.swift  # HardwareBoard, Pin, Peripheral, ConnectionConfig
│   │   │   ├── HarnessModels.swift   # HarnessPlan, SectionContract, QualityReport
│   │   │   ├── HermesModels.swift    # HermesIdea, HermesSession, HermesContext, HermesIdeaType
│   │   │   ├── Issue.swift           # Issue, IssueStatus, IssuePriority, IssueMetadata
│   │   │   ├── KanbanModels.swift    # KanbanBoard, KanbanTask, KanbanColumn
│   │   │   ├── RagieModels.swift     # RagieConfiguration, RagieDocument, RagieChunk
│   │   │   ├── SpoilerModels.swift   # SpoilerTag, SpoilerSeverity, SpoilerRegion
│   │   │   ├── TraceModels.swift     # Trace, TraceEvent, TraceSpan (analytics)
│   │   │   ├── VersionControl.swift  # VCBranch, VCCommit, VCDiff, VCMergeResult
│   │   │   ├── WritingAdvisorModels.swift # WritingRecommendation, AdvisorCategory, AdvisorContext
│   │   │   ├── WritingGoal.swift     # WritingGoal, GoalType, GoalUnit, WritingStreak
│   │   │   └── iPadProModels.swift   # iPad Pro-specific UI models
│   │   ├── Services/                 # Business logic
│   │   │   ├── AIService.swift       # Claude API integration + tool loop
│   │   │   ├── ApplePencilManager.swift    # Apple Pencil input handling
│   │   │   ├── ChatbotService.swift  # Jules chatbot with conversation history + AI
│   │   │   ├── ComputerUseService.swift # Anthropic computer use API wrapper
│   │   │   ├── CoworkService.swift   # ProspectDatabase, BrowserService, GmailService
│   │   │   ├── CRMManager.swift      # CRM contacts, deals, interactions (in-memory)
│   │   │   ├── DatabaseManager.swift # SQLite persistence (sessions, suggestions, VC)
│   │   │   ├── DocumentManager.swift # Document CRUD + statistics
│   │   │   ├── DoltVersionControlService.swift  # Branch/commit/diff/merge/time-travel
│   │   │   ├── EncouragementService.swift # Motivational messages + milestones
│   │   │   ├── FocusSessionManager.swift # Focus session lifecycle
│   │   │   ├── GiftCardError.swift   # GiftCardError enum with localized messages
│   │   │   ├── GiftCardManager.swift # Gift card bundles, redemption, expiration
│   │   │   ├── GuiNewService.swift   # gui.new API client for canvas creation
│   │   │   ├── HardwareManager.swift # Hardware board configs, pins, peripherals
│   │   │   ├── HermesService.swift   # Creative ideation agent with session management
│   │   │   ├── IssueManager.swift    # Issue CRUD + status/priority management
│   │   │   ├── KanbanManager.swift   # Kanban board and task management
│   │   │   ├── KeyboardShortcutManager.swift # Keyboard shortcut registration
│   │   │   ├── MultiAgentHarness.swift # Three-agent harness (planner/generator/evaluator)
│   │   │   ├── MultitaskingManager.swift   # iPadOS multitasking/split view
│   │   │   ├── ProductivityAnalytics.swift # Writing analytics and statistics
│   │   │   ├── RagieService.swift    # RAG document ingestion + semantic retrieval (Ragie API)
│   │   │   ├── SpoilerProtectionService.swift # Spoiler tagging, redaction, export
│   │   │   ├── StageManagerSupport.swift   # Stage Manager window management
│   │   │   ├── TemplateManager.swift # Template CRUD + 7 default templates
│   │   │   ├── TraceAnalysisService.swift  # Distributed trace analysis
│   │   │   ├── WritingAdvisorService.swift # AI-powered personalized writing advisor
│   │   │   ├── WritingGoalManager.swift  # Goal tracking + streaks
│   │   │   └── WritingToolExecutor.swift   # AI tool loop executor (5 built-in tools)
│   │   ├── Plugins/                  # Plugin architecture
│   │   │   ├── Plugin.swift          # Plugin protocol, PluginCapability, PluginAction
│   │   │   ├── PluginManager.swift   # Plugin registry and lifecycle (singleton)
│   │   │   ├── ClaudeMemoryPlugin.swift  # Memory storage via plugin protocol
│   │   │   └── MCPClient.swift       # MCP (Model Context Protocol) client
│   │   ├── Views/                    # UI layer
│   │   │   ├── CRMDashboardView.swift     # Metal-themed CRM stats + pipeline SwiftUI view
│   │   │   ├── MetalDashboardView.swift   # Metal GPU-accelerated dashboard
│   │   │   ├── MetalDashboardViewModel.swift
│   │   │   ├── MetalTheme.swift       # Metal rendering theme/colors
│   │   │   ├── SpoilerProtectionViews.swift # SwiftUI views for spoiler tag management
│   │   │   └── iPadProViews.swift     # iPad Pro-specific SwiftUI views
│   │   ├── Previews/
│   │   │   └── MetalDashboardPreview.swift
│   │   ├── Extensions/
│   │   │   ├── String+Extensions.swift   # Placeholder substitution utilities
│   │   │   └── CoreGraphics+Codable.swift # CGFloat/CGSize/CGPoint Codable support
│   │   └── WritersApp.swift          # Main entry point / facade class
│   ├── WritersAppCLI/
│   │   └── main.swift                # Interactive CLI
│   ├── MockerKit/                    # Container management library
│   │   ├── Config/MockerConfig.swift # State paths + JSON persistence helpers
│   │   ├── Compose/                  # Docker Compose orchestration
│   │   ├── Container/                # ContainerEngine actor + ContainerStore
│   │   ├── Image/                    # ImageManager + ImageStore
│   │   ├── Network/NetworkManager.swift
│   │   ├── Volume/VolumeManager.swift
│   │   ├── Formatters/TableFormatter.swift
│   │   └── Models/                   # ContainerInfo, ImageInfo, NetworkInfo, VolumeInfo
│   ├── Mocker/                       # Docker-compatible CLI (uses MockerKit)
│   │   ├── Commands/MockerCommand.swift  # Root command + subcommands
│   │   └── Formatters/TableFormatter.swift
│   └── ManpageOperator/
│       └── main.swift                # Ubuntu manpage CLI (show/search/list)
├── Tests/
│   ├── WritersAppTests/              # 35 test files, 316+ test functions
│   │   ├── WritersAppTests.swift     # Core: templates, documents, tool loop, VC (original)
│   │   ├── AIModelsChangedTests.swift
│   │   ├── AIServiceTests.swift
│   │   ├── CoworkModeTests.swift
│   │   ├── DatabaseManagerTests.swift
│   │   ├── DocumentEquatableHashableTests.swift
│   │   ├── DocumentManagerTests.swift
│   │   ├── DoltVersionControlServiceTests.swift
│   │   ├── EncouragementServiceTests.swift
│   │   ├── ErrorPathTests.swift
│   │   ├── ExportTests.swift
│   │   ├── FocusSessionManagerTests.swift
│   │   ├── GiftCardBundleTests.swift
│   │   ├── GiftCardErrorTests.swift
│   │   ├── GiftCardManagerTests.swift
│   │   ├── HarnessTests.swift
│   │   ├── HermesModelsChangedTests.swift
│   │   ├── HermesModelsTests.swift
│   │   ├── IssueManagementTests.swift
│   │   ├── iPadProFeaturesTests.swift
│   │   ├── iPadProViewsTests.swift
│   │   ├── KanbanManagerTests.swift
│   │   ├── MetalDashboardTests.swift
│   │   ├── PerformanceTests.swift
│   │   ├── PluginTests.swift
│   │   ├── PRChangesCoworkTests.swift
│   │   ├── PRChangesTests.swift
│   │   ├── ProductivityAnalyticsTests.swift
│   │   ├── ScreenplaySceneTemplateTests.swift
│   │   ├── TemplateManagerTests.swift
│   │   ├── WritersAppCoworkTests.swift
│   │   ├── WritersAppPRChangesTests.swift
│   │   ├── WritersAppViewModelFormattingTests.swift
│   │   ├── WritingAdvisorTests.swift
│   │   ├── WritingGoalManagerTests.swift
│   │   └── (more)
│   └── MockerKitTests/
│       └── MockerKitTests.swift      # 57 tests for MockerKit
├── mobile/                           # React Native / Expo mobile app ("Jules")
│   ├── src/
│   │   ├── screens/                  # DocumentsScreen, KanbanScreen, GoalsScreen,
│   │   │                             #   TemplatesScreen, LoginScreen, SettingsScreen
│   │   └── context/                  # APIContext, AuthContext
│   ├── ios/Jules.xcodeproj           # iOS target
│   ├── android/                      # Android target
│   └── package.json                  # Expo 51 / React Native 0.74
├── examples/
│   ├── python_ai_service.py          # Python Anthropic SDK example
│   └── requirements.txt
├── scripts/
│   ├── unified_processor.py          # Trace processing
│   ├── analyze-traces.sh
│   └── requirements.txt
├── tests/
│   ├── test_session_start.sh         # Hook integration tests
│   └── test_firecrawl_skill_generator.py
├── .vscode/                          # VS Code configuration
├── .github/
│   └── workflows/
│       ├── swift.yml                 # Build + test on macOS (push to main/claude/**)
│       ├── ci.yml                    # Full CI/CD: backend, frontend, mobile
│       ├── codeql.yml                # Security analysis
│       └── jekyll-gh-pages.yml       # GitHub Pages deployment
├── .claude/
│   ├── project.md                    # Quick reference (commands, APIs, structure)
│   ├── workflow.md                   # ask → plan → execute workflow guide
│   ├── settings.json                 # Hooks + tool permissions
│   ├── hooks/
│   │   └── session-start.sh          # SessionStart hook — installs deps, builds
│   ├── agents/                       # Subagents (isolated workers)
│   │   ├── knowledge-advisor.md
│   │   ├── swift-code-reviewer.md
│   │   ├── swift-debugger.md
│   │   ├── template-designer.md
│   │   └── test-runner.md
│   ├── skills/                       # Reusable workflows
│   │   ├── add-template.md
│   │   ├── add-ai-feature.md
│   │   ├── add-version-control-op.md
│   │   ├── build-and-test.md
│   │   ├── firecrawl.md
│   │   └── generate-skill-from-url.md
│   └── knowledge/                    # Structured standards as JSON
│       ├── index.json
│       ├── swift.json
│       ├── architecture.json
│       ├── security.json
│       ├── templates.json
│       └── testing.json
├── .mcp.json                         # MCP server config (openbrowser, gemini)
├── .devcontainer/devcontainer.json   # Dev container configuration
├── .coderabbit.yaml                  # CodeRabbit AI review configuration
├── next.config.ts                    # Next.js web app config
├── package.json                      # Web app: "aims" (Next.js + Anthropic SDK + Neon DB)
├── Package.swift                     # SPM manifest (WritersApp, Mocker, ManpageOperator)
└── README.md
```

## Architecture Patterns

### Manager Pattern
- `TemplateManager`: Template lifecycle, 7 default templates
- `DocumentManager`: Document CRUD, search, and statistics
- `IssueManager`: Issue CRUD with status and priority transitions
- `KanbanManager`: Kanban boards, tasks, column-based workflow
- `WritingGoalManager`: Goal creation, progress tracking, streaks
- `FocusSessionManager`: Focus session lifecycle
- `CRMManager`: CRM contacts, deals, interactions (in-memory)
- `GiftCardManager`: Gift card bundles, redemption tracking (SQLite-backed)
- `HardwareManager`: Hardware board configurations and peripherals (in-memory)

### Service Pattern
- `AIService`: Anthropic API calls, tool loop, analysis
- `ChatbotService`: Session-based Jules chatbot with conversation trimming
- `ComputerUseService`: Anthropic computer use API wrapper
- `EncouragementService`: Milestone-aware motivational messages
- `GuiNewService`: gui.new API client for canvas/dashboard export
- `HermesService`: Creative ideation agent with idea parsing and stats
- `MultiAgentHarness`: Three-agent pipeline (planner → generator → evaluator)
- `ProductivityAnalytics`: Writing analytics aggregation
- `RagieService`: RAG document ingestion and semantic retrieval via Ragie API
- `SpoilerProtectionService`: Spoiler tagging, redaction, multi-format markup export
- `TraceAnalysisService`: Distributed trace analysis
- `WritingAdvisorService`: AI-powered personalized writing recommendations
- `DoltVersionControlService`: Branch/commit/diff/merge for documents

### Cowork Mode Services
Three services bundled in `CoworkService.swift`, exposed via `WritersApp`:
- `ProspectDatabase`: Writing prospect CRUD (in-memory)
- `BrowserService`: Web page browsing and research history
- `GmailService`: Gmail message reading/searching (optional, requires auth)

### Database Layer
- `DatabaseManager`: SQLite via `CSQLite`. Persists:
  - User sessions (`UserSession`)
  - AI suggestions (`AISuggestion`)
  - AI configuration per user
  - Issues (mirror of in-memory `IssueManager`)
  - Version control branches, commits, and document snapshots
  - Gift card bundles and individual gift cards

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

### Multi-Agent Harness
- `MultiAgentHarness` in `Services/MultiAgentHarness.swift` runs a three-agent pipeline
- **Planner** creates a `HarnessPlan` with per-section `SectionContract`s
- **Generator** writes each section against its contract
- **Evaluator** scores output and produces a `QualityReport`
- Entry point: `WritersApp` does not yet expose this via the facade; use the service directly

### Version Control
- Inspired by Dolt (Git semantics over document data)
- `VCBranch` → `VCCommit` → `[VCDocumentSnapshot]` linked chain
- Supports: `initializeDefaultBranch()`, `checkoutBranch()`, `commit()`, `log()`, `diff()`, `merge()`, `query(asOf:)` (time-travel), `history(of:)`
- Merge strategies: `.fastForward` and `.threeWay`
- Backed by `DatabaseManager` for durability

### Model Structure
- **Structs** for data: `Document`, `Template`, `AIConfiguration`, `Issue`, `KanbanTask`, `VCBranch`, `WritingGoal`, `AppSettings`, `SpoilerTag`, `HermesIdea`, `CRMContact`
- **Classes** for services: `WritersApp`, `TemplateManager`, `DocumentManager`, `AIService`, `DatabaseManager`, `IssueManager`, `KanbanManager`, `PluginManager`, `EncouragementService`, `CRMManager`, `GiftCardManager`
- **Enums** for types: See "Enum Reference" section below
- All entities have UUID `id` property (conform to `Identifiable`)

### SPM Targets
The `Package.swift` defines five products:

| Target | Type | Description |
|--------|------|-------------|
| `WritersApp` | Library | Main library; depends only on `CSQLite` (no other external deps) |
| `WritersAppCLI` | Executable | Interactive CLI; depends on `WritersApp` |
| `MockerKit` | Library | Container management library; depends on `Yams` |
| `mocker` | Executable | Docker-compatible CLI; depends on `MockerKit` + `ArgumentParser` |
| `manop` | Executable | Ubuntu manpage CLI; depends on `ArgumentParser` |

External dependencies: `swift-argument-parser` (≥1.3.0), `Yams` (≥5.0.0).

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
// Core managers (always available)
public let templateManager: TemplateManager
public let documentManager: DocumentManager
public let issueManager: IssueManager
public let kanbanManager: KanbanManager
public let hardwareManager: HardwareManager
public let databaseManager: DatabaseManager
public let pluginManager: PluginManager           // shared singleton
public let encouragementService: EncouragementService
public let versionControl: DoltVersionControlService
public let giftCardManager: GiftCardManager
public let crmManager: CRMManager
public let spoilerProtection: SpoilerProtectionService
public let prospectDatabase: ProspectDatabase     // Cowork mode
public let browserService: BrowserService         // Cowork mode

// Optional services (enabled on demand)
public private(set) var aiService: AIService?
public private(set) var chatbotService: ChatbotService?
public private(set) var hermesService: HermesService?
public private(set) var ragieService: RagieService?
public private(set) var writingAdvisorService: WritingAdvisorService?
public private(set) var guiService: GuiNewService?
public private(set) var gmailService: GmailService?   // Cowork mode
public private(set) var activeCoworkSession: CoworkSession?
public private(set) var currentUserId: UUID?

// Computed
public var isAIEnabled: Bool
public var isMemoryPluginEnabled: Bool
public var isRagieEnabled: Bool
public var isDarkModeEnabled: Bool
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

### Spoiler Protection
```swift
tagSpoiler(in:startOffset:endOffset:description:severity:) -> SpoilerTag?
removeSpoilerTag(id:)
getSpoilerTags(forDocument:) -> [SpoilerTag]
documentHasSpoilers(_:) -> Bool
redactedContent(forDocument:) -> String?
exportDocumentWithSpoilerMarkup(id:format:) -> String?   // .markdown, .html, .custom
```

### Ragie Integration (RAG)
```swift
enableRagie(configuration: RagieConfiguration)
disableRagie()
isRagieEnabled: Bool

ingestDocumentToRagie(documentId:) async throws -> RagieDocument
getRagieDocumentStatus(ragieId:) async throws -> RagieDocument
retrieveFromRagie(query:limit:) async throws -> [RagieChunk]
listRagieDocuments() async throws -> [RagieDocument]
```

### Hermes Creative Ideation
```swift
startHermesSession(context:) throws -> HermesSession
generateIdeas(topic:session:count:) async throws -> [HermesIdea]
expandIdea(_:session:) async throws -> HermesIdea
endHermesSession()
getAllIdeas(from:filteredBy:) -> [HermesIdea]
getHermesSessionStats(from:) -> HermesSessionStats?
```

### App Settings
```swift
getAppSettings() -> AppSettings
toggleDarkMode()
setDarkMode(_:)
setTheme(_: AppTheme)
setFontSize(_: Int)
setDefaultWordCountGoal(_: Int?)
setSpellCheckEnabled(_:)
setGrammarCheckEnabled(_:)
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

### Spoiler Protection
```swift
SpoilerSeverity:    mild, moderate, major, critical
SpoilerMarkupFormat: markdown, html, custom
```

### Hermes
```swift
HermesIdeaType: concept, character, plot, setting, theme, dialogue, title, custom
```

### App Settings
```swift
AppTheme: system, light, dark, solarized, nord, dracula
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
GiftCardError:    bundleNotFound, cardNotFound, cardAlreadyRedeemed, cardExpired,
                  invalidAmount, insufficientBalance
RagieError:       ragieNotEnabled, documentNotFound, ingestionFailed, retrievalFailed
```

## AI Integration

### Claude Models Supported

| Model | Best For | Context | Performance |
|-------|----------|---------|-------------|
| **Claude 3.5 Sonnet** | General-purpose, most cost-effective | 200K tokens | Excellent balance of speed/quality |
| **Claude 3 Opus** | Complex reasoning, long documents | 200K tokens | Highest reasoning power |
| **Claude 3 Sonnet** | Fast responses, real-time features | 200K tokens | Good speed/quality ratio |
| **Claude 3 Haiku** | Lightweight, low-latency tasks | 200K tokens | Fastest, lowest cost |

See [MYTHOS.md](MYTHOS.md) for information on extended model capabilities used in this project.

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

316+ test functions across 35 test files in `Tests/WritersAppTests/` plus `Tests/MockerKitTests/`.

Run with: `swift test`

| Test File | Coverage Area |
|-----------|---------------|
| `WritersAppTests.swift` | Core: templates, documents, tool loop, version control |
| `AIServiceTests.swift` | AI assistance types, response parsing |
| `AIModelsChangedTests.swift` | Tool loop model changes |
| `CoworkModeTests.swift` / `WritersAppCoworkTests.swift` / `PRChangesCoworkTests.swift` | Cowork mode |
| `DatabaseManagerTests.swift` | SQLite persistence |
| `DocumentManagerTests.swift` / `DocumentEquatableHashableTests.swift` | Document CRUD |
| `DoltVersionControlServiceTests.swift` | Branches, commits, diffs, merges, time-travel |
| `EncouragementServiceTests.swift` | Milestone messages |
| `ErrorPathTests.swift` | Error handling edge cases |
| `ExportTests.swift` | Markdown/HTML/plaintext export |
| `FocusSessionManagerTests.swift` | Focus session lifecycle |
| `GiftCardBundleTests.swift` / `GiftCardManagerTests.swift` / `GiftCardErrorTests.swift` | Gift cards |
| `HarnessTests.swift` | Multi-agent harness pipeline |
| `HermesModelsTests.swift` / `HermesModelsChangedTests.swift` | Creative ideation |
| `iPadProFeaturesTests.swift` / `iPadProViewsTests.swift` | iPad Pro features |
| `IssueManagementTests.swift` | Issue CRUD, status/priority |
| `KanbanManagerTests.swift` | Kanban boards and task workflow |
| `MetalDashboardTests.swift` | Metal rendering dashboard |
| `PerformanceTests.swift` | Performance benchmarks |
| `PluginTests.swift` | Plugin protocol, memory plugin |
| `PRChangesTests.swift` / `WritersAppPRChangesTests.swift` | PR-specific regression tests |
| `ProductivityAnalyticsTests.swift` | Writing analytics |
| `ScreenplaySceneTemplateTests.swift` | Screenplay template |
| `TemplateManagerTests.swift` | Template CRUD, defaults |
| `WritingAdvisorTests.swift` | Writing advisor recommendations |
| `WritingGoalManagerTests.swift` | Goal tracking, streaks |
| `WritersAppViewModelFormattingTests.swift` | View model formatting |
| `MockerKitTests.swift` | Container management (57 tests) |

## Environment Variables

| Variable | Purpose |
|----------|---------|
| `ANTHROPIC_API_KEY` | Claude API key for AI features |
| `GEMINI_API_KEY` | Gemini API key for MCP gemini server |
| `CLAUDE_PROJECT_DIR` | Project root (set by session-start hook) |

## Claude Code Extensions

The `.claude/` directory organises all Claude Code extensions for this project.

```
.claude/
├── project.md             # Quick reference guide
├── workflow.md            # ask → plan → execute workflow
├── settings.json          # Hooks registration + tool permissions
├── hooks/
│   └── session-start.sh   # SessionStart hook — installs deps, builds
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
│   ├── firecrawl.md
│   └── generate-skill-from-url.md
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
| `build-and-test` | Building the project and running the full test suite |
| `add-version-control-op` | Extending `DoltVersionControlService` with new operations |
| `firecrawl` | Scraping URLs, searching the web, crawling sites, or browsing interactive pages |
| `generate-skill-from-url` | Generating a new skill definition from a URL |

## MCP Servers

Configured in `.mcp.json`:

| Server | Transport | Purpose |
|--------|-----------|---------|
| `openbrowser` | stdio (`uvx openbrowser-ai[mcp] --mcp`) | Headless browser automation |
| `gemini` | stdio (`npx @rlabs-inc/gemini-mcp`) | Gemini AI model access; requires `GEMINI_API_KEY` |

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
5. Add CLI option in `main.swift` if applicable
6. Add test coverage

### Adding a New Export Format
1. Add case to `ExportFormat` enum in `WritersApp.swift`
2. Implement conversion in `exportDocument()` method
3. Update tests

### Modifying Document/Template Models
1. Update struct in `Models/` directory
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

### Working on MockerKit / Mocker CLI
- Library: `Sources/MockerKit/` — `ContainerEngine` is an actor delegating to Apple's container CLI
- CLI: `Sources/Mocker/Commands/` — uses `ArgumentParser` subcommands
- Tests: `Tests/MockerKitTests/MockerKitTests.swift`
- Build: `swift build --target mocker` / `swift run mocker <subcommand>`
- Note: `MockerKit` depends on `Yams` for Docker Compose file parsing

### Working on ManpageOperator
- Source: `Sources/ManpageOperator/main.swift`
- Subcommands: `show`, `search`, `whatis`, `list`, `sections`
- Build: `swift build --target manop` / `swift run manop <subcommand>`

### Working on the Mobile App
- Location: `mobile/` — React Native / Expo 51
- App name: Jules (iOS target `Jules.xcodeproj`)
- Screens: Documents, Kanban, Goals, Templates, Login, Settings
- Context providers: `APIContext` (server URL), `AuthContext` (user auth)
- Build: `cd mobile && npx expo start`

### Working on the Web App (AIMS)
- Location: project root — Next.js 14 with TypeScript
- Package name: `aims`; scripts: `dev`, `build`, `start`, `test`
- Key deps: `@anthropic-ai/sdk`, `@neondatabase/serverless`, `next`, `zod`, `winston`
- Build: `npm run dev` / `npm run build`

## Files to Avoid Modifying Without Care

- `Package.swift` — Changes affect all targets; `CSQLite` system library must remain; external deps for Mocker must stay pinned
- `.vscode/` — VS Code settings for cross-device development
- `Tests/` — Ensure tests pass after changes
- `Sources/WritersApp/Views/` — Metal/SwiftUI views with platform-specific rendering code
- `Sources/WritersApp/Plugins/` — Plugin infrastructure; changes may break MCP integration
- `Sources/WritersApp/Services/DatabaseManager.swift` — Schema changes require migration strategy
- `Sources/MockerKit/Container/ContainerEngine.swift` — Actor isolation; changes affect thread safety

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
- `WritersApp` initializer wires `ChatbotService`, `HermesService`, and `WritingAdvisorService` automatically when `aiConfiguration` is provided
- Ragie requires a separate `enableRagie(configuration:)` call after init
- `GiftCardManager` is SQLite-backed (unlike most managers which are in-memory)
- `CRMManager` is in-memory only (no SQLite persistence)
- `MultiAgentHarness` is not exposed via the `WritersApp` facade — use the service directly

## CI/CD

### GitHub Actions Workflows

| Workflow | Trigger | What it does |
|----------|---------|--------------|
| `swift.yml` | Push to `main`/`claude/**`; PR to `main` | `swift build -v && swift test -v` on `macos-latest` |
| `ci.yml` | Push to `main`/`develop`/`claude/**`; PRs | Backend + frontend + mobile build and test |
| `codeql.yml` | Schedule + push | CodeQL security analysis |
| `jekyll-gh-pages.yml` | Push to `main` | GitHub Pages deployment |

All PRs to `main` must pass the Swift CI workflow before merging.

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
- Branch naming: descriptive feature names (e.g., `claude/add-feature-name`, `copilot/add-feature-name`)
- Keep commits focused and well-described
- CI runs automatically on push to `claude/**` branches
