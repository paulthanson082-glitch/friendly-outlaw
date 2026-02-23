#!/usr/bin/env python3
"""
AI Writing Assistant CLI

An interactive command-line interface for AI-powered writing assistance.
Uses the Anthropic Claude API to maintain a real conversation history,
so follow-up questions and requests build on what was discussed before.

Usage:
    python ai_assistant_cli.py

Environment variables:
    ANTHROPIC_API_KEY  - Your Anthropic API key (required)
"""

import os
import sys
import textwrap
from typing import List, Dict

import anthropic


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

CLAUDE_MODEL = "claude-3-5-sonnet-20241022"
MAX_TOKENS = 4096
TERMINAL_WIDTH = 80

SYSTEM_PROMPT = """You are an expert AI writing assistant helping writers with \
creative and professional projects. You have deep knowledge of narrative \
structure, character development, pacing, dialogue, genre conventions, and \
style.

You can help with:
- Continuing or drafting new sections of stories, essays, or any written work
- Improving text for clarity, flow, voice, and impact
- Grammar and spelling corrections
- Generating title and headline ideas
- Brainstorming story, plot, or content ideas
- Developing characters with depth and complexity
- Building outlines and story structures
- Analyzing writing for tone, pacing, and readability
- Changing the tone or style of existing text
- Answering craft questions about writing technique

Be helpful, encouraging, and specific. When giving feedback, explain the \
reasoning so writers can learn from it. Keep track of context shared earlier \
in the conversation so you can make consistent suggestions."""

HELP_TEXT = """
╔══════════════════════════════════════════════════════════════╗
║              AI Writing Assistant — Commands                 ║
╠══════════════════════════════════════════════════════════════╣
║  /help       Show this help message                          ║
║  /clear      Clear conversation history and start fresh      ║
║  /history    Show the number of messages in the conversation ║
║  /quit       Exit the assistant  (also /exit or /q)          ║
╠══════════════════════════════════════════════════════════════╣
║  Example prompts:                                            ║
║  "Continue this story: The door creaked open..."             ║
║  "Improve this paragraph: [paste your text]"                 ║
║  "Give me 5 title ideas for a sci-fi story about memory"     ║
║  "Brainstorm plot ideas for a mystery set in 1920s Paris"    ║
║  "Develop a villain who used to be a teacher"                ║
║  "Create an outline for a short story about forgiveness"     ║
║  "Check the grammar in: [paste your text]"                   ║
║  "Rewrite this in a more casual tone: [paste your text]"     ║
╚══════════════════════════════════════════════════════════════╝
"""

WELCOME_BANNER = """
╔══════════════════════════════════════════════════════════════╗
║           AI Writing Assistant CLI                           ║
║           Powered by Claude (Anthropic)                      ║
╠══════════════════════════════════════════════════════════════╣
║  Type your writing request and press Enter to get help.      ║
║  Your conversation is remembered between messages.           ║
║  Type /help for commands, /quit to exit.                     ║
╚══════════════════════════════════════════════════════════════╝
"""


# ---------------------------------------------------------------------------
# Formatting helpers
# ---------------------------------------------------------------------------

def print_wrapped(text: str, prefix: str = "", width: int = TERMINAL_WIDTH) -> None:
    """Print text with word-wrapping, preserving paragraph breaks."""
    paragraphs = text.split("\n")
    for paragraph in paragraphs:
        if not paragraph.strip():
            print()
            continue
        wrapped_lines = textwrap.wrap(
            paragraph,
            width=width - len(prefix),
            subsequent_indent=" " * len(prefix),
        )
        for line in wrapped_lines:
            print(prefix + line)


def print_divider() -> None:
    print("─" * TERMINAL_WIDTH)


# ---------------------------------------------------------------------------
# CLI session
# ---------------------------------------------------------------------------

def run_assistant_session(client: anthropic.Anthropic) -> None:
    """
    Run the interactive assistant loop.

    Maintains a conversation history so each new message has access to all
    prior context, enabling multi-turn dialogue about the same piece of work.
    """
    conversation_history: List[Dict[str, str]] = []

    print(WELCOME_BANNER)

    while True:
        try:
            user_input = input("You: ").strip()
        except (EOFError, KeyboardInterrupt):
            print("\n\nGoodbye! Happy writing!")
            break

        if not user_input:
            continue

        # ── Slash commands ──────────────────────────────────────────────────
        if user_input.startswith("/"):
            normalized_command = user_input.lower().split()[0]

            if normalized_command in ("/quit", "/exit", "/q"):
                print("Goodbye! Happy writing!")
                break

            if normalized_command == "/clear":
                conversation_history.clear()
                print("Conversation history cleared. Starting fresh.\n")
                continue

            if normalized_command == "/history":
                message_count = len(conversation_history)
                turn_count = message_count // 2
                print(
                    f"Conversation has {message_count} messages "
                    f"({turn_count} back-and-forth turns).\n"
                )
                continue

            if normalized_command == "/help":
                print(HELP_TEXT)
                continue

            print(f"Unknown command: {user_input}")
            print("Type /help for a list of commands.\n")
            continue

        # ── AI request ──────────────────────────────────────────────────────
        conversation_history.append({"role": "user", "content": user_input})

        try:
            response = client.messages.create(
                model=CLAUDE_MODEL,
                max_tokens=MAX_TOKENS,
                system=SYSTEM_PROMPT,
                messages=conversation_history,
            )

            assistant_reply = response.content[0].text

            # Persist the reply so future turns have full context
            conversation_history.append(
                {"role": "assistant", "content": assistant_reply}
            )

            print_divider()
            print_wrapped(assistant_reply, prefix="  ")
            print_divider()
            print()

        except anthropic.AuthenticationError:
            print(
                "Authentication failed. Check that ANTHROPIC_API_KEY is set "
                "and valid.\n"
            )
            # Remove the user message we just added so history stays coherent
            conversation_history.pop()

        except anthropic.RateLimitError:
            print("Rate limit reached. Please wait a moment before retrying.\n")
            conversation_history.pop()

        except anthropic.APIStatusError as api_error:
            print(f"API error ({api_error.status_code}): {api_error.message}\n")
            conversation_history.pop()

        except anthropic.APIConnectionError:
            print(
                "Connection error. Check your internet connection and try again.\n"
            )
            conversation_history.pop()


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main() -> None:
    api_key = os.environ.get("ANTHROPIC_API_KEY")
    if not api_key:
        print(
            "Error: ANTHROPIC_API_KEY environment variable is not set.\n"
            "Set it with: export ANTHROPIC_API_KEY='your-api-key-here'\n"
            "Get a key at: https://console.anthropic.com"
        )
        sys.exit(1)

    client = anthropic.Anthropic(api_key=api_key)
    run_assistant_session(client)


if __name__ == "__main__":
    main()
