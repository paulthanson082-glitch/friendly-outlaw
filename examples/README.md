# Examples for Anthropic API

This directory contains examples demonstrating how to use the Anthropic API from multiple languages.

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

## Go Example

The `go_ai_service/` directory contains a Go implementation of the same writing assistant.
Inspired by [PicoClaw](https://github.com/sipeed/picoclaw)'s ultra-lightweight Go design, it uses only the Go standard library — no external SDK required.

### Setup

Go 1.21+ is required. No dependencies to install.

```bash
cd go_ai_service
export ANTHROPIC_API_KEY="your-api-key-here"
go run main.go
```

### Using in Your Code

```go
package main

import (
    "context"
    "fmt"
    "os"
)

func main() {
    config := AIConfiguration{
        APIKey:      os.Getenv("ANTHROPIC_API_KEY"),
        Model:       Claude35Sonnet,
        MaxTokens:   4096,
        Temperature: 0.7,
    }
    service := NewAIService(config)
    ctx := context.Background()

    aiCtx := &AIContext{Genre: "Science Fiction", TargetAudience: "Young Adult"}

    // Continue writing
    continuation, _ := service.ContinueWriting(ctx, "The spaceship drifted through the void...", aiCtx)
    fmt.Println(continuation)

    // Generate titles
    titles, _ := service.GenerateTitles(ctx, "Your content here", aiCtx, 5)
    for i, t := range titles {
        fmt.Printf("%d. %s\n", i+1, t)
    }

    // Improve text
    improved, _ := service.ImproveText(ctx, "Your text to improve", aiCtx)
    fmt.Println(improved)

    // Check grammar
    corrected, _ := service.CheckGrammar(ctx, "Text with potential errors")
    fmt.Println(corrected)

    // Brainstorm ideas
    ideas, _ := service.BrainstormIdeas(ctx, "Time travel paradoxes", aiCtx)
    fmt.Println(ideas)

    // Develop a character
    character, _ := service.DevelopCharacter(ctx, "A reluctant hero with a mysterious past", aiCtx)
    fmt.Println(character)

    // Generate an outline
    outline, _ := service.GenerateOutline(ctx, "A story about AI consciousness", aiCtx)
    fmt.Println(outline)

    // Change tone
    formal, _ := service.ChangeTone(ctx, "Hey! This is really cool!", ToneFormal, nil)
    fmt.Println(formal)

    // Custom request
    result, _ := service.CustomRequest(ctx, "Your text", "Rewrite this as a haiku", aiCtx)
    fmt.Println(result)
}
```

---

## Comparison with Swift Implementation

All three implementations (Swift, Python, Go) mirror the `AIService` found in
`Sources/WritersApp/Services/AIService.swift`.

| Aspect | Swift | Python | Go |
|---|---|---|---|
| HTTP | URLSession (raw) | `anthropic` SDK | `net/http` (raw) |
| Types | Structs + enums | Dataclasses + enums | Structs + typed consts |
| Async | async/await | sync (SDK handles) | `context.Context` |
| Errors | Result / throws | Exceptions | `error` return value |
| Dependencies | None | `anthropic>=0.79.0` | None (stdlib only) |

## Getting an API Key

To use these examples, you'll need an Anthropic API key:

1. Visit [console.anthropic.com](https://console.anthropic.com)
2. Sign up or log in
3. Navigate to API Keys section
4. Generate a new API key
5. Set it as environment variable: `export ANTHROPIC_API_KEY="your-key"`
