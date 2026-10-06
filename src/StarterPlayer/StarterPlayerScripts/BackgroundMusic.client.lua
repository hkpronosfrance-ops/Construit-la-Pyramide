local SoundService = game:GetService("SoundService")

local MUSIC_ID = "rbxassetid://109579195200347"

local music = SoundService:FindFirstChild("BackgroundMusic")
if not music then
	music = Instance.new("Sound")
	music.Name = "BackgroundMusic"
	music.Parent = SoundService
end

music.SoundId = MUSIC_ID
music.Looped = true
music.Volume = 0.35
music:SetAttribute("Music", true)

if not music.IsPlaying then
	music:Play()
end
