local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local C = require(RS:WaitForChild("PyramidHUD"):WaitForChild("Config"))

local COLUMNS = { C.Stats.Pyramids, "Blocks", C.Stats.Speed, C.Stats.Strength }

local function onJoin(p)
	if p:GetAttribute("Blocks") == nil then
		p:SetAttribute("Blocks", 0)
	end
	local stats = p:FindFirstChild("leaderstats") or Instance.new("Folder")
	stats.Name = "leaderstats"
	for _, key in COLUMNS do
		local v = stats:FindFirstChild(key) or Instance.new("NumberValue")
		v.Name = key
		v.Value = math.floor(tonumber(p:GetAttribute(key)) or 0)
		v.Parent = stats
		p:GetAttributeChangedSignal(key):Connect(function()
			v.Value = math.floor(tonumber(p:GetAttribute(key)) or 0)
		end)
	end
	stats.Parent = p
end

Players.PlayerAdded:Connect(onJoin)
for _, p in Players:GetPlayers() do
	task.spawn(onJoin, p)
end
