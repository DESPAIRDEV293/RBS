-- Roblox Admin (loadstring build) — single-file, client-side, executor-friendly.
-- Usage:  loadstring(game:HttpGet("https://raw.githubusercontent.com/DESPAIRDEV293/roblox-script-buddy/main/admin.lua?v=" .. tostring(os.time())))()
local ADMIN_BUILD = "2026-06-07-floattags-4"

if _G.__AdminCleanup then pcall(_G.__AdminCleanup) end
if _G.__AdminUI then
    if type(_G.__AdminUI) == "table" and _G.__AdminUI.destroy then
        pcall(function() _G.__AdminUI:destroy() end)
    elseif type(_G.__AdminUI) == "table" and _G.__AdminUI.screen then
        pcall(function() _G.__AdminUI.screen:Destroy() end)
    end
end
_G.__AdminLoaded = true
_G.__AdminBuild = ADMIN_BUILD
print("[Admin] Loading build " .. ADMIN_BUILD)

local Players       = game:GetService("Players")
local UIS           = game:GetService("UserInputService")
local RunService    = game:GetService("RunService")
local TweenService  = game:GetService("TweenService")
local Lighting      = game:GetService("Lighting")
local CoreGui       = game:GetService("CoreGui")

local LP = Players.LocalPlayer
local cam = workspace.CurrentCamera

------------------------------------------------------------------- THEME
local T = {
    bg   = Color3.fromRGB(14, 15, 20),
    bg2  = Color3.fromRGB(22, 24, 31),
    bg3  = Color3.fromRGB(32, 36, 46),
    line = Color3.fromRGB(48, 53, 66),
    text = Color3.fromRGB(236, 238, 244),
    sub  = Color3.fromRGB(138, 145, 161),
    acc  = Color3.fromRGB(120, 140, 255),
    acc2 = Color3.fromRGB(90, 110, 230),
    good = Color3.fromRGB(96, 200, 140),
    warn = Color3.fromRGB(230, 180, 80),
    bad  = Color3.fromRGB(235, 90, 105),
}

----------------------------------------------------------------- HELPERS
local function corner(p, r) local c = Instance.new("UICorner", p); c.CornerRadius = UDim.new(0, r or 8); return c end
local function stroke(p, c, t) local s = Instance.new("UIStroke", p); s.Color = c or T.line; s.Thickness = t or 1; return s end
local function pad(p, n) local u = Instance.new("UIPadding", p); u.PaddingTop = UDim.new(0,n); u.PaddingBottom = UDim.new(0,n); u.PaddingLeft = UDim.new(0,n); u.PaddingRight = UDim.new(0,n); return u end
local function text(parent, str, o)
    o = o or {}
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Font = o.bold and Enum.Font.GothamBold or Enum.Font.Gotham
    l.TextSize = o.size or 13; l.TextColor3 = o.color or T.text
    l.TextXAlignment = o.align or Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.Text = str; l.Parent = parent
    l.Size = o.fillX and UDim2.new(1, 0, 0, o.h or 20) or UDim2.new(0, o.w or 0, 0, o.h or 20)
    return l
end
local function drag(handle, target, owner)
    local d, sm, sp
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            d = true; sm = i.Position; sp = target.Position
            i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then d = false end end)
        end
    end)
    local sig = UIS.InputChanged:Connect(function(i)
        if d and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local dd = i.Position - sm
            target.Position = UDim2.new(sp.X.Scale, sp.X.Offset + dd.X, sp.Y.Scale, sp.Y.Offset + dd.Y)
        end
    end)
    if owner and owner.conns then table.insert(owner.conns, sig) end
end
local function resize(grip, target, min, owner)
    local r, sm, ss
    grip.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            r = true; sm = i.Position; ss = target.Size
            i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then r = false end end)
        end
    end)
    local sig = UIS.InputChanged:Connect(function(i)
        if r and i.UserInputType == Enum.UserInputType.MouseMovement then
            local dd = i.Position - sm
            target.Size = UDim2.new(0, math.max(min.X, ss.X.Offset + dd.X), 0, math.max(min.Y, ss.Y.Offset + dd.Y))
        end
    end)
    if owner and owner.conns then table.insert(owner.conns, sig) end
end

local function parentSafe(gui)
    local ok = pcall(function() gui.Parent = CoreGui end)
    if not ok then gui.Parent = LP:WaitForChild("PlayerGui") end
end

--------------------------------------------------------------------- UI
local UI = {}
UI.__index = UI

