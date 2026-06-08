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

local closeBtn = topBtn("✕", -38, function()
    if _G.__AdminCleanup then _G.__AdminCleanup() end
end)
local minBtn = topBtn("—", -72, function()
    minimized = not minimized
    tween(Win, 0.18, { Size = minimized and UDim2.new(0,620,0,44) or UDim2.new(0,620,0,440) })
    Body.Visible = not minimized
end)

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
        tween(Win, 0.18, { Size = UDim2.new(0, 44, 0, 36) })
        toggleImg.Visible = false
        toggleBtn.Text = "≡"
    else
        toggleBtn.Text = ""
        toggleImg.Visible = true
        closeBtn.Visible = true
        minBtn.Visible = true
        tween(Win, 0.18, { Size = prevMinimized and UDim2.new(0,620,0,44) or UDim2.new(0,620,0,440) })
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
--   username | displayName | #hexcolor | effect | icon | tag1,tag2,tag3 | textFx | customText | customHandle | outline | font
--
--   - Only `username` is required. Leave any field blank to skip it (keep the |).
--   - hexcolor: a single hex like #ff3b6b, OR two hex values separated by `/`
--               to split the bubble in half (left/right), e.g. #ff3b6b/#00aaff,
--               OR an advanced fill spec like grad:#a,#b@90 or image:1234567890
--   - effect: rain | snow | sparkle | nebula   (or blank for none)
--   - icon:   Roblox image ID (raw number, e.g. 1234567890), OR an animated
--             sprite-sheet spec "gif:assetId:cols:rows:fps[:sheetSize]"
--             e.g. gif:1234567890:4:4:12   (16-frame 4x4 sheet at 12 fps;
--             sheetSize defaults to 1024)
--   - textFx: glitch | type | explode   (or blank for none)
--   - customText:   optional override for the right-side chip text (owner-only)
--   - customHandle: optional override for the "@name" line on the tag (owner-only).
--                   Anyone without an entry shows the anonymous "user" / "@user".
--   - outline: hex color for the tag text outline, or "off" to disable
--   - font:    per-user tag font name (Default | PermanentMarker | LuckiestGuy | Creepster)
--   - Lines starting with # or // are comments. Blank lines are ignored.
--
-- Example paste:
--   DESPAIRDEV293 | Despair | #ff3b6b/#00aaff | nebula |  | Owner,Dev | glitch | VIP | despair | #ffffff | LuckiestGuy
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
    elseif low:sub(1,6) == "image:" or low:sub(1,4) == "img:" or s:match("^%d+$") or low:match("^rbxassetid://") then
        -- Accept: "image:<id>", "img:<id>", a bare numeric asset id, or an rbxassetid url.
        -- Bare numbers are auto-treated as image fills so old pastebin entries
        -- that stored just the asset id still render correctly.
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
                if parts[10] and parts[10] ~= "" then entry.outline = parts[10] end
                if parts[11] and parts[11] ~= "" then entry.font = parts[11] end
                if parts[12] and parts[12] ~= "" then entry.sweep = parts[12]:lower() end
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
    -- Pastebin / remote is the source of truth. Only fill in local-only
    -- entries (keys the remote DB doesn't already define) so that edits made
    -- on pastebin always win over an older cached copy on disk. Stale local
    -- duplicates (keys now present in remote) are pruned and re-saved so the
    -- disk cache doesn't grow forever.
    local n, pruned = 0, 0
    for k, v in pairs(local_) do
        if self.entries[k] == nil then
            self.entries[k] = v
            n = n + 1
        else
            self.localEntries[k] = nil
            pruned = pruned + 1
        end
    end
    if pruned > 0 then pcall(function() self:saveLocal() end) end
    if n > 0 or pruned > 0 then
        print(("[Tags] merged %d local-only override(s), pruned %d stale"):format(n, pruned))
    end
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
local pgCmds    = makeTab("Cmds",    "⌘", "Quick commands, executor and rejoin")
local pgShaders = makeTab("Shaders", "☀", "Real post-processing: bloom, blur, DOF, color")
local pgSpotify = makeTab("Spotify", "♫", "Connect your token and control playback")
local pgConfig  = makeTab("Config",  "⚙", "Settings and keybinds")
local pgSkybox  = makeTab("Skybox",  "☁", "Skybox presets and atmosphere")
local pgMisc    = makeTab("Misc",    "⋯", "Other tools and experimental features")
-- Aliases — content for these older tabs now lives inside the Misc tab.
local pgWorld   = pgMisc
local pgThemes  = pgConfig  -- Themes/colors live under the Settings (Config) tab
local pgDetect  = pgMisc

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
    local thrp, myH = phrp(p), hrp()
    if not (thrp and myH) then notify("No character", "bad"); return end
    notify("Bringing " .. p.Name .. "...", "good")
    task.spawn(function()
        -- direct CFrame loop (works in non-FE / network-owned parts)
        for i = 1, 25 do
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
                for i = 1, 20 do
                    local t = phrp(p); if not t then break end
                    myH.CFrame = t.CFrame
                    pcall(function() firetouchinterest(tool.Handle, t, 0) end)
                    task.wait()
                    pcall(function() firetouchinterest(tool.Handle, t, 1) end)
                    task.wait(0.05)
                end
                myH.CFrame = saved
            end)
        end
        notify("Bring complete", "good")
    end)
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
bind(UIS.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.UserInputType == Enum.UserInputType.MouseButton1 and clickTp and UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
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
        BorderSizePixel = 0, ZIndex = 6,
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
        BorderSizePixel = 0, ZIndex = 6,
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
        BorderSizePixel = 0, ZIndex = 6,
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
        BorderSizePixel = 0, ZIndex = 6,
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
        if e.gui then e.gui:Destroy() end
        if e.clickDetector then pcall(function() e.clickDetector:Destroy() end) end
        pcall(NameHider.restore, p)
    end
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
    local chipColor
    if txt ~= "" then
        e.sh.Visible = true
        e.stat.Text = txt:gsub(",", " • ")
        chipColor = c1 or tagColor(p)
    else
        e.sh.Visible = false
        chipColor = c1 or (p == LP and T.good or T.acc)
    end
    e.dot.BackgroundColor3 = chipColor
    if e.avRing then e.avRing.Color = chipColor end
    if e.glow then
        e.glow.ImageColor3 = chipColor
        e.glow.ImageTransparency = (txt ~= "" or p == LP) and 0.45 or 0.6
    end

    -- Metal sweep highlight: default ON, disable when cfg.sweep == "off"
    local sweepOn = not (cfg and tostring(cfg.sweep or ""):lower() == "off")
    if e.sweep and sweepOn ~= e.sweepOn then
        e.sweepOn = sweepOn
        e.sweepToken = (e.sweepToken or 0) + 1
        if sweepOn then
            local myToken = e.sweepToken
            e.sweep.Visible = true
            task.spawn(function()
                local TweenService = game:GetService("TweenService")
                while e.sweepToken == myToken and e.sweep and e.sweep.Parent do
                    local w = (e.bg and e.bg.AbsoluteSize.X) or 200
                    e.sweep.Position = UDim2.new(0, -60, 0, -12)
                    local tw = TweenService:Create(
                        e.sweep,
                        TweenInfo.new(1.6, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
                        { Position = UDim2.new(0, w + 20, 0, -12) }
                    )
                    tw:Play()
                    task.wait(1.65)
                    task.wait(2.0 + math.random() * 1.5) -- pause between sweeps
                end
                if e.sweep then e.sweep.Visible = false end
            end)
        else
            e.sweep.Visible = false
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
        e.sh.Size   = UDim2.new(0, shW, 0, 24)
        chipBlock   = shW + 8
    end

    -- avatar(5+34) + gap(8) + text + chipBlock + right pad(10)
    local total = 5 + 34 + 8 + textW + chipBlock + 10
    if total < 120 then total = 120 end
    e.bg.Size  = UDim2.new(0, total, 0, 46)
    e.gui.Size = UDim2.new(0, total + 24, 0, 58)
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
        Size = UDim2.new(0, 240, 0, 58),
        StudsOffset = Vector3.new(0, 1.7, 0),
        AlwaysOnTop = true, LightInfluence = 0,
    })

    -- Soft outer glow halo (sits behind the pill, slightly larger & blurred via image)
    local glow = inst("ImageLabel", gui, {
        Name = "glow",
        BackgroundTransparency = 1,
        Image = "rbxasset://textures/ui/Controls/DropShadow.png",
        ImageColor3 = Color3.fromRGB(0, 0, 0),
        ImageTransparency = 0.35,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(12, 12, 244, 244),
        Size = UDim2.new(1, 24, 0, 60),
        Position = UDim2.new(0, -12, 0, 2),
        ZIndex = 0,
    })

    local bg = inst("Frame", gui, {
        Size = UDim2.new(1, 0, 0, 46), Position = UDim2.new(0, 0, 0, 6),
        BackgroundColor3 = T.bg, BackgroundTransparency = 0.05, BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 1,
    })
    corner(bg, 23)
    -- particle layer (sits above bg/image, below text/avatar)
    local fx = inst("Frame", bg, {
        Name = "fx", Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1, ZIndex = 5,
        ClipsDescendants = true,
    })

    local st = stroke(bg, T.acc, 1.4, 0.25)
    local bgGrad = inst("UIGradient", bg, {
        Rotation = 90,
        Color = ColorSequence.new(Color3.fromRGB(40,40,52), Color3.fromRGB(14,14,18)),
    })
    -- image fill layer (sits above gradient, below particles via ZIndex)
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

    -- Glossy top-shine highlight (above bg/image, below text)
    local shine = inst("Frame", bg, {
        Name = "shine",
        Size = UDim2.new(1, -4, 0, 18),
        Position = UDim2.new(0, 2, 0, 1),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        ZIndex = 3,
    })
    corner(shine, 18)
    inst("UIGradient", shine, {
        Rotation = 90,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.55),
            NumberSequenceKeypoint.new(1, 1),
        }),
    })

    -- Bottom subtle inner shadow for depth
    local underShade = inst("Frame", bg, {
        Name = "underShade",
        AnchorPoint = Vector2.new(0, 1),
        Size = UDim2.new(1, 0, 0, 16),
        Position = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.55,
        BorderSizePixel = 0,
        ZIndex = 3,
    })
    inst("UIGradient", underShade, {
        Rotation = 90,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(1, 0.55),
        }),
    })

    -- Metal sweep highlight (animated diagonal specular streak)
    local sweep = inst("Frame", bg, {
        Name = "sweep",
        Size = UDim2.new(0, 38, 1, 24),
        Position = UDim2.new(0, -50, 0, -12),
        Rotation = 18,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 4,
        Visible = false,
    })
    inst("UIGradient", sweep, {
        Rotation = 0,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0,   1),
            NumberSequenceKeypoint.new(0.45, 0.55),
            NumberSequenceKeypoint.new(0.5, 0.25),
            NumberSequenceKeypoint.new(0.55, 0.55),
            NumberSequenceKeypoint.new(1,   1),
        }),
    })


    local av = inst("ImageLabel", bg, {
        Size = UDim2.new(0, 34, 0, 34), Position = UDim2.new(0, 5, 0.5, -17),
        BackgroundColor3 = T.bg3, BorderSizePixel = 0, ScaleType = Enum.ScaleType.Crop,
        ZIndex = 10,
    })
    corner(av, 17)
    -- gradient ring around avatar — colored from chip color in refreshBill
    local avRing = stroke(av, T.acc, 2, 0.1)
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
        BackgroundColor3 = T.acc, BorderSizePixel = 0,
        ZIndex = 11,
    })
    corner(dot, 4)
    -- subtle glow on the dot
    stroke(dot, T.acc, 1, 0.4)
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

    tagBills[p] = { gui = gui, bg = bg, bgGrad = bgGrad, bgImg = bgImg, fx = fx, stroke = st, name = nm, handle = hd, stat = stx, dot = dot, sh = sh, av = av, avRing = avRing, glow = glow, shine = shine, sweep = sweep, sweepToken = 0, sweepOn = nil, clickBtn = clickBtn, clickDetector = cd, base = math.random() * 6.28, effect = nil, fxToken = 0, gifToken = 0, gifKey = nil }
    _G.__SeigeTagBills = tagBills
    NameHider.hide(p)
    refreshBill(p)
    if _G.__SeigeApplyTagFont then pcall(_G.__SeigeApplyTagFont) end
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
            -- tag stays locked to the head (no independent bob); it bounces naturally with the avatar's animation
            e.gui.StudsOffsetWorldSpace = Vector3.new(0, 0, 0)
            if not e.outlineOff then
                e.stroke.Transparency = 0.2 + (math.sin(t * 3 + e.base) + 1) * 0.1
            end
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
    local anim = _G.__SeigeBubbleAnim or "None"
    local amt  = tonumber(_G.__SeigeBubbleAmt) or 0.5
    for _, e in pairs(tagBills) do
        if e.textFx and e.gui and e.gui.Parent then
            pcall(applyTextFx, e, t, dt)
        end
        -- ----- Bubble animation (Themes tab) -----
        if anim ~= "None" and e.bg and e.bg.Parent then
            local sc = e.bg:FindFirstChildOfClass("UIScale")
            if not sc then sc = Instance.new("UIScale"); sc.Scale = 1; sc.Parent = e.bg end
            local phase = (e.base or 0) + t
            if anim == "Bounce" then
                sc.Scale = 1 + math.abs(math.sin(phase * 3)) * 0.15 * amt
            elseif anim == "Pulse" then
                sc.Scale = 1 + math.sin(phase * 4) * 0.08 * amt
            elseif anim == "Float" then
                pcall(function()
                    e.bg.Position = UDim2.new(0.5, 0, 0, math.sin(phase * 2) * 6 * amt)
                end)
            elseif anim == "Wobble" then
                pcall(function() e.bg.Rotation = math.sin(phase * 3) * 6 * amt end)
            elseif anim == "Shake" then
                pcall(function()
                    e.bg.Position = UDim2.new(0.5, math.sin(phase * 30) * 2 * amt, 0, math.cos(phase * 27) * 2 * amt)
                end)
            elseif anim == "Heartbeat" then
                local b = math.sin(phase * 6); b = b * b
                sc.Scale = 1 + b * 0.18 * amt
            end
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
        if tagBills[p] then pcall(NameHider.restore, p); pcall(function() tagBills[p].gui:Destroy() end); tagBills[p] = nil end
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
    -- Default tag for any executor without a custom entry: a "User" chip
    -- alongside their real DisplayName + @username + Roblox avatar.
    do
        local key = (LP.Name or ""):lower()
        if key ~= "" and not TagDB.entries[key] then
            TagDB.entries[key] = { tags = { "User" } }
        end
    end
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
        font = "Default", sweep = "on",
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
    local tbOutline  = field(pgTags, "Outline color (hex, or 'off' to disable)", "outline", "#ffffff   or   off")

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
    -- per-tag font (dafont-style picks)
    local TAG_FONT_OPTS = { "Default", "PermanentMarker", "LuckiestGuy", "Creepster" }
    local fontDD = dropdown(pgTags, "Tag font (per-user)", TAG_FONT_OPTS, function(v) form.font = v end)
    -- metal sweep highlight on/off (per tag)
    local sweepDD = dropdown(pgTags, "Metal sweep animation", { "on", "off" }, function(v) form.sweep = v end)

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
        tbOutline.Text  = (e and e.outline) or ""
        effDD.set(e and e.effect or "none")
        txDD.set(e and e.textFx or "none")
        fontDD.set((e and e.font) or "Default")
        sweepDD.set((e and e.sweep) or "on")
        form.sweep = (e and e.sweep) or "on"
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
                            pcall(NameHider.restore, p); pcall(function() tagBills[p].gui:Destroy() end)
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
        notify("Not in cache — refreshing pastebin…", "warn")
        task.spawn(function()
            local ok = pcall(function() TagDB:load() end)
            if not ok then notify("Pastebin fetch failed", "bad"); return end
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
        local function pick(formVal, tbText) return trimStr(formVal ~= "" and formVal or tbText) end
        local u = pick(form.username, tbUser.Text)
        if u == "" then notify("Username required", "bad"); return end
        local key = u:lower()
        local entry = {}
        local dn = pick(form.displayName, tbDisplay.Text)
        if dn ~= "" then entry.displayName = dn end
        local fillRaw = pick(form.fill, tbFill.Text)
        local c1 = pick(form.color, tbColor.Text)
        local c2 = pick(form.color2, tbColor2.Text)
        if fillRaw ~= "" then
            -- advanced fill takes priority. Normalize common shorthand so the
            -- pastebin export round-trips: a bare asset id (e.g. "132151218054089")
            -- or rbxassetid url becomes "image:<id>"; a single hex stays as-is so
            -- it parses as solid; everything else (grad:/image:/img:) saved verbatim.
            local fLow = fillRaw:lower()
            if fillRaw:match("^%d+$") then
                entry.color = "image:" .. fillRaw
            elseif fLow:match("^rbxassetid://") then
                entry.color = "image:" .. fillRaw:gsub("rbxassetid://", "")
            else
                entry.color = fillRaw
            end
        elseif c1 ~= "" and c2 ~= "" then entry.color = c1 .. "/" .. c2  -- split bubble (two hex)
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
        if form.effect and form.effect ~= "none" then entry.effect = form.effect end
        if form.textFx and form.textFx ~= "none" then entry.textFx = form.textFx end
        local ct = pick(form.customText, tbCustom.Text)
        if ct ~= "" then entry.customText = ct end
        local ch = pick(form.customHandle, tbHandle.Text)
        if ch ~= "" then entry.customHandle = (ch:gsub("^@","")) end
        local ol = pick(form.outline, tbOutline.Text)
        if ol ~= "" then entry.outline = ol end
        if form.font and form.font ~= "" and form.font ~= "Default" then
            entry.font = form.font
        end
        if form.sweep == "off" then entry.sweep = "off" end
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
        if sok then notify("Saved tag for " .. u .. " (persisted)", "good")
        else notify("Saved tag for " .. u .. " — local save failed: " .. tostring(serr), "warn") end
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

    button(pgTags, "Reload from pastebin (discards unsaved)", function()
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
                e.outline or "",
                e.font or "",
                e.sweep or "",
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
    local pbCfg = { devKey = "", userKey = "", pasteKey = "wySWnyme", autoPush = false, autoPull = true, pullInterval = 30 }

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

    -------------------------------------------------------------------
    -- AUTO-PULL  ·  detect remote pastebin edits and reflect them in
    -- the in-game tag editor so changes made on pastebin.com show up
    -- as editable entries without a rejoin.
    -------------------------------------------------------------------
    local lastPullHash = nil
    local function hashStr(s)
        -- cheap content fingerprint; sum + length is enough to detect edits
        s = tostring(s or "")
        local sum = 0
        for i = 1, #s do sum = (sum + s:byte(i) * i) % 2147483647 end
        return #s .. ":" .. sum
    end

    local function pullFromPastebin(silent)
        local src
        local ok = pcall(function()
            src = game:HttpGet(TAGS_PASTEBIN_URL .. (TAGS_PASTEBIN_URL:find("?") and "&" or "?") .. "v=" .. tostring(os.time()))
        end)
        if not ok or not src or src == "" then
            if not silent then notify("Pastebin pull failed", "bad") end
            return false, "fetch failed"
        end
        local h = hashStr(src)
        if lastPullHash and h == lastPullHash then
            if not silent then notify("Pastebin: no changes", "dim") end
            return true, "unchanged"
        end
        lastPullHash = h
        local entries, count = parsePastebin(src)
        if count == 0 then
            if not silent then notify("Pastebin parse returned 0 entries", "warn") end
            return false, "empty parse"
        end
        -- Preserve local overrides on top of the fresh remote snapshot
        TagDB.entries = entries
        TagDB:mergeLocal()
        -- Refresh live bubbles
        for _, p in ipairs(Players:GetPlayers()) do
            pcall(function() TagDB:applyTo(p) end)
            if tagBills[p] then
                pcall(NameHider.restore, p); pcall(function() tagBills[p].gui:Destroy() end)
                tagBills[p] = nil
            end
            pcall(buildBill, p)
        end
        rebuildList()
        if not silent then notify(("Pulled %d tag entries from pastebin"):format(count), "good") end
        return true, "ok"
    end

    toggle(pgTags, "Auto-pull pastebin changes into editor", pbCfg.autoPull, function(v)
        pbCfg.autoPull = v; savePbCfg()
    end)

    button(pgTags, "Pull from pastebin now", function()
        task.spawn(function() pullFromPastebin(false) end)
    end)

    -- Background poller: every pullInterval seconds, re-fetch the paste and,
    -- if its contents changed, update TagDB + rebuild the editor list.
    bind(task.spawn(function()
        -- seed hash with current paste so the first tick after toggle-on
        -- doesn't spuriously "detect a change" on initial load
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
                pcall(pullFromPastebin, true)
            end
        end
    end))

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
    _openPanel = function(key, title, height, builder)
        if active[key] then pcall(function() active[key]:Destroy() end); active[key] = nil; return end
        local gui = inst("ScreenGui", nil, {
            Name = "SeigePanelPopup_" .. tostring(key),
            IgnoreGuiInset = true, ResetOnSpawn = false,
            DisplayOrder = 220, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        })
        safeParent(gui)
        active[key] = gui
        local win = inst("Frame", gui, {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0, 300, 0, height or 200),
            BackgroundColor3 = T.bg, BorderSizePixel = 0,
        })
        corner(win, 10); stroke(win, T.line, 1, 0.3)
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
        closeBtn.MouseButton1Click:Connect(function() gui:Destroy(); active[key] = nil end)
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
            BackgroundTransparency = 1,
        })
        inst("UIListLayout", body, { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder })
        pcall(builder, body)
    end
