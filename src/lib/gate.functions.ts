import { createServerFn } from "@tanstack/react-start";
import {
  getRequestHeader,
  setResponseHeader,
} from "@tanstack/react-start/server";

const DEVICE_COOKIE = "seige_did";
const UNLOCK_COOKIE = "seige_unlocked";
const COOKIE_MAX_AGE = 60 * 60 * 24 * 365; // 1 year for device id
const UNLOCK_MAX_AGE = 60 * 60 * 24 * 7; // 7 days unlock

function getSecret(): string {
  const s = process.env.GATE_SECRET;
  if (!s) throw new Error("GATE_SECRET not set");
  return s;
}

function parseCookies(header: string | undefined | null): Record<string, string> {
  const out: Record<string, string> = {};
  if (!header) return out;
  for (const part of header.split(";")) {
    const idx = part.indexOf("=");
    if (idx < 0) continue;
    const k = part.slice(0, idx).trim();
    const v = part.slice(idx + 1).trim();
    if (k) out[k] = decodeURIComponent(v);
  }
  return out;
}

function getCookie(name: string): string | undefined {
  return parseCookies(getRequestHeader("cookie"))[name];
}

function appendSetCookie(cookie: string) {
  setResponseHeader("set-cookie", cookie);
}

function makeCookie(name: string, value: string, maxAge: number): string {
  return `${name}=${encodeURIComponent(value)}; Path=/; Max-Age=${maxAge}; HttpOnly; Secure; SameSite=Lax`;
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

// Code = 8 hex chars formatted XXXX-XXXX, deterministic per device.
export async function codeForDevice(deviceId: string): Promise<string> {
  const h = await hmacHex(getSecret(), `code:${deviceId}`);
  const c = h.slice(0, 8).toUpperCase();
  return `${c.slice(0, 4)}-${c.slice(4, 8)}`;
}

async function unlockTokenFor(deviceId: string): Promise<string> {
  return (await hmacHex(getSecret(), `unlock:${deviceId}`)).slice(0, 32);
}

function timingSafeEq(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

/** Ensure the visitor has a device id cookie; return it. */
export function ensureDeviceId(): string {
  let id = getCookie(DEVICE_COOKIE);
  if (!id || id.length < 8) {
    id = randomId();
    appendSetCookie(makeCookie(DEVICE_COOKIE, id, COOKIE_MAX_AGE));
  }
  return id;
}

/** Server-callable: is THIS device currently unlocked? */
export const isUnlocked = createServerFn({ method: "GET" }).handler(async () => {
  const id = getCookie(DEVICE_COOKIE);
  const token = getCookie(UNLOCK_COOKIE);
  if (!id || !token) return { unlocked: false as const };
  const expected = await unlockTokenFor(id);
  return { unlocked: timingSafeEq(token, expected) };
});

/** Server-callable: verify the typed code against this device's bound code. */
export const unlockSite = createServerFn({ method: "POST" })
  .inputValidator((data: { code: string }) => {
    if (typeof data?.code !== "string") throw new Error("code required");
    return { code: data.code.trim().toUpperCase().replace(/\s+/g, "") };
  })
  .handler(async ({ data }) => {
    const id = getCookie(DEVICE_COOKIE);
    if (!id) return { ok: false as const, error: "Visit the code page first." };
    const expected = await codeForDevice(id);
    const normalized = data.code.includes("-")
      ? data.code
      : `${data.code.slice(0, 4)}-${data.code.slice(4, 8)}`;
    if (!timingSafeEq(normalized, expected)) {
      return { ok: false as const, error: "Wrong code." };
    }
    const token = await unlockTokenFor(id);
    appendSetCookie(makeCookie(UNLOCK_COOKIE, token, UNLOCK_MAX_AGE));
    return { ok: true as const };
  });
