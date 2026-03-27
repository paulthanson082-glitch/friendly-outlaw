# Hallucination Reduction Guide

This guide explains how to use hallucination-reducing techniques in the friendly-outlaw writers app to minimize factually incorrect or inconsistent outputs from Claude.

## Overview

Even advanced language models like Claude can sometimes generate "hallucinations" — text that is factually incorrect or inconsistent with the given context. The WritersApp provides built-in methods to minimize these hallucinations using proven techniques from prompt engineering.

## Hallucination-Reducing Techniques

### 1. Allow Claude to Say "I Don't Know" (Uncertainty Admission)

**Problem:** Claude often generates plausible-sounding but incorrect information rather than admitting uncertainty.

**Solution:** Explicitly give Claude permission to admit when it lacks information. This drastically reduces false information.

#### Method: `analyzeWithUncertainty()`

```swift
let app = WritersApp(aiConfiguration: config)

// Analyze a document while allowing uncertainty admission
let analysis = try await app.analyzeDocumentWithUncertainty(
    documentId: document.id,
    context: AIContext(
        genre: "technical documentation",
        targetAudience: "software engineers"
    )
)

// The response includes explicit uncertainty areas
print("Analysis: \(analysis.analysis)")
print("Confident areas: \(analysis.confidenceAreas)")
print("Uncertain areas: \(analysis.uncertainAreas)")
print("Information gaps: \(analysis.informationGaps)")
```

**Key Benefits:**
- Claude explicitly acknowledges what it doesn't know
- Clear separation of confident vs. uncertain claims
- Identifies missing information needed for complete analysis

---

### 2. Use Direct Quotes for Factual Grounding

**Problem:** When analyzing long documents, Claude may paraphrase and introduce errors. Direct quotes keep Claude grounded in the actual text.

**Solution:** Ask Claude to extract word-for-word quotes first before performing analysis. This grounds responses in concrete text.

#### Method: `extractQuotesFromDocument()`

```swift
let app = WritersApp(aiConfiguration: config)

// Extract relevant quotes from a document
let quotes = try await app.extractQuotesFromDocument(
    documentId: document.id,
    context: AIContext(
        genre: "research paper",
        additionalNotes: "Focus on methodology and findings"
    )
)

// Use quotes as a foundation for further analysis
for quote in quotes {
    print("Quote: \(quote.text)")
    print("Reference: \(quote.reference ?? "Unknown")")
    print("Relevance: \(quote.relevanceExplanation)")
}
```

**Key Benefits:**
- Exact text from the source document
- Explicit connection between claim and supporting evidence
- Reduces paraphrasing errors

---

### 3. Verify with Citations

**Problem:** Claude may make unsupported claims or forget that statements need justification.

**Solution:** Require Claude to find supporting evidence from the provided material for each claim. If it can't find evidence, it must acknowledge this.

#### Method: `verifyDocumentWithCitations()`

```swift
let app = WritersApp(aiConfiguration: config)

// Verify all claims in a document with citations
let verifiedClaims = try await app.verifyDocumentWithCitations(
    documentId: document.id
)

// Review verified vs. unverified claims
for claim in verifiedClaims {
    if claim.isVerified {
        print("✓ Verified: \(claim.claim)")
        print("  Evidence: \(claim.evidence)")
        if let quote = claim.supportingQuote {
            print("  Quote: \(quote)")
        }
    } else {
        print("✗ Unverified: \(claim.claim)")
        if let uncertainty = claim.uncertaintyNote {
            print("  Note: \(uncertainty)")
        }
    }
}
```

**Key Benefits:**
- Every claim has explicit supporting evidence or an acknowledgment
- Auditable trail of reasoning
- Prevents unsupported assertions

---

### 4. Chain-of-Thought Verification

**Problem:** Claude may leap to conclusions without showing intermediate steps, hiding faulty reasoning.

**Solution:** Ask Claude to explain its reasoning step-by-step, identifying assumptions and uncertainties at each stage.

#### Method: `chainOfThoughtAnalysis()`

