local L = {}

local function pillars(list, size, room)
	local out = {}
	for _, p in list do
		table.insert(out, { kind = "pillar", x = p[1], z = p[2], size = size, room = room })
	end
	return out
end
local function add(t, list)
	for _, v in list do
		table.insert(t, v)
	end
	return t
end

L.Standard = {
	Palette = { Wall = Color3.fromRGB(70, 82, 100), Floor = Color3.fromRGB(58, 68, 84), Trim = Color3.fromRGB(88, 102, 124),
		Water = Color3.fromRGB(95, 230, 240), Light = Color3.fromRGB(120, 225, 255) },
	Boxes = {
		{ name = "Tunnel", x0 = 64, x1 = "face", z0 = -4, z1 = 4, y1 = 12, gable = 3, open = "+x" },
		{ name = "Ante", x0 = 40, x1 = 64, z0 = -14, z1 = 14, y1 = 15 },
		{ name = "Door", x0 = 34, x1 = 42, z0 = -6, z1 = 6, y1 = 12 },
		{ name = "Hall", x0 = -56, x1 = 36, z0 = -40, z1 = 40, y1 = 27 },
	},
	Features = add({
		{ kind = "pool", x0 = -50, x1 = 30, z0 = -32, z1 = 32 },
	}, pillars({ { -51, -35 }, { -51, 35 }, { 31, -35 }, { 31, 35 } }, 7, "Hall")),
	Sign = { x = 44, y = 13, z = 0 },
	Lights = { { -30, 22, -24 }, { 10, 22, -24 }, { -30, 22, 24 }, { 10, 22, 24 }, { 52, 12, 0 }, { 90, 9, 0 }, { 125, 9, 0 } },
}

L.Great = {
	Palette = { Wall = Color3.fromRGB(196, 150, 104), Floor = Color3.fromRGB(170, 126, 86), Trim = Color3.fromRGB(214, 172, 124),
		Water = Color3.fromRGB(80, 200, 205), Light = Color3.fromRGB(255, 176, 100) },
	Boxes = {
		{ name = "Tunnel", x0 = 86, x1 = "face", z0 = -4, z1 = 4, y1 = 13, gable = 4, open = "+x" },
		{ name = "Ante", x0 = 52, x1 = 86, z0 = -18, z1 = 18, y1 = 16 },
		{ name = "Door", x0 = 42, x1 = 54, z0 = -6, z1 = 6, y1 = 13 },
		{ name = "Hall", x0 = -50, x1 = 44, z0 = -44, z1 = 44, y1 = 28 },
	},
	Features = add({
		{ kind = "platform", x0 = 62, x1 = 76, z0 = -7, z1 = 7, h = 1.6 },
		{ kind = "pool", x0 = -44, x1 = 38, z0 = -34, z1 = 34 },
		{ kind = "slab", x0 = -44, x1 = 38, z0 = -2.5, z1 = 2.5, h = "deck" },
		{ kind = "slab", x0 = -5, x1 = -1, z0 = -34, z1 = 34, h = "deck" },
	}, pillars({ { -38, -40 }, { -14, -40 }, { 10, -40 }, { 32, -40 }, { -38, 40 }, { -14, 40 }, { 10, 40 }, { 32, 40 } }, 6, "Hall")),
	Sign = { x = 56, y = 14, z = 0 },
	Lights = { { -24, 23, -28 }, { 18, 23, -28 }, { -24, 23, 28 }, { 18, 23, 28 }, { 69, 13, 0 }, { 110, 10, 0 }, { 145, 10, 0 } },
}

L.Giant = {
	Palette = { Wall = Color3.fromRGB(214, 170, 96), Floor = Color3.fromRGB(186, 142, 76), Trim = Color3.fromRGB(232, 194, 120),
		Water = Color3.fromRGB(90, 215, 220), Light = Color3.fromRGB(255, 196, 110) },
	Boxes = {
		{ name = "Tunnel", x0 = 150, x1 = "face", z0 = -4, z1 = 4, y1 = 12, gable = 3, open = "+x" },
		{ name = "Gallery", x0 = 100, x1 = 150, z0 = -6, z1 = 6, y1 = 24, gable = 6 },
		{ name = "Ante", x0 = 66, x1 = 100, z0 = -20, z1 = 20, y1 = 18 },
		{ name = "NicheN", x0 = 78, x1 = 88, z0 = 19, z1 = 26, y1 = 12 },
		{ name = "NicheS", x0 = 78, x1 = 88, z0 = -26, z1 = -19, y1 = 12 },
		{ name = "Door", x0 = 56, x1 = 68, z0 = -7, z1 = 7, y1 = 14 },
		{ name = "Hall", x0 = -56, x1 = 58, z0 = -50, z1 = 50, y1 = 30 },
	},
	Features = add({
		{ kind = "platform", x0 = 76, x1 = 90, z0 = -8, z1 = 8, h = 2 },
		{ kind = "pool", x0 = -46, x1 = 48, z0 = -40, z1 = 40 },
	}, pillars({ { -51, -45 }, { -51, 45 }, { 53, -45 }, { 53, 45 }, { 1, -46 }, { 1, 46 }, { -51, 0 } }, 7, "Hall")),
	Sign = { x = 70, y = 15, z = 0 },
	Lights = { { -20, 25, -30 }, { 22, 25, -30 }, { -20, 25, 30 }, { 22, 25, 30 }, { 83, 15, 0 }, { 125, 18, 0 }, { 170, 9, 0 } },
}

L.Colossal = {
	Palette = { Wall = Color3.fromRGB(196, 214, 228), Floor = Color3.fromRGB(160, 180, 198), Trim = Color3.fromRGB(222, 236, 246),
		Water = Color3.fromRGB(110, 235, 250), Light = Color3.fromRGB(190, 235, 255) },
	Boxes = {
		{ name = "Tunnel", x0 = 170, x1 = "face", z0 = -5, z1 = 5, y1 = 14, gable = 4, open = "+x" },
		{ name = "Ante", x0 = 128, x1 = 170, z0 = -22, z1 = 22, y1 = 20 },
		{ name = "Door", x0 = 112, x1 = 130, z0 = -8, z1 = 8, y1 = 16 },
		{ name = "Hall", x0 = -60, x1 = 114, z0 = -56, z1 = 56, y1 = 34 },
	},
	Features = add(add({
		{ kind = "platform", x0 = 140, x1 = 158, z0 = -9, z1 = 9, h = 2 },
		{ kind = "platform", x0 = -56, x1 = -30, z0 = -24, z1 = 24, h = 4.4 },
		{ kind = "platform", x0 = -30, x1 = -26, z0 = -24, z1 = 24, h = 3.8 },
		{ kind = "pool", x0 = -20, x1 = 100, z0 = -44, z1 = 44 },
	}, pillars({ { 134, -16 }, { 134, 16 }, { 164, -16 }, { 164, 16 } }, 4, "Ante")),
		pillars({ { -40, -51 }, { 0, -51 }, { 40, -51 }, { 80, -51 }, { -40, 51 }, { 0, 51 }, { 40, 51 }, { 80, 51 } }, 7, "Hall")),
	Sign = { x = 132, y = 17, z = 0 },
	Lights = { { 0, 29, -36 }, { 60, 29, -36 }, { 0, 29, 36 }, { 60, 29, 36 }, { -43, 29, 0 }, { 149, 16, 0 }, { 192, 11, 0 } },
}

return L
