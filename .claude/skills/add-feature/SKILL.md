---
name: add-feature
description: Add a new feature to friendly-outlaw (template, service, model, or AI capability)
disable-model-invocation: false
argument-hint: [feature-type] [description]
---

# Add Feature to friendly-outlaw

Implement a new feature following the project's architecture patterns and conventions.

## Feature types

- **template**: Add a new writing template with placeholders and category
- **service**: Add a new manager or service class (e.g., new issue tracking feature)
- **model**: Add a new data model or extend existing ones
- **ai-feature**: Add a new AI-powered capability or assistance type
- **export**: Add support for a new export format

## General workflow

1. **Research**: Read relevant files and understand patterns in the codebase
2. **Plan**: Determine what files to create/modify and any dependencies
3. **Implement**: Follow project conventions (naming, async/await, Codable)
4. **Test**: Add test cases covering the new functionality
5. **Integrate**: Wire up the new feature in WritersApp facade if needed
6. **Review**: Check against knowledge base standards (run knowledge-advisor)
7. **Commit**: Create a focused commit with clear message

## Before you start

- Consult `.claude/knowledge/` files relevant to your change
- Use the knowledge-advisor agent if unsure about conventions
- Read existing similar implementations as templates
- Check the CLAUDE.md "Common Tasks" section for step-by-step guides

## Files you'll likely modify

- `Sources/WritersApp/Models/` - Data structures
- `Sources/WritersApp/Services/` - Business logic
- `Sources/WritersApp/WritersApp.swift` - Facade/public API
- `Sources/WritersAppCLI/main.swift` - CLI integration (if applicable)
- `Tests/WritersAppTests/WritersAppTests.swift` - Test coverage

## Architecture reminders

- Use `// MARK: - Section` for code organization
- Methods use verbs: `createX`, `updateX`, `deleteX`
- All entities have UUID `id` and conform to `Identifiable`
- Async operations use `async throws` with typed error enums
- Managers are classes, models are structs
- No external dependencies beyond CSQLite

## Post-implementation checklist

- [ ] Code follows Swift naming conventions
- [ ] Async operations properly typed with errors
- [ ] Models conform to Codable where appropriate
- [ ] Database persistence added if stateful
- [ ] Tests added for new functionality
- [ ] CLI support added if user-facing
- [ ] CLAUDE.md updated if adding new public APIs
