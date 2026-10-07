local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local DSS = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local folder = RS:WaitForChild("PyramidHUD")
local C = require(folder:WaitForChild("Config"))
local U = require(folder:WaitForChild("UpgradesConfig"))

local LIVE = not RunService:IsStudio()
local STORE = LIVE and DSS:GetDataStore("BuildThePyramid_Players_v1") or nil
local VERSION = 1
local AUTOSAVE = 60
local RETRIES = 4

-- Session ownership prevents an older server from overwriting a newer session.
-- The lease is refreshed by the normal autosave loop. A dead server's lease
-- eventually expires, while PlayerRemoving/BindToClose release it immediately.
local SESSION_TTL = 180
local CLAIM_ATTEMPTS = 12
local CLAIM_WAIT = 2

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
local revisions = {}
local sessionExpiry = {}
local MAX_RECEIPTS = 50

local SERVER_SESSION = (game.JobId ~= "" and game.JobId or "studio") .. ":" .. HttpService:GenerateGUID(false)

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

local function revisionOf(data)
	local n = type(data) == "table" and tonumber(data.Revision) or nil
	if not n or n ~= n or n == math.huge or n == -math.huge then
		return 0
	end
	return math.max(0, math.floor(n))
end

local function leaseExpiryOf(data)
	local n = type(data) == "table" and tonumber(data.SessionExpiresAt) or nil
	if not n or n ~= n or n == math.huge or n == -math.huge then
		return 0
	end
	return n
end

local function mergeSnapshot(old, data)
	local merged = type(old) == "table" and table.clone(old) or {}
	for _, name in SAVED do
		merged[name] = nil
	end
	merged.Receipts = nil
	for k, v in data do
		merged[k] = v
	end
	return merged
end

local function foreignLiveSession(old, now)
	if type(old) ~= "table" then
		return false
	end
	local owner = old.SessionId
	return type(owner) == "string"
		and owner ~= ""
		and owner ~= SERVER_SESSION
		and leaseExpiryOf(old) > now
end

local function claimSession(p)
	local blockedUntil = 0
	for attempt = 1, CLAIM_ATTEMPTS do
		local blocked = false
		local now = os.time()
		local ok, data = retry(function()
			return STORE:UpdateAsync(key(p), function(old)
				if foreignLiveSession(old, now) then
					blocked = true
					blockedUntil = leaseExpiryOf(old)
					return nil
				end
				local claimed = type(old) == "table" and table.clone(old) or { Version = VERSION }
				claimed.Version = tonumber(claimed.Version) or VERSION
				claimed.SessionId = SERVER_SESSION
				claimed.SessionExpiresAt = now + SESSION_TTL
				claimed.Revision = revisionOf(claimed)
				return claimed
			end)
		end)
		if not ok then
			return false, data, "error"
		end
		if not blocked then
			return true, type(data) == "table" and data or {}, nil
		end
		if not p.Parent then
			return false, nil, "left"
		end
		if attempt < CLAIM_ATTEMPTS then
			local remaining = math.max(0, blockedUntil - os.time())
			task.wait(math.min(CLAIM_WAIT, math.max(0.25, remaining)))
		end
	end
	return false, blockedUntil, "locked"
end

local function loseSession(p)
	if not loaded[p] then
		return
	end
	loaded[p] = nil
	p:SetAttribute("DataSessionLost", true)
	if p.Parent then
		task.defer(function()
			if p.Parent then
				p:Kick("Your data session moved to another server. Please rejoin.")
			end
		end)
	end
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
		if not loaded[p] then
			return false
		end
	end

	local data = snapshot(p)
	local dirty = not same(data, lastSaved[p])
	saving[p] = true
	pending += 1

	local conflict = false
	local now = os.time()
	local expectedRevision = revisions[p] or 0
	local ok, result = retry(function()
		return STORE:UpdateAsync(key(p), function(old)
			if foreignLiveSession(old, now) then
				conflict = true
				return nil
			end

			local oldRevision = revisionOf(old)
			local owner = type(old) == "table" and old.SessionId or nil
			local externallyChanged = owner ~= SERVER_SESSION or oldRevision ~= expectedRevision

			local merged
			if dirty or externallyChanged then
				-- If an old server from a previous deployment overwrote the record and
				-- removed our lease metadata, restore the active session's authoritative
				-- in-memory snapshot instead of accepting that stale write.
				merged = mergeSnapshot(old, data)
				merged.Revision = math.max(oldRevision, expectedRevision) + 1
			else
				merged = type(old) == "table" and table.clone(old) or mergeSnapshot(nil, data)
				merged.Revision = oldRevision
			end

			merged.Version = VERSION
			merged.SessionId = SERVER_SESSION
			merged.SessionExpiresAt = now + SESSION_TTL
			merged.LastSaveAt = now
			return merged
		end)
	end)

	pending -= 1
	saving[p] = nil

	if conflict then
		warn("[PyramidData] session ownership lost for " .. p.Name)
		loseSession(p)
		return false
	end
	if not ok then
		warn("[PyramidData] could not save " .. p.Name .. ": " .. tostring(result))
		return false
	end

	if type(result) == "table" then
		revisions[p] = revisionOf(result)
		sessionExpiry[p] = leaseExpiryOf(result)
	end
	lastSaved[p] = data
	return true
end

local function releaseSession(p)
	if not LIVE then
		return
	end
	local ok, err = retry(function()
		return STORE:UpdateAsync(key(p), function(old)
			if type(old) ~= "table" or old.SessionId ~= SERVER_SESSION then
				return nil
			end
			local released = table.clone(old)
			released.SessionId = nil
			released.SessionExpiresAt = 0
			released.LastSaveAt = os.time()
			return released
		end)
	end)
	if not ok then
		warn("[PyramidData] could not release session for " .. p.Name .. ": " .. tostring(err))
	end
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

	local ok, data, reason = claimSession(p)
	if not p.Parent then
		return
	end
	if not ok then
		if reason == "locked" then
			warn("[PyramidData] active session already owns " .. p.Name)
			p:SetAttribute("DataLoadFailed", true)
			p:Kick("Your progress is still open on another server. Please wait a moment and rejoin.")
		elseif reason ~= "left" then
			warn("[PyramidData] could not load " .. p.Name .. ": " .. tostring(data))
			p:SetAttribute("DataLoadFailed", true)
			p:Kick("Your progress could not be loaded. Please rejoin.")
		end
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
	revisions[p] = revisionOf(data)
	sessionExpiry[p] = leaseExpiryOf(data)
	lastSaved[p] = snapshot(p)
	p:SetAttribute("DataLoaded", true)
end

Players.PlayerAdded:Connect(load)
for _, p in Players:GetPlayers() do
	task.spawn(load, p)
end

local function closePlayer(p)
	if loaded[p] then
		save(p)
		releaseSession(p)
	end
	loaded[p] = nil
	lastSaved[p] = nil
	receipts[p] = nil
	revisions[p] = nil
	sessionExpiry[p] = nil
	saving[p] = nil
end

Players.PlayerRemoving:Connect(closePlayer)

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
	local closing = {}
	for _, p in Players:GetPlayers() do
		closing[p] = true
		task.spawn(function()
			if loaded[p] then
				save(p)
				releaseSession(p)
			end
			closing[p] = nil
		end)
	end
	local t0 = os.clock()
	while (pending > 0 or next(closing) ~= nil) and os.clock() - t0 < 25 do
		task.wait(0.1)
	end
end)
