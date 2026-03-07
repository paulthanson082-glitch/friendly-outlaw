# /rewrite

Update and improve existing content based on analysis findings or general improvement needs.

## Usage
`/rewrite [topic or analysis file path]`

## What This Command Does

1. **Load Existing Content**
   - Check `research/` for an analysis file matching the topic
   - If analysis exists, use its recommendations to guide the rewrite
   - If no analysis, locate the most recent version in `published/` or `drafts/`

2. **Assess Scope**
   - Determine if this is a light update (refresh stats, fix issues) or major rewrite
   - Identify what's working well (preserve these sections)
   - Identify gaps vs. current top SERP results

3. **Rewrite/Update**
   - Update outdated statistics, examples, and references
   - Add missing sections identified in competitive analysis
   - Improve SEO optimization (keyword placement, headings, links)
   - Strengthen introduction and conclusion
   - Improve readability (shorter sentences, better formatting)
   - Refresh internal links with current pages from `context/internal-links-map.md`
   - Maintain or improve word count vs. competitors

4. **Track Changes**
   - Document what was added, updated, or removed
   - Note new sections vs. preserved sections
   - Record SEO improvements made

5. **Quality Check**
   - Verify brand voice consistency (`context/brand-voice.md`)
   - Confirm SEO requirements met (`context/seo-guidelines.md`)

## Output

Save to: `rewrites/[topic-slug]-rewrite-[YYYY-MM-DD].md`

Format:
```
---
title: [Updated Meta Title]
description: [Updated Meta Description]
focus_keyword: [Primary Keyword]
date: [YYYY-MM-DD]
original_url: [URL if rewriting existing post]
status: rewrite
---

[Full rewritten article]

---
## Change Summary
### Added
- [New sections or content added]

### Updated
- [Statistics, examples, or sections refreshed]

### Removed
- [Outdated content removed]

### Preserved
- [Sections kept as-is]

### SEO Improvements
- [Specific SEO changes made]
```

## Context Files to Reference
- `context/brand-voice.md` — voice and tone
- `context/style-guide.md` — editorial standards
- `context/seo-guidelines.md` — SEO requirements
- `context/internal-links-map.md` — current internal links

## Instructions

Rewrite the content about "$ARGUMENTS" to be competitive with current top-ranking articles while maintaining brand voice. Preserve what works, fix what doesn't, and add what's missing. Track all changes clearly.
