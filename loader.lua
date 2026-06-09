-- Live-sync loader for Roblox Admin.
-- Run:
--   loadstring(game:HttpGet("https://seigelollua.lovable.app/api/public/admin.lua?fresh=" .. tostring(os.time())))()
--
-- Strategy: hit the Lovable public script endpoint first. It serves the bundled
-- admin.lua with no-store headers, so changes go live after publishing.
-- GitHub is kept only as a last fallback.

local OWNER  = "DESPAIRDEV293"
local REPO   = "roblox-script-buddy"
local BRANCH = "main"
local FILE   = "admin.lua"
local LIVE_URL = "https://seigelollua.lovable.app/api/public/admin.lua"

-- 1) Tear down any previous instance.
if _G.__AdminCleanup then pcall(_G.__AdminCleanup) end
_G.__AdminLoaded = nil
_G.__AdminUI = nil
_G.__AdminBuild = nil

local HttpService = game:GetService("HttpService")

local function httpGet(url)
    local ok, res = pcall(function() return game:HttpGet(url, true) end)
    if not ok or type(res) ~= "string" then
        ok, res = pcall(function() return game:HttpGet(url) end)
    end
    if not ok then return nil, tostring(res) end
    return res
end

-- 2) Prefer Lovable's no-cache live script endpoint.
local nonce = tostring(os.time()) .. "-" .. tostring(math.random(1, 1e9))
local source, srcErr
for _, url in ipairs({
    LIVE_URL .. "?fresh=" .. nonce,
    LIVE_URL .. "?v=" .. nonce,
    LIVE_URL .. "?nocache=" .. nonce,
}) do
    source, srcErr = httpGet(url)
    if source and source:find("ADMIN_BUILD", 1, true) then
        print(("[AdminLoader] Loaded live Lovable script (%d bytes)"):format(#source))
        break
    end
    source = nil
end

-- 3) Fallback: resolve latest commit SHA on the branch.
local sha
if not source then
    local apiUrl = ("https://api.github.com/repos/%s/%s/commits/%s?_=%d"):format(
        OWNER, REPO, BRANCH, os.time()
    )
    local apiBody, apiErr = httpGet(apiUrl)
    if apiBody then
        local ok, data = pcall(function() return HttpService:JSONDecode(apiBody) end)
        if ok and type(data) == "table" and type(data.sha) == "string" then
            sha = data.sha
        end
    end

    local sourceUrl
    if sha then
        sourceUrl = ("https://raw.githubusercontent.com/%s/%s/%s/%s"):format(OWNER, REPO, sha, FILE)
        print(("[AdminLoader] Pinned to commit %s"):format(sha:sub(1, 7)))
    else
        warn("[AdminLoader] GitHub API unavailable (" .. tostring(apiErr) .. "), falling back")
        sourceUrl = ("https://cdn.jsdelivr.net/gh/%s/%s@%s/%s?v=%d"):format(
            OWNER, REPO, BRANCH, FILE, os.time()
        )
    end

    source, srcErr = httpGet(sourceUrl)
    if not source then
        local fallback = ("https://raw.githubusercontent.com/%s/%s/%s/%s?v=%d-%d"):format(
            OWNER, REPO, BRANCH, FILE, os.time(), math.random(1, 1e9)
        )
        source = httpGet(fallback)
        if not source then error("Admin loader: failed to fetch source: " .. tostring(srcErr)) end
    end
end

local fn, compileErr = loadstring(source)
if not fn then
    error("Admin loader: compile failed: " .. tostring(compileErr))
end

print(("[AdminLoader] Loaded %d bytes — running"):format(#source))
return fn()
