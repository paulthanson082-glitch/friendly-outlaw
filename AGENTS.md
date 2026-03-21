# AI Agents — friendly-outlaw

This document describes the AI agent system used in the friendly-outlaw Swift writers app. Agents are specialized subprocesses invoked by Claude Code to handle isolated tasks without consuming the main session context.

## Quick Reference

| Agent | Command | When to Use |
|-------|---------|-------------|
| `knowledge-advisor` | Delegate before any code change | Retrieve applicable project standards |
| `swift-code-reviewer` | Delegate after editing `.swift` files | Code quality, conventions, correctness |
| `swift-debugger` | Delegate on build/test failures | Diagnose and fix Swift errors |
| `template-designer` | Delegate for template work | Design or review writing templates |
| `test-runner` | Delegate to check tests | Get a concise pass/fail summary |

## Setup Commands

```bash
swift build              # Debug build
swift build -c release   # Release build
swift test               # Run all tests
swift run WritersAppCLI  # Run CLI app
swift package clean      # Remove build artifacts
```

## Agent Definitions

Agents live in `.claude/agents/`. Each file has a YAML front-matter block followed by the system prompt.

```
.claude/agents/
├── knowledge-advisor.md
├── swift-code-reviewer.md
├── swift-debugger.md
├── template-designer.md
└── test-runner.md
```

### Front-Matter Fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | yes | Identifier used when invoking the agent |
| `description` | yes | One-line summary shown in agent listings |
| `tools` | yes | Comma-separated list of tools the agent may call |
| `model` | no | Model override (`haiku`, `sonnet`, `opus`). Inherits from parent if omitted |

### Available Tools

Tools that agents can be granted:

| Tool | Purpose |
|------|---------|
| `Read` | Read files from disk |
| `Edit` | Apply targeted string replacements to files |
| `Write` | Create or overwrite files |
| `Glob` | Find files by name pattern |
| `Grep` | Search file contents with regex |
| `Bash` | Execute shell commands |

---

## Agent Details

### knowledge-advisor

**File**: `.claude/agents/knowledge-advisor.md`
**Model**: `haiku`
**Tools**: `Read`, `Glob`

Reads the structured knowledge base in `.claude/knowledge/` and returns every standard that applies to the described task. Use it **before** writing or modifying any Swift source file.

**When to invoke:**
- Before adding a new feature, template, AI capability, or service method
- Before touching security-sensitive paths (API keys, network, user input)
- Whenever you are unsure which architectural patterns apply

**Knowledge base files:**

| File | Covers |
|------|--------|
| `index.json` | Category index and file map |
| `swift.json` | Naming, optionals, async/await, Codable, no-external-deps |
| `architecture.json` | Manager/service layers, how-to steps for common tasks |
| `security.json` | No hardcoded secrets, input sanitisation, network policy |
| `templates.json` | Placeholder format, count, descriptions, categories |
| `testing.json` | What to test, naming conventions, AI method approach |

**Example delegation:**
> "I am about to add a new async method to AIService for generating chapter outlines. What standards apply?"

The agent returns a structured rule list plus a pre-commit checklist.

---

### swift-code-reviewer

**File**: `.claude/agents/swift-code-reviewer.md`
**Model**: `sonnet`
**Tools**: `Read`, `Grep`, `Glob`, `Bash`

Reviews Swift source files for quality, correctness, and adherence to project conventions. Invoke it after modifying any `.swift` file in `Sources/`.

**Review areas:**

- **Correctness** — logic errors, force-unwraps, missing `throws`/`await`/`try`, Codable breakage
- **Swift conventions** — `MARK` sections, public-before-private order, verb-named methods
- **Performance & safety** — unnecessary copies, retain cycles, main-thread blocking
- **Project-specific rules** — AI methods must be `async throws`, no hardcoded API keys, `{{snake_case}}` placeholders

**Output format:**

```
Critical   — must fix before merging (file:line + corrected code)
Warnings   — should fix
Suggestions — consider improving
[one-line overall verdict]
```

---

### swift-debugger

**File**: `.claude/agents/swift-debugger.md`
**Model**: `sonnet`
**Tools**: `Read`, `Edit`, `Bash`, `Grep`, `Glob`

Diagnoses build errors, runtime crashes, test failures, and unexpected behavior, then applies the minimal fix.

**Debugging workflow:**

