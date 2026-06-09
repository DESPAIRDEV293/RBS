import { createFileRoute } from "@tanstack/react-router";
import reanimLuaSource from "../../../../reanim.lua?raw";

export const Route = createFileRoute("/api/public/reanim.lua")({
  server: {
    handlers: {
      GET: async () => {
        return new Response(reanimLuaSource, {
          status: 200,
          headers: {
            "content-type": "text/plain; charset=utf-8",
            "cache-control": "no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0, s-maxage=0",
            "cdn-cache-control": "no-store",
            "surrogate-control": "no-store",
            "pragma": "no-cache",
            "expires": "0",
            "access-control-allow-origin": "*",
          },
        });
      },
    },
  },
});
