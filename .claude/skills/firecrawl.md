---
name: firecrawl
description: Scrape, search, and browse the web using Firecrawl CLI. Invoke when you need to fetch web content, search the web, crawl a site, or interact with a browser-rendered page (e.g. "scrape this URL", "search for X on the web", "crawl the docs site", "browse to this page and click login").
---

# Firecrawl CLI — Web Data Toolkit

Firecrawl CLI gives agents reliable web data: clean markdown from any page (including JavaScript-heavy sites), web search with scraped results, cloud browser sessions, and full-site crawls.

## Prerequisites

### Installation

Install the CLI if it is not already available:

```bash
npm install -g firecrawl-cli
```

Or use it without installing:

```bash
npx -y firecrawl-cli@latest <command>
```

### Authentication

Authenticate once with your Firecrawl API key (get one at firecrawl.dev):

```bash
firecrawl login --api-key fc-YOUR_KEY
```

The key is stored in `~/.firecrawl/config.json` and reused for all subsequent commands.

If a `FIRECRAWL_API_KEY` environment variable is set it is used automatically — no explicit login step needed.

## Core Commands

### scrape — Fetch a single page

```bash
# Basic scrape to stdout
firecrawl scrape https://example.com

# Save as markdown to a file
firecrawl scrape https://example.com --format markdown -o page.md

# Save as HTML
firecrawl scrape https://example.com --format html -o page.html
```

Use `scrape` when you need the content of a known URL. Output is clean, structured markdown — no noisy HTML.

### search — Web search with optional scraping

```bash
# Search and return result summaries
firecrawl search "AI agent benchmarks 2026" --limit 5

# Search and scrape each result page
firecrawl search "Swift concurrency patterns" --scrape --limit 5 -o results/
```

Use `search` when you need to find information across the web rather than from a specific URL. Combine with `--scrape` to get full page content for each result.

### browser — Cloud browser for interactive pages

Use the cloud browser when a page requires JavaScript, login, form submission, or multi-step interaction.

```bash
# Launch a persistent session
firecrawl browser launch-session

# Navigate to a URL
firecrawl browser execute "open https://example.com"

# Take a DOM snapshot (returns element references like @e5)
firecrawl browser execute "snapshot"

# Click an element by its snapshot reference
firecrawl browser execute "click @e5"

# Fill a form field
firecrawl browser execute "fill @e12 with 'search query'"

# Scrape the current page state
firecrawl browser execute "scrape"

# Close the session when done
firecrawl browser close
```

Use `browser` for pages that `scrape` cannot handle — login-gated content, SPAs, or workflows requiring interaction.

### crawl — Recursively crawl a site

```bash
# Crawl a site and wait for completion
firecrawl crawl https://docs.example.com --wait --progress -o crawl-output.json

# Crawl with a page limit
firecrawl crawl https://example.com --limit 50 --wait -o crawl-output.json
```

Use `crawl` when you need content from many pages on the same site (e.g. full documentation). Results are written to a single JSON file.

### map — Discover all URLs on a domain

```bash
firecrawl map https://example.com -o sitemap.json
```

Use `map` to understand the structure of a site before deciding which pages to scrape or crawl.

## Output Conventions

- Always write results to the **filesystem** (use `-o <path>`) rather than dumping raw content into the conversation.
- Use descriptive filenames: `pricing.md`, `competitor-features.md`, `docs-crawl.json`.
- For multiple search results use a directory: `-o results/` (each page saved as a numbered file).
- After writing, read back only the sections you need — avoid reading entire large files into context.

## Common Workflows

### Research a competitor's pricing page

```bash
firecrawl scrape https://competitor.com/pricing --format markdown -o competitor-pricing.md
```

### Search for documentation and save top results

```bash
firecrawl search "Swift async await best practices" --scrape --limit 3 -o swift-async-docs/
```

### Browse a login-protected page

```bash
firecrawl browser launch-session
firecrawl browser execute "open https://app.example.com/login"
firecrawl browser execute "snapshot"
firecrawl browser execute "fill @e3 with 'user@example.com'"
firecrawl browser execute "fill @e4 with 'password'"
firecrawl browser execute "click @e7"
firecrawl browser execute "snapshot"
firecrawl browser execute "scrape"
firecrawl browser close
```

### Map and selectively crawl docs

```bash
# Discover all URLs first
firecrawl map https://docs.example.com -o sitemap.json

# Then crawl only the relevant section
firecrawl crawl https://docs.example.com/api --wait --limit 30 -o api-docs.json
```

## Error Handling

- If `scrape` returns empty or minimal content, try `browser` instead — the page likely requires JavaScript.
- If authentication fails, re-run `firecrawl login --api-key <key>` or export `FIRECRAWL_API_KEY`.
- If a crawl times out, re-run with a smaller `--limit` value.
- Rate limit errors (429): wait a few seconds and retry, or reduce `--limit`.
