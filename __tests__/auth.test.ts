import {
  hashPassword,
  verifyPassword,
  generateToken,
  verifyToken,
  getTokenFromHeader,
} from "../lib/auth";

// Ensure a JWT_SECRET is set for tests
process.env.JWT_SECRET = "test-secret-for-jest";

describe("hashPassword / verifyPassword", () => {
  it("hashes a password and verifies it successfully", async () => {
    const password = "supersecret1";
    const hash = await hashPassword(password);

    expect(hash).not.toBe(password);
    expect(hash.startsWith("$2")).toBe(true); // bcrypt prefix

    const match = await verifyPassword(password, hash);
    expect(match).toBe(true);
  });

  it("rejects an incorrect password", async () => {
    const hash = await hashPassword("correcthorse");
    const match = await verifyPassword("wrongpassword", hash);
    expect(match).toBe(false);
  });

  it("generates unique hashes for the same password", async () => {
    const hash1 = await hashPassword("samepass");
    const hash2 = await hashPassword("samepass");
    expect(hash1).not.toBe(hash2);
  });
});

describe("generateToken / verifyToken", () => {
  const payload = { userId: "abc-123", email: "user@example.com" };

  it("generates a non-empty JWT string", () => {
    const token = generateToken(payload);
    expect(typeof token).toBe("string");
    expect(token.split(".")).toHaveLength(3); // header.payload.signature
  });

  it("verifies a valid token and returns the payload", () => {
    const token = generateToken(payload);
    const result = verifyToken(token);

    expect(result).not.toBeNull();
    expect(result!.userId).toBe(payload.userId);
    expect(result!.email).toBe(payload.email);
  });

  it("returns null for a tampered token", () => {
    const token = generateToken(payload);
    const tampered = token.slice(0, -5) + "xxxxx";
    expect(verifyToken(tampered)).toBeNull();
  });

  it("returns null for an empty string", () => {
    expect(verifyToken("")).toBeNull();
  });

  it("returns null for a random string", () => {
    expect(verifyToken("not.a.jwt")).toBeNull();
  });
});

describe("getTokenFromHeader", () => {
  it("extracts the token from a valid Bearer header", () => {
    const token = "my.jwt.token";
    expect(getTokenFromHeader(`Bearer ${token}`)).toBe(token);
  });

  it("returns null when the header is missing", () => {
    expect(getTokenFromHeader(null)).toBeNull();
  });

  it("returns null when the header has no Bearer prefix", () => {
    expect(getTokenFromHeader("my.jwt.token")).toBeNull();
  });

  it("returns null for an empty Bearer value", () => {
    expect(getTokenFromHeader("Bearer ")).toBe("");
  });
});
