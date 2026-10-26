   getgenv().qlnt = {
	Silent = {
		Normal = {
			Enabled = true,
			HitChance = 95,
			FOVRadius = 25,
			ShowFOV = true,
			WallCheck = true,
			KnockedCheck = true,
			CrewCheck = true,
			AntiCurve = true,
			NoGroundShots = true,
			Mode = "legit", -- legit / semi-legit / blatant / custom
			Radius = 35, 
			Smoothing = 0.1, 
			DistanceCheck = true,
			MaxDistance = 500, 
			TeamCheck = false, 
			IgnoreFriends = true, 
			VisibleCheck = true, 
			DrawFOVSides = 64, 
			Radient = true, 
		},
		KeyBind = {
			Enabled = true,
			KeyBind = 'p',
			Notification = true,
		},
		HitPart = {
			NearestPoint = true,
			HitPart = 'HumanoidRootPart',
		},
		Prediction = {
			Enabled = true,
			AutoMated = false,
			Prediction = 0.12,
		},
	},
}

local config = {
	Mode = getgenv().qlnt.Silent.Normal.Mode,
	Enabled = getgenv().qlnt.Silent.Normal.Enabled,
	Keybind = getgenv().qlnt.Silent.KeyBind.KeyBind,
	KeybindEnabled = getgenv().qlnt.Silent.KeyBind.Enabled,
	KeybindNotifications = getgenv().qlnt.Silent.KeyBind.Notification,
	HitChance = getgenv().qlnt.Silent.Normal.HitChance,
	Prediction = getgenv().qlnt.Silent.Prediction.Prediction,
	AutoPrediction = getgenv().qlnt.Silent.Prediction.AutoMated,
	HitPart = getgenv().qlnt.Silent.HitPart.HitPart,
	NearestPoint = getgenv().qlnt.Silent.HitPart.NearestPoint,
	FOVRadius = getgenv().qlnt.Silent.Normal.FOVRadius,
	ShowFOV = getgenv().qlnt.Silent.Normal.ShowFOV,
	WallCheck = getgenv().qlnt.Silent.Normal.WallCheck,
	KnockedCheck = getgenv().qlnt.Silent.Normal.KnockedCheck,
	CrewCheck = getgenv().qlnt.Silent.Normal.CrewCheck,
	AntiCurve = getgenv().qlnt.Silent.Normal.AntiCurve,
	NoGroundShots = getgenv().qlnt.Silent.Normal.NoGroundShots,
	Radius = getgenv().qlnt.Silent.Normal.Radius,
	Smoothing = getgenv().qlnt.Silent.Normal.Smoothing,
	DistanceCheck = getgenv().qlnt.Silent.Normal.DistanceCheck,
	MaxDistance = getgenv().qlnt.Silent.Normal.MaxDistance,
	TeamCheck = getgenv().qlnt.Silent.Normal.TeamCheck,
	IgnoreFriends = getgenv().qlnt.Silent.Normal.IgnoreFriends,
	VisibleCheck = getgenv().qlnt.Silent.Normal.VisibleCheck,
	DrawFOVSides = getgenv().qlnt.Silent.Normal.DrawFOVSides,
	Radient = getgenv().qlnt.Silent.Normal.Radient,
}


local function setMode(mode)
	if mode == "legit" then
		config.HitChance = 70
		config.FOVRadius = 20
		config.Prediction = 0.09
		config.ShowFOV = true
	elseif mode == "semi-legit" then
		config.HitChance = 90
		config.FOVRadius = 35
		config.Prediction = 0.12
		config.ShowFOV = true
	elseif mode == "blatant" then
		config.HitChance = 100
		config.FOVRadius = 100
		config.Prediction = 0.99
		config.ShowFOV = true
	end
	config.Mode = mode
end


local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local GuiInset = game:GetService("GuiService"):GetGuiInset()

_G.SilentTarget = nil

local SilentAimConfig = config or getgenv().qlnt and getgenv().qlnt.Silent and getgenv().qlnt.Silent.Normal or {}

