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

local DISCORD_BLURPLE = rgb(88, 101, 242)
local DISCORD_BLURPLE_LIGHT = rgb(114, 137, 218)
local DISCORD_BLURPLE_DARK = rgb(68, 78, 199)
local DISCORD_SURFACE = rgb(49, 51, 56)
local DISCORD_SURFACE_DARK = rgb(30, 31, 34)
local DISCORD_CARD = rgb(64, 68, 75)
local DISCORD_LOGO_ASSET = "rbxassetid://105894278804230"

local function gradientPair(obj, topColor, bottomColor, rotation)
	local g = obj:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient")
	g.Rotation = rotation or 90
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, topColor),
		ColorSequenceKeypoint.new(1, bottomColor),
	})
	g.Parent = obj
	return g
end

local function addRound(parent, radius)
	local corner = parent:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
end

local function makeDiscordHeaderIcon(header)
	local oldIcon = header:FindFirstChild("MenuIcon")
	local oldShadow = header:FindFirstChild("MenuIconShadow")
	if oldIcon and oldIcon:IsA("GuiObject") then oldIcon.Visible = false end
	if oldShadow and oldShadow:IsA("GuiObject") then oldShadow.Visible = false end

	local old = header:FindFirstChild("DiscordHeaderIcon")
	if old then old:Destroy() end

	-- Use the exact user-uploaded Discord PNG so the header logo is pixel-faithful
	-- to the supplied artwork rather than a Roblox-shape approximation.
	local icon = Instance.new("ImageLabel")
	icon.Name = "DiscordHeaderIcon"
	icon.BackgroundTransparency = 1
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.Position = UDim2.new(0, 7, 0.5, 0)
	icon.Size = UDim2.fromOffset(96, 78)
	icon.Image = DISCORD_LOGO_ASSET
	icon.ScaleType = Enum.ScaleType.Fit
	icon.ImageColor3 = WHITE
	icon.ImageTransparency = 0
	icon.ZIndex = header.ZIndex + 6
	icon.Parent = header

	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio = 1
	aspect.DominantAxis = Enum.DominantAxis.Height
	aspect.Parent = icon
end

local function applyDiscordBranding(panel, header, likeBtn, joinBtn, claim, prize)
	panel.BackgroundColor3 = DISCORD_SURFACE
	panel.BackgroundTransparency = 0.12
	local panelStroke = panel:FindFirstChildOfClass("UIStroke")
	if panelStroke then panelStroke.Color = DISCORD_SURFACE_DARK end

	header.BackgroundColor3 = DISCORD_BLURPLE
	header.BackgroundTransparency = 0
	gradientPair(header, DISCORD_BLURPLE_LIGHT, DISCORD_BLURPLE_DARK, 0)
	local headerStroke = header:FindFirstChildOfClass("UIStroke")
	if headerStroke then headerStroke.Color = rgb(20, 24, 45) end

	local rim = header:FindFirstChild("WinRim")
	if rim and rim:IsA("GuiObject") then
		local s = rim:FindFirstChildOfClass("UIStroke")
		if s then s.Color = rgb(40, 49, 160) end
	end

	T.gradient(likeBtn, DISCORD_BLURPLE)
	T.gradient(joinBtn, DISCORD_BLURPLE)
	T.gradient(claim, rgb(91, 98, 112))

	if prize and prize:IsA("GuiObject") then
		prize.BackgroundColor3 = DISCORD_CARD
		prize.BackgroundTransparency = 0.10
		local s = prize:FindFirstChildOfClass("UIStroke")
		if s then s.Color = DISCORD_SURFACE_DARK end
	end

	makeDiscordHeaderIcon(header)
end

local old = pg:FindFirstChild("DiscordInvite")
if old then
	old:Destroy()
end

-- Reuse the exact Free Rewards window so the Discord popup has the
-- same proportions, textures, borders, fonts and button styling.
local sourceGui = pg:WaitForChild("GroupRewards", 30)
if not sourceGui then
	warn("[PyramidDiscordInvite] GroupRewards GUI not found")
	return
end

local sourcePanel = sourceGui:WaitForChild("FreeRewards", 10)
local sourceBackdrop = sourceGui:WaitForChild("Backdrop", 10)
if not sourcePanel or not sourceBackdrop then
	warn("[PyramidDiscordInvite] FreeRewards panel/backdrop not found")
	return
