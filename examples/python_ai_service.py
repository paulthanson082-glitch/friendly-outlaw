import json
import os
from datetime import datetime
from typing import List, Dict, Optional
from dataclasses import dataclass, asdict
from enum import Enum
import anthropic


class AIModel(Enum):
    """Available Claude models"""
    CLAUDE_3_OPUS = "claude-3-opus-20240229"
    CLAUDE_3_SONNET = "claude-3-sonnet-20240229"
    CLAUDE_3_5_SONNET = "claude-3-5-sonnet-20241022"
    CLAUDE_3_HAIKU = "claude-3-haiku-20240307"


class WritingTone(Enum):
    """Different writing tones"""
    PROFESSIONAL = "professional"
    CASUAL = "casual"
    FORMAL = "formal"
    FRIENDLY = "friendly"
    ACADEMIC = "academic"
    CREATIVE = "creative"


@dataclass
class AIConfiguration:
    """Configuration for AI service"""
    api_key: str
    model: AIModel = AIModel.CLAUDE_3_5_SONNET
    temperature: float = 0.7
    max_tokens: int = 4096


@dataclass
class AIContext:
    """Context for AI requests"""
    genre: Optional[str] = None
    target_audience: Optional[str] = None
    writing_style: Optional[str] = None
    additional_notes: Optional[str] = None


@dataclass
class Document:
    """Document representation"""
    id: str
    title: str
    content: str
    category: str
    word_count: int
    created_at: datetime
    modified_at: datetime


