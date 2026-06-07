--==============================================================
--  seige.lol Admin — Full overhaul
--  Sleek dark glass UI · comprehensive feature pack
--==============================================================
local ADMIN_BUILD = "2026-06-07-revamp-1"

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

------------------------------------------------------- LOAD SCREEN
local function showLoadScreen()
    local ls = inst("Frame", Root, {
        Name = "LoadScreen",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.fromRGB(8, 9, 14),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        ZIndex = 500,
    })
    inst("UIGradient", ls, {
        Rotation = 135,
        Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(14, 16, 24)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(6, 7, 12)),
        },
    })

    local card = inst("Frame", ls, {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 360, 0, 180),
        BackgroundColor3 = T.glass,
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        ZIndex = 501,
    })
    corner(card, 16)
    stroke(card, T.acc, 1, 0.5)
    inst("UIGradient", card, {
        Rotation = 120,
        Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, T.bg2),
            ColorSequenceKeypoint.new(1, T.glass),
        },
    })

    local title = inst("TextLabel", card, {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 26),
        Size = UDim2.new(1, 0, 0, 28),
        Font = Enum.Font.GothamBold,
        Text = "seige.lol",
        TextColor3 = T.text,
        TextSize = 22,
        ZIndex = 502,
    })
    local sub = inst("TextLabel", card, {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 56),
        Size = UDim2.new(1, 0, 0, 16),
        Font = Enum.Font.Gotham,
        Text = "Loading admin · " .. ADMIN_BUILD,
        TextColor3 = T.sub,
        TextSize = 11,
        ZIndex = 502,
    })

    -- progress bar
    local barBg = inst("Frame", card, {
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 96),
        Size = UDim2.new(0, 280, 0, 6),
        BackgroundColor3 = T.bg3,
        BorderSizePixel = 0,
        ZIndex = 502,
    })
    corner(barBg, 3)
    local barFill = inst("Frame", barBg, {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = T.acc,
        BorderSizePixel = 0,
        ZIndex = 503,
    })
    corner(barFill, 3)
    inst("UIGradient", barFill, {
        Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, T.acc2),
            ColorSequenceKeypoint.new(1, T.acc),
        },
    })

    local status = inst("TextLabel", card, {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 116),
        Size = UDim2.new(1, 0, 0, 14),
        Font = Enum.Font.Gotham,
        Text = "Initializing…",
        TextColor3 = T.dim,
        TextSize = 10,
        ZIndex = 502,
    })

    local credit = inst("TextLabel", card, {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 1, -22),
        Size = UDim2.new(1, 0, 0, 14),
        Font = Enum.Font.Gotham,
        Text = "made by seige · " .. (LP.Name or ""),
        TextColor3 = T.dim,
        TextSize = 10,
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

    local function tween(obj, t, props)
        TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
    end

    -- entrance
    card.Size = UDim2.new(0, 360, 0, 0)
    tween(card, 0.35, { Size = UDim2.new(0, 360, 0, 180) })

    task.spawn(function()
        for i, label in ipairs(steps) do
            status.Text = label .. "…"
            local pct = i / #steps
            tween(barFill, 0.25, { Size = UDim2.new(pct, 0, 1, 0) })
            task.wait(0.22 + math.random() * 0.18)
        end
        task.wait(0.2)
        tween(ls, 0.4, { BackgroundTransparency = 1 })
        tween(card, 0.4, { BackgroundTransparency = 1 })
        for _, d in ipairs(card:GetDescendants()) do
            if d:IsA("TextLabel") then tween(d, 0.4, { TextTransparency = 1 })
            elseif d:IsA("Frame") then tween(d, 0.4, { BackgroundTransparency = 1 })
            elseif d:IsA("UIStroke") then tween(d, 0.4, { Transparency = 1 }) end
        end
        task.wait(0.45)
        ls:Destroy()
    end)
end
showLoadScreen()



------------------------------------------------------- WINDOW
local Win = inst("Frame", Root, {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = UDim2.new(0, 620, 0, 440),
    BackgroundColor3 = T.bg,
    BackgroundTransparency = 0.05,
    BorderSizePixel = 0,
    Active = true,
})
corner(Win, 14)
stroke(Win, T.line, 1, 0.4)
-- glass gradient
inst("UIGradient", Win, {
    Rotation = 120,
    Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, T.bg2),
        ColorSequenceKeypoint.new(1, T.bg),
    },
    Transparency = NumberSequence.new(0.08),
})
-- soft outer glow
local glow = inst("ImageLabel", Win, {
    BackgroundTransparency = 1,
    Image = "rbxasset://textures/ui/Controls/DropShadow.png",
    ImageColor3 = T.acc,
    ImageTransparency = 0.85,
    ScaleType = Enum.ScaleType.Slice,
    SliceCenter = Rect.new(12,12,244,244),
    Size = UDim2.new(1, 36, 1, 36),
    Position = UDim2.new(0, -18, 0, -18),
    ZIndex = 0,
})

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

