local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local Run=game:GetService("RunService")
local TextService=game:GetService("TextService")
local TweenService=game:GetService("TweenService")
local LocalizationService=game:GetService("LocalizationService")
local folder=script.Parent
local C=require(folder.Config)
local remote=folder.Remote
local T=require(C.Theme)
local p=Players.LocalPlayer
local isFrench=Run:IsStudio()
if not isFrench then
 local ok,locale=pcall(function() return LocalizationService.RobloxLocaleId end)
 isFrench=ok and type(locale)=="string" and locale:lower():sub(1,2)=="fr"
end
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
local annRow,annAvatar,annText,annTitle,annEdge,annRing,annScale,annCardStroke,annDefaultPosition
local annCounter=0
local function annEscape(s) return (tostring(s):gsub("&","&amp;"):gsub("<","&lt;"):gsub(">","&gt;")) end
local function annFade(alpha)
 if annTitle then annTitle.TextTransparency=alpha annTitle.TextStrokeTransparency=math.clamp(.15+alpha*.85,0,1) end
 if annText then annText.TextTransparency=alpha annText.TextStrokeTransparency=math.clamp(.15+alpha*.85,0,1) end
 if annAvatar then
  annAvatar.ImageTransparency=alpha
  annAvatar.BackgroundTransparency=math.clamp(.06+alpha*.94,0,1)
 end
 if annRing then annRing.Transparency=alpha end
 if annRow then annRow.BackgroundTransparency=math.clamp(.05+alpha*.95,0,1) end
 if annCardStroke then annCardStroke.Transparency=math.clamp(.06+alpha*.94,0,1) end
end

local function measureText(label,text,width)
 local params=Instance.new("GetTextBoundsParams")
 params.Text=text
 params.Font=label.FontFace
 params.Size=label.TextSize
 params.Width=width
 local ok,bounds=pcall(TextService.GetTextBoundsAsync,TextService,params)
 params:Destroy()
 if ok and bounds then return bounds end
 return TextService:GetTextSize(text,label.TextSize,label.Font,Vector2.new(width,2000))
end

local function wireAnnouncement(pg)
 local annGui=pg:WaitForChild("AnnouncementLine",30)
 if not annGui then return end

 local legacy=annGui:FindFirstChild("Announcement")
 if legacy and legacy:IsA("GuiObject") then legacy.Visible=false end

 local old=annGui:FindFirstChild("AdminAnnouncementCard")
 if old then old:Destroy() end

 annRow=Instance.new("Frame")
 annRow.Name="AdminAnnouncementCard"
 annRow.AnchorPoint=Vector2.new(.5,0)
 annDefaultPosition=UDim2.new(.5,0,0,42)
 annRow.Position=annDefaultPosition
 annRow.Size=UDim2.fromOffset(460,76)
 annRow.BackgroundColor3=rgb(11,14,18)
 annRow.BackgroundTransparency=.05
 annRow.BorderSizePixel=0
 annRow.ClipsDescendants=true
 annRow.ZIndex=80
 annRow.Visible=false
 annRow.Parent=annGui

 local corner=Instance.new("UICorner")
 corner.CornerRadius=UDim.new(0,12)
 corner.Parent=annRow

 annCardStroke=Instance.new("UIStroke")
 annCardStroke.Name="GoldStroke"
 annCardStroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
 annCardStroke.LineJoinMode=Enum.LineJoinMode.Round
 annCardStroke.Color=rgb(255,190,38)
 annCardStroke.Thickness=2
 annCardStroke.Transparency=.06
 annCardStroke.Parent=annRow

 local grad=Instance.new("UIGradient")
 grad.Rotation=0
 grad.Color=ColorSequence.new({
  ColorSequenceKeypoint.new(0,rgb(12,16,21)),
  ColorSequenceKeypoint.new(.5,rgb(27,22,14)),
  ColorSequenceKeypoint.new(1,rgb(12,16,21)),
 })
 grad.Parent=annRow

 annScale=Instance.new("UIScale")
 annScale.Scale=1
 annScale.Parent=annRow

 annAvatar=Instance.new("ImageLabel")
 annAvatar.Name="Avatar"
 annAvatar.AnchorPoint=Vector2.new(0,.5)
 annAvatar.Position=UDim2.new(0,12,.5,0)
 annAvatar.Size=UDim2.fromOffset(52,52)
 annAvatar.BackgroundColor3=rgb(255,190,38)
 annAvatar.BackgroundTransparency=.06
 annAvatar.BorderSizePixel=0
 annAvatar.ScaleType=Enum.ScaleType.Crop
 annAvatar.ZIndex=82
 annAvatar.Parent=annRow
 local avatarCorner=Instance.new("UICorner")
 avatarCorner.CornerRadius=UDim.new(1,0)
 avatarCorner.Parent=annAvatar
 annRing=Instance.new("UIStroke")
 annRing.Color=rgb(255,220,90)
 annRing.Thickness=2
 annRing.Transparency=0
 annRing.Parent=annAvatar

 annTitle=Instance.new("TextLabel")
 annTitle.Name="Title"
 annTitle.BackgroundTransparency=1
 annTitle.Font=Enum.Font.GothamBlack
 annTitle.TextSize=17
 annTitle.TextScaled=false
 annTitle.TextWrapped=false
 annTitle.TextColor3=rgb(255,214,72)
 annTitle.TextStrokeColor3=Color3.new(0,0,0)
 annTitle.TextStrokeTransparency=.15
 annTitle.TextXAlignment=Enum.TextXAlignment.Left
 annTitle.TextYAlignment=Enum.TextYAlignment.Center
 annTitle.ZIndex=82
 annTitle.Parent=annRow

 annText=Instance.new("TextLabel")
 annText.Name="Body"
 annText.BackgroundTransparency=1
 annText.Font=Enum.Font.GothamBold
 annText.TextSize=17
 annText.TextScaled=false
 annText.TextWrapped=true
 annText.RichText=true
 annText.TextColor3=Color3.new(1,1,1)
 annText.TextStrokeColor3=Color3.new(0,0,0)
 annText.TextStrokeTransparency=.15
 annText.TextXAlignment=Enum.TextXAlignment.Left
 annText.TextYAlignment=Enum.TextYAlignment.Top
 annText.ZIndex=82
 annText.Parent=annRow
 annEdge=nil
