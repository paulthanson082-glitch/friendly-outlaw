# /pm:prd-parse — Transform a PRD into a technical epic with task breakdown

You are a technical architect and project planner. Your job is to read a PRD and decompose it into an actionable epic with individual task files.

**Feature**: $ARGUMENTS

## Process

### Step 1: Read the PRD

Read the PRD file at `.claude/prds/$ARGUMENTS.md`. If it doesn't exist, tell the user and suggest running `/pm:prd-new $ARGUMENTS` first.

### Step 2: Analyze the codebase

Before planning, understand the current codebase:
- Read `CLAUDE.md` for project conventions and architecture
- Explore relevant source files to understand current patterns
- Identify where new code would fit in the existing architecture
- Note any existing code that could be reused or extended

### Step 3: Create the epic directory

Create the directory `.claude/epics/$ARGUMENTS/` and `.claude/epics/$ARGUMENTS/updates/`.

### Step 4: Write the epic plan

Create `.claude/epics/$ARGUMENTS/epic.md` with this structure:

```markdown
# Epic: [Feature Name]

**PRD**: .claude/prds/$ARGUMENTS.md
**Status**: Planning
**Created**: [Today's Date]

## Overview
[1-2 paragraph technical summary of the implementation approach]

## Architecture Decisions
- [Key technical decisions and rationale]

## Task Breakdown

| # | Task | Description | Estimate | Dependencies |
|---|------|-------------|----------|--------------|
| 1 | [title] | [brief description] | S/M/L | - |
| 2 | [title] | [brief description] | S/M/L | #1 |
...

## Dependency Graph
[Show which tasks can run in parallel vs which have dependencies]

## Risk Assessment
- [Potential risks and mitigations]

## Files to Modify
- [List of existing files that will be modified]
- [List of new files that will be created]
```

### Step 5: Create individual task files

For each task in the breakdown, create `.claude/epics/$ARGUMENTS/[#].md`:

```markdown
# Task [#]: [Title]

**Epic**: $ARGUMENTS
**Status**: pending
**Estimate**: S/M/L
**Dependencies**: [list or "none"]

## Objective
[Clear statement of what this task accomplishes]

## Requirements
- [ ] Requirement from PRD this addresses

## Implementation Details
[Specific technical guidance:]
- Files to create/modify
- Functions/methods to add
- Patterns to follow (reference existing code)
- Edge cases to handle

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2

## Testing
- [ ] Test case 1
- [ ] Test case 2
```

### Step 6: Sizing guidelines

Use these estimates:
- **S (Small)**: < 30 min, single file change, straightforward
- **M (Medium)**: 30-90 min, multiple files, some complexity
- **L (Large)**: 90+ min, architectural changes, significant complexity

### Step 7: Summary

Display the full task table and dependency graph. Tell the user:
- Total tasks and size breakdown
- Which tasks can run in parallel
- Suggest next steps:
  - `/pm:epic-oneshot $ARGUMENTS` to create GitHub issues for all tasks at once
  - Or review/edit individual task files first in `.claude/epics/$ARGUMENTS/`
