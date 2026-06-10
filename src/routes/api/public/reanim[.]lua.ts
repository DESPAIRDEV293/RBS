import { createFileRoute } from "@tanstack/react-router";
import reanimLuaSource from "../../../../reanim.lua?raw";

export const Route = createFileRoute("/api/public/reanim.lua")({
  server: {
    handlers: {
      GET: async ({ request }) => {
        const expected = process.env.REANIM_KEY;
        const url = new URL(request.url);
        const provided =
          request.headers.get("x-reanim-key") ?? url.searchParams.get("key");

        if (!expected || provided !== expected) {
          return new Response("Not Found", { status: 404 });
        }

        return new Response(reanimLuaSource, {
          status: 200,
          headers: {
            "content-type": "text/plain; charset=utf-8",
            "cache-control": "no-store, no-cache, must-revalidate, max-age=0",
            "cdn-cache-control": "no-store",
            "surrogate-control": "no-store",
            "pragma": "no-cache",
            "expires": "0",
            "x-robots-tag": "noindex, nofollow",
          },
        });
      },
    },
  },
});
