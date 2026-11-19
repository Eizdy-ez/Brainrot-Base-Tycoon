-- BrainrotFactory.luau — builds blocky brainrot characters out of plain
-- Parts from the data definitions in Config. No external assets: every
-- character in the roster is an original design standing on the same
-- humanoid body, with its absurd creature/object identity carried by
-- its own accessory set (toaster head, sock tentacles, satellite dish
-- with electric sparks, whale tail, tornado swirls…), so each silhouette
-- still reads differently at a glance. Also builds the bandit NPC.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local Factory = {}

local INK = Color3.fromRGB(20, 20, 25)
local WHITE = Color3.fromRGB(255, 255, 255)
local BLACK = Color3.fromRGB(15, 15, 18)
local GOLD = Color3.fromRGB(255, 205, 60)

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

-- Accessory builders: each receives the model, its body part, the
-- definition, a helper to add welded parts in body-local space, and an
-- anchors table (HeadPos/FaceZ/TopY/HalfW/HalfH/HalfD/Scale) computed
-- from the character's body plan, so parts land right at any rarity
-- scale. Forward is -Z; offsets are unscaled body-local units.
local AccessoryBuilders = {}

function AccessoryBuilders.ToasterHead(model, body, def, add, A)
	-- a chrome toaster for a head, two toast slices popping out
	add("Toaster", Vector3.new(1.9, 1.2, 1.3), CFrame.new(0, 1.7, 0), Color3.fromRGB(196, 200, 208), Enum.Material.Metal)
	add("ToastSlot", Vector3.new(1.5, 0.16, 0.9), CFrame.new(0, 2.32, 0), BLACK)
	add("ToastL", Vector3.new(0.62, 0.8, 0.9), CFrame.new(-0.4, 2.55, 0), Color3.fromRGB(246, 208, 140))
	add("ToastR", Vector3.new(0.62, 0.62, 0.9), CFrame.new(0.4, 2.46, 0), Color3.fromRGB(240, 196, 128))
	add("Lever", Vector3.new(0.18, 0.5, 0.18), CFrame.new(1.05, 1.7, 0), def.Accent, Enum.Material.Neon)
	add("EyeL", Vector3.new(0.26, 0.4, 0.1), CFrame.new(-0.4, 1.8, -0.68), INK)
	add("EyeR", Vector3.new(0.26, 0.4, 0.1), CFrame.new(0.4, 1.8, -0.68), INK)
	local dial = add("Dial", Vector3.new(0.42, 0.42, 0.42), CFrame.new(0, 1.3, -0.6), def.Accent, Enum.Material.Neon)
	dial.Shape = Enum.PartType.Ball
end

function AccessoryBuilders.DogEars(model, body, def, add, A)
	add("EarL", Vector3.new(0.4, 0.8, 0.2), CFrame.new(A.HeadPos.X - 0.62, A.HeadPos.Y + 0.8, A.HeadPos.Z) * CFrame.Angles(0, 0, math.rad(18)), def.Accent)
	add("EarR", Vector3.new(0.4, 0.8, 0.2), CFrame.new(A.HeadPos.X + 0.62, A.HeadPos.Y + 0.8, A.HeadPos.Z) * CFrame.Angles(0, 0, math.rad(-18)), def.Accent)
end

function AccessoryBuilders.Snout(model, body, def, add, A)
	add("Snout", Vector3.new(0.7, 0.5, 0.6), CFrame.new(0, A.HeadPos.Y - 0.1, A.FaceZ - 0.25), def.Accent)
	add("Nose", Vector3.new(0.3, 0.22, 0.3), CFrame.new(0, A.HeadPos.Y + 0.03, A.FaceZ - 0.55), BLACK)
	-- a water drop riding on its back
	local drop = add("Drop", Vector3.new(0.7, 0.9, 0.7), CFrame.new(0, A.HalfH + 0.35, 0.4), def.Accent, Enum.Material.Glass)
	drop.Shape = Enum.PartType.Ball
	drop.Transparency = 0.25
end

function AccessoryBuilders.WagTail(model, body, def, add, A)
	add("Tail", Vector3.new(0.28, 0.28, 1.0), CFrame.new(0, 0.55, A.HalfD + 0.25) * CFrame.Angles(math.rad(-24), 0, 0), def.Accent)
end

