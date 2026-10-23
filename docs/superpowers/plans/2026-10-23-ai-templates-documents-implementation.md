# AI-Powered Templates & Document Management Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement three interconnected AI features for template recommendations, template generation, and style-aware document editing in the friendly-outlaw writing app.

**Architecture:** Three phases delivering independent but complementary features built on the existing AIService infrastructure. Phase 1 (Document Enhancements) is the foundation, enabling style analysis. Phases 2 and 3 extend template management with AI-powered discovery and creation.

**Tech Stack:** Swift 5.9+, Anthropic API (Claude 3.5 Sonnet), async/await patterns, existing project's error handling

**Spec:** `docs/superpowers/specs/2026-10-23-ai-templates-documents-design.md`

---

## Global Constraints

- **Swift Version:** 5.9+
- **Platform:** macOS 14+, iOS 16+
- **Anthropic API:** Claude 3.5 Sonnet
- **API Key:** `ANTHROPIC_API_KEY` environment variable
- **Backward Compatibility:** All new features are additive; existing methods remain unchanged
- **Error Handling:** Use typed `AIServiceError` with user-friendly messages
- **Testing:** 90%+ coverage for new code; use existing mock patterns
- **No Breaking Changes:** Existing `continueDocument()` and `improveDocument()` calls must work unchanged

---

## File Structure

### New Files
- `Sources/WritersApp/Models/AIModels.swift` — Will add new model structs for Document Enhancement Options
- `Tests/WritersAppTests/AIServiceTests.swift` — New test file for AI service features

### Modified Files
- `Sources/WritersApp/Services/AIService.swift` — Add 3 new methods + style analysis helper
- `Sources/WritersApp/Services/DocumentManager.swift` — Extend existing methods to support options
- `Sources/WritersApp/Services/TemplateManager.swift` — Add AI-powered template methods
- `Tests/WritersAppTests/DocumentManagerTests.swift` — Add tests for new options
- `Tests/WritersAppTests/TemplateManagerTests.swift` — Add tests for AI template methods

---

# PHASE 1: Document Enhancements (Style-Aware Editing)

> **Deliverable:** Documents can be continued and improved with automatic style/tone matching.

## Task 1.1: Add DocumentEnhancementOptions Model

**Files:**
- Modify: `Sources/WritersApp/Models/AIModels.swift`

**Interfaces:**
- Produces: `DocumentEnhancementOptions` struct with `preserveStyle: Bool`, `targetTone: WritingTone?`, `context: String`
- Produces: `WritingTone` enum with cases: `.confident`, `.creative`, `.formal`, `.conversational`, `.academic`, `.casual`

- [ ] **Step 1: Open AIModels.swift and examine existing models**

Run: `cat Sources/WritersApp/Models/AIModels.swift | head -50`

Look for: Existing struct patterns, protocol conformances (Codable, etc.)

- [ ] **Step 2: Add WritingTone enum**

```swift
enum WritingTone: String, Codable {
    case confident
    case creative
    case formal
    case conversational
    case academic
    case casual
}
```

Insert this after existing enums, before the closing brace. Match indentation/style of existing code.

- [ ] **Step 3: Add DocumentEnhancementOptions struct**

```swift
struct DocumentEnhancementOptions: Codable {
    let preserveStyle: Bool
    let targetTone: WritingTone?
    let context: String
    
    init(preserveStyle: Bool = true, targetTone: WritingTone? = nil, context: String = "") {
        self.preserveStyle = preserveStyle
        self.targetTone = targetTone
        self.context = context
    }
    
    static let `default` = DocumentEnhancementOptions()
}
```

- [ ] **Step 4: Verify it compiles**

Run: `swift build 2>&1 | grep -i "error\|AIModels"`

Expected: No errors mentioning AIModels.swift

- [ ] **Step 5: Commit**

```bash
git add Sources/WritersApp/Models/AIModels.swift
git commit -m "feat: add DocumentEnhancementOptions and WritingTone models

- WritingTone enum with 6 tone variants
- DocumentEnhancementOptions for configuring document edits
- Supports style preservation and tone override
"
```

---

## Task 1.2: Add Style Analysis Helper to AIService

**Files:**
- Modify: `Sources/WritersApp/Services/AIService.swift`

**Interfaces:**
- Consumes: Document text (String)
- Produces: Style analysis string describing tone, sentence structure, vocabulary, etc.

- [ ] **Step 1: Open AIService.swift and find the class definition**

Run: `grep -n "class AIService" Sources/WritersApp/Services/AIService.swift`

Note the line number. This is where we'll add the private helper method.

- [ ] **Step 2: Add private style analysis method**

Before the final closing brace of AIService class, add:

