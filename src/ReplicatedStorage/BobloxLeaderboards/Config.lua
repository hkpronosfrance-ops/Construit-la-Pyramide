return {
	MapName = "PyramidMap",
	StorePrefix = "BuildThePyramid_LB_v1_",
	Keys = { "Strength", "Speed", "Coins", "Pyramids", "Blocks" },
	Format = function(_, n)
		if n < 1000 then
			return tostring(n)
		end
		local u = { "K", "M", "B", "T", "Qa", "Qi" }
		local i, v = 0, n
		while v >= 1000 and i < #u do
			v /= 1000
			i += 1
		end
		local d = n >= 1e5 and 2 or 1
		v = math.floor(v * 10 ^ d) / 10 ^ d
		return (string.format("%." .. d .. "f", v):gsub("%.?0+$", "")) .. u[i]
	end,
}
