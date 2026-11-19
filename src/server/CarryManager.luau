-- CarryManager.luau — the hands of the game: catching wild brainrots by
-- touch, the lucky-catch evolution roll, carrying them stacked on the head,
-- placing them on base pads, stealing from unlocked bases, and dropping
-- everything when a wave (or death) knocks you over.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local CarryManager = {}
local ctx
local Carried = {}       -- [player] = { model, ... } in stack order
local notifyAt = {}      -- [player] = last "carry full" nag time
local placeDebounce = {} -- [player] = last place time
local stealReadyAt = {}  -- [player] = next allowed steal time

function CarryManager.GetCount(player)
	return #(Carried[player] or {})
end

local function capacityOf(profile)
	return Config.Upgrades.Carry.BaseCapacity + profile.CarryLvl
end

local function nag(player, text)
	if (notifyAt[player] or 0) < os.clock() - 2.5 then
		notifyAt[player] = os.clock()
		ctx.Remotes.Event:FireClient(player, "Notify", text, "Error")
		ctx.Remotes.Event:FireClient(player, "PlaySound", "Error", 1)
	end
end

function CarryManager.TryPickup(player, model)
	if not model or not model.Parent then
		return
	end
	if model:GetAttribute("Kind") ~= "Wild" then
		return
	end
	local profile = ctx.Data.Profiles[player]
	if not profile then
		return
	end
	local carried = Carried[player] or {}
	if #carried >= capacityOf(profile) then
		nag(player, "🎒 Carry full! Take it home or buy +CARRY at your base")
		return
	end
	model:SetAttribute("Kind", "Carried")
	ctx.Spawn.Unregister(model)

	local name = model:GetAttribute("BrainrotName")
	local mutation = model:GetAttribute("Mutation")
	local rarity = model:GetAttribute("Rarity")

	-- Lucky catch: the brainrot evolves +1 rarity on the spot.
	if math.random() < profile.LuckLvl * Config.Upgrades.Luck.PerLevel and rarity < 5 then
		local candidates = {}
		for _, def in ipairs(Config.Brainrots) do
			if def.Rarity == rarity + 1 then
				candidates[#candidates + 1] = def
			end
		end
		local newDef = candidates[math.random(#candidates)]
		local cf = model.PrimaryPart.CFrame
		model:Destroy()
		model = ctx.Factory.Build(newDef, mutation)
		model:SetAttribute("Kind", "Carried")
		model.PrimaryPart.CFrame = cf
		name, rarity = newDef.Name, rarity + 1
		ctx.Remotes.Event:FireClient(player, "Notify", "🍀 LUCKY CATCH! It evolved into " .. newDef.Name .. "!", "Success")
		ctx.Remotes.Event:FireClient(player, "PlaySound", "Magic", 1)
	end

	model.PrimaryPart.CanCollide = false
	model.Parent = Workspace
	carried[#carried + 1] = model
	Carried[player] = carried

	profile.Stats.BestCatch = math.max(profile.Stats.BestCatch, rarity)
	if profile.TutorialStep == 0 then
		profile.TutorialStep = 1
	end
	ctx.Remotes.Event:FireClient(player, "PlaySound", "Pickup", 1)
	ctx.Quests.Refresh(player)
	ctx.Data.PushState(player, ctx)
end

function CarryManager.TryPlace(player, base)
	local carried = Carried[player]
	if not carried or #carried == 0 then
		return
	end
	if (placeDebounce[player] or 0) > os.clock() - 0.35 then
		return
	end
	placeDebounce[player] = os.clock()
	local profile = ctx.Data.Profiles[player]
	if not profile then
		return
	end
	if #profile.Displayed >= profile.Pads then
		nag(player, "🟦 All pads full! Buy +2 PADS or fuse brainrots to free space")
		return
	end
	local model = table.remove(carried)
	local entry = { Name = model:GetAttribute("BrainrotName"), Mutation = model:GetAttribute("Mutation") }
	model:Destroy()
	profile.Displayed[#profile.Displayed + 1] = entry
	profile.Stats.Placed += 1
	if profile.TutorialStep == 1 then
		profile.TutorialStep = 2
	end
	ctx.Bases.RenderDisplayed(base)
	ctx.Remotes.Event:FireClient(player, "PlaySound", "Place", 1)
	ctx.Quests.Refresh(player)
	ctx.Data.PushState(player, ctx)
end

function CarryManager.TrySteal(thief, base, padIndex)
	if (stealReadyAt[thief] or 0) > os.clock() then
		return
	end
	local victim = base.Owner
	if not victim or thief == victim then
		return
	end
	local model = base.Pads[padIndex] and base.Pads[padIndex].Model
	if not model or model:GetAttribute("Kind") ~= "Displayed" then
		return
	end
	if base.Locked then
		stealReadyAt[thief] = os.clock() + 1.5
		ctx.Remotes.Event:FireClient(thief, "Notify", "🔒 That base is LOCKED!", "Error")
		ctx.Remotes.Event:FireClient(thief, "PlaySound", "Error", 1)
		return
	end
	local thiefProfile = ctx.Data.Profiles[thief]
	if not thiefProfile then
		return
	end
	local carried = Carried[thief] or {}
	if #carried >= capacityOf(thiefProfile) then
		nag(thief, "🎒 Carry full — you can't steal right now!")
		return
	end
	stealReadyAt[thief] = os.clock() + 2
	local victimProfile = ctx.Data.Profiles[victim]
	local entry = table.remove(victimProfile.Displayed, padIndex)
	base.Pads[padIndex].Model = nil -- keep RenderDisplayed from destroying it
	model:SetAttribute("Kind", "Carried")
	model.PrimaryPart.CanCollide = false
	carried[#carried + 1] = model
	Carried[thief] = carried
	ctx.Bases.RenderDisplayed(base)
	ctx.Remotes.Event:FireClient(thief, "Notify", "😈 You stole a " .. Config.DisplayName(Config.BrainrotByName[entry.Name], entry.Mutation) .. "! Run home!", "Success")
	ctx.Remotes.Event:FireClient(thief, "PlaySound", "Bandit", 1)
	ctx.Remotes.Event:FireClient(victim, "Notify", "⚠️ " .. thief.DisplayName .. " stole your " .. entry.Name .. "! Lock your base next time!", "Error")
	ctx.Remotes.Event:FireClient(victim, "PlaySound", "Bandit", 0.9)
	ctx.Data.PushState(thief, ctx)
	ctx.Data.PushState(victim, ctx)
end

-- Everything carried falls to the ground and becomes wild again.
function CarryManager.DropAll(player, position)
	local carried = Carried[player]
	if not carried or #carried == 0 then
		return
	end
	Carried[player] = {}
	for _, model in ipairs(carried) do
		if model and model.Parent and model.PrimaryPart then
			local body = model.PrimaryPart
			body.CanCollide = true
			local dropPos = position + Vector3.new((math.random() - 0.5) * 7, 0, (math.random() - 0.5) * 7)
			body.CFrame = CFrame.new(dropPos.X, 0.35 + body.Size.Y / 2, dropPos.Z)
			model.Parent = ctx.World.WildFolder
			ctx.Spawn.RegisterWild(model, ctx.Spawn.ZoneFromPosition(dropPos))
		end
	end
	ctx.Data.PushState(player, ctx)
end

function CarryManager.ClearPlayer(player)
	local carried = Carried[player]
	if carried then
		for _, model in ipairs(carried) do
			if model then
				model:Destroy()
			end
		end
	end
	Carried[player] = nil
	notifyAt[player] = nil
	placeDebounce[player] = nil
	stealReadyAt[player] = nil
end

function CarryManager.Start(c)
	ctx = c
	-- stepping on one of your own pedestals places the top carried brainrot
	for _, base in ipairs(ctx.Bases.List) do
		for _, pad in ipairs(base.Pads) do
			pad.Pedestal.Touched:Connect(function(hit)
				local player = Players:GetPlayerFromCharacter(hit and hit.Parent)
				if player and player == base.Owner then
					CarryManager.TryPlace(player, base)
				end
			end)
		end
	end
	-- carried brainrots ride stacked above the head, bobbing
	RunService.Heartbeat:Connect(function()
		local t = os.clock()
		for player, carried in pairs(Carried) do
			local character = player.Character
			local head = character and character:FindFirstChild("Head")
			if head then
				for i, model in ipairs(carried) do
					local body = model.PrimaryPart
					if body then
						local bob = math.sin(t * 3 + i * 1.4) * 0.14
						local target = head.CFrame * CFrame.new(0, 1.6 + (i - 1) * 2.05 + bob, 0)
						body.CFrame = body.CFrame:Lerp(target, 0.45)
					end
				end
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		CarryManager.ClearPlayer(player)
	end)
end

return CarryManager
