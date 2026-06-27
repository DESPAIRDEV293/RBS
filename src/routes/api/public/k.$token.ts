import { createFileRoute } from "@tanstack/react-router";

const headers = {
  "content-type": "text/plain; charset=utf-8",
  "cache-control": "no-store, no-cache, must-revalidate, max-age=0",
  "pragma": "no-cache",
  "expires": "0",
  "x-robots-tag": "noindex",
  "access-control-allow-origin": "*",
  "access-control-allow-methods": "GET, HEAD, OPTIONS",
} as const;

export const Route = createFileRoute("/api/public/k/$token")({
  server: {
    handlers: {
      OPTIONS: async () => new Response(null, { status: 204, headers }),
      GET: async ({ params }) => {
        const token = String(params.token || "").trim();
        if (!token || token.length < 4 || token.length > 64 || !/^[a-zA-Z0-9_-]+$/.test(token)) {
          return new Response("invalid token", { status: 400, headers });
        }
        const { supabaseAdmin } = await import("@/integrations/supabase/client.server");
        const { data } = await supabaseAdmin
          .from("script_keys")
          .select("key, tier, expires_at, revoked")
          .eq("token", token)
          .maybeSingle();
        if (!data) return new Response("key not found", { status: 404, headers });
        if (data.revoked) return new Response("key revoked", { status: 410, headers });
        if (data.expires_at && new Date(data.expires_at).getTime() <= Date.now()) {
          return new Response("key expired", { status: 410, headers });
        }
        const exp = data.expires_at
          ? `expires: ${new Date(data.expires_at).toISOString()}`
          : "expires: never";
        const loadstring = `script_key = "${data.key}" loadstring(game:HttpGet("https://seigescript.online/api/public/loader.lua"))()`;
        const body = `${loadstring}\n\n-- ---------------------------------------------\n-- Your key: ${data.key}\n-- Tier: ${data.tier}\n-- ${exp}\n-- ---------------------------------------------\n-- Copy the FIRST line above and paste it into your executor.\n`;
        return new Response(body, { status: 200, headers });
      },
    },
  },
});
