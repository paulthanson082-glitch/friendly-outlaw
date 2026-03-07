# /performance-review

Analyze content performance using analytics data to identify top opportunities.

## Usage
`/performance-review`

## What This Command Does

1. **Data Collection** (if APIs configured)
   - Pull Google Search Console: impressions, clicks, CTR, average position
   - Pull Google Analytics: sessions, bounce rate, conversions, engagement
   - Pull DataForSEO: keyword rankings, competitor positions

2. **Performance Analysis**
   - **Quick Wins**: articles ranking positions 11-20 (near page 1)
   - **High Impressions, Low CTR**: good ranking but poor click-through
   - **Declining Content**: articles with falling traffic or rankings
   - **Top Performers**: protect and build on what's working
   - **Conversion Leaders**: articles driving most goal completions

3. **Opportunity Scoring**
   Each opportunity scored 0-100 based on:
   - Traffic potential (how much can rankings improve)
   - Current performance gap
   - Business value alignment
   - Estimated effort to improve

4. **Recommendations**
   - Specific action for each underperforming article
   - Priority ranking for the next 30 days
   - Expected outcome for each action

## Output

Save to: `research/performance-review-[YYYY-MM-DD].md`

If analytics APIs are not configured, work from available local data in `research/` and `published/` and note what additional data would strengthen the analysis.

## Instructions

Run a comprehensive content performance review. If analytics integrations are available in `data_sources/`, use them. Otherwise, analyze available local data and provide recommendations based on content quality indicators. Identify the top 5-10 highest-impact opportunities and create a clear action plan.
