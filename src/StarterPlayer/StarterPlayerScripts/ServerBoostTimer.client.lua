local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalizationService = game:GetService("LocalizationService")

local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local serverState = RS:WaitForChild("PyramidHUD")
local sourceGui = pg:WaitForChild("PyramidHUD", 30)
if not sourceGui then
	return
end

local stats = sourceGui:WaitForChild("Stats", 15)
if not stats then
	return
end

local isFrench = RunService:IsStudio()
if not isFrench then
	local ok, locale = pcall(function()
		return LocalizationService.RobloxLocaleId
	end)
	isFrench = ok and type(locale) == "string" and locale:lower():sub(1, 2) == "fr"
end

local rgb = Color3.fromRGB

local defs = {
	{ key = "Coins", fr = "PIÈCES", en = "COINS", color = rgb(255, 205, 45) },
	{ key = "Speed", fr = "VITESSE", en = "SPEED", color = rgb(75, 180, 255) },
	{ key = "Strength", fr = "FORCE", en = "STRENGTH", color = rgb(255, 104, 86) },
	{ key = "Pyramids", fr = "PYRAMIDES", en = "PYRAMIDS", color = rgb(192, 103, 255) },
}

local old = pg:FindFirstChild("ServerBoostTimer")
if old then
	old:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "ServerBoostTimer"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 65
gui.Parent = pg

local holder = Instance.new("Frame")
holder.Name = "Holder"
holder.AnchorPoint = Vector2.new(1, 1)
holder.Position = UDim2.new(1, -22, 1, -146)
holder.Size = UDim2.fromOffset(190, 220)
holder.BackgroundTransparency = 1
holder.Visible = false
holder.Parent = gui

local scale = Instance.new("UIScale")
scale.Parent = holder

local function resize()
	local cam = workspace.CurrentCamera
	if not cam then
		return
	end
	local v = cam.ViewportSize
	scale.Scale = math.clamp(math.min(v.X / 1500, v.Y / 860), 0.62, 1)
end
resize()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)

local title = Instance.new("TextLabel")
title.Name = "Title"
title.AnchorPoint = Vector2.new(1, 1)
title.Position = UDim2.new(1, 0, 1, 0)
title.Size = UDim2.fromOffset(190, 18)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBlack
title.TextSize = 11
title.TextColor3 = rgb(255, 224, 86)
title.TextStrokeColor3 = rgb(20, 15, 8)
title.TextStrokeTransparency = 0.15
title.TextXAlignment = Enum.TextXAlignment.Right
title.Text = isFrench and "BONUS SERVEUR" or "SERVER BOOSTS"
title.Parent = holder

local rows = Instance.new("Frame")
rows.Name = "Rows"
rows.AnchorPoint = Vector2.new(1, 1)
rows.Position = UDim2.new(1, 0, 1, -22)
rows.Size = UDim2.fromOffset(190, 192)
rows.BackgroundTransparency = 1
rows.Parent = holder

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Vertical
layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
layout.Padding = UDim.new(0, 6)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = rows

local function isInsideSpeedEdit(obj)
	local p = obj.Parent
	while p and p ~= stats do
		if p.Name == "SpeedEditIcon" then
			return true
		end
		p = p.Parent
	end
	return false
end

local function findSourceIcon(key)
	local row = stats:FindFirstChild(key)
	if not row then
		return nil
	end

	local best, bestScore
	for _, obj in row:GetDescendants() do
		if obj:IsA("ImageLabel") and not isInsideSpeedEdit(obj) then
			local score = 0
			if obj.Name:lower():find("icon", 1, true) then
				score += 1000
			end
			score += math.max(obj.AbsoluteSize.X * obj.AbsoluteSize.Y, obj.Size.X.Offset * obj.Size.Y.Offset)
			if not best or score > bestScore then
				best, bestScore = obj, score
			end
		end
	end
	return best
end

local cards = {}

