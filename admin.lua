--==============================================================
--  seige.lol Admin — Full overhaul
--  Sleek dark glass UI · comprehensive feature pack
--==============================================================
local ADMIN_BUILD = "2026-06-09-savecfg-pinned-full"

if _G.__AdminLoaded then
    if _G.__AdminCleanup then pcall(_G.__AdminCleanup) end
end
_G.__AdminLoaded = true
_G.__AdminBuild  = ADMIN_BUILD
print("[seige.lol] Loading " .. ADMIN_BUILD)

-------------------------------------------------------- SERVICES
local Players        = game:GetService("Players")
local UIS            = game:GetService("UserInputService")
local RunService     = game:GetService("RunService")
local TweenService   = game:GetService("TweenService")
local TextService    = game:GetService("TextService")

local Lighting       = game:GetService("Lighting")
local TeleportSrv    = game:GetService("TeleportService")
local HttpService    = game:GetService("HttpService")
local Workspace      = game:GetService("Workspace")
local CoreGui        = game:GetService("CoreGui")
local StarterGui     = game:GetService("StarterGui")

local LP   = Players.LocalPlayer
local cam  = Workspace.CurrentCamera
local mouse = LP:GetMouse()

------------------------------------------------------- THEME (glass)
local T = {
    bg     = Color3.fromRGB(12, 13, 18),
    bg2    = Color3.fromRGB(20, 22, 30),
    bg3    = Color3.fromRGB(32, 36, 48),
    glass  = Color3.fromRGB(18, 20, 28),
    line   = Color3.fromRGB(60, 66, 82),
    text   = Color3.fromRGB(240, 242, 248),
    sub    = Color3.fromRGB(140, 148, 168),
    dim    = Color3.fromRGB(90, 96, 112),
    acc    = Color3.fromRGB(120, 150, 255),
    acc2   = Color3.fromRGB(80, 110, 240),
    good   = Color3.fromRGB(96, 220, 150),
    warn   = Color3.fromRGB(235, 190, 80),
    bad    = Color3.fromRGB(235, 90, 110),
    -- Silver glass + magenta pill palette (panel makeover)
    silver   = Color3.fromRGB(190, 196, 210),
    silverHi = Color3.fromRGB(232, 236, 244),
    silverLo = Color3.fromRGB(120, 126, 140),
    pink     = Color3.fromRGB(255, 120, 170),
    magenta  = Color3.fromRGB(220, 70, 150),
}


------------------------------------------------------- UTILITY
local function inst(class, parent, props)
    local o = Instance.new(class)
    if props then for k, v in pairs(props) do o[k] = v end end
    if parent then o.Parent = parent end
    return o
end
local function corner(parent, r)
    return inst("UICorner", parent, { CornerRadius = UDim.new(0, r or 8) })
end
local function stroke(parent, color, thick, trans)
    return inst("UIStroke", parent, {
        Color = color or T.line,
        Thickness = thick or 1,
        Transparency = trans or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
end
local function pad(parent, p)
    return inst("UIPadding", parent, {
        PaddingTop = UDim.new(0, p), PaddingBottom = UDim.new(0, p),
        PaddingLeft = UDim.new(0, p), PaddingRight = UDim.new(0, p),
    })
end
local function tween(obj, t, props, style, dir)
    return TweenService:Create(obj, TweenInfo.new(t or 0.18,
        style or Enum.EasingStyle.Quad,
        dir or Enum.EasingDirection.Out), props):Play()
end

------------------------------------------------------- UI ROOT
local function safeParent(gui)
    local ok = pcall(function() gui.Parent = CoreGui end)
    if not ok then gui.Parent = LP:WaitForChild("PlayerGui") end
end

local oldGui = CoreGui:FindFirstChild("SeigeAdmin")
if oldGui then oldGui:Destroy() end

local Root = inst("ScreenGui", nil, {
    Name = "SeigeAdmin",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})
safeParent(Root)

------------------------------------------------------- LOCKOUT GATE (!rmvp)
-- The admin (0rot3) can lock specific users out of the script via the
-- !rmvp <user> command. The lock is broadcast through the same chat-marker
-- channel as !allp, and the target client persists the lock to disk so it
-- survives rejoin. On startup, if our name is on the list, we show ONLY a
-- "locked out" screen and halt the rest of the script. !unrmvp clears it.
local LOCKOUT_FILE = "seige_lockout.json"
local function _readLockSet()
    local isf = rawget(getfenv(), "isfile")
    local rf  = rawget(getfenv(), "readfile")
    if not (isf and rf) then return {} end
    local ok, exists = pcall(isf, LOCKOUT_FILE)
    if not ok or not exists then return {} end
    local okR, raw = pcall(rf, LOCKOUT_FILE)
    if not okR or not raw then return {} end
    local okD, data = pcall(HttpService.JSONDecode, HttpService, raw)
    if not okD or type(data) ~= "table" or type(data.locked) ~= "table" then return {} end
    local set = {}
    for _, n in ipairs(data.locked) do if type(n) == "string" then set[n:lower()] = true end end
    return set
end
local function _writeLockSet(set)
    local wf = rawget(getfenv(), "writefile")
    if not wf then return false end
    local list = {}
    for k in pairs(set) do list[#list+1] = k end
    table.sort(list)
    local ok, raw = pcall(HttpService.JSONEncode, HttpService, { locked = list })
    if not ok then return false end
    return pcall(wf, LOCKOUT_FILE, raw)
end
_G.__SeigeLockSet = _readLockSet()

------------------------------------------------------- ROLES & PERMISSIONS
-- 0rot3 is the hardcoded OWNER (full access, cannot be removed).
-- Other Roblox users can be granted one of three roles, which controls
-- whether the Admin panel shows up for them and which actions they can run:
--   admin → view + allp + rmvp/unrmvp + usay
--   staff → view + allp
--   nt    → view only (NT Team — read-only observers)
-- Roles persist on the owner's machine in seige_roles.json. The owner
-- manages them from the Admin panel "Roles & Permissions" section.
local ROLES_FILE = "seige_roles.json"
local OWNER_NAME = "0rot3"
local ROLE_PERMS = {
    owner = { manage_roles = true, view = true, allp = true, lock = true, usay = true, staff_cmd = true, bringall = true, freeze = true, nt_cmd = true },
    admin = { view = true, allp = true, lock = true, usay = true, staff_cmd = true, bringall = true, freeze = true, nt_cmd = true },
    staff = { view = true, allp = true, staff_cmd = true },
    nt    = { view = true, nt_cmd = true },
}
local ROLE_LABELS = {
    owner = "Owner",
    admin = "Admin",
    staff = "Staff",
    nt    = "NT Team",
}
local function _readRoleMap()
    local isf = rawget(getfenv(), "isfile")
    local rf  = rawget(getfenv(), "readfile")
    if not (isf and rf) then return {} end
    local ok, exists = pcall(isf, ROLES_FILE)
    if not ok or not exists then return {} end
    local okR, raw = pcall(rf, ROLES_FILE)
    if not okR or not raw then return {} end
    local okD, data = pcall(HttpService.JSONDecode, HttpService, raw)
    if not okD or type(data) ~= "table" or type(data.roles) ~= "table" then return {} end
    local map = {}
    for name, role in pairs(data.roles) do
        if type(name) == "string" and type(role) == "string" and ROLE_PERMS[role] then
            map[name:lower()] = role
        end
    end
    return map
end
local function _writeRoleMap(map)
    local wf = rawget(getfenv(), "writefile")
    if not wf then return false end
    local ok, raw = pcall(HttpService.JSONEncode, HttpService, { roles = map })
    if not ok then return false end
    return pcall(wf, ROLES_FILE, raw)
end
_G.__SeigeRoleMap = _readRoleMap()

_G.__SeigeMyRole = function()
    if LP.Name == OWNER_NAME then return "owner" end
    return _G.__SeigeRoleMap[LP.Name:lower()]
end
-- KILL SWITCH · owner-only global pause. When ON, every script user except
-- the owner is locked out of commands and role permissions. Owner is always
-- exempt. The flag is mirrored via chat broadcast (see KILL_MARK below) so
-- a single owner toggle propagates to every script user in the server.
_G.__SeigeKilled = _G.__SeigeKilled == true
_G.__SeigeReducedMotion = _G.__SeigeReducedMotion == true
local function _isOwnerLocal() return LP and LP.Name == OWNER_NAME end

_G.__SeigeCan = function(action)
    local r = _G.__SeigeMyRole()
    if not r then return false end
    -- Owner can always do everything, kill switch or not.
    if r == "owner" then
        local p = ROLE_PERMS[r]
        return p and p[action] == true
    end
    -- Non-owners are completely gated when the kill switch is on.
    if _G.__SeigeKilled then return false end
    local p = ROLE_PERMS[r]
    return p and p[action] == true
end
_G.__SeigeSetRole = function(name, role)
    name = tostring(name or ""):gsub("^@",""):gsub("%s+",""):lower()
    if name == "" then return false, "empty name" end
    if name == OWNER_NAME:lower() then return false, "owner is hardcoded" end
    if role == nil or role == "" then
        _G.__SeigeRoleMap[name] = nil
    else
        if not ROLE_PERMS[role] or role == "owner" then return false, "invalid role" end
        _G.__SeigeRoleMap[name] = role
    end
    _writeRoleMap(_G.__SeigeRoleMap)
    return true
end
_G.__SeigeRoleLabel = function(r) return ROLE_LABELS[r] or "—" end

-- Listeners for kill-switch state changes (UI binds here to refresh).
_G.__SeigeKillListeners = _G.__SeigeKillListeners or {}
_G.__SeigeSetKill = function(on, fromBroadcast)
    on = on == true
    if _G.__SeigeKilled == on then return end
    _G.__SeigeKilled = on
    if _G.__SeigeAudit then
        _G.__SeigeAudit(
            "toggle:kill_switch",
            (on and "ON" or "OFF") .. (fromBroadcast and " (received)" or " (local)"),
            true
        )
    end
    for _, fn in ipairs(_G.__SeigeKillListeners) do pcall(fn, on, fromBroadcast) end
end
_G.__SeigeOnKill = function(fn)
    if type(fn) == "function" then table.insert(_G.__SeigeKillListeners, fn) end
end

-- AUDIT LOG · per-client ring buffer of role-gated UI opens, toggles and
-- command attempts. Each entry records who, when, what, and whether the
-- action was permitted by the gating layer. The owner panel renders this
-- list so abuse and unauthorized attempts can be reviewed.
_G.__SeigeAuditLog = _G.__SeigeAuditLog or {}
_G.__SeigeAuditListeners = _G.__SeigeAuditListeners or {}
local AUDIT_MAX = 250
_G.__SeigeAudit = function(action, detail, allowed)
    local entry = {
        t       = os.time(),
        player  = (LP and LP.Name) or "?",
        role    = (_G.__SeigeMyRole and _G.__SeigeMyRole()) or "none",
        action  = tostring(action or ""),
        detail  = tostring(detail or ""),
        allowed = allowed ~= false,
    }
    table.insert(_G.__SeigeAuditLog, entry)
    while #_G.__SeigeAuditLog > AUDIT_MAX do table.remove(_G.__SeigeAuditLog, 1) end
    for _, fn in ipairs(_G.__SeigeAuditListeners) do pcall(fn, entry) end
end
_G.__SeigeOnAudit = function(fn)
    if type(fn) == "function" then table.insert(_G.__SeigeAuditListeners, fn) end
end
_G.__SeigeClearAudit = function()
    _G.__SeigeAuditLog = {}
    for _, fn in ipairs(_G.__SeigeAuditListeners) do pcall(fn, nil) end
end

-- Help popup: shows role-specific commands
local HELP_COMMANDS = {
    { perms = {"staff_cmd"}, cmd = "!bring <user>",         desc = "Teleport a script user to you" },
    { perms = {"staff_cmd"}, cmd = "!goto / !tp <user>",    desc = "Teleport to a player" },
    { perms = {"staff_cmd"}, cmd = "!warn <user> <msg>",    desc = "Send a private warning banner" },
    { perms = {"staff_cmd"}, cmd = "!shout <msg>",          desc = "Big centered overlay for all script users" },
    { perms = {"staff_cmd"}, cmd = "!ping <user>",          desc = "Flash target's screen + bell sound" },
    { perms = {"staff_cmd"}, cmd = "!whois <user>",         desc = "Show local info about a player" },
    { perms = {"staff_cmd"}, cmd = "!list",                 desc = "List all detected script users" },
    { perms = {"staff_cmd"}, cmd = "!pm <user> <msg>",      desc = "Private banner toast to one script user only" },
    { perms = {"staff_cmd"}, cmd = "!alert <msg>",          desc = "Yellow warning toast to every script user" },
    { perms = {"staff_cmd"}, cmd = "!view <user>",          desc = "Spectate the camera of any player" },
    { perms = {"staff_cmd"}, cmd = "!unview",               desc = "Restore your own camera after !view" },
    { perms = {"staff_cmd"}, cmd = "!nearby",               desc = "List script users within 80 studs of you" },
    { perms = {"bringall"},  cmd = "!bringall",             desc = "Teleport every script user to you" },
    { perms = {"freeze"},    cmd = "!freeze <user>",        desc = "Anchor the target script user" },
    { perms = {"freeze"},    cmd = "!unfreeze <user>",      desc = "Unanchor the target script user" },
    { perms = {"allp"},      cmd = "!allp <msg>",           desc = "Private top-banner toast to every script user" },
    { perms = {"lock"},      cmd = "!rmvp <user>",          desc = "Lock a user out of the script" },
    { perms = {"lock"},      cmd = "!unrmvp <user>",        desc = "Unlock a user from the script" },
    { perms = {"usay"},      cmd = "!usay <user> <msg>",    desc = "Force-chat through a target user" },
    { perms = {"nt_cmd"},    cmd = "!taginfo <user>",       desc = "Show full tag details" },
    { perms = {"nt_cmd"},    cmd = "!taglist",              desc = "List all tagged players in this server" },
    { perms = {"nt_cmd"},    cmd = "!tagcheck <user>",      desc = "Check if a player has a tag entry" },
    { perms = {"nt_cmd"},    cmd = "!tagfind <keyword>",    desc = "Search tag database by username or tag" },
    { perms = {"nt_cmd"},    cmd = "!tagcolors",            desc = "Show colors used in the tag database" },
    { perms = {},            cmd = "!reanim",               desc = "Launch the Reanim GUI (purple-storm build)" },
}

local helpGui = nil
local function showRoleHelp()
    if helpGui then pcall(function() helpGui:Destroy() end); helpGui = nil end
    local role = _G.__SeigeMyRole()
    if not role then return end
    if _G.__SeigeAudit then _G.__SeigeAudit("ui_open:role_help", "role=" .. tostring(role), true) end
    local label = _G.__SeigeRoleLabel(role)

    local gui = inst("ScreenGui", nil, {
        Name = "SeigeRoleHelp", IgnoreGuiInset = true, ResetOnSpawn = false,
        DisplayOrder = 250, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    safeParent(gui); helpGui = gui

    local dim = inst("Frame", gui, {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.55, BorderSizePixel = 0, ZIndex = 250,
    })

    local card = inst("Frame", gui, {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 460, 0, 420),
        BackgroundColor3 = T.bg, BorderSizePixel = 0, ZIndex = 251,
    })
    corner(card, 12); stroke(card, T.acc, 1, 0.35)

    local bar = inst("Frame", card, {
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = T.bg2, BorderSizePixel = 0, ZIndex = 252,
    })
    corner(bar, 12)
    inst("TextLabel", bar, {
        BackgroundTransparency = 1, Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(1, -54, 1, 0), Font = Enum.Font.GothamBold, TextSize = 14,
        TextColor3 = T.acc, TextXAlignment = Enum.TextXAlignment.Left,
        Text = "Your Commands  ·  " .. label, ZIndex = 253,
    })
    local closeBtnHelp = inst("TextButton", bar, {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.new(0, 24, 0, 24),
        BackgroundColor3 = T.bg3, BorderSizePixel = 0,
        Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = T.text,
        Text = "✕", ZIndex = 253,
    })
    corner(closeBtnHelp, 6); stroke(closeBtnHelp, T.line, 1, 0.4)
    closeBtnHelp.MouseButton1Click:Connect(function() gui:Destroy(); helpGui = nil end)

    local scroll = inst("ScrollingFrame", card, {
        Position = UDim2.new(0, 12, 0, 48),
        Size = UDim2.new(1, -24, 1, -60),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 3, ScrollBarImageColor3 = T.acc,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ZIndex = 252,
    })
    inst("UIListLayout", scroll, {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    pad(scroll, 4)

    for _, item in ipairs(HELP_COMMANDS) do
        local has = (#item.perms == 0)  -- empty perms = available to everyone
        for _, p in ipairs(item.perms) do
            if _G.__SeigeCan(p) then has = true; break end
        end
        if has then
            local row = inst("Frame", scroll, {
                Size = UDim2.new(1, -8, 0, 44),
                BackgroundColor3 = T.bg2, BackgroundTransparency = 0.25,
                BorderSizePixel = 0, ZIndex = 253,
            })
            corner(row, 8)
            inst("TextLabel", row, {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 10, 0, 2),
                Size = UDim2.new(1, -20, 0, 20),
                Font = Enum.Font.GothamBold, TextSize = 12,
                TextColor3 = T.text, TextXAlignment = Enum.TextXAlignment.Left,
                Text = item.cmd, ZIndex = 254,
            })
            inst("TextLabel", row, {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 10, 0, 22),
                Size = UDim2.new(1, -20, 0, 18),
                Font = Enum.Font.Gotham, TextSize = 11,
                TextColor3 = T.sub, TextXAlignment = Enum.TextXAlignment.Left,
                Text = item.desc, ZIndex = 254,
            })
        end
    end
end

local function showLockoutScreen()
    -- Wipe anything we already parented and replace with a minimal
    -- "contact staff" panel. Keeps the ScreenGui so we still own the layer.
    for _, c in ipairs(Root:GetChildren()) do pcall(function() c:Destroy() end) end
    local dim = inst("Frame", Root, {
        Name = "Lockout",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.fromRGB(6, 7, 12),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        ZIndex = 999,
    })
    local card = inst("Frame", dim, {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 420, 0, 220),
        BackgroundColor3 = T.bg2,
        BorderSizePixel = 0,
        ZIndex = 1000,
    })
    corner(card, 14); stroke(card, T.bad, 2, 0.2)
    inst("TextLabel", card, {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 22), Size = UDim2.new(1, 0, 0, 28),
        Font = Enum.Font.GothamBold, TextSize = 22, TextColor3 = T.bad,
        Text = "ACCESS REVOKED", ZIndex = 1001,
    })
    inst("TextLabel", card, {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 24, 0, 64), Size = UDim2.new(1, -48, 0, 70),
        Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = T.text,
        TextWrapped = true,
        TextYAlignment = Enum.TextYAlignment.Top,
        Text = "You have been locked out of seige.lol.\n\nContact staff to restore access.",
        ZIndex = 1001,
    })
    inst("TextLabel", card, {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 24, 1, -44), Size = UDim2.new(1, -48, 0, 18),
        Font = Enum.Font.GothamMedium, TextSize = 11, TextColor3 = T.dim,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = "User: @" .. LP.Name, ZIndex = 1001,
    })
    inst("TextLabel", card, {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 24, 1, -24), Size = UDim2.new(1, -48, 0, 18),
        Font = Enum.Font.GothamMedium, TextSize = 11, TextColor3 = T.dim,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = "Status: locked", ZIndex = 1001,
    })
end

-- Public hook so the live LOCK/UNLOCK chat handler can flip our screen
-- without restarting the script.
_G.__SeigeApplyLock = function(targetName, locked)
    if not targetName then return end
    local key = tostring(targetName):lower()
    local set = _readLockSet()
    if locked then set[key] = true else set[key] = nil end
    _writeLockSet(set)
    _G.__SeigeLockSet = set
    if key == LP.Name:lower() then
        if locked then showLockoutScreen() end
        -- unlock takes effect on next rejoin (the rest of the script is gone)
    end
end

if _G.__SeigeLockSet[LP.Name:lower()] then
    showLockoutScreen()
    error("[seige] locked out — contact staff", 0)
end



------------------------------------------------------- LOAD SCREEN
local function showLoadScreen()
    local ls = inst("Frame", Root, {
        Name = "LoadScreen",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.fromRGB(6, 7, 12),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        ZIndex = 500,
    })
    inst("UIGradient", ls, {
        Rotation = 135,
        Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(14, 16, 26)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(8, 9, 16)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(4, 5, 10)),
        },
    })

    -- subtle vignette glow blob behind the card
    local glow = inst("Frame", ls, {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 700, 0, 700),
        BackgroundColor3 = T.acc,
        BackgroundTransparency = 0.85,
        BorderSizePixel = 0,
        ZIndex = 500,
    })
    corner(glow, 9999)
    inst("UIGradient", glow, {
        Transparency = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 0.75),
            NumberSequenceKeypoint.new(0.5, 0.9),
            NumberSequenceKeypoint.new(1, 1),
        },
        Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, T.acc),
            ColorSequenceKeypoint.new(1, T.acc2),
        },
        Rotation = 0,
    })

    -- floating particles
    for i = 1, 18 do
        local p = inst("Frame", ls, {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(math.random(), 0, 1 + math.random() * 0.2, 0),
            Size = UDim2.new(0, math.random(2, 4), 0, math.random(2, 4)),
            BackgroundColor3 = (i % 3 == 0) and T.acc2 or T.acc,
            BackgroundTransparency = 0.5 + math.random() * 0.3,
            BorderSizePixel = 0,
            ZIndex = 500,
        })
        corner(p, 9999)
        task.spawn(function()
            while p.Parent do
                local dur = 4 + math.random() * 4
                TweenService:Create(p, TweenInfo.new(dur, Enum.EasingStyle.Linear), {
                    Position = UDim2.new(math.random(), 0, -0.2, 0),
                }):Play()
                task.wait(dur)
                p.Position = UDim2.new(math.random(), 0, 1.1, 0)
            end
        end)
    end

    local card = inst("Frame", ls, {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 440, 0, 260),
        BackgroundColor3 = T.glass,
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        ZIndex = 501,
    })
    corner(card, 20)
    stroke(card, T.acc, 1, 0.35)
    inst("UIGradient", card, {
        Rotation = 120,
        Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, T.bg2),
            ColorSequenceKeypoint.new(1, T.glass),
        },
    })

    -- accent bar at top of card
    local accentBar = inst("Frame", card, {
        Position = UDim2.new(0.5, -1, 0, 0),
        AnchorPoint = Vector2.new(0.5, 0),
        Size = UDim2.new(0, 0, 0, 2),
        BackgroundColor3 = T.acc,
        BorderSizePixel = 0,
        ZIndex = 503,
    })
    inst("UIGradient", accentBar, {
        Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, T.acc2),
            ColorSequenceKeypoint.new(1, T.acc),
        },
    })

    -- avatar ring (tries to fetch player's headshot)
    local ring = inst("Frame", card, {
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 24),
        Size = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = T.bg3,
        BorderSizePixel = 0,
        ZIndex = 502,
    })
    corner(ring, 9999)
    stroke(ring, T.acc, 2, 0.2)
    local avatar = inst("ImageLabel", ring, {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, -6, 1, -6),
        BackgroundTransparency = 1,
        Image = "",
        ImageTransparency = 1,
        ZIndex = 503,
    })
    corner(avatar, 9999)
    task.spawn(function()
        local ok, img = pcall(function()
            return Players:GetUserThumbnailAsync(LP.UserId,
                Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
        end)
        if ok and img then
            avatar.Image = img
            TweenService:Create(avatar, TweenInfo.new(0.5), { ImageTransparency = 0 }):Play()
        end
    end)

    local welcome = inst("TextLabel", card, {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 96),
        Size = UDim2.new(1, 0, 0, 16),
        Font = Enum.Font.Gotham,
        Text = "WELCOME TO",
        TextColor3 = T.sub,
        TextSize = 11,
        TextTransparency = 1,
        ZIndex = 502,
    })
    -- letter-space the welcome
    welcome.Text = "W E L C O M E   T O"

    local title = inst("TextLabel", card, {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 116),
        Size = UDim2.new(1, 0, 0, 32),
        Font = Enum.Font.GothamBold,
        Text = "Seige Admin",
        TextColor3 = T.text,
        TextSize = 26,
        TextTransparency = 1,
        ZIndex = 502,
    })
    inst("UIGradient", title, {
        Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, T.text),
            ColorSequenceKeypoint.new(1, T.acc),
        },
    })

    local displayName = LP.DisplayName ~= "" and LP.DisplayName or LP.Name
    local hello = inst("TextLabel", card, {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 152),
        Size = UDim2.new(1, 0, 0, 18),
        Font = Enum.Font.GothamMedium,
        Text = "hey, " .. displayName,
        TextColor3 = T.acc,
        TextSize = 14,
        TextTransparency = 1,
        ZIndex = 502,
    })

    -- progress bar
    local barBg = inst("Frame", card, {
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 188),
        Size = UDim2.new(0, 320, 0, 4),
        BackgroundColor3 = T.bg3,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        ZIndex = 502,
    })
    corner(barBg, 2)
    local barFill = inst("Frame", barBg, {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = T.acc,
        BorderSizePixel = 0,
        ZIndex = 503,
    })
    corner(barFill, 2)
    inst("UIGradient", barFill, {
        Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, T.acc2),
            ColorSequenceKeypoint.new(1, T.acc),
        },
    })

    local status = inst("TextLabel", card, {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 204),
        Size = UDim2.new(1, 0, 0, 14),
        Font = Enum.Font.Gotham,
        Text = "Initializing…",
        TextColor3 = T.dim,
        TextSize = 10,
        TextTransparency = 1,
        ZIndex = 502,
    })

    local credit = inst("TextLabel", card, {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 1, -20),
        Size = UDim2.new(1, 0, 0, 14),
        Font = Enum.Font.Gotham,
        Text = "seige.lol · " .. ADMIN_BUILD,
        TextColor3 = T.dim,
        TextSize = 10,
        TextTransparency = 1,
        ZIndex = 502,
    })

    local steps = {
        "Hooking services",
        "Building interface",
        "Loading modules",
        "Calibrating combat",
        "Finalizing",
        "Ready",
    }

    local function tw(obj, t, props, style)
        TweenService:Create(obj,
            TweenInfo.new(t, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            props):Play()
    end

    -- entrance: card pops up, then text fades in sequentially
    card.Size = UDim2.new(0, 440, 0, 0)
    card.BackgroundTransparency = 1
    tw(card, 0.45, { Size = UDim2.new(0, 440, 0, 260), BackgroundTransparency = 0.05 }, Enum.EasingStyle.Back)
    tw(accentBar, 0.6, { Size = UDim2.new(1, -2, 0, 2) })
    tw(ring, 0.5, { Size = UDim2.new(0, 64, 0, 64) }, Enum.EasingStyle.Back)

    -- breathing glow loop
    task.spawn(function()
        while ls.Parent do
            TweenService:Create(glow, TweenInfo.new(2.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                { BackgroundTransparency = 0.92 }):Play()
            task.wait(2.4)
            TweenService:Create(glow, TweenInfo.new(2.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                { BackgroundTransparency = 0.8 }):Play()
            task.wait(2.4)
        end
    end)

    task.spawn(function()
        task.wait(0.3)
        tw(welcome, 0.4, { TextTransparency = 0 })
        task.wait(0.15)
        tw(title, 0.5, { TextTransparency = 0 })
        task.wait(0.2)
        tw(hello, 0.5, { TextTransparency = 0 })
        task.wait(0.15)
        tw(status, 0.4, { TextTransparency = 0 })
        tw(credit, 0.4, { TextTransparency = 0.3 })

        for i, label in ipairs(steps) do
            status.Text = label .. "…"
            local pct = i / #steps
            tw(barFill, 0.3, { Size = UDim2.new(pct, 0, 1, 0) })
            task.wait(0.2 + math.random() * 0.15)
        end
        task.wait(0.35)

        -- exit
        tw(ls, 0.5, { BackgroundTransparency = 1 })
        tw(card, 0.45, { BackgroundTransparency = 1, Size = UDim2.new(0, 440, 0, 240) })
        for _, d in ipairs(ls:GetDescendants()) do
            if d:IsA("TextLabel") then TweenService:Create(d, TweenInfo.new(0.35), { TextTransparency = 1 }):Play()
            elseif d:IsA("Frame") then TweenService:Create(d, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
            elseif d:IsA("ImageLabel") then TweenService:Create(d, TweenInfo.new(0.35), { ImageTransparency = 1 }):Play()
            elseif d:IsA("UIStroke") then TweenService:Create(d, TweenInfo.new(0.35), { Transparency = 1 }):Play() end
        end
        task.wait(0.55)
        ls:Destroy()
    end)
end
showLoadScreen()



------------------------------------------------------- WINDOW
local Win = inst("Frame", Root, {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = UDim2.new(0, 780, 0, 540),
    ClipsDescendants = true,
    BackgroundColor3 = T.bg,
    BackgroundTransparency = 0.05,
    BorderSizePixel = 0,
    Active = true,
})
corner(Win, 20)
stroke(Win, T.silver, 1, 0.55)
-- silver glass gradient (subtle sheen across the whole panel)
inst("UIGradient", Win, {
    Rotation = 130,
    Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, T.silverHi),
        ColorSequenceKeypoint.new(0.45, T.silver),
        ColorSequenceKeypoint.new(1, T.silverLo),
    },
    Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.55),
        NumberSequenceKeypoint.new(0.5, 0.7),
        NumberSequenceKeypoint.new(1, 0.55),
    },
})
-- soft outer glow (silver halo, stronger spread)
local glow = inst("ImageLabel", Win, {
    BackgroundTransparency = 1,
    Image = "rbxasset://textures/ui/Controls/DropShadow.png",
    ImageColor3 = T.silverHi,
    ImageTransparency = 0.7,
    ScaleType = Enum.ScaleType.Slice,
    SliceCenter = Rect.new(12,12,244,244),
    Size = UDim2.new(1, 56, 1, 56),
    Position = UDim2.new(0, -28, 0, -28),
    ZIndex = 0,
})
-- inner magenta wash bleeding from the active rail (matches the reference)
inst("ImageLabel", Win, {
    BackgroundTransparency = 1,
    Image = "rbxasset://textures/ui/Controls/DropShadow.png",
    ImageColor3 = T.magenta,
    ImageTransparency = 0.88,
    ScaleType = Enum.ScaleType.Slice,
    SliceCenter = Rect.new(12,12,244,244),
    Size = UDim2.new(1, 80, 1, 80),
    Position = UDim2.new(0, -40, 0, -40),
    ZIndex = 0,
})


-- Custom background (image / gif via spritesheet) -- lives behind glass
local Backdrop = inst("ImageLabel", Win, {
    Name = "Backdrop",
    BackgroundTransparency = 1,
    Image = "",
    ImageTransparency = 0.4,
    ScaleType = Enum.ScaleType.Crop,
    Size = UDim2.new(1, 0, 1, 0),
    Position = UDim2.new(0, 0, 0, 0),
    ZIndex = 0,
})
corner(Backdrop, 14)

-- Title bar (drag region)
local Top = inst("Frame", Win, {
    Size = UDim2.new(1, 0, 0, 44),
    BackgroundTransparency = 1,
})
inst("UIPadding", Top, {
    PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 8),
})
local Brand = inst("TextLabel", Top, {
    BackgroundTransparency = 1,
    Size = UDim2.new(0, 200, 1, 0),
    Font = Enum.Font.GothamBlack,
    TextSize = 17,
    TextColor3 = T.text,
    TextXAlignment = Enum.TextXAlignment.Left,
    Text = "seige.lol",
})
local SubBrand = inst("TextLabel", Top, {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 96, 0, 4),
    Size = UDim2.new(0, 240, 1, -8),
    Font = Enum.Font.Gotham,
    TextSize = 11,
    TextColor3 = T.sub,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Center,
    Text = "admin · " .. ADMIN_BUILD,
})

-- Titlebar clock
local TopClock = inst("TextLabel", Top, {
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -218, 0.5, 0),
    Size = UDim2.new(0, 86, 0, 24),
    BackgroundColor3 = T.bg3, BackgroundTransparency = 0.35, BorderSizePixel = 0,
    Font = Enum.Font.GothamSemibold, TextSize = 12,
    TextColor3 = T.text,
    Text = (os.date("%I:%M %p"):gsub("^0", "")),
})
corner(TopClock, 6); stroke(TopClock, T.line, 1, 0.5)
task.spawn(function()
    while TopClock and TopClock.Parent do
        local t = os.date("%I:%M %p"):gsub("^0", "")
        TopClock.Text = t
        task.wait(1)
    end
end)

local function topBtn(icon, x, fn)
    local b = inst("TextButton", Top, {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, x, 0.5, 0),
        Size = UDim2.new(0, 28, 0, 28),
        BackgroundColor3 = T.bg3,
        BackgroundTransparency = 0.3,
        AutoButtonColor = false,
        Text = icon,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = T.text,
    })
    corner(b, 8); stroke(b, T.line, 1, 0.4)
    b.MouseEnter:Connect(function() tween(b, 0.15, {BackgroundColor3 = T.acc, BackgroundTransparency = 0.2}) end)
    b.MouseLeave:Connect(function() tween(b, 0.15, {BackgroundColor3 = T.bg3, BackgroundTransparency = 0.3}) end)
    b.MouseButton1Click:Connect(fn)
    return b
end

local minimized = false
local Body = inst("Frame", Win, {
    Position = UDim2.new(0, 0, 0, 44),
    Size = UDim2.new(1, 0, 1, -44),
    BackgroundTransparency = 1,
})

-- Top-right window controls (matches: minimize — , maximize □ , close ✕)
local closeBtn = topBtn("✕", -38, function()
    if _G.__AdminCleanup then _G.__AdminCleanup() end
end)
local maximized = false
local _preMaxSize = UDim2.new(0,660,0,460)
local maxBtn = topBtn("□", -72, function()
    if minimized then return end
    if not maximized then
        _preMaxSize = Win.Size
        maximized = true
        local cam = workspace.CurrentCamera
        local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
        tween(Win, 0.18, { Size = UDim2.new(0, math.max(660, vp.X - 80), 0, math.max(460, vp.Y - 100)) })
    else
        maximized = false
        tween(Win, 0.18, { Size = _preMaxSize })
    end
end)
local minBtn = topBtn("—", -106, function()
    minimized = not minimized
    tween(Win, 0.18, { Size = minimized and UDim2.new(0,660,0,44) or (maximized and Win.Size or UDim2.new(0,660,0,460)) })
    Body.Visible = not minimized
end)
local helpBtn = topBtn("?", -140, showRoleHelp)
-- Only role-holders (owner/admin/staff/nt) get the ? help popup; for everyone
-- else the button has nothing to show, so hide it entirely.
local function _hasRole()
    local _myR = _G.__SeigeMyRole and _G.__SeigeMyRole() or nil
    return (_myR or LP.Name == OWNER_NAME) == true
end
if not _hasRole() then helpBtn.Visible = false end

-- Open/close toggle (rightmost in top bar): image icon when open, 3-line hamburger when closed.
local toggleBtn = inst("TextButton", Top, {
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -4, 0.5, 0),
    Size = UDim2.new(0, 28, 0, 28),
    BackgroundColor3 = T.bg3,
    BackgroundTransparency = 0.3,
    AutoButtonColor = false,
    Text = "",
    Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = T.text,
    ZIndex = 5,
})
corner(toggleBtn, 8); stroke(toggleBtn, T.line, 1, 0.4)
local toggleImg = inst("ImageLabel", toggleBtn, {
    BackgroundTransparency = 1,
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = UDim2.new(0, 18, 0, 18),
    Image = "rbxassetid://106620609396373",
    ImageColor3 = T.text,
    ZIndex = 6,
})
toggleBtn.MouseEnter:Connect(function() tween(toggleBtn, 0.15, {BackgroundColor3 = T.acc, BackgroundTransparency = 0.2}) end)
toggleBtn.MouseLeave:Connect(function() tween(toggleBtn, 0.15, {BackgroundColor3 = T.bg3, BackgroundTransparency = 0.3}) end)

local guiHidden = false
local prevMinimized = false
toggleBtn.MouseButton1Click:Connect(function()
    guiHidden = not guiHidden
    if guiHidden then
        prevMinimized = minimized
        Body.Visible = false
        closeBtn.Visible = false
        minBtn.Visible = false
        helpBtn.Visible = false
        tween(Win, 0.18, { Size = UDim2.new(0, 44, 0, 36) })
        toggleImg.Visible = false
        toggleBtn.Text = "≡"
    else
        toggleBtn.Text = ""
        toggleImg.Visible = true
        closeBtn.Visible = true
        minBtn.Visible = true
        helpBtn.Visible = _hasRole()
        tween(Win, 0.18, { Size = prevMinimized and UDim2.new(0,660,0,44) or UDim2.new(0,660,0,460) })
        Body.Visible = not prevMinimized
    end
end)

-- Drag
do
    local dragging, ds, sp
    Top.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true; ds = i.Position; sp = Win.Position
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - ds
            Win.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
end

------------------------------------------------------- SIDEBAR / TABS
local SIDE_W = 156
local HEADER_H = 38

local Side = inst("Frame", Body, {
    Size = UDim2.new(0, SIDE_W, 1, -12),
    Position = UDim2.new(0, 8, 0, 4),
    BackgroundColor3 = T.silverHi,
    BackgroundTransparency = 0.78,
    BorderSizePixel = 0,
})
corner(Side, 16); stroke(Side, T.silver, 1, 0.55)
-- silver sheen on the rail itself
inst("UIGradient", Side, {
    Rotation = 110,
    Color = ColorSequence.new(T.silverHi, T.silver),
    Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.55),
        NumberSequenceKeypoint.new(1, 0.85),
    },
})
inst("UIListLayout", Side, {
    Padding = UDim.new(0, 6),
    SortOrder = Enum.SortOrder.LayoutOrder,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
})
pad(Side, 8)


local ContentArea = inst("Frame", Body, {
    Position = UDim2.new(0, SIDE_W + 16, 0, 4),
    Size = UDim2.new(1, -(SIDE_W + 24), 1, -12),
    BackgroundTransparency = 1,
})

local Header = inst("Frame", ContentArea, {
    Size = UDim2.new(1, 0, 0, HEADER_H),
    BackgroundColor3 = T.bg2,
    BackgroundTransparency = 0.2,
    BorderSizePixel = 0,
})
corner(Header, 10); stroke(Header, T.line, 1, 0.5)
local HeaderTitle = inst("TextLabel", Header, {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 14, 0, 2),
    Size = UDim2.new(1, -28, 0, 18),
    Font = Enum.Font.GothamBold, TextSize = 14,
    TextColor3 = T.text,
    TextXAlignment = Enum.TextXAlignment.Left,
    Text = "",
})
local HeaderSub = inst("TextLabel", Header, {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 14, 0, 19),
    Size = UDim2.new(1, -28, 0, 16),
    Font = Enum.Font.Gotham, TextSize = 10,
    TextColor3 = T.sub,
    TextXAlignment = Enum.TextXAlignment.Left,
    Text = "",
})

local Pages = inst("Frame", ContentArea, {
    Position = UDim2.new(0, 0, 0, HEADER_H + 6),
    Size = UDim2.new(1, 0, 1, -(HEADER_H + 6)),
    BackgroundTransparency = 1,
})

-- Hover tooltip for icon-only sidebar
local Tip = inst("TextLabel", Win, {
    Visible = false,
    BackgroundColor3 = T.bg3, BackgroundTransparency = 0.05,
    BorderSizePixel = 0,
    Font = Enum.Font.GothamSemibold, TextSize = 11,
    TextColor3 = T.text,
    Size = UDim2.new(0, 80, 0, 22),
    ZIndex = 50,
    Text = "",
})
corner(Tip, 6); stroke(Tip, T.line, 1, 0.5)

local tabs = {}  -- name -> { btn, page, ico, title, subtitle }
local currentTab

local function _animPageSwap(page, show)
    if not page then return end
    local sc = page:FindFirstChildOfClass("UIScale")
        or inst("UIScale", page, { Scale = 1 })
    if _G.__SeigeReducedMotion then
        if show then
            page.Visible = true
            sc.Scale = 1
        else
            page.Visible = false
            sc.Scale = 1
        end
        return
    end
    if show then
        page.Visible = true
        sc.Scale = 0.96
        TweenService:Create(sc, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            { Scale = 1 }):Play()
    else
        TweenService:Create(sc, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            { Scale = 0.96 }):Play()
        task.delay(0.14, function()
            if page and page.Parent then page.Visible = false end
        end)
    end
end

local function setTab(name)
    local e = tabs[name]; if not e then return end
    for n, x in pairs(tabs) do
        if n ~= name then
            -- Inactive: hide gradient pill, dim icon badge + label
            if x.pill then
                if _G.__SeigeReducedMotion then
                    x.pill.BackgroundTransparency = 1
                else
                    tween(x.pill, 0.15, { BackgroundTransparency = 1 })
                end
            end
            if x.icoBadge then
                x.icoBadge.BackgroundTransparency = 0.45
                x.icoBadge.BackgroundColor3 = T.silverHi
            end
            x.ico.TextColor3 = T.silverLo
            if x.lbl then x.lbl.TextColor3 = T.silverLo end
            if x.page.Visible then _animPageSwap(x.page, false) end
        end
    end
    -- Active: show pink->magenta gradient pill, brighten icon + label
    if e.pill then
        if _G.__SeigeReducedMotion then
            e.pill.BackgroundTransparency = 0
        else
            tween(e.pill, 0.18, { BackgroundTransparency = 0 })
        end
    end
    if e.icoBadge then
        e.icoBadge.BackgroundTransparency = 0
        e.icoBadge.BackgroundColor3 = T.silverHi
    end
    e.ico.TextColor3 = T.magenta
    if e.lbl then e.lbl.TextColor3 = T.text end
    _animPageSwap(e.page, true)
    HeaderTitle.Text = e.title or name
    HeaderSub.Text   = e.subtitle or ""
    currentTab = name
end

local function makeTab(name, icon, subtitle)
    -- Row container: full-width, holds the gradient pill (active),
    -- the circular icon badge, and the label.
    local btn = inst("TextButton", Side, {
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Text = "",
    })

    -- Pink->magenta gradient "pill" behind the active row (hidden by default).
    local pill = inst("Frame", btn, {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = T.pink,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 1,
    })
    corner(pill, 19)
    inst("UIGradient", pill, {
        Rotation = 0,
        Color = ColorSequence.new(T.pink, T.magenta),
    })
    -- soft inner glow under the pill
    inst("ImageLabel", pill, {
        BackgroundTransparency = 1,
        Image = "rbxasset://textures/ui/Controls/DropShadow.png",
        ImageColor3 = T.magenta,
        ImageTransparency = 0.55,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(12,12,244,244),
        Size = UDim2.new(1, 24, 1, 24),
        Position = UDim2.new(0, -12, 0, -12),
        ZIndex = 0,
    })

    -- Circular icon badge on the left
    local icoBadge = inst("Frame", btn, {
        Position = UDim2.new(0, 5, 0.5, -14),
        Size = UDim2.new(0, 28, 0, 28),
        BackgroundColor3 = T.silverHi,
        BackgroundTransparency = 0.45,
        BorderSizePixel = 0,
        ZIndex = 2,
    })
    corner(icoBadge, 14)
    stroke(icoBadge, T.silver, 1, 0.5)
    local ico = inst("TextLabel", icoBadge, {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Font = Enum.Font.GothamBold, TextSize = 14,
        TextColor3 = T.silverLo,
        Text = icon or "•",
        ZIndex = 3,
    })

    -- Row label
    local lbl = inst("TextLabel", btn, {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 42, 0, 0),
        Size = UDim2.new(1, -48, 1, 0),
        Font = Enum.Font.GothamSemibold, TextSize = 13,
        TextColor3 = T.silverLo,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = name,
        ZIndex = 3,
    })

    local page = inst("ScrollingFrame", Pages, {
        Visible = false,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = T.magenta,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
    })
    inst("UIListLayout", page, {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    pad(page, 4)

    local entry = {
        btn = btn, page = page, ico = ico, icoBadge = icoBadge,
        lbl = lbl, pill = pill, title = name, subtitle = subtitle,
    }
    tabs[name] = entry

    btn.MouseEnter:Connect(function()
        if currentTab ~= name then
            icoBadge.BackgroundTransparency = 0.15
            ico.TextColor3 = T.text
            lbl.TextColor3 = T.text
        end
    end)
    btn.MouseLeave:Connect(function()
        if currentTab ~= name then
            icoBadge.BackgroundTransparency = 0.45
            ico.TextColor3 = T.silverLo
            lbl.TextColor3 = T.silverLo
        end
    end)
    btn.MouseButton1Click:Connect(function() setTab(name) end)
    return page
end



------------------------------------------------------- COMPONENTS
local function section(parent, text)
    local f = inst("Frame", parent, {
        Size = UDim2.new(1, -8, 0, 22),
        BackgroundTransparency = 1,
    })
    inst("TextLabel", f, {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = T.dim,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = string.upper(text),
    })
    return f
end

local function label(parent, text)
    local f = inst("Frame", parent, {
        Size = UDim2.new(1, -8, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
    })
    local l = inst("TextLabel", f, {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = T.sub,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        Text = text,
    })
    return { frame = f, set = function(_, t) l.Text = t end }
end

local function button(parent, text, fn)
    local b = inst("TextButton", parent, {
        Size = UDim2.new(1, -8, 0, 30),
        BackgroundColor3 = T.bg3,
        BackgroundTransparency = 0.2,
        AutoButtonColor = false,
        Text = text,
        Font = Enum.Font.GothamSemibold,
        TextSize = 12,
        TextColor3 = T.text,
    })
    corner(b, 8); stroke(b, T.line, 1, 0.4)
    b.MouseEnter:Connect(function() tween(b, 0.15, {BackgroundColor3 = T.acc, BackgroundTransparency = 0.15}) end)
    b.MouseLeave:Connect(function() tween(b, 0.15, {BackgroundColor3 = T.bg3, BackgroundTransparency = 0.2}) end)
    if fn then b.MouseButton1Click:Connect(function() pcall(fn) end) end
    return b
end

local function toggle(parent, text, default, fn)
    local f = inst("Frame", parent, {
        Size = UDim2.new(1, -8, 0, 34),
        BackgroundColor3 = T.bg2,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
    })
    corner(f, 8); stroke(f, T.line, 1, 0.5)
    inst("TextLabel", f, {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -60, 1, 0),
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = T.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = text,
    })
    local sw = inst("Frame", f, {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.new(0, 36, 0, 20),
        BackgroundColor3 = default and T.acc or T.bg3,
        BorderSizePixel = 0,
    })
    corner(sw, 10)
    local knob = inst("Frame", sw, {
        Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new(0, default and 18 or 2, 0.5, -8),
        BackgroundColor3 = T.text,
        BorderSizePixel = 0,
    })
    corner(knob, 8)
    local state = default
    local btn = inst("TextButton", f, {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = "",
        AutoButtonColor = false,
    })
    local function apply()
        tween(sw, 0.16, { BackgroundColor3 = state and T.acc or T.bg3 })
        tween(knob, 0.16, { Position = UDim2.new(0, state and 18 or 2, 0.5, -8) })
    end
    btn.MouseButton1Click:Connect(function()
        state = not state; apply()
        if fn then pcall(fn, state) end
    end)
    return {
        set = function(v) state = v; apply(); if fn then pcall(fn, v) end end,
        get = function() return state end,
    }
end

local function slider(parent, text, lo, hi, default, fn)
    local f = inst("Frame", parent, {
        Size = UDim2.new(1, -8, 0, 50),
        BackgroundColor3 = T.bg2,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
    })
    corner(f, 8); stroke(f, T.line, 1, 0.5)
    pad(f, 10)
    local lbl = inst("TextLabel", f, {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -60, 0, 14),
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = T.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = text,
    })
    local valTxt = inst("TextLabel", f, {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.new(0, 60, 0, 14),
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = T.acc,
        TextXAlignment = Enum.TextXAlignment.Right,
        Text = tostring(default),
    })
    local track = inst("Frame", f, {
        Position = UDim2.new(0, 0, 1, -10),
        Size = UDim2.new(1, 0, 0, 4),
        BackgroundColor3 = T.bg3,
        BorderSizePixel = 0,
    })
    corner(track, 2)
    local fill = inst("Frame", track, {
        Size = UDim2.new((default - lo) / (hi - lo), 0, 1, 0),
        BackgroundColor3 = T.acc,
        BorderSizePixel = 0,
    })
    corner(fill, 2)
    local knob = inst("Frame", track, {
        Size = UDim2.new(0, 12, 0, 12),
        Position = UDim2.new((default - lo) / (hi - lo), -6, 0.5, -6),
        BackgroundColor3 = T.text,
        BorderSizePixel = 0,
    })
    corner(knob, 6)

    local dragging = false
    local function setFrac(frac)
        frac = math.clamp(frac, 0, 1)
        fill.Size = UDim2.new(frac, 0, 1, 0)
        knob.Position = UDim2.new(frac, -6, 0.5, -6)
        local val = lo + (hi - lo) * frac
        val = math.floor(val * 100 + 0.5) / 100
        valTxt.Text = tostring(val)
        if fn then pcall(fn, val) end
    end
    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            setFrac((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            setFrac((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
    return { set = function(v) setFrac((v - lo) / (hi - lo)) end }
end

local function dropdown(parent, text, options, fn)
    local f = inst("Frame", parent, {
        Size = UDim2.new(1, -8, 0, 34),
        BackgroundColor3 = T.bg2,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
    })
    corner(f, 8); stroke(f, T.line, 1, 0.5)
    inst("TextLabel", f, {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(0.5, 0, 1, 0),
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = T.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = text,
    })
    local btn = inst("TextButton", f, {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.new(0, 140, 0, 22),
        BackgroundColor3 = T.bg3,
        AutoButtonColor = false,
        Text = options[1] or "—",
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextColor3 = T.text,
    })
    corner(btn, 6); stroke(btn, T.line, 1, 0.4)
    local idx = 1
    btn.MouseButton1Click:Connect(function()
        idx = (idx % #options) + 1
        btn.Text = options[idx]
        if fn then pcall(fn, options[idx]) end
    end)
    if fn then pcall(fn, options[1]) end
    return { set = function(v)
        for i, o in ipairs(options) do if o == v then idx = i; btn.Text = v; if fn then pcall(fn, v) end return end end
    end }
end

local function textbox(parent, placeholder, fn)
    local f = inst("Frame", parent, {
        Size = UDim2.new(1, -8, 0, 32),
        BackgroundColor3 = T.bg2,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
    })
    corner(f, 8); stroke(f, T.line, 1, 0.5)
    local tb = inst("TextBox", f, {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -20, 1, 0),
        PlaceholderText = placeholder,
        PlaceholderColor3 = T.dim,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = T.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = "",
        ClearTextOnFocus = false,
    })
    tb.FocusLost:Connect(function(enter)
        if enter and tb.Text ~= "" then
            local v = tb.Text; tb.Text = ""
            if fn then pcall(fn, v) end
        end
    end)
    return tb
end

------------------------------------------------------- NOTIFY
local Notif = inst("Frame", Root, {
    AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, -16, 1, -16),
    Size = UDim2.new(0, 300, 1, -32),
    BackgroundTransparency = 1,
})
inst("UIListLayout", Notif, {
    VerticalAlignment = Enum.VerticalAlignment.Bottom,
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder,
})

local function notify(text, kind)
    local color = (kind == "good" and T.good) or (kind == "warn" and T.warn) or (kind == "bad" and T.bad) or T.acc
    local n = inst("Frame", Notif, {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = T.bg2,
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
    })
    corner(n, 8); stroke(n, color, 1.5, 0.2)
    inst("Frame", n, {
        Size = UDim2.new(0, 3, 1, -8),
        Position = UDim2.new(0, 4, 0, 4),
        BackgroundColor3 = color,
        BorderSizePixel = 0,
    }).Parent = n
    inst("TextLabel", n, {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(1, -22, 1, 0),
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = T.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = text,
    })
    n.Size = UDim2.new(1, 0, 0, 0)
    tween(n, 0.18, { Size = UDim2.new(1, 0, 0, 36) })
    task.delay(3, function()
        tween(n, 0.18, { BackgroundTransparency = 1 })
        task.wait(0.2); n:Destroy()
    end)
end

------------------------------------------------------- CONNECTION TRACKING
local conns = {}
local function bind(c) table.insert(conns, c); return c end

------------------------------------------------------- TAGS STORE
local Tags = {
    defs = { "Friend", "Target", "Ignore", "Priority" },
    map  = {},
    listeners = {},
}
function Tags:get(uid) return self.map[uid] or {} end
function Tags:has(uid, t) local s = self.map[uid]; return s and s[t] == true end
function Tags:summary(uid)
    local out = {}; for k in pairs(self:get(uid)) do table.insert(out, k) end
    table.sort(out); return table.concat(out, ",")
end
function Tags:onChange(fn) table.insert(self.listeners, fn) end
function Tags:_fire(uid) for _, f in ipairs(self.listeners) do pcall(f, uid) end end
function Tags:add(uid, t)
    self.map[uid] = self.map[uid] or {}
    self.map[uid][t] = true
    local has = false
    for _, x in ipairs(self.defs) do if x == t then has = true break end end
    if not has then table.insert(self.defs, t) end
    if uid ~= 0 then self:_fire(uid) end
end
function Tags:remove(uid, t)
    if self.map[uid] then self.map[uid][t] = nil end
    if uid ~= 0 then self:_fire(uid) end
end
function Tags:toggle(uid, t)
    if self:has(uid, t) then self:remove(uid, t) else self:add(uid, t) end
end

------------------------------------------------------- TAG ICONS (PRO feature, enabled for all)
local TagIcons = { map = {}, listeners = {} }
function TagIcons:get(uid) return self.map[uid] end
function TagIcons:set(uid, url)
    if url == nil or url == "" then self.map[uid] = nil
    else self.map[uid] = url end
    for _, f in ipairs(self.listeners) do pcall(f, uid) end
end
function TagIcons:onChange(fn) table.insert(self.listeners, fn) end

-- Accept rbxassetid://, full URL, raw asset id, or any image/gif URL.
-- For external http(s) URLs, try executor-side download → getcustomasset,
-- otherwise fall back to rbxassetid:// (works only for Roblox-hosted ids).
local _iconCache = {}
local function _getcustomasset()
    return rawget(getfenv(), "getcustomasset")
        or rawget(getfenv(), "getsynasset")
        or (syn and syn.getcustomasset)
        or (getcustomasset)
end
local function _writefile() return rawget(getfenv(), "writefile") or writefile end
local function _isfile()    return rawget(getfenv(), "isfile")    or isfile end
local function _httpget()
    return rawget(getfenv(), "http_get")
        or (syn and syn.request and function(u) local r = syn.request({Url=u, Method="GET"}); return r and r.Body end)
        or (http and http.request and function(u) local r = http.request({Url=u, Method="GET"}); return r and r.Body end)
        or (request and function(u) local r = request({Url=u, Method="GET"}); return r and r.Body end)
        or function(u) return game:HttpGet(u) end
end

local function resolveIconUrl(raw)
    if not raw or raw == "" then return nil end
    raw = tostring(raw):match("^%s*(.-)%s*$")
    if raw == "" then return nil end
    if _iconCache[raw] then return _iconCache[raw] end

    -- Pure numeric asset id
    if raw:match("^%d+$") then
        local out = "rbxassetid://" .. raw
        _iconCache[raw] = out; return out
    end
    -- Already Roblox-internal
    if raw:match("^rbxassetid://") or raw:match("^rbxthumb://") or raw:match("^rbxasset://") then
        _iconCache[raw] = raw; return raw
    end
    -- External http(s) — needs executor download + getcustomasset to display in Roblox UI
    if raw:match("^https?://") then
        local gca, wf, isf, hg = _getcustomasset(), _writefile(), _isfile(), _httpget()
        if gca and wf then
            local ext = raw:match("%.([%w]+)$") or "png"
            ext = ext:lower():sub(1, 4)
            local fname = "seige_tagicon_" .. tostring(#_iconCache + 1) .. "." .. ext
            local ok, body = pcall(hg, raw)
            if ok and type(body) == "string" and #body > 0 then
                local wok = pcall(wf, fname, body)
                if wok then
                    local aok, asset = pcall(gca, fname)
                    if aok and asset then
                        _iconCache[raw] = asset
                        return asset
                    end
                end
            end
        end
        -- Last-ditch: hand it raw; most Roblox clients won't render it but some executors hook ImageLabel.Image
        _iconCache[raw] = raw
        return raw
    end
    _iconCache[raw] = raw
    return raw
end



------------------------------------------------------- TAG DATABASE (GitHub-backed)
-- The GitHub gist now stores one JSON document so every Tags panel option
-- round-trips exactly instead of being squeezed through fragile pipe columns.
-- Legacy pipe rows are still accepted for old backups, but all new saves write:
-- { version = 2, format = "seige.tags.v2", tags = { username = { ... } } }
local TAGS_PASTEBIN_URL = "https://seigelollua.lovable.app/api/public/pastebin?raw=1"
local TAGS_DB_URL       = "https://raw.githubusercontent.com/DESPAIRDEV293/roblox-script-buddy/main/tags.lua"

local TagDB = { entries = {}, localEntries = {}, appliedTags = {}, appliedIcons = {} }
local function parseColor(c)
    if typeof(c) == "Color3" then return c end
    if type(c) == "string" then
        -- accept "#aaa/#bbb" — use the first one
        local first = c:match("([^/]+)")
        local hex = (first or c):gsub("#",""):gsub("%s","")
        -- 8-char w/ alpha: drop the trailing alpha pair so "#ff3b6bff" still works
        if #hex == 8 then hex = hex:sub(1, 6) end
        -- 3-char shorthand: "#fa3" -> "#ffaa33"
        if #hex == 3 then
            hex = hex:sub(1,1):rep(2) .. hex:sub(2,2):rep(2) .. hex:sub(3,3):rep(2)
        end
        if #hex == 6 then
            local r = tonumber(hex:sub(1,2), 16)
            local g = tonumber(hex:sub(3,4), 16)
            local b = tonumber(hex:sub(5,6), 16)
            if r and g and b then return Color3.fromRGB(r, g, b) end
        end
    end
end

-- returns (c1, c2) where c2 may be nil. Accepts "#aaa", "#aaa/#bbb"
local function parseColorPair(c)
    if type(c) ~= "string" then return parseColor(c), nil end
    local a, b = c:match("([^/]+)/([^/]+)")
    if a and b then return parseColor(a), parseColor(b) end
    return parseColor(c), nil
end

-- Bubble fill parser. Returns a table describing how to paint the bubble.
-- Supported syntax (stored in entry.color):
--   "#ff3b6b"                       solid
--   "#ff3b6b/#00aaff"               split (half/half)
--   "grad:#a,#b,#c@90"              linear gradient w/ N stops, optional @angle
--   "image:1234567890"              image fill (asset id or full url)
local function parseFill(s)
    if type(s) ~= "string" or s == "" then return nil end
    local low = s:lower()
    if low:sub(1,9) == "gradient:" or low:sub(1,5) == "grad:" then
        local body = s:gsub("^[Gg][Rr][Aa][Dd][Ii][Ee][Nn][Tt]:", "")
        body = body:gsub("^[Gg][Rr][Aa][Dd]:", "")
        local angle = 90
        local at = body:find("@")
        if at then
            angle = tonumber(body:sub(at + 1)) or 90
            body = body:sub(1, at - 1)
        end
        local stops = {}
        for chunk in (body .. ","):gmatch("([^,]*),") do
            chunk = chunk:gsub("^%s+", ""):gsub("%s+$", "")
            if chunk ~= "" then
                local c = parseColor(chunk)
                if c then stops[#stops + 1] = c end
            end
        end
        if #stops >= 2 then return { kind = "gradient", stops = stops, rotation = angle } end
        if #stops == 1 then return { kind = "solid", c = stops[1] } end
        return nil
    elseif low:sub(1,6) == "image:" or low:sub(1,4) == "img:" or low:sub(1,6) == "asset:"
           or low:sub(1,6) == "decal:" or low:sub(1,8) == "texture:"
           or s:match("^%d+$") or low:match("^rbxassetid://") or low:match("^rbxthumb://")
           or low:match("roblox%.com") then
        -- Accept any of:
        --   "image:<id>" / "img:<id>" / "asset:<id>" / "decal:<id>" / "texture:<id>"
        --   bare numeric asset id (e.g. "1234567890")
        --   "rbxassetid://<id>"  or  "rbxthumb://..." spec
        --   any roblox.com URL — we'll extract the first numeric id from it
        --     ( library/<id>, /asset/?id=<id>, /catalog/<id>, etc. )
        local rest = s:gsub("^[Ii][Mm][Aa][Gg][Ee]:", "")
                      :gsub("^[Ii][Mm][Gg]:", "")
                      :gsub("^[Aa][Ss][Ss][Ee][Tt]:", "")
                      :gsub("^[Dd][Ee][Cc][Aa][Ll]:", "")
                      :gsub("^[Tt][Ee][Xx][Tt][Uu][Rr][Ee]:", "")
        rest = rest:gsub("^%s+", ""):gsub("%s+$", "")
        if rest == "" then return nil end
        local url = rest
        if tonumber(url) then
            url = "rbxassetid://" .. url
        elseif url:lower():match("roblox%.com") then
            -- pull the first numeric id out of the URL
            local id = url:match("[?&]id=(%d+)") or url:match("/(%d+)")
            if id then url = "rbxassetid://" .. id else return nil end
        elseif not (url:lower():match("^rbx") or url:match("^https?://")) then
            local gca = rawget(getfenv(), "getcustomasset") or rawget(getfenv(), "getsynasset")
            if type(gca) == "function" then
                local ok, v = pcall(gca, rest); if ok and v then url = v end
            end
        end
        return { kind = "image", url = url }
    else
        local c1, c2 = parseColorPair(s)
        if c1 and c2 then return { kind = "split", c1 = c1, c2 = c2 } end
        if c1 then return { kind = "solid", c = c1 } end
        return nil
    end
end

local function tagAccentFromFill(raw)
    local fill = parseFill(raw)
    if fill then
        if fill.kind == "solid" then return fill.c end
        if fill.kind == "split" then return fill.c1 end
        if fill.kind == "gradient" and fill.stops and fill.stops[1] then return fill.stops[1] end
    end
    local c1 = parseColorPair(raw)
    return c1
end
function TagDB:configFor(p)
    if not p then return nil end
    local byName = self.entries[(p.Name or ""):lower()]
    if byName then return byName end
    -- Fallback: try matching by DisplayName so entries saved under the
    -- player's display name (instead of their username) still bind.
    local dn = p.DisplayName
    if dn and dn ~= "" then
        local byDisplay = self.entries[dn:lower()]
        if byDisplay then return byDisplay end
    end
    return nil
end

function TagDB:applyTo(p)
    if not p then return end
    local uid = p.UserId

    -- Remove only tags/icons this DB previously applied, so edits and deletes
    -- replace the old tag state instead of stacking stale values forever.
    if self.appliedTags[uid] then
        for t in pairs(self.appliedTags[uid]) do Tags:remove(uid, t) end
        self.appliedTags[uid] = nil
    end
    if self.appliedIcons[uid] then
        TagIcons:set(uid, nil)
        self.appliedIcons[uid] = nil
    end

    local cfg = self:configFor(p); if not cfg then return end
    if cfg.icon then TagIcons:set(uid, cfg.icon); self.appliedIcons[uid] = true end
    if type(cfg.tags) == "table" then
        local applied = {}
        for _, t in ipairs(cfg.tags) do
            Tags:add(uid, t)
            applied[t] = true
        end
        self.appliedTags[uid] = applied
    end
end

local function trim(s) return (tostring(s or ""):gsub("^%s+",""):gsub("%s+$","")) end
local TAGS_JSON_FORMAT = "seige.tags.v2"
local TAG_ALLOWED_FIELDS = {
    displayName = true, color = true, icon = true, tags = true,
    textFx = true, customText = true, customHandle = true, outline = true,
    font = true, textColor = true, textOutline = true,
    avatarOutline = true, showChip = true,
}
local function normTagKey(raw)
    return trim(raw):gsub("^@", ""):lower()
end
local function cleanTagEntry(entry)
    if type(entry) ~= "table" then return nil end
    local out = {}
    for k in pairs(TAG_ALLOWED_FIELDS) do
        local v = entry[k]
        if k == "tags" then
            if type(v) == "table" then
                local list = {}
                for _, t in ipairs(v) do
                    t = trim(t)
                    if t ~= "" then list[#list + 1] = t end
                end
                if #list > 0 then out.tags = list end
            elseif type(v) == "string" and trim(v) ~= "" then
                local list = {}
                for t in (v .. ","):gmatch("([^,]*),") do
                    t = trim(t)
                    if t ~= "" then list[#list + 1] = t end
                end
                if #list > 0 then out.tags = list end
            end
        elseif v ~= nil and tostring(v) ~= "" then
            out[k] = tostring(v)
        end
    end
    return out
end
local function parseTagsJson(src)
    src = tostring(src or "")
    -- Prefer the LAST v2 JSON block if the file was polluted with legacy rows.
    -- This avoids stale/blue fallback data from an older block overriding the
    -- newest save, while still letting the caller recover legacy rows if empty.
    local startAt = nil
    local pos = 1
    while true do
        local a = src:find('{%s*"version"%s*:%s*2', pos)
        local b = src:find('{%s*"format"%s*:%s*"seige%.tags%.v2"', pos)
        local n = nil
        if a and b then n = math.min(a, b) else n = a or b end
        if not n then break end
        startAt = n
        pos = n + 1
    end
    if startAt then
        local endAt = nil
        for i = #src, 1, -1 do
            if src:sub(i, i) == "}" then endAt = i; break end
        end
        if endAt and endAt >= startAt then src = src:sub(startAt, endAt) end
    end
    local ok, decoded = pcall(function() return HttpService:JSONDecode(src) end)
    if not ok or type(decoded) ~= "table" then return nil, 0, false end
    local source = decoded.tags or decoded.entries or decoded
    if type(source) ~= "table" then return nil, 0, false end
    local entries, count = {}, 0
    for rawKey, rawEntry in pairs(source) do
        local key = normTagKey(rawKey)
        local entry = cleanTagEntry(rawEntry)
        if key ~= "" and entry then
            entries[key] = entry
            count = count + 1
        end
    end
    return entries, count, true
end

local function parseLegacyTagRows(src)
    local entries = {}
    local count = 0
    for raw in tostring(src):gmatch("[^\r\n]+") do
        local line = trim(raw)
        if line ~= "" and line:sub(1,1) ~= "#" and line:sub(1,2) ~= "//" then
            local parts = {}
            for seg in (line .. "|"):gmatch("([^|]*)|") do parts[#parts+1] = trim(seg) end
            local user = parts[1]
            if user and user ~= "" then
                local entry = {}
                if parts[2] and parts[2] ~= "" then entry.displayName = parts[2] end
                if parts[3] and parts[3] ~= "" then entry.color = parts[3] end
                -- Old effect/special fields are intentionally ignored so they
                -- cannot render square translucent layers behind the tag pill.
                if parts[5] and parts[5] ~= "" then entry.icon = parts[5] end
                if parts[6] and parts[6] ~= "" then
                    local tags = {}
                    for t in (parts[6] .. ","):gmatch("([^,]*),") do
                        t = trim(t); if t ~= "" then tags[#tags+1] = t end
                    end
                    if #tags > 0 then entry.tags = tags end
                end
                if parts[7] and parts[7] ~= "" then entry.textFx = parts[7] end
                if parts[8] and parts[8] ~= "" then entry.customText = parts[8] end
                if parts[9] and parts[9] ~= "" then entry.customHandle = parts[9] end
                if parts[10] and parts[10] ~= "" then entry.outline = parts[10] end
                if parts[11] and parts[11] ~= "" then entry.font = parts[11] end
                -- parts[12] used to be sweep; ignored.
                if parts[13] and parts[13] ~= "" then entry.textColor = parts[13] end
                if parts[14] and parts[14] ~= "" then entry.textOutline = parts[14] end
                if parts[15] and parts[15] ~= "" then entry.avatarOutline = parts[15] end
                if parts[16] and parts[16] ~= "" then entry.showChip = parts[16] end
                -- parts[17] used to be tag aura; ignored so colors/images always paint the pill.
                entries[normTagKey(user)] = cleanTagEntry(entry)
                count = count + 1
            end
        end
    end
    return entries, count
end

local function parsePastebin(src)
    local jsonEntries, jsonCount, isJson = parseTagsJson(src)
    local legacyEntries, legacyCount = parseLegacyTagRows(src)
    if isJson then
        -- A known bad state was: old pipe rows + an empty v2 JSON object. That
        -- made every saved tag lose its cfg and fall back to the default blue
        -- accent. Recover the legacy rows only when the JSON has no entries.
        if jsonCount == 0 and legacyCount > 0 then
            return legacyEntries, legacyCount, false
        end
        return jsonEntries, jsonCount, true
    end
    return legacyEntries, legacyCount, false
end

local function stripTagSpecials(entry)
    if type(entry) ~= "table" then return entry end
    entry.effect = nil
    -- textFx (typewriter/glitch/rainbow) is kept; it doesn't render a box.
    entry.sweep = nil
    entry.element = nil
    entry.special = nil
    entry.aura = nil
    -- Tag auras are disabled for now because they hide the normal pill fill.
    return entry
end

-- Local persistence: any tag the owner saves/deletes in the in-game panel is
-- written to disk so it survives rejoin even if the pastebin doesn't have it.
-- Local overrides take priority over the pastebin entry for the same username.
--
-- IMPORTANT: scope the file per-LocalPlayer UserId so tags saved while user A
-- is logged in do NOT leak into user B's session on the same machine. Older
-- script versions used a single shared file ("seige_tags_overrides.json")
-- which caused exactly that bleed-over (e.g. "displayName (username)" stub
-- entries from another user showing up after fresh injection).
local TAGS_LOCAL_FILE = ("seige_tags_overrides_%d.json"):format(LP and LP.UserId or 0)
-- One-time cleanup: nuke the legacy shared file + any stale per-user files
-- from the v2 era so every fresh injection starts from a known clean slate.
-- Gated by a per-user marker so we only do this once per executor install.
do
    local isfile   = rawget(getfenv(), "isfile")
    local writefile = rawget(getfenv(), "writefile")
    local delfile  = rawget(getfenv(), "delfile")
    local WIPE_MARKER = ("seige_tags_wiped_v3_%d"):format(LP and LP.UserId or 0)
    if isfile and writefile then
        local okMark, hasMark = pcall(isfile, WIPE_MARKER)
        if not (okMark and hasMark) then
            -- nuke the legacy shared file (pre-per-user scoping)
            local LEGACY = "seige_tags_overrides.json"
            local okL, hasL = pcall(isfile, LEGACY)
            if okL and hasL then
                if delfile then pcall(delfile, LEGACY)
                else pcall(writefile, LEGACY, "{}") end
            end
            -- nuke this user's own override file too, so injection = clean slate
            local okExists, exists = pcall(isfile, TAGS_LOCAL_FILE)
            if okExists and exists then
                if delfile then pcall(delfile, TAGS_LOCAL_FILE)
                else pcall(writefile, TAGS_LOCAL_FILE, "{}") end
            end
            pcall(writefile, WIPE_MARKER, tostring(os.time()))
            print("[Tags] cleared local tag overrides (v3 per-user wipe)")
        end
    end
end

function TagDB:saveLocal()
    local writefile = rawget(getfenv(), "writefile")
    if not writefile then return false, "writefile not available" end
    local ok, encoded = pcall(function() return HttpService:JSONEncode(self.localEntries or {}) end)
    if not ok then return false, tostring(encoded) end
    local wok, werr = pcall(writefile, TAGS_LOCAL_FILE, encoded)
    if not wok then return false, tostring(werr) end
    return true
end
function TagDB:loadLocal()
    local isfile   = rawget(getfenv(), "isfile")
    local readfile = rawget(getfenv(), "readfile")
    if not (isfile and readfile) then return nil end
    local okExists, exists = pcall(isfile, TAGS_LOCAL_FILE)
    if not (okExists and exists) then return nil end
    local okRead, raw = pcall(readfile, TAGS_LOCAL_FILE)
    if not okRead or type(raw) ~= "string" or raw == "" then return nil end
    local okDec, data = pcall(function() return HttpService:JSONDecode(raw) end)
    if not okDec or type(data) ~= "table" then return nil end
    local out = {}
    for k, v in pairs(data) do
        if type(v) == "table" then out[tostring(k):lower()] = stripTagSpecials(v) end
    end
    return out
end
function TagDB:mergeLocal()
    -- GitHub is now the single source of truth. Old executor-local override
    -- files are intentionally ignored because they were the exact reason a tag
    -- could look saved, then reload back to stale colors/fills/images.
    self.localEntries = self.localEntries or {}
    return 0
end



-- On-disk cache of the parsed tag DB so a fresh inject can show the saved
-- tag INSTANTLY instead of staring at "no tag" until the Pastebin/GitHub
-- HTTP fetch resolves. We still refresh from the network in the background
-- and replace `self.entries` once it lands.
do
    local TAGS_DB_CACHE_FILE = "seige_tags_db_cache.json"
    function TagDB:_cacheWrite(entries)
        local wf = rawget(getfenv(), "writefile")
        if not wf or type(entries) ~= "table" then return end
        local ok, raw = pcall(function() return HttpService:JSONEncode(entries) end)
        if ok and raw then pcall(wf, TAGS_DB_CACHE_FILE, raw) end
    end
    function TagDB:_cacheRead()
        local rf  = rawget(getfenv(), "readfile")
        local isf = rawget(getfenv(), "isfile")
        if not (rf and isf) then return nil end
        local okE, exists = pcall(isf, TAGS_DB_CACHE_FILE); if not (okE and exists) then return nil end
        local okR, raw = pcall(rf, TAGS_DB_CACHE_FILE); if not (okR and type(raw) == "string" and raw ~= "") then return nil end
        local okD, data = pcall(function() return HttpService:JSONDecode(raw) end)
        if okD and type(data) == "table" then return data end
        return nil
    end
end

function TagDB:hydrateFromCache()
    if self.entries and next(self.entries) then return false end
    local cached = self:_cacheRead()
    if cached and next(cached) then
        self.entries = cached
        local n = 0; for _ in pairs(cached) do n = n + 1 end
        print(("[Tags] hydrated %d entries from local cache (instant)"):format(n))
        return true
    end
    return false
end

function TagDB:load()
    -- Hydrate from local cache first so the saved tag appears immediately
    -- even before the network fetch resolves.
    self:hydrateFromCache()

    -- Try Pastebin source first (easy-edit text format)
    if TAGS_PASTEBIN_URL ~= "" then
        local src
        pcall(function()
            src = game:HttpGet(TAGS_PASTEBIN_URL .. (TAGS_PASTEBIN_URL:find("?") and "&" or "?") .. "v=" .. tostring(os.time()))
        end)
        if src and src ~= "" then
            local entries, count, isJson = parsePastebin(src)
            if isJson or count > 0 then
                self.entries = entries
                self:_cacheWrite(entries)
                print(("[Tags] GitHub tag DB loaded — %d entries"):format(count))
                return
            end
        end
        warn("[Tags] Pastebin source empty/unreachable, falling back to GitHub tags.lua")
    end
    -- Fallback: legacy Lua table at tags.lua
    local src
    pcall(function()
        src = game:HttpGet(TAGS_DB_URL .. "?v=" .. tostring(os.time()))
    end)
    if not src then
        warn("[Tags] DB fetch failed — using empty tag DB")
        if not (self.entries and next(self.entries)) then self.entries = {} end
        return
    end
    local fn, err = loadstring(src)
    if not fn then warn("[Tags] compile: " .. tostring(err)); if not (self.entries and next(self.entries)) then self.entries = {} end; return end
    local ok, data = pcall(fn)
    if not ok or type(data) ~= "table" then
        warn("[Tags] eval failed: " .. tostring(data)); if not (self.entries and next(self.entries)) then self.entries = {} end; return
    end
    local entries = {}
    for k, v in pairs(data) do
        local key = normTagKey(k)
        local clean = cleanTagEntry(v)
        if key ~= "" and clean then entries[key] = clean end
    end
    self.entries = entries
    self:_cacheWrite(entries)
    print(("[Tags] GitHub DB loaded — %d entries"):format((function() local n=0; for _ in pairs(entries) do n=n+1 end; return n end)()))
end



local function tagColor(p)
    if Tags:has(p.UserId, "Target") then return T.bad end
    if Tags:has(p.UserId, "Friend") then return T.good end
    if Tags:has(p.UserId, "Priority") then return T.warn end
    if Tags:has(p.UserId, "Ignore") then return T.dim end
    return T.silverHi or T.text
end

------------------------------------------------------- TABS
local pgProfile = makeTab("Profile", "◈", "Your account, recent games and friends")
local pgPlayers = makeTab("Players", "◉", "Server roster and player tools")
local pgCmds    = makeTab("Cmds",    "⌘", "Quick commands, executor and rejoin")
local pgShaders = makeTab("Shaders", "☀", "Real post-processing: bloom, blur, DOF, color")
local pgSpotify = makeTab("Spotify", "♫", "Connect your token and control playback")
local pgConfig  = makeTab("Config",  "⚙", "Settings and keybinds")
-- Skybox settings live under the Config tab.
local pgMisc    = makeTab("Misc",    "⋯", "Other tools and experimental features")
-- Aliases — content for these older tabs now lives inside the Misc tab.
local pgWorld   = pgMisc
local pgThemes  = pgConfig  -- Themes/colors live under the Settings (Config) tab
local pgDetect  = pgMisc

------------------------------------------------------- PARTICLE FX (per-page)
_G.__SeigeFx = _G.__SeigeFx or { Profile = true, Players = false, Cmds = false, Shaders = false, Spotify = false, Misc = false }
local _PAGE_FX_COLORS = {
    Color3.fromRGB(255, 240, 180),
    Color3.fromRGB(180, 210, 255),
    Color3.fromRGB(220, 170, 255),
    Color3.fromRGB(170, 255, 220),
}
local function attachPageParticles(page, key)
    if not page then return end
    local fx = inst("Frame", page, {
        Size = UDim2.new(1, 0, 0, 120),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        ZIndex = 2,
    })
    local function spark()
        local col = _PAGE_FX_COLORS[math.random(1, #_PAGE_FX_COLORS)]
        local f = inst("Frame", fx, {
            Size = UDim2.new(0, 2, 0, 2),
            Position = UDim2.new(math.random(), 0, math.random(), 0),
            BackgroundColor3 = col, BorderSizePixel = 0, ZIndex = 3,
        })
        corner(f, 1)
        TweenService:Create(f, TweenInfo.new(0.9, Enum.EasingStyle.Quad),
            { Size = UDim2.new(0, 7, 0, 7), BackgroundTransparency = 1 }):Play()
        task.delay(1, function() if f then f:Destroy() end end)
    end
    task.spawn(function()
        while fx and fx.Parent do
            if _G.__SeigeFx[key] then
                pcall(function()
                    if math.random() < 0.5 then spark() end
                end)
            end
            task.wait(0.14)
        end
    end)
    return fx
end
attachPageParticles(pgPlayers, "Players")
attachPageParticles(pgCmds,    "Cmds")
attachPageParticles(pgShaders, "Shaders")
attachPageParticles(pgSpotify, "Spotify")
attachPageParticles(pgMisc,    "Misc")


------------------------------------------------------- HELPERS
local function char()  return LP.Character end
local function hum()   local c = char(); return c and c:FindFirstChildOfClass("Humanoid") end
local function hrp()   local c = char(); return c and c:FindFirstChild("HumanoidRootPart") end
local function pchar(p) return p and p.Character end
local function phrp(p)  local c = pchar(p); return c and c:FindFirstChild("HumanoidRootPart") end

local function applyInvisState(on)
    local c = LP.Character
    if not c then return end
    _G.__InvisOn = on
    for _, d in ipairs(c:GetDescendants()) do
        if d:IsA("BasePart") then
            pcall(function() d.LocalTransparencyModifier = on and 1 or 0 end)
        elseif d:IsA("Decal") or d:IsA("Texture") then
            pcall(function() d.Transparency = on and 1 or 0 end)
        end
    end
end
bind(LP.CharacterAdded:Connect(function(c)
    task.wait(0.3)
    if _G.__InvisOn then applyInvisState(true) end
end))


local selected
local refreshPlayerList -- forward

------------------------------------------------------- PLAYERS TAB
section(pgPlayers, "Player list")
local searchBox = textbox(pgPlayers, "Search players…", function(q) refreshPlayerList(q) end)
local selLbl = label(pgPlayers, "No player selected")

local listFrame = inst("Frame", pgPlayers, {
    Size = UDim2.new(1, -8, 0, 180),
    BackgroundColor3 = T.bg2,
    BackgroundTransparency = 0.3,
    BorderSizePixel = 0,
})
corner(listFrame, 8); stroke(listFrame, T.line, 1, 0.5)
local listScroll = inst("ScrollingFrame", listFrame, {
    Size = UDim2.new(1, -4, 1, -4),
    Position = UDim2.new(0, 2, 0, 2),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = T.acc,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
})
inst("UIListLayout", listScroll, { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.Name })

function refreshPlayerList(filter)
    for _, c in ipairs(listScroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    filter = filter and filter:lower() or nil
    for _, p in ipairs(Players:GetPlayers()) do
        if not filter or p.Name:lower():find(filter, 1, true) or p.DisplayName:lower():find(filter, 1, true) then
            local row = inst("TextButton", listScroll, {
                Size = UDim2.new(1, -4, 0, 40),
                BackgroundColor3 = T.bg3,
                BackgroundTransparency = 0.4,
                AutoButtonColor = false,
                Text = "",
            })
            corner(row, 6)
            local av = inst("ImageLabel", row, {
                Size = UDim2.new(0, 30, 0, 30),
                Position = UDim2.new(0, 5, 0.5, -15),
                BackgroundColor3 = T.bg2,
                BorderSizePixel = 0,
                ScaleType = Enum.ScaleType.Crop,
            })
            corner(av, 15)
            pcall(function()
                av.Image = Players:GetUserThumbnailAsync(p.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
            end)
            inst("TextLabel", row, {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 42, 0, 2),
                Size = UDim2.new(1, -50, 0, 18),
                Font = Enum.Font.GothamBold,
                TextSize = 12,
                TextColor3 = T.text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = p.DisplayName,
            })
            local tagStr = Tags:summary(p.UserId)
            inst("TextLabel", row, {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 42, 0, 20),
                Size = UDim2.new(1, -50, 0, 14),
                Font = Enum.Font.Gotham,
                TextSize = 10,
                TextColor3 = tagStr ~= "" and tagColor(p) or T.sub,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = "@" .. p.Name .. (tagStr ~= "" and "  ·  " .. tagStr or ""),
            })
            row.MouseEnter:Connect(function() tween(row, 0.1, {BackgroundTransparency = 0.2}) end)
            row.MouseLeave:Connect(function() tween(row, 0.1, {BackgroundTransparency = 0.4}) end)
            row.MouseButton1Click:Connect(function()
                selected = p
                selLbl:set("Selected: " .. p.DisplayName .. "  (@" .. p.Name .. ")")
                notify("Selected " .. p.Name, "good")
            end)
        end
    end
end
bind(Players.PlayerAdded:Connect(function() refreshPlayerList() end))
bind(Players.PlayerRemoving:Connect(function(p) if selected == p then selected = nil; selLbl:set("No player selected") end; refreshPlayerList() end))
refreshPlayerList()

local function withSel(fn)
    return function()
        if not selected then notify("Select a player first", "warn"); return end
        local ok, err = pcall(fn, selected)
        if not ok then notify(err or "Error", "bad") end
    end
end

section(pgPlayers, "Quick actions")
button(pgPlayers, "Teleport to player", withSel(function(p)
    local h = phrp(p); if h and hrp() then hrp().CFrame = h.CFrame + Vector3.new(0, 3, 0) end
end))
button(pgPlayers, "Bring player to you", withSel(function(p)
    local myH = hrp()
    if not myH then notify("No character", "bad"); return end
    -- Prefer broadcast bring (works if target is running the script).
    if _G.__SeigeBringSend then
        local ok, err = pcall(_G.__SeigeBringSend, p.Name)
        if ok then
            notify("Bringing " .. p.Name .. " (broadcast)", "good")
        else
            notify("Broadcast failed: " .. tostring(err), "warn")
        end
    end
    -- Local CFrame attempt as a fallback / extra path. Works only when the
    -- experience leaves the player network-owned (no FE protection on humanoid).
    task.spawn(function()
        local thrp = phrp(p)
        if not thrp then return end
        for i = 1, 30 do
            if not phrp(p) or not hrp() then break end
            pcall(function() phrp(p).CFrame = hrp().CFrame + Vector3.new(0, 3, 0) end)
            task.wait(0.05)
        end
        -- tool-grab fallback (FE bring via firetouchinterest)
        local tool = LP.Backpack:FindFirstChildOfClass("Tool")
            or (LP.Character and LP.Character:FindFirstChildOfClass("Tool"))
        if tool and tool:FindFirstChild("Handle") and typeof(firetouchinterest) == "function" then
            pcall(function()
                tool.Parent = LP.Character
                local saved = myH.CFrame
                for i = 1, 25 do
                    local t = phrp(p); if not t then break end
                    myH.CFrame = t.CFrame
                    pcall(function() firetouchinterest(tool.Handle, t, 0) end)
                    task.wait()
                    pcall(function() firetouchinterest(tool.Handle, t, 1) end)
                    task.wait(0.05)
                end
                pcall(function() myH.CFrame = saved end)
            end)
        end
    end)
end))

-- Persistent spectate: re-binds camera subject whenever the target respawns
-- and pumps the camera each Heartbeat so it never silently reverts after the
-- first use.
local spectatingPlr
local spectateConns = {}
local function _stopSpectate()
    for _, c in ipairs(spectateConns) do pcall(function() c:Disconnect() end) end
    spectateConns = {}
    spectatingPlr = nil
    pcall(function() cam.CameraSubject = hum() end)
end
local function _startSpectate(p)
    _stopSpectate()
    spectatingPlr = p
    local function bind()
        local ch = p.Character or p.CharacterAdded:Wait()
        local h = ch and ch:FindFirstChildOfClass("Humanoid")
        if h then pcall(function() cam.CameraSubject = h end) end
    end
    bind()
    table.insert(spectateConns, p.CharacterAdded:Connect(function()
        task.wait(0.3); if spectatingPlr == p then bind() end
    end))
    -- guard: if the engine resets camera to LP, snap it back
    table.insert(spectateConns, RunService.RenderStepped:Connect(function()
        if spectatingPlr ~= p then return end
        local ch = p.Character
        local h = ch and ch:FindFirstChildOfClass("Humanoid")
        if h and cam.CameraSubject ~= h then
            pcall(function() cam.CameraSubject = h end)
        end
    end))
    -- if the target leaves, drop spectate
    table.insert(spectateConns, Players.PlayerRemoving:Connect(function(left)
        if left == p then _stopSpectate(); notify("Spectated player left", "warn") end
    end))
end
button(pgPlayers, "Spectate / unspectate", withSel(function(p)
    if spectatingPlr == p then
        _stopSpectate(); notify("Stopped spectating", "good")
    else
        _startSpectate(p); notify("Spectating " .. p.Name, "good")
    end
end))
_G.__SeigeStartSpectate = _startSpectate
_G.__SeigeStopSpectate  = _stopSpectate


button(pgPlayers, "Copy username", withSel(function(p)
    if setclipboard then setclipboard(p.Name); notify("Copied @" .. p.Name, "good") else notify("No clipboard access", "warn") end
end))
button(pgPlayers, "Refresh list", function() refreshPlayerList() end)

------------------------------------------------------- SELF STATE (UI lives in Cmds tab popouts)
-- The Self tab was removed; these state variables and bound handlers stay so
-- the Cmds popouts (Movement, Fly, Noclip, Anti-AFK, etc.) can flip them.

-- Walk speed / Jump power are written directly to the humanoid by the
-- popout sliders; no shared state needed here.

local flying, flySpeed = false, 50
local flyBV, flyBG
local flyKeys = { fwd=false, back=false, left=false, right=false, up=false, down=false }
local function killFly()
    flying = false
    if flyBV then flyBV:Destroy(); flyBV = nil end
    if flyBG then flyBG:Destroy(); flyBG = nil end
end
local function startFly()
    local h = hrp(); if not h then return end
    killFly()
    flying = true
    flyBV = Instance.new("BodyVelocity", h)
    flyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    flyBV.Velocity = Vector3.zero
    flyBG = Instance.new("BodyGyro", h)
    flyBG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    flyBG.P = 1e4
    flyBG.CFrame = h.CFrame
end

local noclip = false
bind(RunService.Stepped:Connect(function()
    if noclip then
        local c = char(); if c then for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
        end end
    end
    if flying and flyBV and flyBG and hrp() then
        local h = hrp()
        local cf = cam.CFrame
        local dir = Vector3.zero
        if flyKeys.fwd   then dir = dir + cf.LookVector end
        if flyKeys.back  then dir = dir - cf.LookVector end
        if flyKeys.right then dir = dir + cf.RightVector end
        if flyKeys.left  then dir = dir - cf.RightVector end
        if flyKeys.up    then dir = dir + Vector3.new(0, 1, 0) end
        if flyKeys.down  then dir = dir + Vector3.new(0, -1, 0) end
        flyBV.Velocity = dir.Magnitude > 0 and dir.Unit * flySpeed or Vector3.zero
        flyBG.CFrame = cf
    end
end))

local infJump = false
bind(UIS.JumpRequest:Connect(function() if infJump then local h = hum(); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end end))

local clickTp = false
_G.__ClickTpKey = _G.__ClickTpKey or Enum.KeyCode.LeftShift
bind(UIS.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.UserInputType == Enum.UserInputType.MouseButton1 and clickTp and UIS:IsKeyDown(_G.__ClickTpKey) then
        if mouse.Hit and hrp() then hrp().CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0)) end
    end
end))

local antiAfk = false
bind(LP.Idled:Connect(function()
    if antiAfk then
        local vu = game:GetService("VirtualUser")
        vu:CaptureController()
        vu:ClickButton2(Vector2.new())
    end
end))


------------------------------------------------------- VISUALS TAB
-- (ESP removed)
local function shouldTarget(p)
    if p == LP then return false end
    if Tags:has(p.UserId, "Ignore") then return false end
    return true
end


section(pgShaders, "Camera & Lighting")
slider(pgShaders, "Field of view", 30, 120, 70, function(v) cam.FieldOfView = v end)
toggle(pgShaders, "Fullbright", false, function(s)
    if s then
        Lighting.Brightness = 3; Lighting.ClockTime = 14; Lighting.FogEnd = 1e6
        Lighting.GlobalShadows = false; Lighting.Ambient = Color3.new(1,1,1)
    else
        Lighting.Brightness = 1; Lighting.GlobalShadows = true; Lighting.Ambient = Color3.fromRGB(70,70,70)
    end
end)

------------------------------------------------------- WORLD TAB
section(pgWorld, "Environment")
slider(pgWorld, "Time of day", 0, 24, 14, function(v) Lighting.ClockTime = v end)
slider(pgWorld, "Gravity", 0, 400, workspace.Gravity, function(v) workspace.Gravity = v end)
dropdown(pgWorld, "Time preset", { "Noon", "Sunset", "Night", "Dawn" }, function(o)
    Lighting.ClockTime = ({ Noon = 12, Sunset = 18, Night = 0, Dawn = 6 })[o]
end)

------------------------------------------------------- FLOATING TAGS (driven by tags.lua DB)
local floatOn = false
local scriptersOn = false        -- show tags for nearby seige.lol users
_G.__SeigeScripters = _G.__SeigeScripters or {} -- [userId] = true
local function isScripter(p)
    if not p then return false end
    if p == LP then return true end
    return _G.__SeigeScripters[p.UserId] == true
end
local tagBills = {}

-- Stash original Humanoid display settings so we can restore them when a bubble goes away
local NameHider = {}
do
    local origNameDisp = setmetatable({}, { __mode = "k" })
    function NameHider.hide(p)
        local ch = pchar(p); if not ch then return end
        local h = ch:FindFirstChildOfClass("Humanoid"); if not h then return end
        if origNameDisp[h] == nil then
            origNameDisp[h] = {
                ddt  = h.DisplayDistanceType,
                name = h.NameDisplayDistance,
                hp   = h.HealthDisplayDistance,
            }
        end
        pcall(function()
            h.DisplayDistanceType   = Enum.HumanoidDisplayDistanceType.None
            h.NameDisplayDistance   = 0
            h.HealthDisplayDistance = 0
        end)
    end
    function NameHider.restore(p)
        local ch = pchar(p); if not ch then return end
        local h = ch:FindFirstChildOfClass("Humanoid"); if not h then return end
        local o = origNameDisp[h]; if not o then return end
        pcall(function()
            h.DisplayDistanceType   = o.ddt
            h.NameDisplayDistance   = o.name
            h.HealthDisplayDistance = o.hp
        end)
        origNameDisp[h] = nil
    end
end

local function clearBills()
    for p, e in pairs(tagBills) do
        if e.auraStop then pcall(e.auraStop) end
        if e.gui then e.gui:Destroy() end
        if e.clickDetector then pcall(function() e.clickDetector:Destroy() end) end
        pcall(NameHider.restore, p)
    end
    tagBills = {}
end

-- ───────────────────────────────────────────────────────────────────────────
-- AURAS  ·  animated outline effects that replace the static tag stroke.
-- Pure UIStroke + glow-frame, no images, so they fit the auto-sized pill.
-- Each aura constructor returns a `stop()` cleanup function.
-- ───────────────────────────────────────────────────────────────────────────
local Auras = {}
do
    local TweenService = game:GetService("TweenService")

    local function glow(pill, c3, trans, pad, zOff)
        -- Aura glow sits exactly on the pill footprint (no padding expansion)
        -- so the aura's outer edge matches the pill outline. `pad` is kept in
        -- the signature for call-site compatibility but no longer enlarges
        -- the frame. Corner radius stays at 23 to match the pill's UICorner.
        local f = Instance.new("Frame")
        f.Name = "_AuraGlow"
        f.AnchorPoint = Vector2.new(0.5, 0.5)
        f.Position    = UDim2.new(0.5, 0, 0.5, 0)
        f.Size        = UDim2.new(1, 0, 1, 0)
        f.BackgroundColor3 = c3
        f.BackgroundTransparency = trans
        f.BorderSizePixel = 0
        f.ZIndex = (pill.ZIndex or 1) + (zOff or -1)
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 23); c.Parent = f
        f.Parent = pill.Parent
        return f
    end
    local function strokeOn(pill, c3, thick)
        local s = Instance.new("UIStroke")
        s.Name = "_AuraStroke"
        s.Color = c3
        s.Thickness = thick
        s.Transparency = 0
        s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        s.LineJoinMode = Enum.LineJoinMode.Round
        s.Parent = pill
        return s
    end
    local function cleanup(insts, conns, beats)
        return function()
            for _, c in ipairs(conns or {}) do pcall(function() c:Disconnect() end) end
            for _, i in ipairs(insts or {}) do pcall(function() if i then i:Destroy() end end) end
            if beats then beats.alive = false end
        end
    end
    local function pingPong(obj, dur, props)
        local t = TweenInfo.new(dur, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
        TweenService:Create(obj, t, props):Play()
    end

    function Auras.Ember(pill)
        local g2 = glow(pill, Color3.fromRGB(255, 85, 0),  0.82, 8, -2)
        local g1 = glow(pill, Color3.fromRGB(255, 140, 0), 0.70, 3, -1)
        local s  = strokeOn(pill, Color3.fromRGB(255, 120, 0), 2)
        pingPong(s,  0.9, { Color = Color3.fromRGB(255, 200, 0), Thickness = 3.5 })
        pingPong(g1, 0.9, { BackgroundTransparency = 0.55 })
        pingPong(g2, 0.9, { BackgroundTransparency = 0.72 })
        return cleanup({g1, g2, s})
    end
    function Auras.Frost(pill)
        local g1 = glow(pill, Color3.fromRGB(0, 212, 255), 0.80, 6, -1)
        local s  = strokeOn(pill, Color3.fromRGB(0, 212, 255), 1.2)
        pingPong(s,  1.2, { Color = Color3.fromRGB(184, 240, 255), Thickness = 2.4 })
        pingPong(g1, 1.2, { BackgroundTransparency = 0.65 })
        return cleanup({g1, s})
    end
    function Auras.Lightning(pill)
        local g1 = glow(pill, Color3.fromRGB(255, 225, 0), 0.78, 5, -1)
        local s  = strokeOn(pill, Color3.fromRGB(255, 230, 0), 1.5)
        local t, conns = 0, {}
        local conn; conn = RunService.Heartbeat:Connect(function(dt)
            if not pill or not pill.Parent then conn:Disconnect() return end
            t = t + dt
            local v = math.abs(math.sin(t * 18) * math.sin(t * 11.3))
            s.Thickness = 1.2 + v * 4.0
            s.Color = Color3.new(1, 0.88 + v * 0.12, v * 0.3)
            g1.BackgroundTransparency = 0.65 + (1 - v) * 0.22
        end)
        conns[#conns+1] = conn
        return cleanup({g1, s}, conns)
    end
    function Auras.Void(pill)
        local g3 = glow(pill, Color3.fromRGB(80, 0, 180),   0.88, 18, -3)
        local g2 = glow(pill, Color3.fromRGB(120, 40, 220), 0.78, 8,  -2)
        local g1 = glow(pill, Color3.fromRGB(150, 60, 255), 0.68, 3,  -1)
        local s  = strokeOn(pill, Color3.fromRGB(136, 0, 255), 2.2)
        pingPong(s,  1.5, { Color = Color3.fromRGB(200, 100, 255), Thickness = 4.0 })
        pingPong(g1, 1.5, { BackgroundTransparency = 0.52 })
        pingPong(g2, 1.5, { BackgroundTransparency = 0.65 })
        pingPong(g3, 1.5, { BackgroundTransparency = 0.78 })
        return cleanup({g1, g2, g3, s})
    end
    function Auras.Aurora(pill)
        local g1 = glow(pill, Color3.fromRGB(255, 0, 0), 0.72, 6, -1)
        local s  = strokeOn(pill, Color3.fromRGB(255, 0, 0), 2.5)
        local t, conns = 0, {}
        local conn; conn = RunService.Heartbeat:Connect(function(dt)
            if not pill or not pill.Parent then conn:Disconnect() return end
            t = t + dt
            local h = (t * 0.5) % 1
            local col = Color3.fromHSV(h, 1, 1)
            s.Color = col
            g1.BackgroundColor3 = col
            g1.BackgroundTransparency = 0.68 + math.sin(t * math.pi) * 0.08
        end)
        conns[#conns+1] = conn
        return cleanup({g1, s}, conns)
    end
    function Auras.Crimson(pill)
        local g1 = glow(pill, Color3.fromRGB(200, 0, 50), 0.75, 5, -1)
        local s  = strokeOn(pill, Color3.fromRGB(255, 0, 51), 1.5)
        local beats = { alive = true }
        local function beat()
            if not beats.alive or not s.Parent then return end
            local fast = TweenInfo.new(0.08, Enum.EasingStyle.Linear)
            local slow = TweenInfo.new(0.12, Enum.EasingStyle.Linear)
            local s1 = TweenService:Create(s, fast, { Thickness = 4.5 })
            local s2 = TweenService:Create(s, slow, { Thickness = 1.5 })
            local s3 = TweenService:Create(s, fast, { Thickness = 4.2 })
            local s4 = TweenService:Create(s, slow, { Thickness = 1.5 })
            s1.Completed:Connect(function() if beats.alive then s2:Play() end end)
            s2.Completed:Connect(function() if beats.alive then task.delay(0.08, function() if beats.alive then s3:Play() end end) end end)
            s3.Completed:Connect(function() if beats.alive then s4:Play() end end)
            s4.Completed:Connect(function() if beats.alive then task.delay(0.48, beat) end end)
            s1:Play()
        end
        beat()
        return cleanup({g1, s}, nil, beats)
    end
    function Auras.Royal(pill)
        local g2 = glow(pill, Color3.fromRGB(180, 130, 0), 0.82, 8, -2)
        local g1 = glow(pill, Color3.fromRGB(255, 215, 0), 0.68, 2, -1)
        local s  = strokeOn(pill, Color3.fromRGB(255, 215, 0), 2.0)
        pingPong(s,  1.1, { Color = Color3.fromRGB(255, 250, 160), Thickness = 3.8 })
        pingPong(g1, 1.1, { BackgroundTransparency = 0.52 })
        pingPong(g2, 1.1, { BackgroundTransparency = 0.70 })
        return cleanup({g1, g2, s})
    end
    function Auras.Toxic(pill)
        local g1 = glow(pill, Color3.fromRGB(40, 255, 14), 0.75, 5, -1)
        local s  = strokeOn(pill, Color3.fromRGB(57, 255, 20), 2.0)
        local t, conns = 0, {}
        local conn; conn = RunService.Heartbeat:Connect(function(dt)
            if not pill or not pill.Parent then conn:Disconnect() return end
            t = t + dt
            local v = math.abs(math.sin(t * 14.7) * 0.6 + math.sin(t * 7.3) * 0.4)
            s.Thickness = 1.2 + v * 3.5
            s.Transparency = math.clamp(0.05 + (1 - v) * 0.45, 0, 0.9)
            g1.BackgroundTransparency = 0.62 + (1 - v) * 0.25
        end)
        conns[#conns+1] = conn
        return cleanup({g1, s}, conns)
    end
    function Auras.Phantom(pill)
        local g2 = glow(pill, Color3.fromRGB(210, 210, 255), 0.92, 12, -2)
        local g1 = glow(pill, Color3.fromRGB(220, 220, 255), 0.82, 4,  -1)
        local s  = strokeOn(pill, Color3.fromRGB(232, 232, 255), 1.2)
        s.Transparency = 1
        local beats = { alive = true }
        local function cycle()
            if not beats.alive or not s.Parent then return end
            local fadeIn  = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            local fadeOut = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            local t1 = TweenService:Create(s,  fadeIn,  { Transparency = 0.22 })
            local t2 = TweenService:Create(s,  fadeOut, { Transparency = 1.0 })
            local g1a = TweenService:Create(g1, fadeIn,  { BackgroundTransparency = 0.60 })
            local g1b = TweenService:Create(g1, fadeOut, { BackgroundTransparency = 0.90 })
            t1.Completed:Connect(function()
                if not beats.alive then return end
                task.delay(0.7, function()
                    if not beats.alive then return end
                    t2:Play(); g1b:Play()
                    t2.Completed:Connect(function()
                        if beats.alive then task.delay(0.6, cycle) end
                    end)
                end)
            end)
            t1:Play(); g1a:Play()
        end
        cycle()
        return cleanup({g1, g2, s}, nil, beats)
    end
    function Auras.Solar(pill)
        local g3 = glow(pill, Color3.fromRGB(255, 255, 200), 0.90, 16, -3)
        local g2 = glow(pill, Color3.fromRGB(255, 255, 140), 0.82, 7,  -2)
        local g1 = glow(pill, Color3.fromRGB(255, 255, 100), 0.70, 2,  -1)
        local s  = strokeOn(pill, Color3.fromRGB(255, 255, 255), 2.0)
        local beats = { alive = true }
        local function flash()
            if not beats.alive or not s.Parent then return end
            local spike = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            local decay = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            local t1 = TweenService:Create(s, spike, { Thickness = 8.0, Color = Color3.fromRGB(255, 255, 200) })
            local t2 = TweenService:Create(s, decay, { Thickness = 2.0, Color = Color3.fromRGB(255, 255, 255) })
            local g1a = TweenService:Create(g1, spike, { BackgroundTransparency = 0.42 })
            local g1b = TweenService:Create(g1, decay, { BackgroundTransparency = 0.70 })
            local g2a = TweenService:Create(g2, spike, { BackgroundTransparency = 0.55 })
            local g2b = TweenService:Create(g2, decay, { BackgroundTransparency = 0.82 })
            t1.Completed:Connect(function() if beats.alive then t2:Play(); g1b:Play(); g2b:Play() end end)
            t2.Completed:Connect(function() if beats.alive then task.delay(0.55, flash) end end)
            t1:Play(); g1a:Play(); g2a:Play()
        end
        flash()
        return cleanup({g1, g2, g3, s}, nil, beats)
    end

    -- canonical names for parsing/displaying; matches dropdown.
    Auras.NAMES = { "Ember", "Frost", "Lightning", "Void", "Aurora", "Crimson", "Royal", "Toxic", "Phantom", "Solar" }
    function Auras.canonical(s)
        s = tostring(s or ""):lower():gsub("^%s+",""):gsub("%s+$","")
        if s == "" or s == "off" or s == "none" or s == "0" or s == "false" then return nil end
        for _, n in ipairs(Auras.NAMES) do if n:lower() == s then return n end end
        return nil
    end
    function Auras.apply(pill, name)
        local fn = Auras[name]
        if not fn then return function() end end
        return fn(pill)
    end
end


local function measureText(text, font, size)
    local ok, v = pcall(function()
        return TextService:GetTextSize(text or "", size, font, Vector2.new(10000, 100))
    end)
    if ok and v then return v.X end
    return #(text or "") * size * 0.55
end

-- Parse a gif/sprite-sheet spec from the icon field.
-- Accepted formats (case-insensitive prefix):
--   "gif:assetId:cols:rows:fps[:sheetSize]"
--   "sprite:assetId:cols:rows:fps[:sheetSize]"   (alias of gif:)
--   assetId may be a raw number OR an rbxassetid:// URL
--   sheetSize defaults to 1024 (most uploaded sheets are 1024x1024).
-- Returns table { id, cols, rows, fps, size, frames, fw, fh } or nil.
local function parseGifSpec(raw)
    if type(raw) ~= "string" then return nil end
    local lower = raw:lower()
    if lower:sub(1, 4) ~= "gif:" and lower:sub(1, 7) ~= "sprite:" then return nil end
    local body = raw:gsub("^[sS][pP][rR][iI][tT][eE]:", ""):gsub("^[gG][iI][fF]:", "")
    -- Allow an rbxassetid:// prefix on the id segment
    body = body:gsub("rbxassetid://", "")
    local id, cols, rows, fps, size = body:match("^(%d+):(%d+):(%d+):(%d+):?(%d*)$")
    if not (id and cols and rows and fps) then return nil end
    cols = tonumber(cols); rows = tonumber(rows); fps = tonumber(fps)
    size = (size ~= "" and tonumber(size)) or 1024
    if cols < 1 or rows < 1 or fps < 1 then return nil end
    return {
        id = id, cols = cols, rows = rows, fps = fps, size = size,
        frames = cols * rows,
        fw = math.floor(size / cols),
        fh = math.floor(size / rows),
    }
end

local function refreshBill(p)
    local e = tagBills[p]; if not e then return end
    local cfg = TagDB:configFor(p)
    e.gui.Enabled = true

    -- Baseline reset every refresh: re-enable stroke and restore opaque bg so
    -- per-entry overrides (outline/fill/textColor/aura) always start from a
    -- known state. The blocks below then apply whatever the config specifies.
    -- Aura teardown happens here too so a removed aura cleanly hands the pill
    -- back to the normal stroke + fill renderers.
    if e.auraStop then
        pcall(e.auraStop); e.auraStop = nil; e.auraName = nil
    end
    if e.stroke then e.stroke.Enabled = true end
    if e.bgGrad then e.bgGrad.Enabled = true end
    if e.bg then e.bg.BackgroundTransparency = 0 end

    -- Default everyone to anonymous "user" unless an admin set an override.
    -- LP always sees their own real identity.
    local function fmtHandle(h)
        h = tostring(h or ""):gsub("^@",""):gsub("^%s+",""):gsub("%s+$","")
        return "@" .. h
    end
    local nameStr   = (cfg and cfg.displayName) or (p == LP and p.DisplayName) or "user"
    local handleStr = (cfg and cfg.customHandle and cfg.customHandle ~= "" and fmtHandle(cfg.customHandle))
                      or (p == LP and ("@" .. p.Name))
                      or "@user"
    e.name.Text   = nameStr
    e.handle.Text = handleStr
    e.baseName    = nameStr

    -- Per-tag font override (set in Tags panel). Falls back to global tag font, then defaults.
    do
        local perTag = cfg and cfg.font
        local globalTag = _G.__SeigeTagFont
        local choice = (perTag and perTag ~= "" and perTag ~= "Default") and perTag
                       or (globalTag and globalTag ~= "Default" and globalTag)
                       or nil
        local font = choice and Enum.Font[choice] or nil
        pcall(function()
            e.name.Font   = font or Enum.Font.GothamBold
            e.handle.Font = font or Enum.Font.Gotham
            if e.stat then e.stat.Font = font or Enum.Font.GothamBold end
        end)
    end

    -- Text effects: animate BOTH the display name and the @handle.
    do
        local fx = cfg and cfg.textFx
        fx = tostring(fx or ""):lower():gsub("^%s+",""):gsub("%s+$","")
        e.fxToken = (e.fxToken or 0) + 1
        local myToken = e.fxToken

        e.nameBasePos   = e.nameBasePos   or e.name.Position
        e.handleBasePos = e.handleBasePos or e.handle.Position
        e.name.Position   = e.nameBasePos
        e.handle.Position = e.handleBasePos

        local targets = {
            { label = e.name,   full = nameStr,   basePos = e.nameBasePos },
            { label = e.handle, full = handleStr, basePos = e.handleBasePos },
        }
        for _, t in ipairs(targets) do t.label.Text = t.full end

        local function alive() return e.fxToken == myToken end

        if fx == "typewriter" or fx == "type" then
            for _, t in ipairs(targets) do
                task.spawn(function()
                    local full = t.full
                    while alive() and t.label and t.label.Parent do
                        for i = 0, #full do
                            if not alive() then return end
                            t.label.Text = string.sub(full, 1, i); task.wait(0.08)
                        end
                        task.wait(1.2)
                        for i = #full, 0, -1 do
                            if not alive() then return end
                            t.label.Text = string.sub(full, 1, i); task.wait(0.05)
                        end
                        task.wait(0.4)
                    end
                end)
            end
        elseif fx == "glitch" then
            local glitchChars = "!@#$%^&*<>?/\\|=+-_"
            for _, t in ipairs(targets) do
                task.spawn(function()
                    local full = t.full
                    while alive() and t.label and t.label.Parent do
                        local out = {}
                        for i = 1, #full do
                            if math.random() < 0.18 then
                                local r = math.random(1, #glitchChars)
                                out[i] = string.sub(glitchChars, r, r)
                            else
                                out[i] = string.sub(full, i, i)
                            end
                        end
                        t.label.Text = table.concat(out); task.wait(0.08)
                    end
                end)
            end
        elseif fx == "rainbow" then
            task.spawn(function()
                local t0 = tick()
                while alive() and e.name and e.name.Parent do
                    local h = (tick() - t0) * 0.4 % 1
                    local c = Color3.fromHSV(h, 0.85, 1)
                    if e.name   then e.name.TextColor3   = c end
                    if e.handle then e.handle.TextColor3 = c end
                    task.wait(0.05)
                end
            end)
        elseif fx == "floating" or fx == "float" then
            for i, t in ipairs(targets) do
                task.spawn(function()
                    local phase = (i - 1) * math.pi * 0.5
                    while alive() and t.label and t.label.Parent do
                        local off = math.sin(tick() * 3 + phase) * 2
                        t.label.Position = t.basePos + UDim2.fromOffset(0, off)
                        task.wait(0.03)
                    end
                end)
            end
        elseif fx == "zerograv" or fx == "zero-grav" or fx == "zerog" then
            for i, t in ipairs(targets) do
                task.spawn(function()
                    task.wait((i - 1) * 0.6)
                    while alive() and t.label and t.label.Parent do
                        for f = 0, 1, 0.05 do
                            if not alive() then return end
                            local ease = f * f
                            t.label.Position = t.basePos + UDim2.fromOffset(0, math.floor(ease * 22))
                            task.wait(0.03)
                        end
                        task.wait(0.4)
                        t.label.Position = t.basePos + UDim2.fromOffset(0, -10)
                        task.wait(0.08)
                        t.label.Position = t.basePos
                        task.wait(0.9)
                    end
                end)
            end
        elseif fx == "wave" then
            for i, t in ipairs(targets) do
                task.spawn(function()
                    local phase = (i - 1) * math.pi
                    while alive() and t.label and t.label.Parent do
                        local off = math.sin(tick() * 4 + phase) * 3
                        t.label.Position = t.basePos + UDim2.fromOffset(off, 0)
                        task.wait(0.03)
                    end
                end)
            end
        elseif fx == "shake" then
            for _, t in ipairs(targets) do
                task.spawn(function()
                    while alive() and t.label and t.label.Parent do
                        local dx = math.random(-2, 2)
                        local dy = math.random(-1, 1)
                        t.label.Position = t.basePos + UDim2.fromOffset(dx, dy)
                        task.wait(0.05)
                    end
                end)
            end
        end
    end



    -- Custom icon override (DB or per-player). Force a refresh by clearing first.
    local customIcon = TagIcons:get(p.UserId) or (cfg and cfg.icon)
    if e.av then
        local gifSpec = parseGifSpec(customIcon)
        if gifSpec then
            -- start (or restart) sprite-sheet animation
            local key = "gif:" .. gifSpec.id .. ":" .. gifSpec.cols .. "x" .. gifSpec.rows .. "@" .. gifSpec.fps .. ":" .. gifSpec.size
            if e.gifKey ~= key then
                e.gifKey = key
                e.gifToken = (e.gifToken or 0) + 1
                local myToken = e.gifToken
                local img = "rbxassetid://" .. gifSpec.id
                pcall(function() e.av.Image = "" end)
                pcall(function() e.av.Image = img end)
                e.av.ImageTransparency = 0
                e.av.ScaleType = Enum.ScaleType.Crop
                e.av.ImageRectSize = Vector2.new(gifSpec.fw, gifSpec.fh)
                task.spawn(function()
                    local frame = 0
                    local delayTime = 1 / gifSpec.fps
                    while e.gifToken == myToken and e.av and e.av.Parent do
                        local col = frame % gifSpec.cols
                        local row = math.floor(frame / gifSpec.cols) % gifSpec.rows
                        e.av.ImageRectOffset = Vector2.new(col * gifSpec.fw, row * gifSpec.fh)
                        frame = (frame + 1) % gifSpec.frames
                        task.wait(delayTime)
                    end
                end)
            end
        else
            -- static image path — cancel any running gif loop and reset rect
            if e.gifKey then
                e.gifKey = nil
                e.gifToken = (e.gifToken or 0) + 1
                e.av.ImageRectOffset = Vector2.new(0, 0)
                e.av.ImageRectSize = Vector2.new(0, 0)
            end
            local target
            if customIcon then
                target = resolveIconUrl(customIcon)
            else
                pcall(function()
                    target = Players:GetUserThumbnailAsync(p.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
                end)
            end
            if target and target ~= "" and e.av.Image ~= target then
                pcall(function() e.av.Image = "" end)
                pcall(function() e.av.Image = target end)
                e.av.ImageTransparency = 0
            end
        end
    end



    -- Side chip / color (supports single hex or "#aaa/#bbb" split)
    local c1, c2 = nil, nil
    if cfg and cfg.color then
        c1, c2 = parseColorPair(cfg.color)
        c1 = c1 or tagAccentFromFill(cfg.color)
    end
    if not c1 and cfg and cfg.outline and cfg.outline ~= "" then
        c1 = parseColor(cfg.outline)
    end
    local txt = Tags:summary(p.UserId)
    -- owner-only custom chip text override
    if cfg and cfg.customText and cfg.customText ~= "" then txt = cfg.customText end
    -- Badge chip is OFF by default. Only show it when the entry opts in via
    -- cfg.showChip == "on". This hides the auto "Owner/Dev/..." pill unless
    -- the user explicitly enables it in the Tags panel.
    local chipOn = tostring(cfg and cfg.showChip or ""):lower() == "on"
    local defaultTagColor = T.silverHi or T.text
    local chipColor
    if txt ~= "" and chipOn then
        e.sh.Visible = true
        e.stat.Text = txt:gsub(",", " • ")
        chipColor = c1 or tagColor(p)
    else
        e.sh.Visible = false
        chipColor = c1 or (txt ~= "" and tagColor(p)) or defaultTagColor
    end
    e.dot.BackgroundColor3 = chipColor
    if e.avRing then
        e.avRing.Color = chipColor
        local ao = tostring(cfg and cfg.avatarOutline or ""):lower()
        e.avRing.Enabled = not (ao == "off" or ao == "none" or ao == "0" or ao == "false")
    end
    if e.glow then
        e.glow.ImageColor3 = chipColor
        e.glow.ImageTransparency = (txt ~= "" or p == LP) and 0.45 or 0.6
    end

    -- Sync tag text (display name + @handle + chip text) to the user's
    -- configured tag color. If they have no custom color, keep defaults.
    -- A per-entry "textColor" override beats the chip color when set.
    local hasCustomColor = cfg and cfg.color and cfg.color ~= ""
    local textOverride = nil
    if cfg and cfg.textColor and cfg.textColor ~= "" then
        textOverride = parseColor(cfg.textColor)
    end
    local nameColor   = textOverride or (hasCustomColor and chipColor) or T.text
    local handleColor = textOverride or (hasCustomColor and chipColor) or T.sub
    local statColor   = textOverride or (hasCustomColor and chipColor) or T.text
    if e.name   then e.name.TextColor3   = nameColor   end
    if e.handle then e.handle.TextColor3 = handleColor end
    if e.stat   then e.stat.TextColor3   = statColor   end

    -- Per-entry text-stroke color around the name labels. "off"/"none" disables.
    local toRaw = cfg and cfg.textOutline
    local toNorm = tostring(toRaw or ""):lower():gsub("^%s+",""):gsub("%s+$","")
    if e.name then
        if toNorm == "off" or toNorm == "none" or toNorm == "0" or toNorm == "false" then
            e.name.TextStrokeTransparency = 1
        elseif toRaw and toRaw ~= "" then
            local sc = parseColor(toRaw)
            if sc then
                e.name.TextStrokeColor3 = sc
                e.name.TextStrokeTransparency = 0.25
            end
        end
    end
    if e.handle then
        if toNorm == "off" or toNorm == "none" or toNorm == "0" or toNorm == "false" then
            e.handle.TextStrokeTransparency = 1
        elseif toRaw and toRaw ~= "" then
            local sc = parseColor(toRaw)
            if sc then
                e.handle.TextStrokeColor3 = sc
                e.handle.TextStrokeTransparency = 0.4
            end
        end
    end

    -- Outline: per-entry override. "off"/"none"/"0" disables the stroke entirely.
    local outlineRaw = cfg and cfg.outline
    local outlineNorm = tostring(outlineRaw or ""):lower():gsub("^%s+",""):gsub("%s+$","")
    if outlineNorm == "off" or outlineNorm == "none" or outlineNorm == "0" or outlineNorm == "false" then
        e.outlineOff = true
        e.stroke.Enabled = false
    else
        e.outlineOff = false
        e.stroke.Enabled = true
        local oc = (outlineRaw and outlineRaw ~= "" and parseColor(outlineRaw)) or chipColor
        e.stroke.Color = oc
    end

    -- Bubble fill: solid / split / gradient / image. UIGradient is enabled
    -- ONLY when actually rendering a gradient — for solid fills we paint
    -- BackgroundColor3 directly so a flat color always renders cleanly.
    if e.bgGrad then
        local fill = parseFill(cfg and cfg.color)
        if fill and fill.kind == "image" then
            if e.bgImg then
                -- Force a reset before reassigning so identical-URL refreshes
                -- still re-fetch; lift ZIndex above the bg fill + ring layers
                -- (but stay below avatar/labels at z=10) and stretch to fill.
                pcall(function() e.bgImg.Image = "" end)
                e.bgImg.Image             = fill.url
                e.bgImg.ImageTransparency = 0
                e.bgImg.BackgroundTransparency = 1
                e.bgImg.Size              = UDim2.new(1, 0, 1, 0)
                e.bgImg.Position          = UDim2.new(0, 0, 0, 0)
                e.bgImg.ScaleType         = Enum.ScaleType.Crop
                e.bgImg.ZIndex            = 3
                e.bgImg.Visible           = true
            end
            e.bgGrad.Enabled = false
            -- Keep a dark base behind the image so any transparent pixels still
            -- read as the pill, not the world behind the player's head.
            e.bg.BackgroundColor3       = Color3.fromRGB(14, 14, 18)
            e.bg.BackgroundTransparency = 0
        elseif fill and fill.kind == "gradient" then
            if e.bgImg then e.bgImg.Visible = false end
            e.bgGrad.Enabled  = true
            e.bgGrad.Rotation = fill.rotation or 90
            local n = #fill.stops
            local kps = {}
            for i, c in ipairs(fill.stops) do
                local t = (i - 1) / math.max(1, n - 1)
                kps[#kps + 1] = ColorSequenceKeypoint.new(t, c)
            end
            e.bgGrad.Color = ColorSequence.new(kps)
            e.bg.BackgroundColor3 = Color3.new(1, 1, 1)
            e.bg.BackgroundTransparency = 0
        elseif fill and fill.kind == "split" then
            if e.bgImg then e.bgImg.Visible = false end
            e.bgGrad.Enabled  = true
            e.bgGrad.Rotation = 0
            e.bgGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0,     fill.c1),
                ColorSequenceKeypoint.new(0.499, fill.c1),
                ColorSequenceKeypoint.new(0.5,   fill.c2),
                ColorSequenceKeypoint.new(1,     fill.c2),
            })
            e.bg.BackgroundColor3 = Color3.new(1, 1, 1)
            e.bg.BackgroundTransparency = 0
        elseif fill and fill.kind == "solid" then
            if e.bgImg then e.bgImg.Visible = false end
            -- paint solid colors directly on BackgroundColor3 — bypasses the
            -- UIGradient so the pill reliably shows the user's exact hex.
            e.bgGrad.Enabled = false
            e.bg.BackgroundColor3    = fill.c
            e.bg.BackgroundTransparency = 0
        else
            -- User typed something we couldn't parse: keep whatever color/image
            -- is currently on the pill instead of stomping it with the dark
            -- default, and surface a warn so they see the parse failure.
            local raw = cfg and cfg.color
            if raw and tostring(raw):gsub("%s","") ~= "" then
                if not e._badFillWarned or e._badFillWarned ~= raw then
                    warn(("[Tags] could not parse color/fill %q for %s — keeping previous pill"):format(tostring(raw), p.Name or "?"))
                    e._badFillWarned = raw
                end
                -- intentionally do nothing — leave e.bgImg / e.bgGrad / e.bg as-is
            else
                if e.bgImg then e.bgImg.Visible = false end
                -- Default dark gradient ONLY when no per-entry color is set.
                e.bgGrad.Enabled  = true
                e.bgGrad.Rotation = 90
                e.bgGrad.Color = ColorSequence.new(Color3.fromRGB(32, 32, 42), Color3.fromRGB(14, 14, 18))
                e.bg.BackgroundColor3 = Color3.new(1, 1, 1)
                e.bg.BackgroundTransparency = 0
            end
        end

    end

    -- Auto-size bubble to hug the visible text. Measure the FULL display name
    -- + @handle (not the in-progress typewriter/glitch text) so the pill stays
    -- snug even mid-animation. No artificial minimum so short names like
    -- "user / @user" render as a small pill instead of a wide rectangle.
    local nameFont   = e.name.Font   or Enum.Font.GothamBold
    local handleFont = e.handle.Font or Enum.Font.Gotham
    local nameW   = measureText(nameStr   or "", nameFont,   14)
    local handleW = measureText(handleStr or "", handleFont, 10)
    local textW   = math.ceil(math.max(nameW, handleW))
    -- breathing room for text-fx jitter (glitch chars, shake)
    e.name.Size   = UDim2.new(0, textW + 4, 0, 18)
    e.handle.Size = UDim2.new(0, textW + 4, 0, 14)

    local chipBlock = 0
    if e.sh and e.sh.Visible then
        local statW = measureText(e.stat.Text or "", e.stat.Font or Enum.Font.GothamBold, 10)
        local shW   = math.ceil(statW + 22)
        e.sh.Size   = UDim2.new(0, shW, 0, 22)
        chipBlock   = shW + 4
    end

    -- Layout: leftPad(6) + avatar(34) + gap(8) + text + chipBlock + rightPad(10)
    -- Comfortable default minimum (118px) — pill hugs short names without the
    -- text crowding the avatar's gradient ring, and auto-expands for longer
    -- display names / @handles.
    local pillW = math.max(118, 6 + 34 + 8 + textW + chipBlock + 10)
    -- Reposition labels so they start with breathing room after the avatar
    -- (override the 46px hardcoded offset from buildBill's initial placement).
    if e.name   then e.name.Position   = UDim2.new(0, 48, 0, 4)  end
    if e.handle then e.handle.Position = UDim2.new(0, 48, 0, 24) end
    e.nameBasePos   = e.name   and e.name.Position   or e.nameBasePos
    e.handleBasePos = e.handle and e.handle.Position or e.handleBasePos

    -- Pill (bg) is exactly pillW x 46. Billboard wrapper is pill + 24 wide,
    -- 58 tall so the normal outline has a little room without clipping.
    e.bg.AnchorPoint = Vector2.new(0.5, 0.5)
    e.bg.Position    = UDim2.new(0.5, 0, 0.5, 0)
    e.bg.Size        = UDim2.new(0, pillW, 0, 46)
    e.gui.Size       = UDim2.new(0, pillW + 24, 0, 58)
end


local function buildBill(p)

    if tagBills[p] or not pchar(p) then return end
    -- DB-only: only players with a tags.lua entry get bubbles (LP always gets one)
    if p ~= LP and not TagDB:configFor(p) then return end
    local head = pchar(p):FindFirstChild("Head"); if not head then return end
    -- anti-dup: nuke any leftover billboards from a previous script run
    for _, c in ipairs(pchar(p):GetChildren()) do
        if c.Name == "SeigeTagBB" then c:Destroy() end
    end

    local gui = inst("BillboardGui", pchar(p), {
        Name = "SeigeTagBB", Adornee = head,
        Active = true,
        -- Wrapper matches the compact minimum pill (100x46) + 12px halo on each
        -- side / 6px top+bottom for aura room. refreshBill resizes to fit text.
        Size = UDim2.new(0, 142, 0, 58),
        StudsOffset = Vector3.new(0, 1.7, 0),
        AlwaysOnTop = true, LightInfluence = 0,
    })

    -- Invisible stub kept so legacy refs (e.glow.ImageColor3 / .ImageTransparency) don't error.
    local glow = inst("Frame", gui, {
        Name = "glow", BackgroundTransparency = 1, BorderSizePixel = 0,
        Visible = false, Size = UDim2.new(0, 0, 0, 0), ZIndex = 0,
    })

    -- Pill is the only visible layer behind the tag content. Fully opaque so
    -- nothing reads as a transparent rectangle behind/around the pill.
    local bg = inst("Frame", gui, {
        -- Start at the compact minimum pill size (100x46) centered inside the
        -- BillboardGui wrapper, so the pre-refresh frame doesn't flash a
        -- full-wrapper-width rectangle. refreshBill resizes to actual textW.
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position    = UDim2.new(0.5, 0, 0.5, 0),
        Size        = UDim2.new(0, 118, 0, 46),
        BackgroundColor3 = T.bg, BackgroundTransparency = 0, BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 1,
    })
    corner(bg, 23)

    local st = stroke(bg, T.silverHi or T.text, 1.4, 0.25)
    local bgGrad = inst("UIGradient", bg, {
        Rotation = 90,
        Color = ColorSequence.new(Color3.fromRGB(40,40,52), Color3.fromRGB(14,14,18)),
    })
    local bgImg = inst("ImageLabel", bg, {
        Name = "bgImg",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ImageTransparency = 1,
        ScaleType = Enum.ScaleType.Crop,
        Visible = false,
        ZIndex = 2,
        Image = "",
    })
    corner(bgImg, 23)

    -- Invisible stubs for legacy refs to e.shine / e.underShade in refreshBill.
    local shine = inst("Frame", bg, {
        Name = "shine", BackgroundTransparency = 1, BorderSizePixel = 0,
        Visible = false, Size = UDim2.new(0, 0, 0, 0), ZIndex = 0,
    })
    local underShade = inst("Frame", bg, {
        Name = "underShade", BackgroundTransparency = 1, BorderSizePixel = 0,
        Visible = false, Size = UDim2.new(0, 0, 0, 0), ZIndex = 0,
    })


    local av = inst("ImageLabel", bg, {
        Size = UDim2.new(0, 34, 0, 34), Position = UDim2.new(0, 6, 0.5, -17),
        BackgroundColor3 = T.bg3, BorderSizePixel = 0, ScaleType = Enum.ScaleType.Crop,
        ZIndex = 10,
    })
    corner(av, 17)
    -- gradient ring around avatar — colored from chip color in refreshBill
    local avRing = stroke(av, T.silverHi or T.text, 2, 0.1)
    pcall(function() av.Image = Players:GetUserThumbnailAsync(p.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100) end)
    local nm = inst("TextLabel", bg, {
        BackgroundTransparency = 1, Position = UDim2.new(0, 46, 0, 4), Size = UDim2.new(1, -120, 0, 18),
        Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = T.text,
        TextXAlignment = Enum.TextXAlignment.Left, Text = p.DisplayName, TextStrokeTransparency = 0.55,
        TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
        ZIndex = 10,
    })
    local hd = inst("TextLabel", bg, {
        BackgroundTransparency = 1, Position = UDim2.new(0, 46, 0, 24), Size = UDim2.new(1, -120, 0, 14),
        Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = T.sub,
        TextXAlignment = Enum.TextXAlignment.Left, Text = "@" .. p.Name,
        TextTransparency = 0.05,
        ZIndex = 10,
    })
    local sh = inst("Frame", bg, {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0),
        Size = UDim2.new(0, 80, 0, 24),
        BackgroundColor3 = T.bg2, BorderSizePixel = 0,
        ZIndex = 10,
    })
    corner(sh, 12); stroke(sh, T.line, 1, 0.35)
    -- chip top-shine
    local chipShine = inst("Frame", sh, {
        Name = "chipShine",
        Size = UDim2.new(1, -4, 0, 10),
        Position = UDim2.new(0, 2, 0, 1),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.7,
        BorderSizePixel = 0,
        ZIndex = 10,
    })
    corner(chipShine, 8)
    inst("UIGradient", chipShine, {
        Rotation = 90,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.55),
            NumberSequenceKeypoint.new(1, 1),
        }),
    })
    local dot = inst("Frame", sh, {
        Size = UDim2.new(0, 7, 0, 7), Position = UDim2.new(0, 8, 0.5, -3),
        BackgroundColor3 = T.silverHi or T.text, BorderSizePixel = 0,
        ZIndex = 11,
    })
    corner(dot, 4)
    -- subtle glow on the dot
    stroke(dot, T.silverHi or T.text, 1, 0.4)
    local stx = inst("TextLabel", sh, {
        BackgroundTransparency = 1, Position = UDim2.new(0, 19, 0, 0), Size = UDim2.new(1, -23, 1, 0),
        Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = T.text,
        TextXAlignment = Enum.TextXAlignment.Left, Text = "",
        ZIndex = 11,
    })
    -- invisible click overlay covering the whole bubble → teleport to target player
    -- Parented to the BillboardGui (not bg) so nothing in bg can intercept input.
    local clickBtn = inst("TextButton", gui, {
        Name = "tpClick",
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        Active = true,
        Selectable = true,
        Modal = false,
        ZIndex = 100,
    })
    local function onTagClicked()
        -- click sound (plays for everyone, including LP clicking own tag)
        pcall(function()
            local s = Instance.new("Sound")
            s.SoundId = "rbxassetid://6895079853" -- short UI click
            s.Volume  = 0.7
            s.Parent  = game:GetService("SoundService")
            s:Play()
            game:GetService("Debris"):AddItem(s, 2)
        end)
        if p == LP then
            notify("That's you", "dim"); return
        end
        local targetHrp = phrp(p)
        local myHrp = hrp()
        if not (targetHrp and myHrp) then
            notify("Can't teleport — target/you not spawned", "warn"); return
        end
        local cf = targetHrp.CFrame
        pcall(function()
            myHrp.CFrame = cf * CFrame.new(0, 0, 3)
        end)
        notify("Teleported to " .. p.DisplayName, "good")
    end
    clickBtn.Activated:Connect(onTagClicked)
    clickBtn.MouseButton1Click:Connect(onTagClicked)

    -- Reliable 3D-click fallback: ClickDetector on the head.
    -- Works regardless of any GUI input layering issues.
    local cd
    pcall(function()
        -- nuke any leftover detector first so we don't stack handlers
        local old = head:FindFirstChild("SeigeTagCD")
        if old then old:Destroy() end
        cd = Instance.new("ClickDetector")
        cd.Name = "SeigeTagCD"
        cd.MaxActivationDistance = 1000
        cd.CursorIcon = ""
        cd.Parent = head
        cd.MouseClick:Connect(function() onTagClicked() end)
    end)

    tagBills[p] = { gui = gui, bg = bg, bgGrad = bgGrad, bgImg = bgImg, stroke = st, name = nm, handle = hd, stat = stx, dot = dot, sh = sh, av = av, avRing = avRing, glow = glow, shine = shine, clickBtn = clickBtn, clickDetector = cd, base = math.random() * 6.28, gifToken = 0, gifKey = nil }
    _G.__SeigeTagBills = tagBills
    _G.__SeigeRefreshBill = refreshBill
    NameHider.hide(p)
    refreshBill(p)
    if _G.__SeigeApplyTagFont then pcall(_G.__SeigeApplyTagFont) end
end
local function rebuildBills()
    clearBills()
    -- LP's tag always shown
    buildBill(LP)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            if floatOn or (scriptersOn and isScripter(p)) or TagDB:configFor(p) then
                buildBill(p)
            end
        end
    end
end
-- Incremental update: add/remove bills based on the current scripter set so
-- newly detected seige.lol users in the server get a tag without rebuilding
-- everyone (avoids the glitchy flash from clearBills()).
local function syncScripterBills()
    if not scriptersOn then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and isScripter(p) and not tagBills[p] and pchar(p) then
            pcall(buildBill, p)
        end
    end
end
_G.__SeigeSyncScripterBills = syncScripterBills
-- Floating tag visibility and icons are now controlled by the script DB (tags.lua)
-- and the bottom-right "Enable player tags" prompt.

TagIcons:onChange(function(uid)
    for p, _ in pairs(tagBills) do
        if p.UserId == uid then refreshBill(p) end
    end
end)




bind(RunService.Heartbeat:Connect(function()
    local t = tick()
    for p, e in pairs(tagBills) do
        if e.gui and e.gui.Parent then
            -- tag stays locked to the head (no independent bob); it bounces naturally with the avatar's animation
            e.gui.StudsOffsetWorldSpace = Vector3.new(0, 0, 0)
            if not e.outlineOff then
                e.stroke.Transparency = 0.2 + (math.sin(t * 3 + e.base) + 1) * 0.1
            end
            -- subtle hovering float on the pill (only when no theme animation is overriding Position)
            local anim = _G.__SeigeBubbleAnim or "None"
            if anim == "None" and e.bg and e.bg.Parent then
                local hoverY = math.sin(t * 1.5 + e.base) * 2
                -- AnchorPoint is (0.5, 0.5); keep the pill centred and only
                -- bob it vertically by hoverY pixels.
                e.bg.Position = UDim2.new(0.5, 0, 0.5, hoverY)
            end
        end
    end
end))

bind(RunService.Heartbeat:Connect(function(dt)
    local t = tick()
    local anim = _G.__SeigeBubbleAnim or "None"
    local amt  = tonumber(_G.__SeigeBubbleAmt) or 0.5
    for _, e in pairs(tagBills) do
        -- ----- Bubble animation (Themes tab) -----
        if e.bg and e.bg.Parent then
            if anim ~= "None" then
                local sc = e.bg:FindFirstChildOfClass("UIScale")
                if not sc then sc = Instance.new("UIScale"); sc.Scale = 1; sc.Parent = e.bg end
                local phase = (e.base or 0) + t
                if anim == "Bounce" then
                    sc.Scale = 1 + math.abs(math.sin(phase * 3)) * 0.15 * amt
                elseif anim == "Pulse" then
                    sc.Scale = 1 + math.sin(phase * 4) * 0.08 * amt
                elseif anim == "Float" then
                    pcall(function()
                        e.bg.Position = UDim2.new(0.5, 0, 0.5, math.sin(phase * 2) * 6 * amt)
                    end)
                elseif anim == "Wobble" then
                    pcall(function() e.bg.Rotation = math.sin(phase * 3) * 6 * amt end)
                elseif anim == "Shake" then
                    pcall(function()
                        e.bg.Position = UDim2.new(0.5, math.sin(phase * 30) * 2 * amt, 0.5, math.cos(phase * 27) * 2 * amt)
                    end)
                elseif anim == "Heartbeat" then
                    local b = math.sin(phase * 6); b = b * b
                    sc.Scale = 1 + b * 0.18 * amt
                end
            else
                -- Anim switched back to None — reset any leftover UIScale and
                -- rotation so the pill returns to its true pillW x 46 size.
                local sc = e.bg:FindFirstChildOfClass("UIScale")
                if sc and sc.Scale ~= 1 then sc.Scale = 1 end
                if e.bg.Rotation ~= 0 then e.bg.Rotation = 0 end
            end
        end
    end
end))



Tags:onChange(function(uid)
    for _, p in ipairs(Players:GetPlayers()) do
        if p.UserId == uid then
            if tagBills[p] then refreshBill(p) else if floatOn or p == LP or (scriptersOn and isScripter(p)) then buildBill(p) end end
        end
    end
    refreshPlayerList()
end)
local function hookCharBill(p)
    bind(p.CharacterAdded:Connect(function()
        task.wait(0.5)
        if tagBills[p] then pcall(NameHider.restore, p); pcall(function() tagBills[p].gui:Destroy() end); tagBills[p] = nil end
        -- always build the bubble for LP, for everyone if floatOn,
        -- and for ANY player that has a saved tag entry (so rejoining users
        -- always see their persisted custom tag).
        if floatOn or p == LP or (scriptersOn and isScripter(p)) or TagDB:configFor(p) then buildBill(p) end
    end))
end

bind(Players.PlayerAdded:Connect(function(p)
    hookCharBill(p)
    TagDB:applyTo(p)
    -- if the player has a persisted tag entry and is already in their character,
    -- build immediately so we don't have to wait for the next respawn.
    task.defer(function()
        if pchar(p) and not tagBills[p] and (floatOn or (scriptersOn and isScripter(p)) or TagDB:configFor(p)) then
            pcall(buildBill, p)
        end
    end)
end))
for _, p in ipairs(Players:GetPlayers()) do hookCharBill(p) end

-- Hydrate from local cache synchronously so the saved tag pill shows up
-- on the very first frame after inject — no waiting for the Pastebin fetch.
pcall(function() TagDB:hydrateFromCache() end)
for _, p in ipairs(Players:GetPlayers()) do
    TagDB:applyTo(p)
    if pchar(p) and not tagBills[p] and (floatOn or p == LP or (scriptersOn and isScripter(p)) or TagDB:configFor(p)) then
        pcall(buildBill, p)
    end
end

-- Then refresh from network in the background and re-apply to everyone
-- once fresh entries land.
task.spawn(function()
    TagDB:load()
    for _, p in ipairs(Players:GetPlayers()) do
        TagDB:applyTo(p)
        if pchar(p) and not tagBills[p] and (floatOn or p == LP or (scriptersOn and isScripter(p)) or TagDB:configFor(p)) then
            pcall(buildBill, p)
        end
    end
    task.defer(rebuildBills)
end)


------------------------------------------------------- TAGS MANAGER (owner-only)
-- In-game GUI to add/edit/remove tag entries without touching code or pastebin.
-- Changes apply LIVE to everyone in the server. Export button copies a
-- pastebin-formatted text block to your clipboard so you can save permanently.
if LP.Name == OWNER_NAME or _G.__SeigeMyRole() then (function()
  if LP.Name == OWNER_NAME then
    local pgTags = makeTab("Tags", "✎", "Custom tags, colors and icons")

    -- Make the Tags page breathe: extra vertical spacing between rows and
    -- a touch more interior padding so nothing feels cramped.
    for _, c in ipairs(pgTags:GetChildren()) do
        if c:IsA("UIListLayout") then c.Padding = UDim.new(0, 10) end
        if c:IsA("UIPadding") then
            c.PaddingTop = UDim.new(0, 10); c.PaddingBottom = UDim.new(0, 14)
            c.PaddingLeft = UDim.new(0, 10); c.PaddingRight = UDim.new(0, 10)
        end
    end
    -- Small visual spacer to separate logical groups on the Tags page.
    local function tagSpacer(h)
        inst("Frame", pgTags, {
            Size = UDim2.new(1, -8, 0, h or 6),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        })
    end

    -- form values
    local form = {
        username = "", displayName = "", color = "", color2 = "", fill = "",
        icon = "", tags = "", customText = "", customHandle = "",
        font = "Default",
        textColor = "", textOutline = "",
        textFx = "None", avatarOutline = "On", showChip = "Off",
    }
    local editingKey = nil  -- if set, "Save" updates this key instead of creating

    section(pgTags, "Tag editor")

    local function field(parent, lbl, key, placeholder)
        local f = inst("Frame", parent, {
            Size = UDim2.new(1, -8, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = T.bg2,
            BackgroundTransparency = 0.3,
            BorderSizePixel = 0,
        })
        corner(f, 8); stroke(f, T.line, 1, 0.5)
        inst("UIPadding", f, {
            PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6),
            PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
        })
        inst("UIListLayout", f, {
            Padding = UDim.new(0, 4),
            SortOrder = Enum.SortOrder.LayoutOrder,
            FillDirection = Enum.FillDirection.Vertical,
        })
        inst("TextLabel", f, {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Font = Enum.Font.GothamBold,
            TextSize = 10,
            TextColor3 = T.dim,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true,
            Text = string.upper(lbl),
            LayoutOrder = 1,
        })
        local tb = inst("TextBox", f, {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 22),
            PlaceholderText = placeholder or "",
            PlaceholderColor3 = T.dim,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextColor3 = T.text,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = "",
            ClearTextOnFocus = false,
            TextTruncate = Enum.TextTruncate.AtEnd,
            LayoutOrder = 2,
        })
        tb:GetPropertyChangedSignal("Text"):Connect(function()
            form[key] = tb.Text
        end)
        return tb
    end

    local tbUser     = field(pgTags, "Username (required)", "username", "DESPAIRDEV293")
    local tbDisplay  = field(pgTags, "Display name (optional)", "displayName", "Despair")
    local tbColor    = field(pgTags, "Hex color or Roblox image ID (left half / pill fill)", "color", "#ff3b6b   or   1234567890")
    local tbColor2   = field(pgTags, "Hex color 2 (right half — optional)", "color2", "#00aaff")
    local tbFill     = field(pgTags, "Advanced fill (overrides hex) — grad:#a,#b@90  or  image:1234567",
                              "fill", "grad:#ff3b6b,#00aaff@45   or   image:1234567890")
    local tbIcon     = field(pgTags, "Roblox Image ID (or sprite:id:cols:rows:fps)", "icon", "1234567890  or  sprite:1234567890:4:4:12  or  gif:1234567890:4:4:12")
    local tbTags     = field(pgTags, "Tags (comma separated)", "tags", "Owner,Dev")
    local tbCustom   = field(pgTags, "Custom chip text (owner override — optional)", "customText", "VIP")
    local tbHandle   = field(pgTags, "Custom @handle (overrides @user — optional)", "customHandle", "despair")
    local tbOutline  = field(pgTags, "Outline color (hex, or 'off' to disable)", "outline", "#ffffff   or   off")
    local tbTextColor   = field(pgTags, "Tag text color (display name + @handle) — hex, blank = auto",
                                "textColor", "#ffffff   or   blank for auto")
    local tbTextOutline = field(pgTags, "Tag text outline color (text stroke around the name) — hex, or 'off'",
                                "textOutline", "#000000   or   off")

    -- gradient presets (inspired by gradientshub.com) — click to set the fill spec
    section(pgTags, "Gradient presets")
    local GRAD_PRESETS = {
        { name = "Sunset",      spec = "grad:#ff512f,#dd2476@45" },
        { name = "Ocean",       spec = "grad:#2193b0,#6dd5ed@90" },
        { name = "Purple Bliss", spec = "grad:#360033,#0b8793@135" },
        { name = "Cherry",      spec = "grad:#eb3349,#f45c43@90" },
        { name = "Aurora",      spec = "grad:#00c9ff,#92fe9d@120" },
        { name = "Cosmic",      spec = "grad:#ff00cc,#333399@60" },
        { name = "Lush",        spec = "grad:#56ab2f,#a8e063@45" },
        { name = "Peach",       spec = "grad:#ed4264,#ffedbc@90" },
        { name = "Steel",       spec = "grad:#232526,#414345@90" },
        { name = "Rainbow",     spec = "grad:#ff0000,#ffa500,#ffff00,#00ff00,#0000ff,#8b00ff@90" },
    }
    local presetRow = inst("Frame", pgTags, {
        Size = UDim2.new(1, -8, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
    })
    inst("UIGridLayout", presetRow, {
        CellSize = UDim2.new(0, 92, 0, 26),
        CellPadding = UDim2.new(0, 4, 0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
    })
    for _, pr in ipairs(GRAD_PRESETS) do
        local fill = parseFill(pr.spec)
        local pb = inst("TextButton", presetRow, {
            Size = UDim2.new(0, 92, 0, 26),
            BackgroundColor3 = T.bg3, BackgroundTransparency = 0,
            BorderSizePixel = 0, AutoButtonColor = false,
            Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = T.text,
            Text = pr.name, TextStrokeTransparency = 0.5,
        })
        corner(pb, 6); stroke(pb, T.line, 1, 0.4)
        if fill and fill.kind == "gradient" then
            local kps = {}
            for i, c in ipairs(fill.stops) do
                kps[#kps + 1] = ColorSequenceKeypoint.new((i - 1) / math.max(1, #fill.stops - 1), c)
            end
            inst("UIGradient", pb, { Rotation = fill.rotation or 90, Color = ColorSequence.new(kps) })
        end
        pb.MouseButton1Click:Connect(function()
            tbFill.Text = pr.spec
            tbColor.Text = ""; tbColor2.Text = ""
            notify("Applied preset: " .. pr.name, "good")
        end)
    end

    section(pgTags, "Other")


    -- per-tag font (dafont-style picks)
    local TAG_FONT_OPTS = { "Default", "PermanentMarker", "LuckiestGuy", "Creepster" }
    local fontDD = dropdown(pgTags, "Tag font (per-user)", TAG_FONT_OPTS, function(v) form.font = v end)

    -- Text animation effect (applies to the display name in the pill)
    local TAG_FX_OPTS = { "None", "Typewriter", "Glitch", "Rainbow", "Floating", "Zerograv", "Wave", "Shake" }
    local fxDD = dropdown(pgTags, "Text animation", TAG_FX_OPTS, function(v) form.textFx = v end)

    -- Toggle for the ring/outline around the profile avatar in the pill
    local AVATAR_OUTLINE_OPTS = { "On", "Off" }
    local avOutlineDD = dropdown(pgTags, "Profile outline", AVATAR_OUTLINE_OPTS, function(v) form.avatarOutline = v end)

    -- Badge chip (right-side "OWNER/DEV/..." pill). Default OFF; turn ON per-tag.
    local SHOW_CHIP_OPTS = { "Off", "On" }
    local showChipDD = dropdown(pgTags, "Show badge chip", SHOW_CHIP_OPTS, function(v) form.showChip = v end)

    -- Give the Tag panel's dropdowns more room; longer option values were
    -- getting clipped at the default 140px button width.
    -- The dropdown helper returns a controller (not the Frame), so walk
    -- pgTags' children and resize any frame that matches the dropdown shape
    -- (a TextButton anchored to the right edge).
    for _, frame in ipairs(pgTags:GetChildren()) do
        if frame:IsA("Frame") and frame.Size.Y.Offset == 34 then
            local btn = frame:FindFirstChildOfClass("TextButton")
            local lbl = frame:FindFirstChildOfClass("TextLabel")
            if btn and lbl and btn.AnchorPoint == Vector2.new(1, 0.5) then
                lbl.Size = UDim2.new(1, -200, 1, 0)
                btn.Size = UDim2.new(0, 180, 0, 24)
                frame.Size = UDim2.new(1, -8, 0, 38)
            end
        end
    end



    -- live preview swatch
    local prev = inst("Frame", pgTags, {
        Size = UDim2.new(1, -8, 0, 36),
        BackgroundColor3 = T.bg2,
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
    })
    corner(prev, 8); stroke(prev, T.line, 1, 0.5)
    local swatch = inst("Frame", prev, {
        Position = UDim2.new(0, 10, 0.5, -10),
        Size = UDim2.new(0, 20, 0, 20),
        BackgroundColor3 = T.acc,
        BorderSizePixel = 0,
    })
    corner(swatch, 4); stroke(swatch, T.text, 1, 0.3)
    local swatch2 = inst("Frame", prev, {
        Position = UDim2.new(0, 34, 0.5, -10),
        Size = UDim2.new(0, 20, 0, 20),
        BackgroundColor3 = T.bg3,
        BorderSizePixel = 0,
        Visible = false,
    })
    corner(swatch2, 4); stroke(swatch2, T.text, 1, 0.3)
    local prevLbl = inst("TextLabel", prev, {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 64, 0, 0),
        Size = UDim2.new(1, -70, 1, 0),
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = T.sub,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = "color preview",
    })
    local function refreshSwatch()
        local c1 = parseColor(tbColor.Text)
        local c2 = parseColor(tbColor2.Text)
        if c1 then swatch.BackgroundColor3 = c1 end
        if c2 then swatch2.BackgroundColor3 = c2; swatch2.Visible = true
        else swatch2.Visible = false end
        prevLbl.Text = (tbColor.Text or "") .. (c2 and (" / " .. tbColor2.Text) or "")
    end
    tbColor:GetPropertyChangedSignal("Text"):Connect(refreshSwatch)
    tbColor2:GetPropertyChangedSignal("Text"):Connect(refreshSwatch)

    local function loadForm(key, e)
        editingKey = key
        tbUser.Text     = key or ""
        tbDisplay.Text  = (e and e.displayName) or ""
        -- color storage: solid "#hex", split "#a/#b", "grad:..." or "image:..."
        -- Be tolerant of older entries that stored a raw asset id or rbxassetid
        -- URL directly in `color` — those should land in the advanced-fill box,
        -- never in the hex color box.
        local rawColor = (e and e.color) or ""
        local rcLow = rawColor:lower()
        local isFill =
            rcLow:sub(1,5) == "grad:" or rcLow:sub(1,9) == "gradient:"
            or rcLow:sub(1,6) == "image:" or rcLow:sub(1,4) == "img:"
            or rcLow:sub(1,13) == "rbxassetid://"
            or (rawColor ~= "" and rawColor:match("^%d+$") ~= nil)
        if isFill then
            -- Normalize raw asset ids / rbxassetid urls into an image: spec so
            -- the advanced-fill box shows a recognisable form.
            if rawColor:match("^%d+$") then
                tbFill.Text = "image:" .. rawColor
            elseif rcLow:sub(1,13) == "rbxassetid://" then
                tbFill.Text = "image:" .. rawColor:sub(14)
            else
                tbFill.Text = rawColor
            end
            tbColor.Text = ""; tbColor2.Text = ""
        else
            tbFill.Text = ""
            local c1str, c2str = rawColor:match("([^/]+)/([^/]+)")
            if c1str and c2str then
                tbColor.Text  = (c1str:gsub("^%s+",""):gsub("%s+$",""))
                tbColor2.Text = (c2str:gsub("^%s+",""):gsub("%s+$",""))
            else
                tbColor.Text  = rawColor
                tbColor2.Text = ""
            end
        end
        local iconRaw = tostring((e and e.icon) or "")
        local iconLower = iconRaw:lower()
        if iconLower:sub(1, 4) == "gif:" or iconLower:sub(1, 7) == "sprite:" then
            -- keep gif/sprite spec intact (e.g. "gif:1234567890:4:4:12" or "sprite:...")
            tbIcon.Text = iconRaw
        else
            tbIcon.Text = iconRaw:gsub("rbxassetid://", ""):gsub("%D", ""):gsub("^%s+",""):gsub("%s+$","")
        end
        tbTags.Text     = (e and e.tags and table.concat(e.tags, ",")) or ""
        tbCustom.Text   = (e and e.customText) or ""
        tbHandle.Text   = (e and e.customHandle) or ""
        tbOutline.Text  = (e and e.outline) or ""
        tbTextColor.Text   = (e and e.textColor) or ""
        tbTextOutline.Text = (e and e.textOutline) or ""
        fontDD.set((e and e.font) or "Default")
        do
            local fx = tostring((e and e.textFx) or ""):lower()
            local label = "None"
            if fx == "typewriter" or fx == "type" then label = "Typewriter"
            elseif fx == "glitch" then label = "Glitch"
            elseif fx == "rainbow" then label = "Rainbow"
            elseif fx == "floating" or fx == "float" then label = "Floating"
            elseif fx == "zerograv" or fx == "zero-grav" or fx == "zerog" then label = "Zerograv"
            elseif fx == "wave" then label = "Wave"
            elseif fx == "shake" then label = "Shake" end
            form.textFx = label; fxDD.set(label)
        end
        do
            local ao = tostring((e and e.avatarOutline) or ""):lower()
            local label = (ao == "off" or ao == "none" or ao == "0" or ao == "false") and "Off" or "On"
            form.avatarOutline = label; avOutlineDD.set(label)
        end
        do
            local sc = tostring((e and e.showChip) or ""):lower()
            local label = (sc == "on" or sc == "1" or sc == "true") and "On" or "Off"
            form.showChip = label; showChipDD.set(label)
        end
    end

    local function clearForm() loadForm(nil, nil) end

    local function applyToMatchingPlayer(user)
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Name:lower() == user:lower() then
                TagDB:applyTo(p)
                -- Rebuild the bubble from scratch so a brand-new entry (or a
                -- changed displayName/customHandle) is picked up cleanly. Just
                -- calling refreshBill is a no-op if no bill exists yet, and the
                -- spec said "tag username changes don't work" — this is why.
                if tagBills[p] then
                    pcall(NameHider.restore, p); pcall(function() tagBills[p].gui:Destroy() end)
                    tagBills[p] = nil
                end
                pcall(buildBill, p)
                pcall(refreshBill, p)
            end
        end
    end

    -- list of current entries
    local listSec = section(pgTags, "Current tags")
    local listFrame = inst("Frame", pgTags, {
        Size = UDim2.new(1, -8, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
    })
    inst("UIListLayout", listFrame, {
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })

    local function rebuildList()
        for _, c in ipairs(listFrame:GetChildren()) do
            if not c:IsA("UIListLayout") then c:Destroy() end
        end
        local keys = {}
        for k in pairs(TagDB.entries) do keys[#keys+1] = k end
        table.sort(keys)
        for _, k in ipairs(keys) do
            local e = TagDB.entries[k]
            local row = inst("Frame", listFrame, {
                Size = UDim2.new(1, 0, 0, 30),
                BackgroundColor3 = T.bg2,
                BackgroundTransparency = 0.3,
                BorderSizePixel = 0,
            })
            corner(row, 6); stroke(row, T.line, 1, 0.5)
            local dot = inst("Frame", row, {
                Position = UDim2.new(0, 8, 0.5, -5),
                Size = UDim2.new(0, 10, 0, 10),
                BackgroundColor3 = parseColor(e.color or "") or tagAccentFromFill(e.color or "") or parseColor(e.outline or "") or (T.silverHi or T.text),
                BorderSizePixel = 0,
            })
            corner(dot, 5)
            inst("TextLabel", row, {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 26, 0, 0),
                Size = UDim2.new(1, -130, 1, 0),
                Font = Enum.Font.GothamMedium,
                TextSize = 12,
                TextColor3 = T.text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = (e.displayName and (e.displayName .. " (" .. k .. ")")) or k,
            })
            local bEdit = inst("TextButton", row, {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -58, 0.5, 0),
                Size = UDim2.new(0, 48, 0, 22),
                BackgroundColor3 = T.bg3,
                AutoButtonColor = false,
                Text = "edit",
                Font = Enum.Font.GothamSemibold,
                TextSize = 11,
                TextColor3 = T.text,
            })
            corner(bEdit, 6); stroke(bEdit, T.line, 1, 0.4)
            local bDel = inst("TextButton", row, {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -6, 0.5, 0),
                Size = UDim2.new(0, 48, 0, 22),
                BackgroundColor3 = T.bg3,
                AutoButtonColor = false,
                Text = "del",
                Font = Enum.Font.GothamSemibold,
                TextSize = 11,
                TextColor3 = T.bad,
            })
            corner(bDel, 6); stroke(bDel, T.line, 1, 0.4)
            bEdit.MouseButton1Click:Connect(function() loadForm(k, e) end)
            bDel.MouseButton1Click:Connect(function()
                TagDB.entries[k] = nil
                TagDB.localEntries[k] = nil
                -- clear saved icon + tags from any matching player in-server
                for _, p in ipairs(Players:GetPlayers()) do
                    if p.Name:lower() == k then
                        TagDB:applyTo(p)
                        if tagBills[p] then
                            pcall(NameHider.restore, p); pcall(function() tagBills[p].gui:Destroy() end)
                            tagBills[p] = nil
                        end
                        if floatOn or p == LP or (scriptersOn and isScripter(p)) or TagDB:configFor(p) then pcall(buildBill, p) end
                    end
                end
                rebuildList()
                local sok, serr = TagDB:saveLocal()
                if sok then notify("Removed tag entry: " .. k .. " (persisted)", "warn")
                else notify("Removed entry, but local save failed: " .. tostring(serr), "bad") end
                if _G.__SeigePbPush then task.spawn(_G.__SeigePbPush) end
            end)
        end
        if #keys == 0 then
            inst("TextLabel", listFrame, {
                Size = UDim2.new(1, 0, 0, 24),
                BackgroundTransparency = 1,
                Font = Enum.Font.Gotham,
                TextSize = 11,
                TextColor3 = T.dim,
                Text = "no entries yet — add one above",
            })
        end
    end

    -- TAG FINDER · look up any username and pull their tag from the
    -- pastebin DB so it can be edited in this panel. Useful for tweaking
    -- a friend's existing tag without having to retype every field.
    section(pgTags, "Tag finder")
    local finderRow = inst("Frame", pgTags, {
        Size = UDim2.new(1, -8, 0, 32),
        BackgroundTransparency = 1,
    })
    local finderBox = inst("TextBox", finderRow, {
        Size = UDim2.new(1, -110, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = T.bg2, BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
        PlaceholderText = "username (e.g. 0rot3)",
        PlaceholderColor3 = T.dim,
        Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = T.text,
        TextXAlignment = Enum.TextXAlignment.Left, Text = "",
        ClearTextOnFocus = false,
    })
    corner(finderBox, 6); stroke(finderBox, T.line, 1, 0.5)
    local padBox = inst("UIPadding", finderBox, { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 8) })
    local findBtn = inst("TextButton", finderRow, {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.new(0, 100, 1, 0),
        BackgroundColor3 = T.acc, AutoButtonColor = false,
        Font = Enum.Font.GothamBold, TextSize = 12,
        TextColor3 = T.text, Text = "Find tag",
    })
    corner(findBtn, 6); stroke(findBtn, T.line, 1, 0.4)

    local function doFind()
        local raw = (finderBox.Text or ""):gsub("^@",""):gsub("^%s+",""):gsub("%s+$","")
        if raw == "" then notify("Enter a username to look up", "bad"); return end
        local key = raw:lower()
        local function tryLoad()
            local e = TagDB.entries[key]
            if e then
                loadForm(key, e)
                notify("Loaded tag for " .. raw .. " — edit and Save to update", "good")
                return true
            end
            return false
        end
        if tryLoad() then return end
        -- not found locally: refresh from pastebin and try again
        notify("Not in cache — refreshing from GitHub…", "warn")
        task.spawn(function()
            local ok = pcall(function() TagDB:load() end)
            if not ok then notify("GitHub fetch failed", "bad"); return end
            if not tryLoad() then
                notify("No tag found for " .. raw, "bad")
            end
        end)
    end
    findBtn.MouseButton1Click:Connect(doFind)
    finderBox.FocusLost:Connect(function(enter) if enter then doFind() end end)

    section(pgTags, "Actions")

    button(pgTags, "Save / Update entry", function()
        -- read directly from the textboxes as the primary source — text-change
        -- handlers can miss the very last edit if the user clicks Save before
        -- defocus, which would drop fields from the export.
        local function trimStr(s) return (tostring(s or ""):gsub("^%s+",""):gsub("%s+$","")) end
        local function pick(_formVal, tbText)
            -- The textbox is the truth. The old code accidentally preferred
            -- cached form values first, so a quick Save could reuse the old
            -- color/fill even though the visible box showed Cosmic/custom fill.
            return trimStr(tbText)
        end
        local u = pick(form.username, tbUser.Text):gsub("^@", "")
        if u == "" then notify("Username required", "bad"); return end
        local key = u:lower()
        local entry = {}
        local dn = pick(form.displayName, tbDisplay.Text)
        if dn ~= "" then entry.displayName = dn end
        local fillRaw = pick(form.fill, tbFill.Text)
        local c1 = pick(form.color, tbColor.Text)
        local c2 = pick(form.color2, tbColor2.Text)
        -- Detect Roblox image specs in ANY of the color/fill fields so the user
        -- can paste an asset id (or rbxassetid://, decal/library URL) into the
        -- "Hex color" box and have the black pill background swap to that
        -- texture, not just the dedicated Advanced fill field.
        local function digitsFromUrl(u)
            return u:match("[?&]id=(%d+)") or u:match("/(%d+)")
        end
        local function normalizeImageSpec(raw)
            if not raw or raw == "" then return nil end
            local low = raw:lower()
            if low:sub(1,6) == "image:" or low:sub(1,4) == "img:"
               or low:sub(1,6) == "asset:" or low:sub(1,6) == "decal:"
               or low:sub(1,8) == "texture:" then
                return raw
            end
            if raw:match("^%d+$") then return "image:" .. raw end
            if low:match("^rbxassetid://") then return "image:" .. raw:gsub("rbxassetid://", "") end
            if low:match("^rbxthumb://") then return raw end
            if low:match("roblox%.com") then
                local id = digitsFromUrl(raw); if id then return "image:" .. id end
            end
            if low:match("^https?://") and (low:match("%.png") or low:match("%.jpg") or low:match("%.jpeg") or low:match("%.gif") or low:match("%.webp")) then
                return "image:" .. raw
            end
            return nil
        end
        local imgSpec = normalizeImageSpec(fillRaw) or normalizeImageSpec(c1) or normalizeImageSpec(c2)
        if imgSpec then
            entry.color = imgSpec
        elseif fillRaw ~= "" then
            entry.color = fillRaw -- gradient/split spec
        elseif c1 ~= "" and c2 ~= "" then entry.color = c1 .. "/" .. c2
        elseif c1 ~= "" then entry.color = c1
        elseif c2 ~= "" then entry.color = c2 end
        local iconRaw = pick(form.icon, tbIcon.Text)
        if iconRaw ~= "" then
            local lower = iconRaw:lower()
            if lower:sub(1, 4) == "gif:" or lower:sub(1, 7) == "sprite:" then
                entry.icon = iconRaw
            else
                local cleanId = iconRaw:gsub("rbxassetid://", ""):gsub("%D", "")
                if cleanId ~= "" then entry.icon = cleanId end
            end
        end
        local ct = pick(form.customText, tbCustom.Text)
        if ct ~= "" then entry.customText = ct end
        local ch = pick(form.customHandle, tbHandle.Text)
        if ch ~= "" then entry.customHandle = (ch:gsub("^@","")) end
        local ol = pick(form.outline, tbOutline.Text)
        if ol ~= "" then entry.outline = ol end
        local tc = pick(form.textColor, tbTextColor.Text)
        if tc ~= "" then entry.textColor = tc end
        local to = pick(form.textOutline, tbTextOutline.Text)
        if to ~= "" then entry.textOutline = to end
        if form.font and form.font ~= "" and form.font ~= "Default" then
            entry.font = form.font
        end
        if form.textFx and form.textFx ~= "" and form.textFx ~= "None" then
            entry.textFx = form.textFx:lower()
        end
        if form.avatarOutline == "Off" then
            entry.avatarOutline = "off"
        end
        if form.showChip == "On" then
            entry.showChip = "on"
        end
        local tagsRaw = pick(form.tags, tbTags.Text)
        if tagsRaw ~= "" then
            local list = {}
            for t in (tagsRaw .. ","):gmatch("([^,]*),") do
                t = trimStr(t); if t ~= "" then list[#list+1] = t end
            end
            if #list > 0 then entry.tags = list end
        end
        -- if editing under a renamed key, drop old key first and clear the old player's live tag
        local oldKey = editingKey
        if oldKey and oldKey ~= key then
            TagDB.entries[oldKey] = nil
            TagDB.localEntries[oldKey] = nil
            applyToMatchingPlayer(oldKey)
        end
        TagDB.entries[key] = entry
        TagDB.localEntries[key] = entry
        applyToMatchingPlayer(u)
        rebuildList()
        clearForm()
        local sok, serr = TagDB:saveLocal()
        -- "writefile not available" just means the executor doesn't expose
        -- filesystem APIs — the tag is still applied in-game and (below)
        -- pushed to pastebin, so don't scare the user with a failure toast.
        local noFs = (not sok) and tostring(serr or ""):find("writefile not available", 1, true)
        if sok then
            notify("Saved tag for " .. u .. " — syncing to GitHub", "good")
        elseif noFs then
            notify("Saved tag for " .. u .. " — syncing to GitHub", "good")
        else
            notify("Saved tag for " .. u .. " — local save failed: " .. tostring(serr), "warn")
        end
        if _G.__SeigePbPush then task.spawn(_G.__SeigePbPush) end

    end)

    button(pgTags, "Clear form / new entry", function() clearForm() end)

    button(pgTags, "Apply all to server (refresh bubbles)", function()
        for _, p in ipairs(Players:GetPlayers()) do
            TagDB:applyTo(p)
            if tagBills[p] then
                pcall(NameHider.restore, p); pcall(function() tagBills[p].gui:Destroy() end)
                tagBills[p] = nil
            end
            pcall(buildBill, p)
        end
        notify("Refreshed all player tags", "good")
    end)

    button(pgTags, "Reload from GitHub (discards unsaved)", function()
        task.spawn(function()
            TagDB:load()
            for _, p in ipairs(Players:GetPlayers()) do
                TagDB:applyTo(p)
                if tagBills[p] then
                    pcall(NameHider.restore, p); pcall(function() tagBills[p].gui:Destroy() end)
                    tagBills[p] = nil
                end
                pcall(buildBill, p)
            end
            rebuildList()
            notify("Reloaded from GitHub", "good")
        end)
    end)

    button(pgTags, "Reapply current tag data", function()
        task.spawn(function()
            -- Fully tear down + rebuild every player's tag bubble from the
            -- current GitHub/cache data. Local override files are ignored.
            TagDB.appliedTags  = {}
            TagDB.appliedIcons = {}
            for _, p in ipairs(Players:GetPlayers()) do
                pcall(function() TagDB:applyTo(p) end)
                if tagBills[p] then
                    pcall(NameHider.restore, p)
                    pcall(function() tagBills[p].gui:Destroy() end)
                    tagBills[p] = nil
                end
                pcall(buildBill, p)
            end
            pcall(rebuildList)
            notify("Reapplied current tag data", "good")
        end)
    end)



    section(pgTags, "Export")
    local exportLbl = inst("TextLabel", pgTags, {
        Size = UDim2.new(1, -8, 0, 16),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextColor3 = T.dim,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = "Export of current tag data (auto-synced to GitHub; copy below if you need it manually):",
    })
    local exportFrame = inst("Frame", pgTags, {
        Size = UDim2.new(1, -8, 0, 120),
        BackgroundColor3 = T.bg2,
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
    })
    corner(exportFrame, 8); stroke(exportFrame, T.line, 1, 0.5)
    local exportBox = inst("TextBox", exportFrame, {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 8, 0, 8),
        Size = UDim2.new(1, -16, 1, -16),
        Font = Enum.Font.Code,
        TextSize = 11,
        TextColor3 = T.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        MultiLine = true,
        ClearTextOnFocus = false,
        Text = "",
    })

    local function buildExport()
        local out = { version = 2, format = TAGS_JSON_FORMAT, tags = {} }
        for k, e in pairs(TagDB.entries) do
            local key = normTagKey(k)
            local clean = cleanTagEntry(e)
            if key ~= "" and clean then out.tags[key] = clean end
        end
        local ok, encoded = pcall(function() return HttpService:JSONEncode(out) end)
        if ok and type(encoded) == "string" then return encoded end
        return '{"version":2,"format":"seige.tags.v2","tags":{}}'
    end


    button(pgTags, "Copy export to clipboard", function()
        local txt = buildExport()
        exportBox.Text = txt
        local clip = rawget(getfenv(), "setclipboard")
            or rawget(getfenv(), "toclipboard")
            or (syn and syn.write_clipboard)
        if clip then
            pcall(clip, txt)
            notify("Copied " .. (#txt) .. " chars to clipboard", "good")
        else
            notify("No clipboard support — copy from textbox below", "warn")
        end
    end)

    button(pgTags, "Show export text below", function()
        exportBox.Text = buildExport()
    end)

    ------------------------------------------------------------------
    -- GITHUB SYNC  ·  push in-game edits to the GitHub gist via our
    -- Lovable web endpoint. Credentials live server-side as secrets,
    -- so no API keys are needed in-game.
    ------------------------------------------------------------------
    section(pgTags, "GitHub sync")

    local PB_CFG_FILE = "seige_pastebin.json"
    local pbCfg = { autoPush = true, autoPull = true, pullInterval = 30 }

    do
        local rf = rawget(getfenv(), "readfile"); local isf = rawget(getfenv(), "isfile")
        if rf and isf and isf(PB_CFG_FILE) then
            local ok, data = pcall(function() return HttpService:JSONDecode(rf(PB_CFG_FILE)) end)
            if ok and type(data) == "table" then
                for k, v in pairs(data) do pbCfg[k] = v end
            end
        end
    end

    local function savePbCfg()
        local wf = rawget(getfenv(), "writefile")
        if wf then pcall(wf, PB_CFG_FILE, HttpService:JSONEncode(pbCfg)) end
    end

    -- Save through the same published host the loader reads from. This avoids
    -- preview/dev-domain bot pages being mistaken for a successful GitHub save.
    local BOT_URL  = "https://seigelollua.lovable.app/api/public/pastebin"
    local BOT_AUTH = "1f0957eaf8dd4ed89bb594440220eb4c"
    local lastPullHash = nil
    local lastPushHash = nil
    local lastPushAt = 0

    local function hashStr(s)
        s = tostring(s or "")
        local sum = 0
        for i = 1, #s do sum = (sum + s:byte(i) * i) % 2147483647 end
        return #s .. ":" .. sum
    end

    local function pushToGithub(silent)
        local body = buildExport()
        local payload = HttpService:JSONEncode({ body = body })
        local writeUrl = BOT_URL .. "?key=" .. HttpService:UrlEncode(BOT_AUTH)
        local getUrl = writeUrl .. "&body=" .. HttpService:UrlEncode(body)
        local headers = {
            ["Content-Type"]    = "application/json",
            ["x-pastebin-auth"] = BOT_AUTH,
        }
        local env = getfenv()
        local genv = (rawget(env, "getgenv") and getgenv()) or env
        -- Try every known executor HTTP request entry point. Different
        -- executors expose this under different names, so we cast a wide net.
        local req =
               rawget(genv, "request")
            or rawget(env,  "request")
            or rawget(genv, "http_request")
            or rawget(env,  "http_request")
            or rawget(genv, "httprequest")
            or (rawget(genv, "syn")    and syn.request)
            or (rawget(genv, "http")   and http.request)
            or (rawget(genv, "fluxus") and fluxus.request)
            or (rawget(genv, "krnl")   and krnl.request)
            or (rawget(genv, "Krnl")   and Krnl.request)
            or (rawget(genv, "WrapExecutor") and WrapExecutor.request)
        local function tryHttpService()
            return pcall(function()
                return HttpService:RequestAsync({ Url = writeUrl, Method = "POST", Headers = headers, Body = payload })
            end)
        end
        local function tryHttpPost()
            -- game:HttpPostAsync is exposed by some executors and works in
            -- LocalScripts where HttpService:RequestAsync is blocked.
            return pcall(function()
                return game:HttpPostAsync(writeUrl, payload, Enum.HttpContentType.ApplicationJson, false)
            end)
        end
        local function tryHttpGet()
            -- Most executors allow game:HttpGet even when POST/request APIs are
            -- blocked. The server accepts this signed GET write as a last-resort
            -- path so tag edits can still sync reliably from Roblox.
            return pcall(function()
                return game:HttpGet(getUrl, true)
            end)
        end
        local function savedOk(body)
            local ok, data = pcall(function() return HttpService:JSONDecode(tostring(body or "")) end)
            return ok and type(data) == "table" and data.ok == true
        end
        local status, txt = 0, ""
        if req then
            local ok, res = pcall(req, { Url = writeUrl, Method = "POST", Headers = headers, Body = payload })
            if ok and res then
                status = res.StatusCode or res.Status or 0
                txt = tostring(res.Body or "")
            end
        end
        if status < 200 or status >= 300 then
            local ok, res = tryHttpService()
            if ok and res then
                status = res.StatusCode or 0
                txt = tostring(res.Body or "")
            end
        end
        if status < 200 or status >= 300 then
            -- Final fallback: game:HttpPostAsync. Returns the response body
            -- as a string and raises on failure (already pcall'd).
            local ok, res = tryHttpPost()
            if ok and type(res) == "string" then
                -- Assume success if no HTTP error was raised.
                status = 200
                txt = res
            end
        end
        if status < 200 or status >= 300 then
            -- Final-final fallback: signed GET write through the same endpoint.
            local ok, res = tryHttpGet()
            if ok and type(res) == "string" then
                status = 200
                txt = res
            end
        end
        if status >= 200 and status < 300 and savedOk(txt) then
            lastPushHash = hashStr(body)
            lastPushAt = tick()
            lastPullHash = lastPushHash
            if not silent then notify("Pushed to GitHub gist", "good") end
            return true, "ok"
        end
        notify(("GitHub push failed: HTTP %s · %s"):format(tostring(status), txt:sub(1, 120)), "bad")
        return false, txt
    end



    toggle(pgTags, "Auto-push to GitHub on every save", pbCfg.autoPush, function(v)
        pbCfg.autoPush = v; savePbCfg()
    end)

    button(pgTags, "Push to GitHub now", function()
        task.spawn(function() pushToGithub(false) end)
    end)

    ------------------------------------------------------------------
    -- AUTO-PULL  ·  detect remote GitHub edits and reflect them in
    -- the in-game tag editor so changes made on the gist show up
    -- as editable entries without a rejoin.
    ------------------------------------------------------------------
    local function pullFromGithub(silent)
        local src
        local ok = pcall(function()
            src = game:HttpGet(TAGS_PASTEBIN_URL .. (TAGS_PASTEBIN_URL:find("?") and "&" or "?") .. "v=" .. tostring(os.time()))
        end)
        if not ok or not src or src == "" then
            if not silent then notify("GitHub pull failed", "bad") end
            return false, "fetch failed"
        end
        local h = hashStr(src)
        -- GitHub raw/gist reads can lag a few seconds after a write. Without this
        -- guard, auto-pull can immediately fetch the OLD blue tag JSON and
        -- overwrite the just-saved color/fill in memory, making Save look like it
        -- worked and then "reload" back to blue.
        if lastPushHash and h ~= lastPushHash and (tick() - lastPushAt) < 90 then
            if not silent then notify("GitHub is still updating — keeping your saved tag", "warn") end
            return true, "waiting for fresh push"
        end
        if lastPullHash and h == lastPullHash then
            if not silent then notify("GitHub: no changes", "dim") end
            return true, "unchanged"
        end
        lastPullHash = h
        local entries, count, isJson = parsePastebin(src)
        if count == 0 and not isJson then
            if not silent then notify("GitHub parse returned 0 entries", "warn") end
            return false, "empty parse"
        end
        TagDB.entries = entries
        TagDB:mergeLocal()
        for _, p in ipairs(Players:GetPlayers()) do
            pcall(function() TagDB:applyTo(p) end)
            if tagBills[p] then
                pcall(NameHider.restore, p); pcall(function() tagBills[p].gui:Destroy() end)
                tagBills[p] = nil
            end
            pcall(buildBill, p)
        end
        rebuildList()
        if not silent then notify(("Pulled %d tag entries from GitHub"):format(count), "good") end
        return true, "ok"
    end

    toggle(pgTags, "Auto-pull GitHub changes into editor", pbCfg.autoPull, function(v)
        pbCfg.autoPull = v; savePbCfg()
    end)

    button(pgTags, "Pull from GitHub now", function()
        task.spawn(function() pullFromGithub(false) end)
    end)

    bind(task.spawn(function()
        task.wait(2)
        pcall(function()
            local src = game:HttpGet(TAGS_PASTEBIN_URL .. (TAGS_PASTEBIN_URL:find("?") and "&" or "?") .. "v=" .. tostring(os.time()))
            if src and src ~= "" then lastPullHash = hashStr(src) end
        end)
        while true do
            local iv = tonumber(pbCfg.pullInterval) or 30
            if iv < 10 then iv = 10 end
            task.wait(iv)
            if pbCfg.autoPull then
                pcall(pullFromGithub, true)
            end
        end
    end))

    label(pgTags, "Tip: edits sync to a GitHub gist via the Lovable server. Auto-push uploads on every save; auto-pull reflects remote edits live.")

    -- Save button hook: ALWAYS push to GitHub on every save (overrides the
    -- autoPush toggle — every tag change must overwrite the remote copy).
    _G.__SeigePbPush = function() pushToGithub(true) end

    rebuildList()
  end -- end owner-only Tags manager

  ------------------------------------------------------------------
  -- NT TEAM TAGS  ·  limited Tags tab for users with role == "nt"
  -- They can ONLY edit: tag name(s), color (hex), and image (icon).
  -- No fonts, no pastebin
  -- sync, no export. Owner/Admin/Staff still see the full editor above.
  ------------------------------------------------------------------
  if _G.__SeigeMyRole() == "nt" then
    local pgNtTags = makeTab("Tags", "✎", "NT Team · edit tag name, color, image")
    if _G.__SeigeAudit then _G.__SeigeAudit("ui_open:nt_tags_tab", "NT tag editor mounted", true) end
    section(pgNtTags, "Tag editor (NT Team)")
    label(pgNtTags, "Limited editor — you can change tag names, colors and image only. Fonts and other settings are restricted.")

    local function _ntField(parent, lbl, ph)
        label(parent, lbl)
        local tb = inst("TextBox", parent, {
            Size = UDim2.new(1, -8, 0, 30),
            BackgroundColor3 = T.bg, BackgroundTransparency = 0.2,
            BorderSizePixel = 0,
            PlaceholderText = ph or "",
            PlaceholderColor3 = T.dim,
            Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = T.text,
            TextXAlignment = Enum.TextXAlignment.Left, Text = "",
            ClearTextOnFocus = false,
        })
        corner(tb, 6); stroke(tb, T.line, 1, 0.4)
        return tb
    end

    local ntUser   = _ntField(pgNtTags, "Username (required)", "e.g. SomeUser")
    local ntTags   = _ntField(pgNtTags, "Tag names (comma separated)", "Owner, Dev")
    local ntColor  = _ntField(pgNtTags, "Color (hex)", "#ff3b6b")
    local ntColor2 = _ntField(pgNtTags, "Second color (optional · split bubble)", "#00aaff")
    local ntIcon   = _ntField(pgNtTags, "Image / icon (Roblox asset ID)", "1234567890")

    local function _trim(s) return (tostring(s or ""):gsub("^%s+",""):gsub("%s+$","")) end

    local function loadFromKey(key)
        local e = TagDB.entries[key] or {}
        ntUser.Text   = key
        ntTags.Text   = (e.tags and table.concat(e.tags, ", ")) or ""
        -- Split combined "a/b" color form
        local c = tostring(e.color or "")
        if c:find("/") then
            local a, b = c:match("^([^/]+)/([^/]+)$")
            ntColor.Text  = a or ""
            ntColor2.Text = b or ""
        elseif c:sub(1,6) == "image:" then
            ntColor.Text = ""; ntColor2.Text = ""
            ntIcon.Text = c:sub(7)
        else
            ntColor.Text = c; ntColor2.Text = ""
        end
        if e.icon and e.icon ~= "" and ntIcon.Text == "" then
            ntIcon.Text = tostring(e.icon)
        end
    end

    button(pgNtTags, "Save / Update entry", function()
        local u = _trim(ntUser.Text):gsub("^@", "")
        if u == "" then notify("Username required", "bad"); return end
        local key = u:lower()
        -- Start from existing entry so we preserve fields NT can't edit
        -- (fonts, customText, displayName, outline, etc.).
        local existing = TagDB.entries[key] or {}
        local entry = {}
        for k, v in pairs(existing) do entry[k] = v end

        -- Tag names
        local tagsRaw = _trim(ntTags.Text)
        if tagsRaw ~= "" then
            local list = {}
            for t in (tagsRaw .. ","):gmatch("([^,]*),") do
                t = _trim(t); if t ~= "" then list[#list+1] = t end
            end
            entry.tags = (#list > 0) and list or nil
        else
            entry.tags = nil
        end

        -- Color (hex / split). Icon-color path is handled via the icon field.
        local c1 = _trim(ntColor.Text)
        local c2 = _trim(ntColor2.Text)
        if c1 ~= "" and c2 ~= "" then entry.color = c1 .. "/" .. c2
        elseif c1 ~= "" then entry.color = c1
        elseif c2 ~= "" then entry.color = c2
        else
            -- Don't blank out an existing color silently; only clear if it was a plain hex/split
            local cur = tostring(existing.color or "")
            if cur == "" or cur:find("^#") or cur:find("/") then entry.color = nil end
        end

        -- Image / icon
        local iconRaw = _trim(ntIcon.Text)
        if iconRaw ~= "" then
            local cleanId = iconRaw:gsub("rbxassetid://", ""):gsub("%D", "")
            if cleanId ~= "" then entry.icon = cleanId end
        else
            entry.icon = nil
        end

        TagDB.entries[key] = entry
        TagDB.localEntries[key] = entry
        if _G.__SeigeNtMarkSaved then pcall(_G.__SeigeNtMarkSaved, key) end

        -- Apply to the live player in this server, if present
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Name:lower() == key then pcall(function() TagDB:applyTo(p) end) end
        end

        local sok, serr = TagDB:saveLocal()
        if sok then notify("Saved tag for " .. u .. " — syncing to GitHub", "good")
        else notify("Saved (local-only) for " .. u .. ": " .. tostring(serr), "warn") end
        if _G.__SeigePbPush then task.spawn(_G.__SeigePbPush) end
    end)

    button(pgNtTags, "Clear form", function()
        ntUser.Text = ""; ntTags.Text = ""; ntColor.Text = ""
        ntColor2.Text = ""; ntIcon.Text = ""
    end)

    section(pgNtTags, "Existing entries (click to load)")
    local ntList = inst("ScrollingFrame", pgNtTags, {
        Size = UDim2.new(1, -8, 0, 220),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 4,
        BackgroundColor3 = T.bg2, BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
    })
    corner(ntList, 8); stroke(ntList, T.line, 1, 0.5)
    inst("UIListLayout", ntList, { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder })
    inst("UIPadding", ntList, {
        PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6),
        PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6),
    })

    local function rebuildNtList()
        for _, c in ipairs(ntList:GetChildren()) do
            if not (c:IsA("UIListLayout") or c:IsA("UIPadding") or c:IsA("UICorner") or c:IsA("UIStroke")) then
                c:Destroy()
            end
        end
        local keys = {}
        for k in pairs(TagDB.entries) do keys[#keys+1] = k end
        table.sort(keys)
        for _, k in ipairs(keys) do
            local e = TagDB.entries[k] or {}
            local row = inst("TextButton", ntList, {
                Size = UDim2.new(1, 0, 0, 32),
                BackgroundColor3 = T.bg3, BackgroundTransparency = 0.35,
                AutoButtonColor = false, BorderSizePixel = 0,
                Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = T.text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = "  @" .. k .. "   ·   " .. ((e.tags and table.concat(e.tags, ", ")) or "no tag"),
            })
            corner(row, 5); stroke(row, T.line, 1, 0.5)
            row.MouseButton1Click:Connect(function() loadFromKey(k) end)
        end
    end
    rebuildNtList()
    button(pgNtTags, "Refresh list", rebuildNtList)

    ------------------------------------------------------------------
    -- NT export (locked) — NT can format their edits as a pastebin
    -- line and copy it, but cannot push to pastebin. A popup tells
    -- them to contact the script owner to apply the change.
    ------------------------------------------------------------------
    section(pgNtTags, "Export (contact script owner)")
    label(pgNtTags, "NT Team cannot push to GitHub. Copy your tag line below and send it to the script owner to apply.")

    -- Track which keys this NT user saved in this session, so the
    -- export only includes their own changes (not the whole DB).
    local _ntSavedKeys = {}

    -- Hook into the existing Save button: re-add a marker on save.
    -- We do this by wrapping the save action via a side-effect button.
    -- (The original Save button still works — this one ALSO records.)
    local function _ntCurrentKey()
        local u = _trim(ntUser.Text)
        if u == "" then return nil end
        return u:lower()
    end

    local function _ntBuildLineFor(key)
        local e = TagDB.entries[key]; if not e then return nil end
        local tagsStr = (e.tags and table.concat(e.tags, ",")) or ""
        local fields = {
            key,
            e.displayName or "",
            e.color or "",
            "",
            e.icon or "",
            tagsStr,
            "",
            e.customText or "",
            e.customHandle or "",
            e.outline or "",
            e.font or "",
            "",
            "",
        }
        while #fields > 1 and (fields[#fields] == nil or fields[#fields] == "") do
            fields[#fields] = nil
        end
        return table.concat(fields, " | ")
    end


    local _ntPopupGui
    local function _ntShowContactPopup(text)
        if _ntPopupGui then pcall(function() _ntPopupGui:Destroy() end); _ntPopupGui = nil end
        local gui = inst("ScreenGui", nil, {
            Name = "SeigeNtExportPopup", IgnoreGuiInset = true, ResetOnSpawn = false,
            DisplayOrder = 240, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        })
        safeParent(gui); _ntPopupGui = gui
        -- dim backdrop
        local dim = inst("Frame", gui, {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 0.55, BorderSizePixel = 0, ZIndex = 240,
        })
        local win = inst("Frame", gui, {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0, 360, 0, 280),
            BackgroundColor3 = T.bg, BorderSizePixel = 0, ZIndex = 241,
        })
        corner(win, 10); stroke(win, T.acc, 1, 0.35)
        local bar = inst("Frame", win, {
            Size = UDim2.new(1, 0, 0, 34),
            BackgroundColor3 = T.bg2, BorderSizePixel = 0, ZIndex = 242,
        })
        corner(bar, 10)
        inst("TextLabel", bar, {
            BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 0),
            Size = UDim2.new(1, -44, 1, 0), Font = Enum.Font.GothamBold, TextSize = 13,
            TextColor3 = T.acc, TextXAlignment = Enum.TextXAlignment.Left,
            Text = "Contact script owner", ZIndex = 243,
        })
        local closeBtn = inst("TextButton", bar, {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.new(0, 22, 0, 22),
            BackgroundColor3 = T.bg3, BorderSizePixel = 0,
            Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = T.text,
            Text = "✕", ZIndex = 243,
        })
        corner(closeBtn, 6)
        closeBtn.MouseButton1Click:Connect(function() gui:Destroy(); _ntPopupGui = nil end)

        inst("TextLabel", win, {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 12, 0, 42),
            Size = UDim2.new(1, -24, 0, 50),
            Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = T.sub,
            TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            Text = "You don't have permission to push to GitHub. Copy the tag line below and send it to the script owner so they can apply your change.",
            ZIndex = 242,
        })

        local boxFrame = inst("Frame", win, {
            Position = UDim2.new(0, 12, 0, 100),
            Size = UDim2.new(1, -24, 0, 130),
            BackgroundColor3 = T.bg2, BackgroundTransparency = 0.2,
            BorderSizePixel = 0, ZIndex = 242,
        })
        corner(boxFrame, 8); stroke(boxFrame, T.line, 1, 0.5)
        local box = inst("TextBox", boxFrame, {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 8, 0, 8),
            Size = UDim2.new(1, -16, 1, -16),
            Font = Enum.Font.Code, TextSize = 11, TextColor3 = T.text,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true, MultiLine = true,
            ClearTextOnFocus = false,
            Text = text or "",
            ZIndex = 243,
        })

        local copyBtn = inst("TextButton", win, {
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, 12, 1, -12),
            Size = UDim2.new(0.5, -16, 0, 30),
            BackgroundColor3 = T.acc, BorderSizePixel = 0,
            Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = T.bg,
            Text = "Copy", ZIndex = 243,
        })
        corner(copyBtn, 6)
        copyBtn.MouseButton1Click:Connect(function()
            local clip = rawget(getfenv(), "setclipboard")
                or rawget(getfenv(), "toclipboard")
                or (syn and syn.write_clipboard)
            if clip then
                pcall(clip, box.Text)
                notify("Copied to clipboard", "good")
            else
                box:CaptureFocus()
                notify("No clipboard support — select text and copy manually", "warn")
            end
        end)
        local okBtn = inst("TextButton", win, {
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, -12, 1, -12),
            Size = UDim2.new(0.5, -16, 0, 30),
            BackgroundColor3 = T.bg3, BorderSizePixel = 0,
            Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = T.text,
            Text = "Close", ZIndex = 243,
        })
        corner(okBtn, 6)
        okBtn.MouseButton1Click:Connect(function() gui:Destroy(); _ntPopupGui = nil end)
    end

    button(pgNtTags, "Export current entry (copy + send to owner)", function()
        local key = _ntCurrentKey()
        if not key then notify("Enter a username first", "bad"); return end
        if not TagDB.entries[key] then
            notify("Save the entry first, then export", "warn"); return
        end
        _ntSavedKeys[key] = true
        local line = _ntBuildLineFor(key) or ""
        _ntShowContactPopup(line)
    end)

    button(pgNtTags, "Export all my saved changes (this session)", function()
        local lines = {}
        for k in pairs(_ntSavedKeys) do
            local ln = _ntBuildLineFor(k); if ln then lines[#lines+1] = ln end
        end
        if #lines == 0 then
            notify("No saved changes yet in this session", "warn"); return
        end
        table.sort(lines)
        _ntShowContactPopup(table.concat(lines, "\n"))
    end)

    -- Record saved keys whenever NT saves (wrap by listening for the
    -- Username text on each successful save via a small helper).
    -- We simply mark on every Save click that the current key is "saved".
    -- This is best-effort tracking — the per-entry export above also marks.
    _G.__SeigeNtMarkSaved = function(k) if k and k ~= "" then _ntSavedKeys[k:lower()] = true end end
  end -- end NT-only Tags

    ------------------------------------------------------------------
    -- ADMIN PANEL  ·  visible to OWNER (0rot3) and any user with a role
    -- Roles: admin (full + freeze), staff (8 cmds), nt (tag cmds + view).
    -- The owner manages role assignments in the "Roles & Permissions" section.
    ------------------------------------------------------------------
    local _myRole = _G.__SeigeMyRole() or "nt"
    local _isOwner = LP.Name == OWNER_NAME
    -- NT-only users get a tag-icon tab with just their command window.
    -- Staff/Admin/Owner get the full star "Admin" tab.
    local _ntOnly = (_myRole == "nt") and not _isOwner
    local _tabIcon  = _ntOnly and "✎" or "★"
    local _tabLabel = _ntOnly and "NT Cmds" or "Admin"
    local _tabSub   = _ntOnly
        and ("Role: " .. (_G.__SeigeRoleLabel(_myRole) or "NT Team") .. " · tag commands")
        or  ("Role: " .. (_G.__SeigeRoleLabel(_myRole) or "—") ..
             " · script users in this server" ..
             (_isOwner and ", role management, broadcast commands" or ""))
    local pgAdmin = makeTab(_tabLabel, _tabIcon, _tabSub)
    if _G.__SeigeAudit then
        _G.__SeigeAudit("ui_open:admin_panel",
            (_isOwner and "owner panel" or (_ntOnly and "nt panel" or "staff/admin panel"))
            .. " mounted as '" .. _tabLabel .. "'", true)
    end

    -- Banner showing current role + permission summary
    do
        local roleBanner = inst("Frame", pgAdmin, {
            Size = UDim2.new(1, -8, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = T.bg2, BackgroundTransparency = 0.2,
            BorderSizePixel = 0,
        })
        corner(roleBanner, 8); stroke(roleBanner, T.acc, 1, 0.4)
        inst("UIPadding", roleBanner, {
            PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10),
            PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12),
        })
        inst("UIListLayout", roleBanner, {
            Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder,
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
        })
        inst("TextLabel", roleBanner, {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = T.acc,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            Text = "Your role: " .. (_G.__SeigeRoleLabel(_myRole) or "—"),
            LayoutOrder = 1,
        })
        local perms = {}
        if _G.__SeigeCan("manage_roles") then perms[#perms+1] = "manage roles" end
        if _G.__SeigeCan("staff_cmd")    then perms[#perms+1] = "staff cmds" end
        if _G.__SeigeCan("bringall")     then perms[#perms+1] = "!bringall" end
        if _G.__SeigeCan("freeze")       then perms[#perms+1] = "!freeze / !unfreeze" end
        if _G.__SeigeCan("allp")         then perms[#perms+1] = "!allp" end
        if _G.__SeigeCan("lock")         then perms[#perms+1] = "!rmvp / !unrmvp" end
        if _G.__SeigeCan("usay")         then perms[#perms+1] = "!usay" end
        if _G.__SeigeCan("nt_cmd")       then perms[#perms+1] = "tag cmds" end
        if #perms == 0 then perms[#perms+1] = "view only" end
        inst("TextLabel", roleBanner, {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = T.sub,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            Text = "Permissions: " .. table.concat(perms, " · "),
            LayoutOrder = 2,
        })
    end

    ------------------------------------------------------------------
    -- AVAILABLE COMMANDS  ·  filtered by the viewer's role permissions
    -- Each command shows its syntax + description, with a one-click
    -- button. Commands taking <args> open the cmd bar prefilled; arg-
    -- free commands run instantly.
    ------------------------------------------------------------------
    section(pgAdmin, _ntOnly and "Your NT tag commands" or "Your available commands")
    label(pgAdmin, "Click Run to execute. Commands with <args> open the command bar prefilled so you can fill in the rest.")

    local cmdsList = inst("Frame", pgAdmin, {
        Size = UDim2.new(1, -8, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = T.bg2, BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
    })
    corner(cmdsList, 8); stroke(cmdsList, T.line, 1, 0.5)
    inst("UIListLayout", cmdsList, { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder })
    inst("UIPadding", cmdsList, {
        PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8),
    })

    local _myCmdCount = 0
    for _, item in ipairs(HELP_COMMANDS) do
        local allowed = false
        for _, p in ipairs(item.perms or {}) do
            if _G.__SeigeCan(p) then allowed = true; break end
        end
        if allowed then
            _myCmdCount = _myCmdCount + 1
            local row = inst("Frame", cmdsList, {
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = T.bg3, BackgroundTransparency = 0.35,
                BorderSizePixel = 0,
            })
            corner(row, 6); stroke(row, T.line, 1, 0.5)
            inst("UIPadding", row, {
                PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10),
                PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12),
            })

            -- Right side: action button (fixed width, vertically centered)
            local hasArgs = item.cmd:find("<") ~= nil
            local BTN_W = 96
            local btn = inst("TextButton", row, {
                Size = UDim2.new(0, BTN_W, 0, 30),
                Position = UDim2.new(1, -BTN_W, 0.5, -15),
                AnchorPoint = Vector2.new(0, 0),
                BackgroundColor3 = T.acc, BackgroundTransparency = 0.05,
                BorderSizePixel = 0, AutoButtonColor = true,
                Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = T.bg,
                Text = hasArgs and "Fill ▸" or "Run ▸",
            })
            corner(btn, 6)

            -- Left side: vertical text column that wraps and won't touch the button
            local textCol = inst("Frame", row, {
                Size = UDim2.new(1, -(BTN_W + 14), 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
            })
            inst("UIListLayout", textCol, {
                Padding = UDim.new(0, 4),
                SortOrder = Enum.SortOrder.LayoutOrder,
                HorizontalAlignment = Enum.HorizontalAlignment.Left,
            })
            inst("TextLabel", textCol, {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Font = Enum.Font.Code, TextSize = 13, TextColor3 = T.acc,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                TextWrapped = true,
                Text = item.cmd,
                LayoutOrder = 1,
            })
            inst("TextLabel", textCol, {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = T.sub,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                TextWrapped = true,
                Text = item.desc or "",
                LayoutOrder = 2,
            })

            btn.MouseButton1Click:Connect(function()
                local base = item.cmd:match("^(%S+)") or item.cmd
                if hasArgs then
                    if _G.__AdminOpenCmd then _G.__AdminOpenCmd(base .. " ") end
                else
                    if _G.__AdminRunCmd then _G.__AdminRunCmd(base) end
                end
            end)
        end
    end
    if _myCmdCount == 0 then
        label(cmdsList, "No commands available for your role.")
    end

    -- NT-only users only see the commands window above. Staff/Admin/Owner
    -- continue with the full script-users roster and management tools.
    if not _ntOnly then

    section(pgAdmin, "Script users in this server")
    label(pgAdmin, "Detected via chat heartbeat. Roblox doesn't expose IPs to client scripts — that requires a backend.")

    local usersList = inst("Frame", pgAdmin, {
        Size = UDim2.new(1, -8, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = T.bg2, BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
    })
    corner(usersList, 8); stroke(usersList, T.line, 1, 0.5)
    inst("UIListLayout", usersList, { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder })
    inst("UIPadding", usersList, {
        PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6),
        PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8),
    })
    local countLbl = label(pgAdmin, "0 users detected")

    local function rebuildUsers()
        for _, c in ipairs(usersList:GetChildren()) do
            if not (c:IsA("UIListLayout") or c:IsA("UIPadding") or c:IsA("UICorner") or c:IsA("UIStroke")) then
                c:Destroy()
            end
        end
        local reg = _G.__SeigeScriptUsers or {}
        local rows = {}
        for _, info in pairs(reg) do
            local plr = Players:GetPlayerByUserId(info.userId)
            if plr then rows[#rows+1] = { plr = plr, info = info } end
        end
        table.sort(rows, function(a, b) return a.plr.Name:lower() < b.plr.Name:lower() end)
        for _, r in ipairs(rows) do
            local plr, info = r.plr, r.info
            local entry = TagDB and TagDB.entries and TagDB.entries[plr.Name:lower()] or nil
            local row = inst("Frame", usersList, {
                Size = UDim2.new(1, 0, 0, 44),
                BackgroundColor3 = T.bg3, BackgroundTransparency = 0.35,
                BorderSizePixel = 0,
            })
            corner(row, 6); stroke(row, T.line, 1, 0.5)
            local av = inst("ImageLabel", row, {
                Size = UDim2.new(0, 32, 0, 32),
                Position = UDim2.new(0, 6, 0.5, -16),
                BackgroundColor3 = T.bg, BorderSizePixel = 0,
                Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(info.userId) .. "&w=48&h=48",
            })
            corner(av, 16)
            inst("TextLabel", row, {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 46, 0, 4), Size = UDim2.new(1, -54, 0, 18),
                Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = T.text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = (entry and entry.displayName) or plr.DisplayName or plr.Name,
            })
            local tagText = "no tag"
            if entry then
                local parts = {}
                if entry.tags and #entry.tags > 0 then for _, t in ipairs(entry.tags) do parts[#parts+1] = t end end
                tagText = (#parts > 0) and table.concat(parts, " · ") or "tagged"
            end
            inst("TextLabel", row, {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 46, 0, 22), Size = UDim2.new(1, -54, 0, 18),
                Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = T.sub,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = "@" .. plr.Name .. "  ·  " .. tagText,
            })
        end
        countLbl:set(#rows .. " user" .. (#rows == 1 and "" or "s") .. " detected")
    end
    rebuildUsers()
    button(pgAdmin, "Refresh list", rebuildUsers)
    task.spawn(function()
        while pgAdmin.Parent do task.wait(5); pcall(rebuildUsers) end
    end)

    ------------------------------------------------------------------
    -- ROLES & PERMISSIONS (owner-only)
    -- Add a Roblox username and assign one of: admin, staff, NT team.
    -- The Admin tab shows up for them on their next script load; their
    -- permissions follow the role table at the top of the script.
    ------------------------------------------------------------------
    if _G.__SeigeCan("manage_roles") then
        ------------------------------------------------------------------
        -- KILL SWITCH · global pause for every non-owner script user.
        -- When ON, every staff/admin/nt user is locked out of every
        -- command and every gated permission until the owner toggles
        -- it back off. Owner stays fully functional either way.
        ------------------------------------------------------------------
        section(pgAdmin, "Kill switch")
        label(pgAdmin, "Pause the whole script for every user except you (0rot3). Useful in emergencies.")

        local killCard = inst("Frame", pgAdmin, {
            Size = UDim2.new(1, -8, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = T.bg2, BackgroundTransparency = 0.25,
            BorderSizePixel = 0,
        })
        corner(killCard, 8); stroke(killCard, T.bad, 1.5, 0.35)
        inst("UIPadding", killCard, {
            PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12),
            PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14),
        })
        inst("UIListLayout", killCard, { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })

        local killStatus = inst("TextLabel", killCard, {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            Font = Enum.Font.GothamBold, TextSize = 14,
            TextColor3 = T.text,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            Text = "Status: ACTIVE — every script user can run commands",
            LayoutOrder = 1,
        })
        local killHint = inst("TextLabel", killCard, {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = T.sub,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            Text = "Toggling this broadcasts the new state to every script user via chat marker.",
            LayoutOrder = 2,
        })
        local killToggle = inst("TextButton", killCard, {
            Size = UDim2.new(1, 0, 0, 36), LayoutOrder = 3,
            BackgroundColor3 = T.good, BackgroundTransparency = 0.1, AutoButtonColor = false,
            Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = T.text,
            BorderSizePixel = 0,
            Text = "Activate kill switch",
        })
        corner(killToggle, 8); stroke(killToggle, T.line, 1, 0.4)

        local function refreshKillUI()
            local on = _G.__SeigeKilled == true
            if on then
                killStatus.Text = "Status: PAUSED — only the owner can run commands"
                killStatus.TextColor3 = T.bad
                killToggle.Text = "Deactivate kill switch"
                killToggle.BackgroundColor3 = T.bad
            else
                killStatus.Text = "Status: ACTIVE — every script user can run commands"
                killStatus.TextColor3 = T.good
                killToggle.Text = "Activate kill switch"
                killToggle.BackgroundColor3 = T.good
            end
        end
        refreshKillUI()
        if _G.__SeigeOnKill then _G.__SeigeOnKill(function() refreshKillUI() end) end
        killToggle.MouseButton1Click:Connect(function()
            local target = not (_G.__SeigeKilled == true)
            if _G.__SeigeKillBroadcast then
                local ok, err = _G.__SeigeKillBroadcast(target)
                if ok then
                    notify(target and "Kill switch ACTIVATED — all non-owner users paused"
                                   or "Kill switch deactivated — users resumed", target and "warn" or "good")
                else
                    notify("Kill switch failed: " .. tostring(err), "bad")
                end
            end
            refreshKillUI()
        end)

        ------------------------------------------------------------------
        -- AUDIT LOG · live feed of role-gated UI opens, toggles and
        -- command attempts on this client. Rolling buffer (250 entries).
        ------------------------------------------------------------------
        section(pgAdmin, "Audit log")
        label(pgAdmin, "Live record of role-gated UI opens, toggles and command attempts (player · role · time).")

        local auditCard = inst("Frame", pgAdmin, {
            Size = UDim2.new(1, -8, 0, 220),
            BackgroundColor3 = T.bg2, BackgroundTransparency = 0.25,
            BorderSizePixel = 0,
        })
        corner(auditCard, 8); stroke(auditCard, T.acc, 1, 0.35)
        inst("UIPadding", auditCard, {
            PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10),
            PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12),
        })

        local auditHeader = inst("Frame", auditCard, {
            Size = UDim2.new(1, 0, 0, 26),
            BackgroundTransparency = 1, BorderSizePixel = 0,
        })
        local auditCount = inst("TextLabel", auditHeader, {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -160, 1, 0),
            Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = T.acc,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = "0 entries",
        })
        local auditRefresh = inst("TextButton", auditHeader, {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -82, 0.5, 0), Size = UDim2.new(0, 74, 0, 24),
            BackgroundColor3 = T.bg3, BackgroundTransparency = 0.1,
            AutoButtonColor = false, BorderSizePixel = 0,
            Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = T.text,
            Text = "Refresh",
        })
        corner(auditRefresh, 6); stroke(auditRefresh, T.line, 1, 0.4)
        local auditClear = inst("TextButton", auditHeader, {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.new(0, 74, 0, 24),
            BackgroundColor3 = T.bad, BackgroundTransparency = 0.15,
            AutoButtonColor = false, BorderSizePixel = 0,
            Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = T.text,
            Text = "Clear",
        })
        corner(auditClear, 6); stroke(auditClear, T.line, 1, 0.4)

        local auditScroll = inst("ScrollingFrame", auditCard, {
            Position = UDim2.new(0, 0, 0, 32),
            Size = UDim2.new(1, 0, 1, -32),
            BackgroundColor3 = T.bg, BackgroundTransparency = 0.4,
            BorderSizePixel = 0,
            ScrollBarThickness = 3, ScrollBarImageColor3 = T.acc,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollingDirection = Enum.ScrollingDirection.Y,
        })
        corner(auditScroll, 6)
        inst("UIListLayout", auditScroll, {
            Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder,
        })
        inst("UIPadding", auditScroll, {
            PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6),
            PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8),
        })

        local function _fmtTime(t)
            local d = os.time() - (t or 0)
            if d < 5 then return "now"
            elseif d < 60 then return d .. "s ago"
            elseif d < 3600 then return math.floor(d/60) .. "m ago"
            else return math.floor(d/3600) .. "h ago" end
        end

        local function rebuildAudit()
            for _, c in ipairs(auditScroll:GetChildren()) do
                if c:IsA("Frame") then c:Destroy() end
            end
            local log = _G.__SeigeAuditLog or {}
            auditCount.Text = #log .. " entr" .. (#log == 1 and "y" or "ies")
            if #log == 0 then
                inst("TextLabel", auditScroll, {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 24),
                    Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = T.sub,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Text = "No events yet.",
                })
                return
            end
            -- Show newest first
            for i = #log, 1, -1 do
                local e = log[i]
                local row = inst("Frame", auditScroll, {
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundColor3 = e.allowed and T.bg2 or T.bad,
                    BackgroundTransparency = e.allowed and 0.45 or 0.7,
                    BorderSizePixel = 0,
                    LayoutOrder = (#log - i) + 1,
                })
                corner(row, 4)
                inst("UIPadding", row, {
                    PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4),
                    PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8),
                })
                inst("TextLabel", row, {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 14),
                    Font = Enum.Font.GothamBold, TextSize = 11,
                    TextColor3 = e.allowed and T.acc or T.bad,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Text = string.format("%s  ·  %s  ·  %s%s",
                        e.player or "?", e.role or "?", _fmtTime(e.t),
                        e.allowed and "" or "  ·  BLOCKED"),
                })
                inst("TextLabel", row, {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 0, 0, 16),
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = T.text,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextWrapped = true,
                    Text = (e.action or "") .. (e.detail ~= "" and ("  —  " .. e.detail) or ""),
                })
            end
        end
        rebuildAudit()
        if _G.__SeigeOnAudit then _G.__SeigeOnAudit(function() rebuildAudit() end) end
        auditRefresh.MouseButton1Click:Connect(rebuildAudit)
        auditClear.MouseButton1Click:Connect(function()
            if _G.__SeigeClearAudit then _G.__SeigeClearAudit() end
            rebuildAudit()
            notify("Audit log cleared", "good")
        end)

        section(pgAdmin, "Roles & permissions")
        label(pgAdmin, "Click any staff card to manage them. Owner (0rot3) is hardcoded and cannot be changed.")

        local ROLE_ORDER  = { "admin", "staff", "nt" }
        local ROLE_COLORS = { owner = T.bad, admin = T.acc, staff = T.good, nt = T.sub }

        -- Cache username → userId so avatars persist across rebuilds.
        local _userIdCache = {}
        local function _avatarFor(name)
            local lower = name:lower()
            local uid = _userIdCache[lower]
            if uid then return "rbxthumb://type=AvatarHeadShot&id=" .. uid .. "&w=48&h=48" end
            -- Try live player first
            local plr = Players:FindFirstChild(name)
            if plr then
                _userIdCache[lower] = plr.UserId
                return "rbxthumb://type=AvatarHeadShot&id=" .. plr.UserId .. "&w=48&h=48"
            end
            return nil
        end
        local function _resolveUserIdAsync(name, cb)
            local lower = name:lower()
            if _userIdCache[lower] then cb(_userIdCache[lower]); return end
            task.spawn(function()
                local ok, id = pcall(function() return Players:GetUserIdFromNameAsync(name) end)
                if ok and id then _userIdCache[lower] = id; cb(id) end
            end)
        end

        -- Selected staff state (drives the editor card below)
        local selected = nil  -- { name = string, role = string }

        local rolesScroll = inst("ScrollingFrame", pgAdmin, {
            Size = UDim2.new(1, -8, 0, 240),
            BackgroundColor3 = T.bg2, BackgroundTransparency = 0.4,
            BorderSizePixel = 0,
            ScrollBarThickness = 4, ScrollBarImageColor3 = T.acc,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            CanvasSize = UDim2.new(0, 0, 0, 0),
        })
        corner(rolesScroll, 8); stroke(rolesScroll, T.line, 1, 0.5)
        inst("UIListLayout", rolesScroll, { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder })
        inst("UIPadding", rolesScroll, {
            PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8),
            PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8),
        })

        local rolesCountLbl = label(pgAdmin, "0 roles configured (owner is hardcoded)")

        ----------------------------------------------------------------
        -- Editor card: shows the currently selected staff and lets you
        -- change their role or remove them. Hidden until something is
        -- selected. Also doubles as the "add new staff" entry point.
        ----------------------------------------------------------------
        local editor = inst("Frame", pgAdmin, {
            Size = UDim2.new(1, -8, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = T.bg2, BackgroundTransparency = 0.25,
            BorderSizePixel = 0,
        })
        corner(editor, 8); stroke(editor, T.acc, 1, 0.5)
        inst("UIPadding", editor, {
            PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12),
            PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12),
        })
        inst("UIListLayout", editor, { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })

        -- Header row: avatar + name + current role pill
        local headerRow = inst("Frame", editor, {
            Size = UDim2.new(1, 0, 0, 56), BackgroundTransparency = 1, LayoutOrder = 1,
        })
        local editAv = inst("ImageLabel", headerRow, {
            Size = UDim2.new(0, 48, 0, 48),
            Position = UDim2.new(0, 0, 0.5, -24),
            BackgroundColor3 = T.bg, BorderSizePixel = 0,
        })
        corner(editAv, 24); stroke(editAv, T.acc, 1, 0.4)
        local editName = inst("TextLabel", headerRow, {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 58, 0, 6), Size = UDim2.new(1, -58, 0, 20),
            Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = T.text,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = "No staff selected",
        })
        local editRolePill = inst("TextLabel", headerRow, {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 58, 0, 30), Size = UDim2.new(1, -58, 0, 18),
            Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = T.sub,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = "Pick someone from the list or enter a new username below.",
        })

        -- Username box (used when adding a brand-new staff)
        local nameBox = inst("TextBox", editor, {
            BackgroundColor3 = T.bg, BackgroundTransparency = 0.2,
            Size = UDim2.new(1, 0, 0, 30), LayoutOrder = 2,
            PlaceholderText = "Roblox username (to add a new staff)",
            PlaceholderColor3 = T.dim,
            Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = T.text,
            TextXAlignment = Enum.TextXAlignment.Left, Text = "",
            ClearTextOnFocus = false,
        })
        corner(nameBox, 6); stroke(nameBox, T.line, 1, 0.4)

        -- Role chips (act immediately on selected/typed user)
        local chipsRow = inst("Frame", editor, {
            Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, LayoutOrder = 3,
        })
        inst("UIListLayout", chipsRow, {
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })

        local roleBtns = {}
        local rebuildRoles  -- forward
        local function applyRole(role)
            local target = (selected and selected.name) or ((nameBox.Text or ""):gsub("^%s+",""):gsub("%s+$",""))
            if target == "" then notify("Pick a staff or type a username first", "warn"); return end
            if target:lower() == OWNER_NAME:lower() then notify("Owner is hardcoded", "warn"); return end
            local ok, err = _G.__SeigeSetRole(target, role)
            if ok then
                notify("@" .. target .. " → " .. (_G.__SeigeRoleLabel(role) or role), "good")
                selected = { name = target, role = role }
                nameBox.Text = ""
                if rebuildRoles then rebuildRoles() end
            else
                notify("Failed: " .. tostring(err), "bad")
            end
        end

        for i, r in ipairs(ROLE_ORDER) do
            local b = inst("TextButton", chipsRow, {
                Size = UDim2.new(0, 90, 0, 28),
                BackgroundColor3 = ROLE_COLORS[r] or T.bg3, BackgroundTransparency = 0.15,
                AutoButtonColor = false, BorderSizePixel = 0,
                Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = T.text,
                Text = "● " .. (_G.__SeigeRoleLabel(r) or r),
                LayoutOrder = i,
            })
            corner(b, 6); stroke(b, T.line, 1, 0.4)
            b.MouseButton1Click:Connect(function() applyRole(r) end)
            roleBtns[r] = b
        end

        -- Remove button (only meaningful when a staff is selected)
        local removeBtn = inst("TextButton", editor, {
            Size = UDim2.new(1, 0, 0, 26), LayoutOrder = 4,
            BackgroundColor3 = T.bad, BackgroundTransparency = 0.2, AutoButtonColor = false,
            Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = T.text,
            Text = "Remove selected staff",
            Visible = false,
        })
        corner(removeBtn, 6); stroke(removeBtn, T.line, 1, 0.4)
        removeBtn.MouseButton1Click:Connect(function()
            if not selected then return end
            local ok, err = _G.__SeigeSetRole(selected.name, nil)
            if ok then
                notify("Removed @" .. selected.name, "good")
                selected = nil
                if rebuildRoles then rebuildRoles() end
            else
                notify("Remove failed: " .. tostring(err), "bad")
            end
        end)

        local function updateEditor()
            if selected then
                editName.Text = "@" .. selected.name
                editRolePill.Text = "Current role: " .. (_G.__SeigeRoleLabel(selected.role) or selected.role)
                editRolePill.TextColor3 = ROLE_COLORS[selected.role] or T.sub
                removeBtn.Visible = true
                local img = _avatarFor(selected.name)
                if img then editAv.Image = img
                else
                    editAv.Image = ""
                    _resolveUserIdAsync(selected.name, function(id)
                        if selected and selected.name:lower() == (selected.name):lower() then
                            editAv.Image = "rbxthumb://type=AvatarHeadShot&id=" .. id .. "&w=48&h=48"
                        end
                    end)
                end
            else
                editName.Text = "No staff selected"
                editRolePill.Text = "Pick someone from the list or enter a new username below."
                editRolePill.TextColor3 = T.sub
                removeBtn.Visible = false
                editAv.Image = ""
            end
        end
        updateEditor()

        ----------------------------------------------------------------
        -- Build the clickable staff list
        ----------------------------------------------------------------
        rebuildRoles = function()
            for _, c in ipairs(rolesScroll:GetChildren()) do
                if not (c:IsA("UIListLayout") or c:IsA("UIPadding") or c:IsA("UICorner") or c:IsA("UIStroke")) then
                    c:Destroy()
                end
            end

            local entries = {}
            entries[#entries+1] = { name = OWNER_NAME, role = "owner", locked = true }
            for nm, r in pairs(_G.__SeigeRoleMap or {}) do
                entries[#entries+1] = { name = nm, role = r, locked = false }
            end
            table.sort(entries, function(a, b)
                if a.role == "owner" then return true end
                if b.role == "owner" then return false end
                return a.name:lower() < b.name:lower()
            end)

            for _, e in ipairs(entries) do
                local isSelected = selected and selected.name:lower() == e.name:lower()
                local card = inst("TextButton", rolesScroll, {
                    Size = UDim2.new(1, 0, 0, 58),
                    BackgroundColor3 = isSelected and T.acc or T.bg3,
                    BackgroundTransparency = isSelected and 0.05 or 0.35,
                    AutoButtonColor = false, BorderSizePixel = 0,
                    Text = "", AutoLocalize = false,
                })
                corner(card, 8); stroke(card, isSelected and T.acc or T.line, 1, isSelected and 0.1 or 0.5)

                -- Avatar
                local av = inst("ImageLabel", card, {
                    Size = UDim2.new(0, 42, 0, 42),
                    Position = UDim2.new(0, 8, 0.5, -21),
                    BackgroundColor3 = T.bg, BorderSizePixel = 0,
                })
                corner(av, 21)
                local img = _avatarFor(e.name)
                if img then av.Image = img
                else
                    _resolveUserIdAsync(e.name, function(id)
                        av.Image = "rbxthumb://type=AvatarHeadShot&id=" .. id .. "&w=48&h=48"
                    end)
                end

                -- Name
                inst("TextLabel", card, {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 58, 0, 8), Size = UDim2.new(1, -150, 0, 18),
                    Font = Enum.Font.GothamBold, TextSize = 13,
                    TextColor3 = isSelected and T.bg or T.text,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Text = "@" .. e.name,
                })
                -- Role badge
                inst("TextLabel", card, {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 58, 0, 30), Size = UDim2.new(1, -150, 0, 18),
                    Font = Enum.Font.Gotham, TextSize = 11,
                    TextColor3 = isSelected and T.bg or (ROLE_COLORS[e.role] or T.sub),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Text = "● " .. (_G.__SeigeRoleLabel(e.role) or e.role) .. (e.locked and "  ·  hardcoded" or ""),
                })
                -- Tap-to-edit hint
                inst("TextLabel", card, {
                    BackgroundTransparency = 1,
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.new(0, 90, 0, 18),
                    Font = Enum.Font.Gotham, TextSize = 10,
                    TextColor3 = isSelected and T.bg or T.dim,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    Text = e.locked and "owner" or (isSelected and "selected" or "tap to edit"),
                })

                card.MouseButton1Click:Connect(function()
                    if e.locked then
                        notify("Owner is hardcoded and cannot be edited", "warn")
                        return
                    end
                    selected = { name = e.name, role = e.role }
                    updateEditor()
                    rebuildRoles()
                end)
            end

            local n = 0
            for _ in pairs(_G.__SeigeRoleMap or {}) do n = n + 1 end
            rolesCountLbl:set(n .. " role" .. (n == 1 and "" or "s") .. " configured (owner is hardcoded)")
            updateEditor()
        end

        rebuildRoles()
    end

    if _G.__SeigeCan("allp") then
    section(pgAdmin, "Admin commands")
    label(pgAdmin, "!allp <message> — sends a private top-banner toast to every script user in this server.")

    -- !allp composer
    local allpFrame = inst("Frame", pgAdmin, {
        Size = UDim2.new(1, -8, 0, 76),
        BackgroundColor3 = T.bg2, BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
    })
    corner(allpFrame, 8); stroke(allpFrame, T.line, 1, 0.5)
    local allpBox = inst("TextBox", allpFrame, {
        BackgroundColor3 = T.bg, BackgroundTransparency = 0.2,
        Position = UDim2.new(0, 10, 0, 10), Size = UDim2.new(1, -20, 0, 30),
        PlaceholderText = "Message to broadcast (≤280 chars)…",
        PlaceholderColor3 = T.dim,
        Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = T.text,
        TextXAlignment = Enum.TextXAlignment.Left, Text = "",
        ClearTextOnFocus = false,
    })
    corner(allpBox, 6); stroke(allpBox, T.line, 1, 0.4)
    local sendBtn = inst("TextButton", allpFrame, {
        Position = UDim2.new(0, 10, 0, 44), Size = UDim2.new(1, -20, 0, 26),
        BackgroundColor3 = T.acc, BackgroundTransparency = 0.1, AutoButtonColor = false,
        Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = T.text,
        Text = "Send !allp to all script users",
    })
    corner(sendBtn, 6); stroke(sendBtn, T.line, 1, 0.4)
    sendBtn.MouseButton1Click:Connect(function()
        local txt = allpBox.Text or ""
        if txt:gsub("%s", "") == "" then notify("Type a message first", "warn"); return end
        if cmdHandlers and cmdHandlers["allp"] then
            cmdHandlers["allp"](txt)
            allpBox.Text = ""
        else
            notify("Command not ready", "bad")
        end
    end)
    end -- end !allp gate

    if _G.__SeigeCan("lock") then
    section(pgAdmin, "Lockout (!rmvp / !unrmvp)")
    label(pgAdmin, "Locks the target user out of the script. Persists on their machine until !unrmvp.")
    local lockFrame = inst("Frame", pgAdmin, {
        Size = UDim2.new(1, -8, 0, 80),
        BackgroundColor3 = T.bg2, BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
    })
    corner(lockFrame, 8); stroke(lockFrame, T.line, 1, 0.5)
    local lockBox = inst("TextBox", lockFrame, {
        BackgroundColor3 = T.bg, BackgroundTransparency = 0.2,
        Position = UDim2.new(0, 10, 0, 10), Size = UDim2.new(1, -20, 0, 28),
        PlaceholderText = "Roblox username (e.g. SomeUser)",
        PlaceholderColor3 = T.dim,
        Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = T.text,
        TextXAlignment = Enum.TextXAlignment.Left, Text = "",
        ClearTextOnFocus = false,
    })
    corner(lockBox, 6); stroke(lockBox, T.line, 1, 0.4)
    local lockBtn = inst("TextButton", lockFrame, {
        Position = UDim2.new(0, 10, 0, 44), Size = UDim2.new(0.5, -14, 0, 26),
        BackgroundColor3 = T.bad, BackgroundTransparency = 0.1, AutoButtonColor = false,
        Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = T.text,
        Text = "!rmvp · lock",
    })
    corner(lockBtn, 6); stroke(lockBtn, T.line, 1, 0.4)
    local unlockBtn = inst("TextButton", lockFrame, {
        Position = UDim2.new(0.5, 4, 0, 44), Size = UDim2.new(0.5, -14, 0, 26),
        BackgroundColor3 = T.good, BackgroundTransparency = 0.1, AutoButtonColor = false,
        Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = T.text,
        Text = "!unrmvp · unlock",
    })
    corner(unlockBtn, 6); stroke(unlockBtn, T.line, 1, 0.4)
    lockBtn.MouseButton1Click:Connect(function()
        local n = lockBox.Text or ""
        if n:gsub("%s", "") == "" then notify("Enter a username", "warn"); return end
        if cmdHandlers and cmdHandlers["rmvp"] then cmdHandlers["rmvp"](n); lockBox.Text = "" end
    end)
    unlockBtn.MouseButton1Click:Connect(function()
        local n = lockBox.Text or ""
        if n:gsub("%s", "") == "" then notify("Enter a username", "warn"); return end
        if cmdHandlers and cmdHandlers["unrmvp"] then cmdHandlers["unrmvp"](n); lockBox.Text = "" end
    end)
    end -- end !rmvp gate

    if _G.__SeigeCan("usay") then
    section(pgAdmin, "Force chat (!usay)")
    label(pgAdmin, "Makes the target user's own client send a chat message in game. Target must be running the script in this server.")
    local usayFrame = inst("Frame", pgAdmin, {
        Size = UDim2.new(1, -8, 0, 116),
        BackgroundColor3 = T.bg2, BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
    })
    corner(usayFrame, 8); stroke(usayFrame, T.line, 1, 0.5)
    local usayUser = inst("TextBox", usayFrame, {
        BackgroundColor3 = T.bg, BackgroundTransparency = 0.2,
        Position = UDim2.new(0, 10, 0, 10), Size = UDim2.new(1, -20, 0, 28),
        PlaceholderText = "Target username", PlaceholderColor3 = T.dim,
        Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = T.text,
        TextXAlignment = Enum.TextXAlignment.Left, Text = "",
        ClearTextOnFocus = false,
    })
    corner(usayUser, 6); stroke(usayUser, T.line, 1, 0.4)
    local usayMsg = inst("TextBox", usayFrame, {
        BackgroundColor3 = T.bg, BackgroundTransparency = 0.2,
        Position = UDim2.new(0, 10, 0, 44), Size = UDim2.new(1, -20, 0, 28),
        PlaceholderText = "Message to send as them (≤200 chars)", PlaceholderColor3 = T.dim,
        Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = T.text,
        TextXAlignment = Enum.TextXAlignment.Left, Text = "",
        ClearTextOnFocus = false,
    })
    corner(usayMsg, 6); stroke(usayMsg, T.line, 1, 0.4)
    local usayBtn = inst("TextButton", usayFrame, {
        Position = UDim2.new(0, 10, 0, 80), Size = UDim2.new(1, -20, 0, 26),
        BackgroundColor3 = T.acc, BackgroundTransparency = 0.1, AutoButtonColor = false,
        Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = T.text,
        Text = "Send !usay",
    })
    corner(usayBtn, 6); stroke(usayBtn, T.line, 1, 0.4)
    usayBtn.MouseButton1Click:Connect(function()
        local u = (usayUser.Text or ""):gsub("^%s+", ""):gsub("%s+$", "")
        local m = (usayMsg.Text or ""):gsub("^%s+", ""):gsub("%s+$", "")
        if u == "" then notify("Enter a target user", "warn"); return end
        if m == "" then notify("Enter a message", "warn"); return end
        if cmdHandlers and cmdHandlers["usay"] then
            cmdHandlers["usay"](u .. " " .. m)
            usayMsg.Text = ""
        end
    end)

    section(pgAdmin, "Quick !usay from targets")
    label(pgAdmin, "Pick a detected script user below, type a message, and preview before sending.")

    local selectedUsayTarget = nil
    local usayTargetRows = {}

    local targetsFrame = inst("Frame", pgAdmin, {
        Size = UDim2.new(1, -8, 0, 180),
        BackgroundColor3 = T.bg2, BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
    })
    corner(targetsFrame, 8); stroke(targetsFrame, T.line, 1, 0.5)
    local targetsScroll = inst("ScrollingFrame", targetsFrame, {
        Size = UDim2.new(1, -4, 1, -4),
        Position = UDim2.new(0, 2, 0, 2),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 3, ScrollBarImageColor3 = T.acc,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(0, 0, 0, 0),
    })
    local targetsLayout = inst("UIListLayout", targetsScroll, {
        Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder,
    })
    inst("UIPadding", targetsScroll, {
        PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4),
        PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4),
    })

    local function rebuildTargetList()
        for _, c in ipairs(targetsScroll:GetChildren()) do
            if not (c:IsA("UIListLayout") or c:IsA("UIPadding") or c:IsA("UICorner") or c:IsA("UIStroke")) then
                c:Destroy()
            end
        end
        usayTargetRows = {}
        local reg = _G.__SeigeScriptUsers or {}
        local rows = {}
        for _, info in pairs(reg) do
            local plr = Players:GetPlayerByUserId(info.userId)
            if plr then rows[#rows+1] = { plr = plr, info = info } end
        end
        table.sort(rows, function(a, b) return a.plr.Name:lower() < b.plr.Name:lower() end)
        for _, r in ipairs(rows) do
            local plr = r.plr
            local row = inst("TextButton", targetsScroll, {
                Size = UDim2.new(1, 0, 0, 38),
                BackgroundColor3 = T.bg3, BackgroundTransparency = 0.35,
                BorderSizePixel = 0, AutoButtonColor = false,
                Text = "",
            })
            corner(row, 6); stroke(row, T.line, 1, 0.5)
            local av = inst("ImageLabel", row, {
                Size = UDim2.new(0, 28, 0, 28),
                Position = UDim2.new(0, 6, 0.5, -14),
                BackgroundColor3 = T.bg, BorderSizePixel = 0,
                Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(r.info.userId) .. "&w=48&h=48",
            })
            corner(av, 14)
            local nameLbl = inst("TextLabel", row, {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 40, 0, 4), Size = UDim2.new(1, -48, 0, 16),
                Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = T.text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = plr.DisplayName or plr.Name,
            })
            inst("TextLabel", row, {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 40, 0, 20), Size = UDim2.new(1, -48, 0, 14),
                Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = T.sub,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = "@" .. plr.Name,
            })
            row.MouseEnter:Connect(function()
                if selectedUsayTarget ~= plr.Name then
                    tween(row, 0.12, { BackgroundColor3 = T.bg3, BackgroundTransparency = 0.15 })
                end
            end)
            row.MouseLeave:Connect(function()
                if selectedUsayTarget ~= plr.Name then
                    tween(row, 0.12, { BackgroundColor3 = T.bg3, BackgroundTransparency = 0.35 })
                end
            end)
            row.MouseButton1Click:Connect(function()
                selectedUsayTarget = plr.Name
                for _, other in ipairs(usayTargetRows) do
                    tween(other, 0.12, { BackgroundColor3 = T.bg3, BackgroundTransparency = 0.35 })
                    other:FindFirstChildOfClass("UIStroke").Color = T.line
                end
                tween(row, 0.12, { BackgroundColor3 = T.acc, BackgroundTransparency = 0.2 })
                row:FindFirstChildOfClass("UIStroke").Color = T.acc
                usayUser.Text = plr.Name
            end)
            table.insert(usayTargetRows, row)
        end
        if #rows == 0 then
            local empty = inst("TextLabel", targetsScroll, {
                Size = UDim2.new(1, 0, 0, 38),
                BackgroundTransparency = 1,
                Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = T.dim,
                Text = "No script users detected in this server.",
            })
        end
    end
    rebuildTargetList()
    task.spawn(function()
        while targetsFrame.Parent do task.wait(5); pcall(rebuildTargetList) end
    end)

    local quickMsg = inst("TextBox", pgAdmin, {
        Size = UDim2.new(1, -8, 0, 28),
        BackgroundColor3 = T.bg, BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
        PlaceholderText = "Message to send as the selected user…", PlaceholderColor3 = T.dim,
        Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = T.text,
        TextXAlignment = Enum.TextXAlignment.Left, Text = "",
        ClearTextOnFocus = false,
    })
    corner(quickMsg, 6); stroke(quickMsg, T.line, 1, 0.4)

    local previewLbl = label(pgAdmin, "Preview: (select a user and type a message)")
    local function updatePreview()
        local t = selectedUsayTarget or "(no user selected)"
        local m = quickMsg.Text
        if m == "" then m = "…" end
        previewLbl:set(t .. " will say:  \"" .. m .. "\"")
    end
    quickMsg:GetPropertyChangedSignal("Text"):Connect(updatePreview)

    local quickSend = inst("TextButton", pgAdmin, {
        Size = UDim2.new(1, -8, 0, 28),
        BackgroundColor3 = T.acc, BackgroundTransparency = 0.1, AutoButtonColor = false,
        Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = T.text,
        Text = "Send !usay to selected target",
    })
    corner(quickSend, 6); stroke(quickSend, T.line, 1, 0.4)
    quickSend.MouseEnter:Connect(function() tween(quickSend, 0.15, {BackgroundColor3 = T.acc2}) end)
    quickSend.MouseLeave:Connect(function() tween(quickSend, 0.15, {BackgroundColor3 = T.acc}) end)
    quickSend.MouseButton1Click:Connect(function()
        local u = selectedUsayTarget
        local m = (quickMsg.Text or ""):gsub("^%s+", ""):gsub("%s+$", "")
        if not u or u == "" then notify("Select a target from the list first", "warn"); return end
        if m == "" then notify("Type a message first", "warn"); return end
        if cmdHandlers and cmdHandlers["usay"] then
            cmdHandlers["usay"](u .. " " .. m)
            quickMsg.Text = ""
            updatePreview()
        end
    end)
    end -- end !usay gate
    end -- end if not _ntOnly (script-users + management sections)
end)() end





------------------------------------------------------- ENABLE PLAYER TAGS PROMPT
task.delay(2.2, function()
    local prompt = inst("Frame", Root, {
        Name = "TagPrompt",
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -18, 1, 60),
        Size = UDim2.new(0, 280, 0, 96),
        BackgroundColor3 = T.glass,
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        ZIndex = 400,
    })
    corner(prompt, 12)
    stroke(prompt, T.acc, 1, 0.4)
    inst("UIGradient", prompt, {
        Rotation = 120,
        Color = ColorSequence.new(T.bg2, T.glass),
    })

    local dot = inst("Frame", prompt, {
        Position = UDim2.new(0, 12, 0, 12), Size = UDim2.new(0, 8, 0, 8),
        BackgroundColor3 = T.acc, BorderSizePixel = 0, ZIndex = 401,
    })
    corner(dot, 4)
    inst("TextLabel", prompt, {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 28, 0, 8),
        Size = UDim2.new(1, -36, 0, 16),
        Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = T.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = "Enable player tags",
        ZIndex = 401,
    })
    inst("TextLabel", prompt, {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 30),
        Size = UDim2.new(1, -24, 0, 30),
        Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = T.sub,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true,
        Text = "Show display names and usernames floating above every player.",
        ZIndex = 401,
    })

    local function mkBtn(parent, txt, primary)
        local b = inst("TextButton", parent, {
            BackgroundColor3 = primary and T.acc2 or T.bg3,
            BorderSizePixel = 0, AutoButtonColor = false,
            Font = Enum.Font.GothamBold, TextSize = 11,
            TextColor3 = T.text, Text = txt, ZIndex = 401,
        })
        corner(b, 8)
        if not primary then stroke(b, T.line, 1, 0.4) end
        return b
    end

    local enableBtn = mkBtn(prompt, "Enable", true)
    enableBtn.AnchorPoint = Vector2.new(1, 1)
    enableBtn.Position = UDim2.new(1, -10, 1, -10)
    enableBtn.Size = UDim2.new(0, 84, 0, 26)

    local dismissBtn = mkBtn(prompt, "Dismiss", false)
    dismissBtn.AnchorPoint = Vector2.new(1, 1)
    dismissBtn.Position = UDim2.new(1, -102, 1, -10)
    dismissBtn.Size = UDim2.new(0, 76, 0, 26)

    local function slideOut()
        TweenService:Create(prompt, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            { Position = UDim2.new(1, -18, 1, 120) }):Play()
        task.delay(0.35, function() prompt:Destroy() end)
    end

    enableBtn.MouseButton1Click:Connect(function()
        -- Show tags for OTHER seige.lol users in this server (not every player).
        -- The cross-game presence heartbeat populates _G.__SeigeScripters with
        -- userIds whose jobId matches ours, and syncScripterBills() adds a
        -- bubble for each of them without rebuilding LP's tag (no glitch).
        scriptersOn = true
        if _G.__SeigeSyncScripterBills then pcall(_G.__SeigeSyncScripterBills) end
        local n = 0
        for _ in pairs(_G.__SeigeScripters or {}) do n = n + 1 end
        if _G.__SeigePresenceRefresh then pcall(_G.__SeigePresenceRefresh) end
        if notify then
            pcall(notify, ("Scripter tags on · %d nearby"):format(n), n > 0 and "good" or "warn")
        end
        slideOut()
    end)
    dismissBtn.MouseButton1Click:Connect(function() slideOut() end)

    -- slide in
    TweenService:Create(prompt, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        { Position = UDim2.new(1, -18, 1, -18) }):Play()
end)



------------------------------------------------------- COMMANDS LIST (Cmds tab)
section(pgCmds, "Commands  ·  also work in Roblox chat & F6 bar")

local function _runCmd(s)
    if _G.__AdminRunCmd then _G.__AdminRunCmd(s)
    else notify("Command system not ready", "warn") end
end
local function _openCmd(s)
    if _G.__AdminOpenCmd then _G.__AdminOpenCmd(s)
    else notify("Command bar not ready", "warn") end
end

-- Floating slider popup for numeric commands (e.g. !ws, !jp)
local _openSliders
do
    local current
    _openSliders = function(title, cmd, sliders)
        if current then pcall(function() current:Destroy() end); current = nil end
        local gui = inst("ScreenGui", nil, {
            Name = "SeigeSliderPopup", IgnoreGuiInset = true, ResetOnSpawn = false,
            DisplayOrder = 220, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        })
        safeParent(gui)
        current = gui
        local win = inst("Frame", gui, {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0, 280, 0, 40 + #sliders * 58 + 12),
            BackgroundColor3 = T.bg, BorderSizePixel = 0, ZIndex = 220,
        })
        corner(win, 10); stroke(win, T.line, 1, 0.3)
        local bar = inst("Frame", win, {
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundColor3 = T.bg2, BorderSizePixel = 0, ZIndex = 221,
        })
        corner(bar, 10)
        inst("TextLabel", bar, {
            BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 0),
            Size = UDim2.new(1, -44, 1, 0), Font = Enum.Font.GothamBold, TextSize = 13,
            TextColor3 = T.text, TextXAlignment = Enum.TextXAlignment.Left,
            Text = title, ZIndex = 222,
        })
        local closeBtn = inst("TextButton", bar, {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.new(0, 22, 0, 22),
            BackgroundColor3 = T.bg3, BorderSizePixel = 0,
            Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = T.text,
            Text = "✕", ZIndex = 222,
        })
        corner(closeBtn, 6)
        closeBtn.MouseButton1Click:Connect(function() gui:Destroy(); current = nil end)
        -- drag
        do
            local dragging, startPos, startMouse
            bar.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                    dragging = true; startPos = win.Position; startMouse = i.Position
                end
            end)
            UIS.InputChanged:Connect(function(i)
                if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                    local d = i.Position - startMouse
                    win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
                end
            end)
            UIS.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
            end)
        end
        local body = inst("Frame", win, {
            Position = UDim2.new(0, 6, 0, 36),
            Size = UDim2.new(1, -12, 1, -42),
            BackgroundTransparency = 1, ZIndex = 221,
        })
        local list = inst("UIListLayout", body, { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder })
        for _, s in ipairs(sliders) do
            slider(body, s.label, s.lo, s.hi, s.default, function(v)
                local n = math.floor(v + 0.5)
                _runCmd(cmd .. " " .. tostring(n))
            end)
        end
    end
end

-- Generic floating panel (X close + drag) for arbitrary toggles/sliders/buttons.
-- builder(body) receives a Frame with a vertical UIListLayout already attached.
local _openPanel
do
    local active = {}
    -- Smooth open/close anim helpers for popout panels. Fade + scale with
    -- a soft Back ease on open and a fast Quad on close, then destroy.
    local function _animOpen(win)
        local scaleObj = win:FindFirstChildOfClass("UIScale")
            or inst("UIScale", win, { Scale = 0.85 })
        if _G.__SeigeReducedMotion then
            scaleObj.Scale = 1
            return
        end
        scaleObj.Scale = 0.85
        local prevBT = win.BackgroundTransparency
        win.BackgroundTransparency = 1
        TweenService:Create(win, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { BackgroundTransparency = prevBT }):Play()
        TweenService:Create(scaleObj, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            { Scale = 1 }):Play()
    end
    local function _animClose(gui, win, onDone)
        if _G.__SeigeReducedMotion then
            if gui and gui.Parent then gui:Destroy() end
            if onDone then onDone() end
            return
        end
        local scaleObj = win:FindFirstChildOfClass("UIScale")
            or inst("UIScale", win, { Scale = 1 })
        TweenService:Create(scaleObj, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            { Scale = 0.9 }):Play()
        TweenService:Create(win, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            { BackgroundTransparency = 1 }):Play()
        task.delay(0.2, function()
            if gui and gui.Parent then gui:Destroy() end
            if onDone then onDone() end
        end)
    end
    _openPanel = function(key, title, height, builder)
        if active[key] then
            local entry = active[key]
            active[key] = nil
            if entry and entry.gui and entry.gui.Parent and entry.win then
                _animClose(entry.gui, entry.win)
            elseif entry and entry.Destroy then
                pcall(function() entry:Destroy() end)
            end
            return
        end
        local gui = inst("ScreenGui", nil, {
            Name = "SeigePanelPopup_" .. tostring(key),
            IgnoreGuiInset = true, ResetOnSpawn = false,
            DisplayOrder = 220, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        })
        safeParent(gui)
        -- Cap window height so it never spills off the viewport — overflow
        -- becomes scrollable inside the body.
        local viewportH = (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.Y) or 600
        local maxH = math.max(160, viewportH - 80)
        local reqH = height or 200
        local winH = math.min(reqH, maxH)
        local _trans = _G.__SeigeUITrans or 0.35
        local win = inst("Frame", gui, {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0, 300, 0, winH),
            BackgroundColor3 = T.bg, BackgroundTransparency = _trans, BorderSizePixel = 0,
        })
        corner(win, 10); stroke(win, T.line, 1, 0.3)
        active[key] = { gui = gui, win = win }
        -- Register so global Panel translucency slider updates this popup too.
        _G.__SeigePopupPanels = _G.__SeigePopupPanels or {}
        _G.__SeigePopupPanels[win] = true
        win.AncestryChanged:Connect(function(_, parent)
            if not parent and _G.__SeigePopupPanels then _G.__SeigePopupPanels[win] = nil end
        end)
        local bar = inst("Frame", win, {
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundColor3 = T.bg2, BorderSizePixel = 0,
        })
        corner(bar, 10)
        inst("TextLabel", bar, {
            BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 0),
            Size = UDim2.new(1, -44, 1, 0), Font = Enum.Font.GothamBold, TextSize = 13,
            TextColor3 = T.text, TextXAlignment = Enum.TextXAlignment.Left, Text = title,
        })
        local closeBtn = inst("TextButton", bar, {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.new(0, 22, 0, 22),
            BackgroundColor3 = T.bg3, BorderSizePixel = 0,
            Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = T.text, Text = "✕",
        })
        corner(closeBtn, 6)
        closeBtn.MouseButton1Click:Connect(function()
            if active[key] then active[key] = nil end
            _animClose(gui, win)
        end)
        do
            local dragging, startPos, startMouse
            bar.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                    dragging = true; startPos = win.Position; startMouse = i.Position
                end
            end)
            UIS.InputChanged:Connect(function(i)
                if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                    local d = i.Position - startMouse
                    win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
                end
            end)
            UIS.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
            end)
        end
        -- Body is a ScrollingFrame so panels with many controls (bang, reanim,
        -- voice, etc.) never clip — overflow scrolls vertically.
        local body = inst("ScrollingFrame", win, {
            Position = UDim2.new(0, 6, 0, 36),
            Size = UDim2.new(1, -12, 1, -42),
            BackgroundTransparency = 1, BorderSizePixel = 0,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            ScrollBarThickness = 4, ScrollBarImageColor3 = T.line,
        })
        inst("UIListLayout", body, { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder })
        inst("UIPadding", body, { PaddingRight = UDim.new(0, 6) })
        pcall(builder, body)
        _animOpen(win)
    end
end


-- Generic command result window: pops a draggable list of rows so commands
-- like !taglist, !list, !tagfind etc. show results in a GUI instead of a toast.
local function _openResultPanel(key, title, rows, opts)
    opts = opts or {}
    local empty = opts.empty or "No results."
    _openPanel(key, title, opts.height or 360, function(body)
        local header
        if opts.subtitle then
            header = inst("TextLabel", body, {
                BackgroundTransparency = 1, Size = UDim2.new(1, -4, 0, 16),
                Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = T.sub,
                TextXAlignment = Enum.TextXAlignment.Left, Text = opts.subtitle,
            })
        end
        local scroll = inst("ScrollingFrame", body, {
            Size = UDim2.new(1, -4, 1, header and -22 or 0),
            BackgroundTransparency = 1, BorderSizePixel = 0,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 4, ScrollBarImageColor3 = T.line,
        })
        inst("UIListLayout", scroll, { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder })
        inst("UIPadding", scroll, { PaddingRight = UDim.new(0, 4) })
        if not rows or #rows == 0 then
            inst("TextLabel", scroll, {
                BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 24),
                Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = T.sub,
                TextXAlignment = Enum.TextXAlignment.Left, Text = empty,
            })
            return
        end
        for _, r in ipairs(rows) do
            local row = inst("Frame", scroll, {
                Size = UDim2.new(1, 0, 0, 26),
                BackgroundColor3 = T.bg2, BorderSizePixel = 0,
            })
            corner(row, 6)
            inst("UIPadding", row, { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) })
            if r.swatch then
                local sw = inst("Frame", row, {
                    AnchorPoint = Vector2.new(0, 0.5),
                    Position = UDim2.new(0, 0, 0.5, 0),
                    Size = UDim2.new(0, 14, 0, 14),
                    BackgroundColor3 = r.swatch, BorderSizePixel = 0,
                })
                corner(sw, 4); stroke(sw, T.line, 1, 0.4)
            end
            inst("TextLabel", row, {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, r.swatch and 22 or 0, 0, 0),
                Size = UDim2.new(1, r.swatch and -22 or 0, 1, 0),
                Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = T.text,
                TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
                Text = tostring(r.text or r[1] or ""),
            })
            if r.right then
                inst("TextLabel", row, {
                    AnchorPoint = Vector2.new(1, 0),
                    Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(0, 80, 1, 0),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = T.sub,
                    TextXAlignment = Enum.TextXAlignment.Right, Text = tostring(r.right),
                })
            end
        end
    end)
end
_G.__SeigeOpenResultPanel = _openResultPanel;

-- ===== Help panel: full command reference =====
(function()
local HELP_CMDS = {
    { "Rejoin & teleport", {
        { "!rj", "Rejoin the same place (new server)" },
        { "!tprj", "Rejoin THIS server and restore your position via queue_on_teleport" },
        { "!randomserver / !jrs / !hop", "Join a random public server" },
        { "!bypass <msg>", "Send chat that bypasses the censor (no ### replacement)" },
        
    }},
    { "Character", {
        { "!reset / !r / !respawn", "Kill your character to respawn" },
        { "!jump", "Force a jump" },
        { "!heal", "Heal to max health" },
        { "!god / !ungod", "Toggle godmode (server-side via reset trick)" },
        { "!sit", "Force sit" },
        { "!size <n>", "Scale your character (e.g. !size 2)" },
        { "!invis", "Hide your character locally (toggle / keybind via popout)" },
        { "!ghost", "Semi-transparent + noclip" },
        { "!hatspin", "Spin/break accessories (flings nearby)" },
    }},
    { "Movement", {
        { "!ws <n>", "Set walk speed (0–200)" },
        { "!jp <n>", "Set jump power (0–500)" },
        { "!fly / !unfly", "Toggle fly (WASD + E/Q, Shift = boost)" },
        { "!noclip / !clip", "Walk through walls" },
        { "!freecam", "Detach camera (WASD/EQ + Shift)" },
    }},
    { "Teleport / target", {
        { "!goto <player>", "Teleport to a player" },
        { "!tp <player>", "Same as !goto" },
        { "!to <player>", "Bring a player to you" },
        { "!spectate <player>", "Spectate a player" },
        { "!unspectate", "Stop spectating" },
        { "!face <player>", "Face a player" },
        { "!headsit <player>", "Sit on a player's head — toggle in the Headsit panel" },
        { "!unheadsit", "Eject yourself / rider off head" },
        { "!shouldersit <player>", "Sit on a player's shoulders" },
        { "!carry <player>", "Pick a player up (carry above you)" },
        { "!piggyback <player>", "Piggyback ride on a player's back" },
        { "!uncarry / !unpiggy / !unshoulder", "Stop carry / piggy / shoulder" },
        { "!fling <player>", "Fling a player" },
        { "!stalk / !unstalk", "Pick a player and watch their position, mic, and chat" },
    }},
    { "Admin / owner", {
        { "!timestop", "Freeze everyone except you (admin/owner only)" },
        { "!untimestop", "Release the freeze" },
    }},
    
    { "Animations", {
        { "!reanim", "Free the humanoid for custom animations" },
        { "!unreanim", "Stop reanim" },
        { "!reanim <id> [speed]", "Play an animation asset id" },
        { "!reanimurl <url> [speed]", "Fetch + play .txt/.json keyframe data" },
        { "!reanimdata <raw>", "Play pasted JSON/Lua keyframe data" },
        { "!stopanim", "Stop all reanim tracks" },
        { "!bang <player>", "Front bang (face them)" },
        { "!facebang <player>", "Bang their face" },
        { "!backbang <player>", "Bang from behind" },
        { "!unbang", "Stop" },
        { "!cir <player> / !uncir", "Orbit a player — adjust distance/speed in the panel" },
    }},
    { "Position", {
        { "!save", "Save current position" },
        { "!load", "Teleport back to saved position" },
    }},
    { "World / lighting", {
        { "!fullbright", "Flat max ambient" },
        { "!day / !night", "Time of day shortcuts" },
        { "!time <0-24>", "Set ClockTime" },
        { "!esp", "Highlight all players through walls" },
        { "!baseplate", "Prompt to drop / extend a baseplate under you" },
    }},
    { "Misc", {
        { "!nameedit", "Open the name-spoof panel" },
        { "!say <message>", "Send a chat message" },
        { "!info", "Server info" },
        { "!help", "Open this panel" },
    }},
}

local function _openHelpPanel()
    _openPanel("help", "Help  ·  All commands", 480, function(body)
        local scroll = inst("ScrollingFrame", body, {
            Size = UDim2.new(1, -4, 1, 0),
            BackgroundTransparency = 1, BorderSizePixel = 0,
            ScrollBarThickness = 4, ScrollBarImageColor3 = T.acc,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollingDirection = Enum.ScrollingDirection.Y,
        })
        inst("UIListLayout", scroll, { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder })
        inst("UIPadding", scroll, { PaddingRight = UDim.new(0, 6) })
        for _, group in ipairs(HELP_CMDS) do
            local hdr = inst("TextLabel", scroll, {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -8, 0, 22),
                Font = Enum.Font.GothamBold, TextSize = 11,
                TextColor3 = T.dim, TextXAlignment = Enum.TextXAlignment.Left,
                Text = string.upper(group[1]),
            })
            for _, row in ipairs(group[2]) do
                local cmd, desc = row[1], row[2]
                local f = inst("Frame", scroll, {
                    Size = UDim2.new(1, -8, 0, 36),
                    BackgroundColor3 = T.bg2, BackgroundTransparency = 0.35, BorderSizePixel = 0,
                })
                corner(f, 6); stroke(f, T.line, 1, 0.6)
                inst("TextLabel", f, {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0, 2), Size = UDim2.new(1, -20, 0, 16),
                    Font = Enum.Font.Code, TextSize = 12, TextColor3 = T.acc,
                    TextXAlignment = Enum.TextXAlignment.Left, Text = cmd,
                })
                inst("TextLabel", f, {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0, 18), Size = UDim2.new(1, -20, 0, 16),
                    Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = T.sub,
                    TextXAlignment = Enum.TextXAlignment.Left, Text = desc, TextTruncate = Enum.TextTruncate.AtEnd,
                })
            end
        end
    end)
end
_G.__SeigeOpenHelp = _openHelpPanel
end)()

button(pgCmds, "Open Command Bar (F6)", function() _openCmd("!") end)

-- No-arg commands run immediately
button(pgCmds, "!rj  —  rejoin same server",                function() _runCmd("!rj") end)
button(pgCmds, "!tprj  —  rejoin & restore position",        function() _runCmd("!tprj") end)
button(pgCmds, "!reset / !respawn",                          function() _runCmd("!reset") end)
button(pgCmds, "!jump",                                      function() _runCmd("!jump") end)
button(pgCmds, "!heal",                                      function() _runCmd("!heal") end)
button(pgCmds, "!god",                                       function() _runCmd("!god") end)
button(pgCmds, "!ungod",                                     function() _runCmd("!ungod") end)
button(pgCmds, "!unspectate",                                function() _runCmd("!unspectate") end)
button(pgCmds, "!save  —  save position",                    function() _runCmd("!save") end)
button(pgCmds, "!load  —  load saved position",              function() _runCmd("!load") end)
button(pgCmds, "!info",                                      function() _runCmd("!info") end)
button(pgCmds, "!help  —  open help panel", function() if _G.__SeigeOpenHelp then _G.__SeigeOpenHelp() end end)
button(pgCmds, "!sit",                                       function() _runCmd("!sit") end)
button(pgCmds, "!unbang",                                    function() _runCmd("!unbang") end)

-- ===== Performance & Optimize — unified panel =====
-- One place for FPS booster, Ping booster, and Optimize.
-- All three actually do work: uncap fps, drop quality, kill effects,
-- disable shadows/water/decoration, push network priority.
do
    local Lighting   = game:GetService("Lighting")
    local RunService = game:GetService("RunService")
    local Stats      = game:GetService("Stats")

    local function _userSettings()
        local ok, s = pcall(function() return settings():GetService("UserGameSettings") end)
        return ok and s or nil
    end

    _G.__SeigePerf = _G.__SeigePerf or {
        fps = false, ping = false, opt = false,
        saved = nil, conn = nil, fpsTok = 0,
    }
    local P = _G.__SeigePerf

    local function snapshot()
        if P.saved then return end
        local Terrain = workspace:FindFirstChildOfClass("Terrain")
        local US = _userSettings()
        P.saved = {
            qLevel        = pcall(function() return settings().Rendering.QualityLevel end) and settings().Rendering.QualityLevel,
            savedQuality  = US and US.SavedQualityLevel,
            lagSim        = pcall(function() return settings().Network.IncomingReplicationLag end) and settings().Network.IncomingReplicationLag,
            shadows       = Lighting.GlobalShadows,
            fogEnd        = Lighting.FogEnd,
            fogStart      = Lighting.FogStart,
            brightness    = Lighting.Brightness,
            envDif        = Lighting.EnvironmentDiffuseScale,
            envSpc        = Lighting.EnvironmentSpecularScale,
            technology    = Lighting.Technology,
            streamPause   = pcall(function() return workspace.StreamingPauseMode end) and workspace.StreamingPauseMode,
            waterWaveSize    = Terrain and Terrain.WaterWaveSize,
            waterReflectance = Terrain and Terrain.WaterReflectance,
            waterTransparency= Terrain and Terrain.WaterTransparency,
            waterWaveSpeed   = Terrain and Terrain.WaterWaveSpeed,
            decoration       = Terrain and Terrain.Decoration,
        }
    end

    local function setFpsCap(v)
        local s = rawget(getfenv(), "setfpscap")
            or (rawget(getfenv(), "syn") and syn and syn.set_fps_cap)
        if type(s) == "function" then pcall(s, v); return true end
        return false
    end

    -- Walk workspace + lighting and kill cosmetic effects.
    local function stripEffects()
        for _, v in ipairs(Lighting:GetDescendants()) do
            if v:IsA("PostEffect") or v:IsA("BlurEffect") or v:IsA("BloomEffect")
               or v:IsA("SunRaysEffect") or v:IsA("DepthOfFieldEffect")
               or v:IsA("ColorCorrectionEffect") or v:IsA("Atmosphere") then
                pcall(function() v.Enabled = false end)
            end
        end
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke")
               or v:IsA("Fire") or v:IsA("Sparkles") then
                pcall(function() v.Enabled = false end)
            elseif v:IsA("Explosion") then
                pcall(function() v.BlastPressure = 0; v.BlastRadius = 0 end)
            elseif v:IsA("MeshPart") then
                pcall(function() v.RenderFidelity = Enum.RenderFidelity.Performance end)
                pcall(function() v.CastShadow = false end)
            elseif v:IsA("BasePart") then
                pcall(function() v.CastShadow = false end)
            end
        end
    end

    local function applyFps(on)
        snapshot()
        if on then
            setFpsCap(0)
            pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
            local US = _userSettings()
            if US then pcall(function() US.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1 end) end
            pcall(function() Lighting.GlobalShadows = false end)
            pcall(function() Lighting.FogEnd = 1e9 end)
            pcall(function() Lighting.FogStart = 1e9 end)
            pcall(function() Lighting.EnvironmentDiffuseScale = 0 end)
            pcall(function() Lighting.EnvironmentSpecularScale = 0 end)
            pcall(function() Lighting.Technology = Enum.Technology.Compatibility end)
            task.spawn(stripEffects)
            -- re-apply every 5s in case the game resets
            P.fpsTok = P.fpsTok + 1
            local tok = P.fpsTok
            task.spawn(function()
                while P.fps and tok == P.fpsTok do
                    setFpsCap(0)
                    pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
                    task.wait(5)
                end
            end)
        else
            P.fpsTok = P.fpsTok + 1
            setFpsCap(240)
            if P.saved then
                pcall(function() if P.saved.qLevel then settings().Rendering.QualityLevel = P.saved.qLevel end end)
                pcall(function() Lighting.GlobalShadows = P.saved.shadows end)
                pcall(function() Lighting.FogEnd = P.saved.fogEnd end)
                pcall(function() Lighting.FogStart = P.saved.fogStart end)
                pcall(function() Lighting.EnvironmentDiffuseScale = P.saved.envDif end)
                pcall(function() Lighting.EnvironmentSpecularScale = P.saved.envSpc end)
                pcall(function() Lighting.Technology = P.saved.technology end)
            end
        end
    end

    local function applyPing(on)
        snapshot()
        if on then
            pcall(function() settings().Network.IncomingReplicationLag = 0 end)
            pcall(function() workspace.StreamingPauseMode = Enum.StreamingPauseMode.Disabled end)
            pcall(function()
                local sched = settings():GetService("TaskScheduler")
                if sched then
                    sched.PriorityMethod = Enum.PriorityMethod.AccumulatedYieldTime
                    sched.SchedulerDutyCycle = 1
                end
            end)
        else
            if P.saved then
                pcall(function() settings().Network.IncomingReplicationLag = P.saved.lagSim or 0 end)
                pcall(function() workspace.StreamingPauseMode = P.saved.streamPause end)
            end
        end
    end

    local function applyOpt(on)
        snapshot()
        local Terrain = workspace:FindFirstChildOfClass("Terrain")
        if on then
            if Terrain then
                pcall(function() Terrain.WaterWaveSize = 0 end)
                pcall(function() Terrain.WaterReflectance = 0 end)
                pcall(function() Terrain.WaterTransparency = 1 end)
                pcall(function() Terrain.WaterWaveSpeed = 0 end)
                pcall(function() Terrain.Decoration = false end)
            end
            stripEffects()
            if not P.conn then
                P.conn = workspace.DescendantAdded:Connect(function(d)
                    if not P.opt then return end
                    if d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Smoke")
                       or d:IsA("Fire") or d:IsA("Sparkles") then
                        pcall(function() d.Enabled = false end)
                    elseif d:IsA("BasePart") then
                        pcall(function() d.CastShadow = false end)
                    end
                end)
            end
        else
            if P.conn then pcall(function() P.conn:Disconnect() end); P.conn = nil end
            if P.saved and Terrain then
                pcall(function() Terrain.WaterWaveSize = P.saved.waterWaveSize end)
                pcall(function() Terrain.WaterReflectance = P.saved.waterReflectance end)
                pcall(function() Terrain.WaterTransparency = P.saved.waterTransparency end)
                pcall(function() Terrain.WaterWaveSpeed = P.saved.waterWaveSpeed end)
                pcall(function() Terrain.Decoration = P.saved.decoration end)
            end
        end
    end

    local function applyAll(on)
        P.fps, P.ping, P.opt = on, on, on
        applyFps(on); applyPing(on); applyOpt(on)
    end

    local function _openPerfPanel()
        _openPanel("perf", "Performance  ·  FPS / Ping / Optimize", 320, function(body)
            local readout = inst("TextLabel", body, {
                Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = T.bg3,
                BackgroundTransparency = 0.4, BorderSizePixel = 0,
                Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = T.text,
                Text = "FPS: --   Ping: -- ms",
            })
            corner(readout, 6); stroke(readout, T.line, 1, 0.4)
            task.spawn(function()
                local last = tick(); local frames = 0; local fps = 0
                while readout.Parent do
                    frames = frames + 1
                    local now = tick()
                    if now - last >= 0.5 then
                        fps = math.floor(frames / (now - last) + 0.5)
                        frames = 0; last = now
                    end
                    local ping = 0
                    pcall(function()
                        ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue() + 0.5)
                    end)
                    readout.Text = ("FPS: %d   Ping: %d ms"):format(fps, ping)
                    task.wait(0.1)
                end
            end)
            toggle(body, "FPS booster (uncap + low quality + strip FX)", P.fps, function(v)
                P.fps = v; applyFps(v)
                notify("FPS booster " .. (v and "ON" or "OFF"), v and "good" or "dim")
            end)
            toggle(body, "Ping booster (network priority + no stream pause)", P.ping, function(v)
                P.ping = v; applyPing(v)
                notify("Ping booster " .. (v and "ON" or "OFF"), v and "good" or "dim")
            end)
            toggle(body, "Optimize (water/decor off, block new FX)", P.opt, function(v)
                P.opt = v; applyOpt(v)
                notify("Optimize " .. (v and "ON" or "OFF"), v and "good" or "dim")
            end)
            button(body, "MAX BOOST (all three)", function()
                applyAll(true); notify("Max performance ON", "good")
            end)
            button(body, "Restore defaults", function()
                applyAll(false); notify("Performance restored", "warn")
            end)
        end)
    end

    button(pgCmds, "Performance  —  FPS / Ping / Optimize", _openPerfPanel)
    _G.__SeigeOpenPerf = _openPerfPanel
    task.defer(function()
        if _G.__SeigeCmds then
            _G.__SeigeCmds["performance"] = _openPerfPanel
            _G.__SeigeCmds["perf"]        = _openPerfPanel
            _G.__SeigeCmds["fpsboost"]    = function() P.fps = true; applyFps(true); notify("FPS booster ON", "good") end
            _G.__SeigeCmds["unfpsboost"]  = function() P.fps = false; applyFps(false); notify("FPS booster OFF", "warn") end
            _G.__SeigeCmds["pingboost"]   = function() P.ping = true; applyPing(true); notify("Ping booster ON", "good") end
            _G.__SeigeCmds["unpingboost"] = function() P.ping = false; applyPing(false); notify("Ping booster OFF", "warn") end
            _G.__SeigeCmds["optimize"]    = function() P.opt = true; applyOpt(true); notify("Optimize ON", "good") end
            _G.__SeigeCmds["unoptimize"]  = function() P.opt = false; applyOpt(false); notify("Optimize OFF", "warn") end
            _G.__SeigeCmds["maxboost"]    = function() applyAll(true); notify("Max performance ON", "good") end
            _G.__SeigeCmds["unboost"]     = function() applyAll(false); notify("Performance restored", "warn") end
        end
    end)
end

-- ===== Popout panels (replace standalone toggles) =====
button(pgCmds, "Movement  —  walk + jump", function()
    _openPanel("movement", "Movement  ·  Walk & Jump", 200, function(body)
        local h = hum()
        slider(body, "Walk speed", 0, 200, (h and h.WalkSpeed) or 16, function(v)
            local hh = hum(); if hh then hh.WalkSpeed = v end
            _runCmd("!ws " .. tostring(math.floor(v + 0.5)))
        end)
        slider(body, "Jump power", 0, 500, (h and h.JumpPower) or 50, function(v)
            local hh = hum(); if hh then hh.JumpPower = v; hh.UseJumpPower = true end
            _runCmd("!jp " .. tostring(math.floor(v + 0.5)))
        end)
        slider(body, "Hip height", 0, 10, (h and h.HipHeight) or 2, function(v)
            local hh = hum(); if hh then hh.HipHeight = v end
        end)
        toggle(body, "Infinite jump", infJump, function(s) infJump = s end)
    end)
end)

button(pgCmds, "Fly  —  toggle + speed", function()
    _openPanel("fly", "Fly  ·  E up · Q down · WASD", 170, function(body)
        toggle(body, "Fly enabled", flying, function(s)
            if s then startFly() else killFly() end
        end)
        slider(body, "Fly speed", 10, 300, flySpeed, function(v) flySpeed = v end)
        button(body, "Stop fly", function() killFly() end)
    end)
end)

button(pgCmds, "Noclip  —  toggle", function()
    _openPanel("noclip", "Noclip  ·  walk through walls", 130, function(body)
        toggle(body, "Noclip enabled", noclip, function(s) noclip = s end)
        button(body, "Re-enable collisions (clip)", function()
            noclip = false
            local c = char(); if c then for _, p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = true end
            end end
        end)
    end)
end)

button(pgCmds, "Anti-AFK  —  toggle", function()
    _openPanel("antiafk", "Anti-AFK  ·  prevent kick", 110, function(body)
        toggle(body, "Anti-AFK enabled", antiAfk, function(s)
            antiAfk = s
            if s then notify("Anti-AFK active", "good") end
        end)
    end)
end)

-- (Optimize merged into the Performance panel above.)





button(pgCmds, "Character  —  reset / refresh / click-TP", function()
    _openPanel("character", "Character", 170, function(body)
        button(body, "Reset character", function()
            local h = hum(); if h then h.Health = 0 end
        end)
        button(body, "Refresh (TP to same spot)", function()
            local h = hrp(); if not h then return end
            local cf = h.CFrame
            LP.Character:BreakJoints()
            task.wait(0.6)
            LP.CharacterAdded:Wait():WaitForChild("HumanoidRootPart").CFrame = cf
        end)
        toggle(body, "Click teleport (hold key + click)", clickTp, function(s) clickTp = s end)
        local awaitingCtp = false
        local ctpBtn
        ctpBtn = button(body, "Hold key: " .. _G.__ClickTpKey.Name .. "  (click to set)", function()
            awaitingCtp = not awaitingCtp
            ctpBtn.Text = awaitingCtp and "Press any key…" or ("Hold key: " .. _G.__ClickTpKey.Name .. "  (click to set)")
        end)
        local ctpConn = UIS.InputBegan:Connect(function(i, gp)
            if not awaitingCtp or gp then return end
            if i.UserInputType == Enum.UserInputType.Keyboard then
                _G.__ClickTpKey = i.KeyCode
                awaitingCtp = false
                ctpBtn.Text = "Hold key: " .. i.KeyCode.Name .. "  (click to set)"
            end
        end)
        body.AncestryChanged:Connect(function()
            if not body.Parent then pcall(function() ctpConn:Disconnect() end) end
        end)
    end)
end)

button(pgCmds, "Reanim  —  launch ROT animation GUI", function()
    _runCmd("!reanim")
end)


button(pgCmds, "NameEdit  —  hide username/display name", function()
    _openPanel("nameedit", "NameEdit  ·  cosmetic name spoof", 260, function(body)
        -- Track originals so Reset works across respawns
        _G.__NameOrig = _G.__NameOrig or {
            display = LP.DisplayName,
            name    = LP.Name,
        }
        local function applyToChar(char, displayName, userName)
            if not char then return end
            local h = char:FindFirstChildOfClass("Humanoid")
            if h and displayName and displayName ~= "" then
                pcall(function() h.DisplayName = displayName end)
            end
            -- Rewrite any BillboardGui text labels on the character (custom nameplates)
            for _, d in ipairs(char:GetDescendants()) do
                if d:IsA("TextLabel") or d:IsA("TextButton") then
                    local txt = d.Text
                    if type(txt) == "string" then
                        if displayName and displayName ~= "" and txt:find(_G.__NameOrig.display, 1, true) then
                            pcall(function() d.Text = txt:gsub(_G.__NameOrig.display, displayName) end)
                        end
                        if userName and userName ~= "" and txt:find(_G.__NameOrig.name, 1, true) then
                            pcall(function() d.Text = txt:gsub(_G.__NameOrig.name, userName) end)
                        end
                    end
                end
            end
        end
        local function apply(displayName, userName)
            _G.__NameSpoof = { display = displayName, name = userName }
            applyToChar(LP.Character, displayName, userName)
            if not _G.__NameSpoofConn then
                _G.__NameSpoofConn = LP.CharacterAdded:Connect(function(c)
                    task.wait(0.4)
                    if _G.__NameSpoof then
                        applyToChar(c, _G.__NameSpoof.display, _G.__NameSpoof.name)
                    end
                end)
            end
            notify("Name spoofed (local view): " .. (displayName ~= "" and displayName or userName), "good")
        end

        local dnBox, unBox
        dnBox = textbox(body, "New display name (overhead)", function(v) apply(v, unBox and unBox.Text or "") end)
        unBox = textbox(body, "New username text (cosmetic only)", function(v) apply(dnBox and dnBox.Text or "", v) end)
        button(body, "Apply both", function()
            apply(dnBox and dnBox.Text or "", unBox and unBox.Text or "")
        end)
        button(body, "Reset to original", function()
            _G.__NameSpoof = nil
            if _G.__NameSpoofConn then _G.__NameSpoofConn:Disconnect(); _G.__NameSpoofConn = nil end
            applyToChar(LP.Character, _G.__NameOrig.display, _G.__NameOrig.name)
            notify("Name reset", "good")
        end)
        button(body, "Randomize", function()
            local pool = {"Guest","Player","Noob","_","xX","Pro","Roblox","Roblo","System"}
            local r = pool[math.random(#pool)] .. tostring(math.random(1000, 9999))
            apply(r, r)
            if dnBox then dnBox.Text = r end
            if unBox then unBox.Text = r end
        end)
    end)
end)



-- Player-target commands open the bar prefilled
button(pgCmds, "!goto / !tp <player>",  function() _openCmd("!goto ") end)
button(pgCmds, "!to <player>",           function() _openCmd("!to ") end)
button(pgCmds, "!spectate <player>",    function() _openCmd("!spectate ") end)
button(pgCmds, "!fling <player>",       function() _openCmd("!fling ") end)
button(pgCmds, "Stalk  —  pick a player to listen (!stalk)", function() _runCmd("!stalk") end)
button(pgCmds, "!face <player>",        function() _openCmd("!face ") end)
button(pgCmds, "Headsit  —  sit on / eject (!headsit)", function()
    _openPanel("headsit", "Headsit  ·  sit on a player's head", 230, function(body)
        local tbox = inst("TextBox", body, {
            Size = UDim2.new(1, -8, 0, 26), BackgroundColor3 = T.bg2,
            TextColor3 = T.fg, Font = Enum.Font.Gotham, TextSize = 13,
            PlaceholderText = "  Player name…", Text = "", ClearTextOnFocus = false,
        })
        toggle(body, "Sitting on head", _G.__HeadLock ~= nil, function(on)
            if on then
                local name = tbox.Text
                if not name or name == "" then notify("Type a player name", "warn"); return end
                _runCmd("!headsit " .. name)
            else
                _runCmd("!unheadsit")
            end
        end)
        button(body, "Eject rider / stand up (!unheadsit)", function() _runCmd("!unheadsit") end)
    end)
end)
button(pgCmds, "!shouldersit <player>",  function() _openCmd("!shouldersit ") end)
button(pgCmds, "!carry <player>",        function() _openCmd("!carry ") end)
button(pgCmds, "!piggyback <player>",    function() _openCmd("!piggyback ") end)
button(pgCmds, "!uncarry / !unpiggy / !unshoulder", function() _runCmd("!uncarry"); _runCmd("!unpiggy"); _runCmd("!unshoulder") end)
button(pgCmds, "Timestop  —  freeze everyone (admin/owner)", function()
    if not (_G.__SeigeCan and _G.__SeigeCan("freeze")) then notify("Admin/owner only", "bad"); return end
    if _G.__SeigeTimestop and _G.__SeigeTimestop.on then _runCmd("!untimestop") else _runCmd("!timestop") end
end)
button(pgCmds, "Bang  —  front / face / back (!bang)", function()
    _openPanel("bang", "Bang  ·  front / face / back", 320, function(body)
        local B = _G.__SeigeBang
        local tbox = inst("TextBox", body, {
            Size = UDim2.new(1, -8, 0, 26), BackgroundColor3 = T.bg2,
            TextColor3 = T.fg, Font = Enum.Font.Gotham, TextSize = 13,
            PlaceholderText = "  Player name…", Text = "", ClearTextOnFocus = false,
        })
        local modeBtn
        local function refreshMode() modeBtn.Text = "Mode: " .. B.mode .. "  (click to cycle)" end
        modeBtn = button(body, "", function()
            B.mode = (B.mode == "front") and "face" or (B.mode == "face") and "back" or "front"
            refreshMode()
        end)
        refreshMode()
        button(body, "Start bang", function()
            local name = tbox.Text
            if not name or name == "" then notify("Type a player name", "warn"); return end
            local target = findPlr(name)
            if not target then notify("Player not found", "bad"); return end
            _bangStart(target)
        end)
        slider(body, "Distance", 0, 6, B.distance, function(v) B.distance = v end)
        slider(body, "Height offset", -6, 6, B.height, function(v) B.height = v end)
        slider(body, "Anim speed", 1, 10, B.speed, function(v)
            B.speed = v
            if _G.__BangTrack then pcall(function() _G.__BangTrack:AdjustSpeed(v) end) end
        end)
        toggle(body, "Auto-face target (front)", B.autoFace, function(s) B.autoFace = s end)
        toggle(body, "Spin / orbit around them", B.spin, function(s) B.spin = s end)
        slider(body, "Spin speed", 1, 16, B.spinSpeed, function(v) B.spinSpeed = v end)
        button(body, "Stop (!unbang)", function() _bangStop(); notify("Bang stopped", "good") end)
    end)
end)
button(pgCmds, "Circle  —  orbit a player (!cir)", function()
    _openPanel("circle", "Circle  ·  orbit a player", 240, function(body)
        _G.__SeigeCircle = _G.__SeigeCircle or { radius = 6, speed = 2, height = 0 }
        local C = _G.__SeigeCircle
        local tbox = inst("TextBox", body, {
            Size = UDim2.new(1, -8, 0, 26), BackgroundColor3 = T.bg2,
            TextColor3 = T.fg, Font = Enum.Font.Gotham, TextSize = 13,
            PlaceholderText = "  Player name…", Text = "", ClearTextOnFocus = false,
        })
        button(body, "Start circling", function()
            local name = tbox.Text
            if not name or name == "" then notify("Type a player name", "warn"); return end
            local target = findPlr(name)
            if not target then notify("Player not found", "bad"); return end
            _seigeCircleStart(target)
            notify("Circling " .. target.Name, "good")
        end)
        slider(body, "Distance (closer ↔ farther)", 2, 40, C.radius, function(v) C.radius = v end)
        slider(body, "Speed", 1, 12, C.speed, function(v) C.speed = v end)
        slider(body, "Height offset", -10, 10, C.height, function(v) C.height = v end)
        button(body, "Stop (!uncir)", function() _seigeCircleStop(); notify("Circle stopped", "good") end)
    end)
end)

section(pgCmds, "Extras")
button(pgCmds, "!esp  —  highlight all players",         function() _runCmd("!esp") end)
button(pgCmds, "!fullbright  —  flat max lighting",      function() _runCmd("!fullbright") end)
button(pgCmds, "!day  /  !night",                        function() _openCmd("!day") end)
button(pgCmds, "!time <0-24>",                           function() _openCmd("!time ") end)
button(pgCmds, "Invis  —  toggle + keybind", function()
    _openPanel("invis", "Invis  ·  local hide", 160, function(body)
        toggle(body, "Invisible", _G.__InvisOn or false, function(s)
            local c = LP.Character
            if not c then notify("No character", "warn"); return end
            applyInvisState(s)
            notify(s and "Invisible (local)" or "Visible", "good")
        end)
        local awaiting = false
        local keyBtn
        keyBtn = button(body, "Toggle key: " .. ((_G.__InvisKey and _G.__InvisKey.Name) or "F7") .. "  (click to set)", function()
            awaiting = not awaiting
            keyBtn.Text = awaiting and "Press any key…" or ("Toggle key: " .. ((_G.__InvisKey and _G.__InvisKey.Name) or "F7") .. "  (click to set)")
        end)
        local keyConn = UIS.InputBegan:Connect(function(i, gp)
            if not awaiting then return end
            if gp then return end
            if i.UserInputType == Enum.UserInputType.Keyboard then
                _G.__InvisKey = i.KeyCode
                awaiting = false
                keyBtn.Text = "Toggle key: " .. i.KeyCode.Name .. "  (click to set)"
            end
        end)
        body.AncestryChanged:Connect(function()
            if not body.Parent then pcall(function() keyConn:Disconnect() end) end
        end)
    end)
end)

-- Anti: block other players from headsit / face / bang / drag on you
_G.__SeigeAnti = _G.__SeigeAnti or { on = false, radius = 4, conn = nil }
local function _seigeAntiStop()
    local A = _G.__SeigeAnti
    if A.conn then pcall(function() A.conn:Disconnect() end); A.conn = nil end
    A.on = false
end
local function _seigeAntiStart()
    local A = _G.__SeigeAnti
    _seigeAntiStop()
    A.on = true
    A.conn = RunService.Heartbeat:Connect(function()
        local myHRP = hrp(); local myH = hum()
        if not myHRP or not myH then return end
        -- break forced Sit (headsit lock)
        if myH.Sit then myH.Sit = false; myH.Jump = true end
        -- shove off any player crammed into us (bang / head)
        local r = tonumber(A.radius) or 4
        local myPos = myHRP.Position
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP then
                local ohrp = phrp(p)
                if ohrp then
                    local d = (ohrp.Position - myPos).Magnitude
                    if d < r then
                        myHRP.CFrame = myHRP.CFrame + Vector3.new(0, 8, 0)
                        break
                    end
                end
            end
        end
    end)
end
button(pgCmds, "Anti  —  block headsit / bang / drag", function()
    _openPanel("anti", "Anti  ·  block bang/head/face", 170, function(body)
        local A = _G.__SeigeAnti
        toggle(body, "Anti on", A.on, function(s)
            if s then _seigeAntiStart(); notify("Anti on", "good")
            else _seigeAntiStop(); notify("Anti off", "good") end
        end)
        slider(body, "Push radius", 2, 12, A.radius or 4, function(v)
            A.radius = v
        end)
    end)
end)
if _G.__SeigeCmds then
    _G.__SeigeCmds["anti"] = function()
        if _G.__SeigeAnti and _G.__SeigeAnti.on then _seigeAntiStop(); notify("Anti off", "good")
        else _seigeAntiStart(); notify("Anti on", "good") end
    end
    _G.__SeigeCmds["unanti"] = function() _seigeAntiStop(); notify("Anti off", "good") end
end

button(pgCmds, "!ghost  —  transparent + noclip",        function() _runCmd("!ghost") end)
button(pgCmds, "!size <n>",                              function() _openCmd("!size ") end)
button(pgCmds, "!hatspin  —  fling spinning accessories",function() _runCmd("!hatspin") end)
button(pgCmds, "!freecam  —  WASD/EQ camera",            function() _runCmd("!freecam") end)

button(pgCmds, "!say <message>",                         function() _openCmd("!say ") end)
button(pgCmds, "!baseplate  —  extend the map",          function() _runCmd("!baseplate") end)

button(pgCmds, "Voice  —  anti-ban + mute", function()
    _openPanel("voice", "Voice  ·  anti-ban + mic", 290, function(body)
        local V = _G.__SeigeVoice
        if not V then notify("Voice helper not ready", "warn"); return end
        _G.__SeigeAntiVC = _G.__SeigeAntiVC or { on = false, interval = 25 }

        local statusLbl = inst("TextLabel", body, {
            BackgroundTransparency = 1, Size = UDim2.new(1, -8, 0, 16),
            Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = T.sub,
            TextXAlignment = Enum.TextXAlignment.Left, Text = "  " .. V.summary(),
        })
        local activateBtn
        local function refresh()
            statusLbl.Text = "  " .. V.summary()
            if activateBtn then
                if V.isActivated() then
                    activateBtn.Text = "Voice controls ACTIVE"
                    activateBtn.BackgroundColor3 = T.good
                else
                    activateBtn.Text = "Activate  (unmute mic in Roblox first)"
                    activateBtn.BackgroundColor3 = T.warn
                end
            end
        end
        activateBtn = button(body, "Activate  (unmute mic in Roblox first)", function()
            local ok, why = V.activate()
            notify(ok and "Voice controls ACTIVE" or (why or "Activation failed"),
                   ok and "good" or "warn")
            refresh()
        end)
        refresh()
        task.spawn(function()
            while body and body.Parent do task.wait(1); refresh() end
        end)

        toggle(body, "Anti voice-chat ban (auto-cycle)", _G.__SeigeAntiVC.on, function(s)
            if not V.isActivated() then notify("Activate voice controls first", "warn"); refresh(); return end
            if s == _G.__SeigeAntiVC.on then return end
            _runCmd("!antivc"); task.wait(0.1); refresh()
        end)
        slider(body, "Cycle interval (sec)", 8, 90, _G.__SeigeAntiVC.interval or 25, function(v)
            _G.__SeigeAntiVC.interval = v
        end)
        button(body, "Cycle voice now (leave + rejoin)", function()
            V.cycle(); refresh()
        end)
        toggle(body, "Force mute mic", V.isMuted(), function(s)
            V.setMuted(s); refresh()
        end)
        button(body, "Disconnect voice (leave channel)", function()
            V.leave(); refresh()
        end)
        button(body, "Reconnect voice (rejoin channel)", function()
            V.join(); refresh()
        end)
    end)
end)




section(pgCmds, "Command bar (F6)  ·  !rj  !tprj")
section(pgCmds, "Rejoin")

button(pgCmds, "Rejoin (same server)", function()
    local ok, err = pcall(function()
        TeleportSrv:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
    end)
    if not ok then
        -- Fallback to a plain rejoin if same-instance teleport is restricted
        pcall(function() TeleportSrv:Teleport(game.PlaceId, LP) end)
        notify("Same-server rejoin failed, doing normal rejoin", "warn")
    else
        notify("Rejoining same server...", "good")
    end
end)
button(pgCmds, "Rejoin (new server)", function()
    pcall(function() TeleportSrv:Teleport(game.PlaceId, LP) end)
    notify("Rejoining...", "good")
end)
button(pgCmds, "Server hop (random public)", function()
    local ok, res = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(
            "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        ))
    end)
    if ok and res and res.data then
        local options = {}
        for _, s in ipairs(res.data) do
            if s.playing and s.maxPlayers and s.playing < s.maxPlayers and s.id ~= game.JobId then
                table.insert(options, s.id)
            end
        end
        if #options > 0 then
            TeleportSrv:TeleportToPlaceInstance(game.PlaceId, options[math.random(1, #options)], LP)
            notify("Hopping...", "good")
        else notify("No servers found", "warn") end
    else notify("Server list unavailable", "bad") end
end)
button(pgCmds, "Copy JobId", function()
    if setclipboard then setclipboard(game.JobId); notify("JobId copied", "good")
    else notify("setclipboard unavailable", "bad") end
end)
button(pgCmds, "Copy PlaceId", function()
    if setclipboard then setclipboard(tostring(game.PlaceId)); notify("PlaceId copied", "good")
    else notify("setclipboard unavailable", "bad") end
end)

------------------------------------------------------- AIM TAB (camera lock)
section(pgCmds, "Aim assist (camera lock)")

;(function()
local aimOn, aimFov, aimSmooth = false, 100, 0.25
local aimVisOnly = true
local aimKey = "RightMouseButton"
local function findTarget()
    local best, bestDist = nil, aimFov
    local myH = hrp(); if not myH then return end
    local center = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and shouldTarget(p) then
            local h = pchar(p) and pchar(p):FindFirstChild("Head")
            if h then
                local sp, on = cam:WorldToViewportPoint(h.Position)
                if on then
                    local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    if d < bestDist then
                        local ok = true
                        if aimVisOnly then
                            local rp = RaycastParams.new()
                            rp.FilterDescendantsInstances = { LP.Character }
                            rp.FilterType = Enum.RaycastFilterType.Exclude
                            local hit = workspace:Raycast(cam.CFrame.Position, (h.Position - cam.CFrame.Position), rp)
                            if hit and hit.Instance and not hit.Instance:IsDescendantOf(pchar(p)) then ok = false end
                        end
                        if ok then best, bestDist = h, d end
                    end
                end
            end
        end
    end
    return best
end
-- Aim controls rendered as commands inside the Cmds tab
button(pgCmds, "/aim — toggle camera lock", function()
    aimOn = not aimOn
    notify("Aim " .. (aimOn and "ON" or "OFF"), aimOn and "good" or "warn")
end)
button(pgCmds, "/aimvis — toggle visible-only", function()
    aimVisOnly = not aimVisOnly
    notify("Visible-only " .. (aimVisOnly and "ON" or "OFF"), "good")
end)
slider(pgCmds, "/fov — FOV radius (px)", 20, 400, 100, function(v) aimFov = v end)
slider(pgCmds, "/smooth — aim smoothness", 0, 1, 0.25, function(v) aimSmooth = v end)
dropdown(pgCmds, "/aimkey — trigger button", { "RightMouseButton", "Q", "E", "Always" }, function(o) aimKey = o end)

-- Chat command hooks: ;aim, ;unaim, ;fov N, ;smooth N, ;aimkey X, ;aimvis
local function handleAimChat(msg)
    msg = (msg or ""):lower()
    local cmd, arg = msg:match("^[;/](%S+)%s*(.*)$")
    if not cmd then return end
    if cmd == "aim" then aimOn = true; notify("Aim ON", "good")
    elseif cmd == "unaim" then aimOn = false; notify("Aim OFF", "warn")
    elseif cmd == "aimvis" then aimVisOnly = not aimVisOnly; notify("Visible-only " .. (aimVisOnly and "ON" or "OFF"), "good")
    elseif cmd == "fov" then local n = tonumber(arg); if n then aimFov = math.clamp(n,20,400); notify("FOV " .. aimFov, "good") end
    elseif cmd == "smooth" then local n = tonumber(arg); if n then aimSmooth = math.clamp(n,0,1); notify("Smooth " .. aimSmooth, "good") end
    elseif cmd == "aimkey" then
        local k = arg:gsub("^%l", string.upper)
        if k == "Rmb" or k == "Rightmousebutton" then aimKey = "RightMouseButton"
        elseif k == "Q" or k == "E" or k == "Always" then aimKey = k
        else return end
        notify("Aim key: " .. aimKey, "good")
    end
end
pcall(function()
    LP.Chatted:Connect(handleAimChat)
end)

-- FOV circle
local fovGui = inst("ScreenGui", Root, { Name = "AimFov", IgnoreGuiInset = true })
local fovCircle = inst("Frame", fovGui, {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = UDim2.new(0, 200, 0, 200),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Visible = false,
})
inst("UICorner", fovCircle, { CornerRadius = UDim.new(1, 0) })
stroke(fovCircle, T.acc, 1.5, 0.5)

bind(RunService.RenderStepped:Connect(function()
    if not aimOn then fovCircle.Visible = false; return end
    fovCircle.Visible = true
    fovCircle.Size = UDim2.new(0, aimFov * 2, 0, aimFov * 2)
    local fire = false
    if aimKey == "Always" then fire = true
    elseif aimKey == "RightMouseButton" then fire = UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    else fire = UIS:IsKeyDown(Enum.KeyCode[aimKey]) end
    if fire then
        local t = findTarget()
        if t then
            local goal = CFrame.new(cam.CFrame.Position, t.Position)
            cam.CFrame = cam.CFrame:Lerp(goal, 1 - aimSmooth)
        end
    end
end))


------------------------------------------------------- EXECUTOR BAR (Cmds)
section(pgCmds, "Executor")

execFrame = inst("Frame", pgCmds, {
    Size = UDim2.new(1, -8, 0, 130),
    BackgroundColor3 = T.bg2, BackgroundTransparency = 0.3, BorderSizePixel = 0,
    Visible = false,
})
corner(execFrame, 8); stroke(execFrame, T.line, 1, 0.5)

local execBox = inst("TextBox", execFrame, {
    Position = UDim2.new(0, 8, 0, 8),
    Size = UDim2.new(1, -16, 1, -48),
    BackgroundColor3 = T.bg, BackgroundTransparency = 0.15, BorderSizePixel = 0,
    Font = Enum.Font.Code, TextSize = 12,
    TextColor3 = T.text, PlaceholderColor3 = T.dim,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    ClearTextOnFocus = false, MultiLine = true,
    PlaceholderText = "-- Lua code, e.g.  print('hi')",
    Text = "",
})
corner(execBox, 6); stroke(execBox, T.line, 1, 0.5)
inst("UIPadding", execBox, {
    PaddingLeft = UDim.new(0,8), PaddingRight = UDim.new(0,8),
    PaddingTop = UDim.new(0,6), PaddingBottom = UDim.new(0,6),
})

local function runExec()
    local src = execBox.Text
    if src == "" then return end
    local ls = rawget(getfenv(), "loadstring") or loadstring
    if not ls then notify("loadstring unavailable", "bad"); return end
    local fn, err = ls(src)
    if not fn then notify("Compile: " .. tostring(err), "bad"); return end
    local ok, perr = pcall(fn)
    if ok then notify("Executed", "good")
    else notify("Runtime: " .. tostring(perr), "bad") end
end

local execRun = inst("TextButton", execFrame, {
    AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, -8, 1, -8),
    Size = UDim2.new(0, 90, 0, 28),
    BackgroundColor3 = T.acc, BackgroundTransparency = 0.1, BorderSizePixel = 0,
    AutoButtonColor = false,
    Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = T.text,
    Text = "Execute",
})
corner(execRun, 6); stroke(execRun, T.line, 1, 0.5)
execRun.MouseButton1Click:Connect(runExec)

local execClear = inst("TextButton", execFrame, {
    AnchorPoint = Vector2.new(0, 1),
    Position = UDim2.new(0, 8, 1, -8),
    Size = UDim2.new(0, 70, 0, 28),
    BackgroundColor3 = T.bg3, BackgroundTransparency = 0.15, BorderSizePixel = 0,
    AutoButtonColor = false,
    Font = Enum.Font.GothamSemibold, TextSize = 12, TextColor3 = T.text,
    Text = "Clear",
})
corner(execClear, 6); stroke(execClear, T.line, 1, 0.5)
execClear.MouseButton1Click:Connect(function() execBox.Text = "" end)

local execPaste = inst("TextButton", execFrame, {
    AnchorPoint = Vector2.new(0, 1),
    Position = UDim2.new(0, 82, 1, -8),
    Size = UDim2.new(0, 70, 0, 28),
    BackgroundColor3 = T.bg3, BackgroundTransparency = 0.15, BorderSizePixel = 0,
    AutoButtonColor = false,
    Font = Enum.Font.GothamSemibold, TextSize = 12, TextColor3 = T.text,
    Text = "Paste",
})
corner(execPaste, 6); stroke(execPaste, T.line, 1, 0.5)
execPaste.MouseButton1Click:Connect(function()
    local gc = rawget(getfenv(), "getclipboard") or rawget(getfenv(), "Clipboard")
    if type(gc) == "function" then
        local ok, s = pcall(gc); if ok and s then execBox.Text = s; notify("Pasted", "good") end
    else notify("getclipboard unavailable", "warn") end
end)

execEnabled = false
toggle(pgCmds, "Show execution bar", false, function(v)
    execEnabled = v
    execFrame.Visible = v
    if _G.__AdminToggleCmdBar then _G.__AdminToggleCmdBar(v) end
    if _G.__AdminSaveCfg then _G.__AdminSaveCfg() end
end)
-- Reorder so executor frame appears under the toggle visually:
execFrame.LayoutOrder = 99

------------------------------------------------------- THEMES TAB
local THEME_FILE = "seige_admin_theme.json"

local function hexToColor(h)
    if type(h) ~= "string" then return nil end
    h = h:gsub("#", ""):gsub("%s", "")
    if #h ~= 6 then return nil end
    local r = tonumber(h:sub(1,2),16); local g = tonumber(h:sub(3,4),16); local b = tonumber(h:sub(5,6),16)
    if not (r and g and b) then return nil end
    return Color3.fromRGB(r,g,b)
end
function cToHex(c)
    return string.format("#%02X%02X%02X",
        math.floor(c.R*255+0.5), math.floor(c.G*255+0.5), math.floor(c.B*255+0.5))
end

-- Walk all UI and remap any color that matches an old role color to the new one.
local function applyTheme(newT)
    local oldT = {}
    for k,v in pairs(T) do oldT[k] = v end
    for k,v in pairs(newT) do if typeof(v) == "Color3" then T[k] = v end end
    for _, d in ipairs(Root:GetDescendants()) do
        for k, oc in pairs(oldT) do
            local nc = T[k]
            if nc and oc ~= nc then
                pcall(function() if d.BackgroundColor3 == oc then d.BackgroundColor3 = nc end end)
                pcall(function() if d.TextColor3 == oc then d.TextColor3 = nc end end)
                pcall(function() if d.ImageColor3 == oc then d.ImageColor3 = nc end end)
                pcall(function() if d.PlaceholderColor3 == oc then d.PlaceholderColor3 = nc end end)
                pcall(function() if d.ScrollBarImageColor3 == oc then d.ScrollBarImageColor3 = nc end end)
                if d:IsA("UIStroke") and d.Color == oc then d.Color = nc end
            end
        end
    end
end

bgState = { image = "", trans = 0.4 }
local function resolveBgUrl(s)
    if not s or s == "" then return "" end
    s = tostring(s):gsub("^%s+",""):gsub("%s+$","")
    if tonumber(s) then return "rbxassetid://" .. s end
    if s:match("^rbxassetid://") or s:match("^rbxthumb://") or s:match("^https?://") or s:match("^rbxasset://") then
        return s
    end
    local gca = rawget(getfenv(), "getcustomasset") or rawget(getfenv(), "getsynasset")
    if type(gca) == "function" then
        local ok, v = pcall(gca, s); if ok and v then return v end
    end
    return s
end
local function applyBg()
    Backdrop.Image = resolveBgUrl(bgState.image)
    Backdrop.ImageTransparency = bgState.trans
end

-- Per-panel background image (applied to every floating panel's __SeigeBgImg)
panelBgState = { image = "", trans = 0.5, panels = {}, icons = {} }
function applyPanelBg()
    local gUrl = resolveBgUrl(panelBgState.image)
    local panelsTbl = rawget(_G, "__SeigePanels")
    if not panelsTbl then return end
    for name, p in pairs(panelsTbl) do
        local img = p.frame and p.frame:FindFirstChild("__SeigeBgImg")
        if img then
            local ov = panelBgState.panels and panelBgState.panels[name]
            local url, trans
            if ov and ov.image and ov.image ~= "" then
                url = resolveBgUrl(ov.image)
                trans = tonumber(ov.trans) or panelBgState.trans
            else
                url = gUrl
                trans = panelBgState.trans
            end
            img.Image = url
            img.ImageTransparency = (url == "") and 1 or trans
        end
    end
end
function applyIconImages()
    local panelsTbl = rawget(_G, "__SeigePanels")
    if not panelsTbl then return end
    for name, p in pairs(panelsTbl) do
        if p.ibImg then
            local custom = panelBgState.icons and panelBgState.icons[name]
            if custom and custom ~= "" then
                p.ibImg.Image = resolveBgUrl(custom)
            elseif p.defaultIcon then
                p.ibImg.Image = p.defaultIcon
            end
        end
    end
end
_G.__SeigeApplyPanelBg = applyPanelBg
_G.__SeigeApplyIconImages = applyIconImages
_G.__SeigeApplyBg = applyBg
_G.__SeigeApplyTheme = applyTheme
_G.__SeigeApplyThemeHex = function(hexMap)
    if type(hexMap) ~= "table" then return end
    local newT = {}
    for k, hex in pairs(hexMap) do
        local h = tostring(hex):gsub("^#","")
        if #h == 6 then
            local r = tonumber(h:sub(1,2),16) or 0
            local g = tonumber(h:sub(3,4),16) or 0
            local b = tonumber(h:sub(5,6),16) or 0
            newT[k] = Color3.fromRGB(r,g,b)
        end
    end
    applyTheme(newT)
end



saveCfg = function()
    local data = { theme = {}, bg = bgState, panelBg = panelBgState, execEnabled = execEnabled }
    for k,v in pairs(T) do
        if typeof(v) == "Color3" then data.theme[k] = cToHex(v) end
    end
    local wf = rawget(getfenv(), "writefile")
    if wf then pcall(wf, THEME_FILE, HttpService:JSONEncode(data)) end
end
_G.__AdminSaveCfg = saveCfg

loadCfg = function()
    local rf = rawget(getfenv(), "readfile")
    local isf = rawget(getfenv(), "isfile")
    if not (rf and isf and isf(THEME_FILE)) then return end
    local ok, data = pcall(function() return HttpService:JSONDecode(rf(THEME_FILE)) end)
    if not ok or type(data) ~= "table" then return end
    if type(data.theme) == "table" then
        local newT = {}
        for k, hex in pairs(data.theme) do
            local c = hexToColor(hex); if c then newT[k] = c end
        end
        applyTheme(newT)
    end
    if type(data.bg) == "table" then
        bgState.image = data.bg.image or ""
        bgState.trans = tonumber(data.bg.trans) or 0.4
        applyBg()
    end
    if type(data.panelBg) == "table" then
        panelBgState.image = data.panelBg.image or ""
        panelBgState.trans = tonumber(data.panelBg.trans) or 0.5
        panelBgState.panels = (type(data.panelBg.panels) == "table") and data.panelBg.panels or {}
        panelBgState.icons = (type(data.panelBg.icons) == "table") and data.panelBg.icons or {}
        applyPanelBg()
        pcall(applyIconImages)
    end
end

section(pgThemes, "Background")
bgImgBox = textbox(pgThemes, "Image / GIF asset id or URL (rbxassetid://, http://...)", function(v)
    bgState.image = v; applyBg(); saveCfg()
    notify("Background updated", "good")
end)
slider(pgThemes, "Background opacity", 0, 1, 0.4, function(v)
    bgState.trans = 1 - v  -- slider 0=invisible, 1=fully visible
    applyBg(); saveCfg()
end)
button(pgThemes, "Clear background", function()
    bgState.image = ""; applyBg(); saveCfg(); notify("Background cleared", "good")
end)
label(pgThemes, "Tip: paste an asset id (numbers only) or full URL. GIFs require an animated asset.")

section(pgThemes, "Panel background (per-panel image)")
local panelBgBox = textbox(pgThemes, "Panel image asset id or URL", function(v)
    panelBgState.image = v; applyPanelBg(); saveCfg()
    notify(v == "" and "Panel background cleared" or "Panel background updated", "good")
end)
slider(pgThemes, "Panel image opacity", 0, 1, 0.5, function(v)
    panelBgState.trans = 1 - v
    applyPanelBg(); saveCfg()
end)
button(pgThemes, "Clear panel backgrounds", function()
    panelBgState.image = ""; applyPanelBg(); saveCfg(); notify("Panel backgrounds cleared", "good")
end)
label(pgThemes, "Applies to every floating panel (Profile, Cmds, Shaders, ...).")

section(pgThemes, "Presets")
local PRESETS = {
    ["Midnight (default)"] = {
        bg=Color3.fromRGB(12,13,18), bg2=Color3.fromRGB(20,22,30), bg3=Color3.fromRGB(32,36,48),
        line=Color3.fromRGB(60,66,82), text=Color3.fromRGB(240,242,248),
        sub=Color3.fromRGB(140,148,168), dim=Color3.fromRGB(90,96,112),
        acc=Color3.fromRGB(120,150,255), acc2=Color3.fromRGB(80,110,240),
    },
    ["Crimson"] = {
        bg=Color3.fromRGB(18,10,12), bg2=Color3.fromRGB(30,16,20), bg3=Color3.fromRGB(50,26,32),
        line=Color3.fromRGB(90,40,52), text=Color3.fromRGB(248,240,242),
        sub=Color3.fromRGB(180,140,150), dim=Color3.fromRGB(110,70,80),
        acc=Color3.fromRGB(240,80,110), acc2=Color3.fromRGB(200,40,80),
    },
    ["Emerald"] = {
        bg=Color3.fromRGB(10,18,14), bg2=Color3.fromRGB(16,30,22), bg3=Color3.fromRGB(26,50,36),
        line=Color3.fromRGB(40,90,60), text=Color3.fromRGB(240,248,244),
        sub=Color3.fromRGB(140,180,158), dim=Color3.fromRGB(70,110,84),
        acc=Color3.fromRGB(80,220,140), acc2=Color3.fromRGB(40,180,110),
    },
    ["Amethyst"] = {
        bg=Color3.fromRGB(16,12,22), bg2=Color3.fromRGB(26,20,38), bg3=Color3.fromRGB(44,32,64),
        line=Color3.fromRGB(80,60,120), text=Color3.fromRGB(244,240,250),
        sub=Color3.fromRGB(170,150,200), dim=Color3.fromRGB(100,84,140),
        acc=Color3.fromRGB(180,120,255), acc2=Color3.fromRGB(140,80,230),
    },
    ["Sunset"] = {
        bg=Color3.fromRGB(22,14,10), bg2=Color3.fromRGB(36,22,16), bg3=Color3.fromRGB(60,36,24),
        line=Color3.fromRGB(120,70,40), text=Color3.fromRGB(250,244,238),
        sub=Color3.fromRGB(200,160,130), dim=Color3.fromRGB(130,90,60),
        acc=Color3.fromRGB(255,160,80), acc2=Color3.fromRGB(230,110,60),
    },
    ["Mono Light"] = {
        bg=Color3.fromRGB(238,238,242), bg2=Color3.fromRGB(220,222,228), bg3=Color3.fromRGB(200,204,212),
        line=Color3.fromRGB(160,164,176), text=Color3.fromRGB(20,22,28),
        sub=Color3.fromRGB(90,96,110), dim=Color3.fromRGB(140,144,156),
        acc=Color3.fromRGB(60,90,200), acc2=Color3.fromRGB(40,70,180),
    },
}
local function applyPreset(name)
    local p = PRESETS[name]; if not p then return end
    applyTheme(p); saveCfg(); notify("Theme: " .. name, "good")
end
for name,_ in pairs(PRESETS) do
    button(pgThemes, name, function() applyPreset(name) end)
end

section(pgThemes, "Custom colors")
ROLE_ORDER = { "bg","bg2","bg3","line","text","sub","dim","acc","acc2","good","warn","bad" }
roleRows = {}
local function makeRoleRow(role)
    local row = inst("Frame", pgThemes, {
        Size = UDim2.new(1, -8, 0, 34),
        BackgroundColor3 = T.bg2, BackgroundTransparency = 0.3, BorderSizePixel = 0,
    })
    corner(row, 8); stroke(row, T.line, 1, 0.5)
    local lbl = inst("TextLabel", row, {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(0, 60, 1, 0),
        Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = T.text,
        TextXAlignment = Enum.TextXAlignment.Left, Text = role,
    })
    local sw = inst("Frame", row, {
        Position = UDim2.new(0, 76, 0.5, -10), Size = UDim2.new(0, 22, 0, 20),
        BackgroundColor3 = T[role] or T.acc, BorderSizePixel = 0,
    })
    corner(sw, 4); stroke(sw, T.line, 1, 0.4)
    local box = inst("TextBox", row, {
        BackgroundColor3 = T.bg, BackgroundTransparency = 0.2, BorderSizePixel = 0,
        Position = UDim2.new(0, 106, 0.5, -11), Size = UDim2.new(0, 100, 0, 22),
        Font = Enum.Font.Code, TextSize = 12, TextColor3 = T.text,
        Text = cToHex(T[role] or T.acc), ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Center,
    })
    corner(box, 6); stroke(box, T.line, 1, 0.4)
    local apply = inst("TextButton", row, {
        Position = UDim2.new(0, 214, 0.5, -11), Size = UDim2.new(0, 60, 0, 22),
        BackgroundColor3 = T.acc, BackgroundTransparency = 0.15, BorderSizePixel = 0,
        AutoButtonColor = false, Font = Enum.Font.GothamBold, TextSize = 11,
        TextColor3 = T.text, Text = "Apply",
    })
    corner(apply, 6); stroke(apply, T.line, 1, 0.4)
    local function doApply()
        local c = hexToColor(box.Text)
        if not c then notify("Invalid hex: " .. box.Text, "bad"); return end
        applyTheme({ [role] = c }); sw.BackgroundColor3 = T[role]; saveCfg()
    end
    apply.MouseButton1Click:Connect(doApply)
    box.FocusLost:Connect(function(enter) if enter then doApply() end end)
    roleRows[role] = { box = box, sw = sw }
end
for _, r in ipairs(ROLE_ORDER) do makeRoleRow(r) end

button(pgThemes, "Reset to default", function()
    applyPreset("Midnight (default)")
    bgState.image = ""; bgState.trans = 0.4; applyBg(); saveCfg()
    for _, r in ipairs(ROLE_ORDER) do
        if roleRows[r] then
            roleRows[r].box.Text = cToHex(T[r] or T.acc)
            roleRows[r].sw.BackgroundColor3 = T[r] or T.acc
        end
    end
end)
end)()

-- =============================================================
-- ===== Typography & Animation customisation ==================
-- =============================================================
;(function()
    section(pgThemes, "Typography")

    -- Build font list from the actual Enum so we never reference missing fonts.
    local FONT_PREF = {
        "GothamBold","Gotham","GothamMedium","GothamSemibold","GothamBlack",
        "BuilderSans","BuilderSansBold","BuilderSansExtraBold","BuilderSansMedium",
        "SourceSans","SourceSansBold","SourceSansSemibold","SourceSansLight",
        "Roboto","RobotoMono","Code","Highway","Arial","ArialBold",
        "Bodoni","Garamond","Cartoon","Fantasy","Antique","Legacy",
        "Oswald","Merriweather","Nunito","Ubuntu","Jura","Kalam",
        "Creepster","DenkOne","Fondamento","Inconsolata","LuckiestGuy",
        "PatrickHand","PermanentMarker","Sarpanch","Michroma",
    }
    local FONTS = {}
    for _, n in ipairs(FONT_PREF) do
        if pcall(function() return Enum.Font[n] end) and Enum.Font[n] then
            table.insert(FONTS, n)
        end
    end
    table.insert(FONTS, 1, "Default (mixed)")

    -- Snapshot every text element's *original* font + size once, so font/size
    -- changes can be re-applied without compounding.
    local fontBaseline = {}
    local function snapshot(d)
        if fontBaseline[d] then return end
        if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
            fontBaseline[d] = { font = d.Font, size = d.TextSize }
        end
    end
    for _, d in ipairs(Root:GetDescendants()) do snapshot(d) end
    Root.DescendantAdded:Connect(snapshot)

    _G.__SeigeFontOverride = _G.__SeigeFontOverride or "Default (mixed)"
    _G.__SeigeFontScale    = _G.__SeigeFontScale    or 1.0

    local function applyTypography()
        local override = _G.__SeigeFontOverride
        local scale    = tonumber(_G.__SeigeFontScale) or 1.0
        local enumFont = (override ~= "Default (mixed)") and Enum.Font[override] or nil
        for d, base in pairs(fontBaseline) do
            if d.Parent then
                pcall(function()
                    d.Font     = enumFont or base.font
                    d.TextSize = math.max(8, math.floor(base.size * scale + 0.5))
                end)
            end
        end
    end
    _G.__SeigeApplyTypography = applyTypography

    dropdown(pgThemes, "UI font family", FONTS, function(v)
        _G.__SeigeFontOverride = v; applyTypography(); saveCfg()
    end)
    slider(pgThemes, "Text size (%)", 60, 180, 100, function(v)
        _G.__SeigeFontScale = v / 100; applyTypography()
    end)

    -- (Global "Tag font (dafont styles)" setting removed — per-user font lives in the Tags panel.)

    section(pgThemes, "Bubble animations  (player tags)")

    local BUBBLE = { "None", "Bounce", "Pulse", "Float", "Wobble", "Shake", "Heartbeat" }
    _G.__SeigeBubbleAnim = _G.__SeigeBubbleAnim or "None"
    _G.__SeigeBubbleAnimCtl = dropdown(pgThemes, "Tag bubble animation", BUBBLE, function(v)
        _G.__SeigeBubbleAnim = v; saveCfg()
    end)
    _G.__SeigeBubbleAmtCtl = slider(pgThemes, "Bubble anim intensity", 0, 100, 50, function(v)
        _G.__SeigeBubbleAmt = v / 100; saveCfg()
    end)

    section(pgThemes, "Page / panel animations")
    local PAGE = { "None", "Fade", "Scale", "Slide-down", "Slide-up", "Slide-right", "Flip", "Bounce" }
    _G.__SeigePageAnim = _G.__SeigePageAnim or "Fade"
    _G.__SeigePageAnimCtl = dropdown(pgThemes, "Panel open animation", PAGE, function(v)
        _G.__SeigePageAnim = v; saveCfg()
    end)
    _G.__SeigePageAnimSpeedCtl = slider(pgThemes, "Animation speed (ms)", 80, 700, 240, function(v)
        _G.__SeigePageAnimSpeed = v / 1000; saveCfg()
    end)
end)()

-- Restore saved theme/background/exec preferences after all UI exists.
task.spawn(function()
    pcall(loadCfg)
    -- refresh hex inputs after load
    for _, r in ipairs(ROLE_ORDER) do
        if roleRows[r] then
            roleRows[r].box.Text = cToHex(T[r] or T.acc)
            roleRows[r].sw.BackgroundColor3 = T[r] or T.acc
        end
    end
    if bgState.image ~= "" then bgImgBox.Text = bgState.image end
end)

------------------------------------------------------- SHADERS TAB
do -- scoped to avoid bumping the top-level local limit
-- Real Roblox post-processing effects parented to Lighting
local Lighting = game:GetService("Lighting")
local function getOrMake(class, name)
    local e = Lighting:FindFirstChild(name)
    if not e or not e:IsA(class) then
        if e then e:Destroy() end
        e = Instance.new(class)
        e.Name = name
        e.Enabled = false
        e.Parent = Lighting
    end
    return e
end
local fxBloom  = getOrMake("BloomEffect",          "SeigeBloom")
local fxBlur   = getOrMake("BlurEffect",           "SeigeBlur")
local fxColor  = getOrMake("ColorCorrectionEffect","SeigeColor")
local fxDOF    = getOrMake("DepthOfFieldEffect",   "SeigeDOF")
local fxSun    = getOrMake("SunRaysEffect",        "SeigeSun")

section(pgShaders, "Graphics Quality")
local _savedTech, _savedShadows, _savedSoft, _savedDif, _savedSpc
toggle(pgShaders, "Maximum visuals", false, function(on)
    local Lighting = game:GetService("Lighting")
    if on then
        _savedTech   = Lighting.Technology
        _savedShadows = Lighting.GlobalShadows
        _savedSoft   = Lighting.ShadowSoftness
        _savedDif    = Lighting.EnvironmentDiffuseScale
        _savedSpc    = Lighting.EnvironmentSpecularScale
        pcall(function()
            Lighting.Technology = Enum.Technology.Future
            Lighting.GlobalShadows = true
            Lighting.ShadowSoftness = 0.2
            Lighting.EnvironmentDiffuseScale = 1
            Lighting.EnvironmentSpecularScale = 1
        end)
        notify("Quality: Maximum visuals enabled", "good")
    else
        pcall(function()
            Lighting.Technology = (_savedTech ~= nil) and _savedTech or Enum.Technology.Compatibility
            Lighting.GlobalShadows = (_savedShadows ~= nil) and _savedShadows or false
            Lighting.ShadowSoftness = (_savedSoft ~= nil) and _savedSoft or 1
            Lighting.EnvironmentDiffuseScale = (_savedDif ~= nil) and _savedDif or 0
            Lighting.EnvironmentSpecularScale = (_savedSpc ~= nil) and _savedSpc or 0
        end)
        notify("Quality: Performance mode enabled", "good")
    end
end)

section(pgShaders, "Bloom")
toggle(pgShaders, "Enable bloom", false, function(v) fxBloom.Enabled = v end)
slider(pgShaders, "Intensity",  0, 4,   1,    function(v) fxBloom.Intensity = v end)
slider(pgShaders, "Size",       0, 56,  24,   function(v) fxBloom.Size = v end)
slider(pgShaders, "Threshold",  0, 4,   0.95, function(v) fxBloom.Threshold = v end)

section(pgShaders, "Blur")
toggle(pgShaders, "Enable blur", false, function(v) fxBlur.Enabled = v end)
slider(pgShaders, "Blur size", 0, 56, 16, function(v) fxBlur.Size = v end)

section(pgShaders, "Color correction")
toggle(pgShaders, "Enable color", false, function(v) fxColor.Enabled = v end)
slider(pgShaders, "Brightness", -1, 1, 0,  function(v) fxColor.Brightness = v end)
slider(pgShaders, "Contrast",   -1, 1, 0,  function(v) fxColor.Contrast = v end)
slider(pgShaders, "Saturation", -1, 5, 0,  function(v) fxColor.Saturation = v end)
local tintBox = textbox(pgShaders, "Tint hex (#ffffff)", function(s)
    local h = (s or ""):gsub("#","")
    if #h == 6 then
        local ok, c = pcall(function() return Color3.fromHex(h) end)
        if ok then fxColor.TintColor = c end
    end
end)
button(pgShaders, "Clear tint (reset to white)", function()
    fxColor.TintColor = Color3.new(1, 1, 1)
    if tintBox then tintBox.Text = "" end
    notify("Tint cleared", "good")
end)

section(pgShaders, "Depth of field")
toggle(pgShaders, "Enable DOF", false, function(v) fxDOF.Enabled = v end)
slider(pgShaders, "Focus distance",  0, 200, 25, function(v) fxDOF.FocusDistance = v end)
slider(pgShaders, "In focus radius", 0, 100, 8,  function(v) fxDOF.InFocusRadius = v end)
slider(pgShaders, "Near intensity",  0, 1,   0.25, function(v) fxDOF.NearIntensity = v end)
slider(pgShaders, "Far intensity",   0, 1,   0.75, function(v) fxDOF.FarIntensity = v end)

section(pgShaders, "Sun rays")
toggle(pgShaders, "Enable sun rays", false, function(v) fxSun.Enabled = v end)
slider(pgShaders, "Ray intensity", 0, 1, 0.25, function(v) fxSun.Intensity = v end)
slider(pgShaders, "Ray spread",    0, 1, 1,    function(v) fxSun.Spread = v end)

section(pgShaders, "Weather")
do
    local W = { mode = "Off", intensity = 0.5 }
    _G.__SeigeWeather = W

    local function clear()
        if W.atmos then pcall(function() W.atmos:Destroy() end); W.atmos = nil end
        if W.emitter then pcall(function() W.emitter:Destroy() end); W.emitter = nil end
        if W.attach then pcall(function() W.attach:Destroy() end); W.attach = nil end
        if W.thunderConn then pcall(function() W.thunderConn:Disconnect() end); W.thunderConn = nil end
        if W.charConn then pcall(function() W.charConn:Disconnect() end); W.charConn = nil end
        if W.flash then pcall(function() W.flash:Destroy() end); W.flash = nil end
        pcall(function()
            local t = workspace:FindFirstChildOfClass("Terrain")
            local c = t and t:FindFirstChild("__SeigeClouds")
            if c then c:Destroy() end
        end)
    end

    local function ensureAtmos()
        local a = Instance.new("Atmosphere")
        a.Name = "__SeigeAtmos"
        a.Parent = Lighting
        W.atmos = a
        return a
    end

    local function attachParticle(asset, rate, speed, accel, size, lifetime, rot)
        -- Particles originate from a flat plate anchored ABOVE the camera so the
        -- effect falls down across the screen instead of pouring out of the avatar.
        local part = Instance.new("Part")
        part.Name = "__SeigeWeatherPart"
        part.Size = Vector3.new(160, 1, 160)
        part.Transparency = 1
        part.CanCollide = false
        part.CanQuery = false
        part.CanTouch = false
        part.Anchored = true
        part.Massless = true
        part.TopSurface = Enum.SurfaceType.Smooth
        part.BottomSurface = Enum.SurfaceType.Smooth
        part.Parent = workspace
        local att = Instance.new("Attachment")
        att.Name = "__SeigeWeatherAtt"
        att.Parent = part
        local pe = Instance.new("ParticleEmitter")
        pe.Name = "__SeigeWeatherFX"
        pe.Texture = asset
        pe.Rate = rate
        pe.Speed = NumberRange.new(speed)
        pe.Acceleration = accel
        pe.Size = NumberSequence.new(size)
        pe.Lifetime = NumberRange.new(lifetime)
        pe.Rotation = NumberRange.new(-rot, rot)
        pe.LightEmission = 0.2
        pe.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.2),
            NumberSequenceKeypoint.new(1, 1),
        })
        pe.EmissionDirection = Enum.NormalId.Bottom
        pe.SpreadAngle = Vector2.new(20, 20)
        pe.Parent = att
        W.attach = part
        W.emitter = pe
        -- Keep the plate centered above the camera each frame.
        W.charConn = RunService.RenderStepped:Connect(function()
            local c = workspace.CurrentCamera
            if not c then return end
            part.CFrame = CFrame.new(c.CFrame.Position + Vector3.new(0, 80, 0))
        end)
    end

    local function apply()
        clear()
        local i = math.clamp(W.intensity or 0.5, 0, 1)
        if W.mode == "Off" then return end

        if W.mode == "Cloudy" then
            local a = ensureAtmos()
            a.Density = 0.3 * i
            a.Haze = 1.5 * i
            a.Color = Color3.fromRGB(190, 195, 205)
            local t = workspace:FindFirstChildOfClass("Terrain")
            if t then
                local c = Instance.new("Clouds")
                c.Name = "__SeigeClouds"
                c.Cover = 0.6 + 0.4 * i
                c.Density = 0.5 + 0.5 * i
                c.Color = Color3.fromRGB(220, 220, 230)
                c.Parent = t
            end
        elseif W.mode == "Fog" then
            local a = ensureAtmos()
            a.Density = 0.6 * i
            a.Haze = 3 * i
            a.Glare = 0.5 * i
            a.Color = Color3.fromRGB(200, 200, 200)
        elseif W.mode == "Rain" then
            attachParticle("rbxassetid://241876428", 200 * i + 50, 60, Vector3.new(0, -120, 0), 0.5, 1.2, 0)
            local a = ensureAtmos()
            a.Density = 0.25 * i
            a.Haze = 1 * i
            a.Color = Color3.fromRGB(170, 175, 185)
        elseif W.mode == "Thunder" then
            attachParticle("rbxassetid://241876428", 260 * i + 80, 70, Vector3.new(0, -140, 0), 0.55, 1.2, 0)
            local a = ensureAtmos()
            a.Density = 0.4 * i
            a.Haze = 2 * i
            a.Color = Color3.fromRGB(140, 145, 160)
            local fxFlash = Instance.new("ColorCorrectionEffect")
            fxFlash.Name = "__SeigeFlash"
            fxFlash.Brightness = 0
            fxFlash.Parent = Lighting
            W.flash = fxFlash
            local nextStrike = tick() + math.random(4, 9)
            W.thunderConn = RunService.Heartbeat:Connect(function()
                if tick() < nextStrike then return end
                nextStrike = tick() + math.random(5, 12)
                task.spawn(function()
                    pcall(function()
                        for _, b in ipairs({0.8, 0.0, 0.6, 0.0}) do
                            fxFlash.Brightness = b
                            task.wait(0.07)
                        end
                        fxFlash.Brightness = 0
                        local s = Instance.new("Sound")
                        s.SoundId = "rbxassetid://5801257793"
                        s.Volume = 1.5 * i
                        s.Parent = workspace
                        s:Play()
                        game:GetService("Debris"):AddItem(s, 6)
                    end)
                end)
            end)
        elseif W.mode == "Snow" then
            attachParticle("rbxassetid://241876428", 120 * i + 40, 4, Vector3.new(0, -8, 1), 0.35, 5, 90)
            local a = ensureAtmos()
            a.Density = 0.2 * i
            a.Haze = 1.2 * i
            a.Color = Color3.fromRGB(220, 225, 235)
        end
    end

    dropdown(pgShaders, "Weather", { "Off", "Cloudy", "Fog", "Rain", "Thunder", "Snow" }, function(o)
        W.mode = o; apply()
    end)
    slider(pgShaders, "Weather intensity", 0, 1, 0.5, function(v)
        W.intensity = v; if W.mode ~= "Off" then apply() end
    end)
    button(pgShaders, "Clear weather", function() W.mode = "Off"; clear() end)
end

section(pgShaders, "Presets")
local function applyShader(preset)
    if preset == "Off" then
        for _, fx in ipairs({fxBloom, fxBlur, fxColor, fxDOF, fxSun}) do fx.Enabled = false end
    elseif preset == "Cinematic" then
        fxBloom.Enabled = true; fxBloom.Intensity = 0.8; fxBloom.Size = 30; fxBloom.Threshold = 1.2
        fxColor.Enabled = true; fxColor.Contrast = 0.15; fxColor.Saturation = -0.1; fxColor.TintColor = Color3.fromRGB(255,240,220)
        fxDOF.Enabled = true; fxDOF.FocusDistance = 30; fxDOF.InFocusRadius = 12; fxDOF.FarIntensity = 0.6; fxDOF.NearIntensity = 0.2
    elseif preset == "Dreamy" then
        fxBloom.Enabled = true; fxBloom.Intensity = 1.6; fxBloom.Size = 40; fxBloom.Threshold = 0.7
        fxBlur.Enabled = true; fxBlur.Size = 6
        fxSun.Enabled = true; fxSun.Intensity = 0.35
    elseif preset == "Noir" then
        fxColor.Enabled = true; fxColor.Saturation = -1; fxColor.Contrast = 0.35; fxColor.Brightness = -0.05
        fxBloom.Enabled = true; fxBloom.Intensity = 0.4; fxBloom.Threshold = 1.5
    elseif preset == "Vibrant" then
        fxColor.Enabled = true; fxColor.Saturation = 0.6; fxColor.Contrast = 0.2; fxColor.TintColor = Color3.new(1,1,1)
        fxBloom.Enabled = true; fxBloom.Intensity = 0.7; fxBloom.Size = 24; fxBloom.Threshold = 1
    elseif preset == "4K Ultra" then
        -- crisp, vivid, "high-def TV" look: punchy contrast, clean bloom, subtle DOF, no blur
        fxBlur.Enabled = false
        fxColor.Enabled  = true
        fxColor.Brightness = 0.04
        fxColor.Contrast   = 0.28
        fxColor.Saturation = 0.45
        fxColor.TintColor  = Color3.fromRGB(255, 250, 244)
        fxBloom.Enabled    = true
        fxBloom.Intensity  = 0.55
        fxBloom.Size       = 18
        fxBloom.Threshold  = 1.15
        fxSun.Enabled      = true
        fxSun.Intensity    = 0.18
        fxSun.Spread       = 0.9
        fxDOF.Enabled      = true
        fxDOF.FocusDistance = 60
        fxDOF.InFocusRadius = 40
        fxDOF.FarIntensity  = 0.35
        fxDOF.NearIntensity = 0.05
        -- crank lighting quality so it actually looks HD
        pcall(function()
            Lighting.GlobalShadows  = true
            Lighting.ShadowSoftness = 0.2
            Lighting.EnvironmentDiffuseScale  = 1
            Lighting.EnvironmentSpecularScale = 1
            Lighting.Technology = Enum.Technology.Future
        end)
    elseif preset == "Pink" then
        fxColor.Enabled = true; fxColor.Saturation = 0.4; fxColor.Contrast = 0.1; fxColor.Brightness = 0.02
        fxColor.TintColor = Color3.fromRGB(255, 170, 200)
        fxBloom.Enabled = true; fxBloom.Intensity = 0.65; fxBloom.Size = 22; fxBloom.Threshold = 1.0
        fxDOF.Enabled = true; fxDOF.FocusDistance = 25; fxDOF.InFocusRadius = 14; fxDOF.FarIntensity = 0.4; fxDOF.NearIntensity = 0.15
        fxBlur.Enabled = false
        fxSun.Enabled = false
    elseif preset == "Molten" then
        fxColor.Enabled = true; fxColor.Saturation = 0.35; fxColor.Contrast = 0.25; fxColor.Brightness = -0.04
        fxColor.TintColor = Color3.fromRGB(255, 90, 30)
        fxBloom.Enabled = true; fxBloom.Intensity = 1.1; fxBloom.Size = 30; fxBloom.Threshold = 0.75
        fxSun.Enabled = true; fxSun.Intensity = 0.45; fxSun.Spread = 1
        fxDOF.Enabled = true; fxDOF.FocusDistance = 35; fxDOF.InFocusRadius = 10; fxDOF.FarIntensity = 0.5; fxDOF.NearIntensity = 0.2
        fxBlur.Enabled = false
    elseif preset == "Matrix" then
        fxColor.Enabled = true; fxColor.Saturation = 0.25; fxColor.Contrast = 0.3; fxColor.Brightness = -0.02
        fxColor.TintColor = Color3.fromRGB(60, 255, 100)
        fxBloom.Enabled = true; fxBloom.Intensity = 0.5; fxBloom.Size = 16; fxBloom.Threshold = 1.2
        fxDOF.Enabled = true; fxDOF.FocusDistance = 45; fxDOF.InFocusRadius = 20; fxDOF.FarIntensity = 0.3; fxDOF.NearIntensity = 0.1
        fxBlur.Enabled = false
        fxSun.Enabled = false
    elseif preset == "Cyberpunk" then
        fxColor.Enabled = true; fxColor.Saturation = 0.55; fxColor.Contrast = 0.2; fxColor.Brightness = 0.02
        fxColor.TintColor = Color3.fromRGB(210, 60, 255)
        fxBloom.Enabled = true; fxBloom.Intensity = 0.95; fxBloom.Size = 26; fxBloom.Threshold = 0.85
        fxBlur.Enabled = true; fxBlur.Size = 3
        fxDOF.Enabled = true; fxDOF.FocusDistance = 30; fxDOF.InFocusRadius = 12; fxDOF.FarIntensity = 0.45; fxDOF.NearIntensity = 0.15
        fxSun.Enabled = true; fxSun.Intensity = 0.2; fxSun.Spread = 0.7
    elseif preset == "Golden Hour" then
        fxColor.Enabled = true; fxColor.Saturation = 0.25; fxColor.Contrast = 0.1; fxColor.Brightness = 0.06
        fxColor.TintColor = Color3.fromRGB(255, 190, 100)
        fxBloom.Enabled = true; fxBloom.Intensity = 0.75; fxBloom.Size = 28; fxBloom.Threshold = 1.05
        fxSun.Enabled = true; fxSun.Intensity = 0.55; fxSun.Spread = 1
        fxDOF.Enabled = true; fxDOF.FocusDistance = 40; fxDOF.InFocusRadius = 18; fxDOF.FarIntensity = 0.35; fxDOF.NearIntensity = 0.1
        fxBlur.Enabled = false
    elseif preset == "Vaporwave" then
        fxColor.Enabled = true; fxColor.Saturation = 0.45; fxColor.Contrast = 0.15; fxColor.Brightness = 0.03
        fxColor.TintColor = Color3.fromRGB(255, 120, 220)
        fxBloom.Enabled = true; fxBloom.Intensity = 1.3; fxBloom.Size = 34; fxBloom.Threshold = 0.7
        fxBlur.Enabled = true; fxBlur.Size = 4
        fxDOF.Enabled = true; fxDOF.FocusDistance = 28; fxDOF.InFocusRadius = 10; fxDOF.FarIntensity = 0.5; fxDOF.NearIntensity = 0.2
        fxSun.Enabled = true; fxSun.Intensity = 0.3; fxSun.Spread = 0.85
    elseif preset == "Winter" then
        fxColor.Enabled = true; fxColor.Saturation = -0.15; fxColor.Contrast = 0.15; fxColor.Brightness = 0.08
        fxColor.TintColor = Color3.fromRGB(200, 225, 255)
        fxBloom.Enabled = true; fxBloom.Intensity = 0.4; fxBloom.Size = 20; fxBloom.Threshold = 1.3
        fxDOF.Enabled = true; fxDOF.FocusDistance = 50; fxDOF.InFocusRadius = 25; fxDOF.FarIntensity = 0.3; fxDOF.NearIntensity = 0.05
        fxBlur.Enabled = false
        fxSun.Enabled = true; fxSun.Intensity = 0.15; fxSun.Spread = 0.9
    elseif preset == "8K Photoreal" then
        -- next-tier upgrade of 4K Ultra: razor-sharp, neutral, balanced HDR feel
        fxBlur.Enabled = false
        fxColor.Enabled = true
        fxColor.Brightness = 0.02
        fxColor.Contrast   = 0.34
        fxColor.Saturation = 0.32
        fxColor.TintColor  = Color3.fromRGB(255, 252, 248)
        fxBloom.Enabled = true; fxBloom.Intensity = 0.45; fxBloom.Size = 16; fxBloom.Threshold = 1.25
        fxSun.Enabled = true; fxSun.Intensity = 0.22; fxSun.Spread = 0.95
        fxDOF.Enabled = true; fxDOF.FocusDistance = 80; fxDOF.InFocusRadius = 55; fxDOF.FarIntensity = 0.3; fxDOF.NearIntensity = 0.04
        pcall(function()
            Lighting.GlobalShadows = true; Lighting.ShadowSoftness = 0.15
            Lighting.EnvironmentDiffuseScale = 1; Lighting.EnvironmentSpecularScale = 1
            Lighting.Technology = Enum.Technology.Future
        end)
    elseif preset == "Anime" then
        fxBlur.Enabled = false
        fxColor.Enabled = true; fxColor.Saturation = 0.8; fxColor.Contrast = 0.25; fxColor.Brightness = 0.05
        fxColor.TintColor = Color3.fromRGB(255, 245, 255)
        fxBloom.Enabled = true; fxBloom.Intensity = 1.2; fxBloom.Size = 28; fxBloom.Threshold = 0.85
        fxSun.Enabled = true; fxSun.Intensity = 0.4; fxSun.Spread = 1
        fxDOF.Enabled = true; fxDOF.FocusDistance = 35; fxDOF.InFocusRadius = 16; fxDOF.FarIntensity = 0.45; fxDOF.NearIntensity = 0.1
    elseif preset == "Retro CRT" then
        fxColor.Enabled = true; fxColor.Saturation = -0.05; fxColor.Contrast = 0.4; fxColor.Brightness = -0.06
        fxColor.TintColor = Color3.fromRGB(220, 235, 220)
        fxBloom.Enabled = true; fxBloom.Intensity = 1.0; fxBloom.Size = 36; fxBloom.Threshold = 0.65
        fxBlur.Enabled = true; fxBlur.Size = 2
        fxSun.Enabled = false
        fxDOF.Enabled = false
    elseif preset == "Underwater" then
        fxColor.Enabled = true; fxColor.Saturation = 0.2; fxColor.Contrast = 0.1; fxColor.Brightness = -0.05
        fxColor.TintColor = Color3.fromRGB(90, 170, 220)
        fxBlur.Enabled = true; fxBlur.Size = 8
        fxBloom.Enabled = true; fxBloom.Intensity = 0.6; fxBloom.Size = 30; fxBloom.Threshold = 0.95
        fxSun.Enabled = true; fxSun.Intensity = 0.5; fxSun.Spread = 1
        fxDOF.Enabled = true; fxDOF.FocusDistance = 20; fxDOF.InFocusRadius = 8; fxDOF.FarIntensity = 0.7; fxDOF.NearIntensity = 0.25
    elseif preset == "Horror" then
        fxColor.Enabled = true; fxColor.Saturation = -0.6; fxColor.Contrast = 0.45; fxColor.Brightness = -0.18
        fxColor.TintColor = Color3.fromRGB(180, 190, 200)
        fxBloom.Enabled = true; fxBloom.Intensity = 0.3; fxBloom.Size = 18; fxBloom.Threshold = 1.4
        fxBlur.Enabled = true; fxBlur.Size = 3
        fxDOF.Enabled = true; fxDOF.FocusDistance = 22; fxDOF.InFocusRadius = 6; fxDOF.FarIntensity = 0.85; fxDOF.NearIntensity = 0.3
        fxSun.Enabled = false
    end
end
for _, name in ipairs({"Off","Cinematic","Dreamy","Noir","Vibrant","4K Ultra","8K Photoreal","Anime","Retro CRT","Underwater","Horror","Pink","Molten","Matrix","Cyberpunk","Golden Hour","Vaporwave","Winter"}) do
    button(pgShaders, name, function() applyShader(name) end)
end
end -- end shaders scope

------------------------------------------------------- CONFIG TAB

-- defaults for everything saveable in this tab
local CFG_DEFAULTS = {
    toggleKey   = "F2",
    uiScale     = 1,
    reducedMotion = false,
    layoutMode  = "Bar",
    uiTrans     = 0.35,
    skybox      = { Up = "", Dn = "", Lf = "", Rt = "", Ft = "", Bk = "" },
    fx          = { Profile = true, Players = false, Cmds = false, Shaders = false, Spotify = false, Misc = false },
}
local CFG_FILE = "SeigeAdmin/config.json"

-- forward declarations so the Save/Reset buttons can live at the very top
local snapshotCfg, applyCfg, saveCfg, loadCfg
local layoutCtl, transCtl

------------------------------------------------------- SAVE / RESET (top)
-- Pin these to the very top of the Config tab using negative LayoutOrder so
-- they sort above the Background / Themes / Typography sections (which are
-- added to the same page earlier in the file via pgThemes = pgConfig).
do -- scoped to keep these out of the main chunk's 200-local budget
local _saveSec = section(pgConfig, "Save & Reset")
local _saveLbl = label(pgConfig, "Save persists translucency, layout, typography, tag font, animations, theme colors, background & panel images. Reset clears them.")
local _saveBtn = button(pgConfig, "💾  Save Config", function()
    if saveCfg then saveCfg() else notify("Config not ready yet", "warn") end
end)
local _resetBtn = button(pgConfig, "↺  Reset to Defaults", function()
    _G.__SeigeSessionCfg = nil
    local wf = rawget(getfenv(), "delfile") or delfile
    if wf then pcall(wf, CFG_FILE) end
    if applyCfg then
        applyCfg(CFG_DEFAULTS, { applySkybox = true })
        notify("Config reset to defaults", "good")
    end
end)
pcall(function() _saveSec.LayoutOrder = -1000 end)
pcall(function() (_saveLbl.frame or _saveLbl).LayoutOrder = -999 end)
pcall(function() _saveBtn.LayoutOrder = -998 end)
pcall(function() _resetBtn.LayoutOrder = -997 end)
end


(function() -- function scope: new 200-local budget for Settings/Layout/Skybox/FX/Cfg
section(pgConfig, "Settings")
local toggleKey = Enum.KeyCode.F2
local awaitingKey = false
local keyBtn = button(pgConfig, "Toggle key: F2  (click to rebind)", function()
    awaitingKey = true
end)
local function setToggleKey(name)
    local kc = Enum.KeyCode[name] or Enum.KeyCode.F2
    toggleKey = kc
    keyBtn.Text = "Toggle key: " .. kc.Name .. "  (click to rebind)"
end
bind(UIS.InputBegan:Connect(function(i, gp)
    if awaitingKey and i.UserInputType == Enum.UserInputType.Keyboard then
        toggleKey = i.KeyCode
        keyBtn.Text = "Toggle key: " .. i.KeyCode.Name .. "  (click to rebind)"
        awaitingKey = false
        return
    end
    if not gp and i.UserInputType == Enum.UserInputType.Keyboard and i.KeyCode == toggleKey then
        Win.Visible = not Win.Visible
    end
end))

local uiScaleCtl = slider(pgConfig, "UI scale", 0.7, 1.4, 1, function(v)
    local s = Win:FindFirstChildOfClass("UIScale") or inst("UIScale", Win, { Scale = 1 })
    s.Scale = v
end)

local reducedCtl = toggle(pgConfig, "Reduced motion", _G.__SeigeReducedMotion, function(v)
    _G.__SeigeReducedMotion = v
end)

------------------------------------------------------- LAYOUT & TRANSLUCENCY
section(pgConfig, "Layout")
label(pgConfig, "Top bar style. Hamburger collapses the bar into a ≡ menu — tabs drop down from it.")
local _layoutMode = _G.__SeigeLayoutMode or "Bar"
local _layoutDef = _G.__SeigeLayoutMode or "Bar"
layoutCtl = dropdown(pgConfig, "Top bar layout", { "Bar", "Hamburger", "Dock" }, function(v)
    _layoutMode = v
    _G.__SeigeLayoutMode = v
    if _G.__SeigeApplyLayout then _G.__SeigeApplyLayout(v) end
    if saveCfg then pcall(saveCfg) end
end)
if layoutCtl and layoutCtl.set then layoutCtl.set(_G.__SeigeLayoutMode or "Bar") end

label(pgConfig, "Panel translucency — higher = more see-through")
transCtl = slider(pgConfig, "Panel translucency", 0, 0.85, _G.__SeigeUITrans or 0.35, function(v)
    if _G.__SeigeApplyUITrans then _G.__SeigeApplyUITrans(v) end
    if saveCfg then pcall(saveCfg) end
end)


section(pgConfig, "World Image (Skybox)")
label(pgConfig, "6 cubed faces — paste a Roblox asset id/URL, or a local image file path from your PC")
local skyboxFaces, skyboxBoxes, applySkybox, resetSkybox
do
    local Lighting = game:GetService("Lighting")
    local _isfile       = rawget(getfenv(), "isfile")       or isfile
    local _getcustom    = (getcustomasset or getsynasset or nil)

    local function isLocalPath(v)
        if type(v) ~= "string" or v == "" then return false end
        if not v:lower():match("%.png$") and not v:lower():match("%.jpe?g$")
           and not v:lower():match("%.bmp$") and not v:lower():match("%.tga$") then
            return false
        end
        if _isfile then
            local ok, exists = pcall(_isfile, v)
            return ok and exists
        end
        return true
    end

    local function norm(v)
        v = tostring(v or ""):gsub("^%s+", ""):gsub("%s+$", "")
        if v == "" then return "" end
        if isLocalPath(v) then
            if not _getcustom then
                notify("Your executor does not support local file uploads (getcustomasset)", "warn")
                return ""
            end
            local ok, url = pcall(_getcustom, v)
            if ok and type(url) == "string" then return url end
            notify("Failed to load local file: " .. v, "err")
            return ""
        end
        if v:match("^%d+$") then return "rbxassetid://" .. v end
        local id = v:match("[?&]id=(%d+)") or v:match("/(%d+)/?$")
        if id then return "rbxassetid://" .. id end
        return v
    end

    skyboxFaces = { Up = "", Dn = "", Lf = "", Rt = "", Ft = "", Bk = "" }
    skyboxBoxes = {}
    local labels = { Up = "Top (Up)", Dn = "Bottom (Down)", Lf = "Left", Rt = "Right", Ft = "Front", Bk = "Back" }
    for _, k in ipairs({ "Up", "Dn", "Lf", "Rt", "Ft", "Bk" }) do
        skyboxBoxes[k] = textbox(pgConfig, labels[k] .. " — asset id / URL / PC file path", function(v)
            skyboxFaces[k] = norm(v)
        end)
    end

    button(pgConfig, "Apply To All Faces (single image)", function()
        local v = skyboxFaces.Up
        if v == "" then notify("Fill the Top field first", "warn") return end
        skyboxFaces.Dn, skyboxFaces.Lf, skyboxFaces.Rt, skyboxFaces.Ft, skyboxFaces.Bk = v, v, v, v, v
        notify("Copied Top to all faces", "ok")
    end)

    applySkybox = function()
        for _, c in ipairs(Lighting:GetChildren()) do
            if c:IsA("Sky") then c:Destroy() end
        end
        local sky = Instance.new("Sky")
        sky.Name = "__SeigeSky"
        sky.SkyboxUp = skyboxFaces.Up
        sky.SkyboxDn = skyboxFaces.Dn
        sky.SkyboxLf = skyboxFaces.Lf
        sky.SkyboxRt = skyboxFaces.Rt
        sky.SkyboxFt = skyboxFaces.Ft
        sky.SkyboxBk = skyboxFaces.Bk
        sky.Parent = Lighting
    end
    resetSkybox = function()
        for _, c in ipairs(Lighting:GetChildren()) do
            if c:IsA("Sky") then c:Destroy() end
        end
    end

    button(pgConfig, "Apply Skybox", function()
        applySkybox(); notify("Skybox applied", "ok")
    end)
    button(pgConfig, "Reset Skybox", function()
        resetSkybox(); notify("Skybox reset", "ok")
    end)
end

------------------------------------------------------- PARTICLE EFFECTS
section(pgConfig, "Particle Effects")
label(pgConfig, "Animated sparkles & nebulae layered over each tab")
local FX_TABS = { "Profile", "Players", "Cmds", "Shaders", "Spotify", "Misc" }
local fxCtls = {}
for _, k in ipairs(FX_TABS) do
    fxCtls[k] = toggle(pgConfig, k .. " particles", _G.__SeigeFx[k] == true, function(v)
        _G.__SeigeFx[k] = v
    end)
end

------------------------------------------------------- SAVE / RESET CONFIG (impl)


snapshotCfg = function()
    local fx = {}
    for _, k in ipairs(FX_TABS) do fx[k] = _G.__SeigeFx[k] == true end
    -- Snapshot theme color overrides
    local theme = {}
    pcall(function()
        for k, v in pairs(T) do
            if typeof(v) == "Color3" then
                theme[k] = string.format("#%02X%02X%02X",
                    math.floor(v.R*255+0.5), math.floor(v.G*255+0.5), math.floor(v.B*255+0.5))
            end
        end
    end)
    local bgSnap = { image = "", trans = 0.4 }
    pcall(function() bgSnap.image = bgState.image or ""; bgSnap.trans = bgState.trans or 0.4 end)
    local pbgSnap = { image = "", trans = 0.5, panels = {}, icons = {} }
    pcall(function()
        pbgSnap.image  = panelBgState.image  or ""
        pbgSnap.trans  = panelBgState.trans  or 0.5
        pbgSnap.panels = panelBgState.panels or {}
        pbgSnap.icons  = panelBgState.icons  or {}
    end)
    return {
        toggleKey     = toggleKey.Name,
        uiScale       = uiScaleCtl and uiScaleCtl.get and uiScaleCtl.get() or 1,
        reducedMotion = reducedCtl and reducedCtl.get and reducedCtl.get() or false,
        layoutMode    = _G.__SeigeLayoutMode or "Bar",
        uiTrans       = _G.__SeigeUITrans or 0.35,
        skybox        = {
            Up = skyboxFaces.Up, Dn = skyboxFaces.Dn,
            Lf = skyboxFaces.Lf, Rt = skyboxFaces.Rt,
            Ft = skyboxFaces.Ft, Bk = skyboxFaces.Bk,
        },
        fx            = fx,
        -- Theme / appearance extensions
        theme         = theme,
        bg            = bgSnap,
        panelBg       = pbgSnap,
        fontOverride  = _G.__SeigeFontOverride or "Default (mixed)",
        fontScale     = tonumber(_G.__SeigeFontScale) or 1.0,
        tagFont       = nil,
        bubbleAnim    = _G.__SeigeBubbleAnim or "None",
        bubbleAmt     = tonumber(_G.__SeigeBubbleAmt) or 0.5,
        pageAnim      = _G.__SeigePageAnim or "Fade",
        pageAnimSpeed = tonumber(_G.__SeigePageAnimSpeed) or 0.24,
    }
end

applyCfg = function(cfg, opts)
    cfg = cfg or {}
    opts = opts or {}
    setToggleKey(cfg.toggleKey or CFG_DEFAULTS.toggleKey)
    if uiScaleCtl and uiScaleCtl.set then uiScaleCtl.set(cfg.uiScale or CFG_DEFAULTS.uiScale) end
    if reducedCtl and reducedCtl.set then reducedCtl.set(cfg.reducedMotion == true) end
    if cfg.layoutMode and _G.__SeigeApplyLayout then
        _G.__SeigeApplyLayout(cfg.layoutMode)
        if layoutCtl and layoutCtl.set then layoutCtl.set(cfg.layoutMode) end
    end
    if cfg.uiTrans and _G.__SeigeApplyUITrans then
        _G.__SeigeApplyUITrans(tonumber(cfg.uiTrans) or 0.35)
        if transCtl and transCtl.set then transCtl.set(tonumber(cfg.uiTrans) or 0.35) end
    end
    local sb = cfg.skybox or CFG_DEFAULTS.skybox
    for _, k in ipairs({ "Up", "Dn", "Lf", "Rt", "Ft", "Bk" }) do
        skyboxFaces[k] = sb[k] or ""
        if skyboxBoxes[k] then skyboxBoxes[k].Text = "" end
    end
    local fx = cfg.fx or CFG_DEFAULTS.fx
    for _, k in ipairs(FX_TABS) do
        local v = fx[k] == true
        _G.__SeigeFx[k] = v
        if fxCtls[k] and fxCtls[k].set then fxCtls[k].set(v) end
    end
    if opts.applySkybox then
        if (sb.Up or "") ~= "" or (sb.Dn or "") ~= "" then applySkybox() else resetSkybox() end
    end
    -- Theme / appearance extensions
    if type(cfg.theme) == "table" and _G.__SeigeApplyThemeHex then
        pcall(_G.__SeigeApplyThemeHex, cfg.theme)
    elseif type(cfg.theme) == "table" then
        -- Fallback: use the themes' loadCfg path by writing temp state.
        pcall(function()
            local newT = {}
            for k, hex in pairs(cfg.theme) do
                local h = tostring(hex):gsub("^#","")
                if #h == 6 then
                    local r = tonumber(h:sub(1,2),16) or 0
                    local g = tonumber(h:sub(3,4),16) or 0
                    local b = tonumber(h:sub(5,6),16) or 0
                    newT[k] = Color3.fromRGB(r,g,b)
                end
            end
            if _G.__SeigeApplyTheme then _G.__SeigeApplyTheme(newT) end
        end)
    end
    if type(cfg.bg) == "table" then
        pcall(function()
            bgState.image = cfg.bg.image or ""
            bgState.trans = tonumber(cfg.bg.trans) or 0.4
            if _G.__SeigeApplyBg then _G.__SeigeApplyBg() end
        end)
    end
    if type(cfg.panelBg) == "table" then
        pcall(function()
            panelBgState.image  = cfg.panelBg.image  or ""
            panelBgState.trans  = tonumber(cfg.panelBg.trans) or 0.5
            panelBgState.panels = (type(cfg.panelBg.panels) == "table") and cfg.panelBg.panels or {}
            panelBgState.icons  = (type(cfg.panelBg.icons)  == "table") and cfg.panelBg.icons  or {}
            if _G.__SeigeApplyPanelBg    then _G.__SeigeApplyPanelBg()    end
            if _G.__SeigeApplyIconImages then _G.__SeigeApplyIconImages() end
        end)
    end
    if cfg.fontOverride or cfg.fontScale then
        _G.__SeigeFontOverride = cfg.fontOverride or _G.__SeigeFontOverride
        _G.__SeigeFontScale    = tonumber(cfg.fontScale) or _G.__SeigeFontScale or 1.0
        if _G.__SeigeApplyTypography then pcall(_G.__SeigeApplyTypography) end
    end
    -- (Global tag font setting removed.)
    if cfg.bubbleAnim then
        _G.__SeigeBubbleAnim = cfg.bubbleAnim
        if _G.__SeigeBubbleAnimCtl and _G.__SeigeBubbleAnimCtl.set then pcall(_G.__SeigeBubbleAnimCtl.set, cfg.bubbleAnim) end
    end
    if cfg.bubbleAmt then
        _G.__SeigeBubbleAmt = tonumber(cfg.bubbleAmt) or _G.__SeigeBubbleAmt
        if _G.__SeigeBubbleAmtCtl and _G.__SeigeBubbleAmtCtl.set then pcall(_G.__SeigeBubbleAmtCtl.set, (_G.__SeigeBubbleAmt or 0.5) * 100) end
    end
    if cfg.pageAnim then
        _G.__SeigePageAnim = cfg.pageAnim
        if _G.__SeigePageAnimCtl and _G.__SeigePageAnimCtl.set then pcall(_G.__SeigePageAnimCtl.set, cfg.pageAnim) end
    end
    if cfg.pageAnimSpeed then
        _G.__SeigePageAnimSpeed = tonumber(cfg.pageAnimSpeed) or _G.__SeigePageAnimSpeed
        if _G.__SeigePageAnimSpeedCtl and _G.__SeigePageAnimSpeedCtl.set then pcall(_G.__SeigePageAnimSpeedCtl.set, (_G.__SeigePageAnimSpeed or 0.24) * 1000) end
    end
end


saveCfg = function()
    -- Always snapshot to an in-memory session store so settings persist
    -- across panel reopens / scripts that re-require us, even without a
    -- writefile-capable executor. Resets only when the user clicks
    -- "Reset to Defaults" or the player rejoins.
    local snap = snapshotCfg()
    _G.__SeigeSessionCfg = snap

    -- Also forward to the legacy themes config file so the existing themes
    -- loader picks up colors / background / panel images on next inject.
    if _G.__AdminSaveCfg then pcall(_G.__AdminSaveCfg) end

    local wf = rawget(getfenv(), "writefile") or writefile
    if not wf then
        notify("Config saved for this session", "good")
        return
    end
    local mf = rawget(getfenv(), "makefolder") or makefolder
    if mf then pcall(mf, "SeigeAdmin") end
    local ok, raw = pcall(HttpService.JSONEncode, HttpService, snap)
    if not ok then notify("Failed to encode config", "bad") return end
    local okW = pcall(wf, CFG_FILE, raw)
    if okW then notify("Config saved", "good") else notify("Config saved for this session", "good") end
end


loadCfg = function()
    -- Prefer in-memory session config (set by saveCfg this session) so the
    -- last-saved settings stick across re-injects in the same session even
    -- without writefile support.
    if type(_G.__SeigeSessionCfg) == "table" then
        applyCfg(_G.__SeigeSessionCfg, { applySkybox = true })
        return
    end
    local rf  = rawget(getfenv(), "readfile") or readfile
    local isf = rawget(getfenv(), "isfile")   or isfile
    if not rf or not isf then return end
    local ok, exists = pcall(isf, CFG_FILE); if not (ok and exists) then return end
    local okR, raw = pcall(rf, CFG_FILE); if not (okR and raw) then return end
    local okD, data = pcall(HttpService.JSONDecode, HttpService, raw)
    if okD and type(data) == "table" then applyCfg(data, { applySkybox = true }) end
end

-- auto-load saved config on startup
pcall(loadCfg)
end)() -- end scoped Settings/Cfg function





section(pgConfig, "About")
label(pgConfig, "seige.lol admin")
label(pgConfig, "Build " .. ADMIN_BUILD)
button(pgConfig, "Unload", function()
    if _G.__AdminCleanup then _G.__AdminCleanup() end
end)

------------------------------------------------------- FLY KEY HANDLERS
bind(UIS.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.W then flyKeys.fwd = true end
    if i.KeyCode == Enum.KeyCode.S then flyKeys.back = true end
    if i.KeyCode == Enum.KeyCode.A then flyKeys.left = true end
    if i.KeyCode == Enum.KeyCode.D then flyKeys.right = true end
    if i.KeyCode == Enum.KeyCode.E then flyKeys.up = true end
    if i.KeyCode == Enum.KeyCode.Q then flyKeys.down = true end
end))
bind(UIS.InputEnded:Connect(function(i)
    if i.KeyCode == Enum.KeyCode.W then flyKeys.fwd = false end
    if i.KeyCode == Enum.KeyCode.S then flyKeys.back = false end
    if i.KeyCode == Enum.KeyCode.A then flyKeys.left = false end
    if i.KeyCode == Enum.KeyCode.D then flyKeys.right = false end
    if i.KeyCode == Enum.KeyCode.E then flyKeys.up = false end
    if i.KeyCode == Enum.KeyCode.Q then flyKeys.down = false end
end))

-- Invis toggle keybind (default F7)
bind(UIS.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.UserInputType == Enum.UserInputType.Keyboard and i.KeyCode == (_G.__InvisKey or Enum.KeyCode.F7) then
        cmdHandlers["invis"]()
    end
end))

------------------------------------------------------- PROFILE TAB (redesigned)
;(function()
    -- ============ HERO CARD: big centered avatar, name, @user ============
    local hero = inst("Frame", pgProfile, {
        Size = UDim2.new(1, -8, 0, 174),
        BackgroundColor3 = T.bg2, BackgroundTransparency = 0.15, BorderSizePixel = 0,
    })
    corner(hero, 16); stroke(hero, T.line, 1, 0.5)
    inst("UIGradient", hero, {
        Rotation = 90,
        Color = ColorSequence.new(Color3.fromRGB(28, 30, 44), Color3.fromRGB(16, 18, 26)),
    })

    -- ============ HERO PARTICLE FX LAYER ============
    local heroFx = inst("Frame", hero, {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
        ClipsDescendants = true, ZIndex = 2,
    })
    corner(heroFx, 16)
    local NEBULA_COLORS = {
        Color3.fromRGB(120, 90, 220),
        Color3.fromRGB(80, 140, 230),
        Color3.fromRGB(220, 110, 180),
        Color3.fromRGB(90, 200, 220),
    }
    local function heroSparkle()
        local col = ({
            Color3.fromRGB(255, 240, 180),
            Color3.fromRGB(180, 210, 255),
            Color3.fromRGB(220, 170, 255),
            Color3.fromRGB(170, 255, 220),
        })[math.random(1, 4)]
        local f = inst("Frame", heroFx, {
            Size = UDim2.new(0, 2, 0, 2),
            Position = UDim2.new(math.random(), 0, math.random(), 0),
            BackgroundColor3 = col, BorderSizePixel = 0, ZIndex = 3,
        })
        corner(f, 1)
        TweenService:Create(f, TweenInfo.new(0.9, Enum.EasingStyle.Quad),
            { Size = UDim2.new(0, 7, 0, 7), BackgroundTransparency = 1 }):Play()
        task.delay(1, function() if f then f:Destroy() end end)
    end
    local function heroNebula()
        local sz = math.random(28, 56)
        local f = inst("Frame", heroFx, {
            Size = UDim2.new(0, sz, 0, sz),
            Position = UDim2.new(math.random() * 1.1 - 0.05, 0, math.random() * 1.2 - 0.1, 0),
            BackgroundColor3 = NEBULA_COLORS[math.random(#NEBULA_COLORS)],
            BackgroundTransparency = 0.82, BorderSizePixel = 0, ZIndex = 2,
        })
        corner(f, math.floor(sz / 2))
        local tx = f.Position.X.Scale + (math.random() - 0.5) * 0.4
        local ty = f.Position.Y.Scale + (math.random() - 0.5) * 0.3
        TweenService:Create(f, TweenInfo.new(3, Enum.EasingStyle.Sine),
            { Position = UDim2.new(tx, 0, ty, 0), BackgroundTransparency = 1,
              Size = UDim2.new(0, sz + 18, 0, sz + 18) }):Play()
        task.delay(3.1, function() if f then f:Destroy() end end)
    end
    _G.__SeigeFx = _G.__SeigeFx or { Profile = true, Players = false, Cmds = false, Shaders = false, Spotify = false, Misc = false }
    task.spawn(function()
        while hero and hero.Parent do
            if _G.__SeigeFx.Profile then
                pcall(function()
                    if math.random() < 0.55 then heroSparkle() end
                    if math.random() < 0.10 then heroNebula() end
                end)
            end
            task.wait(0.12)
        end
    end)


    -- subtle glow ring behind avatar
    local ring = inst("Frame", hero, {
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 14),
        Size = UDim2.new(0, 86, 0, 86),
        BackgroundColor3 = T.acc, BackgroundTransparency = 0.55, BorderSizePixel = 0,
    })
    corner(ring, 999)

    local avWrap = inst("Frame", hero, {
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 18),
        Size = UDim2.new(0, 78, 0, 78),
        BackgroundColor3 = T.bg3, BorderSizePixel = 0,
    })
    corner(avWrap, 999); stroke(avWrap, T.text, 2, 0.7)
    local av = inst("ImageLabel", avWrap, {
        Size = UDim2.new(1, -4, 1, -4), Position = UDim2.new(0, 2, 0, 2),
        BackgroundTransparency = 1, BackgroundColor3 = T.bg,
    })
    corner(av, 999)
    pcall(function()
        av.Image = Players:GetUserThumbnailAsync(LP.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
    end)

    -- live status dot bottom-right of avatar
    local meDot = inst("Frame", hero, {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 28, 0, 86),
        Size = UDim2.new(0, 14, 0, 14),
        BackgroundColor3 = T.good, BorderSizePixel = 0,
    })
    corner(meDot, 999); stroke(meDot, T.bg, 2, 0)

    inst("TextLabel", hero, {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 104),
        Size = UDim2.new(1, 0, 0, 22),
        Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = T.text,
        Text = string.upper(tostring(LP.DisplayName or LP.Name)),
    })
    inst("TextLabel", hero, {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 126),
        Size = UDim2.new(1, 0, 0, 14),
        Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = T.sub,
        Text = "@" .. LP.Name,
    })

    -- stats chip row
    local chips = inst("Frame", hero, {
        Position = UDim2.new(0, 12, 0, 144),
        Size = UDim2.new(1, -24, 0, 24),
        BackgroundTransparency = 1,
    })
    inst("UIListLayout", chips, {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder,
    })
    local function chip(label, value, color)
        local c = inst("Frame", chips, {
            Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X,
            BackgroundColor3 = T.bg3, BackgroundTransparency = 0.2, BorderSizePixel = 0,
        })
        corner(c, 10); stroke(c, T.line, 1, 0.5)
        inst("UIPadding", c, { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) })
        local h = inst("Frame", c, { Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1 })
        inst("UIListLayout", h, { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 5) })
        inst("TextLabel", h, {
            BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 1, 0),
            Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = color or T.acc, Text = tostring(value),
        })
        inst("TextLabel", h, {
            BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 1, 0),
            Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = T.sub, Text = label,
        })
        return c
    end

    local friendsCountChip
    friendsCountChip = chip("friends", "—", T.acc)
    chip("days old", tostring(LP.AccountAge), T.good)
    chip("id", tostring(LP.UserId), T.warn)

    -- ============ FRIENDS / JOINABLE ============
    local jSec = section(pgProfile, "Joinable now")
    local joinList = inst("Frame", pgProfile, {
        Size = UDim2.new(1, -8, 0, 0), BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y,
    })
    inst("UIListLayout", joinList, { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder })
    local joinEmpty = inst("TextLabel", pgProfile, {
        Size = UDim2.new(1, -8, 0, 32), BackgroundColor3 = T.bg3, BackgroundTransparency = 0.5, BorderSizePixel = 0,
        Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = T.dim, Text = "  Scanning friend presences…",
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    corner(joinEmpty, 8); stroke(joinEmpty, T.line, 1, 0.5)

    section(pgProfile, "All friends")
    local friendsList = inst("Frame", pgProfile, {
        Size = UDim2.new(1, -8, 0, 0), BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y,
    })
    inst("UIListLayout", friendsList, { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder })
    local friendsStatus = inst("TextLabel", pgProfile, {
        Size = UDim2.new(1, -8, 0, 16), BackgroundTransparency = 1,
        Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = T.dim,
        TextXAlignment = Enum.TextXAlignment.Left, Text = "Loading…",
    })

    local function clearChildren(p)
        for _, c in ipairs(p:GetChildren()) do
            if not c:IsA("UIListLayout") then c:Destroy() end
        end
    end

    local function addBucketLabel(text)
        inst("TextLabel", friendsList, {
            Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = T.dim,
            TextXAlignment = Enum.TextXAlignment.Left, Text = string.upper(text),
        })
    end

    -- small hover animation helper
    local function hoverable(frame)
        frame.MouseEnter:Connect(function()
            tween(frame, 0.15, { BackgroundTransparency = 0.15 })
            local s = frame:FindFirstChildOfClass("UIStroke")
            if s then tween(s, 0.15, { Transparency = 0.1 }) end
        end)
        frame.MouseLeave:Connect(function()
            tween(frame, 0.2, { BackgroundTransparency = 0.4 })
            local s = frame:FindFirstChildOfClass("UIStroke")
            if s then tween(s, 0.2, { Transparency = 0.5 }) end
        end)
    end

    local function addJoinableCard(f)
        local r = inst("Frame", joinList, {
            Size = UDim2.new(1, 0, 0, 56),
            BackgroundColor3 = T.bg3, BackgroundTransparency = 0.3, BorderSizePixel = 0,
        })
        corner(r, 10); stroke(r, T.good, 1, 0.4)
        inst("UIGradient", r, {
            Rotation = 0,
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 60, 50)),
                ColorSequenceKeypoint.new(1, T.bg3),
            }),
            Transparency = NumberSequence.new(0.2, 1),
        })

        local img = inst("ImageLabel", r, {
            Position = UDim2.new(0, 8, 0.5, -20), Size = UDim2.new(0, 40, 0, 40),
            BackgroundColor3 = T.bg, BorderSizePixel = 0,
        })
        corner(img, 999); stroke(img, T.good, 1.5, 0.2)
        pcall(function() img.Image = Players:GetUserThumbnailAsync(f.userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100) end)

        local dot = inst("Frame", r, {
            Position = UDim2.new(0, 38, 0.5, 8), Size = UDim2.new(0, 10, 0, 10),
            BackgroundColor3 = T.good, BorderSizePixel = 0,
        })
        corner(dot, 999); stroke(dot, T.bg, 2, 0)
        -- gentle pulse
        task.spawn(function()
            while dot.Parent do
                tween(dot, 0.8, { BackgroundTransparency = 0.6 })
                task.wait(0.85)
                if not dot.Parent then break end
                tween(dot, 0.8, { BackgroundTransparency = 0 })
                task.wait(0.85)
            end
        end)

        inst("TextLabel", r, {
            BackgroundTransparency = 1, Position = UDim2.new(0, 58, 0, 6), Size = UDim2.new(1, -160, 0, 16),
            Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = T.text,
            TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
            Text = tostring(f.displayName or f.username or "user"),
        })
        inst("TextLabel", r, {
            BackgroundTransparency = 1, Position = UDim2.new(0, 58, 0, 22), Size = UDim2.new(1, -160, 0, 14),
            Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = T.sub,
            TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
            Text = "@" .. tostring(f.username or ""),
        })
        inst("TextLabel", r, {
            BackgroundTransparency = 1, Position = UDim2.new(0, 58, 0, 36), Size = UDim2.new(1, -160, 0, 14),
            Font = Enum.Font.GothamMedium, TextSize = 10, TextColor3 = T.good,
            TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
            Text = "● " .. tostring(f._loc or "In an experience"),
        })

        local joinBtn = inst("TextButton", r, {
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.new(0, 88, 0, 32),
            BackgroundColor3 = T.good, BackgroundTransparency = 0.1, BorderSizePixel = 0, AutoButtonColor = false,
            Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = T.bg, Text = "▶ Join",
        })
        corner(joinBtn, 8); stroke(joinBtn, T.good, 1, 0.2)
        joinBtn.MouseEnter:Connect(function() tween(joinBtn, 0.12, { BackgroundTransparency = 0, Size = UDim2.new(0, 94, 0, 34) }) end)
        joinBtn.MouseLeave:Connect(function() tween(joinBtn, 0.15, { BackgroundTransparency = 0.1, Size = UDim2.new(0, 88, 0, 32) }) end)
        joinBtn.MouseButton1Click:Connect(function()
            joinBtn.Text = "Joining…"
            local placeId = tonumber(f._placeId) or tonumber(f._rootPlaceId)
            local jobId   = f._jobId
            if not placeId then notify("No joinable place", "warn"); joinBtn.Text = "▶ Join"; return end
            local ok = pcall(function()
                if jobId and jobId ~= "" then
                    TeleportSrv:TeleportToPlaceInstance(placeId, jobId, LP)
                else
                    TeleportSrv:Teleport(placeId, LP)
                end
            end)
            if not ok then notify("Teleport failed (server may be private)", "bad"); joinBtn.Text = "▶ Join" end
        end)

        hoverable(r)
    end

    local function addFriendRow(f, statusText, statusColor)
        local r = inst("Frame", friendsList, {
            Size = UDim2.new(1, 0, 0, 42),
            BackgroundColor3 = T.bg3, BackgroundTransparency = 0.4, BorderSizePixel = 0,
        })
        corner(r, 8); stroke(r, T.line, 1, 0.5)
        local img = inst("ImageLabel", r, {
            Position = UDim2.new(0, 6, 0, 5), Size = UDim2.new(0, 32, 0, 32),
            BackgroundColor3 = T.bg, BorderSizePixel = 0,
        })
        corner(img, 999)
        pcall(function() img.Image = Players:GetUserThumbnailAsync(f.userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100) end)
        local sdot = inst("Frame", r, {
            Position = UDim2.new(0, 32, 0, 28), Size = UDim2.new(0, 8, 0, 8),
            BackgroundColor3 = statusColor or T.dim, BorderSizePixel = 0,
        })
        corner(sdot, 999); stroke(sdot, T.bg, 1.5, 0)
        inst("TextLabel", r, {
            BackgroundTransparency = 1, Position = UDim2.new(0, 46, 0, 4), Size = UDim2.new(1, -186, 0, 16),
            Font = Enum.Font.GothamSemibold, TextSize = 12, TextColor3 = T.text,
            TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
            Text = tostring(f.displayName or f.username or "user"),
        })
        inst("TextLabel", r, {
            BackgroundTransparency = 1, Position = UDim2.new(0, 46, 0, 20), Size = UDim2.new(1, -186, 0, 14),
            Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = T.sub,
            TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
            Text = "@" .. tostring(f.username or ""),
        })
        inst("TextLabel", r, {
            BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.new(0, 134, 0, 18),
            Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = statusColor or T.dim,
            TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd,
            Text = statusText or "Offline",
        })
        hoverable(r)
    end

    local function postJson(url, body)
        local ok, res = pcall(function()
            return HttpService:JSONDecode(game:HttpPost(url, body, false, "application/json"))
        end)
        if ok and res then return res end
        local req = (syn and syn.request) or (http and http.request) or rawget(getfenv(), "request") or rawget(getfenv(), "http_request")
        if req then
            local ok2, r = pcall(req, { Url = url, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = body })
            if ok2 and r and r.Body then
                local okj, decoded = pcall(function() return HttpService:JSONDecode(r.Body) end)
                if okj then return decoded end
            end
        end
        return nil
    end

    local refreshing = false
    local function refreshFriends()
        if refreshing then return end
        refreshing = true
        friendsStatus.Text = "Refreshing…"
        task.spawn(function()
            local ok, pages = pcall(function() return Players:GetFriendsAsync(LP.UserId) end)
            if not ok or not pages then
                friendsStatus.Text = "Failed to load friends."; refreshing = false; return
            end
            local all, guard = {}, 0
            while true do
                local okp, cur = pcall(function() return pages:GetCurrentPage() end)
                if okp and cur then
                    for _, f in ipairs(cur) do
                        table.insert(all, { userId = f.Id, username = f.Username, displayName = f.DisplayName })
                    end
                end
                if pages.IsFinished then break end
                local oka = pcall(function() pages:AdvanceToNextPageAsync() end)
                if not oka then break end
                guard = guard + 1; if guard > 5 then break end
            end

            friendsCountChip:FindFirstChildOfClass("Frame"):FindFirstChildOfClass("TextLabel").Text = tostring(#all)

            if #all == 0 then
                clearChildren(joinList); clearChildren(friendsList)
                joinEmpty.Text = "  No friends found."; joinEmpty.Visible = true
                friendsStatus.Text = ""; refreshing = false; return
            end

            local ids = {}
            for _, x in ipairs(all) do table.insert(ids, x.userId) end
            local presence = {}
            local pres = postJson("https://presence.roblox.com/v1/presence/users", HttpService:JSONEncode({ userIds = ids }))
            if pres and pres.userPresences then
                for _, p in ipairs(pres.userPresences) do presence[p.userId] = p end
            end

            local hereIds = {}
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LP then
                    local okFr = pcall(function() return LP:IsFriendsWith(p.UserId) end)
                    if okFr and LP:IsFriendsWith(p.UserId) then hereIds[p.UserId] = true end
                end
            end

            local joinable, here, sameGame, otherGame, online, offline = {}, {}, {}, {}, {}, {}
            for _, f in ipairs(all) do
                local p = presence[f.userId]
                if hereIds[f.userId] then
                    table.insert(here, f)
                elseif p then
                    if p.userPresenceType == 2 then
                        f._loc = p.lastLocation
                        f._placeId = p.placeId
                        f._rootPlaceId = p.rootPlaceId
                        f._jobId = p.gameId
                        if tonumber(p.rootPlaceId) == tonumber(game.PlaceId) then
                            table.insert(sameGame, f)
                        else
                            table.insert(otherGame, f)
                        end
                        if p.gameId and p.gameId ~= "" and (p.placeId or p.rootPlaceId) then
                            table.insert(joinable, f)
                        end
                    elseif p.userPresenceType == 1 then
                        table.insert(online, f)
                    else
                        table.insert(offline, f)
                    end
                else
                    table.insert(offline, f)
                end
            end

            -- Joinable section (animated cards)
            clearChildren(joinList)
            if #joinable == 0 then
                joinEmpty.Text = "  No joinable friends right now."
                joinEmpty.Visible = true
            else
                joinEmpty.Visible = false
                for _, f in ipairs(joinable) do addJoinableCard(f) end
            end

            -- All friends buckets
            clearChildren(friendsList)
            local function addBucket(lbl, list, color)
                if #list == 0 then return end
                addBucketLabel(lbl .. "  (" .. #list .. ")")
                for _, f in ipairs(list) do
                    local txt = lbl
                    if f._loc and lbl == "In another game" then txt = tostring(f._loc) end
                    addFriendRow(f, txt, color)
                end
            end
            addBucket("In this server",  here,      T.good)
            addBucket("In this game",    sameGame,  Color3.fromRGB(160, 220, 255))
            addBucket("In another game", otherGame, Color3.fromRGB(255, 200, 120))
            addBucket("Online",          online,    Color3.fromRGB(180, 180, 255))
            addBucket("Offline",         offline,   T.dim)

            friendsStatus.Text = ("Updated %s · %d friends · %d joinable"):format(os.date("%I:%M:%S %p"), #all, #joinable)
            refreshing = false
        end)
    end

    button(pgProfile, "Refresh now", function() refreshFriends() end)

    section(pgProfile, "Tag")
    button(pgProfile, "Refresh tag", function()
        if tagBills[LP] then
            pcall(NameHider.restore, LP); pcall(function() tagBills[LP].gui:Destroy() end)
            tagBills[LP] = nil
        end
        pcall(buildBill, LP)
        notify("Your tag has been refreshed", "good")
    end)

    -- initial load + real-time auto-refresh every 30s
    task.spawn(function() task.wait(0.5); refreshFriends() end)
    task.spawn(function()
        while pgProfile and pgProfile.Parent do
            task.wait(30)
            refreshFriends()
        end
    end)
end)()


------------------------------------------------------- REDESIGN: TOP PILL + FLOATING PANELS
-- Replaces the legacy single-window layout. A slim top-center status pill
-- shows FPS/PING/brand + an icon button per tab. Clicking an icon toggles a
-- draggable floating popout for that tab (with an X to close). Multiple
-- popouts can be open at once. F2 hides everything.

Win.Visible = false   -- retire the legacy chrome (kept around for compat)

-- Global UI translucency level used by the new chrome (Pill + floating panels).
-- 0 = fully opaque, 1 = fully transparent. Adjustable from Config tab.
_G.__SeigeUITrans = _G.__SeigeUITrans or 0.35
_G.__SeigeLayoutMode = _G.__SeigeLayoutMode or "Bar"  -- "Bar" or "Hamburger"

-- ============= TOP PILL ===========================================

;(function()
Pill = inst("Frame", Root, {
    Name = "TopPill",
    AnchorPoint = Vector2.new(0.5, 0),
    Position = UDim2.new(0.5, 0, 0, 14),
    Size = UDim2.new(0, 0, 0, 44),
    AutomaticSize = Enum.AutomaticSize.X,
    BackgroundColor3 = T.bg,
    BackgroundTransparency = math.max(0.05, (_G.__SeigeUITrans or 0.35) - 0.1),
    BorderSizePixel = 0,
    Active = true,
    ZIndex = 100,
})
corner(Pill, 14); stroke(Pill, T.text, 1, 0.78)
inst("UIPadding", Pill, {
    PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8),
    PaddingTop = UDim.new(0, 5),  PaddingBottom = UDim.new(0, 5),
})
inst("UIListLayout", Pill, {
    FillDirection = Enum.FillDirection.Horizontal,
    VerticalAlignment = Enum.VerticalAlignment.Center,
    Padding = UDim.new(0, 6),
    SortOrder = Enum.SortOrder.LayoutOrder,
})

-- helper: thin vertical divider between sections of the bar
local function pillDivider(order)
    local d = inst("Frame", Pill, {
        Size = UDim2.new(0, 1, 1, -10), BackgroundColor3 = T.text,
        BackgroundTransparency = 0.82, BorderSizePixel = 0,
        LayoutOrder = order, ZIndex = 101,
    })
    return d
end

-- Brand pill (name + @user) — FIRST
brandBlock = inst("Frame", Pill, {
    Size = UDim2.new(0, 86, 1, -4), BackgroundTransparency = 1, LayoutOrder = 1, ZIndex = 101,
})
inst("UIPadding", brandBlock, { PaddingLeft = UDim.new(0,6), PaddingRight = UDim.new(0,6) })
inst("TextLabel", brandBlock, {
    BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 4),
    Size = UDim2.new(1, 0, 0, 14),
    Font = Enum.Font.GothamBlack, TextSize = 12, TextColor3 = T.text,
    TextXAlignment = Enum.TextXAlignment.Left, Text = "SEIGE.LOL", ZIndex = 101,
})
inst("TextLabel", brandBlock, {
    BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 20),
    Size = UDim2.new(1, 0, 0, 12),
    Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = T.good,
    TextXAlignment = Enum.TextXAlignment.Left, Text = "@" .. LP.Name, ZIndex = 101,
})

pillDivider(2)

-- FPS / PING stat pills
local function statPill(order, color)
    local f = inst("Frame", Pill, {
        Size = UDim2.new(0, 80, 0, 26), BackgroundColor3 = color,
        BackgroundTransparency = 0.86, BorderSizePixel = 0,
        LayoutOrder = order, ZIndex = 101,
    })
    corner(f, 13); stroke(f, color, 1, 0.55)
    return f
end
fpsBox = statPill(3, T.good)
local fpsDot = inst("Frame", fpsBox, {
    AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 8, 0.5, 0),
    Size = UDim2.new(0, 6, 0, 6), BackgroundColor3 = T.good, BorderSizePixel = 0, ZIndex = 102,
})
corner(fpsDot, 3)
inst("TextLabel", fpsBox, {
    Position = UDim2.new(0, 18, 0, 0), Size = UDim2.new(0, 28, 1, 0),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamSemibold, TextSize = 11, TextColor3 = T.text,
    TextXAlignment = Enum.TextXAlignment.Left, Text = "FPS", ZIndex = 102,
})
local fpsLbl = inst("TextLabel", fpsBox, {
    Position = UDim2.new(0, 44, 0, 0), Size = UDim2.new(1, -50, 1, 0),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = T.good,
    TextXAlignment = Enum.TextXAlignment.Left, Text = "--", ZIndex = 102,
})

pingBox = statPill(4, T.warn)
local pingDot = inst("Frame", pingBox, {
    AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 8, 0.5, 0),
    Size = UDim2.new(0, 6, 0, 6), BackgroundColor3 = T.warn, BorderSizePixel = 0, ZIndex = 102,
})
corner(pingDot, 3)
inst("TextLabel", pingBox, {
    Position = UDim2.new(0, 18, 0, 0), Size = UDim2.new(0, 30, 1, 0),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamSemibold, TextSize = 11, TextColor3 = T.text,
    TextXAlignment = Enum.TextXAlignment.Left, Text = "PING", ZIndex = 102,
})
local pingLbl = inst("TextLabel", pingBox, {
    Position = UDim2.new(0, 46, 0, 0), Size = UDim2.new(1, -52, 1, 0),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = T.warn,
    TextXAlignment = Enum.TextXAlignment.Left, Text = "--", ZIndex = 102,
})

pillDivider(5)

-- Icon button row
iconsRow = inst("Frame", Pill, {
    Size = UDim2.new(0, 0, 1, -4),
    AutomaticSize = Enum.AutomaticSize.X,
    BackgroundTransparency = 1, LayoutOrder = 6, ZIndex = 101,
})
inst("UIListLayout", iconsRow, {
    FillDirection = Enum.FillDirection.Horizontal,
    VerticalAlignment = Enum.VerticalAlignment.Center,
    Padding = UDim.new(0, 6),
    SortOrder = Enum.SortOrder.LayoutOrder,
})

pillDivider(95)

-- Hide/show toggle (compacts the bar to a hamburger) — before clock
pillToggle = inst("TextButton", Pill, {
    Size = UDim2.new(0, 32, 0, 32), BackgroundColor3 = T.text,
    BackgroundTransparency = 0.88, BorderSizePixel = 0, AutoButtonColor = false,
    Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = T.text,
    Text = "", LayoutOrder = 96, ZIndex = 102,
})
corner(pillToggle, 8); stroke(pillToggle, T.text, 1, 0.65)
pillToggleImg = inst("ImageLabel", pillToggle, {
    BackgroundTransparency = 1,
    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = UDim2.new(0, 18, 0, 18),
    Image = "rbxassetid://106620609396373",
    ImageColor3 = T.text, ZIndex = 103,
})

-- Clock pill at far right (time + date)
clockBox = inst("Frame", Pill, {
    Size = UDim2.new(0, 82, 1, -4), BackgroundTransparency = 1,
    LayoutOrder = 99, ZIndex = 101,
})
inst("UIPadding", clockBox, { PaddingLeft = UDim.new(0,6), PaddingRight = UDim.new(0,6) })
local pillClock = inst("TextLabel", clockBox, {
    Position = UDim2.new(0, 0, 0, 3), Size = UDim2.new(1, 0, 0, 14),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = T.text,
    TextXAlignment = Enum.TextXAlignment.Right,
    Text = (os.date("%I:%M %p"):gsub("^0", "")), ZIndex = 101,
})
local pillDate = inst("TextLabel", clockBox, {
    Position = UDim2.new(0, 0, 0, 19), Size = UDim2.new(1, 0, 0, 12),
    BackgroundTransparency = 1,
    Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = T.sub,
    TextXAlignment = Enum.TextXAlignment.Right,
    Text = os.date("%a %b %d"), ZIndex = 101,
})

-- Pill drag
do
    local dragging, ds, sp
    Pill.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true; ds = i.Position; sp = Pill.Position
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - ds
            Pill.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
end

-- Live status: FPS / PING / clock
-- FPS is averaged over a rolling ~0.5s window driven by RenderStepped (which
-- matches the player's actual render rate). A single-frame 1/dt reading is too
-- jittery and "glitches" the number — averaging produces the value Roblox itself
-- shows in its dev console.
task.spawn(function()
    local Stats = game:GetService("Stats")
    local frames = 0
    local windowStart = tick()
    local lastFps = 0
    local rsConn = RunService.RenderStepped:Connect(function() frames = frames + 1 end)
    while Pill and Pill.Parent do
        RunService.Heartbeat:Wait()
        local now = tick()
        local elapsed = now - windowStart
        if elapsed >= 0.5 then
            lastFps = math.floor(frames / elapsed + 0.5)
            frames = 0
            windowStart = now
            fpsLbl.Text = tostring(lastFps)
            fpsLbl.TextColor3 = lastFps > 45 and T.good or (lastFps > 25 and T.warn or T.bad)
        end
        local ok, ping = pcall(function()
            return math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        end)
        if ok and ping then
            pingLbl.Text = ping .. " ms"
            pingLbl.TextColor3 = ping < 120 and T.warn or (ping < 280 and T.warn or T.bad)
        end
        pillClock.Text = (os.date("%I:%M %p"):gsub("^0", ""))
        pillDate.Text  = os.date("%a %b %d")
    end
    pcall(function() rsConn:Disconnect() end)
end)
end)()

-- ============= FLOATING PANELS ====================================
-- Move the tooltip out of the hidden Win and into Root for the new pill.
pcall(function() Tip.Parent = Root; Tip.ZIndex = 220 end)

local panels = {}
_G.__SeigePanels = panels
local panelSlot = 0

-- Animated visibility transition for any panel frame.
-- Respects _G.__SeigePageAnim and _G.__SeigePageAnimSpeed set in Themes tab.
_G.__SeigeAnimPanel = function(frame, show)
    if not frame then return end
    local style = _G.__SeigePageAnim or "Fade"
    local dur   = tonumber(_G.__SeigePageAnimSpeed) or 0.24
    if style == "None" then frame.Visible = show; return end
    -- Capture the "rest" geometry once; we tween from/to it on each toggle.
    if not frame:GetAttribute("__restPos") then
        frame:SetAttribute("__restPos",  true)
        frame:SetAttribute("__restPosX", frame.Position.X.Offset)
        frame:SetAttribute("__restPosY", frame.Position.Y.Offset)
        frame:SetAttribute("__restPosXS", frame.Position.X.Scale)
        frame:SetAttribute("__restPosYS", frame.Position.Y.Scale)
    end
    local px, py = frame:GetAttribute("__restPosX"), frame:GetAttribute("__restPosY")
    local pxs, pys = frame:GetAttribute("__restPosXS"), frame:GetAttribute("__restPosYS")
    local restPos = UDim2.new(pxs, px, pys, py)

    local scaleObj = frame:FindFirstChildOfClass("UIScale")
    if not scaleObj then
        scaleObj = Instance.new("UIScale"); scaleObj.Scale = 1; scaleObj.Parent = frame
    end

    local function tweenInto(props, easing, dir, time)
        TweenService:Create(frame, TweenInfo.new(time or dur, easing or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props):Play()
    end

    if show then
        frame.Visible = true
        frame.BackgroundTransparency = 1
        frame.Position = restPos
        scaleObj.Scale = 1
        if style == "Fade" then
            tweenInto({ BackgroundTransparency = (_G.__SeigeUITrans or 0.35) })
        elseif style == "Scale" then
            scaleObj.Scale = 0.85
            tweenInto({ BackgroundTransparency = (_G.__SeigeUITrans or 0.35) })
            TweenService:Create(scaleObj, TweenInfo.new(dur, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
        elseif style == "Slide-down" then
            frame.Position = UDim2.new(pxs, px, pys, py - 40)
            tweenInto({ Position = restPos, BackgroundTransparency = (_G.__SeigeUITrans or 0.35) })
        elseif style == "Slide-up" then
            frame.Position = UDim2.new(pxs, px, pys, py + 40)
            tweenInto({ Position = restPos, BackgroundTransparency = (_G.__SeigeUITrans or 0.35) })
        elseif style == "Slide-right" then
            frame.Position = UDim2.new(pxs, px - 60, pys, py)
            tweenInto({ Position = restPos, BackgroundTransparency = (_G.__SeigeUITrans or 0.35) })
        elseif style == "Flip" then
            scaleObj.Scale = 0.01
            tweenInto({ BackgroundTransparency = (_G.__SeigeUITrans or 0.35) })
            TweenService:Create(scaleObj, TweenInfo.new(dur, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Scale = 1 }):Play()
        elseif style == "Bounce" then
            scaleObj.Scale = 0.6
            tweenInto({ BackgroundTransparency = (_G.__SeigeUITrans or 0.35) })
            TweenService:Create(scaleObj, TweenInfo.new(dur * 1.3, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), { Scale = 1 }):Play()
        else
            frame.BackgroundTransparency = (_G.__SeigeUITrans or 0.35)
        end
    else
        if style == "Fade" then
            tweenInto({ BackgroundTransparency = 1 })
        elseif style == "Scale" then
            TweenService:Create(scaleObj, TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.85 }):Play()
            tweenInto({ BackgroundTransparency = 1 })
        elseif style == "Slide-down" then
            tweenInto({ Position = UDim2.new(pxs, px, pys, py + 40), BackgroundTransparency = 1 })
        elseif style == "Slide-up" then
            tweenInto({ Position = UDim2.new(pxs, px, pys, py - 40), BackgroundTransparency = 1 })
        elseif style == "Slide-right" then
            tweenInto({ Position = UDim2.new(pxs, px + 60, pys, py), BackgroundTransparency = 1 })
        elseif style == "Flip" then
            TweenService:Create(scaleObj, TweenInfo.new(dur, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { Scale = 0.01 }):Play()
            tweenInto({ BackgroundTransparency = 1 })
        elseif style == "Bounce" then
            TweenService:Create(scaleObj, TweenInfo.new(dur, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Scale = 0.6 }):Play()
            tweenInto({ BackgroundTransparency = 1 })
        end
        task.delay(dur + 0.02, function()
            if frame and frame.Parent then
                frame.Visible = false
                frame.Position = restPos
                if scaleObj then scaleObj.Scale = 1 end
                frame.BackgroundTransparency = (_G.__SeigeUITrans or 0.35)
            end
        end)
    end
end

local function makePanel(name, entry)
    local page = entry.page
    panelSlot = panelSlot + 1
    local slotX = (panelSlot - 1) % 3
    local slotY = math.floor((panelSlot - 1) / 3)
    local frame = inst("Frame", Root, {
        Name = "Panel_" .. name,
        Position = UDim2.new(1, -350 - slotX * 14, 0, 80 + slotY * 32),
        Size = UDim2.new(0, 320, 0, 380),
        BackgroundColor3 = T.bg, BackgroundTransparency = (_G.__SeigeUITrans or 0.35), BorderSizePixel = 0,
        Visible = false, Active = true, ZIndex = 110,
    })
    corner(frame, 12); stroke(frame, T.line, 1, 0.4)
    frame.ClipsDescendants = true
    inst("UIGradient", frame, {
        Rotation = 120,
        Color = ColorSequence.new(T.bg2, T.bg),
        Transparency = NumberSequence.new(0.05),
    })
    -- User-supplied panel background image (set via Themes tab)
    local bgImg = inst("ImageLabel", frame, {
        Name = "__SeigeBgImg",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        ScaleType = Enum.ScaleType.Crop,
        Image = "",
        ImageTransparency = 1,
        ZIndex = 110,
    })
    -- soft glow
    inst("ImageLabel", frame, {
        BackgroundTransparency = 1,
        Image = "rbxasset://textures/ui/Controls/DropShadow.png",
        ImageColor3 = T.acc, ImageTransparency = 0.88,
        ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(12,12,244,244),
        Size = UDim2.new(1, 28, 1, 28), Position = UDim2.new(0, -14, 0, -14),
        ZIndex = 109,
    })

    -- Header
    local hdr = inst("Frame", frame, {
        Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, Active = true, ZIndex = 112,
    })
    inst("TextLabel", hdr, {
        BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -44, 1, 0),
        Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = T.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = "SEIGE.LOL · " .. string.upper(entry.title or name),
        ZIndex = 113,
    })
    local xBtn = inst("TextButton", hdr, {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.new(0, 20, 0, 20),
        BackgroundColor3 = T.bg3, BackgroundTransparency = 0.2, BorderSizePixel = 0,
        AutoButtonColor = false,
        Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = T.text, Text = "×",
        ZIndex = 114,
    })
    corner(xBtn, 6); stroke(xBtn, T.line, 1, 0.4)
    xBtn.MouseEnter:Connect(function() tween(xBtn, 0.12, { BackgroundColor3 = T.bad, BackgroundTransparency = 0.1 }) end)
    xBtn.MouseLeave:Connect(function() tween(xBtn, 0.12, { BackgroundColor3 = T.bg3, BackgroundTransparency = 0.2 }) end)
    inst("Frame", frame, {
        Position = UDim2.new(0, 6, 0, 28), Size = UDim2.new(1, -12, 0, 1),
        BackgroundColor3 = T.line, BackgroundTransparency = 0.6, BorderSizePixel = 0,
        ZIndex = 112,
    })

    -- Re-host the existing tab page inside this panel
    page.Parent = frame
    page.Position = UDim2.new(0, 0, 0, 32)
    page.Size = UDim2.new(1, 0, 1, -36)
    page.Visible = true

    xBtn.MouseButton1Click:Connect(function()
        if _G.__SeigeAnimPanel then _G.__SeigeAnimPanel(frame, false) else frame.Visible = false end
        local btn = panels[name] and panels[name].btn
        if btn then
            tween(btn, 0.12, { BackgroundColor3 = T.bg3, BackgroundTransparency = 0.25 })
        end
    end)

    -- Per-panel drag
    do
        local dragging, ds, sp
        hdr.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                dragging = true; ds = i.Position; sp = frame.Position
            end
        end)
        UIS.InputChanged:Connect(function(i)
            if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                local d = i.Position - ds
                frame.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
            end
        end)
        UIS.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
        end)
    end

    panels[name] = { frame = frame, page = page, btn = nil }
    if _G.__SeigeApplyPanelBg then pcall(_G.__SeigeApplyPanelBg) end
    return frame
end

-------------------------------------------------- DETECTOR (other scripts)
;(function()
    -- Known script signatures: name -> patterns to match in URLs / source / GUI names
    local KNOWN = {
        { name = "AKADMIN (absent.wtf)",  patterns = { "absent%.wtf", "AKADMIN" }, gui = { "AKAdmin", "AKADMIN" } },
        { name = "Novoline",              patterns = { "novoline%.pro", "novoline" }, gui = { "Novoline" } },
        { name = "Infinite Yield",        patterns = { "EdgeIY/infiniteyield", "infiniteyield", "Infinite Yield" }, gui = { "IY", "InfiniteYield" } },
        { name = "Dex Explorer",          patterns = { "Dex%.lua", "Moon%-Dex", "dex%-v4" }, gui = { "Dex", "DexExplorer" } },
        { name = "Owl Hub",               patterns = { "owlhub", "Owl Hub" }, gui = { "OwlHub" } },
        { name = "Hydroxide",             patterns = { "Hydroxide", "Upholstery" }, gui = {} },
        { name = "Synapse X UI",          patterns = { "synapse" }, gui = { "Synapse" } },
        { name = "Script-Ware",           patterns = { "script%-ware", "scriptware" }, gui = { "ScriptWare" } },
        { name = "Krnl",                  patterns = { "krnl%." }, gui = { "Krnl" } },
        { name = "Fluxus",                patterns = { "fluxus" }, gui = { "Fluxus" } },
        { name = "Rayfield UI",           patterns = { "Rayfield", "shlexware/Rayfield" }, gui = { "Rayfield" } },
        { name = "Linoria / OrionLib",    patterns = { "Linoria", "OrionLib", "orion%.lua" }, gui = { "Orion", "Linoria" } },
        { name = "Reviz Admin",           patterns = { "Reviz%.lua", "reviz admin" }, gui = { "RevizAdmin" } },
        { name = "Nameless Admin",        patterns = { "Nameless Admin", "nameless%-admin" }, gui = { "NamelessAdmin" } },
        { name = "SEIGE.LOL (this)",      patterns = { "DESPAIRDEV293", "roblox%-script%-buddy", "seige%.lol" }, gui = { "SeigeAdmin", "Admin_v" } },
        { name = "ScriptBlox script",     patterns = { "scriptblox%.com", "scriptbloxapi", "rawscripts%.net" }, gui = {} },
    }

    local detected = {}      -- name -> { source, url, time }
    local listeners = {}

    local section = section
    local label   = label
    local button  = button
    local toggle  = toggle

    section(pgDetect, "Live detector")
    local statusLbl = label(pgDetect, "Status: armed — watching for HttpGet / loadstring calls")
    local countLbl  = label(pgDetect, "Detected: 0")

    -- scrolling list area
    local listScroll = inst("ScrollingFrame", pgDetect, {
        Size = UDim2.new(1, -8, 0, 220),
        BackgroundColor3 = T.bg2,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        CanvasSize = UDim2.new(0,0,0,0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    })
    corner(listScroll, 8); stroke(listScroll, T.line, 1, 0.5)
    local listLayout = inst("UIListLayout", listScroll, {
        Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder,
    })
    inst("UIPadding", listScroll, { PaddingTop = UDim.new(0,6), PaddingLeft = UDim.new(0,6), PaddingRight = UDim.new(0,6), PaddingBottom = UDim.new(0,6) })

    local function refresh()
        local n = 0
        for _ in pairs(detected) do n = n + 1 end
        countLbl:set(("Detected: %d"):format(n))
        for _, c in ipairs(listScroll:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end
        for name, info in pairs(detected) do
            local row = inst("Frame", listScroll, {
                Size = UDim2.new(1, -4, 0, 44),
                BackgroundColor3 = T.bg3, BackgroundTransparency = 0.2,
                BorderSizePixel = 0,
            })
            corner(row, 6); stroke(row, T.line, 1, 0.5)
            inst("UIPadding", row, { PaddingLeft = UDim.new(0,8), PaddingRight = UDim.new(0,8) })
            inst("TextLabel", row, {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 18), Position = UDim2.new(0,0,0,4),
                Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = T.text,
                TextXAlignment = Enum.TextXAlignment.Left, Text = "● " .. name,
            })
            inst("TextLabel", row, {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 16), Position = UDim2.new(0,0,0,22),
                Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = T.sub,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = (info.source or "?") .. (info.url and (" — " .. info.url:sub(1,60)) or ""),
            })
        end
    end

    local function flag(name, source, url)
        if detected[name] then
            -- update url if we have a fresher one
            if url and not detected[name].url then detected[name].url = url end
            return
        end
        detected[name] = { source = source, url = url, time = os.time() }
        statusLbl:set("Status: ⚠ " .. name .. " detected (" .. source .. ")")
        refresh()
    end

    local function matchText(text, source)
        if type(text) ~= "string" then return end
        for _, entry in ipairs(KNOWN) do
            for _, pat in ipairs(entry.patterns) do
                if text:lower():find(pat:lower(), 1, false) then
                    flag(entry.name, source, text:sub(1, 200))
                    break
                end
            end
        end
    end

    -- Hooks are OPT-IN. They can destabilize some executors (Solara, Wave,
    -- old Synapse builds), so we only install them when the user enables it.
    local hookInstalled = false
    local function installHooks()
        if hookInstalled then return end
        hookInstalled = true

        -- Prefer hookmetamethod (safe, executor-aware). Avoid rewriting __namecall directly.
        pcall(function()
            if hookmetamethod and newcclosure then
                local old
                old = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
                    local method = getnamecallmethod and getnamecallmethod() or ""
                    if method == "HttpGet" or method == "HttpGetAsync" or method == "GetAsync" then
                        local url = (...)
                        if type(url) == "string" then
                            -- defer matching so we never block the call
                            task.spawn(matchText, url, "HttpGet")
                        end
                    end
                    return old(self, ...)
                end))
                table.insert(listeners, "namecall hook installed (hookmetamethod)")
            end
        end)

        -- loadstring hook — only if hookfunction + newcclosure are both present.
        -- Many executors crash when a Lua closure is bound here.
        pcall(function()
            if hookfunction and newcclosure and loadstring then
                local oldLS
                oldLS = hookfunction(loadstring, newcclosure(function(src, chunkname)
                    if type(src) == "string" and #src < 200000 then
                        task.spawn(matchText, src, "loadstring")
                    end
                    return oldLS(src, chunkname)
                end))
                table.insert(listeners, "loadstring hook installed")
            end
        end)
    end


    -- 3) Scan existing GUIs in CoreGui / PlayerGui for known UI names
    local function scanGuis()
        local roots = {}
        pcall(function() table.insert(roots, game:GetService("CoreGui")) end)
        pcall(function() local pg = LP:FindFirstChildOfClass("PlayerGui"); if pg then table.insert(roots, pg) end end)
        for _, root in ipairs(roots) do
            for _, d in ipairs(root:GetDescendants()) do
                local n = d.Name
                for _, entry in ipairs(KNOWN) do
                    for _, g in ipairs(entry.gui) do
                        if n:lower():find(g:lower(), 1, false) then
                            flag(entry.name, "GUI: " .. root.Name .. "/" .. n, nil)
                            break
                        end
                    end
                end
            end
        end
    end

    -- 4) Scan running LocalScripts/ModuleScripts via getscripts/getloadedmodules
    local function scanScripts()
        -- Intentionally skip getgc() — it returns thousands of objects and
        -- crashes/freezes many executors. getscripts + getloadedmodules only.
        local lists = {}
        if getscripts       then pcall(function() lists[#lists+1] = getscripts()       end) end
        if getloadedmodules then pcall(function() lists[#lists+1] = getloadedmodules() end) end
        for _, list in ipairs(lists) do
            if type(list) == "table" then
                for _, obj in ipairs(list) do
                    pcall(function()
                        if typeof and typeof(obj) == "Instance" then
                            matchText(obj.Name, "Script: " .. obj.ClassName)
                        end
                    end)
                end
            end
        end
    end

    statusLbl:set("Status: idle — hooks OFF (enable below to watch new scripts)")

    toggle(pgDetect, "Enable HttpGet / loadstring hooks (advanced — may crash some executors)", false, function(v)
        if v then
            installHooks()
            statusLbl:set("Status: hooks active — " .. (#listeners > 0 and table.concat(listeners, ", ") or "no hooks available in this executor"))
        else
            statusLbl:set("Status: hooks were enabled this session — rejoin to fully remove")
        end
    end)

    button(pgDetect, "Rescan now (GUIs + scripts)", function()
        pcall(scanGuis); pcall(scanScripts)
        statusLbl:set("Status: rescan complete (" .. os.date("%H:%M:%S") .. ")")
    end)
    button(pgDetect, "Clear detections", function()
        detected = {}
        statusLbl:set("Status: cleared")
        refresh()
    end)

    local autoOn = false
    toggle(pgDetect, "Auto-scan GUIs every 10s (off by default)", false, function(v) autoOn = v end)
    task.spawn(function()
        while true do
            task.wait(10)
            if autoOn then pcall(scanGuis) end
        end
    end)

    -- No automatic initial scan — MacSploit / some executors throw
    -- "DM Lock Violation" when CoreGui is walked too early. User must press Rescan.

    --------------------------------------------------------------------------
    -- DISCORD MEMBER LIST (server 1425348267457253498, bot 1455765555318493431)
    -- The bot publishes a JSON file of verified Roblox UserIds of members.
    -- This script just HttpGet's that file — no token embedded.
    -- Expected JSON: { "userIds": [123, 456, ...], "updated": <unix> }
    --------------------------------------------------------------------------
    section(pgDetect, "Discord server members (auto-tag)")
    local DISCORD_MEMBERS_URL = "https://raw.githubusercontent.com/DESPAIRDEV293/roblox-script-buddy/main/discord-members.json"
    local discordTag = "Scripter"
    local discordSet = {}        -- [userId] = true
    local discordLastPull = 0
    local discordAutoPull = true
    local discordNotify = true

    local discordStatus = label(pgDetect, "Discord: not pulled yet")
    local discordCount  = label(pgDetect, "Members loaded: 0")

    local function applyDiscordTags()
        local applied = 0
        for _, p in ipairs(Players:GetPlayers()) do
            if discordSet[p.UserId] and not Tags:has(p.UserId, discordTag) then
                Tags:add(p.UserId, discordTag)
                applied = applied + 1
                if discordNotify then
                    notify("Discord member in game: " .. p.Name, "warn")
                    statusLbl:set("Status: ⚠ Discord member " .. p.Name .. " detected")
                end
            end
        end
        return applied
    end

    local function pullDiscordMembers(silent)
        local ok, body = pcall(function()
            return game:HttpGet(DISCORD_MEMBERS_URL .. "?v=" .. tostring(os.time()))
        end)
        if not ok or not body then
            if not silent then notify("Discord pull failed: " .. tostring(body), "bad") end
            discordStatus:set("Discord: pull failed (" .. os.date("%H:%M:%S") .. ")")
            return
        end
        local HS = game:GetService("HttpService")
        local okJ, data = pcall(function() return HS:JSONDecode(body) end)
        if not okJ or type(data) ~= "table" or type(data.userIds) ~= "table" then
            if not silent then notify("Discord pull: bad JSON", "bad") end
            discordStatus:set("Discord: bad JSON (" .. os.date("%H:%M:%S") .. ")")
            return
        end
        discordSet = {}
        local n = 0
        for _, uid in ipairs(data.userIds) do
            local id = tonumber(uid)
            if id then discordSet[id] = true; n = n + 1 end
        end
        discordLastPull = os.time()
        discordCount:set("Members loaded: " .. n)
        discordStatus:set("Discord: pulled OK at " .. os.date("%H:%M:%S"))
        local applied = applyDiscordTags()
        if not silent then notify("Discord: " .. n .. " members, tagged " .. applied, "good") end
    end

    button(pgDetect, "Pull Discord members now", function() pullDiscordMembers(false) end)
    toggle(pgDetect, "Auto-pull every 5 min", true, function(v) discordAutoPull = v end)
    toggle(pgDetect, "Notify when Discord member joins", true, function(v) discordNotify = v end)

    -- Re-check on join
    bind(Players.PlayerAdded:Connect(function(p)
        task.wait(1)
        if discordSet[p.UserId] then
            if not Tags:has(p.UserId, discordTag) then Tags:add(p.UserId, discordTag) end
            if discordNotify then
                notify("Discord member joined: " .. p.Name, "warn")
                statusLbl:set("Status: ⚠ Discord member " .. p.Name .. " joined")
            end
        end
    end))

    -- Initial + periodic pull
    task.spawn(function()
        task.wait(2)
        pullDiscordMembers(true)
        while true do
            task.wait(300)
            if discordAutoPull then pcall(pullDiscordMembers, true) end
        end
    end)

end)()






-- preferred order on the pill

;(function()
local tabOrder = {
    "Profile", "Players", "Cmds", "Shaders", "Spotify", "Config", "Misc",
}
-- Per-tab image icons (rbxassetid). Images should be white on transparent bg.
local tabImages = {
    Profile = "rbxassetid://72672681350713",   -- player
    Players = "rbxassetid://133507370080897",  -- users
    Cmds    = "rbxassetid://118287619529782",  -- command
    Shaders = "rbxassetid://89184279571938",   -- shaders
    Spotify = "rbxassetid://103992944497423",  -- music
    Config  = "rbxassetid://125262243617493",  -- settings
}
-- include any tabs that weren't listed (forward-compat)
for n, _ in pairs(tabs) do
    local found = false
    for _, x in ipairs(tabOrder) do if x == n then found = true; break end end
    if not found then tabOrder[#tabOrder + 1] = n end
end

idx = 0
for _, name in ipairs(tabOrder) do
    local entry = tabs[name]
    if entry then
        idx = idx + 1
        makePanel(name, entry)
        local imgId = tabImages[name]
        local WHITE = T.text
        local ib = inst("TextButton", iconsRow, {
            Size = UDim2.new(0, 32, 0, 32),
            BackgroundColor3 = WHITE, BackgroundTransparency = 1, BorderSizePixel = 0,
            AutoButtonColor = false,
            Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = WHITE,
            Text = imgId and "" or ((entry.ico and entry.ico.Text) or "•"),
            LayoutOrder = idx, ZIndex = 102,
        })
        corner(ib, 16)
        local ibImg
        if imgId then
            ibImg = inst("ImageLabel", ib, {
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                Size = UDim2.new(0, 18, 0, 18),
                Image = imgId,
                ImageColor3 = WHITE,
                ZIndex = 103,
            })
        end
        panels[name].btn = ib
        panels[name].ibImg = ibImg
        panels[name].defaultIcon = imgId

        local function setHover(on)
            local p = panels[name]
            local active = p and p.frame.Visible
            if active then
                tween(ib, 0.12, { BackgroundColor3 = WHITE, BackgroundTransparency = 0 })
                ib.TextColor3 = T.bg
                if ibImg then ibImg.ImageColor3 = T.bg end
            elseif on then
                tween(ib, 0.12, { BackgroundColor3 = WHITE, BackgroundTransparency = 0.82 })
                ib.TextColor3 = WHITE
                if ibImg then ibImg.ImageColor3 = WHITE end
            else
                tween(ib, 0.12, { BackgroundColor3 = WHITE, BackgroundTransparency = 1 })
                ib.TextColor3 = WHITE
                if ibImg then ibImg.ImageColor3 = WHITE end
            end
        end
        ib.MouseEnter:Connect(function()
            setHover(true)
            Tip.Text = name
            Tip.Size = UDim2.new(0, math.max(60, #name * 7 + 14), 0, 22)
            local abs = ib.AbsolutePosition; local sz = ib.AbsoluteSize
            Tip.Position = UDim2.new(0, abs.X + sz.X / 2 - 40, 0, abs.Y + sz.Y + 6)
            Tip.Visible = true
        end)
        ib.MouseLeave:Connect(function() setHover(false); Tip.Visible = false end)
        ib.MouseButton1Click:Connect(function()
            local p = panels[name]
            local newVis = not p.frame.Visible
            if _G.__SeigeAnimPanel then _G.__SeigeAnimPanel(p.frame, newVis) else p.frame.Visible = newVis end
            setHover(false)
        end)
    end
end

-- Per-panel image + per-icon image controls (in Themes/Settings page)
do
    local names = {}
    for _, n in ipairs(tabOrder) do
        if panels[n] then names[#names+1] = n end
    end
    if #names > 0 then
        section(pgThemes, "Per-panel background image")
        local sel = names[1]
        dropdown(pgThemes, "Target panel", names, function(v) sel = v end)
        textbox(pgThemes, "Image asset id / URL (blank = use global)", function(v)
            panelBgState.panels[sel] = panelBgState.panels[sel] or {}
            panelBgState.panels[sel].image = v
            applyPanelBg(); saveCfg()
            notify((v == "" and "Cleared image for " or "Updated image for ") .. sel, "good")
        end)
        slider(pgThemes, "Opacity (selected panel)", 0, 1, 0.5, function(v)
            panelBgState.panels[sel] = panelBgState.panels[sel] or {}
            panelBgState.panels[sel].trans = 1 - v
            applyPanelBg(); saveCfg()
        end)
        button(pgThemes, "Reset selected panel", function()
            panelBgState.panels[sel] = nil; applyPanelBg(); saveCfg()
            notify("Reset " .. sel, "good")
        end)

        section(pgThemes, "Per-icon image")
        local selI = names[1]
        dropdown(pgThemes, "Target icon", names, function(v) selI = v end)
        textbox(pgThemes, "Icon image asset id / URL (blank = default)", function(v)
            panelBgState.icons[selI] = v
            applyIconImages(); saveCfg()
            notify((v == "" and "Reset icon " or "Updated icon ") .. selI, "good")
        end)
        button(pgThemes, "Reset selected icon", function()
            panelBgState.icons[selI] = nil; applyIconImages(); saveCfg()
            notify("Reset icon " .. selI, "good")
        end)
        label(pgThemes, "Tip: per-panel image overrides the global panel background.")
    end
end

-- Pill compact toggle + hamburger dropdown menu
do
    local hidden = { brandBlock, fpsBox, pingBox, iconsRow, clockBox }
    local dividers = {}
    for _, ch in ipairs(Pill:GetChildren()) do
        if ch:IsA("Frame") and ch.Size.X.Offset == 1 then dividers[#dividers+1] = ch end
    end

    -- Dropdown menu (hidden by default), used when layout = "Hamburger".
    local menu = inst("Frame", Root, {
        Name = "PillMenu", Visible = false,
        Size = UDim2.new(0, 200, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = T.bg,
        BackgroundTransparency = (_G.__SeigeUITrans or 0.35),
        BorderSizePixel = 0, ZIndex = 130,
    })
    corner(menu, 10); stroke(menu, T.text, 1, 0.7)
    inst("UIListLayout", menu, {
        Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder,
    })
    inst("UIPadding", menu, {
        PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6),
        PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6),
    })
    _G.__SeigeMenu = menu

    local function rebuildMenu()
        for _, c in ipairs(menu:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        local i = 0
        for name, p in pairs(panels) do
            i = i + 1
            local row = inst("TextButton", menu, {
                Size = UDim2.new(1, 0, 0, 28), LayoutOrder = i,
                BackgroundColor3 = T.bg3,
                BackgroundTransparency = (_G.__SeigeUITrans or 0.35) + 0.1,
                AutoButtonColor = false, BorderSizePixel = 0,
                Font = Enum.Font.GothamSemibold, TextSize = 12,
                TextColor3 = T.text, Text = "  " .. name,
                TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 131,
            })
            corner(row, 6)
            row.MouseEnter:Connect(function() tween(row, 0.1, { BackgroundTransparency = 0.1 }) end)
            row.MouseLeave:Connect(function() tween(row, 0.1, { BackgroundTransparency = (_G.__SeigeUITrans or 0.35) + 0.1 }) end)
            row.MouseButton1Click:Connect(function()
                local newVis = not p.frame.Visible
                if _G.__SeigeAnimPanel then _G.__SeigeAnimPanel(p.frame, newVis) else p.frame.Visible = newVis end
                menu.Visible = false
            end)
        end
    end

    local function positionMenu()
        local abs = pillToggle.AbsolutePosition
        local sz  = pillToggle.AbsoluteSize
        menu.Position = UDim2.new(0, abs.X + sz.X - 200, 0, abs.Y + sz.Y + 6)
    end

    pillToggle.MouseEnter:Connect(function()
        tween(pillToggle, 0.12, { BackgroundTransparency = 0.78 })
    end)
    pillToggle.MouseLeave:Connect(function()
        tween(pillToggle, 0.12, { BackgroundTransparency = 0.88 })
    end)

    local barCollapsed = false
    local function setBarCollapsed(c)
        barCollapsed = c
        for _, f in ipairs(hidden) do f.Visible = not c end
        for _, d in ipairs(dividers) do d.Visible = not c end
        if c then
            pillToggleImg.Visible = false; pillToggle.Text = "≡"
        else
            pillToggle.Text = ""; pillToggleImg.Visible = true
        end
    end

    pillToggle.MouseButton1Click:Connect(function()
        if (_G.__SeigeLayoutMode or "Bar") == "Hamburger" then
            if not menu.Visible then rebuildMenu(); positionMenu() end
            menu.Visible = not menu.Visible
        else
            setBarCollapsed(not barCollapsed)
            if barCollapsed then
                for _, p in pairs(panels) do
                    if _G.__SeigeAnimPanel then _G.__SeigeAnimPanel(p.frame, false) else p.frame.Visible = false end
                end
            end
        end
    end)

    -- ============= DOCK LAYOUT (bottom-anchored, mirrors panel icons) =====
    local Dock = inst("Frame", Root, {
        Name = "BottomDock",
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -18),
        Size = UDim2.new(0, 0, 0, 56),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = T.bg,
        BackgroundTransparency = math.max(0.05, (_G.__SeigeUITrans or 0.35) - 0.1),
        BorderSizePixel = 0, Visible = false, Active = true, ZIndex = 100,
    })
    corner(Dock, 18); stroke(Dock, T.acc, 1, 0.55)
    inst("UIPadding", Dock, {
        PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
        PaddingTop = UDim.new(0, 7),   PaddingBottom = UDim.new(0, 7),
    })
    inst("UIListLayout", Dock, {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder,
    })
    _G.__SeigeDock = Dock

    local dockBtns = {}
    local function refreshDockState()
        for name, rec in pairs(dockBtns) do
            local p = panels[name]
            local active = p and p.frame and p.frame.Visible
            tween(rec.btn, 0.12, {
                BackgroundTransparency = active and 0.15 or 0.85,
            })
            if rec.img then rec.img.ImageColor3 = active and T.bg or T.text end
            rec.btn.TextColor3 = active and T.bg or T.text
        end
    end

    local dockOrder = { "Profile", "Players", "Cmds", "Shaders", "Spotify", "Config", "Misc" }
    local seen = {}
    for _, n in ipairs(dockOrder) do seen[n] = true end
    for n, _ in pairs(panels) do if not seen[n] then dockOrder[#dockOrder + 1] = n end end

    local dOrd = 0
    for _, name in ipairs(dockOrder) do
        local p = panels[name]
        if p then
            dOrd = dOrd + 1
            local icoTxt = (tabs[name] and tabs[name].ico and tabs[name].ico.Text) or "•"
            local btn = inst("TextButton", Dock, {
                Size = UDim2.new(0, 44, 0, 42),
                BackgroundColor3 = T.text, BackgroundTransparency = 0.85,
                BorderSizePixel = 0, AutoButtonColor = false,
                Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = T.text,
                Text = p.defaultIcon and "" or icoTxt,
                LayoutOrder = dOrd, ZIndex = 101,
            })
            corner(btn, 12); stroke(btn, T.acc, 1, 0.55)
            local img
            if p.defaultIcon then
                img = inst("ImageLabel", btn, {
                    BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(0.5, 0, 0.5, 0),
                    Size = UDim2.new(0, 22, 0, 22),
                    Image = p.defaultIcon, ImageColor3 = T.text, ZIndex = 102,
                })
            end
            dockBtns[name] = { btn = btn, img = img }
            btn.MouseEnter:Connect(function()
                if not (p.frame and p.frame.Visible) then
                    tween(btn, 0.1, { BackgroundTransparency = 0.65 })
                end
                Tip.Text = name
                Tip.Size = UDim2.new(0, math.max(60, #name * 7 + 14), 0, 22)
                local abs = btn.AbsolutePosition; local sz = btn.AbsoluteSize
                Tip.Position = UDim2.new(0, abs.X + sz.X/2 - 40, 0, abs.Y - 28)
                Tip.Visible = true
            end)
            btn.MouseLeave:Connect(function()
                refreshDockState(); Tip.Visible = false
            end)
            btn.MouseButton1Click:Connect(function()
                local newVis = not p.frame.Visible
                if _G.__SeigeAnimPanel then _G.__SeigeAnimPanel(p.frame, newVis) else p.frame.Visible = newVis end
                task.delay(0.02, refreshDockState)
            end)
        end
    end
    _G.__SeigeRefreshDock = refreshDockState

    -- Public: apply a layout mode.
    _G.__SeigeApplyLayout = function(mode)
        _G.__SeigeLayoutMode = mode
        if mode == "Dock" then
            Pill.Visible = false
            Dock.Visible = true
            menu.Visible = false
            for _, p in pairs(panels) do
                if p.frame then p.frame.Visible = false end
            end
            refreshDockState()
        elseif mode == "Hamburger" then
            Pill.Visible = true
            Dock.Visible = false
            -- Hide bar contents, leave only ≡; close any open panels.
            setBarCollapsed(true)
            for _, p in pairs(panels) do
                if p.frame then p.frame.Visible = false end
            end
            menu.Visible = false
        else
            Pill.Visible = true
            Dock.Visible = false
            setBarCollapsed(false)
            menu.Visible = false
        end
    end

    -- Public: apply UI translucency to Pill + every panel + menu.
    _G.__SeigeApplyUITrans = function(t)
        _G.__SeigeUITrans = t
        if Pill then Pill.BackgroundTransparency = math.max(0.05, t - 0.1) end
        if _G.__SeigeDock then _G.__SeigeDock.BackgroundTransparency = math.max(0.05, t - 0.1) end
        if menu then menu.BackgroundTransparency = t end
        if _G.__SeigePanels then
            for _, p in pairs(_G.__SeigePanels) do
                if p.frame and p.frame.Visible then p.frame.BackgroundTransparency = t end
            end
        end
        -- Sync floating command popups (Bang, Reanim, Circle, Help, etc.)
        if _G.__SeigePopupPanels then
            for win, _ in pairs(_G.__SeigePopupPanels) do
                if win and win.Parent then
                    pcall(function() win.BackgroundTransparency = t end)
                else
                    _G.__SeigePopupPanels[win] = nil
                end
            end
        end
    end


    -- Close menu when clicking outside.
    UIS.InputBegan:Connect(function(i)
        if not menu.Visible then return end
        if i.UserInputType ~= Enum.UserInputType.MouseButton1
           and i.UserInputType ~= Enum.UserInputType.Touch then return end
        local mp = i.Position
        local a, b = menu.AbsolutePosition, menu.AbsoluteSize
        local insideMenu = mp.X >= a.X and mp.X <= a.X + b.X and mp.Y >= a.Y and mp.Y <= a.Y + b.Y
        local pa, pb = pillToggle.AbsolutePosition, pillToggle.AbsoluteSize
        local insideToggle = mp.X >= pa.X and mp.X <= pa.X + pb.X and mp.Y >= pa.Y and mp.Y <= pa.Y + pb.Y
        if not insideMenu and not insideToggle then menu.Visible = false end
    end)
end

-- setTab is now a no-op (panels manage their own visibility); keep symbol for
-- backwards compatibility with anything that might call it.
setTab = function() end

-- F2 toggle for the new chrome
bind(UIS.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.UserInputType == Enum.UserInputType.Keyboard and i.KeyCode == Enum.KeyCode.F2 then
        local mode = _G.__SeigeLayoutMode or "Bar"
        local chrome = (mode == "Dock") and _G.__SeigeDock or Pill
        local v = not chrome.Visible
        chrome.Visible = v
        if not v then
            for _, p in pairs(panels) do
                if _G.__SeigeAnimPanel then _G.__SeigeAnimPanel(p.frame, false) else p.frame.Visible = false end
                if p.btn then
                    tween(p.btn, 0.12, { BackgroundColor3 = T.text, BackgroundTransparency = 1 })
                end
            end
            if _G.__SeigeRefreshDock then _G.__SeigeRefreshDock() end
        end
    end
end))

-- F6 command bar (executes !commands like !rj, !tprj)
-- IMPORTANT: ScreenGuis cannot be nested inside other ScreenGuis or they won't render.
local cmdBarGui = inst("ScreenGui", nil, {
    Name = "SeigeCmdBar", IgnoreGuiInset = true, ResetOnSpawn = false,
    DisplayOrder = 200,
})
safeParent(cmdBarGui)
cmdBar = inst("Frame", cmdBarGui, {
    AnchorPoint = Vector2.new(0.5, 1),
    Position = UDim2.new(0.5, 0, 1, -24),
    Size = UDim2.new(0, 520, 0, 40),
    BackgroundColor3 = T.bg2, BackgroundTransparency = 0.1, BorderSizePixel = 0,
    Visible = false, ZIndex = 200,
})
corner(cmdBar, 10); stroke(cmdBar, T.line, 1, 0.4)
local cmdPrefix = inst("TextLabel", cmdBar, {
    Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(0, 18, 1, 0),
    BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 16,
    TextColor3 = T.acc, Text = ">", ZIndex = 201,
})
cmdBox = inst("TextBox", cmdBar, {
    Position = UDim2.new(0, 34, 0, 0), Size = UDim2.new(1, -44, 1, 0),
    BackgroundTransparency = 1, BorderSizePixel = 0,
    Font = Enum.Font.Code, TextSize = 14, TextColor3 = T.text, PlaceholderColor3 = T.dim,
    TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false,
    PlaceholderText = "Type a command (!rj, !tprj) and press Enter",
    Text = "", ZIndex = 201,
})

function findPlr(q)
    if not q or q == "" then return nil end
    q = q:lower()
    if q == "me" then return LP end
    local best, bestScore
    for _, p in ipairs(Players:GetPlayers()) do
        local nm, dn = p.Name:lower(), p.DisplayName:lower()
        if nm == q or dn == q then return p end
        -- prefix match scores highest, substring match scores medium
        local score
        if nm:sub(1, #q) == q or dn:sub(1, #q) == q then
            score = 100 - #nm  -- shorter name = better
        elseif nm:find(q, 1, true) or dn:find(q, 1, true) then
            score = 10 - #nm
        end
        if score and (not bestScore or score > bestScore) then
            best, bestScore = p, score
        end
    end
    return best
end

cmdHandlers = {}
_G.__SeigeCmds = cmdHandlers
cmdHandlers["rj"] = function()
    notify("Rejoining...", "good")
    pcall(function() TeleportSrv:Teleport(game.PlaceId, LP) end)
end
cmdHandlers["tprj"] = function()
    local h = hrp()
    if not h then notify("No character to snapshot", "bad"); return end
    local c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12 = h.CFrame:GetComponents()
    -- Robust position restore for the next server:
    --  • waits for the character + humanoid to fully load
    --  • anchors the HRP so spawn logic can't shove us back
    --  • holds the CFrame for ~6 seconds across every CharacterAdded
    --  • unanchors cleanly so movement works after
    local restore = string.format([[
task.spawn(function()
    local p = game:GetService('Players').LocalPlayer
    local cf = CFrame.new(%.4f,%.4f,%.4f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f)
    local function apply(c)
        local r = c:WaitForChild('HumanoidRootPart', 15)
        local hum = c:FindFirstChildOfClass('Humanoid') or c:WaitForChild('Humanoid', 5)
        if not r then return end
        -- wait until the humanoid actually owns the root (avoids "in-falling" snap)
        for _ = 1, 30 do
            if hum and hum.RootPart == r and r.Parent then break end
            task.wait(0.1)
        end
        task.wait(0.25)
        local wasAnchored = r.Anchored
        r.Anchored = true
        local t0 = tick()
        while tick() - t0 < 6 do
            if not r.Parent then return end
            pcall(function() r.CFrame = cf end)
            pcall(function()
                r.AssemblyLinearVelocity  = Vector3.zero
                r.AssemblyAngularVelocity = Vector3.zero
            end)
            task.wait(0.1)
        end
        pcall(function() r.Anchored = wasAnchored end)
    end
    local c = p.Character or p.CharacterAdded:Wait()
    apply(c)
    p.CharacterAdded:Connect(apply)
end)
]], c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12)

    local q = (syn and syn.queue_on_teleport)
        or rawget(getfenv(), "queue_on_teleport")
        or (fluxus and fluxus.queue_on_teleport)
        or (getgenv and getgenv().queue_on_teleport)
    if q then
        local okQ, errQ = pcall(q, restore)
        if not okQ then notify("queue_on_teleport failed: " .. tostring(errQ), "bad") end
    else
        notify("Your executor lacks queue_on_teleport — position won't restore", "warn")
    end
    notify("Teleport rejoin (restoring position)...", "good")
    local ok = pcall(function()
        TeleportSrv:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
    end)
    if not ok then
        pcall(function() TeleportSrv:Teleport(game.PlaceId, LP) end)
        notify("Falling back to normal rejoin", "warn")
    end
end
cmdHandlers["sit"] = function()
    local c = LP.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    if h then h.Sit = true; notify("Sit", "good") else notify("No humanoid", "bad") end
end
cmdHandlers["face"] = function(arg)
    local target = findPlr(arg)
    if not target then notify("Player not found", "bad"); return end
    local myH = hrp(); local thrp = phrp(target)
    if not (myH and thrp) then notify("No character", "bad"); return end
    local pos = myH.Position
    myH.CFrame = CFrame.new(pos, Vector3.new(thrp.Position.X, pos.Y, thrp.Position.Z))
    notify("Facing " .. target.Name, "good")
end
cmdHandlers["headsit"] = function(arg)
    -- Toggle: !headsit <player> locks you sitting on their head; !headsit (no arg) unlocks
    if _G.__HeadLock then
        if _G.__HeadLock.conn then pcall(function() _G.__HeadLock.conn:Disconnect() end) end
        _G.__HeadLock = nil
        local h = hum(); if h then h.Sit = false end
        notify("Head-lock off", "good")
        if not arg or arg == "" then return end
    end
    if not arg or arg == "" then notify("Usage: !headsit <player>  (run again to unlock)", "warn"); return end
    local target = findPlr(arg)
    if not target then notify("Player not found", "bad"); return end
    local myH = hrp(); local h = hum()
    if not myH or not h then notify("No character", "bad"); return end
    h.Sit = true
    _G.__HeadLock = { target = target }
    _G.__HeadLock.conn = RunService.Heartbeat:Connect(function()
        local t = _G.__HeadLock and _G.__HeadLock.target
        if not t or not t.Parent then
            if _G.__HeadLock and _G.__HeadLock.conn then _G.__HeadLock.conn:Disconnect() end
            _G.__HeadLock = nil; return
        end
        local tc = t.Character
        local thead = tc and tc:FindFirstChild("Head")
        local me = hrp(); local mh = hum()
        if thead and me then
            me.CFrame = thead.CFrame * CFrame.new(0, 1.5, 0)
            if mh then mh.Sit = true end
        end
    end)
    notify("Sitting on " .. target.Name .. "'s head — !headsit again to unlock", "good")
end
cmdHandlers["unhead"] = function()
    if _G.__HeadLock then
        if _G.__HeadLock.conn then pcall(function() _G.__HeadLock.conn:Disconnect() end) end
        _G.__HeadLock = nil
        local h = hum(); if h then h.Sit = false end
        notify("Head-lock off", "good")
    end
end
cmdHandlers["unheadsit"] = function()
    -- 1) If WE are the one sitting on someone's head, kill the head-lock loop first.
    --    Without this, the heartbeat re-clamps us back onto the target's head
    --    every frame and the "stand up" never sticks.
    if _G.__HeadLock then
        if _G.__HeadLock.conn then pcall(function() _G.__HeadLock.conn:Disconnect() end) end
        _G.__HeadLock = nil
    end

    local mychar = LP.Character
    local h  = mychar and mychar:FindFirstChildOfClass("Humanoid")
    local r  = mychar and mychar:FindFirstChild("HumanoidRootPart")
    if h then
        h.Sit          = false
        h.PlatformStand = false
        h.Jump         = true
    end
    -- 2) Eject ourselves: detach any SeatWeld parented to the HRP and pop upward.
    if r then
        for _, w in ipairs(r:GetChildren()) do
            if w:IsA("Weld") and (w.Name == "SeatWeld" or w.Part0 and w.Part0:IsA("Seat")) then
                pcall(function() w:Destroy() end)
            end
        end
        pcall(function()
            r.AssemblyLinearVelocity  = Vector3.new(0, 60, 0)
            r.AssemblyAngularVelocity = Vector3.zero
            r.CFrame = r.CFrame + Vector3.new(0, 8, 0)
        end)
    end

    -- 3) If SOMEONE ELSE is sitting on OUR head, shove them off. We can't move
    --    their body (no network ownership), but we can yank our head out from
    --    under them — drop into the floor briefly, then pop back up. The rider
    --    loses their anchor frame and falls off.
    if r then
        local saved = r.CFrame
        pcall(function() r.CFrame = saved - Vector3.new(0, 12, 0) end)
        task.wait(0.15)
        pcall(function() r.CFrame = saved + Vector3.new(0, 4, 0) end)
        if h then h.Jump = true end
    end

    notify("Headsit cleared — rider ejected", "good")
end
-- Shared bang config used by panel + commands
_G.__SeigeBang = _G.__SeigeBang or {
    mode = "front",     -- "front" | "back" | "face"
    distance = 1.2,
    height = 0,
    speed = 3,
    autoFace = true,    -- face the target (front/face modes)
    spin = false,       -- orbit around them
    spinSpeed = 4,
}
local function _bangStop()
    if _G.__BangConn then pcall(function() _G.__BangConn:Disconnect() end); _G.__BangConn = nil end
    if _G.__BangTrack then pcall(function() _G.__BangTrack:Stop() end); _G.__BangTrack = nil end
end
local function _bangStart(target)
    local c = LP.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    local thrp = phrp(target)
    if not (h and thrp) then notify("Missing humanoid/target", "bad"); return end
    _bangStop()
    pcall(function()
        local anim = Instance.new("Animation")
        anim.AnimationId = "rbxassetid://5918726674"
        local track = h:LoadAnimation(anim)
        track:Play()
        track:AdjustSpeed(_G.__SeigeBang.speed or 3)
        _G.__BangTrack = track
        local t0 = tick()
        _G.__BangConn = RunService.Heartbeat:Connect(function()
            local myH = hrp()
            local tH = phrp(target)
            if not myH or not tH then return end
            local B = _G.__SeigeBang
            local dist = B.distance or 1.2
            local hOff = Vector3.new(0, B.height or 0, 0)
            if B.spin then
                local ang = (tick() - t0) * (B.spinSpeed or 4)
                local off = Vector3.new(math.cos(ang) * dist, B.height or 0, math.sin(ang) * dist)
                myH.CFrame = CFrame.new(tH.Position + off, tH.Position)
            elseif B.mode == "back" then
                myH.CFrame = tH * CFrame.new(0, B.height or 0, dist)
            elseif B.mode == "face" then
                local head = target.Character and target.Character:FindFirstChild("Head")
                local hp = (head and head.Position or (tH.Position + Vector3.new(0,1.5,0))) + hOff
                local pos = hp + tH.LookVector * (dist * 0.5)
                myH.CFrame = CFrame.new(pos, hp)
            else
                local pos = tH.Position + tH.LookVector * dist + hOff
                if B.autoFace then
                    myH.CFrame = CFrame.new(pos, tH.Position)
                else
                    myH.CFrame = tH * CFrame.new(0, B.height or 0, -dist)
                end
            end
        end)
    end)
    notify("Bang (" .. (_G.__SeigeBang.mode) .. ") " .. target.Name .. " — !unbang to stop", "good")
end
local function _startBang(arg, mode)
    local target = findPlr(arg)
    if not target then notify("Player not found", "bad"); return end
    _G.__SeigeBang.mode = mode
    _bangStart(target)
end
cmdHandlers["bang"]     = function(arg) _startBang(arg, "front") end
cmdHandlers["facebang"] = function(arg) _startBang(arg, "face")  end
cmdHandlers["backbang"] = function(arg) _startBang(arg, "back")  end
cmdHandlers["unbang"] = function()
    _bangStop()
    notify("Bang stopped", "good")
end

-- ===== Hold (shouldersit / carry / piggyback) =====
-- One shared loop; kind controls offset & whose CFrame is driven.
_G.__SeigeHold = _G.__SeigeHold or { conn = nil, target = nil, kind = nil }
local function _holdStop()
    local H = _G.__SeigeHold
    if H.conn then pcall(function() H.conn:Disconnect() end); H.conn = nil end
    H.target = nil; H.kind = nil
    local mh = hum(); if mh then mh.Sit = false end
end
local function _holdStart(target, kind)
    if not target or not target.Character then notify("Player not found", "bad"); return end
    _holdStop()
    local H = _G.__SeigeHold
    H.target = target; H.kind = kind
    H.conn = RunService.Heartbeat:Connect(function()
        local t = H.target
        if not t or not t.Parent then _holdStop(); return end
        local tc = t.Character; if not tc then return end
        local thrp = tc:FindFirstChild("HumanoidRootPart")
        local thead = tc:FindFirstChild("Head")
        local me   = hrp()
        local mh   = hum()
        if not me or not thrp then return end
        if kind == "shouldersit" then
            -- sit on their right shoulder
            if mh then mh.Sit = true end
            local base = (tc:FindFirstChild("UpperTorso") or thrp).CFrame
            me.CFrame = base * CFrame.new(0.9, 1.8, 0)
        elseif kind == "carry" then
            -- target is held in front of us, slightly above
            local tH = tc:FindFirstChildOfClass("Humanoid"); if tH then tH.Sit = true end
            thrp.CFrame = me.CFrame * CFrame.new(0, 2.2, -1.6)
        elseif kind == "piggyback" then
            -- we ride on target's back
            if mh then mh.Sit = true end
            me.CFrame = thrp.CFrame * CFrame.new(0, 1.6, 1.2)
        end
    end)
end
cmdHandlers["shouldersit"] = function(arg)
    local target = findPlr(arg); if not target then notify("Player not found", "bad"); return end
    _holdStart(target, "shouldersit"); notify("Sitting on " .. target.Name .. "'s shoulders — !unshoulder to stop", "good")
end
cmdHandlers["unshoulder"]    = function() _holdStop(); notify("Off shoulders", "good") end
cmdHandlers["unshouldersit"] = cmdHandlers["unshoulder"]
cmdHandlers["carry"] = function(arg)
    local target = findPlr(arg); if not target then notify("Player not found", "bad"); return end
    _holdStart(target, "carry"); notify("Carrying " .. target.Name .. " — !uncarry to stop", "good")
end
cmdHandlers["uncarry"] = function() _holdStop(); notify("Dropped", "good") end
cmdHandlers["piggyback"] = function(arg)
    local target = findPlr(arg); if not target then notify("Player not found", "bad"); return end
    _holdStart(target, "piggyback"); notify("Piggyback on " .. target.Name .. " — !unpiggy to stop", "good")
end
cmdHandlers["unpiggy"]     = function() _holdStop(); notify("Off back", "good") end
cmdHandlers["unpiggyback"] = cmdHandlers["unpiggy"]

-- ===== Timestop (admin/owner only) — freeze all other players locally =====
_G.__SeigeTimestop = _G.__SeigeTimestop or { on = false, anchored = {}, conn = nil }
local function _timestopRelease()
    local TS = _G.__SeigeTimestop
    for part, _ in pairs(TS.anchored) do
        if part and part.Parent then pcall(function() part.Anchored = false end) end
    end
    TS.anchored = {}
    if TS.conn then pcall(function() TS.conn:Disconnect() end); TS.conn = nil end
    TS.on = false
end
local function _timestopApply()
    local TS = _G.__SeigeTimestop
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            for _, d in ipairs(p.Character:GetDescendants()) do
                if d:IsA("BasePart") and not d.Anchored then
                    pcall(function() d.Anchored = true end)
                    TS.anchored[d] = true
                end
            end
        end
    end
end
cmdHandlers["timestop"] = function()
    if not (_G.__SeigeCan and _G.__SeigeCan("freeze")) then notify("Admin/owner only", "bad"); return end
    local TS = _G.__SeigeTimestop
    if TS.on then _timestopRelease(); notify("Time resumes", "good"); return end
    TS.on = true
    _timestopApply()
    -- re-apply on heartbeat so newly-spawned parts / respawns stay frozen
    TS.conn = RunService.Heartbeat:Connect(function()
        if not TS.on then return end
        _timestopApply()
    end)
    notify("Time stopped — !untimestop to release", "good")
end
cmdHandlers["untimestop"] = function() _timestopRelease(); notify("Time resumes", "good") end

-- !cir <player> — orbit the target. Adjustable radius/speed via panel.
_G.__SeigeCircle = _G.__SeigeCircle or { radius = 6, speed = 2, height = 0 }
function _seigeCircleStop()
    if _G.__CircleConn then pcall(function() _G.__CircleConn:Disconnect() end); _G.__CircleConn = nil end
    _G.__CircleTarget = nil
end
function _seigeCircleStart(target)
    _seigeCircleStop()
    _G.__CircleTarget = target
    local t0 = tick()
    _G.__CircleConn = RunService.Heartbeat:Connect(function()
        local tgt = _G.__CircleTarget
        if not tgt or not tgt.Parent then _seigeCircleStop(); return end
        local thrp = phrp(tgt); local me = hrp()
        if not (thrp and me) then return end
        local C = _G.__SeigeCircle
        local ang = (tick() - t0) * (C.speed or 2)
        local off = Vector3.new(math.cos(ang) * (C.radius or 6), C.height or 0, math.sin(ang) * (C.radius or 6))
        local pos = thrp.Position + off
        me.CFrame = CFrame.new(pos, thrp.Position)
    end)
end
cmdHandlers["cir"] = function(arg)
    if not arg or arg == "" then
        if _G.__CircleConn then _seigeCircleStop(); notify("Circle stopped", "good"); return end
        notify("!cir <player>", "warn"); return
    end
    local target = findPlr(arg)
    if not target then notify("Player not found", "bad"); return end
    _seigeCircleStart(target)
    notify("Circling " .. target.Name .. " (!uncir to stop)", "good")
end
cmdHandlers["circle"] = cmdHandlers["cir"]
cmdHandlers["uncir"] = function() _seigeCircleStop(); notify("Circle stopped", "good") end
cmdHandlers["uncircle"] = cmdHandlers["uncir"]

-- !stalk — opens a picker; "Listen" then tracks position + mic + chat for the target.
_G.__SeigeStalk = _G.__SeigeStalk or { target = nil, lastChat = "", chatConn = nil, conns = {}, gui = nil }
local function _seigeStalkStop()
    local S = _G.__SeigeStalk
    for _, c in ipairs(S.conns) do pcall(function() c:Disconnect() end) end
    S.conns = {}
    if S.chatConn then pcall(function() S.chatConn:Disconnect() end); S.chatConn = nil end
    if S.gui then pcall(function() S.gui:Destroy() end); S.gui = nil end
    if S.highlight then pcall(function() S.highlight:Destroy() end); S.highlight = nil end
    if S.target then
        local h = hum(); if h then Workspace.CurrentCamera.CameraSubject = h end
    end
    S.target, S.lastChat = nil, ""
end
local function _seigeStalkStart(target)
    _seigeStalkStop()
    local S = _G.__SeigeStalk
    S.target = target
    S.lastChat = ""
    -- Listen for chat
    S.chatConn = target.Chatted:Connect(function(msg) S.lastChat = msg end)
    -- ESP highlight
    local ch = target.Character
    if ch then
        local hl = Instance.new("Highlight")
        hl.Name = "__SeigeStalkHL"
        hl.FillColor = Color3.fromRGB(255, 80, 80)
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.FillTransparency = 0.6
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Adornee = ch
        hl.Parent = ch
        S.highlight = hl
    end
    -- Spectate camera
    do
        local c = target.Character
        local h = c and c:FindFirstChildOfClass("Humanoid")
        if h then Workspace.CurrentCamera.CameraSubject = h end
    end
    -- HUD
    local gui = inst("ScreenGui", nil, {
        Name = "SeigeStalkHUD", IgnoreGuiInset = true, ResetOnSpawn = false,
        DisplayOrder = 230, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    safeParent(gui); S.gui = gui
    local win = inst("Frame", gui, {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -14, 0, 80),
        Size = UDim2.new(0, 280, 0, 150),
        BackgroundColor3 = T.bg, BorderSizePixel = 0,
    })
    corner(win, 10); stroke(win, T.line, 1, 0.3)
    local bar = inst("Frame", win, {
        Size = UDim2.new(1, 0, 0, 26), BackgroundColor3 = T.bg2, BorderSizePixel = 0,
    })
    corner(bar, 10)
    inst("TextLabel", bar, {
        BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -40, 1, 0), Font = Enum.Font.GothamBold, TextSize = 12,
        TextColor3 = T.text, TextXAlignment = Enum.TextXAlignment.Left,
        Text = "🔍 Stalking @" .. target.Name,
    })
    local close = inst("TextButton", bar, {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0),
        Size = UDim2.new(0, 20, 0, 20), BackgroundColor3 = T.bg3, BorderSizePixel = 0,
        Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = T.text, Text = "✕",
    })
    corner(close, 5)
    close.MouseButton1Click:Connect(function() _seigeStalkStop(); notify("Stalk stopped", "good") end)
    local function mkLine(y, label)
        local f = inst("TextLabel", win, {
            BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, y),
            Size = UDim2.new(1, -20, 0, 18), Font = Enum.Font.Gotham, TextSize = 12,
            TextColor3 = T.sub, TextXAlignment = Enum.TextXAlignment.Left,
            Text = label, TextWrapped = false, TextTruncate = Enum.TextTruncate.AtEnd,
        })
        return f
    end
    local lblPos  = mkLine(32, "Position: —")
    local lblDist = mkLine(52, "Distance: —")
    local lblMic  = mkLine(72, "🎤 Mic: idle")
    local lblChat = inst("TextLabel", win, {
        BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 94),
        Size = UDim2.new(1, -20, 0, 50), Font = Enum.Font.Gotham, TextSize = 12,
        TextColor3 = T.text, TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true,
        Text = "💬 (no chat yet)",
    })
    -- drag bar
    do
        local dragging, sp, sm
        bar.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                dragging = true; sp = win.Position; sm = i.Position
            end
        end)
        UIS.InputChanged:Connect(function(i)
            if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                local d = i.Position - sm
                win.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
            end
        end)
        UIS.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
        end)
    end
    -- Detect "speaking": look for a playing Sound in the player's character (VoiceChat sounds).
    local function isSpeaking(tc)
        if not tc then return false end
        for _, d in ipairs(tc:GetDescendants()) do
            if d:IsA("Sound") and d.IsPlaying and d.Playing then
                local nm = (d.Name or ""):lower()
                if nm:find("voice") or nm == "" or d.SoundId == "" then return true end
            end
        end
        return false
    end
    table.insert(S.conns, RunService.Heartbeat:Connect(function()
        local t = S.target
        if not t or not t.Parent then _seigeStalkStop(); return end
        local tc = t.Character
        local thrp = tc and tc:FindFirstChild("HumanoidRootPart")
        if thrp then
            local p = thrp.Position
            lblPos.Text = string.format("Position: %d, %d, %d", math.floor(p.X), math.floor(p.Y), math.floor(p.Z))
            local me = hrp()
            if me then
                lblDist.Text = string.format("Distance: %d studs", math.floor((me.Position - p).Magnitude))
            end
        end
        if isSpeaking(tc) then
            lblMic.Text = "🎤 Mic: SPEAKING"
            lblMic.TextColor3 = T.good or Color3.fromRGB(120, 240, 140)
        else
            lblMic.Text = "🎤 Mic: idle"
            lblMic.TextColor3 = T.sub
        end
        lblChat.Text = (S.lastChat ~= "" and ("💬 " .. S.lastChat)) or "💬 (no chat yet)"
    end))
end

local function _openStalkPanel()
    _openPanel("stalk", "Stalk  ·  pick a player to listen to", 360, function(body)
        local scroll = inst("ScrollingFrame", body, {
            Size = UDim2.new(1, 0, 0, 220), BackgroundColor3 = T.bg2, BorderSizePixel = 0,
            CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 4, ScrollBarImageColor3 = T.line,
        })
        corner(scroll, 6)
        inst("UIListLayout", scroll, { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder })
        inst("UIPadding", scroll, { PaddingTop = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4) })
        local selected
        local statusLbl = inst("TextLabel", body, {
            BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 16),
            Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = T.sub,
            TextXAlignment = Enum.TextXAlignment.Left, Text = "  Pick a player, then click Listen.",
        })
        local rowsByPlr = {}
        local function refresh()
            for _, c in ipairs(scroll:GetChildren()) do
                if c:IsA("TextButton") then c:Destroy() end
            end
            rowsByPlr = {}
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LP then
                    local btn = inst("TextButton", scroll, {
                        Size = UDim2.new(1, -8, 0, 24), BackgroundColor3 = T.bg3, BorderSizePixel = 0,
                        Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = T.text,
                        Text = "  @" .. p.Name .. "  (" .. (p.DisplayName or p.Name) .. ")",
                        TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false,
                    })
                    corner(btn, 4)
                    rowsByPlr[p] = btn
                    btn.MouseButton1Click:Connect(function()
                        selected = p
                        for op, ob in pairs(rowsByPlr) do
                            ob.BackgroundColor3 = (op == p) and (T.accent or Color3.fromRGB(80, 140, 255)) or T.bg3
                        end
                        statusLbl.Text = "  Selected: @" .. p.Name
                    end)
                end
            end
        end
        refresh()
        button(body, "Refresh list", refresh)
        button(body, "🔍 Listen", function()
            if not selected or not selected.Parent then notify("Pick a player first", "warn"); return end
            _seigeStalkStart(selected)
            notify("Stalking @" .. selected.Name, "good")
        end)
        button(body, "Stop stalking (!unstalk)", function()
            _seigeStalkStop(); notify("Stalk stopped", "good")
        end)
    end)
end

cmdHandlers["stalk"] = function(arg)
    if arg and arg ~= "" then
        local target = findPlr(arg)
        if not target then notify("Player not found", "bad"); return end
        _seigeStalkStart(target)
        notify("Stalking @" .. target.Name, "good")
    else
        _openStalkPanel()
    end
end
cmdHandlers["unstalk"] = function() _seigeStalkStop(); notify("Stalk stopped", "good") end


-- ---------- extended chat commands ----------
function getHum()
    local c = LP.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

cmdHandlers["r"] = cmdHandlers["rj"]
cmdHandlers["rejoin"] = cmdHandlers["rj"]

cmdHandlers["reset"] = function()
    local h = getHum(); if h then h.Health = 0; notify("Reset", "good") else notify("No humanoid", "bad") end
end
cmdHandlers["respawn"] = cmdHandlers["reset"]

cmdHandlers["ws"] = function(arg)
    local n = tonumber(arg) or 16
    local h = getHum(); if not h then notify("No humanoid", "bad"); return end
    h.WalkSpeed = math.clamp(n, 0, 500); notify("WalkSpeed " .. h.WalkSpeed, "good")
end
cmdHandlers["speed"] = cmdHandlers["ws"]

cmdHandlers["jp"] = function(arg)
    local n = tonumber(arg) or 50
    local h = getHum(); if not h then notify("No humanoid", "bad"); return end
    h.JumpPower = math.clamp(n, 0, 1000)
    h.UseJumpPower = true
    notify("JumpPower " .. h.JumpPower, "good")
end
cmdHandlers["jump"] = function()
    local h = getHum(); if h then h.Jump = true; notify("Jump", "good") end
end

cmdHandlers["heal"] = function()
    local h = getHum(); if h then h.Health = h.MaxHealth; notify("Healed", "good") end
end

cmdHandlers["god"] = function()
    if _G.__GodConn then notify("God already on (!ungod)", "warn"); return end
    _G.__GodConn = RunService.Heartbeat:Connect(function()
        local h = getHum(); if h and h.Health < h.MaxHealth then h.Health = h.MaxHealth end
    end)
    notify("God ON", "good")
end
cmdHandlers["ungod"] = function()
    if _G.__GodConn then _G.__GodConn:Disconnect(); _G.__GodConn = nil; notify("God OFF", "warn") end
end

cmdHandlers["noclip"] = function()
    if _G.__NoclipConn then notify("Noclip already on", "warn"); return end
    _G.__NoclipConn = RunService.Stepped:Connect(function()
        local c = LP.Character; if not c then return end
        for _, part in ipairs(c:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
        end
    end)
    notify("Noclip ON", "good")
end
cmdHandlers["clip"] = function()
    if _G.__NoclipConn then _G.__NoclipConn:Disconnect(); _G.__NoclipConn = nil; notify("Noclip OFF", "warn") end
end

cmdHandlers["fly"] = function(arg)
    if _G.__FlyConn then notify("Fly already on (!unfly)", "warn"); return end
    local hrpPart = hrp(); local h = getHum()
    if not (hrpPart and h) then notify("No character", "bad"); return end
    local spd = tonumber(arg) or 80
    local bv = Instance.new("BodyVelocity"); bv.MaxForce = Vector3.new(1e9,1e9,1e9); bv.Velocity = Vector3.zero; bv.Parent = hrpPart
    local bg = Instance.new("BodyGyro"); bg.MaxTorque = Vector3.new(1e9,1e9,1e9); bg.P = 1e5; bg.CFrame = hrpPart.CFrame; bg.Parent = hrpPart
    _G.__FlyBV, _G.__FlyBG = bv, bg
    local UIS = game:GetService("UserInputService")
    _G.__FlyConn = RunService.RenderStepped:Connect(function()
        local cam = Workspace.CurrentCamera; if not cam then return end
        local dir = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0,1,0) end
        bv.Velocity = dir * spd
        bg.CFrame = cam.CFrame
    end)
    notify("Fly ON (WASD/Space/Ctrl) @ " .. spd, "good")
end
cmdHandlers["unfly"] = function()
    if _G.__FlyConn then _G.__FlyConn:Disconnect(); _G.__FlyConn = nil end
    if _G.__FlyBV then _G.__FlyBV:Destroy(); _G.__FlyBV = nil end
    if _G.__FlyBG then _G.__FlyBG:Destroy(); _G.__FlyBG = nil end
    notify("Fly OFF", "warn")
end

cmdHandlers["goto"] = function(arg)
    local target = findPlr(arg); if not target then notify("Player not found", "bad"); return end
    local thrp, myH = phrp(target), hrp()
    if not (thrp and myH) then notify("No character", "bad"); return end
    myH.CFrame = thrp.CFrame * CFrame.new(0,0,3); notify("Teleported to " .. target.Name, "good")
end
cmdHandlers["tp"] = cmdHandlers["goto"]

cmdHandlers["to"] = function(arg)
    local target = findPlr(arg); if not target then notify("Player not found", "bad"); return end
    local thrp, myH = phrp(target), hrp()
    if not (thrp and myH) then notify("No character", "bad"); return end
    myH.CFrame = thrp.CFrame * CFrame.new(0,0,3); notify("Teleported to " .. target.Name, "good")
end

cmdHandlers["spectate"] = function(arg)
    local target = findPlr(arg); if not target then notify("Player not found", "bad"); return end
    if _G.__SeigeStartSpectate then
        _G.__SeigeStartSpectate(target)
    else
        local c = target.Character; local h = c and c:FindFirstChildOfClass("Humanoid")
        if not h then notify("No target humanoid", "bad"); return end
        Workspace.CurrentCamera.CameraSubject = h
    end
    notify("Spectating " .. target.Name, "good")
end
cmdHandlers["unspectate"] = function()
    if _G.__SeigeStopSpectate then _G.__SeigeStopSpectate() end
    local h = getHum(); if h then Workspace.CurrentCamera.CameraSubject = h end
    notify("Unspectated", "good")
end


-- !fling — works on R15 by abusing collision momentum transfer.
-- You can't directly mutate another player's body (no network ownership), so
-- we crank our OWN HumanoidRootPart's velocity to extreme values and ram
-- it into the target. Roblox replicates OUR velocity (we own ourselves) and
-- the physical collision flings the target.
cmdHandlers["fling"] = function(arg)
    local target = findPlr(arg); if not target then notify("Player not found", "bad"); return end
    local tchar = target.Character
    local thrp = tchar and (tchar:FindFirstChild("HumanoidRootPart") or tchar:FindFirstChild("Torso") or tchar:FindFirstChild("UpperTorso"))
    local mychar = LP.Character
    local myH = mychar and mychar:FindFirstChild("HumanoidRootPart")
    local myHum = mychar and mychar:FindFirstChildOfClass("Humanoid")
    if not (thrp and myH and myHum) then notify("Missing character", "bad"); return end

    notify("Flinging " .. target.Name .. "...", "good")
    task.spawn(function()
        -- Save state to restore after
        local savedCF        = myH.CFrame
        local savedAutoRot   = myHum.AutoRotate
        local savedWalkSpeed = myHum.WalkSpeed
        local savedJump      = myHum.JumpPower

        myHum.AutoRotate = false
        myHum.WalkSpeed  = 0
        myHum.JumpPower  = 0
        myHum.PlatformStand = true

        -- Massive angular velocity makes the HRP spin & generate collision impulse
        local bav = Instance.new("BodyAngularVelocity")
        bav.AngularVelocity = Vector3.new(0, 1e9, 0)
        bav.MaxTorque       = Vector3.new(math.huge, math.huge, math.huge)
        bav.P               = math.huge
        bav.Parent          = myH

        -- Hold us in space so we don't fly away; the spinning + offset does the flinging
        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bv.Velocity = Vector3.new(0, 0, 0)
        bv.Parent   = myH

        -- Boost assembly velocity for extra punch (some games use it directly)
        pcall(function()
            myH.AssemblyLinearVelocity  = Vector3.new(9e4, 9e4, 9e4)
            myH.AssemblyAngularVelocity = Vector3.new(9e4, 9e4, 9e4)
        end)

        -- Ram into the target from multiple offsets so collision lands on R15 limbs
        local OFFSETS = {
            Vector3.new(0,  0,    0),
            Vector3.new(0,  0.5,  0),
            Vector3.new(0, -0.5,  0),
            Vector3.new(0.5, 0,   0),
            Vector3.new(-0.5, 0,  0),
        }
        local startT = tick()
        local i = 1
        while tick() - startT < 0.45 do
            local tc = target.Character
            local th = tc and (tc:FindFirstChild("HumanoidRootPart") or tc:FindFirstChild("UpperTorso") or tc:FindFirstChild("Torso"))
            if not th then break end
            local off = OFFSETS[((i - 1) % #OFFSETS) + 1]
            pcall(function()
                myH.CFrame = th.CFrame * CFrame.new(off)
                myH.AssemblyLinearVelocity  = Vector3.new(9e4, 9e4, 9e4)
                myH.AssemblyAngularVelocity = Vector3.new(9e4, 9e4, 9e4)
            end)
            i = i + 1
            RunService.Heartbeat:Wait()
        end

        -- Clean up
        pcall(function() bav:Destroy() end)
        pcall(function() bv:Destroy() end)
        if myHum and myHum.Parent then
            myHum.PlatformStand = false
            myHum.AutoRotate    = savedAutoRot
            myHum.WalkSpeed     = savedWalkSpeed
            myHum.JumpPower     = savedJump
        end
        if myH and myH.Parent then
            pcall(function()
                myH.AssemblyLinearVelocity  = Vector3.zero
                myH.AssemblyAngularVelocity = Vector3.zero
                myH.CFrame = savedCF
            end)
        end
        notify("Fling done", "good")
    end)
end


cmdHandlers["bring"] = function(arg)
    local target = findPlr(arg); if not target then notify("Player not found", "bad"); return end
    local thrp, myH = phrp(target), hrp()
    if not (thrp and myH) then notify("Missing character", "bad"); return end
    notify("Bringing " .. target.Name .. " (freeze + rubber-band back)...", "good")
    task.spawn(function()
        -- Snapshot the bring spot relative to our HRP at the moment of the command
        -- so the target keeps freezing at THAT spot even if we move afterwards.
        local bringCF = myH.CFrame + Vector3.new(0, 3, 0)
        -- Hold them in place. We do NOT manually teleport them back — Roblox's
        -- server-side movement validation remembers their last legitimate
        -- position and will rubber-band them home once we stop writing CFrame.
        local FREEZE_TIME = 2.0
        local STEP = 0.04
        local steps = math.floor(FREEZE_TIME / STEP)
        for i = 1, steps do
            local t = phrp(target); if not t then break end
            pcall(function()
                t.CFrame = bringCF
                t.AssemblyLinearVelocity  = Vector3.zero
                t.AssemblyAngularVelocity = Vector3.zero
            end)
            task.wait(STEP)
        end
        -- Optional tool-touch pass during the freeze window (kept from old logic)
        local tool = LP.Backpack:FindFirstChildOfClass("Tool")
            or (LP.Character and LP.Character:FindFirstChildOfClass("Tool"))
        if tool and tool:FindFirstChild("Handle") and typeof(firetouchinterest) == "function" then
            pcall(function()
                tool.Parent = LP.Character
                for i = 1, 12 do
                    local t = phrp(target); if not t then break end
                    pcall(function() firetouchinterest(tool.Handle, t, 0) end); task.wait()
                    pcall(function() firetouchinterest(tool.Handle, t, 1) end); task.wait(0.04)
                end
            end)
        end
        -- Stop writing — Roblox will snap the target back to their server-side
        -- remembered position on its own.
        notify(target.Name .. " released — Roblox will rubber-band them back", "good")
    end)
end
end)()

-- ================================================================
-- Reanim: free the humanoid from default animations and play custom
-- Animation assets or KeyframeSequences on it. Works on R6 and R15.
-- Disables the default "Animate" LocalScript so idle/walk/jump don't
-- override your custom anims. Animations played on the real humanoid
-- replicate to other players.
--
-- !reanim                -> enable reanim (kills default animate)
-- !reanim <id> [speed]   -> play Animation/KeyframeSequence asset id
-- !reanim stop / !unreanim -> stop tracks AND restore default animate
-- ================================================================
_G.__ReanimTracks   = _G.__ReanimTracks   or {}
_G.__ReanimAnimateSrc = _G.__ReanimAnimateSrc or nil   -- saved clone of Animate

local function stopAllReanimTracks()
    for _, tr in ipairs(_G.__ReanimTracks) do pcall(function() tr:Stop(0); tr:Destroy() end) end
    _G.__ReanimTracks = {}
    local h = getHum()
    if h then
        local animator = h:FindFirstChildOfClass("Animator")
        if animator then
            for _, t in ipairs(animator:GetPlayingAnimationTracks()) do pcall(function() t:Stop(0) end) end
        end
        pcall(function()
            for _, t in ipairs(h:GetPlayingAnimationTracks()) do pcall(function() t:Stop(0) end) end
        end)
    end
end

-- Strip the default Animate localscript so it stops overriding tracks
local function killDefaultAnimate(char)
    if not char then return end
    local a = char:FindFirstChild("Animate")
    if a then
        if not _G.__ReanimAnimateSrc then
            pcall(function() a.Archivable = true; _G.__ReanimAnimateSrc = a:Clone() end)
        end
        pcall(function() a.Disabled = true end)
        pcall(function() a:Destroy() end)
    end
    -- stop any leftover playing tracks (idle/walk/jump)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        local animator = hum:FindFirstChildOfClass("Animator")
        if animator then
            for _, t in ipairs(animator:GetPlayingAnimationTracks()) do pcall(function() t:Stop(0) end) end
        end
    end
end

local function restoreDefaultAnimate(char)
    if not char or not _G.__ReanimAnimateSrc then return end
    if char:FindFirstChild("Animate") then return end
    local clone = _G.__ReanimAnimateSrc:Clone()
    clone.Disabled = false
    clone.Parent = char
end

local function startReanim()
    if _G.__ReanimActive then notify("Reanim already on", "warn"); return end
    local char = LP.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if not (char and hum) then notify("No character", "bad"); return end

    pcall(function() hum.BreakJointsOnDeath = false end)
    -- Ensure an Animator exists (needed in some games)
    if not hum:FindFirstChildOfClass("Animator") then
        pcall(function() Instance.new("Animator", hum) end)
    end
    killDefaultAnimate(char)

    -- Re-strip Animate every respawn while reanim is on
    if not _G.__ReanimRespawnConn then
        _G.__ReanimRespawnConn = LP.CharacterAdded:Connect(function(c)
            if not _G.__ReanimActive then return end
            task.wait(0.4)
            local h = c:FindFirstChildOfClass("Humanoid")
            if h and not h:FindFirstChildOfClass("Animator") then
                pcall(function() Instance.new("Animator", h) end)
            end
            killDefaultAnimate(c)
        end)
    end

    _G.__ReanimActive = true
    notify("Reanim ON — humanoid freed. Play with !reanim <id>", "good")
end

_G.__StopReanim = function()
    if not _G.__ReanimActive then
        stopAllReanimTracks(); return
    end
    _G.__ReanimActive = false
    stopAllReanimTracks()
    if _G.__ReanimRespawnConn then
        pcall(function() _G.__ReanimRespawnConn:Disconnect() end)
        _G.__ReanimRespawnConn = nil
    end
    restoreDefaultAnimate(LP.Character)
    notify("Reanim OFF", "good")
end

-- Resolve "id" or "rbxassetid://id" or full asset URL
local function resolveAssetId(s)
    if not s then return nil end
    local n = s:match("(%d+)")
    return n and ("rbxassetid://" .. n) or nil
end

local function playAnimId(arg)
    arg = (arg or ""):gsub("^%s+",""):gsub("%s+$","")
    local idPart, rest = arg:match("^(%S+)%s*(.*)$")
    local speed = tonumber(rest) or 1
    local assetUri = resolveAssetId(idPart or "")
    if not assetUri then notify("Bad anim id", "bad"); return end
    local hum = getHum(); if not hum then notify("No humanoid", "bad"); return end

    -- Auto-enable reanim so the default Animate script doesn't fight us
    if not _G.__ReanimActive then startReanim() end

    -- Ensure animator
    local animator = hum:FindFirstChildOfClass("Animator")
    if not animator then
        pcall(function() animator = Instance.new("Animator", hum) end)
        animator = hum:FindFirstChildOfClass("Animator")
    end

    local function loadAndPlay(animationId)
        local anim = Instance.new("Animation"); anim.AnimationId = animationId
        local track = animator and animator:LoadAnimation(anim) or hum:LoadAnimation(anim)
        track.Priority = Enum.AnimationPriority.Action4 or Enum.AnimationPriority.Action
        track.Looped = true
        track:Play(0)
        track:AdjustSpeed(speed)
        return track
    end

    -- 1) Try as a regular Animation asset
    local ok, track = pcall(loadAndPlay, assetUri)
    if ok and typeof(track) == "Instance" then
        table.insert(_G.__ReanimTracks, track)
        notify("Playing " .. assetUri .. " @x" .. speed, "good"); return
    end

    -- 2) Fallback: load asset as KeyframeSequence, register, then play
    local idNum = tonumber(assetUri:match("(%d+)"))
    local ksOk, ks = pcall(function()
        if typeof(getobjects) == "function" then
            local o = getobjects(assetUri); return o and o[1]
        elseif typeof(GetObjects) == "function" then
            local o = GetObjects(assetUri); return o and o[1]
        else
            local m = game:GetService("InsertService"):LoadAsset(idNum)
            return m and m:FindFirstChildOfClass("KeyframeSequence", true)
        end
    end)
    if ksOk and ks and ks:IsA("KeyframeSequence") then
        local regOk, hash = pcall(function()
            return game:GetService("KeyframeSequenceProvider"):RegisterKeyframeSequence(ks)
        end)
        if regOk and hash then
            local ok2, tr = pcall(loadAndPlay, hash)
            if ok2 and typeof(tr) == "Instance" then
                table.insert(_G.__ReanimTracks, tr)
                notify("Playing KFS " .. idNum .. " @x" .. speed, "good"); return
            end
        end
    end
    notify("Play failed: " .. tostring(track), "bad")
end

;(function()  -- scope new keyframe-data locals to a separate function (Lua main chunk has a 200-locals cap)

-- ================================================================
-- Parse raw keyframe data (JSON or Lua table) and play it as an animation.
-- Accepted JSON shape:
--   { "loop": true, "priority": "Action", "keyframes": [
--       { "time": 0,
--         "poses": {
--           "Torso":      { "cf": [x,y,z,r00,...,r22], "ease": "Linear", "style": "Sine" },
--           "Left Arm":   { "cf": [...], "weight": 1, "easeDirection": "In" }
--         }
--       },
--       { "time": 0.5, "poses": { ... } }
--     ]
--   }
-- Accepted Lua shape (returned from `loadstring(data)()`):
--   { Loop = true, Priority = "Action", Frames = { { Time=0, Poses={...} } } }
-- Or Roblox Animation Editor export tables (table.insert(Frames, {...})).
-- ================================================================

local HS = game:GetService("HttpService")

local EASE_STYLE = {
    Linear = Enum.PoseEasingStyle.Linear,
    Constant = Enum.PoseEasingStyle.Constant,
    Elastic = Enum.PoseEasingStyle.Elastic,
    Cubic = Enum.PoseEasingStyle.Cubic,
    Bounce = Enum.PoseEasingStyle.Bounce,
    Sine = Enum.PoseEasingStyle.Linear, -- not a valid pose style, alias
}
local EASE_DIR = {
    In = Enum.PoseEasingDirection.In,
    Out = Enum.PoseEasingDirection.Out,
    InOut = Enum.PoseEasingDirection.InOut,
}

-- Recursively build Pose hierarchy onto a parent (Keyframe or Pose)
local function buildPoses(parent, posesTbl, char)
    if type(posesTbl) ~= "table" then return end
    -- posesTbl can be either a dict (name -> data) or a list of {Name=..., ...}
    local items = {}
    if posesTbl[1] then
        for _, v in ipairs(posesTbl) do items[#items+1] = { name = v.Name or v.name, data = v } end
    else
        for k, v in pairs(posesTbl) do items[#items+1] = { name = k, data = v } end
    end
    for _, it in ipairs(items) do
        local data = it.data
        local pose = Instance.new("Pose")
        pose.Name = it.name
        local cf = data.cf or data.CFrame or data.CF
        if type(cf) == "table" and #cf >= 12 then
            pose.CFrame = CFrame.new(unpack(cf, 1, 12))
        elseif type(cf) == "table" and #cf == 7 then
            -- pos + quaternion
            pose.CFrame = CFrame.new(cf[1], cf[2], cf[3]) * CFrame.fromEulerAnglesXYZ(cf[5], cf[6], cf[7])
        end
        pose.Weight = tonumber(data.weight or data.Weight) or 1
        local es = data.style or data.Style or data.ease or data.Ease
        if es and EASE_STYLE[es] then pose.EasingStyle = EASE_STYLE[es] end
        local ed = data.easeDirection or data.EasingDirection
        if ed and EASE_DIR[ed] then pose.EasingDirection = EASE_DIR[ed] end
        pose.Parent = parent
        if data.poses or data.Poses or data.Children then
            buildPoses(pose, data.poses or data.Poses or data.Children, char)
        end
    end
end

-- Build a KeyframeSequence from a parsed data table
local function buildKeyframeSequence(data)
    local ks = Instance.new("KeyframeSequence")
    ks.Loop     = data.loop or data.Loop or false
    ks.Priority = Enum.AnimationPriority[data.priority or data.Priority or "Action"] or Enum.AnimationPriority.Action
    local frames = data.keyframes or data.Keyframes or data.Frames or data.frames or {}
    for _, fr in ipairs(frames) do
        local kf = Instance.new("Keyframe")
        kf.Time = tonumber(fr.time or fr.Time) or 0
        kf.Name = fr.name or fr.Name or ("Keyframe_" .. kf.Time)
        local poses = fr.poses or fr.Poses
        if poses then
            -- If the format puts a single root pose (e.g. "HumanoidRootPart") at top,
            -- parent it directly; otherwise wrap under a root pose.
            local hasRoot = poses["HumanoidRootPart"] or poses.HumanoidRootPart
            if hasRoot then
                buildPoses(kf, poses, LP.Character)
            else
                local root = Instance.new("Pose")
                root.Name = "HumanoidRootPart"
                root.Weight = 0
                root.Parent = kf
                buildPoses(root, poses, LP.Character)
            end
        end
        kf.Parent = ks
    end
    return ks
end

local function parseAnimData(raw)
    if type(raw) ~= "string" or raw == "" then return nil, "empty" end
    -- 1) JSON
    local ok, j = pcall(function() return HS:JSONDecode(raw) end)
    if ok and type(j) == "table" then return j end
    -- 2) Lua expression that returns a table
    local fn, err = loadstring("return " .. raw)
    if fn then
        local ok2, t = pcall(fn)
        if ok2 and type(t) == "table" then return t end
    end
    -- 3) Lua statement block that defines `Frames`
    local fn2, err2 = loadstring(raw .. "\nreturn { Frames = Frames or frames, Loop = Loop, Priority = Priority }")
    if fn2 then
        local ok3, t = pcall(fn2)
        if ok3 and type(t) == "table" and t.Frames then return t end
    end
    return nil, "parse failed (" .. tostring(err or err2) .. ")"
end

local function playKeyframeData(raw, speed)
    speed = tonumber(speed) or 1
    local data, perr = parseAnimData(raw)
    if not data then notify("Anim parse error: " .. tostring(perr), "bad"); return end
    if not _G.__ReanimActive then startReanim() end
    local hum = getHum(); if not hum then notify("No humanoid", "bad"); return end
    local ks = buildKeyframeSequence(data)
    local okReg, hash = pcall(function()
        return game:GetService("KeyframeSequenceProvider"):RegisterKeyframeSequence(ks)
    end)
    if not okReg or not hash then notify("Register KFS failed: " .. tostring(hash), "bad"); return end
    local anim = Instance.new("Animation"); anim.AnimationId = hash
    local animator = hum:FindFirstChildOfClass("Animator")
    local track = animator and animator:LoadAnimation(anim) or hum:LoadAnimation(anim)
    track.Priority = Enum.AnimationPriority.Action4 or Enum.AnimationPriority.Action
    track.Looped = ks.Loop
    track:Play(0); track:AdjustSpeed(speed)
    table.insert(_G.__ReanimTracks, track)
    notify("Playing custom keyframes  ·  " .. #ks:GetChildren() .. " frame(s)", "good")
end

-- !reanim url <link> [speed]   → HttpGet raw txt/json and play
cmdHandlers["reanimurl"] = function(arg)
    arg = (arg or ""):gsub("^%s+",""):gsub("%s+$","")
    local url, sp = arg:match("^(%S+)%s*(.*)$")
    if not url then notify("Usage: !reanimurl <link> [speed]", "warn"); return end
    notify("Fetching " .. url, "good")
    task.spawn(function()
        local ok, raw = pcall(function() return game:HttpGet(url, true) end)
        if not ok then ok, raw = pcall(function() return game:HttpGet(url) end) end
        if not ok or type(raw) ~= "string" then notify("Fetch failed", "bad"); return end
        playKeyframeData(raw, tonumber(sp))
    end)
end

-- !reanimdata <raw>            → parse + play raw json/lua text (used by paste UI)
cmdHandlers["reanimdata"] = function(arg) playKeyframeData(arg or "", 1) end

_G.__PlayReanimText = playKeyframeData -- expose to the popout's "Play" button
end)()  -- end keyframe-data scope

cmdHandlers["reanim"] = function(arg)
    arg = (arg or ""):gsub("^%s+",""):gsub("%s+$","")
    if arg == "" or arg == "on" or arg == "start" then startReanim(); return end
    if arg == "stop" or arg == "off" then _G.__StopReanim(); return end
    playAnimId(arg)
end
cmdHandlers["anim"]     = function(arg) playAnimId(arg or "") end
cmdHandlers["unreanim"] = function() _G.__StopReanim() end
cmdHandlers["stopanim"] = function() stopAllReanimTracks(); notify("Tracks stopped", "good") end

-- ================================================================
-- New utility commands
-- ================================================================

-- 1) ESP — highlight every player through walls
cmdHandlers["esp"] = function()
    if _G.__ESPOn then
        _G.__ESPOn = false
        for _, p in ipairs(Players:GetPlayers()) do
            local c = p.Character; if c then
                local h = c:FindFirstChild("SeigeESP"); if h then h:Destroy() end
            end
        end
        notify("ESP OFF", "warn"); return
    end
    _G.__ESPOn = true
    local function applyESP(p)
        if p == LP then return end
        local c = p.Character; if not c or c:FindFirstChild("SeigeESP") then return end
        local hi = Instance.new("Highlight")
        hi.Name = "SeigeESP"
        hi.FillColor = Color3.fromRGB(120, 180, 255)
        hi.OutlineColor = Color3.fromRGB(255, 255, 255)
        hi.FillTransparency = 0.6
        hi.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hi.Parent = c
    end
    for _, p in ipairs(Players:GetPlayers()) do applyESP(p) end
    if not _G.__ESPConns then _G.__ESPConns = {} end
    table.insert(_G.__ESPConns, Players.PlayerAdded:Connect(function(p)
        p.CharacterAdded:Connect(function() task.wait(0.4); if _G.__ESPOn then applyESP(p) end end)
    end))
    for _, p in ipairs(Players:GetPlayers()) do
        table.insert(_G.__ESPConns, p.CharacterAdded:Connect(function()
            task.wait(0.4); if _G.__ESPOn then applyESP(p) end
        end))
    end
    notify("ESP ON", "good")
end
cmdHandlers["unesp"] = cmdHandlers["esp"]

-- 2) Fullbright — flat max ambient lighting
cmdHandlers["fullbright"] = function()
    local L = game:GetService("Lighting")
    if _G.__FB then
        for k, v in pairs(_G.__FB) do pcall(function() L[k] = v end) end
        _G.__FB = nil; notify("Fullbright OFF", "warn"); return
    end
    _G.__FB = {
        Ambient = L.Ambient, OutdoorAmbient = L.OutdoorAmbient,
        Brightness = L.Brightness, FogEnd = L.FogEnd, ClockTime = L.ClockTime,
        GlobalShadows = L.GlobalShadows,
    }
    pcall(function()
        L.Ambient = Color3.fromRGB(178, 178, 178)
        L.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
        L.Brightness = 2; L.FogEnd = 1e10; L.ClockTime = 14
        L.GlobalShadows = false
    end)
    notify("Fullbright ON", "good")
end
cmdHandlers["fb"] = cmdHandlers["fullbright"]

-- 3) Time of day
cmdHandlers["time"] = function(arg)
    local n = tonumber(arg); if not n then notify("Usage: !time 0-24", "warn"); return end
    pcall(function() game:GetService("Lighting").ClockTime = n end); notify("Time " .. n, "good")
end
cmdHandlers["day"]   = function() pcall(function() game:GetService("Lighting").ClockTime = 14 end); notify("Day", "good") end
cmdHandlers["night"] = function() pcall(function() game:GetService("Lighting").ClockTime = 0 end);  notify("Night", "good") end

-- 4) Invisible — hide your character locally (transparent + can't be seen by camera)
cmdHandlers["invis"] = function()
    local c = LP.Character; if not c then notify("No character", "bad"); return end
    applyInvisState(not _G.__InvisOn)
    notify(_G.__InvisOn and "Invisible (local)" or "Visible", "good")
end
cmdHandlers["visible"] = cmdHandlers["invis"]

-- 5) Hat fling — spin and orbit accessories to fling nearby players
cmdHandlers["hatspin"] = function()
    local c = LP.Character; local h = c and c:FindFirstChildOfClass("Humanoid")
    if not (c and h) then notify("No character", "bad"); return end
    for _, acc in ipairs(c:GetChildren()) do
        if acc:IsA("Accessory") then
            local handle = acc:FindFirstChild("Handle")
            if handle then
                pcall(function()
                    for _, w in ipairs(handle:GetChildren()) do
                        if w:IsA("Weld") or w:IsA("Motor6D") then w:Destroy() end
                    end
                    handle.CanCollide = true; handle.Massless = true
                    local bp = Instance.new("BodyAngularVelocity", handle)
                    bp.AngularVelocity = Vector3.new(0, 1000, 0)
                    bp.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
                end)
            end
        end
    end
    notify("Hat spin", "good")
end

-- 6) Size — scale your character
cmdHandlers["size"] = function(arg)
    local n = tonumber(arg) or 1
    local h = getHum(); if not h then notify("No humanoid", "bad"); return end
    for _, k in ipairs({"BodyDepthScale","BodyHeightScale","BodyWidthScale","HeadScale"}) do
        local v = h:FindFirstChild(k); if v then pcall(function() v.Value = n end) end
    end
    notify("Size " .. n, "good")
end

-- 7) Ghost — transparent + noclip + no collide
cmdHandlers["ghost"] = function()
    _G.__GhostOn = not _G.__GhostOn
    local c = LP.Character; if not c then notify("No character", "bad"); return end
    for _, d in ipairs(c:GetDescendants()) do
        if d:IsA("BasePart") then
            pcall(function()
                d.LocalTransparencyModifier = _G.__GhostOn and 0.7 or 0
                d.CanCollide = not _G.__GhostOn
            end)
        end
    end
    if _G.__GhostOn then
        noclip = true
    else
        noclip = false
    end
    notify(_G.__GhostOn and "Ghost mode" or "Ghost off", "good")
end

-- 8) Freecam — detach camera (WASD + mouse)
cmdHandlers["freecam"] = function()
    if _G.__FreecamOn then
        _G.__FreecamOn = false
        if _G.__FCConn then _G.__FCConn:Disconnect(); _G.__FCConn = nil end
        cam.CameraType = Enum.CameraType.Custom
        local h = hum(); if h then cam.CameraSubject = h end
        notify("Freecam OFF", "warn"); return
    end
    _G.__FreecamOn = true
    cam.CameraType = Enum.CameraType.Scriptable
    local speed = 1
    _G.__FCConn = RunService.RenderStepped:Connect(function(dt)
        if not _G.__FreecamOn then return end
        local m = 60 * dt * speed
        local move = Vector3.zero
        local UIS = game:GetService("UserInputService")
        if UIS:IsKeyDown(Enum.KeyCode.W) then move = move + Vector3.new(0,0,-m) end
        if UIS:IsKeyDown(Enum.KeyCode.S) then move = move + Vector3.new(0,0, m) end
        if UIS:IsKeyDown(Enum.KeyCode.A) then move = move + Vector3.new(-m,0,0) end
        if UIS:IsKeyDown(Enum.KeyCode.D) then move = move + Vector3.new( m,0,0) end
        if UIS:IsKeyDown(Enum.KeyCode.E) then move = move + Vector3.new(0, m,0) end
        if UIS:IsKeyDown(Enum.KeyCode.Q) then move = move + Vector3.new(0,-m,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then move = move * 3 end
        cam.CFrame = cam.CFrame * CFrame.new(move)
    end)
    notify("Freecam ON  (WASD + EQ + Shift)", "good")
end
cmdHandlers["unfreecam"] = cmdHandlers["freecam"]

-- 9) Server hop — teleport to a RANDOM public server
cmdHandlers["hop"] = function()
    notify("Searching server...", "good")
    task.spawn(function()
        local ok, list = pcall(function()
            local raw = game:HttpGet(string.format(
                "https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", game.PlaceId))
            return game:GetService("HttpService"):JSONDecode(raw)
        end)
        if ok and list and list.data then
            local pool = {}
            for _, s in ipairs(list.data) do
                if s.id ~= game.JobId and s.playing and s.maxPlayers and s.playing < s.maxPlayers then
                    pool[#pool+1] = s.id
                end
            end
            if #pool > 0 then
                local pick = pool[math.random(1, #pool)]
                pcall(function() TeleportSrv:TeleportToPlaceInstance(game.PlaceId, pick, LP) end)
                return
            end
        end
        notify("No public servers found, doing plain rejoin", "warn")
        pcall(function() TeleportSrv:Teleport(game.PlaceId, LP) end)
    end)
end
cmdHandlers["serverhop"]    = cmdHandlers["hop"]
cmdHandlers["randomserver"] = cmdHandlers["hop"]
cmdHandlers["jrs"]          = cmdHandlers["hop"]
cmdHandlers["joinrandom"]   = cmdHandlers["hop"]

-- !bypass — send a chat message that bypasses Roblox text censoring
-- Inserts a zero-width joiner between characters so the filter cannot tokenize
-- the words while humans still read the text normally (no ### replacement).
cmdHandlers["bypass"] = function(arg)
    if not arg or arg == "" then notify("Usage: !bypass <message>", "warn"); return end
    local zwj = "\226\128\141" -- U+200D zero-width joiner (UTF-8)
    local out = {}
    -- walk by UTF-8 codepoints so we don't corrupt multi-byte chars
    local i = 1
    while i <= #arg do
        local b = arg:byte(i)
        local len = 1
        if b >= 0xF0 then len = 4
        elseif b >= 0xE0 then len = 3
        elseif b >= 0xC0 then len = 2 end
        out[#out+1] = arg:sub(i, i + len - 1)
        i = i + len
    end
    local payload = table.concat(out, zwj)
    local TextChat = game:GetService("TextChatService")
    local sent = pcall(function()
        local ch = TextChat.TextChannels:FindFirstChild("RBXGeneral") or TextChat.TextChannels:GetChildren()[1]
        if ch then ch:SendAsync(payload) end
    end)
    if not sent then
        pcall(function()
            game:GetService("ReplicatedStorage"):WaitForChild("DefaultChatSystemChatEvents")
                :WaitForChild("SayMessageRequest"):FireServer(payload, "All")
        end)
    end
    notify("Bypass sent", "good")
end
cmdHandlers["bp"]       = cmdHandlers["bypass"]
cmdHandlers["nocensor"] = cmdHandlers["bypass"]

-- 10) Chat say — send a message in chat from the command bar
cmdHandlers["say"] = function(arg)
    if not arg or arg == "" then notify("Usage: !say <message>", "warn"); return end
    local TextChat = game:GetService("TextChatService")
    local sent = pcall(function()
        local ch = TextChat.TextChannels:FindFirstChild("RBXGeneral") or TextChat.TextChannels:GetChildren()[1]
        if ch then ch:SendAsync(arg) end
    end)
    if not sent then
        pcall(function()
            game:GetService("ReplicatedStorage"):WaitForChild("DefaultChatSystemChatEvents")
                :WaitForChild("SayMessageRequest"):FireServer(arg, "All")
        end)
    end
end

-- !baseplate — extend the map under your feet (with bottom-left yes/no confirm)
(function()
    local function confirm(question, onYes, onNo)
        local gui = inst("ScreenGui", nil, {
            Name = "SeigeConfirm", IgnoreGuiInset = true, ResetOnSpawn = false,
            DisplayOrder = 250, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        })
        safeParent(gui)
        local card = inst("Frame", gui, {
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, 16, 1, -16),
            Size = UDim2.new(0, 280, 0, 92),
            BackgroundColor3 = T.bg, BorderSizePixel = 0,
        })
        corner(card, 10); stroke(card, T.line, 1, 0.3)
        inst("TextLabel", card, {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 12, 0, 8), Size = UDim2.new(1, -24, 0, 44),
            Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = T.text,
            TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top, Text = question,
        })
        local function mkBtn(label, x, color, fn)
            local b = inst("TextButton", card, {
                Position = UDim2.new(0, x, 1, -34), Size = UDim2.new(0, 120, 0, 26),
                BackgroundColor3 = color, BorderSizePixel = 0, AutoButtonColor = true,
                Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = T.text, Text = label,
            })
            corner(b, 6); stroke(b, T.line, 1, 0.4)
            b.MouseButton1Click:Connect(function() gui:Destroy(); if fn then pcall(fn) end end)
        end
        mkBtn("Yes", 12,  T.acc, onYes)
        mkBtn("No",  148, T.bg3, onNo)
        task.delay(15, function() if gui and gui.Parent then gui:Destroy() end end)
    end

    local function doExtend()
        local h = hrp()
        if not h then notify("No character — stand somewhere first", "bad"); return end
        local prev = workspace:FindFirstChild("SeigeBaseplate")
        local size, step
        if prev and prev:IsA("BasePart") then
            step = math.min(prev.Size.X * 2, 16384)
            size = Vector3.new(step, 1, step)
        else
            size = Vector3.new(2048, 1, 2048)
        end
        local plate = prev or Instance.new("Part")
        plate.Name = "SeigeBaseplate"
        plate.Anchored = true
        plate.CanCollide = true
        plate.TopSurface = Enum.SurfaceType.Smooth
        plate.BottomSurface = Enum.SurfaceType.Smooth
        plate.Material = Enum.Material.SmoothPlastic
        plate.Color = Color3.fromRGB(80, 90, 110)
        plate.Size = size
        plate.CFrame = CFrame.new(h.Position.X, h.Position.Y - 6, h.Position.Z)
        plate.Parent = workspace
        notify(string.format("Baseplate extended to %dx%d studs", size.X, size.Z), "good")
    end

    cmdHandlers["baseplate"] = function()
        local prev = workspace:FindFirstChild("SeigeBaseplate")
        local q = prev
            and "A baseplate already exists. Extend it further (doubles size, recenters under you)?"
            or "Extend the map? This drops a 2048x2048 baseplate under you (local only)."
        confirm(q, doExtend, function() notify("Cancelled", "warn") end)
    end
end)()


-- ===== Voice helper (uses real Roblox VoiceChat APIs) =====
-- Exposes _G.__SeigeVoice with: isAvailable, isMuted, setMuted, leave, join,
-- cycle, summary. Used by both the Voice popout and the !antivc command.
;(function()
    local function tryCall(obj, methods, ...)
        if not obj then return false end
        for _, m in ipairs(methods) do
            local fn = nil
            pcall(function() fn = obj[m] end)
            if typeof(fn) == "function" then
                local ok = pcall(fn, obj, ...)
                if ok then return true, m end
            end
        end
        return false
    end
    local function svcInternal()
        local s
        pcall(function() s = game:FindService("VoiceChatInternal") end)
        if not s then pcall(function() s = game:GetService("VoiceChatInternal") end) end
        return s
    end
    local function svcPublic()
        local s
        pcall(function() s = game:GetService("VoiceChatService") end)
        return s
    end

    -- ===== Voice moderation bypass =====
    -- Pattern: under getService("VoiceChatService"), if PlayerService is present
    -- then turn on bypass -> allow PlayerService. Neutralises the client-side
    -- moderation reporter so swearing on mic doesn't get auto-flagged/banned.
    _G.__SeigeVCBypassInstalled = _G.__SeigeVCBypassInstalled or false
    local function installBypass()
        if _G.__SeigeVCBypassInstalled then return true end
        local VCS = svcPublic()
        local PlayerService = nil
        pcall(function() PlayerService = game:GetService("Players") end)
        if not VCS or not PlayerService then return false end

        -- turn on bypass
        pcall(function() VCS.EnableDefaultVoice = false end)
        pcall(function() VCS:SetProperty("EnableDefaultVoice", false) end)

        -- allow PlayerService: silence the moderation -> player reporter path.
        local function hookRemote(r)
            if not r then return end
            local nm = ""
            pcall(function() nm = (r.Name or ""):lower() end)
            if nm == "" then return end
            if not (nm:find("voice") or nm:find("moder") or nm:find("report")
                    or nm:find("transcript") or nm:find("abuse")) then return end
            pcall(function() r.FireServer = function() end end)
            pcall(function() r.InvokeServer = function() return nil end end)
        end
        pcall(function()
            for _, d in ipairs(VCS:GetDescendants()) do hookRemote(d) end
            VCS.DescendantAdded:Connect(hookRemote)
        end)
        pcall(function()
            for _, d in ipairs(PlayerService:GetDescendants()) do hookRemote(d) end
            PlayerService.DescendantAdded:Connect(hookRemote)
        end)

        -- Global namecall guard: drop voice/moderation remote traffic before
        -- it reaches Roblox's server moderation pipeline.
        if hookmetamethod and not _G.__SeigeVCNamecallHooked then
            _G.__SeigeVCNamecallHooked = true
            pcall(function()
                local oldNC
                oldNC = hookmetamethod(game, "__namecall", function(self, ...)
                    local method = getnamecallmethod and getnamecallmethod() or ""
                    if method == "FireServer" or method == "InvokeServer" then
                        local nm = ""
                        pcall(function() nm = (self.Name or ""):lower() end)
                        if nm:find("voicemoderation") or nm:find("voicereport")
                            or nm:find("voicetranscript") or nm:find("voiceabuse")
                            or nm:find("reportabuse") then
                            return nil
                        end
                    end
                    return oldNC(self, ...)
                end)
            end)
        end

        _G.__SeigeVCBypassInstalled = true
        return true
    end
    -- Install on load so swearing protection is on the moment voice activates.
    task.spawn(function() pcall(installBypass) end)

    local V = {}
    V.installBypass = installBypass
    function V.isAvailable()
        return svcInternal() ~= nil or svcPublic() ~= nil
    end
    function V.isPublishing()
        local s = svcInternal(); if not s then return nil end
        local ok, v = pcall(function() return s:IsPublishing() end)
        if ok then return v end
        return nil
    end
    function V.isSubscribed()
        local s = svcInternal(); if not s then return nil end
        local ok, v = pcall(function() return s:IsSubscribed() end)
        if ok then return v end
        return nil
    end
    function V.isMuted()
        local p = V.isPublishing()
        if p == nil then return _G.__SeigeMicMuted == true end
        return p == false
    end

    -- Activation gate: if the user joined the game with their mic MUTED,
    -- nothing voice-related works until they unmute in Roblox and click
    -- "Activate" in the popout (or run !vcactivate).
    _G.__SeigeVoiceActivated = _G.__SeigeVoiceActivated or false
    local function snapshotInitialMute()
        if _G.__SeigeVoiceInitChecked then return end
        _G.__SeigeVoiceInitChecked = true
        local p = V.isPublishing()
        -- nil = API didn't answer yet; treat as locked to be safe.
        _G.__SeigeVoiceStartedMuted = (p == false) or (p == nil)
        if not _G.__SeigeVoiceStartedMuted then
            _G.__SeigeVoiceActivated = true -- mic was live → auto-activate
        end
    end
    task.spawn(function()
        -- Wait briefly for VoiceChatInternal to come online before snapshotting
        for _ = 1, 20 do
            if V.isAvailable() and V.isPublishing() ~= nil then break end
            task.wait(0.5)
        end
        snapshotInitialMute()
    end)
    function V.isActivated() return _G.__SeigeVoiceActivated == true end
    function V.activate()
        snapshotInitialMute()
        if V.isPublishing() == false then
            return false, "Unmute your mic in Roblox first"
        end
        pcall(installBypass) -- ensure swear/ban bypass is live before mic opens
        _G.__SeigeVoiceActivated = true
        return true
    end
    function V.gateCheck(action)
        if not V.isAvailable() then return false, "Voice service not in this game" end
        if not V.isActivated() then
            return false, "Mic muted at start — unmute & click Activate first"
        end
        return true
    end

    -- Mic mute: Publish/Unpublish on VoiceChatInternal (controls transmit).
    function V.setMuted(on)
        local ok, why = V.gateCheck("setMuted")
        if not ok then notify(why, "warn"); return end
        _G.__SeigeMicMuted = on and true or false
        local s = svcInternal()
        if on then
            tryCall(s, { "Unpublish", "PublishPaused" }, true)
        else
            tryCall(s, { "Publish" })
        end
        local pub = svcPublic()
        if pub then pcall(function() if on then pub:joinVoice() end end) end
    end
    function V.leave()
        local ok, why = V.gateCheck("leave"); if not ok then notify(why, "warn"); return end
        local s = svcInternal()
        tryCall(s, { "UnsubscribeAll" })
        tryCall(s, { "Unpublish" })
        local pub = svcPublic()
        tryCall(pub, { "leaveChannel", "LeaveChannel" })
    end
    function V.join()
        local ok, why = V.gateCheck("join"); if not ok then notify(why, "warn"); return end
        local s = svcInternal()
        tryCall(s, { "SubscribeAll" })
        if not _G.__SeigeMicMuted then
            tryCall(s, { "Publish" })
        end
        local pub = svcPublic()
        tryCall(pub, { "joinVoice", "JoinChannel" })
    end
    function V.cycle()
        local ok = V.gateCheck("cycle"); if not ok then return false end
        V.leave()
        task.wait(0.35 + math.random() * 0.5)
        V.join()
        return true
    end
    function V.summary()
        if not V.isAvailable() then return "Voice service not available in this game" end
        if not V.isActivated() then
            return "LOCKED — mic was muted at start. Unmute, then click Activate."
        end
        local mic = V.isMuted() and "MUTED" or "LIVE"
        local sub = V.isSubscribed()
        local subTxt = sub == nil and "?" or (sub and "ON" or "OFF")
        return string.format("Mic: %s   ·   Listening: %s", mic, subTxt)
    end
    _G.__SeigeVoice      = V
    _G.__SeigeCycleVoice = V.cycle

    cmdHandlers["antivc"] = function()
        _G.__SeigeAntiVC = _G.__SeigeAntiVC or { on = false, interval = 10 }
        if _G.__SeigeAntiVC.on then
            _G.__SeigeAntiVC.on = false
            notify("AntiVC OFF", "warn"); return
        end
        local ok, why = V.gateCheck("antivc")
        if not ok then notify(why, "bad"); return end
        pcall(function() V.installBypass() end)
        _G.__SeigeAntiVC.on = true
        notify("AntiVC ON — bypass + recycle (swear-safe)", "good")
        task.spawn(function()
            while _G.__SeigeAntiVC and _G.__SeigeAntiVC.on do
                -- Short interval beats Roblox's voice transcription window so
                -- no full phrase ever reaches the moderation classifier.
                local base = tonumber(_G.__SeigeAntiVC.interval) or 10
                task.wait(math.max(6, base) + math.random() * 3)
                if not (_G.__SeigeAntiVC and _G.__SeigeAntiVC.on) then break end
                V.cycle()
            end
        end)
    end
    cmdHandlers["vcactivate"] = function()
        local ok, why = V.activate()
        notify(ok and "Voice controls ACTIVE" or (why or "Activation failed"), ok and "good" or "warn")
    end
    cmdHandlers["antivoice"] = cmdHandlers["antivc"]
    cmdHandlers["unantivc"]  = function()
        if _G.__SeigeAntiVC then _G.__SeigeAntiVC.on = false end
        notify("AntiVC OFF", "warn")
    end
    cmdHandlers["mute"]   = function() V.setMuted(true);  notify("Mic muted", "good") end
    cmdHandlers["unmute"] = function() V.setMuted(false); notify("Mic live",  "good") end
    cmdHandlers["vcleave"] = function() V.leave(); notify("Voice left", "good") end
    cmdHandlers["vcjoin"]  = function() V.join();  notify("Voice rejoined", "good") end
end)()


cmdHandlers["save"] = function()
    local h = hrp(); if not h then notify("No character", "bad"); return end
    _G.__SavedCF = h.CFrame; notify("Position saved", "good")
end
cmdHandlers["load"] = function()
    local h = hrp(); if not h or not _G.__SavedCF then notify("Nothing saved", "bad"); return end
    h.CFrame = _G.__SavedCF; notify("Position loaded", "good")
end

cmdHandlers["info"] = function()
    notify(string.format("Players: %d  ·  JobId set: %s", #Players:GetPlayers(), tostring(game.JobId ~= "")), "good")
end

cmdHandlers["help"] = function()
    if _G.__SeigeOpenHelp then _G.__SeigeOpenHelp() else notify("Help panel not ready", "warn") end
end

-- Admin-only broadcast: send a private banner message to every script user
-- in this server. Non-script users see nothing (marker is filtered out of chat).
cmdHandlers["allp"] = function(arg)
    if not (_G.__SeigeCan and _G.__SeigeCan("allp")) then notify("!allp requires Admin or Staff role", "bad"); return end
    local msg = tostring(arg or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if msg == "" then notify("Usage: !allp <message>", "warn"); return end
    if not _G.__SeigeAllpSend then notify("Broadcast not ready", "bad"); return end
    local ok, err = _G.__SeigeAllpSend(msg)
    if ok then notify("Sent to all script users", "good")
    else notify("Send failed: " .. tostring(err), "bad") end
end

-- Admin-only lockout: !rmvp <user> locks the target out of the script;
-- !unrmvp <user> clears it. Lock is broadcast via the chat-marker channel
-- and persisted on the target's machine so it survives rejoin.
local function _doLock(arg, locked)
    if not (_G.__SeigeCan and _G.__SeigeCan("lock")) then notify("Requires Admin role", "bad"); return end
    local target = tostring(arg or ""):gsub("^%s+", ""):gsub("%s+$", ""):gsub("^@", "")
    if target == "" then
        notify("Usage: " .. (locked and "!rmvp" or "!unrmvp") .. " <user>", "warn"); return
    end
    if not _G.__SeigeLockBroadcast then notify("Lock broadcast not ready", "bad"); return end
    local ok, err = _G.__SeigeLockBroadcast(target, locked)
    if ok then
        notify((locked and "Locked " or "Unlocked ") .. target, "good")
    else
        notify("Failed: " .. tostring(err), "bad")
    end
end
cmdHandlers["rmvp"]   = function(arg) _doLock(arg, true)  end
cmdHandlers["unrmvp"] = function(arg) _doLock(arg, false) end

-- Admin-only: force the target user's client to send a chat message.
-- Roblox tags the message as coming from the target because their own client
-- calls TextChannel:SendAsync after receiving the broadcast marker.
cmdHandlers["usay"] = function(arg)
    if not (_G.__SeigeCan and _G.__SeigeCan("usay")) then notify("Requires Admin role", "bad"); return end
    local s = tostring(arg or ""):gsub("^%s+", ""):gsub("%s+$", "")
    local target, msg = s:match("^(%S+)%s+(.+)$")
    if not target or not msg then
        notify("Usage: !usay <user> <message>", "warn"); return
    end
    if not _G.__SeigeUsaySend then notify("Broadcast not ready", "bad"); return end
    local ok, err = _G.__SeigeUsaySend(target, msg)
    if ok then notify("Sent !usay to " .. target, "good")
    else notify("Failed: " .. tostring(err), "bad") end
end

-- =====================================================================
-- STAFF COMMANDS (8) · available to Staff, Admin, Owner
-- Excludes !freeze / !unfreeze (Admin/Owner only) and !usay / !rmvp
-- / !unrmvp (Admin/Owner only).
-- =====================================================================
local function _staffGate(name)
    if not (_G.__SeigeCan and _G.__SeigeCan("staff_cmd")) then
        notify(name .. " requires Staff role", "bad"); return false
    end
    return true
end
local function _resolveScriptUser(name)
    name = tostring(name or ""):gsub("^@", ""):gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then return nil end
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower() == name:lower() or p.DisplayName:lower() == name:lower() then
            return p
        end
    end
    return nil
end

-- 1) !bring <user> — teleport target script user to me
cmdHandlers["bring"] = function(arg)
    if not _staffGate("!bring") then return end
    local t = tostring(arg or ""):gsub("%s+", "")
    if t == "" then notify("Usage: !bring <user>", "warn"); return end
    if not _G.__SeigeBringSend then notify("Broadcast not ready", "bad"); return end
    local ok, err = _G.__SeigeBringSend(t)
    if ok then notify("Bringing " .. t, "good") else notify("Failed: " .. tostring(err), "bad") end
end

-- 2) !bringall — teleport every script user to me (Admin/Owner only)
cmdHandlers["bringall"] = function()
    if not (_G.__SeigeCan and _G.__SeigeCan("bringall")) then
        notify("!bringall requires Admin role", "bad"); return
    end
    if not _G.__SeigeBringAllSend then notify("Broadcast not ready", "bad"); return end
    _G.__SeigeBringAllSend()
    notify("Bringing all script users", "good")
end

-- 3) !goto <user> — teleport me to target (local; works on any player)
cmdHandlers["goto"] = function(arg)
    if not _staffGate("!goto") then return end
    local p = _resolveScriptUser(arg)
    if not p then notify("Player not found: " .. tostring(arg), "bad"); return end
    local myHRP = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    local tHRP  = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
    if not (myHRP and tHRP) then notify("Character not ready", "warn"); return end
    myHRP.CFrame = tHRP.CFrame + Vector3.new(0, 0, 3)
    notify("Teleported to " .. p.Name, "good")
end

-- 4) !freeze <user> — anchor the target script user (Admin/Owner only)
cmdHandlers["freeze"] = function(arg)
    if not (_G.__SeigeCan and _G.__SeigeCan("freeze")) then
        notify("!freeze requires Admin role", "bad"); return
    end
    local t = tostring(arg or ""):gsub("%s+", "")
    if t == "" then notify("Usage: !freeze <user>", "warn"); return end
    if not _G.__SeigeFreezeSend then notify("Broadcast not ready", "bad"); return end
    _G.__SeigeFreezeSend(t, true); notify("Froze " .. t, "good")
end

-- 5) !unfreeze <user> (Admin/Owner only)
cmdHandlers["unfreeze"] = function(arg)
    if not (_G.__SeigeCan and _G.__SeigeCan("freeze")) then
        notify("!unfreeze requires Admin role", "bad"); return
    end
    local t = tostring(arg or ""):gsub("%s+", "")
    if t == "" then notify("Usage: !unfreeze <user>", "warn"); return end
    if not _G.__SeigeFreezeSend then notify("Broadcast not ready", "bad"); return end
    _G.__SeigeFreezeSend(t, false); notify("Unfroze " .. t, "good")
end

-- 6) !warn <user> <message> — private warning banner on target's screen
cmdHandlers["warn"] = function(arg)
    if not _staffGate("!warn") then return end
    local s = tostring(arg or ""):gsub("^%s+", ""):gsub("%s+$", "")
    local target, msg = s:match("^(%S+)%s+(.+)$")
    if not target or not msg then notify("Usage: !warn <user> <message>", "warn"); return end
    if not _G.__SeigeWarnSend then notify("Broadcast not ready", "bad"); return end
    local ok, err = _G.__SeigeWarnSend(target, msg)
    if ok then notify("Warned " .. target, "good") else notify("Failed: " .. tostring(err), "bad") end
end

-- 7) !shout <message> — big centered overlay on every script user's screen
cmdHandlers["shout"] = function(arg)
    if not _staffGate("!shout") then return end
    local msg = tostring(arg or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if msg == "" then notify("Usage: !shout <message>", "warn"); return end
    if not _G.__SeigeShoutSend then notify("Broadcast not ready", "bad"); return end
    _G.__SeigeShoutSend(msg); notify("Shouted to all script users", "good")
end

-- 8) !ping <user> — flash target's screen + bell sound
cmdHandlers["ping"] = function(arg)
    if not _staffGate("!ping") then return end
    local t = tostring(arg or ""):gsub("%s+", "")
    if t == "" then notify("Usage: !ping <user>", "warn"); return end
    if not _G.__SeigePingSend then notify("Broadcast not ready", "bad"); return end
    _G.__SeigePingSend(t); notify("Pinged " .. t, "good")
end

-- 9) !whois <user> — show local info about a player
cmdHandlers["whois"] = function(arg)
    if not _staffGate("!whois") then return end
    local p = _resolveScriptUser(arg)
    if not p then notify("Player not found: " .. tostring(arg), "bad"); return end
    local entry = TagDB and TagDB.entries and TagDB.entries[p.Name:lower()] or nil
    local tag = entry and ((entry.tags and entry.tags[1]) or entry.displayName or "tagged") or "no tag"
    local age = "?"; pcall(function() age = tostring(p.AccountAge) end)
    notify(string.format("@%s · %s · age %s d · uid %d · tag: %s",
        p.Name, p.DisplayName, age, p.UserId, tag), "good")
end

-- 10) !list — list all detected script users
cmdHandlers["list"] = function()
    if not _staffGate("!list") then return end
    local reg = _G.__SeigeScriptUsers or {}
    local rows = {}
    for _, info in pairs(reg) do
        local plr = Players:GetPlayerByUserId(info.userId)
        if plr then rows[#rows+1] = { text = "@" .. plr.Name, right = "uid " .. plr.UserId } end
    end
    table.sort(rows, function(a, b) return a.text < b.text end)
    _openResultPanel("list", ("Script users · %d in server"):format(#rows), rows,
        { empty = "No script users detected in this server.", height = 340 })
end

-- =====================================================================
-- STAFF COMMANDS · 5 additional commands available to staff/admin/owner
-- Light-touch oversight tools: private messaging, soft alerts, spectating
-- and proximity scans. All gated through _staffGate("!cmd").
-- =====================================================================

-- 1) !pm <user> <msg> — private banner toast to a single script user
cmdHandlers["pm"] = function(arg)
    if not _staffGate("!pm") then return end
    local s = tostring(arg or ""):gsub("^%s+", ""):gsub("%s+$", "")
    local user, msg = s:match("^(%S+)%s+(.+)$")
    if not user or not msg then notify("Usage: !pm <user> <msg>", "warn"); return end
    if _G.__SeigePmSend then
        local ok, err = _G.__SeigePmSend(user, msg)
        if ok then notify("PM sent to @" .. user:gsub("^@",""), "good")
        else notify("PM failed: " .. tostring(err), "bad") end
    end
end

-- 2) !alert <msg> — yellow warning toast for every script user in the server
cmdHandlers["alert"] = function(arg)
    if not _staffGate("!alert") then return end
    local msg = tostring(arg or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if msg == "" then notify("Usage: !alert <msg>", "warn"); return end
    if _G.__SeigeAlertSend then
        local ok, err = _G.__SeigeAlertSend(msg)
        if ok then notify("Alert broadcast to all script users", "good")
        else notify("Alert failed: " .. tostring(err), "bad") end
    end
end

-- 3) !view <user> — spectate a player's camera (local-only effect)
local _savedCamSubject
cmdHandlers["view"] = function(arg)
    if not _staffGate("!view") then return end
    local t = tostring(arg or ""):gsub("^%s+",""):gsub("%s+$",""):gsub("^@","")
    if t == "" then notify("Usage: !view <user>", "warn"); return end
    local target
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower():sub(1, #t) == t:lower() then target = p; break end
    end
    if not target or not target.Character then notify("Player not found or no character", "warn"); return end
    local hum = target.Character:FindFirstChildOfClass("Humanoid")
    if not hum then notify("Target has no Humanoid", "warn"); return end
    local cam = workspace.CurrentCamera
    if cam then
        if not _savedCamSubject then _savedCamSubject = cam.CameraSubject end
        cam.CameraSubject = hum
        notify("Spectating @" .. target.Name .. " — use !unview to restore", "good")
    end
end

-- 4) !unview — restore your own camera after !view
cmdHandlers["unview"] = function()
    if not _staffGate("!unview") then return end
    local cam = workspace.CurrentCamera
    if cam then
        local myHum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        cam.CameraSubject = _savedCamSubject or myHum
        _savedCamSubject = nil
        notify("Camera restored", "good")
    end
end

-- 5) !nearby — list script users within 80 studs of you
cmdHandlers["nearby"] = function()
    if not _staffGate("!nearby") then return end
    local myChar = LP.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then notify("You have no character yet", "warn"); return end
    local reg = _G.__SeigeScriptUsers or {}
    local rows = {}
    for _, info in pairs(reg) do
        local plr = Players:GetPlayerByUserId(info.userId)
        if plr and plr ~= LP and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local d = (plr.Character.HumanoidRootPart.Position - myHRP.Position).Magnitude
            if d <= 80 then rows[#rows+1] = { name = plr.Name, dist = d } end
        end
    end
    table.sort(rows, function(a, b) return a.dist < b.dist end)
    if #rows == 0 then notify("No script users within 80 studs", "warn"); return end
    local parts = {}
    for _, r in ipairs(rows) do parts[#parts+1] = ("@%s (%dst)"):format(r.name, math.floor(r.dist)) end
    notify(("%d nearby script user%s: %s"):format(#rows, #rows==1 and "" or "s", table.concat(parts, ", ")), "good")
end



-- =====================================================================
-- NT TAG COMMANDS (5) · available to NT Team, Admin, Owner
-- Read-only lookup tools for tag verification and database browsing.
-- =====================================================================
local function _ntGate(name)
    if not (_G.__SeigeCan and _G.__SeigeCan("nt_cmd")) then
        notify(name .. " requires NT Team role", "bad"); return false
    end
    return true
end

-- Small inline hex->Color3 used by tag result panels.
local function _seigeHexColor(h)
    if type(h) ~= "string" then return nil end
    local s = h:gsub("^#", "")
    if #s == 3 then s = s:sub(1,1):rep(2) .. s:sub(2,2):rep(2) .. s:sub(3,3):rep(2) end
    if #s ~= 6 then return nil end
    local ok, c = pcall(function() return Color3.fromHex(s) end)
    if ok and c then return c end
    return nil
end

-- 1) !taginfo <user> — show full tag details in a GUI window
cmdHandlers["taginfo"] = function(arg)
    if not _ntGate("!taginfo") then return end
    local t = tostring(arg or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if t == "" then notify("Usage: !taginfo <user>", "warn"); return end
    local key = t:lower():gsub("^@", "")
    local e = TagDB and TagDB.entries and TagDB.entries[key] or nil
    if not e then
        _openResultPanel("taginfo", "Tag info · @" .. key, {},
            { empty = "No tag entry for @" .. key, height = 160 })
        return
    end
    local rows = {}
    if e.displayName then rows[#rows+1] = { text = "name: " .. tostring(e.displayName) } end
    if e.tags and #e.tags > 0 then
        for i, tag in ipairs(e.tags) do
            rows[#rows+1] = { text = ("tag %d: %s"):format(i, tostring(tag)) }
        end
    end
    if e.color then
        rows[#rows+1] = { text = "color: " .. tostring(e.color), swatch = _seigeHexColor(e.color) }
    end
    if e.textColor then
        rows[#rows+1] = { text = "text: " .. tostring(e.textColor), swatch = _seigeHexColor(e.textColor) }
    end
    if e.textOutline then rows[#rows+1] = { text = "outline: " .. tostring(e.textOutline) } end
    if e.icon then rows[#rows+1] = { text = "icon: " .. tostring(e.icon) } end
    if #rows == 0 then rows[1] = { text = "(entry exists but no details)" } end
    _openResultPanel("taginfo", "Tag info · @" .. key, rows, { height = 320 })
end

-- 2) !taglist — list all tagged players currently in this server (GUI window)
cmdHandlers["taglist"] = function()
    if not _ntGate("!taglist") then return end
    local rows = {}
    for _, p in ipairs(Players:GetPlayers()) do
        local e = TagDB and TagDB.entries and TagDB.entries[p.Name:lower()] or nil
        if e then
            local tag = (e.tags and e.tags[1]) or e.displayName or "tagged"
            rows[#rows+1] = {
                text = "@" .. p.Name .. "  ·  " .. tag,
                swatch = e.color and _seigeHexColor(e.color) or nil,
            }
        end
    end
    table.sort(rows, function(a, b) return a.text < b.text end)
    _openResultPanel("taglist", ("Tagged players · %d in server"):format(#rows), rows,
        { empty = "No tagged players in this server.", height = 360 })
end

-- 3) !tagcheck <user> — quick yes/no whether a player has a tag entry
cmdHandlers["tagcheck"] = function(arg)
    if not _ntGate("!tagcheck") then return end
    local t = tostring(arg or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if t == "" then notify("Usage: !tagcheck <user>", "warn"); return end
    local key = t:lower():gsub("^@", "")
    local e = TagDB and TagDB.entries and TagDB.entries[key] or nil
    if e then
        local tag = e.tags and e.tags[1] or e.displayName or "tagged"
        notify(t .. " has a tag entry (" .. tag .. ")", "good")
    else
        notify(t .. " is NOT in the tag database", "warn")
    end
end

-- 4) !tagfind <keyword> — search tag database by username or tag name (GUI window)
cmdHandlers["tagfind"] = function(arg)
    if not _ntGate("!tagfind") then return end
    local kw = tostring(arg or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if kw == "" then notify("Usage: !tagfind <keyword>", "warn"); return end
    local kwl = kw:lower()
    local rows = {}
    for key, e in pairs(TagDB and TagDB.entries or {}) do
        local match = false
        if key:find(kwl, 1, true) then match = true end
        if not match and e.tags then
            for _, tag in ipairs(e.tags) do
                if tostring(tag):lower():find(kwl, 1, true) then match = true; break end
            end
        end
        if not match and e.displayName and tostring(e.displayName):lower():find(kwl, 1, true) then match = true end
        if match then
            local label = (e.tags and e.tags[1]) or e.displayName or "tagged"
            rows[#rows+1] = {
                text = "@" .. key .. "  ·  " .. label,
                swatch = e.color and _seigeHexColor(e.color) or nil,
            }
        end
    end
    table.sort(rows, function(a, b) return a.text < b.text end)
    _openResultPanel("tagfind", ("Tag search '%s' · %d match%s"):format(kw, #rows, #rows == 1 and "" or "es"),
        rows, { empty = "No tag entries matching '" .. kw .. "'.", height = 360 })
end

-- 5) !tagcolors — show colors currently used in the tag database (GUI window w/ swatches)
cmdHandlers["tagcolors"] = function()
    if not _ntGate("!tagcolors") then return end
    local seen = {}
    for _, e in pairs(TagDB and TagDB.entries or {}) do
        if e.color then
            local c = tostring(e.color)
            seen[c] = (seen[c] or 0) + 1
        end
    end
    local rows = {}
    for c, n in pairs(seen) do
        rows[#rows+1] = { text = c, right = n .. "×", swatch = _seigeHexColor(c), _n = n }
    end
    table.sort(rows, function(a, b) return a._n > b._n end)
    _openResultPanel("tagcolors", ("Tag colors · %d unique"):format(#rows), rows,
        { empty = "No colors found in tag database.", height = 360 })
end

-- !reanim — launch the Reanim GUI (purple-storm build). Available to every script user.
cmdHandlers["reanim"] = function()
    notify("Loading Reanim…", "good")
    task.spawn(function()
        local ok, src = pcall(function()
            return game:HttpGet("https://seigescript.online/api/public/reanim.lua")
        end)
        if not ok or type(src) ~= "string" or src == "" then
            notify("Reanim fetch failed", "bad"); return
        end
        local fn, perr = (loadstring or load)(src, "=reanim")
        if not fn then notify("Reanim parse error: " .. tostring(perr), "bad"); return end
        local rok, rerr = pcall(fn)
        if not rok then notify("Reanim runtime error: " .. tostring(rerr), "bad") end
    end)
end


local function runBarCmd(raw)
    if not raw or raw == "" then return end
    local s = raw:gsub("^%s+", ""):gsub("%s+$", "")
    s = s:gsub("^[!:;]+", "")
    local cmd, arg = s:match("^(%S+)%s*(.*)$")
    if not cmd then return end
    cmd = cmd:lower()
    -- Kill switch: when on, lock every script user out of every command
    -- except the owner. Owner is always exempt.
    if _G.__SeigeKilled and LP.Name ~= OWNER_NAME then
        if _G.__SeigeAudit then _G.__SeigeAudit("cmd_attempt", "!" .. cmd .. " (kill-switch blocked)", false) end
        notify("Script is paused by the owner. Commands disabled.", "bad")
        return
    end
    local h = cmdHandlers[cmd]
    if _G.__SeigeAudit then
        local d = "!" .. cmd
        if arg and arg ~= "" then d = d .. " " .. (arg:len() > 60 and (arg:sub(1, 60) .. "…") or arg) end
        _G.__SeigeAudit("cmd_attempt", d, h ~= nil)
    end
    if h then h(arg) else notify("Unknown command: " .. cmd, "bad") end
end

cmdBox.PlaceholderText = "!rj !tprj !fly !noclip !ws !jp !god !goto !to !spectate !fling !heal !save !load !help"

-- Roblox chat command bridge: any message starting with ! (e.g. !rj, !tprj) runs the command.
-- We ALSO intercept the message at the outgoing send layer so the avatar never
-- broadcasts the "!cmd" text into public chat — commands are hidden.
pcall(function()
    LP.Chatted:Connect(function(msg)
        if type(msg) ~= "string" then return end
        if msg:sub(1, 1) ~= "!" then return end
        runBarCmd(msg)
    end)
end)

-- Hide outgoing "!cmd" messages so they never appear as a chat bubble / chat line.
-- Hooks TextChatService (new chat) and the legacy SayMessageRequest remote.
pcall(function()
    local hookmm    = rawget(getfenv(), "hookmetamethod")
    local getraw    = rawget(getfenv(), "getrawmetatable")
    local setread   = rawget(getfenv(), "setreadonly")
    local getnc     = rawget(getfenv(), "getnamecallmethod")
    local newccl    = rawget(getfenv(), "newcclosure") or function(f) return f end

    local function isAdminCmd(s)
        if type(s) ~= "string" then return false end
        local t = s:gsub("^%s+", "")
        return t:sub(1, 1) == "!"
    end

    -- Preferred: hookmetamethod (Synapse / Fluxus / most modern executors)
    if hookmm then
        local old
        old = hookmm(game, "__namecall", newccl(function(self, ...)
            local method = getnc and getnc() or ""
            if method == "SendAsync" and typeof(self) == "Instance"
               and self:IsA("TextChannel") then
                local args = {...}
                if isAdminCmd(args[1]) then
                    task.spawn(function() runBarCmd(args[1]) end)
                    return nil -- swallow: nothing leaves the client
                end
            elseif method == "FireServer" and typeof(self) == "Instance"
                   and self.Name == "SayMessageRequest" then
                local args = {...}
                if isAdminCmd(args[1]) then
                    task.spawn(function() runBarCmd(args[1]) end)
                    return nil
                end
            end
            return old(self, ...)
        end))
    elseif getraw and setread then
        -- Fallback: manual metatable swap
        local mt = getraw(game)
        local oldNc = mt.__namecall
        setread(mt, false)
        mt.__namecall = newccl(function(self, ...)
            local method = getnc and getnc() or ""
            if method == "SendAsync" and typeof(self) == "Instance"
               and self:IsA("TextChannel") then
                local args = {...}
                if isAdminCmd(args[1]) then
                    task.spawn(function() runBarCmd(args[1]) end)
                    return nil
                end
            elseif method == "FireServer" and typeof(self) == "Instance"
                   and self.Name == "SayMessageRequest" then
                local args = {...}
                if isAdminCmd(args[1]) then
                    task.spawn(function() runBarCmd(args[1]) end)
                    return nil
                end
            end
            return oldNc(self, ...)
        end)
        pcall(setread, mt, true)
    end
end)




local barPinned = false
cmdBox.FocusLost:Connect(function(enter)
    local t = cmdBox.Text
    if enter then
        cmdBox.Text = ""
        cmdBar.Visible = false
        barPinned = false
        runBarCmd(t)
    elseif not barPinned then
        cmdBox.Text = ""
        cmdBar.Visible = false
    end
end)

local function setCmdBar(v, pinned)
    barPinned = v and pinned or false
    cmdBar.Visible = v
    if v then
        task.defer(function()
            cmdBox.Text = ""
            cmdBox:CaptureFocus()
        end)
    else
        cmdBox.Text = ""
        pcall(function() cmdBox:ReleaseFocus() end)
    end
end
_G.__AdminToggleCmdBar = function(v) setCmdBar(v, true) end
_G.__AdminRunCmd = function(s) runBarCmd(s) end
_G.__AdminOpenCmd = function(prefill)
    setCmdBar(true, true)
    task.defer(function()
        cmdBox.Text = prefill or ""
        pcall(function() cmdBox.CursorPosition = #cmdBox.Text + 1 end)
        pcall(function() cmdBox:CaptureFocus() end)
    end)
end

bind(UIS.InputBegan:Connect(function(i, gp)
    if i.UserInputType ~= Enum.UserInputType.Keyboard then return end
    if i.KeyCode == Enum.KeyCode.Escape and cmdBar.Visible then
        setCmdBar(false); return
    end
    if gp then return end
    if i.KeyCode == Enum.KeyCode.F6 or i.KeyCode == Enum.KeyCode.Semicolon then
        setCmdBar(not cmdBar.Visible, false)
    end
end))

-- Open Profile by default
if panels.Profile then panels.Profile.frame.Visible = true end


------------------------------------------------------- SPOTIFY
(function()
    local httpReq = (syn and syn.request)
        or rawget(getfenv(), "http_request")
        or rawget(getfenv(), "request")
        or (fluxus and fluxus.request)
        or (http and http.request)
    local function spReq(method, path, token, body)
        if not httpReq then return nil, "Your executor lacks an HTTP request function" end
        local url = path:sub(1,4) == "http" and path or ("https://api.spotify.com/v1" .. path)
        local headers = { ["Authorization"] = "Bearer " .. token }
        if body then headers["Content-Type"] = "application/json" end
        local ok, res = pcall(httpReq, { Url = url, Method = method, Headers = headers, Body = body })
        if not ok or not res then return nil, "Request failed" end
        return res.StatusCode or res.status_code or 0, res.Body or res.body or ""
    end

    section(pgSpotify, "Spotify Connect")
    label(pgSpotify, "Paste a Spotify OAuth token (see Spotify Web API docs).")
    local token = ""
    local readToken = function() local ok, t = pcall(function() return (readfile and readfile("seige_spotify.txt")) or "" end) if ok and t then token = t end end
    pcall(readToken)
    local nowPlaying = label(pgSpotify, token ~= "" and "Token loaded — press Connect to verify" or "Not connected")
    textbox(pgSpotify, "Spotify access token (BQ…)", function(v)
        token = (v or ""):gsub("^%s+", ""):gsub("%s+$", "")
        pcall(function() if writefile then writefile("seige_spotify.txt", token) end end)
        notify("Token saved", "good")
    end)
    button(pgSpotify, "Connect / verify token", function()
        if token == "" then notify("Paste a token first", "bad"); return end
        local status, body = spReq("GET", "/me", token)
        if status == 200 then
            local ok, data = pcall(function() return HttpService:JSONDecode(body) end)
            local who = (ok and data and (data.display_name or data.id)) or "you"
            nowPlaying:set("Connected as " .. tostring(who))
            notify("Spotify connected: " .. tostring(who), "good")
        else
            nowPlaying:set("Auth failed (" .. tostring(status) .. ")")
            notify("Token rejected (" .. tostring(status) .. ") — get a fresh one", "bad")
        end
    end)
    button(pgSpotify, "Open token helper (developer.spotify.com)", function()
        if setclipboard then pcall(setclipboard, "https://developer.spotify.com/console/get-current-user/") end
        notify("URL copied: developer.spotify.com/console — Get Token w/ user-modify-playback-state", "good")
    end)

    section(pgSpotify, "Playback")
    local nowTrack = label(pgSpotify, "—")
    button(pgSpotify, "▶  Play",  function() local s = spReq("PUT",  "/me/player/play",  token); if s and s >= 400 then notify("Play failed " .. s, "bad") end end)
    button(pgSpotify, "❚❚ Pause", function() local s = spReq("PUT",  "/me/player/pause", token); if s and s >= 400 then notify("Pause failed " .. s, "bad") end end)
    button(pgSpotify, "⏭  Next",  function() local s = spReq("POST", "/me/player/next",  token); if s and s >= 400 then notify("Next failed " .. s, "bad") end end)
    button(pgSpotify, "⏮  Previous", function() local s = spReq("POST", "/me/player/previous", token); if s and s >= 400 then notify("Prev failed " .. s, "bad") end end)
    slider(pgSpotify, "Volume", 0, 100, 60, function(v)
        if token == "" then return end
        spReq("PUT", "/me/player/volume?volume_percent=" .. tostring(math.floor(v + 0.5)), token)
    end)

    section(pgSpotify, "Search & play")
    textbox(pgSpotify, "Search a track (artist — title)", function(q)
        if token == "" then notify("Connect first", "bad"); return end
        q = (q or ""):gsub("^%s+",""):gsub("%s+$","")
        if q == "" then return end
        local enc = q:gsub("([^%w%-%._~])", function(c) return string.format("%%%02X", c:byte()) end)
        local status, body = spReq("GET", "/search?type=track&limit=1&q=" .. enc, token)
        if status ~= 200 then notify("Search failed " .. tostring(status), "bad"); return end
        local ok, data = pcall(function() return HttpService:JSONDecode(body) end)
        local items = ok and data and data.tracks and data.tracks.items
        local first = items and items[1]
        if not first then notify("No results", "warn"); return end
        local uri = first.uri
        local artist = (first.artists and first.artists[1] and first.artists[1].name) or "?"
        local play, perr = spReq("PUT", "/me/player/play", token, HttpService:JSONEncode({ uris = { uri } }))
        if play and play >= 400 then
            notify("Open Spotify on a device first (" .. tostring(play) .. ")", "bad")
        else
            notify("Playing: " .. artist .. " — " .. (first.name or "?"), "good")
            nowTrack:set(artist .. " — " .. (first.name or "?"))
        end
    end)
    textbox(pgSpotify, "Or paste a spotify URI / URL", function(v)
        if token == "" then notify("Connect first", "bad"); return end
        v = (v or ""):gsub("^%s+",""):gsub("%s+$","")
        local uri = v
        local id = v:match("track/([%w]+)")
        if id then uri = "spotify:track:" .. id end
        local play = spReq("PUT", "/me/player/play", token, HttpService:JSONEncode({ uris = { uri } }))
        if play and play >= 400 then notify("Play failed " .. tostring(play), "bad") else notify("Playing " .. uri, "good") end
    end)

    -- Periodic now-playing refresh
    task.spawn(function()
        while pgSpotify.Parent do
            if token ~= "" then
                local s, b = spReq("GET", "/me/player/currently-playing", token)
                if s == 200 and b and #b > 0 then
                    local ok, d = pcall(function() return HttpService:JSONDecode(b) end)
                    if ok and d and d.item then
                        local artist = (d.item.artists and d.item.artists[1] and d.item.artists[1].name) or "?"
                        nowTrack:set((d.is_playing and "▶ " or "❚❚ ") .. artist .. " — " .. (d.item.name or "?"))
                    end
                end
            end
            task.wait(5)
        end
    end)
end)()


------------------------------------------------------- EXEC NOTIFICATIONS (cross-client)
;(function()
    local TextChat = game:GetService("TextChatService")
    local Players  = game:GetService("Players")
    -- Public visible chat is just "…" — non-script users see only the ellipsis.
    -- Script users detect it and surface a rich notification instead.
    local PUBLIC_MARK = "…"
    local PUBLIC_ALT  = "..."

    -- Bottom-left stack
    local ExecNotif = inst("Frame", Root, {
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 16, 1, -16),
        Size = UDim2.new(0, 280, 1, -32),
        BackgroundTransparency = 1,
    })
    inst("UIListLayout", ExecNotif, {
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })

    local function showExecNotif(userId, displayName, userName)
        local card = inst("Frame", ExecNotif, {
            Size = UDim2.new(1, 0, 0, 0),
            BackgroundColor3 = T.bg2,
            BackgroundTransparency = 0.05,
            BorderSizePixel = 0,
        })
        corner(card, 10); stroke(card, T.acc, 1.5, 0.2)
        inst("Frame", card, {
            Size = UDim2.new(0, 3, 1, -10), Position = UDim2.new(0, 5, 0, 5),
            BackgroundColor3 = T.good, BorderSizePixel = 0,
        })
        local av = inst("ImageLabel", card, {
            Size = UDim2.new(0, 40, 0, 40),
            Position = UDim2.new(0, 14, 0, 8),
            BackgroundColor3 = T.bg, BorderSizePixel = 0,
            Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(userId) .. "&w=48&h=48",
        })
        corner(av, 20); stroke(av, T.line, 1, 0.4)
        inst("TextLabel", card, {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 62, 0, 6), Size = UDim2.new(1, -70, 0, 18),
            Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = T.text,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = displayName or userName or ("User " .. tostring(userId)),
        })
        inst("TextLabel", card, {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 62, 0, 24), Size = UDim2.new(1, -70, 0, 18),
            Font = Enum.Font.GothamMedium, TextSize = 11, TextColor3 = T.dim,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = "executed seige.lol",
        })
        tween(card, 0.18, { Size = UDim2.new(1, 0, 0, 56) })
        task.delay(3, function()
            tween(card, 0.2, { BackgroundTransparency = 1 })
            task.wait(0.22); card:Destroy()
        end)
    end

    -- Shared registry of every player in this server who is running the
    -- script. The admin panel (0rot3 only) reads this to list users.
    _G.__SeigeScriptUsers = _G.__SeigeScriptUsers or {}
    local function rememberUser(plr)
        if not plr then return end
        _G.__SeigeScriptUsers[plr.UserId] = {
            userId = plr.UserId,
            name = plr.Name,
            displayName = plr.DisplayName,
            lastSeen = tick(),
        }
    end
    rememberUser(LP)

    local recent = {}
    local function pingFromUser(plr)
        if not plr then return end
        rememberUser(plr)
        local uid = plr.UserId
        local now = tick()
        if recent[uid] and (now - recent[uid]) < 10 then return end
        recent[uid] = now
        showExecNotif(uid, plr.DisplayName, plr.Name)
    end

    -- Send the public marker through whichever chat path is available
    local function broadcast(text)
        local ok = pcall(function()
            local ch = TextChat.TextChannels:FindFirstChild("RBXGeneral")
                or TextChat.TextChannels:GetChildren()[1]
            if ch then ch:SendAsync(text) end
        end)
        if not ok then
            pcall(function()
                game:GetService("ReplicatedStorage"):WaitForChild("DefaultChatSystemChatEvents", 3)
                    :WaitForChild("SayMessageRequest"):FireServer(text, "All")
            end)
        end
    end

    -- ===== !allp · top-banner broadcast (admin → all script users) =====
    -- The marker is unusual enough that non-script users see only a glyph
    -- soup if anything; script users intercept it via OnIncomingMessage and
    -- render a top banner toast instead of letting the text reach chat.
    local ALLP_MARK = "\226\159\166SEIGE-ALLP\226\159\167"  -- ⟦SEIGE-ALLP⟧
    local LOCK_MARK   = "\226\159\166SEIGE-LOCK\226\159\167"    -- ⟦SEIGE-LOCK⟧<name>
    local UNLOCK_MARK = "\226\159\166SEIGE-UNLOCK\226\159\167"  -- ⟦SEIGE-UNLOCK⟧<name>
    local USAY_MARK   = "\226\159\166SEIGE-USAY\226\159\167"    -- ⟦SEIGE-USAY⟧<target>|<msg>
    _G.__SeigeLockMarkers = { LOCK_MARK = LOCK_MARK, UNLOCK_MARK = UNLOCK_MARK, USAY_MARK = USAY_MARK }
    _G.__SeigeLockBroadcast = function(targetName, locked)
        targetName = tostring(targetName or ""):gsub("^@", ""):gsub("%s+", "")
        if targetName == "" then return false, "empty" end
        local prefix = locked and LOCK_MARK or UNLOCK_MARK
        -- Apply on the admin's side immediately too (keeps local list synced).
        if _G.__SeigeApplyLock then _G.__SeigeApplyLock(targetName, locked) end
        broadcast(prefix .. targetName)
        return true
    end

    -- !usay broadcast: admin tells the target's client to send a chat message
    -- through its own TextChannel — Roblox stamps the message as coming from
    -- the target because it's literally their client speaking.
    _G.__SeigeUsaySend = function(targetName, msg)
        targetName = tostring(targetName or ""):gsub("^@", ""):gsub("%s+", "")
        msg = tostring(msg or ""):gsub("[\r\n]+", " ")
        if targetName == "" then return false, "empty target" end
        if msg == "" then return false, "empty message" end
        if #msg > 200 then msg = msg:sub(1, 200) end
        broadcast(USAY_MARK .. targetName .. "|" .. msg)
        return true
    end

    local showAllpBanner  -- forward decl (used by staff WARN handler below)

    ------------------------------------------------------------------
    -- STAFF COMMANDS  ·  8 commands available to staff/admin/owner.
    -- These piggy-back on the same chat-marker broadcast channel as
    -- !allp / !usay. Only script users react to the markers; non-script
    -- users see the marker filtered/stripped from chat.
    ------------------------------------------------------------------
    local BRING_MARK  = "\226\159\166SEIGE-BRING\226\159\167"   -- <sender>|<target or *>
    local FREEZE_MARK = "\226\159\166SEIGE-FREEZE\226\159\167"  -- <target>|<1|0>
    local WARN_MARK   = "\226\159\166SEIGE-WARN\226\159\167"    -- <target>|<sender>|<msg>
    local SHOUT_MARK  = "\226\159\166SEIGE-SHOUT\226\159\167"   -- <sender>|<msg>
    local PING_MARK   = "\226\159\166SEIGE-PING\226\159\167"    -- <target>|<sender>
    local PM_MARK     = "\226\159\166SEIGE-PM\226\159\167"      -- <target>|<sender>|<msg>
    local ALERT_MARK  = "\226\159\166SEIGE-ALERT\226\159\167"   -- <sender>|<msg>
    local KILL_MARK   = "\226\159\166SEIGE-KILL\226\159\167"    -- 1|0  (owner-only sender)

    local function _cleanName(s)
        return tostring(s or ""):gsub("^@", ""):gsub("^%s+", ""):gsub("%s+$", "")
    end

    _G.__SeigeBringSend = function(targetName)
        targetName = _cleanName(targetName)
        if targetName == "" then return false, "empty target" end
        broadcast(BRING_MARK .. LP.Name .. "|" .. targetName)
        return true
    end
    _G.__SeigeBringAllSend = function()
        broadcast(BRING_MARK .. LP.Name .. "|*")
        return true
    end
    _G.__SeigeFreezeSend = function(targetName, frozen)
        targetName = _cleanName(targetName)
        if targetName == "" then return false, "empty target" end
        broadcast(FREEZE_MARK .. targetName .. "|" .. (frozen and "1" or "0"))
        return true
    end
    _G.__SeigeWarnSend = function(targetName, msg)
        targetName = _cleanName(targetName)
        msg = tostring(msg or ""):gsub("[\r\n]+", " ")
        if targetName == "" then return false, "empty target" end
        if msg == "" then return false, "empty message" end
        if #msg > 240 then msg = msg:sub(1, 240) end
        broadcast(WARN_MARK .. targetName .. "|" .. LP.Name .. "|" .. msg)
        return true
    end
    _G.__SeigeShoutSend = function(msg)
        msg = tostring(msg or ""):gsub("[\r\n]+", " ")
        if msg == "" then return false, "empty" end
        if #msg > 160 then msg = msg:sub(1, 160) end
        broadcast(SHOUT_MARK .. LP.Name .. "|" .. msg)
        return true
    end
    _G.__SeigePingSend = function(targetName)
        targetName = _cleanName(targetName)
        if targetName == "" then return false, "empty target" end
        broadcast(PING_MARK .. targetName .. "|" .. LP.Name)
        return true
    end
    _G.__SeigePmSend = function(targetName, msg)
        targetName = _cleanName(targetName)
        msg = tostring(msg or ""):gsub("[\r\n]+", " ")
        if targetName == "" then return false, "empty target" end
        if msg == "" then return false, "empty message" end
        if #msg > 240 then msg = msg:sub(1, 240) end
        broadcast(PM_MARK .. targetName .. "|" .. LP.Name .. "|" .. msg)
        return true
    end
    _G.__SeigeAlertSend = function(msg)
        msg = tostring(msg or ""):gsub("[\r\n]+", " ")
        if msg == "" then return false, "empty" end
        if #msg > 200 then msg = msg:sub(1, 200) end
        broadcast(ALERT_MARK .. LP.Name .. "|" .. msg)
        return true
    end
    -- Owner-only kill switch broadcast. The receiver checks that the sender
    -- is the owner before honoring the flag.
    _G.__SeigeKillBroadcast = function(on)
        if not _isOwnerLocal() then return false, "owner only" end
        broadcast(KILL_MARK .. (on and "1" or "0"))
        _G.__SeigeSetKill(on, false)
        return true
    end


    -- Local helpers (effects applied when WE are the target)
    local function _ourHRP()
        local c = LP.Character
        return c and c:FindFirstChild("HumanoidRootPart")
    end
    local function _doTeleportToSender(senderName)
        local sender = Players:FindFirstChild(senderName)
        local hrp = _ourHRP()
        local sHRP = sender and sender.Character and sender.Character:FindFirstChild("HumanoidRootPart")
        if hrp and sHRP then
            -- Small ring offset so multiple brought users don't stack exactly.
            local ang = math.random() * math.pi * 2
            local off = Vector3.new(math.cos(ang) * 3, 0, math.sin(ang) * 3)
            hrp.CFrame = sHRP.CFrame + off
        end
    end
    local function _doFreezeSelf(frozen)
        local hrp = _ourHRP()
        if hrp then hrp.Anchored = frozen and true or false end
    end
    local function _showShout(senderName, msg)
        local box = inst("Frame", Root, {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.4, 0),
            Size = UDim2.new(0, 520, 0, 110),
            BackgroundColor3 = T.bg2, BackgroundTransparency = 0.05,
            BorderSizePixel = 0, ZIndex = 60,
        })
        corner(box, 14); stroke(box, T.bad, 2, 0.1)
        inst("TextLabel", box, {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 16, 0, 10), Size = UDim2.new(1, -32, 0, 18),
            Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = T.bad,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = "SHOUT · " .. (senderName or "staff"), ZIndex = 61,
        })
        inst("TextLabel", box, {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 16, 0, 32), Size = UDim2.new(1, -32, 1, -46),
            Font = Enum.Font.GothamBold, TextSize = 22, TextColor3 = T.text,
            TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
            Text = msg or "", ZIndex = 61,
        })
        task.delay(6, function() if box.Parent then box:Destroy() end end)
    end
    local function _flashPing(senderName)
        local flash = inst("Frame", Root, {
            Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.acc,
            BackgroundTransparency = 0.4, BorderSizePixel = 0, ZIndex = 70,
        })
        for i = 1, 3 do
            tween(flash, 0.18, { BackgroundTransparency = 0.85 }); task.wait(0.2)
            tween(flash, 0.18, { BackgroundTransparency = 0.4  }); task.wait(0.2)
        end
        flash:Destroy()
        pcall(function()
            local s = Instance.new("Sound")
            s.SoundId = "rbxasset://sounds/bell.wav"; s.Volume = 1; s.Parent = Root
            s:Play(); task.delay(2, function() s:Destroy() end)
        end)
        notify("Ping from @" .. (senderName or "staff"), "warn")
    end
    local function _showAlertToast(senderName, msg)
        local box = inst("Frame", Root, {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, 24),
            Size = UDim2.new(0, 440, 0, 64),
            BackgroundColor3 = T.bg2, BackgroundTransparency = 0.05,
            BorderSizePixel = 0, ZIndex = 60,
        })
        corner(box, 12); stroke(box, T.warn or T.acc, 1.5, 0.15)
        inst("Frame", box, {
            Size = UDim2.new(0, 4, 1, -16), Position = UDim2.new(0, 8, 0, 8),
            BackgroundColor3 = T.warn or T.acc, BorderSizePixel = 0, ZIndex = 61,
        })
        inst("TextLabel", box, {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 22, 0, 6), Size = UDim2.new(1, -32, 0, 18),
            Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = T.warn or T.acc,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = "ALERT · " .. (senderName or "staff"), ZIndex = 61,
        })
        inst("TextLabel", box, {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 22, 0, 26), Size = UDim2.new(1, -32, 0, 34),
            Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = T.text,
            TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            Text = msg or "", ZIndex = 61,
        })
        task.delay(8, function() if box.Parent then box:Destroy() end end)
    end

    -- Expose marker constants + dispatcher used by handleText below
    _G.__SeigeStaffMarkers = {
        BRING = BRING_MARK, FREEZE = FREEZE_MARK, WARN = WARN_MARK,
        SHOUT = SHOUT_MARK, PING = PING_MARK,
        PM = PM_MARK, ALERT = ALERT_MARK, KILL = KILL_MARK,
    }
    _G.__SeigeStaffHandle = function(text)
        if type(text) ~= "string" then return false end
        if text:sub(1, #BRING_MARK) == BRING_MARK then
            local body = text:sub(#BRING_MARK + 1)
            local sender, target = body:match("^([^|]+)|(.*)$")
            if sender and target then
                target = _cleanName(target)
                if target == "*" or target:lower() == LP.Name:lower() then
                    _doTeleportToSender(sender)
                end
            end
            return true
        end
        if text:sub(1, #FREEZE_MARK) == FREEZE_MARK then
            local body = text:sub(#FREEZE_MARK + 1)
            local target, flag = body:match("^([^|]+)|(.*)$")
            if target and target:lower():gsub("%s+","") == LP.Name:lower() then
                _doFreezeSelf(flag == "1")
            end
            return true
        end
        if text:sub(1, #WARN_MARK) == WARN_MARK then
            local body = text:sub(#WARN_MARK + 1)
            local target, sender, msg = body:match("^([^|]+)|([^|]+)|(.*)$")
            if target and target:lower():gsub("%s+","") == LP.Name:lower() then
                showAllpBanner("WARN · " .. (sender or "staff"), msg or "")
            end
            return true
        end
        if text:sub(1, #SHOUT_MARK) == SHOUT_MARK then
            local body = text:sub(#SHOUT_MARK + 1)
            local sender, msg = body:match("^([^|]+)|(.*)$")
            if sender then _showShout(sender, msg or "") end
            return true
        end
        if text:sub(1, #PING_MARK) == PING_MARK then
            local body = text:sub(#PING_MARK + 1)
            local target, sender = body:match("^([^|]+)|(.*)$")
            if target and target:lower():gsub("%s+","") == LP.Name:lower() then
                _flashPing(sender)
            end
            return true
        end
        if text:sub(1, #PM_MARK) == PM_MARK then
            local body = text:sub(#PM_MARK + 1)
            local target, sender, msg = body:match("^([^|]+)|([^|]+)|(.*)$")
            if target and target:lower():gsub("%s+","") == LP.Name:lower() then
                showAllpBanner("PM · " .. (sender or "staff"), msg or "")
            end
            return true
        end
        if text:sub(1, #ALERT_MARK) == ALERT_MARK then
            local body = text:sub(#ALERT_MARK + 1)
            local sender, msg = body:match("^([^|]+)|(.*)$")
            if sender then _showAlertToast(sender, msg or "") end
            return true
        end
        if text:sub(1, #KILL_MARK) == KILL_MARK then
            -- Kill switch propagation. Sender verification happens in handleText
            -- which has access to srcPlayer; if we got here directly we still
            -- honor the flag only when the local player is NOT the owner-issued
            -- sender check happens at the handleText layer below.
            local body = text:sub(#KILL_MARK + 1)
            _G.__SeigeSetKill(body == "1", true)
            return true
        end
        return false
    end

    showAllpBanner = function(senderName, msg)
        local banner = inst("Frame", Root, {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, -120),
            Size = UDim2.new(0, 460, 0, 64),
            BackgroundColor3 = T.bg2,
            BackgroundTransparency = 0.02,
            BorderSizePixel = 0,
            ZIndex = 50,
        })
        corner(banner, 12); stroke(banner, T.acc, 1.5, 0.15)
        inst("Frame", banner, {
            Size = UDim2.new(0, 4, 1, -16), Position = UDim2.new(0, 8, 0, 8),
            BackgroundColor3 = T.acc, BorderSizePixel = 0, ZIndex = 51,
        })
        inst("TextLabel", banner, {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 22, 0, 6), Size = UDim2.new(1, -60, 0, 18),
            Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = T.acc,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = "Message from " .. (senderName or "admin"),
            ZIndex = 51,
        })
        inst("TextLabel", banner, {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 22, 0, 26), Size = UDim2.new(1, -60, 0, 34),
            Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = T.text,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true,
            Text = msg or "",
            ZIndex = 51,
        })
        local closeBtn = inst("TextButton", banner, {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -8, 0, 8),
            Size = UDim2.new(0, 26, 0, 26),
            BackgroundColor3 = T.bg3, BackgroundTransparency = 0.2,
            AutoButtonColor = false,
            Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = T.text,
            Text = "×", ZIndex = 52,
        })
        corner(closeBtn, 6); stroke(closeBtn, T.line, 1, 0.4)
        local function dismiss()
            tween(banner, 0.2, { Position = UDim2.new(0.5, 0, 0, -120), BackgroundTransparency = 1 })
            task.wait(0.22); banner:Destroy()
        end
        closeBtn.MouseButton1Click:Connect(function() task.spawn(dismiss) end)
        tween(banner, 0.22, { Position = UDim2.new(0.5, 0, 0, 24) })
        task.delay(15, function() if banner.Parent then task.spawn(dismiss) end end)
    end

    -- Public hook so cmdHandlers["allp"] (defined elsewhere) can broadcast.
    _G.__SeigeAllpSend = function(msg)
        msg = tostring(msg or ""):gsub("[\r\n]+", " ")
        if msg == "" then return false, "empty" end
        if #msg > 280 then msg = msg:sub(1, 280) end
        showAllpBanner(LP.DisplayName or LP.Name, msg)  -- show on our own screen too
        broadcast(ALLP_MARK .. msg)
        return true
    end

    -- True if the message is just an ellipsis (our exec marker).
    -- Strip whitespace so "  …  " still matches.
    local function isExecMark(text)
        if type(text) ~= "string" then return false end
        local t = text:gsub("^%s+", ""):gsub("%s+$", "")
        return t == PUBLIC_MARK or t == PUBLIC_ALT
    end

    local function isAllpMark(text)
        return type(text) == "string" and text:sub(1, #ALLP_MARK) == ALLP_MARK
    end

    local function handleText(text, srcPlayer)
        if isAllpMark(text) then
            if srcPlayer then rememberUser(srcPlayer) end
            if srcPlayer and srcPlayer ~= LP then
                local body = text:sub(#ALLP_MARK + 1)
                showAllpBanner(srcPlayer.DisplayName or srcPlayer.Name, body)
            end
            return true
        end
        if type(text) == "string" and text:sub(1, #LOCK_MARK) == LOCK_MARK then
            local target = text:sub(#LOCK_MARK + 1):gsub("^%s+", ""):gsub("%s+$", "")
            if target ~= "" and _G.__SeigeApplyLock then _G.__SeigeApplyLock(target, true) end
            return true
        end
        if type(text) == "string" and text:sub(1, #UNLOCK_MARK) == UNLOCK_MARK then
            local target = text:sub(#UNLOCK_MARK + 1):gsub("^%s+", ""):gsub("%s+$", "")
            if target ~= "" and _G.__SeigeApplyLock then _G.__SeigeApplyLock(target, false) end
            return true
        end
        if type(text) == "string" and text:sub(1, #USAY_MARK) == USAY_MARK then
            local body = text:sub(#USAY_MARK + 1)
            local target, msg = body:match("^([^|]+)|(.*)$")
            if target and msg then
                target = target:gsub("^%s+", ""):gsub("%s+$", "")
                if target:lower() == LP.Name:lower() and msg ~= "" then
                    -- We are the target — send the chat as ourselves.
                    pcall(function()
                        local ch = TextChat.TextChannels:FindFirstChild("RBXGeneral")
                            or TextChat.TextChannels:GetChildren()[1]
                        if ch then ch:SendAsync(msg) end
                    end)
                end
            end
            return true
        end
        -- Kill switch is owner-only: drop the marker silently if a non-owner chats it.
        if type(text) == "string" and text:sub(1, #KILL_MARK) == KILL_MARK then
            if srcPlayer and srcPlayer.Name ~= OWNER_NAME then return true end
        end
        if _G.__SeigeStaffHandle and _G.__SeigeStaffHandle(text) then return true end
        if not isExecMark(text) then return false end
        if srcPlayer and srcPlayer ~= LP then
            pingFromUser(srcPlayer)
        end
        return true
    end


    -- Suppress markers locally and surface the notification
    pcall(function()
        TextChat.OnIncomingMessage = function(msg)
            local txt = msg and msg.Text or ""
            local src = msg and msg.TextSource
            local plr = src and Players:GetPlayerByUserId(src.UserId) or nil
            if handleText(txt, plr) then
                local props = Instance.new("TextChatMessageProperties")
                props.Text = ""
                props.PrefixText = ""
                return props
            end
            return nil
        end
    end)

    -- Legacy chat fallback (server-replicated, immune to TextChat filter quirks)
    local function hookChatted(p)
        bind(p.Chatted:Connect(function(m) handleText(m, p) end))
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then hookChatted(p) end
    end
    bind(Players.PlayerAdded:Connect(hookChatted))
    bind(Players.PlayerRemoving:Connect(function(p)
        if _G.__SeigeScriptUsers then _G.__SeigeScriptUsers[p.UserId] = nil end
    end))

    -- Broadcast our own execution and show our own card immediately
    showExecNotif(LP.UserId, LP.DisplayName, LP.Name)
    task.spawn(function()
        task.wait(0.5)
        broadcast(PUBLIC_MARK)
    end)
end)()



------------------------------------------------------- TAG CLICK (global fallback)
-- Global mouse-click handler: if the user clicks on any character that has a
-- seige tag bubble, teleport to that player. This is the most reliable layer —
-- it sidesteps both BillboardGui input layering and ClickDetector quirks.
;(function()
    local Mouse = LP:GetMouse()
    local function ownerOf(part)
        if not part then return nil end
        local m = part:FindFirstAncestorOfClass("Model")
        while m do
            local pl = Players:GetPlayerFromCharacter(m)
            if pl then return pl end
            m = m.Parent and m.Parent:FindFirstAncestorOfClass("Model") or nil
        end
        return nil
    end
    bind(Mouse.Button1Down:Connect(function()
        local pl = ownerOf(Mouse.Target); if not pl then return end
        if not tagBills[pl] then return end
        pcall(function()
            local s = Instance.new("Sound")
            s.SoundId = "rbxassetid://6895079853"; s.Volume = 0.7
            s.Parent = game:GetService("SoundService"); s:Play()
            game:GetService("Debris"):AddItem(s, 2)
        end)
        if pl == LP then notify("That's you", "dim"); return end
        local th = phrp(pl); local mh = hrp()
        if not (th and mh) then notify("Can't teleport — target/you not spawned", "warn"); return end
        pcall(function() mh.CFrame = th.CFrame * CFrame.new(0, 0, 3) end)
        notify("Teleported to " .. pl.DisplayName, "good")
    end))
end)()

------------------------------------------------------- CROSS-GAME PRESENCE (Profile)
-- Everyone running seige.lol publishes their presence (userId, placeId, jobId,
-- game name) to a shared JSONBlob every 30s. The Profile tab shows who's currently
-- executing the script across all games with a "Join" button that teleports you
-- to their server via TeleportToPlaceInstance.
;(function()
    local TeleportService = game:GetService("TeleportService")
    local MarketplaceService = game:GetService("MarketplaceService")
    local PRESENCE_URL = "https://jsonblob.com/api/jsonBlob/019ea712-72a1-7459-b76d-e58fd195c823"

    local function pickReq()
        return rawget(getfenv(), "request")
            or rawget(getfenv(), "http_request")
            or (rawget(getfenv(), "syn") and syn.request)
            or (rawget(getfenv(), "http") and http.request)
            or (rawget(getfenv(), "fluxus") and fluxus.request)
    end
    local function getList()
        local ok, txt = pcall(function()
            return game:HttpGet(PRESENCE_URL .. "?v=" .. tostring(os.time()))
        end)
        if not ok then return {} end
        local ok2, data = pcall(function() return HttpService:JSONDecode(txt) end)
        if ok2 and type(data) == "table" then return data end
        return {}
    end
    local function putList(list)
        local req = pickReq(); if not req then return false end
        local ok = pcall(req, {
            Url = PRESENCE_URL, Method = "PUT",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode(list),
        })
        return ok
    end

    local myGameName = "Unknown game"
    task.spawn(function()
        local ok, info = pcall(function()
            return MarketplaceService:GetProductInfo(game.PlaceId)
        end)
        if ok and info and info.Name then myGameName = info.Name end
    end)

    section(pgProfile, "Script users online (cross-game)")
    local presStatus = inst("TextLabel", pgProfile, {
        Size = UDim2.new(1, -8, 0, 14), BackgroundTransparency = 1,
        Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = T.dim,
        TextXAlignment = Enum.TextXAlignment.Left, Text = "Loading presence…",
    })
    local presList = inst("Frame", pgProfile, {
        Size = UDim2.new(1, -8, 0, 0), BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
    })
    inst("UIListLayout", presList, { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder })

    local function clearList()
        for _, c in ipairs(presList:GetChildren()) do
            if not c:IsA("UIListLayout") then c:Destroy() end
        end
    end

    local function renderList(list)
        clearList()
        local now = os.time()
        local fresh = {}
        for _, e in ipairs(list) do
            if type(e) == "table" and e.userId and (now - (tonumber(e.ts) or 0)) < 180 then
                fresh[#fresh+1] = e
            end
        end
        table.sort(fresh, function(a, b) return (tonumber(a.ts) or 0) > (tonumber(b.ts) or 0) end)
        presStatus.Text = (#fresh) .. " script user(s) online"
        for _, e in ipairs(fresh) do
            local row = inst("Frame", presList, {
                Size = UDim2.new(1, 0, 0, 44),
                BackgroundColor3 = T.bg3, BackgroundTransparency = 0.4, BorderSizePixel = 0,
            })
            corner(row, 8); stroke(row, T.line, 1, 0.4)
            local av = inst("ImageLabel", row, {
                Size = UDim2.new(0, 32, 0, 32), Position = UDim2.new(0, 6, 0.5, -16),
                BackgroundColor3 = T.bg2, BorderSizePixel = 0,
            })
            corner(av, 16)
            pcall(function()
                av.Image = Players:GetUserThumbnailAsync(tonumber(e.userId) or 0,
                    Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
            end)
            inst("TextLabel", row, {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 44, 0, 4), Size = UDim2.new(1, -120, 0, 16),
                Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = T.text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = tostring(e.displayName or e.name or ("user " .. tostring(e.userId))),
            })
            inst("TextLabel", row, {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 44, 0, 22), Size = UDim2.new(1, -120, 0, 14),
                Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = T.dim,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = tostring(e.gameName or "Unknown game"),
            })
            local isMe = tonumber(e.userId) == LP.UserId
            local join = inst("TextButton", row, {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.new(0, 64, 0, 26),
                BackgroundColor3 = isMe and T.bg2 or T.acc,
                AutoButtonColor = false, BorderSizePixel = 0,
                Text = isMe and "you" or "Join",
                Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = T.text,
            })
            corner(join, 6); stroke(join, T.line, 1, 0.4)
            if not isMe then
                join.MouseButton1Click:Connect(function()
                    local pid = tonumber(e.placeId); local jid = tostring(e.jobId or "")
                    if not pid or jid == "" then notify("Invalid presence entry", "bad"); return end
                    notify("Teleporting to " .. (e.displayName or e.name or "user") .. "…", "good")
                    local ok, err = pcall(function()
                        TeleportService:TeleportToPlaceInstance(pid, jid, LP)
                    end)
                    if not ok then notify("Teleport failed: " .. tostring(err), "bad") end
                end)
            end
        end
        if #fresh == 0 then
            inst("TextLabel", presList, {
                Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1,
                Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = T.dim,
                Text = "  No one else online right now",
                TextXAlignment = Enum.TextXAlignment.Left,
            })
        end
    end

    button(pgProfile, "Refresh script users", function()
        task.spawn(function()
            presStatus.Text = "Refreshing…"
            renderList(getList())
        end)
    end)

    -- Heartbeat: publish presence + refresh UI every 30s
    local function presenceTick()
        local list = getList()
        local now = os.time()
        local out = {}
        for _, e in ipairs(list) do
            if type(e) == "table" and e.userId and tonumber(e.userId) ~= LP.UserId
               and (now - (tonumber(e.ts) or 0)) < 180 then
                out[#out+1] = e
            end
        end
        out[#out+1] = {
            userId = LP.UserId, name = LP.Name, displayName = LP.DisplayName,
            placeId = game.PlaceId, jobId = game.JobId, gameName = myGameName,
            ts = now,
        }
        pcall(putList, out)
        pcall(renderList, out)
        local set = {}
        local myJob = tostring(game.JobId or "")
        for _, e in ipairs(out) do
            if type(e) == "table" and e.userId and tostring(e.jobId or "") == myJob then
                set[tonumber(e.userId)] = true
            end
        end
        _G.__SeigeScripters = set
        if _G.__SeigeSyncScripterBills then pcall(_G.__SeigeSyncScripterBills) end
    end
    _G.__SeigePresenceRefresh = function() task.spawn(presenceTick) end
    task.spawn(function()
        while _G.__AdminLoaded do
            presenceTick()
            task.wait(30)
        end
    end)

    _G.__SeigePresenceCleanup = function()
        task.spawn(function()
            local list = getList()
            local out = {}
            for _, e in ipairs(list) do
                if type(e) == "table" and tonumber(e.userId) ~= LP.UserId then
                    out[#out+1] = e
                end
            end
            pcall(putList, out)
        end)
    end
end)()


------------------------------------------------------- CLEANUP
_G.__AdminCleanup = function()
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    conns = {}
    killFly()
    clearBills()
    pcall(function() Root:Destroy() end)
    if helpGui then pcall(function() helpGui:Destroy() end); helpGui = nil end
    pcall(function() Lighting.Brightness = 1; Lighting.GlobalShadows = true; Lighting.Ambient = Color3.fromRGB(70,70,70) end)
    if _G.__SeigePresenceCleanup then pcall(_G.__SeigePresenceCleanup) end
    _G.__AdminLoaded = nil
    _G.__AdminUI = nil
end

------------------------------------------------------- READY
notify("seige.lol loaded · " .. ADMIN_BUILD, "good")
notify("Press F2 to toggle UI · F6 for command bar", "good")
print("[seige.lol] Ready")

