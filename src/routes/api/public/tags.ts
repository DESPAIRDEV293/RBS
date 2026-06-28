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
    headers: { "Content-Type": "application/json", ...CORS },
  });
}

const ALLOWED_FIELDS = new Set([
  "displayName",
  "color",
  "icon",
  "tags",
  "textFx",
  "customText",
  "customHandle",
  "outline",
  "font",
  "textColor",
  "textOutline",
  "avatarOutline",
  "avatarOutlineColor",
  "showChip",
]);

function cleanTagData(input: Record<string, unknown>) {
  const out: Record<string, string | string[]> = {};
  for (const [field, value] of Object.entries(input)) {
    if (!ALLOWED_FIELDS.has(field)) continue;
    if (field === "tags") {
      const tags = Array.isArray(value)
        ? value.map((v) => String(v ?? "").trim()).filter(Boolean)
        : String(value ?? "")
            .split(",")
            .map((v) => v.trim())
            .filter(Boolean);
      if (tags.length) out.tags = tags;
      continue;
    }
    const text = String(value ?? "").trim();
    if (text) out[field] = text;
  }
  return out;
}

export const Route = createFileRoute("/api/public/tags")({
  server: {
    handlers: {
      OPTIONS: async () => new Response(null, { status: 204, headers: CORS }),

      GET: async () => {
        const { supabaseAdmin } = await import(
          "@/integrations/supabase/client.server"
        );
        const { data, error } = await supabaseAdmin
          .from("tag_entries")
          .select("key,data");
        if (error) return json({ error: error.message }, 500);
        const entries: Record<string, unknown> = {};
        for (const row of data ?? []) entries[row.key] = row.data;
        return json({ entries });
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

        const rawKey = typeof body?.key === "string" ? body.key.trim().toLowerCase() : "";
        if (!rawKey || rawKey.length > 64 || !/^[a-z0-9_]+$/.test(rawKey)) {
          return json({ error: "invalid key" }, 400);
        }

        const { supabaseAdmin } = await import(
          "@/integrations/supabase/client.server"
        );

        if (body?.delete === true) {
          const { error } = await supabaseAdmin
            .from("tag_entries")
            .delete()
            .eq("key", rawKey);
          if (error) return json({ error: error.message }, 500);
          return json({ ok: true, deleted: rawKey });
        }

        if (typeof body?.data !== "object" || body.data === null) {
          return json({ error: "data must be an object" }, 400);
        }

        const clean = cleanTagData(body.data as Record<string, unknown>);
        if (Object.keys(clean).length === 0) {
          return json({ error: "data has no valid tag fields" }, 400);
        }

        const { error } = await supabaseAdmin
          .from("tag_entries")
          .upsert({ key: rawKey, data: clean }, { onConflict: "key" });
        if (error) return json({ error: error.message }, 500);
        return json({ ok: true, key: rawKey });
      },
    },
  },
});
