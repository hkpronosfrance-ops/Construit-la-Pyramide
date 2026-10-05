local Sandstone = require(game:GetService("ReplicatedStorage"):WaitForChild("SandstoneSurface"))
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local folder = RS:WaitForChild("PyramidHUD")
local B = require(folder:WaitForChild("BlocksConfig"))
local remote = folder:WaitForChild("Blocks")
local P = B.Pile
local centre = B.Mine.Center
local FLOOR = centre.Y

local base = B.Color
local function tint(k)
	local m = 0.82 + 0.26 * k
	return Color3.new(math.min(1, base.R * m), math.min(1, base.G * m), math.min(1, base.B * m))
end

local rng = Random.new(P.Seed)
local spots = {}
for li, layer in P.Layers do
	local s = P.Spacing
	local shift = (li % 2 == 0) and s / 2 or 0
	local r = layer.Radius
	for gx = -r, r, s do
		for gz = -r, r, s do
			local x = gx + shift + rng:NextNumber(-0.7, 0.7)
			local z = gz + shift + rng:NextNumber(-0.7, 0.7)
			local size = rng:NextNumber(P.Size[1], P.Size[2])
			if x * x + z * z <= (r - size / 2) ^ 2 then
				local shade = rng:NextInteger(P.Shade[1], P.Shade[2])
				table.insert(spots, {
					x = centre.X + x,
					z = centre.Z + z,
					dy = layer.Y + rng:NextNumber(-0.35, 0.35),
					rot = CFrame.Angles(rng:NextNumber(-0.45, 0.45), rng:NextNumber(0, math.pi * 2), rng:NextNumber(-0.45, 0.45)),
					size = size,
					shade = (shade - P.Shade[1]) / math.max(1, P.Shade[2] - P.Shade[1]),
					layer = li,
					key = rng:NextNumber(),
				})
			end
		end
	end
end
table.sort(spots, function(a, b)
	if a.layer ~= b.layer then
		return a.layer > b.layer
	end
	return a.key < b.key
end)

local holder = Instance.new("Folder")
holder.Name = "MinePile"
holder.Parent = workspace

local filler = Instance.new("Part")
filler.Name = "PileFiller"
filler.Shape = Enum.PartType.Cylinder
filler.Anchored = true
filler.CanCollide = true
filler.CanQuery = false
filler.CanTouch = false
filler.CastShadow = false
filler.Transparency = 1
filler.Material = B.Material
filler.Color = P.Filler.Color
filler.TopSurface = Enum.SurfaceType.Smooth
filler.BottomSurface = Enum.SurfaceType.Smooth

local BED_DEPTH = 0.4
local bed = Instance.new("Part")
bed.Name = "PileBed"
bed.Shape = Enum.PartType.Cylinder
bed.Anchored = true
bed.CanCollide = false
bed.CanQuery = false
bed.CanTouch = false
bed.CastShadow = false
bed.Material = B.Material
bed.TopSurface = Enum.SurfaceType.Smooth
bed.BottomSurface = Enum.SurfaceType.Smooth

local function cube(spot)
	local p = Instance.new("Part")
	p.Name = "PileBlock"
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = spot.layer > 1
	p.Material = B.Material
	p.Color = tint(spot.shade)
	Sandstone.Apply(p)
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Size = Vector3.one * spot.size
	return p
end

local function site()
	local map = workspace:FindFirstChild("PyramidMap")
	return map and map:FindFirstChild("PyramidSite")
end

local function fraction()
	local s = site()
	local total = s and s:GetAttribute("BlocksTotal") or 0
	local placed = s and s:GetAttribute("BlocksPlaced") or 0
	if total <= 0 then
		return 1
	end
	local built = math.clamp(placed / total, 0, 1)
	return P.FillFromRemaining and (1 - built) or built
end

local BOTTOM = FLOOR + 1.2
local function levelFor(f)
	return BOTTOM + (P.Depth - 1.2) * math.clamp((f - P.Thin) / (1 - P.Thin), 0, 1)
