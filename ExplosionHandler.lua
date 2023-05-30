local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local Vendor = ReplicatedStorage:WaitForChild("Vendor")

local Comm = require(Vendor.Comm)

local explodeModel = ReplicatedStorage:WaitForChild("ExplodeModel")
local spawner = workspace:WaitForChild("ExplosionArea")

local clientComm = Comm.ClientComm.new(ReplicatedStorage, false, "MainComm")
local event = clientComm:GetSignal("ExplodeVfx")

local DELAY_UNTIL_FADE = 0.15
local TWEEN_TIME = 0.35

local tweenInfo = TweenInfo.new(TWEEN_TIME, Enum.EasingStyle.Linear)

local tweenStart = {}
tweenStart.Transparency = 0

local tweenGoal = {}
tweenGoal.Transparency = 1

local function _getRandomPosition()
	--finding a spot on the spawner to spawn said zombie
	local positionX = spawner.Position.X
	local positionY = spawner.Position.Y
	local positionZ = spawner.Position.Z
	local sizeX = spawner.Size.X
	local sizeZ = spawner.Size.Z

	local randomPositionX = math.random((positionX - sizeX / 2),(positionX + sizeX / 2))
	local randomPositionZ = math.random((positionZ - sizeZ / 2),(positionZ + sizeZ / 2))

	return Vector3.new(randomPositionX, positionY, randomPositionZ)
end

local function onEvent()
	local clone = explodeModel:Clone()
	clone.Name = "Explosion"
	
	local position = _getRandomPosition()
	for _, part in clone:GetChildren() do
		part.Position = position
		part.Material = Enum.Material.SmoothPlastic
		part.Transparency = 0.4
		part.Anchored = true
		part.CanCollide = false
	end
	
	clone.Parent = workspace
	
	task.delay(DELAY_UNTIL_FADE, function()
		for _, part in clone:GetChildren() do
			task.spawn(function()
				local tween = TweenService:Create(part, tweenInfo, tweenGoal)
				tween:Play()
				
				tween.Completed:Connect(function()
					clone:Destroy()
				end)
			end)
		end
	end)
	
end

event:Connect(onEvent)
