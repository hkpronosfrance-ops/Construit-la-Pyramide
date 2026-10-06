local SoundService = game:GetService("SoundService")

local MUSIC_ID = "rbxassetid://109579195200347"

local music = SoundService:FindFirstChild("BackgroundMusic")
local created = false
if not music then
	music = Instance.new("Sound")
	music.Name = "BackgroundMusic"
	created = true
end

music.SoundId = MUSIC_ID
music.Looped = true
music.Volume = 0.35
music:SetAttribute("Music", true)

if created then
	music.Parent = SoundService
end

if not music.IsPlaying then
	music:Play()
end