function UI.new(title, size)
    local self = setmetatable({}, UI)
    self.conns = {}
    local screen = Instance.new("ScreenGui")
    screen.Name = "AdminUI_" .. tostring(math.random(1e6,9e6))
    screen.ResetOnSpawn = false; screen.IgnoreGuiInset = true
    screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    parentSafe(screen)
    self.screen = screen

    local win = Instance.new("Frame", screen)
    win.Size = UDim2.new(0, size.X, 0, size.Y)
    win.Position = UDim2.new(0.5, -size.X/2, 0.5, -size.Y/2)
    win.BackgroundColor3 = T.bg; win.BorderSizePixel = 0
    corner(win, 12); stroke(win)
    self.win = win

    local bar = Instance.new("Frame", win)
    bar.Size = UDim2.new(1, 0, 0, 34); bar.BackgroundColor3 = T.bg2; bar.BorderSizePixel = 0
    corner(bar, 12)
    local mask = Instance.new("Frame", bar)
    mask.Position = UDim2.new(0, 0, 1, -12); mask.Size = UDim2.new(1, 0, 0, 12)
    mask.BackgroundColor3 = T.bg2; mask.BorderSizePixel = 0
    drag(bar, win, self)
    text(bar, title .. "  " .. ADMIN_BUILD, { bold = true, size = 14, h = 34, w = 300 }).Position = UDim2.new(0, 14, 0, 0)

    local function topBtn(sym, x, color)
        local b = Instance.new("TextButton", bar)
        b.Size = UDim2.new(0, 26, 0, 22); b.Position = UDim2.new(1, x, 0, 6)
        b.BackgroundColor3 = T.bg3; b.AutoButtonColor = true
        b.Font = Enum.Font.GothamBold; b.TextSize = 14; b.Text = sym
        b.TextColor3 = color or T.text; corner(b, 6)
        return b
    end
    local minimized = false
    topBtn("X", -34, T.bad).MouseButton1Click:Connect(function() screen.Enabled = false end)
    topBtn("-", -66).MouseButton1Click:Connect(function()
        minimized = not minimized
        win:TweenSize(minimized and UDim2.new(0, size.X, 0, 34) or UDim2.new(0, size.X, 0, size.Y),
            "Out", "Quad", 0.18, true)
    end)

    local tabBar = Instance.new("Frame", win)
    tabBar.Position = UDim2.new(0, 8, 0, 38); tabBar.Size = UDim2.new(1, -16, 0, 26)
    tabBar.BackgroundTransparency = 1
    local tl = Instance.new("UIListLayout", tabBar)
    tl.FillDirection = Enum.FillDirection.Horizontal; tl.Padding = UDim.new(0, 4)
    self.tabBar = tabBar

    local body = Instance.new("Frame", win)
    body.Position = UDim2.new(0, 8, 0, 70); body.Size = UDim2.new(1, -16, 1, -82)
    body.BackgroundTransparency = 1
    self.body = body

    local grip = Instance.new("TextButton", win)
    grip.Size = UDim2.new(0, 14, 0, 14); grip.Position = UDim2.new(1, -16, 1, -16)
    grip.BackgroundColor3 = T.line; grip.Text = ""; grip.AutoButtonColor = false
    corner(grip, 3); resize(grip, win, Vector2.new(340, 260), self)

    local toasts = Instance.new("Frame", screen)
    toasts.AnchorPoint = Vector2.new(1, 1); toasts.Position = UDim2.new(1, -16, 1, -16)
    toasts.Size = UDim2.new(0, 320, 1, -32); toasts.BackgroundTransparency = 1
    local tll = Instance.new("UIListLayout", toasts)
    tll.HorizontalAlignment = Enum.HorizontalAlignment.Right
    tll.VerticalAlignment = Enum.VerticalAlignment.Bottom; tll.Padding = UDim.new(0, 6)
    self.toasts = toasts

    self.tabs = {}; self.cur = nil
    return self
end

function UI:setVisible(v) self.screen.Enabled = v end
function UI:toggle()      self.screen.Enabled = not self.screen.Enabled end
function UI:bind(sig)     table.insert(self.conns, sig); return sig end
function UI:destroy()
    for _, sig in ipairs(self.conns or {}) do pcall(function() sig:Disconnect() end) end
    self.conns = {}
    if self.screen then pcall(function() self.screen:Destroy() end) end
end

function UI:addTab(name)
    local b = Instance.new("TextButton", self.tabBar)
    b.AutomaticSize = Enum.AutomaticSize.X; b.Size = UDim2.new(0, 0, 1, 0)
    b.BackgroundColor3 = T.bg2; b.AutoButtonColor = false
    b.Font = Enum.Font.GothamSemibold; b.TextSize = 12; b.TextColor3 = T.sub
    b.Text = "  " .. name .. "  "; corner(b, 8)
    local panel = Instance.new("ScrollingFrame", self.body)
    panel.Size = UDim2.new(1, 0, 1, 0); panel.BackgroundTransparency = 1
    panel.BorderSizePixel = 0; panel.ScrollBarThickness = 3
    panel.ScrollBarImageColor3 = T.line; panel.CanvasSize = UDim2.new(0,0,0,0)
    panel.AutomaticCanvasSize = Enum.AutomaticSize.Y; panel.Visible = false
    local lay = Instance.new("UIListLayout", panel); lay.Padding = UDim.new(0, 6)
    pad(panel, 4)
    local t = { name = name, btn = b, panel = panel }
    table.insert(self.tabs, t)
    b.MouseButton1Click:Connect(function() self:switchTab(t) end)
    if #self.tabs == 1 then self:switchTab(t) end
    return t
end

function UI:switchTab(tab)
    for _, t in ipairs(self.tabs) do
        local on = t == tab
        t.panel.Visible = on
        TweenService:Create(t.btn, TweenInfo.new(0.15), {
            BackgroundColor3 = on and T.acc or T.bg2,
            TextColor3 = on and Color3.fromRGB(255,255,255) or T.sub,
        }):Play()
    end
    self.cur = tab
end
local function cur(self) return self.cur.panel end

local function rowF(parent, h)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(1, -4, 0, h or 32); f.BackgroundColor3 = T.bg2; f.BorderSizePixel = 0
    corner(f, 8); return f
end

function UI:addSection(title)
    local f = Instance.new("Frame", cur(self))
    f.Size = UDim2.new(1, -4, 0, 26); f.BackgroundTransparency = 1
    local l = text(f, string.upper(title), { bold = true, size = 11, color = T.sub, fillX = true, h = 26 })
    l.Position = UDim2.new(0, 4, 0, 4)
end

function UI:addLabel(t)
    local f = rowF(cur(self), 26); pad(f, 8)
    local l = text(f, t, { fillX = true, size = 13, h = 22 })
    return { set = function(_, v) l.Text = v end }
end

