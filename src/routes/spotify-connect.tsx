import { createFileRoute } from "@tanstack/react-router";
import { useEffect, useState } from "react";

export const Route = createFileRoute("/spotify-connect")({
  component: SpotifyConnect,
  head: () => ({
    meta: [
      { title: "SEIGE — Connect Spotify" },
      { name: "description", content: "Link your Spotify account to SEIGE in two clicks." },
      { name: "robots", content: "noindex, nofollow" },
    ],
  }),
});

const REDIRECT_PATH = "/spotify-connect";
const SCOPES = [
  "user-read-playback-state",
  "user-modify-playback-state",
  "user-read-currently-playing",
  "user-read-private",
  "user-read-email",
].join(" ");
const STORAGE_KEY = "seige.spotify.creds";

type Creds = { client_id: string; client_secret: string; pair: string };

function loadCreds(): Creds | null {
  try {
    const raw = sessionStorage.getItem(STORAGE_KEY);
    if (!raw) return null;
    const j = JSON.parse(raw);
    if (j && j.client_id && j.client_secret && j.pair) return j as Creds;
  } catch {}
  return null;
}

function makePair(): string {
  const a = Math.random().toString(36).slice(2, 6).toUpperCase();
  const b = Math.random().toString(36).slice(2, 6).toUpperCase();
  return `${a}-${b}`;
}

