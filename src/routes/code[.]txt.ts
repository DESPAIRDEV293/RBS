import { createFileRoute } from "@tanstack/react-router";
import { codeForDevice } from "@/lib/gate.functions";

const DEVICE_COOKIE = "seige_did";

function parseCookies(header: string | null): Record<string, string> {
  const out: Record<string, string> = {};
  if (!header) return out;
  for (const part of header.split(";")) {
    const i = part.indexOf("=");
    if (i < 0) continue;
    out[part.slice(0, i).trim()] = decodeURIComponent(part.slice(i + 1).trim());
  }
  return out;
}

function randomId(): string {
  const buf = new Uint8Array(16);
  crypto.getRandomValues(buf);
  return Array.from(buf, (b) => b.toString(16).padStart(2, "0")).join("");
}

async function hmacHex(secret: string, msg: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(msg));
  return Array.from(new Uint8Array(sig), (b) => b.toString(16).padStart(2, "0")).join("");
}

async function deriveCode(deviceId: string): Promise<string> {
  void codeForDevice; // keep tree-shake happy if unused
  const secret = process.env.GATE_SECRET;
  if (!secret) throw new Error("GATE_SECRET not set");
  const h = (await hmacHex(secret, `code:${deviceId}`)).slice(0, 8).toUpperCase();
  return `${h.slice(0, 4)}-${h.slice(4, 8)}`;
}

export const Route = createFileRoute("/code.txt")({
  server: {
    handlers: {
      GET: async ({ request }) => {
        const cookies = parseCookies(request.headers.get("cookie"));
        let id = cookies[DEVICE_COOKIE];
        const headers = new Headers({
          "content-type": "text/plain; charset=utf-8",
          "cache-control": "no-store",
        });
        if (!id || id.length < 8) {
          id = randomId();
          headers.append(
            "set-cookie",
            `${DEVICE_COOKIE}=${id}; Path=/; Max-Age=${60 * 60 * 24 * 365}; HttpOnly; Secure; SameSite=Lax`,
          );
        }
        const code = await deriveCode(id);
        const body =
          `==============================\n` +
          `   SEIGE SITE ACCESS CODE\n` +
          `==============================\n\n` +
          `Your access code (bound to THIS device/browser):\n\n` +
          `      ${code}\n\n` +
          `Paste it back into the unlock page on the same\n` +
          `device. The code will not work on any other\n` +
          `device or browser.\n\n` +
          `Unlock lasts 7 days after you enter it.\n`;
        return new Response(body, { status: 200, headers });
      },
    },
  },
});
