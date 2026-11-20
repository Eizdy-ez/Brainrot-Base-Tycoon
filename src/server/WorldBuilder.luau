-- WorldBuilder.luau — constructs the whole island from code at server start:
-- the spawn plaza AT the island centre, three fenced fields
-- with gates, eight tycoon base plots ringed tight around the centre
-- (display pads, collect/lock/rebirth pads, upgrade buttons), a playful
-- perimeter fence on every side, big readable signs, a leaderboard
-- board, and decorations. The look is the classic brainrot one: BRIGHT
-- DAYTIME, green grass, candy colours, toy-box bases, trees, flowers
-- and white clouds (runtime lighting restores the project's sunny
-- values; default.project.json stays untouched).
-- Everything is authored here as data + loops; no hand-placed Studio content.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
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

local CREAM = Color3.fromRGB(246, 240, 224)
local INK_DARK = Color3.fromRGB(74, 60, 44)

local function board(parent, name, size, cf, title, body, titleColor, bgColor)
	local p = mkPart(parent, name, size, cf, bgColor or CREAM, Enum.Material.SmoothPlastic)
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
	titleLabel.TextColor3 = titleColor or INK_DARK
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
		bodyLabel.TextColor3 = INK_DARK
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

local CANDY_COLORS = {
	Color3.fromRGB(255, 120, 110), Color3.fromRGB(255, 190, 70),
	Color3.fromRGB(90, 200, 140), Color3.fromRGB(100, 170, 255),
	Color3.fromRGB(255, 130, 200), Color3.fromRGB(170, 120, 255),
}
local LEAF_GREENS = {
	Color3.fromRGB(74, 178, 84), Color3.fromRGB(96, 196, 92),
	Color3.fromRGB(58, 160, 76), Color3.fromRGB(120, 205, 100),
}

