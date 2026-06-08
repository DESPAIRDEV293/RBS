import { createServerFn } from "@tanstack/react-start";

export const mintPastebinUserKey = createServerFn({ method: "POST" })
  .inputValidator((data: { devKey: string; username: string; password: string }) => {
    if (!data.devKey || !data.username || !data.password) {
      throw new Error("devKey, username, and password are all required");
    }
    return data;
  })
  .handler(async ({ data }) => {
    const body = new URLSearchParams({
      api_dev_key: data.devKey.trim(),
      api_user_name: data.username.trim(),
      api_user_password: data.password,
    });

    const res = await fetch("https://pastebin.com/api/api_login.php", {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: body.toString(),
    });

    const text = (await res.text()).trim();

    // Pastebin returns either a raw user key OR "Bad API request, <reason>"
    if (!res.ok || text.toLowerCase().startsWith("bad api request")) {
      return { ok: false as const, error: text || `HTTP ${res.status}` };
    }
    return { ok: true as const, userKey: text };
  });
