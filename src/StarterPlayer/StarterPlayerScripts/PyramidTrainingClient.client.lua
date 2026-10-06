local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local CAS = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")
local LocalizationService = game:GetService("LocalizationService")

local player = Players.LocalPlayer
local isFrench = RunService:IsStudio()
if not isFrench then
	local ok, locale = pcall(function()
		return LocalizationService.RobloxLocaleId
	end)
	if ok and type(locale) == "string" then
		isFrench = string.sub(string.lower(locale), 1, 2) == "fr"
	end
end
local folder = RS:WaitForChild("PyramidHUD")
local C = require(folder:WaitForChild("Config"))
local remote = folder:WaitForChild("Training")
local T = C.Training

local function pads()
	local map = workspace:FindFirstChild("PyramidMap")
	local gym = map and map:FindFirstChild("Gym")
	return gym and gym:FindFirstChild("Pads")
end

local ADMIN_ZONE_NAME = "Region_ADMIN"

local function styleAdminLabel(o)
	if not (o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox")) then
		return
	end

	local text = string.upper(o.Text or "")
	local isMultiplier = text == "250X"
	local isAdmin = text == "ADMIN" or text == "ADMINISTRATEUR"
	if not (isMultiplier or isAdmin) then
		return
	end

	if isAdmin and isFrench then
		o.Text = "ADMINISTRATEUR"
	end

	o.Font = Enum.Font.GothamBlack
	o.BackgroundTransparency = 1
	o.BorderSizePixel = 0
	o.TextColor3 = Color3.fromRGB(255, 255, 255)
	o.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	o.TextStrokeTransparency = 0

	local oldCorner = o:FindFirstChild("AdminZoneCorner")
	if oldCorner then
		oldCorner:Destroy()
	end
	local oldStroke = o:FindFirstChild("AdminZoneStroke")
	if oldStroke then
		oldStroke:Destroy()
	end

	local gradient = o:FindFirstChild("AdminZoneGradient")
	if not gradient then
		gradient = Instance.new("UIGradient")
		gradient.Name = "AdminZoneGradient"
		gradient.Parent = o
	end
	gradient.Enabled = true
	gradient.Rotation = 90
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.32, Color3.fromRGB(215, 215, 215)),
		ColorSequenceKeypoint.new(0.68, Color3.fromRGB(85, 85, 85)),
		ColorSequenceKeypoint.new(1.00, Color3.fromRGB(0, 0, 0)),
	})

	for _, other in o:GetChildren() do
		if other:IsA("UIGradient") and other ~= gradient then
			other.Enabled = false
		end
	end
end

local function styleAdminZone()
	local p = pads()
	local zone = p and p:FindFirstChild(ADMIN_ZONE_NAME)
	if not zone then
		return
	end

	for _, o in zone:GetDescendants() do
		styleAdminLabel(o)
	end
	zone.DescendantAdded:Connect(function(o)
		task.defer(styleAdminLabel, o)
	end)
end

task.spawn(function()
	local deadline = os.clock() + 30
	repeat
		styleAdminZone()
		local p = pads()
		if p and p:FindFirstChild(ADMIN_ZONE_NAME) then
			break
		end
		task.wait(0.5)
	until os.clock() >= deadline
end)

local gui = player:WaitForChild("PlayerGui"):WaitForChild("PyramidTraining", 30)
if not gui then return end
local msg = gui:WaitForChild("Message")
msg.Visible = false
local popupTemplate = gui:WaitForChild("GainPopupTemplate")
popupTemplate.Enabled = false
local msgToken = 0
local function say(text)
	msgToken += 1
	local t = msgToken
	msg.Text = text
	msg.Visible = true
	task.delay(2.2, function()
		if msgToken == t then
			msg.Visible = false
		end
	end)
end

local ICON = { [C.Stats.Strength] = C.Icons.Strength, [C.Stats.Speed] = C.Icons.Speed }
local function short(n)
	if n < 1000 then
		return tostring(n)
	end
	local u = { "K", "M", "B", "T", "Qa", "Qi" }
	local i, v = 0, n
	while v >= 1000 and i < #u do
		v /= 1000
		i += 1
	end
	local d = n >= 1e5 and 2 or 1
	v = math.floor(v * 10 ^ d) / 10 ^ d
	return (string.format("%." .. d .. "f", v):gsub("%.?0+$", "")) .. u[i]
