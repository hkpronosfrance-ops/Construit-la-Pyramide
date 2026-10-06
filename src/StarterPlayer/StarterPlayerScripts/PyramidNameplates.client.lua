local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local OWNER_USER_ID = 10027646422
local folder = RS:WaitForChild("PyramidHUD")
local C = require(folder:WaitForChild("Config"))
local R = require(folder:WaitForChild("Ranks"))

local holder = player:WaitForChild("PlayerGui"):WaitForChild("PyramidNameplates", 30)
if not holder then return end
local template = holder:WaitForChild("PlateTemplate")
template.Enabled = false

local function hug(t)
	local parentWidth = t.Parent.AbsoluteSize.X
	if parentWidth < 1 or t.TextBounds.X < 1 then
		return
	end
	local k = math.clamp((t.TextBounds.X + 6) / parentWidth, 0.05, 1)
	if math.abs(t.Size.X.Scale - k) > 0.01 then
		t.Size = UDim2.new(k, 0, t.Size.Y.Scale, 0)
	end
end

local plates = {}

local function build(p, head)
	local bb = template:Clone()
	bb.Name = p.Name
	bb:SetAttribute("IsTemplate", nil)
	bb.Adornee = head
	local count = bb:WaitForChild("Pyramid"):WaitForChild("Count")
	local rank = bb:WaitForChild("Rank")
	local rankInk = rank:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke", rank)
	local gradient = rank:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient", rank)
	local rankScale = rank:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", rank)
	local normalStrokeThickness = rankInk.Thickness
	local normalStrokeTransparency = rankInk.Transparency
	local normalTextColor = rank.TextColor3
	local pulseTween
	local shineTween
	local adminRainbowConnection
	local adminFxOn = false

	local function rainbow(g)
		local h0 = (os.clock() * 0.35) % 1
		local keys = {}
		for i = 0, 6 do
			keys[i + 1] = ColorSequenceKeypoint.new(i / 6, Color3.fromHSV((h0 + i * 0.12) % 1, 0.7, 1))
		end
		g.Color = ColorSequence.new(keys)
	end

	local function setAdminFx(on)
		if on == adminFxOn then
			return
		end
		adminFxOn = on

		if pulseTween then
			pulseTween:Cancel()
			pulseTween = nil
		end
		if shineTween then
			shineTween:Cancel()
			shineTween = nil
		end
		if adminRainbowConnection then
			adminRainbowConnection:Disconnect()
			adminRainbowConnection = nil
		end

		rankScale.Scale = 1
		gradient.Offset = Vector2.new(0, 0)
		rankInk.Thickness = normalStrokeThickness
		rankInk.Transparency = normalStrokeTransparency
		rank.TextColor3 = normalTextColor

		if on then
			-- Match the animated rainbow used by the +50,000 pyramid-fill button.
			rank.TextColor3 = Color3.new(1, 1, 1)
			rankInk.Color = Color3.fromRGB(0, 0, 0)
			rankInk.Thickness = math.max(normalStrokeThickness, 3.2)
			rankInk.Transparency = 0
			gradient.Enabled = true
			gradient.Rotation = 0
			rainbow(gradient)
			adminRainbowConnection = RunService.RenderStepped:Connect(function()
				if adminFxOn and rank.Parent then
					rainbow(gradient)
				end
			end)
		else
			gradient.Enabled = true
		end
	end

	local name = bb:WaitForChild("PlayerName")
	name.Text = p.DisplayName
	bb.Enabled = true
	bb.Parent = holder
	rank:GetPropertyChangedSignal("TextBounds"):Connect(function()
		hug(rank)
	end)
	bb:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		hug(rank)
	end)

	local function paint()
		local pyramids = math.floor(tonumber(p:GetAttribute(C.Stats.Pyramids)) or 0)
		count.Text = pyramids >= 1000 and (math.floor(pyramids / 100) / 10 .. "K") or tostring(pyramids)

		local style
		if p.UserId == OWNER_USER_ID then
			rank.Text = "👑 ADMIN"
			style = R.AdminStyle
			setAdminFx(true)
		else
			setAdminFx(false)
			local index = R.index(pyramids)
			rank.Text = R.Ranks[index][1]
			style = R.style(index)
		end

		gradient.Color = R.sequence(style)
		gradient.Rotation = style.Horizontal and 0 or 90
		rankInk.Color = style.Ink
		hug(rank)
	end
	paint()
	local connections = {
		p:GetAttributeChangedSignal(C.Stats.Pyramids):Connect(paint),
	}
	return { gui = bb, connections = connections, stopFx = function() setAdminFx(false) end }
end

local function drop(p)
	local plate = plates[p]
	if plate then
		if plate.stopFx then plate.stopFx() end
		for _, connection in plate.connections or {} do
			connection:Disconnect()
		end
		plate.gui:Destroy()
		plates[p] = nil
	end
end

local function attach(p, character)
	drop(p)
	local head = character:WaitForChild("Head", 10)
	local hum = character:WaitForChild("Humanoid", 10)
	if not head or character.Parent == nil or p.Character ~= character then
		return
	end
	if hum then
		hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end
	plates[p] = build(p, head)
end

local function watch(p)
	p.CharacterAdded:Connect(function(character)
		attach(p, character)
	end)
	p.CharacterRemoving:Connect(function()
		drop(p)
	end)
	if p.Character then
		task.spawn(attach, p, p.Character)
	end
end

Players.PlayerAdded:Connect(watch)
for _, p in Players:GetPlayers() do
	watch(p)
end
Players.PlayerRemoving:Connect(drop)
