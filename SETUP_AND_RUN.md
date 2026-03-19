# Setup and Run - Complete Guide

This document provides step-by-step instructions for setting up and running the friendly-outlaw Writers App.

## Quick Setup (2 minutes)

### Option 1: Automated Setup (Recommended)

```bash
# Clone the repository (if not already done)
git clone https://github.com/paulthanson082-glitch/friendly-outlaw.git
cd friendly-outlaw

# Run the automated setup script
./setup.sh
```

The setup script will:
- ✅ Verify Swift installation (v5.9+)
- ✅ Verify SQLite3 installation
- ✅ Build the project
- ✅ Test the CLI application
- ✅ Verify all core functionality
- ✅ Display next steps

### Option 2: Manual Setup

```bash
# 1. Check prerequisites
swift --version    # Should be 5.9 or later
sqlite3 --version  # Should be installed

# 2. Build the project
swift build

# 3. Run the application
swift run WritersAppCLI
```

## Prerequisites

| Requirement | Minimum Version | Check Command |
|------------|----------------|---------------|
| Swift | 5.9+ | `swift --version` |
| SQLite3 | 3.x | `sqlite3 --version` |
| macOS | 13.0+ | N/A (macOS only) |
| iOS | 16.0+ | N/A (iOS only) |
| Linux | Ubuntu 20.04+ | `lsb_release -a` |

### Installing Prerequisites

#### macOS
```bash
# Swift and SQLite3 come pre-installed on modern macOS
# If Swift is not installed:
xcode-select --install
```

#### Ubuntu/Debian
```bash
# Install Swift from swift.org
sudo apt-get update
sudo apt-get install libsqlite3-dev
```

#### Fedora/RHEL
```bash
sudo dnf install sqlite-devel
```

## Running the Application

### Interactive Mode (Default)

Start the full interactive menu:

```bash
# Using swift run (recommended, auto-builds)
swift run WritersAppCLI

# Or using the convenience script
./run.sh

# Or using the binary directly
.build/debug/WritersAppCLI
```

**Interactive Menu Features:**
- 📝 Browse and create documents from templates
- 📊 View statistics and analytics
- 🔍 Search documents and templates
- 💡 Memory management (store/retrieve writing context)
- 🎯 Focus sessions (Pomodoro, Sprint, Deep Work)
- 📈 Writing goals and streak tracking
- 🤖 AI-powered writing assistance (with API key)
- 🎨 Hardware board management
- 📤 Export to gui.new

### Command-Line Mode

Use specific commands without entering interactive mode:

```bash
# List all documents
./run.sh --list

# Open a document by title
./run.sh --open "My Story"

# Start a focus session
./run.sh --run pomodoro

# Open document and start session together
./run.sh --open "Chapter 1" --run sprint

# Export statistics to gui.new
./run.sh --gui-stats

# Show help
./run.sh --help
```

### With AI Features

Enable AI-powered writing assistance:

```bash
# Set API key (one-time per session)
export ANTHROPIC_API_KEY="sk-ant-your-key-here"

# Run the application
./run.sh
```

**AI Features Include:**
- Continue writing
- Improve text
- Grammar checking
- Title generation
- Document analysis
- Brainstorming
- Character development
- Outline generation
- And more...

## Build Options

### Debug Build (Default)
```bash
swift build
# Output: .build/debug/WritersAppCLI
```

### Release Build (Optimized)
```bash
swift build -c release
# Output: .build/release/WritersAppCLI
```

### Clean Build
```bash
swift package clean
swift build
```

## Testing

Run the test suite:

```bash
# Run all tests
swift test

# Run with verbose output
swift test --verbose

# Run specific test
swift test --filter WritersAppTests
```

**Current Test Status:**
- ✅ 600/621 tests passing
- ⚠️ 21 tests failing (known template category cleanup issue)
- Core functionality fully tested and working

## Verification

Verify your setup is working correctly:

```bash
# Run the automated verification script
./setup.sh

# Or manually verify each component
swift build                          # Should complete without errors
.build/debug/WritersAppCLI --help    # Should show usage
.build/debug/WritersAppCLI --list    # Should list documents
echo "0" | .build/debug/WritersAppCLI  # Should launch and exit
```

## Troubleshooting

### Build Fails on Linux

**Error:** `sqlite3.h: No such file or directory`

**Solution:**
```bash
# Ubuntu/Debian
sudo apt-get install libsqlite3-dev

# Fedora/RHEL
sudo dnf install sqlite-devel
```

### Swift Not Found

**Error:** `swift: command not found`

**Solution:**
1. Download Swift from https://swift.org/download/
2. Follow installation instructions for your platform
3. Add Swift to your PATH

### Permission Denied on Scripts

**Error:** `bash: ./setup.sh: Permission denied`

**Solution:**
```bash
chmod +x setup.sh
chmod +x run.sh
```

### Database Locked Error

**Error:** `database is locked`

**Solution:**
- Close other instances of the app
- Delete `~/Documents/writersapp.db` to start fresh
- Check file permissions

## Directory Structure

```
friendly-outlaw/
├── Sources/
│   ├── WritersApp/          # Main library
│   │   ├── Models/          # Data models
│   │   ├── Services/        # Business logic
│   │   ├── Views/           # UI components
│   │   ├── Plugins/         # Plugin system
│   │   └── Extensions/      # Utilities
│   └── WritersAppCLI/       # CLI application
├── Tests/
│   └── WritersAppTests/     # Test suite
├── .build/                  # Build artifacts (generated)
├── setup.sh                 # Setup verification script ⭐ NEW
├── run.sh                   # Convenience run script
├── Package.swift            # SPM manifest
├── README.md                # Full documentation
├── QUICK_START.md           # Quick start guide
└── SETUP_VERIFICATION.md    # Detailed setup report

```

## Next Steps

After setup, explore these features:

1. **Browse Templates** (Menu option 1)
   - 7+ professional writing templates
   - Novel chapters, short stories, blog posts, etc.

2. **Create Your First Document** (Menu option 2 or 3)
   - From template or blank
   - Automatic word count tracking

3. **Start a Focus Session** (Menu option 40)
   - Pomodoro: 25-minute focused sessions
   - Sprint: 15-minute writing bursts
   - Deep Work: 90-minute immersive writing

4. **Set Writing Goals** (Menu option 44)
   - Daily word count goals
   - Progress tracking
   - Streak management

5. **Try AI Features** (with API key)
   - Continue writing
   - Improve text
   - Generate ideas
   - Analyze documents

## Documentation

| Document | Description |
|----------|-------------|
| [README.md](README.md) | Complete project documentation |
| [QUICK_START.md](QUICK_START.md) | Quick start guide |
| [SETUP_VERIFICATION.md](SETUP_VERIFICATION.md) | Detailed setup verification |
| [CLAUDE.md](CLAUDE.md) | AI assistant context |
| [DATABASE.md](DATABASE.md) | Database schema and API |
| [CLOTHER.md](CLOTHER.md) | Alternative LLM providers |

## Support

- **GitHub Issues**: https://github.com/paulthanson082-glitch/friendly-outlaw/issues
- **Documentation**: See the docs listed above
- **Setup Problems**: Run `./setup.sh` to diagnose issues

## Summary

✅ **The project is ready to use!**

```bash
# Three ways to get started:
./setup.sh                    # 1. Verify setup
swift run WritersAppCLI       # 2. Run interactively
./run.sh --help               # 3. See all options
```

Happy writing! 📝
