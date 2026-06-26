import { createFileRoute } from "@tanstack/react-router";
// Vite bundles the file as a raw string at build time, so the worker can
// serve it without any filesystem access.
import adminLuaSource from "../../../../admin.lua?raw";

const adminHeaders = {
  "content-type": "text/plain; charset=utf-8",
  // Roblox/executor HTTP caches can be aggressive; make this endpoint
  // explicitly uncacheable at every layer so loadstring gets latest.
  "cache-control": "no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0, s-maxage=0",
  "cdn-cache-control": "no-store",
  "surrogate-control": "no-store",
  "pragma": "no-cache",
  "expires": "0",
  "x-admin-build": adminLuaSource.match(/local ADMIN_BUILD = "([^"]+)"/)?.[1] ?? "unknown",
  "access-control-allow-origin": "*",
  "access-control-allow-methods": "GET, HEAD, OPTIONS",
  "access-control-allow-headers": "Content-Type, Authorization, X-Requested-With, Accept, Origin",
} as const;

export const Route = createFileRoute("/api/public/admin.lua")({
  server: {
    handlers: {
      OPTIONS: async () => new Response(null, { status: 204, headers: adminHeaders }),
      HEAD: async () => new Response(null, { status: 200, headers: adminHeaders }),
      GET: async () => {
        return new Response(adminLuaSource, {
          status: 200,
          headers: adminHeaders,
        });
      },
    },
  },
});
