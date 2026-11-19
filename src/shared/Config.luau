-- Config.luau — every tunable number and definition for Brainrot Base Tycoon.
-- Shared by server and client: rarities, the brainrot roster, zones, upgrades,
-- quests, rebirth, events and the (verified) audio table.

local Config = {}

--====================================================================--
-- Rarities (index 1..5, low to high)
--====================================================================--
Config.Rarities = {
	{ Name = "Common",    Color = Color3.fromRGB(196, 200, 208), IncomeMult = 1 },
	{ Name = "Rare",      Color = Color3.fromRGB(64, 142, 255),  IncomeMult = 6 },
	{ Name = "Epic",      Color = Color3.fromRGB(172, 84, 255),  IncomeMult = 30 },
	{ Name = "Legendary", Color = Color3.fromRGB(255, 186, 38),  IncomeMult = 180 },
	{ Name = "Mythic",    Color = Color3.fromRGB(255, 62, 128),  IncomeMult = 1200 },
}

-- Mutations rolled when a brainrot spawns.
Config.Mutations = {
	None   = { Name = "",       IncomeMult = 1, Chance = 0 },
	Shiny  = { Name = "Shiny",  IncomeMult = 2, Chance = 0.04 },
	Golden = { Name = "Golden", IncomeMult = 5, Chance = 0.01 },
}