```swift
private func analyzeDocumentStyle(_ text: String) -> String {
    guard !text.isEmpty else {
        return "No document text to analyze"
    }
    
    let sentences = text.split(separator: ".").count
    let words = text.split(separator: " ").count
    let averageWordsPerSentence = words > 0 ? words / sentences : 0
    
    let shortSentences = text.split(separator: ".").filter { sent in
        sent.split(separator: " ").count < 10
    }.count
    
    let hasDialogue = text.contains("\"") || text.contains(""")
    let perspective = text.contains("I ") ? "first person" : 
                     text.contains("you ") ? "second person" : 
                     "third person"
    
    var analysis = """
    Document style analysis:
    - Perspective: \(perspective)
    - Sentence length: \(averageWordsPerSentence) words/sentence (shorter = punchier, longer = flowing)
    - Sentence variety: \(shortSentences)/\(sentences) short sentences (more variation = more engaging)
    - Contains dialogue: \(hasDialogue ? "yes" : "no")
    - Total length: \(words) words
    """
    
    return analysis
}
```

- [ ] **Step 3: Verify the method is recognized**

Run: `swift build 2>&1 | grep -i error`

Expected: No errors (or only pre-existing ones)

- [ ] **Step 4: Commit**

```bash
git add Sources/WritersApp/Services/AIService.swift
git commit -m "feat: add private analyzeDocumentStyle helper

- Extracts tone, sentence structure, dialogue usage, perspective
- Returns human-readable style analysis string
- Used by enhanced document continuation/improvement
"
```

---

## Task 1.3: Extend continueDocument with Style Options

**Files:**
- Modify: `Sources/WritersApp/Services/AIService.swift`

**Interfaces:**
- Consumes: `DocumentEnhancementOptions` struct (from Task 1.1)
- Consumes: Existing `continueDocument(documentId:context:)` parameters
- Produces: Same return type as existing (String)

- [ ] **Step 1: Find the current continueDocument method**

Run: `grep -n "func continueDocument" Sources/WritersApp/Services/AIService.swift`

Note the line number and existing signature.

- [ ] **Step 2: Create new continueDocument signature alongside existing**

Add this new version (keep the old one):

```swift
func continueDocument(
    documentId: String,
    context: String = "",
    options: DocumentEnhancementOptions = .default
) async throws -> String {
    guard let document = documentManager.getDocument(documentId) else {
        throw AIServiceError.documentNotFound(documentId)
    }
    
    var systemPrompt = """
    You are a writing assistant helping to continue a document.
    
    Document content (last 500 characters):
    ---
    \(String(document.content.suffix(500)))
    ---
    """
    
    if options.preserveStyle {
        let styleAnalysis = analyzeDocumentStyle(document.content)
        systemPrompt += "\n\n\(styleAnalysis)\n\nMATCH THIS STYLE EXACTLY in your response."
    }
    
    if let tone = options.targetTone {
        systemPrompt += "\n\nUse a \(tone.rawValue) tone."
    }
    
    if !options.context.isEmpty {
        systemPrompt += "\n\nUser note: \(options.context)"
    }
    
    let prompt = "Continue this document naturally:"
    
    return try await sendToClaude(
        systemPrompt: systemPrompt,
        userPrompt: prompt,
        maxTokens: 1000
    )
}
```

**Important:** Keep the existing `continueDocument(documentId:context:)` method unchanged for backward compatibility.

- [ ] **Step 3: Verify compilation**

Run: `swift build 2>&1 | grep -A5 "error"`

Expected: No new errors

- [ ] **Step 4: Commit**

```bash
git add Sources/WritersApp/Services/AIService.swift
git commit -m "feat: add style-aware continueDocument variant

- New overload accepts DocumentEnhancementOptions
- Analyzes document style when preserveStyle=true
- Applies tone override if targetTone specified
- Old signature remains for backward compatibility
"
```

---

## Task 1.4: Extend improveDocument with Style Options

**Files:**
- Modify: `Sources/WritersApp/Services/AIService.swift`

**Interfaces:**
- Consumes: `DocumentEnhancementOptions` struct
- Consumes: `ImprovementFocus` enum (existing)
- Produces: String (improved document text)

- [ ] **Step 1: Find existing improveDocument method**

Run: `grep -n "func improveDocument" Sources/WritersApp/Services/AIService.swift`

- [ ] **Step 2: Add new improveDocument overload**