function AccessoryBuilders.MopHair(model, body, def, add, A)
	-- a mop head of yarn strands standing in for hair
	for i = -2, 2 do
		add("Strand" .. (i + 3), Vector3.new(0.24, 1.5, 0.24),
			CFrame.new(i * 0.3, 2.35, 0) * CFrame.Angles(math.rad(i * 5), 0, math.rad(i * 7)), def.Accent)
	end
	add("MopBand", Vector3.new(1.5, 0.3, 1.4), CFrame.new(0, 2.95, 0), Color3.fromRGB(170, 178, 190), Enum.Material.Metal)
end

function AccessoryBuilders.Tentacles(model, body, def, add, A)
	-- six striped sock tentacles around the blob's base
	for i = 1, 6 do
		local a = (i / 6) * math.pi * 2
		local x, z = math.sin(a) * (A.HalfW + 0.1), math.cos(a) * (A.HalfD + 0.1)
		local color = (i % 2 == 0) and def.Accent or WHITE
		add("Sock" .. i, Vector3.new(0.5, 0.45, 0.9), CFrame.new(x, -A.HalfH + 0.1, z) * CFrame.Angles(0, -a, 0), color)
	end
end

function AccessoryBuilders.LampHead(model, body, def, add, A)
	-- a glowing lampshade head on a brass neck
	add("Neck", Vector3.new(0.34, 0.5, 0.34), CFrame.new(0, 1.35, 0), Color3.fromRGB(196, 160, 90), Enum.Material.Metal)
	local shade = add("Shade", Vector3.new(1.9, 1.15, 1.9), CFrame.new(0, 2.05, 0), def.Accent, Enum.Material.Neon)
	shade.Shape = Enum.PartType.Cylinder
	local bulb = add("BulbGlow", Vector3.new(1.0, 0.5, 1.0), CFrame.new(0, 1.5, 0), WHITE, Enum.Material.Neon)
	bulb.Shape = Enum.PartType.Ball
	add("EyeL", Vector3.new(0.26, 0.4, 0.1), CFrame.new(-0.38, 2.05, -0.92), INK)
	add("EyeR", Vector3.new(0.26, 0.4, 0.1), CFrame.new(0.38, 2.05, -0.92), INK)
end

function AccessoryBuilders.CookieDisc(model, body, def, add, A)
	-- a big cookie disc worn on the front of the torso
	local disc = add("Cookie", Vector3.new(2.7, 0.55, 2.7), CFrame.new(0, 0, -A.HalfD - 0.1) * CFrame.Angles(math.rad(90), 0, 0), def.Body)
	disc.Shape = Enum.PartType.Cylinder
end

function AccessoryBuilders.ChocChips(model, body, def, add, A)
	local spots = { { -0.6, 0.5 }, { 0.55, 0.85 }, { 0.1, -0.3 }, { -0.45, -0.75 }, { 0.7, -0.15 } }
	for i, spot in ipairs(spots) do
		local chip = add("Chip" .. i, Vector3.new(0.3, 0.3, 0.3), CFrame.new(spot[1], spot[2], -A.HalfD - 0.42), def.Accent)
		chip.Shape = Enum.PartType.Ball
	end
end

function AccessoryBuilders.Antenna(model, body, def, add, A)
	add("AntennaRod", Vector3.new(0.14, 0.9, 0.14), CFrame.new(0, A.TopY + 0.4, 0), def.Accent, Enum.Material.Metal)
	local tip = add("AntennaTip", Vector3.new(0.4, 0.4, 0.4), CFrame.new(0, A.TopY + 0.95, 0), Color3.fromRGB(255, 92, 92), Enum.Material.Neon)
	tip.Shape = Enum.PartType.Ball
end

function AccessoryBuilders.PumpkinRibs(model, body, def, add, A)
	for i = -1, 1 do
		add("Rib" .. (i + 2), Vector3.new(0.22, 2.0, 0.22), CFrame.new(i * 0.8, 0, A.FaceZ + 0.12), Color3.fromRGB(214, 106, 26))
	end
	add("Stem", Vector3.new(0.34, 0.5, 0.34), CFrame.new(0, A.HalfH + 0.2, 0) * CFrame.Angles(0, 0, math.rad(12)), Color3.fromRGB(84, 140, 60))
end

