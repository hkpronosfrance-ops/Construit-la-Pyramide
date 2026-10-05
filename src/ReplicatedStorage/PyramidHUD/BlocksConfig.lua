local B = {}

B.Mine = { Center = Vector3.new(248, -14, -40), Radius = 60, MaxY = 6 }

B.PickupCooldown = 0.25

function B.capacity(strength)
	return math.floor(18.3 + 0.472 * math.sqrt(math.max(0, tonumber(strength) or 0)))
end

B.Color = Color3.fromRGB(196, 196, 202)
B.Material = Enum.Material.Concrete

B.Visual = {
	Slots = 6,
	Floors = 10,
	PerFloor = 150,
	Small = 2.6,
	FullSize = 5,
	Max = 6.5,
}

B.Pile = {
	Seed = 20260928,
	Spacing = 3.4,
	Size = { 2.6, 3.4 },
	Layers = { { Radius = 56, Y = -0.5 }, { Radius = 54, Y = 1 } },
	Depth = 12,
	Thin = 0.08,
	Filler = { Radius = 58.5, Color = Color3.fromRGB(128, 128, 134) },
	FillFromRemaining = true,
	Shade = { 184, 206 },
	Fly = 3,
}

B.Throw = { Speed = 42, Lift = 26, Life = 1.3, MinSize = 2.6, MaxSize = 14 }

B.Drop = { Push = 6, Lift = 8, Life = 2.5 }

return B
