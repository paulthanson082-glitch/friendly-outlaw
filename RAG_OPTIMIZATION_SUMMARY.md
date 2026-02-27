# RAG Optimization Strategy - Executive Summary

## Current State vs. Target State

```
┌─────────────────────────────────────────────────────────────────┐
│                   PERFORMANCE COMPARISON                        │
├─────────────────────────────────────────────────────────────────┤
│                        Current │ Phase 1 │ Phase 2 │ Phase 3    │
│ E2E Accuracy                72% │   78%   │   84%   │   88%     │
│ Retrieval Precision        42.8% │   55%   │   60%   │   65%    │
│ Retrieval Recall           65.9% │   72%   │   78%   │   82%    │
│ Retrieval MRR              73.7% │   76%   │   82%   │   85%    │
│ Questions with 0% E2E        31  │   18    │    8    │    4     │
├─────────────────────────────────────────────────────────────────┤
│ Total Improvement                  +16 pts accuracy by Phase 3  │
│ User Experience          "70% works" → "88% works consistently" │
└─────────────────────────────────────────────────────────────────┘
```

---

## Problem Summary

### The Core Issues

| Issue | Severity | Count | Impact |
|-------|----------|-------|--------|
| **Low Precision** | 🔴 Critical | 60 questions | Noise in context fed to Claude |
| **Perfect Retrieval → Failed Response** | 🔴 Critical | 10 questions | Wasted perfect retrieval |
| **Complete Retrieval Failure** | 🔴 Critical | 11 questions | 0% recall on these |
| **Partial Retrieval Failure** | 🟡 High | 10 questions | Missing crucial chunks |
| **Poor Ranking** | 🟡 High | 24 questions | Relevant chunks buried |

### Why It's Happening

