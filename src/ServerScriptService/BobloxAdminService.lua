local Players=game:GetService("Players")
local Run=game:GetService("RunService")
local DS=game:GetService("DataStoreService")
local TextService=game:GetService("TextService")
local Http=game:GetService("HttpService")
local M={}
function M.Start(folder,adapter)
 local C=require(folder.Config) local remote=folder.Remote
 local live=not Run:IsStudio()
 local bans=live and DS:GetDataStore(C.StorePrefix.."_Bans") or nil
 local auditStore=live and DS:GetDataStore(C.StorePrefix.."_Audit") or nil
 local cache,rates,busy,history,memoryBans={},{},{},{},{}
 local function authorized(p)
  if not p then return false end
  if cache[p.UserId]~=nil then return cache[p.UserId] end
  local yes=table.find(C.UserIds,p.UserId)~=nil or (C.StudioAlwaysAdmin and Run:IsStudio())
  if not yes and (C.GroupId or 0)>0 then local ok,rank=pcall(p.GetRankInGroup,p,C.GroupId) yes=ok and rank>=(C.MinRank or 255) end
  cache[p.UserId]=yes==true return yes==true
 end
 local function roster()
  local list={}
  for _,p in Players:GetPlayers() do table.insert(list,{userId=p.UserId,name=p.Name,coins=p:GetAttribute("Coins") or 0,strength=p:GetAttribute("Strength") or 0}) end
  table.sort(list,function(a,b) return a.name:lower()<b.name:lower() end) return list
 end
 local ctx={}
 function ctx.number(value,min,max,integer)
  local s=tostring(value or ""):gsub("[%s,$]",""):upper()
  local base,suffix=s:match("^(%d*%.?%d+)([KMBT]?)$")
  local n=base and tonumber(base)
  if n and suffix~="" then n*=({K=1e3,M=1e6,B=1e9,T=1e12})[suffix] end
  assert(n and n==n and n>=min and n<=max and (not integer or n%1==0),"Enter a valid number from "..min.." to "..max..".")
  return n
 end
 function ctx.player(name)
  assert(type(name)=="string","Select a player first.")
  for _,p in Players:GetPlayers() do if p.Name:lower()==name:lower() or tostring(p.UserId)==name then return p end end
  error("Player has left or the username is not exact.")
 end
 local function audit(p,line,result)
  local record={At=os.time(),Actor=p.UserId,Name=p.Name,Command=line,Result=result,JobId=game.JobId}
  table.insert(history,os.date("!%H:%M:%S").." "..p.Name.." | "..line.." | "..result)
  if #history>60 then table.remove(history,1) end
  print("[Admin] "..history[#history])
  if live then task.spawn(function()
   local ok=pcall(function() auditStore:SetAsync(tostring(record.At).."_"..Http:GenerateGUID(false),record) end)
   if not ok then warn("[Admin] Audit persistence failed; entry remains in server output.") end
  end) end
 end
 local function filtered(p,text)
  assert(#text>0 and #text<=180,"Message must contain 1–180 characters.")
  local ok,value=pcall(function() return TextService:FilterStringAsync(text,p.UserId):GetNonChatStringForBroadcastAsync() end)
  assert(ok,"Roblox text filtering is unavailable. Nothing was sent.") return value
 end
 local function execute(p,line)
  local args={} for word in line:gmatch("%S+") do table.insert(args,word) end
  assert(table.remove(args,1)==C.Prefix,"Invalid command prefix.")
  local action=(table.remove(args,1) or ""):lower()
  if action=="roster" then return "Player list refreshed." end
  if action=="audit" then remote:FireClient(p,"audit",history) return "Recent server actions loaded." end
  if action=="announce" then
   local text=filtered(p,table.concat(args," "))
   remote:FireAllClients("announce",{text=text,fromName=p.Name,fromUserId=p.UserId}) return "Announcement sent to this server."
  end
  if action=="kick" or action=="ban" then
   local target=ctx.player(args[1]) assert(not authorized(target),"Cannot moderate an administrator.")
   if action=="ban" then
    local record={At=os.time(),Actor=p.UserId}
    if live then local ok=pcall(function() bans:SetAsync(tostring(target.UserId),record) end) assert(ok,"Ban could not be saved. Player was not kicked.")
    else memoryBans[target.UserId]=record end
   end
   target:Kick(action=="ban" and "You are banned from this experience." or "You were removed by an administrator.")
   return action.." saved for "..target.Name..(live and "" or " (Studio test only)")
  end
  if action=="unban" then
   local id=ctx.number(args[1],1,1e15,true)
   if live then local ok=pcall(function() bans:RemoveAsync(tostring(id)) end) assert(ok,"Unban could not be saved.")
   else memoryBans[id]=nil end
   return "Unbanned "..id..(live and "" or " (Studio test only)")
  end
  return adapter.Execute(ctx,p,action,args)
 end
 local function handle(p,action,payload)
  if type(action)~="string" then return end
  local now=os.clock() if now-(rates[p] or -10)<.25 then return end rates[p]=now
  if not authorized(p) then remote:FireClient(p,"denied") return end
  if action=="auth" then remote:FireClient(p,"auth",true) remote:FireClient(p,"state",roster()) return end
  if action=="state" then remote:FireClient(p,"state",roster()) return end
  if action~="cmd" or type(payload)~="string" or #payload>300 or busy[p] then return end
  busy[p]=true
  local ok,result=pcall(execute,p,payload)
  result=ok and tostring(result) or ("Error: "..tostring(result):gsub("^.-:%d+: ",""))
  busy[p]=nil audit(p,payload,result)
  if p.Parent then remote:FireClient(p,"reply",result) remote:FireClient(p,"state",roster()) end
 end
 remote.OnServerEvent:Connect(handle)
 local function added(p)
  task.spawn(function()
   local ok,record=true,memoryBans[p.UserId]
   if live then ok,record=pcall(function() return bans:GetAsync(tostring(p.UserId)) end) end
   if not ok then warn("[Admin] Ban check failed for "..p.UserId) end
   if ok and record and p.Parent then p:Kick("You are banned from this experience.") return end
   if p.Parent then
    local isAdmin=authorized(p)
    p:SetAttribute("IsAdmin",isAdmin)
    if isAdmin then remote:FireClient(p,"auth",true) end
   end
  end)
 end
 Players.PlayerAdded:Connect(added)
 Players.PlayerRemoving:Connect(function(p) cache[p.UserId]=nil rates[p]=nil busy[p]=nil end)
 for _,p in Players:GetPlayers() do added(p) end
 return {IsAdmin=authorized,Handle=handle,Context=ctx}
end
return M
