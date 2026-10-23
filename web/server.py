#!/usr/bin/env python3
"""BOT ORACLE — AI Q&A Application Server"""
import os
from flask import Flask, request, jsonify, send_file
import anthropic

app = Flask(__name__)

SYSTEM_PROMPT = (
    "You are an all-knowing AI oracle — one of many bots in a collective intelligence. "
    "Answer questions thoroughly and accurately across all domains: science, history, "
    "technology, arts, philosophy, mathematics, culture, and beyond. "
    "Be direct, clear, and informative. Structure complex answers with clear paragraphs. "
    "You are knowledgeable, precise, and helpful — like the world's best search engine "
    "combined with deep expertise."
)


@app.route("/")
def index():
    return send_file("index.html")


@app.route("/api/ask", methods=["POST"])
def ask():
    data = request.get_json(silent=True) or {}
    question = data.get("question", "").strip()
    api_key = data.get("apiKey", "").strip()
    bot_name = data.get("bot", "ORACLE")

    if not question:
        return jsonify({"error": "No question provided"}), 400
    if not api_key:
        return jsonify({"error": "API key required — click CONFIG to add your key"}), 400

    try:
        client = anthropic.Anthropic(api_key=api_key)
        message = client.messages.create(
            model="claude-opus-4-6",
            max_tokens=2048,
            system=SYSTEM_PROMPT,
            messages=[{"role": "user", "content": question}],
        )
        return jsonify({
            "answer": message.content[0].text,
            "bot": bot_name,
        })

    except anthropic.AuthenticationError:
        return jsonify({"error": "Invalid API key — check your Anthropic credentials"}), 401
    except anthropic.RateLimitError:
        return jsonify({"error": "Rate limit reached — please wait a moment"}), 429
    except anthropic.APIError as exc:
        return jsonify({"error": f"API error: {exc}"}), 500
    except Exception as exc:
        return jsonify({"error": f"Unexpected error: {exc}"}), 500


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    key_hint = "set" if os.environ.get("ANTHROPIC_API_KEY") else "not set (enter in UI)"
    print(f"\n  BOT ORACLE  →  http://localhost:{port}")
    print(f"  ANTHROPIC_API_KEY: {key_hint}\n")
    app.run(host="0.0.0.0", port=port)
