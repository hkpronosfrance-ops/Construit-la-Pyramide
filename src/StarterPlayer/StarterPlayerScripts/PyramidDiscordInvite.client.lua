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
backdrop.BackgroundTransparency = 0.43
backdrop.BorderSizePixel = 0
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.Visible = false
backdrop.ZIndex = 1
backdrop.Parent = gui

local panel = Instance.new("Frame")
panel.Name = "DiscordPanel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(500, 430)
panel.BackgroundColor3 = rgb(62, 63, 67)
panel.BorderSizePixel = 0
panel.Visible = false
panel.ZIndex = 2
panel.Parent = gui

local scale = Instance.new("UIScale")
scale.Scale = 1
scale.Parent = panel

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 8)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = rgb(24, 24, 28)
panelStroke.Thickness = 3
panelStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
panelStroke.Parent = panel

local panelGradient = Instance.new("UIGradient")
panelGradient.Rotation = 90
panelGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, rgb(83, 83, 79)),
	ColorSequenceKeypoint.new(1, rgb(51, 53, 58)),
})
panelGradient.Parent = panel

local studs = Instance.new("ImageLabel")
studs.Name = "SurfaceStuds"
studs.BackgroundTransparency = 1
studs.Image = T.Texture
studs.ImageTransparency = 0.82
studs.ScaleType = Enum.ScaleType.Tile
studs.TileSize = UDim2.fromOffset(20, 20)
studs.Size = UDim2.fromScale(1, 1)
studs.ZIndex = 2
studs.Parent = panel
local studsCorner = Instance.new("UICorner")
studsCorner.CornerRadius = panelCorner.CornerRadius
studsCorner.Parent = studs

local header = Instance.new("Frame")
header.Name = "Header"
header.Position = UDim2.fromOffset(0, 0)
header.Size = UDim2.new(1, 0, 0, 64)
header.BackgroundColor3 = rgb(255, 178, 18)
header.BorderSizePixel = 0
header.ZIndex = 4
header.Parent = panel

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 8)
headerCorner.Parent = header

local headerStroke = Instance.new("UIStroke")
headerStroke.Color = rgb(35, 29, 20)
headerStroke.Thickness = 3
headerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
headerStroke.Parent = header

local headerGradient = Instance.new("UIGradient")
headerGradient.Rotation = 90
headerGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, rgb(255, 213, 50)),
	ColorSequenceKeypoint.new(1, rgb(242, 135, 13)),
})
headerGradient.Parent = header

local headerMask = Instance.new("Frame")
headerMask.BackgroundColor3 = rgb(242, 135, 13)
headerMask.BorderSizePixel = 0
headerMask.Position = UDim2.new(0, 0, 1, -10)
headerMask.Size = UDim2.new(1, 0, 0, 10)
headerMask.ZIndex = 4
headerMask.Parent = header

local iconBubble = Instance.new("Frame")
iconBubble.Name = "IconBubble"
iconBubble.AnchorPoint = Vector2.new(0, 0.5)
iconBubble.Position = UDim2.new(0, 10, 0.5, 0)
iconBubble.Size = UDim2.fromOffset(58, 58)
iconBubble.BackgroundColor3 = BLUE
iconBubble.BorderSizePixel = 0
iconBubble.ZIndex = 6
iconBubble.Parent = header
local iconCorner = Instance.new("UICorner")
iconCorner.CornerRadius = UDim.new(0, 13)
iconCorner.Parent = iconBubble
local iconStroke = Instance.new("UIStroke")
iconStroke.Color = rgb(38, 43, 110)
iconStroke.Thickness = 2
iconStroke.Parent = iconBubble

local icon = Instance.new("TextLabel")
icon.Name = "Icon"
icon.BackgroundTransparency = 1
icon.Size = UDim2.fromScale(1, 1)
icon.Font = Enum.Font.FredokaOne
icon.Text = "💬"
icon.TextSize = 38
icon.TextColor3 = WHITE
icon.ZIndex = 7
icon.Parent = iconBubble

