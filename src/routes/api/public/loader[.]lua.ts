import { createFileRoute } from "@tanstack/react-router";

const loaderLua = `-- seige.lol universal bootstrap
local urls={
  "https://seigescript.online/api/public/admin.lua",
  "https://seigelollua.lovable.app/api/public/admin.lua",
  "https://raw.githubusercontent.com/DESPAIRDEV293/roblox-script-buddy/main/admin.lua"
}
local fresh=tostring(os.time and os.time() or tick())
local function get(url)
  local full=url.."?fresh="..fresh
  local ok,res=pcall(function()return game:HttpGet(full,true)end)
  if ok and type(res)=="string" and #res>1000 then return res end
  local rq=(syn and syn.request)or(http and http.request)or http_request or request
  if rq then
    local ok2,r=pcall(rq,{Url=full,Method="GET",Headers={["Cache-Control"]="no-cache"}})
    if ok2 and r then
      local body=r.Body or r.body
      if type(body)=="string" and #body>1000 then return body end
    end
  end
end
local src,last
for _,u in ipairs(urls)do
  local ok,res=pcall(get,u)
  if ok and type(res)=="string" and #res>1000 then src=res break else last=res end
end
if not src then warn("seige load failed",last)return end
local fn,err=loadstring(src)
if not fn then warn("seige compile failed",err)return end
local ok,runErr=pcall(fn)
if not ok then warn("seige runtime failed",runErr)end
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