"""
Test Data Source Connections
Run this to verify your analytics integrations are working.
"""

import sys
import os

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def test_ga4():
    """Test Google Analytics 4 connection."""
    print("\n--- Google Analytics 4 ---")
    try:
        from data_sources.modules.google_analytics import GoogleAnalytics
        ga = GoogleAnalytics()
        if ga.is_configured():
            data = ga.get_page_performance(days=7, limit=5)
            print(f"✓ Connected! Retrieved {len(data)} pages.")
            if data:
                print(f"  Top page: {data[0]['page_path']} ({data[0]['sessions']} sessions)")
        else:
            print("⚠ Not configured — GA4_PROPERTY_ID or credentials missing")
            print("  See data_sources/README.md for setup instructions")
    except Exception as e:
        print(f"✗ Error: {e}")


def test_gsc():
    """Test Google Search Console connection."""
    print("\n--- Google Search Console ---")
    try:
        from data_sources.modules.google_search_console import GoogleSearchConsole
        gsc = GoogleSearchConsole()
        if gsc.is_configured():
            data = gsc.get_page_rankings(days=7, row_limit=5)
            print(f"✓ Connected! Retrieved {len(data)} ranking rows.")
        else:
            print("⚠ Not configured — GSC_SITE_URL or credentials missing")
            print("  See data_sources/README.md for setup instructions")
    except Exception as e:
        print(f"✗ Error: {e}")


def test_dataforseo():
    """Test DataForSEO connection."""
    print("\n--- DataForSEO ---")
    try:
        from data_sources.modules.dataforseo import DataForSEO
        dfs = DataForSEO()
        if dfs.is_configured():
            data = dfs.get_keyword_data(["test keyword"])
            print(f"✓ Connected! Retrieved data for {len(data)} keywords.")
        else:
            print("⚠ Not configured — DATAFORSEO_LOGIN or DATAFORSEO_PASSWORD missing")
            print("  See data_sources/README.md for setup instructions")
    except Exception as e:
        print(f"✗ Error: {e}")


def test_local_modules():
    """Test local analysis modules (no API required)."""
    print("\n--- Local Analysis Modules ---")

    try:
        from data_sources.modules.search_intent_analyzer import SearchIntentAnalyzer
        analyzer = SearchIntentAnalyzer()
        result = analyzer.analyze("how to start a podcast")
        print(f"✓ SearchIntentAnalyzer: '{result['primary_intent']}' intent detected")
    except Exception as e:
        print(f"✗ SearchIntentAnalyzer: {e}")

    try:
        from data_sources.modules.keyword_analyzer import KeywordAnalyzer
        analyzer = KeywordAnalyzer()
        result = analyzer.analyze("This is a test article about testing.", "testing")
        print(f"✓ KeywordAnalyzer: {result['primary_keyword']['density']}% density")
    except Exception as e:
        print(f"✗ KeywordAnalyzer: {e}")

    try:
        from data_sources.modules.readability_scorer import ReadabilityScorer
        scorer = ReadabilityScorer()
        result = scorer.score("This is a simple test sentence. It should score well.")
        print(f"✓ ReadabilityScorer: Flesch score {result['flesch_reading_ease']['score']}")
    except Exception as e:
        print(f"✗ ReadabilityScorer: {e}")

    try:
        from data_sources.modules.seo_quality_rater import SEOQualityRater
        rater = SEOQualityRater()
        result = rater.rate("# Test Article\n\nThis is a test about testing.", "testing")
        print(f"✓ SEOQualityRater: {result['total_score']}/100")
    except Exception as e:
        print(f"✗ SEOQualityRater: {e}")

    try:
        from data_sources.modules.content_length_comparator import ContentLengthComparator
        comp = ContentLengthComparator()
        result = comp.compare(2000, "test keyword", [1800, 2200, 2500])
        print(f"✓ ContentLengthComparator: {result['competitive_position']['assessment']}")
    except Exception as e:
        print(f"✗ ContentLengthComparator: {e}")


if __name__ == "__main__":
    print("SEO Machine — Connection Tests")
    print("=" * 40)

    test_local_modules()
    test_ga4()
    test_gsc()
    test_dataforseo()

    print("\n" + "=" * 40)
    print("Tests complete. See above for status of each integration.")
