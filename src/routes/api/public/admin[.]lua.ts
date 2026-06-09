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
            // Always serve the newest bundled script after panel/tag fixes.
            "cache-control": "no-store, max-age=0",
            "access-control-allow-origin": "*",
          },
        });
      },
    },
  },
});
