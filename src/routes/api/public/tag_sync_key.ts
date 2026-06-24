import { createFileRoute } from "@tanstack/react-router";

// Returns the TAG_WRITE_SECRET to authorized staff so they can paste it into
// the in-game Config → "Tag sync key" box. Authorization is decided
// server-side from role_entries; the secret is NEVER baked into admin.lua.

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type",
  "Access-Control-Max-Age": "86400",
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      "cache-control": "no-store",
      ...CORS,
    },
  });
}

const OWNER_NAME = "0rot3";
const ALLOWED_ROLES = new Set(["owner", "admin", "nt", "staff"]);

export const Route = createFileRoute("/api/public/tag_sync_key")({
  server: {
    handlers: {
      OPTIONS: async () => new Response(null, { status: 204, headers: CORS }),

      POST: async ({ request }) => {
        let body: any;
        try {
          body = await request.json();
        } catch {
          return json({ error: "invalid json" }, 400);
        }
        const actor =
          typeof body?.actor === "string"
            ? body.actor.trim().toLowerCase()
            : "";
        if (!actor || !/^[a-z0-9_]+$/.test(actor) || actor.length > 64) {
          return json({ error: "invalid actor" }, 400);
        }

        let role: string | null =
          actor === OWNER_NAME.toLowerCase() ? "owner" : null;
        if (!role) {
          const { supabaseAdmin } = await import(
            "@/integrations/supabase/client.server"
          );
          const { data, error } = await supabaseAdmin
            .from("role_entries")
            .select("role")
            .eq("key", actor)
            .maybeSingle();
          if (error) return json({ error: error.message }, 500);
          role = data?.role ?? null;
        }
        if (!role || !ALLOWED_ROLES.has(role)) {
          return json({ error: "forbidden", role }, 403);
        }

        const key = process.env.TAG_WRITE_SECRET ?? "";
        if (!key) return json({ error: "secret not configured" }, 500);
        return json({ ok: true, key, role });
      },
    },
  },
});
