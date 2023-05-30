local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local MarketplaceService = game:GetService("MarketplaceService")

local Vendor = ReplicatedStorage:WaitForChild("Vendor")

local Comm = require(Vendor.Comm)
local Fastcast = require(Vendor.FastCastRedux)
local PlayerData = require(script.PlayerData)
local GunClass = require(script.GunClass)
local ZombieClass = require(script.ZombieClass)
local GameConfig = require(script.GameConfig)
local ServerSignals = require(ReplicatedStorage:WaitForChild("ServerSignals"))

local sendWallUiSignal = ServerSignals.sendWallUi

local serverComm = Comm.ServerComm.new(ReplicatedStorage, "MainComm")

local isStudio = RunService:IsStudio()

local WALL = workspace:WaitForChild("wall")
local PLAYERS_DIED_NOTIFICATION = "you lose"
local PLAYER_DIED_NOTIFICATION = "you died"
local REPAIR_WALL_AMOUNT = 20
local POINTS_TO_REPAIR_WALL = 2000
if isStudio then
	POINTS_TO_REPAIR_WALL = 20
end
local DEFAULT_TAKE_DAMAGE = 20
local DEBRIS_BULLET_WAIT = 0.1
local LIGHTING_TWEEN_TIME = 2.5
local BLACKLIST = {}

local ToolboxProximityPrompt = workspace:WaitForChild("BoxOpened").ProximityPrompt

Players.CharacterAutoLoads = false
local tweenInfo = TweenInfo.new(
	LIGHTING_TWEEN_TIME, 
	Enum.EasingStyle.Linear,
	Enum.EasingDirection.In
)

local zombieInstances = {}
local timeElapsed = 0
local miliseconds = 0
local totalSeconds = 0
local isTasking = false
local players = 0

local Sdk = {
	_gameData = {},
}

local function _ghostWalls()
	local environment = workspace:WaitForChild("Environment")
	local barriers = environment.PlayerBarrier:GetChildren()
	
	for _, barrier in barriers do
		barrier.Transparency = 1
	end
	
	WALL.Transparency = 1
end

local function _createCameraPart()
	local cameraPart = Instance.new("Part")
	cameraPart.Anchored = true
	cameraPart.Name = "CameraPart"
	cameraPart.CastShadow = false
	cameraPart.Transparency = 1
	cameraPart.Position = Vector3.new(52.544, 24.747, -33.093)
	cameraPart.Orientation = Vector3.new(0, 90, 0)
	cameraPart.Parent = workspace
	
	if isStudio then
		cameraPart.Transparency = 0.5
		cameraPart.BrickColor = BrickColor.new("Pink")
	end
	
	print("MESSAGE/INfo:  Camera Part has been created..")
end

local function _createBulletsFolder()
	local folder = Instance.new("Folder")
	folder.Name = "Bullets"
	folder.Parent = workspace
end

local function _createBulletTemplate()
	local part = Instance.new("Part")
	part.Name = "Bullet"
	part.Anchored = true
	part.CanCollide = false
	part.Size = Vector3.new(1, 1, 1)
	part.Parent = ReplicatedStorage
end

local function _getEndpointVector3(player, ray)
	local character = player.Character
	if not character then
		return
	end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		return
	end
	
	local x = humanoidRootPart.Position.X -- or gun attatchment

	local aForY = ray.Direction.Y / ray.Direction.X
	local bForY = ray.Origin.Y - ray.Origin.X * aForY
	local y = aForY * x + bForY

	local aForZ = ray.Direction.Z / ray.Direction.X
	local bForZ = ray.Origin.Z - ray.Origin.X * aForZ
	local z = aForZ * x + bForZ

	return Vector3.new(x, y, z)
end

local function _addToBlacklist(group)
	for _, part in group do
		if part:IsA("BasePart") or part:IsA("MeshPart") or part:IsA("Part") then
			table.insert(BLACKLIST, part)
		end
	end
end

local function _removeFromBlacklist(group)
	for _, part in group do
		if part:IsA("BasePart") or part:IsA("MeshPart") or part:IsA("Part") then
			local partIndex = table.find(BLACKLIST, part)
			table.remove(BLACKLIST, partIndex)
		end
	end
end

