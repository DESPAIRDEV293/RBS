import { createFileRoute } from "@tanstack/react-router";

const RAW_URL = (key: string) => `https://pastebin.com/raw/${key}`;

async function readPaste(): Promise<string> {
  const key = process.env.PASTEBIN_PASTE_KEY!;
  const res = await fetch(`${RAW_URL(key)}?v=${Date.now()}`, { cache: "no-store" });
  if (!res.ok) throw new Error(`read failed: HTTP ${res.status}`);
  return await res.text();
}

async function writePaste(body: string): Promise<{ ok: true; url: string } | { ok: false; error: string }> {
  const dev = process.env.PASTEBIN_DEV_KEY!;
  const user = process.env.PASTEBIN_USER_KEY!;
  const key = process.env.PASTEBIN_PASTE_KEY!;
  const form = new URLSearchParams({
    api_dev_key: dev,
    api_user_key: user,
    api_paste_key: key,
    api_option: "edit",
    api_paste_code: body,
    api_paste_name: "seige_tags",
    api_paste_format: "text",
    api_paste_private: "1",
    api_paste_expire_date: "N",
  });
  const res = await fetch("https://pastebin.com/api/api_post.php", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: form.toString(),
  });
  const txt = (await res.text()).trim();
  if (!res.ok || txt.toLowerCase().startsWith("bad api request")) {
    return { ok: false, error: txt || `HTTP ${res.status}` };
  }
  return { ok: true, url: txt };
}

export const Route = createFileRoute("/api/public/pastebin")({
  server: {
    handlers: {
      GET: async () => {
        try {
          const text = await readPaste();
          const lines = text.split("\n").filter((l) => l.trim().length > 0);
          return Response.json({ ok: true, lineCount: lines.length, raw: text });
        } catch (e) {
          return Response.json(
            { ok: false, error: e instanceof Error ? e.message : String(e) },
            { status: 500 },
          );
        }
      },
      POST: async ({ request }) => {
        let payload: { body?: string };
        try {
          payload = await request.json();
        } catch {
          return Response.json({ ok: false, error: "invalid JSON body" }, { status: 400 });
        }
        if (typeof payload.body !== "string" || payload.body.length === 0) {
          return Response.json({ ok: false, error: "`body` (string) required" }, { status: 400 });
        }
        if (payload.body.length > 500_000) {
          return Response.json({ ok: false, error: "body too large" }, { status: 413 });
        }
        const result = await writePaste(payload.body);
        return Response.json(result, { status: result.ok ? 200 : 502 });
      },
    },
  },
});
