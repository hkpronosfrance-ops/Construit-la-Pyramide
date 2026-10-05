local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local L = require(RS:WaitForChild("PyramidHUD"):WaitForChild("Localization"))

if not L.isFrench() then
	return
end

local busy = setmetatable({}, { __mode = "k" })
local hooked = setmetatable({}, { __mode = "k" })

local function translateProperty(obj, prop)
	if busy[obj] then
		return
	end
	local ok, current = pcall(function()
		return obj[prop]
	end)
	if not ok or type(current) ~= "string" or current == "" then
		return
	end
	local translated = L.translate(current)
	if translated ~= current then
		busy[obj] = true
		pcall(function()
			obj[prop] = translated
		end)
		busy[obj] = nil
	end
end

local function hook(obj)
	if hooked[obj] then
		return
	end

	if obj:IsA("TextLabel") or obj:IsA("TextButton") then
		hooked[obj] = true
		translateProperty(obj, "Text")
		obj:GetPropertyChangedSignal("Text"):Connect(function()
			translateProperty(obj, "Text")
		end)
	elseif obj:IsA("TextBox") then
		hooked[obj] = true
		translateProperty(obj, "PlaceholderText")
		obj:GetPropertyChangedSignal("PlaceholderText"):Connect(function()
			translateProperty(obj, "PlaceholderText")
		end)
	elseif obj:IsA("ProximityPrompt") then
		hooked[obj] = true
		translateProperty(obj, "ActionText")
		translateProperty(obj, "ObjectText")
		obj:GetPropertyChangedSignal("ActionText"):Connect(function()
			translateProperty(obj, "ActionText")
		end)
		obj:GetPropertyChangedSignal("ObjectText"):Connect(function()
			translateProperty(obj, "ObjectText")
		end)
	end
end

local function watch(root)
	for _, obj in root:GetDescendants() do
		hook(obj)
	end
	root.DescendantAdded:Connect(function(obj)
		task.defer(hook, obj)
	end)
end

watch(player:WaitForChild("PlayerGui"))
watch(workspace)