--====================================================================--
-- Brainrot roster — an ORIGINAL cast, invented for this game: every
-- name and design is new (no borrowed roster). Accessory is a list of
-- builder keys the factory knows. Plan is the body plan the factory
-- builds: Humanoid | Quadruped | Flyer | Blob — each plan reads as a
-- different silhouette. NoHead means an accessory draws the head (with
-- its own eyes). Hover is how high a flyer cruises above the ground.
-- Income is cash per second while the brainrot sits on a display pad.
--====================================================================--
Config.Brainrots = {
	-- Common
	{ Name = "Toastino",        Rarity = 1, Income = 1,  Body = Color3.fromRGB(196, 178, 160), Accent = Color3.fromRGB(255, 140, 40),  Accessory = { "ToasterHead" }, NoHead = true },
	{ Name = "Splashound",      Rarity = 1, Income = 2,  Body = Color3.fromRGB(96, 178, 240),  Accent = Color3.fromRGB(240, 248, 255), Accessory = { "DogEars", "Snout", "WagTail" }, Plan = "Quadruped" },
	{ Name = "Moppina",         Rarity = 1, Income = 2,  Body = Color3.fromRGB(226, 208, 170), Accent = Color3.fromRGB(70, 200, 190),  Accessory = { "MopHair" } },
	{ Name = "Socktopus",       Rarity = 1, Income = 3,  Body = Color3.fromRGB(178, 156, 230), Accent = Color3.fromRGB(255, 170, 200), Accessory = { "Tentacles" }, Plan = "Blob" },
	-- Rare
	{ Name = "Lampadina",       Rarity = 2, Income = 8,  Body = Color3.fromRGB(64, 150, 150),  Accent = Color3.fromRGB(255, 214, 110), Accessory = { "LampHead" }, NoHead = true },
	{ Name = "Biscotto Bot",    Rarity = 2, Income = 10, Body = Color3.fromRGB(216, 164, 94),  Accent = Color3.fromRGB(96, 54, 30),    Accessory = { "CookieDisc", "ChocChips", "Antenna" } },
	{ Name = "Pumpkowl",        Rarity = 2, Income = 12, Body = Color3.fromRGB(240, 132, 40),  Accent = Color3.fromRGB(110, 76, 40),   Accessory = { "PumpkinRibs", "Wings", "EarTufts" }, Plan = "Blob" },
	{ Name = "Raviolibot",      Rarity = 2, Income = 14, Body = Color3.fromRGB(246, 228, 178), Accent = Color3.fromRGB(170, 178, 190), Accessory = { "ForkAntenna", "CrimpEdge" } },
	-- Epic
	{ Name = "Disco Fungo",     Rarity = 3, Income = 45, Body = Color3.fromRGB(200, 60, 80),   Accent = Color3.fromRGB(210, 214, 224), Accessory = { "DiscoBall", "Headphones" } },
	{ Name = "Capitano Teapot", Rarity = 3, Income = 55, Body = Color3.fromRGB(52, 66, 110),   Accent = Color3.fromRGB(255, 196, 66),  Accessory = { "TeapotHead", "PirateHat" }, NoHead = true },
	{ Name = "Astro Jelly",     Rarity = 3, Income = 65, Body = Color3.fromRGB(255, 158, 205), Accent = Color3.fromRGB(96, 220, 255),  Accessory = { "JellyDome", "JellyTentacles", "Backpack" }, Plan = "Flyer", Hover = 1.4 },
	{ Name = "Vroom Broom",     Rarity = 3, Income = 75, Body = Color3.fromRGB(150, 104, 58),  Accent = Color3.fromRGB(246, 214, 110), Accessory = { "BroomStick", "Bristles", "Wheels", "Shades" }, Plan = "Flyer", Hover = 1.1 },
	-- Legendary
	{ Name = "Drake Frutto",    Rarity = 4, Income = 300, Body = Color3.fromRGB(240, 84, 140),  Accent = Color3.fromRGB(84, 200, 110),  Accessory = { "DragonWings", "Horns", "DragonTail" }, Plan = "Flyer", Hover = 0.9 },
	{ Name = "Volpina Neon",    Rarity = 4, Income = 380, Body = Color3.fromRGB(245, 130, 50),  Accent = Color3.fromRGB(96, 235, 255),  Accessory = { "FoxEars", "FoxMuzzle", "TripleTail" }, Plan = "Quadruped" },
	{ Name = "Tornadino",       Rarity = 4, Income = 450, Body = Color3.fromRGB(140, 152, 175), Accent = Color3.fromRGB(216, 178, 110), Accessory = { "TornadoBody", "CowboyHat" }, BodySize = Vector3.new(1.5, 2.3, 1.5) },
	-- Mythic
	{ Name = "Waffleone",       Rarity = 5, Income = 2000, Body = Color3.fromRGB(232, 176, 92),  Accent = Color3.fromRGB(150, 84, 30),   Accessory = { "WaffleGrid", "SyrupTop", "Crown" } },
	{ Name = "Balena Void",     Rarity = 5, Income = 2600, Body = Color3.fromRGB(52, 48, 120),   Accent = Color3.fromRGB(178, 120, 255), Accessory = { "WhaleTail", "Stars", "MoonFin" }, Plan = "Flyer", Hover = 1.6 },
	{ Name = "Gnocco d'Oro",    Rarity = 5, Income = 3200, Body = Color3.fromRGB(255, 196, 64),  Accent = Color3.fromRGB(52, 220, 130),  Accessory = { "GemCore", "Crown" }, Plan = "Blob" },
}

Config.BrainrotByName = {}
for _, def in ipairs(Config.Brainrots) do
	Config.BrainrotByName[def.Name] = def
end

-- Income of one displayed brainrot (definition x rarity is already baked into
-- def.Income; mutations multiply it).
function Config.BrainrotIncome(def, mutation)
	local m = Config.Mutations[mutation or "None"]
	return def.Income * (m and m.IncomeMult or 1)
end

function Config.DisplayName(def, mutation)
	if mutation and mutation ~= "None" then
		return mutation .. " " .. def.Name
	end
	return def.Name
end

--====================================================================--
-- Buying wild brainrots (the Steal-a-Brainrot loop): a wild brainrot's
-- price is its income scaled by PricePerIncome and its mutation
-- multiplier, so a Golden costs (and earns) 5x a plain one.
--====================================================================--
Config.PricePerIncome = 15
function Config.BuyPrice(def, mutation)
	local m = Config.Mutations[mutation or "None"]
	local mult = m and m.IncomeMult or 1
	return math.max(5, math.floor(def.Income * Config.PricePerIncome * mult + 0.5))
end

