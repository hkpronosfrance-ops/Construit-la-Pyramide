local Players=game:GetService("Players")
local Run=game:GetService("RunService")
local M={}
function M.Start(F)
 local C=require(F.Config) local R=F.Remote local DS=game:GetService("DataStoreService"):GetDataStore(C.StoreName)
 local live=not Run:IsStudio() local states={}
 local function clean(key,value)
  local d=C.Defaults[key] if d==nil or type(d)~=type(value) then return nil end
  if type(value)=="number" then if value~=value or math.abs(value)==math.huge then return nil end local r=C.Ranges and C.Ranges[key] return math.clamp(value,r and r[1] or 0,r and r[2] or 1) end
  return value
 end
 local function save(p,s)
  if not s.ready or s.saving or s.version==s.saved then return end
  s.saving=true local version=s.version local copy=table.clone(s.data)
  local ok=true if live then ok=pcall(function() DS:UpdateAsync(tostring(p.UserId),function() return copy end) end) end
  if ok then s.saved=version elseif p.Parent then R:FireClient(p,"error","Settings could not be saved. Retrying.") end
  s.saving=false
 end
 local function added(p)
  local s={data=table.clone(C.Defaults),ready=false,version=0,saved=0,last=-10} states[p]=s
  task.spawn(function()
   while p.Parent and not s.ready do
    local ok,d=true,nil if live then ok,d=pcall(function() return DS:GetAsync(tostring(p.UserId)) end) end
    if ok then
     if type(d)=="table" then for k,v in d do local value=clean(k,v) if value~=nil then s.data[k]=value end end end
     s.ready=true R:FireClient(p,"state",s.data)
    else task.wait(5) end
   end
  end)
 end
 R.OnServerEvent:Connect(function(p,action,key,value)
  local s=states[p] if not s or not s.ready then return end
  if os.clock()-s.last<.08 then return end s.last=os.clock()
  if action=="get" then R:FireClient(p,"state",s.data) return end
  if action~="set" or type(key)~="string" then return end
  local valid=clean(key,value) if valid==nil then return end
  s.data[key]=valid s.version+=1 R:FireClient(p,"state",s.data)
 end)
 Players.PlayerAdded:Connect(added) for _,p in Players:GetPlayers() do added(p) end
 Players.PlayerRemoving:Connect(function(p) local s=states[p] if s then while s.saving do task.wait(.1) end save(p,s) end states[p]=nil end)
 task.spawn(function() while task.wait(5) do for p,s in states do task.spawn(save,p,s) end end end)
 game:BindToClose(function() local remaining=0 for p,s in states do remaining+=1 task.spawn(function() while s.saving do task.wait(.1) end save(p,s) remaining-=1 end) end local deadline=os.clock()+25 while remaining>0 and os.clock()<deadline do task.wait(.1) end end)
end
return M
