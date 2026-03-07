# /scrub

Remove AI watermarks and robotic patterns from content to make it sound more human.

## Usage
`/scrub [file path]`

## What This Command Does

Scans the article for common AI writing patterns and replaces them with more natural, human-sounding alternatives.

### Patterns to Remove

**Em-dash overuse**
- Replace excessive em-dashes with varied punctuation (commas, periods, parentheses)

**Filler phrases**
- "In today's [adjective] world/landscape/environment"
- "It's important to note that..."
- "It's worth mentioning that..."
- "As we all know..."
- "Without further ado..."
- "In conclusion, it's clear that..."
- "Needless to say..."
- "At the end of the day..."
- "In this article, we will explore..."
- "This comprehensive guide will..."

**Robotic transitions**
- Replace mechanical transitions ("Furthermore," "Moreover," "Additionally," at sentence starts) with varied, natural connectors

**Hollow intensifiers**
- Remove or replace: "very," "really," "truly," "incredibly," "absolutely," "certainly," "undoubtedly," "obviously"

**Passive voice overuse**
- Convert passive constructions to active voice where natural

**Overly formal phrasing**
- "Utilize" → "use"
- "Leverage" → "use" or "apply"
- "Implement" → "add" or "use" (where simpler)
- "Facilitate" → "help" or "enable"
- "Demonstrate" → "show"
- "Regarding" → "about"
- "Subsequently" → "then" or "next"

**AI-specific patterns**
- Lists of exactly 3 items in every paragraph
- Identical sentence structures repeated throughout
- Section summaries that restate what was just said
- Unnecessary "key takeaway" boxes that repeat the paragraph

## Output

Overwrite the file with the scrubbed version, or save to a new file with `-scrubbed` suffix.

Provide a summary of changes made:
```
## Scrub Summary
- Em-dashes replaced: X
- Filler phrases removed: X
- Passive voice converted: X
- Robotic words replaced: X
- Other patterns fixed: X
```

## Instructions

Read the article at "$ARGUMENTS" and systematically identify and fix all AI watermark patterns listed above. Make the content sound like it was written by a thoughtful human expert who is knowledgeable but conversational. Preserve all factual content — only change the phrasing and structure, not the substance.
