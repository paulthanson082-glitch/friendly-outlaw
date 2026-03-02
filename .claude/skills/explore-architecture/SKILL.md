---
name: explore-architecture
description: Explore the friendly-outlaw architecture, find files, understand patterns
disable-model-invocation: false
argument-hint: [what-to-explore]
---

# Explore friendly-outlaw Architecture

Use this skill to navigate, understand, and document the codebase structure.

## What you can explore

- **models**: Data structures and entities (UUID-based, Codable)
- **services**: Business logic managers and service classes
- **plugins**: Plugin system, MCP client, capabilities
- **ai-integration**: Claude API integration, tool loop, AI features
- **database**: SQLite persistence via DatabaseManager
- **version-control**: Dolt-inspired branching, commits, merges, time-travel
- **errors**: Custom error types and handling patterns
- **testing**: Test organization and patterns
- **templates**: Built-in templates, placeholders, categories

## Research approach

1. **Identify files**: Use Glob patterns to find relevant source files
2. **Read examples**: Look at existing similar implementations
3. **Map patterns**: Identify naming conventions, structure, dependencies
4. **Document**: Summarize findings with file references and line numbers
5. **Create summary**: Provide patterns and guidelines for similar work

## Key directories

```
Sources/WritersApp/
├── Models/           - Data structures (Template, Document, Issue, etc.)
├── Services/         - Business logic (18+ manager/service classes)
├── Plugins/          - Plugin architecture and MCP client
├── Views/            - SwiftUI views (Metal dashboard, iPad views)
└── Extensions/       - String and CoreGraphics utilities
```

## Common patterns to look for

- **Manager pattern**: How do TemplateManager, DocumentManager, etc. work?
- **Service pattern**: How do AIService, DatabaseManager integrate?
- **Error handling**: What error types exist and how are they used?
- **Async/await**: How are async operations structured?
- **Codable conformance**: Which models implement serialization?
- **Database persistence**: How does DatabaseManager layer work?
- **Plugin execution**: How does plugin lifecycle work?

## Output format

When exploring, provide:
- List of relevant files (with line numbers where applicable)
- Key patterns and conventions
- Example code snippets showing patterns
- Recommendations for similar work
