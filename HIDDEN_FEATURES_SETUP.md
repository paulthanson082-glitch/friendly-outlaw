# 15 Hidden Advanced Features - Setup Guide

This guide shows how to enable and use all 15 advanced features in friendly-outlaw.

## Prerequisites
```bash
export ANTHROPIC_API_KEY="sk-ant-..."
swift build -c release
swift run WritersAppCLI
```

---

## GROUP 1: AI & KNOWLEDGE (Features 1-3)

### 1. **Ragie Integration** (Semantic Document Retrieval)
Enable semantic search across your documents:

```swift
import WritersApp

let app = WritersApp()

// Configure Ragie
let ragieConfig = RagieConfiguration(
    apiKey: "your-ragie-api-key",
    apiUrl: "https://api.ragie.ai",
    chunkSize: 1024,
    overlapSize: 200
)
app.enableRagie(configuration: ragieConfig)

// Ingest a document
let ragieDoc = try await app.ingestDocumentToRagie(documentId: docUUID)
print("Ingested with Ragie ID: \(ragieDoc.ragieId)")

// Check processing status
let status = try await app.getRagieDocumentStatus(ragieId: ragieDoc.ragieId)
print("Ready: \(status.isReady)")

// Query semantically
let results = try await app.queryRagie(query: "writing techniques", topK: 5)
results.forEach { chunk in
    print("• \(chunk.content)")
}
```

### 2. **Chatbot Service** (Multi-turn Conversations)
AI conversations with document context:

```swift
// Already enabled when you enableAI()
let config = AIConfiguration(apiKey: apiKey, model: .claude35Sonnet)
app.enableAI(configuration: config, userId: userId)

// The chatbot service is now active
guard let chatbot = app.chatbotService else { return }

// Have a conversation
let response = try await chatbot.chat(
    message: "Help me improve this character",
    documentId: docUUID,
    conversationContext: previousMessages
)
print(response)
```

### 3. **Claude Memory Plugin** (Persistent AI Context)
Store and retrieve memories across sessions:

```swift
// Enable memory plugin
try await app.enableMemoryPlugin()

// Store a memory
try await app.storeMemory(
    key: "protagonist_name",
    value: "Elena Voss",
    category: "characters",
    tags: ["fantasy", "hero"],
    importance: 0.9
)

// Retrieve memory
let name = try await app.retrieveMemory(key: "protagonist_name")

// Search memories
let allCharacters = try await app.searchMemories(
    query: "character descriptions",
    category: "characters",
    limit: 10
)

// Get stats
let stats = try await app.getMemoryStats()
print("Total memories: \(stats["total_memories"])")
```

---

## GROUP 2: PRODUCTIVITY TRACKING (Features 4-7)

### 4. **Focus Session Manager** (Distraction-Free Mode)
Track and manage focused writing sessions:

```swift
let focusManager = FocusSessionManager()

// Start a focus session
var session = focusManager.startFocusSession(
    documentId: docUUID,
    targetWords: 1000,
    mode: .timeBased(durationMinutes: 25)
)
print("Focus session started: \(session.id)")

// Update session as you write
focusManager.updateSessionProgress(
    sessionId: session.id,
    currentWordCount: 250
)

// End session
focusManager.endFocusSession(sessionId: session.id)

// Get insights
let insights = focusManager.getSessionInsights(sessionId: session.id)
print("Productivity: \(insights.wordsPerMinute) WPM")
```

### 5. **Writing Goal Manager** (Streaks & Milestones)
Track writing goals with streak tracking:

```swift
let goalManager = WritingGoalManager()

// Create a goal
let goal = goalManager.createGoal(
    title: "Novel Writing",
    type: .monthly,
    targetValue: 50000,
    unit: .words
)

// Log progress
goalManager.logProgress(goalId: goal.id, value: 5000)

// Check streak
let streak = goalManager.getCurrentStreak(userId: userUUID)
print("Current streak: \(streak.consecutiveDays) days")

// Get milestones
let milestones = goalManager.getMilestones(goalId: goal.id)
milestones.forEach { milestone in
    print("✓ \(milestone.name) at \(milestone.targetValue) \(milestone.unit)")
}
```

### 6. **Encouragement Service** (AI Motivation)
Get personalized motivational messages:

```swift
let encouragement = app.encouragementService

// Milestone-aware encouragement
let msg1 = encouragement.getEncouragementForDocument(
    doc,
    previousWordCount: 1000
)
print("📝 \(msg1?.message)")

// Session-based encouragement
let msg2 = encouragement.getSessionEncouragement(
    durationMinutes: 45,
    wordsWritten: 2000
)
print("⏱️  \(msg2?.message)")

// Generic motivation
let msg3 = encouragement.getGeneralEncouragement()
print("💪 \(msg3.message)")
```

### 7. **Productivity Analytics** (Performance Tracking)
Deep insights into your writing patterns:

