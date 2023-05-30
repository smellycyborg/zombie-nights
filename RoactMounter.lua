local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vendor = ReplicatedStorage:WaitForChild("Vendor")
local RoactComponents = ReplicatedStorage:WaitForChild("RoactComponenets")

local Roact = require(Vendor.Roact)
local Comm = require(Vendor.Comm)
local Signals = require(ReplicatedStorage:WaitForChild("Signals"))
local Main = require(RoactComponents.Main)

local clientComm = Comm.ClientComm.new(ReplicatedStorage, false, "MainComm")
local updatePlayerAmmoUi = clientComm:GetSignal("UpdatePlayerAmmoUi")
local updatePlayerPointsUi = clientComm:GetSignal("UpdatePlayerPointsUi")
local updateGameDetailsUi = clientComm:GetSignal("UpdateGameDetailsUi")
local updateZombiePositionsUi = clientComm:GetSignal("UpdateZombiePositionsUi")
local updatePlayerHealthUi = clientComm:GetSignal("UpdatePlayerHealthUi")
local sendNotification = clientComm:GetSignal("SendNotification")
local openToolboxUi = clientComm:GetSignal("OpenToolboxUi")
local repairWall = clientComm:GetSignal("RepairWall")
local updateWallHealthUi = clientComm:GetSignal("UpdateWallHealthUi")

local updatePlayerHealth = Signals.updatePlayerHealth

local player = Players.LocalPlayer

local ammo = 16
local health = 100
local wallHealth = UDim2.fromScale(1, 1)
local points = 0
local wave = 0
local zombies = 0
local positions = {}
local message = nil
local isToolbox = false

local function repairWallFunc()
	repairWall:Fire()
end

local function onUpdatePlayerAmmoUi(data)
	ammo = data
	
	updateView()
	
	return ammo
end

local function onUpdatePlayerPointsUi(data)
	points = data
	
	updateView()
	
	return points
end

local function onUpadteGameDetailsUi(gameDetails)
	wave, zombies = gameDetails.wave, gameDetails.zombies
	
	updateView()
	
	return wave, zombies
end

local function onUpdatePlayerHealth(data)
	health = data
	
	updateView()
	
	return health
end

local function onUpdateZombiePositionsUi(data)
	positions = data
	
	updateView()
	
	return positions
end

local function onSendNotification(notification)
	message = notification
	
	updateView()
	
	task.delay(3.5, function()
		message = nil
		
		updateView()
		
		return message
	end)
	
	return message
end

local function onOpenToolboxUi()
	isToolbox = not isToolbox
	
	updateView()
	
	return isToolbox
end

local function onUpdateWallHealthUi(data)
	wallHealth = data
	
	updateView()
	
	return wallHealth
end

updatePlayerAmmoUi:Connect(onUpdatePlayerAmmoUi)
updatePlayerPointsUi:Connect(onUpdatePlayerPointsUi)
updateGameDetailsUi:Connect(onUpadteGameDetailsUi)
updatePlayerHealth:Connect(onUpdatePlayerHealth)
updatePlayerHealthUi:Connect(onUpdatePlayerHealth)
updateZombiePositionsUi:Connect(onUpdateZombiePositionsUi)
updateWallHealthUi:Connect(onUpdateWallHealthUi)
sendNotification:Connect(onSendNotification)
openToolboxUi:Connect(onOpenToolboxUi)

function updateView()
	Roact.update(handle, Roact.createElement(Main, {
		ammo = ammo,
		health = health,
		points = points,
		wave = wave,
		zombies = zombies,
		positions = positions,
		message = message,
		isToolbox = isToolbox,
		repairWallFunc = repairWallFunc,
		wallHealth = wallHealth,
	}))
end

local view = Roact.createElement(Main, {
	ammo = ammo,
	health = health,
	points = points,
	wave = wave,
	zombies = zombies,
	positions = positions,
	message = message,
	isToolbox = isToolbox,
	repairWallFunc = repairWallFunc,
	wallHealth = wallHealth,
})

handle = Roact.mount(view, player:WaitForChild("PlayerGui"), "Main")