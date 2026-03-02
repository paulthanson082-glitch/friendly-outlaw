---
name: build-project
description: Build the friendly-outlaw Swift project (debug or release)
disable-model-invocation: false
argument-hint: [debug|release] [optional-flags]
---

# Build friendly-outlaw

Build the Swift package for friendly-outlaw with optional configuration.

## Build modes

- **debug** (default): Fast compile, full debug info, `-Onone` optimization
- **release**: Optimized build with `-Osize` or `-O`, smaller binary

## Quick commands

```bash
# Debug build (default)
swift build

# Release build
swift build -c release

# Clean and rebuild
swift package clean && swift build

# Verbose output
swift build --verbose

# Build and run CLI
swift build && swift run WritersAppCLI
```

## What gets built

- **WritersApp**: Main library with all models, services, and features
- **WritersAppCLI**: Command-line interface for interactive use

## Environment setup

- Requires Swift 5.9+
- Requires macOS 13+ or iOS 16+
- Set `ANTHROPIC_API_KEY` for AI features: `export ANTHROPIC_API_KEY="sk-..."`

## Build output

- Debug: `.build/debug/`
- Release: `.build/release/`

## Troubleshooting

- If build fails, run `swift package clean` first
- Check that CSQLite system library is available (`sqlite3`)
- Ensure Swift version is 5.9 or later: `swift --version`
- For AI features, verify `ANTHROPIC_API_KEY` is set
