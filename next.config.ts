import type { NextConfig } from "next";
import path from "node:path";

const nextConfig: NextConfig = {
  turbopack: {
    resolveAlias: {
      // Redirect bun:bundle to the Node-compatible shim when bundling with
      // Turbopack (Next.js dev + prod). The real bun:bundle is used only when
      // the companion module is loaded inside the Bun runtime.
      "bun:bundle": path.resolve("./src/compat/bun-bundle.ts"),
    },
  },
};

export default nextConfig;
