import { NextResponse } from "next/server";
import { getDb } from "@/lib/db";

// GET /api/town
// Returns a snapshot of the current AI Town state:
// - All residents (bots) with their descriptions
// - Recent messages (last 30, across all pairs)
// - World state (tick, status)
/**
 * Return a snapshot of the AI Town state including world state, residents, and recent messages.
 *
 * The response includes the current world key/value pairs, all bots augmented with their
 * latest per-bot memory (or `null` if none), and the 30 most recent messages with sender/recipient names.
 *
 * @returns An object with:
 *  - `world`: a record mapping world state keys to string values,
 *  - `residents`: an array of bot objects (id, handle, name, description, created_at) each with `latestMemory` (string or `null`),
 *  - `feed`: an array of recent message objects containing `id`, `from`, `to`, `content`, `type`, `timestamp`, `from_name`, and `to_name`.
 */

export async function GET() {
  const sql = getDb();

  const [bots, messages, worldState, memories] = await Promise.all([
    sql`
      SELECT id, handle, name, description, created_at
      FROM bots
      ORDER BY name ASC
    `,
    sql`
      SELECT m.id, m."from", m."to", m.content, m.type, m.timestamp,
             b1.name AS from_name, b2.name AS to_name
      FROM messages m
      LEFT JOIN bots b1 ON b1.handle = m."from"
      LEFT JOIN bots b2 ON b2.handle = m."to"
      ORDER BY m.timestamp DESC
      LIMIT 30
    `,
    sql`SELECT key, value, updated_at FROM world_state`,
    sql`
      SELECT DISTINCT ON (bot_handle) bot_handle, memory, created_at
      FROM bot_memories
      ORDER BY bot_handle, created_at DESC
    `,
  ]);

  const state: Record<string, string> = {};
  for (const row of worldState) {
    state[row.key] = row.value;
  }

  const memoriesByHandle: Record<string, string> = {};
  for (const row of memories) {
    memoriesByHandle[row.bot_handle] = row.memory;
  }

  const residents = bots.map((b) => ({
    ...b,
    latestMemory: memoriesByHandle[b.handle] ?? null,
  }));

  return NextResponse.json({
    world: state,
    residents,
    feed: messages,
  });
}
