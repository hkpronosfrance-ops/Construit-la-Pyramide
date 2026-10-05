local Sandstone = require(game:GetService("ReplicatedStorage"):WaitForChild("SandstoneSurface"))
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local folder = RS:WaitForChild("PyramidHUD")
local C = require(folder:WaitForChild("Config"))
local B = require(folder:WaitForChild("BlocksConfig"))
local V = B.Visual

local remote = folder:FindFirstChild("Blocks") or Instance.new("RemoteEvent")
remote.Name = "Blocks"
remote.Parent = folder

local site = workspace:WaitForChild("PyramidMap"):WaitForChild("PyramidSite")
local function blockColour()
	local c = site:GetAttribute("BlockColor")
	return typeof(c) == "Color3" and c or B.Color
end

local CARRY, CAP = C.Stats.Carrying, C.Stats.Capacity

local PhysicsService = game:GetService("PhysicsService")
local DROPPED, CHARS = "PyramidDropped", "PyramidCharacters"
pcall(PhysicsService.RegisterCollisionGroup, PhysicsService, DROPPED)
pcall(PhysicsService.RegisterCollisionGroup, PhysicsService, CHARS)
PhysicsService:CollisionGroupSetCollidable(DROPPED, CHARS, false)
local function characterGroup(ch)
	for _, d in ch:GetDescendants() do
		if d:IsA("BasePart") then
			d.CollisionGroup = CHARS
		end
	end
	ch.DescendantAdded:Connect(function(d)
		if d:IsA("BasePart") then
			d.CollisionGroup = CHARS
		end
	end)
end
local function watchCharacters(p)
	p.CharacterAdded:Connect(characterGroup)
	if p.Character then
		characterGroup(p.Character)
	end
end
Players.PlayerAdded:Connect(watchCharacters)
for _, p in Players:GetPlayers() do
	watchCharacters(p)
end

local function refreshCapacity(p)
	p:SetAttribute(CAP, B.capacity(p:GetAttribute(C.Stats.Strength)))
end

local FULL = V.PerFloor / V.Slots

local function sizeOf(blocks)
	if blocks <= FULL then
		local k = math.clamp((blocks - 1) / (FULL - 1), 0, 1)
		return V.Small + (V.FullSize - V.Small) * k ^ 0.7
	end
	return math.min(V.Max, V.FullSize * (blocks / FULL) ^ (1 / 3))
end

local function layout(n, g)
	local S = V.Slots
	local stones = {}
	local function add(floor, slot, blocks)
		table.insert(stones, { slot = slot, floor = floor, size = sizeOf(blocks), blocks = blocks })
	end
	if n <= 0 then
		return stones, 0
	end
	if n > V.Floors * V.PerFloor then
		local k = (g and g.floor == V.Floors) and g.count or 0
		local each = n / (V.Floors * S - k)
		for f = 1, V.Floors do
			for slot = 1, (f == V.Floors) and S - k or S do
				add(f, slot, each)
			end
		end
		return stones, each * (S - k)
	end
	local f = math.ceil(n / V.PerFloor)
	for below = 1, f - 1 do
		for k = 1, S do
			add(below, k, FULL)
		end
	end
	local m = n - (f - 1) * V.PerFloor
	local slots = S - ((g and g.floor == f) and g.count or 0)
	if m <= slots then
		for k = 1, m do
			add(f, k, 1)
		end
	else
		for k = 1, slots do
			add(f, k, m / slots)
		end
	end
	return stones, m
end
local gone = {}

local YAW = { 4, -9, 12, -5, 8, -12 }
local APPEAR = TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local piles = {}

local function groundOffset(hrp, hum)
	if hum.RigType == Enum.HumanoidRigType.R6 then
		return -(hrp.Size.Y / 2 + 2)
	end
	return -(hum.HipHeight + hrp.Size.Y / 2)
end

local function cube(model, hrp)
	local part = Instance.new("Part")
	part.Name = "CarriedBlock"
	part.Color = blockColour()
	Sandstone.Apply(part)
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Massless = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = true
	part.CFrame = hrp.CFrame
	part.Parent = model
	local weld = Instance.new("Weld")
	weld.Part0 = hrp
	weld.Part1 = part
	weld.Parent = part
	return part, weld
end

