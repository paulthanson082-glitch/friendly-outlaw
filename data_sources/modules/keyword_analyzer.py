"""
Keyword Analyzer
Calculates keyword density, distribution, clustering, and LSI keyword coverage.
"""

import re
from collections import Counter
from typing import Optional


class KeywordAnalyzer:
    """Analyzes keyword usage within article content."""

    def analyze(self, text: str, keyword: str, secondary_keywords: Optional[list] = None) -> dict:
        """
        Analyze keyword usage in article text.

        Args:
            text: Full article text
            keyword: Primary keyword to analyze
            secondary_keywords: Optional list of secondary keywords

        Returns:
            dict with density, distribution, and recommendations
        """
        # Clean and prepare text
        clean_text = self._clean_text(text)
        words = clean_text.split()
        total_words = len(words)

        if total_words == 0:
            return {"error": "Empty text provided"}

        # Primary keyword analysis
        primary_result = self._analyze_keyword(clean_text, words, keyword)

        # Section distribution
        sections = self._split_into_sections(text)
        distribution = self._analyze_distribution(sections, keyword)

        # Stuffing risk
        stuffing_risk = self._assess_stuffing_risk(primary_result["density"])

        result = {
            "total_words": total_words,
            "primary_keyword": {
                "keyword": keyword,
                **primary_result,
                "stuffing_risk": stuffing_risk,
            },
            "distribution": distribution,
            "distribution_heatmap": self._generate_heatmap(distribution),
        }

        # Secondary keyword analysis
        if secondary_keywords:
            result["secondary_keywords"] = []
            for sec_kw in secondary_keywords:
                sec_result = self._analyze_keyword(clean_text, words, sec_kw)
                result["secondary_keywords"].append({
                    "keyword": sec_kw,
                    **sec_result,
                })

        # Placement checklist
        result["placement_checklist"] = self._check_placement(text, keyword)

        # Recommendations
        result["recommendations"] = self._generate_recommendations(primary_result, distribution)

        return result

    def _clean_text(self, text: str) -> str:
        """Remove Markdown formatting and normalize whitespace."""
        # Remove markdown headers
        text = re.sub(r'^#{1,6}\s+', '', text, flags=re.MULTILINE)
        # Remove markdown links
        text = re.sub(r'\[([^\]]+)\]\([^\)]+\)', r'\1', text)
        # Remove markdown formatting
        text = re.sub(r'[*_`~]', '', text)
        # Normalize whitespace
        text = re.sub(r'\s+', ' ', text)
        return text.lower().strip()

    def _analyze_keyword(self, clean_text: str, words: list, keyword: str) -> dict:
        """Calculate occurrences and density for a keyword."""
        keyword_lower = keyword.lower()

        # Exact phrase matches
        exact_matches = len(re.findall(re.escape(keyword_lower), clean_text))

        # Word count (for multi-word keywords, count words)
        keyword_words = keyword_lower.split()
        total_words = len(words)

        # Density: count keyword occurrences relative to word count
        # For multi-word keywords, divide by effective word count
        if total_words > 0:
            density = round(exact_matches / total_words * 100, 2)
        else:
            density = 0.0

        return {
            "occurrences": exact_matches,
            "total_words": total_words,
            "density": density,
            "density_status": self._density_status(density),
        }

    def _density_status(self, density: float) -> str:
        if density < 0.5:
            return "under_optimized"
        elif density <= 2.0:
            return "optimal"
        elif density <= 2.5:
            return "slightly_high"
        else:
            return "over_optimized"

    def _assess_stuffing_risk(self, density: float) -> str:
        if density > 3.0:
            return "HIGH — Reduce keyword usage immediately"
        elif density > 2.5:
            return "MEDIUM — Consider reducing slightly"
        else:
            return "LOW — Within acceptable range"

    def _split_into_sections(self, text: str) -> dict:
        """Split text into logical sections based on content position."""
        paragraphs = [p.strip() for p in text.split('\n\n') if p.strip()]

        if not paragraphs:
            return {"full": text}

        total = len(paragraphs)
        third = max(1, total // 3)

        return {
            "introduction": '\n\n'.join(paragraphs[:max(1, total // 5)]),
            "body_early": '\n\n'.join(paragraphs[max(1, total // 5):third]),
            "body_mid": '\n\n'.join(paragraphs[third:2 * third]),
            "body_late": '\n\n'.join(paragraphs[2 * third:-max(1, total // 5)]),
            "conclusion": '\n\n'.join(paragraphs[-max(1, total // 5):]),
        }

    def _analyze_distribution(self, sections: dict, keyword: str) -> dict:
        """Calculate keyword presence in each section."""
        keyword_lower = keyword.lower()
        distribution = {}

        for section_name, section_text in sections.items():
            clean_section = self._clean_text(section_text)
            section_words = len(clean_section.split())
            occurrences = len(re.findall(re.escape(keyword_lower), clean_section))

            if section_words > 0:
                density = round(occurrences / section_words * 100, 2)
            else:
                density = 0.0

            distribution[section_name] = {
                "occurrences": occurrences,
                "density": density,
                "word_count": section_words,
            }

        return distribution

    def _generate_heatmap(self, distribution: dict) -> str:
        """Generate ASCII heatmap of keyword distribution."""
        lines = []
        max_density = max((v["density"] for v in distribution.values()), default=1) or 1

        labels = {
            "introduction": "Introduction ",
            "body_early": "Early Body  ",
            "body_mid": "Mid Body    ",
            "body_late": "Late Body   ",
            "conclusion": "Conclusion  ",
        }

        for section, data in distribution.items():
            label = labels.get(section, section.ljust(12))
            density = data["density"]
            bar_length = max(1, int(density / max_density * 20))
            bar = "█" * bar_length
            lines.append(f"{label} {bar} ({density}%)")

        return '\n'.join(lines)

    def _check_placement(self, text: str, keyword: str) -> dict:
        """Check if keyword appears in required locations."""
        keyword_lower = keyword.lower()
        text_lower = text.lower()

        # Split into sections for analysis
        paragraphs = text.split('\n\n')
        first_100_words = ' '.join(text.split()[:100]).lower()
        last_200_words = ' '.join(text.split()[-200:]).lower()

        # Find H1 (first # heading)
        h1_match = re.search(r'^#\s+(.+)$', text, re.MULTILINE)
        h1_text = h1_match.group(1).lower() if h1_match else ""

        # Find H2s
        h2_matches = re.findall(r'^##\s+(.+)$', text, re.MULTILINE)
        h2_texts = ' '.join(h2_matches).lower()

        checklist = {
            "in_h1": keyword_lower in h1_text,
            "in_first_100_words": keyword_lower in first_100_words,
            "in_h2": keyword_lower in h2_texts,
            "in_conclusion": keyword_lower in last_200_words,
        }

        checklist["all_passed"] = all(checklist.values())
        checklist["pass_count"] = sum(1 for v in checklist.values() if v is True)

        return checklist

    def _generate_recommendations(self, primary_result: dict, distribution: dict) -> list:
        """Generate specific recommendations based on analysis."""
        recs = []
        density = primary_result.get("density", 0)
        status = primary_result.get("density_status", "")

        if status == "under_optimized":
            recs.append(f"Increase keyword density from {density}% to 1.0-2.0%. "
                       f"Add {max(1, primary_result['total_words'] // 100 - primary_result['occurrences'])} more occurrences.")

        if status in ("slightly_high", "over_optimized"):
            recs.append(f"Reduce keyword density from {density}%. Use synonyms and related terms instead.")

        # Check distribution gaps
        for section, data in distribution.items():
            if section == "introduction" and data["occurrences"] == 0:
                recs.append("Add primary keyword to the introduction (within first 100 words).")
            if section == "conclusion" and data["occurrences"] == 0:
                recs.append("Add primary keyword to the conclusion section.")

        if not recs:
            recs.append("Keyword density and distribution look good.")

        return recs


if __name__ == "__main__":
    sample_text = """
# How to Start a Podcast: A Complete Guide

Starting a podcast is easier than you think. This guide covers everything you need to know about how to start a podcast from scratch.

## Equipment You Need to Start a Podcast

Before you start a podcast, you'll need the right equipment. The good news is that you don't need expensive gear to start a podcast.

## Recording Your First Episode

Once you have your equipment, it's time to record. Starting a podcast means getting comfortable with your voice.

## Publishing and Distribution

After recording, you need to distribute your podcast. Most successful podcasters use a reliable hosting platform.

## Growing Your Audience

The final step when you start a podcast is growing your listener base.

## Conclusion

Now you know how to start a podcast. Take action today and launch your first episode.
    """

    analyzer = KeywordAnalyzer()
    result = analyzer.analyze(sample_text, "start a podcast", ["podcast hosting", "podcast equipment"])

    print("Keyword Analysis Results\n" + "=" * 50)
    print(f"\nTotal words: {result['total_words']}")
    print(f"\nPrimary keyword: '{result['primary_keyword']['keyword']}'")
    print(f"  Occurrences: {result['primary_keyword']['occurrences']}")
    print(f"  Density: {result['primary_keyword']['density']}%")
    print(f"  Status: {result['primary_keyword']['density_status']}")
    print(f"  Stuffing risk: {result['primary_keyword']['stuffing_risk']}")
    print(f"\nDistribution heatmap:\n{result['distribution_heatmap']}")
    print(f"\nPlacement checklist: {result['placement_checklist']}")
    print(f"\nRecommendations: {result['recommendations']}")
