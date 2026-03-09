---
name: add-ai-feature
description: Implement a new AI-powered writing feature in the friendly-outlaw app. Invoke when asked to add or extend an AI capability (e.g. "add a chapter outline generator", "add a tone changer AI feature").
---

# Add a New AI Feature

Follow these steps to add a new AI-assisted writing capability.

## Step 1 — Consult the knowledge advisor

Before writing any code, call the `knowledge-advisor` subagent:

> "I am about to add an AI feature: <brief description>. What standards apply?"

This returns the mandatory rules from `swift.json`, `architecture.json`, `security.json`, and `testing.json`.

## Step 2 — Add the assistance type (if needed)

File: `Sources/WritersApp/Models/AIModels.swift`

If the feature represents a new _kind_ of assistance, add a case to `AIAssistanceType`:

```swift
// Simple case
case myNewFeature

// Parameterised case (only if the variant drives a meaningfully different prompt)
case changeTone(WritingTone)
```

Use `custom(String)` for one-off requests rather than adding a permanent case.

## Step 3 — Implement the method on AIService

File: `Sources/WritersApp/Services/AIService.swift`

Add a focused `async throws` method following the service pattern:

```swift
/// One-sentence description of what this method does.
public func myNewFeature(text: String, context: String? = nil) async throws -> <ReturnType> {
    let systemPrompt = """
        <Concise system instruction for Claude. No hardcoded keys or secrets.>
        """

    let userContent = context.map { "\($0)\n\n\(text)" } ?? text

    let response = try await sendMessage(
        systemPrompt: systemPrompt,
        userContent: userContent
    )
    return response  // or parse into a typed result
}
```

Rules:
- Method must be `public` and `async throws`
- Use `AIServiceError` for typed error propagation
- Never hardcode the API key — it comes from `AIConfiguration`
- Only `AIService` makes network calls (no network in managers or models)
- Include the `anthropic-version: 2023-06-01` header (handled by `sendMessage`)

## Step 4 — Expose on WritersApp facade (if user-facing)

File: `Sources/WritersApp/WritersApp.swift`

Add a public convenience method that guards on `isAIEnabled` and delegates to `aiService`:

```swift
public func myNewFeature(documentId: UUID, context: String? = nil) async throws -> <ReturnType> {
    guard isAIEnabled, let aiService else { throw AIError.aiNotEnabled }
    guard let document = documentManager.getDocument(id: documentId) else {
        throw AIError.documentNotFound
    }
    return try await aiService.myNewFeature(text: document.content, context: context)
}
```

## Step 5 — Add a CLI option (optional)

File: `Sources/WritersAppCLI/main.swift`

If the feature should be reachable from the interactive CLI, add a numbered menu option in the AI assistance section and wire it to the new facade method.

## Step 6 — Write tests

File: `Tests/WritersAppTests/WritersAppTests.swift`

Add a test following the project convention (no live API calls — test that the method throws `AIError.aiNotEnabled` when AI is disabled, and test any synchronous parsing logic):

```swift
func testMyNewFeatureThrowsWhenAIDisabled() async throws {
    let app = WritersApp()
    let doc = app.createBlankDocument(title: "Test", category: .article)
    do {
        _ = try await app.myNewFeature(documentId: doc.id)
        XCTFail("Expected AIError.aiNotEnabled")
    } catch AIError.aiNotEnabled {
        // expected
    }
}
```

## Step 7 — Run the full test suite

```bash
swift test
```

Use the `test-runner` subagent if you want a concise pass/fail report.

## Step 8 — Run the code reviewer

Use the `swift-code-reviewer` subagent on any modified `.swift` files to catch style issues before committing.
