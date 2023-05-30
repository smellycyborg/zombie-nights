local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vendor = ReplicatedStorage:WaitForChild("Vendor")

local Roact = require(Vendor.Roact)
local ZombiesInstances = require(script.Parent.ZombieInstances)

return function(props)
	local positions = props.positions
	local wave = props.wave
	local zombies = props.zombies
	local wallHealth = props.wallHealth
	
	return Roact.createElement("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 0.6),
	}, {
		uIListLayout = Roact.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),

		wave = Roact.createElement("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(0.15, 1),
			LayoutOrder = 1,
		}, {
			textLabel = Roact.createElement("TextLabel", {
				FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
				Text = "wave: " .. wave,
				TextColor3 = Color3.fromRGB(217, 217, 217),
				TextScaled = true,
				TextSize = 14,
				TextWrapped = true,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0, 0.244),
				Size = UDim2.fromScale(1.03, 0.511),
			}),
		}),
		
		-- frame for zombie status and wall health
		holder = Roact.createElement("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(0.7, 1),
			LayoutOrder = 2,
		}, {
			UIListLayout = Roact.createElement("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			zombieStatus = Roact.createElement("Frame", {
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Size = UDim2.fromScale(1, 0.7),
				LayoutOrder = 1,
			}, {
				zombieStatusBar = Roact.createElement("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.fromRGB(42, 209, 34),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromScale(1, 0.95),
				}, {
					exlamations = Roact.createElement("Frame", {
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 1,
						Size = UDim2.fromScale(1, 1),
					}, {
						exlamationInstances = Roact.createElement(ZombiesInstances, {
							positions = positions,
						})
					}),
				}),
			}),
			wallHealthHolder = Roact.createElement("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 0.3),
				LayoutOrder = 2,
			}, {
				wallHealth = Roact.createElement("Frame", {
					Size = wallHealth,
					BackgroundColor3 = Color3.fromRGB(255, 0, 0),
				})
			})
		}),

		zombiesAmount = Roact.createElement("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(0.15, 1),
			LayoutOrder = 3,
		}, {
			textLabel1 = Roact.createElement("TextLabel", {
				FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
				Text = "zombies: " .. zombies,
				TextColor3 = Color3.fromRGB(217, 217, 217),
				TextScaled = true,
				TextSize = 14,
				TextWrapped = true,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(-0.0392, 0.188),
				Size = UDim2.fromScale(0.99, 0.606),
			}),
		}),
	})
end
