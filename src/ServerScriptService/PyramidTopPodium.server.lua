-- Affiche l'avatar réel du TOP 1 Pyramides sur le podium du Temple des champions.
-- Lit l'attribut "Top" (JSON) publié par LeaderboardService sur Leaderboard_Pyramids
-- et reconstruit la statue dès que le TOP 1 change.
local Players = game:GetService("Players")
local Http = game:GetService("HttpService")

local BOARD_KEY = "Pyramids"
local STATUE_HEIGHT = 9
local IDLE_ANIM = "rbxassetid://507766388"

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
	local first = podium:FindFirstChild("First")
	if first then
		return CFrame.new(first.Position + Vector3.new(0, first.Size.Y / 2, 0))
	end
	return podium:GetPivot()
end

local current = { userId = nil, model = nil, valueLabel = nil }

local function makeTag(model, name, value)
	local head = model:FindFirstChild("Head")
	if not head then
		return nil
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "Top1Tag"
	gui.Size = UDim2.fromScale(8, 3)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 3.2, 0)
	gui.LightInfluence = 0
	gui.MaxDistance = 150
	gui.Parent = head

	local list = Instance.new("UIListLayout")
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.Parent = gui

	local function label(text, color, h)
		local l = Instance.new("TextLabel")
		l.Size = UDim2.fromScale(1, h)
		l.BackgroundTransparency = 1
		l.Font = Enum.Font.FredokaOne
		l.TextScaled = true
		l.TextColor3 = color
		l.Text = text
		l.Parent = gui
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 3
		stroke.Color = Color3.fromRGB(40, 20, 10)
		stroke.Parent = l
		return l
	end
	label("👑 TOP 1", Color3.fromRGB(255, 205, 0), 0.38)
	label(name, Color3.new(1, 1, 1), 0.34)
	return label("🔺 " .. value, Color3.fromRGB(255, 220, 120), 0.28)
end

local function clearStatue()
	if current.model then
		current.model:Destroy()
	end
	current.model = nil
	current.valueLabel = nil
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
	current.valueLabel = makeTag(model, entry.name or ("Player " .. entry.userId), entry.value or "")

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
		return
	end
	if first.userId == current.userId then
		if current.valueLabel then
			current.valueLabel.Text = "🔺 " .. tostring(first.value)
		end
		return
	end
	current.userId = first.userId
	task.spawn(buildStatue, first)
end

board:GetAttributeChangedSignal("Top"):Connect(refresh)
refresh()
