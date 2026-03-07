"""
Readability Scorer
Calculates Flesch Reading Ease, Flesch-Kincaid Grade Level, and other readability metrics.
"""

import re
from typing import Optional


class ReadabilityScorer:
    """Scores content readability using multiple metrics."""

    def score(self, text: str) -> dict:
        """
        Calculate comprehensive readability scores for the given text.

        Args:
            text: Article text to analyze

        Returns:
            dict with all readability metrics and recommendations
        """
        # Clean markdown
        clean = self._clean_markdown(text)

        sentences = self._split_sentences(clean)
        words = self._get_words(clean)
        syllables = sum(self._count_syllables(w) for w in words)

        if not sentences or not words:
            return {"error": "Insufficient text for analysis"}

        word_count = len(words)
        sentence_count = len(sentences)
        avg_sentence_length = word_count / sentence_count

        # Flesch Reading Ease
        if sentence_count > 0 and word_count > 0:
            flesch_ease = 206.835 - (1.015 * avg_sentence_length) - (84.6 * (syllables / word_count))
            flesch_ease = round(max(0, min(100, flesch_ease)), 1)
        else:
            flesch_ease = 0

        # Flesch-Kincaid Grade Level
        if sentence_count > 0 and word_count > 0:
            fk_grade = (0.39 * avg_sentence_length) + (11.8 * (syllables / word_count)) - 15.59
            fk_grade = round(max(0, fk_grade), 1)
        else:
            fk_grade = 0

        # Passive voice
        passive_count = self._count_passive_voice(clean)
        passive_ratio = round(passive_count / sentence_count * 100, 1) if sentence_count > 0 else 0

        # Complex words (3+ syllables)
        complex_words = [w for w in words if self._count_syllables(w) >= 3]
        complex_ratio = round(len(complex_words) / word_count * 100, 1) if word_count > 0 else 0

        # Paragraph analysis
        paragraphs = [p.strip() for p in re.split(r'\n\n+', clean) if p.strip()]
        avg_paragraph_length = word_count / len(paragraphs) if paragraphs else 0
        long_paragraphs = sum(1 for p in paragraphs if len(p.split()) > 150)

        # Transition words
        transition_count = self._count_transitions(clean)
        transition_ratio = round(transition_count / sentence_count * 100, 1) if sentence_count > 0 else 0

        # Overall readability score (0-100)
        overall_score = self._calculate_overall_score(
            flesch_ease, fk_grade, passive_ratio, avg_sentence_length, long_paragraphs
        )

        return {
            "word_count": word_count,
            "sentence_count": sentence_count,
            "paragraph_count": len(paragraphs),
            "flesch_reading_ease": {
                "score": flesch_ease,
                "level": self._flesch_level(flesch_ease),
                "target": "60-70",
                "status": "good" if 55 <= flesch_ease <= 75 else "needs_improvement",
            },
            "flesch_kincaid_grade": {
                "score": fk_grade,
                "label": f"Grade {fk_grade:.0f}",
                "target": "8-10",
                "status": "good" if 7 <= fk_grade <= 11 else "needs_improvement",
            },
            "avg_sentence_length": {
                "words": round(avg_sentence_length, 1),
                "target": "15-20",
                "status": "good" if 12 <= avg_sentence_length <= 22 else "needs_improvement",
            },
            "avg_paragraph_length": {
                "words": round(avg_paragraph_length, 1),
                "target": "50-100",
                "long_paragraphs": long_paragraphs,
            },
            "passive_voice": {
                "count": passive_count,
                "ratio": passive_ratio,
                "target": "< 15%",
                "status": "good" if passive_ratio < 15 else "needs_improvement",
            },
            "complex_words": {
                "count": len(complex_words),
                "ratio": complex_ratio,
                "target": "< 20%",
            },
            "transition_words": {
                "count": transition_count,
                "ratio": transition_ratio,
                "target": "> 25%",
                "status": "good" if transition_ratio >= 20 else "needs_improvement",
            },
            "overall_readability_score": overall_score,
            "recommendations": self._get_recommendations(
                flesch_ease, fk_grade, passive_ratio, avg_sentence_length, long_paragraphs
            ),
        }

    def _clean_markdown(self, text: str) -> str:
        """Remove Markdown formatting for accurate text analysis."""
        text = re.sub(r'^#{1,6}\s+', '', text, flags=re.MULTILINE)
        text = re.sub(r'\[([^\]]+)\]\([^\)]+\)', r'\1', text)
        text = re.sub(r'[*_`~]', '', text)
        text = re.sub(r'^\s*[-*+]\s+', '', text, flags=re.MULTILINE)
        text = re.sub(r'^\s*\d+\.\s+', '', text, flags=re.MULTILINE)
        return text

    def _split_sentences(self, text: str) -> list:
        """Split text into sentences."""
        sentences = re.split(r'(?<=[.!?])\s+', text.strip())
        return [s for s in sentences if len(s.split()) >= 3]

    def _get_words(self, text: str) -> list:
        """Extract words from text."""
        return re.findall(r'\b[a-zA-Z]+\b', text.lower())

    def _count_syllables(self, word: str) -> int:
        """Estimate syllable count for a word."""
        word = word.lower()
        if len(word) <= 3:
            return 1

        # Remove trailing e
        word = re.sub(r'e$', '', word)

        # Count vowel groups
        vowels = re.findall(r'[aeiouy]+', word)
        count = len(vowels)

        return max(1, count)

    def _count_passive_voice(self, text: str) -> int:
        """Count approximate passive voice constructions."""
        # Simple heuristic: "to be" verb + past participle pattern
        passive_patterns = [
            r'\b(?:is|are|was|were|be|been|being)\s+\w+ed\b',
            r'\b(?:is|are|was|were|be|been|being)\s+\w+en\b',
        ]
        count = 0
        for pattern in passive_patterns:
            count += len(re.findall(pattern, text, re.IGNORECASE))
        return count

    def _count_transitions(self, text: str) -> int:
        """Count transition words/phrases."""
        transitions = [
            r'\bhowever\b', r'\btherefore\b', r'\bfurthermore\b', r'\bmoreover\b',
            r'\bconsequently\b', r'\bnevertheless\b', r'\bfor\s+example\b',
            r'\bfor\s+instance\b', r'\bin\s+addition\b', r'\bon\s+the\s+other\s+hand\b',
            r'\bin\s+contrast\b', r'\bas\s+a\s+result\b', r'\bfinally\b',
            r'\bfirst(ly)?\b', r'\bsecond(ly)?\b', r'\bthird(ly)?\b',
            r'\bin\s+conclusion\b', r'\bto\s+summarize\b', r'\bspecifically\b',
            r'\bfor\s+this\s+reason\b', r'\bthat\s+is\b', r'\bin\s+other\s+words\b',
        ]
        count = 0
        text_lower = text.lower()
        for pattern in transitions:
            count += len(re.findall(pattern, text_lower))
        return count

    def _flesch_level(self, score: float) -> str:
        """Convert Flesch score to description."""
        if score >= 90:
            return "Very Easy (5th grade)"
        elif score >= 80:
            return "Easy (6th grade)"
        elif score >= 70:
            return "Fairly Easy (7th grade)"
        elif score >= 60:
            return "Standard (8th-9th grade)"
        elif score >= 50:
            return "Fairly Difficult (10th-12th grade)"
        elif score >= 30:
            return "Difficult (College level)"
        else:
            return "Very Difficult (Professional)"

    def _calculate_overall_score(self, flesch: float, grade: float, passive: float,
                                   avg_sent: float, long_paras: int) -> int:
        """Calculate an overall readability score 0-100."""
        score = 100

        # Deduct for poor Flesch score
        if flesch < 50:
            score -= 20
        elif flesch < 60:
            score -= 10

        # Deduct for high grade level
        if grade > 14:
            score -= 15
        elif grade > 11:
            score -= 8

        # Deduct for passive voice
        if passive > 20:
            score -= 15
        elif passive > 15:
            score -= 8

        # Deduct for long sentences
        if avg_sent > 25:
            score -= 10
        elif avg_sent > 22:
            score -= 5

        # Deduct for wall-of-text paragraphs
        score -= min(10, long_paras * 3)

        return max(0, min(100, score))

    def _get_recommendations(self, flesch: float, grade: float, passive: float,
                              avg_sent: float, long_paras: int) -> list:
        """Generate specific improvement recommendations."""
        recs = []

        if flesch < 60:
            recs.append(f"Improve Flesch score from {flesch} to 60+. Simplify vocabulary and shorten sentences.")

        if grade > 11:
            recs.append(f"Reduce grade level from {grade} to 8-10. Use simpler words and shorter sentences.")

        if passive > 15:
            recs.append(f"Reduce passive voice from {passive}% to < 15%. Rewrite sentences in active voice.")

        if avg_sent > 22:
            recs.append(f"Shorten average sentence length from {avg_sent:.0f} words to 15-20 words.")

        if long_paras > 2:
            recs.append(f"Break up {long_paras} long paragraphs. Target 2-4 sentences per paragraph.")

        if not recs:
            recs.append("Readability is strong. No major improvements needed.")

        return recs


if __name__ == "__main__":
    sample = """
Starting a podcast can seem overwhelming, but with the right approach, it's achievable for anyone
who has something valuable to say to an audience. The podcasting industry has experienced
significant growth over the past decade, with millions of shows now available across various platforms.

## Getting Started

First, you need to determine your niche. What topics are you passionate about? What expertise
do you have that others would benefit from learning? These questions are fundamental to creating
content that resonates with listeners.

Equipment matters, but it doesn't have to be expensive. A decent USB microphone, free recording
software, and a quiet room are enough to produce professional-quality audio.
    """

    scorer = ReadabilityScorer()
    result = scorer.score(sample)

    print("Readability Analysis\n" + "=" * 50)
    print(f"Flesch Reading Ease: {result['flesch_reading_ease']['score']} ({result['flesch_reading_ease']['level']})")
    print(f"Grade Level: {result['flesch_kincaid_grade']['score']}")
    print(f"Avg Sentence Length: {result['avg_sentence_length']['words']} words")
    print(f"Passive Voice: {result['passive_voice']['ratio']}%")
    print(f"Overall Score: {result['overall_readability_score']}/100")
    print(f"\nRecommendations:")
    for rec in result['recommendations']:
        print(f"  - {rec}")
