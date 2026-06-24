import { createFileRoute } from "@tanstack/react-router";

// Proxy endpoint so admin.lua can persist in-game tag edits WITHOUT shipping
// the TAG_WRITE_SECRET to every Roblox client. Authorization is decided
// server-side from the role_entries table (same source the in-game role
// gates use). Allowed: hardcoded owner username, plus anyone whose role is
// owner / admin / nt.

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
const ALLOWED_ROLES = new Set(["owner", "admin", "nt"]);

export const Route = createFileRoute("/api/public/tags_write")({
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
        const key =
          typeof body?.key === "string" ? body.key.trim().toLowerCase() : "";
        if (!actor || !/^[a-z0-9_]+$/.test(actor) || actor.length > 64) {
          return json({ error: "invalid actor" }, 400);
        }
        if (!key || !/^[a-z0-9_]+$/.test(key) || key.length > 64) {
          return json({ error: "invalid key" }, 400);
        }

        const { supabaseAdmin } = await import(
          "@/integrations/supabase/client.server"
        );

        // Authorize the actor.
        let role: string | null = actor === OWNER_NAME.toLowerCase() ? "owner" : null;
        if (!role) {
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

        if (body?.delete === true) {
          const { error } = await supabaseAdmin
            .from("tag_entries")
            .delete()
            .eq("key", key);
          if (error) return json({ error: error.message }, 500);
          return json({ ok: true, deleted: key, actor, role });
        }

        if (typeof body?.data !== "object" || body.data === null) {
          return json({ error: "data must be an object" }, 400);
        }

        const { error } = await supabaseAdmin
          .from("tag_entries")
          .upsert({ key, data: body.data }, { onConflict: "key" });
        if (error) return json({ error: error.message }, 500);
        return json({ ok: true, key, actor, role });
      },
    },
  },
});
