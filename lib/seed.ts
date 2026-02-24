import { getDb, initDb } from "./db";
import { characters } from "./characters";

/**
 * Initializes the database and upserts the project's characters into the `bots` table.
 *
 * Inserts each character from the `characters` list and, on a handle conflict, updates that record's `name` and `description`. Logs a summary of seeded residents to the console.
 */
async function seed() {
  await initDb();
  const sql = getDb();

  for (const char of characters) {
    await sql`
      INSERT INTO bots (handle, name, description)
      VALUES (${char.handle}, ${char.name}, ${char.description})
      ON CONFLICT (handle) DO UPDATE SET
        name = EXCLUDED.name,
        description = EXCLUDED.description
    `;
  }

  console.log(
    "Seeded AI Town residents:",
    characters.map((c) => `@${c.handle} (${c.name})`).join(", ")
  );
}

seed().catch(console.error);
