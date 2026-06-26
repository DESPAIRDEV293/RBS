import { createFileRoute, redirect } from "@tanstack/react-router";
import { useEffect, useState } from "react";
import { isUnlocked } from "@/lib/gate.functions";

// Keep the pasted command short for Potassium/Macsploit/Xeno. The hosted
// loader handles fallback URLs and warning output if an executor blocks one.
const loadstringCommand = `loadstring(game:HttpGet("https://seigescript.online/api/public/loader.lua?fresh=" .. tostring(os.time())))()`;
const loadstringDisplay = loadstringCommand;

export const Route = createFileRoute("/")({
  beforeLoad: async () => {
    const r = await isUnlocked();
    if (!r.unlocked) throw redirect({ to: "/unlock" });
  },
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
    left: (i * 3.7) % 100,
    delay: -(r * 1.4),
    duration: 0.45 + ((i * 13) % 7) / 10,
    opacity: 0.25 + (r * 0.6),
    height: 36 + ((i * 11) % 80),
  };
});

// Better hash so droplets actually scatter across the viewport
function hash(n: number, seed: number) {
  let x = Math.sin(n * 9999 + seed * 374761) * 43758.5453;
  return x - Math.floor(x);
}

// Twinkling stars/sparkles drifting through the storm
const SPARKLES = Array.from({ length: 60 }, (_, i) => {
  const r1 = hash(i, 7);
  const r2 = hash(i, 11);
  const r3 = hash(i, 13);
  const r4 = hash(i, 17);
  return {
    top: r1 * 100,
    left: r2 * 100,
    size: 1.5 + r3 * 2.5,
    delay: r4 * 6,
    duration: 3 + r3 * 4,
  };
});

// Extra bolts at varied positions for a richer storm
const BOLTS = [
  { left: "18%", top: "-2%", width: 110, delay: "0s", height: "55vh" },
  { left: "72%", top: "-3%", width: 80, delay: "3.1s", height: "48vh" },
  { left: "48%", top: "-2%", width: 60, delay: "5.6s", height: "38vh" },
];

