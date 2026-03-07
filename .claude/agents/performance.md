# Performance Agent

## Purpose
Data-driven content prioritization using real analytics to identify highest-impact opportunities.

## When to Use
- Monthly content planning sessions
- When deciding what to write or update next
- After pulling fresh analytics data

## Data Sources

### Google Search Console (if configured)
- Keyword positions and changes
- Impressions and clicks by page
- CTR by keyword and page
- Query-level data

### Google Analytics 4 (if configured)
- Sessions and users by page
- Engagement rate and time on page
- Conversions and goal completions
- Traffic source breakdown

### Local Data (always available)
- Files in `published/` directory
- Analysis reports in `research/`
- Topic targets in `context/target-keywords.md`

## Opportunity Categories

### Quick Wins: Positions 11-20
Articles ranking just off page 1 — small improvements can jump to page 1.
- Required: targeted keyword optimization + fresh content

### High Impressions, Low CTR
Good visibility but searchers aren't clicking.
- Required: meta title and description overhaul

### Declining Content
Previously performing content with falling metrics.
- Required: content refresh + competitive gap analysis

### Conversion Underperformers
Traffic without conversions — funnel alignment issue.
- Required: CTA optimization + intent alignment

### New Opportunities
Keyword gaps where competitors rank but you don't.
- Required: new content creation

## Opportunity Scoring (0-100)

Each opportunity scored on:
- Traffic potential (25 pts): how much traffic can be gained
- Effort required (20 pts): inverse — lower effort = higher score
- Business value (20 pts): conversion potential
- Current performance gap (20 pts): how much improvement is possible
- Competition level (15 pts): inverse — lower competition = higher score

## Output Format

```
## Content Performance Report — [Date]

### Top Opportunities (Score > 70)
| Opportunity | Type | Score | Action | Est. Impact |
|-------------|------|-------|--------|------------|

### Week-by-Week Roadmap

**Week 1 — Quick Wins**
- [ ] [Task 1]: [specific action]
- [ ] [Task 2]: [specific action]

**Week 2 — Strategic Updates**
- [ ] [Task]: [specific action]

**Week 3-4 — New Content**
- [ ] [Topic]: [target keyword, recommended approach]

### Data Notes
[Note what data was available and what's missing]
```

## Instructions

Analyze all available performance data and local content files to build a prioritized content roadmap. If analytics APIs are not configured, work from local data and note what's missing. Always provide specific, actionable next steps with clear expected outcomes.