function AccessoryBuilders.EarTufts(model, body, def, add, A)
	-- owl ear tufts sprouting from the top of the head
	add("TuftL", Vector3.new(0.3, 0.6, 0.16), CFrame.new(-0.62, A.TopY + 0.18, 0) * CFrame.Angles(0, 0, math.rad(20)), def.Accent)
	add("TuftR", Vector3.new(0.3, 0.6, 0.16), CFrame.new(0.62, A.TopY + 0.18, 0) * CFrame.Angles(0, 0, math.rad(-20)), def.Accent)
end

function AccessoryBuilders.Wings(model, body, def, add, A)
	add("WingL", Vector3.new(2.0, 0.16, 1.1), CFrame.new(-(A.HalfW + 0.75), 0.6, 0.2) * CFrame.Angles(0, 0, math.rad(14)), def.Accent)
	add("WingR", Vector3.new(2.0, 0.16, 1.1), CFrame.new(A.HalfW + 0.75, 0.6, 0.2) * CFrame.Angles(0, 0, math.rad(-14)), def.Accent)
end

function AccessoryBuilders.ForkAntenna(model, body, def, add, A)
	add("ForkHandle", Vector3.new(0.16, 1.0, 0.16), CFrame.new(0, A.TopY + 0.45, 0), def.Accent, Enum.Material.Metal)
	for i = -1, 1 do
		add("ForkProng" .. (i + 2), Vector3.new(0.12, 0.45, 0.12), CFrame.new(i * 0.2, A.TopY + 1.15, 0), def.Accent, Enum.Material.Metal)
	end
	add("ForkBar", Vector3.new(0.6, 0.14, 0.14), CFrame.new(0, A.TopY + 0.95, 0), def.Accent, Enum.Material.Metal)
end

function AccessoryBuilders.CrimpEdge(model, body, def, add, A)
	-- the crimped ravioli rim peeking out behind the body
	add("Crimp", Vector3.new(2.5, 2.7, 0.5), CFrame.new(0, 0, 0.4), Color3.fromRGB(232, 200, 140))
end

function AccessoryBuilders.DiscoBall(model, body, def, add, A)
	-- mushroom cap first, then the mirror ball on top of it
	local cap = add("Cap", Vector3.new(2.3, 0.7, 2.3), CFrame.new(0, A.TopY + 0.1, 0), def.Body)
	cap.Shape = Enum.PartType.Cylinder
	for i = 1, 3 do
		local dot = add("CapDot" .. i, Vector3.new(0.34, 0.34, 0.34), CFrame.new(-0.6 + i * 0.45, A.TopY + 0.5, -0.4 + (i % 2) * 0.7), WHITE)
		dot.Shape = Enum.PartType.Ball
	end
	local ball = add("DiscoBall", Vector3.new(1.15, 1.15, 1.15), CFrame.new(0, A.TopY + 1.15, 0), def.Accent, Enum.Material.Metal)
	ball.Shape = Enum.PartType.Ball
	for i = 1, 4 do
		local a = i * math.pi / 2
		add("Mirror" .. i, Vector3.new(0.3, 0.3, 0.08),
			CFrame.new(math.sin(a) * 0.58, A.TopY + 1.15, math.cos(a) * 0.58) * CFrame.Angles(0, a, 0), WHITE, Enum.Material.Neon)
	end
end

function AccessoryBuilders.Headphones(model, body, def, add, A)
	add("Band", Vector3.new(1.7, 0.22, 0.3), CFrame.new(0, 2.05, 0), BLACK)
	add("CupL", Vector3.new(0.3, 0.7, 0.7), CFrame.new(-0.85, 1.6, 0), BLACK)
	add("CupR", Vector3.new(0.3, 0.7, 0.7), CFrame.new(0.85, 1.6, 0), BLACK)
end

function AccessoryBuilders.TeapotHead(model, body, def, add, A)
	-- a round glass teapot head: spout nose, handle ear, golden lid knob
	local pot = add("Teapot", Vector3.new(1.7, 1.35, 1.7), CFrame.new(0, 1.75, 0), Color3.fromRGB(120, 200, 220), Enum.Material.Glass)
	pot.Shape = Enum.PartType.Ball
	add("Spout", Vector3.new(0.34, 0.34, 0.9), CFrame.new(0, 1.6, -1.05) * CFrame.Angles(math.rad(-32), 0, 0), Color3.fromRGB(120, 200, 220), Enum.Material.Glass)
	add("Handle", Vector3.new(0.22, 0.8, 0.6), CFrame.new(0.95, 1.8, 0), Color3.fromRGB(120, 200, 220), Enum.Material.Glass)
	local knob = add("LidKnob", Vector3.new(0.4, 0.4, 0.4), CFrame.new(0, 2.5, 0), def.Accent, Enum.Material.Metal)
	knob.Shape = Enum.PartType.Ball
	add("EyeL", Vector3.new(0.26, 0.4, 0.1), CFrame.new(-0.36, 1.95, -0.82), INK)
	add("EyeR", Vector3.new(0.26, 0.4, 0.1), CFrame.new(0.36, 1.95, -0.82), INK)