if _G.SilentFOVCircle and _G.SilentFOVCircle.Remove then
	_G.SilentFOVCircle:Remove()
end
_G.SilentFOVCircle = Drawing.new('Circle')
_G.SilentFOVCircle.Color = Color3.new(1, 1, 1)
_G.SilentFOVCircle.Thickness = 1
_G.SilentFOVCircle.Filled = false
_G.SilentFOVCircle.Transparency = 1
_G.SilentFOVCircle.Visible = false

local function isPlayerValid(player)
	return player and player.Character and player.Character:FindFirstChild('HumanoidRootPart') and player.Character:FindFirstChild('Humanoid') and player.Character:FindFirstChild('Head')
end

local function calculateHitChance(percentage)
	percentage = math.floor(percentage)
	local chance = math.floor(Random.new():NextNumber(0, 1) * 100) / 100
	return chance <= percentage / 100
end

local function wallCheck(targetPart, targetCharacter)
	local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	local origin = Camera.CFrame.Position
	local _, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
	if onScreen then
		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
		raycastParams.FilterDescendantsInstances = {character, Camera}
		local result = workspace:Raycast(origin, targetPart.Position - origin, raycastParams)
		if result then
			local partHit = result.Instance
			local visible = (not partHit or partHit:IsDescendantOf(targetCharacter))
			return visible
		end
	end
	return false
end

local function getClosestBodyPart(character)
	local closestDistance = math.huge
	local bodyPart = nil
	if character and character:GetChildren() then
		for _, part in pairs(character:GetChildren()) do
			if part:IsA("BasePart") and not string.find(part.Name:lower(), "gun") then
				local pos, onScreen = Camera:WorldToScreenPoint(part.Position)
				if onScreen then
					local distance = (Vector2.new(Mouse.X, Mouse.Y) - Vector2.new(pos.X, pos.Y)).Magnitude
					if distance < closestDistance then
						closestDistance = distance
						bodyPart = part
					end
				end
			end
		end
	end
	return bodyPart
end

local function getNearestPoint(part)
	if part ~= nil then
		local hit = Mouse.Hit.Position
		local half = part.Size * 0.5
		local transform = part.CFrame:PointToObjectSpace(Mouse.Hit.Position)
		local nearestPosition = part.CFrame * Vector3.new(
			math.clamp(transform.X, -half.X, half.X),
			math.clamp(transform.Y, -half.Y, half.Y),
			math.clamp(transform.Z, -half.Z, half.Z)
		)
		return nearestPosition
	end
	return nil
end

local function getClosestTarget()
	local target, closest = nil, math.huge
	local hitChance = calculateHitChance(SilentAimConfig.HitChance)
	if not hitChance then return nil end
	for _, player in pairs(Players:GetPlayers()) do
		if player.Character and player ~= LocalPlayer and player.Character:FindFirstChild('HumanoidRootPart') then
			local hrp = player.Character.HumanoidRootPart
			local pos, onScreen = Camera:WorldToScreenPoint(hrp.Position)
			if onScreen then
				local distance = (Vector2.new(Mouse.X, Mouse.Y) - Vector2.new(pos.X, pos.Y)).Magnitude * 0.6
				if SilentAimConfig.KnockedCheck and isPlayerValid(player) and player.Character:FindFirstChild('BodyEffects') then
					local bodyEffects = player.Character.BodyEffects
					local ko = bodyEffects:FindFirstChild('K.O')
					local grabbed = player.Character:FindFirstChild('GRABBING_CONSTRAINT')
					if (ko and ko.Value) or grabbed then continue end
				end
				if SilentAimConfig.WallCheck and isPlayerValid(player) then
					local targetPart = player.Character:FindFirstChild(SilentAimConfig.HitPart)
					if targetPart then
						if not wallCheck(targetPart, player.Character) then continue end
					end
				end
				if SilentAimConfig.CrewCheck and isPlayerValid(player) and isPlayerValid(LocalPlayer) then
					local targetCrew = player:FindFirstChild('DataFolder') and player.DataFolder:FindFirstChild('Information') and player.DataFolder.Information:FindFirstChild('Crew')
					local localCrew = LocalPlayer:FindFirstChild('DataFolder') and LocalPlayer.DataFolder:FindFirstChild('Information') and LocalPlayer.DataFolder.Information:FindFirstChild('Crew')
					if targetCrew and localCrew and targetCrew.Value ~= '' and localCrew.Value ~= '' and targetCrew.Value == localCrew.Value then continue end
				end
				local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
				if humanoid and humanoid.Health < 4 then continue end
				if distance < closest and distance < SilentAimConfig.FOVRadius * 3 then
					closest = distance
					target = player
				end
			end
		end
	end
	return target
