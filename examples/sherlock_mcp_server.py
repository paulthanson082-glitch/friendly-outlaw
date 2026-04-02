#!/usr/bin/env python3
"""
Sherlock MCP Server - Model Context Protocol wrapper for Sherlock
Enables friendly-outlaw and other MCP clients to use Sherlock tools.

Installation:
    pip install sherlock-project mcp

Usage:
    python sherlock_mcp_server.py

Configuration in Claude client:
    {
        "mcpServers": {
            "sherlock": {
                "command": "python",
                "args": ["path/to/sherlock_mcp_server.py"]
            }
        }
    }
"""

import json
import subprocess
import asyncio
import tempfile
import os
from typing import Any, Dict, List
from pathlib import Path

try:
    from mcp.server import Server
    from mcp.types import Tool, TextContent, ToolResult
except ImportError:
    print("Error: MCP library not found. Install with: pip install mcp")
    exit(1)

# Initialize MCP server
server = Server("sherlock-mcp")

# Sherlock executable path (can be overridden)
SHERLOCK_CMD = os.environ.get("SHERLOCK_CMD", "sherlock")
DEFAULT_TIMEOUT = int(os.environ.get("SHERLOCK_TIMEOUT", "60"))

# Define Sherlock tools for MCP
SHERLOCK_TOOLS = [
    {
        "name": "search_username",
        "description": """Search for a username across 400+ social networks using Sherlock.
Returns a list of platforms where the username was found.""",
        "inputSchema": {
            "type": "object",
            "properties": {
                "username": {
                    "type": "string",
                    "description": "Username to search for (e.g., 'alex_chen', 'character_name')"
                },
                "timeout": {
                    "type": "integer",
                    "description": "Timeout in seconds for the search (default: 60)",
                    "default": 60
                },
                "sites": {
                    "type": "array",
                    "items": {"type": "string"},
                    "description": "Specific sites to check (e.g., ['Twitter', 'GitHub', 'Instagram']). Leave empty for all sites."
                },
                "output_format": {
                    "type": "string",
                    "enum": ["json", "text"],
                    "description": "Output format for results",
                    "default": "json"
                },
                "print_found_only": {
                    "type": "boolean",
                    "description": "Only show platforms where username was found (default: true)",
                    "default": True
                }
            },
            "required": ["username"]
        }
    },
    {
        "name": "batch_search",
        "description": """Search multiple usernames in batch.
Returns results for each username searched.""",
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
                "sites": {
                    "type": "array",
                    "items": {"type": "string"},
                    "description": "Specific sites to check for all usernames"
                }
            },
            "required": ["usernames"]
        }
    },
    {
        "name": "list_supported_sites",
        "description": """List all supported social networks that Sherlock can search.
Returns the complete list of 400+ platforms.""",
        "inputSchema": {
            "type": "object",
            "properties": {
                "search_term": {
                    "type": "string",
                    "description": "Optional: filter sites by name (e.g., 'twitter' returns Twitter sites)"
                }
            }
        }
    },
    {
        "name": "verify_username_availability",
        "description": """Check if a username is available on major platforms.
Quick check across popular networks (Twitter, GitHub, Instagram, etc.).""",
        "inputSchema": {
            "type": "object",
            "properties": {
                "username": {
                    "type": "string",
                    "description": "Username to verify"
                },
                "major_platforms_only": {
                    "type": "boolean",
                    "description": "Check only major platforms (faster)",
                    "default": True
                }
            },
            "required": ["username"]
        }
    }
]

# Major platforms for quick checks
MAJOR_PLATFORMS = [
    "Twitter",
    "GitHub",
    "LinkedIn",
    "Instagram",
    "TikTok",
    "Facebook",
    "Reddit",
    "YouTube",
    "Medium",
    "Twitch",
    "Discord",
    "Amazon",
    "Goodreads",
    "DeviantArt",
    "Patreon"
]


