"""
firecrawl_skill_generator.py
----------------------------
Generate a Claude Code skill file from any documentation URL using
Firecrawl's /agent endpoint.

Usage:
    FIRECRAWL_API_KEY="fc-..." python3 firecrawl_skill_generator.py \
        --url https://docs.example.com \
        --output ../.claude/skills/example.md

Requirements:
    pip install requests  (no Firecrawl SDK needed — plain HTTP)

Models:
    spark-1-mini  (default) — faster and 60% cheaper, good for most sites
    spark-1-pro             — better accuracy for large or complex docs
"""

import argparse
import json
import os
import sys
import time
import textwrap
from typing import Optional
import urllib.request
import urllib.error


# ---------------------------------------------------------------------------
# Schema that the Firecrawl agent must populate
# ---------------------------------------------------------------------------

SKILL_SCHEMA = {
    "type": "object",
    "properties": {
        "name": {
            "type": "string",
            "description": (
                "Kebab-case skill name used in the YAML frontmatter, "
                "e.g. 'stripe-payments' or 'firecrawl-scrape'."
            ),
        },
        "description": {
            "type": "string",
            "description": (
                "One-sentence frontmatter description that tells Claude Code "
                "when to trigger this skill. Start with an action verb."
            ),
        },
        "trigger_conditions": {
            "type": "array",
            "items": {"type": "string"},
            "description": (
                "3-6 example user phrases that should trigger this skill, "
                "e.g. 'scrape a URL', 'extract structured data from a page'."
            ),
        },
        "overview": {
            "type": "string",
            "description": "1-3 sentence overview of what the tool/service does.",
        },
        "steps": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "title": {"type": "string"},
                    "body": {
                        "type": "string",
                        "description": (
                            "Markdown body for this step. Include code blocks "
                            "with language identifiers where relevant."
                        ),
                    },
                },
                "required": ["title", "body"],
            },
            "description": "Ordered list of steps a developer must follow.",
        },
        "key_endpoints_or_methods": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "name": {"type": "string"},
                    "description": {"type": "string"},
                    "example": {
                        "type": "string",
                        "description": "Short code snippet demonstrating usage.",
                    },
                },
                "required": ["name", "description"],
            },
            "description": "The most important API endpoints or SDK methods.",
        },
        "environment_variables": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "name": {"type": "string"},
                    "purpose": {"type": "string"},
                },
                "required": ["name", "purpose"],
            },
            "description": "Required or common environment variables.",
        },
        "common_pitfalls": {
            "type": "array",
            "items": {"type": "string"},
            "description": "Gotchas and mistakes developers frequently make.",
        },
    },
    "required": [
        "name",
        "description",
        "trigger_conditions",
        "overview",
        "steps",
        "key_endpoints_or_methods",
    ],
}


# ---------------------------------------------------------------------------
# Firecrawl agent call
# ---------------------------------------------------------------------------

FIRECRAWL_AGENT_URL = "https://api.firecrawl.dev/v1/agent"


def call_firecrawl_agent(
    url: str,
    api_key: str,
    model: str = "spark-1-mini",
    prompt_extra: str = "",
    timeout: int = 120,
) -> dict:
    """
    Send a POST to the Firecrawl agent to crawl `url` and return the agent's structured skill data.
    
    Parameters:
        url (str): Documentation URL for the agent to crawl.
        api_key (str): Bearer API key used for Authorization with the Firecrawl agent.
        model (str): Model identifier to request from the agent (default "spark-1-mini").
        prompt_extra (str): Additional text appended to the system prompt to influence the agent's output.
        timeout (int): Network timeout in seconds for the agent request (default 120).
    
    Returns:
        dict: The parsed structured response mounted at the agent's `data` key.
    
    Raises:
        RuntimeError: If the HTTP request fails, a network error occurs, or the response does not contain a top-level `data` key.
    """
    system_prompt = textwrap.dedent(f"""\
        You are an expert technical writer who creates Claude Code skill files.
        A Claude Code skill is a markdown file with YAML frontmatter that tells
        Claude Code when and how to use a particular tool or service.

        Crawl the documentation at the provided URL and extract all information
        needed to produce a complete, accurate skill file. Focus on:
        - Primary use cases and trigger phrases
        - Step-by-step integration instructions
        - Key API endpoints or SDK methods with concise code examples
        - Required environment variables and secrets
        - Common pitfalls or configuration gotchas

        Do NOT include any API keys or secrets in code examples — use placeholder
        values like "YOUR_API_KEY" instead.
        {prompt_extra}
    """)

    payload = {
        "url": url,
        "model": model,
        "prompt": system_prompt,
        "schema": SKILL_SCHEMA,
    }

    body = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        FIRECRAWL_AGENT_URL,
        data=body,
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        },
        method="POST",
    )

    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            raw = resp.read().decode("utf-8")
    except urllib.error.HTTPError as exc:
        body_text = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(
            f"Firecrawl agent returned HTTP {exc.code}: {body_text}"
        ) from exc
    except urllib.error.URLError as exc:
        raise RuntimeError(f"Network error contacting Firecrawl: {exc.reason}") from exc

    response = json.loads(raw)

    # The agent endpoint returns structured data under response["data"]
    if "data" not in response:
        raise RuntimeError(
            f"Unexpected Firecrawl response (no 'data' key): {raw[:500]}"
        )

    return response["data"]


