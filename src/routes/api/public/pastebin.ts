import { createFileRoute } from "@tanstack/react-router";

// Backed by a GitHub Gist. Path/auth kept as-is so the in-game loader keeps working.
const GIST_FILENAME = "seige_tags.txt";
const TAGS_JSON_FORMAT = "seige.tags.v2";

type TagEntry = Record<string, string | string[]>;

function trim(value: unknown): string {
  return String(value ?? "").trim();
}

function cleanEntry(entry: Record<string, unknown>): TagEntry | null {
  const allowed = [
    "displayName", "color", "icon", "textFx", "customText", "customHandle",
    "outline", "font", "textColor", "textOutline", "avatarOutline", "showChip",
  ];
  const out: TagEntry = {};
  for (const key of allowed) {
    const value = trim(entry[key]);
    if (value) out[key] = value;
  }
  const rawTags = entry.tags;
  const tags = Array.isArray(rawTags)
    ? rawTags.map(trim).filter(Boolean)
    : trim(rawTags).split(",").map(trim).filter(Boolean);
  if (tags.length) out.tags = tags;
  return Object.keys(out).length ? out : null;
}

function encodeTags(entries: Record<string, TagEntry>): string {
  return JSON.stringify({ version: 2, format: TAGS_JSON_FORMAT, tags: entries });
}

function parseJsonTags(src: string): { entries: Record<string, TagEntry>; count: number } | null {
  const matches = [...src.matchAll(/\{\s*"(?:version|format)"\s*:/g)];
  const start = matches.length ? matches[matches.length - 1].index ?? -1 : -1;
  const end = src.lastIndexOf("}");
  if (start < 0 || end < start) return null;
  try {
    const decoded = JSON.parse(src.slice(start, end + 1)) as { tags?: unknown; entries?: unknown } | Record<string, unknown>;
    const source = ("tags" in decoded && decoded.tags) || ("entries" in decoded && decoded.entries) || decoded;
    if (!source || typeof source !== "object" || Array.isArray(source)) return null;
    const entries: Record<string, TagEntry> = {};
    for (const [rawKey, rawEntry] of Object.entries(source as Record<string, unknown>)) {
      const key = trim(rawKey).replace(/^@/, "").toLowerCase();
      if (!key || !rawEntry || typeof rawEntry !== "object" || Array.isArray(rawEntry)) continue;
      const clean = cleanEntry(rawEntry as Record<string, unknown>);
      if (clean) entries[key] = clean;
    }
    return { entries, count: Object.keys(entries).length };
  } catch {
    return null;
  }
}

function parseLegacyRows(src: string): { entries: Record<string, TagEntry>; count: number } {
  const entries: Record<string, TagEntry> = {};
  for (const rawLine of src.split(/\r?\n/)) {
    const line = rawLine.trim();
    if (!line || line.startsWith("#") || line.startsWith("//") || line.startsWith("{")) continue;
    const parts = line.split("|").map(trim);
    const key = trim(parts[0]).replace(/^@/, "").toLowerCase();
    if (!key) continue;
    const entry: Record<string, unknown> = {
      displayName: parts[1], color: parts[2], icon: parts[4], tags: parts[5],
      textFx: parts[6], customText: parts[7], customHandle: parts[8], outline: parts[9],
      font: parts[10], textColor: parts[12], textOutline: parts[13], avatarOutline: parts[14], showChip: parts[15],
    };
    const clean = cleanEntry(entry);
    if (clean) entries[key] = clean;
  }
  return { entries, count: Object.keys(entries).length };
}

function normalizeTagContent(src: string): string {
  const json = parseJsonTags(src);
  const legacy = parseLegacyRows(src);
  if (json && (json.count > 0 || legacy.count === 0)) return encodeTags(json.entries);
  if (legacy.count > 0) return encodeTags(legacy.entries);
  return encodeTags({});
}

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
  let content = "";
  if (file.truncated && file.raw_url) {
    const raw = await fetch(file.raw_url, { cache: "no-store" });
    if (!raw.ok) throw new Error(`gist raw fetch failed: HTTP ${raw.status}`);
    content = await raw.text();
  } else {
    content = file.content ?? "";
  }
  return normalizeTagContent(content);
}

async function writeGist(body: string): Promise<{ ok: true; url: string } | { ok: false; error: string }> {
  const normalizedBody = normalizeTagContent(body);
  const res = await fetch(gistApiUrl(), {
    method: "PATCH",
    headers: { ...ghHeaders(), "Content-Type": "application/json" },
    body: JSON.stringify({
      files: { [GIST_FILENAME]: { content: normalizedBody } },
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
  const url = new URL(request.url);
  const header = request.headers.get("x-pastebin-auth") || "";
  const queryKey = url.searchParams.get("key") || "";
  return header === expected || queryKey === expected;
}

export const Route = createFileRoute("/api/public/pastebin")({
  server: {
    handlers: {
      GET: async ({ request }) => {
        const url = new URL(request.url);
        const wantRaw = url.searchParams.get("raw") === "1";
        const writeBody = url.searchParams.get("body");
        // Reads are public (the underlying gist is public anyway). Writes still require auth.
        try {
          if (writeBody !== null) {
            if (!authorized(request)) {
              return Response.json({ ok: false, error: "unauthorized" }, { status: 401 });
            }
            if (writeBody.length === 0) {
              return Response.json({ ok: false, error: "`body` required" }, { status: 400 });
            }
            if (writeBody.length > 1_000_000) {
              return Response.json({ ok: false, error: "body too large" }, { status: 413 });
            }
            const result = await writeGist(writeBody);
            return Response.json(result, { status: result.ok ? 200 : 502 });
          }

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