local function _initRaycastBlacklist()
	local environmentDescendants = workspace:WaitForChild("Environment"):GetDescendants()
	_addToBlacklist(environmentDescendants)
	
	for _, player in Players:GetChildren() do
		player.CharacterAdded:Wait()
		
		_addToBlacklist(player.Character:GetChildren())
	end
	
	for _, player in Players:GetChildren() do
		local playerGameData = Sdk._gameData[player]
		playerGameData.raycastParams.FilterDescendantsInstances = BLACKLIST
	end
	
	table.insert(BLACKLIST, WALL)
end

local function _createGun(character)
	wait(character:WaitForChild("HumanoidRootPart"))
	
	local hand = character:WaitForChild("RightHand")
	local clonePos = Vector3.new(hand.Position.X, hand.Position.Y - 0.7, hand.Position.Z)
	
	local clone = ReplicatedStorage:WaitForChild("Gloc"):Clone()
	clone.CanCollide = false
	clone.Massless = true
	clone.Position = clonePos
	clone.Parent = character
	
	local weld = Instance.new("WeldConstraint")
	weld.Enabled = true
	weld.Part0 = clone
	weld.Part1 = hand
	weld.Parent = clone
end

local function characterAdded(character)
	if players == 0 then
		players+=1
	end
	
	local player = Players:GetPlayerFromCharacter(character)
	local playerGameData = Sdk._gameData[player]
	
	_createGun(character)
	_addToBlacklist(character:GetChildren())
	
	playerGameData.raycastParams.FilterDescendantsInstances = BLACKLIST
	
	local humanoid = character:FindFirstChild("Humanoid")
	humanoid.WalkSpeed = 25
	humanoid.AutoRotate = false
	humanoid.Died:Connect(function()
		sendNotification:Fire(player, PLAYER_DIED_NOTIFICATION)
	end)
	
	-- align orientation for character to keep them from rotating
	local alignOrientationAttatchment = Instance.new("Attachment")
	alignOrientationAttatchment.CFrame = CFrame.new(0, 0, -2)
	local alignOrientation = Instance.new("AlignOrientation")
	alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignOrientation.PrimaryAxisOnly = true
	alignOrientation.PrimaryAxis = Vector3.new(-1, 0, 0)
	alignOrientation.Responsiveness = 100
	alignOrientation.Attachment0 = alignOrientationAttatchment
	alignOrientationAttatchment.Parent = character.HumanoidRootPart
	alignOrientation.Parent = character.HumanoidRootPart
	
	local playerGun = playerGameData.gun
	playerGun:reload()
	
	local currentAmmo = playerGun:getAmmo()
	updatePlayerAmmoUi:Fire(player, currentAmmo)
	updatePlayerHealthUi:Fire(player, character.Humanoid.Health)
	
	print("MESSAGE/Info:  character has been added..")
end

local function characterRemoving(character)
	_removeFromBlacklist(character:GetChildren())
	
	print("MESSAGE/Info:  character has been removed..")
end

local function onRayHit(casterData, result, velocity, bullet, player)
	local hit = result.Instance
	local character = hit.Parent
	if not character then
		Debris:AddItem(bullet, DEBRIS_BULLET_WAIT)

		return
	end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then
		Debris:AddItem(bullet, DEBRIS_BULLET_WAIT)

		return
	end

	humanoid:TakeDamage(DEFAULT_TAKE_DAMAGE)
	displayGoo:Fire(player, character)
	
	-- if zombie dies then reward player points 
	local isZombieDead = humanoid.Health <= 0
	if isZombieDead then
		PlayerData:addpoints(player, 50)
		pointsUi:Fire(player, 50, true)
		
		local currentPoints = PlayerData:getpoints(player)
		updatePlayerPointsUi:Fire(player, currentPoints)
	end

	Debris:AddItem(bullet, DEBRIS_BULLET_WAIT)
end

