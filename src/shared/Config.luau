-- Config.luau — every tunable number and definition for Brainrot Base Tycoon.
-- Shared by server and client: rarities, the brainrot roster, zones, upgrades,
-- fusion, quests, rebirth, events and the (verified) audio table.

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

-- Mutations rolled when a brainrot spawns (or granted by fusion).
Config.Mutations = {
	None   = { Name = "",       IncomeMult = 1, Chance = 0 },
	Shiny  = { Name = "Shiny",  IncomeMult = 2, Chance = 0.04 },
	Golden = { Name = "Golden", IncomeMult = 5, Chance = 0.01 },
}

--====================================================================--
-- Brainrot roster. Accessory is a list of builder keys the factory knows.
-- Income is cash per second while the brainrot sits on a display pad.
--====================================================================--
Config.Brainrots = {
	-- Common
	{ Name = "Noobini Pizzanini",      Rarity = 1, Income = 1,  Body = Color3.fromRGB(245, 205, 50),  Accent = Color3.fromRGB(255, 120, 60),  Accessory = { "Pizza" } },
	{ Name = "Pipi Kiwi",              Rarity = 1, Income = 2,  Body = Color3.fromRGB(122, 84, 50),   Accent = Color3.fromRGB(140, 200, 90),  Accessory = { "Beak", "Leaf" } },
	{ Name = "Trippi Troppi",          Rarity = 1, Income = 2,  Body = Color3.fromRGB(255, 138, 76),  Accent = Color3.fromRGB(255, 90, 90),   Accessory = { "TailFin" } },
	-- Rare
	{ Name = "Tung Tung Tung Sahur",   Rarity = 2, Income = 8,  Body = Color3.fromRGB(150, 104, 58),  Accent = Color3.fromRGB(110, 74, 36),   Accessory = { "LogBody", "Bat" } },
	{ Name = "Lirili Larila",          Rarity = 2, Income = 10, Body = Color3.fromRGB(158, 164, 176), Accent = Color3.fromRGB(74, 168, 84),   Accessory = { "Trunk", "Cactus" } },
	{ Name = "Brr Brr Patapim",        Rarity = 2, Income = 12, Body = Color3.fromRGB(112, 78, 46),   Accent = Color3.fromRGB(70, 160, 70),   Accessory = { "TreeTop" } },
	-- Epic
	{ Name = "Cappuccino Assassino",   Rarity = 3, Income = 45, Body = Color3.fromRGB(240, 234, 222), Accent = Color3.fromRGB(120, 78, 40),   Accessory = { "CupHead", "Swords" } },
	{ Name = "Ballerina Cappuccina",   Rarity = 3, Income = 55, Body = Color3.fromRGB(250, 240, 246), Accent = Color3.fromRGB(255, 150, 200), Accessory = { "CupHead", "Tutu" } },
	{ Name = "Chimpanzini Bananini",   Rarity = 3, Income = 65, Body = Color3.fromRGB(246, 224, 84),  Accent = Color3.fromRGB(120, 84, 50),   Accessory = { "Banana" } },
	-- Legendary
	{ Name = "Tralalero Tralala",      Rarity = 4, Income = 300, Body = Color3.fromRGB(70, 150, 230), Accent = Color3.fromRGB(240, 240, 240), Accessory = { "SharkFin", "Sneakers" } },
	{ Name = "Bombardiro Crocodilo",   Rarity = 4, Income = 380, Body = Color3.fromRGB(86, 168, 84),  Accent = Color3.fromRGB(90, 90, 96),    Accessory = { "Wings", "Propeller" } },
	{ Name = "Bombombini Gusini",      Rarity = 4, Income = 450, Body = Color3.fromRGB(244, 244, 248), Accent = Color3.fromRGB(255, 170, 40),  Accessory = { "Wings", "Cap" } },
	-- Mythic
	{ Name = "La Vaca Saturno Saturnita", Rarity = 5, Income = 2000, Body = Color3.fromRGB(246, 246, 250), Accent = Color3.fromRGB(60, 60, 70), Accessory = { "SaturnRing", "Stars" } },
	{ Name = "Giraffa Celeste",        Rarity = 5, Income = 2600, Body = Color3.fromRGB(250, 214, 120), Accent = Color3.fromRGB(150, 100, 50), Accessory = { "LongNeck", "Stars" } },
	{ Name = "Frigo Camelo",           Rarity = 5, Income = 3200, Body = Color3.fromRGB(205, 228, 240), Accent = Color3.fromRGB(230, 180, 90), Accessory = { "FridgeBody", "Cap" } },
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
-- Zones. Fields are rectangles on the island; gates sit on the path.
-- Weights are the rarity roll inside that zone.
--====================================================================--
Config.Zones = {
	{
		Name = "Brainrot Meadows", Price = 0,
		Center = Vector3.new(0, 0, -64), Size = Vector2.new(120, 56),
		GroundColor = Color3.fromRGB(106, 196, 92),
		Weights = { 100, 35, 6, 0.6, 0.05 }, SpawnCap = 14,
	},
	{
		Name = "Neon Lagoon", Price = 5000,
		Center = Vector3.new(0, 0, -148), Size = Vector2.new(120, 56),
		GroundColor = Color3.fromRGB(64, 178, 196),
		Weights = { 55, 60, 22, 3.5, 0.3 }, SpawnCap = 12,
	},
	{
		Name = "Golden Volcano", Price = 75000,
		Center = Vector3.new(0, 0, -232), Size = Vector2.new(120, 56),
		GroundColor = Color3.fromRGB(214, 148, 62),
		Weights = { 25, 55, 45, 14, 2.2 }, SpawnCap = 10,
	},
}
Config.SpawnInterval = 2.4 -- seconds between spawn attempts per zone

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
	Luck = { -- on catch, chance the brainrot jumps +1 rarity
		Start = 0, Max = 5, Costs = { 300, 1000, 3000, 8000, 20000 },
		Label = "+6% Lucky Catch", PerLevel = 0.06,
	},
}

