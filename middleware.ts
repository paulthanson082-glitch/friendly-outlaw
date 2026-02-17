import { NextRequest, NextResponse } from "next/server";
import { verifyToken, getTokenFromHeader } from "@/lib/auth";

// Routes that require a valid JWT
const PROTECTED_PREFIXES = ["/api/user"];

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  const isProtected = PROTECTED_PREFIXES.some((prefix) =>
    pathname.startsWith(prefix)
  );

  if (!isProtected) return NextResponse.next();

  // Accept token from cookie or Authorization header
  const cookieToken = request.cookies.get("token")?.value ?? null;
  const headerToken = getTokenFromHeader(
    request.headers.get("authorization")
  );
  const token = cookieToken ?? headerToken;

  if (!token) {
    return NextResponse.json({ error: "unauthorized" }, { status: 401 });
  }

  const payload = verifyToken(token);
  if (!payload) {
    return NextResponse.json({ error: "invalid or expired token" }, { status: 401 });
  }

  // Forward user info to route handlers via headers
  const requestHeaders = new Headers(request.headers);
  requestHeaders.set("x-user-id", payload.userId);
  requestHeaders.set("x-user-email", payload.email);

  return NextResponse.next({ request: { headers: requestHeaders } });
}

export const config = {
  matcher: ["/api/user/:path*"],
};