topBtn("✕", -4, function()
    if _G.__AdminCleanup then _G.__AdminCleanup() end
end)
topBtn("—", -38, function()
    minimized = not minimized
    tween(Win, 0.18, { Size = minimized and UDim2.new(0,620,0,44) or UDim2.new(0,620,0,440) })
    Body.Visible = not minimized
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
local Side = inst("Frame", Body, {
    Size = UDim2.new(0, 140, 1, -12),
    Position = UDim2.new(0, 8, 0, 4),
    BackgroundColor3 = T.bg2,
    BackgroundTransparency = 0.2,
    BorderSizePixel = 0,
})
corner(Side, 10); stroke(Side, T.line, 1, 0.5)
inst("UIListLayout", Side, {
    Padding = UDim.new(0, 4),
    SortOrder = Enum.SortOrder.LayoutOrder,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
})
pad(Side, 8)

local Pages = inst("Frame", Body, {
    Position = UDim2.new(0, 156, 0, 4),
    Size = UDim2.new(1, -164, 1, -12),
    BackgroundTransparency = 1,
})

local tabs = {}  -- name -> { btn, page }
local currentTab
local function makeTab(name, icon)
    local btn = inst("TextButton", Side, {
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = T.bg3,
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Text = "",
        Font = Enum.Font.GothamSemibold,
    })
    corner(btn, 8)
    local lbl = inst("TextLabel", btn, {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -16, 1, 0),
        Font = Enum.Font.GothamSemibold,
        TextSize = 13,
        TextColor3 = T.sub,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = (icon and (icon .. "  ") or "") .. name,
    })

    local page = inst("ScrollingFrame", Pages, {
        Visible = false,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = T.acc,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
    })
    inst("UIListLayout", page, {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    pad(page, 4)

    local entry = { btn = btn, page = page, lbl = lbl }
    tabs[name] = entry
    btn.MouseButton1Click:Connect(function()
        for n, e in pairs(tabs) do
            if n ~= name then
                tween(e.btn, 0.12, { BackgroundTransparency = 1 })
                e.lbl.TextColor3 = T.sub
                e.page.Visible = false
            end
        end
        tween(btn, 0.12, { BackgroundTransparency = 0.1, BackgroundColor3 = T.acc })
        lbl.TextColor3 = T.text
        page.Visible = true
        currentTab = name
    end)
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
        Size = UDim2.new(1, -8, 0, 22),
        BackgroundTransparency = 1,
    })
    local l = inst("TextLabel", f, {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = T.sub,
        TextXAlignment = Enum.TextXAlignment.Left,
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

-- Accept rbxassetid://, full URL, raw asset id, or any image/gif URL
local function resolveIconUrl(raw)
    if not raw or raw == "" then return nil end
    raw = raw:match("^%s*(.-)%s*$")
    if raw:match("^rbxassetid://") then return raw end
    if raw:match("^rbxthumb://") then return raw end
    if raw:match("^%d+$") then return "rbxassetid://" .. raw end
    return raw -- http(s):// image/gif URL (executors typically proxy via getcustomasset)
end



local function tagColor(p)
    if Tags:has(p.UserId, "Target") then return T.bad end
    if Tags:has(p.UserId, "Friend") then return T.good end
    if Tags:has(p.UserId, "Priority") then return T.warn end
    if Tags:has(p.UserId, "Ignore") then return T.dim end
    return T.acc
end

------------------------------------------------------- TABS
local pgPlayers = makeTab("Players", "◉")
local pgSelf    = makeTab("Self",    "✦")
local pgVisuals = makeTab("Visuals", "◐")
local pgWorld   = makeTab("World",   "◊")
local pgTags    = makeTab("Tags",    "#")
local pgAim     = makeTab("Aim",     "✚")

local pgServer  = makeTab("Server",  "≡")
local pgConfig  = makeTab("Config",  "⚙")

------------------------------------------------------- HELPERS
local function char()  return LP.Character end
local function hum()   local c = char(); return c and c:FindFirstChildOfClass("Humanoid") end
local function hrp()   local c = char(); return c and c:FindFirstChild("HumanoidRootPart") end
local function pchar(p) return p and p.Character end
local function phrp(p)  local c = pchar(p); return c and c:FindFirstChild("HumanoidRootPart") end


local selected
local refreshPlayerList, refreshSelTag, repaintChips -- forward

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
                if refreshSelTag then refreshSelTag() end
                if repaintChips then repaintChips() end
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
    local h = phrp(p); if h and hrp() then h.CFrame = hrp().CFrame + Vector3.new(0, 3, 0) end
end))
local spectatingPlr
button(pgPlayers, "Spectate / unspectate", withSel(function(p)
    if spectatingPlr == p then
        cam.CameraSubject = hum(); spectatingPlr = nil; notify("Stopped spectating", "good")
    else
        local h = pchar(p) and pchar(p):FindFirstChildOfClass("Humanoid")
        if h then cam.CameraSubject = h; spectatingPlr = p; notify("Spectating " .. p.Name, "good") end
    end
end))
button(pgPlayers, "Copy username", withSel(function(p)
    if setclipboard then setclipboard(p.Name); notify("Copied @" .. p.Name, "good") else notify("No clipboard access", "warn") end
end))
button(pgPlayers, "Refresh list", function() refreshPlayerList() end)

