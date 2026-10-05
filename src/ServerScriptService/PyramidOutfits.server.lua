local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local KILT = "rbxassetid://129892047801968"
local PHARAOH = {
	Hat = "18482412",
	Shirt = "rbxassetid://131735751636885",
	Pants = "rbxassetid://101317152622976",
}
local PINK, PURPLE = Color3.fromRGB(255, 92, 232), Color3.fromRGB(168, 64, 255)
local SKIN = Color3.fromRGB(150, 102, 64)

local function aura(hrp, on)
	local old = hrp:FindFirstChild("PharaohAura")
	if old and not on then
		old:Destroy()
	elseif on and not old then
		local e = Instance.new("ParticleEmitter")
		e.Name = "PharaohAura"
		e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		e.Color = ColorSequence.new(PINK, PURPLE)
		e.LightEmission = 1
		e.Rate = 10
		e.Lifetime = NumberRange.new(0.8, 1.4)
		e.Speed = NumberRange.new(0.5, 1.5)
		e.SpreadAngle = Vector2.new(180, 180)
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0) })
		e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 1) })
		e.Parent = hrp
	end
end

local dressing = {}
local function dress(p)
	local ch = p.Character
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	if not (hum and hrp) or dressing[ch] then
		return
	end
	dressing[ch] = true
	local pharaoh = p:GetAttribute("Pharaoh") == true
	local ok, applied = pcall(hum.GetAppliedDescription, hum)
	if ok and applied then
		local desc = applied:Clone()
		desc.Head, desc.Torso = 0, 0
		desc.LeftArm, desc.RightArm, desc.LeftLeg, desc.RightLeg = 0, 0, 0, 0
		desc.GraphicTShirt = 0
		local skin = desc.HeadColor
		local _, sat = skin:ToHSV()
		if sat < 0.15 then
			skin = SKIN
		end
		desc.HeadColor = skin
		desc.TorsoColor, desc.LeftArmColor, desc.RightArmColor, desc.LeftLegColor, desc.RightLegColor = skin, skin, skin, skin, skin
		local keep = {}
		for _, a in desc:GetAccessories(true) do
			if not pharaoh and a.AccessoryType == Enum.AccessoryType.Hair then
				table.insert(keep, a)
			end
		end
		desc:SetAccessories(keep, true)
		if pharaoh then
			desc.HatAccessory = PHARAOH.Hat
		end
		desc.Shirt, desc.Pants = 0, 0
		local done = pcall(hum.ApplyDescription, hum, desc)
		if not done then
			warn("[PyramidOutfits] could not dress " .. p.Name)
		end
	end
	if ch.Parent then
		for _, c in ch:GetChildren() do
			if c:IsA("Shirt") or c:IsA("Pants") or c:IsA("ShirtGraphic") or c.Name == "PharaohStaff" then
				c:Destroy()
			end
		end
		if pharaoh then
			local shirt = Instance.new("Shirt")
			shirt.Name = "PharaohShirt"
			shirt.ShirtTemplate = PHARAOH.Shirt
			shirt.Parent = ch
			local pants = Instance.new("Pants")
			pants.Name = "PharaohPants"
			pants.PantsTemplate = PHARAOH.Pants
			pants.Parent = ch
			local staff = RS:FindFirstChild("PyramidHUD") and RS.PyramidHUD:FindFirstChild("PharaohStaff")
			if staff then
				hum:AddAccessory(staff:Clone())
			end
		else
			local kilt = Instance.new("Pants")
			kilt.Name = "WorkerKilt"
			kilt.PantsTemplate = KILT
			kilt.Parent = ch
		end
		aura(hrp, pharaoh)
	end
	dressing[ch] = nil
	if ch.Parent and (p:GetAttribute("Pharaoh") == true) ~= pharaoh then
		task.defer(dress, p)
	end
end

local function watch(p)
	p.CharacterAppearanceLoaded:Connect(function()
		dress(p)
	end)
	p:GetAttributeChangedSignal("Pharaoh"):Connect(function()
		dress(p)
	end)
	if p.Character and p:HasAppearanceLoaded() then
		task.spawn(dress, p)
	end
end
Players.PlayerAdded:Connect(watch)
for _, p in Players:GetPlayers() do
	watch(p)
end