```swift
let analytics = ProductivityAnalytics()

// Get comprehensive stats
let stats = app.getStatistics()
print("Total documents: \(stats.documentCount)")
print("Average reading time: \(stats.averageReadingTime)")

// AI tool usage (track how often you use AI)
let toolStats = try app.databaseManager.getAIToolUsageStats(userId: userUUID)
toolStats.forEach { stat in
    print("\(stat.toolName): \(stat.usageCount) calls")
}

// Session statistics
let sessionStats = try app.databaseManager.getSessionStats(userId: userUUID)
print("Total session time: \(sessionStats.totalDuration) minutes")
```

---

## GROUP 3: PLATFORM-SPECIFIC (Features 8-11)

### 8. **Apple Pencil Manager** (iOS/iPad Input)
Handle Apple Pencil input and gestures:

```swift
let pencilManager = ApplePencilManager()

// Check if pencil is available
if pencilManager.isPencilAvailable() {
    print("Apple Pencil detected")

    // Handle pencil input
    pencilManager.onPencilInput { input in
        print("Pressure: \(input.pressure)")
        print("Position: \(input.location)")
    }
}

// Register custom gestures
pencilManager.registerGesture(
    name: "quickNote",
    trigger: .doubleTap,
    action: { _ in
        // Create quick note
    }
)
```

### 9. **Multitasking Manager** (iPadOS Split-View)
Handle iPad multitasking and split-screen:

```swift
let multitaskingManager = MultitaskingManager()

// Detect current mode
let mode = multitaskingManager.getCurrentMultitaskingMode()
print("Current mode: \(mode.description)")

// Respond to size changes
multitaskingManager.onSizeChange { newSize in
    print("New size: \(newSize)")
    // Adapt UI accordingly
}

// Handle app state transitions
multitaskingManager.onMultitaskingStateChange { state in
    if case .splitViewActive = state {
        print("Split-view is active")
    }
}
```

### 10. **Stage Manager Support** (iPadOS 17+ Window Mgmt)
Advanced window management:

```swift
let stageManager = StageManagerSupport()

// Check if available
if stageManager.isStageManagerSupported() {
    // Create managed window
    stageManager.createManagedWindow(
        title: "Writing Session",
        initialSize: CGSize(width: 600, height: 800)
    )

    // Monitor stage changes
    stageManager.onStageChange { stage in
        print("Stage: \(stage.description)")
    }
}
```

### 11. **Keyboard Shortcut Manager** (Custom Bindings)
Set up custom keyboard shortcuts:

```swift
let keyboardManager = KeyboardShortcutManager()

// Register shortcuts
keyboardManager.register(
    keys: [.command, .option, .n],
    action: "newDocument"
)

keyboardManager.register(
    keys: [.command, .shift, .s],
    action: "saveDocument"
)

// Listen for shortcuts
keyboardManager.onShortcutTriggered { action in
    switch action {
    case "newDocument":
        print("Creating new document")
    case "saveDocument":
        print("Saving document")
    default:
        break
    }
}
```

---

## GROUP 4: ADVANCED ARCHITECTURE (Features 12-15)

### 12. **Plugin System + MCP Client** (Extensibility)
Load and manage plugins:

```swift
// Memory plugin (built-in)
try await app.enableMemoryPlugin()

// Register custom plugin
class MyCustomPlugin: Plugin {
    func initialize() async throws {
        print("Plugin initialized")
    }

    func shutdown() async throws {
        print("Plugin shutdown")
    }

    func execute(action: PluginAction) async throws -> String {
        return "Action executed"
    }
}

let plugin = MyCustomPlugin()
try await app.pluginManager.registerPlugin(plugin)

// MCP Client for external services
let mcp = MCPClient(
    config: MCPServerConfig(
        name: "my-mcp-server",
        transport: "stdio",
        command: "/path/to/server",
        args: []
    )
)
try await mcp.initialize()
```

### 13. **Dolt Version Control** (Git for Documents)
Full version control for your writing:

```swift
let vc = app.versionControl

// Initialize
try vc.initializeDefaultBranch()

// Create branches
try vc.createBranch(name: "chapter-3-revisions", fromBranch: "main")

// Commit changes
try vc.commit(
    message: "Rewrote opening scene",
    author: "You",
    changes: [documentSnapshot]
)

// View history
let commits = try vc.log(branchName: "main")
commits.forEach { commit in
    print("• \(commit.message) by \(commit.author)")
}

// See differences
let diff = try vc.diff(branchA: "main", branchB: "chapter-3-revisions")
diff.forEach { change in
    print("\(change.changeType): \(change.title)")
}

// Merge branches
let result = try vc.merge(
    sourceBranch: "chapter-3-revisions",
    targetBranch: "main",
    strategy: .threeWay
)

// Time-travel: query state at a specific date
let pastState = try vc.query(asOf: Date(timeIntervalSinceNow: -86400)) // 1 day ago
```

