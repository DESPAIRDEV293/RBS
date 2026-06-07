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

return {
    -- ===== Owner / dev =====
    ["0rot3"] = {
        color = "#7896ff",
        effect = "nebula",
        tags = { "Owner" },
    },

    -- ===== Examples — edit / remove freely =====
    ["Roblox"] = {
        color = "#ff5577",
        effect = "sparkle",
        tags = { "Staff" },
    },
    ["Builderman"] = {
        color = "#60dc96",
        effect = "rain",
        tags = { "Legend" },
    },
    ["Stickmasterluke"] = {
        color = "#ffffff",
        effect = "snow",
        tags = { "OG" },
    },
}
