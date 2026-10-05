local TweenService=game:GetService("TweenService")
local UIS=game:GetService("UserInputService")
local Lighting=game:GetService("Lighting")
local SoundService=game:GetService("SoundService")
local T={}
local WHITE=Color3.new(1,1,1)
local BLACK=Color3.new(0,0,0)
T.Outline=Color3.fromHex("081020")
T.Dark=Color3.fromRGB(38,42,56)
T.Yellow=Color3.fromRGB(255,205,0)
T.Red=Color3.fromRGB(226,41,41)
T.TitleInk=Color3.fromRGB(43,23,64)
T.Texture="rbxassetid://138926013267839"
T.StudTransparency=.55
local FAST=TweenInfo.new(.12,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
local POP=TweenInfo.new(.22,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
local shadows=setmetatable({},{__mode="k"})

local function heightOf(o)
 local h=o.Size.Y.Offset
 if o.Size.Y.Scale~=0 or h<=0 then h=math.max(o.AbsoluteSize.Y,h,40) end
 return h
end
local function radiusOf(o)
 local c=o:FindFirstChildOfClass("UICorner") return c and c.CornerRadius.Offset or 10
end
local function inLayout(o)
 local p=o.Parent
 return p~=nil and (p:FindFirstChildOfClass("UIListLayout")~=nil or p:FindFirstChildOfClass("UIGridLayout")~=nil)
end

function T.tone(color)
 return {hi=color:Lerp(WHITE,.22),base=color,sh=color:Lerp(BLACK,.34)}
end

local click
local function playClick()
 if not click then
  click=Instance.new("Sound") click.Name="MenuClick" click.SoundId="rbxasset://sounds/clickfast.wav" click.Volume=.35 click.Parent=SoundService
 end
 click:Play()
end

function T.studs(o,alpha,tile)
 local t=o:FindFirstChild("SurfaceStuds")
 if not t then
  t=Instance.new("ImageLabel") t.Name="SurfaceStuds" t.BackgroundTransparency=1 t.Active=false
  t.Image=T.Texture t.ScaleType=Enum.ScaleType.Tile t.Size=UDim2.fromScale(1,1)
  Instance.new("UICorner").Parent=t
  t.Parent=o
 end
 t.TileSize=UDim2.fromOffset(tile or 15,tile or 15)
 t.ImageTransparency=alpha or T.StudTransparency
 t.ZIndex=o.ZIndex
 t:FindFirstChildOfClass("UICorner").CornerRadius=UDim.new(0,radiusOf(o))
end

local function shadowFor(o)
 local parent=o.Parent
 if shadows[o] or not (parent and parent:IsA("GuiObject")) or inLayout(o) or o.Name=="Header" then return end
 local s=Instance.new("Frame") s.Name=o.Name.."_Shadow" s.BackgroundColor3=T.Outline s.BackgroundTransparency=.55 s.BorderSizePixel=0 s.Active=false
 local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,radiusOf(o)) c.Parent=s
 local drop=o:IsA("GuiButton") and 4 or 5
 local base=o.ZIndex
 o.ZIndex=base+1
 local function sync()
  s.AnchorPoint=o.AnchorPoint s.Size=o.Size s.Position=o.Position+UDim2.fromOffset(0,drop)
  s.Visible=o.Visible s.ZIndex=o.ZIndex-1
 end
 sync() s.Parent=parent shadows[o]=s
 for _,prop in {"Position","Size","AnchorPoint","Visible","ZIndex"} do o:GetPropertyChangedSignal(prop):Connect(sync) end
 o.AncestryChanged:Connect(function()
  if not o.Parent then s:Destroy() elseif s.Parent~=o.Parent then s.Parent=o.Parent end
 end)
end

local function finish(o)
 if o:IsA("ScrollingFrame") or o:IsA("TextBox") or o:IsA("ViewportFrame") then return end
 local h=heightOf(o) local r=radiusOf(o)
 if not o:FindFirstChild("Bevel") then
  local bh=math.clamp(math.floor(h*.08),3,8)
  local b=Instance.new("Frame") b.Name="Bevel" b.BackgroundColor3=WHITE b.BackgroundTransparency=.35 b.BorderSizePixel=0 b.Active=false
  b.Size=UDim2.new(1,-math.floor(r*1.6),0,bh) b.Position=UDim2.new(0,math.floor(r*.8),0,math.max(2,math.floor(h*.045)))
  b.ZIndex=o.ZIndex b.Parent=o
  local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,math.floor(bh/2)) c.Parent=b
  local g=Instance.new("UIGradient") g.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.18,0),NumberSequenceKeypoint.new(.82,0),NumberSequenceKeypoint.new(1,1)}) g.Parent=b
 end
 if not o:FindFirstChild("Underside") then
  local uh=math.min(26,math.max(4,math.floor(h*.16)))
  local u=Instance.new("Frame") u.Name="Underside" u.BackgroundColor3=T.Outline u.BorderSizePixel=0 u.Active=false
  u.Size=UDim2.new(1,0,0,uh) u.Position=UDim2.new(0,0,1,-uh) u.ZIndex=o.ZIndex u.Parent=o
  local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,r) c.Parent=u
  local g=Instance.new("UIGradient") g.Rotation=90 g.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,.82)}) g.Parent=u
 end
 shadowFor(o)
end

