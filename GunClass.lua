local gun = {}
local gunprototype = {}
local gunprivate = {}

local RELOADING_TIME = 5

function gun.new(player: Player)
	assert(player, "Argument 1 is nil.")
	
	local self = {}
	
	self.reloaded = Instance.new("BindableEvent")
	self.onReloaded = self.reloaded.Event
	
	local private = {}	
	
	private.owner = player
	private.ammo = 16
	private.reloading = false
	
	gunprivate[self] = private	
	
	return setmetatable(self, gunprototype)
end

function gunprototype:reload(reloadTime)
	local private = gunprivate[self]
	
	if private.reloading then
		return
	end
	
	local reloadingTime
	if reloadTime == "times_two" then
		reloadingTime = 2.5
	elseif reloadTime == "times_three" then
		reloadingTime = 1.25
	elseif reloadTime == "inf" then
		reloadingTime = 0
	end
	
	if not reloadingTime then
		reloadingTime = RELOADING_TIME
	end
	
	private.reloading = true
	task.wait(reloadingTime)
	private.ammo = 16
	private.reloading = false
	
	self.reloaded:Fire()
end

function gunprototype:shoot()
	local private = gunprivate[self]
	
	private.ammo-=1
end

function gunprototype:getAmmo()
	local private = gunprivate[self]
	
	return private.ammo
end

function gunprototype:checkReloading()
	local private = gunprivate[self]
	
	return private.reloading
end

gunprototype.__index = gunprototype
gunprototype.__metatable = "This metatable is locked."
gunprototype.__newindex = function(_, _, _)
	error("This metatable is locked.")
end

return gun