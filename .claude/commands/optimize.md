# /optimize

Run a final SEO optimization pass on a draft article before publishing.

## Usage
`/optimize [article file path]`

## What This Command Does

1. **Load Article**
   - Read the specified file from `drafts/` or `rewrites/`
   - Extract all content, meta elements, and structure

2. **Comprehensive SEO Audit**
   - Title tag: length (50-60 chars), keyword presence, click appeal
   - Meta description: length (150-160 chars), keyword, CTA
   - H1: single, contains primary keyword, compelling
   - H2/H3s: keyword variation coverage, logical flow
   - Keyword density: primary (1-2%), secondary distribution
   - First 100 words: primary keyword present
   - Conclusion: keyword present, strong CTA
   - Internal links: count (3-5), anchor text quality, URL validity
   - External links: count (2-3), authority, recency
   - Images: alt text, file names (if any referenced)
   - Word count: vs. recommended length

3. **Readability Check**
   - Average sentence length (target: 15-20 words)
   - Paragraph length (target: 2-4 sentences)
   - Heading frequency (every 300-400 words)
   - Transition words and flow
   - Reading grade level (target: 8th-10th grade)

4. **Content Quality Check**
   - Introduction: hook, problem statement, promise
   - Value proposition vs. competitors
   - Actionable advice presence
   - Data and statistics cited
   - Conclusion CTA clarity

5. **SEO Score (0-100)**
   - Priority fixes (must address before publishing)
   - Quick wins (easy improvements)
   - Optional enhancements

6. **Publishing Readiness**
   - Pass / Needs Work / Not Ready assessment

## Output

Save report to: `drafts/optimization-report-[topic-slug]-[YYYY-MM-DD].md`

Format:
```
---
article_file: [path]
date: [YYYY-MM-DD]
seo_score: [0-100]
publishing_readiness: [Pass/Needs Work/Not Ready]
---

## SEO Score: [X/100]

## Priority Fixes (Required Before Publishing)
[Numbered list of must-fix issues]

## Quick Wins
[Bulleted list of easy improvements]

## Meta Element Options
### Title Variations
1. [Option 1] — [X chars]
2. [Option 2] — [X chars]

### Description Variations
1. [Option 1] — [X chars]
2. [Option 2] — [X chars]

## Link Enhancements
[Specific internal/external link suggestions]

## Publishing Readiness: [Assessment]
[Summary and recommendation]
```

## Instructions

Perform a thorough optimization audit of the article at "$ARGUMENTS". Be specific about every issue — include the exact text that needs changing and what it should be changed to. Provide a clear go/no-go publishing recommendation.
