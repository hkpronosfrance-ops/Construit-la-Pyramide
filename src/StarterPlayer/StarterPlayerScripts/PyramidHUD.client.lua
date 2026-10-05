local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local CAS = game:GetService("ContextActionService")
local MPS = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local folder = RS:WaitForChild("PyramidHUD")
local C = require(folder:WaitForChild("Config"))
local L = require(folder:WaitForChild("Localization"))

local function bootstrapFrenchLocalization()
	if not L.isFrench() then
		return
	end

	local busy = setmetatable({}, { __mode = "k" })
	local hooked = setmetatable({}, { __mode = "k" })

	local function translateProperty(obj, prop)
		if busy[obj] then
			return
		end
		local ok, current = pcall(function()
			return obj[prop]
		end)
		if not ok or type(current) ~= "string" or current == "" then
			return
		end
		local translated = L.translate(current)
		if translated ~= current then
			busy[obj] = true
			pcall(function()
				obj[prop] = translated
			end)
			busy[obj] = nil
		end
	end

	local function hook(obj)
		if hooked[obj] then
			return
		end
		if obj:IsA("TextLabel") or obj:IsA("TextButton") then
			hooked[obj] = true
			translateProperty(obj, "Text")
			obj:GetPropertyChangedSignal("Text"):Connect(function()
				translateProperty(obj, "Text")
			end)
		elseif obj:IsA("TextBox") then
			hooked[obj] = true
			translateProperty(obj, "PlaceholderText")
			obj:GetPropertyChangedSignal("PlaceholderText"):Connect(function()
				translateProperty(obj, "PlaceholderText")
			end)
		elseif obj:IsA("ProximityPrompt") then
			hooked[obj] = true
			translateProperty(obj, "ActionText")
			translateProperty(obj, "ObjectText")
			obj:GetPropertyChangedSignal("ActionText"):Connect(function()
				translateProperty(obj, "ActionText")
			end)
			obj:GetPropertyChangedSignal("ObjectText"):Connect(function()
				translateProperty(obj, "ObjectText")
			end)
		end
	end

	local function watch(root)
		for _, obj in root:GetDescendants() do
			hook(obj)
		end
		root.DescendantAdded:Connect(function(obj)
			task.defer(hook, obj)
		end)
	end

	watch(player:WaitForChild("PlayerGui"))
	watch(workspace)
end

task.spawn(bootstrapFrenchLocalization)
local Tile = require(folder:WaitForChild("TileStyle"))
local action = folder:WaitForChild("Action")

task.spawn(function()
	require(RS:WaitForChild("BobloxAdmin"):WaitForChild("Client")).start()
end)
task.spawn(function()
	require(RS:WaitForChild("BobloxSettings"):WaitForChild("Client")).start()
end)

local WHITE = Color3.new(1, 1, 1)

local pg = player:WaitForChild("PlayerGui")
local gui = pg:WaitForChild("PyramidHUD")
local friendGui = pg:WaitForChild("PyramidFriendBoost")
local keysGui = pg:WaitForChild("PyramidKeys")
for _, g in { gui, friendGui, keysGui } do
	Tile.linkOutlines(g)
end

local UNITS = { "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }
local function commas(n)
	n = math.floor(tonumber(n) or 0)
	local sign = n < 0 and "-" or ""
	n = math.abs(n)
	if n < 1000 then
		return sign .. tostring(n)
	end
	local i, v = 0, n
	while v >= 1000 and i < #UNITS do
		v /= 1000
		i += 1
	end
	local d = n >= 1e5 and 2 or 1
	local p = 10 ^ d
	v = math.floor(v * p + 1e-9) / p
	local text = string.format("%." .. d .. "f", v):gsub("%.?0+$", "")
	return sign .. text .. UNITS[i]
end

local function mult(v)
	return (string.format("%.2f", v):gsub("%.?0+$", ""))
end

local function prefix(label, fallback)
	local p = label:GetAttribute("Prefix")
	return type(p) == "string" and p or fallback
end

local function pop(obj)
	local sc = obj:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
	sc.Parent = obj
	sc.Scale = 1.12
	TweenService:Create(sc, TweenInfo.new(0.18, Enum.EasingStyle.Back), { Scale = 1 }):Play()
end

local function juicy(button)
	local sc = button:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
	sc.Parent = button
	local function to(v)
		TweenService:Create(sc, TweenInfo.new(0.14, Enum.EasingStyle.Back), { Scale = v }):Play()
	end
	button.MouseEnter:Connect(function()
		to(1.08)
	end)
	button.MouseLeave:Connect(function()
		to(1)
	end)
	button.MouseButton1Down:Connect(function()
		to(0.94)
	end)
	button.MouseButton1Up:Connect(function()
		to(1.08)
	end)
end

local rootScale = gui:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
rootScale.Parent = gui
local function rescale()
	local v = workspace.CurrentCamera.ViewportSize
	if v.X < 100 then
		return
	end
	rootScale.Scale = math.clamp(math.min(v.X / 1500, v.Y / 860), 0.5, 1)
end
rescale()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)

