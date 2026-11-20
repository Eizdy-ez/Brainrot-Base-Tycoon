-- EventManager — the living world: Gold Rain events and the base-raiding Bandit NPC.
-- EventManager.luau — the living world: Gold Rain (mutation frenzy)
-- and the Bandit NPC who sneaks into bases and steals displayed
-- brainrots unless a player tackles him.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local EventManager = {}
local ctx

local function eachPlayer(fn)
	for _, player in ipairs(Players:GetPlayers()) do
		fn(player)
	end
end

local function bannerAll(title, sub, color, duration)
	eachPlayer(function(player)
		ctx.Remotes.Event:FireClient(player, "Banner", title, sub, color, duration)
	end)
end

local function soundAll(name, pitch)
	eachPlayer(function(player)
		ctx.Remotes.Event:FireClient(player, "PlaySound", name, pitch or 1)
	end)
end

local function musicAll(track)
	eachPlayer(function(player)
		ctx.Remotes.Event:FireClient(player, "EventMusic", track)
	end)
end

local function pushAll()
	eachPlayer(function(player)
		ctx.Data.PushState(player, ctx)
	end)
end

local function insideAnyBase(pos)
	for _, base in ipairs(ctx.Bases.List) do
		if math.abs(pos.X - base.Center.X) < 23 and math.abs(pos.Z - base.Center.Z) < 23 then
			return true
		end
	end
	return false
end

--====================================================================--
-- Gold Rain
--====================================================================--
local function runGoldRain()
	ctx.GoldRainActive = true
	ctx.World.GoldRainEmitter.Rate = 240
	bannerAll("🌧️ GOLD RAIN!", "Golden brainrots are " .. Config.Events.GoldRainMutationBoost .. "x more likely — go buy one before it sinks!", Color3.fromRGB(255, 200, 60), 5)
	soundAll("Magic", 1)
	musicAll("Gold")
	pushAll()
	task.wait(Config.Events.GoldRainDuration)
	ctx.World.GoldRainEmitter.Rate = 0
	ctx.GoldRainActive = false
	musicAll("Main")
	bannerAll("☀️ The Gold Rain has passed", "The meadows sparkle a little less… for now.", Color3.fromRGB(160, 210, 255), 3)
	pushAll()
end

--====================================================================--
-- Bandit NPC
--====================================================================--
local banditActive = false

local function banditY(pos)
	if insideAnyBase(pos) then
		return 2.35
	end
	return 1.7
end

local function moveToward(model, target, speed, dt)
	local body = model.PrimaryPart
	local pos = body.Position
	local dx, dz = target.X - pos.X, target.Z - pos.Z
	local dist = math.sqrt(dx * dx + dz * dz)
	if dist < 1.6 then
		return true
	end
	local stepLen = math.min(dist, speed * dt)
	local nx, nz = pos.X + dx / dist * stepLen, pos.Z + dz / dist * stepLen
	local ny = banditY(Vector3.new(nx, 0, nz))
	body.CFrame = CFrame.lookAt(Vector3.new(nx, ny, nz), Vector3.new(nx + dx, ny, nz + dz))
	return false
end

