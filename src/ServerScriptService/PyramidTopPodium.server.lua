-- Affiche l'avatar réel du TOP 1 Pyramides sur le podium du Temple des champions.
-- Lit l'attribut "Top" (JSON) publié par LeaderboardService sur Leaderboard_Pyramids
-- et reconstruit la statue dès que le TOP 1 change.
local Players = game:GetService("Players")
local Http = game:GetService("HttpService")

local BOARD_KEY = "Pyramids"
local STATUE_HEIGHT = 14
local IDLE_ANIM = "rbxassetid://507766388"
local GOLD = Color3.fromRGB(255, 196, 46)
local GOLD_LIGHT = Color3.fromRGB(255, 215, 90)

local map = workspace:WaitForChild("PyramidMap")
local boards = map:WaitForChild("Leaderboards")
local board = boards:WaitForChild("Leaderboard_" .. BOARD_KEY)
local temple = boards:WaitForChild("ChampionsTemple", 30)
local podium = temple and temple:WaitForChild("Podium", 30)
if not podium then
	warn("[PyramidTopPodium] Podium introuvable")
	return
end

local function spotCFrame()
	local spot = podium:FindFirstChild("Top1Spot")
	if spot then
		return spot.CFrame
	end
	return podium:GetPivot()
end

-- plaque dorée sur la face du piédestal (construite dans la map)
local function setPlaque(name, value)
	local plaque = podium:FindFirstChild("ChampionPlaque")
	local gui = plaque and plaque:FindFirstChild("PlaqueGui")
	if not gui then
		return
	end
	local nameLabel = gui:FindFirstChild("PlayerName")
	local scoreLabel = gui:FindFirstChild("Score")
	if nameLabel then
		nameLabel.Text = name or "-"
	end
	if scoreLabel then
		scoreLabel.Text = value and ("🔺 " .. value .. " pyramides") or ""
	end
end

local current = { userId = nil, model = nil }

-- couronne dorée qui flotte et tourne au-dessus de la tête
local function addCrown(model, headTop)
	local crown = Instance.new("Model")
	crown.Name = "ChampionCrown"
	local center = Vector3.new(headTop.X, headTop.Y + 2.2, headTop.Z)
	local function piece(name, size, cf, color, neon)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = cf
		p.Color = color
		p.Material = neon and Enum.Material.Neon or Enum.Material.SmoothPlastic
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.CastShadow = false
		p.Parent = crown
		return p
	end
	local base = piece("Band", Vector3.new(0.6, 3.2, 3.2), CFrame.new(center) * CFrame.Angles(0, 0, math.rad(90)), GOLD)
	base.Shape = Enum.PartType.Cylinder
	for i = 0, 4 do
		local a = math.rad(i * 72)
		local offset = Vector3.new(math.cos(a) * 1.25, 0.75, math.sin(a) * 1.25)
		piece("Spike", Vector3.new(0.45, 1, 0.45), CFrame.new(center + offset), GOLD_LIGHT)
		piece("Gem", Vector3.new(0.35, 0.35, 0.35), CFrame.new(center + offset + Vector3.new(0, 0.65, 0)) * CFrame.Angles(0, math.rad(45), math.rad(45)), (i % 2 == 0) and Color3.fromRGB(33, 84, 185) or Color3.fromRGB(200, 30, 40), true)
	end
	crown.PrimaryPart = base
	crown.Parent = model
	task.spawn(function()
		local t0 = os.clock()
		while crown.Parent do
			local t = os.clock() - t0
			crown:PivotTo(CFrame.new(center + Vector3.new(0, math.sin(t * 2) * 0.25, 0)) * CFrame.Angles(0, t * 1.2, 0) * CFrame.Angles(0, 0, math.rad(90)))
			task.wait(1 / 30)
		end
	end)
end

