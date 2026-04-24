---
name: smart-explore
description: Token-optimized structural code search using tree-sitter AST parsing. Use instead of reading full files when you need to understand code structure, find functions, or explore a codebase efficiently.
tools: Bash, Grep, Glob, Read
model: haiku
---

# Smart Explore

Structural code exploration using AST parsing. Simple workflow: search -> outline -> unfold.

## When to Use

Use when you need to understand code without reading full files:

- "How does shutdown work?" -- cross-cutting exploration
- "What's in worker-service.ts?" -- file structure understanding
- "Show me the startSessionProcessor method" -- targeted implementation
- Exploring unfamiliar areas of a codebase
- Replacing multi-round Grep-Read-Grep-Read exploration cycles

**Do NOT use for:**

- Exact name lookups ("where is `ensureWorkerStarted` defined?") -- use Grep
- String literal search ("find all TODO comments") -- use Grep
- Small files under ~100 lines -- use Read directly
- File path search ("find all test files") -- use Glob
- Non-code files, config files, JSON, markdown -- use Read directly

## 3-Layer Workflow (ALWAYS Follow)

**NEVER read a full file when smart_outline + smart_unfold achieves the same understanding at 8x fewer tokens.**

### Step 1: Search -- Find Relevant Symbols

Use the `smart_search` tool:

```
smart_search(query="shutdown", path="./src", max_results=15)
```

**Returns:** Ranked symbols with signatures, line numbers, match reasons, plus folded file views (~2-6k tokens)

### Step 2: Outline -- Get File Structure

Use `smart_outline` when you need deeper structural context for a specific file:

```
smart_outline(file_path="services/worker-service.ts")
```

**Returns:** Complete structural skeleton -- all functions, classes, methods, properties, imports (~1-2k tokens per file)

### Step 3: Unfold -- See Implementation

Review symbols from Steps 1-2. Pick the ones you need. Unfold only those:

```
smart_unfold(file_path="services/worker-service.ts", symbol_name="shutdown")
```

**Returns:** Full source code of the specified symbol (~1-7k tokens depending on symbol size)

## Token Economics

| Approach | Tokens | Use Case |
|----------|--------|----------|
| smart_outline | ~1,500 | "What's in this file?" |
| smart_unfold | ~1,600 | "Show me this function" |
| smart_search | ~2,000-6,000 | "How does X work?" |
| Read (full file) | ~12,000+ | When you truly need everything |
| Explore agent | ~20,000-40,000 | Same as smart_search, 6-12x more expensive |

- **8x token savings** on file understanding via outline + unfold vs Read
- **6-12x token savings** on exploration vs Explore agent
