local RS = game:GetService("ReplicatedStorage")
local folder = RS:WaitForChild("BobloxSettings")

local remote = folder:FindFirstChild("Remote")
if not remote then
	remote = Instance.new("RemoteEvent")
	remote.Name = "Remote"
	remote.Parent = folder
end

require(script.Parent.BobloxSettingsService).Start(folder)
