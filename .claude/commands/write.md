# /write

Create a long-form, SEO-optimized article (2,000-3,000+ words) on the given topic.

## Usage
`/write [topic or research brief path]`

## What This Command Does

1. **Pre-Writing Setup**
   - Load brand voice from `context/brand-voice.md`
   - Load style guide from `context/style-guide.md`
   - Load SEO guidelines from `context/seo-guidelines.md`
   - Check `context/target-keywords.md` for target keyword
   - If a research brief exists in `research/`, use it as the outline

2. **Article Writing**
   - Write 2,000-3,000+ word article following brand voice
   - Use proper H1 > H2 > H3 heading hierarchy
   - Integrate primary keyword in: H1, first 100 words, 2-3 H2s, conclusion
   - Maintain 1-2% keyword density for primary keyword
   - Include secondary keywords naturally throughout
   - Add 3-5 internal links with descriptive anchor text
   - Add 2-3 external links to authority sources
   - Write compelling introduction with hook, problem, and promise
   - Include actionable advice, examples, and data
   - Write clear conclusion with CTA

3. **Meta Elements**
   - Meta title: 50-60 characters, includes primary keyword
   - Meta description: 150-160 characters, compelling and keyword-rich
   - Focus keyword for Yoast/SEO plugin

4. **SEO Checklist**
   - Verify all SEO requirements from `context/seo-guidelines.md`

5. **Auto-Trigger Agents**
   After writing, automatically run these agents:
   - SEO Optimizer — on-page SEO analysis
   - Meta Creator — generate multiple title/description options
   - Internal Linker — specific internal linking suggestions
   - Keyword Mapper — keyword placement and density analysis

## Output

Save article to: `drafts/[topic-slug]-[YYYY-MM-DD].md`

Article format:
```
---
title: [Meta Title]
description: [Meta Description]
focus_keyword: [Primary Keyword]
date: [YYYY-MM-DD]
status: draft
---

[Full article content]

---
## SEO Checklist
[Auto-generated checklist]
```

## Context Files to Reference
- `context/brand-voice.md` — voice, tone, and messaging
- `context/writing-examples.md` — exemplary articles for style reference
- `context/style-guide.md` — editorial standards
- `context/seo-guidelines.md` — SEO requirements
- `context/target-keywords.md` — keyword targets
- `context/internal-links-map.md` — internal linking

## Instructions

Read all context files above. Write a comprehensive, engaging article about "$ARGUMENTS" that genuinely helps the target reader, maintains brand voice, and meets all SEO requirements. After completing the article, invoke the SEO Optimizer, Meta Creator, Internal Linker, and Keyword Mapper agents to analyze the content.
