import { NextRequest, NextResponse } from "next/server";
import { getDb } from "@/lib/db";
import { verifyPassword, generateToken } from "@/lib/auth";

// POST /api/auth/login
export async function POST(request: NextRequest) {
  const body = await request.json();
  const { email, password } = body;

  if (!email || !password) {
    return NextResponse.json(
      { error: "email and password are required" },
      { status: 400 }
    );
  }

  const sql = getDb();

  const [user] = await sql`
    SELECT id, email, username, password_hash
    FROM users
    WHERE email = ${email}
  `;

  if (!user) {
    return NextResponse.json(
      { error: "invalid email or password" },
      { status: 401 }
    );
  }

  const valid = await verifyPassword(password, user.password_hash);
  if (!valid) {
    return NextResponse.json(
      { error: "invalid email or password" },
      { status: 401 }
    );
  }

  const token = generateToken({ userId: user.id, email: user.email });

  const response = NextResponse.json({
    user: { id: user.id, email: user.email, username: user.username },
  });

  response.cookies.set("token", token, {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: "lax",
    maxAge: 60 * 60 * 24 * 7, // 7 days
    path: "/",
  });

  return response;
}
