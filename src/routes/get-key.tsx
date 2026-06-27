import { createFileRoute, redirect } from "@tanstack/react-router";
import { useServerFn } from "@tanstack/react-start";
import { useState } from "react";
import { isUnlocked } from "@/lib/gate.functions";
import { getOrIssueKey } from "@/lib/keys.functions";

export const Route = createFileRoute("/get-key")({
  beforeLoad: async () => {
    const r = await isUnlocked();
    if (!r.unlocked) throw redirect({ to: "/unlock" });
  },
  head: () => ({
    meta: [
      { title: "Get your Seige key" },
      { name: "description", content: "Generate your personal Seige loader key." },
      { name: "robots", content: "noindex" },
    ],
  }),
  component: GetKey,
});

function GetKey() {
  const issue = useServerFn(getOrIssueKey);
  const [loading, setLoading] = useState(false);
  const [err, setErr] = useState<string | null>(null);

  async function onClick() {
    setLoading(true);
    setErr(null);
    try {
      const r = await issue();
      // Open the plain-text key page in a new tab so the user can copy from it.
      window.open(`/api/public/k/${r.token}`, "_blank", "noopener,noreferrer");
    } catch (e) {
      setErr(e instanceof Error ? e.message : String(e));
    } finally {
      setLoading(false);
    }
  }

  return (
    <main className="min-h-screen flex items-center justify-center bg-black text-white p-6">
      <div className="w-full max-w-lg space-y-6 rounded-xl border border-red-900/40 bg-zinc-950/80 p-8 shadow-[0_0_60px_rgba(220,38,38,0.15)]">
        <header className="space-y-2">
          <h1 className="text-3xl font-semibold tracking-tight">Get your Seige key</h1>
          <p className="text-sm text-zinc-400">
            Normal keys expire 24 hours after issue. Owner/admin devices receive a permanent key.
            Click the button to open your unique key on a plain-text page you can copy from.
          </p>
        </header>

        <button
          onClick={onClick}
          disabled={loading}
          className="w-full rounded-lg bg-red-600 hover:bg-red-500 disabled:opacity-50 transition px-4 py-3 font-semibold tracking-wide"
        >
          {loading ? "Generating…" : "Get Key"}
        </button>

        {err && (
          <div className="rounded-md border border-red-700 bg-red-950/40 px-3 py-2 text-sm text-red-200">
            {err}
          </div>
        )}

        <section className="space-y-2 text-sm text-zinc-400">
          <p className="font-medium text-zinc-200">How to use it</p>
          <pre className="overflow-x-auto rounded-md bg-zinc-900 p-3 text-[11px] text-zinc-200 border border-zinc-800">
{`script_key = "PASTE-YOUR-KEY-HERE"
loadstring(game:HttpGet("https://seigescript.online/api/public/loader.lua"))()`}
          </pre>
          <p>Put the <code>script_key = "..."</code> line <strong>above</strong> the loadstring line.</p>
        </section>
      </div>
    </main>
  );
}
