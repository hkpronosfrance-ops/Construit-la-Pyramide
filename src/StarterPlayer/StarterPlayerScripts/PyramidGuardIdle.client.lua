-- Anime les gardes de l'entrée du GYM côté client : respiration lente
-- et tête qui suit le joueur quand il passe à proximité.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LOOK_RANGE = 45
local MAX_YAW = math.rad(55)
local TURN_SPEED = 4
local BREATH_SPEED = 1.6
local BREATH_AMOUNT = 0.05 -- en fraction de la taille de la tête

local player = Players.LocalPlayer
local decor = workspace:WaitForChild("PyramidMap"):WaitForChild("Gym"):WaitForChild("GymDecor", 30)
if not decor then
	return
end

local guards = {}
local collected = {}

local function collect(holder)
	local body = holder:FindFirstChild("Body")
	local head = body and body:FindFirstChild("Head")
	local torso = body and body:FindFirstChild("Torso")
	if not head or not torso then
		return
	end
	collected[holder] = true
	local unit = head.Size.Y
	local guard = {
		holder = holder,
		neck = torso.CFrame * CFrame.new(0, unit, 0),
		look = torso.CFrame.LookVector,
		unit = unit,
		yaw = 0,
		phase = math.random() * math.pi * 2,
		upper = {},
		head = {},
	}
	-- haut du corps (respire) et tête + accessoires de tête (tournent)
	for _, d in body:GetDescendants() do
		if d:IsA("BasePart") and d.Anchored and d.Name ~= "HumanoidRootPart" then
			local attachedToHead = d == head or (d.Parent and d.Parent:IsA("Accessory"))
			local isLeg = d.Name == "Left Leg" or d.Name == "Right Leg"
			if attachedToHead then
				table.insert(guard.head, { part = d, base = d.CFrame })
			elseif not isLeg then
				table.insert(guard.upper, { part = d, base = d.CFrame })
			end
		end
	end
	table.insert(guards, guard)
end

-- avec le streaming, les gardes peuvent arriver après le lancement du script
task.spawn(function()
	while true do
		for _, child in decor:GetChildren() do
			if child.Name == "Guard" and not collected[child] then
				collect(child)
			end
		end
		task.wait(2)
	end
end)

local function targetYaw(guard)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return 0
	end
	local offset = root.Position - guard.neck.Position
	offset = Vector3.new(offset.X, 0, offset.Z)
	if offset.Magnitude > LOOK_RANGE or offset.Magnitude < 1 then
		return 0
	end
	local fwd = Vector3.new(guard.look.X, 0, guard.look.Z).Unit
	local angle = math.atan2(fwd:Cross(offset.Unit).Y, fwd:Dot(offset.Unit))
	if math.abs(angle) > math.rad(110) then
		return 0 -- joueur derrière le garde
	end
	return math.clamp(angle, -MAX_YAW, MAX_YAW)
end

RunService.RenderStepped:Connect(function(dt)
	local t = os.clock()
	for i = #guards, 1, -1 do
		local guard = guards[i]
		if not guard.holder.Parent or not guard.head[1] or not guard.head[1].part.Parent then
			-- garde déchargé par le streaming : on le reprendra quand il revient
			collected[guard.holder] = nil
			table.remove(guards, i)
			continue
		end
		guard.yaw += (targetYaw(guard) - guard.yaw) * math.min(1, dt * TURN_SPEED)
		local breath = CFrame.new(0, math.sin(t * BREATH_SPEED + guard.phase) * BREATH_AMOUNT * guard.unit, 0)
		for _, item in guard.upper do
			item.part.CFrame = breath * item.base
		end
		local turn = guard.neck * CFrame.Angles(0, guard.yaw, 0) * guard.neck:Inverse()
		for _, item in guard.head do
			item.part.CFrame = breath * turn * item.base
		end
	end
end)