class AIService:
    """Service for AI-powered writing assistance using Claude API"""

    def __init__(self, configuration: AIConfiguration):
        self.configuration = configuration
        self.client = anthropic.Anthropic(api_key=configuration.api_key)

    def _create_context_string(self, context: Optional[AIContext]) -> str:
        """Create a context string from AIContext"""
        if not context:
            return ""

        parts = []
        if context.genre:
            parts.append(f"Genre: {context.genre}")
        if context.target_audience:
            parts.append(f"Target Audience: {context.target_audience}")
        if context.writing_style:
            parts.append(f"Writing Style: {context.writing_style}")
        if context.additional_notes:
            parts.append(f"Additional Notes: {context.additional_notes}")

        return "\n".join(parts) if parts else ""

    def continue_writing(self, text: str, context: Optional[AIContext] = None) -> str:
        """Continue writing from existing text"""
        context_str = self._create_context_string(context)

        prompt = f"""Continue writing from where this text leaves off. Match the style, tone, and voice of the existing text.

{context_str}

Existing Text:
{text}

Continue the writing naturally from where it ends."""

        message = self.client.messages.create(
            model=self.configuration.model.value,
            max_tokens=self.configuration.max_tokens,
            temperature=self.configuration.temperature,
            messages=[
                {"role": "user", "content": prompt}
            ]
        )

        return message.content[0].text

    def improve_text(self, text: str, context: Optional[AIContext] = None) -> str:
        """Improve existing text for clarity and impact"""
        context_str = self._create_context_string(context)

        prompt = f"""Improve this text for clarity, flow, and impact while maintaining its core message and style.

{context_str}

Original Text:
{text}

Provide the improved version."""

        message = self.client.messages.create(
            model=self.configuration.model.value,
            max_tokens=self.configuration.max_tokens,
            temperature=self.configuration.temperature,
            messages=[
                {"role": "user", "content": prompt}
            ]
        )

        return message.content[0].text

    def check_grammar(self, text: str) -> str:
        """Check grammar and spelling"""
        prompt = f"""Check this text for grammar and spelling errors. Provide the corrected version.

Text:
{text}

Corrected version:"""

        message = self.client.messages.create(
            model=self.configuration.model.value,
            max_tokens=self.configuration.max_tokens,
            temperature=0.3,
            messages=[
                {"role": "user", "content": prompt}
            ]
        )

        return message.content[0].text

    def generate_titles(self, content: str, context: Optional[AIContext] = None, count: int = 5) -> List[str]:
        """Generate title options for content"""
        context_str = self._create_context_string(context)

        prompt = f"""Generate {count} compelling title options for this content.

{context_str}

Content:
{content}

Provide {count} distinct title options, one per line."""

        message = self.client.messages.create(
            model=self.configuration.model.value,
            max_tokens=self.configuration.max_tokens,
            temperature=self.configuration.temperature,
            messages=[
                {"role": "user", "content": prompt}
            ]
        )

        titles = message.content[0].text.strip().split('\n')
        # Remove numbering and clean up
        return [title.strip().lstrip('0123456789.)- ') for title in titles if title.strip()]

    def brainstorm_ideas(self, topic: str, context: Optional[AIContext] = None) -> str:
        """Brainstorm ideas on a topic"""
        context_str = self._create_context_string(context)

        prompt = f"""Brainstorm creative ideas for this topic. Provide multiple unique angles and approaches.

{context_str}

Topic:
{topic}

Provide detailed, creative ideas:"""

        message = self.client.messages.create(
            model=self.configuration.model.value,
            max_tokens=self.configuration.max_tokens,
            temperature=0.9,
            messages=[
                {"role": "user", "content": prompt}
            ]
        )

        return message.content[0].text

    def develop_character(self, character_concept: str, context: Optional[AIContext] = None) -> str:
        """Develop a character from a concept"""
        context_str = self._create_context_string(context)

        prompt = f"""Develop this character concept into a fully-realized character with:
- Physical description
- Personality traits
- Background/history
- Motivations and goals
- Conflicts and flaws
- Character arc potential

{context_str}

Character Concept:
{character_concept}

Detailed character development:"""

        message = self.client.messages.create(
            model=self.configuration.model.value,
            max_tokens=self.configuration.max_tokens,
            temperature=self.configuration.temperature,
            messages=[
                {"role": "user", "content": prompt}
            ]
        )

        return message.content[0].text

    def generate_outline(self, concept: str, context: Optional[AIContext] = None) -> str:
        """Generate outline from concept"""
        context_str = self._create_context_string(context)

        prompt = f"""Create a detailed outline for this concept with clear structure and progression.

{context_str}

Concept:
{concept}

Detailed outline:"""

        message = self.client.messages.create(
            model=self.configuration.model.value,
            max_tokens=self.configuration.max_tokens,
            temperature=self.configuration.temperature,
            messages=[
                {"role": "user", "content": prompt}
            ]
        )

        return message.content[0].text

    def change_tone(self, text: str, tone: WritingTone, context: Optional[AIContext] = None) -> str:
        """Change the tone of text"""
        context_str = self._create_context_string(context)

        prompt = f"""Rewrite this text in a {tone.value} tone while maintaining its core message.

{context_str}

Original Text:
{text}

Rewritten in {tone.value} tone:"""

        message = self.client.messages.create(
            model=self.configuration.model.value,
            max_tokens=self.configuration.max_tokens,
            temperature=self.configuration.temperature,
            messages=[
                {"role": "user", "content": prompt}
            ]
        )

        return message.content[0].text

    def analyze_document(self, document: Document) -> Dict[str, any]:
        """Analyze entire document comprehensively"""
        prompt = f"""Analyze this document comprehensively and provide:
1. Overall assessment
2. Strengths (3-5 points)
3. Areas for improvement (3-5 points)
4. Specific suggestions for enhancement
5. Target audience suitability

Document Title: {document.title}
Category: {document.category}
Word Count: {document.word_count}

Content:
{document.content}

Provide the analysis in a structured format."""

        message = self.client.messages.create(
            model=self.configuration.model.value,
            max_tokens=self.configuration.max_tokens,
            temperature=self.configuration.temperature,
            messages=[
                {"role": "user", "content": prompt}
            ]
        )

        return {
            "document_id": document.id,
            "analysis": message.content[0].text,
            "timestamp": datetime.now().isoformat()
        }

    def get_writing_insights(self, document: Document) -> Dict[str, any]:
        """Get writing statistics and insights"""
        prompt = f"""Analyze this text and provide insights:
1. Reading level (Flesch-Kincaid grade)
2. Tone analysis
3. Pacing assessment
4. Vocabulary richness
5. Sentence structure variety

Text:
{document.content}

Provide specific metrics and observations."""

        message = self.client.messages.create(
            model=self.configuration.model.value,
            max_tokens=self.configuration.max_tokens,
            temperature=0.3,
            messages=[
                {"role": "user", "content": prompt}
            ]
        )

        return {
            "document_id": document.id,
            "insights": message.content[0].text,
            "timestamp": datetime.now().isoformat()
        }

    def custom_request(self, text: str, instruction: str, context: Optional[AIContext] = None) -> str:
        """Custom AI request with specific instructions"""
        context_str = self._create_context_string(context)

        prompt = f"""{instruction}

{context_str}

Text:
{text}

Response:"""

        message = self.client.messages.create(
            model=self.configuration.model.value,
            max_tokens=self.configuration.max_tokens,
            temperature=self.configuration.temperature,
            messages=[
                {"role": "user", "content": prompt}
            ]
        )

        return message.content[0].text


def main():
    """Example usage of AIService"""
    # Get API key from environment
    api_key = os.environ.get("ANTHROPIC_API_KEY")
    if not api_key:
        print("Error: ANTHROPIC_API_KEY environment variable not set")
        return

    # Create configuration
    config = AIConfiguration(
        api_key=api_key,
        model=AIModel.CLAUDE_3_5_SONNET,
        temperature=0.7
    )

    # Initialize service
    ai_service = AIService(config)

    # Example: Continue writing
    sample_text = "The old house stood at the end of the winding road, its windows dark and mysterious."
    context = AIContext(
        genre="Mystery",
        target_audience="Adult",
        writing_style="Suspenseful"
    )

    print("Original text:")
    print(sample_text)
    print("\nContinued text:")
    continuation = ai_service.continue_writing(sample_text, context)
    print(continuation)

    # Example: Generate titles
    print("\n" + "="*50)
    print("Generated titles:")
    titles = ai_service.generate_titles(sample_text, context)
    for i, title in enumerate(titles, 1):
        print(f"{i}. {title}")

    # Example: Improve text
    print("\n" + "="*50)
    print("Improved text:")
    improved = ai_service.improve_text(sample_text, context)
    print(improved)


if __name__ == "__main__":
    main()