local function makeCard(def, order)
	local card = Instance.new("Frame")
	card.Name = def.key
	card.LayoutOrder = order
	card.Size = UDim2.fromOffset(176, 40)
	card.BackgroundColor3 = rgb(20, 23, 31)
	card.BackgroundTransparency = 0.04
	card.BorderSizePixel = 0
	card.Visible = false
	card.Parent = rows

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 9)
	corner.Parent = card

	local stroke = Instance.new("UIStroke")
	stroke.Color = def.color
	stroke.Thickness = 2
	stroke.Transparency = 0.04
	stroke.Parent = card

	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 0
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, rgb(18, 20, 27)),
		ColorSequenceKeypoint.new(0.62, rgb(31, 34, 44)),
		ColorSequenceKeypoint.new(1, def.color:Lerp(rgb(30, 31, 38), 0.72)),
	})
	gradient.Parent = card

	local iconBack = Instance.new("Frame")
	iconBack.Name = "IconBack"
	iconBack.AnchorPoint = Vector2.new(0, 0.5)
	iconBack.Position = UDim2.new(0, 5, 0.5, 0)
	iconBack.Size = UDim2.fromOffset(36, 36)
	iconBack.BackgroundColor3 = rgb(10, 12, 17)
	iconBack.BackgroundTransparency = 0.14
	iconBack.BorderSizePixel = 0
	iconBack.ZIndex = 2
	iconBack.Parent = card
	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(0, 8)
	iconCorner.Parent = iconBack

	local source = findSourceIcon(def.key)
	local icon
	if source then
		icon = source:Clone()
		icon.Name = "StatIcon"
		icon.AnchorPoint = Vector2.new(0.5, 0.5)
		icon.Position = UDim2.fromScale(0.5, 0.5)
		icon.Size = UDim2.fromOffset(31, 31)
		icon.BackgroundTransparency = 1
		icon.Visible = true
		icon.ZIndex = 3
		icon.Parent = iconBack
		for _, child in icon:GetDescendants() do
			if child:IsA("GuiObject") then
				child.ZIndex = math.max(child.ZIndex, 3)
			end
		end
	end

	local name = Instance.new("TextLabel")
	name.Name = "Name"
	name.BackgroundTransparency = 1
	name.Position = UDim2.fromOffset(47, 3)
	name.Size = UDim2.fromOffset(75, 15)
	name.Font = Enum.Font.GothamBlack
	name.TextSize = 9
	name.TextColor3 = Color3.new(1, 1, 1)
	name.TextStrokeColor3 = rgb(8, 9, 12)
	name.TextStrokeTransparency = 0.25
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.Text = isFrench and def.fr or def.en
	name.ZIndex = 3
	name.Parent = card

	local mult = Instance.new("TextLabel")
	mult.Name = "Multiplier"
	mult.BackgroundTransparency = 1
	mult.Position = UDim2.fromOffset(47, 17)
	mult.Size = UDim2.fromOffset(50, 18)
	mult.Font = Enum.Font.GothamBlack
	mult.TextSize = 13
	mult.TextColor3 = def.color
	mult.TextStrokeColor3 = rgb(8, 9, 12)
	mult.TextStrokeTransparency = 0.2
	mult.TextXAlignment = Enum.TextXAlignment.Left
	mult.Text = "x2"
	mult.ZIndex = 3
	mult.Parent = card

	local timer = Instance.new("TextLabel")
	timer.Name = "Timer"
	timer.AnchorPoint = Vector2.new(1, 0.5)
	timer.Position = UDim2.new(1, -8, 0.5, 0)
	timer.Size = UDim2.fromOffset(72, 24)
	timer.BackgroundTransparency = 1
	timer.Font = Enum.Font.GothamBlack
	timer.TextSize = 13
	timer.TextColor3 = Color3.new(1, 1, 1)
	timer.TextStrokeColor3 = rgb(8, 9, 12)
	timer.TextStrokeTransparency = 0.15
	timer.TextXAlignment = Enum.TextXAlignment.Right
	timer.Text = "09:59"
	timer.ZIndex = 3
	timer.Parent = card

	cards[def.key] = {
		frame = card,
		mult = mult,
		timer = timer,
	}
end

for index, def in defs do
	makeCard(def, index)
end

local function formatMultiplier(value)
	local text = string.format("%.2f", value):gsub("%.?0+$", "")
	return "x" .. text
end

local function formatTime(seconds)
	seconds = math.max(0, math.ceil(seconds))
	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local secs = seconds % 60
	if hours > 0 then
		return string.format("%d:%02d:%02d", hours, minutes, secs)
	end
	return string.format("%02d:%02d", minutes, secs)
end

local function refresh()
	local now = workspace:GetServerTimeNow()
	local active = 0

	for _, def in defs do
		local multiplier = tonumber(serverState:GetAttribute("ServerBoost" .. def.key .. "Multiplier")) or 1
		local endsAt = tonumber(serverState:GetAttribute("ServerBoost" .. def.key .. "End")) or 0
		local remaining = endsAt - now
		local on = multiplier > 1 and remaining > 0

		local card = cards[def.key]
		card.frame.Visible = on
		if on then
			active += 1
			card.mult.Text = formatMultiplier(multiplier)
			card.timer.Text = formatTime(remaining)
		end
	end

	holder.Visible = active > 0
	title.Visible = active > 0
end

for _, def in defs do
	for _, suffix in { "Multiplier", "End" } do
		serverState:GetAttributeChangedSignal("ServerBoost" .. def.key .. suffix):Connect(refresh)
	end
end

refresh()

task.spawn(function()
	while gui.Parent do
		refresh()
		task.wait(0.25)
	end
end)
