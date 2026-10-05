local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local folder = RS:WaitForChild("PyramidHUD")
local C = require(folder:WaitForChild("Config"))
local S = require(folder:WaitForChild("PyramidShape"))
local action = folder:WaitForChild("Action")
local remote = folder:WaitForChild("Build")

local GREEN, WHITE = Color3.fromRGB(90, 255, 110), Color3.fromRGB(255, 255, 255)

local site = workspace:WaitForChild("PyramidMap"):WaitForChild("PyramidSite")
while site:GetAttribute("Origin") == nil do
	site:GetAttributeChangedSignal("Origin"):Wait()
end
local origin = site:GetAttribute("Origin")
site:GetAttributeChangedSignal("Origin"):Connect(function()
	origin = site:GetAttribute("Origin") or origin
end)
local function def()
	return S.def(site:GetAttribute("PyramidType"))
end

local function root()
	local ch = player.Character
	return ch and ch:FindFirstChild("HumanoidRootPart")
end

local function atSite()
	local hrp = root()
	if not hrp then
		return false
	end
	local t = def()
	local half = t.Footprint / 2 + 14
	local d = hrp.Position - origin
	return math.abs(d.X) <= half and math.abs(d.Z) <= half and d.Y < t.Height + 20
end

local cur = { f = 1, fill = {} }
local pending, pendingCount = {}, 0
local fillView = setmetatable({}, {
	__index = function(_, idx)
		if pending[idx] then
			return 1
		end
		return cur.fill[idx]
	end,
})
local dropGhost
local function settle(idx, landed)
	local pd = pending[idx]
	if pd then
		pending[idx] = nil
		pendingCount -= 1
		dropGhost(pd, landed)
	end
end
remote.OnClientEvent:Connect(function(kind, f, data)
	if kind == "sync" then
		cur = { f = f, fill = {} }
		for idx = 1, #data do
			local n = string.byte(data, idx) - 48
			if n > 0 then
				cur.fill[idx - 1] = n
			end
		end
		for idx in pending do
			settle(idx, false)
		end
	elseif kind == "cells" and f == cur.f then
		for _, pair in data do
			cur.fill[pair[1]] = pair[2]
			settle(pair[1], true)
		end
	elseif kind == "reject" then
		for _, idx in data do
			settle(idx, false)
		end
	end
end)
remote:FireServer("sync")

remote.OnClientEvent:Connect(function(kind, boxes)
	if kind ~= "lift" or type(boxes) ~= "table" then
		return
	end
	local ch = player.Character
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	if not (hrp and hum) or hum.Health <= 0 then
		return
	end
	local pos = hrp.Position
	local legs = hum.RigType == Enum.HumanoidRigType.R6 and 2 or hum.HipHeight
	local feet = pos.Y - hrp.Size.Y / 2 - legs
	local rise = 0
	for _, b in boxes do
		local c, half = b[1], b[2] / 2
		local top = c.Y + half.Y
		if math.abs(pos.X - c.X) < half.X + 0.5 and math.abs(pos.Z - c.Z) < half.Z + 0.5 and feet < top - 0.05 and pos.Y > c.Y - half.Y then
			rise = math.max(rise, top - feet + 0.2)
		end
	end
	if rise > 0 then
		ch:PivotTo(ch:GetPivot() + Vector3.new(0, rise, 0))
	end
end)

local function available()
	return math.max(0, (player:GetAttribute(C.Stats.Carrying) or 0) - pendingCount)
end
local function perPress()
	return math.min(math.max(1, player:GetAttribute("BlocksPerPlace") or 1), available())
end

local glow = Instance.new("Folder")
glow.Name = "PyramidPlaceGlow"
glow.Parent = workspace
local boxes = {}

local function box(i)
	local b = boxes[i]
	if not b then
		b = Instance.new("Part")
		b.Name = "NextStone"
		b.Anchored = true
		b.CanCollide = false
		b.CanQuery = false
		b.CanTouch = false
		b.CastShadow = false
		b.Material = Enum.Material.SmoothPlastic
		local frame = Instance.new("SelectionBox")
		frame.Name = "Frame"
		frame.Adornee = b
		frame.LineThickness = 0.08
		frame.SurfaceTransparency = 1
		frame.Parent = b
		boxes[i] = b
	end
	return b
