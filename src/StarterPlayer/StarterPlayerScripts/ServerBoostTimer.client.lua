local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalizationService = game:GetService("LocalizationService")

local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local hud = RS:WaitForChild("PyramidHUD")

local isFrench = RunService:IsStudio()
if not isFrench then
	local ok, locale = pcall(function()
		return LocalizationService.RobloxLocaleId
	end)
	isFrench = ok and type(locale) == "string" and locale:lower():sub(1, 2) == "fr"
end

local rgb = Color3.fromRGB

local defs = {
	{
		key = "Speed",
		fr = "VITESSE",
		en = "SPEED",
		icon = "⚡",
		color = rgb(75, 180, 255),
	},
	{
		key = "Coins",
		fr = "PIÈCES",
		en = "COINS",
		icon = "●",
		color = rgb(255, 205, 45),
	},
	{
		key = "Strength",
		fr = "FORCE",
		en = "STRENGTH",
		icon = "💪",
		color = rgb(255, 104, 86),
	},
	{
		key = "Pyramids",
		fr = "PYRAMIDES",
		en = "PYRAMIDS",
		icon = "▲",
		color = rgb(192, 103, 255),
	},
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
holder.AnchorPoint = Vector2.new(0.5, 0)
holder.Position = UDim2.new(0.5, 0, 0, 82)
holder.Size = UDim2.fromOffset(440, 52)
holder.BackgroundTransparency = 1
holder.Visible = false
holder.Parent = gui

local list = Instance.new("UIListLayout")
list.HorizontalAlignment = Enum.HorizontalAlignment.Center
list.VerticalAlignment = Enum.VerticalAlignment.Top
list.Padding = UDim.new(0, 6)
list.Parent = holder

local title = Instance.new("TextLabel")
title.Name = "Title"
title.LayoutOrder = 1
title.Size = UDim2.fromOffset(250, 18)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBlack
title.TextSize = 12
title.TextColor3 = rgb(255, 221, 92)
title.TextStrokeColor3 = rgb(20, 15, 8)
title.TextStrokeTransparency = 0.2
title.Text = isFrench and "BONUS SERVEUR ACTIF" or "SERVER BOOST ACTIVE"
title.Parent = holder

local rows = Instance.new("Frame")
rows.Name = "Rows"
rows.LayoutOrder = 2
rows.Size = UDim2.fromOffset(440, 28)
rows.BackgroundTransparency = 1
rows.Parent = holder

local rowList = Instance.new("UIListLayout")
rowList.FillDirection = Enum.FillDirection.Horizontal
rowList.HorizontalAlignment = Enum.HorizontalAlignment.Center
rowList.VerticalAlignment = Enum.VerticalAlignment.Center
rowList.Padding = UDim.new(0, 6)
rowList.Parent = rows

local cards = {}

local function makeCard(def)
	local card = Instance.new("Frame")
	card.Name = def.key
	card.Size = UDim2.fromOffset(102, 28)
	card.BackgroundColor3 = rgb(24, 27, 36)
	card.BackgroundTransparency = 0.05
	card.BorderSizePixel = 0
	card.Visible = false
	card.Parent = rows

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 7)
	corner.Parent = card

	local stroke = Instance.new("UIStroke")
	stroke.Color = def.color
	stroke.Thickness = 2
	stroke.Transparency = 0.08
	stroke.Parent = card

	local grad = Instance.new("UIGradient")
	grad.Rotation = 90
	grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, rgb(38, 42, 56)),
		ColorSequenceKeypoint.new(1, rgb(18, 20, 28)),
	})
	grad.Parent = card

	local accent = Instance.new("Frame")
	accent.Name = "Accent"
	accent.Size = UDim2.fromOffset(4, 18)
	accent.Position = UDim2.fromOffset(5, 5)
	accent.BackgroundColor3 = def.color
	accent.BorderSizePixel = 0
	accent.ZIndex = 2
	accent.Parent = card
	local accentCorner = Instance.new("UICorner")
	accentCorner.CornerRadius = UDim.new(1, 0)
	accentCorner.Parent = accent

	local text = Instance.new("TextLabel")
	text.Name = "Text"
	text.BackgroundTransparency = 1
	text.Position = UDim2.fromOffset(12, 2)
	text.Size = UDim2.new(1, -16, 1, -4)
	text.Font = Enum.Font.GothamBlack
	text.TextSize = 9
	text.TextColor3 = Color3.new(1, 1, 1)
	text.TextStrokeColor3 = rgb(8, 9, 12)
	text.TextStrokeTransparency = 0.25
	text.TextXAlignment = Enum.TextXAlignment.Center
	text.TextYAlignment = Enum.TextYAlignment.Center
	text.ZIndex = 3
	text.Parent = card

	cards[def.key] = {
		frame = card,
		text = text,
		def = def,
	}
end

for _, def in defs do
	makeCard(def)
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

local function fitWidth(activeCount)
	if activeCount <= 1 then
		return 164
	elseif activeCount == 2 then
		return 218
	elseif activeCount == 3 then
		return 330
	end
	return 440
end

local function refresh()
	local now = workspace:GetServerTimeNow()
	local activeCount = 0

	for _, def in defs do
		local multiplier = tonumber(hud:GetAttribute("ServerBoost" .. def.key .. "Multiplier")) or 1
		local endsAt = tonumber(hud:GetAttribute("ServerBoost" .. def.key .. "End")) or 0
		local remaining = endsAt - now
		local active = multiplier > 1 and remaining > 0

		local card = cards[def.key]
		card.frame.Visible = active
		if active then
			activeCount += 1
			local name = isFrench and def.fr or def.en
			card.text.Text = string.format("%s x%s  %s", name, tostring(multiplier), formatTime(remaining))
		end
	end

	holder.Visible = activeCount > 0
	rows.Size = UDim2.fromOffset(fitWidth(activeCount), 28)
end

for _, def in defs do
	for _, suffix in { "Multiplier", "End" } do
		hud:GetAttributeChangedSignal("ServerBoost" .. def.key .. suffix):Connect(refresh)
	end
end

refresh()

task.spawn(function()
	while gui.Parent do
		refresh()
		task.wait(0.25)
	end
end)
