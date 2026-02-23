import { NextRequest, NextResponse } from "next/server";
import { getDb } from "@/lib/db";
import { generateBotResponse, generateMemory } from "@/lib/ai";

// POST /api/simulate
// Runs one tick of the AI Town simulation:
// 1. Picks two random bots
// 2. Has the first bot send an AI-generated message to the second
// 3. Optionally generates a reply from the second bot
// 4. Increments the world tick counter

export async function POST(request: NextRequest) {
  const body = await request.json().catch(() => ({}));
  const exchanges = Math.min(Number(body.exchanges ?? 1), 3); // 1-3 exchanges per tick

  const sql = getDb();

  // Check world status
  const [statusRow] = await sql`SELECT value FROM world_state WHERE key = 'status'`;
  if (statusRow?.value === "paused") {
    return NextResponse.json({ error: "Simulation is paused" }, { status: 409 });
  }

  // Fetch all bots
  const bots = await sql`SELECT handle FROM bots ORDER BY RANDOM()`;
  if (bots.length < 2) {
    return NextResponse.json(
      { error: "Need at least 2 bots to simulate" },
      { status: 400 }
    );
  }

  const generated: { from: string; to: string; content: string }[] = [];

  for (let i = 0; i < exchanges; i++) {
    // Pick two distinct random bots for this exchange
    const shuffled = [...bots].sort(() => Math.random() - 0.5);
    const speaker = shuffled[0].handle as string;
    const listener = shuffled[1].handle as string;

    // Fetch recent conversation history
    const recentMessages = await sql`
      SELECT "from", "to", content, timestamp
      FROM messages
      WHERE ("from" = ${speaker} AND "to" = ${listener})
         OR ("from" = ${listener} AND "to" = ${speaker})
      ORDER BY timestamp DESC
      LIMIT 10
    `;

    // Fetch speaker memories
    const memories = await sql`
      SELECT memory, importance, created_at
      FROM bot_memories
      WHERE bot_handle = ${speaker}
      ORDER BY created_at DESC
      LIMIT 5
    `;

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

    await sql`
      INSERT INTO messages ("from", "to", content, type)
      VALUES (${speaker}, ${listener}, ${responseText}, 'simulation')
    `;

    generated.push({ from: speaker, to: listener, content: responseText });

    // Occasionally generate a memory after the exchange
    if (Math.random() < 0.4) {
      const allMessages = [
        ...recentMessages,
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
        // best-effort
      }
    }
  }

  // Increment world tick
  await sql`
    UPDATE world_state
    SET value = (value::INTEGER + 1)::TEXT, updated_at = NOW()
    WHERE key = 'tick'
  `;

  const [tickRow] = await sql`SELECT value FROM world_state WHERE key = 'tick'`;

  return NextResponse.json({ tick: Number(tickRow?.value ?? 0), generated });
}

// GET /api/simulate — return current world state
export async function GET() {
  const sql = getDb();
  const state = await sql`SELECT key, value, updated_at FROM world_state`;
  const result: Record<string, string> = {};
  for (const row of state) {
    result[row.key] = row.value;
  }
  return NextResponse.json(result);
}

// PATCH /api/simulate — pause or resume the simulation
export async function PATCH(request: NextRequest) {
  const { action } = await request.json();
  if (action !== "pause" && action !== "resume") {
    return NextResponse.json(
      { error: "action must be 'pause' or 'resume'" },
      { status: 400 }
    );
  }

  const sql = getDb();
  const newStatus = action === "pause" ? "paused" : "running";

  await sql`
    UPDATE world_state
    SET value = ${newStatus}, updated_at = NOW()
    WHERE key = 'status'
  `;

  return NextResponse.json({ status: newStatus });
}
