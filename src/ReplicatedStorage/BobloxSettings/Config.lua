return {
	Defaults = { Music = true, SFX = true, Volume = 0.7, StrengthPopups = true, LowEffects = false, MaxSpeed = 0 },
	Ranges = { MaxSpeed = { 0, 1e6 } },
	CloseOnBackdrop = false,
	Sliders = {
		{
			Key = "MaxSpeed",
			Label = "MAX SPEED",
			Watch = "NaturalWalkSpeed",
			Range = function(player)
				return 8, math.max(16, player:GetAttribute("NaturalWalkSpeed") or 16)
			end,
		},
	},
	AdminSide = "Right",
	SettingsIcon = "rbxassetid://120353597392384",
	AdminIcon = "rbxassetid://107453728750635",
	Theme = game.ReplicatedStorage.PyramidHUD.Theme,
	Topbar = game.ReplicatedStorage.BobloxTopbar,
	Admin = game.ReplicatedStorage.BobloxAdmin.Client,
	StoreName = "BuildThePyramid_Settings_v1",
}
