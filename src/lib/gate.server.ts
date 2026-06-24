import {
  getRequestHeader,
  setResponseHeader,
} from "@tanstack/react-start/server";

export const DEVICE_COOKIE = "seige_did";
export const UNLOCK_COOKIE = "seige_unlocked";
export const COOKIE_MAX_AGE = 60 * 60 * 24 * 365;
export const UNLOCK_MAX_AGE = 60 * 60 * 24 * 7;

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

export function getCookieValue(name: string): string | undefined {
  return parseCookies(getRequestHeader("cookie"))[name];
}

export function setCookieHeader(name: string, value: string, maxAge: number) {
  setResponseHeader(
    "set-cookie",
    `${name}=${encodeURIComponent(value)}; Path=/; Max-Age=${maxAge}; HttpOnly; Secure; SameSite=Lax`,
  );
}

export function randomId(): string {
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

export async function codeForDevice(deviceId: string): Promise<string> {
  const h = (await hmacHex(getSecret(), `code:${deviceId}`)).slice(0, 8).toUpperCase();
  return `${h.slice(0, 4)}-${h.slice(4, 8)}`;
}

export async function unlockTokenFor(deviceId: string): Promise<string> {
  return (await hmacHex(getSecret(), `unlock:${deviceId}`)).slice(0, 32);
}

export function timingSafeEq(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}