function T.round(o,radius,color,thickness)
 local c=o:FindFirstChildOfClass("UICorner") or Instance.new("UICorner") c.CornerRadius=UDim.new(0,radius or 12) c.Parent=o
 local s=o:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
 s.Color=color or T.Outline s.Thickness=thickness or 3 s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border s.LineJoinMode=Enum.LineJoinMode.Round s.Parent=o
 o.BorderSizePixel=0
 T.studs(o,T.StudTransparency,o:IsA("GuiButton") and 11 or 15)
 finish(o)
end

function T.gradient(o,color)
 local tone=T.tone(color)
 o.BackgroundColor3=WHITE
 local g=o:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient")
 local breakAt=math.clamp(28/heightOf(o),.12,.5)
 g.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,tone.hi),ColorSequenceKeypoint.new(breakAt,tone.base),ColorSequenceKeypoint.new(1,tone.sh)})
 g.Rotation=90 g.Parent=o
 local bevel=o:FindFirstChild("Bevel") if bevel then bevel.BackgroundColor3=tone.hi:Lerp(WHITE,.3) end
 return g
end

function T.text(parent,name,value,pos,size,font)
 local t=Instance.new("TextLabel") t.Name=name t.BackgroundTransparency=1 t.Text=value t.Font=Enum.Font.FredokaOne
 t.TextSize=font or 24 t.TextColor3=WHITE t.Position=pos t.Size=size t.ZIndex=3 t.Parent=parent
 local s=Instance.new("UIStroke") s.Color=T.Outline s.Thickness=math.max(2,(font or 24)*.11) s.LineJoinMode=Enum.LineJoinMode.Round s.Parent=t
 return t
end

function T.closeMark(button)
 button.TextTransparency=1
 local caption=button:FindFirstChild("Caption") if caption then caption.Visible=false end
 if button:FindFirstChild("CloseMark") then return end
 local mark=Instance.new("Frame") mark.Name="CloseMark" mark.BackgroundTransparency=1
 mark.AnchorPoint=Vector2.new(.5,.5) mark.Position=UDim2.fromScale(.5,.5) mark.Size=UDim2.fromScale(.5,.5) mark.ZIndex=4 mark.Parent=button
 local aspect=Instance.new("UIAspectRatioConstraint") aspect.AspectRatio=1 aspect.DominantAxis=Enum.DominantAxis.Height aspect.Parent=mark
 for _,angle in {-45,45} do
  local line=Instance.new("Frame") line.Name="Outline" line.AnchorPoint=Vector2.new(.5,.5) line.Position=UDim2.fromScale(.5,.5)
  line.Size=UDim2.fromScale(1.1,.36) line.Rotation=angle line.BackgroundColor3=T.Outline line.BorderSizePixel=0 line.ZIndex=4 line.Parent=mark
  Instance.new("UICorner",line).CornerRadius=UDim.new(.5,0)
  local fill=Instance.new("Frame") fill.Name="White" fill.AnchorPoint=Vector2.new(.5,.5) fill.Position=UDim2.fromScale(.5,.5)
  fill.Size=UDim2.fromScale(.84,.52) fill.BackgroundColor3=WHITE fill.BorderSizePixel=0 fill.ZIndex=5 fill.Parent=line
  Instance.new("UICorner",fill).CornerRadius=UDim.new(.5,0)
 end
end

local wireReact
function T.react(b)
 if b:FindFirstChild("HoverScale") then return end
 local sc=Instance.new("UIScale") sc.Name="HoverScale" sc.Parent=b
 wireReact(b,sc)
end
wireReact=function(b,sc)
 local ssc
 local s=shadows[b] if s then ssc=s:FindFirstChildOfClass("UIScale") or Instance.new("UIScale") ssc.Parent=s end
 local function to(k)
  TweenService:Create(sc,FAST,{Scale=k}):Play()
  if ssc then TweenService:Create(ssc,FAST,{Scale=k}):Play() end
 end
 local function fillOf() local r=b:FindFirstChild("BtnBorder") r=r and r:FindFirstChild("BtnRim") return r and r:FindFirstChild("BtnFill") end
 local function glow(on)
  local fill=fillOf() if not fill then return end
  local h=fill:FindFirstChild("BtnHover")
  if not h then
   h=Instance.new("Frame") h.Name="BtnHover" h.BackgroundColor3=WHITE h.BackgroundTransparency=1 h.BorderSizePixel=0 h.Active=false
   h.Size=UDim2.fromScale(1,1) h.ZIndex=fill.ZIndex+1 h.Parent=fill
   local fc=fill:FindFirstChildOfClass("UICorner") if fc then Instance.new("UICorner",h).CornerRadius=fc.CornerRadius end
  end
  TweenService:Create(h,FAST,{BackgroundTransparency=(on and b.Active) and .8 or 1}):Play()
 end
 local function grow() if fillOf() then return 1 end return b.Active and 1.06 or 1.02 end
 b.MouseEnter:Connect(function() to(grow()) glow(true) end)
 b.MouseLeave:Connect(function() to(1) glow(false) end)
 b.MouseButton1Down:Connect(function() if b.Active then to(.95) end end)
 b.MouseButton1Up:Connect(function() to(UIS.TouchEnabled and 1 or grow()) end)
 b.Activated:Connect(function() if b.Active then playClick() end end)
