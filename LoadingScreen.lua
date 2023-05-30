local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Vendor = ReplicatedStorage:WaitForChild("Vendor")

local Roact = require(Vendor.Roact)
local Signals = require(ReplicatedStorage:WaitForChild("Signals"))

local loadingScreenDone = Signals.loadingScreenDone

local LoadingScreen = Roact.Component:extend("LoadingScreen")

local CROCKPOT_IMAGE_IG = "rbxassetid://12849260877"
local ZOMBIE_NIGHTS_IMAGE_ID = "rbxassetid://12849173134"
local TIME_UNTIL_FADE = 3

function LoadingScreen:init()
	self.state = {
		image = ZOMBIE_NIGHTS_IMAGE_ID,
		transparency = 1,
		enabled = true,
		isLoaded = false,
	}
	
	self.onPlayBtnActivated = function()
		loadingScreenDone:Fire()
		self:setState({enabled = false})
	end
end

function LoadingScreen:didMount()
	task.spawn(function()
		while self.state.transparency > 0 do
			self:setState({transparency = self.state.transparency - 0.05})
			task.wait(0.1)
		end
	end)
	
	task.spawn(function()
		repeat
			task.wait(1)
		until game:IsLoaded()
		
		self:setState({isLoaded = true})
	end)
	
	task.spawn(function()
		repeat
			task.wait(1)
		until game:IsLoaded() and self.state.transparency >= 1
		
		loadingScreenDone:Fire()
		self:setState({enabled = false})
	end)
end

function LoadingScreen:didUpdate()
	if self.state.transparency <= 0 then
		task.delay(TIME_UNTIL_FADE, function()
			while self.state.transparency < 1 do
				self:setState({transparency = self.state.transparency + 0.05})
				task.wait(0.1)
			end
		end)
	end
end

function LoadingScreen:render()
	local image = self.state.image
	local transparency = self.state.transparency
	local enabled = self.state.enabled
	local isLoaded = self.state.isLoaded
	
	local onPlayBtnActivated = self.onPlayBtnActivated
	
	local transparencySequence = NumberSequence.new(transparency)
	
	local bottom = isLoaded and Roact.createElement("TextButton", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.5, 0.75),
		Size = UDim2.fromScale(0.5, 0.5),
		Text = "click me, play now!",
		TextColor3 = Color3.fromRGB(255, 255, 0),
		ZIndex = 2,
		[Roact.Event.Activated] = function() onPlayBtnActivated() end,
	}) or Roact.createElement("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.5, 0.75),
		Size = UDim2.fromScale(0.5, 0.5),
		Text = "loading..",
		TextColor3 = Color3.fromRGB(255, 255, 0),
		ZIndex = 2,
	})
	
	return Roact.createElement("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(40, 50, 72),
		Visible = enabled,
		ZIndex = 2,
	}, {
		Roact.createElement("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.5, 0.5),
			Image = image,
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 2,
		}, {
			UIAspectRatioConstraint = Roact.createElement("UIAspectRatioConstraint", {
				
			}),
			UIGradient = Roact.createElement("UIGradient", {
				Transparency = transparencySequence,
			})
		}),
		bottom = bottom
	})
end

return LoadingScreen