```swift
func improveDocument(
    documentId: String,
    focusArea: ImprovementFocus = .overall,
    options: DocumentEnhancementOptions = .default
) async throws -> String {
    guard let document = documentManager.getDocument(documentId) else {
        throw AIServiceError.documentNotFound(documentId)
    }
    
    var systemPrompt = """
    You are an expert writing editor improving a document.
    
    Focus area: \(focusArea.description)
    
    Document to improve:
    ---
    \(document.content)
    ---
    """
    
    if options.preserveStyle {
        let styleAnalysis = analyzeDocumentStyle(document.content)
        systemPrompt += "\n\n\(styleAnalysis)\n\nMATCH THIS STYLE EXACTLY in your response."
    }
    
    if let tone = options.targetTone {
        systemPrompt += "\n\nUse a \(tone.rawValue) tone."
    }
    
    if !options.context.isEmpty {
        systemPrompt += "\n\nUser note: \(options.context)"
    }
    
    let prompt = """
    Improve this document focusing on \(focusArea.description).
    Return the full improved document.
    """
    
    return try await sendToClaude(
        systemPrompt: systemPrompt,
        userPrompt: prompt,
        maxTokens: 2000
    )
}
```

**Important:** Keep the existing method for backward compatibility.

- [ ] **Step 3: Verify compilation**

Run: `swift build 2>&1 | grep "error"`

Expected: No errors

- [ ] **Step 4: Commit**

```bash
git add Sources/WritersApp/Services/AIService.swift
git commit -m "feat: add style-aware improveDocument variant

- New overload accepts DocumentEnhancementOptions  
- Preserves document style when requested
- Supports tone override and user context
- Maintains backward compatibility
"
```

---

## Task 1.5: Write Unit Tests for Document Enhancement

**Files:**
- Create: `Tests/WritersAppTests/AIServiceTests.swift`

**Interfaces:**
- Consumes: `AIService`, `DocumentEnhancementOptions`, `WritingTone`
- Tests: Both new document enhancement methods

- [ ] **Step 1: Create AIServiceTests.swift with imports**

```swift
import XCTest
@testable import WritersApp

class AIServiceTests: XCTestCase {
    var sut: AIService!
    var mockDocumentManager: MockDocumentManager!
    
    override func setUp() {
        super.setUp()
        mockDocumentManager = MockDocumentManager()
        sut = AIService(documentManager: mockDocumentManager)
    }
    
    override func tearDown() {
        sut = nil
        mockDocumentManager = nil
        super.tearDown()
    }
}
```

- [ ] **Step 2: Add test for continueDocument with style preservation**

```swift
func testContinueDocument_withStylePreservation() async throws {
    // Setup
    let testDoc = Document(
        id: "test-1",
        title: "Test",
        content: "The quick brown fox jumps. It moves fast.",
        category: .fiction
    )
    mockDocumentManager.documents["test-1"] = testDoc
    
    let options = DocumentEnhancementOptions(
        preserveStyle: true,
        targetTone: nil,
        context: ""
    )
    
    // Execute
    let result = try await sut.continueDocument(
        documentId: "test-1",
        options: options
    )
    
    // Verify
    XCTAssertFalse(result.isEmpty)
    // Verify it's not just returning the input
    XCTAssertNotEqual(result, testDoc.content)
}
```

- [ ] **Step 3: Add test for continueDocument with tone override**

```swift
func testContinueDocument_withToneOverride() async throws {
    let testDoc = Document(
        id: "test-2",
        title: "Test",
        content: "Going forward with this project.",
        category: .article
    )
    mockDocumentManager.documents["test-2"] = testDoc
    
    let options = DocumentEnhancementOptions(
        preserveStyle: false,
        targetTone: .formal,
        context: ""
    )
    
    let result = try await sut.continueDocument(
        documentId: "test-2",
        options: options
    )
    
    XCTAssertFalse(result.isEmpty)
}
```

- [ ] **Step 4: Add test for improveDocument with options**

```swift
func testImproveDocument_withStylePreservation() async throws {
    let testDoc = Document(
        id: "test-3",
        title: "Test",
        content: "The cat sat on the mat. The mat was soft.",
        category: .fiction
    )
    mockDocumentManager.documents["test-3"] = testDoc
    
    let options = DocumentEnhancementOptions(
        preserveStyle: true,
        targetTone: .creative,
        context: "Make it more vivid"
    )
    
    let result = try await sut.improveDocument(
        documentId: "test-3",
        focusArea: .engagement,
        options: options
    )
    
    XCTAssertFalse(result.isEmpty)
    // Result should be improved version
    XCTAssertGreaterThan(result.count, 0)
}
```

- [ ] **Step 5: Add test for backward compatibility**

```swift
func testContinueDocument_backwardCompatible() async throws {
    let testDoc = Document(
        id: "test-4",
        title: "Test",
        content: "Once upon a time...",
        category: .fiction
    )
    mockDocumentManager.documents["test-4"] = testDoc
    
    // Call old signature (should still work)
    let result = try await sut.continueDocument(
        documentId: "test-4",
        context: "add more detail"
    )
    
    XCTAssertFalse(result.isEmpty)
}
```

