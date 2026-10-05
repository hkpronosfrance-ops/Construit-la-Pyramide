local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local Run=game:GetService("RunService")
local TextService=game:GetService("TextService")
local TweenService=game:GetService("TweenService")
local folder=script.Parent
local C=require(folder.Config)
local remote=folder:WaitForChild("Remote")
local T=require(C.Theme)
local p=Players.LocalPlayer
local M={Authorized=false}
local rgb=Color3.fromRGB
local YELLOW=rgb(255,205,0)
local WARN=rgb(255,110,110)
local PREFIX=C.Prefix
local LOG_GAP=12
local built,gui,backdrop,panel,logBox,lineTemplate,selectedLabel,playerList,rowTemplate,confirmFrame,confirmText,pendingAction,confirmMask
local logLines,logToken=0,0
local selected,roster=nil,{}
local searchQuery=""
local pages,tabs={},{}
local pageAlone,pageWithLog={},{}
local function compact(n)
 n=tonumber(n) or 0
 for _,u in {{1e12,"T"},{1e9,"B"},{1e6,"M"},{1e3,"K"}} do
  if math.abs(n)>=u[1] then return (string.format("%.2f",n/u[1]):gsub("0+$",""):gsub("%.$",""))..u[2] end
 end
 return tostring(math.floor(n))
end
local function attrOr(o,name,fallback) local v=o:GetAttribute(name) if v==nil then return fallback end return v end
local function setLogShown(on)
 if not logBox then return end
 logBox.Visible=on
 for name,page in pages do page.Size=UDim2.fromOffset(page.Size.X.Offset,on and pageWithLog[name] or pageAlone[name]) end
end
local function log(value,color)
 if not logBox then return end
 logLines+=1
 local count,oldest=0,nil
 for _,o in logBox:GetChildren() do
  if o:IsA("TextLabel") and o~=lineTemplate then count+=1 if not oldest or o.LayoutOrder<oldest.LayoutOrder then oldest=o end end
 end
 if count>100 and oldest then oldest:Destroy() end
 local line=lineTemplate:Clone() line.Name="Line" line:SetAttribute("IsTemplate",nil)
 line.Text=value line.TextColor3=color or lineTemplate.TextColor3 line.LayoutOrder=logLines line.Visible=true line.Parent=logBox
 setLogShown(true)
 logToken+=1 local mine=logToken
 task.delay(10,function() if logToken==mine then setLogShown(false) end end)
 task.defer(function() if logBox then logBox.CanvasPosition=Vector2.new(0,1e6) end end)
end
local function send(cmd) log("> "..cmd,Color3.new(1,1,1)) remote:FireServer("cmd",cmd) end
local function need()
 if not selected then log("pick a player on the PLAYER tab first",WARN) return false end
 return true
end
local function setConfirm(value)
 if not confirmFrame then return end
 confirmFrame.Visible=value
 if confirmMask then confirmMask.Visible=value end
 local shadow=panel:FindFirstChild("Confirm_Shadow") if shadow then shadow.Visible=value end
end
local function confirm(message,fn) if C.Confirm==false then fn() return end confirmText.Text=message pendingAction=fn setConfirm(true) end
local function showTab(name)
 for n,page in pages do page.Visible=n==name end
 for n,b in tabs do T.gradient(b,n==name and attrOr(b,"ActiveColor",rgb(255,138,0)) or attrOr(b,"IdleColor",rgb(98,106,130))) end
end
local title,titleDefault
local function refreshTitle()
 if not title then return end
 title.Text=selected and string.format(attrOr(title,"SelectedFormat","ADMIN • %s"),selected.name) or titleDefault
end
local function renderPlayers()
 if not playerList then return end
 for _,c in playerList:GetChildren() do if c:IsA("GuiObject") and c.Name:match("^Row_") then c:Destroy() end end
 local x,y=rowTemplate.Position.X.Offset,rowTemplate.Position.Y.Offset
 local step=rowTemplate.Size.Y.Offset+10
 for _,entry in roster do
  if searchQuery~="" and not entry.name:lower():find(searchQuery,1,true) then continue end
  local picked=selected and selected.userId==entry.userId
  local row=T.copy(rowTemplate,playerList,"Row_"..entry.userId)
  row.Position=UDim2.fromOffset(x,y)
  T.gradient(row,picked and attrOr(rowTemplate,"PickedColor",rgb(40,150,60)) or attrOr(rowTemplate,"IdleColor",rgb(58,64,84)))
  local summary=string.format("%s   $%s   💪 %s",entry.name,compact(entry.coins),compact(entry.strength))
  local text=row:FindFirstChild("Summary") if text then text.Text=summary end
  local pick=row:FindFirstChild("Select")
  if pick then
   pick.Activated:Connect(function()
    selected={userId=entry.userId,name=entry.name}
    selectedLabel.Text=attrOr(selectedLabel,"Prefix","selected: ")..entry.name
    refreshTitle() renderPlayers()
   end)
  end
  y+=step
 end
 playerList.CanvasSize=UDim2.fromOffset(0,y+10)
