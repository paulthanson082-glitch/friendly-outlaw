import { NextRequest, NextResponse } from "next/server";
import { getDb } from "@/lib/db";
import { generateBotResponse, generateMemory } from "@/lib/ai";

// POST /api/bots/respond
// Body: { speaker: "pixel", listener: "sage" }
// The speaker bot generates a Claude-powered reply to the listener,
/**
 * Generate an AI reply from a speaker bot to a listener bot, store the reply as a message, and periodically create and store a memory summary for the speaker.
 *
 * @param request - Incoming request whose JSON body must include `speaker` and `listener` bot handles; validates handles, ensures bots exist, and uses recent messages and memories to generate the reply.
 * @returns The created message record containing `id`, `from`, `to`, `content`, `type`, and `timestamp`.
 */
export async function POST(request: NextRequest) {
  const body = await request.json();
  const { speaker, listener } = body;

  if (!speaker || !listener) {
    return NextResponse.json(
      { error: "speaker and listener handles are required" },
      { status: 400 }
    );
  }

  if (speaker === listener) {
    return NextResponse.json(
      { error: "speaker and listener must be different" },
      { status: 400 }
    );
  }

  const sql = getDb();

  // Verify both bots exist
  const [speakerBot] = await sql`SELECT handle FROM bots WHERE handle = ${speaker}`;
  if (!speakerBot) {
    return NextResponse.json({ error: `Bot @${speaker} not found` }, { status: 404 });
  }

  const [listenerBot] = await sql`SELECT handle FROM bots WHERE handle = ${listener}`;
  if (!listenerBot) {
    return NextResponse.json({ error: `Bot @${listener} not found` }, { status: 404 });
  }

  // Fetch recent conversation between these two bots (both directions)
  const recentMessages = await sql`
    SELECT "from", "to", content, timestamp
    FROM messages
    WHERE ("from" = ${speaker} AND "to" = ${listener})
       OR ("from" = ${listener} AND "to" = ${speaker})
    ORDER BY timestamp DESC
    LIMIT 10
  `;

  // Fetch speaker's memories
  const memories = await sql`
    SELECT memory, importance, created_at
    FROM bot_memories
    WHERE bot_handle = ${speaker}
    ORDER BY created_at DESC
    LIMIT 5
  `;

  // Generate the response via Claude
  const responseText = await generateBotResponse(
    speaker,
    listener,
    recentMessages.map((m) => ({
      from: m.from,
      to: m.to,
      content: m.content,
      timestamp: m.timestamp,
    })),
    memories.map((m) => ({
      memory: m.memory,
      importance: m.importance,
      created_at: m.created_at,
    }))
  );

  // Store the message
  const [message] = await sql`
    INSERT INTO messages ("from", "to", content, type)
    VALUES (${speaker}, ${listener}, ${responseText}, 'ai_response')
    RETURNING id, "from", "to", content, type, timestamp
  `;

  // After every 3rd message, generate and store a memory for the speaker
  const msgCount = recentMessages.length + 1;
  if (msgCount % 3 === 0) {
    const allMessages = [
      ...recentMessages.map((m) => ({
        from: m.from,
        to: m.to,
        content: m.content,
        timestamp: m.timestamp,
      })),
      { from: speaker, to: listener, content: responseText, timestamp: new Date().toISOString() },
    ];

    try {
      const memory = await generateMemory(speaker, listener, allMessages);
      if (memory) {
        await sql`
          INSERT INTO bot_memories (bot_handle, memory, importance)
          VALUES (${speaker}, ${memory}, 5)
        `;
      }
    } catch {
      // Memory generation is best-effort; don't fail the request
    }
  }

  return NextResponse.json(message, { status: 201 });
}
