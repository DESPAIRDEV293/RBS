if not game:IsLoaded() then game.Loaded:Wait() end

-- ============================================================================
-- ROT / Reanim performance boost: uncap FPS and lower network throttle BEFORE
-- the rig spawns so the heaviest frames (rig build + initial replication) run
-- at full speed. Saves the user's previous values so we can restore on unload.
-- ============================================================================
_G.__RotPerfBoost = _G.__RotPerfBoost or {}
do
    local P = _G.__RotPerfBoost
    if not P.applied then
        P.applied = true
        -- 1) Uncap FPS — try every executor flavor of the call
        pcall(function()
            if setfpscap then P.prevFps = 60; setfpscap(0) end
        end)
        pcall(function()
            if not P.prevFps and (syn and syn.set_fps_cap) then P.prevFps = 60; syn.set_fps_cap(0) end
        end)
        -- 2) Lower send/receive throttle so replication keeps up at high FPS
        pcall(function()
            local NS = game:GetService("NetworkSettings")
            P.prevSend = NS.IncomingReplicationLag
            NS.IncomingReplicationLag = 0
        end)
        pcall(function()
            settings():GetService("NetworkSettings").PhysicsSendRate = 30
        end)
        -- 3) Defer heavy renderer features for one frame while we load
        pcall(function()
            local L = game:GetService("Lighting")
            P.prevGQ = L.GlobalShadows
            L.GlobalShadows = false
        end)
        task.delay(6, function()
            pcall(function()
                local L = game:GetService("Lighting")
                if P.prevGQ ~= nil then L.GlobalShadows = P.prevGQ end
            end)
        end)
    end
end



local LPH_NO_VIRTUALIZE = LPH_NO_VIRTUALIZE or function(f) return f end
local LPH_JIT           = LPH_JIT           or function(f) return f end

local _safeLoadstring
do
	local _cf  = rawget((getgenv and getgenv()) or _G, "clonefunction")
	local _raw = (_cf and _cf(loadstring or load)) or loadstring or load
	_safeLoadstring = _raw
end

local tweenService     = game:GetService("TweenService")
local players          = game:GetService("Players")
local runService       = game:GetService("RunService")
local userInputService = game:GetService("UserInputService")
local lp               = players.LocalPlayer
local gui              = lp:WaitForChild("PlayerGui")
local mouse            = lp:GetMouse()

local C = {
	PANEL  = Color3.fromRGB(10,   6,  20),
	STROKE = Color3.fromRGB(90,  55, 140),
	ACCENT = Color3.fromRGB(165,  75, 255),
	TEXT   = Color3.fromRGB(238, 228, 255),
	DIM    = Color3.fromRGB(115,  95, 150),
	ACTION = Color3.fromRGB(140,  55, 230),
	DANGER = Color3.fromRGB(195,  55, 210),
	BG     = Color3.fromRGB(7,    3,  15),
	CARD   = Color3.fromRGB(20,  12,  38),
	DIV    = Color3.fromRGB(55,  33,  82),
	SUB    = Color3.fromRGB(178, 158, 215),
	GLOW   = Color3.fromRGB(165,  75, 255),
}

local font = Enum.Font.GothamSemibold

local function tween(obj, info, goals)
	if obj then tweenService:Create(obj, info, goals):Play() end
end

local sfx = { hover = function() end, notify = function() end }

local sg = Instance.new("ScreenGui")
sg.Name           = "ROT_UI"
sg.ResetOnSpawn   = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.IgnoreGuiInset = true
sg.DisplayOrder   = 50
sg.Parent         = (gethui and gethui()) or gui

local screen = sg

local NotifyContainer = Instance.new("Frame", sg)
NotifyContainer.Name                   = "NotifyContainer"
NotifyContainer.Size                   = UDim2.new(0, 280, 1, 0)
NotifyContainer.AnchorPoint            = Vector2.new(1, 0)
NotifyContainer.Position               = UDim2.new(1, -12, 0, 12)
NotifyContainer.BackgroundTransparency = 1
NotifyContainer.BorderSizePixel        = 0
NotifyContainer.ZIndex                 = 200
local _notifLayout = Instance.new("UIListLayout", NotifyContainer)
_notifLayout.SortOrder         = Enum.SortOrder.LayoutOrder
_notifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
_notifLayout.Padding           = UDim.new(0, 6)

local notifEnabled = true

local notify = function(title, text, duration)
	if not notifEnabled then return end
	duration = duration or 5
	task.spawn(function()
		local frame = Instance.new("Frame", NotifyContainer)
		frame.Size                   = UDim2.new(1, 0, 0, 52)
		frame.BackgroundColor3       = C.CARD
		frame.BackgroundTransparency = 1
		frame.BorderSizePixel        = 0
		frame.ZIndex                 = 200
		Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
		local stroke = Instance.new("UIStroke", frame)
		stroke.Color = C.DIV ; stroke.Thickness = 1 ; stroke.Transparency = 0

		local tLbl = Instance.new("TextLabel", frame)
		tLbl.Size = UDim2.new(1, -16, 0, 18) ; tLbl.Position = UDim2.new(0, 10, 0, 8)
		tLbl.BackgroundTransparency = 1
		tLbl.Text = title or "" ; tLbl.Font = Enum.Font.GothamBold ; tLbl.TextSize = 13
		tLbl.TextColor3 = C.ACCENT ; tLbl.TextXAlignment = Enum.TextXAlignment.Left ; tLbl.ZIndex = 201

		local bLbl = Instance.new("TextLabel", frame)
		bLbl.Size = UDim2.new(1, -16, 0, 16) ; bLbl.Position = UDim2.new(0, 10, 0, 28)
		bLbl.BackgroundTransparency = 1
		bLbl.Text = text or "" ; bLbl.Font = Enum.Font.GothamSemibold ; bLbl.TextSize = 11
		bLbl.TextColor3 = C.SUB ; bLbl.TextXAlignment = Enum.TextXAlignment.Left ; bLbl.ZIndex = 201

		tween(frame,  TweenInfo.new(0.2), {BackgroundTransparency = 0})
		tween(stroke, TweenInfo.new(0.2), {Transparency = 0.5})
		task.wait(duration)
		tween(frame,  TweenInfo.new(0.3), {BackgroundTransparency = 1})
		tween(stroke, TweenInfo.new(0.3), {Transparency = 1})
		task.wait(0.35)
		frame:Destroy()
	end)
end

_G._floatingPanelScales = _G._floatingPanelScales or {}
_G._currentScale        = _G._currentScale or 1
_G._getScale            = function() return _G._currentScale end

local _fixedPanels = {}

local function _updateScale()
	local cam = workspace.CurrentCamera
	local vp  = cam and cam.ViewportSize or Vector2.new(1280, 720)
	local s   = math.clamp(math.min(vp.X / 1280, vp.Y / 720), 0.40, 1.0)
	_G._currentScale = s
	for i = 1, #_G._floatingPanelScales do
		_G._floatingPanelScales[i].Scale = s
	end
end
_updateScale()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(_updateScale)

local sliderRegistry = {}

