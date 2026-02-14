# /pm:epic-oneshot — Push epic and all tasks to GitHub as issues

You are a project manager automating GitHub issue creation. Read a local epic and create all GitHub issues in one shot.

**Epic**: $ARGUMENTS

## Process

### Step 1: Read the epic

Read all files in `.claude/epics/$ARGUMENTS/`:
- `epic.md` — the implementation plan
- `1.md`, `2.md`, etc. — individual task files

If the directory doesn't exist, tell the user and suggest:
- `/pm:prd-new $ARGUMENTS` to create a PRD first
- `/pm:prd-parse $ARGUMENTS` to generate tasks from an existing PRD

### Step 2: Determine labels

Check which labels exist in the repo:

```bash
gh label list
```

Create any missing labels needed:
- `epic` — for the parent epic issue
- `task` — for individual tasks
- `size:S`, `size:M`, `size:L` — for estimates

If label creation fails (e.g., label already exists), continue gracefully.

### Step 3: Create the epic issue

Use `gh` to create the parent epic issue:

```bash
gh issue create --title "Epic: [Feature Name]" --label "epic" --body "..."
```

The epic body should include:
- Overview from epic.md
- Full task table with checkboxes (these will be updated as tasks are completed)
- Architecture decisions
- Link to PRD if relevant

Capture the epic issue number from the output.

### Step 4: Create task issues

For each task file (`1.md`, `2.md`, etc.), create a GitHub issue:

```bash
gh issue create --title "[Task title]" --label "task,size:[S/M/L]" --body "..."
```

The task body should include:
- Reference to parent epic: `Part of #[epic-number]`
- Objective
- Implementation details
- Acceptance criteria as checkboxes
- Testing requirements as checkboxes
- Dependencies on other task issues (use the actual issue numbers)

### Step 5: Update local files

After creating all issues, update the local files with GitHub issue numbers:
- Update `epic.md` task table to include issue numbers
- Update each task `.md` file header with its issue number

### Step 6: Update the epic issue

Edit the epic issue body to include links to all task issues:

```bash
gh issue edit [epic-number] --body "..."
```

Include a task checklist in the epic body:
```
## Tasks
- [ ] #101 — Task 1: [title]
- [ ] #102 — Task 2: [title]
...
```

### Step 7: Summary

Display:
- Epic issue URL
- Table of all created task issues with numbers and URLs
- Which tasks can be started immediately (no dependencies)
- Suggest: `/pm:issue-start [issue-number]` to begin working on a task
