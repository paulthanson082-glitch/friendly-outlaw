# /landing-write

Create a conversion-optimized landing page for a product, feature, or campaign.

## Usage
`/landing-write [topic/product]`

## What This Command Does

1. **Research Phase**
   - Analyze top competitor landing pages for this topic
   - Identify primary value proposition and target persona
   - Define conversion goal (signup, demo, purchase, download)

2. **Structure**
   - Above-the-fold: headline, subheadline, primary CTA, hero image alt text
   - Problem section: articulate the pain point
   - Solution section: introduce your solution
   - Features/Benefits: 3-6 key benefits with proof points
   - Social proof: testimonials, logos, numbers
   - Objection handling: FAQ or risk reversal
   - Secondary CTA section
   - Footer CTA

3. **Copywriting**
   - Headline variations (5 options)
   - Subheadline options (3 options)
   - CTA button text options (5 options)
   - Value proposition statement
   - Full page copy following brand voice

4. **SEO Elements**
   - Page title tag
   - Meta description
   - Header tags (H1, H2s)
   - Target keyword integration

## Output

Save to: `landing-pages/[topic-slug]-[YYYY-MM-DD].md`

## Context Files to Reference
- `context/brand-voice.md`
- `context/features.md`
- `context/style-guide.md`
- `context/cro-best-practices.md`

## Instructions

Write a high-converting landing page for "$ARGUMENTS". Focus on clear value proposition, strong CTAs, and social proof. Follow CRO best practices from `context/cro-best-practices.md` and brand voice from `context/brand-voice.md`.