------------------------------------------------------- SELF TAB
section(pgSelf, "Movement")
local wsSlider = slider(pgSelf, "Walk speed", 0, 200, 16, function(v) local h = hum(); if h then h.WalkSpeed = v end end)
local jpSlider = slider(pgSelf, "Jump power", 0, 500, 50, function(v) local h = hum(); if h then h.JumpPower = v; h.UseJumpPower = true end end)

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
toggle(pgSelf, "Fly  (E up · Q down · WASD)", false, function(s)
    if s then startFly() else killFly() end
end)
slider(pgSelf, "Fly speed", 10, 300, 50, function(v) flySpeed = v end)

local noclip = false
toggle(pgSelf, "Noclip", false, function(s) noclip = s end)
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
toggle(pgSelf, "Infinite jump", false, function(s) infJump = s end)
bind(UIS.JumpRequest:Connect(function() if infJump then local h = hum(); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end end))

local clickTp = false
toggle(pgSelf, "Click teleport (Ctrl + click)", false, function(s) clickTp = s end)
bind(UIS.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.UserInputType == Enum.UserInputType.MouseButton1 and clickTp and UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
        if mouse.Hit and hrp() then hrp().CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0)) end
    end
end))

section(pgSelf, "Actions")
button(pgSelf, "Reset character", function() local h = hum(); if h then h.Health = 0 end end)
button(pgSelf, "Refresh character (TP to same spot)", function()
    local h = hrp(); if not h then return end
    local cf = h.CFrame
    LP.Character:BreakJoints()
    task.wait(0.6)
    LP.CharacterAdded:Wait():WaitForChild("HumanoidRootPart").CFrame = cf
end)

local antiAfk = false
toggle(pgSelf, "Anti-AFK", false, function(s)
    antiAfk = s
    if s then notify("Anti-AFK active", "good") end
end)
bind(LP.Idled:Connect(function()
    if antiAfk then
        local vu = game:GetService("VirtualUser")
        vu:CaptureController()
        vu:ClickButton2(Vector2.new())
    end
end))

------------------------------------------------------- VISUALS TAB
section(pgVisuals, "ESP")
local espOn, espFilter = false, "All"
local espNames, espDist, espHealth = true, true, true
local espBoxes = {} -- [player] = { hl, bb, lblName, lblDist, hpFill }

local function clearEsp()
    for _, e in pairs(espBoxes) do
        if e.hl then e.hl:Destroy() end
        if e.bb then e.bb:Destroy() end
    end
    espBoxes = {}
