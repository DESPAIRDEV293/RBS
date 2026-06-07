-- Force-reload loader for Roblox Admin.
-- Run this instead of loading admin.lua directly:
-- loadstring(game:HttpGet("https://raw.githubusercontent.com/DESPAIRDEV293/roblox-script-buddy/main/loader.lua"))()

-- 1) Tear down any previous instance so re-runs don't stack.
if _G.__AdminCleanup then
    pcall(_G.__AdminCleanup)
end
_G.__AdminLoaded = nil
_G.__AdminUI = nil
_G.__AdminBuild = nil

-- 2) Bust every cache layer we can: HttpGet cache + a random nonce.
local base = "https://raw.githubusercontent.com/DESPAIRDEV293/roblox-script-buddy/main/admin.lua"
local nonce = tostring(os.time()) .. "-" .. tostring(math.random(1, 1e9))
local url = base .. "?nocache=" .. nonce

local ok, source = pcall(function()
    -- second arg false = bypass Roblox's HttpGet cache where supported
    return game:HttpGet(url, true)
end)
if not ok or type(source) ~= "string" then
    source = game:HttpGet(url)
end

local fn, err = loadstring(source)
if not fn then
    error("Admin loader failed to compile: " .. tostring(err))
end

print("[AdminLoader] Forced fresh load (" .. #source .. " bytes)")
return fn()