```
┌─────────────────────────────────────────────────────────────┐
│ ROOT CAUSE ANALYSIS                                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ RETRIEVAL LAYER                                             │
│ ├─ Problem: Keyword overlap without semantic understanding │
│ ├─ Cause: Simple BM25-style matching                      │
│ └─ Effect: 60% of retrieved chunks are irrelevant         │
│                                                             │
│ QUERY LAYER                                                 │
│ ├─ Problem: Query vocabulary doesn't match corpus          │
│ ├─ Cause: No synonym/acronym expansion                     │
│ └─ Effect: 11 questions have 0% retrieval                  │
│                                                             │
│ RANKING LAYER                                               │
│ ├─ Problem: Relevant chunks ranked too low               │
│ ├─ Cause: Surface-level IR score, no semantic ranking     │
│ └─ Effect: 24 questions have low MRR                       │
│                                                             │
│ RESPONSE LAYER                                              │
│ ├─ Problem: Claude can't synthesize multi-doc context     │
│ ├─ Cause: No multi-document synthesis instructions        │
│ └─ Effect: 10 questions fail despite perfect retrieval    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Three-Phase Optimization Plan

### 🚀 PHASE 1: Quick Wins (Week 1, ~5 hours, +6% accuracy)

**Goal**: Fix the most obvious problems with minimal effort

| # | Task | Time | Impact | Difficulty |
|---|------|------|--------|-----------|
| 1.1 | Add multi-document synthesis prompt | 1h | Fixes 10 "perfect retrieval, failed response" cases | ⭐ Easy |
| 1.2 | Implement semantic re-ranking via Claude | 2h | Improves precision 42% → 55% | ⭐ Easy |
| 1.3 | Add few-shot examples for document Q&A | 0.5h | +2% accuracy through better citations | ⭐ Easy |
| 1.4 | Create query expansion with synonyms | 1.5h | Improves recall 65% → 72% | ⭐⭐ Medium |

**Expected Outcome**: 72% → **78% accuracy** | 42.8% → **55% precision**

---

### 🎯 PHASE 2: Core Improvements (Week 2, ~6 hours, +6% accuracy)

**Goal**: Fix structural issues in chunking and summarization

| # | Task | Time | Impact | Difficulty |
|---|------|------|--------|-----------|
| 2.1 | Implement semantic chunking by sections | 3-4h | Preserves document structure | ⭐⭐ Medium |
| 2.2 | Add chunk context headers | 1h | Improves ranking by providing context | ⭐ Easy |
| 2.3 | Create query-aware summary generator | 2h | +10% re-ranking effectiveness | ⭐⭐ Medium |

**Expected Outcome**: 78% → **84% accuracy** | 55% → **60% precision**

---

### 🏆 PHASE 3: Advanced Optimization (Week 3+, ~6 hours, +4% accuracy)

**Goal**: Implement sophisticated retrieval strategies

| # | Task | Time | Impact | Difficulty |
|---|------|------|--------|-----------|
| 3.1 | Query classification (factual/conceptual/procedural) | 3-4h | Adaptive retrieval strategies | ⭐⭐⭐ Hard |
| 3.2 | Continuous evaluation harness | 2h | Monitor metrics as changes roll out | ⭐⭐ Medium |

**Expected Outcome**: 84% → **88% accuracy** | 60% → **65% precision**

---

## Quick Implementation Wins

### Immediate Actions (Implement Today)

#### Action 1: Multi-Document Synthesis Prompt
```swift
// Add to RAGService.rankResults()
let synthesisPrompt = """
You have multiple relevant document excerpts. Synthesize them to answer:

\(userQuery)

Remember:
1. Cite which section answers each part
2. If sections contradict, note this
3. If no section covers something, say so explicitly

Sections:
\(rankedChunks.enumerated().map {
  "Section \($0.offset + 1): \($0.element.summary.summaryText)"
}.joined(separator: "\n"))

Answer:
"""
```
**Expected Impact**: +10 questions fixed (perfect retrieval → success)

#### Action 2: Semantic Re-Ranking
```swift
// Replace simple scoring with Claude-based ranking
func semanticScore(chunk: DocumentChunk, query: String) async throws -> Double {
    let scorePrompt = """
    Rate how well this chunk answers the question (0-10 scale):

    Question: \(query)

    Chunk: \(chunk.content)

    Score (just the number):
    """
    let scoreStr = try await aiService.getAssistance(scorePrompt)
    if let score = Double(scoreStr.trimmingCharacters(in: .whitespaces)) {
        return score / 10.0  // Normalize to 0-1
    }
    return 0.0
}
```
**Expected Impact**: +6 questions fixed (low precision → medium precision)

#### Action 3: Query Expansion
```swift
// Before retrieval, expand the query
func expandQuery(_ query: String) async throws -> String {
    let expansionPrompt = """
    Expand this query with synonyms and definitions.

    Original: \(query)

    Return: original, synonym1, synonym2, acronym_expansion1, ...
    """
    return try await aiService.getAssistance(expansionPrompt)
}

// Usage:
let expanded = try await expandQuery("How to use CoT?")
// Returns: "How to use CoT, chain-of-thought, COT, chain of thought reasoning"
let chunks = try await retrieveChunks(expanded, limit: 20)
```
**Expected Impact**: +5 questions fixed (0% recall → positive recall)

---

## Question-Specific Fixes

### Priority 1: Perfect Retrieval, Failed Response (Implement Now!)
```
⚠️ These 10 questions have ALL relevant chunks but still fail:

1. "When deciding whether to use chain-of-thought (CoT)..."
   → Precision: 67%, Recall: 100%, MRR: 100%, E2E: 0%
   → Fix: Add synthesis prompt + few-shot examples

2. "According to the documentation, where can you view..."
   → Precision: 67%, Recall: 100%, MRR: 100%, E2E: 0%
   → Fix: Add synthesis prompt + few-shot examples
```

**Fix Strategy**: These are pure prompt engineering problems. No retrieval needed.

### Priority 2: Zero Retrieval (Implement in Phase 1)
```
⚠️ These 11 questions have ZERO matching chunks:

1. "How can we measure the performance of the ticket classification..."
   → Precision: 0%, Recall: 0%, MRR: 0%, E2E: 0%
   → Fix: Query expansion + synonym matching

2. "How can you combine XML tags with chain of thought..."
   → Precision: 0%, Recall: 0%, MRR: 0%, E2E: 0%
   → Fix: Query expansion + acronym expansion (CoT → chain-of-thought)