--====================================================================--
-- Zones. Fields are rectangles on the island; gates sit on the path.
-- Weights are the rarity roll inside that zone. GroundColor/NeonColor
-- drive the futuristic retheme: dark metal panels, neon accents that
-- get richer per tier.
--====================================================================--
Config.Zones = {
	{
		Name = "Neon Outskirts", Price = 0,
		Center = Vector3.new(0, 0, -64), Size = Vector2.new(120, 56),
		GroundColor = Color3.fromRGB(52, 50, 72),
		NeonColor = Color3.fromRGB(176, 96, 255),
		Weights = { 100, 35, 6, 0.6, 0.05 }, SpawnCap = 10,
	},
	{
		Name = "Magenta Techfields", Price = 5000,
		Center = Vector3.new(0, 0, -148), Size = Vector2.new(120, 56),
		GroundColor = Color3.fromRGB(66, 46, 86),
		NeonColor = Color3.fromRGB(238, 92, 224),
		Weights = { 55, 60, 22, 3.5, 0.3 }, SpawnCap = 9,
	},
	{
		Name = "Quantum Core", Price = 75000,
		Center = Vector3.new(0, 0, -232), Size = Vector2.new(120, 56),
		GroundColor = Color3.fromRGB(40, 52, 88),
		NeonColor = Color3.fromRGB(92, 200, 255),
		Weights = { 25, 55, 45, 14, 2.2 }, SpawnCap = 8,
	},
}
Config.SpawnInterval = 2.4 -- seconds between spawn attempts per zone

-- Portal spawns: a wild brainrot rises out of a ground portal, wanders
-- for a while, then sinks back if nobody buys it.
Config.PortalRiseTime = 0.9   -- seconds to rise out of / sink into a portal
Config.WildWanderTime = { 9, 12 } -- seconds a portal wild wanders before sinking

--====================================================================--
-- Upgrades (bought on base pads or in the shop UI)
--====================================================================--
Config.Upgrades = {
	Pads = { -- display pads: start 4, +2 per purchase, max 12
		Start = 4, Step = 2, Max = 12, Costs = { 250, 900, 3000, 10000 },
		Label = "+2 Display Pads",
	},
	Speed = { -- walk speed levels 0..5, +3 studs/s each
		Start = 0, Max = 5, Costs = { 150, 500, 1500, 4500, 12000 },
		Label = "+3 Walk Speed", BaseSpeed = 16, PerLevel = 3,
	},
	Carry = { -- carry capacity 1 -> 2 -> 3
		Start = 0, Max = 2, Costs = { 400, 3500 },
		Label = "Carry +1 Brainrot", BaseCapacity = 1,
	},
	Luck = { -- on buy, chance the brainrot jumps +1 rarity
		Start = 0, Max = 5, Costs = { 300, 1000, 3000, 8000, 20000 },
		Label = "+6% Lucky Buy", PerLevel = 0.06,
	},
}

--====================================================================--
-- Rebirth: resets cash/upgrades/zones/displayed; +50% income each time.
-- Requirement is lifetime TotalEarned.
--====================================================================--
Config.RebirthBaseRequirement = 100000
Config.RebirthRequirementGrowth = 6
Config.RebirthMultPer = 0.5
function Config.RebirthRequirement(rebirths)
	return Config.RebirthBaseRequirement * (Config.RebirthRequirementGrowth ^ rebirths)
end
function Config.IncomeMultiplier(rebirths)
	return 1 + Config.RebirthMultPer * rebirths
end

