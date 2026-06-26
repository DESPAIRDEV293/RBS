import { createFileRoute, redirect } from "@tanstack/react-router";
import { useEffect, useState } from "react";
import { useServerFn } from "@tanstack/react-start";
import { validateScriptLink } from "@/lib/validate.functions";
import { isUnlocked } from "@/lib/gate.functions";

const LOADSTRING =
  'loadstring(game:HttpGet("https://raw.githubusercontent.com/DESPAIRDEV293/roblox-script-buddy/main/admin.lua?fresh=" .. tostring(os.time())))()';

export const Route = createFileRoute("/validate")({
  beforeLoad: async () => {
    const r = await isUnlocked();
    if (!r.unlocked) throw redirect({ to: "/unlock" });
  },
  head: () => ({ meta: [{ title: "Script Link Validator" }] }),
  component: ValidatePage,
});

type Result = {
  url: string;
  ok: boolean;
  status: number;
  statusText: string;
  contentType: string;
  sizeKb: number;
  ms: number;
  looksLikeLua: boolean;
  firstLine: string;
  error: string | null;
};

function ValidatePage() {
  const run = useServerFn(validateScriptLink);
  const [loading, setLoading] = useState(true);
  const [data, setData] = useState<{ checkedAt: string; results: Result[] } | null>(null);
  const [copied, setCopied] = useState(false);

  const check = async () => {
    setLoading(true);
    try {
      setData(await run());
    } finally {
      setLoading(false);
    }
  };
  useEffect(() => {
    check();
  }, []);

  return (
    <div className="min-h-screen bg-black text-white p-6 font-mono">
      <div className="max-w-4xl mx-auto space-y-6">
        <div className="flex items-center justify-between">
          <h1 className="text-2xl font-bold">Script Link Validator</h1>
          <button
            onClick={check}
            disabled={loading}
            className="px-4 py-2 bg-white text-black rounded hover:bg-zinc-200 disabled:opacity-50"
          >
            {loading ? "Checking…" : "Re-check"}
          </button>
        </div>

        <div className="border border-zinc-800 rounded p-4 bg-zinc-950">
          <div className="text-xs text-zinc-400 mb-2">Loadstring (shareable, works for any user)</div>
          <code className="block break-all text-emerald-400 text-sm">{LOADSTRING}</code>
          <button
            onClick={() => {
              navigator.clipboard.writeText(LOADSTRING);
              setCopied(true);
              setTimeout(() => setCopied(false), 1500);
            }}
            className="mt-3 px-3 py-1 text-sm border border-zinc-700 rounded hover:bg-zinc-900"
          >
            {copied ? "Copied ✓" : "Copy"}
          </button>
        </div>

        {data?.results.map((r) => (
          <div
            key={r.url}
            className={`border rounded p-4 ${
              r.ok ? "border-emerald-700 bg-emerald-950/30" : "border-red-700 bg-red-950/30"
            }`}
          >
            <div className="flex items-center justify-between mb-2">
              <span className="text-sm break-all">{r.url}</span>
              <span
                className={`px-2 py-0.5 rounded text-xs font-bold ${
                  r.ok ? "bg-emerald-600" : "bg-red-600"
                }`}
              >
                {r.ok ? "OK" : "FAIL"}
              </span>
            </div>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-2 text-xs text-zinc-300">
              <div>Status: <span className="text-white">{r.status} {r.statusText}</span></div>
              <div>Latency: <span className="text-white">{r.ms}ms</span></div>
              <div>Size: <span className="text-white">{r.sizeKb} KB</span></div>
              <div>Lua-like: <span className={r.looksLikeLua ? "text-emerald-400" : "text-red-400"}>{r.looksLikeLua ? "yes" : "no"}</span></div>
              <div className="col-span-2 md:col-span-4">Content-Type: <span className="text-white">{r.contentType || "—"}</span></div>
              {r.firstLine && (
                <div className="col-span-2 md:col-span-4">First line: <span className="text-zinc-400">{r.firstLine}</span></div>
              )}
              {r.error && (
                <div className="col-span-2 md:col-span-4 text-red-400">Error: {r.error}</div>
              )}
            </div>
          </div>
        ))}

        {data && (
          <div className="text-xs text-zinc-500">Last checked: {new Date(data.checkedAt).toLocaleString()}</div>
        )}
      </div>
    </div>
  );
}