### 14. **Trace Analysis Service** (Performance Debugging)
Distributed tracing for debugging:

```swift
let traceService = TraceAnalysisService()

// Create a trace
let trace = Trace(
    traceId: UUID().uuidString,
    events: [
        TraceEvent(name: "document_load", timestamp: Date()),
        TraceEvent(name: "ai_call", timestamp: Date()),
        TraceEvent(name: "document_save", timestamp: Date())
    ]
)

// Record spans
let span = TraceSpan(
    name: "improveText",
    startTime: Date(),
    endTime: Date(),
    duration: 1.2
)

// Analyze performance
let analysis = traceService.analyze(trace: trace)
print("Critical path: \(analysis.criticalPath)")
print("Total duration: \(analysis.totalDuration)ms")
```

### 15. **Hardware Manager** (Device Optimization)
Detect and optimize for hardware:

```swift
let hardware = app.hardwareManager

// Check hardware capabilities
if hardware.hasGPUAcceleration() {
    print("✓ GPU acceleration available")
    hardware.enableGPURendering()
}

// Memory-aware optimization
let availableMemory = hardware.getAvailableMemory()
if availableMemory < 512 * 1024 * 1024 { // < 512MB
    hardware.enableLowMemoryMode()
}

// CPU cores
let cores = hardware.getCPUCoreCount()
print("Available cores: \(cores)")

// Device type
if hardware.isIPad() {
    print("Optimizing for iPad")
    hardware.enableIPadOptimizations()
}
```

---

## 🔧 CLI Commands to Try

```bash
# Standard startup
swift run WritersAppCLI

# With Ragie enabled
RAGIE_API_KEY="..." swift run WritersAppCLI

# With alternative LLM provider (via Clother)
clother-ollama swift run WritersAppCLI

# Focus mode
swift run WritersAppCLI --focus 25  # 25 min Pomodoro

# Trace analysis
swift run WritersAppCLI --trace

# GUI export
swift run WritersAppCLI --gui

# List all documents with stats
swift run WritersAppCLI --list
```

---

## 📊 Full Feature Matrix

| Feature | Type | Setup Time | Power |
|---------|------|-----------|-------|
| 1. Ragie | Knowledge | 5 min | ⭐⭐⭐⭐⭐ |
| 2. Chatbot | AI | 1 min | ⭐⭐⭐⭐⭐ |
| 3. Memory Plugin | Storage | 2 min | ⭐⭐⭐⭐ |
| 4. Focus Sessions | Productivity | 1 min | ⭐⭐⭐⭐ |
| 5. Writing Goals | Tracking | 2 min | ⭐⭐⭐⭐ |
| 6. Encouragement | Motivation | 1 min | ⭐⭐⭐ |
| 7. Analytics | Insights | 1 min | ⭐⭐⭐⭐ |
| 8. Apple Pencil | Input | N/A* | ⭐⭐⭐ |
| 9. Multitasking | Platform | N/A* | ⭐⭐⭐ |
| 10. Stage Manager | Platform | N/A* | ⭐⭐⭐ |
| 11. Keyboard Mgr | Input | 3 min | ⭐⭐⭐ |
| 12. Plugins + MCP | Extension | 5 min | ⭐⭐⭐⭐⭐ |
| 13. Dolt VC | Version Ctrl | 2 min | ⭐⭐⭐⭐⭐ |
| 14. Trace Analysis | Debug | 3 min | ⭐⭐⭐⭐ |
| 15. Hardware Mgr | Optimization | 1 min | ⭐⭐⭐ |

*iOS/iPad only — auto-enabled when available

---

## Environment Variables Reference

```bash
# AI / LLM
export ANTHROPIC_API_KEY="sk-ant-..."          # Anthropic Claude
export ANTHROPIC_BASE_URL="https://..."        # Custom LLM endpoint (via Clother)

# Ragie
export RAGIE_API_KEY="..."
export RAGIE_API_URL="https://api.ragie.ai"

# Plugins
export MCP_SERVER_STDIO="/path/to/server"      # MCP stdio server
export MCP_SERVER_HTTP="http://localhost:3000" # MCP HTTP server

# Database
export WRITERS_APP_DB_PATH="/custom/path/db"   # Custom SQLite path

# Features
export ENABLE_GPU_RENDERING="1"
export ENABLE_LOW_MEMORY_MODE="1"
```

---

## Next Steps

1. **Start with #2 (Chatbot)** — Enables core AI features
2. **Add #3 (Memory)** — Persistent context across sessions
3. **Enable #5 (Writing Goals)** — Track progress
4. **Try #13 (Dolt VC)** — Version control for documents
5. **Integrate #1 (Ragie)** — Semantic search at scale

---

**Happy writing! 🚀**
