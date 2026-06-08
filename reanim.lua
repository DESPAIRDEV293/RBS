local playersService = game:GetService("Players")
local workspaceService = game:GetService("Workspace")
local userInputService = game:GetService("UserInputService")
local runService = game:GetService("RunService")
local replicatedStorageService = game:GetService("ReplicatedStorage")
local tweenService = game:GetService("TweenService")
local localPlayer = playersService.LocalPlayer
local currentAnimationState = nil
local httpService = game:GetService("HttpService")
local isInitialized = false
local animationTrack = nil
local animationFolder = nil
local keyframeSequence = nil
local animationController = nil
local animationData = nil
local animationConfig = nil
local activeAnimations = {}
local loadedAnimations = {}
local animationStates = {}
local stateAnimations = {
	["idle"] = nil,
	["walking"] = nil,
	["jumping"] = nil
}
local stateAnimationsPath = "ak/state_animations.json"
local cachedAnimations = {}
local scaleSettings = {
	["heightScale"] = 1,
	["widthScale"] = 1
}
local animationCachePath = "ak/animation_list_cache.json"
_G.hiddenBodyParts = _G.hiddenBodyParts or {}
local hiddenBodyParts = _G.hiddenBodyParts
local bodyPartNames = {
	"Head",
	"UpperTorso",
	"LowerTorso",
	"LeftUpperArm",
	"LeftLowerArm",
	"LeftHand",
	"RightUpperArm",
	"RightLowerArm",
	"RightHand",
	"LeftUpperLeg",
	"LeftLowerLeg",
	"LeftFoot",
	"RightUpperLeg",
	"RightLowerLeg",
	"RightFoot",
	"Torso",
	"Left Arm",
	"Right Arm",
	"Left Leg",
	"Right Leg",
	"HumanoidRootPart"
}
local isRendering = false
local timeStep = 1
local lerpSpeed = 0.1
local isEnabled = true
local isPaused = false
local defaultOffsets = {
	["Head"] = Vector3.new(101, 3, -2152),
	["UpperTorso"] = Vector3.new(101, 3, -2150002),
	["LowerTorso"] = Vector3.new(101, 3, -2150002),
	["Torso"] = Vector3.new(101, 3, -2150002),
	["LeftUpperArm"] = Vector3.new(0, 3, 0),
	["LeftLowerArm"] = Vector3.new(0, 3, 0),
	["LeftHand"] = Vector3.new(0, 3, 0),
	["Left Arm"] = Vector3.new(0, 3, 0),
	["RightUpperArm"] = Vector3.new(999999, 3, 0),
	["RightLowerArm"] = Vector3.new(0, 3, 0),
	["RightHand"] = Vector3.new(0, 3, 0),
	["Right Arm"] = Vector3.new(999999, 3, 0),
	["LeftUpperLeg"] = Vector3.new(-10000000, 3, 25000000),
	["LeftLowerLeg"] = Vector3.new(-10000000, 3, -25000000),
	["LeftFoot"] = Vector3.new(0, 3, 0),
	["Left Leg"] = Vector3.new(-10000000, 3, 25000000),
	["RightUpperLeg"] = Vector3.new(10000000, 3, 25000000),
	["RightLowerLeg"] = Vector3.new(10000000, 3, -25000000),
	["RightFoot"] = Vector3.new(0, 3, 0),
	["Right Leg"] = Vector3.new(10000000, 3, 25000000)
}
local scaledOffsets = {
	["Head"] = Vector3.new(101, 1003, -2152),
	["UpperTorso"] = Vector3.new(101, 1015, -2150002),
	["LowerTorso"] = Vector3.new(101, 996.8, -2150002),
	["Torso"] = Vector3.new(101, 1015, -2150002),
	["LeftUpperArm"] = Vector3.new(0, 1000, 0),
	["LeftLowerArm"] = Vector3.new(0, 1000, 0),
	["LeftHand"] = Vector3.new(0, 1000, 0),
	["Left Arm"] = Vector3.new(0, 1000, 0),
	["RightUpperArm"] = Vector3.new(999999, 1000, 0),
	["RightLowerArm"] = Vector3.new(0, 1000, 0),
	["RightHand"] = Vector3.new(0, 1000, 0),
	["Right Arm"] = Vector3.new(999999, 1000, 0),
	["LeftUpperLeg"] = Vector3.new(-10000000, 1015, 25000000),
	["LeftLowerLeg"] = Vector3.new(-10000000, 1015, -25000000),
	["LeftFoot"] = Vector3.new(0, 1000, 0),
	["Left Leg"] = Vector3.new(-10000000, 1015, 25000000),
	["RightUpperLeg"] = Vector3.new(10000000, 1015, 25000000),
	["RightLowerLeg"] = Vector3.new(10000000, 1015, -25000000),
	["RightFoot"] = Vector3.new(0, 1000, 0),
	["Right Leg"] = Vector3.new(10000000, 1015, 25000000)
}
local eventListeners = {}
local connectionList = {}
local moduleDependencies = {}
local maxCacheSize = 3000
local validAttachments = {
	"Head",
	"UpperTorso",
	"LowerTorso",
	"LeftUpperArm",
	"LeftLowerArm",
	"LeftHand",
	"RightUpperArm",
	"RightLowerArm",
	"RightHand",
	"LeftUpperLeg",
	"LeftLowerLeg",
	"LeftFoot",
	"RightUpperLeg",
	"RightLowerLeg",
	"RightFoot"
}
local animationContext = {
	["isRunning"] = false,
	["currentId"] = nil,
	["keyframes"] = nil,
	["totalDuration"] = 0,
	["elapsedTime"] = 0,
	["speed"] = 1,
	["connection"] = nil
}
local animationQueue = {}
local pendingTasks = {}
local isUpdating = false
(function()
	-- upvalues: (ref) v_u_8, (ref) v_u_7
	local function getPlayerCharacter(player)
		-- upvalues: (ref) v_u_8
		if currentAnimationState then
			local rootPart = player:WaitForChild("HumanoidRootPart", 5)
			if rootPart then
				rootPart.CFrame = currentAnimationState
			end
			currentAnimationState = nil
		end
		local humanoid = player:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Died:Connect(function()
				-- upvalues: (ref) p_u_42, (ref) v_u_8
				local humanoidRootPart = player:FindFirstChild("HumanoidRootPart")
				if humanoidRootPart then
					currentAnimationState = humanoidRootPart.CFrame
				end
			end)
		end
	end
	if localPlayer.Character then
		getPlayerCharacter(localPlayer.Character)
	end
	localPlayer.CharacterAdded:Connect(getPlayerCharacter)
end)()
local characterAttachments = {}
local animationBindings = {}
local transformCache = {}
local animationConfigPath = "ak/custom_animations.json"
local speedKeybindConfigPath = "ak/speed_keybinds.json"
local animationData2 = {}
local function saveAnimationData()
	if not isfolder("ak") then
		makefolder("ak")
	end
end
local function loadSpeedKeybinds()
	-- upvalues: (ref) v_u_53, (ref) v_u_39, (ref) v_u_40, (ref) v_u_9, (ref) v_u_24
	saveAnimationData()
	local animationSaveData = {
		["animations"] = animationQueue,
		["order"] = pendingTasks,
		["timestamp"] = os.time()
	}
	local encodedAnimationData, isEncodeSuccess = pcall(httpService.JSONEncode, httpService, animationSaveData)
	if encodedAnimationData then
		pcall(function()
			-- upvalues: (ref) v_u_24, (ref) v_u_56
			writefile(animationCachePath, isEncodeSuccess)
		end)
	end
end
local function fetchAndExecuteRemoteScript()
	-- upvalues: (ref) v_u_53, (ref) v_u_24, (ref) v_u_9, (ref) v_u_39, (ref) v_u_40
	saveAnimationData()
	local readFileResult, rawFileContent = pcall(readfile, animationCachePath)
	if readFileResult then
		local decodeResult, decodedAnimationList = pcall(httpService.JSONDecode, httpService, rawFileContent)
		if decodeResult and (typeof(decodedAnimationList) == "table" and (decodedAnimationList.animations and decodedAnimationList.order)) then
			animationQueue = decodedAnimationList.animations
			pendingTasks = decodedAnimationList.order
			return true
		end
	end
	return false
end
local function updateFavoriteAnimations()
	-- upvalues: (ref) v_u_41, (ref) v_u_39, (ref) v_u_57
	if isUpdating then
		return
	else
		isUpdating = true
		local httpGetSuccess, remoteScriptSource = pcall(game.HttpGet, game, "https://absent.wtf/testanimlist.lua", true)
		if httpGetSuccess then
			local loadstringSuccess, remoteFunction = pcall(loadstring(remoteScriptSource))
			if loadstringSuccess and type(remoteFunction) == "table" then
				animationQueue = {}
				local animName, animData, animId = pairs(remoteFunction)
				while true do
					local isFavorite
					animId, isFavorite = animName(animData, animId)
					if animId == nil then
						break
					end
					animationQueue[animId] = isFavorite
				end
				loadSpeedKeybinds()
			end
		else
			return
		end
	end
end
local function saveFavoriteAnimations()
	-- upvalues: (ref) v_u_53, (ref) v_u_47, (ref) v_u_9
	saveAnimationData()
	local keybindName, keybindData, keybindValue = pairs(characterAttachments)
	local keybindConfigData = {}
	while true do
		local isKeybindSaved
		keybindValue, isKeybindSaved = keybindName(keybindData, keybindValue)
		if keybindValue == nil then
			break
		end
		keybindConfigData[keybindValue] = tostring(isKeybindSaved)
	end
	local encodedKeybindData, isKeybindEncodeSuccess = pcall(httpService.JSONEncode, httpService, keybindConfigData)
	if encodedKeybindData then
		pcall(function()
			-- upvalues: (ref) v_u_78
			writefile("ak/favorite_animations.json", isKeybindEncodeSuccess)
		end)
	end
end
local function loadAnimationKeybinds()
	-- upvalues: (ref) v_u_53, (ref) v_u_9, (ref) v_u_47, (ref) v_u_39, (ref) v_u_40
	saveAnimationData()
	local readFavoriteFileSuccess, rawFavoriteFileContent = pcall(readfile, "ak/favorite_animations.json")
	if readFavoriteFileSuccess then
		local decodeFavoriteResult, decodedFavoriteAnimations = pcall(httpService.JSONDecode, httpService, rawFavoriteFileContent)
		if decodeFavoriteResult and typeof(decodedFavoriteAnimations) == "table" then
			characterAttachments = {}
			local favoriteAnimName, favoriteAnimData, favoriteAnimId = pairs(decodedFavoriteAnimations)
			while true do
				local isAnimationFavorited
				favoriteAnimId, isAnimationFavorited = favoriteAnimName(favoriteAnimData, favoriteAnimId)
				if favoriteAnimId == nil then
					break
				end
				characterAttachments[favoriteAnimId] = isAnimationFavorited
				if not animationQueue[favoriteAnimId] then
					animationQueue[favoriteAnimId] = isAnimationFavorited
					if not table.find(pendingTasks, favoriteAnimId) then
						table.insert(pendingTasks, favoriteAnimId)
					end
				end
			end
		else
			characterAttachments = {}
		end
	else
		characterAttachments = {}
	end
end
local function applyAnimationKeybinds()
	-- upvalues: (ref) v_u_53, (ref) v_u_48, (ref) v_u_9
	saveAnimationData()
	local animKeyName, animKeyData, animKeyValue = pairs(animationBindings)
	local updatedKeybindConfig = {}
	while true do
		local isConfigApplied
		animKeyValue, isConfigApplied = animKeyName(animKeyData, animKeyValue)
		if animKeyValue == nil then
			break
		end
		updatedKeybindConfig[animKeyValue] = isConfigApplied.Name
	end
	local encodedAppliedKeybinds, isAppliedKeybindEncodeSuccess = pcall(httpService.JSONEncode, httpService, updatedKeybindConfig)
	if encodedAppliedKeybinds then
		pcall(function()
			-- upvalues: (ref) v_u_95
			writefile("ak/animation_keybinds.json", isAppliedKeybindEncodeSuccess)
		end)
	end
end
local function initializeAnimationSystem()
	-- upvalues: (ref) v_u_53, (ref) v_u_9, (ref) v_u_48
	saveAnimationData()
	local readKeybindFileSuccess, rawKeybindFileContent = pcall(readfile, "ak/animation_keybinds.json")
	if readKeybindFileSuccess then
		local jsonString, decodedData = pcall(httpService.JSONDecode, httpService, rawKeybindFileContent)
		if jsonString and typeof(decodedData) == "table" then
			animationBindings = {}
			local key, value, entry = pairs(decodedData)
			while true do
				local keyCodeName
				entry, keyCodeName = key(value, entry)
				if entry == nil then
					break
				end
				local keyCode = Enum.KeyCode[keyCodeName]
				if keyCode then
					animationBindings[entry] = keyCode
				end
			end
		else
			animationBindings = {}
		end
	else
		animationBindings = {}
	end
end
local function saveAnimationState()
	-- upvalues: (ref) v_u_53, (ref) v_u_52, (ref) v_u_9, (ref) v_u_51
	saveAnimationData()
	local animationData3 = {}
	for i = 1, 5 do
		if animationData2[i] then
			animationData3["slot" .. i] = {
				["speed"] = animationData2[i].speed or i * 2 - 1,
				["key"] = animationData2[i].key or ""
			}
		end
	end
	local encodedJson, jsonService = pcall(httpService.JSONEncode, httpService, animationData3)
	if encodedJson then
		pcall(function()
			-- upvalues: (ref) v_u_51, (ref) v_u_110
			writefile(speedKeybindConfigPath, jsonService)
		end)
	end
end
local function loadAnimationState()
	-- upvalues: (ref) v_u_53, (ref) v_u_51, (ref) v_u_9, (ref) v_u_52
	saveAnimationData()
	local fileContent, readResult = pcall(readfile, speedKeybindConfigPath)
	if fileContent then
		local parsedFileData, decodeSuccess = pcall(httpService.JSONDecode, httpService, readResult)
		if parsedFileData and typeof(decodeSuccess) == "table" then
			for slotIndex = 1, 5 do
				local slotKey = "slot" .. slotIndex
				if decodeSuccess[slotKey] then
					animationData2[slotIndex] = {
						["speed"] = decodeSuccess[slotKey].speed or slotIndex * 2 - 1,
						["key"] = decodeSuccess[slotKey].key or ""
					}
				end
			end
		end
	end
end
local function saveAnimationList()
	-- upvalues: (ref) v_u_53, (ref) v_u_20, (ref) v_u_9, (ref) v_u_21
	saveAnimationData()
	local animationStates2 = {
		["idle"] = stateAnimations.idle,
		["walking"] = stateAnimations.walking,
		["jumping"] = stateAnimations.jumping
	}
	local encodedAnimationJson, jsonEncodeSuccess = pcall(httpService.JSONEncode, httpService, animationStates2)
	if encodedAnimationJson then
		pcall(function()
			-- upvalues: (ref) v_u_21, (ref) v_u_121
			writefile(stateAnimationsPath, jsonEncodeSuccess)
		end)
	end
end
local function loadAnimationList()
	-- upvalues: (ref) v_u_53, (ref) v_u_21, (ref) v_u_9, (ref) v_u_20
	saveAnimationData()
	local fileContent2, readSuccess = pcall(readfile, stateAnimationsPath)
	if fileContent2 then
		local parsedAnimationData, decodeSuccess2 = pcall(httpService.JSONDecode, httpService, readSuccess)
		if parsedAnimationData and typeof(decodeSuccess2) == "table" then
			stateAnimations.idle = decodeSuccess2.idle
			stateAnimations.walking = decodeSuccess2.walking
			stateAnimations.jumping = decodeSuccess2.jumping
		end
	end
end
local function initializeGui()
	-- upvalues: (ref) v_u_53, (ref) v_u_49, (ref) v_u_9, (ref) v_u_50
	saveAnimationData()
	local guiKey, guiValue, guiEntry = pairs(transformCache)
	local guiElements = {}
	while true do
		local elementName
		guiEntry, elementName = guiKey(guiValue, guiEntry)
		if guiEntry == nil then
			break
		end
		guiElements[guiEntry] = elementName
	end
	local encodedGuiJson, jsonEncodeSuccess2 = pcall(httpService.JSONEncode, httpService, guiElements)
	if encodedGuiJson then
		pcall(function()
			-- upvalues: (ref) v_u_50, (ref) v_u_134
			writefile(animationConfigPath, jsonEncodeSuccess2)
		end)
	end
end
local function createAnimationTrack()
	-- upvalues: (ref) v_u_53, (ref) v_u_50, (ref) v_u_9, (ref) v_u_49, (ref) v_u_39, (ref) v_u_40
	saveAnimationData()
	local fileContent3, readSuccess2 = pcall(readfile, animationConfigPath)
	if fileContent3 then
		local parsedCacheData, decodeSuccess3 = pcall(httpService.JSONDecode, httpService, readSuccess2)
		if parsedCacheData and typeof(decodeSuccess3) == "table" then
			transformCache = {}
			local animName2, animInfo, animationEntry = pairs(decodeSuccess3)
			while true do
				local animationId
				animationEntry, animationId = animName2(animInfo, animationEntry)
				if animationEntry == nil then
					break
				end
				transformCache[animationEntry] = animationId
				animationQueue[animationEntry] = animationId
				if not table.find(pendingTasks, animationEntry) then
					table.insert(pendingTasks, animationEntry)
				end
			end
		else
			transformCache = {}
		end
	else
		transformCache = {}
	end
end
local function playAnimation()
	-- upvalues: (ref) v_u_53, (ref) v_u_62, (ref) v_u_106, (ref) v_u_88, (ref) v_u_144, (ref) v_u_127, (ref) v_u_118, (ref) v_u_24, (ref) v_u_71
	saveAnimationData()
	fetchAndExecuteRemoteScript()
	initializeAnimationSystem()
	loadAnimationKeybinds()
	createAnimationTrack()
	loadAnimationList()
	loadAnimationState()
	task.spawn(function()
		-- upvalues: (ref) v_u_24, (ref) v_u_71, (ref) v_u_144
		wait(2)
		if isfile(animationCachePath) then
			pcall(function()
				-- upvalues: (ref) v_u_24
				delfile(animationCachePath)
			end)
			print("Deleted old animation cache")
		end
		updateFavoriteAnimations()
		createAnimationTrack()
	end)
end
local animationController2 = {}
local function updateCharacterScale()
	-- upvalues: (ref) v_u_7, (ref) v_u_146
	local playerGui = localPlayer:FindFirstChildWhichIsA("PlayerGui")
	if playerGui then
		local guiObject, childPart, childIndex = ipairs(playerGui:GetChildren())
		while true do
			local childTable
			childIndex, childTable = guiObject(childPart, childIndex)
			if childIndex == nil then
				break
			end
			if childTable:IsA("ScreenGui") and childTable.ResetOnSpawn then
				table.insert(animationController2, childTable)
				childTable.ResetOnSpawn = false
			end
		end
	end
end
local function processCharacter()
	-- upvalues: (ref) v_u_146
	local boneName, boneIndex, boneList = ipairs(animationController2)
	while true do
		local boneData
		boneList, boneData = boneName(boneIndex, boneList)
		if boneList == nil then
			break
		end
		boneData.ResetOnSpawn = true
	end
	table.clear(animationController2)
end
local function updateAnimation()
	-- upvalues: (ref) v_u_12
	if animationFolder then
		local characterModel = animationFolder
		local descendant, descendantName, descendants = pairs(characterModel:GetDescendants())
		while true do
			local headPart
			descendants, headPart = descendant(descendantName, descendants)
			if descendants == nil then
				break
			end
			if headPart:IsA("BasePart") then
				headPart.Transparency = 1
			end
		end
		local headChild = animationFolder:FindFirstChild("Head")
		if headChild then
			local headChildIndex, headChildren, rootPart2 = ipairs(headChild:GetChildren())
			while true do
				local isMoving
				rootPart2, isMoving = headChildIndex(headChildren, rootPart2)
				if rootPart2 == nil then
					break
				end
				if isMoving:IsA("Decal") then
					isMoving.Transparency = 1
				end
			end
		end
	end
