local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalizationService = game:GetService("LocalizationService")
local UIS = game:GetService("UserInputService")
local PPS = game:GetService("ProximityPromptService")

local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local T = require(RS:WaitForChild("PyramidHUD"):WaitForChild("Theme"))

local isFrench = RunService:IsStudio()
if not isFrench then
	local ok, locale = pcall(function()
		return LocalizationService.RobloxLocaleId
	end)
	isFrench = ok and type(locale) == "string" and locale:lower():sub(1, 2) == "fr"
end

local rgb = Color3.fromRGB
local BLUE = rgb(88, 101, 242)
local DARK = rgb(30, 33, 42)
local WHITE = Color3.new(1, 1, 1)

local old = pg:FindFirstChild("DiscordInvite")
if old then
	old:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "DiscordInvite"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 80
gui:SetAttribute("Open", false)
gui.Parent = pg

local backdrop = Instance.new("TextButton")
backdrop.Name = "Backdrop"
backdrop.Text = ""
backdrop.AutoButtonColor = false
backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
backdrop.BackgroundTransparency = 0.42
backdrop.BorderSizePixel = 0
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.Visible = false
backdrop.ZIndex = 1
backdrop.Parent = gui

local panel = Instance.new("Frame")
panel.Name = "DiscordPanel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(590, 410)
panel.BackgroundColor3 = DARK
panel.BorderSizePixel = 0
panel.Visible = false
panel.ZIndex = 2
panel.Parent = gui

local scale = Instance.new("UIScale")
scale.Scale = 1
scale.Parent = panel

local header = Instance.new("Frame")
header.Name = "Header"
header.BackgroundColor3 = BLUE
header.BorderSizePixel = 0
header.Size = UDim2.new(1, 0, 0, 78)
header.ZIndex = 3
header.Parent = panel

local title = Instance.new("TextLabel")
title.Name = "Title"
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(76, 8)
title.Size = UDim2.new(1, -150, 1, -16)
title.Font = Enum.Font.FredokaOne
title.Text = "Discord"
title.TextColor3 = WHITE
title.TextScaled = true
title.TextStrokeColor3 = rgb(8, 16, 32)
title.TextStrokeTransparency = 0
title.ZIndex = 5
title.Parent = header

local titleLimit = Instance.new("UITextSizeConstraint")
titleLimit.MinTextSize = 20
titleLimit.MaxTextSize = 42
titleLimit.Parent = title

local icon = Instance.new("TextLabel")
icon.Name = "Icon"
icon.BackgroundTransparency = 1
icon.Position = UDim2.fromOffset(14, 7)
icon.Size = UDim2.fromOffset(62, 62)
icon.Font = Enum.Font.FredokaOne
icon.Text = "💬"
icon.TextSize = 45
icon.TextColor3 = WHITE
icon.ZIndex = 5
icon.Parent = header

local close = Instance.new("TextButton")
close.Name = "Close"
close.AnchorPoint = Vector2.new(1, 0.5)
close.Position = UDim2.new(1, -12, 0.5, 0)
close.Size = UDim2.fromOffset(50, 50)
close.BackgroundColor3 = rgb(226, 41, 41)
close.Text = "×"
close.TextColor3 = WHITE
close.TextSize = 34
close.Font = Enum.Font.GothamBlack
close.ZIndex = 6
close.Parent = header

local bodyTitle = Instance.new("TextLabel")
bodyTitle.Name = "BodyTitle"
bodyTitle.BackgroundTransparency = 1
bodyTitle.Position = UDim2.fromOffset(34, 105)
bodyTitle.Size = UDim2.new(1, -68, 0, 54)
bodyTitle.Font = Enum.Font.FredokaOne
bodyTitle.Text = isFrench and "REJOINS NOTRE DISCORD !" or "JOIN OUR DISCORD!"
bodyTitle.TextColor3 = WHITE
bodyTitle.TextSize = 32
bodyTitle.TextWrapped = true
bodyTitle.TextStrokeColor3 = rgb(8, 16, 32)
bodyTitle.TextStrokeTransparency = 0
bodyTitle.ZIndex = 4
bodyTitle.Parent = panel

local body = Instance.new("TextLabel")
body.Name = "Body"
body.BackgroundTransparency = 1
body.Position = UDim2.fromOffset(45, 170)
body.Size = UDim2.new(1, -90, 0, 108)
body.Font = Enum.Font.GothamBold
body.Text = isFrench
	and "Retrouve les actualités, les événements, les codes et la communauté du jeu sur notre serveur Discord."
	or "Find game news, events, codes and the community on our Discord server."
body.TextColor3 = rgb(235, 238, 245)
body.TextSize = 21
body.TextWrapped = true
body.TextXAlignment = Enum.TextXAlignment.Center
body.TextYAlignment = Enum.TextYAlignment.Center
body.ZIndex = 4
body.Parent = panel