```swift
let app = WritersApp(aiConfiguration: config)

// Perform step-by-step analysis with explicit reasoning
let analysis = try await app.chainOfThoughtAnalysis(
    documentId: document.id,
    context: AIContext(
        genre: "academic paper",
        additionalNotes: "Analyze argument validity"
    )
)

// Review the reasoning process
print("Reasoning: \(analysis.reasoning)")
for (index, step) in analysis.steps.enumerated() {
    print("\nStep \(index + 1): \(step.claim)")
    print("Reasoning: \(step.reasoning)")
    print("Assumptions: \(step.assumptions)")
    if let uncertainty = step.uncertainty {
        print("Uncertainty: \(uncertainty)")
    }
}

print("\nConclusion: \(analysis.conclusion)")
print("Overall assumptions: \(analysis.assumptions)")
print("Overall uncertainties: \(analysis.uncertainties)")
```

**Key Benefits:**
- Visible reasoning process makes flaws easier to spot
- Explicit assumptions can be challenged or verified
- Uncertainties are identified at each step
- Easier to catch hallucinations in intermediate steps

---

## Combining Techniques

For highest reliability, you can combine multiple techniques:

```swift
// Example: Comprehensive analysis with multiple verification layers
let app = WritersApp(aiConfiguration: config)

// Step 1: Extract quotes for grounding
let quotes = try await app.extractQuotesFromDocument(documentId: doc.id)

// Step 2: Verify claims with citations
let verifiedClaims = try await app.verifyDocumentWithCitations(documentId: doc.id)

// Step 3: Analyze while admitting uncertainty
let uncertaintyAnalysis = try await app.analyzeDocumentWithUncertainty(documentId: doc.id)

// Step 4: Get step-by-step reasoning
let chainOfThought = try await app.chainOfThoughtAnalysis(documentId: doc.id)

// Combine all perspectives for a comprehensive review
print("Foundation: \(quotes.count) key quotes identified")
print("Claims: \(verifiedClaims.count) claims reviewed, " +
      "\(verifiedClaims.filter { $0.isVerified }.count) verified")
print("Confidence: \(uncertaintyAnalysis.confidenceAreas.count) confident areas, " +
      "\(uncertaintyAnalysis.uncertainAreas.count) uncertain areas")
print("Reasoning: \(chainOfThought.steps.count) step analysis")
```

## Best Practices

### 1. **Use the Right Technique for Your Task**

| Task | Recommended Technique |
|------|----------------------|
| Fact-checking | Extract Quotes + Verify with Citations |
| Opinion analysis | Allow Uncertainty |
| Academic evaluation | Chain-of-Thought Verification |
| Content summarization | Extract Quotes |
| Complex reasoning | Combine all four |

### 2. **Always Validate Critical Information**

While these techniques significantly reduce hallucinations, they don't eliminate them. For high-stakes decisions:
- Cross-reference with original sources
- Have multiple perspectives review
- Verify citations manually
- Acknowledge remaining uncertainties

### 3. **Provide Sufficient Context**

Better context = fewer hallucinations:

```swift
let context = AIContext(
    genre: "technical documentation",
    targetAudience: "system administrators",
    plotSummary: nil,
    additionalNotes: "Focus on security implications. " +
                     "User has 10 years experience."
)
```

### 4. **Use for Long Documents (>20k tokens)**

These techniques are especially valuable for:
- Legal documents
- Academic papers
- Technical specifications
- Research reports
- Multi-chapter books

For short texts, simpler approaches may suffice.

## API Reference

### Document-Based Methods

```swift
// Extract quotes from a document
public func extractQuotesFromDocument(
    documentId: UUID,
    context: AIContext? = nil
) async throws -> [QuoteBlock]

// Verify document claims with citations
public func verifyDocumentWithCitations(
    documentId: UUID,
    context: AIContext? = nil
) async throws -> [VerifiedClaim]

// Analyze document with uncertainty admission
public func analyzeDocumentWithUncertainty(
    documentId: UUID,
    context: AIContext? = nil
) async throws -> UncertaintyAwareAnalysis

// Chain-of-thought analysis for document
public func chainOfThoughtAnalysis(
    documentId: UUID,
    context: AIContext? = nil
) async throws -> ChainOfThoughtAnalysis
```

### Text-Based Methods

These work with arbitrary text (non-document):

