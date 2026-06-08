import { createFileRoute } from "@tanstack/react-router";

// Backed by a GitHub Gist. Path/auth kept as-is so the in-game loader keeps working.
const GIST_FILENAME = "seige_tags.txt";

function gistApiUrl(): string {
  const id = process.env.GITHUB_GIST_ID!;
  return `https://api.github.com/gists/${id}`;
}

function ghHeaders(): HeadersInit {
  return {
    Authorization: `Bearer ${process.env.GITHUB_GIST_TOKEN!}`,
    Accept: "application/vnd.github+json",
    "X-GitHub-Api-Version": "2022-11-28",
    "User-Agent": "seige-tag-sync",
  };
}

async function readGist(): Promise<string> {
  const res = await fetch(gistApiUrl(), {
    headers: ghHeaders(),
    cache: "no-store",
  });
  if (!res.ok) throw new Error(`gist read failed: HTTP ${res.status} ${await res.text()}`);
  const json = (await res.json()) as {
    files: Record<string, { filename: string; content: string; truncated?: boolean; raw_url?: string }>;
  };
  const file =
    json.files[GIST_FILENAME] ?? Object.values(json.files)[0];
  if (!file) throw new Error("gist has no files");
  if (file.truncated && file.raw_url) {
    const raw = await fetch(file.raw_url, { cache: "no-store" });
    if (!raw.ok) throw new Error(`gist raw fetch failed: HTTP ${raw.status}`);
    return await raw.text();
  }
  return file.content ?? "";
}

async function writeGist(body: string): Promise<{ ok: true; url: string } | { ok: false; error: string }> {
  const res = await fetch(gistApiUrl(), {
    method: "PATCH",
    headers: { ...ghHeaders(), "Content-Type": "application/json" },
    body: JSON.stringify({
      files: { [GIST_FILENAME]: { content: body } },
    }),
  });
  const txt = await res.text();
  if (!res.ok) return { ok: false, error: `HTTP ${res.status}: ${txt}` };
  try {
    const json = JSON.parse(txt) as {
      html_url: string;
      files: Record<string, { raw_url: string }>;
    };
    const raw = json.files[GIST_FILENAME]?.raw_url ?? json.html_url;
    // Strip the commit sha so the URL always serves the latest revision.
    const stable = raw.replace(
      /\/raw\/[0-9a-f]+\//,
      "/raw/",
    );
    return { ok: true, url: stable };
  } catch {
    return { ok: true, url: "" };
  }
}

function authorized(request: Request): boolean {
  const expected = process.env.PASTEBIN_USER_KEY;
  if (!expected) return false;
  const header = request.headers.get("x-pastebin-auth") || "";
  return header === expected;
}

export const Route = createFileRoute("/api/public/pastebin")({
  server: {
    handlers: {
      GET: async ({ request }) => {
        const url = new URL(request.url);
        const wantRaw = url.searchParams.get("raw") === "1";
        // Reads are public (the underlying gist is public anyway). Writes still require auth.
        try {
          const text = await readGist();
          if (wantRaw) {
            return new Response(text, {
              status: 200,
              headers: {
                "Content-Type": "text/plain; charset=utf-8",
                "Cache-Control": "no-store",
              },
            });
          }
          if (!authorized(request)) {
            return Response.json({ ok: false, error: "unauthorized" }, { status: 401 });
          }
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
        if (!authorized(request)) {
          return Response.json({ ok: false, error: "unauthorized" }, { status: 401 });
        }
        let payload: { body?: string };
        try {
          payload = await request.json();
        } catch {
          return Response.json({ ok: false, error: "invalid JSON body" }, { status: 400 });
        }
        if (typeof payload.body !== "string" || payload.body.length === 0) {
          return Response.json({ ok: false, error: "`body` (string) required" }, { status: 400 });
        }
        if (payload.body.length > 1_000_000) {
          return Response.json({ ok: false, error: "body too large" }, { status: 413 });
        }
        const result = await writeGist(payload.body);
        return Response.json(result, { status: result.ok ? 200 : 502 });
      },
    },
  },
});
