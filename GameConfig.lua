local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WALL = workspace:WaitForChild("wall")

local MAX_HEALTH = 200

local config = {
	gameState = "waiting",
	wallHealth = 200,
	wave = 0,
}

function config:takedamage(damage)
	local isDestroyed = self.wallHealth <= 0
	if isDestroyed then
		WALL.CanCollide = false
		
		return
	end
	
	self.wallHealth-=damage
end

function config:repair(amount)
	local isDestroyed = self.wallHealth <= 0
	if isDestroyed then
		WALL.CanCollide = true
	end
	
	self.wallHealth+=amount
	
	local isMax = self.wallHealth >= MAX_HEALTH
	if isMax then
		self.wallHealth = MAX_HEALTH
	end
end

function config:changestate(state)
	self.gameState=state
end

function config:setwave(reset)
	print("Wave Initiate")
	if reset then
		self.wave = 0
		
		return
	end
	
	self.wave+=1
	print("New Wave", self.wave)
end

return config
