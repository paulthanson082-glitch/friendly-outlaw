# /analyze-existing

Analyze existing blog posts or pages to identify improvement opportunities and prioritize rewrites.

## Usage
`/analyze-existing [URL or file path]`

## What This Command Does

1. **Fetch & Parse Content**
   - If URL: retrieve the page content
   - If file path: read the file
   - Extract: title, headings structure, word count, body content, meta elements

2. **Content Health Analysis**
   - **Word Count**: compare to current SERP average for the keyword
   - **Keyword Optimization**: assess primary keyword placement and density
   - **Heading Structure**: evaluate H1/H2/H3 hierarchy
   - **Internal Links**: count and assess quality
   - **External Links**: count and check for broken or outdated links
   - **Readability**: estimate reading level and sentence complexity
   - **Freshness**: identify outdated statistics, dates, or references

3. **Competitive Positioning**
   - Compare content depth to top 5 current SERP results
   - Identify topics/sections covered by competitors but missing here
   - Assess uniqueness of angle and examples

4. **SEO Audit**
   - Meta title: length and keyword inclusion
   - Meta description: length and quality
   - Keyword density and distribution
   - Schema markup presence
   - Internal linking strategy

5. **Content Health Score (0-100)**
   - Scoring breakdown by category:
     - Content depth (25 pts)
     - SEO optimization (25 pts)
     - Freshness (20 pts)
     - Competitive positioning (15 pts)
     - User experience (15 pts)

6. **Recommendations**
   - Quick wins (can implement in < 30 min)
   - Strategic improvements (require research/rewrite)
   - Rewrite priority: Low / Medium / High / Critical
   - Recommended scope: Light update / Partial rewrite / Full rewrite

## Output

Save analysis to: `research/analysis-[topic-slug]-[YYYY-MM-DD].md`

Format:
```
---
analyzed_url: [URL or file]
date: [YYYY-MM-DD]
content_health_score: [0-100]
rewrite_priority: [Low/Medium/High/Critical]
rewrite_scope: [Light/Partial/Full]
---

## Executive Summary
[2-3 sentence summary of findings]

## Content Health Score: [X/100]
| Category | Score | Notes |
|----------|-------|-------|
| Content Depth | X/25 | |
| SEO Optimization | X/25 | |
| Freshness | X/20 | |
| Competitive Position | X/15 | |
| User Experience | X/15 | |

## Quick Wins
[Immediate improvements, bulleted]

## Strategic Improvements
[Larger improvements requiring research/rewrite]

## Rewrite Brief
[If rewrite recommended: research brief for /rewrite command]
```

## Instructions

Analyze the content at "$ARGUMENTS" and provide a thorough assessment of its current quality, competitive positioning, and specific improvement opportunities. Be direct about the rewrite priority and what it will take to make this content competitive.
