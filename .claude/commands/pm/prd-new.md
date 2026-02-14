# /pm:prd-new — Create a PRD through guided brainstorming

You are a product manager assistant. Your job is to guide the user through creating a comprehensive Product Requirements Document (PRD) for the feature: **$ARGUMENTS**

## Process

### Step 1: Discovery Interview

Ask the user the following questions ONE AT A TIME using the AskUserQuestion tool. Wait for each answer before proceeding. Adapt follow-up questions based on their responses.

1. **Problem Statement**: What problem does this feature solve? Who experiences this problem?
2. **Target Users**: Who are the primary users? Are there secondary users or stakeholders?
3. **Success Criteria**: How will you measure if this feature is successful? What metrics matter?
4. **Scope**: What is the MVP (minimum viable product) for this feature? What's explicitly out of scope?
5. **Constraints**: Are there technical constraints, timeline requirements, or dependencies to be aware of?
6. **Prior Art**: Are there existing solutions or competitors that handle this? What can we learn from them?

### Step 2: Generate the PRD

After gathering answers, create a structured PRD file at `.claude/prds/$ARGUMENTS.md` with this format:

```markdown
# PRD: [Feature Name]

**Status**: Draft
**Author**: [User]
**Created**: [Today's Date]
**Last Updated**: [Today's Date]

## Problem Statement
[Synthesized from interview]

## Goals & Success Metrics
- Goal 1 → Metric
- Goal 2 → Metric

## Target Users
- Primary: [description]
- Secondary: [description]

## User Stories
- As a [user type], I want [action] so that [benefit]
[Generate 3-8 user stories from the interview]

## Functional Requirements
### Must Have (P0)
- [ ] Requirement 1
- [ ] Requirement 2

### Should Have (P1)
- [ ] Requirement 1

### Nice to Have (P2)
- [ ] Requirement 1

## Non-Functional Requirements
- Performance: [requirements]
- Security: [requirements]
- Compatibility: [requirements]

## Technical Considerations
[Any technical notes, constraints, or architecture considerations]

## Out of Scope
- [Explicitly excluded items]

## Open Questions
- [Any unresolved questions from the interview]

## Dependencies
- [External dependencies, APIs, services]
```

### Step 3: Review

After writing the PRD file, display a summary and ask the user if they want to revise any section. Make edits as requested.

### Step 4: Confirm

Tell the user the PRD is saved at `.claude/prds/$ARGUMENTS.md` and suggest next steps:
- Run `/pm:prd-parse $ARGUMENTS` to transform this PRD into a technical epic with task breakdown