end

function T.button(parent,name,value,pos,size,color)
 local b=Instance.new("TextButton") b.Name=name b.Text=value b.Font=Enum.Font.FredokaOne b.TextSize=23 b.TextColor3=WHITE
 b.AutoButtonColor=false b.Position=pos b.Size=size b.BackgroundColor3=WHITE b.Parent=parent
 T.round(b,10,nil,3) T.gradient(b,color) b.TextTransparency=1
 local caption=T.text(b,"Caption",value,UDim2.fromOffset(4,2),UDim2.new(1,-8,1,-4),23)
 caption.TextScaled=true
 local limit=Instance.new("UITextSizeConstraint") limit.MinTextSize=10 limit.MaxTextSize=b.TextSize limit.Parent=caption
 b:GetPropertyChangedSignal("Text"):Connect(function() caption.Text=b.Text end)
 b:GetPropertyChangedSignal("TextSize"):Connect(function() limit.MaxTextSize=b.TextSize end)
 if name=="Close" then T.closeMark(b) end
 T.react(b)
 return b
end

local blurHolders=0
local function holdBlur(on)
 local blur=Lighting:FindFirstChild("PanelBlur")
 if not blur then blur=Instance.new("BlurEffect") blur.Name="PanelBlur" blur.Size=28 blur.Parent=Lighting end
 blurHolders=math.max(0,blurHolders+(on and 1 or -1))
 blur.Enabled=blurHolders>0
end

local WIN_INK=Color3.fromRGB(14,14,18)
local WIN_HEAD=78
local WIN_TARGET_H=600
local DECOR={SurfaceStuds=true,Bevel=true,Underside=true,WinRim=true}
T.WindowAlpha=.5
T.CardAlpha=.55
local function miter(o,thickness,color)
 local s=o:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
 s.Thickness=thickness s.Color=color or WIN_INK s.LineJoinMode=Enum.LineJoinMode.Miter
 s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border s.Enabled=true s.Parent=o
 return s
end
local function square(o)
 local c=o:FindFirstChildOfClass("UICorner") if c then c:Destroy() end
 for _,n in {"Bevel","Underside"} do local x=o:FindFirstChild(n) if x then x.Visible=false end end
 local st=o:FindFirstChild("SurfaceStuds") local sc=st and st:FindFirstChildOfClass("UICorner") if sc then sc.CornerRadius=UDim.new(0,0) end
 local sh=shadows[o] if sh then sh.BackgroundTransparency=1 end
end
local function innerRim(o,color,transparency)
 local r=o:FindFirstChild("WinRim") or Instance.new("Frame")
 r.Name="WinRim" r.BackgroundTransparency=1 r.Active=false r.Size=UDim2.new(1,-4,1,-4) r.Position=UDim2.fromOffset(2,2) r.ZIndex=o.ZIndex r.Parent=o
 miter(r,2,color).Transparency=transparency
 return r
end
local function inkText(label,thickness)
 local s=label:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
 s.Thickness=math.max(thickness,s.Thickness) s.Color=WIN_INK s.LineJoinMode=Enum.LineJoinMode.Round
 s.ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual s.Parent=label
end
local function titleCase(s)
 return (s:lower():gsub("(%a)([%w']*)",function(first,rest) return first:upper()..rest end))
end
local function insideButton(o,stop)
 if o:GetAttribute("KeepCorners") then return true end
 local a=o.Parent
 while a and a~=stop do if (a:IsA("GuiButton") and a:GetAttribute("WinSkinned")) or a:GetAttribute("KeepCorners") then return true end a=a.Parent end
 return false
