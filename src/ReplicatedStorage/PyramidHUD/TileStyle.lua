local S = {}

S.Ink = Color3.fromRGB(20, 16, 28)
S.StudsImage = "rbxassetid://138926013267839"

local function corner(o, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	c.Parent = o
end

local function layer(parent, name, inset, colour, radius, z)
	local f = Instance.new("Frame")
	f.Name = name
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.fromScale(0.5, 0.5)
	f.Size = UDim2.new(1, -inset * 2, 1, -inset * 2)
	f.BackgroundColor3 = colour
	f.BorderSizePixel = 0
	f.Active = false
	f.ZIndex = z
	f.Parent = parent
	corner(f, radius)
	return f
end

local function lum(c)
	return 0.299 * c.R + 0.587 * c.G + 0.114 * c.B
end

function S.paint(host, rim, top, bottom)
	if rim ~= Color3.new(1, 1, 1) and lum(rim) > lum(bottom) * 0.72 then
		rim = bottom:Lerp(Color3.new(0, 0, 0), 0.4)
	end
	local border = layer(host, "TileBorder", 0, S.Ink, 14, 0)
	local rimLayer = layer(border, "TileRim", 2, rim, 12, 1)
	local fill = layer(rimLayer, "TileFill", 2, Color3.new(1, 1, 1), 10, 2)
	local grad = Instance.new("UIGradient")
	grad.Rotation = 90
	grad.Color = ColorSequence.new(top, bottom)
	grad.Parent = fill
	local studs = Instance.new("ImageLabel")
	studs.Name = "Studs"
	studs.BackgroundTransparency = 1
	studs.Active = false
	studs.Image = S.StudsImage
	studs.ScaleType = Enum.ScaleType.Tile
	studs.TileSize = UDim2.fromOffset(13, 13)
	studs.ImageTransparency = 0.3
	studs.Size = UDim2.fromScale(1, 1)
	studs.ZIndex = 3
	studs.Parent = fill
	corner(studs, 10)
	return border, rimLayer, fill
end

local function styleLabel(label)
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.BackgroundTransparency = 1
	local st = label:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
	st.Thickness = 3
	st.Color = S.Ink
	st.LineJoinMode = Enum.LineJoinMode.Round
	st.Parent = label
	local limit = label:FindFirstChildOfClass("UITextSizeConstraint")
	if limit then
		limit.MaxTextSize = 30
	end
end

function S.tile(button, def)
	local size = def.Size or 100
	button.Image = ""
	button.BackgroundTransparency = 1
	button.Size = UDim2.fromOffset(size, size)
	local _, _, fill = S.paint(button, def.Rim, def.Top, def.Bottom)

	local icon = Instance.new("ImageLabel")
	icon.Name = "TileIcon"
	icon.BackgroundTransparency = 1
	icon.Active = false
	icon.Image = def.Icon
	icon.ScaleType = Enum.ScaleType.Fit
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.fromScale(0.5, 0.5)
	local k = def.IconScale or 1
	icon.Size = UDim2.new(k, -6, k, -6)
	icon.ZIndex = 4
	icon.Parent = fill

	local caption = button:FindFirstChild("Caption") or Instance.new("TextLabel")
	caption.Name = "Caption"
	caption.Text = def.Text
	caption.AnchorPoint = Vector2.new(0.5, 1)
	caption.Position = UDim2.new(0.5, 0, 1, 7)
	caption.Size = UDim2.new(1, def.LabelGrow or 16, 0, 30)
	caption.ZIndex = 8
	caption.Parent = button
	styleLabel(caption)
	return fill, icon, caption
end

function S.card(b, rim, top, bottom)
	b.BackgroundTransparency = 1
	local stroke = b:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Enabled = false
	end
	for _, name in { "Bevel", "Underside", "SurfaceStuds" } do
		local o = b:FindFirstChild(name)
		if o then
			o.Visible = false
		end
	end
	local shadow = b.Parent and b.Parent:FindFirstChild(b.Name .. "_Shadow")
	if shadow then
		shadow.BackgroundTransparency = 1
	end
	local border, rimLayer, fill = S.paint(b, rim, top, bottom)
	for _, crop in b:GetChildren() do
		if crop:IsA("CanvasGroup") then
			crop.Position = UDim2.fromOffset(4, 4)
			crop.Size = UDim2.new(1, -8, 1, -8)
			local c = crop:FindFirstChildOfClass("UICorner")
			if c then
				c.CornerRadius = UDim.new(0, 10)
			end
		end
		if crop:IsA("TextLabel") then
			local st = crop:FindFirstChildOfClass("UIStroke")
			if st then
				st.Color = S.Ink
			end
		end
	end
	return border, rimLayer, fill
end

function S.linkOutlines(root)
	local function link(holder)
		local icon = holder:FindFirstChild("Icon")
		if not (icon and icon:IsA("ImageLabel")) then
			return
		end
		local function sync()
			for _, o in holder:GetChildren() do
				if o.Name == "Outline" and o:IsA("ImageLabel") then
					o.Image = icon.Image
				end
			end
		end
		icon:GetPropertyChangedSignal("Image"):Connect(sync)
		sync()
	end
	for _, d in root:GetDescendants() do
		if d:FindFirstChild("Outline") then
			link(d)
		end
	end
end

return S
