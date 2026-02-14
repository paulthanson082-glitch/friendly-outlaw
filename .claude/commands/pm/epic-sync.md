# /pm:epic-sync — Sync local epic state with GitHub issues

You are a project manager syncing local work state with GitHub. Bidirectionally sync epic progress between local files and GitHub issues.

**Epic**: $ARGUMENTS

## Process

### Step 1: Read local state

Read all files in `.claude/epics/$ARGUMENTS/`:
- `epic.md` — get the task table and issue numbers
- Each task file (`1.md`, `2.md`, etc.) — get status and issue number
- `updates/` — check for any work-in-progress update files

### Step 2: Read GitHub state

For each task issue number found in local files:

```bash
gh issue view [number] --json number,title,state,labels,body
```

Also read the parent epic issue.

### Step 3: Determine sync direction

Compare local and remote states for each task:

| Local Status | GitHub State | Action |
|---|---|---|
| `pending` | `open` | No change |
| `in-progress` | `open` | Update GitHub with progress notes |
| `completed` | `open` | Close GitHub issue |
| `pending` | `closed` | Update local to completed |
| `completed` | `closed` | No change |

### Step 4: Apply updates

**Local → GitHub:**
- Close completed issues: `gh issue close [number]`
- Add progress comments for in-progress tasks: `gh issue comment [number] --body "..."`

**GitHub → Local:**
- Update local task file status fields to match GitHub state
- Update epic.md task table

### Step 5: Update epic checklist

Edit the parent epic issue to reflect current task completion:

```bash
gh issue edit [epic-number] --body "..."
```

Update the task checklist, marking completed items with `[x]`.

### Step 6: Summary

Display a sync report:
- Tasks completed: X/Y
- Tasks in progress: X
- Tasks remaining: X
- Any conflicts detected and how they were resolved
- Next recommended tasks to work on (no unmet dependencies)