end
local function shouldEsp(p)
    if p == LP then return false end
    if Tags:has(p.UserId, "Ignore") then return false end
    if espFilter == "Friends" then return Tags:has(p.UserId, "Friend") end
    if espFilter == "Targets" then return Tags:has(p.UserId, "Target") end
    if espFilter == "Tagged"  then return next(Tags:get(p.UserId)) ~= nil end
    return true
end
local function buildEspFor(p)
    if not espOn or not shouldEsp(p) or not pchar(p) then return end
    if espBoxes[p] then return end
    local c = pchar(p)
    local color = tagColor(p)
    local hl = Instance.new("Highlight")
    hl.Adornee = c
    hl.FillTransparency = 0.6
    hl.OutlineColor = color; hl.FillColor = color
    hl.Parent = c
    local head = c:FindFirstChild("Head")
    local bb, lblName, lblDist, hpFill
    if head then
        bb = Instance.new("BillboardGui", c)
        bb.Adornee = head
        bb.Size = UDim2.new(0, 160, 0, 40)
        bb.StudsOffset = Vector3.new(0, 2.8, 0)
        bb.AlwaysOnTop = true
        lblName = inst("TextLabel", bb, {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 14),
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            TextColor3 = color,
            TextStrokeTransparency = 0.5,
            Text = p.DisplayName,
        })
        lblDist = inst("TextLabel", bb, {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0, 14),
            Size = UDim2.new(1, 0, 0, 12),
            Font = Enum.Font.Gotham,
            TextSize = 10,
            TextColor3 = T.sub,
            TextStrokeTransparency = 0.5,
            Text = "",
        })
        local hpBg = inst("Frame", bb, {
            Position = UDim2.new(0.2, 0, 0, 30),
            Size = UDim2.new(0.6, 0, 0, 4),
            BackgroundColor3 = Color3.fromRGB(40, 40, 50),
            BorderSizePixel = 0,
        })
        corner(hpBg, 2)
        hpFill = inst("Frame", hpBg, {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = T.good,
            BorderSizePixel = 0,
        })
        corner(hpFill, 2)
    end
    espBoxes[p] = { hl = hl, bb = bb, lblName = lblName, lblDist = lblDist, hpFill = hpFill }
end
local function rebuildEsp()
    clearEsp()
    if not espOn then return end
    for _, p in ipairs(Players:GetPlayers()) do buildEspFor(p) end
end

toggle(pgVisuals, "ESP", false, function(s) espOn = s; rebuildEsp() end)
dropdown(pgVisuals, "ESP filter", { "All", "Friends", "Targets", "Tagged" }, function(o) espFilter = o; rebuildEsp() end)
toggle(pgVisuals, "Show names", true, function(s) espNames = s end)
toggle(pgVisuals, "Show distance", true, function(s) espDist = s end)
toggle(pgVisuals, "Show health bar", true, function(s) espHealth = s end)
button(pgVisuals, "Refresh ESP", rebuildEsp)

bind(RunService.RenderStepped:Connect(function()
    if not espOn then return end
    local myH = hrp()
    for p, e in pairs(espBoxes) do
        if e.bb then
            if e.lblName then e.lblName.Visible = espNames; e.lblName.TextColor3 = tagColor(p) end
            if e.lblDist then
                e.lblDist.Visible = espDist
                if myH and phrp(p) then
                    e.lblDist.Text = math.floor((myH.Position - phrp(p).Position).Magnitude) .. "m"
                end
            end
            if e.hpFill then
                e.hpFill.Parent.Visible = espHealth
                local h = pchar(p) and pchar(p):FindFirstChildOfClass("Humanoid")
                if h then
                    local f = math.clamp(h.Health / math.max(1, h.MaxHealth), 0, 1)
                    e.hpFill.Size = UDim2.new(f, 0, 1, 0)
                    e.hpFill.BackgroundColor3 = f > 0.5 and T.good or (f > 0.25 and T.warn or T.bad)
                end
            end
        end
    end
end))
bind(Players.PlayerAdded:Connect(function(p)
    bind(p.CharacterAdded:Connect(function() task.wait(0.5); if espOn then buildEspFor(p) end end))
end))
for _, p in ipairs(Players:GetPlayers()) do
    bind(p.CharacterAdded:Connect(function() task.wait(0.5); if espOn then buildEspFor(p) end end))
end

