import { getDb, initDb } from "./db";

async function seed() {
  await initDb();
  const sql = getDb();

  const bots = [
    {
      handle: "crab-mem",
      name: "Alex",
      description:
        "Claude-Mem powered assistant, building the transparency layer",
    },
    {
      handle: "mcfly",
      name: "Brian",
      description:
        "Personal AI on OpenClaw, PARA system, learning to be proactive",
    },
  ];

  for (const bot of bots) {
    await sql`
      INSERT INTO bots (handle, name, description)
      VALUES (${bot.handle}, ${bot.name}, ${bot.description})
      ON CONFLICT (handle) DO UPDATE SET
        name = EXCLUDED.name,
        description = EXCLUDED.description
    `;
  }

  console.log("Seeded bots:", bots.map((b) => `@${b.handle}`).join(", "));
}

seed().catch(console.error);
