-- BrainrotFactory.luau — builds blocky brainrot characters out of plain
-- Parts from the data definitions in Config. No external assets: body, head,
-- eyes and a set of accessory builders (pizza hat, shark fin, Saturn ring…),
-- plus the BillboardGui nameplate and rarity sparkles every brainrot wears.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local Factory = {}

local function part(parent, name, size, cf, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = false
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.Parent = parent
	return p
end

local function weldTo(partInst, body)
	local w = Instance.new("WeldConstraint")
	w.Part0 = body
	w.Part1 = partInst
	w.Parent = partInst
end

-- Accessory builders: each receives the model, its body part, the definition
-- and a helper to add welded parts in body-local space.
local AccessoryBuilders = {}

function AccessoryBuilders.Pizza(model, body, def, add)
	add("PizzaHat", Vector3.new(1.9, 0.18, 1.9), CFrame.new(0, 1.55, 0), Color3.fromRGB(255, 196, 92))
	add("Pepperoni", Vector3.new(0.4, 0.2, 0.4), CFrame.new(0.4, 1.62, 0.3), Color3.fromRGB(200, 60, 50))
	add("Pepperoni2", Vector3.new(0.4, 0.2, 0.4), CFrame.new(-0.45, 1.62, -0.25), Color3.fromRGB(200, 60, 50))
end

function AccessoryBuilders.Leaf(model, body, def, add)
	add("Leaf", Vector3.new(0.24, 0.9, 0.5), CFrame.new(0.2, 1.7, 0) * CFrame.Angles(0, 0, math.rad(-25)), Color3.fromRGB(84, 190, 84))
end

function AccessoryBuilders.Beak(model, body, def, add)
	local beak = add("Beak", Vector3.new(0.5, 0.34, 0.9), CFrame.new(0, 0.95, -1.05), Color3.fromRGB(255, 160, 40))
	beak.Shape = Enum.PartType.Block
end

function AccessoryBuilders.TailFin(model, body, def, add)
	add("TailFin", Vector3.new(0.16, 1.0, 0.9), CFrame.new(0, 0.25, 1.0) * CFrame.Angles(math.rad(-20), 0, 0), def.Accent)
end

function AccessoryBuilders.LogBody(model, body, def, add)
	body.Shape = Enum.PartType.Cylinder
	body.CFrame = body.CFrame * CFrame.Angles(0, 0, math.rad(90))
	add("LogEnd", Vector3.new(0.24, 1.7, 1.7), CFrame.new(0, 0, -0.95), Color3.fromRGB(226, 196, 140))
end

function AccessoryBuilders.Bat(model, body, def, add)
	add("Bat", Vector3.new(0.28, 2.2, 0.28), CFrame.new(1.45, 0.5, 0) * CFrame.Angles(0, 0, math.rad(35)), Color3.fromRGB(120, 82, 44))
end

function AccessoryBuilders.Trunk(model, body, def, add)
	add("Trunk", Vector3.new(0.44, 1.4, 0.44), CFrame.new(0, 0.45, -1.0) * CFrame.Angles(math.rad(18), 0, 0), def.Body)
	add("EarL", Vector3.new(0.18, 1.0, 1.0), CFrame.new(-1.15, 0.9, 0), def.Body)
	add("EarR", Vector3.new(0.18, 1.0, 1.0), CFrame.new(1.15, 0.9, 0), def.Body)
end

function AccessoryBuilders.Cactus(model, body, def, add)
	add("Cactus", Vector3.new(0.55, 1.5, 0.55), CFrame.new(0.7, 1.35, 0.35), Color3.fromRGB(58, 168, 74))
	add("CactusArm", Vector3.new(0.4, 0.7, 0.4), CFrame.new(1.1, 1.5, 0.35), Color3.fromRGB(58, 168, 74))
	add("CactusFlower", Vector3.new(0.4, 0.3, 0.4), CFrame.new(0.7, 2.2, 0.35), Color3.fromRGB(255, 110, 170))
end

function AccessoryBuilders.TreeTop(model, body, def, add)
	add("TrunkTop", Vector3.new(0.5, 0.8, 0.5), CFrame.new(0, 1.5, 0), Color3.fromRGB(110, 74, 36))
	local top = add("Leaves", Vector3.new(2.4, 1.5, 2.4), CFrame.new(0, 2.5, 0), Color3.fromRGB(64, 160, 66))
	top.Shape = Enum.PartType.Ball
end

function AccessoryBuilders.CupHead(model, body, def, add)
	-- the head becomes a coffee cup: white cup, coffee surface, handle
	add("Cup", Vector3.new(1.7, 1.1, 1.7), CFrame.new(0, 1.85, 0), Color3.fromRGB(250, 250, 250))
	add("Coffee", Vector3.new(1.5, 0.14, 1.5), CFrame.new(0, 2.42, 0), Color3.fromRGB(112, 70, 34))
	add("Handle", Vector3.new(0.2, 0.7, 0.7), CFrame.new(1.05, 1.85, 0), Color3.fromRGB(250, 250, 250))
end

function AccessoryBuilders.Swords(model, body, def, add)
	add("SwordL", Vector3.new(0.14, 1.9, 0.3), CFrame.new(-1.5, 0.4, 0) * CFrame.Angles(0, 0, math.rad(-30)), Color3.fromRGB(200, 205, 215))
	add("SwordR", Vector3.new(0.14, 1.9, 0.3), CFrame.new(1.5, 0.4, 0) * CFrame.Angles(0, 0, math.rad(30)), Color3.fromRGB(200, 205, 215))
end

function AccessoryBuilders.Tutu(model, body, def, add)
	local tutu = add("Tutu", Vector3.new(2.9, 0.55, 2.9), CFrame.new(0, -0.45, 0), Color3.fromRGB(255, 160, 205))
	tutu.Shape = Enum.PartType.Cylinder
end

function AccessoryBuilders.Banana(model, body, def, add)
	add("BananaTip", Vector3.new(0.4, 0.9, 0.4), CFrame.new(0, 1.75, 0) * CFrame.Angles(0, 0, math.rad(12)), Color3.fromRGB(110, 76, 40))
	add("PeelL", Vector3.new(0.3, 1.1, 0.16), CFrame.new(-0.95, 0.7, 0) * CFrame.Angles(0, 0, math.rad(38)), Color3.fromRGB(250, 230, 110))
	add("PeelR", Vector3.new(0.3, 1.1, 0.16), CFrame.new(0.95, 0.7, 0) * CFrame.Angles(0, 0, math.rad(-38)), Color3.fromRGB(250, 230, 110))
end

function AccessoryBuilders.SharkFin(model, body, def, add)
	add("Fin", Vector3.new(0.18, 1.1, 1.2), CFrame.new(0, 1.45, 0.15) * CFrame.Angles(math.rad(-18), 0, 0), def.Accent)
	add("TailShark", Vector3.new(0.16, 1.2, 0.8), CFrame.new(0, 0.4, 1.15) * CFrame.Angles(math.rad(24), 0, 0), def.Body)
end

function AccessoryBuilders.Sneakers(model, body, def, add)
	add("ShoeL", Vector3.new(0.85, 0.4, 1.5), CFrame.new(-0.55, -1.35, -0.15), Color3.fromRGB(70, 130, 255))
	add("ShoeR", Vector3.new(0.85, 0.4, 1.5), CFrame.new(0.55, -1.35, -0.15), Color3.fromRGB(255, 80, 80))
end

function AccessoryBuilders.Wings(model, body, def, add)
	add("WingL", Vector3.new(2.0, 0.16, 1.1), CFrame.new(-1.8, 0.6, 0.2) * CFrame.Angles(0, 0, math.rad(14)), def.Accent)
	add("WingR", Vector3.new(2.0, 0.16, 1.1), CFrame.new(1.8, 0.6, 0.2) * CFrame.Angles(0, 0, math.rad(-14)), def.Accent)
end

function AccessoryBuilders.Propeller(model, body, def, add)
	add("Mast", Vector3.new(0.2, 0.9, 0.2), CFrame.new(0, 1.7, 0), Color3.fromRGB(90, 90, 96))
	local prop = add("Propeller", Vector3.new(3.4, 0.14, 0.5), CFrame.new(0, 2.2, 0), Color3.fromRGB(60, 60, 66))
	prop.Name = "PropellerSpin" -- the spawn manager spins parts with this name
end

function AccessoryBuilders.SaturnRing(model, body, def, add)
	local ring = add("Ring", Vector3.new(4.4, 0.16, 4.4), CFrame.new(0, 0.1, 0) * CFrame.Angles(math.rad(16), 0, math.rad(8)), Color3.fromRGB(240, 200, 110))
	ring.Shape = Enum.PartType.Cylinder
end

function AccessoryBuilders.Stars(model, body, def, add)
	for i = 1, 3 do
		local star = add("Star" .. i, Vector3.new(0.42, 0.42, 0.42), CFrame.new(math.sin(i * 2.1) * 1.5, 1.4 + (i % 2) * 0.7, math.cos(i * 2.1) * 1.5), Color3.fromRGB(255, 226, 90), Enum.Material.Neon)
		star.Shape = Enum.PartType.Ball
	end
end

function AccessoryBuilders.LongNeck(model, body, def, add)
	add("Neck", Vector3.new(0.6, 2.0, 0.6), CFrame.new(0, 1.6, -0.4), def.Body)
	add("OssiconeL", Vector3.new(0.2, 0.6, 0.2), CFrame.new(-0.3, 3.1, -0.4), def.Accent)
	add("OssiconeR", Vector3.new(0.2, 0.6, 0.2), CFrame.new(0.3, 3.1, -0.4), def.Accent)
end

function AccessoryBuilders.FridgeBody(model, body, def, add)
	add("FridgeDoor", Vector3.new(1.9, 2.5, 0.18), CFrame.new(0, 0.1, -0.85), Color3.fromRGB(228, 238, 244))
	add("FridgeLine", Vector3.new(1.9, 0.12, 0.2), CFrame.new(0, 0.75, -0.86), Color3.fromRGB(160, 175, 185))
	add("FridgeHandle", Vector3.new(0.16, 0.9, 0.16), CFrame.new(0.7, 0.3, -1.0), Color3.fromRGB(150, 160, 170))
	add("Magnet", Vector3.new(0.4, 0.4, 0.1), CFrame.new(-0.4, 1.1, -0.97), Color3.fromRGB(255, 90, 90), Enum.Material.Neon)
end

function AccessoryBuilders.Cap(model, body, def, add)
	add("CapTop", Vector3.new(1.5, 0.35, 1.5), CFrame.new(0, 1.5, 0), Color3.fromRGB(60, 90, 200))
	add("CapBrim", Vector3.new(1.4, 0.14, 0.9), CFrame.new(0, 1.38, -1.1), Color3.fromRGB(60, 90, 200))
end

-- Build one brainrot model. kind: "Wild" | "Carried" | "Displayed" | "Bandit"
function Factory.Build(def, mutation)
	local model = Instance.new("Model")
	model.Name = Config.DisplayName(def, mutation)

	local rarity = Config.Rarities[def.Rarity]
	local scale = 0.9 + def.Rarity * 0.09

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(2.1, 2.3, 1.6) * scale
	body.Color = def.Body
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = true
	body.Parent = model
	model.PrimaryPart = body

	local function add(name, size, offset, color, material)
		local p = part(model, name, size * scale, body.CFrame * offset, color, material)
		weldTo(p, body)
		return p
	end

	-- head + face (skipped when an accessory replaces the head, e.g. CupHead)
	local hasCupHead = false
	for _, key in ipairs(def.Accessory) do
		if key == "CupHead" then
			hasCupHead = true
		end
	end
	if not hasCupHead then
		add("Head", Vector3.new(1.5, 1.3, 1.4), CFrame.new(0, 1.55, 0), def.Body)
		add("EyeL", Vector3.new(0.26, 0.4, 0.1), CFrame.new(-0.36, 1.7, -0.72), Color3.fromRGB(20, 20, 25))
		add("EyeR", Vector3.new(0.26, 0.4, 0.1), CFrame.new(0.36, 1.7, -0.72), Color3.fromRGB(20, 20, 25))
		add("Smile", Vector3.new(0.6, 0.12, 0.1), CFrame.new(0, 1.28, -0.72), Color3.fromRGB(20, 20, 25))
	else
		add("EyeL", Vector3.new(0.26, 0.4, 0.1), CFrame.new(-0.36, 1.95, -0.88), Color3.fromRGB(20, 20, 25))
		add("EyeR", Vector3.new(0.26, 0.4, 0.1), CFrame.new(0.36, 1.95, -0.88), Color3.fromRGB(20, 20, 25))
	end
	add("FootL", Vector3.new(0.7, 0.35, 1.1), CFrame.new(-0.55, -1.3, -0.1), def.Accent)
	add("FootR", Vector3.new(0.7, 0.35, 1.1), CFrame.new(0.55, -1.3, -0.1), def.Accent)

	for _, key in ipairs(def.Accessory) do
		local builder = AccessoryBuilders[key]
		if builder then
			builder(model, body, def, add)
		end
	end

	-- sparkles: colour by mutation first, then rarity
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "Sparkles"
	if mutation == "Golden" then
		emitter.Color = ColorSequence.new(Color3.fromRGB(255, 214, 64))
		emitter.Rate = 26
	elseif mutation == "Shiny" then
		emitter.Color = ColorSequence.new(Color3.fromRGB(225, 235, 255))
		emitter.Rate = 18
	else
		emitter.Color = ColorSequence.new(rarity.Color)
		emitter.Rate = 2 + def.Rarity * 3
	end
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Size = NumberSequence.new(0.35)
	emitter.Lifetime = NumberRange.new(0.5, 1.1)
	emitter.Speed = NumberRange.new(0.4, 1.2)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.LightEmission = 0.6
	emitter.Parent = body

	-- nameplate
	local gui = Instance.new("BillboardGui")
	gui.Name = "Nameplate"
	gui.Size = UDim2.fromOffset(220, 62)
	gui.StudsOffset = Vector3.new(0, 3.1 * scale, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 90
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0.55, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = Config.DisplayName(def, mutation)
	nameLabel.TextColor3 = rarity.Color
	nameLabel.TextStrokeTransparency = 0.35
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.TextSize = 20
	nameLabel.Parent = gui
	local infoLabel = Instance.new("TextLabel")
	infoLabel.Name = "InfoLabel"
	infoLabel.Position = UDim2.new(0, 0, 0.55, 0)
	infoLabel.Size = UDim2.new(1, 0, 0.45, 0)
	infoLabel.BackgroundTransparency = 1
	infoLabel.Text = rarity.Name .. "  •  $" .. tostring(Config.BrainrotIncome(def, mutation)) .. "/s"
	infoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	infoLabel.TextStrokeTransparency = 0.4
	infoLabel.Font = Enum.Font.FredokaOne
	infoLabel.TextSize = 15
	infoLabel.Parent = gui
	gui.Parent = body

	model:SetAttribute("BrainrotName", def.Name)
	model:SetAttribute("Rarity", def.Rarity)
	model:SetAttribute("Mutation", mutation or "None")
	model:SetAttribute("Income", Config.BrainrotIncome(def, mutation))
	return model
end

-- A blocky bandit NPC the event manager walks around.
function Factory.BuildBandit()
	local model = Instance.new("Model")
	model.Name = "BrainrotBandit"
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(2.2, 2.6, 1.6)
	body.Color = Color3.fromRGB(52, 52, 60)
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = false
	body.Parent = model
	model.PrimaryPart = body
	local function add(name, size, offset, color)
		local p = part(model, name, size, body.CFrame * offset, color)
		weldTo(p, body)
		return p
	end
	add("Head", Vector3.new(1.5, 1.3, 1.4), CFrame.new(0, 1.8, 0), Color3.fromRGB(240, 200, 150))
	add("Mask", Vector3.new(1.56, 0.42, 1.46), CFrame.new(0, 1.92, 0), Color3.fromRGB(15, 15, 18))
	add("EyeL", Vector3.new(0.24, 0.3, 0.1), CFrame.new(-0.35, 1.92, -0.74), Color3.fromRGB(255, 255, 255))
	add("EyeR", Vector3.new(0.24, 0.3, 0.1), CFrame.new(0.35, 1.92, -0.74), Color3.fromRGB(255, 255, 255))
	add("Bag", Vector3.new(1.5, 1.7, 0.8), CFrame.new(0, 0.5, 1.2), Color3.fromRGB(150, 118, 74))
	add("BagTie", Vector3.new(0.5, 0.4, 0.5), CFrame.new(0, 1.55, 1.2), Color3.fromRGB(110, 84, 50))
	local gui = Instance.new("BillboardGui")
	gui.Name = "Nameplate"
	gui.Size = UDim2.fromOffset(200, 40)
	gui.StudsOffset = Vector3.new(0, 3.2, 0)
	gui.AlwaysOnTop = true
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "🕵️ BANDIT! Tackle him!"
	label.TextColor3 = Color3.fromRGB(255, 90, 90)
	label.TextStrokeTransparency = 0.3
	label.Font = Enum.Font.FredokaOne
	label.TextSize = 18
	label.Parent = gui
	gui.Parent = body
	return model
end

return Factory