function SpotifyConnect() {
  const [clientId, setClientId] = useState("");
  const [clientSecret, setClientSecret] = useState("");
  const [pair, setPair] = useState("");
  const [status, setStatus] = useState<string>("");
  const [token, setToken] = useState<string>("");
  const [error, setError] = useState<string>("");

  // Init: read pair from URL or generate one. If we're coming back from
  // Spotify with ?code=..., immediately try to exchange it.
  useEffect(() => {
    const url = new URL(window.location.href);
    const urlPair = (url.searchParams.get("pair") || url.searchParams.get("state") || "").toUpperCase();
    const stored = loadCreds();
    const p = (urlPair || stored?.pair || makePair()).toUpperCase();
    setPair(p);
    if (stored) {
      setClientId(stored.client_id);
      setClientSecret(stored.client_secret);
    }

    const code = url.searchParams.get("code");
    if (code && stored) {
      void exchange(code, stored, p);
    }
  }, []);

  const redirectUri = typeof window !== "undefined"
    ? `${window.location.origin}${REDIRECT_PATH}`
    : "";

  async function exchange(code: string, creds: Creds, pairCode: string) {
    setStatus("Exchanging code for token…");
    setError("");
    try {
      const r = await fetch("/api/public/spotify_exchange", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          client_id: creds.client_id,
          client_secret: creds.client_secret,
          code,
          redirect_uri: `${window.location.origin}${REDIRECT_PATH}`,
        }),
      });
      const j = await r.json();
      if (!r.ok || !j.access_token) {
        setError(j.error || "Token exchange failed");
        setStatus("");
        return;
      }
      setToken(j.access_token);
      setStatus("Sending token to your game…");
      const dr = await fetch("/api/public/spotify_drop", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          code: pairCode,
          access_token: j.access_token,
          refresh_token: j.refresh_token,
          expires_in: j.expires_in,
        }),
      });
      if (!dr.ok) {
        setError("Drop failed — copy the token manually below.");
        setStatus("");
        return;
      }
      setStatus("✓ Connected. You can close this tab — SEIGE is auto-loading the token.");
      // Clear creds so refresh doesn't re-exchange a stale code.
      try { sessionStorage.removeItem(STORAGE_KEY); } catch {}
      // Strip ?code= from URL.
      try {
        const clean = new URL(window.location.href);
        clean.searchParams.delete("code");
        clean.searchParams.delete("state");
        window.history.replaceState({}, "", clean.toString());
      } catch {}
    } catch (e: any) {
      setError(e?.message || "Network error");
      setStatus("");
    }
  }

  function startLogin() {
    setError("");
    const cid = clientId.trim();
    const sec = clientSecret.trim();
    if (!cid || !sec) { setError("Client ID and Client Secret are required."); return; }
    const creds: Creds = { client_id: cid, client_secret: sec, pair };
    try { sessionStorage.setItem(STORAGE_KEY, JSON.stringify(creds)); } catch {}
    const auth = new URL("https://accounts.spotify.com/authorize");
    auth.searchParams.set("response_type", "code");
    auth.searchParams.set("client_id", cid);
    auth.searchParams.set("scope", SCOPES);
    auth.searchParams.set("redirect_uri", redirectUri);
    auth.searchParams.set("state", pair);
    window.location.href = auth.toString();
  }

  function copy(value: string) {
    try { navigator.clipboard.writeText(value); } catch {}
  }

  return (
    <div style={{
      minHeight: "100vh", background: "#0a0a0f", color: "#e7e7ea",
      fontFamily: "ui-monospace, Menlo, Consolas, monospace", padding: "32px 16px",
    }}>
      <div style={{
        maxWidth: 680, margin: "0 auto", background: "#13131a",
        border: "1px solid #1f1f2a", borderRadius: 14, padding: 28,
        boxShadow: "0 30px 80px rgba(0,0,0,.55)",
      }}>
        <h1 style={{
          font: '600 24px/1.2 system-ui, sans-serif', color: "#1DB954", margin: "0 0 6px",
        }}>SEIGE × Spotify</h1>
        <p style={{ color: "#9aa0a6", margin: "0 0 20px", fontSize: 13 }}>
          Paste your Spotify app credentials, click Login, approve in Spotify, and
          we'll bounce you back and auto-load the token into your script.
        </p>

        <ol style={{ color: "#9aa0a6", fontSize: 12, lineHeight: 1.6, paddingLeft: 18, margin: "0 0 20px" }}>
          <li>Open the Spotify Developer dashboard → create an app.</li>
          <li>Add this exact Redirect URI: <code style={{ color: "#1DB954" }}>{redirectUri}</code> <button onClick={() => copy(redirectUri)} style={btnGhost}>copy</button></li>
          <li>Copy your Client ID and Client Secret into the boxes below.</li>
          <li>Press <b>Login with Spotify</b>. Done.</li>
        </ol>

        <label style={lbl}>Client ID</label>
        <input style={inp} value={clientId} onChange={(e) => setClientId(e.target.value)} placeholder="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" />

        <label style={lbl}>Client Secret</label>
        <input style={inp} type="password" value={clientSecret} onChange={(e) => setClientSecret(e.target.value)} placeholder="••••••••••••••••••••••••••••••••" />

        <label style={lbl}>Pair code (auto-shared with the script)</label>
        <div style={{ display: "flex", gap: 8 }}>
          <input style={{ ...inp, flex: 1 }} value={pair} readOnly />
          <button style={btnGhost} onClick={() => copy(pair)}>copy</button>
        </div>

        <button onClick={startLogin} style={btnPrimary}>🎧 Login with Spotify</button>

        {status && <p style={{ color: "#1DB954", marginTop: 18 }}>{status}</p>}
        {error && <p style={{ color: "#ff6b6b", marginTop: 18 }}>{error}</p>}

        {token && (
          <>
            <label style={lbl}>Access token (fallback — only if auto-load fails)</label>
            <div style={{ ...tokBox }}>{token}</div>
            <button onClick={() => copy(token)} style={btnGhost}>Copy token</button>
          </>
        )}

        <p style={{ color: "#5b6068", fontSize: 11, marginTop: 24 }}>
          Your client secret stays in this browser tab (sessionStorage) and is only sent to SEIGE's server for the OAuth exchange. We don't store it.
        </p>
      </div>
    </div>
  );
}

const lbl: React.CSSProperties = { display: "block", color: "#9aa0a6", fontSize: 11, textTransform: "uppercase", letterSpacing: ".08em", marginTop: 14, marginBottom: 6 };
const inp: React.CSSProperties = { width: "100%", boxSizing: "border-box", background: "#08080c", border: "1px solid #1f1f2a", borderRadius: 8, padding: "10px 12px", color: "#e7e7ea", fontFamily: "inherit", fontSize: 13 };
const btnPrimary: React.CSSProperties = { display: "block", width: "100%", marginTop: 22, background: "#1DB954", color: "#000", border: 0, borderRadius: 999, padding: "12px 16px", fontWeight: 700, fontSize: 14, cursor: "pointer" };
const btnGhost: React.CSSProperties = { background: "#1f1f2a", color: "#e7e7ea", border: "1px solid #2a2a36", borderRadius: 8, padding: "6px 10px", fontSize: 11, cursor: "pointer", marginLeft: 4 };
const tokBox: React.CSSProperties = { background: "#08080c", border: "1px solid #1DB95433", borderRadius: 10, padding: 12, color: "#1DB954", wordBreak: "break-all", marginTop: 6, fontSize: 12, userSelect: "all" };
