import { createServerFn } from "@tanstack/react-start";

const TARGETS = [
  "https://seigescript.online/api/public/loader.lua",
  "https://seigescript.online/api/public/admin.lua",
  "https://seigelollua.lovable.app/api/public/admin.lua",
  "https://raw.githubusercontent.com/DESPAIRDEV293/roblox-script-buddy/main/admin.lua",
];

export const validateScriptLink = createServerFn({ method: "GET" }).handler(async () => {
  const results = await Promise.all(
    TARGETS.map(async (url) => {
      const started = Date.now();
      try {
        const res = await fetch(url + "?fresh=" + Date.now(), {
          method: "GET",
          headers: { "user-agent": "Roblox/WinInet", "cache-control": "no-cache" },
        });
        const text = await res.text();
        const ms = Date.now() - started;
        const ct = res.headers.get("content-type") || "";
        const looksLikeLua =
          /loadstring|game:GetService|local\s+\w+\s*=|--\[\[|function\s+/i.test(text);
        const sizeKb = +(text.length / 1024).toFixed(1);
        const firstLine = (text.split("\n").find((l) => l.trim().length) || "").slice(0, 120);
        return {
          url,
          ok: res.ok && looksLikeLua,
          status: res.status,
          statusText: res.statusText,
          contentType: ct,
          sizeKb,
          ms,
          looksLikeLua,
          firstLine,
          error: null as string | null,
        };
      } catch (e: any) {
        return {
          url,
          ok: false,
          status: 0,
          statusText: "fetch failed",
          contentType: "",
          sizeKb: 0,
          ms: Date.now() - started,
          looksLikeLua: false,
          firstLine: "",
          error: String(e?.message || e),
        };
      }
    }),
  );
  return { checkedAt: new Date().toISOString(), results };
});
