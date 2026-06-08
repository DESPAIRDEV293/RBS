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



------------------------------------------------------- TAG DATABASE (script-managed)
-- Two sources are tried, in order:
--   1) TAGS_PASTEBIN_URL  — a raw Pastebin (or any plain-text URL) using the
--      super-simple line format below. EASIEST to edit, no code knowledge needed.
--   2) TAGS_DB_URL        — the legacy tags.lua on GitHub (Lua table).
--
-- Pastebin line format (one player per line, pipe-separated):
--   username | displayName | #hexcolor | effect | icon | tag1,tag2,tag3 | textFx | customText | customHandle
--
--   - Only `username` is required. Leave any field blank to skip it (keep the |).
--   - hexcolor: a single hex like #ff3b6b, OR two hex values separated by `/`
--               to split the bubble in half (left/right), e.g. #ff3b6b/#00aaff
--   - effect: rain | snow | sparkle | nebula   (or blank for none)
--   - icon:   Roblox image ID (raw number, e.g. 1234567890), OR an animated
--             sprite-sheet spec "gif:assetId:cols:rows:fps[:sheetSize]"
--             e.g. gif:1234567890:4:4:12   (16-frame 4x4 sheet at 12 fps;
--             sheetSize defaults to 1024)
--   - textFx: glitch | type | explode   (or blank for none)
--   - customText:   optional override for the right-side chip text (owner-only)
--   - customHandle: optional override for the "@name" line on the tag (owner-only).
--                   Anyone without an entry shows the anonymous "user" / "@user".
--   - Lines starting with # or // are comments. Blank lines are ignored.
--
-- Example paste:
--   DESPAIRDEV293 | Despair | #ff3b6b/#00aaff | nebula |  | Owner,Dev | glitch | VIP | despair
--   Builderman    | Builderman | #00aaff | sparkle | 156 | Roblox
--
-- To change tags: edit the paste, hit Save, rejoin (or wait for next load).
local TAGS_PASTEBIN_URL = "https://pastebin.com/raw/wySWnyme"
local TAGS_DB_URL       = "https://raw.githubusercontent.com/DESPAIRDEV293/roblox-script-buddy/main/tags.lua"

local TagDB = { entries = {} }
local function parseColor(c)
    if typeof(c) == "Color3" then return c end
    if type(c) == "string" then
        -- accept "#aaa/#bbb" — use the first one
        local first = c:match("([^/]+)")
        local hex = (first or c):gsub("#",""):gsub("%s","")
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
function TagDB:configFor(p)
    if not p then return nil end
    return self.entries[(p.Name or ""):lower()]
end
function TagDB:applyTo(p)
    local cfg = self:configFor(p); if not cfg then return end
    if cfg.icon then TagIcons:set(p.UserId, cfg.icon) end
    if type(cfg.tags) == "table" then
        for _, t in ipairs(cfg.tags) do Tags:add(p.UserId, t) end
    end
end