local note = Instance.new("TextLabel")
note.Name = "Note"
note.BackgroundTransparency = 1
note.Position = UDim2.fromOffset(45, 275)
note.Size = UDim2.new(1, -90, 0, 44)
note.Font = Enum.Font.Gotham
note.Text = isFrench
	and "Le lien officiel est disponible dans les liens sociaux de la page du jeu."
	or "The official link is available in the game's social links."
note.TextColor3 = rgb(170, 178, 195)
note.TextSize = 15
note.TextWrapped = true
note.ZIndex = 4
note.Parent = panel

local okButton = Instance.new("TextButton")
okButton.Name = "Ok"
okButton.AnchorPoint = Vector2.new(0.5, 0)
okButton.Position = UDim2.new(0.5, 0, 0, 330)
okButton.Size = UDim2.fromOffset(330, 58)
okButton.BackgroundColor3 = BLUE
okButton.Text = isFrench and "COMPRIS !" or "GOT IT!"
okButton.TextColor3 = WHITE
okButton.TextSize = 24
okButton.Font = Enum.Font.FredokaOne
okButton.ZIndex = 5
okButton.Parent = panel

T.round(panel, 15, rgb(18, 20, 28), 3)
T.gradient(panel, DARK)
T.round(header, 12, rgb(8, 16, 32), 3)
T.gradient(header, BLUE)
T.round(close, 8, rgb(8, 16, 32), 2)
T.gradient(close, rgb(226, 41, 41))
T.round(okButton, 10, rgb(8, 16, 32), 3)
T.gradient(okButton, BLUE)
T.react(close)
T.react(okButton)

local function updateScale()
	local camera = workspace.CurrentCamera
	if not camera then return end
	local v = camera.ViewportSize
	scale.Scale = math.min(1, (v.X - 30) / 590, (v.Y - 50) / 410)
end
updateScale()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)

local function open(value)
	panel.Visible = value
	backdrop.Visible = value
	gui:SetAttribute("Open", value)
end

close.Activated:Connect(function()
	open(false)
end)
okButton.Activated:Connect(function()
	open(false)
end)
backdrop.Activated:Connect(function()
	open(false)
end)
UIS.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == Enum.KeyCode.Escape and panel.Visible then
		open(false)
	end
end)

local hooked = setmetatable({}, { __mode = "k" })
local discordParts = setmetatable({}, { __mode = "k" })

local function partForDiscordText(textObject)
	local node = textObject
	while node and node ~= workspace do
		if node:IsA("BasePart") then
			return node
		end
		node = node.Parent
	end
	return nil
end

local function isDiscordText(obj)
	if not (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")) then
		return false
	end
	return string.upper((obj.Text or ""):gsub("%s+", "")) == "DISCORD"
end

local function signScopeFor(part)
	local node = part
	while node and node.Parent and node.Parent ~= workspace do
		if node:IsA("Model") then
			return node
		end
		if node.Parent and node.Parent:IsA("Model") then
			return node.Parent
		end
		node = node.Parent
	end
	return part
end


local function hookDiscordText(obj)
	if not isDiscordText(obj) then return end
	local part = partForDiscordText(obj)
	if not part or hooked[part] then return end
	hooked[part] = true
	discordParts[part] = true

	-- The Discord board was created from another sign, so it can still
	-- contain the old "Cadeau gratuit" prompt. Disable every legacy
	-- prompt inside this sign only, otherwise Roblox may display/trigger
	-- the wrong prompt when the player presses E.
	local scope = signScopeFor(part)
	for _, descendant in scope:GetDescendants() do
		if descendant:IsA("ProximityPrompt") and descendant.Name ~= "DiscordOpenPrompt" then
			descendant.Enabled = false
		end
	end

	local prompt = part:FindFirstChild("DiscordOpenPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = "DiscordOpenPrompt"
		prompt.Parent = part
	end

	prompt.ActionText = isFrench and "Ouvrir" or "Open"
	prompt.ObjectText = "Discord"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt.Enabled = true
	prompt:SetAttribute("DiscordInvitePrompt", true)

	prompt.Triggered:Connect(function()
		open(true)
	end)
end

local function nearDiscordSign()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then return false end
	for part in discordParts do
		if part and part:IsDescendantOf(workspace) then
			if (root.Position - part.Position).Magnitude <= 13 then
				return true
			end
		end
	end
	return false
end

-- Hard keyboard fallback: even if another custom prompt system consumes
-- the ProximityPrompt event, pressing E beside this board still opens it.
UIS.InputBegan:Connect(function(input, processed)
	if input.KeyCode == Enum.KeyCode.E and not panel.Visible and nearDiscordSign() then
		open(true)
	end
end)

local map = workspace:WaitForChild("PyramidMap", 60)
if map then
	for _, obj in map:GetDescendants() do
		hookDiscordText(obj)
	end
	map.DescendantAdded:Connect(function(obj)
		task.defer(hookDiscordText, obj)
	end)
end


-- Extra robust path for custom ProximityPrompt UIs.
PPS.PromptTriggered:Connect(function(prompt)
	if prompt and prompt:GetAttribute("DiscordInvitePrompt") == true then
		open(true)
	end
end)