local title = Instance.new("TextLabel")
title.Name = "Title"
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(78, 6)
title.Size = UDim2.new(1, -148, 1, -12)
title.Font = Enum.Font.FredokaOne
title.Text = "Discord"
title.TextColor3 = WHITE
title.TextScaled = true
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextStrokeColor3 = rgb(35, 25, 45)
title.TextStrokeTransparency = 0
title.ZIndex = 7
title.Parent = header
local titleLimit = Instance.new("UITextSizeConstraint")
titleLimit.MinTextSize = 20
titleLimit.MaxTextSize = 34
titleLimit.Parent = title

local close = Instance.new("TextButton")
close.Name = "Close"
close.AnchorPoint = Vector2.new(1, 0.5)
close.Position = UDim2.new(1, -10, 0.5, 0)
close.Size = UDim2.fromOffset(48, 48)
close.BackgroundColor3 = rgb(226, 50, 43)
close.BorderSizePixel = 0
close.Text = "X"
close.TextColor3 = WHITE
close.TextStrokeColor3 = rgb(50, 18, 18)
close.TextStrokeTransparency = 0
close.TextSize = 28
close.Font = Enum.Font.GothamBlack
close.AutoButtonColor = true
close.ZIndex = 8
close.Parent = header
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 5)
closeCorner.Parent = close
local closeStroke = Instance.new("UIStroke")
closeStroke.Color = rgb(35, 25, 25)
closeStroke.Thickness = 3
closeStroke.Parent = close

local function makeBlueRow(name, y, text)
	local b = Instance.new("TextButton")
	b.Name = name
	b.Position = UDim2.fromOffset(48, y)
	b.Size = UDim2.new(1, -96, 0, 48)
	b.BackgroundColor3 = rgb(42, 164, 242)
	b.BorderSizePixel = 0
	b.AutoButtonColor = true
	b.Text = ""
	b.ZIndex = 6
	b.Parent = panel

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 7)
	corner.Parent = b
	local stroke = Instance.new("UIStroke")
	stroke.Color = rgb(20, 34, 52)
	stroke.Thickness = 2
	stroke.Parent = b
	local grad = Instance.new("UIGradient")
	grad.Rotation = 90
	grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, rgb(73, 190, 255)),
		ColorSequenceKeypoint.new(1, rgb(25, 126, 222)),
	})
	grad.Parent = b

	local caption = Instance.new("TextLabel")
	caption.Name = "Caption"
	caption.BackgroundTransparency = 1
	caption.Size = UDim2.fromScale(1, 1)
	caption.Font = Enum.Font.FredokaOne
	caption.Text = text
	caption.TextColor3 = WHITE
	caption.TextScaled = true
	caption.TextStrokeColor3 = rgb(10, 23, 42)
	caption.TextStrokeTransparency = 0
	caption.ZIndex = 7
	caption.Parent = b
	local lim = Instance.new("UITextSizeConstraint")
	lim.MinTextSize = 14
	lim.MaxTextSize = 25
	lim.Parent = caption
	return b
end

local joinRow = makeBlueRow(
	"JoinRow",
	86,
	isFrench and "Rejoins notre Discord !" or "Join our Discord!"
)

local socialRow = makeBlueRow(
	"SocialRow",
	144,
	isFrench and "Lien officiel sur la page du jeu !" or "Official link on the game page!"
)

local arrow = Instance.new("TextLabel")
arrow.Name = "Arrow"
arrow.BackgroundTransparency = 1
arrow.Position = UDim2.new(0.5, -34, 0, 198)
arrow.Size = UDim2.fromOffset(68, 58)
arrow.Font = Enum.Font.GothamBlack
arrow.Text = "↓"
arrow.TextSize = 48
arrow.TextColor3 = rgb(235, 241, 255)
arrow.TextStrokeColor3 = rgb(18, 29, 48)
arrow.TextStrokeTransparency = 0
arrow.ZIndex = 6
arrow.Parent = panel

