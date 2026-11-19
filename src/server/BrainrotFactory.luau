-- BrainrotFactory.luau — builds blocky brainrot characters out of plain
-- Parts from the data definitions in Config. No external assets: every
-- character in the roster is an original design standing on the same
-- humanoid body, with its absurd creature/object identity carried by
-- its own accessory set. The cast was re-art-directed against the
-- approved model sheets in artwork/concepts: every character now has
-- an expressive GEOMETRIC face (round eyes with a glint, brows, a real
-- mouth — readable at gameplay distance), its own proportions, and a
-- signature silhouette taken from its sheet (Toastino's cream toaster
-- face panel, Splashound's long floppy ears and head droplet,
-- Lampadina's bell lampshade, Biscotto Bot's cookie-disc head,
-- Pumpkowl's pumpkin head with huge owl eyes, Satelerror's TV-screen
-- face with a glitch mouth, Waffleone's syrup, cape and sceptre…).
--
-- Animation is pure code: the head rides a Motor6D "neck" and the arms
-- hang on Motor6D shoulders, and Factory.Pose swings them — a gentle
-- idle sway with a tilting head, and a proper arm-swing walk cycle
-- while a wild brainrot wanders. The movers (SpawnManager,
-- CarryManager, BaseManager) call Pose; unposed models simply rest.

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

local function weldTo(partInst, anchor)
	local w = Instance.new("WeldConstraint")
	w.Part0 = anchor
	w.Part1 = partInst
	w.Parent = partInst
end

local function ball(p)
	p.Shape = Enum.PartType.Ball
	return p
end

--====================================================================--
-- Per-character art direction: suit colours (the sheet's outfit on the
-- torso), body proportions and special construction flags. Anything
-- not listed uses the Config definition as-is.
--====================================================================--
local PROPS = {
	["Toastino"] = { Suit = Color3.fromRGB(216, 120, 52) },   -- rust-orange jumpsuit
	["Lampadina"] = { Suit = Color3.fromRGB(198, 118, 54) },  -- amber cardigan
	["Satelerror"] = { Suit = Color3.fromRGB(52, 56, 68), TVHead = true }, -- charcoal robot
	["Biscotto Bot"] = { BotArms = true },                    -- grey robot limbs, cookie hands
	["Pumpkowl"] = { Body = Vector3.new(2.3, 2.5, 2.0) },     -- plump pumpkin body
	["Splashound"] = { NoMouth = true },                      -- the snout carries the mouth
	["Volpina Neon"] = { NoMouth = true },                    -- the muzzle covers it
}

-- Face expression per character (standard heads only; the object
-- heads — toaster, lamp, teapot, cookie, pumpkin, TV — draw their own
-- faces inside their builders).
local FACE_STYLE = {
	["Waffleone"] = "Smug",
	["Gnocco d'Oro"] = "Smug",
	["Drake Frutto"] = "Brave",
	["Tornadino"] = "Brave",
}

--====================================================================--
-- Animation registry: the Motor6Ds of every living model, keyed by
-- model so the movers can pose them without knowing the joint layout.
--====================================================================--
local AnimState = {}

function Factory.Pose(model, kind, t)
	local st = AnimState[model]
	if not st then
		return
	end
	local ph = st.Phase
	if kind == "Walk" then
		local s = math.sin(t * 7 + ph)
		st.ShoulderL.Transform = CFrame.Angles(s * 0.6, 0, 0.1)
		st.ShoulderR.Transform = CFrame.Angles(-s * 0.6, 0, -0.1)
		st.Neck.Transform = CFrame.Angles(math.sin(t * 14 + ph) * 0.04, math.sin(t * 3.5 + ph) * 0.1, s * 0.05)
	else -- Idle: slow sway, breathing arms, a head that tilts and looks around
		st.ShoulderL.Transform = CFrame.Angles(math.sin(t * 1.8 + ph) * 0.09, 0, 0.12 + math.sin(t * 1.3 + ph) * 0.03)
		st.ShoulderR.Transform = CFrame.Angles(math.sin(t * 1.8 + ph + 1) * 0.09, 0, -0.12 - math.sin(t * 1.3 + ph) * 0.03)
		st.Neck.Transform = CFrame.Angles(math.sin(t * 1.1 + ph) * 0.05, math.sin(t * 0.6 + ph) * 0.15, math.sin(t * 0.8 + ph) * 0.07)
	end
end

--====================================================================--
-- The standard expressive face, drawn on the head mount's front:
-- round black eyes with a white glint, brows, and a mouth built from
-- little bars (a smile arc, or a smirk for the smug ones).
--====================================================================--
local function buildFace(def, hadd, A)
	local style = FACE_STYLE[def.Name] or "Cute"
	local fz = A.FaceZ
	for _, side in ipairs({ -1, 1 }) do
		local tag = side < 0 and "L" or "R"
		ball(hadd("Eye" .. tag, Vector3.new(0.3, 0.42, 0.16), CFrame.new(side * 0.36, 0.14, fz), INK))
		ball(hadd("Glint" .. tag, Vector3.new(0.1, 0.13, 0.06), CFrame.new(side * 0.36 - 0.07, 0.25, fz - 0.08), WHITE, Enum.Material.Neon))
		local tilt = 0
		if style == "Smug" or style == "Brave" then
			tilt = -side * 0.4
		else
			tilt = side * 0.12
		end
		hadd("Brow" .. tag, Vector3.new(0.34, 0.08, 0.06), CFrame.new(side * 0.37, 0.45, fz) * CFrame.Angles(0, 0, tilt), INK)
	end
	local props = PROPS[def.Name]
	if props and props.NoMouth then
		return
	end
	if style == "Smug" then
		hadd("Smirk", Vector3.new(0.42, 0.09, 0.06), CFrame.new(0.09, -0.3, fz) * CFrame.Angles(0, 0, 0.18), INK)
	else
		hadd("SmileM", Vector3.new(0.26, 0.08, 0.06), CFrame.new(0, -0.33, fz), INK)
		hadd("SmileL", Vector3.new(0.2, 0.08, 0.06), CFrame.new(-0.21, -0.28, fz) * CFrame.Angles(0, 0, 0.5), INK)
		hadd("SmileR", Vector3.new(0.2, 0.08, 0.06), CFrame.new(0.21, -0.28, fz) * CFrame.Angles(0, 0, -0.5), INK)
	end
end

--====================================================================--
-- Accessory builders. Each receives the model, its body part, the
-- definition, TWO part helpers and an anchors table:
--   add  — welded to the BODY; offsets are body-local (head centre
--          sits at y = A.HeadY, the torso front at z = -A.HalfD).
--   hadd — welded to the HEAD MOUNT; offsets are head-local (the head
--          centre is the origin, its face plane at z = A.FaceZ, its
--          top at y = A.TopY), so everything stuck on the head follows
--          the neck's idle tilt and walk bobble.
--====================================================================--
local AccessoryBuilders = {}

--====================================================================--
-- Head builders (hadd space: origin = head centre, face toward -Z)
--====================================================================--

function AccessoryBuilders.ToasterHead(model, body, def, add, hadd, A)
	-- the sheet: a chrome toaster whose CREAM front panel carries the
	-- face — big round eyes, little brows, a tiny smile — with two
	-- toast slices popping out of the top and the lever on its side
	hadd("Toaster", Vector3.new(2.0, 1.25, 1.35), CFrame.new(0, 0.12, 0), Color3.fromRGB(196, 200, 208), Enum.Material.Metal)
	hadd("FacePanel", Vector3.new(1.66, 1.0, 0.12), CFrame.new(0, 0.1, -0.68), Color3.fromRGB(246, 238, 220))
	for _, side in ipairs({ -1, 1 }) do
		local tag = side < 0 and "L" or "R"
		ball(hadd("Eye" .. tag, Vector3.new(0.3, 0.38, 0.14), CFrame.new(side * 0.4, 0.2, -0.76), INK))
		ball(hadd("Glint" .. tag, Vector3.new(0.1, 0.12, 0.06), CFrame.new(side * 0.4 - 0.07, 0.3, -0.83), WHITE, Enum.Material.Neon))
		hadd("Brow" .. tag, Vector3.new(0.3, 0.07, 0.06), CFrame.new(side * 0.4, 0.46, -0.75) * CFrame.Angles(0, 0, side * 0.12), INK)
	end
	hadd("SmileM", Vector3.new(0.24, 0.07, 0.06), CFrame.new(0, -0.18, -0.75), INK)
	hadd("SmileL", Vector3.new(0.18, 0.07, 0.06), CFrame.new(-0.19, -0.14, -0.75) * CFrame.Angles(0, 0, 0.5), INK)
	hadd("SmileR", Vector3.new(0.18, 0.07, 0.06), CFrame.new(0.19, -0.14, -0.75) * CFrame.Angles(0, 0, -0.5), INK)
	hadd("ToastSlot", Vector3.new(1.5, 0.14, 0.9), CFrame.new(0, 0.78, 0), BLACK)
	hadd("ToastL", Vector3.new(0.62, 0.85, 0.92), CFrame.new(-0.4, 1.05, 0), Color3.fromRGB(246, 208, 140))
	hadd("ToastR", Vector3.new(0.62, 0.68, 0.92), CFrame.new(0.4, 0.97, 0), Color3.fromRGB(240, 196, 128))
	hadd("LeverPost", Vector3.new(0.3, 0.14, 0.14), CFrame.new(1.08, 0.3, 0), Color3.fromRGB(120, 124, 132), Enum.Material.Metal)
	ball(hadd("LeverKnob", Vector3.new(0.3, 0.3, 0.3), CFrame.new(1.22, 0.3, 0), def.Accent, Enum.Material.Neon))
	-- the jumpsuit collar and pockets from the sheet, on the torso
	add("Collar", Vector3.new(1.5, 0.3, 1.3), CFrame.new(0, A.HalfH - 0.05, 0), Color3.fromRGB(190, 100, 44))
	add("PocketL", Vector3.new(0.5, 0.55, 0.1), CFrame.new(-0.55, -0.45, -A.HalfD - 0.03), Color3.fromRGB(190, 100, 44))
	add("PocketR", Vector3.new(0.5, 0.55, 0.1), CFrame.new(0.55, -0.45, -A.HalfD - 0.03), Color3.fromRGB(190, 100, 44))
end

function AccessoryBuilders.LampHead(model, body, def, add, hadd, A)
	-- the sheet: a big BELL lampshade for a head, glowing warm, its
	-- face printed on the shade's front, a brass finial on top; the
	-- brass stem neck stays on the body so the shade can tilt
	add("Neck", Vector3.new(0.3, 0.55, 0.3), CFrame.new(0, 1.3, 0), Color3.fromRGB(196, 160, 90), Enum.Material.Metal)
	local flare = hadd("ShadeFlare", Vector3.new(2.1, 0.55, 2.1), CFrame.new(0, 0.32, 0), def.Accent, Enum.Material.Neon)
	flare.Shape = Enum.PartType.Cylinder
	local top = hadd("ShadeTop", Vector3.new(1.5, 0.6, 1.5), CFrame.new(0, 0.82, 0), def.Accent, Enum.Material.Neon)
	top.Shape = Enum.PartType.Cylinder
	local rim = hadd("ShadeRim", Vector3.new(2.2, 0.14, 2.2), CFrame.new(0, 0.06, 0), Color3.fromRGB(214, 170, 92), Enum.Material.Metal)
	rim.Shape = Enum.PartType.Cylinder
	hadd("FinialPost", Vector3.new(0.12, 0.28, 0.12), CFrame.new(0, 1.24, 0), Color3.fromRGB(196, 160, 90), Enum.Material.Metal)
	ball(hadd("Finial", Vector3.new(0.3, 0.3, 0.3), CFrame.new(0, 1.44, 0), Color3.fromRGB(196, 160, 90), Enum.Material.Metal))
	local bulb = ball(hadd("BulbGlow", Vector3.new(0.85, 0.45, 0.85), CFrame.new(0, -0.05, 0), WHITE, Enum.Material.Neon))
	local light = Instance.new("PointLight")
	light.Name = "LampGlow"
	light.Color = Color3.fromRGB(255, 214, 140)
	light.Range = 9
	light.Brightness = 1.3
	light.Parent = bulb
	-- the face glows through the shade's front
	for _, side in ipairs({ -1, 1 }) do
		local tag = side < 0 and "L" or "R"
		ball(hadd("Eye" .. tag, Vector3.new(0.26, 0.36, 0.12), CFrame.new(side * 0.38, 0.38, -1.02), INK))
		hadd("Brow" .. tag, Vector3.new(0.3, 0.07, 0.06), CFrame.new(side * 0.38, 0.62, -1.0) * CFrame.Angles(0, 0, side * 0.12), INK)
	end
	hadd("SmileM", Vector3.new(0.26, 0.08, 0.06), CFrame.new(0, 0.05, -1.06), INK)
	hadd("SmileL", Vector3.new(0.2, 0.08, 0.06), CFrame.new(-0.21, 0.1, -1.05) * CFrame.Angles(0, 0, 0.5), INK)
	hadd("SmileR", Vector3.new(0.2, 0.08, 0.06), CFrame.new(0.21, 0.1, -1.05) * CFrame.Angles(0, 0, -0.5), INK)
	-- cardigan buttons down the torso, like the sheet's cosy outfit
	for i = 0, 2 do
		ball(add("Button" .. i, Vector3.new(0.16, 0.16, 0.16), CFrame.new(0, 0.45 - i * 0.45, -A.HalfD - 0.04), Color3.fromRGB(120, 70, 34)))
	end
end

function AccessoryBuilders.TeapotHead(model, body, def, add, hadd, A)
	-- a round glass teapot head: spout nose, handle ear, golden lid
	-- knob — and now a real face on the glass, like the sheet style
	local pot = ball(hadd("Teapot", Vector3.new(1.75, 1.4, 1.75), CFrame.new(0, 0.18, 0), Color3.fromRGB(120, 200, 220), Enum.Material.Glass))
	pot.Transparency = 0.15
	hadd("Spout", Vector3.new(0.34, 0.34, 0.9), CFrame.new(0, 0.02, -1.05) * CFrame.Angles(math.rad(-32), 0, 0), Color3.fromRGB(120, 200, 220), Enum.Material.Glass)
	hadd("Handle", Vector3.new(0.22, 0.8, 0.6), CFrame.new(0.98, 0.22, 0), Color3.fromRGB(120, 200, 220), Enum.Material.Glass)
	ball(hadd("LidKnob", Vector3.new(0.4, 0.4, 0.4), CFrame.new(0, 0.95, 0), def.Accent, Enum.Material.Metal))
	for _, side in ipairs({ -1, 1 }) do
		local tag = side < 0 and "L" or "R"
		ball(hadd("Eye" .. tag, Vector3.new(0.28, 0.38, 0.12), CFrame.new(side * 0.36, 0.38, -0.84), INK))
		ball(hadd("Glint" .. tag, Vector3.new(0.09, 0.11, 0.05), CFrame.new(side * 0.36 - 0.06, 0.48, -0.9), WHITE, Enum.Material.Neon))
	end
	hadd("SmileM", Vector3.new(0.24, 0.07, 0.06), CFrame.new(0, -0.05, -0.88), INK)
	hadd("SmileL", Vector3.new(0.18, 0.07, 0.06), CFrame.new(-0.19, -0.01, -0.87) * CFrame.Angles(0, 0, 0.5), INK)
	hadd("SmileR", Vector3.new(0.18, 0.07, 0.06), CFrame.new(0.19, -0.01, -0.87) * CFrame.Angles(0, 0, -0.5), INK)
end

function AccessoryBuilders.PirateHat(model, body, def, add, hadd, A)
	local brim = hadd("HatBrim", Vector3.new(1.9, 0.18, 1.5), CFrame.new(0, 1.12, 0), BLACK)
	brim.Shape = Enum.PartType.Cylinder
	hadd("HatTop", Vector3.new(1.3, 0.5, 1.1), CFrame.new(0, 1.34, 0), BLACK)
	ball(hadd("Skull", Vector3.new(0.44, 0.44, 0.44), CFrame.new(0, 1.3, -0.58), WHITE))
end

function AccessoryBuilders.CookieHead(model, body, def, add, hadd, A)
	-- the sheet: the head IS a big flat cookie disc, face and all —
	-- chocolate-chip freckles, big brown eyes, a happy smile
	local disc = hadd("CookieHead", Vector3.new(2.1, 0.5, 2.1), CFrame.new(0, 0.1, 0) * CFrame.Angles(math.rad(90), 0, 0), def.Body)
	disc.Shape = Enum.PartType.Cylinder
	local chips = { { -0.62, 0.55 }, { 0.58, 0.72 }, { -0.15, 0.85 }, { 0.8, -0.35 }, { -0.85, -0.3 }, { 0.25, -0.78 } }
	for i, spot in ipairs(chips) do
		ball(hadd("HeadChip" .. i, Vector3.new(0.24, 0.24, 0.24), CFrame.new(spot[1], spot[2], -0.22), def.Accent))
	end
	for _, side in ipairs({ -1, 1 }) do
		local tag = side < 0 and "L" or "R"
		ball(hadd("Eye" .. tag, Vector3.new(0.32, 0.4, 0.14), CFrame.new(side * 0.38, 0.05, -0.28), def.Accent))
		ball(hadd("Glint" .. tag, Vector3.new(0.11, 0.13, 0.06), CFrame.new(side * 0.38 - 0.07, 0.16, -0.35), WHITE, Enum.Material.Neon))
	end
	hadd("SmileM", Vector3.new(0.28, 0.08, 0.06), CFrame.new(0, -0.38, -0.27), def.Accent)
	hadd("SmileL", Vector3.new(0.2, 0.08, 0.06), CFrame.new(-0.23, -0.33, -0.27) * CFrame.Angles(0, 0, 0.5), def.Accent)
	hadd("SmileR", Vector3.new(0.2, 0.08, 0.06), CFrame.new(0.23, -0.33, -0.27) * CFrame.Angles(0, 0, -0.5), def.Accent)
end

function AccessoryBuilders.PumpkinHead(model, body, def, add, hadd, A)
	-- the sheet: a ribbed pumpkin for a head with HUGE owl eyes on pale
	-- eye discs, a little beak, and the stem + leaf on top
	ball(hadd("Pumpkin", Vector3.new(1.7, 1.55, 1.6), CFrame.new(0, 0.08, 0), Color3.fromRGB(245, 150, 55)))
	for i = -1, 1 do
		hadd("HeadRib" .. (i + 2), Vector3.new(0.14, 1.4, 0.14), CFrame.new(i * 0.55, 0.08, -0.78), Color3.fromRGB(226, 124, 38))
	end
	for _, side in ipairs({ -1, 1 }) do
		local tag = side < 0 and "L" or "R"
		ball(hadd("EyeDisc" .. tag, Vector3.new(0.62, 0.62, 0.2), CFrame.new(side * 0.4, 0.18, -0.72), Color3.fromRGB(252, 214, 150)))
		ball(hadd("Eye" .. tag, Vector3.new(0.4, 0.4, 0.16), CFrame.new(side * 0.4, 0.18, -0.82), INK))
		ball(hadd("Glint" .. tag, Vector3.new(0.13, 0.13, 0.06), CFrame.new(side * 0.4 - 0.09, 0.3, -0.9), WHITE, Enum.Material.Neon))
	end
	ball(hadd("BeakTop", Vector3.new(0.36, 0.2, 0.3), CFrame.new(0, -0.22, -0.8), Color3.fromRGB(255, 190, 60)))
	ball(hadd("BeakLow", Vector3.new(0.28, 0.14, 0.24), CFrame.new(0, -0.36, -0.78), Color3.fromRGB(240, 170, 50)))
	hadd("Stem", Vector3.new(0.3, 0.5, 0.3), CFrame.new(0, 0.95, 0) * CFrame.Angles(0, 0, math.rad(10)), Color3.fromRGB(84, 140, 60))
	local leaf = ball(hadd("Leaf", Vector3.new(0.55, 0.16, 0.4), CFrame.new(0.35, 0.9, 0), Color3.fromRGB(96, 160, 70)))
	leaf.Transparency = 0.05
end

function AccessoryBuilders.TVHead(model, body, def, add, hadd, A)
	-- the sheet: a chunky monitor head whose dark screen carries the
	-- face — glowing cyan eyes and a jagged glitch mouth
	hadd("Monitor", Vector3.new(1.75, 1.45, 1.25), CFrame.new(0, 0.12, 0), Color3.fromRGB(52, 56, 68), Enum.Material.Metal)
	hadd("Screen", Vector3.new(1.45, 1.15, 0.1), CFrame.new(0, 0.12, -0.64), Color3.fromRGB(10, 14, 22))
	for _, side in ipairs({ -1, 1 }) do
		local tag = side < 0 and "L" or "R"
		ball(hadd("Eye" .. tag, Vector3.new(0.27, 0.27, 0.12), CFrame.new(side * 0.35, 0.3, -0.7), def.Accent, Enum.Material.Neon))
		local can = hadd("EarCan" .. tag, Vector3.new(0.55, 0.18, 0.55), CFrame.new(side * 0.95, 0.12, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(70, 74, 86), Enum.Material.Metal)
		can.Shape = Enum.PartType.Cylinder
	end
	-- the glitch mouth: five neon teeth zig-zagging across the screen
	for i = 0, 4 do
		hadd("Glitch" .. i, Vector3.new(0.17, 0.11, 0.06),
			CFrame.new(-0.34 + i * 0.17, -0.28 + (i % 2 == 0 and 0.05 or -0.05), -0.7), def.Accent, Enum.Material.Neon)
	end
end

function AccessoryBuilders.DogEars(model, body, def, add, hadd, A)
	-- the sheet: LONG floppy ears hanging down beside the head
	for _, side in ipairs({ -1, 1 }) do
		local tag = side < 0 and "L" or "R"
		hadd("Ear" .. tag, Vector3.new(0.46, 1.2, 0.26),
			CFrame.new(side * 0.82, -0.25, 0) * CFrame.Angles(0, 0, -side * 0.1), def.Body)
		hadd("EarIn" .. tag, Vector3.new(0.28, 0.85, 0.08),
			CFrame.new(side * 0.84, -0.3, -0.12) * CFrame.Angles(0, 0, -side * 0.1), def.Accent)
	end
end

function AccessoryBuilders.Snout(model, body, def, add, hadd, A)
	-- the sheet: a white muzzle patch, a blue nose, an open happy
	-- mouth with a tongue, and the water droplet riding the head top
	hadd("Muzzle", Vector3.new(0.98, 0.64, 0.3), CFrame.new(0, -0.2, A.FaceZ + 0.04), WHITE)
	hadd("Snout", Vector3.new(0.62, 0.42, 0.5), CFrame.new(0, -0.1, A.FaceZ - 0.2), Color3.fromRGB(170, 215, 250))
	ball(hadd("Nose", Vector3.new(0.32, 0.26, 0.26), CFrame.new(0, 0.04, A.FaceZ - 0.44), Color3.fromRGB(30, 80, 180)))
	hadd("Mouth", Vector3.new(0.4, 0.3, 0.08), CFrame.new(0, -0.42, A.FaceZ - 0.12), INK)
	hadd("Tongue", Vector3.new(0.24, 0.16, 0.06), CFrame.new(0, -0.52, A.FaceZ - 0.13), Color3.fromRGB(255, 130, 160))
	local drop = ball(hadd("HeadDrop", Vector3.new(0.55, 0.72, 0.55), CFrame.new(0, A.TopY + 0.3, 0), def.Accent, Enum.Material.Glass))
	drop.Transparency = 0.2
	ball(hadd("DropTip", Vector3.new(0.26, 0.3, 0.26), CFrame.new(0, A.TopY + 0.72, 0), def.Accent, Enum.Material.Glass))
	-- jacket detail: a white chest panel and droplet studs on the torso
	add("ChestPanel", Vector3.new(1.15, 1.5, 0.12), CFrame.new(0, 0.05, -A.HalfD - 0.03), WHITE)
	for i, spot in ipairs({ { -0.75, 0.5 }, { 0.78, 0.1 }, { -0.8, -0.45 } }) do
		ball(add("DropStud" .. i, Vector3.new(0.2, 0.28, 0.1), CFrame.new(spot[1], spot[2], -A.HalfD - 0.04), WHITE))
	end
end

function AccessoryBuilders.WagTail(model, body, def, add, hadd, A)
	add("Tail", Vector3.new(0.26, 0.26, 1.05), CFrame.new(0, 0.55, A.HalfD + 0.28) * CFrame.Angles(math.rad(-30), 0, 0), def.Body)
	ball(add("TailFin", Vector3.new(0.4, 0.55, 0.4), CFrame.new(0, 0.95, A.HalfD + 0.62), def.Accent, Enum.Material.Glass))
end

function AccessoryBuilders.MopHair(model, body, def, add, hadd, A)
	-- a mop head of yarn strands standing in for hair
	for i = -2, 2 do
		hadd("Strand" .. (i + 3), Vector3.new(0.24, 1.45, 0.24),
			CFrame.new(i * 0.3, 0.72, 0) * CFrame.Angles(math.rad(i * 5), 0, math.rad(i * 7)), def.Accent)
	end
	hadd("MopBand", Vector3.new(1.5, 0.3, 1.4), CFrame.new(0, 1.32, 0), Color3.fromRGB(170, 178, 190), Enum.Material.Metal)
end

function AccessoryBuilders.Antenna(model, body, def, add, hadd, A)
	hadd("AntennaRod", Vector3.new(0.14, 0.9, 0.14), CFrame.new(0, A.TopY + 0.42, 0), Color3.fromRGB(120, 124, 132), Enum.Material.Metal)
	ball(hadd("AntennaTip", Vector3.new(0.42, 0.42, 0.42), CFrame.new(0, A.TopY + 0.98, 0), Color3.fromRGB(255, 200, 92), Enum.Material.Neon))
	-- a cluster of crumbs under the tip, like the sheet's antenna tuft
	ball(hadd("CrumbA", Vector3.new(0.22, 0.22, 0.22), CFrame.new(-0.16, A.TopY + 0.82, 0.08), def.Body))
	ball(hadd("CrumbB", Vector3.new(0.18, 0.18, 0.18), CFrame.new(0.15, A.TopY + 0.86, -0.06), def.Body))
end

function AccessoryBuilders.ForkAntenna(model, body, def, add, hadd, A)
	hadd("ForkHandle", Vector3.new(0.16, 1.0, 0.16), CFrame.new(0, A.TopY + 0.45, 0), def.Accent, Enum.Material.Metal)
	for i = -1, 1 do
		hadd("ForkProng" .. (i + 2), Vector3.new(0.12, 0.45, 0.12), CFrame.new(i * 0.2, A.TopY + 1.15, 0), def.Accent, Enum.Material.Metal)
	end
	hadd("ForkBar", Vector3.new(0.6, 0.14, 0.14), CFrame.new(0, A.TopY + 0.95, 0), def.Accent, Enum.Material.Metal)
end

function AccessoryBuilders.HeadFrame(model, body, def, add, hadd, A)
	-- the crimped ravioli rim framing the face
	local c = Color3.fromRGB(232, 200, 140)
	hadd("FrameT", Vector3.new(1.7, 0.22, 0.16), CFrame.new(0, 0.72, A.FaceZ + 0.06), c)
	hadd("FrameB", Vector3.new(1.7, 0.22, 0.16), CFrame.new(0, -0.72, A.FaceZ + 0.06), c)
	hadd("FrameL", Vector3.new(0.22, 1.6, 0.16), CFrame.new(-0.82, 0, A.FaceZ + 0.06), c)
	hadd("FrameR", Vector3.new(0.22, 1.6, 0.16), CFrame.new(0.82, 0, A.FaceZ + 0.06), c)
end

function AccessoryBuilders.EarTufts(model, body, def, add, hadd, A)
	-- feathered owl ear tufts: three fanned slats per side
	for _, side in ipairs({ -1, 1 }) do
		local tag = side < 0 and "L" or "R"
		for j = 0, 2 do
			hadd("Tuft" .. tag .. j, Vector3.new(0.16, 0.62, 0.3),
				CFrame.new(side * (0.58 + j * 0.1), A.TopY + 0.16, 0) * CFrame.Angles(0, 0, -side * (0.25 + j * 0.22)),
				Color3.fromRGB(196, 110, 44))
		end
	end
end

function AccessoryBuilders.DiscoBall(model, body, def, add, hadd, A)
	-- mushroom cap first, then the mirror ball on top of it
	local cap = hadd("Cap", Vector3.new(2.3, 0.7, 2.3), CFrame.new(0, A.TopY + 0.1, 0), def.Body)
	cap.Shape = Enum.PartType.Cylinder
	for i = 1, 3 do
		ball(hadd("CapDot" .. i, Vector3.new(0.34, 0.34, 0.34), CFrame.new(-0.6 + i * 0.45, A.TopY + 0.5, -0.4 + (i % 2) * 0.7), WHITE))
	end
	ball(hadd("DiscoBall", Vector3.new(1.15, 1.15, 1.15), CFrame.new(0, A.TopY + 1.15, 0), def.Accent, Enum.Material.Metal))
	for i = 1, 4 do
		local a = i * math.pi / 2
		hadd("Mirror" .. i, Vector3.new(0.3, 0.3, 0.08),
			CFrame.new(math.sin(a) * 0.58, A.TopY + 1.15, math.cos(a) * 0.58) * CFrame.Angles(0, a, 0), WHITE, Enum.Material.Neon)
	end
end

function AccessoryBuilders.Headphones(model, body, def, add, hadd, A)
	hadd("Band", Vector3.new(1.7, 0.22, 0.3), CFrame.new(0, 0.52, 0), BLACK)
	hadd("CupL", Vector3.new(0.3, 0.7, 0.7), CFrame.new(-0.88, 0.05, 0), BLACK)
	hadd("CupR", Vector3.new(0.3, 0.7, 0.7), CFrame.new(0.88, 0.05, 0), BLACK)
end

function AccessoryBuilders.Shades(model, body, def, add, hadd, A)
	hadd("ShadeL", Vector3.new(0.55, 0.4, 0.12), CFrame.new(-0.42, 0.18, A.FaceZ - 0.04), BLACK)
	hadd("ShadeR", Vector3.new(0.55, 0.4, 0.12), CFrame.new(0.42, 0.18, A.FaceZ - 0.04), BLACK)
	hadd("ShadeBar", Vector3.new(1.4, 0.12, 0.12), CFrame.new(0, 0.28, A.FaceZ - 0.04), BLACK)
end

function AccessoryBuilders.Horns(model, body, def, add, hadd, A)
	hadd("HornL", Vector3.new(0.26, 0.7, 0.26), CFrame.new(-0.5, 0.95, 0) * CFrame.Angles(0, 0, math.rad(16)), WHITE)
	hadd("HornR", Vector3.new(0.26, 0.7, 0.26), CFrame.new(0.5, 0.95, 0) * CFrame.Angles(0, 0, math.rad(-16)), WHITE)
end

function AccessoryBuilders.FoxEars(model, body, def, add, hadd, A)
	hadd("FEarL", Vector3.new(0.45, 0.85, 0.2), CFrame.new(-0.5, 0.9, 0) * CFrame.Angles(0, 0, math.rad(12)), def.Body)
	hadd("FEarR", Vector3.new(0.45, 0.85, 0.2), CFrame.new(0.5, 0.9, 0) * CFrame.Angles(0, 0, math.rad(-12)), def.Body)
	ball(hadd("FEarTipL", Vector3.new(0.3, 0.3, 0.3), CFrame.new(-0.6, 1.28, 0), def.Accent, Enum.Material.Neon))
	ball(hadd("FEarTipR", Vector3.new(0.3, 0.3, 0.3), CFrame.new(0.6, 1.28, 0), def.Accent, Enum.Material.Neon))
end

function AccessoryBuilders.FoxMuzzle(model, body, def, add, hadd, A)
	hadd("Muzzle", Vector3.new(0.75, 0.5, 0.65), CFrame.new(0, -0.15, A.FaceZ - 0.25), WHITE)
	ball(hadd("FoxNose", Vector3.new(0.28, 0.22, 0.28), CFrame.new(0, 0.02, A.FaceZ - 0.58), BLACK))
end

function AccessoryBuilders.Crown(model, body, def, add, hadd, A)
	local band = hadd("CrownBand", Vector3.new(1.2, 0.4, 1.2), CFrame.new(0, A.TopY + 0.22, 0), GOLD, Enum.Material.Metal)
	band.Shape = Enum.PartType.Cylinder
	for i = 1, 4 do
		local a = (i / 4) * math.pi * 2 + math.pi / 4
		hadd("CrownTip" .. i, Vector3.new(0.24, 0.45, 0.24),
			CFrame.new(math.sin(a) * 0.5, A.TopY + 0.62, math.cos(a) * 0.5), GOLD, Enum.Material.Metal)
	end
	ball(hadd("CrownGem", Vector3.new(0.26, 0.26, 0.26), CFrame.new(0, A.TopY + 0.22, -0.62), Color3.fromRGB(178, 102, 255), Enum.Material.Neon))
end

function AccessoryBuilders.SyrupTop(model, body, def, add, hadd, A)
	-- glossy syrup melting over the top of the head, butter on top —
	-- and now the drips running down the face, like the sheet
	local syrup = hadd("Syrup", Vector3.new(1.9, 0.3, 1.7), CFrame.new(0, A.TopY + 0.1, 0), Color3.fromRGB(122, 62, 22), Enum.Material.Glass)
	syrup.Transparency = 0.15
	hadd("Butter", Vector3.new(0.7, 0.3, 0.7), CFrame.new(0.2, A.TopY + 0.4, 0) * CFrame.Angles(0, math.rad(20), 0), Color3.fromRGB(255, 232, 130))
	for i, drip in ipairs({ { -0.55, 0.55 }, { 0.05, 0.8 }, { 0.6, 0.45 } }) do
		local d = hadd("Drip" .. i, Vector3.new(0.22, drip[2], 0.1), CFrame.new(drip[1], A.TopY - drip[2] / 2 + 0.12, A.FaceZ + 0.03), Color3.fromRGB(122, 62, 22), Enum.Material.Glass)
		d.Transparency = 0.15
	end
end

function AccessoryBuilders.JellyDome(model, body, def, add, hadd, A)
	-- a glass astronaut helmet over the head, its rim a metal ring —
	-- the jellyfish bell now crowns the humanoid like a space helmet
	local dome = ball(hadd("Dome", Vector3.new(2.3, 1.9, 2.3), CFrame.new(0, 0.1, 0), Color3.fromRGB(200, 235, 255), Enum.Material.Glass))
	dome.Transparency = 0.45
	local ring = hadd("DomeRing", Vector3.new(2.15, 0.3, 2.15), CFrame.new(0, -0.58, 0), def.Accent, Enum.Material.Metal)
	ring.Shape = Enum.PartType.Cylinder
end

function AccessoryBuilders.JellyTentacles(model, body, def, add, hadd, A)
	-- jelly strands dangling from the helmet rim past the shoulders
	for i = -2, 2 do
		if i ~= 0 then
			hadd("Tentacle" .. (i + 3), Vector3.new(0.26, 1.15, 0.26),
				CFrame.new(i * 0.44, -1.1, (i % 2 == 0) and 0.55 or -0.55) * CFrame.Angles(math.rad(i * 4), 0, math.rad(i * 5)), def.Body)
		end
	end
end

function AccessoryBuilders.SatDish(model, body, def, add, hadd, A)
	-- a satellite dish worn like a cap, tilted up at the sky, with a
	-- feed arm and a glowing receiver tip (red, like the sheet)
	hadd("DishStalk", Vector3.new(0.22, 0.5, 0.22), CFrame.new(0, A.TopY + 0.2, 0), Color3.fromRGB(150, 158, 175), Enum.Material.Metal)
	local dish = hadd("Dish", Vector3.new(2.3, 0.4, 2.3), CFrame.new(0, A.TopY + 0.62, 0) * CFrame.Angles(math.rad(-32), 0, 0), Color3.fromRGB(214, 220, 232), Enum.Material.Metal)
	dish.Shape = Enum.PartType.Cylinder
	hadd("DishArm", Vector3.new(0.14, 0.14, 1.1), CFrame.new(0, A.TopY + 0.95, -0.35) * CFrame.Angles(math.rad(-32), 0, 0), Color3.fromRGB(150, 158, 175), Enum.Material.Metal)
	ball(hadd("DishTip", Vector3.new(0.36, 0.36, 0.36), CFrame.new(0, A.TopY + 1.12, -0.62), Color3.fromRGB(255, 70, 70), Enum.Material.Neon))
end

function AccessoryBuilders.CowboyHat(model, body, def, add, hadd, A)
	local brim = hadd("HatBrim", Vector3.new(2.2, 0.16, 2.2), CFrame.new(0, A.TopY + 0.05, 0), def.Accent)
	brim.Shape = Enum.PartType.Cylinder
	hadd("HatCrown", Vector3.new(1.15, 0.65, 1.15), CFrame.new(0, A.TopY + 0.42, 0), def.Accent)
end

--====================================================================--
-- Body builders (add space: origin = body centre, head centre at
-- y = A.HeadY, torso front at z = -A.HalfD)
--====================================================================--

function AccessoryBuilders.Tentacles(model, body, def, add, hadd, A)
	-- a skirt of sock tentacles at the waist — this is a sock-topus
	for i = 1, 6 do
		local a = (i / 6) * math.pi * 2
		add("Tentacle" .. i, Vector3.new(0.34, 1.1, 0.34),
			CFrame.new(math.sin(a) * (A.HalfW - 0.1), -1.15, math.cos(a) * (A.HalfD - 0.1))
				* CFrame.Angles(math.cos(a) * 0.35, 0, -math.sin(a) * 0.35), def.Body)
	end
end

function AccessoryBuilders.CookieDisc(model, body, def, add, hadd, A)
	-- a second cookie worn as a chest plate
	local disc = add("CookieTorso", Vector3.new(2.6, 0.5, 2.6), CFrame.new(0, 0, -A.HalfD - 0.1) * CFrame.Angles(math.rad(90), 0, 0), def.Body)
	disc.Shape = Enum.PartType.Cylinder
end

function AccessoryBuilders.ChocChips(model, body, def, add, hadd, A)
	for i = 1, 5 do
		local a = i * 2.4
		ball(add("Chip" .. i, Vector3.new(0.3, 0.3, 0.3),
			CFrame.new(math.sin(a) * 0.85, math.cos(a * 1.3) * 0.7, -A.HalfD - 0.4), def.Accent))
	end
end

function AccessoryBuilders.PumpkinRibs(model, body, def, add, hadd, A)
	for i = -2, 2 do
		add("Rib" .. (i + 3), Vector3.new(0.16, A.HalfH * 2 - 0.2, 0.16), CFrame.new(i * 0.5, 0, -A.HalfD - 0.02), Color3.fromRGB(226, 124, 38))
	end
end

function AccessoryBuilders.Wings(model, body, def, add, hadd, A)
	-- feathered wings: three stacked slats fanning off each shoulder
	for _, side in ipairs({ -1, 1 }) do
		local tag = side < 0 and "L" or "R"
		for j = 0, 2 do
			add("Wing" .. tag .. j, Vector3.new(1.0 - j * 0.18, 0.34, 0.14),
				CFrame.new(side * (A.HalfW + 0.42), 0.55 - j * 0.34, 0.1) * CFrame.Angles(0, 0, -side * (0.35 + j * 0.3)),
				Color3.fromRGB(196, 110, 44))
		end
	end
end

function AccessoryBuilders.CrimpEdge(model, body, def, add, hadd, A)
	-- the crimped ravioli rim around the whole torso
	local c = Color3.fromRGB(232, 200, 140)
	add("CrimpT", Vector3.new(A.HalfW * 2 + 0.25, 0.3, 0.25), CFrame.new(0, A.HalfH + 0.05, 0), c)
	add("CrimpB", Vector3.new(A.HalfW * 2 + 0.25, 0.3, 0.25), CFrame.new(0, -A.HalfH - 0.05, 0), c)
	add("CrimpL", Vector3.new(0.25, A.HalfH * 2 + 0.25, 0.25), CFrame.new(-A.HalfW - 0.05, 0, 0), c)
	add("CrimpR", Vector3.new(0.25, A.HalfH * 2 + 0.25, 0.25), CFrame.new(A.HalfW + 0.05, 0, 0), c)
end

function AccessoryBuilders.Backpack(model, body, def, add, hadd, A)
	-- an astronaut's oxygen backpack with two tanks
	add("Pack", Vector3.new(1.3, 1.7, 0.5), CFrame.new(0, 0.15, A.HalfD + 0.3), Color3.fromRGB(200, 206, 216), Enum.Material.Metal)
	ball(add("TankL", Vector3.new(0.45, 0.9, 0.45), CFrame.new(-0.35, 0.45, A.HalfD + 0.62), def.Accent, Enum.Material.Neon))
	ball(add("TankR", Vector3.new(0.45, 0.9, 0.45), CFrame.new(0.35, 0.45, A.HalfD + 0.62), def.Accent, Enum.Material.Neon))
end

function AccessoryBuilders.BroomStick(model, body, def, add, hadd, A)
	-- the broom it rides, handle angled under the body
	add("BroomStick", Vector3.new(0.22, 0.22, 3.4), CFrame.new(0, -1.35, 0.2) * CFrame.Angles(math.rad(6), 0, 0), Color3.fromRGB(150, 105, 60))
end

function AccessoryBuilders.Bristles(model, body, def, add, hadd, A)
	add("Bristles", Vector3.new(1.0, 0.75, 1.3), CFrame.new(0, -1.45, 1.75), def.Accent)
	add("BristleBand", Vector3.new(1.05, 0.25, 1.35), CFrame.new(0, -1.05, 1.7), Color3.fromRGB(170, 178, 190), Enum.Material.Metal)
end

function AccessoryBuilders.Wheels(model, body, def, add, hadd, A)
	-- little rocket wheels bolted to the broom
	for _, side in ipairs({ -1, 1 }) do
		local tag = side < 0 and "L" or "R"
		local wheel = add("Wheel" .. tag, Vector3.new(0.7, 0.22, 0.7),
			CFrame.new(side * 0.62, -1.5, 1.1) * CFrame.Angles(0, 0, math.rad(90)), BLACK)
		wheel.Shape = Enum.PartType.Cylinder
	end
end

function AccessoryBuilders.SolarPanels(model, body, def, add, hadd, A)
	-- twin solar wings on the back, like the sheet's satellite robot
	for _, side in ipairs({ -1, 1 }) do
		local tag = side < 0 and "L" or "R"
		add("PanelArm" .. tag, Vector3.new(0.9, 0.14, 0.14), CFrame.new(side * (A.HalfW + 0.35), 0.55, A.HalfD + 0.15), Color3.fromRGB(150, 158, 175), Enum.Material.Metal)
		add("Panel" .. tag, Vector3.new(1.5, 1.1, 0.12),
			CFrame.new(side * (A.HalfW + 1.25), 0.55, A.HalfD + 0.15) * CFrame.Angles(0, side * 0.25, 0),
			Color3.fromRGB(38, 64, 140), Enum.Material.Metal)
		add("PanelCell" .. tag, Vector3.new(1.3, 0.9, 0.06),
			CFrame.new(side * (A.HalfW + 1.25), 0.55, A.HalfD + 0.23) * CFrame.Angles(0, side * 0.25, 0),
			Color3.fromRGB(70, 120, 220), Enum.Material.Neon)
	end
end

function AccessoryBuilders.SparkCoils(model, body, def, add, hadd, A)
	-- tesla coils on the shoulders, a sparking core in the chest, and
	-- the glowing circuit traces the sheet draws across the torso
	for _, side in ipairs({ -1, 1 }) do
		local tag = side < 0 and "L" or "R"
		add("CoilPost" .. tag, Vector3.new(0.2, 0.9, 0.2), CFrame.new(side * (A.HalfW + 0.15), A.HalfH + 0.35, 0), Color3.fromRGB(150, 158, 175), Enum.Material.Metal)
		ball(add("CoilOrb" .. tag, Vector3.new(0.45, 0.45, 0.45), CFrame.new(side * (A.HalfW + 0.15), A.HalfH + 0.9, 0), def.Accent, Enum.Material.Neon))
	end
	local core = ball(add("SparkCore", Vector3.new(0.6, 0.6, 0.3), CFrame.new(0, 0.15, -A.HalfD - 0.08), def.Accent, Enum.Material.Neon))
	local spark = Instance.new("ParticleEmitter")
	spark.Name = "Sparks"
	spark.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	spark.Color = ColorSequence.new(def.Accent)
	spark.Rate = 22
	spark.Lifetime = NumberRange.new(0.2, 0.45)
	spark.Speed = NumberRange.new(1.5, 3.5)
	spark.SpreadAngle = Vector2.new(180, 180)
	spark.Size = NumberSequence.new(0.22)
	spark.Parent = core
	add("TraceV", Vector3.new(0.1, 1.3, 0.06), CFrame.new(0, -0.55, -A.HalfD - 0.03), def.Accent, Enum.Material.Neon)
	add("TraceL", Vector3.new(0.7, 0.1, 0.06), CFrame.new(-0.5, 0.62, -A.HalfD - 0.03), def.Accent, Enum.Material.Neon)
	add("TraceR", Vector3.new(0.7, 0.1, 0.06), CFrame.new(0.5, -0.85, -A.HalfD - 0.03), def.Accent, Enum.Material.Neon)
end

function AccessoryBuilders.DragonWings(model, body, def, add, hadd, A)
	for _, side in ipairs({ -1, 1 }) do
		local tag = side < 0 and "L" or "R"
		add("Wing" .. tag, Vector3.new(1.7, 1.1, 0.16),
			CFrame.new(side * (A.HalfW + 0.7), 0.75, A.HalfD * 0.5) * CFrame.Angles(0, side * 0.5, -side * 0.4), def.Body)
		add("WingTip" .. tag, Vector3.new(0.9, 0.6, 0.14),
			CFrame.new(side * (A.HalfW + 1.5), 1.15, A.HalfD * 0.5) * CFrame.Angles(0, side * 0.5, -side * 0.15), def.Accent, Enum.Material.Neon)
	end
	-- the pale dragon belly plate from the sheet
	add("Belly", Vector3.new(1.15, 1.7, 0.24), CFrame.new(0, -0.15, -A.HalfD + 0.02), Color3.fromRGB(250, 222, 228))
end

function AccessoryBuilders.DragonTail(model, body, def, add, hadd, A)
	add("Tail", Vector3.new(0.4, 0.4, 1.5), CFrame.new(0, -0.75, A.HalfD + 0.6) * CFrame.Angles(math.rad(24), 0, 0), def.Body)
	ball(add("TailSpade", Vector3.new(0.55, 0.55, 0.55), CFrame.new(0, -0.45, A.HalfD + 1.35), def.Accent, Enum.Material.Neon))
end

function AccessoryBuilders.TripleTail(model, body, def, add, hadd, A)
	for i = -1, 1 do
		add("FoxTail" .. (i + 2), Vector3.new(0.36, 1.3, 0.36),
			CFrame.new(i * 0.55, 0.1, A.HalfD + 0.35) * CFrame.Angles(math.rad(-28 + math.abs(i) * 8), 0, math.rad(i * 18)), def.Body)
		ball(add("FoxTailTip" .. (i + 2), Vector3.new(0.4, 0.45, 0.4),
			CFrame.new(i * 0.8, 0.72, A.HalfD + 0.62), def.Accent, Enum.Material.Neon))
	end
end

function AccessoryBuilders.TornadoBody(model, body, def, add, hadd, A)
	-- a swirl of tornado rings around the waist, cowboy hat up top
	for i = 0, 2 do
		local ring = add("Swirl" .. i, Vector3.new(A.HalfW * 2 + 0.7 - i * 0.35, 0.3, A.HalfD * 2 + 0.7 - i * 0.35),
			CFrame.new(0, -0.5 - i * 0.45, 0) * CFrame.Angles(0, math.rad(i * 40), 0), Color3.fromRGB(150, 205, 235), Enum.Material.Glass)
		ring.Shape = Enum.PartType.Cylinder
		ring.Transparency = 0.3
	end
end

function AccessoryBuilders.WaffleGrid(model, body, def, add, hadd, A)
	-- the waffle grid stamped over the whole body, head included
	for i = -1, 1 do
		add("GridV" .. (i + 2), Vector3.new(0.14, A.HalfH * 2 - 0.1, 0.1), CFrame.new(i * 0.62, 0, -A.HalfD - 0.03), def.Accent)
		add("GridH" .. (i + 2), Vector3.new(A.HalfW * 2 - 0.1, 0.14, 0.1), CFrame.new(0, i * 0.62, -A.HalfD - 0.03), def.Accent)
		hadd("HeadGridV" .. (i + 2), Vector3.new(0.12, 1.2, 0.08), CFrame.new(i * 0.48, 0, A.FaceZ + 0.02), def.Accent)
		hadd("HeadGridH" .. (i + 2), Vector3.new(1.4, 0.12, 0.08), CFrame.new(0, i * 0.42, A.FaceZ + 0.02), def.Accent)
	end
end

function AccessoryBuilders.Cape(model, body, def, add, hadd, A)
	-- the sheet's royal red cape flowing off the back
	add("Cape", Vector3.new(2.0, 2.3, 0.16), CFrame.new(0, -0.15, A.HalfD + 0.3) * CFrame.Angles(math.rad(-8), 0, 0), Color3.fromRGB(178, 34, 44))
	add("Collar", Vector3.new(1.7, 0.45, 0.55), CFrame.new(0, A.HalfH - 0.05, A.HalfD + 0.1), Color3.fromRGB(150, 26, 36))
end

function AccessoryBuilders.Scepter(model, body, def, add, hadd, A)
	-- a golden sceptre held at its side, purple gem on top
	add("ScepterRod", Vector3.new(0.15, 1.35, 0.15), CFrame.new(A.HalfW + 0.62, -0.35, -0.2) * CFrame.Angles(0, 0, math.rad(10)), GOLD, Enum.Material.Metal)
	ball(add("ScepterOrb", Vector3.new(0.44, 0.44, 0.44), CFrame.new(A.HalfW + 0.74, 0.36, -0.2), GOLD, Enum.Material.Metal))
	ball(add("ScepterGem", Vector3.new(0.26, 0.26, 0.26), CFrame.new(A.HalfW + 0.78, 0.68, -0.2), Color3.fromRGB(178, 102, 255), Enum.Material.Neon))
end

function AccessoryBuilders.WhaleTail(model, body, def, add, hadd, A)
	-- a whale's fluked tail sweeping out of the back
	add("Tail", Vector3.new(0.45, 0.45, 1.6), CFrame.new(0, 0.2, A.HalfD + 0.7) * CFrame.Angles(math.rad(-18), 0, 0), def.Body)
	add("FlukeL", Vector3.new(0.95, 0.22, 0.6), CFrame.new(-0.55, 0.5, A.HalfD + 1.5) * CFrame.Angles(0, math.rad(20), math.rad(-14)), def.Body)
	add("FlukeR", Vector3.new(0.95, 0.22, 0.6), CFrame.new(0.55, 0.5, A.HalfD + 1.5) * CFrame.Angles(0, math.rad(-20), math.rad(14)), def.Body)
	-- the pale whale belly on the front
	add("Belly", Vector3.new(1.3, 1.8, 0.24), CFrame.new(0, -0.1, -A.HalfD + 0.02), Color3.fromRGB(225, 235, 245))
end

function AccessoryBuilders.Stars(model, body, def, add, hadd, A)
	-- void stars sprinkled over the body
	for i = 1, 5 do
		local a = i * 1.7
		ball(add("Star" .. i, Vector3.new(0.2, 0.2, 0.2),
			CFrame.new(math.sin(a) * 0.8, math.cos(a * 1.4) * 0.8, -A.HalfD - 0.05), def.Accent, Enum.Material.Neon))
	end
end

function AccessoryBuilders.MoonFin(model, body, def, add, hadd, A)
	-- a crescent-moon fin riding high on the back
	add("MoonFin", Vector3.new(0.25, 1.5, 0.7), CFrame.new(0, A.HalfH + 0.55, A.HalfD * 0.4) * CFrame.Angles(math.rad(-20), 0, 0), def.Accent, Enum.Material.Neon)
end

function AccessoryBuilders.GemCore(model, body, def, add, hadd, A)
	-- a golden dumpling with a gem heart glowing through its chest
	local ring = add("GemRing", Vector3.new(0.95, 0.95, 0.2), CFrame.new(0, 0.1, -A.HalfD - 0.02), GOLD, Enum.Material.Metal)
	ring.Shape = Enum.PartType.Cylinder
	ball(add("GemCore", Vector3.new(0.55, 0.55, 0.4), CFrame.new(0, 0.1, -A.HalfD - 0.14), def.Accent, Enum.Material.Neon))
end

--====================================================================--
-- Build: ONE humanoid body plan for the whole roster. Body first,
-- then the head on its neck Motor6D, arms on shoulder Motor6Ds, then
-- the character's signature accessory set on top.
--====================================================================--
local HEAD_Y = 1.55 -- body-local height of the head centre

function Factory.Build(def, mutation)
	local model = Instance.new("Model")
	model.Name = def.Name

	local scale = 0.9 + def.Rarity * 0.09
	local props = PROPS[def.Name] or {}
	local bodySize = def.BodySize or props.Body or Vector3.new(2.1, 2.3, 1.6)
	local torsoColor = props.Suit or def.Body

	local body = part(model, "Body", bodySize * scale, CFrame.new(0, 0, 0), torsoColor)
	body.Anchored = true
	model.PrimaryPart = body

	-- the head mount: an invisible pivot the neck Motor6D swings
	local mountOffset = CFrame.new(0, HEAD_Y, 0)
	local mount = part(model, "HeadMount", Vector3.new(0.2, 0.2, 0.2), body.CFrame * mountOffset, WHITE)
	mount.Transparency = 1
	local neck = Instance.new("Motor6D")
	neck.Name = "Neck"
	neck.Part0 = body
	neck.Part1 = mount
	neck.C0 = CFrame.new(0, 1.05, 0)
	neck.C1 = mountOffset:Inverse() * neck.C0
	neck.Parent = body

	local function add(name, size, offset, color, material)
		local p = part(model, name, size * scale, body.CFrame * offset, color, material)
		weldTo(p, body)
		return p
	end

	local function hadd(name, size, offset, color, material)
		local p = part(model, name, size * scale, mount.CFrame * offset, color, material)
		weldTo(p, mount)
		return p
	end

	local A = {
		HeadPos = Vector3.new(0, 0, 0), -- head-local origin
		HeadY = HEAD_Y,
		FaceZ = -(1.4 * scale) / 2 - 0.02,
		TopY = 0.65 * scale,
		HalfW = body.Size.X / 2,
		HalfH = body.Size.Y / 2,
		HalfD = body.Size.Z / 2,
		Scale = scale,
	}

	if not def.NoHead then
		hadd("Head", Vector3.new(1.5, 1.3, 1.4), CFrame.new(0, 0, 0), def.Body)
		buildFace(def, hadd, A)
	end

	-- feet
	add("FootL", Vector3.new(0.62, 0.42, 0.9), CFrame.new(-0.55, -1.3, -0.08), BLACK)
	add("FootR", Vector3.new(0.62, 0.42, 0.9), CFrame.new(0.55, -1.3, -0.08), BLACK)

	-- arms on shoulder Motor6Ds (robot arms for the bot, cookie hands)
	local armColor = props.BotArms and Color3.fromRGB(120, 124, 132) or torsoColor
	local shoulders = {}
	for _, side in ipairs({ -1, 1 }) do
		local tag = side < 0 and "L" or "R"
		local armOffset = CFrame.new(side * (A.HalfW + 0.27 * scale), 0.05, 0)
		local arm = part(model, "Arm" .. tag, Vector3.new(0.52, 1.5, 0.52) * scale, body.CFrame * armOffset, armColor)
		local joint = Instance.new("Motor6D")
		joint.Name = "Shoulder" .. tag
		joint.Part0 = body
		joint.Part1 = arm
		joint.C0 = CFrame.new(side * (A.HalfW + 0.02), 0.8, 0)
		joint.C1 = armOffset:Inverse() * joint.C0
		joint.Parent = body
		shoulders[tag] = joint
		if props.BotArms then
			local hand = part(model, "Hand" .. tag, Vector3.new(0.72, 0.2, 0.72) * scale,
				arm.CFrame * CFrame.new(0, -0.85 * scale, 0) * CFrame.Angles(math.rad(90), 0, 0), def.Body)
			hand.Shape = Enum.PartType.Cylinder
			weldTo(hand, arm)
		end
	end

	AnimState[model] = {
		Neck = neck,
		ShoulderL = shoulders.L,
		ShoulderR = shoulders.R,
		Phase = math.random() * 10,
	}
	model.Destroying:Connect(function()
		AnimState[model] = nil
	end)

	if def.Accessory then
		for _, key in ipairs(def.Accessory) do
			local builder = AccessoryBuilders[key]
			if builder then
				builder(model, body, def, add, hadd, A)
			end
		end
	end

	-- nameplate: name + rarity + income, the genre's signature label
	local gui = Instance.new("BillboardGui")
	gui.Name = "Nameplate"
	gui.Size = UDim2.new(6, 0, 1.6, 0)
	gui.StudsOffset = Vector3.new(0, 3.1 * scale, 0)
	gui.AlwaysOnTop = true
	gui.Parent = body

	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = WHITE
	label.TextStrokeTransparency = 0.35
	label.Text = ""
	label.Parent = gui

	-- sparkles for shiny/golden mutations and the top rarities
	local mut = mutation and Config.Mutations[mutation]
	if mut or def.Rarity >= 4 then
		local sparkles = Instance.new("ParticleEmitter")
		sparkles.Name = "Sparkles"
		sparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		sparkles.Color = ColorSequence.new(mut and mut.Color or Config.Rarities[def.Rarity].Color)
		sparkles.Rate = mut and 26 or 12
		sparkles.Lifetime = NumberRange.new(0.5, 1.1)
		sparkles.Speed = NumberRange.new(0.6, 1.6)
		sparkles.Size = NumberSequence.new(0.35)
		sparkles.Parent = body
	end

	return model
end

-- The bandit NPC: a shifty little burglar built from the same parts.
function Factory.BuildBandit()
	local model = Instance.new("Model")
	model.Name = "Bandit"
	local body = part(model, "Body", Vector3.new(2.1, 2.3, 1.6), CFrame.new(0, 0, 0), Color3.fromRGB(60, 60, 72))
	body.Anchored = true
	model.PrimaryPart = body
	local function add(name, size, offset, color, material)
		local p = part(model, name, size, body.CFrame * offset, color, material)
		weldTo(p, body)
		return p
	end
	add("Head", Vector3.new(1.5, 1.3, 1.4), CFrame.new(0, HEAD_Y, 0), Color3.fromRGB(240, 205, 160))
	add("Mask", Vector3.new(1.56, 0.45, 1.46), CFrame.new(0, HEAD_Y + 0.12, 0), BLACK)
	add("Beanie", Vector3.new(1.6, 0.5, 1.5), CFrame.new(0, HEAD_Y + 0.72, 0), BLACK)
	add("Sack", Vector3.new(1.3, 1.5, 0.8), CFrame.new(0, 0.25, 1.25), Color3.fromRGB(150, 118, 74))
	add("FootL", Vector3.new(0.62, 0.42, 0.9), CFrame.new(-0.55, -1.3, -0.08), BLACK)
	add("FootR", Vector3.new(0.62, 0.42, 0.9), CFrame.new(0.55, -1.3, -0.08), BLACK)
	return model
end

return Factory
