# Sherlock Integration Examples

Practical examples of using Sherlock with friendly-outlaw for character research, author verification, and social media analysis.

## Table of Contents

1. [Character Social Media Research](#character-social-media-research)
2. [Author Pseudonym Verification](#author-pseudonym-verification)
3. [Batch Author Analysis](#batch-author-analysis)
4. [Social Media Profile Study](#social-media-profile-study)
5. [Python MCP Server Example](#python-mcp-server-example)
6. [Swift Plugin Integration](#swift-plugin-integration)

---

## Character Social Media Research

### Scenario

You're writing a tech thriller and need to create an authentic social media profile for your main character, a cybersecurity researcher named "Alex Chen". You want to:
1. Verify the username is realistic
2. See which platforms the username is available on
3. Research similar usernames to understand naming patterns

### Workflow

```bash
# Step 1: Search for your character's intended username
sherlock "alex_chen_cybersec" --print-found --timeout 45

# Step 2: Export results to CSV for analysis
sherlock "alex_chen_cybersec" --csv -o character_research/alex_chen.csv

# Step 3: Try alternative usernames to find available options
sherlock "alexchen_cyber" --print-found
sherlock "alex.chen.sec" --print-found
sherlock "cybersec_alex" --print-found

# Step 4: Open your character document in friendly-outlaw
./run.sh --open "Character: Alex Chen"
```

### Document Template Integration

Create a character document with Sherlock findings:

```markdown
# Character Profile: Alex Chen

## Basic Information
- **Role**: Cybersecurity Researcher
- **Age**: 32
- **Background**: MIT graduate, 10 years in cybersecurity

## Digital Footprint

### Primary Username: alex_chen_cybersec

**Sherlock Research Results:**
- **Available on**: Twitter, GitHub, LinkedIn, Dev.to, Medium
- **Not available on**: Facebook, Instagram, Reddit, TikTok
- **Recommended profile**: GitHub (most credible for a researcher)

### Social Media Strategy

**GitHub Profile**
- Repository: Open-source security tools
- Contributions: Regular commits, active in security community
- Bio: "Security researcher. Open source advocate."

**Twitter/X**
- Tweets about: Zero-day vulnerabilities, cybersecurity news, research findings
- Engagement: 5K followers, active in InfoSec community
- Posting frequency: 2-3 times per week

**LinkedIn**
- Profile: Corporate security research background
- Endorsements: Python, C++, Network Security
- Recommendations: From colleagues at major tech companies

**Medium**
- Articles on: Advanced threat detection, malware analysis techniques
- Audience: Security professionals and researchers
- Publication frequency: 1-2 articles per month

## Character Arc Connection
- Username availability reflects character's early-career anonymity
- Presence on technical platforms (GitHub, Dev.to) shows focus on credibility over fame
- Limited social media presence explains why protagonist is hard to find in opening act
```

---

## Author Pseudonym Verification

### Scenario

You're publishing under the pen name "Morgan Azure" and want to:
1. Check if the name is available across platforms
2. See which platforms you should establish a presence on
3. Avoid competing with an already-famous author using the same name

### Workflow

```bash
# Step 1: Check overall availability
sherlock "morgan_azure" --csv -o pseudonym_research/morgan_azure.csv

# Step 2: Check variations
sherlock "morganazure" --print-found
sherlock "morgan.azure" --print-found
sherlock "morgan_azure_author" --print-found

# Step 3: Check for existing well-known authors
sherlock "morgan_azure" --print-found

# Step 4: Create your author profile document
./run.sh --open "Author: Morgan Azure"
```

### Document Integration

```markdown
# Author Profile: Morgan Azure (Pen Name)

## Pseudonym Research Summary

### Primary Username: morgan_azure

**Availability Status:**
```
Platform          | Status      | Priority
------------------|-------------|----------
Twitter           | Available   | High (build author platform)
Instagram         | Available   | Medium (author photos)
TikTok            | Available   | Medium (book promotion)
Facebook          | Available   | Low
LinkedIn          | Taken       | N/A
Amazon            | Available   | Critical (author page)
Goodreads         | Available   | Critical (book listings)
Medium            | Available   | High (author essays)
Substack          | Available   | High (newsletters)
```

### Recommended Platform Strategy

**Critical Presence (establish immediately):**
- Amazon Author Central
- Goodreads Author Page
- Official Website

**High Priority (within 6 months):**
- Twitter (@morgan_azure)
- Medium (morgan_azure)
- Substack (Morgan Azure newsletter)

**Medium Priority (optional but valuable):**
- Instagram (@morgan_azure)
- TikTok (@morgan_azure - BookTok presence)
- LinkedIn

### Brand Consistency
- Use `morgan_azure` consistently across all platforms for brand recognition
- Email: contact@morganazure.com
- Website domain: morganazure.com

## Cross-Promotion Strategy
- Twitter: Share chapter releases, writing journey
- Medium: Long-form essays about storytelling
- Substack: Newsletter with exclusive content
- Instagram: Author aesthetic, quotes, behind-the-scenes
```

---

## Batch Author Analysis

### Scenario

You're writing a book in the fantasy romance genre and want to research 5 successful authors in your space to understand their social media presence, engagement patterns, and platform strategies.

### Shell Script

```bash
#!/bin/bash
# research_fantasy_romance_authors.sh

# Define authors to research
AUTHORS=(
    "sarah_j_maas"
    "naomi_novik"
    "jennifer_l_armentrout"
    "elise_kova"
    "raven_kennedy"
)

# Create output directory
OUTPUT_DIR="research/fantasy_romance_authors"
mkdir -p "$OUTPUT_DIR"

echo "=== Fantasy Romance Author Research ==="
echo "Analyzing: ${AUTHORS[@]}"
echo ""

# Search each author
for author in "${AUTHORS[@]}"; do
    echo "Researching: $author"
    
    # Run Sherlock and save results
    sherlock "$author" \
        --csv \
        --timeout 45 \
        --print-found \
        -o "$OUTPUT_DIR/${author}_platforms.csv"
    
    # Also get JSON for parsing
    sherlock "$author" \
        --json "$OUTPUT_DIR/${author}_data.json" \
        --timeout 45
    
    echo "✓ Completed: $author"
    echo ""
done

echo "=== Research Complete ==="
echo "Results saved to: $OUTPUT_DIR/"
echo ""
echo "Files created:"
ls -1 "$OUTPUT_DIR/"
```

### Running the Script

```bash
chmod +x research_fantasy_romance_authors.sh
./research_fantasy_romance_authors.sh
```

### Analyzing Results

```bash
# View CSV results
cat research/fantasy_romance_authors/sarah_j_maas_platforms.csv

# Count which platforms are most popular
grep -h "https://" research/fantasy_romance_authors/*.csv | \
    cut -d'/' -f3 | \
    sort | uniq -c | sort -rn

# Create comparison document
./run.sh --open "Fantasy Romance Author Analysis"
```

### Document Template for Analysis

```markdown
# Fantasy Romance Author Research

## Author Comparison Matrix

| Author | Twitter | TikTok | Instagram | Goodreads | Amazon | Website |
|--------|---------|--------|-----------|-----------|--------|---------|
| Sarah J. Maas | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Naomi Novik | ✓ | ✗ | ✓ | ✓ | ✓ | ✓ |
| Jennifer L. Armentrout | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Elise Kova | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Raven Kennedy | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |

## Platform Strategy Insights

### Most Popular: Instagram & TikTok
- 100% of analyzed authors have Instagram
- 80% have TikTok presence (BookTok trend)
- Primarily used for: Visual book promotion, behind-the-scenes content

### Essential: Goodreads & Amazon
- All authors maintain Goodreads author pages
- All have Amazon author central
- Critical for: Book discovery, reader reviews, series management

### Engagement: Twitter
- 100% active on Twitter
- Used for: Real-time engagement, news, community building

## Recommendations for New Fantasy Romance Author

**Must Have:**
1. Goodreads Author Page
2. Amazon Author Central
3. Instagram Account (@yourpennamehere)
4. Official Website

**Should Have:**
1. Twitter Account
2. TikTok Account (BookTok growth potential)
3. Substack (Exclusive content)

**Nice to Have:**
1. Pinterest (Visual marketing for book covers)
2. YouTube (Book trailers, author interviews)
3. Facebook (Fan groups/community)
```

---

## Social Media Profile Study

### Scenario

You need to write authentic dialogue and behavior for a character who is an Instagram influencer in your contemporary romance novel. You want to study real influencer profiles and their communication style.

### Research Workflow

```bash
# Step 1: Find popular lifestyle/wellness influencers
sherlock "wellness_influencer_1" --print-found --site Instagram --site TikTok
sherlock "lifestyle_creator_23" --print-found --site Instagram
sherlock "mindful_living_coach" --print-found --site Instagram --site YouTube

# Step 2: Analyze their username patterns
sherlock "john_doe_coaching" --print-found
sherlock "yoga_with_jane" --print-found
sherlock "wellness_coach_mike" --print-found

# Step 3: Export findings
sherlock "influencer_research" --json -o character_research/influencer_profiles.json

# Step 4: Study actual profiles (not via Sherlock, but informed by findings)
# Visit the platforms found by Sherlock and study:
# - Bio length and style
# - Posting frequency
# - Caption length and tone
# - Hashtag strategy
# - Engagement patterns
```

### Character Development Document

```markdown
# Character: Madison Rivers (Instagram Influencer)

## Digital Persona

### Username & Presence
**Sherlock Research Found:**
- Username: madison_wellness_coach
- Available on: Instagram (verified), TikTok, YouTube, Pinterest, Substack
- Competitor status: Similar usernames exist but not exact match

### Instagram Profile Strategy

**Bio (150 characters)**
```
Wellness Coach 🧘‍♀️ | Yoga & Mindfulness
✨ DM for coaching inquiries
Link in bio ⬇️
```

**Content Pillars (20% each):**
1. Yoga tutorials (morning/evening routines)
2. Wellness tips (nutrition, sleep, mental health)
3. Personal life (relatable struggles, growth journey)
4. Community engagement (followers' questions, challenges)
5. Sponsored content (income source)

**Posting Schedule:**
- Stories: Daily (5-10 per day)
- Feed posts: 4-5 times per week
- Reels: 2-3 per week (high engagement)

### Character Voice

**Caption Style:**
- Authentic and vulnerable
- Motivational but not preachy
- Conversational tone
- Uses relevant emojis (3-5 per caption)
- Calls to action (comments, DMs, saves)

**Example Caption:**
```
Nothing profound here, just real: Some days I don't want to do yoga.
Some mornings I skip meditation. And that's okay.

Today's lesson: Progress isn't about perfection. It's about showing
up for yourself, even when it's messy. 

What's one thing you're showing up for today? Drop it in the
comments 👇 (Not judging. Not comparing. Just connecting.)

#WellnessJourney #YogaCommunity #MindfulLiving
```

### Engagement Metrics (fictional character goals)
- Current followers: 47K
- Engagement rate: 4.2%
- Growing at: ~200 followers/week
- Primary audience: Women 25-40, interested in wellness/yoga
```

---

## Python MCP Server Example

Create a Python MCP server that wraps Sherlock for integration with friendly-outlaw:

### sherlock_mcp_server.py

```python
#!/usr/bin/env python3
"""
Sherlock MCP Server - Model Context Protocol wrapper for Sherlock
Enables friendly-outlaw and other MCP clients to use Sherlock tools.
"""

import json
import subprocess
import asyncio
from typing import Any, Dict, List
from mcp.server import Server
from mcp.types import Tool, TextContent, ToolResult

# Initialize MCP server
server = Server("sherlock-mcp")

# Define Sherlock tools for MCP
SHERLOCK_TOOLS = [
    {
        "name": "search_username",
        "description": "Search for a username across 400+ social networks",
        "inputSchema": {
            "type": "object",
            "properties": {
                "username": {
                    "type": "string",
                    "description": "Username to search for"
                },
                "timeout": {
                    "type": "integer",
                    "description": "Timeout in seconds (default: 60)",
                    "default": 60
                },
                "sites_only": {
                    "type": "string",
                    "description": "Comma-separated list of sites to check (e.g., 'Twitter,GitHub,Instagram')"
                },
                "output_format": {
                    "type": "string",
                    "enum": ["text", "csv", "json"],
                    "description": "Output format",
                    "default": "json"
                },
                "print_found": {
                    "type": "boolean",
                    "description": "Only print found results",
                    "default": True
                }
            },
            "required": ["username"]
        }
    },
    {
        "name": "batch_search",
        "description": "Search multiple usernames in batch",
        "inputSchema": {
            "type": "object",
            "properties": {
                "usernames": {
                    "type": "array",
                    "items": {"type": "string"},
                    "description": "List of usernames to search"
                },
                "timeout": {
                    "type": "integer",
                    "description": "Timeout per search in seconds",
                    "default": 60
                },
                "output_format": {
                    "type": "string",
                    "enum": ["csv", "json"],
                    "default": "csv"
                }
            },
            "required": ["usernames"]
        }
    },
    {
        "name": "list_sites",
        "description": "List all supported Sherlock sites",
        "inputSchema": {
            "type": "object",
            "properties": {}
        }
    }
]

async def search_username(username: str, timeout: int = 60, 
                         sites_only: str = None, 
                         output_format: str = "json",
                         print_found: bool = True) -> Dict[str, Any]:
    """Search for username across social networks"""
    
    cmd = ["sherlock", username, "--timeout", str(timeout)]
    
    if print_found:
        cmd.append("--print-found")
    
    if sites_only:
        for site in sites_only.split(","):
            cmd.extend(["--site", site.strip()])
    
    if output_format == "json":
        cmd.append("--json")
        cmd.append("/tmp/sherlock_result.json")
    elif output_format == "csv":
        cmd.append("--csv")
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout + 10)
        
        if output_format == "json":
            with open("/tmp/sherlock_result.json", "r") as f:
                return json.load(f)
        else:
            return {"results": result.stdout, "success": result.returncode == 0}
    except subprocess.TimeoutExpired:
        return {"error": "Search timed out", "username": username}
    except Exception as e:
        return {"error": str(e), "username": username}

async def batch_search(usernames: List[str], timeout: int = 60,
                       output_format: str = "csv") -> Dict[str, Any]:
    """Search multiple usernames"""
    
    results = {}
    for username in usernames:
        results[username] = await search_username(
            username, 
            timeout=timeout,
            output_format=output_format
        )
        # Small delay between requests
        await asyncio.sleep(1)
    
    return results

async def list_sites() -> Dict[str, Any]:
    """List all supported Sherlock sites"""
    
    try:
        result = subprocess.run(
            ["sherlock", "--help"],
            capture_output=True,
            text=True
        )
        return {"help_text": result.stdout}
    except Exception as e:
        return {"error": str(e)}

@server.call_tool()
async def call_tool(name: str, arguments: Dict[str, Any]) -> ToolResult:
    """Handle tool calls from MCP clients"""
    
    try:
        if name == "search_username":
            result = await search_username(**arguments)
        elif name == "batch_search":
            result = await batch_search(**arguments)
        elif name == "list_sites":
            result = await list_sites()
        else:
            return ToolResult(
                content=[TextContent(type="text", text=f"Unknown tool: {name}")],
                isError=True
            )
        
        return ToolResult(
            content=[TextContent(type="text", text=json.dumps(result, indent=2))],
            isError=False
        )
    except Exception as e:
        return ToolResult(
            content=[TextContent(type="text", text=f"Error: {str(e)}")],
            isError=True
        )

@server.list_tools()
async def list_tools() -> List[Tool]:
    """List available tools"""
    return [Tool(**tool) for tool in SHERLOCK_TOOLS]

async def main():
    """Start the MCP server"""
    async with server:
        print("Sherlock MCP Server started. Awaiting connections...")
        await server.wait_for_shutdown()

if __name__ == "__main__":
    asyncio.run(main())
```

### Usage in friendly-outlaw

Configure in `.claude/settings.json`:

```json
{
  "mcpServers": {
    "sherlock": {
      "command": "python",
      "args": ["examples/sherlock_mcp_server.py"],
      "env": {
        "PATH": "/usr/local/bin:/usr/bin"
      }
    }
  }
}
```

---

## Swift Plugin Integration

### SherlockPlugin.swift

```swift
import Foundation
import WritersApp

/// Sherlock plugin for username research and social media verification
public class SherlockPlugin: Plugin {
    public let id: String = "sherlock-username-lookup"
    public let name: String = "Sherlock Username Lookup"
    public let version: String = "1.0.0"
    public var capabilities: [PluginCapability] = [.tools, .resources]
    public var isEnabled: Bool = false
    
    private let timeout: TimeInterval = 60
    
    public func initialize() async throws {
        isEnabled = true
        print("✓ Sherlock Plugin initialized")
    }
    
    public func shutdown() async throws {
        isEnabled = false
        print("✓ Sherlock Plugin shut down")
    }
    
    public func execute(action: PluginAction) async throws -> Any {
        guard isEnabled else {
            throw PluginError.executionFailed("Plugin not initialized")
        }
        
        switch action.type {
        case .executeTool:
            return try await executeTool(name: action.name, parameters: action.parameters)
        default:
            throw PluginError.actionNotSupported
        }
    }
    
    private func executeTool(name: String, parameters: [String: Any]) async throws -> String {
        switch name {
        case "search_username":
            let username = parameters["username"] as? String ?? ""
            let timeout = parameters["timeout"] as? TimeInterval ?? self.timeout
            return try await searchUsername(username, timeout: timeout)
            
        case "batch_search":
            let usernames = parameters["usernames"] as? [String] ?? []
            return try await batchSearch(usernames)
            
        default:
            throw PluginError.executionFailed("Unknown tool: \(name)")
        }
    }
    
    private func searchUsername(_ username: String, timeout: TimeInterval) async throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/local/bin/sherlock")
        process.arguments = [
            username,
            "--json",
            "--timeout", String(Int(timeout)),
            "--print-found"
        ]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        
        process.waitUntilExit()
        
        return output
    }
    
    private func batchSearch(_ usernames: [String]) async throws -> String {
        var results: [String: Any] = [:]
        
        for username in usernames {
            let result = try await searchUsername(username, timeout: timeout)
            results[username] = result
            
            // Small delay between requests
            try await Task.sleep(nanoseconds: 1_000_000_000)
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: results)
        return String(data: jsonData, encoding: .utf8) ?? ""
    }
}
```

---

## Advanced Usage Tips

### 1. Integrate with AI Features

```bash
# Search for username
sherlock "character_name" --json -o /tmp/sherlock_result.json

# Use findings in AI-assisted character development
./run.sh --open "Character Development"
```

Then ask the AI in your writing session:

```
Given that the username "character_name" is available on: [platforms from Sherlock]
and already taken on: [other platforms], create a realistic social media profile
that explains these presence patterns for my character.
```

### 2. Create Comparison Documents

```bash
# Compare multiple character names
for name in alice bob charlie; do
    sherlock "$name" --csv -o "comparison/$name.csv"
done

# Use in friendly-outlaw for side-by-side comparison
```

### 3. Privacy-Focused Searches

```bash
# Use Tor for privacy
sherlock username --tor

# Or use proxy
sherlock username --proxy socks5://127.0.0.1:1080
```

### 4. Real-Time Availability Check

```bash
# Create a function in your shell
check_username() {
    echo "Checking: $1"
    sherlock "$1" --print-found --timeout 30 --no-color
    echo "---"
}

# Quick check during character naming
check_username "alex_chen"
check_username "alex_chen_tech"
check_username "alextchen"
```

---

## Troubleshooting

### Sherlock Timeout

```bash
# Increase timeout
sherlock username --timeout 120

# Or limit to specific sites
sherlock username --site GitHub --site Twitter --timeout 30
```

### No Results

```bash
# Enable verbose output
sherlock username --verbose

# Use local data
sherlock username --local

# Check specific platform
sherlock username --site Instagram --verbose
```

### Integration Issues

```bash
# Verify Sherlock installation
which sherlock
sherlock --version

# Test basic functionality
sherlock "test_username_xyz" --print-found --timeout 30
```

---

## More Information

- [SHERLOCK.md](../SHERLOCK.md) - Main Sherlock integration documentation
- [Sherlock GitHub](https://github.com/sherlock-project/sherlock) - Official repository
- [friendly-outlaw README](../README.md) - Main project documentation
