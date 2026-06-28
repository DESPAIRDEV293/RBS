import { createFileRoute } from "@tanstack/react-router";

// Pair-code handoff for Spotify tokens. The browser POSTs a token keyed by
// a short pair code; the in-game script polls GET with the same code, and
// the row is deleted on first successful read. Rows expire after ~10min.

const cors = {
  "access-control-allow-origin": "*",
  "access-control-allow-methods": "GET, POST, OPTIONS",
  "access-control-allow-headers": "Content-Type",
  "content-type": "application/json",
  "cache-control": "no-store",
} as const;

const TTL_MS = 10 * 60 * 1000;
const CODE_RE = /^[A-Z0-9-]{4,32}$/;

function norm(v: unknown): string {
  return String(v ?? "").trim().toUpperCase();
}

export const Route = createFileRoute("/api/public/spotify_drop")({
  server: {
    handlers: {
      OPTIONS: async () => new Response(null, { status: 204, headers: cors }),

      POST: async ({ request }) => {
        let body: any = {};
        try { body = await request.json(); } catch {}
        const code = norm(body.code);
        const access_token = String(body.access_token || "").trim();
        const refresh_token = body.refresh_token ? String(body.refresh_token) : null;
        const expires_in = Number(body.expires_in) || null;
        if (!CODE_RE.test(code) || !access_token) {
          return new Response(JSON.stringify({ error: "bad payload" }), { status: 400, headers: cors });
        }
        const { supabaseAdmin } = await import("@/integrations/supabase/client.server");
        await supabaseAdmin.from("spotify_drops").delete().eq("code", code);
        const { error } = await supabaseAdmin
          .from("spotify_drops")
          .insert({ code, access_token, refresh_token, expires_in });
        if (error) return new Response(JSON.stringify({ error: error.message }), { status: 500, headers: cors });
        return new Response(JSON.stringify({ ok: true }), { status: 200, headers: cors });
      },

      GET: async ({ request }) => {
        const url = new URL(request.url);
        const code = norm(url.searchParams.get("code"));
        if (!CODE_RE.test(code)) {
          return new Response(JSON.stringify({ error: "bad code" }), { status: 400, headers: cors });
        }
        const { supabaseAdmin } = await import("@/integrations/supabase/client.server");
        // Best-effort GC: drop anything older than TTL.
        const cutoff = new Date(Date.now() - TTL_MS).toISOString();
        void supabaseAdmin.from("spotify_drops").delete().lt("created_at", cutoff)
          .then(() => undefined, () => undefined);

        const { data, error } = await supabaseAdmin
          .from("spotify_drops")
          .select("access_token, refresh_token, expires_in, created_at")
          .eq("code", code)
          .maybeSingle();
        if (error) return new Response(JSON.stringify({ error: error.message }), { status: 500, headers: cors });
        if (!data) return new Response(JSON.stringify({ pending: true }), { status: 200, headers: cors });
        if (Date.now() - new Date(data.created_at).getTime() > TTL_MS) {
          await supabaseAdmin.from("spotify_drops").delete().eq("code", code);
          return new Response(JSON.stringify({ pending: true, expired: true }), { status: 200, headers: cors });
        }
        // One-shot read: delete after handing it out.
        await supabaseAdmin.from("spotify_drops").delete().eq("code", code);
        return new Response(JSON.stringify({
          access_token: data.access_token,
          refresh_token: data.refresh_token,
          expires_in: data.expires_in,
        }), { status: 200, headers: cors });
      },
    },
  },
});
