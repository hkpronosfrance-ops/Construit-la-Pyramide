local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local TEXTURE="rbxassetid://83003683602369"
local active={}
local function remove(character)
 local state=active[character]
 if state then for _,v in state.objects do v:Destroy() end;active[character]=nil end
end
local function add(character)
 if active[character] then return end
 local root=character:FindFirstChild("HumanoidRootPart")
 if not root then return end
 local state={objects={},emitters={},root=root,phase=0}
 active[character]=state
 local function keep(v) table.insert(state.objects,v);return v end
 local h=keep(Instance.new("Highlight"));h.Name="PharaohPurpleGlow";h.Adornee=character;h.FillColor=Color3.fromRGB(153,40,255)
 h.OutlineColor=Color3.fromRGB(229,155,255);h.FillTransparency=.94;h.OutlineTransparency=.72;h.DepthMode=Enum.HighlightDepthMode.Occluded;h.Parent=character
 for i=1,6 do
  local a=keep(Instance.new("Attachment"));a.Name="PharaohViolet"..i
  local angle=i*math.pi/3
  a.Position=Vector3.new(math.cos(angle)*1.05,-1.8+(i%3)*1.25,math.sin(angle)*1.05);a.Parent=root
  local p=Instance.new("ParticleEmitter");p.Name="PurpleRoyalFlame";p.Texture=TEXTURE
  p.Color=ColorSequence.new(Color3.fromRGB(153,55,255),Color3.fromRGB(106,20,230))
  p.Rate=2;p.Lifetime=NumberRange.new(.7,1.1);p.Speed=NumberRange.new(.15,.4)
  p.Acceleration=Vector3.new(0,.3,0);p.Drag=1.5;p.SpreadAngle=Vector2.new(20,20)
  p.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.5),NumberSequenceKeypoint.new(.25,1.3),NumberSequenceKeypoint.new(.65,1.6),NumberSequenceKeypoint.new(1,1)})
  p.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.16,.78),NumberSequenceKeypoint.new(.6,.88),NumberSequenceKeypoint.new(1,1)})
  p.Rotation=NumberRange.new(0,360);p.RotSpeed=NumberRange.new(-25,25)
  p.LightEmission=.4;p.LightInfluence=0;p.LockedToPart=true;p.Parent=a
  table.insert(state.emitters,p)
 end
 local light=keep(Instance.new("PointLight"));light.Name="PharaohPurpleLight";light.Color=Color3.fromRGB(171,62,255);light.Brightness=.3;light.Range=6;light.Shadows=false;light.Parent=root
end
local function watch(player)
 local function refresh()
  local ch=player.Character;if not ch then return end
  if player:GetAttribute("Pharaoh")==true then add(ch) else remove(ch) end
 end
 player:GetAttributeChangedSignal("Pharaoh"):Connect(refresh)
 player.CharacterAdded:Connect(function(ch)
  ch:WaitForChild("HumanoidRootPart",15)
  if player.Character==ch then refresh() end
 end)
 player.CharacterRemoving:Connect(remove)
 refresh()
end
for _,p in Players:GetPlayers() do watch(p) end
Players.PlayerAdded:Connect(watch)
Players.PlayerRemoving:Connect(function(p) if p.Character then remove(p.Character) end end)
task.spawn(function()
 local map=workspace:WaitForChild("PyramidMap")
 local ph=map:FindFirstChild("Pharaoh")
 if not ph then return end
 local npc=ph:FindFirstChild("PharaohNPC")
 if not npc or not npc:FindFirstChild("HumanoidRootPart") then return end
 add(npc)
end)
local timer=0
RunService.Heartbeat:Connect(function(dt)
 timer+=dt;if timer<.1 then return end;timer=0
 local camera=workspace.CurrentCamera
 for ch,state in active do
  if not ch.Parent then remove(ch) else
   local near=camera and (camera.CFrame.Position-state.root.Position).Magnitude<160
   local low=game:GetService("Players").LocalPlayer:GetAttribute("LowEffects")==true
   for _,p in state.emitters do p.Enabled=near and not low end
  end
 end
end)