async def search_username(
    username: str,
    timeout: int = DEFAULT_TIMEOUT,
    sites: List[str] = None,
    output_format: str = "json",
    print_found_only: bool = True
) -> Dict[str, Any]:
    """
    Search for a username across supported social networks using the sherlock CLI.
    
    Parameters:
        username (str): The username to search for.
        timeout (int): Maximum time in seconds to allow the sherlock process to run.
        sites (List[str] | None): If provided, restrict the search to these site identifiers.
        output_format (str): Desired output format; `"json"` attempts to read structured results from a temporary JSON file, otherwise raw text output is returned.
        print_found_only (bool): If true, include only sites where the username was found.
    
    Returns:
        Dict[str, Any]: A result dictionary. On success with JSON output: contains keys
            - "success": True,
            - "username": the queried username,
            - "results": parsed JSON data,
            - "format": "json".
        For text output or JSON fallback: contains keys
            - "success": True if the sherlock process exited with code 0, False otherwise,
            - "username": the queried username,
            - "output": sherlock's stdout,
            - "errors": sherlock's stderr when the process failed, otherwise None,
            - "format": "text".
        On failures (timeout, missing executable, or other errors) the dictionary contains
            - "success": False and one or more of "error", "recommendation", and "env_var" with human-readable messages describing the problem.
    """

    try:
        # Build command
        cmd = [SHERLOCK_CMD, username]

        # Add timeout
        cmd.extend(["--timeout", str(timeout)])

        # Add specific sites if provided
        if sites:
            for site in sites:
                cmd.extend(["--site", site])

        # Add output preference
        if print_found_only:
            cmd.append("--print-found")

        # Run with temp file for JSON output
        with tempfile.TemporaryDirectory() as tmpdir:
            json_file = os.path.join(tmpdir, "result.json")

            if output_format == "json":
                cmd.extend(["--json", json_file])

            # Execute Sherlock
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=timeout + 10
            )

            # Parse results
            if output_format == "json" and os.path.exists(json_file):
                try:
                    with open(json_file, "r") as f:
                        data = json.load(f)
                    return {
                        "success": True,
                        "username": username,
                        "results": data,
                        "format": "json"
                    }
                except json.JSONDecodeError:
                    pass

            # Return text output
            return {
                "success": result.returncode == 0,
                "username": username,
                "output": result.stdout,
                "errors": result.stderr if result.returncode != 0 else None,
                "format": "text"
            }

    except subprocess.TimeoutExpired:
        return {
            "success": False,
            "username": username,
            "error": f"Search timed out after {timeout} seconds",
            "recommendation": "Try with a longer timeout or limit to specific sites"
        }
    except FileNotFoundError:
        return {
            "success": False,
            "error": f"Sherlock not found at '{SHERLOCK_CMD}'",
            "recommendation": "Install Sherlock: pipx install sherlock-project",
            "env_var": "Set SHERLOCK_CMD environment variable to override path"
        }
    except Exception as e:
        return {
            "success": False,
            "username": username,
            "error": str(e)
        }


async def batch_search(
    usernames: List[str],
    timeout: int = DEFAULT_TIMEOUT,
    sites: List[str] = None
) -> Dict[str, Any]:
    """
    Run Sherlock searches for a list of usernames and aggregate the per-username results.
    
    Parameters:
        usernames (List[str]): Usernames to search, processed in order.
        timeout (int): Per-search timeout in seconds.
        sites (List[str] | None): If provided, restrict each search to these site identifiers; if None, searches all supported sites.
    
    Returns:
        dict: Aggregated batch result with keys:
            - batch_size (int): Number of usernames processed.
            - timeout (int): Timeout value used for each search.
            - sites_filter (List[str] | None): The sites filter passed through.
            - results (Dict[str, Any]): Mapping of username to that username's search result object (as returned by `search_username`).
    """

    results = {
        "batch_size": len(usernames),
        "timeout": timeout,
        "sites_filter": sites,
        "results": {}
    }

    for i, username in enumerate(usernames, 1):
        print(f"Searching {i}/{len(usernames)}: {username}", file=__import__('sys').stderr)

        results["results"][username] = await search_username(
            username,
            timeout=timeout,
            sites=sites,
            output_format="json"
        )

        # Small delay between requests to avoid rate limiting
        if i < len(usernames):
            await asyncio.sleep(1)

    return results


async def list_supported_sites(search_term: str = None) -> Dict[str, Any]:
    """
    Return a list of site identifiers that the installed Sherlock CLI advertises, optionally filtered by a case-insensitive substring.
    
    Parameters:
        search_term (str, optional): Case-insensitive substring to filter site names. If omitted, all discovered sites are returned.
    
    Returns:
        dict: A dictionary with the following keys:
            - success (bool): `True` when site extraction succeeded, `False` on error.
            - total_sites (int): Number of sites included in `sites`.
            - sites (List[str]): Discovered (and optionally filtered) site identifiers.
            - search_filter (str|None): The provided `search_term`, or `None` if not supplied.
            - error (str, optional): Present only when `success` is `False`, containing the error message.
            - recommendation (str, optional): Present only on error with guidance to run `sherlock --help`.
    """

    try:
        result = subprocess.run(
            [SHERLOCK_CMD, "--help"],
            capture_output=True,
            text=True
        )

        # Extract site list from help text
        help_text = result.stdout
        sites = extract_sites_from_help(help_text)

        if search_term:
            sites = [s for s in sites if search_term.lower() in s.lower()]

        return {
            "success": True,
            "total_sites": len(sites),
            "sites": sites,
            "search_filter": search_term
        }

    except Exception as e:
        return {
            "success": False,
            "error": str(e),
            "recommendation": "Run 'sherlock --help' to see available sites"
        }


