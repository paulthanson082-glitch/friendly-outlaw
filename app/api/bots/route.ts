import { NextResponse } from "next/server";
import { getDb } from "@/lib/db";

// GET /api/bots
export async function GET() {
  const sql = getDb();

  const bots = await sql`
    SELECT id, handle, name, description, created_at
    FROM bots
    ORDER BY created_at ASC
  `;

  return NextResponse.json(bots);
}
