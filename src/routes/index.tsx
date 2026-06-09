import { createFileRoute } from "@tanstack/react-router";

const loadstringCommand = 'loadstring(game:HttpGet("https://raw.githubusercontent.com/DESPAIRDEV293/roblox-script-buddy/main/seige.lua"))()';

export const Route = createFileRoute("/")({
  head: () => ({
    meta: [
      { title: "Seige Loadstring — Storm Build" },
      { name: "description", content: "Always-fresh Roblox admin script loader. Live tag sync, storm-grade build." },
      { property: "og:title", content: "Seige Loadstring" },
      { property: "og:description", content: "Always-fresh Roblox admin script loader. Live tag sync, storm-grade build." },
    ],
  }),
  component: Index,
});

// pre-built deterministic raindrops/droplets so SSR === client
const RAIN = Array.from({ length: 140 }, (_, i) => {
  const seed = (i * 9301 + 49297) % 233280;
  const r = seed / 233280;
  return {
    left: (i * 7.3) % 100,
    delay: -(r * 1.4),
    duration: 0.5 + ((i * 13) % 7) / 10,
    opacity: 0.25 + (r * 0.55),
    height: 40 + ((i * 11) % 60),
  };
});

// Better hash so droplets actually scatter across the viewport
function hash(n: number, seed: number) {
  let x = Math.sin(n * 9999 + seed * 374761) * 43758.5453;
  return x - Math.floor(x);
}
const DROPLETS = Array.from({ length: 90 }, (_, i) => {
  const r1 = hash(i, 1);
  const r2 = hash(i, 2);
  const r3 = hash(i, 3);
  const r4 = hash(i, 4);
  return {
    top: r1 * 100,
    left: r2 * 100,
    size: 5 + r3 * 16,
    delay: r4 * 8,
    duration: 5 + r3 * 6,
  };
});