local toast = gui:WaitForChild("Toast")
toast.Visible = false
local toastToken = 0
local function say(text)
	toastToken += 1
	local t = toastToken
	toast.Text = text
	toast.Visible = true
	pop(toast)
	task.delay(2.5, function()
		if toastToken == t then
			toast.Visible = false
		end
	end)
end

local function prompt(productId)
	if productId and productId > 0 then
		MPS:PromptProductPurchase(player, productId)
	else
		say("Not available right now")
	end
end

local priceCache = {}
local latest = setmetatable({}, { __mode = "k" })
local function livePrice(productId, fallback, done, key)
	key = key or done
	latest[key] = productId
	if not productId or productId <= 0 then
		done(fallback)
		return
	end
	if priceCache[productId] then
		done(priceCache[productId])
		return
	end
	task.spawn(function()
		local ok, info = pcall(MPS.GetProductInfo, MPS, productId, Enum.InfoType.Product)
		local p = ok and info and info.PriceInRobux
		if p then
			priceCache[productId] = p
		end
		if latest[key] == productId then
			done(p or fallback)
		end
	end)
end

local function full(n)
	local str = tostring(math.floor(tonumber(n) or 0))
	while true do
		local k
		str, k = str:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
		if k == 0 then
			return str
		end
	end
end

local stats = gui:WaitForChild("Stats")
local rows = {}
for _, key in { "Coins", "Speed", "Strength", "Pyramids" } do
	local r = stats:WaitForChild(key)
	rows[key] = { value = r:WaitForChild("Value"), sub = r:FindFirstChild("Sub") }
end

local speedEdit = stats.Speed:WaitForChild("SpeedEditIcon")
do
	local face = speedEdit:WaitForChild("Icon")
	local rest = face.ImageColor3
	local hit = speedEdit:WaitForChild("Hit")
	hit.MouseEnter:Connect(function()
		face.ImageColor3 = rest:Lerp(WHITE, 0.6)
	end)
	hit.MouseLeave:Connect(function()
		face.ImageColor3 = rest
	end)
	hit.Activated:Connect(function()
		face.ImageColor3 = rest
		require(RS:WaitForChild("BobloxSettings"):WaitForChild("Client")).open("MaxSpeed")
	end)
end
local TextService = game:GetService("TextService")

local function getFrenchOverlay()
	local overlay = pg:FindFirstChild("PyramidFrenchOverlay")
	if overlay then
		return overlay
	end
	overlay = Instance.new("ScreenGui")
	overlay.Name = "PyramidFrenchOverlay"
	overlay.ResetOnSpawn = false
	overlay.IgnoreGuiInset = gui.IgnoreGuiInset
	overlay.DisplayOrder = math.max(gui.DisplayOrder, keysGui.DisplayOrder) + 5
	overlay.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	overlay.Parent = pg
	return overlay
end

local editToken = 0
local function placeSpeedEdit()
	if not L.isFrench() then
		return
	end
	local sub = rows.Speed.sub
	editToken += 1
	local mine = editToken
	task.defer(function()
		if mine ~= editToken or not sub.Parent then
			return
		end

		local overlay = getFrenchOverlay()
		if speedEdit.Parent ~= overlay then
			speedEdit.Parent = overlay
		end

		local width = sub.TextBounds.X
		if width <= 0 then
			width = TextService:GetTextSize(
				sub.Text,
				sub.TextSize,
				sub.Font,
				Vector2.new(1000, math.max(100, sub.AbsoluteSize.Y))
			).X
		end

		speedEdit.Visible = true
		speedEdit.AnchorPoint = Vector2.new(0, 0.5)
		speedEdit.Position = UDim2.fromOffset(
			math.ceil(sub.AbsolutePosition.X + width + 6),
			math.ceil(sub.AbsolutePosition.Y + sub.AbsoluteSize.Y / 2)
		)
		speedEdit.ZIndex = 100
	end)
