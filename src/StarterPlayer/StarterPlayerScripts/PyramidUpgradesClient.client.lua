local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local MPS = game:GetService("MarketplaceService")

local player = Players.LocalPlayer
local folder = RS:WaitForChild("PyramidHUD")
local C = require(folder:WaitForChild("Config"))
local T = require(folder:WaitForChild("Theme"))
local Tile = require(folder:WaitForChild("TileStyle"))
local U = require(folder:WaitForChild("UpgradesConfig"))
local remote = folder:WaitForChild("Upgrades")

local rgb = Color3.fromRGB
local WHITE = Color3.new(1, 1, 1)

local UNITS = { "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }
local function short(n)
	n = math.floor(tonumber(n) or 0)
	if n < 1000 then
		return tostring(n)
	end
	local i, v = 0, n
	while v >= 1000 and i < #UNITS do
		v /= 1000
		i += 1
	end
	local d = n >= 1e5 and 2 or 1
	local p = 10 ^ d
	v = math.floor(v * p + 1e-9) / p
	return (string.format("%." .. d .. "f", v):gsub("%.?0+$", "")) .. UNITS[i]
end

local function attrOr(o, name, fallback)
	local v = o:GetAttribute(name)
	if v == nil then
		return fallback
	end
	return v
end

local gui = player:WaitForChild("PlayerGui"):WaitForChild("PyramidUpgrades")
local backdrop = gui:WaitForChild("Backdrop")
local panel = gui:WaitForChild("Upgrades")
panel.Visible = false
backdrop.Visible = false
Tile.linkOutlines(panel)
local W, H = panel.Size.X.Offset, panel.Size.Y.Offset
local scale = panel:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
scale.Parent = panel
local function fit()
	local v = gui.AbsoluteSize
	if v.X < 100 or v.Y < 100 then
		v = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or v
	end
	if v.X < 100 or v.Y < 100 then
		return
	end
	scale.Scale = math.min(0.8, (v.X - 24) / W, (v.Y - 90) / H)
end
fit()
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
T.adoptWindow(panel)
local close = panel:WaitForChild("Header"):WaitForChild("Close")

local hint = panel:WaitForChild("Hint")
local hintColour = hint.TextColor3
local hintToken = 0
local function say(text, colour)
	hintToken += 1
	local mine = hintToken
	hint.Text = text
	hint.TextColor3 = colour or hintColour
	task.delay(2.4, function()
		if hintToken == mine then
			hint.Text = ""
		end
	end)
end

local list = panel:WaitForChild("List")
local rows = {}
for _, u in U.List do
	local card = list:FindFirstChild(u.Id)
	if not card then
		warn("[PyramidUpgrades] StarterGui.PyramidUpgrades.Upgrades.List has no " .. u.Id .. " card")
		continue
	end
	local buy = card:WaitForChild("Buy")
	local robux = card:WaitForChild("Robux")
	local lv = card:WaitForChild("Level")
	local lvScale = lv:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
	lvScale.Parent = lv
	local buyContent = buy:WaitForChild("Content")
	rows[u.Id] = {
		u = u,
		desc = card:WaitForChild("Desc"),
		lv = lv,
		lvScale = lvScale,
		buy = buy,
		price = buyContent:WaitForChild("Price"),
		priceColour = buyContent.Price.TextColor3,
		coin = buyContent:WaitForChild("Coin"),
		robux = robux,
		robuxPrice = robux:WaitForChild("Content"):WaitForChild("Price"),
	}

	buy.Activated:Connect(function()
		local level = player:GetAttribute(u.Level) or 1
		if level >= U.MaxLevel then
			say("Max level!", rgb(255, 226, 120))
			return
		end
		if (player:GetAttribute(C.Stats.Coins) or 0) < U.Coins[level] then
			say("Not enough coins!")
			return
		end
		remote:FireServer("buy", u.Id, level)
	end)
	robux.Activated:Connect(function()
		local level = player:GetAttribute(u.Level) or 1
		local id = u.ProductIds[level] or 0
		if level >= U.MaxLevel then
			return
		end
		if id <= 0 then
			say("Not on sale yet!")
			return
		end
		MPS:PromptProductPurchase(player, id)
	end)
end

local function refresh()
	local coins = player:GetAttribute(C.Stats.Coins) or 0
	for _, r in rows do
		local u = r.u
		local level = player:GetAttribute(u.Level) or 1
		r.lv.Text = level >= U.MaxLevel and attrOr(r.lv, "MaxText", "MAX") or (attrOr(r.lv, "Prefix", "Lv.") .. level)
		r.desc.Text = u.Describe(u.Effect(level))
		if level >= U.MaxLevel then
			r.price.Text = attrOr(r.buy, "MaxedText", "MAXED")
			r.price.TextColor3 = WHITE
			r.coin.Visible = false
			T.gradient(r.buy, attrOr(r.buy, "MaxedColor", rgb(110, 118, 136)))
			r.robux.Visible = false
		else
			r.price.Text = short(U.Coins[level])
			r.price.TextColor3 = coins >= U.Coins[level] and r.priceColour or attrOr(r.buy, "TooPoorColor", rgb(255, 110, 100))
			r.coin.Visible = true
			T.gradient(r.buy, attrOr(r.buy, "ReadyColor", rgb(80, 220, 40)))
			r.robux.Visible = true
			r.robuxPrice.Text = tostring(U.Robux[level])
		end
	end
end
refresh()
player:GetAttributeChangedSignal(C.Stats.Coins):Connect(refresh)
for _, u in U.List do
	player:GetAttributeChangedSignal(u.Level):Connect(refresh)
end

remote.OnClientEvent:Connect(function(kind, id, why)
	local r = rows[id]
	if kind == "bought" and r then
		refresh()
		r.lvScale.Scale = 1.45
		TweenService:Create(r.lvScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		say(r.u.Title .. " upgraded!", rgb(120, 255, 120))
	elseif kind == "denied" then
		if why then
			say(tostring(why) .. "!")
		end
		refresh()
	end
end)

local dismissed = false
local function open(value)
	panel.Visible = value
	backdrop.Visible = value
	gui:SetAttribute("Open", value)
	if value then
		hint.Text = ""
		fit()
		refresh()
	end
end
close.Activated:Connect(function()
	dismissed = true
	open(false)
end)
UIS.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == Enum.KeyCode.Escape and panel.Visible then
		dismissed = true
		open(false)
	end
end)

local zone, stall
task.spawn(function()
	stall = workspace:WaitForChild("PyramidMap"):WaitForChild("Upgrades")
	zone = stall:WaitForChild("InteractionZone")
end)

local inside = false
RunService.Heartbeat:Connect(function()
	local ch = player.Character
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	local now = false
	if stall and not (zone and zone.Parent) then
		zone = stall:FindFirstChild("InteractionZone")
	end
	if zone and hrp then
		local d = hrp.Position - zone.Position
		local radius = math.min(zone.Size.Y, zone.Size.Z) / 2
		now = Vector2.new(d.X, d.Z).Magnitude <= radius and math.abs(d.Y) < 10
	end
	if now ~= inside then
		inside = now
		if inside then
			if not dismissed then
				open(true)
			end
		else
			dismissed = false
			open(false)
		end
	end
end)
