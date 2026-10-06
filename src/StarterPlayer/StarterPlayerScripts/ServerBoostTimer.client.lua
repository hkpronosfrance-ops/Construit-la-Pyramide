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
local boostTemplates = sourceGui:WaitForChild("Boosts", 15)
if not (stats and boostTemplates) then
	return
end

local speedTemplate = boostTemplates:FindFirstChild("SpeedBoost")
local strengthTemplate = boostTemplates:FindFirstChild("StrengthBoost")
if not (speedTemplate and strengthTemplate) then
	warn("[ServerBoostTimer] Existing SpeedBoost/StrengthBoost templates were not found.")
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
	{
		key = "Coins",
		fr = "PIÈCES",
		en = "COINS",
		template = "Strength",
		rim = rgb(167, 109, 0),
		top = rgb(255, 235, 86),
		bottom = rgb(255, 151, 20),
	},
	{
		key = "Speed",
		fr = "VITESSE",
		en = "SPEED",
		template = "Speed",
		rim = rgb(24, 86, 190),
		top = rgb(150, 225, 255),
		bottom = rgb(40, 140, 255),
	},
	{
		key = "Strength",
		fr = "FORCE",
		en = "STRENGTH",
		template = "Strength",
		rim = rgb(190, 84, 8),
		top = rgb(255, 236, 110),
		bottom = rgb(255, 140, 20),
	},
	{
		key = "Pyramids",
		fr = "PYRAMIDES",
		en = "PYRAMIDS",
		template = "Speed",
		rim = rgb(100, 35, 181),
		top = rgb(240, 143, 255),
		bottom = rgb(145, 57, 255),
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
holder.AnchorPoint = Vector2.new(1, 1)
holder.Position = UDim2.new(1, -14, 1, -146)
holder.Size = UDim2.fromOffset(208, 300)
holder.BackgroundTransparency = 1
holder.Visible = false
holder.Parent = gui

local rootScale = Instance.new("UIScale")
rootScale.Parent = holder

local function resize()
	local cam = workspace.CurrentCamera
	if not cam then
		return
	end
	local v = cam.ViewportSize
	rootScale.Scale = math.clamp(math.min(v.X / 1500, v.Y / 860), 0.62, 1)
end
resize()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)

local rows = Instance.new("Frame")
rows.Name = "Rows"
rows.AnchorPoint = Vector2.new(1, 1)
rows.Position = UDim2.new(1, 0, 1, 0)
rows.Size = UDim2.fromOffset(208, 300)
rows.BackgroundTransparency = 1
rows.Parent = holder

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Vertical
layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
layout.Padding = UDim.new(0, 7)
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

local function sanitizeTemplate(clone, def)
	local price = clone:FindFirstChild("Price", true)
	if price and price:IsA("GuiObject") then
		price.Visible = false
	end

	for _, obj in clone:GetDescendants() do
		if obj:IsA("GuiButton") then
			obj.Active = false
			obj.Selectable = false
			obj.AutoButtonColor = false
		end
		if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
			obj.TextTransparency = 1
			obj.TextStrokeTransparency = 1
		elseif (obj:IsA("ImageLabel") or obj:IsA("ImageButton")) and obj.Name:lower():find("icon", 1, true) then
			obj.ImageTransparency = 1
		elseif obj:IsA("UIStroke") then
			obj.Color = def.rim
		elseif obj:IsA("UIGradient") then
			obj.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, def.top),
				ColorSequenceKeypoint.new(1, def.bottom),
			})
		end
	end
end

local cards = {}
local TARGET_W = 196
local TARGET_H = 72