end
rows.Speed.sub:GetPropertyChangedSignal("Text"):Connect(placeSpeedEdit)
rows.Speed.sub:GetPropertyChangedSignal("TextBounds"):Connect(placeSpeedEdit)
rows.Speed.sub:GetPropertyChangedSignal("AbsolutePosition"):Connect(placeSpeedEdit)
rows.Speed.sub:GetPropertyChangedSignal("AbsoluteSize"):Connect(placeSpeedEdit)
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(placeSpeedEdit)
placeSpeedEdit()

local function attr(name)
	return player:GetAttribute(name) or 0
end

local function humanoidSpeed()
	local ch = player.Character
	local h = ch and ch:FindFirstChildOfClass("Humanoid")
	return h and h.WalkSpeed or 16
end

local lastValues = {}
local function setValue(key, text)
	local r = rows[key]
	if r.value.Text ~= text then
		if lastValues[key] ~= nil then
			pop(r.value)
		end
		lastValues[key] = text
		r.value.Text = text
	end
end

local function refreshStats()
	setValue("Coins", commas(attr(C.Stats.Coins)))
	local sm = player:GetAttribute("SpeedMultiplier") or 1
	local tm = player:GetAttribute("StrengthMultiplier") or 1
	setValue("Speed", commas(attr(C.Stats.Speed)) .. (sm > 1 and (' <font color="#6EFF6E">(x' .. mult(sm) .. ")</font>") or ""))
	setValue("Strength", commas(attr(C.Stats.Strength)) .. (tm > 1 and (' <font color="#6EFF6E">(x' .. mult(tm) .. ")</font>") or ""))
	setValue("Pyramids", commas(attr(C.Stats.Pyramids)))
	rows.Speed.sub.Text = prefix(rows.Speed.sub, "Walk Speed: ") .. commas(math.floor(humanoidSpeed() + 0.5))
	rows.Strength.sub.Text = prefix(rows.Strength.sub, "Capacity: ") .. commas(attr(C.Stats.Carrying)) .. "/" .. commas(attr(C.Stats.Capacity))
end

local friend = friendGui:WaitForChild("FriendBoost")
local friendScale = friend:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
friendScale.Scale = rootScale.Scale
friendScale.Parent = friend
rootScale:GetPropertyChangedSignal("Scale"):Connect(function()
	friendScale.Scale = rootScale.Scale
end)
local friendText = friend:WaitForChild("Text")
local function refreshFriend()
	local v = attr(C.Stats.FriendBoost)
	friendText.Text = prefix(friendText, "Friend Boost: ") .. (v > 0 and ('<font color="#6EFF6E">+' .. v .. "%</font>") or "+0%")
end

local boostsFrame = gui:WaitForChild("Boosts")
local spinning = {}
RunService.RenderStepped:Connect(function(dt)
	for _, r in spinning do
		r.Rotation = (r.Rotation + dt * 14) % 360
	end
end)

local boostRefresh = {}
for _, b in C.Boosts do
	local holder = boostsFrame:FindFirstChild(b.Id .. "Boost")
	if not holder then
		warn("[PyramidHUD] StarterGui.PyramidHUD.Boosts has no " .. b.Id .. "Boost button")
		continue
	end
	local hs = holder:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
	hs.Parent = holder
	local face = holder:WaitForChild("Face")
	local rays = holder:FindFirstChild("Rays")
	if rays then
		table.insert(spinning, rays)
	end
	local priceText = holder:WaitForChild("Price"):WaitForChild("Text")

	local QUICK = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local function lift(k)
		TweenService:Create(hs, QUICK, { Scale = k }):Play()
	end
	face.MouseEnter:Connect(function()
		lift(1.04)
	end)
	face.MouseLeave:Connect(function()
		lift(1)
	end)
	face.MouseButton1Down:Connect(function()
		lift(0.97)
	end)
	face.MouseButton1Up:Connect(function()
		lift(1)
	end)

	local function refresh()
		local tier = C.nextTier(b, attr(b.Level))
		livePrice(tier.ProductId, tier.Price, function(price)
			priceText.Text = prefix(priceText, "ONLY ") .. full(price)
		end, priceText)
	end
	boostRefresh[b.Level] = refresh
	refresh()
	face.Activated:Connect(function()
		prompt(C.nextTier(b, attr(b.Level)).ProductId)
	end)