--====================================================================--
-- Fusion: 3 identical brainrots (same name + mutation) fuse into one
-- random brainrot of the next rarity, keeping the mutation.
--====================================================================--
Config.FusionRequired = 3

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
-- advances it: Place, Earn (lifetime cash), Buy, CatchRarity, Fuse,
-- UnlockZone, SurviveWave, Rebirth.
--====================================================================--
Config.Quests = {
	{ Text = "Place a Brainrot on a pad at your base",        Kind = "Place",       Target = 1,      Reward = 100 },
	{ Text = "Place 5 Brainrots on your pads",                Kind = "Place",       Target = 5,      Reward = 300 },
	{ Text = "Earn $1,000 in total",                          Kind = "Earn",        Target = 1000,   Reward = 500 },
	{ Text = "Buy 2 upgrades",                                Kind = "Buy",         Target = 2,      Reward = 750 },
	{ Text = "Catch a Rare (or better) Brainrot",             Kind = "CatchRarity", Target = 2,      Reward = 1200 },
	{ Text = "Fuse 3 Brainrots into a higher rarity",         Kind = "Fuse",        Target = 1,      Reward = 2500 },
	{ Text = "Unlock the Neon Lagoon",                        Kind = "UnlockZone",  Target = 2,      Reward = 4000 },
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
Config.DataStoreName = "BrainrotBaseTycoon_v1"
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
	Fusion      = "rbxassetid://49459858",   -- "incant" — Roblox
	Magic       = "rbxassetid://106805906",  -- "FROG_MAGIC" — Roblox
	Celebrate   = "rbxassetid://160248368",  -- "Firework Fountain" — Stickmasterluke (public domain)
	Fanfare     = "rbxasset://sounds/victory.wav", -- legacy built-in fanfare
	Bandit      = "rbxassetid://86148536",   -- "Bike Horn Double Toot" — Roblox
	Thud        = "rbxassetid://10548108",   -- "2x4 Sound 1" — Roblox
}

return Config