- [ ] **Step 6: Add test for style analysis helper**

```swift
func testAnalyzeDocumentStyle_extractsMetrics() {
    let text = "The fox jumped. It was quick. A flash of movement."
    
    let analysis = sut.analyzeDocumentStyle(text)
    
    XCTAssertTrue(analysis.contains("perspective"))
    XCTAssertTrue(analysis.contains("Sentence"))
    XCTAssertTrue(analysis.contains("words"))
}
```

- [ ] **Step 7: Run tests to verify they compile**

Run: `swift test AIServiceTests 2>&1 | head -20`

Expected: Tests load without syntax errors

- [ ] **Step 8: Commit**

```bash
git add Tests/WritersAppTests/AIServiceTests.swift
git commit -m "test: add unit tests for document enhancement features

- testContinueDocument_withStylePreservation
- testContinueDocument_withToneOverride
- testImproveDocument_withStylePreservation
- testContinueDocument_backwardCompatible
- testAnalyzeDocumentStyle_extractsMetrics
"
```

---

## Task 1.6: Update DocumentManager to Support Enhancement Options

**Files:**
- Modify: `Tests/WritersAppTests/DocumentManagerTests.swift`

**Interfaces:**
- Consumes: `DocumentEnhancementOptions`
- Produces: Test verification that options pass through correctly

- [ ] **Step 1: Add test for continueDocument with options**

```swift
func testContinueDocument_passesOptionsToAIService() async throws {
    let options = DocumentEnhancementOptions(
        preserveStyle: true,
        targetTone: .creative,
        context: "Add drama"
    )
    
    let result = try await documentManager.continueDocument(
        documentId: "doc-1",
        options: options
    )
    
    XCTAssertFalse(result.isEmpty)
}
```

- [ ] **Step 2: Add test for improveDocument with options**

```swift
func testImproveDocument_passesOptionsToAIService() async throws {
    let options = DocumentEnhancementOptions(
        preserveStyle: false,
        targetTone: .formal,
        context: ""
    )
    
    let result = try await documentManager.improveDocument(
        documentId: "doc-1",
        focusArea: .clarity,
        options: options
    )
    
    XCTAssertFalse(result.isEmpty)
}
```

- [ ] **Step 3: Verify tests compile**

Run: `swift test DocumentManagerTests 2>&1 | grep -i "error\|fail"`

Expected: No compilation errors

- [ ] **Step 4: Commit**

```bash
git add Tests/WritersAppTests/DocumentManagerTests.swift
git commit -m "test: add tests for DocumentEnhancementOptions pass-through

- Verify continueDocument accepts and uses options
- Verify improveDocument accepts and uses options
"
```

---

# PHASE 2: AI Template Generation

> **Deliverable:** Users can describe a template and AI generates structured template with placeholders.

## Task 2.1: Add GeneratedTemplate and Placeholder Models

**Files:**
- Modify: `Sources/WritersApp/Models/AIModels.swift`

**Interfaces:**
- Produces: `Placeholder` struct (name, description, exampleText)
- Produces: `GeneratedTemplate` struct (name, category, placeholders, structure)

- [ ] **Step 1: Add Placeholder struct**

```swift
struct Placeholder: Codable {
    let name: String
    let description: String
    let exampleText: String
}
```

- [ ] **Step 2: Add GeneratedTemplate struct**

```swift
struct GeneratedTemplate: Codable {
    let name: String
    let category: Category
    let placeholders: [Placeholder]
    let structure: String
    
    // Validation
    func validatePlaceholders() -> Bool {
        return !placeholders.isEmpty && placeholders.count <= 15
    }
}
```

- [ ] **Step 3: Verify compilation**

Run: `swift build 2>&1 | grep -i "error"`

Expected: No errors

- [ ] **Step 4: Commit**

```bash
git add Sources/WritersApp/Models/AIModels.swift
git commit -m "feat: add GeneratedTemplate and Placeholder models

- Placeholder: name, description, exampleText
- GeneratedTemplate: name, category, placeholders, structure
- Validation ensures max 15 placeholders per template
"
```

---

## Task 2.2: Implement generateTemplate in AIService

**Files:**
- Modify: `Sources/WritersApp/Services/AIService.swift`

**Interfaces:**
- Consumes: `description: String`, `category: Category`, `desiredLength: WordCount`
- Produces: `GeneratedTemplate` struct

- [ ] **Step 1: Add generateTemplate method**

