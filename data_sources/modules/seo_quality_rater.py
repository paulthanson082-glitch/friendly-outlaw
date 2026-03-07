"""
SEO Quality Rater
Rates content against SEO best practices with a 0-100 score.
"""

import re
from typing import Optional


class SEOQualityRater:
    """
    Rates content quality for SEO on a 0-100 scale.

    Scoring breakdown:
    - Content quality: 25 points
    - Keyword optimization: 20 points
    - Meta elements: 15 points
    - Structure: 15 points
    - Links: 15 points
    - Readability: 10 points
    """

    def rate(
        self,
        text: str,
        keyword: str,
        meta_title: Optional[str] = None,
        meta_description: Optional[str] = None,
        internal_link_count: int = 0,
        external_link_count: int = 0,
        word_count: Optional[int] = None,
    ) -> dict:
        """
        Rate the SEO quality of content.

        Args:
            text: Article body text
            keyword: Primary target keyword
            meta_title: Page meta title
            meta_description: Page meta description
            internal_link_count: Number of internal links
            external_link_count: Number of external links
            word_count: Override word count (if not using text)

        Returns:
            dict with scores, issues, and recommendations
        """
        text_lower = text.lower()
        kw_lower = keyword.lower()
        words = text.split()
        actual_word_count = word_count or len(words)

        scores = {}
        issues = []
        warnings = []
        suggestions = []

        # 1. Content Quality (25 points)
        content_score, content_issues = self._score_content(text, actual_word_count)
        scores["content"] = content_score
        issues.extend([("content", i) for i in content_issues["critical"]])
        warnings.extend([("content", w) for w in content_issues["warnings"]])

        # 2. Keyword Optimization (20 points)
        keyword_score, keyword_issues = self._score_keywords(text, text_lower, kw_lower, words)
        scores["keywords"] = keyword_score
        issues.extend([("keywords", i) for i in keyword_issues["critical"]])
        warnings.extend([("keywords", w) for w in keyword_issues["warnings"]])

        # 3. Meta Elements (15 points)
        meta_score, meta_issues = self._score_meta(meta_title, meta_description, kw_lower)
        scores["meta"] = meta_score
        issues.extend([("meta", i) for i in meta_issues["critical"]])
        warnings.extend([("meta", w) for w in meta_issues["warnings"]])

        # 4. Structure (15 points)
        structure_score, structure_issues = self._score_structure(text)
        scores["structure"] = structure_score
        issues.extend([("structure", i) for i in structure_issues["critical"]])
        warnings.extend([("structure", w) for w in structure_issues["warnings"]])

        # 5. Links (15 points)
        link_score, link_issues = self._score_links(internal_link_count, external_link_count)
        scores["links"] = link_score
        issues.extend([("links", i) for i in link_issues["critical"]])
        warnings.extend([("links", w) for w in link_issues["warnings"]])

        # 6. Readability (10 points)
        readability_score, readability_issues = self._score_readability(text, words)
        scores["readability"] = readability_score
        warnings.extend([("readability", w) for w in readability_issues["warnings"]])

        # Total score
        total = sum(scores.values())

        # Publishing readiness
        readiness = self._determine_readiness(total, len(issues))

        return {
            "total_score": total,
            "max_score": 100,
            "publishing_readiness": readiness,
            "category_scores": {
                "content": {"score": scores["content"], "max": 25},
                "keywords": {"score": scores["keywords"], "max": 20},
                "meta": {"score": scores["meta"], "max": 15},
                "structure": {"score": scores["structure"], "max": 15},
                "links": {"score": scores["links"], "max": 15},
                "readability": {"score": scores["readability"], "max": 10},
            },
            "critical_issues": issues,
            "warnings": warnings,
            "suggestions": suggestions,
            "summary": self._generate_summary(total, issues, warnings),
        }

    def _score_content(self, text: str, word_count: int) -> tuple:
        score = 0
        issues = {"critical": [], "warnings": []}

        # Word count scoring (max 15 pts)
        if word_count >= 2500:
            score += 15
        elif word_count >= 2000:
            score += 12
        elif word_count >= 1500:
            score += 9
        elif word_count >= 1000:
            score += 5
            issues["warnings"].append(f"Word count ({word_count}) is below recommended 2,000+")
        else:
            score += 0
            issues["critical"].append(f"Word count ({word_count}) is too low. Target 2,000+ words.")

        # Has introduction hook (3 pts)
        first_para = text.split('\n\n')[0] if '\n\n' in text else text[:500]
        has_question = '?' in first_para[:200]
        has_statistic = bool(re.search(r'\d+%|\d+\s*million|\d+\s*billion', first_para[:200]))
        if has_question or has_statistic or len(first_para) > 100:
            score += 3
        else:
            issues["warnings"].append("Introduction may lack a strong hook (question, stat, or story)")

        # Has conclusion (2 pts)
        last_500 = text[-500:].lower()
        has_conclusion = any(word in last_500 for word in ['conclusion', 'summary', 'takeaway', 'final'])
        cta_words = ['try', 'start', 'learn', 'get', 'sign up', 'contact', 'download']
        has_cta = any(word in last_500 for word in cta_words)
        if has_conclusion or has_cta:
            score += 2

        # Unique value indicators (5 pts)
        has_data = bool(re.search(r'\d+%|\d+\s+(?:people|users|companies|percent)', text))
        has_examples = any(phrase in text.lower() for phrase in ['for example', 'for instance', 'such as', 'like '])
        if has_data:
            score += 2
        if has_examples:
            score += 3

        return min(25, score), issues

    def _score_keywords(self, text: str, text_lower: str, kw_lower: str, words: list) -> tuple:
        score = 0
        issues = {"critical": [], "warnings": []}

        # Keyword in H1 (5 pts)
        h1_match = re.search(r'^#\s+(.+)$', text, re.MULTILINE)
        if h1_match and kw_lower in h1_match.group(1).lower():
            score += 5
        else:
            issues["critical"].append(f"Primary keyword '{kw_lower}' not found in H1 heading")

        # Keyword density (8 pts)
        kw_count = text_lower.count(kw_lower)
        word_count = len(words)
        density = (kw_count / word_count * 100) if word_count > 0 else 0

        if 1.0 <= density <= 2.0:
            score += 8
        elif 0.5 <= density < 1.0 or 2.0 < density <= 2.5:
            score += 5
            issues["warnings"].append(f"Keyword density {density:.1f}% is outside optimal 1-2% range")
        else:
            score += 0
            if density < 0.5:
                issues["critical"].append(f"Keyword density {density:.1f}% is too low (target 1-2%)")
            else:
                issues["critical"].append(f"Keyword density {density:.1f}% is too high — risk of over-optimization")

        # Keyword in first 100 words (4 pts)
        first_100 = ' '.join(text.split()[:100]).lower()
        if kw_lower in first_100:
            score += 4
        else:
            issues["critical"].append("Primary keyword not found in first 100 words")

        # Keyword in H2s (3 pts)
        h2_matches = re.findall(r'^##\s+(.+)$', text, re.MULTILINE)
        if any(kw_lower in h2.lower() for h2 in h2_matches):
            score += 3
        else:
            issues["warnings"].append("Primary keyword not found in any H2 subheading")

        return min(20, score), issues

    def _score_meta(self, title: Optional[str], description: Optional[str], kw_lower: str) -> tuple:
        score = 0
        issues = {"critical": [], "warnings": []}

        if title is None and description is None:
            issues["critical"].append("No meta title or description provided")
            return 0, issues

        # Title scoring (8 pts)
        if title:
            title_len = len(title)
            if 50 <= title_len <= 60:
                score += 4
            elif 45 <= title_len <= 65:
                score += 2
                issues["warnings"].append(f"Meta title is {title_len} chars — target 50-60")
            else:
                issues["critical"].append(f"Meta title is {title_len} chars — must be 50-60")

            if kw_lower in title.lower():
                score += 4
            else:
                issues["critical"].append("Primary keyword not in meta title")
        else:
            issues["critical"].append("Missing meta title")

        # Description scoring (7 pts)
        if description:
            desc_len = len(description)
            if 150 <= desc_len <= 160:
                score += 4
            elif 140 <= desc_len <= 170:
                score += 2
                issues["warnings"].append(f"Meta description is {desc_len} chars — target 150-160")
            else:
                issues["critical"].append(f"Meta description is {desc_len} chars — must be 150-160")

            if kw_lower in description.lower():
                score += 3
            else:
                issues["warnings"].append("Primary keyword not in meta description")
        else:
            issues["warnings"].append("Missing meta description")

        return min(15, score), issues

    def _score_structure(self, text: str) -> tuple:
        score = 0
        issues = {"critical": [], "warnings": []}

        # Single H1 (4 pts)
        h1_count = len(re.findall(r'^#\s+.+$', text, re.MULTILINE))
        if h1_count == 1:
            score += 4
        elif h1_count == 0:
            issues["critical"].append("Missing H1 heading")
        else:
            issues["critical"].append(f"Multiple H1 headings found ({h1_count}). Use exactly one H1.")

        # H2 subheadings present (5 pts)
        h2_count = len(re.findall(r'^##\s+.+$', text, re.MULTILINE))
        if h2_count >= 4:
            score += 5
        elif h2_count >= 2:
            score += 3
        elif h2_count >= 1:
            score += 1
        else:
            issues["critical"].append("No H2 subheadings found")

        # Heading frequency (every 300-400 words) (3 pts)
        words = text.split()
        headings = len(re.findall(r'^#{1,3}\s+', text, re.MULTILINE))
        words_per_heading = len(words) / headings if headings > 0 else len(words)
        if words_per_heading <= 400:
            score += 3
        elif words_per_heading <= 500:
            score += 1
        else:
            issues["warnings"].append(f"Subheadings are too sparse ({words_per_heading:.0f} words/heading, target < 400)")

        # Lists present (3 pts)
        has_list = bool(re.search(r'^[\s]*[-*+]\s|^\s*\d+\.\s', text, re.MULTILINE))
        if has_list:
            score += 3

        return min(15, score), issues

    def _score_links(self, internal: int, external: int) -> tuple:
        score = 0
        issues = {"critical": [], "warnings": []}

        # Internal links (8 pts)
        if internal >= 3:
            score += 8
        elif internal == 2:
            score += 5
            issues["warnings"].append("Add 1+ more internal links (target: 3-5)")
        elif internal == 1:
            score += 3
            issues["critical"].append("Only 1 internal link. Target 3-5 internal links.")
        else:
            issues["critical"].append("No internal links found. Add 3-5 internal links.")

        # External links (7 pts)
        if external >= 2:
            score += 7
        elif external == 1:
            score += 4
            issues["warnings"].append("Add 1+ more external links to authority sources (target: 2-3)")
        else:
            issues["critical"].append("No external links. Add 2-3 links to authoritative sources.")

        return min(15, score), issues

    def _score_readability(self, text: str, words: list) -> tuple:
        score = 10  # Start at max, deduct for issues
        issues = {"warnings": []}

        # Check for very long sentences
        sentences = re.split(r'[.!?]+', text)
        long_sentences = sum(1 for s in sentences if len(s.split()) > 30)
        if long_sentences > 3:
            score -= 3
            issues["warnings"].append(f"{long_sentences} sentences exceed 30 words. Aim for 15-20 word average.")

        # Check for passive voice indicators
        passive = len(re.findall(r'\b(?:is|are|was|were|been)\s+\w+ed\b', text, re.IGNORECASE))
        if passive > 5:
            score -= 2
            issues["warnings"].append(f"High passive voice usage ({passive} instances). Convert to active voice.")

        # Check paragraph length
        paragraphs = [p for p in text.split('\n\n') if p.strip()]
        long_paras = sum(1 for p in paragraphs if len(p.split()) > 150)
        if long_paras > 2:
            score -= 2
            issues["warnings"].append(f"{long_paras} paragraphs exceed 150 words. Break them up.")

        return max(0, score), issues

    def _determine_readiness(self, score: int, critical_count: int) -> str:
        if critical_count > 0:
            return "Not Ready — Fix critical issues first"
        elif score >= 80:
            return "Ready to Publish"
        elif score >= 65:
            return "Nearly Ready — Address warnings"
        else:
            return "Needs Work — Significant improvements required"

    def _generate_summary(self, score: int, issues: list, warnings: list) -> str:
        if score >= 85:
            return f"Excellent SEO quality ({score}/100). Content is well-optimized and ready to publish."
        elif score >= 70:
            return f"Good SEO quality ({score}/100) with {len(warnings)} areas for improvement."
        elif score >= 55:
            return f"Fair SEO quality ({score}/100). Address {len(issues)} critical issues before publishing."
        else:
            return f"Poor SEO quality ({score}/100). Significant work needed on {len(issues)} critical issues."