end

function AccessoryBuilders.PirateHat(model, body, def, add, A)
	local brim = add("HatBrim", Vector3.new(1.9, 0.18, 1.5), CFrame.new(0, 2.68, 0), BLACK)
	brim.Shape = Enum.PartType.Cylinder
	add("HatTop", Vector3.new(1.3, 0.5, 1.1), CFrame.new(0, 2.9, 0), BLACK)
	local skull = add("Skull", Vector3.new(0.44, 0.44, 0.44), CFrame.new(0, 2.85, -0.58), WHITE)
	skull.Shape = Enum.PartType.Ball
end

function AccessoryBuilders.JellyDome(model, body, def, add, A)
	-- a glass astronaut helmet over the head, its rim a metal ring —
	-- the jellyfish bell now crowns the humanoid like a space helmet
	local dome = add("Dome", Vector3.new(2.3, 1.9, 2.3), CFrame.new(0, 1.62, 0), Color3.fromRGB(200, 235, 255), Enum.Material.Glass)
	dome.Shape = Enum.PartType.Ball
	dome.Transparency = 0.45
	local ring = add("DomeRing", Vector3.new(2.15, 0.3, 2.15), CFrame.new(0, 0.95, 0), def.Accent, Enum.Material.Metal)
	ring.Shape = Enum.PartType.Cylinder
end

function AccessoryBuilders.JellyTentacles(model, body, def, add, A)
	-- jelly strands dangling from the helmet rim past the shoulders
	for i = -2, 2 do
		if i ~= 0 then
			add("Tentacle" .. (i + 3), Vector3.new(0.26, 1.15, 0.26),
				CFrame.new(i * 0.44, 0.45, (i % 2 == 0) and 0.55 or -0.55) * CFrame.Angles(math.rad(i * 4), 0, math.rad(i * 5)), def.Body)
		end
	end
end

function AccessoryBuilders.Backpack(model, body, def, add, A)
	add("Tank", Vector3.new(1.1, 1.5, 0.6), CFrame.new(0, 0.3, A.HalfD + 0.3), Color3.fromRGB(210, 214, 224), Enum.Material.Metal)
	add("TankLight", Vector3.new(0.3, 0.3, 0.14), CFrame.new(0, 0.75, A.HalfD + 0.62), Color3.fromRGB(255, 92, 92), Enum.Material.Neon)
end

function AccessoryBuilders.BroomStick(model, body, def, add, A)
	-- the broom handle running front-to-back under the body: he rides it
	add("Handle", Vector3.new(0.3, 3.6, 0.3), CFrame.new(0, -A.HalfH - 0.28, 0.45) * CFrame.Angles(math.rad(90), 0, 0), Color3.fromRGB(120, 82, 44))
end

function AccessoryBuilders.Bristles(model, body, def, add, A)
	-- a fan of straw bristles at the back end of the broom
	for i = -1, 1 do
		add("Bristle" .. (i + 2), Vector3.new(0.55, 1.1, 0.55),
			CFrame.new(i * 0.4, -A.HalfH - 0.35, 2.35) * CFrame.Angles(math.rad(14), 0, math.rad(i * 10)), def.Accent)
	end
end

function AccessoryBuilders.Wheels(model, body, def, add, A)
	-- two little motorcycle wheels under the broom
	local wf = add("WheelF", Vector3.new(1.0, 0.24, 1.0), CFrame.new(0, -A.HalfH - 0.55, -0.9) * CFrame.Angles(0, 0, math.rad(90)), BLACK)
	wf.Shape = Enum.PartType.Cylinder
	local wb = add("WheelB", Vector3.new(1.0, 0.24, 1.0), CFrame.new(0, -A.HalfH - 0.55, 1.5) * CFrame.Angles(0, 0, math.rad(90)), BLACK)
	wb.Shape = Enum.PartType.Cylinder
end