end

local pulse = 0
local trail
RunService.Heartbeat:Connect(function(dt)
	pulse += dt
	local t = def()
	local hrp = root()
	local n = perPress()
	local cells = {}
	if hrp and n > 0 and cur.f <= t.Floors and atSite() then
		local dir, speed = S.motion(hrp, hrp.Parent:FindFirstChildOfClass("Humanoid"))
		local anchor = trail and trail.floor == cur.f and os.clock() - trail.time < S.TrailTime and trail.pos or nil
		cells = S.targets(t, origin, cur.f, fillView, hrp.Position, n, S.range(player) + t.Cell, dir, speed, anchor)
	end
	local side = t.Cell + 0.1
	for i, idx in cells do
		local b = box(i)
		local colour = GREEN
		b.CFrame = CFrame.new(S.cellPos(t, origin, cur.f, idx))
		b.Size = Vector3.one * side
		b.Color = colour
		b.Transparency = 0.72 + math.sin(pulse * 5) * 0.08
		b.Frame.Color3 = colour
		b.Parent = glow
	end
	for i = #cells + 1, #boxes do
		boxes[i].Parent = nil
	end
end)

local gui = player:WaitForChild("PlayerGui"):WaitForChild("PyramidBuild")
local msg = gui:WaitForChild("Message")
local banner = gui:WaitForChild("Complete")
local coinTemplate = gui:WaitForChild("CoinPopupTemplate")
local rollTemplate = gui:WaitForChild("PyramidRoll")
msg.Visible = false
banner.Visible = false
coinTemplate.Enabled = false
rollTemplate.Visible = false

local token = 0
local function say(text)
	token += 1
	local mine = token
	msg.Text = text
	msg.Visible = true
	task.delay(1.8, function()
		if token == mine then
			msg.Visible = false
		end
	end)
end

local function popup(coins)
	local hrp = root()
	if not hrp then
		return
	end
	local bb = coinTemplate:Clone()
	bb.Name = "CoinPopup"
	bb:SetAttribute("IsTemplate", nil)
	bb.Adornee = hrp
	bb.StudsOffsetWorldSpace = coinTemplate.StudsOffsetWorldSpace + Vector3.new(math.random(-10, 10) / 10, 0, 0)
	local l = bb:WaitForChild("Text")
	local format = coinTemplate:GetAttribute("Format")
	l.Text = (type(format) == "string" and format or "+%s Coins"):format(coins)
	local st = l:FindFirstChildOfClass("UIStroke")
	bb.Enabled = true
	bb.Parent = gui
	local info = TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(bb, info, { StudsOffsetWorldSpace = bb.StudsOffsetWorldSpace + Vector3.new(0, 3, 0) }):Play()
	TweenService:Create(l, info, { TextTransparency = 1 }):Play()
	if st then
		TweenService:Create(st, info, { Transparency = 1 }):Play()
	end
	task.delay(1, function()
		bb:Destroy()
	end)
end

local STEP = 200
local function rarityColour(pct)
	if pct < 5 then
		return Color3.fromRGB(255, 90, 140)
	elseif pct < 10 then
		return Color3.fromRGB(200, 120, 255)
	elseif pct < 15 then
		return Color3.fromRGB(110, 220, 255)
	elseif pct < 25 then
		return Color3.fromRGB(255, 214, 90)
	end
	return Color3.fromRGB(235, 235, 240)
end

local PYRAMID_ICONS = {
	Mini = "rbxassetid://120369674817104",
	Small = "rbxassetid://87456809599643",
	Standard = "rbxassetid://124667642765444",
	Great = "rbxassetid://118733777756419",
	Giant = "rbxassetid://77683856032780",
	Colossal = "rbxassetid://102284739714024",
}
task.spawn(function()
	local images = {}
	for _, asset in PYRAMID_ICONS do table.insert(images, asset) end
	pcall(function() game:GetService("ContentProvider"):PreloadAsync(images) end)
end)

