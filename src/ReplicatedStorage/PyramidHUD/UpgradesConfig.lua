local U = {}

U.Coins = { 100, 350, 1200, 6600, 25000, 90000, 300000, 900000, 2500000 }
U.Robux = { 9, 19, 40, 79, 129, 199, 299, 449, 699 }
U.MaxLevel = #U.Coins + 1

U.List = {
	{
		Id = "BulkPickup",
		Title = "Bulk Pickup",
		Level = "UpgradeBulkPickup",
		Value = "BlocksPerGrab",
		Effect = function(level)
			return level
		end,
		Describe = function(value)
			return value .. (value == 1 and " Block" or " Blocks") .. " Per Grab"
		end,
		Icon = "Stack",
		Color = Color3.fromRGB(214, 150, 70),
		ProductIds = { 3715504899, 3715504901, 3715504905, 3715504910, 3715504911, 3715504913, 3715504917, 3715504922, 3715504926 },
	},
	{
		Id = "BulkPlace",
		Title = "Bulk Place",
		Level = "UpgradeBulkPlace",
		Value = "BlocksPerPlace",
		Effect = function(level)
			return level
		end,
		Describe = function(value)
			return value .. (value == 1 and " Block" or " Blocks") .. " Per Place"
		end,
		Icon = "Block",
		Color = Color3.fromRGB(214, 150, 70),
		ProductIds = { 3715504929, 3715504935, 3715504936, 3715504941, 3715504943, 3715504946, 3715504947, 3715504951, 3715504955 },
	},
	{
		Id = "PlaceRange",
		Title = "Placement Range",
		Level = "UpgradePlaceRange",
		Value = "PlaceRangeBonus",
		Effect = function(level)
			return (level - 1) * 15
		end,
		Describe = function(value)
			return "+" .. value .. "% Place Range"
		end,
		Icon = "Range",
		Color = Color3.fromRGB(70, 150, 235),
		ProductIds = { 3715504958, 3715504959, 3715504966, 3715504968, 3715504970, 3715504974, 3715504976, 3715504977, 3715504980 },
	},
}

function U.get(id)
	for _, u in U.List do
		if u.Id == id then
			return u
		end
	end
end

return U
