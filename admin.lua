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
    Position = UDim2.new(1, -76, 0.5, 0),
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
local SIDE_W = 52
local HEADER_H = 38

local Side = inst("Frame", Body, {
    Size = UDim2.new(0, SIDE_W, 1, -12),
    Position = UDim2.new(0, 8, 0, 4),
    BackgroundColor3 = T.bg2,
    BackgroundTransparency = 0.2,
    BorderSizePixel = 0,
})
corner(Side, 12); stroke(Side, T.line, 1, 0.5)
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

local function setTab(name)
    local e = tabs[name]; if not e then return end
    for n, x in pairs(tabs) do
        if n ~= name then
            tween(x.btn, 0.12, { BackgroundTransparency = 1 })
            x.ico.TextColor3 = T.sub
            x.page.Visible = false
        end
    end
    tween(e.btn, 0.12, { BackgroundTransparency = 0.15, BackgroundColor3 = T.acc })
    e.ico.TextColor3 = T.text
    e.page.Visible = true
    HeaderTitle.Text = e.title or name
    HeaderSub.Text   = e.subtitle or ""
    currentTab = name
end

local function makeTab(name, icon, subtitle)
    local btn = inst("TextButton", Side, {
        Size = UDim2.new(0, 36, 0, 36),
        BackgroundColor3 = T.bg3,
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Text = "",
    })
    corner(btn, 10)
    local ico = inst("TextLabel", btn, {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Font = Enum.Font.GothamBold, TextSize = 18,
        TextColor3 = T.sub,
        Text = icon or "•",
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

    local entry = { btn = btn, page = page, ico = ico, title = name, subtitle = subtitle }
    tabs[name] = entry

    btn.MouseEnter:Connect(function()
        if currentTab ~= name then
            tween(btn, 0.12, { BackgroundTransparency = 0.55, BackgroundColor3 = T.bg3 })
            ico.TextColor3 = T.text
        end
        local pad = 14
        Tip.Text = name
        Tip.Size = UDim2.new(0, math.max(60, #name * 7 + pad), 0, 22)
        local abs = btn.AbsolutePosition; local sz = btn.AbsoluteSize
        local winPos = Win.AbsolutePosition
        Tip.Position = UDim2.new(0, abs.X - winPos.X + sz.X + 8, 0, abs.Y - winPos.Y + (sz.Y/2) - 11)
        Tip.Visible = true
    end)
    btn.MouseLeave:Connect(function()
        if currentTab ~= name then
            tween(btn, 0.12, { BackgroundTransparency = 1 })
            ico.TextColor3 = T.sub
        end
        Tip.Visible = false
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

local TagDB = { entries = {}, localEntries = {}, appliedTags = {}, appliedIcons = {} }
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
    elseif low:sub(1,6) == "image:" or low:sub(1,4) == "img:" then
        local rest = s:gsub("^[Ii][Mm][Aa][Gg][Ee]:", ""):gsub("^[Ii][Mm][Gg]:", "")
        rest = rest:gsub("^%s+", ""):gsub("%s+$", "")
        if rest == "" then return nil end
        local url = rest
        if tonumber(url) then
            url = "rbxassetid://" .. url
        elseif not (url:match("^rbx") or url:match("^https?://")) then
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
function TagDB:configFor(p)
    if not p then return nil end
    return self.entries[(p.Name or ""):lower()]
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

-- Local persistence: any tag the owner saves/deletes in the in-game panel is
-- written to disk so it survives rejoin even if the pastebin doesn't have it.
-- Local overrides take priority over the pastebin entry for the same username.
local TAGS_LOCAL_FILE = "seige_tags_overrides.json"
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
        if type(v) == "table" then out[tostring(k):lower()] = v end
    end
    return out
end
function TagDB:mergeLocal()
    local local_ = self:loadLocal()
    self.localEntries = local_ or {}
    if not local_ then return 0 end
    local n = 0
    for k, v in pairs(local_) do self.entries[k] = v; n = n + 1 end
    if n > 0 then print(("[Tags] merged %d local override(s)"):format(n)) end
    return n
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
                self:mergeLocal()
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
        warn("[Tags] DB fetch failed — using local overrides only")
        self.entries = {}
        self:mergeLocal()
        return
    end
    local fn, err = loadstring(src)
    if not fn then warn("[Tags] compile: " .. tostring(err)); self.entries = {}; self:mergeLocal(); return end
    local ok, data = pcall(fn)
    if not ok or type(data) ~= "table" then
        warn("[Tags] eval failed: " .. tostring(data)); self.entries = {}; self:mergeLocal(); return
    end
    local entries = {}
    for k, v in pairs(data) do entries[tostring(k):lower()] = v end
    self.entries = entries
    print(("[Tags] GitHub DB loaded — %d entries"):format((function() local n=0; for _ in pairs(entries) do n=n+1 end; return n end)()))
    self:mergeLocal()
end



local function tagColor(p)
    if Tags:has(p.UserId, "Target") then return T.bad end
    if Tags:has(p.UserId, "Friend") then return T.good end
    if Tags:has(p.UserId, "Priority") then return T.warn end
    if Tags:has(p.UserId, "Ignore") then return T.dim end
    return T.acc
end

------------------------------------------------------- TABS
local pgProfile = makeTab("Profile", "◈", "Your account, recent games and friends")
local pgPlayers = makeTab("Players", "◉", "Server roster and player tools")
local pgSelf    = makeTab("Self",    "✦", "Character, speed, flight, jump")
local pgVisuals = makeTab("Visuals", "◐", "ESP, lighting and fullbright")
local pgWorld   = makeTab("World",   "◊", "World tweaks and movement")
-- Tags tab removed — now managed via the script database (tags.lua)
-- Aim moved to Cmds tab as commands (pgAim retained as hidden frame for legacy refs)

local pgServer  = makeTab("Server",  "≡", "Server hop and rejoin")
local pgCmds    = makeTab("Cmds",    "⌘", "Quick commands, executor and rejoin")
local pgThemes  = makeTab("Themes",  "✿", "Customize colors and background")
local pgShaders = makeTab("Shaders", "✷", "Real post-processing: bloom, blur, DOF, color")
local pgConfig  = makeTab("Config",  "⚙", "Settings and keybinds")

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
    -- Bubble fill: solid / split / gradient / image
    if e.bgGrad then
        local fill = parseFill(cfg and cfg.color)
        if fill and fill.kind == "image" then
            if e.bgImg then
                e.bgImg.Image = fill.url
                e.bgImg.ImageTransparency = 0
                e.bgImg.Visible = true
            end
            e.bg.BackgroundTransparency = 1
            e.bgGrad.Color = ColorSequence.new(Color3.new(1, 1, 1))
        elseif fill and fill.kind == "gradient" then
            if e.bgImg then e.bgImg.Visible = false end
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
            e.bgGrad.Rotation = 90
            e.bgGrad.Color = ColorSequence.new(fill.c, fill.c)
            e.bg.BackgroundColor3 = Color3.new(1, 1, 1)
            e.bg.BackgroundTransparency = 0
        else
            if e.bgImg then e.bgImg.Visible = false end
            e.bgGrad.Rotation = 90
            e.bgGrad.Color = ColorSequence.new(Color3.fromRGB(32, 32, 42), Color3.fromRGB(14, 14, 18))
            e.bg.BackgroundColor3 = T.bg
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
    -- image fill layer (sits above gradient, below text/avatar via ZIndex)
    local bgImg = inst("ImageLabel", bg, {
        Name = "bgImg",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ImageTransparency = 1,
        ScaleType = Enum.ScaleType.Crop,
        Visible = false,
        ZIndex = 1,
        Image = "",
    })
    corner(bgImg, 21)
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
    tagBills[p] = { gui = gui, bg = bg, bgGrad = bgGrad, bgImg = bgImg, fx = fx, stroke = st, name = nm, handle = hd, stat = stx, dot = dot, sh = sh, av = av, clickBtn = clickBtn, base = math.random() * 6.28, effect = nil, fxToken = 0, gifToken = 0, gifKey = nil }
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
        -- always build the bubble for LP, for everyone if floatOn,
        -- and for ANY player that has a saved tag entry (so rejoining users
        -- always see their persisted custom tag).
        if floatOn or p == LP or TagDB:configFor(p) then buildBill(p) end
    end))
end

bind(Players.PlayerAdded:Connect(function(p)
    hookCharBill(p)
    TagDB:applyTo(p)
    -- if the player has a persisted tag entry and is already in their character,
    -- build immediately so we don't have to wait for the next respawn.
    task.defer(function()
        if pchar(p) and not tagBills[p] and (floatOn or TagDB:configFor(p)) then
            pcall(buildBill, p)
        end
    end)
end))
for _, p in ipairs(Players:GetPlayers()) do hookCharBill(p) end

-- Load the script-managed tag database, then apply to all players
task.spawn(function()
    TagDB:load()
    for _, p in ipairs(Players:GetPlayers()) do
        TagDB:applyTo(p)
        -- ensure persisted entries get a bubble on script reload too
        if pchar(p) and not tagBills[p] and (floatOn or p == LP or TagDB:configFor(p)) then
            pcall(buildBill, p)
        end
    end
    task.defer(rebuildBills)
end)


------------------------------------------------------- TAGS MANAGER (owner-only)
-- In-game GUI to add/edit/remove tag entries without touching code or pastebin.
-- Changes apply LIVE to everyone in the server. Export button copies a
-- pastebin-formatted text block to your clipboard so you can save permanently.
if LP.Name == "0rot3" then
    local EFFECT_OPTS = { "none", "rain", "snow", "sparkle", "nebula" }
    local TEXTFX_OPTS = { "none", "glitch", "type", "explode" }

    local pgTags = makeTab("Tags", "✎", "Custom tags, colors and icons")

    -- form values
    local form = {
        username = "", displayName = "", color = "", color2 = "", fill = "",
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
    local tbFill     = field(pgTags, "Advanced fill (overrides hex) — grad:#a,#b@90  or  image:1234567",
                              "fill", "grad:#ff3b6b,#00aaff@45   or   image:1234567890")
    local tbIcon     = field(pgTags, "Roblox Image ID (or sprite:id:cols:rows:fps)", "icon", "1234567890  or  sprite:1234567890:4:4:12  or  gif:1234567890:4:4:12")
    local tbTags     = field(pgTags, "Tags (comma separated)", "tags", "Owner,Dev")
    local tbCustom   = field(pgTags, "Custom chip text (owner override — optional)", "customText", "VIP")
    local tbHandle   = field(pgTags, "Custom @handle (overrides @user — optional)", "customHandle", "despair")

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
        -- color storage: solid "#hex", split "#a/#b", "grad:..." or "image:..."
        local rawColor = (e and e.color) or ""
        local rcLow = rawColor:lower()
        if rcLow:sub(1,5) == "grad:" or rcLow:sub(1,9) == "gradient:"
           or rcLow:sub(1,6) == "image:" or rcLow:sub(1,4) == "img:" then
            tbFill.Text  = rawColor
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
        effDD.set(e and e.effect or "none")
        txDD.set(e and e.textFx or "none")
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
                    pcall(function() tagBills[p].gui:Destroy() end)
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
                TagDB.entries[k] = nil
                TagDB.localEntries[k] = nil
                -- clear saved icon + tags from any matching player in-server
                for _, p in ipairs(Players:GetPlayers()) do
                    if p.Name:lower() == k then
                        TagDB:applyTo(p)
                        if tagBills[p] then
                            pcall(function() tagBills[p].gui:Destroy() end)
                            tagBills[p] = nil
                        end
                        if floatOn or p == LP or TagDB:configFor(p) then pcall(buildBill, p) end
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

    section(pgTags, "Actions")

    button(pgTags, "Save / Update entry", function()
        local u = (form.username or ""):gsub("^%s+",""):gsub("%s+$","")
        if u == "" then notify("Username required", "bad"); return end
        local key = u:lower()
        local entry = {}
        if form.displayName ~= "" then entry.displayName = form.displayName end
        local fillRaw = (form.fill or ""):gsub("^%s+",""):gsub("%s+$","")
        local c1 = (form.color or ""):gsub("^%s+",""):gsub("%s+$","")
        local c2 = (form.color2 or ""):gsub("^%s+",""):gsub("%s+$","")
        if fillRaw ~= "" then
            -- advanced fill (grad:... / image:...) takes priority
            entry.color = fillRaw
        elseif c1 ~= "" and c2 ~= "" then entry.color = c1 .. "/" .. c2
        elseif c1 ~= "" then entry.color = c1 end
        if form.icon ~= "" then
            local raw = tostring(form.icon):gsub("^%s+",""):gsub("%s+$","")
            local lower = raw:lower()
            if lower:sub(1, 4) == "gif:" or lower:sub(1, 7) == "sprite:" then
                -- keep gif/sprite sheet spec as-is (supports raw id or rbxassetid:// in id segment)
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
        if sok then notify("Saved tag for " .. u .. " (persisted)", "good")
        else notify("Saved tag for " .. u .. " — local save failed: " .. tostring(serr), "warn") end
        if _G.__SeigePbPush then task.spawn(_G.__SeigePbPush) end
    end)

    button(pgTags, "Clear form / new entry", function() clearForm() end)

    button(pgTags, "Apply all to server (refresh bubbles)", function()
        for _, p in ipairs(Players:GetPlayers()) do
            TagDB:applyTo(p)
            if tagBills[p] then
                pcall(function() tagBills[p].gui:Destroy() end)
                tagBills[p] = nil
            end
            pcall(buildBill, p)
        end
        notify("Refreshed all player tags", "good")
    end)

    button(pgTags, "Reload from pastebin (discards unsaved)", function()
        task.spawn(function()
            TagDB:load()
            for _, p in ipairs(Players:GetPlayers()) do
                TagDB:applyTo(p)
                if tagBills[p] then
                    pcall(function() tagBills[p].gui:Destroy() end)
                    tagBills[p] = nil
                end
                pcall(buildBill, p)
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
                e.customHandle or "",
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

    ------------------------------------------------------------------
    -- PASTEBIN SYNC  ·  push in-game edits to the actual pastebin URL
    ------------------------------------------------------------------
    section(pgTags, "Pastebin sync")

    local PB_CFG_FILE = "seige_pastebin.json"
    local pbCfg = { devKey = "", userKey = "", pasteKey = "wySWnyme", autoPush = false }

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

    -- URL-encode a string for application/x-www-form-urlencoded
    local function urlEncode(s)
        s = tostring(s or "")
        s = s:gsub("\n", "\r\n")
        s = s:gsub("([^%w%-%.%_%~])", function(c)
            return string.format("%%%02X", string.byte(c))
        end)
        return s
    end

    -- Pick whichever HTTP-with-POST function the executor exposes
    local function httpPost(url, body, headers)
        local req = rawget(getfenv(), "request")
            or rawget(getfenv(), "http_request")
            or (rawget(getfenv(), "syn") and syn.request)
            or (rawget(getfenv(), "http") and http.request)
            or (rawget(getfenv(), "fluxus") and fluxus.request)
        if not req then return nil, "no executor http request function" end
        local ok, res = pcall(req, {
            Url = url, Method = "POST", Body = body,
            Headers = headers or { ["Content-Type"] = "application/x-www-form-urlencoded" },
        })
        if not ok then return nil, tostring(res) end
        return res, nil
    end

    -- Build form body (table -> "k=v&k=v")
    local function form(params)
        local parts = {}
        for k, v in pairs(params) do
            parts[#parts + 1] = urlEncode(k) .. "=" .. urlEncode(v)
        end
        return table.concat(parts, "&")
    end

    -- Send the current entries to pastebin.
    --   silent=true → only notify on failure
    -- Returns: ok, url_or_error
    local function pushToPastebin(silent)
        if pbCfg.devKey == "" then
            if not silent then notify("Set your Pastebin dev API key first", "bad") end
            return false, "missing dev key"
        end
        local body = buildExport()
        -- EDIT path: keeps the same URL so script users get changes automatically
        if pbCfg.userKey ~= "" and pbCfg.pasteKey ~= "" then
            local res, err = httpPost("https://pastebin.com/api/api_post.php", form({
                api_dev_key      = pbCfg.devKey,
                api_user_key     = pbCfg.userKey,
                api_paste_key    = pbCfg.pasteKey,
                api_option       = "edit",
                api_paste_code   = body,
                api_paste_name   = "seige_tags",
                api_paste_format = "text",
                api_paste_private= "1",
                api_paste_expire_date = "N",
            }))
            if not res then
                if not silent then notify("Pastebin edit failed: " .. tostring(err), "bad") end
                return false, err
            end
            local txt = tostring(res.Body or "")
            if txt:sub(1, 15) == "Bad API request" then
                if not silent then notify("Pastebin: " .. txt, "bad") end
                return false, txt
            end
            if not silent then notify("Pushed to pastebin (edited paste " .. pbCfg.pasteKey .. ")", "good") end
            return true, "https://pastebin.com/raw/" .. pbCfg.pasteKey
        end
        -- CREATE path: makes a new unlisted paste; URL changes each time
        local res, err = httpPost("https://pastebin.com/api/api_post.php", form({
            api_dev_key      = pbCfg.devKey,
            api_option       = "paste",
            api_paste_code   = body,
            api_paste_name   = "seige_tags",
            api_paste_format = "text",
            api_paste_private= "1",  -- unlisted
            api_paste_expire_date = "N",
        }))
        if not res then
            if not silent then notify("Pastebin push failed: " .. tostring(err), "bad") end
            return false, err
        end
        local txt = tostring(res.Body or "")
        if not txt:match("^https?://") then
            if not silent then notify("Pastebin: " .. txt, "bad") end
            return false, txt
        end
        local id = txt:match("pastebin%.com/([%w]+)") or ""
        local raw = id ~= "" and ("https://pastebin.com/raw/" .. id) or txt
        local clip = rawget(getfenv(), "setclipboard")
        if clip then pcall(clip, raw) end
        if not silent then
            notify("Created paste: " .. raw .. " (copied)", "good")
        end
        return true, raw
    end

    -- credential fields
    local function pbField(lbl, key, placeholder)
        local f = inst("Frame", pgTags, {
            Size = UDim2.new(1, -8, 0, 48),
            BackgroundColor3 = T.bg2, BackgroundTransparency = 0.3, BorderSizePixel = 0,
        })
        corner(f, 8); stroke(f, T.line, 1, 0.5)
        inst("TextLabel", f, {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 4),
            Size = UDim2.new(1, -20, 0, 14),
            Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = T.dim,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = string.upper(lbl),
        })
        local tb = inst("TextBox", f, {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 20),
            Size = UDim2.new(1, -20, 0, 22),
            PlaceholderText = placeholder or "",
            PlaceholderColor3 = T.dim,
            Font = Enum.Font.Code, TextSize = 12,
            TextColor3 = T.text,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = tostring(pbCfg[key] or ""),
            ClearTextOnFocus = false,
        })
        tb:GetPropertyChangedSignal("Text"):Connect(function()
            pbCfg[key] = tb.Text
        end)
        tb.FocusLost:Connect(function() savePbCfg() end)
        return tb
    end

    pbField("Pastebin API dev key (required)",   "devKey",   "paste your api_dev_key here")
    pbField("Pastebin API user key (for edit)",  "userKey",  "optional — needed to edit existing paste")
    pbField("Paste key to edit (URL slug)",      "pasteKey", "wySWnyme")

    toggle(pgTags, "Auto-push to pastebin on every save", pbCfg.autoPush, function(v)
        pbCfg.autoPush = v; savePbCfg()
    end)

    button(pgTags, "Push to pastebin now", function()
        task.spawn(function() pushToPastebin(false) end)
    end)

    button(pgTags, "Get user key from username/password (one-time)", function()
        if pbCfg.devKey == "" then notify("Set dev key first", "bad"); return end
        local user = rawget(getfenv(), "Lighting") -- placeholder; we collect via simple prompt
        -- Inline credential prompt
        local up = inst("Frame", Root, {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0, 320, 0, 160),
            BackgroundColor3 = T.bg2, BorderSizePixel = 0, ZIndex = 200,
        })
        corner(up, 10); stroke(up, T.line, 1, 0.4)
        inst("TextLabel", up, {
            BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 8),
            Size = UDim2.new(1, -24, 0, 18), Font = Enum.Font.GothamBold, TextSize = 12,
            TextColor3 = T.text, TextXAlignment = Enum.TextXAlignment.Left,
            Text = "Pastebin login (one-time)", ZIndex = 201,
        })
        local function mkBox(y, ph)
            local b = inst("TextBox", up, {
                BackgroundColor3 = T.bg, BackgroundTransparency = 0.1, BorderSizePixel = 0,
                Position = UDim2.new(0, 12, 0, y), Size = UDim2.new(1, -24, 0, 26),
                Font = Enum.Font.Code, TextSize = 12, TextColor3 = T.text,
                PlaceholderText = ph, PlaceholderColor3 = T.dim,
                ClearTextOnFocus = false, Text = "", ZIndex = 201,
            })
            corner(b, 6); stroke(b, T.line, 1, 0.4)
            return b
        end
        local uBox = mkBox(32, "pastebin username")
        local pBox = mkBox(64, "pastebin password")
        local function close() up:Destroy() end
        local cancel = inst("TextButton", up, {
            Position = UDim2.new(0, 12, 1, -34), Size = UDim2.new(0, 90, 0, 26),
            BackgroundColor3 = T.bg3, BorderSizePixel = 0, AutoButtonColor = false,
            Font = Enum.Font.GothamSemibold, TextSize = 12, TextColor3 = T.text,
            Text = "Cancel", ZIndex = 201,
        })
        corner(cancel, 6); cancel.MouseButton1Click:Connect(close)
        local ok = inst("TextButton", up, {
            AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 1, -34),
            Size = UDim2.new(0, 90, 0, 26),
            BackgroundColor3 = T.acc, BorderSizePixel = 0, AutoButtonColor = false,
            Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = T.text,
            Text = "Login", ZIndex = 201,
        })
        corner(ok, 6)
        ok.MouseButton1Click:Connect(function()
            local un, pw = uBox.Text, pBox.Text
            close()
            task.spawn(function()
                local res, err = httpPost("https://pastebin.com/api/api_login.php", form({
                    api_dev_key       = pbCfg.devKey,
                    api_user_name     = un,
                    api_user_password = pw,
                }))
                if not res then notify("Login failed: " .. tostring(err), "bad"); return end
                local body = tostring(res.Body or "")
                if body:sub(1, 15) == "Bad API request" then
                    notify("Pastebin: " .. body, "bad"); return
                end
                pbCfg.userKey = body; savePbCfg()
                notify("User key saved", "good")
            end)
        end)
    end)

    label(pgTags, "Tip: with both user key + paste key, edits update the SAME URL in place.")
    label(pgTags, "Without them, each push creates a new unlisted paste (URL is copied to clipboard).")

    -- Expose for the Save button to auto-push
    _G.__SeigePbPush = function() if pbCfg.autoPush then pushToPastebin(true) end end

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

------------------------------------------------------- CMDS TAB
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

------------------------------------------------------- EXECUTOR BAR (Cmds)
section(pgCmds, "Executor")

local execFrame = inst("Frame", pgCmds, {
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

local execEnabled = false
toggle(pgCmds, "Show execution bar", false, function(v)
    execEnabled = v
    execFrame.Visible = v
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
local function cToHex(c)
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

local bgState = { image = "", trans = 0.4 }
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

local saveCfg, loadCfg
saveCfg = function()
    local data = { theme = {}, bg = bgState, execEnabled = execEnabled }
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
end

section(pgThemes, "Background")
local bgImgBox = textbox(pgThemes, "Image / GIF asset id or URL (rbxassetid://, http://...)", function(v)
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
local ROLE_ORDER = { "bg","bg2","bg3","line","text","sub","dim","acc","acc2","good","warn","bad" }
local roleRows = {}
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
    end
end
for _, name in ipairs({"Off","Cinematic","Dreamy","Noir","Vibrant"}) do
    button(pgShaders, name, function() applyShader(name) end)
end
end -- end shaders scope

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

------------------------------------------------------- PROFILE TAB
do
    section(pgProfile, "Account")
    local row = inst("Frame", pgProfile, { Size = UDim2.new(1,-8,0,88), BackgroundTransparency = 1 })
    local av = inst("ImageLabel", row, {
        Size = UDim2.new(0,80,0,80),
        Position = UDim2.new(0,0,0,4),
        BackgroundColor3 = T.bg3, BorderSizePixel = 0,
    })
    corner(av, 14); stroke(av, T.line, 1, 0.5)
    pcall(function()
        av.Image = Players:GetUserThumbnailAsync(LP.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
    end)

    inst("TextLabel", row, {
        BackgroundTransparency = 1,
        Position = UDim2.new(0,92,0,4),
        Size = UDim2.new(1,-92,0,22),
        Font = Enum.Font.GothamBold, TextSize = 16,
        TextColor3 = T.text, TextXAlignment = Enum.TextXAlignment.Left,
        Text = tostring(LP.DisplayName or LP.Name),
    })
    inst("TextLabel", row, {
        BackgroundTransparency = 1,
        Position = UDim2.new(0,92,0,28),
        Size = UDim2.new(1,-92,0,16),
        Font = Enum.Font.Gotham, TextSize = 12,
        TextColor3 = T.sub, TextXAlignment = Enum.TextXAlignment.Left,
        Text = "@" .. LP.Name,
    })
    inst("TextLabel", row, {
        BackgroundTransparency = 1,
        Position = UDim2.new(0,92,0,48),
        Size = UDim2.new(1,-92,0,34),
        Font = Enum.Font.Gotham, TextSize = 11,
        TextColor3 = T.dim, TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true,
        Text = "UserId: " .. LP.UserId .. "  ·  AccountAge: " .. LP.AccountAge .. "d",
    })

    section(pgProfile, "Live clock")
    local liveClock = inst("TextLabel", pgProfile, {
        Size = UDim2.new(1,-8,0,46),
        BackgroundColor3 = T.bg3, BackgroundTransparency = 0.3, BorderSizePixel = 0,
        Font = Enum.Font.GothamBlack, TextSize = 20,
        TextColor3 = T.text,
        Text = os.date("%I:%M:%S %p  ·  %a %b %d"),
    })
    corner(liveClock, 10); stroke(liveClock, T.line, 1, 0.5)
    task.spawn(function()
        while liveClock and liveClock.Parent do
            liveClock.Text = os.date("%I:%M:%S %p  ·  %a %b %d")
            task.wait(1)
        end
    end)

    section(pgProfile, "Recent games (created)")
    local gamesList = inst("Frame", pgProfile, {
        Size = UDim2.new(1,-8,0,0), BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y,
    })
    inst("UIListLayout", gamesList, { Padding = UDim.new(0,4), SortOrder = Enum.SortOrder.LayoutOrder })
    local gamesStatus = inst("TextLabel", pgProfile, {
        Size = UDim2.new(1,-8,0,16), BackgroundTransparency = 1,
        Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = T.dim, TextXAlignment = Enum.TextXAlignment.Left,
        Text = "Loading…",
    })

    section(pgProfile, "Friends")
    local friendsList = inst("Frame", pgProfile, {
        Size = UDim2.new(1,-8,0,0), BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y,
    })
    inst("UIListLayout", friendsList, { Padding = UDim.new(0,4), SortOrder = Enum.SortOrder.LayoutOrder })
    local friendsStatus = inst("TextLabel", pgProfile, {
        Size = UDim2.new(1,-8,0,16), BackgroundTransparency = 1,
        Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = T.dim, TextXAlignment = Enum.TextXAlignment.Left,
        Text = "Loading…",
    })

    local function clearChildren(p)
        for _, c in ipairs(p:GetChildren()) do
            if not c:IsA("UIListLayout") then c:Destroy() end
        end
    end

    local function addGameRow(g)
        local f = inst("Frame", gamesList, {
            Size = UDim2.new(1,0,0,40),
            BackgroundColor3 = T.bg3, BackgroundTransparency = 0.4, BorderSizePixel = 0,
        })
        corner(f, 8); stroke(f, T.line, 1, 0.5)
        inst("TextLabel", f, {
            BackgroundTransparency = 1, Position = UDim2.new(0,10,0,4), Size = UDim2.new(1,-110,0,18),
            Font = Enum.Font.GothamSemibold, TextSize = 12, TextColor3 = T.text,
            TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
            Text = tostring(g.name or "Untitled"),
        })
        inst("TextLabel", f, {
            BackgroundTransparency = 1, Position = UDim2.new(0,10,0,22), Size = UDim2.new(1,-110,0,14),
            Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = T.dim,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = "PlaceId: " .. tostring((g.rootPlace and g.rootPlace.id) or g.id or "?"),
        })
        local b = inst("TextButton", f, {
            AnchorPoint = Vector2.new(1,0.5), Position = UDim2.new(1,-8,0.5,0), Size = UDim2.new(0,84,0,24),
            BackgroundColor3 = T.acc, BackgroundTransparency = 0.2, BorderSizePixel = 0, AutoButtonColor = false,
            Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = T.text, Text = "Teleport",
        })
        corner(b, 6)
        b.MouseButton1Click:Connect(function()
            local pid = (g.rootPlace and g.rootPlace.id) or g.id
            if pid then pcall(function() TeleportSrv:Teleport(tonumber(pid), LP) end) end
        end)
    end

    local function addBucketLabel(text)
        inst("TextLabel", friendsList, {
            Size = UDim2.new(1,0,0,16), BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = T.dim,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = string.upper(text),
        })
    end

    local function addFriendRow(f, statusText, statusColor)
        local r = inst("Frame", friendsList, {
            Size = UDim2.new(1,0,0,42),
            BackgroundColor3 = T.bg3, BackgroundTransparency = 0.4, BorderSizePixel = 0,
        })
        corner(r, 8); stroke(r, T.line, 1, 0.5)
        local img = inst("ImageLabel", r, {
            Position = UDim2.new(0,6,0,5), Size = UDim2.new(0,32,0,32),
            BackgroundColor3 = T.bg, BorderSizePixel = 0,
        })
        corner(img, 8)
        pcall(function() img.Image = Players:GetUserThumbnailAsync(f.userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100) end)
        inst("TextLabel", r, {
            BackgroundTransparency = 1, Position = UDim2.new(0,46,0,4), Size = UDim2.new(1,-186,0,16),
            Font = Enum.Font.GothamSemibold, TextSize = 12, TextColor3 = T.text,
            TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
            Text = tostring(f.displayName or f.username or "user"),
        })
        inst("TextLabel", r, {
            BackgroundTransparency = 1, Position = UDim2.new(0,46,0,20), Size = UDim2.new(1,-186,0,14),
            Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = T.sub,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = "@" .. tostring(f.username or ""),
        })
        inst("TextLabel", r, {
            BackgroundTransparency = 1, AnchorPoint = Vector2.new(1,0.5),
            Position = UDim2.new(1,-10,0.5,0), Size = UDim2.new(0,134,0,18),
            Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = statusColor or T.dim,
            TextXAlignment = Enum.TextXAlignment.Right,
            Text = statusText or "Offline",
        })
    end

    local function postJson(url, body)
        local ok, res = pcall(function()
            return HttpService:JSONDecode(game:HttpPost(url, body, false, "application/json"))
        end)
        if ok and res then return res end
        local req = (syn and syn.request) or (http and http.request) or rawget(getfenv(), "request") or rawget(getfenv(), "http_request")
        if req then
            local ok2, r = pcall(req, { Url = url, Method = "POST", Headers = {["Content-Type"]="application/json"}, Body = body })
            if ok2 and r and r.Body then
                local okj, decoded = pcall(function() return HttpService:JSONDecode(r.Body) end)
                if okj then return decoded end
            end
        end
        return nil
    end

    local function refreshGames()
        clearChildren(gamesList)
        gamesStatus.Text = "Loading…"
        task.spawn(function()
            local ok, res = pcall(function()
                return HttpService:JSONDecode(game:HttpGet(
                    "https://games.roblox.com/v2/users/" .. LP.UserId .. "/games?accessFilter=Public&sortOrder=Desc&limit=10"
                ))
            end)
            if ok and res and res.data and #res.data > 0 then
                for _, g in ipairs(res.data) do addGameRow(g) end
                gamesStatus.Text = "Showing " .. #res.data .. " games"
            elseif ok and res and res.data then
                gamesStatus.Text = "No public games."
            else
                gamesStatus.Text = "Failed to load games."
            end
        end)
    end

    local function refreshFriends()
        clearChildren(friendsList)
        friendsStatus.Text = "Loading friends…"
        task.spawn(function()
            local ok, pages = pcall(function() return Players:GetFriendsAsync(LP.UserId) end)
            if not ok or not pages then friendsStatus.Text = "Failed to load friends."; return end

            local all = {}
            local guard = 0
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
                guard = guard + 1
                if guard > 5 then break end
            end

            if #all == 0 then friendsStatus.Text = "No friends found."; return end

            -- Presence lookup
            local ids = {}
            for _, x in ipairs(all) do table.insert(ids, x.userId) end
            local presence = {}
            local pres = postJson("https://presence.roblox.com/v1/presence/users", HttpService:JSONEncode({ userIds = ids }))
            if pres and pres.userPresences then
                for _, p in ipairs(pres.userPresences) do presence[p.userId] = p end
            end

            -- In-this-server: cross-reference with Players in game
            local hereIds = {}
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LP then
                    local okFr = pcall(function() return LP:IsFriendsWith(p.UserId) end)
                    if okFr and LP:IsFriendsWith(p.UserId) then
                        hereIds[p.UserId] = true
                    end
                end
            end

            local here, sameGame, otherGame, online, offline = {}, {}, {}, {}, {}
            for _, f in ipairs(all) do
                local p = presence[f.userId]
                if hereIds[f.userId] then
                    table.insert(here, f)
                elseif p then
                    if p.userPresenceType == 2 then
                        if tonumber(p.rootPlaceId) == tonumber(game.PlaceId) then
                            table.insert(sameGame, f)
                        else
                            f._loc = p.lastLocation
                            table.insert(otherGame, f)
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

            local function addBucket(lbl, list, color)
                if #list == 0 then return end
                addBucketLabel(lbl .. "  (" .. #list .. ")")
                for _, f in ipairs(list) do
                    local txt = lbl
                    if f._loc and lbl == "In another game" then txt = tostring(f._loc) end
                    addFriendRow(f, txt, color)
                end
            end
            addBucket("In this server",  here,      Color3.fromRGB(120,255,160))
            addBucket("In this game",    sameGame,  Color3.fromRGB(160,220,255))
            addBucket("In another game", otherGame, Color3.fromRGB(255,200,120))
            addBucket("Online",          online,    Color3.fromRGB(180,180,255))
            addBucket("Offline",         offline,   T.dim)
            friendsStatus.Text = "Loaded " .. #all .. " friends."
        end)
    end

    button(pgProfile, "Refresh profile", function()
        refreshGames(); refreshFriends()
    end)

    -- Auto-load shortly after script start
    task.spawn(function() task.wait(0.5); refreshGames(); refreshFriends() end)
end

------------------------------------------------------- REDESIGN: TOP PILL + FLOATING PANELS
-- Replaces the legacy single-window layout. A slim top-center status pill
-- shows FPS/PING/brand + an icon button per tab. Clicking an icon toggles a
-- draggable floating popout for that tab (with an X to close). Multiple
-- popouts can be open at once. F2 hides everything.

Win.Visible = false   -- retire the legacy chrome (kept around for compat)

-- ============= TOP PILL ===========================================
local Pill = inst("Frame", Root, {
    Name = "TopPill",
    AnchorPoint = Vector2.new(0.5, 0),
    Position = UDim2.new(0.5, 0, 0, 14),
    Size = UDim2.new(0, 0, 0, 44),
    AutomaticSize = Enum.AutomaticSize.X,
    BackgroundColor3 = T.bg,
    BackgroundTransparency = 0.05,
    BorderSizePixel = 0,
    Active = true,
    ZIndex = 100,
})
corner(Pill, 14); stroke(Pill, T.line, 1, 0.4)
inst("UIGradient", Pill, {
    Rotation = 90,
    Color = ColorSequence.new(T.bg2, T.bg),
    Transparency = NumberSequence.new(0.08),
})
inst("UIPadding", Pill, {
    PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12),
    PaddingTop = UDim.new(0, 5),  PaddingBottom = UDim.new(0, 5),
})
inst("UIListLayout", Pill, {
    FillDirection = Enum.FillDirection.Horizontal,
    VerticalAlignment = Enum.VerticalAlignment.Center,
    Padding = UDim.new(0, 12),
    SortOrder = Enum.SortOrder.LayoutOrder,
})

-- Status (FPS + PING stacked)
local statBlock = inst("Frame", Pill, {
    Size = UDim2.new(0, 90, 1, -4), BackgroundTransparency = 1, LayoutOrder = 1, ZIndex = 101,
})
local fpsLbl = inst("TextLabel", statBlock, {
    BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 3),
    Size = UDim2.new(1, 0, 0, 14),
    Font = Enum.Font.GothamSemibold, TextSize = 11, TextColor3 = T.good,
    TextXAlignment = Enum.TextXAlignment.Left, Text = "● FPS --", ZIndex = 101,
})
local pingLbl = inst("TextLabel", statBlock, {
    BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 19),
    Size = UDim2.new(1, 0, 0, 14),
    Font = Enum.Font.GothamSemibold, TextSize = 11, TextColor3 = T.good,
    TextXAlignment = Enum.TextXAlignment.Left, Text = "● PING --", ZIndex = 101,
})

-- Brand (name + username)
local brandBlock = inst("Frame", Pill, {
    Size = UDim2.new(0, 120, 1, -4), BackgroundTransparency = 1, LayoutOrder = 2, ZIndex = 101,
})
inst("TextLabel", brandBlock, {
    BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 4),
    Size = UDim2.new(1, 0, 0, 14),
    Font = Enum.Font.GothamBlack, TextSize = 12, TextColor3 = T.text,
    TextXAlignment = Enum.TextXAlignment.Left, Text = "SEIGE.LOL", ZIndex = 101,
})
inst("TextLabel", brandBlock, {
    BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 20),
    Size = UDim2.new(1, 0, 0, 12),
    Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = T.sub,
    TextXAlignment = Enum.TextXAlignment.Left, Text = "@" .. LP.Name, ZIndex = 101,
})

-- Icon button row
local iconsRow = inst("Frame", Pill, {
    Size = UDim2.new(0, 0, 1, -4),
    AutomaticSize = Enum.AutomaticSize.X,
    BackgroundTransparency = 1, LayoutOrder = 3, ZIndex = 101,
})
inst("UIListLayout", iconsRow, {
    FillDirection = Enum.FillDirection.Horizontal,
    VerticalAlignment = Enum.VerticalAlignment.Center,
    Padding = UDim.new(0, 4),
    SortOrder = Enum.SortOrder.LayoutOrder,
})

-- Clock at far right
local pillClock = inst("TextLabel", Pill, {
    Size = UDim2.new(0, 78, 1, -4), BackgroundTransparency = 1, LayoutOrder = 99,
    Font = Enum.Font.GothamSemibold, TextSize = 12, TextColor3 = T.text,
    TextXAlignment = Enum.TextXAlignment.Right,
    Text = (os.date("%I:%M %p"):gsub("^0", "")), ZIndex = 101,
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
task.spawn(function()
    local Stats = game:GetService("Stats")
    while Pill and Pill.Parent do
        local dt = RunService.Heartbeat:Wait()
        local fps = math.floor(1 / math.max(dt, 1e-4))
        fpsLbl.Text = "● FPS " .. fps
        fpsLbl.TextColor3 = fps > 45 and T.good or (fps > 25 and T.warn or T.bad)
        local ok, ping = pcall(function()
            return math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        end)
        if ok and ping then
            pingLbl.Text = "● PING " .. ping .. "ms"
            pingLbl.TextColor3 = ping < 120 and T.good or (ping < 280 and T.warn or T.bad)
        end
        pillClock.Text = (os.date("%I:%M %p"):gsub("^0", ""))
    end
end)

-- ============= FLOATING PANELS ====================================
-- Move the tooltip out of the hidden Win and into Root for the new pill.
pcall(function() Tip.Parent = Root; Tip.ZIndex = 220 end)

local panels = {}
local panelSlot = 0
local function makePanel(name, entry)
    local page = entry.page
    panelSlot = panelSlot + 1
    local slotX = (panelSlot - 1) % 3
    local slotY = math.floor((panelSlot - 1) / 3)
    local frame = inst("Frame", Root, {
        Name = "Panel_" .. name,
        Position = UDim2.new(1, -350 - slotX * 14, 0, 80 + slotY * 32),
        Size = UDim2.new(0, 320, 0, 380),
        BackgroundColor3 = T.bg, BackgroundTransparency = 0.04, BorderSizePixel = 0,
        Visible = false, Active = true, ZIndex = 110,
    })
    corner(frame, 12); stroke(frame, T.line, 1, 0.4)
    inst("UIGradient", frame, {
        Rotation = 120,
        Color = ColorSequence.new(T.bg2, T.bg),
        Transparency = NumberSequence.new(0.05),
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

    xBtn.MouseButton1Click:Connect(function() frame.Visible = false end)

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
    return frame
end

-- preferred order on the pill
local tabOrder = {
    "Profile", "Players", "Self", "Visuals", "World",
    "Tags", "Aim", "Server", "Cmds", "Themes", "Shaders", "Config",
}
-- include any tabs that weren't listed (forward-compat)
for n, _ in pairs(tabs) do
    local found = false
    for _, x in ipairs(tabOrder) do if x == n then found = true; break end end
    if not found then tabOrder[#tabOrder + 1] = n end
end

local idx = 0
for _, name in ipairs(tabOrder) do
    local entry = tabs[name]
    if entry then
        idx = idx + 1
        makePanel(name, entry)
        local ib = inst("TextButton", iconsRow, {
            Size = UDim2.new(0, 32, 0, 32),
            BackgroundColor3 = T.bg3, BackgroundTransparency = 0.25, BorderSizePixel = 0,
            AutoButtonColor = false,
            Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = T.text,
            Text = (entry.ico and entry.ico.Text) or "•",
            LayoutOrder = idx, ZIndex = 102,
        })
        corner(ib, 8); stroke(ib, T.line, 1, 0.4)
        panels[name].btn = ib

        local function setHover(on)
            local p = panels[name]
            local active = p and p.frame.Visible
            if on then
                tween(ib, 0.12, { BackgroundColor3 = T.acc, BackgroundTransparency = 0.1 })
            else
                tween(ib, 0.12, {
                    BackgroundColor3 = active and T.acc or T.bg3,
                    BackgroundTransparency = active and 0.15 or 0.25,
                })
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
            p.frame.Visible = not p.frame.Visible
            setHover(false)
        end)
    end
end

-- setTab is now a no-op (panels manage their own visibility); keep symbol for
-- backwards compatibility with anything that might call it.
setTab = function() end

-- F2 toggle for the new chrome
bind(UIS.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.UserInputType == Enum.UserInputType.Keyboard and i.KeyCode == Enum.KeyCode.F2 then
        local v = not Pill.Visible
        Pill.Visible = v
        if not v then
            for _, p in pairs(panels) do p.frame.Visible = false end
        end
    end
end))

-- Open Profile by default
if panels.Profile then panels.Profile.frame.Visible = true end



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
