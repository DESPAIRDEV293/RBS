import { createFileRoute } from "@tanstack/react-router";

// Exchanges a Spotify authorization code for an access token using
// user-supplied client_id / client_secret. Nothing is persisted by this
// endpoint — credentials live only for the duration of this request.

const cors = {
  "access-control-allow-origin": "*",
  "access-control-allow-methods": "POST, OPTIONS",
  "access-control-allow-headers": "Content-Type",
  "content-type": "application/json",
} as const;

export const Route = createFileRoute("/api/public/spotify_exchange")({
  server: {
    handlers: {
      OPTIONS: async () => new Response(null, { status: 204, headers: cors }),
      POST: async ({ request }) => {
        let body: any = {};
        try { body = await request.json(); } catch { /* ignore */ }
        const client_id = String(body.client_id || "").trim();
        const client_secret = String(body.client_secret || "").trim();
        const code = String(body.code || "").trim();
        const redirect_uri = String(body.redirect_uri || "").trim();
        if (!client_id || !client_secret || !code || !redirect_uri) {
          return new Response(JSON.stringify({ error: "missing fields" }), { status: 400, headers: cors });
        }
        const form = new URLSearchParams({ grant_type: "authorization_code", code, redirect_uri }).toString();
        const basic = Buffer.from(`${client_id}:${client_secret}`).toString("base64");
        const r = await fetch("https://accounts.spotify.com/api/token", {
          method: "POST",
          headers: { Authorization: `Basic ${basic}`, "Content-Type": "application/x-www-form-urlencoded" },
          body: form,
        });
        const data: any = await r.json().catch(() => ({}));
        if (!r.ok || !data.access_token) {
          return new Response(JSON.stringify({ error: data.error_description || data.error || "exchange failed", detail: data }), { status: 502, headers: cors });
        }
        return new Response(JSON.stringify({
          access_token: data.access_token,
          refresh_token: data.refresh_token,
          expires_in: data.expires_in,
        }), { status: 200, headers: cors });
      },
    },
  },
});