end
local annRow,annAvatar,annText,annEdge,annRing,annScale
local annCounter=0
local function annEscape(s) return (tostring(s):gsub("&","&amp;"):gsub("<","&lt;"):gsub(">","&gt;")) end
local function annFade(alpha)
 annText.TextTransparency=alpha if annEdge then annEdge.Transparency=alpha end annAvatar.ImageTransparency=alpha annAvatar.BackgroundTransparency=alpha if annRing then annRing.Transparency=alpha end
end
local function wireAnnouncement(pg)
 local annGui=pg:WaitForChild("AnnouncementLine")
 annRow=annGui:WaitForChild("Announcement") annRow.Visible=false
 annScale=annRow:FindFirstChildOfClass("UIScale") or Instance.new("UIScale",annRow)
 annAvatar=annRow:WaitForChild("Avatar") annRing=annAvatar:FindFirstChildOfClass("UIStroke")
 annText=annRow:WaitForChild("Text") annEdge=annText:FindFirstChildOfClass("UIStroke")
end
local function showAnnouncement(data)
 local body=type(data)=="table" and tostring(data.text or "") or tostring(data or "")
 if body=="" or not annRow then return end
 local nick=tostring((type(data)=="table" and data.fromName) or "ADMIN")
 local nickColor=attrOr(annRow,"NickColor",Color3.fromHex("56B2FF"))
 annText.Text=('<font color="#%s">%s</font>: %s'):format(nickColor:ToHex(),annEscape(nick),annEscape(body))
 local bounds=TextService:GetTextSize(nick..": "..body,annText.TextSize,annText.Font,Vector2.new(980,4000))
 local w,h=math.ceil(bounds.X)+10,math.ceil(bounds.Y)+6
 annText.Size=UDim2.fromOffset(w,h)
 local rowW=annText.Position.X.Offset+w
 annRow.Size=UDim2.fromOffset(rowW,math.max(h,annAvatar.Size.Y.Offset))
 local fit=1
 local cam=workspace.CurrentCamera
 if cam and cam.ViewportSize.X>0 then fit=math.min(1,cam.ViewportSize.X*.92/rowW) end
 local userId=type(data)=="table" and tonumber(data.fromUserId) or nil
 annAvatar.Image=""
 if userId and userId>0 then
  task.spawn(function()
   local ok,url=pcall(function() return Players:GetUserThumbnailAsync(userId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size150x150) end)
   if ok then annAvatar.Image=url end
  end)
 end
 annFade(0)
 annRow.Visible=true
 annScale.Scale=fit*.8
 TweenService:Create(annScale,TweenInfo.new(.25,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=fit}):Play()
 annCounter+=1
 local mine=annCounter
 task.delay(7,function()
  if annCounter~=mine then return end
  local started=os.clock()
  while os.clock()-started<.45 do
   if annCounter~=mine then return end
   annFade((os.clock()-started)/.45)
   Run.Heartbeat:Wait()
  end
  if annCounter==mine then annRow.Visible=false end
 end)
end
function M.toggle(value)
 M.start()
 if value==nil then value=not panel.Visible end
 if value and not M.Authorized then remote:FireServer("auth") return end
 panel.Visible=value backdrop.Visible=value
 gui:SetAttribute("Open",value)
 if not value then setConfirm(false) else remote:FireServer("state") end
end
local function wireCommand(b)
 local command=b:GetAttribute("Command")
 if type(command)~="string" or command=="" then return end
 b.Activated:Connect(function()
  local def=b:GetAttribute("Command")
  if def:find("{player}",1,true) and not need() then return end
  local cmd=def:gsub("{player}",function() return selected and selected.name or "" end)
  if cmd:find("{value}",1,true) then
   local fieldName=b:GetAttribute("ValueField")
   local box=fieldName and b.Parent:FindFirstChild(fieldName,true) or (fieldName and panel:FindFirstChild(fieldName,true))
   local value=box and box:IsA("TextBox") and box.Text or ""
   if value=="" then log("Enter a value first.",WARN) return end
   cmd=cmd:gsub("{value}",function() return value end)
  end
  local execute=function() send(PREFIX.." "..cmd) end
  if b:GetAttribute("Confirm") then
   local caption=b:FindFirstChild("Caption")
   local label=caption and caption.Text or b.Name
    confirm(label.." — "..(def:find("{player}",1,true) and selected and selected.name or "THIS SERVER").."\n"..cmd.."?",execute)
  else execute() end
 end)
