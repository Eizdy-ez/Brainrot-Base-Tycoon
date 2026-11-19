-- WorldBuilder.luau — constructs the whole island from code at server start:
-- spawn plaza, three fenced brainrot fields with gates, eight tycoon base
-- plots (display pads, collect/lock/fusion/rebirth pads, upgrade buttons),
-- big readable signs, a leaderboard board, and decorations. Everything is
-- authored here as data + loops; no hand-placed Studio content.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Util = require(Shared:WaitForChild("Util"))

local WorldBuilder = {}

local function mkPart(parent, name, size, cf, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.Parent = parent
	return p
end

local function board(parent, name, size, cf, title, body, titleColor, bgColor)
	local p = mkPart(parent, name, size, cf, bgColor or Color3.fromRGB(38, 40, 52), Enum.Material.SmoothPlastic)
	p.CanCollide = false
	local gui = Instance.new("SurfaceGui")
	gui.Name = "BoardGui"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 42
	gui.Parent = p
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, 0, body and 0.42 or 1, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = title
	titleLabel.TextColor3 = titleColor or Color3.fromRGB(255, 255, 255)
	titleLabel.Font = Enum.Font.FredokaOne
	titleLabel.TextScaled = true
	titleLabel.Parent = gui
	local bodyLabel = nil
	if body then
		bodyLabel = Instance.new("TextLabel")
		bodyLabel.Name = "Body"
		bodyLabel.Position = UDim2.new(0, 0, 0.42, 0)
		bodyLabel.Size = UDim2.new(1, 0, 0.58, 0)
		bodyLabel.BackgroundTransparency = 1
		bodyLabel.Text = body
		bodyLabel.TextColor3 = Color3.fromRGB(225, 228, 235)
		bodyLabel.Font = Enum.Font.FredokaOne
		bodyLabel.TextScaled = true
		bodyLabel.TextWrapped = true
		bodyLabel.Parent = gui
	end
	return p, titleLabel, bodyLabel
end

local function padLabel(partInst, text, color, offsetY)
	local gui = Instance.new("BillboardGui")
	gui.Name = "PadLabel"
	gui.Size = UDim2.fromOffset(190, 56)
	gui.StudsOffset = Vector3.new(0, offsetY or 3.2, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 70
	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.3
	label.Font = Enum.Font.FredokaOne
	label.TextSize = 17
	label.TextWrapped = true
	label.Parent = gui
	gui.Parent = partInst
	return label
end

local BASE_COLORS = {
	Color3.fromRGB(255, 99, 99), Color3.fromRGB(255, 166, 66), Color3.fromRGB(255, 224, 84),
	Color3.fromRGB(96, 214, 110), Color3.fromRGB(74, 196, 224), Color3.fromRGB(96, 130, 255),
	Color3.fromRGB(196, 110, 255), Color3.fromRGB(255, 110, 190),
}

local function buildTree(parent, x, z, s)
	local g = Instance.new("Model")
	g.Name = "Tree"
	g.Parent = parent
	mkPart(g, "Trunk", Vector3.new(1.2 * s, 5 * s, 1.2 * s), CFrame.new(x, 2.5 * s, z), Color3.fromRGB(122, 84, 48))
	local leaf1 = mkPart(g, "Leaves", Vector3.new(5.4 * s, 5 * s, 5.4 * s), CFrame.new(x, 6.6 * s, z), Color3.fromRGB(66, 168, 72))
	leaf1.Shape = Enum.PartType.Ball
	leaf1.CanCollide = false
	local leaf2 = mkPart(g, "LeavesTop", Vector3.new(3.6 * s, 3.4 * s, 3.6 * s), CFrame.new(x + 0.8 * s, 9 * s, z), Color3.fromRGB(84, 190, 84))
	leaf2.Shape = Enum.PartType.Ball
	leaf2.CanCollide = false
end

local function buildBase(parent, slot, centerX, centerZ)
	local dir = centerX > 0 and 1 or -1 -- pads grow away from the island centre
	local color = BASE_COLORS[slot]
	local model = Instance.new("Model")
	model.Name = "Base" .. slot
	model.Parent = parent

	local function L(ox, oz) -- local offset -> world position (dir flips x)
		return Vector3.new(centerX + dir * ox, 0, centerZ + oz)
	end

	-- Futuristic shell (concept B): a dark glass floor over a metal slab,
	-- ringed by full walls on all four sides — dark metal panels below,
	-- glass above — crowned by one slim, dim purple neon line. The front
	-- wall (facing the island centre) holds the gate; its door is driven
	-- by the base lock (see BaseManager.UpdateGate).
	local METAL_DARK = Color3.fromRGB(36, 38, 52)
	local GLASS_TINT = Color3.fromRGB(148, 163, 205)
	local NEON_PURPLE = Color3.fromRGB(176, 96, 255)
	local NEON_MAGENTA = Color3.fromRGB(238, 92, 224)

	mkPart(model, "Trim", Vector3.new(47.5, 0.6, 47.5), CFrame.new(centerX, 0.2, centerZ), METAL_DARK, Enum.Material.Metal)
	local floor = mkPart(model, "Floor", Vector3.new(46, 0.5, 46), CFrame.new(centerX, 0.75, centerZ), Color3.fromRGB(24, 22, 38), Enum.Material.Glass)
	floor.Transparency = 0.12

	local base = {
		Slot = slot, Center = Vector3.new(centerX, 1, centerZ), Model = model,
		Pending = 0, Owner = nil, Locked = false, LockUntil = 0, LockReadyAt = 0,
		Pads = {}, UpgradePads = {}, LightStrips = {},
	}

	-- running-light grid set into the floor: neon strips in a 5x5 lattice.
	-- BaseManager pulses them in sequence so a wave of light travels
	-- across the glass instead of the grid sitting static.
	local gridOffsets = { -18.4, -9.2, 0, 9.2, 18.4 }
	for i, go in ipairs(gridOffsets) do
		local across = mkPart(model, "LightStripX" .. i, Vector3.new(45, 0.14, 0.42), CFrame.new(centerX, 1.06, centerZ + go), i % 2 == 0 and NEON_MAGENTA or NEON_PURPLE, Enum.Material.Neon)
		across.CanCollide = false
		across.CanQuery = false
		across.CanTouch = false
		base.LightStrips[#base.LightStrips + 1] = { Part = across, Phase = i }
		local alongPos = L(go, 0)
		local along = mkPart(model, "LightStripZ" .. i, Vector3.new(0.42, 0.14, 45), CFrame.new(alongPos.X, 1.06, centerZ), i % 2 == 0 and NEON_PURPLE or NEON_MAGENTA, Enum.Material.Neon)
		along.CanCollide = false
		along.CanQuery = false
		along.CanTouch = false
		base.LightStrips[#base.LightStrips + 1] = { Part = along, Phase = i + 0.5 }
	end

	-- one straight wall run in local plot coords: metal band (y 1..4.2),
	-- glass band (up to y 9.4), top rail, and the thin neon crown line.
	-- glassBottom > 4.2 + noLower builds a lintel (no metal band) for the
	-- stretch over the gate opening.
	local WALL_T = 0.8
	local function wallRun(ox1, oz1, ox2, oz2, glassBottom, noLower)
		local mid = L((ox1 + ox2) / 2, (oz1 + oz2) / 2)
		local len = math.abs(ox2 - ox1) + math.abs(oz2 - oz1) + WALL_T
		local alongZ = ox1 == ox2
		local function seg(name, h, cy, thick, segColor, material, transparency)
			local size = alongZ and Vector3.new(thick, h, len) or Vector3.new(len, h, thick)
			local p = mkPart(model, name, size, CFrame.new(mid.X, cy, mid.Z), segColor, material)
			if transparency then
				p.Transparency = transparency
			end
			return p
		end
		if not noLower then
			seg("WallMetal", 3.2, 2.6, WALL_T, METAL_DARK, Enum.Material.Metal)
		end
		local gb = glassBottom or 4.2
		seg("WallGlass", 9.4 - gb, (9.4 + gb) / 2, WALL_T, GLASS_TINT, Enum.Material.Glass, 0.35)
		seg("WallTopRail", 0.55, 9.68, WALL_T + 0.35, METAL_DARK, Enum.Material.Metal)
		local neon = seg("WallNeon", 0.3, 10.1, 0.34, NEON_PURPLE, Enum.Material.Neon)
		neon.CanCollide = false
		neon.Transparency = 0.25
	end

	-- back + side walls run unbroken; the front wall leaves a 9-wide gate
	-- opening at its centre, bridged by a glass lintel.
	wallRun(22.6, -23, 22.6, 23)
	wallRun(-23, -22.6, 23, -22.6)
	wallRun(-23, 22.6, 23, 22.6)
	wallRun(-22.6, -23, -22.6, -4.5)
	wallRun(-22.6, 4.5, -22.6, 23)
	wallRun(-22.6, -4.5, -22.6, 4.5, 7.2, true)

	-- slim frame posts: corners, wall midpoints and the gate jambs
	local postAt = { -22.6, -11.3, 11.3, 22.6 }
	for _, oz in ipairs(postAt) do
		local p = L(-22.6, oz)
		mkPart(model, "FramePost", Vector3.new(1.1, 8.4, 1.1), CFrame.new(p.X, 5.2, p.Z), METAL_DARK, Enum.Material.Metal)
		local q = L(22.6, oz)
		mkPart(model, "FramePost", Vector3.new(1.1, 8.4, 1.1), CFrame.new(q.X, 5.2, q.Z), METAL_DARK, Enum.Material.Metal)
	end
	for _, ox in ipairs({ -22.6, 0, 22.6 }) do
		for _, oz in ipairs({ -22.6, 22.6 }) do
			local p = L(ox, oz)
			mkPart(model, "FramePost", Vector3.new(1.1, 8.4, 1.1), CFrame.new(p.X, 5.2, p.Z), METAL_DARK, Enum.Material.Metal)
		end
	end
	for _, oz in ipairs({ -4.9, 4.9 }) do
		local p = L(-22.6, oz)
		mkPart(model, "GateJamb", Vector3.new(1.1, 6.2, 1.1), CFrame.new(p.X, 4.1, p.Z), METAL_DARK, Enum.Material.Metal)
	end

	-- the gate door itself: tinted glass that turns solid while the base
	-- is locked (BaseManager.UpdateGate drives CanCollide/Transparency;
	-- it starts open). The owner always passes — Effects clears the
	-- door's collision on the owner's own client only.
	local gatePos = L(-22.6, 0)
	local door = mkPart(model, "GateDoor", Vector3.new(0.55, 6.2, 9), CFrame.new(gatePos.X, 4.1, gatePos.Z), Color3.fromRGB(96, 74, 158), Enum.Material.Glass)
	door.Transparency = 0.85
	door.CanCollide = false
	base.GateDoor = door

	-- 12 display pedestals hugging the walls, as in the concept: six
	-- along the back wall, three along each side wall, leaving the
	-- glowing floor open in the middle.
	local padSpots = {}
	for i = 0, 5 do
		padSpots[#padSpots + 1] = { 18.6, -15 + i * 6 }
	end
	for i = 0, 2 do
		padSpots[#padSpots + 1] = { 2 + i * 6, -18.6 }
	end
	for i = 0, 2 do
		padSpots[#padSpots + 1] = { 2 + i * 6, 18.6 }
	end
	for padIndex, spot in ipairs(padSpots) do
		local pos = L(spot[1], spot[2])
		local pedestal = mkPart(model, "Pad" .. padIndex, Vector3.new(3.8, 0.9, 3.8), CFrame.new(pos.X, 1.45, pos.Z), Color3.fromRGB(52, 54, 72), Enum.Material.Metal)
		local top = mkPart(model, "PadTop" .. padIndex, Vector3.new(3.9, 0.22, 3.9), CFrame.new(pos.X, 1.95, pos.Z), color, Enum.Material.Neon)
		top.CanCollide = false
		base.Pads[padIndex] = { Part = top, Pedestal = pedestal, Anchor = Vector3.new(pos.X, 2.05, pos.Z), Model = nil }
	end

	-- collect pad (glowing cylinder the owner stands on to claim cash)
	local cPos = L(-7, -9)
	local collect = mkPart(model, "CollectPad", Vector3.new(6.4, 0.5, 6.4), CFrame.new(cPos.X, 1.25, cPos.Z), Color3.fromRGB(64, 220, 110), Enum.Material.Neon)
	collect.Shape = Enum.PartType.Cylinder
	base.CollectPad = collect
	base.CollectLabel = padLabel(collect, "COLLECT\n$0", Color3.fromRGB(190, 255, 205), 3.6)

	-- lock pad
	local lPos = L(-7, 9)
	local lock = mkPart(model, "LockPad", Vector3.new(5, 0.5, 5), CFrame.new(lPos.X, 1.25, lPos.Z), Color3.fromRGB(90, 160, 255), Enum.Material.SmoothPlastic)
	base.LockPad = lock
	base.LockLabel = padLabel(lock, "🔓 LOCK BASE", Color3.fromRGB(200, 225, 255), 3.4)

	-- fusion + rebirth pads
	local fPos = L(-15, -9)
	local fusion = mkPart(model, "FusionPad", Vector3.new(5.4, 0.5, 5.4), CFrame.new(fPos.X, 1.25, fPos.Z), Color3.fromRGB(190, 100, 255), Enum.Material.Neon)
	base.FusionPad = fusion
	padLabel(fusion, "🧬 FUSION", Color3.fromRGB(235, 205, 255), 3.4)
	local rPos = L(-15, 9)
	local rebirth = mkPart(model, "RebirthPad", Vector3.new(5.4, 0.5, 5.4), CFrame.new(rPos.X, 1.25, rPos.Z), Color3.fromRGB(255, 120, 160), Enum.Material.Neon)
	base.RebirthPad = rebirth
	padLabel(rebirth, "🌟 REBIRTH", Color3.fromRGB(255, 205, 225), 3.4)

	-- four step-on upgrade buttons along the front edge
	local upgradeDefs = {
		{ Key = "Pads", Text = "+2 PADS" },
		{ Key = "Speed", Text = "+SPEED" },
		{ Key = "Carry", Text = "+CARRY" },
		{ Key = "Luck", Text = "+LUCK" },
	}
	for i, udef in ipairs(upgradeDefs) do
		local pos = L(-19.5, -16.5 + (i - 1) * 11)
		local btn = mkPart(model, "Upgrade_" .. udef.Key, Vector3.new(4.6, 0.6, 4.6), CFrame.new(pos.X, 1.3, pos.Z), Color3.fromRGB(255, 196, 66), Enum.Material.SmoothPlastic)
		local label = padLabel(btn, udef.Text, Color3.fromRGB(255, 240, 190), 3.6)
		base.UpgradePads[udef.Key] = { Part = btn, Label = label }
	end

	-- owner sign as a header above the gate, facing the island centre
	local signPos = L(-22.6, 0)
	local _, signTitle = board(model, "Sign", Vector3.new(0.8, 3.6, 13),
		CFrame.lookAt(Vector3.new(signPos.X, 11.6, signPos.Z), Vector3.new(0, 11.6, centerZ)),
		"EMPTY BASE", nil, color, Color3.fromRGB(40, 42, 56))
	base.SignLabel = signTitle

	-- two lamps just inside the front corners
	for _, lz in ipairs({ -18, 18 }) do
		local pos = L(-20, lz)
		mkPart(model, "LampPost", Vector3.new(0.5, 5.5, 0.5), CFrame.new(pos.X, 3.7, pos.Z), Color3.fromRGB(60, 60, 70))
		local bulb = mkPart(model, "LampBulb", Vector3.new(1.1, 1.1, 1.1), CFrame.new(pos.X, 6.8, pos.Z), Color3.fromRGB(226, 196, 255), Enum.Material.Neon)
		bulb.Shape = Enum.PartType.Ball
		bulb.CanCollide = false
	end

	return base
end

function WorldBuilder.Build()
	local world = { Bases = {}, Zones = {} }
	local root = Instance.new("Folder")
	root.Name = "BrainrotWorld"
	root.Parent = Workspace

	-- ocean + island
	local water = mkPart(root, "Water", Vector3.new(1600, 2, 1600), CFrame.new(0, -4.2, -110), Color3.fromRGB(52, 130, 210), Enum.Material.SmoothPlastic)
	water.CanCollide = false
	water.Transparency = 0.25
	mkPart(root, "Sand", Vector3.new(356, 2, 436), CFrame.new(0, -1.6, -110), Color3.fromRGB(238, 220, 168))
	mkPart(root, "Grass", Vector3.new(340, 2, 420), CFrame.new(0, -1, -110), Color3.fromRGB(112, 200, 96))

	-- central path (plaza -> zone 3) and cross paths to the base rows
	mkPart(root, "PathMain", Vector3.new(12, 0.3, 380), CFrame.new(0, 0.06, -80), Color3.fromRGB(226, 204, 160))
	for _, z in ipairs({ 30, -64, -148, -232 }) do
		mkPart(root, "PathCross", Vector3.new(220, 0.3, 10), CFrame.new(0, 0.06, z), Color3.fromRGB(226, 204, 160))
	end

	-- spawn plaza
	local plaza = mkPart(root, "Plaza", Vector3.new(64, 0.5, 64), CFrame.new(0, 0.1, 62), Color3.fromRGB(238, 232, 220))
	plaza.Shape = Enum.PartType.Cylinder
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.CFrame = CFrame.new(0, 0.8, 62) * CFrame.Angles(0, math.rad(180), 0)
	spawn.Color = Color3.fromRGB(90, 200, 255)
	spawn.Material = Enum.Material.Neon
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Parent = root
	world.SpawnCFrame = spawn.CFrame

	-- welcome arch over the path leaving the plaza
	mkPart(root, "ArchPostL", Vector3.new(2, 15, 2), CFrame.new(-8, 7.5, 34), Color3.fromRGB(255, 170, 60))
	mkPart(root, "ArchPostR", Vector3.new(2, 15, 2), CFrame.new(8, 7.5, 34), Color3.fromRGB(255, 170, 60))
	board(root, "WelcomeSign", Vector3.new(24, 6.5, 1.2), CFrame.new(0, 16.5, 34) * CFrame.Angles(0, math.rad(180), 0),
		"🧠 BRAINROT BASE TYCOON", "Catch brainrots • Fill your base • Get RICH!", Color3.fromRGB(255, 214, 90), Color3.fromRGB(46, 44, 66))

	-- rarity guide board (left of plaza) and leaderboard board (right)
	local rarityLines = {}
	for i = #Config.Rarities, 1, -1 do
		local r = Config.Rarities[i]
		rarityLines[#rarityLines + 1] = r.Name:upper()
	end
	board(root, "RarityBoard", Vector3.new(17, 10, 1), CFrame.new(-24, 5.5, 88) * CFrame.Angles(0, math.rad(160), 0),
		"⭐ RARITY ⭐", "MYTHIC > LEGENDARY > EPIC > RARE > COMMON\nShiny x2  •  Golden x5", Color3.fromRGB(255, 120, 190), Color3.fromRGB(40, 42, 56))
	local _, _, lbBody = board(root, "Leaderboard", Vector3.new(17, 10, 1), CFrame.new(24, 5.5, 88) * CFrame.Angles(0, math.rad(-160), 0),
		"🏆 TOP TYCOONS", "…", Color3.fromRGB(255, 214, 90), Color3.fromRGB(40, 42, 56))
	world.LeaderboardLabel = lbBody

	-- decorative shop stand by the plaza
	local stand = Instance.new("Model")
	stand.Name = "ShopStand"
	stand.Parent = root
	mkPart(stand, "Counter", Vector3.new(10, 3, 4), CFrame.new(-30, 1.5, 52), Color3.fromRGB(170, 110, 60))
	mkPart(stand, "Roof", Vector3.new(12, 0.6, 6), CFrame.new(-30, 6.4, 52) * CFrame.Angles(math.rad(8), 0, 0), Color3.fromRGB(255, 96, 96))
	mkPart(stand, "PostL", Vector3.new(0.6, 6, 0.6), CFrame.new(-35, 3, 52), Color3.fromRGB(120, 80, 44))
	mkPart(stand, "PostR", Vector3.new(0.6, 6, 0.6), CFrame.new(-25, 3, 52), Color3.fromRGB(120, 80, 44))
	board(stand, "ShopSign", Vector3.new(11, 2.6, 0.6), CFrame.new(-30, 5, 49.6) * CFrame.Angles(0, math.rad(180), 0),
		"🛒 SHOP — press SHOP button!", nil, Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 96, 96))

	-- zone fields, fences, gates
	for zi, zone in ipairs(Config.Zones) do
		local zc = zone.Center
		local field = Instance.new("Model")
		field.Name = "Zone" .. zi
		field.Parent = root
		mkPart(field, "Ground", Vector3.new(zone.Size.X, 0.6, zone.Size.Y), CFrame.new(zc.X, 0.05, zc.Z), zone.GroundColor)
		mkPart(field, "InnerGlow", Vector3.new(zone.Size.X - 10, 0.2, zone.Size.Y - 10), CFrame.new(zc.X, 0.3, zc.Z), zone.GroundColor:Lerp(Color3.new(1, 1, 1), 0.16))
		-- spawn pads (visual circles)
		for i = 1, 8 do
			local px = zc.X + ((i * 37) % 90) - 45
			local pz = zc.Z + ((i * 23) % 36) - 18
			local pad = mkPart(field, "SpawnPad", Vector3.new(5, 0.25, 5), CFrame.new(px, 0.42, pz), Color3.fromRGB(255, 255, 255), Enum.Material.Neon)
			pad.Shape = Enum.PartType.Cylinder
			pad.Transparency = 0.45
			pad.CanCollide = false
		end
		-- perimeter fence with a gap on the path (x in [-7,7]) on both z sides
		local fx, fz = zone.Size.X / 2, zone.Size.Y / 2
		local fenceColor = Color3.fromRGB(120, 86, 50)
		for _, sideZ in ipairs({ zc.Z - fz, zc.Z + fz }) do
			for x = -fx, fx, 10 do
				if math.abs(x) > 8 then
					mkPart(field, "FencePost", Vector3.new(0.7, 2.6, 0.7), CFrame.new(zc.X + x, 1.3, sideZ), fenceColor)
				end
			end
			mkPart(field, "FenceRailL", Vector3.new(fx - 8, 0.5, 0.5), CFrame.new(zc.X - (fx + 8) / 2 - 0, 1.9, sideZ), fenceColor)
			mkPart(field, "FenceRailR", Vector3.new(fx - 8, 0.5, 0.5), CFrame.new(zc.X + (fx + 8) / 2, 1.9, sideZ), fenceColor)
		end
		for _, sideX in ipairs({ zc.X - fx, zc.X + fx }) do
			for z = -fz, fz, 10 do
				mkPart(field, "FencePost", Vector3.new(0.7, 2.6, 0.7), CFrame.new(sideX, 1.3, zc.Z + z), fenceColor)
			end
			mkPart(field, "FenceRail", Vector3.new(0.5, 0.5, zone.Size.Y), CFrame.new(sideX, 1.9, zc.Z), fenceColor)
		end
		world.Zones[zi] = { Def = zone, Model = field }
	end

	-- gates between zones (zone 2 gate at z=-106, zone 3 gate at z=-190)
	world.Gates = {}
	for zi = 2, 3 do
		local zone = Config.Zones[zi]
		local gateZ = zone.Center.Z + zone.Size.Y / 2 + 14
		local gate = Instance.new("Model")
		gate.Name = "Gate" .. zi
		gate.Parent = root
		mkPart(gate, "PostL", Vector3.new(2.2, 13, 2.2), CFrame.new(-8, 6.5, gateZ), Color3.fromRGB(70, 70, 84))
		mkPart(gate, "PostR", Vector3.new(2.2, 13, 2.2), CFrame.new(8, 6.5, gateZ), Color3.fromRGB(70, 70, 84))
		board(gate, "GateSign", Vector3.new(21, 5.5, 1), CFrame.new(0, 14.5, gateZ) * CFrame.Angles(0, math.rad(180), 0),
			"🔒 " .. zone.Name:upper(), "Unlock for $" .. Util.FormatInt(zone.Price), Color3.fromRGB(255, 214, 90), Color3.fromRGB(46, 44, 66))
		local wall = mkPart(gate, "Barrier", Vector3.new(124, 9, 1), CFrame.new(0, 4.5, gateZ), Color3.fromRGB(120, 200, 255), Enum.Material.ForceField)
		wall.Transparency = 0.45
		wall.CanCollide = false
		local pad = mkPart(gate, "GatePad", Vector3.new(7, 0.5, 7), CFrame.new(0, 0.35, gateZ + 7), Color3.fromRGB(255, 196, 66), Enum.Material.Neon)
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "UnlockPrompt"
		prompt.ActionText = "Unlock " .. zone.Name
		prompt.ObjectText = "$" .. Util.FormatInt(zone.Price)
		prompt.HoldDuration = 0.6
		prompt.MaxActivationDistance = 12
		prompt.Parent = pad
		world.Gates[zi] = { Pad = pad, Prompt = prompt, Barrier = wall, Z = gateZ }
	end

	-- rarity arch at the first field entrance: five gem pillars
	local archZ = -28
	for i, rarity in ipairs(Config.Rarities) do
		local x = (i - 3) * 7
		mkPart(root, "GemPost", Vector3.new(1.4, 6 + i * 0.7, 1.4), CFrame.new(x, (6 + i * 0.7) / 2, archZ), Color3.fromRGB(70, 70, 84))
		local gem = mkPart(root, "Gem", Vector3.new(2.2, 2.2, 2.2), CFrame.new(x, 7 + i * 0.7, archZ), rarity.Color, Enum.Material.Neon)
		gem.Shape = Enum.PartType.Ball
		gem.CanCollide = false
	end
	board(root, "FieldsSign", Vector3.new(30, 5, 1), CFrame.new(0, 13.5, archZ) * CFrame.Angles(0, math.rad(180), 0),
		"🌈 THE BRAINROT FIELDS", "Touch a brainrot to catch it — carry it home!", Color3.fromRGB(140, 255, 170), Color3.fromRGB(46, 44, 66))

	-- eight bases: two columns of four
	local slot = 0
	for _, x in ipairs({ -128, 128 }) do
		for _, z in ipairs({ 30, -64, -148, -232 }) do
			slot += 1
			world.Bases[slot] = buildBase(root, slot, x, z)
		end
	end

	-- decorations: trees, rocks, flowers, clouds, path lamps
	local rng = Random.new(20261119)
	for i = 1, 16 do
		local x = rng:NextNumber(-160, 160)
		local z = rng:NextNumber(-310, 90)
		if math.abs(x) > 70 and math.abs(x) < 100 then
			buildTree(root, x, z, rng:NextNumber(0.8, 1.4))
		end
	end
	for i = 1, 9 do
		local rock = mkPart(root, "Rock", Vector3.new(rng:NextNumber(2, 4.5), rng:NextNumber(1.2, 2.4), rng:NextNumber(2, 4)),
			CFrame.new(rng:NextNumber(-165, 165), 0.6, rng:NextNumber(-315, 95)) * CFrame.Angles(0, rng:NextNumber(0, 3), 0),
			Color3.fromRGB(148, 150, 158))
		rock.CanCollide = false
	end
	for i = 1, 46 do
		local flower = mkPart(root, "Flower", Vector3.new(0.55, 0.55, 0.55),
			CFrame.new(rng:NextNumber(-165, 165), 0.35, rng:NextNumber(-315, 95)),
			Color3.fromHSV(rng:NextNumber(), 0.65, 1), Enum.Material.Neon)
		flower.Shape = Enum.PartType.Ball
		flower.CanCollide = false
	end
	for i = 1, 7 do
		local cx, cz = rng:NextNumber(-220, 220), rng:NextNumber(-340, 60)
		local cy = rng:NextNumber(58, 84)
		for j = 1, 3 do
			local cloud = mkPart(root, "Cloud", Vector3.new(rng:NextNumber(16, 30), 3.2, rng:NextNumber(8, 14)),
				CFrame.new(cx + (j - 2) * 11, cy + rng:NextNumber(-1, 1), cz), Color3.fromRGB(252, 252, 255))
			cloud.CanCollide = false
			cloud.CanQuery = false
			cloud.CanTouch = false
		end
	end
	for z = 20, -260, -40 do
		for _, x in ipairs({ -8.5, 8.5 }) do
			mkPart(root, "PathLamp", Vector3.new(0.45, 5, 0.45), CFrame.new(x, 2.5, z), Color3.fromRGB(60, 60, 70))
			local bulb = mkPart(root, "PathLampBulb", Vector3.new(1, 1, 1), CFrame.new(x, 5.4, z), Color3.fromRGB(255, 240, 180), Enum.Material.Neon)
			bulb.Shape = Enum.PartType.Ball
			bulb.CanCollide = false
		end
	end

	-- gold-rain emitter rig (toggled by the event manager)
	local rainRig = mkPart(root, "GoldRainRig", Vector3.new(10, 1, 10), CFrame.new(0, 60, -130), Color3.fromRGB(255, 255, 255))
	rainRig.Transparency = 1
	rainRig.CanCollide = false
	rainRig.CanQuery = false
	rainRig.CanTouch = false
	local rain = Instance.new("ParticleEmitter")
	rain.Name = "GoldRain"
	rain.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	rain.Color = ColorSequence.new(Color3.fromRGB(255, 206, 60))
	rain.Size = NumberSequence.new(0.8)
	rain.Rate = 0
	rain.Lifetime = NumberRange.new(2.4, 2.6)
	rain.Speed = NumberRange.new(48, 52)
	rain.EmissionDirection = Enum.NormalId.Bottom
	rain.SpreadAngle = Vector2.new(0, 0)
	rain.RotSpeed = NumberRange.new(-60, 60)
	rain.LightEmission = 0.8
	rain.Parent = rainRig
	world.GoldRainEmitter = rain

	-- folders other managers fill
	local wild = Instance.new("Folder")
	wild.Name = "WildBrainrots"
	wild.Parent = Workspace
	world.WildFolder = wild

	return world
end

return WorldBuilder