if __name__ == "__main__":
    sample_text = """
# How to Start a Podcast: The Complete Guide for Beginners

Starting a podcast is one of the best ways to share your expertise and build an audience. Over 500 million people listen to podcasts worldwide, making this the perfect time to start a podcast.

## What You Need to Start a Podcast

Before you start recording, you need the right equipment. A USB microphone is the best way to start a podcast without breaking the bank.

For example, the Blue Yeti is a popular choice for beginners who want to start a podcast with professional quality.

## Recording Your Episodes

Once you have your equipment, it's time to start recording. Most podcasters record in a quiet room to reduce background noise.

## Publishing Your Podcast

After recording, you need a hosting platform to distribute your podcast to Apple Podcasts, Spotify, and other directories.

## Growing Your Listener Base

The final step is marketing your podcast. Share episodes on social media and engage with your audience to grow your listener base.

## Conclusion

Now you have everything you need to start a podcast. Take action today and record your first episode. Try [Brand] free for 14 days to get started.
    """

    rater = SEOQualityRater()
    result = rater.rate(
        text=sample_text,
        keyword="start a podcast",
        meta_title="How to Start a Podcast: Complete Beginner's Guide",
        meta_description="Learn how to start a podcast in 2025. Step-by-step guide covering equipment, recording, publishing, and growing your audience. Start today.",
        internal_link_count=2,
        external_link_count=1,
    )

    print("SEO Quality Rating\n" + "=" * 50)
    print(f"Total Score: {result['total_score']}/100")
    print(f"Publishing Readiness: {result['publishing_readiness']}")
    print(f"\nCategory Scores:")
    for cat, data in result['category_scores'].items():
        print(f"  {cat.capitalize()}: {data['score']}/{data['max']}")
    print(f"\nCritical Issues ({len(result['critical_issues'])}):")
    for category, issue in result['critical_issues']:
        print(f"  [{category}] {issue}")
    print(f"\nWarnings ({len(result['warnings'])}):")
    for category, warning in result['warnings']:
        print(f"  [{category}] {warning}")