local function playerAdded(player)
	PlayerData.add(player)
	
	Sdk._gameData[player] = {}
	
	local playerGameData = Sdk._gameData[player]
	playerGameData.gun = GunClass.new(player)
	playerGameData.gun.onReloaded:Connect(function()
		local currentAmmo = playerGameData.gun:getAmmo()
		updatePlayerAmmoUi:Fire(player, currentAmmo)
	end)

	local function onLengthChanged(cast, lastPoint, direction, length, velocity, bullet)
		if bullet then 
			local bulletLength = bullet.Size.Z/2
			local offset = CFrame.new(0, 0, -(length - bulletLength))
			bullet.CFrame = CFrame.lookAt(lastPoint, lastPoint + direction):ToWorldSpace(offset)
		end
	end
	
	playerGameData.caster = Fastcast.new()
	
	playerGameData.caster.RayHit:Connect(function(casterData, result, velocity, bullet)
		onRayHit(casterData, result, velocity, bullet, player)
	end)
	
	playerGameData.caster.LengthChanged:Connect(onLengthChanged)
	
	playerGameData.raycastParams = RaycastParams.new()
	playerGameData.raycastParams.FilterDescendantsInstances = BLACKLIST
	playerGameData.raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	
	playerGameData.casterBehavior = Fastcast.newBehavior()
	playerGameData.casterBehavior.AutoIgnoreContainer = false
	playerGameData.casterBehavior.CosmeticBulletContainer = workspace:WaitForChild("Bullets")
	playerGameData.casterBehavior.CosmeticBulletTemplate = ReplicatedStorage:WaitForChild("bullet")
	playerGameData.casterBehavior.RaycastParams = playerGameData.raycastParams
	
	player.CharacterAdded:Connect(characterAdded)
	player.CharacterRemoving:Connect(characterRemoving)
	player:LoadCharacter()
end

local function playerRemoving(player)
	PlayerData.remove(player)
	
	Sdk._gameData[player] = nil
end

local function onPlayerMouseMove(player, ray)
	
	
	
end

local function onPlayerMouseClick(player, ray)
	local playerGameData = Sdk._gameData[player]
	local playerGun = playerGameData.gun
	local caster = playerGameData.caster
	local casterBehavior = playerGameData.casterBehavior
	
	local character = player.Character
	if not character then 
		return
	end
	
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then
		return
	end
	
	local playerIsDead = humanoid.Health <= 0
	if playerIsDead then
		return
	end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		return
	end
	
	local casterOriginPos = humanoidRootPart.Position
	
	local currentAmmo = playerGun:getAmmo()
	if currentAmmo == 0 and not playerGun:checkReloading() then
		playSound:Fire(player, "RELOAD_SOUND")
		
		task.spawn(function()
			local playerReloadTime = PlayerData:getreloadtime(player)
			playerGun:reload(playerReloadTime)
		end)
		
		--print("MESSAGE/Info:  play empty sound because gun out of ammo..")
		
		return
	elseif currentAmmo == 0 and playerGun:checkReloading() then
		playSound:Fire(player, "CLANK_SOUND")
		
		return
	end
	
	if not playerGun:checkReloading() then
		playerGun:shoot()
		playSound:Fire(player, "FIRE_SOUND")
		PlayerData:addpoints(player, 1)
		--pointsUi:Fire(player, 1, true)
		
		local currentPoints = PlayerData:getpoints(player)
		updatePlayerPointsUi:Fire(player, currentPoints)
		
		local endpoint = _getEndpointVector3(player, ray)
		local casterDirection = (endpoint - casterOriginPos).Unit
		
		caster:Fire(casterOriginPos, casterDirection, 400, casterBehavior)
	end

	currentAmmo = playerGun:getAmmo()
	updatePlayerAmmoUi:Fire(player, currentAmmo)
	
	--print("MESSAGE/Info: new ammo is " .. playerGun:getAmmo())
end

local function onGamepassPurchase(player, gamepass)

end

local function _tweenMoon()
	local tweenDay = {}
	tweenDay.ClockTime = 6.3
	local tweenNight = {}
	tweenNight.ClockTime = 4.6
	
	local tweenToDay = TweenService:Create(Lighting, tweenInfo, tweenDay)
	local tweenToNight = TweenService:Create(Lighting, tweenInfo, tweenNight)
	
	local isDay = math.floor(Lighting.ClockTime) == 6
	local isNight = math.floor(Lighting.ClockTime) == 4
	if isDay then
		tweenToNight:Play()
	else
		if isNight then
			tweenToDay:Play()
		end
	end
end

local function _updateClientsUi()
	for _, player in Players:GetPlayers() do
		updateGameDetailsUi:Fire(player, {
			wave = GameConfig.wave, 
			zombies = #zombieInstances,
		})
	end
end