-- a cheerful low-poly tree: a round terracotta pot, a brown trunk and
-- a cluster of green foliage balls, some with candy "fruit"
local function buildTree(parent, x, z, s, colorIdx)
	local g = Instance.new("Model")
	g.Name = "Tree"
	g.Parent = parent
	local pot = mkPart(g, "Pot", Vector3.new(3.2 * s, 1.2 * s, 3.2 * s), CFrame.new(x, 0.6 * s, z), Color3.fromRGB(196, 110, 70), Enum.Material.SmoothPlastic)
	pot.Shape = Enum.PartType.Cylinder
	mkPart(g, "Trunk", Vector3.new(0.9 * s, 3.4 * s, 0.9 * s), CFrame.new(x, 2.6 * s, z), Color3.fromRGB(140, 96, 58), Enum.Material.Wood)
	local leaf = LEAF_GREENS[((colorIdx - 1) % #LEAF_GREENS) + 1]
	local blobs = { { 0, 5.6, 0, 4.6 }, { -1.5, 4.7, 0.6, 3.2 }, { 1.5, 4.8, -0.5, 3.4 }, { 0.3, 4.6, 1.4, 2.8 } }
	for j, b in ipairs(blobs) do
		local foliage = mkPart(g, "Foliage" .. j, Vector3.new(b[4] * s, b[4] * s, b[4] * s),
			CFrame.new(x + b[1] * s, b[2] * s, z + b[3] * s), leaf, Enum.Material.SmoothPlastic)
		foliage.Shape = Enum.PartType.Ball
		foliage.CanCollide = false
	end
	if colorIdx % 2 == 0 then
		local fruit = CANDY_COLORS[((colorIdx - 1) % #CANDY_COLORS) + 1]
		for j = 1, 3 do
			local f = mkPart(g, "Fruit" .. j, Vector3.new(0.7 * s, 0.7 * s, 0.7 * s),
				CFrame.new(x + (j - 2) * 1.4 * s, (4.6 + (j % 2) * 0.9) * s, z + 1.7 * s), fruit, Enum.Material.SmoothPlastic)
			f.Shape = Enum.PartType.Ball
			f.CanCollide = false
		end
	end
end

-- a bright toy block with a white stripe, used as island clutter
local function buildToyBlock(parent, x, z, s, rot, colorIdx)
	local g = Instance.new("Model")
	g.Name = "ToyBlock"
	g.Parent = parent
	mkPart(g, "Block", Vector3.new(3.2 * s, 3.2 * s, 3.2 * s), CFrame.new(x, 1.6 * s, z) * CFrame.Angles(0, rot, 0), CANDY_COLORS[((colorIdx - 1) % #CANDY_COLORS) + 1], Enum.Material.SmoothPlastic)
	local strip = mkPart(g, "Stripe", Vector3.new(3.3 * s, 0.5 * s, 3.3 * s), CFrame.new(x, 2.5 * s, z) * CFrame.Angles(0, rot, 0), Color3.fromRGB(255, 252, 244), Enum.Material.SmoothPlastic)
	strip.CanCollide = false
end

--====================================================================--
-- Bright daytime, set explicitly at runtime so the island always
-- reads sunny and candy-coloured: early-afternoon sun, bright ambient,
-- no fog, a gentle bloom and a warm colour grade — the starter
-- project's own daylight values, restated.
--====================================================================--
local function applyDay()
	Lighting.ClockTime = 13.5
	Lighting.Brightness = 3
	Lighting.Ambient = Color3.fromRGB(158, 158, 173)
	Lighting.OutdoorAmbient = Color3.fromRGB(140, 148, 179)
	Lighting.FogColor = Color3.fromRGB(196, 226, 255)
	Lighting.FogStart = 100000
	Lighting.FogEnd = 100000
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 1
	local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmo then
		atmo.Density = 0.18
		atmo.Color = Color3.fromRGB(199, 219, 255)
		atmo.Decay = Color3.fromRGB(140, 173, 242)
		atmo.Glare = 0.25
		atmo.Haze = 1.2
		atmo.Offset = 0.25
	end
	local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
	if bloom then
		bloom.Intensity = 0.35
		bloom.Size = 24
		bloom.Threshold = 0.85
	end
	local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
	if cc then
		cc.TintColor = Color3.fromRGB(255, 255, 255)
		cc.Brightness = 0.02
		cc.Contrast = 0.05
		cc.Saturation = 0.18
	end
	local rays = Lighting:FindFirstChildOfClass("SunRaysEffect")
	if rays then
		rays.Intensity = 0.06
		rays.Spread = 0.7
	end
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

	-- Toy-box shell: a pastel floor in the slot's own colour over a cream
	-- slab, ringed by full walls on all four sides — cream panels below,
	-- light glass above — crowned by one slim line in the slot
	-- colour. The front wall (facing the island centre) holds the gate;
	-- its door is driven by the base lock (see BaseManager.UpdateGate).
	local CREAM_WALL = Color3.fromRGB(240, 228, 198)
	local CREAM_DARK = Color3.fromRGB(210, 185, 140)
	local GLASS_TINT = Color3.fromRGB(190, 225, 245)
	local WHITE = Color3.fromRGB(255, 255, 255)

	mkPart(model, "Trim", Vector3.new(47.5, 0.6, 47.5), CFrame.new(centerX, 0.2, centerZ), CREAM_DARK, Enum.Material.SmoothPlastic)
	mkPart(model, "Floor", Vector3.new(46, 0.5, 46), CFrame.new(centerX, 0.75, centerZ), color:Lerp(WHITE, 0.45), Enum.Material.SmoothPlastic)

	local base = {
		Slot = slot, Center = Vector3.new(centerX, 1, centerZ), Model = model,
		Pending = 0, Owner = nil, Locked = false, LockUntil = 0, LockReadyAt = 0,
		Pads = {}, UpgradePads = {},
	}

	-- pastel inlay strips set into the floor: a sparse cross (2 each
	-- way) alternating the base's colour and its neighbour — a quiet
	-- toy-floor inlay, static and glow-free.
	local stripB = BASE_COLORS[(slot % #BASE_COLORS) + 1]
	local gridOffsets = { -13.8, 13.8 }
	for i, go in ipairs(gridOffsets) do
		local across = mkPart(model, "LightStripX" .. i, Vector3.new(45, 0.14, 0.42), CFrame.new(centerX, 1.06, centerZ + go), i % 2 == 0 and stripB or color, Enum.Material.SmoothPlastic)
		across.CanCollide = false
		across.CanQuery = false
		across.CanTouch = false
		local alongPos = L(go, 0)
		local along = mkPart(model, "LightStripZ" .. i, Vector3.new(0.42, 0.14, 45), CFrame.new(alongPos.X, 1.06, centerZ), i % 2 == 0 and color or stripB, Enum.Material.SmoothPlastic)
		along.CanCollide = false
		along.CanQuery = false
		along.CanTouch = false
	end

	-- one straight wall run in local plot coords: cream band (y 1..4.2),
	-- glass band (up to y 9.4), top rail, and the thin crown
	-- line in the slot colour. glassBottom > 4.2 + noLower builds a
	-- lintel (no cream band) for the stretch over the gate opening.
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
			seg("WallCream", 3.2, 2.6, WALL_T, CREAM_WALL, Enum.Material.SmoothPlastic)
		end
		local gb = glassBottom or 4.2
		seg("WallGlass", 9.4 - gb, (9.4 + gb) / 2, WALL_T, GLASS_TINT, Enum.Material.Glass, 0.45)
		seg("WallTopRail", 0.55, 9.68, WALL_T + 0.35, CREAM_DARK, Enum.Material.SmoothPlastic)
		local crown = seg("WallCrown", 0.3, 10.1, 0.34, color, Enum.Material.SmoothPlastic)
		crown.CanCollide = false
		crown.Transparency = 0.1
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
		mkPart(model, "FramePost", Vector3.new(1.1, 8.4, 1.1), CFrame.new(p.X, 5.2, p.Z), CREAM_DARK, Enum.Material.SmoothPlastic)
		local q = L(22.6, oz)
		mkPart(model, "FramePost", Vector3.new(1.1, 8.4, 1.1), CFrame.new(q.X, 5.2, q.Z), CREAM_DARK, Enum.Material.SmoothPlastic)
	end
	for _, ox in ipairs({ -22.6, 0, 22.6 }) do
		for _, oz in ipairs({ -22.6, 22.6 }) do
			local p = L(ox, oz)
			mkPart(model, "FramePost", Vector3.new(1.1, 8.4, 1.1), CFrame.new(p.X, 5.2, p.Z), CREAM_DARK, Enum.Material.SmoothPlastic)
		end
	end
	for _, oz in ipairs({ -4.9, 4.9 }) do
		local p = L(-22.6, oz)
		mkPart(model, "GateJamb", Vector3.new(1.1, 6.2, 1.1), CFrame.new(p.X, 4.1, p.Z), CREAM_DARK, Enum.Material.SmoothPlastic)
	end

	-- the gate door itself: tinted glass that turns solid while the base
	-- is locked (BaseManager.UpdateGate drives CanCollide/Transparency;
	-- it starts open). The owner always passes — Effects clears the
	-- door's collision on the owner's own client only.
	local gatePos = L(-22.6, 0)
	local door = mkPart(model, "GateDoor", Vector3.new(0.55, 6.2, 9), CFrame.new(gatePos.X, 4.1, gatePos.Z), color, Enum.Material.Glass)
	door.Transparency = 0.85
	door.CanCollide = false
	base.GateDoor = door

	-- 8 display pedestals hugging the walls (Round 9D: down from
	-- 12; Round 10D: respread so EVERY neighbouring gap is wide —
	-- the 9D spread left the two corner pairs only ~6 studs apart
	-- while the straight runs were 11-13): four along the back
	-- wall spanning the full run at 13-stud gaps, two along each
	-- side wall also 13 apart and centred so the corner gaps land
	-- at ~12.1 — every adjacent pair now sits in a 12.1-13 band,
	-- leaving the inlaid floor open in the middle.
	local padSpots = {}
	for i = 0, 3 do
		padSpots[#padSpots + 1] = { 18.6, -19.5 + i * 13 }
	end
	for i = 0, 1 do
		padSpots[#padSpots + 1] = { 6.5 - i * 13, -18.6 }
	end
	for i = 0, 1 do
		padSpots[#padSpots + 1] = { 6.5 - i * 13, 18.6 }
	end
	for padIndex, spot in ipairs(padSpots) do
		local pos = L(spot[1], spot[2])
		local pedestal = mkPart(model, "Pad" .. padIndex, Vector3.new(3.8, 0.9, 3.8), CFrame.new(pos.X, 1.45, pos.Z), Color3.fromRGB(238, 228, 200), Enum.Material.SmoothPlastic)
		local top = mkPart(model, "PadTop" .. padIndex, Vector3.new(3.9, 0.22, 3.9), CFrame.new(pos.X, 1.95, pos.Z), color, Enum.Material.SmoothPlastic)
		top.CanCollide = false
		base.Pads[padIndex] = { Part = top, Pedestal = pedestal, Anchor = Vector3.new(pos.X, 2.05, pos.Z), Model = nil }
	end

	-- collect pad (green cylinder the owner stands on to claim cash)
	local cPos = L(-7, -9)
	local collect = mkPart(model, "CollectPad", Vector3.new(6.4, 0.5, 6.4), CFrame.new(cPos.X, 1.25, cPos.Z), Color3.fromRGB(64, 220, 110), Enum.Material.SmoothPlastic)
	collect.Shape = Enum.PartType.Cylinder
	base.CollectPad = collect
	base.CollectLabel = padLabel(collect, "COLLECT\n$0", Color3.fromRGB(190, 255, 205), 3.6)

	-- lock pad
	local lPos = L(-7, 9)
	local lock = mkPart(model, "LockPad", Vector3.new(5, 0.5, 5), CFrame.new(lPos.X, 1.25, lPos.Z), Color3.fromRGB(90, 160, 255), Enum.Material.SmoothPlastic)
	base.LockPad = lock
	base.LockLabel = padLabel(lock, "🔓 LOCK BASE", Color3.fromRGB(200, 225, 255), 3.4)

	-- a decorative toy cube floats on the spare floor spot by the pads
	local fPos = L(-15, -9)
	local holo = mkPart(model, "ToyCube", Vector3.new(2.2, 2.2, 2.2), CFrame.new(fPos.X, 3.4, fPos.Z) * CFrame.Angles(math.rad(24), math.rad(36), 0), stripB, Enum.Material.SmoothPlastic)
	holo.Transparency = 0.15
	holo.CanCollide = false
	holo.CanQuery = false
	holo.CanTouch = false
	mkPart(model, "ToyCubeBase", Vector3.new(3.4, 0.4, 3.4), CFrame.new(fPos.X, 1.2, fPos.Z), CREAM_DARK, Enum.Material.SmoothPlastic)

	-- rebirth pad
	local rPos = L(-15, 9)
	local rebirth = mkPart(model, "RebirthPad", Vector3.new(5.4, 0.5, 5.4), CFrame.new(rPos.X, 1.25, rPos.Z), Color3.fromRGB(255, 120, 160), Enum.Material.SmoothPlastic)
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
		"EMPTY BASE", nil, color, CREAM)
	base.SignLabel = signTitle

	-- two lamps just inside the front corners
	for _, lz in ipairs({ -18, 18 }) do
		local pos = L(-20, lz)
		mkPart(model, "LampPost", Vector3.new(0.5, 5.5, 0.5), CFrame.new(pos.X, 3.7, pos.Z), Color3.fromRGB(150, 120, 84), Enum.Material.Wood)
		local bulb = mkPart(model, "LampBulb", Vector3.new(1.1, 1.1, 1.1), CFrame.new(pos.X, 6.8, pos.Z), Color3.fromRGB(255, 230, 150), Enum.Material.SmoothPlastic)
		bulb.Shape = Enum.PartType.Ball
		bulb.CanCollide = false
	end

	return base
end

function WorldBuilder.Build()
	applyDay()
	local world = { Bases = {}, Zones = {} }
	local root = Instance.new("Folder")
	root.Name = "BrainrotWorld"
	root.Parent = Workspace

	-- the island: a bright lake, a sandy rim and a green grass top. The
	-- whole game lives in a tight arena centred on the spawn point
	-- (0, 0): the fields run south in a strip, bases ring the centre at
	-- x = ±92, and trees, flowers and clouds dress the rest.
	local water = mkPart(root, "Water", Vector3.new(1600, 2, 1600), CFrame.new(0, -4.2, -93), Color3.fromRGB(64, 164, 230), Enum.Material.SmoothPlastic)
	water.CanCollide = false
	water.Transparency = 0.15
	mkPart(root, "Sand", Vector3.new(260, 2, 272), CFrame.new(0, -1.6, -93), Color3.fromRGB(238, 216, 160), Enum.Material.Sand)
	mkPart(root, "Grass", Vector3.new(248, 2, 260), CFrame.new(0, -1, -93), Color3.fromRGB(102, 194, 88), Enum.Material.Grass)

	-- central path (plaza -> zone 3) and cross paths to the base rows:
	-- sandy walkways edged with plain guide lines
	local PATH_SAND = Color3.fromRGB(238, 226, 192)
	local PATH_A = Color3.fromRGB(255, 176, 66)
	local PATH_B = Color3.fromRGB(255, 110, 170)
	local BASE_ROWS = { 0, -50, -118, -186 }
	mkPart(root, "PathMain", Vector3.new(12, 0.3, 224), CFrame.new(0, 0.06, -94), PATH_SAND, Enum.Material.Sand)
	for _, sx in ipairs({ -6.4, 6.4 }) do
		local edge = mkPart(root, "PathEdge", Vector3.new(0.5, 0.34, 224), CFrame.new(sx, 0.08, -94), PATH_A, Enum.Material.SmoothPlastic)
		edge.CanCollide = false
	end
	for _, z in ipairs(BASE_ROWS) do
		mkPart(root, "PathCross", Vector3.new(232, 0.3, 10), CFrame.new(0, 0.06, z), PATH_SAND, Enum.Material.Sand)
		local line = mkPart(root, "PathCrossLine", Vector3.new(232, 0.34, 0.5), CFrame.new(0, 0.08, z), PATH_B, Enum.Material.SmoothPlastic)
		line.CanCollide = false
	end

	-- spawn plaza AT the centre point: a cream disc with a golden
	-- rim and candy corner pillars; the player spawn sits in
	-- its middle
	local rim = mkPart(root, "PlazaRim", Vector3.new(48, 0.4, 48), CFrame.new(0, 0.02, 0), PATH_A, Enum.Material.SmoothPlastic)
	rim.Shape = Enum.PartType.Cylinder
	rim.CanCollide = false
	local plaza = mkPart(root, "Plaza", Vector3.new(44, 0.5, 44), CFrame.new(0, 0.1, 0), Color3.fromRGB(243, 233, 205), Enum.Material.Concrete)
	plaza.Shape = Enum.PartType.Cylinder
	for ci, corner in ipairs({ { -17, -17 }, { 17, -17 }, { -17, 17 }, { 17, 17 } }) do
		mkPart(root, "PlazaPillar", Vector3.new(1.1, 9, 1.1), CFrame.new(corner[1], 4.5, corner[2]), Color3.fromRGB(238, 228, 200), Enum.Material.SmoothPlastic)
		local coreColor = CANDY_COLORS[((ci - 1) % #CANDY_COLORS) + 1]
		local core = mkPart(root, "PlazaPillarCore", Vector3.new(0.5, 8.2, 0.5), CFrame.new(corner[1], 4.5, corner[2]), coreColor, Enum.Material.SmoothPlastic)
		core.CanCollide = false
	end
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.CFrame = CFrame.new(0, 0.8, 0) * CFrame.Angles(0, math.rad(180), 0)
	spawn.Color = Color3.fromRGB(90, 200, 255)
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Parent = root
	world.SpawnCFrame = spawn.CFrame

	-- rarity guide board (west of plaza) and leaderboard board (east)
	board(root, "RarityBoard", Vector3.new(17, 10, 1), CFrame.new(-28, 5.5, 12) * CFrame.Angles(0, math.rad(150), 0),
		"⭐ RARITY ⭐", "MYTHIC > LEGENDARY > EPIC > RARE > COMMON\nShiny x2  •  Golden x5", Color3.fromRGB(214, 62, 140), CREAM)
	local _, _, lbBody = board(root, "Leaderboard", Vector3.new(17, 10, 1), CFrame.new(28, 5.5, 12) * CFrame.Angles(0, math.rad(-150), 0),
		"🏆 TOP TYCOONS", "…", Color3.fromRGB(176, 124, 16), CREAM)
	world.LeaderboardLabel = lbBody

	-- decorative shop stand west of the plaza (warm wood + coral roof)
	local stand = Instance.new("Model")
	stand.Name = "ShopStand"
	stand.Parent = root
	mkPart(stand, "Counter", Vector3.new(10, 3, 4), CFrame.new(-31, 1.5, -14), Color3.fromRGB(172, 122, 80), Enum.Material.Wood)
	mkPart(stand, "Roof", Vector3.new(12, 0.6, 6), CFrame.new(-31, 6.4, -14) * CFrame.Angles(math.rad(8), 0, 0), Color3.fromRGB(255, 110, 100), Enum.Material.SmoothPlastic)
	mkPart(stand, "PostL", Vector3.new(0.6, 6, 0.6), CFrame.new(-36, 3, -14), Color3.fromRGB(150, 105, 64), Enum.Material.Wood)
	mkPart(stand, "PostR", Vector3.new(0.6, 6, 0.6), CFrame.new(-26, 3, -14), Color3.fromRGB(150, 105, 64), Enum.Material.Wood)
	board(stand, "ShopSign", Vector3.new(11, 2.6, 0.6), CFrame.new(-31, 5, -16.4) * CFrame.Angles(0, math.rad(90), 0),
		"🛒 SHOP — press SHOP button!", nil, Color3.fromRGB(96, 58, 12), Color3.fromRGB(255, 205, 90))

	--================================================================--
	-- Perimeter fence on EVERY side of the arena, Steal-a-Brainrot
	-- style: a warm wooden band, a light glass band above and a slim
	-- golden crown line — the same language as the base shells, one
	-- ring around it all, so the play area's edge is unmistakable.
	--================================================================--
	local PERI_WOOD = Color3.fromRGB(206, 168, 116)
	local PERI_GLASS = Color3.fromRGB(190, 225, 245)
	local function perimeterRun(x1, z1, x2, z2)
		local dx, dz = x2 - x1, z2 - z1
		local len = math.sqrt(dx * dx + dz * dz) + 0.8
		local mid = Vector3.new((x1 + x2) / 2, 0, (z1 + z2) / 2)
		local function seg(name, h, cy, thick, segColor, material, transparency)
			local p = mkPart(root, name, Vector3.new(thick, h, len),
				CFrame.lookAt(Vector3.new(mid.X, cy, mid.Z), Vector3.new(x2, cy, z2)), segColor, material)
			if transparency then
				p.Transparency = transparency
			end
			return p
		end
		seg("PerimeterWood", 4.2, 2.1, 0.8, PERI_WOOD, Enum.Material.Wood)
		seg("PerimeterGlass", 5.2, 6.8, 0.8, PERI_GLASS, Enum.Material.Glass, 0.45)
		seg("PerimeterRail", 0.55, 9.68, 1.15, PERI_WOOD, Enum.Material.Wood)
		local crown = seg("PerimeterTrim", 0.3, 10.1, 0.34, PATH_A, Enum.Material.SmoothPlastic)
		crown.CanCollide = false
		crown.Transparency = 0.1
	end
	perimeterRun(-122, 28, 122, 28)
	perimeterRun(122, 28, 122, -214)
	perimeterRun(122, -214, -122, -214)
	perimeterRun(-122, -214, -122, 28)
	for _, corner in ipairs({ { -122, 28 }, { 122, 28 }, { 122, -214 }, { -122, -214 } }) do
		mkPart(root, "PerimeterPost", Vector3.new(1.6, 9.4, 1.6), CFrame.new(corner[1], 4.7, corner[2]), PERI_WOOD, Enum.Material.Wood)
	end

	-- the three fields, fences, gates — classic meadow look: coloured
	-- grass (sand for the volcano tier), a lighter inner tint, wooden
	-- fences with a top rail in the zone's accent colour,
	-- corner pillars, toy crates and a readable board at the
	-- entrance. Visual richness grows with the tier: more pillars
	-- and crates in the higher zones.
	local ZONE_MATS = { Enum.Material.Grass, Enum.Material.Grass, Enum.Material.Sand }
	for zi, zone in ipairs(Config.Zones) do
		local zc = zone.Center
		local accent = zone.AccentColor
		local groundMat = ZONE_MATS[zi] or Enum.Material.Grass
		local field = Instance.new("Model")
		field.Name = "Zone" .. zi
		field.Parent = root
		mkPart(field, "Ground", Vector3.new(zone.Size.X, 0.6, zone.Size.Y), CFrame.new(zc.X, 0.05, zc.Z), zone.GroundColor, groundMat)
		mkPart(field, "InnerTint", Vector3.new(zone.Size.X - 10, 0.2, zone.Size.Y - 10), CFrame.new(zc.X, 0.3, zc.Z), zone.GroundColor:Lerp(accent, 0.18), groundMat)
		-- meadow seams: thin darker grooves dividing the field into plots
		for gx = -40, 40, 20 do
			local seam = mkPart(field, "MeadowSeam", Vector3.new(0.35, 0.22, zone.Size.Y - 8), CFrame.new(zc.X + gx, 0.32, zc.Z), zone.GroundColor:Lerp(Color3.fromRGB(0, 0, 0), 0.16), groundMat)
			seam.CanCollide = false
		end
		-- corner pillars (2 in zone 1, 4 from zone 2 up)
		local pillarSpots = { { -52, -17 }, { 52, 17 } }
		if zi >= 2 then
			pillarSpots[#pillarSpots + 1] = { 52, -17 }
			pillarSpots[#pillarSpots + 1] = { -52, 17 }
		end
		for _, spot in ipairs(pillarSpots) do
			mkPart(field, "Pillar", Vector3.new(1.2, 10, 1.2), CFrame.new(zc.X + spot[1], 5, zc.Z + spot[2]), Color3.fromRGB(228, 205, 160), Enum.Material.Wood)
			local core = mkPart(field, "PillarCore", Vector3.new(0.55, 9.2, 0.55), CFrame.new(zc.X + spot[1], 5, zc.Z + spot[2]), accent, Enum.Material.SmoothPlastic)
			core.CanCollide = false
			local tip = mkPart(field, "PillarTip", Vector3.new(1.5, 1.5, 1.5), CFrame.new(zc.X + spot[1], 10.6, zc.Z + spot[2]), accent, Enum.Material.SmoothPlastic)
			tip.Shape = Enum.PartType.Ball
			tip.CanCollide = false
		end
		-- toy crates stacked near the edges (more in higher tiers)
		for i = 1, 2 + zi do
			local cx = zc.X + ((i * 41 + zi * 17) % 96) - 48
			local cz = zc.Z + ((i * 29 + zi * 11) % 40) - 20
			mkPart(field, "ToyCrate", Vector3.new(3.4, 3.4, 3.4), CFrame.new(cx, 2, cz) * CFrame.Angles(0, math.rad(i * 27), 0), CANDY_COLORS[((i + zi - 1) % #CANDY_COLORS) + 1], Enum.Material.SmoothPlastic)
			local strip = mkPart(field, "CrateStrip", Vector3.new(3.5, 0.4, 3.5), CFrame.new(cx, 3.1, cz) * CFrame.Angles(0, math.rad(i * 27), 0), accent, Enum.Material.SmoothPlastic)
			strip.CanCollide = false
		end
		-- board at the field entrance naming the tier
		local _, zoneTitle = board(field, "ZoneBoard", Vector3.new(16, 4.5, 0.5), CFrame.new(zc.X + 16, 6.5, zc.Z + zone.Size.Y / 2 + 3) * CFrame.Angles(0, math.rad(180), 0),
			zone.Name:upper(), "ZONE " .. zi .. " — brainrots wander here!", accent, CREAM)
		zoneTitle.TextTransparency = 0.05
		-- perimeter fence with a gap on the path (x in [-7,7]) on both z sides:
		-- wooden posts, a top rail in the zone's accent colour
		local fx, fz = zone.Size.X / 2, zone.Size.Y / 2
		local fenceColor = Color3.fromRGB(150, 105, 64)
		for _, sideZ in ipairs({ zc.Z - fz, zc.Z + fz }) do
			for x = -fx, fx, 10 do
				if math.abs(x) > 8 then
					mkPart(field, "FencePost", Vector3.new(0.7, 2.6, 0.7), CFrame.new(zc.X + x, 1.3, sideZ), fenceColor, Enum.Material.Wood)
				end
			end
			local railL = mkPart(field, "FenceRailL", Vector3.new(fx - 8, 0.4, 0.4), CFrame.new(zc.X - (fx + 8) / 2 - 0, 2.2, sideZ), accent, Enum.Material.SmoothPlastic)
			railL.CanCollide = false
			local railR = mkPart(field, "FenceRailR", Vector3.new(fx - 8, 0.4, 0.4), CFrame.new(zc.X + (fx + 8) / 2, 2.2, sideZ), accent, Enum.Material.SmoothPlastic)
			railR.CanCollide = false
			mkPart(field, "FenceRailLowL", Vector3.new(fx - 8, 0.4, 0.4), CFrame.new(zc.X - (fx + 8) / 2 - 0, 1.1, sideZ), fenceColor, Enum.Material.Wood)
			mkPart(field, "FenceRailLowR", Vector3.new(fx - 8, 0.4, 0.4), CFrame.new(zc.X + (fx + 8) / 2, 1.1, sideZ), fenceColor, Enum.Material.Wood)
		end
		for _, sideX in ipairs({ zc.X - fx, zc.X + fx }) do
			for z = -fz, fz, 10 do
				mkPart(field, "FencePost", Vector3.new(0.7, 2.6, 0.7), CFrame.new(sideX, 1.3, zc.Z + z), fenceColor, Enum.Material.Wood)
			end
			local rail = mkPart(field, "FenceRail", Vector3.new(0.4, 0.4, zone.Size.Y), CFrame.new(sideX, 2.2, zc.Z), accent, Enum.Material.SmoothPlastic)
			rail.CanCollide = false
			mkPart(field, "FenceRailLow", Vector3.new(0.4, 0.4, zone.Size.Y), CFrame.new(sideX, 1.1, zc.Z), fenceColor, Enum.Material.Wood)
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
		mkPart(gate, "PostL", Vector3.new(2.2, 13, 2.2), CFrame.new(-8, 6.5, gateZ), Color3.fromRGB(228, 205, 160), Enum.Material.Wood)
		mkPart(gate, "PostR", Vector3.new(2.2, 13, 2.2), CFrame.new(8, 6.5, gateZ), Color3.fromRGB(228, 205, 160), Enum.Material.Wood)
		board(gate, "GateSign", Vector3.new(21, 5.5, 1), CFrame.new(0, 14.5, gateZ) * CFrame.Angles(0, math.rad(180), 0),
			"🔒 " .. zone.Name:upper(), "Unlock for $" .. Util.FormatInt(zone.Price), Color3.fromRGB(176, 124, 16), CREAM)
		local wall = mkPart(gate, "Barrier", Vector3.new(124, 9, 1), CFrame.new(0, 4.5, gateZ), zone.AccentColor, Enum.Material.ForceField)
		wall.Transparency = 0.45
		wall.CanCollide = false
		local pad = mkPart(gate, "GatePad", Vector3.new(7, 0.5, 7), CFrame.new(0, 0.35, gateZ + 7), Color3.fromRGB(255, 196, 66), Enum.Material.SmoothPlastic)
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
	local archZ = -24
	for i, rarity in ipairs(Config.Rarities) do
		local x = (i - 3) * 7
		mkPart(root, "GemPost", Vector3.new(1.4, 6 + i * 0.7, 1.4), CFrame.new(x, (6 + i * 0.7) / 2, archZ), Color3.fromRGB(210, 190, 155), Enum.Material.Wood)
		local gem = mkPart(root, "Gem", Vector3.new(2.2, 2.2, 2.2), CFrame.new(x, 7 + i * 0.7, archZ), rarity.Color, Enum.Material.SmoothPlastic)
		gem.Shape = Enum.PartType.Ball
		gem.CanCollide = false
	end
	board(root, "FieldsSign", Vector3.new(30, 5, 1), CFrame.new(0, 13.5, archZ) * CFrame.Angles(0, math.rad(180), 0),
		"🧠 BRAINROT BASE TYCOON", "Brainrots wander the fields — buy one before it wanders away!", Color3.fromRGB(176, 124, 16), CREAM)

	-- eight bases in two tight columns flanking the field strip, their
	-- fronts an 8-stud walk from the fields, ringing the central plaza
	local slot = 0
	for _, x in ipairs({ -92, 92 }) do
		for _, z in ipairs(BASE_ROWS) do
			slot += 1
			world.Bases[slot] = buildBase(root, slot, x, z)
		end
	end

	-- decorations: trees in terracotta pots, toy blocks, flowers, white
	-- clouds, path lamps — all in the island's bright candy palette.
	-- Scatter uses rejection sampling so nothing lands inside a field,
	-- a base plot or the plaza.
	local rng = Random.new(20261119)
	local function pointFree(x, z)
		if math.abs(x) < 64 and z < -24 and z > -212 then
			return false -- the field strip
		end
		if math.abs(x) > 64 and math.abs(x) < 120 then
			for _, rowZ in ipairs(BASE_ROWS) do
				if math.abs(z - rowZ) < 27 then
					return false -- a base plot
				end
			end
		end
		if math.sqrt(x * x + z * z) < 27 then
			return false -- the plaza
		end
		return true
	end
	local function scatterPoint()
		for _ = 1, 40 do
			local x = rng:NextNumber(-118, 118)
			local z = rng:NextNumber(-210, 24)
			if pointFree(x, z) then
				return x, z
			end
		end
		return nil, nil
	end
	for i = 1, 14 do
		local x, z = scatterPoint()
		if x then
			buildTree(root, x, z, rng:NextNumber(0.8, 1.4), i)
		end
	end
	for i = 1, 9 do
		local x, z = scatterPoint()
		if x then
			buildToyBlock(root, x, z, rng:NextNumber(0.7, 1.3), rng:NextNumber(0, 3), i)
		end
	end
	-- flowers dotted over the grass: a green stem and a candy head
	local FLOWER_HEADS = {
		Color3.fromRGB(255, 120, 170), Color3.fromRGB(255, 214, 90), Color3.fromRGB(255, 252, 244),
		Color3.fromRGB(255, 150, 80), Color3.fromRGB(190, 130, 255), Color3.fromRGB(255, 100, 100),
	}
	for i = 1, 46 do
		local fx, fz = rng:NextNumber(-118, 118), rng:NextNumber(-210, 24)
		local stem = mkPart(root, "FlowerStem", Vector3.new(0.09, 0.55, 0.09), CFrame.new(fx, 0.28, fz), Color3.fromRGB(62, 150, 70))
		stem.CanCollide = false
		local head = mkPart(root, "Flower", Vector3.new(0.55, 0.55, 0.55),
			CFrame.new(fx, 0.68, fz), FLOWER_HEADS[(i % #FLOWER_HEADS) + 1], Enum.Material.SmoothPlastic)
		head.Shape = Enum.PartType.Ball
		head.CanCollide = false
	end
	for _ = 1, 7 do
		local cx, cz = rng:NextNumber(-150, 150), rng:NextNumber(-230, 30)
		local cy = rng:NextNumber(52, 72)
		for j = 1, 3 do
			-- puffy white clouds drifting over the island
			local cloud = mkPart(root, "Cloud", Vector3.new(rng:NextNumber(16, 30), 3.2, rng:NextNumber(8, 14)),
				CFrame.new(cx + (j - 2) * 11, cy + rng:NextNumber(-1, 1), cz), Color3.fromRGB(255, 255, 255))
			cloud.Transparency = 0.1
			cloud.CanCollide = false
			cloud.CanQuery = false
			cloud.CanTouch = false
		end
	end
	for z = 16, -200, -36 do
		for _, x in ipairs({ -8.5, 8.5 }) do
			mkPart(root, "PathLamp", Vector3.new(0.45, 5, 0.45), CFrame.new(x, 2.5, z), Color3.fromRGB(150, 105, 64), Enum.Material.Wood)
			local bulb = mkPart(root, "PathLampBulb", Vector3.new(1, 1, 1), CFrame.new(x, 5.4, z), Color3.fromRGB(255, 236, 170), Enum.Material.SmoothPlastic)
			bulb.Shape = Enum.PartType.Ball
			bulb.CanCollide = false
		end
	end

	-- gold-rain emitter rig (toggled by the event manager)
	local rainRig = mkPart(root, "GoldRainRig", Vector3.new(10, 1, 10), CFrame.new(0, 60, -93), Color3.fromRGB(255, 255, 255))
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
