import { createFileRoute } from "@tanstack/react-router";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, x-tag-secret",
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

// Tag groups are stored as a single JSONB blob in tag_entries under this key.
// Keeping the shape inside the existing table avoids a schema migration.
const STORAGE_KEY = "__tag_groups__";
const VALID_GROUPS = new Set([
  "OWNERS",
  "ADMINS",
  "CO_OWNERS",
  "LINE_USERS",
  "BLACKLIST",
]);

type GroupMap = Record<string, string[]>;

function emptyGroups(): GroupMap {
  return {
    OWNERS: [],
    ADMINS: [],
    CO_OWNERS: [],
    LINE_USERS: [],
    BLACKLIST: [],
  };
}

export const Route = createFileRoute("/api/public/tag_groups")({
  server: {
    handlers: {
      OPTIONS: async () => new Response(null, { status: 204, headers: CORS }),

      GET: async () => {
        const { supabaseAdmin } = await import(
          "@/integrations/supabase/client.server"
        );
        const { data, error } = await supabaseAdmin
          .from("tag_entries")
          .select("data")
          .eq("key", STORAGE_KEY)
          .maybeSingle();
        if (error) return json({ error: error.message }, 500);
        const groups: GroupMap = emptyGroups();
        const stored = (data?.data as GroupMap | null) ?? null;
        if (stored && typeof stored === "object") {
          for (const k of VALID_GROUPS) {
            const list = Array.isArray(stored[k]) ? stored[k] : [];
            groups[k] = list.filter((u) => typeof u === "string");
          }
        }
        return json(groups);
      },

      POST: async ({ request }) => {
        const secret = request.headers.get("x-tag-secret") ?? "";
        const expected = process.env.TAG_WRITE_SECRET ?? "";
        if (!expected || secret !== expected) {
          return json({ error: "unauthorized" }, 401);
        }

        let body: any;
        try {
          body = await request.json();
        } catch {
          return json({ error: "invalid json" }, 400);
        }

        const username =
          typeof body?.username === "string"
            ? body.username.trim().toLowerCase()
            : "";
        const group =
          typeof body?.tag_group === "string"
            ? body.tag_group.trim().toUpperCase()
            : "";
        const remove = body?.remove === true;

        if (!username || username.length > 64 || !/^[a-z0-9_]+$/.test(username)) {
          return json({ error: "invalid username" }, 400);
        }
        if (!VALID_GROUPS.has(group)) {
          return json({ error: "invalid tag_group" }, 400);
        }

        const { supabaseAdmin } = await import(
          "@/integrations/supabase/client.server"
        );

        const { data: existing, error: readErr } = await supabaseAdmin
          .from("tag_entries")
          .select("data")
          .eq("key", STORAGE_KEY)
          .maybeSingle();
        if (readErr) return json({ error: readErr.message }, 500);

        const groups: GroupMap = emptyGroups();
        const stored = (existing?.data as GroupMap | null) ?? null;
        if (stored && typeof stored === "object") {
          for (const k of VALID_GROUPS) {
            const list = Array.isArray(stored[k]) ? stored[k] : [];
            groups[k] = list.filter((u) => typeof u === "string");
          }
        }

        // Remove from every group first (a user belongs to one group at a time),
        // then add to the requested group unless this is a delete.
        for (const k of VALID_GROUPS) {
          groups[k] = groups[k].filter((u) => u !== username);
        }
        if (!remove) {
          groups[group].push(username);
        }

        const { error: writeErr } = await supabaseAdmin
          .from("tag_entries")
          .upsert({ key: STORAGE_KEY, data: groups }, { onConflict: "key" });
        if (writeErr) return json({ error: writeErr.message }, 500);

        return json({ ok: true, groups });
      },
    },
  },
});