local function _spawnZombies()
	local randomNumber = math.random(1, 5)
	local playersAmount = #Players:GetChildren()
	
	local zombiesToSpawn = randomNumber * playersAmount + GameConfig.wave
	-- creation and handling of zombie instance 
	for i = 1, zombiesToSpawn do
		local sizes = {"Small", "Normal", "Large"}
		local randomSize = sizes[math.random(1, #sizes)]
		
		local zombieInstance = ZombieClass.new(randomSize)
		
		table.insert(zombieInstances, zombieInstance)
		
		_updateClientsUi()
		
		zombieInstance:spawn()
		zombieInstance.onDeath:Connect(function()
			zombieInstance:destroy()
			
			local zombieIndex = table.find(zombieInstances, zombieInstance)
			table.remove(zombieInstances, zombieIndex)
			
			_updateClientsUi()
		end)
	end
end

-- starts the spawn, spawns zombies 
local function _startRound()
	for _, player in Players:GetPlayers() do
		if player.Character:FindFirstChild("Humanoid").Health <= 0 then
			player:LoadCharacter()
		end
	end
	
	GameConfig:changestate("round_in_progress")
	GameConfig:setwave(false)
	
	_updateClientsUi()
	
	for i = 1, GameConfig.wave  do
		_spawnZombies()
		
		-- repeat a way until all zombies are gone then spawn next wave
		repeat
			task.wait(0.1)
			local noZombies = next(zombieInstances) == nil
		until noZombies 
	end
	
	GameConfig:changestate("waiting")
end

local function _destroyZombies()
	for _, zombie in zombieInstances do
		zombie:destroy()
	end
	
	table.clear(zombieInstances)
end

local function _updateZombiePositionUi()
	local positions = {}

	local zombieSpawnPointPosition = workspace.ZombieSpawners.Spawner.Position
	local partPosition = workspace.ZombieEndPointUi.Position
	local totalDistance = (partPosition - zombieSpawnPointPosition).Magnitude

	for _, zombie in zombieInstances do
		local zombiePosition = zombie:getposition()
		local zombieDistance = (zombiePosition - partPosition).Magnitude

		local positionAwayFromPart = (totalDistance - zombieDistance)
		local x = (positionAwayFromPart / totalDistance)
		local position = UDim2.fromScale(x, 0)
		
		table.insert(positions, position)
	end

	for _, player in Players:GetPlayers() do
		updateZombiePositionsUi:Fire(player, positions)
	end
end

-- this function handles our game loop
local function onHeartbeat(deltatime)
	timeElapsed += deltatime
	
	if timeElapsed < 0.1 then
		return
	end
	
	timeElapsed = 0
	miliseconds += 0.1
	
	if miliseconds >= 1 then
		totalSeconds += 1
		
		_updateZombiePositionUi()
		
		miliseconds = 0
	end
	
	if totalSeconds >= 60 then
		_tweenMoon()
		totalSeconds = 0
	end
	
	local isRestarting = GameConfig.gameState == "restarting"
	if isRestarting then
		return
	end
	
	-- check if all players in game are dead or if some are alive
	local allPlayersDied
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local humanoid = character:FindFirstChild("Humanoid")
		
		local hasDied = humanoid.Health <= 0
		if not hasDied then
			allPlayersDied = false
			
			break
		end
		
		allPlayersDied = true
	end
	
	-- if all players in game are dead we load character set wave to 0
	-- destroy zombies and clear zombie instances table then start the round
	if allPlayersDied then
		for _, player in Players:GetPlayers() do
			sendNotification:Fire(player, PLAYERS_DIED_NOTIFICATION)
		end
		
		GameConfig:changestate("restarting")
		
		task.wait(5)
		
		_destroyZombies()
		
		for _, player in Players:GetPlayers() do
			if player.Character:FindFirstChild("Humanoid").Health <= 0 then
				player:LoadCharacter()
			end
		end
		
		GameConfig:setwave(true)
		GameConfig:changestate("waiting")
		_startRound()
		
		return
	end
	
	local gameState = GameConfig.gameState
	
	if isTasking then
		return 
	end
	
	local noZombies = next(zombieInstances) == nil
	local waveCompleted = gameState == "waiting"
	if noZombies and waveCompleted then
		
		-- if players made it to the next round 
		--if GameConfig.wave > 1 then
			for _, player in Players:GetPlayers() do
				PlayerData:addpoints(player, 100)
				pointsUi:Fire(player, 100, true)
				
				local currentPoints = PlayerData:getpoints(player)
				updatePlayerPointsUi:Fire(player, currentPoints)
			end
		--end
		
		_startRound()
		
		return
	end
	
	-- handles pathfinding task for every zombie instance
	task.spawn(function()
		isTasking = true
		
		for zombieIndex, zombie in zombieInstances do
			zombie:findpath()
		end
		
		isTasking = false
	end)
end

local function onGamepassPurchaseFinished(player, id, wasPurchased)
	if not wasPurchased then
		return
	end
	
	local isLaserSight = id == 153359729
	if not isLaserSight then
		PlayerData:setreloadtime(player, id)
		
		return
	end
	
	PlayerData:setlasersight(player)
end

local function onToolboxPromptTriggered(player)
	openToolboxUi:Fire(player)
end

local function onRepairWall(player) -- Todo turn into remote function
	local playerData = PlayerData.playerData[player]
	
	local hasPoints = playerData.points >= POINTS_TO_REPAIR_WALL
	if not hasPoints then
		return
	end
	
	if GameConfig.wallHealth <= 199 then
		PlayerData:subpoints(player, POINTS_TO_REPAIR_WALL)
		GameConfig:repair(REPAIR_WALL_AMOUNT)
		pointsUi:Fire(player, POINTS_TO_REPAIR_WALL, false)

		local currentPoints = PlayerData.playerData[player].points
		updatePlayerPointsUi:Fire(player, currentPoints)
	end
	
	local wallHealth = GameConfig.wallHealth
	local maxHealth = 200
	local healthPercentage = wallHealth / maxHealth
	local healthSize = UDim2.fromScale(healthPercentage, 1)
	
	for _, player in Players:GetChildren() do
		if GameConfig.wallHealth >= maxHealth then
			sendWallUi:Fire(player, REPAIR_WALL_AMOUNT, true, true)
		else
			sendWallUi:Fire(player, REPAIR_WALL_AMOUNT, true, false)
		end
		
		updateWallHealthUi:Fire(player, healthSize)
	end
end

local function onSendWallUiSignal(amount, isAdd)
	local wallHealth = GameConfig.wallHealth
	local maxHealth = 200
	local healthPercentage = wallHealth / maxHealth
	local healthSize = UDim2.fromScale(healthPercentage, 1)
	
	for _, player in Players:GetPlayers() do
		sendWallUi:Fire(player, amount, isAdd)
		
		updateWallHealthUi:Fire(player, healthSize)
		
		explodeVfx:Fire(player)
	end
end

function Sdk.init(options)
	
	for _, player in Players:GetChildren() do
		playerAdded(player)
	end
	
	_createCameraPart()
	_createBulletsFolder()
	_createBulletTemplate()
	_initRaycastBlacklist()
	
	task.spawn(function()
		_ghostWalls()
	end)
	
	-- remotes
	explodeVfx = serverComm:CreateSignal("ExplodeVfx")
	updateWallHealthUi = serverComm:CreateSignal("UpdateWallHealthUi")
	displayGoo = serverComm:CreateSignal("DisplayGoo")
	pointsUi = serverComm:CreateSignal("PointsUi")
	sendWallUi = serverComm:CreateSignal("SendWallUi")
	openToolboxUi = serverComm:CreateSignal("OpenToolboxUi")
	sendNotification = serverComm:CreateSignal("SendNotification")
	updatePlayerHealthUi = serverComm:CreateSignal("UpdatePlayerHealthUi")
	updateGameDetailsUi = serverComm:CreateSignal("UpdateGameDetailsUi")
	playSound = serverComm:CreateSignal("PlaySound")
	updatePlayerAmmoUi = serverComm:CreateSignal("UpdatePlayerAmmoUi")
	updatePlayerPointsUi = serverComm:CreateSignal("UpdatePlayerPointsUi")
	updateZombiePositionsUi = serverComm:CreateSignal("UpdateZombiePositionsUi")
	local playerMouseMove = serverComm:CreateSignal("PlayerMouseMove")
	local playerMouseClick = serverComm:CreateSignal("PlayerMouseClick")
	local repairWall = serverComm:CreateSignal("RepairWall")
	
	-- bindings
	playerMouseMove:Connect(onPlayerMouseMove)
	playerMouseClick:Connect(onPlayerMouseClick)
	repairWall:Connect(onRepairWall)
	sendWallUiSignal:Connect(onSendWallUiSignal)
	Players.PlayerAdded:Connect(playerAdded)
	Players.PlayerRemoving:Connect(playerRemoving)
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(onGamepassPurchaseFinished)
	ToolboxProximityPrompt.Triggered:Connect(onToolboxPromptTriggered)
	
	-- this repeat is so we don't start our game loop until there's at least one character
	repeat
		task.wait(0.1)
	until players >= 1
	
	RunService.Heartbeat:Connect(onHeartbeat)
end

return Sdk
