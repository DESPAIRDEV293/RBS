import { createFileRoute } from "@tanstack/react-router";
// Vite bundles the file as a raw string at build time, so the worker can
// serve it without any filesystem access.
import adminLuaSource from "../../../../admin.lua?raw";

const adminHeaders = {
  "content-type": "text/plain; charset=utf-8",
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

// Loader endpoints (and the in-browser /validate page) must keep working
// without a key. Roblox executors come through with one of these UAs.
function isExecutorUA(ua: string | null): boolean {
  if (!ua) return true; // most Roblox executors send no UA — treat as executor
  const u = ua.toLowerCase();
  return u.includes("roblox") || u.includes("synapse") || u.includes("luau") || u === "";
}

function denied(reason: string): Response {
  // Always 200 so loadstring(game:HttpGet(...)) on the executor doesn't crash
  // before our friendly message reaches the user.
  const body = `-- seige.lol: unauthorized (${reason})\nlocal _SEIGE_UNAUTHORIZED = "${reason.replace(/"/g, "'")}"\nwarn("[seige.lol] " .. _SEIGE_UNAUTHORIZED)\npcall(function()\n  if game and game.StarterGui then\n    game:GetService("StarterGui"):SetCore("SendNotification", {Title="seige.lol", Text=_SEIGE_UNAUTHORIZED, Duration=8})\n  end\nend)\n`;
  return new Response(body, { status: 200, headers: adminHeaders });
}

export const Route = createFileRoute("/api/public/admin.lua")({
  server: {
    handlers: {
      OPTIONS: async () => new Response(null, { status: 204, headers: adminHeaders }),
      HEAD: async () => new Response(null, { status: 200, headers: adminHeaders }),
      GET: async ({ request }) => {
        const url = new URL(request.url);
        const key = (url.searchParams.get("key") || "").trim().toUpperCase();
        const hwid = (url.searchParams.get("hwid") || "").trim().slice(0, 128);
        const ua = request.headers.get("user-agent");

        // Browser hits (validate page, manual check, etc.) bypass — only executors enforce.
        if (!isExecutorUA(ua) && !key) {
          return new Response(adminLuaSource, { status: 200, headers: adminHeaders });
        }

        if (!key) return denied("missing script_key — get one at https://seigescript.online/get-key");
        if (!/^SEIGE-[A-Z0-9-]{8,80}$/.test(key)) return denied("malformed script_key");

        const { supabaseAdmin } = await import("@/integrations/supabase/client.server");
        const { data, error } = await supabaseAdmin
          .from("script_keys")
          .select("key, tier, hwid, expires_at, revoked")
          .eq("key", key)
          .maybeSingle();
        if (error) return denied("auth backend error");
        if (!data) return denied("unknown script_key");
        if (data.revoked) return denied("key revoked");
        if (data.expires_at && new Date(data.expires_at).getTime() <= Date.now()) {
          return denied("key expired — get a new one at https://seigescript.online/get-key");
        }

        // HWID lock: bind on first use, enforce thereafter
        if (data.hwid) {
          if (hwid && data.hwid !== hwid) return denied("key bound to a different device");
        } else if (hwid) {
          await supabaseAdmin.from("script_keys").update({ hwid }).eq("key", key);
        }

        // Best-effort usage stamp; never block the executor on this.
        void supabaseAdmin
          .from("script_keys")
          .update({ last_used_at: new Date().toISOString() })
          .eq("key", key)
          .then(() => undefined, () => undefined);

        return new Response(adminLuaSource, { status: 200, headers: adminHeaders });
      },
    },
  },
});
