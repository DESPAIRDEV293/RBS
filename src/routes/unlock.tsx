import { createFileRoute, useRouter, redirect } from "@tanstack/react-router";
import { useServerFn } from "@tanstack/react-start";
import { useState } from "react";
import { unlockSite, isUnlocked } from "@/lib/gate.functions";

export const Route = createFileRoute("/unlock")({
  beforeLoad: async () => {
    const r = await isUnlocked();
    if (r.unlocked) throw redirect({ to: "/" });
  },
  head: () => ({
    meta: [
      { title: "Unlock — Seige" },
      { name: "robots", content: "noindex" },
    ],
  }),
  component: UnlockPage,
});

function UnlockPage() {
  const router = useRouter();
  const unlock = useServerFn(unlockSite);
  const [code, setCode] = useState("");
  const [err, setErr] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setErr(null);
    try {
      const r = await unlock({ data: { code } });
      if (r.ok) {
        await router.invalidate();
        await router.navigate({ to: "/" });
      } else {
        setErr(r.error);
      }
    } catch (e) {
      setErr(e instanceof Error ? e.message : String(e));
    } finally {
      setLoading(false);
    }
  }

  return (
    <main className="min-h-screen flex items-center justify-center bg-[#05070d] text-slate-100 p-6">
      <div className="w-full max-w-md space-y-6 rounded-2xl border border-white/10 bg-white/[0.03] p-7 backdrop-blur">
        <header className="space-y-2">
          <p className="text-[11px] font-semibold uppercase tracking-[0.4em] text-indigo-300/80">
            seige · access gate
          </p>
          <h1 className="text-2xl font-bold tracking-tight">Enter your access code</h1>
          <p className="text-sm text-slate-400">
            Each device gets a unique code. Open the link below in a new tab,
            copy your code, and paste it back here on this same device.
          </p>
        </header>

        <a
          href="/code.txt"
          target="_blank"
          rel="noopener noreferrer"
          className="block rounded-lg border border-indigo-400/30 bg-indigo-500/10 px-4 py-3 text-center text-sm font-semibold text-indigo-200 hover:bg-indigo-500/20 transition"
        >
          → Open my access code (opens /code.txt)
        </a>

        <form onSubmit={onSubmit} className="space-y-3">
          <input
            value={code}
            onChange={(e) => setCode(e.target.value)}
            placeholder="XXXX-XXXX"
            autoComplete="off"
            spellCheck={false}
            className="w-full rounded-md border border-white/10 bg-black/40 px-4 py-3 text-center font-mono text-lg tracking-[0.3em] uppercase focus:outline-none focus:ring-2 focus:ring-indigo-400/60"
          />
          <button
            type="submit"
            disabled={loading || code.replace(/[^A-Za-z0-9]/g, "").length < 8}
            className="w-full rounded-md bg-indigo-500 px-4 py-2.5 text-sm font-semibold text-white hover:bg-indigo-400 disabled:opacity-40 transition"
          >
            {loading ? "Unlocking…" : "Unlock site"}
          </button>
          {err && <p className="text-xs text-red-400 text-center">{err}</p>}
        </form>

        <p className="text-[11px] text-slate-500 text-center">
          The code only works on the device that requested it. Unlock lasts 7 days.
        </p>
      </div>
    </main>
  );
}
