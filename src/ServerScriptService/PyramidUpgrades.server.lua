local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local folder = RS:WaitForChild("PyramidHUD")
local C = require(folder:WaitForChild("Config"))
local U = require(folder:WaitForChild("UpgradesConfig"))
local Ready = require(script.Parent:WaitForChild("PyramidPlayerReady"))

local remote = folder:FindFirstChild("Upgrades") or Instance.new("RemoteEvent")
remote.Name = "Upgrades"
remote.Parent = folder

local function apply(p, u, level)
	p:SetAttribute(u.Level, level)
	p:SetAttribute(u.Value, u.Effect(level))
end

local function onJoin(p)
	for _, u in U.List do
		local level = math.clamp(math.floor(tonumber(p:GetAttribute(u.Level)) or 1), 1, U.MaxLevel)
		apply(p, u, level)
	end
end
Players.PlayerAdded:Connect(onJoin)
for _, p in Players:GetPlayers() do
	onJoin(p)
end

local busy = {}
remote.OnServerEvent:Connect(function(p, action, id, seen)
	if action ~= "buy" or type(id) ~= "string" or busy[p] then
		return
	end
	if not Ready.IsReady(p) then
		remote:FireClient(p, "denied", id, "Please wait a moment")
		return
	end
	local u = U.get(id)
	if not u then
		return
	end
	busy[p] = true
	local level = p:GetAttribute(u.Level) or 1
	local price = U.Coins[level]
	local coins = p:GetAttribute(C.Stats.Coins) or 0
	if seen ~= level then
		remote:FireClient(p, "denied", id)
	elseif level >= U.MaxLevel or not price then
		remote:FireClient(p, "denied", id, "Max level")
	elseif coins < price then
		remote:FireClient(p, "denied", id, "Not enough coins")
	else
		p:SetAttribute(C.Stats.Coins, coins - price)
		apply(p, u, level + 1)
		remote:FireClient(p, "bought", id)
	end
	task.wait(0.15)
	busy[p] = nil
end)
Players.PlayerRemoving:Connect(function(p)
	busy[p] = nil
end)

task.spawn(function()
	local products
	for _ = 1, 100 do
		products = _G.PyramidProducts
		if products then
			break
		end
		task.wait(0.1)
	end
	if not products then
		warn("[Upgrades] PyramidHUDService products table missing; Robux upgrades are off")
		return
	end
	for _, u in U.List do
		for index, productId in u.ProductIds do
			if productId > 0 then
				products[productId] = function(p)
					local paidAttr = "PaidUpgrade_" .. u.Id
					local level = math.clamp(math.floor(tonumber(p:GetAttribute(u.Level)) or 1), 1, U.MaxLevel)
					local entitledLevel = math.clamp(index + 1, 1, U.MaxLevel)
					if index < level then
						p:SetAttribute(paidAttr, math.max(math.floor(tonumber(p:GetAttribute(paidAttr)) or 1), entitledLevel))
						return true
					end
					local expected = level
					if index > expected then
						return false
					end
					apply(p, u, level + 1)
					p:SetAttribute(paidAttr, math.max(math.floor(tonumber(p:GetAttribute(paidAttr)) or 1), level + 1))
					remote:FireClient(p, "bought", u.Id)
					return true
				end
			end
		end
	end
end)
