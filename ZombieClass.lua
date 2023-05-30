local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PathfindingService = game:GetService("PathfindingService")

local config = require(script.Parent.GameConfig)
local scheduler = require(script.Parent.Scheduler)
local ServerSignals = require(ReplicatedStorage:WaitForChild("ServerSignals"))
local sendWallUiSignal = ServerSignals.sendWallUi

local WALL = workspace:WaitForChild("wall")
local DEFAULT_WALL_DAMAGE = 10
local DEFAULT_HUMANOID_DAMAGE = 20
local TIME_UNTIL_NEXT_ATTACK = 1
local DAMAGE_DELAY_AFTER_ANIM = 0.3

local sound = script.ZombieSound

local zombie = {}
local zombieprototype = {}
local zombieprivate = {}

local function _getRandomPosition()
--grabbing spawner
	local zombieSpawners = workspace:WaitForChild("ZombieSpawners"):GetChildren()
	local randomNumber
	randomNumber = math.random(1, #zombieSpawners)
	
--finding a spot on the spawner to spawn said zombie
	local positionX = zombieSpawners[randomNumber].Position.X
	local positionY = zombieSpawners[randomNumber].Position.Y
	local positionZ = zombieSpawners[randomNumber].Position.Z
	local sizeX = zombieSpawners[randomNumber].Size.X
	local sizeZ = zombieSpawners[randomNumber].Size.Z

	local randomPositionX = math.random((positionX - sizeX / 2),(positionX + sizeX / 2))
	local randomPositionZ = math.random((positionZ - sizeZ / 2),(positionZ + sizeZ / 2))
	
	return Vector3.new(randomPositionX, positionY, randomPositionZ)
end

local function _getClosestCharacter()
	for _, player in Players:GetPlayers() do
		local character = player.Character
		if not character then
			continue
		end
		
		local humanoid = character:FindFirstChild("Humanoid")
		if not humanoid then
			continue
		end
		
		if humanoid.Health <= 0 then
			continue
		end
		
		return character
	end
	
	return nil
end
--This is also where the damage handling happens
local function _setConnections(self)
	local private = zombieprivate[self]

	local function onTouchedConnection(otherPart)
		if private.hasAttacked then
			return
		end
		
		if not private.isAttacking then
			return
		end
		
		local isWall = otherPart.Name == "wall"
		if isWall then
			if config.wallHealth > 0 then
				sendWallUiSignal:Fire(DEFAULT_WALL_DAMAGE, false)
			end
			
			config:takedamage(DEFAULT_WALL_DAMAGE)
			
			private.hasAttacked = true
			
			task.wait(TIME_UNTIL_NEXT_ATTACK)
			
			private.hasAttacked = false
		else
			local character = otherPart.Parent
			local isZombie = character:FindFirstChild("Zombie")
			if isZombie then
				return
			end
			
			local humanoid = character:FindFirstChild("Humanoid")
			if not humanoid then
				return
			end
			
			humanoid:TakeDamage(DEFAULT_HUMANOID_DAMAGE)
			private.hasAttacked = true
			
			task.wait(TIME_UNTIL_NEXT_ATTACK)
			
			private.hasAttacked = false
		end
	end
	
	local zombieParts = private.model:GetChildren()
	--Zombie touch connection
	for _, part in zombieParts do
		if part:IsA("BasePart") or part:IsA("MeshPart") or part:IsA("Part") then
			local touchedConnection = part.Touched:Connect(onTouchedConnection)
			
			table.insert(private.connections, touchedConnection)
		end
	end
end

local function _attack(self)
	local private = zombieprivate[self]
	local attackTrack = private.model.Humanoid:LoadAnimation(script.Animations.Attack)

	task.wait(DAMAGE_DELAY_AFTER_ANIM)
	
	private.isAttacking = true
	attackTrack:Play()

	task.wait(TIME_UNTIL_NEXT_ATTACK)
	
	private.isAttacking = false
end

function zombie.new(size: String)
	assert(size, "Argument 1 nil.")
	
	local self = {}
	self.attack = Instance.new("BindableEvent")
	self.onAttack = self.attack.Event
	self.death = Instance.new("BindableEvent")
	self.onDeath = self.death.Event
	
	local private = {}
	private.size = size
	private.hasAttacked = false
	private.isAttacking = false
	private.connections = {}
	
	zombieprivate[self] = private
	
	return setmetatable(self, zombieprototype)
end

function zombieprototype:spawn()
	local private = zombieprivate[self]
	
	local Zombies = ReplicatedStorage:WaitForChild("Zombies")
	local zombieFolder = Zombies:FindFirstChild(private.size):GetChildren()
	local zombieType = math.random(1, #zombieFolder)
	local zombie = zombieFolder[zombieType]
	
	if not zombie then
		warn("MESSAGE/Warn:  Attempt to index nil with zombie ..")
	end
	
	local clone = zombie:Clone()
	clone.Name =  zombie.Name
	clone.PrimaryPart.Position = _getRandomPosition()
	clone.Parent = workspace
	
	local isZombie = Instance.new("StringValue")
	isZombie.Name = "Zombie"
	isZombie.Parent = clone
	
	clone.Humanoid.Died:Connect(function()
		self.death:Fire()
	end)
	
	-- plays sound when you hurt zombie 
	local isPlaying = false
	clone.Humanoid:GetPropertyChangedSignal("Health"):Connect(function()
		if isPlaying then
			return
		end
		
		local soundClone = sound:Clone()
		soundClone.Parent = clone
		
		isPlaying = true
		soundClone:Play()
		soundClone.Ended:Connect(function()
			isPlaying = false
			soundClone:Destroy()
		end)
	end)

	private.model = clone
	
	_setConnections(self)
	
	local interval = 1.1
	local startAsap = false
	
	private.schedule = scheduler.new()
	private.schedule:interval(interval, startAsap, function()
		_attack(self)
	end)
end

function zombieprototype:findpath()
	local private = zombieprivate[self]
	
	local isWall = config.wallHealth > 0
	if isWall then
		local wallPositionZ = WALL.Position.Z
		local zombiePosition = private.model.PrimaryPart.Position

		private.model.Humanoid:MoveTo(Vector3.new(zombiePosition.X, zombiePosition.Y, wallPositionZ))
	else
		local closestCharacter = _getClosestCharacter()
		if not closestCharacter then
			return
		end
		
		local characterPosition = closestCharacter.PrimaryPart.Position

		private.model.Humanoid:MoveTo(characterPosition)		
	end
end

function zombieprototype:getposition()
	local private = zombieprivate[self]

	return private.model.PrimaryPart.Position
end

function zombieprototype:destroy()
	for _, connection in zombieprivate[self].connections do
		connection:Disconnect()
	end
	zombieprivate[self].schedule:shutdown()
	
	zombieprivate[self].model:Destroy()
	zombieprivate[self] = nil
	self.onAttack = nil
	self.onDeath = nil
	self = nil
end

zombieprototype.__index = zombieprototype
zombieprototype.__metatable = "This metatable is locked."
zombieprototype.__newindex = function(_, _, _)
	error("This metatable is locked.")
end

return zombie
