local hum = script.Parent:FindFirstChildOfClass("Humanoid")
if not hum then
	return
end

local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator")
animator.Parent = hum

local anim = Instance.new("Animation")
anim.AnimationId = "rbxassetid://507766666"

local track = animator:LoadAnimation(anim)
track.Looped = true
track:Play()
