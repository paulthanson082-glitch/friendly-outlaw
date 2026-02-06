# CLAUDE.md — friendly-outlaw

## Project Overview

friendly-outlaw is a Swift-based Writers App with AI-powered writing assistance, template management, and a plugin system with Claude Memory support.

- **Platform**: macOS 13+, iOS 16+
- **Swift**: 5.9+
- **Package Manager**: Swift Package Manager

## Quick Commands

```bash
# Build
swift build
swift build -c release

# Test
swift test
swift test --verbose

# Run CLI
swift run WritersAppCLI

# Run with AI features
export ANTHROPIC_API_KEY="<your-key>"
swift run WritersAppCLI

# Clean
swift package clean
```

## Project Structure

```
Sources/
├── WritersApp/
│   ├── Models/           # Template, Document, AIModels
│   ├── Services/         # TemplateManager, DocumentManager, AIService
│   ├── Plugins/          # Plugin system and Claude Memory plugin
│   │   ├── Plugin.swift            # Plugin protocol and types
│   │   ├── PluginManager.swift     # Plugin lifecycle management
│   │   ├── ClaudeMemoryPlugin.swift # Persistent memory storage
│   │   └── MCPClient.swift         # MCP protocol support
│   ├── Extensions/
│   └── WritersApp.swift  # Main app entry point
└── WritersAppCLI/
    └── main.swift        # CLI interface
Tests/
└── WritersAppTests/      # Unit tests including PluginTests.swift
```

## Plugin System

The app includes a plugin architecture with MCP (Model Context Protocol) support. The built-in **Claude Memory Plugin** provides persistent memory storage for AI interactions.

### Key Plugin APIs

```swift
// Enable memory plugin
app.enableMemoryPlugin()

// Store/retrieve/search memories
app.storeMemory(key:value:category:tags:importance:)
app.retrieveMemory(key:)
app.searchMemories(query:category:limit:)
app.listMemories(category:limit:sortBy:)
app.clearMemory(key:category:)
app.getMemoryStats()

// Plugin management
app.getPlugins()
app.getEnabledPlugins()
app.shutdownPlugins()
```

### Plugin Capabilities

Plugins can declare: `memory`, `tools`, `resources`, `prompts`, `sampling`, `logging`, `custom_actions`

## Architecture Patterns

- **Manager pattern**: TemplateManager, DocumentManager, PluginManager
- **Service pattern**: AIService for Anthropic API operations
- **Protocol-based plugins**: All plugins conform to the `Plugin` protocol
- **Async/await**: All AI and plugin operations are `async throws`

## Guidelines

- Never commit API keys or secrets
- Use `ANTHROPIC_API_KEY` environment variable for AI features
- Run `swift test` before committing changes
- See `docs/AI_ASSISTANT_GUIDE.md` for detailed contributor guide
