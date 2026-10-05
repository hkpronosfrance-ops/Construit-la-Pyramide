local gym=workspace:WaitForChild("PyramidMap"):WaitForChild("Gym")
local function apply(belt)
 if not (belt:IsA("BasePart") and belt.Name=="Belt" and belt.Parent.Name=="Treadmill") then return end
 local old=belt:FindFirstChild("BeltChevrons")
 if old and old:IsA("SurfaceGui") then return end
 if old then old:Destroy() end
 local gui=Instance.new("SurfaceGui")
 gui.Name="BeltChevrons"
 gui.Face=Enum.NormalId.Top
 gui.SizingMode=Enum.SurfaceGuiSizingMode.FixedSize
 gui.CanvasSize=Vector2.new(1440,640)
 local strip=Instance.new("Frame")
 strip.Name="Strip"
 strip.BackgroundTransparency=1
 strip.AnchorPoint=Vector2.new(.5,.5)
 strip.Position=UDim2.fromScale(.5,.5)
 strip.Size=UDim2.fromOffset(640,1440)
 strip.Rotation=90
 strip.Parent=gui
 gui.AlwaysOnTop=false
 gui.LightInfluence=0.4
 gui.MaxDistance=160
 gui.ClipsDescendants=true
 for row=0,3 do
  local image=Instance.new("ImageLabel")
  image.Name="Chevron"..(row+1)
  image.BackgroundTransparency=1
  image.Image="rbxassetid://120934602434599"
  image.ImageColor3=Color3.fromRGB(210,216,224)
  image.ImageTransparency=.88
  image.Size=UDim2.new(1,0,.25,0)
  image.Position=UDim2.fromScale(0,row*.25)
  image.Rotation=180
  image.ScaleType=Enum.ScaleType.Stretch
  image.Parent=strip
 end
 gui.Parent=belt
end
for _,v in gym:GetDescendants() do apply(v) end
gym.DescendantAdded:Connect(apply)
