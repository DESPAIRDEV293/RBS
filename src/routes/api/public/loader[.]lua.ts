import { createFileRoute } from "@tanstack/react-router";

const loaderLua = `-- seige.lol universal bootstrap
local urls={
  "https://seigelollua.lovable.app/api/public/admin.lua",
  "https://raw.githubusercontent.com/DESPAIRDEV293/roblox-script-buddy/main/admin.lua",
  "https://seigescript.online/api/public/admin.lua"
}
local function now()
  local ok,v=pcall(function()
    if os and os.time then return os.time() end
    if tick then return tick() end
    return math.random(1,999999999)
  end)
  return tostring((ok and v) or math.random(1,999999999))
end
local function bodyFromResponse(r)
  if type(r)=="string" then return r end
  if type(r)=="table" then return r.Body or r.body or r.ResponseBody or r.responseBody end
end
local function good(s)
  return type(s)=="string" and #s>1000 and s:find("ADMIN_BUILD",1,true)
end
local function requester()
  if type(syn)=="table" and type(syn.request)=="function" then return syn.request end
  if type(http)=="table" and type(http.request)=="function" then return http.request end
  if type(http_request)=="function" then return http_request end
  if type(request)=="function" then return request end
end
local function get(url)
  local full=url..(url:find("?",1,true) and "&" or "?").."fresh="..now()
  local ok,res=pcall(function()return game:HttpGet(full,true)end)
  res=bodyFromResponse(res)
  if ok and good(res) then return res end
  ok,res=pcall(function()return game:HttpGet(full)end)
  res=bodyFromResponse(res)
  if ok and good(res) then return res end
  local rq=requester()
  if rq then
    ok,res=pcall(function()return rq({Url=full,Method="GET",Headers={Accept="text/plain",["Cache-Control"]="no-cache"}})end)
    res=bodyFromResponse(res)
    if ok and good(res) then return res end
  end
  return nil, tostring(res)
end
local src,last
for _,u in ipairs(urls)do
  local ok,res=pcall(get,u)
  if ok and good(res) then src=res break end
  last=res
end
if not src then warn("[seige.lol] load failed: "..tostring(last));return end
if type(loadstring)~="function" then warn("[seige.lol] executor has no loadstring support");return end
local fn,err=loadstring(src)
if not fn then warn("[seige.lol] compile failed: "..tostring(err));return end
local ok,runErr=pcall(fn)
if not ok then warn("[seige.lol] runtime failed: "..tostring(runErr))end
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