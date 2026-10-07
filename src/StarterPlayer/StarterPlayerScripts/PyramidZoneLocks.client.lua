-- Cache le cadenas des plaques de zone du GYM dès que le joueur a débloqué la zone.
-- Même règle que PyramidTrainingClient : attribut Unlocked_<zone>, zone payante, ou pyramides requises.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local C = require(ReplicatedStorage:WaitForChild("PyramidHUD"):WaitForChild("Config"))

local player = Players.LocalPlayer
local gym = workspace:WaitForChild("PyramidMap"):WaitForChild("Gym")
local pads = gym:WaitForChild("Pads")
local decor = gym:WaitForChild("GymDecor", 30)
local plaques = decor and decor:WaitForChild("ZonePlaques", 30)
if not plaques then
	return
end

local function unlocked(zone)
	if player:GetAttribute("Unlocked_" .. zone.Name) then
		return true
	end
	if zone:GetAttribute("Paid") then
		return player:GetAttribute("IsAdmin") == true or RunService:IsStudio()
	end
	return (player:GetAttribute(C.Stats.Pyramids) or 0) >= (zone:GetAttribute("RequiredPyramids") or 0)
end

while true do
	for _, plaque in plaques:GetChildren() do
		local lock = plaque:FindFirstChild("Lock")
		local zone = pads:FindFirstChild(plaque.Name)
		if lock and zone then
			local hidden = unlocked(zone) and 1 or 0
			for _, part in lock:GetDescendants() do
				if part:IsA("BasePart") then
					-- modifié côté client uniquement : les autres joueurs voient leur propre état
					part.Transparency = hidden
				end
			end
		end
	end
	task.wait(0.5)
end