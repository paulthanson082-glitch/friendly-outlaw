# Statusline Counter Scripts

This directory contains scripts for VS Code statusLineCommand integration.

## statusline-counts.sh

Convenience wrapper for the StatuslineCounter executable that provides project-scoped counts of AI suggestions and writing sessions.

### Features

- **Fast Performance**: Direct SQLite reads (~15ms)
- **Project Scoping**: Counts filtered by project name
- **Auto-Build**: Automatically builds StatuslineCounter if not present
- **Environment Variable**: Respects `WRITERS_APP_DATA_DIR`
- **Graceful Errors**: Returns zeros on any error

### Usage

```bash
# Basic usage
./plugin/scripts/statusline-counts.sh /path/to/project

# Example output
{"project":"my-project","sessions":15,"suggestions":42}

# With custom database location
WRITERS_APP_DATA_DIR=/custom/path ./plugin/scripts/statusline-counts.sh /path/to/project
```

### VS Code Integration

To integrate with VS Code statusline, install the `statusLineCommand` extension and add to your settings.json:

```json
{
  "statusLineCommand.commands": [
    {
      "id": "writersapp.counts",
      "name": "WritersApp",
      "command": "/absolute/path/to/friendly-outlaw/plugin/scripts/statusline-counts.sh",
      "arguments": ["${workspaceFolder}"],
      "interval": 30000,
      "format": "WA: {suggestions}s / {sessions}t"
    }
  ]
}
```

**Parameters:**
- `id`: Unique identifier for this command
- `name`: Display name in statusline
- `command`: Absolute path to the script
- `arguments`: `${workspaceFolder}` provides the current project path
- `interval`: Update interval in milliseconds (30000 = 30 seconds)
- `format`: Display format using `{suggestions}` and `{sessions}` placeholders

### Direct Executable Usage

You can also call the StatuslineCounter executable directly:

```bash
# After building
cd /path/to/friendly-outlaw
swift build
.build/debug/StatuslineCounter /path/to/project
```

### How It Works

1. Takes a project path as command-line argument
2. Extracts the project name from the path (last component)
3. Opens the SQLite database (location from `WRITERS_APP_DATA_DIR` or default)
4. Queries `AI_Suggestions` with `WHERE project = ?`
5. Queries `User_Sessions` with `WHERE project = ?`
6. Returns JSON with counts and project name
7. On any error, returns zeros gracefully

### Performance

- **Average execution time**: ~15ms (measured on modern hardware with typical database sizes <1000 records)
- **No dependencies**: Direct SQLite access, no HTTP calls
- **Lightweight**: No worker process required
- **Safe**: Read-only database access

Performance may vary based on database size, hardware, and system load.

### Environment Variables

- `WRITERS_APP_DATA_DIR`: Custom database directory (default: user documents directory)

Example:
```bash
export WRITERS_APP_DATA_DIR="$HOME/.writersapp"
./plugin/scripts/statusline-counts.sh /path/to/project
```

### Troubleshooting

**Returns zeros when database has data:**
- Check that the `project` field is populated in the database
- Verify the project name matches (it's the last path component)

**Script not found error:**
- Ensure the script is executable: `chmod +x plugin/scripts/statusline-counts.sh`
- Use absolute paths in VS Code settings

**Build errors:**
- Run `swift build` manually to see detailed error messages
- Ensure SQLite3 development libraries are installed (Linux only)

### See Also

- [DATABASE.md](../../DATABASE.md) - Complete database documentation
- [README.md](../../README.md) - Main project documentation
