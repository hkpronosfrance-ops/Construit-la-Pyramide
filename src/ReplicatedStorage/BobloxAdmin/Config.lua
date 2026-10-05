local function owners()
	if game.CreatorType == Enum.CreatorType.User then
		return { game.CreatorId }
	end
	local ok, info = pcall(function()
		return game:GetService("GroupService"):GetGroupInfoAsync(game.CreatorId)
	end)
	return (ok and info and info.Owner) and { info.Owner.Id } or {}
end

return {
	UserIds = owners(),
	GroupId = game.CreatorType == Enum.CreatorType.Group and game.CreatorId or 0,
	MinRank = 255,
	StudioAlwaysAdmin = true,
	Confirm = false,
	CloseOnBackdrop = false,
	Prefix = "/admin",
	Theme = game.ReplicatedStorage.PyramidHUD.Theme,
	StorePrefix = "BuildThePyramid_Admin_v1",
}
