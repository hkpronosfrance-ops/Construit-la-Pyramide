local RS = game:GetService("ReplicatedStorage")
local folder = RS.PyramidHUD
local C = require(folder.Config)
local U = require(folder.UpgradesConfig)
local ServerBoosts = require(script.Parent:WaitForChild("PyramidServerBoosts"))

local ADD = { coins = C.Stats.Coins, strength = C.Stats.Strength, speed = C.Stats.Speed }
local SET = {
	setcoins = C.Stats.Coins,
	pyramids = C.Stats.Pyramids,
	setstrength = C.Stats.Strength,
	setspeed = C.Stats.Speed,
	statblocks = "Blocks",
}

local function site()
	return workspace.PyramidMap.PyramidSite
end

local function root(p)
	local ch = p.Character
	return ch and ch:FindFirstChild("HumanoidRootPart")
end

local function setUpgrade(p, u, level)
	level = math.clamp(math.floor(level), 1, U.MaxLevel)
	p:SetAttribute(u.Level, level)
	p:SetAttribute(u.Value, u.Effect(level))
end

local function setBoost(p, b, times)
	p:SetAttribute(b.Level, times)
	p:SetAttribute(b.Multiplier, C.multiplier(b, times))
end

local function setZones(p, open)
	for zone in C.ZoneUnlock or {} do
		p:SetAttribute("Unlocked_" .. zone, open or nil)
	end
end

