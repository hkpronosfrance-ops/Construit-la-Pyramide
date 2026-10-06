local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalizationService = game:GetService("LocalizationService")

local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local state = RS:WaitForChild("PyramidHUD")
local Tile = require(state:WaitForChild("TileStyle"))

local hud = pg:WaitForChild("PyramidHUD", 30)
if not hud then return end
local stats = hud:WaitForChild("Stats", 15)
if not stats then return end

local isFrench = RunService:IsStudio()
if not isFrench then
	local ok, locale = pcall(function()
		return LocalizationService.RobloxLocaleId
	end)
	isFrench = ok and type(locale) == "string" and locale:lower():sub(1, 2) == "fr"
end

local rgb = Color3.fromRGB

local defs = {
	{ key = "Coins", fr = "PIÈCES", en = "COINS", rim = rgb(166,108,0), top = rgb(255,235,82), bottom = rgb(255,147,18) },
	{ key = "Speed", fr = "VITESSE", en = "SPEED", rim = rgb(24,86,190), top = rgb(150,225,255), bottom = rgb(40,140,255) },
	{ key = "Strength", fr = "FORCE", en = "STRENGTH", rim = rgb(190,84,8), top = rgb(255,236,110), bottom = rgb(255,140,20) },
	{ key = "Pyramids", fr = "PYRAMIDES", en = "PYRAMIDS", rim = rgb(105,36,182), top = rgb(239,143,255), bottom = rgb(146,57,255) },
}

local function findIconImage(key)
	local row = stats:FindFirstChild(key)
	if not row then return "" end
	local best, score
	for _, obj in row:GetDescendants() do
		if obj:IsA("ImageLabel") and obj.Image ~= "" then
			local bad = false
			local p = obj.Parent
			while p and p ~= row do
				if p.Name == "SpeedEditIcon" then bad = true break end
				p = p.Parent
			end
			if not bad then
				local s = math.max(obj.AbsoluteSize.X * obj.AbsoluteSize.Y, obj.Size.X.Offset * obj.Size.Y.Offset)
				if obj.Name:lower():find("icon",1,true) then s += 100000 end
				if not best or s > score then best, score = obj, s end
			end
		end
	end
	return best and best.Image or ""
end

for _, def in defs do
	def.icon = findIconImage(def.key)
end

local old = pg:FindFirstChild("ServerBoostTimer")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "ServerBoostTimer"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 65
gui.Parent = pg

local holder = Instance.new("Frame")
holder.Name = "Holder"
holder.AnchorPoint = Vector2.new(1,1)
holder.Position = UDim2.new(1,-18,1,-150)
holder.Size = UDim2.fromOffset(258,112)
holder.BackgroundTransparency = 1
holder.Visible = false
holder.Parent = gui

local rootScale = Instance.new("UIScale")
rootScale.Parent = holder
local function resize()
	local cam = workspace.CurrentCamera
	if not cam then return end
	local v = cam.ViewportSize
	rootScale.Scale = math.clamp(math.min(v.X/1500,v.Y/860),0.68,1)
end
resize()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)

local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.fromOffset(126,52)
grid.CellPadding = UDim2.fromOffset(6,7)
grid.FillDirectionMaxCells = 2
grid.HorizontalAlignment = Enum.HorizontalAlignment.Right
grid.VerticalAlignment = Enum.VerticalAlignment.Bottom
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.Parent = holder

local cards = {}