local function entry(template, parent, key, y)
	local def = S.Types[key]
	local pct = math.floor(def.Weight + 0.5)
	local e = template:Clone()
	e.Name = key
	e:SetAttribute("IsTemplate", nil)
	e.Position = UDim2.new(template.Position.X.Scale, template.Position.X.Offset, 0, y)
	e.Visible = true
	e.Parent = parent
	local sc = e:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", e)
	local icon = e:WaitForChild("Icon")
	icon.Image = PYRAMID_ICONS[key] or PYRAMID_ICONS.Standard
	local name = e:WaitForChild("PyramidName")
	name.Text = def.Name
	name.TextColor3 = def.Color:Lerp(Color3.new(1, 1, 1), 0.25)
	local chance = e:WaitForChild("Chance")
	chance.Text = pct .. "%"
	chance.TextColor3 = rarityColour(pct)
	local function fade(alpha)
		icon.ImageTransparency = alpha
		for _, d in e:GetDescendants() do
			if d:IsA("TextLabel") then
				d.TextTransparency = alpha
			elseif d:IsA("UIStroke") then
				d.Transparency = alpha
			end
		end
	end
	return e, sc, fade
end

local function randomKey()
	local sum = 0
	for _, def in S.Types do
		sum += def.Weight
	end
	local roll = math.random() * sum
	for key, def in S.Types do
		roll -= def.Weight
		if roll <= 0 then
			return key
		end
	end
	return S.Current
end

local tick = Instance.new("Sound")
tick.SoundId = "rbxasset://sounds/clickfast.wav"
tick.Volume = 0.4
tick.Parent = gui

local function drawNext(target)
	if not S.Types[target] then
		return
	end
	local old = gui:FindFirstChild("PyramidRollShown")
	if old then
		old:Destroy()
	end
	local layer = rollTemplate:Clone()
	layer.Name = "PyramidRollShown"
	local dim = rollTemplate:GetAttribute("DimTransparency")
	dim = type(dim) == "number" and dim or rollTemplate.BackgroundTransparency
	layer.BackgroundTransparency = 1
	layer.Visible = true
	layer.Parent = gui
	TweenService:Create(layer, TweenInfo.new(0.3), { BackgroundTransparency = dim }):Play()
	local stage = layer:WaitForChild("Stage")
	local fit = stage:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", stage)
	fit.Scale = math.clamp(gui.AbsoluteSize.Y / 820, 0.55, 1.1)
	local reel = stage:WaitForChild("Reel")
	local entryTemplate = stage:WaitForChild("EntryTemplate")
	entryTemplate.Visible = false
	local centre = entryTemplate.Position.Y.Offset
	local N = 26
	local keys = {}
	keys[N] = target
	for i = N - 1, 1, -1 do
		local key
		repeat
			key = randomKey()
		until key ~= keys[i + 1]
		keys[i] = key
	end
	local items = {}
	for i = 1, N do
		local e, sc, fade = entry(entryTemplate, reel, keys[i], centre - (i - 1) * STEP)
		items[i] = { e = e, sc = sc, fade = fade, y = centre - (i - 1) * STEP }
	end
	local travel = (N - 1) * STEP
	local duration = math.max(2, S.RollTime - 1.6)
	local t0 = os.clock()
	local lastIndex = 0
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local a = math.clamp((os.clock() - t0) / duration, 0, 1)
		local offset = travel * (1 - (1 - a) ^ 4)
		reel.Position = UDim2.fromOffset(0, offset)
		for _, it in items do
			local d = math.abs(it.y + offset - centre) / STEP
			it.fade(math.clamp(d * 0.45, 0, 0.85))
			it.sc.Scale = 1 - math.clamp(d * 0.12, 0, 0.3)
		end
		local index = math.floor(offset / STEP + 0.5)
		if index ~= lastIndex then
			lastIndex = index
			tick:Play()
		end
		if a >= 1 then
			conn:Disconnect()
			local win = items[N]
			win.sc.Scale = 1.25
			TweenService:Create(win.sc, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1.1 }):Play()
			task.delay(1.2, function()
				TweenService:Create(layer, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
				local f0 = os.clock()
				local out
				out = RunService.RenderStepped:Connect(function()
					local k = math.clamp((os.clock() - f0) / 0.3, 0, 1)
					for _, it in items do
						it.fade(math.max(k, 0))
					end
					if k >= 1 then
						out:Disconnect()
						layer:Destroy()
					end
				end)
			end)
		end
	end)
