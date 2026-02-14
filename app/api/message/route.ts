import { NextRequest, NextResponse } from "next/server";
import { getDb } from "@/lib/db";

// GET /api/message?from=crab-mem&to=mcfly&limit=50
export async function GET(request: NextRequest) {
  const sql = getDb();
  const { searchParams } = request.nextUrl;

  const from = searchParams.get("from");
  const to = searchParams.get("to");
  const limit = Math.min(parseInt(searchParams.get("limit") ?? "50", 10), 200);

  if (from && to) {
    const messages = await sql`
      SELECT id, "from", "to", content, type, timestamp
      FROM messages
      WHERE "from" = ${from} AND "to" = ${to}
      ORDER BY timestamp DESC
      LIMIT ${limit}
    `;
    return NextResponse.json(messages);
  }

  if (from) {
    const messages = await sql`
      SELECT id, "from", "to", content, type, timestamp
      FROM messages
      WHERE "from" = ${from}
      ORDER BY timestamp DESC
      LIMIT ${limit}
    `;
    return NextResponse.json(messages);
  }

  if (to) {
    const messages = await sql`
      SELECT id, "from", "to", content, type, timestamp
      FROM messages
      WHERE "to" = ${to}
      ORDER BY timestamp DESC
      LIMIT ${limit}
    `;
    return NextResponse.json(messages);
  }

  const messages = await sql`
    SELECT id, "from", "to", content, type, timestamp
    FROM messages
    ORDER BY timestamp DESC
    LIMIT ${limit}
  `;
  return NextResponse.json(messages);
}

// POST /api/message
export async function POST(request: NextRequest) {
  const body = await request.json();
  const { from, to, content, type = "message" } = body;

  if (!from || !to || !content) {
    return NextResponse.json(
      { error: "from, to, and content are required" },
      { status: 400 }
    );
  }

  const sql = getDb();

  // Verify both handles exist
  const [sender] = await sql`SELECT handle FROM bots WHERE handle = ${from}`;
  if (!sender) {
    return NextResponse.json(
      { error: `Bot @${from} not found` },
      { status: 404 }
    );
  }

  const [receiver] = await sql`SELECT handle FROM bots WHERE handle = ${to}`;
  if (!receiver) {
    return NextResponse.json(
      { error: `Bot @${to} not found` },
      { status: 404 }
    );
  }

  const [message] = await sql`
    INSERT INTO messages ("from", "to", content, type)
    VALUES (${from}, ${to}, ${content}, ${type})
    RETURNING id, "from", "to", content, type, timestamp
  `;

  return NextResponse.json(message, { status: 201 });
}
