# AGENTS.md

## Setup commands
- Build: `swift build`
- Build release: `swift build -c release`
- Run tests: `swift test`
- Run CLI: `swift run WritersAppCLI`
- Clean: `swift package clean`

## Code style
- Swift 5.9+, macOS 13+ / iOS 16+
- Use `async throws` for AI operations
- Structs for data models, classes for services/managers
- All models conform to `Codable` and `Identifiable`
- Use `// MARK: - Section Name` for code organization
- Methods use verbs: `createDocument`, `improveText`
- No external dependencies — Swift standard library only