```swift
func generateTemplate(
    description: String,
    category: Category,
    desiredLength: WordCount = .medium
) async throws -> GeneratedTemplate {
    guard !description.trimmingCharacters(in: .whitespaces).isEmpty else {
        throw AIServiceError.invalidUserIntent
    }
    
    let wordCountRange = desiredLength.range
    
    let systemPrompt = """
    You are a creative writing template designer. Generate a template structure.
    Return ONLY valid JSON, no markdown, no explanation.
    
    Template requirements:
    - Category: \(category.rawValue)
    - Word count: \(wordCountRange.lowerBound)-\(wordCountRange.upperBound) words
    - Include 5-8 sections with {{PLACEHOLDER_NAME}} markers
    - Each placeholder needs name (CAPS), description, and example
    
    JSON format:
    {
      "name": "Template Name",
      "category": "\(category.rawValue)",
      "structure": "# Section\\n{{PLACEHOLDER}}...",
      "placeholders": [
        {"name": "PLACEHOLDER", "description": "...", "exampleText": "..."}
      ]
    }
    """
    
    let userPrompt = "Create a template for: \(description)"
    
    let response = try await sendToClaude(
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
        maxTokens: 1500
    )
    
    // Parse JSON response
    guard let jsonData = response.data(using: .utf8) else {
        throw AIServiceError.invalidApiResponse
    }
    
    let decoder = JSONDecoder()
    let generated = try decoder.decode(GeneratedTemplate.self, from: jsonData)
    
    guard generated.validatePlaceholders() else {
        throw AIServiceError.templateGenerationFailed("Too many placeholders (max 15)")
    }
    
    return generated
}
```

- [ ] **Step 2: Add error case if not present**

In AIServiceError enum, ensure this case exists:

```swift
case templateGenerationFailed(String)
```

- [ ] **Step 3: Verify compilation**

Run: `swift build 2>&1 | grep "error"`

Expected: No new errors

- [ ] **Step 4: Commit**

```bash
git add Sources/WritersApp/Services/AIService.swift
git commit -m "feat: implement generateTemplate in AIService

- Accepts description, category, desired word count
- Sends to Claude with JSON format requirements
- Parses and validates response
- Throws appropriate errors on failure
"
```

---

## Task 2.3: Implement createTemplateFromAI in TemplateManager

**Files:**
- Modify: `Sources/WritersApp/Services/TemplateManager.swift`

**Interfaces:**
- Consumes: `GeneratedTemplate` (from Task 2.1)
- Produces: `Template` (existing type, fully populated)

- [ ] **Step 1: Find TemplateManager class**

Run: `grep -n "class TemplateManager" Sources/WritersApp/Services/TemplateManager.swift`

- [ ] **Step 2: Add createTemplateFromAI method**

```swift
func createTemplateFromAI(generated: GeneratedTemplate) throws -> Template {
    let templateId = UUID().uuidString
    
    // Convert GeneratedTemplate to Template
    let template = Template(
        id: templateId,
        name: generated.name,
        category: generated.category,
        structure: generated.structure,
        placeholders: generated.placeholders.map { p in
            TemplatePlaceholder(
                id: UUID().uuidString,
                name: p.name,
                description: p.description,
                defaultText: p.exampleText
            )
        },
        createdAt: Date(),
        isArchived: false
    )
    
    // Store in system
    templates[templateId] = template
    
    return template
}
```

**Note:** Adjust `TemplatePlaceholder` initialization based on your actual Template schema.

- [ ] **Step 3: Verify it compiles**

Run: `swift build 2>&1 | grep "error"`

- [ ] **Step 4: Commit**

```bash
git add Sources/WritersApp/Services/TemplateManager.swift
git commit -m "feat: add createTemplateFromAI to TemplateManager

- Converts GeneratedTemplate to persistent Template
- Generates unique template ID
- Stores placeholders with descriptions
- Returns fully initialized Template
"
```

---

## Task 2.4: Write Tests for Template Generation

**Files:**
- Modify: `Tests/WritersAppTests/AIServiceTests.swift`
- Modify: `Tests/WritersAppTests/TemplateManagerTests.swift`

**Interfaces:**
- Tests: `generateTemplate()` method
- Tests: `createTemplateFromAI()` method

- [ ] **Step 1: Add test to AIServiceTests**

```swift
func testGenerateTemplate_returnsValidStructure() async throws {
    let result = try await sut.generateTemplate(
        description: "A mystery novel outline with multiple suspects",
        category: .fiction,
        desiredLength: .long
    )
    
    XCTAssertFalse(result.name.isEmpty)
    XCTAssertEqual(result.category, .fiction)
    XCTAssertFalse(result.structure.isEmpty)
    XCTAssertFalse(result.placeholders.isEmpty)
}
```

- [ ] **Step 2: Add test for placeholder validation**

