local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local S = require(RS:WaitForChild("PyramidHUD"):WaitForChild("PyramidShape"))
local site = workspace:WaitForChild("PyramidMap"):WaitForChild("PyramidSite")

local FADE = 0.45
local MIN_DARK = 0.8
local MAX_BUILD = 10
local SETTLE, MAX_SETTLE = 0.6, 5
local ORBIT = 7
local FLY = 2.2
local PRELOAD = 3

local playing = false
local state = {}

local function training()
	return player:GetAttribute("BenchLocal") or player:GetAttribute("OnTreadmill")
end

local gui = player:WaitForChild("PlayerGui"):WaitForChild("PyramidCinematic")
local dark = gui:WaitForChild("Dark")
dark.BackgroundTransparency = 1

local function fade(toDark, wait)
	local tw = TweenService:Create(dark, TweenInfo.new(FADE, Enum.EasingStyle.Quad), { BackgroundTransparency = toDark and 0 or 1 })
	tw:Play()
	if wait ~= false then
		tw.Completed:Wait()
	end
end

local title = gui:WaitForChild("Title")
title.Visible = false
local titleScale = title:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", title)
local nameLine = title:WaitForChild("Name")
local doneLine = title:WaitForChild("Complete")
local function strokeOf(l)
	return l:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke", l)
end
local nameStroke, doneStroke = strokeOf(nameLine), strokeOf(doneLine)

local function showTitle(text)
	nameLine.Text = text
	for _, l in { nameLine, doneLine } do
		l.TextTransparency = 0
	end
	nameStroke.Transparency, doneStroke.Transparency = 0, 0
	titleScale.Scale = 0.2
	title.Visible = true
	TweenService:Create(titleScale, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end
local function hideTitle()
	local info = TweenInfo.new(0.5)
	for _, l in { nameLine, doneLine } do
		TweenService:Create(l, info, { TextTransparency = 1 }):Play()
	end
	TweenService:Create(nameStroke, info, { Transparency = 1 }):Play()
	TweenService:Create(doneStroke, info, { Transparency = 1 }):Play()
	task.delay(0.5, function()
		title.Visible = false
	end)
end

local function run()
	if playing then
		return
	end
	local ch = player.Character
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	if not (hum and ch:FindFirstChild("HumanoidRootPart")) then
		return
	end
	playing = true
	table.clear(state)
	local cam = workspace.CurrentCamera

	fade(true)
	local hidden = {}
	for _, g in player.PlayerGui:GetChildren() do
		if g ~= gui and g:IsA("ScreenGui") and g.Enabled then
			g.Enabled = false
			table.insert(hidden, g)
		end
	end
	local held = ch:FindFirstChild("HumanoidRootPart")
	local wasAnchored = held.Anchored
	held.Anchored = true
	state.hidden, state.held, state.wasAnchored = hidden, held, wasAnchored
	local t0 = os.clock()
	while not site:GetAttribute("ChamberReady") and site:GetAttribute("ChamberOpen") and os.clock() - t0 < MAX_BUILD do
		task.wait(0.05)
	end

	local t = S.def(site:GetAttribute("PyramidType"))
	local o = site:GetAttribute("Origin")
	local face = o.X + t.Footprint / 2

	local built = site:FindFirstChild("Built")
	local lastAdded = os.clock()
	local added = built and built.DescendantAdded:Connect(function()
		lastAdded = os.clock()
	end)
	pcall(function()
		player:RequestStreamAroundAsync(o, 5)
	end)
	local settleStart = os.clock()
	while os.clock() - lastAdded < SETTLE and os.clock() - settleStart < MAX_SETTLE do
		task.wait(0.05)
	end
	if added then
		added:Disconnect()
	end
	if built then
		local textures = {}
		for _, d in built:GetDescendants() do
			if d:IsA("Texture") then
				table.insert(textures, d)
			end
		end
		local preloaded = false
		task.spawn(function()
			pcall(function()
				game:GetService("ContentProvider"):PreloadAsync(textures)
			end)
			preloaded = true
		end)
		local pt = os.clock()
		while not preloaded and os.clock() - pt < PRELOAD do
			task.wait(0.05)
		end
	end
	task.wait(math.max(0, MIN_DARK - (os.clock() - t0)))

	local centre = o + Vector3.new(0, t.Height * 0.32, 0)
	local radius = t.Footprint * 0.95
	local height = o.Y + t.Height * 0.75
	local function orbitAt(a)
		local m = 1 / 0.9
		local e
		if a < 0.1 then
			e = m * a * a / 0.2
		elseif a > 0.9 then
			local b = 1 - a
			e = 1 - m * b * b / 0.2
		else
			e = m * (0.05 + (a - 0.1))
		end
		local ang = e * math.pi * 2
		return CFrame.lookAt(Vector3.new(o.X + math.cos(ang) * radius, height, o.Z + math.sin(ang) * radius), centre)
	end
	cam.CameraType = Enum.CameraType.Scriptable
	cam.CFrame = orbitAt(0)
	fade(false, false)
	showTitle(t.Name:upper())
	local start = os.clock()
	local titleGone = false
	while true do
		local a = math.clamp((os.clock() - start) / ORBIT, 0, 1)
		cam.CFrame = orbitAt(a)
		if not titleGone and a > 0.8 then
			titleGone = true
			hideTitle()
		end
		if a >= 1 then
			break
		end
		RunService.RenderStepped:Wait()
	end

	local shot = CFrame.lookAt(Vector3.new(face + 7, o.Y + 6, o.Z), Vector3.new(face - 12, o.Y + 5, o.Z))
	local fly = TweenService:Create(cam, TweenInfo.new(FLY, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), { CFrame = shot })
	fly:Play()
	task.wait(FLY - FADE)
	fade(true)

	ch = player.Character
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	hum = ch and ch:FindFirstChildOfClass("Humanoid")
	local spot = Vector3.new(face + 12, o.Y + 4, o.Z)
	if held.Parent then
		held.Anchored = wasAnchored
	end
	if hrp and not training() then
		ch:PivotTo(CFrame.lookAt(spot, Vector3.new(face, spot.Y, o.Z)))
		hrp.AssemblyLinearVelocity = Vector3.zero
		cam.CFrame = CFrame.lookAt(spot + Vector3.new(11, 5, 0), Vector3.new(face, o.Y + 5, o.Z))
	end
	cam.CameraType = Enum.CameraType.Custom
	if hum then
		cam.CameraSubject = hum
	end
	for _, g in hidden do
		if g.Parent then
			g.Enabled = true
		end
	end
	task.wait(0.2)
	fade(false)
	playing = false
end

local function play()
	if playing then
		return
	end
	local ok, err = pcall(run)
	if not ok then
		warn("[Cinematic] " .. tostring(err))
		for _, g in state.hidden or {} do
			if g.Parent then
				g.Enabled = true
			end
		end
		if state.held and state.held.Parent then
			state.held.Anchored = state.wasAnchored == true
		end
		local cam = workspace.CurrentCamera
		cam.CameraType = Enum.CameraType.Custom
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			cam.CameraSubject = hum
		end
		title.Visible = false
		dark.BackgroundTransparency = 1
		playing = false
	end
end

site:GetAttributeChangedSignal("ChamberOpen"):Connect(function()
	if site:GetAttribute("ChamberOpen") then
		task.spawn(play)
	end
end)