function UI:addButton(label, cb)
    local b = Instance.new("TextButton", cur(self))
    b.Size = UDim2.new(1, -4, 0, 32); b.BackgroundColor3 = T.acc
    b.AutoButtonColor = false; b.Font = Enum.Font.GothamSemibold
    b.TextSize = 13; b.TextColor3 = Color3.fromRGB(255,255,255); b.Text = label
    corner(b, 8)
    b.MouseEnter:Connect(function() TweenService:Create(b, TweenInfo.new(0.12), { BackgroundColor3 = T.acc2 }):Play() end)
    b.MouseLeave:Connect(function() TweenService:Create(b, TweenInfo.new(0.12), { BackgroundColor3 = T.acc }):Play() end)
    b.MouseButton1Click:Connect(function() if cb then cb() end end)
    return b
end

function UI:addToggle(label, default, cb)
    local f = rowF(cur(self), 36); pad(f, 12)
    local l = text(f, label, { size = 13, h = 22, fillX = true }); l.Size = UDim2.new(1, -48, 1, 0)
    local sw = Instance.new("TextButton", f)
    sw.Size = UDim2.new(0, 40, 0, 22); sw.Position = UDim2.new(1, -40, 0.5, -11)
    sw.Text = ""; sw.AutoButtonColor = false
    sw.BackgroundColor3 = default and T.acc or T.bg3; corner(sw, 11)
    local knob = Instance.new("Frame", sw)
    knob.Size = UDim2.new(0, 16, 0, 16); knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
    knob.BorderSizePixel = 0; knob.Position = UDim2.new(0, default and 21 or 3, 0.5, -8); corner(knob, 8)
    local state = default and true or false
    local function update()
        TweenService:Create(sw, TweenInfo.new(0.18, Enum.EasingStyle.Quad), { BackgroundColor3 = state and T.acc or T.bg3 }):Play()
        TweenService:Create(knob, TweenInfo.new(0.18, Enum.EasingStyle.Quad), { Position = UDim2.new(0, state and 21 or 3, 0.5, -8) }):Play()
    end
    sw.MouseButton1Click:Connect(function() state = not state; update(); if cb then cb(state) end end)
    return { get = function() return state end, set = function(_, v) state = v; update(); if cb then cb(state) end end }
end

function UI:addSlider(label, mn, mx, def, cb)
    local f = rowF(cur(self), 62); pad(f, 12)
    local l = text(f, label, { size = 12, h = 20 })
    l.Position = UDim2.new(0, 0, 0, 0); l.Size = UDim2.new(1, -60, 0, 20)
    local v = Instance.new("TextLabel", f)
    v.BackgroundColor3 = T.bg3; v.BorderSizePixel = 0
    v.Font = Enum.Font.GothamSemibold; v.TextSize = 11; v.TextColor3 = T.text
    v.Size = UDim2.new(0, 52, 0, 20); v.Position = UDim2.new(1, -52, 0, 0)
    v.Text = tostring(def); corner(v, 6)
    local tr = Instance.new("Frame", f)
    tr.Size = UDim2.new(1, 0, 0, 6); tr.Position = UDim2.new(0, 0, 1, -8)
    tr.BackgroundColor3 = T.bg3; tr.BorderSizePixel = 0; corner(tr, 3)
    local fill = Instance.new("Frame", tr)
    fill.BackgroundColor3 = T.acc; fill.BorderSizePixel = 0
    fill.Size = UDim2.new((def - mn) / (mx - mn), 0, 1, 0); corner(fill, 3)
    local knob = Instance.new("Frame", tr)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = UDim2.new((def - mn) / (mx - mn), 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.fromRGB(255,255,255); knob.BorderSizePixel = 0
    corner(knob, 7); stroke(knob, T.acc, 2)
    local hit = Instance.new("Frame", tr)
    hit.Size = UDim2.new(1, 0, 0, 22); hit.Position = UDim2.new(0, 0, 0.5, -11)
    hit.BackgroundTransparency = 1; hit.ZIndex = 2
    local dr
    local function setFromX(px)
        local rel = math.clamp((px - tr.AbsolutePosition.X) / tr.AbsoluteSize.X, 0, 1)
        local val = math.floor(mn + (mx - mn) * rel + 0.5)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        knob.Position = UDim2.new(rel, 0, 0.5, 0)
        v.Text = tostring(val); if cb then cb(val) end
    end
    hit.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dr = true; setFromX(i.Position.X)
        end
    end)
    self:bind(UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dr = false end
    end))
    self:bind(UIS.InputChanged:Connect(function(i)
        if dr and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            setFromX(i.Position.X)
        end
    end))
end

function UI:addTextBox(placeholder, cb)
    local f = rowF(cur(self), 32)
    local tb = Instance.new("TextBox", f)
    tb.Size = UDim2.new(1, -16, 1, -8); tb.Position = UDim2.new(0, 8, 0, 4)
    tb.BackgroundColor3 = T.bg3; tb.BorderSizePixel = 0
    tb.Font = Enum.Font.Gotham; tb.TextSize = 13; tb.TextColor3 = T.text
    tb.PlaceholderText = placeholder; tb.Text = ""
    tb.ClearTextOnFocus = false; tb.TextXAlignment = Enum.TextXAlignment.Left
    corner(tb, 6); pad(tb, 6)
    tb.FocusLost:Connect(function(e) if e and cb then cb(tb.Text); tb.Text = "" end end)
    return tb
end