end
local function lerpTransform(hiddenBodyParts2)
	-- upvalues: (ref) v_u_10, (ref) v_u_11, (ref) v_u_12, (ref) v_u_26, (ref) v_u_34, (ref) v_u_33, (ref) v_u_37, (ref) v_u_35, (ref) v_u_36, (ref) v_u_29, (ref) v_u_28, (ref) v_u_27
	if not (isInitialized and (animationTrack and (animationTrack.Parent and (animationFolder and animationFolder.Parent)))) then
		return
	end
	if not isRendering then
		return
	end
	local rootPosition = animationFolder:FindFirstChild("HumanoidRootPart")
	if not rootPosition then
		return
	end
	if not connectionList then
		connectionList = {}
	end
	if not eventListeners then
		eventListeners = {}
	end
	local bonePath = validAttachments
	if #bonePath == 0 then
		return
	end
	local isVelocityActive = rootPosition.AssemblyLinearVelocity.Magnitude > 0.1
	if not moduleDependencies then
		moduleDependencies = {}
	end
	table.insert(moduleDependencies, 1, {
		["pos"] = rootPosition.Position,
		["rot"] = rootPosition.CFrame - rootPosition.Position
	})
	if maxCacheSize < #moduleDependencies then
		table.remove(moduleDependencies)
	end
	if isEnabled then
		local firstBoneName = bonePath[1]
		local currentPart = animationTrack:FindFirstChild(firstBoneName)
		if currentPart then
			if not connectionList[firstBoneName] then
				connectionList[firstBoneName] = currentPart.CFrame
			end
			if not eventListeners[firstBoneName] then
				eventListeners[firstBoneName] = currentPart.CFrame
			end
			if isVelocityActive then
				local currentPosition = rootPosition.Position
				local rootCFrame = rootPosition.CFrame - rootPosition.Position
				connectionList[firstBoneName] = CFrame.new(currentPosition) * rootCFrame
			end
			local lerpPosition = eventListeners[firstBoneName]:Lerp(connectionList[firstBoneName], lerpSpeed)
			currentPart.CFrame = lerpPosition
			currentPart.AssemblyLinearVelocity = Vector3.zero
			currentPart.AssemblyAngularVelocity = Vector3.zero
			eventListeners[firstBoneName] = lerpPosition
			for boneStep = 2, #bonePath do
				local currentBoneName = bonePath[boneStep]
				local targetPart = animationTrack:FindFirstChild(currentBoneName)
				local previousPart = animationTrack:FindFirstChild(bonePath[boneStep - 1])
				if targetPart then
					if previousPart then
						if not connectionList[currentBoneName] then
							connectionList[currentBoneName] = targetPart.CFrame
						end
						if not eventListeners[currentBoneName] then
							eventListeners[currentBoneName] = targetPart.CFrame
						end
						if isVelocityActive then
							local previousPosition = previousPart.Position
							local previousCFrame = previousPart.CFrame - previousPart.Position
							local positionOffset
							if boneStep == 2 then
								positionOffset = (previousPosition - rootPosition.Position).Unit
							else
								local anchorPart = animationTrack:FindFirstChild(bonePath[boneStep - 2])
								if anchorPart then
									positionOffset = (previousPosition - anchorPart.Position).Unit
								else
									positionOffset = previousCFrame.LookVector
								end
							end
							if positionOffset.Magnitude < 0.1 then
								positionOffset = previousCFrame.LookVector
							end
							local calculatedPosition = previousPosition + positionOffset * timeStep
							connectionList[currentBoneName] = CFrame.new(calculatedPosition) * previousCFrame
						end
						local lerpValue = eventListeners[currentBoneName]:Lerp(connectionList[currentBoneName], lerpSpeed)
						targetPart.CFrame = lerpValue
						targetPart.AssemblyLinearVelocity = Vector3.zero
						targetPart.AssemblyAngularVelocity = Vector3.zero
						eventListeners[currentBoneName] = lerpValue
					end
				end
			end
		end
	else
		local animationCount = #moduleDependencies
		local zeroVector = { 0 }
		for animIndex = 2, v187 do
			zeroVector[animIndex] = zeroVector[animIndex - 1] + (moduleDependencies[animIndex - 1].pos - moduleDependencies[animIndex].pos).Magnitude
		end
		for boneLoopIndex = 1, #bonePath do
			local loopBoneName = bonePath[boneLoopIndex]
			local loopPart = animationTrack:FindFirstChild(loopBoneName)
			if loopPart then
				local timeOffset = (boneLoopIndex - 1) * timeStep
				local currentIndex = boneLoopIndex
				local tempHolder = nil
				for i2 = 2, v187 do
					if timeOffset <= zeroVector[i2] then
						tempHolder = i2
						break
					end
				end
				local j
				if tempHolder and (moduleDependencies[tempHolder] and moduleDependencies[tempHolder - 1]) then
					local previousTime = zeroVector[tempHolder - 1]
					local currentTime = zeroVector[tempHolder]
					local lerpAlpha = (timeOffset - previousTime) / math.max(1e-6, currentTime - previousTime)
					local previousPosition2 = moduleDependencies[tempHolder - 1].pos
					local currentPosition2 = moduleDependencies[tempHolder].pos
					local previousRotation = moduleDependencies[tempHolder - 1].rot
					local interpolatedPosition = previousPosition2:Lerp(currentPosition2, lerpAlpha)
					local interpolatedCFrame = CFrame.new(interpolatedPosition) * previousRotation
					if not eventListeners[loopBoneName] then
						eventListeners[loopBoneName] = loopPart.CFrame
					end
					if not connectionList[loopBoneName] then
						connectionList[loopBoneName] = loopPart.CFrame
					end
					connectionList[loopBoneName] = interpolatedCFrame
					local interpolatedAttachment = eventListeners[loopBoneName]:Lerp(connectionList[loopBoneName], lerpSpeed)
					loopPart.CFrame = interpolatedAttachment
					loopPart.AssemblyLinearVelocity = Vector3.zero
					loopPart.AssemblyAngularVelocity = Vector3.zero
					eventListeners[loopBoneName] = interpolatedAttachment
					j = currentIndex
				else
					local cameraCFrame = rootPosition.CFrame
					local rayOrigin = cameraCFrame + cameraCFrame.LookVector * (-(j - 1) * timeStep)
					loopPart.CFrame = rayOrigin
					eventListeners[loopBoneName] = rayOrigin
					j = currentIndex
				end
			end
		end
	end
end
local function updateCharacter(player2)
	-- upvalues: (ref) v_u_10, (ref) v_u_11, (ref) v_u_12, (ref) v_u_26, (ref) v_u_209, (ref) v_u_31, (ref) v_u_30, (ref) v_u_32, (ref) v_u_25, (ref) v_u_23, (ref) v_u_16
	if isInitialized and (animationTrack and (animationTrack.Parent and (animationFolder and animationFolder.Parent))) then
		if isRendering then
			lerpTransform(player2)
			return
		elseif groundModeEnabled then
			local partName, offset, characterPart = pairs(defaultOffsets)
			while true do
				local characterModel2
				characterPart, characterModel2 = partName(offset, characterPart)
				if characterPart == nil then
					break
				end
				local characterPartInstance = animationTrack:FindFirstChild(characterPart)
				if characterPartInstance and characterPartInstance:IsA("BasePart") then
					characterPartInstance.CFrame = CFrame.new(characterModel2)
					characterPartInstance.AssemblyLinearVelocity = Vector3.zero
					characterPartInstance.AssemblyAngularVelocity = Vector3.zero
				end
			end
			return
		elseif isPaused then
			local attachmentName, attachment, worldModel = pairs(scaledOffsets)
			while true do
				local worldModelInstance
				worldModel, worldModelInstance = attachmentName(attachment, worldModel)
				if worldModel == nil then
					break
				end
				local worldPartInstance = animationTrack:FindFirstChild(worldModel)
				if worldPartInstance and worldPartInstance:IsA("BasePart") then
					worldPartInstance.CFrame = CFrame.new(worldModelInstance)
					worldPartInstance.AssemblyLinearVelocity = Vector3.zero
					worldPartInstance.AssemblyAngularVelocity = Vector3.zero
				end
			end
		else
			local boneName2, boneIndex2, bone = ipairs(bodyPartNames)
			while true do
				local characterBone
				bone, characterBone = boneName2(boneIndex2, bone)
				if bone == nil then
					break
				end
				local worldBone = animationTrack:FindFirstChild(characterBone)
				local characterHumanoid = animationFolder:FindFirstChild(characterBone)
				if worldBone and characterHumanoid then
					if _G.hiddenBodyParts[characterBone] then
						if not _G.hiddenBodyPartPositions then
							_G.hiddenBodyPartPositions = {}
						end
						if not _G.hiddenBodyPartPositions[characterBone] then
							local gravityForce = Vector3.new(0, -500, 0)
							local baseCFrame = worldBone.CFrame - worldBone.Position
							_G.hiddenBodyPartPositions[characterBone] = CFrame.new(gravityForce) * baseCFrame
						end
						worldBone.CFrame = _G.hiddenBodyPartPositions[characterBone]
					else
						if _G.hiddenBodyPartPositions then
							_G.hiddenBodyPartPositions[characterBone] = nil
						end
						worldBone.Anchored = false
						worldBone.CFrame = characterHumanoid.CFrame
					end
					worldBone.AssemblyLinearVelocity = Vector3.zero
					worldBone.AssemblyAngularVelocity = Vector3.zero
				end
			end
			local worldHumanoid = animationFolder:FindFirstChildWhichIsA("Humanoid")
			if worldHumanoid and (scaleSettings.heightScale ~= 1 or scaleSettings.widthScale ~= 1) then
				local halfHeight = animationConfig * scaleSettings.heightScale - 0.5
				worldHumanoid.HipHeight = math.max(halfHeight, 0.2)
			end
		end
	else
		return
	end
end
local function applyAnimation()
	-- upvalues: (ref) v_u_10, (ref) v_u_12, (ref) v_u_16, (ref) v_u_23, (ref) v_u_17, (ref) v_u_18
	if isInitialized and animationFolder then
		local targetHumanoid = animationFolder:FindFirstChildWhichIsA("Humanoid")
		if targetHumanoid then
			local scaledHalfHeight = animationConfig * scaleSettings.heightScale - 0.5
			targetHumanoid.HipHeight = math.max(scaledHalfHeight, 0.2)
			local attachmentPoint, c0Transform, partAttachment = pairs(activeAnimations)
			while true do
				local worldAttachment
				partAttachment, worldAttachment = attachmentPoint(c0Transform, partAttachment)
				if partAttachment == nil then
					break
				end
				if partAttachment and partAttachment:IsA("BasePart") then
					partAttachment.Size = Vector3.new(worldAttachment.X * scaleSettings.widthScale, worldAttachment.Y * scaleSettings.heightScale, worldAttachment.Z * scaleSettings.widthScale)
				end
			end
			local worldAttachmentName, worldCFrame, worldAttachmentPoint = pairs(loadedAnimations)
			while true do
				local jointInstance
				worldAttachmentPoint, jointInstance = worldAttachmentName(worldCFrame, worldAttachmentPoint)
				if worldAttachmentPoint == nil then
					break
				end
				if worldAttachmentPoint and worldAttachmentPoint:IsA("Motor6D") then
					local c0Position = jointInstance.C0.Position
					local scaledC0Position = Vector3.new(c0Position.X * scaleSettings.widthScale, c0Position.Y * scaleSettings.heightScale, c0Position.Z * scaleSettings.widthScale)
					worldAttachmentPoint.C0 = CFrame.new(scaledC0Position) * (jointInstance.C0 - jointInstance.C0.Position)
					local c1Position = jointInstance.C1.Position
					local scaledC1Position = Vector3.new(c1Position.X * scaleSettings.widthScale, c1Position.Y * scaleSettings.heightScale, c1Position.Z * scaleSettings.widthScale)
					worldAttachmentPoint.C1 = CFrame.new(scaledC1Position) * (jointInstance.C1 - jointInstance.C1.Position)
				end
			end
		end
	else
		return
	end
end
local function renderStepHandler()
	-- upvalues: (ref) v_u_2, (ref) v_u_7
	pcall(function()
		-- upvalues: (ref) v_u_2, (ref) v_u_7
		local virtualModel = workspaceService:FindFirstChild("VirtuallyNad")
		if virtualModel then
			local headMovementAttachment = virtualModel:FindFirstChild("HeadMovement")
			if headMovementAttachment and headMovementAttachment:IsA("LocalScript") then
				headMovementAttachment.Disabled = true
			end
		end
		localPlayer:SetAttribute("TurnHead", false)
	end)
end
local function virtualNadPart()
	-- upvalues: (ref) v_u_2
	pcall(function()
		-- upvalues: (ref) v_u_2
		local virtuallyNadPart = workspaceService:FindFirstChild("VirtuallyNad")
		if virtuallyNadPart then
			local headMovementAttachment2 = virtuallyNadPart:FindFirstChild("HeadMovement")
			if headMovementAttachment2 and headMovementAttachment2:IsA("LocalScript") then
				headMovementAttachment2.Disabled = false
			end
		end
	end)
end
local ragdollEvent = nil
local function ragdollModule(player3)
	-- upvalues: (ref) v_u_10, (ref) v_u_5, (ref) v_u_7, (ref) v_u_11, (ref) v_u_13, (ref) v_u_12, (ref) v_u_16, (ref) v_u_23, (ref) v_u_168, (ref) v_u_17, (ref) v_u_18, (ref) v_u_14, (ref) v_u_152, (ref) v_u_2, (ref) v_u_157, (ref) v_u_249, (ref) v_u_15, (ref) v_u_4, (ref) v_u_231, (ref) v_u_22, (ref) v_u_38, (ref) v_u_252, (ref) v_u_253
	isInitialized = player3
	local ragdollEvent2 = game:GetService("ReplicatedStorage"):FindFirstChild("event_rag")
	local ragdollRemote = game:GetService("ReplicatedStorage"):FindFirstChild("Ragdoll")
	local unragdollRemote = game:GetService("ReplicatedStorage"):FindFirstChild("Unragdoll")
	local localModulesFolder = nil
	if not (ragdollEvent2 or ragdollRemote) then
		local localModulesFolder3, backendModule3 = pcall(function()
			-- upvalues: (ref) v_u_5
			local localModulesFolder2 = replicatedStorageService:FindFirstChild("LocalModules", true)
			local backendModule = localModulesFolder2 and localModulesFolder2:FindFirstChild("Backend")
			if backendModule then
				local hiddenBodyParts3 = require
				local backendModule2 = backendModule.FindFirstChild
			end
		end)
		localModulesFolder = localModulesFolder3 and backendModule3 and backendModule3 or localModulesFolder
	end
	if isInitialized then
		local character = localPlayer.Character
		if not character then
			return
		end
		local humanoid2 = character:FindFirstChildOfClass("Humanoid")
		local rootPart3 = character:FindFirstChild("HumanoidRootPart")
		if not (humanoid2 and rootPart3) then
			return
		end
		animationTrack = character
		keyframeSequence = rootPart3.CFrame
		character.Archivable = true
		animationFolder = character:Clone()
		character.Archivable = false
		local playerName = animationTrack.Name
		animationFolder.Name = playerName .. "Celeste"
		local targetHumanoid2 = animationFolder:FindFirstChildWhichIsA("Humanoid")
		if targetHumanoid2 then
			targetHumanoid2.DisplayName = playerName .. "Celeste"
			animationConfig = targetHumanoid2.HipHeight
			scaleSettings = {
				["heightScale"] = 1,
				["widthScale"] = 1
			}
			targetHumanoid2.WalkSpeed = humanoid2.WalkSpeed
			targetHumanoid2.JumpPower = humanoid2.JumpPower
		end
		local targetRootPart = not animationFolder.PrimaryPart and animationFolder:FindFirstChild("HumanoidRootPart")
		if targetRootPart then
			animationFolder.PrimaryPart = targetRootPart
		end
		updateAnimation()
		activeAnimations = {}
		loadedAnimations = {}
		local targetModel = animationFolder
		local descendant2, descendant3, descendant4 = ipairs(targetModel:GetDescendants())
		while true do
			local animateController
			descendant4, animateController = descendant2(descendant3, descendant4)
			if descendant4 == nil then
				break
			end
			if animateController:IsA("BasePart") then
				activeAnimations[animateController] = animateController.Size
			elseif animateController:IsA("Motor6D") then
				loadedAnimations[animateController] = {
					["C0"] = animateController.C0,
					["C1"] = animateController.C1
				}
			end
		end
		local animateController2 = animationTrack:FindFirstChild("Animate")
		if animateController2 then
			animationController = animateController2:Clone()
			animationController.Parent = animationFolder
			animationController.Disabled = true
		end
		updateCharacterScale()
		animationFolder.Parent = workspaceService
		localPlayer.Character = animationFolder
		if targetHumanoid2 then
			workspaceService.CurrentCamera.CameraSubject = targetHumanoid2
		end
		processCharacter()
		if animationController then
			animationController.Disabled = false
		end
		if targetHumanoid2 then
			targetHumanoid2:ChangeState(Enum.HumanoidStateType.Running)
		end
		task.spawn(function()
			-- upvalues: (ref) v_u_10, (ref) v_u_255, (ref) v_u_11, (ref) v_u_256, (ref) v_u_258, (ref) v_u_249, (ref) v_u_15, (ref) v_u_4, (ref) v_u_231
			if isInitialized then
				if ragdollEvent2 then
					pcall(function()
						-- upvalues: (ref) v_u_11
						local ragdollEvent3 = game:GetService("ReplicatedStorage"):FindFirstChild("event_rag")
						if ragdollEvent3 then
							local playerHumanoid = animationTrack and (animationTrack:FindFirstChildOfClass("Humanoid") and animationTrack:FindFirstChildOfClass("Humanoid"))
							if playerHumanoid then
								game.Players.LocalPlayer.Character.Humanoid.HipHeight = playerHumanoid.HipHeight
							end
							ragdollEvent3:FireServer(unpack({ "Hinge" }))
						end
					end)
				elseif ragdollRemote then
					pcall(function()
						local ragdollRemote2 = game:GetService("ReplicatedStorage"):FindFirstChild("Ragdoll")
						if ragdollRemote2 then
							ragdollRemote2:FireServer(unpack({ "Ball" }))
						end
					end)
				elseif localModulesFolder then
					pcall(function()
						-- upvalues: (ref) v_u_258, (ref) v_u_249
						localModulesFolder.Ragdoll:Fire(true)
						renderStepHandler()
					end)
				end
				if animationData then
					animationData:Disconnect()
				end
				animationData = runService.Heartbeat:Connect(updateCharacter)
			end
		end)
	else
		local key2, value2, entry2 = pairs(cachedAnimations)
		while true do
			local connection
			entry2, connection = key2(value2, entry2)
			if entry2 == nil then
				break
			end
			if connection then
				connection:Disconnect()
			end
		end
		cachedAnimations = {}
		if animationData then
			animationData:Disconnect()
			animationData = nil
		end
		if animationContext.connection then
			animationContext.connection:Disconnect()
			animationContext.connection = nil
		end
		animationContext.isRunning = false
		if not (animationTrack and animationFolder) then
			return
		end
		for index = 1, 3 do
			pcall(function()
				-- upvalues: (ref) v_u_255, (ref) v_u_257, (ref) v_u_258, (ref) v_u_252
				if ragdollEvent2 then
					local ragdollEvent4 = game:GetService("ReplicatedStorage"):FindFirstChild("event_rag")
					if ragdollEvent4 then
						ragdollEvent4:FireServer(unpack({ "Hinge" }))
					end
				elseif unragdollRemote then
					local unragdollRemote2 = game:GetService("ReplicatedStorage"):FindFirstChild("Unragdoll")
					if unragdollRemote2 then
						unragdollRemote2:FireServer()
					end
				elseif localModulesFolder then
					localModulesFolder.Ragdoll:Fire(false)
					virtualNadPart()
				end
			end)
			task.wait(0.1)
		end
		local localRootPart = animationTrack:FindFirstChild("HumanoidRootPart")
		local targetRootPart2 = animationFolder:FindFirstChild("HumanoidRootPart")
		local targetCFrame = targetRootPart2 and targetRootPart2.CFrame or keyframeSequence
		local targetAnimateController = animationFolder:FindFirstChild("Animate")
		if targetAnimateController then
			targetAnimateController.Parent = animationTrack
			targetAnimateController.Disabled = true
		end
		animationFolder:Destroy()
		if localRootPart then
			localRootPart.CFrame = targetCFrame
		end
		local localHumanoid = animationTrack:FindFirstChildWhichIsA("Humanoid")
		updateCharacterScale()
		localPlayer.Character = animationTrack
		if localHumanoid then
			workspaceService.CurrentCamera.CameraSubject = localHumanoid
		end
		processCharacter()
		if targetAnimateController then
			task.wait(0.1)
			targetAnimateController.Disabled = false
		end
		ragdollEvent = nil
	end
end
local eventListeners2 = {}
local function animationModule()
	-- upvalues: (ref) v_u_38, (ref) v_u_12, (ref) v_u_18, (ref) v_u_14, (ref) v_u_290
	animationContext.isRunning = false
	if animationFolder then
		local key3, value3, entry3 = pairs(loadedAnimations)
		while true do
			local module
			entry3, module = key3(value3, entry3)
			if entry3 == nil then
				break
			end
			if entry3 and entry3:IsA("Motor6D") then
				entry3.C0 = module.C0
			end
		end
		local playerCharacter = animationFolder
		local part, child, childName = pairs(playerCharacter:GetChildren())
		while true do
			local targetPosition
			childName, targetPosition = part(child, childName)
			if childName == nil then
				break
			end
			if targetPosition:IsA("LocalScript") and (not targetPosition.Enabled and targetPosition ~= animationController) then
				targetPosition.Enabled = true
			end
		end
		if animationController then
			animationController.Disabled = false
		end
	end
	if animationContext.connection then
		animationContext.connection:Disconnect()
		animationContext.connection = nil
	end
	local animKey, animValue, animTrack = pairs(eventListeners2)
	while true do
		local requestSuccess
		animTrack, requestSuccess = animKey(animValue, animTrack)
		if animTrack == nil then
			break
		end
		requestSuccess.NameButton.BackgroundColor3 = Color3.new(0, 0, 0)
	end
