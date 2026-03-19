# Setup and Run Guide

This guide documents the complete setup and execution process for the **friendly-outlaw** Writers App.

## ✅ Prerequisites Verification

The following prerequisites have been verified as installed and working:

| Component | Version | Status |
|-----------|---------|--------|
| Swift | 6.2.4 | ✅ Installed |
| SQLite3 | System Library | ✅ Available via pkg-config |
| Target Platform | x86_64-unknown-linux-gnu | ✅ Compatible |

## 🔧 Setup Process

### 1. Clone the Repository

```bash
git clone https://github.com/paulthanson082-glitch/friendly-outlaw.git
cd friendly-outlaw
```

### 2. Verify Prerequisites

```bash
# Check Swift installation
swift --version

# Check SQLite3 availability (Linux)
pkg-config --exists sqlite3 && echo "SQLite3 found" || echo "SQLite3 not found"
```

If SQLite3 is not found on Linux, install it:

```bash
# Ubuntu/Debian
sudo apt-get install libsqlite3-dev

# Fedora/RHEL
sudo dnf install sqlite-devel
```

### 3. Build the Project

```bash
# Debug build (recommended for development)
swift build

# Release build (optimized for production)
swift build -c release
```

**Expected output:**
```
Building for debugging...
[compilation progress...]
Build complete! (time varies)
```

The compiled binary will be available at:
- Debug: `.build/debug/WritersAppCLI`
- Release: `.build/release/WritersAppCLI`

### 4. Run Tests (Optional)

```bash
swift test
```

**Note:** As of this verification:
- Total tests: 621
- Compilation: ✅ Successful
- Test results: 600 passing, 21 failing (pre-existing template category issues)
- The failing tests relate to template counts and categories (expected 7 templates, actual 17)

## 🚀 Running the Application

### Interactive Mode (Recommended)

The easiest way to run the application:

```bash
# Using the convenience script
./run.sh

# Or directly with swift run
swift run WritersAppCLI

# Or using the compiled binary
.build/debug/WritersAppCLI
```

This launches the interactive CLI menu with all features available.

### Command-Line Mode

For non-interactive usage:

```bash
# Show help
./run.sh --help

# List all documents
./run.sh --list

# Open a document by title
./run.sh --open "My Story"

# Open a document by ID
./run.sh --open <document-uuid>

# Start a focus session
./run.sh --run pomodoro

# Combined: open document and start session
./run.sh --open "My Novel" --run sprint
```

### With AI Features

To enable AI-powered writing assistance:

```bash
# Set your Anthropic API key
export ANTHROPIC_API_KEY="your-api-key-here"

# Run the application
./run.sh
```

Or inline:

```bash
ANTHROPIC_API_KEY="your-key" ./run.sh
```

## ✅ Verification Checklist

All items have been verified as working:

- [x] **Swift compiler available**: `swift --version` returns 6.2.4
- [x] **SQLite3 available**: `pkg-config --exists sqlite3` succeeds
- [x] **Project builds**: `swift build` completes successfully
- [x] **Tests compile**: `swift test` compiles 621 tests
- [x] **Application launches**: CLI starts and displays main menu
- [x] **Help command works**: `--help` displays usage information
- [x] **List command works**: `--list` shows document list (empty initially)
- [x] **Run script works**: `./run.sh` executes properly
- [x] **Menu displays**: All menu categories visible (Templates, Memory, Productivity, etc.)

## 📋 Application Features

The Writers App provides:

### Core Features
- ✅ 17 pre-built writing templates (Novel, Short Story, Blog Post, etc.)
- ✅ Document management (Create, edit, search, export)
- ✅ Word count and reading time tracking
- ✅ Multiple export formats (Markdown, HTML, plain text)

### AI Features (with ANTHROPIC_API_KEY)
- Continue writing
- Improve text
- Grammar checking
- Title generation
- Document analysis
- Brainstorming
- Character development
- Outline generation

### Productivity Features
- Focus sessions (Freewrite, Pomodoro, Sprint, Deep Work)
- Writing goals and progress tracking
- Streak tracking
- Productivity analytics
- Encouragement system

### Advanced Features
- Memory plugin for knowledge storage
- Issue tracking and management
- Kanban boards for project organization
- Version control (Dolt-style Git semantics)
- Hardware board management
- gui.new visual export integration

### Optional Integrations
- Ragie (document retrieval) - requires RAGIE_API_KEY
- gui.new Pro (extended export) - requires GUI_NEW_API_KEY
- Clother (100+ LLM providers) - requires separate installation

## 🎯 Quick Start Example

Here's a complete example session:

```bash
# 1. Navigate to project
cd friendly-outlaw

# 2. Build the project
swift build
# Output: Build complete! (0.99s)

# 3. Run the application
./run.sh

# 4. The menu appears - try these options:
# → Press 1 to browse templates
# → Press 2 to create a document from template
# → Press 3 to create a blank document
# → Press 5 to view statistics
# → Press 0 to exit
```

## 🔍 Troubleshooting

### Build fails with "sqlite3 not found"

**Solution:**
```bash
# Ubuntu/Debian
sudo apt-get install libsqlite3-dev

# Fedora/RHEL
sudo dnf install sqlite-devel
```

### Permission denied on run.sh

**Solution:**
```bash
chmod +x run.sh
```

### Swift not found

**Solution:** Download and install Swift from https://swift.org/download/

### Tests fail with template category errors

**Status:** Known issue - the codebase has evolved to include more templates (17) than the original specification (7). The application works correctly; tests need updating to match current implementation. This does not affect application functionality.

## 📚 Additional Documentation

For more detailed information, see:

- **QUICK_START.md** - Quick start guide with examples
- **README.md** - Comprehensive feature documentation
- **CLAUDE.md** - Complete API reference for AI assistants
- **DATABASE.md** - Database schema and SQL operations
- **CLOTHER.md** - Alternative LLM provider setup

## 🎉 Success Confirmation

If you see this output when running the application, setup is complete:

```
╔══════════════════════════════════════╗
║     Writers App with Templates       ║
║   Swift Edition - Productivity Plus  ║
╚══════════════════════════════════════╝

ⓘ AI features disabled (set ANTHROPIC_API_KEY to enable)
✓ Claude Memory plugin enabled

Main Menu:
[... menu options ...]
```

**You're all set! The friendly-outlaw Writers App is ready to use.** 📝

---

*Document last updated: 2026-03-19*
*Verified on: x86_64-unknown-linux-gnu with Swift 6.2.4*
