local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local Vendor = ReplicatedStorage:WaitForChild("Vendor")

local Comm = require(Vendor.Comm)
local numberSuffix = require(ReplicatedStorage:WaitForChild("NumberSuffix"))

local billboardGui = ReplicatedStorage:WaitForChild("CharacterBillboardGui")
local wallUiPart = workspace:WaitForChild("WallRepairUiPart")
local sounds = workspace:WaitForChild("Sounds")

local clientComm = Comm.ClientComm.new(ReplicatedStorage, false, "MainComm")
local pointsUi = clientComm:GetSignal("PointsUi")

local TWEEN_TIME = 1
local DESTROY_TIME = 1.6
local FADE_TIME = 1.2
local FADE_INCREMENT = 0.1
local TRANSPARENCY_GOAL = 1

local player = Players.LocalPlayer
local sounds = workspace:WaitForChild("Sounds")
local pointsSound = sounds.Pick_up_gold

local tweenInfo = TweenInfo.new(TWEEN_TIME, Enum.EasingStyle.Linear)

local function onPointsUi(amount, isAdd)
	--local foundGui = workspace.WallRepairUiPart:FindFirstChild("PointsUi")
	--if foundGui then
	--	foundGui:Destroy()
	--end

	local clone = billboardGui:Clone()
	clone.Name = "PointsUi"

	local amountModified = numberSuffix(amount)
	local sign = isAdd and "+" or "-"
	local text = sign .. amountModified

	clone.Frame.TextLabel.Text = text

	clone.Frame.TextLabel.TextColor3 = Color3.fromRGB(0, 85, 255)
	
	local head = player.Character:FindFirstChild("Head")
	if not head then
		return
	end
	
	clone.Parent = head

	local guiTweenGoal = {}
	guiTweenGoal.StudsOffset = Vector3.new(0, 19, 0)

	local tweenUp = TweenService:Create(clone, tweenInfo, guiTweenGoal)
	tweenUp:Play()

	pointsSound:Play()

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

pointsUi:Connect(onPointsUi)