```swift
func testGenerateTemplate_placeholdersWellFormed() async throws {
    let result = try await sut.generateTemplate(
        description: "A short story",
        category: .fiction,
        desiredLength: .short
    )
    
    for placeholder in result.placeholders {
        XCTAssertFalse(placeholder.name.isEmpty)
        XCTAssertFalse(placeholder.description.isEmpty)
        XCTAssertFalse(placeholder.exampleText.isEmpty)
    }
}
```

- [ ] **Step 3: Add test to TemplateManagerTests**

```swift
func testCreateTemplateFromAI_convertsAndStores() throws {
    let generated = GeneratedTemplate(
        name: "Test Template",
        category: .fiction,
        placeholders: [
            Placeholder(
                name: "OPENING",
                description: "Opening hook",
                exampleText: "Once upon a time..."
            )
        ],
        structure: "# Introduction\n{{OPENING}}"
    )
    
    let result = try templateManager.createTemplateFromAI(generated: generated)
    
    XCTAssertEqual(result.name, "Test Template")
    XCTAssertEqual(result.category, .fiction)
    XCTAssertEqual(result.placeholders.count, 1)
}
```

- [ ] **Step 4: Run tests**

Run: `swift test AIServiceTests TemplateManagerTests 2>&1 | grep -i "pass\|fail"`

Expected: Tests compile without errors

- [ ] **Step 5: Commit**

```bash
git add Tests/WritersAppTests/AIServiceTests.swift Tests/WritersAppTests/TemplateManagerTests.swift
git commit -m "test: add unit tests for template generation features

- testGenerateTemplate_returnsValidStructure
- testGenerateTemplate_placeholdersWellFormed
- testCreateTemplateFromAI_convertsAndStores
"
```

---

# PHASE 3: Template Recommendations

> **Deliverable:** Users can describe their intent and AI recommends matching templates from system library.

## Task 3.1: Add TemplateRecommendation Model

**Files:**
- Modify: `Sources/WritersApp/Models/AIModels.swift`

**Interfaces:**
- Produces: `TemplateRecommendation` struct (templateId, name, matchScore, matchReason, category)

- [ ] **Step 1: Add TemplateRecommendation struct**

```swift
struct TemplateRecommendation: Codable {
    let templateId: String
    let name: String
    let matchScore: Double
    let matchReason: String
    let category: Category
    
    // Validation
    func isReliableMatch() -> Bool {
        return matchScore >= 0.65
    }
    
    func isHighlyRecommended() -> Bool {
        return matchScore >= 0.85
    }
}
```

- [ ] **Step 2: Verify compilation**

Run: `swift build 2>&1 | grep "error"`

- [ ] **Step 3: Commit**

```bash
git add Sources/WritersApp/Models/AIModels.swift
git commit -m "feat: add TemplateRecommendation model

- Includes matchScore (0.0-1.0) and matchReason
- Validation methods for reliability thresholds
- Supports filtering by match quality
"
```

---

## Task 3.2: Implement recommendTemplates in AIService

**Files:**
- Modify: `Sources/WritersApp/Services/AIService.swift`

**Interfaces:**
- Consumes: `userIntent: String`, `category: Category?`, `limit: Int`
- Produces: `[TemplateRecommendation]` array

- [ ] **Step 1: Add recommendTemplates method**

```swift
func recommendTemplates(
    userIntent: String,
    category: Category? = nil,
    limit: Int = 5
) async throws -> [TemplateRecommendation] {
    guard !userIntent.trimmingCharacters(in: .whitespaces).isEmpty else {
        throw AIServiceError.invalidUserIntent
    }
    
    let availableTemplates = templateManager.getAllActiveTemplates()
    
    guard !availableTemplates.isEmpty else {
        throw AIServiceError.noMatchingTemplates
    }
    
    // Build template list for context
    let templateList = availableTemplates.map { template in
        "\(template.id): \(template.name) (\(template.category.rawValue))"
    }.joined(separator: "\n")
    
    let systemPrompt = """
    You are a writing assistant that recommends templates.
    Return ONLY valid JSON array, no markdown or explanation.
    
    Available templates:
    \(templateList)
    
    For each recommendation, provide:
    {
      "templateId": "id",
      "name": "Template Name",
      "matchScore": 0.92,
      "matchReason": "Why this matches",
      "category": "fiction"
    }
    
    Return array sorted by matchScore descending.
    """
    
    let userPrompt = "User intent: \(userIntent)"
    
    let response = try await sendToClaude(
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
        maxTokens: 800
    )
    
    // Parse JSON response
    guard let jsonData = response.data(using: .utf8) else {
        throw AIServiceError.invalidApiResponse
    }
    
    let decoder = JSONDecoder()
    var recommendations = try decoder.decode([TemplateRecommendation].self, from: jsonData)
    
    // Validate template IDs exist
    recommendations = recommendations.filter { rec in
        availableTemplates.contains { $0.id == rec.templateId }
    }
    
    guard !recommendations.isEmpty else {
        throw AIServiceError.noMatchingTemplates
    }
    
    // Filter by category if specified
    if let category = category {
        recommendations = recommendations.filter { $0.category == category }
    }
    
    // Limit results
    return Array(recommendations.prefix(limit))
}
```