section(pgVisuals, "Camera & Lighting")
slider(pgVisuals, "Field of view", 30, 120, 70, function(v) cam.FieldOfView = v end)
toggle(pgVisuals, "Fullbright", false, function(s)
    if s then
        Lighting.Brightness = 3; Lighting.ClockTime = 14; Lighting.FogEnd = 1e6
        Lighting.GlobalShadows = false; Lighting.Ambient = Color3.new(1,1,1)
    else
        Lighting.Brightness = 1; Lighting.GlobalShadows = true; Lighting.Ambient = Color3.fromRGB(70,70,70)
    end
end)
toggle(pgVisuals, "Low graphics (fog off, shadows off)", false, function(s)
    Lighting.FogEnd = s and 1e6 or 1000
    Lighting.GlobalShadows = not s
end)

------------------------------------------------------- WORLD TAB
section(pgWorld, "Environment")
slider(pgWorld, "Time of day", 0, 24, 14, function(v) Lighting.ClockTime = v end)
slider(pgWorld, "Gravity", 0, 400, workspace.Gravity, function(v) workspace.Gravity = v end)
dropdown(pgWorld, "Time preset", { "Noon", "Sunset", "Night", "Dawn" }, function(o)
    Lighting.ClockTime = ({ Noon = 12, Sunset = 18, Night = 0, Dawn = 6 })[o]
end)

------------------------------------------------------- TAGS TAB
section(pgTags, "Current selection")
local selTagLbl = label(pgTags, "No player selected")
function refreshSelTag()
    if selected then
        local s = Tags:summary(selected.UserId)
        selTagLbl:set(selected.Name .. " — " .. (s ~= "" and s or "no tags"))
    else
        selTagLbl:set("No player selected")
    end
end