return {
	Execute = function(ctx, admin, action, args)
		if action == "day" or action == "night" then
			game.Lighting.ClockTime = action == "day" and 14 or 0
			return "Lighting updated."
		end
		if action == "blocks" then
			local s = site()
			local total = s:GetAttribute("BlocksTotal") or C.PyramidTotal
			local n = ctx.number(args[1], 0, total, true)
			s:SetAttribute("BlocksPlaced", n)
			return "Pyramid blocks set to " .. n .. "."
		end
		if action == "fillpct" then
			local s = site()
			local total = s:GetAttribute("BlocksTotal") or C.PyramidTotal
			local pct = ctx.number(args[1], 0, 100, false)
			s:SetAttribute("BlocksPlaced", math.floor(total * pct / 100))
			return "Pyramid filled to " .. pct .. "%."
		end
		if action == "finishpyramid" then
			local s = site()
			s:SetAttribute("BlocksPlaced", s:GetAttribute("BlocksTotal"))
			return "Pyramid finished; the next one starts in a few seconds."
		end
		if action == "pyramidtype" then
			local build = _G.PyramidBuild
			assert(build, "The pyramid service is not running.")
			local key = args[1]
			local name = build.Start(key ~= "random" and key or nil)
			assert(name, "The pyramid is just finishing, try again in a few seconds.")
			return "New pyramid: " .. name .. "."
		end

		if action == "chamberadd" then
			local s = site()
			assert(s:GetAttribute("ChamberOpen"), "The chamber is closed: finish a pyramid first.")
			local n = ctx.number(args[1], 1, 60, true)
			local max = C.Chamber.MaxMinutes
			local mins = s:GetAttribute("ChamberMinutes") or C.Chamber.Minutes
			local add = math.clamp(n, 0, max - mins)
			s:SetAttribute("ChamberMinutes", mins + add)
			s:SetAttribute("ChamberEnd", (s:GetAttribute("ChamberEnd") or workspace:GetServerTimeNow()) + add * 60)
			return ("Chamber +%d min (%d / %d)."):format(add, mins + add, max)
		end
		if action == "chamberclose" then
			local s = site()
			assert(s:GetAttribute("ChamberOpen"), "The chamber is already closed.")
			s:SetAttribute("ChamberOpen", false)
			return "Chamber closed; the next pyramid is drawn."
		end

		if action == "serverboost" then
			local kind = ServerBoosts.Resolve(args[1])
			assert(kind, "Use speed, coins, strength, pyramids or all.")
			local multiplier = ctx.number(args[2], 1, 100, false)
			local minutes = ctx.number(args[3], 0.1, 1440, false)
			ServerBoosts.Set(kind, multiplier, minutes * 60)
			return ("Server boost %s x%s for %s min."):format(kind, tostring(multiplier), tostring(minutes))
		end
		if action == "serverboostoff" then
			local kind = ServerBoosts.Resolve(args[1] or "all")
			assert(kind, "Use speed, coins, strength, pyramids or all.")
			ServerBoosts.Stop(kind)
			return "Server boost stopped: " .. kind .. "."
		end
		if action == "serverbooststatus" then
			local parts = {}
			for _, kind in { "speed", "coins", "strength", "pyramids" } do
				local multiplier, seconds = ServerBoosts.Status(kind)
				table.insert(parts, ("%s x%s (%ds)"):format(kind, tostring(multiplier), math.ceil(seconds)))
			end
			return table.concat(parts, " | ")
		end

		local p = ctx.player(args[1])
		if action == "teleport" or action == "bring" then
			local a, b = root(admin), root(p)
			assert(a and b, "Both players need a character.")
			if action == "teleport" then
				a.CFrame = b.CFrame * CFrame.new(0, 0, 4)
				return "Teleported to " .. p.Name .. "."
			end
			b.CFrame = a.CFrame * CFrame.new(0, 0, -4)
			return "Brought " .. p.Name .. "."
		end
		if action == "carry" then
			local cap = p:GetAttribute(C.Stats.Capacity) or 1
			local n = ctx.number(args[2], 0, cap, true)
			p:SetAttribute(C.Stats.Carrying, n)
			return p.Name .. " now carries " .. n .. " blocks."
		end
		if action == "fillbag" then
			local cap = p:GetAttribute(C.Stats.Capacity) or 1
			p:SetAttribute(C.Stats.Carrying, cap)
			return "Backpack filled for " .. p.Name .. " (" .. cap .. ")."
		end
		if action == "upgrade" then
			local u = U.get(args[2] or "")
			assert(u, "Unknown upgrade.")
			local n = ctx.number(args[3], 1, U.MaxLevel, true)
			setUpgrade(p, u, n)
			return u.Title .. " set to Lv." .. n .. " for " .. p.Name .. "."
		end
		if action == "maxupgrades" or action == "resetupgrades" then
			for _, u in U.List do
				setUpgrade(p, u, action == "maxupgrades" and U.MaxLevel or 1)
			end
			return "Upgrades " .. (action == "maxupgrades" and "maxed" or "reset") .. " for " .. p.Name .. "."
		end
		if action == "boost" then
			local b = C.boost(args[2] or "")
			assert(b, "Unknown boost.")
			local n = ctx.number(args[3], 0, 100, true)
			setBoost(p, b, n)
			return b.Title .. " bought " .. n .. " times for " .. p.Name .. "."
		end
		if action == "pharaoh" then
			local mode = string.lower(args[2] or "")
			assert(mode == "on" or mode == "off", "Use on or off.")
			p:SetAttribute("PharaohOff", mode == "off" or nil)
			if mode == "off" then
				return "Pharaoh perks turned off for " .. p.Name .. "."
			end
			if p:GetAttribute("PharaohPass") ~= true then
				return p.Name .. " does not own the Pharaoh pass."
			end
			return "Pharaoh perks turned on for " .. p.Name .. "."
		end
		if action == "unlockzones" or action == "lockzones" then
			setZones(p, action == "unlockzones")
			return "Gym zones " .. (action == "unlockzones" and "unlocked" or "locked") .. " for " .. p.Name .. "."
		end
		if action == "resetplayer" then
			for _, key in { C.Stats.Coins, C.Stats.Speed, C.Stats.Strength, C.Stats.Pyramids, C.Stats.Carrying, "Blocks" } do
				p:SetAttribute(key, 0)
			end
			for _, u in U.List do
				setUpgrade(p, u, 1)
			end
			for _, b in C.Boosts do
				setBoost(p, b, 0)
			end
			setZones(p, false)
			return "All stats reset for " .. p.Name .. "."
		end
		local key = ADD[action] or SET[action]
		assert(key, "Unknown command.")
		local n = ctx.number(args[2], 0, 1e15, true)
		p:SetAttribute(key, ADD[action] and ((p:GetAttribute(key) or 0) + n) or n)
		return key .. " updated for " .. p.Name .. "."
	end,
}
