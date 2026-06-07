-- Cache-busting loader for Roblox Admin.
-- Run this instead of loading admin.lua directly:
-- loadstring(game:HttpGet("https://raw.githubusercontent.com/DESPAIRDEV293/roblox-script-buddy/main/loader.lua"))()

local adminUrl = "https://raw.githubusercontent.com/DESPAIRDEV293/roblox-script-buddy/main/admin.lua"
local bustedUrl = adminUrl .. "?v=" .. tostring(os.time())
local source = game:HttpGet(bustedUrl)
local fn, err = loadstring(source)

if not fn then
    error("Admin loader failed: " .. tostring(err))
end

return fn()