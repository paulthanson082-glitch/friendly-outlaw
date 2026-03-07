# /landing-audit

Audit an existing landing page for CRO issues and optimization opportunities.

## Usage
`/landing-audit [URL or file path]`

## What This Command Does

1. **Above-the-Fold Analysis**
   - Headline clarity and value proposition
   - CTA visibility and prominence
   - Trust signals present
   - Page load signals (mobile-first)

2. **CTA Analysis**
   - Number and placement of CTAs
   - Button copy clarity and action-orientation
   - CTA color/contrast (described)
   - Form friction (fields, length)

3. **Trust Signal Audit**
   - Testimonials: specificity and credibility
   - Social proof: numbers, logos, reviews
   - Risk reversals: guarantees, trials, refunds
   - Authority signals: awards, press, certifications

4. **Page Structure**
   - Logical flow and narrative arc
   - Objection handling presence
   - FAQ section
   - Mobile layout considerations

5. **CRO Score (0-100)**
   - Above fold: X/25
   - CTAs: X/25
   - Trust signals: X/25
   - Structure & copy: X/25

6. **A/B Test Recommendations**
   - Priority tests to run
   - Hypothesis for each test
   - Expected impact

## Output

Save to: `audits/landing-audit-[topic-slug]-[YYYY-MM-DD].md`

## Instructions

Audit the landing page at "$ARGUMENTS" against CRO best practices in `context/cro-best-practices.md`. Provide a scored assessment with specific, actionable improvements. Include A/B test recommendations with clear hypotheses.
