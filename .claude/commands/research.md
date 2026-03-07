# /research

Perform comprehensive keyword and competitive research for a given topic before writing.

## Usage
`/research [topic]`

## What This Command Does

1. **Keyword Research**
   - Identify primary keyword and 5-10 secondary keywords
   - Find long-tail keyword variations
   - Classify search intent (informational/navigational/transactional/commercial)
   - Estimate search volume and difficulty tiers

2. **Competitor Analysis**
   - Analyze top 10 SERP results for the primary keyword
   - Summarize each competitor's angle, word count, key sections
   - Identify content gaps and what's missing from current results

3. **Content Planning**
   - Recommend optimal article length based on SERP data
   - Create a detailed outline with H2/H3 structure
   - Identify "People Also Ask" questions to answer
   - Suggest internal linking opportunities (from context/internal-links-map.md)
   - List external authority sources to cite

4. **Meta Element Preview**
   - Draft candidate meta title (50-60 chars)
   - Draft candidate meta description (150-160 chars)

## Output

Save research brief to: `research/brief-[topic-slug]-[YYYY-MM-DD].md`

The brief should include:
- **Topic**: [topic]
- **Primary Keyword**: with search intent label
- **Secondary Keywords**: list
- **Competitor Summary Table**: competitor | angle | word count | key sections
- **Content Gaps**: what top results miss
- **Recommended Outline**: H1 > H2 > H3 hierarchy
- **PAA Questions**: list of People Also Ask questions
- **Internal Links**: relevant pages from context/internal-links-map.md
- **External Sources**: authority sites to cite
- **Meta Preview**: title and description drafts

## Context Files to Reference
- `context/target-keywords.md` — existing keyword clusters and rankings
- `context/competitor-analysis.md` — known competitors and gaps
- `context/internal-links-map.md` — internal linking opportunities
- `context/seo-guidelines.md` — SEO requirements

## Instructions

Read the context files above, then conduct research on "$ARGUMENTS". Create a thorough research brief that will guide writing a best-in-class article on this topic. Focus on what differentiates your brand and fills genuine content gaps.
