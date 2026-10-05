local M={}
local Tween=game:GetService("TweenService")
function M.Create(pg)
 local screen=pg:WaitForChild("GameTopbar",10)
 if not screen then
  screen=Instance.new("ScreenGui") screen.Name="GameTopbar" screen.ResetOnSpawn=false
  screen.ScreenInsets=Enum.ScreenInsets.TopbarSafeInsets screen.DisplayOrder=75 screen.Parent=pg
 end
 local function build(name,icon,side)
  local b=Instance.new("ImageButton") b.Name=name b.Image="" b.AutoButtonColor=false b.BackgroundColor3=Color3.fromRGB(18,18,21) b.BackgroundTransparency=.3 b.BorderSizePixel=0
  b.AnchorPoint=Vector2.new(side=="Right" and 1 or 0,.5) b.Position=UDim2.new(side=="Right" and 1 or 0,side=="Right" and -8 or 8,.5,5) b.Size=UDim2.fromOffset(44,44) b.Parent=screen
  Instance.new("UICorner",b).CornerRadius=UDim.new(1,0)
  local img=Instance.new("ImageLabel") img.Name="Icon" img.BackgroundTransparency=1 img.Image=icon img.ScaleType=Enum.ScaleType.Fit img.AnchorPoint=Vector2.new(.5,.5) img.Position=UDim2.fromScale(.5,.5) img.Size=UDim2.fromScale(.64,.64) img.Parent=b
  local tip=Instance.new("TextLabel") tip.Name="Tooltip" tip.BackgroundColor3=Color3.fromRGB(18,18,21) tip.BackgroundTransparency=.15 tip.Text=name tip.Font=Enum.Font.GothamBold tip.TextSize=14 tip.TextColor3=Color3.new(1,1,1) tip.Size=UDim2.fromOffset(88,28) tip.AnchorPoint=Vector2.new(.5,0) tip.Position=UDim2.new(.5,0,1,8) tip.Visible=false tip.Parent=b Instance.new("UICorner",tip).CornerRadius=UDim.new(0,8)
  return b
 end
 local function add(name,icon,side,callback)
  local b=screen:FindFirstChild(name) or build(name,icon,side)
  local tip=b:FindFirstChild("Tooltip")
  local rest,restAlpha=b.BackgroundColor3,b.BackgroundTransparency
  local hover=rest:Lerp(Color3.new(1,1,1),.15)
  b.MouseEnter:Connect(function() if tip then tip.Visible=true end Tween:Create(b,TweenInfo.new(.1),{BackgroundTransparency=math.max(0,restAlpha-.15),BackgroundColor3=hover}):Play() end)
  b.MouseLeave:Connect(function() if tip then tip.Visible=false end Tween:Create(b,TweenInfo.new(.1),{BackgroundTransparency=restAlpha,BackgroundColor3=rest}):Play() end)
  b.Activated:Connect(callback)
  return b
 end
 return {Gui=screen,Add=add}
end
return M
