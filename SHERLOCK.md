# Sherlock Integration Guide

Sherlock is a powerful username reconnaissance tool that hunts down social media accounts across 400+ social networks. This guide explains how to integrate Sherlock with friendly-outlaw for character research, author verification, and social media profile discovery.

## Overview

Sherlock helps writers by:
- **Character Research**: Find existing social media profiles to study character archetypes and personas
- **Author Research**: Discover what other authors in your genre are doing on social media
- **Pseudonym Verification**: Check if a pen name or pseudonym is available or already taken
- **Username Availability**: Quickly verify username availability across multiple platforms
- **Profile Inspiration**: Study real profiles for authentic character social media presence in your stories

## Installation

### Using pipx (Recommended)

```bash
pipx install sherlock-project
```

### Using pip

```bash
pip install sherlock-project
```

### Using Docker

```bash
docker run -it --rm sherlock/sherlock
```

### Alternative Installation Methods

- **Homebrew** (macOS): `brew install sherlock-project`
- **Debian/Ubuntu**: Package available for Debian >= 13 and Ubuntu >= 22.10
- **Kali Linux**: `apt install sherlock-project`
- **BlackArch**: `pacman -S sherlock`

For more installation methods, see the [Sherlock Project GitHub](https://github.com/sherlock-project/sherlock).

## Quick Start

### Basic Usage

Search for a single username:

```bash
sherlock username123
```

Search for multiple usernames:

```bash
sherlock user1 user2 user3
```

### Output

Results are saved to individual text files (e.g., `username123.txt`) containing:
- Username
- Matching platform names
- URLs to found profiles
- Status code information

## Integration with friendly-outlaw

### Method 1: Using Sherlock as an MCP Server (Recommended)

The most seamless integration is through an MCP (Model Context Protocol) server wrapper around Sherlock. This allows the CLI to call Sherlock tools directly.

#### Setting Up the MCP Server

1. **Create a Sherlock MCP server** (see examples section below)
2. **Configure it in your `.claude` settings** or client configuration:

```json
{
  "mcpServers": {
    "sherlock": {
      "command": "python",
      "args": ["-m", "sherlock_mcp_server"],
      "env": {
        "SHERLOCK_TIMEOUT": "60",
        "SHERLOCK_VERIFY": "true"
      }
    }
  }
}
```

3. **Use Sherlock tools in the CLI** for character research

### Method 2: CLI Integration (Direct)

Run Sherlock independently and import results into your documents:

```bash
# Search for a character name or author
sherlock character_name -o character_profiles.txt

# The results can be imported into a document
./run.sh --open "Character Research"
```

### Method 3: Plugin-Based Integration

Create a Swift plugin wrapper that calls Sherlock as a subprocess. This approach allows tighter integration with the WritersApp API:

```swift
import WritersApp

// Pseudocode for a Sherlock plugin
class SherlockPlugin: Plugin {
    let id = "sherlock-username-lookup"
    let name = "Sherlock Username Lookup"
    
    func execute(action: PluginAction) async throws -> Any {
        if action.type == .executeTool && action.name == "search_username" {
            let username = action.parameters["username"] as? String ?? ""
            return try await searchUsername(username)
        }
        throw PluginError.actionNotSupported
    }
    
    private func searchUsername(_ username: String) async throws -> [String: Any] {
        // Call sherlock CLI and parse results
        // Return found platforms and URLs
    }
}
```

## Features and Capabilities

### Supported Output Formats

| Format | Command | Use Case |
|--------|---------|----------|
| Text File (default) | `sherlock user -o results.txt` | Easy to read, import into documents |
| CSV | `sherlock user --csv` | Import into spreadsheets, structured data |
| JSON | `sherlock user -j data.json` | API-friendly format, easy parsing |
| XLSX | `sherlock user --xlsx` | Microsoft Excel format |

### Advanced Options

```bash
# Search specific sites only
sherlock username --site Twitter --site Facebook --site Instagram

# Limit to NSFW sites
sherlock username --nsfw

# Use Tor for privacy
sherlock username --tor

# Use new Tor circuit per request
sherlock username --unique-tor

# Custom timeout (seconds)
sherlock username --timeout 120

# Use proxy
sherlock username --proxy socks5://127.0.0.1:1080

# Print only found results
sherlock username --print-found

# Print all results (including not found)
sherlock username --print-all

# No color output
sherlock username --no-color

# Browse results automatically
sherlock username --browse

# Use local data only (offline)
sherlock username --local
```

### Supported Platforms

Sherlock searches across 400+ social networks including:
- **Major Networks**: Twitter/X, Facebook, Instagram, TikTok, LinkedIn, Reddit
- **Creative Platforms**: DeviantArt, Pixiv, Behance, ArtStation
- **Writing Communities**: Medium, Substack, Patreon, Wattpad
- **Gaming & Tech**: Steam, GitHub, GitLab, StackOverflow, Twitch
- **Forum Communities**: Discord, Slack, Telegram
- **E-Commerce**: eBay, Amazon, Etsy
- **Video Platforms**: YouTube, Vimeo, Dailymotion
- **And many more...**

See `sherlock --help` for the full list of supported sites.

## Use Cases for Writers

### 1. Character Social Media Background

Create authentic social media profiles for fictional characters:

```bash
# Search for realistic username patterns
sherlock "john_developer_2023"
sherlock "jane_writes_novels"
sherlock "artist_alex_90s"
```

Use the results to understand which platforms the username would be available on, informing your character's digital footprint.

### 2. Author Pseudonym Research

Verify that your pen name isn't already taken:

```bash
sherlock "your_pen_name"
```

Check the CSV output to see which platforms have the username already registered.

### 3. Competitive Author Analysis

Research other authors in your genre:

```bash
# Search for known authors' usernames
sherlock "author_name" --print-found

# Export to CSV for analysis
sherlock "author_name" --csv
```

### 4. Writing Community Presence

Find active writing communities where authors participate:

```bash
# Search across writing-specific platforms
sherlock username --site Wattpad --site Medium --site Substack
```

### 5. Character Research for Realistic Dialogue

Study how real people present themselves on social media to write more authentic character voices:

```bash
# Search for various usernames to study profile patterns
sherlock programmer_username
sherlock artist_username
sherlock author_username
```

## Integration Examples

### Example 1: CSV Import for Character Database

```bash
# Export Sherlock results as CSV
sherlock "character_name" --csv -fo character_research/

# In friendly-outlaw, create a document from the CSV:
./run.sh --open "Character Social Media Database"
```

Then import the CSV data into your character template:

```markdown
# Character: {{character_name}}

## Social Media Presence
- Found on: [Import from Sherlock results]
- Available usernames: [Identify from Sherlock output]
- Competitor profiles: [Research similar usernames]
```

### Example 2: Batch Author Research

```bash
#!/bin/bash
# research_authors.sh - Batch research multiple authors

AUTHORS=("author1" "author2" "author3")
OUTPUT_DIR="author_research"

mkdir -p "$OUTPUT_DIR"

for author in "${AUTHORS[@]}"; do
    sherlock "$author" --csv -o "$OUTPUT_DIR/${author}_socials.csv"
done

echo "Research complete. Results in $OUTPUT_DIR/"
```

### Example 3: Real-time Character Username Validation

Create a rapid feedback loop during character creation:

```bash
# When developing a new character
read -p "Enter character name: " char_name

# Quickly check username availability
echo "Checking username availability for: $char_name"
sherlock "$char_name" --print-found --timeout 30

# Results help inform character background
```

## Integration with AI Features

Combine Sherlock with friendly-outlaw's AI features:

```swift
// Pseudocode: AI-assisted character creation with Sherlock
let app = WritersApp(aiConfiguration: aiConfig)

// 1. Generate character concept with AI
let character = try await app.developCharacter(
    characterConcept: "A software developer with a hidden past",
    context: context
)

// 2. Research realistic social media presence
let sherlockResults = try await searchSherlockUsername(
    username: character.username
)

// 3. Incorporate findings into character development
let enhancedCharacter = try await app.generateOutline(
    concept: "Social media presence for: \(character.name). Platforms found: \(sherlockResults.platforms)",
    context: context
)
```

## Performance Tips

### Optimize for Speed

```bash
# Set custom timeout for faster searches
sherlock username --timeout 30

# Search specific sites only (faster)
sherlock username --site Twitter --site GitHub

# Use local data for offline mode
sherlock username --local
```

### Use Tor for Privacy

```bash
# Single Tor circuit (faster)
sherlock username --tor

# New circuit per request (slower, more private)
sherlock username --unique-tor
```

### Batch Processing

```bash
# Search multiple usernames efficiently
sherlock user1 user2 user3 --timeout 30 -fo batch_results/
```

## API Reference

### Sherlock CLI Arguments

```bash
usage: sherlock [-h] [--version] [--verbose] [--folderoutput FOLDEROUTPUT]
                [--output OUTPUT] [--tor] [--unique-tor] [--csv] [--xlsx]
                [--site SITE_NAME] [--proxy PROXY_URL] [--json JSON_FILE]
                [--timeout TIMEOUT] [--print-all] [--print-found] [--no-color]
                [--browse] [--local] [--nsfw]
                USERNAMES [USERNAMES ...]

Positional Arguments:
  USERNAMES             One or more usernames to check

Optional Arguments:
  -h, --help            Show help message
  --version             Display version and dependencies
  --verbose, -v, -d     Extra debugging information
  --folderoutput -fo    Output folder for multiple usernames
  --output, -o          Output file for single username
  --tor, -t             Use Tor (requires Tor installed)
  --unique-tor, -u      New Tor circuit per request
  --csv                 Create CSV file output
  --xlsx                Create Excel file output
  --site SITE_NAME      Limit to specific sites (repeatable)
  --proxy PROXY_URL, -p Use HTTP proxy
  --json JSON_FILE      Load sites from JSON file
  --timeout TIMEOUT     Response timeout in seconds (default: 60)
  --print-all           Print all results (including not found)
  --print-found         Print only found results
  --no-color            Disable colored output
  --browse, -b          Open results in browser
  --local, -l           Use local data.json only
  --nsfw                Include NSFW sites
```

## Troubleshooting

### Sherlock Not Found

```bash
# Check if Sherlock is installed
which sherlock

# If not found, install via pipx
pipx install sherlock-project

# Verify installation
sherlock --version
```

### Timeout Issues

```bash
# Increase timeout for slow connections
sherlock username --timeout 120

# Or use local mode for offline searches
sherlock username --local
```

### No Results Found

```bash
# Enable verbose output to see what's happening
sherlock username --verbose

# Check specific sites
sherlock username --site Twitter --site GitHub

# Include NSFW sites if needed
sherlock username --nsfw
```

### Proxy Issues

```bash
# Test with custom proxy
sherlock username --proxy socks5://your-proxy:1080

# Use Tor as fallback
sherlock username --tor
```

## Related Documentation

- [README.md](README.md) - Main project documentation
- [PLUGIN_INTEGRATION.md](PLUGIN_INTEGRATION.md) - Plugin system guide (if available)
- [MCP.md](MCP.md) - Model Context Protocol integration (if available)

## Credits

- **Sherlock Project**: [GitHub](https://github.com/sherlock-project/sherlock)
- Original creator: Siddharth Dushantha
- License: MIT

## Contributing

To contribute Sherlock improvements to friendly-outlaw:

1. Test Sherlock integration with real character research
2. Document discovered workflows
3. Share findings via GitHub Issues or PRs
4. Suggest new use cases for writers

## License

This integration guide is part of friendly-outlaw, licensed under MIT.

The Sherlock Project is also licensed under MIT © Sherlock Project.
