# Claude Code Setup for friendly-outlaw

This directory organizes how Claude Code helps with this Swift writers app. Think of it as your project's AI assistant playbook.

## Quick Orientation

**When you start working on a task:**

1. **Ask** — Describe what you want to build or fix
2. **Plan** — Claude consults the knowledge base via the knowledge-advisor agent
3. **Execute** — You approve, Claude writes code and runs tests

This setup makes sure Claude knows your patterns before writing anything.

## What's in Here

| File/Dir | Purpose |
|----------|---------|
| **workflow.md** | How the ask → plan → execute flow works (start here if new) |
| **project.md** | Quick intro: what friendly-outlaw is, how to build/test/run |
| **agents/** | Specialized workers (knowledge-advisor reads rules, swift-debugger fixes errors, etc.) |
| **skills/** | Step-by-step workflows for common tasks (add template, add AI feature, etc.) |
| **knowledge/** | Structured standards (Swift rules, architecture patterns, security, templates, testing) |
| **hooks/** | Scripts that run automatically (e.g., on session start: installs dependencies, builds project) |
| **settings.json** | Permissions and hook registration |

## Using This Setup

### Before Making a Code Change
Use the **knowledge-advisor** subagent to retrieve applicable standards:

> "I'm adding a new async method to AIService for generating chapter outlines. What standards apply?"

It reads the relevant knowledge files and returns a focused checklist. This takes 10 seconds and prevents rework.

### For Common Tasks
Use **skills** — they're step-by-step guides:
- Adding a new writing template? → use `add-template` skill
- Implementing a new AI feature? → use `add-ai-feature` skill
- Extending version control? → use `add-version-control-op` skill

### For Debugging
Use **subagents** to stay focused:
- Build errors or crashes? → **swift-debugger** agent
- Want a second opinion on your code? → **swift-code-reviewer** agent
- Need to run tests? → **test-runner** agent

### Standards & Knowledge Base
All project rules live in `.claude/knowledge/` as JSON files — no guessing, no outdated docs:

- **swift.json** — Naming, optionals, async/await, no external deps
- **architecture.json** — Manager/service patterns, how to add features
- **security.json** — No hardcoded secrets, input validation, network policy
- **templates.json** — Placeholder format, category rules
- **testing.json** — What to test, AI method guidance

## One More Thing

The session-start hook (`.claude/hooks/session-start.sh`) runs automatically on Ctrl+K web sessions. It installs dependencies, builds the project, and sets up plugins. If something fails, it'll tell you—then you can fix and retry.

## Need Help?

- General Claude Code questions? → `/help`
- Found a bug or have feedback? → Report at https://github.com/anthropics/claude-code/issues
- Want to understand the project better? → Read `project.md` next
