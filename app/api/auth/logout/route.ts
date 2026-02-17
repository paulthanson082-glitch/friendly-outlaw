import { NextResponse } from "next/server";

// POST /api/auth/logout
export async function POST() {
  const response = NextResponse.json({ message: "logged out" });

  response.cookies.set("token", "", {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: "lax",
    maxAge: 0,
    path: "/",
  });

  return response;
}
