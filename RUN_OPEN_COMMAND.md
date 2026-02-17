# Run Open Command - Documentation

## Overview

The Writers App CLI supports a powerful **combined command** feature that allows you to **open a document and start a focus session** in a single command. This is perfect for writers who want to jump straight into a focused writing session on a specific document.

## Syntax

```bash
WritersAppCLI --open <id|title> --run [type]
WritersAppCLI --run [type] --open <id|title>  # Order doesn't matter
```

or with the convenience script:

```bash
./run.sh --open <id|title> --run [type]
./run.sh --run [type] --open <id|title>
```

## Session Types

The `--run` command supports the following focus session types:

| Type | Duration | Description |
|------|----------|-------------|
| `freewrite` or `free` | No limit | Open-ended writing session (default) |
| `pomodoro` or `pomo` | 25 minutes | Pomodoro technique session |
| `sprint` or `writing-sprint` | 15 minutes | Quick writing sprint |
| `deepwork` or `deep` | 90 minutes | Deep work session |
| `marathon` | Extended | Marathon writing session |

## Opening Documents

You can open documents by:

1. **Full UUID**: `--open 12345678-1234-1234-1234-123456789abc`
2. **Exact title match**: `--open "My Novel"` (case-insensitive)
3. **Partial title match**: `--open "Chapter"` (finds documents containing "Chapter")

## Examples

### Basic Usage

```bash
# Open "My Novel" and start a 25-minute Pomodoro session
WritersAppCLI --open "My Novel" --run pomodoro

# Open "Chapter 1" and start a 15-minute writing sprint
WritersAppCLI --open "Chapter 1" --run sprint

# Open document by ID and start a 90-minute deep work session
WritersAppCLI --open <document-id> --run deepwork

# Open document and start a free write session (no time limit)
WritersAppCLI --open "My Story" --run
# or simply
WritersAppCLI --open "My Story" --run freewrite
```

### Using run.sh Script

```bash
# Open document and start session
./run.sh --open "My Novel" --run pomodoro

# Run in release mode (optimized)
./run.sh --release --open "My Novel" --run pomodoro

# Order doesn't matter
./run.sh --run deepwork --open "Chapter 1"
```

## What Happens

When you use the combined `--open --run` command, the CLI:

1. **Finds the document** by ID or title (supports partial matching)
2. **Validates** that no other focus session is currently active
3. **Starts the focus session** with the specified type and duration
4. **Links the session to the document** for progress tracking
5. **Updates the document's metadata** (sets `lastOpened` timestamp)
6. **Displays document information**:
   - Title and category
   - Current word count and character count
   - Goal progress (if a word count goal is set)
7. **Shows session details**:
   - Session type and duration
   - Starting word count
   - Linked document name

## Session Tracking

The focus session tracks your writing progress:

- Records starting word count
- Links to the document for analytics
- Tracks time spent in the session
- Updates productivity statistics

You can view your current session or end it by running the CLI in interactive mode:

```bash
# Start interactive mode
WritersAppCLI

# Then use menu options:
# 41. View Current Session
# 42. End Focus Session
# 43. Focus Session Stats
```

## Error Handling

The command handles various error scenarios:

- **Document not found**: Shows error and suggests using `--list`
- **Multiple partial matches**: Lists all matches and asks for more specific title
- **Session already active**: Prevents starting multiple simultaneous sessions
- **Invalid session type**: Shows error and lists valid types

## Standalone Commands

You can also use `--open` and `--run` separately:

### Open Only

```bash
# Open a document (displays info but doesn't start session)
WritersAppCLI --open "My Story"
```

### Run Only

```bash
# Start a focus session without linking to a document
WritersAppCLI --run pomodoro
```

## Tips

1. **Use quotes** for titles with spaces: `--open "My Novel"`
2. **Partial matching** is case-insensitive: `--open "chapter"` matches "Chapter 1"
3. **Order doesn't matter**: `--open X --run Y` = `--run Y --open X`
4. **Default session type**: If you don't specify a type, it defaults to `freewrite`
5. **Check documents first**: Use `--list` to see available documents
6. **Interactive mode**: For more advanced features, run without arguments

## Integration with Productivity Features

The combined command integrates with the app's productivity tracking:

- **Writing goals**: Progress toward goals is tracked during the session
- **Analytics**: Session data is recorded for productivity reports
- **Encouragement**: Automatic encouragement messages during writing
- **Statistics**: Session stats available via menu option 43

## Complete Workflow Example

```bash
# 1. List available documents
./run.sh --list

# 2. Open document and start a Pomodoro session
./run.sh --open "My Novel" --run pomodoro

# 3. Write for 25 minutes...

# 4. View session stats (interactive mode)
./run.sh
# Select option 41 to view current session
# Select option 42 to end session when done
```

## See Also

- `WritersAppCLI --help` - Full CLI help
- `./run.sh --help` - run.sh script help
- Interactive menu - Run `WritersAppCLI` without arguments for all features