end

local function getPredictedPosition()
	if not isPlayerValid(_G.SilentTarget) or not Players[tostring(_G.SilentTarget)].Character:FindFirstChild(SilentAimConfig.HitPart) then
		return nil
	end
	local silentCFrame = nil
	local targetCF = nil
	local targetChar = Players[tostring(_G.SilentTarget)].Character
	local targetVel = targetChar.HumanoidRootPart.Velocity
	local targetMov = targetChar.Humanoid.MoveDirection
	if SilentAimConfig.NearestPoint and _G.SilentTarget.Character and isPlayerValid(_G.SilentTarget) then
		local hitPart = SilentAimConfig.HitPart
		if hitPart == "Head" or hitPart == "UpperTorso" or hitPart == "LowerTorso" then
			hitPart = tostring(getClosestBodyPart(_G.SilentTarget.Character))
		end
		SilentAimConfig.HitPart = hitPart or "HumanoidRootPart"
		local targetPart = targetChar:FindFirstChild(SilentAimConfig.HitPart)
		if targetPart then
			local closestPoint = getNearestPoint(targetPart)
			if closestPoint then
				targetCF = closestPoint
			else
				targetCF = targetPart.CFrame
			end
		end
	else
		local targetPart = targetChar:FindFirstChild(SilentAimConfig.HitPart)
		if targetPart then
			targetCF = targetPart.CFrame
		end
	end
	if not targetCF then return nil end
	if SilentAimConfig.AntiCurve then
		local magnitude = targetVel.Magnitude
		local magnitude2 = targetMov.Magnitude
		if magnitude > 86 then
			_G.AntiCurveActive = true
		elseif magnitude < 1 and magnitude2 > 0.01 then
			_G.AntiCurveActive = true
		elseif magnitude > 5 and magnitude2 < 0.01 then
			_G.AntiCurveActive = true
		else
			_G.AntiCurveActive = false
		end
	else
		_G.AntiCurveActive = false
	end
	if SilentAimConfig.NoGroundShots then
		if targetVel.Y < -20 then
			_G.NoGroundShotsActive = true
		else
			_G.NoGroundShotsActive = false
		end
	else
		_G.NoGroundShotsActive = false
	end
	if _G.AntiCurveActive then
		local moveDirection = targetMov
		silentCFrame = targetCF + (moveDirection * SilentAimConfig.Prediction * 16)
	elseif _G.NoGroundShotsActive then
		silentCFrame = targetCF + (Vector3.new(targetVel.X, 0, targetVel.Z) * SilentAimConfig.Prediction)
	else
		silentCFrame = targetCF + (targetVel * SilentAimConfig.Prediction)
	end
	return silentCFrame
end

local function applySilentAim()
	if not SilentAimConfig.Enabled then return end
	_G.SilentTarget = getClosestTarget()
	local target = _G.SilentTarget
	if not target or not target.Character or not target.Character:FindFirstChild('HumanoidRootPart') then return end
	local hrpPosition = Camera:WorldToScreenPoint(target.Character.HumanoidRootPart.Position)
	local distance = (Vector2.new(Mouse.X, Mouse.Y) - Vector2.new(hrpPosition.X, hrpPosition.Y)).Magnitude * 0.6
	if distance < SilentAimConfig.FOVRadius * 3 then
		local predictedPos = getPredictedPosition()
		if predictedPos ~= nil then
			local args = {
				[1] = "MOUSE",
				[2] = Vector3.new(predictedPos.X, predictedPos.Y, predictedPos.Z)
			}
			local ReplicatedStorage = game:GetService('ReplicatedStorage')
			local remote = ReplicatedStorage:FindFirstChild("MAINEVENT")
			if remote then
				remote:FireServer(unpack(args))
			end
		end
	end
