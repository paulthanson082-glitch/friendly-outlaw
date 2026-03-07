# /article

Simplified all-in-one article creation workflow — research, write, and optimize in one command.

## Usage
`/article [topic]`

## What This Command Does

Runs the full content creation pipeline automatically:

1. **Research** — keyword and competitor research (equivalent to `/research`)
2. **Write** — creates the full article (equivalent to `/write`)
3. **Optimize** — final SEO pass (equivalent to `/optimize`)

Use this for a streamlined workflow when you want everything done in one session.

For more control over each step, use `/research`, `/write`, and `/optimize` individually.

## Output

- Research brief: `research/brief-[topic-slug]-[YYYY-MM-DD].md`
- Draft article: `drafts/[topic-slug]-[YYYY-MM-DD].md`
- Optimization report: `drafts/optimization-report-[topic-slug]-[YYYY-MM-DD].md`

## Context Files to Reference
- `context/brand-voice.md`
- `context/writing-examples.md`
- `context/style-guide.md`
- `context/seo-guidelines.md`
- `context/target-keywords.md`
- `context/internal-links-map.md`
- `context/competitor-analysis.md`

## Instructions

Execute the complete research → write → optimize pipeline for "$ARGUMENTS". Read all context files, conduct thorough research, write a high-quality 2,000-3,000+ word article, run agent analysis, and perform final optimization. Provide a summary of all outputs at the end.
