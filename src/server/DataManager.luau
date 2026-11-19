-- DataManager.luau — per-player profiles: DataStore persistence with pcall
-- guards and a session fallback, leaderstats, and the state snapshot the
-- client UI renders from.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Util = require(Shared:WaitForChild("Util"))

local DataManager = {}
DataManager.Profiles = {}   -- [player] = profile (plain data)
DataManager.SessionOnly = {} -- [player] = true when the store could not be read

local store = nil
local function getStore()
	if store then
		return store
	end
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Config.DataStoreName)
	end)
	if ok then
		store = result
	end
	return store
end

function DataManager.DefaultProfile()
	return {
		Cash = Config.StartCash,
		TotalEarned = 0,
		Rebirths = 0,
		Pads = Config.Upgrades.Pads.Start,
		SpeedLvl = Config.Upgrades.Speed.Start,
		CarryLvl = Config.Upgrades.Carry.Start,
		LuckLvl = Config.Upgrades.Luck.Start,
		Zones = { true, false, false },
		Displayed = {}, -- ordered: { Name = string, Mutation = string } per pad
		QuestIndex = 1,
		QuestBase = 0,
		TutorialStep = 0,
		TutorialDone = false,
		Stats = { Placed = 0, Bought = 0, BrainrotsBought = 0, WavesSurvived = 0, BestBuy = 0 },
	}
end

local function mergeDefaults(profile, defaults)
	for k, v in pairs(defaults) do
		if profile[k] == nil or type(profile[k]) ~= type(v) then
			profile[k] = Util.CopyTable(v)
		elseif type(v) == "table" and k ~= "Displayed" then
			mergeDefaults(profile[k], v)
		end
	end
	return profile
end

function DataManager.LoadProfile(player)
	local profile = DataManager.DefaultProfile()
	local ds = getStore()
	if ds then
		local ok, data = pcall(function()
			return ds:GetAsync("player_" .. player.UserId)
		end)
		if ok and type(data) == "table" then
			profile = mergeDefaults(data, DataManager.DefaultProfile())
		elseif not ok then
			DataManager.SessionOnly[player] = true
			warn("[Brainrot] DataStore read failed for " .. player.Name .. "; session-only profile")
		end
	else
		DataManager.SessionOnly[player] = true
	end
	DataManager.Profiles[player] = profile
	DataManager.SetupLeaderstats(player)
	return profile
end

function DataManager.SaveProfile(player)
	local profile = DataManager.Profiles[player]
	if not profile then
		return
	end
	local ds = getStore()
	if not ds then
		return
	end
	local ok, err = pcall(function()
		ds:SetAsync("player_" .. player.UserId, profile)
	end)
	if not ok then
		warn("[Brainrot] DataStore save failed for " .. player.Name .. ": " .. tostring(err))
	end
end

function DataManager.SetupLeaderstats(player)
	local profile = DataManager.Profiles[player]
	local folder = Instance.new("Folder")
	folder.Name = "leaderstats"
	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = math.floor(profile.Cash)
	cash.Parent = folder
	local earned = Instance.new("IntValue")
	earned.Name = "Total Earned"
	earned.Value = math.floor(profile.TotalEarned)
	earned.Parent = folder
	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Value = profile.Rebirths
	rebirths.Parent = folder
	folder.Parent = player
end

function DataManager.SyncLeaderstats(player)
	local profile = DataManager.Profiles[player]
	local folder = player:FindFirstChild("leaderstats")
	if not (profile and folder) then
		return
	end
	folder.Cash.Value = math.floor(profile.Cash)
	folder["Total Earned"].Value = math.floor(profile.TotalEarned)
	folder.Rebirths.Value = profile.Rebirths
end

function DataManager.AddCash(player, amount, ctx)
	local profile = DataManager.Profiles[player]
	if not profile then
		return
	end
	profile.Cash += amount
	if amount > 0 then
		profile.TotalEarned += amount
	end
	DataManager.SyncLeaderstats(player)
	if ctx then
		DataManager.PushState(player, ctx)
	end
end

function DataManager.SpendCash(player, amount)
	local profile = DataManager.Profiles[player]
	if not profile or profile.Cash < amount then
		return false
	end
	profile.Cash -= amount
	DataManager.SyncLeaderstats(player)
	return true
end

-- The snapshot the client UI renders from. Kept small: it is pushed whole.
function DataManager.BuildState(player, ctx)
	local profile = DataManager.Profiles[player]
	if not profile then
		return nil
	end
	local base = ctx and ctx.Bases and ctx.Bases.ByPlayer[player]
	local incomePerSec = 0
	for _, entry in ipairs(profile.Displayed) do
		local def = Config.BrainrotByName[entry.Name]
		if def then
			incomePerSec += Config.BrainrotIncome(def, entry.Mutation)
		end
	end
	incomePerSec *= Config.IncomeMultiplier(profile.Rebirths)

	local displayed = {}
	for i, entry in ipairs(profile.Displayed) do
		local def = Config.BrainrotByName[entry.Name]
		if def then
			displayed[i] = {
				Name = entry.Name, Mutation = entry.Mutation, Rarity = def.Rarity,
				Income = Config.BrainrotIncome(def, entry.Mutation),
			}
		end
	end

	local quest = nil
	local questDef = Config.Quests[profile.QuestIndex]
	if questDef then
		quest = {
			Text = questDef.Text, Reward = questDef.Reward,
			Progress = ctx and ctx.Quests and ctx.Quests.GetProgress(player) or 0,
			Target = questDef.Target, Index = profile.QuestIndex, Total = #Config.Quests,
		}
	end

	return {
		Cash = math.floor(profile.Cash),
		TotalEarned = math.floor(profile.TotalEarned),
		Rebirths = profile.Rebirths,
		IncomePerSec = incomePerSec,
		Pending = base and math.floor(base.Pending) or 0,
		Pads = profile.Pads,
		Displayed = displayed,
		SpeedLvl = profile.SpeedLvl,
		CarryLvl = profile.CarryLvl,
		LuckLvl = profile.LuckLvl,
		CarryCapacity = Config.Upgrades.Carry.BaseCapacity + profile.CarryLvl,
		CarryCount = ctx and ctx.Carry and ctx.Carry.GetCount(player) or 0,
		Zones = profile.Zones,
		Quest = quest,
		RebirthRequirement = Config.RebirthRequirement(profile.Rebirths),
		IncomeMultiplier = Config.IncomeMultiplier(profile.Rebirths),
		TutorialStep = profile.TutorialStep,
		TutorialDone = profile.TutorialDone,
		BaseSlot = base and base.Slot or 0,
		GoldRain = ctx and ctx.GoldRainActive or false,
	}
end

function DataManager.PushState(player, ctx)
	local state = DataManager.BuildState(player, ctx)
	if state then
		ctx.Remotes.Event:FireClient(player, "State", state)
	end
end

function DataManager.Start(ctx)
	Players.PlayerRemoving:Connect(function(player)
		DataManager.SaveProfile(player)
		DataManager.Profiles[player] = nil
		DataManager.SessionOnly[player] = nil
	end)
	game:BindToClose(function()
		for player in pairs(DataManager.Profiles) do
			DataManager.SaveProfile(player)
		end
	end)
	task.spawn(function()
		while true do
			task.wait(Config.AutosaveSeconds)
			for player in pairs(DataManager.Profiles) do
				DataManager.SaveProfile(player)
			end
		end
	end)
end

return DataManager
