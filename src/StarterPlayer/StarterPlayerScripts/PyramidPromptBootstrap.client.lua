local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local function menuOpen()
	if player:GetAttribute("BenchLocal") or player:GetAttribute("Training") then
		return true
	end
	for _, g in PlayerGui:GetChildren() do
		if g:IsA("ScreenGui") and g:GetAttribute("Open") == true then
			return true
		end
	end
	return false
end

require(RS:WaitForChild("CustomPrompt")).start({ MenuOpen = menuOpen, MaxCameraDistance = 100 })
