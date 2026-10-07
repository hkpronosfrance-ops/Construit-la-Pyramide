local M = {}

function M.IsReady(player)
	return player ~= nil
		and player.Parent ~= nil
		and player:GetAttribute("DataLoaded") == true
		and player:GetAttribute("DataSessionLost") ~= true
end

return M