end
local function decodedResponse(url)
	-- upvalues: (ref) v_u_12, (ref) v_u_38, (ref) v_u_304, (ref) v_u_290, (ref) v_u_39, (ref) v_u_47, (ref) v_u_14, (ref) v_u_19, (ref) v_u_18, (ref) v_u_4, (ref) v_u_23
	if not animationFolder then
		warn("Reanimate first!")
		return
	end
	if url == "" then
		return
	end
	local humanoid3 = animationFolder:FindFirstChildWhichIsA("Humanoid")
	if not humanoid3 then
		return
	end
	local hasLowerTorso = animationFolder:FindFirstChild("LowerTorso") ~= nil
	if not (hasLowerTorso and animationFolder:FindFirstChild("LowerTorso") or animationFolder:FindFirstChild("Torso")) then
		return
	end
	if animationContext.isRunning and animationContext.currentId == url then
		animationModule()
		animationContext.currentId = nil
		return
	end
	local trackKey, trackValue, track = pairs(eventListeners2)
	while true do
		local animationData4
		track, animationData4 = trackKey(trackValue, track)
		if track == nil then
			break
		end
		animationData4.NameButton.BackgroundColor3 = Color3.new(0, 0, 0)
	end
	local animationList = { animationQueue, characterAttachments }
	local animName3, animUrl, animEntry = pairs(animationList)
	local currentAnimation = nil
	while true do
		local bodyParts
		animEntry, bodyParts = animName3(animUrl, animEntry)
		if animEntry == nil then
			v320 = currentAnimation
		end
		local partName2, partValue, partObj = pairs(bodyParts)
		while true do
			local playingTracks
			partObj, playingTracks = partName2(partValue, partObj)
			if partObj == nil then
				partObj = currentAnimation
				break
			end
			if tostring(playingTracks) == url then
				break
			end
		end
		if partObj then
			break
		end
		currentAnimation = partObj
	end
	if v320 and eventListeners2[v320] then
		eventListeners2[v320].NameButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
	end
	if animationController and (humanoid3.MoveDirection.Magnitude > 0 or humanoid3:GetState() == Enum.HumanoidStateType.Running) then
		animationController.Disabled = true
		local track2, trackName, trackObj = pairs(humanoid3:GetPlayingAnimationTracks())
		while true do
			local httpResponse
			trackObj, httpResponse = track2(trackName, trackObj)
			if trackObj == nil then
				break
			end
			httpResponse:Stop()
		end
	end
	local animationUrlMap = animationStates[url]
	if not animationUrlMap then
		local isRequestSuccessful = nil
		local rawResponse = nil
		if tostring(url):match("^http") then
			local httpRequestUrl, httpResult = pcall(function()
				-- upvalues: (ref) p_u_305
				return game:HttpGet(url)
			end)
			if httpRequestUrl then
				local jsonSuccess
				jsonSuccess, animationUrlMap = pcall(function()
					-- upvalues: (ref) v_u_330
					return loadstring(httpResult)()
				end)
				if jsonSuccess and type(animationUrlMap) == "table" then
					isRequestSuccessful = true
				else
					animationUrlMap = rawResponse
				end
			else
				animationUrlMap = rawResponse
			end
		elseif tonumber(url) then
			isRequestSuccessful, animationUrlMap = pcall(function()
				-- upvalues: (ref) p_u_305
				return game:GetObjects("rbxassetid://" .. url)[1]
			end)
		else
			local jsonData
			jsonData, animationUrlMap = pcall(function()
				-- upvalues: (ref) p_u_305
				return loadstring(url)()
			end)
			if jsonData and type(animationUrlMap) == "table" then
				isRequestSuccessful = true
			else
				animationUrlMap = rawResponse
			end
		end
		if not (isRequestSuccessful and animationUrlMap) then
			return
		end
		animationStates[url] = animationUrlMap
	end
	if type(animationUrlMap) ~= "table" then
		animationUrlMap.Priority = Enum.AnimationPriority.Action
		animationContext.keyframes = animationUrlMap:GetKeyframes()
		if not animationContext.keyframes or #animationContext.keyframes == 0 then
			return
		end
		animationContext.totalDuration = animationContext.keyframes[#animationContext.keyframes].Time
	else
		local firstAnimKey = next(animationUrlMap)
		if not firstAnimKey then
			return
		end
		animationContext.keyframes = animationUrlMap[firstAnimKey]
		if not animationContext.keyframes or #animationContext.keyframes == 0 then
			return
		end
		animationContext.totalDuration = animationContext.keyframes[#animationContext.keyframes].Time
	end
	animationContext.currentId = url
	animationContext.elapsedTime = 0
	animationContext.isRunning = true
	local character2 = animationFolder
	local rootPartOffset
	if hasLowerTorso then
		local rootPart4 = character2:FindFirstChild("HumanoidRootPart")
		local headPart2 = character2:FindFirstChild("Head")
		local leftUpperArm = character2:FindFirstChild("LeftUpperArm")
		local rightUpperArm = character2:FindFirstChild("RightUpperArm")
		local leftUpperLeg = character2:FindFirstChild("LeftUpperLeg")
		local rightUpperLeg = character2:FindFirstChild("RightUpperLeg")
		local leftFoot = character2:FindFirstChild("LeftFoot")
		local rightFoot = character2:FindFirstChild("RightFoot")
		local leftHand = character2:FindFirstChild("LeftHand")
		local rightHand = character2:FindFirstChild("RightHand")
		local leftLowerArm = character2:FindFirstChild("LeftLowerArm")
		local rightLowerArm = character2:FindFirstChild("RightLowerArm")
		local leftLowerLeg = character2:FindFirstChild("LeftLowerLeg")
		local rightLowerLeg = character2:FindFirstChild("RightLowerLeg")
		local lowerTorso = character2:FindFirstChild("LowerTorso")
		local upperTorso = character2:FindFirstChild("UpperTorso")
		rootPartOffset = {}
		if rootPart4 then
			rootPart4 = rootPart4:FindFirstChild("RootJoint")
		end
		rootPartOffset.Torso = rootPart4
		if headPart2 then
			headPart2 = headPart2:FindFirstChild("Neck")
		end
		rootPartOffset.Head = headPart2
		if leftUpperArm then
			leftUpperArm = leftUpperArm:FindFirstChild("LeftShoulder")
		end
		rootPartOffset.LeftUpperArm = leftUpperArm
		if rightUpperArm then
			rightUpperArm = rightUpperArm:FindFirstChild("RightShoulder")
		end
		rootPartOffset.RightUpperArm = rightUpperArm
		if leftUpperLeg then
			leftUpperLeg = leftUpperLeg:FindFirstChild("LeftHip")
		end
		rootPartOffset.LeftUpperLeg = leftUpperLeg
		if rightUpperLeg then
			rightUpperLeg = rightUpperLeg:FindFirstChild("RightHip")
		end
		rootPartOffset.RightUpperLeg = rightUpperLeg
		if leftFoot then
			leftFoot = leftFoot:FindFirstChild("LeftAnkle")
		end
		rootPartOffset.LeftFoot = leftFoot
		if rightFoot then
			rightFoot = rightFoot:FindFirstChild("RightAnkle")
		end
		rootPartOffset.RightFoot = rightFoot
		if leftHand then
			leftHand = leftHand:FindFirstChild("LeftWrist")
		end
		rootPartOffset.LeftHand = leftHand
		if rightHand then
			rightHand = rightHand:FindFirstChild("RightWrist")
		end
		rootPartOffset.RightHand = rightHand
		if leftLowerArm then
			leftLowerArm = leftLowerArm:FindFirstChild("LeftElbow")
		end
		rootPartOffset.LeftLowerArm = leftLowerArm
		if rightLowerArm then
			rightLowerArm = rightLowerArm:FindFirstChild("RightElbow")
		end
		rootPartOffset.RightLowerArm = rightLowerArm
		if leftLowerLeg then
			leftLowerLeg = leftLowerLeg:FindFirstChild("LeftKnee")
		end
		rootPartOffset.LeftLowerLeg = leftLowerLeg
		if rightLowerLeg then
			rightLowerLeg = rightLowerLeg:FindFirstChild("RightKnee")
		end
		rootPartOffset.RightLowerLeg = rightLowerLeg
		if lowerTorso then
			lowerTorso = lowerTorso:FindFirstChild("Root")
		end
		rootPartOffset.LowerTorso = lowerTorso
		if upperTorso then
			upperTorso = upperTorso:FindFirstChild("Waist")
		end
		rootPartOffset.UpperTorso = upperTorso
	else
		rootPartOffset = (function(characterModel3)
			local child2, childName2, childValue = pairs(characterModel3:GetChildren())
			local animationQueue2 = {}
			while true do
				local animationData5
				childValue, animationData5 = child2(childName2, childValue)
				if childValue == nil then
					break
				end
				if animationData5:IsA("BasePart") then
					local track3, trackName2, trackValue2 = pairs(animationData5:GetChildren())
					while true do
						local currentAnimation2
						trackValue2, currentAnimation2 = track3(trackName2, trackValue2)
						if trackValue2 == nil then
							break
						end
						if currentAnimation2:IsA("Motor6D") and (currentAnimation2.Part1 and currentAnimation2.Part1.Parent == characterModel3) then
							local jointName = currentAnimation2.Part1.Name
							animationQueue2[jointName] = currentAnimation2
							if jointName == "Left Arm" then
								animationQueue2.LeftArm = currentAnimation2
							elseif jointName == "Right Arm" then
								animationQueue2.RightArm = currentAnimation2
							elseif jointName == "Left Leg" then
								animationQueue2.LeftLeg = currentAnimation2
							elseif jointName == "Right Leg" then
								animationQueue2.RightLeg = currentAnimation2
							elseif jointName == "Head" then
								animationQueue2.Head = currentAnimation2
							elseif jointName == "HumanoidRootPart" then
								animationQueue2.Torso = currentAnimation2
							end
						end
					end
				end
			end
			return animationQueue2
		end)(character2)
	end
	local animationStates3 = {}
	if not loadedAnimations then
		loadedAnimations = {}
	end
	local keyframe, time, cframe = pairs(rootPartOffset)
	while true do
		local interpolationAlpha
		cframe, interpolationAlpha = keyframe(time, cframe)
		if cframe == nil then
			break
		end
		if interpolationAlpha and interpolationAlpha:IsA("Motor6D") then
			animationStates3[cframe] = interpolationAlpha
			if not loadedAnimations[interpolationAlpha] then
				loadedAnimations[interpolationAlpha] = {
					["C0"] = interpolationAlpha.C0,
					["C1"] = interpolationAlpha.C1
				}
			end
		end
	end
	if not animationContext.connection then
		local animationModule2 = animationFolder
		local part2, partName3, partValue2 = pairs(animationModule2:GetChildren())
		while true do
			local animationPlayback
			partValue2, animationPlayback = part2(partName3, partValue2)
			if partValue2 == nil then
				break
			end
			if animationPlayback:IsA("LocalScript") and (animationPlayback.Enabled and animationPlayback ~= animationController) then
				animationPlayback.Enabled = false
			end
		end
		animationContext.connection = runService.Heartbeat:Connect(function(animationInfo)
			-- upvalues: (ref) v_u_38, (ref) v_u_12, (ref) v_u_304, (ref) v_u_363, (ref) v_u_18, (ref) v_u_23
			if not (animationContext.isRunning and animationFolder) then
				animationModule()
				return
			end
			if not animationContext.keyframes then
				return
			end
			animationContext.elapsedTime = animationContext.elapsedTime + animationInfo * animationContext.speed
			if animationContext.totalDuration > 0 then
				animationContext.elapsedTime = animationContext.elapsedTime % animationContext.totalDuration
			end
			local previousKeyframe = nil
			local currentKeyframe = nil
			for frameIndex = 1, #animationContext.keyframes - 1 do
				if animationContext.elapsedTime >= animationContext.keyframes[frameIndex].Time then
					if animationContext.elapsedTime < animationContext.keyframes[frameIndex + 1].Time then
						previousKeyframe = animationContext.keyframes[frameIndex]
						currentKeyframe = animationContext.keyframes[frameIndex + 1]
						break
					end
				end
			end
			if not previousKeyframe then
				previousKeyframe = animationContext.keyframes[#animationContext.keyframes]
				currentKeyframe = animationContext.keyframes[1]
			end
			local timeDelta = currentKeyframe.Time - previousKeyframe.Time
			if timeDelta <= 0 then
				timeDelta = animationContext.totalDuration
			end
			local elapsedTime = animationContext.elapsedTime - previousKeyframe.Time
			local normalizedTime = 0 < timeDelta and elapsedTime / timeDelta or 0
			local blendFactor = math.clamp(normalizedTime, 0, 1)
			if previousKeyframe.Data then
				local key4, value4, propertyName = pairs(previousKeyframe.Data)
				while true do
					local targetCFrame2
					propertyName, targetCFrame2 = key4(value4, propertyName)
					if propertyName == nil then
						break
					end
					local stateName = animationStates3[propertyName]
					if stateName and (loadedAnimations and loadedAnimations[stateName]) then
						local interpolatedCFrame2 = loadedAnimations[stateName].C0 * targetCFrame2
						local nextKeyframeData = currentKeyframe.Data
						if nextKeyframeData then
							nextKeyframeData = currentKeyframe.Data[propertyName]
						end
						if nextKeyframeData then
							stateName.C0 = interpolatedCFrame2:Lerp(loadedAnimations[stateName].C0 * nextKeyframeData, blendFactor)
						else
							stateName.C0 = interpolatedCFrame2
						end
					end
				end
			else
				local descendant5, descendantName2, descendantValue = pairs(previousKeyframe:GetDescendants())
				while true do
					local jointPart
					descendantValue, jointPart = descendant5(descendantName2, descendantValue)
					if descendantValue == nil then
						break
					end
					if jointPart:IsA("Pose") then
						local jointStateName = animationStates3[jointPart.Name]
						if jointStateName and (loadedAnimations and loadedAnimations[jointStateName]) then
							local finalCFrame = loadedAnimations[jointStateName].C0 * jointPart.CFrame
							local correspondingPart = currentKeyframe:FindFirstChild(jointPart.Name, true)
							if correspondingPart and correspondingPart:IsA("Pose") then
								jointStateName.C0 = finalCFrame:Lerp(loadedAnimations[jointStateName].C0 * correspondingPart.CFrame, blendFactor)
							else
								jointStateName.C0 = finalCFrame
							end
						end
					end
				end
			end
			if scaleSettings.heightScale ~= 1 or scaleSettings.widthScale ~= 1 then
				local joint, jointName2, jointValue = pairs(loadedAnimations)
				while true do
					local cframeValue
					jointValue, cframeValue = joint(jointName2, jointValue)
					if jointValue == nil then
						break
					end
					if jointValue and jointValue:IsA("Motor6D") then
						local positionOffset2 = jointValue.C0 - jointValue.C0.Position
						local originalPosition = cframeValue.C0.Position
						local scaledPosition = Vector3.new(originalPosition.X * scaleSettings.widthScale, originalPosition.Y * scaleSettings.heightScale, originalPosition.Z * scaleSettings.widthScale)
						jointValue.C0 = CFrame.new(scaledPosition) * positionOffset2
					end
				end
			end
		end)
	end
end
local function updateFunction(stateName2)
	-- upvalues: (ref) v_u_12, (ref) v_u_10, (ref) v_u_20, (ref) v_u_38, (ref) v_u_304, (ref) v_u_402
	if not (animationFolder and isInitialized) then
		return
	end
	local animationTrack2 = stateAnimations[stateName2]
	local isPlaying = false
	if animationContext.isRunning and animationContext.currentId then
		local animKey2, animValue2, animTrack2 = pairs(stateAnimations)
		while true do
			local rootPart5
			animTrack2, rootPart5 = animKey2(animValue2, animTrack2)
			if animTrack2 == nil then
				break
			end
			if rootPart5 and (rootPart5 ~= "" and tostring(rootPart5) == tostring(animationContext.currentId)) then
				isPlaying = true
				break
			end
		end
	end
	if animationTrack2 and animationTrack2 ~= "" then
		if animationFolder then
			if animationFolder:FindFirstChildWhichIsA("Humanoid") then
				if animationContext.isRunning and animationContext.currentId then
					if not isPlaying then
						return
					end
					if tostring(animationContext.currentId) == tostring(animationTrack2) then
						return
					end
				end
				if animationContext.isRunning then
					animationModule()
					task.wait(0.05)
				end
				if animationFolder and isInitialized then
					pcall(function()
						-- upvalues: (ref) v_u_402, (ref) v_u_404
						decodedResponse(tostring(animationTrack2))
					end)
				end
			else
				return
			end
		else
			return
		end
	else
		if isPlaying then
			animationModule()
		end
		return
	end
end
local function stateCheckFunction()
	-- upvalues: (ref) v_u_12, (ref) v_u_10, (ref) v_u_22, (ref) v_u_38, (ref) v_u_20, (ref) v_u_304, (ref) v_u_410, (ref) v_u_4, (ref) v_u_23, (ref) v_u_18
	if not (animationFolder and isInitialized) then
		return
	end
	if not animationFolder:FindFirstChildWhichIsA("Humanoid") then
		return
	end
	local animKey3, animLoadFunction, animData2 = pairs(cachedAnimations)
	while true do
		local loadedAnimation, animationInstance = animKey3(animLoadFunction, animData2)
		if loadedAnimation == nil then
			break
		end
		animData2 = loadedAnimation
		if animationInstance then
			pcall(function()
				-- upvalues: (ref) v_u_415
				animationInstance:Disconnect()
			end)
		end
	end
	cachedAnimations = {}
	if animationContext.isRunning and animationContext.currentId then
		local stateKey, stateValue, currentStateTrack = pairs(stateAnimations)
		while true do
			local humanoid4
			currentStateTrack, humanoid4 = stateKey(stateValue, currentStateTrack)
			if currentStateTrack == nil then
				break
			end
			if humanoid4 and (humanoid4 ~= "" and tostring(humanoid4) == tostring(animationContext.currentId)) then
				animationModule()
				break
			end
		end
	end
	local function getHumanoidState()
		-- upvalues: (ref) v_u_12
		if not animationFolder then
			return "idle"
		end
		local characterHumanoid2 = animationFolder:FindFirstChildWhichIsA("Humanoid")
		if not characterHumanoid2 then
			return "idle"
		end
		local moveDirectionMagnitude = characterHumanoid2.MoveDirection.Magnitude
		local getStateSuccess, currentState = pcall(function()
			-- upvalues: (ref) v_u_420
			return characterHumanoid2:GetState()
		end)
		return getStateSuccess and ((currentState == Enum.HumanoidStateType.Jumping or currentState == Enum.HumanoidStateType.Freefall) and "jumping" or (0.1 < moveDirectionMagnitude and "walking" or "idle")) or "idle"
	end
	local currentHumanoidState = getHumanoidState()
	local isMoving2 = currentHumanoidState
	local isJumping = currentHumanoidState
	if stateAnimations[currentHumanoidState] and stateAnimations[currentHumanoidState] ~= "" then
		task.defer(function()
			-- upvalues: (ref) v_u_12, (ref) v_u_10, (ref) v_u_410, (ref) v_u_425
			if animationFolder and isInitialized then
				updateFunction(currentHumanoidState)
			end
		end)
	end
	cachedAnimations.stateMonitor = runService.Heartbeat:Connect(function(unusedParam)
		-- upvalues: (ref) v_u_12, (ref) v_u_10, (ref) v_u_22, (ref) v_u_424, (ref) v_u_427, (ref) v_u_38, (ref) v_u_20, (ref) v_u_304, (ref) v_u_410, (ref) v_u_426, (ref) v_u_23, (ref) v_u_18
		if not (animationFolder and isInitialized) then
			if cachedAnimations.stateMonitor then
				pcall(function()
					-- upvalues: (ref) v_u_22
					cachedAnimations.stateMonitor:Disconnect()
				end)
				cachedAnimations.stateMonitor = nil
			end
			return
		end
		if not animationFolder:FindFirstChildWhichIsA("Humanoid") then
			if cachedAnimations.stateMonitor then
				pcall(function()
					-- upvalues: (ref) v_u_22
					cachedAnimations.stateMonitor:Disconnect()
				end)
				cachedAnimations.stateMonitor = nil
			end
			return
		end
		local fetchHumanoidState = getHumanoidState()
		if fetchHumanoidState ~= isJumping then
			isJumping = fetchHumanoidState
			local isLoaded = false
			if animationContext.isRunning and animationContext.currentId then
				local jointName3, jointValue2, jointInstance2 = pairs(stateAnimations)
				while true do
					local cframeValue2
					jointInstance2, cframeValue2 = jointName3(jointValue2, jointInstance2)
					if jointInstance2 == nil then
						break
					end
					if cframeValue2 and (cframeValue2 ~= "" and tostring(cframeValue2) == tostring(animationContext.currentId)) then
						isLoaded = true
						break
					end
				end
			end
			if isLoaded then
				animationModule()
			end
			if stateAnimations[fetchHumanoidState] and (stateAnimations[fetchHumanoidState] ~= "" and (animationFolder and isInitialized)) then
				task.defer(function()
					-- upvalues: (ref) v_u_12, (ref) v_u_10, (ref) v_u_410, (ref) v_u_428
					if animationFolder and isInitialized then
						updateFunction(fetchHumanoidState)
					end
				end)
			end
		end
		isMoving2 = fetchHumanoidState
		if (scaleSettings.heightScale ~= 1 or scaleSettings.widthScale ~= 1) and loadedAnimations then
			local joint2, jointName4, jointValue3 = pairs(loadedAnimations)
			while true do
				local cframeValue3
				jointValue3, cframeValue3 = joint2(jointName4, jointValue3)
				if jointValue3 == nil then
					break
				end
				if jointValue3 and (jointValue3:IsA("Motor6D") and jointValue3.Parent) then
					local positionOffset3 = jointValue3.C0 - jointValue3.C0.Position
					local originalPosition2 = cframeValue3.C0.Position
					local scaledPosition2 = Vector3.new(originalPosition2.X * scaleSettings.widthScale, originalPosition2.Y * scaleSettings.heightScale, originalPosition2.Z * scaleSettings.widthScale)
					jointValue3.C0 = CFrame.new(scaledPosition2) * positionOffset3
				end
			end
		end
	end)
end
local function guiUpdateFunction()
	-- upvalues: (ref) v_u_7, (ref) v_u_6, (ref) v_u_289, (ref) v_u_10, (ref) v_u_12, (ref) v_u_441, (ref) v_u_20, (ref) v_u_39, (ref) v_u_122, (ref) v_u_22, (ref) v_u_38, (ref) v_u_304, (ref) v_u_23, (ref) v_u_246, (ref) v_u_3, (ref) v_u_11, (ref) v_u_26, (ref) v_u_33, (ref) v_u_34, (ref) v_u_35, (ref) v_u_27, (ref) v_u_30, (ref) v_u_52, (ref) v_u_111, (ref) v_u_49, (ref) v_u_47, (ref) v_u_48, (ref) v_u_402, (ref) v_u_135, (ref) v_u_96, (ref) v_u_79, (ref) v_u_290
	local playerGui2 = localPlayer:WaitForChild("PlayerGui")
	if not playerGui2:FindFirstChild("AKReanimGUI") then
		local screenGuiInstance = Instance.new("ScreenGui")
		screenGuiInstance.Name = "AKReanimGUI"
		screenGuiInstance.ResetOnSpawn = false
		screenGuiInstance.Parent = playerGui2
		local mainFrame = Instance.new("Frame")
		mainFrame.Size = UDim2.new(0, 280, 0, 395)
		mainFrame.Position = UDim2.new(0.5, -140, 0.5, -197.5)
		mainFrame.BackgroundColor3 = Color3.new(0, 0, 0)
		mainFrame.BackgroundTransparency = 0.6
		mainFrame.BorderSizePixel = 0
		mainFrame.Parent = screenGuiInstance
		local mainCorner = Instance.new("UICorner")
		mainCorner.CornerRadius = UDim.new(0, 15)
		mainCorner.Parent = mainFrame
		local headerFrame = Instance.new("Frame")
		headerFrame.Size = UDim2.new(1, 0, 0, 30)
		headerFrame.Position = UDim2.new(0, 0, 0, 0)
		headerFrame.BackgroundTransparency = 1
		headerFrame.BorderSizePixel = 0
		headerFrame.Parent = mainFrame
		local titleLabel = Instance.new("TextLabel")
		titleLabel.Size = UDim2.new(1, -100, 1, 0)
		titleLabel.Position = UDim2.new(0, 50, 0, 0)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Text = "AK REANIMATION"
		titleLabel.TextColor3 = Color3.new(1, 1, 1)
		titleLabel.TextSize = 16
		titleLabel.Font = Enum.Font.Gotham
		titleLabel.TextXAlignment = Enum.TextXAlignment.Center
		titleLabel.Parent = headerFrame
		local contentFrame = Instance.new("Frame")
		contentFrame.Size = UDim2.new(0, 40, 0, 18)
		contentFrame.Position = UDim2.new(0, 6, 0, 6)
		contentFrame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
		contentFrame.BorderSizePixel = 0
		contentFrame.Parent = headerFrame
		local contentCorner = Instance.new("UICorner")
		contentCorner.CornerRadius = UDim.new(0, 9)
		contentCorner.Parent = contentFrame
		local buttonContainer = Instance.new("Frame")
		buttonContainer.Size = UDim2.new(0, 14, 0, 14)
		buttonContainer.Position = UDim2.new(0, 2, 0, 2)
		buttonContainer.BackgroundColor3 = Color3.new(0.7, 0.7, 0.7)
		buttonContainer.BorderSizePixel = 0
		buttonContainer.Parent = contentFrame
		local buttonCorner = Instance.new("UICorner")
		buttonCorner.CornerRadius = UDim.new(0, 7)
		buttonCorner.Parent = buttonContainer
		local toggleButton = Instance.new("TextButton")
		toggleButton.Size = UDim2.new(1, 0, 1, 0)
		toggleButton.BackgroundTransparency = 1
		toggleButton.Text = ""
		toggleButton.Parent = contentFrame
		local isToggled = false
		local isVisible = false
		local animationSpeed = 0
		toggleButton.MouseButton1Click:Connect(function()
			-- upvalues: (ref) v_u_454, (ref) v_u_455, (ref) v_u_453, (ref) v_u_6, (ref) v_u_448, (ref) v_u_450, (ref) v_u_289, (ref) v_u_10, (ref) v_u_12, (ref) v_u_441
			if isVisible then
				return
			else
				local startTime = tick()
				if startTime - animationSpeed >= 3 then
					isVisible = true
					animationSpeed = startTime
					isToggled = not isToggled
					local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
					if isToggled then
						tweenService:Create(contentFrame, tweenInfo, {
							["BackgroundColor3"] = Color3.fromRGB(0, 150, 255)
						}):Play()
						tweenService:Create(buttonContainer, tweenInfo, {
							["Position"] = UDim2.new(1, -16, 0, 2),
							["BackgroundColor3"] = Color3.new(1, 1, 1)
						}):Play()
					else
						tweenService:Create(contentFrame, tweenInfo, {
							["BackgroundColor3"] = Color3.new(0.2, 0.2, 0.2)
						}):Play()
						tweenService:Create(buttonContainer, tweenInfo, {
							["Position"] = UDim2.new(0, 2, 0, 2),
							["BackgroundColor3"] = Color3.new(0.7, 0.7, 0.7)
						}):Play()
					end
					ragdollModule(isToggled)
					if isToggled then
						spawn(function()
							-- upvalues: (ref) v_u_10, (ref) v_u_12, (ref) v_u_441
							wait(0.3)
							if isInitialized and animationFolder then
								stateCheckFunction()
							end
						end)
					end
					spawn(function()
						-- upvalues: (ref) v_u_454
						wait(3)
						isVisible = false
					end)
				end
			end
		end)
		local closeButton = Instance.new("TextButton")
		closeButton.Size = UDim2.new(0, 22, 0, 22)
		closeButton.Position = UDim2.new(1, -48, 0, 4)
		closeButton.BackgroundColor3 = Color3.new(0, 0, 0)
		closeButton.BackgroundTransparency = 0.7
		closeButton.Text = "\226\136\146"
		closeButton.TextColor3 = Color3.new(1, 1, 1)
		closeButton.TextScaled = true
		closeButton.Font = Enum.Font.Gotham
		closeButton.BorderSizePixel = 0
		closeButton.Parent = headerFrame
		local closeCorner = Instance.new("UICorner")
		closeCorner.CornerRadius = UDim.new(0, 10)
		closeCorner.Parent = closeButton
		local minimizeButton = Instance.new("TextButton")
		minimizeButton.Size = UDim2.new(0, 22, 0, 22)
		minimizeButton.Position = UDim2.new(1, -24, 0, 4)
		minimizeButton.BackgroundColor3 = Color3.new(0, 0, 0)
		minimizeButton.BackgroundTransparency = 0.7
		minimizeButton.Text = "\195\151"
		minimizeButton.TextColor3 = Color3.new(1, 1, 1)
		minimizeButton.TextScaled = true
		minimizeButton.Font = Enum.Font.Gotham
		minimizeButton.BorderSizePixel = 0
		minimizeButton.Parent = headerFrame
		local minimizeCorner = Instance.new("UICorner")
		minimizeCorner.CornerRadius = UDim.new(0, 10)
		minimizeCorner.Parent = minimizeButton
		local statusLabel = Instance.new("TextLabel")
		statusLabel.Size = UDim2.new(1, -16, 0, 12)
		statusLabel.Position = UDim2.new(0, 8, 0, 32)
		statusLabel.BackgroundTransparency = 1
		statusLabel.Text = "Ready"
		statusLabel.TextColor3 = Color3.new(0.7, 0.7, 0.7)
		statusLabel.TextSize = 10
		statusLabel.Font = Enum.Font.Gotham
		statusLabel.Parent = mainFrame
		local settingsFrame = Instance.new("Frame")
		settingsFrame.Size = UDim2.new(1, -16, 0, 25)
		settingsFrame.Position = UDim2.new(0, 8, 0, 48)
		settingsFrame.BackgroundTransparency = 1
		settingsFrame.Parent = mainFrame
		local saveButton = Instance.new("TextButton")
		saveButton.Size = UDim2.new(0.166, -2, 1, 0)
		saveButton.Position = UDim2.new(0, 0, 0, 0)
		saveButton.BackgroundColor3 = Color3.new(0, 0, 0)
		saveButton.BackgroundTransparency = 0.5
		saveButton.Text = "All"
		saveButton.TextColor3 = Color3.new(1, 1, 1)
		saveButton.TextSize = 11
		saveButton.Font = Enum.Font.Gotham
		saveButton.BorderSizePixel = 0
		saveButton.Parent = settingsFrame
		local loadButton = Instance.new("TextButton")
		loadButton.Size = UDim2.new(0.166, -2, 1, 0)
		loadButton.Position = UDim2.new(0.166, 2, 0, 0)
		loadButton.BackgroundColor3 = Color3.new(0, 0, 0)
		loadButton.BackgroundTransparency = 0.8
		loadButton.Text = "Favs"
		loadButton.TextColor3 = Color3.new(1, 1, 1)
		loadButton.TextSize = 11
		loadButton.Font = Enum.Font.Gotham
		loadButton.BorderSizePixel = 0
		loadButton.Parent = settingsFrame
		local resetButton = Instance.new("TextButton")
		resetButton.Size = UDim2.new(0.166, -2, 1, 0)
		resetButton.Position = UDim2.new(0.332, 4, 0, 0)
		resetButton.BackgroundColor3 = Color3.new(0, 0, 0)
		resetButton.BackgroundTransparency = 0.8
		resetButton.Text = "Custom"
		resetButton.TextColor3 = Color3.new(1, 1, 1)
		resetButton.TextSize = 11
		resetButton.Font = Enum.Font.Gotham
		resetButton.BorderSizePixel = 0
		resetButton.Parent = settingsFrame
		local exportButton = Instance.new("TextButton")
		exportButton.Size = UDim2.new(0.166, -2, 1, 0)
		exportButton.Position = UDim2.new(0.498, 6, 0, 0)
		exportButton.BackgroundColor3 = Color3.new(0, 0, 0)
		exportButton.BackgroundTransparency = 0.8
		exportButton.Text = "States"
		exportButton.TextColor3 = Color3.new(1, 1, 1)
		exportButton.TextSize = 11
		exportButton.Font = Enum.Font.Gotham
		exportButton.BorderSizePixel = 0
		exportButton.Parent = settingsFrame
		local importButton = Instance.new("TextButton")
		importButton.Size = UDim2.new(0.166, -2, 1, 0)
		importButton.Position = UDim2.new(0.664, 8, 0, 0)
		importButton.BackgroundColor3 = Color3.new(0, 0, 0)
		importButton.BackgroundTransparency = 0.8
		importButton.Text = "Size"
		importButton.TextColor3 = Color3.new(1, 1, 1)
		importButton.TextSize = 11
		importButton.Font = Enum.Font.Gotham
		importButton.BorderSizePixel = 0
		importButton.Parent = settingsFrame
		local exportCorner = Instance.new("UICorner")
		exportCorner.CornerRadius = UDim.new(0, 10)
		exportCorner.Parent = importButton
		local importButton2 = Instance.new("TextButton")
		importButton2.Size = UDim2.new(0.166, -2, 1, 0)
		importButton2.Position = UDim2.new(0.83, 10, 0, 0)
		importButton2.BackgroundColor3 = Color3.new(0, 0, 0)
		importButton2.BackgroundTransparency = 0.8
		importButton2.Text = "Others"
		importButton2.TextColor3 = Color3.new(1, 1, 1)
		importButton2.TextSize = 11
		importButton2.Font = Enum.Font.Gotham
		importButton2.BorderSizePixel = 0
		importButton2.Parent = settingsFrame
		local importCorner = Instance.new("UICorner")
		importCorner.CornerRadius = UDim.new(0, 10)
		importCorner.Parent = importButton2
		local saveCorner = Instance.new("UICorner")
		saveCorner.CornerRadius = UDim.new(0, 10)
		saveCorner.Parent = saveButton
		local loadCorner = Instance.new("UICorner")
		loadCorner.CornerRadius = UDim.new(0, 10)
		loadCorner.Parent = loadButton
		local resetCorner = Instance.new("UICorner")
		resetCorner.CornerRadius = UDim.new(0, 10)
		resetCorner.Parent = resetButton
		local settingsCorner = Instance.new("UICorner")
		settingsCorner.CornerRadius = UDim.new(0, 10)
		settingsCorner.Parent = exportButton
		local searchBox = Instance.new("TextBox")
		searchBox.Size = UDim2.new(1, -16, 0, 22)
		searchBox.Position = UDim2.new(0, 8, 0, 78)
		searchBox.BackgroundColor3 = Color3.new(0, 0, 0)
		searchBox.BackgroundTransparency = 0.5
		searchBox.Text = ""
		searchBox.PlaceholderText = "Search..."
		searchBox.TextColor3 = Color3.new(1, 1, 1)
		searchBox.PlaceholderColor3 = Color3.new(0.7, 0.7, 0.7)
		searchBox.TextSize = 11
		searchBox.Font = Enum.Font.Gotham
		searchBox.BorderSizePixel = 0
		searchBox.Parent = mainFrame
		local searchCorner = Instance.new("UICorner")
		searchCorner.CornerRadius = UDim.new(0, 10)
		searchCorner.Parent = searchBox
		local scrollContainer = Instance.new("ScrollingFrame")
		scrollContainer.Size = UDim2.new(1, -16, 1, -175)
		scrollContainer.Position = UDim2.new(0, 8, 0, 105)
		scrollContainer.BackgroundTransparency = 1
		scrollContainer.ScrollBarThickness = 4
		scrollContainer.ScrollBarImageColor3 = Color3.new(1, 1, 1)
		scrollContainer.ScrollBarImageTransparency = 0.5
		scrollContainer.BorderSizePixel = 0
		scrollContainer.ScrollingDirection = Enum.ScrollingDirection.Y
		scrollContainer.Parent = mainFrame
		local listLayout = Instance.new("UIListLayout")
		listLayout.Padding = UDim.new(0, 3)
		listLayout.SortOrder = Enum.SortOrder.LayoutOrder
		listLayout.Parent = scrollContainer
		local optionFrame = Instance.new("Frame")
		optionFrame.Size = UDim2.new(1, -16, 0, 80)
		optionFrame.Position = UDim2.new(0, 8, 0, 105)
		optionFrame.BackgroundTransparency = 1
		optionFrame.Visible = false
		optionFrame.Parent = mainFrame
		local inputBox = Instance.new("TextBox")
		inputBox.Size = UDim2.new(1, 0, 0, 22)
		inputBox.Position = UDim2.new(0, 0, 0, 0)
		inputBox.BackgroundColor3 = Color3.new(0, 0, 0)
		inputBox.BackgroundTransparency = 0.5
		inputBox.Text = ""
		inputBox.PlaceholderText = "Animation Name..."
		inputBox.TextColor3 = Color3.new(1, 1, 1)
		inputBox.PlaceholderColor3 = Color3.new(0.7, 0.7, 0.7)
		inputBox.TextSize = 11
		inputBox.Font = Enum.Font.Gotham
		inputBox.BorderSizePixel = 0
		inputBox.Parent = optionFrame
		local inputCorner = Instance.new("UICorner")
		inputCorner.CornerRadius = UDim.new(0, 10)
		inputCorner.Parent = inputBox
		local sliderInput = Instance.new("TextBox")
		sliderInput.Size = UDim2.new(1, 0, 0, 45)
		sliderInput.Position = UDim2.new(0, 0, 0, 27)
		sliderInput.BackgroundColor3 = Color3.new(0, 0, 0)
		sliderInput.BackgroundTransparency = 0.5
		sliderInput.Text = ""
		sliderInput.PlaceholderText = "Keyframe Code..."
		sliderInput.TextColor3 = Color3.new(1, 1, 1)
		sliderInput.PlaceholderColor3 = Color3.new(0.7, 0.7, 0.7)
		sliderInput.TextSize = 9
		sliderInput.Font = Enum.Font.Code
		sliderInput.TextWrapped = true
		sliderInput.TextXAlignment = Enum.TextXAlignment.Left
		sliderInput.TextYAlignment = Enum.TextYAlignment.Top
		sliderInput.ClearTextOnFocus = false
		sliderInput.MultiLine = true
		sliderInput.BorderSizePixel = 0
		sliderInput.Parent = optionFrame
		local sliderCorner = Instance.new("UICorner")
		sliderCorner.CornerRadius = UDim.new(0, 10)
		sliderCorner.Parent = sliderInput
		local categoryFrame = Instance.new("Frame")
		categoryFrame.Size = UDim2.new(1, -16, 1, -175)
		categoryFrame.Position = UDim2.new(0, 8, 0, 105)
		categoryFrame.BackgroundTransparency = 1
		categoryFrame.Visible = false
		categoryFrame.Parent = mainFrame
		local categoryScroll = Instance.new("ScrollingFrame")
		categoryScroll.Size = UDim2.new(1, 0, 1, 0)
		categoryScroll.Position = UDim2.new(0, 0, 0, 0)
		categoryScroll.BackgroundTransparency = 1
		categoryScroll.ScrollBarThickness = 4
		categoryScroll.ScrollBarImageColor3 = Color3.new(1, 1, 1)
		categoryScroll.ScrollBarImageTransparency = 0.5
		categoryScroll.BorderSizePixel = 0
		categoryScroll.Parent = categoryFrame
		local categoryLayout = Instance.new("UIListLayout")
		categoryLayout.Padding = UDim.new(0, 10)
		categoryLayout.SortOrder = Enum.SortOrder.LayoutOrder
		categoryLayout.Parent = categoryScroll
		local function initializeUI(player4, character3, humanoid5)
			-- upvalues: (ref) v_u_486, (ref) v_u_20, (ref) v_u_39, (ref) v_u_122, (ref) v_u_462, (ref) v_u_10, (ref) v_u_22, (ref) v_u_38, (ref) v_u_304, (ref) v_u_441
			local overlayFrame = Instance.new("Frame")
			overlayFrame.Size = UDim2.new(1, 0, 0, 110)
			overlayFrame.BackgroundColor3 = Color3.new(0, 0, 0)
			overlayFrame.BackgroundTransparency = 0.7
			overlayFrame.BorderSizePixel = 0
			overlayFrame.LayoutOrder = humanoid5
			overlayFrame.Parent = categoryScroll
			local overlayCorner = Instance.new("UICorner")
			overlayCorner.CornerRadius = UDim.new(0, 10)
			overlayCorner.Parent = overlayFrame
			local titleLabel2 = Instance.new("TextLabel")
			titleLabel2.Size = UDim2.new(1, -10, 0, 20)
			titleLabel2.Position = UDim2.new(0, 5, 0, 5)
			titleLabel2.BackgroundTransparency = 1
			titleLabel2.Text = character3
			titleLabel2.TextColor3 = Color3.new(1, 1, 1)
			titleLabel2.TextSize = 12
			titleLabel2.Font = Enum.Font.GothamBold
			titleLabel2.TextXAlignment = Enum.TextXAlignment.Left
			titleLabel2.Parent = overlayFrame
			local selectButton = Instance.new("TextButton")
			selectButton.Size = UDim2.new(1, -10, 0, 25)
			selectButton.Position = UDim2.new(0, 5, 0, 30)
			selectButton.BackgroundColor3 = Color3.new(0, 0, 0)
			selectButton.BackgroundTransparency = 0.5
			local defaultText = "Select Animation..."
			local frame
			if stateAnimations[player4] and stateAnimations[player4] ~= "" then
				local textColor, textSize
				textColor, textSize, frame = pairs(animationQueue)
				while true do
					local font
					frame, font = textColor(textSize, frame)
					if frame == nil then
						frame = defaultText
						break
					end
					if tostring(font) == tostring(stateAnimations[player4]) then
						break
					end
				end
				if frame == "Select Animation..." then
					frame = "Custom Keyframes"
				end
			else
				frame = defaultText
			end
			selectButton.Text = frame
			selectButton.TextColor3 = Color3.new(1, 1, 1)
			selectButton.TextSize = 10
			selectButton.Font = Enum.Font.Gotham
			selectButton.TextXAlignment = Enum.TextXAlignment.Left
			selectButton.BorderSizePixel = 0
			selectButton.Parent = overlayFrame
			local titleCorner = Instance.new("UICorner")
			titleCorner.CornerRadius = UDim.new(0, 8)
			titleCorner.Parent = selectButton
			local titlePadding = Instance.new("UIPadding")
			titlePadding.PaddingLeft = UDim.new(0, 8)
			titlePadding.Parent = selectButton
			local searchBox2 = Instance.new("TextBox")
			searchBox2.Size = UDim2.new(1, -10, 0, 40)
			searchBox2.Position = UDim2.new(0, 5, 0, 60)
			searchBox2.BackgroundColor3 = Color3.new(0, 0, 0)
			searchBox2.BackgroundTransparency = 0.5
			searchBox2.Text = ""
			searchBox2.PlaceholderText = "Or paste keyframe code..."
			searchBox2.TextColor3 = Color3.new(1, 1, 1)
			searchBox2.PlaceholderColor3 = Color3.new(0.7, 0.7, 0.7)
			searchBox2.TextSize = 9
			searchBox2.Font = Enum.Font.Code
			searchBox2.TextWrapped = true
			searchBox2.TextXAlignment = Enum.TextXAlignment.Left
			searchBox2.TextYAlignment = Enum.TextYAlignment.Top
			searchBox2.ClearTextOnFocus = false
			searchBox2.MultiLine = true
			searchBox2.BorderSizePixel = 0
			searchBox2.Parent = overlayFrame
			local searchCorner2 = Instance.new("UICorner")
			searchCorner2.CornerRadius = UDim.new(0, 8)
			searchCorner2.Parent = searchBox2
			local isSearching = false
			local currentAnimation3 = nil
			selectButton.MouseButton1Click:Connect(function()
				-- upvalues: (ref) v_u_504, (ref) v_u_505, (ref) v_u_494, (ref) v_u_20, (ref) p_u_488, (ref) v_u_122, (ref) v_u_502, (ref) v_u_462, (ref) p_u_489, (ref) v_u_10, (ref) v_u_22, (ref) v_u_38, (ref) v_u_304, (ref) v_u_441, (ref) v_u_39
				if isSearching then
					if currentAnimation3 then
						currentAnimation3:Destroy()
					end
					isSearching = false
				else
					isSearching = true
					currentAnimation3 = Instance.new("Frame")
					currentAnimation3.Size = UDim2.new(1, 0, 0, 180)
					currentAnimation3.Position = UDim2.new(0, 0, 1, 2)
					currentAnimation3.BackgroundColor3 = Color3.new(0, 0, 0)
					currentAnimation3.BackgroundTransparency = 0.3
					currentAnimation3.BorderSizePixel = 0
					currentAnimation3.ZIndex = 10
					currentAnimation3.Parent = selectButton
					local searchBoxCorner = Instance.new("UICorner")
					searchBoxCorner.CornerRadius = UDim.new(0, 8)
					searchBoxCorner.Parent = currentAnimation3
					local filterBox = Instance.new("TextBox")
					filterBox.Size = UDim2.new(1, -8, 0, 22)
					filterBox.Position = UDim2.new(0, 4, 0, 4)
					filterBox.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
					filterBox.BackgroundTransparency = 0.3
					filterBox.Text = ""
					filterBox.PlaceholderText = "Search..."
					filterBox.TextColor3 = Color3.new(1, 1, 1)
					filterBox.PlaceholderColor3 = Color3.new(0.7, 0.7, 0.7)
					filterBox.TextSize = 10
					filterBox.Font = Enum.Font.Gotham
					filterBox.BorderSizePixel = 0
					filterBox.ZIndex = 10
					filterBox.ClearTextOnFocus = false
					filterBox.Parent = currentAnimation3
					local filterBoxCorner = Instance.new("UICorner")
					filterBoxCorner.CornerRadius = UDim.new(0, 6)
					filterBoxCorner.Parent = filterBox
					local animationListFrame = Instance.new("ScrollingFrame")
					animationListFrame.Size = UDim2.new(1, -4, 1, -30)
					animationListFrame.Position = UDim2.new(0, 2, 0, 28)
					animationListFrame.BackgroundTransparency = 1
					animationListFrame.ScrollBarThickness = 3
					animationListFrame.ScrollBarImageColor3 = Color3.new(1, 1, 1)
					animationListFrame.ScrollBarImageTransparency = 0.5
					animationListFrame.BorderSizePixel = 0
					animationListFrame.ZIndex = 10
					animationListFrame.Parent = currentAnimation3
					local listLayout2 = Instance.new("UIListLayout")
					listLayout2.Padding = UDim.new(0, 2)
					listLayout2.SortOrder = Enum.SortOrder.Name
					listLayout2.Parent = animationListFrame
					local animationButtons = {}
					local function createAnimationButton()
						-- upvalues: (ref) v_u_511, (ref) v_u_507, (ref) v_u_509, (ref) v_u_20, (ref) p_u_488, (ref) v_u_122, (ref) v_u_494, (ref) v_u_502, (ref) v_u_505, (ref) v_u_504, (ref) v_u_462, (ref) p_u_489, (ref) v_u_10, (ref) v_u_22, (ref) v_u_38, (ref) v_u_304, (ref) v_u_441, (ref) v_u_39, (ref) v_u_510
						local animIndex2, animButton, animData3 = pairs(animationButtons)
						while true do
							local button
							animData3, button = animIndex2(animButton, animData3)
							if animData3 == nil then
								break
							end
							button:Destroy()
						end
						animationButtons = {}
						local searchText = filterBox.Text:lower()
						local animButtonInstance = Instance.new("TextButton")
						animButtonInstance.Size = UDim2.new(1, 0, 0, 22)
						animButtonInstance.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
						animButtonInstance.BackgroundTransparency = 0.3
						animButtonInstance.Text = " [None]"
						animButtonInstance.TextColor3 = Color3.new(1, 0.5, 0.5)
						animButtonInstance.TextSize = 10
						animButtonInstance.Font = Enum.Font.GothamBold
						animButtonInstance.TextXAlignment = Enum.TextXAlignment.Left
						animButtonInstance.BorderSizePixel = 0
						animButtonInstance.ZIndex = 10
						animButtonInstance.LayoutOrder = -1
						animButtonInstance.Parent = animationListFrame
						table.insert(animationButtons, animButtonInstance)
						animButtonInstance.MouseButton1Click:Connect(function()
							-- upvalues: (ref) v_u_20, (ref) p_u_488, (ref) v_u_122, (ref) v_u_494, (ref) v_u_502, (ref) v_u_505, (ref) v_u_504, (ref) v_u_462, (ref) p_u_489, (ref) v_u_10, (ref) v_u_22, (ref) v_u_38, (ref) v_u_304, (ref) v_u_441
							stateAnimations[player4] = ""
							saveAnimationList()
							selectButton.Text = "Select Animation..."
							searchBox2.Text = ""
							if currentAnimation3 then
								currentAnimation3:Destroy()
							end
							isSearching = false
							statusLabel.Text = character3 .. " cleared"
							statusLabel.TextColor3 = Color3.new(1, 0.7, 0.3)
							spawn(function()
								-- upvalues: (ref) v_u_462
								wait(2)
								statusLabel.Text = "Ready"
								statusLabel.TextColor3 = Color3.new(0.7, 0.7, 0.7)
							end)
							if isInitialized then
								local animKey4, animValue3, animEntry2 = pairs(cachedAnimations)
								while true do
									local animationList2
									animEntry2, animationList2 = animKey4(animValue3, animEntry2)
									if animEntry2 == nil then
										break
									end
									if animationList2 then
										pcall(function()
											-- upvalues: (ref) v_u_521
											animationList2:Disconnect()
										end)
									end
								end
								cachedAnimations = {}
								if animationContext.isRunning then
									animationModule()
								end
								task.wait(0.1)
								if isInitialized then
									stateCheckFunction()
								end
							end
						end)
						local entryKey, entryValue, entry4 = pairs(animationQueue)
						local filteredAnimations = {}
						local buttonIndex = 0
						local debounceTime = 50
						while true do
							local lastSearchTime
							entry4, lastSearchTime = entryKey(entryValue, entry4)
							if entry4 == nil then
								break
							end
							if searchText == "" or entry4:lower():find(searchText, 1, true) then
								table.insert(filteredAnimations, {
									["name"] = entry4,
									["id"] = lastSearchTime
								})
								buttonIndex = buttonIndex + 1
								if debounceTime <= buttonIndex then
									break
								end
							end
						end
						table.sort(filteredAnimations, function(button2, animationName)
							return button2.name < animationName.name
						end)
						local filteredIndex, filteredButton, filteredAnim = ipairs(filteredAnimations)
						while true do
							local buttonContainer2
							filteredAnim, buttonContainer2 = filteredIndex(filteredButton, filteredAnim)
							if filteredAnim == nil then
								break
							end
							local playButton = Instance.new("TextButton")
							playButton.Size = UDim2.new(1, 0, 0, 22)
							playButton.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
							playButton.BackgroundTransparency = 0.3
							playButton.Text = " " .. buttonContainer2.name
							playButton.TextColor3 = Color3.new(1, 1, 1)
							playButton.TextSize = 10
							playButton.Font = Enum.Font.Gotham
							playButton.TextXAlignment = Enum.TextXAlignment.Left
							playButton.BorderSizePixel = 0
							playButton.ZIndex = 10
							playButton.Parent = animationListFrame
							table.insert(animationButtons, playButton)
							playButton.MouseButton1Click:Connect(function()
								-- upvalues: (ref) v_u_20, (ref) p_u_488, (ref) v_u_534, (ref) v_u_122, (ref) v_u_494, (ref) v_u_502, (ref) v_u_505, (ref) v_u_504, (ref) v_u_462, (ref) p_u_489, (ref) v_u_10, (ref) v_u_22, (ref) v_u_38, (ref) v_u_304, (ref) v_u_441
								stateAnimations[player4] = tostring(buttonContainer2.id)
								saveAnimationList()
								selectButton.Text = buttonContainer2.name
								searchBox2.Text = ""
								if currentAnimation3 then
									currentAnimation3:Destroy()
								end
								isSearching = false
								statusLabel.Text = character3 .. " set to " .. buttonContainer2.name
								statusLabel.TextColor3 = Color3.new(0.5, 1, 0.5)
								spawn(function()
									-- upvalues: (ref) v_u_462
									wait(2)
									statusLabel.Text = "Ready"
									statusLabel.TextColor3 = Color3.new(0.7, 0.7, 0.7)
								end)
								if isInitialized then
									local animKey5, animValue4, animEntry3 = pairs(cachedAnimations)
									while true do
										local animationContainer
										animEntry3, animationContainer = animKey5(animValue4, animEntry3)
										if animEntry3 == nil then
											break
										end
										if animationContainer then
											pcall(function()
												-- upvalues: (ref) v_u_539
												animationContainer:Disconnect()
											end)
										end
									end
									cachedAnimations = {}
									if animationContext.isRunning then
										animationModule()
									end
									task.wait(0.1)
									if isInitialized then
										stateCheckFunction()
									end
								end
							end)
						end
						task.defer(function()
							-- upvalues: (ref) v_u_509, (ref) v_u_510
							animationListFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout2.AbsoluteContentSize.Y)
						end)
					end
					createAnimationButton()
					local isPlaying2 = false
					local searchInput = filterBox
					filterBox.GetPropertyChangedSignal(searchInput, "Text"):Connect(function()
						-- upvalues: (ref) v_u_541, (ref) v_u_540
						if not isPlaying2 then
							isPlaying2 = true
							task.wait(0.2)
							createAnimationButton()
							isPlaying2 = false
						end
					end)
				end
			end)
			searchBox2.FocusLost:Connect(function(hiddenBodyParts4)
				-- upvalues: (ref) v_u_502, (ref) v_u_20, (ref) p_u_488, (ref) v_u_122, (ref) v_u_494, (ref) v_u_462, (ref) p_u_489, (ref) v_u_10, (ref) v_u_22, (ref) v_u_38, (ref) v_u_304, (ref) v_u_441
				if searchBox2.Text ~= "" then
					stateAnimations[player4] = searchBox2.Text
					saveAnimationList()
					selectButton.Text = "Custom Keyframes"
					statusLabel.Text = character3 .. " set to custom keyframes"
					statusLabel.TextColor3 = Color3.new(0.5, 1, 0.5)
					spawn(function()
						-- upvalues: (ref) v_u_462
						wait(2)
						statusLabel.Text = "Ready"
						statusLabel.TextColor3 = Color3.new(0.7, 0.7, 0.7)
					end)
					if isInitialized then
						local partName4, partValue3, partEntry = pairs(cachedAnimations)
						while true do
							local uiContainer
							partEntry, uiContainer = partName4(partValue3, partEntry)
							if partEntry == nil then
								break
							end
							if uiContainer then
								pcall(function()
									-- upvalues: (ref) v_u_546
									uiContainer:Disconnect()
								end)
							end
						end
						cachedAnimations = {}
						if animationContext.isRunning then
							animationModule()
						end
						task.wait(0.1)
						if isInitialized then
							stateCheckFunction()
						end
					end
				end
			end)
		end
		initializeUI("idle", "IDLE Animation", 1)
		initializeUI("walking", "WALKING Animation", 2)
		initializeUI("jumping", "JUMPING Animation", 3)
		spawn(function()
			-- upvalues: (ref) v_u_486, (ref) v_u_487
			wait(0.1)
			categoryScroll.CanvasSize = UDim2.new(0, 0, 0, categoryLayout.AbsoluteContentSize.Y + 10)
		end)
		local titleFrame = Instance.new("Frame")
		titleFrame.Size = UDim2.new(1, -16, 1, -175)
		titleFrame.Position = UDim2.new(0, 8, 0, 105)
		titleFrame.BackgroundTransparency = 1
		titleFrame.Visible = false
		titleFrame.Parent = mainFrame
		local titleLabel3 = Instance.new("TextLabel")
		titleLabel3.Size = UDim2.new(1, 0, 0, 25)
		titleLabel3.Position = UDim2.new(0, 0, 0, 10)
		titleLabel3.BackgroundTransparency = 1
		titleLabel3.Text = "Height: 1.00x"
		titleLabel3.TextColor3 = Color3.new(1, 1, 1)
		titleLabel3.TextSize = 12
		titleLabel3.Font = Enum.Font.GothamBold
		titleLabel3.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel3.Parent = titleFrame
		local contentFrame2 = Instance.new("Frame")
		contentFrame2.Size = UDim2.new(1, -20, 0, 6)
		contentFrame2.Position = UDim2.new(0, 10, 0, 45)
		contentFrame2.BackgroundColor3 = Color3.new(0, 0, 0)
		contentFrame2.BackgroundTransparency = 0.5
		contentFrame2.BorderSizePixel = 0
		contentFrame2.Parent = titleFrame
		local contentCorner2 = Instance.new("UICorner")
		contentCorner2.CornerRadius = UDim.new(0, 3)
		contentCorner2.Parent = contentFrame2
		local buttonContainer3 = Instance.new("Frame")
		buttonContainer3.Size = UDim2.new(0, 14, 0, 14)
		buttonContainer3.Position = UDim2.new(0.5, -7, 0.5, -7)
		buttonContainer3.BackgroundColor3 = Color3.new(1, 1, 1)
		buttonContainer3.BackgroundTransparency = 0.2
		buttonContainer3.BorderSizePixel = 0
		buttonContainer3.Parent = contentFrame2
		local buttonCorner2 = Instance.new("UICorner")
		buttonCorner2.CornerRadius = UDim.new(0, 7)
		buttonCorner2.Parent = buttonContainer3
		local statusLabel2 = Instance.new("TextLabel")
		statusLabel2.Size = UDim2.new(1, 0, 0, 25)
		statusLabel2.Position = UDim2.new(0, 0, 0, 80)
		statusLabel2.BackgroundTransparency = 1
		statusLabel2.Text = "Width: 1.00x"
		statusLabel2.TextColor3 = Color3.new(1, 1, 1)
		statusLabel2.TextSize = 12
		statusLabel2.Font = Enum.Font.GothamBold
		statusLabel2.TextXAlignment = Enum.TextXAlignment.Left
		statusLabel2.Parent = titleFrame
		local sliderFrame = Instance.new("Frame")
		sliderFrame.Size = UDim2.new(1, -20, 0, 6)
		sliderFrame.Position = UDim2.new(0, 10, 0, 115)
		sliderFrame.BackgroundColor3 = Color3.new(0, 0, 0)
		sliderFrame.BackgroundTransparency = 0.5
		sliderFrame.BorderSizePixel = 0
		sliderFrame.Parent = titleFrame
		local sliderCorner2 = Instance.new("UICorner")
		sliderCorner2.CornerRadius = UDim.new(0, 3)
		sliderCorner2.Parent = sliderFrame
		local fillFrame = Instance.new("Frame")
		fillFrame.Size = UDim2.new(0, 14, 0, 14)
		fillFrame.Position = UDim2.new(0.5, -7, 0.5, -7)
		fillFrame.BackgroundColor3 = Color3.new(1, 1, 1)
		fillFrame.BackgroundTransparency = 0.2
		fillFrame.BorderSizePixel = 0
		fillFrame.Parent = sliderFrame
		local fillCorner = Instance.new("UICorner")
		fillCorner.CornerRadius = UDim.new(0, 7)
		fillCorner.Parent = fillFrame
		local toggleButton2 = Instance.new("TextButton")
		toggleButton2.Size = UDim2.new(0, 100, 0, 30)
		toggleButton2.Position = UDim2.new(0.5, -50, 0, 160)
		toggleButton2.BackgroundColor3 = Color3.new(0, 0, 0)
		toggleButton2.BackgroundTransparency = 0.5
		toggleButton2.Text = "Reset Size"
		toggleButton2.TextColor3 = Color3.new(1, 1, 1)
		toggleButton2.TextSize = 11
		toggleButton2.Font = Enum.Font.Gotham
		toggleButton2.BorderSizePixel = 0
		toggleButton2.Parent = titleFrame
		local buttonCorner3 = Instance.new("UICorner")
		buttonCorner3.CornerRadius = UDim.new(0, 10)
		buttonCorner3.Parent = toggleButton2
		local isToggled2 = false
		local isEnabled2 = false
		local function updateSlider(sliderValue)
			-- upvalues: (ref) v_u_23, (ref) v_u_552, (ref) v_u_549, (ref) v_u_10, (ref) v_u_246
			local minValue = 0.1
			scaleSettings.heightScale = minValue * math.pow(100 / minValue, sliderValue)
			buttonContainer3.Position = UDim2.new(sliderValue, -7, 0.5, -7)
			titleLabel3.Text = string.format("Height: %.2fx", scaleSettings.heightScale)
			if isInitialized then
				applyAnimation()
			end
		end
		local function applyTransparency(transparencyLevel)
			-- upvalues: (ref) v_u_23, (ref) v_u_557, (ref) v_u_554, (ref) v_u_10, (ref) v_u_246
			local fadeSpeed = 0.1
			scaleSettings.widthScale = fadeSpeed * math.pow(100 / fadeSpeed, transparencyLevel)
			fillFrame.Position = UDim2.new(transparencyLevel, -7, 0.5, -7)
			statusLabel2.Text = string.format("Width: %.2fx", scaleSettings.widthScale)
			if isInitialized then
				applyAnimation()
			end
		end
		local function hideBodyParts(partList)
			-- upvalues: (ref) v_u_550, (ref) v_u_565
			updateSlider((math.clamp((partList.Position.X - contentFrame2.AbsolutePosition.X) / contentFrame2.AbsoluteSize.X, 0, 1)))
		end
		local function showBodyParts(character4)
			-- upvalues: (ref) v_u_555, (ref) v_u_568
			applyTransparency((math.clamp((character4.Position.X - sliderFrame.AbsolutePosition.X) / sliderFrame.AbsoluteSize.X, 0, 1)))
		end
		buttonContainer3.InputBegan:Connect(function(player5)
			-- upvalues: (ref) v_u_561, (ref) v_u_570
			if player5.UserInputType == Enum.UserInputType.MouseButton1 or player5.UserInputType == Enum.UserInputType.Touch then
				isToggled2 = true
				hideBodyParts(player5)
			end
		end)
		fillFrame.InputBegan:Connect(function(bodyPart)
			-- upvalues: (ref) v_u_562, (ref) v_u_572
			if bodyPart.UserInputType == Enum.UserInputType.MouseButton1 or bodyPart.UserInputType == Enum.UserInputType.Touch then
				isEnabled2 = true
				showBodyParts(bodyPart)
			end
		end)
		userInputService.InputChanged:Connect(function(transparency)
			-- upvalues: (ref) v_u_561, (ref) v_u_570, (ref) v_u_562, (ref) v_u_572
			if isToggled2 and (transparency.UserInputType == Enum.UserInputType.MouseMovement or transparency.UserInputType == Enum.UserInputType.Touch) then
				hideBodyParts(transparency)
			end
			if isEnabled2 and (transparency.UserInputType == Enum.UserInputType.MouseMovement or transparency.UserInputType == Enum.UserInputType.Touch) then
				showBodyParts(transparency)
			end
		end)
		userInputService.InputEnded:Connect(function(recursive)
			-- upvalues: (ref) v_u_561, (ref) v_u_562
			if recursive.UserInputType == Enum.UserInputType.MouseButton1 or recursive.UserInputType == Enum.UserInputType.Touch then
				isToggled2 = false
				isEnabled2 = false
			end
		end)
		toggleButton2.MouseButton1Click:Connect(function()
			-- upvalues: (ref) v_u_23, (ref) v_u_552, (ref) v_u_557, (ref) v_u_549, (ref) v_u_554, (ref) v_u_10, (ref) v_u_246
			scaleSettings.heightScale = 1
			scaleSettings.widthScale = 1
			buttonContainer3.Position = UDim2.new(0.5, -7, 0.5, -7)
			fillFrame.Position = UDim2.new(0.5, -7, 0.5, -7)
			titleLabel3.Text = "Height: 1.00x"
			statusLabel2.Text = "Width: 1.00x"
			if isInitialized then
				applyAnimation()
			end
		end)
		toggleButton2.MouseEnter:Connect(function()
			-- upvalues: (ref) v_u_559
			toggleButton2.BackgroundTransparency = 0.3
		end)
		toggleButton2.MouseLeave:Connect(function()
			-- upvalues: (ref) v_u_559
			toggleButton2.BackgroundTransparency = 0.5
		end)
		local settingsFrame2 = Instance.new("Frame")
		settingsFrame2.Size = UDim2.new(1, -16, 1, -175)
		settingsFrame2.Position = UDim2.new(0, 8, 0, 105)
		settingsFrame2.BackgroundTransparency = 1
		settingsFrame2.Visible = false
		settingsFrame2.Parent = mainFrame
		local descriptionLabel = Instance.new("TextLabel")
		descriptionLabel.Size = UDim2.new(1, 0, 0, 20)
		descriptionLabel.Position = UDim2.new(0, 0, 0, 0)
		descriptionLabel.BackgroundTransparency = 1
		descriptionLabel.Text = "Hide Bodyparts"
		descriptionLabel.TextColor3 = Color3.new(1, 1, 1)
		descriptionLabel.TextSize = 12
		descriptionLabel.Font = Enum.Font.GothamBold
		descriptionLabel.TextXAlignment = Enum.TextXAlignment.Left
		descriptionLabel.Parent = settingsFrame2
		local actionButton = Instance.new("TextButton")
		actionButton.Size = UDim2.new(1, 0, 0, 28)
		actionButton.Position = UDim2.new(0, 0, 0, 25)
		actionButton.BackgroundColor3 = Color3.new(0, 0, 0)
		actionButton.BackgroundTransparency = 0.5
		actionButton.Text = " Select Body Parts..."
		actionButton.TextColor3 = Color3.new(1, 1, 1)
		actionButton.TextSize = 10
		actionButton.Font = Enum.Font.Gotham
		actionButton.TextXAlignment = Enum.TextXAlignment.Left
		actionButton.BorderSizePixel = 0
		actionButton.Parent = settingsFrame2
		local buttonCorner4 = Instance.new("UICorner")
		buttonCorner4.CornerRadius = UDim.new(0, 10)
		buttonCorner4.Parent = actionButton
		local uiPadding = Instance.new("UIPadding")
		uiPadding.PaddingLeft = UDim.new(0, 10)
		uiPadding.Parent = actionButton
		local defaultBodyParts = {
			"Head",
			"UpperTorso",
			"LowerTorso",
			"LeftUpperArm",
			"LeftLowerArm",
			"LeftHand",
			"RightUpperArm",
			"RightLowerArm",
			"RightHand",
			"LeftUpperLeg",
			"LeftLowerLeg",
			"LeftFoot",
			"RightUpperLeg",
			"RightLowerLeg",
			"RightFoot",
			"Torso",
			"Left Arm",
			"Right Arm",
			"Left Leg",
			"Right Leg"
		}
		local function getBodyPart(partName5)
			-- upvalues: (ref) v_u_10, (ref) v_u_12, (ref) v_u_11
			if isInitialized and (animationFolder and animationTrack) then
				local workspacePart = animationFolder:FindFirstChild(partName5)
				local characterPart2 = animationTrack:FindFirstChild(partName5)
				if workspacePart and workspacePart:IsA("BasePart") then
					if characterPart2 and characterPart2:IsA("BasePart") then
						workspacePart.Transparency = 1
						workspacePart.CanCollide = false
						if partName5 == "Head" then
							local child3, index2, childPart2 = ipairs(workspacePart:GetChildren())
							while true do
								local children
								childPart2, children = child3(index2, childPart2)
								if childPart2 == nil then
									break
								end
								if children:IsA("Decal") then
									children.Transparency = 1
								end
							end
						end
						_G.hiddenBodyParts[partName5] = true
						print("\226\156\147 Hidden:", partName5)
					end
				else
					return
				end
			else
				return
			end
		end
		local function setBodyPartTransparency(partName6)
			_G.hiddenBodyParts[partName6] = nil
			print("\226\156\147 Shown:", partName6)
		end
		local isMenuOpen = false
		local menuContainer = nil
		actionButton.MouseButton1Click:Connect(function()
			-- upvalues: (ref) v_u_593, (ref) v_u_594, (ref) v_u_10, (ref) v_u_12, (ref) v_u_462, (ref) v_u_579, (ref) v_u_582, (ref) v_u_592, (ref) v_u_590
			if isMenuOpen then
				if menuContainer then
					menuContainer:Destroy()
				end
				isMenuOpen = false
				return
			elseif isInitialized and animationFolder then
				isMenuOpen = true
				menuContainer = Instance.new("Frame")
				menuContainer.Size = UDim2.new(1, 0, 0, 150)
				menuContainer.Position = UDim2.new(0, 0, 1, 3)
				menuContainer.BackgroundColor3 = Color3.new(0, 0, 0)
				menuContainer.BackgroundTransparency = 0.3
				menuContainer.BorderSizePixel = 0
				menuContainer.ZIndex = 10
				menuContainer.Parent = actionButton
				local menuCorner = Instance.new("UICorner")
				menuCorner.CornerRadius = UDim.new(0, 10)
				menuCorner.Parent = menuContainer
				local scrollFrame = Instance.new("ScrollingFrame")
				scrollFrame.Size = UDim2.new(1, -6, 1, -6)
				scrollFrame.Position = UDim2.new(0, 3, 0, 3)
				scrollFrame.BackgroundTransparency = 1
				scrollFrame.ScrollBarThickness = 3
				scrollFrame.ScrollBarImageColor3 = Color3.new(1, 1, 1)
				scrollFrame.ScrollBarImageTransparency = 0.5
				scrollFrame.BorderSizePixel = 0
				scrollFrame.ZIndex = 10
				scrollFrame.Parent = menuContainer
				local listLayout3 = Instance.new("UIListLayout")
				listLayout3.Padding = UDim.new(0, 2)
				listLayout3.SortOrder = Enum.SortOrder.Name
				listLayout3.Parent = scrollFrame
				local index3, entry5, value5 = ipairs(defaultBodyParts)
				while true do
					local currentPlayer
					value5, currentPlayer = index3(entry5, value5)
					if value5 == nil then
						break
					end
					if animationFolder:FindFirstChild(currentPlayer) ~= nil then
						local toggleButton3 = Instance.new("TextButton")
						toggleButton3.Size = UDim2.new(1, 0, 0, 24)
						toggleButton3.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
						toggleButton3.BackgroundTransparency = 0.3
						toggleButton3.Text = (_G.hiddenBodyParts[currentPlayer] and "\226\156\147 " or "   ") .. currentPlayer
						toggleButton3.TextColor3 = _G.hiddenBodyParts[currentPlayer] and Color3.fromRGB(100, 200, 255) or Color3.new(1, 1, 1)
						toggleButton3.TextSize = 9
						toggleButton3.Font = Enum.Font.Gotham
						toggleButton3.TextXAlignment = Enum.TextXAlignment.Left
						toggleButton3.BorderSizePixel = 0
						toggleButton3.ZIndex = 10
						toggleButton3.Parent = scrollFrame
						local menuPadding = Instance.new("UIPadding")
						menuPadding.PaddingLeft = UDim.new(0, 5)
						menuPadding.Parent = toggleButton3
						toggleButton3.MouseButton1Click:Connect(function()
							-- upvalues: (ref) v_u_601, (ref) v_u_592, (ref) v_u_462, (ref) v_u_590, (ref) v_u_602
							if _G.hiddenBodyParts[currentPlayer] then
								setBodyPartTransparency(currentPlayer)
								statusLabel.Text = currentPlayer .. " shown"
								statusLabel.TextColor3 = Color3.new(1, 0.7, 0.3)
							else
								getBodyPart(currentPlayer)
								statusLabel.Text = currentPlayer .. " hidden"
								statusLabel.TextColor3 = Color3.new(0.5, 1, 0.5)
							end
							spawn(function()
								-- upvalues: (ref) v_u_462
								wait(2)
								statusLabel.Text = "Ready"
								statusLabel.TextColor3 = Color3.new(0.7, 0.7, 0.7)
							end)
							toggleButton3.Text = (_G.hiddenBodyParts[currentPlayer] and "\226\156\147 " or "   ") .. currentPlayer
							toggleButton3.TextColor3 = _G.hiddenBodyParts[currentPlayer] and Color3.fromRGB(100, 200, 255) or Color3.new(1, 1, 1)
						end)
					end
				end
				spawn(function()
					-- upvalues: (ref) v_u_596, (ref) v_u_597
					wait(0.05)
					scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout3.AbsoluteContentSize.Y)
				end)
			else
				statusLabel.Text = "Enable reanimation first!"
				statusLabel.TextColor3 = Color3.new(1, 0.3, 0.3)
				spawn(function()
					-- upvalues: (ref) v_u_462
					wait(2)
					statusLabel.Text = "Ready"
					statusLabel.TextColor3 = Color3.new(0.7, 0.7, 0.7)
				end)
			end
		end)
		local buttonHeight = 60
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 0, 20)
		label.Position = UDim2.new(0, 0, 0, buttonHeight)
		label.BackgroundTransparency = 1
		label.Text = "Snake Mode"
		label.TextColor3 = Color3.new(1, 1, 1)
		label.TextSize = 12
		label.Font = Enum.Font.GothamBold
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = settingsFrame2
		local headerFrame2 = Instance.new("Frame")
		headerFrame2.Size = UDim2.new(0, 40, 0, 18)
		headerFrame2.Position = UDim2.new(1, -45, 0, buttonHeight + 1)
		headerFrame2.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
		headerFrame2.BorderSizePixel = 0
		headerFrame2.Parent = settingsFrame2
		local headerCorner = Instance.new("UICorner")
		headerCorner.CornerRadius = UDim.new(0, 9)
		headerCorner.Parent = headerFrame2
		local titleFrame2 = Instance.new("Frame")
		titleFrame2.Size = UDim2.new(0, 14, 0, 14)
		titleFrame2.Position = UDim2.new(0, 2, 0, 2)
		titleFrame2.BackgroundColor3 = Color3.new(0.7, 0.7, 0.7)
		titleFrame2.BorderSizePixel = 0
		titleFrame2.Parent = headerFrame2
		local titleCorner2 = Instance.new("UICorner")
		titleCorner2.CornerRadius = UDim.new(0, 7)
		titleCorner2.Parent = titleFrame2
		local closeButton2 = Instance.new("TextButton")
		closeButton2.Size = UDim2.new(1, 0, 1, 0)
		closeButton2.BackgroundTransparency = 1
		closeButton2.Text = ""
		closeButton2.Parent = headerFrame2
		closeButton2.MouseButton1Click:Connect(function()
			-- upvalues: (ref) v_u_10, (ref) v_u_462, (ref) v_u_26, (ref) v_u_33, (ref) v_u_34, (ref) v_u_35, (ref) v_u_6, (ref) v_u_606, (ref) v_u_608
			if isInitialized then
				isRendering = not isRendering
				eventListeners = {}
				connectionList = {}
				moduleDependencies = {}
				local tweenInfo2 = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
				if isRendering then
					tweenService:Create(headerFrame2, tweenInfo2, {
						["BackgroundColor3"] = Color3.fromRGB(0, 150, 255)
					}):Play()
					tweenService:Create(titleFrame2, tweenInfo2, {
						["Position"] = UDim2.new(1, -16, 0, 2),
						["BackgroundColor3"] = Color3.new(1, 1, 1)
					}):Play()
					statusLabel.Text = "Snake mode enabled"
					statusLabel.TextColor3 = Color3.new(0.5, 1, 0.5)
				else
					tweenService:Create(headerFrame2, tweenInfo2, {
						["BackgroundColor3"] = Color3.new(0.2, 0.2, 0.2)
					}):Play()
					tweenService:Create(titleFrame2, tweenInfo2, {
						["Position"] = UDim2.new(0, 2, 0, 2),
						["BackgroundColor3"] = Color3.new(0.7, 0.7, 0.7)
					}):Play()
					statusLabel.Text = "Snake mode disabled"
					statusLabel.TextColor3 = Color3.new(1, 0.7, 0.3)
				end
				spawn(function()
					-- upvalues: (ref) v_u_462
					wait(2)
					statusLabel.Text = "Ready"
					statusLabel.TextColor3 = Color3.new(0.7, 0.7, 0.7)
				end)
			else
				statusLabel.Text = "Enable reanimation first!"
				statusLabel.TextColor3 = Color3.new(1, 0.3, 0.3)
				spawn(function()
					-- upvalues: (ref) v_u_462
					wait(2)
					statusLabel.Text = "Ready"
					statusLabel.TextColor3 = Color3.new(0.7, 0.7, 0.7)
				end)
			end
		end)
		local titleLabel4 = Instance.new("TextLabel")
		titleLabel4.Size = UDim2.new(1, -60, 0, 18)
		titleLabel4.Position = UDim2.new(0, 0, 0, buttonHeight + 25)
		titleLabel4.BackgroundTransparency = 1
		titleLabel4.Text = "Distance: 1.00"
		titleLabel4.TextColor3 = Color3.new(0.9, 0.9, 0.9)
		titleLabel4.TextSize = 10
		titleLabel4.Font = Enum.Font.Gotham
		titleLabel4.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel4.Parent = settingsFrame2
		local contentFrame3 = Instance.new("Frame")
		contentFrame3.Size = UDim2.new(1, -10, 0, 4)
		contentFrame3.Position = UDim2.new(0, 5, 0, buttonHeight + 45)
		contentFrame3.BackgroundColor3 = Color3.new(0, 0, 0)
		contentFrame3.BackgroundTransparency = 0.5
		contentFrame3.BorderSizePixel = 0
		contentFrame3.Parent = settingsFrame2
		local contentCorner3 = Instance.new("UICorner")
		contentCorner3.CornerRadius = UDim.new(0, 2)
		contentCorner3.Parent = contentFrame3
		local itemFrame = Instance.new("Frame")
		itemFrame.Size = UDim2.new(0, 12, 0, 12)
		itemFrame.Position = UDim2.new(0.18, -6, 0.5, -6)
		itemFrame.BackgroundColor3 = Color3.new(1, 1, 1)
		itemFrame.BackgroundTransparency = 0.2
		itemFrame.BorderSizePixel = 0
		itemFrame.Parent = contentFrame3
		local itemCorner = Instance.new("UICorner")
		itemCorner.CornerRadius = UDim.new(0, 6)
		itemCorner.Parent = itemFrame
		local isInitialized2 = false
		local function createButton(buttonText)
			-- upvalues: (ref) v_u_27, (ref) v_u_615, (ref) v_u_612
			timeStep = 0.2 + buttonText * 4.8
			itemFrame.Position = UDim2.new(buttonText, -6, 0.5, -6)
			titleLabel4.Text = string.format("Distance: %.2f", timeStep)
		end
		local function updateUI(targetFrame)
			-- upvalues: (ref) v_u_613, (ref) v_u_619
			createButton((math.clamp((targetFrame.Position.X - contentFrame3.AbsolutePosition.X) / contentFrame3.AbsoluteSize.X, 0, 1)))
		end
		itemFrame.InputBegan:Connect(function(isVisible2)
			-- upvalues: (ref) v_u_617, (ref) v_u_621
			if isVisible2.UserInputType == Enum.UserInputType.MouseButton1 or isVisible2.UserInputType == Enum.UserInputType.Touch then
				isInitialized2 = true
				updateUI(isVisible2)
			end
		end)
		userInputService.InputChanged:Connect(function(animationStyle)
			-- upvalues: (ref) v_u_617, (ref) v_u_621
			if isInitialized2 and (animationStyle.UserInputType == Enum.UserInputType.MouseMovement or animationStyle.UserInputType == Enum.UserInputType.Touch) then
				updateUI(animationStyle)
			end
		end)
		userInputService.InputEnded:Connect(function(easingDirection)
			-- upvalues: (ref) v_u_617
			if easingDirection.UserInputType == Enum.UserInputType.MouseButton1 or easingDirection.UserInputType == Enum.UserInputType.Touch then
				isInitialized2 = false
			end
		end)
		local baseHeight = 140
		local statusLabel3 = Instance.new("TextLabel")
		statusLabel3.Size = UDim2.new(1, 0, 0, 20)
		statusLabel3.Position = UDim2.new(0, 0, 0, baseHeight)
		statusLabel3.BackgroundTransparency = 1
		statusLabel3.Text = "Cover Sky (need layered clothing)"
		statusLabel3.TextColor3 = Color3.new(1, 1, 1)
		statusLabel3.TextSize = 12
		statusLabel3.Font = Enum.Font.GothamBold
		statusLabel3.TextXAlignment = Enum.TextXAlignment.Left
		statusLabel3.Parent = settingsFrame2
		local settingsFrame3 = Instance.new("Frame")
		settingsFrame3.Size = UDim2.new(0, 40, 0, 18)
		settingsFrame3.Position = UDim2.new(1, -45, 0, baseHeight + 1)
		settingsFrame3.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
		settingsFrame3.BorderSizePixel = 0
		settingsFrame3.Parent = settingsFrame2
		local settingsCorner2 = Instance.new("UICorner")
		settingsCorner2.CornerRadius = UDim.new(0, 9)
		settingsCorner2.Parent = settingsFrame3
		local optionFrame2 = Instance.new("Frame")
		optionFrame2.Size = UDim2.new(0, 14, 0, 14)
		optionFrame2.Position = UDim2.new(0, 2, 0, 2)
		optionFrame2.BackgroundColor3 = Color3.new(0.7, 0.7, 0.7)
		optionFrame2.BorderSizePixel = 0
		optionFrame2.Parent = settingsFrame3
		local optionCorner = Instance.new("UICorner")
		optionCorner.CornerRadius = UDim.new(0, 7)
		optionCorner.Parent = optionFrame2
		local saveButton2 = Instance.new("TextButton")
		saveButton2.Size = UDim2.new(1, 0, 1, 0)
		saveButton2.BackgroundTransparency = 1
		saveButton2.Text = ""
		saveButton2.Parent = settingsFrame3
		saveButton2.MouseButton1Click:Connect(function()
			-- upvalues: (ref) v_u_10, (ref) v_u_462, (ref) v_u_30, (ref) v_u_6, (ref) v_u_627, (ref) v_u_629
			if isInitialized then
				isPaused = not isPaused
				local tweenInfo3 = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
				if isPaused then
					tweenService:Create(settingsFrame3, tweenInfo3, {
						["BackgroundColor3"] = Color3.fromRGB(0, 150, 255)
					}):Play()
					tweenService:Create(optionFrame2, tweenInfo3, {
						["Position"] = UDim2.new(1, -16, 0, 2),
						["BackgroundColor3"] = Color3.new(1, 1, 1)
					}):Play()
					statusLabel.Text = "Cover Sky enabled"
					statusLabel.TextColor3 = Color3.new(0.5, 1, 0.5)
				else
					tweenService:Create(settingsFrame3, tweenInfo3, {
						["BackgroundColor3"] = Color3.new(0.2, 0.2, 0.2)
					}):Play()
					tweenService:Create(optionFrame2, tweenInfo3, {
						["Position"] = UDim2.new(0, 2, 0, 2),
						["BackgroundColor3"] = Color3.new(0.7, 0.7, 0.7)
					}):Play()
					statusLabel.Text = "Cover Sky disabled"
					statusLabel.TextColor3 = Color3.new(1, 0.7, 0.3)
				end
				spawn(function()
					-- upvalues: (ref) v_u_462
					wait(2)
					statusLabel.Text = "Ready"
					statusLabel.TextColor3 = Color3.new(0.7, 0.7, 0.7)
				end)
			else
				statusLabel.Text = "Enable reanimation first!"
				statusLabel.TextColor3 = Color3.new(1, 0.3, 0.3)
				spawn(function()
					-- upvalues: (ref) v_u_462
					wait(2)
					statusLabel.Text = "Ready"
					statusLabel.TextColor3 = Color3.new(0.7, 0.7, 0.7)
				end)
			end
		end)
		local totalHeight = baseHeight + 30
		local descriptionLabel2 = Instance.new("TextLabel")
		descriptionLabel2.Size = UDim2.new(1, 0, 0, 20)
		descriptionLabel2.Position = UDim2.new(0, 0, 0, totalHeight)
		descriptionLabel2.BackgroundTransparency = 1
		descriptionLabel2.Text = "Cover Ground (need layered clothing)"
		descriptionLabel2.TextColor3 = Color3.new(1, 1, 1)
		descriptionLabel2.TextSize = 12
		descriptionLabel2.Font = Enum.Font.GothamBold
		descriptionLabel2.TextXAlignment = Enum.TextXAlignment.Left
		descriptionLabel2.Parent = settingsFrame2
		local footerFrame = Instance.new("Frame")
		footerFrame.Size = UDim2.new(0, 40, 0, 18)
		footerFrame.Position = UDim2.new(1, -45, 0, totalHeight + 1)
		footerFrame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
		footerFrame.BorderSizePixel = 0
		footerFrame.Parent = settingsFrame2
		local footerCorner = Instance.new("UICorner")
		footerCorner.CornerRadius = UDim.new(0, 9)
		footerCorner.Parent = footerFrame
		local controlFrame = Instance.new("Frame")
		controlFrame.Size = UDim2.new(0, 14, 0, 14)
		controlFrame.Position = UDim2.new(0, 2, 0, 2)
		controlFrame.BackgroundColor3 = Color3.new(0.7, 0.7, 0.7)
		controlFrame.BorderSizePixel = 0
		controlFrame.Parent = footerFrame
		local controlCorner = Instance.new("UICorner")
		controlCorner.CornerRadius = UDim.new(0, 7)
		controlCorner.Parent = controlFrame
		local applyButton = Instance.new("TextButton")
		applyButton.Size = UDim2.new(1, 0, 1, 0)
		applyButton.BackgroundTransparency = 1
		applyButton.Text = ""
		applyButton.Parent = footerFrame
		applyButton.MouseButton1Click:Connect(function()
			-- upvalues: (ref) v_u_10, (ref) v_u_462, (ref) v_u_6, (ref) v_u_635, (ref) v_u_637
			if isInitialized then
				groundModeEnabled = not groundModeEnabled
				local tweenInfo4 = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
				if groundModeEnabled then
					tweenService:Create(footerFrame, tweenInfo4, {
						["BackgroundColor3"] = Color3.fromRGB(0, 150, 255)
					}):Play()
					tweenService:Create(controlFrame, tweenInfo4, {
						["Position"] = UDim2.new(1, -16, 0, 2),
						["BackgroundColor3"] = Color3.new(1, 1, 1)
					}):Play()
					statusLabel.Text = "Cover Ground enabled"
					statusLabel.TextColor3 = Color3.new(0.5, 1, 0.5)
				else
					tweenService:Create(footerFrame, tweenInfo4, {
						["BackgroundColor3"] = Color3.new(0.2, 0.2, 0.2)
					}):Play()
					tweenService:Create(controlFrame, tweenInfo4, {
						["Position"] = UDim2.new(0, 2, 0, 2),
						["BackgroundColor3"] = Color3.new(0.7, 0.7, 0.7)
					}):Play()
					statusLabel.Text = "Cover Ground disabled"
					statusLabel.TextColor3 = Color3.new(1, 0.7, 0.3)
				end
				spawn(function()
					-- upvalues: (ref) v_u_462
					wait(2)
					statusLabel.Text = "Ready"
					statusLabel.TextColor3 = Color3.new(0.7, 0.7, 0.7)
				end)
			else
				statusLabel.Text = "Enable reanimation first!"
				statusLabel.TextColor3 = Color3.new(1, 0.3, 0.3)
				spawn(function()
					-- upvalues: (ref) v_u_462
					wait(2)
					statusLabel.Text = "Ready"
					statusLabel.TextColor3 = Color3.new(0.7, 0.7, 0.7)
				end)
			end
		end)
		local resetButton2 = Instance.new("TextButton")
		resetButton2.Size = UDim2.new(0, 60, 0, 22)
		resetButton2.Position = UDim2.new(0, 8, 0, 105)
		resetButton2.BackgroundColor3 = Color3.new(0, 0, 0)
		resetButton2.BackgroundTransparency = 0.5
		resetButton2.Text = "Add"
		resetButton2.TextColor3 = Color3.new(1, 1, 1)
		resetButton2.TextSize = 10
		resetButton2.Font = Enum.Font.Gotham
		resetButton2.BorderSizePixel = 0
		resetButton2.Parent = mainFrame
		local resetCorner2 = Instance.new("UICorner")
		resetCorner2.CornerRadius = UDim.new(0, 9)
		resetCorner2.Parent = resetButton2
		local playerCharacter2 = "all"
		local isMenuOpen2 = false
		local isDragging = false
		local dragOffset = false
		local mainFrame2 = nil
		local isInputFocused = false
		Instance.new("TextButton")
		local toggleButton4 = Instance.new("TextButton")
		toggleButton4.Size = UDim2.new(0, 25, 0, 25)
		toggleButton4.Position = UDim2.new(1, -33, 1, -33)
		toggleButton4.BackgroundColor3 = Color3.new(0, 0, 0)
		toggleButton4.BackgroundTransparency = 0.5
		toggleButton4.Text = "i"
		toggleButton4.TextColor3 = Color3.new(1, 1, 1)
		toggleButton4.TextSize = 14
		toggleButton4.Font = Enum.Font.GothamBold
		toggleButton4.BorderSizePixel = 0
		toggleButton4.ZIndex = 10
		toggleButton4.Visible = false
		toggleButton4.Parent = mainFrame
		task.defer(function()
			-- upvalues: (ref) v_u_649, (ref) v_u_643
			toggleButton4.Visible = playerCharacter2 == "custom" or playerCharacter2 == "states"
		end)
		local toggleButtonCorner = Instance.new("UICorner")
		toggleButtonCorner.CornerRadius = UDim.new(1, 0)
		toggleButtonCorner.Parent = toggleButton4
		toggleButton4.MouseEnter:Connect(function()
			-- upvalues: (ref) v_u_649
			toggleButton4.BackgroundTransparency = 0.3
		end)
		toggleButton4.MouseLeave:Connect(function()
			-- upvalues: (ref) v_u_649
			toggleButton4.BackgroundTransparency = 0.5
		end)
		local menuTitle = nil
		local function updateMenuPosition()
			-- upvalues: (ref) v_u_651, (ref) v_u_443
			if menuTitle then
				menuTitle:Destroy()
			end
			menuTitle = Instance.new("Frame")
			menuTitle.Size = UDim2.new(0, 380, 0, 300)
			menuTitle.Position = UDim2.new(0.5, -190, 0.5, -150)
			menuTitle.BackgroundColor3 = Color3.new(0, 0, 0)
			menuTitle.BackgroundTransparency = 0.6
			menuTitle.BorderSizePixel = 0
			menuTitle.ZIndex = 100
			menuTitle.Parent = screenGuiInstance
			local titleCorner3 = Instance.new("UICorner")
			titleCorner3.CornerRadius = UDim.new(0, 15)
			titleCorner3.Parent = menuTitle
			local titleLabel5 = Instance.new("TextLabel")
			titleLabel5.Size = UDim2.new(1, -40, 0, 30)
			titleLabel5.Position = UDim2.new(0, 10, 0, 5)
			titleLabel5.BackgroundTransparency = 1
			titleLabel5.Text = "How to Convert Animations"
			titleLabel5.TextColor3 = Color3.new(1, 1, 1)
			titleLabel5.TextSize = 14
			titleLabel5.Font = Enum.Font.GothamBold
			titleLabel5.TextXAlignment = Enum.TextXAlignment.Left
			titleLabel5.ZIndex = 101
			titleLabel5.Parent = menuTitle
			local closeButton3 = Instance.new("TextButton")
			closeButton3.Size = UDim2.new(0, 25, 0, 25)
			closeButton3.Position = UDim2.new(1, -30, 0, 5)
			closeButton3.BackgroundColor3 = Color3.new(0, 0, 0)
			closeButton3.BackgroundTransparency = 0.7
			closeButton3.Text = "\195\151"
			closeButton3.TextColor3 = Color3.new(1, 1, 1)
			closeButton3.TextSize = 18
			closeButton3.Font = Enum.Font.Gotham
			closeButton3.BorderSizePixel = 0
			closeButton3.ZIndex = 101
			closeButton3.Parent = menuTitle
			local closeButtonCorner = Instance.new("UICorner")
			closeButtonCorner.CornerRadius = UDim.new(0, 10)
			closeButtonCorner.Parent = closeButton3
			closeButton3.MouseButton1Click:Connect(function()
				-- upvalues: (ref) v_u_651
				menuTitle:Destroy()
				menuTitle = nil
			end)
			local statusLabel4 = Instance.new("TextLabel")
			statusLabel4.Size = UDim2.new(1, -20, 0, 150)
			statusLabel4.Position = UDim2.new(0, 10, 0, 40)
			statusLabel4.BackgroundTransparency = 1
			statusLabel4.Text = "1. Open Roblox Studio and create a new game\r\n\r\n2. Create a Folder in Workspace named \"Keyframes\"\r\n\r\n3. Put all your KeyframeSequences in the folder\r\n   (Each animation should be named differently)\r\n\r\n4. Publish your game to Roblox\r\n\r\n5. Join the published game with your executor\r\n\r\n6. Execute the converter script below:"
			statusLabel4.TextColor3 = Color3.new(1, 1, 1)
			statusLabel4.TextSize = 11
			statusLabel4.Font = Enum.Font.Gotham
			statusLabel4.TextXAlignment = Enum.TextXAlignment.Left
			statusLabel4.TextYAlignment = Enum.TextYAlignment.Top
			statusLabel4.TextWrapped = true
			statusLabel4.ZIndex = 101
			statusLabel4.Parent = menuTitle
			local containerFrame = Instance.new("Frame")
			containerFrame.Size = UDim2.new(1, -20, 0, 50)
			containerFrame.Position = UDim2.new(0, 10, 0, 195)
			containerFrame.BackgroundColor3 = Color3.new(0, 0, 0)
			containerFrame.BackgroundTransparency = 0.5
			containerFrame.BorderSizePixel = 0
			containerFrame.ZIndex = 101
			containerFrame.Parent = menuTitle
			local containerCorner = Instance.new("UICorner")
			containerCorner.CornerRadius = UDim.new(0, 10)
			containerCorner.Parent = containerFrame
			local inputBox2 = Instance.new("TextBox")
			inputBox2.Size = UDim2.new(1, -10, 1, -10)
			inputBox2.Position = UDim2.new(0, 10, 0, 5)
			inputBox2.BackgroundTransparency = 1
			inputBox2.Text = "loadstring(game:HttpGet(\"https://akadmin-bzk.pages.dev/Converter.lua\"))()"
			inputBox2.TextColor3 = Color3.new(0.8, 1, 0.8)
			inputBox2.TextSize = 10
			inputBox2.Font = Enum.Font.Code
			inputBox2.TextWrapped = true
			inputBox2.TextEditable = false
			inputBox2.TextXAlignment = Enum.TextXAlignment.Left
			inputBox2.TextYAlignment = Enum.TextYAlignment.Center
			inputBox2.ClearTextOnFocus = false
			inputBox2.ZIndex = 102
			inputBox2.Parent = containerFrame
			local submitButton = Instance.new("TextButton")
			submitButton.Size = UDim2.new(0, 60, 0, 25)
			submitButton.Position = UDim2.new(0.5, -30, 1, 15)
			submitButton.BackgroundColor3 = Color3.new(0, 0, 0)
			submitButton.BackgroundTransparency = 0.3
			submitButton.Text = "Copy"
			submitButton.TextColor3 = Color3.new(1, 1, 1)
			submitButton.TextSize = 11
			submitButton.Font = Enum.Font.Gotham
			submitButton.BorderSizePixel = 0
			submitButton.ZIndex = 102
			submitButton.Parent = containerFrame
			local submitButtonCorner = Instance.new("UICorner")
			submitButtonCorner.CornerRadius = UDim.new(0, 8)
			submitButtonCorner.Parent = submitButton
			submitButton.MouseEnter:Connect(function()
				-- upvalues: (ref) v_u_660
				submitButton.BackgroundTransparency = 0.1
			end)
			submitButton.MouseLeave:Connect(function()
				-- upvalues: (ref) v_u_660
				submitButton.BackgroundTransparency = 0.3
			end)
			submitButton.MouseButton1Click:Connect(function()
				-- upvalues: (ref) v_u_659, (ref) v_u_660
				setclipboard(inputBox2.Text)
				submitButton.Text = "Copied!"
				spawn(function()
					-- upvalues: (ref) v_u_660
					wait(1.5)
					submitButton.Text = "Copy"
				end)
			end)
			local inputLabel = Instance.new("TextLabel")
			inputLabel.Size = UDim2.new(1, -20, 0, 25)
			inputLabel.Position = UDim2.new(0, 10, 0, 240)
			inputLabel.BackgroundTransparency = 1
			inputLabel.Text = "After converting, find keyframe codes in your executor\'s workspace folder"
			inputLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
			inputLabel.TextSize = 9
			inputLabel.Font = Enum.Font.Gotham
			inputLabel.TextWrapped = true
			inputLabel.TextXAlignment = Enum.TextXAlignment.Center
			inputLabel.ZIndex = 101
			inputLabel.Parent = menuTitle
		end
		toggleButton4.MouseButton1Click:Connect(function()
			-- upvalues: (ref) v_u_663
			updateMenuPosition()
		end)
		local function onSubmitInput()
			-- upvalues: (ref) v_u_643, (ref) v_u_649
			if playerCharacter2 == "custom" or playerCharacter2 == "states" then
				toggleButton4.Visible = true
			else
				toggleButton4.Visible = false
			end
		end
		local settingsFrame4 = Instance.new("Frame")
		settingsFrame4.Size = UDim2.new(1, -16, 0, 65)
		settingsFrame4.Position = UDim2.new(0, 8, 1, -70)
		settingsFrame4.BackgroundTransparency = 1
		settingsFrame4.Parent = mainFrame
		local settingsLabel = Instance.new("TextLabel")
		settingsLabel.Size = UDim2.new(0, 40, 0, 18)
		settingsLabel.Position = UDim2.new(0, 0, 0, 0)
		settingsLabel.BackgroundTransparency = 1
		settingsLabel.Text = "Speed:"
		settingsLabel.TextColor3 = Color3.new(1, 1, 1)
		settingsLabel.TextSize = 9
		settingsLabel.Font = Enum.Font.Gotham
		settingsLabel.TextXAlignment = Enum.TextXAlignment.Left
		settingsLabel.Parent = settingsFrame4
		local sliderBackground = Instance.new("Frame")
		sliderBackground.Size = UDim2.new(1, -100, 0, 6)
		sliderBackground.Position = UDim2.new(0, 45, 0, 7)
		sliderBackground.BackgroundColor3 = Color3.new(0, 0, 0)
		sliderBackground.BackgroundTransparency = 0.5
		sliderBackground.BorderSizePixel = 0
		sliderBackground.Parent = settingsFrame4
		local sliderBackgroundCorner = Instance.new("UICorner")
		sliderBackgroundCorner.CornerRadius = UDim.new(0, 3)
		sliderBackgroundCorner.Parent = sliderBackground
		local sliderHandle = Instance.new("Frame")
		sliderHandle.Size = UDim2.new(0, 12, 0, 12)
		sliderHandle.Position = UDim2.new(0.5, -6, 0.5, -6)
		sliderHandle.BackgroundColor3 = Color3.new(1, 1, 1)
		sliderHandle.BackgroundTransparency = 0.2
		sliderHandle.BorderSizePixel = 0
		sliderHandle.Parent = sliderBackground
		local sliderHandleCorner = Instance.new("UICorner")
		sliderHandleCorner.CornerRadius = UDim.new(0, 6)
		sliderHandleCorner.Parent = sliderHandle
		local sliderValueLabel = Instance.new("TextLabel")
		sliderValueLabel.Size = UDim2.new(0, 40, 0, 18)
		sliderValueLabel.Position = UDim2.new(0, 215, 0, 0)
		sliderValueLabel.BackgroundTransparency = 1
		sliderValueLabel.Text = "5"
		sliderValueLabel.TextColor3 = Color3.new(1, 1, 1)
		sliderValueLabel.TextSize = 9
		sliderValueLabel.Font = Enum.Font.Gotham
		sliderValueLabel.TextXAlignment = Enum.TextXAlignment.Left
		sliderValueLabel.Parent = settingsFrame4
		local resetButton3 = Instance.new("TextButton")
		resetButton3.Size = UDim2.new(0, 30, 0, 14)
		resetButton3.Position = UDim2.new(1, -30, 0, 2)
		resetButton3.BackgroundColor3 = Color3.new(0, 0, 0)
		resetButton3.BackgroundTransparency = 0.5
		resetButton3.Text = "Reset"
		resetButton3.TextColor3 = Color3.new(1, 1, 1)
		resetButton3.TextSize = 7
		resetButton3.Font = Enum.Font.Gotham
		resetButton3.BorderSizePixel = 0
		resetButton3.Parent = settingsFrame4
		local resetButtonCorner = Instance.new("UICorner")
		resetButtonCorner.CornerRadius = UDim.new(0, 8)
		resetButtonCorner.Parent = resetButton3
		local contentContainer = Instance.new("Frame")
		contentContainer.Size = UDim2.new(1, 0, 0, 38)
		contentContainer.Position = UDim2.new(0, 0, 0, 22)
		contentContainer.BackgroundTransparency = 1
		contentContainer.Parent = settingsFrame4
		local characterModel4 = playerCharacter2
		local dragStartPos = toggleButton4
		local animationData6 = screenGuiInstance
		local playerData = statusLabel
		local eventListeners3 = {}
		for index4 = 1, 5 do
			local currentItem = index4
			local optionFrame3 = Instance.new("Frame")
			optionFrame3.Size = UDim2.new(0.18, 0, 1, 0)
			optionFrame3.Position = UDim2.new((currentItem - 1) * 0.2 + 0.01, 0, 0, 0)
			optionFrame3.BackgroundTransparency = 1
			optionFrame3.Parent = contentContainer
			local speedInputBox = Instance.new("TextBox")
			speedInputBox.Size = UDim2.new(1, 0, 0, 16)
			speedInputBox.Position = UDim2.new(0, 0, 0, 0)
			speedInputBox.BackgroundColor3 = Color3.new(0, 0, 0)
			speedInputBox.BackgroundTransparency = 0.5
			speedInputBox.Text = animationData2 and animationData2[currentItem] and tostring(animationData2[currentItem].speed) or tostring(currentItem * 2 - 1)
			speedInputBox.TextColor3 = Color3.new(1, 1, 1)
			speedInputBox.TextSize = 8
			speedInputBox.Font = Enum.Font.Gotham
			speedInputBox.BorderSizePixel = 0
			speedInputBox.Parent = optionFrame3
			local speedInputCorner = Instance.new("UICorner")
			speedInputCorner.CornerRadius = UDim.new(0, 6)
			speedInputCorner.Parent = speedInputBox
			local applySpeedButton = Instance.new("TextButton")
			applySpeedButton.Size = UDim2.new(1, 0, 0, 16)
			applySpeedButton.Position = UDim2.new(0, 0, 0, 20)
			applySpeedButton.BackgroundColor3 = Color3.new(0, 0, 0)
			applySpeedButton.BackgroundTransparency = 0.5
			applySpeedButton.Text = "Key"
			applySpeedButton.TextColor3 = Color3.new(0.8, 0.8, 0.8)
			applySpeedButton.TextSize = 7
			applySpeedButton.Font = Enum.Font.Gotham
			applySpeedButton.BorderSizePixel = 0
			applySpeedButton.Parent = optionFrame3
			local applyButtonCorner = Instance.new("UICorner")
			applyButtonCorner.CornerRadius = UDim.new(0, 6)
			applyButtonCorner.Parent = applySpeedButton
			eventListeners3[currentItem] = {
				["speedInput"] = speedInputBox,
				["keybindButton"] = applySpeedButton,
				["connection"] = nil
			}
			speedInputBox.FocusLost:Connect(function()
				-- upvalues: (ref) v_u_52, (ref) v_u_681, (ref) v_u_683, (ref) v_u_111
				if not animationData2[currentItem] then
					animationData2[currentItem] = {
						["speed"] = currentItem * 2 - 1,
						["key"] = ""
					}
				end
				local inputSpeedValue = tonumber(speedInputBox.Text)
				if inputSpeedValue and (0 <= inputSpeedValue and inputSpeedValue <= 10) then
					animationData2[currentItem].speed = inputSpeedValue
					saveAnimationState()
				else
					speedInputBox.Text = tostring(animationData2[currentItem].speed)
				end
			end)
			applySpeedButton.MouseButton1Click:Connect(function()
				-- upvalues: (ref) v_u_52, (ref) v_u_681, (ref) v_u_685, (ref) v_u_111, (ref) v_u_679, (ref) v_u_678, (ref) v_u_3, (ref) v_u_38, (ref) v_u_669, (ref) v_u_671
				if not animationData2[currentItem] then
					animationData2[currentItem] = {
						["speed"] = currentItem * 2 - 1,
						["key"] = ""
					}
				end
				if animationData2[currentItem].key == "" then
					applySpeedButton.Text = "..."
					playerData.Text = "Press any key for slot " .. currentItem .. "..."
					playerData.TextColor3 = Color3.new(1, 1, 0.5)
					local lastUpdateTime = nil
					lastUpdateTime = userInputService.InputBegan:Connect(function(mouseX, mouseY)
						-- upvalues: (ref) v_u_685, (ref) v_u_678, (ref) v_u_688, (ref) v_u_52, (ref) v_u_681, (ref) v_u_111, (ref) v_u_679, (ref) v_u_3, (ref) v_u_38, (ref) v_u_669, (ref) v_u_671
						if not mouseY then
							if mouseX.KeyCode == Enum.KeyCode.Escape or mouseX.KeyCode == Enum.KeyCode.Backspace then
								applySpeedButton.Text = "Key"
								playerData.Text = "Cancelled"
								playerData.TextColor3 = Color3.new(0.7, 0.7, 0.7)
								spawn(function()
									-- upvalues: (ref) v_u_678
									wait(2)
									playerData.Text = "Ready"
								end)
								lastUpdateTime:Disconnect()
							elseif mouseX.KeyCode ~= Enum.KeyCode.Unknown then
								animationData2[currentItem].key = mouseX.KeyCode.Name
								applySpeedButton.Text = mouseX.KeyCode.Name:sub(1, 3)
								applySpeedButton.TextColor3 = Color3.new(1, 1, 1)
								saveAnimationState()
								if eventListeners3[currentItem].connection then
									eventListeners3[currentItem].connection:Disconnect()
								end
								eventListeners3[currentItem].connection = userInputService.InputBegan:Connect(function(deltaTime, elapsedTime2)
									-- upvalues: (ref) p_u_689, (ref) v_u_52, (ref) v_u_681, (ref) v_u_38, (ref) v_u_669, (ref) v_u_671
									if not elapsedTime2 then
										if deltaTime.KeyCode == mouseX.KeyCode then
											local currentSpeed = animationData2[currentItem].speed / 10
											animationContext.speed = animationData2[currentItem].speed / 5
											sliderHandle.Position = UDim2.new(currentSpeed, -6, 0.5, -6)
											sliderValueLabel.Text = string.format("%d", animationData2[currentItem].speed)
										end
									end
								end)
								playerData.Text = "Bound slot " .. currentItem .. " to " .. mouseX.KeyCode.Name
								playerData.TextColor3 = Color3.new(0.5, 1, 0.5)
								spawn(function()
									-- upvalues: (ref) v_u_678
									wait(2)
									playerData.Text = "Ready"
									playerData.TextColor3 = Color3.new(0.7, 0.7, 0.7)
								end)
								lastUpdateTime:Disconnect()
							end
						end
					end)
				else
					animationData2[currentItem].key = ""
					applySpeedButton.Text = "Key"
					applySpeedButton.TextColor3 = Color3.new(0.8, 0.8, 0.8)
					saveAnimationState()
					if eventListeners3[currentItem].connection then
						eventListeners3[currentItem].connection:Disconnect()
						eventListeners3[currentItem].connection = nil
					end
					playerData.Text = "Unbound slot " .. currentItem
					playerData.TextColor3 = Color3.new(1, 0.5, 0.5)
					spawn(function()
						-- upvalues: (ref) v_u_678
						wait(2)
						playerData.Text = "Ready"
						playerData.TextColor3 = Color3.new(0.7, 0.7, 0.7)
					end)
				end
			end)
		end
		for index5 = 1, 5 do
			local keyConfig = index5
			if animationData2[keyConfig] then
				eventListeners3[keyConfig].speedInput.Text = tostring(animationData2[keyConfig].speed)
				if animationData2[keyConfig].key and animationData2[keyConfig].key ~= "" then
					eventListeners3[keyConfig].keybindButton.Text = animationData2[keyConfig].key:sub(1, 3)
					eventListeners3[keyConfig].keybindButton.TextColor3 = Color3.new(1, 1, 1)
					local keyCode2 = Enum.KeyCode[animationData2[keyConfig].key]
					if keyCode2 then
						eventListeners3[keyConfig].connection = userInputService.InputBegan:Connect(function(player6, character5)
							-- upvalues: (ref) v_u_696, (ref) v_u_52, (ref) v_u_695, (ref) v_u_38, (ref) v_u_669, (ref) v_u_671
							if not character5 then
								if player6.KeyCode == keyCode2 then
									local speedModifier = animationData2[keyConfig].speed / 10
									animationContext.speed = animationData2[keyConfig].speed / 5
									sliderHandle.Position = UDim2.new(speedModifier, -6, 0.5, -6)
									sliderValueLabel.Text = string.format("%d", animationData2[keyConfig].speed)
								end
							end
						end)
					end
				end
			end
		end
		local uiElements = {
			playerData,
			settingsFrame,
			searchBox,
			scrollContainer,
			settingsFrame4,
			optionFrame,
			categoryFrame,
			dragStartPos,
			resetButton2,
			titleFrame,
			settingsFrame2
		}
		local function updateUI2(playerData2)
			-- upvalues: (ref) v_u_478, (ref) v_u_49, (ref) v_u_675, (ref) v_u_47, (ref) v_u_48, (ref) v_u_402, (ref) v_u_39, (ref) v_u_135, (ref) v_u_96, (ref) v_u_79, (ref) v_u_678, (ref) v_u_646, (ref) v_u_647, (ref) v_u_3, (ref) v_u_290
			local containerFrame2 = Instance.new("Frame")
			containerFrame2.Size = UDim2.new(1, 0, 0, 35)
			containerFrame2.BackgroundTransparency = 1
			containerFrame2.Parent = scrollContainer
			local hasCustomSetting = transformCache[playerData2.name] ~= nil
			local positionOffset4 = hasCustomSetting and (characterModel4 == "custom" and -102 or -70) or -70
			local actionButton2 = Instance.new("TextButton")
			actionButton2.Size = UDim2.new(1, positionOffset4, 1, 0)
			actionButton2.Position = UDim2.new(0, 0, 0, 0)
			actionButton2.BackgroundColor3 = Color3.new(0, 0, 0)
			actionButton2.BackgroundTransparency = 0.5
			actionButton2.Text = " " .. playerData2.name
			actionButton2.TextColor3 = Color3.new(1, 1, 1)
			actionButton2.TextSize = 12
			actionButton2.Font = Enum.Font.Gotham
			actionButton2.TextXAlignment = Enum.TextXAlignment.Left
			actionButton2.BorderSizePixel = 0
			actionButton2.Parent = containerFrame2
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 12)
			corner.Parent = actionButton2
			local textLabel
			if hasCustomSetting and characterModel4 == "custom" then
				textLabel = Instance.new("TextButton")
				textLabel.Size = UDim2.new(0, 32, 1, 0)
				textLabel.Position = UDim2.new(1, -98, 0, 0)
				textLabel.BackgroundTransparency = 1
				textLabel.Text = "X"
				textLabel.TextColor3 = Color3.new(1, 0.3, 0.3)
				textLabel.TextSize = 16
				textLabel.BorderSizePixel = 0
				textLabel.Parent = containerFrame2
			else
				textLabel = nil
			end
			local toggleButton5 = Instance.new("TextButton")
			toggleButton5.Size = UDim2.new(0, 32, 1, 0)
			toggleButton5.Position = UDim2.new(1, -66, 0, 0)
			toggleButton5.BackgroundTransparency = 1
			toggleButton5.Text = characterAttachments[playerData2.name] and "\226\152\133" or "\226\152\134"
			toggleButton5.TextColor3 = characterAttachments[playerData2.name] and Color3.new(1, 0.8, 0) or Color3.new(0.7, 0.7, 0.7)
			toggleButton5.TextSize = 16
			toggleButton5.BorderSizePixel = 0
			toggleButton5.Parent = containerFrame2
			local settingsButton = Instance.new("TextButton")
			settingsButton.Size = UDim2.new(0, 32, 1, 0)
			settingsButton.Position = UDim2.new(1, -32, 0, 0)
			settingsButton.BackgroundTransparency = 1
			settingsButton.Text = animationBindings[playerData2.name] and (animationBindings[playerData2.name].Name:gsub("KeyCode%.", ""):sub(1, 3) or "Bind") or "Bind"
			settingsButton.TextColor3 = animationBindings[playerData2.name] and Color3.new(1, 1, 1) or Color3.new(0.8, 0.8, 0.8)
			settingsButton.TextSize = 8
			settingsButton.Font = Enum.Font.Gotham
			settingsButton.BorderSizePixel = 0
			settingsButton.Parent = containerFrame2
			actionButton2.MouseEnter:Connect(function()
				-- upvalues: (ref) v_u_705
				actionButton2.BackgroundTransparency = 0.3
			end)
			actionButton2.MouseLeave:Connect(function()
				-- upvalues: (ref) v_u_705
				actionButton2.BackgroundTransparency = 0.5
			end)
			actionButton2.MouseButton1Click:Connect(function()
				-- upvalues: (ref) v_u_402, (ref) p_u_701
				decodedResponse(tostring(playerData2.id))
			end)
			if textLabel then
				textLabel.MouseButton1Click:Connect(function()
					-- upvalues: (ref) v_u_49, (ref) p_u_701, (ref) v_u_39, (ref) v_u_48, (ref) v_u_47, (ref) v_u_135, (ref) v_u_96, (ref) v_u_79
					transformCache[playerData2.name] = nil
					animationQueue[playerData2.name] = nil
					animationBindings[playerData2.name] = nil
					characterAttachments[playerData2.name] = nil
					initializeGui()
					applyAnimationKeybinds()
					saveFavoriteAnimations()
					loadGUI()
				end)
			end
			toggleButton5.MouseButton1Click:Connect(function()
				-- upvalues: (ref) v_u_47, (ref) p_u_701, (ref) v_u_708, (ref) v_u_79, (ref) v_u_675
				if characterAttachments[playerData2.name] then
					characterAttachments[playerData2.name] = nil
					toggleButton5.Text = "\226\152\134"
					toggleButton5.TextColor3 = Color3.new(0.7, 0.7, 0.7)
				else
					characterAttachments[playerData2.name] = tostring(playerData2.id)
					toggleButton5.Text = "\226\152\133"
					toggleButton5.TextColor3 = Color3.new(1, 0.8, 0)
				end
				saveFavoriteAnimations()
				if characterModel4 == "favorites" then
					spawn(function()
						wait(0.1)
						loadGUI()
					end)
				end
			end)
			settingsButton.MouseButton1Click:Connect(function()
				-- upvalues: (ref) v_u_48, (ref) p_u_701, (ref) v_u_96, (ref) v_u_709, (ref) v_u_678, (ref) v_u_646, (ref) v_u_647, (ref) v_u_3
				if animationBindings[playerData2.name] then
					animationBindings[playerData2.name] = nil
					applyAnimationKeybinds()
					settingsButton.Text = "Bind"
					settingsButton.TextColor3 = Color3.new(0.8, 0.8, 0.8)
					playerData.Text = "Unbound " .. playerData2.name
					playerData.TextColor3 = Color3.new(1, 0.5, 0.5)
					spawn(function()
						-- upvalues: (ref) v_u_678
						wait(2)
						playerData.Text = "Ready"
						playerData.TextColor3 = Color3.new(0.7, 0.7, 0.7)
					end)
					return
				elseif not dragOffset then
					dragOffset = true
					mainFrame2 = playerData2.name
					playerData.Text = "Press any key to bind..."
					playerData.TextColor3 = Color3.new(1, 1, 0.5)
					settingsButton.Text = "..."
					local eventConnection = nil
					eventConnection = userInputService.InputBegan:Connect(function(uiContainer2, parentFrame)
						-- upvalues: (ref) v_u_646, (ref) v_u_647, (ref) p_u_701, (ref) v_u_710, (ref) v_u_709, (ref) v_u_678, (ref) v_u_48, (ref) v_u_96
						if parentFrame then
							return
						elseif dragOffset and mainFrame2 == playerData2.name then
							if uiContainer2.KeyCode == Enum.KeyCode.Escape or uiContainer2.KeyCode == Enum.KeyCode.Backspace then
								settingsButton.Text = "Bind"
								settingsButton.TextColor3 = Color3.new(0.8, 0.8, 0.8)
								playerData.Text = "Binding cancelled"
								playerData.TextColor3 = Color3.new(0.7, 0.7, 0.7)
								spawn(function()
									-- upvalues: (ref) v_u_678
									wait(2)
									playerData.Text = "Ready"
								end)
								dragOffset = false
								mainFrame2 = nil
								eventConnection:Disconnect()
							elseif uiContainer2.KeyCode ~= Enum.KeyCode.Unknown then
								animationBindings[playerData2.name] = uiContainer2.KeyCode
								applyAnimationKeybinds()
								settingsButton.Text = uiContainer2.KeyCode.Name:gsub("KeyCode%.", ""):sub(1, 3)
								settingsButton.TextColor3 = Color3.new(1, 1, 1)
								playerData.Text = "Bound to " .. uiContainer2.KeyCode.Name:gsub("KeyCode%.", "")
								playerData.TextColor3 = Color3.new(0.5, 1, 0.5)
								spawn(function()
									-- upvalues: (ref) v_u_678
									wait(2)
									playerData.Text = "Ready"
									playerData.TextColor3 = Color3.new(0.7, 0.7, 0.7)
								end)
								dragOffset = false
								mainFrame2 = nil
								eventConnection:Disconnect()
							end
						else
							eventConnection:Disconnect()
						end
					end)
				end
			end)
			eventListeners2[playerData2.name] = {
				["Container"] = containerFrame2,
				["NameButton"] = actionButton2,
				["FavoriteButton"] = toggleButton5,
				["KeybindButton"] = settingsButton,
				["DeleteButton"] = textLabel
			}
		end
		function loadGUI()
			-- upvalues: (ref) v_u_478, (ref) v_u_290, (ref) v_u_480, (ref) v_u_675, (ref) v_u_648, (ref) v_u_641, (ref) v_u_485, (ref) v_u_548, (ref) v_u_577, (ref) v_u_476, (ref) v_u_39, (ref) v_u_49, (ref) v_u_47, (ref) v_u_713, (ref) v_u_479
			local mainUI = scrollContainer
			local child4, childName3, childElement = pairs(mainUI:GetChildren())
			while true do
				local statusText
				childElement, statusText = child4(childName3, childElement)
				if childElement == nil then
					break
				end
				if statusText:IsA("Frame") then
					statusText:Destroy()
				end
			end
			eventListeners2 = {}
			local statusFrame = optionFrame
			local animationTrack3
			if characterModel4 ~= "custom" then
				animationTrack3 = false
			else
				animationTrack3 = isInputFocused
			end
			statusFrame.Visible = animationTrack3
			resetButton2.Visible = characterModel4 == "custom"
			categoryFrame.Visible = characterModel4 == "states"
			titleFrame.Visible = characterModel4 == "size"
			settingsFrame2.Visible = characterModel4 == "others"
			scrollContainer.Visible = characterModel4 ~= "states" and (characterModel4 ~= "size" and characterModel4 ~= "others")
			searchBox.Visible = characterModel4 ~= "states" and (characterModel4 ~= "size" and characterModel4 ~= "others")
			if characterModel4 ~= "states" and (characterModel4 ~= "size" and characterModel4 ~= "others") then
				if characterModel4 ~= "custom" then
					scrollContainer.Size = UDim2.new(1, -16, 1, -175)
					scrollContainer.Position = UDim2.new(0, 8, 0, 105)
				elseif isInputFocused then
					scrollContainer.Size = UDim2.new(1, -16, 1, -270)
					scrollContainer.Position = UDim2.new(0, 8, 0, 195)
				else
					scrollContainer.Size = UDim2.new(1, -16, 1, -205)
					scrollContainer.Position = UDim2.new(0, 8, 0, 135)
				end
				local keyList = {}
				local lowercaseText = searchBox.Text:lower()
				local animationData7 = animationQueue
				if characterModel4 == "custom" then
					animationData7 = transformCache
				end
				local animName4, animTrack3, animation = pairs(animationData7)
				while true do
					local configTable
					animation, configTable = animName4(animTrack3, animation)
					if animation == nil then
						break
					end
					if (characterModel4 ~= "favorites" or characterAttachments[animation] ~= nil) and (lowercaseText == "" or animation:lower():find(lowercaseText)) then
						table.insert(keyList, {
							["name"] = animation,
							["id"] = configTable
						})
					end
				end
				table.sort(keyList, function(inputValue, minValue2)
					return inputValue.name < minValue2.name
				end)
				local key5, value6, keyValuePair = pairs(keyList)
				while true do
					local resultValue
					keyValuePair, resultValue = key5(value6, keyValuePair)
					if keyValuePair == nil then
						break
					end
					updateUI2(resultValue)
				end
				spawn(function()
					-- upvalues: (ref) v_u_478, (ref) v_u_479
					wait(0.1)
					scrollContainer.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
				end)
			end
		end
		local isInitialized3 = false
		local function renderStep(rawValue)
			-- upvalues: (ref) v_u_38, (ref) v_u_669, (ref) v_u_671
			local roundedValue = math.floor(rawValue * 10 + 0.5)
			animationContext.speed = roundedValue / 5
			sliderHandle.Position = UDim2.new(rawValue, -6, 0.5, -6)
			sliderValueLabel.Text = string.format("%d", roundedValue)
		end
		local function validateInput(inputString)
			-- upvalues: (ref) v_u_667, (ref) v_u_737
			renderStep((math.clamp((inputString.Position.X - sliderBackground.AbsolutePosition.X) / sliderBackground.AbsoluteSize.X, 0, 1)))
		end
		local function loadConfig()
			-- upvalues: (ref) v_u_38, (ref) v_u_669, (ref) v_u_671
			animationContext.speed = 1
			sliderHandle.Position = UDim2.new(0.5, -6, 0.5, -6)
			sliderValueLabel.Text = "5"
		end
		spawn(function()
			-- upvalues: (ref) v_u_669, (ref) v_u_671
			wait(0.1)
			sliderHandle.Position = UDim2.new(0.5, -6, 0.5, -6)
			sliderValueLabel.Text = "5"
		end)
		sliderBackground.InputBegan:Connect(function(configPath)
			-- upvalues: (ref) v_u_734, (ref) v_u_739
			if configPath.UserInputType == Enum.UserInputType.MouseButton1 or configPath.UserInputType == Enum.UserInputType.Touch then
				isInitialized3 = true
				validateInput(configPath)
			end
		end)
		userInputService.InputChanged:Connect(function(defaultConfig)
			-- upvalues: (ref) v_u_734, (ref) v_u_739
			if isInitialized3 and (defaultConfig.UserInputType == Enum.UserInputType.MouseMovement or defaultConfig.UserInputType == Enum.UserInputType.Touch) then
				validateInput(defaultConfig)
			end
		end)
		userInputService.InputEnded:Connect(function(playerCharacter3)
			-- upvalues: (ref) v_u_734
			if playerCharacter3.UserInputType == Enum.UserInputType.MouseButton1 or playerCharacter3.UserInputType == Enum.UserInputType.Touch then
				isInitialized3 = false
			end
		end)
		resetButton3.MouseButton1Click:Connect(function()
			-- upvalues: (ref) v_u_740
			loadConfig()
		end)
		resetButton3.MouseEnter:Connect(function()
			-- upvalues: (ref) v_u_672
			resetButton3.BackgroundTransparency = 0.3
		end)
		resetButton3.MouseLeave:Connect(function()
			-- upvalues: (ref) v_u_672
			resetButton3.BackgroundTransparency = 0.5
		end)
		minimizeButton.MouseButton1Click:Connect(function()
			-- upvalues: (ref) v_u_304, (ref) v_u_10, (ref) v_u_289, (ref) v_u_677
			animationModule()
			if isInitialized then
				ragdollModule(false)
			end
			animationData6:Destroy()
		end)
		closeButton.MouseButton1Click:Connect(function()
			-- upvalues: (ref) v_u_645, (ref) v_u_644, (ref) v_u_700, (ref) v_u_6, (ref) v_u_444, (ref) v_u_458, (ref) v_u_480, (ref) v_u_675, (ref) v_u_648, (ref) v_u_641, (ref) v_u_485, (ref) v_u_548, (ref) v_u_577, (ref) v_u_676, (ref) v_u_478, (ref) v_u_476
			if not isDragging then
				isDragging = true
				if isMenuOpen2 then
					local tweenInfo5 = tweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						["Size"] = UDim2.new(0, 280, 0, 395)
					})
					closeButton.Text = "\226\136\146"
					isMenuOpen2 = false
					tweenInfo5:Play()
					tweenInfo5.Completed:Connect(function()
						-- upvalues: (ref) v_u_700, (ref) v_u_480, (ref) v_u_675, (ref) v_u_648, (ref) v_u_641, (ref) v_u_485, (ref) v_u_548, (ref) v_u_577, (ref) v_u_676, (ref) v_u_478, (ref) v_u_476, (ref) v_u_645
						local partName7, partValue4, partEntry2 = pairs(uiElements)
						while true do
							local targetPosition2
							partEntry2, targetPosition2 = partName7(partValue4, partEntry2)
							if partEntry2 == nil then
								break
							end
							if targetPosition2 ~= optionFrame then
								if targetPosition2 ~= resetButton2 then
									if targetPosition2 ~= categoryFrame then
										if targetPosition2 ~= titleFrame then
											if targetPosition2 ~= settingsFrame2 then
												if targetPosition2 ~= dragStartPos then
													if targetPosition2 == scrollContainer or targetPosition2 == searchBox then
														targetPosition2.Visible = characterModel4 ~= "states" and (characterModel4 ~= "size" and characterModel4 ~= "others")
													else
														targetPosition2.Visible = true
													end
												else
													targetPosition2.Visible = characterModel4 == "custom" or characterModel4 == "states"
												end
											else
												targetPosition2.Visible = characterModel4 == "others"
											end
										else
											targetPosition2.Visible = characterModel4 == "size"
										end
									else
										targetPosition2.Visible = characterModel4 == "states"
									end
								else
									targetPosition2.Visible = characterModel4 == "custom"
								end
							else
								local movementDirection
								if characterModel4 ~= "custom" then
									movementDirection = false
								else
									movementDirection = isInputFocused
								end
								targetPosition2.Visible = movementDirection
							end
						end
						isDragging = false
					end)
				else
					local animKey6, animValue5, animEntry4 = pairs(uiElements)
					while true do
						local raycastFilter
						animEntry4, raycastFilter = animKey6(animValue5, animEntry4)
						if animEntry4 == nil then
							break
						end
						raycastFilter.Visible = false
					end
					local tweenProperties = tweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						["Size"] = UDim2.new(0, 280, 0, 30)
					})
					closeButton.Text = "+"
					isMenuOpen2 = true
					tweenProperties:Play()
					tweenProperties.Completed:Connect(function()
						-- upvalues: (ref) v_u_645
						isDragging = false
					end)
				end
			end
		end)
		searchBox:GetPropertyChangedSignal("Text"):Connect(loadGUI)
		saveButton.MouseButton1Click:Connect(function()
			-- upvalues: (ref) v_u_675, (ref) v_u_648, (ref) v_u_464, (ref) v_u_465, (ref) v_u_466, (ref) v_u_467, (ref) v_u_468, (ref) v_u_470, (ref) v_u_664
			characterModel4 = "all"
			isInputFocused = false
			saveButton.BackgroundTransparency = 0.5
			loadButton.BackgroundTransparency = 0.8
			resetButton.BackgroundTransparency = 0.8
			exportButton.BackgroundTransparency = 0.8
			importButton.BackgroundTransparency = 0.8
			importButton2.BackgroundTransparency = 0.8
			onSubmitInput()
			loadGUI()
		end)
		loadButton.MouseButton1Click:Connect(function()
			-- upvalues: (ref) v_u_675, (ref) v_u_465, (ref) v_u_464, (ref) v_u_466, (ref) v_u_467, (ref) v_u_470, (ref) v_u_664
			characterModel4 = "favorites"
			loadButton.BackgroundTransparency = 0.5
			saveButton.BackgroundTransparency = 0.8
			resetButton.BackgroundTransparency = 0.8
			exportButton.BackgroundTransparency = 0.8
			importButton2.BackgroundTransparency = 0.8
			onSubmitInput()
			loadGUI()
		end)
		resetButton.MouseButton1Click:Connect(function()
			-- upvalues: (ref) v_u_675, (ref) v_u_466, (ref) v_u_464, (ref) v_u_465, (ref) v_u_467, (ref) v_u_470, (ref) v_u_664
			characterModel4 = "custom"
			resetButton.BackgroundTransparency = 0.5
			saveButton.BackgroundTransparency = 0.8
			loadButton.BackgroundTransparency = 0.8
			exportButton.BackgroundTransparency = 0.8
			importButton2.BackgroundTransparency = 0.8
			onSubmitInput()
			loadGUI()
		end)
		exportButton.MouseButton1Click:Connect(function()
			-- upvalues: (ref) v_u_675, (ref) v_u_467, (ref) v_u_464, (ref) v_u_465, (ref) v_u_466, (ref) v_u_468, (ref) v_u_470, (ref) v_u_664
			characterModel4 = "states"
			exportButton.BackgroundTransparency = 0.5
			saveButton.BackgroundTransparency = 0.8
			loadButton.BackgroundTransparency = 0.8
			resetButton.BackgroundTransparency = 0.8
			importButton.BackgroundTransparency = 0.8
			importButton2.BackgroundTransparency = 0.8
			onSubmitInput()
			loadGUI()
		end)
		importButton.MouseButton1Click:Connect(function()
			-- upvalues: (ref) v_u_675, (ref) v_u_468, (ref) v_u_464, (ref) v_u_465, (ref) v_u_466, (ref) v_u_467, (ref) v_u_470, (ref) v_u_664
			characterModel4 = "size"
			importButton.BackgroundTransparency = 0.5
			saveButton.BackgroundTransparency = 0.8
			loadButton.BackgroundTransparency = 0.8
			resetButton.BackgroundTransparency = 0.8
			exportButton.BackgroundTransparency = 0.8
			importButton2.BackgroundTransparency = 0.8
			importButton2.BackgroundTransparency = 0.8
			onSubmitInput()
			loadGUI()
		end)
		importButton2.MouseButton1Click:Connect(function()
			-- upvalues: (ref) v_u_675, (ref) v_u_470, (ref) v_u_464, (ref) v_u_465, (ref) v_u_466, (ref) v_u_467, (ref) v_u_468, (ref) v_u_664
			characterModel4 = "others"
			importButton2.BackgroundTransparency = 0.5
			saveButton.BackgroundTransparency = 0.8
			loadButton.BackgroundTransparency = 0.8
			resetButton.BackgroundTransparency = 0.8
			exportButton.BackgroundTransparency = 0.8
			importButton.BackgroundTransparency = 0.8
			onSubmitInput()
			loadGUI()
		end)
		resetButton2.MouseButton1Click:Connect(function()
			-- upvalues: (ref) v_u_648, (ref) v_u_480, (ref) v_u_641, (ref) v_u_478, (ref) v_u_481, (ref) v_u_483, (ref) v_u_678, (ref) v_u_49, (ref) v_u_39, (ref) v_u_135
			if isInputFocused then
				local statusText2 = inputBox.Text
				local messageText = sliderInput.Text
				if statusText2 == "" or messageText == "" then
					playerData.Text = "Name and code required!"
					playerData.TextColor3 = Color3.new(1, 0.3, 0.3)
					spawn(function()
						-- upvalues: (ref) v_u_678
						wait(2)
						playerData.Text = "Ready"
						playerData.TextColor3 = Color3.new(0.7, 0.7, 0.7)
					end)
					return
				end
				transformCache[statusText2] = messageText
				animationQueue[statusText2] = messageText
				initializeGui()
				inputBox.Text = ""
				sliderInput.Text = ""
				isInputFocused = false
				optionFrame.Visible = false
				resetButton2.Text = "Add"
				resetButton2.BackgroundColor3 = Color3.new(0, 0, 0)
				scrollContainer.Size = UDim2.new(1, -16, 1, -175)
				scrollContainer.Position = UDim2.new(0, 8, 0, 105)
				playerData.Text = "Added: " .. statusText2
				playerData.TextColor3 = Color3.new(0.5, 1, 0.5)
				spawn(function()
					-- upvalues: (ref) v_u_678
					wait(2)
					playerData.Text = "Ready"
					playerData.TextColor3 = Color3.new(0.7, 0.7, 0.7)
				end)
				loadGUI()
			else
				isInputFocused = true
				optionFrame.Visible = true
				resetButton2.Text = "Save"
				resetButton2.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
				scrollContainer.Size = UDim2.new(1, -16, 1, -270)
				scrollContainer.Position = UDim2.new(0, 8, 0, 195)
			end
		end)
		resetButton2.MouseEnter:Connect(function()
			-- upvalues: (ref) v_u_641
			resetButton2.BackgroundTransparency = 0.3
		end)
		resetButton2.MouseLeave:Connect(function()
			-- upvalues: (ref) v_u_641
			resetButton2.BackgroundTransparency = 0.5
		end)
		local isMoving3 = false
		local currentCFrame = nil
		local velocity = nil
		local function updateFunction2(player7)
			-- upvalues: (ref) v_u_757, (ref) v_u_758, (ref) v_u_759, (ref) v_u_444
			isMoving3 = true
			currentCFrame = player7.Position
			velocity = mainFrame.Position
		end
		local function renderStepConnection(character6)
			-- upvalues: (ref) v_u_757, (ref) v_u_758, (ref) v_u_444, (ref) v_u_759
			if isMoving3 then
				local characterOffset = character6.Position - currentCFrame
				mainFrame.Position = UDim2.new(velocity.X.Scale, velocity.X.Offset + characterOffset.X, velocity.Y.Scale, velocity.Y.Offset + characterOffset.Y)
			end
		end
		local function inputConnection()
			-- upvalues: (ref) v_u_757
			isMoving3 = false
		end
		headerFrame.InputBegan:Connect(function(uiElement)
			-- upvalues: (ref) v_u_761
			if uiElement.UserInputType == Enum.UserInputType.MouseButton1 or uiElement.UserInputType == Enum.UserInputType.Touch then
				updateFunction2(uiElement)
			end
		end)
		userInputService.InputChanged:Connect(function(textLabel2)
			-- upvalues: (ref) v_u_764
			if textLabel2.UserInputType == Enum.UserInputType.MouseMovement or textLabel2.UserInputType == Enum.UserInputType.Touch then
				renderStepConnection(textLabel2)
			end
		end)
		userInputService.InputEnded:Connect(function(containerFrame3)
			-- upvalues: (ref) v_u_765
			if containerFrame3.UserInputType == Enum.UserInputType.MouseButton1 or containerFrame3.UserInputType == Enum.UserInputType.Touch then
				inputConnection()
			end
		end)
		playerData.Text = "Loading animations..."
		spawn(function()
			-- upvalues: (ref) v_u_39, (ref) v_u_678
			wait(1)
			local bodyPartName, bodyPartValue, bodyPartEntry = pairs(animationQueue)
			local rotationSpeed = 0
			while true do
				bodyPartEntry = bodyPartName(bodyPartValue, bodyPartEntry)
				if bodyPartEntry == nil then
					break
				end
				rotationSpeed = rotationSpeed + 1
			end
			playerData.Text = "Loaded " .. rotationSpeed .. " animations"
			playerData.TextColor3 = Color3.new(0.5, 1, 0.5)
			loadGUI()
			spawn(function()
				-- upvalues: (ref) v_u_678
				wait(2)
				playerData.Text = "Ready"
				playerData.TextColor3 = Color3.new(0.7, 0.7, 0.7)
			end)
		end)
	end
end
userInputService.InputBegan:Connect(function(mouse, camera)
	-- upvalues: (ref) v_u_48, (ref) v_u_49, (ref) v_u_39, (ref) v_u_47, (ref) v_u_402
	if camera then
		return
	end
	local animName5, animData4, animPair = pairs(animationBindings)
	while true do
		local fallbackAnim
		animPair, fallbackAnim = animName5(animData4, animPair)
		if animPair == nil then
			break
		end
		if mouse.KeyCode == fallbackAnim then
			local activeAnimation = transformCache[animPair] or (animationQueue[animPair] or characterAttachments[animPair])
			if activeAnimation then
				decodedResponse(tostring(activeAnimation))
			end
			break
		end
	end
end)
task.spawn(function()
	-- upvalues: (ref) v_u_145, (ref) v_u_118, (ref) v_u_773
	playAnimation()
	loadAnimationState()
	guiUpdateFunction()
end)
print("AK Reanim loaded!")