end

local top = gui:WaitForChild("Pyramid")
local bar = top:WaitForChild("Bar")
local fill = bar:WaitForChild("Track"):WaitForChild("Fill")
local barText = bar:WaitForChild("Count")

local multLabel = bar:WaitForChild("CoinsMultiplier")
local multGrad = multLabel:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient")
multGrad.Parent = multLabel
local function rainbow(g)
	local h0 = (os.clock() * 0.35) % 1
	local keys = {}
	for i = 0, 6 do
		keys[i + 1] = ColorSequenceKeypoint.new(i / 6, Color3.fromHSV((h0 + i * 0.12) % 1, 0.7, 1))
	end
	g.Color = ColorSequence.new(keys)
end
RunService.RenderStepped:Connect(function()
	if multLabel.Visible then
		rainbow(multGrad)
	end
end)

local offers = top:WaitForChild("Fill")
local offerButtons = {}
local chamberMode = false
local site
for i, o in C.PyramidFill do
	local b = offers:FindFirstChild("Fill" .. o.Amount)
	if not b then
		warn("[PyramidHUD] StarterGui.PyramidHUD.Pyramid.Fill has no Fill" .. o.Amount .. " button")
		continue
	end
	local t = b:WaitForChild("Amount")
	local g = i == #C.PyramidFill and t:FindFirstChildOfClass("UIGradient")
	if g then
		RunService.RenderStepped:Connect(function()
			rainbow(g)
		end)
	end
	juicy(b)
	local priceLabel = b:WaitForChild("PriceTag"):WaitForChild("Price")
	local function setPrice(price)
		priceLabel.Text = full(price)
	end
	livePrice(o.ProductId, o.Price, setPrice)
	offerButtons[i] = { label = t, setPrice = setPrice, fill = o }
	b.Activated:Connect(function()
		if not chamberMode then
			prompt(o.ProductId)
			return
		end
		local c = C.Chamber.Offers[i]
		local mins = site and site:GetAttribute("ChamberMinutes") or C.Chamber.Minutes
		if c and mins + c.Minutes <= C.Chamber.MaxMinutes then
			prompt(c.ProductId)
		end
	end)
end

local function setChamberMode(on)
	local mins = site and site:GetAttribute("ChamberMinutes") or 0
	for i, ob in offerButtons do
		local c = C.Chamber and C.Chamber.Offers[i]
		if on and c then
			ob.label.Text = "+" .. c.Minutes .. " MIN"
			ob.label.TextTransparency = mins + c.Minutes <= C.Chamber.MaxMinutes and 0 or 0.55
		else
			ob.label.Text = "+" .. full(ob.fill.Amount)
			ob.label.TextTransparency = 0
		end
		if on ~= chamberMode then
			if on and c then
				livePrice(c.ProductId, c.Price, ob.setPrice)
			else
				livePrice(ob.fill.ProductId, ob.fill.Price, ob.setPrice)
			end
		end
	end
	chamberMode = on
end