--====================================================================--
-- Quests: a chain, one active at a time. Kind drives which game event
-- advances it: Place, Earn (lifetime cash), Buy (upgrades), BuyBrainrot,
-- BuyRarity (best rarity bought), UnlockZone, SurviveWave, Rebirth.
--====================================================================--
Config.Quests = {
	{ Text = "Place a Brainrot on a pad at your base",        Kind = "Place",       Target = 1,      Reward = 100 },
	{ Text = "Place 5 Brainrots on your pads",                Kind = "Place",       Target = 5,      Reward = 300 },
	{ Text = "Earn $1,000 in total",                          Kind = "Earn",        Target = 1000,   Reward = 500 },
	{ Text = "Buy 2 upgrades",                                Kind = "Buy",         Target = 2,      Reward = 750 },
	{ Text = "Buy a Rare (or better) Brainrot",               Kind = "BuyRarity",   Target = 2,      Reward = 1200 },
	{ Text = "Buy 4 Brainrots from the portals",              Kind = "BuyBrainrot", Target = 4,      Reward = 2500 },
	{ Text = "Unlock the Magenta Techfields",                 Kind = "UnlockZone",  Target = 2,      Reward = 4000 },
	{ Text = "Survive a Brainrot Wave (keep your carry!)",    Kind = "SurviveWave", Target = 1,      Reward = 6000 },
	{ Text = "Earn $100,000 in total",                        Kind = "Earn",        Target = 100000, Reward = 15000 },
	{ Text = "Rebirth for the first time",                    Kind = "Rebirth",     Target = 1,      Reward = 25000 },
}

--====================================================================--
-- Events
--====================================================================--
Config.Events = {
	GoldRainInterval = { 240, 420 }, GoldRainDuration = 45, GoldRainMutationBoost = 6,
	WaveInterval = { 360, 540 }, WaveWarningTime = 6, WaveSweepTime = 7,
	BanditInterval = { 150, 300 },
}

Config.StartCash = 150
Config.BaseLockTime = 45      -- seconds a base stays locked
Config.BaseLockCooldown = 90  -- seconds before it can lock again
-- v2: the roster was fully renamed, so v1 saves (which store brainrots
-- by name) cannot carry over; everyone starts fresh on the new cast.
Config.DataStoreName = "BrainrotBaseTycoon_v2"
Config.AutosaveSeconds = 60

--====================================================================--
-- Audio. EVERY id below was verified against the Roblox economy API
-- (economy.roblox.com/v2/assets/<id>/details -> AssetTypeId 3 = Audio)
-- on 2026-11-19. APM tracks are from Roblox's licensed APMOfficial
-- library (IsPublicDomain), the SFX are Roblox-creator classics or
-- public-domain uploads. victory.wav is a documented legacy built-in.
--====================================================================--
Config.Audio = {
	BgmMain     = "rbxassetid://1843404009", -- "Happy Song" — APMOfficial
	BgmZone     = "rbxassetid://1837879082", -- "Paradise Falls" — APMOfficial
	BgmEvent    = "rbxassetid://1846368080", -- "Stadium Rave (A)" — APMOfficial
	Click       = "rbxassetid://6895079853", -- "UI Click" — mattwyc (public domain)
	Pickup      = "rbxassetid://26723422",   -- "balloonpop" — Roblox
	Place       = "rbxassetid://160248302",  -- "Pop 2" — Stickmasterluke (public domain)
	Collect     = "rbxassetid://4612375233", -- "gem_pickup" — thienbao2109 (public domain)
	Buy         = "rbxassetid://14810387808",-- "mvm_bought_upgrade" — Alika0946 (public domain)
	Error       = "rbxassetid://104560954",  -- "Simple Beep" — Roblox (played low-pitched)
	Alarm       = "rbxassetid://104560954",  -- "Simple Beep" — Roblox (repeated pattern)
	Dash        = "rbxassetid://129425637",  -- "woosh" — Roblox
	WaveHit     = "rbxassetid://160248505",  -- "Bang 4" — Stickmasterluke (public domain)
	Magic       = "rbxassetid://106805906",  -- "FROG_MAGIC" — Roblox
	Celebrate   = "rbxassetid://160248368",  -- "Firework Fountain" — Stickmasterluke (public domain)
	Fanfare     = "rbxasset://sounds/victory.wav", -- legacy built-in fanfare
	Bandit      = "rbxassetid://86148536",   -- "Bike Horn Double Toot" — Roblox
	Thud        = "rbxassetid://10548108",   -- "2x4 Sound 1" — Roblox
}

return Config