local function makeCard(def, order)
	local card = Instance.new("Frame")
	card.Name = def.key
	card.LayoutOrder = order
	card.Size = UDim2.fromOffset(126,52)
	card.BackgroundTransparency = 1
	card.Visible = false
	card.Parent = holder

	local shadow = Instance.new("Frame")
	shadow.Name = "Shadow"
	shadow.AnchorPoint = Vector2.new(0.5,0.5)
	shadow.Position = UDim2.new(0.5,2,0.5,3)
	shadow.Size = UDim2.new(1,-2,1,-2)
	shadow.BackgroundColor3 = rgb(8,8,12)
	shadow.BackgroundTransparency = 0.28
	shadow.BorderSizePixel = 0
	shadow.ZIndex = -2
	shadow.Parent = card
	local shadowCorner = Instance.new("UICorner")
	shadowCorner.CornerRadius = UDim.new(0,14)
	shadowCorner.Parent = shadow

	local _,_,fill = Tile.paint(card, def.rim, def.top, def.bottom)

	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.BackgroundTransparency = 1
	icon.Image = def.icon
	icon.ScaleType = Enum.ScaleType.Fit
	icon.AnchorPoint = Vector2.new(0.5,0.5)
	icon.Position = UDim2.new(0,27,0.5,0)
	icon.Size = UDim2.fromOffset(32,32)
	icon.ZIndex = 6
	icon.Parent = fill

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromOffset(43,7)
	title.Size = UDim2.fromOffset(79,17)
	title.Font = Enum.Font.FredokaOne
	title.TextScaled = false
	title.TextSize = 9
	title.TextColor3 = Color3.new(1,1,1)
	title.TextStrokeColor3 = Tile.Ink
	title.TextStrokeTransparency = 0
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.TextYAlignment = Enum.TextYAlignment.Center
	title.TextTruncate = Enum.TextTruncate.AtEnd
	title.ZIndex = 7
	title.Parent = fill

	local timerBack = Instance.new("Frame")
	timerBack.Name = "TimerBack"
	timerBack.AnchorPoint = Vector2.new(0.5,0)
	timerBack.Position = UDim2.new(0,84,0,30)
	timerBack.Size = UDim2.fromOffset(50,13)
	timerBack.BackgroundColor3 = rgb(13,47,20)
	timerBack.BackgroundTransparency = 0.08
	timerBack.BorderSizePixel = 0
	timerBack.ZIndex = 7
	timerBack.Parent = fill
	local tc = Instance.new("UICorner")
	tc.CornerRadius = UDim.new(0,4)
	tc.Parent = timerBack
	local ts = Instance.new("UIStroke")
	ts.Color = rgb(58,210,78)
	ts.Thickness = 1.2
	ts.Transparency = 0.15
	ts.Parent = timerBack

	local timer = Instance.new("TextLabel")
	timer.Name = "Timer"
	timer.Size = UDim2.fromScale(1,1)
	timer.BackgroundTransparency = 1
	timer.Font = Enum.Font.GothamBlack
	timer.TextSize = 8
	timer.TextColor3 = rgb(110,255,125)
	timer.TextStrokeColor3 = rgb(5,25,8)
	timer.TextStrokeTransparency = 0.25
	timer.ZIndex = 8
	timer.Parent = timerBack

	local accent = Instance.new("Frame")
	accent.Name = "Accent"
	accent.AnchorPoint = Vector2.new(0,0.5)
	accent.Position = UDim2.new(0,5,0.5,0)
	accent.Size = UDim2.fromOffset(2,32)
	accent.BackgroundColor3 = def.top
	accent.BorderSizePixel = 0
	accent.ZIndex = 8
	accent.Parent = fill
	local accentCorner = Instance.new("UICorner")
	accentCorner.CornerRadius = UDim.new(1,0)
	accentCorner.Parent = accent

	cards[def.key] = {
		frame = card,
		title = title,
		timer = timer,
		def = def,
	}
end

for i, def in defs do makeCard(def,i) end

local function fmtMult(v)
	return string.format("%.2f",v):gsub("%.?0+$","")
end

local function fmtTime(seconds)
	seconds = math.max(0,math.ceil(seconds))
	local h = math.floor(seconds/3600)
	local m = math.floor((seconds%3600)/60)
	local s = seconds%60
	if h > 0 then return string.format("%d:%02d:%02d",h,m,s) end
	return string.format("%02d:%02d",m,s)
end

local function refresh()
	local now = workspace:GetServerTimeNow()
	local active = 0
	for _, def in defs do
		local mult = tonumber(state:GetAttribute("ServerBoost"..def.key.."Multiplier")) or 1
		local endsAt = tonumber(state:GetAttribute("ServerBoost"..def.key.."End")) or 0
		local remain = endsAt-now
		local on = mult > 1 and remain > 0
		local card = cards[def.key]
		card.frame.Visible = on
		if on then
			active += 1
			card.title.Text = fmtMult(mult).."x "..(isFrench and def.fr or def.en)
			card.timer.Text = fmtTime(remain)
		end
	end
	holder.Visible = active > 0
end

for _, def in defs do
	for _, suffix in {"Multiplier","End"} do
		state:GetAttributeChangedSignal("ServerBoost"..def.key..suffix):Connect(refresh)
	end
end

refresh()
task.spawn(function()
	while gui.Parent do
		refresh()
		task.wait(0.25)
	end
end)
