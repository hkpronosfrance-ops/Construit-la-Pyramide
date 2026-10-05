local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

task.spawn(function()
	local RS = game:GetService("ReplicatedStorage")
	local C = require(RS:WaitForChild("PyramidHUD"):WaitForChild("Config"))
	local price = C.Pharaoh and C.Pharaoh.Price
	local ok, info = pcall(function()
		return game:GetService("MarketplaceService"):GetProductInfo(C.Pharaoh.GamePassId, Enum.InfoType.GamePass)
	end)
	if ok and info and info.PriceInRobux then
		price = info.PriceInRobux
	end
	local model = workspace:WaitForChild("PyramidMap"):WaitForChild("Pharaoh")
	local tag = model:FindFirstChild("Tag", true)
	local label = tag and tag:FindFirstChild("Price")
	if label and price then
		label.Text = tostring(price)
	end
	local prompt = model:FindFirstChild("PharaohPrompt", true)
	if prompt and price then
		prompt.ObjectText = price .. " Robux"
	end
end)
local map = workspace:WaitForChild("PyramidMap")
local model = map:FindFirstChild("Pharaoh")
if not model then
	return
end
local npc = model:WaitForChild("PharaohNPC")
local hum = npc:WaitForChild("Humanoid")
local animator = hum:WaitForChild("Animator")
local head = npc:WaitForChild("Head")
local hrp = npc:WaitForChild("HumanoidRootPart")
local neck = head:WaitForChild("Neck")
local waist = npc:WaitForChild("UpperTorso"):WaitForChild("Waist")
local staff = npc:WaitForChild("Staff")

local PINK = Color3.fromRGB(255, 92, 232)
local NEAR = 18
local LOOK = 30

local ANIMS = { Wave = 507770239, Point = 507770453, Cheer = 507770677 }
local tracks = {}
for name, id in ANIMS do
	local a = Instance.new("Animation")
	a.AnimationId = "rbxassetid://" .. id
	local t = animator:LoadAnimation(a)
	t.Priority = Enum.AnimationPriority.Action
	tracks[name] = t
end
local busyUntil = 0
local flash
local function play(name, length)
	local now = os.clock()
	if now < busyUntil then
		return false
	end
	busyUntil = now + length + 0.6
	local t = tracks[name]
	t:Play(0.3)
	task.delay(length, function()
		t:Stop(0.4)
	end)
	if name == "Cheer" then
		task.delay(0.45, flash)
	end
	return true
end

local tip = Instance.new("Attachment")
tip.Name = "AnkhTip"
tip.Position = Vector3.new(staff.Size.X / 2, staff.Size.Y / 2, 0) * 0.9
tip.Parent = staff
local sparks = Instance.new("ParticleEmitter")
sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
sparks.Color = ColorSequence.new(PINK, Color3.fromRGB(255, 220, 120))
sparks.LightEmission = 1
sparks.Rate = 0
sparks.Lifetime = NumberRange.new(0.6, 1.1)
sparks.Speed = NumberRange.new(4, 9)
sparks.SpreadAngle = Vector2.new(180, 180)
sparks.Drag = 3
sparks.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 0) })
sparks.Parent = tip
local light = Instance.new("PointLight")
light.Color = PINK
light.Range = 16
light.Brightness = 0
light.Parent = tip
flash = function()
	sparks:Emit(36)
	light.Brightness = 6
	TweenService:Create(light, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Brightness = 0 }):Play()
end

local rings, gem = {}, model:FindFirstChild("Gem")
for _, p in model:GetChildren() do
	if p.Name == "Ring" then
		table.insert(rings, p)
	end
end
local gemBase = gem and gem.CFrame
local bill = model:FindFirstChild("PharaohHologram", true)
local billBase = bill and bill.StudsOffset or Vector3.zero

local yaw, pitch = 0, 0
RunService.PreSimulation:Connect(function()
	neck.Transform = neck.Transform * CFrame.Angles(pitch * 0.8, yaw * 0.7, 0)
	waist.Transform = waist.Transform * CFrame.Angles(0, yaw * 0.3, 0)
end)
local function nearest()
	local best, bestD
	for _, p in Players:GetPlayers() do
		local ch = p.Character
		local r = ch and ch:FindFirstChild("HumanoidRootPart")
		if r then
			local d = (r.Position - hrp.Position).Magnitude
			if d < LOOK and (not bestD or d < bestD) then
				best, bestD = ch, d
			end
		end
	end
	return best, bestD
end

local wasNear = false
local nextFlourish = os.clock() + 4
RunService.RenderStepped:Connect(function(dt)
	local now = os.clock()
	local ch = nearest()
	local wantYaw, wantPitch = 0, 0
	if ch then
		local target = (ch:FindFirstChild("Head") or ch:FindFirstChild("HumanoidRootPart")).Position
		local d = hrp.CFrame:PointToObjectSpace(target) - Vector3.new(0, 1.5, 0)
		wantYaw = math.clamp(math.atan2(-d.X, -d.Z), math.rad(-60), math.rad(60))
		wantPitch = math.clamp(math.atan2(d.Y, Vector2.new(d.X, d.Z).Magnitude), math.rad(-20), math.rad(25))
	end
	local k = 1 - math.exp(-dt * 5)
	yaw += (wantYaw - yaw) * k
	pitch += (wantPitch - pitch) * k

	local mine = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local near = mine and (mine.Position - hrp.Position).Magnitude < NEAR
	if near and not wasNear then
		if player:GetAttribute("Pharaoh") then
			play("Cheer", 2.2)
		else
			play("Wave", 2.4)
		end
	end
	wasNear = near and true or false

	if now > nextFlourish then
		nextFlourish = now + 7 + math.random() * 6
		if mine and (mine.Position - hrp.Position).Magnitude < 70 then
			if math.random() < 0.6 then
				play("Cheer", 2.2)
			else
				play("Point", 2)
			end
		end
	end

	local s = math.sin(now * 2.2)
	for _, r in rings do
		r.Transparency = 0.15 + 0.2 * (0.5 + 0.5 * s)
	end
	if gem and gemBase then
		gem.CFrame = gemBase * CFrame.new(0, 0.25 + 0.2 * math.sin(now * 1.7), 0) * CFrame.Angles(0, now * 1.2, 0)
	end
	if bill then
		bill.StudsOffset = billBase + Vector3.new(0, 0.25 * math.sin(now * 1.3), 0)
	end
end)
