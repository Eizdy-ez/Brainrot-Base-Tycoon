-- EventManager.luau — the living world: Gold Rain (mutation frenzy), the
-- Brainrot Wave (a wall of cartoon chaos that knocks carried brainrots
-- loose unless you shelter in a base), and the Bandit NPC who sneaks into
-- bases and steals displayed brainrots unless a player tackles him.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Util = require(Shared:WaitForChild("Util"))

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
	bannerAll("☀️ The Gold Rain has passed", "The fields sparkle a little less… for now.", Color3.fromRGB(160, 210, 255), 3)
	pushAll()
end

--====================================================================--
-- Brainrot Wave
--====================================================================--
local function runWave()
	local participants = {}
	eachPlayer(function(player)
		participants[player] = true
	end)
	bannerAll("⚠️ BRAINROT WAVE INCOMING!", "Shelter inside ANY base — or keep your carry if you dare!", Color3.fromRGB(255, 90, 90), Config.Events.WaveWarningTime)
	musicAll("Wave")
	for _ = 1, 3 do
		soundAll("Alarm", 1)
		task.wait(1.4)
	end
	task.wait(math.max(0, Config.Events.WaveWarningTime - 4.2))

	-- build the wave wall
	local wallModel = Instance.new("Model")
	wallModel.Name = "BrainrotWave"
	local wall = Instance.new("Part")
	wall.Name = "Wall"
	wall.Size = Vector3.new(8, 30, 360)
	wall.Color = Color3.fromRGB(64, 164, 255)
	wall.Material = Enum.Material.Glass
	wall.Transparency = 0.35
	wall.Anchored = true
	wall.CanCollide = false
	wall.CanQuery = false
	wall.CanTouch = false
	wall.Parent = wallModel
	local foam = Instance.new("Part")
	foam.Name = "Foam"
	foam.Size = Vector3.new(9, 5, 360)
	foam.Color = Color3.fromRGB(240, 250, 255)
	foam.Material = Enum.Material.SmoothPlastic
	foam.Transparency = 0.2
	foam.Anchored = true
	foam.CanCollide = false
	foam.CanQuery = false
	foam.CanTouch = false
	foam.Parent = wallModel
	local sign = Instance.new("BillboardGui")
	sign.Size = UDim2.fromOffset(500, 90)
	sign.AlwaysOnTop = true
	local signText = Instance.new("TextLabel")
	signText.Size = UDim2.fromScale(1, 1)
	signText.BackgroundTransparency = 1
	signText.Text = "🌊 BRAINROT WAVE 🌊"
	signText.TextColor3 = Color3.fromRGB(255, 255, 255)
	signText.TextStrokeTransparency = 0.25
	signText.Font = Enum.Font.FredokaOne
	signText.TextSize = 44
	signText.Parent = sign
	sign.Parent = wall
	wallModel.Parent = Workspace

	local hit = {}
	local sweepTime = Config.Events.WaveSweepTime
	local elapsed = 0
	local step = 0.1
	while elapsed < sweepTime do
		task.wait(step)
		elapsed += step
		local wallX = Util.Lerp(-210, 210, elapsed / sweepTime)
		wall.CFrame = CFrame.new(wallX, 13, -110)
		foam.CFrame = CFrame.new(wallX, 26, -110)
		sign.StudsOffset = Vector3.new(0, 20, 0)
		for player in pairs(participants) do
			if not hit[player] then
				local character = player.Character
				local hrp = character and character:FindFirstChild("HumanoidRootPart")
				if hrp and math.abs(hrp.Position.X - wallX) < 6 and not insideAnyBase(hrp.Position) then
					hit[player] = true
					ctx.Carry.DropAll(player, hrp.Position)
					hrp.AssemblyLinearVelocity = Vector3.new(46, 30, 0)
					ctx.Remotes.Event:FireClient(player, "Shake", 0.8)
					ctx.Remotes.Event:FireClient(player, "PlaySound", "WaveHit", 1)
					ctx.Remotes.Event:FireClient(player, "Notify", "🌊 The wave knocked your brainrots loose!", "Error")
				end
			end
		end
	end
	wallModel:Destroy()
	musicAll("Main")
	-- survivors: sheltered in a base, or still holding a brainrot
	for player in pairs(participants) do
		local profile = ctx.Data.Profiles[player]
		local character = player.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		if profile and hrp then
			if insideAnyBase(hrp.Position) or ctx.Carry.GetCount(player) > 0 then
				profile.Stats.WavesSurvived += 1
				ctx.Quests.Refresh(player)
			end
		end
	end
	bannerAll("🌈 The wave has passed!", "Survivors earned quest credit. The fields are restocking…", Color3.fromRGB(140, 255, 170), 3.5)
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
			walkTo(Vector3.new(0, 0, 96), 12, 25)
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
	rig.Size = Vector3.new(330, 1, 410)
	rig.CFrame = CFrame.new(0, 58, -110)

	task.spawn(function()
		task.wait(75)
		while true do
			runGoldRain()
			task.wait(math.random(Config.Events.GoldRainInterval[1], Config.Events.GoldRainInterval[2]))
		end
	end)
	task.spawn(function()
		task.wait(120)
		while true do
			runWave()
			task.wait(math.random(Config.Events.WaveInterval[1], Config.Events.WaveInterval[2]))
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