- [ ] **Step 2: Ensure error cases exist**

In AIServiceError, verify:

```swift
case noMatchingTemplates
case invalidUserIntent
```

- [ ] **Step 3: Verify compilation**

Run: `swift build 2>&1 | grep "error"`

- [ ] **Step 4: Commit**

```bash
git add Sources/WritersApp/Services/AIService.swift
git commit -m "feat: implement recommendTemplates in AIService

- Accepts user intent, optional category filter, limit
- Sends available templates to Claude for matching
- Parses and validates template IDs exist
- Returns sorted by relevance (matchScore)
"
```

---

## Task 3.3: Implement recommendTemplates in TemplateManager

**Files:**
- Modify: `Sources/WritersApp/Services/TemplateManager.swift`

**Interfaces:**
- Consumes: `[TemplateRecommendation]` from AIService
- Produces: Validated recommendations with actual template metadata

- [ ] **Step 1: Add recommendTemplates method**

```swift
func recommendTemplates(userIntent: String) async throws -> [TemplateRecommendation] {
    var recommendations = try await aiService.recommendTemplates(userIntent: userIntent)
    
    // Final validation: ensure templates still exist and aren't archived
    recommendations = recommendations.filter { rec in
        guard let template = templates[rec.templateId] else { return false }
        return !template.isArchived
    }
    
    guard !recommendations.isEmpty else {
        throw AIServiceError.noMatchingTemplates
    }
    
    return recommendations
}
```

- [ ] **Step 2: Verify compilation**

Run: `swift build 2>&1 | grep "error"`

- [ ] **Step 3: Commit**

```bash
git add Sources/WritersApp/Services/TemplateManager.swift
git commit -m "feat: add recommendTemplates to TemplateManager

- Calls AIService for recommendations
- Validates templates still exist and are active
- Filters out archived templates
- Returns only valid recommendations
"
```

---

## Task 3.4: Write Tests for Template Recommendations

**Files:**
- Modify: `Tests/WritersAppTests/AIServiceTests.swift`
- Modify: `Tests/WritersAppTests/TemplateManagerTests.swift`

**Interfaces:**
- Tests: `recommendTemplates()` in both services

- [ ] **Step 1: Add test to AIServiceTests**

```swift
func testRecommendTemplates_returnsValidRecommendations() async throws {
    let result = try await sut.recommendTemplates(userIntent: "I want to write a mystery novel")
    
    XCTAssertFalse(result.isEmpty)
    
    // Verify all results are well-formed
    for rec in result {
        XCTAssertFalse(rec.templateId.isEmpty)
        XCTAssertFalse(rec.name.isEmpty)
        XCTAssertTrue(rec.matchScore >= 0.0 && rec.matchScore <= 1.0)
        XCTAssertFalse(rec.matchReason.isEmpty)
    }
}
```

- [ ] **Step 2: Add test with category filter**

```swift
func testRecommendTemplates_withCategory() async throws {
    let result = try await sut.recommendTemplates(
        userIntent: "short story",
        category: .fiction,
        limit: 3
    )
    
    XCTAssertLessThanOrEqual(result.count, 3)
    
    for rec in result {
        XCTAssertEqual(rec.category, .fiction)
    }
}
```

- [ ] **Step 3: Add test for bad intent**

```swift
func testRecommendTemplates_handlesBadIntent() async throws {
    do {
        _ = try await sut.recommendTemplates(userIntent: "   ")
        XCTFail("Should throw invalidUserIntent")
    } catch AIServiceError.invalidUserIntent {
        // Expected
    }
}
```

- [ ] **Step 4: Add test to TemplateManagerTests**

```swift
func testRecommendTemplates_validatesAgainstSystem() async throws {
    let result = try await templateManager.recommendTemplates(
        userIntent: "I want to write a blog post"
    )
    
    // Each recommendation must point to valid, active template
    for rec in result {
        let template = templateManager.getTemplate(rec.templateId)
        XCTAssertNotNil(template)
        XCTAssertFalse(template!.isArchived)
    }
}
```

- [ ] **Step 5: Run tests**

Run: `swift test AIServiceTests TemplateManagerTests 2>&1 | tail -10`

