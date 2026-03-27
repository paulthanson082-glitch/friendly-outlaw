# Getting Started - Mac Pro Development Setup

**Project**: friendly-outlaw (WritersApp Swift + AIMS Web)
**Branch**: `claude/research-mythos-leak-zqUkX`
**Date**: March 27, 2026
**Target**: macOS 13+ (Mac Pro)

---

## 📋 Your Setup Checklist

### ✅ What's Ready for You

We've prepared **three things** for your Mac Pro build:

1. **Development Configuration** - Environment files and settings
2. **Automation Scripts** - Build, test, and workflow automation
3. **This Summary** - Your complete getting-started guide

---

## 🚀 Quick Start (2 minutes)

### Step 1: Copy the .env File

```bash
cd /path/to/friendly-outlaw
cp .env.example .env

# Edit .env and add your Anthropic API key (optional for basic testing)
# ANTHROPIC_API_KEY=sk-ant-...
```

### Step 2: Run Setup Script

```bash
./scripts/setup-dev-env.sh
```

This script will:
- ✅ Verify Swift 5.9+ installed
- ✅ Check SQLite3 (install if needed via Homebrew)
- ✅ Verify git
- ✅ Set up environment files
- ✅ Make scripts executable
- ✅ Show recommendations

### Step 3: Build & Test

```bash
# Build (release = optimized for Mac Pro)
./scripts/build.sh release

# Run tests (88+ tests should pass)
./scripts/test.sh

# Run the CLI
./run.sh
```

**Expected time**: 3-5 minutes total

---

## 📁 What We Created for You

### 1. Configuration Files

#### `.env.example`
- Template for environment variables
- Copy to `.env` and customize
- Includes API keys, database paths, AI settings
- **Don't commit .env to git** (it's in .gitignore)

### 2. Automation Scripts

Located in `scripts/` directory:

#### `setup-dev-env.sh`
Sets up your entire development environment
```bash
./scripts/setup-dev-env.sh
```

#### `build.sh`
Builds the project (debug or release)
```bash
./scripts/build.sh debug          # Quick debug build
./scripts/build.sh release        # Optimized release build
./scripts/build.sh release --clean # Clean + rebuild
```

#### `test.sh`
Runs the complete test suite (88+ tests)
```bash
./scripts/test.sh                 # All tests
./scripts/test.sh true            # Verbose output
./scripts/test.sh false DocumentTests  # Filter by name
```

#### `dev.sh`
Interactive development menu
```bash
./scripts/dev.sh              # Show interactive menu
./scripts/dev.sh build-debug  # Direct commands
./scripts/dev.sh build-release
./scripts/dev.sh test
./scripts/dev.sh run
./scripts/dev.sh full         # Build + Test + Run
./scripts/dev.sh clean        # Clean rebuild
./scripts/dev.sh env          # Show environment
```

#### `run.sh` (existing)
Convenient CLI runner
```bash
./run.sh                                    # Debug
./run.sh --release                          # Release build
ANTHROPIC_API_KEY="sk-..." ./run.sh        # With AI
```

---

## 🛠️ Development Workflows

### Recommended Workflow 1: Interactive Menu

```bash
./scripts/dev.sh
# Choose option 5: Build + Test + Run
```

### Recommended Workflow 2: Step by Step

```bash
# Build
./scripts/build.sh release

# Test
./scripts/test.sh

# Run
./run.sh
```

### Recommended Workflow 3: One-Command Full Build

```bash
./scripts/dev.sh full
```

### Advanced: Direct Swift Commands

```bash
# Build
swift build -c release

# Test
swift test --verbose

# Run
swift run WritersAppCLI
```

---

## 📊 Project Structure (Ready to Build)

```
friendly-outlaw/
├── Sources/WritersApp/         # Main Swift library (70 files)
│   ├── Models/                 # Data structures (18 files)
│   ├── Services/               # Business logic (15+ files)
│   ├── Plugins/                # Plugin system
│   ├── Views/                  # SwiftUI + Metal rendering
│   └── WritersApp.swift        # Main facade (42KB)
│
├── Tests/
│   └── WritersAppTests/        # 88+ unit tests (1541 lines)
│
├── Scripts/                    # NEW: Development automation
│   ├── setup-dev-env.sh        # Environment setup
│   ├── build.sh                # Build automation
│   ├── test.sh                 # Test runner
│   └── dev.sh                  # Development menu
│
├── .env.example                # NEW: Environment template
├── BUILD_FOR_MAC_PRO.md        # Build instructions
├── PRE_BUILD_STATUS.md         # Project status report
├── GETTING_STARTED.md          # This file
├── CLAUDE.md                   # Full documentation
└── Package.swift               # Swift package manifest
```

---

## ⚙️ Environment Variables

Edit `.env` file to customize:

```bash
# AI Features (get from https://console.anthropic.com/)
ANTHROPIC_API_KEY=sk-ant-...

# Database (defaults to ~/Documents/writersapp.db)
DATABASE_PATH=

# AI Model (default: claude-3-5-sonnet)
AI_MODEL=claude-3-5-sonnet
AI_MAX_TOKENS=4096
AI_TEMPERATURE=0.7

# Development
DEBUG=false
BUILD_CONFIG=release

# macOS Specific
METAL_RENDERING=true
```

---

## 🔍 Verification Commands

### Check Swift Setup
```bash
swift --version          # Should be 5.9+
xcode-select -p          # Shows Xcode path
sqlite3 --version        # SQLite3 required
git --version            # Should be installed
```