end

local gui = Instance.new("ScreenGui")
gui.Name = "DiscordInvite"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = sourceGui.IgnoreGuiInset
gui.DisplayOrder = math.max(sourceGui.DisplayOrder + 1, 80)
gui:SetAttribute("Open", false)
gui.Parent = pg

local backdrop = sourceBackdrop:Clone()
backdrop.Name = "Backdrop"
backdrop.Visible = false
backdrop.Parent = gui

local panel = sourcePanel:Clone()
panel.Name = "DiscordPanel"
panel.Visible = false
panel.Parent = gui

-- IMPORTANT: wire the clone through the exact same Theme adoption path as
-- PyramidGroupRewards. The original window contains styled Caption/BtnFill
-- descendants; adopting before changing Text keeps those visible descendants
-- synchronized and preserves the real Free Rewards rendering instead of only
-- changing the invisible TextButton.Text values.
T.adoptWindow(panel)

local header = panel:WaitForChild("Header")
local close = header:WaitForChild("Close")
local likeBtn = panel:WaitForChild("Like")
local joinBtn = panel:WaitForChild("Join")
local claim = panel:WaitForChild("Claim")
local hint = panel:WaitForChild("Hint")
local prize = panel:WaitForChild("Prize")
local amount = prize:WaitForChild("Amount")

applyDiscordBranding(panel, header, likeBtn, joinBtn, claim, prize)

-- Change only the content of the real Free Rewards controls. Their geometry,
-- gradients, strokes, textures, shadows and typography remain untouched.
local title = header:FindFirstChild("Title")
if title and title:IsA("TextLabel") then
	title.Text = "Discord"
end

likeBtn.Text = isFrench and "Rejoins notre Discord !" or "Join our Discord!"
joinBtn.Text = isFrench and "Lien officiel sur la page du jeu !" or "Official link on the game page!"
amount.Text = isFrench and "Communauté • Codes • Actus" or "Community • Codes • News"
hint.Text = isFrench
	and "Retrouve le serveur officiel dans les liens sociaux de la page Roblox du jeu."
	or "Find the official server in the Roblox game page social links."
claim.Text = isFrench and "COMPRIS" or "GOT IT"

-- Match the original Free Rewards "Locked" state for the bottom button.
-- T.adoptWindow above wires BtnFill to this gradient, so the visible skinned
-- layers receive the exact same grey palette as PyramidGroupRewards.
-- Keep the bottom action subdued while staying inside the Discord palette.
T.gradient(claim, rgb(91, 98, 112))

-- Keep the exact Free Rewards layout, only remove reward-specific imagery/text
-- that would otherwise imply coins or a claimable reward.
for _, obj in prize:GetDescendants() do
	if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
		obj.Visible = false
	end
end

-- Make the center line fit our Discord text without changing the panel geometry.
amount.TextScaled = true
amount.TextWrapped = true
local amountConstraint = amount:FindFirstChildOfClass("UITextSizeConstraint")
if not amountConstraint then
	amountConstraint = Instance.new("UITextSizeConstraint")
	amountConstraint.Parent = amount
end
amountConstraint.MinTextSize = 14
amountConstraint.MaxTextSize = 24

hint.TextWrapped = true
hint.TextScaled = false
hint.TextSize = math.min(hint.TextSize > 0 and hint.TextSize or 14, 14)

-- The bottom button should look exactly like the original Locked/Claim button.
claim.AutoButtonColor = true

local function open(value)
	panel.Visible = value
	backdrop.Visible = value
	gui:SetAttribute("Open", value)
end

close.Activated:Connect(function()
	open(false)
end)
claim.Activated:Connect(function()
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

-- These rows are visual calls-to-action; the official external link belongs
-- in the Roblox experience's Social Links area.
likeBtn.Activated:Connect(function()
	hint.Text = isFrench
		and "Le lien Discord officiel est disponible dans les liens sociaux de la page du jeu."
		or "The official Discord link is available in the game page social links."
end)
joinBtn.Activated:Connect(function()
	hint.Text = isFrench
		and "Ouvre la page Roblox du jeu puis utilise les liens sociaux officiels."
		or "Open the Roblox game page and use the official social links."
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
