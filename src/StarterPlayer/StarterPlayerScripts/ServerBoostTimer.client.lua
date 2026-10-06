local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalizationService = game:GetService("LocalizationService")

local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local state = RS:WaitForChild("PyramidHUD")
local C = require(state:WaitForChild("Config"))

local hud = pg:WaitForChild("PyramidHUD", 30)
if not hud then
	return
end

local stats = hud:WaitForChild("Stats", 15)
local boosts = hud:WaitForChild("Boosts", 15)
if not (stats and boosts) then
	return
end

local speedTemplate = boosts:FindFirstChild("SpeedBoost")
local strengthTemplate = boosts:FindFirstChild("StrengthBoost")
if not (speedTemplate and strengthTemplate) then
	warn("[ServerBoostTimer] Missing SpeedBoost/StrengthBoost templates.")
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
		template = strengthTemplate,
		rim = rgb(166, 108, 0),
		top = rgb(255, 235, 82),
		bottom = rgb(255, 147, 18),
	},
	{
		key = "Speed",
		fr = "VITESSE",
		en = "SPEED",
		template = speedTemplate,
		rim = rgb(24, 86, 190),
		top = rgb(150, 225, 255),
		bottom = rgb(40, 140, 255),
	},
	{
		key = "Strength",
		fr = "FORCE",
		en = "STRENGTH",
		template = strengthTemplate,
		rim = rgb(190, 84, 8),
		top = rgb(255, 236, 110),
		bottom = rgb(255, 140, 20),
	},
	{
		key = "Pyramids",
		fr = "PYRAMIDES",
		en = "PYRAMIDS",
		template = speedTemplate,
		rim = rgb(105, 36, 182),
		top = rgb(239, 143, 255),
		bottom = rgb(146, 57, 255),
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
holder.Position = UDim2.new(1, -15, 1, -145)
holder.Size = UDim2.fromOffset(246, 106)
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
	rootScale.Scale = math.clamp(math.min(v.X / 1500, v.Y / 860), 0.65, 1)
end
resize()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)

local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.fromOffset(118, 48)
grid.CellPadding = UDim2.fromOffset(6, 6)
grid.FillDirectionMaxCells = 2
grid.HorizontalAlignment = Enum.HorizontalAlignment.Right
grid.VerticalAlignment = Enum.VerticalAlignment.Bottom
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.Parent = holder

local function statIconImage(key)
	local row = stats:FindFirstChild(key)
	if not row then
		return nil
	end
	local best, score
	for _, obj in row:GetDescendants() do
		if obj:IsA("ImageLabel") and not obj:IsDescendantOf(row:FindFirstChild("SpeedEditIcon") or Instance.new("Folder")) then
			local area = math.max(obj.AbsoluteSize.X * obj.AbsoluteSize.Y, obj.Size.X.Offset * obj.Size.Y.Offset)
			if obj.Name:lower():find("icon", 1, true) then
				area += 100000
			end
			if not best or area > score then
				best, score = obj, area
			end
		end
	end
	return best and best.Image or nil
end

local function recolor(clone, def)
	for _, obj in clone:GetDescendants() do
		if obj:IsA("UIStroke") then
			obj.Color = def.rim
		elseif obj:IsA("UIGradient") then
			obj.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, def.top),
				ColorSequenceKeypoint.new(1, def.bottom),
			})
		end
	end
end

local function replaceBoostIcon(clone, image)
	if not image or image == "" then
		return
	end
	for _, obj in clone:GetDescendants() do
		if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
			local current = obj.Image
			if current == C.Icons.Speed or current == C.Icons.Strength then
				obj.Image = image
			end
		end
	end
end

local function setMainText(clone, text)
	local changed = false
	for _, obj in clone:GetDescendants() do
		if obj:IsA("TextLabel") or obj:IsA("TextButton") then
			local value = (obj.Text or ""):lower()
			if value:find("speed", 1, true)
				or value:find("vitesse", 1, true)
				or value:find("strength", 1, true)
				or value:find("force", 1, true)
			then
				obj.Text = text
				changed = true
			end
		end
	end
	if not changed then
		local face = clone:FindFirstChild("Face", true)
		local caption = face and face:FindFirstChild("Caption", true)
		if caption and caption:IsA("TextLabel") then
			caption.Text = text
		end
	end
end

local function setTimerText(clone, text)
	local price = clone:FindFirstChild("Price", true)
	local label = price and price:FindFirstChild("Text", true)
	if label and label:IsA("TextLabel") then
		label.Text = text
		label.TextColor3 = rgb(104, 255, 119)
		label.TextStrokeColor3 = rgb(10, 40, 13)
		label.TextStrokeTransparency = 0.2
		return label
	end
	return nil
end

local cards = {}

local function makeCard(def, order)
	local shell = Instance.new("Frame")
	shell.Name = def.key
	shell.LayoutOrder = order
	shell.Size = UDim2.fromOffset(118, 48)
	shell.BackgroundTransparency = 1
	shell.ClipsDescendants = true
	shell.Visible = false
	shell.Parent = holder

	local clone = def.template:Clone()
	clone.Name = "ExactBoost"
	clone.AnchorPoint = Vector2.new(0.5, 0.5)
	clone.Position = UDim2.fromScale(0.5, 0.5)
	clone.Visible = true
	clone.Parent = shell

	for _, obj in clone:GetDescendants() do
		if obj:IsA("GuiButton") then
			obj.Active = false
			obj.Selectable = false
			obj.AutoButtonColor = false
		end
	end

	local sourceSize = def.template.AbsoluteSize
	local sourceW = math.max(sourceSize.X, def.template.Size.X.Offset, 1)
	local sourceH = math.max(sourceSize.Y, def.template.Size.Y.Offset, 1)
	local fit = math.min(118 / sourceW, 48 / sourceH)
	local sc = Instance.new("UIScale")
	sc.Scale = fit
	sc.Parent = clone

	recolor(clone, def)
	replaceBoostIcon(clone, statIconImage(def.key))

	local name = isFrench and def.fr or def.en
	setMainText(clone, "2x " .. name)
	local timer = setTimerText(clone, "09:59")

	cards[def.key] = {
		frame = shell,
		clone = clone,
		timer = timer,
		name = name,
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
		local multiplier = tonumber(state:GetAttribute("ServerBoost" .. def.key .. "Multiplier")) or 1
		local endsAt = tonumber(state:GetAttribute("ServerBoost" .. def.key .. "End")) or 0
		local remaining = endsAt - now
		local on = multiplier > 1 and remaining > 0

		local card = cards[def.key]
		card.frame.Visible = on
		if on then
			active += 1
			setMainText(card.clone, formatMultiplier(multiplier) .. "x " .. card.name)
			if card.timer then
				card.timer.Text = formatTime(remaining)
			end
		end
	end

	holder.Visible = active > 0
end

for _, def in defs do
	for _, suffix in { "Multiplier", "End" } do
		state:GetAttributeChangedSignal("ServerBoost" .. def.key .. suffix):Connect(refresh)
	end
end

refresh()

task.spawn(function()
	while gui.Parent do
		refresh()
		task.wait(0.25)
	end
end)
