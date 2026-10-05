local R = {}

R.Ranks = {
	{ "SAND SWEEPER", 0 },
	{ "WATER BEARER", 1 },
	{ "ROPE PULLER", 2 },
	{ "BRICK HAULER", 3 },
	{ "STONE CARRIER", 4 },
	{ "BLOCK PUSHER", 5 },
	{ "RAMP BUILDER", 6 },
	{ "APPRENTICE MASON", 7 },
	{ "MASON", 8 },
	{ "SENIOR MASON", 9 },
	{ "CHIEF MASON", 10 },
	{ "STONE CUTTER", 12 },
	{ "MASTER CUTTER", 14 },
	{ "QUARRY FOREMAN", 16 },
	{ "SITE OVERSEER", 18 },
	{ "CREW LEADER", 20 },
	{ "MASTER BUILDER", 23 },
	{ "SURVEYOR", 26 },
	{ "SCRIBE", 30 },
	{ "ROYAL SCRIBE", 34 },
	{ "ARCHITECT", 38 },
	{ "SENIOR ARCHITECT", 43 },
	{ "ROYAL ARCHITECT", 48 },
	{ "GRAND ARCHITECT", 54 },
	{ "PRIEST OF PTAH", 60 },
	{ "HIGH PRIEST", 67 },
	{ "VIZIER'S AIDE", 75 },
	{ "VIZIER", 84 },
	{ "GRAND VIZIER", 94 },
	{ "NOMARCH", 105 },
	{ "GOVERNOR", 117 },
	{ "ROYAL TREASURER", 130 },
	{ "KEEPER OF THE SEAL", 145 },
	{ "GENERAL", 160 },
	{ "COMMANDER", 180 },
	{ "PRINCE", 200 },
	{ "CROWN PRINCE", 225 },
	{ "CO-REGENT", 250 },
	{ "PHARAOH", 280 },
	{ "GREAT PHARAOH", 315 },
	{ "LORD OF TWO LANDS", 355 },
	{ "SON OF RA", 400 },
	{ "EYE OF HORUS", 450 },
	{ "CHOSEN OF OSIRIS", 510 },
	{ "LIVING SPHINX", 580 },
	{ "STAR OF THE NILE", 660 },
	{ "SUN KING", 750 },
	{ "DIVINE PHARAOH", 850 },
	{ "IMMORTAL PHARAOH", 1000 },
	{ "GOD OF PYRAMIDS", 1200 },
}

local rgb = Color3.fromRGB
R.Groups = {
	{ Colors = { rgb(255, 240, 200), rgb(222, 178, 108) }, Ink = rgb(70, 44, 16) },
	{ Colors = { rgb(190, 255, 120), rgb(40, 200, 70) }, Ink = rgb(12, 60, 20) },
	{ Colors = { rgb(120, 140, 255), rgb(92, 48, 255) }, Ink = rgb(22, 14, 70) },
	{ Colors = { rgb(150, 245, 255), rgb(0, 160, 255) }, Ink = rgb(0, 44, 84) },
	{ Colors = { rgb(255, 160, 235), rgb(220, 40, 190) }, Ink = rgb(70, 8, 60) },
	{ Colors = { rgb(255, 150, 120), rgb(220, 30, 40) }, Ink = rgb(70, 8, 10) },
	{ Colors = { rgb(255, 240, 120), rgb(255, 150, 0) }, Ink = rgb(84, 40, 0) },
	{ Colors = { rgb(210, 150, 255), rgb(140, 60, 255), rgb(255, 200, 60) }, Ink = rgb(40, 10, 70) },
	{ Colors = { rgb(255, 245, 130), rgb(255, 120, 0), rgb(210, 20, 20) }, Ink = rgb(70, 10, 0) },
	{
		Colors = { rgb(255, 96, 110), rgb(255, 186, 60), rgb(255, 240, 90), rgb(110, 235, 120), rgb(80, 200, 255), rgb(160, 120, 255), rgb(255, 120, 210) },
		Ink = rgb(34, 22, 52),
		Horizontal = true,
	},
}

function R.index(pyramids)
	pyramids = tonumber(pyramids) or 0
	local found = 1
	for i, r in R.Ranks do
		if pyramids >= r[2] then
			found = i
		else
			break
		end
	end
	return found
end

function R.style(index)
	return R.Groups[math.clamp(math.floor((index - 1) / 5) + 1, 1, #R.Groups)]
end

function R.sequence(style)
	local keys = {}
	local n = #style.Colors
	for i, c in style.Colors do
		table.insert(keys, ColorSequenceKeypoint.new(n == 1 and 0 or (i - 1) / (n - 1), c))
	end
	if n == 1 then
		table.insert(keys, ColorSequenceKeypoint.new(1, style.Colors[1]))
	end
	return ColorSequence.new(keys)
end

return R