const DROPLETS = Array.from({ length: 55 }, (_, i) => {
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

function WaterText({ text, accent = false }: { text: string; accent?: boolean }) {
  return (
    <span className={`water-text inline-block ${accent ? "water-text-accent" : ""}`}>
      {text.split("").map((ch, i) => {
        const ripples = [
          { top: 18, left: 30, delay: i * 0.12 + 0.1, dur: 3.2 },
          { top: 55, left: 70, delay: i * 0.12 + 0.9, dur: 3.8 },
          { top: 78, left: 40, delay: i * 0.12 + 1.7, dur: 3.4 },
          { top: 35, left: 85, delay: i * 0.12 + 2.4, dur: 4.0 },
        ];
        return (
          <span
            key={i}
            className="water-letter"
            style={{ animationDelay: `${i * 0.12}s` }}
          >
            <span className="water-letter-glyph">{ch}</span>
            {ripples.map((r, j) => (
              <span
                key={j}
                className="water-ripple"
                style={{
                  top: `${r.top}%`,
                  left: `${r.left}%`,
                  animationDelay: `${r.delay}s`,
                  animationDuration: `${r.dur}s`,
                }}
              />
            ))}
          </span>
        );
      })}
    </span>
  );
}

function FeatureCard({ title, desc }: { title: string; desc: string }) {
  return (
    <div className="storm-feature-card relative overflow-hidden rounded-xl border border-white/[0.08] p-4">
      <div className="absolute inset-0 storm-feature-glow pointer-events-none" />
      <h3 className="relative text-sm font-bold text-indigo-200">{title}</h3>
      <p className="relative mt-1.5 text-xs leading-relaxed text-slate-400/80">{desc}</p>
    </div>
  );
}

function CmdExample({ cmd, desc }: { cmd: string; desc: string }) {
  return (
    <div className="flex items-center gap-3 rounded-lg border border-white/[0.06] bg-black/30 px-3 py-2.5">
      <code className="shrink-0 rounded bg-indigo-500/15 px-1.5 py-0.5 text-[11px] font-semibold text-indigo-300">
        {cmd}
      </code>
      <span className="text-xs text-slate-400/80">{desc}</span>
    </div>
  );
}

function Index() {
  // Anti-lag: detect low-power devices on the client (SSR-safe defaults to full FX).
  // Also pauses all storm animations when the tab is hidden so we don't waste CPU.
  const [lowFx, setLowFx] = useState(false);
  const [paused, setPaused] = useState(false);

  useEffect(() => {
    const nav = navigator as Navigator & { deviceMemory?: number; connection?: { saveData?: boolean } };
    const cores = nav.hardwareConcurrency ?? 8;
    const mem = nav.deviceMemory ?? 8;
    const saveData = nav.connection?.saveData === true;
    const coarse = typeof window !== "undefined" && window.matchMedia("(pointer: coarse)").matches;
    if (cores <= 4 || mem <= 4 || saveData || coarse) setLowFx(true);

    const onVis = () => setPaused(document.hidden);
    document.addEventListener("visibilitychange", onVis);
    return () => document.removeEventListener("visibilitychange", onVis);
  }, []);

  return (
    <div
      className={`storm-root relative min-h-screen overflow-hidden text-slate-100 ${lowFx ? "storm-low-fx" : ""} ${paused ? "storm-paused" : ""}`}
    >

      {/* sky gradient */}
      <div className="storm-sky absolute inset-0" />
      {/* animated aurora mesh */}
      <div className="storm-aurora absolute inset-0 pointer-events-none" />
      {/* rolling cloud layers */}
      <div className="storm-clouds storm-clouds-1 absolute inset-0" />
      <div className="storm-clouds storm-clouds-2 absolute inset-0" />
      <div className="storm-clouds storm-clouds-3 absolute inset-0" />
      {/* subtle vignette for depth */}
      <div className="storm-vignette absolute inset-0 pointer-events-none" />
      {/* lightning flash overlay */}
      <div className="storm-lightning absolute inset-0 pointer-events-none" />
      {/* multiple lightning bolts */}
      {BOLTS.map((b, i) => (
        <svg
          key={i}
          className="storm-bolt absolute pointer-events-none"
          viewBox="0 0 100 300"
          preserveAspectRatio="none"
          style={{
            left: b.left,
            top: b.top,
            width: `${b.width}px`,
            height: b.height,
            animationDelay: b.delay,
          }}
        >
          <path
            d="M55 0 L30 130 L55 130 L20 300 L70 140 L42 140 L72 0 Z"
            fill="url(#boltGrad)"
          />
          <defs>
            <linearGradient id="boltGrad" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stopColor="#ffffff" />
              <stop offset="40%" stopColor="#e0e7ff" />
              <stop offset="75%" stopColor="#a5b4fc" />
              <stop offset="100%" stopColor="#6366f1" />
            </linearGradient>
          </defs>
        </svg>
      ))}

      {/* twinkling sparkles */}
      <div className="absolute inset-0 pointer-events-none">
        {SPARKLES.map((s, i) => (
          <span
            key={i}
            className="storm-sparkle"
            style={{
              top: `${s.top}%`,
              left: `${s.left}%`,
              width: `${s.size}px`,
              height: `${s.size}px`,
              animationDelay: `${s.delay}s`,
              animationDuration: `${s.duration}s`,
            }}
          />
        ))}
      </div>

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
        <section className="storm-card storm-card-shimmer relative overflow-hidden rounded-2xl p-6 sm:p-7">
          <div className="storm-card-glow absolute inset-0 pointer-events-none" />
          <div className="storm-scanline absolute inset-0 pointer-events-none" />




          <div className="relative flex items-center justify-between gap-4">
            <p className="text-[11px] font-semibold uppercase tracking-[0.3em] text-indigo-200/70">
              Loadstring Here:
            </p>
            <button
              onClick={() => {
                navigator.clipboard?.writeText(loadstringCommand);
              }}
              className="storm-btn rounded-lg px-3.5 py-1.5 text-xs font-semibold tracking-wide"
            >
              Copy
            </button>
          </div>

          <pre className="storm-code relative mt-3 overflow-hidden rounded-xl border border-white/10 bg-black/40 p-4 text-sm text-slate-200 backdrop-blur">
            <span className="storm-code-sweep pointer-events-none" />
            <code className="relative block overflow-x-auto">{loadstringDisplay}</code>
          </pre>
        </section>

        {/* Features grid */}
        <section className="relative z-10 space-y-6">
          <div className="flex items-center gap-3">
            <span className="h-px flex-1 bg-indigo-400/20" />
            <span className="text-[10px] font-bold uppercase tracking-[0.35em] text-indigo-200/60">
              What this script can do
            </span>
            <span className="h-px flex-1 bg-indigo-400/20" />
          </div>

          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            <FeatureCard
              title="Sleek Dark Glass UI"
              desc="Modern glass-morphism admin panel with smooth animations, customizable themes, typography, and transparency."
            />
            <FeatureCard
              title="Role-Based Permissions"
              desc="Owner, Admin, Staff, and NT Team roles with gated command access. Owner-only kill switch and audit logging."
            />
            <FeatureCard
              title="50+ Built-in Commands"
              desc="From trolling to utility — everything is one ! command away in the chat or via the GUI."
            />
            <FeatureCard
              title="Movement"
              desc="Fly with adjustable speed, Noclip, Infinite Jump, Walk Speed, Jump Power, Hip Height, and Click Teleport."
            />
            <FeatureCard
              title="Player Interactions"
              desc="Goto, Bring, Carry, Headsit, Shouldersit, Piggyback, Bang, Facebang, Backbang, Fling, Stalk, and Spectate."
            />
            <FeatureCard
              title="Trolling"
              desc="Timestop to freeze everyone, Circle players, force-chat with !usay, private banners with !allp."
            />
            <FeatureCard
              title="Performance Boost"
              desc="FPS Booster, Ping Booster, and full Optimize mode — or hit !maxboost for everything at once."
            />
            <FeatureCard
              title="Tags System"
              desc="Tag players as Friend, Target, Ignore, or Priority. Search and inspect tags across servers."
            />
            <FeatureCard
              title="Reanim GUI"
              desc="Built-in ROT animation loader with a full animation browser, preview, playback speed, and custom folder support."
            />
          </div>
        </section>

        {/* Command examples */}
        <section className="relative z-10 space-y-4">
          <div className="flex items-center gap-3">
            <span className="h-px flex-1 bg-indigo-400/20" />
            <span className="text-[10px] font-bold uppercase tracking-[0.35em] text-indigo-200/60">
              Command Examples
            </span>
            <span className="h-px flex-1 bg-indigo-400/20" />
          </div>

          <div className="storm-card relative overflow-hidden rounded-2xl p-5 sm:p-6">
            <div className="storm-card-glow absolute inset-0 pointer-events-none" />
            <div className="relative grid gap-3 sm:grid-cols-2">
              <CmdExample cmd="!fly" desc="Toggle flight mode" />
              <CmdExample cmd="!noclip" desc="Walk through walls" />
              <CmdExample cmd="!goto <player>" desc="Teleport to a player" />
              <CmdExample cmd="!bring <player>" desc="Teleport player to you" />
              <CmdExample cmd="!headsit <player>" desc="Sit on their head" />
              <CmdExample cmd="!bang <player>" desc="Start bang animation" />
              <CmdExample cmd="!facebang <player>" desc="Face-to-face bang" />
              <CmdExample cmd="!fling <player>" desc="Launch a player" />
              <CmdExample cmd="!stalk <player>" desc="Follow and listen" />
              <CmdExample cmd="!timestop" desc="Freeze everyone (admin)" />
              <CmdExample cmd="!circle <player>" desc="Orbit around target" />
              <CmdExample cmd="!allp <msg>" desc="Banner to all script users" />
              <CmdExample cmd="!ws 100" desc="Set walk speed" />
              <CmdExample cmd="!jp 150" desc="Set jump power" />
              <CmdExample cmd="!maxboost" desc="Enable all performance" />
              <CmdExample cmd="!reanim" desc="Open animation GUI" />
            </div>
          </div>
        </section>

        <footer className="flex flex-wrap items-center justify-between gap-3 text-xs text-slate-400/70">
          <span>⛈  storm-grade · Real time syncing</span>
          <span className="font-mono text-indigo-300/70">v.beta</span>
        </footer>
      </main>

      <p className="disclaimer-glow absolute bottom-4 left-0 right-0 z-10 text-center text-[11px] text-red-500">
        Warning* using scripts and injecting on roblox is prohibited by their terms of service use this at your own risk we arent responsible for bans
      </p>

      <style>{`
        /* Pause every storm animation when the tab is hidden — saves real CPU. */
        .storm-paused *,
        .storm-paused *::before,
        .storm-paused *::after {
          animation-play-state: paused !important;
        }
        /* Low-power devices: drop the heaviest layers entirely. */
        .storm-low-fx .storm-drop,
        .storm-low-fx .storm-droplet,
        .storm-low-fx .storm-bolt,
        .storm-low-fx .storm-clouds-2,
        .storm-low-fx .water-ripple {
          display: none !important;
        }
        .storm-low-fx .storm-lightning {
          animation-duration: 16s !important;
        }
        .storm-low-fx .storm-card {
          backdrop-filter: blur(6px) !important;
          -webkit-backdrop-filter: blur(6px) !important;
        }

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
          /* Single drop-shadow instead of stacked — filters compose expensively in Chrome. */
          filter: drop-shadow(0 0 22px rgba(165,180,252,0.85));
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
          will-change: transform;
        }
        @keyframes storm-rain {
          0%   { transform: translate3d(0,-20vh,0) skewX(-12deg); }
          100% { transform: translate3d(0,120vh,0) skewX(-12deg); }
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
          /* text-shadow is cheaper than filter: drop-shadow for text. */
          text-shadow: 0 2px 18px rgba(99,102,241,0.5);
        }

        .storm-card {
          /* Solid translucent gradient instead of backdrop-blur.
             backdrop-filter re-samples the animated rain layer every frame
             in Chrome, which was the main source of lag. */
          background:
            linear-gradient(180deg, rgba(14,20,38,0.92), rgba(6,10,20,0.95));
          border: 1px solid rgba(165,180,252,0.22);
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
          will-change: transform, opacity;
        }
        @keyframes storm-droplet-slip {
          0%, 70% { transform: translate3d(0,0,0); opacity: 0.85; }
          90%     { transform: translate3d(0,60px,0); opacity: 0.6; }
          100%    { transform: translate3d(0,120px,0); opacity: 0; }
        }

        /* Anti-lag: kill heavy animations for users who prefer reduced motion
           or are on low-power devices (Save-Data hint). */
        @media (prefers-reduced-motion: reduce) {
          .storm-clouds,
          .storm-lightning,
          .storm-bolt,
          .storm-drop,
          .storm-droplet,
          .water-letter,
          .water-ripple,
          .disclaimer-glow {
            animation: none !important;
          }
          .storm-card {
            backdrop-filter: none !important;
            -webkit-backdrop-filter: none !important;
          }
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
        .disclaimer-glow {
          text-shadow:
            0 0 6px rgba(255, 50, 0, 0.8),
            0 0 14px rgba(255, 80, 0, 0.6),
            0 0 28px rgba(220, 40, 0, 0.5),
            0 0 48px rgba(200, 30, 0, 0.4);
          animation: disclaimer-inferno-pulse 2.5s ease-in-out infinite;
        }
        @keyframes disclaimer-inferno-pulse {
          0%, 100% {
            text-shadow:
              0 0 6px rgba(255, 50, 0, 0.8),
              0 0 14px rgba(255, 80, 0, 0.6),
              0 0 28px rgba(220, 40, 0, 0.5),
              0 0 48px rgba(200, 30, 0, 0.4);
          }
          50% {
            text-shadow:
              0 0 10px rgba(255, 60, 0, 0.95),
              0 0 22px rgba(255, 100, 0, 0.8),
              0 0 40px rgba(240, 50, 0, 0.65),
              0 0 64px rgba(220, 40, 0, 0.5);
          }
        }

        .storm-feature-card {
          background: linear-gradient(180deg, rgba(16,22,40,0.85), rgba(8,12,22,0.92));
          transition: transform 0.2s ease, box-shadow 0.2s ease;
        }
        .storm-feature-card:hover {
          transform: translateY(-2px);
          box-shadow: 0 20px 50px -12px rgba(0,0,0,0.5), 0 0 40px -8px rgba(99,102,241,0.2);
        }
        .storm-feature-glow {
          background: radial-gradient(ellipse 70% 45% at 50% 0%, rgba(129,140,248,0.10), transparent 70%);
        }

        /* Aurora mesh — soft drifting color blobs for depth */
        .storm-aurora {
          background:
            radial-gradient(ellipse 50% 40% at 15% 25%, rgba(99,102,241,0.22), transparent 60%),
            radial-gradient(ellipse 45% 35% at 85% 20%, rgba(56,189,248,0.18), transparent 60%),
            radial-gradient(ellipse 60% 45% at 50% 80%, rgba(139,92,246,0.18), transparent 65%);
          mix-blend-mode: screen;
          filter: blur(40px);
          animation: storm-aurora-drift 22s ease-in-out infinite alternate;
        }
        @keyframes storm-aurora-drift {
          0%   { transform: translate3d(-2%, -1%, 0) scale(1); opacity: 0.85; }
          50%  { transform: translate3d(3%, 2%, 0) scale(1.06); opacity: 1; }
          100% { transform: translate3d(-1%, 1%, 0) scale(1.02); opacity: 0.9; }
        }

        .storm-clouds-3 {
          background-image:
            radial-gradient(ellipse 900px 180px at 40% 8%, rgba(140,150,200,0.32), transparent 60%),
            radial-gradient(ellipse 700px 150px at 85% 16%, rgba(70,80,130,0.45), transparent 60%);
          animation: storm-drift-a 120s linear infinite reverse;
          opacity: 0.35;
          mix-blend-mode: screen;
          filter: blur(28px);
        }

        .storm-vignette {
          background: radial-gradient(ellipse 90% 70% at 50% 50%, transparent 40%, rgba(0,0,0,0.55) 100%);
        }

        /* Sparkles — tiny twinkling stars across the storm */
        .storm-sparkle {
          position: absolute;
          border-radius: 50%;
          background: radial-gradient(circle, #ffffff 0%, rgba(199,210,254,0.9) 40%, transparent 70%);
          box-shadow: 0 0 6px rgba(199,210,254,0.9), 0 0 14px rgba(129,140,248,0.55);
          opacity: 0;
          animation: storm-twinkle ease-in-out infinite;
          will-change: opacity, transform;
        }
        @keyframes storm-twinkle {
          0%, 100% { opacity: 0; transform: scale(0.6); }
          50%      { opacity: 1; transform: scale(1.2); }
        }

        /* Card shimmer — animated gradient border + breathing glow */
        .storm-card-shimmer {
          position: relative;
        }
        .storm-card-shimmer::before {
          content: "";
          position: absolute;
          inset: 0;
          border-radius: inherit;
          padding: 1px;
          background: conic-gradient(
            from 0deg,
            rgba(165,180,252,0.0),
            rgba(165,180,252,0.85),
            rgba(56,189,248,0.6),
            rgba(139,92,246,0.7),
            rgba(165,180,252,0.0)
          );
          -webkit-mask: linear-gradient(#000 0 0) content-box, linear-gradient(#000 0 0);
          -webkit-mask-composite: xor;
                  mask-composite: exclude;
          animation: storm-conic-spin 8s linear infinite;
          pointer-events: none;
          opacity: 0.9;
        }
        @keyframes storm-conic-spin {
          to { transform: rotate(360deg); }
        }

        /* Code block — diagonal sweep highlight */
        .storm-code-sweep {
          position: absolute;
          top: 0; left: -60%;
          width: 50%; height: 100%;
          background: linear-gradient(
            115deg,
            transparent 0%,
            rgba(165,180,252,0.0) 30%,
            rgba(199,210,254,0.18) 50%,
            rgba(165,180,252,0.0) 70%,
            transparent 100%
          );
          animation: storm-sweep 5.5s ease-in-out infinite;
        }
        @keyframes storm-sweep {
          0%   { transform: translateX(0); }
          60%  { transform: translateX(360%); }
          100% { transform: translateX(360%); }
        }

        /* Scanline across the card */
        .storm-scanline {
          background: linear-gradient(180deg, transparent 0%, rgba(165,180,252,0.18) 50%, transparent 100%);
          height: 2px;
          top: 0;
          animation: storm-scan 7s linear infinite;
          opacity: 0.6;
        }
        @keyframes storm-scan {
          0%   { transform: translateY(0%); opacity: 0; }
          10%  { opacity: 0.7; }
          90%  { opacity: 0.7; }
          100% { transform: translateY(2800%); opacity: 0; }
        }

        /* Crisper title — breathing glow */
        .storm-title {
          animation: storm-title-breathe 5s ease-in-out infinite;
        }
        @keyframes storm-title-breathe {
          0%, 100% { filter: drop-shadow(0 4px 30px rgba(99,102,241,0.25)); }
          50%      { filter: drop-shadow(0 6px 50px rgba(129,140,248,0.55)); }
        }

        .storm-low-fx .storm-sparkle,
        .storm-low-fx .storm-aurora,
        .storm-low-fx .storm-clouds-3,
        .storm-low-fx .storm-card-shimmer::before,
        .storm-low-fx .storm-scanline,
        .storm-low-fx .storm-code-sweep {
          display: none !important;
        }
        .storm-low-fx .storm-title { animation: none !important; }
      `}</style>
    </div>
  );
}
