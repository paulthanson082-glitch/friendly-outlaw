# /pm:issue-start — Start working on a GitHub issue

You are a developer assistant starting work on a specific task. Set up the workspace and begin implementation.

**Issue**: $ARGUMENTS

## Process

### Step 1: Fetch issue details

```bash
gh issue view $ARGUMENTS --json number,title,body,labels,assignees
```

Parse the issue body for:
- Objective
- Implementation details
- Acceptance criteria
- Dependencies
- Parent epic reference

### Step 2: Check dependencies

If the issue references dependencies (e.g., "Depends on #102"):
- Check if those issues are closed: `gh issue view [dep-number] --json state`
- If dependencies are not met, warn the user and ask if they want to proceed anyway

### Step 3: Find the local task file

Search `.claude/epics/` for a task file that references issue $ARGUMENTS. If found:
- Read the full task details from the local file
- Update its status to `in-progress`

### Step 4: Prepare the workspace

- Read `CLAUDE.md` to understand project conventions
- Read all files listed in the "Implementation Details" section to understand current code
- Identify the specific changes needed

### Step 5: Create a work update file

Create `.claude/epics/[epic-name]/updates/$ARGUMENTS-start.md`:

```markdown
# Issue #$ARGUMENTS — Work Started

**Started**: [timestamp]
**Branch**: [current branch]

## Plan
[Brief implementation plan based on issue details]

## Files to Touch
- [list of files]
```

### Step 6: Begin implementation

Start implementing the task following the issue's implementation details and acceptance criteria. Work through each requirement methodically:

1. Make the code changes described in the issue
2. Follow the project's code conventions from CLAUDE.md
3. Run tests after changes: `swift test`
4. Verify each acceptance criterion is met

### Step 7: On completion

After implementation is complete:
- Run the full test suite and confirm all tests pass
- Update the local task file status to `completed`
- Create a completion update at `.claude/epics/[epic-name]/updates/$ARGUMENTS-done.md`:

```markdown
# Issue #$ARGUMENTS — Completed

**Completed**: [timestamp]

## Changes Made
- [summary of changes]

## Files Modified
- [list]

## Test Results
[test output summary]
```

- Commit changes with a message referencing the issue: `Closes #$ARGUMENTS — [description]`
- Suggest running `/pm:epic-sync [epic-name]` to update GitHub