section(pgTags, "Apply tag to selected")
local chipsHolder = inst("Frame", pgTags, {
    Size = UDim2.new(1, -8, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1,
})
inst("UIListLayout", chipsHolder, {
    Padding = UDim.new(0, 6),
    FillDirection = Enum.FillDirection.Horizontal,
    SortOrder = Enum.SortOrder.LayoutOrder,
})

function repaintChips()
    for _, c in ipairs(chipsHolder:GetChildren()) do if c:IsA("TextButton") then
        local active = selected and Tags:has(selected.UserId, c.Name)
        c.BackgroundColor3 = active and T.acc or T.bg3
        c.TextColor3 = active and T.text or T.sub
    end end
end
local function addChip(tag)
    local b = inst("TextButton", chipsHolder, {
        Name = tag,
        Size = UDim2.new(0, 0, 0, 26),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = T.bg3,
        AutoButtonColor = false,
        Text = "  " .. tag .. "  ",
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = T.sub,
    })
    corner(b, 13); stroke(b, T.line, 1, 0.5)
    b.MouseButton1Click:Connect(function()
        if not selected then notify("Select a player first", "warn"); return end
        Tags:toggle(selected.UserId, tag); refreshSelTag(); repaintChips(); refreshPlayerList()
    end)
end
for _, t in ipairs(Tags.defs) do addChip(t) end

section(pgTags, "Create new tag")
textbox(pgTags, "Tag name…", function(name)
    name = name:gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then return end
    Tags:add(0, name); Tags:remove(0, name)
    addChip(name); notify("Tag '" .. name .. "' added", "good")
end)
button(pgTags, "Clear tags on selected", function()
    if not selected then notify("Select a player first", "warn"); return end
    for t in pairs(Tags:get(selected.UserId)) do Tags:remove(selected.UserId, t) end
    refreshSelTag(); repaintChips(); refreshPlayerList()
end)
button(pgTags, "Clear ALL tags", function()
    for uid in pairs(Tags.map) do for t in pairs(Tags.map[uid]) do Tags:remove(uid, t) end end
    refreshSelTag(); repaintChips(); refreshPlayerList()
end)

-- Hook selection -> refresh chip states
task.spawn(function()
    while task.wait(0.4) do refreshSelTag(); repaintChips() end
end)

------------------------------------------------------- FLOATING TAGS
section(pgTags, "Floating tags in-game")
local floatOn = false
local tagBills = {}

local function clearBills()
    for _, e in pairs(tagBills) do if e.gui then e.gui:Destroy() end end
    tagBills = {}
end
local function refreshBill(p)
    local e = tagBills[p]; if not e then return end
    e.gui.Enabled = true
    e.name.Text = p.DisplayName
    e.handle.Text = "@" .. p.Name
    local txt = Tags:summary(p.UserId)
    if txt ~= "" then
        e.sh.Visible = true
        e.stat.Text = txt:gsub(",", " • ")
        local c = tagColor(p)
        e.stroke.Color = c; e.dot.BackgroundColor3 = c
    else
        e.sh.Visible = false
        if p == LP then
            e.stroke.Color = T.good; e.dot.BackgroundColor3 = T.good
        else
            e.stroke.Color = T.acc; e.dot.BackgroundColor3 = T.acc
        end
    end
end
local function buildBill(p)
    if tagBills[p] or not pchar(p) then return end
    local head = pchar(p):FindFirstChild("Head"); if not head then return end
    local gui = inst("BillboardGui", pchar(p), {
        Name = "SeigeTagBB", Adornee = head,

        Size = UDim2.new(0, 240, 0, 50),
        StudsOffsetWorldSpace = Vector3.new(0, 3.2, 0),
        AlwaysOnTop = true, LightInfluence = 0,
    })
    local bg = inst("Frame", gui, {
        Size = UDim2.new(1, 0, 0, 42), Position = UDim2.new(0, 0, 0, 4),
        BackgroundColor3 = T.bg, BackgroundTransparency = 0.1, BorderSizePixel = 0,
    })
    corner(bg, 21)
    local st = stroke(bg, T.acc, 1.4, 0.3)
    inst("UIGradient", bg, {
        Rotation = 90,
        Color = ColorSequence.new(Color3.fromRGB(32,32,42), Color3.fromRGB(14,14,18)),
    })
    local av = inst("ImageLabel", bg, {
        Size = UDim2.new(0, 32, 0, 32), Position = UDim2.new(0, 5, 0.5, -16),
        BackgroundColor3 = T.bg3, BorderSizePixel = 0, ScaleType = Enum.ScaleType.Crop,
    })
    corner(av, 16)
    pcall(function() av.Image = Players:GetUserThumbnailAsync(p.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100) end)
    local nm = inst("TextLabel", bg, {
        BackgroundTransparency = 1, Position = UDim2.new(0, 44, 0, 3), Size = UDim2.new(1, -120, 0, 18),
        Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = T.text,
        TextXAlignment = Enum.TextXAlignment.Left, Text = p.DisplayName, TextStrokeTransparency = 0.7,
    })
    local hd = inst("TextLabel", bg, {
        BackgroundTransparency = 1, Position = UDim2.new(0, 44, 0, 22), Size = UDim2.new(1, -120, 0, 14),
        Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = T.sub,
        TextXAlignment = Enum.TextXAlignment.Left, Text = "@" .. p.Name,
    })
    local sh = inst("Frame", bg, {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0),
        Size = UDim2.new(0, 80, 0, 22),
        BackgroundColor3 = T.bg2, BorderSizePixel = 0,
    })
    corner(sh, 11); stroke(sh, T.line, 1, 0.4)
    local dot = inst("Frame", sh, {
        Size = UDim2.new(0, 6, 0, 6), Position = UDim2.new(0, 8, 0.5, -3),
        BackgroundColor3 = T.acc, BorderSizePixel = 0,
    })
    corner(dot, 3)
    local stx = inst("TextLabel", sh, {
        BackgroundTransparency = 1, Position = UDim2.new(0, 18, 0, 0), Size = UDim2.new(1, -22, 1, 0),
        Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = T.text,
        TextXAlignment = Enum.TextXAlignment.Left, Text = "",
    })
    tagBills[p] = { gui = gui, stroke = st, name = nm, handle = hd, stat = stx, dot = dot, sh = sh, av = av, base = math.random() * 6.28 }
    refreshBill(p)
end
local function rebuildBills()
    clearBills()
    -- LP's tag always shown
    buildBill(LP)
    if not floatOn then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then buildBill(p) end
    end
end
toggle(pgTags, "Show floating tags above heads", false, function(s) floatOn = s; rebuildBills() end)

button(pgTags, "Refresh floating tags", rebuildBills)

