-- QuestManager.luau — the quest chain: one active quest per player, progress
-- read from lifetime stats (with a baseline for the repeatable kinds), cash
-- rewards on completion, chained automatically.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Util = require(Shared:WaitForChild("Util"))

local QuestManager = {}
local ctx

local function baselineFor(profile, kind)
	if kind == "Place" then
		return profile.Stats.Placed
	elseif kind == "Buy" then
		return profile.Stats.Bought
	elseif kind == "BuyBrainrot" then
		return profile.Stats.BrainrotsBought
	elseif kind == "SurviveWave" then
		return profile.Stats.WavesSurvived
	end
	return 0
end

function QuestManager.GetProgress(player)
	local profile = ctx.Data.Profiles[player]
	if not profile then
		return 0
	end
	local def = Config.Quests[profile.QuestIndex]
	if not def then
		return 0
	end
	if def.Kind == "Place" then
		return profile.Stats.Placed - profile.QuestBase
	elseif def.Kind == "Buy" then
		return profile.Stats.Bought - profile.QuestBase
	elseif def.Kind == "BuyBrainrot" then
		return profile.Stats.BrainrotsBought - profile.QuestBase
	elseif def.Kind == "SurviveWave" then
		return profile.Stats.WavesSurvived - profile.QuestBase
	elseif def.Kind == "Earn" then
		return math.floor(profile.TotalEarned)
	elseif def.Kind == "BuyRarity" then
		return profile.Stats.BestBuy
	elseif def.Kind == "UnlockZone" then
		local highest = 1
		for zi, unlocked in ipairs(profile.Zones) do
			if unlocked then
				highest = zi
			end
		end
		return highest
	elseif def.Kind == "Rebirth" then
		return profile.Rebirths
	end
	return 0
end

-- Grant every completion the player has earned (can chain several).
function QuestManager.Refresh(player)
	local profile = ctx.Data.Profiles[player]
	if not profile then
		return
	end
	local completed = false
	while profile.QuestIndex <= #Config.Quests do
		local def = Config.Quests[profile.QuestIndex]
		if QuestManager.GetProgress(player) >= def.Target then
			profile.QuestIndex += 1
			profile.QuestBase = baselineFor(profile, (Config.Quests[profile.QuestIndex] or {}).Kind)
			ctx.Data.AddCash(player, def.Reward)
			ctx.Remotes.Event:FireClient(player, "Notify", "✅ Quest complete: " .. def.Text .. "  (+$" .. Util.FormatInt(def.Reward) .. ")", "Success")
			ctx.Remotes.Event:FireClient(player, "PlaySound", "Celebrate", 1)
			completed = true
		else
			break
		end
	end
	if completed and profile.QuestIndex > #Config.Quests then
		ctx.Remotes.Event:FireClient(player, "Notify", "🏆 ALL QUESTS COMPLETE! You are a true Brainrot Tycoon!", "Success")
	end
	ctx.Data.PushState(player, ctx)
end

function QuestManager.Start(c)
	ctx = c
end

return QuestManager