function UI:addDropdown(label, opts, cb)
    local f = rowF(cur(self), 32); pad(f, 10)
    text(f, label, { size = 12, h = 22 }).Size = UDim2.new(1, -120, 1, 0)
    local b = Instance.new("TextButton", f)
    b.Size = UDim2.new(0, 110, 0, 22); b.Position = UDim2.new(1, -110, 0.5, -11)
    b.BackgroundColor3 = T.bg3; b.AutoButtonColor = true
    b.Font = Enum.Font.GothamSemibold; b.TextSize = 12
    b.TextColor3 = T.text; b.Text = opts[1] or "—"; corner(b, 6)
    local i = 1
    b.MouseButton1Click:Connect(function()
        i = (i % #opts) + 1; b.Text = opts[i]; if cb then cb(opts[i]) end
    end)
end

-- Pixel-art tag chips wrapped in a flex row. Returns { addChip = fn(label, cb, isActive), refresh = fn() }
function UI:addTagRow()
    local wrap = Instance.new("Frame", cur(self))
    wrap.Size = UDim2.new(1, -4, 0, 0); wrap.AutomaticSize = Enum.AutomaticSize.Y
    wrap.BackgroundTransparency = 1
    local lay = Instance.new("UIListLayout", wrap)
    lay.FillDirection = Enum.FillDirection.Horizontal
    lay.Wraps = true; lay.SortOrder = Enum.SortOrder.LayoutOrder
    lay.Padding = UDim.new(0, 6)
    local api = {}
    function api.addChip(label, cb, getActive)
        local outer = Instance.new("Frame", wrap)
        outer.BackgroundTransparency = 1
        outer.AutomaticSize = Enum.AutomaticSize.X
        outer.Size = UDim2.new(0, 0, 0, 30)
        -- Pixel shadow (offset solid block, no rounding)
        local shadow = Instance.new("Frame", outer)
        shadow.BackgroundColor3 = Color3.fromRGB(0,0,0)
        shadow.BorderSizePixel = 0
        shadow.Position = UDim2.new(0, 3, 0, 3)
        shadow.Size = UDim2.new(1, -3, 1, -3)
        -- Button
        local b = Instance.new("TextButton", outer)
        b.AutomaticSize = Enum.AutomaticSize.X
        b.Size = UDim2.new(0, 0, 1, -3)
        b.BackgroundColor3 = Color3.fromRGB(255,255,255)
        b.AutoButtonColor = false
        b.Font = Enum.Font.GothamBold; b.TextSize = 12
        b.TextColor3 = Color3.fromRGB(15,15,15)
        b.Text = "  " .. label .. "  "
        corner(b, 6); stroke(b, Color3.fromRGB(0,0,0), 2)
        local padInner = Instance.new("UIPadding", b)
        padInner.PaddingLeft = UDim.new(0, 6); padInner.PaddingRight = UDim.new(0, 6)
        local function paint()
            local active = getActive and getActive()
            if active then
                b.BackgroundColor3 = T.acc
                b.TextColor3 = Color3.fromRGB(255,255,255)
            else
                b.BackgroundColor3 = Color3.fromRGB(255,255,255)
                b.TextColor3 = Color3.fromRGB(15,15,15)
            end
        end
        b.MouseButton1Click:Connect(function() if cb then cb() end; paint() end)
        paint()
        return { paint = paint, button = b }
    end
    function api.repaint() for _, c in ipairs(wrap:GetChildren()) do if c:IsA("Frame") and c:FindFirstChildOfClass("TextButton") then end end end
    return api
end

function UI:addPlayerList(onClick, getBadge)
    -- Container expands with content; outer tab panel handles scrolling.
    local f = Instance.new("Frame", cur(self))
    f.Size = UDim2.new(1, -4, 0, 0); f.AutomaticSize = Enum.AutomaticSize.Y
    f.BackgroundColor3 = T.bg2; f.BorderSizePixel = 0
    corner(f, 8); pad(f, 6)
    local lay = Instance.new("UIListLayout", f); lay.Padding = UDim.new(0, 4)
    local rows = {}
    local function makeRow(p)
        local r = Instance.new("TextButton", f)
        r.Size = UDim2.new(1, 0, 0, 44); r.BackgroundColor3 = T.bg3
        r.AutoButtonColor = false; r.Text = ""; corner(r, 8)
        local img = Instance.new("ImageLabel", r)
        img.Size = UDim2.new(0, 32, 0, 32); img.Position = UDim2.new(0, 6, 0.5, -16)
        img.BackgroundColor3 = T.bg; img.BorderSizePixel = 0; corner(img, 16)
        local ok, url = pcall(function()
            return Players:GetUserThumbnailAsync(p.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
        end)
        if ok then img.Image = url end
        local n = text(r, p.DisplayName, { bold = true, size = 13, h = 18 })
        n.Position = UDim2.new(0, 46, 0, 5); n.Size = UDim2.new(1, -130, 0, 18)
        local s = text(r, "@" .. p.Name, { size = 11, color = T.sub, h = 14 })
        s.Position = UDim2.new(0, 46, 0, 23); s.Size = UDim2.new(1, -130, 0, 14)
        local badge = text(r, "", { size = 11, color = T.sub, h = 18 })
        badge.TextXAlignment = Enum.TextXAlignment.Right
        badge.Position = UDim2.new(1, -84, 0.5, -9); badge.Size = UDim2.new(0, 78, 0, 18)
        if getBadge then badge.Text = getBadge(p) or "" end
        r.MouseEnter:Connect(function() TweenService:Create(r, TweenInfo.new(0.1), { BackgroundColor3 = T.line }):Play() end)
        r.MouseLeave:Connect(function() TweenService:Create(r, TweenInfo.new(0.1), { BackgroundColor3 = T.bg3 }):Play() end)
        r.MouseButton1Click:Connect(function() if onClick then onClick(p) end end)
        return r, badge
    end
    local function refresh()
        for _, c in ipairs(f:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
        rows = {}
        for _, p in ipairs(Players:GetPlayers()) do
            local r, b = makeRow(p); rows[p] = { row = r, badge = b }
        end
    end
    self:bind(Players.PlayerAdded:Connect(refresh)); self:bind(Players.PlayerRemoving:Connect(refresh))
    refresh()
    return {
        refresh = refresh,
        updateBadges = function()
            for p, e in pairs(rows) do if getBadge and e.badge then e.badge.Text = getBadge(p) or "" end end
        end,
    }
end

function UI:notify(msg, kind)
    local color = ({ good = T.good, warn = T.warn, bad = T.bad })[kind] or T.acc
    local f = Instance.new("Frame", self.toasts)
    f.Size = UDim2.new(0, 280, 0, 44); f.BackgroundColor3 = T.bg2; f.BorderSizePixel = 0
    corner(f, 8); stroke(f, color, 1)
    local bar = Instance.new("Frame", f)
    bar.Size = UDim2.new(0, 4, 1, 0); bar.BackgroundColor3 = color; bar.BorderSizePixel = 0; corner(bar, 2)
    local l = text(f, msg, { size = 13 })
    l.Position = UDim2.new(0, 12, 0, 0); l.Size = UDim2.new(1, -16, 1, 0); l.TextWrapped = true
    task.delay(4, function()
        for i = 0, 1, 0.08 do f.BackgroundTransparency = i; l.TextTransparency = i; task.wait(0.02) end
        f:Destroy()
    end)
end

--------------------------------------------------------------- TAG STORE
-- Tags are local: a labelling layer to drive feature filtering.
local Tags = {
    defs = { "Friend", "Target", "Ignore" }, -- editable
    map  = {},                                -- [userId] = { [tag]=true }
    listeners = {},
}
function Tags:get(uid) return self.map[uid] or {} end
function Tags:has(uid, t) local s = self.map[uid]; return s and s[t] == true end
function Tags:onChange(fn) table.insert(self.listeners, fn) end
function Tags:_fire(uid) for _, f in ipairs(self.listeners) do pcall(f, uid) end end
function Tags:add(uid, t)
    if not self.map[uid] then self.map[uid] = {} end
    self.map[uid][t] = true
    local found = false; for _, x in ipairs(self.defs) do if x == t then found = true break end end
    if not found then table.insert(self.defs, t) end
    if uid ~= 0 then self:_fire(uid) end
end
function Tags:remove(uid, t)
    if self.map[uid] then self.map[uid][t] = nil end
    if uid ~= 0 then self:_fire(uid) end
end
function Tags:toggle(uid, t) if self:has(uid, t) then self:remove(uid, t) else self:add(uid, t) end end
function Tags:summary(uid)
    local out = {}; for t in pairs(self:get(uid)) do table.insert(out, t) end
    table.sort(out); return table.concat(out, ",")
end


------------------------------------------------------------------ BUILD
local win = UI.new("Admin", Vector2.new(460, 560))
_G.__AdminUI = win
local tabPlayers = win:addTab("Players")
local tabSelf    = win:addTab("Self")
local tabVis     = win:addTab("Visuals")
local tabWorld   = win:addTab("World")
local tabTags    = win:addTab("Tags")
local tabLogs    = win:addTab("Logs")

local selected -- selected player
local repaintChips -- forward declaration; assigned in the Tags tab setup

-- PLAYERS ----------------------------------------------------------------
win:switchTab(tabPlayers)
win:addSection("Player list")
local selStatus = win:addLabel("No player selected")
local list = win:addPlayerList(
    function(p)
        selected = p
        selStatus:set("Selected: " .. p.DisplayName .. " (@" .. p.Name .. ")")
        if repaintChips then repaintChips() end
        win:notify("Selected " .. p.Name, "good")
    end,
    function(p) return Tags:summary(p.UserId) end
)
win:addSection("Quick actions")
local function ensureSel(fn) return function() if selected then fn(selected) else win:notify("Select a player first", "warn") end end end

local function root(p) local c = p.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function hum(p)  local c = p.Character; return c and c:FindFirstChildOfClass("Humanoid") end

win:addButton("Teleport to selected", ensureSel(function(p)
    local r = root(p); local me = root(LP)
    if r and me then me.CFrame = r.CFrame + Vector3.new(0,3,0) end
end))
win:addButton("Spectate selected", ensureSel(function(p)
    if p.Character and p.Character:FindFirstChildOfClass("Humanoid") then
        cam.CameraSubject = p.Character:FindFirstChildOfClass("Humanoid")
        win:notify("Spectating " .. p.Name, "good")
    end
end))
win:addButton("Stop spectating", function()
    if LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") then
        cam.CameraSubject = LP.Character:FindFirstChildOfClass("Humanoid")
    end
end)
win:addButton("Copy username", ensureSel(function(p)
    if setclipboard then setclipboard(p.Name); win:notify("Copied @" .. p.Name, "good") else win:notify("setclipboard not supported", "bad") end
end))

-- SELF -------------------------------------------------------------------
win:switchTab(tabSelf)
win:addSection("Movement")
local ws, jp = 16, 50
win:addSlider("Walk speed", 16, 200, 16, function(v) ws = v; local h = hum(LP); if h then h.WalkSpeed = v end end)
win:addSlider("Jump power", 50, 500, 50, function(v) jp = v; local h = hum(LP); if h then h.JumpPower = v end end)
local infJump = false
win:addToggle("Infinite jump", false, function(s) infJump = s end)
win:bind(UIS.JumpRequest:Connect(function() if infJump then local h = hum(LP); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end end))

local flying, bv, bg
local function stopFly() flying = false; if bv then bv:Destroy() bv=nil end; if bg then bg:Destroy() bg=nil end end
local function startFly()
    local hrp = root(LP); if not hrp then return end
    stopFly(); flying = true
    bv = Instance.new("BodyVelocity", hrp); bv.MaxForce = Vector3.new(1e6,1e6,1e6); bv.Velocity = Vector3.zero
    bg = Instance.new("BodyGyro", hrp); bg.MaxTorque = Vector3.new(1e6,1e6,1e6); bg.P = 1e4
end
local flySpeed = 60
win:addToggle("Fly (WASD / Space / Ctrl)", false, function(s) if s then startFly() else stopFly() end end)
win:addSlider("Fly speed", 20, 250, 60, function(v) flySpeed = v end)

local noclip = false
win:addToggle("Noclip", false, function(s) noclip = s end)

win:bind(RunService.Stepped:Connect(function()
    if flying and bv then
        local d = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then d += cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then d -= cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then d -= cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then d += cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then d += Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then d -= Vector3.new(0,1,0) end
        bv.Velocity = d.Magnitude > 0 and d.Unit * flySpeed or Vector3.zero
        if bg then bg.CFrame = cam.CFrame end
    end
    if noclip and LP.Character then
        for _, part in ipairs(LP.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end))
win:bind(LP.CharacterAdded:Connect(function(c)
    stopFly()
    local h = c:WaitForChild("Humanoid"); h.WalkSpeed = ws; h.JumpPower = jp
end))

win:addSection("Utility")
win:addButton("Reset character", function() LP.Character:BreakJoints() end)
win:addButton("Click-teleport (click anywhere)", function()
    win:notify("Next click teleports you", "good")
    local m = LP:GetMouse()
    local c; c = m.Button1Down:Connect(function()
        c:Disconnect()
        if m.Hit then local r = root(LP); if r then r.CFrame = CFrame.new(m.Hit.Position + Vector3.new(0,3,0)) end end
    end)
end)

-- VISUALS ----------------------------------------------------------------
win:switchTab(tabVis)
win:addSection("ESP")
local espEnabled = false
local espFilter = "All"
local espBoxes = {} -- [player] = { hl = Highlight, bb = BillboardGui, line = Drawing? }
local function clearEsp()
    for p, e in pairs(espBoxes) do
        if e.hl then e.hl:Destroy() end
        if e.bb then e.bb:Destroy() end
        if e.line then pcall(function() e.line:Remove() end) end
    end
    espBoxes = {}
end
local function colorFor(p)
    if Tags:has(p.UserId, "Friend") then return T.good end
    if Tags:has(p.UserId, "Target") then return T.bad end
    if Tags:has(p.UserId, "Ignore") then return T.sub end
    return T.acc
end
local function shouldEsp(p)
    if p == LP then return false end
    if Tags:has(p.UserId, "Ignore") then return false end
    if espFilter == "Friends" then return Tags:has(p.UserId, "Friend") end
    if espFilter == "Targets" then return Tags:has(p.UserId, "Target") end
    if espFilter == "Tagged"  then return next(Tags:get(p.UserId)) ~= nil end
    return true
end
local function rebuildEsp()
    clearEsp()
    if not espEnabled then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if shouldEsp(p) and p.Character then
            local hl = Instance.new("Highlight")
            hl.Adornee = p.Character
            hl.FillTransparency = 0.7
            hl.OutlineColor = colorFor(p); hl.FillColor = colorFor(p)
            hl.Parent = p.Character
            local head = p.Character:FindFirstChild("Head")
            local bb
            if head then
                bb = Instance.new("BillboardGui")
                bb.Adornee = head; bb.Size = UDim2.new(0, 160, 0, 22)
                bb.StudsOffset = Vector3.new(0, 2.4, 0); bb.AlwaysOnTop = true
                bb.Parent = p.Character
                local lbl = Instance.new("TextLabel", bb)
                lbl.BackgroundTransparency = 1; lbl.Size = UDim2.new(1,0,1,0)
                lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 13
                lbl.TextColor3 = colorFor(p)
                lbl.TextStrokeTransparency = 0.5
                local tagStr = Tags:summary(p.UserId)
                lbl.Text = p.DisplayName .. (tagStr ~= "" and " [" .. tagStr .. "]" or "")
            end
            espBoxes[p] = { hl = hl, bb = bb }
        end
    end
end
win:addToggle("ESP enabled", false, function(s) espEnabled = s; rebuildEsp() end)
win:addDropdown("ESP filter", { "All", "Friends", "Targets", "Tagged" }, function(o) espFilter = o; rebuildEsp() end)
win:addButton("Refresh ESP", rebuildEsp)
local function bindCharacterRefresh(p)
    win:bind(p.CharacterAdded:Connect(function() task.wait(0.5); rebuildEsp() end))
end
win:bind(Players.PlayerAdded:Connect(function(p) bindCharacterRefresh(p) end))
for _, p in ipairs(Players:GetPlayers()) do
    bindCharacterRefresh(p)
end

win:addSection("Floating tags")

-- Per-player BillboardGui above head showing tag chips with a floating animation.
local floatTagsEnabled = true  -- ON by default so tags are visible immediately
local tagBillboards = {} -- [player] = { gui=BillboardGui, label=TextLabel, stroke=UIStroke, base=number }

local function tagDisplayColor(p)
    if Tags:has(p.UserId, "Target") then return T.bad end
    if Tags:has(p.UserId, "Friend") then return T.good end
    if Tags:has(p.UserId, "Ignore") then return T.sub end
    return T.acc
end

local function clearTagBillboards()
    for _, e in pairs(tagBillboards) do if e.gui then e.gui:Destroy() end end
    tagBillboards = {}
end

local function refreshTagBillboardFor(p)
    local entry = tagBillboards[p]
    if not entry then return end
    local tags = Tags:summary(p.UserId)
    if tags == "" then
        entry.gui.Enabled = false
        return
    end
    entry.gui.Enabled = true
    entry.name.Text = p.DisplayName
    entry.handle.Text = "@" .. p.Name
    entry.stat.Text = tags:gsub(",", " • ")
    local c = tagDisplayColor(p)
    entry.stroke.Color = c
    entry.statDot.BackgroundColor3 = c
end

local function buildTagBillboard(p)
    if tagBillboards[p] or not p.Character then return end
    local head = p.Character:FindFirstChild("Head")
    if not head then return end

    local gui = Instance.new("BillboardGui")
    gui.Name = "AdminTagBB"
    gui.Adornee = head
    gui.Size = UDim2.new(0, 260, 0, 56)
    gui.StudsOffsetWorldSpace = Vector3.new(0, 3.2, 0)
    gui.AlwaysOnTop = true
    gui.LightInfluence = 0
    gui.ClipsDescendants = false
    gui.Parent = p.Character

    -- Outer pill
    local bg = Instance.new("Frame", gui)
    bg.Size = UDim2.new(1, 0, 0, 44)
    bg.Position = UDim2.new(0, 0, 0, 6)
    bg.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    bg.BackgroundTransparency = 0.1
    bg.BorderSizePixel = 0
    local corner = Instance.new("UICorner", bg); corner.CornerRadius = UDim.new(1, 0)
    local stroke = Instance.new("UIStroke", bg)
    stroke.Thickness = 1.4
    stroke.Color = T.acc
    stroke.Transparency = 0.25
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    -- Soft inner shadow / gradient
    local grad = Instance.new("UIGradient", bg)
    grad.Rotation = 90
    grad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(34, 34, 42)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 14, 18)),
    }

    -- Avatar circle (left)
    local av = Instance.new("ImageLabel", bg)
    av.Size = UDim2.new(0, 34, 0, 34)
    av.Position = UDim2.new(0, 5, 0.5, -17)
    av.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
    av.BorderSizePixel = 0
    av.ScaleType = Enum.ScaleType.Crop
    local avCorner = Instance.new("UICorner", av); avCorner.CornerRadius = UDim.new(1, 0)
    local avStroke = Instance.new("UIStroke", av)
    avStroke.Thickness = 1
    avStroke.Color = Color3.fromRGB(60, 60, 72)
    pcall(function()
        av.Image = Players:GetUserThumbnailAsync(
            p.UserId,
            Enum.ThumbnailType.HeadShot,
            Enum.ThumbnailSize.Size100x100
        )
    end)

    -- Name (top line)
    local nameLbl = Instance.new("TextLabel", bg)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Position = UDim2.new(0, 46, 0, 4)
    nameLbl.Size = UDim2.new(1, -120, 0, 18)
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 14
    nameLbl.TextColor3 = Color3.fromRGB(245, 245, 250)
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    nameLbl.TextYAlignment = Enum.TextYAlignment.Center
    nameLbl.TextStrokeTransparency = 0.7
    nameLbl.Text = p.DisplayName

    -- Handle (bottom line)
    local handle = Instance.new("TextLabel", bg)
    handle.BackgroundTransparency = 1
    handle.Position = UDim2.new(0, 46, 0, 22)
    handle.Size = UDim2.new(1, -120, 0, 16)
    handle.Font = Enum.Font.Gotham
    handle.TextSize = 11
    handle.TextColor3 = Color3.fromRGB(150, 150, 165)
    handle.TextXAlignment = Enum.TextXAlignment.Left
    handle.TextYAlignment = Enum.TextYAlignment.Center
    handle.Text = "@" .. p.Name

    -- Right stat pill
    local statHolder = Instance.new("Frame", bg)
    statHolder.AnchorPoint = Vector2.new(1, 0.5)
    statHolder.Position = UDim2.new(1, -8, 0.5, 0)
    statHolder.Size = UDim2.new(0, 70, 0, 24)
    statHolder.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
    statHolder.BorderSizePixel = 0
    local sCorner = Instance.new("UICorner", statHolder); sCorner.CornerRadius = UDim.new(1, 0)
    local sStroke = Instance.new("UIStroke", statHolder)
    sStroke.Color = Color3.fromRGB(55, 55, 68); sStroke.Thickness = 1

    local statDot = Instance.new("Frame", statHolder)
    statDot.Size = UDim2.new(0, 6, 0, 6)
    statDot.Position = UDim2.new(0, 8, 0.5, -3)
    statDot.BackgroundColor3 = T.acc
    statDot.BorderSizePixel = 0
    local dCorner = Instance.new("UICorner", statDot); dCorner.CornerRadius = UDim.new(1, 0)

    local statTxt = Instance.new("TextLabel", statHolder)
    statTxt.BackgroundTransparency = 1
    statTxt.Position = UDim2.new(0, 18, 0, 0)
    statTxt.Size = UDim2.new(1, -22, 1, 0)
    statTxt.Font = Enum.Font.GothamBold
    statTxt.TextSize = 11
    statTxt.TextColor3 = Color3.fromRGB(235, 235, 245)
    statTxt.TextXAlignment = Enum.TextXAlignment.Left
    statTxt.TextYAlignment = Enum.TextYAlignment.Center
    statTxt.Text = ""

    tagBillboards[p] = {
        gui = gui, bg = bg, stroke = stroke,
        name = nameLbl, handle = handle,
        stat = statTxt, statDot = statDot,
        base = math.random() * 6.28,
    }
    refreshTagBillboardFor(p)
end


local function rebuildTagBillboards()
    clearTagBillboards()
    if not floatTagsEnabled then return end
    for _, p in ipairs(Players:GetPlayers()) do
        buildTagBillboard(p) -- include self
    end
end

-- Floating animation: bob up/down, gentle pulse.
win:bind(RunService.Heartbeat:Connect(function()
    if not floatTagsEnabled then return end
    local t = tick()
    for p, e in pairs(tagBillboards) do
        if e.gui and e.gui.Parent then
            local phase = e.base or 0
            local y = 3 + math.sin(t * 2 + phase) * 0.25
            e.gui.StudsOffsetWorldSpace = Vector3.new(0, y, 0)
            if e.stroke then
                e.stroke.Transparency = 0.15 + (math.sin(t * 3 + phase) + 1) * 0.1
            end
        end
    end
end))

win:addToggle("Show floating tags", true, function(s)
    floatTagsEnabled = s
    rebuildTagBillboards()
end)
win:addButton("Refresh floating tags", rebuildTagBillboards)

-- Ensure a player has a billboard if they should
local function ensureTagBillboardFor(p)
    if not floatTagsEnabled then return end
    if tagBillboards[p] and tagBillboards[p].gui and tagBillboards[p].gui.Parent then
        refreshTagBillboardFor(p); return
    end
    if tagBillboards[p] then
        pcall(function() tagBillboards[p].gui:Destroy() end)
        tagBillboards[p] = nil
    end
    if p.Character and p.Character:FindFirstChild("Head") then
        buildTagBillboard(p)
    else
        -- wait for head to arrive
        task.spawn(function()
            local char = p.Character or p.CharacterAdded:Wait()
            char:WaitForChild("Head", 5)
            task.wait(0.2)
            if floatTagsEnabled then buildTagBillboard(p) end
        end)
    end
end

-- React to tag add/remove
Tags:onChange(function(uid)
    for _, p in ipairs(Players:GetPlayers()) do
        if p.UserId == uid then ensureTagBillboardFor(p) end
    end
end)

local function hookPlayer(p)
    win:bind(p.CharacterAdded:Connect(function()
        task.wait(0.4)
        if tagBillboards[p] then
            pcall(function() tagBillboards[p].gui:Destroy() end)
            tagBillboards[p] = nil
        end
        ensureTagBillboardFor(p)
    end))
end
win:bind(Players.PlayerAdded:Connect(hookPlayer))
for _, p in ipairs(Players:GetPlayers()) do hookPlayer(p) end

-- Build for anyone already in-game with tags
task.defer(rebuildTagBillboards)





win:addSection("Display")
local bright = false
win:addToggle("Fullbright", false, function(s)
    bright = s
    if s then
        Lighting.Brightness = 3; Lighting.ClockTime = 14; Lighting.FogEnd = 1e6
        Lighting.GlobalShadows = false; Lighting.Ambient = Color3.new(1,1,1)
    else
        Lighting.Brightness = 1; Lighting.GlobalShadows = true; Lighting.Ambient = Color3.fromRGB(70,70,70)
    end
end)
win:addSlider("Field of view", 30, 120, 70, function(v) cam.FieldOfView = v end)

-- WORLD ------------------------------------------------------------------
win:switchTab(tabWorld)
win:addSection("World")
win:addSlider("Time of day", 0, 24, 14, function(v) Lighting.ClockTime = v end)
win:addSlider("Gravity",     0, 400, 196, function(v) workspace.Gravity = v end)
win:addDropdown("Time preset", { "Noon", "Sunset", "Night", "Dawn" }, function(o)
    Lighting.ClockTime = ({ Noon = 12, Sunset = 18, Night = 0, Dawn = 6 })[o]
end)

-- TAGS -------------------------------------------------------------------
win:switchTab(tabTags)
win:addSection("Current selection")
local selTagLabel = win:addLabel("No player selected")
local function refreshSelTag()
    if selected then
        local s = Tags:summary(selected.UserId)
        selTagLabel:set(selected.Name .. " — " .. (s ~= "" and s or "no tags"))
    else
        selTagLabel:set("No player selected")
    end
end

win:addSection("Apply tag to selected")
local tagRow = win:addTagRow()
local chipRefs = {}
repaintChips = function() for _, c in ipairs(chipRefs) do c.paint() end end
local function addTagChip(t)
    local c = tagRow.addChip(t,
        function()
            if not selected then win:notify("Select a player first", "warn"); return end
            Tags:toggle(selected.UserId, t)
            refreshSelTag(); list.updateBadges(); rebuildEsp()
            repaintChips()
            win:notify(selected.Name .. " ↔ " .. t, "good")
        end,
        function() return selected and Tags:has(selected.UserId, t) end
    )
    table.insert(chipRefs, c)
end
for _, t in ipairs(Tags.defs) do addTagChip(t) end

win:addSection("Create new tag")
win:addTextBox("Tag name…", function(name)
    name = (name or ""):gsub("%s+", "")
    if name == "" then return end
    Tags:add(0, name); Tags:remove(0, name) -- registers in defs without assigning
    addTagChip(name); win:notify("Tag '" .. name .. "' added", "good")
end)

win:addSection("Clear")
win:addButton("Clear all tags on selected", function()
    if not selected then return end
    for t in pairs(Tags:get(selected.UserId)) do Tags:remove(selected.UserId, t) end
    refreshSelTag(); list.updateBadges(); rebuildEsp()
end)
win:addButton("Clear all tags on all players", function()
    Tags.map = {}; list.updateBadges(); refreshSelTag(); rebuildEsp()
end)

-- LOGS -------------------------------------------------------------------
win:switchTab(tabLogs)
win:addSection("Activity")
local logPanel = tabLogs.panel
local function log(line)
    local f = rowF(logPanel, 22); pad(f, 6)
    text(f, os.date("[%H:%M:%S] ") .. line, { size = 11, color = T.sub, fillX = true, h = 18 })
end
local origNotify = win.notify
function win:notify(msg, kind) origNotify(self, msg, kind); pcall(log, tostring(msg)) end

-- HOTKEY -----------------------------------------------------------------
win:bind(UIS.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.F2 then win:toggle() end
end))

_G.__AdminCleanup = function()
    pcall(stopFly)
    pcall(clearEsp)
    if win then pcall(function() win:destroy() end) end
    _G.__AdminUI = nil
    _G.__AdminLoaded = false
end

win:switchTab(tabPlayers)
win:notify("Loaded " .. ADMIN_BUILD .. ". Press F2 to toggle.", "good")
