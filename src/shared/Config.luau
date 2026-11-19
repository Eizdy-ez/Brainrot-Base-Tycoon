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
-- name and design is new (no borrowed roster). Every character stands
-- on the SAME humanoid body plan; the absurd creature/object identity
-- of each one comes from its accessory set (toaster head, sock
-- tentacles, satellite dish with electric sparks, whale tail…) plus
-- its colours, so each silhouette still reads differently at a glance.
-- Accessory is a list of builder keys the factory knows. NoHead means
-- an accessory draws the head (with its own eyes). Price, when present,
-- overrides the income-scaled buy price (the starter Commons use it so
-- a brand-new player can always afford one). Income is cash per second
-- while the brainrot sits on a display pad.
--====================================================================--
Config.Brainrots = {
	-- Common (starter band: flat prices a $50 wallet can always pay)
	{ Name = "Toastino",        Rarity = 1, Income = 1,  Price = 25, Body = Color3.fromRGB(196, 178, 160), Accent = Color3.fromRGB(255, 140, 40),  Accessory = { "ToasterHead" }, NoHead = true },
	{ Name = "Splashound",      Rarity = 1, Income = 2,  Price = 35, Body = Color3.fromRGB(96, 178, 240),  Accent = Color3.fromRGB(240, 248, 255), Accessory = { "DogEars", "Snout", "WagTail" } },
	{ Name = "Moppina",         Rarity = 1, Income = 2,  Price = 40, Body = Color3.fromRGB(226, 208, 170), Accent = Color3.fromRGB(70, 200, 190),  Accessory = { "MopHair" } },
	{ Name = "Socktopus",       Rarity = 1, Income = 3,  Price = 50, Body = Color3.fromRGB(178, 156, 230), Accent = Color3.fromRGB(255, 170, 200), Accessory = { "Tentacles" } },
	-- Rare
	{ Name = "Lampadina",       Rarity = 2, Income = 8,  Body = Color3.fromRGB(64, 150, 150),  Accent = Color3.fromRGB(255, 214, 110), Accessory = { "LampHead" }, NoHead = true },
	{ Name = "Biscotto Bot",    Rarity = 2, Income = 10, Body = Color3.fromRGB(216, 164, 94),  Accent = Color3.fromRGB(96, 54, 30),    Accessory = { "CookieHead", "CookieDisc", "ChocChips", "Antenna" }, NoHead = true },
	{ Name = "Pumpkowl",        Rarity = 2, Income = 12, Body = Color3.fromRGB(240, 132, 40),  Accent = Color3.fromRGB(110, 76, 40),   Accessory = { "PumpkinHead", "PumpkinRibs", "Wings", "EarTufts" }, NoHead = true },
	{ Name = "Raviolibot",      Rarity = 2, Income = 14, Body = Color3.fromRGB(246, 228, 178), Accent = Color3.fromRGB(170, 178, 190), Accessory = { "ForkAntenna", "CrimpEdge", "HeadFrame" } },
	-- Epic
	{ Name = "Disco Fungo",     Rarity = 3, Income = 45, Body = Color3.fromRGB(200, 60, 80),   Accent = Color3.fromRGB(210, 214, 224), Accessory = { "DiscoBall", "Headphones" } },
	{ Name = "Capitano Teapot", Rarity = 3, Income = 55, Body = Color3.fromRGB(52, 66, 110),   Accent = Color3.fromRGB(255, 196, 66),  Accessory = { "TeapotHead", "PirateHat" }, NoHead = true },
	{ Name = "Astro Jelly",     Rarity = 3, Income = 65, Body = Color3.fromRGB(255, 158, 205), Accent = Color3.fromRGB(96, 220, 255),  Accessory = { "JellyDome", "JellyTentacles", "Backpack" } },
	{ Name = "Vroom Broom",     Rarity = 3, Income = 75, Body = Color3.fromRGB(150, 104, 58),  Accent = Color3.fromRGB(246, 214, 110), Accessory = { "BroomStick", "Bristles", "Wheels", "Shades" } },
	{ Name = "Satelerror",      Rarity = 3, Income = 85, Body = Color3.fromRGB(112, 124, 148), Accent = Color3.fromRGB(96, 225, 255),  Accessory = { "TVHead", "SatDish", "SolarPanels", "SparkCoils" }, NoHead = true },
	-- Legendary
	{ Name = "Drake Frutto",    Rarity = 4, Income = 300, Body = Color3.fromRGB(240, 84, 140),  Accent = Color3.fromRGB(84, 200, 110),  Accessory = { "DragonWings", "Horns", "DragonTail" } },
	{ Name = "Volpina Neon",    Rarity = 4, Income = 380, Body = Color3.fromRGB(245, 130, 50),  Accent = Color3.fromRGB(96, 235, 255),  Accessory = { "FoxEars", "FoxMuzzle", "TripleTail" } },
	{ Name = "Tornadino",       Rarity = 4, Income = 450, Body = Color3.fromRGB(140, 152, 175), Accent = Color3.fromRGB(216, 178, 110), Accessory = { "TornadoBody", "CowboyHat" }, BodySize = Vector3.new(1.7, 1.9, 1.7) },
	-- Mythic
	{ Name = "Waffleone",       Rarity = 5, Income = 2000, Body = Color3.fromRGB(232, 176, 92),  Accent = Color3.fromRGB(150, 84, 30),   Accessory = { "WaffleGrid", "SyrupTop", "Crown", "Cape", "Scepter" } },
	{ Name = "Balena Void",     Rarity = 5, Income = 2600, Body = Color3.fromRGB(52, 48, 120),   Accent = Color3.fromRGB(178, 120, 255), Accessory = { "WhaleTail", "Stars", "MoonFin" } },
	{ Name = "Gnocco d'Oro",    Rarity = 5, Income = 3200, Body = Color3.fromRGB(255, 196, 64),  Accent = Color3.fromRGB(52, 220, 130),  Accessory = { "GemCore", "Crown" } },
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
	-- a def's flat Price (the starter Commons) replaces the income scale
	local base = def.Price or (def.Income * Config.PricePerIncome)
	return math.max(5, math.floor(base * mult + 0.5))
end

--====================================================================--
-- Zones. Fields are rectangles on the island; gates sit on the path.
-- Weights are the rarity roll inside that zone. EVERY rarity has a
-- nonzero weight in EVERY zone: no character is locked behind a paid
-- gate — anything in the roster can rise out of a portal in the free
-- first district and be bought there (higher districts just roll the
-- top rarities far more often). GroundColor/NeonColor drive the
-- futuristic retheme: dark metal panels, neon accents that get
-- richer per tier.
--====================================================================--
Config.Zones = {
	{
		Name = "Neon District", Price = 0,
		Center = Vector3.new(0, 0, -50), Size = Vector2.new(120, 44),
		GroundColor = Color3.fromRGB(44, 42, 64),
		NeonColor = Color3.fromRGB(176, 96, 255),
		Weights = { 100, 32, 5, 1.5, 0.3 }, SpawnCap = 10,
	},
	{
		Name = "Magenta Quarter", Price = 5000,
		Center = Vector3.new(0, 0, -118), Size = Vector2.new(120, 44),
		GroundColor = Color3.fromRGB(56, 38, 74),
		NeonColor = Color3.fromRGB(238, 92, 224),
		Weights = { 55, 60, 22, 4, 0.6 }, SpawnCap = 9,
	},
	{
		Name = "Quantum Heights", Price = 75000,
		Center = Vector3.new(0, 0, -186), Size = Vector2.new(120, 44),
		GroundColor = Color3.fromRGB(32, 42, 74),
		NeonColor = Color3.fromRGB(92, 200, 255),
		Weights = { 25, 55, 45, 14, 2.5 }, SpawnCap = 8,
	},
}
Config.SpawnInterval = 2.4 -- seconds between spawn attempts per zone

-- Portal spawns: a wild brainrot rises out of a ground portal, wanders
-- for a while, then sinks back if nobody buys it.
Config.PortalRiseTime = 0.9   -- seconds to rise out of / sink into a portal
Config.PortalAnimTime = 0.35  -- seconds for the portal circle to open / close
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
-- BuyRarity (best rarity bought), UnlockZone, Rebirth.
--====================================================================--
Config.Quests = {
	{ Text = "Place a Brainrot on a pad at your base",        Kind = "Place",       Target = 1,      Reward = 100 },
	{ Text = "Place 5 Brainrots on your pads",                Kind = "Place",       Target = 5,      Reward = 300 },
	{ Text = "Earn $1,000 in total",                          Kind = "Earn",        Target = 1000,   Reward = 500 },
	{ Text = "Buy 2 upgrades",                                Kind = "Buy",         Target = 2,      Reward = 750 },
	{ Text = "Buy a Rare (or better) Brainrot",               Kind = "BuyRarity",   Target = 2,      Reward = 1200 },
	{ Text = "Buy 4 Brainrots from the portals",              Kind = "BuyBrainrot", Target = 4,      Reward = 2500 },
	{ Text = "Unlock the Magenta Quarter",                   Kind = "UnlockZone",  Target = 2,      Reward = 4000 },
	{ Text = "Buy 12 Brainrots from the portals",             Kind = "BuyBrainrot", Target = 12,     Reward = 6000 },
	{ Text = "Earn $100,000 in total",                        Kind = "Earn",        Target = 100000, Reward = 15000 },
	{ Text = "Rebirth for the first time",                    Kind = "Rebirth",     Target = 1,      Reward = 25000 },
}

--====================================================================--
-- Events
--====================================================================--
Config.Events = {
	GoldRainInterval = { 240, 420 }, GoldRainDuration = 45, GoldRainMutationBoost = 6,
	BanditInterval = { 150, 300 },
}

Config.StartCash = 50
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
	Click       = "rbxassetid://6895079853", -- "UI Click" — mattwyc (public domain)
	Pickup      = "rbxassetid://26723422",   -- "balloonpop" — Roblox
	Place       = "rbxassetid://160248302",  -- "Pop 2" — Stickmasterluke (public domain)
	Collect     = "rbxassetid://4612375233", -- "gem_pickup" — thienbao2109 (public domain)
	Buy         = "rbxassetid://14810387808",-- "mvm_bought_upgrade" — Alika0946 (public domain)
	Error       = "rbxassetid://104560954",  -- "Simple Beep" — Roblox (played low-pitched)
	Dash        = "rbxassetid://129425637",  -- "woosh" — Roblox
	Magic       = "rbxassetid://106805906",  -- "FROG_MAGIC" — Roblox
	Celebrate   = "rbxassetid://160248368",  -- "Firework Fountain" — Stickmasterluke (public domain)
	Fanfare     = "rbxasset://sounds/victory.wav", -- legacy built-in fanfare
	Bandit      = "rbxassetid://86148536",   -- "Bike Horn Double Toot" — Roblox
	Thud        = "rbxassetid://10548108",   -- "2x4 Sound 1" — Roblox
}

return Config
