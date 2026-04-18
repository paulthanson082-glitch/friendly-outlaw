# The Ask → Plan → Execute Workflow

This is how you work effectively with Claude in this project.

## The Pattern

**Most tasks follow this flow:**

```
You: "I want to add [feature / fix / refactor]"
    ↓
Claude: "Here are the applicable standards from your knowledge base"
    ↓
You: "Looks good" or "Actually, change X to Y"
    ↓
Claude: Writes code, runs tests, commits
```

This workflow ensures Claude follows your project's patterns before writing anything.

## Step 1: Ask

Just say what you want. You don't need a perfect prompt. Examples:

- "Add a new Kanban column type called 'testing'"
- "Fix the document export to not drop metadata"
- "Implement a new AI feature that generates pacing suggestions"

## Step 2: Plan (Automatic)

Claude consults the **knowledge-advisor** subagent to retrieve applicable standards. This happens automatically—no action needed from you. The agent reads:

- `.claude/knowledge/swift.json` — If it's Swift code
- `.claude/knowledge/architecture.json` — If it touches the app structure
- `.claude/knowledge/security.json` — If it handles user data or API calls
- `.claude/knowledge/testing.json` — Always (every change needs tests)
- `.claude/knowledge/templates.json` — If it's about writing templates

The advisor returns a **checklist of rules** specific to your task. This takes ~10 seconds.

## Step 3: Approve

Look at the plan. It should show:
- What files will change
- The applicable standards
- A pre-commit checklist

Say "looks good" or point out changes. You control the direction.

## Step 4: Execute

Claude writes code, tests it, and commits to your branch.

---

## When to Invoke Agents Directly

Most tasks use the automatic knowledge-advisor. But for specific problems:

| Situation | Invoke |
|-----------|--------|
| Build fails or crashes | **swift-debugger** — diagnoses the error |
| Tests fail mysteriously | **test-runner** — runs tests, shows failures clearly |
| Need code review | **swift-code-reviewer** — checks quality vs. conventions |
| Adding a complex template | **template-designer** — guides you through structure |
| Designing a feature | **Plan** subagent (if available) — works out architecture before coding |

## When to Use Skills

**Skills** are pre-built workflows for repetitive tasks:

- `add-template` — Add a new writing template to TemplateManager
- `add-ai-feature` — Implement a new AI capability (Claude method, system prompt, test)
- `build-and-test` — Build the project and run tests, report failures
- `add-version-control-op` — Extend DoltVersionControlService with a new operation

Invoke with: "Use the X skill" or ask Claude to add a template (it auto-detects).

---

## Why This Works

1. **Standards are in one place** — `.claude/knowledge/` — so they don't rot
2. **Plans happen before code** — You review before anything changes
3. **Agents specialize** — Knowledge-advisor, debugger, reviewer each do one job well
4. **Async/repeatable** — Same pattern every time, no surprises

## Example: Add a New Document Status

**You:** "Add a new document status called 'archived'. Documents should be soft-deleted but queryable."

**Claude:** Consults knowledge-advisor → returns applicable rules (architecture patterns, naming conventions, testing approach)

**Claude's plan:**
```
Files to change:
- Models/Document.swift (add .archived case to DocumentStatus enum)
- Services/DocumentManager.swift (filter archived docs from list, add unarchive method)
- Tests/WritersAppTests.swift (test soft-delete + unarchive)

Applicable rules:
- swift-naming: Status enums use .camelCase cases
- arch-001: Always keep in-memory and DB in sync
- test-001: Test the success path and edge cases
```

**You:** "Looks good" (or "Actually, also add a soft-delete timestamp")

**Claude:** Makes the changes, tests, commits to your branch