local function refreshPyramid()
	site = site or (workspace:FindFirstChild("PyramidMap") and workspace.PyramidMap:FindFirstChild("PyramidSite"))
	if site and site:GetAttribute("ChamberOpen") and C.Chamber then
		local left = math.max(0, math.floor((site:GetAttribute("ChamberEnd") or 0) - workspace:GetServerTimeNow()))
		local mins = site:GetAttribute("ChamberMinutes") or C.Chamber.Minutes
		barText.Text = ("%d:%02d"):format(left // 60, left % 60)
		multLabel.Visible = true
		multLabel.Text = ("%d / %d MIN"):format(mins, C.Chamber.MaxMinutes)
		setChamberMode(true)
		local k = math.clamp(left / math.max(1, mins * 60), 0, 1)
		TweenService:Create(fill, TweenInfo.new(0.25, Enum.EasingStyle.Linear), { Size = UDim2.fromScale(k, 1) }):Play()
		return
	end
	setChamberMode(false)
	local placed = site and site:GetAttribute("BlocksPlaced") or 0
	local total = site and site:GetAttribute("BlocksTotal") or C.PyramidTotal
	barText.Text = full(placed) .. " / " .. full(total)
	local mult = site and site:GetAttribute("CoinsMultiplier") or 1
	multLabel.Visible = mult > 1
	multLabel.Text = (string.format("%.2f", mult):gsub("%.?0+$", "")) .. "x COINS"
	local k = total > 0 and math.clamp(placed / total, 0, 1) or 0
	TweenService:Create(fill, TweenInfo.new(0.35, Enum.EasingStyle.Quad), { Size = UDim2.fromScale(k, 1) }):Play()
end

local topY = top.Position.Y.Offset
local function avoidTopbar()
	local tb = pg:FindFirstChild("GameTopbar")
	local left, right = -math.huge, math.huge
	if tb then
		for _, b in tb:GetChildren() do
			if b:IsA("GuiObject") and b.Visible then
				local x = b.AbsolutePosition.X
				if x < workspace.CurrentCamera.ViewportSize.X / 2 then
					left = math.max(left, x + b.AbsoluteSize.X)
				else
					right = math.min(right, x)
				end
			end
		end
	end
	local w = bar.AbsoluteSize.X
	local cx = workspace.CurrentCamera.ViewportSize.X / 2
	local clash = cx - w / 2 < left + 8 or cx + w / 2 > right - 8
	top.Position = UDim2.new(top.Position.X.Scale, top.Position.X.Offset, 0, clash and math.ceil(62 / rootScale.Scale) or topY)
end
task.spawn(function()
	local tb = pg:WaitForChild("GameTopbar", 30)
	if tb then
		tb.DescendantAdded:Connect(function()
			task.defer(avoidTopbar)
		end)
		for _, b in tb:GetChildren() do
			if b:IsA("GuiObject") then
				b:GetPropertyChangedSignal("Visible"):Connect(avoidTopbar)
			end
		end
	end
	avoidTopbar()
end)
bar:GetPropertyChangedSignal("AbsoluteSize"):Connect(avoidTopbar)
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
	task.defer(avoidTopbar)
end)

local function cornerScale(frame)
	local sc = frame:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
	sc.Scale = rootScale.Scale
	sc.Parent = frame
	rootScale:GetPropertyChangedSignal("Scale"):Connect(function()
		sc.Scale = rootScale.Scale
	end)
end

local hints = keysGui:WaitForChild("Keys")
cornerScale(hints)
local touchKeys = keysGui:WaitForChild("TouchKeys")
cornerScale(touchKeys)

local keyRows = {}
for _, k in C.Keys do
	local r = hints:FindFirstChild(k.Action)
	local tb = touchKeys:FindFirstChild(k.Action)
	if r then
		table.insert(keyRows, { cap = r:WaitForChild("Cap"):WaitForChild("Key"), def = k })
	end
	if tb then
		juicy(tb)
		tb.Activated:Connect(function()
			action:Fire(k.Action)
		end)
	end
	CAS:BindAction("Pyramid" .. k.Action, function(_, state)
		if state == Enum.UserInputState.Begin then
			action:Fire(k.Action)
		end
		return Enum.ContextActionResult.Pass
	end, false, k.Keyboard, k.Gamepad)
end

