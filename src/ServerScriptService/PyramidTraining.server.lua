local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Run = game:GetService("RunService")

local folder = RS:WaitForChild("PyramidHUD")
local C = require(folder:WaitForChild("Config"))
local T = C.Training
local ServerBoosts = require(script.Parent:WaitForChild("PyramidServerBoosts"))
local Ready = require(script.Parent:WaitForChild("PyramidPlayerReady"))
local remote = folder:FindFirstChild("Training") or Instance.new("RemoteEvent")
remote.Name = "Training"
remote.Parent = folder

local pads = workspace:WaitForChild("PyramidMap"):WaitForChild("Gym"):WaitForChild("Pads")

local adminCfg = {}
do
	local ok, cfg = pcall(require, RS:WaitForChild("BobloxAdmin"):WaitForChild("Config"))
	if ok then
		adminCfg = cfg
	end
end
local function checkAdmin(p)
	local yes = table.find(adminCfg.UserIds or {}, p.UserId) ~= nil
	if not yes and (adminCfg.GroupId or 0) > 0 then
		local ok, rank = pcall(p.GetRankInGroup, p, adminCfg.GroupId)
		yes = ok and rank >= (adminCfg.MinRank or 255)
	end
	p:SetAttribute("IsAdmin", yes or nil)
end
Players.PlayerAdded:Connect(checkAdmin)
for _, p in Players:GetPlayers() do
	task.spawn(checkAdmin, p)
end
local function isAdmin(p)
	return p:GetAttribute("IsAdmin") == true or Run:IsStudio()
end

local function allowed(p, zone)
	if p:GetAttribute("Unlocked_" .. zone.Name) then
		return true
	end
	if zone:GetAttribute("Paid") then
		return isAdmin(p), "Admin only"
	end
	local req = zone:GetAttribute("RequiredPyramids") or 0
	if (p:GetAttribute(C.Stats.Pyramids) or 0) < req then
		return false, ("Requirement: %d Pyramid%s"):format(req, req == 1 and "" or "s")
	end
	return true
end

local site = workspace.PyramidMap:WaitForChild("PyramidSite")
local function best(p)
	local m = 1
	for _, z in pads:GetChildren() do
		if not z:GetAttribute("Chamber") and allowed(p, z) then
			m = math.max(m, z:GetAttribute("Multiplier") or 1)
		end
	end
	return m
end
local function multiplier(p, zone)
	if zone:GetAttribute("Chamber") then
		return (site:GetAttribute("ChamberMult") or 2) * best(p)
	end
	return zone:GetAttribute("Multiplier") or 1
end

local function gain(p, zone, stat, base, boostAttr, quiet)
	if not Ready.IsReady(p) then
		return 0
	end
	local serverKind = stat == C.Stats.Speed and "speed" or "strength"
	local amount = base * multiplier(p, zone) * (p:GetAttribute(boostAttr) or 1)
		* ServerBoosts.Get(serverKind)
		* (1 + (p:GetAttribute(C.Stats.FriendBoost) or 0) / 100)
	amount = math.max(1, math.floor(amount + 0.5))
	p:SetAttribute(stat, (p:GetAttribute(stat) or 0) + amount)
	if not quiet then
		remote:FireClient(p, "gain", stat, amount)
	end
	return amount
end

local benching = {}
local occupied = {}

local function root(p)
	local ch = p.Character
	return ch and ch:FindFirstChild("HumanoidRootPart"), ch and ch:FindFirstChildOfClass("Humanoid")
end

local function stopBench(p, fromClient)
	local s = benching[p]
	if not s then
		return
	end
	benching[p] = nil
	occupied[s.pad] = nil
	s.prompt.Enabled = true
	p:SetAttribute("Training", nil)
	if not fromClient then
		remote:FireClient(p, "bench", nil)
	end
end

local function startBench(p, zone, pad, prompt)
	if not Ready.IsReady(p) then
		return
	end
	if benching[p] or occupied[pad] then
		return
	end
	if p:GetAttribute("OnTreadmill") then
		return
	end
	if not allowed(p, zone) then
		return
	end
	local hrp, hum = root(p)
	if not (hrp and hum) or hum.Health <= 0 then
		return
	end
	occupied[pad] = p
	prompt.Enabled = false
	benching[p] = { zone = zone, pad = pad, prompt = prompt, next = os.clock() + T.BenchInterval }
	p:SetAttribute("Training", "Bench")
	remote:FireClient(p, "bench", pad.Parent, zone:GetAttribute("Multiplier") or 1)
end

