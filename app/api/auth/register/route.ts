import { NextRequest, NextResponse } from "next/server";
import { getDb } from "@/lib/db";
import { hashPassword, generateToken } from "@/lib/auth";

// POST /api/auth/register
export async function POST(request: NextRequest) {
  const body = await request.json();
  const { email, username, password } = body;

  if (!email || !username || !password) {
    return NextResponse.json(
      { error: "email, username, and password are required" },
      { status: 400 }
    );
  }

  if (password.length < 8) {
    return NextResponse.json(
      { error: "password must be at least 8 characters" },
      { status: 400 }
    );
  }

  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    return NextResponse.json({ error: "invalid email address" }, { status: 400 });
  }

  const sql = getDb();

  const [existing] = await sql`
    SELECT id FROM users WHERE email = ${email} OR username = ${username}
  `;

  if (existing) {
    return NextResponse.json(
      { error: "email or username already in use" },
      { status: 409 }
    );
  }

  const passwordHash = await hashPassword(password);

  const [user] = await sql`
    INSERT INTO users (email, username, password_hash)
    VALUES (${email}, ${username}, ${passwordHash})
    RETURNING id, email, username, created_at
  `;

  const token = generateToken({ userId: user.id, email: user.email });

  const response = NextResponse.json(
    { user: { id: user.id, email: user.email, username: user.username, createdAt: user.created_at } },
    { status: 201 }
  );

  response.cookies.set("token", token, {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: "lax",
    maxAge: 60 * 60 * 24 * 7, // 7 days
    path: "/",
  });

  return response;
}
