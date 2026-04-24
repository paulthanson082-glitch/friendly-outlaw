# Claude Code Plugins Reference

Curated catalog of the official Anthropic plugin marketplace (`anthropics/claude-plugins-official`) as observed from the live `marketplace.json`. The marketplace is registered in `.claude/settings.json` under `extraKnownMarketplaces`, so `/plugin` shows these automatically.

## Quick usage

- Browse the interactive picker: `/plugin`
- Install a specific plugin: `/plugin install <name>@claude-plugins-official`
- Team-wide auto-enable: add to `enabledPlugins` in `.claude/settings.json`

## Enabled for this project

These are auto-enabled via `.claude/settings.json#/enabledPlugins`:

| Plugin | Why it is on |
|--------|--------------|
| `swift-lsp` | Code intelligence for the Swift sources under `Sources/WritersApp/` |
| `pr-review-toolkit` | Multi-agent PR review — comments, tests, error handling, quality |
| `commit-commands` | Commit/push/PR workflow slash commands |
| `plugin-dev` | We have our own plugin architecture (`Sources/WritersApp/Plugins/`) |
| `skill-creator` | We extend `.claude/skills/`; this authors and evals skills |
| `claude-md-management` | Keeps this `CLAUDE.md` and friends healthy |

To disable any of them, flip the value to `false` or remove the line.

## Full catalog (by category)

### Language servers
`clangd-lsp` · `csharp-lsp` · `elixir-ls-lsp` · `gopls-lsp` · `jdtls-lsp` · `kotlin-lsp` · `lua-lsp` · `php-lsp` · `pyright-lsp` · `ruby-lsp` · `rust-analyzer-lsp` · `swift-lsp` · `typescript-lsp`

### Anthropic workflow tooling
- `commit-commands` — git commit, push, PR workflows
- `pr-review-toolkit` — PR reviewers specialized by concern
- `code-review` — confidence-scored PR review agent
- `code-simplifier` — clarity/consistency pass on recent diffs
- `feature-dev` — end-to-end feature workflow with specialized agents
- `plugin-dev` — toolkit for building Claude Code plugins
- `agent-sdk-dev` — Claude Agent SDK helpers
- `mcp-server-dev` — design and build MCP servers
- `skill-creator` — create, improve, and eval skills
- `claude-code-setup` — audit a repo and recommend automations
- `claude-md-management` — audit/maintain `CLAUDE.md`
- `hookify` — generate hooks from conversation patterns
- `frontend-design` — escape generic AI UI aesthetics
- `session-report` — explorable HTML session usage report
- `explanatory-output-style` / `learning-output-style` — replacements for deprecated output styles

### Source hosts and code search
`github` · `gitlab` · `sourcegraph` · `greptile` · `serena`

### Issue trackers, PM, docs
`linear` · `asana` · `atlassian` (Jira/Confluence) · `notion` · `intercom` · `circleback` · `legalzoom`

### PR review add-ons
`coderabbit` · `optibot` · `autofix-bot` · `qodo-skills`

### Databases
`mongodb` · `supabase` · `firebase` · `neon` · `prisma` · `planetscale` · `cockroachdb` · `pinecone` · `atlan` · `dataverse` · `azure-cosmos-db-assistant` · `databases-on-aws` · `data-engineering` · `astronomer-data-agents` · `fiftyone`

### Cloud and deployment
`aws-amplify` · `aws-serverless` · `deploy-on-aws` · `sagemaker-ai` · `azure-skills` · `cloudflare` · `vercel` · `netlify-skills` · `railway` · `fastly-agent-toolkit` · `terraform` · `followrabbit`

### Security and supply chain
`semgrep` · `sonarqube` · `aikido` · `ai-plugins` (Endor Labs) · `sonatype-guide` · `nightvision` · `opsera-devsecops` · `security-guidance`

### Observability and incidents
`sentry` · `posthog` · `amplitude` · `pagerduty` · `firetiger`

### Messaging bridges
`slack` · `discord` · `telegram` · `imessage` · `zoom-plugin`

### Browser and web automation
`playwright` · `chrome-devtools-mcp` · `stagehand` · `firecrawl` · `brightdata-plugin` · `nimble`

### Design and docs
`figma` · `miro` · `cloudinary` · `mintlify` · `microsoft-docs` · `context7` · `playground`

### Framework and platform skills
`expo` · `laravel-boost` · `pydantic-ai` · `shopify` · `shopify-ai-toolkit` · `liquid-skills` · `wix` · `wordpress.com` · `ui5` · `ui5-typescript-conversion` · `cds-mcp` (SAP) · `netsuite-suitecloud` · `huggingface-skills` · `atomic-agents`

### Payments and commerce
`stripe` · `sumup` · `revenuecat`

### Specialty
- `math-olympiad` — competition math with adversarial verification
- `remember` — tiered daily memory logs across sessions
- `superpowers` — brainstorming plus subagent-driven dev plus TDD
- `ralph-loop` — iterative self-referential work loops
- `helius` — Solana tooling
- `goodmem` — memory infra for AI agents
- `zapier` — 8,000+ apps via Zapier actions

## Caveats

- The catalog above was captured from the live `marketplace.json`; the marketplace updates frequently, so treat this list as a snapshot. `/plugin` is always authoritative.
- A separate community marketplace (`anthropics/claude-plugins-community`) exists with many more plugins; not registered here.
- Some plugins appear under multiple names (`data` vs `data-engineering` vs `astronomer-data-agents`).
- Plugins require user trust approval the first time they are installed.