function AccessoryBuilders.Shades(model, body, def, add, A)
	add("ShadeL", Vector3.new(0.55, 0.4, 0.12), CFrame.new(A.HeadPos.X - 0.42, A.HeadPos.Y + 0.17, A.FaceZ - 0.04), BLACK)
	add("ShadeR", Vector3.new(0.55, 0.4, 0.12), CFrame.new(A.HeadPos.X + 0.42, A.HeadPos.Y + 0.17, A.FaceZ - 0.04), BLACK)
	add("ShadeBar", Vector3.new(1.4, 0.12, 0.12), CFrame.new(A.HeadPos.X, A.HeadPos.Y + 0.27, A.FaceZ - 0.04), BLACK)
end

function AccessoryBuilders.DragonWings(model, body, def, add, A)
	add("DWingL", Vector3.new(1.7, 0.14, 0.9), CFrame.new(-(A.HalfW + 0.7), 0.75, 0.5) * CFrame.Angles(0, math.rad(-18), math.rad(28)), def.Accent)
	add("DWingR", Vector3.new(1.7, 0.14, 0.9), CFrame.new(A.HalfW + 0.7, 0.75, 0.5) * CFrame.Angles(0, math.rad(18), math.rad(-28)), def.Accent)
	-- dragonfruit scale fins as a crest over the head and shoulders
	for i = 0, 2 do
		add("Fin" .. i, Vector3.new(0.16, 0.6, 0.4), CFrame.new(0, A.HalfH + 0.1, -0.6 + i * 0.7), def.Accent)
	end
end

function AccessoryBuilders.SatDish(model, body, def, add, A)
	-- a satellite dish worn like a cap, tilted up at the sky, with a
	-- feed arm and a glowing receiver tip
	add("DishStalk", Vector3.new(0.22, 0.5, 0.22), CFrame.new(0, A.TopY + 0.2, 0), Color3.fromRGB(150, 158, 175), Enum.Material.Metal)
	local dish = add("Dish", Vector3.new(2.3, 0.4, 2.3), CFrame.new(0, A.TopY + 0.62, 0) * CFrame.Angles(math.rad(-32), 0, 0), Color3.fromRGB(214, 220, 232), Enum.Material.Metal)
	dish.Shape = Enum.PartType.Cylinder
	add("DishArm", Vector3.new(0.14, 0.14, 1.1), CFrame.new(0, A.TopY + 0.95, -0.35) * CFrame.Angles(math.rad(-32), 0, 0), Color3.fromRGB(150, 158, 175), Enum.Material.Metal)
	local tip = add("DishTip", Vector3.new(0.36, 0.36, 0.36), CFrame.new(0, A.TopY + 1.12, -0.62), def.Accent, Enum.Material.Neon)
	tip.Shape = Enum.PartType.Ball
end

function AccessoryBuilders.SolarPanels(model, body, def, add, A)
	-- twin solar-panel wings on the back, dark blue with neon seams
	for _, side in ipairs({ -1, 1 }) do
		local panel = add("Panel" .. (side < 0 and "L" or "R"), Vector3.new(1.9, 1.5, 0.14),
			CFrame.new(side * (A.HalfW + 0.55), 0.45, A.HalfD + 0.28) * CFrame.Angles(0, math.rad(side * -16), math.rad(side * 10)),
			Color3.fromRGB(28, 48, 110), Enum.Material.SmoothPlastic)
		panel.Name = "SolarPanel"
		add("PanelSeam" .. (side < 0 and "L" or "R"), Vector3.new(1.94, 0.16, 0.16),
			CFrame.new(side * (A.HalfW + 0.55), 0.45, A.HalfD + 0.36) * CFrame.Angles(0, math.rad(side * -16), math.rad(side * 10)),
			def.Accent, Enum.Material.Neon)
	end
end

