# /priorities

Generate a content prioritization matrix to identify highest-impact content tasks.

## Usage
`/priorities`

## What This Command Does

1. **Audit Published Content**
   - List all files in `published/` directory
   - Check `context/target-keywords.md` for tracked keywords
   - Review any analysis files in `research/`

2. **Opportunity Scoring**
   Score each content opportunity on these factors (0-100):
   - **Traffic Potential**: estimated search volume for target keyword
   - **Current Performance**: existing rank, CTR (from GSC if available)
   - **Competitive Gap**: gap vs. top-ranking content
   - **Business Value**: alignment with conversion goals
   - **Effort**: estimated time to create/update
   - **Freshness**: how outdated is existing content

3. **Prioritization Matrix**
   Categorize tasks into:
   - **Quick Wins**: high impact, low effort (do this week)
   - **Strategic Projects**: high impact, higher effort (plan this month)
   - **Maintenance Tasks**: lower impact updates (batch quarterly)
   - **New Content**: high-opportunity topics not yet covered

4. **Week-by-Week Roadmap**
   - Week 1: [top priority tasks]
   - Week 2: [next priority tasks]
   - Week 3-4: [upcoming tasks]

## Output

Print the prioritization matrix to screen and save to: `research/priorities-[YYYY-MM-DD].md`

Format:
```
## Content Priority Matrix — [Date]

### Quick Wins (Do This Week)
| Topic | Current Status | Opportunity | Action |
|-------|---------------|-------------|--------|

### Strategic Projects (This Month)
| Topic | Effort | Impact | Target Keyword |
|-------|--------|--------|---------------|

### New Content Opportunities
| Topic | Search Intent | Est. Volume | Priority |
|-------|--------------|-------------|---------|

### Week-by-Week Roadmap
**Week 1**: ...
**Week 2**: ...
```

## Instructions

Analyze all content context and available data to build a prioritized content roadmap. Reference `context/target-keywords.md`, `research/` analysis files, and `published/` content. Provide clear, actionable priorities that maximize SEO and business impact.
