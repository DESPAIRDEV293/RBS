import { createFileRoute, Link } from "@tanstack/react-router";
import { useEffect, useState } from "react";
import { getMyCode } from "@/lib/gate.functions";

export const Route = createFileRoute("/code")({
  loader: () => getMyCode(),
  head: () => ({
    meta: [
      { title: "Your Access Code — Seige" },
      { name: "description", content: "Your unique device access code for Seige." },
      { name: "robots", content: "noindex" },
    ],
  }),
  component: CodePage,
});

function CodePage() {
  const { code } = Route.useLoaderData();
  const [copied, setCopied] = useState(false);

  useEffect(() => {
    if (!copied) return;
    const t = setTimeout(() => setCopied(false), 1600);
    return () => clearTimeout(t);
  }, [copied]);

  function copy() {
    navigator.clipboard.writeText(code).then(() => setCopied(true)).catch(() => {});
  }

  return (
    <div className="relative min-h-screen overflow-hidden bg-[#05070d] text-slate-100">
      {/* sky + glow background */}
      <div
        className="absolute inset-0"
        style={{
          background:
            "radial-gradient(ellipse 90% 60% at 20% 0%, rgba(99,102,241,0.18), transparent 60%), radial-gradient(ellipse 80% 50% at 80% 10%, rgba(56,189,248,0.10), transparent 65%), linear-gradient(180deg, #0a0e1a 0%, #0b1224 35%, #060912 100%)",
        }}
      />

      <main className="relative z-10 mx-auto flex min-h-screen max-w-3xl flex-col justify-center gap-8 px-6 py-16">
        <header className="space-y-3">
          <p className="text-[11px] font-semibold uppercase tracking-[0.4em] text-indigo-300/80">
            seige · device access code
          </p>
          <h1 className="text-4xl font-black leading-tight tracking-tight sm:text-5xl">
            Your one-device <span className="text-indigo-400">access code</span>
          </h1>
          <p className="max-w-2xl text-sm leading-relaxed text-slate-300/85">
            This code is bound to <strong className="text-indigo-200">this browser on this device</strong>.
            It will not work anywhere else. Copy it, head back to the unlock
            page, and paste it in to access the site for 7 days.
          </p>
        </header>

        {/* code card */}
        <section className="relative overflow-hidden rounded-2xl border border-white/10 bg-white/[0.03] p-7 backdrop-blur">
          <div className="absolute inset-0 pointer-events-none" style={{ background: "radial-gradient(ellipse 80% 60% at 50% 0%, rgba(99,102,241,0.15), transparent 70%)" }} />

          <div className="relative flex items-center justify-between gap-4">
            <p className="text-[11px] font-semibold uppercase tracking-[0.3em] text-indigo-200/70">
              Your code
            </p>
            <button
              onClick={copy}
              className="rounded-lg border border-indigo-400/30 bg-indigo-500/15 px-3.5 py-1.5 text-xs font-semibold text-indigo-200 hover:bg-indigo-500/25 transition"
            >
              {copied ? "Copied!" : "Copy"}
            </button>
          </div>

          <pre className="relative mt-4 overflow-x-auto rounded-xl border border-white/10 bg-black/40 p-6 text-center backdrop-blur">
            <code className="font-mono text-3xl font-bold tracking-[0.5em] text-indigo-100 sm:text-4xl">
              {code}
            </code>
          </pre>

          <p className="relative mt-4 text-xs text-slate-400/70">
            Keep this private. Anyone with this code on this device can unlock the site.
          </p>
        </section>

        {/* steps */}
        <section className="grid gap-3 sm:grid-cols-3">
          {[
            { n: "1", t: "Copy the code", d: "Tap Copy or select the code above." },
            { n: "2", t: "Open Unlock", d: "Go back to the unlock page on this same device." },
            { n: "3", t: "Paste & enter", d: "Drop it into the unlock box. Good for 7 days." },
          ].map((s) => (
            <div
              key={s.n}
              className="rounded-xl border border-white/[0.08] bg-white/[0.02] p-4"
            >
              <span className="inline-flex h-6 w-6 items-center justify-center rounded-full bg-indigo-500/20 text-xs font-bold text-indigo-300">
                {s.n}
              </span>
              <h3 className="mt-2 text-sm font-bold text-indigo-100">{s.t}</h3>
              <p className="mt-1 text-xs text-slate-400/80">{s.d}</p>
            </div>
          ))}
        </section>

        {/* facts */}
        <section className="rounded-2xl border border-white/[0.06] bg-black/30 p-5 text-xs text-slate-400/80">
          <ul className="space-y-2">
            <li><span className="text-indigo-300">•</span> Codes are derived from a server secret + a per-device id stored in a cookie.</li>
            <li><span className="text-indigo-300">•</span> Clearing cookies / using a different browser gives you a new device id and a new code.</li>
            <li><span className="text-indigo-300">•</span> The code itself does not unlock the site — entering it on the unlock page does, for 7 days.</li>
            <li><span className="text-indigo-300">•</span> Never share your code. It only works on this device, but treat it like a password.</li>
          </ul>
        </section>

        <footer className="flex flex-wrap items-center justify-between gap-3 text-xs">
          <Link
            to="/unlock"
            className="rounded-lg border border-indigo-400/30 bg-indigo-500/10 px-4 py-2 font-semibold text-indigo-200 hover:bg-indigo-500/20 transition"
          >
            ← Back to unlock
          </Link>
          <span className="text-slate-500">v.beta · device-bound</span>
        </footer>
      </main>
    </div>
  );
}
