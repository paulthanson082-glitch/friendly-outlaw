# AI-Powered Templates & Document Management Design Spec

**Date:** 2026-10-23  
**Project:** friendly-outlaw  
**Scope:** Add AI-powered features for template recommendations, AI template generation, and enhanced document editing with style/tone preservation  
**Status:** Design Phase

---

## Executive Summary

This spec defines three interconnected AI features that enhance the template and document management system in friendly-outlaw:

1. **Template Recommendations (C)** — Claude suggests matching templates based on user intent
2. **AI Template Generation (A)** — Claude generates custom template structures with smart placeholders
3. **Document Enhancement (B)** — Claude continues/improves documents while preserving writing style and tone

These features integrate with the existing `AIService` infrastructure and use the Anthropic API (Claude 3.5 Sonnet by default).

---

## Problem Statement

Currently, friendly-outlaw offers:
- Fixed template library with predefined structures
- Basic AI document continuation and improvement
- No style-aware editing (AI improvements don't match document voice)
- Users must manually browse templates to find matches

**Gaps:**
- New users don't know which template fits their intent
- Users can't create templates without manual effort
- AI-enhanced text often doesn't match existing document style
- No way to customize writing tone (formal, creative, conversational, etc.)

---

## Solution Overview

### User Workflows

**Workflow A: Discover & Use Templates**
```
User describes intent → AI recommends templates → User selects or creates → Document begins
```

**Workflow B: AI-Assisted Template Creation**
```
User describes desired structure → Claude generates template → User customizes → Template saved
```

**Workflow C: Style-Aware Document Editing**
```
User writes document → Selects "Continue" or "Improve" → AI analyzes style → Enhanced text matches voice
```

---

## Architecture

### Data Models

**TemplateRecommendation** — Used in template search results
```swift
struct TemplateRecommendation: Codable {
    let templateId: UUID                // Unique identifier (matches Template.id type)
    let name: String                     // "Mystery Novel Outline"
    let matchScore: Double              // 0.0-1.0 confidence score
    let matchReason: String             // "Matches your focus on plot structure"
    let category: Category              // .fiction, .article, .blog, etc.
}
```

**GeneratedTemplate** — Returned from AI generation before saving
```swift
struct GeneratedTemplate: Codable {
    let name: String
    let category: Category
    let placeholders: [Placeholder]     // User-editable sections
    let structure: String               // Markdown outline with {{PLACEHOLDER_NAME}} markers
}

struct Placeholder: Codable {
    let name: String                    // "OPENING_HOOK"
    let description: String             // "Hook that captures reader attention"
    let exampleText: String             // "The old lighthouse keeper had one secret..."
}
```

**DocumentEnhancementOptions** — Configuration for AI editing
```swift
struct DocumentEnhancementOptions: Codable {
    let preserveStyle: Bool             // Analyze & match document tone/voice
    let targetTone: WritingTone?        // Optional: "confident", "creative", "formal", etc.
    let context: String                 // User notes: "Make it more action-packed"
    
    init(preserveStyle: Bool = true, targetTone: WritingTone? = nil, context: String = "") {
        self.preserveStyle = preserveStyle
        self.targetTone = targetTone
        self.context = context
    }
    
    static let `default` = DocumentEnhancementOptions()
}

enum WritingTone: String, Codable {
    case confident, creative, formal, conversational, academic, casual
}
```

### Service Layer Extensions

**AIService.swift additions:**

```swift
// C: Template Recommendations
func recommendTemplates(
    userIntent: String,
    category: Category? = nil,
    limit: Int = 5
) async throws -> [TemplateRecommendation]
```
- Sends user intent to Claude with available templates
- Returns ranked list with match scores (highest first)
- Filters by category if provided
- Throws `AIServiceError.noMatchingTemplates` if no suitable matches

```swift
// A: AI Template Generation
func generateTemplate(
    description: String,
    category: Category,
    desiredLength: WordCount = .medium
) async throws -> GeneratedTemplate
```
- Takes user description: "A mystery novel outline with multiple suspects"
- Returns structured template with placeholders
- Throws `AIServiceError.templateGenerationFailed` if Claude fails
- Generated templates are not yet saved (user reviews first)

```swift
// B: Enhanced Document Continuation & Improvement
func continueDocument(
    documentId: String,
    context: String = "",
    options: DocumentEnhancementOptions = .default
) async throws -> String

func improveDocument(
    documentId: String,
    focusArea: ImprovementFocus = .overall,
    options: DocumentEnhancementOptions = .default
) async throws -> String
```
- Both methods now accept `DocumentEnhancementOptions`
- If `preserveStyle == true`: analyze document first, inject style guidance into prompt
- If `targetTone` specified: override tone instructions
- Backward compatible (existing calls still work)

### Manager Layer Changes

**TemplateManager.swift:**

```swift
func recommendTemplates(userIntent: String) async throws -> [TemplateRecommendation]
```
- Calls AIService.recommendTemplates()
- Validates that recommended template IDs resolve with `getTemplate(id:)`
- Filters out any recommendations whose templateId cannot be resolved
- Returns only validated recommendations (empty array if all are invalid)
- Throws `AIServiceError.noMatchingTemplates` if Claude returns no matches

```swift
func createTemplateFromAI(generated: GeneratedTemplate) throws -> Template
```
- Converts `GeneratedTemplate` to persistable `Template` with mapping:
  - `GeneratedTemplate.name` → `Template.name`
  - `GeneratedTemplate.category` → `Template.category`
  - `GeneratedTemplate.structure` → `Template.content` (markdown)
  - `GeneratedTemplate.placeholders` → stored as `Template.placeholders` metadata
  - Generates new UUID for `Template.id`
  - Uses current date for `createdAt`
  - Auto-derives description from first 200 chars of structure (or structure name)
- Returns newly persisted Template for immediate use
- Used after user approves AI-generated structure

**DocumentManager.swift:**

Enhanced `continueDocument()` and `improveDocument()` to:
- Accept `DocumentEnhancementOptions`
- Fetch document text from storage using documentId
- Optionally analyze document style and pass to AIService via prompt context
- Call existing AIService text-based methods, passing:
  - Document text directly (not documentId)
  - Analyzed style as system prompt context if `preserveStyle=true`
  - Tone and user context from DocumentEnhancementOptions
- Example style analysis injected into prompt: "tone: conversational, sentence length: short, uses dialogue"

---

## API & Prompt Design

### Template Recommendations Prompt

**System Context:**
```
You are a writing assistant. Based on the user's intent and available templates, 
recommend the best templates. Return valid JSON only.

Available templates:
- fiction-short: Short story templates (500-5000 words)
- fiction-novel: Full novel outlines (50k+ words)
- article-blog: Blog post structure
- article-essay: Long-form essay
- script-dialogue: Screenplay/dialogue format
[etc. - generated from available templates]

For each recommendation, provide JSON with ALL required fields:
{
  "templateId": "550e8400-e29b-41d4-a716-446655440000",
  "name": "Mystery Short Story",
  "matchScore": 0.92,
  "matchReason": "Matches your short fiction intent with strong plot structure focus",
  "category": "fiction"
}
Return array, highest scores first.
```

**User Input Example:**
```
"I want to write a short detective story with a twist ending"
```

**Expected Output:**
```json
[
  {
    "templateId": "fiction-short",
    "name": "Mystery Short Story",
    "matchScore": 0.95,
    "matchReason": "Perfect for mystery short stories; includes twist ending sections"
  },
  {
    "templateId": "fiction-detective",
    "name": "Detective Narrative",
    "matchScore": 0.88,
    "matchReason": "Structured for detective-centered plots with clue layering"
  }
]
```

### Template Generation Prompt

**System Context:**
```
Generate a creative writing template structure. Return valid JSON only.

Template details:
- Category: [user's category]
- Desired length: [word count range]
- Purpose: [derived from user description]

Provide a Markdown outline with {{PLACEHOLDER_NAME: description}} markers.
Include 5-8 key sections with examples.

Return JSON with ALL required fields:
{
  "name": "Template Name",
  "category": "fiction",
  "structure": "# Part 1: Setup\n{{HOOK_OPENING: Attention-grabbing opening}}...",
  "placeholders": [
    {"name": "HOOK_OPENING", "description": "Opening that grabs reader", "exampleText": "The old lighthouse keeper had one secret..."}
  ]
}
```

**User Input Example:**
```
"I want a template for writing a sci-fi novella with world-building and character arcs"
```

**Expected Output:**
```json
{
  "name": "Sci-Fi Novella with World Building",
  "structure": "# Act 1: World Introduction\n{{WORLD_RULES}}...",
  "placeholders": [
    {
      "name": "WORLD_RULES",
      "description": "Core scientific/magical rules of your world",
      "exampleText": "The planet orbits a binary star system..."
    }
  ]
}
```

### Document Enhancement Prompt (Style-Aware)

**System Context (with style analysis):**
```
Enhance the following document [continuation/improvement].

Document style analysis:
- Tone: conversational, warm, encouraging
- Sentence structure: Mix of short punchy sentences and flowing longer ones
- Vocabulary: Accessible, avoids jargon, uses concrete examples
- Perspective: Second person, addresses reader directly
- Pacing: Varies tempo for engagement

Writing instructions:
- MATCH THIS STYLE EXACTLY in your response
- Continue from: [last 500 chars of document]
- Focus: [continuation/grammar/clarity/engagement]
- User context: [optional user notes]
```

---

## Error Handling

**AIServiceError cases:**

| Error | Cause | User Message |
|-------|-------|--------------|
| `templateNotFound(String)` | Referenced template doesn't exist | "Template not found. Try recommendations." |
| `invalidUserIntent` | Intent too vague | "Please be more specific (e.g., 'mystery novel')" |
| `templateGenerationFailed(String)` | Claude failed to generate | "Couldn't generate template. Try different description." |
| `noMatchingTemplates` | No templates match criteria | "No templates match. Try different category." |
| `styleAnalysisFailed` | Can't parse document style | "Proceeding without style matching." (continue anyway) |
| `networkError` | API unavailable | "AI service unavailable. Try again later." |
| `invalidApiResponse` | Claude returned invalid JSON | "AI response parsing failed. Try again." |

---

## Testing Strategy

### Unit Tests

**AIServiceTests.swift** (new file)
- `testRecommendTemplates_returnsValidRecommendations()` — Verify structure and ordering
- `testRecommendTemplates_withCategory()` — Filter by category works
- `testRecommendTemplates_handlesBadIntent()` — Throws invalidUserIntent
- `testRecommendTemplates_noMatches()` — Throws noMatchingTemplates
- `testGenerateTemplate_createsValidStructure()` — Template has required fields
- `testGenerateTemplate_includePlaceholders()` — Placeholders are well-formed
- `testGenerateTemplate_categoryMatches()` — Generated category matches request
- `testEnhanceDocument_preservesStyle()` — Style analysis passes to prompt
- `testEnhanceDocument_appliesTone()` — Tone override works
- `testEnhanceDocument_networkError()` — Handles API failure gracefully

**TemplateManagerTests.swift** (extend)
- `testRecommendTemplates_validatesAgainstSystem()` — Filters deleted templates
- `testCreateTemplateFromAI_convertsStructure()` — GeneratedTemplate → Template
- `testCreateTemplateFromAI_preservesPlaceholders()` — Placeholders stored

**DocumentManagerTests.swift** (extend)
- `testContinueDocument_withOptions()` — Options passed through
- `testImproveDocument_withStyle()` — Style preservation works
- `testContinueDocument_backwardCompatible()` — Old calls still work

### Mock Testing

- Mock AIService responses with known outputs
- Mock Claude API responses (deterministic JSON)
- Mock network failures
- Mock invalid API responses

### Integration Tests

- End-to-end: recommend → select → continue document
- End-to-end: describe template → generate → create → use

---

## Implementation Phases

### Phase 1: Document Enhancements (B)
**Duration:** 2-3 days  
**Files:** AIService.swift, DocumentManager.swift, Tests

- Add `DocumentEnhancementOptions` model
- Extend `continueDocument()` and `improveDocument()` signatures
- Implement style analysis (extract tone/voice from existing text)
- Update Claude prompts to include style context
- Add error handling for style analysis failure
- Write unit tests
- **Deliverable:** Documents can be continued/improved with tone matching

### Phase 2: AI Template Generation (A)
**Duration:** 2-3 days  
**Files:** AIModels.swift, AIService.swift, TemplateManager.swift, Tests

- Add `GeneratedTemplate` and `Placeholder` models
- Implement `AIService.generateTemplate()`
- Implement `TemplateManager.createTemplateFromAI()`
- Design Claude prompt for template generation
- Add validation (ensure placeholders are well-formed)
- Write unit tests
- **Deliverable:** Users can describe a template, Claude generates structure

### Phase 3: Template Recommendations (C)
**Duration:** 2-3 days  
**Files:** AIModels.swift, AIService.swift, TemplateManager.swift, Tests

- Add `TemplateRecommendation` model
- Implement `AIService.recommendTemplates()`
- Implement `TemplateManager.recommendTemplates()` with validation
- Design Claude prompt for recommendations
- Handle edge cases (no matching templates, ambiguous intent)
- Write unit tests
- **Deliverable:** Users get smart template suggestions based on intent

---

## Dependencies & Integration

**External:**
- Anthropic API (Claude 3.5 Sonnet)
- Existing `AIService` infrastructure
- `ANTHROPIC_API_KEY` environment variable

**Internal:**
- Existing `Document`, `Template`, `Category` models
- Existing error handling patterns
- Existing async/await patterns

**No Breaking Changes:**
- All existing AIService methods remain backward compatible
- New features are additive only

---

## Success Criteria

✅ Template recommendations ranked by relevance (matchScore)  
✅ Generated templates include editable placeholders  
✅ AI-enhanced document text matches document style/tone  
✅ All features handle errors gracefully (no crashes)  
✅ 90%+ unit test coverage for new code  
✅ Users can complete workflows without manual intervention  

---

## Open Questions / Decisions

1. **Style Analysis Depth:** Should we extract additional metrics (dialogue percentage, punctuation style, etc.)? Current design uses basic tone/voice. *Recommendation:* Start basic, enhance if needed.

2. **Placeholder Limits:** Max number of placeholders per generated template? Current design unbounded. *Recommendation:* Limit to 10-15 for usability.

3. **Template Recommendation Threshold:** What matchScore should be considered "good enough"? *Recommendation:* Show all above 0.65, highlight 0.85+.

4. **Caching:** Should recommended/generated templates be cached to save API calls? *Recommendation:* Not in Phase 1; add if performance becomes issue.

---

## Files to Create/Modify

| File | Action | Size |
|------|--------|------|
| `docs/superpowers/specs/2026-10-23-ai-templates-documents-design.md` | Create | This spec |
| `Sources/WritersApp/Models/AIModels.swift` | Extend | +150 lines |
| `Sources/WritersApp/Services/AIService.swift` | Extend | +250 lines |
| `Sources/WritersApp/Services/TemplateManager.swift` | Extend | +100 lines |
| `Sources/WritersApp/Services/DocumentManager.swift` | Extend | +75 lines |
| `Tests/WritersAppTests/AIServiceTests.swift` | Create | +400 lines |
| `Tests/WritersAppTests/TemplateManagerTests.swift` | Extend | +100 lines |
| `Tests/WritersAppTests/DocumentManagerTests.swift` | Extend | +75 lines |

**Total new code:** ~1,150 lines (mostly tests)

---

## References

- CLAUDE.md — Project overview and existing patterns
- DATABASE.md — Template/Document schema
- AIService.swift — Existing AI integration patterns
- TemplateManager.swift — Template management patterns