end

local function showAnnouncement(data)
 local body=type(data)=="table" and tostring(data.text or "") or tostring(data or "")
 if body=="" or not annRow then return end

 local nick=tostring((type(data)=="table" and data.fromName) or "ADMIN")
 local nickColor=attrOr(annRow,"NickColor",rgb(86,178,255))
 local titleText=isFrench and "📢 MESSAGE SERVEUR" or "📢 SERVER ANNOUNCEMENT"

 annTitle.Text=titleText
 annText.Text=('<font color="#%s"><b>%s</b></font>: %s'):format(
  nickColor:ToHex(),
  annEscape(nick),
  annEscape(body)
 )

 local cam=workspace.CurrentCamera
 local viewportW=cam and cam.ViewportSize.X or 1280
 local maxCardW=math.clamp(math.floor(viewportW*.58),460,720)
 local minCardW=400
 local textLeft=76
 local rightPad=16
 local topPad=10
 local titleH=21
 local titleGap=3
 local bottomPad=11

 local titleNatural=measureText(annTitle,titleText,3000)
 local bodyPlain=nick..": "..body
 local bodyNatural=measureText(annText,bodyPlain,3000)
 local desiredContentW=math.max(titleNatural.X,bodyNatural.X)
 local cardW=math.clamp(math.ceil(desiredContentW)+textLeft+rightPad,minCardW,maxCardW)
 local textW=cardW-textLeft-rightPad

 local bodyBounds=measureText(annText,bodyPlain,textW)
 local bodyH=math.max(20,math.ceil(bodyBounds.Y))
 local cardH=math.max(76,topPad+titleH+titleGap+bodyH+bottomPad)

 annTitle.Position=UDim2.fromOffset(textLeft,topPad)
 annTitle.Size=UDim2.fromOffset(textW,titleH)
 annText.Position=UDim2.fromOffset(textLeft,topPad+titleH+titleGap)
 annText.Size=UDim2.fromOffset(textW,bodyH)
 annRow.Size=UDim2.fromOffset(cardW,cardH)

 local fit=1
 if cam and cam.ViewportSize.X>0 then
  fit=math.min(1,cam.ViewportSize.X*.92/cardW)
 end

 local userId=type(data)=="table" and tonumber(data.fromUserId) or nil
 annAvatar.Image=""
 if userId and userId>0 then
  task.spawn(function()
   local ok,url=pcall(function()
    return Players:GetUserThumbnailAsync(userId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size150x150)
   end)
   if ok and annAvatar then annAvatar.Image=url end
  end)
 end

 annCounter+=1
 local mine=annCounter
 annFade(0)
 annRow.Visible=true
 annScale.Scale=fit*.86
 annRow.Position=annDefaultPosition-UDim2.fromOffset(0,18)
 TweenService:Create(annScale,TweenInfo.new(.28,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=fit}):Play()
 TweenService:Create(annRow,TweenInfo.new(.28,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Position=annDefaultPosition}):Play()

 task.delay(7,function()
  if annCounter~=mine then return end
  local target=annDefaultPosition-UDim2.fromOffset(0,14)
  TweenService:Create(annRow,TweenInfo.new(.32,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Position=target}):Play()
  local started=os.clock()
  while os.clock()-started<.32 do
   if annCounter~=mine then return end
   annFade((os.clock()-started)/.32)
   Run.Heartbeat:Wait()
  end
  if annCounter==mine then
   annRow.Visible=false
   annRow.Position=annDefaultPosition
  end
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
 local pageServer=pages.SERVER
 if pageServer then
  local announce=Instance.new("Frame")
  announce.Name="ServerAnnouncement"
  announce.Size=UDim2.new(1,-8,0,102)
  announce.Position=UDim2.fromOffset(4,4)
  announce.BackgroundColor3=rgb(25,28,38)
  announce.BorderSizePixel=0
  announce.ZIndex=20
  announce.Parent=pageServer

  local corner=Instance.new("UICorner")
  corner.CornerRadius=UDim.new(0,8)
  corner.Parent=announce

  local edge=Instance.new("UIStroke")
  edge.Color=rgb(255,184,34)
  edge.Thickness=2
  edge.Transparency=.10
  edge.Parent=announce

  local bg=Instance.new("UIGradient")
  bg.Rotation=0
  bg.Color=ColorSequence.new({
   ColorSequenceKeypoint.new(0,rgb(31,34,46)),
   ColorSequenceKeypoint.new(.55,rgb(45,34,18)),
   ColorSequenceKeypoint.new(1,rgb(26,29,39)),
  })
  bg.Parent=announce

  local label=Instance.new("TextLabel")
  label.Name="Title"
  label.BackgroundTransparency=1
  label.Position=UDim2.fromOffset(10,5)
  label.Size=UDim2.new(1,-20,0,16)
  label.Font=Enum.Font.GothamBold
  label.TextSize=11
  label.TextXAlignment=Enum.TextXAlignment.Left
  label.TextColor3=YELLOW
  label.Text=isFrench and "📢 MESSAGE SERVEUR" or "📢 SERVER ANNOUNCEMENT"
  label.ZIndex=21
  label.Parent=announce

  local description=Instance.new("TextLabel")
  description.Name="Description"
  description.BackgroundTransparency=1
  description.Position=UDim2.fromOffset(10,20)
  description.Size=UDim2.new(1,-20,0,13)
  description.Font=Enum.Font.Gotham
  description.TextSize=9
  description.TextXAlignment=Enum.TextXAlignment.Left
  description.TextColor3=rgb(205,208,218)
  description.Text=isFrench and "Envoie un message filtré à tous les joueurs de ce serveur." or "Broadcast a filtered message to everyone in this server."
  description.ZIndex=21
  description.Parent=announce

  local box=Instance.new("TextBox")
  box.Name="Message"
  box.Position=UDim2.fromOffset(10,38)
  box.Size=UDim2.new(1,-104,0,43)
  box.BackgroundColor3=rgb(14,16,23)
  box.BorderSizePixel=0
  box.ClearTextOnFocus=false
  box.MultiLine=true
  box.TextWrapped=true
  box.TextTruncate=Enum.TextTruncate.None
  box.ClipsDescendants=true
  box.PlaceholderText="Message..."
  box.Text=""
  box.TextColor3=Color3.new(1,1,1)
  box.PlaceholderColor3=rgb(130,136,153)
  box.Font=Enum.Font.Gotham
  box.TextSize=11
  box.TextXAlignment=Enum.TextXAlignment.Left
  box.TextYAlignment=Enum.TextYAlignment.Top
  box.ZIndex=21
  box.Parent=announce
  local boxCorner=Instance.new("UICorner")
  boxCorner.CornerRadius=UDim.new(0,5)
  boxCorner.Parent=box
  local boxStroke=Instance.new("UIStroke")
  boxStroke.Color=rgb(88,94,112)
  boxStroke.Transparency=.35
  boxStroke.Thickness=1
  boxStroke.Parent=box

  local sendButton=Instance.new("TextButton")
  sendButton.Name="Send"
  sendButton.AnchorPoint=Vector2.new(1,0)
  sendButton.Position=UDim2.new(1,-10,0,38)
  sendButton.Size=UDim2.fromOffset(84,43)
  sendButton.BackgroundColor3=rgb(255,138,0)
  sendButton.BorderSizePixel=0
  sendButton.AutoButtonColor=false
  sendButton.Text=isFrench and "ENVOYER" or "SEND"
  sendButton.TextColor3=Color3.new(1,1,1)
  sendButton.TextStrokeColor3=rgb(110,48,0)
  sendButton.TextStrokeTransparency=.35
  sendButton.TextTransparency=0
  sendButton.Font=Enum.Font.GothamBold
  sendButton.TextSize=11
  sendButton.ZIndex=23
  sendButton.Parent=announce
  local sendCorner=Instance.new("UICorner")
  sendCorner.CornerRadius=UDim.new(0,5)
  sendCorner.Parent=sendButton
  local sendStroke=Instance.new("UIStroke")
  sendStroke.Color=rgb(255,210,92)
  sendStroke.Thickness=1
  sendStroke.Transparency=.18
  sendStroke.Parent=sendButton

  local counter=Instance.new("TextLabel")
  counter.Name="Counter"
  counter.BackgroundTransparency=1
  counter.Position=UDim2.fromOffset(10,84)
  counter.Size=UDim2.fromOffset(70,12)
  counter.Font=Enum.Font.Gotham
  counter.TextSize=8
  counter.TextXAlignment=Enum.TextXAlignment.Left
  counter.TextColor3=rgb(145,150,165)
  counter.Text="0 / 180"
  counter.ZIndex=21
  counter.Parent=announce

  local status=Instance.new("TextLabel")
  status.Name="Status"
  status.BackgroundTransparency=1
  status.AnchorPoint=Vector2.new(1,0)
  status.Position=UDim2.new(1,-10,0,84)
  status.Size=UDim2.fromOffset(180,12)
  status.Font=Enum.Font.GothamBold
  status.TextSize=8
  status.TextXAlignment=Enum.TextXAlignment.Right
  status.TextColor3=rgb(130,255,145)
  status.Text=""
  status.ZIndex=21
  status.Parent=announce

  box:GetPropertyChangedSignal("Text"):Connect(function()
   if #box.Text>180 then box.Text=box.Text:sub(1,180) end
   counter.Text=tostring(#box.Text).." / 180"
   counter.TextColor3=#box.Text>=165 and rgb(255,175,80) or rgb(145,150,165)
  end)

  local normal=sendButton.BackgroundColor3
  sendButton.MouseEnter:Connect(function()
   TweenService:Create(sendButton,TweenInfo.new(.12),{BackgroundColor3=rgb(255,167,48)}):Play()
  end)
  sendButton.MouseLeave:Connect(function()
   TweenService:Create(sendButton,TweenInfo.new(.12),{BackgroundColor3=normal}):Play()
  end)

  for _,child in pageServer:GetChildren() do
   if child~=announce and child:IsA("GuiObject") then
    child.Position=child.Position+UDim2.fromOffset(0,108)
   end
  end
  if pageServer:IsA("ScrollingFrame") then
   pageServer.CanvasSize=pageServer.CanvasSize+UDim2.fromOffset(0,108)
  end

  local statusToken=0
  local function setStatus(textValue,color)
   statusToken+=1
   local mine=statusToken
   status.Text=textValue
   status.TextColor3=color
   task.delay(2.5,function()
    if statusToken==mine and status then status.Text="" end
   end)
  end
  local function submitAnnouncement()
   local message=(box.Text or ""):match("^%s*(.-)%s*$")
   if message=="" then
    setStatus(isFrench and "MESSAGE REQUIS" or "MESSAGE REQUIRED",WARN)
    log("Enter a server message first.",WARN)
    return
   end
   send(PREFIX.." announce "..message)
   box.Text=""
   setStatus(isFrench and "ENVOYÉ ✓" or "SENT ✓",rgb(130,255,145))
  end
  sendButton.Activated:Connect(submitAnnouncement)
  UIS.InputBegan:Connect(function(input,processed)
   if processed or not box:IsFocused() then return end
   if input.KeyCode==Enum.KeyCode.Return and (UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.RightControl)) then
    box:ReleaseFocus()
    submitAnnouncement()
   end
  end)
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
