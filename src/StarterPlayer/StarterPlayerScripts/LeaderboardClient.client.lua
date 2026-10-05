local Players=game:GetService("Players")
local Http=game:GetService("HttpService")
local p=Players.LocalPlayer
local folder=workspace:WaitForChild(require(game.ReplicatedStorage.BobloxLeaderboards.Config).MapName or "PyramidMap"):WaitForChild("Leaderboards")
local Rows=require(game.ReplicatedStorage.BobloxLeaderboards.Rows)
local function connect(board)
 local key=board:GetAttribute("StatKey") if not key then return end
 local panel=board:WaitForChild("Panel")
 local template=panel:WaitForChild("RankingUI")
 local gui=template:Clone() gui.Name="LocalRanking_"..key gui.Adornee=panel gui.Active=true
 gui.ResetOnSpawn=false gui.MaxDistance=120 gui.Parent=p:WaitForChild("PlayerGui") template.Enabled=false
 local function update()
  local ok,data=pcall(Http.JSONDecode,Http,board:GetAttribute("Top") or "[]")
  if ok then Rows.setEntries(gui,data) end
  local row=gui.YourResult
  local rank=p:GetAttribute("LeaderboardRank_"..key)
  row.Rank.Text=rank and ("#"..rank) or "#—"
  row.PlayerName.Text=p.Name row.Value.Text=p:GetAttribute("LeaderboardValue_"..key) or "0"
  row.Avatar.Visible=p.UserId>0 row.Avatar.Placeholder.Visible=false
  row.Avatar.Image="rbxthumb://type=AvatarHeadShot&id="..p.UserId.."&w=150&h=150"
 end
 local connections={}
 for _,signal in {board:GetAttributeChangedSignal("Top"),p:GetAttributeChangedSignal("LeaderboardRank_"..key),p:GetAttributeChangedSignal("LeaderboardValue_"..key)} do
  table.insert(connections,signal:Connect(update))
 end
 board.Destroying:Connect(function() for _,c in connections do c:Disconnect() end gui:Destroy() end)
 update()
end
for _,board in folder:GetChildren() do connect(board) end
folder.ChildAdded:Connect(connect)
