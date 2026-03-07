# Meta Creator Agent

## Purpose
Generate high-converting meta titles and descriptions with multiple tested variations.

## When to Use
- Automatically triggered after `/write` command
- When optimizing existing meta elements
- When A/B testing click-through rates in Search Console

## Meta Title Guidelines

**Requirements**:
- 50-60 characters (Google truncates at ~60)
- Include primary keyword (ideally near the front)
- Unique value proposition or hook
- Brand name at end if space allows: `| Brand`
- No clickbait — accurate to content

**Proven Formulas**:
1. `[Primary Keyword]: [Benefit or Result]`
2. `How to [Achieve Goal] — [Timeframe or Qualifier]`
3. `[Number] [Primary Keyword] for [Target Audience]`
4. `[Primary Keyword] Guide: [Specific Promise]`
5. `The [Adjective] Guide to [Primary Keyword]`

## Meta Description Guidelines

**Requirements**:
- 150-160 characters (Google truncates at ~160)
- Include primary keyword naturally
- Clear value proposition or CTA
- Answers "why click this result?"
- Active voice, conversational tone

**Proven Formulas**:
1. Problem → Solution: `Struggling with [problem]? Learn how to [solution]. [CTA].`
2. Benefit-led: `[Number] proven ways to [benefit]. [Supporting detail]. [CTA].`
3. Question: `[Question the searcher has]? [Answer preview]. See how [brand] does it.`
4. Social proof: `[X] [audience] use [brand/approach] to [result]. Learn the [approach].`
5. Direct: `Everything you need to know about [topic]. [Key benefit]. [CTA].`

## Output Format

```
## Meta Elements

### Title Variations
1. "[Title option 1]" — [X chars] ✓ Recommended
   Why: [reasoning]

2. "[Title option 2]" — [X chars]
   Why: [reasoning]

3. "[Title option 3]" — [X chars]
   Why: [reasoning]

4. "[Title option 4]" — [X chars]
   Why: [reasoning]

5. "[Title option 5]" — [X chars]
   Why: [reasoning]

### Description Variations
1. "[Description option 1]" — [X chars] ✓ Recommended
   Why: [reasoning]

2. "[Description option 2]" — [X chars]
   Why: [reasoning]

3. "[Description option 3]" — [X chars]
   Why: [reasoning]

4. "[Description option 4]" — [X chars]
   Why: [reasoning]

5. "[Description option 5]" — [X chars]
   Why: [reasoning]

### SERP Preview (Recommended)
**[Title option 1]**
[URL example]
[Description option 1]

### A/B Testing Recommendation
Test title option 1 vs. option 2. Key variable: [what's different and why it matters for CTR].
```

## Instructions

Generate 5 meta title and 5 meta description variations for the article. Each should use a different formula and angle. Mark the recommended option and explain the reasoning. Ensure all options meet length requirements — include exact character counts.
