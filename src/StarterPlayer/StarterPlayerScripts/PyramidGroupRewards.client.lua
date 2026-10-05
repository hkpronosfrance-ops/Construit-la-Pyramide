local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local GroupService = game:GetService("GroupService")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local folder = RS:WaitForChild("PyramidHUD")
local C = require(folder:WaitForChild("Config"))
local T = require(folder:WaitForChild("Theme"))
local remote = folder:WaitForChild("GroupReward")
local G = C.GroupReward

local rgb = Color3.fromRGB

local state = { joined = false, claimed = false, verifiable = G.GroupId > 0 }

local gui = player:WaitForChild("PlayerGui"):WaitForChild("GroupRewards")
local backdrop = gui:WaitForChild("Backdrop")
local panel = gui:WaitForChild("FreeRewards")
panel.Visible = false
backdrop.Visible = false
T.adoptWindow(panel)
local close = panel:WaitForChild("Header"):WaitForChild("Close")
local likeBtn = panel:WaitForChild("Like")
local joinBtn = panel:WaitForChild("Join")
local claim = panel:WaitForChild("Claim")
local hint = panel:WaitForChild("Hint")
local amount = panel:WaitForChild("Prize"):WaitForChild("Amount")

local function attrOr(name, fallback)
	local v = claim:GetAttribute(name)
	if v == nil then
		return fallback
	end
	return v
end

local function comma(n)
	local s = tostring(math.floor(n))
	repeat
		local k
		s, k = s:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
	until k == 0
	return s
end
local format = amount:GetAttribute("Format")
amount.Text = (type(format) == "string" and format or "+%s Coins!"):format(comma(G.Coins))

local busy = false
local function paint()
	if state.claimed then
		claim.Text = attrOr("ClaimedText", "Claimed")
		T.gradient(claim, attrOr("LockedColor", rgb(104, 122, 152)))
	elseif state.joined then
		claim.Text = attrOr("ClaimText", "Claim")
		T.gradient(claim, attrOr("ReadyColor", rgb(46, 214, 46)))
	else
		claim.Text = attrOr("LockedText", "Locked")
		T.gradient(claim, attrOr("LockedColor", rgb(104, 122, 152)))
	end
end

local token = 0
local function promptJoin()
	if state.joined or not state.verifiable or busy then
		return
	end
	busy = true
	local mine = token
	pcall(function()
		GroupService:PromptJoinAsync(G.GroupId)
	end)
	busy = false
	if mine == token then
		remote:FireServer("get")
	end
end

local function open(value)
	token += 1
	panel.Visible = value
	backdrop.Visible = value
	gui:SetAttribute("Open", value)
	if value then
		hint.Text = ""
		remote:FireServer("get")
		task.spawn(function()
			local ok, member = pcall(function()
				return player:IsInGroupAsync(G.GroupId)
			end)
			if not ok then
				ok, member = pcall(player.IsInGroup, player, G.GroupId)
			end
			if panel.Visible and not (ok and member) then
				promptJoin()
			end
		end)
	end
end

close.Activated:Connect(function()
	open(false)
end)
UIS.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == Enum.KeyCode.Escape and panel.Visible then
		open(false)
	end
end)
likeBtn.Activated:Connect(function()
	hint.Text = "Press the thumbs up on the game page to like the game!"
end)
joinBtn.Activated:Connect(promptJoin)
claim.Activated:Connect(function()
	if state.claimed then
		hint.Text = "You already claimed this reward."
	elseif not state.joined then
		hint.Text = "Join our group first!"
		promptJoin()
	else
		remote:FireServer("claim")
	end
end)

remote.OnClientEvent:Connect(function(kind, data)
	if kind == "state" and type(data) == "table" then
		state.joined = data.joined == true
		state.claimed = data.claimed == true
		state.verifiable = data.verifiable == true
		paint()
	elseif kind == "granted" then
		claim.Text = attrOr("ThanksText", "Thank You!")
		hint.Text = "+" .. comma(tonumber(data) or G.Coins) .. " coins!"
	elseif kind == "denied" then
		hint.Text = tostring(data)
	end
end)
paint()

local hooked = setmetatable({}, { __mode = "k" })
local function hook(pp)
	if pp:IsA("ProximityPrompt") and not hooked[pp] then
		hooked[pp] = true
		pp.Triggered:Connect(function()
			open(true)
		end)
	end
end
task.spawn(function()
	local map = workspace:WaitForChild("PyramidMap", 60)
	local sign = map and map:WaitForChild("FreeGiftSign", 60)
	if sign then
		sign.DescendantAdded:Connect(hook)
		for _, d in sign:GetDescendants() do
			hook(d)
		end
	end
end)