local function runBandit()
	if banditActive then
		return
	end
	local candidates = {}
	for _, base in ipairs(ctx.Bases.List) do
		-- a locked base has its gate shut, so the bandit cannot get in:
		-- he only ever targets bases whose gate stands open
		if base.Owner and not base.Locked and ctx.Data.Profiles[base.Owner] and #ctx.Data.Profiles[base.Owner].Displayed >= 1 then
			candidates[#candidates + 1] = base
		end
	end
	if #candidates == 0 then
		return
	end
	banditActive = true
	local base = candidates[math.random(#candidates)]
	local victim = base.Owner
	local bandit = ctx.Factory.BuildBandit()
	local startZ = base.Center.Z
	bandit.PrimaryPart.CFrame = CFrame.new(0, banditY(Vector3.new(0, 0, startZ)), startZ)
	bandit.Parent = Workspace

	local state = { dead = false, loot = nil, lootEntry = nil }
	bandit.PrimaryPart.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit and hit.Parent)
		if player and not state.dead then
			state.dead = true
			ctx.Remotes.Event:FireClient(player, "PlaySound", "Bandit", 1.2)
			if state.loot then
				local loot = state.loot
				loot.PrimaryPart.CanCollide = true
				local pos = bandit.PrimaryPart.Position
				loot.PrimaryPart.CFrame = CFrame.new(pos.X, 0.35 + loot.PrimaryPart.Size.Y / 2, pos.Z)
				loot.Parent = ctx.World.WildFolder
				ctx.Spawn.RegisterWild(loot, ctx.Spawn.ZoneFromPosition(pos))
				ctx.Remotes.Event:FireClient(player, "Notify", "💥 You tackled the bandit and saved the " .. state.lootEntry.Name .. "!", "Success")
				ctx.Remotes.Event:FireClient(player, "PlaySound", "Celebrate", 1)
				if victim then
					ctx.Remotes.Event:FireClient(victim, "Notify", "💪 " .. player.DisplayName .. " tackled the bandit — your brainrot dropped in the field!", "Success")
				end
			else
				ctx.Remotes.Event:FireClient(player, "Notify", "💥 You scared the bandit away!", "Success")
			end
		end
	end)

	task.spawn(function()
		local dirToCenter = base.Center.X > 0 and -1 or 1
		local frontPos = Vector3.new(base.Center.X + dirToCenter * 17, 0, base.Center.Z)
		local function walkTo(target, speed, timeout)
			local waited = 0
			while not state.dead and waited < timeout do
				local dt = task.wait(0.05)
				waited += dt
				if moveToward(bandit, target, speed, dt) then
					return true
				end
				if state.loot then
					local bp = bandit.PrimaryPart
					state.loot.PrimaryPart.CFrame = bp.CFrame * CFrame.new(0, 3.4, 0)
				end
			end
			return false
		end

		-- sneak to the base, grab a brainrot, run for the plaza exit
		if walkTo(frontPos, 10, 20) and not state.dead then
			local profile = ctx.Data.Profiles[victim]
			-- if the owner hit the lock while he was sneaking in, he
			-- gives up the grab and slips back out empty-handed
			if profile and #profile.Displayed > 0 and not base.Locked then
				local padIndex = math.random(#profile.Displayed)
				local pad = base.Pads[padIndex]
				if pad and walkTo(Vector3.new(pad.Anchor.X, 0, pad.Anchor.Z), 9, 12) and not state.dead then
					local model = pad.Model
					if model and model:GetAttribute("Kind") == "Displayed" then
						local entry = table.remove(profile.Displayed, padIndex)
						pad.Model = nil
						model:SetAttribute("Kind", "BanditLoot")
						model.PrimaryPart.CanCollide = false
						state.loot = model
						state.lootEntry = entry
						ctx.Bases.RenderDisplayed(base)
						ctx.Data.PushState(victim, ctx)
						ctx.Remotes.Event:FireClient(victim, "Notify", "🕵️ A BANDIT stole your " .. entry.Name .. "! Tackle him before he escapes!", "Error")
						ctx.Remotes.Event:FireClient(victim, "PlaySound", "Bandit", 1)
					end
				end
			end
		end
		if not state.dead then
			walkTo(Vector3.new(0, 0, 10), 12, 25)
		end
		if not state.dead and state.loot then
			state.loot:Destroy()
			if victim then
				ctx.Remotes.Event:FireClient(victim, "Notify", "😭 The bandit escaped with your " .. state.lootEntry.Name .. "!", "Error")
			end
		end
		bandit:Destroy()
		banditActive = false
	end)
end

function EventManager.Start(c)
	ctx = c
	-- widen the gold-rain rig so particles fall over the whole island
	local rig = Workspace:WaitForChild("BrainrotWorld"):WaitForChild("GoldRainRig")
	rig.Size = Vector3.new(240, 1, 250)
	rig.CFrame = CFrame.new(0, 58, -93)

	task.spawn(function()
		task.wait(75)
		while true do
			runGoldRain()
			task.wait(math.random(Config.Events.GoldRainInterval[1], Config.Events.GoldRainInterval[2]))
		end
	end)
	task.spawn(function()
		task.wait(60)
		while true do
			runBandit()
			task.wait(math.random(Config.Events.BanditInterval[1], Config.Events.BanditInterval[2]))
		end
	end)
end

return EventManager
