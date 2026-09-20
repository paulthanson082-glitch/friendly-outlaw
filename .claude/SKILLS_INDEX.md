# Claude Code Skills & Resources Index

A comprehensive guide to Claude Code skills, agents, workflows, tools, and resources for the friendly-outlaw writers app and the broader Claude Code ecosystem.

---

## 📋 Quick Navigation

- [Project-Specific Skills](#project-specific-skills) — Tools for friendly-outlaw development
- [Agent Skills](#agent-skills) — Specialized autonomous agents from the ecosystem
- [Workflows & Knowledge](#workflows--knowledge-guides) — Complete development workflows and best practices
- [Tools & Utilities](#tools--utilities) — Productivity tools for Claude Code development
- [Status Lines](#status-lines) — Terminal UI enhancements
- [Hooks](#hooks) — Automation and validation hooks
- [Slash Commands](#slash-commands) — Custom commands organized by task type
- [CLAUDE.md Files](#claudemd-files) — Project-specific development guides
- [Alternative Clients](#alternative-clients) — Third-party UIs for Claude Code
- [Official Resources](#official-resources) — Anthropic documentation and examples
- [Output Styles](#output-styles) — Customizable response formatting

---

## Project-Specific Skills

These skills are tailored for the friendly-outlaw writers app.

### Writing & Content
| Skill | File | Description |
|-------|------|-------------|
| **add-template** | `add-template.md` | Add a new writing template to TemplateManager |
| **add-ai-feature** | `add-ai-feature.md` | Implement AI-assisted writing capabilities |
| **build-and-test** | `build-and-test.md` | Build the project and run the full test suite |

### Architecture & System
| Skill | File | Description |
|-------|------|-------------|
| **add-version-control-op** | `add-version-control-op.md` | Extend DoltVersionControlService with new operations |
| **generate-skill-from-url** | `generate-skill-from-url.md` | Generate a new skill definition from a URL |

### External Integration
| Skill | File | Description |
|-------|------|-------------|
| **firecrawl** | `firecrawl.md` | Web scraping, searching, and browser automation |

---

## Agent Skills

Specialized autonomous agents from the broader ecosystem. These agents are isolated workers that handle specific domains with deep expertise.

### General-Purpose Agents

| Agent | Author | License | Description |
|-------|--------|---------|-------------|
| **AgentSys** | avifenesh | MIT | Workflow automation system with plugins, agents, and skills for task-to-production workflows, PR management, code cleanup, and multi-agent code review |
| **Book Factory** | Robert Guss | MIT | Comprehensive pipeline replicating traditional publishing infrastructure for nonfiction book creation |
| **Claude Code Agents** | Paul - UndeadList | MIT | E2E development workflow with subagent prompts, parallel auditors, and browser-based QA |
| **Claude Scientific Skills** | K-Dense | MIT | Research, science, engineering, analysis, finance and writing capabilities |
| **Everything Claude Code** | Affaan Mustafa | MIT | Exemplary resources covering core engineering domains and Claude Code features |
| **Fullstack Dev Skills** | jeffallan | MIT | 65 specialized skills for full-stack development with 9 project workflow commands |
| **Superpowers** | Jesse Vincent | MIT | Core competencies covering planning, reviewing, testing, debugging and more |
| **Trail of Bits Security Skills** | Trail of Bits | CC-BY-SA-4.0 | Professional security-focused skills for code auditing and vulnerability detection |

---

## Workflows & Knowledge Guides

Complete development workflows, best practices, and learning resources.

### General Workflows

| Workflow | Author | License | Description |
|----------|--------|---------|-------------|
| **AB Method** | Ayoub Bensalah | MIT | Spec-driven workflow transforming large problems into focused incremental missions |
| **Agentic Workflow Patterns** | ThibautMelen | N/A | Comprehensive collection with Mermaid diagrams for each agentic pattern |
| **Claude Code Handbook** | nikiforovall | MIT | Best practices, tips, and techniques for Claude Code workflows |
| **Claude Code PM** | Ran Aroussi | MIT | Feature-packed project-management workflow with numerous specialized agents |
| **Claude CodePro** | Max Ritter | N/A | Professional development environment with spec-driven workflow and TDD enforcement |
| **Claude Code Tips** | ykdojo | N/A | 35+ brief but information-dense tips covering voice input, multi-model orchestration, and more |
| **Claude Code Ultimate Guide** | Florian BRUNIAUX | CC-BY-SA-4.0 | Tremendous documentation covering beginner to power user with production templates |
| **The Startup** | Rudolf Schmidt | MIT | Comprehensive project-management workflow for shipping production code |

### Ralph Wiggum (Autonomous Loops)

The Ralph Wiggum technique enables autonomous AI agents to iteratively work toward task completion.

| Resource | Author | License | Description |
|----------|--------|---------|-------------|
| **Ralph for Claude Code** | Frank Bria | MIT | Autonomous AI development framework with intelligent exit detection and safety guardrails |
| **ralph-orchestrator** | mikeyobrien | MIT | Robust, well-tested orchestration system for AI-driven development |
| **ralph-wiggum-bdd** | marcindulak | Apache-2.0 | Standalone Bash script for Behavior-Driven Development with Ralph loop |
| **The Ralph Playbook** | Clayton Farr | MIT | Detailed and comprehensive guide to the Ralph Wiggum technique |

### Team & Multi-Agent Coordination

| Resource | Author | License | Description |
|----------|--------|---------|-------------|
| **Claude Code Agent Teams: Exercises** | Panaversity | N/A | Practical exercises with 6 exercises + 2 capstones for team coordination |
| **Harness** | revfactory | Apache-2.0 | Meta-skill designing domain-specific agent teams with automated skill generation |

---

## Tools & Utilities

### Session & Context Management

| Tool | Author | License | Description |
|------|--------|---------|-------------|
| **claude-code-tools** | Prasad Chalasani | MIT | Session continuity tools with full-text search and cross-agent handoff |
| **claude-session-restore** | ZENG3LD | N/A | Restore context from previous sessions using git history and analysis |
| **claudekit** | Carl Rannaberg | MIT | CLI toolkit with auto-save checkpointing and 20+ specialized subagents |
| **ContextKit** | Cihat Gündüz | MIT | Systematic development framework with 4-phase planning and specialized quality agents |
| **recall** | zippoxer | MIT | Full-text search your Claude Code sessions with terminal UI |
| **Vibe-Log** | Vibe-Log | MIT | Analyzes prompts locally, provides session analysis with HTML reports |

### Orchestration & Multi-Agent

| Tool | Author | License | Description |
|------|--------|---------|-------------|
| **Auto-Claude** | AndyMik90 | AGPL-3.0 | Multi-agent coding framework with kanban-style UI for autonomous code shipping |
| **Claude Code Flow** | ruvnet | MIT | Code-first orchestration layer for recursive agent cycles |
| **Claude Squad** | smtg-ai | AGPL-3.0 | Manage multiple Claude Code, Codex, and Aider agents in separate workspaces |
| **Claude Swarm** | parruda | MIT | Connect a session to a swarm of Claude Code agents |
| **Happy Coder** | GrocerPublishAgent | MIT | Spawn and control multiple Claude Codes in parallel from phone or desktop |
| **Ruflo** | rUv | MIT | Orchestration platform for multi-agent swarms with self-learning and vector memory |
| **sudocode** | ssh-randy | Apache-2.0 | Lightweight agent orchestration with specification framework integration |
| **TSK - Task Manager** | dtormoen | MIT | Delegate tasks to AI agents in sandboxed Docker environments |

### Code Quality & Linting

| Tool | Author | License | Description |
|------|--------|---------|-------------|
| **agnix** | agent-sh | Apache-2.0 | Comprehensive linter for Claude Code agent files with IDE plugins |
| **cc-tools** | Josh Symonds | N/A | High-performance Go implementation of hooks and utilities with smart linting |
| **TDD Guard** | Nizar Selander | MIT | Hooks-driven system monitoring file operations and enforcing TDD principles |

### Configuration & Config Management

| Tool | Author | License | Description |
|------|--------|---------|-------------|
| **ClaudeCTX** | John Fox | MIT | Switch entire Claude Code configuration with a single command |
| **claude-rules-doctor** | nulone | MIT | Detect dead `.claude/rules/` files and catch configuration failures |
| **rulesync** | dyoshikawa | MIT | Auto-generate configs for AI coding agents with inter-agent conversion |

### Development Containers & Sandboxing

| Tool | Author | License | Description |
|------|--------|---------|-------------|
| **Container Use** | dagger | Apache-2.0 | Development environments enabling multiple agents to work safely |
| **run-claude-docker** | Jonas | MIT | Docker runner forwarding workspace with access to settings and keys |
| **viwo-cli** | Hal Shin | MIT | Run Claude Code in Docker with git worktrees for safer permission handling |

### IDE Integrations

| Tool | Author | License | Description |
|------|--------|---------|-------------|
| **claude-code-ide.el** | manzaltu | GPL-3.0 | Emacs integration with ediff-based suggestions and LSP diagnostics |
| **claude-code.el** | stevemolitor | Apache-2.0 | Emacs interface for Claude Code CLI |
| **claude-code.nvim** | greggh | MIT | Seamless Neovim integration for Claude Code |
| **Claudix** | Haleclipse | AGPL-3.0 | VSCode extension with interactive chat, session management, and streaming responses |

### Alternative Clients & Monitoring

| Tool | Author | License | Description |
|------|--------|---------|-------------|
| **Claudable** | Ethan Park | MIT | Web builder leveraging local CLI agents for building and deploying products |
| **claude-esp** | phiat | MIT | Go-based TUI streaming Claude Code's hidden output (thinking, tool calls) to separate terminal |
| **claude-devtools** | matt1398 | MIT | Desktop app providing detailed observability into Claude Code sessions |
| **claude-tmux** | Niels Groeneveld | N/A | Manage Claude Code within tmux with status monitoring and PR support |
| **crystal** | stravu | MIT | Full-fledged desktop application for orchestrating and monitoring Claude Code agents |
| **Omnara** | Ishaan Sehgal | Apache-2.0 | Command center for AI agents syncing across terminal, web, and mobile |

---

## Status Lines

Terminal UI enhancements showing real-time Claude Code information.

| Status Line | Author | License | Description |
|-------------|--------|---------|-------------|
| **CCometixLine** | Haleclipse | N/A | High-performance Rust statusline with Git integration and usage tracking |
| **ccstatusline** | sirmalloc | MIT | Highly customizable formatter showing model info, git branch, token usage |
| **claude-code-statusline** | rz1989s | MIT | Enhanced 4-line statusline with themes and cost tracking |
| **claude-powerline** | Owloops | MIT | Vim-style powerline with real-time usage tracking and custom themes |
| **claudia-statusline** | Hagan Franks | MIT | High-performance Rust statusline with persistent stats and SQLite backing |

---

## Hooks

Automation and validation scripts that run automatically during Claude Code operations.

| Hook | Author | License | Description |
|------|--------|---------|-------------|
| **Britfix** | Talieisin | MIT | Converts American to British English, context-aware for code files |
| **CC Notify** | dazuiba | MIT | Desktop notifications for Claude Code with one-click jump to VS Code |
| **cchooks** | GowayLee | MIT | Lightweight Python SDK simplifying hook creation with clean API |
| **HCOM** | aannoo | MIT | Real-time communication between Claude Code sub agents using hooks |
| **claude-code-hooks-sdk** | beyondcode | MIT | Laravel-inspired PHP SDK for building Claude Code hook responses |
| **claude-hooks** | John Lindquist | MIT | TypeScript-based system for configuring and customizing hooks |
| **Claudio** | Christopher Toth | N/A | Adds delightful OS-native sounds to Claude Code via simple hooks |
| **Dippy** | Lily Dayton | MIT | Auto-approve safe bash commands using AST-based parsing |
| **parry** | Dmytro Onypko | MIT | Prompt injection scanner for Claude Code hooks |
| **Plannotator** | backnotprop | Apache-2.0 | Interactive plan review UI intercepting ExitPlanMode via hooks |

---

## Slash Commands

Organized by task type — commonly used custom commands from the ecosystem.

### Version Control & Git

- `/analyze-issue` — Fetch GitHub issue details to create comprehensive implementation specs
- `/commit` — Create git commits using conventional commit format with emojis
- `/commit-fast` — Automate git commit by selecting first suggestion
- `/create-pr` — Streamline PR creation with branch, commit, and format steps
- `/create-pull-request` — Comprehensive PR creation with GitHub CLI and template structure
- `/create-worktrees` — Create git worktrees for all open PRs or specific branches
- `/fix-github-issue` — Analyze and fix GitHub issues using structured approach
- `/fix-issue` — Address GitHub issues by analyzing context and implementing solution
- `/fix-pr` — Fetch and fix unresolved PR comments automatically
- `/update-branch-name` — Update branch names with proper prefixes and formats

### Code Analysis & Testing

- `/analyze-code` — Review code structure and identify key components
- `/check` — Perform comprehensive code quality and security checks
- `/clean` — Address code formatting and quality issues (Python)
- `/code_analysis` — Advanced code analysis menu for deep inspection
- `/implement-issue` — Implement GitHub issues following strict project guidelines
- `/implement-task` — Approach task implementation methodically
- `/optimize` — Analyze code performance and propose optimizations
- `/repro-issue` — Create reproducible test cases for GitHub issues
- `/task-breakdown` — Analyze requirements and create manageable tasks
- `/tdd` — Guide development using Test-Driven Development principles
- `/tdd-implement` — Implement TDD with Red-Green-Refactor discipline
- `/testing_plan_integration` — Create inline Rust-style tests

### Context Loading & Priming

- `/context-prime` — Prime Claude with comprehensive project understanding
- `/initref` — Initialize reference documentation structure
- `/load-llms-txt` — Load LLM configuration files to context
- `/prime` — Set up initial project context
- `/reminder` — Re-establish project context after conversation breaks
- `/rsi` — Read all commands and key files for optimized development

### Documentation & Changelogs

- `/add-to-changelog` — Add new changelog entries while maintaining format
- `/create-docs` — Analyze code structure to create comprehensive documentation
- `/docs` — Generate documentation following project structure
- `/explain-issue-fix` — Document solution approaches for GitHub issues
- `/update-docs` — Review current docs and update implementation progress

### CI / Deployment

- `/build-react-app` — Build React applications with error handling
- `/release` — Manage software releases with changelog updates
- `/run-ci` — Activate virtual environments and run CI checks
- `/run-pre-commit` — Run pre-commit checks with intelligent handling

### Project & Task Management

- `/create-command` — Guide through creating new custom commands
- `/create-plan` — Generate comprehensive product requirement documents
- `/create-prp` — Create product requirement plans from methodology
- `/do-issue` — Implement GitHub issues with manual review points
- `/next-task` — Get next task from TaskMaster and create branch
- `/prd-generator` — Generate comprehensive Product Requirements Documents
- `/todo` — Manage project todo items with due dates and prioritization

### Hook Creation

- `/create-hook` — Intelligently prompt through hook creation process

---

## CLAUDE.md Files

Exemplary project-specific development guides from the ecosystem.

### Language-Specific

| Project | Language | Author | Description |
|---------|----------|--------|-------------|
| **AI IntelliJ Plugin** | Gradle/IntelliJ | didalgolab | Comprehensive Gradle commands with platform-specific patterns |
| **AWS MCP Server** | Python | alexei-led | Multiple environment setup with detailed code style guidelines |
| **DroidconKotlin** | Kotlin | touchlab | Cross-platform Kotlin Multiplatform with clear module structure |
| **Giselle** | TypeScript/Node | giselles-ai | pnpm workflow with Vitest and strict code formatting |
| **HASH** | Rust | hashintel | Strong emphasis on Rust documentation and code standards |
| **Inkline** | Vue 3/TypeScript | inkline | Component creation process with comprehensive testing |
| **LangGraphJS** | TypeScript | langchain-ai | Detailed TypeScript guidelines with monorepo structure |
| **Metabase** | Clojure/ClojureScript | metabase | REPL-driven development with incremental approach |
| **SPy** | Multiple | spylang | Strict coding conventions with comprehensive testing |
| **TPL** | Go | KarpelesLab | Go project conventions with error handling guidance |

### Domain-Specific

| Project | Domain | Author | Description |
|---------|--------|--------|-------------|
| **AVS Vibe** | Blockchain | Layr-Labs | EigenLayer AVS development with consistent naming |
| **Comm** | Messaging | CommE2E | E2E-encrypted messaging with security implementation |
| **Course Builder** | Education | badass-courses | Collaborative course creation with Turborepo |
| **Cursor Tools** | AI Tooling | eastlondoner | Versatile AI command interface with browser automation |
| **Guitar** | Desktop App | soramimi | Git GUI Client build commands for various platforms |
| **Network Chronicles** | Game Dev | Fimeg | AI-driven game characters with LLM integration |
| **Pareto Mac** | Security | ParetoSecurity | Mac security audit tool with contribution guidelines |
| **SG Cars Trends** | Full-stack | sgcarstrends | TypeScript monorepo with AWS/Cloudflare integration |

### Project Scaffolding & MCP

| Project | Approach | Author | Description |
|---------|----------|--------|-------------|
| **Basic Memory** | AI-Human Collab | basicmachines-co | Bidirectional LLM-markdown communication with MCP |
| **claude-code-mcp-enhanced** | MCP Enhancement | grahama1970 | Detailed instructions for Claude with testing guidance |
| **MCP Engine** | Package Management | featureform | Strict package management with comprehensive type checking |
| **Perplexity MCP** | Integration | Family-IT-Guy | Step-by-step installation with troubleshooting guidance |
| **pre-commit-hooks** | Git Hooks | aRustyDev | Exemplary documentation without all-caps messaging |
| **SteadyStart** | Workflow Design | steadycursor | Clear instructions on style, permissions, and documentation |

---

## Alternative Clients

Third-party UIs and tools for interacting with Claude Code.

| Client | Author | License | Description |
|--------|--------|---------|-------------|
| **Claudable** | Ethan Park | MIT | Open-source web builder leveraging local CLI agents |
| **claude-esp** | phiat | MIT | Go-based TUI streaming hidden output (thinking, tool calls) |
| **claude-tmux** | Niels Groeneveld | N/A | Manage instances in tmux with status monitoring |
| **crystal** | stravu | MIT | Desktop app for orchestrating and monitoring agents |
| **Omnara** | Ishaan Sehgal | Apache-2.0 | Command center syncing across terminal, web, mobile |

---

## Official Resources

Anthropic-provided documentation and examples.

| Resource | Type | Description |
|----------|------|-------------|
| **Anthropic Documentation** | Docs | Official docs for Claude Code with installation, usage, API references, tutorials |
| **Anthropic Quickstarts** | Examples | Comprehensive guides for three AI-powered demo projects |
| **Claude Code GitHub Actions** | Integration | Official GitHub Actions integration with CI/CD examples |

---

## Output Styles

Customizable response formatting for Claude Code.

| Style | Author | License | Description |
|-------|--------|---------|-------------|
| **ccoutputstyles** | Vivek Nair | MIT | CLI tool and template gallery with 15+ pre-built templates |
| **Debugging Styles** | Jamie Matthews | MIT | Well-written styles focused on systematic debugging |
| **Gen-Alpha Slang** | Steve Nims | MIT | Humorous alternative formatting in gen-alpha style |

---

## How to Use These Resources

### Finding Skills
1. Search this document for your use case (Ctrl+F)
2. Check the category tables for matching tools
3. Use `/help` to see what's installed locally

### Installing Skills
```bash
/aviz-skills-installer
```

### Creating Custom Skills
1. Read an existing skill from `.claude/skills/`
2. Use `/create-command` or `/create-hook` to scaffold new ones
3. Reference this index for patterns and examples

### For Contributors
When adding new skills to friendly-outlaw, update the **Project-Specific Skills** section at the top with:
- Skill name and file path
- Clear description
- Use cases

---

## Quick Tips

- **Search**: Use Ctrl+F to find resources by keyword (e.g., "workflow", "testing", "git")
- **Combine tools**: Chain multiple skills in sequence for complex tasks
- **Check versions**: Many resources are actively maintained — check their repos for latest features
- **Learn from examples**: CLAUDE.md files show real-world patterns from production projects
- **Build on existing work**: Use established workflows as templates for custom setups

---

**Last updated**: 2026-09-20 | **Data source**: AVIZ Skills Directory