-- lumière dorée et particules autour de la statue
local function addAura(root, height)
	local light = Instance.new("PointLight")
	light.Color = GOLD_LIGHT
	light.Range = 18
	light.Brightness = 2.5
	light.Shadows = false
	light.Parent = root

	-- les particules suivent la forme de la pièce : volume invisible de la taille de la statue
	local holder = Instance.new("Part")
	holder.Name = "AuraVolume"
	holder.Size = Vector3.new(height * 0.55, height, height * 0.55)
	holder.CFrame = root.CFrame
	holder.Transparency = 1
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanTouch = false
	holder.CanQuery = false
	holder.Parent = root.Parent

	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Name = "ChampionSparkles"
	sparkles.Color = ColorSequence.new(GOLD_LIGHT, GOLD)
	sparkles.LightEmission = 0.8
	sparkles.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
	sparkles.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	sparkles.Lifetime = NumberRange.new(1.5, 2.5)
	sparkles.Rate = 18
	sparkles.Speed = NumberRange.new(1, 2)
	sparkles.SpreadAngle = Vector2.new(180, 180)
	sparkles.Acceleration = Vector3.new(0, 1.5, 0)
	sparkles.Shape = Enum.ParticleEmitterShape.Cylinder
	sparkles.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
	sparkles.Parent = holder
end

local function clearStatue()
	if current.model then
		current.model:Destroy()
	end
	current.model = nil
end

local function buildStatue(entry)
	local ok, model = pcall(Players.CreateHumanoidModelFromUserId, Players, entry.userId)
	if not ok or not model then
		warn("[PyramidTopPodium] Avatar indisponible pour " .. tostring(entry.userId) .. " : " .. tostring(model))
		return
	end
	-- le TOP 1 a pu changer pendant le chargement de l'avatar
	if current.userId ~= entry.userId then
		model:Destroy()
		return
	end
	clearStatue()

	model.Name = "Top1Statue"
	local animate = model:FindFirstChild("Animate")
	if animate then
		animate:Destroy()
	end
	local hum = model:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
		hum.BreakJointsOnDeath = false
	end
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.CanCollide = false
			d.CanTouch = false
			d.CanQuery = false
		end
	end
	local root = model:FindFirstChild("HumanoidRootPart")
	if root then
		root.Anchored = true
		model.PrimaryPart = root
	end

	-- la boîte englobante inclut les accessoires (ailes, familiers...), on mesure le corps seul
	local function bodyExtent()
		local lo, hi = math.huge, -math.huge
		for _, part in model:GetChildren() do
			if part:IsA("BasePart") and part ~= root then
				lo = math.min(lo, part.Position.Y - part.Size.Y / 2)
				hi = math.max(hi, part.Position.Y + part.Size.Y / 2)
			end
		end
		return lo, hi
	end
	local lo, hi = bodyExtent()
	if hi > lo then
		model:ScaleTo(model:GetScale() * STATUE_HEIGHT / (hi - lo))
	end
	-- debout sur le podium, face à l'entrée
	local spot = spotCFrame()
	model:PivotTo(spot)
	lo = bodyExtent()
	model:PivotTo(model:GetPivot() + Vector3.new(0, spot.Position.Y - lo, 0))
	model.Parent = podium

	current.model = model
	setPlaque(entry.name or ("Player " .. entry.userId), entry.value)

	if hum then
		local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
		local anim = Instance.new("Animation")
		anim.AnimationId = IDLE_ANIM
		local okAnim, track = pcall(animator.LoadAnimation, animator, anim)
		if okAnim and track then
			track.Looped = true
			track:Play()
			-- la pose d'attente abaisse un peu le corps : on recale les pieds sur le podium
			task.wait(0.3)
			if current.model == model then
				model:PivotTo(model:GetPivot() + Vector3.new(0, spot.Position.Y - bodyExtent(), 0))
			end
		end
	end
	if current.model ~= model then
		return
	end
	local head = model:FindFirstChild("Head")
	if head then
		addCrown(model, head.Position + Vector3.new(0, head.Size.Y / 2, 0))
	end
	if root then
		addAura(root, STATUE_HEIGHT)
	end
end

local function refresh()
	local raw = board:GetAttribute("Top")
	if type(raw) ~= "string" then
		return
	end
	local ok, top = pcall(Http.JSONDecode, Http, raw)
	if not ok or type(top) ~= "table" then
		return
	end
	local first = top[1]
	if not first or not first.userId then
		current.userId = nil
		clearStatue()
		setPlaque(nil, nil)
		return
	end
	if first.userId == current.userId then
		setPlaque(first.name, first.value)
		return
	end
	current.userId = first.userId
	task.spawn(buildStatue, first)
end

board:GetAttributeChangedSignal("Top"):Connect(refresh)
refresh()