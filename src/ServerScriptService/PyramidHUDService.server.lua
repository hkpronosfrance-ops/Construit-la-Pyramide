local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local MPS = game:GetService("MarketplaceService")

local folder = RS:WaitForChild("PyramidHUD")
local C = require(folder:WaitForChild("Config"))

local DEFAULTS = {
	[C.Stats.Coins] = 0,
	[C.Stats.Speed] = 0,
	[C.Stats.Strength] = 0,
	[C.Stats.Pyramids] = 0,
	[C.Stats.Carrying] = 0,
	[C.Stats.Capacity] = 1,
	[C.Stats.FriendBoost] = 0,
}
for _, b in C.Boosts do
	DEFAULTS[b.Level] = 0
	DEFAULTS[b.Multiplier] = 1
end

local function site()
	local map = workspace:FindFirstChild("PyramidMap")
	return map and map:FindFirstChild("PyramidSite")
end

do
	local s = site()
	if s then
		if s:GetAttribute("BlocksTotal") == nil then
			s:SetAttribute("BlocksTotal", C.PyramidTotal)
		end
		if s:GetAttribute("BlocksPlaced") == nil then
			s:SetAttribute("BlocksPlaced", 0)
		end
	end
end

local friendCache = {}
local function areFriends(a, b)
	local key = a.UserId < b.UserId and (a.UserId .. ":" .. b.UserId) or (b.UserId .. ":" .. a.UserId)
	if friendCache[key] == nil then
		local ok, yes = pcall(a.IsFriendsWith, a, b.UserId)
		friendCache[key] = ok and yes or false
	end
	return friendCache[key]
end

local function refreshFriends(leaving)
	local list = Players:GetPlayers()
	for _, p in list do
		local n = 0
		for _, q in list do
			if q ~= p and q ~= leaving and areFriends(p, q) then
				n += 1
			end
		end
		p:SetAttribute(C.Stats.FriendBoost, math.min(n * C.FriendBoostPerFriend, C.FriendBoostMax or math.huge))
	end
end

local function onJoin(p)
	for name, v in DEFAULTS do
		if p:GetAttribute(name) == nil then
			p:SetAttribute(name, v)
		end
	end
	task.spawn(refreshFriends)
end

Players.PlayerAdded:Connect(onJoin)
for _, p in Players:GetPlayers() do
	onJoin(p)
end
Players.PlayerRemoving:Connect(function(leaving)
	task.spawn(refreshFriends, leaving)
end)

local products = {}
_G.PyramidProducts = products
for _, b in C.Boosts do
	for index, tier in b.Tiers do
		if tier.ProductId > 0 then
			products[tier.ProductId] = function(p)
				local level = C.boostLevel(b, p:GetAttribute(b.Level))
				if level >= #b.Tiers then
					return true
				end
				local expected = level + 1
				if index < expected then
					return true
				end
				if index > expected then
					return false
				end
				p:SetAttribute(b.Level, expected)
				p:SetAttribute(b.Multiplier, C.multiplier(b, expected))
				return true
			end
		end
	end
end
for _, o in C.PyramidFill do
	if o.ProductId > 0 then
		products[o.ProductId] = function(p)
			local build = _G.PyramidBuild
			if not (build and build.Fill) then
				return false
			end
			return build.Fill(p, o.Amount)
		end
	end
end

for zoneName, u in C.ZoneUnlock or {} do
	if (u.ProductId or 0) > 0 then
		products[u.ProductId] = function(p)
			p:SetAttribute("Unlocked_" .. zoneName, true)
			return true
		end
	end
end
for _, o in (C.Chamber and C.Chamber.Offers) or {} do
	if (o.ProductId or 0) > 0 then
		products[o.ProductId] = function()
			local s = site()
			if not (s and s:GetAttribute("ChamberOpen")) then
				return false
			end
			local mins = s:GetAttribute("ChamberMinutes") or C.Chamber.Minutes
			if mins + o.Minutes > C.Chamber.MaxMinutes then
				return false
			end
			s:SetAttribute("ChamberMinutes", mins + o.Minutes)
			s:SetAttribute("ChamberEnd", (s:GetAttribute("ChamberEnd") or workspace:GetServerTimeNow()) + o.Minutes * 60)
			return true
		end
	end
end
local function owns(p, passId)
	for attempt = 1, 3 do
		local ok, yes = pcall(MPS.UserOwnsGamePassAsync, MPS, p.UserId, passId)
		if ok then
			return yes == true
		end
		task.wait(attempt * 2)
	end
	return false
end
local function refreshPharaoh(p)
	p:SetAttribute("Pharaoh", (p:GetAttribute("PharaohPass") == true and p:GetAttribute("PharaohOff") ~= true) or nil)
