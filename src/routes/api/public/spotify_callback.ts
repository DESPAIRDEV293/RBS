import { createFileRoute } from "@tanstack/react-router";

// Spotify OAuth callback for SEIGE.
// Hardcoded app credentials — only used by the in-game "Login with Spotify"
// button. The Spotify dashboard has this exact URL registered as a redirect
// URI: https://seigescript.online/api/public/spotify_callback

const CLIENT_ID = "6c238740d5df4698b0304c1d88a3e6f2";
const CLIENT_SECRET = "30c88c52c7a148f7bd114b113358f01e";
const REDIRECT_URI = "https://seigescript.online/api/public/spotify_callback";

function page(title: string, body: string, status = 200) {
  const html = `<!doctype html><html><head><meta charset="utf-8"><title>${title}</title>
<meta name="viewport" content="width=device-width,initial-scale=1">
<style>
  body{margin:0;background:#0a0a0f;color:#e7e7ea;font:14px/1.5 ui-monospace,Menlo,Consolas,monospace;padding:32px;}
  h1{font:600 22px/1.2 system-ui,sans-serif;color:#1DB954;margin:0 0 16px;}
  .card{max-width:760px;margin:0 auto;background:#13131a;border:1px solid #1f1f2a;border-radius:14px;padding:24px;box-shadow:0 20px 60px rgba(0,0,0,.5);}
  .tok{background:#08080c;border:1px solid #1DB95433;border-radius:10px;padding:14px;word-break:break-all;color:#1DB954;margin:8px 0 18px;user-select:all;}
  label{color:#9aa0a6;font-size:12px;text-transform:uppercase;letter-spacing:.08em;}
  .btn{display:inline-block;background:#1DB954;color:#000;font-weight:600;padding:10px 16px;border-radius:999px;text-decoration:none;margin-top:8px;cursor:pointer;border:0;}
  .meta{color:#7a7f87;font-size:12px;margin-top:18px;}
  .err{color:#ff6b6b;}
</style></head><body><div class="card">${body}</div>
<script>
function copy(id){const t=document.getElementById(id);navigator.clipboard.writeText(t.innerText).then(()=>{const b=document.getElementById(id+'b');b.innerText='✓ Copied';setTimeout(()=>b.innerText='Copy',1500);});}
</script></body></html>`;
  return new Response(html, {
    status,
    headers: { "Content-Type": "text/html; charset=utf-8", "cache-control": "no-store" },
  });
}

export const Route = createFileRoute("/api/public/spotify_callback")({
  server: {
    handlers: {
      GET: async ({ request }) => {
        const url = new URL(request.url);
        const code = url.searchParams.get("code");
        const error = url.searchParams.get("error");

        if (error) {
          return page("Spotify error", `<h1>Spotify error</h1><p class="err">${error}</p>`, 400);
        }
        if (!code) {
          // Bounce to authorize URL for convenience.
          const scopes = [
            "user-read-playback-state",
            "user-modify-playback-state",
            "user-read-currently-playing",
            "user-read-private",
            "user-read-email",
          ].join(" ");
          const authUrl =
            "https://accounts.spotify.com/authorize?response_type=code" +
            `&client_id=${encodeURIComponent(CLIENT_ID)}` +
            `&scope=${encodeURIComponent(scopes)}` +
            `&redirect_uri=${encodeURIComponent(REDIRECT_URI)}`;
          return new Response(null, { status: 302, headers: { Location: authUrl } });
        }

        const body = new URLSearchParams({
          grant_type: "authorization_code",
          code,
          redirect_uri: REDIRECT_URI,
        }).toString();
        const basic = Buffer.from(`${CLIENT_ID}:${CLIENT_SECRET}`).toString("base64");
        const r = await fetch("https://accounts.spotify.com/api/token", {
          method: "POST",
          headers: {
            Authorization: `Basic ${basic}`,
            "Content-Type": "application/x-www-form-urlencoded",
          },
          body,
        });
        const data: any = await r.json().catch(() => ({}));
        if (!r.ok || !data.access_token) {
          return page(
            "Token exchange failed",
            `<h1>Token exchange failed</h1><pre class="err">${JSON.stringify(data, null, 2)}</pre>`,
            502,
          );
        }
        return page(
          "Spotify connected",
          `<h1>✓ Spotify connected</h1>
           <label>Access token (paste into SEIGE → Spotify tab)</label>
           <div class="tok" id="tok">${data.access_token}</div>
           <button class="btn" id="tokb" onclick="copy('tok')">Copy</button>
           <p class="meta">Expires in ${data.expires_in ?? 3600}s. When it expires, click "Login with Spotify" again.</p>
           ${data.refresh_token ? `<label>Refresh token (optional, save somewhere safe)</label><div class="tok" id="ref">${data.refresh_token}</div><button class="btn" id="refb" onclick="copy('ref')">Copy</button>` : ""}`,
        );
      },
    },
  },
});
