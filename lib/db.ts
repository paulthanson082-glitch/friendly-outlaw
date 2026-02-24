import { neon } from "@neondatabase/serverless";

export function getDb() {
  const sql = neon(process.env.DATABASE_URL!);
  return sql;
}

/**
 * Ensure required database schema exists and seed initial world state.
 *
 * Creates tables `bots`, `messages`, `bot_memories`, and `world_state`, adds indexes used for queries, and inserts default `world_state` keys (`status` = `running`, `tick` = `0`) if they are missing.
 */
export async function initDb() {
  const sql = getDb();

  await sql`
    CREATE TABLE IF NOT EXISTS bots (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      handle TEXT UNIQUE NOT NULL,
      name TEXT NOT NULL,
      description TEXT NOT NULL,
      created_at TIMESTAMPTZ DEFAULT NOW()
    )
  `;

  await sql`
    CREATE TABLE IF NOT EXISTS messages (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      "from" TEXT NOT NULL,
      "to" TEXT NOT NULL,
      content TEXT NOT NULL,
      type TEXT NOT NULL DEFAULT 'message',
      timestamp TIMESTAMPTZ DEFAULT NOW()
    )
  `;

  await sql`CREATE INDEX IF NOT EXISTS idx_messages_from ON messages ("from")`;
  await sql`CREATE INDEX IF NOT EXISTS idx_messages_to ON messages ("to")`;
  await sql`CREATE INDEX IF NOT EXISTS idx_messages_timestamp ON messages ("timestamp" DESC)`;

  // Bot memories: recent conversation context stored per bot
  await sql`
    CREATE TABLE IF NOT EXISTS bot_memories (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      bot_handle TEXT NOT NULL REFERENCES bots(handle) ON DELETE CASCADE,
      memory TEXT NOT NULL,
      importance INTEGER NOT NULL DEFAULT 5,
      created_at TIMESTAMPTZ DEFAULT NOW()
    )
  `;

  await sql`CREATE INDEX IF NOT EXISTS idx_bot_memories_handle ON bot_memories (bot_handle)`;
  await sql`CREATE INDEX IF NOT EXISTS idx_bot_memories_created ON bot_memories (created_at DESC)`;

  // World state: tracks simulation metadata
  await sql`
    CREATE TABLE IF NOT EXISTS world_state (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL,
      updated_at TIMESTAMPTZ DEFAULT NOW()
    )
  `;

  // Seed default world state values if missing
  await sql`
    INSERT INTO world_state (key, value)
    VALUES ('status', 'running'), ('tick', '0')
    ON CONFLICT (key) DO NOTHING
  `;
}
