local Sandstone = require(game:GetService("ReplicatedStorage"):WaitForChild("SandstoneSurface"))
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local folder = RS:WaitForChild("PyramidHUD")
local C = require(folder:WaitForChild("Config"))
local S = require(folder:WaitForChild("PyramidShape"))
local ServerBoosts = require(script.Parent:WaitForChild("PyramidServerBoosts"))

local remote = folder:FindFirstChild("Build") or Instance.new("RemoteEvent")
remote.Name = "Build"
remote.Parent = folder

local site = workspace:WaitForChild("PyramidMap"):WaitForChild("PyramidSite")
local origin
local t, U

local SS = game:GetService("ServerStorage")
local hiddenStore = SS:FindFirstChild("_HiddenUnderPyramid") or Instance.new("Folder")
hiddenStore.Name = "_HiddenUnderPyramid"
hiddenStore.Parent = SS
local hidden = {}
local function coverDecor(half)
	local x0, x1, z0, z1 = origin.X - half, origin.X + half, origin.Z - half, origin.Z + half
	local function under(o)
		local ok, cf, size = pcall(function()
			if o:IsA("BasePart") then
				return o.CFrame, o.Size
			end
			return o:GetBoundingBox()
		end)
		if not ok then
			return false
		end
		local h = size / 2
		local ex = math.abs(cf.RightVector.X) * h.X + math.abs(cf.UpVector.X) * h.Y + math.abs(cf.LookVector.X) * h.Z
		local ez = math.abs(cf.RightVector.Z) * h.X + math.abs(cf.UpVector.Z) * h.Y + math.abs(cf.LookVector.Z) * h.Z
		return cf.X + ex > x0 and cf.X - ex < x1 and cf.Z + ez > z0 and cf.Z - ez < z1
	end
	for o, parent in hidden do
		if not under(o) then
			o.Parent = parent
			hidden[o] = nil
		end
	end
	for _, name in { "Decor", "Dunes", "FarPyramids" } do
		local f = site.Parent:FindFirstChild(name)
		if f then
			for _, o in f:GetDescendants() do
				if (o:IsA("Model") or o:IsA("BasePart")) and o.Parent:IsA("Folder") and under(o) then
					hidden[o] = o.Parent
					o.Parent = hiddenStore
				end
			end
		end
	end
end

local function applyType(key)
	t = S.def(key)
	U = t.PerCell
	site:SetAttribute("PyramidType", t.Key)
	site:SetAttribute("CoinsMultiplier", t.Mult)
	site:SetAttribute("BlockColor", t.Color)
	site:SetAttribute("BlocksTotal", t.Total)
	origin = S.origin(site, t)
	site:SetAttribute("Origin", origin)
	local function square(part, side)
		if part then
			part.Size = Vector3.new(side, part.Size.Y, side)
			part.Position = Vector3.new(origin.X, part.Position.Y, origin.Z)
		end
	end
	square(site:FindFirstChild("Foundation"), t.Side)
	square(site:FindFirstChild("FoundationEdge"), t.Side + 8)
	local area = site:FindFirstChild("BuildArea")
	square(area, t.Footprint)
	if area then
		area:SetAttribute("Base", t.Footprint)
	end
	coverDecor((t.Side + 8) / 2 + 4)
	local holo = site:FindFirstChild("HologramAnchor")
	if holo then
		holo.Position = Vector3.new(origin.X, origin.Y + t.Height + 10, origin.Z)
		local text = holo:FindFirstChildWhichIsA("TextLabel", true)
		if text then
			text.Text = t.Name:upper()
		end
	end
end
applyType(S.pick())

local model = site:FindFirstChild("Built") or Instance.new("Model")
model.Name = "Built"
model.Parent = site

local FACES = { Enum.NormalId.Top, Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right }

local liftQueue = {}
local function liftOut(cf, size)
	local half = size / 2
	for _, p in Players:GetPlayers() do
		local ch = p.Character
		local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
		if hrp then
			local d = hrp.Position - cf.Position
			if math.abs(d.X) < half.X + 30 and math.abs(d.Z) < half.Z + 30 and d.Y > -half.Y - 10 and d.Y < half.Y + 12 then
				local q = liftQueue[p]
				if not q then
					q = {}
					liftQueue[p] = q
					task.defer(function()
						liftQueue[p] = nil
						if p.Parent then
							remote:FireClient(p, "lift", q)
						end
					end)
				end
				table.insert(q, { cf.Position, size })
			end
		end
	end
