"""
Search Intent Analyzer
Classifies keyword search intent as informational, navigational, transactional, or commercial.
"""

import re
from typing import Literal

IntentType = Literal["informational", "navigational", "transactional", "commercial"]


class SearchIntentAnalyzer:
    """Analyzes keywords to classify their search intent."""

    # Keyword patterns for each intent type
    INFORMATIONAL_PATTERNS = [
        r"\bhow\s+to\b", r"\bwhat\s+is\b", r"\bwhat\s+are\b", r"\bwhy\s+is\b",
        r"\bwhen\s+is\b", r"\bwho\s+is\b", r"\bwhere\s+is\b", r"\bhow\s+does\b",
        r"\bguide\b", r"\btutorial\b", r"\bexplain\b", r"\bdefinition\b",
        r"\blearn\b", r"\btips\b", r"\bways\s+to\b", r"\bexamples?\b",
        r"\bideas?\b", r"\bfacts?\b", r"\bhistory\s+of\b", r"\bbenefits?\s+of\b",
        r"\badvantages?\s+of\b", r"\bdifference\s+between\b", r"\bvs\.?\b",
        r"\bcomparison\b", r"\bpros\s+and\s+cons\b",
    ]

    NAVIGATIONAL_PATTERNS = [
        r"\blogin\b", r"\blog\s+in\b", r"\bsign\s+in\b", r"\bwebsite\b",
        r"\bofficial\b", r"\bhomepage\b", r"\bdownload\b", r"\bapp\b",
        r"\bportal\b", r"\bdashboard\b",
    ]

    TRANSACTIONAL_PATTERNS = [
        r"\bbuy\b", r"\bpurchase\b", r"\border\b", r"\bshop\b", r"\bget\b",
        r"\bsubscribe\b", r"\bsign\s+up\b", r"\btry\b", r"\bfree\s+trial\b",
        r"\bdownload\b", r"\binstall\b", r"\bcoupon\b", r"\bdiscount\b",
        r"\bprice\b", r"\bcost\b", r"\baffordable\b", r"\bcheap\b",
        r"\bpro\b", r"\bpremium\b", r"\bplan\s*s?\b",
    ]

    COMMERCIAL_PATTERNS = [
        r"\bbest\b", r"\btop\b", r"\breview\s*s?\b", r"\bcompare\b",
        r"\balternatives?\b", r"\brecommend\b", r"\bworth\s+it\b",
        r"\brated\b", r"\branked\b", r"\blegit\b", r"\breliable\b",
        r"\bsoftware\b", r"\btool\s*s?\b", r"\bplatform\s*s?\b",
        r"\bservice\s*s?\b", r"\bsolution\s*s?\b",
    ]

    def analyze(self, keyword: str) -> dict:
        """
        Analyze a keyword and return intent classification with confidence scores.

        Args:
            keyword: The search keyword to analyze

        Returns:
            dict with intent type, confidence scores, and explanation
        """
        keyword_lower = keyword.lower()

        scores = {
            "informational": self._score_patterns(keyword_lower, self.INFORMATIONAL_PATTERNS),
            "navigational": self._score_patterns(keyword_lower, self.NAVIGATIONAL_PATTERNS),
            "transactional": self._score_patterns(keyword_lower, self.TRANSACTIONAL_PATTERNS),
            "commercial": self._score_patterns(keyword_lower, self.COMMERCIAL_PATTERNS),
        }

        # Determine primary intent
        primary_intent = max(scores, key=scores.get)

        # If all scores are 0, default to informational
        if all(score == 0 for score in scores.values()):
            primary_intent = "informational"
            scores["informational"] = 1

        # Calculate confidence as percentage of primary vs total
        total = sum(scores.values()) or 1
        confidence = round(scores[primary_intent] / total * 100, 1)

        return {
            "keyword": keyword,
            "primary_intent": primary_intent,
            "confidence": confidence,
            "scores": scores,
            "content_type_recommendation": self._get_content_recommendation(primary_intent),
            "explanation": self._explain(keyword_lower, primary_intent),
        }

    def _score_patterns(self, text: str, patterns: list) -> int:
        """Count how many patterns match the text."""
        return sum(1 for pattern in patterns if re.search(pattern, text, re.IGNORECASE))

    def _get_content_recommendation(self, intent: IntentType) -> str:
        recommendations = {
            "informational": "Long-form guide, how-to article, or explainer post",
            "navigational": "Brand page or direct product/feature page",
            "transactional": "Landing page with strong CTA, pricing, or sign-up focus",
            "commercial": "Comparison article, review, or alternatives page",
        }
        return recommendations.get(intent, "General article")

    def _explain(self, keyword: str, intent: IntentType) -> str:
        explanations = {
            "informational": f"Searcher wants to learn about '{keyword}'. Create educational content that answers their question.",
            "navigational": f"Searcher is looking for a specific site or page. Focus on brand/product content.",
            "transactional": f"Searcher is ready to act. Create conversion-focused content with clear CTAs.",
            "commercial": f"Searcher is researching before deciding. Create comparison or review content that helps them choose.",
        }
        return explanations.get(intent, "Create relevant content for this keyword.")

    def batch_analyze(self, keywords: list[str]) -> list[dict]:
        """Analyze multiple keywords at once."""
        return [self.analyze(kw) for kw in keywords]


if __name__ == "__main__":
    analyzer = SearchIntentAnalyzer()

    test_keywords = [
        "how to start a podcast",
        "best podcast hosting platform",
        "buy podcast microphone",
        "spotify login",
        "podcast hosting review",
        "what is RSS feed",
    ]

    print("Search Intent Analysis\n" + "=" * 50)
    for kw in test_keywords:
        result = analyzer.analyze(kw)
        print(f"\n'{kw}'")
        print(f"  Intent: {result['primary_intent']} ({result['confidence']}% confidence)")
        print(f"  Recommendation: {result['content_type_recommendation']}")
