local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vendor = ReplicatedStorage:WaitForChild("Vendor")
local RoactComponents = ReplicatedStorage:WaitForChild("RoactComponenets")

local Roact = require(Vendor.Roact)

local Details = require(RoactComponents.Details)
local LoadingScreen = require(RoactComponents.LoadingScreen)
local MenuButton = require(RoactComponents.MenuButton)
local Menu = require(RoactComponents.Menu)
local Notification = require(RoactComponents.Notification)
local GamepassScreen = require(RoactComponents.GamepassScreen)
local ToolboxScreen = require(RoactComponents.ToolboxScreen)

local Main = Roact.Component:extend("Main")

function Main:init()
	self.state = {
		currentScreen = "none",
	}
	
	self.onCloseBtnActivated = function(_rbx)
		self:setState({currentScreen = "none"})
	end
	
	-- this is for the menu buttons
	self.onBtnActivated = function(buttonName)
		self:setState(function(state)
			return {currentScreen = state.currentScreen == buttonName and "none" or buttonName}
		end)
	end
end

function Main:didUpdate(oldProps)
	if oldProps.isToolbox ~= self.props.isToolbox then
		if not self.props.isToolbox then
			self:setState({currentScreen = "none"})
		else
			self:setState({currentScreen = "toolbox"})
		end
	end
end

function Main:render()
	local ammo = self.props.ammo
	local health = self.props.health
	local wave = self.props.wave
	local zombies = self.props.zombies
	local points = self.props.points
	local positions = self.props.positions
	local message = self.props.message
	local repairWallFunc = self.props.repairWallFunc
	local wallHealth = self.props.wallHealth
	
	local currentScreen = self.state.currentScreen
	local onCloseBtnActivated = self.onCloseBtnActivated
	local onBtnActivated = self.onBtnActivated
	
	return Roact.createElement("ScreenGui", {
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
	}, {
		LoadingScreen = Roact.createElement(LoadingScreen),
		Details = Roact.createElement(Details,{
			wave = wave,
			zombies = zombies,
			ammo = ammo,
			health = health,
			points = points,
			positions = positions,
			wallHealth = wallHealth,
		}),
		MenuButton = Roact.createElement(MenuButton, {
			enabled = currentScreen == "none",
			onBtnActivated = onBtnActivated,
		}),
		Menu = Roact.createElement(Menu, {
			enabled = currentScreen == "menu",
			onCloseBtnActivated = onCloseBtnActivated,
			onBtnActivated = onBtnActivated,
			buttonNames = {"gamepass"}
		}),
		Notification = Roact.createElement(Notification, {
			message = message,
		}),
		GamepassScreen = Roact.createElement(GamepassScreen, {
			enabled = currentScreen == "gamepass",
			onCloseBtnActivated = onCloseBtnActivated,
		}),
		ToolboxScreen = Roact.createElement(ToolboxScreen, {
			enabled = currentScreen == "toolbox",
			onCloseBtnActivated = onCloseBtnActivated,
			repairWallFunc = repairWallFunc,
		})
	})
end

return Main