end

local function piece(name, cf, size)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Color = t.Color
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanTouch = false
	Sandstone.Apply(p)
	p.Size = size
	p.CFrame = cf
	p.Parent = model
	liftOut(cf, size)
	return p
end

local floors = {}
local cur

local function newFloor(f)
	cur = { f = f, k = f <= t.Floors and S.side(t, f) or 0, fill = {}, count = 0, runs = {}, growing = {} }
end

local function runPart(run, r)
	local cf, size = S.box(t, origin, cur.f, r, r, run[1], run[2])
	if run[3] then
		run[3].Size, run[3].CFrame = size, cf
		liftOut(cf, size)
	else
		run[3] = piece("Row" .. r, cf, size)
	end
end

local function finishStone(idx)
	local g = cur.growing[idx]
	if g then
		g:Destroy()
		cur.growing[idx] = nil
	end
	local k = cur.k
	local r, c = idx // k, idx % k
	local list = cur.runs[r]
	if not list then
		list = {}
		cur.runs[r] = list
	end
	local before, after
	for _, run in list do
		if run[2] == c - 1 then
			before = run
		elseif run[1] == c + 1 then
			after = run
		end
	end
	if before and after then
		before[2] = after[2]
		after[3]:Destroy()
		table.remove(list, table.find(list, after))
		runPart(before, r)
	elseif before then
		before[2] = c
		runPart(before, r)
	elseif after then
		after[1] = c
		runPart(after, r)
	else
		local run = { c, c }
		table.insert(list, run)
		runPart(run, r)
	end
end

local function progress(part, have)
	local bb = part:FindFirstChild("Progress")
	if not bb then
		bb = Instance.new("BillboardGui")
		bb.Name = "Progress"
		bb.Size = UDim2.fromScale(3.4, 0.9)
		bb.StudsOffsetWorldSpace = Vector3.new(0, t.Cell / 2 + 0.9, 0)
		bb.MaxDistance = 70
		bb.LightInfluence = 0
		bb.Parent = part
		local back = Instance.new("Frame")
		back.Name = "Back"
		back.Size = UDim2.fromScale(1, 1)
		back.BackgroundColor3 = Color3.fromRGB(28, 24, 36)
		back.BackgroundTransparency = 0.2
		back.Parent = bb
		Instance.new("UICorner", back).CornerRadius = UDim.new(0.5, 0)
		local rim = Instance.new("UIStroke")
		rim.Color = Color3.fromRGB(14, 12, 20)
		rim.Thickness = 2
		rim.Parent = back
		local fill = Instance.new("Frame")
		fill.Name = "Fill"
		fill.BackgroundColor3 = Color3.fromRGB(90, 225, 60)
		fill.Parent = back
		Instance.new("UICorner", fill).CornerRadius = UDim.new(0.5, 0)
		local text = Instance.new("TextLabel")
		text.Name = "Count"
		text.BackgroundTransparency = 1
		text.Size = UDim2.fromScale(1, 1)
		text.Font = Enum.Font.FredokaOne
		text.TextScaled = true
		text.TextColor3 = Color3.new(1, 1, 1)
		text.ZIndex = 2
		text.Parent = back
		local ink = Instance.new("UIStroke")
		ink.Color = Color3.fromRGB(14, 12, 20)
		ink.Thickness = 2
		ink.Parent = text
	end
	bb.Back.Fill.Size = UDim2.fromScale(have / U, 1)
	bb.Back.Count.Text = have .. "/" .. U
end

local function deposit(idx, amount)
	local have = cur.fill[idx] or 0
	local add = math.min(amount, U - have)
	if add <= 0 then
		return 0
	end
	have += add
	cur.fill[idx] = have
	cur.count += add
	if have >= U then
		finishStone(idx)
	else
		local g = cur.growing[idx]
		if not g then
			local k = cur.k
			local r, c = idx // k, idx % k
			g = piece("Stone" .. idx, S.box(t, origin, cur.f, r, r, c, c))
			cur.growing[idx] = g
		end
		progress(g, have)
	end
	return add
end