async def verify_username_availability(
    username: str,
    major_platforms_only: bool = True
) -> Dict[str, Any]:
    """
    Check if a username appears on selected platforms using a short Sherlock search.
    
    Parameters:
        username (str): The username to check.
        major_platforms_only (bool): If True, limit checks to the predefined MAJOR_PLATFORMS; if False, allow checking all supported sites.
    
    Returns:
        dict: Result object with these keys:
            - username (str): The checked username.
            - available (bool): `True` if the username was not found on checked platforms, `False` otherwise.
            - platforms_checked (str): `"major"` when `major_platforms_only` was True, `"all"` otherwise.
            - results (dict): When `available` is `True`, contains the parsed Sherlock JSON results (may be empty).
            - summary (str): When `available` is `True`, a human-readable summary of findings.
            - error (str): When `available` is `False`, contains an error message when available.
    """

    sites_to_check = MAJOR_PLATFORMS if major_platforms_only else None

    result = await search_username(
        username,
        timeout=30,  # Shorter timeout for quick check
        sites=sites_to_check,
        output_format="json",
        print_found_only=True
    )

    if result.get("success"):
        return {
            "username": username,
            "available": True,
            "platforms_checked": "major" if major_platforms_only else "all",
            "results": result.get("results", {}),
            "summary": format_availability_summary(result)
        }
    else:
        return {
            "username": username,
            "available": False,
            "error": result.get("error"),
            "platforms_checked": "major" if major_platforms_only else "all"
        }


def extract_sites_from_help(help_text: str) -> List[str]:
    """
    Parse Sherlock CLI help text and return candidate site name tokens.
    
    Parameters:
        help_text (str): Full help output from the Sherlock CLI.
    
    Returns:
        List[str]: Candidate site name tokens extracted from the help text. This is a heuristic extraction and may include false positives or non-site tokens.
    """
    # This is a simplified extraction - could be improved
    sites = []
    for line in help_text.split('\n'):
        if '--site' in line and 'SITE_NAME' not in line:
            # Try to extract site name from help text
            parts = line.strip().split()
            for part in parts:
                if part and not part.startswith('-'):
                    sites.append(part)
    return sites


def format_availability_summary(result: Dict[str, Any]) -> str:
    """
    Produce a human-readable summary of where a username was found from a Sherlock-style search result.
    
    Parameters:
        result (Dict[str, Any]): Search result object expected to contain a "results" key whose value is a mapping of platform names to findings (or an empty mapping).
    
    Returns:
        A summary string: `"Username not found on any checked platform (good availability!)"` when no platforms report a match; `"Username found on: <platform1, platform2, ...>"` when matches are present; or `"Unable to summarize results"` if the input cannot be summarized.
    """

    try:
        found = result.get("results", {})
        total = len(found)

        if total == 0:
            return "Username not found on any checked platform (good availability!)"
        else:
            platforms = ", ".join(found.keys()) if isinstance(found, dict) else "multiple platforms"
            return f"Username found on: {platforms}"
    except:
        return "Unable to summarize results"


@server.call_tool()
async def call_tool(name: str, arguments: Dict[str, Any]) -> ToolResult:
    """
    Dispatches an MCP tool invocation to the matching handler and returns a ToolResult representing the outcome.
    
    Parameters:
        name (str): The tool name to invoke (e.g., "search_username", "batch_search",
            "list_supported_sites", "verify_username_availability").
        arguments (Dict[str, Any]): Tool-specific arguments to pass to the handler.
    
    Returns:
        ToolResult: On success, contains a single text content item with the JSON-serialized
        handler result and `isError=False`. If the tool name is unknown or an exception
        occurs while handling the call, contains a text error message and `isError=True`.
    """

    try:
        if name == "search_username":
            result = await search_username(**arguments)
        elif name == "batch_search":
            result = await batch_search(**arguments)
        elif name == "list_supported_sites":
            result = await list_supported_sites(**arguments)
        elif name == "verify_username_availability":
            result = await verify_username_availability(**arguments)
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
            content=[TextContent(type="text", text=f"Error calling tool '{name}': {str(e)}")],
            isError=True
        )


@server.list_tools()
async def list_tools() -> List[Tool]:
    """List available tools"""
    return [Tool(**tool) for tool in SHERLOCK_TOOLS]


async def main():
    """
    Start and run the Sherlock MCP server until shutdown.
    
    Verifies the configured Sherlock executable (logging a warning if verification fails), writes startup status and the available tools to stderr, enters the server context, and waits for shutdown.
    """

    # Verify Sherlock installation
    try:
        result = subprocess.run(
            [SHERLOCK_CMD, "--version"],
            capture_output=True,
            text=True,
            timeout=5
        )
        if result.returncode == 0:
            version_info = result.stdout.strip()
            print(f"✓ Sherlock found: {version_info}", file=__import__('sys').stderr)
        else:
            print(f"Warning: Sherlock may not be properly installed", file=__import__('sys').stderr)
    except Exception as e:
        print(f"Warning: Cannot verify Sherlock installation: {e}", file=__import__('sys').stderr)

    print("Sherlock MCP Server starting...", file=__import__('sys').stderr)
    print("Available tools:", file=__import__('sys').stderr)
    for tool in SHERLOCK_TOOLS:
        print(f"  - {tool['name']}: {tool['description'].split(chr(10))[0]}", file=__import__('sys').stderr)
    print("", file=__import__('sys').stderr)

    async with server:
        print("Sherlock MCP Server ready. Awaiting connections...", file=__import__('sys').stderr)
        await server.wait_for_shutdown()


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\nShutdown requested", file=__import__('sys').stderr)
    except Exception as e:
        print(f"Error: {e}", file=__import__('sys').stderr)
        exit(1)