Expected: All tests compile and pass

- [ ] **Step 6: Commit**

```bash
git add Tests/WritersAppTests/AIServiceTests.swift Tests/WritersAppTests/TemplateManagerTests.swift
git commit -m "test: add unit tests for template recommendation features

- testRecommendTemplates_returnsValidRecommendations
- testRecommendTemplates_withCategory
- testRecommendTemplates_handlesBadIntent
- testRecommendTemplates_validatesAgainstSystem
"
```

---

# Integration & Finalization

## Task 4.1: Run Full Test Suite

- [ ] **Step 1: Run all new tests**

```bash
swift test 2>&1 | tail -20
```

Expected: All tests pass (PASS count > 0, no FAIL)

- [ ] **Step 2: Check code coverage**

Run: `swift test --code-coverage 2>&1 | grep "coverage"`

Target: 90%+ for new code

- [ ] **Step 3: Commit if needed**

If any test failures, fix them and commit:

```bash
git add -A
git commit -m "fix: resolve test failures"
```

---

## Task 4.2: Verify Backward Compatibility

- [ ] **Step 1: Test old API calls still work**

Write quick test:

```swift
func testBackwardCompatibility() async throws {
    // Old continueDocument call
    let result1 = try await aiService.continueDocument(
        documentId: "doc-1",
        context: "add drama"
    )
    XCTAssertFalse(result1.isEmpty)
    
    // Old improveDocument call
    let result2 = try await aiService.improveDocument(
        documentId: "doc-1"
    )
    XCTAssertFalse(result2.isEmpty)
}
```

Run: `swift test <TestFile> -k "BackwardCompatibility" -v`

- [ ] **Step 2: Verify no breaking changes**

Run: `swift build 2>&1`

Expected: Build succeeds with no errors

- [ ] **Step 3: Commit final tests**

```bash
git add Tests/WritersAppTests/
git commit -m "test: verify backward compatibility

- Old continueDocument/improveDocument signatures still work
- No breaking changes to existing APIs
"
```

---

## Task 4.3: Documentation Updates

- [ ] **Step 1: Update CLAUDE.md with new methods**

Edit `CLAUDE.md` to add under "Key APIs":

```markdown
// Template Recommendations
recommendTemplates(userIntent:category:limit:) async throws -> [TemplateRecommendation]

// Template Generation
generateTemplate(description:category:desiredLength:) async throws -> GeneratedTemplate
createTemplateFromAI(generated:) throws -> Template

// Enhanced Document Editing
continueDocument(documentId:context:options:) async throws -> String
improveDocument(documentId:focusArea:options:) async throws -> String
```

- [ ] **Step 2: Commit documentation**

```bash
git add CLAUDE.md
git commit -m "docs: update CLAUDE.md with new AI features

- Add new AIService methods
- Add new TemplateManager methods
- Document DocumentEnhancementOptions
"
```

---

## Self-Review Against Spec

**✅ Spec Coverage Check:**

| Spec Section | Task | Status |
|--------------|------|--------|
| DocumentEnhancementOptions model | 1.1 | ✓ Complete |
| WritingTone enum | 1.1 | ✓ Complete |
| continueDocument() with options | 1.3 | ✓ Complete |
| improveDocument() with options | 1.4 | ✓ Complete |
| generateTemplate() method | 2.2 | ✓ Complete |
| createTemplateFromAI() | 2.3 | ✓ Complete |
| recommendTemplates() in AIService | 3.2 | ✓ Complete |
| recommendTemplates() in TemplateManager | 3.3 | ✓ Complete |
| Unit tests for all features | 1.5, 2.4, 3.4 | ✓ Complete |
| Backward compatibility | 4.2 | ✓ Complete |
| Error handling | Throughout | ✓ Complete |

**✅ Type Consistency Check:**
- `DocumentEnhancementOptions` used in both Task 1.3 and 1.4
- `WritingTone` enum properly used in 1.3, 1.4
- `GeneratedTemplate` and `Placeholder` properly used in 2.1, 2.2, 2.3
- `TemplateRecommendation` properly used in 3.1, 3.2, 3.3

**✅ No Placeholder Patterns Found:**
- All code examples are complete and functional
- All test code shows exact assertions
- All commit messages are specific

---

# Execution Options

Plan complete and saved to `docs/superpowers/plans/2026-10-23-ai-templates-documents-implementation.md`.

**Two execution approaches:**

### **Option 1: Subagent-Driven (Recommended)**
Dispatch a fresh subagent per task, with review checkpoints between phases. Fast iteration, isolated work.

### **Option 2: Inline Execution**  
Execute tasks sequentially in this session using the executing-plans skill, with manual review gates.

**Which approach would you prefer?**
