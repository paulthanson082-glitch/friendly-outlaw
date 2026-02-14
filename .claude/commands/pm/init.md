# /pm:init — Initialize the PM workflow for this project

You are setting up the project management workflow. Verify the directory structure exists and display available commands.

## Process

### Step 1: Verify directory structure

Check that these directories exist, create any that are missing:

- `.claude/commands/pm/` — PM command definitions
- `.claude/epics/` — Local epic workspace (should be in .gitignore)
- `.claude/prds/` — PRD storage
- `.claude/context/` — Project context files

### Step 2: Verify .gitignore

Check that `.gitignore` includes `.claude/epics/`. If not, add it — epics contain local working state that should not be committed.

### Step 3: Check GitHub CLI

Verify `gh` is available and authenticated:

```bash
gh auth status
```

If not authenticated, tell the user to run `gh auth login`.

### Step 4: Scan existing state

Report:
- Number of PRDs in `.claude/prds/`
- Number of epics in `.claude/epics/`
- For each epic, show task count and completion status

### Step 5: Display available commands

```
PM Workflow Commands:

  /pm:init              Initialize/verify PM workflow setup
  /pm:prd-new [name]    Create a new PRD through guided brainstorming
  /pm:prd-parse [name]  Transform a PRD into a technical epic with tasks
  /pm:epic-oneshot [name]  Push epic + all tasks to GitHub as issues
  /pm:epic-sync [name]  Sync local epic state with GitHub issues
  /pm:issue-start [#]   Start working on a specific GitHub issue

Workflow:
  1. /pm:prd-new [feature]        → Create PRD
  2. /pm:prd-parse [feature]      → Plan epic + tasks
  3. /pm:epic-oneshot [feature]   → Push to GitHub
  4. /pm:issue-start [issue-#]    → Begin implementation
  5. /pm:epic-sync [feature]      → Sync progress
```