```

**Fix Strategy**: Expand queries before retrieval to capture more documents.

### Priority 3: Partial Retrieval (Implement in Phase 1-2)
```
⚠️ These 10 questions find ~50% of relevant chunks:

1. "How can you create multiple test cases for an evaluation..."
   → Precision: 33%, Recall: 50%, MRR: 50%, E2E: 0%
   → Fix: Semantic re-ranking + query expansion
```

**Fix Strategy**: Combine semantic re-ranking with query expansion.

---

## Implementation Roadmap

```
┌──────────────────────────────────────────────────────────────┐
│                    WEEK 1: QUICK WINS                        │
├──────────────────────────────────────────────────────────────┤
│ Mon  │ Implement synthesis prompt (1h)                        │
│ Tue  │ Implement semantic re-ranking (2h)                     │
│ Wed  │ Add few-shot examples (0.5h) + query expansion (1.5h)  │
│ Thu  │ Test Phase 1 changes on full 100-question set          │
│ Fri  │ Measure improvements, document results                 │
│      │ Expected: 72% → 78% accuracy                           │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│                   WEEK 2: CORE IMPROVEMENTS                  │
├──────────────────────────────────────────────────────────────┤
│ Mon  │ Implement semantic chunking algorithm (3-4h)           │
│ Tue  │ Add chunk context headers (1h)                         │
│ Wed  │ Create query-aware summary generator (2h)              │
│ Thu  │ Integration testing with semantic chunking             │
│ Fri  │ Measure improvements, document results                 │
│      │ Expected: 78% → 84% accuracy                           │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│                 WEEK 3+: ADVANCED OPTIMIZATION                │
├──────────────────────────────────────────────────────────────┤
│ Mon  │ Design query classification system                     │
│ Tue-Thu │ Implement adaptive retrieval strategies (3-4h)      │
│ Fri  │ Continuous evaluation harness (2h)                     │
│      │ Expected: 84% → 88% accuracy                           │
└──────────────────────────────────────────────────────────────┘
```

---

## Success Criteria

### Phase 1 Success ✓
- [ ] 10 "perfect retrieval, failed response" cases fixed
- [ ] Precision improved to 55%+ on sample of 20 questions
- [ ] Zero-retrieval questions now have >20% recall
- [ ] E2E accuracy measured at 78%+

### Phase 2 Success ✓
- [ ] Semantic chunking reduces token overhead by 15%
- [ ] MRR improved to 82%+
- [ ] All critical failures reduced from 31 to ≤8
- [ ] E2E accuracy measured at 84%+

### Phase 3 Success ✓
- [ ] Adaptive retrieval improves precision to 65%+
- [ ] Query classification covers 90%+ of question types
- [ ] Continuous evaluation dashboard operational
- [ ] E2E accuracy measured at 88%+

---

## Key Files to Modify

### Phase 1
- `Sources/WritersApp/Services/RAGService.swift` — Add synthesis prompt, semantic re-ranking, query expansion
- `Tests/WritersAppTests/WritersAppTests.swift` — Add tests for new retrieval strategies

### Phase 2
- `Sources/WritersApp/Services/RAGService.swift` — Add semantic chunking
- `Sources/WritersApp/Models/RAGModels.swift` — Update chunk structure with context headers

### Phase 3
- `Sources/WritersApp/Services/RAGService.swift` — Add query classification and adaptive strategies
- New file: `Sources/WritersApp/Services/RAGEvaluationService.swift` — Evaluation harness

---

## Risk Assessment

| Phase | Risk Level | Mitigation |
|-------|-----------|-----------|
| Phase 1 | 🟢 Low | Prompt-based changes only, easily reversible |
| Phase 2 | 🟡 Medium | Chunking changes affect retrieval; test thoroughly |
| Phase 3 | 🟡 Medium | Query classification may over-specialize; need fallback |

---

## Next Steps

1. **Review this report** with team
2. **Approve Phase 1 work** (quick wins)
3. **Start implementation** immediately
4. **Measure baseline** (current 72% accuracy)
5. **Implement Phase 1** (target 78% accuracy)
6. **Evaluate results** before Phase 2

---

## Questions?

Refer to `RAG_OPTIMIZATION_REPORT.md` for detailed analysis of each failure pattern.