function AccessoryBuilders.SparkCoils(model, body, def, add, A)
	-- twin tesla coils on the shoulders, and a live spark emitter on
	-- the chest core: this robot visibly crackles with electricity
	for _, side in ipairs({ -1, 1 }) do
		add("CoilPost" .. (side < 0 and "L" or "R"), Vector3.new(0.2, 0.7, 0.2), CFrame.new(side * (A.HalfW + 0.05), A.HalfH + 0.3, 0), Color3.fromRGB(150, 158, 175), Enum.Material.Metal)
		for j = 0, 2 do
			local coil = add("Coil" .. (side < 0 and "L" or "R") .. j, Vector3.new(0.52, 0.14, 0.52),
				CFrame.new(side * (A.HalfW + 0.05), A.HalfH + 0.12 + j * 0.2, 0), def.Accent, Enum.Material.Neon)
			coil.Shape = Enum.PartType.Cylinder
		end
		local orb = add("CoilOrb" .. (side < 0 and "L" or "R"), Vector3.new(0.42, 0.42, 0.42), CFrame.new(side * (A.HalfW + 0.05), A.HalfH + 0.72, 0), Color3.fromRGB(225, 245, 255), Enum.Material.Neon)
		orb.Shape = Enum.PartType.Ball
	end
	local core = add("SparkCore", Vector3.new(0.7, 0.7, 0.3), CFrame.new(0, 0.15, -A.HalfD - 0.08), def.Accent, Enum.Material.Neon)
	core.Shape = Enum.PartType.Ball
	local sparks = Instance.new("ParticleEmitter")
	sparks.Name = "ElectricSparks"
	sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparks.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(160, 235, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
	})
	sparks.Size = NumberSequence.new(0.28)
	sparks.Rate = 22
	sparks.Lifetime = NumberRange.new(0.25, 0.6)
	sparks.Speed = NumberRange.new(2.5, 5)
	sparks.SpreadAngle = Vector2.new(180, 180)
	sparks.LightEmission = 1
	sparks.Parent = core
end

function AccessoryBuilders.Horns(model, body, def, add, A)
	add("HornL", Vector3.new(0.26, 0.7, 0.26), CFrame.new(A.HeadPos.X - 0.5, A.HeadPos.Y + 0.95, A.HeadPos.Z) * CFrame.Angles(0, 0, math.rad(16)), WHITE)
	add("HornR", Vector3.new(0.26, 0.7, 0.26), CFrame.new(A.HeadPos.X + 0.5, A.HeadPos.Y + 0.95, A.HeadPos.Z) * CFrame.Angles(0, 0, math.rad(-16)), WHITE)
end

function AccessoryBuilders.DragonTail(model, body, def, add, A)
	add("Tail", Vector3.new(0.5, 0.5, 1.6), CFrame.new(0, -0.2, A.HalfD + 0.6) * CFrame.Angles(math.rad(18), 0, 0), def.Body)
	add("TailSpade", Vector3.new(0.8, 0.7, 0.16), CFrame.new(0, 0.05, A.HalfD + 1.45), def.Accent)
end

function AccessoryBuilders.FoxEars(model, body, def, add, A)
	add("FEarL", Vector3.new(0.45, 0.85, 0.2), CFrame.new(A.HeadPos.X - 0.5, A.HeadPos.Y + 0.9, A.HeadPos.Z) * CFrame.Angles(0, 0, math.rad(12)), def.Body)
	add("FEarR", Vector3.new(0.45, 0.85, 0.2), CFrame.new(A.HeadPos.X + 0.5, A.HeadPos.Y + 0.9, A.HeadPos.Z) * CFrame.Angles(0, 0, math.rad(-12)), def.Body)
	local tipL = add("FEarTipL", Vector3.new(0.3, 0.3, 0.3), CFrame.new(A.HeadPos.X - 0.6, A.HeadPos.Y + 1.28, A.HeadPos.Z), def.Accent, Enum.Material.Neon)
	tipL.Shape = Enum.PartType.Ball
	local tipR = add("FEarTipR", Vector3.new(0.3, 0.3, 0.3), CFrame.new(A.HeadPos.X + 0.6, A.HeadPos.Y + 1.28, A.HeadPos.Z), def.Accent, Enum.Material.Neon)
	tipR.Shape = Enum.PartType.Ball
end

function AccessoryBuilders.FoxMuzzle(model, body, def, add, A)
	add("Muzzle", Vector3.new(0.75, 0.5, 0.65), CFrame.new(0, A.HeadPos.Y - 0.15, A.FaceZ - 0.25), WHITE)
	add("FoxNose", Vector3.new(0.28, 0.2, 0.28), CFrame.new(0, A.HeadPos.Y, A.FaceZ - 0.58), BLACK)
end

