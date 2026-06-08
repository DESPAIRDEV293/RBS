-- seige.lol — Tag database
-- Maps Roblox username -> tag config. Loaded by admin.lua at runtime.
--
-- Fields per entry:
--   color        : "#rrggbb" string OR Color3 (stroke / dot accent color)
--   effect       : "rain" | "snow" | "sparkle" | "nebula" | nil
--   icon         : image/gif URL, "rbxassetid://ID", or numeric asset id
--   displayName  : optional override for the big text (defaults to player's DisplayName)
--   tags         : optional array of short labels shown in the side chip ({"Owner"}, ...)
--
-- IMPORTANT: keys are case-insensitive @Name (not DisplayName).
--
-- Database intentionally empty — every user (including the owner) creates
-- their tag from scratch in the in-game Tags panel.

return {}
