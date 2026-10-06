local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local SoundService=game:GetService("SoundService")
local RunService=game:GetService("RunService")
local LocalizationService=game:GetService("LocalizationService")
local folder=script.Parent
local C=require(folder.Config)
local remote=folder.Remote
local T=require(C.Theme)
local p=Players.LocalPlayer
local M={}
local rgb=Color3.fromRGB
local isFrench=RunService:IsStudio()
if not isFrench then
 local ok,locale=pcall(function() return LocalizationService.RobloxLocaleId end)
 if ok and type(locale)=="string" then isFrench=string.sub(string.lower(locale),1,2)=="fr" end
end
local FR_TEXT={
 ["Settings"]="Paramètres",
 ["Music"]="Musique",
 ["MUSIC"]="MUSIQUE",
 ["Sound Effects"]="Effets sonores",
 ["SOUND EFFECTS"]="EFFETS SONORES",
 ["Volume"]="Volume",
 ["VOLUME"]="VOLUME",
 ["Max Speed"]="Vitesse max",
 ["MAX SPEED"]="VITESSE MAX",
 ["Low Effects"]="Effets réduits",
 ["LOW EFFECTS"]="EFFETS RÉDUITS",
}
local localizedTextConnections=setmetatable({},{__mode="k"})
local function localizeText(root)
 if not isFrench then return end
 local function apply(o)
  if not (o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox")) then return end
  local function refresh()
   local t=FR_TEXT[o.Text]
   if t and o.Text~=t then o.Text=t end
  end
  refresh()
  if not localizedTextConnections[o] then
   localizedTextConnections[o]=o:GetPropertyChangedSignal("Text"):Connect(refresh)
  end
 end
 apply(root)
 for _,o in root:GetDescendants() do apply(o) end
 root.DescendantAdded:Connect(apply)
end
local S=table.clone(C.Defaults)
local baseVolume=setmetatable({},{__mode="k"})
local dimmed=setmetatable({},{__mode="k"})
local built,panel,backdrop
local controls={}
local rowsByKey={}
local function isMusic(s) return s:GetAttribute("Music")==true or s.Name:lower():find("music")~=nil end
local function applySound(s)
 if baseVolume[s]==nil then baseVolume[s]=s.Volume end
 local music=isMusic(s)
 local on=(music and S.Music) or ((not music) and S.SFX)
 s.Volume=baseVolume[s]*(on and math.clamp(S.Volume,0,1) or 0)
end
local function effectOff(o)
 if (o:IsA("ParticleEmitter") or o:IsA("Beam") or o:IsA("Trail")) and o.Enabled then o.Enabled=false dimmed[o]=true end
end
local function hook(o)
 if o:IsA("Sound") then applySound(o) elseif S.LowEffects then effectOff(o) end
end
local function applyAll()
 for s in baseVolume do if s.Parent then applySound(s) end end
 p:SetAttribute("LowEffects",S.LowEffects==true) p:SetAttribute("StrengthPopups",S.StrengthPopups~=false)
 if S.LowEffects then
  for _,o in workspace:GetDescendants() do effectOff(o) end
 else
  for o in dimmed do if o.Parent then o.Enabled=true end end
  table.clear(dimmed)
 end
 for key,fn in controls do fn(S[key]) end
end
local function open(value)
 panel.Visible=value backdrop.Visible=value panel.Parent:SetAttribute("Open",value)
 if value then require(C.Admin).toggle(false) end
end
local function attrOr(o,name,fallback) local v=o:GetAttribute(name) if v==nil then return fallback end return v end
local function toggle(r,key)
 local b=r:FindFirstChild("Toggle") if not b then return end
 b.Activated:Connect(function()
  local value=not S[key]
  remote:FireServer("set",key,value)
  S[key]=value applyAll()
 end)
 controls[key]=function(v)
  b.Text=v and attrOr(b,"OnText","ON") or attrOr(b,"OffText","OFF")
  local g=b:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient")
  g.Rotation=90
  g.Color=v and ColorSequence.new(attrOr(b,"OnTop",rgb(71,255,72)),attrOr(b,"OnBase",rgb(25,220,45)))
   or ColorSequence.new(attrOr(b,"OffTop",rgb(255,93,93)),attrOr(b,"OffBase",rgb(226,41,41)))
  g.Parent=b
 end
end
local function volume(r)
 local value=r:FindFirstChild("Value")
 local function step(name,delta)
  local b=r:FindFirstChild(name) if not b then return end
  b.Activated:Connect(function()
   local v=math.clamp(math.floor((S.Volume+delta)*10+.5)/10,0,1)
   S.Volume=v remote:FireServer("set","Volume",v) applyAll()
  end)
 end
 step("Minus",-.1) step("Plus",.1)
 controls.Volume=function(v)
  if value then value.Text=string.format(attrOr(value,"Format","%d%%"),math.floor((tonumber(v) or 0)*100+.5)) end
 end
end
local function slider(r,def)
 local key=def.Key
 local value=r:FindFirstChild("ValueBox") and r.ValueBox:FindFirstChild("Value")
 local track=r:FindFirstChild("Track") if not track then return end
 local fill=track:FindFirstChild("Fill")
 local knob=track:FindFirstChild("Knob")
 local function range() local lo,hi=def.Range(p) lo=tonumber(lo) or 0 hi=math.max(lo,tonumber(hi) or lo) return lo,hi end
 local function show(v)
  local lo,hi=range()
  local cur=(v==0 or v>=hi) and hi or math.clamp(v,lo,hi)
  local k=hi>lo and (cur-lo)/(hi-lo) or 1
  if knob then knob.Position=UDim2.new(k,0,.5,0) end
  if fill then fill.Size=UDim2.fromScale(k,1) end
  if value then value.Text=def.Format and def.Format(cur) or tostring(math.floor(cur+.5)) end
  p:SetAttribute("Setting_"..key,v)
 end
 controls[key]=show
 local dragging=false
 local function at(x)
  local lo,hi=range()
  local k=math.clamp((x-track.AbsolutePosition.X)/math.max(1,track.AbsoluteSize.X),0,1)
  local v=lo+(hi-lo)*k
  if k>=.995 or hi<=lo then v=0 else v=math.floor(v+.5) if v>=hi then v=0 end end
  S[key]=v show(v)
 end
 local function begin(input)
  if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=true at(input.Position.X) end
 end
 track.InputBegan:Connect(begin)
 if knob then knob.InputBegan:Connect(begin) end
 local hit=r:FindFirstChild("TrackHit") if hit then hit.InputBegan:Connect(begin) end
 UIS.InputChanged:Connect(function(input)
  if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then at(input.Position.X) end
 end)
 UIS.InputEnded:Connect(function(input)
  if dragging and (input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch) then
   dragging=false remote:FireServer("set",key,S[key])
  end
 end)
 if def.Watch then p:GetAttributeChangedSignal(def.Watch):Connect(function() show(S[key]) end) end
end
local function wirePanel(gui)
 localizeText(gui)
 backdrop=gui:WaitForChild("Backdrop")
 panel=gui:WaitForChild("Settings")
 panel.Visible=false backdrop.Visible=false
 local scale=panel:FindFirstChildOfClass("UIScale") or Instance.new("UIScale") scale.Parent=panel
 local W,H=panel.Size.X.Offset,panel.Size.Y.Offset
 local function resize() local v=workspace.CurrentCamera.ViewportSize if v.X<100 or v.Y<100 then return end scale.Scale=math.min(.8,(v.X-24)/W,(v.Y-40)/H) end
 resize() workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
 T.adoptWindow(panel)
 local close=panel:WaitForChild("Header"):WaitForChild("Close")
 close.Activated:Connect(function() open(false) end)
 backdrop.Activated:Connect(function() if C.CloseOnBackdrop~=false then open(false) end end)
 local sliders={}
 for _,def in C.Sliders or {} do sliders[def.Key]=def end
 for _,r in panel:GetDescendants() do
  local key=r:GetAttribute("SettingKey")
  if type(key)=="string" then
   rowsByKey[key]=r
   if sliders[key] then slider(r,sliders[key])
   elseif key=="Volume" then volume(r)
   elseif C.Defaults[key]~=nil then toggle(r,key) end
  end
 end
end
local function cornerButtons(pg)
 local bar=require(C.Topbar).Create(pg)
 bar.Add("Settings",C.SettingsIcon,"Left",function() open(not panel.Visible) end)
 local admin=bar.Add("Admin",C.AdminIcon,C.AdminSide or "Right",function() open(false) require(C.Admin).toggle() end)
 admin.Visible=false
 task.spawn(function()
  local g=pg:WaitForChild("AdminPanel")
  local function sync() admin.Visible=g:GetAttribute("Authorized")==true if g:GetAttribute("Open") then open(false) end end
  g:GetAttributeChangedSignal("Authorized"):Connect(sync) g:GetAttributeChangedSignal("Open"):Connect(sync) sync()
 end)
end
function M.start()
 if built then return M end built=true
 local pg=p:WaitForChild("PlayerGui")
 local settingsPanel=pg:WaitForChild("SettingsPanel",30)
 if not settingsPanel then return M end
 wirePanel(settingsPanel)
 cornerButtons(pg)
 workspace.DescendantAdded:Connect(hook) pg.DescendantAdded:Connect(hook) SoundService.DescendantAdded:Connect(hook)
 for _,o in SoundService:GetDescendants() do hook(o) end
 for _,o in workspace:GetDescendants() do if o:IsA("Sound") then hook(o) end end
 remote.OnClientEvent:Connect(function(kind,data)
  if kind=="state" and type(data)=="table" then
   for k,v in data do if C.Defaults[k]~=nil and type(v)==type(C.Defaults[k]) then S[k]=v end end
   applyAll()
  end
 end)
 UIS.InputBegan:Connect(function(input,processed) if not processed and input.KeyCode==Enum.KeyCode.Escape and panel.Visible then open(false) end end)
 applyAll()
 remote:FireServer("get")
 return M
end
function M.toggle() M.start() open(not panel.Visible) end
function M.open(key)
 M.start() open(true)
 local r=key and rowsByKey[key]
 if not r then return end
 local old=r:FindFirstChild("Flash") if old then old:Destroy() end
 local f=Instance.new("Frame") f.Name="Flash" f.Size=UDim2.fromScale(1,1) f.BackgroundColor3=Color3.new(1,1,1) f.BackgroundTransparency=1 f.BorderSizePixel=0 f.ZIndex=r.ZIndex+5 f.Parent=r
 local corner=r:FindFirstChildOfClass("UICorner") if corner then Instance.new("UICorner",f).CornerRadius=corner.CornerRadius end
 task.spawn(function()
  local TS=game:GetService("TweenService")
  for _=1,2 do
   f.BackgroundTransparency=.55
   local t=TS:Create(f,TweenInfo.new(.45,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundTransparency=1}) t:Play() t.Completed:Wait()
  end
  f:Destroy()
 end)
end
return M