end
local function popup(stat, amount, lift)
	lift = lift or 0
	local ch = player.Character
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end
	local bb = popupTemplate:Clone()
	bb.Name = "GainPopup"
	bb:SetAttribute("IsTemplate", nil)
	bb.Adornee = hrp
	local start = popupTemplate.StudsOffsetWorldSpace
	bb.StudsOffsetWorldSpace = start + Vector3.new(0, lift, 0)
	local row = bb:WaitForChild("Row")
	row.Position = UDim2.fromScale(lift == 0 and math.random() * 0.15 or 0, 0)
	local icon = row:WaitForChild("Icon")
	icon.Image = ICON[stat] or ""
	local t = row:WaitForChild("Amount")
	t.Text = "+" .. short(amount)
	local st = t:FindFirstChildOfClass("UIStroke")
	bb.Enabled = true
	bb.Parent = gui
	local info = TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(bb, info, { StudsOffsetWorldSpace = Vector3.new(start.X - 2.5, start.Y + 3 + lift, start.Z) }):Play()
	TweenService:Create(icon, info, { ImageTransparency = 1 }):Play()
	TweenService:Create(t, info, { TextTransparency = 1 }):Play()
	if st then
		TweenService:Create(st, info, { Transparency = 1 }):Play()
	end
	task.delay(1.2, function()
		bb:Destroy()
	end)
end

local bench
local function motors()
	local ch = player.Character
	if not ch then
		return {}
	end
	local function m(parent, name)
		local p = ch:FindFirstChild(parent)
		return p and p:FindFirstChild(name)
	end
	return {
		rs = m("RightUpperArm", "RightShoulder") or m("Torso", "Right Shoulder"),
		ls = m("LeftUpperArm", "LeftShoulder") or m("Torso", "Left Shoulder"),
		re = m("RightLowerArm", "RightElbow"),
		le = m("LeftLowerArm", "LeftElbow"),
	}
end

local function lieCFrame(pad)
	local cf = pad.CFrame * CFrame.new(0, pad.Size.Y / 2 + 1.05, pad.Size.Z * 0.31)
	local up = -cf.LookVector
	local back = -Vector3.yAxis
	return CFrame.fromMatrix(cf.Position, up:Cross(back), up, back)
end

local function endBench(tellServer)
	if not bench then
		return
	end
	local b0 = bench
	bench = nil
	player:SetAttribute("BenchLocal", nil)
	CAS:UnbindAction("PyramidStopBench")
	for _, b in b0.bar do
		if b[1].Parent then
			b[1].CFrame = b[2]
		end
	end
	for _, mo in motors() do
		mo.Transform = CFrame.new()
	end
	local ch = player.Character
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	if hrp and hum then
		local side = (b0.pad.CFrame * CFrame.new(3.6, 0, 0)).Position
		local face = b0.pad.CFrame.RightVector
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.CFrame = CFrame.lookAt(side + Vector3.new(0, 3, 0), side + Vector3.new(0, 3, 0) + face)
		hum.PlatformStand = false
		hum:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
	if tellServer then
		remote:FireServer("stop")
	end
end

local function beginBench(model, mult)
	endBench(false)
	local pad = model:FindFirstChild("BenchPad")
	if not pad then
		return
	end
	local bar = {}
	for _, p in model:GetChildren() do
		if p:IsA("BasePart") and (p.Name == "Bar" or p.Name == "Plate" or p.Name == "PlateGlow" or p.Name == "Collar") then
			table.insert(bar, { p, p.CFrame })
		end
	end
	local barPart = model:FindFirstChild("Bar")
	bench = {
		model = model, pad = pad, bar = bar, t0 = os.clock(), period = 1 / T.RepSpeed(mult or 1), lie = lieCFrame(pad),
		restY = barPart and barPart.Position.Y or pad.Position.Y + 3,
	}
	player:SetAttribute("BenchLocal", true)
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.PlatformStand = true
	end
	CAS:BindActionAtPriority("PyramidStopBench", function(_, state)
		if state == Enum.UserInputState.Begin then
			endBench(true)
		end
		return Enum.ContextActionResult.Sink
	end, false, 3000, Enum.KeyCode.E, Enum.KeyCode.Space, Enum.KeyCode.ButtonX, Enum.KeyCode.ButtonA)
