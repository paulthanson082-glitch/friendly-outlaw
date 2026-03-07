"""
Content Length Comparator
Analyzes content length relative to SERP competitors.
"""

import re
import statistics
from typing import Optional


class ContentLengthComparator:
    """
    Compares content length against estimated SERP competitor lengths.

    Note: For accurate competitor data, integrate with a SERP API (DataForSEO, etc.)
    This module provides analysis logic and estimation utilities.
    """

    def compare(
        self,
        your_word_count: int,
        keyword: str,
        competitor_word_counts: Optional[list] = None,
        content_type: str = "blog_post",
    ) -> dict:
        """
        Compare your content length against competitors.

        Args:
            your_word_count: Your article's word count
            keyword: Target keyword (for recommendations)
            competitor_word_counts: List of competitor word counts (if available)
            content_type: Type of content for benchmarking

        Returns:
            dict with comparison data and recommendations
        """
        # Use provided competitor data or benchmark estimates
        if competitor_word_counts and len(competitor_word_counts) >= 3:
            comp_data = self._analyze_competitors(competitor_word_counts)
        else:
            comp_data = self._get_benchmark_estimates(content_type)
            comp_data["note"] = "Using benchmark estimates. Provide actual competitor data for accuracy."

        # Gap analysis
        gap_to_median = your_word_count - comp_data["median"]
        gap_to_75th = your_word_count - comp_data["percentile_75"]

        # Position in competitive landscape
        if competitor_word_counts:
            position = sum(1 for c in competitor_word_counts if c > your_word_count) + 1
            percentile = round((1 - position / len(competitor_word_counts)) * 100, 0)
        else:
            position = None
            percentile = None

        # Recommendation
        recommendation = self._get_recommendation(
            your_word_count, comp_data["median"], comp_data["percentile_75"]
        )

        return {
            "your_word_count": your_word_count,
            "competitor_stats": comp_data,
            "gap_to_median": gap_to_median,
            "gap_to_75th_percentile": gap_to_75th,
            "competitive_position": {
                "rank": position,
                "percentile": percentile,
                "assessment": self._position_assessment(gap_to_median, gap_to_75th),
            },
            "recommendation": recommendation,
            "target_word_count": self._get_target(comp_data["median"], comp_data["percentile_75"]),
        }

    def _analyze_competitors(self, word_counts: list) -> dict:
        """Calculate statistics from competitor word counts."""
        sorted_counts = sorted(word_counts)
        return {
            "count": len(word_counts),
            "min": min(word_counts),
            "max": max(word_counts),
            "median": int(statistics.median(word_counts)),
            "mean": int(statistics.mean(word_counts)),
            "percentile_75": int(self._percentile(sorted_counts, 75)),
            "percentile_90": int(self._percentile(sorted_counts, 90)),
        }

    def _percentile(self, sorted_list: list, p: float) -> float:
        """Calculate the p-th percentile of a sorted list."""
        if not sorted_list:
            return 0
        idx = (p / 100) * (len(sorted_list) - 1)
        lower = int(idx)
        upper = min(lower + 1, len(sorted_list) - 1)
        fraction = idx - lower
        return sorted_list[lower] + fraction * (sorted_list[upper] - sorted_list[lower])

    def _get_benchmark_estimates(self, content_type: str) -> dict:
        """Return benchmark estimates when no competitor data is available."""
        benchmarks = {
            "blog_post": {
                "median": 1800,
                "percentile_75": 2500,
                "percentile_90": 3500,
                "mean": 2000,
                "min": 800,
                "max": 5000,
            },
            "how_to_guide": {
                "median": 2200,
                "percentile_75": 3000,
                "percentile_90": 4500,
                "mean": 2500,
                "min": 1200,
                "max": 6000,
            },
            "comparison": {
                "median": 2000,
                "percentile_75": 2800,
                "percentile_90": 4000,
                "mean": 2200,
                "min": 1000,
                "max": 5000,
            },
            "landing_page": {
                "median": 800,
                "percentile_75": 1200,
                "percentile_90": 1800,
                "mean": 900,
                "min": 400,
                "max": 2500,
            },
        }
        return benchmarks.get(content_type, benchmarks["blog_post"])

    def _position_assessment(self, gap_to_median: int, gap_to_75th: int) -> str:
        if gap_to_75th >= 0:
            return "Strong — in top 25% of competitors by length"
        elif gap_to_median >= 0:
            return "Competitive — above median competitor length"
        elif gap_to_median >= -300:
            return "Near median — within 300 words of competitor median"
        else:
            return "Below median — significantly shorter than competitors"

    def _get_recommendation(self, your_count: int, median: int, p75: int) -> str:
        if your_count >= p75:
            return "Content length is competitive. Focus on quality over quantity."
        elif your_count >= median:
            words_to_add = p75 - your_count
            return f"Consider adding ~{words_to_add:,} more words to reach the 75th percentile ({p75:,} words)."
        else:
            words_to_add = median - your_count
            return (
                f"Content is below the competitive median. Add at least {words_to_add:,} words "
                f"to reach median ({median:,} words). Target {p75:,} words for top-quartile depth."
            )

    def _get_target(self, median: int, p75: int) -> int:
        """Calculate the recommended target word count."""
        # Aim for 75th percentile or at least median + 10%
        return max(p75, int(median * 1.1))

    def from_text(self, text: str, keyword: str, competitor_word_counts: Optional[list] = None,
                  content_type: str = "blog_post") -> dict:
        """
        Analyze content length from text directly.

        Args:
            text: Your article text
            keyword: Target keyword
            competitor_word_counts: Optional list of competitor word counts
            content_type: Content type for benchmarking
        """
        # Clean markdown and count words
        clean = re.sub(r'^#{1,6}\s+', '', text, flags=re.MULTILINE)
        clean = re.sub(r'\[([^\]]+)\]\([^\)]+\)', r'\1', clean)
        clean = re.sub(r'[*_`~]', '', clean)
        word_count = len(clean.split())

        return self.compare(word_count, keyword, competitor_word_counts, content_type)


if __name__ == "__main__":
    comparator = ContentLengthComparator()

    # Example with competitor data
    competitor_counts = [2100, 1800, 2800, 3200, 1950, 2400, 2050, 2700, 1600, 3500]

    result = comparator.compare(
        your_word_count=1850,
        keyword="how to start a podcast",
        competitor_word_counts=competitor_counts,
    )

    print("Content Length Analysis\n" + "=" * 50)
    print(f"Your word count: {result['your_word_count']:,}")
    print(f"\nCompetitor Stats:")
    stats = result['competitor_stats']
    print(f"  Median: {stats['median']:,}")
    print(f"  75th percentile: {stats['percentile_75']:,}")
    print(f"  Range: {stats['min']:,} - {stats['max']:,}")
    print(f"\nGap to median: {result['gap_to_median']:+,} words")
    print(f"Gap to 75th percentile: {result['gap_to_75th_percentile']:+,} words")
    print(f"\nPosition: {result['competitive_position']['assessment']}")
    print(f"\nRecommendation: {result['recommendation']}")
    print(f"Target word count: {result['target_word_count']:,}")
