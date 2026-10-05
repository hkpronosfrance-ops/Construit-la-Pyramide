local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local folder = RS:WaitForChild("PyramidHUD")
local C = require(folder:WaitForChild("Config"))
local B = require(folder:WaitForChild("BlocksConfig"))
local action = folder:WaitForChild("Action")
local remote = folder:WaitForChild("Blocks")

local function inMine()
	local ch = player.Character
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return false
	end
	local d = hrp.Position - B.Mine.Center
	return Vector2.new(d.X, d.Z).Magnitude <= B.Mine.Radius and hrp.Position.Y <= B.Mine.MaxY
end

local touchHeld = false
local touchInput
local function watchTile(o)
	if o:IsA("GuiButton") and o.Name == "PickUp" then
		local function press(input)
			return input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1
		end
		o.InputBegan:Connect(function(input)
			if press(input) then
				touchHeld = true
				touchInput = input
			end
		end)
		o.InputEnded:Connect(function(input)
			if press(input) then
				touchHeld = false
			end
		end)
	end
end
UIS.InputEnded:Connect(function(input)
	if input == touchInput then
		touchHeld = false
		touchInput = nil
	end
end)
local pg = player:WaitForChild("PlayerGui")
for _, o in pg:GetDescendants() do
	watchTile(o)
end
pg.DescendantAdded:Connect(watchTile)

local function held()
	return touchHeld
		or (UIS:IsKeyDown(Enum.KeyCode.E) and not UIS:GetFocusedTextBox())
		or UIS:IsGamepadButtonDown(Enum.UserInputType.Gamepad1, Enum.KeyCode.ButtonX)
end

local site = workspace:WaitForChild("PyramidMap"):WaitForChild("PyramidSite")
local function finished()
	local total = site:GetAttribute("BlocksTotal") or 0
	return total > 0 and (site:GetAttribute("BlocksPlaced") or 0) >= total
end
local noteDone

local lastGrab = 0
local function tryGrab()
	if os.clock() - lastGrab < B.PickupCooldown or not inMine() then
		return
	end
	if finished() then
		noteDone()
		return
	end
	if (player:GetAttribute(C.Stats.Carrying) or 0) >= (player:GetAttribute(C.Stats.Capacity) or 1) then
		return
	end
	lastGrab = os.clock()
	remote:FireServer("pickup")
end

action.Event:Connect(function(kind)
	if kind == "PickUp" then
		if inMine() and not finished() and (player:GetAttribute(C.Stats.Carrying) or 0) >= (player:GetAttribute(C.Stats.Capacity) or 1) then
			remote:FireServer("pickup")
		else
			tryGrab()
		end
	elseif kind == "Drop" then
		remote:FireServer("drop")
	end
end)

game:GetService("RunService").Heartbeat:Connect(function()
	if held() then
		tryGrab()
	end
end)

local gui = player:WaitForChild("PlayerGui"):WaitForChild("PyramidBlocks")
local msg = gui:WaitForChild("Message")
msg.Visible = false
local popupTemplate = gui:WaitForChild("BlockPopupTemplate")
popupTemplate.Enabled = false
local token = 0
local function say(text)
	token += 1
	local mine = token
	msg.Text = text
	msg.Visible = true
	task.delay(1.8, function()
		if token == mine then
			msg.Visible = false
		end
	end)
end
local lastNote = 0
function noteDone()
	if os.clock() - lastNote > 2 then
		lastNote = os.clock()
		say("The pyramid is finished! Wait for the next one.")
	end
end