end
local function countFor(f)
	if f >= P.Thin then
		return #spots
	end
	return math.floor(#spots * f / P.Thin + 0.5)
end

local level = BOTTOM
local goal = BOTTOM
local function cfAt(spot, l)
	return CFrame.new(spot.x, l + spot.dy, spot.z) * spot.rot
end

local function placeFiller(l)
	local blend = math.clamp((l - BOTTOM) / 3, 0, 1)
	local height = (l + 2 - FLOOR) * blend
	if height < 0.4 then
		filler.Parent = nil
		bed.Parent = nil
		return
	end
	filler.Size = Vector3.new(height, P.Filler.Radius * 2, P.Filler.Radius * 2)
	filler.CFrame = CFrame.new(centre.X, FLOOR + height / 2, centre.Z) * CFrame.Angles(0, 0, math.pi / 2)
	filler.Parent = holder
	local bedHeight = (l - BED_DEPTH - FLOOR) * blend
	if bedHeight < 0.4 then
		bed.Parent = nil
		return
	end
	bed.Size = Vector3.new(bedHeight, P.Filler.Radius * 2, P.Filler.Radius * 2)
	bed.CFrame = CFrame.new(centre.X, FLOOR + bedHeight / 2, centre.Z) * CFrame.Angles(0, 0, math.pi / 2)
	bed.Parent = holder
end

local function apply(l)
	level = l
	local list, cfs = {}, {}
	for _, spot in spots do
		if spot.on and spot.part and not spot.busy then
			table.insert(list, spot.part)
			table.insert(cfs, cfAt(spot, l))
		end
	end
	if #list > 0 then
		workspace:BulkMoveTo(list, cfs, Enum.BulkMoveMode.FireCFrameChanged)
	end
	placeFiller(l)
end

local levelToken = 0
local function moveLevel(to, duration)
	levelToken += 1
	local mine = levelToken
	local from = level
	local t0 = os.clock()
	task.spawn(function()
		while levelToken == mine do
			local a = math.clamp((os.clock() - t0) / duration, 0, 1)
			local eased = 1 - (1 - a) ^ 2
			apply(from + (to - from) * eased)
			if a >= 1 then
				break
			end
			RunService.Heartbeat:Wait()
		end
	end)
end

local APPEAR = TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local VANISH = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

local function show(spot, wait)
	spot.token = (spot.token or 0) + 1
	local mine = spot.token
	if not spot.part then
		spot.part = cube(spot)
	end
	local p = spot.part
	if wait == nil then
		spot.busy = false
		p.CFrame, p.Size, p.Transparency = cfAt(spot, goal), Vector3.one * spot.size, 0
		p.Parent = holder
		return
	end
	spot.busy = true
	p.Parent = nil
	task.delay(wait, function()
		if spot.token ~= mine then
			return
		end
		local target = cfAt(spot, goal)
		p.CFrame = target + Vector3.new(0, 10, 0)
		p.Size = Vector3.one * spot.size * 0.3
		p.Transparency = 1
		p.Parent = holder
		local t = TweenService:Create(p, APPEAR, { CFrame = target, Size = Vector3.one * spot.size, Transparency = 0 })
		t:Play()
		t.Completed:Wait()
		if spot.token == mine then
			spot.busy = false
			p.CFrame = cfAt(spot, level)
		end
	end)
end

local function hide(spot, wait, comeBack)
	spot.token = (spot.token or 0) + 1
	local mine = spot.token
	local p = spot.part
	if not p or not p.Parent then
		return
	end
	spot.busy = true
	task.delay(wait, function()
		if spot.token ~= mine then
			return
		end
		local t = TweenService:Create(p, VANISH, { CFrame = p.CFrame - Vector3.new(0, 1.5, 0), Size = Vector3.one * spot.size * 0.2, Transparency = 1 })
		t:Play()
		t.Completed:Wait()
		if spot.token ~= mine then
			return
		end
		if comeBack then
			show(spot)
		else
			spot.busy = false
			p.Parent = nil
		end
	end)
end

local function refresh(animated)
	local f = fraction()
	local newGoal = levelFor(f)
	local want = countFor(f)
	local first = #spots - want + 1
	local adding, removing, staying = {}, {}, {}
	for i, spot in spots do
		local visible = i >= first
		if visible ~= (spot.on == true) then
			table.insert(visible and adding or removing, spot)
		elseif visible then
			table.insert(staying, spot)
		end
		spot.on = visible
	end
	local rising = newGoal > goal + 2
	goal = newGoal

	if not animated then
		for _, spot in adding do
			show(spot)
		end
		for _, spot in removing do
			hide(spot, 0)
		end
		apply(goal)
		return
	end

	if rising then
		for _, spot in staying do
			table.insert(adding, spot)
		end
		table.sort(adding, function(a, b)
			if a.layer ~= b.layer then
				return a.layer < b.layer
			end
			return a.key < b.key
		end)
		for n, spot in adding do
			show(spot, 2.5 * (n - 1) / math.max(1, #adding))
		end
		moveLevel(goal, 2.5)
	else
		moveLevel(goal, 0.6)
		for n = 1, math.min(14, #staying) do
			hide(staying[math.random(1, #staying)], (n - 1) * 0.03, true)
		end
		for _, spot in adding do
			show(spot, 0)
		end
		local span = math.min(2.5, #removing * 0.004)
		for n, spot in removing do
			hide(spot, span * (n - 1) / math.max(1, #removing))
		end
	end
end

local queued = false
local function queue()
	if queued then
		return
	end
	queued = true
	task.delay(0.2, function()
		queued = false
		refresh(true)
	end)
end

task.spawn(function()
	local s
	repeat
		s = site()
		if not s then
			task.wait(1)
		end
	until s
	s:GetAttributeChangedSignal("BlocksPlaced"):Connect(queue)
	s:GetAttributeChangedSignal("BlocksTotal"):Connect(queue)
	local function recolour()
		local c = s:GetAttribute("BlockColor")
		if typeof(c) == "Color3" then
			base = c
		end
		filler.Color = Color3.new(base.R * 0.62, base.G * 0.62, base.B * 0.62)
		bed.Color = Color3.new(base.R * 0.7, base.G * 0.7, base.B * 0.7)
		Sandstone.Apply(bed)
		for _, spot in spots do
			if spot.part then
				spot.part.Color = tint(spot.shade)
				Sandstone.Apply(spot.part)
			end
		end
	end
	s:GetAttributeChangedSignal("BlockColor"):Connect(recolour)
	recolour()
	refresh(false)
end)

local function fly(amount)
	local ch = player.Character
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end
	local picked = {}
	for _ = 1, 30 do
		local spot = spots[math.random(1, #spots)]
		if spot.on and spot.part and (Vector3.new(spot.x, level, spot.z) - hrp.Position).Magnitude < 22 then
			table.insert(picked, spot)
			if #picked >= math.min(amount, P.Fly) then
				break
			end
		end
	end
	for _, spot in picked do
		local p = cube(spot)
		p.Size *= 0.8
		p.CFrame = cfAt(spot, level)
		p.Parent = workspace
		local info = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		TweenService:Create(p, info, { CFrame = hrp.CFrame + Vector3.new(0, 1, 0), Size = p.Size * 0.4, Transparency = 0.3 }):Play()
		task.delay(0.36, function()
			p:Destroy()
		end)
	end
end

remote.OnClientEvent:Connect(function(kind, amount)
	if kind == "picked" then
		fly(tonumber(amount) or 1)
	end
end)
