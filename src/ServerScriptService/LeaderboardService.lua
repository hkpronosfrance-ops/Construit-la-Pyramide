local Players=game:GetService("Players")
local DS=game:GetService("DataStoreService")
local Run=game:GetService("RunService")
local Http=game:GetService("HttpService")
local Config=require(game.ReplicatedStorage.BobloxLeaderboards.Config)
local M={} local states={} local names={} local stores={} local closing=false
local live=not Run:IsStudio()
local function number(v)
 v=tonumber(v) or 0
 if v~=v or v==math.huge or v==-math.huge then return 0 end
 return math.clamp(math.floor(v),0,9e15)
end
local function display(key,n)
 n=number(n)
 if Config.Format then return Config.Format(key,n) end
 if key=="Playtime" then
  if n<60 then return n.."s" end
  return n>=3600 and string.format("%dh %02dm",n//3600,(n%3600)//60) or (n//60).."m"
 end
 for _,u in {{1e12,"T"},{1e9,"B"},{1e6,"M"},{1e3,"K"}} do
  if n>=u[1] then return (string.format("%.1f",n/u[1]):gsub("%.0$",""))..u[2] end
 end
 return tostring(n)
end
local function measured(p,key)
 local attr=p:GetAttribute(key)
 local stats=p:FindFirstChild("leaderstats")
 local value=stats and stats:FindFirstChild(key)
 return number(attr or (value and value.Value))
end
local function update(p,s)
 for _,key in Config.Keys do
  local value
  if key=="Playtime" then value=s.base+math.floor(os.clock()-s.joined)
  else value=math.max(s.values[key] or 0,measured(p,key)) end
  s.values[key]=value
  p:SetAttribute("LeaderboardValue_"..key,display(key,value))
  if key=="Playtime" then p:SetAttribute("Playtime",value) end
 end
end
local function loadKey(p,s,key)
 if not live then s.loaded[key]=true return end
 local ok,value=pcall(function() return stores[key]:GetAsync(tostring(p.UserId)) end)
 if ok and states[p]==s then
  local saved=number(value)
  s.values[key]=math.max(s.values[key] or 0,saved)
  if key=="Playtime" then s.base=saved end
  s.loaded[key]=true
 end
end
local function load(p)
 if states[p] then return end
 local s={values={},loaded={},joined=os.clock(),base=0,saving=false}
 states[p]=s
 for _,key in Config.Keys do s.values[key]=0 loadKey(p,s,key) end
 if p.Parent then update(p,s) end
end
function M.save(p)
 local s=states[p] if not s then return end
 while s.saving do task.wait(.05) end
 s.saving=true update(p,s)
 if live then
  for _,key in Config.Keys do
   if not s.loaded[key] then loadKey(p,s,key) update(p,s) end
   if s.loaded[key] then
    local value=s.values[key]
    local ok,err=pcall(function()
     stores[key]:UpdateAsync(tostring(p.UserId),function(old) return math.max(number(old),value) end)
    end)
    if not ok then warn("Leaderboard save "..key..": "..tostring(err)) end
   end
  end
 end
 s.saving=false
end
function M.refresh()
 local boards=workspace[Config.MapName or "PyramidMap"].Leaderboards
 for _,key in Config.Keys do
  local entries={}
  local success=true
  if live then
   local ok,page=pcall(function() return stores[key]:GetSortedAsync(false,100,1):GetCurrentPage() end)
   success=ok
   if ok then
    for _,item in page do
     local id=tonumber(item.key)
     if id then table.insert(entries,{id=id,value=item.value}) end
    end
   end
  else
   for p,s in states do
    update(p,s)
    if s.values[key]>0 then table.insert(entries,{id=p.UserId,value=s.values[key],name=p.Name}) end
   end
   table.sort(entries,function(a,b) return a.value==b.value and a.id<b.id or a.value>b.value end)
  end
  if success then
   for p in states do p:SetAttribute("LeaderboardRank_"..key,nil) end
   local top={}
   for rank,e in entries do
    if rank>100 then break end
    local name=e.name or names[e.id]
    if not name then
     local ok,result=pcall(Players.GetNameFromUserIdAsync,Players,e.id)
     name=ok and result or ("Player "..e.id)
     if ok then names[e.id]=name end
    end
    table.insert(top,{userId=e.id,name=name,value=display(key,e.value)})
    local p=Players:GetPlayerByUserId(e.id)
    if p then p:SetAttribute("LeaderboardRank_"..key,rank) end
   end
   local board=boards:FindFirstChild("Leaderboard_"..key)
   if board then board:SetAttribute("Top",Http:JSONEncode(top)) board:SetAttribute("DataConnected",true) end
  end
 end
end
function M.start()
 if M.started then return end M.started=true
 for _,key in Config.Keys do if live then stores[key]=DS:GetOrderedDataStore(Config.StorePrefix..key) end end
 Players.PlayerAdded:Connect(function(p) task.spawn(load,p) end)
 Players.PlayerRemoving:Connect(function(p) M.save(p) states[p]=nil end)
 for _,p in Players:GetPlayers() do task.spawn(load,p) end
 task.spawn(function()
  while not closing do task.wait(1) for p,s in states do if p.Parent then update(p,s) end end end
 end)
 task.spawn(function()
  task.wait(3)
  while not closing do
   for p in states do M.save(p) end
   local ok,err=pcall(M.refresh) if not ok then warn(err) end
   task.wait(live and 90 or 5)
  end
 end)
 game:BindToClose(function()
  closing=true local pending=0
  for p in states do pending+=1 task.spawn(function() M.save(p) pending-=1 end) end
  local deadline=os.clock()+25
  while pending>0 and os.clock()<deadline do task.wait(.1) end
 end)
end
return M
