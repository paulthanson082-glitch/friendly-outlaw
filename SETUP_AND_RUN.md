# Setup and Run — Writers App

A step-by-step guide to getting the Writers App up and running on your machine.

---

## Prerequisites

| Requirement | Version | Notes |
|-------------|---------|-------|
| Swift | 5.9+ | [swift.org/download](https://swift.org/download/) |
| SQLite3 dev libraries | any | Included with macOS; `libsqlite3-dev` on Linux |
| Xcode Command Line Tools | latest | macOS only — `xcode-select --install` |

---

## Quick Start

### 1 — Clone the repository

```bash
git clone https://github.com/paulthanson082-glitch/friendly-outlaw.git
cd friendly-outlaw
```

### 2 — Verify setup (recommended)

Run the automated setup script to check prerequisites, build the project, and run a smoke test:

```bash
./setup.sh
```

Sample output:

```
======================================
  Writers App — Setup Verification
======================================

→ Checking Swift...
✓ Swift found: Swift version 5.9.0
→ Checking SQLite3...
✓ SQLite3 found (version 3.43.2)
→ Building Writers App (debug)...
✓ Build succeeded
→ Checking binary...
✓ Binary present: .build/debug/WritersAppCLI (11M)
→ Running CLI smoke test (--help)...
✓ CLI responds to --help

======================================
  Setup complete!
======================================
```

### 3 — Run the CLI

```bash
./run.sh
```

The interactive menu will start. No API key is required for most features.

---

## Build Commands

| Command | Description |
|---------|-------------|
| `swift build` | Debug build |
| `swift build -c release` | Optimised release build |
| `swift package clean` | Remove build artifacts |

---

## Run Commands

| Command | Description |
|---------|-------------|
| `./run.sh` | Build (debug) and launch interactive CLI |
| `./run.sh --release` | Build (release) and launch interactive CLI |
| `swift run WritersAppCLI` | Build and run via SPM |
| `.build/debug/WritersAppCLI` | Run previously built binary directly |
| `.build/release/WritersAppCLI` | Run previously built release binary directly |

---

## Tests

```bash
swift test           # Run all tests
swift test --verbose # Verbose output
```

---

## AI Features (optional)

Set `ANTHROPIC_API_KEY` to enable Claude-powered writing assistance:

```bash
ANTHROPIC_API_KEY="sk-ant-..." ./run.sh
```

Or export it in your shell session:

```bash
export ANTHROPIC_API_KEY="sk-ant-..."
./run.sh
```

---

## Linux Setup

Install required system packages before building:

```bash
sudo apt-get update
sudo apt-get install -y libsqlite3-dev
```

Then follow the Quick Start steps above.

---

## VS Code

Open the repository folder in VS Code. Pre-configured build tasks are available via **⌘⇧B** (macOS) or **Ctrl+Shift+B** (Linux/Windows):

- **Swift: Build** — debug build
- **Swift: Build Release** — release build
- **Swift: Test** — run test suite
- **Swift: Clean** — remove build artifacts
- **Swift: Run CLI** — build and launch interactive CLI

---

## Troubleshooting

### `sqlite3` not found during build

**macOS:** Run `xcode-select --install` to install the Xcode Command Line Tools, which include SQLite3.

**Linux:** Install the development package:
```bash
sudo apt-get install libsqlite3-dev
```

### `fatal: cannot use bare repository ... safe.bareRepository is 'explicit'`

Some environments enforce strict Git safety settings that break Swift Package Manager when it reads cached bare repositories.

Use the repository scripts (`./setup.sh`, `./run.sh`) or prefix direct Swift commands with:

```bash
env GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=safe.bareRepository GIT_CONFIG_VALUE_0=all swift build
env GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=safe.bareRepository GIT_CONFIG_VALUE_0=all swift test
```

### `swift: command not found`

Download and install Swift from [swift.org/download](https://swift.org/download/), then add it to your `PATH`.

### Build fails with linker errors

Ensure the Xcode Command Line Tools are installed and up-to-date:
```bash
xcode-select --install     # install
xcode-select -p            # verify path
```

### Tests fail to compile

Run `swift build` first to catch compilation errors with clearer diagnostics, then re-run `swift test`.
