local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local DSS = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local folder = RS:WaitForChild("PyramidHUD")
local C = require(folder:WaitForChild("Config"))
local U = require(folder:WaitForChild("UpgradesConfig"))

local LIVE = not RunService:IsStudio()
local STORE = LIVE and DSS:GetDataStore("BuildThePyramid_Players_v1") or nil
local VERSION = 1
local AUTOSAVE = 60
local RETRIES = 4

local SAVED = {
	C.Stats.Coins, C.Stats.Speed, C.Stats.Strength, C.Stats.Pyramids, C.Stats.Carrying,
	"Blocks", "GroupRewardClaimed", "PharaohOff",
}
for _, b in C.Boosts do
	table.insert(SAVED, b.Level)
end
for _, u in U.List do
	table.insert(SAVED, u.Level)
end
for zone in C.ZoneUnlock or {} do
	table.insert(SAVED, "Unlocked_" .. zone)
end

local loaded = {}
local lastSaved = {}
local pending = 0
local receipts = {}
local saving = {}
local MAX_RECEIPTS = 50

local function key(p)
	return "u_" .. p.UserId
end

local function retry(fn)
	local ok, result
	for attempt = 1, RETRIES do
		ok, result = pcall(fn)
		if ok then
			return true, result
		end
		task.wait(attempt)
	end
	return false, result
end

local function snapshot(p)
	local data = { Version = VERSION }
	for _, name in SAVED do
		local v = p:GetAttribute(name)
		if type(v) == "number" or type(v) == "boolean" then
			data[name] = v
		end
	end
	local list = receipts[p]
	if list and #list > 0 then
		data.Receipts = table.concat(list, ",")
	end
	return data
end

local function same(a, b)
	if not (a and b) then
		return false
	end
	for k, v in a do
		if b[k] ~= v then
			return false
		end
	end
	for k in b do
		if a[k] == nil then
			return false
		end
	end
	return true
end

local function save(p)
	if not LIVE then
		return true
	end
	if not loaded[p] then
		return false
	end
	while saving[p] do
		task.wait(0.1)
	end
	local data = snapshot(p)
	if same(data, lastSaved[p]) then
		return true
	end
	saving[p] = true
	pending += 1
	local ok, err = retry(function()
		STORE:UpdateAsync(key(p), function()
			return data
		end)
	end)
	pending -= 1
	saving[p] = nil
	if ok then
		lastSaved[p] = data
	else
		warn("[PyramidData] could not save " .. p.Name .. ": " .. tostring(err))
	end
	return ok
end

local function derive(p)
	for _, b in C.Boosts do
		local level = C.boostLevel(b, p:GetAttribute(b.Level))
		p:SetAttribute(b.Level, level)
		p:SetAttribute(b.Multiplier, C.multiplier(b, level))
	end
	for _, u in U.List do
		local level = math.clamp(math.floor(tonumber(p:GetAttribute(u.Level)) or 1), 1, U.MaxLevel)
		p:SetAttribute(u.Level, level)
		p:SetAttribute(u.Value, u.Effect(level))
	end
end

local function load(p)
	if not LIVE then
		receipts[p] = {}
		derive(p)
		loaded[p] = true
		lastSaved[p] = nil
		p:SetAttribute("DataLoaded", true)
		return
	end
	local ok, data = retry(function()
		return STORE:GetAsync(key(p))
	end)
	if not p.Parent then
		return
	end
	if not ok then
		warn("[PyramidData] could not load " .. p.Name .. ": " .. tostring(data))
		p:SetAttribute("DataLoadFailed", true)
		p:Kick("Your progress could not be loaded. Please rejoin.")
		return
	end
	receipts[p] = {}
	if type(data) == "table" and type(data.Receipts) == "string" then
		for id in string.gmatch(data.Receipts, "[^,]+") do
			table.insert(receipts[p], id)
		end
	end
	if type(data) == "table" then
		for _, name in SAVED do
			local v = data[name]
			if type(v) == "number" or type(v) == "boolean" then
				p:SetAttribute(name, v)
			end
		end
	end
	derive(p)
	loaded[p] = true
	lastSaved[p] = type(data) == "table" and data or nil
	p:SetAttribute("DataLoaded", true)
end

Players.PlayerAdded:Connect(load)
for _, p in Players:GetPlayers() do
	task.spawn(load, p)
end

Players.PlayerRemoving:Connect(function(p)
	save(p)
	loaded[p] = nil
	lastSaved[p] = nil
	receipts[p] = nil
end)

_G.PyramidData = {
	IsLoaded = function(p)
		return loaded[p] == true
	end,
	HasReceipt = function(p, id)
		return table.find(receipts[p] or {}, id) ~= nil
	end,
	AddReceipt = function(p, id)
		local list = receipts[p]
		if not list then
			list = {}
			receipts[p] = list
		end
		table.insert(list, id)
		while #list > MAX_RECEIPTS do
			table.remove(list, 1)
		end
	end,
	Save = save,
}

task.spawn(function()
	while true do
		task.wait(AUTOSAVE)
		for _, p in Players:GetPlayers() do
			task.spawn(save, p)
		end
	end
end)

game:BindToClose(function()
	for _, p in Players:GetPlayers() do
		task.spawn(save, p)
	end
	task.wait()
	local t0 = os.clock()
	while pending > 0 and os.clock() - t0 < 25 do
		task.wait(0.1)
	end
end)