local function fillRows(need)
	local k, added, rows, changed = cur.k, 0, {}, {}
	for idx = 0, k * k - 1 do
		if need <= 0 then
			break
		end
		local have = cur.fill[idx] or 0
		local add = math.min(need, U - have)
		if add > 0 then
			cur.fill[idx] = have + add
			cur.count += add
			need -= add
			added += add
			rows[idx // k] = true
			table.insert(changed, { idx, have + add })
		end
	end
	for r in rows do
		for _, run in cur.runs[r] or {} do
			run[3]:Destroy()
		end
		local list = {}
		cur.runs[r] = list
		local run
		for c = 0, k - 1 do
			local idx = r * k + c
			local have = cur.fill[idx] or 0
			if have >= U then
				local g = cur.growing[idx]
				if g then
					g:Destroy()
					cur.growing[idx] = nil
				end
				if run and run[2] == c - 1 then
					run[2] = c
				else
					run = { c, c }
					table.insert(list, run)
				end
			elseif have > 0 then
				local g = cur.growing[idx] or piece("Stone" .. idx, S.box(t, origin, cur.f, r, r, c, c))
				cur.growing[idx] = g
				progress(g, have)
			end
		end
		for _, rn in list do
			runPart(rn, r)
		end
	end
	return added, changed
end

local function clearFloorParts()
	for _, list in cur.runs do
		for _, run in list do
			run[3]:Destroy()
		end
	end
	for _, g in cur.growing do
		g:Destroy()
	end
end

local function floorDone()
	return cur.f <= t.Floors and cur.count >= cur.k * cur.k * U
end

local function encode()
	if cur.f > t.Floors then
		return ""
	end
	local chars = table.create(cur.k * cur.k, "0")
	for idx, n in cur.fill do
		chars[idx + 1] = string.char(48 + n)
	end
	return table.concat(chars)
end

local function sync(target)
	if target then
		remote:FireClient(target, "sync", cur.f, encode())
	else
		remote:FireAllClients("sync", cur.f, encode())
	end
end

local function closeFloor()
	clearFloorParts()
	local f, k = cur.f, cur.k
	floors[f] = piece("Floor" .. f, S.box(t, origin, f, 0, k - 1, 0, k - 1))
	newFloor(f + 1)
end

local function placedTotal()
	return (cur.f > t.Floors and t.Total) or (t.Starts[cur.f] * U + cur.count)
end

local target, filling, fillGen = 0, false, 0

local function rebuild(total)
	fillGen += 1
	filling, target = false, 0
	if cur then
		clearFloorParts()
	end
	for f, p in floors do
		p:Destroy()
		floors[f] = nil
	end
	total = math.clamp(total, 0, t.Total)
	local f, j = S.floorOf(t, total // U)
	for n = 1, math.min(f - 1, t.Floors) do
		local k = S.side(t, n)
		floors[n] = piece("Floor" .. n, S.box(t, origin, n, 0, k - 1, 0, k - 1))
	end
	newFloor(f)
	if f <= t.Floors then
		fillRows(j * U + total % U)
	end
end

local helpers = {}
local carry = {}
local finishing = false
local expected = 0

local function addContribution(userId, blocks)
	if blocks and blocks > 0 then
		helpers[userId] = (helpers[userId] or 0) + blocks
	end
end

local function coinReward(blocks)
	return math.floor(blocks * S.CoinsPerBlock * t.Mult * ServerBoosts.Get("coins") + 0.5)
end

local function pyramidReward(base)
	return math.max(1, math.floor(base * ServerBoosts.Get("pyramids") + 0.5))
end

local function setTotal(value)
	expected = value
	site:SetAttribute("BlocksPlaced", value)
end

local FILL_STEPS, FILL_WAIT = 60, 0.03
local finish
local function grow(total)
	target = math.max(target, math.min(total, t.Total))
	if filling then
		return
	end
	filling = true
	fillGen += 1
	local gen = fillGen
	task.spawn(function()
		local step = math.max(1, math.ceil((target - placedTotal()) / FILL_STEPS))
		while gen == fillGen and placedTotal() < target and cur.f <= t.Floors do
			local want = math.min(target - placedTotal(), math.max(step, U * cur.k))
			if want >= cur.k * cur.k * U - cur.count then
				closeFloor()
				sync()
			else
				local _, changed = fillRows(want)
				remote:FireAllClients("cells", cur.f, changed)
			end
			setTotal(placedTotal())
			if placedTotal() >= t.Total then
				finish()
				break
			end
			task.wait(FILL_WAIT)
		end
		if gen == fillGen then
			filling = false
		end
	end)
end

local function newPyramid(key)
	finishing = true
	table.clear(helpers)
	remote:FireAllClients("roll", key)
	task.delay(S.RollTime, function()
		applyType(key)
		rebuild(0)
		setTotal(0)
		sync()
		finishing = false
		local blocks = 0
		for _, c in carry do
			addContribution(c[1], c[2])
			blocks += c[2]
		end
		table.clear(carry)
		if blocks > 0 then
			grow(math.min(blocks, t.Total))
		end
	end)
end

function finish()
	if finishing then
		return
	end
	finishing = true
	for _, p in Players:GetPlayers() do
		if (helpers[p.UserId] or 0) >= (C.PyramidMinContribution or 1) then
			local baseAdd = (p:GetAttribute("Pharaoh") and C.Pharaoh and C.Pharaoh.Pyramids) or 1
			local add = pyramidReward(baseAdd)
			p:SetAttribute(C.Stats.Pyramids, (p:GetAttribute(C.Stats.Pyramids) or 0) + add)
		end
	end
	remote:FireAllClients("complete", t.Name)
	site:SetAttribute("ChamberMult", t.Chamber or 2)
	site:SetAttribute("ChamberOpen", true)
	task.spawn(function()
		while site:GetAttribute("ChamberOpen") do
			site:GetAttributeChangedSignal("ChamberOpen"):Wait()
		end
		newPyramid(S.pick(t.Key))
	end)
end

site:GetAttributeChangedSignal("BlocksPlaced"):Connect(function()
	local value = site:GetAttribute("BlocksPlaced") or 0
	if value == expected then
		return
	end
	if value > expected then
		grow(value + (filling and math.max(0, target - expected) or 0))
		site:SetAttribute("BlocksPlaced", expected)
		return
	end
	rebuild(value)
	expected = value
	sync()
end)

rebuild(math.clamp(site:GetAttribute("BlocksPlaced") or 0, 0, t.Total))
setTotal(placedTotal())

local buckets = {}
local MAX_LIST = 64
local function place(p, f, list)
	if type(list) ~= "table" then
		return
	end
	local function refuse(from)
		local out = {}
		for i = from, math.min(#list, MAX_LIST) do
			table.insert(out, list[i])
		end
		if #out > 0 then
			remote:FireClient(p, "reject", f, out)
		end
	end
	local ch = p.Character
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	local carrying = p:GetAttribute(C.Stats.Carrying) or 0
	if finishing or cur.f > t.Floors or f ~= cur.f or not hrp or carrying <= 0 then
		refuse(1)
		return
	end
	local now = os.clock()
	local per = math.max(1, p:GetAttribute("BlocksPerPlace") or 1)
	local rate = per / S.PlaceCooldown
	local burst = per * 2
	local b = buckets[p]
	if not b then
		b = { tokens = burst, time = now }
		buckets[p] = b
	end
	b.tokens = math.min(burst, b.tokens + (now - b.time) * rate)
	b.time = now
	local hum = hrp.Parent and hrp.Parent:FindFirstChildOfClass("Humanoid")
	local speed = math.min(hrp.AssemblyLinearVelocity.Magnitude, (hum and hum.WalkSpeed or 16) * 1.5)
	local reach = S.range(p) + t.Cell + 6 + speed * 0.3
	local k = cur.k
	local used, changed, rejected = 0, {}, {}
	local closed = false
	for i = 1, math.min(#list, MAX_LIST) do
		local idx = list[i]
		local ok = not closed and type(idx) == "number" and idx == math.floor(idx) and idx >= 0 and idx < k * k
			and b.tokens >= 1 and used < carrying and (cur.fill[idx] or 0) < U
			and (S.cellPos(t, origin, f, idx) - hrp.Position).Magnitude <= reach
		if ok then
			used += deposit(idx, 1)
			b.tokens -= 1
			table.insert(changed, { idx, cur.fill[idx] })
			closed = floorDone()
		else
			table.insert(rejected, idx)
		end
	end
	if #rejected > 0 then
		remote:FireClient(p, "reject", f, rejected)
	end
	if used == 0 then
		return
	end
	p:SetAttribute(C.Stats.Carrying, carrying - used)
	p:SetAttribute("Blocks", (p:GetAttribute("Blocks") or 0) + used)
	local gain = coinReward(used)
	p:SetAttribute(C.Stats.Coins, (p:GetAttribute(C.Stats.Coins) or 0) + gain)
	addContribution(p.UserId, used)
	remote:FireAllClients("cells", f, changed)
	if closed then
		closeFloor()
		sync()
	end
	setTotal(placedTotal())
	remote:FireClient(p, "placed", used, gain)
	if placedTotal() >= t.Total then
		finish()
	end
end

local INSTA_WAIT, INSTA_STEPS = 0.03, 90
local instaRunning = {}
local function atSite(hrp)
	local d = hrp.Position - origin
	local half = t.Footprint / 2 + 14
	return math.abs(d.X) <= half and math.abs(d.Z) <= half and d.Y < t.Height + 20
end
local function instaPlace(p)
	local ch = p.Character
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	if instaRunning[p] or not p:GetAttribute("Pharaoh") or finishing or not hrp or not atSite(hrp) then
		return
	end
	local carrying = p:GetAttribute(C.Stats.Carrying) or 0
	if carrying <= 0 then
		return
	end
	instaRunning[p] = true
	p:SetAttribute("InstaPlacing", true)
	local per = math.max(20, math.ceil(carrying / INSTA_STEPS))
	task.spawn(function()
		local order, orderFloor, at = nil, nil, 1
		while p.Parent and not finishing and cur.f <= t.Floors do
			carrying = p:GetAttribute(C.Stats.Carrying) or 0
			if carrying <= 0 or not hrp.Parent then
				break
			end
			if orderFloor ~= cur.f then
				order, orderFloor, at = {}, cur.f, 1
				local dist = {}
				for idx = 0, cur.k * cur.k - 1 do
					table.insert(order, idx)
					dist[idx] = (S.cellPos(t, origin, cur.f, idx) - hrp.Position).Magnitude
				end
				table.sort(order, function(a, b)
					return dist[a] < dist[b]
				end)
			end
			local f = cur.f
			local used, changed, budget = 0, {}, math.min(per, carrying)
			while budget > 0 and at <= #order do
				local idx = order[at]
				local put = deposit(idx, budget)
				if put > 0 then
					used += put
					budget -= put
					table.insert(changed, { idx, cur.fill[idx] })
				end
				if (cur.fill[idx] or 0) >= U then
					at += 1
				end
				if floorDone() then
					break
				end
			end
			if used > 0 then
				p:SetAttribute(C.Stats.Carrying, carrying - used)
				p:SetAttribute("Blocks", (p:GetAttribute("Blocks") or 0) + used)
				local gain = coinReward(used)
				p:SetAttribute(C.Stats.Coins, (p:GetAttribute(C.Stats.Coins) or 0) + gain)
				addContribution(p.UserId, used)
				remote:FireAllClients("cells", f, changed)
				remote:FireClient(p, "placed", used, gain)
			end
			if floorDone() then
				closeFloor()
				sync()
			end
			setTotal(placedTotal())
			if placedTotal() >= t.Total then
				finish()
				break
			end
			if used == 0 and at > #order then
				break
			end
			task.wait(INSTA_WAIT)
		end
		instaRunning[p] = nil
		if p.Parent then
			p:SetAttribute("InstaPlacing", nil)
		end
	end)
end

local function robuxFill(p, amount)
	if finishing or cur.f > t.Floors then
		return false
	end
	local base = math.max(placedTotal(), filling and target or 0)
	local fits = math.clamp(t.Total - base, 0, amount)
	p:SetAttribute("Blocks", (p:GetAttribute("Blocks") or 0) + amount)
	local gain = coinReward(amount)
	p:SetAttribute(C.Stats.Coins, (p:GetAttribute(C.Stats.Coins) or 0) + gain)
	addContribution(p.UserId, fits)
	remote:FireClient(p, "placed", amount, gain)
	if amount > fits then
		table.insert(carry, { p.UserId, amount - fits })
	end
	if fits > 0 then
		grow(base + fits)
	end
	return true
end

_G.PyramidBuild = {
	Fill = robuxFill,
	Start = function(key)
		if finishing then
			return nil
		end
		key = S.Types[key] and key or S.pick(t.Key)
		newPyramid(key)
		return S.Types[key].Name
	end,
}

local lastSync = {}
remote.OnServerEvent:Connect(function(p, action, f, list)
	if action == "place" then
		place(p, f, list)
	elseif action == "sync" then
		local now = os.clock()
		if now - (lastSync[p] or 0) >= 1 then
			lastSync[p] = now
			sync(p)
		end
	elseif action == "insta" then
		instaPlace(p)
	end
end)
Players.PlayerRemoving:Connect(function(p)
	buckets[p] = nil
	lastSync[p] = nil
end)
