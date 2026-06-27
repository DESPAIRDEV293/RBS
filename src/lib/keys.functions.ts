import { createServerFn } from "@tanstack/react-start";

const KEY_COOKIE = "seige_key_token";
const KEY_COOKIE_MAX_AGE = 60 * 60 * 24 * 30; // 30 days; key itself may expire sooner

function makeKey(): { key: string; token: string } {
  const bytes = new Uint8Array(16);
  crypto.getRandomValues(bytes);
  const hex = Array.from(bytes, (b) => b.toString(16).padStart(2, "0")).join("").toUpperCase();
  const key = `SEIGE-${hex.slice(0, 4)}-${hex.slice(4, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 20)}`;
  const tBuf = new Uint8Array(8);
  crypto.getRandomValues(tBuf);
  const token = Array.from(tBuf, (b) => b.toString(16).padStart(2, "0")).join("");
  return { key, token };
}

export const getOrIssueKey = createServerFn({ method: "POST" }).handler(async () => {
  const { supabaseAdmin } = await import("@/integrations/supabase/client.server");
  const {
    getCookieValue,
    setCookieHeader,
    codeForDevice,
    randomId,
    DEVICE_COOKIE,
    COOKIE_MAX_AGE,
    OWNER_CODES,
  } = await import("./gate.server");

  // Ensure device cookie exists
  let deviceId = getCookieValue(DEVICE_COOKIE);
  if (!deviceId || deviceId.length < 8) {
    deviceId = randomId();
    setCookieHeader(DEVICE_COOKIE, deviceId, COOKIE_MAX_AGE);
  }

  const derivedCode = await codeForDevice(deviceId);
  const isOwnerDevice = OWNER_CODES.has(derivedCode);

  // Try to reuse the existing token cookie if its key is still active
  const existingToken = getCookieValue(KEY_COOKIE);
  if (existingToken) {
    const { data } = await supabaseAdmin
      .from("script_keys")
      .select("key, token, tier, expires_at, revoked")
      .eq("token", existingToken)
      .maybeSingle();
    if (data && !data.revoked) {
      const stillValid = !data.expires_at || new Date(data.expires_at).getTime() > Date.now();
      if (stillValid) {
        return { token: data.token, key: data.key, tier: data.tier, expires_at: data.expires_at };
      }
    }
  }

  // Mint a new key
  const { key, token } = makeKey();
  const tier = isOwnerDevice ? "admin" : "normal";
  const expires_at = isOwnerDevice ? null : new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString();

  const { error } = await supabaseAdmin.from("script_keys").insert({
    key,
    token,
    tier,
    label: isOwnerDevice ? `owner-device-${derivedCode}` : null,
    device_id: deviceId,
    expires_at,
  });
  if (error) throw new Error(error.message);

  setCookieHeader(KEY_COOKIE, token, KEY_COOKIE_MAX_AGE);
  return { token, key, tier, expires_at };
});
