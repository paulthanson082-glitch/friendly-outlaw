# Quick Start Guide - Open and Run

This guide demonstrates how to quickly open and run the friendly-outlaw Writers App.

## Prerequisites

- Swift 5.9 or later
- macOS 13+ or Linux with SQLite3 development libraries

## Opening the Project

The project is a Swift Package Manager (SPM) project. You can open it in several ways:

### Option 1: Command Line (Recommended)

```bash
# Navigate to the project directory
cd /path/to/friendly-outlaw

# The project is now "open" - you can work with it using Swift commands
```

### Option 2: Xcode (macOS)

```bash
open Package.swift
```

This will open the project in Xcode.

### Option 3: VS Code

```bash
code .
```

The project includes complete VS Code configuration in `.vscode/` directory.

## Building the Project

### Debug Build

```bash
swift build
```

This creates a debug build in `.build/debug/WritersAppCLI`.

### Release Build

```bash
swift build -c release
```

This creates an optimized release build in `.build/release/WritersAppCLI`.

## Running the Application

### Interactive Mode

Run the CLI in interactive mode to explore all features:

```bash
# Using swift run (automatically builds if needed)
swift run WritersAppCLI

# Or using the pre-built binary
.build/debug/WritersAppCLI

# Or using the convenient run script
./run.sh
```

### Command-Line Arguments

The application supports direct command-line operations:

```bash
# Show help
./run.sh --help

# List all documents
./run.sh --list

# Open a document by title
./run.sh --open "My Story"

# Open a document by ID
./run.sh --open <document-uuid>
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

## Testing the Project

Run the test suite to verify everything works:

```bash
swift test
```

All tests should pass, demonstrating that the project is working correctly.

## Verification Checklist

✅ **Project Opens**: You can navigate to the directory and access all files  
✅ **Project Builds**: `swift build` completes without errors  
✅ **Tests Pass**: `swift test` runs all tests successfully  
✅ **Application Runs**: The CLI launches and displays the main menu  
✅ **Help Works**: `--help` displays usage information  
✅ **List Works**: `--list` shows available documents  

## Example Session

Here's what a typical session looks like:

```bash
$ cd friendly-outlaw
$ swift build
Building for debugging...
[...build output...]
Build complete! (15.93s)

$ swift run WritersAppCLI
╔══════════════════════════════════════╗
║     Writers App with Templates       ║
║   Swift Edition - Productivity Plus  ║
╚══════════════════════════════════════╝

ⓘ AI features disabled (set ANTHROPIC_API_KEY to enable)
✓ Claude Memory plugin enabled

Main Menu:
1. Browse Templates
2. Create Document from Template
3. Create Blank Document
4. View All Documents
5. View Statistics
[... more options ...]

Enter your choice:
```

## What's Available

This Writers App provides:

- **7+ Pre-built Templates**: Novel chapters, short stories, blog posts, articles, poetry, and more
- **Document Management**: Create, edit, search, and export documents
- **Word Count Tracking**: Automatic word counting and reading time estimation
- **Statistics & Analytics**: Track your writing progress
- **AI Writing Assistant**: Continue writing, improve text, generate ideas (with API key)
- **Multiple Export Formats**: Markdown, HTML, plain text
- **Productivity Features**: Focus sessions, writing goals, streak tracking
- **Memory Plugin**: Store and retrieve writing-related memories

## Next Steps

1. **Browse Templates**: Option 1 in the main menu
2. **Create Your First Document**: Option 2 or 3
3. **Explore Features**: Try different menu options
4. **Set Up AI**: Add your Anthropic API key for AI features
5. **Read Full Documentation**: Check README.md for comprehensive details

## Troubleshooting

### Build Fails on Linux

Install SQLite3 development libraries:

```bash
# Ubuntu/Debian
sudo apt-get install libsqlite3-dev

# Fedora/RHEL
sudo dnf install sqlite-devel
```

### Swift Not Found

Download and install Swift from https://swift.org/download/

### Permission Denied on run.sh

Make the script executable:

```bash
chmod +x run.sh
```

## Summary

The project **opens** by navigating to the directory, and **runs** by executing:

```bash
swift build && swift run WritersAppCLI
```

or simply:

```bash
./run.sh
```

That's it! You now have a working Writers App ready to use. 📝
