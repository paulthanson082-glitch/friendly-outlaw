# Python Examples for Anthropic API

This directory contains Python examples demonstrating how to use the Anthropic API with the official Python SDK.

## Setup

1. Install the required dependencies:

```bash
pip install -r requirements.txt
```

2. Set your Anthropic API key as an environment variable:

```bash
export ANTHROPIC_API_KEY="your-api-key-here"
```

## Usage

### Running the Interactive AI Writing Assistant

The `ai_assistant_cli.py` script provides a full interactive chat interface. Your
conversation history is maintained across messages so you can ask follow-up
questions and the assistant remembers what you discussed earlier.

```bash
python ai_assistant_cli.py
```

**Available CLI commands** (type inside the assistant):

| Command    | Description                                  |
|------------|----------------------------------------------|
| `/help`    | Show command list and example prompts        |
| `/clear`   | Clear conversation history and start fresh   |
| `/history` | Show how many messages are in the session    |
| `/quit`    | Exit the assistant (also `/exit` or `/q`)    |

### Running the AI Service Example

```bash
python python_ai_service.py
```

### Using in Your Code

```python
import os
from python_ai_service import AIService, AIConfiguration, AIModel, AIContext, WritingTone

# Initialize the service
config = AIConfiguration(
    api_key=os.environ.get("ANTHROPIC_API_KEY"),
    model=AIModel.CLAUDE_3_5_SONNET,
    temperature=0.7
)

ai_service = AIService(config)

# Continue writing
context = AIContext(
    genre="Science Fiction",
    target_audience="Young Adult"
)

continuation = ai_service.continue_writing(
    "The spaceship drifted through the void...",
    context
)

# Generate titles
titles = ai_service.generate_titles(
    "Your content here",
    context,
    count=5
)

# Improve text
improved = ai_service.improve_text(
    "Your text to improve",
    context
)

# Check grammar
corrected = ai_service.check_grammar("Text with potential errors")

# Brainstorm ideas
ideas = ai_service.brainstorm_ideas(
    "Time travel paradoxes",
    context
)

# Develop a character
character = ai_service.develop_character(
    "A reluctant hero with a mysterious past",
    context
)

# Generate an outline
outline = ai_service.generate_outline(
    "A story about AI consciousness",
    context
)

# Change tone
professional = ai_service.change_tone(
    "Hey! This is really cool!",
    WritingTone.PROFESSIONAL
)

# Custom request
result = ai_service.custom_request(
    text="Your text",
    instruction="Rewrite this as a haiku",
    context=context
)
```

## Features

The `AIService` class provides the following methods:

- **continue_writing()** - Continue writing from existing text
- **improve_text()** - Improve text for clarity and impact
- **check_grammar()** - Check and correct grammar/spelling
- **generate_titles()** - Generate title options
- **brainstorm_ideas()** - Brainstorm creative ideas
- **develop_character()** - Develop character concepts
- **generate_outline()** - Create structured outlines
- **change_tone()** - Rewrite in different tones
- **analyze_document()** - Comprehensive document analysis
- **get_writing_insights()** - Writing statistics and insights
- **custom_request()** - Custom instructions to the AI

## Configuration Options

### AIModel Enum
- `CLAUDE_3_OPUS` - Most capable model
- `CLAUDE_3_5_SONNET` - Balanced performance (recommended)
- `CLAUDE_3_SONNET` - Fast and capable
- `CLAUDE_3_HAIKU` - Fastest model

### WritingTone Enum
- `PROFESSIONAL`
- `CASUAL`
- `FORMAL`
- `FRIENDLY`
- `ACADEMIC`
- `CREATIVE`

### AIContext
Provides context for AI requests:
- `genre` - Writing genre
- `target_audience` - Intended audience
- `writing_style` - Desired style
- `additional_notes` - Extra context

## Comparison with Swift Implementation

This Python implementation mirrors the functionality of the Swift `AIService` found in `Sources/WritersApp/Services/AIService.swift`, but uses the official Anthropic Python SDK instead of raw HTTP requests.

### Key Differences:

1. **SDK vs Raw HTTP**: Python uses the official `anthropic` SDK, while Swift uses URLSession for raw HTTP requests
2. **Type Safety**: Both implementations use strong typing (Python dataclasses, Swift structs)
3. **Async/Await**: Both support asynchronous operations
4. **Error Handling**: Python uses exceptions, Swift uses Result types

## Getting an API Key

To use these examples, you'll need an Anthropic API key:

1. Visit [console.anthropic.com](https://console.anthropic.com)
2. Sign up or log in
3. Navigate to API Keys section
4. Generate a new API key
5. Set it as environment variable: `export ANTHROPIC_API_KEY="your-key"`
