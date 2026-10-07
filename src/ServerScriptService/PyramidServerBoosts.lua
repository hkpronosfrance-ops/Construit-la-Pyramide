local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local hud = RS:WaitForChild("PyramidHUD")

local M = {}

local STUDIO = RunService:IsStudio()
M.MaxMultiplier = STUDIO and 100 or 5
M.MaxDurationSeconds = STUDIO and 24 * 60 * 60 or 6 * 60 * 60

local TYPES = {
	speed = "Speed",
	coins = "Coins",
	strength = "Strength",
	pyramids = "Pyramids",
}

local ALIASES = {
	speed = "speed",
	vitesse = "speed",
	coins = "coins",
	coin = "coins",
	pieces = "coins",
	["pièces"] = "coins",
	strength = "strength",
	force = "strength",
	pyramids = "pyramids",
	pyramid = "pyramids",
	pyramides = "pyramids",
	piramides = "pyramids",
}

local function now()
	return workspace:GetServerTimeNow()
end

local function attrs(key)
	local suffix = TYPES[key]
	return "ServerBoost" .. suffix .. "Multiplier", "ServerBoost" .. suffix .. "End"
end

function M.Resolve(value)
	local key = tostring(value or ""):lower()
	if key == "all" or key == "tout" then
		return "all"
	end
	return ALIASES[key]
end

local function initKey(key)
	local multAttr, endAttr = attrs(key)
	if hud:GetAttribute(multAttr) == nil then
		hud:SetAttribute(multAttr, 1)
	end
	if hud:GetAttribute(endAttr) == nil then
		hud:SetAttribute(endAttr, 0)
	end
end

for key in TYPES do
	initKey(key)
end

function M.Get(key)
	key = M.Resolve(key) or key
	if key == "all" or not TYPES[key] then
		return 1
	end
	local multAttr, endAttr = attrs(key)
	local mult = tonumber(hud:GetAttribute(multAttr)) or 1
	local endsAt = tonumber(hud:GetAttribute(endAttr)) or 0
	if mult <= 1 or endsAt <= now() then
		return 1
	end
	return mult
end

local function setOne(key, multiplier, durationSeconds)
	local multAttr, endAttr = attrs(key)
	if multiplier <= 1 or durationSeconds <= 0 then
		hud:SetAttribute(multAttr, 1)
		hud:SetAttribute(endAttr, 0)
		return
	end
	hud:SetAttribute(multAttr, multiplier)
	hud:SetAttribute(endAttr, now() + durationSeconds)
end

function M.Set(key, multiplier, durationSeconds)
	key = M.Resolve(key) or key
	assert(key == "all" or TYPES[key], "Unknown server multiplier.")
	multiplier = math.clamp(tonumber(multiplier) or 1, 1, M.MaxMultiplier)
	durationSeconds = math.clamp(tonumber(durationSeconds) or 0, 0, M.MaxDurationSeconds)
	if key == "all" then
		for one in TYPES do
			setOne(one, multiplier, durationSeconds)
		end
	else
		setOne(key, multiplier, durationSeconds)
	end
end

function M.Stop(key)
	key = M.Resolve(key) or key
	if key == "all" then
		for one in TYPES do
			setOne(one, 1, 0)
		end
	elseif TYPES[key] then
		setOne(key, 1, 0)
	end
end

function M.Status(key)
	key = M.Resolve(key) or key
	if not TYPES[key] then
		return 1, 0
	end
	local multAttr, endAttr = attrs(key)
	local multiplier = M.Get(key)
	local endsAt = tonumber(hud:GetAttribute(endAttr)) or 0
	return multiplier, math.max(0, endsAt - now())
end

task.spawn(function()
	while task.wait(1) do
		local t = now()
		for key in TYPES do
			local multAttr, endAttr = attrs(key)
			local endsAt = tonumber(hud:GetAttribute(endAttr)) or 0
			if endsAt > 0 and endsAt <= t then
				hud:SetAttribute(multAttr, 1)
				hud:SetAttribute(endAttr, 0)
			end
		end
	end
end)

return M