end

-- ===== Help panel: full command reference =====
(function()
local HELP_CMDS = {
    { "Rejoin & teleport", {
        { "!rj", "Rejoin the same place (new server)" },
        { "!tprj", "Rejoin THIS server and restore your position via queue_on_teleport" },
        
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
        { "!head <player>", "Sit on a player's head and lock there until !head or !unhead" },
        { "!fling <player>", "Fling a player" },
    }},
    { "Animations", {
        { "!reanim", "Free the humanoid for custom animations" },
        { "!unreanim", "Stop reanim" },
        { "!reanim <id> [speed]", "Play an animation asset id" },
        { "!reanimurl <url> [speed]", "Fetch + play .txt/.json keyframe data" },
        { "!reanimdata <raw>", "Play pasted JSON/Lua keyframe data" },
        { "!stopanim", "Stop all reanim tracks" },
        { "!bang <player>", "Roblox classic" },
        { "!unbang", "Stop" },
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

-- ===== Performance: FPS booster + Ping booster (in one popout) =====
do
    -- Save originals once so toggling off restores them
    local saved
    local function snapshot()
        if saved then return end
        saved = {
            qLevel = pcall(function() return settings().Rendering.QualityLevel end) and settings().Rendering.QualityLevel,
            lagSim = pcall(function() return settings().Network.IncomingReplicationLag end) and settings().Network.IncomingReplicationLag,
            shadows = Lighting.GlobalShadows,
            fogEnd = Lighting.FogEnd,
            fogStart = Lighting.FogStart,
            brightness = Lighting.Brightness,
            envDif = Lighting.EnvironmentDiffuseScale,
            envSpc = Lighting.EnvironmentSpecularScale,
            streamPause = pcall(function() return workspace.StreamingPauseMode end) and workspace.StreamingPauseMode,
        }
    end

    local fpsOn, pingOn = false, false
    local fpsToken = 0

    local function setFpsCap(v)
        local s = rawget(getfenv(), "setfpscap")
            or (rawget(getfenv(), "syn") and syn and syn.set_fps_cap)
        if type(s) == "function" then pcall(s, v); return true end
        return false
    end

    local function applyFps(on)
        snapshot()
        if on then
            -- Uncap fps via executor
            setFpsCap(0)  -- 0 = unlimited on most executors
            -- Drop graphics quality to bare minimum
            pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
            pcall(function() Lighting.GlobalShadows = false end)
            pcall(function() Lighting.FogEnd = 1e6 end)
            pcall(function() Lighting.FogStart = 1e6 end)
            pcall(function() Lighting.EnvironmentDiffuseScale = 0 end)
            pcall(function() Lighting.EnvironmentSpecularScale = 0 end)
            -- Kill expensive effects
            for _, v in ipairs(Lighting:GetDescendants()) do
                if v:IsA("PostEffect") or v:IsA("BlurEffect") or v:IsA("BloomEffect")
                   or v:IsA("SunRaysEffect") or v:IsA("DepthOfFieldEffect")
                   or v:IsA("ColorCorrectionEffect") then
                    pcall(function() v.Enabled = false end)
                end
            end
            -- Strip heavy workspace effects (particles, smoke, fire, trails, meshes' textures)
            task.spawn(function()
                local tok = fpsToken + 1; fpsToken = tok
                for _, v in ipairs(workspace:GetDescendants()) do
                    if tok ~= fpsToken then return end
                    if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke")
                       or v:IsA("Fire") or v:IsA("Sparkles") then
                        pcall(function() v.Enabled = false end)
                    elseif v:IsA("Explosion") then
                        pcall(function() v.BlastPressure = 0; v.BlastRadius = 0 end)
                    elseif v:IsA("MeshPart") then
                        pcall(function() v.RenderFidelity = Enum.RenderFidelity.Performance end)
                    end
                end
            end)
            -- Periodically re-apply (some games reset settings)
            task.spawn(function()
                local tok = fpsToken
                while fpsOn and tok == fpsToken do
                    setFpsCap(0)
                    pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
                    task.wait(5)
                end
            end)
        else
            fpsToken = fpsToken + 1
            -- Restore
            setFpsCap(240)
            if saved then
                pcall(function() if saved.qLevel then settings().Rendering.QualityLevel = saved.qLevel end end)
                pcall(function() Lighting.GlobalShadows = saved.shadows end)
                pcall(function() Lighting.FogEnd = saved.fogEnd end)
                pcall(function() Lighting.FogStart = saved.fogStart end)
                pcall(function() Lighting.EnvironmentDiffuseScale = saved.envDif end)
                pcall(function() Lighting.EnvironmentSpecularScale = saved.envSpc end)
            end
        end
    end

    local function applyPing(on)
        snapshot()
        if on then
            -- Push network as hard as the client allows
            pcall(function() settings().Network.IncomingReplicationLag = 0 end)
            -- Reduce streaming pauses (heavy lag-spike trigger)
            pcall(function() workspace.StreamingPauseMode = Enum.StreamingPauseMode.Disabled end)
            -- Bump task scheduler priority where exposed
            pcall(function()
                local sched = settings():GetService("TaskScheduler")
                if sched then
                    sched.PriorityMethod = Enum.PriorityMethod.AccumulatedYieldTime
                    sched.SchedulerDutyCycle = 1
                end
            end)
        else
            if saved then
                pcall(function() settings().Network.IncomingReplicationLag = saved.lagSim or 0 end)
                pcall(function() workspace.StreamingPauseMode = saved.streamPause end)
            end
        end
    end

    button(pgCmds, "Performance  —  FPS & Ping booster", function()
        _openPanel("perfboost", "Performance  ·  FPS & Ping booster", 220, function(body)
            -- live pings/fps readout
            local stats = game:GetService("Stats")
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
                        ping = math.floor(stats.Network.ServerStatsItem["Data Ping"]:GetValue() + 0.5)
                    end)
                    readout.Text = ("FPS: %d   Ping: %d ms"):format(fps, ping)
                    task.wait(0.1)
                end
            end)
            toggle(body, "FPS booster (uncap + strip effects)", fpsOn, function(v)
                fpsOn = v; applyFps(v)
                notify("FPS booster " .. (v and "ON" or "OFF"), v and "good" or "dim")
            end)
            toggle(body, "Ping booster (push network priority)", pingOn, function(v)
                pingOn = v; applyPing(v)
                notify("Ping booster " .. (v and "ON" or "OFF"), v and "good" or "dim")
            end)
            button(body, "Boost BOTH (max performance)", function()
                fpsOn = true; pingOn = true
                applyFps(true); applyPing(true)
                notify("Max performance mode ON", "good")
            end)
            button(body, "Restore defaults", function()
                fpsOn = false; pingOn = false
                applyFps(false); applyPing(false)
                notify("Performance restored", "warn")
            end)
        end)
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

-- ===== OPTIMIZE  ·  one-click game speed-up =====================
do
_G.__SeigeOptimize = _G.__SeigeOptimize or { on = false, saved = nil }

local function _seigeOptimizeApply(on)
    local Lighting   = game:GetService("Lighting")
    local Players    = game:GetService("Players")
    local Terrain    = workspace:FindFirstChildOfClass("Terrain")
    local UserSet    = (function() local ok,s = pcall(function() return settings():GetService("UserGameSettings") end); return ok and s or nil end)()

    local O = _G.__SeigeOptimize
    if on then
        if not O.saved then
            O.saved = {
                qualityLevel        = (UserSet and UserSet.SavedQualityLevel) or nil,
                globalShadows       = Lighting.GlobalShadows,
                fogEnd              = Lighting.FogEnd,
                fogStart            = Lighting.FogStart,
                brightness          = Lighting.Brightness,
                envSpec             = Lighting.EnvironmentSpecularScale,
                envDif              = Lighting.EnvironmentDiffuseScale,
                technology          = Lighting.Technology,
                waterWaveSize       = Terrain and Terrain.WaterWaveSize,
                waterReflectance    = Terrain and Terrain.WaterReflectance,
                waterTransparency   = Terrain and Terrain.WaterTransparency,
                waterWaveSpeed      = Terrain and Terrain.WaterWaveSpeed,
                decoration          = Terrain and Terrain.Decoration,
            }
        end
        pcall(function()
            if UserSet then
                UserSet.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
            end
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        end)
        pcall(function() Lighting.GlobalShadows = false end)
        pcall(function() Lighting.FogEnd = 1e9 end)
        pcall(function() Lighting.Brightness = math.max(1, Lighting.Brightness) end)
        pcall(function() Lighting.EnvironmentSpecularScale = 0 end)
        pcall(function() Lighting.EnvironmentDiffuseScale = 0 end)
        if Terrain then
            pcall(function() Terrain.WaterWaveSize = 0 end)
            pcall(function() Terrain.WaterReflectance = 0 end)
            pcall(function() Terrain.WaterTransparency = 1 end)
            pcall(function() Terrain.WaterWaveSpeed = 0 end)
            pcall(function() Terrain.Decoration = false end)
        end
        -- strip cosmetic effects from existing parts
        for _, d in ipairs(workspace:GetDescendants()) do
            if d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Smoke")
               or d:IsA("Fire") or d:IsA("Sparkles") or d:IsA("Explosion") then
                pcall(function() d.Enabled = false end)
            elseif d:IsA("PostEffect") then
                pcall(function() d.Enabled = false end)
            end
        end
        for _, pp in ipairs(Lighting:GetChildren()) do
            if pp:IsA("PostEffect") then pcall(function() pp.Enabled = false end) end
        end
        -- block future particles/post-effects
        if not O.conn then
            O.conn = workspace.DescendantAdded:Connect(function(d)
                if not _G.__SeigeOptimize.on then return end
                if d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Smoke")
                   or d:IsA("Fire") or d:IsA("Sparkles") then
                    pcall(function() d.Enabled = false end)
                end
            end)
        end
        O.on = true
    else
        O.on = false
        if O.conn then pcall(function() O.conn:Disconnect() end); O.conn = nil end
        if O.saved then
            local s = O.saved
            pcall(function() if UserSet and s.qualityLevel then UserSet.SavedQualityLevel = s.qualityLevel end end)
            pcall(function() Lighting.GlobalShadows = s.globalShadows end)
            pcall(function() Lighting.FogEnd = s.fogEnd end)
            pcall(function() Lighting.FogStart = s.fogStart end)
            pcall(function() Lighting.Brightness = s.brightness end)
            pcall(function() Lighting.EnvironmentSpecularScale = s.envSpec end)
            pcall(function() Lighting.EnvironmentDiffuseScale = s.envDif end)
            if Terrain then
                pcall(function() Terrain.WaterWaveSize = s.waterWaveSize end)
                pcall(function() Terrain.WaterReflectance = s.waterReflectance end)
                pcall(function() Terrain.WaterTransparency = s.waterTransparency end)
                pcall(function() Terrain.WaterWaveSpeed = s.waterWaveSpeed end)
                pcall(function() Terrain.Decoration = s.decoration end)
            end
            O.saved = nil
        end
    end
end

local function _seigeOpenOptimize()
    _openPanel("optimize", "Optimize  ·  game speed boost", 200, function(body)
        inst("TextLabel", body, {
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = T.sub,
            TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
            Text = "Strips shadows, fog, water FX, particles & post-effects. Drops quality to Level 1. Toggle off to restore.",
        })
        toggle(body, "Optimize active", _G.__SeigeOptimize.on, function(v)
            _seigeOptimizeApply(v)
            notify("Optimize " .. (v and "ON — game sped up" or "OFF — restored"), v and "good" or "warn")
        end)
        button(body, "Apply now (re-run)", function()
            _seigeOptimizeApply(true)
            notify("Optimization re-applied", "good")
        end)
        button(body, "Restore defaults", function()
            _seigeOptimizeApply(false)
            notify("Restored", "warn")
        end)
    end)
end

button(pgCmds, "Optimize  —  speed up the game", _seigeOpenOptimize)
-- cmdHandlers is created later in the file; register via deferred hook
task.defer(function()
    if _G.__SeigeCmds then
        _G.__SeigeCmds["optimize"] = _seigeOpenOptimize
        _G.__SeigeCmds["unoptimize"] = function()
            _seigeOptimizeApply(false); notify("Optimize OFF", "warn")
        end
    end
end)
end -- end OPTIMIZE do-block





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
        toggle(body, "Click teleport (Ctrl + click)", clickTp, function(s) clickTp = s end)
    end)
end)

button(pgCmds, "Reanim  —  animations + keyframe data", function()
    _openPanel("reanim", "Reanim  ·  asset id / url / pasted keyframes", 410, function(body)
        button(body, "Start reanim (free humanoid)", function() _runCmd("!reanim") end)
        button(body, "Stop reanim", function() _runCmd("!unreanim") end)
        textbox(body, "Animation/KFS asset id  (id [speed])", function(v) _runCmd("!reanim " .. v) end)
        textbox(body, "Load keyframe txt/json from URL (url [speed])", function(v) _runCmd("!reanimurl " .. v) end)

        -- Paste box for raw JSON or Lua-table keyframe data
        local pasteFrame = inst("Frame", body, {
            Size = UDim2.new(1, -8, 0, 150),
            BackgroundColor3 = T.bg2, BackgroundTransparency = 0.3, BorderSizePixel = 0,
        })
        corner(pasteFrame, 8); stroke(pasteFrame, T.line, 1, 0.5)
        local pasteBox = inst("TextBox", pasteFrame, {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 8, 0, 6),
            Size = UDim2.new(1, -16, 1, -12),
            PlaceholderText = "Paste keyframe data here (JSON or Lua table)…",
            PlaceholderColor3 = T.dim,
            Font = Enum.Font.Code, TextSize = 11, TextColor3 = T.text,
            TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true, MultiLine = true, ClearTextOnFocus = false, Text = "",
        })
        button(body, "Play pasted keyframes", function()
            local txt = pasteBox.Text or ""
            if txt:gsub("%s","") == "" then notify("Paste some data first", "warn"); return end
            if _G.__PlayReanimText then _G.__PlayReanimText(txt, 1) end
        end)
        button(body, "Stop all playing tracks", function() _runCmd("!stopanim") end)
    end)
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
button(pgCmds, "!face <player>",        function() _openCmd("!face ") end)
button(pgCmds, "!head <player>",        function() _openCmd("!head ") end)
button(pgCmds, "!bang <player>",        function() _openCmd("!bang ") end)

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

    -- ===== Tag-specific font (3 dafont-style options) =====
    -- Picked from dafont.com lookalikes shipped with Roblox:
    --   • PermanentMarker  — handwritten marker (dafont: "Permanent Marker")
    --   • LuckiestGuy      — chunky comic caps   (dafont: "Luckiest Guy")
    --   • Creepster        — horror display      (dafont: "Creepster")
    local TAG_FONTS = { "Default", "PermanentMarker", "LuckiestGuy", "Creepster" }
    _G.__SeigeTagFont = _G.__SeigeTagFont or "Default"
    local function applyTagFont()
        local choice = _G.__SeigeTagFont
        local font = (choice ~= "Default") and Enum.Font[choice] or nil
        local bills = _G.__SeigeTagBills or {}
        for _, e in pairs(bills) do
            if e and e.name and e.handle then
                pcall(function()
                    e.name.Font   = font or Enum.Font.GothamBold
                    e.handle.Font = font or Enum.Font.Gotham
                    if e.stat then e.stat.Font = font or Enum.Font.GothamBold end
                end)
            end
        end
    end
    _G.__SeigeApplyTagFont = applyTagFont
    dropdown(pgThemes, "Tag font (dafont styles)", TAG_FONTS, function(v)
        _G.__SeigeTagFont = v; applyTagFont(); saveCfg()
    end)

    section(pgThemes, "Bubble animations  (player tags)")

    local BUBBLE = { "None", "Bounce", "Pulse", "Float", "Wobble", "Shake", "Heartbeat" }
    _G.__SeigeBubbleAnim = _G.__SeigeBubbleAnim or "None"
    dropdown(pgThemes, "Tag bubble animation", BUBBLE, function(v)
        _G.__SeigeBubbleAnim = v; saveCfg()
    end)
    slider(pgThemes, "Bubble anim intensity", 0, 100, 50, function(v)
        _G.__SeigeBubbleAmt = v / 100
    end)

    section(pgThemes, "Page / panel animations")
    local PAGE = { "None", "Fade", "Scale", "Slide-down", "Slide-up", "Slide-right", "Flip", "Bounce" }
    _G.__SeigePageAnim = _G.__SeigePageAnim or "Fade"
    dropdown(pgThemes, "Panel open animation", PAGE, function(v)
        _G.__SeigePageAnim = v; saveCfg()
    end)
    slider(pgThemes, "Animation speed (ms)", 80, 700, 240, function(v)
        _G.__SeigePageAnimSpeed = v / 1000
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
    end
end
for _, name in ipairs({"Off","Cinematic","Dreamy","Noir","Vibrant","4K Ultra"}) do
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

-- Invis toggle keybind (default F7)
bind(UIS.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.UserInputType == Enum.UserInputType.Keyboard and i.KeyCode == (_G.__InvisKey or Enum.KeyCode.F7) then
        cmdHandlers["invis"]()
    end
end))

------------------------------------------------------- PROFILE TAB (redesigned)
do
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
    task.spawn(function()
        while hero and hero.Parent do
            if math.random() < 0.55 then heroSparkle() end
            if math.random() < 0.10 then heroNebula() end
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
    BackgroundTransparency = 0.02,
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
local brandBlock = inst("Frame", Pill, {
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
local fpsBox = statPill(3, T.good)
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

local pingBox = statPill(4, T.warn)
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
local iconsRow = inst("Frame", Pill, {
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
local pillToggle = inst("TextButton", Pill, {
    Size = UDim2.new(0, 32, 0, 32), BackgroundColor3 = T.text,
    BackgroundTransparency = 0.88, BorderSizePixel = 0, AutoButtonColor = false,
    Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = T.text,
    Text = "", LayoutOrder = 96, ZIndex = 102,
})
corner(pillToggle, 8); stroke(pillToggle, T.text, 1, 0.65)
local pillToggleImg = inst("ImageLabel", pillToggle, {
    BackgroundTransparency = 1,
    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = UDim2.new(0, 18, 0, 18),
    Image = "rbxassetid://106620609396373",
    ImageColor3 = T.text, ZIndex = 103,
})

-- Clock pill at far right (time + date)
local clockBox = inst("Frame", Pill, {
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

-- ============= FLOATING PANELS ====================================
-- Move the tooltip out of the hidden Win and into Root for the new pill.
pcall(function() Tip.Parent = Root; Tip.ZIndex = 220 end)

local panels = {}
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
            tweenInto({ BackgroundTransparency = 0.04 })
        elseif style == "Scale" then
            scaleObj.Scale = 0.85
            tweenInto({ BackgroundTransparency = 0.04 })
            TweenService:Create(scaleObj, TweenInfo.new(dur, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
        elseif style == "Slide-down" then
            frame.Position = UDim2.new(pxs, px, pys, py - 40)
            tweenInto({ Position = restPos, BackgroundTransparency = 0.04 })
        elseif style == "Slide-up" then
            frame.Position = UDim2.new(pxs, px, pys, py + 40)
            tweenInto({ Position = restPos, BackgroundTransparency = 0.04 })
        elseif style == "Slide-right" then
            frame.Position = UDim2.new(pxs, px - 60, pys, py)
            tweenInto({ Position = restPos, BackgroundTransparency = 0.04 })
        elseif style == "Flip" then
            scaleObj.Scale = 0.01
            tweenInto({ BackgroundTransparency = 0.04 })
            TweenService:Create(scaleObj, TweenInfo.new(dur, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Scale = 1 }):Play()
        elseif style == "Bounce" then
            scaleObj.Scale = 0.6
            tweenInto({ BackgroundTransparency = 0.04 })
            TweenService:Create(scaleObj, TweenInfo.new(dur * 1.3, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), { Scale = 1 }):Play()
        else
            frame.BackgroundTransparency = 0.04
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
                frame.BackgroundTransparency = 0.04
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
local tabOrder = {
    "Profile", "Players", "Cmds", "Shaders", "Spotify", "Config", "Skybox", "Misc",
}
-- Per-tab image icons (rbxassetid). Images should be white on transparent bg.
local tabImages = {
    Profile = "rbxassetid://72672681350713",   -- player
    Players = "rbxassetid://133507370080897",  -- users
    Cmds    = "rbxassetid://79760780173556",   -- command
    Shaders = "rbxassetid://89184279571938",   -- shaders
    Spotify = "rbxassetid://103992944497423",  -- music
    Config  = "rbxassetid://125262243617493",  -- settings
    Skybox  = "rbxassetid://115487520048176",  -- skybox
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
        local imgId = tabImages[name]
        local WHITE = Color3.fromRGB(255,255,255)
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

        local function setHover(on)
            local p = panels[name]
            local active = p and p.frame.Visible
            if active then
                tween(ib, 0.12, { BackgroundColor3 = WHITE, BackgroundTransparency = 0 })
                ib.TextColor3 = Color3.fromRGB(10,10,12)
                if ibImg then ibImg.ImageColor3 = Color3.fromRGB(10,10,12) end
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

-- Pill compact toggle (hides stats/icons/clock, leaves a hamburger)
do
    local collapsed = false
    local hidden = { brandBlock, fpsBox, pingBox, iconsRow, clockBox }
    -- also hide every divider frame in the pill except the toggle itself
    local dividers = {}
    for _, ch in ipairs(Pill:GetChildren()) do
        if ch:IsA("Frame") and ch.Size.X.Offset == 1 then dividers[#dividers+1] = ch end
    end
    pillToggle.MouseEnter:Connect(function()
        tween(pillToggle, 0.12, { BackgroundTransparency = 0.78 })
    end)
    pillToggle.MouseLeave:Connect(function()
        tween(pillToggle, 0.12, { BackgroundTransparency = 0.88 })
    end)
    pillToggle.MouseButton1Click:Connect(function()
        collapsed = not collapsed
        for _, f in ipairs(hidden) do f.Visible = not collapsed end
        for _, d in ipairs(dividers) do d.Visible = not collapsed end
        if collapsed then
            pillToggleImg.Visible = false
            pillToggle.Text = "≡"
            for _, p in pairs(panels) do
                if _G.__SeigeAnimPanel then _G.__SeigeAnimPanel(p.frame, false) else p.frame.Visible = false end
            end
        else
            pillToggle.Text = ""
            pillToggleImg.Visible = true
        end
    end)
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
            for _, p in pairs(panels) do
                if _G.__SeigeAnimPanel then _G.__SeigeAnimPanel(p.frame, false) else p.frame.Visible = false end
                if p.btn then
                    tween(p.btn, 0.12, { BackgroundColor3 = Color3.fromRGB(255,255,255), BackgroundTransparency = 1 })
                end
            end
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
local cmdBar = inst("Frame", cmdBarGui, {
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
local cmdBox = inst("TextBox", cmdBar, {
    Position = UDim2.new(0, 34, 0, 0), Size = UDim2.new(1, -44, 1, 0),
    BackgroundTransparency = 1, BorderSizePixel = 0,
    Font = Enum.Font.Code, TextSize = 14, TextColor3 = T.text, PlaceholderColor3 = T.dim,
    TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false,
    PlaceholderText = "Type a command (!rj, !tprj) and press Enter",
    Text = "", ZIndex = 201,
})

local function findPlr(q)
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

local cmdHandlers = {}
_G.__SeigeCmds = cmdHandlers
cmdHandlers["rj"] = function()
    notify("Rejoining...", "good")
    pcall(function() TeleportSrv:Teleport(game.PlaceId, LP) end)
end
cmdHandlers["tprj"] = function()
    local h = hrp()
    if h then
        local c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12 = h.CFrame:GetComponents()
        local restore = string.format(
            "task.spawn(function() local p=game:GetService('Players').LocalPlayer local cf=CFrame.new(%.4f,%.4f,%.4f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f) local function apply(c) local r=c:WaitForChild('HumanoidRootPart',10) if r then task.wait(0.4) for i=1,8 do pcall(function() r.CFrame=cf end) task.wait(0.15) end end end local c=p.Character or p.CharacterAdded:Wait() apply(c) p.CharacterAdded:Connect(apply) end)",
            c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12)
        local q = (syn and syn.queue_on_teleport)
            or rawget(getfenv(), "queue_on_teleport")
            or (fluxus and fluxus.queue_on_teleport)
            or (getgenv and getgenv().queue_on_teleport)
        if q then pcall(q, restore) else notify("Your executor lacks queue_on_teleport — position won't restore", "warn") end
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
cmdHandlers["head"] = function(arg)
    -- Toggle: !head <player> locks you sitting on their head; !head (no arg) unlocks
    if _G.__HeadLock then
        if _G.__HeadLock.conn then pcall(function() _G.__HeadLock.conn:Disconnect() end) end
        _G.__HeadLock = nil
        local h = hum(); if h then h.Sit = false end
        notify("Head-lock off", "good")
        if not arg or arg == "" then return end
    end
    if not arg or arg == "" then notify("Usage: !head <player>  (run again to unlock)", "warn"); return end
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
    notify("Sitting on " .. target.Name .. "'s head — !head again to unlock", "good")
end
cmdHandlers["unhead"] = function()
    if _G.__HeadLock then
        if _G.__HeadLock.conn then pcall(function() _G.__HeadLock.conn:Disconnect() end) end
        _G.__HeadLock = nil
        local h = hum(); if h then h.Sit = false end
        notify("Head-lock off", "good")
    end
end
cmdHandlers["bang"] = function(arg)
    local target = findPlr(arg)
    if not target then notify("Player not found", "bad"); return end
    local c = LP.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    local thrp = phrp(target)
    if not (h and thrp) then notify("Missing humanoid/target", "bad"); return end
    pcall(function()
        local anim = Instance.new("Animation")
        anim.AnimationId = "rbxassetid://5918726674"
        local track = h:LoadAnimation(anim)
        track:Play()
        track:AdjustSpeed(3)
        _G.__BangTrack = track
        _G.__BangConn = RunService.Heartbeat:Connect(function()
            local myH = hrp()
            if not myH or not phrp(target) then return end
            myH.CFrame = phrp(target).CFrame * CFrame.new(0, 0, -1.2)
        end)
    end)
    notify("Bang " .. target.Name .. " (!unbang to stop)", "good")
end
cmdHandlers["unbang"] = function()
    if _G.__BangConn then _G.__BangConn:Disconnect(); _G.__BangConn = nil end
    if _G.__BangTrack then pcall(function() _G.__BangTrack:Stop() end); _G.__BangTrack = nil end
    notify("Bang stopped", "good")
end

-- ---------- extended chat commands ----------
local function getHum()
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
    local c = target.Character; local h = c and c:FindFirstChildOfClass("Humanoid")
    if not h then notify("No target humanoid", "bad"); return end
    Workspace.CurrentCamera.CameraSubject = h
    notify("Spectating " .. target.Name, "good")
end
cmdHandlers["unspectate"] = function()
    local h = getHum(); if h then Workspace.CurrentCamera.CameraSubject = h; notify("Unspectated", "good") end
end

cmdHandlers["fling"] = function(arg)
    local target = findPlr(arg); if not target then notify("Player not found", "bad"); return end
    local thrp = phrp(target); local myH = hrp()
    if not (thrp and myH) then notify("Missing character", "bad"); return end
    pcall(function()
        local v = Instance.new("BodyVelocity")
        v.MaxForce = Vector3.new(1e9,1e9,1e9)
        v.Velocity = Vector3.new(math.random(-1,1)*1e4, 1e4, math.random(-1,1)*1e4)
        v.Parent = thrp
        task.delay(0.25, function() v:Destroy() end)
    end)
    notify("Flung " .. target.Name, "good")
end

cmdHandlers["bring"] = function(arg)
    local target = findPlr(arg); if not target then notify("Player not found", "bad"); return end
    local thrp, myH = phrp(target), hrp()
    if not (thrp and myH) then notify("Missing character", "bad"); return end
    notify("Bringing " .. target.Name .. "...", "good")
    task.spawn(function()
        for i = 1, 25 do
            if not phrp(target) or not hrp() then break end
            pcall(function() phrp(target).CFrame = hrp().CFrame + Vector3.new(0, 3, 0) end)
            task.wait(0.05)
        end
        local tool = LP.Backpack:FindFirstChildOfClass("Tool")
            or (LP.Character and LP.Character:FindFirstChildOfClass("Tool"))
        if tool and tool:FindFirstChild("Handle") and typeof(firetouchinterest) == "function" then
            pcall(function()
                tool.Parent = LP.Character
                local saved = myH.CFrame
                for i = 1, 20 do
                    local t = phrp(target); if not t then break end
                    myH.CFrame = t.CFrame
                    pcall(function() firetouchinterest(tool.Handle, t, 0) end); task.wait()
                    pcall(function() firetouchinterest(tool.Handle, t, 1) end); task.wait(0.05)
                end
                myH.CFrame = saved
            end)
        end
    end)
end

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

-- 9) Server hop — teleport to a random public server
cmdHandlers["hop"] = function()
    notify("Searching server...", "good")
    task.spawn(function()
        local ok, list = pcall(function()
            local raw = game:HttpGet(string.format(
                "https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", game.PlaceId))
            return game:GetService("HttpService"):JSONDecode(raw)
        end)
        if ok and list and list.data then
            for _, s in ipairs(list.data) do
                if s.id ~= game.JobId and s.playing < s.maxPlayers then
                    pcall(function() TeleportSrv:TeleportToPlaceInstance(game.PlaceId, s.id, LP) end)
                    return
                end
            end
        end
        pcall(function() TeleportSrv:Teleport(game.PlaceId, LP) end)
    end)
end
cmdHandlers["serverhop"] = cmdHandlers["hop"]

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
    local V = {}
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
        _G.__SeigeAntiVC = _G.__SeigeAntiVC or { on = false, interval = 25 }
        if _G.__SeigeAntiVC.on then
            _G.__SeigeAntiVC.on = false
            notify("AntiVC OFF", "warn"); return
        end
        local ok, why = V.gateCheck("antivc")
        if not ok then notify(why, "bad"); return end
        _G.__SeigeAntiVC.on = true
        notify("AntiVC ON — recycling voice (undetected)", "good")
        task.spawn(function()
            while _G.__SeigeAntiVC and _G.__SeigeAntiVC.on do
                local base = tonumber(_G.__SeigeAntiVC.interval) or 25
                task.wait(math.max(4, base) + math.random() * 4)
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


local function runBarCmd(raw)
    if not raw or raw == "" then return end
    local s = raw:gsub("^%s+", ""):gsub("%s+$", "")
    s = s:gsub("^[!:;]+", "")
    local cmd, arg = s:match("^(%S+)%s*(.*)$")
    if not cmd then return end
    cmd = cmd:lower()
    local h = cmdHandlers[cmd]
    if h then h(arg) else notify("Unknown command: " .. cmd, "bad") end
end

cmdBox.PlaceholderText = "!rj !tprj !fly !noclip !ws !jp !god !goto !to !spectate !fling !heal !save !load !help"

-- Roblox chat command bridge: any message starting with ! (e.g. !rj, !tprj) runs the command
pcall(function()
    LP.Chatted:Connect(function(msg)
        if type(msg) ~= "string" then return end
        if msg:sub(1, 1) ~= "!" then return end
        runBarCmd(msg)
    end)
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

    local recent = {}
    local function pingFromUser(plr)
        if not plr then return end
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

    -- True if the message is just an ellipsis (our exec marker).
    -- Strip whitespace so "  …  " still matches.
    local function isExecMark(text)
        if type(text) ~= "string" then return false end
        local t = text:gsub("^%s+", ""):gsub("%s+$", "")
        return t == PUBLIC_MARK or t == PUBLIC_ALT
    end

    local function handleText(text, srcPlayer)
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
    task.spawn(function()
        while _G.__AdminLoaded do
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
    pcall(function() Lighting.Brightness = 1; Lighting.GlobalShadows = true; Lighting.Ambient = Color3.fromRGB(70,70,70) end)
    if _G.__SeigePresenceCleanup then pcall(_G.__SeigePresenceCleanup) end
    _G.__AdminLoaded = nil
    _G.__AdminUI = nil
end

------------------------------------------------------- READY
notify("seige.lol loaded · " .. ADMIN_BUILD, "good")
notify("Press F2 to toggle UI · F6 for command bar", "good")
print("[seige.lol] Ready")