end
function M.start()
 if built then return M end built=true
 local pg=p:WaitForChild("PlayerGui")
 wireAnnouncement(pg)
 gui=pg:WaitForChild("AdminPanel") gui:SetAttribute("Authorized",false)
 backdrop=gui:WaitForChild("Backdrop")
 panel=gui:WaitForChild("Admin")
 panel.Visible=false backdrop.Visible=false
 local W,H=panel.Size.X.Offset,panel.Size.Y.Offset
 local scale=panel:FindFirstChildOfClass("UIScale") or Instance.new("UIScale",panel)
 local function resize() local v=workspace.CurrentCamera.ViewportSize if v.X<100 or v.Y<100 then return end scale.Scale=math.min(.8,(v.X-24)/W,(v.Y-30)/H) end
 resize() workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
 local header=panel:WaitForChild("Header")
 title=header:FindFirstChild("Title") titleDefault=title and title.Text or "ADMIN PANEL"
 local close=header:WaitForChild("Close")
 logBox=panel:WaitForChild("Log")
 lineTemplate=logBox:WaitForChild("LineTemplate") lineTemplate.Visible=false
 for _,c in panel:GetChildren() do
  local name=c:GetAttribute("Tab")
  if c:IsA("GuiButton") and type(name)=="string" then
   tabs[name]=c
   c.Activated:Connect(function() showTab(name) end)
  end
  local page=c.Name:match("^Page_(.+)$")
  if page and c:IsA("GuiObject") then
   pages[page]=c
   local top=c.Position.Y.Offset
   pageAlone[page]=logBox.Position.Y.Offset+logBox.Size.Y.Offset-top
   pageWithLog[page]=logBox.Position.Y.Offset-LOG_GAP-top
  end
 end
 local pagePlayer=pages.PLAYER
 selectedLabel=pagePlayer:WaitForChild("SelectedLabel")
 selectedLabel.Text=attrOr(selectedLabel,"EmptyText","nobody selected")
 local search=pagePlayer:WaitForChild("Search")
 search:GetPropertyChangedSignal("Text"):Connect(function() searchQuery=search.Text:lower() renderPlayers() end)
 playerList=pagePlayer:WaitForChild("Players")
 rowTemplate=playerList:WaitForChild("RowTemplate") rowTemplate.Visible=false
 local function on(name,fn) local b=pagePlayer:FindFirstChild(name,true) if b then b.Activated:Connect(fn) end end
 on("Kick",function()
  if need() then local name=selected.name confirm("Kick "..name.." from the server?",function() send(PREFIX.." kick "..name.." Kicked by admin") end) end
 end)
 on("Ban",function()
  if need() then local name=selected.name confirm("BAN "..name.."? They will not be able to rejoin.",function() send(PREFIX.." ban "..name.." Banned by admin") end) end
 end)
 on("TeleportTo",function() if need() then send(PREFIX.." teleport "..selected.name) end end)
 on("Bring",function() if need() then send(PREFIX.." bring "..selected.name) end end)
 local unbanBox=pagePlayer:FindFirstChild("UnbanUserId",true)
 on("Unban",function()
  local id=unbanBox and tonumber(unbanBox.Text) if not id then log("give a UserId",WARN) return end
  send(PREFIX.." unban "..math.floor(id))
 end)
 for _,b in panel:GetDescendants() do if b:IsA("GuiButton") then wireCommand(b) end end
 confirmMask=panel:FindFirstChild("ConfirmMask")
 confirmFrame=panel:WaitForChild("Confirm")
 confirmText=confirmFrame:WaitForChild("Message")
 confirmFrame:WaitForChild("Yes").Activated:Connect(function() local fn=pendingAction pendingAction=nil setConfirm(false) if fn then fn() end end)
 confirmFrame:WaitForChild("No").Activated:Connect(function() pendingAction=nil setConfirm(false) end)
 setConfirm(false)
 T.adoptWindow(panel)
 setLogShown(false)
 local function setAuthorized(value)
  M.Authorized=value gui:SetAttribute("Authorized",value)
  if not value then panel.Visible=false backdrop.Visible=false gui:SetAttribute("Open",false) setConfirm(false) end
 end
 remote.OnClientEvent:Connect(function(kind,data)
  if kind=="auth" then setAuthorized(data==true)
  elseif kind=="denied" then setAuthorized(false)
  elseif kind=="state" then roster=type(data)=="table" and data or {} renderPlayers()
  elseif kind=="reply" then log(tostring(data),YELLOW)
  elseif kind=="audit" then for _,line in data do log(line,YELLOW) end
  elseif kind=="announce" then showAnnouncement(data)
  end
 end)
 close.Activated:Connect(function() M.toggle(false) end)
 backdrop.Activated:Connect(function() if C.CloseOnBackdrop~=false then M.toggle(false) end end)
 UIS.InputBegan:Connect(function(input,processed)
  if processed then return end
  if input.KeyCode==Enum.KeyCode.F2 then M.toggle() elseif input.KeyCode==Enum.KeyCode.Escape and panel.Visible then M.toggle(false) end
 end)
 task.spawn(function() while task.wait(4) do if panel.Visible and M.Authorized then remote:FireServer("state") end end end)
 showTab("PLAYER")
 remote:FireServer("auth")
 task.spawn(function() for _=1,5 do task.wait(2) if M.Authorized then return end remote:FireServer("auth") end end)
 return M
end
return M