local function makeCard(def, order)
	local shell = Instance.new("Frame")
	shell.Name = def.key
	shell.LayoutOrder = order
	shell.Size = UDim2.fromOffset(TARGET_W, TARGET_H)
	shell.BackgroundTransparency = 1
	shell.Visible = false
	shell.Parent = rows

	local template = def.template == "Strength" and strengthTemplate or speedTemplate
	local art = template:Clone()
	art.Name = "BoostArt"
	art.AnchorPoint = Vector2.new(0.5, 0.5)
	art.Position = UDim2.fromScale(0.5, 0.5)
	art.Visible = true
	art.Parent = shell
	sanitizeTemplate(art, def)

	local abs = template.AbsoluteSize
	local sourceW = math.max(abs.X, template.Size.X.Offset, 1)
	local sourceH = math.max(abs.Y, template.Size.Y.Offset, 1)
	local fit = math.min(TARGET_W / sourceW, TARGET_H / sourceH)
	local artScale = Instance.new("UIScale")
	artScale.Scale = fit
	artScale.Parent = art

	local sourceIcon = findSourceIcon(def.key)
	if sourceIcon then
		local icon = sourceIcon:Clone()
		icon.Name = "ServerStatIcon"
		icon.AnchorPoint = Vector2.new(0.5, 0.5)
		icon.Position = UDim2.new(0, 38, 0.5, 0)
		icon.Size = UDim2.fromOffset(48, 48)
		icon.BackgroundTransparency = 1
		icon.Visible = true
		icon.ZIndex = 30
		icon.Parent = shell
		for _, child in icon:GetDescendants() do
			if child:IsA("GuiObject") then
				child.ZIndex = math.max(child.ZIndex, 30)
			end
		end
	end

	local main = Instance.new("TextLabel")
	main.Name = "Main"
	main.BackgroundTransparency = 1
	main.Position = UDim2.fromOffset(67, 10)
	main.Size = UDim2.fromOffset(119, 27)
	main.Font = Enum.Font.FredokaOne
	main.TextSize = 20
	main.TextScaled = false
	main.TextColor3 = Color3.new(1, 1, 1)
	main.TextStrokeColor3 = rgb(18, 12, 8)
	main.TextStrokeTransparency = 0
	main.TextXAlignment = Enum.TextXAlignment.Center
	main.TextYAlignment = Enum.TextYAlignment.Center
	main.ZIndex = 31
	main.Parent = shell

	local timerBack = Instance.new("Frame")
	timerBack.Name = "TimerBack"
	timerBack.AnchorPoint = Vector2.new(0.5, 0)
	timerBack.Position = UDim2.new(0, 126, 0, 40)
	timerBack.Size = UDim2.fromOffset(102, 22)
	timerBack.BackgroundColor3 = rgb(19, 25, 20)
	timerBack.BackgroundTransparency = 0.08
	timerBack.BorderSizePixel = 0
	timerBack.ZIndex = 30
	timerBack.Parent = shell
	local timerCorner = Instance.new("UICorner")
	timerCorner.CornerRadius = UDim.new(0, 6)
	timerCorner.Parent = timerBack
	local timerStroke = Instance.new("UIStroke")
	timerStroke.Color = rgb(49, 210, 76)
	timerStroke.Thickness = 1.5
	timerStroke.Transparency = 0.15
	timerStroke.Parent = timerBack

	local timer = Instance.new("TextLabel")
	timer.Name = "Timer"
	timer.Size = UDim2.fromScale(1, 1)
	timer.BackgroundTransparency = 1
	timer.Font = Enum.Font.GothamBlack
	timer.TextSize = 11
	timer.TextColor3 = rgb(104, 255, 119)
	timer.TextStrokeColor3 = rgb(8, 20, 10)
	timer.TextStrokeTransparency = 0.25
	timer.TextXAlignment = Enum.TextXAlignment.Center
	timer.TextYAlignment = Enum.TextYAlignment.Center
	timer.ZIndex = 31
	timer.Parent = timerBack

	cards[def.key] = {
		frame = shell,
		main = main,
		timer = timer,
	}
end

for index, def in defs do
	makeCard(def, index)
end

local function formatMultiplier(value)
	return string.format("%.2f", value):gsub("%.?0+$", "")
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
			local name = isFrench and def.fr or def.en
			card.main.Text = string.format("%sx %s", formatMultiplier(multiplier), name)
			card.timer.Text = (isFrench and "⏱ " or "⏱ ") .. formatTime(remaining)
		end
	end

	holder.Visible = active > 0
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