local function trim(s) return (tostring(s or ""):gsub("^%s+",""):gsub("%s+$","")) end
local function parsePastebin(src)
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
                if parts[4] and parts[4] ~= "" then entry.effect = parts[4]:lower() end
                if parts[5] and parts[5] ~= "" then entry.icon = parts[5] end
                if parts[6] and parts[6] ~= "" then
                    local tags = {}
                    for t in (parts[6] .. ","):gmatch("([^,]*),") do
                        t = trim(t); if t ~= "" then tags[#tags+1] = t end
                    end
                    if #tags > 0 then entry.tags = tags end
                end
                if parts[7] and parts[7] ~= "" then entry.textFx = parts[7]:lower() end
                if parts[8] and parts[8] ~= "" then entry.customText = parts[8] end
                if parts[9] and parts[9] ~= "" then entry.customHandle = parts[9] end
                entries[user:lower()] = entry
                count = count + 1
            end
        end
    end
    return entries, count
end

function TagDB:load()
    -- Try Pastebin source first (easy-edit text format)
    if TAGS_PASTEBIN_URL ~= "" then
        local src
        pcall(function()
            src = game:HttpGet(TAGS_PASTEBIN_URL .. (TAGS_PASTEBIN_URL:find("?") and "&" or "?") .. "v=" .. tostring(os.time()))
        end)
        if src and src ~= "" then
            local entries, count = parsePastebin(src)
            if count > 0 then
                self.entries = entries
                print(("[Tags] Pastebin DB loaded — %d entries"):format(count))
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
    if not src then warn("[Tags] DB fetch failed"); return end
    local fn, err = loadstring(src)
    if not fn then warn("[Tags] compile: " .. tostring(err)); return end
    local ok, data = pcall(fn)
    if not ok or type(data) ~= "table" then
        warn("[Tags] eval failed: " .. tostring(data)); return
    end
    local entries = {}
    for k, v in pairs(data) do entries[tostring(k):lower()] = v end
    self.entries = entries
    print(("[Tags] GitHub DB loaded — %d entries"):format((function() local n=0; for _ in pairs(entries) do n=n+1 end; return n end)()))
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
-- Tags tab removed — now managed via the script database (tags.lua)
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

------------------------------------------------------- FLOATING TAGS (driven by tags.lua DB)
local floatOn = false
local tagBills = {}

-- ===== Particle effects (rain / snow / sparkle / nebula) =====
local lastSpawn = setmetatable({}, { __mode = "k" })
local NEBULA_COLORS = {
    Color3.fromRGB(120, 90, 220),
    Color3.fromRGB(80, 110, 240),
    Color3.fromRGB(200, 80, 200),
    Color3.fromRGB(80, 180, 220),
}
local function spawnRain(e)
    local f = inst("Frame", e.fx, {
        Size = UDim2.new(0, 2, 0, math.random(8, 14)),
        Position = UDim2.new(math.random(), 0, 0, -12),
        BackgroundColor3 = Color3.fromRGB(150, 190, 255),
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0, ZIndex = 0,
    })
    TweenService:Create(f, TweenInfo.new(0.55, Enum.EasingStyle.Linear),
        { Position = UDim2.new(f.Position.X.Scale, 0, 1, 8), BackgroundTransparency = 1 }):Play()
    task.delay(0.6, function() if f then f:Destroy() end end)
end
local function spawnSnow(e)
    local f = inst("Frame", e.fx, {
        Size = UDim2.new(0, 3, 0, 3),
        Position = UDim2.new(math.random(), 0, 0, -4),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0, ZIndex = 0,
    })
    corner(f, 2)
    local x = f.Position.X.Scale + (math.random() - 0.5) * 0.18
    TweenService:Create(f, TweenInfo.new(1.3, Enum.EasingStyle.Sine),
        { Position = UDim2.new(x, 0, 1, 4), BackgroundTransparency = 1 }):Play()
    task.delay(1.35, function() if f then f:Destroy() end end)
end
local function spawnSparkle(e)
    local f = inst("Frame", e.fx, {
        Size = UDim2.new(0, 2, 0, 2),
        Position = UDim2.new(math.random(), 0, math.random(), 0),
        BackgroundColor3 = Color3.fromRGB(255, 240, 180),
        BackgroundTransparency = 0,
        BorderSizePixel = 0, ZIndex = 0,
    })
    corner(f, 1)
    TweenService:Create(f, TweenInfo.new(0.55, Enum.EasingStyle.Quad),
        { Size = UDim2.new(0, 6, 0, 6), BackgroundTransparency = 1 }):Play()
    task.delay(0.6, function() if f then f:Destroy() end end)
end
local function spawnNebula(e)
    local sz = math.random(22, 38)
    local f = inst("Frame", e.fx, {
        Size = UDim2.new(0, sz, 0, sz),
        Position = UDim2.new(math.random() * 1.2 - 0.1, 0, math.random() * 1.4 - 0.2, 0),
        BackgroundColor3 = NEBULA_COLORS[math.random(#NEBULA_COLORS)],
        BackgroundTransparency = 0.78,
        BorderSizePixel = 0, ZIndex = 0,
    })
    corner(f, math.floor(sz / 2))
    local tx = f.Position.X.Scale + (math.random() - 0.5) * 0.5
    local ty = f.Position.Y.Scale + (math.random() - 0.5) * 0.4
    TweenService:Create(f, TweenInfo.new(2.6, Enum.EasingStyle.Sine),
        { Position = UDim2.new(tx, 0, ty, 0), BackgroundTransparency = 1,
          Size = UDim2.new(0, sz + 12, 0, sz + 12) }):Play()
    task.delay(2.7, function() if f then f:Destroy() end end)
end
local EFFECT_RATES  = { rain = 0.045, snow = 0.10, sparkle = 0.13, nebula = 0.30 }
local EFFECT_SPAWN  = { rain = spawnRain, snow = spawnSnow, sparkle = spawnSparkle, nebula = spawnNebula }




local function clearBills()
    for _, e in pairs(tagBills) do if e.gui then e.gui:Destroy() end end
    tagBills = {}
end
local function measureText(text, font, size)
    local ok, v = pcall(function()
        return TextService:GetTextSize(text or "", size, font, Vector2.new(10000, 100))
    end)
    if ok and v then return v.X end
    return #(text or "") * size * 0.55
end

-- Parse a gif/sprite-sheet spec from the icon field.
-- Accepted format: "gif:assetId:cols:rows:fps[:sheetSize]"
--   sheetSize defaults to 1024 (most uploaded sheets are 1024x1024).
-- Returns table { id, cols, rows, fps, size, frames, fw, fh } or nil.
local function parseGifSpec(raw)
    if type(raw) ~= "string" then return nil end
    local lower = raw:lower()
    if lower:sub(1, 4) ~= "gif:" then return nil end
    local id, cols, rows, fps, size = raw:match("^[gG][iI][fF]:(%d+):(%d+):(%d+):(%d+):?(%d*)$")
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
    if cfg and cfg.color then c1, c2 = parseColorPair(cfg.color) end
    local txt = Tags:summary(p.UserId)
    -- owner-only custom chip text override
    if cfg and cfg.customText and cfg.customText ~= "" then txt = cfg.customText end
    if txt ~= "" then
        e.sh.Visible = true
        e.stat.Text = txt:gsub(",", " • ")
        local c = c1 or tagColor(p)
        e.stroke.Color = c; e.dot.BackgroundColor3 = c
    else
        e.sh.Visible = false
        local c = c1 or (p == LP and T.good or T.acc)
        e.stroke.Color = c; e.dot.BackgroundColor3 = c
    end
    -- Two-color split bubble background (left half c1, right half c2)
    if e.bgGrad then
        if c1 and c2 then
            e.bgGrad.Rotation = 0
            e.bgGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0,    c1),
                ColorSequenceKeypoint.new(0.499, c1),
                ColorSequenceKeypoint.new(0.5,  c2),
                ColorSequenceKeypoint.new(1,    c2),
            })
            e.bg.BackgroundTransparency = 0
        else
            e.bgGrad.Rotation = 90
            e.bgGrad.Color = ColorSequence.new(Color3.fromRGB(32,32,42), Color3.fromRGB(14,14,18))
            e.bg.BackgroundTransparency = 0.1
        end
    end

    -- Effect change
    local newEffect = cfg and cfg.effect
    if newEffect ~= e.effect then
        e.effect = newEffect
        if e.fx then for _, c in ipairs(e.fx:GetChildren()) do c:Destroy() end end
    end

    -- Text effect (glitch / type / explode)
    local newTextFx = cfg and cfg.textFx
    e.nameBase   = nameStr
    e.handleBase = handleStr
    if newTextFx ~= e.textFx then
        e.textFx = newTextFx
        e.txState = nil
        -- restore plain text immediately; engine will take over next frame
        e.name.Text   = e.nameBase
        e.handle.Text = e.handleBase
    end

    -- Auto-size bubble to text content
    local nameW   = measureText(e.name.Text,   Enum.Font.GothamBold, 14)
    local handleW = measureText(e.handle.Text, Enum.Font.Gotham,     10)
    local textW   = math.ceil(math.max(nameW, handleW))
    e.name.Size   = UDim2.new(0, textW + 4, 0, 18)
    e.handle.Size = UDim2.new(0, textW + 4, 0, 14)

    local chipBlock = 0
    if e.sh.Visible then
        local statW = measureText(e.stat.Text, Enum.Font.GothamBold, 10)
        local shW   = math.ceil(statW + 28)
        e.sh.Size   = UDim2.new(0, shW, 0, 22)
        chipBlock   = shW + 8
    end

    -- avatar(5+32) + gap(8) + text + chipBlock + right pad(10)
    local total = 5 + 32 + 8 + textW + chipBlock + 10
    if total < 110 then total = 110 end
    e.bg.Size  = UDim2.new(0, total, 0, 42)
    e.gui.Size = UDim2.new(0, total + 8, 0, 50)
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
        Size = UDim2.new(0, 240, 0, 50),
        StudsOffsetWorldSpace = Vector3.new(0, 3.2, 0),
        AlwaysOnTop = true, LightInfluence = 0,
    })
    local bg = inst("Frame", gui, {
        Size = UDim2.new(1, 0, 0, 42), Position = UDim2.new(0, 0, 0, 4),
        BackgroundColor3 = T.bg, BackgroundTransparency = 0.1, BorderSizePixel = 0,
        ClipsDescendants = true,
    })
    corner(bg, 21)
    -- particle layer (sits behind text)
    local fx = inst("Frame", bg, {
        Name = "fx", Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1, ZIndex = 0,
    })

    local st = stroke(bg, T.acc, 1.4, 0.3)
    local bgGrad = inst("UIGradient", bg, {
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
    -- invisible click overlay covering the whole bubble → teleport to target player
    local clickBtn = inst("TextButton", bg, {
        Name = "tpClick",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        Active = true,
        ZIndex = 50,
    })
    clickBtn.MouseButton1Click:Connect(function()
        if p == LP then return end
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
    end)
    tagBills[p] = { gui = gui, bg = bg, bgGrad = bgGrad, fx = fx, stroke = st, name = nm, handle = hd, stat = stx, dot = dot, sh = sh, av = av, clickBtn = clickBtn, base = math.random() * 6.28, effect = nil, fxToken = 0, gifToken = 0, gifKey = nil }
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
            local y = 3.2 + math.sin(t * 2 + e.base) * 0.25
            e.gui.StudsOffsetWorldSpace = Vector3.new(0, y, 0)
            e.stroke.Transparency = 0.2 + (math.sin(t * 3 + e.base) + 1) * 0.1
        end
    end
end))