local frenchKeysHolder
local function setupFrenchKeysOverlay()
	if not L.isFrench() or frenchKeysHolder then
		return
	end

	local overlay = getFrenchOverlay()
	local holder = Instance.new("Frame")
	holder.Name = "FrenchKeys"
	holder.AnchorPoint = Vector2.new(1, 1)
	holder.Position = UDim2.new(1, -26, 1, -26)
	holder.Size = UDim2.fromOffset(230, 92)
	holder.BackgroundTransparency = 1
	holder.ClipsDescendants = false
	holder.ZIndex = 90
	holder.Parent = overlay

	local scale = Instance.new("UIScale")
	scale.Name = "FrenchKeysScale"
	scale.Scale = rootScale.Scale
	scale.Parent = holder
	rootScale:GetPropertyChangedSignal("Scale"):Connect(function()
		scale.Scale = rootScale.Scale
	end)

	for index, actionName in { "PickUp", "Drop" } do
		local row = hints:FindFirstChild(actionName)
		if row and row:IsA("GuiObject") then
			row.Parent = holder
			row.AnchorPoint = Vector2.new(0, 0)
			row.Position = UDim2.fromOffset(0, (index - 1) * 46)
			row.Size = UDim2.fromOffset(230, 44)
			row.ClipsDescendants = false
			row.ZIndex = 91

			local textLabel = row:FindFirstChild("Text")
			if textLabel and textLabel:IsA("GuiObject") then
				textLabel.Size = UDim2.new(1, -math.max(64, textLabel.Position.X.Offset) - 6, textLabel.Size.Y.Scale, textLabel.Size.Y.Offset)
				textLabel.ClipsDescendants = false
			end
		end
	end

	frenchKeysHolder = holder
end

setupFrenchKeysOverlay()

local function applyDevice()
	local last = UIS:GetLastInputType()
	local pad = last.Name:find("Gamepad") ~= nil
	local touch = last == Enum.UserInputType.Touch or (UIS.TouchEnabled and not UIS.KeyboardEnabled and not pad)
	hints.Visible = not touch
	touchKeys.Visible = touch
	if frenchKeysHolder then
		frenchKeysHolder.Visible = not touch
	end
	for _, kr in keyRows do
		if pad then
			kr.cap.Text = kr.def.PadLabel
		else
			kr.cap.Text = UIS:GetStringForKeyCode(kr.def.Keyboard)
			if kr.cap.Text == "" then
				kr.cap.Text = kr.def.Keyboard.Name
			end
		end
	end
end
applyDevice()
UIS.LastInputTypeChanged:Connect(applyDevice)

for _, name in { C.Stats.Coins, C.Stats.Speed, C.Stats.Strength, C.Stats.Pyramids, C.Stats.Carrying, C.Stats.Capacity, "SpeedMultiplier", "StrengthMultiplier" } do
	player:GetAttributeChangedSignal(name):Connect(refreshStats)
end
player:GetAttributeChangedSignal(C.Stats.FriendBoost):Connect(refreshFriend)
for levelAttr, fn in boostRefresh do
	player:GetAttributeChangedSignal(levelAttr):Connect(fn)
end
local function applyCap()
	local natural = C.Training.WalkSpeed(player:GetAttribute(C.Stats.Speed) or 0)
	player:SetAttribute("NaturalWalkSpeed", natural)
	local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not h then
		return
	end
	local cap = player:GetAttribute("Setting_MaxSpeed") or 0
	local target = (cap > 0) and math.min(natural, math.max(8, cap)) or natural
	if math.abs(h.WalkSpeed - target) > 1e-3 then
		h.WalkSpeed = target
	end
end
local function watchHumanoid(ch)
	local h = ch:WaitForChild("Humanoid", 10)
	if h then
		h:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
		h:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
		h:GetPropertyChangedSignal("WalkSpeed"):Connect(refreshStats)
		applyCap()
	end
	refreshStats()
end
player:GetAttributeChangedSignal(C.Stats.Speed):Connect(applyCap)
player:GetAttributeChangedSignal("Setting_MaxSpeed"):Connect(applyCap)
if player.Character then
	task.spawn(watchHumanoid, player.Character)
end
player.CharacterAdded:Connect(watchHumanoid)

task.spawn(function()
	local map = workspace:WaitForChild("PyramidMap", 30)
	site = map and map:WaitForChild("PyramidSite", 30)
	if site then
		site:GetAttributeChangedSignal("BlocksPlaced"):Connect(refreshPyramid)
		site:GetAttributeChangedSignal("BlocksTotal"):Connect(refreshPyramid)
		site:GetAttributeChangedSignal("CoinsMultiplier"):Connect(refreshPyramid)
		for _, name in { "ChamberOpen", "ChamberEnd", "ChamberMinutes" } do
			site:GetAttributeChangedSignal(name):Connect(refreshPyramid)
		end
		task.spawn(function()
			while true do
				task.wait(0.25)
				if site:GetAttribute("ChamberOpen") then
					refreshPyramid()
				end
			end
		end)
	end
	refreshPyramid()
end)

refreshStats()
refreshFriend()
refreshPyramid()
