local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local folder = RS:WaitForChild("PyramidHUD")
local C = require(folder:WaitForChild("Config"))
local S = require(folder:WaitForChild("PyramidShape"))
local L = require(folder:WaitForChild("ChamberLayouts"))
local surface = RS:FindFirstChild("SandstoneSurface")
local Sandstone = surface and require(surface)

local site = workspace:WaitForChild("PyramidMap"):WaitForChild("PyramidSite")

local SPRING_TAG = "PyramidSpring"

local function now()
	return workspace:GetServerTimeNow()
end

local function subtract(r, holes)
	local as, bs = { r[1], r[2] }, { r[3], r[4] }
	for _, h in holes do
		for _, a in { h[1], h[2] } do
			if a > r[1] and a < r[2] then
				table.insert(as, a)
			end
		end
		for _, b in { h[3], h[4] } do
			if b > r[3] and b < r[4] then
				table.insert(bs, b)
			end
		end
	end
	local function unique(t)
		table.sort(t)
		local out = {}
		for _, v in t do
			if #out == 0 or v - out[#out] > 1e-4 then
				table.insert(out, v)
			end
		end
		return out
	end
	as, bs = unique(as), unique(bs)
	local out = {}
	for j = 1, #bs - 1 do
		local bm = (bs[j] + bs[j + 1]) / 2
		local start
		for i = 1, #as - 1 do
			local am = (as[i] + as[i + 1]) / 2
			local covered = false
			for _, h in holes do
				if am > h[1] and am < h[2] and bm > h[3] and bm < h[4] then
					covered = true
					break
				end
			end
			if not covered then
				start = start or as[i]
			elseif start then
				table.insert(out, { start, as[i], bs[j], bs[j + 1] })
				start = nil
			end
		end
		if start then
			table.insert(out, { start, as[#as], bs[j], bs[j + 1] })
		end
	end
	return out
end

local function worldBoxes(layout, o, t)
	local face = t.Footprint / 2 + 2
	local out = {}
	for _, b in layout.Boxes do
		local x1 = b.x1 == "face" and face or b.x1
		local lx1 = b.x1 == "face" and (t.Footprint / 2 - (math.ceil(b.y1 / t.Cell) - 1) * t.Cell) or nil
		table.insert(out, {
			name = b.name,
			x0 = o.X + b.x0, x1 = o.X + x1, lx1 = lx1 and o.X + lx1, z0 = o.Z + b.z0, z1 = o.Z + b.z1,
			y0 = o.Y, y1 = o.Y + b.y1, wallTop = o.Y + b.y1 - (b.gable or 0),
			gable = b.gable, open = b.open,
		})
	end
	return out
end

local function stone(template, class, size, cf, parent)
	local p
	if class == "Part" then
		p = template:Clone()
	else
		p = Instance.new(class)
		p.Anchored = true
		p.Color, p.Material, p.MaterialVariant = template.Color, template.Material, template.MaterialVariant
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.CanTouch = false
		for _, tx in template:GetChildren() do
			tx:Clone().Parent = p
		end
	end
	p.Name = "Fill"
	p.Size, p.CFrame = size, cf
	p.Parent = parent
	return p
end

local function fillOverRoof(part, template, b, fy0, fy1)
	local xa, xb = b.x0, math.min(b.x1, part.Position.X + part.Size.X / 2)
	local a = math.max(fy0, b.wallTop)
	if xb - xa < 0.05 or fy1 - a < 0.05 then
		return
	end
	local xm, w = (xa + xb) / 2, xb - xa
	local r0 = math.max(a, b.y1)
	if fy1 - r0 > 0.05 then
		stone(template, "Part", Vector3.new(w, fy1 - r0, b.z1 - b.z0), CFrame.new(xm, (r0 + fy1) / 2, (b.z0 + b.z1) / 2), part)
	end
	local g = b.gable or 0
	local ya, yb = a, math.min(fy1, b.y1)
	if g > 0 and yb - ya > 0.05 then
		local half, zc = (b.z1 - b.z0) / 2, (b.z0 + b.z1) / 2
		local da, db = half * (ya - b.wallTop) / g, half * (yb - b.wallTop) / g
		for _, s in { -1, 1 } do
			local edge = zc + s * half
			if da > 0.05 then
				stone(template, "Part", Vector3.new(w, yb - ya, da), CFrame.new(xm, (ya + yb) / 2, edge - s * da / 2), part)
			end
			stone(template, "WedgePart", Vector3.new(w, yb - ya, db - da), CFrame.fromMatrix(Vector3.new(xm, (ya + yb) / 2, edge - s * (da + db) / 2),
				Vector3.new(-s, 0, 0), Vector3.new(0, -1, 0), Vector3.new(0, 0, s)), part)
		end
	end
end

local function carve(t, boxes)
	local built = site:FindFirstChild("Built")
	if not built then
		return nil
	end
	local first
	for f = 1, t.Floors do
		local part = built:FindFirstChild("Floor" .. f)
		if part and part:IsA("BasePart") then
			first = first or part
			local fy0 = part.Position.Y - part.Size.Y / 2
			local fy1 = part.Position.Y + part.Size.Y / 2
			local holes = {}
			for _, b in boxes do
				if b.y0 < fy1 - 0.01 and b.y1 > fy0 + 0.01 then
					table.insert(holes, { b.x0, b.x1, b.z0, b.z1 })
				end
			end
			if #holes > 0 then
				local half = part.Size / 2
				local r = { part.Position.X - half.X, part.Position.X + half.X, part.Position.Z - half.Z, part.Position.Z + half.Z }
				local template = part:Clone()
				for _, ch in template:GetChildren() do
					if not ch:IsA("Texture") then
						ch:Destroy()
					end
				end
				for _, q in subtract(r, holes) do
					local piece = template:Clone()
					piece.Name = "Piece"
					piece.Size = Vector3.new(q[2] - q[1], part.Size.Y, q[4] - q[3])
					piece.CFrame = CFrame.new((q[1] + q[2]) / 2, part.Position.Y, (q[3] + q[4]) / 2)
					piece.Parent = part
				end
				for _, b in boxes do
					if b.open == "+x" then
						fillOverRoof(part, template, b, fy0, fy1)
					end
				end
				template:Destroy()
				part.Transparency = 1
				part.CanCollide = false
				part.CanQuery = false
				part.CanTouch = false
				for _, ch in part:GetChildren() do
					if ch:IsA("Texture") then
						ch.Transparency = 1
					end
				end
			end
		end
	end
	return first
end

local function block(parent, name, size, cf, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanTouch = false
	p.Parent = parent
	if Sandstone and not material then
		Sandstone.Apply(p)
	end
	return p
end

local function line(m, b, boxes, pal)
	local bx1 = b.lx1 or b.x1
	local cx, cz = (b.x0 + bx1) / 2, (b.z0 + b.z1) / 2
	local w, d = bx1 - b.x0, b.z1 - b.z0
	block(m, b.name .. "Floor", Vector3.new(w, 0.4, d), CFrame.new(cx, b.y0 + 0.2, cz), pal.Floor)
	if b.gable then
		local half = d / 2
		local ang = math.atan2(b.gable, half)
		local len = math.sqrt(half * half + b.gable * b.gable) + 0.6
		for s = -1, 1, 2 do
			block(m, b.name .. "Roof", Vector3.new(w, 1, len), CFrame.new(cx, b.wallTop + b.gable / 2, cz + s * half / 2) * CFrame.Angles(s * ang, 0, 0) * CFrame.new(0, -0.75, 0), pal.Wall)
		end
	else
		block(m, b.name .. "Ceiling", Vector3.new(w, 1, d), CFrame.new(cx, b.y1 - 0.5, cz), pal.Wall)
	end
	local faces = {
		{ key = "+x", axis = "x", at = bx1, out = 1, u0 = b.z0, u1 = b.z1 },
		{ key = "-x", axis = "x", at = b.x0, out = -1, u0 = b.z0, u1 = b.z1 },
		{ key = "+z", axis = "z", at = b.z1, out = 1, u0 = b.x0, u1 = bx1 },
		{ key = "-z", axis = "z", at = b.z0, out = -1, u0 = b.x0, u1 = bx1 },
	}
	for _, f in faces do
		if b.open ~= f.key then
			local openings = {}
			for _, o in boxes do
				if o ~= b then
					local lo, hi = f.axis == "x" and o.x0 or o.z0, f.axis == "x" and o.x1 or o.z1
					local crosses = (f.out > 0 and lo <= f.at + 0.01 and hi > f.at + 0.01) or (f.out < 0 and hi >= f.at - 0.01 and lo < f.at - 0.01)
					if crosses then
						local ou0, ou1 = f.axis == "x" and o.z0 or o.x0, f.axis == "x" and o.z1 or o.x1
						local a0, a1 = math.max(f.u0, ou0), math.min(f.u1, ou1)
						local v1 = math.min(b.wallTop, o.wallTop)
						if a1 > a0 and v1 > b.y0 then
							table.insert(openings, { a0, a1, b.y0, v1 })
						end
					end
				end
			end
			for _, q in subtract({ f.u0, f.u1, b.y0, b.wallTop }, openings) do
				local um, vm = (q[1] + q[2]) / 2, (q[3] + q[4]) / 2
				local inward = f.at - f.out * 0.5
				if f.axis == "x" then
					block(m, b.name .. "Wall", Vector3.new(1, q[4] - q[3], q[2] - q[1]), CFrame.new(inward, vm, um), pal.Wall)
				else
					block(m, b.name .. "Wall", Vector3.new(q[2] - q[1], q[4] - q[3], 1), CFrame.new(um, vm, inward), pal.Wall)
				end
			end
		end
	end
end

local DECK = 3.2
local STEPS, STEP_RUN = 3, 2.2
local WATER_TEXTURE = "rbxassetid://76175233029521"
local WATER_FLOW = "PyramidWaterFlow"
local function waterTexture(part, name, studs, transparency, flowU, flowV, sway)
	local t = Instance.new("Texture")
	t.Name = name
	t.Texture = WATER_TEXTURE
	t.Face = Enum.NormalId.Top
	t.StudsPerTileU, t.StudsPerTileV = studs, studs
	t.Transparency = transparency
	t:SetAttribute("FlowU", flowU)
	t:SetAttribute("FlowV", flowV)
	t:SetAttribute("Sway", sway)
	t.Parent = part
	CollectionService:AddTag(t, WATER_FLOW)
	return t
end

local function ramp(m, name, pos, width, height, run, outward, pal)
	local up = Vector3.yAxis
	local p = Instance.new("WedgePart")
	p.Name = name
	p.Anchored = true
	p.Size = Vector3.new(width, height, run)
	p.CFrame = CFrame.fromMatrix(pos, up:Cross(outward), up, outward)
	p.Color = pal.Trim
	p.Material = Enum.Material.SmoothPlastic
	p.CanTouch = false
	p.Parent = m
	return p
end

local function feature(m, f, o, boxes, pal)
	local floorY = o.Y + 0.4
	if f.kind == "platform" or f.kind == "slab" then
		local h = f.h == "deck" and DECK or f.h
		local y0 = f.kind == "slab" and floorY + h - 0.6 or floorY
		block(m, "Platform", Vector3.new(f.x1 - f.x0, floorY + h - y0, f.z1 - f.z0), CFrame.new(o.X + (f.x0 + f.x1) / 2, (y0 + floorY + h) / 2, o.Z + (f.z0 + f.z1) / 2), pal.Trim)
	elseif f.kind == "pillar" then
		local top = o.Y + 20
		for _, b in boxes do
			if b.name == f.room then
				top = b.y1 - 1
			end
		end
		block(m, "Pillar", Vector3.new(f.size, top - floorY, f.size), CFrame.new(o.X + f.x, (floorY + top) / 2, o.Z + f.z), pal.Trim)
	elseif f.kind == "pool" then
		local x0, x1, z0, z1 = o.X + f.x0, o.X + f.x1, o.Z + f.z0, o.Z + f.z1
		local hall
		for _, b in boxes do
			if b.name == (f.room or "Hall") then
				hall = b
			end
		end
		if hall then
			for _, q in subtract({ hall.x0, hall.x1, hall.z0, hall.z1 }, { { x0, x1, z0, z1 } }) do
				block(m, "Deck", Vector3.new(q[2] - q[1], DECK, q[4] - q[3]), CFrame.new((q[1] + q[2]) / 2, floorY + DECK / 2, (q[3] + q[4]) / 2), pal.Floor)
			end
			for _, b in boxes do
				if b ~= hall and b.x0 < hall.x1 and b.x1 > hall.x1 then
					local s0, s1 = math.max(b.z0, hall.z0), math.min(b.z1, hall.z1)
					ramp(m, "Ramp", Vector3.new(hall.x1 + 3, floorY + DECK / 2, (s0 + s1) / 2), s1 - s0, DECK, 6, -Vector3.xAxis, pal)
				end
			end
		end
		local bottom = floorY + 0.3
		local rise = (floorY + DECK - bottom) / (STEPS + 1)
		local LIP, LIP_W = Color3.fromRGB(255, 244, 214), 0.35
		for k = 1, STEPS do
			local i0, i1 = (k - 1) * STEP_RUN, k * STEP_RUN
			local stepTop = floorY + DECK - k * rise
			local tile = pal.Trim:Lerp(pal.Water, 0.15 + 0.12 * k)
			for _, q in subtract({ x0 + i0, x1 - i0, z0 + i0, z1 - i0 }, { { x0 + i1, x1 - i1, z0 + i1, z1 - i1 } }) do
				local step = block(m, "PoolStep", Vector3.new(q[2] - q[1], stepTop - floorY, q[4] - q[3]), CFrame.new((q[1] + q[2]) / 2, (floorY + stepTop) / 2, (q[3] + q[4]) / 2), tile)
				step.CanCollide = false
				waterTexture(step, "Caustics", 14, 0.6, 1.2, 0, 2)
			end
			for _, e in {
				{ (x0 + x1) / 2, z0 + i1 - LIP_W / 2, x1 - x0 - 2 * i1 + 2 * LIP_W, LIP_W },
				{ (x0 + x1) / 2, z1 - i1 + LIP_W / 2, x1 - x0 - 2 * i1 + 2 * LIP_W, LIP_W },
				{ x0 + i1 - LIP_W / 2, (z0 + z1) / 2, LIP_W, z1 - z0 - 2 * i1 },
				{ x1 - i1 + LIP_W / 2, (z0 + z1) / 2, LIP_W, z1 - z0 - 2 * i1 },
			} do
				local lip = block(m, "StepLip", Vector3.new(e[3], 0.12, e[4]), CFrame.new(e[1], stepTop + 0.06, e[2]), LIP)
				lip.CanCollide = false
				lip.CanQuery = false
			end
		end
		local run = STEPS * STEP_RUN
		local rh = floorY + DECK - rise * 0.35 - bottom
		for _, e in {
			{ Vector3.new((x0 + x1) / 2, bottom + rh / 2, z1 - run / 2), x1 - x0, Vector3.zAxis },
			{ Vector3.new((x0 + x1) / 2, bottom + rh / 2, z0 + run / 2), x1 - x0, -Vector3.zAxis },
			{ Vector3.new(x1 - run / 2, bottom + rh / 2, (z0 + z1) / 2), z1 - z0, Vector3.xAxis },
			{ Vector3.new(x0 + run / 2, bottom + rh / 2, (z0 + z1) / 2), z1 - z0, -Vector3.xAxis },
		} do
			local r = ramp(m, "PoolRamp", e[1], e[2], rh, run, e[3], pal)
			r.Transparency = 1
			r.CastShadow = false
		end
		for _, q in subtract({ x0 - 1.2, x1 + 1.2, z0 - 1.2, z1 + 1.2 }, { { x0, x1, z0, z1 } }) do
			block(m, "PoolCoping", Vector3.new(q[2] - q[1], 0.25, q[4] - q[3]), CFrame.new((q[1] + q[2]) / 2, floorY + DECK + 0.125, (q[3] + q[4]) / 2), pal.Trim)
		end
		local bottomPart = block(m, "SpringBottom", Vector3.new(x1 - x0, 0.3, z1 - z0), CFrame.new((x0 + x1) / 2, floorY + 0.15, (z0 + z1) / 2), pal.Water:Lerp(Color3.fromRGB(0, 40, 80), 0.35))
		waterTexture(bottomPart, "Caustics", 14, 0.25, 1.2, 0, 2)
		local top = floorY + DECK - 0.4
		local depth = top - bottom
		local water = block(m, "Spring", Vector3.new(x1 - x0, depth, z1 - z0), CFrame.new((x0 + x1) / 2, bottom + depth / 2, (z0 + z1) / 2), pal.Water, Enum.Material.Glass)
		water.Transparency = 0.72
		water.CastShadow = false
		water.CanCollide = false
		water.CanQuery = false
		local glow = Instance.new("PointLight")
		glow.Color = pal.Water
		glow.Range = 40
		glow.Brightness = 1.2
		glow.Parent = water
		local surface = block(m, "SpringSurface", Vector3.new(x1 - x0, 0.1, z1 - z0), CFrame.new((x0 + x1) / 2, top + 0.02, (z0 + z1) / 2), pal.Water, Enum.Material.Glass)
		surface.Transparency = 0.7
		surface.CanCollide = false
		surface.CanQuery = false
		surface.CastShadow = false
		waterTexture(surface, "Ripples", 24, 0.55, -0.8, 0.6, 0)
		water:SetAttribute("Chamber", true)
		CollectionService:AddTag(water, SPRING_TAG)
	end
end

local function sign(parent, pos, lines)
	local anchor = block(parent, "SignAnchor", Vector3.new(1, 1, 1), CFrame.new(pos), Color3.new(1, 1, 1), Enum.Material.SmoothPlastic)
	anchor.Transparency = 1
	anchor.CanCollide = false
	anchor.CanQuery = false
	local total = 0
	for _, l in lines do
		total += l.h
	end
	local bb = Instance.new("BillboardGui")
	bb.Name = "Sign"
	bb.Size = UDim2.fromScale(lines[1].w, total)
	bb.LightInfluence = 0
	bb.MaxDistance = 220
	bb.Parent = anchor
	local y = 0
	for _, l in lines do
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.Position = UDim2.fromScale(0, y / total)
		t.Size = UDim2.fromScale(1, l.h / total)
		t.Font = Enum.Font.FredokaOne
		t.TextScaled = true
		t.Text = l.text
		t.TextColor3 = Color3.new(1, 1, 1)
		t.Parent = bb
		local st = Instance.new("UIStroke")
		st.Thickness = 3
		st.Color = Color3.fromRGB(30, 16, 40)
		st.Parent = t
		local g = Instance.new("UIGradient")
		if l.rainbow then
			local keys = {}
			for k = 0, 6 do
				keys[k + 1] = ColorSequenceKeypoint.new(k / 6, Color3.fromHSV((k * 0.14) % 1, 0.65, 1))
			end
			g.Color = ColorSequence.new(keys)
		else
			g.Rotation = 90
			g.Color = ColorSequence.new(Color3.fromRGB(255, 250, 225), Color3.fromRGB(255, 205, 110))
		end
		g.Parent = t
		y += l.h
	end
end

local function lights(m, layout, o)
	for _, l in layout.Lights or {} do
		local p = block(m, "Lamp", Vector3.new(1, 1, 1), CFrame.new(o.X + l[1], o.Y + l[2], o.Z + l[3]), layout.Palette.Light, Enum.Material.SmoothPlastic)
		p.Transparency = 1
		p.CanCollide = false
		p.CanQuery = false
		local pl = Instance.new("PointLight")
		pl.Color = layout.Palette.Light
		pl.Range = 40
		pl.Brightness = 1.6
		pl.Shadows = false
		pl.Parent = p
	end
end

local function openUp(t, mult)
	local layout = L[t.Key]
	local o = site:GetAttribute("Origin")
	if not (layout and o) then
		return
	end
	local boxes = worldBoxes(layout, o, t)
	local floor1 = carve(t, boxes)
	if not floor1 then
		return
	end
	local m = Instance.new("Model")
	m.Name = "ChamberInterior"
	for _, b in boxes do
		line(m, b, boxes, layout.Palette)
	end
	for _, f in layout.Features do
		feature(m, f, o, boxes, layout.Palette)
	end
	lights(m, layout, o)
	local text = ("%dx TRAINING INSIDE"):format(mult)
	sign(m, Vector3.new(o.X + t.Footprint / 2 + 6, o.Y + 20, o.Z), {
		{ text = "PHARAOH'S CHAMBER", w = 28, h = 3.2 },
		{ text = text, w = 28, h = 2.4, rainbow = true },
	})
	m.Parent = floor1
end

local delivering = {}

local function pendingMinutes(p)
	local n = tonumber(p:GetAttribute("PendingChamberMinutes")) or 0
	if n ~= n or n == math.huge or n == -math.huge then
		return 0
	end
	return math.max(0, math.floor(n))
end

local function deliverPending(p)
	if delivering[p] or not p.Parent or not site:GetAttribute("ChamberOpen") or not site:GetAttribute("ChamberReady") then
		return false
	end
	local data = _G.PyramidData
	if not (data and data.IsLoaded(p)) then
		return false
	end

	local pending = pendingMinutes(p)
	if pending <= 0 then
		return true
	end

	local mins = tonumber(site:GetAttribute("ChamberMinutes")) or C.Chamber.Minutes
	if mins ~= mins or mins == math.huge or mins == -math.huge then
		mins = C.Chamber.Minutes
	end
	mins = math.clamp(math.floor(mins), C.Chamber.Minutes, C.Chamber.MaxMinutes)
	local room = math.max(0, C.Chamber.MaxMinutes - mins)
	local add = math.min(pending, room)
	if add <= 0 then
		return false
	end

	delivering[p] = true
	local endAt = tonumber(site:GetAttribute("ChamberEnd"))
	if not endAt or endAt ~= endAt or endAt == math.huge or endAt == -math.huge then
		endAt = now()
	end

	-- Apply only what fits in the current chamber. Any remainder stays on the
	-- player and can be consumed by a later chamber/server.
	site:SetAttribute("ChamberMinutes", mins + add)
	site:SetAttribute("ChamberEnd", math.max(endAt, now()) + add * 60)
	p:SetAttribute("PendingChamberMinutes", pending - add)

	-- Persist the consumed credit promptly. If this save fails, the player's
	-- credit remains dirty and the normal autosave/leave path will retry it.
	task.spawn(function()
		if p.Parent and data.IsLoaded(p) then
			data.Save(p)
		end
		delivering[p] = nil
	end)
	return true
end

_G.PyramidChamber = {
	DeliverPending = deliverPending,
}

local function deliverOnlinePending()
	for _, p in Players:GetPlayers() do
		task.defer(deliverPending, p)
	end
end

local running = false
local function run()
	running = true
	local mult = site:GetAttribute("ChamberMult") or 2
	site:SetAttribute("ChamberMinutes", C.Chamber.Minutes)
	site:SetAttribute("ChamberEnd", now() + C.Chamber.Minutes * 60)
	local ok, err = pcall(openUp, S.def(site:GetAttribute("PyramidType")), mult)
	if not ok then
		warn("[PyramidChamber] could not open the pyramid: " .. tostring(err))
	end
	site:SetAttribute("ChamberReady", true)
	-- Paid minutes are player-owned credits. Apply saved credits only after the
	-- chamber is actually open and ready.
	deliverOnlinePending()
	while site:GetAttribute("ChamberOpen") and now() < (site:GetAttribute("ChamberEnd") or 0) do
		task.wait(0.25)
	end
	for _, water in CollectionService:GetTagged(SPRING_TAG) do
		CollectionService:RemoveTag(water, SPRING_TAG)
	end
	site:SetAttribute("ChamberMinutes", nil)
	site:SetAttribute("ChamberEnd", nil)
	site:SetAttribute("ChamberReady", nil)
	site:SetAttribute("ChamberOpen", false)
	running = false
end

site:GetAttributeChangedSignal("ChamberOpen"):Connect(function()
	if site:GetAttribute("ChamberOpen") and not running then
		task.spawn(run)
	end
end)
if site:GetAttribute("ChamberOpen") and not running then
	task.spawn(run)
end

local function watchPlayer(p)
	local function tryDeliver()
		if p:GetAttribute("DataLoaded") == true and pendingMinutes(p) > 0 and site:GetAttribute("ChamberOpen") then
			task.defer(deliverPending, p)
		end
	end
	-- DataLoaded only: receipt grants are delivered explicitly by ProcessReceipt
	-- after the entitlement has been saved, so an unsaved purchase cannot leak
	-- into transient chamber state.
	p:GetAttributeChangedSignal("DataLoaded"):Connect(tryDeliver)
	tryDeliver()
end

Players.PlayerAdded:Connect(watchPlayer)
for _, p in Players:GetPlayers() do
	watchPlayer(p)
end
Players.PlayerRemoving:Connect(function(p)
	delivering[p] = nil
end)
