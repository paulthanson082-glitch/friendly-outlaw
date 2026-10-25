import Anthropic from "@anthropic-ai/sdk";
import { NextRequest, NextResponse } from "next/server";

const client = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });

export async function POST(req: NextRequest) {
  try {
    const { prompt } = await req.json();
    if (!prompt || typeof prompt !== "string") {
      return NextResponse.json({ error: "No prompt" }, { status: 400 });
    }

    const message = await client.messages.create({
      model: "claude-sonnet-5-5",
      max_tokens: 2000,
      messages: [{ role: "user", content: prompt }],
    });

    const block = message.content[0];
    const text = block && block.type === "text" ? block.text : "";
    return NextResponse.json({ result: text });
  } catch (err) {
    const msg = err instanceof Error ? err.message : "Unknown error";
    console.error(err);
    return NextResponse.json({ error: msg }, { status: 500 });
  }
}
