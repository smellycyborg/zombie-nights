local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Vendor = ReplicatedStorage:WaitForChild("Vendor")

local Comm = require(Vendor.Comm)

local clientComm = Comm.ClientComm.new(ReplicatedStorage, false, "MainComm")
local displayGoo = clientComm:GetSignal("DisplayGoo")

local billboardGui = ReplicatedStorage:WaitForChild("SpatterGui")

local TWEEN_TIME = 1
local DESTROY_TIME = 0.6
local FADE_TIME = 1
local FADE_INCREMENT = 0.1
local TRANSPARENCY_GOAL = 1

local tweenInfo = TweenInfo.new(TWEEN_TIME, Enum.EasingStyle.Linear)

local function onDisplayGoo(character)
	local foundGui = character:FindFirstChild("SpatterUi")
	if foundGui then
		return
	end

	local clone = billboardGui:Clone()
	clone.Name = "SpatterUi"
	clone.Parent = character:FindFirstChild("HumanoidRootPart")

	local guiTweenGoal = {}
	guiTweenGoal.StudsOffset = Vector3.new(0, 3, 0)

	local tweenUp = TweenService:Create(clone, tweenInfo, guiTweenGoal)
	tweenUp:Play()

	for _, element in pairs(clone.Frame:GetChildren()) do
		task.delay(FADE_TIME, function()
			for transparency = 0, TRANSPARENCY_GOAL, FADE_INCREMENT do
				local uiGradient = element:FindFirstChild("UIGradient")
				if not uiGradient then
					return
				end

				local transparencySequence = NumberSequence.new(transparency)
				uiGradient.Transparency = transparencySequence
				wait()
			end
		end)
	end

	task.delay(DESTROY_TIME, function()
		clone:Destroy()
	end)
end

displayGoo:Connect(onDisplayGoo)