end

local POPUP_EVERY = 0.35
local coinSum, coinTimer = 0, false
remote.OnClientEvent:Connect(function(kind, a, b)
	if kind == "placed" then
		coinSum += tonumber(b) or (tonumber(a) or 1) * S.CoinsPerBlock
		if not coinTimer then
			coinTimer = true
			task.delay(POPUP_EVERY, function()
				coinTimer = false
				if coinSum > 0 then
					popup(coinSum)
				end
				coinSum = 0
			end)
		end
	elseif kind == "roll" then
		drawNext(a)
	elseif kind == "complete" then
		local format = banner:GetAttribute("Format")
		banner.Text = (type(format) == "string" and format or "%s COMPLETE!"):format(tostring(a or "Pyramid"):upper())
		banner.Visible = true
		task.delay(4, function()
			banner.Visible = false
		end)
	end
end)

local touchHeld = false
local touchInput
local function watchTile(o)
	if o:IsA("GuiButton") and o.Name == "PickUp" then
		local function press(input)
			return input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1
		end
		o.InputBegan:Connect(function(input)
			if press(input) then
				touchHeld = true
				touchInput = input
			end
		end)
		o.InputEnded:Connect(function(input)
			if press(input) then
				touchHeld = false
			end
		end)
	end
end
UIS.InputEnded:Connect(function(input)
	if input == touchInput then
		touchHeld = false
		touchInput = nil
	end
end)
local pg = player:WaitForChild("PlayerGui")
for _, o in pg:GetDescendants() do
	watchTile(o)
end
pg.DescendantAdded:Connect(watchTile)

local function held()
	return touchHeld
		or (UIS:IsKeyDown(Enum.KeyCode.E) and not UIS:GetFocusedTextBox())
		or UIS:IsGamepadButtonDown(Enum.UserInputType.Gamepad1, Enum.KeyCode.ButtonX)
end

local function carried()
	return player:GetAttribute(C.Stats.Carrying) or 0
end

local ghosts = Instance.new("Folder")
ghosts.Name = "PyramidFlyingBlocks"
ghosts.Parent = workspace
local FLY = 0.18
local ARC = 3
local WAIT = 1.5
local flying = {}

local FACES = { Enum.NormalId.Top, Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right }
local function ghostPart(t)
	local g = Instance.new("Part")
	g.Name = "FlyingBlock"
	g.Anchored = true
	g.CanCollide = false
	g.CanQuery = false
	g.CanTouch = false
	g.CastShadow = false
	g.Material = Enum.Material.SmoothPlastic
	g.TopSurface = Enum.SurfaceType.Smooth
	g.BottomSurface = Enum.SurfaceType.Smooth
	local c = site:GetAttribute("BlockColor")
	g.Color = typeof(c) == "Color3" and c or t.Color
	local surface = RS:FindFirstChild("SandstoneSurface")
	if surface then
		require(surface).Apply(g)
		return g
	end
	for _, face in FACES do
		local tex = Instance.new("Texture")
		tex.Texture = S.Studs
		tex.Face = face
		tex.StudsPerTileU = t.Cell / 3
		tex.StudsPerTileV = t.Cell / 3
		tex.Transparency = 0.3
		tex.Parent = g
	end
	return g
end

local function pileTop(hrp)
	local pile = hrp.Parent:FindFirstChild("CarriedBlocks")
	local best
	if pile then
		for _, part in pile:GetChildren() do
			if part:IsA("BasePart") and (not best or part.Position.Y > best.Position.Y) then
				best = part
			end
		end
	end
	return best and best.Position or hrp.Position + Vector3.new(0, 3, 0)