bind(RunService.Heartbeat:Connect(function()
    local t = tick()
    for p, e in pairs(tagBills) do
        if e.gui and e.gui.Parent then
            local y = 3.2 + math.sin(t * 2 + e.base) * 0.25
            e.gui.StudsOffsetWorldSpace = Vector3.new(0, y, 0)
            e.stroke.Transparency = 0.2 + (math.sin(t * 3 + e.base) + 1) * 0.1
        end
    end
end))
Tags:onChange(function(uid)
    for _, p in ipairs(Players:GetPlayers()) do
        if p.UserId == uid then
            if tagBills[p] then refreshBill(p) else if floatOn or p == LP then buildBill(p) end end
        end
    end
    refreshPlayerList()
end)
local function hookCharBill(p)
    bind(p.CharacterAdded:Connect(function()
        task.wait(0.5)
        if tagBills[p] then pcall(function() tagBills[p].gui:Destroy() end); tagBills[p] = nil end
        if floatOn or p == LP then buildBill(p) end
    end))
end

bind(Players.PlayerAdded:Connect(hookCharBill))
for _, p in ipairs(Players:GetPlayers()) do hookCharBill(p) end
task.defer(rebuildBills)

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
        floatOn = true
        rebuildBills()
        if notify then pcall(notify, "Player tags enabled", "good") end
        slideOut()
    end)
    dismissBtn.MouseButton1Click:Connect(function() slideOut() end)

    -- slide in
    TweenService:Create(prompt, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        { Position = UDim2.new(1, -18, 1, -18) }):Play()
end)



------------------------------------------------------- AIM TAB (camera lock)
section(pgAim, "Camera lock")
local aimOn, aimFov, aimSmooth = false, 100, 0.25
local aimVisOnly = true
local aimKey = "RightMouseButton"
local function findTarget()
    local best, bestDist = nil, aimFov
    local myH = hrp(); if not myH then return end
    local center = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and shouldEsp(p) then
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
toggle(pgAim, "Camera lock (hold key)", false, function(s) aimOn = s end)
slider(pgAim, "FOV radius (px)", 20, 400, 100, function(v) aimFov = v end)
slider(pgAim, "Smoothness", 0, 1, 0.25, function(v) aimSmooth = v end)
toggle(pgAim, "Visible targets only", true, function(s) aimVisOnly = s end)
dropdown(pgAim, "Trigger button", { "RightMouseButton", "Q", "E", "Always" }, function(o) aimKey = o end)

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

------------------------------------------------------- SERVER TAB

------------------------------------------------------- SERVER TAB
section(pgServer, "Server")
button(pgServer, "Rejoin server", function()
    pcall(function() TeleportSrv:Teleport(game.PlaceId, LP) end)
end)
button(pgServer, "Server hop (random public)", function()
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
        else notify("No servers found", "warn") end
    else notify("Server list unavailable", "bad") end
end)
button(pgServer, "Copy JobId", function()
    if setclipboard then setclipboard(game.JobId); notify("JobId copied", "good") end
end)

------------------------------------------------------- CONFIG TAB
section(pgConfig, "Settings")
local toggleKey = Enum.KeyCode.F2
local awaitingKey = false
local keyBtn = button(pgConfig, "Toggle key: F2  (click to rebind)", function()
    awaitingKey = true
end)
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

slider(pgConfig, "UI scale", 0.7, 1.4, 1, function(v)
    local s = Win:FindFirstChildOfClass("UIScale") or inst("UIScale", Win, { Scale = 1 })
    s.Scale = v
end)

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

------------------------------------------------------- DEFAULT TAB

-- Manually fire default
do
    local e = tabs["Players"]
    tween(e.btn, 0.12, { BackgroundTransparency = 0.1, BackgroundColor3 = T.acc })
    e.lbl.TextColor3 = T.text
    e.page.Visible = true
    currentTab = "Players"
end

------------------------------------------------------- CLEANUP
_G.__AdminCleanup = function()
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    conns = {}
    killFly()
    clearEsp()
    clearBills()
    pcall(function() Root:Destroy() end)
    pcall(function() Lighting.Brightness = 1; Lighting.GlobalShadows = true; Lighting.Ambient = Color3.fromRGB(70,70,70) end)
    _G.__AdminLoaded = nil
    _G.__AdminUI = nil
end

------------------------------------------------------- READY
notify("seige.lol loaded · " .. ADMIN_BUILD, "good")
notify("Press F2 to toggle UI", "good")
print("[seige.lol] Ready")
