local Rows={}
function Rows.apply(gui)
 for _,name in {"Heading","Status","YourResult","YourResultLabel","RankingList"} do local item=gui:FindFirstChild(name) if item then item:Destroy() end end
 gui.ZOffset=.08
 gui.Active=true
 gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
 for _,child in gui:GetChildren() do if child.Name:match("^Row_") then child:Destroy() end end
 local list=Instance.new("ScrollingFrame") list.Name="RankingList" list.Position=UDim2.fromOffset(16,20) list.Size=UDim2.fromOffset(568,610)
 list.BackgroundTransparency=1 list.BorderSizePixel=0 list.CanvasSize=UDim2.fromOffset(0,6094)
 list.ScrollingDirection=Enum.ScrollingDirection.Y list.ScrollBarThickness=8 list.ScrollBarImageColor3=Color3.fromRGB(150,223,255)
 list.Active=true list.ScrollingEnabled=true list.ClipsDescendants=true list.ZIndex=2 list.Parent=gui
 for i=1,100 do
  local row=Instance.new("Frame") row.Name="Row_"..i row.Position=UDim2.fromOffset(0,(i-1)*61) row.Size=UDim2.fromOffset(554,55)
  row.BackgroundColor3=i==1 and Color3.fromRGB(255,211,62) or (i==2 and Color3.fromRGB(211,225,240) or (i==3 and Color3.fromRGB(223,161,98) or Color3.fromRGB(121,177,216)))
  row.BorderSizePixel=0 row.ZIndex=2 row.Parent=list
  local corner=Instance.new("UICorner") corner.CornerRadius=UDim.new(0,6) corner.Parent=row
  local gradient=Instance.new("UIGradient") gradient.Rotation=90 gradient.Color=ColorSequence.new(Color3.new(1,1,1),Color3.fromRGB(177,196,214)) gradient.Parent=row
  local function label(name,txt,x,w,align,color)
   local t=Instance.new("TextLabel") t.Name=name t.Text=txt t.Position=UDim2.fromOffset(x,9) t.Size=UDim2.fromOffset(w,37)
   t.BackgroundTransparency=1 t.Font=Enum.Font.FredokaOne t.TextScaled=true t.TextColor3=color or Color3.new(1,1,1)
   t.TextXAlignment=align t.Parent=row
   local stroke=Instance.new("UIStroke") stroke.Color=Color3.fromRGB(32,48,68) stroke.Thickness=1.6 stroke.Parent=t
   local limit=Instance.new("UITextSizeConstraint") limit.MaxTextSize=27 limit.MinTextSize=10 limit.Parent=t
   return t
  end
  label("Rank","#"..i,6,66,Enum.TextXAlignment.Center,i<=3 and Color3.fromRGB(255,225,113) or Color3.new(1,1,1))
  local avatar=Instance.new("ImageLabel") avatar.Name="Avatar" avatar.Position=UDim2.fromOffset(77,4) avatar.Size=UDim2.fromOffset(47,47)
  avatar.BackgroundColor3=Color3.fromRGB(65,91,116) avatar.BackgroundTransparency=.25 avatar.Image="" avatar.Visible=false avatar.Parent=row
  local round=Instance.new("UICorner") round.CornerRadius=UDim.new(0,9) round.Parent=avatar
  local placeholder=Instance.new("Frame") placeholder.Name="Placeholder" placeholder.Size=UDim2.fromScale(1,1) placeholder.BackgroundTransparency=1 placeholder.Parent=avatar
  for _,spec in {{14,7,19,19},{8,28,31,14}} do
   local p=Instance.new("Frame") p.Position=UDim2.fromOffset(spec[1],spec[2]) p.Size=UDim2.fromOffset(spec[3],spec[4]) p.BackgroundColor3=Color3.fromRGB(188,207,220) p.BorderSizePixel=0 p.Parent=placeholder
   local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,7) c.Parent=p
  end
  label("PlayerName","—",137,264,Enum.TextXAlignment.Left)
  label("Value","—",402,141,Enum.TextXAlignment.Right)
  for _,c in row:GetDescendants() do if c:IsA("GuiObject") then c.ZIndex=3 end end
 end
 local own=list.Row_10:Clone() own.Name="YourResult" own.Position=UDim2.fromOffset(16,698) own.Size=UDim2.fromOffset(568,55) own.Avatar.Visible=true
 own.BackgroundColor3=Color3.fromRGB(92,222,153)
 own.Rank.Text="#—" own.PlayerName.Text="—" own.Value.Text="—" own.Parent=gui
 local border=Instance.new("UIStroke") border.Color=Color3.fromRGB(149,255,185) border.Thickness=3 border.Parent=own
 local caption=Instance.new("TextLabel") caption.Name="YourResultLabel" caption.Text="YOUR RESULT"
 caption.BackgroundTransparency=1 caption.Position=UDim2.fromOffset(16,653) caption.Size=UDim2.fromOffset(568,33)
 caption.Font=Enum.Font.FredokaOne caption.TextSize=27 caption.TextColor3=Color3.fromRGB(149,255,185) caption.ZIndex=3 caption.Parent=gui
end
function Rows.setEntries(gui,entries)
 local list=gui:FindFirstChild("RankingList")
 if not list then return end
 for i=1,100 do
  local row=list:FindFirstChild("Row_"..i) local entry=entries[i]
  if row then
   row.PlayerName.Text=entry and tostring(entry.name) or "—"
   row.Value.Text=entry and tostring(entry.value) or "—"
   local userId=entry and tonumber(entry.userId)
   row.Avatar.Image=userId and ("rbxthumb://type=AvatarHeadShot&id="..math.floor(userId).."&w=150&h=150") or ""
   row.Avatar.Visible=userId~=nil
   row.Avatar.Placeholder.Visible=false
  end
 end
 if gui:FindFirstChild("Status") then gui.Status:Destroy() end
end
return Rows