end

Mouse.KeyDown:Connect(function(key)

if SilentAimConfig.KeybindEnabled and key:lower() == SilentAimConfig.Keybind then
    SilentAimConfig.Enabled = not SilentAimConfig.Enabled
    if SilentAimConfig.KeybindNotifications then
          local status = SilentAimConfig.Enabled and "on" or "off"
          local sg = game:GetService("StarterGui")
          coroutine.wrap(function()
                pcall(function()
					sg:SetCore("SendNotification", {
					   Text = status,
		               Duration = 4
                    })
                end)
          end)()
       end
    end
end)

RunService.Heartbeat:Connect(function()
	if SilentAimConfig.AutoPrediction then
		local success, pingValue = pcall(function()
			return game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValueString()
		end)
		if not success or not pingValue then return end
		local split = string.split(pingValue, '(')
		if not split or not split[1] then return end
		local ping = tonumber(split[1])
		if not ping then return end
		if ping < 190 then
			SilentAimConfig.Prediction = 0.180
		elseif ping < 180 then
			SilentAimConfig.Prediction = 0.170
		elseif ping < 170 then
			SilentAimConfig.Prediction = 0.165
		elseif ping < 160 then
			SilentAimConfig.Prediction = 0.1574
		elseif ping < 150 then
			SilentAimConfig.Prediction = 0.1555
		elseif ping < 140 then
			SilentAimConfig.Prediction = 0.141
		elseif ping < 130 then
			SilentAimConfig.Prediction = 0.1344
		elseif ping < 120 then
			SilentAimConfig.Prediction = 0.1344
		elseif ping < 110 then
			SilentAimConfig.Prediction = 0.1300
		elseif ping < 100 then
			SilentAimConfig.Prediction = 0.1295
		elseif ping < 90 then
			SilentAimConfig.Prediction = 0.1295
		elseif ping < 80 then
			SilentAimConfig.Prediction = 0.1300
		elseif ping < 70 then
			SilentAimConfig.Prediction = 0.1290
		elseif ping < 60 then
			SilentAimConfig.Prediction = 0.1250
		elseif ping < 50 then
			SilentAimConfig.Prediction = 0.1230
		elseif ping < 40 then
			SilentAimConfig.Prediction = 0.1190
		elseif ping < 30 then
			SilentAimConfig.Prediction = 0.1100
		elseif ping < 20 then
			SilentAimConfig.Prediction = 0.1000
		end
	end
end)

RunService.Heartbeat:Connect(function()
	_G.SilentFOVCircle.Visible = SilentAimConfig.ShowFOV == false
	_G.SilentFOVCircle.Radius = (SilentAimConfig.FOVRadius or 35) * 3
	_G.SilentFOVCircle.Position = Vector2.new(Mouse.X, Mouse.Y + GuiInset.Y)
	_G.SilentFOVCircle.Color = Color3.new(1, 1, 1)
	_G.SilentFOVCircle.Filled = SilentAimConfig.Radient == true
	_G.SilentFOVCircle.Transparency = SilentAimConfig.Radient == true and 0.3 or 1
end)

local toolConnection
local function onToolAdded(tool)
   if tool:IsA('Tool') then
      if toolConnection then
         toolConnection:Disconnect()
      end
      toolConnection = tool.Activated:Connect(applySilentAim)
   end
end

local function onCharacterAdded(character)
   character.ChildAdded:Connect(onToolAdded)
end

if LocalPlayer.Character then
   onCharacterAdded(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
