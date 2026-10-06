local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local AssetService = game:GetService("AssetService")

local OWNER_USER_ID = 10027646422
local ADMIN_AURA_ASSET_ID = 10584464506
local KILT = "rbxassetid://129892047801968"
local PHARAOH = {
	Hat = "18482412",
	Shirt = "rbxassetid://131735751636885",
	Pants = "rbxassetid://101317152622976",
}
local PINK, PURPLE = Color3.fromRGB(255, 92, 232), Color3.fromRGB(168, 64, 255)
local ADMIN_RED, ADMIN_DARK_RED = Color3.fromRGB(255, 35, 35), Color3.fromRGB(90, 0, 0)
local SKIN = Color3.fromRGB(150, 102, 64)

local function aura(hrp, mode)
	local old = hrp:FindFirstChild("PharaohAura")
	if old then
		old:Destroy()
	end
	local adminOld = hrp:FindFirstChild("AdminAura")
	if adminOld then
		adminOld:Destroy()
	end

	if mode == "pharaoh" then
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
	elseif mode == "admin" then
		local e = Instance.new("ParticleEmitter")
		e.Name = "AdminAura"
		e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		e.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, ADMIN_RED),
			ColorSequenceKeypoint.new(1, ADMIN_DARK_RED),
		})
		e.LightEmission = 0.8
		e.Rate = 16
		e.Lifetime = NumberRange.new(0.7, 1.25)
		e.Speed = NumberRange.new(0.35, 1.2)
		e.SpreadAngle = Vector2.new(180, 180)
		e.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.5),
			NumberSequenceKeypoint.new(0.6, 0.22),
			NumberSequenceKeypoint.new(1, 0),
		})
		e.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.08),
			NumberSequenceKeypoint.new(1, 1),
		})
		e.Parent = hrp
	end
end

local function adminHighlight(character, on)
	local old = character:FindFirstChild("AdminHighlight")
	if not on then
		if old then old:Destroy() end
		return
	end
	local h = old or Instance.new("Highlight")
	h.Name = "AdminHighlight"
	h.DepthMode = Enum.HighlightDepthMode.Occluded
	h.FillColor = Color3.fromRGB(105, 0, 0)
	h.FillTransparency = 0.72
	h.OutlineColor = Color3.fromRGB(255, 40, 40)
	h.OutlineTransparency = 0.08
	h.Parent = character
end

local adminAuraTemplate
local adminAuraLoadAttempted = false

local function getAdminAuraTemplate()
	if adminAuraLoadAttempted then
		return adminAuraTemplate
	end
	adminAuraLoadAttempted = true

	local ok, loaded = pcall(function()
		return AssetService:LoadAssetAsync(ADMIN_AURA_ASSET_ID)
	end)
	if not ok or not loaded then
		warn("[PyramidOutfits] could not load admin aura asset " .. tostring(ADMIN_AURA_ASSET_ID) .. ": " .. tostring(loaded))
		return nil
	end

	for _, o in loaded:GetDescendants() do
		if o:IsA("Script") or o:IsA("LocalScript") or o:IsA("ModuleScript") then
			o:Destroy()
		end
	end

	adminAuraTemplate = loaded
	return adminAuraTemplate
end

local function removeAdminAuraAsset(character)
	for _, o in character:GetDescendants() do
		if o.Name == "AdminAuraAsset" or (o:IsA("Accessory") and o:GetAttribute("AdminAuraAsset") == true) then
			o:Destroy()
		end
	end
end

local function attachAdminAuraAsset(character, humanoid, hrp)
	removeAdminAuraAsset(character)

	local templateAsset = getAdminAuraTemplate()
	if not templateAsset then
		return
	end

	local clone = templateAsset:Clone()
	clone.Name = "AdminAuraAsset"

	local accessories = {}
	for _, o in clone:GetDescendants() do
		if o:IsA("Accessory") then
			table.insert(accessories, o)
		end
	end
	for _, accessory in accessories do
		accessory.Parent = nil
		accessory:SetAttribute("AdminAuraAsset", true)
		humanoid:AddAccessory(accessory)
	end

	local hasParts = false
	for _, o in clone:GetDescendants() do
		if o:IsA("BasePart") then
			hasParts = true
			o.Anchored = false
			o.CanCollide = false
			o.CanTouch = false
			o.CanQuery = false
			o.Massless = true
		end
	end

	if hasParts then
		clone.Parent = character
		clone:PivotTo(hrp.CFrame)
		for _, part in clone:GetDescendants() do
			if part:IsA("BasePart") then
				local weld = Instance.new("WeldConstraint")
				weld.Name = "AdminAuraWeld"
				weld.Part0 = hrp
				weld.Part1 = part
				weld.Parent = part
			end
		end
	else
		local attachment = Instance.new("Attachment")
		attachment.Name = "AdminAuraAsset"
		attachment.Parent = hrp
		for _, o in clone:GetDescendants() do
			if o:IsA("ParticleEmitter") or o:IsA("Beam") or o:IsA("Trail") then
				o.Parent = attachment
			end
		end
		clone:Destroy()
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
	local isOwner = p.UserId == OWNER_USER_ID
	local pharaoh = not isOwner and p:GetAttribute("Pharaoh") == true
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
			if not pharaoh and not isOwner and a.AccessoryType == Enum.AccessoryType.Hair then
				table.insert(keep, a)
			end
		end
		desc:SetAccessories(keep, true)
		if pharaoh or isOwner then
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
			if c:IsA("Shirt") or c:IsA("Pants") or c:IsA("ShirtGraphic") or c.Name == "PharaohStaff" or c.Name == "AdminStaff" then
				c:Destroy()
			end
		end
		if pharaoh or isOwner then
			local shirt = Instance.new("Shirt")
			shirt.Name = isOwner and "AdminShirt" or "PharaohShirt"
			shirt.ShirtTemplate = PHARAOH.Shirt
			shirt.Parent = ch
			local pants = Instance.new("Pants")
			pants.Name = isOwner and "AdminPants" or "PharaohPants"
			pants.PantsTemplate = PHARAOH.Pants
			pants.Parent = ch
			local staff = RS:FindFirstChild("PyramidHUD") and RS.PyramidHUD:FindFirstChild("PharaohStaff")
			if staff then
				local clone = staff:Clone()
				clone.Name = isOwner and "AdminStaff" or "PharaohStaff"
				hum:AddAccessory(clone)
			end
		else
			local kilt = Instance.new("Pants")
			kilt.Name = "WorkerKilt"
			kilt.PantsTemplate = KILT
			kilt.Parent = ch
		end
		if isOwner then
			aura(hrp, "admin")
			adminHighlight(ch, true)
			attachAdminAuraAsset(ch, hum, hrp)
		elseif pharaoh then
			aura(hrp, "pharaoh")
			adminHighlight(ch, false)
		else
			aura(hrp, nil)
			adminHighlight(ch, false)
			removeAdminAuraAsset(ch)
		end
	end
	dressing[ch] = nil
	if ch.Parent and not isOwner and (p:GetAttribute("Pharaoh") == true) ~= pharaoh then
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