function Index() {

  return (
    <div className="storm-root relative min-h-screen overflow-hidden text-slate-100">
      {/* sky gradient */}
      <div className="storm-sky absolute inset-0" />
      {/* rolling cloud layers */}
      <div className="storm-clouds storm-clouds-1 absolute inset-0" />
      <div className="storm-clouds storm-clouds-2 absolute inset-0" />
      {/* lightning flash overlay */}
      <div className="storm-lightning absolute inset-0 pointer-events-none" />
      {/* lightning bolt SVG */}
      <svg
        className="storm-bolt absolute pointer-events-none"
        viewBox="0 0 100 300"
        preserveAspectRatio="none"
      >
        <path
          d="M55 0 L30 130 L55 130 L20 300 L70 140 L42 140 L72 0 Z"
          fill="url(#boltGrad)"
        />
        <defs>
          <linearGradient id="boltGrad" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor="#e0e7ff" />
            <stop offset="60%" stopColor="#a5b4fc" />
            <stop offset="100%" stopColor="#6366f1" />
          </linearGradient>
        </defs>
      </svg>

      {/* rain */}
      <div className="absolute inset-0 pointer-events-none">
        {RAIN.map((d, i) => (
          <span
            key={i}
            className="storm-drop"
            style={{
              left: `${d.left}%`,
              animationDelay: `${d.delay}s`,
              animationDuration: `${d.duration}s`,
              opacity: d.opacity,
              height: `${d.height}px`,
            }}
          />
        ))}
      </div>

      {/* mist at bottom */}
      <div className="storm-mist absolute inset-x-0 bottom-0 h-1/2 pointer-events-none" />

      {/* full-screen droplet layer */}
      <div className="absolute inset-0 pointer-events-none z-[1]">
        {DROPLETS.map((d, i) => (
          <span
            key={i}
            className="storm-droplet"
            style={{
              top: `${d.top}%`,
              left: `${d.left}%`,
              width: `${d.size}px`,
              height: `${d.size * 1.15}px`,
              animationDelay: `${d.delay}s`,
              animationDuration: `${d.duration}s`,
            }}
          />
        ))}
      </div>

      <main className="relative z-10 mx-auto flex min-h-screen max-w-4xl flex-col justify-center gap-10 px-6 py-16">
        <header className="space-y-4">
          <p className="text-[11px] font-semibold uppercase tracking-[0.4em] text-indigo-300/80">
            seige.lol  ·  storm build
          </p>
          <h1 className="storm-title text-5xl font-black leading-[0.95] tracking-tight sm:text-7xl">
            <WaterText text="Seige" />{" "}
            <WaterText text="Loadstring" accent />
          </h1>
          <p className="max-w-2xl text-base leading-relaxed text-slate-300/85">
            Your script your way. Quick, Reliable, Safe. Enjoy seige soon
          </p>
        </header>

        {/* glass card */}
        <section className="storm-card relative overflow-hidden rounded-2xl p-6 sm:p-7">
          <div className="storm-card-glow absolute inset-0 pointer-events-none" />



          <div className="relative flex items-center justify-between gap-4">
            <p className="text-[11px] font-semibold uppercase tracking-[0.3em] text-indigo-200/70">
              Live command
            </p>
            <button
              disabled
              className="storm-btn storm-btn-disabled rounded-lg px-3.5 py-1.5 text-xs font-semibold tracking-wide"
            >
              Copy
            </button>
          </div>

          <pre className="relative mt-3 overflow-x-auto rounded-xl border border-white/10 bg-black/40 p-4 text-sm text-slate-500/80 backdrop-blur select-none">
            <code>{loadstringCommand}</code>
          </pre>

          <p className="relative mt-4 text-xs text-slate-400/60">
            Script is currently unavailable — check back soon.
          </p>
        </section>

        <footer className="flex flex-wrap items-center justify-between gap-3 text-xs text-slate-400/70">
          <span>⛈  storm-grade · live tag sync</span>
          <span className="font-mono text-indigo-300/70">v.live</span>
        </footer>
      </main>

      <style>{`
        .storm-root {
          background: #05070d;
        }
        .storm-sky {
          background:
            radial-gradient(ellipse 90% 60% at 20% 0%, rgba(99,102,241,0.18), transparent 60%),
            radial-gradient(ellipse 80% 50% at 80% 10%, rgba(56,189,248,0.10), transparent 65%),
            linear-gradient(180deg, #0a0e1a 0%, #0b1224 35%, #060912 100%);
        }
        .storm-clouds {
          background-repeat: repeat-x;
          opacity: 0.55;
          mix-blend-mode: screen;
          filter: blur(20px);
        }
        .storm-clouds-1 {
          background-image:
            radial-gradient(ellipse 600px 120px at 20% 18%, rgba(120,130,170,0.45), transparent 60%),
            radial-gradient(ellipse 500px 110px at 60% 12%, rgba(80,90,140,0.45), transparent 60%),
            radial-gradient(ellipse 700px 140px at 90% 22%, rgba(100,110,160,0.4), transparent 60%);
          animation: storm-drift-a 60s linear infinite;
        }
        .storm-clouds-2 {
          background-image:
            radial-gradient(ellipse 800px 160px at 10% 30%, rgba(60,70,110,0.5), transparent 60%),
            radial-gradient(ellipse 600px 140px at 70% 26%, rgba(90,100,150,0.4), transparent 60%);
          animation: storm-drift-b 90s linear infinite;
          opacity: 0.45;
        }
        @keyframes storm-drift-a {
          from { transform: translateX(0); }
          to   { transform: translateX(-40%); }
        }
        @keyframes storm-drift-b {
          from { transform: translateX(0); }
          to   { transform: translateX(30%); }
        }

        .storm-lightning {
          background: rgba(180, 200, 255, 0);
          animation: storm-flash 9s linear infinite;
        }
        @keyframes storm-flash {
          0%, 92%, 100% { background: rgba(180, 200, 255, 0); }
          93%   { background: rgba(200, 215, 255, 0.55); }
          93.5% { background: rgba(180, 200, 255, 0.05); }
          94%   { background: rgba(220, 230, 255, 0.7); }
          94.6% { background: rgba(180, 200, 255, 0.0); }
          96%   { background: rgba(200, 215, 255, 0.35); }
          96.4% { background: rgba(180, 200, 255, 0); }
        }

        .storm-bolt {
          top: -2%;
          left: 18%;
          width: 110px;
          height: 55vh;
          opacity: 0;
          filter: drop-shadow(0 0 18px rgba(165,180,252,0.9))
                  drop-shadow(0 0 60px rgba(99,102,241,0.55));
          animation: storm-bolt-flash 9s linear infinite;
        }
        @keyframes storm-bolt-flash {
          0%, 93.6%, 100% { opacity: 0; transform: translateY(-6px) scaleY(0.98); }
          93.8% { opacity: 1; transform: translateY(0) scaleY(1); }
          94.4% { opacity: 0.9; }
          94.6% { opacity: 0; }
        }

        .storm-drop {
          position: absolute;
          top: -10%;
          width: 1px;
          background: linear-gradient(180deg, transparent, rgba(180,200,255,0.85));
          animation: storm-rain linear infinite;
          transform: translateY(0) skewX(-12deg);
        }
        @keyframes storm-rain {
          0%   { transform: translateY(-20vh) skewX(-12deg); }
          100% { transform: translateY(120vh) skewX(-12deg); }
        }

        .storm-mist {
          background: linear-gradient(180deg, transparent, rgba(8,12,24,0.85) 70%, #03060d);
        }

        .storm-title {
          background: linear-gradient(180deg, #f1f5ff 0%, #c7d2fe 55%, #818cf8 100%);
          -webkit-background-clip: text;
          background-clip: text;
          color: transparent;
          text-shadow: 0 4px 40px rgba(99,102,241,0.25);
        }
        .storm-title-accent {
          background: linear-gradient(180deg, #a5b4fc, #6366f1 70%, #312e81);
          -webkit-background-clip: text;
          background-clip: text;
          color: transparent;
          filter: drop-shadow(0 2px 14px rgba(99,102,241,0.5));
        }

        .storm-card {
          background:
            linear-gradient(180deg, rgba(20,28,52,0.55), rgba(8,12,24,0.65));
          border: 1px solid rgba(165,180,252,0.18);
          backdrop-filter: blur(14px) saturate(140%);
          -webkit-backdrop-filter: blur(14px) saturate(140%);
          box-shadow:
            0 1px 0 rgba(255,255,255,0.06) inset,
            0 30px 80px -20px rgba(0,0,0,0.7),
            0 0 60px -10px rgba(99,102,241,0.25);
        }
        .storm-card-glow {
          background: radial-gradient(ellipse 60% 50% at 50% 0%, rgba(129,140,248,0.18), transparent 70%);
        }

        .storm-droplet {
          position: absolute;
          border-radius: 50% 50% 50% 50% / 60% 60% 40% 40%;
          background:
            radial-gradient(circle at 30% 28%, rgba(255,255,255,0.9), rgba(180,200,255,0.18) 40%, rgba(40,60,120,0.05) 70%, transparent 75%);
          box-shadow:
            inset 0 -2px 3px rgba(255,255,255,0.35),
            inset 0 2px 3px rgba(0,0,0,0.25),
            0 1px 2px rgba(0,0,0,0.4);
          opacity: 0.85;
          animation: storm-droplet-slip 7s ease-in infinite;
        }
        @keyframes storm-droplet-slip {
          0%, 70% { transform: translateY(0); opacity: 0.85; }
          90%     { transform: translateY(60px); opacity: 0.6; }
          100%    { transform: translateY(120px); opacity: 0; }
        }

        .storm-btn {
          background: linear-gradient(180deg, rgba(129,140,248,0.25), rgba(67,56,202,0.35));
          border: 1px solid rgba(165,180,252,0.35);
          color: #e0e7ff;
          transition: all 0.2s ease;
          box-shadow: 0 0 0 0 rgba(129,140,248,0.0);
        }
        .storm-btn:hover {
          background: linear-gradient(180deg, rgba(129,140,248,0.4), rgba(67,56,202,0.5));
          box-shadow: 0 0 24px -2px rgba(129,140,248,0.6);
          transform: translateY(-1px);
        }
        .storm-btn-disabled {
          opacity: 0.5;
          cursor: not-allowed;
          filter: grayscale(0.6);
        }
        .storm-btn-disabled:hover {
          background: linear-gradient(180deg, rgba(129,140,248,0.25), rgba(67,56,202,0.35));
          box-shadow: none;
          transform: none;
        }
      `}</style>
    </div>
  );
}