end
local function watchPharaoh(p)
	p:GetAttributeChangedSignal("PharaohPass"):Connect(function()
		refreshPharaoh(p)
	end)
	p:GetAttributeChangedSignal("PharaohOff"):Connect(function()
		refreshPharaoh(p)
	end)
	refreshPharaoh(p)
end
Players.PlayerAdded:Connect(watchPharaoh)
for _, p in Players:GetPlayers() do
	watchPharaoh(p)
end
local function checkPasses(p)
	local ph = C.Pharaoh
	if ph and (ph.GamePassId or 0) > 0 and owns(p, ph.GamePassId) then
		p:SetAttribute("PharaohPass", true)
	end
	for zoneName, u in C.ZoneUnlock or {} do
		if (u.GamePassId or 0) > 0 and owns(p, u.GamePassId) then
			p:SetAttribute("Unlocked_" .. zoneName, true)
		end
	end
end
Players.PlayerAdded:Connect(checkPasses)
for _, p in Players:GetPlayers() do
	task.spawn(checkPasses, p)
end
MPS.PromptGamePassPurchaseFinished:Connect(function(p, passId, bought)
	if bought and C.Pharaoh and passId == C.Pharaoh.GamePassId then
		p:SetAttribute("PharaohOff", nil)
		p:SetAttribute("PharaohPass", true)
	end
	if bought then
		for zoneName, u in C.ZoneUnlock or {} do
			if u.GamePassId == passId then
				p:SetAttribute("Unlocked_" .. zoneName, true)
			end
		end
	end
end)

task.spawn(function()
	local map = workspace:WaitForChild("PyramidMap")
	local npc = map:WaitForChild("Pharaoh", 30)
	local prompt = npc and npc:FindFirstChild("PharaohPrompt", true)
	if not prompt then
		return
	end
	prompt.Triggered:Connect(function(p)
		if p:GetAttribute("Pharaoh") then
			local note = folder:FindFirstChild("Training")
			if note then
				note:FireClient(p, "denied", "You already own the Pharaoh pass!")
			end
		end
		pcall(MPS.PromptGamePassPurchase, MPS, p, C.Pharaoh.GamePassId)
	end)
end)

local function deliverPurchasedBlocks(p)
	local build = _G.PyramidBuild
	if build and build.DeliverPending then
		task.defer(build.DeliverPending, p)
	end
end

MPS.ProcessReceipt = function(receipt)
	local p = Players:GetPlayerByUserId(receipt.PlayerId)
	local grant = products[receipt.ProductId]
	local data = _G.PyramidData
	if not (p and grant and data and data.IsLoaded(p)) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if data.HasReceipt(p, receipt.PurchaseId) then
		if data.Save(p) then
			deliverPurchasedBlocks(p)
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local ok, result = pcall(grant, p)
	if not ok or result ~= true then
		if not ok then
			warn("[Purchases] " .. tostring(result))
		end
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	data.AddReceipt(p, receipt.PurchaseId)
	if not data.Save(p) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	-- World delivery starts only after the paid entitlement and receipt are
	-- durably saved. Other product types simply have nothing pending to deliver.
	deliverPurchasedBlocks(p)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

local groupRemote = folder:WaitForChild("GroupReward")
local G = C.GroupReward
local function member(p)
	if (G.GroupId or 0) <= 0 then
		return false, false
	end
	local ok, yes = pcall(p.IsInGroupAsync, p, G.GroupId)
	if not ok then
		ok, yes = pcall(p.IsInGroup, p, G.GroupId)
	end
	return ok and yes == true, true
end
local function pushGroup(p)
	local joined, verifiable = member(p)
	groupRemote:FireClient(p, "state", { joined = joined, verifiable = verifiable, claimed = p:GetAttribute("GroupRewardClaimed") == true })
end
local groupBusy = {}
groupRemote.OnServerEvent:Connect(function(p, action)
	if groupBusy[p] then
		return
	end
	groupBusy[p] = true
	if action == "get" then
		pushGroup(p)
	elseif action == "claim" then
		local joined, verifiable = member(p)
		local data = _G.PyramidData
		if data and not data.IsLoaded(p) then
			groupRemote:FireClient(p, "denied", "Please wait a moment")
		elseif p:GetAttribute("GroupRewardClaimed") then
			groupRemote:FireClient(p, "denied", "You already claimed this reward.")
		elseif not verifiable then
			groupRemote:FireClient(p, "denied", "Not available right now")
		elseif not joined then
			groupRemote:FireClient(p, "denied", "Join our group first!")
		else
			p:SetAttribute("GroupRewardClaimed", true)
			p:SetAttribute(C.Stats.Coins, (p:GetAttribute(C.Stats.Coins) or 0) + G.Coins)
			groupRemote:FireClient(p, "granted", G.Coins)
		end
		pushGroup(p)
	end
	task.wait(0.3)
	groupBusy[p] = nil
end)
Players.PlayerRemoving:Connect(function(p)
	groupBusy[p] = nil
end)
