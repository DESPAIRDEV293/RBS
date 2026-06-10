## Goal

Rebuild the entire main admin GUI from scratch using the 8 uploaded Roblox icons, keeping 100% feature parity with the current `admin.lua` (commands, shaders, weather, spotify, themes, dock, tags, reanim/rot bridge). Ship a fresh loadstring at the end.

## Icon mapping

| Tab / Action | Asset ID |
|---|---|
| Profile | `rbxassetid://72672681350713` |
| Players | `rbxassetid://133507370080897` |
| Commands | `rbxassetid://118287619529782` |
| Shaders (Skybox) | `rbxassetid://89184279571938` |
| Config | `rbxassetid://125262243617493` |
| Open/Close toggle | `rbxassetid://106620609396373` |
| Spotify / Music | `rbxassetid://103992944497423` |
| Themes | `rbxassetid://75470621365440` |

(No icon supplied for **Misc** and **Tags** — I'll reuse Config + Players glyphs unless you send IDs for those.)

## What gets deleted vs kept

**Deleted (old GUI shell, rebuilt from scratch):**
- Old top bar (Bar / Hamburger / Dock layout switcher and all its color controls)
- Old panel tab system, old translucency target picker, old text-color picker
- Old open/close pill, old draggable positioning code
- All legacy layout-mode branches and their save/load keys

**Kept (logic only, rewired into new shell):**
- Every command, every shader/bloom/DOF effect, weather presets + animations
- Spotify panel logic, Themes presets, Tag rendering, Players list, Profile data
- Config save/load (schema migrated — old keys ignored cleanly)
- `tags.lua` untouched
- Reanim (`rot.lua` / `reanim.lua`) bridge: unchanged loader hooks so existing reanim scripts keep working

## New GUI structure

```text
┌──────────────────────────────────────────────────┐
│  [icon] Seige         · · ·          [close-x]   │  ← slim title bar
├──────┬───────────────────────────────────────────┤
│ [P]  │                                           │
│ [U]  │                                           │
│ [C]  │            Active panel content           │
│ [S]  │       (Profile / Players / Cmds /         │
│ [♪]  │        Shaders / Spotify / Config /       │
│ [⚙]  │        Themes / Tags)                     │
│ [🎨] │                                           │
│ [#]  │                                           │
└──────┴───────────────────────────────────────────┘
   ↑ vertical icon rail, active tile glows accent
```

- Single fixed layout (no more Bar/Hamburger/Dock toggle — those caused most of the bugs).
- Floating open/close button (the 106620609396373 icon) docked bottom-right when GUI is hidden.
- Drag handle on the title bar.
- Per-panel translucency + text color controls live inside the **Themes** tab (simpler than the old multi-target picker).

## Build steps

1. **Snapshot reanim hooks** — grep `_G.__Seige*` symbols `rot.lua` / `reanim.lua` depend on, list them, preserve names exactly.
2. **Extract feature modules** in place (no behavior change): commands table, shaders apply fns, weather presets, spotify, themes, tags — leave as local tables/functions.
3. **Delete the entire GUI build section** (top bar, panel factory, dock, hamburger, layout switcher, old config UI).
4. **Build new shell**: ScreenGui → main frame → title bar + icon rail + content area, with one render function per tab that calls the preserved feature modules.
5. **Rewire config save/load** to the new key set; silently drop unknown old keys.
6. **Verify**: `luajit -bl admin.lua` clean; grep that every preserved `_G.__Seige*` symbol still exists.
7. **Bump `ADMIN_BUILD`**, give you the fresh loadstring.

## Design previews

Before step 4 I'll generate 2–3 rendered mockups of the new main GUI (icon rail + content area styling variants) so you pick the look before I write the Lua.

## Open questions

- **Misc / Tags icons** — send IDs or I reuse Config/Players?
- **Default tab** on open — Profile, or last-used (persisted)?
- **Open/close icon position** — bottom-right (current), or somewhere else?
