import { createFileRoute } from "@tanstack/react-router";

const loaderLua = `-- seige.lol universal bootstrap (key-gated)
local KEY = (typeof(script_key)=="string" and script_key) or (_G and _G.script_key) or (getgenv and getgenv().script_key) or ""
local function safeHwid()
  local ok,v=pcall(function()
    if gethwid then return gethwid() end
    if syn and syn.gethwid then return syn.gethwid() end
    if getgenv and getgenv().identifyexecutor then local _,h=getgenv().identifyexecutor() return h end
    return game:GetService("RbxAnalyticsService"):GetClientId()
  end)
  return (ok and type(v)=="string" and v) or "nohwid"
end
local HWID = safeHwid():gsub("[^%w%-]","" ):sub(1,128)
local function enc(s) return (s:gsub("[^%w]", function(c) return string.format("%%%02X", c:byte()) end)) end
local base="https://seigescript.online/api/public/admin.lua"
local function now()
  local ok,v=pcall(function()
    if os and os.time then return os.time() end
    if tick then return tick() end
    return math.random(1,999999999)
  end)
  return tostring((ok and v) or math.random(1,999999999))
end
local urls={
  base.."?key="..enc(KEY).."&hwid="..enc(HWID).."&fresh="..now(),
  "https://seigescript.online/api/public/admin.lua?key="..enc(KEY).."&hwid="..enc(HWID).."&fresh="..now(),
}
local function body(r)
  if type(r)=="string" then return r end
  if type(r)=="table" then return r.Body or r.body or r.ResponseBody or r.responseBody end
end
local function good(s) return type(s)=="string" and #s>1000 and s:find("ADMIN_BUILD",1,true) end
local function unauth(s) return type(s)=="string" and s:find("_SEIGE_UNAUTHORIZED",1,true) end
local function requester()
  if type(syn)=="table" and type(syn.request)=="function" then return syn.request end
  if type(http)=="table" and type(http.request)=="function" then return http.request end
  if type(http_request)=="function" then return http_request end
  if type(request)=="function" then return request end
end
local function get(u)
  local ok,res=pcall(function() return game:HttpGet(u,true) end)
  res=body(res); if ok and (good(res) or unauth(res)) then return res end
  ok,res=pcall(function() return game:HttpGet(u) end)
  res=body(res); if ok and (good(res) or unauth(res)) then return res end
  local rq=requester()
  if rq then
    ok,res=pcall(function() return rq({Url=u,Method="GET",Headers={Accept="text/plain",["Cache-Control"]="no-cache"}}) end)
    res=body(res); if ok and (good(res) or unauth(res)) then return res end
  end
  return nil
end
if KEY=="" then
  warn("[seige.lol] No script_key set. Get one at https://seigescript.online/get-key then add a line ABOVE this loadstring: script_key = \\"YOUR-KEY\\"")
  return
end
local src
for _,u in ipairs(urls) do
  local r=get(u); if r then src=r; break end
end
if not src then warn("[seige.lol] fetch failed"); return end
if unauth(src) and not good(src) then
  -- run the friendly unauthorized warning script
  local f=(loadstring or load)(src); if f then pcall(f) end; return
end
local fn,err=(loadstring or load)(src)
if not fn then warn("[seige.lol] compile failed: "..tostring(err)); return end
local ok,runErr=pcall(fn)
if not ok then warn("[seige.lol] runtime failed: "..tostring(runErr)) end
`;

const loaderHeaders = {
  "content-type": "text/plain; charset=utf-8",
  "cache-control": "no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0, s-maxage=0",
  "cdn-cache-control": "no-store",
  "surrogate-control": "no-store",
  "pragma": "no-cache",
  "expires": "0",
  "access-control-allow-origin": "*",
  "access-control-allow-methods": "GET, HEAD, OPTIONS",
  "access-control-allow-headers": "Content-Type, Authorization, X-Requested-With, Accept, Origin",
} as const;

export const Route = createFileRoute("/api/public/loader.lua")({
  server: {
    handlers: {
      OPTIONS: async () => new Response(null, { status: 204, headers: loaderHeaders }),
      HEAD: async () => new Response(null, { status: 200, headers: loaderHeaders }),
      GET: async () => new Response(loaderLua, { status: 200, headers: loaderHeaders }),
    },
  },
});