```swift
public func extractQuotesFromText(
    text: String,
    context: AIContext? = nil
) async throws -> [QuoteBlock]

public func verifyTextWithCitations(
    text: String,
    context: AIContext? = nil
) async throws -> [VerifiedClaim]

public func analyzeTextWithUncertainty(
    text: String,
    context: AIContext? = nil
) async throws -> UncertaintyAwareAnalysis

public func chainOfThoughtAnalysisForText(
    text: String,
    context: AIContext? = nil
) async throws -> ChainOfThoughtAnalysis
```

## Return Types

### QuoteBlock
```swift
public struct QuoteBlock: Codable {
    public let text: String                    // Exact quote
    public let reference: String?              // Page/section reference
    public let relevanceExplanation: String    // Why this quote matters
}
```

### VerifiedClaim
```swift
public struct VerifiedClaim: Codable {
    public let claim: String                   // The claim being verified
    public let supportingQuote: String?        // Exact supporting text
    public let evidence: String                // Description of evidence
    public let isVerified: Bool                // Whether verified from source
    public let uncertaintyNote: String?        // If unverified, why
}
```

### UncertaintyAwareAnalysis
```swift
public struct UncertaintyAwareAnalysis: Codable {
    public let analysis: String                // Main analysis
    public let confidenceAreas: [String]       // Areas of confidence
    public let uncertainAreas: [String]        // Areas of uncertainty
    public let informationGaps: [String]       // Missing information
}
```

### ChainOfThoughtAnalysis
```swift
public struct ChainOfThoughtAnalysis: Codable {
    public let reasoning: String               // Overall reasoning
    public let steps: [ReasoningStep]          // Individual steps
    public let assumptions: [String]           // Assumptions made
    public let uncertainties: [String]         // Uncertainties identified
    public let conclusion: String              // Final conclusion
}

public struct ReasoningStep: Codable {
    public let claim: String                   // Claim in this step
    public let reasoning: String               // Why/how we arrived at this
    public let assumptions: [String]           // Assumptions for this step
    public let uncertainty: String?            // Uncertainty in this step
}
```

## Examples

### Example 1: Fact-Checking a News Article

```swift
let article = app.createBlankDocument(
    title: "Breaking: Tech Company Announces New Product",
    category: .article
)
// ... add article content ...

// Extract key claims as quotes
let quotes = try await app.extractQuotesFromDocument(documentId: article.id)

// Verify each claim
let verified = try await app.verifyDocumentWithCitations(documentId: article.id)

// Report
for claim in verified {
    if !claim.isVerified {
        print("⚠️ Unverified claim: \(claim.claim)")
    }
}
```

### Example 2: Academic Paper Review

```swift
let paper = app.createBlankDocument(
    title: "Research on Machine Learning Ethics",
    category: .article
)
// ... add paper content ...

// Analyze with step-by-step reasoning
let analysis = try await app.chainOfThoughtAnalysis(documentId: paper.id)

print("Argument structure:")
for (i, step) in analysis.steps.enumerated() {
    print("\(i+1). \(step.claim)")
    print("   Based on: \(step.assumptions)")
    if let uncertainty = step.uncertainty {
        print("   ⚠️ \(uncertainty)")
    }
}
```

### Example 3: Technical Documentation Review

```swift
let docs = app.createBlankDocument(
    title: "API Documentation v2.1",
    category: .article
)
// ... add documentation ...

let context = AIContext(
    genre: "technical documentation",
    targetAudience: "API developers",
    additionalNotes: "Check for accuracy of code examples"
)

// Get uncertainty-aware analysis
let analysis = try await app.analyzeDocumentWithUncertainty(
    documentId: docs.id,
    context: context
)

print("✓ Can confidently state: \(analysis.confidenceAreas)")
print("? Uncertain about: \(analysis.uncertainAreas)")
print("⚠️ Need more information on: \(analysis.informationGaps)")
```

## References

- Original guide: "Hallucination Reduction in Large Language Models"
- Technique papers:
  - "Chain-of-Thought Prompting Elicits Reasoning in Large Language Models" (Wei et al., 2022)
  - "Least-to-Most Prompting Enables Complex Reasoning in Large Language Models" (Zhou et al., 2022)
  - "Self-Consistency Improves Chain of Thought Reasoning in Language Models" (Wang et al., 2022)

## Feedback & Issues

For bugs or feature requests related to hallucination reduction, report to: https://github.com/anthropics/claude-code/issues