local function render(p)
	local ch = p.Character
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	if not (hrp and hum) then
		return
	end
	local pile = piles[p]
	if not pile or pile.model.Parent ~= ch then
		if pile then
			pile.model:Destroy()
		end
		local model = Instance.new("Model")
		model.Name = "CarriedBlocks"
		model.Parent = ch
		pile = { model = model, cubes = {} }
		piles[p] = pile
	end

	local stones = layout(p:GetAttribute(CARRY) or 0, gone[p])
	local base = 0
	for _, s in stones do
		if s.floor == 1 then
			base = math.max(base, s.size)
		end
	end
	local radius = 1.25 * base + 1.6
	local floorY = groundOffset(hrp, hum)

	local used = {}
	local top = {}
	for _, s in stones do
		local angle = math.rad((s.slot - 1) * 360 / V.Slots)
		local x, z = math.sin(angle) * radius, math.cos(angle) * radius
		local y = top[s.slot] or floorY
		top[s.slot] = y + s.size
		local key = s.slot .. ":" .. s.floor
		used[key] = true
		local target = CFrame.new(x, y + s.size / 2, z) * CFrame.Angles(0, math.rad(YAW[s.slot] * s.floor), 0)
		local c = pile.cubes[key]
		if not c then
			local part, weld = cube(pile.model, hrp)
			c = { part = part, weld = weld }
			pile.cubes[key] = c
			part.Size = Vector3.one * s.size * 0.4
			weld.C0 = CFrame.new(x, floorY + 0.5, z)
			c.tweens = {
				TweenService:Create(weld, APPEAR, { C0 = target }),
				TweenService:Create(part, APPEAR, { Size = Vector3.one * s.size }),
			}
			for _, t in c.tweens do
				t:Play()
			end
		else
			for _, t in c.tweens or {} do
				t:Cancel()
			end
			c.tweens = nil
			c.part.Size = Vector3.one * s.size
			c.weld.C0 = target
		end
	end
	for key, c in pile.cubes do
		if not used[key] then
			c.part:Destroy()
			pile.cubes[key] = nil
		end
	end
end

local function clearPile(p)
	local pile = piles[p]
	if pile then
		pile.model:Destroy()
		piles[p] = nil
	end
end

local function inMine(p)
	local ch = p.Character
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	if not (hrp and hum) or hum.Health <= 0 then
		return false
	end
	local d = hrp.Position - B.Mine.Center
	return Vector2.new(d.X, d.Z).Magnitude <= B.Mine.Radius and hrp.Position.Y <= B.Mine.MaxY
end

local lastGrab = {}
local function pickUp(p)
	local now = os.clock()
	if now - (lastGrab[p] or 0) < B.PickupCooldown * 0.8 then
		return
	end
	if not inMine(p) then
		return
	end
	local total = site:GetAttribute("BlocksTotal") or 0
	if total > 0 and (site:GetAttribute("BlocksPlaced") or 0) >= total then
		return
	end
	lastGrab[p] = now
	local carrying = p:GetAttribute(CARRY) or 0
	local capacity = p:GetAttribute(CAP) or 1
	if carrying >= capacity then
		remote:FireClient(p, "full")
		return
	end
	local per = math.max(1, p:GetAttribute("BlocksPerGrab") or 1)
	if p:GetAttribute("Pharaoh") then
		per = math.max(per, (math.floor(carrying / V.PerFloor) + 1) * V.PerFloor - carrying)
	end
	local add = math.min(per, capacity - carrying)
	p:SetAttribute(CARRY, carrying + add)
	remote:FireClient(p, "picked", add)
end

