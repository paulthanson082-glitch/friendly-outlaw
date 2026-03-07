# SEO Machine

A specialized Claude Code workspace for creating long-form, SEO-optimized blog content for any business.

## What's Included

### Custom Commands (`.claude/commands/`)

| Command | Purpose |
|---------|---------|
| `/research [topic]` | Keyword research + competitor analysis → research brief |
| `/write [topic]` | Write 2,000-3,000+ word SEO article (auto-triggers agents) |
| `/rewrite [topic]` | Update and improve existing content |
| `/analyze-existing [URL/file]` | Audit existing content with health score (0-100) |
| `/optimize [file]` | Final SEO pass before publishing |
| `/publish-draft [file]` | Publish to WordPress via REST API with Yoast SEO |
| `/article [topic]` | All-in-one: research + write + optimize |
| `/priorities` | Content prioritization matrix |
| `/scrub [file]` | Remove AI watermarks and robotic patterns |
| `/performance-review` | Analytics-driven content performance analysis |
| `/research-serp [keyword]` | SERP analysis for a target keyword |
| `/research-gaps` | Competitor content gap analysis |
| `/research-trending` | Trending topic opportunities |
| `/research-performance` | Performance-based content priorities |
| `/research-topics [pillar]` | Topic cluster research |
| `/landing-write [topic]` | Create conversion-optimized landing page |
| `/landing-audit [file]` | CRO audit for landing pages |
| `/landing-research [topic]` | Competitor landing page research |
| `/landing-competitor [URL]` | Deep competitor landing page teardown |
| `/landing-publish [file]` | Publish landing page to WordPress |

### Specialized Agents (`.claude/agents/`)

| Agent | Purpose |
|-------|---------|
| `content-analyzer` | Comprehensive content analysis (5 modules) |
| `seo-optimizer` | On-page SEO audit and recommendations |
| `meta-creator` | Generate 5 meta title + 5 description variations |
| `internal-linker` | Strategic internal linking recommendations |
| `keyword-mapper` | Keyword placement and density analysis |
| `editor` | Human-sounding content transformation |
| `performance` | Data-driven content prioritization |
| `headline-generator` | 10+ headline variations with A/B testing |
| `cro-analyst` | CRO analysis for landing pages |
| `landing-page-optimizer` | Integrated SEO + CRO optimization |

### Marketing Skills (`.claude/skills/`)

26 marketing skills for copywriting, CRO, strategy, channels, and more:

- **Copywriting**: `/copywriting`, `/copy-editing`
- **CRO**: `/page-cro`, `/form-cro`, `/signup-flow-cro`, `/onboarding-cro`, `/popup-cro`, `/paywall-upgrade-cro`
- **Strategy**: `/content-strategy`, `/pricing-strategy`, `/launch-strategy`, `/marketing-ideas`
- **Channels**: `/email-sequence`, `/social-content`, `/paid-ads`
- **SEO**: `/seo-audit`, `/schema-markup`, `/programmatic-seo`, `/competitor-alternatives`
- **Analytics**: `/analytics-tracking`, `/ab-test-setup`
- **Other**: `/referral-program`, `/free-tool-strategy`, `/marketing-psychology`

### Analysis Modules (`data_sources/modules/`)

| Module | Purpose |
|--------|---------|
| `search_intent_analyzer.py` | Classify keyword intent (informational/commercial/transactional) |
| `keyword_analyzer.py` | Density, distribution, clustering, stuffing detection |
| `seo_quality_rater.py` | Comprehensive SEO score (0-100) |
| `content_length_comparator.py` | Compare length to SERP competitors |
| `readability_scorer.py` | Flesch scores, passive voice, sentence analysis |
| `google_analytics.py` | GA4 traffic and engagement data |
| `google_search_console.py` | Rankings, CTR, quick wins |
| `dataforseo.py` | Keyword data, SERP analysis |

## Getting Started

### 1. Configure Context Files

Fill out the templates in `context/` with your business information:

| File | What to Add |
|------|-------------|
| `context/brand-voice.md` | Brand voice, tone, messaging, target reader |
| `context/writing-examples.md` | 3-5 full examples of your best articles |
| `context/style-guide.md` | Editorial standards, grammar, formatting |
| `context/seo-guidelines.md` | Review and adjust SEO requirements |
| `context/target-keywords.md` | Keyword research organized by topic cluster |
| `context/internal-links-map.md` | All key pages with URLs and anchor text |
| `context/competitor-analysis.md` | Competitor content strategy analysis |
| `context/features.md` | Product/service features and benefits |
| `context/cro-best-practices.md` | Review and customize CRO standards |

### 2. (Optional) Configure Analytics

For data-driven insights, configure one or more integrations:

```bash
cp .env.example .env
# Edit .env with your credentials

pip install -r data_sources/requirements.txt

python3 data_sources/test_connections.py
```

See `data_sources/README.md` for detailed setup.

### 3. (Optional) Configure WordPress Publishing

To publish directly to WordPress:
1. Install `wordpress/seo-machine-yoast-rest.php` as an MU-plugin
2. Create an Application Password in WordPress Admin
3. Add WordPress credentials to `.env`

See `wordpress/README.md` for detailed setup.

### 4. Start Creating Content

```
/research your topic here
/write your topic here
/optimize drafts/your-article-2025-01-01.md
```

## Directory Structure

```
.claude/
├── commands/          # 19 custom workflow commands
├── agents/            # 10 specialized analysis agents
└── skills/            # 26 marketing skills

context/               # Your business context (fill these out!)
├── brand-voice.md
├── writing-examples.md
├── style-guide.md
├── seo-guidelines.md
├── target-keywords.md
├── internal-links-map.md
├── competitor-analysis.md
├── features.md
└── cro-best-practices.md

data_sources/          # Analytics integrations + analysis modules
├── modules/           # Python analysis modules
├── config/            # API credentials (git-ignored)
└── cache/             # API response cache (git-ignored)

config/                # Configuration
└── competitors.example.json

wordpress/             # WordPress integration
├── seo-machine-yoast-rest.php
└── README.md

topics/                # Topic ideas
research/              # Research briefs and analysis reports
drafts/                # Work in progress articles
review-required/       # Articles pending review
published/             # Final published versions
rewrites/              # Updated existing content
landing-pages/         # Landing page content
audits/                # Audit reports
```

## Content Quality Standards

Every article must meet:

- **2,000+ words** (2,500-3,000+ preferred; match/beat competitor median)
- **Primary keyword density**: 1-2%
- **Keyword in**: H1, first 100 words, 2+ H2s, meta title, meta description
- **Internal links**: 3-5 with descriptive anchor text
- **External links**: 2-3 to authority sources
- **Meta title**: 50-60 characters
- **Meta description**: 150-160 characters
- **Reading level**: 8th-10th grade (Flesch-Kincaid)

## Workflow

### Creating New Content
1. `/research [topic]` → research brief in `research/`
2. `/write [topic]` → article in `drafts/` + agent reports
3. Review and edit based on agent feedback
4. `/optimize [file]` → optimization report
5. `/publish-draft [file]` → WordPress draft

### Updating Existing Content
1. `/analyze-existing [URL]` → analysis in `research/`
2. `/rewrite [topic]` → updated article in `rewrites/`
3. `/optimize [file]` → optimization report
4. `/publish-draft [file]` → update WordPress

## Tips

- **Fill out context files thoroughly** — content quality depends on them
- **Always research before writing** — skip at your peril
- **Review agent output** — agents catch what you miss
- **Address critical issues** before publishing
- **Update `internal-links-map.md`** after every publish
