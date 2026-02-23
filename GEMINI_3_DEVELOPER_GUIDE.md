# Gemini 3 Developer Guide

Reference documentation for the Gemini 3 model family, covering features, capabilities, and API integration details.

---

## Model: `gemini-3.1-pro-preview`

### Overview

Gemini 3.1 Pro Preview is Google's latest reasoning-optimized AI model, released on **February 19, 2026**. It is the successor to Gemini 3 Pro and introduces significant improvements in reasoning depth, agentic tool usage, and output capacity, while maintaining the same pricing as its predecessor.

### Model Versions

| Version | Description |
|---------|-------------|
| `gemini-3.1-pro-preview` | Standard Gemini 3.1 Pro Preview |
| `gemini-3.1-pro-preview-customtools` | Dedicated endpoint optimized for agentic workflows with custom tools. Use this variant if the standard model ignores custom tools in favor of built-in bash commands. |

---

## Supported Data Types

| Direction | Supported Types |
|-----------|----------------|
| **Input** | Text, Image, Video, Audio, PDF |
| **Output** | Text |

---

## Token Limits

| Limit | Value |
|-------|-------|
| Input token limit | 1,048,576 (~1M tokens) |
| Output token limit | 65,536 |
| Max file upload size | 100 MB (up from 20 MB in previous versions) |

The expanded output limit (65,536 tokens) resolves a truncation issue in Gemini 3 Pro that frequently cut off code generation around 21,000 tokens.

---

## Capabilities

| Capability | Status |
|------------|--------|
| Audio generation | Not supported |
| Batch API | Supported |
| Caching | Supported |
| Code execution | Supported |
| File search | Supported (AI Studio only) |
| Function calling | Supported |
| Grounding with Google Maps | Not supported |
| Image generation | Not supported |
| Live API | Not supported |
| Search grounding | Supported |
| Structured outputs | Supported |
| Thinking | Supported |
| URL context | Supported |

---

## Thinking System

Gemini 3.1 Pro uses a **three-tier thinking system** that lets developers control the depth of the model's internal reasoning before generating a response.

### Thinking Levels

Use the `thinking_level` parameter to control reasoning depth:

| Level | Use case |
|-------|----------|
| `"low"` | Fast responses, simple tasks, low latency |
| `"medium"` | Balanced reasoning and latency (new in 3.1) |
| `"high"` | Maximum reasoning depth for complex tasks |

**Notes:**
- Dynamic thinking is enabled by default.
- You **cannot** use both `thinking_level` and the legacy `thinking_budget` parameter in the same request — doing so returns a `400` error.
- The field `total_reasoning_tokens` has been renamed to `total_thought_tokens` in the Interactions API v1beta.

### Thought Signatures

Gemini 3.1 uses **Thought Signatures** to preserve reasoning context across API calls. These are encrypted representations of the model's internal reasoning and **must be returned to the model** in subsequent requests exactly as received.

---

## Pricing

| Usage | Price |
|-------|-------|
| Input | $2.00 per 1M tokens |
| Output | $12.00 per 1M tokens |
| Cached context | Up to 75% discount on repeated contexts |

Pricing is identical to Gemini 3 Pro — performance improvements at no additional cost.

---

## Benchmark Performance

| Benchmark | Score |
|-----------|-------|
| ARC-AGI-2 | 77.1% (more than double Gemini 3 Pro's 31.1%) |
| SWE-Bench Verified | 80.6% |
| GPQA Diamond | 94.3% |
| Artificial Analysis Intelligence Index | 57 (median for similar-tier models: 26) |
| Output speed | 112.0 tokens/sec (median for similar-tier models: 72.0 t/s) |

Gemini 3.1 Pro tops 13 of 16 industry benchmarks and leads on APEX-Agents, nearly doubling Gemini 3 Pro's agentic score.

---

## API Usage

### Basic Text Generation

```python
import google.generativeai as genai

genai.configure(api_key="YOUR_API_KEY")
model = genai.GenerativeModel("gemini-3.1-pro-preview")

response = model.generate_content("Explain quantum entanglement in simple terms.")
print(response.text)
```

### Using the Thinking Feature

```python
response = model.generate_content(
    "Debug this complex async race condition...",
    generation_config={
        "thinking_level": "high"  # low | medium | high
    }
)
print(response.text)
```

### Function Calling (Custom Tools)

Use `gemini-3.1-pro-preview-customtools` for reliable custom tool execution in agentic workflows:

```python
model = genai.GenerativeModel("gemini-3.1-pro-preview-customtools")

tools = [
    {
        "function_declarations": [
            {
                "name": "search_documents",
                "description": "Search through writing documents",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "query": {"type": "string", "description": "Search query"}
                    },
                    "required": ["query"]
                }
            }
        ]
    }
]

response = model.generate_content("Find documents about space exploration", tools=tools)
```

### Multimodal Input (Image + Text)

```python
import PIL.Image

image = PIL.Image.open("document_scan.jpg")
response = model.generate_content(["Summarize the key points from this document:", image])
print(response.text)
```

### Caching for Cost Reduction

```python
# Use caching for repeated long-context calls (up to 75% cost savings)
from google.generativeai import caching
import datetime

cache = caching.CachedContent.create(
    model="gemini-3.1-pro-preview",
    contents=long_context_content,
    ttl=datetime.timedelta(hours=1)
)

model = genai.GenerativeModel.from_cached_content(cached_content=cache)
response = model.generate_content("What are the main themes?")
```

---

## Migration from Gemini 2.5

If upgrading from Gemini 2.5 or earlier:

1. **Remove manual chain-of-thought prompting** — Gemini 3 handles reasoning automatically with `thinking_level`.
2. **Remove explicit temperature settings** — Google recommends using the default temperature of `1.0`. Explicitly setting temperature may cause output looping.
3. **Update `total_reasoning_tokens` references** — Rename to `total_thought_tokens` in the Interactions API v1beta.
4. **Switch to customtools endpoint** if the model ignores your custom functions — use `gemini-3.1-pro-preview-customtools`.

---

## Developer Platforms

Gemini 3.1 Pro Preview is available on:

- **Google AI Studio** — web-based prototyping and testing
- **Gemini API** — direct REST/SDK access
- **Gemini CLI** — command-line tool access
- **Google Antigravity** — agentic development platform
- **Android Studio** — mobile development integration
- **Vertex AI** — enterprise-grade deployment
- **GitHub Copilot** — available to Pro, Pro+, Business, and Enterprise users

---

## Known Limitations

- Still in **preview** as of February 2026 — not yet generally available.
- **Fact-checking accuracy** is significantly lower than Claude Opus 4.6 or GPT-5.2 in internal benchmarks.
- **Knowledge cutoff**: January 2025.
- Function calling with custom tools and built-in tools (e.g., Search, Code Execution) **cannot be used simultaneously** in the same request.

---

## Additional Resources

- [Gemini 3 Developer Guide](https://ai.google.dev/gemini-api/docs/gemini-3)
- [Gemini 3.1 Pro Preview API Reference](https://ai.google.dev/gemini-api/docs/models/gemini-3.1-pro-preview)
- [Vertex AI Gemini 3.1 Pro Documentation](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/models/gemini/3-1-pro)
- [Google Blog: Gemini 3.1 Pro Announcement](https://blog.google/innovation-and-ai/models-and-research/gemini-models/gemini-3-1-pro/)
