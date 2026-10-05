local S = {}

S.Types = {
	Standard = { Name = "Sapphire Pyramid", Base = 100, Color = Color3.fromRGB(64, 132, 238), Mult = 1, Chamber = 2, Weight = 58 },
	Great = { Name = "Amethyst Pyramid", Base = 112, Color = Color3.fromRGB(162, 88, 232), Mult = 1.5, Chamber = 3, Weight = 28 },
	Giant = { Name = "Golden Pyramid", Base = 127, Color = Color3.fromRGB(250, 196, 40), Mult = 2, Chamber = 5, Weight = 10 },
	Colossal = { Name = "Diamond Pyramid", Base = 143, Color = Color3.fromRGB(120, 220, 255), Mult = 5, Chamber = 10, Weight = 4 },
}
S.Current = "Standard"

function S.pick(avoid)
	local sum = 0
	for key, t in S.Types do
		if key ~= avoid then
			sum += t.Weight
		end
	end
	local roll = math.random() * sum
	for key, t in S.Types do
		if key ~= avoid then
			roll -= t.Weight
			if roll <= 0 then
				return key
			end
		end
	end
	return S.Current
end

S.Cell = 3
S.SiteEast = -94
S.SiteZ = -40
S.Rim = 12
S.Studs = "rbxassetid://138926013267839"

S.BaseRange = 18
S.PlaceCooldown = 0.1
S.TrailTime = 1.5
S.CoinsPerBlock = 2
S.ResetDelay = 5
S.RollTime = 6.5

local cache = {}
function S.def(key)
	key = S.Types[key] and key or S.Current
	if cache[key] then
		return cache[key]
	end
	local t = table.clone(S.Types[key])
	t.Key = key
	t.Floors = math.ceil(t.Base / 2)
	t.PerCell = t.PerCell or 1
	t.Cell = S.Cell
	t.Footprint = t.Base * S.Cell
	t.Side = t.Footprint + 2 * S.Rim
	t.SiteX = S.SiteEast - t.Side / 2
	t.Starts = {}
	local cells = 0
	for f = 1, t.Floors do
		t.Starts[f] = cells
		local k = t.Base - 2 * (f - 1)
		cells += k * k
	end
	t.Cells = cells
	t.Total = cells * t.PerCell
	t.Height = t.Floors * t.Cell
	cache[key] = t
	return t
end

function S.side(t, f)
	return t.Base - 2 * (f - 1)
end

function S.floorOf(t, i)
	if i >= t.Cells then
		return t.Floors + 1, 0
	end
	local lo, hi = 1, t.Floors
	while lo < hi do
		local mid = (lo + hi + 1) // 2
		if t.Starts[mid] <= i then
			lo = mid
		else
			hi = mid - 1
		end
	end
	return lo, i - t.Starts[lo]
end

function S.box(t, origin, f, r0, r1, c0, c1, height)
	local k = S.side(t, f)
	local s = t.Cell
	local h = height or s
	local x0 = origin.X - k * s / 2
	local z0 = origin.Z - k * s / 2
	local size = Vector3.new((c1 - c0 + 1) * s, h, (r1 - r0 + 1) * s)
	local centre = Vector3.new(x0 + (c0 + c1 + 1) * s / 2, origin.Y + (f - 1) * s + h / 2, z0 + (r0 + r1 + 1) * s / 2)
	return CFrame.new(centre), size
end

function S.cellPos(t, origin, f, idx)
	local k = S.side(t, f)
	local s = t.Cell
	local r, c = idx // k, idx % k
	return Vector3.new(origin.X - k * s / 2 + (c + 0.5) * s, origin.Y + (f - 0.5) * s, origin.Z - k * s / 2 + (r + 0.5) * s)
end

function S.motion(hrp, hum)
	local md = hum and hum.MoveDirection or Vector3.zero
	md = Vector3.new(md.X, 0, md.Z)
	if md.Magnitude > 0.1 then
		return md.Unit, hum.WalkSpeed
	end
	local look = Vector3.new(hrp.CFrame.LookVector.X, 0, hrp.CFrame.LookVector.Z)
	return look.Magnitude > 0.01 and look.Unit or Vector3.new(0, 0, -1), 0
end

