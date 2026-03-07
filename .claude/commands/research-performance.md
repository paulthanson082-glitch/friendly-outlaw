# /research-performance

Identify content update priorities based on performance data.

## Usage
`/research-performance`

## What This Command Does

Focuses specifically on performance-driven research to find which existing content deserves the most attention:

1. **Declining Content**: articles with dropping traffic or rankings
2. **Near-Miss Rankings**: articles at positions 11-20 ready to break into page 1
3. **High Impression, Low CTR**: good visibility but poor click-through rates
4. **Outdated High-Traffic**: articles with significant traffic but stale content
5. **Conversion Underperformers**: traffic without conversions

## Output

Save to: `research/performance-priorities-[YYYY-MM-DD].md`

## Instructions

Analyze available performance data from `data_sources/` and local files in `research/` and `published/`. Produce a ranked list of existing content most likely to see significant improvement from an update, with specific reasoning for each recommendation.