# ---------------------------------------------------------------------------
# Skill file renderer
# ---------------------------------------------------------------------------

def render_skill_markdown(data: dict) -> str:
    """
    Render the agent-produced skill structure into a Claude Code skill markdown string.
    
    Parameters:
    	data (dict): Structured skill data produced by the agent. Expected keys:
    		- name (str)
    		- description (str)
    		- overview (str, optional)
    		- trigger_conditions (list[str], optional)
    		- steps (list[dict] with keys "title" and "body", optional)
    		- key_endpoints_or_methods (list[dict] with keys "name", "description", and optional "example", optional)
    		- environment_variables (list[dict] with keys "name" and "purpose", optional)
    		- common_pitfalls (list[str], optional)
    
    Returns:
    	markdown (str): A single string containing the rendered Claude skill markdown, including YAML frontmatter, title, and sections for overview, when to use, steps, endpoints/methods (with fenced code examples when provided), environment variables table, and common pitfalls.
    """
    lines = []

    # --- Frontmatter ---
    lines.append("---")
    lines.append(f"name: {data['name']}")
    lines.append(f"description: {data['description']}")
    lines.append("---")
    lines.append("")

    # --- Title ---
    title = data["name"].replace("-", " ").title()
    lines.append(f"# {title}")
    lines.append("")

    # --- Overview ---
    if data.get("overview"):
        lines.append(data["overview"])
        lines.append("")

    # --- When to Use ---
    triggers = data.get("trigger_conditions", [])
    if triggers:
        lines.append("## When to Use")
        lines.append("")
        for t in triggers:
            lines.append(f'- "{t}"')
        lines.append("")

    # --- Steps ---
    steps = data.get("steps", [])
    for i, step in enumerate(steps, start=1):
        lines.append(f"## Step {i} — {step['title']}")
        lines.append("")
        lines.append(step["body"].strip())
        lines.append("")

    # --- Key Endpoints / Methods ---
    endpoints = data.get("key_endpoints_or_methods", [])
    if endpoints:
        lines.append("## Key Endpoints / Methods")
        lines.append("")
        for ep in endpoints:
            lines.append(f"### `{ep['name']}`")
            lines.append("")
            lines.append(ep["description"])
            if ep.get("example"):
                lines.append("")
                # Detect language from example content heuristically
                lang = _detect_lang(ep["example"])
                lines.append(f"```{lang}")
                lines.append(ep["example"].strip())
                lines.append("```")
            lines.append("")

    # --- Environment Variables ---
    env_vars = data.get("environment_variables", [])
    if env_vars:
        lines.append("## Environment Variables")
        lines.append("")
        lines.append("| Variable | Purpose |")
        lines.append("|----------|---------|")
        for ev in env_vars:
            lines.append(f"| `{ev['name']}` | {ev['purpose']} |")
        lines.append("")

    # --- Common Pitfalls ---
    pitfalls = data.get("common_pitfalls", [])
    if pitfalls:
        lines.append("## Common Pitfalls")
        lines.append("")
        for p in pitfalls:
            lines.append(f"- {p}")
        lines.append("")

    return "\n".join(lines)


