local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vendor = ReplicatedStorage:WaitForChild("Vendor")

local Roact = require(Vendor.Roact)

local PlayerDetails = require(ReplicatedStorage.RoactComponenets.PlayerDetails)
local GameDetails = require(ReplicatedStorage.RoactComponenets.GameDetails)

return function (props)
	local wave = props.wave
	local zombies = props.zombies
	local ammo = props.ammo
	local health = props.health
	local points = props.points
	local positions = props.positions
	local wallHealth = props.wallHealth
	
	return Roact.createElement("Frame", {
		Style = Enum.FrameStyle.DropShadow,
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Position = UDim2.fromScale(0.5, 0),
		Size = UDim2.fromScale(1, 0.11),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
	}, {
		uIListLayout = Roact.createElement("UIListLayout", {
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		GameDetails = Roact.createElement(GameDetails,{
			wave = wave,
			zombies = zombies,
			positions = positions,
			wallHealth = wallHealth,
		}),
		PlayerDetails = Roact.createElement(PlayerDetails,{
			ammo = ammo,
			health = health,
			points = points,
		}),
	})
end