local function popup(amount)
	local ch = player.Character
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end
	local bb = popupTemplate:Clone()
	bb.Name = "BlockPopup"
	bb:SetAttribute("IsTemplate", nil)
	bb.Adornee = hrp
	bb.StudsOffsetWorldSpace = popupTemplate.StudsOffsetWorldSpace + Vector3.new(math.random(-10, 10) / 10, 0, 0)
	local t = bb:WaitForChild("Text")
	local format = popupTemplate:GetAttribute(amount == 1 and "FormatOne" or "Format")
	t.Text = (type(format) == "string" and format or (amount == 1 and "+%s Block" or "+%s Blocks")):format(amount)
	local st = t:FindFirstChildOfClass("UIStroke")
	bb.Enabled = true
	bb.Parent = gui
	local info = TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(bb, info, { StudsOffsetWorldSpace = bb.StudsOffsetWorldSpace + Vector3.new(0, 3, 0) }):Play()
	TweenService:Create(t, info, { TextTransparency = 1 }):Play()
	if st then
		TweenService:Create(st, info, { Transparency = 1 }):Play()
	end
	task.delay(1, function()
		bb:Destroy()
	end)
end

local RunService = game:GetService("RunService")
local function blocks(cf, size, from, to)
	local a, b = cf:PointToObjectSpace(from), cf:PointToObjectSpace(to)
	local h = size / 2
	local t0, t1 = 0, 1
	for _, axis in { "X", "Y", "Z" } do
		local d = b[axis] - a[axis]
		if math.abs(d) < 1e-6 then
			if math.abs(a[axis]) > h[axis] then
				return false
			end
		else
			local u, v = (-h[axis] - a[axis]) / d, (h[axis] - a[axis]) / d
			if u > v then
				u, v = v, u
			end
			t0, t1 = math.max(t0, u), math.min(t1, v)
			if t0 > t1 then
				return false
			end
		end
	end
	return true
end
RunService.RenderStepped:Connect(function()
	local ch = player.Character
	local pile = ch and ch:FindFirstChild("CarriedBlocks")
	local head = ch and ch:FindFirstChild("Head")
	if not (pile and head) then
		return
	end
	local eye = workspace.CurrentCamera.CFrame.Position
	for _, part in pile:GetChildren() do
		if part:IsA("BasePart") then
			part.LocalTransparencyModifier = blocks(part.CFrame, part.Size, eye, head.Position) and 0.7 or 0
		end
	end
end)

remote.OnClientEvent:Connect(function(kind, amount)
	if kind == "picked" then
		popup(tonumber(amount) or 1)
	elseif kind == "full" then
		say("Backpack full! Train Strength for more.")
	end
end)

local anchorPart = Instance.new("Part")
anchorPart.Name = "PyramidPickUpAnchor"
anchorPart.Anchored = true
anchorPart.CanCollide = false
anchorPart.CanQuery = false
anchorPart.CanTouch = false
anchorPart.Transparency = 1
anchorPart.Size = Vector3.new(0.2, 0.2, 0.2)
anchorPart.Parent = workspace

local pickPrompt = Instance.new("ProximityPrompt")
pickPrompt.Name = "PickUpPrompt"
pickPrompt.ObjectText = "Block"
pickPrompt.ActionText = "Pick Up"
pickPrompt.KeyboardKeyCode = Enum.KeyCode.E
pickPrompt.GamepadKeyCode = Enum.KeyCode.ButtonX
pickPrompt.HoldDuration = 0
pickPrompt.MaxActivationDistance = 12
pickPrompt.RequiresLineOfSight = false
pickPrompt.Style = Enum.ProximityPromptStyle.Custom
pickPrompt.Enabled = false
pickPrompt.Parent = anchorPart
pickPrompt.Triggered:Connect(function()
	tryGrab()
end)

local function canPick()
	return inMine()
		and not finished()
		and (player:GetAttribute(C.Stats.Carrying) or 0) < (player:GetAttribute(C.Stats.Capacity) or 1)
end
game:GetService("RunService").RenderStepped:Connect(function()
	local ch = player.Character
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	local show = hrp ~= nil and canPick()
	if show then
		local right = workspace.CurrentCamera.CFrame.RightVector
		right = Vector3.new(right.X, 0, right.Z)
		right = right.Magnitude > 0.01 and right.Unit or Vector3.xAxis
		anchorPart.CFrame = CFrame.new(hrp.Position + right * 3 - Vector3.new(0, 1.2, 0))
	end
	if pickPrompt.Enabled ~= show then
		pickPrompt.Enabled = show
	end
end)