local lastThrow = {}
local function throw(p)
	local carrying = p:GetAttribute(CARRY) or 0
	local ch = p.Character
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	local now = os.clock()
	if carrying <= 0 or not hrp or now - (lastThrow[p] or 0) < 0.2 then
		return
	end
	lastThrow[p] = now
	local g = gone[p]
	local stones, topBlocks = layout(carrying, g)
	local last = stones[#stones]
	if not last then
		return
	end
	local onTop = 0
	for _, s in stones do
		if s.floor == last.floor then
			onTop += 1
		end
	end
	local size = last.size
	local pile = piles[p]
	local from = pile and pile.cubes[last.slot .. ":" .. last.floor]
	local look = hrp.CFrame.LookVector
	local start = from and from.part.CFrame or CFrame.new(hrp.Position - look * 3 + Vector3.new(0, 1, 0))
	local removed = onTop == 1 and math.ceil(topBlocks) or math.max(1, math.floor(last.blocks + 0.5))
	if onTop == 1 then
		gone[p] = nil
	elseif last.blocks > 1 then
		gone[p] = { floor = last.floor, count = ((g and g.floor == last.floor) and g.count or 0) + 1 }
	end
	p:SetAttribute(CARRY, math.max(0, carrying - removed))

	local T = B.Drop
	local out = start.Position - hrp.Position
	out = Vector3.new(out.X, 0, out.Z)
	out = out.Magnitude > 0.1 and out.Unit or Vector3.new(-look.X, 0, -look.Z).Unit
	local stone = Instance.new("Part")
	stone.Name = "DroppedBlocks"
	stone.Size = Vector3.one * size
	stone.Color = blockColour()
	Sandstone.Apply(stone)
	stone.TopSurface = Enum.SurfaceType.Smooth
	stone.BottomSurface = Enum.SurfaceType.Smooth
	stone.CanTouch = false
	stone.CanQuery = false
	stone.CollisionGroup = DROPPED
	stone.CFrame = start
	stone.Parent = workspace
	stone:SetNetworkOwner(nil)
	stone.AssemblyLinearVelocity = out * T.Push + Vector3.new(0, T.Lift, 0)
	stone.AssemblyAngularVelocity = Vector3.new(math.random() - 0.5, 0, math.random() - 0.5) * 6
	task.delay(T.Life, function()
		if stone.Parent then
			local fade = TweenService:Create(stone, TweenInfo.new(0.35), { Transparency = 1, Size = stone.Size * 0.4 })
			fade:Play()
			fade.Completed:Wait()
			stone:Destroy()
		end
	end)
end

local function finished()
	local total = site:GetAttribute("BlocksTotal") or 0
	return total > 0 and (site:GetAttribute("BlocksPlaced") or 0) >= total
end

local function spill(p)
	if (p:GetAttribute(CARRY) or 0) <= 0 then
		return
	end
	local ch = p.Character
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	local pile = piles[p]
	if hrp and pile then
		for _, c in pile.cubes do
			local from = c.part
			local stone = Instance.new("Part")
			stone.Name = "SpilledBlocks"
			stone.Size = from.Size
			stone.Color = blockColour()
			Sandstone.Apply(stone)
			stone.TopSurface = Enum.SurfaceType.Smooth
			stone.BottomSurface = Enum.SurfaceType.Smooth
			stone.CanTouch = false
			stone.CanQuery = false
			stone.CanCollide = false
			stone.CFrame = from.CFrame
			stone.Parent = workspace
			stone:SetNetworkOwner(nil)
			local out = from.Position - hrp.Position
			out = Vector3.new(out.X, 0, out.Z)
			out = out.Magnitude > 0.1 and out.Unit or hrp.CFrame.LookVector
			stone.AssemblyLinearVelocity = out * (14 + math.random() * 10) + Vector3.new(0, 18 + math.random() * 8, 0)
			stone.AssemblyAngularVelocity = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 12
			task.delay(0.25, function()
				if stone.Parent then
					stone.CanCollide = true
				end
			end)
			task.delay(B.Throw.Life + 0.8, function()
				if stone.Parent then
					local fade = TweenService:Create(stone, TweenInfo.new(0.4), { Transparency = 1, Size = stone.Size * 0.4 })
					fade:Play()
					fade.Completed:Wait()
					stone:Destroy()
				end
			end)
		end
	end
	p:SetAttribute(CARRY, 0)
end

local spilled = false
local function onPlaced()
	if not finished() then
		spilled = false
	elseif not spilled then
		spilled = true
		for _, p in Players:GetPlayers() do
			spill(p)
		end
	end
end
site:GetAttributeChangedSignal("BlocksPlaced"):Connect(onPlaced)
site:GetAttributeChangedSignal("BlocksTotal"):Connect(onPlaced)

remote.OnServerEvent:Connect(function(p, action)
	if action == "pickup" then
		pickUp(p)
	elseif action == "drop" then
		throw(p)
	end
end)

local function onJoin(p)
	if p:GetAttribute(CARRY) == nil then
		p:SetAttribute(CARRY, 0)
	end
	refreshCapacity(p)
	p:GetAttributeChangedSignal(C.Stats.Strength):Connect(function()
		refreshCapacity(p)
	end)
	local before = p:GetAttribute(CARRY) or 0
	p:GetAttributeChangedSignal(CARRY):Connect(function()
		local now = p:GetAttribute(CARRY) or 0
		if now > before then
			gone[p] = nil
		end
		before = now
		render(p)
	end)
	p:GetAttributeChangedSignal(CAP):Connect(function()
		render(p)
	end)
	p.CharacterAdded:Connect(function(ch)
		ch:WaitForChild("HumanoidRootPart", 10)
		ch:WaitForChild("Humanoid", 10)
		render(p)
		if finished() then
			task.delay(0.6, spill, p)
		end
	end)
	p.CharacterRemoving:Connect(function()
		clearPile(p)
	end)
	if p.Character then
		task.spawn(render, p)
	end
end

site:GetAttributeChangedSignal("BlockColor"):Connect(function()
	local c = blockColour()
	for _, pile in piles do
		for _, cube in pile.cubes do
			cube.part.Color = c
			Sandstone.Apply(cube.part)
		end
	end
end)

Players.PlayerAdded:Connect(onJoin)
for _, p in Players:GetPlayers() do
	task.spawn(onJoin, p)
end
Players.PlayerRemoving:Connect(function(p)
	clearPile(p)
	lastGrab[p] = nil
	lastThrow[p] = nil
	gone[p] = nil
end)
