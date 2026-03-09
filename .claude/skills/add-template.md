---
name: add-template
description: Add a new writing template to the friendly-outlaw app. Invoke when asked to create or add a template (e.g. "add a screenplay template", "create a new blog post template").
---

# Add a New Writing Template

Follow these steps to add a new writing template to the app.

## Step 1 — Decide the template properties

Collect:
- **Title**: human-readable name (e.g. "Mystery Novel")
- **Category**: one of `TemplateCategory` cases — `novel`, `shortStory`, `screenplay`, `blogPost`, `article`, `essay`, `poetry`, `businessLetter`, `proposal`, `resume`, `other`
- **Description**: one sentence describing the template
- **Content**: the full template body using `{{placeholder_key}}` syntax for variable parts
- **Placeholders**: list each key, its display label, and whether it is required

Placeholder rules:
- Keys must be `{{snake_case}}`
- Aim for 3–7 placeholders per template (not too few to be generic, not too many to be tedious)
- Mark truly optional sections with `isRequired: false`

## Step 2 — Edit TemplateManager.swift

File: `Sources/WritersApp/Services/TemplateManager.swift`

Inside `loadDefaultTemplates()`, append a new `Template(...)` initialiser following the existing pattern:

```swift
templates.append(Template(
    title: "<Title>",
    content: """
        <template body with {{placeholders}}>
        """,
    category: .<category>,
    description: "<one-sentence description>",
    placeholders: [
        Placeholder(key: "<key>", displayName: "<Label>", isRequired: true),
        // ... more placeholders
    ]
))
```

## Step 3 — Verify placeholder substitution

Run a quick mental check: every `{{key}}` in `content` must have a matching `Placeholder` entry with the same `key`. Mismatches cause silent no-ops at runtime.

## Step 4 — Run the test suite

```bash
swift test
```

All existing tests must continue to pass. If you added a template that changes the count returned by `getAllTemplates()`, update the assertion in `WritersAppTests.swift`.

## Step 5 — Use the template-designer agent for complex templates

If the template is long or the placeholder design is unclear, delegate to the `template-designer` subagent first, then apply its output here.
