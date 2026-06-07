-- Force-reload loader for Roblox Admin.
-- Run:
--   loadstring(game:HttpGet("https://raw.githubusercontent.com/DESPAIRDEV293/roblox-script-buddy/main/loader.lua"))()
--
-- Strategy: GitHub's raw CDN caches ~5min and IGNORES query strings.
-- The only reliable bypass is to fetch the latest commit SHA via the API,
-- then load admin.lua pinned to that SHA (content-addressed = always fresh).

local OWNER  = "DESPAIRDEV293"
local REPO   = "roblox-script-buddy"
local BRANCH = "main"
local FILE   = "admin.lua"

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

-- 2) Resolve latest commit SHA on the branch (uncached JSON endpoint).
local sha
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

-- 3) Build source URL. Pinned-to-SHA is content-addressed and never cached stale.
local sourceUrl
if sha then
    sourceUrl = ("https://raw.githubusercontent.com/%s/%s/%s/%s"):format(OWNER, REPO, sha, FILE)
    print(("[AdminLoader] Pinned to commit %s"):format(sha:sub(1, 7)))
else
    -- Fallback: jsdelivr (separate CDN, different cache window) then raw with nonce.
    warn("[AdminLoader] GitHub API unavailable (" .. tostring(apiErr) .. "), falling back")
    sourceUrl = ("https://cdn.jsdelivr.net/gh/%s/%s@%s/%s?v=%d"):format(
        OWNER, REPO, BRANCH, FILE, os.time()
    )
end

local source, srcErr = httpGet(sourceUrl)
if not source then
    -- Last-ditch fallback
    local fallback = ("https://raw.githubusercontent.com/%s/%s/%s/%s?v=%d-%d"):format(
        OWNER, REPO, BRANCH, FILE, os.time(), math.random(1, 1e9)
    )
    source = httpGet(fallback)
    if not source then error("Admin loader: failed to fetch source: " .. tostring(srcErr)) end
end

local fn, compileErr = loadstring(source)
if not fn then
    error("Admin loader: compile failed: " .. tostring(compileErr))
end

print(("[AdminLoader] Loaded %d bytes — running"):format(#source))
return fn()