### Check Project Health
```bash
swift package describe   # Verify dependencies
swift build 2>&1 | grep -i error  # Check for errors
./scripts/test.sh        # Run test suite (should pass)
```

### Check Git Status
```bash
git status               # Should be on claude/research-mythos-leak-zqUkX
git log --oneline -3    # Recent commits
```

---

## 📈 Build Performance on Mac Pro

### Expected Times

| Operation | M1/M2 Pro | Intel | Status |
|-----------|-----------|-------|--------|
| First build | 2-3 min | 3-5 min | ⏱️ One-time |
| Incremental build | 30-60 sec | 1-2 min | ⚡ After changes |
| Release build | 3-5 min | 5-8 min | 🚀 Optimized |
| Test suite | 1-2 min | 2-3 min | ✅ All 88+ pass |
| Full workflow | 5-10 min | 8-15 min | 📊 Complete cycle |

---

## 🐛 Troubleshooting

### "Swift: command not found"
```bash
# Install Xcode Command Line Tools
xcode-select --install

# Or install full Xcode from App Store
```

### "module 'CSQLite' not found"
```bash
# Install SQLite3 development files
brew install sqlite3
```

### Build fails with warnings
```bash
# Try clean rebuild
./scripts/build.sh release --clean
```

### Tests fail mysteriously
```bash
# Clean and rebuild
swift package clean
swift test --verbose
```

### Database corruption
```bash
# Delete corrupted database (will recreate on next run)
rm ~/Documents/writersapp.db
./run.sh
```

---

## 📖 Documentation Reference

| File | Purpose |
|------|---------|
| `CLAUDE.md` | Complete reference (27KB) - APIs, architecture, patterns |
| `BUILD_FOR_MAC_PRO.md` | Build instructions with prereqs |
| `PRE_BUILD_STATUS.md` | Project health report |
| `GETTING_STARTED.md` | This file - quick reference |
| `README.md` | Main project documentation |
| `APPLICATION_ACCESS.md` | Both apps access guide |
| `DEPLOYMENT.md` | Deployment instructions |

---

## 🎯 What You Can Do Now

### Immediate (No coding)
- ✅ Run setup script
- ✅ Build the project
- ✅ Run test suite
- ✅ Try the CLI

### Next Steps
- 📝 Create documents using templates
- 🔍 Explore the codebase
- 🧪 Understand test structure
- 🚀 Enable AI features with API key

### Advanced (With coding)
- 🆕 Add new templates
- 🧠 Implement AI features
- 📊 Create new data models
- 🔌 Build plugins

---

## 🔐 Security Notes

- **Never commit .env to git** - It's in .gitignore
- **Keep API keys private** - Use environment variables
- **Don't share ANTHROPIC_API_KEY** - It costs money
- **Test with test key first** - Before using production key

---

## 💡 Pro Tips for Mac Pro

### Tip 1: Use Release Builds for Testing
```bash
./scripts/build.sh release  # Much faster for CLI
```

### Tip 2: Parallel Test Execution
Tests automatically run in parallel on Mac Pro's multiple cores.

### Tip 3: Metal GPU Acceleration
Set `METAL_RENDERING=true` in .env for GPU-accelerated dashboard.

### Tip 4: Keyboard Shortcuts
Build scripts support:
- `Cmd+B` in VS Code - builds automatically
- `Cmd+Shift+U` - run tests
- Custom shortcuts in `.vscode/keybindings.json`

### Tip 5: Hot Reload (When Editing)
```bash
# Terminal 1: Keep this running
swift build -c release -Xswiftc -enable-batch-mode

# Terminal 2: Edit code
# Changes auto-rebuild
```

---

## 🚀 Next Steps After Setup

1. **Verify Build Works**
   ```bash
   ./scripts/dev.sh full
   ```

2. **Explore Templates**
   ```bash
   ./run.sh
   # Select: Browse Templates
   ```

3. **Create Your First Document**
   ```bash
   ./run.sh
   # Select: Create Document from Template
   ```

4. **Enable AI (Optional)**
   - Get API key from https://console.anthropic.com/
   - Add to `.env`: `ANTHROPIC_API_KEY=sk-ant-...`
   - Re-run: `./run.sh`

5. **Read the Documentation**
   - Start with `README.md`
   - Deep dive: `CLAUDE.md`
   - API reference: See section in `CLAUDE.md`

---

## 📞 Support

### Check These First
1. Run setup script: `./scripts/setup-dev-env.sh`
2. Verify environment: `./scripts/dev.sh env`
3. Try clean rebuild: `./scripts/build.sh release --clean`
4. Check documentation: See CLAUDE.md

### Common Issues
- **Build fails**: Clean with `swift package clean`
- **Tests fail**: Run `./scripts/test.sh true` for details
- **Swift not found**: Run `xcode-select --install`
- **Database issues**: Delete `~/Documents/writersapp.db`

---

## ✨ Summary

You now have:

✅ **Development configuration** - `.env` template ready
✅ **Build automation** - `./scripts/build.sh`
✅ **Test automation** - `./scripts/test.sh`
✅ **Development menu** - `./scripts/dev.sh`
✅ **Setup script** - `./scripts/setup-dev-env.sh`
✅ **Complete guides** - BUILD_FOR_MAC_PRO.md, PRE_BUILD_STATUS.md

**Ready to build on Mac Pro!** 🎉

---

**Branch**: `claude/research-mythos-leak-zqUkX`
**Last Updated**: March 27, 2026
**Status**: ✅ Ready for development
