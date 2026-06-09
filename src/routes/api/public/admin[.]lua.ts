import { createFileRoute } from "@tanstack/react-router";
// Vite bundles the file as a raw string at build time, so the worker can
// serve it without any filesystem access.
import adminLuaSource from "../../../../admin.lua?raw";

export const Route = createFileRoute("/api/public/admin.lua")({
  server: {
    handlers: {
      GET: async () => {
        return new Response(adminLuaSource, {
          status: 200,
          headers: {
            "content-type": "text/plain; charset=utf-8",
            // Roblox executors don't honor caching, but proxies do — keep it
            // short so edits ship quickly on rejoin.
            "cache-control": "public, max-age=30, must-revalidate",
            "access-control-allow-origin": "*",
          },
        });
      },
    },
  },
});
