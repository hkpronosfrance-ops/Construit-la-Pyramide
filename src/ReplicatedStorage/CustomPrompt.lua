local S={}
function S.start(options)
 options=options or {}
 local Players=game:GetService("Players")
 local PPS=game:GetService("ProximityPromptService")
 local UIS=game:GetService("UserInputService")
 local Run=game:GetService("RunService")
 local p=Players.LocalPlayer
 local pg=p:WaitForChild("PlayerGui")
 local root=pg:WaitForChild("CustomInteractionUI")
 if root:GetAttribute("Started") then return end
 root:SetAttribute("Started",true)
 local template=root:WaitForChild("PromptTemplate")
 template.Visible=false
 local function colour(name,fallback) local v=template:GetAttribute(name) return typeof(v)=="Color3" and v or fallback end
 local KEY_IDLE,KEY_FULL=colour("KeyIdle",Color3.fromRGB(59,79,74)),colour("KeyFull",Color3.fromRGB(96,214,84))
 local DISK_IDLE,DISK_HOLD=colour("DiskIdle",Color3.fromRGB(21,39,40)),colour("DiskHold",Color3.fromRGB(59,119,73))
 local actionY=template.Content.Action.Position.Y.Offset
 local objectGap=actionY-template.Content.Object.Position.Y.Offset-16
 local shown={}
 local function matches(prompt)
  return not options.Attribute or prompt:GetAttribute(options.Attribute)
 end
 local function hide(prompt)
  local v=shown[prompt] if not v then return end shown[prompt]=nil
  if v.Pointer then v.Pointer=nil prompt:InputHoldEnd() end
  for _,c in v.Connections do c:Disconnect() end
  v.Gui:Destroy()
 end
 local function show(prompt,inputType)
  if not matches(prompt) then return end
  hide(prompt)
  local parent=prompt.Parent
  local adornee=parent
  if parent and parent:IsA("Model") then adornee=parent.PrimaryPart or parent:FindFirstChildWhichIsA("BasePart",true) end
  if not adornee then return end
  local bill=template:Clone() bill.Name="Prompt_"..prompt.Name bill:SetAttribute("IsTemplate",nil)
  local scale=bill:FindFirstChildOfClass("UIScale") or Instance.new("UIScale",bill)
  local frame=bill:WaitForChild("Content")
  frame.Position=UDim2.fromOffset(prompt.UIOffset.X,prompt.UIOffset.Y)
  local disk=frame:WaitForChild("KeyBackground")
  local key=disk:WaitForChild("Interact")
  local keyText=key:WaitForChild("Key")
  local object=frame:WaitForChild("Object")
  local action=frame:WaitForChild("Action")
  object.Text=prompt.ObjectText
  action.Text=prompt.ActionText
  action.Position=UDim2.fromOffset(action.Position.X.Offset,prompt.ObjectText=="" and actionY-objectGap or actionY)
  local fill=key:FindFirstChild("HoldFill") or Instance.new("UIGradient") fill.Name="HoldFill" fill.Rotation=90 fill.Parent=key
  local keyScale=key:FindFirstChildOfClass("UIScale") or Instance.new("UIScale",key)
  local function setFill(amount)
   if amount<=0 then fill.Color=ColorSequence.new(KEY_IDLE) return end
   if amount>=1 then fill.Color=ColorSequence.new(KEY_FULL) return end
   local edge=math.clamp(1-amount,.002,.998)
   fill.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,KEY_IDLE),ColorSequenceKeypoint.new(edge-.001,KEY_IDLE),ColorSequenceKeypoint.new(edge,KEY_FULL),ColorSequenceKeypoint.new(1,KEY_FULL)})
  end
  setFill(0)
  disk.BackgroundColor3=DISK_IDLE
  bill.Visible=false
  bill.Parent=root
  local v={Gui=bill,Connections={},Pointer=nil,Started=nil} shown[prompt]=v
  local function connect(signal,fn) table.insert(v.Connections,signal:Connect(fn)) end
  local function updateKey(kind)
   if kind==Enum.ProximityPromptInputType.Touch or kind==Enum.UserInputType.Touch then keyText.Text="TAP" keyText.TextSize=16
   elseif kind==Enum.ProximityPromptInputType.Gamepad or tostring(kind):find("Gamepad") then keyText.Text=prompt.GamepadKeyCode.Name:gsub("Button","") keyText.TextSize=24
   else
    local text=UIS:GetStringForKeyCode(prompt.KeyboardKeyCode)
    keyText.Text=text~="" and text or prompt.KeyboardKeyCode.Name keyText.TextSize=#keyText.Text>2 and 16 or 28
   end
  end
  updateKey(inputType)
  connect(UIS.LastInputTypeChanged,updateKey)
  connect(prompt:GetPropertyChangedSignal("ActionText"),function() action.Text=prompt.ActionText end)
  connect(prompt:GetPropertyChangedSignal("ObjectText"),function() object.Text=prompt.ObjectText end)
  connect(prompt.PromptButtonHoldBegan,function() v.Started=os.clock() disk.BackgroundColor3=DISK_HOLD end)
  connect(prompt.PromptButtonHoldEnded,function() v.Started=nil setFill(0) disk.BackgroundColor3=DISK_IDLE end)
  connect(prompt.Triggered,function()
   v.Started=nil setFill(1)
   keyScale.Scale=1.15
   game:GetService("TweenService"):Create(keyScale,TweenInfo.new(.2,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1}):Play()
   task.delay(.2,function() if shown[prompt]==v then setFill(0) end end)
  end)
  local function release()
   if v.Pointer then v.Pointer=nil prompt:InputHoldEnd() end
  end
  connect(key.InputBegan,function(input)
   if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
    if not v.Pointer then v.Pointer=input prompt:InputHoldBegin() end
   end
  end)
  connect(UIS.InputEnded,function(input)
   if input==v.Pointer or input.UserInputType==Enum.UserInputType.MouseButton1 and v.Pointer and v.Pointer.UserInputType==Enum.UserInputType.MouseButton1 then release() end
  end)
  connect(UIS.WindowFocusReleased,release)
  connect(prompt.Destroying,function() hide(prompt) end)
  connect(Run.RenderStepped,function()
   local camera=workspace.CurrentCamera
   if not camera or not adornee:IsDescendantOf(workspace) then bill.Visible=false return end
   local position=adornee:IsA("Attachment") and adornee.WorldPosition or adornee.Position
   local target=position+Vector3.new(0,prompt.Parent and prompt.Parent:IsA("Seat") and .6 or 1.3,0)
   local point,visible=camera:WorldToViewportPoint(target)
   local distance=(camera.CFrame.Position-target).Magnitude
   bill.Visible=visible and distance<=(options.MaxCameraDistance or 30) bill.Position=UDim2.fromOffset(point.X,point.Y)
   scale.Scale=math.clamp(camera.ViewportSize.X/480,.7,1)*1.15*math.clamp(16/math.max(distance,1),.7,1)
   if v.Started and prompt.HoldDuration>0 then setFill(math.clamp((os.clock()-v.Started)/prompt.HoldDuration,0,1)) end
  end)
 end
 PPS.PromptShown:Connect(show)
 PPS.PromptHidden:Connect(hide)
 local function custom(v) if v:IsA("ProximityPrompt") and matches(v) then v.Style=Enum.ProximityPromptStyle.Custom end end
 workspace.DescendantAdded:Connect(custom)
 for _,v in workspace:GetDescendants() do custom(v) end
 local blocked=false
 local function menuOpen()
  if options.MenuOpen then return options.MenuOpen() end
  for _,g in pg:GetChildren() do
   if g~=root and g:IsA("ScreenGui") and g:GetAttribute("Open")==true then return true end
  end
  return false
 end
 Run.Heartbeat:Connect(function()
  local now=menuOpen()
  if now~=blocked then blocked=now PPS.Enabled=not now end
 end)
 p.CharacterRemoving:Connect(function() local list={} for prompt in shown do table.insert(list,prompt) end for _,prompt in list do hide(prompt) end end)
end
return S
