# Quick Start Guide - Running the Writers App

This guide will help you quickly get the Writers App CLI up and running.

## Prerequisites

- Swift 5.9+ installed
- macOS 13+ or Linux with Swift support

## Quick Start

### Option 1: Using the run script (Easiest)

```bash
# Make the script executable (first time only)
chmod +x run.sh

# Run the application
./run.sh
```

### Option 2: Manual Build and Run

```bash
# Build the application
swift build

# Run the CLI
swift run WritersAppCLI
```

### Option 3: Build Release Version

For better performance, build a release version:

```bash
# Build release version
swift build -c release

# Run the release binary directly
.build/release/WritersAppCLI
```

## Enabling AI Features (Optional)

To use AI-powered writing assistance features:

1. Get an API key from [Anthropic Console](https://console.anthropic.com)
2. Set the environment variable:

```bash
export ANTHROPIC_API_KEY="your-api-key-here"
```

3. Run the application - AI features will be automatically enabled

## Features Available

When you run the application, you'll have access to:

### Core Features
1. **Browse Templates** - View 7+ professional writing templates
2. **Create Documents** - From templates or blank
3. **View Documents** - See all your created documents
4. **Statistics** - Track your writing progress
5. **Search** - Find templates and documents quickly

### AI Features (with API key)
- Continue Writing
- Improve Document
- Generate Title Ideas
- Analyze Document
- Brainstorm Ideas
- Develop Character
- Generate Outline

### Memory Plugin
- Store and retrieve writing-related memories
- Search through saved memories
- Memory statistics

### Productivity Features
- Focus Sessions (Pomodoro, Writing Sprint, Deep Work)
- Daily Writing Goals
- Writing Streaks
- Progress Tracking
- Productivity Reports

## Testing

Run the test suite to verify everything works:

```bash
swift test
```

All 176 tests should pass successfully.

## Example Session

Here's what a typical session looks like:

```
1. Start the application
2. Browse available templates
3. Create a document from a template (e.g., Short Story)
4. Start a focus session (e.g., 25-minute Pomodoro)
5. View your statistics
6. Exit the application
```

## Troubleshooting

### Build Issues

If you encounter build errors:

```bash
# Clean build artifacts
swift package clean

# Rebuild
swift build
```

### AI Features Not Working

- Verify your API key is set: `echo $ANTHROPIC_API_KEY`
- Make sure you have an active internet connection
- Check that your API key is valid at console.anthropic.com

## Next Steps

- Read the main [README.md](README.md) for detailed documentation
- Check [DATABASE.md](DATABASE.md) for database features
- See [VSCODE_SETUP.md](VSCODE_SETUP.md) for development setup
- Explore [docs/](docs/) for additional guides

## Support

For issues or questions, please open an issue on the GitHub repository.

Happy Writing! 📝
