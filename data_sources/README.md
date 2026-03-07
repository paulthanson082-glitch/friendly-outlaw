# Data Sources Setup

This directory contains integrations with analytics and data APIs used by SEO Machine.

## Installation

```bash
pip install -r requirements.txt
```

Also download NLTK data (one-time setup):

```python
import nltk
nltk.download('punkt')
nltk.download('stopwords')
```

## Configuration

### 1. Create Credentials Directory

```bash
mkdir -p data_sources/config
```

The `config/` directory is git-ignored. Never commit credentials.

### 2. Google Analytics 4

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a project or select an existing one
3. Enable the **Google Analytics Data API**
4. Create a **Service Account** with Viewer role
5. Download the JSON key file
6. Save as `data_sources/config/ga4_credentials.json`
7. In GA4, grant the service account **Viewer** access to your property
8. Add your property ID to `.env`:

```
GA4_PROPERTY_ID=123456789
```

### 3. Google Search Console

1. In the same Google Cloud project, enable the **Search Console API**
2. The same service account key works for both GA4 and GSC
3. In Search Console, add the service account email as a **Full** user
4. Add your site URL to `.env`:

```
GSC_SITE_URL=https://yoursite.com
```

### 4. DataForSEO

1. Sign up at [DataForSEO](https://dataforseo.com/)
2. Get your API login and password
3. Add to `.env`:

```
DATAFORSEO_LOGIN=your_login
DATAFORSEO_PASSWORD=your_password
```

### 5. Environment File

Copy `.env.example` to `.env` and fill in your values:

```bash
cp .env.example .env
```

## Testing Connections

```bash
# Test all connections
python3 data_sources/test_connections.py

# Test DataForSEO specifically
python3 data_sources/test_dataforseo.py
```

## Module Reference

| Module | Purpose | Requires |
|--------|---------|---------|
| `google_analytics.py` | GA4 traffic and engagement data | GA4 credentials |
| `google_search_console.py` | GSC rankings and CTR | GSC credentials |
| `dataforseo.py` | Keyword data and SERP analysis | DataForSEO account |
| `data_aggregator.py` | Combines data from all sources | All above |
| `search_intent_analyzer.py` | Classify keyword search intent | None (local) |
| `keyword_analyzer.py` | Keyword density and clustering | None (local) |
| `seo_quality_rater.py` | Comprehensive SEO scoring | None (local) |
| `content_length_comparator.py` | SERP competitor length analysis | requests |
| `readability_scorer.py` | Flesch-Kincaid and readability | textstat |

## Usage Examples

```python
# Get GA4 traffic for last 30 days
from data_sources.modules.google_analytics import GoogleAnalytics
ga = GoogleAnalytics()
data = ga.get_page_performance(days=30)

# Analyze keyword density
from data_sources.modules.keyword_analyzer import KeywordAnalyzer
analyzer = KeywordAnalyzer()
result = analyzer.analyze(text="your article text", keyword="target keyword")

# Get readability score
from data_sources.modules.readability_scorer import ReadabilityScorer
scorer = ReadabilityScorer()
score = scorer.score(text="your article text")
```
