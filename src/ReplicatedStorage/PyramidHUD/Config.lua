local C = {}

C.Icons = {
	Speed = "rbxassetid://133205424214665",
	Strength = "rbxassetid://126939253803851",
}

C.FriendBoostPerFriend = 10
C.FriendBoostMax = 50
C.PyramidMinContribution = 100

C.Boosts = {
	{
		Id = "Speed",
		Title = "1.5x Speed",
		Factor = 1.5,
		Level = "SpeedBoosts",
		Multiplier = "SpeedMultiplier",
		Icon = C.Icons.Speed,
		Rim = Color3.fromRGB(24, 86, 190),
		Top = Color3.fromRGB(150, 225, 255),
		Bottom = Color3.fromRGB(40, 140, 255),
		Tiers = {
			{ Price = 3, ProductId = 3715499933 },
			{ Price = 9, ProductId = 3715499934 },
			{ Price = 19, ProductId = 3715499937 },
			{ Price = 39, ProductId = 3715499939 },
			{ Price = 79, ProductId = 3715499941 },
			{ Price = 149, ProductId = 3715499943 },
			{ Price = 299, ProductId = 3715499945 },
		},
	},
	{
		Id = "Strength",
		Title = "1.6x Strength",
		Factor = 1.6,
		Level = "StrengthBoosts",
		Multiplier = "StrengthMultiplier",
		Icon = C.Icons.Strength,
		Rim = Color3.fromRGB(190, 84, 8),
		Top = Color3.fromRGB(255, 236, 110),
		Bottom = Color3.fromRGB(255, 140, 20),
		Tiers = {
			{ Price = 5, ProductId = 3715499951 },
			{ Price = 15, ProductId = 3715499953 },
			{ Price = 29, ProductId = 3715499956 },
			{ Price = 59, ProductId = 3715499959 },
			{ Price = 119, ProductId = 3715499961 },
			{ Price = 249, ProductId = 3715499966 },
			{ Price = 499, ProductId = 3715499968 },
		},
	},
}

function C.boost(id)
	for _, b in C.Boosts do
		if b.Id == id then
			return b
		end
	end
end

function C.boostLevel(boost, level)
	return math.clamp(math.floor(tonumber(level) or 0), 0, #boost.Tiers)
end

function C.nextTier(boost, level)
	local current = C.boostLevel(boost, level)
	if current >= #boost.Tiers then
		return nil
	end
	return boost.Tiers[current + 1]
end

function C.multiplier(boost, level)
	return boost.Factor ^ C.boostLevel(boost, level)
end

C.PyramidFill = {
	{ Amount = 1000, Price = 49, ProductId = 3715499743, Rim = Color3.fromRGB(40, 150, 10), Top = Color3.fromRGB(207, 255, 57), Bottom = Color3.fromRGB(45, 231, 24) },
	{ Amount = 5000, Price = 129, ProductId = 3715499747, Rim = Color3.fromRGB(180, 80, 0), Top = Color3.fromRGB(255, 220, 90), Bottom = Color3.fromRGB(255, 130, 10) },
	{ Amount = 10000, Price = 249, ProductId = 3715499750, Rim = Color3.fromRGB(150, 16, 16), Top = Color3.fromRGB(255, 130, 110), Bottom = Color3.fromRGB(235, 35, 35) },
	{ Amount = 50000, Price = 699, ProductId = 3715499751, Rim = Color3.fromRGB(90, 20, 180), Top = Color3.fromRGB(247, 139, 255), Bottom = Color3.fromRGB(151, 53, 255) },
}

C.Chamber = {
	Minutes = 3,
	MaxMinutes = 60,
	Offers = {
		{ Minutes = 1, Price = 49, ProductId = 3715452094 },
		{ Minutes = 5, Price = 129, ProductId = 3715452098 },
		{ Minutes = 10, Price = 249, ProductId = 3715452102 },
		{ Minutes = 50, Price = 699, ProductId = 3715452107 },
	},
}

C.Pharaoh = { GamePassId = 2001986456, Price = 149, Pyramids = 2 }

C.GroupReward = { GroupId = game.CreatorType == Enum.CreatorType.Group and game.CreatorId or 0, Coins = 1000, Icon = "rbxassetid://102217164765801", Arrow = "rbxassetid://83205092246605" }

C.Training = {
	BenchInterval = 1,
	TreadInterval = 1,
	BaseStrength = 1,
	BaseSpeed = 1,
	WalkSpeed = function(speed)
		return math.floor(16 + 1.1035 * math.max(0, speed) ^ 0.435 + 0.5)
	end,
	RepSpeed = function(mult)
		return 1 + 0.3 * math.log(math.max(1, mult), 2)
	end,
	RunAnimSpeed = function(mult)
		return math.min(3.2, 1.1 + 0.25 * math.log(math.max(1, mult), 2))
	end,
}

C.ZoneUnlock = {
	Region_2x = { Price = 29, ProductId = 3715399402 },
	Region_5x = { Price = 59, ProductId = 3715399405 },
	Region_10x = { Price = 99, ProductId = 3715399407 },
	Region_25x = { Price = 199, ProductId = 3715399409 },
	Region_50x = { Price = 399, ProductId = 3715399411 },
	Region_75x = { Price = 699, ProductId = 3715399415 },
	Region_100x = { Price = 999, ProductId = 3715399416 },
	Region_ADMIN = { Price = 1499, GamePassId = 1999197559 },
}

C.PyramidTotal = 171700

C.Keys = {
	{ Action = "PickUp", Text = "Pick Up", Keyboard = Enum.KeyCode.E, Gamepad = Enum.KeyCode.ButtonX, PadLabel = "X", PadColour = Color3.fromRGB(40, 120, 255) },
	{ Action = "Drop", Text = "Drop", Keyboard = Enum.KeyCode.Q, Gamepad = Enum.KeyCode.ButtonY, PadLabel = "Y", PadColour = Color3.fromRGB(255, 190, 20) },
}

C.Stats = {
	Coins = "Coins",
	Speed = "Speed",
	Strength = "Strength",
	Pyramids = "Pyramids",
	Carrying = "Carrying",
	Capacity = "Capacity",
	FriendBoost = "FriendBoost",
}

return C