end

UIS.JumpRequest:Connect(function()
	if bench then
		endBench(true)
	end
end)

RunService.Stepped:Connect(function()
	if not bench then
		return
	end
	local ch = player.Character
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	if hrp then
		hrp.CFrame = bench.lie
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
	end
	local k = (math.cos((os.clock() - bench.t0) / bench.period * math.pi * 2) + 1) / 2
	local mo = motors()
	local shoulder = CFrame.Angles(math.rad(90 - 35 * (1 - k)), 0, 0)
	local elbow = CFrame.Angles(math.rad(-20 * (1 - k)), 0, 0)
	if mo.rs then
		mo.rs.Transform = shoulder
	end
	if mo.ls then
		mo.ls.Transform = shoulder
	end
	if mo.re then
		mo.re.Transform = elbow
	end
	if mo.le then
		mo.le.Transform = elbow
	end
end)

RunService.Heartbeat:Connect(function()
	if not bench then
		return
	end
	local ch = player.Character
	if not ch then
		return
	end
	local hands = {}
	for _, n in { "RightHand", "LeftHand", "Right Arm", "Left Arm" } do
		local h = ch:FindFirstChild(n)
		if h then
			local tip = h.Name:find("Arm") and (h.CFrame * CFrame.new(0, -h.Size.Y / 2, 0)).Position or h.Position
			table.insert(hands, tip)
		end
	end
	if #hands == 0 then
		return
	end
	local y = 0
	for _, v in hands do
		y += v.Y
	end
	y /= #hands
	local dy = y - bench.restY
	for _, b in bench.bar do
		b[1].CFrame = b[2] + Vector3.new(0, dy, 0)
	end
end)

local runTrack, runZone
local function stopRunAnim()
	if runTrack then
		runTrack:Stop(0.15)
		runTrack = nil
	end
	runZone = nil
end

local function runAnimation(hum)
	local ch = hum.Parent
	local animate = ch:FindFirstChild("Animate")
	local slot = animate and animate:FindFirstChild("run")
	local anim = slot and slot:FindFirstChildOfClass("Animation")
	local animator = hum:FindFirstChildOfClass("Animator")
	if not (anim and animator) then
		return nil
	end
	local track = animator:LoadAnimation(anim)
	track.Looped = true
	track.Priority = Enum.AnimationPriority.Action
	return track
end

local function beltOf(zone)
	local tm = zone and zone:FindFirstChild("Treadmill")
	return tm and tm:FindFirstChild("Belt")
end

RunService.Heartbeat:Connect(function()
	local name = player:GetAttribute("OnTreadmill")
	local ch = player.Character
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	local p = pads()
	local zone = name and p and p:FindFirstChild(name)
	local belt = beltOf(zone)
	local on = false
	if belt and hrp and hum and not bench then
		local lp = belt.CFrame:PointToObjectSpace(hrp.Position)
		on = math.abs(lp.X) < belt.Size.X / 2 + 0.3 and math.abs(lp.Z) < belt.Size.Z / 2 and lp.Y > 0 and lp.Y < 5.5
	end
	if on and hum.MoveDirection.Magnitude < 0.1 then
		if runZone ~= zone or not runTrack then
			stopRunAnim()
			runTrack = runAnimation(hum)
			runZone = zone
			if runTrack then
				runTrack:Play(0.15)
				local dir = belt.CFrame.ZVector
				local pos = hrp.Position
				hrp.CFrame = CFrame.lookAt(pos, pos + Vector3.new(dir.X, 0, dir.Z))
			end
		end
		if runTrack then
			runTrack:AdjustSpeed(T.RunAnimSpeed(zone:GetAttribute("Multiplier") or 1))
		end
	elseif runTrack then
		stopRunAnim()
	end
end)

local function unlocked(zone)
	if player:GetAttribute("Unlocked_" .. zone.Name) then
		return true
	end
	if zone:GetAttribute("Paid") then
		return player:GetAttribute("IsAdmin") == true or RunService:IsStudio()
	end
	return (player:GetAttribute(C.Stats.Pyramids) or 0) >= (zone:GetAttribute("RequiredPyramids") or 0)
