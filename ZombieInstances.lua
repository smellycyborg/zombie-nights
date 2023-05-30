local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vendor = ReplicatedStorage:WaitForChild("Vendor")

local Roact = require(Vendor.Roact)

return function(props)
	local positions = props.positions
	
	local zombies = {}
	for index, position in positions do
		zombies[index] = Roact.createElement("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(0.02, 1),
			Position = position,
			Text = "!",
			TextScaled = true,
			FontFace = Font.new("rbxasset://fonts/families/AccanthisADFStd.json"),
			TextColor3 = Color3.fromRGB(255, 0, 4),
		},{
			UIStroke = Roact.createElement("UIStroke",{
				Color = Color3.fromRGB(255,98,98),
				Thickness = 2,
			})
		})
	end
	
	return Roact.createFragment(zombies)
end