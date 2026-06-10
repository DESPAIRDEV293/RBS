## Goal

Strip every UI-building block from `admin.lua` (462KB / 14,101 lines) and rebuild a clean dark-glass shell — top center pill + floating panels — that wires back into every existing command handler, state table, hotkey, icon, tag DB, perf booster, and reanim loader. **No functionality lost.** New build tag: `2026-06-10-ui-rebuild-v1`.

## What gets wiped

The following ranges are pure UI construction and get deleted:

```text
Line range     Block
501–798        Load screen
799–1048       Old WINDOW (Win/Root/Drag)
1049–1311      Sidebar / tabs rail
1312–1571      Component primitives (button, slider, toggle as currently styled)
2200–2261      Tabs system
2214–2261      Particle FX layer
2290–2554      Players tab UI
2483–2554      Self-state popout UI
2555–2582      Visuals tab UI
2575–2582      World tab UI
3691–6048      Tags Manager UI (keep the data store + has_role logic above 3691)
6145–6431      Commands list UI
6432–6576      Help panel UI
6577–6815      Performance panel UI (keep handler logic, rebuild panel)
6816–7270      Popout panels (Movement, Fly, Noclip, Anti-AFK, Character, Headsit, Bang, Circle, Invis, Anti, Voice)
7271–7371      Aim tab UI
7372–7462      Executor bar UI
7463–7811      Themes tab UI
7812–7941      Typography & animation customisation UI
7942–8459      Shaders tab UI
8460–9019      Config tab UI (keep save/reset implementations from 8756–9019 — those are not UI)
9047–9526      Profile tab UI
9527–9992      Current "redesign" top pill + floating panels (the half-finished one we're replacing)
```

## What stays untouched

```text
1–164          Header, services, theme tokens, util, root mount, lockout gate
164–500        Roles & permissions (has_role logic, owner detection)
1572–1622      notify() pipeline
1619–1652      Connection tracking
1623–1726      Tags store
1653–1726      Tag icons logic
1727–2199      GitHub-backed tag DB
2262–2289      Helpers
2483–2554      SELF STATE table (data only — UI rebuilt)
2583–3690      Floating tags renderer (driven by tag DB)
6049–6144      "Enable Player Tags" prompt (in-world, not panel chrome)
9993–11104     Other-script detector
11105–11878    Hold/shouldersit/carry/timestop logic
11879–13200    Chat command handlers, reanim, voice helpers, executor bridges
13201–13308    Spotify
13309–13857    Exec notifications cross-client
13858–13890    Tag click global fallback
13891–14096    Cross-game presence
14083–14101    Cleanup + ready
```

All `cmdHandlers[...]` entries, `_G.__SeigeCmds`, role tables, tag DB fetch, perf/fps booster toggles, reanim fetch (now key-gated), hotkeys, and the chat/F6 command bar all keep working — I only swap the Lua that mounts pixels.

## New UI architecture

Three new files of Lua, all inline at the same spots in admin.lua:

### 1. Shell (replaces 799–1311 + 9527–9992)

- `Root` ScreenGui (existing)
- `Pill` — top center floating bar, draggable, holds: brand mark · clock · player count · 5 category buttons · settings cog · close. Glass blur via `BackgroundTransparency` + `UIStroke` + `UICorner 14`.
- Hover any category button → its `Panel` slides down 8px from the pill with spring tween (`TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)`).
- F6 still toggles the executor bar; F4 still toggles whole UI.

### 2. Panel factory (replaces 1312–1571)

One function `makePanel(id, title, opts)` returns a floating frame with:
- header (drag handle, title, close X)
- scrolling body with `UIListLayout` + auto canvas
- consistent padding, divider, accent stripe by category

Six widget primitives rebuilt against this: `pButton`, `pToggle`, `pSlider`, `pTextBox`, `pDropdown`, `pRow`. Same call signatures as today so the panel-building code below can be re-wired with minimal churn.

### 3. Panel re-wiring

Each old panel gets re-authored against the new primitives, but **only the layout is rewritten** — every callback (`cmdHandlers["fly"]`, `_G.__SeigePerf.toggle`, etc.) is called verbatim. Panels rebuilt:

- Players (list + bring/goto/spectate row actions)
- Commands (categorized list)
- Help (full ref, scroll)
- Movement / Fly / Noclip / Anti-AFK / Character / Headsit / Bang / Circle / Invis / Anti / Voice popouts
- Performance (FPS/ping booster + live readout)
- Aim
- Themes / Shaders / Typography
- Config (save/reset/translucency/layout/particles)
- Profile
- Tags Manager (owner-only)

### 4. Executor bar + notify

Rebuilt with the new look but identical contract — F6 toggles, Enter submits to `runBarCmd`. `notify()` keeps its existing API; only the toast visual is reskinned.

## Risk + verification

- The file is huge; one bad line breaks the whole loadstring. I'll bump the build tag and republish after the rewrite so you can re-execute and read any compile error from the first line.
- I'll keep a `_G.__SeigeCleanup` registry so re-executing the loadstring cleanly tears down the old UI before mounting the new one (already present, will preserve).
- Acceptance: `!help`, `!fly`, `!perf`, `!reanim`, `!stalk`, `!nameedit`, F6 bar, and the top pill all open and run.

## Out of scope

- Server route changes — none needed.
- New commands — none added.
- Tag DB format — unchanged.
- The web app (`src/routes/*`) — not touched in this plan.

Approve and I'll start the rewrite.