end
local reach = {}
task.spawn(function()
	while true do
		local p = pads()
		if p then
			for _, zone in p:GetChildren() do
				local bp = zone:FindFirstChild("BenchPress")
				local pad = bp and bp:FindFirstChild("BenchPad")
				local prompt = pad and pad:FindFirstChildOfClass("ProximityPrompt")
				if prompt then
					reach[prompt] = reach[prompt] or prompt.MaxActivationDistance
					prompt.MaxActivationDistance = unlocked(zone) and reach[prompt] or 0
				end
			end
		end
		task.wait(0.5)
	end
end)

local MPS = game:GetService("MarketplaceService")
local offered
local function zoneAt(pos)
	local p = pads()
	if not p then
		return nil
	end
	for _, zone in p:GetChildren() do
		local area = zone:FindFirstChild("TrainZone")
		if area then
			local rel = area.CFrame:PointToObjectSpace(pos)
			local h = area.Size / 2
			if math.abs(rel.X) <= h.X and math.abs(rel.Z) <= h.Z and math.abs(rel.Y) <= h.Y + 4 then
				return zone
			end
		end
	end
	return nil
end
task.spawn(function()
	while true do
		task.wait(0.25)
		local ch = player.Character
		local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
		local zone = hrp and zoneAt(hrp.Position)
		if zone ~= offered then
			offered = nil
			if zone and not unlocked(zone) then
				offered = zone
				local req = zone:GetAttribute("RequiredPyramids") or 0
				if zone:GetAttribute("Paid") or req <= 0 then
					say(isFrench and "Vous n\'avez pas débloqué cette zone !" or "You haven\'t unlocked this zone!")
				else
					say(isFrench and (("Vous n\'avez pas débloqué cette zone ! Nécessite %d pyramide%s"):format(req, req == 1 and "" or "s")) or (("You haven\'t unlocked this zone! Needs %d Pyramid%s"):format(req, req == 1 and "" or "s")))
				end
				local u = (C.ZoneUnlock or {})[zone.Name]
				if u and (u.GamePassId or 0) > 0 then
					pcall(MPS.PromptGamePassPurchase, MPS, player, u.GamePassId)
				elseif u and (u.ProductId or 0) > 0 then
					pcall(MPS.PromptProductPurchase, MPS, player, u.ProductId)
				end
			end
		end
	end
end)

remote.OnClientEvent:Connect(function(kind, a, b)
	if kind == "bench" then
		if a then
			beginBench(a, b)
		else
			endBench(false)
		end
	elseif kind == "gain" then
		popup(a, b)
	elseif kind == "gainBoth" then
		popup(C.Stats.Speed, a, 2.2)
		popup(C.Stats.Strength, b, 0)
	elseif kind == "denied" then
		say(tostring(a))
	end
end)

player.CharacterAdded:Connect(function()
	if bench then
		for _, b in bench.bar do
			if b[1].Parent then
				b[1].CFrame = b[2]
			end
		end
	end
	bench = nil
	player:SetAttribute("BenchLocal", nil)
	CAS:UnbindAction("PyramidStopBench")
	stopRunAnim()
end)

local CollectionService = game:GetService("CollectionService")
local flowing = {}
local function addFlow(t)
	if t:IsA("Texture") then
		flowing[t] = true
	end
end
for _, t in CollectionService:GetTagged("PyramidWaterFlow") do
	addFlow(t)
end
CollectionService:GetInstanceAddedSignal("PyramidWaterFlow"):Connect(addFlow)
CollectionService:GetInstanceRemovedSignal("PyramidWaterFlow"):Connect(function(t)
	flowing[t] = nil
end)
RunService.RenderStepped:Connect(function()
	if next(flowing) == nil then
		return
	end
	local now = os.clock()
	for t in flowing do
		t.OffsetStudsU = now * (t:GetAttribute("FlowU") or 0) + math.sin(now * 0.5) * (t:GetAttribute("Sway") or 0)
		t.OffsetStudsV = now * (t:GetAttribute("FlowV") or 0)
	end
end)
