import { createFileRoute } from "@tanstack/react-router";
import { useServerFn } from "@tanstack/react-start";
import { useState } from "react";
import { mintPastebinUserKey } from "@/lib/pastebin.functions";

export const Route = createFileRoute("/pastebin-key")({
  component: PastebinKeyHelper,
  head: () => ({
    meta: [
      { title: "Pastebin user key helper" },
      { name: "description", content: "Generate a Pastebin user key from your dev key, username, and password." },
      { name: "robots", content: "noindex" },
    ],
  }),
});

function PastebinKeyHelper() {
  const mint = useServerFn(mintPastebinUserKey);
  const [devKey, setDevKey] = useState("");
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState<{ ok: boolean; value: string } | null>(null);

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setResult(null);
    try {
      const r = await mint({ data: { devKey, username, password } });
      if (r.ok) setResult({ ok: true, value: r.userKey });
      else setResult({ ok: false, value: r.error });
    } catch (err) {
      setResult({ ok: false, value: err instanceof Error ? err.message : String(err) });
    } finally {
      setLoading(false);
    }
  }

  function copy() {
    if (result?.ok) navigator.clipboard.writeText(result.value).catch(() => {});
  }

  return (
    <main className="min-h-screen flex items-center justify-center bg-background p-6">
      <div className="w-full max-w-md space-y-6">
        <header className="space-y-2">
          <h1 className="text-2xl font-semibold tracking-tight">Pastebin user key helper</h1>
          <p className="text-sm text-muted-foreground">
            Paste your dev key, username, and password. Your password is sent to Pastebin once and never stored.
          </p>
        </header>

        <form onSubmit={onSubmit} className="space-y-4">
          <Field label="Dev API key" value={devKey} onChange={setDevKey} placeholder="from pastebin.com/doc_api" />
          <Field label="Pastebin username" value={username} onChange={setUsername} />
          <Field label="Pastebin password" value={password} onChange={setPassword} type="password" />

          <button
            type="submit"
            disabled={loading || !devKey || !username || !password}
            className="w-full rounded-md bg-primary text-primary-foreground font-medium py-2.5 disabled:opacity-50 hover:bg-primary/90 transition"
          >
            {loading ? "Requesting…" : "Get user key"}
          </button>
        </form>

        {result && (
          <div
            className={`rounded-md border p-4 space-y-2 ${
              result.ok ? "border-primary/40 bg-primary/5" : "border-destructive/40 bg-destructive/5"
            }`}
          >
            <p className="text-xs uppercase tracking-wide text-muted-foreground">
              {result.ok ? "Your user key" : "Pastebin error"}
            </p>
            <code className="block break-all text-sm font-mono">{result.value}</code>
            {result.ok && (
              <button
                type="button"
                onClick={copy}
                className="text-xs underline text-muted-foreground hover:text-foreground"
              >
                Copy to clipboard
              </button>
            )}
          </div>
        )}
      </div>
    </main>
  );
}

function Field({
  label,
  value,
  onChange,
  placeholder,
  type = "text",
}: {
  label: string;
  value: string;
  onChange: (v: string) => void;
  placeholder?: string;
  type?: string;
}) {
  return (
    <label className="block space-y-1.5">
      <span className="text-sm font-medium text-foreground">{label}</span>
      <input
        type={type}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder={placeholder}
        autoComplete="off"
        className="w-full rounded-md border border-input bg-background px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-ring"
      />
    </label>
  );
}
