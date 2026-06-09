-- seige.lol — live-sync Roblox Admin loader
-- Run:
--   loadstring(game:HttpGet("https://project--9cc69d4f-b5d0-456b-878c-80800e55ce94-dev.lovable.app/api/public/admin.lua?fresh=" .. tostring(os.time())))()

local OWNER, REPO, BRANCH, FILE = "DESPAIRDEV293", "roblox-script-buddy", "main", "admin.lua"
local BRAND = "seige.lol"
local LIVE_URL = "https://project--9cc69d4f-b5d0-456b-878c-80800e55ce94-dev.lovable.app/api/public/admin.lua"
local PUBLISHED_URL = "https://seigelollua.lovable.app/api/public/admin.lua"

if _G.__AdminCleanup then pcall(_G.__AdminCleanup) end
_G.__AdminLoaded, _G.__AdminUI, _G.__AdminBuild = nil, nil, nil

local HttpService = game:GetService("HttpService")

local function httpGet(url)
    local ok, res = pcall(function() return game:HttpGet(url, true) end)
    if not ok or type(res) ~= "string" then
        ok, res = pcall(function() return game:HttpGet(url) end)
    end
    if not ok then return nil, tostring(res) end
    return res
end

local nonce = tostring(os.time()) .. "-" .. tostring(math.random(1, 1e9))
local liveCandidates = {
    LIVE_URL .. "?fresh=" .. nonce,
    LIVE_URL .. "?v=" .. nonce,
    LIVE_URL .. "?nocache=" .. nonce,
    PUBLISHED_URL .. "?fresh=" .. nonce,
}

local source, err
for _, url in ipairs(liveCandidates) do
    source, err = httpGet(url)
    if source and source:find("ADMIN_BUILD", 1, true) then
        print(("[%s] Loaded live Lovable script (%d bytes)"):format(BRAND, #source))
        break
    end
    source = nil
end

if not source then
print(("[%s] Live endpoint unavailable, resolving latest GitHub commit…"):format(BRAND))

-- 1) Latest commit SHA (uncached JSON API).
local sha
local apiBody = httpGet(("https://api.github.com/repos/%s/%s/commits/%s?_=%d")
    :format(OWNER, REPO, BRANCH, os.time()))
if apiBody then
    local ok, data = pcall(function() return HttpService:JSONDecode(apiBody) end)
    if ok and type(data) == "table" and type(data.sha) == "string" then sha = data.sha end
end

-- 2) Content-addressed raw URL (immutable, never stale).
local sourceUrl
if sha then
    sourceUrl = ("https://raw.githubusercontent.com/%s/%s/%s/%s"):format(OWNER, REPO, sha, FILE)
    print(("[%s] Pinned to %s"):format(BRAND, sha:sub(1, 7)))
else
    warn(("[%s] API unreachable — falling back to jsDelivr"):format(BRAND))
    sourceUrl = ("https://cdn.jsdelivr.net/gh/%s/%s@%s/%s?v=%d")
        :format(OWNER, REPO, BRANCH, FILE, os.time())
end

source, err = httpGet(sourceUrl)
if not source then
    local fb = ("https://raw.githubusercontent.com/%s/%s/%s/%s?v=%d-%d")
        :format(OWNER, REPO, BRANCH, FILE, os.time(), math.random(1, 1e9))
    source = httpGet(fb)
    if not source then error(("[%s] fetch failed: %s"):format(BRAND, tostring(err))) end
end
end

local fn, compileErr = loadstring(source)
if not fn then error(("[%s] compile failed: %s"):format(BRAND, tostring(compileErr))) end

print(("[%s] Loaded %d bytes"):format(BRAND, #source))
return fn()
