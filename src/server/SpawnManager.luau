-- SpawnManager.luau — keeps the three fields stocked with wild
-- brainrots. A round portal irises open in the ground, the brainrot
-- rises out of it, the portal closes; it wanders its zone for a few
-- seconds with a Buy prompt on it, then a portal reopens under it and
-- it sinks back if nobody bought it. Dropped or rescued brainrots
-- (death drops, bandit loot) re-enter as plain wilds: no portal, no
-- sink timer, but still bought through the same prompt.
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

local function groundYFor(model)
	local body = model.PrimaryPart
	return 0.35 + body.Size.Y / 2 + (model:GetAttribute("Hover") or 0)
end

--====================================================================--
-- Portal visual: a round hole in the ground — a dark pit disc ringed
-- in the zone's accent colour, with a glowing core, a point light and
-- rising sparkles. The portal visibly OPENS and CLOSES: its scale (st.PortalK,
-- 0 = shut, 1 = fully open) irises the ring/disc/core in and out.
-- Built per spawn and destroyed when the brainrot is bought or has
-- finished sinking.
--====================================================================--
local function portalPart(parent, name, size, cf, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Parent = parent
	return p
end

local function buildPortal(zi, point)
	local neon = Config.Zones[zi].NeonColor
	local portal = Instance.new("Model")
	portal.Name = "Portal"
	local ring = portalPart(portal, "Ring", Vector3.new(8.2, 0.22, 8.2), CFrame.new(point.X, 0.42, point.Z), neon, Enum.Material.Neon)
	ring.Shape = Enum.PartType.Cylinder
	local disc = portalPart(portal, "Disc", Vector3.new(7.2, 0.16, 7.2), CFrame.new(point.X, 0.5, point.Z), Color3.fromRGB(16, 14, 30), Enum.Material.Metal)
	disc.Shape = Enum.PartType.Cylinder
	local core = portalPart(portal, "Core", Vector3.new(5.6, 0.14, 5.6), CFrame.new(point.X, 0.56, point.Z), neon, Enum.Material.Neon)
	core.Shape = Enum.PartType.Cylinder
	local light = Instance.new("PointLight")
	light.Name = "PortalLight"
	light.Color = neon
	light.Range = 14
	light.Brightness = 2
	light.Parent = core
	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Name = "PortalSparkles"
	sparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparkles.Color = ColorSequence.new(neon)
	sparkles.Size = NumberSequence.new(0.45)
	sparkles.Rate = 26
	sparkles.Lifetime = NumberRange.new(0.6, 1.2)
	sparkles.Speed = NumberRange.new(3, 6)
	sparkles.SpreadAngle = Vector2.new(24, 24)
	sparkles.LightEmission = 0.8
	sparkles.Parent = core
	portal.Parent = ctx.World.WildFolder
	return portal, {
		Ring = ring, Disc = disc, Core = core, Light = light, Sparkles = sparkles,
		BaseSize = { Ring = ring.Size, Disc = disc.Size, Core = core.Size },
	}
end

-- Apply the portal's open scale: discs iris out from a point, the pit
-- stays dark, the light and sparkles fade in with the opening.
local function applyPortalScale(st)
	local parts = st.PortalParts
	if not parts then
		return
	end
	local k = math.max(st.PortalK or 0, 0.02)
	for _, key in ipairs({ "Ring", "Disc", "Core" }) do
		local base = parts.BaseSize[key]
		parts[key].Size = Vector3.new(base.X * k, base.Y, base.Z * k)
		parts[key].Transparency = (st.PortalK or 0) <= 0.01 and 1 or 0
	end
	parts.Light.Enabled = (st.PortalK or 0) > 0.05
	parts.Light.Brightness = 2 * (st.PortalK or 0)
	parts.Sparkles.Enabled = (st.PortalK or 0) > 0.4
end

-- Advance the portal toward its target scale (1 = open, 0 = closed);
-- returns the current scale.
local function updatePortal(st, dt)
	if not st.PortalParts then
		return 1
	end
	local target = st.PortalTarget or 1
	local k = st.PortalK or 0
	local step = dt / Config.PortalAnimTime
	if k < target then
		k = math.min(target, k + step)
	elseif k > target then
		k = math.max(target, k - step)
	end
	st.PortalK = k
	applyPortalScale(st)
	return k
end

local function destroyPortal(st)
	if st.Portal then
		st.Portal:Destroy()
		st.Portal = nil
		st.PortalParts = nil
	end
end

--====================================================================--
-- Wild registry. opts: { Portal = model, PortalParts = table,
-- Despawn = bool, GroundY = number }. Every wild gets a Buy prompt;
-- its price comes from the model's Price attribute (set at spawn, or
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
	prompt.Enabled = false -- the mover enables it once the wild is wandering
	prompt.Parent = body
	prompt.Triggered:Connect(function(player)
		ctx.Carry.TryBuy(player, model)
	end)

	local st = {
		Zone = zi,
		Target = randomPointInZone(zi),
		Phase = math.random() * 6,
		State = opts.Portal and "Rising" or "Wandering",
		StateTime = 0,
		RiseK = 0, SinkK = 0,
		PortalK = opts.Portal and 0 or 1, -- portal spawns start shut, then iris open
		PortalTarget = 1,
		WanderTime = math.random() * (Config.WildWanderTime[2] - Config.WildWanderTime[1]) + Config.WildWanderTime[1],
		GroundY = opts.GroundY or groundYFor(model),
		SpawnPoint = Vector3.new(body.Position.X, 0, body.Position.Z),
		Yaw = math.random() * math.pi * 2,
		Portal = opts.Portal,
		PortalParts = opts.PortalParts,
		Despawn = opts.Despawn or false,
		Prompt = prompt,
	}
	if opts.Portal then
		applyPortalScale(st)
	end
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
		destroyPortal(st)
		if st.Prompt then
			st.Prompt:Destroy()
		end
	end
end

-- A buyer claimed this wild: stop its lifecycle, strip the prompt and
-- portal, and hand the model over. Only wandering wilds can be bought.
function SpawnManager.ClaimWild(model)
	local st = WildSet[model]
	if not st or st.State ~= "Wandering" then
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
	local groundY = groundYFor(model)
	local sinkDepth = body.Size.Y + 1.4
	-- start sunk beneath the portal; the mover raises it
	body.CFrame = CFrame.new(point.X, groundY - sinkDepth, point.Z)
		* CFrame.Angles(0, math.random() * math.pi * 2, 0)
	model.Parent = ctx.World.WildFolder
	local portal, parts = buildPortal(zi, point)
	SpawnManager.RegisterWild(model, zi, {
		Portal = portal, PortalParts = parts, Despawn = true, GroundY = groundY,
	})
	-- a soft portal shimmer for anyone close enough to hear it
	for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
		local character = player.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		if hrp and (hrp.Position - point).Magnitude < 48 then
			ctx.Remotes.Event:FireClient(player, "PlaySound", "Magic", 0.9)
		end
	end
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
	-- lifecycle + wander mover. Portal choreography: the circle irises
	-- OPEN, the brainrot rises, the circle irises CLOSED; on timeout a
	-- fresh circle opens under the brainrot, it sinks, the circle closes.
	RunService.Heartbeat:Connect(function(dt)
		local t = os.clock()
		for model, st in pairs(WildSet) do
			local body = model.PrimaryPart
			if not body or not model.Parent then
				SpawnManager.Unregister(model)
			elseif st.State == "Rising" then
				local k = updatePortal(st, dt)
				if st.PortalParts and k >= 1 then
					-- the open core breathes while the brainrot emerges
					local pulse = 0.2 + 0.3 * math.abs(math.sin(t * 6 + st.Phase))
					st.PortalParts.Core.Transparency = pulse
				end
				if k >= 1 then
					st.RiseK = math.min(1, st.RiseK + dt / Config.PortalRiseTime)
					local sinkDepth = body.Size.Y + 1.4
					local y = st.GroundY - sinkDepth * (1 - st.RiseK)
					body.CFrame = CFrame.new(st.SpawnPoint.X, y, st.SpawnPoint.Z) * CFrame.Angles(0, st.Yaw, 0)
					if st.RiseK >= 1 then
						st.PortalTarget = 0 -- emerged: iris shut behind it
					end
				end
				if st.RiseK >= 1 and k <= 0.02 then
					destroyPortal(st)
					st.State = "Wandering"
					st.StateTime = 0
					if st.Prompt then
						st.Prompt.Enabled = true
					end
				end
			elseif st.State == "SinkOpen" then
				-- a fresh portal irises open under the standing brainrot
				if updatePortal(st, dt) >= 1 then
					st.State = "Sinking"
				end
			elseif st.State == "Sinking" then
				st.SinkK = math.min(1, st.SinkK + dt / Config.PortalRiseTime)
				local sinkDepth = body.Size.Y + 1.4
				local y = st.GroundY - sinkDepth * st.SinkK
				body.CFrame = CFrame.new(st.SpawnPoint.X, y, st.SpawnPoint.Z) * CFrame.Angles(0, st.Yaw, 0)
				if st.SinkK >= 1 then
					st.State = "SinkClose"
					st.PortalTarget = 0
				end
			elseif st.State == "SinkClose" then
				if updatePortal(st, dt) <= 0.02 then
					SpawnManager.Unregister(model)
					model:Destroy()
				end
			else -- Wandering
				st.StateTime += dt
				if st.Despawn and st.StateTime >= st.WanderTime then
					st.State = "SinkOpen"
					st.SinkK = 0
					st.SpawnPoint = Vector3.new(body.Position.X, 0, body.Position.Z)
					st.Yaw = math.random() * math.pi * 2
					if st.Prompt then
						st.Prompt.Enabled = false
					end
					-- the portal reopens where the brainrot stands
					if st.Portal then
						st.Portal:Destroy()
					end
					local portal, parts = buildPortal(st.Zone, st.SpawnPoint)
					st.Portal, st.PortalParts = portal, parts
					st.PortalK = 0
					st.PortalTarget = 1
					applyPortalScale(st)
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
						local bobY = st.GroundY + math.abs(math.sin(t * 3.2 + st.Phase)) * 0.35
						body.CFrame = CFrame.lookAt(Vector3.new(nx, bobY, nz), Vector3.new(nx + dx, bobY, nz + dz))
							* CFrame.Angles(math.sin(t * 3.2 + st.Phase) * 0.03, 0, math.sin(t * 7 + st.Phase) * 0.05)
						-- the walk cycle: swinging arms, bobbling head
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