local BODY = 2.2
local LEAD = 0.5
local NEIGHBOUR = 3.5
function S.nearestFree(t, origin, f, fill, pos, n, range, dir, speed, anchor)
	dir = dir or Vector3.zero
	speed = speed or 0
	local k = S.side(t, f)
	local s = t.Cell
	local x0, z0 = origin.X - k * s / 2, origin.Z - k * s / 2
	local y = origin.Y + (f - 0.5) * s
	local pc, pr = math.floor((pos.X - x0) / s), math.floor((pos.Z - z0) / s)
	local w = math.ceil(range / s) + 1
	local reach = s / 2 + BODY
	local ahead = s + speed * LEAD
	local back = pos - dir * (s + speed * 0.1)
	local from = anchor or back
	local lx, lz = back.X - from.X, back.Z - from.Z
	local ll = lx * lx + lz * lz
	local function trail(cx, cz)
		local a = ll > 0 and math.clamp(((cx - from.X) * lx + (cz - from.Z) * lz) / ll, 0, 1) or 0
		return math.sqrt((cx - from.X - lx * a) ^ 2 + (cz - from.Z - lz * a) ^ 2)
	end
	local function done(r, c)
		if r < 0 or c < 0 or r >= k or c >= k then
			return true
		end
		return (fill[r * k + c] or 0) >= t.PerCell
	end
	local found = {}
	for r = math.max(0, pr - w), math.min(k - 1, pr + w) do
		for c = math.max(0, pc - w), math.min(k - 1, pc + w) do
			local idx = r * k + c
			if (fill[idx] or 0) < t.PerCell then
				local cx, cz = x0 + (c + 0.5) * s, z0 + (r + 0.5) * s
				if (Vector3.new(cx, y, cz) - pos).Magnitude <= range then
					local rx, rz = cx - pos.X, cz - pos.Z
					local group = 1
					if math.abs(rx) < reach and math.abs(rz) < reach then
						group = 3
					else
						local fwd = rx * dir.X + rz * dir.Z
						local side = math.abs(rx * dir.Z - rz * dir.X)
						if dir.Magnitude > 0 and fwd > -reach and fwd < ahead + reach and side < reach then
							group = 2
						end
					end
					local around = (done(r - 1, c) and 1 or 0) + (done(r + 1, c) and 1 or 0)
						+ (done(r, c - 1) and 1 or 0) + (done(r, c + 1) and 1 or 0)
					local toBack = math.sqrt((cx - back.X) ^ 2 + (cz - back.Z) ^ 2)
					local score = trail(cx, cz) + 0.2 * toBack - NEIGHBOUR * around
					table.insert(found, { idx, score, group })
				end
			end
		end
	end
	table.sort(found, function(a, b)
		if a[3] ~= b[3] then
			return a[3] < b[3]
		end
		if a[2] ~= b[2] then
			return a[2] < b[2]
		end
		return a[1] < b[1]
	end)
	local out = {}
	for i = 1, math.min(n, #found) do
		out[i] = found[i][1]
	end
	return out
end

function S.targets(t, origin, f, fill, pos, amount, range, dir, speed, anchor)
	local out = {}
	for _, idx in S.nearestFree(t, origin, f, fill, pos, amount, range, dir, speed, anchor) do
		if amount <= 0 then
			break
		end
		table.insert(out, idx)
		amount -= t.PerCell - (fill[idx] or 0)
	end
	return out
end

function S.closestFree(t, origin, f, fill, pos)
	local k = S.side(t, f)
	local best, bestD
	for idx = 0, k * k - 1 do
		if (fill[idx] or 0) < t.PerCell then
			local d = (S.cellPos(t, origin, f, idx) - pos).Magnitude
			if not bestD or d < bestD then
				best, bestD = idx, d
			end
		end
	end
	return best
end

function S.origin(site, t)
	local area = site:FindFirstChild("BuildArea")
	local ground = site:FindFirstChild("Foundation")
	local y = ground and (ground.Position.Y + ground.Size.Y / 2) or (area.Position.Y - area.Size.Y / 2)
	return Vector3.new(t.SiteX, y, S.SiteZ)
end

function S.range(player)
	return S.BaseRange * (1 + (tonumber(player:GetAttribute("PlaceRangeBonus")) or 0) / 100)
end

return S