end
function T.windowButton(b)
 if b:GetAttribute("WinSkinned") then return end
 b:SetAttribute("WinSkinned",true)
 local pz=b.Parent and b.Parent:IsA("GuiObject") and b.Parent.ZIndex or 0
 if b.ZIndex<=pz+1 then
  local lift=pz+2-b.ZIndex b.ZIndex+=lift
  for _,d in b:GetDescendants() do if d:IsA("GuiObject") then d.ZIndex+=lift end end
 end
 square(b)
 local h=math.max(b.AbsoluteSize.Y,b.Size.Y.Offset,20)
 local radius=math.clamp(math.floor(h*.22),6,10)
 local old=b:FindFirstChild("WinRim") if old then old:Destroy() end
 local ink=b:FindFirstChildOfClass("UIStroke") if ink then ink.Enabled=false end
 b.BackgroundTransparency=1
 local z=b.ZIndex
 local function layer(parent,name,inset,color,r,zi)
  local f=Instance.new("Frame") f.Name=name f.Active=false f.BorderSizePixel=0 f.BackgroundColor3=color
  f.AnchorPoint=Vector2.new(.5,.5) f.Position=UDim2.fromScale(.5,.5) f.Size=UDim2.new(1,-inset*2,1,-inset*2) f.ZIndex=zi f.Parent=parent
  Instance.new("UICorner",f).CornerRadius=UDim.new(0,math.max(2,r))
  return f
 end
 local border=layer(b,"BtnBorder",0,WIN_INK,radius,z+1)
 local rim=layer(border,"BtnRim",2,BLACK,radius-2,z+2)
 local fill=layer(rim,"BtnFill",2,WHITE,radius-4,z+3)
 local fg=Instance.new("UIGradient") fg.Rotation=90 fg.Parent=fill
 local st=b:FindFirstChild("SurfaceStuds") or Instance.new("ImageLabel")
 st.Name="SurfaceStuds" st.BackgroundTransparency=1 st.Active=false st.Image=T.Texture st.ScaleType=Enum.ScaleType.Tile
 st.AnchorPoint=Vector2.zero st.Position=UDim2.new() st.Size=UDim2.fromScale(1,1) st.Visible=true st.Parent=fill
 local tile=math.clamp(math.floor(h*.15),4,12)
 st.TileSize=UDim2.fromOffset(tile,tile) st.ImageTransparency=.3 st.ZIndex=z+4
 local sc=st:FindFirstChildOfClass("UICorner") or Instance.new("UICorner",st) sc.CornerRadius=UDim.new(0,math.max(2,radius-4))
 for _,c in b:GetChildren() do
  if c:IsA("GuiObject") and c~=border and c.Visible and c.ZIndex<=z+4 then
   local lift=z+5-c.ZIndex c.ZIndex+=lift
   for _,d in c:GetDescendants() do if d:IsA("GuiObject") then d.ZIndex+=lift end end
  end
 end
 local function shade()
  local g=b:FindFirstChildOfClass("UIGradient")
  local k=g and g.Color.Keypoints
  local base=k and k[math.min(2,#k)].Value or WHITE
  local top=k and k[1].Value or base:Lerp(WHITE,.22)
  fg.Color=ColorSequence.new(top,base)
  rim.BackgroundColor3=base:Lerp(BLACK,.45)
 end
 shade()
 local g=b:FindFirstChildOfClass("UIGradient") if g then g:GetPropertyChangedSignal("Color"):Connect(shade) end
 local cap=b:FindFirstChild("Caption")
 local sym=cap and (cap.Text=="+" or cap.Text=="-") and cap.Text
 if sym and not b:FindFirstChild("Symbol") then
  cap.TextTransparency=1 local cs=cap:FindFirstChildOfClass("UIStroke") if cs then cs.Enabled=false end
  local box=Instance.new("Frame") box.Name="Symbol" box.BackgroundTransparency=1 box.Active=false
  box.AnchorPoint=Vector2.new(.5,.5) box.Position=UDim2.fromScale(.5,.5) box.Size=UDim2.fromOffset(26,26) box.ZIndex=z+6 box.Parent=b
  for i,look in {{WIN_INK,0},{WHITE,4}} do
   for _,angle in (sym=="+" and {0,90} or {0}) do
    local bar=Instance.new("Frame") bar.Name=i==1 and "BarOutline" or "Bar" bar.AnchorPoint=Vector2.new(.5,.5) bar.Position=UDim2.fromScale(.5,.5)
    bar.Size=UDim2.fromOffset(26-look[2],10-look[2]) bar.Rotation=angle bar.BackgroundColor3=look[1] bar.BorderSizePixel=0 bar.Active=false
    bar.ZIndex=z+(i==1 and 6 or 7) bar.Parent=box
    Instance.new("UICorner",bar).CornerRadius=UDim.new(.5,0)
   end
  end
 end
 for _,t in b:GetChildren() do if t:IsA("TextLabel") then inkText(t,h<40 and 2.5 or 3.5) end end
end
local function closeX(close)
 square(close)
 miter(close,3)
 innerRim(close,Color3.fromRGB(120,10,10),.1)
 local st=close:FindFirstChild("SurfaceStuds") if st then st.ImageTransparency=.4 st.TileSize=UDim2.fromOffset(9,9) st.Visible=true st.ZIndex=close.ZIndex+1 end
 local g=close:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient")
 g.Rotation=90 g.Color=ColorSequence.new(Color3.fromRGB(245,60,50),Color3.fromRGB(190,20,20)) g.Parent=close
 close.TextTransparency=1
 for _,n in {"CloseMark","CloseGlyph","Caption"} do local x=close:FindFirstChild(n) if x then x.Visible=false end end
 local x=close:FindFirstChild("WinX")
 if not x then
  x=Instance.new("Frame") x.Name="WinX" x.BackgroundTransparency=1 x.Active=false
  x.AnchorPoint=Vector2.new(.5,.5) x.Position=UDim2.fromScale(.5,.5) x.Size=UDim2.fromScale(.62,.62) x.Parent=close
  Instance.new("UIAspectRatioConstraint",x).AspectRatio=1
  for i,look in {{WIN_INK,0},{WHITE,6}} do
   for _,angle in {45,-45} do
    local arm=Instance.new("Frame") arm.Name=i==1 and "ArmOutline" or "Arm" arm.AnchorPoint=Vector2.new(.5,.5) arm.Position=UDim2.fromScale(.5,.5)
    arm.Size=UDim2.new(1.2,-look[2],.3,-look[2]) arm.Rotation=angle arm.BackgroundColor3=look[1] arm.BorderSizePixel=0 arm.Active=false arm.Parent=x
    Instance.new("UICorner",arm).CornerRadius=UDim.new(.5,0)
   end
  end
 end
 x.ZIndex=close.ZIndex+3
 for _,arm in x:GetChildren() do if arm:IsA("Frame") then arm.ZIndex=close.ZIndex+(arm.Name=="Arm" and 4 or 3) end end
end
local function bodyChildren(panel,head)
 local list={}
 for _,c in panel:GetChildren() do
  if c:IsA("GuiObject") and c~=head and not DECOR[c.Name] and not c.Name:match("_Shadow$")
   and c.Position.Y.Scale==0 and c.Size.Y.Scale<1 then
   table.insert(list,c)
  end
 end
 return list
end
local function straddle(panel,head)
 if panel:GetAttribute("WinShifted") then return end
 panel:SetAttribute("WinShifted",true)
 local list=bodyChildren(panel,head)
 local top=math.huge
 for _,c in list do top=math.min(top,c.Position.Y.Offset) end
 local delta=top-(WIN_HEAD/2+16)
 if top==math.huge or delta<=0 then return end
 for _,c in list do c.Position-=UDim2.fromOffset(0,delta) end
 panel.Size-=UDim2.fromOffset(0,delta)
end
local NO_STUDS={WinRim=true,Studs=true,SurfaceStuds=true,Bevel=true,Underside=true,Backdrop=true,Header=true,WinX=true}
local function studBlock(o)
 if NO_STUDS[o.Name] or o.Name:match("_Shadow$") or o:GetAttribute("WinStuds") then return end
 if not (o:IsA("Frame") or o:IsA("ScrollingFrame") or o:IsA("TextBox") or o:IsA("CanvasGroup")) then return end
 if o.BackgroundTransparency>=.9 or not o.Visible then return end
 local size=o.AbsoluteSize if size.X<16 or size.Y<10 then return end
 o:SetAttribute("WinStuds",true)
 local st=o:FindFirstChild("SurfaceStuds")
 if not st then
  st=Instance.new("ImageLabel") st.Name="SurfaceStuds" st.BackgroundTransparency=1 st.Active=false
  st.Image=T.Texture st.ScaleType=Enum.ScaleType.Tile st.Size=UDim2.fromScale(1,1) st.Parent=o
 end
 local tile=math.clamp(math.floor(math.min(size.X,size.Y)*.15),4,16)
 local c=o.BackgroundColor3 local lum=.299*c.R+.587*c.G+.114*c.B
 st.TileSize=UDim2.fromOffset(tile,tile) st.ImageTransparency=lum<.35 and .62 or .35
 st.ZIndex=o.ZIndex st.Visible=true
 local corner=o:FindFirstChildOfClass("UICorner")
 if corner then local sc=st:FindFirstChildOfClass("UICorner") or Instance.new("UICorner",st) sc.CornerRadius=corner.CornerRadius end
end
local function skinContent(panel,head)
 straddle(panel,head)
 local close=head:FindFirstChild("Close") if close then closeX(close) end
 for _,o in panel:GetDescendants() do
  if o:IsA("GuiObject") and o~=head and not o:IsDescendantOf(head) and o~=panel and not insideButton(o,panel) then
   if o:FindFirstChild("Bevel") then
    if o:IsA("GuiButton") then T.windowButton(o)
    elseif not o:GetAttribute("WinSkinned") then
     o:SetAttribute("WinSkinned",true) square(o)
     local g=o:FindFirstChildOfClass("UIGradient") if g then g:Destroy() end
     o.BackgroundColor3=Color3.fromRGB(38,41,47) o.BackgroundTransparency=T.CardAlpha
     local st=o:FindFirstChild("SurfaceStuds") if st then st.Visible=false end
     miter(o,2,Color3.fromRGB(24,26,30))
     studBlock(o)
    end
   elseif not o:IsA("ImageLabel") then
    local c=o:FindFirstChildOfClass("UICorner") if c then c:Destroy() end
    studBlock(o)
   end
  end
 end
end
local function skinWindow(panel,head,color)
 local h,s,v=color:ToHSV()
 if s<.4 then color=Color3.fromRGB(56,150,255) h,s,v=color:ToHSV() end
 local shift=(h>.1 and h<.2) and -.06 or .07
 local pal={color,Color3.fromHSV((h+shift)%1,s*.85,math.min(1,v*1.1+.1)),color:Lerp(BLACK,.4)}
 square(panel)
 local pg=panel:FindFirstChildOfClass("UIGradient") if pg then pg:Destroy() end
 panel.BackgroundColor3=Color3.fromRGB(58,62,69) panel.BackgroundTransparency=T.WindowAlpha
 miter(panel,4)
 local studs=panel:FindFirstChild("SurfaceStuds") if studs then studs.ImageTransparency=.82 studs.TileSize=UDim2.fromOffset(22,22) studs.Visible=true end
 innerRim(panel,Color3.fromRGB(96,101,110),.3).ZIndex=0
 square(head)
 local lift=10-head.ZIndex
 if lift>0 then
  head.ZIndex+=lift
  for _,d in head:GetDescendants() do if d:IsA("GuiObject") then d.ZIndex+=lift end end
 end
 head.Position=UDim2.fromOffset(-10,-WIN_HEAD/2) head.Size=UDim2.new(1,20,0,WIN_HEAD)
 head.BackgroundTransparency=0
 local hg=head:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient")
 hg.Rotation=0 hg.Color=ColorSequence.new(pal[1],pal[2]) hg.Parent=head
 miter(head,4)
 local hs=head:FindFirstChild("SurfaceStuds") if hs then hs.ImageTransparency=.72 hs.TileSize=UDim2.fromOffset(20,20) end
 innerRim(head,pal[3],0)
 local iconX=12
 local icon=head:FindFirstChild("MenuIcon")
 local shade=head:FindFirstChild("MenuIconShadow") if shade then shade.Visible=false end
 if icon then
  icon.AnchorPoint=Vector2.new(0,.5) icon.Position=UDim2.new(0,-8,.5,-4) icon.Size=UDim2.fromOffset(WIN_HEAD+34,WIN_HEAD+34)
  iconX=WIN_HEAD+32
 end
 local title=head:FindFirstChild("Title")
 if title then
  title.Text=titleCase(title.Text)
  title.AnchorPoint=Vector2.new(0,.5) title.Position=UDim2.new(0,iconX,.5,0)
  title.Size=UDim2.new(1,-(iconX+WIN_HEAD+20),.8,0) title.TextXAlignment=Enum.TextXAlignment.Left title.TextScaled=true
  local lim=title:FindFirstChildOfClass("UITextSizeConstraint") if lim then lim.MaxTextSize=64 end
  local ts=title:FindFirstChildOfClass("UIStroke") if ts then ts.Thickness=2.5 ts.Color=WIN_INK end
 end
 local close=head:FindFirstChild("Close")
 if close then
  close.AnchorPoint=Vector2.new(1,.5) close.Position=UDim2.new(1,-9,.5,0) close.Size=UDim2.fromOffset(WIN_HEAD-16,WIN_HEAD-16)
  closeX(close)
 end
end

function T.header(panel,head,icon,color)
 T.round(panel,15,nil,3) T.gradient(panel,T.Dark)
 panel.BackgroundTransparency=.35
 local height=math.clamp(math.floor(panel.Size.X.Offset*.105),68,84)
 head.Name="Header" head.Position=UDim2.fromOffset(0,0) head.Size=UDim2.new(1,0,0,height)
 T.round(head,12,nil,3) T.gradient(head,color or T.Yellow)
 T.studs(head,.58,10)
 local title=head:FindFirstChild("Title")
 title.Position=UDim2.fromOffset(78,5) title.Size=UDim2.new(1,-156,1,-10)
 title.TextXAlignment=Enum.TextXAlignment.Center title.TextScaled=true title.ZIndex=6
 local lim=title:FindFirstChildOfClass("UITextSizeConstraint") or Instance.new("UITextSizeConstraint") lim.MinTextSize=18 lim.MaxTextSize=math.floor(height*.62) lim.Parent=title
 title.UIStroke.Thickness=4 title.UIStroke.Color=T.TitleInk
 local iconSide=height-14
 if type(icon)=="string" and icon:match("^rbxasset") then
  local shadow=Instance.new("ImageLabel") shadow.Name="MenuIconShadow" shadow.BackgroundTransparency=1 shadow.Image=icon shadow.ScaleType=Enum.ScaleType.Fit
  shadow.ImageColor3=BLACK shadow.ImageTransparency=.55 shadow.Size=UDim2.fromOffset(iconSide,iconSide) shadow.Position=UDim2.fromOffset(12,11) shadow.ZIndex=5 shadow.Parent=head
  local img=Instance.new("ImageLabel") img.Name="MenuIcon" img.BackgroundTransparency=1 img.Image=icon img.ScaleType=Enum.ScaleType.Fit
  img.Size=UDim2.fromOffset(iconSide,iconSide) img.Position=UDim2.fromOffset(12,7) img.ZIndex=6 img.Parent=head
 else
  T.text(head,"MenuIcon",icon or "",UDim2.fromOffset(12,6),UDim2.fromOffset(iconSide,iconSide),42)
 end
 local close=head:FindFirstChild("Close")
 local side=height-24
 close.AnchorPoint=Vector2.new(0,.5) close.Position=UDim2.new(1,-side-14,.5,0) close.Size=UDim2.fromOffset(side,side) close.Text="×" close.TextSize=38
 T.gradient(close,T.Red) T.studs(close,.7,9)
 local st=close:FindFirstChildOfClass("UIStroke") if st then st.Thickness=2 end
 skinWindow(panel,head,color or T.Yellow)
 T.windowBehaviour(panel,function() skinContent(panel,head) end)
end
function T.windowBehaviour(panel,onShow)
 local norm
 local function normalizer()
  if norm then return norm end
  local sc=panel:FindFirstChildOfClass("UIScale") if not sc then return nil end
  norm={sc=sc,base=sc.Scale,writing=false,tween=false}
  function norm.target()
   local h=math.max(1,panel.Size.Y.Offset) local w=math.max(1,panel.Size.X.Offset)
   local v=workspace.CurrentCamera.ViewportSize
   local s=norm.base*(WIN_TARGET_H/h)
   if v.X>100 and v.Y>100 then s=math.min(s,(v.X-24)/(w+20),(v.Y-40)/(h+WIN_HEAD/2)) end
   return s
  end
  local mine={}
  local function write(v) mine[math.floor(v*10000+.5)]=true sc.Scale=v end
  norm.write=write
  function norm.apply() if norm.tween then return end write(norm.target()) end
  sc:GetPropertyChangedSignal("Scale"):Connect(function()
   local key=math.floor(sc.Scale*10000+.5)
   if norm.tween or mine[key] then return end
   norm.base=sc.Scale norm.apply()
  end)
  return norm
 end
 local holding=false
 local function visibility()
  if panel.Visible and onShow then onShow() end
  if panel.Visible and not holding then
   holding=true holdBlur(true)
   local n=normalizer()
   if n then
    if n.tw then n.tw:Cancel() end
    n.token=(n.token or 0)+1 local token=n.token
    local target=n.target()
    n.tween=true n.write(target*.82)
    local tw=TweenService:Create(n.sc,POP,{Scale=target}) n.tw=tw
    tw.Completed:Connect(function() if n.token==token then n.tw=nil n.tween=false n.apply() end end)
    tw:Play()
   end
  elseif not panel.Visible and holding then
   holding=false holdBlur(false)
   if norm and norm.tw then norm.token=(norm.token or 0)+1 norm.tw:Cancel() norm.tw=nil norm.tween=false norm.apply() end
  end
 end
 panel:GetPropertyChangedSignal("Visible"):Connect(visibility)
 panel.AncestryChanged:Connect(function() if not panel.Parent and holding then holding=false holdBlur(false) end end)
 visibility()
end
local wired=setmetatable({},{__mode="k"})
local function findShadow(o)
 local parent=o.Parent
 if not parent then return nil end
 for _,s in parent:GetChildren() do
  if s~=o and s.Name==o.Name.."_Shadow" and s:IsA("Frame") then
   local d=s.Position-o.Position
   if d.X.Scale==0 and d.Y.Scale==0 and d.X.Offset==0 and d.Y.Offset>=0 and d.Y.Offset<=8 and s.Size==o.Size then return s,d.Y.Offset end
  end
 end
 return nil
end
local function followShadow(o)
 local s,drop=findShadow(o)
 if not s then return end
 shadows[o]=s
 local function sync()
  s.AnchorPoint=o.AnchorPoint s.Size=o.Size s.Position=o.Position+UDim2.fromOffset(0,drop)
  s.Visible=o.Visible s.ZIndex=o.ZIndex-1
 end
 for _,prop in {"Position","Size","AnchorPoint","Visible","ZIndex"} do o:GetPropertyChangedSignal(prop):Connect(sync) end
 o.AncestryChanged:Connect(function()
  if not o.Parent then s:Destroy() elseif s.Parent~=o.Parent then s.Parent=o.Parent end
 end)
 sync()
end
local function followFill(b)
 local border=b:FindFirstChild("BtnBorder")
 local rim=border and border:FindFirstChild("BtnRim")
 local fill=rim and rim:FindFirstChild("BtnFill")
 local fg=fill and fill:FindFirstChildOfClass("UIGradient")
 local g=b:FindFirstChildOfClass("UIGradient")
 if not (fg and g) then return end
 g:GetPropertyChangedSignal("Color"):Connect(function()
  local k=g.Color.Keypoints
  local base=k[math.min(2,#k)].Value
  fg.Color=ColorSequence.new(k[1].Value,base)
  rim.BackgroundColor3=base:Lerp(BLACK,.45)
 end)
end
function T.adoptButton(b)
 if wired[b] then return end
 wired[b]=true
 local cap=b:FindFirstChild("Caption")
 if cap and cap:IsA("TextLabel") then
  b:GetPropertyChangedSignal("Text"):Connect(function() if b.Text~="" then cap.Text=b.Text end end)
 end
 followFill(b)
 local sc=b:FindFirstChild("HoverScale")
 if sc and sc:IsA("UIScale") then wireReact(b,sc) end
end
function T.adopt(root)
 local list=root:GetDescendants()
 table.insert(list,root)
 for _,o in list do
  if o:IsA("GuiObject") and not wired[o] then
   if shadows[o]==nil then followShadow(o) end
   if o:IsA("GuiButton") then T.adoptButton(o) else wired[o]=true end
  end
 end
end
function T.adoptWindow(panel)
 T.adopt(panel)
 T.windowBehaviour(panel)
end
function T.copy(template,parent,name)
 local c=template:Clone()
 c.Name=name or template.Name
 c:SetAttribute("IsTemplate",nil)
 local s=findShadow(template)
 if s then
  local cs=s:Clone()
  cs.Name=c.Name.."_Shadow"
  cs.Parent=parent
 end
 c.Parent=parent
 c.Visible=true
 T.adopt(c)
 return c
end

local INK=Color3.fromRGB(12,10,18)
T.Ink=INK
function T.cardText(parent,name,text,y,h,size,color)
 local t=Instance.new("TextLabel") t.Name=name t.BackgroundTransparency=1 t.Position=UDim2.fromOffset(4,y) t.Size=UDim2.new(1,-8,0,h)
 t.Font=Enum.Font.FredokaOne t.RichText=true t.Text=text t.TextSize=size t.TextColor3=color or WHITE t.ZIndex=4 t.Parent=parent
 local s=Instance.new("UIStroke") s.Color=INK s.Thickness=math.max(2,size*.12) s.LineJoinMode=Enum.LineJoinMode.Round s.Parent=t
 return t
end
function T.paintCard(card,color)
 card.BackgroundColor3=WHITE card.BorderSizePixel=0 card.ClipsDescendants=false
 Instance.new("UICorner",card).CornerRadius=UDim.new(0,12)
 local s=Instance.new("UIStroke") s.Color=color:Lerp(WHITE,.12) s.Thickness=4 s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border s.Parent=card
 local g=Instance.new("UIGradient") g.Rotation=90 g.Color=ColorSequence.new(color:Lerp(BLACK,.42),color:Lerp(BLACK,.72)) g.Parent=card
end
function T.shopButton(parent,name,text,pos,size,color)
 local b=Instance.new("TextButton") b.Name=name b.AutoButtonColor=false b.Text="" b.TextTransparency=1 b.Position=pos b.Size=size
 b.BorderSizePixel=0 b.BackgroundColor3=WHITE b.ZIndex=4 b.Parent=parent
 Instance.new("UICorner",b).CornerRadius=UDim.new(0,7)
 local s=Instance.new("UIStroke") s.Color=INK s.Thickness=2.5 s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border s.Parent=b
 local g=Instance.new("UIGradient") g.Rotation=90 g.Parent=b
 local label=T.cardText(b,"Caption",text,0,size.Y.Offset,math.floor(size.Y.Offset*.62)) label.Position=UDim2.new() label.Size=UDim2.fromScale(1,1) label.ZIndex=5
 b:GetPropertyChangedSignal("Text"):Connect(function() if b.Text~="" then label.Text=b.Text end end)
 local function paint(c)
  g.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,c:Lerp(WHITE,.28)),ColorSequenceKeypoint.new(.5,c),ColorSequenceKeypoint.new(1,c:Lerp(BLACK,.28))})
 end
 paint(color)
 T.react(b)
 return b,paint,label
end
local monetizationConfig
local function RS_MONETIZATION_CONFIG()
 if monetizationConfig==nil then
  local folder=game:GetService("ReplicatedStorage"):FindFirstChild("Monetization")
  local module=folder and folder:FindFirstChild("Config")
  local ok,value=pcall(function() return require(module) end)
  monetizationConfig=(ok and type(value)=="table") and value or {UseLivePrices=true}
 end
 return monetizationConfig
end
T.RobuxIcon="rbxasset://textures/ui/common/robux.png"
function T.robuxButton(parent,name,pos,size,price,productId,label,color,infoType)
 local b=T.shopButton(parent,name,"",pos,size,color or Color3.fromRGB(222,40,232))
 b.Caption.Visible=false
 local h=size.Y.Offset
 local row=Instance.new("Frame") row.Name="Content" row.BackgroundTransparency=1 row.Size=UDim2.fromScale(1,1) row.ZIndex=5 row.Parent=b
 local list=Instance.new("UIListLayout") list.FillDirection=Enum.FillDirection.Horizontal list.HorizontalAlignment=Enum.HorizontalAlignment.Center
 list.VerticalAlignment=Enum.VerticalAlignment.Center list.Padding=UDim.new(0,4) list.SortOrder=Enum.SortOrder.LayoutOrder list.Parent=row
 local font=math.floor(h*.6)
 local function word(n,text,order)
  local t=T.cardText(row,n,text,0,h,font) t.AutomaticSize=Enum.AutomaticSize.X t.Size=UDim2.fromOffset(0,h) t.LayoutOrder=order t.ZIndex=6 return t
 end
 if label then word("Label",label,1) end
 local side=math.floor(h*.72)
 local frame=Instance.new("Frame") frame.Name="RobuxFrame" frame.BackgroundTransparency=1 frame.Size=UDim2.fromOffset(side,side) frame.LayoutOrder=2 frame.ZIndex=6 frame.Parent=row
 local edge=math.max(1,math.floor(side*.07+.5))
 for _,o in {{-1,0},{1,0},{0,-1},{0,1},{-1,-1},{1,-1},{-1,1},{1,1}} do
  local rim=Instance.new("ImageLabel") rim.Name="Rim" rim.BackgroundTransparency=1 rim.Image=T.RobuxIcon rim.ImageColor3=INK rim.ScaleType=Enum.ScaleType.Fit
  rim.AnchorPoint=Vector2.new(.5,.5) rim.Position=UDim2.new(.5,o[1]*edge,.5,o[2]*edge) rim.Size=UDim2.fromScale(1,1) rim.ZIndex=6 rim.Parent=frame
 end
 local mark=Instance.new("ImageLabel") mark.Name="RobuxIcon" mark.BackgroundTransparency=1 mark.Image=T.RobuxIcon mark.ImageColor3=WHITE mark.ScaleType=Enum.ScaleType.Fit
 mark.AnchorPoint=Vector2.new(.5,.5) mark.Position=UDim2.fromScale(.5,.5) mark.Size=UDim2.fromScale(1,1) mark.ZIndex=7 mark.Parent=frame
 local amount=word("Amount",tostring(price),3)
 local pricing=RS_MONETIZATION_CONFIG()
 if (productId or 0)>0 and pricing.UseLivePrices~=false then
  task.spawn(function()
   local kind=infoType or Enum.InfoType.Product
   local ok,info=pcall(function() return game:GetService("MarketplaceService"):GetProductInfo(productId,kind) end)
   if ok and type(info)=="table" and tonumber(info.PriceInRobux) then amount.Text=tostring(info.PriceInRobux) end
  end)
 end
 return b
end
function T.money(n)
 local s=tostring(math.floor(n)) repeat local c; s,c=s:gsub("^(-?%d+)(%d%d%d)","%1,%2") until c==0 return "$"..s
end

return T
