import { NextRequest, NextResponse } from "next/server";
import { getDb } from "@/lib/db";

// GET /api/user/profile  (protected — requires valid JWT via middleware)
export async function GET(request: NextRequest) {
  const userId = request.headers.get("x-user-id");

  if (!userId) {
    return NextResponse.json({ error: "unauthorized" }, { status: 401 });
  }

  const sql = getDb();

  const [user] = await sql`
    SELECT id, email, username, created_at, updated_at
    FROM users
    WHERE id = ${userId}
  `;

  if (!user) {
    return NextResponse.json({ error: "user not found" }, { status: 404 });
  }

  return NextResponse.json({
    user: {
      id: user.id,
      email: user.email,
      username: user.username,
      createdAt: user.created_at,
      updatedAt: user.updated_at,
    },
  });
}

// PATCH /api/user/profile  (protected — update username)
export async function PATCH(request: NextRequest) {
  const userId = request.headers.get("x-user-id");

  if (!userId) {
    return NextResponse.json({ error: "unauthorized" }, { status: 401 });
  }

  const body = await request.json();
  const { username } = body;

  if (!username) {
    return NextResponse.json({ error: "username is required" }, { status: 400 });
  }

  const sql = getDb();

  const [conflict] = await sql`
    SELECT id FROM users WHERE username = ${username} AND id != ${userId}
  `;

  if (conflict) {
    return NextResponse.json({ error: "username already taken" }, { status: 409 });
  }

  const [updated] = await sql`
    UPDATE users
    SET username = ${username}, updated_at = NOW()
    WHERE id = ${userId}
    RETURNING id, email, username, created_at, updated_at
  `;

  return NextResponse.json({
    user: {
      id: updated.id,
      email: updated.email,
      username: updated.username,
      createdAt: updated.created_at,
      updatedAt: updated.updated_at,
    },
  });
}
