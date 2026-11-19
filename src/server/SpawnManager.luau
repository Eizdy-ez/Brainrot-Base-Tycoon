-- SpawnManager.luau — keeps the three fields stocked with wandering wild
-- brainrots: rarity rolls per zone, shiny/golden mutations (boosted during
-- Gold Rain), and a light wander mover for every wild model.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Util = require(Shared:WaitForChild("Util"))

local SpawnManager = {}
local ctx
local WildSet = {}       -- [model] = { Zone = n, Target = Vector3, Phase = number }
local CountByZone = {}
local TouchWired = {}    -- [model] = true once its Touched is connected

local function randomPointInZone(zi)
	local zone = Config.Zones[zi]
	local x = zone.Center.X + (math.random() * 2 - 1) * (zone.Size.X / 2 - 6)
	local z = zone.Center.Z + (math.random() * 2 - 1) * (zone.Size.Y / 2 - 5)
	return Vector3.new(x, 0, z)
end

function SpawnManager.ZoneFromPosition(pos)
	for zi, zone in ipairs(Config.Zones) do
		if math.abs(pos.X - zone.Center.X) < zone.Size.X / 2 and math.abs(pos.Z - zone.Center.Z) < zone.Size.Y / 2 then
			return zi
		end
	end
	return 1
end

function SpawnManager.RegisterWild(model, zi)
	if WildSet[model] then
		return
	end
	WildSet[model] = { Zone = zi, Target = randomPointInZone(zi), Phase = math.random() * 6 }
	CountByZone[zi] = (CountByZone[zi] or 0) + 1
	model:SetAttribute("Kind", "Wild")
	model:SetAttribute("HomeZone", zi)
	if not TouchWired[model] then
		TouchWired[model] = true
		model.PrimaryPart.Touched:Connect(function(hit)
			local player = Players:GetPlayerFromCharacter(hit and hit.Parent)
			if player then
				ctx.Carry.TryPickup(player, model)
			end
		end)
	end
end

function SpawnManager.Unregister(model)
	local st = WildSet[model]
	if st then
		CountByZone[st.Zone] = math.max(0, (CountByZone[st.Zone] or 1) - 1)
		WildSet[model] = nil
	end
end

local function rollMutation()
	local goldenChance = Config.Mutations.Golden.Chance
	local shinyChance = Config.Mutations.Shiny.Chance
	if ctx and ctx.GoldRainActive then
		goldenChance *= Config.Events.GoldRainMutationBoost
		shinyChance *= 2
	end
	local roll = math.random()
	if roll < goldenChance then
		return "Golden"
	elseif roll < goldenChance + shinyChance then
		return "Shiny"
	end
	return "None"
end

function SpawnManager.SpawnWild(zi)
	local zone = Config.Zones[zi]
	local rarity = Util.WeightedIndex(zone.Weights)
	local candidates = {}
	for _, def in ipairs(Config.Brainrots) do
		if def.Rarity == rarity then
			candidates[#candidates + 1] = def
		end
	end
	local def = candidates[math.random(#candidates)]
	local mutation = rollMutation()
	local model = ctx.Factory.Build(def, mutation)
	local body = model.PrimaryPart
	local point = randomPointInZone(zi)
	model.PrimaryPart.CFrame = CFrame.new(point.X, 0.35 + body.Size.Y / 2, point.Z)
		* CFrame.Angles(0, math.random() * math.pi * 2, 0)
	model.Parent = ctx.World.WildFolder
	SpawnManager.RegisterWild(model, zi)
	return model
end

function SpawnManager.Start(c)
	ctx = c
	-- initial stock, then a steady trickle
	for zi, zone in ipairs(Config.Zones) do
		for _ = 1, math.floor(zone.SpawnCap * 0.6) do
			SpawnManager.SpawnWild(zi)
		end
	end
	task.spawn(function()
		while true do
			task.wait(Config.SpawnInterval)
			for zi, zone in ipairs(Config.Zones) do
				if (CountByZone[zi] or 0) < zone.SpawnCap then
					SpawnManager.SpawnWild(zi)
				end
			end
		end
	end)
	-- wander mover
	RunService.Heartbeat:Connect(function(dt)
		local t = os.clock()
		for model, st in pairs(WildSet) do
			local body = model.PrimaryPart
			if not body or not model.Parent then
				SpawnManager.Unregister(model)
			else
				local pos = body.Position
				local target = st.Target
				local dx, dz = target.X - pos.X, target.Z - pos.Z
				local dist = math.sqrt(dx * dx + dz * dz)
				if dist < 2 then
					st.Target = randomPointInZone(st.Zone)
				else
					local speed = 2.6
					local step = math.min(dist, speed * dt)
					local nx, nz = pos.X + dx / dist * step, pos.Z + dz / dist * step
					local bobY = 0.35 + body.Size.Y / 2 + math.abs(math.sin(t * 3.2 + st.Phase)) * 0.35
					body.CFrame = CFrame.lookAt(Vector3.new(nx, bobY, nz), Vector3.new(nx + dx, bobY, nz + dz))
				end
			end
		end
	end)
end

return SpawnManager