function AccessoryBuilders.TripleTail(model, body, def, add, A)
	-- three bushy tails with neon tips
	for i = -1, 1 do
		add("Tail" .. (i + 2), Vector3.new(0.55, 0.55, 1.5),
			CFrame.new(i * 0.55, 0.65, A.HalfD + 0.35) * CFrame.Angles(math.rad(-30), math.rad(i * 16), 0), def.Body)
		local tip = add("TailTip" .. (i + 2), Vector3.new(0.6, 0.6, 0.6),
			CFrame.new(i * 0.85, 1.15, A.HalfD + 0.9) * CFrame.Angles(math.rad(-30), math.rad(i * 16), 0), def.Accent, Enum.Material.Neon)
		tip.Shape = Enum.PartType.Ball
	end
end

function AccessoryBuilders.TornadoBody(model, body, def, add, A)
	-- stacked swirl rings that widen toward the top of the funnel
	local s1 = add("Swirl1", Vector3.new(2.0, 0.55, 2.0), CFrame.new(0, -0.85, 0), Color3.fromRGB(160, 172, 195))
	s1.Shape = Enum.PartType.Cylinder
	local s2 = add("Swirl2", Vector3.new(2.6, 0.55, 2.6), CFrame.new(0.15, -0.15, 0), Color3.fromRGB(150, 163, 188))
	s2.Shape = Enum.PartType.Cylinder
	local s3 = add("Swirl3", Vector3.new(3.1, 0.55, 3.1), CFrame.new(-0.12, 0.55, 0), Color3.fromRGB(140, 152, 175))
	s3.Shape = Enum.PartType.Cylinder
	local debris = add("Debris", Vector3.new(0.35, 0.35, 0.35), CFrame.new(1.45, 0.2, 0.4), Color3.fromRGB(120, 82, 44))
	debris.Shape = Enum.PartType.Ball
end

function AccessoryBuilders.CowboyHat(model, body, def, add, A)
	local brim = add("HatBrim", Vector3.new(2.2, 0.16, 2.2), CFrame.new(0, A.TopY + 0.05, 0), def.Accent)
	brim.Shape = Enum.PartType.Cylinder
	add("HatCrown", Vector3.new(1.15, 0.65, 1.15), CFrame.new(0, A.TopY + 0.42, 0), def.Accent)
end

function AccessoryBuilders.WaffleGrid(model, body, def, add, A)
	-- the waffle's pressed grid: thin darker grooves across the front
	for i = -1, 1 do
		add("GridV" .. (i + 2), Vector3.new(0.16, 2.2, 0.1), CFrame.new(i * 0.65, 0, -A.HalfD - 0.03), def.Accent)
		add("GridH" .. (i + 2), Vector3.new(2.0, 0.16, 0.1), CFrame.new(0, i * 0.65, -A.HalfD - 0.03), def.Accent)
	end
end

function AccessoryBuilders.SyrupTop(model, body, def, add, A)
	-- a slab of glossy syrup melting over the top of the head, butter on top
	local syrup = add("Syrup", Vector3.new(1.9, 0.3, 1.7), CFrame.new(0, A.TopY + 0.08, 0), Color3.fromRGB(122, 62, 22), Enum.Material.Glass)
	syrup.Transparency = 0.15
	add("Butter", Vector3.new(0.7, 0.3, 0.7), CFrame.new(0.2, A.TopY + 0.38, 0) * CFrame.Angles(0, math.rad(20), 0), Color3.fromRGB(255, 232, 130))
end

function AccessoryBuilders.Crown(model, body, def, add, A)
	local band = add("CrownBand", Vector3.new(1.2, 0.4, 1.2), CFrame.new(0, A.TopY + 0.15, 0), GOLD, Enum.Material.Metal)
	band.Shape = Enum.PartType.Cylinder
	for i = 1, 4 do
		local a = (i / 4) * math.pi * 2 + math.pi / 4
		add("CrownTip" .. i, Vector3.new(0.24, 0.45, 0.24),
			CFrame.new(math.sin(a) * 0.5, A.TopY + 0.55, math.cos(a) * 0.5), GOLD, Enum.Material.Metal)
	end
end

function AccessoryBuilders.WhaleTail(model, body, def, add, A)
	-- a full whale tail sprouting from the lower back, plus the pale
	-- belly worn as a front apron plate
	add("TailStalk", Vector3.new(0.9, 0.8, 1.2), CFrame.new(0, -0.45, A.HalfD + 0.3), def.Body)
	add("FlukeL", Vector3.new(1.6, 0.22, 0.9), CFrame.new(-0.95, -0.2, A.HalfD + 1.1) * CFrame.Angles(0, math.rad(24), math.rad(-10)), def.Body)
	add("FlukeR", Vector3.new(1.6, 0.22, 0.9), CFrame.new(0.95, -0.2, A.HalfD + 1.1) * CFrame.Angles(0, math.rad(-24), math.rad(10)), def.Body)
	add("Belly", Vector3.new(1.9, 1.7, 0.3), CFrame.new(0, -0.35, A.FaceZ + 0.02), Color3.fromRGB(150, 160, 220))
