local M = {}
M.Texture = "rbxassetid://127971212433825"
M.TileSize = 6
function M.Apply(part)
	part.Material = Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	for _, face in Enum.NormalId:GetEnumItems() do
		local name = "Sandstone_" .. face.Name
		local tex = part:FindFirstChild(name)
		if not tex then
			tex = Instance.new("Texture")
			tex.Name = name
			tex.Face = face
			tex.Texture = M.Texture
			tex.StudsPerTileU = M.TileSize
			tex.StudsPerTileV = M.TileSize
			tex.Transparency = 0.12
			tex.Parent = part
		end
		tex.Color3 = part.Color
	end
end
return M