local function setupBench(zone)
	local bp = zone:FindFirstChild("BenchPress")
	local pad = bp and bp:FindFirstChild("BenchPad")
	if not pad then
		return
	end
	local prompt = pad:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.ObjectText = "Bench"
		prompt.ActionText = "Train"
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 9
		prompt.RequiresLineOfSight = false
		prompt.Style = Enum.ProximityPromptStyle.Custom
		prompt.Parent = pad
	end
	prompt.Triggered:Connect(function(p)
		startBench(p, zone, pad, prompt)
	end)
end

remote.OnServerEvent:Connect(function(p, action)
	if action == "stop" then
		stopBench(p, true)
	end
end)

local belts = {}
local function setupTreadmill(zone)
	local tm = zone:FindFirstChild("Treadmill")
	local belt = tm and tm:FindFirstChild("Belt")
	if belt then
		table.insert(belts, { belt = belt, zone = zone })
	end
end

for _, zone in pads:GetChildren() do
	setupBench(zone)
	setupTreadmill(zone)
end

local CollectionService = game:GetService("CollectionService")
local function springUnder(hrp)
	for _, w in CollectionService:GetTagged("PyramidSpring") do
		local lp = w.CFrame:PointToObjectSpace(hrp.Position)
		if math.abs(lp.X) < w.Size.X / 2 and math.abs(lp.Z) < w.Size.Z / 2 and lp.Y > -2 and lp.Y < 3.2 then
			return w
		end
	end
	return nil
end
local nextSpring = {}

local nextTread = {}
local function beltUnder(hrp)
	for _, b in belts do
		local lp = b.belt.CFrame:PointToObjectSpace(hrp.Position)
		if math.abs(lp.X) < b.belt.Size.X / 2 + 0.3 and math.abs(lp.Z) < b.belt.Size.Z / 2 and lp.Y > 0 and lp.Y < 5.5 then
			return b
		end
	end
end

task.spawn(function()
	while true do
		task.wait(0.2)
		local now = os.clock()
		for _, p in Players:GetPlayers() do
			local hrp, hum = root(p)
			local s = benching[p]
			if not Ready.IsReady(p) then
				if s then
					stopBench(p)
					s = nil
				end
				if p:GetAttribute("OnTreadmill") ~= nil then
					p:SetAttribute("OnTreadmill", nil)
				end
				if p:GetAttribute("InSpring") ~= nil then
					p:SetAttribute("InSpring", nil)
				end
				nextTread[p] = nil
				nextSpring[p] = nil
				continue
			end
			if s then
				if not hrp or not hum or hum.Health <= 0 or (hrp.Position - s.pad.Position).Magnitude > 12 then
					stopBench(p)
				elseif now >= s.next then
					s.next = now + T.BenchInterval
					gain(p, s.zone, C.Stats.Strength, T.BaseStrength, "StrengthMultiplier")
				end
			end
			local b = (not s) and hrp and hum and hum.Health > 0 and beltUnder(hrp) or nil
			local ok = b and allowed(p, b.zone)
			local name = (b and ok) and b.zone.Name or nil
			if p:GetAttribute("OnTreadmill") ~= name then
				p:SetAttribute("OnTreadmill", name)
				nextTread[p] = now + T.TreadInterval
			end
			if name and now >= (nextTread[p] or 0) then
				nextTread[p] = now + T.TreadInterval
				gain(p, b.zone, C.Stats.Speed, T.BaseSpeed, "SpeedMultiplier")
			end
			local w = (not s) and (not name) and hrp and hum and hum.Health > 0 and springUnder(hrp) or nil
			if w then
				if not nextSpring[p] then
					nextSpring[p] = now + T.TreadInterval
				elseif now >= nextSpring[p] then
					nextSpring[p] = now + T.TreadInterval
					local sp = gain(p, w, C.Stats.Speed, T.BaseSpeed, "SpeedMultiplier", true)
					local st = gain(p, w, C.Stats.Strength, T.BaseStrength, "StrengthMultiplier", true)
					remote:FireClient(p, "gainBoth", sp, st)
				end
			else
				nextSpring[p] = nil
			end
			if p:GetAttribute("InSpring") ~= (w and true or nil) then
				p:SetAttribute("InSpring", w and true or nil)
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(p)
	stopBench(p)
	nextTread[p] = nil
	nextSpring[p] = nil
end)
local function onChar(p)
	p.CharacterRemoving:Connect(function()
		stopBench(p)
	end)
end
Players.PlayerAdded:Connect(onChar)
for _, p in Players:GetPlayers() do
	onChar(p)
end