local highlight = Instance.new("TextLabel")
highlight.Name = "Highlight"
highlight.BackgroundTransparency = 1
highlight.Position = UDim2.fromOffset(28, 252)
highlight.Size = UDim2.new(1, -56, 0, 44)
highlight.Font = Enum.Font.FredokaOne
highlight.Text = isFrench and "💬 COMMUNAUTÉ • CODES • ACTUS" or "💬 COMMUNITY • CODES • NEWS"
highlight.TextColor3 = rgb(255, 215, 45)
highlight.TextScaled = true
highlight.TextStrokeColor3 = rgb(80, 55, 0)
highlight.TextStrokeTransparency = 0
highlight.ZIndex = 6
highlight.Parent = panel
local highlightLimit = Instance.new("UITextSizeConstraint")
highlightLimit.MinTextSize = 15
highlightLimit.MaxTextSize = 26
highlightLimit.Parent = highlight

local description = Instance.new("TextLabel")
description.Name = "Description"
description.BackgroundTransparency = 1
description.Position = UDim2.fromOffset(42, 298)
description.Size = UDim2.new(1, -84, 0, 52)
description.Font = Enum.Font.GothamBold
description.Text = isFrench
	and "Retrouve notre serveur officiel dans les liens sociaux de la page Roblox du jeu."
	or "Find our official server in the social links on the Roblox game page."
description.TextColor3 = rgb(235, 235, 238)
description.TextSize = 16
description.TextWrapped = true
description.TextXAlignment = Enum.TextXAlignment.Center
description.TextYAlignment = Enum.TextYAlignment.Center
description.ZIndex = 6
description.Parent = panel

local okButton = Instance.new("TextButton")
okButton.Name = "Ok"
okButton.AnchorPoint = Vector2.new(0.5, 0)
okButton.Position = UDim2.new(0.5, 0, 0, 362)
okButton.Size = UDim2.fromOffset(300, 52)
okButton.BackgroundColor3 = rgb(130, 145, 172)
okButton.BorderSizePixel = 0
okButton.AutoButtonColor = true
okButton.Text = ""
okButton.ZIndex = 6
okButton.Parent = panel

local okCorner = Instance.new("UICorner")
okCorner.CornerRadius = UDim.new(0, 7)
okCorner.Parent = okButton
local okStroke = Instance.new("UIStroke")
okStroke.Color = rgb(27, 34, 49)
okStroke.Thickness = 2
okStroke.Parent = okButton
local okGradient = Instance.new("UIGradient")
okGradient.Rotation = 90
okGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, rgb(172, 186, 212)),
	ColorSequenceKeypoint.new(1, rgb(104, 119, 151)),
})
okGradient.Parent = okButton

local okCaption = Instance.new("TextLabel")
okCaption.Name = "Caption"
okCaption.BackgroundTransparency = 1
okCaption.Size = UDim2.fromScale(1, 1)
okCaption.Font = Enum.Font.FredokaOne
okCaption.Text = isFrench and "COMPRIS" or "GOT IT"
okCaption.TextColor3 = WHITE
okCaption.TextScaled = true
okCaption.TextStrokeColor3 = rgb(23, 30, 45)
okCaption.TextStrokeTransparency = 0
okCaption.ZIndex = 7
okCaption.Parent = okButton
local okLimit = Instance.new("UITextSizeConstraint")
okLimit.MinTextSize = 16
okLimit.MaxTextSize = 26
okLimit.Parent = okCaption

local function updateScale()
	local camera = workspace.CurrentCamera
	if not camera then return end
	local v = camera.ViewportSize
	scale.Scale = math.min(1, (v.X - 28) / 500, (v.Y - 46) / 430)
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

-- The blue rows are informational on purpose: Roblox experiences should
-- direct players to the experience's official social links rather than
-- attempting to open an external Discord URL directly.
joinRow.Activated:Connect(function() end)
socialRow.Activated:Connect(function() end)

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
