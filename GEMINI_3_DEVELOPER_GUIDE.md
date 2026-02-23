# Gemini 3 Developer Guide

Gemini 3 is Google's most intelligent model family to date, built on a foundation of state-of-the-art reasoning. It is designed to master agentic workflows, autonomous coding, and complex multimodal tasks.

All Gemini 3 models are currently in **preview**.

Source: [Gemini 3 Developer Guide](https://ai.google.dev/gemini-api/docs/gemini-3)

---

## Quick Start

```python
from google import genai

client = genai.Client()

response = client.models.generate_content(
    model="gemini-3.1-pro-preview",
    contents="Find the race condition in this multi-threaded C++ snippet: [code here]",
)

print(response.text)
```

---

## Model Family

| Model ID | Context Window (In / Out) | Knowledge Cutoff | Description |
|----------|--------------------------|-----------------|-------------|
| `gemini-3.1-pro-preview` | 1M / 64k | Jan 2025 | Next iteration of performance, behavior, and intelligence improvements in the 3 Pro family |
| `gemini-3-pro-preview` | 1M / 64k | Jan 2025 | Best for complex tasks requiring broad world knowledge and advanced reasoning across modalities |
| `gemini-3-flash-preview` | 1M / 64k | Jan 2025 | Pro-level intelligence at the speed and pricing of Flash |
| `gemini-3-pro-image-preview` | 65k / 32k | Jan 2025 | Highest quality image generation model (also known as Nano Banana Pro) |

### Model Versions (`gemini-3.1-pro-preview`)

| Version | Description |
|---------|-------------|
| `gemini-3.1-pro-preview` | Standard endpoint |
| `gemini-3.1-pro-preview-customtools` | Dedicated endpoint for agentic workflows. Use this if the standard model ignores custom tools in favor of built-in bash commands. |

---

## Supported Data Types

| Direction | Supported Types |
|-----------|----------------|
| **Input** | Text, Image, Video, Audio, PDF |
| **Output** | Text |

---

## Token Limits

| Model | Input | Output |
|-------|-------|--------|
| `gemini-3.1-pro-preview` | 1,048,576 | 65,536 |
| `gemini-3-pro-preview` | 1,048,576 | 65,536 |
| `gemini-3-flash-preview` | 1,048,576 | 65,536 |
| `gemini-3-pro-image-preview` | 65,536 | 32,768 |

---

## Capabilities (`gemini-3.1-pro-preview`)

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

## Pricing

| Model | Input (≤200k tokens) | Output (≤200k tokens) | Input (>200k tokens) | Output (>200k tokens) |
|-------|---------------------|----------------------|---------------------|----------------------|
| `gemini-3.1-pro-preview` | $2 / 1M | $12 / 1M | $4 / 1M | $18 / 1M |
| `gemini-3-pro-preview` | $2 / 1M | $12 / 1M | $4 / 1M | $18 / 1M |
| `gemini-3-flash-preview` | $0.50 / 1M | $3 / 1M | — | — |
| `gemini-3-pro-image-preview` | $2 / 1M (text) | $0.134 / image* | — | — |

\* Image output pricing varies by resolution. See the [pricing page](https://ai.google.dev/gemini-api/docs/pricing) for details.

---

## New API Features in Gemini 3

### Thinking Level

Gemini 3 models use dynamic thinking by default. The `thinking_level` parameter controls the maximum depth of the model's internal reasoning before producing a response. Levels are treated as relative allowances rather than strict token guarantees.

**Default**: `high` (if `thinking_level` is not specified).

| Thinking Level | Gemini 3.1 Pro | Gemini 3 Pro | Gemini 3 Flash | Description |
|---------------|---------------|-------------|---------------|-------------|
| `minimal` | Not supported | Not supported | Supported | Matches "no thinking" for most queries. The model may think very minimally for complex coding tasks. Minimizes latency for chat or high-throughput applications. Does **not** guarantee thinking is off. |
| `low` | Supported | Supported | Supported | Minimizes latency and cost. Best for simple instruction following, chat, or high-throughput applications. |
| `medium` | Supported | Not supported | Supported | Balanced thinking for most tasks. |
| `high` | **Default** (Dynamic) | **Default** (Dynamic) | **Default** (Dynamic) | Maximizes reasoning depth. May significantly increase time to first output token, but produces more carefully reasoned responses. |

**Important:** You cannot use both `thinking_level` and the legacy `thinking_budget` parameter in the same request. Doing so returns a `400` error.

```python
from google import genai
from google.genai import types

client = genai.Client()

response = client.models.generate_content(
    model="gemini-3.1-pro-preview",
    contents="How does AI work?",
    config=types.GenerateContentConfig(
        thinking_config=types.ThinkingConfig(thinking_level="low")
    ),
)

print(response.text)
```

---

### Media Resolution

Gemini 3 adds granular control over multimodal vision processing via the `media_resolution` parameter. Higher resolutions improve the model's ability to read fine text or identify small details, but increase token usage and latency.

The parameter determines the maximum tokens allocated per input image or video frame. It can be set per individual media part or globally via `generation_config` (global setting is not available for `ultra_high`).

#### Recommended Settings

| Media Type | Recommended Setting | Max Tokens | Usage Guidance |
|-----------|---------------------|-----------|----------------|
| Images | `media_resolution_high` | 1120 | Recommended for most image analysis tasks to ensure maximum quality. |
| PDFs | `media_resolution_medium` | 560 | Optimal for document understanding; quality typically saturates at medium. Increasing to high rarely improves OCR results for standard documents. |
| Video (General) | `media_resolution_low` or `media_resolution_medium` | 70 per frame | `low` and `medium` are treated identically for video (70 tokens/frame). Sufficient for most action recognition and description tasks. |
| Video (Text-heavy) | `media_resolution_high` | 280 per frame | Required when reading dense text (OCR) or small details within video frames. |

#### Token counts by resolution level

| Resolution | Images | Video |
|-----------|--------|-------|
| `media_resolution_low` | 280 | 70 per frame |
| `media_resolution_medium` | 560 | 70 per frame (same as low) |
| `media_resolution_high` | 1120 | 280 per frame |
| `media_resolution_ultra_high` | — | — |

> **Note:** The `media_resolution` parameter is currently only available in the `v1alpha` API version.

```python
from google import genai
from google.genai import types
import base64

# media_resolution is only available in the v1alpha API version
client = genai.Client(http_options={'api_version': 'v1alpha'})

response = client.models.generate_content(
    model="gemini-3.1-pro-preview",
    contents=[
        types.Content(
            parts=[
                types.Part(text="What is in this image?"),
                types.Part(
                    inline_data=types.Blob(
                        mime_type="image/jpeg",
                        data=base64.b64decode("..."),
                    ),
                    media_resolution={"level": "media_resolution_high"}
                )
            ]
        )
    ]
)

print(response.text)
```

---

## Benchmark Performance

| Benchmark | Score |
|-----------|-------|
| ARC-AGI-2 | 77.1% (vs. Gemini 3 Pro: 31.1%) |
| SWE-Bench Verified | 80.6% |
| GPQA Diamond | 94.3% |
| Artificial Analysis Intelligence Index | 57 (median for similar-tier models: 26) |
| Output speed | 112.0 tokens/sec (median for similar-tier models: 72.0 t/s) |

Gemini 3.1 Pro tops 13 of 16 industry benchmarks and leads on APEX-Agents, nearly doubling Gemini 3 Pro's agentic score.

---

## Migration from Gemini 2.5

If upgrading from Gemini 2.5 or earlier:

1. **Remove manual chain-of-thought prompting** — Gemini 3 handles reasoning automatically via `thinking_level`.
2. **Remove explicit temperature settings** — Google recommends using the default (`1.0`). Explicitly setting temperature may cause output looping.
3. **Replace `thinking_budget`** with `thinking_level` — they cannot be used together.
4. **Switch to the customtools endpoint** if the standard model ignores custom functions — use `gemini-3.1-pro-preview-customtools`.

---

## Developer Platforms

Gemini 3.1 Pro Preview is available on:

- **Google AI Studio** — web-based prototyping and testing
- **Gemini API** — direct REST/SDK access
- **Gemini CLI** — command-line access
- **Google Antigravity** — agentic development platform
- **Android Studio** — mobile development integration
- **Vertex AI** — enterprise deployment
- **GitHub Copilot** — available to Pro, Pro+, Business, and Enterprise users

---

## Known Limitations

- All Gemini 3 models are still in **preview** — not yet generally available.
- **Knowledge cutoff**: January 2025.
- Custom tools and built-in tools (Search, Code Execution) **cannot be used simultaneously** in the same request.
- `minimal` thinking level is only available on Gemini 3 Flash, not Pro variants.
- `media_resolution` is only available via the `v1alpha` API version.

---

## Additional Resources

- [Gemini 3 Developer Guide](https://ai.google.dev/gemini-api/docs/gemini-3)
- [Gemini 3.1 Pro Preview model page](https://ai.google.dev/gemini-api/docs/models/gemini-3.1-pro-preview)
- [Media resolution docs](https://ai.google.dev/gemini-api/docs/media-resolution)
- [Gemini API pricing](https://ai.google.dev/gemini-api/docs/pricing)
- [Vertex AI Gemini 3.1 Pro](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/models/gemini/3-1-pro)
