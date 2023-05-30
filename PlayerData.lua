local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GamepassInfo = require(ReplicatedStorage:WaitForChild("RoactComponenets").GamepassInfo)

local PlayerData = {
	playerData = {},
	playerDataStore = DataStoreService:GetDataStore("PlayerData"),
}

local function characterAdded(character)

end

function PlayerData.add(player)
	local DEFAULT_SCHEMA = {
		points = 0,
		reloadTime = "none",
		laserSight = false,
	}
	
	if player.Name == "crockpoti" or player.Name == "SnowKevin494" then
		DEFAULT_SCHEMA.reloadTime = "inf"
	end
	
	local playerData
	local success, data = pcall(function()
		return PlayerData.playerDataStore:GetAsync(player.UserId)
	end)

	if success then
		if data ~= nil then
			playerData = data
		else
			playerData = DEFAULT_SCHEMA
		end
	else
		playerData = DEFAULT_SCHEMA
		warn(data)
	end

	PlayerData.playerData[player] = playerData
end

function PlayerData.remove(player)
	local playerData = PlayerData.playerData[player]

	local success, err = pcall(function()
		-- save player data
		PlayerData.playerDataStore:SetAsync(string.format("Player_%d", player.UserId), playerData)
	end)

	if (err) then
		warn(err)
	end

	repeat
		task.wait()
	until success

	PlayerData.playerData[player] = nil
end

function PlayerData:addpoints(player, amount)
	local playerData = self.playerData[player]
	
	playerData.points+=amount
end

function PlayerData:subpoints(player, amount)
	local playerData = self.playerData[player]
	
	playerData.points-=amount
end

function PlayerData:getpoints(player)
	return self.playerData[player].points
end

function PlayerData:getreloadtime(player)
	return self.playerData[player].reloadTime
end

function PlayerData:setreloadtime(player, id)
	for gamepass, info in GamepassInfo do
		if info.id == id then
			self.playerData[player].reloadTime = gamepass
		end
	end
end

function PlayerData:setlasersight(player)
	self.playerData[player].laserSight = true
end

return PlayerData