1. **Reproduce** — run `swift build 2>&1` or `swift test 2>&1`
2. **Diagnose** — read the reported file/line, check recent `git diff HEAD`, review call sites
3. **Fix** — apply the smallest targeted change; prefer `if let`/`guard let` over `!`
4. **Verify** — confirm `swift build` and `swift test` both pass

**Common root causes in this codebase:**

| Symptom | Likely Cause |
|---------|-------------|
| Crash on optional | Force-unwrap `!` on dictionary lookup or `first(where:)` |
| Compile error on async call | Missing `await` or `try` |
| JSON decode failure | New `Codable` property without `CodingKeys` update |
| Template renders literal `{{key}}` | Placeholder key missing from `Placeholder` structs |
| Linux build failure | Missing `#if canImport(FoundationNetworking)` guard |

**Output format:**

```
Root cause: <one sentence>

Fix applied:
  File: <path>:<line>
  Change: <brief description>

Verification:
  Build: PASS / FAIL
  Tests: N/N passed / N failures
```

---

### template-designer

**File**: `.claude/agents/template-designer.md`
**Model**: `sonnet`
**Tools**: `Read`, `Edit`, `Grep`, `Glob`

Designs and implements writing templates in `TemplateManager.swift`. Use it when adding a new template or auditing existing ones for placeholder consistency.

**Template structure:**

```swift
Template(
    id: UUID(),
    name: "Template Name",
    description: "Brief description for writers",
    category: .blogPost,
    content: """
    # {{title}}

    {{introduction}}
    """,
    placeholders: [
        Placeholder(key: "title", description: "The document title", defaultValue: "My Title"),
        Placeholder(key: "introduction", description: "Opening paragraph", defaultValue: "")
    ],
    tags: ["tag1", "tag2"]
)
```

**Placeholder rules:**
- Format: `{{snake_case_key}}` — lowercase letters and underscores only
- Every key used in `content` must have a matching `Placeholder` struct
- Every `Placeholder` struct must be referenced in `content`
- Target 3–8 placeholders per template

**Available categories:** `novel`, `shortStory`, `screenplay`, `blogPost`, `article`, `essay`, `poetry`, `businessLetter`, `proposal`, `resume`, `other`

---

### test-runner

**File**: `.claude/agents/test-runner.md`
**Model**: `haiku`
**Tools**: `Bash`, `Read`, `Grep`, `Glob`

Runs `swift test` and returns a concise pass/fail summary. Use after modifying source files to confirm no regressions.

**Output format:**

```
# All pass:
All N tests passed.

# Failures:
N/M tests passed. Failures:

1. TestClassName.testMethodName
   File: Tests/WritersAppTests/WritersAppTests.swift:LINE
   Error: <assertion message>

# Build failure:
Build failed. Compiler errors:
<relevant error lines>
```

---

## Creating a New Agent

1. Create a markdown file in `.claude/agents/<name>.md`
2. Add the YAML front-matter block:

```yaml
---
name: agent-name
description: One-line summary of what the agent does and when to use it.
tools: Read, Glob          # only tools the agent actually needs
model: haiku               # haiku for simple tasks, sonnet for complex ones
---
```

3. Write the system prompt below the front-matter. Include:
   - Role and scope
   - Step-by-step workflow
   - Output format
   - Any project-specific rules the agent must follow

**Choosing a model:**

| Task type | Recommended model |
|-----------|------------------|
| Simple lookup, file reading, formatting | `haiku` |
| Code review, debugging, writing | `sonnet` |
| Highly complex reasoning or planning | `opus` |

**Granting tools — principle of least privilege:**
Only grant the tools the agent needs. Read-only agents (`knowledge-advisor`, `test-runner`) should not have `Edit` or `Write`. Agents that fix code (`swift-debugger`) need `Edit` and `Bash`.

---

## Code Style (for agents generating Swift)

- **Swift 5.9+**, macOS 13+ / iOS 16+
- Use `async throws` for AI operations and plugin calls
- Structs for data models (`Document`, `Template`, `Issue`), classes for services (`WritersApp`, `TemplateManager`)
- All models conform to `Codable` and `Identifiable` (UUID `id`)
- Use `// MARK: - Section Name` to organize code sections
- Methods use verbs: `createDocument`, `improveText`, `advanceKanbanTask`
- No external dependencies — Swift standard library and `CSQLite` only
- No hardcoded API keys or secrets
