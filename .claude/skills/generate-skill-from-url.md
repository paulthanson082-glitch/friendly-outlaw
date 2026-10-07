---
name: generate-skill-from-url
description: Generate a complete Claude skill file from any documentation URL using Firecrawl's agent endpoint. Invoke when asked to "generate a skill from URL", "create a skill for [tool/service]", or "build a skill from documentation at [URL]".
---

# Generate a Claude Skill from a URL

Use this skill to automatically create a well-structured Claude skill file by crawling documentation at a given URL with Firecrawl's `/agent` endpoint.

## When to Use

- "Generate a skill for the Stripe API from their docs"
- "Create a skill from this URL: https://..."
- "Build a Claude skill for [any tool/service] using their documentation"

## Step 1 — Collect the target URL and skill name

Ask the user for:
- **URL**: the documentation or landing page to crawl (e.g. `https://docs.stripe.com/api`)
- **Skill name** (optional): the desired `name:` in the skill frontmatter; default to a slug derived from the URL host

## Step 2 — Run the Firecrawl Skills Generator script

The generator lives at `examples/firecrawl_skill_generator.py`. Run it with the target URL:

```bash
FIRECRAWL_API_KEY="fc-..." python3 examples/firecrawl_skill_generator.py \
  --url "<target-url>" \
  --output ".claude/skills/<skill-name>.md"
```

The script calls Firecrawl's `/agent` endpoint, which autonomously:
1. Maps the site to find relevant documentation pages
2. Crawls and extracts content from those pages
3. Structures the content into a valid skill file

Set `FIRECRAWL_API_KEY` from your Firecrawl account (https://firecrawl.dev). Use `--model spark-1-pro` for complex or large documentation sites.

## Step 3 — Review the generated skill

Open the output file and verify:

| Check | What to look for |
|-------|-----------------|
| Frontmatter | `name:` is a valid slug; `description:` clearly states when to trigger |
| Trigger conditions | The decision tree in the skill body covers the main use cases |
| Steps | Each step is actionable and references correct file paths / commands |
| Security | No API keys, secrets, or hardcoded credentials in the file |
| Formatting | Code blocks have language identifiers; tables render correctly |

If the generated output is incomplete or inaccurate, re-run with `--model spark-1-pro` or refine the `--prompt-extra` flag.

## Step 4 — Register the skill in CLAUDE.md (if it belongs to this project)

If the new skill should be available project-wide, add it to the "Available Skills" table in `CLAUDE.md`:

```markdown
| `<skill-name>` | When to use this skill |
```

## Step 5 — Test the skill

Manually invoke the new skill in a Claude Code session to verify it triggers correctly and produces the expected output.

## Reference: Script Flags

| Flag | Default | Description |
|------|---------|-------------|
| `--url` | *(required)* | Documentation URL to crawl |
| `--output` | stdout | File path to write the generated skill |
| `--model` | `spark-1-mini` | Firecrawl model: `spark-1-mini` (faster, cheaper) or `spark-1-pro` (more accurate) |
| `--prompt-extra` | *(none)* | Additional instructions appended to the generation prompt |
| `--timeout` | `120` | Max seconds to wait for the agent response |
