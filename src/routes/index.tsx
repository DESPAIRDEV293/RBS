import { createFileRoute } from "@tanstack/react-router";

const loadstringCommand = 'loadstring(game:HttpGet("https://project--9cc69d4f-b5d0-456b-878c-80800e55ce94-dev.lovable.app/api/public/admin.lua?fresh=" .. tostring(os.time())))()';

export const Route = createFileRoute("/")({
  head: () => ({
    meta: [
      { title: "Seige Loadstring" },
      { name: "description", content: "Always-fresh Roblox admin script loader with live tag sync." },
      { property: "og:title", content: "Seige Loadstring" },
      { property: "og:description", content: "Always-fresh Roblox admin script loader with live tag sync." },
    ],
  }),
  component: Index,
});

function Index() {
  return (
    <div className="min-h-screen bg-background text-foreground">
      <main className="mx-auto flex min-h-screen max-w-4xl flex-col justify-center gap-8 px-6 py-12">
        <section className="space-y-5">
          <p className="text-sm font-semibold uppercase tracking-normal text-muted-foreground">seige.lol</p>
          <h1 className="text-4xl font-bold tracking-normal sm:text-5xl">Seige Loadstring</h1>
          <p className="max-w-2xl text-base text-muted-foreground">
            Use this live endpoint so script and tag fixes load from the newest published build instead of cached GitHub raw files.
          </p>
        </section>

        <section className="space-y-3">
          <p className="text-sm font-medium text-muted-foreground">Live command</p>
          <pre className="overflow-x-auto rounded-md border border-border bg-card p-4 text-sm text-card-foreground">
            <code>{loadstringCommand}</code>
          </pre>
        </section>
      </main>
    </div>
  );
}
