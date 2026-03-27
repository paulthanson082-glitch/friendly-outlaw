# Build Instructions for Mac Pro

**Project**: friendly-outlaw (WritersApp + AIMS platform)
**Target**: macOS (Mac Pro)
**Branch**: `claude/research-mythos-leak-zqUkX`
**Last Updated**: March 27, 2026

---

## Pre-Build Checklist

- [ ] Mac Pro with macOS 13+ (Ventura or later recommended)
- [ ] Xcode 15+ installed (`xcode-select --install` if needed)
- [ ] Swift 5.9+ available (`swift --version`)
- [ ] SQLite3 development files installed
- [ ] Node.js 18+ for AIMS web app (optional)
- [ ] Git installed and configured

### Verify Prerequisites

```bash
# Check Swift version (should be 5.9+)
swift --version

# Check Xcode installation
xcode-select -p
# Should output: /Applications/Xcode.app/Contents/Developer

# Check SQLite3
sqlite3 --version

# Verify git
git --version
```

---

## Quick Build (Recommended)

```bash
cd /path/to/friendly-outlaw

# Clone the development branch if needed
git checkout claude/research-mythos-leak-zqUkX

# Build for Mac (debug)
swift build

# Or optimized release build (faster CLI)
swift build -c release
```

**Expected output:**
```
Building for production...
Build complete! (XX.XXs)
```

---

## Run the Writers App CLI

### Option 1: Using the convenience script
```bash
./run.sh
```

### Option 2: Direct Swift execution
```bash
# Debug build
swift run WritersAppCLI

# Release build
.build/release/WritersAppCLI
```

### Option 3: With AI features enabled
```bash
export ANTHROPIC_API_KEY="sk-ant-..."
./run.sh
```

---

## Test Suite

Run all 664+ tests:

```bash
# Standard test run
swift test

# Verbose output
swift test --verbose

# Specific test class
swift test WritersAppTests

# Show timing information
swift test --stats
```

**Test Coverage:**
- ✅ Core (WritersAppTests): Templates, documents, word count, statistics (125 tests)
- ✅ Version control (Dolt): Branches, commits, diffs, merges, time-travel (75 tests)
- ✅ Writing goals: Goal tracking, streaks, progress (69 tests)
- ✅ Database manager: SQLite persistence, queries (57 tests)
- ✅ Productivity analytics: Writing analytics, stats (49 tests)
- ✅ Focus sessions: Session lifecycle, modes (49 tests)
- ✅ iPad Pro features: UI models, multitasking (37 tests)
- ✅ Document manager: CRUD, search, statistics (29 tests)
- ✅ Error paths: Error handling, edge cases (28 tests)
- ✅ Encouragement service: Messages, milestones (28 tests)
- ✅ Metal dashboard: GPU rendering, view models (27 tests)
- ✅ Issue management: CRUD, status transitions (22 tests)
- ✅ Plugins: Plugin lifecycle, memory plugin (21 tests)
- ✅ AI Service: Messaging, tool loops, analysis (21 tests)
- ✅ Export formats: Markdown, HTML, plain text (19 tests)
- ✅ Performance: Load testing, benchmarks (8 tests)

---

## Build Artifacts

After building, files are located in:

```
.build/
├── debug/
│   ├── WritersAppCLI          # Debug executable
│   └── libWritersApp.*         # Library
├── release/
│   ├── WritersAppCLI          # Optimized executable
│   └── libWritersApp.*
└── checkouts/                  # Dependencies
```

### Distribution (Release Build)

For distribution, use the release build:

```bash
# Build release
swift build -c release

# Location: .build/release/WritersAppCLI
# This is optimized and can be distributed
```

---

## Clean Build

If you encounter issues, clean and rebuild:

```bash
swift package clean
swift build -c release
```

---

## Advanced Options

### Build with Verbose Output
```bash
swift build -v 2>&1 | tee build.log
```

### Build with Sanitizers (Debug)
```bash
swift build -Xswiftc -sanitize=thread
```

### Static Linking (for distribution)
```bash
swift build -c release -Xswiftc -static-stdlib
```

---

## AIMS Web App (Optional)

The project also includes an AIMS web application (Next.js/React):

```bash
# Install dependencies
npm install
cd backend && npm install && cd ..

# Start development server
npm run dev

# Access at http://localhost:3000
```

---

## Troubleshooting

### Swift Build Fails

**"module 'CSQLite' not found"**
- Install SQLite3 dev files: `brew install sqlite3`
- Update Xcode: `xcode-select --install`

**"error: unable to load standard library"**
- Swift version mismatch: ensure Swift 5.9+
- Update Xcode if needed

### Performance Issues

- Use release build for testing: `swift build -c release`
- Mac Pro should handle builds quickly (2-5 minutes depending on M1/M2/Intel)

### Database Issues

- Default DB location: `~/Documents/writersapp.db`
- For testing: in-memory DB is used (`:memory:`)
- If corrupted, delete the file and rebuild

---

## Next Steps After Build

1. **Run Tests**: `swift test` (should pass all 664+ tests)
2. **Try CLI**: `./run.sh` and explore the interactive menu
3. **Check AI Features**: Set `ANTHROPIC_API_KEY` for Claude integration
4. **Explore Web App**: `npm run dev` for the AIMS platform

---

## Key Files to Know

| File | Purpose |
|------|---------|
| `Package.swift` | SPM manifest (dependencies, targets) |
| `Sources/WritersApp/` | Main Swift library (70 Swift files, 1.1MB) |
| `Sources/WritersAppCLI/main.swift` | CLI entry point |
| `Tests/WritersAppTests/` | Test suite (16 test files, 664+ tests) |
| `run.sh` | Convenient build/run script |

---

## Documentation Reference

- **[CLAUDE.md](CLAUDE.md)** - AI assistant guide (architecture, APIs, patterns)
- **[README.md](README.md)** - Main project documentation
- **[APPLICATION_ACCESS.md](APPLICATION_ACCESS.md)** - Access guide for both apps
- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Deployment instructions

---

## Build Profile

**Estimated Build Times (Mac Pro):**
- First build (M1/M2): ~2-3 minutes
- Incremental build: ~30-60 seconds
- Release build: ~3-5 minutes
- Test suite: ~1-2 minutes

---

## Support

If you encounter issues:

1. Check Swift version: `swift --version`
2. Verify dependencies: `swift package describe`
3. Run clean build: `swift package clean && swift build`
4. Check logs: `swift build -v 2>&1 | tee build.log`

For detailed documentation, see [CLAUDE.md](CLAUDE.md) or run:
```bash
./run.sh --help
```
