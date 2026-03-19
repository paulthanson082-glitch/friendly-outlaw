# Setup and Run

This guide covers everything you need to install dependencies, build the project, and run the Writers App CLI.

---

## Prerequisites

| Requirement | Minimum version | Notes |
|-------------|----------------|-------|
| [Swift](https://swift.org/download/) | 5.9 | Swift 6.x also supported |
| SQLite3 development library | 3.x | System-provided on macOS; `libsqlite3-dev` on Linux |
| macOS **or** Linux | macOS 13+ / Ubuntu 20.04+ | Windows is not supported |

### macOS

Swift is bundled with Xcode or available as a standalone toolchain from [swift.org](https://swift.org/download/).  
SQLite3 is pre-installed on macOS — no extra steps needed.

### Linux (Ubuntu / Debian)

```bash
# Install SQLite3 development headers
sudo apt-get update
sudo apt-get install -y libsqlite3-dev

# Install Swift (example for Ubuntu 22.04 – adjust for your distro)
# See https://swift.org/download/ for the latest tarball
```

---

## Quick Setup (Automated)

Run the included setup script to verify all prerequisites, build the project, and confirm the CLI works:

```bash
./setup.sh
```

The script will:
1. Verify Swift and SQLite3 are available
2. Run `swift build` (debug build)
3. Confirm the CLI binary was created
4. Perform a smoke test (`--help`, `--list`)
5. Report a pass/fail summary with next steps

To also perform a release build during setup:

```bash
./setup.sh --release
```

---

## Manual Setup

### 1. Clone the repository

```bash
git clone https://github.com/paulthanson082-glitch/friendly-outlaw.git
cd friendly-outlaw
```

### 2. Build

**Debug build** (fast, includes debug symbols):

```bash
swift build
```

**Release build** (optimized, smaller binary):

```bash
swift build -c release
```

Build artifacts are placed in:

| Mode    | Binary path                       |
|---------|-----------------------------------|
| Debug   | `.build/debug/WritersAppCLI`      |
| Release | `.build/release/WritersAppCLI`    |

### 3. Run

There are several ways to run the application:

```bash
# Recommended: use the convenience script (builds automatically if needed)
./run.sh

# Or call swift run directly
swift run WritersAppCLI

# Or call the pre-built binary directly
.build/debug/WritersAppCLI
```

---

## Running the CLI

### Interactive Mode

Launch without arguments to enter the interactive menu:

```bash
./run.sh
```

### Command-Line Arguments

```bash
# Show help
./run.sh --help

# List all documents
./run.sh --list

# Open a document by title or UUID
./run.sh --open "My Novel"
./run.sh --open <document-uuid>

# Start a focus session
./run.sh --run pomodoro        # 25-minute Pomodoro session
./run.sh --run sprint          # 15-minute writing sprint
./run.sh --run deepwork        # 90-minute deep-work block

# Combine flags
./run.sh --open "Chapter 1" --run pomodoro
```

### Release Mode

```bash
./run.sh --release
```

### With AI Features

AI-powered writing assistance (powered by Claude / Anthropic) requires an API key:

```bash
# One-time for the current shell session
export ANTHROPIC_API_KEY="sk-ant-your-key-here"
./run.sh

# Or inline (single command)
ANTHROPIC_API_KEY="sk-ant-your-key-here" ./run.sh
```

> **Note:** AI features are optional. The app runs fully without an API key; AI menu items are hidden automatically when no key is configured.

---

## Running Tests

```bash
swift test               # Run all tests
swift test --verbose     # Verbose output
```

---

## Cleaning Build Artifacts

```bash
swift package clean
```

---

## Troubleshooting

### `error: no such module 'CSQLite'`

The `CSQLite` system library wrapper requires `sqlite3` development headers.

- **macOS**: These are included with Xcode Command Line Tools — run `xcode-select --install`.
- **Linux**: Install with `sudo apt-get install libsqlite3-dev` (Debian/Ubuntu) or equivalent.

### `swift: command not found`

Swift is not installed or not in your `$PATH`. Download and install from [swift.org/download](https://swift.org/download/), then follow the platform-specific PATH instructions.

### Build hangs or is very slow

First builds fetch and compile all Swift Package Manager dependencies. This is normal and only happens once. Subsequent builds are incremental and much faster.

### Binary exists but crashes at launch

Ensure you are running the binary from the project root directory, as the app may look for relative paths (e.g. the database file defaults to the Documents directory on macOS and `$HOME` on Linux).

---

## Project Structure (Quick Reference)

```
friendly-outlaw/
├── Sources/
│   ├── WritersApp/          # Library: models, services, views
│   └── WritersAppCLI/       # CLI entry point (main.swift)
├── Tests/
│   └── WritersAppTests/     # Unit tests
├── Package.swift            # SPM manifest
├── setup.sh                 # Automated setup & verification script
├── run.sh                   # Convenience runner script
└── SETUP_AND_RUN.md         # This file
```

---

## Additional Resources

| Document | Description |
|----------|-------------|
| `README.md` | Full feature overview |
| `QUICK_START.md` | Condensed getting-started guide |
| `DATABASE.md` | SQLite schema and persistence details |
| `CLAUDE.md` | AI assistant context and API reference |
| `DEPLOYMENT.md` | Production deployment instructions |
