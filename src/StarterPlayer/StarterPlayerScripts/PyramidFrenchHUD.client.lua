local Players = game:GetService("Players")
local LocalizationService = game:GetService("LocalizationService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local isFrench = RunService:IsStudio()

if not isFrench then
	local locale = "en-us"
	local ok, value = pcall(function()
		return LocalizationService.RobloxLocaleId
	end)
	if ok and type(value) == "string" then
		locale = string.lower(value)
	end
	isFrench = string.sub(locale, 1, 2) == "fr"
end

if not isFrench then
	return
end

local playerGui = player:WaitForChild("PlayerGui")

-- IMPORTANT:
-- This localization layer changes Text only.
-- It must not modify Size, Position, Font, TextSize, TextScaled, UIScale,
-- UIStroke, AnchorPoint, layout objects, or any other visual property.

local EXACT = {
	["Pick Up"] = "Ramasser",
	["Drop"] = "Déposer",
	["SAND SWEEPER"] = "BALAYEUR DE SABLE",
	["1.5x Speed"] = "1.5x Vitesse",
	["2x Strength"] = "2x Force",
}

local function translate(text)
	local exact = EXACT[text]
	if exact then
		return exact
	end

	local value = text:match("^Walk Speed:%s*(.+)$")
	if value then
		return "Vitesse de marche : " .. value
	end

	value = text:match("^Capacity:%s*(.+)$")
	if value then
		return "Capacité : " .. value
	end

	value = text:match("^Friend Boost:%s*(.+)$")
	if value then
		return "Bonus d'amis : " .. value
	end

	value = text:match("^ONLY%s+(.+)$")
	if value then
		return "SEULEMENT " .. value
	end

	return nil
end

local watched = setmetatable({}, { __mode = "k" })

local function watchTextObject(obj)
	if watched[obj] then
		return
	end
	if not (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")) then
		return
	end

	watched[obj] = true

	local applying = false
	local function apply()
		if applying or not obj.Parent then
			return
		end

		local translated = translate(obj.Text)
		if translated and translated ~= obj.Text then
			applying = true
			obj.Text = translated
			applying = false
		end
	end

	apply()
	obj:GetPropertyChangedSignal("Text"):Connect(apply)
end

local function scan(root)
	if root:IsA("TextLabel") or root:IsA("TextButton") or root:IsA("TextBox") then
		watchTextObject(root)
	end
	for _, obj in root:GetDescendants() do
		watchTextObject(obj)
	end
end

local watchedRoots = setmetatable({}, { __mode = "k" })

local function watchRoot(root)
	if watchedRoots[root] then
		return
	end
	watchedRoots[root] = true
	scan(root)
	root.DescendantAdded:Connect(function(obj)
		watchTextObject(obj)
	end)
end

local HUD_NAMES = {
	PyramidHUD = true,
	PyramidFriendBoost = true,
	PyramidKeys = true,
}

-- HUDs may already exist before this LocalScript starts, while their descendants
-- are still being cloned/created. Watch both current and future descendants.
for name in HUD_NAMES do
	local gui = playerGui:FindFirstChild(name)
	if gui then
		watchRoot(gui)
	end
end

playerGui.ChildAdded:Connect(function(child)
	if HUD_NAMES[child.Name] then
		watchRoot(child)
	end
end)

-- Some overhead/world-facing text is cloned into the character at runtime.
local function scanCharacter(character)
	scan(character)
	character.DescendantAdded:Connect(watchTextObject)
end

if player.Character then
	scanCharacter(player.Character)
end
player.CharacterAdded:Connect(scanCharacter)
