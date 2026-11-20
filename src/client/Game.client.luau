-- Game (client) — client bootstrap: builds the ScreenGui, starts the UI modules and routes server events.
-- Brainrot Base Tycoon — client bootstrap.
-- Builds the ScreenGui, starts every UI module, routes the server's events
-- (state snapshots, toasts, sounds, banners, effects) and sends player
-- actions (shop buys, rebirth, dash) back. All rendering of game
-- state comes from the server's snapshots; this side only presents.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("BrainrotRemotes")
local actionRemote = remotes:WaitForChild("Action")
local eventRemote = remotes:WaitForChild("Event")
local stateFunction = remotes:WaitForChild("GetState")

local AudioClient = require(script.Parent:WaitForChild("AudioClient"))
local Hud = require(script.Parent:WaitForChild("Hud"))
local QuestUI = require(script.Parent:WaitForChild("QuestUI"))
local ShopUI = require(script.Parent:WaitForChild("ShopUI"))
local Tutorial = require(script.Parent:WaitForChild("Tutorial"))
local Effects = require(script.Parent:WaitForChild("Effects"))

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotGui"
gui.ResetOnSpawn = false
gui.DisplayOrder = 5
gui.Parent = player:WaitForChild("PlayerGui")

local ctx = {
	Remotes = { Action = actionRemote, Event = eventRemote, GetState = stateFunction },
	Audio = AudioClient,
	Hud = Hud,
	QuestUI = QuestUI,
	ShopUI = ShopUI,
	Tutorial = Tutorial,
	Effects = Effects,
	State = nil,
}

local function requestDash()
	actionRemote:FireServer("Dash")
	Effects.DashFov()
end
ctx.RequestDash = requestDash

AudioClient.Start(ctx)
Hud.Start(ctx, gui)
QuestUI.Start(ctx, gui)
ShopUI.Start(ctx, gui)
Tutorial.Start(ctx, gui)
Effects.Start(ctx)

local function applyState(state)
	if type(state) ~= "table" then
		return
	end
	ctx.State = state
	Hud.Update(state)
	QuestUI.Update(state)
	ShopUI.Update(state)
	Tutorial.Update(state)
	Effects.GateCheck(state)
end

eventRemote.OnClientEvent:Connect(function(eventName, a, b, c, d)
	if eventName == "State" then
		applyState(a)
	elseif eventName == "Notify" then
		Hud.Toast(a, b)
	elseif eventName == "PlaySound" then
		AudioClient.PlaySfx(a, b)
	elseif eventName == "Banner" then
		Hud.Banner(a, b, c, d)
	elseif eventName == "CollectFx" then
		Effects.CollectBurst(a, b)
	elseif eventName == "Shake" then
		Effects.Shake(a)
	elseif eventName == "OpenPanel" then
		if a == "Shop" then
			ShopUI.Open()
		end
	elseif eventName == "OpenRebirth" then
		Hud.ShowRebirthConfirm()
	elseif eventName == "EventMusic" then
		AudioClient.PlayBgm(a)
	end
end)

-- first snapshot (the server also pushes one shortly after join)
task.spawn(function()
	for _ = 1, 5 do
		local ok, state = pcall(function()
			return stateFunction:InvokeServer()
		end)
		if ok and state then
			applyState(state)
			break
		end
		task.wait(1)
	end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
		requestDash()
	end
end)

print("[Brainrot Base Tycoon] client ready")