end

function AccessoryBuilders.MoonFin(model, body, def, add, A)
	-- a crescent-moon fin standing on the back like a dorsal sail: a
	-- body-coloured ball bites the neon one to carve the crescent
	local moon = add("MoonFin", Vector3.new(1.1, 1.1, 0.18), CFrame.new(0, 0.85, A.HalfD + 0.16), def.Accent, Enum.Material.Neon)
	moon.Shape = Enum.PartType.Ball
	local cut = add("MoonCut", Vector3.new(0.9, 0.9, 0.34), CFrame.new(0.28, 1.02, A.HalfD + 0.16), def.Body)
	cut.Shape = Enum.PartType.Ball
end

function AccessoryBuilders.GemCore(model, body, def, add, A)
	local ring = add("GemRing", Vector3.new(1.1, 0.25, 1.1), CFrame.new(0, 0.1, A.FaceZ + 0.1) * CFrame.Angles(math.rad(90), 0, 0), GOLD, Enum.Material.Metal)
	ring.Shape = Enum.PartType.Cylinder
	local gem = add("GemCore", Vector3.new(0.7, 0.9, 0.4), CFrame.new(0, 0.1, A.FaceZ - 0.05), def.Accent, Enum.Material.Neon)
	gem.Shape = Enum.PartType.Ball
end

function AccessoryBuilders.Stars(model, body, def, add, A)
	for i = 1, 3 do
		local star = add("Star" .. i, Vector3.new(0.42, 0.42, 0.42), CFrame.new(math.sin(i * 2.1) * 1.5, 1.4 + (i % 2) * 0.7, math.cos(i * 2.1) * 1.5), Color3.fromRGB(255, 226, 90), Enum.Material.Neon)
		star.Shape = Enum.PartType.Ball
	end
end

-- Build one brainrot model. kind: "Wild" | "Carried" | "Displayed" | "Bandit"
function Factory.Build(def, mutation)
	local model = Instance.new("Model")
	model.Name = Config.DisplayName(def, mutation)

	local rarity = Config.Rarities[def.Rarity]
	local scale = 0.9 + def.Rarity * 0.09

	-- ONE body plan for the whole cast: a standing humanoid torso. Each
	-- character's creature/object absurdity lives in its accessories.
	local bodySize = def.BodySize or Vector3.new(2.1, 2.3, 1.6)

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = bodySize * scale
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

	-- anchors the accessory builders position against (humanoid frame:
	-- head centred at y 1.55, face toward -Z, TopY = top of the head)
	local anchors = {
		HeadPos = Vector3.new(0, 1.55, 0), FaceZ = -0.72, TopY = 1.55 + 0.65 * scale, Scale = scale,
		HalfW = body.Size.X / 2, HalfH = body.Size.Y / 2, HalfD = body.Size.Z / 2,
	}

	-- head + face (skipped when an accessory draws the head itself)
	if not def.NoHead then
		add("Head", Vector3.new(1.5, 1.3, 1.4), CFrame.new(0, 1.55, 0), def.Body)
		add("EyeL", Vector3.new(0.26, 0.4, 0.1), CFrame.new(-0.36, 1.7, -0.72), INK)
		add("EyeR", Vector3.new(0.26, 0.4, 0.1), CFrame.new(0.36, 1.7, -0.72), INK)
		add("Smile", Vector3.new(0.6, 0.12, 0.1), CFrame.new(0, 1.28, -0.72), INK)
	end

	-- feet
	add("FootL", Vector3.new(0.7, 0.35, 1.1), CFrame.new(-0.55, -1.3, -0.1), def.Accent)
	add("FootR", Vector3.new(0.7, 0.35, 1.1), CFrame.new(0.55, -1.3, -0.1), def.Accent)

	for _, key in ipairs(def.Accessory) do
		local builder = AccessoryBuilders[key]
		if builder then
			builder(model, body, def, add, anchors)
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
	model:SetAttribute("Hover", def.Hover or 0)
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