def _detect_lang(snippet: str) -> str:
    """
    Guess the most appropriate code-fence language for a code snippet.
    
    Returns:
        lang (str): One of "python", "typescript", "bash", "json" when detected, or an empty string if no suitable language is identified.
    """
    s = snippet.strip()
    if s.startswith("import ") or s.startswith("from ") or "def " in s:
        return "python"
    if s.startswith("const ") or s.startswith("import {") or "=>" in s:
        return "typescript"
    if s.startswith("curl ") or s.startswith("$ "):
        return "bash"
    if s.startswith("{") or s.startswith("["):
        return "json"
    return ""


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def parse_args() -> argparse.Namespace:
    """
    Parse command-line arguments for generating a Claude Code skill from a documentation URL.
    
    Recognizes the following options:
    - --url (required): documentation URL to crawl
    - --output: output file path; prints to stdout if omitted
    - --model: Firecrawl model to use ("spark-1-mini" or "spark-1-pro")
    - --prompt-extra: additional instructions appended to the generation prompt
    - --timeout: maximum seconds to wait for the agent response
    
    Returns:
        argparse.Namespace: Parsed arguments with attributes `url`, `output`, `model`, `prompt_extra`, and `timeout`.
    """
    parser = argparse.ArgumentParser(
        description="Generate a Claude Code skill file from a documentation URL.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=textwrap.dedent("""\
            Examples:
              # Write to stdout
              FIRECRAWL_API_KEY=fc-... python3 firecrawl_skill_generator.py \\
                  --url https://docs.firecrawl.dev

              # Write to a skill file
              FIRECRAWL_API_KEY=fc-... python3 firecrawl_skill_generator.py \\
                  --url https://docs.stripe.com/api \\
                  --output ../.claude/skills/stripe-payments.md \\
                  --model spark-1-pro
        """),
    )
    parser.add_argument("--url", required=True, help="Documentation URL to crawl.")
    parser.add_argument(
        "--output",
        default=None,
        help="Output file path. Prints to stdout if omitted.",
    )
    parser.add_argument(
        "--model",
        default="spark-1-mini",
        choices=["spark-1-mini", "spark-1-pro"],
        help="Firecrawl model to use (default: spark-1-mini).",
    )
    parser.add_argument(
        "--prompt-extra",
        default="",
        help="Additional instructions appended to the generation prompt.",
    )
    parser.add_argument(
        "--timeout",
        type=int,
        default=120,
        help="Max seconds to wait for the agent response (default: 120).",
    )
    return parser.parse_args()


def main() -> None:
    """
    Run the CLI: fetch a Claude Code skill from the Firecrawl agent for the provided URL and output it as markdown.
    
    Parses command-line arguments, reads FIRECRAWL_API_KEY from the environment, invokes the Firecrawl agent to retrieve structured skill data, converts that data to Claude skill markdown, and either writes the markdown to the specified output file or prints it to stdout. Reports progress and the agent elapsed time to stderr.
    
    Exits with status 1 if the FIRECRAWL_API_KEY is not set or if the agent call fails.
    """
    args = parse_args()

    api_key = os.environ.get("FIRECRAWL_API_KEY")
    if not api_key:
        print(
            "Error: FIRECRAWL_API_KEY environment variable is not set.\n"
            "Get your key at https://firecrawl.dev",
            file=sys.stderr,
        )
        sys.exit(1)

    print(f"Crawling {args.url} with model={args.model} …", file=sys.stderr)
    start = time.time()

    try:
        data = call_firecrawl_agent(
            url=args.url,
            api_key=api_key,
            model=args.model,
            prompt_extra=args.prompt_extra,
            timeout=args.timeout,
        )
    except RuntimeError as exc:
        print(f"Error: {exc}", file=sys.stderr)
        sys.exit(1)

    elapsed = time.time() - start
    print(f"Agent completed in {elapsed:.1f}s", file=sys.stderr)

    markdown = render_skill_markdown(data)

    if args.output:
        output_path = os.path.abspath(args.output)
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        with open(output_path, "w", encoding="utf-8") as fh:
            fh.write(markdown)
        print(f"Skill written to {output_path}", file=sys.stderr)
    else:
        print(markdown)


if __name__ == "__main__":
    main()
