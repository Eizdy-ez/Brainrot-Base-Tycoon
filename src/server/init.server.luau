-- Brainrot Base Tycoon — server bootstrap.
-- Creates the remotes, builds the world, starts every manager, and routes
-- player joins/leaves and client actions. All game content lives in the
-- sibling ModuleScripts; this script is the wiring.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local DataManager = require(script:WaitForChild("DataManager"))
local WorldBuilder = require(script:WaitForChild("WorldBuilder"))
local BrainrotFactory = require(script:WaitForChild("BrainrotFactory"))
local BaseManager = require(script:WaitForChild("BaseManager"))
local SpawnManager = require(script:WaitForChild("SpawnManager"))
local CarryManager = require(script:WaitForChild("CarryManager"))
local Economy = require(script:WaitForChild("Economy"))
local ShopManager = require(script:WaitForChild("ShopManager"))
local QuestManager = require(script:WaitForChild("QuestManager"))
local EventManager = require(script:WaitForChild("EventManager"))
local LeaderboardManager = require(script:WaitForChild("LeaderboardManager"))

--====================================================================--
-- Remotes (created here so both sides know exactly where they live)
--====================================================================--
local remotesFolder = Instance.new("Folder")
remotesFolder.Name = "BrainrotRemotes"
local actionRemote = Instance.new("RemoteEvent")
actionRemote.Name = "Action"
actionRemote.Parent = remotesFolder
local eventRemote = Instance.new("RemoteEvent")
eventRemote.Name = "Event"
eventRemote.Parent = remotesFolder
local stateFunction = Instance.new("RemoteFunction")
stateFunction.Name = "GetState"
stateFunction.Parent = remotesFolder
remotesFolder.Parent = ReplicatedStorage

--====================================================================--
-- Shared context handed to every manager
--====================================================================--
local ctx = {
	Remotes = { Action = actionRemote, Event = eventRemote, GetState = stateFunction },
	Data = DataManager,
	Factory = BrainrotFactory,
	Bases = BaseManager,
	Spawn = SpawnManager,
	Carry = CarryManager,
	Economy = Economy,
	Shop = ShopManager,
	Quests = QuestManager,
	Events = EventManager,
	GoldRainActive = false,
	DashUntil = {},
	DashReadyAt = {},
}

ctx.World = WorldBuilder.Build()

DataManager.Start(ctx)
BaseManager.Start(ctx)
SpawnManager.Start(ctx)
CarryManager.Start(ctx)
Economy.Start(ctx)
ShopManager.Start(ctx)
QuestManager.Start(ctx)
EventManager.Start(ctx)
LeaderboardManager.Start(ctx)

stateFunction.OnServerInvoke = function(player)
	return DataManager.BuildState(player, ctx)
end

--====================================================================--
-- Dash (Shift): server-timed speed burst with a cooldown
--====================================================================--
local function doDash(player)
	local now = os.clock()
	if (ctx.DashReadyAt[player] or 0) > now then
		return
	end
	local profile = DataManager.Profiles[player]
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not (profile and humanoid) then
		return
	end
	ctx.DashReadyAt[player] = now + 4
	ctx.DashUntil[player] = now + 1.1
	humanoid.WalkSpeed = Config.Upgrades.Speed.BaseSpeed + Config.Upgrades.Speed.PerLevel * profile.SpeedLvl + 18
	eventRemote:FireClient(player, "PlaySound", "Dash", 1)
	task.delay(1.15, function()
		ShopManager.ApplySpeed(player)
	end)
end

actionRemote.OnServerEvent:Connect(function(player, action, a, b)
	if action == "BuyUpgrade" and type(a) == "string" then
		ShopManager.BuyUpgrade(player, a)
	elseif action == "Rebirth" then
		ShopManager.Rebirth(player)
	elseif action == "ToggleLock" then
		-- the HUD's LOCK button (Round 10): same server-side toggle
		-- the lock pad used to fire, on the player's OWN base only
		local base = BaseManager.ByPlayer[player]
		if base then
			BaseManager.ToggleLock(base)
		end
	elseif action == "UnlockZone" and type(a) == "number" and (a == 2 or a == 3) then
		ShopManager.UnlockZone(player, a)
	elseif action == "Dash" then
		doDash(player)
	elseif action == "RequestState" then
		DataManager.PushState(player, ctx)
	end
end)

--====================================================================--
-- Player lifecycle
--====================================================================--
local function onCharacterAdded(player, character)
	local humanoid = character:WaitForChild("Humanoid", 10)
	local hrp = character:WaitForChild("HumanoidRootPart", 10)
	if not (humanoid and hrp) then
		return
	end
	BaseManager.TeleportToBase(player)
	ShopManager.ApplySpeed(player)
	ShopManager.ApplyAura(player)
	humanoid.Died:Connect(function()
		CarryManager.DropAll(player, hrp.Position)
	end)
end

local function onPlayerAdded(player)
	local profile = DataManager.LoadProfile(player)
	local base = BaseManager.Assign(player)
	if not base then
		eventRemote:FireClient(player, "Notify", "⚠️ All bases are taken in this server — your progress still saves!", "Error")
	end
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	if player.Character then
		onCharacterAdded(player, player.Character)
	end
	task.delay(1.5, function()
		DataManager.PushState(player, ctx)
		if not profile.TutorialDone then
			eventRemote:FireClient(player, "Banner", "🧠 Welcome to Brainrot Base Tycoon!", "Brainrots wander the fields — buy one before it wanders away!", Color3.fromRGB(120, 220, 255), 5)
		else
			eventRemote:FireClient(player, "Notify", "👋 Welcome back, tycoon! Your base is just as you left it.", "Info")
		end
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end
Players.PlayerRemoving:Connect(function(player)
	BaseManager.Release(player)
	ctx.DashUntil[player] = nil
	ctx.DashReadyAt[player] = nil
end)

print("[Brainrot Base Tycoon] server ready — world built, managers running")
