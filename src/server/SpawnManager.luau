-- SpawnManager — keeps the three fields stocked with wandering wild brainrots, ready to buy.
-- Key responsibility: keeps all three fields stocked with wandering wild brainrots carrying a live Buy prompt.
-- SpawnManager.luau — keeps the three fields stocked with wild
-- brainrots. A wild brainrot simply APPEARS standing on the field,
-- already walking: it wanders its zone for a few seconds with a Buy
-- prompt on it, then wanders off (despawns) if nobody bought it.
-- Surface spawn, plain walking, flat feet — the wander never
-- bounces the model.
-- Dropped or rescued brainrots (death drops, bandit loot) re-enter
-- through the same registry: no despawn timer, same Buy prompt.
-- Rarity rolls per zone; shiny/golden mutations boosted during Gold Rain.

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Util = require(Shared:WaitForChild("Util"))

local SpawnManager = {}
local ctx
local WildSet = {}       -- [model] = state (see RegisterWild)
local CountByZone = {}

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

-- the body-centre height at which the model's feet rest exactly on
-- the field surface (FootDrop is stamped by the factory at build)
local function groundYFor(model)
	local body = model.PrimaryPart
	return 0.35 + (model:GetAttribute("FootDrop") or (body.Size.Y / 2 + 0.35)) + (model:GetAttribute("Hover") or 0)
end

--====================================================================--
-- Wild registry. opts: { Despawn = bool, GroundY = number }. Every
-- wild gets a Buy prompt, enabled from the moment it appears; its
-- price comes from the model's Price attribute (set at spawn, or
-- computed here for re-registered models that never had one).
--====================================================================--
function SpawnManager.RegisterWild(model, zi, opts)
	if WildSet[model] then
		return
	end
	opts = opts or {}
	local body = model.PrimaryPart
	local def = Config.BrainrotByName[model:GetAttribute("BrainrotName")]
	if not model:GetAttribute("Price") and def then
		model:SetAttribute("Price", Config.BuyPrice(def, model:GetAttribute("Mutation")))
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BuyPrompt"
	prompt.ActionText = "Buy"
	prompt.ObjectText = "$" .. Util.FormatInt(model:GetAttribute("Price") or 0)
	prompt.HoldDuration = 0.35
	prompt.MaxActivationDistance = 11
	prompt.RequiresLineOfSight = false
	prompt.Enabled = true -- buyable from the moment it appears
	prompt.Parent = body
	prompt.Triggered:Connect(function(player)
		ctx.Carry.TryBuy(player, model)
	end)

	local st = {
		Zone = zi,
		Target = randomPointInZone(zi),
		Phase = math.random() * 6,
		StateTime = 0,
		WanderTime = math.random() * (Config.WildWanderTime[2] - Config.WildWanderTime[1]) + Config.WildWanderTime[1],
		GroundY = opts.GroundY or groundYFor(model),
		Despawn = opts.Despawn or false,
		Prompt = prompt,
	}
	WildSet[model] = st
	CountByZone[zi] = (CountByZone[zi] or 0) + 1
	model:SetAttribute("Kind", "Wild")
	model:SetAttribute("HomeZone", zi)
end

function SpawnManager.Unregister(model)
	local st = WildSet[model]
	if st then
		CountByZone[st.Zone] = math.max(0, (CountByZone[st.Zone] or 1) - 1)
		WildSet[model] = nil
		if st.Prompt then
			st.Prompt:Destroy()
		end
	end
end

-- A buyer claimed this wild: stop its wander, strip the prompt, and
-- hand the model over. Fails only if the wild is already gone (bought
-- by someone else, or wandered off and despawned).
function SpawnManager.ClaimWild(model)
	local st = WildSet[model]
	if not st then
		return false
	end
	SpawnManager.Unregister(model)
	return true
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
	model:SetAttribute("Price", Config.BuyPrice(def, mutation))
	local body = model.PrimaryPart
	local point = randomPointInZone(zi)
	-- it appears standing on the surface, feet flat, and starts walking
	body.CFrame = CFrame.new(point.X, groundYFor(model), point.Z)
		* CFrame.Angles(0, math.random() * math.pi * 2, 0)
	model.Parent = ctx.World.WildFolder
	SpawnManager.RegisterWild(model, zi, { Despawn = true })
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
	-- wander mover: a plain walk at a CONSTANT height — no bounce, no
	-- tilt — with the factory's arm-swing walk cycle on top. A wild
	-- whose wander time runs out simply leaves (the model is removed).
	RunService.Heartbeat:Connect(function(dt)
		local t = os.clock()
		for model, st in pairs(WildSet) do
			local body = model.PrimaryPart
			if not body or not model.Parent then
				SpawnManager.Unregister(model)
			else
				st.StateTime += dt
				if st.Despawn and st.StateTime >= st.WanderTime then
					SpawnManager.Unregister(model)
					model:Destroy()
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
						body.CFrame = CFrame.lookAt(
							Vector3.new(nx, st.GroundY, nz),
							Vector3.new(nx + dx, st.GroundY, nz + dz))
						-- the walk cycle: swinging arms, steady head
						st.PoseAcc = (st.PoseAcc or 0) + dt
						if st.PoseAcc > 0.05 then
							st.PoseAcc = 0
							ctx.Factory.Pose(model, "Walk", t)
						end
					end
				end
			end
		end
	end)
end

return SpawnManager