local function makeSlider(parent, yOffset, label, color, default, min, max, onChange, skipTheme)
	local initPct = math.clamp((default - min) / (max - min), 0, 1)
	local card = Instance.new("Frame", parent)
	card.BackgroundColor3       = color
	card.BackgroundTransparency = 0.82
	card.BorderSizePixel        = 0
	card.Position               = UDim2.new(0, 12, 0, yOffset)
	card.Size                   = UDim2.new(1, -24, 0, 42)
	card.ClipsDescendants       = true
	card.ZIndex                 = 12
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
	local stroke = Instance.new("UIStroke", card)
	stroke.Color = color ; stroke.Transparency = 0.7 ; stroke.Thickness = 1
	local progress = Instance.new("Frame", card)
	progress.BackgroundColor3       = color
	progress.BackgroundTransparency = 0
	progress.BorderSizePixel        = 0
	progress.Size                   = UDim2.new(initPct, 0, 1, 0)
	progress.ZIndex                 = 13
	Instance.new("UICorner", progress).CornerRadius = UDim.new(0, 8)
	local progGrad = Instance.new("UIGradient", progress)
	progGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(0.8, 0),
		NumberSequenceKeypoint.new(1, 0.3),
	})
	local thumb = Instance.new("Frame", card)
	thumb.AnchorPoint            = Vector2.new(0.5, 0.5)
	thumb.Position               = UDim2.new(initPct, 0, 0.5, 0)
	thumb.Size                   = UDim2.new(0, 4, 0, 20)
	thumb.BackgroundColor3       = Color3.new(1, 1, 1)
	thumb.BackgroundTransparency = 0
	thumb.BorderSizePixel        = 0
	thumb.ZIndex                 = 16
	Instance.new("UICorner", thumb).CornerRadius = UDim.new(1, 0)
	local info = Instance.new("TextLabel", card)
	info.BackgroundTransparency = 1
	info.Position    = UDim2.new(0, 14, 0, 0)
	info.Size        = UDim2.new(1, -14, 1, 0)
	info.Font        = Enum.Font.GothamSemibold ; info.TextSize = 12
	info.TextXAlignment = Enum.TextXAlignment.Left
	info.TextColor3  = Color3.fromRGB(255, 255, 255)
	info.TextTransparency = 0.15
	info.Text        = tostring(default) .. "  " .. label
	info.ZIndex      = 15
	local interact = Instance.new("TextButton", card)
	interact.Text = "" ; interact.AutoButtonColor = false
	interact.BackgroundTransparency = 1
	interact.Size = UDim2.new(1, 0, 1, 0) ; interact.ZIndex = 16
	local active  = false
	local padding = {0, 0}
	local function updateSlider()
		local posX  = math.clamp(mouse.X, padding[1], padding[2])
		local rel   = (posX - padding[1]) / (padding[2] - padding[1])
		local value = math.round(min + rel * (max - min))
		local pct   = (value - min) / (max - min)
		tween(progress, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {Size = UDim2.new(pct, 0, 1, 0)})
		tween(thumb,    TweenInfo.new(0.4, Enum.EasingStyle.Quint), {Position = UDim2.new(pct, 0, 0.5, 0)})
		info.Text = tostring(value) .. "  " .. label
		onChange(value)
	end
	interact.MouseEnter:Connect(function()
		if active then return end
		tween(card,  TweenInfo.new(0.25, Enum.EasingStyle.Quint), {BackgroundTransparency = 0.74})
		tween(thumb, TweenInfo.new(0.20, Enum.EasingStyle.Quint), {BackgroundTransparency = 0.1, Size = UDim2.new(0, 4, 0, 24)})
	end)
	interact.MouseLeave:Connect(function()
		if active then return end
		tween(card,  TweenInfo.new(0.30, Enum.EasingStyle.Quint), {BackgroundTransparency = 0.82})
		tween(thumb, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {BackgroundTransparency = 0.3, Size = UDim2.new(0, 4, 0, 20)})
	end)
	interact.MouseButton1Down:Connect(function()
		padding = {interact.AbsolutePosition.X, interact.AbsolutePosition.X + interact.AbsoluteSize.X}
		active  = true ; updateSlider()
		tween(card,  TweenInfo.new(0.15, Enum.EasingStyle.Quint), {BackgroundTransparency = 0.65})
		tween(thumb, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {BackgroundTransparency = 0, Size = UDim2.new(0, 5, 0, 28)})
	end)
	mouse.Move:Connect(function() if active then updateSlider() end end)
	userInputService.InputEnded:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
		and input.UserInputType ~= Enum.UserInputType.Touch then return end
		if not active then return end
		active = false
		tween(card,  TweenInfo.new(0.35, Enum.EasingStyle.Quint), {BackgroundTransparency = 0.82})
		tween(thumb, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {BackgroundTransparency = 0.3, Size = UDim2.new(0, 4, 0, 20)})
	end)
	local handle = {card = card, progress = progress, stroke = stroke, defaultColor = color}
	handle.setValue = function(value)
		value = math.clamp(math.round(value), min, max)
		local pct = (value - min) / (max - min)
		tween(progress, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {Size = UDim2.new(pct, 0, 1, 0)})
		tween(thumb,    TweenInfo.new(0.4, Enum.EasingStyle.Quint), {Position = UDim2.new(pct, 0, 0.5, 0)})
		info.Text = tostring(value) .. "  " .. label
	end
	if not skipTheme then sliderRegistry[#sliderRegistry + 1] = handle end
	return handle
end

local function makeFloatingPanel(w, h, anchorX, anchorY)
	local pnl = Instance.new("Frame", screen)
	pnl.Size                   = UDim2.new(0, w, 0, h)
	pnl.AnchorPoint            = Vector2.new(anchorX, anchorY)
	pnl.Position               = UDim2.new(anchorX, 0, anchorY, 0)
	pnl.BackgroundColor3       = C.PANEL
	pnl.BackgroundTransparency = 0
	pnl.BorderSizePixel        = 0
	pnl.ZIndex                 = 150
	pnl.Active                 = true
	pnl.Visible                = false
	Instance.new("UICorner", pnl).CornerRadius = UDim.new(0, 8)
	local pStroke = Instance.new("UIStroke", pnl)
	pStroke.Color = C.STROKE ; pStroke.Thickness = 1
	pStroke.Transparency = 0.5 ; pStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	_fixedPanels[#_fixedPanels + 1] = pnl
	local pnlUIScale = Instance.new("UIScale", pnl)
	pnlUIScale.Scale = _G._getScale()
	_G._floatingPanelScales[#_G._floatingPanelScales + 1] = pnlUIScale
	return pnl
end

local function makePanelTitleBar(pnl, title, onClose)
	local bar = Instance.new("Frame", pnl)
	bar.Size = UDim2.new(1, 0, 0, 34) ; bar.BackgroundTransparency = 1
	bar.BorderSizePixel = 0 ; bar.ZIndex = 151
	local lbl = Instance.new("TextLabel", bar)
	lbl.Text = title ; lbl.Font = Enum.Font.GothamBold ; lbl.TextSize = 11
	lbl.TextColor3 = C.SUB ; lbl.Position = UDim2.new(0, 12, 0, 0)
	lbl.Size = UDim2.new(1, -40, 1, 0) ; lbl.BackgroundTransparency = 1
	lbl.TextXAlignment = Enum.TextXAlignment.Left ; lbl.ZIndex = 152
	local closeBtn = Instance.new("TextButton", bar)
	closeBtn.Text = "" ; closeBtn.Size = UDim2.new(0, 22, 0, 22)
	closeBtn.Position = UDim2.new(1, -28, 0.5, -11)
	closeBtn.BackgroundTransparency = 1 ; closeBtn.BorderSizePixel = 0
	closeBtn.ZIndex = 153 ; closeBtn.AutoButtonColor = false
	local closeIcon = Instance.new("ImageLabel", closeBtn)
	closeIcon.BackgroundTransparency = 1 ; closeIcon.Size = UDim2.new(0, 10, 0, 10)
	closeIcon.Position = UDim2.new(0.5, 0, 0.5, 0) ; closeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	closeIcon.Image = "rbxassetid://82927197777156"
	closeIcon.ImageColor3 = Color3.new(1, 1, 1) ; closeIcon.ImageTransparency = 0.45 ; closeIcon.ZIndex = 154
	closeBtn.MouseButton1Click:Connect(onClose)
	closeBtn.MouseEnter:Connect(function()
		tween(closeIcon, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {ImageTransparency = 0})
	end)
	closeBtn.MouseLeave:Connect(function()
		tween(closeIcon, TweenInfo.new(0.20, Enum.EasingStyle.Quint), {ImageTransparency = 0.45})
	end)
	return bar
end

local _cs = {}
_cs._nvDragOwner = nil

_cs.makePanelDraggable = function(pnl, bar, onMove)
	local dragging     = false
	local touchInput   = nil
	local dragStartM   = Vector2.zero
	local dragStartPos = UDim2.new()
	local function pointerPos()
		if touchInput then return Vector2.new(touchInput.Position.X, touchInput.Position.Y) end
		return userInputService:GetMouseLocation()
	end
	bar.InputBegan:Connect(function(i)
		if dragging or (_cs._nvDragOwner ~= nil and _cs._nvDragOwner ~= pnl) then return end
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			touchInput = nil ; dragStartM = userInputService:GetMouseLocation()
			dragStartPos = pnl.Position ; dragging = true ; _cs._nvDragOwner = pnl
		elseif i.UserInputType == Enum.UserInputType.Touch then
			touchInput = i ; dragStartM = Vector2.new(i.Position.X, i.Position.Y)
			dragStartPos = pnl.Position ; dragging = true ; _cs._nvDragOwner = pnl
		end
	end)
	userInputService.InputEnded:Connect(function(i)
		if i == touchInput or i.UserInputType == Enum.UserInputType.MouseButton1 then
			if dragging then
				dragging = false ; touchInput = nil
				if _cs._nvDragOwner == pnl then _cs._nvDragOwner = nil end
			end
		end
	end)
	runService.RenderStepped:Connect(LPH_NO_VIRTUALIZE(function()
		if not dragging then return end
		local d   = pointerPos() - dragStartM
		local cam = workspace.CurrentCamera
		local vp  = cam and cam.ViewportSize or Vector2.new(1280, 720)
		local ps  = pnl.AbsoluteSize
		local curPxX = dragStartPos.X.Offset + dragStartPos.X.Scale * vp.X
		local curPxY = dragStartPos.Y.Offset + dragStartPos.Y.Scale * vp.Y
		local anchorOffX = pnl.AnchorPoint.X * ps.X
		local anchorOffY = pnl.AnchorPoint.Y * ps.Y
		local newX = math.clamp(curPxX + d.X, anchorOffX, vp.X - ps.X + anchorOffX)
		local newY = math.clamp(curPxY + d.Y, anchorOffY, vp.Y - ps.Y + anchorOffY)
		local newPos = UDim2.new(0, newX, 0, newY)
		pnl.Position = newPos
		if onMove then onMove(newPos) end
	end))
end

_G._reanimAPI             = nil
_G._reanimLoaded          = false
_G._reanimPanel           = nil
_G._reanimPanelPositioned = false

local reloadCustom = function() end

;(function()
	local stalkie = {
		services = {
			players            = game:GetService("Players"),
			workspace          = game:GetService("Workspace"),
			replicated         = game:GetService("ReplicatedStorage"),
			run_service        = game:GetService("RunService"),
			user_input_service = game:GetService("UserInputService"),
			http_service       = game:GetService("HttpService"),
		},
		flags       = { reanimated = false },
		clones      = {},
		connections = { hb=nil, died=nil, real_char_child_removed=nil,
		                character_removing=nil, clone_died=nil,
		                clone_char_child_removed=nil, animation_hb=nil },
		real_chars  = {},
		callbacks   = { on_play=nil, on_stop=nil, on_deactivate=nil },
		animation   = {
			cache = {},
			state = { is_playing=false, current_url=nil, speed=1.0,
			          keyframes=nil, total_duration=0, elapsed_time=0 },
			original_motor_c0s = {},
			joints = {},
			ac_joint_map = nil,
		},
	}

	local API = {}

	local AC_HIERARCHY = {
		{ part = "LowerTorso",    parent = "HumanoidRootPart" },
		{ part = "UpperTorso",    parent = "LowerTorso"       },
		{ part = "Head",          parent = "UpperTorso"       },
		{ part = "LeftUpperArm",  parent = "UpperTorso"       },
		{ part = "LeftLowerArm",  parent = "LeftUpperArm"     },
		{ part = "LeftHand",      parent = "LeftLowerArm"     },
		{ part = "RightUpperArm", parent = "UpperTorso"       },
		{ part = "RightLowerArm", parent = "RightUpperArm"    },
		{ part = "RightHand",     parent = "RightLowerArm"    },
		{ part = "LeftUpperLeg",  parent = "LowerTorso"       },
		{ part = "LeftLowerLeg",  parent = "LeftUpperLeg"     },
		{ part = "LeftFoot",      parent = "LeftLowerLeg"     },
		{ part = "RightUpperLeg", parent = "LowerTorso"       },
		{ part = "RightLowerLeg", parent = "RightUpperLeg"    },
		{ part = "RightFoot",     parent = "RightLowerLeg"    },
	}

	local function buildACJointMap(clone)
		local map = {}
		for _, c in ipairs(clone:GetDescendants()) do
			if c:IsA("AnimationConstraint")
			and c.Attachment0 and c.Attachment0.Parent
			and c.Attachment1 and c.Attachment1.Parent then
				local childName = c.Attachment1.Parent.Name
				map[childName] = {
					constraint = c,
					part0  = c.Attachment0.Parent,
					part1  = c.Attachment1.Parent,
					att0CF = c.Attachment0.CFrame,
					att1CF = c.Attachment1.CFrame,
				}
			end
		end
		return map
	end

	local function setACConstraints(clone, enabled)
		for _, c in ipairs(clone:GetDescendants()) do
			if c:IsA("BallSocketConstraint") or c:IsA("AnimationConstraint") then
				pcall(function() c.Enabled = enabled end)
			end
		end
	end

	local get_game_ragdoll_info = function(enable)
		local place_id = game.PlaceId
		local rep = stalkie.services.replicated
		if place_id == 15546218972 or place_id == 6884319169 then
			local remote = rep:WaitForChild("event_rag", 4)
			if remote then return remote, {"Ball"}, false end
		elseif place_id == 5991163185 then
			local ok, remote = pcall(function() return rep.Remotes.Physics.Ragdoll end)
			if ok and remote then return remote, {}, false end
		elseif place_id == 5683833663 then
			local local_event = rep:WaitForChild("LocalRagdollEvent", 4)
			if local_event then return local_event, {enable}, true end
		end
		local function findChild(parent, path)
			local cur = parent
			for part in path:gmatch("[^/]+") do
				if not cur then return nil end
				cur = cur:FindFirstChild(part)
			end
			return cur
		end
		local candidates = {
			"Ragdoll", "RagdollEvent", "event_rag", "Rag", "Ragdolled",
			"Remotes/Ragdoll", "Events/Ragdoll", "Remotes/Physics/Ragdoll",
			"RemoteEvents/Ragdoll", "RemoteEvents/RagdollEvent",
		}
		for _, path in ipairs(candidates) do
			local r = findChild(rep, path)
			if r then
				if r:IsA("BindableEvent") then return r, {enable}, true
				elseif r:IsA("RemoteEvent") or r:IsA("RemoteFunction") then return r, {}, false end
			end
		end
		return nil, nil, false
	end

	local set_model_transparency = function(model, transparency)
		if not model then return end
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") then part.Transparency = transparency end
		end
	end

	local get_local_player = function()
		local player = stalkie.services.players.LocalPlayer
		if not player then
			return "bad argument to 'get_local_player' (LocalPlayer not found; must run in a LocalScript)"
		end
		return player
	end

	local get_char = function(player)
		if typeof(player) ~= "Instance" or not player:IsA("Player") then
			return ("bad argument #1 to 'get_char' (Player expected, got %s)"):format(typeof(player))
		end
		local character = player.Character
		if not character or not character.Parent then
			return ("Player %s has no active character."):format(player.Name)
		end
		return character
	end

	local clone_char = function(model)
		if typeof(model) ~= "Instance" then
			return ("bad argument #1 to 'clone_char' (Instance expected, got %s)"):format(typeof(model))
		end
		model.Archivable = true
		local new_clone = model:Clone()
		model.Archivable = false
		new_clone.Name = "Reanimation"
		new_clone.Parent = stalkie.services.workspace
		local _animScript = new_clone:WaitForChild("Animate", 6)
		if _animScript then _animScript.Disabled = true end
		new_clone.Humanoid.RequiresNeck = false
		new_clone.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		if new_clone:FindFirstChildWhichIsA("ForceField") then
			new_clone:FindFirstChildWhichIsA("ForceField"):Destroy()
		end
		return new_clone
	end

	local fire_remote = function(remote, is_local, ...)
		if typeof(remote) ~= "Instance" then
			return ("bad argument to 'fire_remote' (Instance expected, got %s)"):format(typeof(remote))
		end
		if is_local then
			if not remote:IsA("BindableEvent") then
				return ("bad argument to 'fire_remote' (BindableEvent expected for local event, got %s)"):format(remote.ClassName)
			end
			remote:Fire(...)
		else
			if not (remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction")) then
				return ("bad argument to 'fire_remote' (RemoteEvent or RemoteFunction expected, got %s)"):format(remote.ClassName)
			end
			if remote:IsA("RemoteEvent") then remote:FireServer(...)
			else remote:InvokeServer(...) end
		end
	end

	API.get_clone = function(player)
		player = player or get_local_player()
		if typeof(player) == "string" then return nil end
		return stalkie.clones[player]
	end

	API.get_real_character = function(player)
		player = player or get_local_player()
		if typeof(player) == "string" then return nil end
		return stalkie.real_chars[player]
	end

	API.is_reanimated        = function() return stalkie.flags.reanimated end
	API.set_animation_speed  = function(speed) stalkie.animation.state.speed = tonumber(speed) or 1.0 end
	API.on_animation_play    = function(cb) if type(cb) == "function" then stalkie.callbacks.on_play        = cb end end
	API.on_animation_stop    = function(cb) if type(cb) == "function" then stalkie.callbacks.on_stop        = cb end end
	API.on_deactivate        = function(cb) if type(cb) == "function" then stalkie.callbacks.on_deactivate  = cb end end
	API.is_animation_playing = function() return stalkie.animation.state.is_playing, stalkie.animation.state.current_url end

	API.stop_animation = function()
		local stopped_url = stalkie.animation.state.current_url
		if stalkie.connections.animation_hb then
			stalkie.connections.animation_hb:Disconnect()
			stalkie.connections.animation_hb = nil
		end
		local _keptSpeed = stalkie.animation.state.speed
		stalkie.animation.state = {
			is_playing=false, current_url=nil, speed=_keptSpeed,
			keyframes=nil, total_duration=0, elapsed_time=0,
		}
		local player = get_local_player()
		if typeof(player) == "string" then return end
		local cc = API.get_clone(player)
		if cc then
			for motor, orig_c0 in pairs(stalkie.animation.original_motor_c0s) do
				if motor and motor.Parent then motor.C0 = orig_c0 end
			end
			if stalkie.animation.ac_joint_map then
				for _, jd in pairs(stalkie.animation.ac_joint_map) do
					if jd.constraint and jd.constraint.Parent then
						pcall(function() jd.constraint.Transform = CFrame.identity end)
					end
				end
			end
			local cas = cc:FindFirstChild("Animate")
			if cas then cas.Enabled = true end
		end
		if stopped_url and stalkie.callbacks.on_stop then pcall(stalkie.callbacks.on_stop, stopped_url) end
	end

	API.reanimate = function(bool, remote, args)
		if bool ~= true and bool ~= false then
			return ("bad argument #1 to 'reanimate' (boolean expected, got %s)"):format(typeof(bool))
		end
		local player = get_local_player()
		if typeof(player) == "string" then return player end
		local is_local_event = false
		if not remote then
			local game_remote, game_args, is_local = get_game_ragdoll_info(bool)
			if game_remote then remote=game_remote; args=game_args; is_local_event=is_local end
		end
		if bool then
			if stalkie.flags.reanimated then return "Already reanimated." end
			local real_char = get_char(player)
			if typeof(real_char) == "string" then return real_char end
			if not real_char:FindFirstChild("Humanoid") then return "Real character is missing a Humanoid." end
			local real_hrp = real_char:FindFirstChild("HumanoidRootPart")
			if not real_hrp then return "Real character is missing a HumanoidRootPart, cannot reanimate." end
			stalkie.real_chars[player] = real_char
			local cloned_char = clone_char(real_char)
			if typeof(cloned_char) == "string" then return cloned_char end
			if not cloned_char:FindFirstChild("Humanoid") then return "Cloned character failed to create or is missing a Humanoid." end
			stalkie.clones[player] = cloned_char
			set_model_transparency(cloned_char, 1)
			local player_gui = player:FindFirstChildWhichIsA("PlayerGui")
			local _guisFlipped = {}
			if player_gui then
				for _, g in player_gui:GetChildren() do
					if g:IsA("ScreenGui") and g.ResetOnSpawn then
						g.ResetOnSpawn = false ; _guisFlipped[g] = true
					end
				end
			end
			player.Character = cloned_char
			local _camHum = cloned_char:WaitForChild("Humanoid", 6)
			if _camHum then stalkie.services.workspace.CurrentCamera.CameraSubject = _camHum end
			local _animS2 = cloned_char:WaitForChild("Animate", 6)
			if _animS2 then _animS2.Disabled = true ; _animS2.Disabled = false end
			table.clear(stalkie.animation.original_motor_c0s)
			table.clear(stalkie.animation.joints)
			local hasMotor6D = false
			for _, descendant in ipairs(cloned_char:GetDescendants()) do
				if descendant:IsA("Motor6D") and descendant.Part1 then
					hasMotor6D = true
					stalkie.animation.joints[descendant.Part1.Name] = descendant
					stalkie.animation.original_motor_c0s[descendant] = descendant.C0
				end
			end
			if not hasMotor6D then
				stalkie.animation.ac_joint_map = buildACJointMap(cloned_char)
			else
				stalkie.animation.ac_joint_map = nil
			end
			if player_gui then
				for _, g in player_gui:GetChildren() do
					if g:IsA("ScreenGui") and _guisFlipped[g] then g.ResetOnSpawn = true end
				end
			end
			local real_humanoid   = real_char.Humanoid
			local cloned_humanoid = cloned_char.Humanoid
			if real_humanoid and real_humanoid.Parent then
				real_humanoid.Health = real_humanoid.MaxHealth
			end
			for _, dt2 in ipairs({0.1, 0.5, 1.0}) do
				task.delay(dt2, function()
					if real_humanoid and real_humanoid.Parent and stalkie.flags.reanimated then
						real_humanoid.Health = real_humanoid.MaxHealth
					end
				end)
			end
			pcall(function() real_humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false) end)
			pcall(function()
				real_humanoid.HealthChanged:Connect(function(hp)
					if stalkie.flags.reanimated and real_humanoid and real_humanoid.Parent
					and hp < real_humanoid.MaxHealth then
						real_humanoid.Health = real_humanoid.MaxHealth
					end
				end)
			end)
			if cloned_humanoid then
				pcall(function() cloned_humanoid.BreakJointsOnDeath = false end)
				pcall(function()
					cloned_humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead,        false)
					cloned_humanoid:SetStateEnabled(Enum.HumanoidStateType.FallenParts,  false)
					cloned_humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,      false)
					cloned_humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics,      false)
				end)
				pcall(function()
					cloned_humanoid.HealthChanged:Connect(function(hp)
						if stalkie.flags.reanimated and cloned_humanoid and cloned_humanoid.Parent
						and hp < cloned_humanoid.MaxHealth then
							cloned_humanoid.Health = cloned_humanoid.MaxHealth
						end
					end)
				end)
				pcall(function()
					cloned_humanoid.StateChanged:Connect(function(_, new)
						local bad = new == Enum.HumanoidStateType.Dead
						         or new == Enum.HumanoidStateType.Ragdoll
						         or new == Enum.HumanoidStateType.Physics
						         or new == Enum.HumanoidStateType.FallenParts
						if bad and stalkie.flags.reanimated and cloned_humanoid and cloned_humanoid.Parent then
							cloned_humanoid.Health = cloned_humanoid.MaxHealth
							pcall(function() cloned_humanoid:ChangeState(Enum.HumanoidStateType.Running) end)
						end
					end)
				end)
			end
			local ZERO_VEL = Vector3.new()
			local ZERO_TORQUE = Vector3.new(0, 0, 0)
			local FULL_TORQUE = Vector3.new(400000, 400000, 400000)
			local cachedBg
			stalkie.connections.hb = stalkie.services.run_service.Heartbeat:Connect(
				LPH_NO_VIRTUALIZE(function()
					if not real_char or not real_char.Parent or not cloned_char or not cloned_char.Parent then
						API.reanimate(false, remote, args); return
					end
					local hrp = cloned_char:FindFirstChild("HumanoidRootPart")
					if hrp then
						local bg = cachedBg
						if not bg or bg.Parent ~= hrp then
							bg = hrp:FindFirstChild("ShiftLockGyro")
							if not bg then
								bg = Instance.new("BodyGyro")
								bg.Name="ShiftLockGyro"; bg.P=5000; bg.D=300
								bg.MaxTorque=ZERO_TORQUE; bg.Parent=hrp
							end
							cachedBg = bg
						end
						local uis = stalkie.services.user_input_service
						local mouse_behavior = uis.MouseBehavior
						local is_panning = uis:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
						if mouse_behavior==Enum.MouseBehavior.LockCenter and not is_panning then
							local cam = stalkie.services.workspace.CurrentCamera
							if cam then
								local look = cam.CFrame.LookVector
								local hzLook = Vector3.new(look.X, 0, look.Z)
								if hzLook.Magnitude > 0.001 then
									bg.MaxTorque = FULL_TORQUE
									bg.CFrame = CFrame.new(Vector3.new(), hzLook)
								end
							end
						else
							if bg.MaxTorque ~= ZERO_TORQUE then bg.MaxTorque = ZERO_TORQUE end
						end
					end
					for _, p in real_char:GetChildren() do
						if p:IsA("BasePart") then
							local clone_part = cloned_char:FindFirstChild(p.Name)
							if clone_part then
								p.CFrame=clone_part.CFrame; p.Velocity=ZERO_VEL
							end
						end
					end
					if real_humanoid and real_humanoid.Parent and real_humanoid.Health < real_humanoid.MaxHealth then
						real_humanoid.Health = real_humanoid.MaxHealth
					end
					if cloned_humanoid and cloned_humanoid.Parent and cloned_humanoid.Health < cloned_humanoid.MaxHealth then
						cloned_humanoid.Health = cloned_humanoid.MaxHealth
					end
				end))

			task.delay(1.5, function()
				if not stalkie.flags.reanimated then return end
				stalkie.connections.died = real_humanoid.Died:Connect(function()
					API.reanimate(false, remote, args)
				end)
				stalkie.connections.real_char_child_removed = real_char.ChildRemoved:Connect(function(child)
					if child==real_humanoid or child==real_hrp then API.reanimate(false,remote,args) end
				end)
			end)
			stalkie.connections.clone_char_child_removed = cloned_char.ChildRemoved:Connect(function(child)
				if child==cloned_humanoid then API.reanimate(false,remote,args) end
			end)
			stalkie.connections.clone_died = cloned_humanoid.Died:Connect(function()
				task.delay(0.35, function()
					if not stalkie.flags.reanimated then return end
					if not cloned_humanoid or not cloned_humanoid.Parent then
						API.reanimate(false, remote, args)
					end
				end)
			end)
			stalkie.connections.character_removing = player.CharacterRemoving:Connect(function(cbr)
				if cbr == cloned_char then API.reanimate(false, remote, args) end
			end)
			if remote then
				local err = fire_remote(remote, is_local_event, unpack(args or {}))
				if err then return err end
			end
			stalkie.flags.reanimated = true
		else
			if not stalkie.flags.reanimated then
				for key, conn in pairs(stalkie.connections) do
					if conn and type(conn) == "table" and type(conn.Disconnect) == "function" then
						pcall(conn.Disconnect, conn); stalkie.connections[key] = nil
					end
				end
				return
			end
			API.stop_animation()
			do
				local _cc_off = API.get_clone(player)
				if _cc_off and stalkie.animation.ac_joint_map then
					setACConstraints(_cc_off, true)
					stalkie.animation.ac_joint_map = nil
				end
			end
			if remote then
				local err = fire_remote(remote, is_local_event, unpack(args or {}))
				if err then return err end
			end
			for key, connection in pairs(stalkie.connections) do
				if connection then connection:Disconnect(); stalkie.connections[key]=nil end
			end
			local cc2 = stalkie.clones[player]
			local rc2 = stalkie.real_chars[player]
			local _savedHRPCF = nil
			if cc2 and cc2.Parent then
				local _cHRP = cc2:FindFirstChild("HumanoidRootPart")
				if _cHRP then _savedHRPCF = _cHRP.CFrame end
			end
			if rc2 and rc2.Parent then
				set_model_transparency(rc2, 0)
				local hrp2 = rc2:FindFirstChild("HumanoidRootPart")
				if hrp2 then hrp2.Transparency = 1 end
				local pg2 = player:FindFirstChildWhichIsA("PlayerGui")
				local _guisFlipped2 = {}
				if pg2 then
					for _, g in pg2:GetChildren() do
						if g:IsA("ScreenGui") and g.ResetOnSpawn then
							g.ResetOnSpawn = false ; _guisFlipped2[g] = true
						end
					end
				end
				player.Character = rc2
				if cc2 and cc2.Parent then cc2:Destroy(); stalkie.clones[player]=nil end
				local crh2 = rc2:FindFirstChild("Humanoid")
				if crh2 then stalkie.services.workspace.CurrentCamera.CameraSubject = crh2 end
				if _savedHRPCF then
					local _snapCF = _savedHRPCF
					local _snapRC = rc2
					task.spawn(function()
						local t0 = tick()
						while tick() - t0 < 0.5 do
							task.wait()
							local h = _snapRC and _snapRC.Parent and _snapRC:FindFirstChild("HumanoidRootPart")
							if not h then break end
							h.CFrame = _snapCF
							pcall(function() h.Velocity = Vector3.new() end)
							pcall(function() h.AssemblyLinearVelocity = Vector3.new() end)
						end
						if not (_snapRC and _snapRC.Parent) then return end
						local wrapLayers = {}
						for _, desc in _snapRC:GetDescendants() do
							if desc:IsA("WrapLayer") then
								wrapLayers[#wrapLayers + 1] = desc
								pcall(function() desc.Enabled = false end)
							end
						end
						task.defer(function()
							for _, wl in wrapLayers do
								pcall(function() if wl and wl.Parent then wl.Enabled = true end end)
							end
						end)
						for _, child in _snapRC:GetChildren() do
							if child:IsA("Accessory") then
								local handle = child:FindFirstChild("Handle")
								if handle then
									local weld = handle:FindFirstChildWhichIsA("Weld")
									           or handle:FindFirstChildWhichIsA("AccessoryWeld")
									if weld and weld.Part1 and weld.Part1.Parent then
										pcall(function()
											handle.CFrame = weld.Part1.CFrame * weld.C1 * weld.C0:Inverse()
										end)
									end
								end
							end
						end
					end)
				end
				if pg2 then
					for _, g in pg2:GetChildren() do
						if g:IsA("ScreenGui") and _guisFlipped2[g] then g.ResetOnSpawn = true end
					end
				end
			end
			stalkie.clones[player]     = nil
			stalkie.real_chars[player] = nil
			if stalkie.callbacks.on_deactivate then pcall(stalkie.callbacks.on_deactivate) end
			stalkie.flags.reanimated = false
		end
	end

	API.play_animation = function(url, speed)
		if not stalkie.flags.reanimated then return "Cannot play animation, not reanimated." end
		local player = get_local_player()
		if typeof(player) == "string" then return player end
		local cc = API.get_clone(player)
		if not cc then return "Cannot play animation, clone character not found." end
		if stalkie.animation.state.is_playing and stalkie.animation.state.current_url==url then
			API.stop_animation(); return
		end
		API.stop_animation()
		local ctrl = cc:FindFirstChildOfClass("Humanoid") or cc:FindFirstChildOfClass("AnimationController")
		if ctrl then
			local tracks = ctrl:GetPlayingAnimationTracks()
			if tracks then for _, track in ipairs(tracks) do track:Stop(0) end end
		end
		local anim = stalkie.animation
		local cas = cc:FindFirstChild("Animate")
		if cas then cas.Enabled = false end
		anim.state.speed = tonumber(speed) or 1.0
		local keyframe_data = anim.cache[url]
		if not keyframe_data then
			local ok1, response = pcall(game.HttpGet, game, url)
			if not ok1 then return "Animation Error: Failed to fetch URL." end
			local loaded_fn, load_err = _safeLoadstring(response)
			if not loaded_fn then return "Animation Error: Invalid script from URL. "..tostring(load_err) end
			local ok2, data = pcall(loaded_fn)
			if not ok2 then return "Animation Error: Script from URL failed to execute. "..tostring(data) end
			keyframe_data = data
			if typeof(keyframe_data) ~= "table" then return "Animation Error: Script from URL did not return a table." end
			anim.cache[url] = keyframe_data
		end
		local keyframes = keyframe_data[next(keyframe_data)]
		if not keyframes or #keyframes==0 then return "No keyframes array found for animation URL: "..url end
		anim.state.keyframes      = keyframes
		anim.state.is_playing     = true
		anim.state.current_url    = url
		anim.state.total_duration = keyframes[#keyframes].Time
		if anim.state.total_duration<=0 then API.stop_animation(); return end
		anim.state.elapsed_time = 0
		local hasMotor6D_pa = next(anim.joints) ~= nil
		if not hasMotor6D_pa then
			anim.ac_joint_map = buildACJointMap(cc)
			if not (anim.ac_joint_map and next(anim.ac_joint_map)) then
				anim.ac_joint_map = nil
			end
		end
		if stalkie.callbacks.on_play then pcall(stalkie.callbacks.on_play, anim.state.current_url) end
		local _animCC = cc
		local _animEvent = anim.ac_joint_map
			and stalkie.services.run_service.PreSimulation
			or  stalkie.services.run_service.Heartbeat
		local _animAnimator = anim.ac_joint_map and (function()
			local h = _animCC:FindFirstChildOfClass("Humanoid")
			       or _animCC:FindFirstChildOfClass("AnimationController")
			return h and h:FindFirstChildOfClass("Animator")
		end)() or nil
		stalkie.connections.animation_hb = _animEvent:Connect(
			LPH_NO_VIRTUALIZE(function(dt)
				if not anim.state.is_playing then return end
				if not _animCC or not _animCC.Parent then API.stop_animation(); return end
				anim.state.elapsed_time =
					(anim.state.elapsed_time + dt * anim.state.speed) % anim.state.total_duration
				local kfs = anim.state.keyframes
				local t   = anim.state.elapsed_time
				local lo, hi = 1, #kfs - 1
				while lo < hi do
					local mid = math.floor((lo + hi + 1) / 2)
					if kfs[mid].Time <= t then lo = mid else hi = mid - 1 end
				end
				local cf = kfs[lo]
				local nf = kfs[lo + 1] or kfs[1]
				local fd = nf.Time - cf.Time
				if fd <= 0 then fd = (anim.state.total_duration - cf.Time) + nf.Time end
				local segElapsed = t - cf.Time
				if segElapsed < 0 then segElapsed = segElapsed + anim.state.total_duration end
				local alpha = math.clamp(segElapsed / fd, 0, 1)
				if anim.ac_joint_map then
					if _animAnimator and _animAnimator.EvaluationThrottled then return end
					for _, entry in ipairs(AC_HIERARCHY) do
						local jd = anim.ac_joint_map[entry.part]
						if jd and jd.constraint and jd.constraint.Parent then
							local poseCF = CFrame.identity
							if cf.Data and cf.Data[entry.part] then
								local p  = cf.Data[entry.part]
								local np = nf.Data and nf.Data[entry.part]
								poseCF   = (np ~= nil) and p:Lerp(np, alpha) or p
							end
							jd.constraint.Transform = poseCF
						end
					end
				else
					for partName, pose_cf in pairs(cf.Data) do
						local motor = anim.joints[partName]
						if motor and anim.original_motor_c0s[motor] then
							local orig = anim.original_motor_c0s[motor]
							local np   = nf.Data and nf.Data[partName]
							motor.C0   = np and (orig*pose_cf:Lerp(np,alpha)) or (orig*pose_cf)
						end
					end
				end
			end))
	end

	API._buildACJointMap  = buildACJointMap
	API._setACConstraints = setACConstraints
	API._AC_HIERARCHY     = AC_HIERARCHY

	_G.loadReanimAPI = function(cb)
		if _G._reanimLoaded then if cb then cb() end; return end
		local ok, result = pcall(function() return API end)
		if ok and result and result.reanimate then
			_G._reanimAPI    = result
			_G._reanimLoaded = true
			if cb then cb() end
		else
			notify("Reanim", "Failed to init integral Reanimation API")
		end
	end

end)()

local _initReanimPanel
_initReanimPanel = function()
	local _RS = {}
	local function _setup()
		_G._reanimPanel = makeFloatingPanel(340, 380, 0.5, 0.35)
		_G._reanimPanel.Name = "ROT_Panel"

		local reanimBar = makePanelTitleBar(_G._reanimPanel, "ROT", function()
			_G._reanimPanel.Visible = false
		end)
		_cs.makePanelDraggable(_G._reanimPanel, reanimBar)

		local STATUS_Y = 46

		local statusChip = Instance.new("Frame", _G._reanimPanel)
		statusChip.Size = UDim2.new(0, 170, 0, 26) ; statusChip.Position = UDim2.new(0, 12, 0, STATUS_Y)
		statusChip.BackgroundColor3 = C.CARD ; statusChip.BackgroundTransparency = 0
		statusChip.BorderSizePixel = 0 ; statusChip.ZIndex = 152
		Instance.new("UICorner", statusChip).CornerRadius = UDim.new(0, 6)
		local statusStroke = Instance.new("UIStroke", statusChip)
		statusStroke.Color = C.DIV ; statusStroke.Thickness = 1 ; statusStroke.Transparency = 0.55

		_RS.reanimStatusDot = Instance.new("Frame", statusChip)
		_RS.reanimStatusDot.Size = UDim2.new(0, 6, 0, 6) ; _RS.reanimStatusDot.Position = UDim2.new(0, 10, 0.5, 0)
		_RS.reanimStatusDot.AnchorPoint = Vector2.new(0, 0.5) ; _RS.reanimStatusDot.BackgroundColor3 = C.DIV
		_RS.reanimStatusDot.BorderSizePixel = 0 ; _RS.reanimStatusDot.ZIndex = 153
		Instance.new("UICorner", _RS.reanimStatusDot).CornerRadius = UDim.new(1, 0)

		_RS.reanimStatusLbl = Instance.new("TextLabel", statusChip)
		_RS.reanimStatusLbl.Size = UDim2.new(1, -26, 1, 0) ; _RS.reanimStatusLbl.Position = UDim2.new(0, 22, 0, 0)
		_RS.reanimStatusLbl.BackgroundTransparency = 1 ; _RS.reanimStatusLbl.Font = Enum.Font.GothamSemibold
		_RS.reanimStatusLbl.TextSize = 11 ; _RS.reanimStatusLbl.TextColor3 = C.SUB
		_RS.reanimStatusLbl.TextXAlignment = Enum.TextXAlignment.Left
		_RS.reanimStatusLbl.TextYAlignment = Enum.TextYAlignment.Center
		_RS.reanimStatusLbl.Text = "Idle" ; _RS.reanimStatusLbl.ZIndex = 153

		_RS.reanimToggleBtn = Instance.new("TextButton", _G._reanimPanel)
		_RS.reanimToggleBtn.Size = UDim2.new(0, 120, 0, 26) ; _RS.reanimToggleBtn.AnchorPoint = Vector2.new(1, 0)
		_RS.reanimToggleBtn.Position = UDim2.new(1, -12, 0, STATUS_Y) ; _RS.reanimToggleBtn.BackgroundColor3 = C.ACTION
		_RS.reanimToggleBtn.BackgroundTransparency = 0 ; _RS.reanimToggleBtn.BorderSizePixel = 0
		_RS.reanimToggleBtn.Font = Enum.Font.GothamBold ; _RS.reanimToggleBtn.TextSize = 11
		_RS.reanimToggleBtn.TextColor3 = C.TEXT ; _RS.reanimToggleBtn.Text = "Reanimate"
		_RS.reanimToggleBtn.AutoButtonColor = false ; _RS.reanimToggleBtn.ZIndex = 152
		Instance.new("UICorner", _RS.reanimToggleBtn).CornerRadius = UDim.new(0, 6)
		_RS.reanimToggleBtn.MouseEnter:Connect(function()
			tween(_RS.reanimToggleBtn, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {BackgroundTransparency = 0.05})
		end)
		_RS.reanimToggleBtn.MouseLeave:Connect(function()
			tween(_RS.reanimToggleBtn, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {BackgroundTransparency = 0.15})
		end)

		do
			local hdrDiv = Instance.new("Frame", _G._reanimPanel)
			hdrDiv.BackgroundColor3 = C.DIV ; hdrDiv.BorderSizePixel = 0
			hdrDiv.Position = UDim2.new(0, 12, 0, STATUS_Y + 32)
			hdrDiv.Size = UDim2.new(1, -24, 0, 1) ; hdrDiv.BackgroundTransparency = 0 ; hdrDiv.ZIndex = 152
			local dGrad = Instance.new("UIGradient", hdrDiv)
			dGrad.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(0.15, 0),
				NumberSequenceKeypoint.new(0.85, 0), NumberSequenceKeypoint.new(1, 0.8),
			})
		end

		local TAB_Y = STATUS_Y + 32 + 8
		local TAB_H = 28
		local tabBar = Instance.new("Frame", _G._reanimPanel)
		tabBar.BackgroundColor3 = C.BG ; tabBar.BackgroundTransparency = 0 ; tabBar.BorderSizePixel = 0
		tabBar.Position = UDim2.new(0, 12, 0, TAB_Y) ; tabBar.Size = UDim2.new(1, -24, 0, TAB_H) ; tabBar.ZIndex = 152
		Instance.new("UICorner", tabBar).CornerRadius = UDim.new(0, 8)
		local tabStroke = Instance.new("UIStroke", tabBar)
		tabStroke.Color = C.DIV ; tabStroke.Thickness = 1 ; tabStroke.Transparency = 0.55

		local tabPill = Instance.new("Frame", tabBar)
		tabPill.BackgroundColor3 = C.CARD ; tabPill.BackgroundTransparency = 0 ; tabPill.BorderSizePixel = 0
		tabPill.Position = UDim2.new(0, 2, 0, 2) ; tabPill.Size = UDim2.new(0.37, -4, 1, -4) ; tabPill.ZIndex = 153
		Instance.new("UICorner", tabPill).CornerRadius = UDim.new(0, 6)
		local tabPillStroke = Instance.new("UIStroke", tabPill)
		tabPillStroke.Color = C.DIV ; tabPillStroke.Thickness = 1 ; tabPillStroke.Transparency = 0.6

		do
			_RS.tabBtns = {}
			local function makeTab(label)
				local btn = Instance.new("TextButton", tabBar)
				btn.BackgroundTransparency = 1
				btn.BorderSizePixel        = 0
				btn.Text                   = label
				btn.Font                   = Enum.Font.GothamSemibold
				btn.TextSize               = 11
				btn.TextColor3             = C.DIM
				btn.AutoButtonColor        = false
				btn.ZIndex                 = 154
				return btn
			end
			_RS.tabGlobalBtn = makeTab("Global") ; _RS.tabCustomBtn = makeTab("Custom")
			_RS.tabFavsBtn   = makeTab("Favs")   ; _RS.tabStatesBtn = makeTab("States")
			_RS.tabBtns = { _RS.tabGlobalBtn, _RS.tabCustomBtn, _RS.tabFavsBtn, _RS.tabStatesBtn }
			for i, btn in ipairs(_RS.tabBtns) do
				btn.Position = UDim2.new(0.25 * (i-1), 0, 0, 0) ; btn.Size = UDim2.new(0.25, 0, 1, 0)
			end
		end
		_RS.tabGlobalBtn.MouseButton1Click:Connect(function() _RS.setTab("global") end)
		_RS.tabCustomBtn.MouseButton1Click:Connect(function() if reloadCustom then reloadCustom() end ; _RS.setTab("custom") end)
		_RS.tabFavsBtn.MouseButton1Click:Connect(function()   _RS.setTab("favs")   end)
		_RS.tabStatesBtn.MouseButton1Click:Connect(function() _RS.setTab("states") end)

		local SEARCH_Y = TAB_Y + TAB_H + 8
		do
			local reanimSearchCard = Instance.new("Frame", _G._reanimPanel)
			reanimSearchCard.BackgroundColor3 = C.CARD ; reanimSearchCard.BackgroundTransparency = 0
			reanimSearchCard.BorderSizePixel = 0 ; reanimSearchCard.Position = UDim2.new(0, 12, 0, SEARCH_Y)
			reanimSearchCard.Size = UDim2.new(1, -24, 0, 28) ; reanimSearchCard.ZIndex = 152
			Instance.new("UICorner", reanimSearchCard).CornerRadius = UDim.new(0, 8)
			local reanimSearchStroke = Instance.new("UIStroke", reanimSearchCard)
			reanimSearchStroke.Color = C.DIV ; reanimSearchStroke.Thickness = 1 ; reanimSearchStroke.Transparency = 0.5
			_RS.reanimSearchBox = Instance.new("TextBox", reanimSearchCard)
			_RS.reanimSearchBox.BackgroundTransparency = 1 ; _RS.reanimSearchBox.Position = UDim2.new(0, 10, 0, 0)
			_RS.reanimSearchBox.Size = UDim2.new(1, -10, 1, 0) ; _RS.reanimSearchBox.Font = Enum.Font.GothamSemibold
			_RS.reanimSearchBox.TextSize = 11 ; _RS.reanimSearchBox.TextColor3 = C.TEXT
			_RS.reanimSearchBox.PlaceholderColor3 = C.DIM ; _RS.reanimSearchBox.Text = ""
			_RS.reanimSearchBox.PlaceholderText = "Search animations..." ; _RS.reanimSearchBox.ClearTextOnFocus = false
			_RS.reanimSearchBox.ZIndex = 153
			_RS.reanimSearchBox.Focused:Connect(function()
				tween(reanimSearchStroke, TweenInfo.new(0.15), {Color = C.ACCENT, Transparency = 0.4})
			end)
			_RS.reanimSearchBox.FocusLost:Connect(function()
				tween(reanimSearchStroke, TweenInfo.new(0.2), {Color = C.DIV, Transparency = 0.5})
			end)
			_RS.reanimSearchCard = reanimSearchCard
		end

		local SCROLL_Y = SEARCH_Y + 28 + 6
		_RS.SLIDER_H = 57
		local reanimScrollBox = Instance.new("Frame", _G._reanimPanel)
		reanimScrollBox.BackgroundColor3 = C.BG ; reanimScrollBox.BackgroundTransparency = 0
		reanimScrollBox.BorderSizePixel = 0 ; reanimScrollBox.Position = UDim2.new(0, 12, 0, SCROLL_Y)
		reanimScrollBox.Size = UDim2.new(1, -24, 0, 380 - SCROLL_Y - 42 - 16)
		reanimScrollBox.ZIndex = 152 ; reanimScrollBox.ClipsDescendants = true
		Instance.new("UICorner", reanimScrollBox).CornerRadius = UDim.new(0, 8)
		local rsbStroke = Instance.new("UIStroke", reanimScrollBox)
		rsbStroke.Color = C.DIV ; rsbStroke.Thickness = 1 ; rsbStroke.Transparency = 0.6
		_RS.reanimScrollBox = reanimScrollBox
		_RS.reanimScroll = Instance.new("ScrollingFrame", reanimScrollBox)
		_RS.reanimScroll.Position = UDim2.new(0,0,0,0) ; _RS.reanimScroll.Size = UDim2.new(1,0,1,0)
		_RS.reanimScroll.BackgroundTransparency = 1 ; _RS.reanimScroll.ScrollBarThickness = 0
		_RS.reanimScroll.ScrollBarImageColor3 = C.ACCENT ; _RS.reanimScroll.ScrollBarImageTransparency = 0.6
		_RS.reanimScroll.BorderSizePixel = 0 ; _RS.reanimScroll.CanvasSize = UDim2.new(0,0,0,0) ; _RS.reanimScroll.ZIndex = 152

		local STATES_Y = SEARCH_Y
		local statesBar = Instance.new("Frame", _G._reanimPanel)
		statesBar.BackgroundColor3 = C.BG ; statesBar.BackgroundTransparency = 0 ; statesBar.BorderSizePixel = 0
		statesBar.Position = UDim2.new(0, 12, 0, STATES_Y) ; statesBar.Size = UDim2.new(1, -24, 0, TAB_H)
		statesBar.ZIndex = 152 ; statesBar.Visible = false
		Instance.new("UICorner", statesBar).CornerRadius = UDim.new(0, 8)
		local statesBarStroke = Instance.new("UIStroke", statesBar)
		statesBarStroke.Color = C.DIV ; statesBarStroke.Thickness = 1 ; statesBarStroke.Transparency = 0.55
		local statesPill = Instance.new("Frame", statesBar)
		statesPill.BackgroundColor3 = C.CARD ; statesPill.BackgroundTransparency = 0 ; statesPill.BorderSizePixel = 0
		statesPill.Position = UDim2.new(0, 2, 0, 2) ; statesPill.Size = UDim2.new(0.333, -4, 1, -4) ; statesPill.ZIndex = 153
		Instance.new("UICorner", statesPill).CornerRadius = UDim.new(0, 6)
		Instance.new("UIStroke", statesPill).Color = C.DIV
		_RS.statesPill = statesPill
		local function makeStateBtn(label, posX)
			local btn = Instance.new("TextButton", statesBar)
			btn.BackgroundTransparency = 1 ; btn.BorderSizePixel = 0
			btn.Position = UDim2.new(posX, 0, 0, 0) ; btn.Size = UDim2.new(0.333, 0, 1, 0)
			btn.Font = Enum.Font.GothamSemibold ; btn.TextSize = 11 ; btn.TextColor3 = C.SUB
			btn.Text = label ; btn.AutoButtonColor = false ; btn.ZIndex = 154
			return btn
		end
		_RS.stateIdleBtn = makeStateBtn("Idle", 0) ; _RS.stateWalkBtn = makeStateBtn("Walk", 0.333)
		_RS.stateJumpBtn = makeStateBtn("Jump", 0.667) ; _RS.activeState = nil

		local SUBSTATES_Y = STATES_Y + TAB_H + 8
		local subStatesBar = Instance.new("Frame", _G._reanimPanel)
		subStatesBar.BackgroundColor3 = C.BG ; subStatesBar.BackgroundTransparency = 0 ; subStatesBar.BorderSizePixel = 0
		subStatesBar.Position = UDim2.new(0, 12, 0, SUBSTATES_Y) ; subStatesBar.Size = UDim2.new(1, -24, 0, TAB_H)
		subStatesBar.ZIndex = 152 ; subStatesBar.Visible = false
		Instance.new("UICorner", subStatesBar).CornerRadius = UDim.new(0, 8)
		Instance.new("UIStroke", subStatesBar).Color = C.DIV
		local subStatesPill = Instance.new("Frame", subStatesBar)
		subStatesPill.BackgroundColor3 = C.CARD ; subStatesPill.BackgroundTransparency = 0 ; subStatesPill.BorderSizePixel = 0
		subStatesPill.Position = UDim2.new(0, 2, 0, 2) ; subStatesPill.Size = UDim2.new(0.5, -4, 1, -4) ; subStatesPill.ZIndex = 153
		Instance.new("UICorner", subStatesPill).CornerRadius = UDim.new(0, 6)
		Instance.new("UIStroke", subStatesPill).Color = C.DIV
		_RS.subStatesPill = subStatesPill
		local function makeSubStateBtn(label, posX)
			local btn = Instance.new("TextButton", subStatesBar)
			btn.BackgroundTransparency = 1 ; btn.BorderSizePixel = 0
			btn.Position = UDim2.new(posX, 0, 0, 0) ; btn.Size = UDim2.new(0.5, 0, 1, 0)
			btn.Font = Enum.Font.GothamSemibold ; btn.TextSize = 11 ; btn.TextColor3 = C.SUB
			btn.Text = label ; btn.AutoButtonColor = false ; btn.ZIndex = 154
			return btn
		end
		_RS.subStateGlobalBtn = makeSubStateBtn("Global", 0)
		_RS.subStateCustomBtn = makeSubStateBtn("Custom", 0.5)
		_RS.activeSubState    = nil

		local PANEL_H = 380
		local function repositionContent()
			local isStates = _RS.activeTab == "states"
			_RS.reanimSearchCard.Visible = not isStates
			if isStates then
				local sbY = TAB_Y + TAB_H + 8
				_RS.statesBar.Position = UDim2.new(0, 12, 0, sbY) ; _RS.statesBar.Visible = true
				local subY = sbY + TAB_H + 8
				_RS.subStatesBar.Position = UDim2.new(0, 12, 0, subY) ; _RS.subStatesBar.Visible = true
				if _RS.statesSearchCard then
					local ssY = subY + TAB_H + 8
					_RS.statesSearchCard.Position = UDim2.new(0, 12, 0, ssY) ; _RS.statesSearchCard.Visible = true
					local scrollY = ssY + 28 + 6
					_RS.reanimScrollBox.Position = UDim2.new(0, 12, 0, scrollY)
					_RS.reanimScrollBox.Size = UDim2.new(1, -24, 0, PANEL_H - scrollY - 42 - 16)
				end
				_RS.reanimScrollBox.Visible = true
			else
				_RS.statesBar.Visible = false ; _RS.subStatesBar.Visible = false
				if _RS.statesSearchCard then _RS.statesSearchCard.Visible = false end
				local searchY = TAB_Y + TAB_H + 8
				_RS.reanimSearchCard.Position = UDim2.new(0, 12, 0, searchY)
				local scrollY = searchY + 28 + 6
				_RS.reanimScrollBox.Position = UDim2.new(0, 12, 0, scrollY)
				_RS.reanimScrollBox.Size = UDim2.new(1, -24, 0, PANEL_H - scrollY - 42 - 16)
				_RS.reanimScrollBox.Visible = true
			end
		end
		_RS.repositionContent = repositionContent

		local function setStateTab(state)
			if state ~= "idle" and state ~= "walk" and state ~= "jump" then state = "idle" end
			_RS.activeState = state
			_RS.stateIdleBtn.TextColor3 = state == "idle" and C.TEXT or C.SUB
			_RS.stateWalkBtn.TextColor3 = state == "walk" and C.TEXT or C.SUB
			_RS.stateJumpBtn.TextColor3 = state == "jump" and C.TEXT or C.SUB
			local stPillX = state == "idle" and 0 or state == "walk" and 0.333 or 0.667
			tween(statesPill, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
				{Position = UDim2.new(stPillX, 2, 0, 2)})
			subStatesBar.Visible = true
			task.defer(function() if _RS.refreshStateHighlights then _RS.refreshStateHighlights() end end)
		end

		local function setSubStateTab(sub)
			_RS.activeSubState = sub
			_RS.subStateCustomBtn.TextColor3 = sub == "custom" and C.TEXT or C.SUB
			_RS.subStateGlobalBtn.TextColor3 = sub == "global" and C.TEXT or C.SUB
			tween(subStatesPill, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
				{Position = UDim2.new(sub == "global" and 0 or 0.5, 2, 0, 2)})
			_RS.reanimItems = sub == "custom" and _RS.customItems or _RS.globalItems
			_RS.hideAllRows()
			if _RS.customLoadLbl then _RS.customLoadLbl.Visible = false end
			_RS.reanimRefreshSearch()
			if _RS.refreshStateHighlights then _RS.refreshStateHighlights() end
			if _RS.repositionContent then _RS.repositionContent() end
		end

		_RS.stateIdleBtn.MouseButton1Click:Connect(function() setStateTab("idle") end)
		_RS.stateWalkBtn.MouseButton1Click:Connect(function() setStateTab("walk") end)
		_RS.stateJumpBtn.MouseButton1Click:Connect(function() setStateTab("jump") end)
		_RS.subStateCustomBtn.MouseButton1Click:Connect(function() setSubStateTab("custom") end)
		_RS.subStateGlobalBtn.MouseButton1Click:Connect(function() setSubStateTab("global") end)

		_RS.refreshStateHighlights = function()
			local slot = _RS.activeState or "idle"
			local assigned = _RS.stateAnims[slot]
			local assignedName = assigned and assigned.name or nil
			for _, it in ipairs(_RS.globalItems) do
				it.nameLbl.TextColor3 = (it.name == assignedName) and C.ACCENT or C.TEXT
			end
			for _, it in ipairs(_RS.customItems) do
				it.nameLbl.TextColor3 = (it.name == assignedName) and C.ACCENT or C.TEXT
			end
		end

		_RS.statesBar = statesBar ; _RS.subStatesBar = subStatesBar

		do
			local ssCard = Instance.new("Frame", _G._reanimPanel)
			ssCard.BackgroundColor3 = C.CARD ; ssCard.BackgroundTransparency = 0 ; ssCard.BorderSizePixel = 0
			ssCard.Position = UDim2.new(0, 12, 0, 0) ; ssCard.Size = UDim2.new(1, -24, 0, 28)
			ssCard.ZIndex = 152 ; ssCard.Visible = false
			Instance.new("UICorner", ssCard).CornerRadius = UDim.new(0, 8)
			local ssStroke = Instance.new("UIStroke", ssCard)
			ssStroke.Color = C.DIV ; ssStroke.Thickness = 1 ; ssStroke.Transparency = 0.5
			local ssBox = Instance.new("TextBox", ssCard)
			ssBox.BackgroundTransparency = 1 ; ssBox.Position = UDim2.new(0, 10, 0, 0)
			ssBox.Size = UDim2.new(1, -10, 1, 0) ; ssBox.Font = Enum.Font.GothamSemibold
			ssBox.TextSize = 11 ; ssBox.TextColor3 = C.TEXT ; ssBox.PlaceholderColor3 = C.DIM
			ssBox.Text = "" ; ssBox.PlaceholderText = "Search animations..." ; ssBox.ClearTextOnFocus = false ; ssBox.ZIndex = 153
			ssBox.Focused:Connect(function() tween(ssStroke, TweenInfo.new(0.15), {Color = C.ACCENT, Transparency = 0.4}) end)
			ssBox.FocusLost:Connect(function() tween(ssStroke, TweenInfo.new(0.2), {Color = C.DIV, Transparency = 0.5}) end)
			ssBox:GetPropertyChangedSignal("Text"):Connect(function()
				if _RS.activeTab == "states" then
					_RS.reanimSearchBox.Text = ssBox.Text ; _RS.reanimRefreshSearch()
				end
			end)
			_RS.statesSearchCard = ssCard ; _RS.statesSearchBox = ssBox
		end

		_RS.globalItems = {} ; _RS.customItems = {} ; _RS.favsItems = {} ; _RS.favKeybinds = {}
		_RS.REANIM_KEYBINDS_FILE = "ROT/reanim_keybinds.json"
		_RS.REANIM_FAVS_FILE     = "ROT/reanim_favs.json"
		_RS.REANIM_STATES_FILE   = "ROT/reanim_states.json"
		_RS.savedReanimKeybinds  = {}

		_RS.saveReanimKeybinds = function()
			pcall(function()
				if not isfolder("ROT") then makefolder("ROT") end
				local data = {}
				for keyName, bind in pairs(_RS.favKeybinds) do
					if type(keyName)=="string" and type(bind)=="table" and type(bind.name)=="string" and bind.name~="" then
						data[bind.name] = keyName
					end
				end
				_RS.savedReanimKeybinds = data
				writefile(_RS.REANIM_KEYBINDS_FILE, game:GetService("HttpService"):JSONEncode(data))
			end)
		end
		_RS.loadReanimKeybinds = function()
			pcall(function()
				if isfile and isfile(_RS.REANIM_KEYBINDS_FILE) then
					local ok, data = pcall(function() return game:GetService("HttpService"):JSONDecode(readfile(_RS.REANIM_KEYBINDS_FILE)) end)
					if ok and type(data)=="table" then
						_RS.savedReanimKeybinds = {}
						for emoteName, keyName in pairs(data) do
							if type(emoteName)=="string" and type(keyName)=="string" and keyName~="" and keyName~="Unknown" then
								_RS.savedReanimKeybinds[emoteName] = keyName
							end
						end
					end
				end
			end)
		end
		_RS.saveFavsItems = function()
			pcall(function()
				if not isfolder("ROT") then makefolder("ROT") end
				local data = {}
				for _, it in ipairs(_RS.favsItems) do
					if type(it.name)=="string" and it.name~="" then data[#data+1] = {name=it.name, url=it.url} end
				end
				writefile(_RS.REANIM_FAVS_FILE, game:GetService("HttpService"):JSONEncode(data))
			end)
		end
		_RS.savedFavsData = {}
		_RS.loadFavsData = function()
			pcall(function()
				if isfile and isfile(_RS.REANIM_FAVS_FILE) then
					local ok, data = pcall(function() return game:GetService("HttpService"):JSONDecode(readfile(_RS.REANIM_FAVS_FILE)) end)
					if ok and type(data)=="table" then _RS.savedFavsData = data end
				end
			end)
		end
		_RS.loadFavsData()
		_RS.saveStateAnims = function()
			pcall(function()
				if not isfolder("ROT") then makefolder("ROT") end
				local data = {}
				for slot, anim in pairs(_RS.stateAnims) do
					if anim and type(anim.name)=="string" and anim.name~="" then
						data[slot] = { name=anim.name, url=anim.url }
					end
				end
				writefile(_RS.REANIM_STATES_FILE, game:GetService("HttpService"):JSONEncode(data))
			end)
		end
		_RS.savedStatesData = {}
		_RS.loadStatesData = function()
			pcall(function()
				if isfile and isfile(_RS.REANIM_STATES_FILE) then
					local ok, data = pcall(function() return game:GetService("HttpService"):JSONDecode(readfile(_RS.REANIM_STATES_FILE)) end)
					if ok and type(data)=="table" then _RS.savedStatesData = data end
				end
			end)
		end
		_RS.loadStatesData()

		_RS.kbRefreshers       = {}
		_RS.reanimItems        = _RS.globalItems
		_RS.reanimCurrentName  = nil
		_RS.reanimLocalConn    = nil
		_RS.reanimLocalJoints  = nil
		_RS.reanimLocalOrigC0s = nil
		_RS.reanimGeneration   = 0
		_RS.activeTab          = "global"
		_RS.stateAnims         = { idle=nil, walk=nil, jump=nil }
		_RS.stateConn          = nil
		_RS.stateLastState     = nil
		_RS.manualOverride     = false
		_RS.REANIM_ROW_H       = 32

		_RS.reanimRefreshSearch = function()
			local q = _RS.reanimSearchBox.Text:lower()
			local yOff = 4
			for _, item in ipairs(_RS.reanimItems) do
				local visible = q=="" or item.name:lower():find(q, 1, true) ~= nil
				item.row.Visible = visible
				if visible then item.row.Position = UDim2.new(0, 4, 0, yOff) ; yOff = yOff + _RS.REANIM_ROW_H end
			end
			_RS.reanimScroll.CanvasSize = UDim2.new(0, 0, 0, yOff + 4)
		end
		_RS.hideAllRows = function()
			for _, item in ipairs(_RS.globalItems) do item.row.Visible = false end
			for _, item in ipairs(_RS.customItems) do item.row.Visible = false end
			for _, item in ipairs(_RS.favsItems)   do item.row.Visible = false end
		end
		_RS.setTab = function(tab)
			_RS.activeTab   = tab
			_RS.reanimItems = tab=="global" and _RS.globalItems or tab=="custom" and _RS.customItems
			               or tab=="favs" and _RS.favsItems or {}
			do
				local KEYS = {"global","custom","favs","states"}
				local BTNS = _RS.tabBtns
				local TI   = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
				for i, btn in ipairs(BTNS) do
					local a = KEYS[i] == tab
					btn.TextColor3 = a and C.TEXT or C.DIM
					if a then
						tween(tabPill, TI, {Position = UDim2.new(0.25*(i-1), 2, 0, 2), Size = UDim2.new(0.25, -4, 1, -4)})
					end
				end
			end
			local isStates = tab == "states"
			if isStates then
				if _RS.activeState == nil then
					_RS.activeState = "idle" ; _RS.stateIdleBtn.TextColor3 = C.TEXT
					_RS.stateWalkBtn.TextColor3 = C.SUB ; _RS.stateJumpBtn.TextColor3 = C.SUB
					tween(statesPill, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(0,2,0,2)})
				end
				if _RS.activeSubState == nil then
					_RS.activeSubState = "global" ; _RS.subStateGlobalBtn.TextColor3 = C.TEXT ; _RS.subStateCustomBtn.TextColor3 = C.SUB
					tween(subStatesPill, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(0,2,0,2)})
				end
				if _RS.statesSearchBox then _RS.statesSearchBox.Text = "" end
			else
				_RS.activeState = nil ; _RS.activeSubState = nil
				if _RS.statesSearchBox then _RS.statesSearchBox.Text = "" end
			end
			if _RS.repositionContent then _RS.repositionContent() end
			if not isStates then
				_RS.hideAllRows() ; _RS.reanimSearchBox.Text = ""
				if tab=="custom" and #_RS.customItems==0 then
					_RS.customLoadLbl.Visible = true ; _RS.reanimScroll.CanvasSize = UDim2.new(0,0,0,72)
				else
					_RS.customLoadLbl.Visible = false ; _RS.reanimRefreshSearch()
				end
				for _, it in ipairs(_RS.reanimItems) do
					it.nameLbl.TextColor3 = (it.name == _RS.reanimCurrentName) and C.ACCENT or C.TEXT
				end
			else
				local sub = _RS.activeSubState or "global"
				_RS.reanimItems = sub=="custom" and _RS.customItems or _RS.globalItems
				_RS.hideAllRows()
				if _RS.customLoadLbl then _RS.customLoadLbl.Visible = false end
				_RS.reanimRefreshSearch()
				if _RS.refreshStateHighlights then _RS.refreshStateHighlights() end
			end
		end
	end

	local function _logic()
		_RS.reanimSpeed = 1.0

		local function _parseJsonAnim(src, dispName)
			local ok, arr = pcall(function() return game:GetService("HttpService"):JSONDecode(src) end)
			if not ok or type(arr) ~= "table" then return nil end
			local kfs = {}
			for _, entry in ipairs(arr) do
				if type(entry)=="table" and type(entry.Time)=="number" and type(entry.Poses)=="table" then
					local data = {} ; local rootPos = nil
					for partName, poseInfo in pairs(entry.Poses) do
						if type(poseInfo)=="table" and type(poseInfo.CFrame)=="table" then
							local cf  = poseInfo.CFrame
							local pos = type(cf.Position)=="table" and cf.Position or {0,0,0}
							local ori = type(cf.Orientation)=="table" and cf.Orientation or {0,0,0}
							if partName == "LowerTorso" then
								rootPos = Vector3.new(pos[1] or 0, pos[2] or 0, pos[3] or 0)
								data[partName] = CFrame.fromOrientation(ori[1] or 0, ori[2] or 0, ori[3] or 0)
							else
								data[partName] = CFrame.new(pos[1] or 0, pos[2] or 0, pos[3] or 0)
									* CFrame.fromOrientation(ori[1] or 0, ori[2] or 0, ori[3] or 0)
							end
						end
					end
					kfs[#kfs+1] = { Time=entry.Time, Data=data, RootPos=rootPos }
				end
			end
			if #kfs == 0 then return nil end
			return { [dispName or "animation"] = kfs }
		end

		_RS.reanimPlayLocal = function(path)
			if not readfile then return false, "readfile not available" end
			local ok, src = pcall(readfile, path)
			if not ok then return false, "readfile failed: "..tostring(src) end
			local animData
			if path:match("%.json$") then
				local dispName = (path:match("[/\\]([^/\\]+)$") or path):gsub("%.[^%.]+$","")
				animData = _parseJsonAnim(src, dispName)
				if not animData then return false, "invalid JSON animation file" end
			else
				local fnOk, animFn = pcall(_safeLoadstring, src)
				if not fnOk or not animFn then return false, "loadstring failed" end
				local dataOk, data = pcall(animFn)
				if not dataOk or type(data)~="table" then return false, "script did not return a table" end
				animData = data
			end
			if not _G._reanimAPI then return false, "API not loaded" end
			_RS.reanimGeneration = _RS.reanimGeneration + 1
			local myGen = _RS.reanimGeneration
			if _RS.reanimLocalConn then _RS.reanimLocalConn:Disconnect() ; _RS.reanimLocalConn = nil end
			pcall(function() _G._reanimAPI.stop_animation() end)
			local player = game:GetService("Players").LocalPlayer
			local clone   = _G._reanimAPI.get_clone(player)
			if not clone then return false, "not reanimated" end
			_RS.reanimLocalJoints = nil ; _RS.reanimLocalOrigC0s = nil ; _RS.reanimLocalIsMotor6D = nil
			local animCtrl = clone:FindFirstChildOfClass("Humanoid") or clone:FindFirstChildOfClass("AnimationController")
			if animCtrl then
				local tracks = animCtrl:GetPlayingAnimationTracks()
				if tracks then for _, t in ipairs(tracks) do t:Stop() end end
			end
			local animScript = clone:FindFirstChild("Animate")
			if animScript then animScript.Enabled = false end
			local keyframes = animData[next(animData)]
			if not keyframes or #keyframes==0 then return false, "no keyframes" end
			if not _RS.reanimLocalOrigC0s then
				local joints, origC0s = {}, {}
				local hasMotor6D_L = false
				for _, d in ipairs(clone:GetDescendants()) do
					if d:IsA("Motor6D") and d.Part1 then
						hasMotor6D_L = true ; joints[d.Part1.Name] = d ; origC0s[d] = d.C0
					end
				end
				_RS.reanimLocalJoints = joints ; _RS.reanimLocalOrigC0s = origC0s ; _RS.reanimLocalIsMotor6D = hasMotor6D_L
			end
			if not _RS.reanimLocalIsMotor6D then
				_RS.reanimLocalACMap = _G._reanimAPI and _G._reanimAPI._buildACJointMap(clone) or nil
			else
				_RS.reanimLocalACMap = nil
			end
			local joints, origC0s = _RS.reanimLocalJoints, _RS.reanimLocalOrigC0s
			local totalDur = keyframes[#keyframes].Time
			if totalDur <= 0 then return false, "animation has zero or negative duration" end
			local elapsed  = 0
			local _localACAnimator = _RS.reanimLocalACMap and (function()
				local h = clone:FindFirstChildOfClass("Humanoid") or clone:FindFirstChildOfClass("AnimationController")
				return h and h:FindFirstChildOfClass("Animator")
			end)() or nil
			local _localEvent = _RS.reanimLocalACMap
				and game:GetService("RunService").PreSimulation
				or  game:GetService("RunService").Heartbeat
			local localConn
			localConn = _localEvent:Connect(LPH_NO_VIRTUALIZE(function(dt)
				if myGen ~= _RS.reanimGeneration then localConn:Disconnect() ; return end
				if totalDur > 0 then
					elapsed = (elapsed + dt * _RS.reanimSpeed) % totalDur
					local lo, hi = 1, #keyframes - 1
					while lo < hi do
						local mid = math.floor((lo + hi) / 2)
						if keyframes[mid + 1].Time <= elapsed then lo = mid + 1 else hi = mid end
					end
					local cf, nf
					if keyframes[lo] and keyframes[lo+1] and elapsed >= keyframes[lo].Time and elapsed < keyframes[lo+1].Time then
						cf = keyframes[lo] ; nf = keyframes[lo+1]
					else
						cf = keyframes[#keyframes] ; nf = keyframes[1]
					end
					local dur = nf.Time - cf.Time
					local alpha
					if dur <= 0 then
						local segLen = (totalDur - cf.Time) + nf.Time
						if segLen <= 0 then segLen = totalDur end
						local segElapsed = elapsed >= cf.Time and (elapsed - cf.Time) or (totalDur - cf.Time + elapsed)
						alpha = math.clamp(segElapsed / segLen, 0, 1)
					else
						alpha = math.clamp((elapsed - cf.Time) / dur, 0, 1)
					end
					if _RS.reanimLocalACMap then
						if _localACAnimator and _localACAnimator.EvaluationThrottled then return end
						local _hier = _G._reanimAPI and _G._reanimAPI._AC_HIERARCHY or {}
						for _, entry in ipairs(_hier) do
							local jd = _RS.reanimLocalACMap[entry.part]
							if jd and jd.constraint and jd.constraint.Parent then
								local poseCF = CFrame.identity
								if cf.Data and cf.Data[entry.part] then
									local p = cf.Data[entry.part] ; local np = nf.Data and nf.Data[entry.part]
									poseCF = np and p:Lerp(np, alpha) or p
								end
								jd.constraint.Transform = poseCF
							end
						end
					else
						for part, pose in pairs(cf.Data) do
							local motor = joints[part]
							if motor and origC0s[motor] then
								local np = nf.Data and nf.Data[part]
								motor.C0 = origC0s[motor] * (np and pose:Lerp(np, alpha) or pose)
							end
						end
					end
				else
					for part, pose in pairs(keyframes[1].Data) do
						local motor = joints[part]
						if motor and origC0s[motor] then motor.C0 = origC0s[motor] * pose end
					end
				end
			end))
			_RS.reanimLocalConn = localConn
			if _RS.reanimLocalAncConn then pcall(function() _RS.reanimLocalAncConn:Disconnect() end) ; _RS.reanimLocalAncConn = nil end
			_RS.reanimLocalAncConn = clone.AncestryChanged:Connect(function()
				if not clone:IsDescendantOf(game) then
					localConn:Disconnect()
					if _RS.reanimLocalConn == localConn then _RS.reanimLocalConn = nil end
					_RS.reanimLocalAncConn = nil
					pcall(function()
						if _RS.reanimLocalACMap then
							for _, jd in pairs(_RS.reanimLocalACMap) do
								if jd.constraint and jd.constraint.Parent then jd.constraint.Transform = CFrame.identity end
							end
						end
					end)
				end
			end)
			return true, localConn
		end

		local function _rawPlay(n, url, silent)
			if not _G._reanimAPI then return end
			_RS.reanimGeneration = _RS.reanimGeneration + 1
			local spawnGen = _RS.reanimGeneration
			if _RS.reanimLocalConn then _RS.reanimLocalConn:Disconnect() ; _RS.reanimLocalConn = nil end
			_RS.reanimCurrentName = n
			task.spawn(function()
				if _RS.reanimGeneration ~= spawnGen then return end
				if url:sub(1,4) ~= "http" then
					local ok, err = _RS.reanimPlayLocal(url)
					if not ok then notify("Reanim", "Failed: "..tostring(err)) end
				else
					pcall(function() _G._reanimAPI.stop_animation() end)
					local ok, err = pcall(function() _G._reanimAPI.play_animation(url, _RS.reanimSpeed) end)
					if not ok then notify("Reanim", "Failed: "..tostring(err)) end
				end
			end)
			if not silent then
				local function refreshColors(list)
					for _, it in ipairs(list) do it.nameLbl.TextColor3 = (it.name==n) and C.ACCENT or C.TEXT end
				end
				refreshColors(_RS.globalItems) ; refreshColors(_RS.customItems) ; refreshColors(_RS.favsItems)
				_RS.reanimStatusLbl.Text = "Playing: "..n:sub(1,22)
			end
		end

		local function reanimPlayByName(n, url)
			if not _G._reanimAPI then notify("Reanim","API not loaded yet") ; return end
			_RS.manualOverride = true ; _rawPlay(n, url)
		end

		local function reanimStopCurrent()
			_RS.reanimGeneration = _RS.reanimGeneration + 1
			if _RS.reanimLocalConn then _RS.reanimLocalConn:Disconnect() ; _RS.reanimLocalConn = nil end
			if _RS.reanimLocalJoints and _RS.reanimLocalOrigC0s then
				for _, motor in pairs(_RS.reanimLocalJoints) do
					if _RS.reanimLocalOrigC0s[motor] then pcall(function() motor.C0 = _RS.reanimLocalOrigC0s[motor] end) end
				end
				if _RS.reanimLocalACMap then
					local p2 = game:GetService("Players").LocalPlayer
					local c2 = _G._reanimAPI and _G._reanimAPI.get_clone(p2)
					if c2 and _G._reanimAPI then _G._reanimAPI._setACConstraints(c2, true) end
					_RS.reanimLocalACMap = nil
				end
				_RS.reanimLocalJoints = nil ; _RS.reanimLocalOrigC0s = nil
			end
			pcall(function()
				_G._reanimAPI.stop_animation()
				local hasStateAnims = _RS.stateAnims and (_RS.stateAnims.idle or _RS.stateAnims.walk or _RS.stateAnims.jump)
				if not hasStateAnims then
					local clone = _G._reanimAPI.get_clone()
					if clone then
						local animScript = clone:FindFirstChild("Animate")
						if animScript then animScript.Enabled = true end
					end
				end
			end)
			_RS.reanimCurrentName = nil ; _RS.manualOverride = false ; _RS.stateLastState = nil
			if _RS.startStateLoop then _RS.startStateLoop() end
			for _, it in ipairs(_RS.globalItems) do it.nameLbl.TextColor3 = C.TEXT end
			for _, it in ipairs(_RS.customItems) do it.nameLbl.TextColor3 = C.TEXT end
			for _, it in ipairs(_RS.favsItems)   do it.nameLbl.TextColor3 = C.TEXT end
			_RS.reanimStatusLbl.Text = "Idle"
			if _RS.reanimStatusDot then tween(_RS.reanimStatusDot, TweenInfo.new(0.2), {BackgroundColor3 = C.DIV}) end
		end

		local HST = Enum.HumanoidStateType
		local function getMovementSlot()
			if not _G._reanimAPI then return "idle" end
			local clone = _G._reanimAPI.get_clone()
			if not clone or not clone.Parent then return "idle" end
			local hum = clone:FindFirstChildOfClass("Humanoid")
			if not hum then return "idle" end
			local st = hum:GetState()
			if st == HST.Jumping or st == HST.Freefall then return "jump" end
			if hum.MoveDirection.Magnitude > 0.05 then return "walk" end
			return "idle"
		end

		local function stopStateLoop()
			if _RS.stateConn then _RS.stateConn:Disconnect() ; _RS.stateConn = nil end
			_RS.stateLastState = nil
		end

		local function startStateLoop()
			stopStateLoop()
			if not (_RS.stateAnims.idle or _RS.stateAnims.walk or _RS.stateAnims.jump) then return end
			_RS.stateConn = runService.Heartbeat:Connect(LPH_NO_VIRTUALIZE(function()
				if _RS.manualOverride then return end
				if not _G._reanimAPI or not _G._reanimAPI.is_reanimated() then return end
				local slot = getMovementSlot()
				if slot == _RS.stateLastState then return end
				_RS.stateLastState = slot
				local anim = _RS.stateAnims[slot]
				if not anim then
					_RS.reanimGeneration = _RS.reanimGeneration + 1
					pcall(function() _G._reanimAPI.stop_animation() end)
					if _RS.reanimLocalConn then _RS.reanimLocalConn:Disconnect() ; _RS.reanimLocalConn = nil end
					if _RS.reanimLocalJoints and _RS.reanimLocalOrigC0s then
						for _, motor in pairs(_RS.reanimLocalJoints) do
							if _RS.reanimLocalOrigC0s[motor] then pcall(function() motor.C0 = _RS.reanimLocalOrigC0s[motor] end) end
						end
						if _RS.reanimLocalACMap then
							local clone4 = _G._reanimAPI and _G._reanimAPI.get_clone()
							if clone4 and _G._reanimAPI then _G._reanimAPI._setACConstraints(clone4, true) end
							_RS.reanimLocalACMap = nil
						end
					end
					local clone = _G._reanimAPI.get_clone()
					if clone then
						local animScript = clone:FindFirstChild("Animate")
						if animScript then animScript.Enabled = true end
					end
					_RS.reanimCurrentName = nil ; _RS.reanimStatusLbl.Text = "Idle"
				else
					_rawPlay(anim.name, anim.url, true)
					_RS.reanimStatusLbl.Text = slot:sub(1,1):upper()..slot:sub(2)..": "..anim.name:sub(1,16)
				end
			end))
		end
		_RS.startStateLoop = startStateLoop ; _RS.stopStateLoop = stopStateLoop

		local SONGS_FOLDER = "ROT/Songs"
		local emoteSounds  = {}
		local emoteSound   = Instance.new("Sound")
		emoteSound.Volume  = 0.8 ; emoteSound.Looped = true ; emoteSound.Parent = game:GetService("SoundService")
		task.spawn(function()
			pcall(function()
				if not isfolder("ROT")   then makefolder("ROT")   end
				if not isfolder(SONGS_FOLDER) then makefolder(SONGS_FOLDER) end
			end)
			if not listfiles then return end
			local ok, files = pcall(listfiles, SONGS_FOLDER)
			if not ok or not files then return end
			for _, path in ipairs(files) do
				local ext = path:match("%.([^%.]+)$")
				if ext and (ext:lower()=="mp3" or ext:lower()=="ogg" or ext:lower()=="wav") then
					local fileName = path:match("[/\\]([^/\\]+)$") or path
					local name = fileName:gsub("%.([^%.]+)$",""):lower()
					if not emoteSounds[name] then pcall(function() emoteSounds[name] = getcustomasset(path) end) end
				end
			end
		end)
		local function playEmoteSound(animName)
			local assetId = emoteSounds[animName:lower()]
			if assetId and assetId ~= "" then
				emoteSound.SoundId = assetId ; emoteSound:Stop() ; emoteSound:Play()
			else emoteSound:Stop() end
		end
		local function stopEmoteSound() emoteSound:Stop() end
		local _origPlayByName = reanimPlayByName
		reanimPlayByName = function(n, url) _origPlayByName(n, url) ; playEmoteSound(n) end
		local _origStopCurrent = reanimStopCurrent
		reanimStopCurrent = function() _origStopCurrent() ; stopEmoteSound() end

		local function favSlotOf(n)
			for slot, b in pairs(_RS.favKeybinds) do if b.name==n then return slot end end
			return nil
		end
		local function applySavedReanimKeybind(name, animUrl)
			local keyName = _RS.savedReanimKeybinds[name]
			if type(keyName)~="string" or keyName=="" or keyName=="Unknown" then return end
			local prev = favSlotOf(name)
			if prev and prev ~= keyName then _RS.favKeybinds[prev] = nil end
			_RS.favKeybinds[keyName] = {name=name, url=animUrl}
		end
		_RS.loadReanimKeybinds()

		local function reanimAddItem(name, animUrl, itemList)
			local isFavTab = (itemList == _RS.favsItems)
			applySavedReanimKeybind(name, animUrl)
			local row = Instance.new("Frame", _RS.reanimScroll)
			row.BackgroundTransparency = 1 ; row.BorderSizePixel = 0
			row.Size = UDim2.new(1, -8, 0, _RS.REANIM_ROW_H - 4) ; row.Visible = false ; row.ZIndex = 153
			Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)
			local nameLbl = Instance.new("TextLabel", row)
			nameLbl.BackgroundTransparency = 1 ; nameLbl.Position = UDim2.new(0, 10, 0, 0)
			nameLbl.Size = UDim2.new(1, -68, 1, 0) ; nameLbl.Font = font ; nameLbl.TextSize = 12
			nameLbl.TextColor3 = C.TEXT ; nameLbl.TextXAlignment = Enum.TextXAlignment.Left
			nameLbl.TextTruncate = Enum.TextTruncate.AtEnd ; nameLbl.Text = name ; nameLbl.ZIndex = 154
			local kbBtn = Instance.new("TextButton", row)
			kbBtn.BackgroundTransparency = 1 ; kbBtn.AnchorPoint = Vector2.new(1, 0.5)
			kbBtn.Position = UDim2.new(1, -27, 0.5, 0) ; kbBtn.Size = UDim2.new(0, 28, 0, 16)
			kbBtn.Font = Enum.Font.GothamBold ; kbBtn.TextSize = 10 ; kbBtn.TextXAlignment = Enum.TextXAlignment.Right
			kbBtn.AutoButtonColor = false ; kbBtn.BorderSizePixel = 0 ; kbBtn.ZIndex = 162
			local bindActive = false ; local bindConn = nil
			local function refreshKbLbl()
				if bindActive then return end
				local slot = favSlotOf(name)
				kbBtn.Text = slot or "bind" ; kbBtn.TextColor3 = slot and C.ACCENT or C.DIM
			end
			refreshKbLbl()
			if not _RS.kbRefreshers[name] then _RS.kbRefreshers[name] = {} end
			local myRefIdx = #_RS.kbRefreshers[name] + 1
			_RS.kbRefreshers[name][myRefIdx] = refreshKbLbl
			local function refreshAllKb(n2)
				if _RS.kbRefreshers[n2] then for _, fn in pairs(_RS.kbRefreshers[n2]) do fn() end end
			end
			kbBtn.MouseButton1Click:Connect(function()
				if bindActive then return end
				bindActive = true ; kbBtn.Text = "..." ; kbBtn.TextColor3 = C.TEXT
				bindConn = userInputService.InputBegan:Connect(function(inp, gp)
					if gp then return end
					local kc = inp.KeyCode
					if kc==Enum.KeyCode.Backspace or kc==Enum.KeyCode.Delete then
						local slot = favSlotOf(name)
						if slot then _RS.favKeybinds[slot] = nil ; notify("Favs", name:sub(1,18).." unbound") end
						_RS.saveReanimKeybinds() ; bindActive=false ; bindConn:Disconnect() ; bindConn=nil ; refreshKbLbl() ; return
					end
					if kc==Enum.KeyCode.Escape then bindActive=false ; bindConn:Disconnect() ; bindConn=nil ; refreshKbLbl() ; return end
					if kc==Enum.KeyCode.Unknown then return end
					local kcName = kc.Name
					if _RS.favKeybinds[kcName] then refreshAllKb(_RS.favKeybinds[kcName].name) end
					local prev = favSlotOf(name) ; if prev then _RS.favKeybinds[prev] = nil end
					_RS.favKeybinds[kcName] = {name=name, url=animUrl}
					_RS.saveReanimKeybinds() ; bindActive=false ; bindConn:Disconnect() ; bindConn=nil
					refreshAllKb(name) ; notify("Favs", name:sub(1,18).." -> "..kcName)
				end)
			end)
			row.AncestryChanged:Connect(function()
				if not row.Parent then
					if _RS.kbRefreshers[name] then _RS.kbRefreshers[name][myRefIdx] = nil end
					if bindConn then bindConn:Disconnect() ; bindConn = nil end
				end
			end)
			local starBtn = Instance.new("ImageButton", row)
			starBtn.Size = UDim2.new(0, 18, 0, 18) ; starBtn.AnchorPoint = Vector2.new(1, 0.5)
			starBtn.Position = UDim2.new(1, -5, 0.5, 0) ; starBtn.BackgroundTransparency = 1
			starBtn.BorderSizePixel = 0 ; starBtn.Image = "rbxassetid://102437792716891"
			starBtn.AutoButtonColor = false ; starBtn.ZIndex = 162
			if isFavTab then
				starBtn.ImageColor3 = Color3.fromRGB(255, 200, 40)
				starBtn.MouseButton1Click:Connect(function()
					for i, it in ipairs(_RS.favsItems) do
						if it.name == name then
							local slot = favSlotOf(name) ; if slot then _RS.favKeybinds[slot] = nil end
							_RS.saveReanimKeybinds() ; if bindConn then bindConn:Disconnect() ; bindConn=nil end
							it.row:Destroy() ; table.remove(_RS.favsItems, i) ; _RS.saveFavsItems()
							refreshAllKb(name) ; notify("Favs","Removed: "..name:sub(1,24))
							if _RS.activeTab=="favs" then _RS.reanimRefreshSearch() end ; return
						end
					end
				end)
			else
				local function refreshStar()
					local inFavs = false
					for _, it in ipairs(_RS.favsItems) do if it.name==name then inFavs=true ; break end end
					starBtn.ImageColor3 = inFavs and Color3.fromRGB(255,200,40) or C.DIM
					starBtn.ImageTransparency = inFavs and 0 or 0.3
				end
				refreshStar()
				starBtn.MouseButton1Click:Connect(function()
					for i, it in ipairs(_RS.favsItems) do
						if it.name==name then
							local slot = favSlotOf(name) ; if slot then _RS.favKeybinds[slot]=nil end
							_RS.saveReanimKeybinds() ; it.row:Destroy() ; table.remove(_RS.favsItems,i)
							_RS.saveFavsItems() ; refreshStar() ; refreshAllKb(name) ; notify("Favs","Removed: "..name:sub(1,24)) ; return
						end
					end
					reanimAddItem(name, animUrl, _RS.favsItems) ; _RS.saveFavsItems() ; refreshStar()
					if _RS.activeTab=="favs" then _RS.reanimRefreshSearch() end
					notify("Favs","Added: "..name:sub(1,24))
				end)
			end
			local div = Instance.new("Frame", row)
			div.BackgroundColor3 = C.DIV ; div.BorderSizePixel = 0 ; div.AnchorPoint = Vector2.new(0,1)
			div.Position = UDim2.new(0,0,1,2) ; div.Size = UDim2.new(1,0,0,1) ; div.ZIndex = 154
			local hitbox = Instance.new("TextButton", row)
			hitbox.Text = "" ; hitbox.AutoButtonColor = false ; hitbox.BackgroundTransparency = 1
			hitbox.Size = UDim2.new(1,0,1,0) ; hitbox.ZIndex = 157
			hitbox.MouseEnter:Connect(function()
				sfx.hover() ; row.BackgroundColor3 = C.ACCENT
				tween(row, TweenInfo.new(0.15), {BackgroundTransparency = 0.85})
			end)
			hitbox.MouseLeave:Connect(function()
				tween(row, TweenInfo.new(0.2), {BackgroundTransparency = 1})
			end)
			hitbox.MouseButton1Click:Connect(function()
				if _RS.activeTab == "states" then
					local slot = _RS.activeState or "idle"
					local prev = _RS.stateAnims[slot]
					if prev and prev.name==name then
						_RS.stateAnims[slot] = nil ; notify("States", slot:sub(1,1):upper()..slot:sub(2).." cleared")
					else
						_RS.stateAnims[slot] = {name=name, url=animUrl}
						notify("States", slot:sub(1,1):upper()..slot:sub(2)..": "..name:sub(1,22))
					end
					if _RS.saveStateAnims then _RS.saveStateAnims() end
					if _RS.refreshStateHighlights then _RS.refreshStateHighlights() end
					_RS.manualOverride = false
					if _RS.startStateLoop then _RS.startStateLoop() end
					if not _RS.stateConn and _RS.reanimCurrentName then reanimStopCurrent() end
					return
				end
				if not _G._reanimAPI then notify("Reanim","API not loaded yet") ; return end
				if _RS.reanimCurrentName == name then reanimStopCurrent() else reanimPlayByName(name, animUrl) end
			end)
			itemList[#itemList+1] = {name=name, url=animUrl, row=row, nameLbl=nameLbl}
		end

		local globalLoadLbl = Instance.new("TextLabel", _RS.reanimScroll)
		globalLoadLbl.BackgroundTransparency = 1 ; globalLoadLbl.Position = UDim2.new(0,10,0,10)
		globalLoadLbl.Size = UDim2.new(1,-20,0,20) ; globalLoadLbl.Font = font ; globalLoadLbl.TextSize = 12
		globalLoadLbl.TextColor3 = C.SUB ; globalLoadLbl.Text = "Loading..." ; globalLoadLbl.ZIndex = 153
		_RS.reanimScroll.CanvasSize = UDim2.new(0,0,0,40)

		task.spawn(function()
			local ok, resp = pcall(function() return game:HttpGet("https://static.rawth.net/animations.lua") end)
			if not ok or not resp then globalLoadLbl.Text = "Failed to load list" ; return end
			local animTable
			local loadOk = pcall(function() animTable = _safeLoadstring(resp)() end)
			if not loadOk or type(animTable)~="table" then globalLoadLbl.Text = "Bad response" ; return end
			local names = {}
			for k in pairs(animTable) do names[#names+1] = k end
			table.sort(names, function(a,b) return a:lower()<b:lower() end)
			globalLoadLbl.Visible = false
			for _, n in ipairs(names) do
				local dispName = n:gsub("^[Ss][Hh][Aa][Rr][Pp]%s*/%s*",""):gsub("^[Pp][Oo][Oo][Dd][Ll][Ee]%s*/%s*","")
				reanimAddItem(dispName, animTable[n], _RS.globalItems)
			end
			if _RS.activeTab=="global" then _RS.reanimRefreshSearch() end
			if _RS.savedStatesData and next(_RS.savedStatesData) then
				for slot, entry in pairs(_RS.savedStatesData) do
					if (slot=="idle" or slot=="walk" or slot=="jump")
					and type(entry)=="table" and type(entry.name)=="string" and entry.name~="" then
						local url = entry.url
						if (not url or url=="") and animTable then
							for n2, u in pairs(animTable) do
								local disp = n2:gsub("^[Ss][Hh][Aa][Rr][Pp]%s*/%s*",""):gsub("^[Pp][Oo][Oo][Dd][Ll][Ee]%s*/%s*","")
								if disp==entry.name then url=u ; break end
							end
						end
						if url and url~="" then _RS.stateAnims[slot] = {name=entry.name, url=url} end
					end
				end
				if _RS.refreshStateHighlights then _RS.refreshStateHighlights() end
			end
			if #_RS.savedFavsData > 0 then
				for _, fav in ipairs(_RS.savedFavsData) do
					if type(fav.name)=="string" and fav.name~="" then
						local url = fav.url
						if (not url or url=="") and animTable then
							for n2, u in pairs(animTable) do
								local disp = n2:gsub("^[Ss][Hh][Aa][Rr][Pp]%s*/%s*",""):gsub("^[Pp][Oo][Oo][Dd][Ll][Ee]%s*/%s*","")
								if disp==fav.name then url=u ; break end
							end
						end
						if url and url~="" then
							local already = false
							for _, it in ipairs(_RS.favsItems) do if it.name==fav.name then already=true ; break end end
							if not already then reanimAddItem(fav.name, url, _RS.favsItems) end
						end
					end
				end
				if _RS.activeTab=="favs" then _RS.reanimRefreshSearch() end
			end
		end)

		_RS.customLoadLbl = Instance.new("TextLabel", _RS.reanimScroll)
		_RS.customLoadLbl.BackgroundTransparency = 1 ; _RS.customLoadLbl.AnchorPoint = Vector2.new(0.5,0)
		_RS.customLoadLbl.Position = UDim2.new(0.5,0,0,10) ; _RS.customLoadLbl.Size = UDim2.new(1,-20,0,0)
		_RS.customLoadLbl.AutomaticSize = Enum.AutomaticSize.Y ; _RS.customLoadLbl.Font = font ; _RS.customLoadLbl.TextSize = 12
		_RS.customLoadLbl.TextColor3 = C.SUB ; _RS.customLoadLbl.TextWrapped = true
		_RS.customLoadLbl.TextXAlignment = Enum.TextXAlignment.Center ; _RS.customLoadLbl.TextYAlignment = Enum.TextYAlignment.Top
		_RS.customLoadLbl.Text = "No custom animations found.\nAdd .lua, .txt, or .json files to:\nworkspace/ROT/custom/"
		_RS.customLoadLbl.Visible = false ; _RS.customLoadLbl.ZIndex = 153

		local function _reloadCustom()
			for _, it in ipairs(_RS.customItems) do it.row:Destroy() end
			table.clear(_RS.customItems)
			local folder = "ROT/custom"
			if isfolder and makefolder then
				if not isfolder("ROT") then makefolder("ROT") end
				if not isfolder("ROT/custom") then makefolder("ROT/custom") end
			end
			local files = {}
			if listfiles then
				local ok2, result = pcall(listfiles, folder)
				if ok2 and result then
					for _, path in ipairs(result) do
						if path:match("%.lua$") or path:match("%.txt$") or path:match("%.json$") then
							files[#files+1] = path
						end
					end
				end
			end
			if #files == 0 then
				if _RS.activeTab=="custom" then
					_RS.customLoadLbl.Visible = true ; _RS.reanimScroll.CanvasSize = UDim2.new(0,0,0,72)
				else
					_RS.customLoadLbl.Visible = false
				end
				return
			end
			_RS.customLoadLbl.Visible = false
			for _, path in ipairs(files) do
				local fileName = path:match("[/\\]([^/\\]+)$") or path
				local dispName = fileName:gsub("%.[^%.]+$","")
				local ok3, src = pcall(readfile, path)
				if ok3 and src then
					if path:match("%.json$") then
						local animData = _parseJsonAnim(src, dispName)
						if animData then reanimAddItem(next(animData) or dispName, path, _RS.customItems)
						else reanimAddItem(dispName.." (err)", path, _RS.customItems) end
					else
						local fnOk, animFn = pcall(_safeLoadstring, src)
						if fnOk and animFn then
							local dataOk, animData = pcall(animFn)
							local animName = (dataOk and type(animData)=="table" and next(animData)) or dispName
							reanimAddItem(animName, path, _RS.customItems)
						else reanimAddItem(dispName.." (err)", path, _RS.customItems) end
					end
				end
			end
			if _RS.activeTab=="custom" then _RS.reanimRefreshSearch() end
		end
		reloadCustom = _reloadCustom ; _reloadCustom()

		do
			local SLIDER_Y = 380 - 42 - 8
			makeSlider(_G._reanimPanel, SLIDER_Y, "speed", C.ACTION, 10, 1, 30, function(v)
				_RS.reanimSpeed = v * 0.1
				if _G._reanimAPI then pcall(function() _G._reanimAPI.set_animation_speed(_RS.reanimSpeed) end) end
			end, true)
		end

		_RS.setTab("global")
		_RS.reanimSearchBox:GetPropertyChangedSignal("Text"):Connect(_RS.reanimRefreshSearch)

		userInputService.InputBegan:Connect(function(inp, gp)
			if gp then return end
			local kcName = inp.KeyCode.Name
			if kcName=="Unknown" then return end
			local b = _RS.favKeybinds[kcName]
			if not b then return end
			if not _G._reanimAPI then notify("Reanim","API not loaded yet") ; return end
			if _RS.reanimCurrentName==b.name then reanimStopCurrent() else reanimPlayByName(b.name, b.url) end
		end)

		local _origStopCurrentForOverride = reanimStopCurrent
		reanimStopCurrent = function() _RS.manualOverride = false ; _origStopCurrentForOverride() end

		local reanimActive = false ; local reanimLastUsed = 0 ; local REANIM_COOLDOWN = 3

		_RS.reanimToggleBtn.MouseButton1Click:Connect(function()
			if not _G._reanimAPI then
				_G.loadReanimAPI(nil) ; notify("Reanim","Loading API, try again in a moment") ; return
			end
			local now = tick()
			local remaining = REANIM_COOLDOWN - (now - reanimLastUsed)
			if remaining > 0 then notify("Reanim", string.format("Wait %.1fs", remaining)) ; return end
			reanimLastUsed = now ; reanimActive = not reanimActive
			if reanimActive then
				local char = lp and lp.Character
				local hum  = char and char:FindFirstChildOfClass("Humanoid")
				if hum and hum.RigType == Enum.HumanoidRigType.R6 then
					notify("Reanim","Switch to R15 for best results")
				end
				pcall(function() _G._reanimAPI.reanimate(true) end)
				_RS.reanimToggleBtn.Text             = "Stop Reanim"
				_RS.reanimToggleBtn.BackgroundColor3 = Color3.fromRGB(230, 30, 30)
				_RS.reanimStatusLbl.Text             = "Status: Active"
				if _RS.reanimStatusDot then tween(_RS.reanimStatusDot, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(80, 210, 100)}) end
				notify("Reanim","Reanimated")
				_RS.manualOverride = false
				if _RS.startStateLoop then _RS.startStateLoop() end
			else
				_RS.reanimGeneration = _RS.reanimGeneration + 1
				if _RS.reanimLocalConn then _RS.reanimLocalConn:Disconnect() ; _RS.reanimLocalConn = nil end
				if _RS.reanimLocalJoints and _RS.reanimLocalOrigC0s then
					for _, motor in pairs(_RS.reanimLocalJoints) do
						if _RS.reanimLocalOrigC0s[motor] then pcall(function() motor.C0 = _RS.reanimLocalOrigC0s[motor] end) end
					end
					if _RS.reanimLocalACMap then
						local p3 = game:GetService("Players").LocalPlayer
						local c3 = _G._reanimAPI and _G._reanimAPI.get_clone(p3)
						if c3 and _G._reanimAPI then _G._reanimAPI._setACConstraints(c3, true) end
						_RS.reanimLocalACMap = nil
					end
					_RS.reanimLocalJoints = nil ; _RS.reanimLocalOrigC0s = nil
				end
				pcall(function() _G._reanimAPI.stop_animation() end)
				pcall(function() _G._reanimAPI.reanimate(false) end)
				_RS.manualOverride = false
				if _RS.stopStateLoop then _RS.stopStateLoop() end
				_RS.reanimToggleBtn.Text             = "Reanimate"
				_RS.reanimToggleBtn.BackgroundColor3 = C.ACTION
				_RS.reanimStatusLbl.Text             = "Status: Idle"
				_RS.reanimCurrentName = nil
				for _, it in ipairs(_RS.reanimItems) do it.nameLbl.TextColor3 = C.TEXT end
				notify("Reanim","Stopped")
			end
		end)

		local function _onReanimDeactivate()
			if not reanimActive then return end
			reanimActive = false ; _RS.reanimGeneration = _RS.reanimGeneration + 1
			if _RS.reanimLocalConn then _RS.reanimLocalConn:Disconnect() ; _RS.reanimLocalConn = nil end
			_RS.reanimLocalJoints = nil ; _RS.reanimLocalOrigC0s = nil ; _RS.manualOverride = false
			if _RS.stopStateLoop then _RS.stopStateLoop() end
			_RS.reanimToggleBtn.Text             = "Reanimate"
			_RS.reanimToggleBtn.BackgroundColor3 = C.ACTION
			_RS.reanimStatusLbl.Text             = "Idle"
			_RS.reanimCurrentName = nil
			if _RS.reanimStatusDot then tween(_RS.reanimStatusDot, TweenInfo.new(0.2), {BackgroundColor3 = C.DIV}) end
			for _, it in ipairs(_RS.globalItems) do it.nameLbl.TextColor3 = C.TEXT end
			for _, it in ipairs(_RS.customItems) do it.nameLbl.TextColor3 = C.TEXT end
			for _, it in ipairs(_RS.favsItems)   do it.nameLbl.TextColor3 = C.TEXT end
		end

		if _G._reanimAPI then _G._reanimAPI.on_deactivate(_onReanimDeactivate) end
		local _origLoadAPI = _G.loadReanimAPI
		_G.loadReanimAPI = function(cb)
			_origLoadAPI(function()
				if _G._reanimAPI then _G._reanimAPI.on_deactivate(_onReanimDeactivate) end
				if cb then cb() end
			end)
		end
	end

	_setup(); _logic()
end

_G.loadReanimAPI(function()
	_initReanimPanel()
	_G._reanimPanel.Visible = true
end)