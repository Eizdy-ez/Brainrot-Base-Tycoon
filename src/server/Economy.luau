-- Economy.luau — the money heartbeat: every second each displayed brainrot
-- pays its income (times the owner's rebirth multiplier) into the base's
-- pending pool; stepping on the collect pad claims the pool as cash.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Util = require(Shared:WaitForChild("Util"))

local Economy = {}
local ctx

function Economy.Collect(base)
	local player = base.Owner
	if not player then
		return
	end
	local amount = math.floor(base.Pending)
	if amount < 1 then
		ctx.Remotes.Event:FireClient(player, "Notify", "Nothing to collect yet — your brainrots are still earning!", "Info")
		return
	end
	base.Pending = 0
	base.CollectLabel.Text = "COLLECT\n$0"
	ctx.Data.AddCash(player, amount, ctx)
	ctx.Remotes.Event:FireClient(player, "CollectFx", amount, base.CollectPad.Position)
	ctx.Remotes.Event:FireClient(player, "PlaySound", "Collect", 1)
	local profile = ctx.Data.Profiles[player]
	if profile and profile.TutorialStep == 2 then
		profile.TutorialStep = 3
	end
	ctx.Quests.Refresh(player)
	ctx.Data.PushState(player, ctx)
end

function Economy.Start(c)
	ctx = c
	task.spawn(function()
		while true do
			task.wait(1)
			for _, base in ipairs(ctx.Bases.List) do
				local owner = base.Owner
				if owner then
					local profile = ctx.Data.Profiles[owner]
					if profile and #profile.Displayed > 0 then
						local perSec = 0
						for _, entry in ipairs(profile.Displayed) do
							local def = Config.BrainrotByName[entry.Name]
							if def then
								perSec += Config.BrainrotIncome(def, entry.Mutation)
							end
						end
						perSec *= Config.IncomeMultiplier(profile.Rebirths)
						if perSec > 0 then
							local before = math.floor(base.Pending)
							base.Pending += perSec
							local after = math.floor(base.Pending)
							if after ~= before then
								base.CollectLabel.Text = "COLLECT\n$" .. Util.FormatInt(after)
							end
						end
					end
				end
			end
		end
	end)
end

return Economy
