local RunService = game:GetService("RunService")
local pads = workspace:WaitForChild("PyramidMap"):WaitForChild("Gym"):WaitForChild("Pads")
local old = workspace:FindFirstChild("GymZoneParticles")
if old then old:Destroy() end
local folder = Instance.new("Folder")
folder.Name = "GymZoneParticles"
folder.Parent = workspace
local profiles = {
 Region_FREE={6,.65}, Region_2x={8,.75}, Region_5x={9,.9},
 Region_10x={10,1}, Region_25x={11,.85}, Region_50x={12,1},
 Region_75x={13,.95}, Region_100x={14,1.1}, Region_ADMIN={17,1.2},
}
local entries = {}
local function install(region)
 if entries[region] then return end
 local zone = region:FindFirstChild("TrainZone")
 if not (zone and zone:IsA("BasePart")) then return end
 local profile = profiles[region.Name] or {8,.8}
 local p = Instance.new("Part")
 p.Name = region.Name
 p.Anchored = true
 p.Transparency = 1
 p.CanCollide = false
 p.CanTouch = false
 p.CanQuery = false
 p.CastShadow = false
 p.Size = Vector3.new(math.max(1,zone.Size.X-3),.2,math.max(1,zone.Size.Z-3))
 p.CFrame = zone.CFrame * CFrame.new(0,-zone.Size.Y/2+.7,0)
 p.Parent = folder
 local emitters = {}
 for layer=1,2 do
  local e=Instance.new("ParticleEmitter")
  e.Name=layer==1 and "FloatingSparkles" or "FineMotes"
  e.Texture="rbxassetid://136760378165719"
  e.Color=ColorSequence.new(zone.Color,zone.Color:Lerp(Color3.new(1,1,1),.28))
  e.LightEmission=.7
  e.LightInfluence=0
  e.Rate=layer==1 and profile[1] or profile[1]*.65
  e.Lifetime=NumberRange.new(3.5,5.5)
  e.Speed=NumberRange.new(.45,.9)
  e.Acceleration=Vector3.new(.06,.08,.03)
  e.Drag=.3
  e.SpreadAngle=Vector2.new(12,12)
  e.EmissionDirection=Enum.NormalId.Top
  e.Rotation=NumberRange.new(0,360)
  e.RotSpeed=NumberRange.new(-20,20)
  e.LockedToPart=false
  local size=profile[2]*(layer==1 and 1 or .36)
  e.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(.18,size),NumberSequenceKeypoint.new(.7,size*.7),NumberSequenceKeypoint.new(1,0)})
  e.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.15,.2),NumberSequenceKeypoint.new(.65,.35),NumberSequenceKeypoint.new(1,1)})
  e.Parent=p
  table.insert(emitters,e)
 end
 entries[region]={part=p,zone=zone,emitters=emitters}
end
for _,region in pads:GetChildren() do task.spawn(function() region:WaitForChild("TrainZone",30) install(region) end) end
pads.ChildAdded:Connect(function(region) task.defer(function() region:WaitForChild("TrainZone",15) install(region) end) end)
local elapsed=0
RunService.Heartbeat:Connect(function(dt)
 elapsed+=dt
 if elapsed<.5 then return end
 elapsed=0
 local camera=workspace.CurrentCamera
 for region,data in entries do
  if not region:IsDescendantOf(pads) then data.part:Destroy() entries[region]=nil
  else
   local near=camera and (camera.CFrame.Position-data.part.Position).Magnitude<220
   for _,e in data.emitters do
    e.Enabled=(not not near) and game:GetService("Players").LocalPlayer:GetAttribute("LowEffects")~=true
    e.Color=ColorSequence.new(data.zone.Color,data.zone.Color:Lerp(Color3.new(1,1,1),.28))
   end
  end
 end
end)