end

local function launch(t, idx, from, to)
	local g = ghostPart(t)
	g.Size = Vector3.one * t.Cell * 0.55
	g.CFrame = CFrame.new(from)
	g.Parent = ghosts
	local pd = { ghost = g, time = os.clock(), from = from, to = to, size = t.Cell }
	pending[idx] = pd
	pendingCount += 1
	flying[pd] = true
end

dropGhost = function(pd, landed)
	local g = pd.ghost
	if landed then
		local left = FLY - (os.clock() - pd.time)
		if left <= 0 then
			flying[pd] = nil
			g:Destroy()
		else
			task.delay(left, function()
				flying[pd] = nil
				g:Destroy()
			end)
		end
		return
	end
	flying[pd] = nil
	TweenService:Create(g, TweenInfo.new(0.15), { Transparency = 1, Size = g.Size * 0.3 }):Play()
	task.delay(0.16, function()
		g:Destroy()
	end)
end

RunService.RenderStepped:Connect(function()
	local now = os.clock()
	for pd in flying do
		local a = math.clamp((now - pd.time) / FLY, 0, 1)
		local e = 1 - (1 - a) ^ 2
		local g = pd.ghost
		if g.Parent then
			g.CFrame = CFrame.new(pd.from:Lerp(pd.to, e) + Vector3.new(0, ARC * math.sin(math.pi * a), 0))
				* CFrame.Angles(0, (1 - e) * 1.5, (1 - e) * 0.8)
			g.Size = Vector3.one * pd.size * (0.55 + 0.45 * e)
		end
	end
	for idx, pd in pending do
		if now - pd.time > WAIT then
			settle(idx, false)
		end
	end
end)

local SEND = 30
local budget, lastSend = 0, 0
local function perPlace()
	return math.max(1, player:GetAttribute("BlocksPerPlace") or 1)
end

local function sendBlocks(count)
	local hrp = root()
	local t = def()
	if not hrp or count <= 0 or cur.f > t.Floors then
		return 0
	end
	local dir, speed = S.motion(hrp, hrp.Parent:FindFirstChildOfClass("Humanoid"))
	local anchor = trail and trail.floor == cur.f and os.clock() - trail.time < S.TrailTime and trail.pos or nil
	local list = S.targets(t, origin, cur.f, fillView, hrp.Position, count, S.range(player) + t.Cell, dir, speed, anchor)
	if #list == 0 then
		return 0
	end
	local from = pileTop(hrp)
	local sum = Vector3.zero
	for _, idx in list do
		local to = S.cellPos(t, origin, cur.f, idx)
		sum += to
		launch(t, idx, from, to)
	end
	trail = { pos = sum / #list, time = os.clock(), floor = cur.f }
	remote:FireServer("place", cur.f, list)
	lastSend = os.clock()
	return #list
end

local lastInsta = 0
local function pharaoh()
	return player:GetAttribute("Pharaoh") == true
end
local function insta()
	if carried() > 0 and not player:GetAttribute("InstaPlacing") and os.clock() - lastInsta > 0.4 then
		lastInsta = os.clock()
		remote:FireServer("insta")
	end
end

action.Event:Connect(function(kind)
	if kind ~= "PickUp" or not atSite() then
		return
	end
	if carried() <= 0 then
		say("Get blocks from the mine first!")
		return
	end
	if pharaoh() then
		insta()
		return
	end
	sendBlocks(math.min(perPlace(), available()))
	budget = 0
end)

RunService.Heartbeat:Connect(function(dt)
	if not held() then
		budget = 0
		return
	end
	if pharaoh() then
		if atSite() then
			insta()
		end
		return
	end
	budget = math.min(perPlace(), budget + dt * perPlace() / S.PlaceCooldown)
	if budget >= 1 and os.clock() - lastSend >= 1 / SEND and available() > 0 and atSite() then
		local sent = sendBlocks(math.min(math.floor(budget), available()))
		budget -= sent
	end
end)
