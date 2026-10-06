local Workspace = game:GetService("Workspace")

local map = Workspace:WaitForChild("PyramidMap", 30)
if not map then return end

local gym = map:WaitForChild("Gym", 30)
if not gym then return end

local pads = gym:WaitForChild("Pads", 30)
if not pads then return end

local BLACK_TOP = Color3.fromRGB(8, 8, 8)
local BLACK_BOTTOM = Color3.fromRGB(52, 52, 52)
local WHITE = Color3.fromRGB(255, 255, 255)

local watched = setmetatable({}, { __mode = "k" })

local function isTargetText(text)
	local upper = string.upper(text or "")
	return upper == "250X" or upper == "ADMIN" or upper == "ADMINISTRATEUR"
end

local function styleText(label)
	if not (label:IsA("TextLabel") or label:IsA("TextButton") or label:IsA("TextBox")) then
		return
	end
	if not isTargetText(label.Text) then
		return
	end

	label.TextColor3 = BLACK_TOP
	label.TextStrokeColor3 = WHITE
	label.TextStrokeTransparency = 0

	local gradient = label:FindFirstChild("AdminBlackGradient")
	if not gradient then
		gradient = Instance.new("UIGradient")
		gradient.Name = "AdminBlackGradient"
		gradient.Parent = label
	end
	gradient.Rotation = 90
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, BLACK_TOP),
		ColorSequenceKeypoint.new(1, BLACK_BOTTOM),
	})

	local stroke = label:FindFirstChild("AdminWhiteStroke")
	if not stroke then
		stroke = Instance.new("UIStroke")
		stroke.Name = "AdminWhiteStroke"
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Parent = label
	end
	stroke.Color = WHITE
	stroke.Thickness = label.Text:upper() == "250X" and 3 or 2.5
	stroke.Transparency = 0
end

local function watchLabel(label)
	if watched[label] then return end
	watched[label] = true
	styleText(label)
	label:GetPropertyChangedSignal("Text"):Connect(function()
		styleText(label)
	end)
end

local function styleZone(zone)
	if not (zone:GetAttribute("Paid") == true or string.find(string.upper(zone.Name), "ADMIN", 1, true)) then
		return
	end

	for _, obj in zone:GetDescendants() do
		if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
			watchLabel(obj)
		end
	end

	zone.DescendantAdded:Connect(function(obj)
		if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
			watchLabel(obj)
		end
	end)
end

for _, zone in pads:GetChildren() do
	styleZone(zone)
end

pads.ChildAdded:Connect(styleZone)
