local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local folder = RS:WaitForChild("PyramidHUD")
local C = require(folder:WaitForChild("Config"))
local R = require(folder:WaitForChild("Ranks"))

local holder = player:WaitForChild("PlayerGui"):WaitForChild("PyramidNameplates")
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
		local index = R.index(pyramids)
		local style = R.style(index)
		rank.Text = R.Ranks[index][1]
		gradient.Color = R.sequence(style)
		gradient.Rotation = style.Horizontal and 0 or 90
		rankInk.Color = style.Ink
		hug(rank)
	end
	paint()
	local conn = p:GetAttributeChangedSignal(C.Stats.Pyramids):Connect(paint)
	return { gui = bb, conn = conn }
end

local function drop(p)
	local plate = plates[p]
	if plate then
		plate.conn:Disconnect()
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