-- Particle spawner — runs each Heartbeat for bills with an effect
bind(RunService.Heartbeat:Connect(function(dt)
    for _, e in pairs(tagBills) do
        if e.effect and e.fx and e.fx.Parent then
            local rate = EFFECT_RATES[e.effect] or 0.2
            lastSpawn[e] = (lastSpawn[e] or 0) + dt
            if lastSpawn[e] >= rate then
                lastSpawn[e] = 0
                local fn = EFFECT_SPAWN[e.effect]
                if fn then pcall(fn, e) end
            end
        end
    end
end))

-- Text effects: glitch / type / explode
local GLITCH_CHARS = { "#","@","%","&","*","?","/","\\","█","▓","▒","░","!","¥","Ω","§","∆","◊" }
local function glitchify(src, intensity)
    if src == "" then return src end
    local out = {}
    for i = 1, #src do
        local ch = src:sub(i, i)
        if ch ~= " " and math.random() < intensity then
            out[i] = GLITCH_CHARS[math.random(1, #GLITCH_CHARS)]
        else
            out[i] = ch
        end
    end
    return table.concat(out)
end
local function applyTextFx(e, t, dt)
    local fx = e.textFx
    if not fx then return end
    local st = e.txState or {}
    e.txState = st
    if fx == "glitch" then
        st.t = (st.t or 0) + dt
        if st.t >= 0.06 then
            st.t = 0
            local hot = (math.sin(t * 3) + 1) * 0.5
            local intensity = 0.05 + hot * 0.18
            e.name.Text   = glitchify(e.nameBase,   intensity)
            e.handle.Text = glitchify(e.handleBase, intensity * 0.7)
        end
    elseif fx == "type" then
        st.t = (st.t or 0) + dt
        st.phase = st.phase or "type"
        st.i = st.i or 0
        local full = e.nameBase
        if st.phase == "type" then
            if st.t >= 0.06 then
                st.t = 0; st.i = st.i + 1
                if st.i >= #full then st.i = #full; st.phase = "hold"; st.hold = 0 end
            end
        elseif st.phase == "hold" then
            st.hold = (st.hold or 0) + dt
            if st.hold >= 1.4 then st.phase = "erase" end
        elseif st.phase == "erase" then
            if st.t >= 0.04 then
                st.t = 0; st.i = st.i - 1
                if st.i <= 0 then st.i = 0; st.phase = "type" end
            end
        end
        local caret = (math.floor(t * 2) % 2 == 0) and "▍" or " "
        e.name.Text   = full:sub(1, st.i) .. caret
        e.handle.Text = e.handleBase
    elseif fx == "explode" then
        st.t = (st.t or 0) + dt
        st.cycle = st.cycle or 2.2
        if st.t >= st.cycle then
            st.t = 0
            -- pop: scatter chars (insert spaces) then collapse
            local function scatter(src, n)
                local out = {}
                for i = 1, #src do out[#out+1] = src:sub(i,i) end
                for _ = 1, n do
                    table.insert(out, math.random(1, math.max(1,#out)), " ")
                end
                return table.concat(out)
            end
            local frames = { 6, 10, 14, 10, 6, 3, 0 }
            task.spawn(function()
                for _, n in ipairs(frames) do
                    if not e.gui or not e.gui.Parent then return end
                    e.name.Text   = scatter(e.nameBase, n)
                    e.handle.Text = scatter(e.handleBase, math.floor(n/2))
                    task.wait(0.06)
                end
                if e.gui and e.gui.Parent then
                    e.name.Text = e.nameBase; e.handle.Text = e.handleBase
                end
            end)
        end
    end
end
bind(RunService.Heartbeat:Connect(function(dt)
    local t = tick()
    for _, e in pairs(tagBills) do
        if e.textFx and e.gui and e.gui.Parent then
            pcall(applyTextFx, e, t, dt)
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

bind(Players.PlayerAdded:Connect(function(p)
    hookCharBill(p)
    TagDB:applyTo(p)
end))
for _, p in ipairs(Players:GetPlayers()) do hookCharBill(p) end

-- Load the script-managed tag database, then apply to all players
task.spawn(function()
    TagDB:load()
    for _, p in ipairs(Players:GetPlayers()) do TagDB:applyTo(p) end
    task.defer(rebuildBills)
end)


------------------------------------------------------- TAGS MANAGER (owner-only)
-- In-game GUI to add/edit/remove tag entries without touching code or pastebin.
-- Changes apply LIVE to everyone in the server. Export button copies a
-- pastebin-formatted text block to your clipboard so you can save permanently.
if LP.Name == "0rot3" then
    local EFFECT_OPTS = { "none", "rain", "snow", "sparkle", "nebula" }
    local TEXTFX_OPTS = { "none", "glitch", "type", "explode" }

    local pgTags = makeTab("Tags", "✎")

    -- form values
    local form = {
        username = "", displayName = "", color = "", color2 = "",
        icon = "", effect = "none", textFx = "none", tags = "", customText = "", customHandle = "",
    }
    local editingKey = nil  -- if set, "Save" updates this key instead of creating

    section(pgTags, "Tag editor")

    local function field(parent, lbl, key, placeholder)
        local f = inst("Frame", parent, {
            Size = UDim2.new(1, -8, 0, 48),
            BackgroundColor3 = T.bg2,
            BackgroundTransparency = 0.3,
            BorderSizePixel = 0,
        })
        corner(f, 8); stroke(f, T.line, 1, 0.5)
        inst("TextLabel", f, {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 4),
            Size = UDim2.new(1, -20, 0, 14),
            Font = Enum.Font.GothamBold,
            TextSize = 10,
            TextColor3 = T.dim,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = string.upper(lbl),
        })
        local tb = inst("TextBox", f, {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 20),
            Size = UDim2.new(1, -20, 0, 22),
            PlaceholderText = placeholder or "",
            PlaceholderColor3 = T.dim,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextColor3 = T.text,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = "",
            ClearTextOnFocus = false,
        })
        tb:GetPropertyChangedSignal("Text"):Connect(function()
            form[key] = tb.Text
        end)
        return tb
    end

    local tbUser     = field(pgTags, "Username (required)", "username", "DESPAIRDEV293")
    local tbDisplay  = field(pgTags, "Display name (optional)", "displayName", "Despair")
    local tbColor    = field(pgTags, "Hex color (left half)", "color", "#ff3b6b")
    local tbColor2   = field(pgTags, "Hex color 2 (right half — optional)", "color2", "#00aaff")
    local tbIcon     = field(pgTags, "Roblox Image ID (or gif:id:cols:rows:fps)", "icon", "1234567890  or  gif:1234567890:4:4:12")
    local tbTags     = field(pgTags, "Tags (comma separated)", "tags", "Owner,Dev")
    local tbCustom   = field(pgTags, "Custom chip text (owner override — optional)", "customText", "VIP")
    local tbHandle   = field(pgTags, "Custom @handle (overrides @user — optional)", "customHandle", "despair")

    -- effect dropdown
    local effDD = dropdown(pgTags, "Particle effect", EFFECT_OPTS, function(v) form.effect = v end)
    -- text animation dropdown
    local txDD  = dropdown(pgTags, "Text animation", TEXTFX_OPTS, function(v) form.textFx = v end)

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
        -- split "color" / "color/color2" back into the two fields
        local rawColor = (e and e.color) or ""
        local c1str, c2str = rawColor:match("([^/]+)/([^/]+)")
        if c1str and c2str then
            tbColor.Text  = (c1str:gsub("^%s+",""):gsub("%s+$",""))
            tbColor2.Text = (c2str:gsub("^%s+",""):gsub("%s+$",""))
        else
            tbColor.Text  = rawColor
            tbColor2.Text = ""
        end
        local iconRaw = tostring((e and e.icon) or "")
        if iconRaw:lower():sub(1, 4) == "gif:" then
            -- keep gif spec intact (e.g. "gif:1234567890:4:4:12")
            tbIcon.Text = iconRaw
        else
            tbIcon.Text = iconRaw:gsub("rbxassetid://", ""):gsub("%D", ""):gsub("^%s+",""):gsub("%s+$","")
        end
        tbTags.Text     = (e and e.tags and table.concat(e.tags, ",")) or ""
        tbCustom.Text   = (e and e.customText) or ""
        tbHandle.Text   = (e and e.customHandle) or ""
        effDD.set(e and e.effect or "none")
        txDD.set(e and e.textFx or "none")
    end

    local function clearForm() loadForm(nil, nil) end

    local function applyToMatchingPlayer(user)
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Name:lower() == user:lower() then
                TagDB:applyTo(p)
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
                BackgroundColor3 = parseColor(e.color or "") or T.acc,
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
                local prev = TagDB.entries[k]
                TagDB.entries[k] = nil
                -- clear icon + tags from any matching player in-server
                for _, p in ipairs(Players:GetPlayers()) do
                    if p.Name:lower() == k then
                        if prev and prev.icon then TagIcons:set(p.UserId, nil) end
                        if prev and type(prev.tags) == "table" then
                            for _, t in ipairs(prev.tags) do Tags:remove(p.UserId, t) end
                        end
                        pcall(refreshBill, p)
                    end
                end
                rebuildList()
                notify("Removed tag entry: " .. k, "warn")
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

    section(pgTags, "Actions")

    button(pgTags, "Save / Update entry", function()
        local u = (form.username or ""):gsub("^%s+",""):gsub("%s+$","")
        if u == "" then notify("Username required", "bad"); return end
        local key = u:lower()
        local entry = {}
        if form.displayName ~= "" then entry.displayName = form.displayName end
        local c1 = (form.color or ""):gsub("^%s+",""):gsub("%s+$","")
        local c2 = (form.color2 or ""):gsub("^%s+",""):gsub("%s+$","")
        if c1 ~= "" and c2 ~= "" then entry.color = c1 .. "/" .. c2
        elseif c1 ~= "" then entry.color = c1 end
        if form.icon ~= "" then
            local raw = tostring(form.icon):gsub("^%s+",""):gsub("%s+$","")
            if raw:lower():sub(1, 4) == "gif:" then
                -- keep gif sprite-sheet spec as-is
                entry.icon = raw
            else
                local cleanId = raw:gsub("rbxassetid://", ""):gsub("%D", "")
                if cleanId ~= "" then entry.icon = cleanId end
            end
        end
        if form.effect and form.effect ~= "none" then entry.effect = form.effect end
        if form.textFx and form.textFx ~= "none" then entry.textFx = form.textFx end
        if form.customText and form.customText ~= "" then entry.customText = form.customText end
        if form.customHandle and form.customHandle ~= "" then
            entry.customHandle = (form.customHandle:gsub("^@",""):gsub("^%s+",""):gsub("%s+$",""))
        end
        if form.tags ~= "" then
            local list = {}
            for t in (form.tags .. ","):gmatch("([^,]*),") do
                t = t:gsub("^%s+",""):gsub("%s+$","")
                if t ~= "" then list[#list+1] = t end
            end
            if #list > 0 then entry.tags = list end
        end
        -- if editing under a renamed key, drop old key first
        if editingKey and editingKey ~= key then TagDB.entries[editingKey] = nil end
        TagDB.entries[key] = entry
        applyToMatchingPlayer(u)
        rebuildList()
        clearForm()
        notify("Saved tag for " .. u, "good")
    end)

    button(pgTags, "Clear form / new entry", function() clearForm() end)

    button(pgTags, "Apply all to server (refresh bubbles)", function()
        for _, p in ipairs(Players:GetPlayers()) do
            TagDB:applyTo(p)
            pcall(refreshBill, p)
        end
        notify("Refreshed all player tags", "good")
    end)

    button(pgTags, "Reload from pastebin (discards unsaved)", function()
        task.spawn(function()
            TagDB:load()
            for _, p in ipairs(Players:GetPlayers()) do
                TagDB:applyTo(p); pcall(refreshBill, p)
            end
            rebuildList()
            notify("Reloaded from pastebin", "good")
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
        Text = "Paste this text into pastebin.com/wySWnyme to save permanently:",
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
        local keys = {}
        for k in pairs(TagDB.entries) do keys[#keys+1] = k end
        table.sort(keys)
        local lines = {}
        for _, k in ipairs(keys) do
            local e = TagDB.entries[k]
            local tagsStr = (e.tags and table.concat(e.tags, ",")) or ""
            lines[#lines+1] = table.concat({
                k,
                e.displayName or "",
                e.color or "",
                e.effect or "",
                e.icon or "",
                tagsStr,
                e.textFx or "",
                e.customText or "",
            }, " | ")
        end
        return table.concat(lines, "\n")
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

    rebuildList()
end





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
