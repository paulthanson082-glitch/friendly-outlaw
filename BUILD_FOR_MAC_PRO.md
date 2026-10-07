# Build Instructions for Mac Pro

**Project**: friendly-outlaw (WritersApp + AIMS platform)
**Target**: macOS 14+ (Mac Pro — Intel & Apple Silicon M-series)
**Last Updated**: March 27, 2026

---

## Supported Mac Pro Hardware

| Mac Pro Model | Chip | macOS Min | Status |
|---------------|------|-----------|--------|
| Mac Pro (2023) | Apple M2 Ultra | macOS 14 Sonoma | ✅ Supported |
| Mac Pro (2019) | Intel Xeon W | macOS 14 Sonoma | ✅ Supported |
| Mac Pro (2013) | Intel Xeon E5 | macOS 14 Sonoma | ✅ Supported |

> **Note:** Apple Silicon (M2 Ultra) Mac Pros build natively for arm64. Intel Mac Pros build for x86_64. Universal binaries are built automatically by Swift Package Manager.

---

## Pre-Build Checklist

- [ ] Mac Pro with **macOS 14 Sonoma** or later
- [ ] **Xcode 16+** installed from the App Store
- [ ] Swift 5.9+ available (`swift --version`)
- [ ] Xcode Command Line Tools installed (`xcode-select --install`)
- [ ] SQLite3 development files (included with Xcode CLT)
- [ ] Node.js 18+ for AIMS web app (optional)
- [ ] Git installed and configured

### Verify Prerequisites

```bash
# Check Swift version (should be 5.9+)
swift --version

# Check Xcode installation
xcode-select -p
# Should output: /Applications/Xcode.app/Contents/Developer

# Check Xcode Command Line Tools
xcode-select --version

# Check SQLite3 (included with Xcode CLT)
sqlite3 --version

# Verify git
git --version

# Check macOS version
sw_vers
```

---

## Quick Build (Recommended)

```bash
cd /path/to/friendly-outlaw

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

Run all 621+ tests:

```bash
# Standard test run
swift test

# Verbose output
swift test --verbose

# Specific test class
swift test --filter WritersAppTests

# Show timing information
swift test --parallel
```

**Test Coverage:**
- ✅ Core: Templates, documents, word count, statistics
- ✅ Tool loop: Tool definitions, execution, results
- ✅ WritingToolExecutor: 5 built-in writing tools
- ✅ Issue management: CRUD, reopening, status transitions
- ✅ Kanban: Boards, tasks, workflow columns
- ✅ Version control: Branches, commits, diffs, merges, time-travel
- ✅ AI Service: Messaging, tool loops, analysis
- ✅ Chatbot, Hardware, Goals, Focus Sessions, and more

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
- Mac Pro handles builds very quickly (see Build Profile section for times by chip)

### Database Issues

- Default DB location: `~/Documents/writersapp.db`
- For testing: in-memory DB is used (`:memory:`)
- If corrupted, delete the file and rebuild

---

## Next Steps After Build

1. **Run Tests**: `swift test` (should pass 600+ tests)
2. **Try CLI**: `./run.sh` and explore the interactive menu
3. **Check AI Features**: Set `ANTHROPIC_API_KEY` for Claude integration
4. **Explore Web App**: `npm run dev` for the AIMS platform

---

## Key Files to Know

| File | Purpose |
|------|---------|
| `Package.swift` | SPM manifest (dependencies, targets) |
| `Sources/WritersApp/` | Main Swift library (~70 Swift files) |
| `Sources/WritersAppCLI/main.swift` | CLI entry point |
| `Tests/WritersAppTests/` | Test suite (621+ tests) |
| `run.sh` | Convenient build/run script |
| `setup.sh` | Prerequisite verification script |

---

## Documentation Reference

- **[CLAUDE.md](CLAUDE.md)** - AI assistant guide (architecture, APIs, patterns)
- **[README.md](README.md)** - Main project documentation
- **[APPLICATION_ACCESS.md](APPLICATION_ACCESS.md)** - Access guide for both apps
- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Deployment instructions

---

## Build Profile

**Estimated Build Times (Mac Pro):**
- First build (M2 Ultra): ~30–60 seconds
- First build (Intel Xeon): ~2–3 minutes
- Incremental build: ~5–15 seconds
- Release build (M2 Ultra): ~1–2 minutes
- Release build (Intel Xeon): ~3–5 minutes
- Test suite: ~30–90 seconds

> **Apple Silicon advantage:** The M2 Ultra in the 2023 Mac Pro provides significantly faster build times than Intel equivalents due to the unified memory architecture and Neural Engine acceleration for Swift compilation.

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
