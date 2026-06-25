import { createServerFn } from "@tanstack/react-start";

export const getMyCode = createServerFn({ method: "GET" }).handler(async () => {
  const {
    getCookieValue,
    setCookieHeader,
    codeForDevice,
    randomId,
    DEVICE_COOKIE,
    COOKIE_MAX_AGE,
  } = await import("./gate.server");
  let id = getCookieValue(DEVICE_COOKIE);
  if (!id || id.length < 8) {
    id = randomId();
    setCookieHeader(DEVICE_COOKIE, id, COOKIE_MAX_AGE);
  }
  const code = await codeForDevice(id);
  return { code };
});

export const isUnlocked = createServerFn({ method: "GET" }).handler(async () => {
  const {
    getCookieValue,
    codeForDevice,
    unlockTokenFor,
    timingSafeEq,
    DEVICE_COOKIE,
    UNLOCK_COOKIE,
    OWNER_CODES,
  } = await import("./gate.server");
  const { getRequestHeader } = await import("@tanstack/react-start/server");
  // Preview / sandbox host bypass: skip the gate on Lovable preview URLs.
  const host = (getRequestHeader("host") || "").toLowerCase();
  if (
    host.includes("id-preview") ||
    host.includes("-dev.lovable.app") ||
    host.startsWith("localhost") ||
    host.startsWith("127.0.0.1")
  ) {
    return { unlocked: true as const };
  }
  const id = getCookieValue(DEVICE_COOKIE);
  if (!id) return { unlocked: false as const };
  // Owner bypass: derived code in allowlist → always unlocked.
  const code = await codeForDevice(id);
  if (OWNER_CODES.has(code)) return { unlocked: true as const };
  const token = getCookieValue(UNLOCK_COOKIE);
  if (!token) return { unlocked: false as const };
  const expected = await unlockTokenFor(id);
  return { unlocked: timingSafeEq(token, expected) };
});

export const unlockSite = createServerFn({ method: "POST" })
  .inputValidator((data: { code: string }) => {
    if (typeof data?.code !== "string") throw new Error("code required");
    return { code: data.code.trim().toUpperCase().replace(/\s+/g, "") };
  })
  .handler(async ({ data }) => {
    const {
      getCookieValue,
      setCookieHeader,
      codeForDevice,
      unlockTokenFor,
      timingSafeEq,
      DEVICE_COOKIE,
      UNLOCK_COOKIE,
      UNLOCK_MAX_AGE,
    } = await import("./gate.server");
    const id = getCookieValue(DEVICE_COOKIE);
    if (!id) return { ok: false as const, error: "Visit the code page first." };
    const expected = await codeForDevice(id);
    const normalized = data.code.includes("-")
      ? data.code
      : `${data.code.slice(0, 4)}-${data.code.slice(4, 8)}`;
    if (!timingSafeEq(normalized, expected)) {
      return { ok: false as const, error: "Wrong code." };
    }
    const token = await unlockTokenFor(id);
    setCookieHeader(UNLOCK_COOKIE, token, UNLOCK_MAX_AGE);
    return { ok: true as const };
  });
